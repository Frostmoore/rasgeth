// The person's calendars (3.12.3): CalDAV accounts (read and write) and read-only iCal addresses.
// What identifies a calendar (its name, kind, the CalDAV address and user) is kept in the settings;
// the secret (a CalDAV password, or a whole iCal address, which is itself a secret for Google's
// «secret address») lives only in the keychain as `calendar:<id>`, never in a file, a log or an
// answer. Without an open keychain a calendar cannot be added. Plain HTTP only: PROPFIND to try a
// CalDAV account, REPORT to list, PUT to write; the fetch is a parameter, so tests use a fake.
import { randomUUID } from "node:crypto";
import type { SqlClient } from "@redgiant/events";
import { type CalendarEvent, type CalendarInfo, PRODUCT_NAME } from "@redgiant/protocol";
import type { Vault } from "../vault.js";
import { buildIcs, eventsBetween, parseIcs, type RawEvent } from "./ics.js";

export class CalendarError extends Error {}
export class CalendarNotFoundError extends CalendarError {}

export type CalendarFetch = (url: string, init: RequestInit) => Promise<Response>;

export interface CalendarInput {
  name: string;
  kind: "caldav" | "ics";
  /** CalDAV: the calendar's collection address. iCal: the iCal address (https:// or webcal://). */
  url: string;
  user?: string | undefined;
  password?: string | undefined;
  agents?: boolean | undefined;
}

type Stored = CalendarInfo;

const KEY = "calendars";
const TIMEOUT_MS = 20_000;
const MAX_BYTES = 8 * 1024 * 1024;

const keyOf = (id: string) => `calendar:${id}`;
const httpUrl = (u: string) => u.trim().replace(/^webcal:\/\//i, "https://");

/** An iCal address as it may be shown: the host only, the rest is a secret. */
export function icsShown(url: string): string {
  try {
    return new URL(httpUrl(url)).host;
  } catch {
    return "";
  }
}

const decodeXml = (s: string) =>
  s
    .replace(/<!\[CDATA\[([\s\S]*?)\]\]>/g, "$1")
    .replace(/&lt;/g, "<")
    .replace(/&gt;/g, ">")
    .replace(/&quot;/g, '"')
    .replace(/&apos;/g, "'")
    .replace(/&#13;/g, "\r")
    .replace(/&#10;/g, "\n")
    .replace(/&amp;/g, "&");

/** The calendar objects of a CalDAV multistatus answer. */
export function calendarData(xml: string): string[] {
  const out: string[] = [];
  const re = /<([\w-]+:)?calendar-data\b[^>]*>([\s\S]*?)<\/([\w-]+:)?calendar-data>/gi;
  for (let m = re.exec(xml); m; m = re.exec(xml)) if (m[2]) out.push(decodeXml(m[2]));
  return out;
}

const rangeStamp = (d: Date) =>
  d
    .toISOString()
    .replace(/[-:]/g, "")
    .replace(/\.\d{3}/, "");

export class CalendarService {
  private readonly fetcher: CalendarFetch;

  constructor(
    private readonly o: {
      db: SqlClient;
      vault?: Vault | undefined;
      fetch?: CalendarFetch;
      now?: () => Date;
    },
  ) {
    this.fetcher = o.fetch ?? ((url, init) => fetch(url, init));
  }

  private async stored(owner: string): Promise<Stored[]> {
    const [r] = await this.o.db.query<{ value: unknown }>(
      "SELECT value FROM rg_settings WHERE owner_id = $1 AND key = $2",
      [owner, KEY],
    );
    if (!r) return [];
    return (typeof r.value === "string" ? JSON.parse(r.value) : r.value) as Stored[];
  }

  private async save(owner: string, list: Stored[]): Promise<void> {
    await this.o.db.query(
      `INSERT INTO rg_settings (owner_id, key, value) VALUES ($1, $2, $3)
       ON CONFLICT (owner_id, key) DO UPDATE SET value = EXCLUDED.value`,
      [owner, KEY, JSON.stringify(list)],
    );
  }

  /** Every calendar of the person, as shown (an iCal address only by its host). */
  async list(owner: string): Promise<CalendarInfo[]> {
    return this.stored(owner);
  }

  /** The calendars open to the agents (and, with `ids`, only those). */
  async open(owner: string, ids?: readonly string[]): Promise<CalendarInfo[]> {
    return (await this.stored(owner)).filter(
      (c) => c.agents === true && (!ids || ids.includes(c.id)),
    );
  }

  private secret(owner: string, id: string): string | undefined {
    return this.o.vault?.systemValue(owner, keyOf(id));
  }

  private request(url: string, init: RequestInit): Promise<Response> {
    return this.fetcher(url, {
      ...init,
      redirect: "follow",
      signal: AbortSignal.timeout(TIMEOUT_MS),
    });
  }

  private auth(user: string | undefined, password: string | undefined): Record<string, string> {
    return user && password
      ? { authorization: `Basic ${Buffer.from(`${user}:${password}`).toString("base64")}` }
      : {};
  }

  private async text(res: Response): Promise<string> {
    const t = await res.text();
    if (t.length > MAX_BYTES) throw new CalendarError("The calendar answered with too much data");
    return t;
  }

  /** Tries a calendar before it is kept: a wrong address or password fails here. */
  private async probe(i: CalendarInput): Promise<void> {
    try {
      if (i.kind === "ics") {
        const res = await this.request(httpUrl(i.url), { method: "GET" });
        if (!res.ok) throw new CalendarError(`The address answered ${res.status}`);
        if (!/BEGIN:VCALENDAR/i.test(await this.text(res)))
          throw new CalendarError("That address is not an iCal calendar");
        return;
      }
      const res = await this.request(i.url, {
        method: "PROPFIND",
        headers: {
          ...this.auth(i.user, i.password),
          depth: "0",
          "content-type": "application/xml; charset=utf-8",
        },
        body: '<?xml version="1.0"?><d:propfind xmlns:d="DAV:"><d:prop><d:resourcetype/></d:prop></d:propfind>',
      });
      if (res.status === 401 || res.status === 403)
        throw new CalendarError("The server refused the user or the password");
      if (res.status !== 207 && !res.ok)
        throw new CalendarError(`The server answered ${res.status}`);
    } catch (err) {
      if (err instanceof CalendarError) throw err;
      throw new CalendarError(`The calendar did not answer: ${(err as Error).message}`);
    }
  }

  async add(owner: string, i: CalendarInput): Promise<CalendarInfo> {
    const vault = this.o.vault;
    if (!vault?.ready)
      throw new CalendarError(
        "The keychain is closed: open it first, a calendar's secret is kept there",
      );
    if (i.kind === "caldav" && (!i.user || !i.password))
      throw new CalendarError("A CalDAV calendar needs its user and password");
    const url = i.kind === "ics" ? httpUrl(i.url) : i.url.trim();
    if (!/^https?:\/\//i.test(url)) throw new CalendarError("The address must start with https://");
    await this.probe({ ...i, url });
    const id = `cal_${randomUUID().slice(0, 8)}`;
    const secret = i.kind === "ics" ? url : (i.password ?? "");
    const host = icsShown(url) || url;
    await vault.setSystem(owner, keyOf(id), secret, {
      name: `calendar-${id}`,
      service: i.name.trim() || host,
      category: "other",
      ...(i.user && { username: i.user }),
      hosts: [host.toLowerCase()],
      inject: { header: "", format: "{value}" },
      section: "calendars",
      kind: "other",
      what: i.kind === "ics" ? host : (i.user ?? host),
    });
    const box: Stored = {
      id,
      name: i.name.trim() || host,
      kind: i.kind,
      // An iCal address is only in the keychain: the settings keep its host.
      url: i.kind === "ics" ? host : url,
      ...(i.kind === "caldav" && i.user && { user: i.user }),
      writable: i.kind === "caldav",
      ...(i.agents === true && { agents: true }),
      createdAt: (this.o.now?.() ?? new Date()).toISOString(),
    };
    await this.save(owner, [...(await this.stored(owner)), box]);
    return { ...box };
  }

  async update(
    owner: string,
    id: string,
    patch: { name?: string | undefined; agents?: boolean | undefined },
  ): Promise<CalendarInfo> {
    const list = await this.stored(owner);
    const c = list.find((x) => x.id === id);
    if (!c) throw new CalendarNotFoundError(`Calendar "${id}" not found`);
    if (patch.name !== undefined) c.name = patch.name.trim() || c.name;
    if (patch.agents !== undefined) {
      if (patch.agents) c.agents = true;
      else delete c.agents;
    }
    await this.save(owner, list);
    return { ...c };
  }

  async remove(owner: string, id: string): Promise<void> {
    const list = await this.stored(owner);
    if (!list.some((c) => c.id === id)) return;
    await this.save(
      owner,
      list.filter((c) => c.id !== id),
    );
    if (this.o.vault?.ready) await this.o.vault.setSystem(owner, keyOf(id), null);
  }

  private async rawEvents(owner: string, c: Stored, from: Date, to: Date): Promise<RawEvent[]> {
    const secret = this.secret(owner, c.id);
    if (secret === undefined)
      throw new CalendarError(`The secret of "${c.name}" is missing: the person adds it again`);
    if (c.kind === "ics") {
      const res = await this.request(httpUrl(secret), { method: "GET" });
      if (!res.ok) throw new CalendarError(`"${c.name}" answered ${res.status}`);
      return parseIcs(await this.text(res));
    }
    const body = `<?xml version="1.0" encoding="utf-8"?>
<c:calendar-query xmlns:d="DAV:" xmlns:c="urn:ietf:params:xml:ns:caldav"><d:prop><c:calendar-data/></d:prop><c:filter><c:comp-filter name="VCALENDAR"><c:comp-filter name="VEVENT"><c:time-range start="${rangeStamp(from)}" end="${rangeStamp(to)}"/></c:comp-filter></c:comp-filter></c:filter></c:calendar-query>`;
    const res = await this.request(c.url, {
      method: "REPORT",
      headers: {
        ...this.auth(c.user, secret),
        depth: "1",
        "content-type": "application/xml; charset=utf-8",
      },
      body,
    });
    if (res.status !== 207 && !res.ok)
      throw new CalendarError(`"${c.name}" answered ${res.status}`);
    return calendarData(await this.text(res)).flatMap((d) => parseIcs(d));
  }

  /**
   * The events from `from` to `to` of the calendars given (all the open ones when none): one
   * calendar failing is said and does not hide the others.
   */
  async events(
    owner: string,
    from: Date,
    to: Date,
    ids?: readonly string[],
  ): Promise<{ events: CalendarEvent[]; problems: string[] }> {
    const mine = (await this.stored(owner)).filter(
      (c) => c.agents === true && (!ids || ids.includes(c.id)),
    );
    const events: CalendarEvent[] = [];
    const problems: string[] = [];
    for (const c of mine) {
      try {
        events.push(...eventsBetween(await this.rawEvents(owner, c, from, to), from, to, c.name));
      } catch (err) {
        problems.push(`${c.name}: ${(err as Error).message}`);
      }
    }
    return { events: events.sort((a, b) => a.start.localeCompare(b.start)), problems };
  }

  /** Writes one event to a CalDAV calendar (the person has already said yes). */
  async create(
    owner: string,
    id: string,
    ev: {
      summary: string;
      start: string;
      end?: string | undefined;
      allDay: boolean;
      location?: string | undefined;
      description?: string | undefined;
    },
  ): Promise<{ uid: string; url: string }> {
    const c = (await this.stored(owner)).find((x) => x.id === id);
    if (!c) throw new CalendarNotFoundError(`Calendar "${id}" not found`);
    if (c.agents !== true)
      throw new CalendarError(`"${c.name}" is not open to the agents: only the person opens it`);
    if (c.kind !== "caldav")
      throw new CalendarError(
        `"${c.name}" is read only (an iCal address): events can only be added to a CalDAV calendar`,
      );
    const secret = this.secret(owner, c.id);
    if (secret === undefined) throw new CalendarError(`The password of "${c.name}" is missing`);
    const uid = `${randomUUID()}@${PRODUCT_NAME.toLowerCase()}`;
    const url = `${c.url.replace(/\/+$/, "")}/${uid}.ics`;
    const res = await this.request(url, {
      method: "PUT",
      headers: {
        ...this.auth(c.user, secret),
        "content-type": "text/calendar; charset=utf-8",
        "if-none-match": "*",
      },
      body: buildIcs(
        {
          uid,
          summary: ev.summary,
          start: ev.start,
          allDay: ev.allDay,
          ...(ev.end && { end: ev.end }),
          ...(ev.location && { location: ev.location }),
          ...(ev.description && { description: ev.description }),
        },
        this.o.now?.() ?? new Date(),
      ),
    });
    if (!res.ok) throw new CalendarError(`"${c.name}" refused the event (${res.status})`);
    return { uid, url };
  }
}

// A minimal iCalendar (RFC 5545) reader and writer for events (3.12.3): VEVENT with UID, SUMMARY,
// DTSTART/DTEND (UTC, with TZID, floating or whole-day), DURATION, LOCATION, DESCRIPTION, EXDATE
// and the usual RRULE (DAILY, WEEKLY with BYDAY, MONTHLY, YEARLY; INTERVAL, COUNT, UNTIL). Other
// rule parts are ignored, and a rule that cannot be read leaves the event as a single one.
import type { CalendarEvent } from "@redgiant/protocol";

export interface RawEvent {
  uid: string;
  summary: string;
  start: Date;
  end?: Date;
  allDay: boolean;
  location?: string;
  description?: string;
  rrule?: Record<string, string>;
  exdates: number[];
}

interface Line {
  name: string;
  params: Record<string, string>;
  value: string;
}

/** Folded lines joined (a line starting with a space or tab continues the one before). */
function unfold(text: string): string[] {
  const out: string[] = [];
  for (const l of text.replace(/\r\n?/g, "\n").split("\n")) {
    if ((l.startsWith(" ") || l.startsWith("\t")) && out.length > 0)
      out[out.length - 1] += l.slice(1);
    else out.push(l);
  }
  return out.filter((l) => l.length > 0);
}

function parseLine(l: string): Line | undefined {
  // The first colon outside quotes ends the name and its parameters.
  let q = false;
  let at = -1;
  for (let i = 0; i < l.length; i++) {
    const ch = l[i];
    if (ch === '"') q = !q;
    else if (ch === ":" && !q) {
      at = i;
      break;
    }
  }
  if (at < 1) return undefined;
  const head = l.slice(0, at);
  const parts: string[] = [];
  let cur = "";
  q = false;
  for (const ch of head) {
    if (ch === '"') q = !q;
    if (ch === ";" && !q) {
      parts.push(cur);
      cur = "";
    } else cur += ch;
  }
  parts.push(cur);
  const [name, ...ps] = parts;
  const params: Record<string, string> = {};
  for (const p of ps) {
    const eq = p.indexOf("=");
    if (eq > 0) params[p.slice(0, eq).toUpperCase()] = p.slice(eq + 1).replace(/^"|"$/g, "");
  }
  return { name: (name ?? "").toUpperCase(), params, value: l.slice(at + 1) };
}

const unescapeText = (s: string) =>
  s.replace(/\\([nN,;\\])/g, (_, c: string) => (c === "n" || c === "N" ? "\n" : c));

const escapeText = (s: string) =>
  s.replace(/\\/g, "\\\\").replace(/;/g, ";").replace(/,/g, "\\,").replace(/\r?\n/g, "\\n");

/** The offset (ms) of a time zone at an instant; 0 for a zone the runtime does not know. */
function zoneOffset(at: number, tz: string): number {
  try {
    const f = new Intl.DateTimeFormat("en-US", {
      timeZone: tz,
      hourCycle: "h23",
      year: "numeric",
      month: "numeric",
      day: "numeric",
      hour: "numeric",
      minute: "numeric",
      second: "numeric",
    });
    const p: Record<string, number> = {};
    for (const x of f.formatToParts(new Date(at)))
      if (x.type !== "literal") p[x.type] = Number(x.value);
    const asUtc = Date.UTC(
      p.year ?? 0,
      (p.month ?? 1) - 1,
      p.day ?? 1,
      p.hour ?? 0,
      p.minute ?? 0,
      p.second ?? 0,
    );
    return asUtc - Math.floor(at / 1000) * 1000;
  } catch {
    return 0;
  }
}

function dateValue(l: Line): { at: Date; allDay: boolean } | undefined {
  const m = l.value.trim().match(/^(\d{4})(\d{2})(\d{2})(?:T(\d{2})(\d{2})(\d{2})(Z)?)?$/);
  if (!m) return undefined;
  const [, y, mo, d, h, mi, s, z] = m;
  const utc = Date.UTC(
    Number(y),
    Number(mo) - 1,
    Number(d),
    Number(h ?? 0),
    Number(mi ?? 0),
    Number(s ?? 0),
  );
  if (h === undefined || l.params.VALUE === "DATE") return { at: new Date(utc), allDay: true };
  if (z || !l.params.TZID) return { at: new Date(utc), allDay: false };
  const tz = l.params.TZID;
  const first = utc - zoneOffset(utc, tz);
  return { at: new Date(utc - zoneOffset(first, tz)), allDay: false };
}

function durationMs(v: string): number | undefined {
  const m = v.match(/^([+-])?P(?:(\d+)W)?(?:(\d+)D)?(?:T(?:(\d+)H)?(?:(\d+)M)?(?:(\d+)S)?)?$/);
  if (!m) return undefined;
  const n = (x: string | undefined) => Number(x ?? 0);
  const ms = (((n(m[2]) * 7 + n(m[3])) * 24 + n(m[4])) * 60 + n(m[5])) * 60_000 + n(m[6]) * 1000;
  return m[1] === "-" ? -ms : ms;
}

/** The events of an iCalendar text (a calendar file, a CalDAV object or a whole feed). */
export function parseIcs(text: string): RawEvent[] {
  const out: RawEvent[] = [];
  let cur: Line[] | undefined;
  let depth = 0;
  for (const raw of unfold(text)) {
    const l = parseLine(raw);
    if (!l) continue;
    if (l.name === "BEGIN" && l.value.toUpperCase() === "VEVENT" && !cur) {
      cur = [];
      depth = 0;
    } else if (cur && l.name === "BEGIN") depth++;
    else if (cur && l.name === "END" && depth > 0) depth--;
    else if (cur && l.name === "END" && l.value.toUpperCase() === "VEVENT") {
      const ev = build(cur);
      if (ev) out.push(ev);
      cur = undefined;
    } else if (cur && depth === 0) cur.push(l);
  }
  return out;
}

function build(lines: Line[]): RawEvent | undefined {
  const get = (n: string) => lines.find((l) => l.name === n);
  const startLine = get("DTSTART");
  const start = startLine && dateValue(startLine);
  if (!start) return undefined;
  const endLine = get("DTEND");
  let end = endLine ? dateValue(endLine)?.at : undefined;
  const dur = get("DURATION");
  if (!end && dur) {
    const ms = durationMs(dur.value.trim());
    if (ms !== undefined) end = new Date(start.at.getTime() + ms);
  }
  const rule = get("RRULE");
  const rrule = rule
    ? Object.fromEntries(
        rule.value.split(";").flatMap((p) => {
          const [k, v] = p.split("=");
          return k && v ? [[k.toUpperCase(), v] as [string, string]] : [];
        }),
      )
    : undefined;
  const exdates = lines
    .filter((l) => l.name === "EXDATE")
    .flatMap((l) => l.value.split(",").map((v) => dateValue({ ...l, value: v })?.at.getTime()))
    .filter((x): x is number => x !== undefined);
  const text = (n: string) => {
    const l = get(n);
    return l ? unescapeText(l.value) : undefined;
  };
  const location = text("LOCATION");
  const description = text("DESCRIPTION");
  return {
    uid: get("UID")?.value.trim() || `${start.at.getTime()}-${text("SUMMARY") ?? ""}`,
    summary: text("SUMMARY") ?? "",
    start: start.at,
    ...(end && { end }),
    allDay: start.allDay,
    ...(location && { location }),
    ...(description && { description }),
    ...(rrule && { rrule }),
    exdates,
  };
}

const DAYS = ["SU", "MO", "TU", "WE", "TH", "FR", "SA"];

/** Every start of a repeating event inside the range (at most `cap` of them). */
function occurrences(ev: RawEvent, from: number, to: number, cap = 1000): number[] {
  const first = ev.start.getTime();
  const r = ev.rrule;
  const ex = new Set(ev.exdates);
  if (!r?.FREQ) return [first];
  const interval = Math.max(1, Number(r.INTERVAL ?? 1) || 1);
  const count = r.COUNT ? Number(r.COUNT) : Infinity;
  const until = r.UNTIL
    ? (dateValue({ name: "UNTIL", params: {}, value: r.UNTIL })?.at.getTime() ?? Infinity)
    : Infinity;
  const day = 86_400_000;
  const out: number[] = [];
  let n = 0;
  const push = (t: number): boolean => {
    if (t < first || t > until || n >= count) return false;
    n++;
    if (t + (ev.end ? ev.end.getTime() - first : 0) >= from && t <= to && !ex.has(t)) out.push(t);
    return out.length < cap;
  };
  const s = ev.start;
  const byday = (r.BYDAY ?? "")
    .split(",")
    .map((d) => DAYS.indexOf(d.slice(-2)))
    .filter((d) => d >= 0);
  for (let i = 0; i < 5000; i++) {
    let times: number[];
    if (r.FREQ === "DAILY") times = [first + i * interval * day];
    else if (r.FREQ === "WEEKLY") {
      const weekStart = first - s.getUTCDay() * day + i * interval * 7 * day;
      const days = byday.length ? [...byday].sort((a, b) => a - b) : [s.getUTCDay()];
      times = days.map((d) => weekStart + d * day);
    } else if (r.FREQ === "MONTHLY")
      times = [
        Date.UTC(
          s.getUTCFullYear(),
          s.getUTCMonth() + i * interval,
          s.getUTCDate(),
          s.getUTCHours(),
          s.getUTCMinutes(),
          s.getUTCSeconds(),
        ),
      ];
    else if (r.FREQ === "YEARLY")
      times = [
        Date.UTC(
          s.getUTCFullYear() + i * interval,
          s.getUTCMonth(),
          s.getUTCDate(),
          s.getUTCHours(),
          s.getUTCMinutes(),
          s.getUTCSeconds(),
        ),
      ];
    else return [first];
    for (const t of times) {
      if (t > to || t > until || n >= count) return out;
      if (!push(t)) return out;
    }
    if (times.every((t) => t > to)) break;
  }
  return out;
}

const dateOnly = (d: Date) => d.toISOString().slice(0, 10);

/** The events that touch [from, to), repeats expanded, soonest first. */
export function eventsBetween(
  raws: RawEvent[],
  from: Date,
  to: Date,
  calendar?: string,
): CalendarEvent[] {
  const out: CalendarEvent[] = [];
  for (const ev of raws) {
    const length = ev.end ? ev.end.getTime() - ev.start.getTime() : 0;
    for (const t of occurrences(ev, from.getTime(), to.getTime())) {
      if (t + length < from.getTime() && !(length === 0 && t >= from.getTime())) continue;
      if (t >= to.getTime()) continue;
      const s = new Date(t);
      const e = ev.end ? new Date(t + length) : undefined;
      out.push({
        uid: ev.uid,
        summary: ev.summary,
        start: ev.allDay ? dateOnly(s) : s.toISOString(),
        ...(e && { end: ev.allDay ? dateOnly(e) : e.toISOString() }),
        allDay: ev.allDay,
        ...(ev.location && { location: ev.location }),
        ...(ev.description && { description: ev.description }),
        ...(calendar && { calendar }),
      });
    }
  }
  return out.sort((a, b) => a.start.localeCompare(b.start));
}

const stamp = (d: Date) =>
  d
    .toISOString()
    .replace(/[-:]/g, "")
    .replace(/\.\d{3}/, "");
const dayStamp = (iso: string) => iso.slice(0, 10).replace(/-/g, "");

/** A new event as a calendar object for a CalDAV PUT. */
export function buildIcs(
  ev: {
    uid: string;
    summary: string;
    start: string;
    end?: string;
    allDay: boolean;
    location?: string;
    description?: string;
  },
  now: Date,
): string {
  const fold = (l: string) => {
    const parts: string[] = [];
    for (let i = 0; i < l.length; i += 74) parts.push((i ? " " : "") + l.slice(i, i + 74));
    return parts.join("\r\n");
  };
  const lines = [
    "BEGIN:VCALENDAR",
    "VERSION:2.0",
    "PRODID:-//RedGiant//Calendar//EN",
    "BEGIN:VEVENT",
    `UID:${ev.uid}`,
    `DTSTAMP:${stamp(now)}`,
  ];
  if (ev.allDay) {
    lines.push(`DTSTART;VALUE=DATE:${dayStamp(ev.start)}`);
    // The end of a whole-day event is the day after its last day.
    const last = new Date(`${(ev.end ?? ev.start).slice(0, 10)}T00:00:00Z`);
    lines.push(`DTEND;VALUE=DATE:${dayStamp(new Date(last.getTime() + 86_400_000).toISOString())}`);
  } else {
    const start = new Date(ev.start);
    lines.push(`DTSTART:${stamp(start)}`);
    lines.push(`DTEND:${stamp(ev.end ? new Date(ev.end) : new Date(start.getTime() + 3_600_000))}`);
  }
  lines.push(`SUMMARY:${escapeText(ev.summary)}`);
  if (ev.location) lines.push(`LOCATION:${escapeText(ev.location)}`);
  if (ev.description) lines.push(`DESCRIPTION:${escapeText(ev.description)}`);
  lines.push("END:VEVENT", "END:VCALENDAR");
  return `${lines.map(fold).join("\r\n")}\r\n`;
}

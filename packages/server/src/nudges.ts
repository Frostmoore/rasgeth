// God's friendly nudges (3.12.1, `nudges.ts` in the protocol): at most one a day (or less, as the
// person chooses), never at night, tied to real facts (a topic waiting for the person, one whose
// tasks stand still, one left for days), else a morning greeting. Sentences from a fixed list
// filled with real data: no model call. Delivered as a notification to the open pages and apps
// (`god.nudge`) and to the devices (push), never as a request and never written into a topic.
// Checked on the topics' clock (`tick`, with the service's `now` in tests).

import type { SqlClient } from "@redgiant/events";
import {
  DEFAULT_NUDGE_SETTINGS,
  type GodNudge,
  localDay,
  type NudgeFacts,
  NudgeSettings,
  nudgeDue,
  pickNudge,
  type TopicView,
} from "@redgiant/protocol";
import { settingValue } from "./setting-value.js";

const DAY = 86_400_000;
/** Open tasks standing still this long make a topic «stalled». */
export const STALLED_DAYS = 2;
/** A topic untouched this long is «left». */
export const LEFT_DAYS = 3;
/** A greeting only in the morning: in the afternoon, without facts, nothing. */
const GREETING_UNTIL = 12;

const SETTINGS_KEY = "god_nudges";
const LAST_KEY = "god_nudge_last";

export interface NudgeHost {
  db: SqlClient;
  topics(ownerId: string): Promise<TopicView[]>;
  language(ownerId: string): string;
  godName(ownerId: string): string | undefined;
  /** To the open pages and apps; to the devices by push. */
  deliver(ownerId: string, nudge: GodNudge, godName: string): void;
  now?: () => number;
  /** Minutes east of UTC of the person's clock (default: the server's). */
  offsetMin?: (at: number) => number;
}

/** The facts from the active topics (pure). */
export function nudgeFacts(list: readonly TopicView[], now: number): NudgeFacts {
  const days = (iso: string | null, created: string) =>
    Math.floor((now - Date.parse(iso ?? created)) / DAY);
  const facts: NudgeFacts = { waiting: [], stalled: [], left: [] };
  for (const t of list) {
    if (t.archived) continue;
    const d = days(t.lastAt, t.createdAt);
    if (t.state === "waiting") facts.waiting.push({ id: t.id, title: t.title });
    else if (t.tasks > 0 && d >= STALLED_DAYS)
      facts.stalled.push({ id: t.id, title: t.title, days: d });
    else if (t.tasks === 0 && !t.pinned && d >= LEFT_DAYS)
      facts.left.push({ id: t.id, title: t.title, days: d });
  }
  // The oldest first: what waits longest comes first.
  const age = (id: string) => {
    const t = list.find((x) => x.id === id);
    return t ? Date.parse(t.lastAt ?? t.createdAt) : 0;
  };
  facts.waiting.sort((a, b) => age(a.id) - age(b.id));
  facts.stalled.sort((a, b) => b.days - a.days);
  facts.left.sort((a, b) => b.days - a.days);
  return facts;
}

export class NudgeService {
  constructor(private readonly h: NudgeHost) {}

  private now() {
    return this.h.now?.() ?? Date.now();
  }

  private offset(at: number) {
    return this.h.offsetMin?.(at) ?? -new Date(at).getTimezoneOffset();
  }

  private async read(ownerId: string, key: string): Promise<unknown> {
    const [r] = await this.h.db.query<{ value: unknown }>(
      "SELECT value FROM rg_settings WHERE owner_id = $1 AND key = $2",
      [ownerId, key],
    );
    return r ? settingValue(r.value) : undefined;
  }

  private async write(ownerId: string, key: string, value: unknown): Promise<void> {
    await this.h.db.query(
      `INSERT INTO rg_settings (owner_id, key, value) VALUES ($1, $2, $3)
       ON CONFLICT (owner_id, key) DO UPDATE SET value = EXCLUDED.value`,
      [ownerId, key, JSON.stringify(value)],
    );
  }

  async settings(ownerId: string): Promise<NudgeSettings> {
    const s = NudgeSettings.safeParse(await this.read(ownerId, SETTINGS_KEY));
    return s.success ? s.data : DEFAULT_NUDGE_SETTINGS;
  }

  async setSettings(ownerId: string, s: NudgeSettings): Promise<void> {
    await this.write(ownerId, SETTINGS_KEY, NudgeSettings.parse(s));
  }

  /** When the last nudge went (ms), or null. */
  async last(ownerId: string): Promise<number | null> {
    const v = await this.read(ownerId, LAST_KEY);
    return typeof v === "number" ? v : null;
  }

  /** The periodic check: sends the nudge when one is due. What went, or null. */
  async tick(ownerId: string, at?: number): Promise<GodNudge | null> {
    const now = at ?? this.now();
    const god = this.h.godName(ownerId);
    if (!god) return null;
    const offset = this.offset(now);
    if (!nudgeDue(now, offset, await this.last(ownerId), await this.settings(ownerId))) return null;
    const facts = nudgeFacts(await this.h.topics(ownerId), now);
    const day = Math.round(Date.parse(localDay(now, offset)) / DAY);
    const picked = pickNudge(facts, this.h.language(ownerId), day);
    const hour = new Date(now + offset * 60_000).getUTCHours();
    if (picked.kind === "greeting" && hour >= GREETING_UNTIL) return null;
    const nudge: GodNudge = {
      id: `${localDay(now, offset)}-${picked.kind}`,
      ...picked,
      at: new Date(now).toISOString(),
    };
    await this.write(ownerId, LAST_KEY, now);
    this.h.deliver(ownerId, nudge, god);
    return nudge;
  }
}

import { z } from "zod";

/**
 * God's friendly nudges (3.12.1): at most one a day (or less, as the person chooses), never at
 * night, tied to real facts (a topic waiting for the person, a task stalled, a topic left for
 * days), else a morning greeting. The sentences come from a fixed list in it and en, filled with
 * real data: no model is asked. A nudge is a notification, never a request: it asks no permission
 * and waits for nothing, and it is never written into a topic's history (a generic one opens the
 * simple screen; a topic is made only when the person writes).
 */

/** How often: once a day at most, every other day, once a week. */
export const NudgeEvery = z.enum(["day", "two_days", "week"]);
export type NudgeEvery = z.infer<typeof NudgeEvery>;

export const NudgeSettings = z.object({
  on: z.boolean(),
  every: NudgeEvery,
});
export type NudgeSettings = z.infer<typeof NudgeSettings>;

export const DEFAULT_NUDGE_SETTINGS: NudgeSettings = { on: true, every: "day" };

/** The hours a nudge may come (local time, from inclusive to exclusive): never at night. */
export const NUDGE_HOURS = { from: 9, to: 20 } as const;

/** What it is about: a topic waiting, a task stalled, a topic left, or just a greeting. */
export const NudgeKind = z.enum(["waiting", "stalled", "left", "greeting"]);
export type NudgeKind = z.infer<typeof NudgeKind>;

export const GodNudge = z.object({
  id: z.string(),
  kind: NudgeKind,
  /** The topic it is about; null for a greeting (it opens only the screen with the invitation). */
  topicId: z.string().nullable(),
  /** The sentence, in the person's language. */
  text: z.string(),
  at: z.string(),
});
export type GodNudge = z.infer<typeof GodNudge>;

/** The real facts a nudge may speak of. */
export interface NudgeFacts {
  /** Topics with something waiting for the person (oldest first). */
  waiting: { id: string; title: string }[];
  /** Topics whose open tasks have not moved for days. */
  stalled: { id: string; title: string; days: number }[];
  /** Topics nobody touched for days (not archived yet). */
  left: { id: string; title: string; days: number }[];
}

const DAY = 86_400_000;
const EVERY_DAYS: Record<NudgeEvery, number> = { day: 1, two_days: 2, week: 7 };

/** The local day of a time, as YYYY-MM-DD (offset: minutes east of UTC). */
export function localDay(ms: number, offsetMin: number): string {
  return new Date(ms + offsetMin * 60_000).toISOString().slice(0, 10);
}

/**
 * Whether a nudge may go now (pure): switched on, inside the hours, and enough local days since
 * the last one (`day`: not twice in the same day).
 */
export function nudgeDue(
  now: number,
  offsetMin: number,
  last: number | null,
  s: NudgeSettings,
): boolean {
  if (!s.on) return false;
  const hour = new Date(now + offsetMin * 60_000).getUTCHours();
  if (hour < NUDGE_HOURS.from || hour >= NUDGE_HOURS.to) return false;
  if (last === null) return true;
  const days = Math.round(
    (Date.parse(localDay(now, offsetMin)) - Date.parse(localDay(last, offsetMin))) / DAY,
  );
  return days >= EVERY_DAYS[s.every];
}

/** The fixed sentences ({t}: a topic's title, {d}: days). Some of each, so they vary by day. */
export const NUDGE_WORDS: Record<"it" | "en", Record<NudgeKind, readonly string[]>> = {
  it: {
    waiting: [
      "Hai del lavoro in sospeso, sai? «{t}» aspetta una tua risposta.",
      "Quando hai un minuto: «{t}» aspetta te.",
      "Ti ricordo «{t}»: manca solo una tua parola.",
    ],
    stalled: [
      "«{t}» è fermo da {d} giorni. Diamo un'occhiata insieme?",
      "Il lavoro su «{t}» non va avanti da {d} giorni: vuoi che lo riprendiamo?",
    ],
    left: [
      "Non parliamo di «{t}» da {d} giorni. Lo riprendiamo?",
      "«{t}» è lì da {d} giorni. Andiamo avanti o lo mettiamo in archivio?",
    ],
    greeting: [
      "Buongiorno! A cosa lavoriamo oggi?",
      "Eccomi. Cosa facciamo di bello oggi?",
      "Ciao! Hai qualcosa in mente per oggi?",
    ],
  },
  en: {
    waiting: [
      "You have work waiting, you know? «{t}» is waiting for your answer.",
      "When you have a minute: «{t}» is waiting for you.",
      "A reminder about «{t}»: it only needs a word from you.",
    ],
    stalled: [
      "«{t}» has not moved for {d} days. Shall we look at it together?",
      "The work on «{t}» has stood still for {d} days: shall we pick it up?",
    ],
    left: [
      "We have not talked about «{t}» for {d} days. Shall we pick it up?",
      "«{t}» has been there for {d} days. Carry on, or put it in the archive?",
    ],
    greeting: [
      "Good morning! What are we working on today?",
      "Here I am. What shall we do today?",
      "Hi! Anything in mind for today?",
    ],
  },
};

/**
 * The nudge for the facts (pure): a topic waiting first, then a stalled one, then one left for
 * days, else a greeting. [day] picks among the sentences (they change from day to day).
 */
export function pickNudge(
  facts: NudgeFacts,
  lang: string,
  day: number,
): { kind: NudgeKind; topicId: string | null; text: string } {
  const words = NUDGE_WORDS[lang.toLowerCase().startsWith("it") ? "it" : "en"];
  const say = (kind: NudgeKind, t = "", d = 0) => {
    const list = words[kind];
    const s = list[Math.abs(day) % list.length] as string;
    return s.replace("{t}", t).replace("{d}", String(d));
  };
  const w = facts.waiting[0];
  if (w) return { kind: "waiting", topicId: w.id, text: say("waiting", w.title) };
  const st = facts.stalled[0];
  if (st) return { kind: "stalled", topicId: st.id, text: say("stalled", st.title, st.days) };
  const l = facts.left[0];
  if (l) return { kind: "left", topicId: l.id, text: say("left", l.title, l.days) };
  return { kind: "greeting", topicId: null, text: say("greeting") };
}

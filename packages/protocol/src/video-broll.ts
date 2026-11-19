// The rules of the cutaways ("B" clips) over the speech (G41.6), ported from montatore's
// `DirectionRules`, `InsertValidator` and `InsertRepairer` (tests/Unit/Direction). Pure: times
// are seconds of the program (the speech one after the other, silences cut), a B is named by its
// path. `validateInserts` only lists what breaks a rule (on a timeline the person made they warn,
// never block: montatore's D17, the last word is the person's); `repairInserts` brings any list
// (the automatic draft, an agent's direction) to one that keeps every rule, fixing where it can
// and dropping where it cannot, and says what it did.

/** Share of the speech (after the opening seconds) covered by B clips, by density. */
export const BROLL_COVERAGE = { low: 0.15, medium: 0.3, high: 0.45 } as const;
export type BrollCoverage = keyof typeof BROLL_COVERAGE;

export interface BrollRules {
  /** Seconds: the shortest and longest insert. */
  minLen: number;
  maxLen: number;
  /** Seconds at the start that stay on the speaker. */
  introHold: number;
  /** Seconds of speaker at least between two inserts. */
  minGap: number;
  coverage: BrollCoverage;
}

/** montatore's defaults: 2–7 s, 5 s held at the start, 3 s between, medium coverage. */
export function brollRules(o: Partial<BrollRules> = {}): BrollRules {
  return { minLen: 2, maxLen: 7, introHold: 5, minGap: 3, coverage: "medium", ...o };
}

/** Seconds of B wanted on a program `duration` long. */
export const brollTargetSeconds = (r: BrollRules, duration: number): number =>
  Math.max(0, duration - r.introHold) * (BROLL_COVERAGE[r.coverage] ?? BROLL_COVERAGE.medium);

/** How many inserts are wanted, at the average length. */
export const brollTargetCount = (r: BrollRules, duration: number): number =>
  Math.round(brollTargetSeconds(r, duration) / Math.max(0.5, (r.minLen + r.maxLen) / 2));

/** A B may be used twice only when there are not enough different ones for the coverage. */
export const brollAllowsReuse = (r: BrollRules, duration: number, catalogSize: number): boolean =>
  catalogSize < brollTargetCount(r, duration);

/** A B as the rules see it: a picture has no length; `parts` are its good stretches (seconds). */
export interface BrollItem {
  id: string;
  still: boolean;
  /** Seconds; null for a picture. */
  duration: number | null;
  /** Good stretches [start, end]; absent or empty: the whole clip. */
  parts?: readonly (readonly [number, number])[];
}

/** One insert, in program time: which B, from when to when, from which point of the B. */
export interface BrollInsert {
  b: string;
  start: number;
  end: number;
  /** Where it starts in the B (seconds). */
  bIn: number;
  /** Why (an agent's reason, the words it covers). */
  reason?: string;
}

/** A word of the program (seconds). */
export interface ProgramWord {
  start: number;
  end: number;
}

export type BrollViolationCode =
  | "unknown_b"
  | "bad_range"
  | "out_of_range"
  | "intro"
  | "too_short"
  | "too_long"
  | "exceeds_b"
  | "splits_word"
  | "overlap"
  | "gap"
  | "reused_b";

export interface BrollViolation {
  code: BrollViolationCode;
  /** The insert's index in the list given. */
  index: number;
  message: string;
}

export interface BrollAction {
  /** "snapped", "clamped", "shortened", "lengthened", "b_in", "shortened_prev", "gap", "dropped_<violation>". */
  code: string;
  message: string;
}

/** Tolerance on times (a frame at 60 fps is 0.016 s). */
export const BROLL_EPS = 0.01;
const EPS = BROLL_EPS;

const partsOf = (b: BrollItem): (readonly [number, number])[] =>
  b.still ? [] : b.parts?.length ? [...b.parts] : [[0, b.duration ?? 0]];

/** The longest insert a B gives: its longest good part (a picture: no limit). */
export function longestPart(b: BrollItem): number {
  if (b.still) return Number.POSITIVE_INFINITY;
  return Math.max(0, ...partsOf(b).map(([s, e]) => e - s));
}

function partContaining(b: BrollItem, bIn: number, len: number): boolean {
  return partsOf(b).some(([s, e]) => bIn >= s - EPS && bIn + len <= e + EPS);
}

/** The start in the B for an insert `len` long, nearest `bIn`, inside a good part long enough. */
export function fitBIn(b: BrollItem, bIn: number, len: number): number | undefined {
  if (b.still) return 0;
  let best: number | undefined;
  for (const [s, e] of partsOf(b)) {
    if (e - s < len - 0.001) continue;
    const c = Math.min(Math.max(bIn, s), e - len);
    if (best === undefined || Math.abs(c - bIn) < Math.abs(best - bIn)) best = c;
  }
  return best === undefined ? undefined : round3(best);
}

const round3 = (n: number) => Math.round(n * 1000) / 1000;
const sec = (s: number) => `${s.toFixed(1)} s`;
const label = (i: BrollInsert) => `B ${i.b} (${i.start.toFixed(1)}–${i.end.toFixed(1)} s)`;

/** The words of the program, sorted; a moment inside one, its boundaries. */
export class ProgramScript {
  readonly words: readonly ProgramWord[];
  private readonly bounds: number[];
  constructor(words: readonly ProgramWord[]) {
    this.words = [...words].sort((a, b) => a.start - b.start);
    this.bounds = [...new Set(this.words.flatMap((w) => [w.start, w.end]))].sort((a, b) => a - b);
  }
  /** The word holding the moment (its ends excluded), if any. */
  wordAt(t: number): ProgramWord | undefined {
    for (const w of this.words) {
      if (t > w.start + 1e-6 && t < w.end - 1e-6) return w;
      if (w.start > t) break;
    }
    return undefined;
  }
  boundaries(): readonly number[] {
    return this.bounds;
  }
}

interface Ctx {
  rules: BrollRules;
  catalog: ReadonlyMap<string, BrollItem>;
  script: ProgramScript;
  duration: number;
}

const ctxOf = (
  rules: BrollRules,
  catalog: readonly BrollItem[],
  words: readonly ProgramWord[] | ProgramScript,
  duration: number,
): Ctx => ({
  rules,
  catalog: new Map(catalog.map((b) => [b.id, b])),
  script: words instanceof ProgramScript ? words : new ProgramScript(words),
  duration,
});

const MESSAGES: Record<BrollViolationCode, string> = {
  unknown_b: "the B is not among the coverage files",
  bad_range: "its times are not valid",
  out_of_range: "it goes outside the video",
  intro: "it falls in the opening seconds, which stay on the speaker",
  too_short: "it is shorter than the shortest insert",
  too_long: "it is longer than the longest insert",
  exceeds_b: "it goes past the B's good parts",
  splits_word: "it starts or ends in the middle of a word",
  overlap: "it overlaps the insert before",
  gap: "it is too close to the insert before",
  reused_b: "the B is used again although there are enough different ones",
};

/** What breaks the rules in a list of inserts (in any order); nothing is changed. */
export function validateInserts(
  rules: BrollRules,
  catalog: readonly BrollItem[],
  words: readonly ProgramWord[] | ProgramScript,
  duration: number,
  inserts: readonly BrollInsert[],
): BrollViolation[] {
  return validateIn(ctxOf(rules, catalog, words, duration), inserts);
}

function validateIn(c: Ctx, inserts: readonly BrollInsert[]): BrollViolation[] {
  const v: BrollViolation[] = [];
  const add = (code: BrollViolationCode, index: number, extra = "") =>
    v.push({
      code,
      index,
      message: `${label(inserts[index] as BrollInsert)}: ${MESSAGES[code]}${extra}`,
    });
  const order = inserts
    .map((_, i) => i)
    .sort((a, b) => (inserts[a]?.start ?? 0) - (inserts[b]?.start ?? 0));
  const reuse = brollAllowsReuse(c.rules, c.duration, c.catalog.size);
  const used = new Set<string>();
  let prev: BrollInsert | undefined;
  for (const i of order) {
    const ins = inserts[i] as BrollInsert;
    const b = c.catalog.get(ins.b);
    const len = ins.end - ins.start;
    if (!b) add("unknown_b", i);
    if (!(len > 0)) {
      add("bad_range", i);
      continue;
    }
    if (ins.start < -EPS || ins.end > c.duration + EPS) add("out_of_range", i);
    if (ins.start < c.rules.introHold - EPS) add("intro", i);
    if (len < c.rules.minLen - EPS) add("too_short", i, ` (${sec(len)})`);
    if (len > c.rules.maxLen + EPS) add("too_long", i, ` (${sec(len)})`);
    if (b && !b.still && !partContaining(b, ins.bIn, len)) add("exceeds_b", i);
    if (c.script.wordAt(ins.start) || c.script.wordAt(ins.end)) add("splits_word", i);
    if (prev) {
      if (ins.start < prev.end - EPS) add("overlap", i);
      else if (ins.start - prev.end < c.rules.minGap - EPS)
        add("gap", i, ` (at least ${sec(c.rules.minGap)} of speaker between)`);
    }
    if (!reuse && used.has(ins.b)) add("reused_b", i);
    used.add(ins.b);
    if (!prev || ins.end > prev.end) prev = ins;
  }
  return v;
}

/**
 * Any list of inserts made into one that keeps every rule; never fails (at worst fewer inserts).
 * Steps as montatore's: unknown Bs → the video's limits and the opening seconds → word boundaries
 * → length (min/max and the B's longest good part) → the start inside a good part → overlaps and
 * gaps (the end of the one before is shortened first, D22) → reused Bs → the validator as a net.
 */
export function repairInserts(
  rules: BrollRules,
  catalog: readonly BrollItem[],
  words: readonly ProgramWord[] | ProgramScript,
  duration: number,
  inserts: readonly BrollInsert[],
): { inserts: BrollInsert[]; actions: BrollAction[] } {
  const c = ctxOf(rules, catalog, words, duration);
  const actions: BrollAction[] = [];
  const drop = (code: string, ins: BrollInsert, why: string): undefined => {
    actions.push({ code: `dropped_${code}`, message: `dropped ${label(ins)}: ${why}` });
    return undefined;
  };
  const note = (code: string, ins: BrollInsert, what: string) =>
    actions.push({ code, message: `${label(ins)}: ${what}` });
  const r = c.rules;

  /** A moment in [lo, hi] outside every word, nearest `desired`. */
  const pick = (lo: number, hi: number, desired: number): number | undefined => {
    if (hi < lo - EPS) return undefined;
    const cands = c.script.boundaries().filter((b) => b >= lo - EPS && b <= hi + EPS);
    for (const t of [desired, lo, hi])
      if (t >= lo - EPS && t <= hi + EPS && !c.script.wordAt(t)) cands.push(t);
    if (!cands.length) return undefined;
    cands.sort((a, b) => Math.abs(a - desired) - Math.abs(b - desired));
    return round3(Math.min(Math.max(cands[0] as number, lo), hi));
  };
  const snapStart = (t: number) => {
    const w = c.script.wordAt(t);
    return !w ? t : w.start >= r.introHold - EPS ? w.start : w.end;
  };
  const snapEnd = (t: number) => {
    const w = c.script.wordAt(t);
    return w ? Math.min(w.end, c.duration) : t;
  };

  const fixOne = (raw: BrollInsert): BrollInsert | undefined => {
    const ins = { ...raw };
    const b = c.catalog.get(ins.b);
    if (!b) return drop("unknown_b", ins, "it is not among the coverage files");
    if (!Number.isFinite(ins.start) || !Number.isFinite(ins.end) || ins.end <= ins.start)
      return drop("bad_range", ins, "its times are not valid");
    const lo = r.introHold;
    if (ins.start < lo - EPS || ins.end > c.duration + EPS) {
      ins.start = Math.max(ins.start, lo);
      ins.end = Math.min(ins.end, c.duration);
      if (ins.end - ins.start <= EPS)
        return drop("intro", ins, "it falls wholly in the opening seconds or outside the video");
      note("clamped", ins, "moved inside the limits (opening seconds or end of the video)");
    }
    const s = snapStart(ins.start);
    const e = snapEnd(ins.end);
    if (Math.abs(s - ins.start) > EPS || Math.abs(e - ins.end) > EPS) {
      ins.start = s;
      ins.end = e;
      note("snapped", ins, "put on the words' boundaries");
    }
    const maxLen = Math.min(r.maxLen, longestPart(b));
    if (maxLen < r.minLen - EPS)
      return drop(
        "exceeds_b",
        ins,
        "the B (or its longest good part) is shorter than the shortest insert",
      );
    const len = ins.end - ins.start;
    if (len > maxLen + EPS || len < r.minLen - EPS) {
      const desired = len > maxLen ? ins.start + maxLen : ins.start + r.minLen;
      const end = pick(ins.start + r.minLen, Math.min(ins.start + maxLen, c.duration), desired);
      if (end === undefined) {
        // At the end of the video: the start comes earlier.
        const start = pick(Math.max(lo, ins.end - maxLen), ins.end - r.minLen, ins.end - r.minLen);
        if (start === undefined || c.script.wordAt(ins.end))
          return drop("too_short", ins, "there is no room for the shortest insert");
        ins.start = start;
      } else ins.end = end;
      note(
        len > maxLen ? "shortened" : "lengthened",
        ins,
        `${len > maxLen ? "shortened" : "lengthened"} to stay between ${sec(r.minLen)} and ${sec(maxLen)}`,
      );
    }
    if (b.still) ins.bIn = 0;
    else if (!partContaining(b, ins.bIn, ins.end - ins.start)) {
      const bIn = fitBIn(b, Number.isFinite(ins.bIn) ? ins.bIn : 0, ins.end - ins.start);
      if (bIn === undefined) return drop("exceeds_b", ins, "no good part of the B is long enough");
      ins.bIn = bIn;
      note("b_in", ins, "the part of the B moved inside a good part");
    }
    return ins;
  };

  let out = inserts.flatMap((i) => fixOne(i) ?? []).sort((a, b) => a.start - b.start);
  // Overlaps and gaps: each insert starts on its word, so the end of the one before goes first.
  const kept: BrollInsert[] = [];
  for (const ins of out) {
    const prev = kept.at(-1);
    if (prev && ins.start < prev.end + r.minGap - EPS) {
      const latest = ins.start - r.minGap;
      const end = pick(prev.start + r.minLen, latest, latest);
      if (end !== undefined) {
        prev.end = end;
        note(
          "shortened_prev",
          prev,
          `shortened at the end to leave ${sec(r.minGap)} of speaker before ${label(ins)}`,
        );
        kept.push(ins);
        continue;
      }
      const earliest = prev.end + r.minGap;
      const start = pick(earliest, ins.end - r.minLen, earliest);
      if (start === undefined) {
        drop(
          ins.start < prev.end ? "overlap" : "gap",
          ins,
          `too close to ${label(prev)} and cannot be shortened`,
        );
        continue;
      }
      ins.start = start;
      note(
        "gap",
        ins,
        `shortened at the start to leave ${sec(r.minGap)} of speaker after ${label(prev)}`,
      );
    }
    kept.push(ins);
  }
  out = kept;
  if (!brollAllowsReuse(r, c.duration, c.catalog.size)) {
    const used = new Set<string>();
    out = out.filter((ins) => {
      if (used.has(ins.b)) {
        drop("reused_b", ins, "the B is used already and there are enough different ones");
        return false;
      }
      used.add(ins.b);
      return true;
    });
  }
  // The last defence: what the validator still refuses goes (it should not happen).
  for (let round = 0; round < 5; round++) {
    const v = validateIn(c, out);
    if (!v.length) break;
    const bad = new Set(v.map((x) => x.index));
    for (const x of v)
      actions.push({ code: `dropped_${x.code}`, message: `dropped: ${x.message}` });
    out = out.filter((_, i) => !bad.has(i));
  }
  return { inserts: out, actions };
}

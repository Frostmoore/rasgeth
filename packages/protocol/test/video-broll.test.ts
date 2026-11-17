// The B rules (G41.6) as tables, from montatore's tests/Unit/Direction: a 60 s program with a
// word every half second ("p0" 0.0–0.4, "p1" 0.5–0.9, …); coverage: eight 10 s clips (b1…b8), a
// short one of 1.5 s, a picture, a 20 s clip whose good parts are 2–5 and 12–18.
import { describe, expect, it } from "vitest";
import {
  type BrollInsert,
  type BrollItem,
  brollAllowsReuse,
  brollRules,
  brollTargetCount,
  fitBIn,
  repairInserts,
  validateInserts,
} from "../src/index.js";

const rules = brollRules();
const words = (duration = 60) =>
  Array.from({ length: Math.ceil(duration / 0.5) }, (_, i) => ({
    start: i * 0.5,
    end: i * 0.5 + 0.4,
  }));
const catalog = (videos = 8): BrollItem[] => [
  ...Array.from({ length: videos }, (_, i) => ({ id: `b${i + 1}`, still: false, duration: 10 })),
  { id: "short", still: false, duration: 1.5 },
  { id: "photo", still: true, duration: null },
  {
    id: "port",
    still: false,
    duration: 20,
    parts: [
      [2, 5],
      [12, 18],
    ] as [number, number][],
  },
];
const ins = (b: string, start: number, end: number, bIn = 0): BrollInsert => ({
  b,
  start,
  end,
  bIn,
});
const codes = (list: BrollInsert[], cat = catalog()) =>
  validateInserts(rules, cat, words(), 60, list).map((v) => v.code);

function repair(list: BrollInsert[], cat = catalog(), duration = 60) {
  const out = repairInserts(rules, cat, words(duration), duration, list);
  // Whatever goes in, what comes out keeps every rule.
  expect(validateInserts(rules, cat, words(duration), duration, out.inserts)).toEqual([]);
  return out;
}
const spans = (o: { inserts: BrollInsert[] }) => o.inserts.map((i) => [i.b, i.start, i.end, i.bIn]);
const acts = (o: { actions: { code: string }[] }) => o.actions.map((a) => a.code);

describe("brollRules", () => {
  it.each([
    ["low", 60, 2],
    ["medium", 60, 4],
    ["high", 60, 6],
    ["medium", 5, 0],
  ] as const)("coverage %s on %d s wants %d inserts", (coverage, duration, n) => {
    expect(brollTargetCount(brollRules({ coverage }), duration)).toBe(n);
  });
  it("reuse only when there are not enough different Bs", () => {
    expect(brollAllowsReuse(rules, 60, 11)).toBe(false);
    expect(brollAllowsReuse(rules, 60, 2)).toBe(true);
  });
  it.each([
    [0, 6, 12],
    [3, 2.5, 2.5],
    [14, 3, 14],
    [0, 7, undefined],
  ] as const)("fitBIn on the port clip from %d for %d s gives %s", (bIn, len, want) => {
    const port = catalog().find((b) => b.id === "port") as BrollItem;
    expect(fitBIn(port, bIn, len)).toBe(want);
  });
});

describe("validateInserts", () => {
  it.each<[string, BrollInsert[], string[]]>([
    ["a good list", [ins("b1", 5, 9.5), ins("photo", 13, 18), ins("b2", 21, 27.5, 3)], []],
    ["unknown B", [ins("zz", 10, 13)], ["unknown_b"]],
    ["bad range", [ins("b1", 13, 10)], ["bad_range"]],
    ["intro", [ins("b1", 3, 7)], ["intro"]],
    ["out of range", [ins("b1", 57, 61)], ["out_of_range"]],
    ["too short", [ins("b1", 10, 11)], ["too_short"]],
    ["too long", [ins("b1", 10, 18)], ["too_long"]],
    ["exceeds the B", [ins("b1", 10, 15, 6)], ["exceeds_b"]],
    ["too short and exceeds", [ins("short", 10, 11.95)], ["too_short", "exceeds_b"]],
    ["splits a word at the start", [ins("b1", 10.2, 14)], ["splits_word"]],
    ["splits a word at the end", [ins("b1", 10, 14.2)], ["splits_word"]],
    ["inside a good part", [ins("port", 10, 14.5, 12.5)], []],
    ["across good parts", [ins("port", 10, 14.5, 4)], ["exceeds_b"]],
    ["overlap", [ins("b1", 10, 15), ins("b2", 14, 18)], ["overlap"]],
    ["gap", [ins("b1", 10, 15), ins("b2", 16, 20)], ["gap"]],
    ["far enough", [ins("b1", 10, 15), ins("b2", 18, 22)], []],
    ["order does not count", [ins("b2", 16, 20), ins("b1", 10, 15)], ["gap"]],
    ["reused with enough Bs", [ins("b1", 10, 15), ins("b1", 20, 25, 5)], ["reused_b"]],
  ])("%s", (_, list, want) => {
    expect(codes(list)).toEqual(want);
  });
  it("reuse is fine with only two Bs", () => {
    expect(codes([ins("b1", 10, 15), ins("b1", 20, 25, 5)], catalog().slice(0, 2))).toEqual([]);
  });
});

describe("repairInserts", () => {
  it.each<[string, BrollInsert[], (string | number)[][], string[]]>([
    [
      "a valid list passes untouched",
      [ins("b1", 10, 14.5), ins("b2", 20, 24.5)],
      [
        ["b1", 10, 14.5, 0],
        ["b2", 20, 24.5, 0],
      ],
      [],
    ],
    [
      "unknown and bad ranges dropped",
      [ins("zz", 10, 14), ins("b1", 14, 10), ins("b1", Number.NaN, 12)],
      [],
      ["dropped_unknown_b", "dropped_bad_range", "dropped_bad_range"],
    ],
    ["words are not split", [ins("b1", 10.2, 14.2)], [["b1", 10, 14.4, 0]], ["snapped"]],
    ["too short is lengthened", [ins("b1", 10, 10.9)], [["b1", 10, 12, 0]], ["lengthened"]],
    ["never longer than the B", [ins("b1", 10, 16, 7)], [["b1", 10, 16, 4]], ["b_in"]],
    ["a B shorter than the minimum", [ins("short", 10, 12)], [], ["dropped_exceeds_b"]],
    ["pictures start at 0", [ins("photo", 10, 16, 3)], [["photo", 10, 16, 0]], []],
    ["inside the second good part", [ins("port", 10, 14.5, 12.5)], [["port", 10, 14.5, 12.5]], []],
    [
      "moved into the good part that fits",
      [ins("port", 10, 14.5, 6)],
      [["port", 10, 14.5, 12]],
      ["b_in"],
    ],
    ["stays in the first good part", [ins("port", 10, 12.5, 2.5)], [["port", 10, 12.5, 2.5]], []],
    [
      "the next keeps its word, the one before is shortened",
      [ins("b1", 5, 11.5), ins("b2", 14, 18.5)],
      [
        ["b1", 5, 11, 0],
        ["b2", 14, 18.5, 0],
      ],
      ["shortened_prev"],
    ],
    [
      "reused B dropped",
      [ins("b1", 10, 14.5), ins("b1", 30, 34.5, 5)],
      [["b1", 10, 14.5, 0]],
      ["dropped_reused_b"],
    ],
  ])("%s", (_, list, want, wantActs) => {
    const out = repair(list);
    expect(spans(out)).toEqual(want);
    expect(acts(out)).toEqual(wantActs);
  });
  it("the opening stays on the speaker", () => {
    const out = repair([ins("b1", 2, 8.5)]);
    expect(spans(out)).toEqual([["b1", 5, 8.5, 0]]);
    expect(acts(out)).toContain("clamped");
    expect(repair([ins("b1", 0, 4)]).inserts).toEqual([]);
  });
  it("too long is shortened to a word boundary", () => {
    const [i] = repair([ins("b1", 10, 20)]).inserts;
    expect(i?.start).toBe(10);
    expect(i?.end).toBeLessThanOrEqual(17);
    expect(i?.end).toBeGreaterThan(16.5);
  });
  it("seven seconds asked from a six-second good part", () => {
    const [i] = repair([ins("port", 10, 17, 12)]).inserts;
    expect((i?.end ?? 0) - (i?.start ?? 0)).toBeLessThanOrEqual(6.01);
  });
  it("overlaps: the first wins, the second is trimmed or dropped", () => {
    const out = repair([ins("b2", 13, 19.5), ins("b1", 10, 14.5), ins("b3", 20, 21.5)]);
    expect(spans(out)).toEqual([
      ["b1", 10, 14.5, 0],
      ["b2", 17.5, 19.5, 0],
    ]);
    expect(acts(out)).toContain("gap");
    expect(acts(out)).toContain("dropped_gap");
  });
  it("reuse kept with only two Bs", () => {
    expect(
      repair([ins("b1", 10, 14.5), ins("b1", 30, 34.5, 5)], catalog().slice(0, 2)).inserts,
    ).toHaveLength(2);
  });
  it("at the end of the video the start comes earlier", () => {
    const [i] = repair([ins("b1", 59, 63)]).inserts;
    expect(Math.abs((i?.end ?? 0) - 60)).toBeLessThanOrEqual(0.11);
    expect((i?.end ?? 0) - (i?.start ?? 0)).toBeGreaterThanOrEqual(1.99);
  });
  it("garbage in, valid out", () => {
    let seed = 42;
    const rnd = (lo: number, hi: number) => {
      seed = (seed * 1103515245 + 12345) % 2 ** 31;
      return lo + (seed % (hi - lo + 1));
    };
    const ids = catalog()
      .map((b) => b.id)
      .concat("zz");
    const list = Array.from({ length: 60 }, () => {
      const s = rnd(-50, 650) / 10;
      return ins(
        ids[rnd(0, ids.length - 1)] as string,
        s,
        s + rnd(-20, 120) / 10,
        rnd(-20, 120) / 10,
      );
    });
    expect(repair(list).inserts.length).toBeGreaterThan(0);
  });
});

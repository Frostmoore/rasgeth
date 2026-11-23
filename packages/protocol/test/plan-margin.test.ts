import { describe, expect, it } from "vitest";
import { marginLevel, marginText, weeklyMargin } from "../src/plan-margin.js";

const DAY = 86_400_000;
const now = Date.parse("2026-11-23T12:00:00Z");
const resetIn = (days: number) => new Date(now + days * DAY).toISOString();

describe("weeklyMargin", () => {
  it.each([
    ["Officina's case: 87% of the week gone, 70% used", 0.91, 70, 17],
    ["ahead of the pace", 3.5, 54, -4],
    ["exactly on the pace", 3.5, 50, 0],
    ["week just begun", 7, 0, 0],
    ["week almost over, little used", 0.07, 50, 49],
  ])("%s", (_n, days, used, expected) => {
    expect(weeklyMargin({ usedPct: used, resetsAt: resetIn(days) }, now)).toBe(expected);
  });

  it("is null without a usable reset time, a reading or in a window already past", () => {
    expect(weeklyMargin({ usedPct: 10 }, now)).toBeNull();
    expect(weeklyMargin({ usedPct: 10, resetsAt: "nonsense" }, now)).toBeNull();
    expect(weeklyMargin({ usedPct: null, resetsAt: resetIn(2) }, now)).toBeNull();
    expect(weeklyMargin({ usedPct: 10, resetsAt: resetIn(-1) }, now)).toBeNull();
  });

  it("never counts more than the whole week", () => {
    // A reset more than 7 days away (clock skew): elapsed share stays 0.
    expect(weeklyMargin({ usedPct: 5, resetsAt: resetIn(9) }, now)).toBe(-5);
  });
});

describe("marginLevel and marginText", () => {
  it.each([
    [40, "ok"],
    [10, "ok"],
    [9, "warn"],
    [0, "warn"],
    [-1, "err"],
    [-30, "err"],
  ] as const)("margin %i is %s", (m, level) => {
    expect(marginLevel(m)).toBe(level);
  });
  it.each([
    [17, "+17"],
    [-4, "−4"],
    [0, "0"],
  ])("%i is written %s", (m, text) => {
    expect(marginText(m)).toBe(text);
  });
});

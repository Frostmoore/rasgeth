// @vitest-environment jsdom
// 3.9.8: the header's bars of a flat subscription. Before any reading the 5h bar waits with a
// dash; a plan without a 5-hour window (Claude's, on the person's plan) shows only what it has,
// never an empty «5h –» beside its week.

import { describe, expect, it } from "vitest";
import { planBars } from "../src/state.js";

describe("planBars", () => {
  it.each([
    ["nothing read yet", [], [["5h", null]]],
    [
      "Claude without a 5-hour window",
      [
        { id: "7d", label: "7g", usedPct: 2 },
        { id: "model:Fable", label: "Fable", usedPct: 0 },
      ],
      [
        ["7d", 2],
        ["model:Fable", 0],
      ],
    ],
    [
      "both windows, 5h first",
      [
        { id: "7d", label: "7g", usedPct: 1 },
        { id: "5h", label: "5h", usedPct: 1 },
      ],
      [
        ["5h", 1],
        ["7d", 1],
      ],
    ],
  ] as const)("%s", (_name, windows, expected) => {
    expect(planBars([...windows]).map((w) => [w.id, w.usedPct])).toEqual(expected);
  });
});

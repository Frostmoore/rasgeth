// @vitest-environment jsdom
// 3.12.3: the header's plan bars. The 5-hour window is always shown (a dash when empty); the
// 7-day window shows its margin against an even pace next to the percentage and takes its colour
// from the margin, not from the percentage; the tooltip says the reset times and the reading time.
import { cleanup, render } from "@testing-library/preact";
import { afterEach, beforeEach, describe, expect, it } from "vitest";
import { dictionaries, lang } from "../src/i18n.js";
import type { PlanLimits } from "../src/api.js";
import { PlanBars } from "../src/components/PlanBars.js";

const DAY = 86_400_000;
const now = Date.parse("2026-11-23T12:00:00Z");
const plan = (used: number, daysLeft: number): PlanLimits => ({
  provider: "claude-subscription",
  readAt: "2026-11-23T11:58:00Z",
  windows: [
    { id: "7d", label: "7g", usedPct: used, resetsAt: new Date(now + daysLeft * DAY).toISOString() },
    { id: "model:Fable", label: "Fable", usedPct: 0 },
  ],
});

beforeEach(() => {
  lang.value = "en";
});
afterEach(cleanup);

describe("PlanBars", () => {
  it("shows the 5h window as a dash, the week's margin and the model window", () => {
    const { container } = render(<PlanBars plan={plan(70, 0.91)} now={now} />);
    const bars = [...container.querySelectorAll(".limit")];
    expect(bars.map((b) => b.querySelector(".limit-name")?.textContent)).toEqual([
      "5h",
      "7d",
      "Fable",
    ]);
    expect(bars[0]?.querySelector(".limit-num")?.textContent).toBe("–");
    expect(bars[1]?.querySelector(".limit-num")?.textContent).toBe("70%");
    expect(bars[1]?.querySelector(".limit-margin")?.textContent).toBe("+17");
    expect(bars[2]?.querySelector(".limit-margin")).toBeNull();
  });

  it.each([
    ["comfortable: green", 70, 0.91, "limit ", "ok"],
    ["tight: amber", 85, 0.91, "limit medium", "warn"],
    ["over the pace: red, at a low percentage", 40, 3.5, "limit high", "err"],
  ])("the week's colour follows the margin (%s)", (_n, used, left, cls, margin) => {
    const { container } = render(<PlanBars plan={plan(used, left)} now={now} />);
    const week = container.querySelectorAll(".limit")[1];
    expect(week?.className).toBe(cls);
    expect(week?.querySelector(".limit-margin")?.className).toContain(margin);
  });

  it("the tooltip has the reset time and when the plan was read; a missing reading is said", () => {
    const { container } = render(<PlanBars plan={plan(70, 0.91)} now={now} />);
    const tip = container.querySelectorAll(".limit")[1]?.getAttribute("title") ?? "";
    expect(tip).toContain("7d: 70% · +17");
    expect(tip).toContain("Resets ");
    expect(tip).toContain("Plan read ");
    expect(tip).toContain("17 points");
    cleanup();
    const { container: c2 } = render(
      <PlanBars plan={{ provider: "p", windows: [] }} now={now} />,
    );
    expect(c2.querySelector(".limit")?.getAttribute("title")).toContain("not read yet");
  });

  it("a week without a reset time has no margin and keeps the percentage's colour", () => {
    const p = plan(75, 3);
    delete p.windows[0]?.resetsAt;
    const { container } = render(<PlanBars plan={p} now={now} />);
    const week = container.querySelectorAll(".limit")[1];
    expect(week?.querySelector(".limit-margin")).toBeNull();
    expect(week?.className).toBe("limit medium");
  });

  it("every new word exists in both languages", () => {
    for (const k of ["limitResets", "limitReadAt", "limitNotRead", "limitMarginTip"]) {
      expect(dictionaries.en[k as never]).toBeTruthy();
      expect(dictionaries.it[k as never]).toBeTruthy();
    }
  });
});

import type { AgentKind } from "@redgiant/protocol";
import { describe, expect, it } from "vitest";
import { hasOwnMascot, MASCOT_STATES, mascotSpec, subagentSignSvg, THEMES } from "../src/index.js";

// Decision «Mascotte solo per orchestratori e agenti di primo livello» (2026-11-19): only the
// lasting agents have a face of their own; a sub-agent (opened by an agent for one task with
// run_subagent/run_subagents, stopped when the task ends) shows a plain sign instead.
const TABLE: [AgentKind, boolean, boolean][] = [
  // kind, persistent, has its own mascot
  ["god", true, true],
  ["demigod", true, true],
  ["orchestrator", true, true],
  ["agent", true, true],
  ["assistant", true, true],
  ["inspector", true, true],
  ["subagent", false, false],
  // A sub-agent is temporary by construction (the registry forces persistent: false); even a
  // record that says otherwise never gets a face.
  ["subagent", true, false],
  // The first level is decided by the kind, not by the flag: a lasting kind keeps its mascot.
  ["agent", false, true],
  ["orchestrator", false, true],
];

describe("hasOwnMascot", () => {
  it.each(TABLE)("%s (persistent %s) -> %s", (kind, persistent, expected) => {
    expect(hasOwnMascot({ kind, persistent })).toBe(expected);
  });
});

// The sign shown instead (board «segno dei sotto-agenti», choice A, 2026-11-19).
describe("subagentSignSvg", () => {
  const parent = mascotSpec("Coder", "agent");
  it.each(MASCOT_STATES.map((s) => [s]))("draws the ring in the parent's colour (%s)", (state) => {
    const svg = subagentSignSvg(parent, { state, theme: "light", size: 20 });
    const ring = state === "error" ? THEMES.light.err : parent.colors.light.body;
    expect(svg).toContain(`stroke="${ring}"`);
    expect(svg).toContain('width="20"');
    expect(svg).toContain(`st-${state}`);
    expect(svg.includes("spin")).toBe(state === "work");
    expect(svg.includes("pulse")).toBe(state === "think");
    expect(svg.includes(THEMES.light.accent)).toBe(state === "wait");
    expect(svg.includes("M9.8 9.8")).toBe(state === "error");
    // Asleep: the faded ring alone, no dot.
    expect(svg.includes('r="3"')).toBe(state !== "idle" && state !== "error");
  });

  it("is grey without a parent and uses the page's variables without a theme", () => {
    expect(subagentSignSvg(undefined, { theme: "dark" })).toContain(`stroke="${THEMES.dark.dim}"`);
    const page = subagentSignSvg(parent, { state: "work", label: "Tester <1>" });
    expect(page).toContain('class="sgr"');
    expect(page).toContain(`--h:${parent.hue};--c:${parent.chroma}`);
    expect(page).toContain('aria-label="Tester &lt;1&gt;"');
    expect(subagentSignSvg(parent)).toContain('aria-hidden="true"');
  });
});

import type { AgentKind } from "@redgiant/protocol";
import { describe, expect, it } from "vitest";
import { hasOwnMascot } from "../src/scopes.js";

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

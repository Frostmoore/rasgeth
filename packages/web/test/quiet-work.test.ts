// @vitest-environment jsdom
// The quiet line (3.12.8, the person's report: «God lavora ma non appare nulla che mostri che sta lavorando»): when
// the agent works and nothing else on screen shows it, a line says it works, since when and the tool under way.
import type { Event } from "@redgiant/protocol";
import { describe, expect, it } from "vitest";
import { buildItems, quietWork, type SessionView } from "../src/state.js";

let seq = 0;
const ev = (type: string, payload: unknown, sec = seq): Event =>
  ({
    id: `e${++seq}`,
    seq,
    ts: new Date(Date.UTC(2026, 10, 26, 10, 0, sec)).toISOString(),
    ownerId: "me",
    projectId: null,
    agentId: "god",
    sessionId: "s1",
    type,
    payload,
    hash: "",
    prevHash: "",
  }) as unknown as Event;
const answer = (parts: unknown[]) =>
  ev("message.assistant", {
    parts,
    metrics: {
      inputTokens: 10,
      outputTokens: 2,
      cachedReadTokens: 0,
      cacheWriteTokens: 0,
      contextUsed: 12,
      contextWindow: 1000,
      startedAt: "2026-11-26T10:00:00.000Z",
      source: "server",
    },
    costUsd: 0,
    provider: "fake",
    model: "m",
    stopReason: "tool_use",
  });
const view = (events: Event[], over: Partial<SessionView> = {}): SessionView => ({
  events,
  text: "",
  thinking: "",
  state: "running",
  synced: true,
  ...over,
});

describe("the quiet line", () => {
  it("shows while the agent works between steps, timed from its last step", () => {
    seq = 0;
    const events = [ev("message.user", { text: "go" }, 0), answer([{ type: "text", text: "Ok" }])];
    const q = quietWork(view(events), buildItems(events));
    expect(q).toEqual({ since: Date.UTC(2026, 10, 26, 10, 0, 1) });
  });

  it("says which tool is under way when nothing shows it", () => {
    seq = 0;
    const events = [
      ev("message.user", { text: "go" }),
      ev("tool.call", { callId: "c1", tool: "fetch", input: {} }),
    ];
    // Its card is not the last thing on screen (for example a hidden tool): the line names it.
    expect(quietWork(view(events), [])?.tool).toBe("fetch");
  });

  it("stays away when something else shows the work", () => {
    seq = 0;
    const events = [
      ev("message.user", { text: "go" }),
      ev("tool.call", { callId: "c1", tool: "fetch", input: {} }),
    ];
    // the tool's own card, still turning
    expect(quietWork(view(events), buildItems(events))).toBeUndefined();
    // a model request under way, text streaming, a summary, a picture being made
    expect(quietWork(view(events, { call: { since: 0, chars: 0 } }), [])).toBeUndefined();
    expect(quietWork(view(events, { text: "Sto" }), [])).toBeUndefined();
    expect(quietWork(view(events, { compacting: true }), [])).toBeUndefined();
    expect(quietWork(view(events, { drawing: { percent: 10 } }), [])).toBeUndefined();
    // and of course when the agent is not working
    expect(quietWork(view(events, { state: "idle" }), [])).toBeUndefined();
  });

  it("a tool that answered is not under way any more", () => {
    seq = 0;
    const events = [
      ev("tool.call", { callId: "c1", tool: "fetch", input: {} }),
      ev("tool.result", { callId: "c1", ok: false, output: "404" }),
    ];
    expect(quietWork(view(events), [])?.tool).toBeUndefined();
  });
});

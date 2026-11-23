import { describe, expect, it } from "vitest";
import {
  AGENT_SET_IDS,
  AGENT_SETS,
  AgentSpec,
  agentSetOf,
  agentSetsGuidance,
  connectionRefs,
  hasConnectionKind,
  normalizeConnections,
  TOOL_KITS,
  toolEntryOf,
} from "../src/index.js";

describe("agent sets", () => {
  it("has the five sets, once each, in the board's order", () => {
    expect(AGENT_SETS.map((s) => s.id)).toEqual([...AGENT_SET_IDS]);
    expect(AGENT_SET_IDS).toEqual(["researcher", "email", "messages", "sheets", "agenda"]);
  });

  // The table: what each set wants to be connected to and which kits it needs.
  const table: [string, string[], string[]][] = [
    ["researcher", [], ["present"]],
    ["email", ["mailbox"], ["mail"]],
    ["messages", ["chat"], ["mail"]],
    ["sheets", [], ["documents", "canvas"]],
    ["agenda", ["calendar"], ["mail"]],
  ];
  it.each(table)("%s wants %j and needs kits %j", (id, wants, kits) => {
    const s = agentSetOf(id);
    expect([...(s?.wants ?? [])]).toEqual(wants);
    for (const k of kits) expect(s?.kits).toContain(k);
  });

  it("every set is complete, in both languages, with real kits and tools", () => {
    for (const s of AGENT_SETS) {
      for (const w of [s.name, s.description, ...s.examples, ...s.asks.map((a) => a.text)]) {
        expect(w.it.length).toBeGreaterThan(2);
        expect(w.en.length).toBeGreaterThan(2);
      }
      expect(s.examples.length).toBeGreaterThanOrEqual(3);
      expect(s.instructions.length).toBeGreaterThan(100);
      expect(s.asks.length).toBeGreaterThan(0);
      for (const k of s.kits) expect(TOOL_KITS).toContain(k);
      for (const t of s.tools) expect(toolEntryOf(t), `${s.id}: ${t}`).toBeDefined();
    }
  });

  it("the requests that name a tool name a real one", () => {
    expect(agentSetOf("email")?.asks.map((a) => a.by)).toEqual(["mail_send"]);
    expect(agentSetOf("agenda")?.asks.map((a) => a.by)).toEqual(["calendar_create_event"]);
    expect(toolEntryOf("calendar_create_event")).toBeDefined();
    expect(toolEntryOf("chat_send")).toBeDefined();
  });

  it("God's guidance names every set with its phrases", () => {
    const g = agentSetsGuidance();
    for (const s of AGENT_SETS) expect(g).toContain(`"${s.id}"`);
    expect(g).toContain("remind me to call the dentist on Thursday");
  });
});

describe("agent connections", () => {
  it("old MCP names become typed references, without loss or repeats", () => {
    expect(normalizeConnections(["notes", "files", "notes"])).toEqual([
      { kind: "mcp", ref: "notes" },
      { kind: "mcp", ref: "files" },
    ]);
    expect(normalizeConnections("x")).toEqual([]);
  });

  it("takes any number of every kind", () => {
    const many = Array.from({ length: 40 }, (_, i) => ({ kind: "mailbox", ref: `box_${i}` }));
    const list = normalizeConnections([
      ...many,
      { kind: "chat", ref: "telegram" },
      { kind: "calendar", ref: "cal1" },
      { kind: "bogus", ref: "x" },
    ]);
    expect(list).toHaveLength(42);
    expect(connectionRefs(list, "mailbox")).toHaveLength(40);
    expect(hasConnectionKind(list, "calendar")).toBe(true);
    expect(hasConnectionKind(list, "mcp")).toBe(false);
  });

  it("the agent's schema reads both forms", () => {
    const base = {
      id: "a",
      kind: "assistant",
      parentId: null,
      projectId: null,
      persistent: true,
      name: "A",
    };
    const r = AgentSpec.parse({
      ...base,
      connections: ["notes", { kind: "chat", ref: "telegram" }],
    });
    expect(r.connections).toEqual([
      { kind: "mcp", ref: "notes" },
      { kind: "chat", ref: "telegram" },
    ]);
  });
});

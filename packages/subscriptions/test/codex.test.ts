import { mkdtemp } from "node:fs/promises";
import { tmpdir } from "node:os";
import { join } from "node:path";
import type { EngineTurn } from "@redgiant/agent";
import { afterEach, describe, expect, it } from "vitest";
import { ChatgptSubscriptionProvider, codexImage, codexWindows } from "../src/index.js";

const fake = join(import.meta.dirname, "fake-codex.mjs");
let providers: ChatgptSubscriptionProvider[] = [];
afterEach(() => {
  for (const p of providers) p.stop();
  providers = [];
});

async function provider() {
  const home = await mkdtemp(join(tmpdir(), "rg-codex-"));
  const p = new ChatgptSubscriptionProvider({
    home,
    cwd: join(home, "work"),
    command: { file: process.execPath, args: [fake] },
  });
  providers.push(p);
  return p;
}

const turn = (text: string, log: string[]): EngineTurn => ({
  text,
  images: [],
  system: "You are God.",
  tools: [{ name: "read_file", description: "Read", inputSchema: { type: "object" } }],
  model: { provider: "chatgpt-subscription", model: "gpt-6", effort: "max" },
  resume: undefined,
  runTool: async (c) => {
    log.push(`tool ${c.callId} ${c.name} ${JSON.stringify(c.input)}`);
    return { content: "hello", isError: false };
  },
  onMessage: async (m) => {
    log.push(
      `${m.stopReason} ${m.parts.map((p) => (p.type === "text" ? p.text : p.type)).join(",")}`,
    );
  },
});

describe("ChatGPT on a subscription", () => {
  it("runs the turn in Codex with Rasgeth's tools as dynamic tools, and keeps the plan's limits", async () => {
    const p = await provider();
    const log: string[] = [];
    expect(await p.engine.turn(turn("What is in a.txt?", log))).toEqual({
      resume: "th-1",
      stopReason: "end_turn",
    });
    expect(log).toEqual([
      "end_turn thinking",
      "tool_use tool_call",
      'tool call_1 read_file {"path":"a.txt"}',
      "end_turn Tool said hello (true)",
    ]);
    expect(await p.limits()).toEqual([
      { id: "5h", label: "5h", usedPct: 21, resetsAt: "2026-11-02T06:13:20.000Z" },
      { id: "7d", label: "7g", usedPct: 48 },
    ]);
    expect(await p.models()).toEqual(["gpt-6"]);
  });

  it("gives every message, the first turn's too, its own request's usage and Codex's window", async () => {
    const p = await provider();
    expect(p.modelInfo("gpt-6").contextWindow).toBe(272_000);
    const seen: string[] = [];
    await p.engine.turn({
      ...turn("What is in a.txt?", []),
      onMessage: async (m) => {
        const x = m.metrics;
        seen.push(
          `${m.parts[0]?.type} ${x.inputTokens}/${x.cachedReadTokens}/${x.outputTokens} ${x.contextUsed}/${x.contextWindow}`,
        );
      },
    });
    // Codex reports each request's usage after its items and tool calls: read at once, the first
    // messages had none (all zeros, window 272000) and the answer the first request's numbers.
    expect(seen).toEqual([
      "thinking 1200/0/40 1240/475000",
      "tool_call 1200/0/40 1240/475000",
      "text 1400/1000/100 1500/475000",
    ]);
    // The window Codex said is the model's from now on, before any usage of a new thread.
    expect(p.modelInfo("gpt-6").contextWindow).toBe(475_000);
  });

  it("starts the thread with Codex's own shell off and a read-only sandbox", async () => {
    const p = await provider();
    // The fake echoes thread/start's parameters on stderr; read them through the protocol's own answer.
    const started: unknown[] = [];
    const conn = (
      p as unknown as {
        conn: { listeners: Set<unknown>; request: (m: string, x: unknown) => Promise<unknown> };
      }
    ).conn;
    const original = conn.request.bind(conn);
    conn.request = async (m: string, x: unknown) => {
      if (m === "thread/start") started.push(x);
      return original(m, x);
    };
    await p.engine.turn(turn("go", []));
    expect(started[0]).toMatchObject({
      model: "gpt-6",
      approvalPolicy: "never",
      sandbox: "read-only",
      baseInstructions: "You are God.",
      dynamicTools: [{ type: "function", name: "read_file" }],
      config: {
        "features.shell_tool": false,
        "features.unified_exec": false,
        // Codex's own pictures only when the conversation lets it (2026-11-19).
        "features.image_generation": false,
        web_search: "live",
      },
    });
  });

  it("lets Codex draw only when the conversation allows it, and hands over the file it saved", async () => {
    const p = await provider();
    const started: { config: Record<string, unknown> }[] = [];
    const conn = (
      p as unknown as {
        conn: { request: (m: string, x: unknown) => Promise<unknown> };
      }
    ).conn;
    const original = conn.request.bind(conn);
    conn.request = async (m: string, x: unknown) => {
      if (m === "thread/start") started.push(x as { config: Record<string, unknown> });
      return original(m, x);
    };
    const log: string[] = [];
    const made: { path?: string | undefined; prompt?: string | undefined }[] = [];
    const r = await p.engine.turn({
      ...turn("draw", log),
      native: ["image"],
      onNativeStart: async (m) => {
        log.push(`start ${m.id} ${m.kind} ${m.prompt}`);
      },
      onNativeMade: async (m) => {
        log.push(`made ${m.id} ${m.error ?? "ok"}`);
        made.push(m);
      },
    });
    expect(r.stopReason).toBe("end_turn");
    expect(started[0]?.config["features.image_generation"]).toBe(true);
    expect(log).toEqual([
      "end_turn thinking",
      "start ig_1 image A crowned star",
      "made ig_1 ok",
      "end_turn Here it is.",
    ]);
    expect(made[0]?.path).toMatch(/generated_images[/\\]th-1[/\\]ig_1\.png$/);
  });

  it("reads a finished picture: its file, its bytes, or why it failed", () => {
    expect(codexImage("a", { savedPath: "/h/g.png", result: "x" }, "p")).toEqual({
      id: "a",
      kind: "image",
      prompt: "p",
      path: "/h/g.png",
    });
    expect(codexImage("b", { result: "data:image/png;base64,QUJD" }, undefined)).toEqual({
      id: "b",
      kind: "image",
      data: "QUJD",
    });
    expect(
      codexImage("c", { failure: { type: "usageLimitExceeded" }, result: "" }, undefined).error,
    ).toMatch(/limit/);
    expect(codexImage("d", { status: "completed", result: "" }, undefined).error).toMatch(
      /no file/,
    );
  });

  it("reports a failed login as a rejected key, and logs in with a device code", async () => {
    const p = await provider();
    await expect(p.engine.turn(turn("fail", []))).rejects.toMatchObject({ rejectedKey: true });
    const login = await p.login();
    expect([login.url, login.code]).toEqual(["https://auth.openai.com/codex/device", "ABCD-1234"]);
    expect(await login.done).toBe(true);
  });

  it("reads windows from Codex's snapshot", () => {
    expect(
      codexWindows({ primary: { usedPercent: 99.6, windowDurationMins: 300 }, secondary: null }),
    ).toEqual([{ id: "5h", label: "5h", usedPct: 100 }]);
    expect(codexWindows(null)).toEqual([]);
  });
});

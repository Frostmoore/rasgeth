// The model's own generation before ours (2026-11-19). An engine in miniature stands for Codex:
// it "draws" a file in its own folder and says so, as `codex app-server` does; Rasgeth copies it
// into the agent's workspace, sends it with the card and logs it as image_generation. Asked for
// Rasgeth's tool, the same engine calls ours. The engine follows the words it is given (the
// description and the person's text): what is tested is the description and the routing, not a
// model.
import { mkdir, readFile, writeFile } from "node:fs/promises";
import { join } from "node:path";
import type { EngineTurn } from "@redgiant/agent";
import { FakeProvider, ProviderRegistry } from "@redgiant/providers";
import { afterEach, describe, expect, it } from "vitest";
import {
  imageTextHook,
  nativeSection,
  sendFileMissing,
  sniffImage,
  unreachableImages,
} from "../src/native-media.js";
import { startServer, wsClient } from "./helpers.js";

// A 1x1 PNG.
const PNG = Buffer.from(
  "iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mP8z8DwHwAFBQIAX8jx0gAAAABJRU5ErkJggg==",
  "base64",
);

/** A Codex in miniature: draws by itself when it may and nobody asked for Rasgeth's tool. */
class FakeEngineProvider {
  readonly id = "chatgpt-subscription";
  nativeFolder = "";
  /** What each turn was given. */
  readonly seen: { native: readonly string[]; description: string }[] = [];
  readonly engine = {
    id: "chatgpt-subscription",
    turn: async (t: EngineTurn) => {
      const ours = t.tools.find((d) => d.name === "image_generation");
      this.seen.push({ native: t.native ?? [], description: ours?.description ?? "" });
      const explicit = /your tool|Rasgeth's tool/i.test(t.text);
      const metrics = {
        startedAt: new Date().toISOString(),
        endedAt: new Date().toISOString(),
        inputTokens: 1,
        cachedReadTokens: 0,
        cacheWriteTokens: 0,
        outputTokens: 1,
        contextUsed: 2,
        contextWindow: 1000,
        prefillMs: 0,
        decodeMs: 0,
        tokPerSec: 0,
        source: "server" as const,
      };
      if (t.native?.includes("image") && !explicit && /draw/.test(t.text)) {
        await t.onNativeStart?.({ id: "ig_1", kind: "image", prompt: "A red giant star" });
        const dir = join(this.nativeFolder, "th-1");
        await mkdir(dir, { recursive: true });
        const file = join(dir, "ig_1.png");
        await writeFile(file, PNG);
        await t.onNativeMade?.({
          id: "ig_1",
          kind: "image",
          path: file,
          prompt: "A red giant star",
        });
      } else if (/draw/.test(t.text)) {
        await t.onMessage({
          parts: [
            {
              type: "tool_call",
              callId: "c1",
              name: "image_generation",
              input: { prompt: "a star" },
            },
          ],
          stopReason: "tool_use",
          metrics,
          model: t.model.model,
        });
        await t.runTool({ callId: "c1", name: "image_generation", input: { prompt: "a star" } });
      }
      await t.onMessage({
        parts: [{ type: "text", text: "Here it is." }],
        stopReason: "end_turn",
        metrics,
        model: t.model.model,
      });
      return { resume: "th-1", stopReason: "end_turn" as const };
    },
  };
  modelInfo(model: string) {
    return { id: model, contextWindow: 200_000, maxOutputTokens: 8000 };
  }
  // biome-ignore lint/correctness/useYield: the engine runs every turn.
  async *stream(): AsyncIterable<never> {
    throw new Error("engine only");
  }
}

let cleanup: (() => Promise<unknown>)[] = [];
afterEach(async () => {
  for (const c of cleanup) await c();
  cleanup = [];
});

async function server() {
  const engine = new FakeEngineProvider();
  const s = await startServer(
    () => ({ text: "unused" }),
    {},
    {
      providers: new ProviderRegistry()
        .register(new FakeProvider(() => ({ text: "fake" })))
        .register(engine as never),
      defaultModel: { provider: "chatgpt-subscription", model: "gpt-6" },
    },
  );
  cleanup.push(s.close);
  engine.nativeFolder = join(s.core.platformPath("me"), "..", "codex-home", "generated_images");
  const god = await s.api<{ id: string }>("POST", "/api/agents", {
    kind: "god",
    parentId: null,
    name: "God",
  });
  const session = async () =>
    (await s.api<{ sessionId: string }>("POST", "/api/sessions", { agentId: god.body.id })).body
      .sessionId;
  return { s, engine, session };
}

describe("the model's own generation first (2026-11-19)", () => {
  it("copies the engine's picture into the workspace, sends it with the card, logs it as image_generation", async () => {
    const { s, engine, session } = await server();
    const sid = await session();
    const c = await wsClient(s.url);
    cleanup.push(async () => c.close());
    c.send({ type: "session.follow", sessionId: sid });
    await c.waitFor("session.synced");
    await (await s.core.send("me", sid, "draw a red giant")).done;

    // The engine was told it may draw, and our tool says to use it only when asked by name.
    expect(engine.seen[0]?.native).toEqual(["image"]);
    expect(engine.seen[0]?.description).toMatch(/^Your model makes pictures by itself/);
    const log = await s.core.history("me", sid);
    const started = log.find((e) => e.type === "session.started");
    expect(started?.type === "session.started" && started.payload.native).toEqual(["image"]);
    expect(started?.type === "session.started" && started.payload.system).toMatch(
      /## Pictures you make yourself/,
    );
    // Logged as our tool's call and result: the chat shows «generating», then the file.
    const call = log.find((e) => e.type === "tool.call");
    expect(call?.type === "tool.call" && call.payload).toMatchObject({
      callId: "native_ig_1",
      tool: "image_generation",
      input: { prompt: "A red giant star", by: "chatgpt-subscription" },
    });
    const result = log.find((e) => e.type === "tool.result");
    expect(result?.type === "tool.result" && result.payload.ok).toBe(true);
    const rel =
      (result?.type === "tool.result" && result.payload.output.match(/Saved (\S+)/)?.[1]) || "";
    expect(rel).toMatch(/^images\/\d{4}-\d{2}-\d{2}\/\d{6}-a-red-giant-star\.png$/);
    expect(await readFile(join(s.core.platformPath("me"), rel))).toEqual(PNG);
    const sent = log.find((e) => e.type === "file.sent");
    expect(sent?.type === "file.sent" && sent.payload).toMatchObject({
      path: rel,
      mime: "image/png",
      size: PNG.length,
      caption: "A red giant star",
    });
    // Live: the call reaches the page before the file (the «generating» card).
    const live = c.messages.flatMap((m) =>
      m.type === "event" && ["tool.call", "file.sent", "tool.result"].includes(m.event.type)
        ? [m.event.type]
        : [],
    );
    expect(live).toEqual(["tool.call", "file.sent", "tool.result"]);
  });

  it("uses Rasgeth's tool when the person asks for it by name", async () => {
    const { s, engine, session } = await server();
    const sid = await session();
    await (await s.core.send("me", sid, "draw a star, use your tool")).done;
    expect(engine.seen[0]?.native).toEqual(["image"]);
    const log = await s.core.history("me", sid);
    const call = log.find((e) => e.type === "tool.call");
    expect(call?.type === "tool.call" && call.payload.callId).toBe("c1");
    // Our tool ran: not set up here, it says where to set it up.
    const result = log.find((e) => e.type === "tool.result");
    expect(result?.type === "tool.result" && result.payload.output).toMatch(/Not set up yet/);
    expect(log.some((e) => e.type === "file.sent")).toBe(false);
  });

  it("with the setting off, keeps our tool as it was and the engine does not draw; a running conversation keeps its start's choice", async () => {
    const { s, engine, session } = await server();
    const before = await session();
    await (await s.core.send("me", before, "hello")).done;
    s.core.setMedia({ choices: {}, keys: {}, native: false });
    const sid = await session();
    await (await s.core.send("me", sid, "draw a star")).done;
    expect(engine.seen[1]?.native).toEqual([]);
    expect(engine.seen[1]?.description).toMatch(/^Make a picture from a description/);
    const log = await s.core.history("me", sid);
    const started = log.find((e) => e.type === "session.started");
    expect(started?.type === "session.started" && started.payload.system).not.toMatch(
      /Pictures you make yourself/,
    );
    const call = log.find((e) => e.type === "tool.call");
    expect(call?.type === "tool.call" && call.payload.callId).toBe("c1");
    // The conversation started before keeps drawing by itself after a restart of its session.
    s.core.closeIdle(0);
    await (await s.core.send("me", before, "draw it")).done;
    expect(engine.seen.at(-1)?.native).toEqual(["image"]);
  });

  it("refuses a file outside the engine's own folder", async () => {
    const { s, engine, session } = await server();
    const sid = await session();
    const elsewhere = join(s.core.platformPath("me"), "..", "secret.png");
    await writeFile(elsewhere, PNG);
    const real = engine.engine.turn;
    engine.engine.turn = async (t) => {
      await t.onNativeStart?.({ id: "x", kind: "image" });
      await t.onNativeMade?.({ id: "x", kind: "image", path: elsewhere });
      return { resume: "th-1", stopReason: "end_turn" };
    };
    await (await s.core.send("me", sid, "draw")).done;
    engine.engine.turn = real;
    const log = await s.core.history("me", sid);
    const result = log.find((e) => e.type === "tool.result");
    expect(result?.type === "tool.result" && result.payload).toMatchObject({
      ok: false,
      output: expect.stringMatching(/not where it keeps them/),
    });
    expect(log.some((e) => e.type === "file.sent")).toBe(false);
  });
});

describe("pictures the person cannot open (2026-11-19)", () => {
  it("finds pictures by a path in a Markdown answer", () => {
    expect(
      unreachableImages(
        "Eccola: ![gatto](/data/engines/codex/generated_images/a.png) e ![web](https://x.it/a.png) ![](data:image/png;base64,AA) ![rel](images/2026/a.png)",
      ),
    ).toEqual(["/data/engines/codex/generated_images/a.png", "images/2026/a.png"]);
    expect(unreachableImages("niente immagini [link](/a.png)")).toEqual([]);
  });

  it("reminds the agent once per path, as Rasgeth's quiet note", () => {
    const hook = imageTextHook();
    const done = (text: string) =>
      hook({ message: { role: "assistant", parts: [{ type: "text", text }] } } as never, {
        sessionId: "s1",
        ownerId: "me",
        projectId: null,
        agentId: "a",
      });
    const first = done("![x](/tmp/x.png)");
    expect(first).toMatchObject({ quiet: true, text: expect.stringMatching(/send_file/) });
    expect(done("![x](/tmp/x.png)")).toBeUndefined();
    expect(done("all good")).toBeUndefined();
  });

  it("tells send_file's caller what to do with a path outside the workspace", async () => {
    expect(await sendFileMissing("/data/engines/codex/generated_images/t/a.png")).toMatch(
      /already in the chat/,
    );
    expect(await sendFileMissing(import.meta.filename)).toMatch(
      /Save or copy it into your workspace/,
    );
    expect(await sendFileMissing("nope.png")).toMatch(/only from your workspace/);
  });

  it("knows a picture from its bytes and says nothing without a native image", () => {
    expect(sniffImage(PNG)).toBe("image/png");
    expect(sniffImage(Buffer.from([0xff, 0xd8, 0xff, 0xe0]))).toBe("image/jpeg");
    expect(sniffImage(Buffer.from("hello"))).toBe("application/octet-stream");
    expect(nativeSection([])).toBe("");
    expect(nativeSection(["image"])).toMatch(/do not send it again/);
  });
});

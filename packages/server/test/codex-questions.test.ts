// 3.9.5 (Coder, 3.9.3): the Chat on the Codex engine asked about a UPS; the question came out as
// a bulleted text, the turn looked over and Codex went on by itself 9 s later. Now the Chat has
// ask_user, Codex's own questions are off, and a question Codex asks anyway reaches the person as
// Rasgeth's card: the engine waits, the answer goes back through the app-server protocol and the
// turn goes on. The real adapter talks to a `codex app-server` in miniature (fake-codex.mjs).
import { mkdtemp } from "node:fs/promises";
import { tmpdir } from "node:os";
import { join } from "node:path";
import type { Event, QuestionRequestInfo } from "@redgiant/protocol";
import { FakeProvider, ProviderRegistry } from "@redgiant/providers";
import { ChatgptSubscriptionProvider } from "@redgiant/subscriptions";
import { afterEach, describe, expect, it } from "vitest";
import { startServer, wsClient } from "./helpers.js";

const fake = join(import.meta.dirname, "..", "..", "subscriptions", "test", "fake-codex.mjs");

let cleanup: (() => Promise<unknown> | unknown)[] = [];
afterEach(async () => {
  for (const c of cleanup.reverse()) await c();
  cleanup = [];
});

async function server() {
  const home = await mkdtemp(join(tmpdir(), "rg-codex-q-"));
  const codex = new ChatgptSubscriptionProvider({
    home,
    cwd: join(home, "work"),
    command: { file: process.execPath, args: [fake] },
  });
  cleanup.push(() => codex.stop());
  const s = await startServer(
    () => ({ text: "unused" }),
    {},
    {
      providers: new ProviderRegistry()
        .register(new FakeProvider(() => ({ text: "fake" })))
        .register(codex),
      defaultModel: { provider: "chatgpt-subscription", model: "gpt-6" },
    },
  );
  cleanup.push(s.close);
  await s.api("POST", "/api/agents", { kind: "god", parentId: null, name: "God" });
  const chat = (await s.core.chatAgent("me")).id;
  const sid = await s.core.startSession("me", chat);
  return { s, sid };
}

describe("a question from the Codex engine (3.9.5)", () => {
  it("shows the card, waits for the person, hands the answer back and goes on", async () => {
    const { s, sid } = await server();
    const c = await wsClient(s.url);
    cleanup.push(() => c.close());
    c.send({ type: "session.follow", sessionId: sid });
    await c.waitFor("session.synced");
    const { done } = await s.core.send("me", sid, "ups");
    let finished = false;
    void done.then(() => {
      finished = true;
    });

    const asked = (await c.waitFor("question.request")) as { request: QuestionRequestInfo };
    expect(asked.request.agentName).toBe("Chat");
    expect(asked.request.questions).toEqual([
      {
        question: "How much does it need to power, and for how long?",
        header: "Load",
        options: [
          { label: "About 300 W, 5-10 minutes", description: "PC and monitor" },
          { label: "About 600 W, 20 minutes" },
          { label: "Not sure", description: "I will check the labels" },
        ],
        multiSelect: false,
      },
    ]);
    // The engine waits: no answer of the model before the person's, the turn still runs.
    await new Promise((ok) => setTimeout(ok, 300));
    expect(finished).toBe(false);
    const texts = async () =>
      (await s.core.history("me", sid)).flatMap((e: Event) =>
        e.type === "message.assistant"
          ? e.payload.parts.flatMap((p) => (p.type === "text" ? [p.text] : []))
          : [],
      );
    expect(await texts()).toEqual([]);

    c.send({
      type: "question.answer",
      requestId: asked.request.requestId,
      answers: [["About 600 W, 20 minutes"]],
    });
    await done;
    expect(await texts()).toEqual(["For About 600 W, 20 minutes: a 1000 VA UPS."]);
    const log = await s.core.history("me", sid);
    const kinds = log.map((e) => e.type).filter((k) => /^(question|tool)\./.test(k));
    expect(kinds).toEqual(["tool.call", "question.asked", "question.answered", "tool.result"]);
    const answered = log.find((e) => e.type === "question.answered");
    expect(answered?.type === "question.answered" && answered.payload).toMatchObject({
      answers: [["About 600 W, 20 minutes"]],
      by: "human",
      via: "web",
    });
  });
});

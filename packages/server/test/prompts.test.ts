import type { CompletionRequest } from "@redgiant/providers";
import { afterEach, describe, expect, it } from "vitest";
import { expandPrompt, type PromptView, toPlaceholders } from "../src/index.js";
import { OTHER, startServer } from "./helpers.js";

type Server = Awaited<ReturnType<typeof startServer>>;
let s: Server | undefined;
afterEach(async () => {
  await s?.close();
  s = undefined;
});

describe("names as placeholders", () => {
  const names = { name: "Zeus", god: "Zeus", demigod: "Demi-Zeus", role: "Keeps the diary" };
  const all = new Set(["name", "god", "demigod", "role"] as const);

  it("takes whole names only, the longest first", () => {
    expect(toPlaceholders("Zeus and Demi-Zeus; Zeus's job; Zeusian; {name}", names, all)).toBe(
      "{name} and {demigod}; {name}'s job; Zeusian; {name}",
    );
    expect(
      toPlaceholders("Ask God, not Demi-God.", { name: "X", god: "God", demigod: "Demi-God" }, all),
    ).toBe("Ask {god}, not {demigod}.");
  });

  it("keeps {name} out unless the built-in text uses it, and the role only after «Your job:»", () => {
    const n = { name: "Chat", god: "God", demigod: "Demi-God", role: "chat" };
    expect(toPlaceholders("Chat with God. Your job: chat", n, new Set(["god"]))).toBe(
      "Chat with {god}. Your job: chat",
    );
    expect(toPlaceholders("Your job: chat. Chat on.", n, new Set(["name", "role"]))).toBe(
      "Your job: {role}. {name} on.",
    );
  });

  it("puts the names back as they are now", () => {
    expect(
      expandPrompt("{name} asks {god} and {demigod}. Your job: {role}", {
        name: "Ada",
        god: "Odin",
        demigod: "Loki",
      }),
    ).toBe("Ada asks Odin and Loki. Your job: ");
  });
});

describe("agents' instructions (2026-11-06)", () => {
  it("shows the built-in text with the names, keeps edits with placeholders, follows renames", async () => {
    s = await startServer({ text: "ok" });
    const god = (
      await s.api<{ id: string }>("POST", "/api/agents", {
        kind: "god",
        parentId: null,
        name: "Zeus",
      })
    ).body;
    const demi = (
      await s.api<{ id: string }>("POST", "/api/agents", {
        kind: "demigod",
        parentId: god.id,
        name: "Hermes",
      })
    ).body;
    const first = (await s.api<PromptView>("GET", `/api/agents/${demi.id}/prompt`)).body;
    expect(first.isDefault).toBe(true);
    expect(first.text).toBe(first.defaultText);
    expect(first.text).toMatch(/^You are Hermes, .*Pass every request to Zeus with ask_god/);

    const edited = `${first.text} Always greet the user.`;
    const saved = (
      await s.api<PromptView>("PUT", `/api/agents/${demi.id}/prompt`, { text: edited })
    ).body;
    expect(saved).toMatchObject({ isDefault: false, text: edited });
    const kept = s.core.registry.get(demi.id)?.systemPrompt ?? "";
    expect(kept).toMatch(/^You are \{name\}, .*to \{god\} with ask_god/);
    expect(kept).not.toContain("Zeus");

    await s.api("PATCH", `/api/agents/${god.id}`, { name: "Odin" });
    await s.api("PATCH", `/api/agents/${demi.id}`, { name: "Loki" });
    const after = (await s.api<PromptView>("GET", `/api/agents/${demi.id}/prompt`)).body;
    expect(after.text).toMatch(/^You are Loki, .*Pass every request to Odin with ask_god.*greet/);
    const agent = s.core.registry.get(demi.id);
    expect(agent && s.core.systemFor(agent)).toBe(after.text);

    // The built-in text again: by null, or by saving it unchanged.
    expect(
      (await s.api<PromptView>("PUT", `/api/agents/${demi.id}/prompt`, { text: null })).body
        .isDefault,
    ).toBe(true);
    expect(s.core.registry.get(demi.id)?.systemPrompt).toBeUndefined();
    await s.api("PUT", `/api/agents/${demi.id}/prompt`, { text: after.defaultText });
    expect(s.core.registry.get(demi.id)?.systemPrompt).toBeUndefined();
  });

  it("is another owner's business only for that owner", async () => {
    s = await startServer({ text: "ok" });
    const god = (
      await s.api<{ id: string }>("POST", "/api/agents", {
        kind: "god",
        parentId: null,
        name: "God",
      })
    ).body;
    expect((await s.api("GET", `/api/agents/${god.id}/prompt`, undefined, OTHER)).status).toBe(404);
    expect((await s.api("PUT", `/api/agents/${god.id}/prompt`, { text: "Hi" }, OTHER)).status).toBe(
      404,
    );
    expect((await s.api("PUT", `/api/agents/${god.id}/prompt`, { text: 3 })).status).toBe(400);
  });

  it("never changes the system prompt of a conversation already open", async () => {
    const seen: CompletionRequest[] = [];
    s = await startServer((req) => {
      seen.push(req);
      return { text: "ok" };
    });
    const god = (
      await s.api<{ id: string }>("POST", "/api/agents", {
        kind: "god",
        parentId: null,
        name: "God",
      })
    ).body;
    const open = async () =>
      (await s?.api<{ sessionId: string }>("POST", "/api/sessions", { agentId: god.id }))?.body
        .sessionId as string;
    const me = s.core.registry.get(god.id)?.ownerId as string;
    const sid = await open();
    await (await s.core.send(me, sid, "One")).done;
    const before = seen.at(-1)?.system;
    expect(before).toMatch(/^You are God, the main orchestrator/);

    await s.api("PUT", `/api/agents/${god.id}/prompt`, { text: "You are God. Be brief." });
    await (await s.core.send(me, sid, "Two")).done;
    expect(seen.at(-1)?.system).toBe(before);
    const started = (await s.core.store.list({ sessionId: sid })).filter(
      (e) => e.type === "session.started",
    );
    expect(started).toHaveLength(1);

    // A new conversation starts with the new instructions.
    const next = await open();
    await (await s.core.send(me, next, "Three")).done;
    expect(seen.at(-1)?.system).toMatch(/^You are God\. Be brief\./);
  });

  it("does the same for the everyday Chat, through its agent or its own route", async () => {
    const seen: CompletionRequest[] = [];
    s = await startServer((req) => {
      seen.push(req);
      return { text: "ok" };
    });
    await s.api("POST", "/api/agents", { kind: "god", parentId: null, name: "Zeus" });
    const chat = (await s.api<PromptView>("GET", "/api/chat/prompt")).body;
    expect(chat.isDefault).toBe(true);
    expect(chat.text).toContain("suggest asking Zeus");
    const a = (await s.api<{ id: string }>("GET", "/api/chat/agent")).body;
    expect((await s.api<PromptView>("GET", `/api/agents/${a.id}/prompt`)).body).toEqual(chat);

    const saved = (
      await s.api<PromptView>("PUT", `/api/agents/${a.id}/prompt`, {
        text: "Be brief. Ask Zeus for projects.",
      })
    ).body;
    expect(saved.isDefault).toBe(false);
    expect((await s.api("GET", "/api/chat/settings")).body).toEqual({
      systemPrompt: "Be brief. Ask {god} for projects.",
    });
    const { sessionId } = (
      await s.api<{ sessionId: string }>("POST", "/api/sessions", { agentId: a.id })
    ).body;
    const me = s.core.registry.get(a.id)?.ownerId as string;
    await (await s.core.send(me, sessionId, "Ciao")).done;
    expect(seen.at(-1)?.system).toMatch(/^Be brief\. Ask Zeus for projects\./);

    const back = (await s.api<PromptView>("PUT", "/api/chat/prompt", { text: null })).body;
    expect(back.isDefault).toBe(true);
    expect((await s.api("GET", "/api/chat/settings")).body).toEqual({});
    expect(s.core.registry.get(a.id)?.systemPrompt).toContain("{god}");
  });

  it("is warm and practical, and brings an older built-in text up to date (G40.15)", async () => {
    const seen: CompletionRequest[] = [];
    s = await startServer((req) => {
      seen.push(req);
      return { text: "ok" };
    });
    await s.api("POST", "/api/agents", { kind: "god", parentId: null, name: "Zeus" });
    const a = (await s.api<{ id: string }>("GET", "/api/chat/agent")).body;
    // The Chat of an older version kept the built-in text of then on its agent.
    const before =
      "You are the user's everyday assistant. Answer clearly and briefly, in the user's language. Search the web when the answer depends on recent or specific facts, and read the pages you rely on. When you use web sources, cite them inline as [1], [2]… and end with a short list of those sources (title and URL). You have a folder of your own and every tool: files and commands, the canvas (show_file opens any file in a viewer, show a site) to show what you make, boards (publish_board) to propose variants to choose from, send_file, pictures, videos and sounds, web search and pages. Use them instead of describing what you would do. When a tool says it is not set up, tell the person plainly and where to set it up in RedGiant's Settings. For work that belongs to a project, suggest asking {god}, who hands it to the project's team.";
    const me = s.core.registry.get(a.id)?.ownerId as string;
    await s.core.registry.configure({ type: "human", ownerId: me }, a.id, { systemPrompt: before });
    expect(s.core.registry.get(a.id)?.systemPrompt).toBe(before);
    // The page opens the Chat: its agent gets the text of this version (new conversations).
    await s.api("GET", "/api/chat/agent");
    const view = (await s.api<PromptView>("GET", "/api/chat/prompt")).body;
    expect(view.isDefault).toBe(true);
    expect(view.text).toMatch(
      /^You are the user's everyday companion: warm, curious and genuinely engaged\. Talk like a thoughtful friend who knows a lot, in the user's language\. Match the length to the question: /,
    );
    const { sessionId } = (
      await s.api<{ sessionId: string }>("POST", "/api/sessions", { agentId: a.id })
    ).body;
    await (await s.core.send(me, sessionId, "Ciao")).done;
    const system = seen.at(-1)?.system ?? "";
    expect(system).toMatch(/^You are the user's everyday companion/);
    expect(system).not.toContain("Answer clearly and briefly");
    // Web and citations stay, then the practical paragraph, then the tools as before.
    const order = [
      "cite them inline as [1], [2]",
      "\n\nBe practical: when the person has a problem or a choice to make, search the web",
      "ask with ask_user (a few questions with options to tap)",
      "show them with show_products",
      "\n\nYou have a folder of your own and every tool",
      "suggest asking Zeus",
    ].map((x) => system.indexOf(x));
    expect(order.every((at) => at >= 0)).toBe(true);
    expect([...order].sort((x, y) => x - y)).toEqual(order);
    expect(s.core.registry.get(a.id)?.systemPrompt).not.toBe(before);
  });
});

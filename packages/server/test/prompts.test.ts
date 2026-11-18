import type { CompletionRequest } from "@redgiant/providers";
import { afterEach, describe, expect, it } from "vitest";
import { expandPrompt, type PromptView, toPlaceholders } from "../src/index.js";
import { OTHER, startServer } from "./helpers.js";

/** God's built-in instructions up to 3.8.14, with the product's name of then. */
const GOD_3814 =
  "You are {name}, the main orchestrator of this RedGiant installation. You oversee the platform and every project; you delegate project work to the project orchestrators. You do not do the work yourself: you organise it and hand it over. When the user asks to build, make or change something (a site, an app, a document, code, a design), use the project it belongs to, or create one with create_project and its orchestrator with create_agent (kind orchestrator), then give the work to that orchestrator with delegate. When the user asks about a project (how it is going, what it contains), ask its inspector with ask_inspector, which only reads; when something must be done in it, delegate to its orchestrator. Tasks for the same agent go into the same conversation, so it keeps the context. You are also the user's chief of staff: when a request is the job of one of their personal assistants (list_agents shows them, kind assistant, with their role), hand it over with ask_assistant and report the answer here. Do yourself only what is talk: answering, explaining, planning with the user, the platform's settings. Messages reach you from the user, directly or relayed from their Telegram by {demigod}, their spokesperson. Handing work over with delegate returns at once: tell the user it has started, stay available, and when its <task_report> comes back as a message, tell them how it went. The models are the user's choice: give an agent a model (create_agent model, set_agent_model) only when the user explicitly asked for that model, never by your own choice; otherwise leave it out and the user's default applies. A stopped agent is paused, not gone: when it is needed again, bring it back with resume_agent (its open tasks go on in the same conversation) instead of creating a new one; remove_agent takes an agent out of the team (the user can restore it).";

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

  it("takes God's built-in text of 3.8.14 for the built-in one, with the name of today (3.9.0)", async () => {
    const seen: CompletionRequest[] = [];
    s = await startServer((req) => {
      seen.push(req);
      return { text: "ok" };
    });
    const god = (
      await s.api<{ id: string }>("POST", "/api/agents", {
        kind: "god",
        parentId: null,
        name: "Zeus",
      })
    ).body;
    const me = s.core.registry.get(god.id)?.ownerId as string;
    // As an older page could save it: the built-in text of then, kept with placeholders.
    await s.core.registry.configure({ type: "human", ownerId: me }, god.id, {
      systemPrompt: GOD_3814,
    });
    const view = (await s.api<PromptView>("GET", `/api/agents/${god.id}/prompt`)).body;
    expect(view.isDefault).toBe(true);
    expect(view.text).toMatch(
      /^You are Zeus, the main orchestrator of this Rasgeth installation\./,
    );
    const { sessionId } = (
      await s.api<{ sessionId: string }>("POST", "/api/sessions", { agentId: god.id })
    ).body;
    await (await s.core.send(me, sessionId, "Ciao")).done;
    expect(seen.at(-1)?.system).toMatch(/^You are Zeus, the main orchestrator of this Rasgeth/);
    // Saving the old text, with the names in place, is the built-in one too.
    await s.api("PUT", `/api/agents/${god.id}/prompt`, {
      text: expandPrompt(GOD_3814, { name: "Zeus", god: "Zeus", demigod: "Demi-God" }),
    });
    expect(s.core.registry.get(god.id)?.systemPrompt).toBeUndefined();
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

  // The built-in texts of older versions, as their Chat agents kept them.
  const OLDER = {
    "3.8.0":
      "You are the user's everyday assistant. Answer clearly and briefly, in the user's language. Search the web when the answer depends on recent or specific facts, and read the pages you rely on. When you use web sources, cite them inline as [1], [2]… and end with a short list of those sources (title and URL). You have a folder of your own and every tool: files and commands, the canvas (show_file opens any file in a viewer, show a site) to show what you make, boards (publish_board) to propose variants to choose from, send_file, pictures, videos and sounds, web search and pages. Use them instead of describing what you would do. When a tool says it is not set up, tell the person plainly and where to set it up in RedGiant's Settings. For work that belongs to a project, suggest asking {god}, who hands it to the project's team.",
    "3.8.6":
      "You are the user's everyday companion: warm, curious and genuinely engaged. Talk like a thoughtful friend who knows a lot, in the user's language. Match the length to the question: a quick fact gets a quick answer, while ideas, advice, explanations and creative work get the depth, nuance and examples they deserve. Follow the thread of the conversation, ask a question back when it helps, offer your own view when asked, and use headings, lists or tables only when they make things clearer. Search the web when the answer depends on recent or specific facts, and read the pages you rely on. When you use web sources, cite them inline as [1], [2]… and end with a short list of those sources (title and URL).\n\nBe practical: when the person has a problem or a choice to make, search the web and bring concrete options (products, places, services, steps) with prices and links, not general advice. When the right answer depends on their preferences or situation, ask with ask_user (a few questions with options to tap) before going on. When a comparison or a number helps, put it in a widget: options side by side, a calculator, a slider to try. Keep plain text for what is just read. When the options are products to buy or compare, show them with show_products: cards with picture, price, shop and link.\n\nYou have a folder of your own and every tool: files and commands, the canvas (show_file opens any file in a viewer, show a site) to show what you make, boards (publish_board) to propose variants to choose from, send_file, pictures, videos and sounds, web search and pages. Use them instead of describing what you would do. When a tool says it is not set up, tell the person plainly and where to set it up in RedGiant's Settings. For work that belongs to a project, suggest asking {god}, who hands it to the project's team.",
    "3.8.14":
      "You are the person's everyday companion: warm, curious and genuinely engaged, like a friend who knows a lot and enjoys explaining it. Write in the person's language. Be friendly and natural, never servile and never padded: no flattery, no \"Great question!\", no repeating the question back, no empty closing lines.\n\nBy default give a full, engaging answer, the kind a knowledgeable friend gives when they take the question seriously:\n1. The direct answer first, in the opening line or two: yes or no, how much, which one.\n2. Why, in plain words: the idea behind it, with any technical term explained.\n3. An example worked out with the person's own numbers and situation (or realistic ones when they gave none).\n4. What to do in practice: concrete steps, tips, what to watch out for.\n5. A close that moves things on: one concrete offer to go further (a calculation, a comparison, a plan, a checklist) or one useful question about their situation.\nKeep it short only for dry facts: a time, a date, a name, a trivial yes or no, a quick sum (15% of 80 gets the result and its one-line working). A question that sounds simple but touches the person's home, health, money, work or plans deserves the full answer.\n\nUse rich formatting when it helps the reader: short headings, bulleted or numbered lists, **bold** for the key points and numbers, tables to compare. Never a wall of text: short paragraphs, one idea each. Follow the thread of the conversation, and give your own view when asked.\n\nSearch the web when the answer depends on recent or specific facts, and read the pages you rely on. When you use web sources, cite them inline as [1], [2]… and end with a short list of those sources (title and URL).\n\nBe practical: when the person has a problem or a choice to make, search the web and bring concrete options (products, places, services, steps) with prices and links, not general advice. When the right answer depends on their preferences or situation, ask with ask_user (a few questions with options to tap) before going on; when reasonable assumptions are enough, answer and say which ones you made. When the options are products to buy or compare, show them with show_products: cards with picture, price, shop and link.\n\nWidgets: in this chat, add a widget whenever the person could play with the answer, even when text alone would answer it:\n- numbers they can vary: calculations, conversions, mortgages and loans, bills and consumption, humidity and dew point, calories;\n- comparisons between options, side by side with the figures that matter;\n- choices with criteria, where weighing what matters to them changes the pick;\n- things to try: sliders, a timer, a small simulation.\nFor example: \"will the humidity inside drop if I air the house?\" gets a calculator with temperature and humidity inside and outside and the humidity inside after airing; \"fixed or variable mortgage?\" gets both payments side by side with sliders for the amount, the years and the rate; \"which laptop for work?\" gets the shortlist in a table with a weight for each criterion.\nA widget is a ```widget block in your answer: the fence line may carry a short title (```widget Humidity after airing), then plain HTML with RedGiant's rg- classes (described below) and a small <script> that recomputes as the person types, then the closing fence. Open it on the person's own numbers. The widget goes with the text, never instead of it: write the full answer, put the widget where it helps (usually after the worked example) and say in one line what to try in it.\n\nYou have a folder of your own and every tool: files and commands, the canvas (show_file opens any file in a viewer, show a site) to show what you make, boards (publish_board) to propose variants to choose from, send_file, pictures, videos and sounds, web search and pages. Use them instead of describing what you would do. When a tool says it is not set up, tell the person plainly and where to set it up in RedGiant's Settings. For work that belongs to a project, suggest asking {god}, who hands it to the project's team.",
  };

  for (const [version, before] of Object.entries(OLDER))
    it(`is full, warm and practical, and brings the ${version} built-in text up to date`, async () => {
      const seen: CompletionRequest[] = [];
      s = await startServer((req) => {
        seen.push(req);
        return { text: "ok" };
      });
      await s.api("POST", "/api/agents", { kind: "god", parentId: null, name: "Zeus" });
      const a = (await s.api<{ id: string }>("GET", "/api/chat/agent")).body;
      // The Chat of an older version kept the built-in text of then on its agent.
      const me = s.core.registry.get(a.id)?.ownerId as string;
      await s.core.registry.configure({ type: "human", ownerId: me }, a.id, {
        systemPrompt: before,
      });
      expect(s.core.registry.get(a.id)?.systemPrompt).toBe(before);
      // The page opens the Chat: its agent gets the text of this version (new conversations).
      await s.api("GET", "/api/chat/agent");
      const view = (await s.api<PromptView>("GET", "/api/chat/prompt")).body;
      expect(view.isDefault).toBe(true);
      expect(view.text).toMatch(
        /^You are the person's everyday companion: warm, curious and genuinely engaged, like a friend who knows a lot/,
      );
      const { sessionId } = (
        await s.api<{ sessionId: string }>("POST", "/api/sessions", { agentId: a.id })
      ).body;
      await (await s.core.send(me, sessionId, "Ciao")).done;
      const system = seen.at(-1)?.system ?? "";
      expect(system).toMatch(/^You are the person's everyday companion/);
      // Full answers by default: nothing the model reads as "be brief".
      expect(system).not.toContain("Answer clearly and briefly");
      expect(system).not.toContain("Match the length to the question");
      expect(system).toContain("By default give a full, engaging answer");
      expect(system).toContain("Keep it short only for dry facts");
      // The answer, then the voice and web, the practical help, the widgets, the tools.
      const order = [
        "1. The direct answer first",
        "5. A close that moves things on",
        "cite them inline as [1], [2]",
        "\n\nBe practical: when the person has a problem or a choice to make, search the web",
        "ask with ask_user (a few questions with options to tap)",
        "show them with show_products",
        "\n\nWidgets: in this chat, add a widget whenever the person could play with the answer",
        "humidity and dew point",
        "A widget is a ```widget block in your answer",
        "The widget goes with the text, never instead of it",
        "\n\nYou have a folder of your own and every tool",
        "suggest asking Zeus",
      ].map((x) => system.indexOf(x));
      expect(order.every((at) => at >= 0)).toBe(true);
      expect([...order].sort((x, y) => x - y)).toEqual(order);
      expect(s.core.registry.get(a.id)?.systemPrompt).not.toBe(before);
    });
});

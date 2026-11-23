// God's topics on Telegram (3.12.3): the person's own words are routed before Demi-God relays them,
// «reply» goes to the mapped topic, the gateway puts the topic's title on top when it changes, the
// «Move» button and the commands. PGlite + FakeProvider + the fake Bot API: no real model.
import type { Event } from "@redgiant/protocol";
import type { CompletionRequest } from "@redgiant/providers";
import { afterEach, describe, expect, it, vi } from "vitest";
import { fakeTelegram } from "./fake-telegram.js";
import { startServer } from "./helpers.js";

type Server = Awaited<ReturnType<typeof startServer>>;
let s: Server | undefined;
let tg: Awaited<ReturnType<typeof fakeTelegram>> | undefined;
afterEach(async () => {
  vi.useRealTimers();
  await s?.close();
  await tg?.close();
  s = undefined;
});

const USER = 4242;
const lastText = (req: CompletionRequest) => {
  const m = [...req.messages]
    .reverse()
    .find((x) => x.role === "user" && x.parts.some((p) => p.type === "text"));
  const p = m?.parts.find((x) => x.type === "text");
  return p?.type === "text" ? p.text : "";
};
const toolResult = (req: CompletionRequest) => {
  const last = req.messages.at(-1);
  const p = last?.role === "user" ? last.parts.find((x) => x.type === "tool_result") : undefined;
  return p?.type === "tool_result" ? p.content : undefined;
};

/** The router: what it was asked, and where each message goes (a title, or «new: Title»). */
function router() {
  const asked: string[] = [];
  const plan: string[] = [];
  const fn = async (call: { text: string }) => {
    asked.push(call.text.split("<message>\n")[1]?.split("\n</message>")[0] ?? "");
    const want = plan.shift() ?? "new: Altro";
    if (want.startsWith("new: "))
      return `{"topic":"new","title":"${want.slice(5)}","confidence":0.95}`;
    const id = call.text.match(new RegExp(`id: (\\S+) \\| title: ${want}`))?.[1];
    return `{"topic":"${id}","confidence":0.95}`;
  };
  return { asked, plan, fn };
}

const demigodRequests: CompletionRequest[] = [];

async function setup(r = router()) {
  demigodRequests.length = 0;
  tg = await fakeTelegram();
  s = await startServer(
    (req) => {
      if (req.system.startsWith("You are Demi-God")) {
        demigodRequests.push(req);
        const res = toolResult(req);
        // Demi-God rewords what the person said: the routing must not read this.
        return res === undefined
          ? { toolCalls: [{ name: "ask_god", input: { message: `REWORDED ${lastText(req)}` } }] }
          : { text: res };
      }
      return { text: `God: ${lastText(req).split("\n").pop()}` };
    },
    {},
    { topicsRouter: async () => ({ fn: r.fn, model: { provider: "fake", model: "router" } }) },
    undefined,
    tg.apiRoot,
  );
  const god = await s.api<{ id: string }>("POST", "/api/agents", {
    kind: "god",
    parentId: null,
    name: "God",
  });
  await s.api("POST", "/api/agents", { kind: "demigod", parentId: god.body.id, name: "Demi-God" });
  const { body } = await s.api<{ code: string }>("POST", "/api/telegram/pair");
  await s.gateway?.handleUpdate(tg.text(USER, `/start ${body.code}`) as never);
  return r;
}

const say = async (update: unknown) => {
  await s?.gateway?.handleUpdate(update as never);
  await s?.gateway?.idle();
};
const sent = () => tg?.calls.filter((c) => c.method === "sendMessage" && c.body.chat_id === USER);
const lastSent = () => sent()?.at(-1);
const topics = async () => (await (s as Server).core.topics.list("me")).topics;
const events = (sid: string) => (s as Server).core.store.list({ sessionId: sid });
const types = (es: Event[]) => es.map((e) => e.type);
type Keyboard = { inline_keyboard: { text: string; callback_data: string }[][] };

describe("God's topics on Telegram", () => {
  it("routes the person's own words before relaying, and Demi-God keeps one conversation", async () => {
    const r = await setup();
    r.plan.push("new: Preventivo Rossi", "Preventivo Rossi");
    await say(tg?.text(USER, "Prepara il preventivo per Rossi"));
    await say(tg?.text(USER, "/nuovo"));
    await say(tg?.text(USER, "Backup NAS"));
    await say(tg?.text(USER, "aggiungi l'hosting al preventivo"));
    // The router read the original words, never Demi-God's rewording.
    expect(r.asked).toEqual([
      "Prepara il preventivo per Rossi",
      "aggiungi l'hosting al preventivo",
    ]);
    const list = await topics();
    expect(list.map((t) => t.title).sort()).toEqual(["Backup NAS", "Preventivo Rossi"]);
    // Each ask_god wrote into the chosen topic, with the routing event before the message.
    const rossi = list.find((t) => t.title === "Preventivo Rossi");
    const es = await events(rossi?.id as string);
    expect(types(es)).toContain("topic.routed");
    const user = es.filter((e) => e.type === "message.user");
    expect(user).toHaveLength(2);
    expect(user[1]?.payload).toMatchObject({ from: "Telegram" });
    // Demi-God is one conversation: the same prefix (system, tools) on every request.
    expect(demigodRequests.length).toBeGreaterThan(3);
    expect(new Set(demigodRequests.map((q) => q.system)).size).toBe(1);
    expect(new Set(demigodRequests.map((q) => JSON.stringify(q.tools))).size).toBe(1);
    const demi = (await (s as Server).core.listSessions("me")).filter(
      (x) => (s as Server).core.registry.get(x.agent_id)?.kind === "demigod",
    );
    expect(demi).toHaveLength(1);
  });

  it("a reply to an answer goes to that answer's topic", async () => {
    const r = await setup();
    r.plan.push("new: Preventivo Rossi");
    await say(tg?.text(USER, "Prepara il preventivo per Rossi"));
    const first = lastSent()?.messageId as number;
    await say(tg?.text(USER, "/nuovo"));
    await say(tg?.text(USER, "Backup NAS"));
    const a = (await topics()).find((t) => t.title === "Preventivo Rossi");
    // The reply rule decides first, without asking the router.
    const before = r.asked.length;
    await say(tg?.reply(USER, "controlla le cifre", first));
    expect(r.asked.length).toBe(before);
    const es = await events(a?.id as string);
    expect(es.filter((e) => e.type === "message.user")).toHaveLength(2);
    expect(es.filter((e) => e.type === "topic.routed").at(-1)?.payload).toMatchObject({
      via: "reply",
    });
  });

  it("puts the title on top only when the topic changes or after 30 minutes", async () => {
    const r = await setup();
    vi.useFakeTimers({ toFake: ["Date"], now: new Date("2026-11-23T10:00:00Z") });
    r.plan.push("new: Preventivo Rossi", "Backup NAS", "Backup NAS");
    await say(tg?.text(USER, "Prepara il preventivo per Rossi"));
    expect(lastSent()?.body.text).toMatch(/^<b>Preventivo Rossi<\/b>\n/);
    // Same topic, soon after: no header.
    vi.setSystemTime(new Date("2026-11-23T10:05:00Z"));
    await say(tg?.text(USER, "aggiungi anche l'hosting"));
    expect(lastSent()?.body.text).not.toMatch(/<b>/);
    // Another topic: the header says so.
    await say(tg?.text(USER, "/nuovo"));
    await say(tg?.text(USER, "Backup NAS"));
    expect(lastSent()?.body.text).toMatch(/^<b>Backup NAS<\/b>\n/);
    // The same one 10 minutes later: none; after 32 minutes of silence: again.
    vi.setSystemTime(new Date("2026-11-23T10:15:00Z"));
    await say(tg?.text(USER, "controlla lo spazio rimasto"));
    expect(lastSent()?.body.text).not.toMatch(/<b>/);
    vi.setSystemTime(new Date("2026-11-23T10:47:00Z"));
    await say(tg?.text(USER, "controlla anche i log di ieri"));
    expect(lastSent()?.body.text).toMatch(/^<b>Backup NAS<\/b>\n/);
  });

  it("«Move» under the answer with the title moves the last exchange, or opens a new topic", async () => {
    const r = await setup();
    r.plan.push("new: Preventivo Rossi");
    await say(tg?.text(USER, "Prepara il preventivo per Rossi"));
    await say(tg?.text(USER, "/nuovo"));
    await say(tg?.text(USER, "Backup NAS"));
    const button = (lastSent()?.body.reply_markup as Keyboard).inline_keyboard[0]?.[0];
    expect(button?.text).toBe("Move");
    await say(tg?.button(USER, button?.callback_data as string));
    const menu = lastSent()?.body;
    expect(menu?.text).toBe("Move this exchange to:");
    const rows = (menu?.reply_markup as Keyboard).inline_keyboard;
    // The other active topic, then «New topic».
    expect(rows.map((x) => x[0]?.text)).toEqual(["Preventivo Rossi", "New topic"]);
    await say(tg?.button(USER, rows[0]?.[0]?.callback_data as string));
    const rossi = (await topics()).find((t) => t.title === "Preventivo Rossi");
    const nas = (await topics()).find((t) => t.title === "Backup NAS");
    expect(types(await events(nas?.id as string))).toContain("message.moved");
    const arrived = (await events(rossi?.id as string)).filter((e) => e.type === "message.user");
    expect(arrived).toHaveLength(2);
    expect(
      tg?.calls.some(
        (c) => c.method === "editMessageText" && c.body.text === "Moved to: Preventivo Rossi",
      ),
    ).toBe(true);
    // /sposta then «New topic» opens one.
    await say(tg?.text(USER, "/sposta"));
    const rows2 = (lastSent()?.body.reply_markup as Keyboard).inline_keyboard;
    await say(tg?.button(USER, rows2.at(-1)?.[0]?.callback_data as string));
    expect((await topics()).length).toBe(3);
  });

  it("/argomenti lists the active topics; /nuovo (and /new) opens a new one without resetting anything", async () => {
    const r = await setup();
    r.plan.push("new: Preventivo Rossi");
    await say(tg?.text(USER, "Prepara il preventivo per Rossi"));
    await say(tg?.text(USER, "/argomenti"));
    expect(lastSent()?.body.text).toBe("Active topics:\n1. Preventivo Rossi");
    await say(tg?.text(USER, "/nuovo"));
    expect(lastSent()?.body.text).toMatch(/^New topic/);
    // Even a message that would continue the topic opens a new one, once.
    await say(tg?.text(USER, "e l'hosting"));
    expect((await topics()).length).toBe(2);
    await say(tg?.text(USER, "/new"));
    await say(tg?.text(USER, "altra cosa"));
    expect((await topics()).length).toBe(3);
    // Demi-God never started over.
    const demi = (await (s as Server).core.listSessions("me")).filter(
      (x) => (s as Server).core.registry.get(x.agent_id)?.kind === "demigod",
    );
    expect(demi).toHaveLength(1);
  });

  it("the chat's mapping is in the table, so it survives a restart", async () => {
    const r = await setup();
    r.plan.push("new: Preventivo Rossi");
    await say(tg?.text(USER, "Prepara il preventivo per Rossi"));
    const id = lastSent()?.messageId as number;
    const [t] = await topics();
    expect(await (s as Server).core.topicOfChatMessage("me", `telegram:${USER}`, String(id))).toBe(
      t?.id,
    );
  });
});

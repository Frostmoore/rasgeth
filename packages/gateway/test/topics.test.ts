// God's topics in the other chats (3.12.3): the title on top when the topic changes or after 30
// minutes (fake clock), replies carried to the host, the mapping of what was sent, /argomenti,
// /sposta by number and /nuovo. A fake transport and host: no platform, no model.
import { EventEmitter } from "node:events";
import { describe, expect, it } from "vitest";
import { type Button, ChatBridge, type GatewayHost, type Incoming } from "../src/index.js";
import { memoryDb } from "./pglite.js";

class FakeTransport {
  readonly platform = "slack" as const;
  readonly maxLength = 4000;
  readonly buttons = false;
  on: ((m: Incoming) => Promise<void>) | undefined;
  sent: { chatId: string; text: string; id: string }[] = [];
  async start(on: (m: Incoming) => Promise<void>) {
    this.on = on;
  }
  async stop() {}
  async send(chatId: string, text: string, _buttons?: Button[]) {
    const id = `m${this.sent.length + 1}`;
    this.sent.push({ chatId, text, id });
    return id;
  }
  texts() {
    return this.sent.map((m) => m.text);
  }
}

const A = { topicId: "sess_a", title: "Preventivo Rossi", isNew: true };
const B = { topicId: "sess_b", title: "Backup NAS", isNew: true };

async function setup() {
  const { db } = await memoryDb();
  const t = new FakeTransport();
  let clock = Date.parse("2026-11-23T10:00:00Z");
  const route: (typeof A)[] = [];
  const asked: { text: string; replyTo?: { chat: string; messageId: string } }[] = [];
  const remembered: [string, string, string][] = [];
  const moved: [string, string][] = [];
  let fresh = 0;
  const e = new EventEmitter();
  const host: GatewayHost = {
    async askDemigod(_o, _c, text, extra) {
      asked.push({ text, ...(extra?.replyTo && { replyTo: extra.replyTo }) });
      const r = route.shift();
      if (r) extra?.onRouted?.(r);
      return `You said: ${text}`;
    },
    async rememberChatMessage(_o, chat, messageId, topicId) {
      remembered.push([chat, messageId, topicId]);
    },
    async chatTopics() {
      return [
        { id: A.topicId, title: A.title },
        { id: B.topicId, title: B.title },
      ];
    },
    async moveFromChat(_o, from, to) {
      moved.push([from, to]);
      return { topicId: A.topicId, title: A.title, answer: "Redone there" };
    },
    newConversation: () => {
      fresh++;
    },
    approvals: {
      on: (ev: string, l: (...a: never[]) => void) => e.on(ev, l),
      decide: () => true,
    },
    language: () => "en",
  };
  const bridge = new ChatBridge({ db, host, transport: t, now: () => clock });
  await bridge.start();
  const send = async (m: Partial<Incoming>) => {
    await t.on?.({ userId: "u1", chatId: "c1", ...m });
    await bridge.idle();
  };
  const { code } = bridge.pairingCode("me");
  await send({ text: `/start ${code}` });
  t.sent = [];
  return {
    t,
    send,
    route,
    asked,
    remembered,
    moved,
    fresh: () => fresh,
    advance: (ms: number) => {
      clock += ms;
    },
  };
}

describe("God's topics in the other chats", () => {
  it("puts the title on top only on a change or after 30 minutes of silence", async () => {
    const x = await setup();
    x.route.push(A, A, B, B, B);
    await x.send({ text: "preventivo" });
    expect(x.t.texts().at(-1)).toBe("*Preventivo Rossi*\nYou said: preventivo");
    x.advance(5 * 60_000);
    await x.send({ text: "e l'hosting" });
    expect(x.t.texts().at(-1)).toBe("You said: e l'hosting");
    await x.send({ text: "backup" });
    expect(x.t.texts().at(-1)).toBe("*Backup NAS*\nYou said: backup");
    x.advance(10 * 60_000);
    await x.send({ text: "ancora" });
    expect(x.t.texts().at(-1)).toBe("You said: ancora");
    x.advance(31 * 60_000);
    await x.send({ text: "dopo una pausa" });
    expect(x.t.texts().at(-1)).toBe("*Backup NAS*\nYou said: dopo una pausa");
    // Every message sent is remembered with its topic.
    expect(x.remembered.map((r) => r[2])).toEqual([
      A.topicId,
      A.topicId,
      B.topicId,
      B.topicId,
      B.topicId,
    ]);
    expect(x.remembered[0]?.slice(0, 2)).toEqual(["slack:c1", "m1"]);
  });

  it("carries the message replied to, with the chat it belongs to", async () => {
    const x = await setup();
    await x.send({ text: "e questo?", replyTo: "m7" });
    expect(x.asked[0]?.replyTo).toEqual({ chat: "slack:c1", messageId: "m7" });
  });

  it("/argomenti lists the active topics, /nuovo starts a new one", async () => {
    const x = await setup();
    await x.send({ text: "/argomenti" });
    expect(x.t.texts().at(-1)).toBe("Active topics:\n1. Preventivo Rossi\n2. Backup NAS");
    await x.send({ text: "/nuovo" });
    await x.send({ text: "/new" });
    expect(x.fresh()).toBe(2);
    expect(x.t.texts().at(-1)).toMatch(/^New topic/);
  });

  it("/sposta moves the last exchange with a numbered list", async () => {
    const x = await setup();
    await x.send({ text: "/sposta" });
    expect(x.t.texts().at(-1)).toBe("There is nothing to move yet.");
    x.route.push(B);
    await x.send({ text: "backup" });
    await x.send({ text: "/sposta" });
    // The topic it is in is left out; «New topic» is last.
    expect(x.t.texts().at(-1)).toMatch(
      /^Move this exchange to:\n\n1\. Preventivo Rossi\n2\. New topic\n/,
    );
    await x.send({ text: "1" });
    expect(x.moved).toEqual([[B.topicId, A.topicId]]);
    expect(x.t.texts().slice(-2)).toEqual([
      "Moved to: Preventivo Rossi",
      "*Preventivo Rossi*\nRedone there",
    ]);
    await x.send({ text: "/sposta" });
    await x.send({ text: "2" });
    expect(x.moved.at(-1)).toEqual([A.topicId, "new"]);
  });
});

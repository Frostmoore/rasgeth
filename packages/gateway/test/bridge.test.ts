import { EventEmitter } from "node:events";
import {
  type PermissionRequestInfo,
  PRODUCT_NAME,
  type QuestionRequestInfo,
} from "@redgiant/protocol";
import { describe, expect, it } from "vitest";
import {
  type Button,
  ChatBridge,
  type GatewayHost,
  type Incoming,
  splitText,
  type Transport,
} from "../src/index.js";
import { memoryDb } from "./pglite.js";

class FakeTransport implements Transport {
  readonly platform = "discord" as const;
  readonly maxLength = 50;
  on: ((m: Incoming) => Promise<void>) | undefined;
  sent: { chatId: string; text: string; buttons?: Button[]; id: string }[] = [];
  edits: { messageId: string; text: string }[] = [];
  constructor(readonly buttons: boolean) {}
  async start(on: (m: Incoming) => Promise<void>) {
    this.on = on;
  }
  async stop() {}
  async send(chatId: string, text: string, buttons?: Button[]) {
    const id = `m${this.sent.length + 1}`;
    this.sent.push({ chatId, text, ...(buttons?.length && { buttons }), id });
    return id;
  }
  async edit(_chatId: string, messageId: string, text: string) {
    this.edits.push({ messageId, text });
  }
  texts() {
    return this.sent.map((m) => m.text);
  }
}

function fakeHost() {
  const approvals = new EventEmitter();
  const questions = new EventEmitter();
  const skills = new EventEmitter();
  const skillDecisions: [string, string, string][] = [];
  const decided: [string, string][] = [];
  const answered: unknown[] = [];
  const asked: { chatId: string; text: string; secretOk?: boolean }[] = [];
  const host: GatewayHost = {
    async askDemigod(_owner, chatId, text, extra) {
      asked.push({ chatId, text, ...(extra?.secretOk && { secretOk: true }) });
      return `You said: ${text}`;
    },
    transcription: {},
    async transcribe() {
      return "hello from a voice note";
    },
    approvals: {
      on: (e: string, l: (...a: never[]) => void) => approvals.on(e, l),
      decide(_o, id, d) {
        decided.push([id, d]);
        approvals.emit("closed", "me", id, d);
        return true;
      },
    },
    questions: {
      on: (e: string, l: (...a: never[]) => void) => questions.on(e, l),
      answer(_o, _id, a) {
        answered.push(a);
        return true;
      },
    },
    language: () => "en",
    skillUpdates: {
      on: (e: string, l: (...a: never[]) => void) => skills.on(e, l),
      async decide(owner, id, d, via) {
        if (skillDecisions.some(([x]) => x === id)) return false;
        skillDecisions.push([id, d, via]);
        skills.emit("closed", owner, id, d, via);
        return true;
      },
    },
  };
  return { host, approvals, questions, decided, answered, asked, skills, skillDecisions };
}

async function setup(buttons = true) {
  const { db } = await memoryDb();
  const t = new FakeTransport(buttons);
  const h = fakeHost();
  const bridge = new ChatBridge({ db, host: h.host, transport: t });
  await bridge.start();
  const send = async (m: Partial<Incoming>) => {
    await t.on?.({ userId: "u1", chatId: "c1", ...m });
    await bridge.idle();
  };
  const { code } = bridge.pairingCode("me");
  await send({ text: `/start ${code}`, username: "marta" });
  t.sent = [];
  return { bridge, t, send, ...h };
}

const perm: PermissionRequestInfo = {
  requestId: "r1",
  agentId: "a",
  agentName: "Coder",
  projectId: "demo",
  tool: "bash",
  input: { command: "rm -rf /srv/x" },
  reasons: ["writes outside the project: /srv/x"],
  danger: ["outside-project"],
  createdAt: new Date().toISOString(),
};

const question: QuestionRequestInfo = {
  requestId: "q1",
  sessionId: "s",
  agentId: "a",
  agentName: "Coder",
  projectId: null,
  questions: [
    {
      question: "Which database?",
      options: [{ label: "Postgres" }, { label: "SQLite" }],
      multiSelect: false,
    },
    {
      question: "Which extras?",
      options: [{ label: "Backups" }, { label: "Metrics" }, { label: "Logs" }],
      multiSelect: true,
    },
  ],
  createdAt: new Date().toISOString(),
};

describe("chat bridge (G29.5)", () => {
  it("pairs a chat with a one-time code and refuses strangers", async () => {
    const { db } = await memoryDb();
    const t = new FakeTransport(true);
    const bridge = new ChatBridge({ db, host: fakeHost().host, transport: t });
    await bridge.start();
    await t.on?.({ userId: "u9", chatId: "c9", text: "hi" });
    expect(t.texts()[0]).toMatch(/not linked.*Discord/);
    await t.on?.({ userId: "u9", chatId: "c9", text: "/start 123456" });
    expect(t.texts()[1]).toMatch(/To link this chat/);
    const { code } = bridge.pairingCode("me");
    await t.on?.({ userId: "u9", chatId: "c9", text: `start ${code}` });
    expect(t.texts()[2]).toMatch(/Linked/);
    expect((await bridge.links("me")).map((l) => [l.userId, l.chatId])).toEqual([["u9", "c9"]]);
    // A code works once.
    await t.on?.({ userId: "u8", chatId: "c8", text: `/start ${code}` });
    expect(await bridge.links("me")).toHaveLength(1);
    await bridge.unlink("me", "u9");
    expect(await bridge.links("me")).toEqual([]);
  });

  it("relays text and voice to Demi-God and splits long answers", async () => {
    const { t, send, asked } = await setup();
    await send({ text: "what is on today" });
    expect(asked).toEqual([{ chatId: "c1", text: "what is on today" }]);
    expect(t.texts()).toEqual(["You said: what is on today"]);
    t.sent = [];
    await send({ audio: { data: new Uint8Array([1]), mime: "audio/ogg" } });
    expect(t.texts()[0]).toBe("I heard: hello from a voice note");
    // 50 characters at most per message on this fake platform.
    expect(t.texts().slice(1).join("")).toBe("You said: hello from a voice note");
    expect(splitText("a".repeat(120), 50)).toHaveLength(3);
  });

  it("says why a voice note did not become text, in the person's language", async () => {
    const { t, send, host } = await setup();
    host.language = () => "it";
    host.transcribe = async () => {
      throw Object.assign(new Error("Groq refused the key"), {
        code: "voice_key_refused",
        vars: { name: "Groq" },
      });
    };
    await send({ audio: { data: new Uint8Array([1]), mime: "audio/ogg" } });
    expect(t.texts().join("")).toBe(
      "Groq ha rifiutato la chiave: controllala in Rasgeth, Impostazioni, Voce.",
    );
  });

  it("asks approvals with buttons, and closes them when answered", async () => {
    const { t, send, approvals, decided } = await setup();
    approvals.emit("request", "me", perm);
    await new Promise((r) => setTimeout(r, 20));
    const m = t.sent.at(-1);
    // What happens first, in words; the reason and the danger in the person's language, the raw
    // input last (3.5.6).
    expect(m?.text.split("\n")).toEqual([
      "Approval needed: Coder (demo) asks for your yes",
      "Deletes /srv/x.",
      "Why: Writes outside the project's folder: /srv/x",
      "Danger: Writing outside the project",
      'Details: bash {"command":"rm -rf /srv/x"}',
    ]);
    expect(m?.buttons?.map((b) => b.label)).toEqual(["Allow", "Deny"]);
    await send({ button: m?.buttons?.[1]?.id ?? "" });
    expect(decided).toEqual([["r1", "deny"]]);
    await new Promise((r) => setTimeout(r, 20));
    expect(t.edits.at(-1)?.text).toMatch(/Denied$/);
  });

  it("says what a platform request does, with the project's name (3.5.6)", async () => {
    const { t, approvals } = await setup();
    approvals.emit("request", "me", {
      ...perm,
      requestId: "r3",
      agentName: "God",
      projectId: null,
      tool: "platform_project",
      input: { action: "archive", project_id: "proj_7" },
      names: { proj_7: "Collaudo 3.5.3" },
      reasons: ["Changes the platform"],
      danger: ["platform"],
    });
    await new Promise((r) => setTimeout(r, 20));
    expect(t.sent.at(-1)?.text.split("\n")).toEqual([
      "Approval needed: God asks for your yes",
      "Archives the project “Collaudo 3.5.3”: its agents stop and nobody changes its files until you restore it.",
      "Danger: Changing Rasgeth itself",
      'Details: platform_project {"action":"archive","project_id":"proj_7"}',
    ]);
  });

  it("starts a truly dangerous request with its danger, in words (p3.5.4)", async () => {
    const { t, send, approvals, decided } = await setup();
    approvals.emit("request", "me", {
      ...perm,
      requestId: "r2",
      tool: "canvas_edit",
      input: { path: "modulo.pdf", ops: [{ op: "redact", page: 1, find: "Rossi" }] },
      reasons: ["truly dangerous: redacts modulo.pdf"],
      danger: ["critical-delete"],
      critical: [{ id: "critical-delete", action: "redact", target: "modulo.pdf" }],
    });
    await new Promise((r) => setTimeout(r, 20));
    const m = t.sent.at(-1);
    const lines = m?.text.split("\n") ?? [];
    expect(lines[0]).toBe("DANGER: an action that cannot be undone");
    expect(lines[1]).toBe(
      "Removes for good the text and pictures under the chosen areas from modulo.pdf.",
    );
    expect(m?.text).toContain("Coder (demo) asks for your yes");
    // The critical reason written for the model is not repeated in English.
    expect(m?.text).not.toContain("Why:");
    // No emoji and no symbols as icons; the answer works as for any request.
    expect(m?.text).not.toMatch(/\p{Extended_Pictographic}/u);
    expect(m?.buttons?.map((b) => b.label)).toEqual(["Allow", "Deny"]);
    await send({ button: m?.buttons?.[0]?.id ?? "" });
    expect(decided).toEqual([["r2", "allow"]]);
    // An ordinary request has no danger line.
    approvals.emit("request", "me", perm);
    await new Promise((r) => setTimeout(r, 20));
    expect(t.sent.at(-1)?.text.startsWith("Approval needed")).toBe(true);
  });

  it("numbers the choices where the platform has no buttons", async () => {
    const { t, send, approvals, questions, decided, answered, asked } = await setup(false);
    approvals.emit("request", "me", perm);
    await new Promise((r) => setTimeout(r, 20));
    expect(t.sent.at(-1)?.text).toMatch(/1\. Allow\n2\. Deny/);
    await send({ text: "1" });
    expect(decided).toEqual([["r1", "allow"]]);
    // No prompt left: a number is a message again.
    await send({ text: "1" });
    expect(asked.at(-1)?.text).toBe("1");

    questions.emit("request", "me", question);
    await new Promise((r) => setTimeout(r, 20));
    expect(t.sent.at(-1)?.text).toMatch(/Which database\?[\s\S]*1\. Postgres\n2\. SQLite/);
    await send({ text: "2" });
    await new Promise((r) => setTimeout(r, 20));
    expect(t.sent.at(-1)?.text).toMatch(/Which extras\?[\s\S]*more than one/);
    await send({ text: "1, 3" });
    expect(answered).toEqual([[["SQLite"], ["Backups", "Logs"]]]);
  });

  it("takes words as the answer to a question, and buttons for single choices", async () => {
    const { t, send, questions, answered } = await setup();
    questions.emit("request", "me", question);
    await new Promise((r) => setTimeout(r, 20));
    const first = t.sent.at(-1);
    expect(first?.buttons?.map((b) => b.label)).toEqual(["Postgres", "SQLite"]);
    await send({ button: first?.buttons?.[0]?.id ?? "" });
    await new Promise((r) => setTimeout(r, 20));
    await send({ text: "none for now" });
    expect(answered).toEqual([[["Postgres"], ["none for now"]]]);
  });

  it("answers /new, /stop and /status", async () => {
    const { db } = await memoryDb();
    const t = new FakeTransport(true);
    const h = fakeHost();
    let fresh = 0;
    const host: GatewayHost = {
      ...h.host,
      newConversation: () => {
        fresh++;
      },
      stopWork: async () => false,
      statusSummary: async () => ({
        working: ["God"],
        approvals: 1,
        questions: 0,
        spentUsd: 1.5,
        limitUsd: null,
      }),
    };
    const bridge = new ChatBridge({ db, host, transport: t });
    await bridge.start();
    const { code } = bridge.pairingCode("me");
    await t.on?.({ userId: "u1", chatId: "c1", text: `/start ${code}` });
    await t.on?.({ userId: "u1", chatId: "c1", text: "/new" });
    await t.on?.({ userId: "u1", chatId: "c1", text: "/stop" });
    await t.on?.({ userId: "u1", chatId: "c1", text: "/status" });
    expect(fresh).toBe(1);
    expect(t.texts().slice(1)).toEqual([
      "New conversation: God and I start fresh.",
      "Nothing was running.",
      "Working now: God.\nWaiting for you: 1 approvals, 0 questions.\nSpent: $1.50.",
    ]);
  });
});

// Built at run time: no key-shaped literal in the sources.
const fakeToken = () => `ghp_${"A1b2".repeat(9)}`;

describe("a message that looks like a secret (2026-11-19)", () => {
  it("is held with buttons, and «Send anyway» passes it as written with secretOk", async () => {
    const { t, send, asked } = await setup();
    const text = `the link is ${fakeToken()}`;
    await send({ text });
    expect(asked).toEqual([]);
    const notice = t.sent.at(-1);
    expect(notice?.text).toMatch(/looks like it holds a secret \(a key\)/);
    expect(notice?.text).not.toContain(fakeToken());
    expect(notice?.buttons?.map((b) => b.label)).toEqual([
      "Send anyway",
      "Send without it",
      "Leave it",
    ]);
    await send({ button: notice?.buttons?.[0]?.id ?? "" });
    expect(asked).toEqual([{ chatId: "c1", text, secretOk: true }]);
    expect(t.edits.at(-1)?.text).toMatch(/Sent as written\.$/);
    // A choice counts once: the same button again sends nothing more.
    await send({ button: notice?.buttons?.[0]?.id ?? "" });
    expect(asked).toHaveLength(1);
  });

  it("«Send without it» lets the server blank it (no secretOk), «Leave it» sends nothing", async () => {
    const { t, send, asked } = await setup();
    await send({ text: `one ${fakeToken()}` });
    await send({ button: t.sent.at(-1)?.buttons?.[1]?.id ?? "" });
    expect(asked).toEqual([{ chatId: "c1", text: `one ${fakeToken()}` }]);
    expect(t.edits.at(-1)?.text).toMatch(/Sent without the secret\.$/);
    await send({ text: `two ${fakeToken()}` });
    await send({ button: t.sent.at(-1)?.buttons?.[2]?.id ?? "" });
    expect(asked).toHaveLength(1);
    expect(t.edits.at(-1)?.text).toMatch(/Not sent\.$/);
  });

  it("without buttons the choices are numbered and answered by number", async () => {
    const { t, send, asked } = await setup(false);
    await send({ text: `password: Zx81-hunter2` });
    const notice = t.sent.at(-1)?.text ?? "";
    expect(notice).toMatch(/a password/);
    expect(notice).toMatch(/1\. Send anyway\n2\. Send without it\n3\. Leave it/);
    expect(notice).not.toContain("Zx81-hunter2");
    await send({ text: "1" });
    expect(asked).toEqual([{ chatId: "c1", text: "password: Zx81-hunter2", secretOk: true }]);
    // The number answered the warning: it is not a message of its own.
    expect(asked.map((a) => a.text)).not.toContain("1");
  });

  it("only the person who sent it chooses, and a choice after the time runs out sends nothing", async () => {
    const { bridge, t, send, asked } = await setup();
    await send({ text: `x ${fakeToken()}` });
    const id = t.sent.at(-1)?.buttons?.[0]?.id ?? "";
    // Someone else linked to another owner presses it.
    const { code } = bridge.pairingCode("other");
    await send({ userId: "u2", chatId: "c2", text: `/start ${code}` });
    await send({ userId: "u2", chatId: "c2", button: id });
    expect(asked).toEqual([]);
    const realNow = Date.now;
    try {
      Date.now = () => realNow() + 11 * 60_000;
      await send({ button: id });
    } finally {
      Date.now = realNow;
    }
    expect(asked).toEqual([]);
    expect(t.edits.at(-1)?.text).toMatch(/Too late/);
  });

  it("a plain message, a link without a secret, goes on as before", async () => {
    const { send, asked } = await setup();
    await send({ text: "https://www.amazon.it/dp/B0CX23V2ZK?ref=nav_logo&th=1" });
    expect(asked).toHaveLength(1);
  });
});

const skillUpdate = {
  proposalId: "prop_1",
  name: "invoice-pdf",
  agentName: "Coder",
  line: "Added the step for .rtf files: it failed twice on Word documents",
  createdAt: new Date().toISOString(),
};

describe("a new version of a skill waiting for the person (3.9.7)", () => {
  it("comes with its line and Approve / Reject; the answer closes it", async () => {
    const { t, skills, skillDecisions } = await setup();
    skills.emit("request", "me", skillUpdate);
    await new Promise((r) => setTimeout(r, 20));
    const m = t.sent.at(-1);
    expect(m?.text).toBe(
      [
        "Coder proposes a new version of the skill «invoice-pdf»:",
        skillUpdate.line,
        `The whole comparison: ${PRODUCT_NAME}, Settings, Extensions.`,
      ].join("\n"),
    );
    expect(m?.buttons?.map((b) => b.label)).toEqual(["Approve", "Reject"]);
    await t.on?.({ userId: "u1", chatId: "c1", button: m?.buttons?.[0]?.id ?? "" });
    await new Promise((r) => setTimeout(r, 20));
    expect(skillDecisions).toEqual([["prop_1", "approve", "discord"]]);
    expect(t.edits.at(-1)?.text).toMatch(/Approved: agents use it from their next conversation\.$/);
  });

  it("without buttons it is answered by number; decided on the page, the copy says so", async () => {
    const { t, send, skills, skillDecisions } = await setup(false);
    skills.emit("request", "me", skillUpdate);
    await new Promise((r) => setTimeout(r, 20));
    expect(t.sent.at(-1)?.text).toMatch(/1\. Approve\n2\. Reject/);
    await send({ text: "2" });
    expect(skillDecisions).toEqual([["prop_1", "reject", "discord"]]);
    skills.emit("request", "me", { ...skillUpdate, proposalId: "prop_2" });
    await new Promise((r) => setTimeout(r, 20));
    skills.emit("closed", "me", "prop_2", "approve", "web");
    await new Promise((r) => setTimeout(r, 20));
    expect(t.edits.at(-1)?.text).toMatch(/Already decided by you on the web page: approved\.$/);
  });
});

describe("a password manager's export (3.9.8)", () => {
  /** Generated rows only: never a real password in a test. */
  const exportText = (n: number) =>
    [
      "name,url,username,password",
      ...Array.from(
        { length: n },
        (_, i) => `Site ${i},https://s${i}.example.com/,u${i},Gx${i}#fake${i * 31}Q`,
      ),
    ].join("\n");

  it("offers the keychain first; it imports, says only counts, and sends the words without it", async () => {
    const { t, send, asked, host } = await setup();
    const imported: string[] = [];
    host.importPasswords = async (_owner, text) => {
      imported.push(text);
      return { added: 3, skipped: 0 };
    };
    await send({ text: `here they are\n${exportText(3)}` });
    const notice = t.sent.at(-1);
    expect(notice?.text).toMatch(/3 passwords exported from a password manager/);
    expect(notice?.text).not.toContain("Gx0#fake0Q");
    expect(notice?.buttons?.map((b) => b.label)).toEqual([
      "Put them in the keychain",
      "Send without it",
      "Send anyway",
      "Leave it",
    ]);
    await send({ button: notice?.buttons?.[0]?.id ?? "" });
    expect(imported).toHaveLength(1);
    expect(t.edits.at(-1)?.text).toMatch(/In the keychain: 3 new, 0 already there/);
    // The words go on without secretOk: the server blanks the export.
    expect(asked).toEqual([{ chatId: "c1", text: `here they are\n${exportText(3)}` }]);
  });

  it("«Send anyway» asks a second time, naming how many", async () => {
    const { t, send, asked } = await setup();
    await send({ text: exportText(2) });
    await send({ button: t.sent.at(-1)?.buttons?.[2]?.id ?? "" });
    expect(asked).toEqual([]);
    const sure = t.sent.at(-1);
    expect(sure?.text).toMatch(/Send 2 passwords to the agent as written\?/);
    expect(sure?.buttons?.map((b) => b.label)).toEqual(["Yes, send 2 passwords", "Leave it"]);
    await send({ button: sure?.buttons?.[0]?.id ?? "" });
    expect(asked).toEqual([{ chatId: "c1", text: exportText(2), secretOk: true }]);
  });

  it("a closed keychain imports nothing and sends nothing", async () => {
    const { t, send, asked, host } = await setup();
    host.importPasswords = async () => {
      throw Object.assign(new Error("The keychain is closed"), { code: "vault_closed" });
    };
    await send({ text: exportText(2) });
    await send({ button: t.sent.at(-1)?.buttons?.[0]?.id ?? "" });
    expect(t.edits.at(-1)?.text).toMatch(/The keychain is closed: nothing was imported or sent/);
    expect(asked).toEqual([]);
  });
});

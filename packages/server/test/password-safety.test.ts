// 3.9.8, the person's report («Altro errore gravissimo»): a password manager's export pasted in a
// conversation reached the log, Echo, the portrait and the engine's transcript. Here: the server
// blanks an export the page did not hold, the keychain takes it without the model seeing a value
// (from the composer, from a chat, from an agent's proposal), and «Cancella per sempre» erases a
// message everywhere, the engine's transcript rewritten with its owner and mode. Every password
// here is generated: no real one ever appears in a test.
import { mkdir, mkdtemp, readdir, readFile, stat, writeFile } from "node:fs/promises";
import { tmpdir } from "node:os";
import { join } from "node:path";
import type { CompletionRequest } from "@redgiant/protocol";
import type { FakeTurn } from "@redgiant/providers";
import { afterEach, describe, expect, it } from "vitest";
import {
  cleanTranscript,
  ERASED_MARK,
  fingerprints,
  rewriteTranscript,
} from "../src/erase-message.js";
import type { MasterKeyStore } from "../src/vault.js";
import { blankPastedSecrets, Vault } from "../src/vault.js";
import { startServer } from "./helpers.js";

const fake = (i: number) => `Pw${(i * 104729).toString(36)}!x${i % 7}Q`;
const exportCsv = (n: number) =>
  [
    "name,url,username,password,note",
    ...Array.from(
      { length: n },
      (_, i) => `Site ${i},https://site${i}.example.com/,user${i}@example.com,${fake(i)},`,
    ),
  ].join("\n");

const memKeys = (): MasterKeyStore => {
  let key: Buffer | null = null;
  return {
    kind: "file",
    load: async () => key,
    save: async (k: Buffer) => {
      key = k;
    },
  };
};

describe("password exports never reach the model (3.9.8)", () => {
  it("the server blanks an export the page did not hold, and the agent hears how many", () => {
    const out = blankPastedSecrets(`ecco\n${exportCsv(4)}`);
    for (let i = 0; i < 4; i++) expect(out).not.toContain(fake(i));
    expect(out).toContain("4 passwords");
    expect(out).toContain("keychain");
  });

  it("the keychain takes an export in one write, only names and counts come back", async () => {
    const dir = join(await mkdtemp(join(tmpdir(), "rg-pw-")), "keychain");
    const v = new Vault({ dir, keyStores: [memKeys()] });
    await v.open();
    const r = await v.importExportText("me", exportCsv(5));
    expect(r.added).toBe(5);
    expect(r.skipped).toBe(0);
    expect(JSON.stringify(r)).not.toContain(fake(0));
    const view = await v.view("me");
    expect(view.entries.map((e) => e.username).sort()).toContain("user1@example.com");
    expect(v.reveal("me", r.names[2] as string)).toBe(fake(2));
    // Every entry is the person's only: no agent, asked every time.
    expect(view.entries.every((e) => e.ask === "always" && !e.allow.allAgents)).toBe(true);
    // The same export again: nothing new.
    expect(await v.importExportText("me", exportCsv(5))).toMatchObject({ added: 0, skipped: 5 });
    // The file on disk is sealed.
    expect(await readFile(join(dir, "keychain.enc"), "utf8")).not.toContain(fake(1));
  });

  it("a closed keychain imports nothing and says so", async () => {
    const dir = join(await mkdtemp(join(tmpdir(), "rg-pw-")), "keychain");
    const broken: MasterKeyStore = {
      kind: "file",
      load: async () => null,
      save: async () => {
        throw new Error("no");
      },
    };
    const v = new Vault({ dir, keyStores: [broken] });
    await v.open();
    expect(v.ready).toBe(false);
    await expect(v.importExportText("me", exportCsv(2))).rejects.toMatchObject({
      code: "vault_closed",
    });
  });
});

describe("an engine's transcript without the erased text (3.9.8)", () => {
  const secret = exportCsv(3);
  const fp = fingerprints(`please keep these\n${secret}`);
  const lines = [
    JSON.stringify({
      type: "user",
      message: { role: "user", content: `please keep these\n${secret}` },
    }),
    JSON.stringify({
      type: "assistant",
      message: {
        content: [
          { type: "thinking", thinking: `the rows: ${fake(1)}`, signature: "sig" },
          { type: "text", text: "I will not repeat them." },
        ],
      },
    }),
    JSON.stringify({ type: "assistant", message: { content: [{ type: "text", text: "ok" }] } }),
  ];

  it("replaces the strings holding it and drops the thinking blocks holding it", () => {
    const out = cleanTranscript(lines.join("\n"), fp);
    expect(out.left).toBe(0);
    expect(out.changed).toBe(2);
    for (let i = 0; i < 3; i++) expect(out.text).not.toContain(fake(i));
    expect(out.text).toContain(ERASED_MARK);
    expect(out.text).toContain("I will not repeat them.");
    expect(out.text).not.toContain('"thinking"');
  });

  it("rewrites the file with its mode, and the old one is gone", async () => {
    const dir = await mkdtemp(join(tmpdir(), "rg-tr-"));
    const file = join(dir, "abc123def.jsonl");
    await writeFile(file, lines.join("\n"), { mode: 0o640 });
    const before = await stat(file);
    expect(await rewriteTranscript(file, fp)).toBe(2);
    const after = await stat(file);
    expect(after.mode & 0o777).toBe(before.mode & 0o777);
    expect(after.uid).toBe(before.uid);
    expect(await readdir(dir)).toEqual(["abc123def.jsonl"]);
    expect(await readFile(file, "utf8")).not.toContain(fake(0));
    // Nothing to change: the file is not touched.
    expect(await rewriteTranscript(file, fp)).toBe(0);
  });
});

describe("«Cancella per sempre» on one message (3.9.8)", () => {
  let s: Awaited<ReturnType<typeof startServer>>;
  afterEach(() => s?.close());

  it("erases the message and the replies quoting it from the log, Echo and the engine's transcript", async () => {
    const seen: string[] = [];
    s = await startServer((req: CompletionRequest): FakeTurn => {
      seen.push(JSON.stringify(req.messages));
      return { text: "Noted: the warehouse code is MAG-4471-WAREHOUSE." };
    });
    const god = (
      await s.api<{ id: string }>("POST", "/api/agents", {
        kind: "god",
        parentId: null,
        name: "God",
      })
    ).body.id;
    const sid = (await s.api<{ sessionId: string }>("POST", "/api/sessions", { agentId: god })).body
      .sessionId;
    await (await s.core.send("me", sid, "The warehouse code is MAG-4471-WAREHOUSE, remember it"))
      .done;
    await (await s.core.send("me", sid, "and the weather is nice today")).done;
    const events = await s.core.store.list({ sessionId: sid });
    const user = events.find((e) => e.type === "message.user");
    expect(user).toBeDefined();
    const seq = user?.seq as number;
    // A fake engine transcript for this conversation, under a fake engine's home.
    const home = join(s.dir, "engine-home");
    await mkdir(join(home, "projects", "work"), { recursive: true });
    const transcript = join(home, "projects", "work", "engine-sess-001.jsonl");
    await writeFile(
      transcript,
      `${JSON.stringify({ type: "user", message: { content: "The warehouse code is MAG-4471-WAREHOUSE, remember it" } })}\n${JSON.stringify({ type: "user", message: { content: "and the weather is nice today" } })}\n`,
      { mode: 0o600 },
    );
    s.core.engineHomes.set("fake-engine", home);
    await s.core.store.append({
      ownerId: "me",
      sessionId: sid,
      body: { type: "engine.session", payload: { engine: "fake-engine", id: "engine-sess-001" } },
    });
    await s.core.echo.catchUp();

    const pre = await s.api<{ quotes: number; engine: boolean }>(
      "POST",
      `/api/sessions/${sid}/erase-preview`,
      { seq },
    );
    expect(pre.body).toEqual({ quotes: 2, engine: true });
    const r = await s.api<{ erased: number; seqs: number[]; transcripts: number }>(
      "POST",
      `/api/sessions/${sid}/erase`,
      { seq, withQuotes: true },
    );
    expect(r.status).toBe(200);
    expect(r.body.erased).toBe(3);
    expect(r.body.transcripts).toBe(1);
    const rows = await s.core.store.list({ sessionId: sid });
    for (const e of rows) expect(JSON.stringify(e.payload ?? "")).not.toContain("MAG-4471");
    expect(rows.filter((e) => e.type === "redaction")).toHaveLength(3);
    const tr = await readFile(transcript, "utf8");
    expect(tr).not.toContain("MAG-4471");
    expect(tr).toContain("the weather is nice");
    expect((await stat(transcript)).mode & 0o777).toBe(0o600);
    const hits = await s.core.echo.search("me", { query: "warehouse", agents: [god] });
    expect(hits).toEqual([]);
    // The next turn is rebuilt from the log: the erased words are not in the model's history.
    seen.length = 0;
    await (await s.core.send("me", sid, "anything else?")).done;
    expect(seen.join("")).not.toContain("MAG-4471");
    expect(seen.join("")).toContain("the weather is nice");
  });

  it("refuses while a turn runs, and an agent's message is not the person's to erase this way", async () => {
    s = await startServer(() => ({ text: "fine" }));
    const god = (
      await s.api<{ id: string }>("POST", "/api/agents", {
        kind: "god",
        parentId: null,
        name: "God",
      })
    ).body.id;
    const sid = (await s.api<{ sessionId: string }>("POST", "/api/sessions", { agentId: god })).body
      .sessionId;
    await (await s.core.send("me", sid, "hello there, this is a message")).done;
    const answer = (await s.core.store.list({ sessionId: sid })).find(
      (e) => e.type === "message.assistant",
    );
    const r = await s.api("POST", `/api/sessions/${sid}/erase`, { seq: answer?.seq });
    expect(r.status).toBe(400);
    // Someone else cannot erase it.
    const user = (await s.core.store.list({ sessionId: sid })).find(
      (e) => e.type === "message.user",
    );
    const other = await s.api(
      "POST",
      `/api/sessions/${sid}/erase`,
      { seq: user?.seq },
      "other-token-0123456789",
    );
    expect(other.status).toBe(400);
  });
});

// The secretary through the HTTP API (3.12.4): public signed webhooks, the person's own routes, a
// real core with a fake model and a fake Meta (a function). No network.
import { createHmac } from "node:crypto";
import { afterEach, describe, expect, it } from "vitest";
import { startServer } from "./helpers.js";

type Server = Awaited<ReturnType<typeof startServer>>;
let s: Server | undefined;
afterEach(async () => {
  await s?.close();
  s = undefined;
});

const SECRET = "fedcba9876543210fedcba9876543210";
const TOKEN = "EAAG-route-token-long-enough-1234567";

const graph = (sent: unknown[]) =>
  (async (url: string | URL | Request, init?: RequestInit) => {
    const u = String(url);
    const auth = (init?.headers as Record<string, string>)?.authorization;
    if (auth !== `Bearer ${TOKEN}`)
      return new Response(JSON.stringify({ error: { message: "bad", code: 190 } }), {
        status: 401,
      });
    if (u.includes("/messages")) {
      sent.push(JSON.parse(String(init?.body)));
      return new Response(JSON.stringify({ messages: [{ id: "wamid.1" }] }));
    }
    return new Response(JSON.stringify({ display_phone_number: "+39 1", verified_name: "X" }));
  }) as typeof fetch;

describe("secretary routes", () => {
  it("connects WhatsApp by the guide, receives a signed message and routes it to the person", async () => {
    const sent: unknown[] = [];
    s = await startServer(
      [
        {
          text: JSON.stringify({
            action: "escalate",
            reason: "commitment",
            summary: "Wants a table for 4 on Friday",
            draft: "Certo, venerdì alle 20 va bene.",
          }),
        },
      ],
      {},
      { secretaryFetch: graph(sent) },
    );
    const me = { type: "human" as const, ownerId: "me" };
    const god = await s.core.registry.create(me, { kind: "god", parentId: null, name: "God" });
    const agent = await s.core.registry.create(me, {
      kind: "demigod",
      parentId: god.id,
      name: "Segretario",
      systemPrompt: "Restaurant open 12-23.",
      model: { provider: "fake", model: "m" },
    });

    // No way in from outside yet: the guide says so.
    const no = await s.api<{ code: string }>("POST", "/api/secretary/whatsapp/start", {
      name: "T",
    });
    expect(no.status).toBe(400);
    expect(no.body.code).toBe("no_remote");
    s.core.setPublicUrl("https://rg.example.test");
    const start = await s.api<{ id: string; verifyToken: string; webhookUrl: string }>(
      "POST",
      "/api/secretary/whatsapp/start",
      { name: "Trattoria", agentId: agent.id },
    );
    expect(start.status).toBe(201);
    expect(start.body.webhookUrl).toBe(
      `https://rg.example.test/api/secretary/whatsapp/${start.body.id}/webhook`,
    );

    // Meta's handshake needs no sign-in, only the verify token.
    const hook = `${s.url}/api/secretary/whatsapp/${start.body.id}/webhook`;
    expect(
      (await fetch(`${hook}?hub.mode=subscribe&hub.verify_token=bad&hub.challenge=7`)).status,
    ).toBe(403);
    const ok = await fetch(
      `${hook}?hub.mode=subscribe&hub.verify_token=${start.body.verifyToken}&hub.challenge=7`,
    );
    expect(await ok.text()).toBe("7");

    const wrong = await s.api("POST", `/api/secretary/whatsapp/${start.body.id}/finish`, {
      phoneNumberId: "123456",
      token: "t".repeat(30),
      appSecret: SECRET,
    });
    expect(wrong.status).toBe(400);
    expect(wrong.body).toMatchObject({ code: "bad_token" });
    const fin = await s.api("POST", `/api/secretary/whatsapp/${start.body.id}/finish`, {
      phoneNumberId: "123456",
      token: TOKEN,
      appSecret: SECRET,
    });
    expect(fin.status).toBe(200);
    expect(JSON.stringify(fin.body)).not.toContain(TOKEN);
    expect(s.core.vault.systemValue("me", `secretary:${start.body.id}:token`)).toBe(TOKEN);

    const payload = JSON.stringify({
      entry: [
        {
          changes: [
            {
              value: {
                metadata: { phone_number_id: "123456" },
                contacts: [{ wa_id: "39333", profile: { name: "Anna" } }],
                messages: [
                  {
                    from: "39333",
                    id: "m1",
                    timestamp: String(Math.floor(Date.now() / 1000)),
                    type: "text",
                    text: { body: "Un tavolo per 4 venerdì?" },
                  },
                ],
              },
            },
          ],
        },
      ],
    });
    const bad = await fetch(hook, {
      method: "POST",
      body: payload,
      headers: { "x-hub-signature-256": "sha256=0" },
    });
    expect(bad.status).toBe(403);
    const sig = `sha256=${createHmac("sha256", SECRET).update(payload).digest("hex")}`;
    const good = await fetch(hook, {
      method: "POST",
      body: payload,
      headers: { "x-hub-signature-256": sig },
    });
    expect(good.status).toBe(200);
    await new Promise((r) => setTimeout(r, 400));

    const list = await s.api<{
      contacts: { id: string; name: string }[];
      pending: { id: string; reason: string; draft: string }[];
    }>("GET", "/api/secretary/contacts");
    expect(list.body.contacts.map((c) => c.name)).toEqual(["Anna"]);
    expect(list.body.pending[0]).toMatchObject({
      reason: "commitment",
      draft: "Certo, venerdì alle 20 va bene.",
    });
    expect(sent).toEqual([]);
    const yes = await s.api(
      "POST",
      `/api/secretary/pending/${list.body.pending[0]?.id}/approve`,
      {},
    );
    expect(yes.status).toBe(200);
    expect(sent).toEqual([
      expect.objectContaining({
        to: "39333",
        text: { body: "Certo, venerdì alle 20 va bene.", preview_url: false },
      }),
    ]);
    const conv = await s.api<{ messages: { by: string }[] }>(
      "GET",
      `/api/secretary/contacts/${list.body.contacts[0]?.id}`,
    );
    expect(conv.body.messages.map((m) => m.by)).toEqual(["contact", "person"]);

    // Another person cannot read it; the keys leave with the account.
    expect(
      (
        await s.api(
          "GET",
          `/api/secretary/contacts/${list.body.contacts[0]?.id}`,
          undefined,
          "other-token",
        )
      ).status,
    ).toBe(401);
    expect((await s.api("DELETE", `/api/secretary/accounts/${start.body.id}`)).status).toBe(200);
    expect(s.core.vault.systemValue("me", `secretary:${start.body.id}:token`)).toBeUndefined();
  });

  /** A WhatsApp account with a fake model that always asks for a ready reply. */
  async function asking(reason: "commitment" | "unknown", mode: "ask" | "classifier" = "ask") {
    const sent: unknown[] = [];
    s = await startServer(
      [
        {
          text: JSON.stringify({
            action: "escalate",
            reason,
            summary: "Wants a table",
            draft: "Friday at 8 is fine.",
          }),
        },
      ],
      {},
      { secretaryFetch: graph(sent) },
    );
    const me = { type: "human" as const, ownerId: "me" };
    const god = await s.core.registry.create(me, { kind: "god", parentId: null, name: "God" });
    const agent = await s.core.registry.create(me, {
      kind: "demigod",
      parentId: god.id,
      name: "Segretario",
      model: { provider: "fake", model: "m" },
    });
    s.core.setPublicUrl("https://rg.example.test");
    await s.core.requestSettings.set("me", { mode });
    const start = await s.core.secretary.startWhatsApp("me", "T", agent.id);
    await s.core.secretary.finishWhatsApp("me", start.id, {
      name: "",
      phoneNumberId: "123456",
      token: TOKEN,
      appSecret: SECRET,
    });
    // Two fake channels listen as the gateways do (a chat with buttons, the phone's push).
    const chat: {
      opened: { id: string; tool: string; input: unknown }[];
      closed: [string, string | undefined][];
    } = {
      opened: [],
      closed: [],
    };
    const push = { opened: [] as string[], closed: [] as string[] };
    s.core.approvals.on("request", (_o, info) => {
      chat.opened.push({ id: info.requestId, tool: info.tool, input: info.input });
      push.opened.push(info.requestId);
    });
    s.core.approvals.on("closed", (_o, id, _d, via) => {
      chat.closed.push([id, via]);
      push.closed.push(id);
    });
    const payload = JSON.stringify({
      entry: [
        {
          changes: [
            {
              value: {
                metadata: { phone_number_id: "123456" },
                contacts: [{ wa_id: "39333", profile: { name: "Anna" } }],
                messages: [
                  {
                    from: "39333",
                    id: `m${Math.random()}`,
                    timestamp: String(Math.floor(Date.now() / 1000)),
                    type: "text",
                    text: { body: "Un tavolo per 4 venerdì?" },
                  },
                ],
              },
            },
          ],
        },
      ],
    });
    const r = await s.core.secretary.whatsappWebhook(
      start.id,
      payload,
      `sha256=${createHmac("sha256", SECRET).update(payload).digest("hex")}`,
    );
    await r.done;
    return { sent, chat, push };
  }

  it("a commitment reaches the page's requests, the chats and the phone; the first answer closes the others", async () => {
    const { sent, chat, push } = await asking("commitment");
    // Even with «don't ask me anything»: a commitment always asks.
    expect(chat.opened).toHaveLength(1);
    const asked = chat.opened[0] as { id: string; tool: string; input: Record<string, string> };
    expect(asked.tool).toBe("secretary_reply");
    expect(asked.input).toMatchObject({ contact: "Anna", reply: "Friday at 8 is fine." });
    expect(push.opened).toEqual([asked.id]);
    const page = await (s as Server).api<{ requestId: string; tool: string }[]>(
      "GET",
      "/api/permissions",
    );
    expect(page.body.map((p) => p.requestId)).toEqual([asked.id]);
    expect(sent).toEqual([]);
    // Answered in Telegram: the page and the phone see it closed, and the reply goes out.
    (s as Server).core.approvals.decide("me", asked.id, "allow", undefined, "telegram");
    await (s as Server).core.secretary.engine.idle();
    expect(chat.closed).toEqual([[asked.id, "telegram"]]);
    expect(sent).toEqual([
      expect.objectContaining({
        to: "39333",
        text: { body: "Friday at 8 is fine.", preview_url: false },
      }),
    ]);
    expect((await (s as Server).api<unknown[]>("GET", "/api/permissions")).body).toEqual([]);
    expect(await (s as Server).core.secretary.pending("me")).toEqual([]);
  });

  it("a no on the page refuses the reply; answering in Messages closes the request everywhere", async () => {
    const a = await asking("commitment");
    const id = (a.chat.opened[0] as { id: string }).id;
    expect(
      (await (s as Server).api("POST", `/api/permissions/${id}`, { decision: "deny" })).status,
    ).toBe(200);
    await (s as Server).core.secretary.engine.idle();
    expect(a.sent).toEqual([]);
    expect(await (s as Server).core.secretary.pending("me")).toEqual([]);
    await s?.close();
    const b = await asking("commitment");
    const id2 = (b.chat.opened[0] as { id: string }).id;
    const [p] = await (s as Server).core.secretary.pending("me");
    await (s as Server).core.secretary.approve("me", (p as { id: string }).id);
    await (s as Server).core.secretary.engine.idle();
    expect(b.chat.closed.map((c) => c[0])).toEqual([id2]);
    expect((await (s as Server).api<unknown[]>("GET", "/api/permissions")).body).toEqual([]);
    expect(b.sent).toHaveLength(1);
  });

  it("with «don't ask me anything» an ordinary request is the classifier's, a commitment still asks", async () => {
    const plain = await asking("unknown", "classifier");
    expect(plain.chat.opened).toHaveLength(0);
    expect(await (s as Server).core.secretary.pending("me")).toHaveLength(1);
    await s?.close();
    const hard = await asking("commitment", "classifier");
    expect(hard.chat.opened).toHaveLength(1);
    expect(hard.sent).toEqual([]);
  });
});

// Calendars, per-agent connections and the ready-made sets (3.12.3), end to end with a fake model, a
// fake CalDAV/iCal server (a function, never the network) and the settings' own routes.
import type { CompletionRequest } from "@redgiant/providers";
import { afterEach, describe, expect, it } from "vitest";
import { startServer, wsClient } from "./helpers.js";
import { mailServers, rawMail } from "./mail-servers.js";

type Server = Awaited<ReturnType<typeof startServer>>;
let s: Server | undefined;
afterEach(async () => {
  await s?.close();
  s = undefined;
});

const ROOM = { contextWindow: 65_536 };
const DAV = "https://dav.example.test/cal/home/";
const USER = "marta";
const PASS = "dav-password-42";
const ICS_URL = "https://calendar.google.example/private-SECRET123/basic.ics";

const vevent = (uid: string, summary: string, start: string) =>
  `BEGIN:VCALENDAR\r\nVERSION:2.0\r\nBEGIN:VEVENT\r\nUID:${uid}\r\nDTSTART:${start}\r\nDTEND:${start}\r\nSUMMARY:${summary}\r\nEND:VEVENT\r\nEND:VCALENDAR\r\n`;

/** A CalDAV collection and an iCal feed in a function: it records what it was asked. */
function fakeDav() {
  const objects: string[] = [vevent("a@x", "Dentist", "20261126T090000Z")];
  const calls: { method: string; url: string; auth: string | null; body: string }[] = [];
  const feed = `BEGIN:VCALENDAR\r\nVERSION:2.0\r\n${vevent("g@x", "Football", "20261127T180000Z").split("\r\n").slice(2, -2).join("\r\n")}\r\nEND:VCALENDAR\r\n`;
  const fetcher = async (url: string, init: RequestInit): Promise<Response> => {
    const headers = (init.headers ?? {}) as Record<string, string>;
    calls.push({
      method: init.method ?? "GET",
      url,
      auth: headers.authorization ?? null,
      body: typeof init.body === "string" ? init.body : "",
    });
    if (url === ICS_URL) return new Response(feed, { status: 200 });
    if (!url.startsWith(DAV)) return new Response("no", { status: 404 });
    const ok = `Basic ${Buffer.from(`${USER}:${PASS}`).toString("base64")}`;
    if (headers.authorization !== ok) return new Response("denied", { status: 401 });
    if (init.method === "PROPFIND") return new Response("<multistatus/>", { status: 207 });
    if (init.method === "REPORT") {
      const data = objects.map(
        (o) =>
          `<d:response><d:propstat><d:prop><c:calendar-data>${o}</c:calendar-data></d:prop></d:propstat></d:response>`,
      );
      return new Response(
        `<d:multistatus xmlns:d="DAV:" xmlns:c="urn:ietf:params:xml:ns:caldav">${data.join("")}</d:multistatus>`,
        { status: 207 },
      );
    }
    if (init.method === "PUT") {
      objects.push(String(init.body));
      return new Response("", { status: 201 });
    }
    return new Response("", { status: 405 });
  };
  return { fetcher, calls, objects };
}

async function team(server: Server, connections?: unknown) {
  const god = await server.api<{ id: string }>("POST", "/api/agents", {
    kind: "god",
    parentId: null,
    name: "God",
  });
  const a = await server.api<{ id: string }>("POST", "/api/agents", {
    kind: "assistant",
    parentId: god.body.id,
    name: "Agenda",
    role: "Keeps the diary",
    ...(connections !== undefined && { connections }),
  });
  expect(a.status).toBe(201);
  const { body } = await server.api<{ sessionId: string }>("POST", "/api/sessions", {
    agentId: a.body.id,
  });
  return { god: god.body.id, agent: a.body.id, sessionId: body.sessionId };
}

const resultOf = (req: CompletionRequest) => {
  const part = req.messages.at(-1)?.parts.find((p) => p.type === "tool_result") as
    | { content: string }
    | undefined;
  return part?.content;
};

/** A model that calls the tools in turn, and keeps what each answered. */
function script(calls: { name: string; input: unknown }[]) {
  const seen: string[] = [];
  return {
    seen,
    fn: (req: CompletionRequest) => {
      const r = resultOf(req);
      if (r !== undefined) seen.push(r);
      const next = calls[seen.length];
      return next ? { toolCalls: [next] } : { text: "Done." };
    },
  };
}

const addCal = (server: Server, body: Record<string, unknown>) =>
  server.api<Record<string, unknown> & { id: string }>("POST", "/api/settings/calendars", body);

describe("calendars in Settings", () => {
  it("adds CalDAV and iCal calendars, keeps the secrets in the keychain and never sends them back", async () => {
    const dav = fakeDav();
    s = await startServer({ text: "x" }, ROOM, { calendarFetch: dav.fetcher });
    const bad = await addCal(s, {
      name: "Home",
      kind: "caldav",
      url: DAV,
      user: USER,
      password: "wrong",
    });
    expect(bad.status).toBe(400);
    expect(JSON.stringify(bad.body)).not.toContain("wrong");
    const home = await addCal(s, {
      name: "Home",
      kind: "caldav",
      url: DAV,
      user: USER,
      password: PASS,
    });
    expect(home.status).toBe(201);
    expect(home.body).toMatchObject({ kind: "caldav", writable: true, user: USER });
    const g = await addCal(s, {
      name: "Google",
      kind: "ics",
      url: ICS_URL.replace("https://", "webcal://"),
    });
    expect(g.status).toBe(201);
    expect(g.body).toMatchObject({ kind: "ics", writable: false, url: "calendar.google.example" });
    const list = await s.api("GET", "/api/settings/calendars");
    const text = JSON.stringify(list.body);
    expect(text).not.toContain(PASS);
    expect(text).not.toContain("SECRET123");
    // The keychain holds both, as entries a part of RedGiant uses.
    const view = JSON.stringify((await s.api("GET", "/api/vault")).body);
    expect(view).toContain(`calendar:${home.body.id}`);
    expect(view).toContain(`calendar:${g.body.id}`);
    expect(view).not.toContain(PASS);
    expect(view).not.toContain("SECRET123");
    expect(s.core.vault.systemValue("me", `calendar:${home.body.id}`)).toBe(PASS);
    expect(s.core.vault.systemValue("me", `calendar:${g.body.id}`)).toBe(ICS_URL);
    // An address that is not a calendar is refused before it is kept.
    const nope = await addCal(s, { name: "x", kind: "ics", url: "https://dav.example.test/other" });
    expect(nope.status).toBe(400);
    // Removing one removes its secret.
    expect((await s.api("DELETE", `/api/settings/calendars/${g.body.id}`)).status).toBe(200);
    expect(s.core.vault.systemValue("me", `calendar:${g.body.id}`)).toBeUndefined();
    expect(
      (await s.api<{ calendars: unknown[] }>("GET", "/api/settings/calendars")).body.calendars,
    ).toHaveLength(1);
  });
});

describe("an agent's calendars", () => {
  async function setup(
    calls: { name: string; input: unknown }[],
    connected: "home" | "google" | "both" | "none",
  ) {
    const dav = fakeDav();
    const sc = script(calls);
    s = await startServer(sc.fn, ROOM, { calendarFetch: dav.fetcher });
    const home = await addCal(s, {
      name: "Home",
      kind: "caldav",
      url: DAV,
      user: USER,
      password: PASS,
      agents: true,
    });
    const g = await addCal(s, { name: "Google", kind: "ics", url: ICS_URL, agents: true });
    const closed = await addCal(s, {
      name: "Private",
      kind: "caldav",
      url: DAV,
      user: USER,
      password: PASS,
    });
    const refs = [
      ...(connected === "home" || connected === "both"
        ? [{ kind: "calendar", ref: home.body.id }]
        : []),
      ...(connected === "google" || connected === "both"
        ? [{ kind: "calendar", ref: g.body.id }]
        : []),
      // A calendar the person did not open to the agents is never seen, even if listed.
      ...(connected !== "none" ? [{ kind: "calendar", ref: closed.body.id }] : []),
    ];
    const t = await team(s, refs);
    return { dav, sc, t, ids: { home: home.body.id, g: g.body.id } };
  }

  it("lists the events of exactly the calendars connected to it", async () => {
    const range = { from: "2026-11-25", to: "2026-11-30" };
    const a = await setup([{ name: "calendar_list_events", input: range }], "both");
    await (await s?.core.send("me", a.t.sessionId, "What is on this week?"))?.done;
    expect(a.sc.seen[0]).toContain("Dentist");
    expect(a.sc.seen[0]).toContain("[Home]");
    expect(a.sc.seen[0]).toContain("Football");
    expect(a.sc.seen[0]).not.toContain("Private");
    await s?.close();
    const b = await setup([{ name: "calendar_list_events", input: range }], "google");
    await (await s?.core.send("me", b.t.sessionId, "What is on this week?"))?.done;
    expect(b.sc.seen[0]).toContain("Football");
    expect(b.sc.seen[0]).not.toContain("Dentist");
    // The CalDAV server was never asked for this agent.
    expect(b.dav.calls.filter((c) => c.method === "REPORT")).toEqual([]);
  });

  it("an agent connected to no calendar sees none", async () => {
    const a = await setup([{ name: "calendar_list_events", input: {} }], "none");
    await (await s?.core.send("me", a.t.sessionId, "Agenda?"))?.done;
    expect(a.sc.seen[0]).toMatch(/No calendar is connected to you/);
  });

  it("an event is written only after the person's yes, and an iCal address cannot be written", async () => {
    const a = await setup(
      [
        {
          name: "calendar_create_event",
          input: {
            calendar: "Home",
            summary: "Call the dentist",
            start: "2026-11-27T15:00:00Z",
            end: "2026-11-27T15:30:00Z",
          },
        },
      ],
      "both",
    );
    const c = await wsClient((s as Server).url);
    c.send({ type: "session.follow", sessionId: a.t.sessionId });
    await c.waitFor("session.synced");
    c.send({
      type: "session.send",
      sessionId: a.t.sessionId,
      text: "Put the dentist call in my diary",
    });
    const req = await c.waitFor("permission.request", () => true, 15_000);
    expect(req.request.tool).toBe("calendar_create_event");
    expect(req.request.danger).toContain("calendar-write");
    // Nothing is written while the request waits.
    expect(a.dav.calls.filter((x) => x.method === "PUT")).toEqual([]);
    c.send({
      type: "permission.resolve",
      requestId: req.request.requestId,
      decision: "allow",
      remember: false,
    });
    await c.waitFor(
      "event",
      (e) => e.event.type === "message.assistant" && e.event.payload?.stopReason === "end_turn",
      15_000,
    );
    c.close();
    const put = a.dav.calls.filter((x) => x.method === "PUT");
    expect(put).toHaveLength(1);
    expect(put[0]?.url.startsWith(DAV)).toBe(true);
    expect(put[0]?.body).toContain("SUMMARY:Call the dentist");
    expect(put[0]?.body).toContain("DTSTART:20261127T150000Z");
    expect(a.sc.seen[0]).toMatch(/Added "Call the dentist" to "Home"/);
  });

  it("a no writes nothing", async () => {
    const a = await setup(
      [{ name: "calendar_create_event", input: { summary: "x", start: "2026-11-27T15:00:00Z" } }],
      "home",
    );
    const c = await wsClient((s as Server).url);
    c.send({ type: "session.follow", sessionId: a.t.sessionId });
    await c.waitFor("session.synced");
    c.send({ type: "session.send", sessionId: a.t.sessionId, text: "Add x" });
    const req = await c.waitFor("permission.request", () => true, 15_000);
    c.send({
      type: "permission.resolve",
      requestId: req.request.requestId,
      decision: "deny",
      remember: false,
    });
    await c.waitFor(
      "event",
      (e) => e.event.type === "message.assistant" && e.event.payload?.stopReason === "end_turn",
      15_000,
    );
    c.close();
    expect(a.dav.calls.filter((x) => x.method === "PUT")).toEqual([]);
    expect(a.sc.seen[0]).toMatch(/Permission denied/);
  });
});

describe("an agent's chats", () => {
  it("sees and writes only on the chats connected to it", async () => {
    const sc = script([
      { name: "chat_accounts", input: {} },
      { name: "chat_send", input: { text: "Anna asks about Monday" } },
      { name: "chat_send", input: { text: "x", chat: "discord" } },
    ]);
    s = await startServer(sc.fn, ROOM);
    const sent: { text: string; to?: string[] | undefined }[] = [];
    s.core.automationLinks = async () => ({
      chats: ["telegram", "whatsapp", "discord"],
      mailboxes: [],
    });
    s.core.notify = async (_o, text, to) => {
      sent.push({ text, to });
      return { delivered: to ?? [], failed: [] };
    };
    const t = await team(s, [
      { kind: "chat", ref: "whatsapp" },
      { kind: "chat", ref: "telegram" },
    ]);
    await (await s.core.send("me", t.sessionId, "Tell me what Anna says"))?.done;
    expect(sc.seen[0]).toContain("telegram, whatsapp");
    expect(sc.seen[0]).not.toContain("discord");
    expect(sent[0]).toEqual({ text: "Anna asks about Monday", to: ["telegram", "whatsapp"] });
    expect(sc.seen[1]).toMatch(/Sent on/);
    // Discord is linked but not connected to this agent.
    expect(sc.seen[2]).toMatch(/"discord" is not one of yours/);
    expect(sent).toHaveLength(1);
  });
});

describe("connections, without limit and without loss", () => {
  it("old MCP names become typed references; any number of every kind is kept", async () => {
    s = await startServer({ text: "x" }, ROOM);
    const god = await s.api<{ id: string }>("POST", "/api/agents", {
      kind: "god",
      parentId: null,
      name: "God",
    });
    const a = await s.api<{ id: string; connections: unknown[] }>("POST", "/api/agents", {
      kind: "assistant",
      parentId: god.body.id,
      name: "Old",
      role: "r",
      connections: ["notes", "files"],
    });
    expect(a.body.connections).toEqual([
      { kind: "mcp", ref: "notes" },
      { kind: "mcp", ref: "files" },
    ]);
    // A row stored by an older version (strings in the column) reads the same, after a restart.
    await s.core.db.query("UPDATE rg_agents SET connections = $2 WHERE id = $1", [
      a.body.id,
      JSON.stringify(["old-a", "old-b"]),
    ]);
    await s.core.registry.load();
    expect(s.core.registry.get(a.body.id)?.connections).toEqual([
      { kind: "mcp", ref: "old-a" },
      { kind: "mcp", ref: "old-b" },
    ]);
    const many = [
      ...Array.from({ length: 30 }, (_, i) => ({ kind: "mailbox", ref: `box_${i}` })),
      ...Array.from({ length: 12 }, (_, i) => ({ kind: "calendar", ref: `cal_${i}` })),
      { kind: "chat", ref: "telegram" },
      { kind: "chat", ref: "whatsapp" },
      "notes",
    ];
    const put = await s.api("PATCH", `/api/agents/${a.body.id}`, { connections: many });
    expect(put.status).toBe(200);
    const list = await s.api<{ id: string; connections: { kind: string; ref: string }[] }[]>(
      "GET",
      "/api/agents",
    );
    const got = { body: list.body.find((x) => x.id === a.body.id) as (typeof list.body)[number] };
    expect(got.body.connections).toHaveLength(45);
    expect(got.body.connections.filter((c) => c.kind === "mailbox")).toHaveLength(30);
    expect(got.body.connections.at(-1)).toEqual({ kind: "mcp", ref: "notes" });
    expect(
      (
        await s.api("PATCH", `/api/agents/${a.body.id}`, {
          connections: [{ kind: "bogus", ref: "x" }],
        })
      ).status,
    ).toBe(400);
  });

  it("the options list what can be connected: mailboxes and calendars open to the agents, chats, servers", async () => {
    const dav = fakeDav();
    s = await startServer({ text: "x" }, ROOM, { calendarFetch: dav.fetcher });
    s.core.automationLinks = async () => ({ chats: ["telegram"], mailboxes: [] });
    await addCal(s, {
      name: "Home",
      kind: "caldav",
      url: DAV,
      user: USER,
      password: PASS,
      agents: true,
    });
    await addCal(s, { name: "Hidden", kind: "caldav", url: DAV, user: USER, password: PASS });
    const o = await s.api<{
      calendars: { name: string }[];
      chats: string[];
      mailboxes: unknown[];
      mcp: string[];
    }>("GET", "/api/connections/options");
    expect(o.body.calendars.map((c) => c.name)).toEqual(["Home"]);
    expect(o.body.chats).toEqual(["telegram"]);
    expect(o.body.mailboxes).toEqual([]);
    expect(Array.isArray(o.body.mcp)).toBe(true);
  });
});

describe("the ready-made sets", () => {
  it("are listed, and an agent made from one has its instructions and its kits on", async () => {
    s = await startServer({ text: "x" }, ROOM);
    const sets = await s.api<{ sets: { id: string }[] }>("GET", "/api/agent-sets");
    expect(sets.body.sets.map((x) => x.id)).toEqual([
      "researcher",
      "email",
      "messages",
      "sheets",
      "agenda",
    ]);
    const god = await s.api<{ id: string }>("POST", "/api/agents", {
      kind: "god",
      parentId: null,
      name: "God",
    });
    const a = await s.api<{ id: string; systemPrompt: string }>("POST", "/api/agents", {
      kind: "assistant",
      parentId: god.body.id,
      name: "Posta",
      role: "My email",
      preset: "email",
      systemPrompt: "Always sign as Marta.",
    });
    expect(a.status).toBe(201);
    expect(a.body.systemPrompt).toContain("You look after the person's email");
    expect(a.body.systemPrompt).toContain("Always sign as Marta.");
    const choice = await s.core.toolChoices.get("me");
    expect(choice.agentKits?.[a.body.id]).toMatchObject({ mail: "on" });
    // Another agent is untouched.
    const other = await s.api<{ id: string }>("POST", "/api/agents", {
      kind: "assistant",
      parentId: god.body.id,
      name: "Plain",
      role: "r",
    });
    expect(choice.agentKits?.[other.body.id]).toBeUndefined();
  });

  it("God creates an agent from a set with create_agent, and learns what is left to connect", async () => {
    let system = "";
    const sc = script([
      {
        name: "create_agent",
        input: {
          kind: "assistant",
          name: "Calendar",
          role: "Reminders and my diary",
          preset: "agenda",
        },
      },
    ]);
    s = await startServer((req: CompletionRequest) => {
      system = req.system ?? system;
      return sc.fn(req);
    }, ROOM);
    const god = await s.api<{ id: string }>("POST", "/api/agents", {
      kind: "god",
      parentId: null,
      name: "God",
    });
    const { body } = await s.api<{ sessionId: string }>("POST", "/api/sessions", {
      agentId: god.body.id,
    });
    await (await s.core.send("me", body.sessionId, "Remind me to call the dentist on Thursday"))
      ?.done;
    expect(system).toContain("## Ready-made agent sets");
    expect(system).toContain('"agenda"');
    expect(system).toContain("remind me to call the dentist on Thursday");
    expect(sc.seen[0]).toContain('from the set "agenda"');
    expect(sc.seen[0]).toContain("Still to connect by the person: a calendar");
    const made = s.core.registry.list({ ownerId: "me" }).find((a) => a.name === "Calendar");
    expect(made?.systemPrompt).toContain("You keep the person's agenda");
    expect((await s.core.toolChoices.get("me")).agentKits?.[made?.id ?? ""]).toMatchObject({
      mail: "on",
    });
  });
});

describe("an agent's mailboxes", () => {
  it("sees only the mailboxes connected to it; with none connected it keeps the ones open to the agents", async () => {
    const work = await mailServers({
      inbox: [{ raw: rawMail({ from: "boss@work.example", subject: "For Work" }) }],
    });
    const home = await mailServers({
      inbox: [{ raw: rawMail({ from: "mum@home.example", subject: "For Home" }) }],
    });
    try {
      const sc = script([
        { name: "mail_search", input: {} },
        { name: "mail_search", input: { mailbox: "Work" } },
      ]);
      s = await startServer(sc.fn, ROOM);
      const add = async (name: string, m: typeof work) => {
        const r = await s?.api<{ id: string }>("POST", "/api/settings/mailboxes", {
          name,
          category: "work",
          host: "127.0.0.1",
          port: m.imapPort,
          secure: false,
          user: "testuser@example.test",
          password: "testpass",
          smtp: { host: "127.0.0.1", port: m.smtpPort, secure: false },
          agents: true,
        });
        return (r as { body: { id: string } }).body.id;
      };
      const workId = await add("Work", work);
      const homeId = await add("Home", home);
      const t = await team(s, [{ kind: "mailbox", ref: homeId }]);
      await (await s.core.send("me", t.sessionId, "Any mail?"))?.done;
      expect(sc.seen[0]).toContain("For Home");
      expect(sc.seen[0]).not.toContain("For Work");
      expect(sc.seen[1]).toMatch(/There is no mailbox "Work"/);
      // The service an agent gets is the scoped one; one without mailbox connections gets all.
      expect(await s.core.mailOf(t.agent).open("me")).toHaveLength(1);
      const plain = (
        await s.api<{ id: string }>("POST", "/api/agents", {
          kind: "assistant",
          parentId: t.god,
          name: "Plain",
          role: "r",
        })
      ).body.id;
      expect((await s.core.mailOf(plain).open("me")).map((b) => b.id).sort()).toEqual(
        [workId, homeId].sort(),
      );
    } finally {
      await work.close();
      await home.close();
    }
  });
});

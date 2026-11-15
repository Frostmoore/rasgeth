// G40.1: device tokens and the app's protocol. A device gets a token of its own (with a password
// session, with the password itself, or from the core for the setup channel of G40.3), kept only
// as a hash; it is worth the installation's token, is revoked on its own at once (its WebSocket
// closes) and answers the requests «all together» as «app (<device>)».
import type { AppHello, DeviceCreated, DeviceView, Event } from "@redgiant/protocol";
import { afterEach, describe, expect, it } from "vitest";
import { DeviceStore, migrateDevices } from "../src/index.js";
import { startServer, TOKEN, wsClient } from "./helpers.js";
import { memoryDb } from "./pglite.js";

type Server = Awaited<ReturnType<typeof startServer>>;
let s: Server | undefined;
afterEach(async () => {
  await s?.close();
  s = undefined;
});

const PASSWORD = "una-password-lunga";

async function anon(method: string, path: string, body?: unknown, token?: string) {
  const r = await fetch(`${s?.url}${path}`, {
    method,
    headers: {
      "content-type": "application/json",
      ...(token && { authorization: `Bearer ${token}` }),
    },
    ...(body !== undefined && { body: JSON.stringify(body) }),
  });
  return { status: r.status, body: (await r.json()) as Record<string, unknown> };
}

async function until(check: () => boolean | Promise<boolean>, ms = 5000) {
  const end = Date.now() + ms;
  while (!(await check())) {
    if (Date.now() > end) throw new Error("timed out");
    await new Promise((r) => setTimeout(r, 10));
  }
}

describe("the device store", () => {
  it("keeps only a hash; names, uses, renames and revokes one device at a time", async () => {
    const { db } = await memoryDb();
    await migrateDevices(db);
    let now = Date.parse("2026-11-15T10:00:00Z");
    const store = new DeviceStore(db, { now: () => now });
    const a = await store.create("me", { name: "Pixel 8", platform: "android" });
    const b = await store.create("me", { name: "Mac", platform: "macos" });
    await store.create("other", { name: "Theirs", platform: "ios" });
    expect(a.token).toMatch(/^rgd_[\w-]{43}$/);
    expect(a.device).toMatchObject({ name: "Pixel 8", platform: "android", lastUsedAt: null });
    // Nothing in the table is the token.
    const rows = await db.query<Record<string, unknown>>("SELECT * FROM rg_app_devices");
    expect(JSON.stringify(rows)).not.toContain(a.token);
    expect(JSON.stringify(rows)).not.toContain(a.token.slice(4));

    expect(await store.authenticate(a.token)).toEqual({
      ownerId: "me",
      device: { id: a.device.id, name: "Pixel 8" },
    });
    expect(await store.authenticate("rgs_not-a-device")).toBeNull();
    expect(await store.authenticate(`${a.token}x`)).toBeNull();

    await store.used(a.device.id, "192.168.1.20");
    now += 1000;
    await store.used(a.device.id, "192.168.1.20");
    const seen = (await store.list("me")).find((d) => d.id === a.device.id);
    expect(seen).toMatchObject({
      lastUsedAt: "2026-11-15T10:00:00.000Z",
      lastAddress: "192.168.1.20",
    });

    expect((await store.rename("me", a.device.id, "Telefono"))?.name).toBe("Telefono");
    expect(store.nameOf(a.device.id)).toBe("Telefono");
    // Someone else's device is not found.
    expect(await store.rename("other", a.device.id, "x")).toBeNull();
    expect(await store.revoke("other", a.device.id)).toBe(false);

    const revoked: string[][] = [];
    store.on("revoked", (_o, ids) => revoked.push(ids));
    expect(await store.revoke("me", a.device.id)).toBe(true);
    expect(await store.revoke("me", a.device.id)).toBe(false);
    expect(await store.authenticate(a.token)).toBeNull();
    expect((await store.list("me")).map((d) => d.name)).toEqual(["Mac"]);
    expect(await store.revokeAll("me", b.device.id)).toBe(0);
    expect(await store.revokeAll("me")).toBe(1);
    expect(revoked).toEqual([[a.device.id], [b.device.id]]);
    expect((await store.list("other")).length).toBe(1);
  });
});

describe("over HTTP", () => {
  it("the hello: without credentials, nothing personal; with a token, whether it is valid", async () => {
    s = await startServer(() => ({ text: "x" }));
    const first = await anon("GET", "/api/app/hello");
    expect(first.status).toBe(200);
    const hello = first.body as unknown as AppHello;
    expect(hello).toMatchObject({
      app: "redgiant",
      appProtocol: 1,
      firstStartCompleted: true,
      access: { password: false, code: false, token: true },
      signedIn: false,
    });
    expect(typeof hello.machine).toBe("string");
    expect(JSON.stringify(hello)).not.toMatch(/"me"|ownerId|owner/);
    await s.api("PUT", "/api/auth/password", { password: PASSWORD });
    const made = (
      await s.api<DeviceCreated>("POST", "/api/devices", {
        name: "Pixel 8",
        platform: "android",
      })
    ).body;
    const signed = (await anon("GET", "/api/app/hello", undefined, made.token))
      .body as unknown as AppHello;
    expect(signed).toMatchObject({
      access: { password: true },
      signedIn: true,
      device: { id: made.device.id, name: "Pixel 8" },
    });
    expect((await anon("GET", "/api/app/hello", undefined, "rgd_wrong")).body.signedIn).toBe(false);
  });

  it("pairs with the password: wrong tries counted, a token worth the installation's", async () => {
    s = await startServer(() => ({ text: "x" }));
    const dev = { name: "Pixel 8", platform: "android" };
    expect((await anon("POST", "/api/app/pair", { ...dev, password: PASSWORD })).status).toBe(409);
    await s.api("PUT", "/api/auth/password", { password: PASSWORD });
    expect((await anon("POST", "/api/app/pair", { ...dev, password: "wrong" })).body.code).toBe(
      "wrong",
    );
    expect((await anon("POST", "/api/app/pair", { name: "", platform: "android" })).status).toBe(
      400,
    );
    const ok = await anon("POST", "/api/app/pair", { ...dev, password: PASSWORD });
    expect(ok.status).toBe(200);
    const token = ok.body.token as string;
    // No password session left behind: the device's token is the only credential made.
    expect((await s.api<unknown[]>("GET", "/api/auth/sessions")).body).toEqual([]);
    expect((await anon("GET", "/api/projects", undefined, token)).status).toBe(200);
    // Listed by its use, never with its token.
    const list = (await s.api<DeviceView[]>("GET", "/api/devices")).body;
    expect(list).toHaveLength(1);
    expect(list[0]?.lastUsedAt).not.toBeNull();
    expect(list[0]?.lastAddress).toMatch(/127\.0\.0\.1/);
    expect(JSON.stringify(list)).not.toContain(token);
    const mine = (await anon("GET", "/api/devices", undefined, token))
      .body as unknown as DeviceView[];
    expect(mine[0]?.current).toBe(true);
    // Five wrong tries from one address (a right one starts the count again), then it waits.
    for (let i = 0; i < 5; i++) await anon("POST", "/api/app/pair", { ...dev, password: "no" });
    expect((await anon("POST", "/api/app/pair", { ...dev, password: PASSWORD })).status).toBe(429);
  });

  it("a session makes device tokens, a device never; rename and revoke at once", async () => {
    s = await startServer(() => ({ text: "x" }));
    await s.api("PUT", "/api/auth/password", { password: PASSWORD });
    const session = (await anon("POST", "/api/auth/login", { password: PASSWORD })).body
      .token as string;
    const viaSession = await anon(
      "POST",
      "/api/devices",
      { name: "iPhone", platform: "ios" },
      session,
    );
    expect(viaSession.status).toBe(200);
    const token = viaSession.body.token as string;
    const id = (viaSession.body.device as DeviceView).id;
    const fromDevice = await anon("POST", "/api/devices", { name: "x", platform: "ios" }, token);
    expect(fromDevice).toMatchObject({ status: 403, body: { code: "device" } });
    // The app's token does what the installation's does.
    expect((await anon("GET", "/api/agents", undefined, token)).status).toBe(200);

    expect((await s.api("PATCH", `/api/devices/${id}`, { name: "Telefono" })).status).toBe(200);
    expect((await s.api("PATCH", `/api/devices/${id}`, { name: "" })).status).toBe(400);
    expect((await s.api("PATCH", "/api/devices/dev_nope", { name: "x" })).status).toBe(404);
    expect((await s.api<DeviceView[]>("GET", "/api/devices")).body[0]?.name).toBe("Telefono");

    expect((await s.api("DELETE", `/api/devices/${id}`)).status).toBe(200);
    expect((await anon("GET", "/api/agents", undefined, token)).status).toBe(401);
    expect((await s.api("DELETE", `/api/devices/${id}`)).status).toBe(404);
  });

  it("a new password and «sign out everywhere» end the devices (but the one changing it)", async () => {
    s = await startServer(() => ({ text: "x" }));
    await s.api("PUT", "/api/auth/password", { password: PASSWORD });
    const mk = async (name: string) =>
      (await anon("POST", "/api/app/pair", { name, platform: "linux", password: PASSWORD })).body
        .token as string;
    const a = await mk("A");
    const b = await mk("B");
    expect(
      (await anon("PUT", "/api/auth/password", { password: "altra-password-lunga" }, a)).status,
    ).toBe(200);
    expect((await anon("GET", "/api/agents", undefined, a)).status).toBe(200);
    expect((await anon("GET", "/api/agents", undefined, b)).status).toBe(401);
    expect((await anon("POST", "/api/auth/sessions/revoke", undefined, TOKEN)).status).toBe(200);
    expect((await anon("GET", "/api/agents", undefined, a)).status).toBe(401);
  });
});

describe("the app as a channel of the requests (G36.17)", () => {
  it("a device receives requests and questions, answers as «app (<device>)», and a revoke closes it", async () => {
    s = await startServer((req) => {
      const last = req.messages.at(-1);
      if (last?.parts.some((p) => p.type === "tool_result")) return { text: "done" };
      const said = last?.parts.flatMap((p) => (p.type === "text" ? [p.text] : [])).join("");
      if (said === "ask")
        return {
          toolCalls: [
            {
              name: "ask_user",
              input: {
                questions: [{ question: "A o B?", options: [{ label: "A" }, { label: "B" }] }],
              },
            },
          ],
        };
      return { toolCalls: [{ name: "write_file", input: { path: "a.txt", content: "x" } }] };
    });
    const god = (
      await s.api<{ id: string }>("POST", "/api/agents", {
        kind: "god",
        parentId: null,
        name: "God",
        mode: "manual",
      })
    ).body.id;
    const sid = (await s.api<{ sessionId: string }>("POST", "/api/sessions", { agentId: god })).body
      .sessionId;
    const made = await s.core.devices.create("me", { name: "Pixel 8", platform: "android" });
    const app = await wsClient(s.url, made.token);
    const page = await wsClient(s.url);
    await app.waitFor("welcome");
    await page.waitFor("welcome");

    // Every channel at once; the app's answer closes the page's copy and says where.
    const turn = await s.core.send("me", sid, "write");
    const req = await app.waitFor("permission.request");
    await page.waitFor("permission.request");
    app.send({ type: "permission.resolve", requestId: req.request.requestId, decision: "allow" });
    const closed = await page.waitFor("permission.closed");
    expect(closed).toMatchObject({ decision: "allow", via: "app (Pixel 8)" });
    await turn.done;

    // A rename shows in the next answer.
    await s.core.devices.rename("me", made.device.id, "Telefono");
    const turn2 = await s.core.send("me", sid, "ask");
    const q = await app.waitFor("question.request");
    app.send({ type: "question.answer", requestId: q.request.requestId, answers: [["A"]] });
    expect(await page.waitFor("question.closed")).toMatchObject({ via: "app (Telefono)" });
    await turn2.done;

    const events = (await s.api<Event[]>("GET", `/api/sessions/${sid}/events`)).body;
    const resolved = events.find((e) => e.type === "permission.resolved");
    expect(resolved?.payload).toMatchObject({ decision: "allow", via: "app (Pixel 8)" });
    const answered = events.find((e) => e.type === "question.answered");
    expect(answered?.payload).toMatchObject({ via: "app (Telefono)" });
    // Nowhere in the log is the token.
    expect(JSON.stringify(events)).not.toContain(made.token);

    // Revoked: the app's connection closes at once, the page's stays.
    await s.core.devices.revoke("me", made.device.id);
    await until(() => app.closed()?.code === 4003);
    expect(page.closed()).toBeUndefined();
    page.close();
  });

  it("a request whose time runs out is a no, told to the app as «timeout»", async () => {
    s = await startServer(() => ({ text: "x" }));
    const made = await s.core.devices.create("me", { name: "Mac", platform: "macos" });
    const app = await wsClient(s.url, made.token);
    await app.waitFor("welcome");
    const stop = new AbortController();
    const answer = s.core.approvals.ask(
      {
        requestId: "r-timeout",
        requester: { id: "a", name: "God", ownerId: "me", projectId: null, kind: "god" },
        call: { callId: "c", name: "bash", input: { command: "ls" } },
        reasons: ["runs a command"],
        danger: [],
      } as never,
      stop.signal,
    );
    await app.waitFor("permission.request");
    stop.abort("timeout");
    expect(await answer).toBe("deny");
    expect(await app.waitFor("permission.closed")).toMatchObject({
      decision: "deny",
      via: "timeout",
    });
    // Too late: the app's yes finds nothing to decide.
    app.send({ type: "permission.resolve", requestId: "r-timeout", decision: "allow" });
    await app.waitFor("error", (m) => m.code === "not_found");
    app.close();
  });
});

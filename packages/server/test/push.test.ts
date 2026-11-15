// G40.4: notifications to the devices. A device registers its UnifiedPush endpoint (or its APNs
// token); requests and questions reach it encrypted (RFC 8291) as one more channel «all at once»,
// the first answer withdraws them, a notification's Yes / No goes through the same rules (never a
// quick yes to a truly dangerous request), and dead endpoints are dropped. The endpoint and the
// relay here are local HTTP servers that decrypt as the phone would.
import { createECDH, createPublicKey, randomBytes, verify } from "node:crypto";
import { createServer, type Server as HttpServer, type IncomingMessage } from "node:http";
import type { AddressInfo } from "node:net";
import type { PushChannelView, PushNotice } from "@redgiant/protocol";
import { afterEach, describe, expect, it } from "vitest";
import { DeviceStore, migrateDevices } from "../src/index.js";
import { b64u, decrypt, unb64u } from "../src/push/ece.js";
import { migratePush, PushService, VAPID_KEY } from "../src/push/service.js";
import { startServer } from "./helpers.js";
import { memoryDb } from "./pglite.js";

type Server = Awaited<ReturnType<typeof startServer>>;
let s: Server | undefined;
const closers: (() => Promise<void>)[] = [];
afterEach(async () => {
  await s?.close();
  s = undefined;
  for (const c of closers.splice(0)) await c();
});

async function until(check: () => boolean | Promise<boolean>, ms = 5000) {
  const end = Date.now() + ms;
  while (!(await check())) {
    if (Date.now() > end) throw new Error("timed out");
    await new Promise((r) => setTimeout(r, 10));
  }
}

/** The phone's own keys, as UnifiedPush gives them. */
function phoneKeys() {
  const ecdh = createECDH("prime256v1");
  ecdh.generateKeys();
  const auth = randomBytes(16);
  return {
    keys: { p256dh: b64u(ecdh.getPublicKey()), auth: b64u(auth) },
    open: (body: Buffer) =>
      JSON.parse(decrypt(body, ecdh.getPrivateKey(), auth).toString()) as PushNotice,
  };
}

interface Hit {
  path: string;
  headers: IncomingMessage["headers"];
  body: Buffer;
}

/** A push service (or the relay) on localhost: answers with the next status of `statuses`. */
async function fakeEndpoint(statuses: number[] = []) {
  const hits: Hit[] = [];
  let hang = false;
  const server: HttpServer = createServer((req, res) => {
    const chunks: Buffer[] = [];
    req.on("data", (c: Buffer) => chunks.push(c));
    req.on("end", () => {
      hits.push({ path: req.url ?? "", headers: req.headers, body: Buffer.concat(chunks) });
      if (hang) return;
      res.writeHead(statuses.shift() ?? 201).end();
    });
  });
  await new Promise<void>((ok) => server.listen(0, "127.0.0.1", ok));
  closers.push(
    () =>
      new Promise((ok) => {
        server.closeAllConnections();
        server.close(() => ok());
      }),
  );
  const url = `http://127.0.0.1:${(server.address() as AddressInfo).port}`;
  return {
    url,
    hits,
    statuses,
    hangs: () => {
      hang = true;
    },
  };
}

const request = (id: string, o: Record<string, unknown> = {}) =>
  ({
    requestId: id,
    requester: { id: "a", name: "God", ownerId: "me", projectId: null, kind: "god" },
    call: { callId: "c", name: "bash", input: { command: "ls -la" } },
    reasons: ["runs a command"],
    danger: [],
    ...o,
  }) as never;

async function withPhone(o: { relayUrl?: string } = {}) {
  s = await startServer(
    () => ({ text: "Fatto, ecco il riassunto." }),
    {},
    {
      push: { retryDelayMs: 0, timeoutMs: 500, ...(o.relayUrl && { relayUrl: o.relayUrl }) },
    },
  );
  const made = await s.core.devices.create("me", { name: "Pixel 8", platform: "android" });
  return { made, phone: phoneKeys() };
}

describe("Web Push to a UnifiedPush endpoint", () => {
  it("registers, sends a request encrypted with VAPID, and the app's Yes decides it", async () => {
    const push = await fakeEndpoint();
    const { made, phone } = await withPhone();
    const srv = s as Server;
    const dev = made.device.id;
    const reg = await srv.api<PushChannelView>(
      "PUT",
      `/api/devices/${dev}/push`,
      { kind: "webpush", endpoint: `${push.url}/up/abc`, keys: phone.keys },
      made.token,
    );
    expect(reg.status).toBe(200);
    expect(reg.body).toMatchObject({ kind: "webpush", target: push.url.slice(7), lastError: null });
    // The VAPID key was made once, in the keychain; the app learns its public half.
    expect(srv.core.vault.systemValue("me", VAPID_KEY)).toBeDefined();
    const info = await srv.api<{ vapidPublicKey: string; apns: boolean }>(
      "GET",
      "/api/app/push",
      undefined,
      made.token,
    );
    expect(info.body.apns).toBe(false);
    expect(unb64u(info.body.vapidPublicKey)).toHaveLength(65);

    const listed = await srv.api<{ id: string; push: PushChannelView | null }[]>(
      "GET",
      "/api/devices",
    );
    expect(listed.body.find((d) => d.id === dev)?.push?.kind).toBe("webpush");

    const answer = srv.core.approvals.ask(request("r1"), new AbortController().signal);
    await until(() => push.hits.length === 1);
    const hit = push.hits[0] as Hit;
    expect(hit.path).toBe("/up/abc");
    expect(hit.headers["content-encoding"]).toBe("aes128gcm");
    expect(hit.headers.urgency).toBe("high");
    expect(Number(hit.headers.ttl)).toBeGreaterThan(0);
    expect(hit.headers.topic).toMatch(/^[\w-]{32}$/);
    // Nothing readable on the wire.
    expect(hit.body.toString("latin1")).not.toContain("ls -la");
    const notice = phone.open(hit.body);
    expect(notice).toMatchObject({
      kind: "request",
      requestId: "r1",
      actions: ["allow", "deny"],
      title: "God asks for permission",
    });
    expect(notice.body).toContain("ls -la");

    // The VAPID token: for the endpoint's origin, signed by the announced key.
    const m = String(hit.headers.authorization).match(/^vapid t=([^,]+), k=(.+)$/);
    expect(m?.[2]).toBe(info.body.vapidPublicKey);
    const [h, c, sig] = (m?.[1] ?? "").split(".");
    expect(JSON.parse(unb64u(c ?? "").toString()).aud).toBe(push.url);
    const pub = unb64u(info.body.vapidPublicKey);
    const key = createPublicKey({
      key: { kty: "EC", crv: "P-256", x: b64u(pub.subarray(1, 33)), y: b64u(pub.subarray(33)) },
      format: "jwk",
    });
    expect(
      verify(
        "sha256",
        Buffer.from(`${h}.${c}`),
        { key, dsaEncoding: "ieee-p1363" },
        unb64u(sig ?? ""),
      ),
    ).toBe(true);

    // The Yes of the notification: the device's token, the same decide as every channel.
    const yes = await srv.api(
      "POST",
      "/api/app/requests/r1/answer",
      { decision: "allow" },
      made.token,
    );
    expect(yes.status).toBe(200);
    expect(await answer).toBe("allow");
    // The notification is withdrawn: same topic, says where it was answered.
    await until(() => push.hits.length === 2);
    const closed = phone.open((push.hits[1] as Hit).body);
    expect(closed).toMatchObject({ id: notice.id, closed: { via: "app (Pixel 8)" } });
    expect(push.hits[1]?.headers.topic).toBe(hit.headers.topic);
    // Too late for a second answer.
    expect(
      (await srv.api("POST", "/api/app/requests/r1/answer", { decision: "deny" }, made.token))
        .status,
    ).toBe(404);
  });

  it("never takes a quick yes for a truly dangerous request, nor an answer from the page's token", async () => {
    const push = await fakeEndpoint();
    const { made, phone } = await withPhone();
    const srv = s as Server;
    await srv.api(
      "PUT",
      `/api/devices/${made.device.id}/push`,
      { kind: "webpush", endpoint: `${push.url}/up/1`, keys: phone.keys },
      made.token,
    );
    const answer = srv.core.approvals.ask(
      request("r2", {
        call: { callId: "c", name: "bash", input: { command: "rm -rf /home" } },
        danger: ["critical-delete"],
        critical: [{ id: "critical-delete", action: "delete-forever", target: "/home" }],
      }),
      new AbortController().signal,
    );
    await until(() => push.hits.length === 1);
    const notice = phone.open((push.hits[0] as Hit).body);
    expect(notice).toMatchObject({ critical: true, actions: [] });

    const yes = await srv.api<{ code: string }>(
      "POST",
      "/api/app/requests/r2/answer",
      { decision: "allow" },
      made.token,
    );
    expect(yes).toMatchObject({ status: 403, body: { code: "open_app" } });
    // Only a device answers from a notification.
    expect(
      (await srv.api("POST", "/api/app/requests/r2/answer", { decision: "deny" })).status,
    ).toBe(403);
    expect(srv.core.approvals.list("me").map((r) => r.requestId)).toEqual(["r2"]);
    // A no is always welcome.
    expect(
      (await srv.api("POST", "/api/app/requests/r2/answer", { decision: "deny" }, made.token))
        .status,
    ).toBe(200);
    expect(await answer).toBe("deny");
  });

  it("a request whose time runs out is a no, and the notification is withdrawn", async () => {
    const push = await fakeEndpoint();
    const { made, phone } = await withPhone();
    const srv = s as Server;
    await srv.api(
      "PUT",
      `/api/devices/${made.device.id}/push`,
      { kind: "webpush", endpoint: `${push.url}/up/1`, keys: phone.keys },
      made.token,
    );
    const stop = new AbortController();
    const answer = srv.core.approvals.ask(request("r3"), stop.signal);
    await until(() => push.hits.length === 1);
    stop.abort("timeout");
    expect(await answer).toBe("deny");
    await until(() => push.hits.length === 2);
    expect(phone.open((push.hits[1] as Hit).body).closed).toEqual({ via: "timeout" });
  });

  it("drops an endpoint that is gone, tries a failing one twice, and gives up on a slow one", async () => {
    const push = await fakeEndpoint([500, 500, 410]);
    const { made, phone } = await withPhone();
    const srv = s as Server;
    const dev = made.device.id;
    const path = `/api/devices/${dev}/push`;
    await srv.api(
      "PUT",
      path,
      { kind: "webpush", endpoint: `${push.url}/up/1`, keys: phone.keys },
      made.token,
    );

    // 500, then 500 again: two tries, then the error is shown.
    const t1 = await srv.api<{ ok: boolean; error: string }>("POST", `${path}/test`);
    expect(t1.body).toEqual({ ok: false, error: "HTTP 500", gone: false });
    expect(push.hits).toHaveLength(2);
    const v = await srv.api<{ id: string; push: PushChannelView | null }[]>("GET", "/api/devices");
    expect(v.body[0]?.push?.lastError).toBe("HTTP 500");

    // 410: the subscription is gone, the channel with it.
    const t2 = await srv.api<{ ok: boolean; gone: boolean }>("POST", `${path}/test`);
    expect(t2.body).toMatchObject({ ok: false, gone: true });
    expect((await srv.api("POST", `${path}/test`)).status).toBe(404);
    const after = await srv.api<{ push: PushChannelView | null }[]>("GET", "/api/devices");
    expect(after.body[0]?.push).toBeNull();

    // An endpoint that never answers: two tries of 500 ms each, then «timed out».
    await srv.api(
      "PUT",
      path,
      { kind: "webpush", endpoint: `${push.url}/up/2`, keys: phone.keys },
      made.token,
    );
    push.hangs();
    const started = Date.now();
    const t3 = await srv.api<{ ok: boolean; error: string }>("POST", `${path}/test`);
    expect(t3.body).toMatchObject({ ok: false, error: "timed out" });
    expect(Date.now() - started).toBeLessThan(4000);
  });

  it("sends a test that the phone reads, and keeps devices to their own channel", async () => {
    const push = await fakeEndpoint();
    const { made, phone } = await withPhone();
    const srv = s as Server;
    const other = await srv.core.devices.create("me", { name: "Mac", platform: "macos" });
    const path = `/api/devices/${made.device.id}/push`;
    const body = { kind: "webpush", endpoint: `${push.url}/up/1`, keys: phone.keys };
    // Another device cannot register, remove or test this one's channel.
    expect((await srv.api("PUT", path, body, other.token)).status).toBe(403);
    expect((await srv.api("PUT", path, body, made.token)).status).toBe(200);
    expect((await srv.api("POST", `${path}/test`, undefined, other.token)).status).toBe(403);
    expect((await srv.api("DELETE", path, undefined, other.token)).status).toBe(403);
    // Bad keys are refused at once, not at the first message.
    expect(
      (
        await srv.api(
          "PUT",
          path,
          { ...body, keys: { ...phone.keys, p256dh: b64u(Buffer.alloc(65, 4)) } },
          made.token,
        )
      ).status,
    ).toBe(400);
    // Not a device of this owner.
    expect((await srv.api("PUT", "/api/devices/dev_nope/push", body)).status).toBe(404);

    expect((await srv.api("POST", `${path}/test`)).body).toEqual({ ok: true });
    expect(phone.open((push.hits[0] as Hit).body)).toMatchObject({ kind: "test" });
    const listed = await srv.api<{ id: string; push: PushChannelView | null }[]>(
      "GET",
      "/api/devices",
    );
    expect(listed.body.find((d) => d.id === made.device.id)?.push?.lastSentAt).not.toBeNull();

    // Revoking the device removes its channel.
    await srv.core.devices.revoke("me", made.device.id);
    await until(async () => (await srv.core.push.views("me")).size === 0);
    const rows = await (srv.core as unknown as { push: PushService }).push.views("me");
    expect(rows.size).toBe(0);
  });

  it("tells an answer only when nobody watches the conversation", async () => {
    const push = await fakeEndpoint();
    const { made, phone } = await withPhone();
    const srv = s as Server;
    await srv.api(
      "PUT",
      `/api/devices/${made.device.id}/push`,
      { kind: "webpush", endpoint: `${push.url}/up/1`, keys: phone.keys },
      made.token,
    );
    const god = await srv.api<{ id: string }>("POST", "/api/agents", {
      kind: "god",
      parentId: null,
      name: "God",
    });
    const { body } = await srv.api<{ sessionId: string }>("POST", "/api/sessions", {
      agentId: god.body.id,
    });
    await srv.api("POST", `/api/sessions/${body.sessionId}/messages`, { text: "riassumi" });
    await until(() => push.hits.length === 1);
    expect(phone.open((push.hits[0] as Hit).body)).toMatchObject({
      kind: "message",
      title: "God",
      body: "Fatto, ecco il riassunto.",
      sessionId: body.sessionId,
    });

    // Someone follows it now: no notification.
    const unfollow = await srv.core.follow("me", body.sessionId, () => {});
    await srv.api("POST", `/api/sessions/${body.sessionId}/messages`, { text: "ancora" });
    await until(() => !srv.core.isWatched("nobody") && srv.core.approvals.list("me").length === 0);
    await new Promise((r) => setTimeout(r, 300));
    await srv.core.push.idle();
    expect(push.hits).toHaveLength(1);
    unfollow();
  });
});

describe("APNs, ready and switched off", () => {
  it("says it is off without a relay, and seals the content for the device through one", async () => {
    const relay = await fakeEndpoint();
    const phone = phoneKeys();
    const token = "ab".repeat(32);

    // Without a relay (as shipped now): registered, shown as off, nothing sent.
    const off = await withPhone();
    const reg = await (s as Server).api<PushChannelView>(
      "PUT",
      `/api/devices/${off.made.device.id}/push`,
      { kind: "apns", token, keys: phone.keys },
      off.made.token,
    );
    expect(reg.body).toMatchObject({ kind: "apns", target: "APNs", blocked: "relay_off" });
    const t = await (s as Server).api("POST", `/api/devices/${off.made.device.id}/push/test`);
    expect(t.body).toMatchObject({ ok: false, error: "APNs relay switched off" });
    await s?.close();
    s = undefined;

    // With the relay switched on (at publication).
    const on = await withPhone({ relayUrl: relay.url });
    const srv = s as Server;
    await srv.api(
      "PUT",
      `/api/devices/${on.made.device.id}/push`,
      { kind: "apns", token, keys: phone.keys, environment: "sandbox" },
      on.made.token,
    );
    const answer = srv.core.approvals.ask(request("r9"), new AbortController().signal);
    await until(() => relay.hits.length === 1);
    const hit = relay.hits[0] as Hit;
    expect(hit.path).toBe("/v1/push");
    const sent = JSON.parse(hit.body.toString()) as Record<string, unknown>;
    expect(sent).toMatchObject({ token, environment: "sandbox", quiet: false });
    // The relay sees no words of the request: only what is sealed for the phone.
    expect(hit.body.toString()).not.toContain("ls -la");
    expect(hit.body.toString()).not.toContain("God");
    expect(phone.open(unb64u(String(sent.sealed)))).toMatchObject({
      kind: "request",
      requestId: "r9",
    });
    srv.core.approvals.decide("me", "r9", "deny", undefined, "web");
    expect(await answer).toBe("deny");
    await until(() => relay.hits.length === 2);
    const closed = JSON.parse((relay.hits[1] as Hit).body.toString()) as Record<string, unknown>;
    expect(closed).toMatchObject({ quiet: true, collapseId: sent.collapseId });
  });
});

describe("tasks", () => {
  it("tells a task of the person's own agent, not one between sub-agents", async () => {
    const push = await fakeEndpoint();
    const { db } = await memoryDb();
    await migrateDevices(db);
    await migratePush(db);
    const devices = new DeviceStore(db);
    const made = await devices.create("me", { name: "Pixel", platform: "android" });
    const values = new Map<string, string>();
    const service = new PushService({
      db,
      devices,
      vault: {
        ready: true,
        systemValue: (_o: string, k: string) => values.get(k),
        setSystem: async (_o: string, k: string, v: string | null) => {
          if (v) values.set(k, v);
        },
      } as never,
      retryDelayMs: 0,
    });
    const phone = phoneKeys();
    await service.register("me", made.device.id, {
      kind: "webpush",
      endpoint: `${push.url}/up/1`,
      keys: phone.keys,
    });
    const listeners: ((e: unknown) => void)[] = [];
    const tasks = new Map([
      ["t1", { title: "Prepara la relazione", from: { agentId: "god", sessionId: "s1" } }],
      ["t2", { title: "Un pezzo", from: { agentId: "orch", sessionId: "s2" } }],
    ]);
    const registry = new Map([
      ["god", { name: "God", parentId: null }],
      ["orch", { name: "Orch", parentId: "god" }],
    ]);
    const none = { on: () => undefined };
    service.attach({
      approvals: none,
      questions: none,
      store: {
        subscribe: (f: (e: unknown) => void) => {
          listeners.push(f);
          return () => {};
        },
      },
      tasks: { get: (id: string) => tasks.get(id) },
      registry: { get: (id: string) => registry.get(id) },
      language: () => "it",
      machineName: async () => "Casa",
      isWatched: () => false,
      onTurnEnded: () => () => {},
    } as never);
    const closed = (taskId: string) => ({
      type: "task.closed",
      ownerId: "me",
      sessionId: "x",
      payload: { taskId, outcome: "verified" },
    });
    for (const f of listeners) f(closed("t2"));
    for (const f of listeners) f(closed("t1"));
    await service.idle();
    expect(push.hits).toHaveLength(1);
    expect(phone.open((push.hits[0] as Hit).body)).toMatchObject({
      kind: "task",
      title: "Compito finito",
      body: "Prepara la relazione",
      server: "Casa",
      sessionId: "s1",
    });
  });
});

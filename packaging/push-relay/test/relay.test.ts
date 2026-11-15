// The blind push relay for APNs (G40.4): against a fake APNs (HTTP/2 on localhost). It passes
// the sealed content as it is, with the publisher's provider token, maps a dead token to 410,
// refuses what APNs would refuse, and never sees the words of a notification.
import { createECDH, generateKeyPairSync, randomBytes, verify } from "node:crypto";
import { createServer as createHttp, type Server } from "node:http";
import { createServer as createH2, type Http2Server, type IncomingHttpHeaders } from "node:http2";
import type { AddressInfo } from "node:net";
import { afterEach, describe, expect, it } from "vitest";
import { b64u, decrypt, encrypt, unb64u } from "../../../packages/server/src/push/ece.js";
// @ts-expect-error plain JavaScript, no types
import { createRelay, relayFromEnv } from "../relay.mjs";

const closers: (() => Promise<void> | void)[] = [];
afterEach(async () => {
  for (const c of closers.splice(0).reverse()) await c();
});

const listen = async <S extends Server | Http2Server>(s: S) => {
  await new Promise<void>((ok) => s.listen(0, "127.0.0.1", ok));
  return `http://127.0.0.1:${(s.address() as AddressInfo).port}`;
};

/** A fake APNs: records each push and answers with the next status (and reason). */
async function fakeApns(answers: { status: number; reason?: string }[] = []) {
  const pushes: { headers: IncomingHttpHeaders; body: Record<string, unknown> }[] = [];
  const server = createH2((req, res) => {
    const chunks: Buffer[] = [];
    req.on("data", (c: Buffer) => chunks.push(c));
    req.on("end", () => {
      pushes.push({ headers: req.headers, body: JSON.parse(Buffer.concat(chunks).toString()) });
      const a = answers.shift() ?? { status: 200 };
      res.writeHead(a.status, { "content-type": "application/json" });
      res.end(a.reason ? JSON.stringify({ reason: a.reason }) : "");
    });
  });
  const url = await listen(server);
  closers.push(() => new Promise<void>((ok) => server.close(() => ok())));
  return { url, pushes };
}

async function startRelay(apnsUrl: string, o: Record<string, unknown> = {}) {
  const { privateKey, publicKey } = generateKeyPairSync("ec", { namedCurve: "P-256" });
  const relay = createRelay({
    key: privateKey.export({ type: "pkcs8", format: "pem" }),
    keyId: "KEY123",
    teamId: "TEAM456",
    topic: "app.redgiant.companion",
    hosts: { production: apnsUrl, sandbox: apnsUrl },
    ...o,
  });
  const server = createHttp(relay.handler);
  const url = await listen(server);
  closers.push(() => {
    relay.close();
    server.closeAllConnections();
    return new Promise<void>((ok) => server.close(() => ok()));
  });
  const post = async (body: unknown) => {
    const r = await fetch(`${url}/v1/push`, {
      method: "POST",
      headers: { "content-type": "application/json" },
      body: JSON.stringify(body),
    });
    return { status: r.status, body: (await r.json()) as Record<string, unknown> };
  };
  return { url, post, publicKey };
}

const TOKEN = "ab".repeat(32);

function sealedFor() {
  const ecdh = createECDH("prime256v1");
  ecdh.generateKeys();
  const auth = randomBytes(16);
  const notice = JSON.stringify({ v: 1, kind: "request", title: "God asks", body: "rm -rf" });
  const sealed = b64u(
    encrypt(Buffer.from(notice), { p256dh: b64u(ecdh.getPublicKey()), auth: b64u(auth) }),
  );
  return { sealed, open: (s: string) => decrypt(unb64u(s), ecdh.getPrivateKey(), auth).toString() };
}

describe("the blind relay", () => {
  it("passes the sealed content to APNs with the publisher's provider token", async () => {
    const apns = await fakeApns();
    const relay = await startRelay(apns.url);
    const { sealed, open } = sealedFor();
    const r = await relay.post({ token: TOKEN, sealed, collapseId: "abc", ttl: 600 });
    expect(r).toEqual({ status: 200, body: { ok: true } });
    const p = apns.pushes[0];
    expect(p?.headers[":path"]).toBe(`/3/device/${TOKEN}`);
    expect(p?.headers).toMatchObject({
      "apns-topic": "app.redgiant.companion",
      "apns-push-type": "alert",
      "apns-priority": "10",
      "apns-collapse-id": "abc",
    });
    // The provider token: ES256, the key's id, the team, signed with the .p8.
    const [h, c, sig] = String(p?.headers.authorization)
      .replace(/^bearer /, "")
      .split(".");
    expect(JSON.parse(unb64u(h ?? "").toString())).toEqual({ alg: "ES256", kid: "KEY123" });
    expect(JSON.parse(unb64u(c ?? "").toString()).iss).toBe("TEAM456");
    expect(
      verify(
        "sha256",
        Buffer.from(`${h}.${c}`),
        { key: relay.publicKey, dsaEncoding: "ieee-p1363" },
        unb64u(sig ?? ""),
      ),
    ).toBe(true);
    // A generic alert the extension replaces; the content as it came, still sealed.
    expect(p?.body).toMatchObject({
      aps: { alert: { "loc-key": "RG_NOTICE" }, "mutable-content": 1 },
      rg: sealed,
    });
    expect(JSON.stringify(p?.body)).not.toContain("rm -rf");
    expect(open(String(p?.body.rg))).toContain("rm -rf");
  });

  it("sends a withdrawal quietly, replacing the shown notification", async () => {
    const apns = await fakeApns();
    const relay = await startRelay(apns.url);
    await relay.post({ token: TOKEN, sealed: sealedFor().sealed, collapseId: "abc", quiet: true });
    expect(apns.pushes[0]?.headers).toMatchObject({
      "apns-priority": "5",
      "apns-collapse-id": "abc",
    });
    expect(apns.pushes[0]?.body.aps).toMatchObject({ "interruption-level": "passive" });
    expect(apns.pushes[0]?.body.aps).not.toHaveProperty("sound");
  });

  it("maps APNs' answers: a dead token is 410, the rest says only the reason", async () => {
    const apns = await fakeApns([
      { status: 410, reason: "Unregistered" },
      { status: 400, reason: "BadDeviceToken" },
      { status: 429, reason: "TooManyRequests" },
      { status: 500, reason: "InternalServerError" },
    ]);
    const relay = await startRelay(apns.url);
    const sealed = sealedFor().sealed;
    expect((await relay.post({ token: TOKEN, sealed })).status).toBe(410);
    expect((await relay.post({ token: TOKEN, sealed })).status).toBe(410);
    expect((await relay.post({ token: TOKEN, sealed })).status).toBe(429);
    expect(await relay.post({ token: TOKEN, sealed })).toEqual({
      status: 502,
      body: { error: "InternalServerError" },
    });
  });

  it("refuses what APNs would refuse, before calling it", async () => {
    const apns = await fakeApns();
    const relay = await startRelay(apns.url, { perTokenPerMinute: 2 });
    const sealed = sealedFor().sealed;
    expect((await relay.post({ token: "nothex", sealed })).status).toBe(400);
    expect((await relay.post({ token: TOKEN, sealed: "not base64url!" })).status).toBe(400);
    expect((await relay.post({ token: TOKEN, sealed: "a".repeat(3601) })).status).toBe(413);
    expect((await relay.post({ token: TOKEN, sealed, collapseId: "x".repeat(65) })).status).toBe(
      400,
    );
    expect(apns.pushes).toHaveLength(0);
    // A per-token limit (in memory only).
    expect((await relay.post({ token: TOKEN, sealed })).status).toBe(200);
    expect((await relay.post({ token: TOKEN, sealed })).status).toBe(200);
    expect((await relay.post({ token: TOKEN, sealed })).status).toBe(429);
  });

  it("answers 502 when APNs cannot be reached, within its time limit", async () => {
    const relay = await startRelay("http://127.0.0.1:1", { timeoutMs: 500 });
    const r = await relay.post({ token: TOKEN, sealed: sealedFor().sealed });
    expect(r.status).toBe(502);
  });

  it("needs its key, key id, team and topic from the environment", () => {
    expect(() => relayFromEnv({})).toThrow(/APNS_KEY or APNS_KEY_FILE, APNS_KEY_ID/);
  });
});

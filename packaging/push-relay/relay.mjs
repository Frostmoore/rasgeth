#!/usr/bin/env node
// Rasgeth's blind push relay for APNs (G40.4, 3.8). NOT published nor switched on yet: it is
// turned on when the Rasgeth app is published on the App Store, because Apple's push key (.p8)
// belongs to the account that publishes the app and cannot be given to whoever installs
// Rasgeth. A Rasgeth server sends here only what it sealed for one device (RFC 8291's
// aes128gcm with the key pair the phone made; the Notification Service Extension opens it) and
// Apple's device token; the relay adds the publisher's provider token and passes it to APNs.
//
// It is blind and keeps nothing: no database, no files, no log of what passes (not the sealed
// content, not the tokens). The only memory is a per-token rate limit and the provider token,
// both lost on restart. No dependencies: node:http, node:http2, node:crypto.
//
//   POST /v1/push  {token, environment?, sealed, collapseId?, quiet?, ttl?}
//     200 {ok:true}   delivered to APNs
//     400             a malformed request          410  the device token is gone (drop it)
//     413             too big for APNs              429  too many for this token, or APNs said so
//     502             APNs failed (its reason only, never the content)
//   GET  /health   {ok:true}
//
// Environment: APNS_KEY (the .p8's PEM) or APNS_KEY_FILE, APNS_KEY_ID, APNS_TEAM_ID, APNS_TOPIC
// (the app's bundle id, `it.rasgeth.app`), PORT (8790), HOST (0.0.0.0); APNS_HOST / APNS_SANDBOX_HOST only to point
// at a fake APNs in tests.

import { createPrivateKey, sign } from "node:crypto";
import { readFileSync } from "node:fs";
import { createServer } from "node:http";
import { connect } from "node:http2";

const PRODUCTION = "https://api.push.apple.com";
const SANDBOX = "https://api.sandbox.push.apple.com";
/** APNs takes payloads up to 4096 bytes: the sealed content plus the generic alert. */
const MAX_SEALED = 3600;
const MAX_BODY = 8192;
/** Apple refuses provider tokens older than an hour and refreshed more often than every 20 min. */
const TOKEN_LIFE_MS = 50 * 60_000;

const b64u = (b) => Buffer.from(b).toString("base64url");

/**
 * The relay's HTTP handler.
 * @param {{ key: string, keyId: string, teamId: string, topic: string,
 *   hosts?: { production?: string, sandbox?: string },
 *   perTokenPerMinute?: number, timeoutMs?: number, now?: () => number }} o
 */
export function createRelay(o) {
  const key = createPrivateKey(o.key);
  const now = o.now ?? Date.now;
  const hosts = {
    production: o.hosts?.production ?? PRODUCTION,
    sandbox: o.hosts?.sandbox ?? SANDBOX,
  };
  /** @type {{ jwt: string, at: number } | undefined} */
  let provider;
  /** @type {Map<string, import("node:http2").ClientHttp2Session>} */
  const sessions = new Map();
  /** @type {Map<string, { minute: number, count: number }>} */
  const rate = new Map();

  const providerToken = () => {
    if (provider && now() - provider.at < TOKEN_LIFE_MS) return provider.jwt;
    const head = b64u(JSON.stringify({ alg: "ES256", kid: o.keyId }));
    const claims = b64u(JSON.stringify({ iss: o.teamId, iat: Math.floor(now() / 1000) }));
    const sig = sign("sha256", Buffer.from(`${head}.${claims}`), {
      key,
      dsaEncoding: "ieee-p1363",
    });
    provider = { jwt: `${head}.${claims}.${b64u(sig)}`, at: now() };
    return provider.jwt;
  };

  const session = (origin) => {
    const open = sessions.get(origin);
    if (open && !open.closed && !open.destroyed) return open;
    const s = connect(origin);
    s.on("error", () => sessions.delete(origin));
    s.on("close", () => sessions.delete(origin));
    s.unref();
    sessions.set(origin, s);
    return s;
  };

  const limited = (token) => {
    const minute = Math.floor(now() / 60_000);
    const r = rate.get(token);
    if (!r || r.minute !== minute) {
      if (rate.size > 10_000) rate.clear();
      rate.set(token, { minute, count: 1 });
      return false;
    }
    r.count++;
    return r.count > (o.perTokenPerMinute ?? 30);
  };

  /** One push to APNs: its status and reason (never the content). */
  const toApns = (p) =>
    new Promise((resolve) => {
      const payload = JSON.stringify({
        aps: p.quiet
          ? // The update that withdraws a request: it replaces the shown one, without a sound.
            {
              alert: { "loc-key": "RG_CLOSED" },
              "mutable-content": 1,
              "interruption-level": "passive",
            }
          : { alert: { "loc-key": "RG_NOTICE" }, "mutable-content": 1, sound: "default" },
        // What the device opens; the generic alert shows only if it cannot.
        rg: p.sealed,
      });
      const headers = {
        ":method": "POST",
        ":path": `/3/device/${p.token}`,
        authorization: `bearer ${providerToken()}`,
        "apns-topic": o.topic,
        "apns-push-type": "alert",
        "apns-priority": p.quiet ? "5" : "10",
        "apns-expiration": String(Math.floor(now() / 1000) + p.ttl),
        ...(p.collapseId && { "apns-collapse-id": p.collapseId }),
        "content-type": "application/json",
      };
      let done = false;
      const finish = (r) => {
        if (done) return;
        done = true;
        clearTimeout(timer);
        resolve(r);
      };
      const timer = setTimeout(() => {
        req?.close();
        finish({ status: 0, reason: "timeout" });
      }, o.timeoutMs ?? 10_000);
      let req;
      try {
        req = session(hosts[p.environment]).request(headers);
      } catch {
        return finish({ status: 0, reason: "connect" });
      }
      let status = 0;
      const chunks = [];
      req.on("response", (h) => {
        status = Number(h[":status"]);
      });
      req.on("data", (c) => chunks.push(c));
      req.on("end", () => {
        let reason = "";
        try {
          reason = String(JSON.parse(Buffer.concat(chunks).toString() || "{}").reason ?? "");
        } catch {}
        finish({ status, reason });
      });
      req.on("error", () => finish({ status: 0, reason: "network" }));
      req.end(payload);
    });

  const answer = (res, status, body) => {
    res.writeHead(status, { "content-type": "application/json" }).end(JSON.stringify(body));
  };

  /** @type {import("node:http").RequestListener} */
  const handler = (req, res) => {
    if (req.method === "GET" && req.url === "/health") return answer(res, 200, { ok: true });
    if (req.method !== "POST" || req.url !== "/v1/push")
      return answer(res, 404, { error: "not found" });
    const chunks = [];
    let size = 0;
    req.on("data", (c) => {
      size += c.length;
      if (size > MAX_BODY) {
        answer(res, 413, { error: "too big" });
        req.destroy();
      } else chunks.push(c);
    });
    req.on("end", async () => {
      if (res.headersSent) return;
      let b;
      try {
        b = JSON.parse(Buffer.concat(chunks).toString());
      } catch {
        return answer(res, 400, { error: "not JSON" });
      }
      const token = typeof b?.token === "string" ? b.token.toLowerCase() : "";
      const environment = b?.environment === "sandbox" ? "sandbox" : "production";
      const sealed = typeof b?.sealed === "string" ? b.sealed : "";
      const collapseId = typeof b?.collapseId === "string" ? b.collapseId : undefined;
      const ttl = Number.isInteger(b?.ttl) ? Math.min(Math.max(b.ttl, 0), 7 * 86_400) : 3600;
      if (!/^[0-9a-f]{64,200}$/.test(token)) return answer(res, 400, { error: "bad token" });
      if (!/^[A-Za-z0-9_-]+$/.test(sealed))
        return answer(res, 400, { error: "bad sealed content" });
      if (sealed.length > MAX_SEALED) return answer(res, 413, { error: "too big for APNs" });
      if (collapseId !== undefined && !/^[A-Za-z0-9_-]{1,64}$/.test(collapseId))
        return answer(res, 400, { error: "bad collapse id" });
      if (limited(token)) return answer(res, 429, { error: "too many" });
      const r = await toApns({
        token,
        environment,
        sealed,
        collapseId,
        ttl,
        quiet: b?.quiet === true,
      });
      if (r.status === 200) return answer(res, 200, { ok: true });
      // The token is gone for good: the server drops the channel.
      if (
        r.status === 410 ||
        (r.status === 400 && /BadDeviceToken|DeviceTokenNotForTopic/.test(r.reason))
      )
        return answer(res, 410, { error: r.reason || "gone" });
      if (r.status === 413) return answer(res, 413, { error: r.reason || "too big" });
      if (r.status === 429) return answer(res, 429, { error: r.reason || "too many" });
      return answer(res, 502, { error: r.reason || `APNs ${r.status || "unreachable"}` });
    });
  };

  return {
    handler,
    close: () => {
      for (const s of sessions.values()) s.close();
      sessions.clear();
    },
  };
}

/** From the environment: the key's PEM (or its file), its id, the team and the app's topic. */
export function relayFromEnv(env = process.env) {
  const key = env.APNS_KEY || (env.APNS_KEY_FILE && readFileSync(env.APNS_KEY_FILE, "utf8"));
  const missing = ["APNS_KEY_ID", "APNS_TEAM_ID", "APNS_TOPIC"].filter((k) => !env[k]);
  if (!key) missing.unshift("APNS_KEY or APNS_KEY_FILE");
  if (missing.length) throw new Error(`Missing: ${missing.join(", ")}`);
  return createRelay({
    key,
    keyId: env.APNS_KEY_ID,
    teamId: env.APNS_TEAM_ID,
    topic: env.APNS_TOPIC,
    hosts: {
      ...(env.APNS_HOST && { production: env.APNS_HOST }),
      ...(env.APNS_SANDBOX_HOST && { sandbox: env.APNS_SANDBOX_HOST }),
    },
  });
}

if (import.meta.url === `file://${process.argv[1]}`) {
  const relay = relayFromEnv();
  const port = Number(process.env.PORT ?? 8790);
  createServer(relay.handler).listen(port, process.env.HOST ?? "0.0.0.0", () => {
    // The one line it ever writes: nothing about what passes.
    process.stdout.write(`Rasgeth push relay on port ${port}\n`);
  });
}

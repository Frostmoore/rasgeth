// The app's setup channel (G40.3): the nodes' handshake in setup mode at /api/setup-channel, on a
// real server. The app pins the machine's key, one device at a time, the API's own rules inside
// (the first access, maintenance), then a device token (G40.1's function, faked here) and the CA.
import { join } from "node:path";
import { SETUP_CHANNEL_PATH } from "@redgiant/protocol";
import { afterEach, describe, expect, it, vi } from "vitest";
import WebSocket from "ws";
import {
  dialNode,
  type NodeChannelError,
  newIdentity,
  type SecureLink,
} from "../src/nodes/channel.js";
import { type SetupHooks, SetupService } from "../src/setup.js";
import { channelRequestOk, type SetupDevice } from "../src/setup-channel.js";
import { SetupNetwork } from "../src/setup-network.js";
import { startServer } from "./helpers.js";
import { apStatus, fakeHelper } from "./setup-network-fakes.js";

type Server = Awaited<ReturnType<typeof startServer>>;
let s: Server | undefined;
const links: SecureLink[] = [];
afterEach(async () => {
  for (const l of links.splice(0)) l.close();
  await s?.close();
  s = undefined;
  vi.restoreAllMocks();
});

const hooks: SetupHooks = {
  key: async () => [],
  server: async () => [],
  telegram: async () => null,
  search: async () => {},
  engine: async () => {},
};

async function withChannel(status: () => Record<string, unknown> | null = () => apStatus()) {
  vi.spyOn(console, "log").mockImplementation(() => {});
  const fake = fakeHelper(status);
  const issued: [string, SetupDevice][] = [];
  s = await startServer([], {}, {}, undefined, undefined, async (core, dir) => {
    const setup = new SetupService({
      db: core.db,
      core,
      dataDir: join(dir, "data"),
      ownerId: "me",
      hooks,
    });
    await setup.applyAtStartup();
    return {
      setup,
      setupNetwork: new SetupNetwork({ helper: fake.helper, cacheMs: 0 }),
      issueDeviceToken: async (owner, device) => {
        issued.push([owner, device]);
        return { token: "rgd_fake-device-token", device: { id: "dev_1" } };
      },
    };
  });
  return { ...fake, issued };
}

/** The app's side: dials with a fresh key as if from `from` (the address a proxy saw). */
async function app(o: { from?: string; expect?: string } = {}) {
  const url = `${(s?.url ?? "").replace(/^http/, "ws")}${SETUP_CHANNEL_PATH}`;
  const headers = { "x-forwarded-for": o.from ?? "10.42.0.10" };
  const d = await dialNode({
    url,
    identity: newIdentity().identity,
    mode: "setup",
    ...(o.expect && { expect: o.expect }),
    socket: (u) => new WebSocket(u, { headers }),
  });
  links.push(d.link);
  let n = 0;
  const waiting = new Map<number, (m: Record<string, unknown>) => void>();
  d.link.onMessage((m) => {
    const r = m as Record<string, unknown>;
    waiting.get(r.id as number)?.(r);
  });
  const ask = (m: Record<string, unknown>) =>
    new Promise<Record<string, unknown>>((ok) => {
      const id = ++n;
      waiting.set(id, ok);
      d.link.send({ id, ...m });
    });
  const http = async (method: string, path: string, body?: unknown) => {
    const r = await ask({
      t: "http",
      method,
      path,
      ...(body !== undefined && { body: JSON.stringify(body) }),
    });
    return { ...r, json: r.body ? JSON.parse(r.body as string) : undefined };
  };
  return { ...d, ask, http };
}

describe("what the setup channel carries", () => {
  it("only the API, with known methods and small bodies", () => {
    expect(channelRequestOk({ method: "GET", path: "/api/auth/methods" })).toBe(true);
    expect(channelRequestOk({ method: "POST", path: "/api/setup/complete", body: "{}" })).toBe(
      true,
    );
    expect(channelRequestOk({ method: "GET", path: "/api/jobs?limit=5" })).toBe(true);
    expect(channelRequestOk({ method: "GET", path: "/index.html" })).toBe(false);
    expect(channelRequestOk({ method: "GET", path: "/api/../etc/passwd" })).toBe(false);
    expect(channelRequestOk({ method: "GET", path: SETUP_CHANNEL_PATH })).toBe(false);
    expect(channelRequestOk({ method: "TRACE", path: "/api/health" })).toBe(false);
    expect(channelRequestOk({ method: "GET", path: "/api/health\nx" })).toBe(false);
    expect(
      channelRequestOk({ method: "POST", path: "/api/x", body: "x".repeat(1024 * 1024 + 1) }),
    ).toBe(false);
  });
});

describe("the setup channel (G40.3)", () => {
  it("answers with this machine's node key, which the app pins", async () => {
    await withChannel();
    const a = await app();
    const info = await a.ask({ t: "info" });
    const fp = (await s?.core.nodes.identity("me"))?.fingerprint;
    expect(a.peer.fingerprint).toBe(fp);
    expect(info).toMatchObject({
      ok: true,
      fingerprint: fp,
      here: "setup",
      signedIn: false,
      auth: { password: false, firstAccess: "password" },
      network: { active: true, ssid: "Rasgeth-Setup-1A2B" },
    });
    // The network's password is not part of what the channel tells.
    expect(JSON.stringify(info)).not.toContain("passphrase");
    a.link.close();
    // Pinned: the same key again is fine, another one is refused before anything is sent.
    const again = await app({ expect: fp as string });
    expect(again.peer.fingerprint).toBe(fp);
    again.link.close();
    const wrong = await app({ expect: newIdentity().identity.fingerprint }).catch((e) => e);
    expect((wrong as NodeChannelError).code).toBe("fingerprint-changed");
  });

  it("holds one device at a time", async () => {
    await withChannel();
    const first = await app();
    const second = await app().catch((e) => e);
    expect((second as NodeChannelError).code).toBe("busy");
    first.link.close();
    await new Promise((r) => setTimeout(r, 50));
    const third = await app();
    expect((await third.ask({ t: "info" })).ok).toBe(true);
  });

  it("creates the first access inside, then hands over the device token and the CA", async () => {
    const { issued } = await withChannel();
    const a = await app();
    // Nothing before signing in.
    expect(await a.ask({ t: "device", name: "Pixel 9" })).toMatchObject({
      ok: false,
      error: "unauthorized",
    });
    expect(await a.ask({ t: "home-network", cable: true })).toMatchObject({
      ok: false,
      error: "unauthorized",
    });
    const first = await a.http("POST", "/api/auth/first-access", {
      password: "una-password-lunga",
    });
    expect(first.status).toBe(200);
    // The session opened inside is used for the rest of the channel.
    expect((await a.http("GET", "/api/setup")).status).toBe(200);
    expect((await a.ask({ t: "info" })).signedIn).toBe(true);
    const dev = await a.ask({ t: "device", name: "Pixel 9", platform: "android" });
    expect(dev).toMatchObject({
      ok: true,
      token: "rgd_fake-device-token",
      deviceId: "dev_1",
      ca: "Q0EgUEVN",
      fingerprint: a.peer.fingerprint,
    });
    expect(issued).toEqual([["me", { name: "Pixel 9", platform: "android" }]]);
    // An unknown platform is "other".
    await a.ask({ t: "device", name: "Laptop", platform: "beos" });
    expect(issued[1]?.[1].platform).toBe("other");
    expect(await a.ask({ t: "home-network", cable: true })).toMatchObject({
      ok: true,
      state: "connected",
      address: "192.168.1.40",
    });
    expect(await a.ask({ t: "home-network", ssid: "Casa", password: "short" })).toMatchObject({
      ok: false,
      error: "bad_request",
    });
    expect((await a.ask({ t: "http", method: "GET", path: "/" })).error).toBe("bad_request");
  });

  it("keeps the API's rules: the first access from outside the local network, maintenance", async () => {
    await withChannel(() => apStatus({ active: false, mode: "off" }));
    const outside = await app({ from: "203.0.113.9" });
    const r = await outside.http("POST", "/api/auth/first-access", {
      password: "una-password-lunga",
    });
    expect(r.status).toBe(403);
    expect(r.json.code).toBe("not_here");
    outside.link.close();
    await s?.close();
    await withChannel(() => apStatus({ mode: "maintenance", pending: false }));
    const m = await app();
    expect((await m.ask({ t: "info" })).here).toBe("maintenance");
    const no = await m.http("POST", "/api/auth/first-access", { password: "una-password-lunga" });
    expect(no.status).toBe(403);
    expect(no.json.code).toBe("closed");
  });
});

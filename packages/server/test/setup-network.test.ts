// RedGiant OS's temporary network on the server's side (G40.3): the rules as tables, then the
// captive portal, the first access and the home network over HTTP, with a fake OS helper.
import { request } from "node:http";
import { join } from "node:path";
import { afterEach, describe, expect, it, vi } from "vitest";
import { type SetupHooks, SetupService } from "../src/setup.js";
import {
  captiveRedirect,
  homeChoiceOf,
  inSubnet,
  networkOf,
  parseSetupStatus,
  SetupNetwork,
} from "../src/setup-network.js";
import { startServer } from "./helpers.js";
import { apStatus, fakeHelper } from "./setup-network-fakes.js";

describe("the temporary network's rules", () => {
  it("knows its subnet", () => {
    expect(inSubnet("10.42.0.10", "10.42.0.0/24")).toBe(true);
    expect(inSubnet("::ffff:10.42.0.10", "10.42.0.0/24")).toBe(true);
    expect(inSubnet("10.42.1.10", "10.42.0.0/24")).toBe(false);
    expect(inSubnet("192.168.1.5", "10.42.0.0/24")).toBe(false);
    expect(inSubnet("fe80::1", "10.42.0.0/24")).toBe(false);
    expect(inSubnet(undefined, "10.42.0.0/24")).toBe(false);
    expect(inSubnet("10.42.0.10", "nonsense")).toBe(false);
  });

  it("says where a request comes from only while the network is open", () => {
    const open = { active: true, mode: "setup" as const, subnet: "10.42.0.0/24" };
    expect(networkOf("10.42.0.10", open)).toBe("setup");
    expect(networkOf("10.42.0.10", { ...open, mode: "maintenance" })).toBe("maintenance");
    expect(networkOf("192.168.1.5", open)).toBe("home");
    expect(networkOf("10.42.0.10", { ...open, active: false })).toBe("home");
    expect(networkOf("10.42.0.10", { ...open, mode: "off" })).toBe("home");
    expect(networkOf("10.42.0.10", null)).toBe("home");
  });

  it("sends the probes of phones and computers to the first start's page, never RedGiant's own names", () => {
    const at = (host: string | undefined, here: "home" | "setup" | "maintenance" = "setup") =>
      captiveRedirect({ host, here, address: "10.42.0.1" });
    for (const probe of [
      "connectivitycheck.gstatic.com",
      "clients3.google.com",
      "captive.apple.com",
      "www.apple.com",
      "www.msftconnecttest.com",
      "www.msftncsi.com",
      "detectportal.firefox.com",
      "nmcheck.gnome.org",
    ])
      expect(at(probe)).toBe("http://10.42.0.1/");
    expect(at("captive.apple.com", "maintenance")).toBe("http://10.42.0.1/");
    for (const own of [
      "10.42.0.1",
      "10.42.0.1:7600",
      "redgiant.local",
      "redgiant-2.local",
      "setup.redgiant",
      "redgiant",
      "localhost:7600",
      "[fe80::1]",
      undefined,
    ])
      expect(at(own)).toBeNull();
    expect(at("connectivitycheck.gstatic.com", "home")).toBeNull();
  });

  it("reads the machine's answer, and anything odd as closed", () => {
    expect(parseSetupStatus(apStatus())).toMatchObject({
      active: true,
      mode: "setup",
      ssid: "RedGiant-Setup-1A2B",
      networks: [{ ssid: "Casa", security: "psk", signal: -45 }],
    });
    expect(parseSetupStatus({ ok: true, active: true, mode: "weird" })).toMatchObject({
      active: false,
      mode: "off",
      capable: "unknown",
      networks: [],
      lastTry: null,
    });
    expect(
      parseSetupStatus(
        apStatus({ lastTry: { state: "failed", ssid: "Casa", error: "connect_failed", at: 5 } }),
      ).lastTry,
    ).toEqual({ state: "failed", ssid: "Casa", error: "connect_failed", at: 5 });
  });

  it("checks the home network chosen as the helper will", () => {
    expect(homeChoiceOf({ cable: true })).toEqual({ cable: true });
    expect(homeChoiceOf({ ssid: "Casa", password: "una password" })).toEqual({
      ssid: "Casa",
      password: "una password",
      hidden: false,
    });
    expect(homeChoiceOf({ ssid: "Aperta" })).toEqual({
      ssid: "Aperta",
      password: "",
      hidden: false,
    });
    expect(homeChoiceOf({ ssid: "Casa", password: "short" })).toBeNull();
    expect(homeChoiceOf({ ssid: "" })).toBeNull();
    expect(homeChoiceOf({ ssid: "x".repeat(33) })).toBeNull();
    expect(homeChoiceOf(null)).toBeNull();
  });

  it("asks the machine at most every few seconds, keeps it open while used, closes it when done", async () => {
    let t = 0;
    const { helper, calls } = fakeHelper(() => apStatus());
    const n = new SetupNetwork({ helper, now: () => t });
    expect(await n.here("10.42.0.10")).toBe("setup");
    expect(await n.here("10.42.0.11")).toBe("setup");
    expect(await n.here("192.168.1.5")).toBe("home");
    expect(calls.filter((c) => c.op === "ap-status")).toHaveLength(1);
    expect(calls.filter((c) => c.op === "ap-keep")).toHaveLength(1);
    t = 61_000;
    await n.here("10.42.0.10");
    expect(calls.filter((c) => c.op === "ap-status")).toHaveLength(2);
    expect(calls.filter((c) => c.op === "ap-keep")).toHaveLength(2);
    await n.reconcile(false);
    expect(calls.some((c) => c.op === "ap-done")).toBe(false);
    await n.reconcile(true);
    expect(calls.some((c) => c.op === "ap-done")).toBe(true);
  });

  it("is never there without the OS helper, or with an old one", async () => {
    expect(await new SetupNetwork().here("10.42.0.10")).toBe("home");
    expect(await new SetupNetwork().status()).toBeNull();
    const { helper } = fakeHelper(() => null);
    expect(await new SetupNetwork({ helper }).status()).toBeNull();
    expect(await new SetupNetwork({ helper }).here("10.42.0.10")).toBe("home");
  });
});

// --- over HTTP ----------------------------------------------------------------------------------

type Server = Awaited<ReturnType<typeof startServer>>;
let s: Server | undefined;
afterEach(async () => {
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

async function withNetwork(status: () => Record<string, unknown> | null) {
  vi.spyOn(console, "log").mockImplementation(() => {});
  const fake = fakeHelper(status);
  let setup: SetupService | undefined;
  const network = new SetupNetwork({ helper: fake.helper, cacheMs: 0 });
  s = await startServer([], {}, {}, undefined, undefined, async (core, dir) => {
    setup = new SetupService({
      db: core.db,
      core,
      dataDir: join(dir, "data"),
      ownerId: "me",
      hooks,
    });
    await setup.applyAtStartup();
    setup.completedHooks.push(() => network.done());
    return { setup, setupNetwork: network };
  });
  return { ...fake, setup: setup as SetupService };
}

/** A raw request with any Host (fetch would not let a test choose it). */
function raw(
  path: string,
  headers: Record<string, string>,
  method = "GET",
  body?: unknown,
): Promise<{ status: number; location?: string; body: string }> {
  const u = new URL(s?.url ?? "");
  return new Promise((ok, no) => {
    const r = request(
      {
        host: u.hostname,
        port: u.port,
        path,
        method,
        headers: { ...(body !== undefined && { "content-type": "application/json" }), ...headers },
      },
      (res) => {
        let b = "";
        res.on("data", (d) => {
          b += d;
        });
        res.on("end", () =>
          ok({
            status: res.statusCode ?? 0,
            ...(res.headers.location && { location: res.headers.location }),
            body: b,
          }),
        );
      },
    );
    r.on("error", no);
    r.end(body === undefined ? undefined : JSON.stringify(body));
  });
}

const fromAp = { "x-forwarded-for": "10.42.0.10" };
const fromHome = { "x-forwarded-for": "192.168.1.77" };

describe("the temporary network over HTTP (G40.3)", () => {
  it("answers the captive probes from the temporary network with the first start's page", async () => {
    await withNetwork(() => apStatus());
    for (const [host, path] of [
      ["connectivitycheck.gstatic.com", "/generate_204"],
      ["captive.apple.com", "/hotspot-detect.html"],
      ["www.msftconnecttest.com", "/connecttest.txt"],
    ]) {
      const r = await raw(path as string, { host: host as string, ...fromAp });
      expect(r.status).toBe(302);
      expect(r.location).toBe("http://10.42.0.1/");
    }
    // RedGiant's own address is the page, and the home network is never redirected.
    expect((await raw("/api/health", { host: "10.42.0.1", ...fromAp })).status).toBe(200);
    expect(
      (await raw("/generate_204", { host: "connectivitycheck.gstatic.com", ...fromHome })).status,
    ).not.toBe(302);
  });

  it("tells the page it is on the temporary network, with nothing secret", async () => {
    await withNetwork(() => apStatus());
    const here = JSON.parse(
      (await raw("/api/setup-network/here", { host: "10.42.0.1", ...fromAp })).body,
    );
    expect(here).toEqual({ here: "setup", ssid: "RedGiant-Setup-1A2B" });
    const home = JSON.parse(
      (await raw("/api/setup-network/here", { host: "x.local", ...fromHome })).body,
    );
    expect(home).toEqual({ here: "home" });
    // The rest needs a sign-in.
    expect((await raw("/api/setup-network", { host: "10.42.0.1", ...fromAp })).status).toBe(401);
  });

  it("lets the temporary network of a first start create the access, and closes it once completed", async () => {
    const { calls, setup } = await withNetwork(() => apStatus());
    const methods = JSON.parse(
      (await raw("/api/auth/methods", { host: "10.42.0.1", ...fromAp })).body,
    );
    expect(methods.firstAccess).toBe("password");
    const r = await raw("/api/auth/first-access", { host: "10.42.0.1", ...fromAp }, "POST", {
      password: "una-password-lunga",
    });
    expect(r.status).toBe(200);
    expect(calls.some((c) => c.op === "ap-keep")).toBe(true);
    await setup.complete();
    expect(calls.some((c) => c.op === "ap-done")).toBe(true);
  });

  it("never makes a new owner from the temporary network in maintenance", async () => {
    await withNetwork(() => apStatus({ mode: "maintenance", pending: false }));
    const methods = JSON.parse(
      (await raw("/api/auth/methods", { host: "10.42.0.1", ...fromAp })).body,
    );
    expect(methods.firstAccess).toBeUndefined();
    const r = await raw("/api/auth/first-access", { host: "10.42.0.1", ...fromAp }, "POST", {
      password: "una-password-lunga",
    });
    expect(r.status).toBe(403);
    expect(JSON.parse(r.body).code).toBe("closed");
    // From the home network the first access is the usual one (G39.7).
    const home = JSON.parse(
      (await raw("/api/auth/methods", { host: "x.local", ...fromHome })).body,
    );
    expect(home.firstAccess).toBe("password");
  });

  it("tries the home network for a signed-in page, the password checked first", async () => {
    const { calls } = await withNetwork(() => apStatus());
    const api = s?.api as NonNullable<Server>["api"];
    expect((await api("GET", "/api/setup-network")).body).toMatchObject({
      here: "home",
      status: { active: true, ssid: "RedGiant-Setup-1A2B" },
    });
    expect((await api("POST", "/api/setup-network/home", { cable: true })).body).toEqual({
      state: "connected",
      address: "192.168.1.40",
    });
    expect(
      (await api("POST", "/api/setup-network/home", { ssid: "Casa", password: "una password" }))
        .body,
    ).toEqual({ state: "trying" });
    expect(
      (await api("POST", "/api/setup-network/home", { ssid: "Casa", password: "short" })).status,
    ).toBe(400);
    expect(calls.filter((c) => c.op === "home-network-try")).toEqual([
      { op: "home-network-try", cable: true },
      { op: "home-network-try", ssid: "Casa", password: "una password", hidden: false },
    ]);
  });
});

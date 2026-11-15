// The setup channel for the app (G40.3, RGCompanion): a WebSocket at /api/setup-channel with the
// nodes' handshake (nodes/channel.ts) in "setup" mode. RedGiant answers with its node identity
// (ed25519, `node:identity`); the app pins its fingerprint the first time and from then on talks
// only to that key, on the temporary network RedGiant-Setup-XXXX and at home. Inside, every frame
// is encrypted (X25519, ChaCha20-Poly1305 with counters): the account's password and the home
// Wi-Fi's never travel in clear over the open air, nor through anyone listening.
//
// One device at a time: while one app holds the channel another one is refused ("busy"). The
// channel gives nothing by itself: what may be done is what the HTTP API allows, with the same
// rules (the first access from the local network, first-access.ts; in maintenance never a new
// owner), because every request inside it is the API's own, carried with the address and the
// proxies' headers of the connection that opened the channel. Messages, each with its `id`:
//   {t: "info"}                          → the machine's fingerprint, version, first access, network
//   {t: "http", method, path, body?}     → the API's answer {status, type, body}; the session a
//                                          sign-in or the first access opened is used for the rest
//   {t: "device", name, platform?}       → signed in: a token for this device (issued by G40.1's
//                                          function, injected) and the machine's local CA
//   {t: "home-network", cable | ssid…}   → signed in: the home network (setup-network.ts)
import type { IncomingMessage } from "node:http";
import type { SetupHomeChoice, SetupNetworkHere } from "@redgiant/protocol";
import type WebSocket from "ws";
import type { Principal } from "./auth.js";
import { acceptNode, type NodeIdentity, type SecureLink } from "./nodes/channel.js";
import { homeChoiceOf, type SetupNetwork } from "./setup-network.js";

/** The systems the app runs on (the same values as G40.1's `DevicePlatform`). */
export type SetupDevicePlatform = "android" | "ios" | "windows" | "macos" | "linux" | "other";
const PLATFORMS = new Set<string>(["android", "ios", "windows", "macos", "linux", "other"]);

/** A device the app runs on, as it introduces itself. */
export interface SetupDevice {
  name: string;
  platform: SetupDevicePlatform;
}

/**
 * Issues the token of a device for its owner (G40.1, Settings › Devices: named, revocable, never
 * in clear in a log): `core.devices.create(ownerId, { name, platform })`. Passed from outside:
 * the setup channel only hands it over.
 */
export type IssueDeviceToken = (
  ownerId: string,
  device: SetupDevice,
) => Promise<{ token: string; device: { id: string } }>;

export interface SetupChannelOptions {
  /** The owner of this installation (one per installation). */
  owner: string;
  /** This machine's identity (the nodes' one, from the keychain). */
  identity: (ownerId: string) => Promise<NodeIdentity>;
  /** The HTTP API (Hono's fetch); `env` carries the connection's address. */
  fetch: (req: Request, env: unknown) => Response | Promise<Response>;
  authenticate: (token: string | undefined) => Promise<Principal | null>;
  network?: SetupNetwork | undefined;
  issueDeviceToken?: IssueDeviceToken | undefined;
  version?: string | null | undefined;
  timeoutMs?: number;
}

/** The headers of the connection that opened the channel, carried into every request in it. */
const CARRIED = [
  "x-forwarded-for",
  "x-forwarded-proto",
  "x-real-ip",
  "forwarded",
  "cf-connecting-ip",
  "cf-ray",
  "user-agent",
  "x-redgiant-local-tls",
];
const METHODS = new Set(["GET", "POST", "PUT", "PATCH", "DELETE"]);
/** API paths only; never the channel itself. */
const PATH = /^\/api\/[A-Za-z0-9/_.~%-]*(\?[A-Za-z0-9_.~%&=+,-]*)?$/;
const SIGN_IN = new Set(["/api/auth/first-access", "/api/auth/login", "/api/auth/setup-code"]);
const MAX_BODY = 1024 * 1024;

/** Whether a request may go through the channel: an API path, a known method, a small body. */
export function channelRequestOk(m: { method?: unknown; path?: unknown; body?: unknown }): boolean {
  if (typeof m.method !== "string" || !METHODS.has(m.method)) return false;
  if (typeof m.path !== "string" || !PATH.test(m.path) || m.path.includes("..")) return false;
  if (m.path.startsWith("/api/setup-channel")) return false;
  if (m.body !== undefined && (typeof m.body !== "string" || m.body.length > MAX_BODY))
    return false;
  return true;
}

interface Held {
  fingerprint: string;
  link: SecureLink;
}

export class SetupChannel {
  private held: Held | undefined;

  constructor(private readonly o: SetupChannelOptions) {}

  /** Whether a device holds the channel now. */
  get busy(): boolean {
    return Boolean(this.held?.link.isOpen);
  }

  /** A socket that just opened at /api/setup-channel. */
  async accept(ws: WebSocket, req: IncomingMessage): Promise<void> {
    // The app's hello may arrive while the key is read: nothing is delivered until the
    // handshake listens.
    ws.pause();
    let identity: NodeIdentity;
    try {
      identity = await this.o.identity(this.o.owner);
    } catch {
      ws.close(4005, "The keychain is closed: the setup channel needs this machine's key");
      return;
    }
    let acc: Awaited<ReturnType<typeof acceptNode>>;
    try {
      const accepting = acceptNode(ws, {
        identity,
        known: () => false,
        // One device at a time; the same device coming back takes its place.
        setup: (fp) => (this.held?.link.isOpen && this.held.fingerprint !== fp ? "busy" : true),
        ...(this.o.timeoutMs && { timeoutMs: this.o.timeoutMs }),
      });
      ws.resume();
      acc = await accepting;
    } catch {
      return;
    }
    if (acc.mode !== "setup") {
      acc.link.close(4006, "Not a setup handshake");
      return;
    }
    const link = acc.link;
    const fingerprint = acc.peer.fingerprint;
    if (this.held && this.held.fingerprint === fingerprint) this.held.link.close(1000, "replaced");
    const held: Held = { fingerprint, link };
    this.held = held;
    link.onClose(() => {
      if (this.held === held) this.held = undefined;
    });
    const conn = connectionOf(req);
    let session: string | undefined;
    link.onMessage((raw) => {
      const m = (raw && typeof raw === "object" ? raw : {}) as Record<string, unknown>;
      const id = typeof m.id === "string" || typeof m.id === "number" ? m.id : null;
      void this.handle(m, conn, {
        get: () => session,
        set: (t) => {
          session = t;
        },
      })
        .then((r) => link.send({ id, ok: true, ...r }))
        .catch((err: Error & { code?: string }) =>
          link.send({ id, ok: false, error: err.code ?? "failed", message: err.message }),
        );
    });
  }

  private async handle(
    m: Record<string, unknown>,
    conn: Connection,
    session: { get(): string | undefined; set(t: string): void },
  ): Promise<Record<string, unknown>> {
    const here: SetupNetworkHere = (await this.o.network?.here(conn.address)) ?? "home";
    const identity = await this.o.identity(this.o.owner);
    const signedIn = async () => {
      const p = await this.o.authenticate(session.get());
      if (!p) throw Object.assign(new Error("Sign in first"), { code: "unauthorized" });
      return p;
    };
    switch (m.t) {
      case "info": {
        const methods = await this.call(conn, session.get(), "GET", "/api/auth/methods");
        const status = await this.o.network?.status();
        return {
          fingerprint: identity.fingerprint,
          version: this.o.version ?? null,
          here,
          auth: methods.json,
          signedIn: Boolean(await this.o.authenticate(session.get())),
          network: status
            ? {
                active: status.active,
                mode: status.mode,
                ssid: status.ssid,
                networks: status.networks,
                lastTry: status.lastTry,
              }
            : null,
        };
      }
      case "http": {
        if (!channelRequestOk(m))
          throw Object.assign(new Error("Not a request the channel carries"), {
            code: "bad_request",
          });
        const r = await this.call(
          conn,
          session.get(),
          m.method as string,
          m.path as string,
          m.body as string | undefined,
        );
        const path = (m.path as string).split("?")[0] ?? "";
        // A sign-in in the channel: the rest of it uses that session.
        const token = (r.json as { token?: unknown } | undefined)?.token;
        if (r.status === 200 && SIGN_IN.has(path) && typeof token === "string") session.set(token);
        return { status: r.status, type: r.type, body: r.body };
      }
      case "device": {
        const p = await signedIn();
        const issue = this.o.issueDeviceToken;
        if (!issue)
          throw Object.assign(new Error("Device tokens are not available here"), {
            code: "unavailable",
          });
        const name = typeof m.name === "string" ? m.name.trim().slice(0, 60) : "";
        if (!name)
          throw Object.assign(new Error("A device name is needed"), { code: "bad_request" });
        const platform: SetupDevicePlatform =
          typeof m.platform === "string" && PLATFORMS.has(m.platform)
            ? (m.platform as SetupDevicePlatform)
            : "other";
        const t = await issue(p.ownerId, { name, platform });
        return {
          token: t.token,
          deviceId: t.device.id,
          ca: (await this.o.network?.ca()) ?? null,
          fingerprint: identity.fingerprint,
        };
      }
      case "home-network": {
        await signedIn();
        const choice: SetupHomeChoice | null = homeChoiceOf(m);
        if (!choice)
          throw Object.assign(new Error("A network name (and its password) or the cable"), {
            code: "bad_request",
          });
        if (!this.o.network?.available)
          throw Object.assign(new Error("No temporary network here"), { code: "not_installed" });
        return { ...(await this.o.network.tryHome(choice)) };
      }
      default:
        throw Object.assign(new Error("Unknown message"), { code: "bad_request" });
    }
  }

  /** One request to the API, as the connection that opened the channel would make it. */
  private async call(
    conn: Connection,
    token: string | undefined,
    method: string,
    path: string,
    body?: string,
  ): Promise<{ status: number; type: string; body: string; json?: unknown }> {
    const headers = new Headers(conn.headers);
    if (token) headers.set("authorization", `Bearer ${token}`);
    if (body !== undefined) headers.set("content-type", "application/json");
    const res = await this.o.fetch(
      new Request(`http://${conn.host}${path}`, {
        method,
        headers,
        ...(body !== undefined && method !== "GET" && { body }),
      }),
      { incoming: { socket: { remoteAddress: conn.socket } } },
    );
    const type = res.headers.get("content-type") ?? "";
    const text = await res.text();
    let json: unknown;
    if (type.includes("json"))
      try {
        json = JSON.parse(text);
      } catch {}
    return { status: res.status, type, body: text, ...(json !== undefined && { json }) };
  }
}

interface Connection {
  host: string;
  socket: string | undefined;
  /** Who is asking, as the API itself reckons it (Cloudflare's, the last proxy's, the socket). */
  address: string | undefined;
  headers: [string, string][];
}

function connectionOf(req: IncomingMessage): Connection {
  const h = (n: string) => {
    const v = req.headers[n];
    return Array.isArray(v) ? v.join(", ") : v;
  };
  const headers: [string, string][] = [];
  for (const n of CARRIED) {
    const v = h(n);
    if (v) headers.push([n, v]);
  }
  const socket = req.socket?.remoteAddress;
  const host =
    (h("host") ?? "redgiant.local").replace(/[^A-Za-z0-9.:[\]-]/g, "") || "redgiant.local";
  return {
    host,
    socket,
    address: h("cf-connecting-ip") || h("x-forwarded-for")?.split(",").at(-1)?.trim() || socket,
    headers,
  };
}

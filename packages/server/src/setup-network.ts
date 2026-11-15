// RedGiant OS's temporary network (G40.3), as the server sees it: RedGiant-Setup-XXXX, opened by
// the machine (packaging/os/rootfs/usr/lib/redgiant-os/redgiant-setup-ap) at a first start and,
// later, as maintenance. The server asks the OS helper what it is doing (ap-status), answers the
// captive portal probes of phones and computers with the first start's page, tells the first
// access rule where a request comes from (first-access.ts: the temporary network of a first start
// is the local network; in maintenance it never makes a new owner), keeps the network open while
// a device uses it, closes it when the first start is completed, and tries the home network.
// The rules are pure functions, tested as tables.
import type {
  SetupHomeChoice,
  SetupHomeResult,
  SetupNetworkHere,
  SetupNetworkStatus,
  SetupWifiNetwork,
} from "@redgiant/protocol";
import { HelperError, type OsHelper, wifiPasswordOk, wifiSsidOk } from "./os-helper.js";

/** An IPv4 address as a number, or null (an IPv4 inside IPv6, ::ffff:10.42.0.5, included). */
function v4(ip: string): number | null {
  let a = ip.trim().toLowerCase();
  if (a.startsWith("::ffff:")) a = a.slice(7);
  const m = /^(\d{1,3})\.(\d{1,3})\.(\d{1,3})\.(\d{1,3})$/.exec(a);
  if (!m) return null;
  const n = m.slice(1).map(Number);
  if (n.some((x) => x > 255)) return null;
  return (((n[0] ?? 0) << 24) | ((n[1] ?? 0) << 16) | ((n[2] ?? 0) << 8) | (n[3] ?? 0)) >>> 0;
}

/** Whether `address` is in `subnet` (a.b.c.d/n, IPv4 only). */
export function inSubnet(address: string | undefined, subnet: string): boolean {
  if (!address) return false;
  const [base = "", bits = ""] = subnet.split("/");
  const b = v4(base);
  const a = v4(address);
  const n = Number(bits);
  if (a === null || b === null || !Number.isInteger(n) || n < 8 || n > 32) return false;
  const mask = n === 32 ? 0xffffffff : (0xffffffff << (32 - n)) >>> 0;
  return (a & mask) === (b & mask);
}

/** Where a request comes from: the temporary network (setup or maintenance) or anywhere else. */
export function networkOf(
  address: string | undefined,
  status: Pick<SetupNetworkStatus, "active" | "mode" | "subnet"> | null | undefined,
): SetupNetworkHere {
  if (!status?.active || status.mode === "off") return "home";
  return inSubnet(address, status.subnet) ? status.mode : "home";
}

/** The names that are RedGiant itself (never redirected). */
function ours(host: string, address: string): boolean {
  const h = host.toLowerCase().replace(/:\d+$/, "").replace(/\.$/, "");
  return (
    h === "" ||
    h === address ||
    h === "localhost" ||
    h === "setup.redgiant" ||
    h.endsWith(".local") ||
    !h.includes(".") ||
    v4(h) !== null ||
    h.startsWith("[")
  );
}

/**
 * The captive portal: a request from the temporary network for a name that is not RedGiant's
 * (the probe of a phone or a computer: connectivitycheck.gstatic.com/generate_204,
 * captive.apple.com/hotspot-detect.html, www.msftconnecttest.com/connecttest.txt,
 * detectportal.firefox.com…; the DNS answers every name with RedGiant's address) goes to the
 * first start's page, so the system shows it by itself. Where to send it, or null.
 */
export function captiveRedirect(o: {
  host: string | undefined;
  here: SetupNetworkHere;
  address: string;
}): string | null {
  if (o.here === "home") return null;
  if (ours(o.host ?? "", o.address)) return null;
  return `http://${o.address}/`;
}

const str = (v: unknown, d = "") => (typeof v === "string" ? v : d);
const numOr = (v: unknown, d: number | null) => (typeof v === "number" ? v : d);

/** The helper's ap-status reply, checked (anything odd becomes "off"). */
export function parseSetupStatus(r: Record<string, unknown>): SetupNetworkStatus {
  const mode = r.mode === "setup" || r.mode === "maintenance" ? r.mode : "off";
  const capable = ["ok", "container", "no_wifi", "no_ap"].includes(str(r.capable))
    ? (r.capable as SetupNetworkStatus["capable"])
    : "unknown";
  const networks: SetupWifiNetwork[] = Array.isArray(r.networks)
    ? r.networks
        .filter(
          (n): n is Record<string, unknown> =>
            !!n && typeof n === "object" && typeof (n as { ssid?: unknown }).ssid === "string",
        )
        .map((n) => ({
          ssid: str(n.ssid),
          security: str(n.security, "psk"),
          signal: numOr(n.signal, -100) ?? -100,
        }))
    : [];
  const t = r.lastTry as Record<string, unknown> | null | undefined;
  const lastTry =
    t && (t.state === "connected" || t.state === "failed")
      ? {
          state: t.state as "connected" | "failed",
          ssid: str(t.ssid),
          ...(typeof t.error === "string" && { error: t.error }),
          at: numOr(t.at, 0) ?? 0,
        }
      : null;
  return {
    active: r.active === true && mode !== "off",
    mode,
    capable,
    pending: r.pending === true,
    ssid: str(r.ssid),
    passphrase: str(r.passphrase),
    address: str(r.address, "10.42.0.1"),
    subnet: str(r.subnet, "10.42.0.0/24"),
    since: numOr(r.since, null),
    windowEnds: numOr(r.windowEnds, 0) ?? 0,
    trying: r.trying === true,
    networks,
    lastTry,
  };
}

/** The home network chosen, checked as the helper will check it again. */
export function homeChoiceOf(b: unknown): SetupHomeChoice | null {
  if (!b || typeof b !== "object") return null;
  const o = b as Record<string, unknown>;
  if (o.cable === true) return { cable: true };
  if (typeof o.ssid !== "string" || !wifiSsidOk(o.ssid)) return null;
  const password = typeof o.password === "string" ? o.password : "";
  if (password !== "" && !wifiPasswordOk(password)) return null;
  return { ssid: o.ssid, password, hidden: o.hidden === true };
}

export interface SetupNetworkOptions {
  helper?: OsHelper | undefined;
  /** Tests: the clock (ms). */
  now?: () => number;
  /** How long a status is reused (default 3 s). */
  cacheMs?: number;
}

/** The temporary network through the OS helper; without one (no RedGiant OS) it is never there. */
export class SetupNetwork {
  private cached: { at: number; status: SetupNetworkStatus | null } | undefined;
  private asking: Promise<SetupNetworkStatus | null> | undefined;
  private keptAt = Number.NEGATIVE_INFINITY;

  constructor(private readonly o: SetupNetworkOptions = {}) {}

  private now() {
    return this.o.now?.() ?? Date.now();
  }

  get available(): boolean {
    return Boolean(this.o.helper);
  }

  /** What the machine says (reused for a few seconds); null without a temporary network. */
  async status(fresh = false): Promise<SetupNetworkStatus | null> {
    const helper = this.o.helper;
    if (!helper) return null;
    const c = this.cached;
    if (!fresh && c && this.now() - c.at < (this.o.cacheMs ?? 3000)) return c.status;
    this.asking ??= helper
      .call({ op: "ap-status" })
      .then((r) => parseSetupStatus(r))
      // An old system (no ap-status) or a helper that fails: no temporary network.
      .catch(() => null)
      .then((status) => {
        this.cached = { at: this.now(), status };
        this.asking = undefined;
        return status;
      });
    return this.asking;
  }

  /** Where a request from `address` comes from. A device there keeps the network open. */
  async here(address: string | undefined): Promise<SetupNetworkHere> {
    if (!this.o.helper) return "home";
    const s = await this.status();
    const here = networkOf(address, s);
    if (here !== "home") this.keep();
    return here;
  }

  /** A device is using the temporary network: it stays open (asked at most once a minute). */
  keep(): void {
    const t = this.now();
    if (!this.o.helper || t - this.keptAt < 60_000) return;
    this.keptAt = t;
    void this.o.helper.call({ op: "ap-keep" }).catch(() => {});
  }

  /** The first start is completed: the machine forgets it was new, the network closes. */
  async done(): Promise<void> {
    if (!this.o.helper) return;
    await this.o.helper.call({ op: "ap-done" }).catch(() => {});
    this.cached = undefined;
  }

  /** At start: a first start completed before the machine knew it (an old server) closes it. */
  async reconcile(completed: boolean): Promise<void> {
    if (!completed) return;
    const s = await this.status(true);
    if (s?.pending) await this.done();
  }

  /** The home network: the cable (its address), or a Wi-Fi network tried with the network closed. */
  async tryHome(choice: SetupHomeChoice): Promise<SetupHomeResult> {
    const helper = this.o.helper;
    if (!helper) throw new HelperError("not_installed");
    const r = await helper.call(
      "cable" in choice
        ? { op: "home-network-try", cable: true }
        : {
            op: "home-network-try",
            ssid: choice.ssid,
            password: choice.password ?? "",
            hidden: choice.hidden === true,
          },
    );
    this.cached = undefined;
    return r.state === "connected"
      ? { state: "connected", ...(typeof r.address === "string" && { address: r.address }) }
      : { state: "trying" };
  }

  /** The machine's local CA (base64 PEM) for the app, or null. */
  async ca(): Promise<string | null> {
    const helper = this.o.helper;
    if (!helper) return null;
    const r = await helper.call({ op: "https-status" }).catch(() => null);
    return typeof r?.ca === "string" && r.ca ? r.ca : null;
  }
}

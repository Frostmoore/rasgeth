// RedGiant OS's temporary network (G40.3): redgiant-setup-ap and the OS helper's ap-* and
// home-network-try, run for real with fake programs (busctl answers as iwd would, the rest only
// writes down what it was asked), in another root. The rule (decide) is a table.
import { execFileSync, spawnSync } from "node:child_process";
import { createHash } from "node:crypto";
import {
  chmodSync,
  copyFileSync,
  existsSync,
  mkdirSync,
  mkdtempSync,
  readFileSync,
  statSync,
  writeFileSync,
} from "node:fs";
import { tmpdir } from "node:os";
import { join } from "node:path";
import { fileURLToPath } from "node:url";
import { beforeEach, describe, expect, it } from "vitest";

const script = fileURLToPath(
  new URL("../rootfs/usr/lib/redgiant-os/redgiant-setup-ap", import.meta.url),
);
const helper = fileURLToPath(
  new URL("../../../packages/server/helpers/redgiant-helper", import.meta.url),
);
const has = (c: string) => spawnSync("sh", ["-c", `command -v ${c}`]).status === 0;
const tools = process.platform === "linux" && has("bash") && has("jq") && has("sha256sum");

const v = (type: string, data: unknown) => ({ type, data });
/** iwd's objects: the card as a station (with networks around) or as an access point. */
function objects(mode: "station" | "ap", o: { ap?: boolean; card?: boolean } = {}) {
  const data: Record<string, Record<string, Record<string, unknown>>> = {
    "/net/connman/iwd/0": {
      "net.connman.iwd.Adapter": {
        Powered: v("b", true),
        SupportedModes: v("as", o.ap === false ? ["station"] : ["ad-hoc", "station", "ap"]),
      },
    },
  };
  if (o.card !== false) {
    data["/net/connman/iwd/0/3"] = {
      "net.connman.iwd.Device": {
        Name: v("s", "wlan0"),
        Powered: v("b", true),
        Mode: v("s", mode),
        Adapter: v("o", "/net/connman/iwd/0"),
      },
      ...(mode === "station"
        ? { "net.connman.iwd.Station": { State: v("s", "disconnected"), Scanning: v("b", false) } }
        : { "net.connman.iwd.AccessPoint": { Started: v("b", false) } }),
    };
    if (mode === "station") {
      for (const [i, name] of ["Casa", "Vicino"].entries())
        data[`/net/connman/iwd/0/3/${i}_psk`] = {
          "net.connman.iwd.Network": {
            Name: v("s", name),
            Type: v("s", "psk"),
            Device: v("o", "/net/connman/iwd/0/3"),
          },
        };
    }
  }
  return JSON.stringify({ type: "a{oa{sa{sv}}}", data: [data] });
}

const FAKE_BUSCTL = `#!/bin/sh
D="$REDGIANT_SETUP_TEST_ROOT/fake"
echo "busctl $*" >>"$D/calls"
mode=$(cat "$D/mode" 2>/dev/null || echo station)
case "$*" in
  *GetManagedObjects*) cat "$D/objects-$mode.json" ;;
  *"set-property"*"Device Mode s ap"*) echo ap >"$D/mode" ;;
  *"set-property"*"Device Mode s station"*) echo station >"$D/mode" ;;
  *get-property*Scanning*) echo '{"type":"b","data":false}' ;;
  *GetOrderedNetworks*) echo '{"type":"a(on)","data":[[["/net/connman/iwd/0/3/1_psk",-7000],["/net/connman/iwd/0/3/0_psk",-4500]]]}' ;;
  *StartProfile*) [ -e "$D/ap-fail" ] && exit 1; exit 0 ;;
  *) exit 0 ;;
esac
`;
// ip: the default route (cable or none), the temporary network's address, a wired card.
const FAKE_IP = `#!/bin/sh
D="$REDGIANT_SETUP_TEST_ROOT/fake"
echo "ip $*" >>"$D/calls"
case "$*" in
  "-4 route show default") cat "$D/route" 2>/dev/null ;;
  "-o -4 addr show dev wlan0") echo "4: wlan0    inet 10.42.0.1/24 brd 10.42.0.255 scope global wlan0" ;;
  "-j -4 addr show") cat "$D/addrs.json" 2>/dev/null || echo '[]' ;;
  *) echo '[]' ;;
esac
`;
const RECORD = (name: string) => `#!/bin/sh
echo "${name} $*" >>"$REDGIANT_SETUP_TEST_ROOT/fake/calls"
exit 0
`;
const DETECT = `#!/bin/sh
if [ -e "$REDGIANT_SETUP_TEST_ROOT/fake/container" ]; then echo lxc; exit 0; fi
echo none; exit 1
`;

let root: string;
let bin: string;
const fake = (f: string) => join(root, "fake", f);
const calls = () => (existsSync(fake("calls")) ? readFileSync(fake("calls"), "utf8") : "");
const env = (extra: Record<string, string> = {}) => ({
  ...process.env,
  REDGIANT_SETUP_TEST_BIN: bin,
  REDGIANT_SETUP_TEST_ROOT: root,
  REDGIANT_HELPER_TEST_BIN: bin,
  REDGIANT_HELPER_TEST_ROOT: root,
  ...extra,
});
const run = (args: string[], extra: Record<string, string> = {}) =>
  execFileSync("bash", [script, ...args], { env: env(extra), encoding: "utf8", timeout: 60_000 });
const status = () => JSON.parse(run(["status"]));
/** One request to the OS helper, as the socket gives it. */
const ask = (line: string) => {
  const r = spawnSync("sh", [helper, "--stdin"], {
    env: env(),
    input: `${line}\n`,
    encoding: "utf8",
    timeout: 60_000,
  });
  return JSON.parse(r.stdout.trim().split("\n").at(-1) ?? "{}");
};
const b64 = (s: string) => Buffer.from(s).toString("base64");

beforeEach(() => {
  if (!tools) return;
  root = mkdtempSync(join(tmpdir(), "rg-setup-ap-"));
  bin = join(root, "bin");
  for (const d of [
    "bin",
    "fake",
    "etc",
    "proc",
    "var/lib/redgiant/setup-ap",
    "usr/lib/redgiant-os",
  ])
    mkdirSync(join(root, d), { recursive: true });
  writeFileSync(join(root, "etc/machine-id"), "0123456789abcdef0123456789abcdef\n");
  writeFileSync(join(root, "proc/uptime"), "120.55 300.00\n");
  writeFileSync(join(root, "var/lib/redgiant/setup-ap/pending"), "");
  writeFileSync(fake("objects-station.json"), objects("station"));
  writeFileSync(fake("objects-ap.json"), objects("ap"));
  // The helper runs the OS's own copy of the script.
  copyFileSync(script, join(root, "usr/lib/redgiant-os/redgiant-setup-ap"));
  chmodSync(join(root, "usr/lib/redgiant-os/redgiant-setup-ap"), 0o755);
  const put = (name: string, body: string) => {
    writeFileSync(join(bin, name), body);
    chmodSync(join(bin, name), 0o755);
  };
  put("busctl", FAKE_BUSCTL);
  put("ip", FAKE_IP);
  put("systemd-detect-virt", DETECT);
  for (const n of ["networkctl", "sysctl", "dnsmasq", "systemctl", "systemd-run", "rfkill"])
    put(n, RECORD(n));
});

describe("when the temporary network is open (redgiant-setup-ap decide)", () => {
  const cases: [string, string][] = [
    // A first start: always (the cable too), for 30 minutes from power on.
    ["pending=1 uptime=10", "setup"],
    ["pending=1 uptime=1799", "setup"],
    ["pending=1 uptime=1800", "off"],
    ["pending=1 uptime=1800 missing=-1", "off"],
    // A device using it, or a home network that failed: 10 more minutes.
    ["pending=1 uptime=4000 now=100 grace=200", "setup"],
    ["pending=1 uptime=4000 now=300 grace=200", "off"],
    // The home network works: closed, even within the window.
    ["pending=1 handed=1 uptime=10", "off"],
    ["pending=1 handed=1 uptime=10 now=1 grace=50", "off"],
    // Asked open (ap-start) or closed (ap-stop).
    ["pending=1 handed=1 uptime=9999 now=1 force=50", "setup"],
    ["pending=1 uptime=10 now=1 closed=50", "off"],
    // A configured machine: only maintenance, after 10 minutes without a home network.
    ["pending=0 uptime=10", "off"],
    ["pending=0 missing=-1", "off"],
    ["pending=0 missing=599", "off"],
    ["pending=0 missing=600", "maintenance"],
    ["pending=0 now=1 force=50", "maintenance"],
    ["pending=0 now=1 missing=900 closed=50", "off"],
    // Open for maintenance: closes when the cable is back, or after 10 minutes (the card looks
    // for the home Wi-Fi again), unless a device is using it.
    ["pending=0 cur=maintenance missing=-1", "off"],
    ["pending=0 cur=maintenance missing=900 on=100", "maintenance"],
    ["pending=0 cur=maintenance missing=900 on=600", "off"],
    ["pending=0 cur=maintenance missing=900 on=600 now=10 grace=99", "maintenance"],
    // A first start completed while open: closed.
    ["pending=0 cur=setup missing=-1", "off"],
  ];
  it.each(cases)("%s → %s", { skip: !tools }, (args, want) => {
    expect(run(["decide", ...args.split(" ")]).trim()).toBe(want);
  });
  it("refuses what it does not know", { skip: !tools }, () => {
    expect(spawnSync("bash", [script, "decide", "owner=1"], { env: env() }).status).toBe(2);
  });
});

describe("the temporary network on the machine (redgiant-setup-ap)", () => {
  it("names itself after the machine, the same at every start", { skip: !tools }, () => {
    const want = createHash("sha256")
      .update("0123456789abcdef0123456789abcdef")
      .digest("hex")
      .slice(0, 4)
      .toUpperCase();
    expect(run(["ssid"]).trim()).toBe(`RedGiant-Setup-${want}`);
  });

  it("knows when it cannot be: a container, no Wi-Fi, a card that cannot", { skip: !tools }, () => {
    expect(run(["capable"]).trim()).toBe("ok");
    writeFileSync(fake("objects-station.json"), objects("station", { ap: false }));
    expect(run(["capable"]).trim()).toBe("no_ap");
    writeFileSync(fake("objects-station.json"), objects("station", { card: false }));
    expect(run(["capable"]).trim()).toBe("no_wifi");
    writeFileSync(fake("container"), "");
    expect(run(["capable"]).trim()).toBe("container");
    // The service then only says so: RedGiant is found on the network.
    run(["run"]);
    expect(readFileSync(join(root, "run/redgiant-setup/capable"), "utf8").trim()).toBe("container");
    expect(calls()).not.toContain("StartProfile");
  });

  it("opens with iwd, one lease, a DNS for every name and nothing routed; closes leaving nothing", {
    skip: !tools,
  }, () => {
    run(["start", "setup"]);
    const s = status();
    expect(s).toMatchObject({
      ok: true,
      active: true,
      mode: "setup",
      pending: true,
      capable: "unknown",
      address: "10.42.0.1",
      subnet: "10.42.0.0/24",
      passphrase: "redgiant",
      trying: false,
      lastTry: null,
    });
    expect(s.ssid).toMatch(/^RedGiant-Setup-[0-9A-F]{4}$/);
    // The networks around, seen before the card became an access point, strongest first.
    expect(s.networks).toEqual([
      { ssid: "Casa", security: "psk", signal: -45 },
      { ssid: "Vicino", security: "psk", signal: -70 },
    ]);
    const net = readFileSync(join(root, "run/systemd/network/70-redgiant-setup.network"), "utf8");
    for (const line of [
      "Name=wlan0",
      "Address=10.42.0.1/24",
      "DHCPServer=yes",
      "PoolSize=1",
      "IPv4Forwarding=no",
      "RequiredForOnline=no",
      "DNS=10.42.0.1",
      "SendOption=114:string:http://10.42.0.1/",
    ])
      expect(net).toContain(line);
    const profile = join(root, `var/lib/iwd/ap/${s.ssid}.ap`);
    expect(readFileSync(profile, "utf8")).toContain("Passphrase=redgiant");
    expect(statSync(profile).mode & 0o777).toBe(0o600);
    const c = calls();
    expect(c).toContain("net.connman.iwd.Station Scan");
    expect(c).toContain("net.connman.iwd.Device Mode s ap");
    expect(c).toContain(`net.connman.iwd.AccessPoint StartProfile s ${s.ssid}`);
    expect(c).toContain("sysctl -qw net.ipv4.conf.wlan0.forwarding=0");
    expect(c).toMatch(/dnsmasq .*--listen-address=10\.42\.0\.1 .*--address=\/#\/10\.42\.0\.1/);
    run(["stop"]);
    expect(status()).toMatchObject({ active: false, mode: "off" });
    expect(existsSync(join(root, "run/systemd/network/70-redgiant-setup.network"))).toBe(false);
    expect(calls()).toContain("net.connman.iwd.AccessPoint Stop");
    expect(calls()).toContain("net.connman.iwd.Device Mode s station");
  });

  it("without dnsmasq (an older system): addresses only, no DNS offered", { skip: !tools }, () => {
    const noDns = join(root, "bin-nodns");
    mkdirSync(noDns);
    for (const n of ["busctl", "ip", "systemd-detect-virt", "networkctl", "sysctl"])
      copyFileSync(join(bin, n), join(noDns, n));
    for (const n of ["busctl", "ip", "systemd-detect-virt", "networkctl", "sysctl"])
      chmodSync(join(noDns, n), 0o755);
    // PATH without dnsmasq: only the fakes and the basic tools (bash, jq…) found by full path.
    const path = [noDns, "/usr/bin", "/bin"].join(":");
    if (spawnSync("sh", ["-c", "PATH=/usr/bin:/bin command -v dnsmasq"]).status === 0) return;
    execFileSync("bash", [script, "start", "setup"], {
      env: { ...env({ REDGIANT_SETUP_TEST_BIN: noDns }), PATH: path },
      encoding: "utf8",
    });
    const net = readFileSync(join(root, "run/systemd/network/70-redgiant-setup.network"), "utf8");
    expect(net).toContain("EmitDNS=no");
    expect(net).not.toContain("DNS=10.42.0.1\n");
  });

  it("leaves nothing open when iwd does not start the access point", { skip: !tools }, () => {
    writeFileSync(fake("ap-fail"), "");
    expect(spawnSync("bash", [script, "start", "setup"], { env: env() }).status).toBe(1);
    expect(status().active).toBe(false);
    expect(existsSync(join(root, "run/systemd/network/70-redgiant-setup.network"))).toBe(false);
  });

  it("tries the home Wi-Fi with the network closed, and opens it again with the error", {
    skip: !tools,
  }, () => {
    const answer = join(root, "fake-helper");
    const put = (reply: string) => {
      writeFileSync(answer, `#!/bin/sh\ncat >>"${fake("helper-in")}"\necho '${reply}'\n`);
      chmodSync(answer, 0o755);
    };
    const req = `wifi ${b64("Casa")} psk visible 0\n`;
    mkdirSync(join(root, "run/redgiant-setup"), { recursive: true });
    // Refused: open again, with the error, for 10 more minutes.
    put('{"ok":false,"error":"connect_failed","detail":"Operation failed"}');
    run(["start", "setup"]);
    writeFileSync(join(root, "run/redgiant-setup/try.req"), req);
    run(["try"], { REDGIANT_SETUP_TEST_HELPER: answer });
    expect(readFileSync(fake("helper-in"), "utf8")).toBe(
      `wifi-join-trial ${b64("Casa")} psk visible 0\n`,
    );
    let s = status();
    expect(s).toMatchObject({
      active: true,
      mode: "setup",
      trying: false,
      lastTry: { state: "failed", ssid: "Casa", error: "connect_failed" },
    });
    const grace = Number(readFileSync(join(root, "run/redgiant-setup/grace"), "utf8"));
    expect(grace).toBeGreaterThan(Date.now() / 1000 + 500);
    expect(existsSync(join(root, "run/redgiant-setup/try.req"))).toBe(false);
    // Joined: closed for good, the app finds RedGiant on the home network.
    put('{"ok":true,"state":"connected"}');
    writeFileSync(join(root, "run/redgiant-setup/try.req"), req);
    run(["try"], { REDGIANT_SETUP_TEST_HELPER: answer });
    s = status();
    expect(s).toMatchObject({ active: false, lastTry: { state: "connected", ssid: "Casa" } });
    expect(existsSync(join(root, "run/redgiant-setup/handed"))).toBe(true);
    expect(run(["decide", "pending=1", "handed=1", "uptime=10"]).trim()).toBe("off");
  });
});

describe("the OS helper's temporary network commands", () => {
  it("passes ap-status on, and ap-done makes the machine forget it was new", {
    skip: !tools,
  }, () => {
    const s = ask("ap-status");
    expect(s).toMatchObject({ ok: true, active: false, pending: true });
    expect(ask("ap-status now")).toEqual({ ok: false, error: "bad_request" });
    expect(ask("ap-done")).toEqual({ ok: true });
    expect(existsSync(join(root, "var/lib/redgiant/setup-ap/pending"))).toBe(false);
    expect(ask("ap-status").pending).toBe(false);
  });

  it("opens it only where it can be, and closes it", { skip: !tools }, () => {
    expect(ask("ap-start")).toEqual({ ok: false, error: "no_ap" });
    mkdirSync(join(root, "run/redgiant-setup"), { recursive: true });
    writeFileSync(join(root, "run/redgiant-setup/capable"), "ok\n");
    expect(ask("ap-start")).toEqual({ ok: true });
    expect(existsSync(join(root, "run/redgiant-setup/force"))).toBe(true);
    expect(ask("ap-stop")).toEqual({ ok: true });
    expect(existsSync(join(root, "run/redgiant-setup/force"))).toBe(false);
    expect(existsSync(join(root, "run/redgiant-setup/closed"))).toBe(true);
  });

  it("hands over to the cable with its address, after the reply", { skip: !tools }, () => {
    expect(ask("home-network-try cable")).toEqual({ ok: false, error: "no_cable" });
    writeFileSync(
      fake("addrs.json"),
      JSON.stringify([
        { ifname: "wlan0", operstate: "UP", addr_info: [{ local: "10.42.0.1", scope: "global" }] },
        {
          ifname: "docker0",
          operstate: "UP",
          addr_info: [{ local: "172.17.0.1", scope: "global" }],
        },
        {
          ifname: "enp1s0",
          operstate: "UP",
          addr_info: [{ local: "192.168.1.40", scope: "global" }],
        },
      ]),
    );
    expect(ask("home-network-try cable")).toEqual({
      ok: true,
      state: "connected",
      address: "192.168.1.40",
    });
    expect(calls()).toMatch(/systemd-run --on-active=20 .*redgiant-setup-ap handover/);
  });

  it("keeps the home Wi-Fi's password only in iwd's file, and tries it in its own unit", {
    skip: !tools,
  }, () => {
    expect(ask(`home-network-try ${b64("Casa")} ${b64("short")} visible`)).toEqual({
      ok: false,
      error: "bad_password",
    });
    expect(ask(`home-network-try ${b64("Casa")} ${b64("una password")} sideways`)).toEqual({
      ok: false,
      error: "bad_request",
    });
    expect(ask(`home-network-try ${b64("Casa")} ${b64("una password")} visible`)).toEqual({
      ok: true,
      state: "trying",
    });
    const file = join(root, "var/lib/iwd/Casa.psk");
    expect(readFileSync(file, "utf8")).toBe(
      "[Settings]\nAutoConnect=false\n\n[Security]\nPassphrase=una password\n",
    );
    expect(statSync(file).mode & 0o777).toBe(0o600);
    const req = readFileSync(join(root, "run/redgiant-setup/try.req"), "utf8");
    expect(req).toBe(`wifi ${b64("Casa")} psk visible 0\n`);
    expect(req).not.toContain(b64("una password"));
    expect(calls()).toMatch(
      /systemd-run --on-active=3 --unit=redgiant-setup-try .*redgiant-setup-ap try/,
    );
    expect(calls()).not.toContain("una password");
    // While a try runs, another one waits.
    writeFileSync(join(root, "run/redgiant-setup/trying"), "");
    expect(ask(`home-network-try ${b64("Casa")} - visible`)).toEqual({ ok: false, error: "busy" });
  });

  it("joins only a network being tried, never another saved one", { skip: !tools }, () => {
    mkdirSync(join(root, "var/lib/iwd"), { recursive: true });
    writeFileSync(join(root, "var/lib/iwd/Casa.psk"), "[Security]\nPassphrase=una password\n");
    expect(ask(`wifi-join-trial ${b64("Casa")} psk visible 0`)).toEqual({
      ok: false,
      error: "not_found",
    });
    expect(ask(`wifi-join-trial ${b64("Casa")} wep visible 0`)).toEqual({
      ok: false,
      error: "bad_request",
    });
  });
});

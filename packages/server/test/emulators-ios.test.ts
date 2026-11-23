// 3.12.2: iOS simulators, with fakes only (no Mac, no Xcode, no serve-sim, no network). Detection
// as a table; `IosHost` against a fake simctl, a fake serve-sim process, a fake MJPEG stream and a
// fake WebSocket (touches as fractions, text as key presses, buttons, rotation, the process
// stopped with the screen); `Devices` with simulators in the list and the same limit of emulators;
// the agents' tools on a simulator (no element list, `.app` folders from the workspace, bundle
// ids, the log); the node's commands; the bridge's guided install with the person's yes.
import { createHash } from "node:crypto";
import { mkdir, mkdtemp, readdir, realpath, rm, writeFile } from "node:fs/promises";
import { tmpdir } from "node:os";
import { join, sep } from "node:path";
import { EmuInstallPlanBody, type EmulatorReport, IOS_BRIDGE_VERSION } from "@redgiant/protocol";
import { afterEach, describe, expect, it } from "vitest";
import { detectEmulators, type EmulatorFacts } from "../src/emulators/detect.js";
import { Devices, type IosDeviceHost } from "../src/emulators/devices.js";
import { FakeDeviceHost } from "../src/emulators/host.js";
import { InstallError } from "../src/emulators/install.js";
import { IosBridgeInstaller, integrityOf } from "../src/emulators/install-ios.js";
import {
  type BridgeProcess,
  IosHost,
  jpegSize,
  MjpegParser,
  parseBridgeInfo,
  type Run,
  TAG,
  touchPlan,
  typeEvents,
  type WsLike,
} from "../src/emulators/ios.js";
import { deviceTools } from "../src/emulators/tools.js";
import { Jobs } from "../src/jobs.js";
import { deviceCommandAllowed } from "../src/nodes/device.js";

const UDID = "11111111-2222-3333-4444-555555555555";
const UDID2 = "AAAAAAAA-BBBB-CCCC-DDDD-EEEEEEEEEEEE";

/** The smallest JPEG a parser can size: SOI, a start-of-frame with the dimensions, EOI. */
const jpeg = (w: number, h: number, tag = 0) =>
  Buffer.from([
    0xff,
    0xd8,
    0xff,
    0xc0,
    0x00,
    0x0b,
    0x08,
    h >> 8,
    h & 255,
    w >> 8,
    w & 255,
    0x01,
    0x01,
    0x11,
    tag,
    0xff,
    0xd9,
  ]);
const part = (b: Buffer) =>
  Buffer.concat([
    Buffer.from(`--frame\r\nContent-Type: image/jpeg\r\nContent-Length: ${b.length}\r\n\r\n`),
    b,
    Buffer.from("\r\n"),
  ]);

// ---- detection ----

const facts = (over: Partial<EmulatorFacts> = {}): EmulatorFacts => ({
  os: "macos",
  arch: "arm64",
  container: false,
  looked: [],
  avds: [],
  accel: { ok: true, kind: "hvf" },
  maxRunning: 2,
  at: "2026-11-23T00:00:00Z",
  ...over,
});
const sim = {
  name: "iPhone 18",
  udid: UDID,
  runtime: "iOS 27.2",
  state: "shutdown" as const,
};

describe("iOS detection", () => {
  const cases: [string, Partial<EmulatorFacts>, string[], boolean][] = [
    ["no Xcode", { ios: { simulators: [] } }, ["xcode"], false],
    ["Intel Mac", { arch: "x64", ios: { xcode: "27.2", simulators: [sim] } }, ["ios-arch"], false],
    ["no bridge yet", { ios: { xcode: "27.2", simulators: [sim] } }, ["ios-bridge"], false],
    [
      "ready",
      {
        ios: {
          xcode: "27.2",
          simulators: [sim],
          bridge: "serve-sim",
          bridgeVersion: "0.1.49",
          bridgeDir: "/x",
        },
      },
      [],
      true,
    ],
  ];
  for (const [name, over, missing, ready] of cases)
    it(name, () => {
      const r = detectEmulators(facts(over));
      expect(r.missing.filter((m) => m.startsWith("ios") || m === "xcode")).toEqual(missing);
      expect(r.ios?.ready).toBe(ready);
    });

  it("is absent on Linux and Windows", () => {
    expect(detectEmulators(facts({ os: "linux" })).ios).toBeUndefined();
    expect(detectEmulators(facts({ os: "windows" })).ios).toBeUndefined();
  });
});

// ---- the bridge's output, the stream and the keys ----

describe("serve-sim's words", () => {
  it("the JSON line gives the addresses, only on this machine", () => {
    const line = JSON.stringify({
      url: "http://127.0.0.1:3200",
      streamUrl: `http://127.0.0.1:3200/helper/${UDID}/stream.mjpeg`,
      wsUrl: `ws://127.0.0.1:3200/helper/${UDID}/ws`,
      port: 3200,
      device: UDID,
    });
    expect(parseBridgeInfo(`starting\n${line}\n`)).toEqual({
      streamUrl: `http://127.0.0.1:3200/helper/${UDID}/stream.mjpeg`,
      wsUrl: `ws://127.0.0.1:3200/helper/${UDID}/ws`,
    });
    expect(parseBridgeInfo("no json here")).toBeUndefined();
    expect(
      parseBridgeInfo(
        JSON.stringify({ streamUrl: "http://evil.example/s", wsUrl: "ws://evil.example/w" }),
      ),
    ).toBeUndefined();
  });

  it("frames are cut by Content-Length, also across chunks", () => {
    const a = jpeg(390, 844, 1);
    const b = jpeg(390, 844, 2);
    const all = Buffer.concat([part(a), part(b)]);
    const p = new MjpegParser();
    const got: Buffer[] = [];
    for (let i = 0; i < all.length; i += 7) got.push(...p.push(all.subarray(i, i + 7)));
    expect(got).toHaveLength(2);
    expect(got[0]?.equals(a)).toBe(true);
    expect(got[1]?.equals(b)).toBe(true);
    expect(jpegSize(a)).toEqual({ width: 390, height: 844 });
    expect(jpegSize(Buffer.from("nope"))).toBeUndefined();
  });

  it("touches are fractions: a tap is begin and end, a swipe moves between", () => {
    expect(touchPlan({ kind: "tap", x: 0.5, y: 0.485 }).map((t) => [t.type, t.x, t.y])).toEqual([
      ["begin", 0.5, 0.485],
      ["end", 0.5, 0.485],
    ]);
    const swipe = touchPlan({ kind: "swipe", x: 0.5, y: 0.8, x2: 0.5, y2: 0.2, ms: 160 });
    expect(swipe[0]?.type).toBe("begin");
    expect(swipe.at(-1)).toMatchObject({ type: "end", x: 0.5, y: 0.2 });
    expect(swipe.slice(1, -1).every((t) => t.type === "move" && t.y < 0.8 && t.y > 0.2)).toBe(true);
    for (const t of swipe) expect(t.x >= 0 && t.x <= 1 && t.y >= 0 && t.y <= 1).toBe(true);
  });

  it("text is key presses with shift around capitals; other characters are refused", () => {
    expect(typeEvents("aB")).toEqual([
      { type: "down", usage: 4 },
      { type: "up", usage: 4 },
      { type: "down", usage: 225 },
      { type: "down", usage: 5 },
      { type: "up", usage: 5 },
      { type: "up", usage: 225 },
    ]);
    expect(() => typeEvents("è")).toThrow(/US-keyboard/);
  });
});

// ---- the host, against fakes ----

class FakeSimctl {
  calls: string[][] = [];
  sims = [
    { name: "iPhone 18", udid: UDID, state: "Shutdown" },
    { name: "iPad Air", udid: UDID2, state: "Booted" },
  ];
  logs = "2026-11-23 app[1] error: boom";
  run: Run = async (file, args) => {
    this.calls.push([file, ...args]);
    if (file !== "xcrun") return { code: 1, out: "", err: "no" };
    const [, sub, ...r] = args;
    if (sub === "list")
      return {
        code: 0,
        out: JSON.stringify({
          devices: {
            "com.apple.CoreSimulator.SimRuntime.iOS-27-2": this.sims.map((s) => ({
              ...s,
              isAvailable: true,
            })),
            "com.apple.CoreSimulator.SimRuntime.watchOS-12-0": [
              { name: "Watch", udid: "W", state: "Shutdown", isAvailable: true },
            ],
          },
        }),
        err: "",
      };
    if (sub === "bootstatus") {
      const s = this.sims.find((x) => x.udid === r[0]);
      if (s) s.state = "Booted";
      return { code: 0, out: "", err: "" };
    }
    if (sub === "shutdown") {
      const s = this.sims.find((x) => x.udid === r[0]);
      if (s) s.state = "Shutdown";
      return { code: 0, out: "", err: "" };
    }
    if (sub === "spawn") return { code: 0, out: this.logs, err: "" };
    return { code: 0, out: "", err: "" };
  };
}

class FakeWs implements WsLike {
  binaryType = "";
  onopen: ((e: unknown) => void) | null = null;
  onmessage: ((e: { data: unknown }) => void) | null = null;
  onclose: ((e: unknown) => void) | null = null;
  onerror: ((e: unknown) => void) | null = null;
  sent: { tag: number; body: Record<string, unknown> }[] = [];
  closed = false;
  constructor(readonly url: string) {
    queueMicrotask(() => this.onopen?.({}));
  }
  send(d: Uint8Array) {
    this.sent.push({
      tag: d[0] as number,
      body: JSON.parse(Buffer.from(d.subarray(1)).toString("utf8")),
    });
  }
  close() {
    this.closed = true;
  }
}

function rig(o: { bridge?: boolean } = {}) {
  const simctl = new FakeSimctl();
  const procs: { udid: string; killed: boolean; script: string }[] = [];
  const sockets: FakeWs[] = [];
  let push: (b: Buffer) => void = () => {};
  let endStream: () => void = () => {};
  const streams: string[] = [];
  const host = new IosHost({
    bridge: async () => (o.bridge === false ? undefined : "/bridge/serve-sim.js"),
    run: simctl.run,
    keyMs: 0,
    fps: 1000,
    spawn: (script, udid) => {
      const rec = { udid, killed: false, script };
      procs.push(rec);
      let out: (t: string) => void = () => {};
      let exit: (c: number | null) => void = () => {};
      const exited = new Promise<number | null>((r) => {
        exit = r;
      });
      const proc: BridgeProcess = {
        onOutput: (cb) => {
          out = cb;
          queueMicrotask(() =>
            out(
              `${JSON.stringify({
                url: "http://127.0.0.1:3200",
                streamUrl: `http://127.0.0.1:3200/helper/${udid}/stream.mjpeg`,
                wsUrl: `ws://127.0.0.1:3200/helper/${udid}/ws`,
                port: 3200,
                device: udid,
              })}\n`,
            ),
          );
        },
        exit: exited,
        kill: () => {
          rec.killed = true;
          exit(null);
        },
      };
      return proc;
    },
    fetch: (async (url: string) => {
      streams.push(url);
      const body = new ReadableStream<Uint8Array>({
        start(c) {
          push = (b) => c.enqueue(b);
          endStream = () => c.close();
        },
      });
      return new Response(body, { status: 200 });
    }) as unknown as typeof fetch,
    webSocket: (url) => {
      const w = new FakeWs(url);
      sockets.push(w);
      return w;
    },
  });
  return {
    host,
    simctl,
    procs,
    sockets,
    streams,
    send: (b: Buffer) => push(part(b)),
    end: () => endStream(),
  };
}

const tick = (ms = 5) => new Promise((r) => setTimeout(r, ms));

describe("IosHost", () => {
  it("lists only iOS simulators and gives the booted ones as devices", async () => {
    const { host } = rig();
    expect((await host.simulators()).map((s) => s.name)).toEqual(["iPhone 18", "iPad Air"]);
    expect(await host.devices()).toEqual([
      {
        serial: UDID2,
        kind: "emulator",
        state: "device",
        platform: "ios",
        model: "iPad Air",
        runtime: "iOS 27.2",
      },
    ]);
  });

  it("boots with bootstatus -b and stops with shutdown; a bad id never reaches simctl", async () => {
    const { host, simctl } = rig();
    expect(await host.boot(UDID)).toBe(UDID);
    expect(simctl.calls.at(-1)).toEqual(["xcrun", "simctl", "bootstatus", UDID, "-b"]);
    await host.stop(UDID);
    expect(simctl.calls.at(-1)).toEqual(["xcrun", "simctl", "shutdown", UDID]);
    const n = simctl.calls.length;
    await expect(host.boot("../etc; rm -rf /")).rejects.toThrow(/simulator/);
    await expect(host.shell("x", ["launch", "a.b"])).rejects.toThrow(/simulator/);
    expect(simctl.calls).toHaveLength(n);
  });

  it("shows the screen's frames, with their size, and stops the bridge when it closes", async () => {
    const r = rig();
    const frames: { width: number; height: number; data: string }[] = [];
    const ended: (string | undefined)[] = [];
    const screen = await r.host.screen(
      UDID2,
      (f) => frames.push(f),
      (e) => ended.push(e),
    );
    expect(r.procs).toEqual([{ udid: UDID2, killed: false, script: "/bridge/serve-sim.js" }]);
    await tick();
    r.send(jpeg(1179, 2556, 7));
    await tick(20);
    expect(frames[0]).toMatchObject({ width: 1179, height: 2556 });
    expect(Buffer.from(frames[0]?.data ?? "", "base64").equals(jpeg(1179, 2556, 7))).toBe(true);
    expect(screen.size()).toEqual({ width: 1179, height: 2556 });
    expect(r.streams[0]).toContain(`/helper/${UDID2}/stream.mjpeg`);
    await screen.close();
    expect(r.procs[0]?.killed).toBe(true);
    expect(ended).toEqual([undefined]);
  });

  it("a second screen on the same simulator shares the one bridge", async () => {
    const r = rig();
    const a = await r.host.screen(
      UDID2,
      () => {},
      () => {},
    );
    const b = await r.host.screen(
      UDID2,
      () => {},
      () => {},
    );
    expect(r.procs).toHaveLength(1);
    await a.close();
    expect(r.procs[0]?.killed).toBe(false);
    await b.close();
    expect(r.procs[0]?.killed).toBe(true);
  });

  it("says when the stream ends, and when the bridge is not installed", async () => {
    const r = rig();
    const ended: (string | undefined)[] = [];
    await r.host.screen(
      UDID2,
      () => {},
      (e) => ended.push(e),
    );
    await tick();
    r.end();
    await tick(20);
    expect(ended[0]).toMatch(/stopped/);
    const none = rig({ bridge: false });
    await expect(
      none.host.screen(
        UDID2,
        () => {},
        () => {},
      ),
    ).rejects.toThrow(/not installed/);
  });

  it("sends touches as fractions, buttons, keys, text and rotation through the WebSocket", async () => {
    const r = rig();
    const screen = await r.host.screen(
      UDID2,
      () => {},
      () => {},
    );
    await screen.input({ kind: "tap", x: 0.5, y: 0.485 });
    await screen.input({ kind: "button", button: "home" });
    await screen.input({ kind: "key", key: "Enter" });
    await screen.input({ kind: "text", text: "a" });
    await screen.input({ kind: "rotate" });
    const ws = r.sockets[0];
    expect(ws?.url).toContain(`/helper/${UDID2}/ws`);
    expect(ws?.sent.map((m) => [m.tag, m.body])).toEqual([
      [TAG.touch, { type: "begin", x: 0.5, y: 0.485 }],
      [TAG.touch, { type: "end", x: 0.5, y: 0.485 }],
      [TAG.button, { button: "home" }],
      [TAG.key, { type: "down", usage: 40 }],
      [TAG.key, { type: "up", usage: 40 }],
      [TAG.key, { type: "down", usage: 4 }],
      [TAG.key, { type: "up", usage: 4 }],
      [TAG.orientation, { orientation: "landscape_left" }],
    ]);
    await expect(screen.input({ kind: "button", button: "back" })).rejects.toThrow(/no back/);
    await screen.close();
    expect(ws?.closed).toBe(true);
  });

  it("runs only the verbs the tools need, with checked arguments", async () => {
    const { host, simctl } = rig();
    await host.shell(UDID2, ["launch", "com.example.App"]);
    expect(simctl.calls.at(-1)).toEqual(["xcrun", "simctl", "launch", UDID2, "com.example.App"]);
    await expect(host.shell(UDID2, ["launch", "com.x; reboot"])).rejects.toThrow(/bundle id/);
    await expect(host.shell(UDID2, ["rm", "-rf", "/"])).rejects.toThrow(/does not run/);
    expect(await host.shell(UDID2, ["logs", "5", "all"])).toContain("boom");
    const spawnCall = simctl.calls.at(-1) ?? [];
    expect(spawnCall.slice(0, 5)).toEqual(["xcrun", "simctl", "spawn", UDID2, "log"]);
    expect(spawnCall).toContain('messageType == "Error" OR messageType == "Fault"');
    await host.shell(UDID2, ["logs", "5", "process", "My App"]);
    expect(simctl.calls.at(-1)).toContain('process == "My App"');
    await expect(host.shell(UDID2, ["logs", "5", "process", 'x" OR 1==1'])).rejects.toThrow(/name/);
    await expect(host.shell(UDID2, ["logs", "999", "all"])).rejects.toThrow(/Minutes/);
  });

  it("installs only an .app folder", async () => {
    const dir = await realpath(await mkdtemp(join(tmpdir(), "rg-ios-")));
    try {
      const app = join(dir, "My.app");
      await mkdir(app);
      await writeFile(join(dir, "File.app"), "x");
      const { host, simctl } = rig();
      expect(await host.install(UDID2, app)).toBe("Success");
      expect(simctl.calls.at(-1)).toEqual(["xcrun", "simctl", "install", UDID2, app]);
      await expect(host.install(UDID2, join(dir, "File.app"))).rejects.toThrow(/folder/);
      await expect(host.install(UDID2, join(dir, "x.apk"))).rejects.toThrow(/\.app/);
    } finally {
      await rm(dir, { recursive: true, force: true });
    }
  });
});

// ---- the same list and limit as Android ----

/** A fake that acts out simulators the way `IosHost` shows them to `Devices`. */
class FakeIos extends FakeDeviceHost implements IosDeviceHost {
  sims = [
    { name: "iPhone 18", udid: UDID, runtime: "iOS 27.2", state: "shutdown" as const },
    { name: "iPad Air", udid: UDID2, runtime: "iOS 27.2", state: "shutdown" as const },
  ];
  override async simulators() {
    return this.sims.map((s) => ({ ...s }));
  }
  override async boot(udid: string) {
    this.calls.push(`boot ${udid}`);
    const s = this.sims.find((x) => x.udid === udid);
    if (s) s.state = "booted";
    return udid;
  }
  override async stop(udid: string) {
    this.calls.push(`stop ${udid}`);
    const s = this.sims.find((x) => x.udid === udid);
    if (s) s.state = "shutdown";
  }
}

describe("simulators in Devices", () => {
  it("appear in the list as ios:<udid>, are booted when opened and stopped by the person", async () => {
    const ios = new FakeIos();
    const d = new Devices({ host: new FakeDeviceHost(), ios, avds: async () => [] });
    const list = await d.list();
    expect(list.filter((x) => x.platform === "ios").map((x) => [x.id, x.state, x.runtime])).toEqual(
      [
        [`ios:${UDID}`, "off", "iOS 27.2"],
        [`ios:${UDID2}`, "off", "iOS 27.2"],
      ],
    );
    const frame = await d.frame(`ios:${UDID}`);
    expect(frame.width).toBe(576);
    expect(ios.calls).toContain(`boot ${UDID}`);
    expect(ios.calls).toContain(`screen ${UDID}`);
    expect((await d.list()).find((x) => x.id === `ios:${UDID}`)).toMatchObject({
      state: "on",
      ours: true,
    });
    await d.stop(`ios:${UDID}`);
    expect(ios.calls).toContain(`stop ${UDID}`);
    expect((await d.list()).find((x) => x.id === `ios:${UDID}`)?.state).toBe("off");
    d.close();
  });

  it("count in the limit of emulators running at once", async () => {
    const ios = new FakeIos();
    // The fake Android host has an emulator running already; the limit is two.
    const d = new Devices({
      host: new FakeDeviceHost(),
      ios,
      avds: async () => [],
      maxRunning: () => 2,
    });
    await d.ensure(`ios:${UDID}`);
    await expect(d.ensure(`ios:${UDID2}`)).rejects.toThrow(/At most 2 emulators/);
    d.close();
  });

  it("a Mac without the bridge or an unknown id is refused in words", async () => {
    const d = new Devices({ host: new FakeDeviceHost(), avds: async () => [] });
    await expect(d.ensure(`ios:${UDID}`)).rejects.toThrow(/not available/);
    const e = new Devices({ host: new FakeDeviceHost(), ios: new FakeIos(), avds: async () => [] });
    await expect(e.ensure("ios:00000000-0000-0000-0000-000000000000")).rejects.toThrow(
      /No such simulator/,
    );
    d.close();
    e.close();
  });
});

// ---- the agents' tools ----

const run = (tools: ReturnType<typeof deviceTools>, name: string, input: unknown) => {
  const t = tools.find((x) => x.def.name === name);
  if (!t) throw new Error(name);
  return (t as unknown as { run: (i: unknown, ctx: unknown) => Promise<unknown> }).run(input, {});
};
const text = (r: unknown) =>
  typeof r === "string" ? r : ((r as { content: string }).content ?? "");

describe("the device tools on a simulator", () => {
  let root = "";
  afterEach(async () => {
    if (root) await rm(root, { recursive: true, force: true });
    root = "";
  });
  async function setup() {
    const ios = new FakeIos();
    ios.answers.launch = "com.example.App: 1234";
    ios.answers.logs = "line one\nline two boom";
    const d = new Devices({ host: new FakeDeviceHost(), ios, avds: async () => [] });
    root = await realpath(await mkdtemp(join(tmpdir(), "rg-ios-tools-")));
    await mkdir(join(root, "build", "My.app"), { recursive: true });
    await writeFile(join(root, "build", "app.apk"), "apk");
    await writeFile(join(root, "build", "file.app"), "not a folder");
    return { ios, d, tools: deviceTools(d, { root, waitMs: 50, vision: true }) };
  }
  const id = `ios:${UDID}`;

  it("list names the simulator; look gives the picture and says there is no element list", async () => {
    const { tools } = await setup();
    expect(text(await run(tools, "device_list", {}))).toContain(
      `${id}: iPhone 18 — iOS simulator (iOS 27.2)`,
    );
    const look = (await run(tools, "device_look", { device: id })) as {
      content: string;
      images: unknown[];
    };
    expect(look.content).toContain("no list of elements");
    expect(look.images).toHaveLength(1);
  });

  it("tap by point works, by number is refused, text waits are refused", async () => {
    const { ios, tools } = await setup();
    await run(tools, "device_tap", { device: id, x: 0.5, y: 0.485 });
    expect(ios.inputs.at(-1)?.event).toEqual({ kind: "tap", x: 0.5, y: 0.485 });
    const byRef = (await run(tools, "device_tap", { device: id, ref: 3 })) as {
      content: string;
      isError: boolean;
    };
    expect(byRef.isError).toBe(true);
    expect(byRef.content).toMatch(/no list of elements/);
    const wait = (await run(tools, "device_wait", { device: id, text: "Hi" })) as {
      isError: boolean;
    };
    expect(wait.isError).toBe(true);
  });

  it("install takes an .app folder from the workspace only", async () => {
    const { ios, tools } = await setup();
    expect(text(await run(tools, "device_install", { device: id, apk: "build/My.app" }))).toContain(
      "Installed build/My.app",
    );
    expect(ios.calls.at(-1)).toBe(`install ${UDID} ${join(root, "build", "My.app")}`);
    for (const apk of ["build/app.apk", "build/file.app", "nowhere/X.app"]) {
      const r = (await run(tools, "device_install", { device: id, apk })) as { isError?: boolean };
      expect(r.isError).toBe(true);
    }
    const outside = (await run(tools, "device_install", {
      device: id,
      apk: join(tmpdir(), "Other.app"),
    })) as { isError?: boolean };
    expect(outside.isError).toBe(true);
    // Android's tool still refuses a folder for an APK on its devices.
    const android = (await run(tools, "device_install", {
      device: "emulator-5554",
      apk: "build/My.app",
    })) as {
      isError?: boolean;
    };
    expect(android.isError).toBe(true);
    expect(sep).toBeTruthy();
  });

  it("launch uses the bundle id; the log filters by bundle id or process", async () => {
    const { ios, tools } = await setup();
    expect(
      text(await run(tools, "device_launch", { device: id, package: "com.example.App" })),
    ).toContain("Started com.example.App");
    expect(ios.calls.at(-1)).toBe(`shell ${UDID} launch com.example.App`);
    const bad = (await run(tools, "device_launch", { device: id, package: "bad id" })) as {
      isError: boolean;
    };
    expect(bad.isError).toBe(true);
    expect(
      text(
        await run(tools, "device_logs", {
          device: id,
          package: "com.example.App",
          contains: "boom",
        }),
      ),
    ).toBe("line two boom");
    expect(ios.calls.at(-1)).toBe(`shell ${UDID} logs 5 subsystem com.example.App`);
    await run(tools, "device_logs", { device: id, process: "My App", minutes: 10 });
    expect(ios.calls.at(-1)).toBe(`shell ${UDID} logs 10 process My App`);
  });
});

// ---- what another machine may ask of a Mac node ----

describe("a Mac node's commands", () => {
  it("allows the tools' iOS verbs and nothing wider", () => {
    expect(deviceCommandAllowed(["launch", "com.example.App"])).toBe(true);
    expect(deviceCommandAllowed(["terminate", "com.example.App"])).toBe(true);
    expect(deviceCommandAllowed(["logs", "5", "all"])).toBe(true);
    expect(deviceCommandAllowed(["logs", "5", "subsystem", "com.example.App"])).toBe(true);
    expect(deviceCommandAllowed(["logs", "5", "process", 'a"b'])).toBe(false);
    expect(deviceCommandAllowed(["launch", "a b"])).toBe(false);
    expect(deviceCommandAllowed(["launch"])).toBe(false);
    expect(deviceCommandAllowed(["spawn", "x"])).toBe(false);
  });
});

// ---- the bridge's guided install ----

const macReport = (
  over: Partial<EmulatorReport["ios"]> & { os?: "macos" | "linux"; arch?: "arm64" | "x64" } = {},
) =>
  ({
    os: over.os ?? "macos",
    arch: over.arch ?? "arm64",
    ios: { xcode: "27.2", simulators: [], ready: false, ...over },
  }) as unknown as EmulatorReport;

describe("installing the iOS bridge", () => {
  const dirs: string[] = [];
  afterEach(async () => {
    for (const d of dirs.splice(0)) await rm(d, { recursive: true, force: true });
  });
  const tgz = Buffer.from("fake tarball bytes");
  const meta = {
    dist: {
      tarball: `https://registry.npmjs.org/serve-sim/-/serve-sim-${IOS_BRIDGE_VERSION}.tgz`,
      integrity: integrityOf(tgz),
      unpackedSize: 1234,
    },
  };
  const net = (o: { meta?: unknown; body?: Buffer; metaStatus?: number } = {}) =>
    (async (url: string) => {
      if (url.endsWith(`/serve-sim/${IOS_BRIDGE_VERSION}`))
        return new Response(JSON.stringify(o.meta ?? meta), { status: o.metaStatus ?? 200 });
      return new Response(new Uint8Array(o.body ?? tgz), {
        status: 200,
        headers: { "content-length": String((o.body ?? tgz).length) },
      });
    }) as unknown as typeof fetch;

  async function setup(
    report: EmulatorReport,
    extra: { npm?: string | undefined; fetch?: typeof fetch } = {},
  ) {
    const dir = join(await mkdtemp(join(tmpdir(), "rg-iosbridge-")), "ios-bridge");
    dirs.push(join(dir, ".."));
    const calls: { file: string; args: string[] }[] = [];
    const jobs = new Jobs();
    const inst = new IosBridgeInstaller({
      jobs,
      machine: { report: async () => report },
      dir,
      fetch: extra.fetch ?? net(),
      npm: async () => ("npm" in extra ? extra.npm : "/node/bin/npm"),
      run: async (file, args) => {
        calls.push({ file, args });
        // What npm would do: serve-sim appears under the prefix.
        const prefix = args[args.indexOf("--prefix") + 1] as string;
        const pkg = join(prefix, "node_modules", "serve-sim", "dist");
        await mkdir(pkg, { recursive: true });
        await writeFile(join(pkg, "serve-sim.js"), "// fake");
        return { code: 0, out: "", err: "" };
      },
      env: () => ({ PATH: "/usr/bin", HOME: "/h", SECRET_KEY: "no" }),
    });
    return { inst, jobs, calls, dir };
  }
  const finish = async (jobs: Jobs, id: string) => {
    for (let i = 0; i < 200; i++) {
      const j = jobs.get("o", id);
      if (j && j.state !== "running") return j;
      await tick(10);
    }
    throw new Error("job did not finish");
  };

  it("explains why not: not a Mac, Intel, no Xcode, no npm, offline, already there", async () => {
    const table: [
      string,
      EmulatorReport,
      { npm?: string | undefined; fetch?: typeof fetch },
      string,
    ][] = [
      ["linux", macReport({ os: "linux" }), {}, "not-mac"],
      ["intel", macReport({ arch: "x64" }), {}, "intel"],
      ["no xcode", macReport({ xcode: undefined as never }), {}, "no-xcode"],
      ["no npm", macReport(), { npm: undefined }, "no-npm"],
      ["offline", macReport(), { fetch: net({ metaStatus: 503 }) }, "offline"],
      [
        "foreign address",
        macReport(),
        {
          fetch: net({
            meta: {
              dist: { tarball: "https://evil.example/x.tgz", integrity: meta.dist.integrity },
            },
          }),
        },
        "offline",
      ],
      [
        "there",
        macReport({ bridge: "serve-sim", bridgeVersion: IOS_BRIDGE_VERSION }),
        {},
        "nothing",
      ],
    ];
    for (const [name, report, extra, blocked] of table) {
      const { inst } = await setup(report, extra);
      const p = await inst.plan("o");
      expect([name, p.blocked, p.planId]).toEqual([name, blocked, undefined]);
    }
  });

  it("a plan that can start names the folder and size; it runs only with its id, once", async () => {
    const { inst, jobs, calls, dir } = await setup(macReport());
    const p = await inst.plan("o");
    expect(p).toMatchObject({
      folder: dir,
      version: IOS_BRIDGE_VERSION,
      bytes: 1234,
      licence: "Apache-2.0",
    });
    expect(p.blocked).toBeUndefined();
    expect(() => inst.start("o", { planId: "nope" })).toThrow(InstallError);
    expect(() => inst.start("other", { planId: p.planId as string })).toThrow(/not known/);
    expect(calls).toHaveLength(0);
    const job = inst.start("o", { planId: p.planId as string });
    const done = await finish(jobs, job.id);
    expect(done.state).toBe("done");
    expect(calls).toHaveLength(1);
    const args = calls[0]?.args ?? [];
    expect(args.slice(0, 1)).toEqual(["install"]);
    expect(args).toContain("--ignore-scripts");
    expect(args[args.indexOf("--prefix") + 1]).toBe(dir);
    expect(args[args.indexOf("--cache") + 1]).toBe(join(dir, "npm-cache"));
    // Nothing is left of the download, and the bridge is where the detector looks.
    expect(await readdir(dir)).not.toContain(".download");
    expect(() => inst.start("o", { planId: p.planId as string })).toThrow(/not known/);
  });

  it("a download that does not match the registry's checksum installs nothing", async () => {
    const { inst, jobs, calls } = await setup(macReport(), {
      fetch: net({ body: Buffer.from("tampered") }),
    });
    const p = await inst.plan("o");
    const job = inst.start("o", { planId: p.planId as string });
    const done = await finish(jobs, job.id);
    expect(done.state).toBe("failed");
    expect(done.error?.message).toMatch(/checksum/);
    expect(calls).toHaveLength(0);
  });

  it("its body is checked like the other install bodies", () => {
    expect(EmuInstallPlanBody.safeParse({}).success).toBe(true);
    expect(createHash("sha512").update(tgz).digest("base64")).toBe(
      meta.dist.integrity.slice("sha512-".length),
    );
  });
});

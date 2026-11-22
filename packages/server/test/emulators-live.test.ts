// 3.11 phase 2: a device live in the Canvas. The pinned scrcpy server (refused when its hash
// differs), JPEGs split out of ffmpeg's stream and at most ~15 a second with the last one kept,
// ffmpeg's arguments; `Devices` against `FakeDeviceHost`: the list (AVDs off, emulators running,
// phones), an AVD started when opened and within the person's limit, one shared screen, who drives
// (the person only after taking control, the agents never while the person has it), turns, the
// emulators Rasgeth started switched off when unused (never the person's own), and the WebSocket
// messages (frames and states; the person's gestures never in the log).
import { mkdtemp, writeFile } from "node:fs/promises";
import { tmpdir } from "node:os";
import { join } from "node:path";
import { afterEach, describe, expect, it, vi } from "vitest";
import { Devices } from "../src/emulators/devices.js";
import { FakeDeviceHost } from "../src/emulators/host.js";
import {
  DECODE_ARGS,
  FrameGate,
  JpegSplitter,
  SCRCPY_JAR,
  SCRCPY_SHA256,
  scrcpyJar,
} from "../src/emulators/jpeg.js";
import { startServer, wsClient } from "./helpers.js";

const jpeg = (n: number) => Buffer.from([0xff, 0xd8, n, 0x00, 0xff, 0xd9]);

describe("the screen's pieces", () => {
  it("carries scrcpy-server 3.3.3 and refuses another file", async () => {
    expect((await scrcpyJar()).length).toBe(90164);
    expect(SCRCPY_SHA256).toMatch(/^7e70323b/);
    const dir = await mkdtemp(join(tmpdir(), "rg-jar-"));
    await writeFile(join(dir, "x"), "not the jar");
    await expect(scrcpyJar(join(dir, "x"))).rejects.toThrow(/SHA-256/);
    expect(SCRCPY_JAR).toMatch(/vendor[\\/]scrcpy[\\/]scrcpy-server-v3\.3\.3$/);
  });

  it("splits JPEGs across chunks", () => {
    const s = new JpegSplitter();
    const two = Buffer.concat([jpeg(1), jpeg(2)]);
    expect(s.push(two.subarray(0, 8)).map((b) => b[2])).toEqual([1]);
    expect(s.push(two.subarray(8)).map((b) => b[2])).toEqual([2]);
    expect(s.push(Buffer.from([0x00, 0x01]))).toEqual([]);
  });

  it("sends at most one frame per gap and always the last one", () => {
    vi.useFakeTimers();
    try {
      let t = 0;
      const sent: string[] = [];
      const g = new FrameGate(
        (f) => sent.push(f.data),
        66,
        () => t,
      );
      g.push({ data: "a", width: 1, height: 1 });
      t = 10;
      g.push({ data: "b", width: 1, height: 1 });
      t = 20;
      g.push({ data: "c", width: 1, height: 1 });
      expect(sent).toEqual(["a"]);
      t = 66;
      vi.advanceTimersByTime(66);
      expect(sent).toEqual(["a", "c"]);
      g.close();
    } finally {
      vi.useRealTimers();
    }
  });

  it("asks ffmpeg for every frame at once, without the flag that held them all (phase 2)", () => {
    expect(DECODE_ARGS).toContain("passthrough");
    expect(DECODE_ARGS).not.toContain("nobuffer");
    expect(DECODE_ARGS.join(" ")).toContain("-threads 1");
  });
});

describe("devices in the Canvas", () => {
  const make = (max = 2) => {
    const host = new FakeDeviceHost();
    let now = 1_000_000;
    const d = new Devices({
      host,
      avds: async () => ["Pixel_8", "Tablet"],
      maxRunning: () => max,
      now: () => now,
    });
    return { host, d, later: (ms: number) => (now += ms) };
  };

  it("lists AVDs off, emulators running and phones by stable ids", async () => {
    const { d } = make();
    const list = await d.list();
    expect(list.map((x) => [x.id, x.kind, x.state])).toEqual([
      ["avd:Pixel_8", "emulator", "on"],
      ["R58N12ABCDE", "phone", "on"],
      ["avd:Tablet", "emulator", "off"],
    ]);
    d.close();
  });

  it("two emulators of the same AVD: the second one goes by its serial", async () => {
    const { d, host } = make();
    host.attached.push({
      serial: "emulator-5556",
      kind: "emulator",
      state: "device",
      avd: "Pixel_8",
    });
    expect((await d.list()).map((x) => x.id)).toEqual([
      "avd:Pixel_8",
      "R58N12ABCDE",
      "emulator-5556",
      "avd:Tablet",
    ]);
    d.close();
  });

  it("starts an AVD when it is opened, within the limit", async () => {
    const { d, host } = make(2);
    const states: string[] = [];
    await d.watch("avd:Tablet", (e) => e.type === "state" && states.push(e.state));
    expect(host.calls).toContain("boot Tablet");
    expect(states).toEqual(["starting", "on", "on"]);
    expect((await d.list()).find((x) => x.id === "avd:Tablet")).toMatchObject({
      ours: true,
      state: "on",
    });
    const full = make(1);
    await expect(full.d.ensureOn("avd:Tablet")).rejects.toThrow(/At most 1 emulators/);
    await expect(d.ensureOn("avd:Nope")).rejects.toThrow(/no AVD named/);
    d.close();
    full.d.close();
  });

  it("shares one screen; the person drives only after taking control, the agents never then", async () => {
    const { d, host } = make();
    const a: string[] = [];
    const b: string[] = [];
    const offA = await d.watch("avd:Pixel_8", (e) => e.type === "frame" && a.push(e.frame.data));
    await d.watch("avd:Pixel_8", (e) => e.type === "frame" && b.push(e.frame.data));
    host.frame("emulator-5554", "CCCC");
    expect(a.at(-1)).toBe("CCCC");
    expect(b.at(-1)).toBe("CCCC");
    expect(host.calls.filter((c) => c.startsWith("screen"))).toHaveLength(1);
    offA();
    await expect(d.input("avd:Pixel_8", { kind: "tap", x: 0.5, y: 0.5 }, "person")).rejects.toThrow(
      /Take control/,
    );
    await d.input("avd:Pixel_8", { kind: "tap", x: 0.5, y: 0.5 }, "agents");
    d.setControl("avd:Pixel_8", "person");
    await d.input("avd:Pixel_8", { kind: "text", text: "ciao" }, "person");
    await expect(d.input("avd:Pixel_8", { kind: "tap", x: 0.1, y: 0.1 }, "agents")).rejects.toThrow(
      /person has control/,
    );
    expect(host.inputs.map((i) => i.event.kind)).toEqual(["tap", "text"]);
    expect((await d.frame("avd:Pixel_8")).data).toBe("CCCC");
    d.close();
  });

  it("agents take turns on a device", async () => {
    const { d } = make();
    const order: number[] = [];
    await Promise.all([
      d.exclusive("x", async () => {
        await new Promise((r) => setTimeout(r, 20));
        order.push(1);
      }),
      d.exclusive("x", async () => {
        order.push(2);
      }),
    ]);
    expect(order).toEqual([1, 2]);
    d.close();
  });

  it("switches off, when unused, only the emulators it started; screens close when nobody looks", async () => {
    const { d, host, later } = make();
    const off = await d.watch("avd:Tablet", () => {});
    off();
    later(2 * 60_000);
    await d.sweep();
    expect(host.calls).toContain("close emulator-5556");
    expect(host.calls).not.toContain("stop emulator-5556");
    later(20 * 60_000);
    await d.sweep();
    expect(host.calls).toContain("stop emulator-5556");
    expect(host.calls).not.toContain("stop emulator-5554");
    await expect(d.stop("R58N12ABCDE")).rejects.toThrow(/phone is not switched off/);
    d.close();
  });
});

describe("the device's messages", () => {
  const open: { close: () => Promise<unknown> }[] = [];
  afterEach(async () => {
    for (const s of open.splice(0)) await s.close().catch(() => {});
  });

  it("H.264 to a page that decodes it (phase 7): a key frame asked, JPEG until the first packet", async () => {
    const host = new FakeDeviceHost();
    const s = await startServer([], {}, { deviceHost: host });
    open.push(s);
    const jpeg = await wsClient(s.url);
    jpeg.send({ type: "device.watch", id: "avd:Pixel_8" });
    await jpeg.waitFor("device.frame", (m) => m.id === "avd:Pixel_8");
    const c = await wsClient(s.url);
    c.send({ type: "device.watch", id: "avd:Pixel_8", format: "h264" });
    await c.waitFor("device.video", (m) => m.key && m.data === "S0VZ");
    expect(host.calls).toContain("keyframe emulator-5554");
    host.packet("emulator-5554", { data: "REVM" });
    await c.waitFor("device.video", (m) => m.data === "REVM");
    host.frame("emulator-5554", "TkVX");
    await jpeg.waitFor("device.frame", (m) => m.data === "TkVX");
    await new Promise((r) => setTimeout(r, 100));
    expect(c.messages.some((m) => m.type === "device.frame" && m.data === "TkVX")).toBe(false);
    expect(jpeg.messages.some((m) => m.type === "device.video")).toBe(false);
    c.close();
    jpeg.close();
  });

  it("frames and states to the page; the person's gestures reach the device, never the log", async () => {
    const host = new FakeDeviceHost();
    const s = await startServer([], {}, { deviceHost: host });
    open.push(s);
    const c = await wsClient(s.url);
    c.send({ type: "device.watch", id: "avd:Pixel_8" });
    const st = await c.waitFor("device.state", (m) => m.id === "avd:Pixel_8" && m.state === "on");
    expect(st.control).toBe("agents");
    await c.waitFor("device.frame", (m) => m.id === "avd:Pixel_8");
    c.send({ type: "device.input", id: "avd:Pixel_8", event: { kind: "tap", x: 0.2, y: 0.3 } });
    await c.waitFor("error", (m) => JSON.stringify(m).includes("Take control"));
    c.send({ type: "device.control", id: "avd:Pixel_8", take: true });
    await c.waitFor("device.state", (m) => m.control === "person");
    c.send({ type: "device.input", id: "avd:Pixel_8", event: { kind: "text", text: "segreto" } });
    await vi.waitFor(() => expect(host.inputs.map((i) => i.event.kind)).toContain("text"));
    const list = await s.api<{ devices: { id: string }[] }>("GET", "/api/emulators/devices");
    expect(list.body.devices.map((d) => d.id)).toContain("R58N12ABCDE");
    expect(JSON.stringify(await s.core.db.query("SELECT * FROM rg_events"))).not.toContain(
      "segreto",
    );
    c.send({ type: "device.unwatch", id: "avd:Pixel_8" });
    c.close();
  });
});

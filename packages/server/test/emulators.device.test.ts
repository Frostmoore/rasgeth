// 3.11 phases 4 and 7 with real Android emulators (`REDGIANT_DEVICE_TESTS=1 pnpm test:device`):
// adb's server on ANDROID_ADB_SERVER_PORT (this machine's, or a tunnel to another one's) with at
// least one emulator running (two for the «several at once» case), ffmpeg in REDGIANT_DEVICE_FFMPEG.
// Two real servers in this process: «rig» drives the emulators with the real AndroidHost, «severino»
// uses them through the node system. Numbers are printed for the plan.
import { spawn } from "node:child_process";
import { appendFileSync } from "node:fs";
import { writeFile } from "node:fs/promises";
import { join } from "node:path";
import type {
  EmuDeviceView,
  NodesState,
  PairCode,
  PendingPair,
  ServerMessage,
} from "@redgiant/protocol";
import { afterAll, describe, expect, it } from "vitest";
import { AndroidHost } from "../src/emulators/android.js";
import { FakeDeviceHost } from "../src/emulators/host.js";
import { startServer, wsClient } from "./helpers.js";

const on = process.env.REDGIANT_DEVICE_TESTS === "1";
const FF = process.env.REDGIANT_DEVICE_FFMPEG ?? "ffmpeg";
const OUT = process.env.REDGIANT_DEVICE_OUT;
const port = Number(process.env.ANDROID_ADB_SERVER_PORT) || 5037;
type Server = Awaited<ReturnType<typeof startServer>>;
const open: Server[] = [];
afterAll(async () => {
  for (const s of open.reverse()) await s.close().catch(() => {});
});
const sleep = (ms: number) => new Promise((r) => setTimeout(r, ms));
/** The numbers, on the console and in OUT/numbers.txt (vitest keeps passing tests' console quiet). */
const note = (...a: unknown[]) => {
  const line = a.map((x) => (typeof x === "string" ? x : JSON.stringify(x))).join(" ");
  console.log(line);
  if (OUT) appendFileSync(join(OUT, "numbers.txt"), `${line}\n`);
};
async function until<T>(
  f: () => Promise<T | undefined | false> | T | undefined | false,
  ms = 20_000,
) {
  const end = Date.now() + ms;
  for (;;) {
    const v = await f();
    if (v) return v as T;
    if (Date.now() > end) throw new Error("timed out waiting");
    await sleep(25);
  }
}
const real = () => new AndroidHost({ tools: async () => ({}), ffmpeg: async () => FF, port });

async function pairUp(principal: Server, node: Server) {
  const st = async (s: Server) => (await s.api<NodesState>("GET", "/api/nodes")).body;
  const code = (await principal.api<PairCode>("POST", "/api/nodes/code")).body;
  await node.api<PendingPair>("POST", "/api/nodes/pair", {
    address: principal.url,
    code: code.code,
  });
  const p = await st(principal);
  const n = await st(node);
  await principal.api("POST", "/api/nodes/confirm", {
    fingerprint: (p.pending[0] as PendingPair).fingerprint,
    name: "Rig",
  });
  await node.api("POST", "/api/nodes/confirm", {
    fingerprint: (n.pending[0] as PendingPair).fingerprint,
    rights: ["use"],
  });
  const fp = n.self.fingerprint as string;
  await until(() => principal.core.nodes.isOnline(fp));
  await principal.core.nodes.poll("me", fp);
  return fp;
}

describe.skipIf(!on)("real emulators (3.11 phases 4 and 7)", () => {
  it("through a node: listed, watched in pieces, driven, the agents' commands", async () => {
    const here = new FakeDeviceHost();
    here.attached = [];
    const severino = await startServer(
      [{ text: "OK" }],
      {},
      {
        deviceHost: here,
        nodes: { hostName: "severino", reconnectMs: [60], waitMs: 5000, pollMs: 0 },
      },
    );
    open.push(severino);
    const rig = await startServer(
      [{ text: "OK" }],
      {},
      {
        deviceHost: real(),
        nodes: { hostName: "rig", reconnectMs: [60], waitMs: 5000, pollMs: 0 },
      },
    );
    open.push(rig);
    const fp = await pairUp(severino, rig);
    const list = (await severino.api<{ devices: EmuDeviceView[] }>("GET", "/api/emulators/devices"))
      .body.devices;
    const ems = list.filter(
      (d) => d.kind === "emulator" && d.state === "on" && d.id.endsWith(`@${fp}`),
    );
    note(
      "node devices:",
      ems.map((d) => d.id),
    );
    expect(ems.length).toBeGreaterThan(0);
    const id = (ems[0] as EmuDeviceView).id;
    const c = await wsClient(severino.url);
    const t0 = performance.now();
    c.send({ type: "device.watch", id });
    const first = await c.waitFor("device.frame", (m) => m.id === id, 60_000);
    note(
      "node: first frame",
      Math.round(performance.now() - t0),
      "ms",
      first.width,
      "x",
      first.height,
      Math.round((first.data.length * 3) / 4 / 1024),
      "KB",
    );
    c.send({ type: "device.control", id, take: true });
    await c.waitFor("device.state", (m) => m.id === id && m.control === "person");
    c.send({ type: "device.input", id, event: { kind: "button", button: "home" } });
    await sleep(1500);
    // Tap → first new frame, through the node (quiet screen first).
    const lat: number[] = [];
    const count = () => c.messages.filter((m) => m.type === "device.frame").length;
    for (let i = 0; i < 8; i++) {
      let last = count();
      for (let q = 0; q < 40; q++) {
        await sleep(100);
        if (count() === last) break;
        last = count();
      }
      const before = count();
      const s = performance.now();
      c.send({
        type: "device.input",
        id,
        event:
          i % 2
            ? { kind: "button", button: "home" }
            : { kind: "swipe", x: 0.5, y: 0.8, x2: 0.5, y2: 0.3, ms: 150 },
      });
      await until(() => count() > before, 5000).catch(() => undefined);
      lat.push(Math.round(performance.now() - s));
    }
    lat.sort((a, b) => a - b);
    note("node: gesture → frame ms", lat, "median", lat[Math.floor(lat.length / 2)]);
    const f0 = count();
    const s0 = performance.now();
    for (let i = 0; i < 4; i++) {
      c.send({
        type: "device.input",
        id,
        event: { kind: "swipe", x: 0.5, y: 0.8, x2: 0.5, y2: 0.3, ms: 250 },
      });
      await sleep(400);
      c.send({ type: "device.input", id, event: { kind: "button", button: "home" } });
      await sleep(400);
    }
    const secs = (performance.now() - s0) / 1000;
    note("node: moving fps", ((count() - f0) / secs).toFixed(1));
    const hub = severino.core.deviceHub.of("me");
    const t1 = performance.now();
    const xml = await hub.shell(id, ["uiautomator", "dump", "/dev/tty"]);
    note(
      "node: uiautomator through the node",
      Math.round(performance.now() - t1),
      "ms",
      xml.length,
      "chars",
    );
    expect(xml).toContain("<hierarchy");
    await expect(hub.shell(id, ["sh", "-c", "id"])).rejects.toThrow(/does not run/);
    if (OUT) {
      const last = c.messages
        .filter(
          (m): m is Extract<ServerMessage, { type: "device.frame" }> => m.type === "device.frame",
        )
        .at(-1);
      if (last) await writeFile(join(OUT, "30-via-node.jpg"), Buffer.from(last.data, "base64"));
    }
    c.send({ type: "device.control", id, take: false });
    c.send({ type: "device.unwatch", id });
    c.close();
  });

  it("several at once, and H.264 for a page that decodes it", async () => {
    const s = await startServer([{ text: "OK" }], {}, { deviceHost: real() });
    open.push(s);
    const list = (await s.api<{ devices: EmuDeviceView[] }>("GET", "/api/emulators/devices")).body
      .devices;
    const ems = list.filter((d) => d.kind === "emulator" && d.state === "on");
    note(
      "here:",
      ems.map((d) => d.id),
    );
    const c = await wsClient(s.url);
    for (const d of ems) c.send({ type: "device.watch", id: d.id });
    for (const d of ems) await c.waitFor("device.frame", (m) => m.id === d.id, 60_000);
    note("several at once: frames from", ems.length, "devices");
    expect(ems.length).toBeGreaterThan(0);
    const id = (ems[0] as EmuDeviceView).id;
    const v = await wsClient(s.url);
    const t0 = performance.now();
    v.send({ type: "device.watch", id, format: "h264" });
    const key = await v.waitFor("device.video", (m) => m.id === id && m.key && !m.config, 20_000);
    note(
      "h264: key frame after",
      Math.round(performance.now() - t0),
      "ms",
      key.width,
      "x",
      key.height,
    );
    await sleep(3000);
    const packets = v.messages.filter(
      (m): m is Extract<ServerMessage, { type: "device.video" }> => m.type === "device.video",
    );
    const cfg = packets.findIndex((p) => p.config);
    expect(cfg).toBeGreaterThanOrEqual(0);
    const stream = Buffer.concat(packets.slice(cfg).map((p) => Buffer.from(p.data, "base64")));
    note("h264:", packets.length, "packets,", Math.round(stream.length / 1024), "KB in 3 s");
    // ffmpeg decodes what a page would.
    const frames = await new Promise<number>((resolve) => {
      const p = spawn(
        FF,
        ["-hide_banner", "-loglevel", "error", "-f", "h264", "-i", "pipe:0", "-f", "null", "-"],
        {
          stdio: ["pipe", "ignore", "pipe"],
        },
      );
      let err = "";
      p.stderr.on("data", (d) => {
        err += d;
      });
      p.on("exit", () => resolve(err.includes("error") ? -1 : 1));
      p.stdin.end(stream);
    });
    expect(frames).toBe(1);
    if (OUT) await writeFile(join(OUT, "31-h264.h264"), stream);
    c.close();
    v.close();
  });
});

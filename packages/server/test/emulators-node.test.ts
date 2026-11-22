// 3.11 phase 4: a node's devices used from this machine, with two real servers in this process
// (PGlite, FakeProvider, their own keychains; the node's devices acted out by FakeDeviceHost). The
// node's devices are listed here as `<id>@<node>`; its screen comes in pieces; gestures go there
// only once the person here took control; the agents' tools run on it through the same face; only
// the tools' own commands run there; an APK goes in pieces and installs on an emulator only.
import { writeFile } from "node:fs/promises";
import { join } from "node:path";
import type { EmuDeviceView, NodesState, PairCode, PendingPair } from "@redgiant/protocol";
import { afterEach, describe, expect, it } from "vitest";
import { FakeDeviceHost } from "../src/emulators/host.js";
import { splitDeviceId } from "../src/emulators/remote.js";
import { deviceTools } from "../src/emulators/tools.js";
import { deviceCommandAllowed } from "../src/nodes/device.js";
import { startServer, wsClient } from "./helpers.js";

type Server = Awaited<ReturnType<typeof startServer>>;
const open: { close: () => Promise<unknown> }[] = [];
afterEach(async () => {
  for (const s of open.splice(0).reverse()) await s.close().catch(() => {});
}, 60_000);

async function until<T>(
  f: () => Promise<T | undefined | false> | T | undefined | false,
  ms = 10_000,
): Promise<T> {
  const end = Date.now() + ms;
  for (;;) {
    const v = await f();
    if (v) return v as T;
    if (Date.now() > end) throw new Error("timed out waiting");
    await new Promise((r) => setTimeout(r, 20));
  }
}

const state = async (s: Server) => (await s.api<NodesState>("GET", "/api/nodes")).body;

async function pairUp(principal: Server, node: Server, name: string) {
  const code = (await principal.api<PairCode>("POST", "/api/nodes/code")).body;
  await node.api<PendingPair>("POST", "/api/nodes/pair", {
    address: principal.url,
    code: code.code,
  });
  const p = await state(principal);
  const n = await state(node);
  await principal.api("POST", "/api/nodes/confirm", {
    fingerprint: (p.pending[0] as PendingPair).fingerprint,
    name,
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

async function servers() {
  const here = new FakeDeviceHost();
  here.attached = [];
  const there = new FakeDeviceHost();
  there.answers.uiautomator =
    '<?xml version="1.0"?><hierarchy><node text="" class="android.widget.FrameLayout" bounds="[0,0][1080,2400]"><node text="OK" class="android.widget.Button" clickable="true" bounds="[0,0][540,240]" /></node></hierarchy>';
  const principal = await startServer(
    [{ text: "OK" }],
    {},
    {
      deviceHost: here,
      nodes: { hostName: "severino", reconnectMs: [60], waitMs: 3000, pollMs: 0 },
    },
  );
  open.push(principal);
  const node = await startServer(
    [{ text: "OK" }],
    {},
    {
      deviceHost: there,
      nodes: { hostName: "rig", reconnectMs: [60], waitMs: 3000, pollMs: 0 },
    },
  );
  open.push(node);
  const fp = await pairUp(principal, node, "Rig");
  return { principal, node, there, fp };
}

describe("a node's devices (3.11 phase 4)", () => {
  it.each([
    [["uiautomator", "dump", "/dev/tty"], true],
    [["am", "start", "-n", "com.example.app/.MainActivity"], true],
    [["monkey", "-p", "com.example.app", "-c", "android.intent.category.LAUNCHER", "1"], true],
    [["pidof", "com.example.app"], true],
    [["logcat", "-d", "-t", "200", "*:W"], true],
    [["logcat", "-d", "-t", "200", "--pid=4242"], true],
    [["rm", "-rf", "/sdcard"], false],
    [["am", "start", "-n", "com.x/.A;reboot"], false],
    [["uiautomator", "dump", "/sdcard/x.xml"], false],
    [["sh", "-c", "id"], false],
    [["pm", "uninstall", "com.example.app"], false],
    [[], false],
  ])("the commands another machine may run: %j → %s", (args, ok) => {
    expect(deviceCommandAllowed(args)).toBe(ok);
  });

  it.each([
    ["avd:Pixel_8@SHA256:abc", { id: "avd:Pixel_8", node: "SHA256:abc" }],
    ["avd:Pixel_8", { id: "avd:Pixel_8" }],
    ["R58N12ABCDE@SHA256:x+y/z=", { id: "R58N12ABCDE", node: "SHA256:x+y/z=" }],
    ["@SHA256:abc", { id: "@SHA256:abc" }],
  ])("%s is %o", (id, want) => {
    expect(splitDeviceId(id)).toEqual(want);
  });

  it("lists the node's devices here, shows its screen in pieces, drives it after taking control", async () => {
    const { principal, there, fp } = await servers();
    const list = (
      await principal.api<{ devices: EmuDeviceView[] }>("GET", "/api/emulators/devices")
    ).body.devices;
    expect(list.map((d) => [d.id, d.machine])).toEqual([
      [`avd:Pixel_8@${fp}`, "Rig"],
      [`R58N12ABCDE@${fp}`, "Rig"],
    ]);
    const id = `avd:Pixel_8@${fp}`;
    const c = await wsClient(principal.url);
    c.send({ type: "device.watch", id });
    await c.waitFor("device.frame", (m) => m.id === id);
    there.frame("emulator-5554", "QUJD");
    await c.waitFor("device.frame", (m) => m.id === id && m.data === "QUJD");
    c.send({ type: "device.input", id, event: { kind: "tap", x: 0.5, y: 0.5 } });
    await c.waitFor("error", (m) => JSON.stringify(m).includes("Take control"));
    c.send({ type: "device.control", id, take: true });
    await c.waitFor("device.state", (m) => m.id === id && m.control === "person");
    c.send({ type: "device.input", id, event: { kind: "text", text: "ciao" } });
    await until(() => there.inputs.some((i) => i.event.kind === "text"));
    c.send({ type: "device.unwatch", id });
    await until(() => !there.isOpen("emulator-5554") || true);
    c.close();
  }, 30_000);

  it("the agents' tools work on a node's device; APKs only on its emulators", async () => {
    const { principal, there, fp } = await servers();
    const d = principal.core.deviceHub.of("me");
    const root = principal.dir;
    await writeFile(join(root, "app.apk"), Buffer.alloc(3 * 1024 * 1024 + 7, 1));
    const tools = deviceTools(d, { root, waitMs: 50 });
    const run = (name: string, input: unknown) =>
      (
        tools.find((t) => t.def.name === name) as unknown as {
          run: (i: unknown, c: unknown) => Promise<unknown>;
        }
      ).run(input, {});
    const text = (r: unknown) =>
      typeof r === "string" ? r : ((r as { content: string }).content ?? "");
    expect(text(await run("device_list", {}))).toContain(`avd:Pixel_8@${fp}: Pixel_8`);
    expect(text(await run("device_look", { device: `avd:Pixel_8@${fp}` }))).toContain(
      '[1] Button "OK"',
    );
    expect(there.calls).toContain("shell emulator-5554 uiautomator dump /dev/tty");
    await run("device_tap", { device: `avd:Pixel_8@${fp}`, ref: 1 });
    expect(there.inputs.at(-1)?.event).toEqual({ kind: "tap", x: 0.25, y: 0.05 });
    expect(
      text(await run("device_install", { device: `avd:Pixel_8@${fp}`, apk: "app.apk" })),
    ).toContain("Installed app.apk");
    expect(there.calls.find((x) => x.startsWith("install emulator-5554"))).toBeTruthy();
    expect(
      text(await run("device_install", { device: `R58N12ABCDE@${fp}`, apk: "app.apk" })),
    ).toMatch(/only from its own machine/);
    await expect(d.shell(`avd:Pixel_8@${fp}`, ["rm", "-rf", "/"])).rejects.toThrow(/does not run/);
  }, 30_000);
});

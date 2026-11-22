// 3.11 phase 3: the agents' device tools against `FakeDeviceHost`. uiautomator's tree read as
// numbered elements (kept until the screen changes), taps by number or point, typing refused in a
// password field, APKs only from the workspace, apps launched by package, logs by package, waiting
// for a text, and the agents waiting while the person has control. The `devices` kit is off by
// default and its tools are in the catalog.
import { mkdir, mkdtemp, writeFile } from "node:fs/promises";
import { tmpdir } from "node:os";
import { join } from "node:path";
import { TOOL_CATALOG, TOOL_KITS } from "@redgiant/protocol";
import { describe, expect, it } from "vitest";
import { Devices } from "../src/emulators/devices.js";
import { FakeDeviceHost } from "../src/emulators/host.js";
import { describeUi, deviceTools, parseUiTree } from "../src/emulators/tools.js";
import { KIT_LINES } from "../src/request-tool.js";

const DUMP = `UI hierchary dumped to: /dev/tty
<?xml version='1.0' encoding='UTF-8' standalone='yes' ?><hierarchy rotation="0"><node index="0" text="" resource-id="" class="android.widget.FrameLayout" clickable="false" bounds="[0,0][1080,2400]"><node index="0" text="" resource-id="com.x:id/user" class="android.widget.EditText" clickable="true" focused="true" password="false" bounds="[0,100][1080,200]" /><node index="1" text="" resource-id="com.x:id/pass" class="android.widget.EditText" clickable="true" focused="false" password="true" bounds="[0,220][1080,320]" /><node index="2" text="Sign in" resource-id="com.x:id/go" class="android.widget.Button" clickable="true" bounds="[0,400][540,520]" /><node index="3" text="" content-desc="Settings" class="android.widget.ImageView" clickable="true" bounds="[980,0][1080,100]" /><node index="4" text="" class="android.view.View" clickable="false" bounds="[0,600][1080,700]" /></node></hierarchy>`;

const run = (tools: ReturnType<typeof deviceTools>, name: string, input: unknown) => {
  const t = tools.find((x) => x.def.name === name);
  if (!t) throw new Error(name);
  return (t as unknown as { run: (i: unknown, ctx: unknown) => Promise<unknown> }).run(input, {});
};
const text = (r: unknown) =>
  typeof r === "string" ? r : ((r as { content: string }).content ?? "");

async function setup(o: { vision?: boolean } = {}) {
  const host = new FakeDeviceHost();
  host.answers.uiautomator = DUMP;
  const d = new Devices({ host, avds: async () => ["Pixel_8"] });
  const root = await mkdtemp(join(tmpdir(), "rg-dev-tools-"));
  await mkdir(join(root, "build"), { recursive: true });
  await writeFile(join(root, "build", "app.apk"), "apk");
  const tools = deviceTools(d, {
    root,
    waitMs: 50,
    ...(o.vision !== undefined && { vision: o.vision }),
  });
  return { host, d, root, tools };
}

describe("the screen's elements", () => {
  it("are numbered with their centres; empty views are left out", () => {
    const nodes = parseUiTree(DUMP.slice(DUMP.indexOf("<?xml")));
    expect(nodes.map((n) => [n.ref, n.cls, n.text || n.desc, n.x, n.y])).toEqual([
      [1, "EditText", "", 0.5, 0.063],
      [2, "EditText", "", 0.5, 0.113],
      [3, "Button", "Sign in", 0.25, 0.192],
      [4, "ImageView", "Settings", 0.954, 0.021],
    ]);
    const words = describeUi(nodes);
    expect(words).toContain('[3] Button "Sign in" (id go)');
    expect(words).toContain("(password field)");
    expect(words).toContain("[1] EditText (id user) focused");
  });
});

describe("the device tools", () => {
  it("are a kit that starts off, in the catalog", () => {
    expect(TOOL_KITS).toContain("devices");
    expect(TOOL_CATALOG.find((e) => e.id === "device")).toMatchObject({
      prefix: "device_",
      kit: "devices",
    });
    expect(KIT_LINES.devices).toMatch(/emulators/);
  });

  it("list, look (with a picture for a model that sees), tap by number, look again", async () => {
    const { host, d, tools } = await setup({ vision: true });
    expect(text(await run(tools, "device_list", {}))).toContain(
      "avd:Pixel_8: Pixel_8 — emulator, on",
    );
    const look = (await run(tools, "device_look", { device: "avd:Pixel_8" })) as {
      content: string;
      images: unknown[];
    };
    expect(look.content).toContain('[3] Button "Sign in"');
    expect(look.images).toHaveLength(1);
    // The tree is kept until a new frame comes.
    await run(tools, "device_look", { device: "avd:Pixel_8" });
    expect(host.calls.filter((c) => c.includes("uiautomator"))).toHaveLength(1);
    expect(text(await run(tools, "device_tap", { device: "avd:Pixel_8", ref: 3 }))).toContain(
      'Tapped [3] "Sign in"',
    );
    expect(host.inputs.at(-1)?.event).toEqual({ kind: "tap", x: 0.25, y: 0.192 });
    host.frame("emulator-5554");
    await run(tools, "device_look", { device: "avd:Pixel_8" });
    expect(host.calls.filter((c) => c.includes("uiautomator"))).toHaveLength(2);
    expect(text(await run(tools, "device_tap", { device: "avd:Pixel_8", ref: 99 }))).toMatch(
      /No element \[99\]/,
    );
    await run(tools, "device_tap", { device: "avd:Pixel_8", x: 0.1, y: 0.9, long: true });
    expect(host.inputs.at(-1)?.event).toEqual({ kind: "long", x: 0.1, y: 0.9 });
    d.close();
  });

  it("types into the focused field, never into a password field", async () => {
    const { host, d, tools } = await setup();
    expect(
      text(await run(tools, "device_type", { device: "avd:Pixel_8", text: "ann", submit: true })),
    ).toContain("Typed 3 characters and pressed Enter");
    expect(host.inputs.slice(-2).map((i) => i.event)).toEqual([
      { kind: "text", text: "ann" },
      { kind: "key", key: "Enter" },
    ]);
    const refused = await run(tools, "device_type", {
      device: "avd:Pixel_8",
      text: "hunter2",
      ref: 2,
    });
    expect(text(refused)).toMatch(/password field/);
    expect(host.inputs.some((i) => i.event.kind === "text" && i.event.text === "hunter2")).toBe(
      false,
    );
    d.close();
  });

  it("swipes, presses, turns", async () => {
    const { host, d, tools } = await setup();
    await run(tools, "device_swipe", { device: "avd:Pixel_8", direction: "up" });
    await run(tools, "device_press", { device: "avd:Pixel_8", key: "back" });
    await run(tools, "device_press", { device: "avd:Pixel_8", key: "Enter" });
    await run(tools, "device_rotate", { device: "avd:Pixel_8" });
    expect(host.inputs.map((i) => i.event.kind)).toEqual(["swipe", "button", "key", "rotate"]);
    d.close();
  });

  it("installs an APK from the workspace only, launches by package, reads logs", async () => {
    const { host, d, root, tools } = await setup();
    expect(
      text(await run(tools, "device_install", { device: "avd:Pixel_8", apk: "build/app.apk" })),
    ).toBe("Installed build/app.apk on avd:Pixel_8.");
    expect(host.calls.at(-1)).toBe(`install emulator-5554 ${join(root, "build", "app.apk")}`);
    expect(
      text(await run(tools, "device_install", { device: "avd:Pixel_8", apk: "/etc/passwd.apk" })),
    ).toMatch(/no \/etc\/passwd.apk|in your workspace/);
    expect(
      text(await run(tools, "device_install", { device: "avd:Pixel_8", apk: "notes.txt" })),
    ).toMatch(/Only .apk/);
    host.answers.monkey = "Events injected: 1";
    expect(
      text(
        await run(tools, "device_launch", { device: "avd:Pixel_8", package: "com.example.app" }),
      ),
    ).toContain("Started com.example.app");
    expect(host.calls.at(-1)).toContain("monkey -p com.example.app");
    host.answers.pidof = "4242\n";
    host.answers.logcat = "E AndroidRuntime: FATAL EXCEPTION\nI other line";
    expect(
      text(
        await run(tools, "device_logs", {
          device: "avd:Pixel_8",
          package: "com.example.app",
          contains: "fatal",
        }),
      ),
    ).toBe("E AndroidRuntime: FATAL EXCEPTION");
    expect(host.calls.at(-1)).toContain("--pid=4242");
    d.close();
  });

  it("waits for a text; while the person has control the agents wait, then say so", async () => {
    const { d, tools } = await setup();
    expect(
      text(await run(tools, "device_wait", { device: "avd:Pixel_8", text: "sign in" })),
    ).toContain("[3]");
    d.setControl("avd:Pixel_8", "person");
    expect(text(await run(tools, "device_tap", { device: "avd:Pixel_8", ref: 3 }))).toMatch(
      /person has control/,
    );
    d.close();
  });
});

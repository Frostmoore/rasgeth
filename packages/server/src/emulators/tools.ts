// The agents' devices (3.11, phase 3): the `device_*` tools of the `devices` kit (off by default:
// an agent switches it on with request_tool). The common way of mobile agents: look (a small
// screenshot when the model sees images, always the screen's elements with numbers), act on an
// element by its number (or on a point as a fraction of the screen), look again. uiautomator's tree
// takes seconds, so it is kept until the screen changes. Every action shows in the person's live
// view; while the person has control the agents wait. Passwords are never typed by an agent.
// Installing reads the APK from the agent's workspace only; what asks whom is the policy's
// (an ordinary request on an emulator, the person's on a real phone).
import { realpath } from "node:fs/promises";
import { isAbsolute, relative, resolve, sep } from "node:path";
import type { Tool, ToolContext } from "@redgiant/agent";
import { DEVICE_BUTTONS, DEVICE_KEYS, type DeviceInput } from "@redgiant/protocol";
import { z } from "zod";
import { type DeviceAccess, DeviceError } from "./devices.js";

/** One element of the screen, as uiautomator says it. */
export interface UiNode {
  ref: number;
  text: string;
  desc: string;
  id: string;
  cls: string;
  clickable: boolean;
  focused: boolean;
  password: boolean;
  checked?: boolean;
  /** Its centre as fractions of the screen. */
  x: number;
  y: number;
}

const attr = (tag: string, name: string) => {
  const m = new RegExp(`\\s${name}="([^"]*)"`).exec(tag);
  return (m?.[1] ?? "")
    .replace(/&quot;/g, '"')
    .replace(/&apos;/g, "'")
    .replace(/&lt;/g, "<")
    .replace(/&gt;/g, ">")
    .replace(/&#10;/g, " ")
    .replace(/&amp;/g, "&");
};

/**
 * uiautomator's XML: the elements worth naming (text, a description, or something to press), with
 * numbers and their centres. The first node's bounds are the whole screen. Pure.
 */
export function parseUiTree(xml: string): UiNode[] {
  const tags = xml.match(/<node\b[^>]*>/g) ?? [];
  let W = 0;
  let H = 0;
  const out: UiNode[] = [];
  for (const tag of tags) {
    const b = /\[(-?\d+),(-?\d+)\]\[(-?\d+),(-?\d+)\]/.exec(attr(tag, "bounds"));
    if (!b) continue;
    const [x1, y1, x2, y2] = [b[1], b[2], b[3], b[4]].map(Number) as [
      number,
      number,
      number,
      number,
    ];
    W = Math.max(W, x2);
    H = Math.max(H, y2);
    const text = attr(tag, "text").trim();
    const desc = attr(tag, "content-desc").trim();
    const clickable = attr(tag, "clickable") === "true" || attr(tag, "long-clickable") === "true";
    const editable = /EditText/.test(attr(tag, "class"));
    if (!text && !desc && !clickable && !editable) continue;
    if (x2 <= x1 || y2 <= y1) continue;
    out.push({
      ref: out.length + 1,
      text,
      desc,
      id: attr(tag, "resource-id").replace(/^.*:id\//, ""),
      cls: attr(tag, "class").replace(/^.*\./, ""),
      clickable: clickable || editable,
      focused: attr(tag, "focused") === "true",
      password: attr(tag, "password") === "true",
      ...(attr(tag, "checkable") === "true" && { checked: attr(tag, "checked") === "true" }),
      x: (x1 + x2) / 2,
      y: (y1 + y2) / 2,
    });
  }
  return out.map((n) => ({
    ...n,
    x: W ? Math.round((n.x / W) * 1000) / 1000 : 0.5,
    y: H ? Math.round((n.y / H) * 1000) / 1000 : 0.5,
  }));
}

/** The elements as an agent reads them: `[3] Button "OK" (id ok) at 0.50,0.62`. Pure. */
export function describeUi(nodes: readonly UiNode[], limit = 150): string {
  const lines = nodes.slice(0, limit).map((n) => {
    const name = n.password ? "(password field)" : n.text || n.desc;
    const bits = [
      `[${n.ref}]`,
      n.cls || "View",
      name ? JSON.stringify(name.slice(0, 120)) : "",
      n.desc && n.text ? `(${n.desc.slice(0, 80)})` : "",
      n.id ? `(id ${n.id})` : "",
      n.checked !== undefined ? (n.checked ? "checked" : "unchecked") : "",
      n.focused ? "focused" : "",
      n.clickable ? "" : "not pressable",
      `at ${n.x.toFixed(2)},${n.y.toFixed(2)}`,
    ];
    return bits.filter(Boolean).join(" ");
  });
  const more = nodes.length > limit ? `\n… and ${nodes.length - limit} more elements` : "";
  return lines.length
    ? lines.join("\n") + more
    : "No named element on the screen (use the screenshot, or x and y).";
}

const PACKAGE = /^[A-Za-z][\w]*(\.[A-Za-z][\w]*)+$/;
const ACTIVITY = /^[\w.$]+$/;

export interface DeviceToolsOptions {
  /** The agent's workspace (APKs are installed from there only). */
  root: string;
  /** The model reads images: device_look adds a picture of the screen. */
  vision?: boolean;
  /** How long an action waits while the person has control (default ten minutes). */
  waitMs?: number;
}

export function deviceTools(d: DeviceAccess, o: DeviceToolsOptions): Tool[] {
  /** The tree of each device, kept until a new frame arrives. */
  const trees = new Map<string, { seq: number; nodes: UiNode[] }>();
  const sleep = (ms: number, signal?: AbortSignal) =>
    new Promise<void>((r) => {
      const t = setTimeout(r, ms);
      signal?.addEventListener("abort", () => {
        clearTimeout(t);
        r();
      });
    });
  const tree = async (device: string, fresh = false): Promise<UiNode[]> => {
    const seq = d.seq(device);
    const kept = trees.get(device);
    if (!fresh && kept && seq !== undefined && kept.seq === seq) return kept.nodes;
    const out = await d.shell(device, ["uiautomator", "dump", "/dev/tty"]);
    const start = out.indexOf("<?xml");
    const end = out.lastIndexOf("</hierarchy>");
    const nodes = start >= 0 && end > start ? parseUiTree(out.slice(start, end + 12)) : [];
    trees.set(device, { seq: d.seq(device) ?? -1, nodes });
    return nodes;
  };
  const err = (e: unknown) => ({
    content: e instanceof Error ? e.message : String(e),
    isError: true,
  });
  /** One agent at a time on a device; waits while the person drives it. */
  const act = <T>(device: string, ctx: ToolContext | undefined, f: () => Promise<T>) =>
    d
      .exclusive(device, async () => {
        const until = Date.now() + (o.waitMs ?? 10 * 60_000);
        while (d.controlOf(device) === "person") {
          if (Date.now() > until)
            throw new DeviceError(
              "The person has control of this device right now. Try again later, or ask them.",
            );
          await sleep(Math.min(1000, Math.max(10, until - Date.now())), ctx?.signal);
        }
        return f();
      })
      .catch(err);
  const input = (device: string, e: DeviceInput) => d.input(device, e, "agents");
  const tool = (
    def: Tool["def"],
    schema: z.ZodType,
    run: (i: never, ctx: ToolContext) => Promise<unknown>,
  ): Tool => ({ def, schema, run }) as unknown as Tool;
  const deviceProp = {
    device: {
      type: "string",
      description: "The device's id from device_list (avd:<name> or a serial)",
    },
  };
  const point = async (device: string, i: { ref?: number; x?: number; y?: number }) => {
    if (i.ref !== undefined) {
      const n = (await tree(device)).find((x) => x.ref === i.ref);
      if (!n)
        throw new DeviceError(
          `No element [${i.ref}] on the screen now: look again with device_look`,
        );
      return { x: n.x, y: n.y, what: `[${n.ref}] ${JSON.stringify(n.text || n.desc || n.cls)}` };
    }
    if (i.x === undefined || i.y === undefined)
      throw new DeviceError("Give ref, or x and y (fractions 0-1)");
    return { x: i.x, y: i.y, what: `${i.x.toFixed(2)},${i.y.toFixed(2)}` };
  };
  const target = z.object({
    device: z.string().min(1),
    ref: z.number().int().positive().optional(),
    x: z.number().min(0).max(1).optional(),
    y: z.number().min(0).max(1).optional(),
  });
  const targetProps = {
    ...deviceProp,
    ref: { type: "integer", description: "An element's number from device_look" },
    x: { type: "number", minimum: 0, maximum: 1, description: "Fraction of the screen's width" },
    y: { type: "number", minimum: 0, maximum: 1, description: "Fraction of the screen's height" },
  };
  const LOOK_AGAIN = " Look again with device_look to see the result.";

  return [
    tool(
      {
        name: "device_list",
        description:
          "The Android devices of this machine: virtual devices (AVDs, on or off), emulators running and real phones over USB or Wi-Fi, with their ids and who drives them now.",
        inputSchema: { type: "object", properties: {} },
      },
      z.object({}),
      async () => {
        const list = await d.list();
        if (!list.length)
          return "No device here. The person can see what is missing in Settings › Emulators.";
        return list
          .map(
            (x) =>
              `${x.id}: ${x.name} — ${x.kind === "phone" ? `phone (${x.link ?? "usb"})` : "emulator"}, ${x.state}${x.control === "person" ? ", the person has control" : ""}`,
          )
          .join("\n");
      },
    ),
    tool(
      {
        name: "device_open",
        description:
          "Open a device: an AVD that is off is started without a window (it takes a minute; at most as many emulators as the person allows run at once). The person sees it live in their canvas.",
        inputSchema: { type: "object", properties: deviceProp, required: ["device"] },
      },
      z.object({ device: z.string().min(1) }),
      ({ device }: { device: string }, ctx) =>
        act(device, ctx, async () => {
          await d.frame(device, ctx?.signal);
          return `${device} is on.${LOOK_AGAIN}`;
        }),
    ),
    tool(
      {
        name: "device_look",
        description:
          "See a device's screen: its elements with numbers (use them with device_tap and device_type), and a picture when you can read images. Look again after every action.",
        inputSchema: { type: "object", properties: deviceProp, required: ["device"] },
      },
      z.object({ device: z.string().min(1) }),
      async ({ device }: { device: string }, ctx) => {
        try {
          const frame = await d.frame(device, ctx?.signal);
          const nodes = await tree(device);
          const head = `${device}, screen ${frame.width}×${frame.height}${d.controlOf(device) === "person" ? " (the person has control now)" : ""}:\n`;
          return o.vision
            ? {
                content: head + describeUi(nodes),
                images: [
                  { type: "image" as const, mediaType: "image/jpeg" as const, data: frame.data },
                ],
              }
            : head + describeUi(nodes);
        } catch (e) {
          return err(e);
        }
      },
    ),
    tool(
      {
        name: "device_tap",
        description:
          "Tap an element by its number from device_look, or a point (x, y as fractions of the screen). long: press and hold.",
        inputSchema: {
          type: "object",
          properties: { ...targetProps, long: { type: "boolean" } },
          required: ["device"],
        },
      },
      target.extend({ long: z.boolean().optional() }),
      (i: { device: string; ref?: number; x?: number; y?: number; long?: boolean }, ctx) =>
        act(i.device, ctx, async () => {
          const p = await point(i.device, i);
          await input(
            i.device,
            i.long ? { kind: "long", x: p.x, y: p.y } : { kind: "tap", x: p.x, y: p.y },
          );
          return `${i.long ? "Held" : "Tapped"} ${p.what}.${LOOK_AGAIN}`;
        }),
    ),
    tool(
      {
        name: "device_swipe",
        description:
          "Swipe on the screen: a direction (scrolls the content the other way), or from x,y to x2,y2 (fractions).",
        inputSchema: {
          type: "object",
          properties: {
            ...deviceProp,
            direction: { type: "string", enum: ["up", "down", "left", "right"] },
            x: { type: "number" },
            y: { type: "number" },
            x2: { type: "number" },
            y2: { type: "number" },
          },
          required: ["device"],
        },
      },
      z.object({
        device: z.string().min(1),
        direction: z.enum(["up", "down", "left", "right"]).optional(),
        x: z.number().min(0).max(1).optional(),
        y: z.number().min(0).max(1).optional(),
        x2: z.number().min(0).max(1).optional(),
        y2: z.number().min(0).max(1).optional(),
      }),
      (
        i: { device: string; direction?: string; x?: number; y?: number; x2?: number; y2?: number },
        ctx,
      ) =>
        act(i.device, ctx, async () => {
          const dirs: Record<string, [number, number, number, number]> = {
            up: [0.5, 0.75, 0.5, 0.25],
            down: [0.5, 0.25, 0.5, 0.75],
            left: [0.8, 0.5, 0.2, 0.5],
            right: [0.2, 0.5, 0.8, 0.5],
          };
          const v = i.direction
            ? dirs[i.direction]
            : i.x !== undefined && i.y !== undefined && i.x2 !== undefined && i.y2 !== undefined
              ? ([i.x, i.y, i.x2, i.y2] as [number, number, number, number])
              : undefined;
          if (!v) throw new DeviceError("Give a direction, or x, y, x2 and y2");
          await input(i.device, { kind: "swipe", x: v[0], y: v[1], x2: v[2], y2: v[3] });
          return `Swiped ${i.direction ?? "as asked"}.${LOOK_AGAIN}`;
        }),
    ),
    tool(
      {
        name: "device_type",
        description:
          "Type text into the field that has the focus (tap it first), or into an element by its number; submit presses Enter. Never passwords or codes: the person types those after taking control.",
        inputSchema: {
          type: "object",
          properties: {
            ...deviceProp,
            text: { type: "string" },
            ref: { type: "integer" },
            submit: { type: "boolean" },
          },
          required: ["device", "text"],
        },
      },
      z.object({
        device: z.string().min(1),
        text: z.string().min(1).max(2000),
        ref: z.number().int().positive().optional(),
        submit: z.boolean().optional(),
      }),
      (i: { device: string; text: string; ref?: number; submit?: boolean }, ctx) =>
        act(i.device, ctx, async () => {
          if (i.ref !== undefined) {
            const p = await point(i.device, i);
            await input(i.device, { kind: "tap", x: p.x, y: p.y });
            await sleep(400, ctx?.signal);
          }
          const nodes = await tree(i.device, true);
          const field =
            i.ref !== undefined ? nodes.find((n) => n.ref === i.ref) : nodes.find((n) => n.focused);
          if (field?.password)
            throw new DeviceError(
              "That is a password field: passwords are typed by the person. Ask them to take control of the device (its screen in their canvas).",
            );
          await input(i.device, { kind: "text", text: i.text });
          if (i.submit) await input(i.device, { kind: "key", key: "Enter" });
          return `Typed ${i.text.length} characters${i.submit ? " and pressed Enter" : ""}.${LOOK_AGAIN}`;
        }),
    ),
    tool(
      {
        name: "device_press",
        description: `Press a key (${DEVICE_KEYS.join(", ")}) or one of the phone's buttons (${DEVICE_BUTTONS.join(", ")}).`,
        inputSchema: {
          type: "object",
          properties: {
            ...deviceProp,
            key: { type: "string", enum: [...DEVICE_KEYS, ...DEVICE_BUTTONS] },
          },
          required: ["device", "key"],
        },
      },
      z.object({ device: z.string().min(1), key: z.enum([...DEVICE_KEYS, ...DEVICE_BUTTONS]) }),
      (i: { device: string; key: string }, ctx) =>
        act(i.device, ctx, async () => {
          const isButton = (DEVICE_BUTTONS as readonly string[]).includes(i.key);
          await input(
            i.device,
            isButton
              ? { kind: "button", button: i.key as (typeof DEVICE_BUTTONS)[number] }
              : { kind: "key", key: i.key as (typeof DEVICE_KEYS)[number] },
          );
          return `Pressed ${i.key}.${LOOK_AGAIN}`;
        }),
    ),
    tool(
      {
        name: "device_rotate",
        description: "Turn the device between portrait and landscape.",
        inputSchema: { type: "object", properties: deviceProp, required: ["device"] },
      },
      z.object({ device: z.string().min(1) }),
      ({ device }: { device: string }, ctx) =>
        act(device, ctx, async () => {
          await input(device, { kind: "rotate" });
          await sleep(1500, ctx?.signal);
          return `Turned.${LOOK_AGAIN}`;
        }),
    ),
    tool(
      {
        name: "device_wait",
        description:
          "Wait until a text shows on the screen (up to 30 seconds), or a number of milliseconds.",
        inputSchema: {
          type: "object",
          properties: {
            ...deviceProp,
            text: { type: "string" },
            ms: { type: "integer", maximum: 30000 },
          },
          required: ["device"],
        },
      },
      z.object({
        device: z.string().min(1),
        text: z.string().min(1).max(200).optional(),
        ms: z.number().int().min(0).max(30_000).optional(),
      }),
      async (i: { device: string; text?: string; ms?: number }, ctx) => {
        try {
          if (!i.text) {
            await sleep(i.ms ?? 1000, ctx?.signal);
            return `Waited ${i.ms ?? 1000} ms.`;
          }
          const until = Date.now() + Math.min(i.ms ?? 30_000, 30_000);
          const want = i.text.toLowerCase();
          while (Date.now() < until && !ctx?.signal?.aborted) {
            const nodes = await tree(i.device, true);
            const n = nodes.find((x) => `${x.text} ${x.desc}`.toLowerCase().includes(want));
            if (n)
              return `«${i.text}» is on the screen: [${n.ref}] at ${n.x.toFixed(2)},${n.y.toFixed(2)}.`;
            await sleep(700, ctx?.signal);
          }
          return { content: `«${i.text}» did not show in time.`, isError: true };
        } catch (e) {
          return err(e);
        }
      },
    ),
    tool(
      {
        name: "device_install",
        description:
          "Install an APK from your workspace on a device (on an emulator it is an ordinary request; on a real phone the person always decides).",
        inputSchema: {
          type: "object",
          properties: {
            ...deviceProp,
            apk: { type: "string", description: "Path of the .apk in your workspace" },
          },
          required: ["device", "apk"],
        },
      },
      z.object({ device: z.string().min(1), apk: z.string().min(1).max(1000) }),
      (i: { device: string; apk: string }, ctx) =>
        act(i.device, ctx, async () => {
          if (!/\.apk$/i.test(i.apk)) throw new DeviceError("Only .apk files are installed");
          const root = await realpath(o.root).catch(() => o.root);
          const file = await realpath(isAbsolute(i.apk) ? i.apk : resolve(root, i.apk)).catch(
            () => {
              throw new DeviceError(`There is no ${i.apk} in your workspace`);
            },
          );
          const rel = relative(root, file);
          if (rel.startsWith("..") || isAbsolute(rel) || rel.split(sep)[0] === "..")
            throw new DeviceError("The APK must be in your workspace");
          const out = await d.install(i.device, file, ctx?.signal);
          if (!/Success/.test(out))
            throw new DeviceError(`The device refused the APK: ${out.slice(0, 500)}`);
          return `Installed ${rel.split(sep).join("/")} on ${i.device}.`;
        }),
    ),
    tool(
      {
        name: "device_launch",
        description: "Start an app by its package (and an activity, if you know it).",
        inputSchema: {
          type: "object",
          properties: { ...deviceProp, package: { type: "string" }, activity: { type: "string" } },
          required: ["device", "package"],
        },
      },
      z.object({
        device: z.string().min(1),
        package: z.string().regex(PACKAGE),
        activity: z.string().regex(ACTIVITY).optional(),
      }),
      (i: { device: string; package: string; activity?: string }, ctx) =>
        act(i.device, ctx, async () => {
          const out = i.activity
            ? await d.shell(
                i.device,
                ["am", "start", "-n", `${i.package}/${i.activity}`],
                ctx?.signal,
              )
            : await d.shell(i.device, [
                "monkey",
                "-p",
                i.package,
                "-c",
                "android.intent.category.LAUNCHER",
                "1",
              ]);
          if (/Error|No activities found|does not exist/i.test(out))
            throw new DeviceError(`It did not start: ${out.trim().slice(0, 400)}`);
          return `Started ${i.package}.${LOOK_AGAIN}`;
        }),
    ),
    tool(
      {
        name: "device_logs",
        description:
          "The device's recent log (logcat): an app's lines by its package, or warnings and errors of everything.",
        inputSchema: {
          type: "object",
          properties: {
            ...deviceProp,
            package: { type: "string" },
            lines: { type: "integer", maximum: 500 },
            contains: { type: "string" },
          },
          required: ["device"],
        },
      },
      z.object({
        device: z.string().min(1),
        package: z.string().regex(PACKAGE).optional(),
        lines: z.number().int().min(10).max(500).optional(),
        contains: z.string().max(200).optional(),
      }),
      async (i: { device: string; package?: string; lines?: number; contains?: string }, ctx) => {
        try {
          const n = String(i.lines ?? 200);
          let args = ["logcat", "-d", "-t", n, "*:W"];
          if (i.package) {
            const pid = (await d.shell(i.device, ["pidof", i.package], ctx?.signal))
              .trim()
              .split(/\s+/)[0];
            if (!pid) return `${i.package} is not running.`;
            args = ["logcat", "-d", "-t", n, `--pid=${pid}`];
          }
          let text = await d.shell(i.device, args, ctx?.signal);
          if (i.contains) {
            const want = i.contains.toLowerCase();
            text = text
              .split("\n")
              .filter((l) => l.toLowerCase().includes(want))
              .join("\n");
          }
          return text.trim().slice(-20_000) || "Nothing in the log.";
        } catch (e) {
          return err(e);
        }
      },
    ),
  ];
}

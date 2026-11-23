// iOS simulators on a Mac (3.12.2), behind the same `DeviceHost` as Android. `xcrun simctl` lists,
// boots, stops, installs an app folder, launches it by bundle id and reads the log; the picture and
// the touches come through serve-sim (Apache-2.0, Apple silicon), which Rasgeth never ships: the
// person's yes downloads it into a Rasgeth folder (`install-ios.ts`). serve-sim runs as a child
// process per booted simulator (`serve-sim --no-preview <udid>` prints one JSON line with the
// stream and WebSocket addresses), only while a screen is open. Its MJPEG stream gives the frames;
// its WebSocket takes `[tag][JSON]` messages (touch 0x03, button 0x04, key 0x06, orientation 0x07)
// with x and y as fractions of the screen. Programs run with `execFile`/`spawn`, never a shell,
// arguments one by one and checked; keyboard repair (`serve-sim repair-input`, which restarts
// SpringBoard) is never run from here.
import { execFile, spawn } from "node:child_process";
import { stat } from "node:fs/promises";
import type { DeviceInput, IosReport } from "@redgiant/protocol";
import { parseSimctl } from "./detect.js";
import type { DeviceFrame, DeviceHost, DeviceScreen, HostDevice } from "./host.js";

const UDID = /^[0-9A-Fa-f]{8}(-[0-9A-Fa-f]{4}){3}-[0-9A-Fa-f]{12}$/;
const BUNDLE = /^[A-Za-z0-9][A-Za-z0-9._-]{0,150}$/;
/** A process or a subsystem in a log filter: no quote, no backslash, nothing a predicate could use. */
const NAME = /^[A-Za-z0-9][A-Za-z0-9._ -]{0,100}$/;
const sleep = (ms: number) => new Promise((r) => setTimeout(r, ms));

export class IosError extends Error {}

export type Run = (
  file: string,
  args: string[],
  o: { timeoutMs: number; signal?: AbortSignal; env?: NodeJS.ProcessEnv; input?: string },
) => Promise<{ code: number | null; out: string; err: string }>;

/** `execFile` (no shell): the answer even when the program fails. */
export const runProgram: Run = (file, args, o) =>
  new Promise((resolve) => {
    const child = execFile(
      file,
      args,
      {
        timeout: o.timeoutMs,
        maxBuffer: 32 * 1024 * 1024,
        ...(o.signal && { signal: o.signal }),
        ...(o.env && { env: o.env }),
      },
      (err, out, errOut) => {
        const code =
          err === null
            ? 0
            : typeof (err as NodeJS.ErrnoException).code === "number"
              ? ((err as NodeJS.ErrnoException).code as unknown as number)
              : null;
        resolve({ code, out: String(out), err: String(errOut || (err ? err.message : "")) });
      },
    );
    // Text for the program's stdin (never a shell string).
    if (o.input !== undefined) {
      child.stdin?.on("error", () => {});
      child.stdin?.end(o.input);
    }
  });

/** The bridge process serve-sim runs as for one simulator. */
export interface BridgeProcess {
  onOutput(cb: (text: string) => void): void;
  /** The exit code (null when it was killed). */
  exit: Promise<number | null>;
  kill(): void;
}
export type SpawnBridge = (script: string, udid: string) => BridgeProcess;

/** Only what serve-sim needs from the environment: Rasgeth's own keys never go to it. */
export function bridgeEnv(env: NodeJS.ProcessEnv): NodeJS.ProcessEnv {
  const keep = ["PATH", "HOME", "USER", "LANG", "LC_ALL", "TMPDIR", "DEVELOPER_DIR", "SHELL"];
  return Object.fromEntries(keep.filter((k) => env[k] !== undefined).map((k) => [k, env[k]]));
}

/** The Node Rasgeth runs with starts serve-sim's script (no global install, no `npx`). */
export const spawnBridge: SpawnBridge = (script, udid) => {
  const child = spawn(process.execPath, [script, "--no-preview", udid], {
    env: bridgeEnv(process.env),
    stdio: ["ignore", "pipe", "pipe"],
  });
  const exit = new Promise<number | null>((r) => {
    child.on("error", () => r(null));
    child.on("close", (c) => r(c));
  });
  return {
    onOutput: (cb) => {
      child.stdout.on("data", (d: Buffer) => cb(d.toString("utf8")));
      child.stderr.on("data", (d: Buffer) => cb(d.toString("utf8")));
    },
    exit,
    kill: () => {
      child.kill("SIGTERM");
    },
  };
};

/** What serve-sim prints once it serves a simulator. */
export interface BridgeInfo {
  streamUrl: string;
  wsUrl: string;
}

/** The JSON line serve-sim prints (`{"url","streamUrl","wsUrl","port","device"}`) in its output. */
export function parseBridgeInfo(text: string): BridgeInfo | undefined {
  for (const line of text.split(/\r?\n/)) {
    const t = line.trim();
    if (!t.startsWith("{")) continue;
    try {
      const j = JSON.parse(t) as { streamUrl?: unknown; wsUrl?: unknown };
      if (typeof j.streamUrl === "string" && typeof j.wsUrl === "string") {
        // Only this machine: the bridge listens here and nowhere else is asked.
        const ok = (u: string) => /^(https?|wss?):\/\/(127\.0\.0\.1|localhost|\[::1\])[:/]/.test(u);
        if (ok(j.streamUrl) && ok(j.wsUrl)) return { streamUrl: j.streamUrl, wsUrl: j.wsUrl };
      }
    } catch {}
  }
  return undefined;
}

// ---- The MJPEG stream: `--frame\r\nContent-Type: image/jpeg\r\nContent-Length: N\r\n\r\n<JPEG>\r\n` ----

/** Cuts the stream into JPEG frames, by each part's Content-Length. Pure state, no timers. */
export class MjpegParser {
  private buf: Buffer = Buffer.alloc(0);

  /** The frames the chunk completed. */
  push(chunk: Uint8Array): Buffer[] {
    this.buf = this.buf.length ? Buffer.concat([this.buf, chunk]) : Buffer.from(chunk);
    const out: Buffer[] = [];
    for (;;) {
      const end = this.buf.indexOf("\r\n\r\n");
      if (end < 0) {
        // Nothing but garbage grows without a header: keep it bounded.
        if (this.buf.length > 64 * 1024) this.buf = Buffer.alloc(0);
        break;
      }
      const head = this.buf.subarray(0, end).toString("latin1");
      const len = /content-length:\s*(\d+)/i.exec(head)?.[1];
      if (!len) {
        this.buf = this.buf.subarray(end + 4);
        continue;
      }
      const n = Number(len);
      if (n > 32 * 1024 * 1024) {
        this.buf = Buffer.alloc(0);
        break;
      }
      if (this.buf.length < end + 4 + n) break;
      out.push(Buffer.from(this.buf.subarray(end + 4, end + 4 + n)));
      this.buf = this.buf.subarray(end + 4 + n);
    }
    return out;
  }
}

/** A JPEG's width and height, from its first start-of-frame marker; undefined when not found. */
export function jpegSize(b: Uint8Array): { width: number; height: number } | undefined {
  if (b.length < 4 || b[0] !== 0xff || b[1] !== 0xd8) return undefined;
  let i = 2;
  while (i + 9 < b.length) {
    if (b[i] !== 0xff) {
      i++;
      continue;
    }
    const m = b[i + 1] as number;
    if (m === 0xff) {
      i++;
      continue;
    }
    if (m === 0xd8 || (m >= 0xd0 && m <= 0xd7) || m === 0x01) {
      i += 2;
      continue;
    }
    const len = ((b[i + 2] as number) << 8) | (b[i + 3] as number);
    const sof = m >= 0xc0 && m <= 0xcf && m !== 0xc4 && m !== 0xc8 && m !== 0xcc;
    if (sof)
      return {
        height: ((b[i + 5] as number) << 8) | (b[i + 6] as number),
        width: ((b[i + 7] as number) << 8) | (b[i + 8] as number),
      };
    i += 2 + len;
  }
  return undefined;
}

// ---- Input: serve-sim's WebSocket messages ----

export const TAG = { touch: 0x03, button: 0x04, key: 0x06, orientation: 0x07, config: 0x82 };

/** `[tag][JSON]`, as serve-sim's own command line sends it. */
export function wsMessage(tag: number, body: unknown): Uint8Array {
  const json = Buffer.from(JSON.stringify(body), "utf8");
  const out = new Uint8Array(1 + json.length);
  out[0] = tag;
  out.set(json, 1);
  return out;
}

const HID_SHIFT = 225;
/** US-keyboard characters as HID usages (page 7), the ones serve-sim's `type` knows. */
export function keystroke(ch: string): { usage: number; shift: boolean } | undefined {
  if (/^[a-z]$/.test(ch)) return { usage: 4 + ch.charCodeAt(0) - 97, shift: false };
  if (/^[A-Z]$/.test(ch)) return { usage: 4 + ch.charCodeAt(0) - 65, shift: true };
  const digits = "1234567890";
  const marks = "!@#$%^&*()";
  const d = digits.indexOf(ch);
  if (d >= 0) return { usage: 30 + d, shift: false };
  const m = marks.indexOf(ch);
  if (m >= 0) return { usage: 30 + m, shift: true };
  const pairs: [string, string, number][] = [
    ["-", "_", 45],
    ["=", "+", 46],
    ["[", "{", 47],
    ["]", "}", 48],
    ["\\", "|", 49],
    [";", ":", 51],
    ["'", '"', 52],
    ["`", "~", 53],
    [",", "<", 54],
    [".", ">", 55],
    ["/", "?", 56],
  ];
  for (const [a, b, usage] of pairs) {
    if (ch === a) return { usage, shift: false };
    if (ch === b) return { usage, shift: true };
  }
  if (ch === " ") return { usage: 44, shift: false };
  if (ch === "\n") return { usage: 40, shift: false };
  if (ch === "\t") return { usage: 43, shift: false };
  return undefined;
}

/** The key presses that type a text (shift held around the characters that need it). */
export function typeEvents(text: string): { type: "down" | "up"; usage: number }[] {
  const out: { type: "down" | "up"; usage: number }[] = [];
  for (const ch of text) {
    if (ch === "\r") continue;
    const k = keystroke(ch);
    if (!k) throw new IosError(`Cannot type ${JSON.stringify(ch)}: only US-keyboard characters`);
    if (k.shift) out.push({ type: "down", usage: HID_SHIFT });
    out.push({ type: "down", usage: k.usage }, { type: "up", usage: k.usage });
    if (k.shift) out.push({ type: "up", usage: HID_SHIFT });
  }
  return out;
}

const HID_LEFT_GUI = 227;
const HID_V = 25;
/** Cmd+V as key presses. */
export function pasteEvents(): { type: "down" | "up"; usage: number }[] {
  return [
    { type: "down", usage: HID_LEFT_GUI },
    { type: "down", usage: HID_V },
    { type: "up", usage: HID_V },
    { type: "up", usage: HID_LEFT_GUI },
  ];
}

const KEY_USAGE: Record<string, number> = {
  Enter: 40,
  Escape: 41,
  Backspace: 42,
  Tab: 43,
  Space: 44,
  Delete: 76,
  ArrowRight: 79,
  ArrowLeft: 80,
  ArrowDown: 81,
  ArrowUp: 82,
};

/** The buttons a simulator has; back and recents are Android's. */
const BUTTONS: Record<string, { button: string; page?: number; usage?: number }> = {
  home: { button: "home" },
  power: { button: "power", page: 12, usage: 48 },
  volume_up: { button: "volume-up", page: 12, usage: 233 },
  volume_down: { button: "volume-down", page: 12, usage: 234 },
};

export type Orientation =
  | "portrait"
  | "landscape_left"
  | "portrait_upside_down"
  | "landscape_right";

/** The touches that make a gesture, as serve-sim takes them (fractions of the screen). Pure. */
export function touchPlan(
  e: Extract<DeviceInput, { kind: "tap" | "long" | "swipe" }>,
): { type: "begin" | "move" | "end"; x: number; y: number; wait: number }[] {
  if (e.kind === "tap")
    return [
      { type: "begin", x: e.x, y: e.y, wait: 40 },
      { type: "end", x: e.x, y: e.y, wait: 0 },
    ];
  if (e.kind === "long")
    return [
      { type: "begin", x: e.x, y: e.y, wait: e.ms ?? 800 },
      { type: "end", x: e.x, y: e.y, wait: 0 },
    ];
  const ms = e.ms ?? 300;
  const steps = Math.max(2, Math.min(60, Math.round(ms / 16)));
  const out: { type: "begin" | "move" | "end"; x: number; y: number; wait: number }[] = [
    { type: "begin", x: e.x, y: e.y, wait: Math.round(ms / steps) },
  ];
  for (let i = 1; i < steps; i++)
    out.push({
      type: "move",
      x: e.x + ((e.x2 - e.x) * i) / steps,
      y: e.y + ((e.y2 - e.y) * i) / steps,
      wait: Math.round(ms / steps),
    });
  out.push({ type: "end", x: e.x2, y: e.y2, wait: 0 });
  return out;
}

export interface WsLike {
  binaryType?: string;
  onopen: ((e: unknown) => void) | null;
  onmessage: ((e: { data: unknown }) => void) | null;
  onclose: ((e: unknown) => void) | null;
  onerror: ((e: unknown) => void) | null;
  send(data: Uint8Array): void;
  close(): void;
}

export interface IosHostOptions {
  /** serve-sim's script, when installed (the guided step); undefined: not installed. */
  bridge: () => Promise<string | undefined>;
  run?: Run;
  spawn?: SpawnBridge;
  fetch?: typeof fetch;
  webSocket?: (url: string) => WsLike;
  /** How long a simulator may take to boot / the bridge to answer. */
  bootMs?: number;
  bridgeMs?: number;
  /** At most this many frames a second (default 15). */
  fps?: number;
  /** Pause between the key presses of a text (default 4 ms, as serve-sim's own `type`). */
  keyMs?: number;
}

interface Bridge {
  proc: BridgeProcess;
  info: Promise<BridgeInfo>;
  refs: number;
}

export class IosHost implements DeviceHost {
  private readonly bridges = new Map<string, Bridge>();
  private readonly run: Run;

  constructor(private readonly o: IosHostOptions) {
    this.run = o.run ?? runProgram;
  }

  private async simctl(args: string[], timeoutMs = 60_000, signal?: AbortSignal, input?: string) {
    const r = await this.run("xcrun", ["simctl", ...args], {
      timeoutMs,
      ...(signal && { signal }),
      ...(input !== undefined && { input }),
    });
    if (r.code !== 0) throw new IosError((r.err || r.out || "simctl failed").trim().slice(0, 600));
    return r.out;
  }

  /** Every iOS simulator on this Mac (booted or not), with its runtime. */
  async simulators(): Promise<IosReport["simulators"]> {
    return parseSimctl(await this.simctl(["list", "-j", "devices"], 20_000)).filter((s) =>
      s.runtime.startsWith("iOS"),
    );
  }

  /** The simulators that are booted, as devices. */
  async devices(): Promise<HostDevice[]> {
    return (await this.simulators())
      .filter((s) => s.state === "booted")
      .map((s) => ({
        serial: s.udid,
        kind: "emulator" as const,
        state: "device" as const,
        platform: "ios" as const,
        model: s.name,
        runtime: s.runtime,
      }));
  }

  async boot(udid: string, signal?: AbortSignal): Promise<string> {
    if (!UDID.test(udid)) throw new IosError("Not a simulator's id");
    // `bootstatus -b` boots a simulator that is off and waits until it has finished starting.
    await this.simctl(["bootstatus", udid, "-b"], this.o.bootMs ?? 5 * 60_000, signal);
    return udid;
  }

  async stop(udid: string): Promise<void> {
    if (!UDID.test(udid)) throw new IosError("Not a simulator's id");
    this.release(udid, true);
    const r = await this.run("xcrun", ["simctl", "shutdown", udid], { timeoutMs: 60_000 });
    // Already off is not a failure.
    if (r.code !== 0 && !/current state: Shutdown/i.test(r.err))
      throw new IosError((r.err || "shutdown failed").trim().slice(0, 400));
  }

  // ---- serve-sim, one process per simulator while someone looks ----

  private acquire(udid: string): Promise<BridgeInfo> {
    let b = this.bridges.get(udid);
    if (!b) {
      const made = this.startBridge(udid);
      b = made;
      this.bridges.set(udid, made);
      made.info.catch(() => {
        if (this.bridges.get(udid) === made) this.bridges.delete(udid);
      });
    }
    b.refs++;
    return b.info;
  }

  private startBridge(udid: string): Bridge {
    const bridge = { proc: undefined, refs: 0 } as unknown as Bridge;
    bridge.info = (async () => {
      const script = await this.o.bridge();
      if (!script)
        throw new IosError(
          "The iOS bridge (serve-sim) is not installed: install it from Settings › Emulators",
        );
      const proc = (this.o.spawn ?? spawnBridge)(script, udid);
      bridge.proc = proc;
      return new Promise<BridgeInfo>((resolve, reject) => {
        let text = "";
        const timer = setTimeout(() => {
          proc.kill();
          reject(new IosError("serve-sim did not say where it serves the simulator"));
        }, this.o.bridgeMs ?? 45_000);
        proc.onOutput((t) => {
          text = (text + t).slice(-8000);
          const i = parseBridgeInfo(text);
          if (i) {
            clearTimeout(timer);
            resolve(i);
          }
        });
        void proc.exit.then((c) => {
          clearTimeout(timer);
          if (this.bridges.get(udid) === bridge) this.bridges.delete(udid);
          reject(new IosError(`serve-sim stopped (${c ?? "killed"}): ${text.trim().slice(-300)}`));
        });
      });
    })();
    return bridge;
  }

  private release(udid: string, force = false) {
    const b = this.bridges.get(udid);
    if (!b) return;
    b.refs = force ? 0 : Math.max(0, b.refs - 1);
    if (b.refs === 0) {
      this.bridges.delete(udid);
      b.proc?.kill();
    }
  }

  /** Stops every bridge (the server closes). */
  close(): void {
    for (const udid of [...this.bridges.keys()]) this.release(udid, true);
  }

  async screen(
    udid: string,
    onFrame: (f: DeviceFrame) => void,
    ended: (error?: string) => void,
  ): Promise<DeviceScreen> {
    if (!UDID.test(udid)) throw new IosError("Not a simulator's id");
    const info = await this.acquire(udid).catch((e) => {
      this.release(udid);
      throw e;
    });
    const abort = new AbortController();
    let closed = false;
    let size = { width: 0, height: 0 };
    let orientation: Orientation = "portrait";
    let ws: Promise<WsLike> | undefined;
    const doFetch = this.o.fetch ?? fetch;
    const gap = 1000 / (this.o.fps ?? 15);
    let last = 0;
    let pending: Buffer | undefined;
    let timer: NodeJS.Timeout | undefined;
    const emit = (jpeg: Buffer) => {
      last = Date.now();
      const s = jpegSize(jpeg);
      if (s) size = s;
      onFrame({ data: jpeg.toString("base64"), width: size.width, height: size.height });
    };
    const finish = (error?: string) => {
      if (closed) return;
      closed = true;
      if (timer) clearTimeout(timer);
      abort.abort();
      void ws?.then((w) => w.close()).catch(() => {});
      this.release(udid);
      ended(error);
    };
    void (async () => {
      try {
        const r = await doFetch(info.streamUrl, { signal: abort.signal });
        if (!r.ok || !r.body) throw new IosError(`The stream answered ${r.status}`);
        const parser = new MjpegParser();
        const reader = r.body.getReader();
        for (;;) {
          const { done, value } = await reader.read();
          if (done) break;
          for (const jpeg of parser.push(value)) {
            const wait = gap - (Date.now() - last);
            if (wait <= 0) {
              pending = undefined;
              emit(jpeg);
            } else {
              pending = jpeg;
              timer ??= setTimeout(() => {
                timer = undefined;
                if (pending && !closed) {
                  const p = pending;
                  pending = undefined;
                  emit(p);
                }
              }, wait);
            }
          }
        }
        finish("The simulator's screen stopped");
      } catch (e) {
        if (!closed) finish(e instanceof Error ? e.message : String(e));
      }
    })();

    const socket = (): Promise<WsLike> => {
      ws ??= new Promise<WsLike>((resolve, reject) => {
        const w = (this.o.webSocket ?? ((u: string) => new WebSocket(u) as unknown as WsLike))(
          info.wsUrl,
        );
        w.binaryType = "arraybuffer";
        w.onopen = () => resolve(w);
        w.onerror = () => {
          ws = undefined;
          reject(new IosError("Could not reach the simulator's input channel"));
        };
        w.onclose = () => {
          ws = undefined;
        };
        w.onmessage = (m) => {
          const d = m.data instanceof ArrayBuffer ? new Uint8Array(m.data) : undefined;
          if (!d || d[0] !== TAG.config) return;
          try {
            const c = JSON.parse(Buffer.from(d.subarray(1)).toString("utf8")) as {
              orientation?: Orientation;
            };
            if (c.orientation) orientation = c.orientation;
          } catch {}
        };
      });
      return ws;
    };
    const send = async (tag: number, body: unknown) => (await socket()).send(wsMessage(tag, body));

    return {
      size: () => size,
      input: async (e) => {
        switch (e.kind) {
          case "tap":
          case "long":
          case "swipe":
            for (const t of touchPlan(e)) {
              await send(TAG.touch, { type: t.type, x: t.x, y: t.y });
              if (t.wait) await sleep(t.wait);
            }
            return;
          case "text": {
            // Any language: the text goes on the simulator's pasteboard and Cmd+V pastes it. When
            // that is refused, plain US-keyboard text is typed key by key as before.
            const pasted = await this.simctl(["pbcopy", udid], 15_000, undefined, e.text).then(
              () => true,
              () => false,
            );
            if (pasted) {
              for (const k of pasteEvents()) {
                await send(TAG.key, k);
                await sleep(this.o.keyMs ?? 4);
              }
              return;
            }
            for (const k of typeEvents(e.text)) {
              await send(TAG.key, k);
              await sleep(this.o.keyMs ?? 4);
            }
            return;
          }
          case "key": {
            const usage = KEY_USAGE[e.key];
            if (usage === undefined) throw new IosError(`No such key: ${e.key}`);
            await send(TAG.key, { type: "down", usage });
            await send(TAG.key, { type: "up", usage });
            return;
          }
          case "button": {
            const b = BUTTONS[e.button];
            if (!b) throw new IosError(`An iPhone has no ${e.button} button (use home)`);
            await send(TAG.button, b);
            return;
          }
          case "rotate": {
            const next: Orientation = orientation === "portrait" ? "landscape_left" : "portrait";
            await send(TAG.orientation, { orientation: next });
            orientation = next;
            return;
          }
        }
      },
      close: async () => {
        finish();
      },
    };
  }

  /**
   * The few commands the agents' tools need, by verb (never a free command): `launch <bundle>`,
   * `terminate <bundle>`, `logs <minutes> <all|subsystem|process> [name]`.
   */
  async shell(udid: string, args: readonly string[]): Promise<string> {
    if (!UDID.test(udid)) throw new IosError("Not a simulator's id");
    const [verb, ...r] = args;
    switch (verb) {
      case "launch":
      case "terminate": {
        if (r.length !== 1 || !BUNDLE.test(r[0] ?? ""))
          throw new IosError("Give the app's bundle id (com.example.App)");
        return (await this.simctl([verb, udid, r[0] as string], 60_000)).trim() || "Done";
      }
      case "logs": {
        const minutes = Number(r[0]);
        if (!Number.isInteger(minutes) || minutes < 1 || minutes > 60)
          throw new IosError("Minutes must be 1 to 60");
        const kind = r[1];
        const name = r[2];
        let predicate = 'messageType == "Error" OR messageType == "Fault"';
        if (kind === "subsystem" || kind === "process") {
          if (!name || !NAME.test(name)) throw new IosError("Not a name a log filter accepts");
          predicate = `${kind} == "${name}"`;
        } else if (kind !== "all") throw new IosError("Unknown log filter");
        const out = await this.simctl(
          [
            "spawn",
            udid,
            "log",
            "show",
            "--last",
            `${minutes}m`,
            "--style",
            "compact",
            "--predicate",
            predicate,
          ],
          90_000,
        );
        return out;
      }
      case "ax": {
        if (r.length) throw new IosError("ax takes no argument");
        return this.accessibility(udid);
      }
      default:
        throw new IosError("That command does not run on an iOS simulator");
    }
  }

  /** serve-sim's accessibility snapshot of the screen (JSON text), through the running bridge. */
  private async accessibility(udid: string): Promise<string> {
    const info = await this.acquire(udid).catch((e) => {
      this.release(udid);
      throw e;
    });
    try {
      const url = info.streamUrl.replace(/\/stream\.mjpeg(\?.*)?$/, "/ax");
      const res = await (this.o.fetch ?? fetch)(url, { signal: AbortSignal.timeout(15_000) });
      const body = await res.text();
      if (!res.ok)
        throw new IosError(`Accessibility unavailable (${res.status}): ${body.slice(0, 200)}`);
      return body.slice(0, 4 * 1024 * 1024);
    } finally {
      this.release(udid);
    }
  }

  /**
   * `serve-sim repair-input -d <udid>`: restarts the simulator's home screen (SpringBoard) and
   * closes its open apps, to get touches and keys working again. Only ever called for an explicit
   * action of the person; the bridge is restarted afterwards.
   */
  async repair(udid: string): Promise<void> {
    if (!UDID.test(udid)) throw new IosError("Not a simulator's id");
    const script = await this.o.bridge();
    if (!script) throw new IosError("The iOS bridge (serve-sim) is not installed");
    this.release(udid, true);
    const r = await this.run(process.execPath, [script, "repair-input", "-d", udid], {
      timeoutMs: 90_000,
      env: bridgeEnv(process.env),
    });
    if (r.code !== 0)
      throw new IosError((r.err || r.out || "repair-input failed").trim().slice(-400));
  }

  /** An `.app` folder of this Mac installed on the simulator; «Success» when simctl did it. */
  async install(udid: string, app: string): Promise<string> {
    if (!UDID.test(udid)) throw new IosError("Not a simulator's id");
    if (!/\.app$/i.test(app)) throw new IosError("Only .app folders are installed on a simulator");
    if (!(await stat(app).catch(() => null))?.isDirectory())
      throw new IosError("The .app must be a folder (a built app for the simulator)");
    await this.simctl(["install", udid, app], 5 * 60_000);
    return "Success";
  }
}

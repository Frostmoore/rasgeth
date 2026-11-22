// Android devices through adb and scrcpy (3.11, phase 2), on any machine with an SDK: adb's own
// server (started with the SDK's adb when it is not running, when someone opens a device), Tango
// (`@yume-chan/adb`, `@yume-chan/scrcpy`) for the device's screen and input, the emulator started
// without a window (it also runs on a machine without a display). Programs run with `execFile` or
// `spawn` and arguments one by one; commands on the device escape every argument.
//
// What phase 0 measured decides the details: touches use the pointer id of a finger (0), never the
// mouse's; rotation is the system's own setting (`user_rotation`), since scrcpy's rotate does not
// turn an emulator's screen; the scrcpy server is the pinned 3.3.3, the last one Tango speaks.
import { execFile, spawn } from "node:child_process";
import { readFile } from "node:fs/promises";
import { basename } from "node:path";
import type { DeviceInput } from "@redgiant/protocol";
import { type Adb, AdbServerClient, escapeArg } from "@yume-chan/adb";
import { AdbScrcpyClient, AdbScrcpyOptions3_3_3 } from "@yume-chan/adb-scrcpy";
import { AdbServerNodeTcpConnector } from "@yume-chan/adb-server-node-tcp";
import {
  type AndroidKeyCode,
  AndroidKeyEventAction,
  AndroidMotionEventAction,
  DefaultServerPath,
  ScrcpyInstanceId,
} from "@yume-chan/scrcpy";
import { ReadableStream, WritableStream } from "@yume-chan/stream-extra";
import { parseAdbDevices } from "./detect.js";
import {
  type DeviceFrame,
  type DeviceHost,
  type DeviceScreen,
  type HostDevice,
  KEY_CODES,
  type VideoPacket,
} from "./host.js";
import { H264ToJpeg, scrcpyJar } from "./jpeg.js";

const AVD_NAME = /^[A-Za-z0-9][A-Za-z0-9._-]{0,99}$/;
const sleep = (ms: number) => new Promise((r) => setTimeout(r, ms));

export interface AndroidHostOptions {
  /** The SDK's programs on this machine (from `detectEmulators`); adb alone is enough for phones. */
  tools: () => Promise<{ adb?: string; emulator?: string }>;
  /** ffmpeg, to turn the video into JPEG frames. */
  ffmpeg: () => Promise<string>;
  /** adb's server port (default ANDROID_ADB_SERVER_PORT or 5037). */
  port?: number;
  /** How long an AVD may take to start. */
  bootMs?: number;
}

const one = <T>(bytes: Uint8Array) =>
  new ReadableStream<T>({
    start(c) {
      c.enqueue(bytes as T);
      c.close();
    },
  });

export class AndroidHost implements DeviceHost {
  private readonly client: AdbServerClient;
  private readonly port: number;

  constructor(private readonly o: AndroidHostOptions) {
    this.port = o.port ?? (Number(process.env.ANDROID_ADB_SERVER_PORT) || 5037);
    this.client = new AdbServerClient(
      new AdbServerNodeTcpConnector({ host: "127.0.0.1", port: this.port }),
    );
  }

  private run(file: string, args: string[], timeoutMs = 30_000) {
    return new Promise<string>((resolve, reject) => {
      execFile(file, args, { timeout: timeoutMs, windowsHide: true }, (err, out, errOut) =>
        err
          ? reject(new Error(`${basename(file)}: ${(errOut || err.message).trim()}`))
          : resolve(out),
      );
    });
  }

  /** adb's server is there: started with the SDK's adb when it is not (someone opened a device). */
  private async server(): Promise<void> {
    try {
      await this.client.getVersion();
      return;
    } catch {}
    const { adb } = await this.o.tools();
    if (!adb) throw new Error("There is no adb on this machine (the SDK's platform-tools)");
    await this.run(adb, ["-P", String(this.port), "start-server"]);
  }

  async devices(): Promise<HostDevice[]> {
    await this.server();
    const list = await this.client.getDevices(["device", "unauthorized", "offline"]);
    const text = list
      .map((d) => `${d.serial} ${d.state}${d.model ? ` model:${d.model}` : ""}`)
      .join("\n");
    const out: HostDevice[] = [];
    for (const d of parseAdbDevices(text)) {
      let avd: string | undefined;
      if (d.kind === "emulator" && d.state === "device")
        avd =
          (
            await this.shell(d.serial, ["getprop", "ro.boot.qemu.avd_name"]).catch(() => "")
          ).trim() || undefined;
      out.push({
        serial: d.serial,
        kind: d.kind,
        state: d.state,
        ...(d.model && { model: d.model }),
        ...(d.link && { link: d.link }),
        ...(avd && { avd }),
      });
    }
    return out;
  }

  async boot(avd: string, signal?: AbortSignal): Promise<string> {
    if (!AVD_NAME.test(avd)) throw new Error("Not an AVD's name");
    const { emulator } = await this.o.tools();
    if (!emulator) throw new Error("The Android Emulator is not installed on this machine");
    await this.server();
    const already = (await this.devices()).find((d) => d.avd === avd);
    if (!already) {
      // No window (machines without a display too), no sound, the state not saved on exit.
      const p = spawn(
        emulator,
        ["-avd", avd, "-no-window", "-no-audio", "-no-boot-anim", "-no-snapshot-save"],
        { detached: true, stdio: "ignore", windowsHide: true },
      );
      p.on("error", () => {});
      p.unref();
    }
    const until = Date.now() + (this.o.bootMs ?? 240_000);
    while (Date.now() < until) {
      if (signal?.aborted) throw new Error("Stopped");
      const d = (await this.devices().catch(() => [])).find(
        (x) => x.avd === avd && x.state === "device",
      );
      if (
        d &&
        (await this.shell(d.serial, ["getprop", "sys.boot_completed"]).catch(() => "")).trim() ===
          "1"
      )
        return d.serial;
      await sleep(1500);
    }
    throw new Error(`${avd} did not finish starting in time`);
  }

  async stop(serial: string): Promise<void> {
    if (!/^emulator-\d+$/.test(serial)) throw new Error("Only emulators are switched off");
    const { adb } = await this.o.tools();
    if (!adb) throw new Error("There is no adb on this machine");
    await this.run(adb, ["-P", String(this.port), "-s", serial, "emu", "kill"]);
  }

  private adb(serial: string): Promise<Adb> {
    return this.client.createAdb({ serial });
  }

  async shell(serial: string, args: readonly string[]): Promise<string> {
    await this.server();
    const adb = await this.adb(serial);
    try {
      return await adb.subprocess.noneProtocol.spawnWaitText(args.map(escapeArg));
    } finally {
      await adb.close().catch(() => {});
    }
  }

  async install(serial: string, apk: string): Promise<string> {
    const bytes = new Uint8Array(await readFile(apk));
    const adb = await this.adb(serial);
    const remote = "/data/local/tmp/rasgeth-install.apk";
    try {
      const sync = await adb.sync();
      try {
        await sync.write({ filename: remote, file: one(bytes) });
      } finally {
        await sync.dispose();
      }
      const out = await adb.subprocess.noneProtocol.spawnWaitText(
        ["pm", "install", "-r", "-t", remote].map(escapeArg),
      );
      await adb.subprocess.noneProtocol
        .spawnWaitText(["rm", "-f", remote].map(escapeArg))
        .catch(() => "");
      return out.trim();
    } finally {
      await adb.close().catch(() => {});
    }
  }

  async screen(
    serial: string,
    onFrame: (f: DeviceFrame) => void,
    ended: (error?: string) => void,
    onVideo?: (p: VideoPacket) => void,
  ): Promise<DeviceScreen> {
    await this.server();
    const [jar, ffmpeg] = await Promise.all([scrcpyJar(), this.o.ffmpeg()]);
    const adb = await this.adb(serial);
    await AdbScrcpyClient.pushServer(adb, one(jar));
    const options = new AdbScrcpyOptions3_3_3(
      {
        audio: false,
        video: true,
        control: true,
        maxSize: 1280,
        maxFps: 30,
        videoBitRate: 4_000_000,
        clipboardAutosync: false,
        stayAwake: true,
        // Forward: works with adb's server on another machine too (a node, an ssh tunnel).
        tunnelForward: true,
        // Its own id: a screen left behind (a crash) never holds the next one's socket.
        scid: ScrcpyInstanceId.random(),
      },
      { version: "3.3.3" },
    );
    const sc = await AdbScrcpyClient.start(adb, DefaultServerPath, options);
    void sc.output.pipeTo(new WritableStream<string>({ write() {} })).catch(() => {});
    const video = await sc.videoStream;
    let done = false;
    const finish = (error?: string) => {
      if (done) return;
      done = true;
      decoder.close();
      ended(error);
    };
    const decoder = new H264ToJpeg(
      ffmpeg,
      () => ({ width: video.width, height: video.height }),
      onFrame,
      (why) => finish(why),
    );
    void video.stream
      .pipeTo(
        new WritableStream({
          write(p) {
            if (p.type === "configuration") decoder.configure(p.data);
            else decoder.data(p.data);
            onVideo?.({
              data: Buffer.from(p.data).toString("base64"),
              config: p.type === "configuration",
              key: p.type === "configuration" || p.keyframe === true,
              width: video.width,
              height: video.height,
            });
          },
        }),
      )
      .then(
        () => finish(),
        (e: unknown) => finish(e instanceof Error ? e.message : String(e)),
      );
    const ctl = sc.controller;
    if (!ctl) throw new Error("scrcpy started without control");
    const at = (x: number, y: number) => ({
      pointerX: Math.round(x * video.width),
      pointerY: Math.round(y * video.height),
      videoWidth: video.width,
      videoHeight: video.height,
    });
    const touch = (action: AndroidMotionEventAction, x: number, y: number) =>
      ctl.injectTouch({
        action,
        // A finger (phase 0): the mouse's id without a pressed button is ignored.
        pointerId: 0n,
        ...at(x, y),
        pressure: action === AndroidMotionEventAction.Up ? 0 : 1,
        actionButton: 0,
        buttons: 0,
      });
    const key = async (code: number) => {
      for (const action of [AndroidKeyEventAction.Down, AndroidKeyEventAction.Up])
        await ctl.injectKeyCode({
          action,
          keyCode: code as AndroidKeyCode,
          repeat: 0,
          metaState: 0,
        });
    };
    const input = async (e: DeviceInput): Promise<void> => {
      switch (e.kind) {
        case "tap":
          await touch(AndroidMotionEventAction.Down, e.x, e.y);
          await touch(AndroidMotionEventAction.Up, e.x, e.y);
          return;
        case "long":
          await touch(AndroidMotionEventAction.Down, e.x, e.y);
          await sleep(e.ms ?? 800);
          await touch(AndroidMotionEventAction.Up, e.x, e.y);
          return;
        case "swipe": {
          const steps = 10;
          const ms = e.ms ?? 300;
          await touch(AndroidMotionEventAction.Down, e.x, e.y);
          for (let i = 1; i <= steps; i++) {
            await sleep(ms / steps);
            await touch(
              AndroidMotionEventAction.Move,
              e.x + ((e.x2 - e.x) * i) / steps,
              e.y + ((e.y2 - e.y) * i) / steps,
            );
          }
          await touch(AndroidMotionEventAction.Up, e.x2, e.y2);
          return;
        }
        case "text":
          await ctl.injectText(e.text);
          return;
        case "key":
          await key(KEY_CODES[e.key] ?? 66);
          return;
        case "button":
          await key(KEY_CODES[e.button] ?? 4);
          return;
        case "rotate": {
          // The system's setting: portrait ↔ landscape (scrcpy's rotate does not turn an emulator).
          const now = (
            await this.shell(serial, ["settings", "get", "system", "user_rotation"]).catch(
              () => "0",
            )
          ).trim();
          await this.shell(serial, ["settings", "put", "system", "accelerometer_rotation", "0"]);
          await this.shell(serial, [
            "settings",
            "put",
            "system",
            "user_rotation",
            now === "0" ? "1" : "0",
          ]);
          return;
        }
      }
    };
    return {
      size: () => ({ width: video.width, height: video.height }),
      input,
      keyframe: async () => {
        await ctl.resetVideo().catch(() => {});
      },
      close: async () => {
        finish();
        await sc.close().catch(() => {});
        await adb.close().catch(() => {});
      },
    };
  }
}

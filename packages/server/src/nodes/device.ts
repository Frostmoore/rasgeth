// A machine's devices for the machines that may use it (3.11, phase 4): the `device` operation,
// on the node's own side. «use» is enough to look at and drive its devices (as its person would
// let an agent there do); the person of this machine keeps the upper hand: while they have control
// of a device here, gestures from another machine are refused. A screen goes in pieces (`chunk`:
// a frame or a state) until the asker stops it. Only the commands the agents' tools need run on a
// device (uiautomator's tree, starting an app, its log), never one an asker writes. Apps are
// installed from another machine on emulators only: a real phone's are its own machine's call.
import { mkdir, rm, writeFile } from "node:fs/promises";
import { join } from "node:path";
import { DeviceInput, isEmulatorId } from "@redgiant/protocol";
import type { DeviceAccess } from "../emulators/devices.js";
import { type NodeCaller, NodeError } from "./service.js";

const PACKAGE = /^[A-Za-z][\w]*(\.[A-Za-z][\w]*)+$/;
const COMPONENT = /^[A-Za-z][\w]*(\.[A-Za-z][\w]*)+\/[\w.$]+$/;
/** Pieces of an APK sent to a node: at most this big each, and in all. */
export const DEVICE_PIECE = 2 * 1024 * 1024;
const MAX_APK = 512 * 1024 * 1024;

/** The commands another machine may run on a device here: the agents' tools' own. Pure. */
export function deviceCommandAllowed(args: readonly unknown[]): boolean {
  const a = args.map(String);
  if (a.length !== args.length || a.some((x) => x.length > 300)) return false;
  const [p, ...r] = a;
  switch (p) {
    case "uiautomator":
      return r.length === 2 && r[0] === "dump" && r[1] === "/dev/tty";
    case "am":
      return r.length === 3 && r[0] === "start" && r[1] === "-n" && COMPONENT.test(r[2] ?? "");
    case "monkey":
      return (
        r.length === 5 &&
        r[0] === "-p" &&
        PACKAGE.test(r[1] ?? "") &&
        r[2] === "-c" &&
        r[3] === "android.intent.category.LAUNCHER" &&
        r[4] === "1"
      );
    case "pidof":
      return r.length === 1 && PACKAGE.test(r[0] ?? "");
    case "logcat":
      return (
        r.length === 4 &&
        r[0] === "-d" &&
        r[1] === "-t" &&
        /^\d{1,3}$/.test(r[2] ?? "") &&
        (r[3] === "*:W" || /^--pid=\d{1,7}$/.test(r[3] ?? ""))
      );
    default:
      return false;
  }
}

export interface NodeDeviceOptions {
  devices: () => DeviceAccess;
  /** Where APKs sent by other machines wait (one folder per asker). */
  dir: string;
  /** This machine lends its devices (the person may switch it off). */
  lends?: (ownerId: string) => boolean;
}

const safe = (fp: string) =>
  fp
    .replace(/^SHA256:/, "")
    .replace(/[^A-Za-z0-9]/g, "")
    .slice(0, 24);

export function nodeDeviceHandler(o: NodeDeviceOptions) {
  return async (c: NodeCaller, raw: unknown): Promise<unknown> => {
    if (o.lends && !o.lends(c.ownerId))
      throw new NodeError("refused", "This machine does not lend its devices now");
    const b = (raw ?? {}) as Record<string, unknown>;
    const d = o.devices();
    const id = typeof b.id === "string" && b.id.length <= 200 ? b.id : "";
    const needId = () => {
      if (!id) throw new NodeError("invalid", "Which device?");
      return id;
    };
    const wrap = async <T>(f: () => Promise<T>): Promise<T> => {
      try {
        return await f();
      } catch (e) {
        if (e instanceof NodeError) throw e;
        throw new NodeError("refused", e instanceof Error ? e.message : String(e));
      }
    };
    switch (b.action) {
      case "list":
        return { devices: await d.list() };
      case "ensure":
        await wrap(() => d.ensure(needId(), c.signal));
        return {};
      case "watch": {
        // Pieces until the asker stops (its cancel aborts the signal).
        const off = await d.watch(needId(), (e) => c.chunk(e));
        await new Promise<void>((resolve) => {
          if (c.signal.aborted) return resolve();
          c.signal.addEventListener("abort", () => resolve(), { once: true });
        });
        off();
        return {};
      }
      case "frame":
        return { frame: await wrap(() => d.frame(needId(), c.signal)) };
      case "input": {
        const e = DeviceInput.safeParse(b.event);
        if (!e.success) throw new NodeError("invalid", "Not a gesture");
        await wrap(() => d.input(needId(), e.data, "agents"));
        return {};
      }
      case "shell": {
        const args = Array.isArray(b.args) ? b.args : [];
        if (!deviceCommandAllowed(args))
          throw new NodeError("refused", "That command does not run on this machine's devices");
        return { out: await wrap(() => d.shell(needId(), args.map(String), c.signal)) };
      }
      case "put": {
        // A piece of an APK, in order; the first one starts the file again.
        const upload = typeof b.upload === "string" && /^[A-Za-z0-9-]{8,64}$/.test(b.upload) ? b.upload : "";
        const offset = Number(b.offset);
        const data = typeof b.data === "string" ? Buffer.from(b.data, "base64") : Buffer.alloc(0);
        if (!upload || !Number.isInteger(offset) || offset < 0 || offset + data.length > MAX_APK)
          throw new NodeError("invalid", "Not a piece of an APK");
        if (data.length > DEVICE_PIECE) throw new NodeError("invalid", "Piece too big");
        const dir = join(o.dir, safe(c.from));
        await mkdir(dir, { recursive: true });
        await writeFile(join(dir, `${upload}.apk`), data, { flag: offset === 0 ? "w" : "a" });
        return { offset: offset + data.length };
      }
      case "install": {
        const dev = needId();
        if (!isEmulatorId(dev))
          throw new NodeError(
            "refused",
            "Apps are installed on a real phone only from its own machine, by its person",
          );
        const upload = typeof b.upload === "string" && /^[A-Za-z0-9-]{8,64}$/.test(b.upload) ? b.upload : "";
        if (!upload) throw new NodeError("invalid", "Which APK?");
        const file = join(o.dir, safe(c.from), `${upload}.apk`);
        try {
          return { out: await wrap(() => d.install(dev, file, c.signal)) };
        } finally {
          await rm(file, { force: true }).catch(() => {});
        }
      }
      case "stop":
        await wrap(() => d.stop(needId()));
        return {};
      default:
        throw new NodeError("invalid", "Unknown device action");
    }
  };
}

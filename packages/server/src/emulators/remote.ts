// A node's devices used from this machine (3.11, phase 4), and every device one person can open:
// this machine's and those of its nodes that have emulators or phones, by one id (`<id>@<node>` for
// a node's). A node's screen comes through the node system in pieces (one frame each) while
// someone here looks; gestures, the agents' commands and an APK (in pieces) go back the same way.
// Who drives a node's device from here (the agents or the person) is kept here; the node's own
// person keeps the upper hand there.
import { execFile } from "node:child_process";
import { randomUUID } from "node:crypto";
import { readFile, stat } from "node:fs/promises";
import { basename, dirname } from "node:path";
import type { DeviceInput, EmuDeviceView } from "@redgiant/protocol";
import { DEVICE_PIECE } from "../nodes/device.js";
import type { Nodes } from "../nodes/service.js";
import { type DeviceAccess, DeviceError, type DeviceEvent, type Devices } from "./devices.js";
import type { DeviceFrame } from "./host.js";

type Ask = (
  body: Record<string, unknown>,
  o?: { onChunk?: (b: unknown) => void; signal?: AbortSignal; timeoutMs?: number },
) => Promise<unknown>;

interface Live {
  listeners: Set<(e: DeviceEvent) => void>;
  stop: AbortController;
  frame?: DeviceFrame;
  seq: number;
  state?: Extract<DeviceEvent, { type: "state" }>;
}

/** A folder as a tar archive (`tar` without a shell, the folder's own name first). */
export function tarFolder(dir: string): Promise<Buffer> {
  return new Promise((resolve, reject) => {
    execFile(
      "tar",
      ["-cf", "-", "-C", dirname(dir), basename(dir)],
      { encoding: "buffer", maxBuffer: 512 * 1024 * 1024, timeout: 120_000 },
      (e, out, err) =>
        e
          ? reject(new DeviceError(`tar: ${String(err || e.message).slice(0, 300)}`))
          : resolve(out),
    );
  });
}

/** One node's devices, through its `device` operation. */
export class RemoteDevices implements DeviceAccess {
  private readonly live = new Map<string, Live>();
  private readonly control = new Map<string, "agents" | "person">();
  private readonly queues = new Map<string, Promise<unknown>>();

  constructor(private readonly ask: Ask) {}

  async list(): Promise<EmuDeviceView[]> {
    const r = (await this.ask({ action: "list" }, { timeoutMs: 20_000 })) as {
      devices?: EmuDeviceView[];
    };
    return (r.devices ?? []).map((d) => ({ ...d, control: this.controlOf(d.id) }));
  }

  controlOf(id: string): "agents" | "person" {
    return this.control.get(id) ?? "agents";
  }

  setControl(id: string, who: "agents" | "person"): void {
    this.control.set(id, who);
    const l = this.live.get(id);
    if (l)
      for (const f of l.listeners)
        f({ type: "state", state: l.state?.state ?? "on", control: who });
  }

  async watch(id: string, listener: (e: DeviceEvent) => void): Promise<() => void> {
    let l = this.live.get(id);
    if (!l) {
      const entry: Live = { listeners: new Set(), stop: new AbortController(), seq: 0 };
      l = entry;
      this.live.set(id, entry);
      void this.ask(
        { action: "watch", id },
        {
          signal: entry.stop.signal,
          timeoutMs: 24 * 3600_000,
          onChunk: (b) => {
            const e = b as DeviceEvent;
            if (e?.type === "frame") {
              entry.frame = e.frame;
              entry.seq++;
            } else if (e?.type === "state") entry.state = e;
            const out: DeviceEvent = e.type === "state" ? { ...e, control: this.controlOf(id) } : e;
            for (const f of entry.listeners) f(out);
          },
        },
      ).catch((err: unknown) => {
        if (entry.stop.signal.aborted) return;
        this.live.delete(id);
        for (const f of entry.listeners)
          f({
            type: "state",
            state: "offline",
            control: this.controlOf(id),
            error: err instanceof Error ? err.message : String(err),
          });
      });
    }
    const entry = l;
    entry.listeners.add(listener);
    if (entry.frame) listener({ type: "frame", frame: entry.frame });
    return () => {
      entry.listeners.delete(listener);
      if (entry.listeners.size === 0) {
        this.live.delete(id);
        entry.stop.abort();
      }
    };
  }

  async input(id: string, e: DeviceInput, by: "person" | "agents"): Promise<void> {
    if (by === "person" && this.controlOf(id) !== "person")
      throw new DeviceError("Take control of the device first");
    if (by === "agents" && this.controlOf(id) === "person")
      throw new DeviceError(
        "The person has control of this device right now: try again later, or ask them",
      );
    await this.ask({ action: "input", id, event: e }, { timeoutMs: 30_000 });
  }

  async frame(id: string, signal?: AbortSignal): Promise<DeviceFrame> {
    const kept = this.live.get(id)?.frame;
    if (kept) return kept;
    const r = (await this.ask(
      { action: "frame", id },
      { timeoutMs: 300_000, ...(signal && { signal }) },
    )) as {
      frame?: DeviceFrame;
    };
    if (!r.frame) throw new DeviceError("The device's screen sent no picture");
    return r.frame;
  }

  seq(id: string): number | undefined {
    return this.live.get(id)?.seq;
  }

  async shell(id: string, args: readonly string[], signal?: AbortSignal): Promise<string> {
    const r = (await this.ask(
      { action: "shell", id, args: [...args] },
      { timeoutMs: 120_000, ...(signal && { signal }) },
    )) as {
      out?: string;
    };
    return r.out ?? "";
  }

  async install(id: string, apk: string, signal?: AbortSignal): Promise<string> {
    // An iOS app is a folder: it goes as a tar, which the node unpacks and installs.
    const folder = (await stat(apk).catch(() => null))?.isDirectory() ?? false;
    const bytes = folder ? await tarFolder(apk) : await readFile(apk);
    const upload = randomUUID();
    for (let offset = 0; offset === 0 || offset < bytes.length; offset += DEVICE_PIECE) {
      const piece = bytes.subarray(offset, offset + DEVICE_PIECE);
      await this.ask(
        {
          action: "put",
          upload,
          offset,
          data: piece.toString("base64"),
          ...(folder && { kind: "app" }),
        },
        { timeoutMs: 120_000, ...(signal && { signal }) },
      );
      if (bytes.length === 0) break;
    }
    const r = (await this.ask(
      { action: "install", id, upload },
      { timeoutMs: 600_000, ...(signal && { signal }) },
    )) as {
      out?: string;
    };
    return r.out ?? "";
  }

  async ensure(id: string, signal?: AbortSignal): Promise<void> {
    await this.ask({ action: "ensure", id }, { timeoutMs: 600_000, ...(signal && { signal }) });
  }

  async stop(id: string): Promise<void> {
    await this.ask({ action: "stop", id }, { timeoutMs: 60_000 });
  }

  exclusive<T>(id: string, f: () => Promise<T>): Promise<T> {
    const next = (this.queues.get(id) ?? Promise.resolve()).then(f, f);
    this.queues.set(
      id,
      next.catch(() => {}),
    );
    return next;
  }
}

/** `<id>@<node>` → the node and the node's own id; a plain id is this machine's. Pure. */
export function splitDeviceId(id: string): { id: string; node?: string } {
  const at = id.lastIndexOf("@");
  if (at <= 0 || at === id.length - 1) return { id };
  return { id: id.slice(0, at), node: id.slice(at + 1) };
}

/** Every device one person can open: this machine's and their nodes'. */
export class DeviceHub {
  private readonly remotes = new Map<string, RemoteDevices>();

  constructor(
    private readonly o: {
      local: Devices;
      nodes: Pick<Nodes, "known" | "request">;
    },
  ) {}

  private remote(ownerId: string, fp: string): RemoteDevices {
    const key = `${ownerId}\n${fp}`;
    let r = this.remotes.get(key);
    if (!r) {
      r = new RemoteDevices((body, o = {}) =>
        this.o.nodes.request(ownerId, fp, "device", body, {
          once: true,
          ...(o.timeoutMs !== undefined && { timeoutMs: o.timeoutMs }),
          ...(o.signal && { signal: o.signal }),
          ...(o.onChunk && { onChunk: o.onChunk }),
        }),
      );
      this.remotes.set(key, r);
    }
    return r;
  }

  /** One person's devices behind one face (`DeviceAccess`), ids of nodes' devices with `@<node>`. */
  of(ownerId: string): DeviceAccess {
    const local = this.o.local;
    const route = async (id: string): Promise<{ d: DeviceAccess; id: string }> => {
      const s = splitDeviceId(id);
      if (!s.node) return { d: local, id };
      const known = await this.o.nodes.known(ownerId).catch(() => []);
      if (!known.some((n) => n.fingerprint === s.node)) return { d: local, id };
      return { d: this.remote(ownerId, s.node), id: s.id };
    };
    const routeSync = (id: string): { d: DeviceAccess; id: string } => {
      const s = splitDeviceId(id);
      if (!s.node) return { d: local, id };
      const key = `${ownerId}\n${s.node}`;
      const r = this.remotes.get(key);
      return r ? { d: r, id: s.id } : { d: local, id };
    };
    const hub = this;
    return {
      async list() {
        const mine = await local.list();
        const known = await hub.o.nodes.known(ownerId).catch(() => []);
        const theirs = await Promise.all(
          known
            .filter((n) => n.online && n.view?.capabilities?.emulators)
            .map(async (n) =>
              (
                await hub
                  .remote(ownerId, n.fingerprint)
                  .list()
                  .catch(() => [] as EmuDeviceView[])
              ).map(
                (d): EmuDeviceView => ({
                  ...d,
                  id: `${d.id}@${n.fingerprint}`,
                  ...(d.serial && { serial: `${d.serial}@${n.fingerprint}` }),
                  machine: n.name,
                }),
              ),
            ),
        );
        return [...mine, ...theirs.flat()];
      },
      watch: async (id, listener, o) => {
        const r = await route(id);
        return r.d.watch(r.id, listener, o);
      },
      controlOf: (id) => {
        const r = routeSync(id);
        return r.d.controlOf(r.id);
      },
      setControl: (id, who) => {
        const r = routeSync(id);
        r.d.setControl(r.id, who);
      },
      input: async (id, e, by) => {
        const r = await route(id);
        return r.d.input(r.id, e, by);
      },
      frame: async (id, signal) => {
        const r = await route(id);
        return r.d.frame(r.id, signal);
      },
      seq: (id) => {
        const r = routeSync(id);
        return r.d.seq(r.id);
      },
      shell: async (id, args, signal) => {
        const r = await route(id);
        return r.d.shell(r.id, args, signal);
      },
      install: async (id, apk, signal) => {
        const r = await route(id);
        return r.d.install(r.id, apk, signal);
      },
      ensure: async (id, signal) => {
        const r = await route(id);
        return r.d.ensure(r.id, signal);
      },
      stop: async (id) => {
        const r = await route(id);
        return r.d.stop(r.id);
      },
      exclusive: (id, f) => local.exclusive(id, f),
    };
  }
}

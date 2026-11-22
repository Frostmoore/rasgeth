// The devices of this machine in the Canvas (3.11, phase 2): the AVDs (on or off), the emulators
// already running and the phones adb sees, each with one screen shared by whoever looks (the
// person's pages and apps, an agent's `device_look`) and who drives it now: the agents, or the
// person after «Take control» (their gestures are never logged). An AVD opened while off is started
// without a window, within the person's limit of emulators at once; the ones Rasgeth started are
// switched off after a while unused, never the person's own. Agents act one at a time.
import {
  DEFAULT_MAX_EMULATORS,
  type DeviceInput,
  type DeviceState,
  type EmuDeviceView,
} from "@redgiant/protocol";
import type { DeviceFrame, DeviceHost, DeviceScreen, HostDevice } from "./host.js";

export type DeviceEvent =
  | { type: "frame"; frame: DeviceFrame }
  | { type: "state"; state: DeviceState; control: "agents" | "person"; error?: string };
type Listener = (e: DeviceEvent) => void;

export class DeviceError extends Error {}

export interface DevicesOptions {
  host: DeviceHost;
  /** The AVDs of this machine (from Settings › Emulators' report). */
  avds: () => Promise<string[]>;
  maxRunning?: () => number;
  /** An emulator Rasgeth started is switched off after this long unused (default 15 minutes). */
  idleMs?: number;
  /** A screen nobody looks at closes after this long (default one minute). */
  screenIdleMs?: number;
  now?: () => number;
}

interface Live {
  serial: string;
  screen: DeviceScreen;
  frame?: DeviceFrame;
  firstFrame: Promise<void>;
}

const idOf = (d: HostDevice) => (d.kind === "emulator" && d.avd ? `avd:${d.avd}` : d.serial);
const stateOf = (d: HostDevice): DeviceState =>
  d.state === "device" ? "on" : d.state === "unauthorized" ? "unauthorized" : "offline";

export class Devices {
  private readonly listeners = new Map<string, Set<Listener>>();
  private readonly live = new Map<string, Promise<Live>>();
  private readonly control = new Map<string, "agents" | "person">();
  private readonly starting = new Set<string>();
  private readonly ours = new Set<string>();
  private readonly lastUse = new Map<string, number>();
  private readonly queues = new Map<string, Promise<unknown>>();
  /** Frames seen per device: what an agent's cached tree is checked against. */
  private readonly seqs = new Map<string, number>();
  private readonly timer: NodeJS.Timeout;

  constructor(private readonly o: DevicesOptions) {
    this.timer = setInterval(() => void this.sweep(), 15_000);
    this.timer.unref();
  }

  private now() {
    return (this.o.now ?? Date.now)();
  }

  /** How many frames the device's screen sent (undefined: no screen open). */
  seq(id: string): number | undefined {
    return this.live.has(id) ? (this.seqs.get(id) ?? 0) : undefined;
  }

  controlOf(id: string): "agents" | "person" {
    return this.control.get(id) ?? "agents";
  }

  /** AVDs (on or off), running emulators and phones, by a stable id. */
  async list(): Promise<EmuDeviceView[]> {
    const [attached, avds] = await Promise.all([
      this.o.host.devices().catch(() => [] as HostDevice[]),
      this.o.avds().catch(() => [] as string[]),
    ]);
    const out: EmuDeviceView[] = [];
    for (const d of attached) {
      const id = idOf(d);
      out.push({
        id,
        name: d.avd ?? d.model ?? d.serial,
        kind: d.kind,
        state: stateOf(d),
        serial: d.serial,
        ...(d.avd && { avd: d.avd }),
        ...(d.model && { model: d.model }),
        ...(d.link && { link: d.link }),
        ...(this.ours.has(d.serial) && { ours: true }),
        control: this.controlOf(id),
      });
    }
    for (const name of avds)
      if (!out.some((d) => d.avd === name))
        out.push({
          id: `avd:${name}`,
          name,
          kind: "emulator",
          state: this.starting.has(`avd:${name}`) ? "starting" : "off",
          avd: name,
          control: this.controlOf(`avd:${name}`),
        });
    return out;
  }

  private emit(id: string, e: DeviceEvent) {
    for (const l of this.listeners.get(id) ?? []) l(e);
  }

  private stateEvent(id: string, state: DeviceState, error?: string): DeviceEvent {
    return { type: "state", state, control: this.controlOf(id), ...(error && { error }) };
  }

  /** The device's serial, starting its AVD when it is off (within the limit). */
  async ensureOn(id: string, signal?: AbortSignal): Promise<string> {
    const attached = await this.o.host.devices();
    const found = attached.find((d) => idOf(d) === id || d.serial === id);
    if (found) {
      if (found.state === "unauthorized")
        throw new DeviceError(
          "The phone waits for the person's yes to this computer (on its screen)",
        );
      if (found.state !== "device") throw new DeviceError("The device does not answer adb now");
      return found.serial;
    }
    if (!id.startsWith("avd:"))
      throw new DeviceError("No such device: open device_list for the ids");
    const avd = id.slice(4);
    if (!(await this.o.avds()).includes(avd))
      throw new DeviceError(`There is no AVD named ${avd} here`);
    const running = attached.filter((d) => d.kind === "emulator").length;
    const max = this.o.maxRunning?.() ?? DEFAULT_MAX_EMULATORS;
    if (running >= max)
      throw new DeviceError(
        `At most ${max} emulators run at once on this machine (Settings › Emulators): switch one off first`,
      );
    this.starting.add(id);
    this.emit(id, this.stateEvent(id, "starting"));
    try {
      const serial = await this.o.host.boot(avd, signal);
      this.ours.add(serial);
      this.lastUse.set(serial, this.now());
      return serial;
    } finally {
      this.starting.delete(id);
    }
  }

  /** The shared screen, opened when needed. */
  private screenOf(id: string, signal?: AbortSignal): Promise<Live> {
    let p = this.live.get(id);
    if (!p) {
      p = (async () => {
        const serial = await this.ensureOn(id, signal);
        let first!: () => void;
        const firstFrame = new Promise<void>((r) => {
          first = r;
        });
        const entry: Live = { serial, screen: undefined as unknown as DeviceScreen, firstFrame };
        entry.screen = await this.o.host.screen(
          serial,
          (frame) => {
            entry.frame = frame;
            this.seqs.set(id, (this.seqs.get(id) ?? 0) + 1);
            first();
            this.emit(id, { type: "frame", frame });
          },
          (error) => {
            this.live.delete(id);
            this.emit(id, this.stateEvent(id, "offline", error ?? "The screen stopped"));
          },
        );
        this.emit(id, this.stateEvent(id, "on"));
        return entry;
      })();
      this.live.set(id, p);
      p.catch(() => this.live.delete(id));
    }
    this.touch(id);
    return p;
  }

  private touch(id: string) {
    this.lastUse.set(id, this.now());
  }

  /** Someone looks: frames and states until they stop. A device that is off is started. */
  async watch(id: string, listener: Listener): Promise<() => void> {
    const set = this.listeners.get(id) ?? new Set<Listener>();
    this.listeners.set(id, set);
    set.add(listener);
    const stop = () => {
      set.delete(listener);
      this.touch(id);
    };
    try {
      const live = await this.screenOf(id);
      listener(this.stateEvent(id, "on"));
      if (live.frame) listener({ type: "frame", frame: live.frame });
    } catch (e) {
      listener(this.stateEvent(id, "off", e instanceof Error ? e.message : String(e)));
    }
    return stop;
  }

  setControl(id: string, who: "agents" | "person"): void {
    this.control.set(id, who);
    this.emit(id, this.stateEvent(id, "on"));
  }

  /** A gesture: the person's only while they have control, an agent's only while they do not. */
  async input(id: string, e: DeviceInput, by: "person" | "agents"): Promise<void> {
    if (by === "person" && this.controlOf(id) !== "person")
      throw new DeviceError("Take control of the device first");
    if (by === "agents" && this.controlOf(id) === "person")
      throw new DeviceError(
        "The person has control of this device right now: try again later, or ask them",
      );
    const live = await this.screenOf(id);
    await live.screen.input(e);
    this.touch(id);
  }

  /** The screen now (JPEG), waiting a moment for the first frame. */
  async frame(id: string, signal?: AbortSignal): Promise<DeviceFrame> {
    const live = await this.screenOf(id, signal);
    await Promise.race([live.firstFrame, new Promise((r) => setTimeout(r, 8000))]);
    if (!live.frame) throw new DeviceError("The device's screen sent no picture");
    return live.frame;
  }

  async serial(id: string, signal?: AbortSignal): Promise<string> {
    const s = await this.ensureOn(id, signal);
    this.touch(id);
    return s;
  }

  get host(): DeviceHost {
    return this.o.host;
  }

  /** Switches an emulator off (the person's button, or Rasgeth's own after a while unused). */
  async stop(id: string): Promise<void> {
    const attached = await this.o.host.devices();
    const d = attached.find((x) => idOf(x) === id || x.serial === id);
    if (!d) return;
    if (d.kind !== "emulator") throw new DeviceError("A phone is not switched off from here");
    await this.closeScreen(id);
    await this.o.host.stop(d.serial);
    this.ours.delete(d.serial);
    this.emit(id, this.stateEvent(id, "off"));
  }

  private async closeScreen(id: string) {
    const p = this.live.get(id);
    this.live.delete(id);
    if (p) await (await p.catch(() => undefined))?.screen.close().catch(() => {});
  }

  /** Agents take turns on a device. */
  exclusive<T>(id: string, f: () => Promise<T>): Promise<T> {
    const prev = this.queues.get(id) ?? Promise.resolve();
    const next = prev.then(f, f);
    this.queues.set(
      id,
      next.catch(() => {}),
    );
    return next;
  }

  /** Screens nobody uses close; emulators Rasgeth started and nobody used are switched off. */
  async sweep(): Promise<void> {
    const t = this.now();
    for (const id of [...this.live.keys()])
      if (
        !this.listeners.get(id)?.size &&
        t - (this.lastUse.get(id) ?? 0) > (this.o.screenIdleMs ?? 60_000)
      )
        await this.closeScreen(id);
    const attached = await this.o.host.devices().catch(() => [] as HostDevice[]);
    for (const d of attached) {
      if (!this.ours.has(d.serial)) continue;
      const id = idOf(d);
      const used = Math.max(this.lastUse.get(id) ?? 0, this.lastUse.get(d.serial) ?? 0);
      if (!this.listeners.get(id)?.size && t - used > (this.o.idleMs ?? 15 * 60_000))
        await this.stop(id).catch(() => {});
    }
  }

  close(): void {
    clearInterval(this.timer);
  }
}

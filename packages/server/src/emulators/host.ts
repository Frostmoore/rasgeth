// What a machine does with Android devices (3.11, phase 2): the devices adb sees, starting and
// stopping an AVD, a device's screen (JPEG frames) and the person's or an agent's gestures, and the
// few commands the agents' tools need (uiautomator, logcat, an APK installed, an app launched).
// `AndroidHost` does it with adb and scrcpy (Tango); `FakeDeviceHost` acts it out for the tests.
import type { DeviceInput } from "@redgiant/protocol";

export interface DeviceFrame {
  /** JPEG, base64. */
  data: string;
  width: number;
  height: number;
}

/** One H.264 packet as scrcpy sent it (3.11 phase 7): Annex B, a configuration or a frame. */
export interface VideoPacket {
  /** base64 of the Annex B bytes. */
  data: string;
  /** SPS/PPS: a decoder starts (again) from it. */
  config: boolean;
  /** A key frame: a decoder may start from the configuration and it. */
  key: boolean;
  width: number;
  height: number;
}

/** A device adb sees now. */
export interface HostDevice {
  serial: string;
  kind: "emulator" | "phone";
  state: "device" | "unauthorized" | "offline" | "other";
  model?: string;
  /** For an emulator: its AVD. */
  avd?: string;
  link?: "usb" | "wifi";
}

/** A device's screen while someone looks at it or works on it. */
export interface DeviceScreen {
  size(): { width: number; height: number };
  input(e: DeviceInput): Promise<void>;
  /** Asks the device for a key frame soon (someone started watching the H.264). */
  keyframe?(): Promise<void>;
  close(): Promise<void>;
}

export interface DeviceHost {
  devices(): Promise<HostDevice[]>;
  /** Starts an AVD without a window and waits until Android has started; its serial. */
  boot(avd: string, signal?: AbortSignal): Promise<string>;
  stop(serial: string): Promise<void>;
  /** The screen: frames arrive at most about 15 a second; `ended` when it stops by itself. */
  screen(
    serial: string,
    onFrame: (f: DeviceFrame) => void,
    ended: (error?: string) => void,
    /** 3.11 phase 7: the H.264 itself, for pages that decode it (WebCodecs). */
    onVideo?: (p: VideoPacket) => void,
  ): Promise<DeviceScreen>;
  /** A command on the device (`args` are passed one by one, never through a shell string). */
  shell(serial: string, args: readonly string[]): Promise<string>;
  /** An APK of this machine installed on the device; adb's answer. */
  install(serial: string, apk: string): Promise<string>;
}

/** Android's key codes for the keys and buttons the page and the tools send. */
export const KEY_CODES: Record<string, number> = {
  Enter: 66,
  Backspace: 67,
  Delete: 112,
  Tab: 61,
  Escape: 111,
  Space: 62,
  ArrowUp: 19,
  ArrowDown: 20,
  ArrowLeft: 21,
  ArrowRight: 22,
  back: 4,
  home: 3,
  recents: 187,
  power: 26,
  volume_up: 24,
  volume_down: 25,
};

/** The fake for tests: a phone, an emulator running and an AVD that boots; every call recorded. */
export class FakeDeviceHost implements DeviceHost {
  readonly calls: string[] = [];
  readonly inputs: { serial: string; event: DeviceInput }[] = [];
  attached: HostDevice[] = [
    {
      serial: "emulator-5554",
      kind: "emulator",
      state: "device",
      avd: "Pixel_8",
      model: "sdk gphone64",
    },
    { serial: "R58N12ABCDE", kind: "phone", state: "device", link: "usb", model: "SM A525F" },
  ];
  /** What `shell` answers, by the first argument (`uiautomator`, `logcat`, `pm`…). */
  answers: Record<string, string> = {};
  /** Frames sent by an open screen (each `frame()` call sends one). */
  private readonly open = new Map<string, (f: DeviceFrame) => void>();
  private readonly video = new Map<string, (p: VideoPacket) => void>();

  /** Sends an H.264 packet to an open screen. */
  packet(serial: string, p: Partial<VideoPacket> = {}): void {
    this.video.get(serial)?.({
      data: "AAAA",
      config: false,
      key: false,
      width: 576,
      height: 1280,
      ...p,
    });
  }
  private next = 5556;

  /** `frame`: the picture every screen sends (base64 JPEG; the demo gives a real one). */
  constructor(private readonly picture = "AAAA") {}

  async devices(): Promise<HostDevice[]> {
    return this.attached.map((d) => ({ ...d }));
  }

  async boot(avd: string): Promise<string> {
    this.calls.push(`boot ${avd}`);
    const serial = `emulator-${this.next}`;
    this.next += 2;
    this.attached.push({ serial, kind: "emulator", state: "device", avd });
    return serial;
  }

  async stop(serial: string): Promise<void> {
    this.calls.push(`stop ${serial}`);
    this.attached = this.attached.filter((d) => d.serial !== serial);
  }

  async screen(
    serial: string,
    onFrame: (f: DeviceFrame) => void,
    _ended?: (error?: string) => void,
    onVideo?: (p: VideoPacket) => void,
  ): Promise<DeviceScreen> {
    this.calls.push(`screen ${serial}`);
    this.open.set(serial, onFrame);
    if (onVideo) this.video.set(serial, onVideo);
    onFrame({ data: this.picture, width: 576, height: 1280 });
    return {
      keyframe: async () => {
        this.calls.push(`keyframe ${serial}`);
        this.video.get(serial)?.({
          data: "S0VZ",
          config: false,
          key: true,
          width: 576,
          height: 1280,
        });
      },
      size: () => ({ width: 576, height: 1280 }),
      input: async (event) => {
        this.inputs.push({ serial, event });
      },
      close: async () => {
        this.calls.push(`close ${serial}`);
        this.open.delete(serial);
      },
    };
  }

  /** Sends a frame to an open screen. */
  frame(serial: string, data = this.picture): void {
    this.open.get(serial)?.({ data, width: 576, height: 1280 });
  }

  isOpen(serial: string): boolean {
    return this.open.has(serial);
  }

  async shell(serial: string, args: readonly string[]): Promise<string> {
    this.calls.push(`shell ${serial} ${args.join(" ")}`);
    return this.answers[args[0] ?? ""] ?? "";
  }

  async install(serial: string, apk: string): Promise<string> {
    this.calls.push(`install ${serial} ${apk}`);
    return "Success";
  }
}

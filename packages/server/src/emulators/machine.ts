// This machine's emulators (3.11): the report of `detectEmulators`, measured once and kept for a
// minute (Settings › Emulators can ask again), with the machine's own settings (the SDK folder the
// person chose, how many emulators at once). The same report answers a node's capabilities.
import {
  DEFAULT_MAX_EMULATORS,
  type EmulatorReport,
  EmulatorSettings,
  type EmuOs,
} from "@redgiant/protocol";
import { detectEmulators, type EmulatorFacts } from "./detect.js";
import { gatherEmulatorFacts, looksLikeSdk, osOf } from "./gather.js";

const FRESH_MS = 60_000;

/** Where the settings are kept: one value for the machine (`rg_settings`, `OwnerSettings`). */
export interface EmulatorSettingsStore {
  get(): EmulatorSettings;
  set(v: EmulatorSettings): Promise<EmulatorSettings>;
}

/** Kept in memory (tests, and a server without a database). */
export function memorySettings(start?: Partial<EmulatorSettings>): EmulatorSettingsStore {
  let v = EmulatorSettings.parse(start ?? {});
  return {
    get: () => v,
    set: async (n) => {
      v = EmulatorSettings.parse(n);
      return v;
    },
  };
}

export class EmulatorSettingsError extends Error {}

export interface EmulatorMachineOptions {
  settings: EmulatorSettingsStore;
  /** Tests: the facts instead of reading the machine. */
  gather?: (o: {
    custom: string | null;
    maxRunning: number;
    iosBridgeDir?: string;
  }) => Promise<EmulatorFacts>;
  /** Where the iOS bridge is installed (3.12.2): a folder of Rasgeth's own. */
  iosBridgeDir?: string;
  /** Tests: whether a folder is an SDK. */
  isSdk?: (path: string) => Promise<boolean>;
  os?: EmuOs;
  now?: () => number;
}

export class EmulatorMachine {
  private last: { at: number; value: Promise<EmulatorReport> } | undefined;

  constructor(private readonly o: EmulatorMachineOptions) {}

  /** The folder of the iOS bridge (undefined in tests without one). */
  get iosBridgeDir(): string | undefined {
    return this.o.iosBridgeDir;
  }

  settings(): EmulatorSettings {
    return this.o.settings.get();
  }

  report(fresh = false): Promise<EmulatorReport> {
    const now = (this.o.now ?? Date.now)();
    if (!fresh && this.last && now - this.last.at < FRESH_MS) return this.last.value;
    const s = this.settings();
    const value = (this.o.gather ?? gatherEmulatorFacts)({
      custom: s.sdkPath,
      maxRunning: s.maxRunning ?? DEFAULT_MAX_EMULATORS,
      ...(this.o.iosBridgeDir && { iosBridgeDir: this.o.iosBridgeDir }),
    }).then(detectEmulators);
    // A failed look is not kept: the next one tries again.
    value.catch(() => {
      if (this.last?.value === value) this.last = undefined;
    });
    this.last = { at: now, value };
    return value;
  }

  /**
   * The person's choices. A folder must be absolute and hold an SDK (platform-tools, emulator,
   * cmdline-tools or system-images); `null` forgets it.
   */
  async update(b: { sdkPath?: string | null | undefined; maxRunning?: number | undefined }) {
    const cur = this.settings();
    let sdkPath = cur.sdkPath;
    if (b.sdkPath !== undefined) {
      const p = b.sdkPath?.trim() || null;
      if (p !== null) {
        const os = this.o.os ?? osOf();
        const absolute = os === "windows" ? /^([A-Za-z]:[\\/]|\\\\)/.test(p) : p.startsWith("/");
        if (!absolute) throw new EmulatorSettingsError("The folder must be a full path");
        if (!(await (this.o.isSdk ?? ((x: string) => looksLikeSdk(x, os)))(p)))
          throw new EmulatorSettingsError(
            "No Android SDK in that folder (no platform-tools, emulator, cmdline-tools or system-images)",
          );
      }
      sdkPath = p;
    }
    const next = await this.o.settings.set({ sdkPath, maxRunning: b.maxRunning ?? cur.maxRunning });
    this.last = undefined;
    return next;
  }
}

/** The settings are the machine's, not a person's: one row under this owner. */
export const EMULATOR_SETTINGS_OWNER = "machine";

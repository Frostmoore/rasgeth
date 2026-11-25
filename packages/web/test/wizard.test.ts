import { DANGER_IDS } from "@redgiant/protocol";
import { beforeEach, describe, expect, it } from "vitest";
import type { SetupState } from "../src/api.js";
import { localModelName } from "../src/format.js";
import { lang } from "../src/i18n.js";
import {
  diskTiles,
  gainText,
  MOE_PREFETCH_IMAGE_SIZE,
  MOE_PREFETCH_SIZE,
  moePrefetchTexts,
  PRESETS,
  presetOf,
  recap,
  skippable,
  stepAfter,
  stepsFor,
  stepsOf,
  suggestModel,
  sysmemAdviceDue,
} from "../src/wizard.js";

beforeEach(() => {
  lang.value = "it";
});

const hw = (o: Partial<SetupState["hardware"]> = {}) =>
  ({
    os: "win32",
    cpu: "AMD Ryzen 9 9900X",
    cores: 24,
    ramGb: 63.6,
    diskFreeGb: 1188.5,
    gpus: [],
    suggestion: { engine: "windows", maxModelGb: 12.8, kind: "gpu", vramGb: 16 },
    ...o,
  }) as SetupState["hardware"];

describe("the wizard's steps (2026-11-06)", () => {
  it("adds where the code lives only for the advanced mode; access from outside for everyone (G39.3)", () => {
    const standard = stepsFor("standard");
    expect(standard).toEqual(stepsFor(undefined));
    expect(standard).not.toContain("wzCode");
    expect(standard.slice(0, 5)).toEqual([
      "wzWelcome",
      "wzRole",
      "wzAccount",
      "wzMachine",
      "wzMode",
    ]);
    const advanced = stepsFor("advanced");
    expect(advanced.slice(advanced.indexOf("wzTelegram"), -1)).toEqual([
      "wzTelegram",
      "wzStorage",
      "wzCode",
      "wzRemote",
      "wzSafety",
    ]);
    expect(stepAfter(advanced, "wzStorage")).toBe("wzCode");
    expect(stepAfter(standard, "wzStorage")).toBe("wzRemote");
    expect(stepAfter(standard, "wzDone")).toBe("wzDone");
    expect(standard.filter((k) => skippable(k))).toEqual([
      "wzAccount",
      "wzBrain",
      "wzLocal",
      "wzImport",
      "wzTelegram",
      "wzStorage",
      "wzRemote",
    ]);
    // Coming from another agent? (G36.7): optional, right after the agents are named.
    expect(stepAfter(standard, "wzAssign")).toBe("wzImport");
    expect(skippable("wzSafety")).toBe(false);
  });

  it("a node has only its own few steps; local models are not offered where none fits (G39.3)", () => {
    expect(stepsFor("advanced", { role: "node" })).toEqual([
      "wzWelcome",
      "wzRole",
      "wzAccount",
      "wzMachine",
      "wzDone",
    ]);
    expect(stepsFor("standard", { local: false })).not.toContain("wzLocal");
    expect(stepsFor("standard", { local: true })).toContain("wzLocal");
    expect(stepsOf({ config: { role: "node" } })).toHaveLength(5);
    expect(stepsOf({ config: {}, offer: { local: false } })).not.toContain("wzLocal");
  });

  it("does not ask again for the password the first access chose (G39.7)", () => {
    expect(stepsOf({ config: {} }, { password: true })).not.toContain("wzAccount");
    expect(stepsOf({ config: { role: "node" } }, { password: true })).toEqual([
      "wzWelcome",
      "wzRole",
      "wzMachine",
      "wzDone",
    ]);
    expect(stepsOf({ config: {} }, { password: false })).toContain("wzAccount");
  });

  it("the password step cannot be skipped after signing in with the setup code (G39.3)", () => {
    expect(skippable("wzAccount")).toBe(true);
    expect(skippable("wzAccount", { mustSetPassword: true })).toBe(false);
    expect(skippable("wzStorage", { mustSetPassword: true })).toBe(true);
  });

  it("knows a ready choice of approvals in any order, and a choice of one's own", () => {
    expect(presetOf([...PRESETS.balanced].reverse())).toBe("balanced");
    expect(presetOf(DANGER_IDS)).toBe("careful");
    expect(presetOf(["platform"])).toBeUndefined();
  });

  it("suggests the strongest model for who decides and a fast one for who answers", () => {
    const models = [
      { provider: "openai", model: "gpt-5-mini", effort: true },
      { provider: "claude-subscription", model: "claude-haiku-4-5", effort: false },
      { provider: "claude-subscription", model: "claude-opus-4-1", effort: true },
      { provider: "local", model: "gemma.gguf", effort: false },
    ];
    expect(suggestModel(models, "strong")).toEqual({
      provider: "claude-subscription",
      model: "claude-opus-4-1",
      effort: "high",
    });
    // A model on this computer first: free and always there.
    expect(suggestModel(models, "fast")).toEqual({ provider: "local", model: "gemma.gguf" });
    expect(suggestModel(models.slice(0, 3), "fast")?.model).toBe("claude-haiku-4-5");
    // The backup model: best from another provider.
    expect(suggestModel(models, "strong", "claude-subscription")?.provider).toBe("openai");
    expect(suggestModel([], "strong")).toBeNull();
  });

  it("shows the disks for the models, the one in use lit, moving only on Windows SSDs", () => {
    const disks = [
      { name: "C", ssd: true, bus: "nvme", freeGb: 1188.5, totalGb: 1863 },
      { name: "F", ssd: false, bus: "sata", freeGb: 2410, totalGb: 3726 },
    ];
    const tiles = diskTiles(hw({ disks, modelDisk: { windows: "C" }, onWindows: true }), "windows");
    expect(tiles.map((d) => [d.label, d.here, d.canMove, d.hdd])).toEqual([
      ["C:", true, true, false],
      ["F:", false, false, true],
    ]);
    expect(tiles[0]?.kind).toBe("SSD NVME");
    expect(tiles[0]?.usedPct).toBe(36);
    // Elsewhere: the one disk of RedGiant's data, with its free room, nothing to move.
    const one = diskTiles(hw({ os: "linux" }), "cuda");
    expect(one).toHaveLength(1);
    expect(one[0]).toMatchObject({ label: "Questo disco", freeGb: 1188.5, canMove: false });
  });

  it("sums up what was set, each square opening its step", () => {
    const s = {
      config: {
        completed: false,
        subscriptions: { claude: true },
        engine: { variant: "windows", model: "Qwen3.6-35B.gguf" },
      },
      secretsSet: { keys: ["openai"], server: false, telegram: false },
      locked: {},
      hardware: hw({ modelDisk: { windows: "E" } }),
      names: { god: "Zeus", demigod: "Ermes", godPrompt: null },
      policy: { humanOnly: [...PRESETS.careful], disabledDanger: [], dangers: [] },
      budgetUsd: 20,
    } as unknown as SetupState;
    const items = recap(s, { models: 5, godModel: "Opus 4.1", telegramUser: null }, (id) =>
      id === "openai" ? "OpenAI" : id,
    );
    expect(items.map((x) => x.step)).toEqual([
      "wzBrain",
      "wzLocal",
      "wzNames",
      "wzTelegram",
      "wzSafety",
      "wzSafety",
    ]);
    expect(items[0]).toMatchObject({
      value: "Claude, OpenAI, un modello su questo computer",
      sub: "5 modelli disponibili",
    });
    expect(items[1]).toMatchObject({ value: "Qwen3.6-35B", sub: "in uso, su E:" });
    expect(items[2]).toMatchObject({ value: "Zeus e Ermes", sub: "Zeus pensa con Opus 4.1" });
    expect(items[3]).toMatchObject({ value: "Non ancora", on: false });
    expect(items[4]?.value).toBe("Prudente");
    expect(items[5]?.value).toBe("Al massimo $20");
  });
});

describe("the options next to SSD stream (G32.1)", () => {
  const nvidia = [{ name: "RTX 4080 Super", vramGb: 16, vendor: "nvidia", integrated: false }];
  it("each engine says what its patched build downloads", () => {
    expect(moePrefetchTexts("cuda").help).toContain(MOE_PREFETCH_IMAGE_SIZE);
    expect(moePrefetchTexts("cuda").help).toContain("Docker");
    expect(moePrefetchTexts("windows").help).toContain(MOE_PREFETCH_SIZE);
    expect(moePrefetchTexts("cuda").missing).not.toBe(moePrefetchTexts("windows").missing);
  });

  it("says a gain as a percentage (p3.12.6)", () => {
    expect(gainText(2.88, 3.21)).toBe("+11%");
    expect(gainText(10, 9)).toBe("-10%");
    expect(gainText(5, 5)).toBe("0%");
    expect(gainText(0, 5)).toBe("");
  });

  it("NVIDIA's Sysmem Fallback advice: Windows, an NVIDIA card, SSD stream on, until closed", () => {
    const win = hw({ onWindows: true, gpus: nvidia } as Partial<SetupState["hardware"]>);
    expect(sysmemAdviceDue(win, "windows", true, false)).toBe(true);
    // The engines in Docker on Windows go through the same driver.
    expect(sysmemAdviceDue(win, "cuda", true, false)).toBe(true);
    expect(sysmemAdviceDue(win, "windows", true, true)).toBe(false);
    expect(sysmemAdviceDue(win, "windows", false, false)).toBe(false);
    expect(sysmemAdviceDue(win, "cpu", true, false)).toBe(false);
    const linux = hw({ onWindows: false, windowsEngine: false, gpus: nvidia } as Partial<
      SetupState["hardware"]
    >);
    expect(sysmemAdviceDue(linux, "cuda", true, false)).toBe(false);
    const amd = hw({
      onWindows: true,
      gpus: [{ name: "RX 7900", vramGb: 24, vendor: "amd", integrated: false }],
    } as Partial<SetupState["hardware"]>);
    expect(sysmemAdviceDue(amd, "windows", true, false)).toBe(false);
    const laptop = hw({
      onWindows: true,
      gpus: [{ name: "Intel Iris", vramGb: 0, vendor: "nvidia", integrated: true }],
    } as Partial<SetupState["hardware"]>);
    expect(sysmemAdviceDue(laptop, "windows", true, false)).toBe(false);
  });
});

describe("local model names (p3.3.1)", () => {
  it("shows a readable name, never the path", () => {
    expect(
      localModelName(
        "C:\\Users\\Pixel\\AppData\\Local\\Rasgeth\\engine\\models\\GLM-4.5-Air-Q4_K_S-00001-of-00002.gguf",
      ),
    ).toBe("GLM-4.5 Air Q4_K_S");
    expect(localModelName("/data/models/Qwen3-30B-A3B-Instruct-2507-Q4_K_M.gguf")).toBe(
      "Qwen3-30B A3B Instruct-2507 Q4_K_M",
    );
    expect(localModelName("gemma-3-12b-it-Q4_K_M.gguf")).toBe("gemma-3-12b it Q4_K_M");
    expect(localModelName("gpt-5")).toBe("gpt-5");
  });
});

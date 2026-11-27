// @vitest-environment jsdom
// The «Improvements» of a local model's card (p3.12.6): the section and its warning, a card dimmed
// with its reason, a gold card for what we tried ourselves, and the choices going with the start.
import { LOCAL_MODELS } from "@redgiant/protocol";
import { cleanup, fireEvent, render, waitFor } from "@testing-library/preact";
import { afterEach, beforeEach, describe, expect, it, vi } from "vitest";
import type { LocalModelChoice, SetupState } from "../src/api.js";
import { lang } from "../src/i18n.js";

const calls: { name: string; args: unknown[] }[] = [];
let choices: LocalModelChoice[] = [];
const fakeApi = new Proxy(
  {},
  {
    get: (_t, name: string) => {
      if (name === "then") return undefined;
      return (...args: unknown[]) => {
        calls.push({ name, args });
        if (name === "localModels")
          return Promise.resolve({
            models: choices,
            files: choices.flatMap((m) =>
              m.file ? [{ file: m.file.file, bytes: m.file.sizeGb * 1e9, partial: false }] : [],
            ),
            diskFreeGb: 400,
          });
        if (name === "jobs") return Promise.resolve([]);
        if (name === "improvementTest") return Promise.resolve({ id: "j1" });
        if (name === "job")
          return Promise.resolve({
            id: "j1",
            kind: "improvement_test",
            state: "running",
            steps: [],
            vars: {},
          });
        if (name === "setupEngine") return Promise.resolve({ id: "e1" });
        // 3.12.10: 16k in a 16 GB card, 32k with the recommended engine's passes.
        if (name === "contextInfo")
          return Promise.resolve({ trained: 1048576, inCard: args[3] ? 32768 : 16384 });
        return Promise.resolve({});
      };
    },
  },
);
vi.mock("../src/state.js", async (orig) => ({
  ...(await orig<typeof import("../src/state.js")>()),
  getApi: () => fakeApi,
}));

const { LocalModels } = await import("../src/components/LocalModels.js");
const { Dialogs } = await import("../src/components/dialogs.js");

const state = (engine?: Record<string, unknown>, tests: unknown[] = []) =>
  ({
    config: {
      completed: true,
      ...(engine && { engine: { variant: "cuda", model: "other.gguf", ...engine } }),
      improvementTests: tests,
    },
    secretsSet: { keys: [], server: false, telegram: false },
    locked: {},
    providers: [],
    hardware: {
      os: "linux",
      cpu: "Intel i5-12500H",
      cores: 12,
      ramGb: 64,
      freeRamGb: 40,
      diskFreeGb: 500,
      disks: [{ name: "/", ssd: true, bus: "nvme", freeGb: 500, totalGb: 1000 }],
      modelDisk: { docker: "/" },
      gpus: [{ name: "NVIDIA GeForce RTX 4080", vramGb: 16, vendor: "nvidia", integrated: false }],
      dockerGpu: true,
      gpuAccess: "",
      windowsEngine: false,
      suggestion: { engine: "cuda", maxModelGb: 12.8, kind: "gpu", vramGb: 16 },
    },
    names: { god: null, demigod: null, godPrompt: null },
    policy: { humanOnly: [], disabledDanger: [], dangers: [] },
    budgetUsd: null,
    canRunSearch: true,
    moePrefetch: null,
    moePrefetchImage: "available",
  }) as unknown as SetupState;

const entry = (id: string, over: Partial<LocalModelChoice> = {}): LocalModelChoice => {
  const m = LOCAL_MODELS.find((x) => x.id === id);
  if (!m) throw new Error(id);
  return {
    ...m,
    file: { file: `${id}-Q4.gguf`, sizeGb: 10, quant: "Q4_K_M", quality: "good" },
    smallestGb: 10,
    improvements: [
      { id: "prefetch", available: false, reason: "needMoe" },
      { id: "bigChunks", available: false, reason: "needMoe" },
      { id: "speculative", available: true, draft: false },
      { id: "noRepack", available: true },
    ],
    ...over,
  };
};

const open = async (r: ReturnType<typeof render>, name: string) => {
  await waitFor(() => expect(r.getAllByText(name).length).toBeGreaterThan(0));
  fireEvent.click(r.getAllByText(name)[0] as HTMLElement);
};
const card = (id: string) => document.querySelector(`[data-improvement="${id}"]`) as HTMLElement;
const startButton = (r: ReturnType<typeof render>) =>
  r
    .getAllByRole("button")
    .find((b: HTMLElement) => (b.textContent ?? "").trim() === "Avvia") as HTMLElement;

beforeEach(() => {
  lang.value = "it";
  calls.length = 0;
  Element.prototype.scrollIntoView = vi.fn();
});
afterEach(cleanup);

describe("Improvements in the model's card (p3.12.6)", () => {
  it("shows the section with its warning and the four improvements by name", async () => {
    choices = [entry("qwen3.8-27b")];
    const r = render(<LocalModels s={state()} reload={() => {}} />);
    await open(r, "Qwen3.8 27B");
    expect(r.getByText("Miglioramenti")).toBeTruthy();
    expect(r.getByText(/Si accendono a mano, uno per uno/)).toBeTruthy();
    expect(r.getByText(/può dare zero guadagno o anche peggiorare le cose/)).toBeTruthy();
    for (const name of ["Prefetch", "Big Chunks", "Speculative Decoding", "No Repack"])
      expect(r.getByText(name)).toBeTruthy();
    expect(r.getByText("i pesi come sono nel file, senza riordinarli")).toBeTruthy();
    // Never a native checkbox or radio: our switches.
    expect(document.querySelectorAll("input[type=checkbox], input[type=radio]")).toHaveLength(0);
  });

  it("names the SSD streaming Deep Field in the computer's box", async () => {
    choices = [entry("qwen3.8-27b")];
    const r = render(<LocalModels s={state()} reload={() => {}} />);
    expect(r.container.textContent).toContain("lo streaming dall'SSD di Rasgeth");
    // The old switches left the computer's box.
    expect(r.queryByText("Strato dopo in anticipo")).toBeNull();
    expect(r.queryByText("Blocchi grandi")).toBeNull();
  });

  it("dims a card that cannot be used, with a switch off and disabled and the reason", async () => {
    choices = [entry("qwen3.8-27b")];
    const r = render(<LocalModels s={state()} reload={() => {}} />);
    await open(r, "Qwen3.8 27B");
    const prefetch = card("prefetch");
    expect(prefetch.classList.contains("off")).toBe(true);
    const sw = prefetch.querySelector("[role=switch]") as HTMLButtonElement;
    expect(sw.disabled).toBe(true);
    expect(sw.getAttribute("aria-checked")).toBe("false");
    expect(prefetch.textContent).toMatch(/Spento: funziona solo con i modelli a esperti/);
    expect(prefetch.querySelector(".impr-lock svg")).toBeTruthy();
    // The ones that always work are not dimmed.
    expect(card("noRepack").classList.contains("off")).toBe(false);
  });

  it("names the card in the NVIDIA reason, or says it has only the integrated graphics", async () => {
    choices = [
      entry("qwen3.8-27b", {
        improvements: [
          { id: "prefetch", available: false, reason: "needNvidia", gpu: "Radeon RX 7800" },
          { id: "bigChunks", available: false, reason: "needGpu" },
          { id: "speculative", available: true },
          { id: "noRepack", available: true },
        ],
      }),
    ];
    const r = render(<LocalModels s={state()} reload={() => {}} />);
    await open(r, "Qwen3.8 27B");
    expect(card("prefetch").textContent).toContain(
      "Spento: serve una scheda video NVIDIA. Questo computer ha Radeon RX 7800.",
    );
    expect(card("bigChunks").textContent).toContain("solo la grafica integrata");
    cleanup();
    choices = [
      entry("qwen3.8-27b", {
        improvements: [
          { id: "prefetch", available: false, reason: "needNvidia" },
          { id: "bigChunks", available: true },
          { id: "speculative", available: true },
          { id: "noRepack", available: true },
        ],
      }),
    ];
    const again = render(<LocalModels s={state()} reload={() => {}} />);
    await open(again, "Qwen3.8 27B");
    expect(card("prefetch").textContent).toContain("Questo computer ha solo la grafica integrata.");
  });

  it("draws a gold card, with the star and the numbers, for what we tried ourselves", async () => {
    choices = [entry("qwen3.8-27b")];
    const r = render(<LocalModels s={state()} reload={() => {}} />);
    await open(r, "Qwen3.8 27B");
    const gold = card("noRepack");
    expect(gold.classList.contains("gold")).toBe(true);
    expect(gold.textContent).toContain("Provato da noi su questo modello");
    expect(gold.textContent).toContain("Scrittura da 2,88 a 3,21 token/s (+11%). Intel i5-12500H.");
    expect(gold.querySelector(".impr-star svg")).toBeTruthy();
    // Nothing else is gold: only what was measured (No Repack and the model's MTP).
    expect(document.querySelectorAll(".impr-card.gold")).toHaveLength(2);
    const spec = card("speculative");
    expect(spec.classList.contains("gold")).toBe(true);
    expect(spec.textContent).toContain(
      "Con l'MTP del modello. Scrittura da 2,98 a 3,88 token/s (+30%). Intel i5-12500H.",
    );
  });

  it("offers the model's MTP only where the model has it, and starts with it", async () => {
    choices = [
      entry("qwen3.8-27b", {
        improvements: [
          { id: "prefetch", available: false, reason: "needMoe" },
          { id: "bigChunks", available: false, reason: "needMoe" },
          { id: "speculative", available: true, draft: false, mtp: true },
          { id: "noRepack", available: true },
        ],
      }),
    ];
    const r = render(<LocalModels s={state()} reload={() => {}} />);
    await open(r, "Qwen3.8 27B");
    const choice = Array.from(card("speculative").querySelectorAll("button")).find(
      (b) => b.textContent === "MTP del modello",
    ) as HTMLElement;
    expect(choice).toBeTruthy();
    fireEvent.click(choice);
    expect(card("speculative").textContent).toContain("nessun secondo modello");
    fireEvent.click(startButton(r));
    const sent = calls.find((c) => c.name === "setupEngine")?.args[0];
    expect(sent).toMatchObject({ speculative: "mtp" });
  });

  it("does not offer the model's MTP when the model has none", async () => {
    choices = [entry("qwen3.8-27b")];
    const r = render(<LocalModels s={state()} reload={() => {}} />);
    await open(r, "Qwen3.8 27B");
    const labels = Array.from(card("speculative").querySelectorAll("button")).map(
      (b) => b.textContent,
    );
    expect(labels).not.toContain("MTP del modello");
  });

  it("shows what was measured on this computer", async () => {
    choices = [entry("qwen3.8-27b")];
    const test = {
      model: "qwen3.8-27b-Q4.gguf",
      improvement: "noRepack",
      at: "2026-11-25T10:00:00.000Z",
      read: { before: 41, after: 41.5 },
      write: { before: 2.9, after: 3.2 },
    };
    const r = render(<LocalModels s={state(undefined, [test])} reload={() => {}} />);
    await open(r, "Qwen3.8 27B");
    expect(card("noRepack").textContent).toContain(
      "Misurato su questo computer: lettura 41 → 41,5, scrittura 2,9 → 3,2 token/s.",
    );
  });

  it("starts the model with the card's choices: No Repack, Big Chunks and Prefetch", async () => {
    choices = [
      entry("qwen3.6-35b-a3b", {
        improvements: [
          { id: "prefetch", available: true },
          { id: "bigChunks", available: true },
          { id: "speculative", available: true },
          { id: "noRepack", available: true },
        ],
      }),
    ];
    // Deep Field is on (the engine of another model uses it), so the card may use it.
    const r = render(<LocalModels s={state({ stream: true })} reload={() => {}} />);
    await open(r, "Qwen3.6 35B A3B");
    for (const id of ["prefetch", "bigChunks", "noRepack"])
      fireEvent.click(card(id).querySelector("[role=switch]") as HTMLElement);
    fireEvent.click(startButton(r));
    const sent = calls.find((c) => c.name === "setupEngine")?.args[0];
    expect(sent).toMatchObject({
      variant: "cuda",
      model: "qwen3.6-35b-a3b-Q4.gguf",
      stream: true,
      bigChunks: true,
      moePrefetch: true,
      noRepack: true,
    });
  });

  it("3.12.10: the context bar says where everything stops fitting in the card, and its choice goes with the start", async () => {
    choices = [entry("qwen3.8-27b")];
    const r = render(<LocalModels s={state()} reload={() => {}} />);
    await open(r, "Qwen3.8 27B");
    const bar = await waitFor(() => {
      const b = r.getByTestId("context-bar");
      expect(b.textContent).toMatch(/Oltre 16k una parte del modello va sul processore/);
      return b;
    });
    expect(bar.querySelector(".kit-slider-mark")).not.toBeNull();
    // The steps 4k 8k 16k 32k …: the third is 16k, all in the card.
    fireEvent.input(bar.querySelector("input[type=range]") as HTMLElement, {
      target: { value: "2" },
    });
    await waitFor(() => expect(bar.textContent).toMatch(/Tutto nella scheda: la velocità piena/));
    fireEvent.click(startButton(r));
    const sent = calls.find((c) => c.name === "setupEngine")?.args[0];
    expect(sent).toMatchObject({ model: "qwen3.8-27b-Q4.gguf", ctx: 16384 });
  });

  it("3.12.10: our recommended engine, gold, off until switched on; on, it books its context and goes with the start", async () => {
    choices = [entry("inkling-2-mini")];
    const r = render(<LocalModels s={state()} reload={() => {}} />);
    await open(r, "Inkling 2 Mini");
    const rec = await waitFor(() => card("recommended"));
    expect(rec.className).toMatch(/gold/);
    expect(rec.textContent).toMatch(
      /Legge a blocchi di 128 token, più corti se il contesto è più lungo\. Contesto 64k, tutto nella scheda\./,
    );
    expect(rec.textContent).toMatch(/NVIDIA RTX 4080 SUPER/);
    const sw = rec.querySelector("[role=switch]") as HTMLElement;
    expect(sw.getAttribute("aria-checked")).toBe("false");
    fireEvent.click(sw);
    await waitFor(() =>
      expect(calls.some((c) => c.name === "contextInfo" && c.args[3] === "inkling-2-mini")).toBe(
        true,
      ),
    );
    fireEvent.click(startButton(r));
    const sent = calls.find((c) => c.name === "setupEngine")?.args[0];
    expect(sent).toMatchObject({
      model: "inkling-2-mini-Q4.gguf",
      ctx: 65536,
      recommended: "inkling-2-mini",
    });
  });

  it("3.12.10: the processor threads, automatic until chosen, for writing and reading apart", async () => {
    choices = [entry("qwen3.8-27b")];
    const r = render(<LocalModels s={state()} reload={() => {}} />);
    await open(r, "Qwen3.8 27B");
    const box = await waitFor(() => r.getByTestId("threads"));
    expect(box.textContent).toMatch(/automatico/);
    expect(box.textContent).toMatch(/Questo processore ne ha 12/);
    const [write, read] = Array.from(box.querySelectorAll("input[type=range]")) as HTMLElement[];
    fireEvent.input(write as HTMLElement, { target: { value: "8" } });
    fireEvent.input(read as HTMLElement, { target: { value: "12" } });
    fireEvent.click(startButton(r));
    const sent = calls.find((c) => c.name === "setupEngine")?.args[0];
    expect(sent).toMatchObject({ threads: 8, threadsBatch: 12 });
  });

  it("sends nothing it was not asked: switches off, no extra fields", async () => {
    choices = [entry("qwen3.8-27b")];
    const r = render(<LocalModels s={state()} reload={() => {}} />);
    await open(r, "Qwen3.8 27B");
    fireEvent.click(startButton(r));
    const sent = calls.find((c) => c.name === "setupEngine")?.args[0] as Record<string, unknown>;
    expect(sent.noRepack).toBeUndefined();
    expect(sent.bigChunks).toBeUndefined();
    expect(sent.moePrefetch).toBeUndefined();
    expect(sent.threads).toBeUndefined();
    expect(sent.threadsBatch).toBeUndefined();
  });

  it("shows the running engine's choices on the active model's card", async () => {
    choices = [entry("qwen3.8-27b")];
    const r = render(
      <LocalModels s={state({ model: "qwen3.8-27b-Q4.gguf", noRepack: true })} reload={() => {}} />,
    );
    await open(r, "Qwen3.8 27B");
    const sw = card("noRepack").querySelector("[role=switch]") as HTMLElement;
    expect(sw.getAttribute("aria-checked")).toBe("true");
  });

  it("asks in our window before measuring, then starts the measurement", async () => {
    choices = [entry("qwen3.8-27b")];
    const r = render(
      <>
        <LocalModels s={state()} reload={() => {}} />
        <Dialogs />
      </>,
    );
    await open(r, "Qwen3.8 27B");
    const measure = Array.from(card("noRepack").querySelectorAll("button")).find((b) =>
      (b.textContent ?? "").includes("Misura su questo computer"),
    ) as HTMLElement;
    fireEvent.click(measure);
    await waitFor(() => expect(r.getByText(/Richiede molto tempo e molto calcolo/)).toBeTruthy());
    expect(r.getByText(/anche una perdita/)).toBeTruthy();
    expect(calls.some((c) => c.name === "improvementTest")).toBe(false);
    fireEvent.click(r.getByText("Avvia la misura"));
    await waitFor(() => expect(calls.some((c) => c.name === "improvementTest")).toBe(true));
    const call = calls.find((c) => c.name === "improvementTest");
    expect(call?.args[1]).toBe("noRepack");
    expect(call?.args[0]).toMatchObject({ model: "qwen3.8-27b-Q4.gguf", variant: "cuda" });
  });

  it("has no measure button for speculative decoding (it keeps its own test)", async () => {
    choices = [entry("qwen3.8-27b")];
    const r = render(<LocalModels s={state()} reload={() => {}} />);
    await open(r, "Qwen3.8 27B");
    const spec = card("speculative");
    expect(spec.textContent).not.toContain("Misura su questo computer");
    expect(spec.textContent).toContain("Misura il guadagno");
    expect(spec.textContent).toContain("Spenta");
  });
});

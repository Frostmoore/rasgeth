// @vitest-environment jsdom
// G41.7 in the page: where the video is made. «Crea il video» lists this machine and the nodes
// with what each offers; at the project's first render nothing is chosen and the button waits for
// the person's pick (R2), which goes with the render and is remembered; a choice made before is
// used as it is; machines that cannot render now say why. Settings > Nodes has the same choice.
import type { Job, RenderMachine, RgVideo } from "@redgiant/protocol";
import { newRgVideo } from "@redgiant/protocol";
import { act, cleanup, fireEvent, render, waitFor } from "@testing-library/preact";
import { afterEach, beforeEach, describe, expect, it, vi } from "vitest";
import { lang } from "../src/i18n.js";

type Handler = (...args: unknown[]) => unknown;
let handlers: Record<string, Handler> = {};
const calls: [string, unknown[]][] = [];
const fakeApi = new Proxy(
  {},
  {
    get: (_t, name: string) => {
      if (name === "then") return undefined;
      return (...args: unknown[]) => {
        calls.push([name, args]);
        const h = handlers[name];
        return h ? Promise.resolve(h(...args)) : Promise.resolve({});
      };
    },
  },
);
vi.mock("../src/state.js", async (orig) => ({
  ...(await orig<typeof import("../src/state.js")>()),
  getApi: () => fakeApi,
  openCanvas: () => "id",
}));
const { RenderPanel, machineDetail } = await import(
  "../src/components/viewers/video/RenderPanel.js"
);

const film = (): RgVideo =>
  newRgVideo({ width: 1920, height: 1080, rate: { num: 25, den: 1 }, aspect: "16:9" }, "Gita");
const here: RenderMachine = { id: "here", name: "this machine", ok: true, nvenc: false };
const rig: RenderMachine = {
  id: "SHA256:rig",
  name: "Rig",
  ok: true,
  gpu: "NVIDIA GeForce RTX 4080 SUPER",
  nvenc: true,
  ffmpeg: "9.0.1",
};
const coder: RenderMachine = {
  id: "SHA256:coder",
  name: "Coder",
  ok: true,
  nvenc: false,
  download: true,
};
const off: RenderMachine = {
  id: "SHA256:off",
  name: "Monnezza",
  ok: false,
  reason: "offline",
  nvenc: false,
};
const job: Job = {
  id: "j1",
  kind: "video_render",
  vars: { name: "gita.rgvideo", node: "Rig" },
  state: "running",
  steps: [
    { id: "video_wait", state: "skipped" },
    { id: "video_probe", state: "done" },
    { id: "node_ffmpeg", state: "done" },
    {
      id: "node_copy",
      state: "running",
      progress: { done: 40_000_000, total: 120_000_000, rate: 9_000_000, secondsLeft: 9 },
    },
    { id: "video_render", state: "waiting" },
    { id: "node_fetch", state: "waiting" },
    { id: "node_check", state: "waiting" },
    { id: "video_save", state: "waiting" },
  ],
  startedAt: "2026-11-17T10:00:00Z",
};

beforeEach(() => {
  lang.value = "it";
  handlers = {};
  calls.length = 0;
});
afterEach(cleanup);

const panel = () =>
  render(
    <RenderPanel
      file={{ scope: "project:p1", path: "gita.rgvideo" }}
      doc={film()}
      onClose={() => {}}
    />,
  );
const buttonOf = (c: Element, text: string) =>
  [...c.querySelectorAll("button")].find((b) => b.textContent?.includes(text)) as HTMLButtonElement;

describe("what each machine offers (it, en)", () => {
  it.each<[RenderMachine, string, string]>([
    [rig, "RTX 4080 SUPER, NVENC", "RTX 4080 SUPER, NVENC"],
    [
      coder,
      "solo CPU · ffmpeg si scarica al primo video",
      "CPU only · ffmpeg downloaded at the first video",
    ],
    [here, "solo CPU", "CPU only"],
    [off, "solo CPU · spento", "CPU only · offline"],
    [
      { ...coder, ok: false, reason: "no-media" },
      "solo CPU · serve RedGiant 3.9 o più nuovo lì",
      "CPU only · RedGiant 3.9 or later needed there",
    ],
    [
      { ...coder, ok: false, reason: "no-right" },
      "solo CPU · senza il permesso di usarlo",
      "CPU only · no permission to use it",
    ],
  ])("%j", (m, it, en) => {
    lang.value = "it";
    expect(machineDetail(m)).toBe(it);
    lang.value = "en";
    expect(machineDetail(m)).toBe(en);
  });
});

describe("«Crea il video»: where (G41.7, R2)", () => {
  it("at the first render the person picks the machine; the pick goes with the render", async () => {
    handlers.videoMachines = () => ({ machines: [here, rig, coder, off] });
    handlers.videoRender = () => ({ job });
    handlers.job = () => job;
    const r = panel();
    await waitFor(() =>
      expect(r.container.textContent).toContain("Dove faccio i video di questo progetto?"),
    );
    // Our drawn choices, never a native control; the machine that cannot render says why.
    expect(r.container.querySelector("input, select")).toBeNull();
    expect(r.container.textContent).toContain("Rig");
    expect(r.container.textContent).toContain("RTX 4080 SUPER, NVENC");
    expect(r.container.textContent).toContain("Coder");
    expect(r.container.textContent).toContain("Monnezza: solo CPU · spento");
    expect(buttonOf(r.container, "Monnezza")).toBeUndefined();
    const start = () => buttonOf(r.container, "Crea il video") as HTMLButtonElement;
    expect(start().disabled).toBe(true);
    fireEvent.click(buttonOf(r.container, "Rig"));
    expect(start().disabled).toBe(false);
    expect(r.container.textContent).toContain("su Rig");
    await act(async () => {
      fireEvent.click(start());
    });
    expect(calls.find(([n]) => n === "videoRender")?.[1]).toEqual([
      "project:p1",
      "gita.rgvideo",
      { where: "SHA256:rig" },
    ]);
    await waitFor(() => expect(r.container.textContent).toContain("Copio i file su Rig"));
    expect(r.container.textContent).not.toContain("Dove faccio i video");
  });

  it("a choice made before is used; this machine alone asks nothing", async () => {
    handlers.videoMachines = () => ({ machines: [here, rig], chosen: "SHA256:rig" });
    const r = panel();
    await waitFor(() =>
      expect(buttonOf(r.container, "Rig")?.getAttribute("aria-pressed")).toBe("true"),
    );
    expect(r.container.textContent).not.toContain("Dove faccio i video");
    expect(buttonOf(r.container, "Crea il video").disabled).toBe(false);
    cleanup();
    handlers.videoMachines = () => ({ machines: [here] });
    const alone = panel();
    await waitFor(() => expect(calls.filter(([n]) => n === "videoMachines")).toHaveLength(2));
    expect(alone.container.textContent).not.toContain("Dove");
    expect(alone.container.textContent).toContain("su questo computer");
    expect(buttonOf(alone.container, "Crea il video").disabled).toBe(false);
  });

  it("in English too", async () => {
    lang.value = "en";
    handlers.videoMachines = () => ({ machines: [here, rig] });
    const r = panel();
    await waitFor(() =>
      expect(r.container.textContent).toContain("Where should this project's videos be made?"),
    );
    expect(r.container.textContent).toContain("This machine");
  });
});

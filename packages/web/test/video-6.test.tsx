// @vitest-environment jsdom
// G41.6 in the page: «Crea il video» from the editor (the choices as a table, the job with its bar
// and «Cancel», the finished MP4 opened in the canvas) and the render an agent started, shown in
// the corner card with «Cancel» like a download.
import { type Job, newRgVideo, type RgVideo } from "@redgiant/protocol";
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
const opened: unknown[] = [];
vi.mock("../src/state.js", async (orig) => ({
  ...(await orig<typeof import("../src/state.js")>()),
  getApi: () => fakeApi,
  openCanvas: (...args: unknown[]) => {
    opened.push(args);
    return "id";
  },
}));
const { RenderPanel, renderAsk, renderHeights } = await import(
  "../src/components/viewers/video/RenderPanel.js"
);
const { Downloads } = await import("../src/components/Downloads.js");

const film = (w = 1920, h = 1080): RgVideo =>
  newRgVideo(
    {
      width: w,
      height: h,
      rate: { num: 25, den: 1 },
      aspect: w > h ? "16:9" : w < h ? "9:16" : "1:1",
    },
    "Gita",
  );
const job = (state: Job["state"], more: Partial<Job> = {}): Job => ({
  id: "j1",
  kind: "video_render",
  vars: { name: "gita.rgvideo" },
  state,
  steps: [
    { id: "video_probe", state: "done" },
    {
      id: "video_render",
      state: state === "running" ? "running" : "done",
      ...(state === "running" && { progress: { done: 42, total: 100, rate: 2, secondsLeft: 29 } }),
    },
  ],
  startedAt: "2026-11-17T10:00:00Z",
  ...more,
});

beforeEach(() => {
  lang.value = "it";
  handlers = {};
  calls.length = 0;
  opened.length = 0;
});
afterEach(() => {
  cleanup();
  vi.useRealTimers();
});

describe("the choices", () => {
  it.each<[number, number, number[]]>([
    [1920, 1080, [1080, 720, 480]],
    [3840, 2160, [2160, 1440, 1080, 720]],
    [1080, 1920, [1080, 720, 480]],
    [640, 360, [360]],
  ])("a %d×%d timeline offers %j", (w, h, want) => {
    expect(renderHeights(film(w, h))).toEqual(want);
  });
  it.each<[string, number, string, object]>([
    ["same", 1080, "good", {}],
    ["16:9", 1080, "good", {}],
    ["9:16", 720, "draft", { aspect: "9:16", height: 720, quality: "draft" }],
    ["same", 480, "best", { height: 480, quality: "best" }],
  ])("shape %s, %dp, %s asks %j", (shape, height, quality, want) => {
    expect(renderAsk(film(), shape as never, height, quality as never)).toEqual(want);
  });
});

describe("«Crea il video» in the editor", () => {
  it("starts the render with the choices, shows its bar and «Annulla», then opens the video", async () => {
    let state: Job["state"] = "running";
    handlers.videoRender = () => ({ job: job("running") });
    handlers.job = () =>
      state === "running"
        ? job("running")
        : job("done", {
            result: {
              path: "renders/gita-v1.mp4",
              sidecars: [],
              seconds: 12,
              width: 720,
              height: 1280,
              frames: 300,
              reused: 0,
              warnings: [],
            },
          });
    handlers.cancelJob = () => ({ ok: true });
    const r = render(
      <RenderPanel
        file={{ scope: "p1", path: "video/gita.rgvideo" }}
        doc={film()}
        onClose={() => {}}
      />,
    );
    const button = (text: string) =>
      [...r.container.querySelectorAll("button")].find((b) =>
        b.textContent?.trim().startsWith(text),
      ) as HTMLButtonElement;
    // Our drawn choices, never a native control.
    expect(r.container.querySelector("input, select")).toBeNull();
    fireEvent.click(button("9:16"));
    fireEvent.click(button("720p"));
    fireEvent.click(button("Prova veloce"));
    await act(async () => fireEvent.click(button("Crea il video")));
    expect(calls.find(([n]) => n === "videoRender")?.[1]).toEqual([
      "p1",
      "video/gita.rgvideo",
      { aspect: "9:16", height: 720, quality: "draft" },
    ]);
    await waitFor(() => expect(r.container.querySelector(".ui-job.running")).toBeTruthy());
    expect(r.container.textContent).toContain("Video di gita.rgvideo");
    expect(r.container.textContent).toContain("Faccio il video con ffmpeg");
    expect(r.container.querySelector(".ui-progress")).toBeTruthy();
    expect(button("Annulla")).toBeTruthy();
    expect(button("Crea il video").disabled).toBe(true);
    state = "done";
    await waitFor(() => expect(r.container.textContent).toContain("Pronto: renders/gita-v1.mp4."), {
      timeout: 3000,
    });
    fireEvent.click(button("Apri"));
    expect(opened).toEqual([
      ["gita-v1.mp4", { kind: "file", scope: "p1", path: "renders/gita-v1.mp4" }],
    ]);
    expect(button("Rifallo")).toBeTruthy();
  });

  it("in English too", async () => {
    lang.value = "en";
    const r = render(
      <RenderPanel file={{ scope: "p1", path: "g.rgvideo" }} doc={film()} onClose={() => {}} />,
    );
    expect(r.container.textContent).toContain("Make the video");
    expect(r.container.textContent).toContain("As the timeline (16:9)");
    expect(r.container.textContent).toContain("Quick look");
  });
});

describe("the corner card", () => {
  it("shows a render an agent started, with «Annulla», and leaves other jobs out", async () => {
    handlers.jobs = () => [job("running"), { ...job("running"), id: "j2", kind: "video_preview" }];
    const r = render(<Downloads />);
    await waitFor(() => expect(r.container.querySelector(".downloads .ui-job")).toBeTruthy());
    expect(r.container.querySelectorAll(".ui-job")).toHaveLength(1);
    expect(r.container.textContent).toContain("Video di gita.rgvideo");
    expect(
      [...r.container.querySelectorAll("button")].some((b) => b.textContent?.includes("Annulla")),
    ).toBe(true);
  });
});

// «Crea il video» (G41.6): the render of the timeline, from the editor. The shape (the timeline's,
// or another one reframed at the centre), the short side, the quality; then the job
// `video_render` with its bar and «Cancel», and the finished MP4 opened in the canvas. The same
// job an agent starts with `video render` also shows in the corner card (Downloads.tsx).
// G41.7: where it is made, this machine or a node, with what each offers («Rig — RTX 4080 SUPER,
// NVENC», «Coder — CPU only»): asked at the project's first render (nothing chosen until the
// person picks), then remembered; changed here or in Settings > Nodes.
import {
  type DocFile,
  type Job,
  type RenderMachine,
  type RgVideo,
  VIDEO_RENDER_HEIGHTS,
  type VideoRenderAsk,
  type VideoRenderQuality,
  type VideoRenderResult,
} from "@redgiant/protocol";
import { useEffect, useState } from "preact/hooks";
import { followJobInApp } from "../../../embed.js";
import { t } from "../../../i18n.js";
import {
  IconClose,
  IconCpu,
  IconDownload,
  IconFilm,
  IconGpu,
  IconMonitor,
} from "../../../icons.js";
import { getApi, openCanvas } from "../../../state.js";
import { Seg } from "../../SettingsKit.js";
import { JobView, useJob } from "../../ui.js";

type Shape = "same" | NonNullable<VideoRenderAsk["aspect"]>;

/** The short sides offered: the timeline's own and the usual ones below it. */
export function renderHeights(doc: Pick<RgVideo, "format">): number[] {
  const short = Math.min(doc.format.width, doc.format.height);
  const list = VIDEO_RENDER_HEIGHTS.filter((h) => h < short);
  return [short, ...list].slice(0, 4);
}

/** What the page asks for, from its choices. */
export function renderAsk(
  doc: Pick<RgVideo, "format">,
  shape: Shape,
  height: number,
  quality: VideoRenderQuality,
): VideoRenderAsk {
  const short = Math.min(doc.format.width, doc.format.height);
  return {
    ...(shape !== "same" && shape !== doc.format.aspect && { aspect: shape }),
    ...(height < short && { height }),
    ...(quality !== "good" && { quality }),
  };
}

/** What a machine offers, in a few words: its card and NVENC, or the CPU only. */
export function machineDetail(m: RenderMachine): string {
  const what = m.gpu
    ? m.nvenc
      ? t("veRenderGpuNvenc", { gpu: m.gpu.replace(/^NVIDIA (GeForce )?/, "") })
      : m.gpu.replace(/^NVIDIA (GeForce )?/, "")
    : t("veRenderCpuOnly");
  const why = m.ok
    ? m.download
      ? t("veRenderDownloads")
      : ""
    : t(
        (
          {
            offline: "veRenderWhyOffline",
            "no-right": "veRenderWhyNoRight",
            "no-media": "veRenderWhyNoMedia",
            "no-ffmpeg": "veRenderWhyNoFfmpeg",
          } as const
        )[m.reason ?? "offline"],
      );
  return why ? `${what} · ${why}` : what;
}

/** The machine's name as the page says it. */
export const machineName = (m: RenderMachine) =>
  m.id === "here" ? t("veRenderThisMachine") : m.name;

/** Where the project's videos go: the machines that can render now, the others said why not. */
function Where({
  machines,
  value,
  onChange,
}: {
  machines: RenderMachine[];
  value: string | undefined;
  onChange: (id: string) => void;
}) {
  const ok = machines.filter((m) => m.ok || m.id === value);
  const off = machines.filter((m) => !m.ok && m.id !== value);
  return (
    <div class="ve-render-row ve-render-where">
      <span class="ve-small dim">{t("veRenderWhere")}</span>
      <Seg<string>
        label={t("veRenderWhere")}
        value={value}
        onChange={onChange}
        vertical
        options={ok.map(
          (m) =>
            [
              m.id,
              <span class="ve-machine" key={m.id}>
                {m.id === "here" ? (
                  <IconMonitor size={13} />
                ) : m.gpu ? (
                  <IconGpu size={13} />
                ) : (
                  <IconCpu size={13} />
                )}
                <b>{machineName(m)}</b>
                <span class="dim">{machineDetail(m)}</span>
              </span>,
            ] as const,
        )}
      />
      {off.length > 0 && (
        <p class="ve-small dim ve-render-off">
          {off.map((m) => `${machineName(m)}: ${machineDetail(m)}`).join(" · ")}
        </p>
      )}
    </div>
  );
}

export function RenderPanel({
  file,
  doc,
  onClose,
  onDownload,
}: {
  file: DocFile;
  doc: RgVideo;
  onClose: () => void;
  /** G42.18: an app embedding the editor saves the finished video its own way (true: done). */
  onDownload?: (f: { scope: string; path: string; name: string }) => boolean;
}) {
  const heights = renderHeights(doc);
  const [shape, setShape] = useState<Shape>("same");
  const [height, setHeight] = useState<number>(
    heights.find((h) => h <= 1080) ?? heights[0] ?? 1080,
  );
  const [quality, setQuality] = useState<VideoRenderQuality>("good");
  const [jobId, setJobId] = useState<string>();
  const [error, setError] = useState<string>();
  // G41.7: the machines, and the project's choice (none yet: the person picks before starting).
  const [machines, setMachines] = useState<RenderMachine[]>();
  const [where, setWhere] = useState<string>();
  const [chosen, setChosen] = useState<string>();
  useEffect(() => {
    let live = true;
    void getApi()
      .videoMachines(file.scope)
      .then((r) => {
        if (!live) return;
        const list = r.machines ?? [];
        setMachines(list);
        setChosen(r.chosen);
        // A choice made before is used; with this machine alone there is nothing to choose.
        setWhere(r.chosen ?? (list.length <= 1 ? "here" : undefined));
      })
      .catch(() => live && setMachines([]));
    return () => {
      live = false;
    };
  }, [file.scope]);
  const job = useJob(jobId);
  const result = job?.state === "done" ? (job.result as VideoRenderResult) : undefined;
  const start = async () => {
    setError(undefined);
    try {
      const r = await getApi().videoRender(file.scope, file.path, {
        ...renderAsk(doc, shape, height, quality),
        ...(where && { where }),
      });
      setJobId(r.job.id);
      // Inside the app its notifications follow the render too (G42.18).
      followJobInApp(r.job.id, t("veRenderJob", { name: file.path.split("/").pop() ?? file.path }));
      if (where) setChosen(where);
    } catch (e) {
      setError((e as Error).message);
    }
  };
  /** «Salva come…» of the finished video: the app's dialog inside it, the browser's here. */
  const saveResult = async (path: string) => {
    const name = path.split("/").pop() ?? path;
    if (onDownload?.({ scope: file.scope, path, name })) return;
    try {
      const blob = await getApi().download(file.scope, path);
      const a = document.createElement("a");
      a.href = URL.createObjectURL(blob);
      a.download = name;
      a.click();
      URL.revokeObjectURL(a.href);
    } catch (e) {
      setError((e as Error).message);
    }
  };
  const running = job?.state === "running";
  const many = (machines?.length ?? 0) > 1;
  const at = machines?.find((m) => m.id === (where ?? chosen));
  const asking = many && where === undefined;
  const label = (h: number) =>
    h >= 2160
      ? "4K"
      : h === Math.min(doc.format.width, doc.format.height)
        ? `${h}p · ${t("veRenderFull")}`
        : `${h}p`;
  return (
    <section class="ve-render" aria-label={t("veRenderTitle")}>
      <div class="ve-transcript-bar">
        <strong>{t("veRenderTitle")}</strong>
        <span class="dim ve-small">
          {at && at.id !== "here" ? t("veRenderOn", { name: at.name }) : t("veRenderHere")}
        </span>
        <div class="spacer" />
        <button
          type="button"
          class="vw-icon"
          title={t("close")}
          aria-label={t("close")}
          onClick={onClose}
        >
          <IconClose size={14} />
        </button>
      </div>
      {many && machines && (
        <>
          {asking && <p class="notice ve-render-ask">{t("veRenderWhereAsk")}</p>}
          <Where machines={machines} value={where} onChange={setWhere} />
        </>
      )}
      <div class="ve-render-row">
        <span class="ve-small dim">{t("veRenderShape")}</span>
        <Seg<Shape>
          label={t("veRenderShape")}
          value={shape}
          onChange={setShape}
          options={[
            [
              "same",
              t("veRenderSame", {
                shape:
                  doc.format.aspect === "free"
                    ? `${doc.format.width}×${doc.format.height}`
                    : doc.format.aspect,
              }),
            ],
            ...(["16:9", "9:16", "1:1"] as const)
              .filter((a) => a !== doc.format.aspect)
              .map((a) => [a, a] as const),
          ]}
        />
      </div>
      <div class="ve-render-row">
        <span class="ve-small dim">{t("veRenderSize")}</span>
        <Seg<string>
          label={t("veRenderSize")}
          value={String(height)}
          onChange={(v) => setHeight(Number(v))}
          options={heights.map((h) => [String(h), label(h)] as const)}
        />
      </div>
      <div class="ve-render-row">
        <span class="ve-small dim">{t("veRenderQuality")}</span>
        <Seg<VideoRenderQuality>
          label={t("veRenderQuality")}
          value={quality}
          onChange={setQuality}
          options={[
            ["draft", t("veRenderDraft")],
            ["good", t("veRenderGood")],
            ["best", t("veRenderBest")],
          ]}
        />
      </div>
      <div class="ve-render-row">
        <button
          type="button"
          class="vw-btn small primary"
          disabled={running || asking}
          onClick={() => void start()}
        >
          <IconFilm size={13} /> {t(job && !running ? "veRenderAgain" : "veRenderStart")}
        </button>
      </div>
      {error && <p class="notice error">{error}</p>}
      {job && <JobView job={job as Job} cancellable countSteps={["video_probe", "video_render"]} />}
      {result && (
        <p class="ve-render-done">
          {t("veRenderDone", { path: result.path })}{" "}
          <button
            type="button"
            class="vw-btn small"
            onClick={() =>
              openCanvas(result.path.split("/").pop() ?? result.path, {
                kind: "file",
                scope: file.scope,
                path: result.path,
              })
            }
          >
            {t("veRenderOpen")}
          </button>{" "}
          <button
            type="button"
            class="vw-btn small"
            title={t("veRenderSaveHint")}
            onClick={() => void saveResult(result.path)}
          >
            <IconDownload size={13} /> {t("veSaveAs")}
          </button>
        </p>
      )}
    </section>
  );
}

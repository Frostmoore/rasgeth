// «Crea il video» (G41.6): the render of the timeline on this machine, from the editor. The shape
// (the timeline's, or another one reframed at the centre), the short side, the quality; then the
// job `video_render` with its bar and «Cancel», and the finished MP4 opened in the canvas. The
// same job an agent starts with `video render` also shows in the corner card (Downloads.tsx).
import {
  type DocFile,
  type Job,
  type RgVideo,
  VIDEO_RENDER_HEIGHTS,
  type VideoRenderAsk,
  type VideoRenderQuality,
  type VideoRenderResult,
} from "@redgiant/protocol";
import { useState } from "preact/hooks";
import { t } from "../../../i18n.js";
import { IconClose, IconFilm } from "../../../icons.js";
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

export function RenderPanel({
  file,
  doc,
  onClose,
}: {
  file: DocFile;
  doc: RgVideo;
  onClose: () => void;
}) {
  const heights = renderHeights(doc);
  const [shape, setShape] = useState<Shape>("same");
  const [height, setHeight] = useState<number>(
    heights.find((h) => h <= 1080) ?? heights[0] ?? 1080,
  );
  const [quality, setQuality] = useState<VideoRenderQuality>("good");
  const [jobId, setJobId] = useState<string>();
  const [error, setError] = useState<string>();
  const job = useJob(jobId);
  const result = job?.state === "done" ? (job.result as VideoRenderResult) : undefined;
  const start = async () => {
    setError(undefined);
    try {
      const r = await getApi().videoRender(
        file.scope,
        file.path,
        renderAsk(doc, shape, height, quality),
      );
      setJobId(r.job.id);
    } catch (e) {
      setError((e as Error).message);
    }
  };
  const running = job?.state === "running";
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
        <span class="dim ve-small">{t("veRenderHere")}</span>
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
          disabled={running}
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
          </button>
        </p>
      )}
    </section>
  );
}

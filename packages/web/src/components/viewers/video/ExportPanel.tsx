// «Esporta» (G41.6b): the timeline for another editor, from the editor. «Esporta per Resolve»
// writes the FCP7 XML montatore writes (the person confirmed it in DaVinci Resolve), «Esporta
// OTIO» OpenTimelineIO; both beside the timeline. The folder of the originals is where they are
// on the computer that runs Resolve (montatore's D21, remembered by this browser); empty, the
// files point to this machine. Then the file: «Scarica» (or the embedding app's own way to save
// it, `onDownload`), «Apri» in the canvas, and what the XML does not carry (redone in Resolve).
import type { DocFile, VideoExportFormat, VideoExportResult } from "@redgiant/protocol";
import { useState } from "preact/hooks";
import { ApiError } from "../../../api.js";
import { embedded } from "../../../embed.js";
import { t } from "../../../i18n.js";
import { IconClose, IconDownload, IconExternal, IconFilm } from "../../../icons.js";
import { getApi, openCanvas } from "../../../state.js";

const ROOT_KEY = "rg.video.resolveMediaRoot";

const storedRoot = (): string => {
  try {
    return localStorage.getItem(ROOT_KEY) ?? "";
  } catch {
    return "";
  }
};

/** What the XML for Resolve leaves out, as the page says it (none: an empty list). */
export function leftOutLines(r: VideoExportResult): string[] {
  if (r.format !== "resolve") return [];
  const l = r.leftOut;
  const parts: [number, Parameters<typeof t>[0]][] = [
    [l.titles, "veExportTitles"],
    [l.transitions, "veExportTransitions"],
    [l.fades, "veExportFades"],
    [l.volumes, "veExportVolumes"],
    [l.kenBurns, "veExportKenBurns"],
    [l.reframes, "veExportReframes"],
    [l.speeds, "veExportSpeeds"],
    [l.colors ?? 0, "veExportColors"],
    [l.stills ?? 0, "veExportStills"],
    [l.ducking, "veExportDucking"],
    [l.markers, "veExportMarkers"],
    [l.captions, "veExportCaptions"],
  ];
  return parts.filter(([n]) => n > 0).map(([n, key]) => t(key, { n: String(n) }));
}

export function ExportPanel({
  file,
  onClose,
  onDownload,
}: {
  file: DocFile;
  onClose: () => void;
  /** An app embedding the editor saves the file its own way; true: done. */
  onDownload?: (f: { scope: string; path: string; name: string }) => boolean;
}) {
  const [root, setRoot] = useState(storedRoot);
  const [busy, setBusy] = useState<VideoExportFormat>();
  const [result, setResult] = useState<VideoExportResult>();
  const [error, setError] = useState<string>();
  const run = async (format: VideoExportFormat) => {
    setBusy(format);
    setError(undefined);
    setResult(undefined);
    try {
      localStorage.setItem(ROOT_KEY, root.trim());
    } catch {
      // A browser without storage asks again next time.
    }
    try {
      const r = await getApi().videoExport(file.scope, file.path, format, root.trim());
      setResult(r.result);
    } catch (e) {
      setError(
        e instanceof ApiError && e.code === "video_export_rate"
          ? t("veExportRate")
          : (e as Error).message,
      );
    } finally {
      setBusy(undefined);
    }
  };
  const name = result ? (result.path.split("/").pop() ?? result.path) : "";
  const download = async () => {
    if (!result) return;
    if (onDownload?.({ scope: file.scope, path: result.path, name })) return;
    try {
      const blob = await getApi().download(file.scope, result.path);
      const a = document.createElement("a");
      a.href = URL.createObjectURL(blob);
      a.download = name;
      a.click();
      URL.revokeObjectURL(a.href);
    } catch (e) {
      setError((e as Error).message);
    }
  };
  const left = result ? leftOutLines(result) : [];
  return (
    <section class="ve-render ve-export" aria-label={t("veExportTitle")}>
      <div class="ve-transcript-bar">
        <strong>{t("veExportTitle")}</strong>
        <span class="dim ve-small">{t("veExportBeside")}</span>
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
      <label class="ve-export-root">
        <span class="ve-small dim">{t("veExportRoot")}</span>
        <input
          type="text"
          value={root}
          spellcheck={false}
          placeholder={t("veExportRootPlaceholder")}
          onInput={(e) => setRoot((e.target as HTMLInputElement).value)}
          onKeyDown={(e) => {
            // The editor's own keys stay out of what is written here.
            e.stopPropagation();
            if (e.key === "Enter") void run("resolve");
          }}
        />
        <span class="ve-small dim">
          {t(root.trim() ? "veExportRootHint" : "veExportRootEmpty")}
        </span>
      </label>
      <div class="ve-render-row">
        <button
          type="button"
          class="vw-btn small primary"
          disabled={!!busy}
          onClick={() => void run("resolve")}
        >
          <IconFilm size={13} /> {t(busy === "resolve" ? "veExportBusy" : "veExportResolve")}
        </button>
        <button
          type="button"
          class="vw-btn small"
          disabled={!!busy}
          onClick={() => void run("otio")}
        >
          <IconExternal size={13} /> {t(busy === "otio" ? "veExportBusy" : "veExportOtio")}
        </button>
      </div>
      {error && <p class="notice error">{error}</p>}
      {result && (
        <div class="ve-export-done">
          <p class="ve-render-done">
            {t("veExportDone", { path: result.path, clips: String(result.clips) })}{" "}
            <button type="button" class="vw-btn small" onClick={() => void download()}>
              <IconDownload size={13} /> {t(embedded() ? "veSaveAs" : "veExportDownload")}
            </button>{" "}
            <button
              type="button"
              class="vw-btn small"
              onClick={() =>
                openCanvas(name, { kind: "file", scope: file.scope, path: result.path })
              }
            >
              {t("veRenderOpen")}
            </button>
          </p>
          {result.example && (
            <p class="ve-small dim">{t("veExportPoints", { example: result.example })}</p>
          )}
          {result.format === "resolve" && <p class="ve-small dim">{t("veExportHowResolve")}</p>}
          {left.length > 0 && (
            <p class="ve-small dim">{t("veExportLeftOut", { what: left.join(", ") })}</p>
          )}
          {result.leftOut.missing.length > 0 && (
            <p class="notice">
              {t("veExportMissing", { files: result.leftOut.missing.join(", ") })}
            </p>
          )}
        </div>
      )}
    </section>
  );
}

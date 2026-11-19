// A timeline (`.rgvideo`) in the canvas, played in the browser on the proxies (G41.5a): the stage
// with the tracks' players (`video/player.ts`), the transport (play, frames, a drawn scrubber,
// timecode), the tracks at a glance with their strips of frames and waveforms, and «Anteprima
// esatta»: a stretch from the cursor made by ffmpeg as the final video. The server prepares
// the files (proxy, strip, waveform) as jobs with their bar the first time; state in state.ts.
// The editing (moving, trimming, the inspector) comes with the editor of G41.5b.

import {
  clipEnd,
  framesToSeconds,
  isMediaRef,
  type RgVideo,
  readRgVideo,
  timecode,
  type VideoMediaInfo,
  type VideoPreviewResult,
} from "@redgiant/protocol";
import { useEffect, useMemo, useRef, useState } from "preact/hooks";
import { t, tOptional } from "../../i18n.js";
import {
  IconChevronLeft,
  IconChevronRight,
  IconClose,
  IconFilm,
  IconPause,
  IconPlay,
} from "../../icons.js";
import {
  EXACT_LENGTHS,
  getApi,
  setVideoMedia,
  setVideoView,
  videoMedia,
  videoViewKey,
  videoViewOf,
} from "../../state.js";
import { JobView, Progress, useJob } from "../ui.js";
import { type PlayerMediaMap, TimelinePlayer, timelineEnd } from "./video/player.js";

type File = { scope: string; path: string };

/** The page's map of files for the player, from what the server prepared. */
export function playerMediaOf(media: VideoMediaInfo[] | undefined): PlayerMediaMap {
  const out: PlayerMediaMap = {};
  for (const m of media ?? [])
    out[m.media] = {
      ...(m.proxy && { proxy: m.proxy }),
      ...(m.file && { file: m.file }),
      ...(m.kind && { kind: m.kind }),
      ...(m.missing && { missing: true }),
      ...(m.probe?.width && m.probe.height && { width: m.probe.width, height: m.probe.height }),
    };
  return out;
}

/** The server's Inter for texts and subtitles, as in the render (once per page). */
export function useFonts(fonts: { regular: string; bold: string } | undefined) {
  useEffect(() => {
    if (!fonts || document.getElementById("vp-fonts")) return;
    const s = document.createElement("style");
    s.id = "vp-fonts";
    s.textContent = `@font-face{font-family:"RG Inter";src:url("${fonts.regular}") format("truetype");font-weight:400}@font-face{font-family:"RG Inter";src:url("${fonts.bold}") format("truetype");font-weight:700}`;
    document.head.appendChild(s);
  }, [fonts?.regular]);
}

/**
 * The files a timeline uses (and `extra` ones about to go in), prepared on the server: jobs the
 * first time (proxy, strip, wave), then asked again for the links; a failure is not retried in
 * a loop. The answer goes into `videoMedia` (state.ts).
 */
export function usePrepared(file: File, doc: RgVideo | undefined, extra: readonly string[] = []) {
  const key = videoViewKey(file);
  const prepared = videoMedia.value[key];
  const [pending, setPending] = useState<string[]>([]);
  const [rounds, setRounds] = useState(0);
  const ended = useRef({ n: 0, ok: false });
  const names = useMemo(
    () =>
      JSON.stringify(
        [
          ...new Set([
            ...(doc?.clips.flatMap((c) => (isMediaRef(c.ref) ? [c.ref.media] : [])) ?? []),
            ...extra,
          ]),
        ].sort(),
      ),
    [doc, extra.join("\n")],
  );
  useEffect(() => {
    if (!doc) return;
    let live = true;
    const api = getApi();
    void (
      extra.length
        ? api.videoPrepare(file.scope, file.path, [...extra])
        : api.videoPrepare(file.scope, file.path)
    ).then(
      (r) => {
        if (!live) return;
        setVideoMedia(key, r);
        ended.current = { n: 0, ok: false };
        setPending(r.media.flatMap((m) => m.jobs));
      },
      () => {},
    );
    return () => {
      live = false;
    };
  }, [key, names, rounds, !!doc]);
  const jobEnded = (ok: boolean) => {
    const e = ended.current;
    e.n++;
    e.ok ||= ok;
    // All done: ask again (the next files, the links); a failure is not retried in a loop.
    if (e.n >= pending.length && e.ok && rounds < 6) setRounds((n) => n + 1);
  };
  const preparing = pending.length > 0 && ended.current.n < pending.length;
  return { prepared, pending, preparing, jobEnded, again: () => setRounds((n) => n + 1) };
}

/** One job preparing a file: its words and bar; `onEnd` when it stops. */
export function PrepJob({ id, onEnd }: { id: string; onEnd: (ok: boolean) => void }) {
  const job = useJob(id);
  useEffect(() => {
    if (job && job.state !== "running") onEnd(job.state === "done");
  }, [job?.state]);
  if (!job || job.state === "done") return null;
  if (job.state !== "running") return <JobView job={job} />;
  const step = job.steps.find((s) => s.state === "running");
  return (
    <div class="vp-prep-job">
      <span>{tOptional(`job_${job.kind}`, job.vars) ?? job.kind}</span>
      {step?.progress && <Progress progress={step.progress} unit="count" />}
    </div>
  );
}

/** The exact preview's job; when done, its link goes into the view. */
export function ExactJob({ id, view, from }: { id: string; view: string; from: number }) {
  const job = useJob(id);
  useEffect(() => {
    if (job?.state !== "done") return;
    const r = job.result as VideoPreviewResult;
    void getApi()
      .videoExactLink(r.id)
      .then(
        ({ url }) =>
          setVideoView(view, {
            exactJob: undefined,
            exact: { url, from: r.start ?? from, frames: r.frames, warnings: r.warnings ?? [] },
          }),
        () => setVideoView(view, { exactJob: undefined }),
      );
  }, [job?.state]);
  if (!job) return null;
  return (
    <div class="vp-exact-job">
      <JobView job={job} cancellable />
      {job.state !== "running" && job.state !== "done" && (
        <button
          type="button"
          class="link"
          onClick={() => setVideoView(view, { exactJob: undefined })}
        >
          {t("close")}
        </button>
      )}
    </div>
  );
}

/** The tracks at a glance: video tracks from the top, then audio; clips with frames or sound. */
function Tracks({
  doc,
  media,
  frame,
  seek,
}: {
  doc: RgVideo;
  media: Record<string, VideoMediaInfo>;
  frame: number;
  seek: (f: number) => void;
}) {
  const end = Math.max(1, timelineEnd(doc));
  const rate = doc.format.rate;
  const video = doc.tracks.filter((x) => x.kind === "Video").reverse();
  const audio = doc.tracks.filter((x) => x.kind === "Audio");
  const pct = (f: number) => `${((f / end) * 100).toFixed(3)}%`;
  const onLane = (e: PointerEvent) => {
    const r = (e.currentTarget as HTMLElement).getBoundingClientRect();
    seek(Math.round(((e.clientX - r.left) / Math.max(1, r.width)) * end));
  };
  return (
    <section class="vp-tracks" aria-label={t("vpTracks")}>
      {[...video, ...audio].map((tr) => {
        const off = tr.kind === "Video" ? tr.hidden : tr.muted;
        return (
          <div
            key={tr.id}
            class={`vp-track ${tr.kind === "Video" ? "v" : "a"}${off ? " off" : ""}`}
          >
            <span class="vp-track-name">
              {tr.id}
              {off && (
                <span class="dim"> · {t(tr.kind === "Video" ? "vpHidden" : "vpMutedTrack")}</span>
              )}
            </span>
            <div class="vp-lane" onPointerDown={onLane}>
              {doc.clips
                .filter((c) => c.track === tr.id)
                .map((c) => {
                  const m = isMediaRef(c.ref) ? media[c.ref.media] : undefined;
                  const dur = m?.probe?.duration ?? 0;
                  const len = Math.max(1e-6, framesToSeconds(c.sourceRange.duration, rate));
                  const from = framesToSeconds(c.sourceRange.start, rate);
                  // The whole file's strip or wave, placed so the clip's part shows.
                  const inner =
                    dur > 0
                      ? {
                          left: `${(-(from / len) * 100).toFixed(3)}%`,
                          width: `${((dur / len) * 100).toFixed(3)}%`,
                        }
                      : undefined;
                  const label = isMediaRef(c.ref)
                    ? (c.name ?? c.ref.media.split("/").pop())
                    : "text" in c.ref
                      ? c.ref.text
                      : (c.name ?? "");
                  return (
                    <div
                      key={c.id}
                      class={`vp-clip${c.enabled ? "" : " disabled"}${m?.missing ? " missing" : ""}${isMediaRef(c.ref) ? "" : " gen"}`}
                      style={{ left: pct(c.start), width: pct(clipEnd(c) - c.start) }}
                      title={label}
                    >
                      {tr.kind === "Video" && m?.filmstrip && inner && (
                        <div
                          class="vp-strip"
                          style={{ ...inner, backgroundImage: `url("${m.filmstrip.url}")` }}
                        />
                      )}
                      {tr.kind === "Video" && m?.kind === "image" && m.file && (
                        <div
                          class="vp-strip still"
                          style={{ backgroundImage: `url("${m.file}")` }}
                        />
                      )}
                      {tr.kind === "Audio" && m?.waveform && inner && (
                        <div
                          class="vp-wave"
                          style={{
                            ...inner,
                            maskImage: `url("${m.waveform.url}")`,
                            WebkitMaskImage: `url("${m.waveform.url}")`,
                          }}
                        />
                      )}
                      <span class="vp-clip-name">{label}</span>
                    </div>
                  );
                })}
              <div class="vp-head" style={{ left: pct(frame) }} />
            </div>
          </div>
        );
      })}
    </section>
  );
}

export function VideoPreview({ file }: { file: File }) {
  const key = videoViewKey(file);
  const view = videoViewOf(key);
  const [doc, setDoc] = useState<RgVideo>();
  const [error, setError] = useState<string>();
  const stage = useRef<HTMLDivElement>(null);
  const audioBox = useRef<HTMLDivElement>(null);
  const player = useRef<TimelinePlayer | undefined>(undefined);

  // The timeline as saved; read again when the file changes.
  useEffect(() => {
    let stop = false;
    let version: number | undefined;
    const load = () =>
      void getApi()
        .read(file.scope, file.path)
        .then(
          (r) => {
            if (stop) return;
            try {
              setDoc(readRgVideo(r.encoding === "utf8" ? r.content : atob(r.content)));
              setError(undefined);
            } catch (e) {
              setError(t("vpReadError", { e: (e as Error).message }));
            }
          },
          (e: unknown) => !stop && setError(t("vpReadError", { e: (e as Error).message })),
        );
    load();
    const timer = setInterval(
      () =>
        void getApi()
          .canvasVersion(file.scope, file.path, true)
          .then(
            (r) => {
              if (version !== undefined && r.version !== version) load();
              version = r.version;
            },
            () => {},
          ),
      3000,
    );
    return () => {
      stop = true;
      clearInterval(timer);
    };
  }, [key]);

  const { prepared, pending, preparing, jobEnded } = usePrepared(file, doc);
  const mediaMap = useMemo(() => playerMediaOf(prepared?.media), [prepared]);
  const byName = useMemo(
    () => Object.fromEntries((prepared?.media ?? []).map((m) => [m.media, m])),
    [prepared],
  );
  useFonts(prepared?.fonts);

  // The player: made once, fed the timeline and the files.
  useEffect(() => {
    if (!stage.current || !audioBox.current) return;
    const p = new TimelinePlayer({
      stage: stage.current,
      audioBox: audioBox.current,
      onFrame: (f) => setVideoView(key, { frame: f }),
      onEnd: (f) => setVideoView(key, { frame: f, playing: false }),
    });
    p.frame = videoViewOf(key).frame;
    player.current = p;
    return () => {
      p.destroy();
      player.current = undefined;
      setVideoView(key, { playing: false });
    };
  }, [key, !!doc]);
  useEffect(() => {
    if (doc) player.current?.setDoc(doc, mediaMap);
  }, [doc, mediaMap]);

  // The texts' size follows the stage's short side, as in the render.
  useEffect(() => {
    const el = stage.current;
    if (!el || typeof ResizeObserver === "undefined") return;
    const ro = new ResizeObserver(() =>
      el.style.setProperty("--side", `${Math.min(el.clientWidth, el.clientHeight)}px`),
    );
    ro.observe(el);
    return () => ro.disconnect();
  }, [!!doc]);

  if (error) return <p class="notice error">{error}</p>;
  if (!doc) return <div class="vw-empty dim">{t("loading")}</div>;

  const rate = doc.format.rate;
  const fps = rate.num / rate.den;
  const end = timelineEnd(doc);
  const frame = Math.min(view.frame, Math.max(0, end - 1));
  const seek = (f: number) => {
    const g = Math.max(0, Math.min(Math.max(0, end - 1), Math.round(f)));
    player.current?.seek(g);
    setVideoView(key, { frame: g });
  };
  const toggle = () => {
    const p = player.current;
    if (!p) return;
    if (p.playing) {
      p.pause();
      setVideoView(key, { playing: false, frame: p.frame });
    } else {
      p.frame = frame;
      p.play();
      setVideoView(key, { playing: true });
    }
  };
  const exactLen = Number(view.exactLength);
  const askExact = () => {
    player.current?.pause();
    const to = Math.min(end, frame + Math.round(exactLen * fps));
    setVideoView(key, { playing: false, exact: undefined });
    void getApi()
      .videoExact(file.scope, file.path, frame, Math.max(frame + 1, to))
      .then(
        ({ job }) => setVideoView(key, { exactJob: job.id }),
        () => {},
      );
  };
  const onKey = (e: KeyboardEvent) => {
    const tag = (e.target as HTMLElement).tagName;
    if (tag === "INPUT" || tag === "TEXTAREA") return;
    if (e.key === " ") toggle();
    else if (e.key === "ArrowLeft") seek(frame - (e.shiftKey ? Math.round(fps) : 1));
    else if (e.key === "ArrowRight") seek(frame + (e.shiftKey ? Math.round(fps) : 1));
    else if (e.key === "Home") seek(0);
    else if (e.key === "End") seek(end - 1);
    else return;
    e.preventDefault();
  };
  const scrub = (e: PointerEvent) => {
    const el = e.currentTarget as HTMLElement;
    const at = (x: number) => {
      const r = el.getBoundingClientRect();
      seek(((x - r.left) / Math.max(1, r.width)) * end);
    };
    at(e.clientX);
    el.setPointerCapture?.(e.pointerId);
    const move = (m: PointerEvent) => at(m.clientX);
    const up = () => {
      el.removeEventListener("pointermove", move);
      el.removeEventListener("pointerup", up);
    };
    el.addEventListener("pointermove", move);
    el.addEventListener("pointerup", up);
  };
  const missing = (prepared?.media ?? []).filter((m) => m.missing).map((m) => m.media);
  const { width: W, height: H } = doc.format;

  return (
    // biome-ignore lint/a11y/noStaticElementInteractions: the keys of a player (space, arrows)
    <div class="vp" tabIndex={-1} onKeyDown={onKey}>
      <div class="vp-screen" style={{ "--ar": `${W} / ${H}`, "--arn": String(W / H) }}>
        <div
          ref={stage}
          class="vp-stage"
          role="img"
          aria-label={doc.name ?? file.path.split("/").pop()}
        />
        <div ref={audioBox} class="vp-audio" aria-hidden="true" />
        {end === 0 && <p class="vp-empty">{t("vpEmpty")}</p>}
        {view.exact && (
          <div class="vp-exact">
            <div class="vp-exact-bar">
              <strong>{t("vpExactFrom", { tc: timecode(view.exact.from, rate) })}</strong>
              <div class="spacer" />
              <button
                type="button"
                class="vw-icon"
                title={t("vpExactClose")}
                aria-label={t("vpExactClose")}
                onClick={() => setVideoView(key, { exact: undefined })}
              >
                <IconClose size={14} />
              </button>
            </div>
            {/* biome-ignore lint/a11y/useMediaCaption: the subtitles are burnt in when asked */}
            <video src={view.exact.url} controls autoPlay playsInline />
          </div>
        )}
      </div>
      <div class="vw-bar vp-transport">
        <div class="vw-seg">
          <button
            type="button"
            title={t("vpPrevFrame")}
            aria-label={t("vpPrevFrame")}
            onClick={() => seek(frame - 1)}
          >
            <IconChevronLeft size={14} />
          </button>
          <button
            type="button"
            class="vp-play"
            title={view.playing ? t("vpPause") : t("vpPlay")}
            aria-label={view.playing ? t("vpPause") : t("vpPlay")}
            aria-pressed={view.playing}
            disabled={end === 0}
            onClick={toggle}
          >
            {view.playing ? <IconPause size={14} /> : <IconPlay size={14} />}
          </button>
          <button
            type="button"
            title={t("vpNextFrame")}
            aria-label={t("vpNextFrame")}
            onClick={() => seek(frame + 1)}
          >
            <IconChevronRight size={14} />
          </button>
        </div>
        <span class="vp-tc">
          {timecode(frame, rate)} <span class="dim">/ {timecode(end, rate)}</span>
        </span>
        <div
          class="vp-scrub"
          role="slider"
          tabIndex={0}
          aria-label={t("vpPosition")}
          aria-valuemin={0}
          aria-valuemax={Math.max(0, end - 1)}
          aria-valuenow={frame}
          aria-valuetext={timecode(frame, rate)}
          onPointerDown={scrub}
        >
          <span class="vp-scrub-fill" style={{ width: `${end ? (frame / end) * 100 : 0}%` }} />
          <span class="vp-scrub-knob" style={{ left: `${end ? (frame / end) * 100 : 0}%` }} />
        </div>
        <div class="vw-seg">
          {EXACT_LENGTHS.map((s) => (
            <button
              key={s}
              type="button"
              class={view.exactLength === s ? "on" : ""}
              aria-pressed={view.exactLength === s}
              title={t("vpExactLength")}
              onClick={() => setVideoView(key, { exactLength: s })}
            >
              {t("vpSeconds", { n: s })}
            </button>
          ))}
        </div>
        <button
          type="button"
          class="vw-btn small"
          title={t("vpExactHint", { s: view.exactLength })}
          disabled={end === 0 || !!view.exactJob}
          onClick={askExact}
        >
          <IconFilm size={14} />
          {t("vpExact")}
        </button>
      </div>
      {view.exactJob && <ExactJob id={view.exactJob} view={key} from={frame} />}
      {view.exact?.warnings.length ? <p class="notice">{view.exact.warnings.join(" · ")}</p> : null}
      {preparing && (
        <div class="vp-prep">
          <strong>{t("vpPreparing")}</strong>
          {pending.map((id) => (
            <PrepJob key={id} id={id} onEnd={jobEnded} />
          ))}
        </div>
      )}
      {missing.length > 0 && (
        <p class="notice">
          {missing.length === 1
            ? t("vpMissing1", { name: missing[0] as string })
            : t("vpMissing", { n: String(missing.length), names: missing.join(", ") })}
        </p>
      )}
      <Tracks doc={doc} media={byName} frame={frame} seek={seek} />
      <p class="vp-note dim">{t("vpApprox")}</p>
    </div>
  );
}

// The timeline editor's inspector and transcript (G41.5c). The inspector shows what is chosen:
// a clip (fades, Ken Burns from its presets on a miniature, fit or fill, volume in dB, audio on,
// link), a text (its words, style and place), a transition (kind, direction, length), a subtitle
// (its words and times) with the subtitles' settings and files, and an audio track's ducking under
// the voice. The transcript lists the subtitles' words (G41.4's, from the transcription): a click
// on the first, Shift+click on the last, «Cut» takes them out of the whole timeline. Every change
// is one of video-timeline.ts's pure edits, handed to the editor's `commit`. Our own controls only:
// switches, drawn choices, sliders; never a checkbox, a select or a native dialog.
// G41.5d: the timeline's own settings with nothing chosen (its shape, 16:9 / 9:16 / 1:1, and the
// sound at −14 LUFS, A2), and on a clip what shows around a fitted picture (nothing, black, a
// blurred copy) and its crop, a frame on the miniature moved with the mouse, a finger or the
// arrows (A1).

import {
  captionsToSrt,
  captionsToVtt,
  clipLength,
  cutTimeRange,
  isMediaRef,
  isTextRef,
  kenBurnsPreset,
  lanes,
  moveCrop,
  needsReframe,
  type RgVideo,
  reframeCrop,
  removeCaptions,
  removeTransition,
  setCaption,
  setCaptionSettings,
  setClipProps,
  setFormat,
  setGenerator,
  setNormalize,
  setTrack,
  setTransition,
  timecode,
  trackOf,
  VIDEO_TEXT_POSITIONS,
  VIDEO_TEXT_STYLES,
  type VideoAspect,
  type VideoCaption,
  type VideoClip,
  type VideoEdit,
  type VideoIdGen,
  type VideoMediaInfo,
  type VideoRate,
  type VideoRect,
  type VideoTextRef,
  type VideoTransition,
  wholeCrop,
} from "@redgiant/protocol";
import { useEffect, useMemo, useRef, useState } from "preact/hooks";
import { lang, t } from "../../../i18n.js";
import { IconClose, IconDownload, IconLink, IconPencil, IconTrash } from "../../../icons.js";
import {
  dbText,
  KB_PRESETS,
  type KbPreset,
  kbPresetOf,
  secText,
  TRANSITION_DIRS,
  TRANSITION_FAMILIES,
  type TranscriptWordRef,
  transitionFamily,
  transitionKind,
  wordsSpan,
} from "../../../viewers/video-ops.js";
import { Seg } from "../../SettingsKit.js";
import { Toggle } from "../../ui.js";

type Commit = (next: RgVideo, what: VideoEdit, select?: string[]) => boolean;

/** A slider of ours: moves freely, the edit is made when it is let go (one change, one undo). */
export function Dial({
  label,
  value,
  min,
  max,
  step,
  format,
  onCommit,
}: {
  label: string;
  value: number;
  min: number;
  max: number;
  step: number;
  format: (v: number) => string;
  onCommit: (v: number) => void;
}) {
  const [live, setLive] = useState<number>();
  const v = live ?? value;
  const span = max - min || 1;
  return (
    // biome-ignore lint/a11y/noNoninteractiveElementInteractions: the label only keeps its slider's keys
    <label
      class="ve-dial"
      onKeyDown={(e) => {
        // One press, one step, one edit (Shift: ten); the editor's keys stay out of it.
        const k = e.key;
        const by =
          k === "ArrowRight" || k === "ArrowUp"
            ? 1
            : k === "ArrowLeft" || k === "ArrowDown"
              ? -1
              : k === "PageUp"
                ? 10
                : k === "PageDown"
                  ? -10
                  : 0;
        if (!by && k !== "Home" && k !== "End") return;
        e.preventDefault();
        e.stopPropagation();
        const n =
          k === "Home"
            ? min
            : k === "End"
              ? max
              : Math.max(min, Math.min(max, v + by * step * (e.shiftKey ? 10 : 1)));
        const r = Math.round(n / step) * step;
        setLive(undefined);
        if (r !== value) onCommit(r);
      }}
    >
      <span class="ve-dial-hd">
        <span>{label}</span>
        <output>{format(v)}</output>
      </span>
      <input
        type="range"
        min={min}
        max={max}
        step={step}
        value={v}
        aria-valuetext={format(v)}
        style={{ "--pct": String((v - min) / span) }}
        onInput={(e) => setLive(Number((e.target as HTMLInputElement).value))}
        onChange={(e) => {
          setLive(undefined);
          const n = Number((e.target as HTMLInputElement).value);
          if (n !== value) onCommit(n);
        }}
      />
    </label>
  );
}

/** A text edited in a box: the edit is made on leaving it, or Ctrl+Enter; Esc gives it back. */
function TextBox({
  label,
  value,
  onCommit,
  rows = 3,
  id,
}: {
  label: string;
  value: string;
  onCommit: (v: string) => void;
  rows?: number;
  id?: string;
}) {
  const [text, setText] = useState(value);
  useEffect(() => setText(value), [value]);
  const done = () => {
    if (text.trim() && text !== value) onCommit(text);
    else setText(value);
  };
  return (
    <label class="ve-field">
      <span>{label}</span>
      <textarea
        id={id}
        rows={rows}
        value={text}
        onInput={(e) => setText((e.target as HTMLTextAreaElement).value)}
        onBlur={done}
        onKeyDown={(e) => {
          e.stopPropagation();
          if (e.key === "Escape") {
            setText(value);
            (e.target as HTMLTextAreaElement).blur();
          }
          if (e.key === "Enter" && (e.ctrlKey || e.metaKey)) {
            e.preventDefault();
            done();
          }
        }}
      />
    </label>
  );
}

const pct = (n: number) => `${(n * 100).toFixed(1)}%`;
const rectStyle = (r: VideoRect) => ({
  left: pct(r.x),
  top: pct(r.y),
  width: pct(r.w),
  height: pct(r.h),
});

/** The picture of a clip, small: a photo itself, a video's first frame of its strip. */
function Thumb({ info, still }: { info: VideoMediaInfo | undefined; still: boolean }) {
  if (still && info?.file)
    return <span class="ve-thumb-pic" style={{ backgroundImage: `url("${info.file}")` }} />;
  if (info?.filmstrip)
    return (
      <span
        class="ve-thumb-pic strip"
        style={{
          backgroundImage: `url("${info.filmstrip.url}")`,
          backgroundSize: `${info.filmstrip.tiles * 100}% 100%`,
        }}
      />
    );
  return <span class="ve-thumb-pic none" />;
}

/** Ken Burns: the miniature with where it starts (solid) and ends (dashed), and the presets. */
function KenBurns({
  clip,
  info,
  onSet,
}: {
  clip: VideoClip;
  info: VideoMediaInfo | undefined;
  onSet: (p: KbPreset | "none") => void;
}) {
  const now = kbPresetOf(clip.kenBurns, kenBurnsPreset);
  const still = isMediaRef(clip.ref) && !!clip.ref.still;
  return (
    <div class="ve-kb">
      <span class="ve-label">{t("veKenBurns")}</span>
      <div class="ve-thumb" aria-hidden="true">
        <Thumb info={info} still={still} />
        {clip.kenBurns && (
          <>
            <span class="ve-kb-rect from" style={rectStyle(clip.kenBurns.from)} />
            <span class="ve-kb-rect to" style={rectStyle(clip.kenBurns.to)} />
          </>
        )}
      </div>
      <fieldset class="ve-kb-grid ve-group" aria-label={t("veKenBurns")}>
        <button
          type="button"
          class={`ve-kb-opt${now === "none" ? " on" : ""}`}
          aria-pressed={now === "none"}
          title={t("veKbNone")}
          onClick={() => onSet("none")}
        >
          <span class="ve-kb-word">{t("veKbNone")}</span>
        </button>
        {KB_PRESETS.map(([z, p]) => {
          const id = `${z}-${p}` as KbPreset;
          const kb = kenBurnsPreset(z, p);
          const label = t(`veKb_${z}_${p}`);
          return (
            <button
              key={id}
              type="button"
              class={`ve-kb-opt${now === id ? " on" : ""}`}
              aria-pressed={now === id}
              title={label}
              aria-label={label}
              onClick={() => onSet(id)}
            >
              <span class="ve-kb-mini" aria-hidden="true">
                <span class="ve-kb-rect from" style={rectStyle(kb.from)} />
                <span class="ve-kb-rect to" style={rectStyle(kb.to)} />
              </span>
            </button>
          );
        })}
      </fieldset>
      {now === "custom" && <p class="dim ve-small">{t("veKbCustom")}</p>}
    </div>
  );
}

/** A picture's size: the probe's, or (a photo, never probed) read from the file itself. */
function useSourceSize(info: VideoMediaInfo | undefined): { w: number; h: number } | undefined {
  const probed =
    info?.probe?.width && info.probe.height
      ? { w: info.probe.width, h: info.probe.height }
      : undefined;
  const [read, setRead] = useState<{ w: number; h: number }>();
  const file = !probed && info?.kind === "image" ? info.file : undefined;
  useEffect(() => {
    setRead(undefined);
    if (!file || typeof Image === "undefined") return;
    const img = new Image();
    img.onload = () => img.naturalWidth && setRead({ w: img.naturalWidth, h: img.naturalHeight });
    img.src = file;
  }, [file]);
  return probed ?? read;
}

/** One step of the arrows on the crop: a hundredth of the picture (Shift: a tenth). */
const CROP_STEP = 0.01;

/**
 * The crop (A1): the miniature with the part kept as a frame to move (the mouse, a finger, the
 * arrows; the edit is made on letting go), «Al centro» and «Togli». Without a crop a filled clip
 * shows its centre: the frame starts there.
 */
export function CropBox({
  clip,
  info,
  out,
  onSet,
}: {
  clip: VideoClip;
  info: VideoMediaInfo | undefined;
  out: { w: number; h: number };
  onSet: (crop: VideoRect | null) => void;
}) {
  const src = useSourceSize(info);
  const [live, setLive] = useState<VideoRect>();
  const box = useRef<HTMLDivElement>(null);
  const press = useRef<{ x: number; y: number; from: VideoRect; moved: boolean } | undefined>(
    undefined,
  );
  const has = !wholeCrop(clip.crop);
  if (!src || (!has && !needsReframe(src, out))) return null;
  const base = has ? (clip.crop as VideoRect) : reframeCrop(src, out);
  const r = live ?? base;
  const still = isMediaRef(clip.ref) && !!clip.ref.still;
  const done = (next: VideoRect) => {
    setLive(undefined);
    if (JSON.stringify(next) !== JSON.stringify(clip.crop)) onSet(next);
  };
  return (
    <div class="ve-crop">
      <span class="ve-label">{t("veCrop")}</span>
      <div
        class="ve-thumb ve-crop-thumb"
        ref={box}
        style={{
          aspectRatio: `${src.w} / ${src.h}`,
          width: `min(100%, ${Math.round((180 * src.w) / src.h)}px)`,
        }}
        onPointerMove={(e) => {
          const p = press.current;
          const el = box.current;
          if (!p || !el) return;
          const dx = (e.clientX - p.x) / Math.max(1, el.clientWidth);
          const dy = (e.clientY - p.y) / Math.max(1, el.clientHeight);
          if (Math.abs(dx) + Math.abs(dy) > 0.002) p.moved = true;
          setLive(moveCrop(p.from, dx, dy));
        }}
        onPointerUp={(e) => {
          const p = press.current;
          press.current = undefined;
          (e.currentTarget as HTMLElement).releasePointerCapture?.(e.pointerId);
          if (p?.moved && live) done(live);
          else setLive(undefined);
        }}
        onPointerCancel={() => {
          press.current = undefined;
          setLive(undefined);
        }}
      >
        <Thumb info={info} still={still} />
        <span class="ve-crop-shade" aria-hidden="true" style={rectStyle(r)} />
        <button
          type="button"
          class={`ve-crop-rect${has || live ? "" : " auto"}`}
          style={rectStyle(r)}
          aria-label={t("veCropMove")}
          title={t("veCropMoveHint")}
          onPointerDown={(e) => {
            e.preventDefault();
            e.stopPropagation();
            box.current?.setPointerCapture?.(e.pointerId);
            press.current = { x: e.clientX, y: e.clientY, from: base, moved: false };
          }}
          onKeyDown={(e) => {
            const k = e.key;
            const by = (e.shiftKey ? 10 : 1) * CROP_STEP;
            const d =
              k === "ArrowLeft"
                ? [-by, 0]
                : k === "ArrowRight"
                  ? [by, 0]
                  : k === "ArrowUp"
                    ? [0, -by]
                    : k === "ArrowDown"
                      ? [0, by]
                      : undefined;
            if (!d) return;
            // The editor's own arrows (the playhead) stay out of it.
            e.preventDefault();
            e.stopPropagation();
            done(moveCrop(base, d[0] as number, d[1] as number));
          }}
        />
      </div>
      <div class="ve-insp-row">
        <button type="button" class="vw-btn small" onClick={() => done(reframeCrop(src, out))}>
          {t("veCropCentre")}
        </button>
        <button type="button" class="vw-btn small" disabled={!has} onClick={() => onSet(null)}>
          {t("veCropRemove")}
        </button>
      </div>
    </div>
  );
}

/** The timeline's own settings, with nothing chosen: its shape and the sound's loudness. */
function TimelineSettings({ doc, commit }: { doc: RgVideo; commit: Commit }) {
  const f = doc.format;
  const aspects = [
    ["16:9", "veAspect_16_9"],
    ["9:16", "veAspect_9_16"],
    ["1:1", "veAspect_1_1"],
  ] as const satisfies readonly (readonly [VideoAspect, string])[];
  return (
    <section class="ve-insp-sec" aria-label={t("veTimelineSettings")}>
      <h5>{t("veTimelineSettings")}</h5>
      <span class="ve-label">{t("veAspect")}</span>
      <Seg
        label={t("veAspect")}
        value={f.aspect}
        options={aspects.map(([a, k]) => [a, t(k)])}
        onChange={(aspect) => commit(setFormat(doc, { aspect }), "format")}
      />
      <p class="dim ve-small">{t("veFormatSize", { w: String(f.width), h: String(f.height) })}</p>
      <Toggle
        label={t("veNormalize")}
        description={t("veNormalizeHelp")}
        checked={doc.normalize !== false}
        onChange={(on) => commit(setNormalize(doc, on), "format")}
      />
    </section>
  );
}

/** The subtitles' settings and files (shown with a subtitle, or with nothing chosen). */
function CaptionSettings({ doc, name, commit }: { doc: RgVideo; name: string; commit: Commit }) {
  const c = doc.captions;
  const save = (kind: "srt" | "vtt") => {
    const text =
      kind === "srt"
        ? captionsToSrt(c.segments, doc.format.rate)
        : captionsToVtt(c.segments, doc.format.rate);
    const url = URL.createObjectURL(new Blob([text], { type: "text/plain;charset=utf-8" }));
    const a = document.createElement("a");
    a.href = url;
    a.download = `${name.replace(/\.rgvideo$/i, "")}.${kind}`;
    a.click();
    setTimeout(() => URL.revokeObjectURL(url), 1000);
  };
  return (
    <section class="ve-insp-sec" aria-label={t("veCaptions")}>
      <h5>{t("veCaptions")}</h5>
      <Toggle
        label={t("veBurnIn")}
        description={t("veBurnInHelp")}
        checked={c.burnIn}
        onChange={(on) => commit(setCaptionSettings(doc, { burnIn: on }), "caption")}
      />
      <span class="ve-label">{t("veCaptionStyle")}</span>
      <Seg
        label={t("veCaptionStyle")}
        value={c.style}
        options={(["boxed", "plain", "bold"] as const).map((s) => [s, t(`veCapStyle_${s}`)])}
        onChange={(style) => commit(setCaptionSettings(doc, { style }), "caption")}
      />
      <span class="ve-label">{t("veCaptionPlace")}</span>
      <Seg
        label={t("veCaptionPlace")}
        value={c.position}
        options={(["bottom", "top"] as const).map((s) => [s, t(`vePos_${s}`)])}
        onChange={(position) => commit(setCaptionSettings(doc, { position }), "caption")}
      />
      <div class="ve-insp-row">
        <button
          type="button"
          class="vw-btn small"
          disabled={!c.segments.length}
          onClick={() => save("srt")}
        >
          <IconDownload size={13} /> SRT
        </button>
        <button
          type="button"
          class="vw-btn small"
          disabled={!c.segments.length}
          onClick={() => save("vtt")}
        >
          <IconDownload size={13} /> VTT
        </button>
      </div>
    </section>
  );
}

/** An audio track's ducking: down under the voice tracks, by how much. */
function Ducking({ doc, trackId, commit }: { doc: RgVideo; trackId: string; commit: Commit }) {
  const tr = trackOf(doc, trackId);
  if (tr?.kind !== "Audio") return null;
  const others = lanes(doc, "Audio").filter((id) => id !== trackId);
  const duck = tr.duck;
  const voice = others.filter((id) => doc.clips.some((c) => c.track === id));
  const it = lang.value === "it";
  return (
    <section class="ve-insp-sec" aria-label={t("veDucking")}>
      <h5>{t("veTrackOf", { name: tr.name })}</h5>
      <Toggle
        label={t("veDucking")}
        description={t("veDuckingHelp")}
        checked={!!duck}
        disabled={!others.length}
        onChange={(on) =>
          commit(
            setTrack(doc, trackId, {
              duck: on
                ? {
                    under: voice.length ? voice : others.slice(0, 1),
                    amountDb: -12,
                    attackMs: 200,
                    releaseMs: 600,
                  }
                : null,
            }),
            "track",
          )
        }
      />
      {duck && (
        <>
          <Dial
            label={t("veDuckAmount")}
            value={duck.amountDb}
            min={-40}
            max={0}
            step={1}
            format={(v) => dbText(v, it)}
            onCommit={(amountDb) =>
              commit(setTrack(doc, trackId, { duck: { ...duck, amountDb } }), "track")
            }
          />
          <span class="ve-label">{t("veDuckUnder")}</span>
          <fieldset class="ve-chips ve-group" aria-label={t("veDuckUnder")}>
            {others.map((id) => {
              const on = duck.under.includes(id);
              return (
                <button
                  key={id}
                  type="button"
                  class={`ve-chip${on ? " on" : ""}`}
                  aria-pressed={on}
                  onClick={() => {
                    const under = on ? duck.under.filter((u) => u !== id) : [...duck.under, id];
                    if (!under.length) return;
                    commit(setTrack(doc, trackId, { duck: { ...duck, under } }), "track");
                  }}
                >
                  {trackOf(doc, id)?.name ?? id}
                </button>
              );
            })}
          </fieldset>
        </>
      )}
    </section>
  );
}

export interface InspectorProps {
  doc: RgVideo;
  name: string;
  clip?: VideoClip | undefined;
  selected: number;
  transition?: VideoTransition | undefined;
  caption?: VideoCaption | undefined;
  info?: VideoMediaInfo | undefined;
  playhead: number;
  commit: Commit;
  onLink: () => void;
  onEditText: (id: string) => void;
  onClose?: (() => void) | undefined;
}

export function Inspector(p: InspectorProps) {
  const { doc, commit } = p;
  const rate = doc.format.rate;
  const it = lang.value === "it";
  const secs = (f: number) => secText(f, rate, it);
  const head = (title: string) => (
    <div class="ve-insp-head">
      <h4 title={title}>{title}</h4>
      {p.onClose && (
        <button
          type="button"
          class="vw-icon"
          title={t("veInspectorClose")}
          aria-label={t("veInspectorClose")}
          onClick={p.onClose}
        >
          <IconClose size={14} />
        </button>
      )}
    </div>
  );

  // ---- a transition ----
  if (p.transition) {
    const x = p.transition;
    const { family, dir } = transitionFamily(x.kind);
    const from = doc.clips.find((c) => c.id === x.from);
    const to = doc.clips.find((c) => c.id === x.to);
    const most = Math.max(
      2,
      Math.min(
        Math.round((rate.num / rate.den) * 4),
        (from ? clipLength(from) : 2) + (to ? clipLength(to) : 2),
      ),
    );
    const len = x.inOffset + x.outOffset;
    return (
      <div class="ve-insp-body">
        {head(t("veTransitionOf", { kind: t(`veFx_${family}`) }))}
        <dl>
          <dt>{t("veTrack")}</dt>
          <dd>{x.track}</dd>
          <dt>{t("veLength")}</dt>
          <dd>{secs(len)}</dd>
        </dl>
        <span class="ve-label">{t("veTransitionKind")}</span>
        <Seg
          label={t("veTransitionKind")}
          value={family}
          options={TRANSITION_FAMILIES.map((f) => [f, t(`veFx_${f}`)])}
          onChange={(f) =>
            commit(setTransition(doc, x.id, { kind: transitionKind(f, dir) }), "transition")
          }
        />
        {dir && (
          <>
            <span class="ve-label">{t("veDirection")}</span>
            <Seg
              label={t("veDirection")}
              value={dir}
              options={TRANSITION_DIRS.map((d) => [d, t(`veDir_${d}`)])}
              onChange={(d) =>
                commit(setTransition(doc, x.id, { kind: transitionKind(family, d) }), "transition")
              }
            />
          </>
        )}
        <Dial
          label={t("veTransitionLength")}
          value={len}
          min={2}
          max={most}
          step={1}
          format={secs}
          onCommit={(n) => {
            const a = Math.floor(n / 2);
            commit(setTransition(doc, x.id, { inOffset: a, outOffset: n - a }), "transition");
          }}
        />
        <button
          type="button"
          class="vw-btn small danger"
          onClick={() => commit(removeTransition(doc, x.id), "transition")}
        >
          <IconTrash size={13} /> {t("veTransitionRemove")}
        </button>
      </div>
    );
  }

  // ---- a subtitle ----
  if (p.caption) {
    const s = p.caption;
    return (
      <div class="ve-insp-body">
        {head(t("veCaption"))}
        <dl>
          <dt>{t("veStart")}</dt>
          <dd>{timecode(s.start, rate)}</dd>
          <dt>{t("veEnd")}</dt>
          <dd>{timecode(s.end, rate)}</dd>
        </dl>
        <TextBox
          id="ve-caption-text"
          label={t("veCaptionText")}
          value={s.text}
          onCommit={(text) => commit(setCaption(doc, s.id, { text }), "caption")}
        />
        <div class="ve-insp-row">
          <button
            type="button"
            class="vw-btn small"
            disabled={p.playhead >= s.end}
            onClick={() => commit(setCaption(doc, s.id, { start: p.playhead }), "caption")}
          >
            {t("veCaptionStartHere")}
          </button>
          <button
            type="button"
            class="vw-btn small"
            disabled={p.playhead <= s.start}
            onClick={() => commit(setCaption(doc, s.id, { end: p.playhead }), "caption")}
          >
            {t("veCaptionEndHere")}
          </button>
        </div>
        <button
          type="button"
          class="vw-btn small danger"
          onClick={() => commit(removeCaptions(doc, [s.id]), "caption")}
        >
          <IconTrash size={13} /> {t("veCaptionRemove")}
        </button>
        <CaptionSettings doc={doc} name={p.name} commit={commit} />
      </div>
    );
  }

  const c = p.clip;
  if (!c)
    return (
      <div class="ve-insp-body">
        {head(t("veInspector"))}
        <p class="dim">{t("veInspectorNone")}</p>
        <TimelineSettings doc={doc} commit={commit} />
        <CaptionSettings doc={doc} name={p.name} commit={commit} />
      </div>
    );

  const tr = trackOf(doc, c.track);
  const audio = tr?.kind === "Audio";
  const text = isTextRef(c.ref) ? (c.ref as VideoTextRef) : undefined;
  const media = isMediaRef(c.ref);
  const len = clipLength(c);
  const fadeMax = Math.max(0, Math.min(Math.floor(len / 2), Math.round((rate.num / rate.den) * 5)));
  const ids = [c.id];
  const props = (x: Parameters<typeof setClipProps>[2]) =>
    commit(setClipProps(doc, ids, x), "props");
  const label = text
    ? text.text
    : (c.name ?? (media ? (c.ref as { media: string }).media.split("/").pop() : t("veColour")));
  return (
    <div class="ve-insp-body">
      {head(label ?? "")}
      <dl>
        <dt>{t("veTrack")}</dt>
        <dd>{tr?.name ?? c.track}</dd>
        <dt>{t("veStart")}</dt>
        <dd>{timecode(c.start, rate)}</dd>
        <dt>{t("veLength")}</dt>
        <dd>{timecode(len, rate)}</dd>
        {media && !(c.ref as { still?: boolean }).still && (
          <>
            <dt>{t("veSourceInOut")}</dt>
            <dd>
              {timecode(c.sourceRange.start, rate)} - {timecode(c.sourceRange.start + len, rate)}
            </dd>
          </>
        )}
      </dl>
      {p.selected > 1 && <p class="dim ve-small">{t("veSelected", { n: String(p.selected) })}</p>}
      <Toggle
        label={audio ? t("veAudioOn") : t("veClipOn")}
        description={audio ? t("veAudioOnHelp") : t("veClipOnHelp")}
        checked={c.enabled}
        onChange={(on) => props({ enabled: on })}
      />
      {text && (
        <section class="ve-insp-sec" aria-label={t("veText")}>
          <TextBox
            id="ve-text-words"
            label={t("veTextWords")}
            value={text.text}
            onCommit={(v) => commit(setGenerator(doc, c.id, { text: v }), "text")}
          />
          <button type="button" class="vw-btn small" onClick={() => p.onEditText(c.id)}>
            <IconPencil size={13} /> {t("veEditOnPicture")}
          </button>
          <span class="ve-label">{t("veTextStyle")}</span>
          <Seg
            label={t("veTextStyle")}
            value={text.style}
            options={VIDEO_TEXT_STYLES.map((s) => [s, t(`veStyle_${s}`)])}
            onChange={(style) => commit(setGenerator(doc, c.id, { style }), "text")}
          />
          <span class="ve-label">{t("veTextPlace")}</span>
          <Seg
            label={t("veTextPlace")}
            value={text.position}
            options={VIDEO_TEXT_POSITIONS.map((s) => [s, t(`vePos_${s}`)])}
            onChange={(position) => commit(setGenerator(doc, c.id, { position }), "text")}
          />
        </section>
      )}
      {audio && (
        <Dial
          label={t("veVolume")}
          value={Math.max(-30, Math.min(12, c.volume))}
          min={-30}
          max={12}
          step={0.5}
          format={(v) => dbText(v, it)}
          onCommit={(volume) => props({ volume })}
        />
      )}
      {fadeMax > 0 && (
        <>
          <Dial
            label={audio ? t("veFadeInAudio") : t("veFadeIn")}
            value={Math.min(c.fadeIn, fadeMax)}
            min={0}
            max={fadeMax}
            step={1}
            format={secs}
            onCommit={(fadeIn) => props({ fadeIn })}
          />
          <Dial
            label={audio ? t("veFadeOutAudio") : t("veFadeOut")}
            value={Math.min(c.fadeOut, fadeMax)}
            min={0}
            max={fadeMax}
            step={1}
            format={secs}
            onCommit={(fadeOut) => props({ fadeOut })}
          />
        </>
      )}
      {!audio && media && (
        <>
          <span class="ve-label">{t("veFitLabel")}</span>
          <Seg
            label={t("veFitLabel")}
            value={c.fit}
            options={[
              ["fill", t("veFill")],
              ["fit", t("veFitIn")],
            ]}
            onChange={(fit) => props({ fit })}
          />
          {c.fit === "fit" && (
            <>
              <span class="ve-label">{t("veBackground")}</span>
              <Seg
                label={t("veBackground")}
                value={c.background ?? "none"}
                options={[
                  ["none", t("veBg_none")],
                  ["black", t("veBg_black")],
                  ["blur", t("veBg_blur")],
                ]}
                onChange={(b) => props({ background: b === "none" ? null : b })}
              />
            </>
          )}
          <CropBox
            clip={c}
            info={p.info}
            out={{ w: doc.format.width, h: doc.format.height }}
            onSet={(crop) => props({ crop })}
          />
          <KenBurns
            clip={c}
            info={p.info}
            onSet={(id) => {
              if (id === "none") return props({ kenBurns: null });
              const [z, d] = id.split("-") as ["in" | "out", "left" | "right" | "up" | "down"];
              props({ kenBurns: kenBurnsPreset(z, d) });
            }}
          />
        </>
      )}
      <button type="button" class="vw-btn small" onClick={p.onLink}>
        <IconLink size={13} /> {c.link ? t("veUnlinkClip") : t("veLinkClip")}
      </button>
      {audio && <Ducking doc={doc} trackId={c.track} commit={commit} />}
    </div>
  );
}

// ---- the transcript ----------------------------------------------------------------------------

export function TranscriptPanel({
  doc,
  words,
  chosen,
  playhead,
  rate,
  busy,
  onChoose,
  onSeek,
  commit,
  gen,
  onFromSpeech,
  onClose,
}: {
  doc: RgVideo;
  words: TranscriptWordRef[];
  chosen: { a: number; b: number } | undefined;
  playhead: number;
  rate: VideoRate;
  busy: boolean;
  onChoose: (w: { a: number; b: number } | undefined) => void;
  onSeek: (f: number) => void;
  commit: Commit;
  gen: VideoIdGen;
  onFromSpeech: () => void;
  onClose: () => void;
}) {
  const [focus, setFocus] = useState(0);
  const list = useRef<HTMLDivElement>(null);
  const lo = chosen ? Math.min(chosen.a, chosen.b) : -1;
  const hi = chosen ? Math.max(chosen.a, chosen.b) : -1;
  const span = chosen ? wordsSpan(words, chosen.a, chosen.b, rate) : undefined;
  const groups = useMemo(() => {
    const out: { cap: string; start: number; items: number[] }[] = [];
    words.forEach((w, i) => {
      const last = out.at(-1);
      if (last?.cap === w.cap) last.items.push(i);
      else out.push({ cap: w.cap, start: w.start, items: [i] });
    });
    return out;
  }, [words]);
  const cut = () => {
    if (!span) return;
    const next = cutTimeRange(doc, span[0], span[1], { ids: gen });
    if (commit(next, "ripple_delete")) {
      onChoose(undefined);
      onSeek(span[0]);
    }
  };
  const pick = (i: number, extend: boolean) => {
    setFocus(i);
    onChoose(extend && chosen ? { a: chosen.a, b: i } : { a: i, b: i });
    const w = words[i];
    if (w && !extend) onSeek(w.start);
  };
  const go = (i: number, extend: boolean) => {
    const n = Math.max(0, Math.min(words.length - 1, i));
    pick(n, extend);
    list.current?.querySelector<HTMLElement>(`[data-word="${n}"]`)?.focus();
  };
  return (
    <section class="ve-transcript" aria-label={t("veTranscript")}>
      <div class="ve-transcript-bar">
        <strong>{t("veTranscript")}</strong>
        <span class="dim ve-small">{t("veTranscriptHint")}</span>
        <div class="spacer" />
        <button type="button" class="vw-btn small" disabled={busy} onClick={onFromSpeech}>
          {busy ? t("veTranscribing") : t("veFromSpeech")}
        </button>
        <button
          type="button"
          class="vw-btn small primary"
          disabled={!span}
          onClick={cut}
          title={span ? t("veCutWordsHint", { tc: timecode(span[0], rate) }) : undefined}
        >
          {t("veCutWords", { n: String(chosen ? hi - lo + 1 : 0) })}
        </button>
        <button
          type="button"
          class="vw-icon"
          title={t("veTranscriptClose")}
          aria-label={t("veTranscriptClose")}
          onClick={onClose}
        >
          <IconClose size={14} />
        </button>
      </div>
      {!words.length ? (
        <p class="dim ve-small">{t("veTranscriptEmpty")}</p>
      ) : (
        // biome-ignore lint/a11y/useSemanticElements: paragraphs of words (a fieldset would break the lines' flow); the arrows move among them
        <div
          class="ve-words"
          ref={list}
          role="group"
          aria-label={t("veTranscriptWords")}
          onKeyDown={(e) => {
            const k = e.key;
            if (k === "ArrowRight" || k === "ArrowLeft") {
              e.preventDefault();
              e.stopPropagation();
              go(focus + (k === "ArrowRight" ? 1 : -1), e.shiftKey);
            } else if (k === "Delete" || k === "Backspace") {
              e.preventDefault();
              e.stopPropagation();
              cut();
            } else if (k === "Escape") {
              e.stopPropagation();
              onChoose(undefined);
            }
          }}
        >
          {groups.map((g) => (
            <p key={g.cap} class="ve-words-line">
              <span class="ve-words-tc">{timecode(g.start, rate)}</span>
              {g.items.map((i) => {
                const w = words[i] as TranscriptWordRef;
                const on = i >= lo && i <= hi;
                const now = playhead >= w.start && playhead < w.end;
                return (
                  <button
                    key={i}
                    type="button"
                    data-word={i}
                    tabIndex={i === focus ? 0 : -1}
                    class={`ve-word${on ? " on" : ""}${now ? " now" : ""}`}
                    aria-pressed={on}
                    onClick={(e) => pick(i, e.shiftKey)}
                  >
                    {w.text}
                  </button>
                );
              })}
            </p>
          ))}
        </div>
      )}
    </section>
  );
}

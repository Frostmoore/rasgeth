// The timeline editor in the canvas (G41.5b), at an editor's level and with Resolve's keys: the
// program viewer (the player of G41.5a on the proxies) and, when wanted, the source viewer with
// In and Out; under them the timeline at full width: track headers (locked, hidden or muted, the
// destination of F9/F10, add and remove), a ruler in timecode with the markers, zoom, clips with
// their strip of frames or waveform, the tools A (select), B (blade), T (ripple trim), a marquee,
// linked selection, snapping, dragging across tracks, edges that trim (Alt: one side only, for
// J- and L-cuts), gaps to choose and close; the files of this timeline in a row (dragged in, or from
// the project's files). Every change is one of the protocol's pure edits (video-timeline.ts) sent
// to the host as its difference (video-ops.ts): revisions, undo, an agent's changes highlighted.
// The clip's inspector, texts, subtitles and the phone are G41.5c (the inspector's place is here).

import {
  addMarker,
  addTrack,
  addedClips,
  appendClip,
  applyVideoAction,
  bladeAt,
  clipAt,
  clipEnd,
  clipOf,
  closeGap,
  copyClips,
  type DocChange,
  type DocFile,
  fps,
  isMediaRef,
  lanes,
  liftClips,
  linkClips,
  moveClips,
  nextEdit,
  PERSON,
  pasteClips,
  placeClip,
  prevEdit,
  type RgVideo,
  removeMarker,
  removeTrack,
  rippleDeleteClips,
  setClipProps,
  setMarker,
  setTrack,
  snap,
  snapPoints,
  timecode,
  timelineDuration,
  trackClips,
  trackOf,
  trimClip,
  unlinkClips,
  type VideoClip,
  type VideoEdit,
  type VideoMediaInfo,
  type VideoTrack,
  withLinked,
} from "@redgiant/protocol";
import type { JSX } from "preact";
import { useEffect, useMemo, useRef, useState } from "preact/hooks";
import { announce, typingIn } from "../../a11y.js";
import { t } from "../../i18n.js";
import {
  IconAppend,
  IconBlade,
  IconChevronLeft,
  IconChevronRight,
  IconClose,
  IconCursor,
  IconEye,
  IconEyeOff,
  IconFilm,
  IconFlag,
  IconImage,
  IconInsert,
  IconKeyboard,
  IconLink,
  IconLock,
  IconMagnet,
  IconMarkIn,
  IconMarkOut,
  IconMaximize,
  IconMinus,
  IconMusic,
  IconOverwrite,
  IconPause,
  IconPlay,
  IconPlus,
  IconRedo,
  IconRippleTrim,
  IconSpeaker,
  IconSpeakerOff,
  IconTrash,
  IconUndo,
  IconUnlock,
} from "../../icons.js";
import {
  EXACT_LENGTHS,
  getApi,
  openDoc,
  saveDoc,
  sendDoc,
  setVideoEdit,
  setVideoView,
  type VideoEditState,
  videoClipboard,
  videoEditOf,
  videoViewKey,
  videoViewOf,
} from "../../state.js";
import { holdMark } from "../../viewers/agent-marks.js";
import { OwnUndo } from "../../viewers/own-undo.js";
import {
  clampPpf,
  edgeAt,
  editAction,
  fitPpf,
  gapAt,
  isTimelineMedia,
  mediaRefOf,
  PageIds,
  rulerTicks,
  shuttleRate,
  snapBlock,
  sourceLength,
  touchedIds,
  VIDEO_KEYS,
  type VideoCommand,
  VideoCollab,
  videoActionsOf,
  videoDocOp,
  videoKey,
} from "../../viewers/video-ops.js";
import { askText } from "../dialogs.js";
import { Modal } from "../ui.js";
import { type PlayerMediaMap, TimelinePlayer } from "./video/player.js";
import { ExactJob, PrepJob, playerMediaOf, useFonts, usePrepared } from "./VideoPreview.js";

export const TIMELINE_EDITABLE = /\.rgvideo$/i;

/** The track headers' width (they stay at the left while the timeline scrolls). */
export const HEAD_W = 152;
const LANE_H: Record<VideoTrack["kind"], number> = { Video: 58, Audio: 44 };
const RULER_H = 26;
const SNAP_PX = 10;
const EDGE_PX = 7;
/** The page's own drag data: a file of the project (with its In and Out when from the source). */
const MEDIA_TYPE = "application/x-redgiant-media";
/** The project's files tree (Explorer.tsx). */
export const FILE_TYPE = "application/x-redgiant-file";

let asks = 0;
const askId = () => `v${Date.now().toString(36)}${(asks++).toString(36)}`;
const newGroup = () => `g-${Math.random().toString(36).slice(2, 10)}`;

const MARKER_COLORS = ["BLUE", "GREEN", "RED", "YELLOW", "PURPLE", "CYAN"] as const;

type Drag =
  | { mode: "scrub" }
  | {
      mode: "move";
      id: string;
      sel: string[];
      x0: number;
      y0: number;
      base: RgVideo;
      track0: string;
      moved: boolean;
      linked: boolean;
      view?: RgVideo;
    }
  | {
      mode: "trim";
      id: string;
      edge: "in" | "out";
      x0: number;
      base: RgVideo;
      ripple: boolean;
      linked: boolean;
      view?: RgVideo;
    }
  | { mode: "marquee"; x0: number; y0: number; keep: string[]; frame: number; moved: boolean };

interface HostApi {
  commit(next: RgVideo, what: VideoEdit, select?: string[]): boolean;
  undo(): void;
  redo(): void;
  presence(on: boolean): void;
}

/** A clip's words: its file's name, a text's words, a colour's name. */
export function clipLabel(c: VideoClip): string {
  if (isMediaRef(c.ref)) return c.name ?? c.ref.media.split("/").pop() ?? c.ref.media;
  if ("text" in c.ref) return c.ref.text;
  return c.name ?? t("veColour");
}

const fileName = (m: string) => m.split("/").pop() ?? m;
const kindIcon = (info: VideoMediaInfo | undefined, media: string) =>
  info?.kind === "image" || /\.(png|jpe?g|webp|gif|bmp|tiff?|avif|heic|heif)$/i.test(media) ? (
    <IconImage size={13} />
  ) : info?.kind === "audio" ||
    /\.(mp3|wav|m4a|aac|flac|ogg|oga|opus|weba|wma|aiff?)$/i.test(media) ? (
    <IconMusic size={13} />
  ) : (
    <IconFilm size={13} />
  );

/** A button of the editor's bars: a drawn icon, its words as title and label. */
function Tool({
  label,
  keys,
  on,
  pressed,
  disabled,
  children,
  class: cls,
}: {
  label: string;
  keys?: string;
  on: () => void;
  pressed?: boolean;
  disabled?: boolean;
  children: JSX.Element | JSX.Element[];
  class?: string;
}) {
  const title = keys ? `${label} (${keys})` : label;
  return (
    <button
      type="button"
      class={`vw-icon ve-tool${pressed ? " on" : ""}${cls ? ` ${cls}` : ""}`}
      title={title}
      aria-label={title}
      {...(pressed !== undefined && { "aria-pressed": pressed })}
      disabled={disabled}
      onClick={on}
    >
      {children}
    </button>
  );
}

/** The source viewer: one file, its In and Out (I/O), and where it goes (F9, F10, Shift+F12). */
function SourceViewer({
  info,
  source,
  rate,
  onSet,
  onPlace,
  onClose,
}: {
  info: VideoMediaInfo | undefined;
  source: NonNullable<VideoEditState["source"]>;
  rate: RgVideo["format"]["rate"];
  onSet: (patch: Partial<NonNullable<VideoEditState["source"]>>) => void;
  onPlace: (mode: "insert" | "overwrite" | "append") => void;
  onClose: () => void;
}) {
  const v = useRef<HTMLVideoElement>(null);
  const [playing, setPlaying] = useState(false);
  const f = fps(rate);
  const ref = mediaRefOf(info, source.media, rate);
  const len = ref ? sourceLength(ref, rate) : Math.max(source.out, 1);
  const src = info?.proxy ?? info?.file;
  const still = ref?.still || info?.kind === "image";
  const at = Math.max(0, Math.min(len, source.at));
  // A new file, or a jump from the keys: the element goes there.
  useEffect(() => {
    const el = v.current;
    if (!el || playing) return;
    if (Math.abs(el.currentTime * f - at) > 0.5) el.currentTime = at / f;
  }, [at, source.media, src]);
  const seek = (x: number) => onSet({ at: Math.max(0, Math.min(len, Math.round(x))) });
  const toggle = () => {
    const el = v.current;
    if (!el) return;
    if (el.paused) {
      if (at >= source.out) el.currentTime = source.in / f;
      void el.play();
    } else el.pause();
  };
  const scrub = (e: PointerEvent) => {
    const el = e.currentTarget as HTMLElement;
    const go = (x: number) => {
      const r = el.getBoundingClientRect();
      seek(((x - r.left) / Math.max(1, r.width)) * len);
    };
    go(e.clientX);
    const move = (m: PointerEvent) => go(m.clientX);
    const up = () => {
      window.removeEventListener("pointermove", move);
      window.removeEventListener("pointerup", up);
    };
    window.addEventListener("pointermove", move);
    window.addEventListener("pointerup", up);
  };
  const pct = (x: number) => `${((x / Math.max(1, len)) * 100).toFixed(3)}%`;
  return (
    <section class="ve-source" aria-label={t("veSource")} data-source="">
      <div class="ve-viewer-head">
        <strong title={source.media}>{fileName(source.media)}</strong>
        <span class="dim">{t("veSource")}</span>
        <div class="spacer" />
        <button
          type="button"
          class="vw-icon"
          title={t("veSourceClose")}
          aria-label={t("veSourceClose")}
          onClick={onClose}
        >
          <IconClose size={13} />
        </button>
      </div>
      <div class="ve-source-screen">
        {still && info?.file ? (
          <img src={info.file} alt={fileName(source.media)} />
        ) : src ? (
          // biome-ignore lint/a11y/useMediaCaption: a file of the project, shown to choose a part
          <video
            ref={v}
            src={src}
            preload="auto"
            playsInline
            onPlay={() => setPlaying(true)}
            onPause={() => setPlaying(false)}
            onTimeUpdate={(e) => {
              const el = e.currentTarget as HTMLVideoElement;
              const now = Math.round(el.currentTime * f);
              if (!el.paused && now >= source.out) el.pause();
              onSet({ at: now });
            }}
          />
        ) : (
          <p class="dim">{t("vePreparingFile", { name: fileName(source.media) })}</p>
        )}
      </div>
      <div
        class="ve-source-scrub"
        role="slider"
        tabIndex={0}
        aria-label={t("veSourcePosition")}
        aria-valuemin={0}
        aria-valuemax={len}
        aria-valuenow={at}
        aria-valuetext={timecode(at, rate)}
        onPointerDown={scrub}
      >
        <span
          class="ve-source-range"
          style={{ left: pct(source.in), width: pct(source.out - source.in) }}
        />
        <span class="ve-source-knob" style={{ left: pct(at) }} />
      </div>
      <div class="vw-bar ve-source-bar">
        <Tool label={playing ? t("vpPause") : t("vpPlay")} keys={t("veKeySpace")} on={toggle}>
          {playing ? <IconPause size={14} /> : <IconPlay size={14} />}
        </Tool>
        <Tool label={t("veMarkIn")} keys="I" on={() => onSet({ in: Math.min(at, source.out - 1) })}>
          <IconMarkIn />
        </Tool>
        <Tool
          label={t("veMarkOut")}
          keys="O"
          on={() => onSet({ out: Math.max(at, source.in + 1) })}
        >
          <IconMarkOut />
        </Tool>
        <span class="ve-tc" title={t("veSourceInOut")}>
          {timecode(source.in, rate)} <span class="dim">-</span> {timecode(source.out, rate)}{" "}
          <span class="dim">({timecode(source.out - source.in, rate)})</span>
        </span>
        <div class="spacer" />
        <Tool label={t("veInsert")} keys="F9" on={() => onPlace("insert")} disabled={!ref}>
          <IconInsert />
        </Tool>
        <Tool label={t("veOverwrite")} keys="F10" on={() => onPlace("overwrite")} disabled={!ref}>
          <IconOverwrite />
        </Tool>
        <Tool label={t("veAppend")} keys="Shift+F12" on={() => onPlace("append")} disabled={!ref}>
          <IconAppend />
        </Tool>
        {/* biome-ignore lint/a11y/noStaticElementInteractions: only the mouse drags; F9, F10 and Shift+F12 place from the keys */}
        <span
          class="ve-source-drag"
          draggable
          title={t("veSourceDrag")}
          onDragStart={(e) => {
            e.dataTransfer?.setData(
              MEDIA_TYPE,
              JSON.stringify({ media: source.media, in: source.in, out: source.out }),
            );
            if (e.dataTransfer) e.dataTransfer.effectAllowed = "copy";
          }}
        >
          <IconFilm size={13} />
          {t("veSourceDragShort")}
        </span>
      </div>
    </section>
  );
}

export function VideoEditor({
  file,
  onReveal,
}: {
  file: DocFile;
  onReveal?: (reveal: ((c: DocChange) => void) | undefined) => void;
}) {
  const key = videoViewKey(file);
  const view = videoViewOf(key);
  const ed = videoEditOf(key);
  const edit = (patch: Partial<VideoEditState>) => setVideoEdit(key, patch);
  const [doc, setDoc] = useState<RgVideo>();
  /** The timeline while a drag goes on (committed on release). */
  const [shown, setShown] = useState<RgVideo>();
  /** What agents just changed: highlighted, with who. */
  const [marks, setMarks] = useState<Record<string, { who: string; rev: number }>>({});
  const [marquee, setMarquee] = useState<{ x: number; y: number; w: number; h: number }>();
  const [dropHint, setDropHint] = useState<{ track: string; frame: number }>();
  const [notice, setNotice] = useState<string>();
  const [selMarker, setSelMarker] = useState<string>();
  const root = useRef<HTMLElement>(null);
  const rows = useRef<HTMLDivElement>(null);
  const scroller = useRef<HTMLDivElement>(null);
  const stage = useRef<HTMLDivElement>(null);
  const audioBox = useRef<HTMLDivElement>(null);
  const player = useRef<TimelinePlayer | undefined>(undefined);
  const host = useRef<HostApi | undefined>(undefined);
  const ids = useRef(new PageIds());
  const drag = useRef<Drag | undefined>(undefined);
  const noticeTimer = useRef<ReturnType<typeof setTimeout> | undefined>(undefined);
  /** A file dropped before the server read it: placed once its probe is there. */
  const pendingPlace = useRef<
    | {
        media: string;
        in: number;
        out?: number;
        frame: number;
        targets: { video: string | null; audio: string | null };
        mode: "insert" | "overwrite" | "append";
      }
    | undefined
  >(undefined);

  const say = (text: string) => {
    setNotice(text);
    announce(text);
    if (noticeTimer.current) clearTimeout(noticeTimer.current);
    noticeTimer.current = setTimeout(() => setNotice(undefined), 4000);
  };

  // ---- the host: the timeline, others' revisions, the person's own ------------------------
  useEffect(() => {
    let closed = false;
    let json: RgVideo | undefined;
    let group = newGroup();
    const own = new OwnUndo();
    const sentIn = new Map<string, string>();
    const fading = new Map<number, () => void>();
    const collab = new VideoCollab((o) => {
      sentIn.set(o.clientId, group);
      sendDoc({
        type: "doc.ops",
        file,
        clientId: o.clientId,
        baseRevision: o.baseRevision,
        ops: o.actions.map(videoDocOp),
        groupId: group,
      });
    });
    const resync = () => sendDoc({ type: "doc.open", file });
    const set = (d: RgVideo) => {
      json = d;
      setDoc(d);
    };
    const close = openDoc(file, {
      opened(snapshot, revision) {
        if (snapshot.family !== "video") return;
        collab.reset(revision);
        own.forget();
        set(snapshot.doc);
      },
      replaced(m) {
        if (m.snapshot.family !== "video") return;
        collab.reset(m.revision);
        own.forget();
        set(m.snapshot.doc);
      },
      changed(m) {
        if (!json) return resync();
        const actions = videoActionsOf(m.ops);
        if (collab.remote(m.revision, actions) === "reload") return resync();
        set(actions.reduce(applyVideoAction, json));
        own.changed(m.change);
        // An undone change loses its highlight (and its «Annulla questa modifica»).
        for (const r of m.change.undoOf ?? []) {
          fading.get(r)?.();
          fading.delete(r);
        }
        if (m.change.author === PERSON || m.change.replaced) return;
        const who = m.change.authorName ?? m.change.author;
        const rev = m.change.revision;
        const touched = [...touchedIds(actions)];
        setMarks((x) => ({ ...x, ...Object.fromEntries(touched.map((id) => [id, { who, rev }])) }));
        fading.set(
          rev,
          holdMark(
            file,
            rev,
            () => root.current,
            () => {
              fading.delete(rev);
              if (closed) return;
              setMarks((x) =>
                Object.fromEntries(Object.entries(x).filter(([, v]) => v.rev !== rev)),
              );
            },
          ),
        );
      },
      ack(m) {
        if (!collab.ack(m.clientId, m.revision)) return;
        own.made(m.revision, sentIn.get(m.clientId) ?? `r${m.revision}`);
        sentIn.delete(m.clientId);
        // Ctrl+Z pressed before this was confirmed (p3.5.7): asked now, for the right gesture.
        for (const ask of own.release(collab.pending))
          sendDoc({ type: "doc.undo", file, clientId: askId(), ...ask });
      },
      rejected(m) {
        if (collab.rejected(m.clientId)) {
          own.forget();
          resync();
        }
      },
    });
    host.current = {
      commit(next, what, select) {
        if (!json) return false;
        const a = editAction(json, next, what);
        if (!a) return false;
        group = newGroup();
        set(next);
        collab.local(a);
        const have = new Set(next.clips.map((c) => c.id));
        const sel = (select ?? videoEditOf(key).sel).filter((id) => have.has(id));
        setVideoEdit(key, { sel });
        return true;
      },
      undo() {
        const ask = own.press("undo", collab.pending);
        if (ask) sendDoc({ type: "doc.undo", file, clientId: askId(), ...ask });
      },
      redo() {
        const ask = own.press("redo", collab.pending);
        if (ask) sendDoc({ type: "doc.undo", file, clientId: askId(), ...ask });
      },
      presence(on) {
        sendDoc({
          type: "doc.presence",
          file,
          editing: on,
          from: 0,
          to: 0,
          revision: collab.revision,
        });
      },
    };
    return () => {
      closed = true;
      for (const cancel of fading.values()) cancel();
      close();
      host.current = undefined;
    };
  }, [file.scope, file.path]);

  // ---- the files: prepared on the server, the player ---------------------------------------
  const { prepared, pending, preparing, jobEnded } = usePrepared(file, doc, ed.pool);
  const mediaMap: PlayerMediaMap = useMemo(() => playerMediaOf(prepared?.media), [prepared]);
  const byName = useMemo(
    () =>
      Object.fromEntries((prepared?.media ?? []).map((m) => [m.media, m])) as Record<
        string,
        VideoMediaInfo
      >,
    [prepared],
  );
  useFonts(prepared?.fonts);

  useEffect(() => {
    if (!stage.current || !audioBox.current) return;
    const p = new TimelinePlayer({
      stage: stage.current,
      audioBox: audioBox.current,
      onFrame: (f) => {
        setVideoView(key, { frame: f });
        follow(f);
      },
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
  const showing = shown ?? doc;
  useEffect(() => {
    if (showing) player.current?.setDoc(showing, mediaMap);
  }, [showing, mediaMap]);
  useEffect(() => {
    const el = stage.current;
    if (!el || typeof ResizeObserver === "undefined") return;
    const ro = new ResizeObserver(() =>
      el.style.setProperty("--side", `${Math.min(el.clientWidth, el.clientHeight)}px`),
    );
    ro.observe(el);
    return () => ro.disconnect();
  }, [!!doc]);

  // A file dropped before it was read: placed now that its probe came.
  useEffect(() => {
    const p = pendingPlace.current;
    if (!p || !doc) return;
    const info = byName[p.media];
    if (info?.missing) {
      pendingPlace.current = undefined;
      say(t("veFileMissing", { name: fileName(p.media) }));
      return;
    }
    if (!mediaRefOf(info, p.media, doc.format.rate)) return;
    pendingPlace.current = undefined;
    place(p.media, p.in, p.out, p.frame, p.targets, p.mode);
  }, [byName]);

  // The first fit, once the timeline and its width are known.
  useEffect(() => {
    if (!doc || ed.ppf !== undefined) return;
    const w = scroller.current?.clientWidth ?? 900;
    edit({ ppf: fitPpf(w - HEAD_W, timelineDuration(doc), doc.format.rate) });
  }, [!!doc]);

  // «Show» in the changes' panel: the clip the change was about, chosen and in view.
  useEffect(() => {
    onReveal?.((c: DocChange) => {
      const id = c.summary.video?.id;
      if (!id) return;
      const el = rows.current?.querySelector<HTMLElement>(`[data-clip="${CSS.escape(id)}"]`);
      if (!el) return;
      edit({ sel: [id] });
      el.scrollIntoView({ block: "nearest", inline: "center" });
    });
    return () => onReveal?.(undefined);
  }, []);

  if (!doc) return <div class="vw-empty dim">{t("loading")}</div>;

  // ---- geometry ----------------------------------------------------------------------------
  const rate = doc.format.rate;
  const f1 = fps(rate);
  const sec = Math.max(1, Math.round(f1));
  const ppf = ed.ppf ?? 1;
  const total = Math.max(timelineDuration(showing as RgVideo), Math.round(f1 * 10));
  const width = Math.ceil((total + f1 * 30) * ppf);
  const playhead = Math.max(0, view.frame);
  const th = Math.ceil(SNAP_PX / ppf);
  const has = new Set(doc.clips.map((c) => c.id));
  const sel = ed.sel.filter((id) => has.has(id));
  const selSet = new Set(sel);
  const linked = ed.linkedSel;
  const gen = (d: RgVideo) => ids.current.for(d);
  const commit = (next: RgVideo, what: VideoEdit, select?: string[]) =>
    host.current?.commit(next, what, select) ?? false;
  const frameAt = (clientX: number) => {
    const r = rows.current?.getBoundingClientRect();
    const f = Math.round((clientX - (r?.left ?? 0) - HEAD_W) / ppf);
    return Number.isFinite(f) ? Math.max(0, f) : playhead;
  };
  const trackUnder = (x: number, y: number) =>
    (document.elementFromPoint?.(x, y) as HTMLElement | null)?.closest<HTMLElement>("[data-lane]")
      ?.dataset.lane;
  const snapFrame = (f: number, exclude: ReadonlySet<string>) =>
    ed.snapping ? snap(f, snapPoints(doc, exclude, playhead), th) : f;
  function follow(f: number) {
    const sc = scroller.current;
    if (!sc) return;
    const x = f * (videoEditOf(key).ppf ?? 1);
    const left = sc.scrollLeft;
    const room = sc.clientWidth - HEAD_W;
    if (x < left || x > left + room - 30) sc.scrollLeft = Math.max(0, x - room * 0.25);
  }

  // ---- playing -----------------------------------------------------------------------------
  const seek = (f: number) => {
    const g = Math.max(0, Math.min(total + Math.round(f1 * 30), Math.round(f)));
    player.current?.seek(g);
    setVideoView(key, { frame: g });
    follow(g);
  };
  const stop = () => {
    const p = player.current;
    if (!p) return;
    p.pause();
    setVideoView(key, { playing: false, frame: p.frame });
  };
  const shuttle = (r: number) => {
    const p = player.current;
    if (!p) return;
    p.frame = playhead;
    p.play(r);
    setVideoView(key, { playing: true });
  };
  const toggle = () => (view.playing ? stop() : shuttle(1));
  const halt = () => view.playing && stop();

  // ---- edits -------------------------------------------------------------------------------
  const zoom = (factor: number, anchor = playhead) => {
    const sc = scroller.current;
    const next = clampPpf(ppf * factor);
    const before = anchor * ppf - (sc?.scrollLeft ?? 0);
    edit({ ppf: next });
    requestAnimationFrame(() => {
      if (sc) sc.scrollLeft = Math.max(0, anchor * next - before);
    });
  };
  const fit = () => {
    const w = scroller.current?.clientWidth ?? 900;
    edit({ ppf: fitPpf(w - HEAD_W, timelineDuration(doc), rate) });
    requestAnimationFrame(() => {
      if (scroller.current) scroller.current.scrollLeft = 0;
    });
  };
  /** Places [in, out) of a file at `frame` (or after the last clip): the probe first if needed. */
  function place(
    media: string,
    srcIn: number,
    srcOut: number | undefined,
    frame: number,
    targets: { video: string | null; audio: string | null },
    mode: "insert" | "overwrite" | "append",
    moveHead = false,
  ) {
    const d = doc as RgVideo;
    const info = byName[media];
    const ref = mediaRefOf(info, media, rate);
    if (!ref) {
      pendingPlace.current = {
        media,
        in: srcIn,
        ...(srcOut !== undefined && { out: srcOut }),
        frame,
        targets,
        mode,
      };
      if (!videoEditOf(key).pool.includes(media)) edit({ pool: [...videoEditOf(key).pool, media] });
      say(t("vePreparingFile", { name: fileName(media) }));
      return;
    }
    const out = srcOut ?? sourceLength(ref, rate);
    // A sound alone never goes on a video track; a picture never on an audio one.
    const sound = info?.kind === "audio";
    const tg = sound
      ? { video: null, audio: targets.audio ?? lanes(d, "Audio")[0] ?? null }
      : targets;
    const opts = { targets: tg, ids: gen(d) };
    const next =
      mode === "append"
        ? appendClip(d, ref, srcIn, out, opts)
        : placeClip(d, ref, srcIn, out, frame, { ...opts, mode });
    if (next === d) return say(t("veNothingToPlace"));
    const added = addedClips(d, next);
    commit(next, mode, added);
    if (moveHead) {
      const end = Math.max(...added.map((id) => clipEnd(clipOf(next, id) as VideoClip)));
      if (Number.isFinite(end)) seek(end);
    }
  }
  const fromSource = (mode: "insert" | "overwrite" | "append") => {
    const s = ed.source;
    if (!s) return say(t("veNoSource"));
    place(s.media, s.in, s.out, playhead, ed.targets, mode, true);
  };
  const openSource = (media: string, part?: { in: number; out: number }) => {
    const ref = mediaRefOf(byName[media], media, rate);
    const len = ref ? sourceLength(ref, rate) : sec * 5;
    const p = part ?? { in: 0, out: len };
    edit({
      sourceOpen: true,
      source: { media, in: p.in, out: p.out, at: p.in },
      ...(!ed.pool.includes(media) && !used.includes(media) && { pool: [...ed.pool, media] }),
    });
  };
  const setSource = (patch: Partial<NonNullable<VideoEditState["source"]>>) => {
    const s = videoEditOf(key).source;
    if (s) edit({ source: { ...s, ...patch } });
  };
  const toggleTrack = (tr: VideoTrack, prop: "locked" | "hidden" | "muted") =>
    commit(setTrack(doc, tr.id, { [prop]: !tr[prop] }), "track");

  const run = (cmd: VideoCommand, inSource = false) => {
    const s = ed.source;
    if (inSource && s) {
      const len = sourceLength(
        mediaRefOf(byName[s.media], s.media, rate) ?? { media: s.media },
        rate,
      );
      const go = (x: number) => setSource({ at: Math.max(0, Math.min(len, x)) });
      const el = root.current?.querySelector<HTMLVideoElement>(".ve-source video");
      switch (cmd) {
        case "play":
        case "forward":
          if (el?.paused) void el.play();
          else el?.pause();
          return;
        case "stop":
          el?.pause();
          return;
        case "reverse":
          return go(s.at - sec);
        case "prevFrame":
          return go(s.at - 1);
        case "nextFrame":
          return go(s.at + 1);
        case "prevSecond":
          return go(s.at - sec);
        case "nextSecond":
          return go(s.at + sec);
        case "home":
          return go(0);
        case "end":
          return go(len);
        default:
      }
    }
    switch (cmd) {
      case "undo":
        return host.current?.undo();
      case "redo":
        return host.current?.redo();
      case "save":
        return saveDoc(file);
      case "play":
        return toggle();
      case "reverse":
      case "forward":
        return shuttle(shuttleRate(view.playing, player.current?.rate ?? 1, cmd));
      case "stop":
        return stop();
      case "prevFrame":
        halt();
        return seek(playhead - 1);
      case "nextFrame":
        halt();
        return seek(playhead + 1);
      case "prevSecond":
        halt();
        return seek(playhead - sec);
      case "nextSecond":
        halt();
        return seek(playhead + sec);
      case "prevEdit":
        return seek(prevEdit(doc, playhead));
      case "nextEdit":
        return seek(nextEdit(doc, playhead));
      case "home":
        return seek(0);
      case "end":
        return seek(timelineDuration(doc));
      case "blade": {
        const under = sel.filter((id) => {
          const c = clipOf(doc, id);
          return c && playhead > c.start && playhead < clipEnd(c);
        });
        const next = bladeAt(doc, playhead, under.length ? under : null, { ids: gen(doc) });
        if (next === doc) return say(t("veNothingToCut"));
        return commit(next, "blade");
      }
      case "lift":
        if (selMarker) {
          setSelMarker(undefined);
          return commit(removeMarker(doc, selMarker), "marker");
        }
        if (sel.length) return commit(liftClips(doc, sel, { linked }), "lift", []);
        return;
      case "ripple":
        if (selMarker) {
          setSelMarker(undefined);
          return commit(removeMarker(doc, selMarker), "marker");
        }
        if (sel.length) return commit(rippleDeleteClips(doc, sel, { linked }), "ripple_delete", []);
        if (ed.gap) {
          const next = closeGap(doc, ed.gap.track, ed.gap.frame);
          edit({ gap: undefined });
          if (next === doc) return say(t("veNoGap"));
          return commit(next, "close_gap");
        }
        return;
      case "copy": {
        if (!sel.length) return;
        const copied = copyClips(doc, sel, { linked });
        videoClipboard.value = copied;
        return say(t("veCopied", { n: String(copied.length) }));
      }
      case "paste": {
        const copied = videoClipboard.value;
        if (!copied.length) return say(t("veNothingCopied"));
        const next = pasteClips(doc, copied, playhead, { ids: gen(doc) });
        if (next === doc) return say(t("veNothingToPlace"));
        return commit(next, "paste", addedClips(doc, next));
      }
      case "selectAll":
        return edit({ sel: doc.clips.map((c) => c.id), gap: undefined });
      case "selectAtPlayhead":
        return edit({
          sel: doc.clips
            .filter(
              (c) => playhead >= c.start && playhead < clipEnd(c) && !trackOf(doc, c.track)?.locked,
            )
            .map((c) => c.id),
        });
      case "link": {
        if (!sel.length) return;
        const any = doc.clips.some((c) => selSet.has(c.id) && c.link);
        const next = any ? unlinkClips(doc, sel) : linkClips(doc, sel, { ids: gen(doc) });
        if (next === doc) return say(t("veLinkTwo"));
        commit(next, any ? "unlink" : "link");
        return say(any ? t("veUnlinked") : t("veLinked"));
      }
      case "linkedSel":
        edit({ linkedSel: !linked });
        return say(linked ? t("veLinkedSelOff") : t("veLinkedSelOn"));
      case "escape":
        setSelMarker(undefined);
        return edit({ sel: [], gap: undefined, help: false });
      case "insert":
      case "overwrite":
      case "append":
        return fromSource(cmd);
      case "toolSelect":
        return edit({ tool: "select" });
      case "toolBlade":
        return edit({ tool: "blade" });
      case "toolTrim":
        return edit({ tool: "trim" });
      case "snap":
        edit({ snapping: !ed.snapping });
        return say(ed.snapping ? t("veSnapOff") : t("veSnapOn"));
      case "marker": {
        const next = addMarker(doc, playhead, { ids: gen(doc) });
        if (next === doc) return;
        return commit(next, "marker");
      }
      case "enable": {
        if (!sel.length) return;
        const any = doc.clips.some((c) => selSet.has(c.id) && c.enabled);
        return commit(setClipProps(doc, sel, { enabled: !any }), "props");
      }
      case "markIn":
        if (s) setSource({ in: Math.min(s.at, s.out - 1) });
        return;
      case "markOut":
        if (s) setSource({ out: Math.max(s.at, s.in + 1) });
        return;
      case "zoomIn":
        return zoom(1.5);
      case "zoomOut":
        return zoom(1 / 1.5);
      case "fit":
        return fit();
      case "help":
        return edit({ help: !ed.help });
      case "nudgeLeft":
      case "nudgeRight": {
        if (!sel.length) return;
        const d = cmd === "nudgeLeft" ? -1 : 1;
        const first = doc.clips.find((c) => selSet.has(c.id));
        const order = first ? [first.id, ...sel.filter((id) => id !== first.id)] : sel;
        return commit(moveClips(doc, order, d, 0, { linked, ids: gen(doc) }), "move");
      }
      case "trimStart":
      case "trimEnd": {
        const c = doc.clips.find(
          (x) => selSet.has(x.id) && playhead > x.start && playhead < clipEnd(x),
        );
        if (!c) return say(t("veTrimNeedsClip"));
        const ripple = ed.tool === "trim";
        const next =
          cmd === "trimStart"
            ? trimClip(doc, c.id, "in", playhead - c.start, { ripple, linked })
            : trimClip(doc, c.id, "out", playhead - clipEnd(c), { ripple, linked });
        return commit(next, ripple ? "ripple_trim" : "trim");
      }
      default:
    }
  };

  const onKey = (e: KeyboardEvent) => {
    if (e.defaultPrevented || typingIn(e.target)) return;
    const el = e.target as HTMLElement;
    // A button's own Enter and Space; the arrows of a toolbar move between its buttons.
    if ((e.key === " " || e.key === "Enter") && el.closest("button")) return;
    if (e.key.startsWith("Arrow") && el.closest("[role=toolbar]")) return;
    const cmd = videoKey(e);
    if (!cmd) return;
    e.preventDefault();
    run(cmd, !!el.closest(".ve-source"));
  };

  // ---- the mouse on the timeline -----------------------------------------------------------
  const startDrag = (d: Drag) => {
    drag.current = d;
    const move = (ev: PointerEvent) => onMove(ev);
    const up = (ev: PointerEvent) => {
      window.removeEventListener("pointermove", move);
      window.removeEventListener("pointerup", up);
      window.removeEventListener("pointercancel", up);
      onUp(ev);
    };
    window.addEventListener("pointermove", move);
    window.addEventListener("pointerup", up);
    window.addEventListener("pointercancel", up);
  };
  const onMove = (ev: PointerEvent) => {
    const d = drag.current;
    if (!d) return;
    if (d.mode === "scrub") return seek(frameAt(ev.clientX));
    if (d.mode === "move") {
      const dx = ev.clientX - d.x0;
      if (!d.moved && Math.abs(dx) < 3 && Math.abs(ev.clientY - d.y0) < 3) return;
      if (!d.moved) host.current?.presence(true);
      d.moved = true;
      let delta = Math.round(dx / ppf);
      const moving = new Set(d.linked ? withLinked(d.base, d.sel) : d.sel);
      if (ed.snapping) delta = snapBlock(d.base, moving, delta, playhead, th);
      const kind = trackOf(d.base, d.track0)?.kind ?? "Video";
      const ls = lanes(d.base, kind);
      const over = trackUnder(ev.clientX, ev.clientY);
      const laneDelta = over && ls.includes(over) ? ls.indexOf(over) - ls.indexOf(d.track0) : 0;
      const order = [d.id, ...d.sel.filter((id) => id !== d.id)];
      d.view = moveClips(d.base, order, delta, laneDelta, { linked: d.linked, ids: gen(d.base) });
      setShown(d.view);
      return;
    }
    if (d.mode === "trim") {
      const c = clipOf(d.base, d.id);
      if (!c) return;
      const at = d.edge === "in" ? c.start : clipEnd(c);
      let delta = Math.round((ev.clientX - d.x0) / ppf);
      if (!d.view) host.current?.presence(true);
      if (ed.snapping) {
        const ex = new Set(d.linked ? withLinked(d.base, [d.id]) : [d.id]);
        delta = snap(at + delta, snapPoints(d.base, ex, playhead), th) - at;
      }
      d.view = trimClip(d.base, d.id, d.edge, delta, { ripple: d.ripple, linked: d.linked });
      setShown(d.view);
      // The edge's frame shows in the viewer while trimming.
      const now = clipOf(d.view, d.id);
      if (now) player.current?.seek(d.edge === "in" ? now.start : clipEnd(now) - 1);
      return;
    }
    // The marquee: the clips it touches join the selection.
    const r = rows.current?.getBoundingClientRect();
    if (!r) return;
    const x1 = Math.min(d.x0, ev.clientX) - r.left;
    const x2 = Math.max(d.x0, ev.clientX) - r.left;
    const y1 = Math.min(d.y0, ev.clientY) - r.top;
    const y2 = Math.max(d.y0, ev.clientY) - r.top;
    setMarquee({ x: x1, y: y1, w: x2 - x1, h: y2 - y1 });
    if (x2 - x1 < 4 && y2 - y1 < 4) return;
    d.moved = true;
    const hit: string[] = [];
    for (const el of Array.from(rows.current?.querySelectorAll<HTMLElement>("[data-clip]") ?? [])) {
      const b = el.getBoundingClientRect();
      const bx1 = b.left - r.left;
      const bx2 = b.right - r.left;
      const by1 = b.top - r.top;
      const by2 = b.bottom - r.top;
      if (bx1 < x2 && bx2 > x1 && by1 < y2 && by2 > y1) hit.push(el.dataset.clip as string);
    }
    edit({ sel: [...new Set([...d.keep, ...hit])], gap: undefined });
  };
  const onUp = (_ev: PointerEvent) => {
    const d = drag.current;
    drag.current = undefined;
    if (!d) return;
    if (d.mode === "marquee") {
      setMarquee(undefined);
      if (!d.moved) seek(d.frame);
      return;
    }
    if (d.mode === "move" || d.mode === "trim") {
      const v = d.view;
      setShown(undefined);
      if (v) host.current?.presence(false);
      if (v && v !== d.base)
        commit(v, d.mode === "move" ? "move" : d.ripple ? "ripple_trim" : "trim");
      if (d.mode === "trim") player.current?.seek(playhead);
    }
  };
  const pressRuler = (e: PointerEvent) => {
    if (e.button !== 0) return;
    e.preventDefault();
    halt();
    seek(frameAt(e.clientX));
    startDrag({ mode: "scrub" });
  };
  const pressClip = (e: PointerEvent, c: VideoClip) => {
    if (e.button !== 0) return;
    e.preventDefault();
    e.stopPropagation();
    root.current?.focus({ preventScroll: true });
    setSelMarker(undefined);
    const tr = trackOf(doc, c.track);
    if (tr?.locked) {
      edit({ gap: undefined });
      return say(t("veLocked", { id: c.track }));
    }
    if (ed.tool === "blade") {
      const f = snapFrame(frameAt(e.clientX), new Set());
      const next = bladeAt(doc, f, [c.id], { ids: gen(doc) });
      if (next !== doc) commit(next, "blade");
      return;
    }
    const el = e.currentTarget as HTMLElement;
    const r = el.getBoundingClientRect();
    const edge = edgeAt(e.clientX, r.left, r.width, EDGE_PX);
    const link = linked && !e.altKey;
    const mine = link ? withLinked(doc, [c.id]) : [c.id];
    if (edge) {
      edit({ sel: mine, gap: undefined });
      startDrag({
        mode: "trim",
        id: c.id,
        edge,
        x0: e.clientX,
        base: doc,
        ripple: ed.tool === "trim",
        linked: link,
      });
      return;
    }
    if (e.shiftKey || e.ctrlKey || e.metaKey) {
      const on = selSet.has(c.id);
      edit({
        sel: on ? sel.filter((id) => !mine.includes(id)) : [...new Set([...sel, ...mine])],
        gap: undefined,
      });
      return;
    }
    const chosen = selSet.has(c.id) && !e.altKey ? sel : mine;
    edit({ sel: chosen, gap: undefined });
    startDrag({
      mode: "move",
      id: c.id,
      sel: chosen,
      x0: e.clientX,
      y0: e.clientY,
      base: doc,
      track0: c.track,
      moved: false,
      linked: link,
    });
  };
  const pressLane = (e: PointerEvent, tr: VideoTrack) => {
    if (e.button !== 0 || ed.tool === "blade") return;
    e.preventDefault();
    root.current?.focus({ preventScroll: true });
    setSelMarker(undefined);
    const f = frameAt(e.clientX);
    const keep = e.shiftKey || e.ctrlKey || e.metaKey ? sel : [];
    const gap =
      !clipAt(doc, tr.id, f) && gapAt(doc, tr.id, f) ? { track: tr.id, frame: f } : undefined;
    edit({ sel: keep, gap });
    startDrag({ mode: "marquee", x0: e.clientX, y0: e.clientY, keep, frame: f, moved: false });
  };
  const clipKey = (e: KeyboardEvent, c: VideoClip) => {
    if (e.key !== "Enter" && e.key !== " ") return;
    e.preventDefault();
    e.stopPropagation();
    const mine = linked ? withLinked(doc, [c.id]) : [c.id];
    if (e.shiftKey || e.ctrlKey || e.metaKey) {
      const on = selSet.has(c.id);
      edit({ sel: on ? sel.filter((id) => !mine.includes(id)) : [...new Set([...sel, ...mine])] });
    } else edit({ sel: mine, gap: undefined });
    announce(t("veChosen", { name: clipLabel(c) }));
  };

  // ---- dropping files in -------------------------------------------------------------------
  const dropTypes = (e: DragEvent) => Array.from(e.dataTransfer?.types ?? []);
  const accepts = (e: DragEvent) =>
    dropTypes(e).includes(MEDIA_TYPE) || dropTypes(e).includes(FILE_TYPE);
  const targetsFor = (tr: VideoTrack) => {
    if (tr.kind === "Audio") return { video: null, audio: tr.id };
    const i = lanes(doc, "Video").indexOf(tr.id);
    const audio = lanes(doc, "Audio");
    return { video: tr.id, audio: audio[i] ?? audio[0] ?? null };
  };
  const dragOverLane = (e: DragEvent, tr: VideoTrack) => {
    if (!accepts(e)) return;
    e.preventDefault();
    if (e.dataTransfer) e.dataTransfer.dropEffect = "copy";
    setDropHint({ track: tr.id, frame: snapFrame(frameAt(e.clientX), new Set()) });
  };
  const dropOnLane = (e: DragEvent, tr: VideoTrack) => {
    setDropHint(undefined);
    if (!accepts(e)) return;
    e.preventDefault();
    const frame = snapFrame(frameAt(e.clientX), new Set());
    if (tr.locked) return say(t("veLocked", { id: tr.id }));
    const raw = e.dataTransfer?.getData(MEDIA_TYPE);
    if (raw) {
      const m = JSON.parse(raw) as { media: string; in?: number; out?: number };
      return place(m.media, m.in ?? 0, m.out, frame, targetsFor(tr), "overwrite");
    }
    const f = JSON.parse(e.dataTransfer?.getData(FILE_TYPE) || "{}") as {
      scope?: string;
      path?: string;
    };
    if (!f.path || f.scope !== file.scope) return say(t("veOtherProject"));
    if (!isTimelineMedia(f.path)) return say(t("veNotMedia", { name: fileName(f.path) }));
    place(f.path, 0, undefined, frame, targetsFor(tr), "overwrite");
  };
  const addFile = async () => {
    const path = await askText(t("veAddFile"), "", { label: t("veAddFilePath") });
    if (!path?.trim()) return;
    const p = path.trim().replace(/^\/+/, "");
    if (!isTimelineMedia(p)) return say(t("veNotMedia", { name: fileName(p) }));
    openSource(p);
  };

  // ---- drawing -----------------------------------------------------------------------------
  const tl = showing as RgVideo;
  const videoTracks = tl.tracks.filter((x) => x.kind === "Video").reverse();
  const audioTracks = tl.tracks.filter((x) => x.kind === "Audio");
  const used = [...new Set(doc.clips.flatMap((c) => (isMediaRef(c.ref) ? [c.ref.media] : [])))];
  const pool = [...used, ...ed.pool.filter((m) => !used.includes(m))];
  const missing = (prepared?.media ?? []).filter((m) => m.missing).map((m) => m.media);
  const ticks = rulerTicks(ppf, rate, total + Math.round(f1 * 30));
  const one = sel.length ? clipOf(doc, sel[0] as string) : undefined;
  const exactLen = Number(view.exactLength);
  const end = timelineDuration(doc);
  const askExact = () => {
    stop();
    const to = Math.min(end, playhead + Math.round(exactLen * f1));
    setVideoView(key, { playing: false, exact: undefined });
    void getApi()
      .videoExact(
        file.scope,
        file.path,
        Math.min(playhead, Math.max(0, end - 1)),
        Math.max(playhead + 1, to),
      )
      .then(
        ({ job }) => setVideoView(key, { exactJob: job.id }),
        () => {},
      );
  };
  const px = (f: number) => `${(f * ppf).toFixed(2)}px`;
  const clipBox = (tr: VideoTrack, c: VideoClip) => {
    const info = isMediaRef(c.ref) ? byName[c.ref.media] : undefined;
    const dur = info?.probe?.duration ?? 0;
    const fileW = dur * f1 * ppf;
    const left = -c.sourceRange.start * ppf;
    const label = clipLabel(c);
    const mark = marks[c.id];
    const cls = [
      "ve-clip",
      tr.kind === "Video" ? "v" : "a",
      selSet.has(c.id) && "sel",
      !c.enabled && "disabled",
      info?.missing && "missing",
      !isMediaRef(c.ref) && "gen",
      mark && "agent",
    ]
      .filter(Boolean)
      .join(" ");
    return (
      // biome-ignore lint/a11y/useSemanticElements: a clip is drawn on the lane, chosen like a button
      <div
        key={c.id}
        data-clip={c.id}
        class={cls}
        role="button"
        tabIndex={0}
        aria-pressed={selSet.has(c.id)}
        aria-label={t("veClipLabel", {
          name: label,
          track: c.track,
          start: timecode(c.start, rate),
          length: timecode(c.sourceRange.duration, rate),
        })}
        title={`${label} · ${timecode(c.start, rate)} · ${timecode(c.sourceRange.duration, rate)}`}
        style={{
          left: px(c.start),
          width: `${Math.max(2, c.sourceRange.duration * ppf).toFixed(2)}px`,
        }}
        onPointerDown={(e) => pressClip(e as PointerEvent, c)}
        onKeyDown={(e) => clipKey(e as KeyboardEvent, c)}
        onDblClick={() =>
          isMediaRef(c.ref) &&
          openSource(c.ref.media, {
            in: c.sourceRange.start,
            out: c.sourceRange.start + c.sourceRange.duration,
          })
        }
      >
        {tr.kind === "Video" && info?.filmstrip && fileW > 0 && (
          <div
            class="ve-strip"
            style={{
              left: `${left.toFixed(2)}px`,
              width: `${fileW.toFixed(2)}px`,
              backgroundImage: `url("${info.filmstrip.url}")`,
            }}
          />
        )}
        {tr.kind === "Video" && info?.kind === "image" && info.file && (
          <div class="ve-strip still" style={{ backgroundImage: `url("${info.file}")` }} />
        )}
        {tr.kind === "Audio" && info?.waveform && fileW > 0 && (
          <div
            class="ve-wave"
            style={{
              left: `${left.toFixed(2)}px`,
              width: `${fileW.toFixed(2)}px`,
              maskImage: `url("${info.waveform.url}")`,
              WebkitMaskImage: `url("${info.waveform.url}")`,
            }}
          />
        )}
        <span class="ve-clip-name">
          {c.link && <IconLink size={10} />}
          {label}
        </span>
        {mark && <span class="ve-clip-who">{mark.who}</span>}
        <span class="ve-edge in" aria-hidden="true" />
        <span class="ve-edge out" aria-hidden="true" />
      </div>
    );
  };
  const lane = (tr: VideoTrack) => {
    const h = LANE_H[tr.kind];
    const off = tr.kind === "Video" ? tr.hidden : tr.muted;
    const target = tr.kind === "Video" ? ed.targets.video : ed.targets.audio;
    const empty = !doc.clips.some((c) => c.track === tr.id);
    const gap = ed.gap?.track === tr.id ? gapAt(tl, tr.id, ed.gap.frame) : undefined;
    return (
      <div
        key={tr.id}
        class={`ve-row ${tr.kind === "Video" ? "v" : "a"}${off ? " off" : ""}${tr.locked ? " locked" : ""}`}
        style={{ height: `${h}px` }}
      >
        <div class="ve-head">
          <button
            type="button"
            class={`ve-target${target === tr.id ? " on" : ""}`}
            aria-pressed={target === tr.id}
            title={t("veTarget", { id: tr.id })}
            onClick={() =>
              edit({
                targets: {
                  ...ed.targets,
                  [tr.kind === "Video" ? "video" : "audio"]: target === tr.id ? null : tr.id,
                },
              })
            }
          >
            {tr.id}
          </button>
          <button
            type="button"
            class="ve-track-name"
            title={t("veRenameTrack")}
            onClick={async () => {
              const name = await askText(t("veRenameTrack"), tr.name, { label: t("veTrackName") });
              if (name?.trim() && name.trim() !== tr.name)
                commit(setTrack(doc, tr.id, { name: name.trim() }), "track");
            }}
          >
            {tr.name}
          </button>
          <Tool
            label={tr.locked ? t("veUnlockTrack") : t("veLockTrack")}
            pressed={tr.locked}
            on={() => toggleTrack(tr, "locked")}
          >
            {tr.locked ? <IconLock size={13} /> : <IconUnlock size={13} />}
          </Tool>
          {tr.kind === "Video" ? (
            <Tool
              label={tr.hidden ? t("veShowTrack") : t("veHideTrack")}
              pressed={!!tr.hidden}
              on={() => toggleTrack(tr, "hidden")}
            >
              {tr.hidden ? <IconEyeOff size={13} /> : <IconEye size={13} />}
            </Tool>
          ) : (
            <Tool
              label={tr.muted ? t("veUnmuteTrack") : t("veMuteTrack")}
              pressed={!!tr.muted}
              on={() => toggleTrack(tr, "muted")}
            >
              {tr.muted ? <IconSpeakerOff size={13} /> : <IconSpeaker size={13} />}
            </Tool>
          )}
          {empty && tr.id !== "V1" && tr.id !== "A1" && (
            <Tool
              label={t("veRemoveTrack", { id: tr.id })}
              on={() => {
                const next = removeTrack(doc, tr.id);
                if (next === doc) return say(t("veRemoveOnlyEmpty"));
                const k = tr.kind === "Video" ? "video" : "audio";
                if (ed.targets[k] === tr.id)
                  edit({ targets: { ...ed.targets, [k]: tr.kind === "Video" ? "V1" : "A1" } });
                commit(next, "remove_track");
              }}
            >
              <IconTrash size={12} />
            </Tool>
          )}
        </div>
        {/* biome-ignore lint/a11y/noStaticElementInteractions: the lane takes the mouse (marquee, gaps, drops); the keys are the editor's */}
        <div
          class="ve-lane"
          data-lane={tr.id}
          style={{ width: `${width}px` }}
          onPointerDown={(e) => pressLane(e as PointerEvent, tr)}
          onDragOver={(e) => dragOverLane(e as DragEvent, tr)}
          onDragLeave={() => setDropHint(undefined)}
          onDrop={(e) => dropOnLane(e as DragEvent, tr)}
        >
          {gap && (
            <div
              class="ve-gap"
              style={{ left: px(gap[0]), width: px(gap[1] - gap[0]) }}
              title={t("veGapChosen")}
            />
          )}
          {tl.transitions
            .filter((x) => x.track === tr.id)
            .map((x) => {
              const from = clipOf(tl, x.from);
              if (!from) return null;
              const cut = clipEnd(from);
              return (
                <div
                  key={x.id}
                  class="ve-trans"
                  title={t("veTransition")}
                  style={{ left: px(cut - x.inOffset), width: px(x.inOffset + x.outOffset) }}
                />
              );
            })}
          {trackClips(tl, tr.id).map((c) => clipBox(tr, c))}
          {dropHint?.track === tr.id && (
            <div class="ve-drop" style={{ left: px(dropHint.frame) }} />
          )}
        </div>
      </div>
    );
  };

  return (
    <section
      class={`ve tool-${ed.tool}${view.playing ? " playing" : ""}`}
      ref={root}
      tabIndex={-1}
      onKeyDown={onKey}
      aria-label={t("veEditor")}
    >
      <div class={`ve-top${ed.sourceOpen && ed.source ? " two" : ""}`}>
        {ed.sourceOpen && ed.source && (
          <SourceViewer
            info={byName[ed.source.media]}
            source={ed.source}
            rate={rate}
            onSet={setSource}
            onPlace={fromSource}
            onClose={() => edit({ sourceOpen: false })}
          />
        )}
        <section class="ve-program" aria-label={t("veProgram")}>
          <div
            class="vp-screen ve-screen"
            style={{
              "--ar": `${doc.format.width} / ${doc.format.height}`,
              "--arn": String(doc.format.width / doc.format.height),
            }}
          >
            <div
              ref={stage}
              class="vp-stage"
              role="img"
              aria-label={doc.name ?? fileName(file.path)}
            />
            <div ref={audioBox} class="vp-audio" aria-hidden="true" />
            {end === 0 && <p class="vp-empty">{t("veEmpty")}</p>}
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
          <div class="vw-bar ve-transport">
            <Tool label={t("vpPrevFrame")} keys="←" on={() => run("prevFrame")}>
              <IconChevronLeft size={14} />
            </Tool>
            <Tool
              label={view.playing ? t("vpPause") : t("vpPlay")}
              keys={t("veKeySpace")}
              pressed={view.playing}
              on={toggle}
              class="ve-play"
            >
              {view.playing ? <IconPause size={14} /> : <IconPlay size={14} />}
            </Tool>
            <Tool label={t("vpNextFrame")} keys="→" on={() => run("nextFrame")}>
              <IconChevronRight size={14} />
            </Tool>
            <span class="ve-tc" aria-live="off">
              {timecode(playhead, rate)} <span class="dim">/ {timecode(end, rate)}</span>
            </span>
            <div class="spacer" />
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
          {view.exactJob && <ExactJob id={view.exactJob} view={key} from={playhead} />}
        </section>
        {one && (
          <aside class="ve-inspector" aria-label={t("veInspector")}>
            <h4>{clipLabel(one)}</h4>
            <dl>
              <dt>{t("veTrack")}</dt>
              <dd>{one.track}</dd>
              <dt>{t("veStart")}</dt>
              <dd>{timecode(one.start, rate)}</dd>
              <dt>{t("veLength")}</dt>
              <dd>{timecode(one.sourceRange.duration, rate)}</dd>
              {isMediaRef(one.ref) && !one.ref.still && (
                <>
                  <dt>{t("veSourceInOut")}</dt>
                  <dd>
                    {timecode(one.sourceRange.start, rate)} -{" "}
                    {timecode(one.sourceRange.start + one.sourceRange.duration, rate)}
                  </dd>
                </>
              )}
              <dt>{t("veState")}</dt>
              <dd>
                {one.enabled ? t("veOn") : t("veOff")}
                {one.link ? ` · ${t("veIsLinked")}` : ""}
              </dd>
            </dl>
            {sel.length > 1 && <p class="dim">{t("veSelected", { n: String(sel.length) })}</p>}
          </aside>
        )}
      </div>

      <div class="vw-bar ve-bar" role="toolbar" aria-label={t("veTools")}>
        <div class="vw-seg">
          <Tool
            label={t("veToolSelect")}
            keys="A"
            pressed={ed.tool === "select"}
            on={() => run("toolSelect")}
          >
            <IconCursor size={15} />
          </Tool>
          <Tool
            label={t("veToolBlade")}
            keys="B"
            pressed={ed.tool === "blade"}
            on={() => run("toolBlade")}
          >
            <IconBlade />
          </Tool>
          <Tool
            label={t("veToolTrim")}
            keys="T"
            pressed={ed.tool === "trim"}
            on={() => run("toolTrim")}
          >
            <IconRippleTrim />
          </Tool>
        </div>
        <div class="vw-seg">
          <Tool label={t("veSnap")} keys="N" pressed={ed.snapping} on={() => run("snap")}>
            <IconMagnet />
          </Tool>
          <Tool
            label={t("veLinkedSel")}
            keys="Ctrl+Shift+L"
            pressed={linked}
            on={() => run("linkedSel")}
          >
            <IconLink />
          </Tool>
        </div>
        <div class="vw-seg">
          <Tool label={t("veBladeHere")} keys="Ctrl+B" on={() => run("blade")}>
            <IconBlade />
          </Tool>
          <Tool label={t("veLift")} keys="Backspace" disabled={!sel.length} on={() => run("lift")}>
            <IconMinus />
          </Tool>
          <Tool
            label={t("veRipple")}
            keys="Delete"
            disabled={!sel.length && !ed.gap}
            on={() => run("ripple")}
          >
            <IconTrash size={14} />
          </Tool>
          <Tool
            label={t("veLinkClips")}
            keys="Ctrl+Alt+L"
            disabled={!sel.length}
            on={() => run("link")}
          >
            <IconLink />
          </Tool>
          <Tool label={t("veMarker")} keys="M" on={() => run("marker")}>
            <IconFlag />
          </Tool>
        </div>
        <div class="vw-seg">
          <Tool label={t("veZoomOut")} keys="-" on={() => run("zoomOut")}>
            <IconMinus />
          </Tool>
          <Tool label={t("veFit")} keys="Shift+Z" on={() => run("fit")}>
            <IconMaximize size={14} />
          </Tool>
          <Tool label={t("veZoomIn")} keys="+" on={() => run("zoomIn")}>
            <IconPlus />
          </Tool>
        </div>
        <div class="spacer" />
        <div class="vw-seg">
          <Tool label={t("veUndo")} keys="Ctrl+Z" on={() => run("undo")}>
            <IconUndo size={14} />
          </Tool>
          <Tool label={t("veRedo")} keys="Ctrl+Shift+Z" on={() => run("redo")}>
            <IconRedo size={14} />
          </Tool>
          <Tool label={t("veHelp")} keys="?" pressed={ed.help} on={() => run("help")}>
            <IconKeyboard />
          </Tool>
        </div>
      </div>

      <div
        class="ve-scroll"
        ref={scroller}
        onWheel={(e) => {
          if (!(e.ctrlKey || e.metaKey || e.altKey)) return;
          e.preventDefault();
          zoom(e.deltaY < 0 ? 1.25 : 0.8, frameAt(e.clientX));
        }}
      >
        <div class="ve-rows" ref={rows} style={{ width: `${width + HEAD_W}px` }}>
          <div class="ve-row ve-ruler-row" style={{ height: `${RULER_H}px` }}>
            <div class="ve-head ve-corner">
              <button
                type="button"
                class="link"
                onClick={() => commit(addTrack(doc, "Video"), "add_track")}
              >
                <IconPlus size={11} /> {t("veAddVideo")}
              </button>
              <button
                type="button"
                class="link"
                onClick={() => commit(addTrack(doc, "Audio"), "add_track")}
              >
                <IconPlus size={11} /> {t("veAddAudio")}
              </button>
            </div>
            <div
              class="ve-ruler"
              style={{ width: `${width}px` }}
              onPointerDown={(e) => pressRuler(e as PointerEvent)}
            >
              {ticks.map((k) => (
                <span
                  key={k.frame}
                  class={`ve-tick${k.minor ? " minor" : ""}`}
                  style={{ left: px(k.frame) }}
                >
                  {k.label}
                </span>
              ))}
              {tl.markers.map((m) => (
                <button
                  key={m.id}
                  type="button"
                  class={`ve-marker c-${m.color.toLowerCase()}${selMarker === m.id ? " sel" : ""}`}
                  style={{ left: px(m.frame) }}
                  title={m.note || t("veMarkerAt", { tc: timecode(m.frame, rate) })}
                  aria-label={
                    t("veMarkerAt", { tc: timecode(m.frame, rate) }) + (m.note ? `: ${m.note}` : "")
                  }
                  aria-pressed={selMarker === m.id}
                  onPointerDown={(e) => e.stopPropagation()}
                  onClick={(e) => {
                    if (e.altKey) {
                      const i = MARKER_COLORS.indexOf(m.color as (typeof MARKER_COLORS)[number]);
                      const color = MARKER_COLORS[(i + 1) % MARKER_COLORS.length] ?? "BLUE";
                      return commit(setMarker(doc, m.id, { color }), "marker");
                    }
                    setSelMarker(m.id);
                    edit({ sel: [], gap: undefined });
                    seek(m.frame);
                  }}
                  onDblClick={async () => {
                    const note = await askText(t("veMarkerNote"), m.note, {
                      label: t("veMarkerNote"),
                    });
                    if (note !== null && note !== m.note)
                      commit(setMarker(doc, m.id, { note }), "marker");
                  }}
                >
                  <IconFlag size={11} />
                </button>
              ))}
            </div>
          </div>
          {videoTracks.map(lane)}
          <div class="ve-split" />
          {audioTracks.map(lane)}
          <div
            class="ve-playhead"
            style={{ left: `${HEAD_W + playhead * ppf}px` }}
            aria-hidden="true"
          />
          {marquee && (
            <div
              class="ve-marquee"
              style={{
                left: `${marquee.x}px`,
                top: `${marquee.y}px`,
                width: `${marquee.w}px`,
                height: `${marquee.h}px`,
              }}
            />
          )}
        </div>
      </div>

      <section class="ve-pool" aria-label={t("vePool")}>
        <strong>{t("vePool")}</strong>
        {pool.map((m) => (
          <button
            key={m}
            type="button"
            class={`ve-pool-item${ed.source?.media === m && ed.sourceOpen ? " on" : ""}${byName[m]?.missing ? " missing" : ""}`}
            draggable
            title={t("vePoolItem", { name: m })}
            onClick={() => openSource(m)}
            onDragStart={(e) => {
              e.dataTransfer?.setData(MEDIA_TYPE, JSON.stringify({ media: m }));
              if (e.dataTransfer) e.dataTransfer.effectAllowed = "copy";
            }}
          >
            {kindIcon(byName[m], m)}
            <span>{fileName(m)}</span>
          </button>
        ))}
        <button type="button" class="vw-btn small" onClick={addFile}>
          <IconPlus size={12} />
          {t("veAddFile")}
        </button>
        <span class="dim ve-pool-hint">{t("vePoolHint")}</span>
      </section>

      {notice && (
        <p class="ve-notice" role="status">
          {notice}
        </p>
      )}
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
      {ed.help && (
        <Modal
          title={t("veHelpTitle")}
          onClose={() => edit({ help: false })}
          icon={<IconKeyboard />}
        >
          <dl class="ve-keys">
            {VIDEO_KEYS.map((k) => (
              <div key={k.keys}>
                <dt>
                  <kbd>{k.keys}</kbd>
                </dt>
                <dd>{t(k.what)}</dd>
              </div>
            ))}
          </dl>
          <p class="dim">{t("veHelpMouse")}</p>
        </Modal>
      )}
    </section>
  );
}

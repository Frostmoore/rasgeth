// The video family (G41.2): `.rgvideo` timelines with tracks, edited by the person in the page's
// timeline and by the agents with canvas_edit, through the same pure edits of the protocol
// (video-timeline.ts) and the same actions (video-patch.ts): each sets one entity by its id,
// positions are absolute, so conflicts and rebasing are on ids. The file is the timeline's JSON;
// proxies, thumbnails, strips and waveforms are derived caches, never in it.
import { extname } from "node:path";
import {
  applyVideoAction,
  checkVideoAction,
  composeVideoActions,
  type DocOp,
  type DocSummary,
  describeVideo,
  diffTimeline,
  invertVideoAction,
  mapVideoAction,
  type RgVideo,
  readRgVideo,
  VIDEO_ENGINE,
  VIDEO_ENGINE_VERSION,
  type VideoAction,
  type VideoDocOp,
  videoActionsConflict,
  writeRgVideo,
} from "@redgiant/protocol";
import type { DocFamily, Loaded } from "./family.js";
import { VIDEO_CATALOG, videoFromAgent } from "./video/agent.js";
import { videoStructure } from "./video/structure.js";

/** The biggest timeline the editor opens. */
export const MAX_RGVIDEO_BYTES = 50 * 1024 * 1024;

export interface VideoModel {
  doc: RgVideo;
}

const wrap = (op: VideoAction): VideoDocOp => ({
  family: "video",
  engine: VIDEO_ENGINE,
  engineVersion: VIDEO_ENGINE_VERSION,
  op,
});
const actionOf = (op: DocOp): VideoAction => {
  if (op.family !== "video") throw new Error("not an operation on a video timeline");
  return op.op;
};

export class VideoFamily implements DocFamily<VideoModel> {
  readonly id = "video" as const;
  readonly engine = VIDEO_ENGINE;
  readonly engineVersion = VIDEO_ENGINE_VERSION;

  accepts(path: string): boolean {
    return extname(path).toLowerCase() === ".rgvideo";
  }

  load(bytes: Uint8Array): Loaded<VideoModel> {
    if (bytes.length > MAX_RGVIDEO_BYTES)
      throw new Error(`it is over ${MAX_RGVIDEO_BYTES / 1024 / 1024} MB`);
    let text: string;
    try {
      text = new TextDecoder("utf-8", { fatal: true }).decode(bytes);
    } catch {
      throw new Error("it is not UTF-8 text (an .rgvideo file is a JSON timeline)");
    }
    return { model: { doc: readRgVideo(text) }, format: {} };
  }

  save(model: VideoModel): Uint8Array {
    return new TextEncoder().encode(writeRgVideo(model.doc));
  }

  snapshot(model: VideoModel) {
    return { family: "video" as const, doc: model.doc };
  }

  check(model: VideoModel, op: DocOp): string | undefined {
    if (op.family !== "video") return "not an operation on a video timeline";
    return checkVideoAction(model.doc, op.op);
  }

  apply(model: VideoModel, op: DocOp): VideoModel {
    return { doc: applyVideoAction(model.doc, actionOf(op)) };
  }

  invert(model: VideoModel, op: DocOp): DocOp {
    return wrap(invertVideoAction(model.doc, actionOf(op)));
  }

  compose(ops: readonly DocOp[]): DocOp {
    return wrap(composeVideoActions(ops.map(actionOf)));
  }

  conflicts(a: DocOp, b: DocOp): boolean {
    return videoActionsConflict(actionOf(a), actionOf(b));
  }

  map(a: DocOp, b: DocOp): DocOp | undefined {
    const m = mapVideoAction(actionOf(a), actionOf(b));
    return m && wrap(m);
  }

  /** While the person drags or types in the timeline the agents' edits wait. */
  touches(): boolean {
    return true;
  }

  mapPos(_op: DocOp, pos: number): number {
    return pos;
  }

  lineOf(): number {
    return 1;
  }

  placeOf(): string {
    return "the timeline";
  }

  /** A change from outside as the entities it changed (small: it can be undone, and merged). */
  diff(before: VideoModel, after: VideoModel, maxBytes: number): DocOp | undefined {
    const a = diffTimeline(before.doc, after.doc, "replace");
    if (!a) return undefined;
    return JSON.stringify(a).length * 2 <= maxBytes ? wrap(a) : undefined;
  }

  summarize(model: VideoModel, ops: readonly DocOp[], kind?: DocSummary["kind"]): DocSummary {
    const d = describeVideo(model.doc, ops.map(actionOf));
    const { added = 0, removed = 0, action } = d.change;
    const k: DocSummary["kind"] =
      action === "replace"
        ? "replace"
        : added && !removed
          ? "insert"
          : removed && !added
            ? "delete"
            : "edit";
    return {
      text: d.text,
      kind: kind ?? k,
      video: d.change,
      ...(ops.length > 1 && { count: ops.length }),
    };
  }

  wrote(): [number, number][] {
    return [];
  }

  fromAgent(model: VideoModel, ops: readonly unknown[]) {
    const r = videoFromAgent(model.doc, ops);
    if ("error" in r) return r;
    return { ops: r.actions.map(wrap) };
  }

  catalog(): string {
    return VIDEO_CATALOG;
  }

  structure(
    model: VideoModel,
    ask: { fromLine?: number | undefined; toLine?: number | undefined },
  ): string {
    return videoStructure(model.doc, ask);
  }
}

export const videoFamily = new VideoFamily();

import type {
  AssistantPart,
  ImagePart,
  MessageMetrics,
  ModelSpec,
  StopReason,
} from "@redgiant/protocol";
import type { StallLimits, StreamEvent, ToolDef } from "@redgiant/providers";

/** One of RedGiant's tools run for the engine: validated, permitted, hooked and logged as usual. */
export type RunTool = (call: {
  callId: string;
  name: string;
  input: unknown;
}) => Promise<{ content: string; isError: boolean }>;

export interface EngineTurn {
  text: string;
  images: ImagePart[];
  system: string;
  tools: ToolDef[];
  /**
   * The tools left aside (off by default or switched off, 3.9.8): an engine that can declare tools
   * only when its conversation starts (Codex) declares these too, so one switched on later is
   * callable at the next step; until then the session refuses them.
   */
  aside?: ToolDef[] | undefined;
  model: ModelSpec;
  /** The engine's own conversation id from an earlier turn: the turn continues it. */
  resume: string | undefined;
  signal?: AbortSignal | undefined;
  runTool: RunTool;
  /**
   * Tools joined the conversation during this turn (3.9.8: `request_tool`), read after each tool
   * call. An engine whose tool list is fixed for its turn (Claude Code, Codex) then ends the turn
   * once the results are delivered and returns "tools_added": the session starts the next one at
   * once, in the same engine conversation, with the whole list. Never a tool said to be on that
   * the model cannot call.
   */
  toolsAdded?: (() => boolean) | undefined;
  /** An assistant message as the engine produced it: recorded at once, before its tools run. */
  onMessage(m: {
    parts: AssistantPart[];
    metrics: MessageMetrics;
    stopReason: StopReason;
    model: string;
  }): Promise<void>;
  live?: ((e: StreamEvent) => void) | undefined;
  /**
   * Called at every message the engine sends, whatever it is (3.5.4): the session's watch for
   * an engine that stopped answering.
   */
  alive?: (() => void) | undefined;
  /**
   * A tool the engine ran itself (an external ACP agent, G38.6): recorded as it is, never run by
   * RedGiant. Its result comes later through `onExternalResult`, with the same `callId`.
   */
  onExternalTool?:
    | ((call: { callId: string; name: string; input: unknown }) => Promise<void>)
    | undefined;
  onExternalResult?:
    | ((result: { callId: string; ok: boolean; output: string }) => Promise<void>)
    | undefined;
  /** The engine summarised its own conversation (shown in the chat; RedGiant's history stays). */
  onCompaction?: ((info: { trigger: string; preTokens?: number | undefined }) => void) | undefined;
  /**
   * What the engine may make with its own tools in this conversation (2026-11-19, `image`…:
   * `sessionNative` in the protocol), fixed at its start. The rest goes through RedGiant's tools.
   */
  native?: readonly string[] | undefined;
  /** The engine started making something with its own tool (the chat says «generating…»). */
  onNativeStart?:
    | ((m: { id: string; kind: NativeKind; prompt?: string }) => Promise<void>)
    | undefined;
  /** The engine made it (or failed): RedGiant saves it in the workspace and sends it. */
  onNativeMade?: ((m: NativeMade) => Promise<void>) | undefined;
}

/** What an engine makes by itself (2026-11-19). */
export type NativeKind = "image" | "video" | "audio";

/** Our tool an engine's own making is logged as (the chat draws it the same way). */
export const NATIVE_TOOL: Record<NativeKind, string> = {
  image: "image_generation",
  video: "video_generation",
  audio: "audio_generation",
};

/**
 * The log's call id of an engine's own making. Its result has no tool call in a model message
 * (the engine kept it): `rebuildHistory` leaves these out of a history sent to another model.
 */
export const nativeCallId = (id: string) => `native_${id}`;
export const isNativeCallId = (callId: string) => callId.startsWith("native_");

/** Something the engine made with its own tool: a picture Codex drew. */
export interface NativeMade {
  /** The engine's id for it: the same as `onNativeStart`'s. */
  id: string;
  kind: NativeKind;
  /** Where the engine saved it (absolute), when it did. */
  path?: string | undefined;
  /** Its bytes in base64, when the engine gave them instead of a file. */
  data?: string | undefined;
  /** What it was asked to make, in the engine's words. */
  prompt?: string | undefined;
  /** Why it was not made, when it was not. */
  error?: string | undefined;
}

/**
 * A model that runs its own loop (a flat subscription through the vendor's agent, G21): the
 * conversation lives in the engine, the tools stay RedGiant's. The engine compacts its own
 * context; RedGiant only records what happens.
 */
export interface Engine {
  readonly id: string;
  /** How long it may stay silent (3.5.4); default `ENGINE_STALL`. */
  readonly stall?: StallLimits | undefined;
  turn(t: EngineTurn): Promise<{ resume: string; stopReason: StopReason | "tools_added" }>;
  /**
   * Whether tools switched on now can be called in the engine conversation `resume` (3.9.8);
   * absent: always (the engine takes a new list at its next turn). Codex declares its tools once,
   * when a conversation starts: one started without them can never call them.
   */
  addable?(resume: string | undefined, names: readonly string[]): boolean;
}

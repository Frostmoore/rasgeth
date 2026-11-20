// Claude on a flat subscription (G21.2), through Anthropic's own Claude Agent SDK: the official way to
// run Claude with a subscription's login (a token from `claude setup-token`). The SDK runs the model
// loop; its own tools are switched off and RedGiant's tools are offered as an in-process MCP server,
// so permissions, sandbox and the event log stay RedGiant's.
//
// This is the only file that knows the SDK. Its usage method is marked experimental: if it changes,
// only `limits` here needs fixing.
import { mkdir, readFile, rename, writeFile } from "node:fs/promises";
import { dirname } from "node:path";
import type { Engine, EngineTurn } from "@redgiant/agent";
import type { AssistantPart, MessageMetrics, ModelSpec } from "@redgiant/protocol";
import {
  anthropicModel,
  catalogModel,
  catalogModels,
  type ModelInfo,
  type Provider,
  ProviderError,
  type SubscriptionWindow,
} from "@redgiant/providers";
import { z } from "zod";
import { windowsBasics } from "./tools.js";

export const CLAUDE_SUBSCRIPTION = "claude-subscription";
const SERVER = "redgiant";
const PREFIX = `mcp__${SERVER}__`;

/** What the engine needs from the SDK; tests pass fakes, production passes the real module. */
export interface ClaudeSdk {
  query(o: { prompt: AsyncIterable<unknown>; options: Record<string, unknown> }): AsyncIterable<
    Record<string, unknown>
  > & {
    usage_EXPERIMENTAL_MAY_CHANGE_DO_NOT_RELY_ON_THIS_API_YET?(o?: {
      skipBehaviors?: boolean;
    }): Promise<unknown>;
    interrupt?(): Promise<void>;
    supportedModels?(): Promise<unknown>;
  };
  createSdkMcpServer(o: { name: string; tools: unknown[] }): unknown;
  tool(
    name: string,
    description: string,
    shape: Record<string, z.ZodType>,
    handler: (
      args: unknown,
      extra: unknown,
    ) => Promise<{
      content: { type: "text"; text: string }[];
      isError?: boolean;
    }>,
  ): unknown;
}

export interface ClaudeSubscriptionOptions {
  /** The subscription's long-lived token (`claude setup-token`). */
  token: string;
  /** Where the engine keeps its own state (sessions, settings), apart from the user's. */
  configDir: string;
  /** A directory the engine may call home (it touches no files: its tools are off). */
  cwd: string;
  sdk?: ClaudeSdk;
  /** Claude Code's program (found or downloaded, 2026-11-05); default the SDK's own. */
  executable?: string;
  now?: () => number;
  /**
   * The engine's own web search (2026-11-03) instead of RedGiant's `web_search`: Claude
   * searches with the subscription and cites its sources. Default on.
   */
  nativeWebSearch?: boolean;
  /**
   * The plan's limits read on their own when none is known or the last is old (3.9.8): an engine
   * started without a message answers the usage request (no model call). Off in tests that count
   * the engine's runs.
   */
  readPlan?: boolean;
  /** Where the last windows are kept, so a restart does not leave the header empty (3.9.8). */
  limitsFile?: string;
}

/** RedGiant's search tool, done by the engine itself when its own search is on. */
const OWN_SEARCH = "web_search";

const loadSdk = async (): Promise<ClaudeSdk> =>
  (await import("@anthropic-ai/claude-agent-sdk")) as unknown as ClaudeSdk;

/** RedGiant's JSON Schemas as the zod shapes the SDK asks for (it turns them back into JSON Schema). */
function shapeOf(schema: unknown): Record<string, z.ZodType> {
  try {
    const s = z.fromJSONSchema(schema as never) as unknown as { shape?: Record<string, z.ZodType> };
    return s.shape ?? {};
  } catch {
    return {};
  }
}

type Block = { type: string; [k: string]: unknown };

/** A message's usage as RedGiant's metrics (the window from the model's catalogue). */
function metricsOf(
  usage: Record<string, number> | undefined,
  model: string,
  started: number,
  now: number,
): MessageMetrics {
  const input = usage?.input_tokens ?? 0;
  const read = usage?.cache_read_input_tokens ?? 0;
  const write = usage?.cache_creation_input_tokens ?? 0;
  const out = usage?.output_tokens ?? 0;
  const window = anthropicModel(model)?.contextWindow ?? 200_000;
  return {
    startedAt: new Date(started).toISOString(),
    endedAt: new Date(now).toISOString(),
    inputTokens: input + read + write,
    cachedReadTokens: read,
    cacheWriteTokens: write,
    outputTokens: out,
    contextUsed: input + read + write + out,
    contextWindow: window,
    prefillMs: 0,
    decodeMs: 0,
    tokPerSec: 0,
    source: "server",
  };
}

/** One SDK turn: prompt in, assistant messages out, RedGiant's tools in between. */
export class ClaudeEngine implements Engine {
  readonly id = CLAUDE_SUBSCRIPTION;
  /** Full model ids the engine said the plan offers (`supportedModels`), newest reading. */
  offered: string[] = [];
  readonly offeredInfo = new Map<string, { displayName?: string; supportsEffort?: boolean }>();
  private askedModels = false;
  /** The plan's windows, as the turns report them (the provider shows them). */
  onLimits: ((w: SubscriptionWindow[]) => void) | undefined;
  constructor(private readonly o: ClaudeSubscriptionOptions) {}

  private env(): Record<string, string> {
    return {
      ...windowsBasics(),
      ...(process.env.PATH && { PATH: process.env.PATH }),
      ...(process.env.Path && !process.env.PATH && { PATH: process.env.Path }),
      HOME: this.o.configDir,
      USERPROFILE: this.o.configDir,
      CLAUDE_CONFIG_DIR: this.o.configDir,
      // Without a token the engine uses the login already in its folder (`claude login`).
      ...(this.o.token && { CLAUDE_CODE_OAUTH_TOKEN: this.o.token }),
      // No self-updates. (CLAUDE_CODE_DISABLE_NONESSENTIAL_TRAFFIC is left out on purpose: with
      // it the engine loads ~36k tokens of tool definitions it would otherwise defer.)
      DISABLE_AUTOUPDATER: "1",
    };
  }

  /** The common options: no own tools, no settings files, only RedGiant's server. */
  options(model: ModelSpec, extra: Record<string, unknown> = {}): Record<string, unknown> {
    return {
      model: model.model,
      ...(model.effort && { effort: model.effort }),
      // Only the engine's own web search among its tools (the rest are RedGiant's).
      tools: this.o.nativeWebSearch === false ? [] : ["WebSearch"],
      // No skills listing, no settings files: the agent is RedGiant's, not Claude Code's.
      skills: [],
      // Only RedGiant's MCP server: the account's claude.ai connectors would add tens of
      // thousands of tokens of tools to every call (they load in the background).
      strictMcpConfig: true,
      settingSources: [],
      cwd: this.o.cwd,
      env: this.env(),
      ...(this.o.executable && { pathToClaudeCodeExecutable: this.o.executable }),
      ...extra,
    };
  }

  /**
   * Once per run, the models the plan offers, as the engine itself lists them (3.5.4): asked of
   * the query already running, so it costs no model call. Aliases ("opus") count through the id
   * they resolve to; only full `claude-` ids are kept.
   */
  private learnModels(q: { supportedModels?(): Promise<unknown> }): void {
    if (this.askedModels || !q.supportedModels) return;
    this.askedModels = true;
    void Promise.race([
      q.supportedModels(),
      new Promise<undefined>((r) => setTimeout(() => r(undefined), 5000).unref?.()),
    ])
      .then((list) => {
        if (!Array.isArray(list)) return;
        const ids: string[] = [];
        for (const raw of list as {
          value?: unknown;
          resolvedModel?: unknown;
          displayName?: unknown;
          supportsEffort?: unknown;
        }[]) {
          const id = [raw.resolvedModel, raw.value].find(
            (v): v is string => typeof v === "string" && /^claude-[a-z0-9-]+$/.test(v),
          );
          if (!id || ids.includes(id)) continue;
          ids.push(id);
          this.offeredInfo.set(id, {
            ...(typeof raw.displayName === "string" && { displayName: raw.displayName }),
            ...(typeof raw.supportsEffort === "boolean" && { supportsEffort: raw.supportsEffort }),
          });
        }
        if (ids.length) this.offered = ids;
      })
      .catch(() => {});
  }

  /** The plan's full reading (5 hours, 7 days, per-model windows such as Fable), never waited for. */
  private readUsage(q: {
    usage_EXPERIMENTAL_MAY_CHANGE_DO_NOT_RELY_ON_THIS_API_YET?(o?: {
      skipBehaviors?: boolean;
    }): Promise<unknown>;
  }): void {
    const usage = q.usage_EXPERIMENTAL_MAY_CHANGE_DO_NOT_RELY_ON_THIS_API_YET?.({
      skipBehaviors: true,
    });
    if (!usage) return;
    void Promise.race([usage, new Promise((r) => setTimeout(r, 10_000).unref?.())])
      .then((u) => {
        const w = claudeWindows(u);
        if (w.length) this.onLimits?.(w);
      })
      .catch(() => {});
  }

  /**
   * The plan's windows read on their own (3.9.8): the engine started without a message (it makes
   * no model call) answers the usage request and is closed at once. Empty when the plan has no
   * readable limits (a `setup-token` token lacks the profile scope) or the engine does not answer.
   */
  async readPlan(timeoutMs = 15_000): Promise<SubscriptionWindow[]> {
    const sdk = this.o.sdk ?? (await loadSdk());
    const abort = new AbortController();
    let release = () => {};
    const gate = new Promise<void>((r) => {
      release = r;
    });
    // The engine's input: nothing, until it is closed.
    async function* idle(): AsyncIterable<unknown> {
      await gate;
    }
    try {
      const { model: _none, ...options } = this.options(
        { provider: CLAUDE_SUBSCRIPTION, model: "" },
        { abortController: abort, permissionMode: "dontAsk" },
      );
      const q = sdk.query({ prompt: idle(), options });
      const usage = q.usage_EXPERIMENTAL_MAY_CHANGE_DO_NOT_RELY_ON_THIS_API_YET?.({
        skipBehaviors: true,
      });
      if (!usage) return [];
      let timer: ReturnType<typeof setTimeout> | undefined;
      const u = await Promise.race([
        usage,
        new Promise<undefined>((r) => {
          timer = setTimeout(() => r(undefined), timeoutMs);
          timer.unref?.();
        }),
      ]).finally(() => clearTimeout(timer));
      return claudeWindows(u);
    } catch {
      return [];
    } finally {
      release();
      abort.abort();
    }
  }

  async turn(
    t: EngineTurn,
  ): Promise<{ resume: string; stopReason: "end_turn" | "aborted" | "tools_added" }> {
    const sdk = this.o.sdk ?? (await loadSdk());
    const now = this.o.now ?? Date.now;
    // The SDK's tool calls reach our handlers without their tool_use id: each call takes the
    // oldest announced id with that name (the assistant message always comes first).
    const pending = new Map<string, string[]>();
    let calls = 0;
    // Ids already given to a call: announced later, they are not handed out again.
    const used = new Set<string>();
    const native = this.o.nativeWebSearch !== false;
    const offered = native ? t.tools.filter((d) => d.name !== OWN_SEARCH) : t.tools;
    const tools = offered.map((d) =>
      sdk.tool(d.name, d.description, shapeOf(d.inputSchema), async (args, extra) => {
        // The call's own id when the engine passes it along; otherwise the oldest announced one
        // with that name; otherwise a unique one, even for two calls in the same millisecond
        // (sharing an id, the first line would never show its result).
        const own = (extra as { _meta?: Record<string, unknown> } | undefined)?._meta?.[
          "claudecode/toolUseId"
        ];
        const announced = pending.get(d.name);
        if (typeof own === "string" && announced?.includes(own))
          announced.splice(announced.indexOf(own), 1);
        const callId =
          (typeof own === "string" && own) ||
          announced?.shift() ||
          `call_${d.name}_${now()}_${++calls}`;
        used.add(callId);
        const r = await t.runTool({ callId, name: d.name, input: args });
        return {
          content: [{ type: "text", text: r.content }],
          ...(r.isError && { isError: true }),
        };
      }),
    );
    const user = {
      type: "user",
      parent_tool_use_id: null,
      message: {
        role: "user",
        content: [
          { type: "text", text: t.text },
          ...t.images.map((im) => ({
            type: "image",
            source: { type: "base64", media_type: im.mediaType, data: im.data },
          })),
        ],
      },
    };
    // The prompt ends at once: kept open, the engine switches to its interactive mode and loads
    // ~44k more tokens of context on every call.
    async function* prompt() {
      yield user;
    }
    const abort = new AbortController();
    const stop = () => abort.abort();
    t.signal?.addEventListener("abort", stop, { once: true });
    let session = t.resume ?? "";
    let started = now();
    let stopReason: "end_turn" | "aborted" | "tools_added" = "end_turn";
    // Tools joined in this turn (3.9.8): the engine's list is fixed for its run, so it stops right
    // after these results (its PostToolUse hook ends the loop before the next model call) and the
    // session starts the next turn with the whole list.
    let stoppedForTools = false;
    const afterTool = async () => {
      if (!t.toolsAdded?.()) return { continue: true };
      stoppedForTools = true;
      return { continue: false, stopReason: "Tools joined: the turn goes on with them." };
    };
    try {
      const q = sdk.query({
        prompt: prompt(),
        options: this.options(t.model, {
          systemPrompt: t.system,
          mcpServers: { [SERVER]: sdk.createSdkMcpServer({ name: SERVER, tools }) },
          allowedTools: [
            ...offered.map((d) => `${PREFIX}${d.name}`),
            ...(native ? ["WebSearch"] : []),
          ],
          // Only RedGiant's tools are allowed, and RedGiant asks its own permissions inside
          // each of them; anything else the engine would refuse without asking.
          permissionMode: "dontAsk",
          hooks: { PostToolUse: [{ hooks: [afterTool] }] },
          // Always: every piece of the answer tells the session the engine is alive (3.5.4).
          includePartialMessages: true,
          abortController: abort,
          ...(t.resume && { resume: t.resume }),
        }),
      });
      this.learnModels(q);
      let askedUsage = false;
      for await (const m of q) {
        t.alive?.();
        // The plan's windows (5 hours, 7 days, per model) once per turn, asked as soon as the engine
        // runs (3.9.8): asked at the end, the engine was already closing and never answered, so the
        // header stayed empty. No model call: the engine reads the plan's usage page.
        if (!askedUsage && m.type === "system") {
          askedUsage = true;
          this.readUsage(q);
        }
        if (typeof m.session_id === "string") session = m.session_id;
        // The engine summarised its own context (Claude Agent SDK "compact_boundary").
        if (m.type === "system" && (m as { subtype?: string }).subtype === "compact_boundary") {
          const meta = (m as { compact_metadata?: { trigger?: string; pre_tokens?: number } })
            .compact_metadata;
          t.onCompaction?.({ trigger: meta?.trigger ?? "auto", preTokens: meta?.pre_tokens });
        }
        if (m.type === "stream_event") {
          const e = m.event as {
            type?: string;
            delta?: { type?: string; text?: string; thinking?: string };
          };
          if (e.type === "content_block_delta" && e.delta?.type === "text_delta" && e.delta.text)
            t.live?.({ type: "text_delta", text: e.delta.text });
          if (
            e.type === "content_block_delta" &&
            e.delta?.type === "thinking_delta" &&
            e.delta.thinking
          )
            t.live?.({ type: "thinking_delta", text: e.delta.thinking });
          continue;
        }
        if (m.type === "assistant" && m.parent_tool_use_id === null) {
          const msg = m.message as {
            content?: Block[];
            usage?: Record<string, number>;
            model?: string;
            stop_reason?: string;
          };
          const parts: AssistantPart[] = [];
          for (const b of msg.content ?? []) {
            if (b.type === "text" && typeof b.text === "string" && b.text)
              parts.push({ type: "text", text: b.text });
            else if (b.type === "thinking" && typeof b.thinking === "string" && b.thinking)
              parts.push({ type: "thinking", text: b.thinking });
            else if (b.type === "tool_use" && typeof b.name === "string") {
              const name = b.name.startsWith(PREFIX) ? b.name.slice(PREFIX.length) : b.name;
              const callId = String(b.id);
              if (!used.has(callId)) pending.set(name, [...(pending.get(name) ?? []), callId]);
              parts.push({
                type: "tool_call",
                callId,
                name,
                input: b.input,
                rawInput: JSON.stringify(b.input ?? {}),
              });
            }
          }
          if (parts.length === 0) continue;
          await t.onMessage({
            parts,
            metrics: metricsOf(msg.usage, t.model.model, started, now()),
            stopReason: parts.some((p) => p.type === "tool_call") ? "tool_use" : "end_turn",
            model: msg.model ?? t.model.model,
          });
          started = now();
        }
        if (m.type === "rate_limit_event") {
          const w = eventWindows(m.rate_limit_info);
          if (w.length) this.onLimits?.(w);
          continue;
        }
        if (m.type === "result") {
          if (m.subtype !== "success" && !stoppedForTools) {
            const why = Array.isArray(m.errors)
              ? (m.errors as string[]).join("; ")
              : String(m.subtype);
            if (abort.signal.aborted) stopReason = "aborted";
            else throw new ProviderError(`Claude subscription: ${why}`, false);
          }
          if (m.is_error === true && typeof m.result === "string" && !stoppedForTools) {
            const text = m.result;
            throw new ProviderError(
              `Claude subscription: ${text}`,
              false,
              /401|authentication|invalid.*token|oauth|logged in|\/login/i.test(text)
                ? { status: 401 }
                : {},
            );
          }
        }
      }
    } catch (err) {
      if (abort.signal.aborted) stopReason = "aborted";
      else throw err;
    } finally {
      t.signal?.removeEventListener("abort", stop);
    }
    if (stoppedForTools && stopReason === "end_turn") stopReason = "tools_added";
    return { resume: session, stopReason };
  }
}

/** The SDK's window names as ours. */
const EVENT_WINDOWS: Record<string, [string, string]> = {
  five_hour: ["5h", "5h"],
  seven_day: ["7d", "7g"],
};

/**
 * A `rate_limit_event`'s windows (utilisation as a fraction or a percentage, reset in seconds).
 * The SDK sends one window per event (`rateLimitType`, `utilization`, `resetsAt`: 3.9.8, on Coder
 * the header stayed empty because only the older `unifiedWindows` form was read); both are read.
 */
export function eventWindows(info: unknown): SubscriptionWindow[] {
  const flat = info as
    | { rateLimitType?: string; utilization?: number; resetsAt?: number }
    | undefined;
  const named = flat?.rateLimitType ? EVENT_WINDOWS[flat.rateLimitType] : undefined;
  if (named && typeof flat?.utilization === "number") {
    const [id, label] = named;
    const pct = flat.utilization <= 1 ? flat.utilization * 100 : flat.utilization;
    return [
      {
        id,
        label,
        usedPct: Math.round(pct),
        ...(flat.resetsAt && {
          resetsAt: new Date(flat.resetsAt * (flat.resetsAt < 1e12 ? 1000 : 1)).toISOString(),
        }),
      },
    ];
  }
  const u = (
    info as
      | { unifiedWindows?: Record<string, { utilization?: number; resetsAt?: number }> }
      | undefined
  )?.unifiedWindows;
  const out: SubscriptionWindow[] = [];
  for (const [key, id, label] of [
    ["five_hour", "5h", "5h"],
    ["seven_day", "7d", "7g"],
  ] as const) {
    const w = u?.[key];
    if (typeof w?.utilization !== "number") continue;
    const pct = w.utilization <= 1 ? w.utilization * 100 : w.utilization;
    out.push({
      id,
      label,
      usedPct: Math.round(pct),
      ...(w.resetsAt && {
        resetsAt: new Date(w.resetsAt * (w.resetsAt < 1e12 ? 1000 : 1)).toISOString(),
      }),
    });
  }
  return out;
}

/** The SDK's usage answer as windows (5 hours, 7 days, and per-model ones like Fable). */
export function claudeWindows(r: unknown): SubscriptionWindow[] {
  const rl = (r as { rate_limits?: Record<string, unknown> | null } | undefined)?.rate_limits ?? {};
  type W = { utilization?: number | null; resets_at?: string | null; display_name?: string };
  const out: SubscriptionWindow[] = [];
  const add = (id: string, label: string, w: W | null | undefined) => {
    if (typeof w?.utilization === "number")
      out.push({
        id,
        label,
        usedPct: Math.round(w.utilization),
        ...(w.resets_at && { resetsAt: w.resets_at }),
      });
  };
  add("5h", "5h", rl.five_hour as W | undefined);
  add("7d", "7g", rl.seven_day as W | undefined);
  for (const m of (rl.model_scoped as W[] | null | undefined) ?? [])
    if (m.display_name) add(`model:${m.display_name}`, m.display_name, m);
  return out;
}

/** A reading older than this is read again when someone looks (3.9.8). */
const STALE_MS = 10 * 60_000;
/** After a reading that gave nothing, the next try waits this long. */
const RETRY_MS = 2 * 60_000;
/** How long the first look waits for a reading on its own. */
const FIRST_WAIT_MS = 2500;

/**
 * The provider RedGiant sees: models to pick, their windows, the engine, the plan's limits.
 * It has no `stream`: sessions on it always go through the engine.
 */
export class ClaudeSubscriptionProvider implements Provider {
  readonly id = CLAUDE_SUBSCRIPTION;
  readonly engine: ClaudeEngine;
  private readonly now: () => number;
  /** When the windows were last reported (a turn or a reading); 0: never. */
  private at = 0;
  /** When a reading on its own was last tried, and the one running. */
  private tried = 0;
  private reading: Promise<void> | undefined;
  private readonly loaded: Promise<void>;

  constructor(private readonly o: ClaudeSubscriptionOptions) {
    this.now = o.now ?? Date.now;
    this.engine = new ClaudeEngine(o);
    this.engine.onLimits = (w) => this.merge(w);
    this.loaded = this.load();
  }

  /** The windows the last run of the server knew (3.9.8): shown until a newer report. */
  private async load(): Promise<void> {
    if (!this.o.limitsFile) return;
    try {
      const kept = JSON.parse(await readFile(this.o.limitsFile, "utf8")) as {
        at?: number;
        windows?: SubscriptionWindow[];
      };
      if (!Array.isArray(kept.windows) || this.windows.length) return;
      this.windows = kept.windows.filter(
        (w) => typeof w?.id === "string" && typeof w.label === "string",
      );
      this.at = typeof kept.at === "number" ? kept.at : 0;
    } catch {
      // Nothing kept yet.
    }
  }

  private async save(): Promise<void> {
    const file = this.o.limitsFile;
    if (!file) return;
    try {
      await mkdir(dirname(file), { recursive: true });
      const tmp = `${file}.tmp`;
      await writeFile(tmp, JSON.stringify({ at: this.at, windows: this.windows }));
      await rename(tmp, file);
    } catch {
      // Only a convenience for the next start.
    }
  }

  /**
   * The models to offer (3.5.4): the catalog's current generation, and the models the engine
   * itself says the plan has (`supportedModels`, read during a turn, no extra call) that the
   * catalog does not know yet ("data to be confirmed"). Without a turn yet, the catalog's.
   */
  async models(): Promise<string[]> {
    const current = catalogModels("anthropic")
      .filter(([, m]) => m.status === "current")
      .map(([id]) => id);
    const extra = this.engine.offered.filter(
      (id) => !catalogModel("anthropic", id) && !current.includes(id),
    );
    return [...current, ...extra];
  }

  modelInfo(model: string): ModelInfo {
    const e = anthropicModel(model);
    const seen = this.engine.offeredInfo.get(model);
    return {
      id: model,
      contextWindow: e?.contextWindow ?? 200_000,
      maxOutputTokens: e?.maxOutputTokens ?? 64_000,
      supportsEffort: e?.supportsEffort ?? seen?.supportsEffort ?? true,
      ...((e?.name ?? seen?.displayName) && { name: e?.name ?? seen?.displayName }),
      ...(!e && { unconfirmed: true }),
      ...(e?.isNew && { isNew: true }),
    };
  }

  // biome-ignore lint/correctness/useYield: a session on a subscription never streams here.
  async *stream(): AsyncIterable<never> {
    throw new ProviderError(
      "A Claude subscription runs through its engine, not as a stream",
      false,
    );
  }

  private windows: SubscriptionWindow[] = [];

  /**
   * The plan's limits: what the turns report (their rate-limit events and the usage reading), and,
   * with `readPlan`, a reading on its own when none is known or the last is older than
   * {@link STALE_MS} (3.9.8: after a restart the header stayed empty until God's next turn). The
   * answer never waits long for it: the first one waits at most {@link FIRST_WAIT_MS}, the others
   * get the windows known and the next look gets the new ones. A window past its reset shows 0%.
   */
  async limits(): Promise<SubscriptionWindow[]> {
    await this.loaded;
    const now = this.now();
    if (
      this.o.readPlan &&
      !this.reading &&
      now - this.at > STALE_MS &&
      now - this.tried > (this.windows.length ? STALE_MS : RETRY_MS)
    ) {
      this.tried = now;
      this.reading = this.engine
        .readPlan()
        .then((w) => {
          if (w.length) this.merge(w);
        })
        .finally(() => {
          this.reading = undefined;
        });
    }
    if (!this.windows.length && this.reading) {
      let timer: ReturnType<typeof setTimeout> | undefined;
      await Promise.race([
        this.reading,
        new Promise<void>((r) => {
          timer = setTimeout(r, FIRST_WAIT_MS);
          timer.unref?.();
        }),
      ]).finally(() => clearTimeout(timer));
    }
    return this.windows.map((w) => {
      if (!w.resetsAt || Date.parse(w.resetsAt) > now) return w;
      const { resetsAt: _past, ...rest } = w;
      return { ...rest, usedPct: 0 };
    });
  }

  private merge(fresh: SubscriptionWindow[]): void {
    const byId = new Map(this.windows.map((w) => [w.id, w]));
    for (const w of fresh) byId.set(w.id, w);
    const order = (id: string) => (id === "5h" ? 0 : id === "7d" ? 1 : 2);
    this.windows = [...byId.values()].sort((a, b) => order(a.id) - order(b.id));
    this.at = this.now();
    void this.save();
  }
}

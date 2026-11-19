// ChatGPT on a flat subscription (G21.3), through OpenAI's own Codex app server (`codex app-server`,
// JSON-RPC over stdio): the official way to use a ChatGPT plan from a program, with the device-code
// login meant for machines without a browser. Codex runs the model loop; its own shell and editing
// are switched off (read-only sandbox, no shell tools) and RedGiant's tools are offered as Codex's
// "dynamic tools", so permissions, sandbox and log stay RedGiant's.
//
// This is the only file that knows the protocol. Dynamic tools are an experimental part of it: if
// they change, only this file needs fixing.
import { type ChildProcessWithoutNullStreams, spawn } from "node:child_process";
import { mkdir } from "node:fs/promises";
import { createRequire } from "node:module";
import { delimiter, join } from "node:path";
import { createInterface } from "node:readline";
import type { Engine, EngineTurn } from "@redgiant/agent";
import type { AssistantPart, MessageMetrics } from "@redgiant/protocol";
import { PRODUCT_NAME } from "@redgiant/protocol";
import {
  type ModelInfo,
  type Provider,
  ProviderError,
  type SubscriptionWindow,
} from "@redgiant/providers";
import { windowsBasics } from "./tools.js";

export const CHATGPT_SUBSCRIPTION = "chatgpt-subscription";

export interface ChatgptSubscriptionOptions {
  /** Where Codex keeps its login and threads (CODEX_HOME), apart from the user's. */
  home: string;
  /** A directory Codex may call its workspace (it touches no files: read-only sandbox). */
  cwd: string;
  /** The program to run; default the bundled `codex app-server`. Tests pass a fake. */
  command?: { file: string; args: string[] };
  /** Folders first on the program's PATH (the downloaded build's ripgrep, 2026-11-05). */
  pathPrefix?: string[];
  now?: () => number;
  /** Codex's own live web search (2026-11-03) instead of RedGiant's `web_search`. Default on. */
  nativeWebSearch?: boolean;
}

type Json = Record<string, unknown>;
type Pending = { ok: (v: unknown) => void; ko: (e: Error) => void };

/** One `codex app-server` process and its JSON-RPC line protocol. */
class CodexConnection {
  private proc: ChildProcessWithoutNullStreams | undefined;
  private ready: Promise<void> | undefined;
  private next = 1;
  private readonly pending = new Map<number | string, Pending>();
  readonly listeners = new Set<(method: string, params: Json) => void>();
  /** Requests from Codex to us (dynamic tool calls); the answer goes back as the result. */
  onRequest: ((method: string, params: Json) => Promise<unknown>) | undefined;

  constructor(private readonly o: ChatgptSubscriptionOptions) {}

  private command() {
    if (this.o.command) return this.o.command;
    const bin = createRequire(import.meta.url).resolve("@openai/codex/bin/codex.js");
    return { file: process.execPath, args: [bin, "app-server"] };
  }

  start(): Promise<void> {
    this.ready ??= (async () => {
      await mkdir(this.o.home, { recursive: true });
      await mkdir(this.o.cwd, { recursive: true });
      const { file, args } = this.command();
      const proc = spawn(file, args, {
        env: {
          ...windowsBasics(),
          PATH: [...(this.o.pathPrefix ?? []), process.env.PATH ?? process.env.Path ?? ""]
            .filter(Boolean)
            .join(delimiter),
          HOME: this.o.home,
          USERPROFILE: this.o.home,
          CODEX_HOME: this.o.home,
        },
        cwd: this.o.cwd,
        stdio: ["pipe", "pipe", "pipe"],
      });
      this.proc = proc;
      proc.stderr.resume();
      proc.on("exit", () => {
        this.proc = undefined;
        this.ready = undefined;
        for (const p of this.pending.values()) p.ko(new ProviderError("Codex stopped", true));
        this.pending.clear();
      });
      createInterface({ input: proc.stdout }).on("line", (line) => this.receive(line));
      await this.request("initialize", {
        clientInfo: { name: "redgiant", title: PRODUCT_NAME, version: "2" },
        capabilities: { experimentalApi: true, requestAttestation: false },
      });
      this.notify("initialized", {});
    })();
    return this.ready;
  }

  private send(m: Json) {
    this.proc?.stdin.write(`${JSON.stringify(m)}\n`);
  }

  private receive(line: string) {
    let m: Json;
    try {
      m = JSON.parse(line) as Json;
    } catch {
      return;
    }
    const id = m.id as number | string | undefined;
    if (id !== undefined && typeof m.method === "string") {
      // A request from Codex.
      const method = m.method;
      void (
        this.onRequest?.(method, (m.params ?? {}) as Json) ?? Promise.reject(new Error("unhandled"))
      )
        .then((result) => this.send({ id, result }))
        .catch((err: Error) => this.send({ id, error: { code: -32000, message: err.message } }));
      return;
    }
    if (id !== undefined) {
      const p = this.pending.get(id);
      this.pending.delete(id);
      if (!p) return;
      const error = m.error as { message?: string; code?: number } | undefined;
      if (error) p.ko(new ProviderError(`Codex: ${error.message ?? "error"}`, false));
      else p.ok(m.result);
      return;
    }
    if (typeof m.method === "string")
      for (const l of this.listeners) l(m.method, (m.params ?? {}) as Json);
  }

  request<T = Json>(method: string, params: unknown): Promise<T> {
    const id = this.next++;
    return new Promise<T>((ok, ko) => {
      this.pending.set(id, { ok: ok as (v: unknown) => void, ko });
      this.send({ id, method, params });
    });
  }

  notify(method: string, params: unknown) {
    this.send({ method, params });
  }

  stop() {
    this.proc?.kill();
  }
}

/** Codex's rate-limit snapshot as windows: the primary is the 5-hour one, the secondary the week. */
export function codexWindows(snapshot: unknown): SubscriptionWindow[] {
  const s = snapshot as {
    primary?: {
      usedPercent?: number;
      windowDurationMins?: number | null;
      resetsAt?: number | null;
    } | null;
    secondary?: {
      usedPercent?: number;
      windowDurationMins?: number | null;
      resetsAt?: number | null;
    } | null;
  } | null;
  const out: SubscriptionWindow[] = [];
  for (const [w, fallback] of [
    [s?.primary, "5h"],
    [s?.secondary, "7d"],
  ] as const) {
    if (typeof w?.usedPercent !== "number") continue;
    const mins = w.windowDurationMins ?? (fallback === "5h" ? 300 : 10_080);
    const id = mins <= 600 ? "5h" : "7d";
    const label = mins < 1440 ? `${Math.round(mins / 60)}h` : `${Math.round(mins / 1440)}g`;
    out.push({
      id,
      label,
      usedPct: Math.round(w.usedPercent),
      ...(w.resetsAt && {
        resetsAt: new Date(w.resetsAt * (w.resetsAt < 1e12 ? 1000 : 1)).toISOString(),
      }),
    });
  }
  return out;
}

/** A finished `imageGeneration` item as what the engine made: its saved file, or its bytes. */
export function codexImage(id: string, item: Json, prompt: string | undefined) {
  const failure = item.failure as { type?: string } | null | undefined;
  const failed = failure || item.status === "failed";
  const path = typeof item.savedPath === "string" && item.savedPath ? item.savedPath : undefined;
  const data = !path && typeof item.result === "string" && item.result ? item.result : undefined;
  return {
    id,
    kind: "image" as const,
    ...(prompt && { prompt }),
    ...(failed
      ? {
          error:
            failure?.type === "usageLimitExceeded"
              ? "the plan's image limit is reached"
              : "Codex could not make it",
        }
      : path
        ? { path }
        : data
          ? { data: data.replace(/^data:[^,]*,/, "") }
          : { error: "Codex gave no file" }),
  };
}

/** The window assumed for a model before Codex has said its own (its first usage report). */
const CODEX_WINDOW = 272_000;
/** How long a tool call waits for its model request's usage before it is recorded without it. */
const USAGE_WAIT_MS = 5_000;
/** A message as the engine says it: metrics and model are added when it is recorded. */
type Said = { parts: AssistantPart[]; stopReason: "end_turn" | "tool_use" };

/** One turn on Codex: a thread per RedGiant session, RedGiant's tools as dynamic tools. */
export class CodexEngine implements Engine {
  readonly id = CHATGPT_SUBSCRIPTION;
  onLimits: ((w: SubscriptionWindow[]) => void) | undefined;
  private readonly loaded = new Set<string>();
  /** The turn waiting for each thread's dynamic tool calls, and how it records a message. */
  private readonly turns = new Map<string, { t: EngineTurn; say: (m: Said) => Promise<void> }>();
  /** Each model's context window as Codex last said it (the catalogue knows none of them). */
  private readonly windows = new Map<string, number>();

  constructor(
    private readonly conn: CodexConnection,
    private readonly o: ChatgptSubscriptionOptions,
  ) {
    conn.onRequest = async (method, params) => {
      if (method === "item/tool/requestUserInput") return this.userInput(params);
      if (method !== "item/tool/call") throw new Error(`Not supported: ${method}`);
      const running = this.turns.get(String(params.threadId));
      if (!running)
        return {
          success: false,
          contentItems: [{ type: "inputText", text: "No turn is running." }],
        };
      const callId = String(params.callId);
      const name = String(params.tool);
      const { t, say } = running;
      // The call is announced in the log before it runs, like any model's tool call, with its
      // model request's usage (which Codex reports right after the call: `say` waits for it).
      await say({
        parts: [
          {
            type: "tool_call",
            callId,
            name,
            input: params.arguments,
            rawInput: JSON.stringify(params.arguments ?? {}),
          },
        ],
        stopReason: "tool_use",
      });
      const r = await t.runTool({ callId, name, input: params.arguments });
      return { success: !r.isError, contentItems: [{ type: "inputText", text: r.content }] };
    };
  }

  /**
   * Codex asks the person and waits (`item/tool/requestUserInput`): Rasgeth's card, then the
   * answers back by question id. Codex's own question tools are switched off (`thread/start`),
   * so this comes only if a later Codex offers them anyway.
   */
  private async userInput(
    params: Json,
  ): Promise<{ answers: Record<string, { answers: string[] }> }> {
    const questions = Array.isArray(params.questions) ? (params.questions as Json[]) : [];
    const say = (text: string) => ({ answers: codexAnswers(text, questions) });
    const running = this.turns.get(String(params.threadId));
    if (!running) return say("No turn is running.");
    // Keys never travel in an answer (G36.20): they go in the keychain, from Settings.
    if (questions.some((q) => q.isSecret === true))
      return say(
        `Secrets are never asked in a question: ask the person to add it in ${PRODUCT_NAME}'s Settings (the keychain).`,
      );
    const r = await this.ask(running, String(params.itemId ?? params.callId ?? ""), questions);
    return say(r?.content ?? NOBODY_TO_ASK);
  }

  private readonly usage = new Map<string, { last: Json; window: number | null; at: number }>();
  /** A model's context window as Codex said it, once it has (none before the first usage). */
  windowOf(model: string): number | undefined {
    return this.windows.get(model);
  }

  private metrics(threadId: string, model: string): MessageMetrics {
    const u = this.usage.get(threadId);
    const last = (u?.last ?? {}) as Record<string, number>;
    const at = new Date((this.o.now ?? Date.now)()).toISOString();
    const input = last.inputTokens ?? 0;
    return {
      startedAt: at,
      endedAt: at,
      inputTokens: input,
      cachedReadTokens: last.cachedInputTokens ?? 0,
      cacheWriteTokens: last.cacheWriteInputTokens ?? 0,
      outputTokens: last.outputTokens ?? 0,
      contextUsed: last.totalTokens ?? input + (last.outputTokens ?? 0),
      contextWindow: u?.window ?? this.windows.get(model) ?? CODEX_WINDOW,
      prefillMs: 0,
      decodeMs: 0,
      tokPerSec: 0,
      source: "server",
    };
  }

  async turn(t: EngineTurn): Promise<{ resume: string; stopReason: "end_turn" | "aborted" }> {
    await this.conn.start();
    const native = this.o.nativeWebSearch !== false;
    // Codex's own image tool (2026-11-19) only when the conversation lets it (`sessionNative`):
    // otherwise pictures go through Rasgeth's image_generation.
    const drawsItself = t.native?.includes("image") === true;
    // With Codex's own search, RedGiant's is not offered too (one way to search).
    const tools = t.tools
      .filter((d) => !native || d.name !== "web_search")
      .map((d) => ({
        type: "function",
        name: d.name,
        description: d.description,
        inputSchema: d.inputSchema,
      }));
    const threadParams = {
      model: t.model.model,
      cwd: this.o.cwd,
      approvalPolicy: "never",
      sandbox: "read-only",
      baseInstructions: t.system,
      dynamicTools: tools,
      // Codex's own shell off (commands run through RedGiant's tools); its web search live.
      config: {
        "features.shell_tool": false,
        "features.unified_exec": false,
        "features.image_generation": drawsItself,
        // Codex's own questions off (3.9.5): its async one did not wait for the person. The agent
        // asks with Rasgeth's ask_user, which shows the card and waits.
        "tools.experimental_request_user_input.enabled": false,
        web_search: native ? "live" : "disabled",
      },
    };
    let threadId = t.resume;
    if (threadId && !this.loaded.has(threadId)) {
      await this.conn.request("thread/resume", { threadId, ...threadParams });
      this.loaded.add(threadId);
    }
    if (!threadId) {
      const r = await this.conn.request<{ thread: { id: string } }>("thread/start", threadParams);
      threadId = r.thread.id;
      this.loaded.add(threadId);
    }
    const id = threadId;
    // Codex reports a model request's usage (`thread/tokenUsage/updated`) only after that
    // request's items and tool calls: its messages wait for it, so each one carries its own
    // request's numbers. Read at once, the first turn had none (all zeros) and every later message
    // the request before. They are recorded in order; a tool call waits at most `USAGE_WAIT_MS`.
    let held: { m: Said; recorded: () => void; failed: (e: unknown) => void }[] = [];
    let recording: Promise<void> = Promise.resolve();
    const record = () => {
      const out = held;
      held = [];
      if (out.length === 0) return;
      const metrics = this.metrics(id, t.model.model);
      for (const h of out)
        recording = recording.then(() =>
          t
            .onMessage({ ...h.m, metrics, model: t.model.model })
            .then(h.recorded, (e: unknown) => h.failed(e)),
        );
    };
    const say = (m: Said, wait?: number) =>
      new Promise<void>((recorded, failed) => {
        const h = { m, recorded, failed };
        held.push(h);
        if (wait !== undefined)
          setTimeout(() => {
            if (held.includes(h)) record();
          }, wait).unref?.();
      });
    this.turns.set(id, { t, say: (m) => say(m, USAGE_WAIT_MS) });
    let turnId: string | undefined;
    let gaveUp: () => void = () => {};
    /** One Codex turn; "asked": we stopped it at a question that does not wait (see below). */
    const run = (input: Json[]) => {
      turnId = undefined;
      let asked: { callId: string; questions: Json[] } | undefined;
      const stopAt = () => {
        if (turnId)
          void this.conn.request("turn/interrupt", { threadId: id, turnId }).catch(() => {});
      };
      const done = new Promise<"end_turn" | "aborted" | "asked">((ok, ko) => {
        const listen = (method: string, p: Json) => {
          if (p.threadId !== undefined && p.threadId !== id) return;
          t.alive?.();
          if (method === "thread/tokenUsage/updated") {
            const u = p.tokenUsage as { last: Json; modelContextWindow: number | null };
            this.usage.set(id, { last: u.last, window: u.modelContextWindow, at: Date.now() });
            if (u.modelContextWindow) this.windows.set(t.model.model, u.modelContextWindow);
            record();
          } else if (method === "thread/compacted") {
            // Codex summarised its own context.
            t.onCompaction?.({ trigger: "auto" });
          } else if (
            (method === "item/started" || method === "item/completed") &&
            (p.item as Json | undefined)?.type === "imageGeneration"
          ) {
            // A picture Codex draws itself: RedGiant shows «generating», then saves and sends it.
            const item = p.item as Json;
            const id = String(item.id ?? "");
            const prompt = typeof item.revisedPrompt === "string" ? item.revisedPrompt : undefined;
            const started = method === "item/started";
            // What was said before it goes first (with the numbers known so far): the picture can
            // take a minute and the request's usage comes only after it.
            if (started) record();
            recording = recording
              .then(() =>
                started
                  ? t.onNativeStart?.({ id, kind: "image", ...(prompt && { prompt }) })
                  : t.onNativeMade?.(codexImage(id, item, prompt)),
              )
              .catch(() => {});
          } else if (method === "item/agentMessage/delta") {
            t.live?.({ type: "text_delta", text: String(p.delta ?? "") });
          } else if (method === "item/completed") {
            const item = p.item as Json;
            const parts: AssistantPart[] = [];
            if (item.type === "contextCompaction") t.onCompaction?.({ trigger: "auto" });
            const questions = Array.isArray(item.questions) ? (item.questions as Json[]) : [];
            if (item.type === "agentMessage" && questions.length && !asked) {
              // A question Codex asks without waiting (`request_user_input_async`, 3.9.5: on 3.9.3
              // it showed as a bulleted text and Codex went on by itself 9 s later). Its own
              // questions are switched off; should one come anyway, the turn stops here and the
              // person gets Rasgeth's question card; their answer starts the next Codex turn.
              asked = { callId: String(item.id ?? ""), questions };
              record();
              stopAt();
            } else if (item.type === "reasoning") {
              const text = [
                ...((item.summary as string[]) ?? []),
                ...((item.content as string[]) ?? []),
              ].join("\n");
              if (text) parts.push({ type: "thinking", text });
            } else if (
              item.type === "agentMessage" &&
              !asked &&
              typeof item.text === "string" &&
              item.text
            ) {
              parts.push({ type: "text", text: item.text });
            }
            if (parts.length) say({ parts, stopReason: "end_turn" }).catch(() => {});
          } else if (method === "account/rateLimits/updated") {
            const w = codexWindows(p.rateLimits);
            if (w.length) this.onLimits?.(w);
          } else if (method === "turn/completed") {
            this.conn.listeners.delete(listen);
            // A request that ended without its usage (failed, interrupted): what is held goes now.
            record();
            const turn = p.turn as { status?: string; error?: { message?: string } | null };
            if (asked && !t.signal?.aborted) ok("asked");
            else if (turn.status === "interrupted") ok("aborted");
            else if (turn.status === "failed") {
              const msg = turn.error?.message ?? "the turn failed";
              ko(
                new ProviderError(
                  `ChatGPT subscription: ${msg}`,
                  false,
                  /401|unauthori[sz]ed|log ?in|token/i.test(msg) ? { status: 401 } : {},
                ),
              );
            } else ok("end_turn");
          }
        };
        this.conn.listeners.add(listen);
        // Cancelled and Codex does not confirm (3.5.4: it may be the one stuck): its process is
        // stopped, the turn ends as aborted, and the next one starts a fresh Codex.
        gaveUp = () => {
          this.conn.listeners.delete(listen);
          record();
          this.loaded.clear();
          this.conn.stop();
          ok("aborted");
        };
      });
      return {
        done,
        asked: () => asked,
        started: () => {
          if (asked) stopAt();
        },
      };
    };
    let giveUp: ReturnType<typeof setTimeout> | undefined;
    const interrupt = () => {
      if (turnId)
        void this.conn.request("turn/interrupt", { threadId: id, turnId }).catch(() => {});
      giveUp ??= setTimeout(() => gaveUp(), 10_000);
      giveUp.unref?.();
    };
    t.signal?.addEventListener("abort", interrupt, { once: true });
    try {
      let input: Json[] = [
        { type: "text", text: t.text, text_elements: [] },
        ...t.images.map((im) => ({
          type: "image",
          url: `data:${im.mediaType};base64,${im.data}`,
        })),
      ];
      for (;;) {
        const turn = run(input);
        const r = await this.conn.request<{ turn: { id: string } }>("turn/start", {
          threadId: id,
          model: t.model.model,
          ...(t.model.effort && { effort: t.model.effort === "max" ? "xhigh" : t.model.effort }),
          input,
        });
        turnId = r.turn.id;
        turn.started();
        if (t.signal?.aborted) interrupt();
        const stopReason = await turn.done;
        await recording;
        const asked = turn.asked();
        if (stopReason !== "asked" || !asked)
          return { resume: id, stopReason: stopReason === "asked" ? "end_turn" : stopReason };
        // The person answers on the card (or the question's rules decide); Codex goes on with it.
        // Codex's turn is over: no usage will come for it, the call is recorded at once.
        const r2 = await this.ask(
          {
            t,
            say: (m) => {
              const said = say(m);
              record();
              return said;
            },
          },
          asked.callId,
          asked.questions,
        );
        await recording;
        if (t.signal?.aborted) return { resume: id, stopReason: "aborted" };
        input = [
          {
            type: "text",
            text: r2?.content ?? NOBODY_TO_ASK,
            text_elements: [],
          },
        ];
      }
    } finally {
      clearTimeout(giveUp);
      t.signal?.removeEventListener("abort", interrupt);
      this.turns.delete(id);
    }
  }

  /**
   * A question from Codex through Rasgeth's `ask_user` (3.9.5): announced in the log like any tool
   * call and run as one, so the person gets the same card on every channel and the turn waits
   * for them under the questions' own rules (no answer is never an answer). Undefined: this agent
   * has no ask_user (it does not talk with the person).
   */
  private async ask(
    running: { t: EngineTurn; say: (m: Said) => Promise<void> },
    callId: string,
    questions: Json[],
  ): Promise<{ content: string; isError: boolean } | undefined> {
    const { t, say } = running;
    if (!t.tools.some((d) => d.name === ASK_TOOL)) return undefined;
    const input = askInput(questions);
    await say({
      parts: [
        { type: "tool_call", callId, name: ASK_TOOL, input, rawInput: JSON.stringify(input) },
      ],
      stopReason: "tool_use",
    });
    return t.runTool({ callId, name: ASK_TOOL, input });
  }
}

/** Rasgeth's question tool: the one way an agent asks the person (its card, every channel). */
const ASK_TOOL = "ask_user";
const NOBODY_TO_ASK =
  "No person can answer questions here: choose yourself, and say plainly which choice you made.";

/**
 * Codex's questions (`request_user_input`: question, header, options with label and description;
 * the async one: title, options as strings) as ask_user's input.
 */
export function askInput(questions: Json[]): {
  questions: {
    question: string;
    header?: string;
    options: { label: string; description?: string }[];
  }[];
} {
  return {
    questions: questions.map((q) => {
      const header = typeof q.header === "string" ? q.header.trim().slice(0, 40) : "";
      const options = (Array.isArray(q.options) ? (q.options as unknown[]) : []).map((o) => {
        if (typeof o === "string") return { label: o };
        const { label, description } = o as Json;
        return {
          label: String(label ?? ""),
          ...(typeof description === "string" && description && { description }),
        };
      });
      return {
        question: String(q.question ?? q.title ?? ""),
        ...(header && { header }),
        options,
      };
    }),
  };
}

/**
 * ask_user's answer as Codex's `request_user_input` response: each question's chosen labels (or
 * the person's own words). An answer that is not the person's (nobody answered, their classifier,
 * an error) goes whole to the first question, for the model to read.
 */
export function codexAnswers(
  content: string,
  questions: Json[],
): Record<string, { answers: string[] }> {
  const asked = askInput(questions).questions.map((q) => q.question);
  const at = asked.map((q) => content.indexOf(`${q}\n-> `));
  const plain =
    at[0] === 0 && at.every((i) => i >= 0) && at.every((i, n) => n === 0 || i > (at[n - 1] ?? 0));
  const out: Record<string, { answers: string[] }> = {};
  questions.forEach((q, n) => {
    const key = String(q.id ?? n);
    if (!plain) {
      out[key] = { answers: n === 0 ? [content] : [] };
      return;
    }
    const from = (at[n] ?? 0) + (asked[n]?.length ?? 0) + 4;
    const to = n + 1 < at.length ? (at[n + 1] ?? content.length) - 2 : content.length;
    const text = content.slice(from, to);
    out[key] = { answers: text ? text.split("; ") : [] };
  });
  return out;
}

/**
 * The provider RedGiant sees: models, the engine, the plan's limits and the login. Sessions on it
 * always go through the engine.
 */
export class ChatgptSubscriptionProvider implements Provider {
  readonly id = CHATGPT_SUBSCRIPTION;
  readonly engine: CodexEngine;
  private readonly conn: CodexConnection;
  private windows: SubscriptionWindow[] = [];
  private modelCache: string[] | undefined;

  /** Where Codex saves the pictures it draws itself (2026-11-19): Rasgeth takes them from here. */
  readonly nativeFolder: string;

  constructor(o: ChatgptSubscriptionOptions) {
    this.nativeFolder = join(o.home, "generated_images");
    this.conn = new CodexConnection(o);
    this.engine = new CodexEngine(this.conn, o);
    this.engine.onLimits = (w) => {
      this.windows = w;
    };
  }

  async models(): Promise<string[]> {
    if (this.modelCache) return this.modelCache;
    await this.conn.start();
    const r = await this.conn.request<{
      data?: { id?: string; model?: string; hidden?: boolean }[];
    }>("model/list", {});
    this.modelCache = (r.data ?? [])
      .filter((m) => !m.hidden)
      .map((m) => m.model ?? m.id ?? "")
      .filter(Boolean);
    return this.modelCache;
  }

  modelInfo(model: string): ModelInfo {
    return {
      id: model,
      contextWindow: this.engine.windowOf(model) ?? CODEX_WINDOW,
      maxOutputTokens: 128_000,
      supportsEffort: true,
    };
  }

  // biome-ignore lint/correctness/useYield: a session on a subscription never streams here.
  async *stream(): AsyncIterable<never> {
    throw new ProviderError(
      "A ChatGPT subscription runs through its engine, not as a stream",
      false,
    );
  }

  /** The plan's windows: the last update from the turns, or a fresh reading. */
  async limits(): Promise<SubscriptionWindow[]> {
    if (this.windows.length) return this.windows;
    try {
      await this.conn.start();
      const r = await this.conn.request<{ rateLimits?: unknown }>("account/rateLimits/read", {});
      this.windows = codexWindows(r.rateLimits);
    } catch {
      // Not logged in yet, or Codex unavailable: no bars.
    }
    return this.windows;
  }

  /** Who is logged in (null: nobody). */
  async account(): Promise<{ email: string | null; plan: string | null } | null> {
    await this.conn.start();
    const r = await this.conn.request<{
      account?: { type?: string; email?: string; planType?: string } | null;
    }>("account/read", { refreshToken: false });
    const a = r.account;
    return a && a.type === "chatgpt" ? { email: a.email ?? null, plan: a.planType ?? null } : null;
  }

  /**
   * Starts the device-code login: the human opens the address and types the code; `done` settles
   * when ChatGPT confirms (or refuses).
   */
  async login(): Promise<{ url: string; code: string; done: Promise<boolean> }> {
    await this.conn.start();
    const r = await this.conn.request<{
      type: string;
      verificationUrl: string;
      userCode: string;
      loginId: string;
    }>("account/login/start", { type: "chatgptDeviceCode" });
    const done = new Promise<boolean>((ok) => {
      const listen = (method: string, p: Json) => {
        if (method !== "account/login/completed" || (p.loginId && p.loginId !== r.loginId)) return;
        this.conn.listeners.delete(listen);
        ok(p.success === true);
      };
      this.conn.listeners.add(listen);
    });
    return { url: r.verificationUrl, code: r.userCode, done };
  }

  async logout(): Promise<void> {
    await this.conn.start();
    await this.conn.request("account/logout", undefined);
    this.windows = [];
  }

  stop(): void {
    this.conn.stop();
  }
}

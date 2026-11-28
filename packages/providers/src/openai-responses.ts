import { forProvider } from "./deferred.js";
import { MetricsClock } from "./metrics.js";
import { OpenAICompatProvider, parseArgs } from "./openai-compat.js";
import { sseData } from "./sse.js";
import {
  type AssistantPart,
  type ChatMessage,
  type CompletionRequest,
  ProviderError,
  type StopReason,
  type StreamEvent,
  type Usage,
} from "./types.js";

/** One item of a Responses API `output` array (kept as received so it can be replayed). */
interface OutputItem {
  type: string;
  [key: string]: unknown;
}

interface ResponsesEvent {
  type: string;
  delta?: string;
  item?: OutputItem;
  response?: {
    model?: string;
    status?: string;
    incomplete_details?: { reason?: string } | null;
    error?: { message?: string; code?: string } | null;
    output?: OutputItem[];
    usage?: {
      input_tokens?: number;
      output_tokens?: number;
      input_tokens_details?: { cached_tokens?: number };
      output_tokens_details?: { reasoning_tokens?: number };
    } | null;
  };
  message?: string;
  code?: string;
}

/**
 * OpenAI's Responses API (`POST /responses`). Chat Completions refuses function tools together
 * with reasoning effort on newer models; this endpoint takes both. Model discovery and the key
 * check are those of {@link OpenAICompatProvider}.
 */
export class OpenAIResponsesProvider extends OpenAICompatProvider {
  /** Builds the request body. Exposed for tests. */
  override buildBody(full: CompletionRequest): Record<string, unknown> {
    const request = forProvider({}, full.model, full);
    const effort = request.effort;
    const input: unknown[] = [];
    for (const m of request.messages) input.push(...this.toInput(m, request.model));
    return {
      model: request.model,
      ...(request.system && { instructions: request.system }),
      input,
      ...(request.tools.length > 0 && {
        tools: request.tools.map((t) => ({
          type: "function",
          name: t.name,
          description: t.description,
          parameters: t.inputSchema,
          strict: false,
        })),
      }),
      ...(request.tools.length > 0 && request.toolChoice === "none" && { tool_choice: "none" }),
      ...(request.maxTokens !== undefined && { max_output_tokens: request.maxTokens }),
      ...(effort !== undefined &&
        (this.options.effortStyle ?? "none") !== "none" && {
          reasoning: { effort: effort === "max" ? "high" : effort, summary: "auto" },
        }),
      include: ["reasoning.encrypted_content"],
      store: false,
      ...(this.options.sendCacheKey && request.cacheKey && { prompt_cache_key: request.cacheKey }),
      ...this.options.extraBody?.(request),
      stream: true,
    };
  }

  private toInput(m: ChatMessage, model: string): unknown[] {
    if (m.role === "user") {
      const out: unknown[] = [];
      const content: unknown[] = [];
      for (const p of m.parts) {
        if (p.type === "tool_result") {
          out.push({
            type: "function_call_output",
            call_id: p.callId,
            output: p.isError ? `ERROR: ${p.content}` : p.content,
          });
        } else if (p.type === "image") {
          content.push({ type: "input_image", image_url: `data:${p.mediaType};base64,${p.data}` });
        } else {
          content.push({ type: "input_text", text: p.text });
        }
      }
      // Tool outputs first (they answer the previous turn's calls), then what the person said.
      if (content.length > 0) out.push({ type: "message", role: "user", content });
      return out;
    }
    // Replay the output items as received, reasoning included (cache discipline), without their ids: with
    // `store: false` OpenAI keeps nothing, and an item sent back with its id is looked up and refused («Item with id
    // … not found»). The reasoning travels in `encrypted_content`, the calls keep their `call_id`.
    if (
      m.native?.provider === this.id &&
      m.native.model === model &&
      Array.isArray(m.native.content)
    )
      return (m.native.content as OutputItem[]).map(({ id: _id, ...item }) => item);
    const out: unknown[] = [];
    for (const p of m.parts) {
      if (p.type === "text")
        out.push({
          type: "message",
          role: "assistant",
          content: [{ type: "output_text", text: p.text }],
        });
      else if (p.type === "tool_call")
        out.push({ type: "function_call", call_id: p.callId, name: p.name, arguments: p.rawInput });
    }
    return out;
  }

  override async *stream(
    request: CompletionRequest,
    signal?: AbortSignal,
  ): AsyncIterable<StreamEvent> {
    const info = this.modelInfo(request.model);
    const clock = new MetricsClock();
    let text = "";
    let thinking = "";
    const items: OutputItem[] = [];
    let completed: ResponsesEvent["response"];
    let servedModel = request.model;
    const pendingCalls: Extract<StreamEvent, { type: "tool_call" }>[] = [];

    try {
      const response = await this.fetchImpl(
        `${this.options.baseURL.replace(/\/$/, "")}/responses`,
        {
          method: "POST",
          headers: {
            "content-type": "application/json",
            accept: "text/event-stream",
            ...(this.options.apiKey && { authorization: `Bearer ${this.options.apiKey}` }),
            ...this.options.headers,
          },
          body: JSON.stringify(this.buildBody(request)),
          ...(signal && { signal }),
        },
      );
      if (!response.ok || !response.body) {
        const detail = await response.text().catch(() => "");
        const retriable =
          response.status === 408 || response.status === 429 || response.status >= 500;
        throw new ProviderError(
          `${this.id}: HTTP ${response.status} ${detail.slice(0, 500)}`,
          retriable,
          { status: response.status },
        );
      }

      for await (const data of sseData(response.body)) {
        if (data.trim() === "[DONE]") break;
        yield { type: "alive" };
        const ev = JSON.parse(data) as ResponsesEvent;
        switch (ev.type) {
          case "response.output_text.delta":
            if (ev.delta) {
              clock.token();
              text += ev.delta;
              yield { type: "text_delta", text: ev.delta };
            }
            break;
          case "response.reasoning_summary_text.delta":
            if (ev.delta) {
              clock.token();
              thinking += ev.delta;
              yield { type: "thinking_delta", text: ev.delta };
            }
            break;
          case "response.function_call_arguments.delta":
            clock.token();
            break;
          case "response.output_item.done":
            if (ev.item) {
              items.push(ev.item);
              if (ev.item.type === "function_call") {
                const raw = typeof ev.item.arguments === "string" ? ev.item.arguments : "";
                pendingCalls.push({
                  type: "tool_call",
                  callId: String(ev.item.call_id ?? ev.item.id ?? `call_${pendingCalls.length}`),
                  name: String(ev.item.name ?? ""),
                  input: parseArgs(raw),
                  rawInput: raw,
                });
              }
            }
            break;
          case "response.completed":
          case "response.incomplete":
            completed = ev.response;
            if (ev.response?.model) servedModel = ev.response.model;
            break;
          case "response.failed":
            throw new ProviderError(
              `${this.id}: ${ev.response?.error?.message ?? "response failed"}`,
              false,
            );
          case "error":
            throw new ProviderError(`${this.id}: ${ev.message ?? "stream error"}`, false);
        }
      }
    } catch (err) {
      if (signal?.aborted) {
        const usage: Usage = {
          inputTokens: 0,
          cachedReadTokens: 0,
          cacheWriteTokens: 0,
          outputTokens: 0,
        };
        yield {
          type: "done",
          completion: {
            message: { role: "assistant", parts: text ? [{ type: "text", text }] : [] },
            stopReason: "aborted",
            usage,
            metrics: clock.finish(usage, info.contextWindow),
            model: request.model,
            provider: this.id,
          },
        };
        return;
      }
      if (err instanceof ProviderError) throw err;
      throw new ProviderError(`${this.id}: ${String(err)}`, true, { cause: err });
    }

    const parts: AssistantPart[] = [];
    if (thinking) parts.push({ type: "thinking", text: thinking });
    if (text) parts.push({ type: "text", text });
    for (const call of pendingCalls) {
      parts.push({ ...call, type: "tool_call" });
      yield { ...call };
    }

    const u = completed?.usage;
    const usage: Usage = {
      inputTokens: u?.input_tokens ?? 0,
      cachedReadTokens: u?.input_tokens_details?.cached_tokens ?? 0,
      cacheWriteTokens: 0,
      outputTokens: u?.output_tokens ?? 0,
    };
    const refused = items.some(
      (i) =>
        i.type === "message" &&
        Array.isArray(i.content) &&
        i.content.some((c: { type?: string }) => c?.type === "refusal"),
    );
    const stopReason: StopReason =
      pendingCalls.length > 0
        ? "tool_use"
        : completed?.status === "incomplete" &&
            completed.incomplete_details?.reason === "max_output_tokens"
          ? "max_tokens"
          : refused || completed?.incomplete_details?.reason === "content_filter"
            ? "refusal"
            : "end_turn";
    yield {
      type: "done",
      completion: {
        message: {
          role: "assistant",
          parts,
          native: { provider: this.id, model: request.model, content: items },
        },
        stopReason,
        usage,
        metrics: clock.finish(usage, info.contextWindow),
        model: servedModel,
        provider: this.id,
      },
    };
  }
}

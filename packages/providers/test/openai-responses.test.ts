import { describe, expect, it } from "vitest";
import {
  type ChatMessage,
  type CompletionRequest,
  complete,
  OpenAIResponsesProvider,
  ProviderError,
} from "../src/index.js";
import { fakeFetch, sseResponse } from "./helpers.js";

const run = (p: OpenAIResponsesProvider, r: CompletionRequest) => complete(p.stream(r));
const user = (text: string): ChatMessage => ({ role: "user", parts: [{ type: "text", text }] });
const tools = [{ name: "read_file", description: "d", inputSchema: { type: "object" } }];

const usage = {
  input_tokens: 120,
  input_tokens_details: { cached_tokens: 100 },
  output_tokens: 30,
  output_tokens_details: { reasoning_tokens: 12 },
};

function provider(events: Parameters<typeof sseResponse>[0]) {
  const f = fakeFetch(() => sseResponse(events));
  const p = new OpenAIResponsesProvider({
    id: "openai",
    baseURL: "https://api.openai.test/v1/",
    apiKey: "sk-test",
    effortStyle: "reasoning_effort",
    sendCacheKey: true,
    fetch: f.fetch,
  });
  return { p, f };
}

const textItem = {
  type: "message",
  id: "msg_1",
  role: "assistant",
  status: "completed",
  content: [{ type: "output_text", text: "Hello there", annotations: [] }],
};

describe("OpenAIResponsesProvider", () => {
  it("streams a text answer with cached tokens in the usage", async () => {
    const { p, f } = provider([
      { event: "response.created", data: { type: "response.created", response: {} } },
      {
        data: { type: "response.output_text.delta", delta: "Hello " },
      },
      { data: { type: "response.output_text.delta", delta: "there" } },
      { data: { type: "response.output_item.done", item: textItem } },
      {
        data: {
          type: "response.completed",
          response: { status: "completed", model: "gpt-6.2-astra-2026", usage },
        },
      },
    ]);
    const c = await run(p, {
      model: "gpt-6.2-astra",
      system: "S",
      tools: [],
      messages: [user("hi")],
    });
    expect(f.calls[0]?.url).toBe("https://api.openai.test/v1/responses");
    expect(c.message.parts).toEqual([{ type: "text", text: "Hello there" }]);
    expect(c.stopReason).toBe("end_turn");
    expect(c.usage).toMatchObject({ inputTokens: 120, cachedReadTokens: 100, outputTokens: 30 });
    expect(c.model).toBe("gpt-6.2-astra-2026");
    expect(c.message.native).toEqual({
      provider: "openai",
      model: "gpt-6.2-astra",
      content: [textItem],
    });
  });

  it("reports a tool call and stops with tool_use", async () => {
    const call = {
      type: "function_call",
      id: "fc_1",
      call_id: "call_1",
      name: "read_file",
      arguments: '{"path":"a.ts"}',
    };
    const { p } = provider([
      { data: { type: "response.output_item.added", item: { ...call, arguments: "" } } },
      { data: { type: "response.function_call_arguments.delta", delta: '{"path"' } },
      { data: { type: "response.function_call_arguments.delta", delta: ':"a.ts"}' } },
      { data: { type: "response.output_item.done", item: call } },
      { data: { type: "response.completed", response: { status: "completed", usage } } },
    ]);
    const c = await run(p, { model: "m", system: "", tools, messages: [user("go")] });
    expect(c.stopReason).toBe("tool_use");
    expect(c.message.parts).toContainEqual({
      type: "tool_call",
      callId: "call_1",
      name: "read_file",
      input: { path: "a.ts" },
      rawInput: '{"path":"a.ts"}',
    });
  });

  it("keeps reasoning and replays the stored output items next turn, without their ids (store: false)", async () => {
    const reasoning = {
      type: "reasoning",
      id: "rs_1",
      summary: [{ type: "summary_text", text: "Thinking it over" }],
      encrypted_content: "gAAAA-opaque",
    };
    const call = {
      type: "function_call",
      id: "fc_1",
      call_id: "call_1",
      name: "read_file",
      arguments: "{}",
    };
    const { p, f } = provider([
      { data: { type: "response.reasoning_summary_text.delta", delta: "Thinking " } },
      { data: { type: "response.reasoning_summary_text.delta", delta: "it over" } },
      { data: { type: "response.output_item.done", item: reasoning } },
      { data: { type: "response.output_item.done", item: call } },
      { data: { type: "response.completed", response: { status: "completed", usage } } },
    ]);
    const first = await run(p, { model: "m", system: "S", tools, messages: [user("go")] });
    expect(first.message.parts[0]).toEqual({ type: "thinking", text: "Thinking it over" });
    await run(p, {
      model: "m",
      system: "S",
      tools,
      messages: [
        user("go"),
        first.message,
        { role: "user", parts: [{ type: "tool_result", callId: "call_1", content: "file" }] },
      ],
    });
    expect(f.calls.length).toBe(2);
    expect(f.calls[1]?.body.input).toEqual([
      { type: "message", role: "user", content: [{ type: "input_text", text: "go" }] },
      {
        type: "reasoning",
        summary: [{ type: "summary_text", text: "Thinking it over" }],
        encrypted_content: "gAAAA-opaque",
      },
      { type: "function_call", call_id: "call_1", name: "read_file", arguments: "{}" },
      { type: "function_call_output", call_id: "call_1", output: "file" },
    ]);
  });

  it("rebuilds an assistant turn from parts when there is no native content", () => {
    const { p } = provider([]);
    const body = p.buildBody({
      model: "m",
      system: "S",
      tools,
      messages: [
        user("go"),
        {
          role: "assistant",
          parts: [
            { type: "thinking", text: "hmm" },
            { type: "text", text: "calling" },
            { type: "tool_call", callId: "c1", name: "read_file", input: {}, rawInput: "{}" },
          ],
        },
        {
          role: "user",
          parts: [
            { type: "tool_result", callId: "c1", content: "bad", isError: true },
            { type: "image", mediaType: "image/png", data: "QUJD" },
          ],
        },
      ],
    });
    expect(body.input).toEqual([
      { type: "message", role: "user", content: [{ type: "input_text", text: "go" }] },
      { type: "message", role: "assistant", content: [{ type: "output_text", text: "calling" }] },
      { type: "function_call", call_id: "c1", name: "read_file", arguments: "{}" },
      { type: "function_call_output", call_id: "c1", output: "ERROR: bad" },
      {
        type: "message",
        role: "user",
        content: [{ type: "input_image", image_url: "data:image/png;base64,QUJD" }],
      },
    ]);
  });

  it("builds the body: instructions, tools, effort, encrypted reasoning, no storage", () => {
    const { p } = provider([]);
    const body = p.buildBody({
      model: "gpt-6.2-astra",
      system: "S",
      tools,
      messages: [user("hi")],
      effort: "max",
      maxTokens: 777,
      cacheKey: "conv-1",
    });
    expect(body).toMatchObject({
      model: "gpt-6.2-astra",
      instructions: "S",
      tools: [
        {
          type: "function",
          name: "read_file",
          description: "d",
          parameters: { type: "object" },
          strict: false,
        },
      ],
      reasoning: { effort: "high", summary: "auto" },
      include: ["reasoning.encrypted_content"],
      store: false,
      max_output_tokens: 777,
      prompt_cache_key: "conv-1",
      stream: true,
    });
    const low = p.buildBody({
      model: "m",
      system: "S",
      tools: [],
      messages: [user("x")],
      effort: "low",
    });
    expect(low.reasoning).toEqual({ effort: "low", summary: "auto" });
    const none = p.buildBody({ model: "m", system: "S", tools: [], messages: [user("x")] });
    expect(none.reasoning).toBeUndefined();
  });

  it("maps incomplete responses to max_tokens", async () => {
    const { p } = provider([
      { data: { type: "response.output_text.delta", delta: "cut" } },
      {
        data: {
          type: "response.incomplete",
          response: { status: "incomplete", incomplete_details: { reason: "max_output_tokens" } },
        },
      },
    ]);
    const c = await run(p, { model: "m", system: "", tools: [], messages: [user("x")] });
    expect(c.stopReason).toBe("max_tokens");
  });

  it("turns response.failed into a ProviderError", async () => {
    const { p } = provider([
      {
        data: {
          type: "response.failed",
          response: { error: { message: "server_error happened" } },
        },
      },
    ]);
    await expect(
      run(p, { model: "m", system: "", tools: [], messages: [user("x")] }),
    ).rejects.toThrow(/server_error happened/);
  });

  it("turns an HTTP 400 into a non-retriable ProviderError", async () => {
    const f = fakeFetch(() => new Response('{"error":{"message":"bad request"}}', { status: 400 }));
    const p = new OpenAIResponsesProvider({ id: "openai", baseURL: "http://x/v1", fetch: f.fetch });
    await expect(
      run(p, { model: "m", system: "", tools: [], messages: [user("x")] }),
    ).rejects.toMatchObject({
      name: "ProviderError",
      retriable: false,
      message: expect.stringContaining("HTTP 400"),
    });
    expect(ProviderError).toBeDefined();
  });
});

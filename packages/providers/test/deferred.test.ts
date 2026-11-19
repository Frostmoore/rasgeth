// Deferred tools (3.9.4): a session declares the tools it started without as deferred and a result
// that switches some on names them. Anthropic keeps them out of the cached prefix (`defer_loading`,
// `tool_reference` in the result, the breakpoint on the last loaded tool); every other provider
// gets only what the model may call, those named at the end in the order they were named.
import { describe, expect, it } from "vitest";
import {
  AnthropicProvider,
  type ChatMessage,
  type CompletionRequest,
  forProvider,
  loadedTools,
  namedTools,
  OpenAICompatProvider,
  type ToolDef,
} from "../src/index.js";

const def = (name: string, deferred = false): ToolDef => ({
  name,
  description: `${name} does it`,
  inputSchema: { type: "object", properties: {} },
  ...(deferred && { deferred: true }),
});
const tools = [
  def("bash"),
  def("read_file"),
  def("blender", true),
  def("image_generation", true),
  def("mail_send", true),
];
const ask: ChatMessage = { role: "user", parts: [{ type: "text", text: "draw" }] };
const call: ChatMessage = {
  role: "assistant",
  parts: [{ type: "tool_call", callId: "c1", name: "request_tool", input: {}, rawInput: "{}" }],
};
const result = (refs: string[]): ChatMessage => ({
  role: "user",
  parts: [{ type: "tool_result", callId: "c1", content: "images is on", refs }],
});

describe("loading deferred tools", () => {
  it("names the tools the results switched on, in order", () => {
    const msgs = [
      ask,
      call,
      result(["image_generation"]),
      call,
      result(["blender", "image_generation"]),
    ];
    expect(namedTools(msgs)).toEqual(["image_generation", "blender"]);
    expect(loadedTools(tools, msgs).map((t) => t.name)).toEqual([
      "bash",
      "read_file",
      "image_generation",
      "blender",
    ]);
    expect(loadedTools(tools, msgs).some((t) => "deferred" in t)).toBe(false);
  });

  it("keeps the request for a provider that loads on demand, trims it for the others", () => {
    const req = { tools, messages: [ask] };
    expect(forProvider({ deferredTools: () => true }, "m", req)).toBe(req);
    expect(forProvider({}, "m", req).tools.map((t) => t.name)).toEqual(["bash", "read_file"]);
    const oa = new OpenAICompatProvider({ id: "local", baseUrl: "http://x/v1" });
    const body = oa.buildBody({
      model: "m",
      system: "",
      tools,
      messages: [ask, call, result(["blender"])],
    });
    expect((body.tools as { function: { name: string } }[]).map((t) => t.function.name)).toEqual([
      "bash",
      "read_file",
      "blender",
    ]);
  });
});

describe("Anthropic's deferred loading", () => {
  const p = new AnthropicProvider({ apiKey: "t" });
  const base: CompletionRequest = { model: "claude-opus-5-5", system: "s", tools, messages: [ask] };

  it("says which models have it", () => {
    for (const m of [
      "claude-opus-5-5",
      "claude-sonnet-4-5-20250929",
      "claude-haiku-4-5-20251001",
      "claude-fable-5",
      "claude-opus-4-8",
    ])
      expect(p.deferredTools(m), m).toBe(true);
    for (const m of [
      "claude-opus-4-1-20250805",
      "claude-sonnet-4-20250514",
      "claude-3-7-sonnet-latest",
      "gpt-x",
    ])
      expect(p.deferredTools(m), m).toBe(false);
  });

  it("sends deferred tools with defer_loading and the breakpoint on the last loaded one", () => {
    const sent = p.buildParams(base).tools as unknown as Record<string, unknown>[];
    expect(sent.map((t) => [t.name, t.defer_loading ?? false, "cache_control" in t])).toEqual([
      ["bash", false, false],
      ["read_file", false, true],
      ["blender", true, false],
      ["image_generation", true, false],
      ["mail_send", true, false],
    ]);
  });

  it("surfaces switched-on tools by reference: the tool list does not move", () => {
    const later = p.buildParams({ ...base, messages: [ask, call, result(["image_generation"])] });
    expect(later.tools).toEqual(p.buildParams(base).tools);
    expect(later.system).toEqual(p.buildParams(base).system);
    expect(later.messages[2]?.content).toEqual([
      {
        type: "tool_result",
        tool_use_id: "c1",
        content: [
          { type: "text", text: "images is on" },
          { type: "tool_reference", tool_name: "image_generation" },
        ],
      },
    ]);
  });

  it("loads them in the list for a model without deferred loading", () => {
    const old = p.buildParams({
      ...base,
      model: "claude-opus-4-1-20250805",
      messages: [ask, call, result(["image_generation"])],
    });
    const sent = old.tools as unknown as Record<string, unknown>[];
    expect(sent.map((t) => t.name)).toEqual(["bash", "read_file", "image_generation"]);
    expect(sent.some((t) => t.defer_loading)).toBe(false);
    expect("cache_control" in (sent[2] ?? {})).toBe(true);
  });
});

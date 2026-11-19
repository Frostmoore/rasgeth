// Deferred tools (3.9.4, decision «Strumenti spenti di serie, accesi a gruppi quando servono"): a
// session declares the tools it started without as deferred, and a tool result that switches some
// on names them (`refs`). A provider with deferred loading (Anthropic's `defer_loading` and
// `tool_reference`) keeps them out of its cached prefix; every other provider gets only the tools
// the model may call: the loaded ones, then those a result named, in the order they were named. The
// prefix of such a provider changes once per switch, like a compaction.
import type { ChatMessage } from "@redgiant/protocol";
import type { CompletionRequest, Provider, ToolDef } from "./types.js";

/** The deferred tools the history names, in the order of the results that name them. */
export function namedTools(messages: readonly ChatMessage[]): string[] {
  const out: string[] = [];
  for (const m of messages)
    if (m.role === "user")
      for (const p of m.parts)
        if (p.type === "tool_result")
          for (const n of p.refs ?? []) if (!out.includes(n)) out.push(n);
  return out;
}

/** A tool list without deferred tools: those the history named join at the end, loaded. */
export function loadedTools(
  tools: readonly ToolDef[],
  messages: readonly ChatMessage[],
): ToolDef[] {
  if (!tools.some((t) => t.deferred)) return [...tools];
  const loaded = tools.filter((t) => !t.deferred);
  const byName = new Map(tools.filter((t) => t.deferred).map((t) => [t.name, t]));
  for (const n of namedTools(messages)) {
    const t = byName.get(n);
    if (!t) continue;
    const { deferred: _, ...def } = t;
    loaded.push(def);
  }
  return loaded;
}

/** The request as `provider` takes it for `model`: unchanged when it loads tools on demand. */
export function forProvider<R extends Pick<CompletionRequest, "tools" | "messages">>(
  provider: Pick<Provider, "deferredTools">,
  model: string,
  request: R,
): R {
  if (!request.tools.some((t) => t.deferred)) return request;
  if (provider.deferredTools?.(model) === true) return request;
  return { ...request, tools: loadedTools(request.tools, request.messages) };
}

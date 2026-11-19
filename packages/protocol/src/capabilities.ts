/**
 * What a model can do by itself (2026-11-19, «generazione nativa del modello prima del nostro
 * strumento»): for pictures, videos, sounds and web search, either the model's own engine does it
 * ("native": Codex on a ChatGPT plan draws pictures with its own image tool), or Rasgeth's tool
 * does it with the provider the person chose ("ours"), or nobody can ("none").
 *
 * One table, by provider (an engine works the same for every model it runs), and pure functions
 * over it, tested as a table: change the table first. The way is chosen when a conversation starts
 * and stays for its whole life (the prompt prefix stays the same); our tool always stays in the
 * set, so the person can still ask for it by name.
 */

/** The things a model may do by itself. */
export const CAPABILITIES = ["image", "video", "audio", "web_search"] as const;
export type Capability = (typeof CAPABILITIES)[number];

/** How a capability is done in a conversation. */
export type CapabilityWay = "native" | "ours" | "none";

/** The generation capabilities the person's setting covers («use the model's tool when it has one»). */
export const GENERATION_CAPABILITIES: readonly Capability[] = ["image", "video", "audio"];

/** Rasgeth's own tool for each capability. */
export const OUR_TOOL: Record<Capability, string> = {
  image: "image_generation",
  video: "video_generation",
  audio: "audio_generation",
  web_search: "web_search",
};

/**
 * What each provider's engine does by itself. Absent: nothing. Codex (`codex app-server`) has an
 * image tool (`features.image_generation`, items `imageGeneration` with the file it saved under
 * `$CODEX_HOME/generated_images/`) and a live web search; Claude Code and Anthropic's API search the
 * web themselves. None of them makes videos or sounds.
 */
export const NATIVE_CAPABILITIES: Readonly<Record<string, readonly Capability[]>> = {
  "chatgpt-subscription": ["image", "web_search"],
  "claude-subscription": ["web_search"],
  anthropic: ["web_search"],
};

/** The folder of the agent's workspace where a capability's files are saved. */
export const CAPABILITY_FOLDER: Partial<Record<Capability, string>> = {
  image: "images",
  video: "videos",
  audio: "audio",
};

/** Whether a provider's engine does a capability by itself. */
export function hasNative(provider: string, capability: Capability): boolean {
  return NATIVE_CAPABILITIES[provider]?.includes(capability) ?? false;
}

/**
 * The way a capability is done for one conversation: native when the engine can and the person
 * lets it (`preferNative`, on by default; web search is always the engine's when it has one, as
 * before), ours when our tool is in the set, none otherwise.
 */
export function capabilityWay(
  provider: string,
  capability: Capability,
  o: { preferNative: boolean; ours: boolean },
): CapabilityWay {
  const generation = GENERATION_CAPABILITIES.includes(capability);
  if (hasNative(provider, capability) && (o.preferNative || !generation)) return "native";
  return o.ours ? "ours" : "none";
}

/**
 * The generation capabilities done natively in one conversation. A new conversation: what the
 * provider can and the person allows now. A resumed one: what its start recorded (`recorded`),
 * kept only where the current provider can still do it (the person may have changed the model
 * since); an old conversation without the record is decided now.
 */
export function sessionNative(
  provider: string,
  preferNative: boolean,
  recorded?: readonly string[],
): Capability[] {
  const able = GENERATION_CAPABILITIES.filter((c) => hasNative(provider, c));
  if (recorded) return able.filter((c) => recorded.includes(c));
  return preferNative ? able : [];
}

/**
 * The words added to our tool's description when the model does the same by itself: it stays in
 * the set (the prefix does not change), for when the person asks for Rasgeth's tool by name.
 */
export function nativeToolNote(capability: Capability): string {
  const what = capability === "image" ? "pictures" : capability === "video" ? "videos" : "sounds";
  return `Your model makes ${what} by itself: use your own tool for that. Use this one only when the person asks for it by name or for the provider chosen in Settings (for example «use your tool», «use Rasgeth's tool», «use the provider I chose»).`;
}

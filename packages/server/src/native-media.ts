// Pictures and files that reach the person (2026-11-19, «generazione nativa del modello prima del
// nostro strumento»): what the agent is told when its model draws by itself, and a reminder when
// an answer shows a picture by a path the person cannot open (the card stayed mute on Coder).
import { stat } from "node:fs/promises";
import { isAbsolute } from "node:path";
import type { Hooks } from "@redgiant/agent";
import { type Capability, PRODUCT_NAME } from "@redgiant/protocol";

/**
 * The system prompt's words when the model's engine makes pictures (videos, sounds) by itself:
 * Rasgeth keeps and sends what it makes, our tool is for when the person asks for it.
 */
export function nativeSection(native: readonly Capability[]): string {
  if (!native.includes("image")) return "";
  return `## Pictures you make yourself
Your model has its own image tool: use it when a picture is wanted. ${PRODUCT_NAME} saves every picture it makes in your workspace (images/<date>/) and sends it to the person in the chat by itself: do not send it again, do not write its path or a link to it in your answer, and do not ask anyone to copy it. image_generation is ${PRODUCT_NAME}'s tool, with the provider the person chose in Settings: use it only when the person asks for it by name («use your tool», «use ${PRODUCT_NAME}'s tool»).`;
}

/** A picture's type from its first bytes (an engine's base64 picture comes without a name). */
export function sniffImage(data: Buffer): string {
  if (data.subarray(0, 8).equals(Buffer.from([0x89, 0x50, 0x4e, 0x47, 0x0d, 0x0a, 0x1a, 0x0a])))
    return "image/png";
  if (data[0] === 0xff && data[1] === 0xd8 && data[2] === 0xff) return "image/jpeg";
  if (
    data.subarray(0, 4).toString("latin1") === "RIFF" &&
    data.subarray(8, 12).toString("latin1") === "WEBP"
  )
    return "image/webp";
  if (data.subarray(0, 4).toString("latin1") === "GIF8") return "image/gif";
  return "application/octet-stream";
}

/**
 * The pictures of a Markdown text the person cannot open: every `![…](src)` whose source is not a
 * web address or an inline picture. The page and the app show those as «cannot be opened»; the
 * agent is told to send the file instead.
 */
export function unreachableImages(text: string): string[] {
  const out: string[] = [];
  for (const m of text.matchAll(/!\[[^\]]*\]\(\s*<?([^)\s>]+)>?(?:\s+"[^"]*")?\s*\)/g)) {
    const src = m[1] ?? "";
    if (/^(https?:|data:image\/)/i.test(src)) continue;
    if (!out.includes(src)) out.push(src);
  }
  return out;
}

/** What the agent is told about a picture in its answer the person cannot open. */
export function unreachableImageNote(srcs: readonly string[]): string {
  return `Your answer shows ${srcs.length === 1 ? "a picture" : "pictures"} by a path the person cannot open (${srcs.join(", ")}): in the chat it does not appear. A file reaches the person only through send_file, from your workspace (copy or save it there first, for example in images/); a picture your model made itself is already in the chat. Send it now if it is not, and say it was sent only after the tool confirms it. Do not repeat the path in your answer.`;
}

/**
 * The stop hook that reminds the agent once per path (2026-11-19): an answer with a picture the
 * person cannot open gets one more turn to send the file.
 */
export function imageTextHook(): NonNullable<Hooks["stop"]>[number] {
  const told = new Map<string, Set<string>>();
  return (completion, ctx) => {
    const text = completion.message.parts
      .flatMap((p) => (p.type === "text" ? [p.text] : []))
      .join("\n");
    const seen = told.get(ctx.sessionId) ?? new Set<string>();
    const fresh = unreachableImages(text).filter((s) => !seen.has(s));
    if (fresh.length === 0) return undefined;
    for (const s of fresh) seen.add(s);
    told.set(ctx.sessionId, seen);
    return { text: unreachableImageNote(fresh), quiet: true as const };
  };
}

/**
 * send_file's error for a path it cannot send (2026-11-19, Chat on Coder sent Codex's picture by
 * its path): what to do instead. A picture in an engine's own folder is already in the chat; any
 * other file outside the workspace goes there first.
 */
export async function sendFileMissing(path: string): Promise<string> {
  if (/[/\\]generated_images[/\\]/.test(path))
    return `"${path}" is in your model's own folder, outside your workspace. ${PRODUCT_NAME} saves the pictures your model makes in your workspace (images/<date>/) and sends them to the person by itself: it is already in the chat. Do not send it again; if you need the file, look in images/.`;
  const exists =
    isAbsolute(path) &&
    (await stat(path).then(
      (x) => x.isFile(),
      () => false,
    ));
  if (exists)
    return `"${path}" is outside your workspace and the projects you may read: the person cannot get it from there. Save or copy it into your workspace first (for example images/ or files/), then send it from there. Until send_file confirms, do not say it was sent.`;
  return `There is no file "${path}" in your workspace${isAbsolute(path) ? " or in a project you may read" : ""}. Files reach the person only from your workspace: save or copy it there first, then send it. Until send_file confirms, do not say it was sent.`;
}

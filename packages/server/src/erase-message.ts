// «Cancella per sempre» on one message (3.9.8, the person's report: a password export pasted by
// mistake reached the log, Echo, the portrait and the engine's own transcript). What a message
// leaves behind is found by its fingerprints (its long lines and, for an export, its values), kept
// in memory only; the engine's transcript is rewritten without them, keeping its owner and mode
// (on Coder a copy written as root left the engine unable to resume: «No conversation found with
// session ID»), and the old file is shredded.
import { randomBytes } from "node:crypto";
import { chmod, chown, open, readdir, readFile, rename, stat } from "node:fs/promises";
import { join } from "node:path";
import { readPasswordExport } from "@redgiant/protocol";
import { shredFile } from "./vault.js";

/** What replaces a string of the transcript holding the erased text. */
export const ERASED_MARK = "[erased at the person's request]";

/**
 * The pieces that betray a message: its lines of 12 characters or more (the whole text when it is
 * shorter), its long words with a digit or a symbol (a code a reply may quote), and an export's
 * values of 8 or more. Never logged, never stored.
 */
export function fingerprints(text: string): string[] {
  const out = new Set<string>();
  const lines = text
    .split(/\r?\n/)
    .map((l) => l.trim())
    .filter((l) => l.length >= 12);
  for (const l of lines) out.add(l);
  if (lines.length === 0 && text.trim().length >= 6) out.add(text.trim());
  // Codes, keys and passwords a reply may quote alone: long words with a digit or a symbol.
  for (const w of text.split(/\s+/)) {
    const t = w.replace(/^[("'«]+|[)"'».,;:!?]+$/g, "");
    if (t.length >= 10 && /[\d_\-#!@$%&*+=/\\]/.test(t) && !/^https?:/.test(t)) out.add(t);
  }
  for (const r of readPasswordExport(text).rows) if (r.value.length >= 8) out.add(r.value);
  return [...out];
}

/** Whether a string holds one of the fingerprints. */
export const tainted = (s: string, fp: readonly string[]): boolean => fp.some((f) => s.includes(f));

/**
 * A transcript (JSON lines) without the fingerprints: every string holding one becomes
 * `ERASED_MARK`, every thinking block holding one is dropped (its signature would no longer
 * match), a line that is not JSON becomes a summary line. `left` must be 0 before it is used.
 */
export function cleanTranscript(
  text: string,
  fp: readonly string[],
): { text: string; changed: number; left: number } {
  if (fp.length === 0) return { text, changed: 0, left: 0 };
  // The fingerprints as JSON writes them too (quotes, backslashes, line breaks escaped).
  const raw = [...new Set([...fp, ...fp.map((f) => JSON.stringify(f).slice(1, -1))])];
  let changed = 0;
  const walk = (v: unknown): unknown => {
    if (typeof v === "string") {
      if (!tainted(v, fp)) return v;
      changed++;
      return ERASED_MARK;
    }
    if (Array.isArray(v))
      return v
        .filter((x) => {
          const thinking =
            x !== null &&
            typeof x === "object" &&
            ((x as { type?: unknown }).type === "thinking" ||
              (x as { type?: unknown }).type === "redacted_thinking" ||
              (x as { type?: unknown }).type === "reasoning");
          if (thinking && tainted(JSON.stringify(x), raw)) {
            changed++;
            return false;
          }
          return true;
        })
        .map(walk);
    if (v !== null && typeof v === "object")
      return Object.fromEntries(Object.entries(v).map(([k, x]) => [k, walk(x)]));
    return v;
  };
  const out = text.split("\n").map((l) => {
    if (!l.trim() || !tainted(l, raw)) return l;
    try {
      return JSON.stringify(walk(JSON.parse(l)));
    } catch {
      changed++;
      return JSON.stringify({ type: "summary", summary: ERASED_MARK });
    }
  });
  const left = out.filter((l) => tainted(l, raw)).length;
  return { text: out.join("\n"), changed, left };
}

/**
 * Rewrites a transcript without the fingerprints: the new file takes the old one's owner and mode
 * before it replaces it, and the old one is shredded. Nothing is written when nothing matches; it
 * throws (writing nothing) when the clean copy would still hold one.
 */
export async function rewriteTranscript(file: string, fp: readonly string[]): Promise<number> {
  const before = await readFile(file, "utf8");
  const clean = cleanTranscript(before, fp);
  if (clean.changed === 0) return 0;
  if (clean.left !== 0) throw new Error("the transcript could not be cleaned: nothing changed");
  const st = await stat(file);
  const tmp = `${file}.${randomBytes(4).toString("hex")}.clean`;
  const h = await open(tmp, "wx", st.mode & 0o777);
  try {
    await h.writeFile(clean.text);
    await h.sync();
  } finally {
    await h.close();
  }
  await chmod(tmp, st.mode & 0o7777);
  // The engine runs as the file's owner: the copy must be theirs (only root can give it).
  if (process.getuid?.() === 0) await chown(tmp, st.uid, st.gid);
  const old = `${file}.${randomBytes(4).toString("hex")}.old`;
  await rename(file, old);
  await rename(tmp, file);
  await shredFile(old);
  return clean.changed;
}

/**
 * The files where an engine keeps one conversation: Claude Code's
 * `<config>/projects/<project>/<id>.jsonl`, Codex's `<home>/sessions/…/rollout-…-<id>.jsonl`
 * (and its archived ones).
 */
export async function engineTranscripts(homes: readonly string[], id: string): Promise<string[]> {
  if (!/^[A-Za-z0-9_-]{6,80}$/.test(id)) return [];
  const out: string[] = [];
  const walk = async (dir: string, depth: number) => {
    const entries = await readdir(dir, { withFileTypes: true }).catch(() => []);
    for (const e of entries) {
      const p = join(dir, e.name);
      if (e.isDirectory() && depth > 0) await walk(p, depth - 1);
      else if (e.isFile() && e.name.endsWith(".jsonl") && e.name.includes(id)) out.push(p);
    }
  };
  for (const home of new Set(homes)) {
    await walk(join(home, "projects"), 2);
    await walk(join(home, "sessions"), 4);
    await walk(join(home, "archived_sessions"), 4);
  }
  return out;
}

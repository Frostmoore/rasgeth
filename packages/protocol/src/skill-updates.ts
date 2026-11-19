// Skills that improve with use (3.9.7, the person's decision): every new version of an installed
// skill waits for the person's yes, and the request says in one line what changed and why
// («Added the step for .rtf files: it failed twice on Word documents»). The line is built here,
// once, for the page, the app and the chats.
import { z } from "zod";

/** The longest «what changed» an agent may write, and the longest line shown. */
export const SKILL_CHANGE_MAX = 160;
export const SKILL_LINE_MAX = 280;

/** The first sentence of a text (for the reason, its first clause too), without its final stop. */
const firstSentence = (s: string, clause = false) => {
  const one = s.replace(/\s+/g, " ").trim();
  const m = one.match(clause ? /^(.+?[.!?;:])(?:\s|$)/u : /^(.+?[.!?])(?:\s|$)/u);
  return (m?.[1] ?? one).replace(/[.!?;:,\s]+$/u, "");
};

/**
 * «: it failed…» reads on, so the reason starts in lower case; a name stays as it is («Word
 * Online…»), and so does an acronym («VAT…»), but «The VAT…» becomes «the VAT…».
 */
const onward = (why: string) => {
  const [first = "", next = ""] = why.split(" ");
  if (!/^\p{Lu}\p{Ll}*$/u.test(first)) return why;
  if (/^\p{Lu}\p{Ll}/u.test(next)) return why;
  return why.charAt(0).toLowerCase() + why.slice(1);
};

/**
 * «What changed: why», in one line: the agent's `change` and the first sentence of its reason,
 * cut at `SKILL_LINE_MAX` characters on a word. Either part may be missing (an older proposal).
 */
export function skillUpdateLine(o: {
  change?: string | null | undefined;
  why?: string | null | undefined;
}): string {
  const change = firstSentence(o.change ?? "");
  const why = firstSentence(o.why ?? "", true);
  const lower = change ? onward(why) : why;
  const line = change && why ? `${change}: ${lower}` : change || why;
  if (line.length <= SKILL_LINE_MAX) return line;
  const cut = line.slice(0, SKILL_LINE_MAX - 1);
  return `${cut.slice(0, Math.max(cut.lastIndexOf(" "), SKILL_LINE_MAX / 2)).trimEnd()}…`;
}

/** A new version of a skill waiting for the person, as the chats show it (with its buttons). */
export const SkillUpdateRequestInfo = z.object({
  proposalId: z.string(),
  name: z.string(),
  /** The agent who wrote it, by name. */
  agentName: z.string(),
  /** What changed and why, in one line (`skillUpdateLine`). */
  line: z.string(),
  createdAt: z.string(),
});
export type SkillUpdateRequestInfo = z.infer<typeof SkillUpdateRequestInfo>;

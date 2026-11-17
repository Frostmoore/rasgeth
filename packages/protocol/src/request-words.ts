// A request in the person's words for the channels that cannot run these rules themselves (G42.1:
// RGCompanion's cards in the chat): what it does (`requestSentence`), its reasons
// (`requestReasons`), the red card's sentences (`criticalSentences`) and its dangers' names and
// hints (`dangerWords`), in Italian and in English. The page computes the same with the same
// functions; the server adds these to every `permission.request` it sends.
import { z } from "zod";
import { criticalSentences } from "./critical.js";
import { dangerWords } from "./dangers.js";
import { requestReasons, requestSentence } from "./requests.js";
import type { PermissionRequestInfo } from "./wire.js";

export const RequestWordsLang = z.object({
  what: z.string(),
  reasons: z.array(z.string()),
  critical: z.array(z.string()),
  dangers: z.array(z.object({ id: z.string(), name: z.string(), hint: z.string() })),
});
export type RequestWordsLang = z.infer<typeof RequestWordsLang>;

export const RequestWords = z.object({ it: RequestWordsLang, en: RequestWordsLang });
export type RequestWords = z.infer<typeof RequestWords>;

/** The words of a request in one language. Pure. */
export function requestWordsIn(
  lang: "it" | "en",
  r: Omit<PermissionRequestInfo, "words">,
): RequestWordsLang {
  return {
    what: requestSentence(lang, r.tool, r.input, r.names),
    reasons: requestReasons(lang, r),
    critical: criticalSentences(lang, r),
    dangers: r.danger.map((id) => ({ id, ...dangerWords(lang, id) })),
  };
}

/** The request with its words in both languages (the ones it carried are made again). Pure. */
export function withRequestWords(r: PermissionRequestInfo): PermissionRequestInfo {
  const { words: _old, ...rest } = r;
  return { ...rest, words: { it: requestWordsIn("it", rest), en: requestWordsIn("en", rest) } };
}

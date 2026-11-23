// What the secretary tells the person (3.12.4), in the interface's language.
import type { PersonNotice } from "./engine.js";

const REASON = {
  it: {
    unknown: "non so rispondere da solo",
    commitment: "serve il tuo sì per un impegno",
    price: "serve il tuo sì per un prezzo nuovo",
    file: "ha mandato un file",
    limit: "troppi messaggi in un'ora",
    other: "serve una tua risposta",
  },
  en: {
    unknown: "I cannot answer this alone",
    commitment: "needs your yes for a commitment",
    price: "needs your yes for a new price",
    file: "sent a file",
    limit: "too many messages in an hour",
    other: "needs an answer from you",
  },
} as const;

/** A short message for the person's chats; the full request is in Messages. */
export function secretaryNotice(n: PersonNotice, lang: "it" | "en"): string {
  const it = lang === "it";
  if (n.kind === "failed")
    return it
      ? `Segretario (${n.channel}): non sono riuscito a rispondere a ${n.contact}: ${n.why}`
      : `Secretary (${n.channel}): I could not answer ${n.contact}: ${n.why}`;
  const why = REASON[lang][n.reason];
  const head = `${n.contact} (${n.channel}): ${why}.`;
  const draft = n.draft ? (it ? `\nRisposta pronta: ${n.draft}` : `\nReady reply: ${n.draft}`) : "";
  return `${head}\n${n.summary}${draft}\n${it ? "Aprila in Messaggi per inviare, modificare o rifiutare." : "Open it in Messages to send, edit or refuse."}`;
}

// A `codex app-server` stand-in for the demo (3.9.5, DEMO_CODEX_ASK=1): driven by Rasgeth's real
// Codex adapter, it asks the person about a UPS with request_user_input and waits for the answer,
// as Codex does; then it answers with the option chosen. JSON-RPC lines on stdio, no network.
import { createInterface } from "node:readline";

const send = (m) => process.stdout.write(`${JSON.stringify(m)}\n`);
let turn = 0;
createInterface({ input: process.stdin }).on("line", (line) => {
  const m = JSON.parse(line);
  const at = { threadId: "th-ups", turnId: `tu-${turn}` };
  if (m.id !== undefined && !m.method) {
    // The person's answer, from Rasgeth's card.
    const chosen = m.result?.answers?.carico?.answers?.join(", ") || "la tua risposta";
    send({
      method: "item/completed",
      params: {
        ...at,
        completedAtMs: 0,
        item: {
          type: "agentMessage",
          id: `msg-${turn}`,
          text: `Con «${chosen}» ti basta un gruppo di continuità line-interactive da 1000 VA.`,
        },
      },
    });
    send({
      method: "turn/completed",
      params: { ...at, turn: { id: at.turnId, status: "completed" } },
    });
    return;
  }
  switch (m.method) {
    case "initialize":
      return send({ id: m.id, result: { userAgent: "demo" } });
    case "thread/start":
    case "thread/resume":
      return send({ id: m.id, result: { thread: { id: "th-ups" } } });
    case "model/list":
      return send({ id: m.id, result: { data: [{ id: "gpt-5.5", model: "gpt-5.5" }] } });
    case "account/rateLimits/read":
      return send({ id: m.id, result: { rateLimits: null } });
    case "turn/interrupt":
      send({ id: m.id, result: {} });
      return send({
        method: "turn/completed",
        params: { ...at, turn: { id: at.turnId, status: "interrupted" } },
      });
    case "turn/start": {
      turn++;
      const t = { threadId: "th-ups", turnId: `tu-${turn}` };
      send({ id: m.id, result: { turn: { id: t.turnId, status: "inProgress", items: [] } } });
      send({
        id: 7000 + turn,
        method: "item/tool/requestUserInput",
        params: {
          ...t,
          itemId: `ask-${turn}`,
          isBlocking: true,
          autoResolutionMs: null,
          questions: [
            {
              id: "carico",
              header: "Carico",
              question: "Quanta potenza deve reggere il gruppo di continuità, e per quanto tempo?",
              isOther: true,
              isSecret: false,
              options: [
                { label: "Sì, circa 300 W; mi bastano 5–10 minuti", description: "PC e monitor" },
                { label: "Circa 600 W, almeno 20 minuti", description: "Anche router e NAS" },
                { label: "Non sono sicuro", description: "Controllo le etichette e ti dico" },
              ],
            },
          ],
        },
      });
      return;
    }
  }
});

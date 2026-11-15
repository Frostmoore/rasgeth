// What an agent's mascot shows (G40.2), from what the page already knows: a request or a question
// waiting for the person, a conversation running (thinking while the model has not written yet or
// is reasoning, working otherwise), the last followed conversation stopped by a budget or a hook,
// or idle.
import type { MascotState } from "@redgiant/protocol";
import { approvals, peekSessionView, questions, sessionRows } from "./state.js";

/** Events that leave a conversation blocked until the person does something. */
const BLOCKING = new Set(["budget.exceeded", "hook.blocked"]);

export function agentMascotState(agentId: string): MascotState {
  if (
    approvals.value.some((r) => r.agentId === agentId) ||
    questions.value.some((q) => q.agentId === agentId)
  )
    return "wait";
  const rows = sessionRows.value.filter((r) => r.agentId === agentId && !r.archived);
  const running = rows.filter((r) => r.running);
  if (running.length > 0) {
    const thinking = running.some((r) => {
      const v = peekSessionView(r.id)?.value;
      return (
        v?.state === "running" &&
        !!v.call &&
        (v.call.writing === "thinking" || v.call.firstToken === undefined)
      );
    });
    return thinking ? "think" : "work";
  }
  const latest = [...rows].sort((a, b) =>
    (b.lastAt ?? b.createdAt).localeCompare(a.lastAt ?? a.createdAt),
  )[0];
  const last = latest && peekSessionView(latest.id)?.value.events.at(-1);
  return last && BLOCKING.has(last.type) ? "error" : "idle";
}

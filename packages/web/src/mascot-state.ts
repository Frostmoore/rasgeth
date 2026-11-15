// What an agent's mascot shows (G40.2), from what the page already knows: a request or a question
// waiting for the person, a conversation running (thinking while the model has not written yet or
// is reasoning, working otherwise), the last followed conversation stopped by a budget or a hook,
// awake for two minutes after answering the person (3.8.1, «active»), or idle (asleep).

import { signal } from "@preact/signals";
import type { MascotState } from "@redgiant/protocol";
import { approvals, peekSessionView, questions, sessionRows } from "./state.js";

/** Events that leave a conversation blocked until the person does something. */
const BLOCKING = new Set(["budget.exceeded", "hook.blocked"]);

/** How long an agent stays awake after its last answer to the person. */
export const ACTIVE_FOR_MS = 2 * 60_000;

/** The page's clock for the mascots: moved only when an «active» one has to fall asleep. */
export const mascotNow = signal(Date.now());
let wake: ReturnType<typeof setTimeout> | undefined;
let wakeAt = Number.POSITIVE_INFINITY;
function asleepAt(at: number): void {
  if (at >= wakeAt) return;
  if (wake) clearTimeout(wake);
  wakeAt = at;
  wake = setTimeout(
    () => {
      wake = undefined;
      wakeAt = Number.POSITIVE_INFINITY;
      mascotNow.value = Date.now();
    },
    Math.max(0, at - Date.now()) + 50,
  );
}

export function agentMascotState(agentId: string, now = mascotNow.value): MascotState {
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
  if (last && BLOCKING.has(last.type)) return "error";
  const replied = Math.max(0, ...rows.map((r) => (r.repliedAt ? Date.parse(r.repliedAt) : 0)));
  if (replied > 0 && now - replied < ACTIVE_FOR_MS && now >= replied - 60_000) {
    asleepAt(replied + ACTIVE_FOR_MS);
    return "active";
  }
  return "idle";
}

import type { Event } from "@redgiant/protocol";

/** The events that say how far a turn got. */
const TURN_EVENTS = new Set<Event["type"]>([
  "message.user",
  "message.assistant",
  "tool.call",
  "tool.result",
  "engine.session",
]);

/**
 * Whether a conversation's last turn was cut (3.8.9): the server stopped (a power cut, a crash,
 * an update) while it worked. Pure, from the conversation's events: a turn that ended has the
 * model's last message (no call left to run, not stopped) or, with an engine, its
 * `engine.session`; a message still waiting for the model, a call, or a result means the turn
 * was going on.
 */
export function turnCut(events: readonly Event[]): boolean {
  for (let i = events.length - 1; i >= 0; i--) {
    const e = events[i] as Event;
    if (e.payload === null || !TURN_EVENTS.has(e.type)) continue;
    if (e.type === "engine.session") return false;
    // `aborted`: the server's own stop cut it (an update); a person's stop gives the task up, so
    // only the server's reaches a resume (`resumeInterrupted` looks at open tasks only).
    if (e.type === "message.assistant")
      return ["tool_use", "pause", "aborted"].includes(e.payload.stopReason);
    return true;
  }
  return false;
}

/** When the last turn event was written: an old cut is not picked up again (ms since epoch). */
export function lastTurnAt(events: readonly Event[]): number | undefined {
  for (let i = events.length - 1; i >= 0; i--) {
    const e = events[i] as Event;
    if (TURN_EVENTS.has(e.type)) return Date.parse(e.ts);
  }
  return undefined;
}

/**
 * What a resumed turn reads (3.8.9): its history is complete up to the stop, and nothing done
 * before it must be done again. The collaudo of 2026-11-17 (GAIA, a blackout) ended with a second
 * orchestrator and two more agents because the work did not go on by itself.
 */
export function resumeNote(task: { id: string; title: string }): string {
  return (
    `[RedGiant restarted (a power cut, a crash or an update) while you were working on task ${task.id} («${task.title}»). ` +
    "Your conversation above is everything that happened up to that moment; a call answered «Interrupted» did not return, and what it does may or may not have happened. " +
    "Check what is already there (files, running commands, list_agents, read_agent) before going on, and do not do again what is done: " +
    "do not create again agents, projects or tasks that already exist, and give work to the agents you already have. " +
    "Then go on with the task where it stopped.]"
  );
}

/**
 * What a resumed agent reads in each conversation with an open task (p3.8.9): it was stopped (a
 * pause, by the person or by an agent above it) and is working again. The GAIA collaudo of
 * 2026-11-17: God paused the team near the week's limit, could not bring it back and made a third
 * orchestrator; resuming in the same conversation keeps one team.
 */
export function pausedNote(task: { id: string; title: string }): string {
  return (
    `[You were stopped (paused) while working on task ${task.id} («${task.title}») and you are resumed now. ` +
    "Your conversation above is everything that happened up to the stop; a call answered «Interrupted» did not return, and what it does may or may not have happened. " +
    "Check what is already there before going on, do not do again what is done, and do not create again agents, projects or tasks that already exist. " +
    "Then go on with the task where it stopped.]"
  );
}

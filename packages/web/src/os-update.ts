// RedGiant OS's update as the page shows it (3.8.1, the person: «si deve capire che sta aggiornando
// con eta e tutto»): the steps in order, which are done, which one runs, which failed, and how long
// the whole is likely to take still. Pure, from the updater's state (os-update.json).
import type { OsUpdates } from "@redgiant/protocol";

export type OsUpdate = NonNullable<OsUpdates["update"]>;
export type StepMark = "done" | "now" | "todo" | "failed";

/** The steps of an update, when the updater does not list them (before 3.8.1). */
export const DEFAULT_STEPS = ["check", "download", "files", "install", "restart", "wait"];

/**
 * Seconds the steps after the downloads usually take (measured on Coder and the Proxmox
 * container): the new system files, RedGiant's restart, its first answer.
 */
export const STEP_SECONDS: Record<string, number> = {
  check: 10,
  install: 10,
  restart: 45,
  wait: 45,
  rollback: 60,
};

/** The steps with their marks: what is done, what runs now, what failed, what comes. */
export function updateSteps(
  u: OsUpdate | null,
  running: boolean,
  /** The page lost the server while it followed the update: RedGiant is restarting. */
  restarting = false,
): { id: string; mark: StepMark }[] {
  const run = u?.run ?? null;
  const steps = run?.steps.length ? run.steps : DEFAULT_STEPS;
  const state = u?.state;
  const finished = state === "latest" && !!run?.finishedAt;
  // Before 3.8.1 «files» was both the download and the install of the system's files.
  let current = restarting ? "restart" : (u?.step ?? (running ? "check" : null));
  if (current && !steps.includes(current)) current = current === "files" ? "install" : null;
  if (finished) return steps.map((id) => ({ id, mark: "done" }));
  // Stopped: the last step it began failed (rollback itself went through).
  if (state === "error" || state === "breaking") {
    const began = Object.keys(run?.stepAt ?? {});
    const last = began.filter((s) => s !== "rollback").at(-1) ?? current;
    const at = last ? steps.indexOf(last) : -1;
    return steps.map((id, i) => ({
      id,
      mark:
        id === "rollback" ? "done" : i < at ? "done" : i === at ? "failed" : ("todo" as StepMark),
    }));
  }
  const at = current ? steps.indexOf(current) : -1;
  return steps.map((id, i) => ({
    id,
    mark: at < 0 ? "todo" : i < at ? "done" : i === at ? "now" : "todo",
  }));
}

/** True while the machine is applying an update (or the page lost RedGiant during one). */
export function updating(u: OsUpdate | null, running: boolean): boolean {
  return running || u?.state === "applying";
}

/**
 * The seconds the whole update probably needs still, or null when it cannot be said yet (the
 * download's speed is not known). The downloads count by their own speed, the steps after them
 * by what they usually take, less what the running one already took.
 */
export function secondsLeft(
  u: OsUpdate | null,
  running: boolean,
  now: number = Date.now(),
  restarting = false,
): number | null {
  if (!updating(u, running) && !restarting) return null;
  const run = u?.run ?? null;
  const steps = updateSteps(u, running, restarting);
  const current = steps.find((s) => s.mark === "now")?.id ?? null;
  if (!current) return null;
  const p = run?.progress ?? null;
  const files = run?.plan?.files?.bytes ?? 0;
  let left = 0;
  for (const s of steps) {
    if (s.mark !== "now" && s.mark !== "todo") continue;
    if (s.id === "download") {
      if (s.mark === "now") {
        if (!p || p.eta === null || p.bps <= 0) return null;
        left += p.eta + files / p.bps;
      } else left += images(run) > 0 ? Number.NaN : 0;
    } else if (s.id === "files") {
      if (s.mark === "now") {
        if (p && p.bps > 0) left += Math.max(0, p.total - p.done) / p.bps;
        else left += 5;
      }
    } else {
      const usual = STEP_SECONDS[s.id] ?? 10;
      const began = s.mark === "now" ? run?.stepAt[s.id] : undefined;
      const took = began ? Math.max(0, (now - Date.parse(began)) / 1000) : 0;
      // A step longer than usual still has a little left (never «0 seconds»).
      left += s.mark === "now" ? Math.max(usual / 4, usual - took) : usual;
    }
  }
  return Number.isFinite(left) ? Math.round(left) : null;
}

/** The bytes the images still need from the internet, from the plan (what is here counts 0). */
function images(run: OsUpdate["run"] | null | undefined): number {
  return (run?.plan?.images ?? []).reduce((n, i) => n + (i.here ? 0 : i.bytes), 0);
}

/**
 * The bytes the update downloads in all: once the images' download began, what Docker really
 * needs (layers already here do not count), otherwise the plan (images not here); with the
 * system's files.
 */
export function planBytes(u: OsUpdate | null): number {
  const run = u?.run ?? null;
  const p = u?.step === "download" ? run?.progress : null;
  return (p && p.total > 0 ? p.total : images(run)) + (run?.plan?.files?.bytes ?? 0);
}

/** How long a finished update took, in seconds (null when unknown). */
export function tookSeconds(u: OsUpdate | null): number | null {
  const run = u?.run;
  if (!run?.finishedAt) return null;
  const s = (Date.parse(run.finishedAt) - Date.parse(run.startedAt)) / 1000;
  return Number.isFinite(s) && s >= 0 ? Math.round(s) : null;
}

/** The version the page should tell it updated to: the run ended well, from another version. */
export function updatedTo(u: OsUpdate | null): { to: string; from: string } | null {
  const run = u?.run;
  if (u?.state !== "latest" || !run?.finishedAt || !run.from || !u.installed) return null;
  return run.from !== u.installed ? { to: u.installed, from: run.from } : null;
}

// The marketing names of Rasgeth's own systems (3.10.3, decided with the person on 2026-11-21:
// «devono essere quelli veramente distintivi ad avere un nome loro»). Only these six have one; the
// rest keeps its plain name (Knowledge, Automations, Keychain…). A name goes on the title of its
// feature (a settings section, a page header, a part of a page) with a few words beside it saying
// what it is, in the person's language; buttons and sentences inside a flow keep plain words.
// Internal code names do not change. RGCompanion mirrors this list (`lib/ui/systems.dart`).
import { type Key, t } from "./i18n.js";

export const SYSTEMS = [
  "constellation",
  "eventHorizon",
  "nebula",
  "deepField",
  "filament",
  "persistar",
] as const;
export type SystemId = (typeof SYSTEMS)[number];

const KEYS: Record<SystemId, [Key, Key]> = {
  constellation: ["sysConstellation", "sysConstellationWhat"],
  eventHorizon: ["sysEventHorizon", "sysEventHorizonWhat"],
  nebula: ["sysNebula", "sysNebulaWhat"],
  deepField: ["sysDeepField", "sysDeepFieldWhat"],
  filament: ["sysFilament", "sysFilamentWhat"],
  persistar: ["sysPersistar", "sysPersistarWhat"],
};

/** The system's name (the same in every language). */
export const sysName = (id: SystemId) => t(KEYS[id][0]);
/** The few words saying what it is, in the person's language. */
export const sysWhat = (id: SystemId) => t(KEYS[id][1]);

/**
 * A system's name as a title, with what it is beside it (under it with `stack`, as in the list of
 * Settings). It goes inside the title's own element (h1, h2, h3, a list row).
 */
export function SysTitle({ id, stack = false }: { id: SystemId; stack?: boolean }) {
  return (
    <span class={`sys${stack ? " stack" : ""}`} data-sys={id}>
      <span class="sys-name">{sysName(id)}</span>
      <span class="sys-what">{sysWhat(id)}</span>
    </span>
  );
}

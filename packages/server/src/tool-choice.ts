// The tools page (G34.5): which common tools the person switched off, for every agent or agent by
// agent, kept in rg_settings; and what each one weighs on every request (its name, description
// and schema, as the model receives them, with the profile of the agent's model).
import type { Tool } from "@redgiant/agent";
import type { SqlClient } from "@redgiant/events";
import {
  type KitState,
  type KitView,
  kitDefault,
  kitState,
  TOOL_CATALOG,
  TOOL_KITS,
  ToolChoice,
  type ToolKit,
  type ToolStateFor,
  type ToolsView,
  type ToolView,
  toolEntryOf,
  toolState,
  toolTokens,
} from "@redgiant/protocol";
import type { Workspace } from "@redgiant/tools";

const KEY = "tools";

/** The person's choice of tools, one row per owner. */
export class ToolChoiceStore {
  constructor(private readonly db: SqlClient) {}

  async get(ownerId: string): Promise<ToolChoice> {
    const [row] = await this.db.query<{ value: unknown }>(
      "SELECT value FROM rg_settings WHERE owner_id = $1 AND key = $2",
      [ownerId, KEY],
    );
    if (!row) return { off: [], agents: {} };
    const v = typeof row.value === "string" ? JSON.parse(row.value) : row.value;
    const parsed = ToolChoice.safeParse(v);
    return parsed.success ? parsed.data : { off: [], agents: {} };
  }

  async set(ownerId: string, choice: ToolChoice): Promise<void> {
    await this.db.query(
      `INSERT INTO rg_settings (owner_id, key, value) VALUES ($1, $2, $3)
       ON CONFLICT (owner_id, key) DO UPDATE SET value = EXCLUDED.value`,
      [ownerId, KEY, JSON.stringify(ToolChoice.parse(choice))],
    );
  }
}

/** Characters a tool adds to every request: its definition as it is sent. */
export function toolChars(t: Pick<Tool, "def">): number {
  return JSON.stringify({
    name: t.def.name,
    description: t.def.description,
    input_schema: t.def.inputSchema,
  }).length;
}

/**
 * The page's entries and kits from the tools measured (name → characters): only the entries some
 * agent has, in the catalog's order. With `who`, each one says what that agent gets (3.9.4: on from
 * the start, off by default, or switched off by the person).
 */
export function toolsView(
  choice: ToolChoice,
  measured: ReadonlyMap<string, number>,
  who: ToolStateFor | null,
  /** The person's agents by id (the view for every agent names the exceptions); others are left out. */
  agentNames?: ReadonlyMap<string, string>,
): ToolsView {
  const agentId = who?.agentId ?? null;
  const byEntry = new Map<string, string[]>();
  for (const name of [...measured.keys()].sort()) {
    const e = toolEntryOf(name);
    if (!e) continue;
    byEntry.set(e.id, [...(byEntry.get(e.id) ?? []), name]);
  }
  const entries: ToolView[] = [];
  for (const e of TOOL_CATALOG) {
    const tools = byEntry.get(e.id);
    if (!tools) continue;
    const chars = tools.reduce((n, t) => n + (measured.get(t) ?? 0), 0);
    const essential = e.essential === true;
    const global = essential || !choice.off.includes(e.id);
    const state: KitState = who
      ? toolState(choice, e.id, who)
      : essential
        ? "on"
        : !global
          ? "off"
          : kitState(choice, e.kit as ToolKit, null);
    // Agents that differ from the switch for everyone, so the page can say so (3.5.3).
    const exceptions =
      agentId === null && !essential && agentNames
        ? Object.entries(choice.agents).flatMap(([id, m]) => {
            const st = m[e.id];
            const name = agentNames.get(id);
            return st && name !== undefined && (st === "on") !== global
              ? [{ agentId: id, name, state: st }]
              : [];
          })
        : [];
    entries.push({
      id: e.id,
      group: e.group,
      essential,
      ...(e.kit && { kit: e.kit }),
      state,
      tools,
      chars,
      tokens: toolTokens(chars),
      global,
      ...(exceptions.length > 0 && { exceptions }),
      ...(agentId !== null && {
        own: essential ? null : (choice.agents[agentId]?.[e.id] ?? null),
        on: state !== "off",
      }),
    });
  }
  const kits: KitView[] = TOOL_KITS.flatMap((k) => {
    const of = entries.filter((v) => v.kit === k);
    if (of.length === 0) return [];
    return [
      {
        id: k,
        entries: of.map((v) => v.id),
        tokens: of.reduce((n, v) => n + v.tokens, 0),
        state: kitState(choice, k, who),
        default: kitDefault(k, who?.kind),
        own: who ? (choice.agentKits?.[who.agentId]?.[k] ?? null) : (choice.kits?.[k] ?? null),
        ...(who && { global: choice.kits?.[k] ?? null }),
      },
    ];
  });
  const sum = (vs: ToolView[]) => vs.reduce((n, v) => n + v.tokens, 0);
  return {
    agentId,
    entries,
    kits,
    total: sum(entries.filter((v) => v.state === "on")),
    saved: sum(entries.filter((v) => v.state !== "on")),
    essential: sum(entries.filter((v) => v.essential)),
  };
}

/**
 * A workspace that does nothing, for weighing an agent's tools without its sandbox (a dry build):
 * the tools are only described, never run.
 */
export function dryWorkspace(): Workspace {
  const no = () => Promise.reject(new Error("A dry workspace only describes tools"));
  return {
    root: "/workspace",
    readOnly: true,
    readText: no,
    writeText: no,
    exists: no,
    isFile: no,
    glob: no,
    exec: no,
    execFile: no,
    openTerminal: no,
  };
}

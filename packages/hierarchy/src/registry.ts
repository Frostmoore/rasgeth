import { randomUUID } from "node:crypto";
import type { EventStore, SqlClient } from "@redgiant/events";
import { hasOwnMascot, MascotBook, mascotSpec, SATELLITE_SEED } from "@redgiant/mascot";
import {
  type AgentSpec,
  LOCAL_OWNER_ID,
  type MascotSpec,
  type ModelSpec,
  type PermissionMode,
  PROJECT_AGENTS_DEFAULT,
} from "@redgiant/protocol";
import {
  type Actor,
  type AgentNode,
  type AgentRoom,
  agentRoom,
  CHILD_KINDS,
  can,
  countsTowardAgentLimit,
  type LimitNode,
} from "./scopes.js";

/**
 * How an agent left the team (p3.8.9): when, by whom ("person" or the agent's name), why, the
 * agent the removal started from (`root`: itself, or the one above it removed with it) and the
 * status it had, given back on restore.
 */
export interface Removal {
  at: string;
  by: string;
  byId?: string;
  reason: string;
  root: string;
  was: "active" | "stopped";
  /** Work its worktree held that is not in the project, so the worktree stayed (3.10.2). */
  kept?: KeptWork;
}

/** What a removed agent's kept worktree holds (3.10.2): restoring the agent gets it back. */
export interface KeptWork {
  branch: string;
  /** Commits not in the project's checked-out branch (counted up to 20). */
  commits: number;
  /** Files changed and not committed in its worktree. */
  changes: number;
  /** It could not be checked, so it was kept as it is. */
  error?: boolean;
}

export interface AgentRecord extends AgentSpec {
  ownerId: string;
  /** "removed" (p3.8.9): out of the team, its history kept; `removed` says how. */
  status: "active" | "stopped" | "removed";
  removed?: Removal;
  /** Its project is archived (2026-11-09): read from the registry, never stored. */
  readonly archived?: boolean;
  /** It is the person's Chat (p3.8.9): read from the registry, never stored. */
  readonly chat?: boolean;
}

export interface NewAgent {
  kind: AgentSpec["kind"];
  parentId: string | null;
  projectId?: string | null;
  persistent?: boolean;
  name: string;
  role?: string;
  systemPrompt?: string;
  model?: ModelSpec;
  mode?: PermissionMode;
  connections?: string[];
  subprojectId?: string;
  compaction?: { at?: number; keep?: number };
  skills?: string[];
  projects?: string[];
}

export class HierarchyError extends Error {
  constructor(message: string) {
    super(message);
    this.name = "HierarchyError";
  }
}

/**
 * A project already has as many agents as the person allows (2026-11-18): nothing was created or
 * brought back. The message is for the model; `code` and `vars` let the page and the app say it in
 * the person's language.
 */
export class AgentLimitError extends HierarchyError {
  readonly code = "agent_limit";
  constructor(
    readonly projectId: string,
    readonly projectName: string,
    readonly max: number,
    readonly count: number,
  ) {
    super(
      `${
        max === 0
          ? `The project "${projectName}" works with its orchestrator alone (its limit is 0 agents)`
          : `The project "${projectName}" can have at most ${max} agent${max === 1 ? "" : "s"} besides its orchestrator`
      }: it has ${count}. Nothing was created: ask the person to raise the limit (Settings > Projects)${
        count > 0 ? " or remove an agent first" : ""
      }.`,
    );
    this.name = "AgentLimitError";
  }

  get vars(): Record<string, string> {
    return { project: this.projectName, max: String(this.max), count: String(this.count) };
  }
}

interface Row {
  id: string;
  owner_id: string;
  kind: AgentSpec["kind"];
  parent_id: string | null;
  project_id: string | null;
  persistent: boolean;
  name: string;
  role: string | null;
  system_prompt: string | null;
  model: string | null;
  mode: PermissionMode | null;
  connections: string | null;
  subproject_id: string | null;
  compaction: string | null;
  skills: string | null;
  projects: string | null;
  mascot_seed: string | null;
  status: "active" | "stopped" | "removed";
  removed: string | null;
  created_at?: string | Date;
}

export async function migrateHierarchy(db: SqlClient): Promise<void> {
  await db.query(`
    CREATE TABLE IF NOT EXISTS rg_agents (
      id            text PRIMARY KEY,
      owner_id      text NOT NULL,
      kind          text NOT NULL,
      parent_id     text REFERENCES rg_agents(id),
      project_id    text,
      persistent    boolean NOT NULL,
      name          text NOT NULL,
      role          text,
      system_prompt text,
      model         text,
      mode          text,
      status        text NOT NULL DEFAULT 'active',
      created_at    timestamptz NOT NULL DEFAULT now()
    )`);
  // The services an assistant may use (G24.11).
  await db.query("ALTER TABLE rg_agents ADD COLUMN IF NOT EXISTS connections text");
  // The subproject an agent works in (G24.13).
  await db.query("ALTER TABLE rg_agents ADD COLUMN IF NOT EXISTS subproject_id text");
  // How its conversations are summarised (G24.14c).
  await db.query("ALTER TABLE rg_agents ADD COLUMN IF NOT EXISTS compaction text");
  // Other projects it is assigned to (2026-11-03), under their orchestrators.
  await db.query("ALTER TABLE rg_agents ADD COLUMN IF NOT EXISTS projects text");
  // The skills an agent uses, when not all (G24.14c).
  await db.query("ALTER TABLE rg_agents ADD COLUMN IF NOT EXISTS skills text");
  // Its mascot's seed (G40.2): fixed at creation; the agents made before get theirs at `load`.
  await db.query("ALTER TABLE rg_agents ADD COLUMN IF NOT EXISTS mascot_seed text");
  // How a removed agent left the team (p3.8.9), given back on restore.
  await db.query("ALTER TABLE rg_agents ADD COLUMN IF NOT EXISTS removed text");
  // One God and one Demi-God per owner, one orchestrator and one inspector per project.
  await db.query(
    "CREATE UNIQUE INDEX IF NOT EXISTS rg_agents_one_god ON rg_agents (owner_id, kind) WHERE kind IN ('god', 'demigod') AND status = 'active'",
  );
  // G24.13: one inspector per project and one per subproject; one orchestrator per project.
  await db.query("DROP INDEX IF EXISTS rg_agents_one_per_project");
  await db.query(
    "CREATE UNIQUE INDEX IF NOT EXISTS rg_agents_one_per_project_v2 ON rg_agents (owner_id, project_id, kind, (COALESCE(subproject_id, ''))) WHERE kind IN ('orchestrator', 'inspector') AND status = 'active'",
  );
  await db.query(`
    CREATE TABLE IF NOT EXISTS rg_budgets (
      scope      text NOT NULL,
      key        text NOT NULL,
      limit_usd  double precision,
      limit_tok  bigint,
      spent_usd  double precision NOT NULL DEFAULT 0,
      spent_tok  bigint NOT NULL DEFAULT 0,
      PRIMARY KEY (scope, key)
    )`);
  // Spend per day (G24.10): what the counters above add up, for the month's chart.
  await db.query(`
    CREATE TABLE IF NOT EXISTS rg_spend_daily (
      owner_id text NOT NULL,
      day      text NOT NULL,
      scope    text NOT NULL,
      key      text NOT NULL,
      usd      double precision NOT NULL DEFAULT 0,
      tokens   bigint NOT NULL DEFAULT 0,
      PRIMARY KEY (owner_id, day, scope, key)
    )`);
}

const fromRow = (r: Row): AgentRecord => ({
  id: r.id,
  ownerId: r.owner_id,
  kind: r.kind,
  parentId: r.parent_id,
  projectId: r.project_id,
  persistent: r.persistent,
  name: r.name,
  ...(r.role !== null && { role: r.role }),
  ...(r.system_prompt !== null && { systemPrompt: r.system_prompt }),
  ...(r.model !== null && { model: JSON.parse(r.model) as ModelSpec }),
  ...(r.mode !== null && { mode: r.mode }),
  ...(r.connections !== null && { connections: JSON.parse(r.connections) as string[] }),
  ...(r.subproject_id !== null && { subprojectId: r.subproject_id }),
  ...(r.skills !== null && { skills: JSON.parse(r.skills) as string[] }),
  ...(r.projects && { projects: JSON.parse(r.projects) as string[] }),
  ...(r.mascot_seed && { mascotSeed: r.mascot_seed }),
  ...(r.compaction !== null && {
    compaction: JSON.parse(r.compaction) as { at?: number; keep?: number },
  }),
  status: r.status,
  ...(r.removed && { removed: JSON.parse(r.removed) as Removal }),
});

/**
 * The agent tree of every owner. Creation and stopping are checked against the scope rules
 * and recorded in the event log.
 */
const projectKey = (ownerId: string, projectId: string) => `${ownerId}/${projectId}`;

export class AgentRegistry {
  private cache = new Map<string, AgentRecord>();
  /** Archived projects (2026-11-09), as `owner/project` (project ids are slugs): set by the server at start. */
  private readonly archivedProjects = new Set<string>();
  /** Each owner's Chat agent (p3.8.9): set by the server; never removed. */
  private readonly chats = new Map<string, string>();
  /**
   * Each project's agent limit (2026-11-18), as `owner/project`, with its name for the refusal:
   * set by the server at start and when the person changes it; absent, the default.
   */
  private readonly agentLimits = new Map<string, { max: number; name: string }>();

  constructor(
    private readonly db: SqlClient,
    private readonly store: EventStore,
  ) {}

  private readonly changeListeners = new Set<(ownerId: string) => void>();
  /**
   * Called after one of the owner's agents was made, stopped, configured, moved, renamed or got
   * a new face (p3.8.9): the server tells every page and app of the owner to read the team again.
   */
  onChange(listener: (ownerId: string) => void): () => void {
    this.changeListeners.add(listener);
    return () => this.changeListeners.delete(listener);
  }
  private changed(ownerId: string): void {
    for (const f of this.changeListeners) f(ownerId);
  }

  /**
   * Loads every agent into memory (the tree is small). Agents made before mascots (G40.2) get
   * their seed now, once, in the order they were made: their name of today (or `name#1`… when
   * that face is taken), saved and logged, so it never changes again.
   */
  async load(): Promise<void> {
    const rows = await this.db.query<Row>("SELECT * FROM rg_agents");
    this.cache = new Map(rows.map((r) => [r.id, this.mark(fromRow(r))]));
    const time = (r: Row) => (r.created_at ? new Date(r.created_at).getTime() : 0);
    // Sub-agents never get one (decision of 2026-11-19): they show their parent's ring.
    const missing = rows
      .filter((r) => !r.mascot_seed && hasOwnMascot({ kind: r.kind as AgentRecord["kind"] }))
      .sort((a, b) => time(a) - time(b));
    for (const r of missing) {
      const a = this.cache.get(r.id);
      if (!a) continue;
      const seed = this.claimSeed(a.ownerId, a.name, a.kind, a.id);
      await this.db.query("UPDATE rg_agents SET mascot_seed = $2 WHERE id = $1", [a.id, seed]);
      a.mascotSeed = seed;
      await this.store.append({
        ownerId: a.ownerId,
        projectId: a.projectId,
        agentId: null,
        body: {
          type: "agent.mascot_changed",
          payload: { agentId: a.id, seed, reason: "migrated" },
        },
      });
    }
  }

  /**
   * An agent's mascot (G40.2): from its saved seed (its id if it has none yet). A sub-agent has
   * none (decision «Mascotte solo per orchestratori e agenti di primo livello», 2026-11-19): it
   * shows a ring in its parent's colour (`subagentSignSvg`), even if an older one kept a seed.
   */
  mascotOf(id: string): MascotSpec | undefined {
    const a = this.cache.get(id);
    if (!a || !hasOwnMascot(a)) return undefined;
    // The person's Chat is Satellite (3.12.1), drawn by hand, whatever seed it kept.
    if (this.chats.get(a.ownerId) === a.id) return mascotSpec(SATELLITE_SEED, a.kind);
    return mascotSpec(a.mascotSeed ?? a.id, a.kind);
  }

  /** The faces the owner's working agents have now (all but `except`). */
  private mascotBook(ownerId: string, except?: string): MascotBook {
    const book = new MascotBook();
    // A removed agent keeps its face (p3.8.9): it may come back.
    for (const a of this.cache.values())
      if (a.ownerId === ownerId && a.status !== "stopped" && a.mascotSeed && a.id !== except) {
        const spec = this.mascotOf(a.id);
        if (spec) book.add(spec);
      }
    return book;
  }

  /**
   * The face a new agent named `name` would get now (3.8.1, the app's preview while the person
   * types): the same choice `create` makes, nothing saved. None for a sub-agent.
   */
  previewMascot(ownerId: string, name: string, kind: AgentSpec["kind"]): MascotSpec | undefined {
    if (!hasOwnMascot({ kind })) return undefined;
    return this.mascotBook(ownerId).claim(name, kind);
  }

  /** The first free face for `base` among the owner's agents: the seed to save. */
  private claimSeed(
    ownerId: string,
    base: string,
    kind: AgentSpec["kind"],
    except?: string,
  ): string {
    return this.mascotBook(ownerId, except).claim(base, kind).seed;
  }

  /**
   * «Change mascot» (G40.2): the person asks for a new face, explicitly. A new seed, different
   * from every face in use (the old one included), saved and logged. God is drawn by hand.
   */
  async changeMascot(actor: Actor, id: string): Promise<AgentRecord> {
    const a = this.cache.get(id);
    if (!a) throw new HierarchyError(`Unknown agent "${id}"`);
    if (actor.type !== "human") throw new HierarchyError("Only the person changes a mascot");
    if (a.kind === "god") throw new HierarchyError("God's mascot is drawn by hand");
    if (this.chats.get(a.ownerId) === id)
      throw new HierarchyError("The Chat's mascot, Satellite, is drawn by hand");
    if (!hasOwnMascot(a)) throw new HierarchyError("A sub-agent has no mascot of its own");
    const book = this.mascotBook(a.ownerId);
    const base = `${a.name}~${randomUUID().slice(0, 6)}`;
    const seed = book.claim(base, a.kind).seed;
    await this.db.query("UPDATE rg_agents SET mascot_seed = $2 WHERE id = $1", [id, seed]);
    const updated: AgentRecord = { ...a, mascotSeed: seed };
    this.cache.set(id, this.mark(updated));
    await this.store.append({
      ownerId: a.ownerId,
      projectId: a.projectId,
      agentId: null,
      body: { type: "agent.mascot_changed", payload: { agentId: id, seed, reason: "changed" } },
    });
    this.changed(a.ownerId);
    return updated;
  }

  get(id: string): AgentRecord | undefined {
    return this.cache.get(id);
  }

  /**
   * Every cached record says whether its project is archived (the scope rules read it), always
   * as it is now. Not enumerable: it never reaches a row, an event or an answer by a spread.
   */
  private mark(record: AgentRecord): AgentRecord {
    Object.defineProperty(record, "archived", {
      get: () =>
        record.projectId !== null &&
        this.archivedProjects.has(projectKey(record.ownerId, record.projectId)),
      enumerable: false,
      configurable: true,
    });
    Object.defineProperty(record, "chat", {
      get: () => this.chats.get(record.ownerId) === record.id,
      enumerable: false,
      configurable: true,
    });
    return record;
  }

  /** The owner's Chat agent (p3.8.9): the scope rules never let anyone remove it. */
  setChatAgent(ownerId: string, id: string | null): void {
    if (id) this.chats.set(ownerId, id);
    else this.chats.delete(ownerId);
  }

  /** A project archived or restored (2026-11-09): its agents only read until it comes back. */
  setProjectArchived(ownerId: string, projectId: string, archived: boolean): void {
    const key = projectKey(ownerId, projectId);
    if (archived) this.archivedProjects.add(key);
    else this.archivedProjects.delete(key);
  }

  isProjectArchived(ownerId: string, projectId: string | null | undefined): boolean {
    return !!projectId && this.archivedProjects.has(projectKey(ownerId, projectId));
  }

  /** A project's agent limit (2026-11-18), or `null` for the default. Removes nobody. */
  setProjectAgentLimit(
    ownerId: string,
    projectId: string,
    max: number | null,
    name?: string,
  ): void {
    const key = projectKey(ownerId, projectId);
    if (max === null) this.agentLimits.delete(key);
    else this.agentLimits.set(key, { max, name: name ?? projectId });
  }

  /** How many agents the project may have besides its orchestrator. */
  projectAgentLimit(ownerId: string, projectId: string): number {
    return this.agentLimits.get(projectKey(ownerId, projectId))?.max ?? PROJECT_AGENTS_DEFAULT;
  }

  /** Whether `adding` more agents that count fit in the project now (`agentRoom`). */
  agentRoom(ownerId: string, projectId: string, adding = 1): AgentRoom {
    return agentRoom(
      this.list({ ownerId, projectId, removed: true }),
      projectId,
      this.projectAgentLimit(ownerId, projectId),
      adding,
    );
  }

  /** Throws `AgentLimitError` when these agents, joining the team as given, would not fit. */
  private assertRoom(ownerId: string, projectId: string | null, joining: LimitNode[]): void {
    if (!projectId) return;
    const adding = joining.filter((a) => countsTowardAgentLimit(a, projectId)).length;
    const room = this.agentRoom(ownerId, projectId, adding);
    if (!room.ok)
      throw new AgentLimitError(
        projectId,
        this.agentLimits.get(projectKey(ownerId, projectId))?.name ?? projectId,
        room.max,
        room.count,
      );
  }

  /** Lookup for scope checks. */
  readonly resolve = (id: string): AgentNode | undefined => this.cache.get(id);

  /**
   * The team: removed agents (p3.8.9) are never in it, unless `removed` asks for them ("only":
   * them alone, true: with the others).
   */
  list(
    filter: {
      ownerId?: string;
      projectId?: string;
      parentId?: string;
      activeOnly?: boolean;
      removed?: boolean | "only";
    } = {},
  ): AgentRecord[] {
    return [...this.cache.values()].filter(
      (a) =>
        (filter.ownerId === undefined || a.ownerId === filter.ownerId) &&
        (filter.projectId === undefined || a.projectId === filter.projectId) &&
        (filter.parentId === undefined || a.parentId === filter.parentId) &&
        (!filter.activeOnly || a.status === "active") &&
        (filter.removed === "only"
          ? a.status === "removed"
          : filter.removed === true || a.status !== "removed"),
    );
  }

  /** Creates an agent on behalf of `actor` (the human, or the agent that spawns it). */
  async create(actor: Actor, input: NewAgent): Promise<AgentRecord> {
    const ownerId = actor.type === "human" ? actor.ownerId : actor.agent.ownerId;
    const parent = input.parentId ? this.cache.get(input.parentId) : undefined;
    if (input.parentId && !parent) throw new HierarchyError(`Unknown parent "${input.parentId}"`);
    if (parent && parent.status !== "active")
      throw new HierarchyError(
        parent.status === "removed" ? "The parent agent is removed" : "The parent agent is stopped",
      );
    if (parent && parent.ownerId !== ownerId)
      throw new HierarchyError("The parent belongs to another owner");

    if (input.kind === "god") {
      if (parent) throw new HierarchyError("God has no parent");
      if (actor.type !== "human") throw new HierarchyError("Only the human can create God");
    } else {
      if (!parent) throw new HierarchyError(`A ${input.kind} needs a parent`);
      if (!CHILD_KINDS[parent.kind].includes(input.kind)) {
        throw new HierarchyError(`A ${parent.kind} cannot have a ${input.kind} below it`);
      }
      if (!can(actor, "spawn", parent, this.resolve)) {
        throw new HierarchyError(`Not allowed to create agents under "${parent.name}"`);
      }
    }

    const needsProject = ["orchestrator", "agent", "subagent", "inspector"].includes(input.kind);
    const projectId = needsProject ? (input.projectId ?? parent?.projectId ?? null) : null;
    if (needsProject && !projectId)
      throw new HierarchyError(`A ${input.kind} belongs to a project`);
    if (this.isProjectArchived(ownerId, projectId))
      throw new HierarchyError(`The project "${projectId}" is archived: restore it first`);
    if (parent?.projectId && projectId !== parent.projectId) {
      throw new HierarchyError("A child must belong to its parent's project");
    }
    const persistent = input.kind === "subagent" ? false : (input.persistent ?? true);
    // A child works where its parent does; only project agents belong to a subproject.
    const subprojectId =
      parent?.subprojectId ??
      (["agent", "inspector"].includes(input.kind) ? input.subprojectId : undefined);
    if (parent?.subprojectId && input.subprojectId && input.subprojectId !== parent.subprojectId)
      throw new HierarchyError("A child works in its parent's subproject");
    // The person's limit for the project (2026-11-18): every way of making an agent comes here.
    this.assertRoom(ownerId, projectId, [{ kind: input.kind, projectId, status: "active" }]);

    const agentId = `${input.kind}_${randomUUID().slice(0, 8)}`;
    // The mascot's seed is fixed now (G40.2): renaming never changes the face. A sub-agent gets
    // none (2026-11-19): it shows its parent's ring.
    const mascotSeed = hasOwnMascot(input)
      ? this.claimSeed(ownerId, input.name, input.kind)
      : undefined;
    const record: AgentRecord = {
      id: agentId,
      ownerId,
      kind: input.kind,
      parentId: input.parentId,
      projectId,
      persistent,
      name: input.name,
      ...(input.role !== undefined && { role: input.role }),
      ...(input.systemPrompt !== undefined && { systemPrompt: input.systemPrompt }),
      ...(input.model !== undefined && { model: input.model }),
      ...(input.mode !== undefined && { mode: input.mode }),
      ...(input.connections !== undefined && { connections: input.connections }),
      ...(subprojectId !== undefined && { subprojectId }),
      ...(mascotSeed !== undefined && { mascotSeed }),
      status: "active",
    };
    try {
      await this.db.query(
        `INSERT INTO rg_agents (id, owner_id, kind, parent_id, project_id, persistent, name, role, system_prompt, model, mode, connections, subproject_id, mascot_seed)
         VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11, $12, $13, $14)`,
        [
          record.id,
          ownerId,
          record.kind,
          record.parentId,
          projectId,
          persistent,
          record.name,
          input.role ?? null,
          input.systemPrompt ?? null,
          input.model ? JSON.stringify(input.model) : null,
          input.mode ?? null,
          input.connections ? JSON.stringify(input.connections) : null,
          subprojectId ?? null,
          mascotSeed ?? null,
        ],
      );
    } catch (err) {
      if (/unique/i.test(String(err))) {
        throw new HierarchyError(
          input.kind === "god" || input.kind === "demigod"
            ? `There is already a ${input.kind}`
            : `The project already has an ${input.kind}`,
        );
      }
      throw err;
    }
    this.cache.set(record.id, this.mark(record));
    const { status: _s, ownerId: _o, ...spec } = record;
    await this.store.append({
      ownerId,
      projectId,
      agentId: actor.type === "agent" ? actor.agent.id : null,
      body: { type: "agent.spawned", payload: { agent: spec } },
    });
    this.changed(ownerId);
    return record;
  }

  /** Stops an agent and, recursively, everything below it. */
  async stop(actor: Actor, id: string, reason: string): Promise<string[]> {
    const target = this.cache.get(id);
    if (!target) throw new HierarchyError(`Unknown agent "${id}"`);
    if (!can(actor, "stop", target, this.resolve))
      throw new HierarchyError(`Not allowed to stop "${target.name}"`);
    if (target.status === "removed") throw new HierarchyError(`"${target.name}" is removed`);
    const stopped: string[] = [];
    const walk = async (a: AgentRecord) => {
      for (const child of this.list({ parentId: a.id, activeOnly: true })) await walk(child);
      if (a.status === "stopped") return;
      await this.db.query("UPDATE rg_agents SET status = 'stopped' WHERE id = $1", [a.id]);
      a.status = "stopped";
      stopped.push(a.id);
      await this.store.append({
        ownerId: a.ownerId,
        projectId: a.projectId,
        agentId: a.id,
        body: { type: "agent.stopped", payload: { agentId: a.id, reason } },
      });
    };
    await walk(target);
    if (stopped.length > 0) this.changed(target.ownerId);
    return stopped;
  }

  /**
   * Resumes a stopped agent (p3.8.9: stopping is a pause), with the agents below it that were
   * stopped (never sub-agents: they lived for one task). Refused while the agent above it is
   * stopped or removed, and when its place is taken now (a project's new orchestrator): nothing
   * half done. The core then lets their open tasks go on. Returns the ids, `id` first.
   */
  async resume(actor: Actor, id: string, by: string): Promise<{ resumed: AgentRecord[] }> {
    const target = this.cache.get(id);
    if (!target) throw new HierarchyError(`Unknown agent "${id}"`);
    if (target.status === "removed")
      throw new HierarchyError(`"${target.name}" is removed: restore it instead`);
    if (target.status === "active") throw new HierarchyError(`"${target.name}" is not stopped`);
    if (!can(actor, "resume", target, this.resolve))
      throw new HierarchyError(`Not allowed to resume "${target.name}"`);
    const parent = target.parentId ? this.cache.get(target.parentId) : undefined;
    if (parent && parent.status !== "active")
      throw new HierarchyError(
        `"${parent.name}" above it is ${parent.status}: bring it back first`,
      );
    const group: AgentRecord[] = [];
    const walk = (a: AgentRecord) => {
      group.push(a);
      for (const child of this.list({ parentId: a.id }))
        if (child.status === "stopped" && child.kind !== "subagent") walk(child);
    };
    walk(target);
    // Only what did not count while stopped (a sub-agent) takes room in the project's limit.
    this.assertRoom(
      target.ownerId,
      target.projectId,
      group
        .filter((a) => !countsTowardAgentLimit(a, a.projectId ?? ""))
        .map((a) => ({ ...a, status: "active" as const })),
    );
    try {
      await this.db.transaction(async (tx) => {
        for (const a of group)
          await tx.query("UPDATE rg_agents SET status = 'active' WHERE id = $1", [a.id]);
      });
    } catch (err) {
      if (/unique/i.test(String(err)))
        throw new HierarchyError(
          `The place of "${target.name}" is taken now (another ${target.kind} works there): stop or remove that one first`,
        );
      throw err;
    }
    for (const a of group) a.status = "active";
    await this.store.append({
      ownerId: target.ownerId,
      projectId: target.projectId,
      agentId: actor.type === "agent" ? actor.agent.id : null,
      body: {
        type: "agent.resumed",
        payload: { agentId: id, by, with: group.slice(1).map((a) => a.id) },
      },
    });
    return { resumed: group };
  }

  /**
   * The agents a removal of `id` takes with it (p3.8.9): everything below it that is still in the
   * team, deepest first, then `id` itself last. Nothing is checked or changed.
   */
  subtree(id: string): AgentRecord[] {
    const out: AgentRecord[] = [];
    const walk = (a: AgentRecord) => {
      for (const child of this.list({ parentId: a.id })) walk(child);
      out.push(a);
    };
    const a = this.cache.get(id);
    if (a && a.status !== "removed") walk(a);
    return out;
  }

  /**
   * Removes an agent from the team (p3.8.9) with everything below it: they leave every list and
   * take no turn; nothing of their history goes (rows, sessions and log stay) and `restore` brings
   * them back as they were. The scope rules decide who may (`can` "remove"). Returns the ids,
   * `id` first. The core stops their turns and closes their tasks.
   */
  async remove(
    actor: Actor,
    id: string,
    reason: string,
    by: string,
  ): Promise<{ removed: AgentRecord[] }> {
    const target = this.cache.get(id);
    if (!target) throw new HierarchyError(`Unknown agent "${id}"`);
    if (target.status === "removed")
      throw new HierarchyError(`"${target.name}" is removed already`);
    if (!can(actor, "remove", target, this.resolve))
      throw new HierarchyError(
        target.kind === "god" || target.kind === "demigod" || target.chat
          ? `"${target.name}" is never removed`
          : `Not allowed to remove "${target.name}"`,
      );
    const group = this.subtree(id).reverse();
    const at = new Date().toISOString();
    for (const a of group) {
      const removal: Removal = {
        at,
        by,
        ...(actor.type === "agent" && { byId: actor.agent.id }),
        reason,
        root: id,
        was: a.status === "stopped" ? "stopped" : "active",
      };
      await this.db.query("UPDATE rg_agents SET status = 'removed', removed = $2 WHERE id = $1", [
        a.id,
        JSON.stringify(removal),
      ]);
      a.status = "removed";
      a.removed = removal;
    }
    await this.store.append({
      ownerId: target.ownerId,
      projectId: target.projectId,
      agentId: actor.type === "agent" ? actor.agent.id : null,
      body: {
        type: "agent.removed",
        payload: {
          agentId: id,
          reason,
          by,
          with: group.slice(1).map((a) => a.id),
          was: group[0]?.removed?.was ?? "active",
        },
      },
    });
    return { removed: group };
  }

  /** Notes on a removed agent the work its kept worktree holds (3.10.2), for the removed list. */
  async noteKept(id: string, kept: KeptWork): Promise<void> {
    const a = this.cache.get(id);
    if (!a || a.status !== "removed" || !a.removed) return;
    const removal: Removal = { ...a.removed, kept };
    await this.db.query("UPDATE rg_agents SET removed = $2 WHERE id = $1", [
      id,
      JSON.stringify(removal),
    ]);
    a.removed = removal;
  }

  /**
   * Brings back a removal (p3.8.9): the agent and those removed with it, each with the status it
   * had. Refused while the agent above it is removed (restore that one), and when the place it
   * had is taken now (a project's new orchestrator or inspector): nothing half done.
   */
  async restore(actor: Actor, id: string, by: string): Promise<{ restored: AgentRecord[] }> {
    const target = this.cache.get(id);
    if (!target) throw new HierarchyError(`Unknown agent "${id}"`);
    if (target.status !== "removed" || !target.removed)
      throw new HierarchyError(`"${target.name}" is not removed`);
    if (target.removed.root !== id) {
      const root = this.cache.get(target.removed.root);
      throw new HierarchyError(
        `"${target.name}" was removed with "${root?.name ?? target.removed.root}": restore that one`,
      );
    }
    if (!can(actor, "remove", target, this.resolve))
      throw new HierarchyError(`Not allowed to restore "${target.name}"`);
    const parent = target.parentId ? this.cache.get(target.parentId) : undefined;
    if (parent?.status === "removed")
      throw new HierarchyError(`"${parent.name}" above it is removed: restore it first`);
    const group = [...this.cache.values()]
      .filter((a) => a.status === "removed" && a.removed?.root === id)
      // Parents before children, as they were made.
      .sort((a, b) => (a.id === id ? -1 : b.id === id ? 1 : depth(this, a) - depth(this, b)));
    const taken = group.find(
      (a) =>
        a.status === "removed" &&
        a.removed?.was === "active" &&
        ["god", "demigod", "orchestrator", "inspector"].includes(a.kind) &&
        this.list({ ownerId: a.ownerId, activeOnly: true }).some(
          (o) =>
            o.kind === a.kind &&
            o.projectId === a.projectId &&
            (o.subprojectId ?? null) === (a.subprojectId ?? null),
        ),
    );
    if (taken)
      throw new HierarchyError(
        `The project "${taken.projectId}" has another ${taken.kind} now: remove or stop it first`,
      );
    // The project's limit (2026-11-18): a removed agent comes back only if there is room for it
    // and for those removed with it, as they were.
    this.assertRoom(
      target.ownerId,
      target.projectId,
      group.map((a) => ({ ...a, status: a.removed?.was ?? "active" })),
    );
    // All of the group or none (a unique place taken meanwhile fails the whole restore).
    try {
      await this.db.transaction(async (tx) => {
        for (const a of group)
          await tx.query("UPDATE rg_agents SET status = $2, removed = NULL WHERE id = $1", [
            a.id,
            a.removed?.was ?? "active",
          ]);
      });
    } catch (err) {
      if (/unique/i.test(String(err)))
        throw new HierarchyError(`Its place is taken now: remove or stop the agent there first`);
      throw err;
    }
    for (const a of group) {
      a.status = a.removed?.was ?? "active";
      delete a.removed;
    }
    await this.store.append({
      ownerId: target.ownerId,
      projectId: target.projectId,
      agentId: actor.type === "agent" ? actor.agent.id : null,
      body: {
        type: "agent.restored",
        payload: { agentId: id, by, with: group.slice(1).map((a) => a.id) },
      },
    });
    return { restored: group };
  }

  /**
   * Changes model, mode or prompt; only God (not on itself) and the human may. `null` clears
   * a field (the model is inherited again, the prompt is the default one).
   */
  async configure(
    actor: Actor,
    id: string,
    change: {
      model?: ModelSpec | null;
      mode?: PermissionMode | null;
      systemPrompt?: string | null;
      connections?: string[] | null;
      role?: string | null;
      compaction?: { at?: number; keep?: number } | null;
      skills?: string[] | null;
      projects?: string[] | null;
    },
  ): Promise<AgentRecord> {
    const target = this.cache.get(id);
    if (!target) throw new HierarchyError(`Unknown agent "${id}"`);
    if (!can(actor, "configure", target, this.resolve))
      throw new HierarchyError(`Not allowed to configure "${target.name}"`);
    const columns = {
      model: "model",
      mode: "mode",
      systemPrompt: "system_prompt",
      connections: "connections",
      role: "role",
      compaction: "compaction",
      skills: "skills",
      projects: "projects",
    } as const;
    const sets: string[] = [];
    const params: unknown[] = [id];
    for (const [key, column] of Object.entries(columns) as [keyof typeof columns, string][]) {
      if (change[key] === undefined) continue;
      const v = change[key];
      params.push(
        (key === "model" ||
          key === "connections" ||
          key === "compaction" ||
          key === "skills" ||
          key === "projects") &&
          v !== null
          ? JSON.stringify(v)
          : v,
      );
      sets.push(`${column} = $${params.length}`);
    }
    if (sets.length > 0)
      await this.db.query(`UPDATE rg_agents SET ${sets.join(", ")} WHERE id = $1`, params);
    const updated: AgentRecord = { ...target };
    for (const key of Object.keys(columns) as (keyof typeof columns)[]) {
      const v = change[key];
      if (v === undefined) continue;
      if (v === null) delete updated[key];
      else Object.assign(updated, { [key]: v });
    }
    this.cache.set(id, this.mark(updated));
    this.changed(target.ownerId);
    return updated;
  }

  /**
   * Moves an agent to another project or subproject, or under another parent (G24.14c: a project
   * becoming a subproject of another). Only the human does it; the log records it.
   */
  async move(
    id: string,
    to: { projectId: string | null; subprojectId: string | null; parentId: string | null },
  ): Promise<AgentRecord> {
    const a = this.cache.get(id);
    if (!a) throw new HierarchyError(`Unknown agent "${id}"`);
    await this.db.query(
      "UPDATE rg_agents SET project_id = $2, subproject_id = $3, parent_id = $4 WHERE id = $1",
      [id, to.projectId, to.subprojectId, to.parentId],
    );
    const { subprojectId: _s, ...rest } = a;
    const moved: AgentRecord = {
      ...rest,
      projectId: to.projectId,
      parentId: to.parentId,
      ...(to.subprojectId && { subprojectId: to.subprojectId }),
    };
    this.cache.set(id, this.mark(moved));
    this.changed(a.ownerId);
    return moved;
  }

  /** Renames an agent (the setup wizard names God and Demi-God). */
  async rename(id: string, name: string): Promise<AgentRecord> {
    const a = this.cache.get(id);
    if (!a) throw new HierarchyError(`Unknown agent "${id}"`);
    await this.db.query("UPDATE rg_agents SET name = $2 WHERE id = $1", [id, name]);
    const updated = { ...a, name };
    this.cache.set(id, this.mark(updated));
    this.changed(a.ownerId);
    return updated;
  }

  /** Effective model of an agent: its own fields, the missing ones inherited up the tree (RD13). */
  effectiveModel(id: string): ModelSpec | undefined {
    const chain: AgentRecord[] = [];
    let cur = this.cache.get(id);
    while (cur) {
      chain.push(cur);
      cur = cur.parentId ? this.cache.get(cur.parentId) : undefined;
    }
    let merged: Partial<ModelSpec> = {};
    for (const a of chain.reverse()) if (a.model) merged = { ...merged, ...a.model };
    return merged.provider && merged.model ? (merged as ModelSpec) : undefined;
  }
}

/** How deep an agent sits in the tree (God is 0). */
function depth(registry: AgentRegistry, a: AgentRecord): number {
  let n = 0;
  let cur = a.parentId ? registry.get(a.parentId) : undefined;
  while (cur && n < 50) {
    n++;
    cur = cur.parentId ? registry.get(cur.parentId) : undefined;
  }
  return n;
}

export { LOCAL_OWNER_ID };

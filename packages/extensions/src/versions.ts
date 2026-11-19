// Skills that improve with use (3.9.7): every installed skill keeps the history of its versions,
// who wrote each one, why and when, and the person can go back to any of them. The history only
// goes forward: going back writes a new version equal to the old one, nothing is deleted.

import { lstat, mkdir, readdir, readFile, rm, stat, writeFile } from "node:fs/promises";
import { dirname, join } from "node:path";
import type { EventStore, SqlClient } from "@redgiant/events";

export type SkillVersionHow = "baseline" | "edited" | "install" | "update" | "import" | "rollback";

export interface SkillVersion {
  name: string;
  /** "platform" or "project:<id>", as /api/extensions/installed lists it. */
  scope: string;
  version: number;
  how: SkillVersionHow;
  /** Who wrote it: an agent's id, "human", or null when nobody knows (before the history). */
  author: string | null;
  /** Who let it in: "human", "auto" (the person's policy), or null (the person wrote it). */
  approvedBy: string | null;
  /** Why: the proposal's summary, or what the person wrote. */
  reason: string | null;
  /** The version a rollback went back to. */
  fromVersion: number | null;
  proposalId: string | null;
  createdAt: string;
  /** The names of its files besides SKILL.md. */
  files: string[];
  /** False when its files were too large to keep (it is listed, but cannot come back). */
  restorable: boolean;
  /** The newest version: the one agents get from their next conversation. */
  current: boolean;
}

/** Above this a version is listed but its files are not kept. */
export const VERSION_MAX_BYTES = 4 * 1024 * 1024;

export async function migrateSkillVersions(db: SqlClient): Promise<void> {
  await db.query(`
    CREATE TABLE IF NOT EXISTS rg_skill_versions (
      owner_id     text NOT NULL,
      scope        text NOT NULL,
      name         text NOT NULL,
      version      integer NOT NULL,
      how          text NOT NULL,
      skill_md     text NOT NULL,
      files        jsonb,
      author       text,
      approved_by  text,
      reason       text,
      from_version integer,
      proposal_id  text,
      created_at   timestamptz NOT NULL DEFAULT now(),
      PRIMARY KEY (owner_id, scope, name, version)
    )`);
}

/** A skill's folder as `path → base64`, or null when it is too large to keep. */
export async function snapshotSkill(dir: string): Promise<Record<string, string> | null> {
  const out: Record<string, string> = {};
  let bytes = 0;
  const walk = async (rel: string): Promise<boolean> => {
    for (const e of await readdir(join(dir, rel), { withFileTypes: true }).catch(() => [])) {
      const path = rel ? `${rel}/${e.name}` : e.name;
      if (e.isSymbolicLink()) continue;
      if (e.isDirectory()) {
        if (!(await walk(path))) return false;
        continue;
      }
      if (!e.isFile()) continue;
      const data = await readFile(join(dir, path));
      bytes += data.length;
      if (bytes > VERSION_MAX_BYTES) return false;
      out[path] = data.toString("base64");
    }
    return true;
  };
  if (!(await walk(""))) return null;
  return Object.fromEntries(Object.entries(out).sort(([a], [b]) => a.localeCompare(b)));
}

/** Same files, whatever order the database gives the keys back in (jsonb sorts them its way). */
const canonical = (f: Record<string, string>) =>
  JSON.stringify(Object.entries(f).sort(([x], [y]) => (x < y ? -1 : x > y ? 1 : 0)));
const same = (a: Record<string, string> | null, b: Record<string, string> | null) =>
  a !== null && b !== null && canonical(a) === canonical(b);

interface Row {
  owner_id: string;
  scope: string;
  name: string;
  version: number;
  how: SkillVersionHow;
  skill_md: string;
  files: unknown;
  author: string | null;
  approved_by: string | null;
  reason: string | null;
  from_version: number | null;
  proposal_id: string | null;
  created_at: Date | string;
}

const filesOf = (v: unknown): Record<string, string> | null =>
  v == null
    ? null
    : typeof v === "string"
      ? (JSON.parse(v) as Record<string, string>)
      : (v as Record<string, string>);

export class SkillVersions {
  constructor(
    private readonly o: {
      db: SqlClient;
      store: EventStore;
      /** Where a scope's skills live (`<root>/skills/<name>`). */
      root: (ownerId: string, scope: string) => Promise<string>;
    },
  ) {}

  private async dir(ownerId: string, scope: string, name: string) {
    return join(await this.o.root(ownerId, scope), "skills", name);
  }

  private async rows(ownerId: string, scope: string, name: string): Promise<Row[]> {
    return this.o.db.query<Row>(
      "SELECT * FROM rg_skill_versions WHERE owner_id = $1 AND scope = $2 AND name = $3 ORDER BY version DESC",
      [ownerId, scope, name],
    );
  }

  /**
   * Before a skill changes: what is on disk becomes a version if the history does not have it
   * yet (the state before the history began, or a change made by hand since).
   */
  async keepCurrent(ownerId: string, scope: string, name: string): Promise<void> {
    const dir = await this.dir(ownerId, scope, name);
    const md = await stat(join(dir, "SKILL.md")).catch(() => undefined);
    if (!md) return;
    const files = await snapshotSkill(dir);
    const [last] = await this.rows(ownerId, scope, name);
    if (last && same(filesOf(last.files), files)) return;
    await this.insert(ownerId, scope, name, dir, files, {
      how: last ? "edited" : "baseline",
      author: null,
      approvedBy: null,
      reason: null,
      // Before the history began: the file's own date is the best "when" there is.
      ...(!last && { at: md.mtime }),
    });
  }

  /** The skill as it is now on disk becomes its newest version. */
  async record(
    ownerId: string,
    scope: string,
    name: string,
    meta: {
      how: Exclude<SkillVersionHow, "baseline" | "edited">;
      author: string | null;
      approvedBy: string | null;
      reason: string | null;
      fromVersion?: number;
      proposalId?: string;
    },
  ): Promise<number> {
    const dir = await this.dir(ownerId, scope, name);
    return this.insert(ownerId, scope, name, dir, await snapshotSkill(dir), meta);
  }

  private async insert(
    ownerId: string,
    scope: string,
    name: string,
    dir: string,
    files: Record<string, string> | null,
    meta: {
      how: SkillVersionHow;
      author: string | null;
      approvedBy: string | null;
      reason: string | null;
      fromVersion?: number;
      proposalId?: string;
      at?: Date;
    },
  ): Promise<number> {
    const skillMd = await readFile(join(dir, "SKILL.md"), "utf8").catch(() => "");
    const [{ next } = { next: 1 }] = await this.o.db.query<{ next: number }>(
      "SELECT COALESCE(MAX(version), 0) + 1 AS next FROM rg_skill_versions WHERE owner_id = $1 AND scope = $2 AND name = $3",
      [ownerId, scope, name],
    );
    const version = Number(next);
    await this.o.db.query(
      `INSERT INTO rg_skill_versions (owner_id, scope, name, version, how, skill_md, files, author, approved_by, reason, from_version, proposal_id, created_at)
       VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11, $12, $13)`,
      [
        ownerId,
        scope,
        name,
        version,
        meta.how,
        skillMd,
        files ? JSON.stringify(files) : null,
        meta.author,
        meta.approvedBy,
        meta.reason,
        meta.fromVersion ?? null,
        meta.proposalId ?? null,
        (meta.at ?? new Date()).toISOString(),
      ],
    );
    await this.o.store.append({
      ownerId,
      projectId: scope.startsWith("project:") ? scope.slice("project:".length) : null,
      body: {
        type: "extension.versioned",
        payload: {
          kind: "skill",
          name,
          scope,
          version,
          how: meta.how,
          author: meta.author,
          ...(meta.fromVersion !== undefined && { fromVersion: meta.fromVersion }),
        },
      },
    });
    return version;
  }

  /** Newest first. */
  async list(ownerId: string, scope: string, name: string): Promise<SkillVersion[]> {
    const rows = await this.rows(ownerId, scope, name);
    return rows.map((r, i) => {
      const files = filesOf(r.files);
      return {
        name: r.name,
        scope: r.scope,
        version: Number(r.version),
        how: r.how,
        author: r.author,
        approvedBy: r.approved_by,
        reason: r.reason,
        fromVersion: r.from_version === null ? null : Number(r.from_version),
        proposalId: r.proposal_id,
        createdAt: new Date(r.created_at).toISOString(),
        files: files ? Object.keys(files).filter((f) => f !== "SKILL.md") : [],
        restorable: files !== null,
        current: i === 0,
      };
    });
  }

  /** One version's SKILL.md (for the comparison). */
  async skillMd(ownerId: string, scope: string, name: string, version: number) {
    const [r] = await this.o.db.query<{ skill_md: string }>(
      "SELECT skill_md FROM rg_skill_versions WHERE owner_id = $1 AND scope = $2 AND name = $3 AND version = $4",
      [ownerId, scope, name, version],
    );
    return r?.skill_md;
  }

  /** The author of the newest version, and how it came (for the policy, 3.9.7). */
  async latest(
    ownerId: string,
    scope: string,
    name: string,
  ): Promise<{ how: SkillVersionHow; author: string | null } | undefined> {
    const [r] = await this.rows(ownerId, scope, name);
    return r ? { how: r.how, author: r.author } : undefined;
  }

  /**
   * «Go back to version N»: its files replace the skill's, as a new version. Only the person
   * (the API refuses anything else).
   */
  async rollback(
    ownerId: string,
    scope: string,
    name: string,
    version: number,
    by: string,
  ): Promise<number> {
    const [r] = await this.o.db.query<Row>(
      "SELECT * FROM rg_skill_versions WHERE owner_id = $1 AND scope = $2 AND name = $3 AND version = $4",
      [ownerId, scope, name, version],
    );
    if (!r) throw new SkillVersionError(`The skill "${name}" has no version ${version}`);
    const files = filesOf(r.files);
    if (!files)
      throw new SkillVersionError(`Version ${version} of "${name}" was too large to keep`);
    await this.keepCurrent(ownerId, scope, name);
    const dir = await this.dir(ownerId, scope, name);
    // Never through a link: the folder is ours, written afresh.
    if ((await lstat(dir).catch(() => undefined))?.isSymbolicLink())
      throw new SkillVersionError(`The skill "${name}" is a link: it cannot go back here`);
    await rm(dir, { recursive: true, force: true });
    await mkdir(dir, { recursive: true });
    for (const [path, data] of Object.entries(files)) {
      if (path.split("/").some((p) => p === ".." || p === "")) continue;
      await mkdir(dirname(join(dir, path)), { recursive: true });
      await writeFile(join(dir, path), Buffer.from(data, "base64"));
    }
    return this.record(ownerId, scope, name, {
      how: "rollback",
      author: by,
      approvedBy: null,
      reason: null,
      fromVersion: version,
    });
  }
}

export class SkillVersionError extends Error {}

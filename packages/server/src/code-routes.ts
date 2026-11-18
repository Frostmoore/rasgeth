// The advanced interface's routes (G40.11): what the app's «Projects» reads and does in a project's
// repository, with the page's rules. Reading works on archived projects too; every change goes
// through `assertWritable` (an archived project is read only), a push is a request to the person
// (danger `git-push`, asked like an agent's and answered from «For you»), and git always runs
// without a shell (`runGit`, arguments checked).
//
//   GET  /api/projects/:id/git            → branch, upstream, ahead/behind, the changed files
//   GET  /api/projects/:id/git/log        → the latest commits (?limit=, ?all=1 for every branch),
//                                           each with its parents (the app's graph, G40.17)
//   GET  /api/projects/:id/git/branches   → the branches with their upstream and ahead/behind
//   GET  /api/projects/:id/git/diff       → a unified patch: the working tree, ?commit=, ?task=
//                                           or ?agent= (the agent's worktree against its base)
//   POST /api/projects/:id/git/hunk       → keep (stage) or discard one hunk; a discarded hunk is
//                                           kept in `.trash/diffs/` first, to put back by hand
//   POST /api/projects/:id/git/commit     → everything in the working tree, with a message
//   POST /api/projects/:id/git/push       → a job: the person's yes («For you»), then the push
//   GET  /api/projects/:id/events         → the project's log, newest first, filtered
//   GET  /api/files/search                → names and lines matching a text, in a scope

import { randomUUID } from "node:crypto";
import { mkdir, mkdtemp, readdir, readFile, rm, stat, writeFile } from "node:fs/promises";
import { tmpdir } from "node:os";
import { join, relative, sep } from "node:path";
import { type ApprovalRequest, allows } from "@redgiant/hierarchy";
import { PRODUCT_NAME } from "@redgiant/protocol";
import { worktreeDir } from "@redgiant/sandbox";
import type { Context, Hono } from "hono";
import { z } from "zod";
import { BadRequestError, NotFoundError, type RedGiantCore } from "./core.js";
import { parseScope, TRASH } from "./files.js";
import { JobFailure } from "./jobs.js";
import { hasOwnRepo, type RunGit, runGit, safeDirectoryPath } from "./project-git.js";

/** At most this much of a patch goes to the app (a phone reads one file at a time). */
export const MAX_PATCH_CHARS = 400_000;

export interface GitChange {
  path: string;
  /** M modified, A added, D deleted, R renamed, ? untracked, U in conflict. */
  status: "M" | "A" | "D" | "R" | "?" | "U";
  staged: boolean;
}

export interface GitStatus {
  repo: boolean;
  branch: string | null;
  upstream: string | null;
  ahead: number;
  behind: number;
  changes: GitChange[];
}

/** `git status --porcelain=v2 --branch` in words the app shows. */
export function parseStatus(out: string): Omit<GitStatus, "repo"> {
  let branch: string | null = null;
  let upstream: string | null = null;
  let ahead = 0;
  let behind = 0;
  const changes: GitChange[] = [];
  const kind = (xy: string): GitChange["status"] => {
    const c = xy[0] !== "." ? xy[0] : xy[1];
    return c === "A" || c === "D" || c === "R" ? c : c === "C" ? "A" : "M";
  };
  for (const line of out.split("\n")) {
    if (line.startsWith("# branch.head ")) {
      const b = line.slice(14).trim();
      branch = b === "(detached)" ? null : b;
    } else if (line.startsWith("# branch.upstream ")) upstream = line.slice(18).trim();
    else if (line.startsWith("# branch.ab ")) {
      const m = line.match(/\+(\d+) -(\d+)/);
      ahead = Number(m?.[1] ?? 0);
      behind = Number(m?.[2] ?? 0);
    } else if (line.startsWith("1 ")) {
      const f = line.split(" ");
      changes.push({
        path: f.slice(8).join(" "),
        status: kind(f[1] ?? ".M"),
        staged: f[1]?.[0] !== ".",
      });
    } else if (line.startsWith("2 ")) {
      const f = line.split(" ");
      const [path = ""] = f.slice(9).join(" ").split("\t");
      changes.push({ path, status: "R", staged: f[1]?.[0] !== "." });
    } else if (line.startsWith("u ")) {
      changes.push({ path: line.split(" ").slice(10).join(" "), status: "U", staged: false });
    } else if (line.startsWith("? ")) {
      changes.push({ path: line.slice(2), status: "?", staged: false });
    }
  }
  return { branch, upstream, ahead, behind, changes };
}

/** `[ahead 2, behind 1]` (for-each-ref's upstream:track). */
export function parseTrack(track: string): { ahead: number; behind: number } {
  return {
    ahead: Number(track.match(/ahead (\d+)/)?.[1] ?? 0),
    behind: Number(track.match(/behind (\d+)/)?.[1] ?? 0),
  };
}

/**
 * Whether an event says something went wrong (the Log's «Errors only»): a tool that failed, an
 * error, a refusal, an agent blocked or a turn that ended badly.
 */
export function isErrorEvent(e: { type: string; payload: unknown }): boolean {
  if (/error|fail|denied|blocked|abandon/i.test(e.type)) return true;
  const p = e.payload as Record<string, unknown> | null;
  if (!p || typeof p !== "object") return false;
  if (e.type === "tool.result" && p.ok === false) return true;
  if (e.type === "task.verified" && p.passed === false) return true;
  if (e.type === "task.closed" && p.outcome === "abandoned") return true;
  if (e.type === "approval.resolved" && p.decision === "deny") return true;
  return typeof p.stopReason === "string" && /error|refus/i.test(p.stopReason);
}

/** One file's patch out of a whole one, checked: a single `diff --git` with at least one hunk. */
export function checkHunkPatch(patch: string): void {
  const headers = patch.match(/^diff --git /gm)?.length ?? 0;
  if (!patch.startsWith("diff --git ") || headers !== 1 || !/^@@ /m.test(patch))
    throw new BadRequestError("A patch of one file with its hunk is needed");
  if (patch.length > 1_000_000) throw new BadRequestError("The patch is too long");
}

const Hunk = z.object({
  patch: z.string().min(1),
  action: z.enum(["keep", "discard"]),
  agent: z.string().min(1).max(200).optional(),
});
const Commit = z.object({
  message: z.string().trim().min(1).max(2000),
  agent: z.string().min(1).max(200).optional(),
});
const Push = z.object({ agent: z.string().min(1).max(200).optional() });
const SKIP = new Set([".git", "node_modules", ".worktrees", TRASH, ".redgiant"]);

// biome-ignore lint/suspicious/noExplicitAny: the app's own Env, kept private in app.ts
export function codeRoutes<E extends { Variables: any }>(
  app: Hono<E>,
  core: RedGiantCore,
  owner: (c: Context<E>) => string,
  run: RunGit = runGit,
): void {
  const project = async (ownerId: string, id: string) => {
    const p = await core.projects.get(ownerId, id);
    if (!p) throw new NotFoundError(`Project "${id}" not found`);
    return p;
  };
  /** git in [dir], trusted as a safe directory (the server's user may not own the folder). */
  const git = async (dir: string, args: string[], ok: number[] = [0]) => {
    const r = await run(["-c", `safe.directory=${safeDirectoryPath(dir)}`, ...args], dir);
    if (!ok.includes(r.code))
      throw new BadRequestError(`git ${args[0]}: ${(r.stderr || r.stdout).trim().slice(0, 500)}`);
    return r;
  };
  /** The project's folder, or the agent's worktree in it when it has one. */
  const where = async (ownerId: string, projectId: string, agentId?: string) => {
    const p = await project(ownerId, projectId);
    if (!(await hasOwnRepo(p.path))) throw new BadRequestError("The project has no git repository");
    if (!agentId) return { p, dir: p.path, agent: null };
    const a = core.registry.get(agentId);
    if (!a || a.ownerId !== ownerId || a.projectId !== projectId)
      throw new NotFoundError(`Agent "${agentId}" not found in this project`);
    const wt = join(p.path, worktreeDir(a.id));
    const has = await stat(join(wt, ".git")).then(
      () => true,
      () => false,
    );
    return { p, dir: has ? wt : p.path, agent: a };
  };
  const head = async (dir: string) =>
    (await git(dir, ["rev-parse", "--verify", "-q", "HEAD"], [0, 1])).code === 0;

  app.get("/api/projects/:id/git", async (c) => {
    const p = await project(owner(c), c.req.param("id"));
    if (!(await hasOwnRepo(p.path)))
      return c.json({
        repo: false,
        branch: null,
        upstream: null,
        ahead: 0,
        behind: 0,
        changes: [],
      });
    const r = await git(p.path, ["status", "--porcelain=v2", "--branch", "--untracked-files=all"]);
    return c.json({ repo: true, ...parseStatus(r.stdout) } satisfies GitStatus, 200);
  });

  app.get("/api/projects/:id/git/log", async (c) => {
    const { dir } = await where(owner(c), c.req.param("id"), c.req.query("agent"));
    if (!(await head(dir))) return c.json([], 200);
    const limit = Math.min(200, Math.max(1, Number(c.req.query("limit") ?? 30) || 30));
    const all = c.req.query("all") === "1";
    const r = await git(dir, [
      "log",
      `-n${limit}`,
      ...(all ? ["--all", "--date-order"] : []),
      "--format=%H%x1f%h%x1f%an%x1f%aI%x1f%D%x1f%s%x1f%P%x1e",
    ]);
    return c.json(
      r.stdout
        .split("\x1e")
        .map((x) => x.trim())
        .filter(Boolean)
        .map((x) => {
          const [hash = "", short = "", author = "", date = "", refs = "", subject = "", p = ""] =
            x.split("\x1f");
          const parents = p.split(" ").filter(Boolean);
          return { hash, short, author, date, refs, subject, parents };
        }),
      200,
    );
  });

  app.get("/api/projects/:id/git/branches", async (c) => {
    const { dir } = await where(owner(c), c.req.param("id"));
    const r = await git(dir, [
      "for-each-ref",
      "refs/heads",
      "--format=%(refname:short)%1f%(upstream:short)%1f%(upstream:track)%1f%(committerdate:iso-strict)%1f%(subject)%1f%(HEAD)",
    ]);
    return c.json(
      r.stdout
        .split("\n")
        .filter(Boolean)
        .map((x) => {
          const [name = "", upstream = "", track = "", date = "", subject = "", star = ""] =
            x.split("\x1f");
          return {
            name,
            current: star === "*",
            upstream: upstream || null,
            ...parseTrack(track),
            date,
            subject,
          };
        }),
      200,
    );
  });

  app.get("/api/projects/:id/git/diff", async (c) => {
    const ownerId = owner(c);
    const projectId = c.req.param("id");
    const commit = c.req.query("commit");
    const task = c.req.query("task");
    let agentId = c.req.query("agent");
    let title = "";
    if (task) {
      const opened = (await core.store.list({ projectId, types: ["task.opened"] })).find(
        (e) => e.ownerId === ownerId && e.type === "task.opened" && e.payload?.taskId === task,
      );
      if (!opened || opened.type !== "task.opened" || !opened.payload)
        throw new NotFoundError(`Task "${task}" not found`);
      title = opened.payload.title;
      agentId = opened.agentId ?? undefined;
    }
    const { dir, p } = await where(ownerId, projectId, agentId);
    let patch: string;
    let kind: "commit" | "agent" | "working";
    if (commit) {
      if (!/^[0-9a-f]{4,40}$/i.test(commit)) throw new BadRequestError("Not a commit");
      kind = "commit";
      title = (await git(dir, ["log", "-1", "--format=%s", commit])).stdout.trim();
      patch = (
        await git(dir, [
          "show",
          "--format=",
          "--patch",
          "--no-color",
          "--no-ext-diff",
          "-M",
          commit,
        ])
      ).stdout;
    } else {
      kind = dir === p.path ? "working" : "agent";
      // The agent's branch against where it left the project's, uncommitted changes included.
      let base = "HEAD";
      if (kind === "agent") {
        const main = (await git(p.path, ["rev-parse", "HEAD"], [0, 128])).stdout.trim();
        if (main)
          base = (await git(dir, ["merge-base", "HEAD", main], [0, 1])).stdout.trim() || "HEAD";
      }
      patch = (await head(dir))
        ? (await git(dir, ["diff", "--no-color", "--no-ext-diff", "-M", base])).stdout
        : "";
      // New files too: git shows nothing for them until they are added.
      const untracked = (await git(dir, ["ls-files", "--others", "--exclude-standard"])).stdout
        .split("\n")
        .filter(Boolean)
        .slice(0, 60);
      for (const f of untracked) {
        if (patch.length > MAX_PATCH_CHARS) break;
        const r = await git(
          dir,
          ["diff", "--no-color", "--no-ext-diff", "--no-index", "--", "/dev/null", f],
          [0, 1],
        );
        patch += r.stdout;
      }
    }
    const truncated = patch.length > MAX_PATCH_CHARS;
    return c.json(
      {
        kind,
        title,
        agentId: agentId ?? null,
        patch: truncated ? patch.slice(0, MAX_PATCH_CHARS) : patch,
        truncated,
      },
      200,
    );
  });

  app.post("/api/projects/:id/git/hunk", async (c) => {
    const ownerId = owner(c);
    const projectId = c.req.param("id");
    const b = Hunk.safeParse(await c.req.json().catch(() => null));
    if (!b.success) return c.json({ error: "Say the patch and keep or discard" }, 400);
    core.assertWritable(ownerId, `project:${projectId}`);
    checkHunkPatch(b.data.patch);
    const { dir, p } = await where(ownerId, projectId, b.data.agent);
    const tmp = await mkdtemp(join(tmpdir(), "rg-hunk-"));
    const file = join(tmp, "hunk.patch");
    let backup: string | null = null;
    try {
      await writeFile(file, b.data.patch);
      const args =
        b.data.action === "keep"
          ? ["apply", "--cached", "--recount", "--whitespace=nowarn"]
          : ["apply", "-R", "--recount", "--whitespace=nowarn"];
      await git(dir, [...args, "--check", file]);
      if (b.data.action === "discard") {
        // Kept first: a discarded change can be put back (git apply) from the trash.
        const keep = join(p.path, TRASH, "diffs");
        await mkdir(keep, { recursive: true });
        const name = `${new Date().toISOString().replace(/[:.]/g, "-")}-${randomUUID().slice(0, 6)}.patch`;
        await writeFile(join(keep, name), b.data.patch);
        backup = `${TRASH}/diffs/${name}`;
      }
      await git(dir, [...args, file]);
    } finally {
      await rm(tmp, { recursive: true, force: true });
    }
    const path =
      b.data.patch.match(/^\+\+\+ b\/(.+)$/m)?.[1] ?? b.data.patch.match(/^--- a\/(.+)$/m)?.[1];
    if (b.data.action === "discard" && path)
      await core.store.append({
        ownerId,
        projectId,
        body: {
          type: "workspace.changed",
          payload: {
            scope: `project:${projectId}`,
            action: "write",
            path: relative(p.path, join(dir, path)).split(sep).join("/"),
            by: "human",
          },
        },
      });
    return c.json({ ok: true, backup }, 200);
  });

  app.post("/api/projects/:id/git/commit", async (c) => {
    const ownerId = owner(c);
    const projectId = c.req.param("id");
    const b = Commit.safeParse(await c.req.json().catch(() => null));
    if (!b.success) return c.json({ error: "A message is needed" }, 400);
    core.assertWritable(ownerId, `project:${projectId}`);
    const { dir } = await where(ownerId, projectId, b.data.agent);
    await git(dir, ["add", "-A"]);
    if ((await git(dir, ["diff", "--cached", "--quiet"], [0, 1])).code === 0)
      return c.json({ error: "Nothing to commit", code: "nothing" }, 400);
    const named = (await git(dir, ["config", "user.name"], [0, 1])).stdout.trim();
    const identity = named
      ? []
      : ["-c", `user.name=${PRODUCT_NAME}`, "-c", "user.email=rasgeth@localhost"];
    await git(dir, [...identity, "commit", "-q", "-m", b.data.message]);
    const short = (await git(dir, ["rev-parse", "--short", "HEAD"])).stdout.trim();
    return c.json({ commit: short }, 200);
  });

  app.post("/api/projects/:id/git/push", async (c) => {
    const ownerId = owner(c);
    const projectId = c.req.param("id");
    const b = Push.safeParse(await c.req.json().catch(() => ({})));
    if (!b.success) return c.json({ error: "Bad request" }, 400);
    core.assertWritable(ownerId, `project:${projectId}`);
    const { dir, p } = await where(ownerId, projectId, b.data.agent);
    const branch = (await git(dir, ["rev-parse", "--abbrev-ref", "HEAD"])).stdout.trim();
    if (!branch || branch === "HEAD") return c.json({ error: "Not on a branch" }, 400);
    const remotes = (await git(dir, ["remote"])).stdout.split("\n").filter(Boolean);
    if (remotes.length === 0)
      return c.json({ error: "The project has no remote repository", code: "no_remote" }, 400);
    const remote = remotes.includes("origin") ? "origin" : (remotes[0] as string);
    // Who asks: the project's orchestrator, or God (the request names the person's action).
    const agents = core.registry.list({ ownerId, activeOnly: true });
    const requester =
      agents.find((a) => a.projectId === projectId && a.kind === "orchestrator") ??
      agents.find((a) => a.kind === "god");
    if (!requester) return c.json({ error: "No agent can carry the request" }, 400);
    const sub = relative(p.path, dir).split(sep).join("/");
    const job = core.jobs.start(
      ownerId,
      "git_push",
      ["ask", "push"],
      async (h) => {
        h.step("ask");
        const id = `push_${randomUUID().slice(0, 12)}`;
        const command = `git push ${remote} HEAD:${branch}`;
        const request: ApprovalRequest = {
          requestId: id,
          requester,
          call: {
            callId: id,
            name: "bash",
            input: { command, project: p.name, branch, from: `${PRODUCT_NAME} app` },
          },
          reasons: [`Sends the branch ${branch} of ${p.name} to ${remote} (asked from the app)`],
          danger: ["git-push"],
        };
        const answer = await core.person.approve(request, h.signal, {
          kind: "approval",
          critical: false,
          what: `git push of ${branch} (${p.name})`,
          defaultTimeoutMs: 30 * 60_000,
        });
        if (!allows(answer)) throw new JobFailure("denied", "Not pushed: the answer was no");
        h.step("push");
        // In the project's sandbox, like an agent's push: credentials stay on the egress routes.
        const ws = await core.scopeWorkspace(ownerId, `project:${projectId}`);
        const args = [...(sub ? ["-C", sub] : []), "push", remote, `HEAD:${branch}`];
        const r = await ws.execFile("git", args, { timeoutMs: 120_000 });
        if (r.exitCode !== 0)
          throw new JobFailure("push_failed", (r.stderr || r.stdout).trim().slice(0, 500));
        return { branch, remote };
      },
      { project: p.name, branch },
    );
    return c.json(job, 202);
  });

  app.get("/api/projects/:id/events", async (c) => {
    const ownerId = owner(c);
    const projectId = c.req.param("id");
    await project(ownerId, projectId);
    const agent = c.req.query("agent");
    const type = c.req.query("type");
    const errors = c.req.query("errors") === "1";
    const before = Number(c.req.query("before") ?? 0) || 0;
    const limit = Math.min(500, Math.max(1, Number(c.req.query("limit") ?? 150) || 150));
    const all = (await core.store.list({ projectId })).filter((e) => e.ownerId === ownerId);
    const types = [...new Set(all.map((e) => e.type))].sort();
    const agentIds = [...new Set(all.map((e) => e.agentId).filter((x): x is string => !!x))];
    const out = [];
    for (let i = all.length - 1; i >= 0 && out.length < limit; i--) {
      const e = all[i];
      if (!e || (before && e.seq >= before)) continue;
      if (agent && e.agentId !== agent) continue;
      if (type && e.type !== type) continue;
      if (errors && !isErrorEvent(e)) continue;
      out.push({
        seq: e.seq,
        ts: e.ts,
        type: e.type,
        agentId: e.agentId,
        agentName: e.agentId ? (core.registry.get(e.agentId)?.name ?? null) : null,
        sessionId: e.sessionId,
        error: isErrorEvent(e),
        payload: e.payload,
      });
    }
    return c.json(
      {
        events: out,
        types,
        agents: agentIds.map((id) => ({ id, name: core.registry.get(id)?.name ?? id })),
      },
      200,
    );
  });

  app.get("/api/files/search", async (c) => {
    const ownerId = owner(c);
    const scope = parseScope(c.req.query("scope") ?? "");
    const q = (c.req.query("q") ?? "").trim().toLowerCase();
    if (q.length < 2) return c.json([], 200);
    const root =
      scope.kind === "project"
        ? (await project(ownerId, scope.projectId)).path
        : scope.kind === "platform"
          ? core.platformPath(ownerId)
          : core.assistantsPath(ownerId);
    return c.json(await searchFiles(root, q), 200);
  });
}

/** Names and lines with [q] (lower case), at most 100 hits over at most 5000 files. */
export async function searchFiles(
  root: string,
  q: string,
): Promise<{ path: string; line: number | null; text: string | null }[]> {
  const hits: { path: string; line: number | null; text: string | null }[] = [];
  let seen = 0;
  const walk = async (dir: string): Promise<void> => {
    const entries = await readdir(dir, { withFileTypes: true }).catch(() => []);
    entries.sort((a, b) => a.name.localeCompare(b.name));
    for (const d of entries) {
      if (hits.length >= 100 || seen >= 5000) return;
      if (SKIP.has(d.name)) continue;
      const full = join(dir, d.name);
      const rel = relative(root, full).split(sep).join("/");
      if (d.isDirectory()) {
        await walk(full);
        continue;
      }
      if (!d.isFile()) continue;
      seen++;
      if (d.name.toLowerCase().includes(q)) hits.push({ path: rel, line: null, text: null });
      const st = await stat(full).catch(() => undefined);
      if (!st || st.size > 512 * 1024) continue;
      const bytes = await readFile(full).catch(() => undefined);
      if (!bytes || bytes.includes(0)) continue;
      const lines = bytes.toString("utf8").split(/\r?\n/);
      for (let i = 0; i < lines.length && hits.length < 100; i++) {
        const l = lines[i] as string;
        if (l.toLowerCase().includes(q))
          hits.push({ path: rel, line: i + 1, text: l.trim().slice(0, 200) });
      }
    }
  };
  await walk(root);
  return hits;
}

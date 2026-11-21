import type { Workspace } from "@redgiant/tools";

const TIMEOUT = { timeoutMs: 60_000 };
const IDENTITY = ["-c", "user.name=Rasgeth", "-c", "user.email=rasgeth@localhost"];

export const worktreeDir = (agentId: string) => `.worktrees/${safe(agentId)}`;
export const worktreeBranch = (agentId: string) => `rg/${safe(agentId)}`;

function safe(agentId: string): string {
  const s = agentId.toLowerCase().replace(/[^a-z0-9_-]/g, "-");
  if (!s) throw new Error("Empty agent id");
  return s;
}

/** Runs git without a shell: identical on Linux, macOS, Windows and in containers. */
const run = (ws: Workspace, args: string[]) => ws.execFile("git", args, TIMEOUT);

async function git(ws: Workspace, args: string[]): Promise<string> {
  const r = await run(ws, args);
  if (r.exitCode !== 0)
    throw new Error(
      `git ${args.find((a) => !a.startsWith("-"))} failed: ${(r.stderr || r.stdout).trim()}`,
    );
  return r.stdout.trim();
}

/** The identity of commits made where git has none: ours, never the person's email. */
export const DEFAULT_GIT_IDENTITY = { name: "Rasgeth", email: "rasgeth@localhost" } as const;

/**
 * A repository-level identity when git finds none (3.9.9, Coder: an orchestrator's `git commit`
 * failed with «Author identity unknown»). Read where the agents run their commands (this
 * workspace: the host or the container), so an identity the person set in their own git
 * configuration wins; only the repository's `.git/config` is ever written, never the global one.
 */
export async function ensureIdentity(ws: Workspace): Promise<void> {
  for (const [key, value] of [
    ["user.name", DEFAULT_GIT_IDENTITY.name],
    ["user.email", DEFAULT_GIT_IDENTITY.email],
  ] as const)
    if ((await run(ws, ["config", "--get", key])).exitCode !== 0)
      await git(ws, ["config", "--local", key, value]);
}

/** Makes sure the workspace is a git repository with at least one commit and an identity. */
export async function ensureRepo(ws: Workspace): Promise<void> {
  if ((await run(ws, ["rev-parse", "--is-inside-work-tree"])).exitCode !== 0) {
    await git(ws, ["init", "-q"]);
    // Files stay exactly as agents write them (Windows git converts line endings by default).
    // Only for repositories RedGiant creates: existing ones keep their own configuration.
    await git(ws, ["config", "core.autocrlf", "false"]);
  }
  await ensureIdentity(ws);
  const exclude = ".git/info/exclude";
  const current = (await ws.exists(exclude)) ? await ws.readText(exclude) : "";
  // Agents' worktrees and RedGiant's own files (custom tools' copies) never show up in git.
  const missing = [".worktrees/", ".redgiant/"].filter((x) => !current.split(/\r?\n/).includes(x));
  if (missing.length > 0) {
    await ws.writeText(
      exclude,
      `${current}${current && !current.endsWith("\n") ? "\n" : ""}${missing.join("\n")}\n`,
    );
  }
  if ((await run(ws, ["rev-parse", "--verify", "-q", "HEAD"])).exitCode !== 0) {
    await git(ws, ["add", "-A"]);
    await git(ws, [...IDENTITY, "commit", "-q", "--allow-empty", "-m", "Initial commit"]);
  }
}

/** Creates (or reuses) the agent's worktree on its own branch; returns its path. */
export async function createWorktree(
  ws: Workspace,
  agentId: string,
  base = "HEAD",
): Promise<string> {
  await ensureRepo(ws);
  const dir = worktreeDir(agentId);
  if (await ws.exists(`${dir}/.git`)) return dir;
  const branch = worktreeBranch(agentId);
  const exists =
    (await run(ws, ["rev-parse", "--verify", "-q", `refs/heads/${branch}`])).exitCode === 0;
  await git(
    ws,
    exists
      ? ["worktree", "add", "-q", dir, branch]
      : ["worktree", "add", "-q", "-b", branch, dir, base],
  );
  return dir;
}

/** Commits everything in a worktree (or workspace); returns false when there was nothing to commit. */
export async function commitAll(
  ws: Workspace,
  message: string,
  author = "Rasgeth <rasgeth@localhost>",
): Promise<boolean> {
  await git(ws, ["add", "-A"]);
  if ((await run(ws, ["diff", "--cached", "--quiet"])).exitCode === 0) return false;
  const [name = "Rasgeth", email = "rasgeth@localhost"] = author.replace(/>$/, "").split(" <");
  // The message is an argument, never shell text: an agent cannot inject commands through it.
  await git(ws, [
    "-c",
    `user.name=${name}`,
    "-c",
    `user.email=${email}`,
    "commit",
    "-q",
    "-m",
    message,
  ]);
  return true;
}

export type MergeResult = { ok: true; merged: boolean } | { ok: false; conflicts: string[] };

/**
 * Merges the agent's branch into the branch checked out in `ws`. On conflict the merge is
 * aborted (the workspace is left as it was) and the conflicting files are reported.
 */
export async function mergeWorktree(ws: Workspace, agentId: string): Promise<MergeResult> {
  const r = await run(ws, [...IDENTITY, "merge", "--no-ff", "--no-edit", worktreeBranch(agentId)]);
  if (r.exitCode === 0) return { ok: true, merged: !/Already up to date/i.test(r.stdout) };
  const conflicts = (await run(ws, ["diff", "--name-only", "--diff-filter=U"])).stdout
    .split(/\r?\n/)
    .filter(Boolean);
  await run(ws, ["merge", "--abort"]);
  if (conflicts.length === 0) throw new Error(`git merge failed: ${(r.stderr || r.stdout).trim()}`);
  return { ok: false, conflicts };
}

export async function removeWorktree(
  ws: Workspace,
  agentId: string,
  deleteBranch = false,
): Promise<void> {
  await git(ws, ["worktree", "remove", "--force", worktreeDir(agentId)]);
  if (deleteBranch) await git(ws, ["branch", "-D", worktreeBranch(agentId)]);
}

/** What `tidyWorktree` did with an agent's worktree and branch. */
export type TidyResult =
  | { state: "none" }
  | { state: "removed" }
  | { state: "kept"; branch: string; commits: string[]; changes: string[] };

/**
 * An agent's worktree and branch once it leaves the team (3.10.1, Coder: removed agents left
 * `rg/<agent>` and `.worktrees/<agent>` behind). Both go only when the branch has no commit the
 * branch checked out in `ws` lacks and the worktree has no uncommitted change (untracked files
 * count); otherwise both stay and the result says what is not merged. Nothing is ever lost here.
 */
export async function tidyWorktree(ws: Workspace, agentId: string): Promise<TidyResult> {
  const dir = worktreeDir(agentId);
  const branch = worktreeBranch(agentId);
  const hasBranch =
    (await run(ws, ["rev-parse", "--verify", "-q", `refs/heads/${branch}`])).exitCode === 0;
  const hasDir = await ws.exists(`${dir}/.git`);
  if (!hasBranch && !hasDir) return { state: "none" };
  const commits = hasBranch
    ? (await git(ws, ["log", "--format=%h %s", "-n", "20", `HEAD..refs/heads/${branch}`]))
        .split(/\r?\n/)
        .filter(Boolean)
    : [];
  const changes = hasDir
    ? (await git(ws, ["-C", dir, "status", "--porcelain", "--untracked-files=all"]))
        .split(/\r?\n/)
        .map((l) => l.trim())
        .filter(Boolean)
    : [];
  if (commits.length > 0 || changes.length > 0) return { state: "kept", branch, commits, changes };
  if (hasDir) await git(ws, ["worktree", "remove", "--force", dir]);
  await run(ws, ["worktree", "prune"]);
  if (hasBranch) await git(ws, ["branch", "-D", branch]);
  return { state: "removed" };
}

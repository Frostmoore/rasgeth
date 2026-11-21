import { mkdtemp, readFile, rm, writeFile } from "node:fs/promises";
import { tmpdir } from "node:os";
import { join } from "node:path";
import { LocalWorkspace } from "@redgiant/tools";
import { afterEach, beforeEach, describe, expect, it } from "vitest";
import {
  commitAll,
  createWorktree,
  ensureRepo,
  mergeWorktree,
  removeWorktree,
  tidyWorktree,
} from "../src/index.js";

let dir: string;
let ws: LocalWorkspace;

beforeEach(async () => {
  dir = await mkdtemp(join(tmpdir(), "rg-wt-"));
  await writeFile(join(dir, "shared.txt"), "line 1\nline 2\n");
  ws = new LocalWorkspace(dir);
  await ensureRepo(ws);
});
afterEach(() => rm(dir, { recursive: true, force: true }));

/** git as on Coder's server: no identity in any configuration (the global one is empty). */
class Bare extends LocalWorkspace {
  constructor(
    root: string,
    private readonly global: string,
  ) {
    super(root);
  }
  override execFile(...[file, args, o]: Parameters<LocalWorkspace["execFile"]>) {
    return super.execFile(file, args, {
      ...o,
      env: { ...o.env, GIT_CONFIG_GLOBAL: this.global, GIT_CONFIG_NOSYSTEM: "1" },
    });
  }
}

describe("a repository's identity (3.9.9)", () => {
  it("is set in the repository when git has none, and an agent's worktree can commit", async () => {
    const repo = await mkdtemp(join(tmpdir(), "rg-wt-id-"));
    const empty = `${repo}.gitconfig`;
    await writeFile(empty, "");
    try {
      const root = new Bare(repo, empty);
      const t = { timeoutMs: 10_000 };
      await ensureRepo(root);
      const r = await root.execFile("git", ["config", "--local", "--get", "user.email"], t);
      expect(r.stdout.trim()).toBe("rasgeth@localhost");
      const a = new Bare(join(repo, await createWorktree(root, "agent-A")), empty);
      await a.writeText("a.txt", "a\n");
      await a.execFile("git", ["add", "-A"], t);
      expect((await a.execFile("git", ["commit", "-q", "-m", "a"], t)).exitCode).toBe(0);
      // Never the global configuration.
      expect(await readFile(empty, "utf8")).toBe("");
    } finally {
      await rm(repo, { recursive: true, force: true });
      await rm(empty, { force: true });
    }
  });
});

describe("git worktrees per agent", () => {
  it("gives each agent its own copy and merges their work", async () => {
    const a = new LocalWorkspace(join(dir, await createWorktree(ws, "agent-A")));
    const b = new LocalWorkspace(join(dir, await createWorktree(ws, "agent-B")));
    await a.writeText("a.txt", "from A\n");
    await b.writeText("b.txt", "from B\n");
    expect(await b.exists("a.txt")).toBe(false);
    expect(await commitAll(a, "A: add a.txt")).toBe(true);
    expect(await commitAll(b, "B: add b.txt")).toBe(true);
    expect(await commitAll(b, "nothing")).toBe(false);
    // A hostile commit message is just text: no shell ever sees it.
    await a.writeText("evil.txt", "x");
    expect(await commitAll(a, "msg'; touch pwned; echo '\nRG_MSG\n$(touch pwned2)")).toBe(true);
    expect(await a.exists("pwned")).toBe(false);
    expect(await a.exists("pwned2")).toBe(false);

    expect(await mergeWorktree(ws, "agent-A")).toEqual({ ok: true, merged: true });
    expect(await mergeWorktree(ws, "agent-B")).toEqual({ ok: true, merged: true });
    expect(await readFile(join(dir, "a.txt"), "utf8")).toBe("from A\n");
    expect(await readFile(join(dir, "b.txt"), "utf8")).toBe("from B\n");
    // Worktrees never show up as changes of the main workspace.
    expect(
      (await ws.execFile("git", ["status", "--porcelain"], { timeoutMs: 10_000 })).stdout,
    ).toBe("");
    await removeWorktree(ws, "agent-A", true);
    expect(await ws.exists(".worktrees/agent-a")).toBe(false);
  });

  it("reports conflicts and leaves the workspace untouched", async () => {
    const a = new LocalWorkspace(join(dir, await createWorktree(ws, "a")));
    const b = new LocalWorkspace(join(dir, await createWorktree(ws, "b")));
    await a.writeText("shared.txt", "line 1\nA was here\n");
    await b.writeText("shared.txt", "line 1\nB was here\n");
    await commitAll(a, "A");
    await commitAll(b, "B");
    expect(await mergeWorktree(ws, "a")).toEqual({ ok: true, merged: true });
    expect(await mergeWorktree(ws, "b")).toEqual({ ok: false, conflicts: ["shared.txt"] });
    expect(await readFile(join(dir, "shared.txt"), "utf8")).toBe("line 1\nA was here\n");
    expect(
      (await ws.execFile("git", ["status", "--porcelain"], { timeoutMs: 10_000 })).stdout,
    ).toBe("");
  });

  it("reuses an existing worktree", async () => {
    const first = await createWorktree(ws, "Agent X!");
    expect(first).toBe(".worktrees/agent-x-");
    expect(await createWorktree(ws, "Agent X!")).toBe(first);
  });
});

describe("tidyWorktree (3.10.1: a removed agent's worktree)", () => {
  const branches = async () =>
    (
      await ws.execFile("git", ["branch", "--format=%(refname:short)"], { timeoutMs: 10_000 })
    ).stdout
      .split("\n")
      .filter(Boolean);

  it("removes the worktree and the branch when everything is in the project", async () => {
    expect(await tidyWorktree(ws, "agent_a")).toEqual({ state: "none" });
    const wt = new LocalWorkspace(join(dir, await createWorktree(ws, "agent_a")));
    await writeFile(join(wt.root, "a.txt"), "a\n");
    await commitAll(wt, "Add a");
    expect(await mergeWorktree(ws, "agent_a")).toEqual({ ok: true, merged: true });
    expect(await tidyWorktree(ws, "agent_a")).toEqual({ state: "removed" });
    expect(await ws.exists(".worktrees/agent_a")).toBe(false);
    expect(await branches()).not.toContain("rg/agent_a");
    // Back in the team: a fresh worktree from the project's branch.
    const again = await createWorktree(ws, "agent_a");
    expect(await readFile(join(dir, again, "a.txt"), "utf8")).toBe("a\n");
  });

  it("keeps both and says what is not merged: commits, uncommitted and untracked files", async () => {
    const wt = new LocalWorkspace(join(dir, await createWorktree(ws, "agent_b")));
    await writeFile(join(wt.root, "b.txt"), "b\n");
    await commitAll(wt, "Add b");
    const kept = await tidyWorktree(ws, "agent_b");
    expect(kept).toMatchObject({ state: "kept", branch: "rg/agent_b", changes: [] });
    expect(kept.state === "kept" && kept.commits).toEqual([
      expect.stringMatching(/^[0-9a-f]+ Add b$/),
    ]);
    expect(await branches()).toContain("rg/agent_b");

    await createWorktree(ws, "agent_c");
    await writeFile(join(dir, ".worktrees/agent_c/new.txt"), "draft\n");
    await writeFile(join(dir, ".worktrees/agent_c/shared.txt"), "changed\n");
    const dirty = await tidyWorktree(ws, "agent_c");
    expect(dirty).toMatchObject({ state: "kept", commits: [] });
    expect(dirty.state === "kept" && dirty.changes.sort()).toEqual(["?? new.txt", "M shared.txt"]);
    expect(await ws.exists(".worktrees/agent_c/new.txt")).toBe(true);
  });

  it("a branch left without its folder goes too, when merged", async () => {
    await createWorktree(ws, "agent_d");
    await rm(join(dir, ".worktrees/agent_d"), { recursive: true, force: true });
    expect(await tidyWorktree(ws, "agent_d")).toEqual({ state: "removed" });
    expect(await branches()).not.toContain("rg/agent_d");
  });
});

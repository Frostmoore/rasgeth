import { execFile } from "node:child_process";
import { mkdtemp, readFile, rm, writeFile } from "node:fs/promises";
import { tmpdir } from "node:os";
import { join } from "node:path";
import { promisify } from "node:util";
import type { Job } from "@redgiant/protocol";
import { afterEach, describe, expect, it } from "vitest";
import { checkHunkPatch, isErrorEvent, parseStatus, parseTrack } from "../src/code-routes.js";
import { startServer } from "./helpers.js";

// The advanced interface's routes (G40.11): git status, log, branches, diffs, hunks, commit,
// push as a request to the person, the project's log and the file search.

const exec = promisify(execFile);
const git = async (cwd: string, ...args: string[]) =>
  (await exec("git", args, { cwd })).stdout.trim();

type Server = Awaited<ReturnType<typeof startServer>>;
let s: Server | undefined;
const extra: string[] = [];
afterEach(async () => {
  await s?.close();
  s = undefined;
  for (const d of extra.splice(0))
    await rm(d, { recursive: true, force: true, maxRetries: 10, retryDelay: 200 });
});

describe("parsers", () => {
  it("reads git status v2 with branch, upstream, ahead/behind and every kind of change", () => {
    const out = [
      "# branch.oid 0123",
      "# branch.head main",
      "# branch.upstream origin/main",
      "# branch.ab +2 -1",
      "1 .M N... 100644 100644 100644 aaa bbb src/a b.ts",
      "1 A. N... 000000 100644 100644 000 ccc new.ts",
      "2 R. N... 100644 100644 100644 ddd eee R100 moved.ts\told.ts",
      "u UU N... 100644 100644 100644 100644 f g h conflict.ts",
      "? notes.txt",
    ].join("\n");
    expect(parseStatus(out)).toEqual({
      branch: "main",
      upstream: "origin/main",
      ahead: 2,
      behind: 1,
      changes: [
        { path: "src/a b.ts", status: "M", staged: false },
        { path: "new.ts", status: "A", staged: true },
        { path: "moved.ts", status: "R", staged: true },
        { path: "conflict.ts", status: "U", staged: false },
        { path: "notes.txt", status: "?", staged: false },
      ],
    });
    expect(parseStatus("# branch.head (detached)\n").branch).toBeNull();
  });

  it.each([
    ["[ahead 2, behind 1]", { ahead: 2, behind: 1 }],
    ["[behind 4]", { ahead: 0, behind: 4 }],
    ["", { ahead: 0, behind: 0 }],
  ])("track %s", (track, want) => expect(parseTrack(track)).toEqual(want));

  it.each([
    [{ type: "tool.result", payload: { callId: "c", ok: false, output: "x" } }, true],
    [{ type: "tool.result", payload: { callId: "c", ok: true, output: "x" } }, false],
    [{ type: "tool.call", payload: { tool: "bash" } }, false],
    [{ type: "task.verified", payload: { passed: false } }, true],
    [{ type: "task.closed", payload: { outcome: "abandoned" } }, true],
    [{ type: "agent.blocked", payload: {} }, true],
    [{ type: "message.assistant", payload: { stopReason: "error" } }, true],
    [{ type: "message.assistant", payload: { stopReason: "end_turn" } }, false],
  ])("isErrorEvent %j", (e, want) => expect(isErrorEvent(e)).toBe(want));

  it("accepts one file's hunk, nothing else", () => {
    const one = "diff --git a/x b/x\n--- a/x\n+++ b/x\n@@ -1 +1 @@\n-a\n+b\n";
    expect(() => checkHunkPatch(one)).not.toThrow();
    expect(() => checkHunkPatch(`${one}${one}`)).toThrow();
    expect(() => checkHunkPatch("--- a/x\n+++ b/x\n@@ -1 +1 @@\n")).toThrow();
    expect(() => checkHunkPatch("diff --git a/x b/x\n")).toThrow();
  });
});

describe("the routes", () => {
  const setUp = async () => {
    s = await startServer([]);
    const me = { type: "human" as const, ownerId: "me" };
    await s.core.registry.create(me, { kind: "god", parentId: null, name: "God" });
    const p = await s.core.projects.create("me", "Shop");
    await writeFile(join(p.path, "README.md"), "# Shop\n\nline 2\nline 3\n");
    await writeFile(join(p.path, "app.js"), "const a = 1;\nconsole.log(a);\n");
    await git(p.path, "add", "-A");
    await git(p.path, "-c", "user.name=T", "-c", "user.email=t@x", "commit", "-qm", "Files");
    return p;
  };

  it("status, log, branches and the working tree's diff, new files included", async () => {
    const p = await setUp();
    const server = s as Server;
    await writeFile(join(p.path, "README.md"), "# Shop\n\nline two\nline 3\n");
    await writeFile(join(p.path, "new.txt"), "hello\n");
    const st = await server.api<{ repo: boolean; branch: string; changes: unknown[] }>(
      "GET",
      "/api/projects/shop/git",
    );
    expect(st.body).toMatchObject({ repo: true, branch: "main", upstream: null, ahead: 0 });
    expect(st.body.changes).toEqual([
      { path: "README.md", status: "M", staged: false },
      { path: "new.txt", status: "?", staged: false },
    ]);
    const log = await server.api<{ subject: string; short: string }[]>(
      "GET",
      "/api/projects/shop/git/log",
    );
    expect(log.body.map((c) => c.subject)[0]).toBe("Files");
    const br = await server.api<{ name: string; current: boolean }[]>(
      "GET",
      "/api/projects/shop/git/branches",
    );
    expect(br.body).toMatchObject([{ name: "main", current: true, upstream: null }]);
    const d = await server.api<{ kind: string; patch: string }>(
      "GET",
      "/api/projects/shop/git/diff",
    );
    expect(d.body.kind).toBe("working");
    expect(d.body.patch).toContain("-line 2\n+line two");
    expect(d.body.patch).toContain("+++ b/new.txt");
    const c = await server.api<{ patch: string; title: string }>(
      "GET",
      `/api/projects/shop/git/diff?commit=${log.body[0]?.short}`,
    );
    expect(c.body.title).toBe("Files");
    expect(c.body.patch).toContain("+++ b/app.js");
    expect((await server.api("GET", "/api/projects/shop/git/diff?commit=HEAD;rm")).status).toBe(
      400,
    );
    // G40.17: every commit with its parents, and every branch with ?all=1 (the app's graph).
    await git(p.path, "checkout", "-qb", "side");
    await git(
      p.path,
      "-c",
      "user.name=T",
      "-c",
      "user.email=t@x",
      "commit",
      "-q",
      "--allow-empty",
      "-m",
      "Side",
    );
    await git(p.path, "checkout", "-q", "main");
    const graph = await server.api<{ subject: string; hash: string; parents: string[] }[]>(
      "GET",
      "/api/projects/shop/git/log?all=1",
    );
    expect(graph.body.map((c) => c.subject)).toEqual(["Side", "Files"]);
    expect(graph.body[0]?.parents).toEqual([graph.body[1]?.hash]);
    expect(graph.body[1]?.parents).toEqual([]);
    const only = await server.api<{ subject: string }[]>("GET", "/api/projects/shop/git/log");
    expect(only.body.map((c) => c.subject)).toEqual(["Files"]);
    expect((await server.api("GET", "/api/projects/ghost/git")).status).toBe(404);
  });

  it("discards a hunk (kept in the trash first), keeps one, commits", async () => {
    const p = await setUp();
    const server = s as Server;
    await writeFile(join(p.path, "README.md"), "# Shop\n\nline two\nline 3\n");
    await writeFile(join(p.path, "app.js"), "const a = 2;\nconsole.log(a);\n");
    const { patch } = (await server.api<{ patch: string }>("GET", "/api/projects/shop/git/diff"))
      .body;
    const files = patch.split(/^(?=diff --git )/m).filter(Boolean);
    const readme = files.find((f) => f.includes("README.md")) as string;
    const app = files.find((f) => f.includes("app.js")) as string;
    const gone = await server.api<{ backup: string }>("POST", "/api/projects/shop/git/hunk", {
      patch: readme,
      action: "discard",
    });
    expect(gone.status).toBe(200);
    expect(await readFile(join(p.path, "README.md"), "utf8")).toBe("# Shop\n\nline 2\nline 3\n");
    expect(await readFile(join(p.path, gone.body.backup), "utf8")).toBe(readme);
    const kept = await server.api("POST", "/api/projects/shop/git/hunk", {
      patch: app,
      action: "keep",
    });
    expect(kept.status).toBe(200);
    expect(await git(p.path, "diff", "--cached", "--name-only")).toBe("app.js");
    expect(
      (await server.api("POST", "/api/projects/shop/git/hunk", { patch: "nope", action: "keep" }))
        .status,
    ).toBe(400);
    const done = await server.api<{ commit: string }>("POST", "/api/projects/shop/git/commit", {
      message: "Two",
    });
    expect(done.status).toBe(200);
    expect(await git(p.path, "log", "-1", "--format=%s")).toBe("Two");
    const again = await server.api<{ code: string }>("POST", "/api/projects/shop/git/commit", {
      message: "Nothing",
    });
    expect(again.body.code).toBe("nothing");
  });

  it("an archived project is read only: no hunk, no commit, no push", async () => {
    const p = await setUp();
    const server = s as Server;
    await writeFile(join(p.path, "app.js"), "const a = 3;\n");
    expect((await server.api("POST", "/api/projects/shop/archive")).status).toBe(200);
    expect((await server.api("GET", "/api/projects/shop/git")).status).toBe(200);
    expect(
      (await server.api("POST", "/api/projects/shop/git/commit", { message: "x" })).status,
    ).toBe(423);
    expect((await server.api("POST", "/api/projects/shop/git/push", {})).status).toBe(423);
    const { patch } = (await server.api<{ patch: string }>("GET", "/api/projects/shop/git/diff"))
      .body;
    expect(
      (await server.api("POST", "/api/projects/shop/git/hunk", { patch, action: "discard" }))
        .status,
    ).toBe(423);
  });

  it("a push waits for the person's yes, and a no pushes nothing", async () => {
    const p = await setUp();
    const server = s as Server;
    expect(
      (await server.api<{ code: string }>("POST", "/api/projects/shop/git/push", {})).body.code,
    ).toBe("no_remote");
    const remote = await mkdtemp(join(tmpdir(), "rg-remote-"));
    extra.push(remote);
    await git(remote, "init", "-q", "--bare");
    await git(p.path, "remote", "add", "origin", remote);

    const waitAsked = async () => {
      for (let i = 0; i < 200; i++) {
        const [r] = server.core.approvals.list("me");
        if (r) return r;
        await new Promise((ok) => setTimeout(ok, 10));
      }
      throw new Error("no request");
    };
    const no = await server.api<Job>("POST", "/api/projects/shop/git/push", {});
    expect(no.status).toBe(202);
    const asked = await waitAsked();
    expect(asked.danger).toEqual(["git-push"]);
    server.core.approvals.decide("me", asked.requestId, "deny");
    expect((await server.core.jobs.settled(no.body.id))?.error?.code).toBe("denied");
    expect(await git(remote, "branch")).toBe("");

    const yes = await server.api<Job>("POST", "/api/projects/shop/git/push", {});
    server.core.approvals.decide("me", (await waitAsked()).requestId, "allow");
    expect((await server.core.jobs.settled(yes.body.id))?.state).toBe("done");
    expect(await git(remote, "log", "-1", "--format=%s", "main")).toBe("Files");
  });

  it("the project's log, filtered, and the tasks with their verifier", async () => {
    const p = await setUp();
    const server = s as Server;
    const god = server.core.registry.list({ ownerId: "me" })[0];
    for (const body of [
      { type: "task.opened", payload: { taskId: "t1", title: "Prices" } },
      {
        type: "tool.call",
        payload: { callId: "c1", tool: "bash", input: { command: "npm test" } },
      },
      { type: "tool.result", payload: { callId: "c1", ok: false, output: "1 failed" } },
      { type: "task.verified", payload: { taskId: "t1", verifier: "npm test", passed: false } },
    ] as const)
      await server.core.store.append({
        ownerId: "me",
        projectId: p.id,
        agentId: god?.id ?? null,
        body,
      } as Parameters<Server["core"]["store"]["append"]>[0]);
    const all = await server.api<{ events: { type: string; error: boolean }[]; types: string[] }>(
      "GET",
      "/api/projects/shop/events",
    );
    expect(all.body.events[0]?.type).toBe("task.verified");
    expect(all.body.types).toContain("tool.call");
    const errors = await server.api<{ events: { type: string }[] }>(
      "GET",
      "/api/projects/shop/events?errors=1",
    );
    expect(errors.body.events.map((e) => e.type)).toEqual(["task.verified", "tool.result"]);
    const calls = await server.api<{ events: unknown[] }>(
      "GET",
      "/api/projects/shop/events?type=tool.call",
    );
    expect(calls.body.events).toHaveLength(1);
    const tasks = await server.api<{ verifier: unknown; outcome: string }[]>(
      "GET",
      "/api/projects/shop/tasks",
    );
    expect(tasks.body[0]).toMatchObject({
      outcome: "open",
      verifier: { command: "npm test", passed: false },
      note: null,
    });
  });

  it("searches names and lines, never inside .git", async () => {
    await setUp();
    const server = s as Server;
    const hits = await server.api<{ path: string; line: number | null }[]>(
      "GET",
      "/api/files/search?scope=project:shop&q=console",
    );
    expect(hits.body).toEqual([{ path: "app.js", line: 2, text: "console.log(a);" }]);
    const names = await server.api<{ path: string; line: number | null }[]>(
      "GET",
      "/api/files/search?scope=project:shop&q=readme",
    );
    expect(names.body[0]).toEqual({ path: "README.md", line: null, text: null });
    expect(
      (await server.api<unknown[]>("GET", "/api/files/search?scope=project:shop&q=HEAD")).body,
    ).toEqual([]);
  });
});

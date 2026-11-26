// Whole projects from Claude Code (alpha 4.0, plan_import_progetti.md): what the preview finds and leaves out.
import { mkdir, mkdtemp, writeFile } from "node:fs/promises";
import { tmpdir } from "node:os";
import { join } from "node:path";
import { describe, expect, it } from "vitest";
import {
  claudeSlug,
  findClaudeProjects,
  isSecretFile,
  isWorktreeGit,
  machineLines,
  originOf,
} from "../src/import-projects.js";

describe("Claude Code's projects, the pure rules", () => {
  it.each([
    ["/mnt/archive1/progetti/work/harness", "-mnt-archive1-progetti-work-harness"],
    ["C:\\Users\\ana\\my_app", "C--Users-ana-my-app"],
    ["/home/ana/site.it", "-home-ana-site-it"],
  ])("Claude's folder name for %s", (path, slug) => expect(claudeSlug(path)).toBe(slug));

  it.each([
    [{ isFile: true, text: "gitdir: /x/.git/worktrees/harness-3127" }, true],
    [{ isFile: true, text: "something else" }, false],
    [{ isFile: false }, false],
  ])("a worktree's .git %j → %s", (dotGit, worktree) =>
    expect(isWorktreeGit(dotGit)).toBe(worktree),
  );

  it.each([
    [
      '[core]\n\tbare = false\n[remote "origin"]\n\turl = https://git.home.example/ana/site.git\n',
      "https://git.home.example/ana/site.git",
    ],
    [
      '[remote "origin"]\n\turl = https://ana:tok3n@github.com/ana/site.git\n',
      "https://github.com/ana/site.git",
    ],
    ['[remote "upstream"]\n\turl = https://github.com/x/y.git\n', undefined],
    ["", undefined],
  ])("origin of a git config → %s", (config, url) => expect(originOf(config)).toBe(url));

  it.each([
    [".env", true],
    [".env.production", true],
    [".env.example", false],
    ["anthropic.key", true],
    ["AuthKey_ABC.p8", true],
    ["secrets.json", true],
    ["id_ed25519", true],
    ["README.md", false],
    ["keys.ts", false],
  ])("secret file %s → %s", (name, secret) => expect(isSecretFile(name)).toBe(secret));

  it("lines tied to this machine, with the reason", () => {
    const text = [
      "# Project",
      "Code in `/mnt/archive1/progetti/work/harness`.",
      "Enter with `ssh rig` (PowerShell).",
      "DOCKER_HOST=ssh://root@192.168.1.13",
      "Files in E:\\coding\\XAMPP\\htdocs",
      "Open https://hub.home.varitest.ovh",
      "Use pnpm build and pnpm test.",
    ].join("\n");
    expect(machineLines(text).map((m) => [m.line, m.why])).toEqual([
      [2, "path"],
      [3, "ssh"],
      [4, "docker"],
      [5, "path"],
      [6, "address"],
    ]);
  });
});

describe("Claude Code's projects found on a computer", () => {
  it("reads each project Claude Code knows, leaves out the missing ones and worktrees", async () => {
    const home = await mkdtemp(join(tmpdir(), "rg-import-home-"));
    const site = join(home, "code", "site");
    const wt = join(home, "code", "site-wt");
    await mkdir(join(site, ".git"), { recursive: true });
    await writeFile(
      join(site, ".git", "config"),
      '[remote "origin"]\n\turl = https://ana:t@git.home.lan/ana/site.git\n',
    );
    await writeFile(join(site, "CLAUDE.md"), "# Site\nDeploy with `ssh web1`.\nTests: npm test.\n");
    await writeFile(join(site, "CLAUDE.local.md"), "Notes for me only.\n");
    await mkdir(join(site, "memory"));
    await writeFile(join(site, "memory", "roadmap.md"), "# Roadmap\n");
    await writeFile(join(site, ".env"), "API_KEY=secret\n");
    await mkdir(join(site, "node_modules", "x"), { recursive: true });
    await writeFile(join(site, "node_modules", "x", "big.js"), "x".repeat(10_000));
    await writeFile(join(site, "index.html"), "<p>hi</p>");
    await mkdir(wt, { recursive: true });
    await writeFile(join(wt, ".git"), `gitdir: ${site}/.git/worktrees/site-wt\n`);
    const claudeDir = join(home, ".claude", "projects", claudeSlug(site));
    await mkdir(join(claudeDir, "memory"), { recursive: true });
    await writeFile(join(claudeDir, "memory", "deploy.md"), "Deploys only on Fridays.\n");
    await writeFile(join(claudeDir, "a.jsonl"), "{}\n");
    await writeFile(join(claudeDir, "b.jsonl"), "{}\n");
    await writeFile(
      join(home, ".claude.json"),
      JSON.stringify({ projects: { [site]: {}, [wt]: {}, [join(home, "gone")]: {}, [home]: {} } }),
    );

    const found = await findClaudeProjects(home);
    // In the order of their paths: code/site, code/site-wt, gone (the home itself is not a project).
    expect(found.map((p) => [p.name, p.out ?? "in"])).toEqual([
      ["site", "in"],
      ["site-wt", "worktree"],
      ["gone", "missing"],
    ]);
    const p = found.find((x) => x.name === "site");
    expect(p).toMatchObject({
      git: true,
      remote: "https://git.home.lan/ana/site.git",
      notes: [{ file: "memory/roadmap.md" }],
      memory: [{ file: "deploy.md", text: "Deploys only on Fridays.\n" }],
      conversations: 2,
      secrets: [".env"],
    });
    expect(p?.instructions.map((i) => i.file)).toEqual(["CLAUDE.md", "CLAUDE.local.md"]);
    expect(p?.machine).toEqual([
      { file: "CLAUDE.md", line: 2, text: "Deploy with `ssh web1`.", why: "ssh" },
    ]);
    // node_modules is not counted, the secret neither
    expect(p?.bytes).toBeLessThan(1000);
  });
});

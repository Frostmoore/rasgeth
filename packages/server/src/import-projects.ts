// Whole projects from Claude Code (alpha 4.0, plan_import_progetti.md): the folders Claude Code knows
// (`~/.claude.json` › projects, with `~/.claude/projects/<slug>` for their memory and conversations),
// read only because the person asked. For each: its folder and repository, the instructions to give its
// orchestrator, the notes in its `memory/`, Claude's memory of it, its conversations, the secrets that
// stay out and the lines tied to this machine an agent will offer to adapt. Nothing changes here: the
// preview says what an import would bring, the person chooses.

import { readdir, readFile, stat } from "node:fs/promises";
import { basename, join } from "node:path";

/** Claude Code's folder name for a project: its path with every other character than a-z, 0-9 as «-». */
export function claudeSlug(path: string): string {
  return path.replace(/[^a-zA-Z0-9]/g, "-");
}

/** A `.git` that is a file («gitdir: …») is a `git worktree`: a working copy of another project, left out. */
export function isWorktreeGit(dotGit: { isFile: boolean; text?: string }): boolean {
  return dotGit.isFile && /^gitdir:/m.test(dotGit.text ?? "");
}

/** The address of `origin` in a `.git/config`, without any credentials it may carry; undefined without one. */
export function originOf(gitConfig: string): string | undefined {
  const section = /\[remote "origin"\]([\s\S]*?)(?=\n\[|$)/.exec(gitConfig)?.[1];
  const url = section && /^\s*url\s*=\s*(.+)$/m.exec(section)?.[1]?.trim();
  if (!url) return undefined;
  // https://user:token@host/… → https://host/… (a token in a remote is never shown nor kept).
  return url.replace(/^(https?:\/\/)[^@/]+@/, "$1");
}

/** Files that hold secrets: never read, never copied; the preview says to put them in the keychain. */
export function isSecretFile(name: string): boolean {
  return (
    (/^\.env(\..+)?$/i.test(name) && !/\.(example|sample|template)$/i.test(name)) ||
    /\.(key|pem|p8|p12|pfx|keystore|jks)$/i.test(name) ||
    /^(secrets?|credentials?)(\..+)?\.json$/i.test(name) ||
    /^id_(rsa|ed25519|ecdsa)$/.test(name)
  );
}

/** What makes a line belong to one machine: its paths, hosts and addresses. */
const MACHINE_PATTERNS: { re: RegExp; why: MachineReason }[] = [
  { re: /(^|[\s`'"(])\/(mnt|media|srv|opt|home\/[a-z_][\w-]*|root|Users\/[\w.-]+)\//, why: "path" },
  { re: /\b[A-Z]:\\[\w\\. -]+/, why: "path" },
  { re: /\bssh\s+(-[\w]+\s+)*[a-z][\w.-]*\b/i, why: "ssh" },
  { re: /\bDOCKER_HOST\b|\bunix:\/\/\/var\/run\/docker\.sock\b/, why: "docker" },
  {
    re: /\b(10|127|192\.168|172\.(1[6-9]|2\d|3[01]))\.\d{1,3}\.\d{1,3}(\.\d{1,3})?\b/,
    why: "address",
  },
  { re: /\b[\w-]+\.(home|lan|local|internal)\b/i, why: "address" },
];
export type MachineReason = "path" | "ssh" | "docker" | "address";

/** Lines of the instructions tied to this machine, for an agent to adapt with the person (at most `max`). */
export function machineLines(
  text: string,
  max = 30,
): { line: number; text: string; why: MachineReason }[] {
  const out: { line: number; text: string; why: MachineReason }[] = [];
  const lines = text.split(/\r?\n/);
  for (const [i, raw] of lines.entries()) {
    const hit = MACHINE_PATTERNS.find((p) => p.re.test(raw));
    if (!hit) continue;
    out.push({ line: i + 1, text: raw.trim().slice(0, 200), why: hit.why });
    if (out.length >= max) break;
  }
  return out;
}

/** Instructions files of a Claude Code project, in the order they are read. */
export const PROJECT_INSTRUCTIONS = ["CLAUDE.md", ".claude/CLAUDE.md", "CLAUDE.local.md"];

/** One project as the preview shows it. */
export interface FoundProject {
  name: string;
  path: string;
  /** Not there any more, or a worktree of another project: left out, with the reason. */
  out?: "missing" | "worktree";
  remote?: string;
  git: boolean;
  instructions: { file: string; text: string }[];
  /** Markdown files in the project's `memory/` (roadmap, plans, decisions): names and sizes. */
  notes: { file: string; size: number }[];
  /** Claude's own memory of it (`~/.claude/projects/<slug>/memory/*.md`). */
  memory: { file: string; text: string }[];
  /** Conversations Claude Code kept (`<slug>/*.jsonl`). */
  conversations: number;
  /** Secret files found (relative paths): they stay out. */
  secrets: string[];
  machine: { file: string; line: number; text: string; why: MachineReason }[];
  /** Its size without node_modules and .git, in bytes (what a copy would take). */
  bytes: number;
}

const WALK_SKIP = new Set([
  "node_modules",
  ".git",
  ".venv",
  "venv",
  "__pycache__",
  "dist",
  "build",
  ".next",
  "target",
]);
const MAX_TEXT = 60_000;

const readText = (p: string) =>
  readFile(p, "utf8").then(
    (t) => t.slice(0, MAX_TEXT),
    () => undefined,
  );

/** Secrets (as relative paths) and the size of a folder, without the generated folders (depth ≤ 6). */
async function survey(root: string): Promise<{ secrets: string[]; bytes: number }> {
  const secrets: string[] = [];
  let bytes = 0;
  let seen = 0;
  const visit = async (dir: string, rel: string, depth: number): Promise<void> => {
    if (depth > 6 || seen > 50_000) return;
    for (const e of await readdir(dir, { withFileTypes: true }).catch(() => [])) {
      if (e.isSymbolicLink()) continue;
      const r = rel ? `${rel}/${e.name}` : e.name;
      if (e.isDirectory()) {
        if (!WALK_SKIP.has(e.name)) await visit(join(dir, e.name), r, depth + 1);
      } else if (e.isFile()) {
        seen++;
        if (isSecretFile(e.name)) secrets.push(r);
        else bytes += (await stat(join(dir, e.name)).catch(() => undefined))?.size ?? 0;
      }
    }
  };
  await visit(root, "", 0);
  return { secrets: secrets.sort(), bytes };
}

/** One project folder, read as Claude Code left it (`claudeDir`: `~/.claude/projects/<slug>`). */
export async function readProject(path: string, claudeDir: string): Promise<FoundProject> {
  const name = basename(path) || path;
  const base: FoundProject = {
    name,
    path,
    git: false,
    instructions: [],
    notes: [],
    memory: [],
    conversations: 0,
    secrets: [],
    machine: [],
    bytes: 0,
  };
  const dir = await stat(path).catch(() => undefined);
  if (!dir?.isDirectory()) return { ...base, out: "missing" };
  const dotGit = await stat(join(path, ".git")).catch(() => undefined);
  if (dotGit?.isFile()) {
    const text = await readText(join(path, ".git"));
    if (isWorktreeGit({ isFile: true, ...(text !== undefined && { text }) }))
      return { ...base, out: "worktree" };
  }
  const git = Boolean(dotGit?.isDirectory());
  const remote = git ? originOf((await readText(join(path, ".git", "config"))) ?? "") : undefined;
  const instructions: FoundProject["instructions"] = [];
  for (const file of PROJECT_INSTRUCTIONS) {
    const text = await readText(join(path, file));
    if (text?.trim()) instructions.push({ file, text });
  }
  const notes: FoundProject["notes"] = [];
  for (const e of await readdir(join(path, "memory"), { withFileTypes: true }).catch(() => []))
    if (e.isFile() && /\.md$/i.test(e.name))
      notes.push({
        file: `memory/${e.name}`,
        size: (await stat(join(path, "memory", e.name)).catch(() => undefined))?.size ?? 0,
      });
  const memory: FoundProject["memory"] = [];
  for (const e of await readdir(join(claudeDir, "memory"), { withFileTypes: true }).catch(() => []))
    if (e.isFile() && /\.md$/i.test(e.name)) {
      const text = await readText(join(claudeDir, "memory", e.name));
      if (text?.trim()) memory.push({ file: e.name, text });
    }
  const conversations = (await readdir(claudeDir).catch(() => [] as string[])).filter((f) =>
    f.endsWith(".jsonl"),
  ).length;
  const { secrets, bytes } = await survey(path);
  const machine = instructions.flatMap((i) =>
    machineLines(i.text).map((m) => ({ file: i.file, ...m })),
  );
  return {
    ...base,
    git,
    ...(remote && { remote }),
    instructions,
    notes: notes.sort((a, b) => a.file.localeCompare(b.file)),
    memory,
    conversations,
    secrets,
    machine,
    bytes,
  };
}

/** The folder a project's conversations were held in: the `cwd` of the first lines of its newest transcript. */
export async function cwdOf(claudeDir: string): Promise<string | undefined> {
  const files = (await readdir(claudeDir).catch(() => [] as string[])).filter((f) =>
    f.endsWith(".jsonl"),
  );
  const dated = await Promise.all(
    files.map(async (f) => ({
      f,
      t: (await stat(join(claudeDir, f)).catch(() => undefined))?.mtimeMs ?? 0,
    })),
  );
  for (const { f } of dated.sort((a, b) => b.t - a.t).slice(0, 3)) {
    const head = (await readFile(join(claudeDir, f), "utf8").catch(() => "")).slice(0, 200_000);
    const cwd = /"cwd"\s*:\s*"((?:[^"\\]|\\.)*)"/.exec(head)?.[1];
    if (cwd) return JSON.parse(`"${cwd}"`) as string;
  }
  return undefined;
}

/**
 * The projects Claude Code knows on this computer: the paths in `~/.claude.json` › projects and the
 * folders under `~/.claude/projects` (their path from the `cwd` of their conversations: a folder name
 * cannot tell «/» from «-»). The home folder itself is not a project.
 */
export async function findClaudeProjects(home: string): Promise<FoundProject[]> {
  const paths = new Set<string>();
  try {
    const json = await readFile(join(home, ".claude.json"), "utf8");
    const projects = (JSON.parse(json) as { projects?: Record<string, unknown> }).projects;
    for (const p of Object.keys(projects ?? {})) paths.add(p);
  } catch {
    // no file, or not JSON: only the folders below
  }
  const root = join(home, ".claude", "projects");
  for (const e of await readdir(root, { withFileTypes: true }).catch(() => []))
    if (e.isDirectory()) {
      const cwd = await cwdOf(join(root, e.name));
      if (cwd) paths.add(cwd);
    }
  const homeNorm = home.replace(/[\\/]+$/, "");
  const out: FoundProject[] = [];
  for (const p of [...paths].sort()) {
    if (p.replace(/[\\/]+$/, "") === homeNorm) continue;
    out.push(await readProject(p, join(root, claudeSlug(p))));
  }
  return out;
}

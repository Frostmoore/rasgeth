import { execFileSync } from "node:child_process";
import { existsSync } from "node:fs";
import { chmod, mkdir, mkdtemp, readFile, rm, writeFile } from "node:fs/promises";
import { createServer } from "node:net";
import { tmpdir } from "node:os";
import { join } from "node:path";
import { fileURLToPath } from "node:url";
import { afterEach, describe, expect, it } from "vitest";
import { DEFAULT_BUILD, INSTALLED_LOCKFILE, readRelease, Supervisor } from "../src/index.js";

// A new image without internet (3.9.1). The entrypoint merges the image's source into the live
// one; the supervisor used to build it with `pnpm install`, which cannot work offline, and went
// back to the previous version, which did not answer in the new image. Now the image's own build
// is used when the live code is the image's, and the packages are installed again only when the
// lockfile changed.

const entrypoint = fileURLToPath(new URL("../../../docker/entrypoint.sh", import.meta.url));

/** The image's stand-in for the server: answers with its compiled file. */
const SERVER = `import http from "node:http";
import { readFileSync } from "node:fs";
const v = readFileSync("packages/a/dist/x.js", "utf8").trim();
http.createServer((req, res) => res.end(v)).listen(Number(process.env.REDGIANT_PORT), "127.0.0.1");
`;

/** pnpm without a network: install fails, build compiles. Every call is written down. */
const PNPM = `#!/bin/sh
echo "$*" >> "$PNPM_CALLS"
case "$1" in
  install) echo "ERR_PNPM_META_FETCH_FAIL: no network" >&2; exit 1 ;;
  build) cp packages/a/src/x.ts packages/a/dist/x.js ;;
esac
`;

const freePort = () =>
  new Promise<number>((resolve) => {
    const s = createServer().listen(0, "127.0.0.1", () => {
      const { port } = s.address() as { port: number };
      s.close(() => resolve(port));
    });
  });

let dirs: string[] = [];
let sups: Supervisor[] = [];
afterEach(async () => {
  for (const s of sups) await s.stop();
  for (const d of dirs)
    await rm(d, { recursive: true, force: true, maxRetries: 10, retryDelay: 200 });
  dirs = [];
  sups = [];
});

async function world() {
  const root = await mkdtemp(join(tmpdir(), "rg-image-"));
  dirs.push(root);
  const app = join(root, "image");
  const data = join(root, "data");
  const bin = join(root, "bin");
  const calls = join(root, "pnpm-calls.txt");
  await mkdir(bin, { recursive: true });
  await writeFile(join(bin, "pnpm"), PNPM);
  await chmod(join(bin, "pnpm"), 0o755);
  await writeFile(calls, "");

  /** A new image: its version, lockfile and compiled code. */
  const image = async (version: string, lock: string, code: string) => {
    await rm(app, { recursive: true, force: true });
    await mkdir(join(app, "packages", "a", "src"), { recursive: true });
    await mkdir(join(app, "packages", "a", "dist"), { recursive: true });
    await mkdir(join(app, "node_modules", "dep"), { recursive: true });
    await writeFile(join(app, ".image-version"), version);
    await writeFile(join(app, ".gitignore"), "node_modules/\ndist/\n*.tsbuildinfo\n");
    await writeFile(join(app, "server.mjs"), SERVER);
    await writeFile(join(app, "pnpm-lock.yaml"), lock);
    await writeFile(join(app, INSTALLED_LOCKFILE), lock);
    await writeFile(join(app, "node_modules", "dep", "index.js"), lock);
    await writeFile(join(app, "packages", "a", "src", "x.ts"), code);
    await writeFile(join(app, "packages", "a", "dist", "x.js"), code);
  };
  const uid = process.getuid?.() ?? 0;
  const gid = process.getgid?.() ?? 0;
  /** The container starts: the entrypoint, up to the supervisor. */
  const start = () =>
    execFileSync("bash", [entrypoint], {
      env: {
        ...process.env,
        REDGIANT_APP_DIR: app,
        REDGIANT_DATA_DIR: data,
        REDGIANT_RUN_AS: `${uid}:${gid}`,
        REDGIANT_ENTRYPOINT_PREPARE_ONLY: "1",
      },
    }).toString();
  const src = join(data, "source");
  const git = (...a: string[]) =>
    execFileSync("git", ["-c", "user.name=t", "-c", "user.email=t@t", ...a], { cwd: src })
      .toString()
      .trim();
  const port = await freePort();
  const url = `http://127.0.0.1:${port}`;
  /** The supervisor as the image runs it, with pnpm offline. */
  const supervise = () => {
    const sup = new Supervisor({
      sourceDir: src,
      stateDir: join(data, "release"),
      build: DEFAULT_BUILD,
      start: { command: process.execPath, args: ["server.mjs"] },
      env: {
        ...process.env,
        PATH: `${bin}:${process.env.PATH}`,
        PNPM_CALLS: calls,
        REDGIANT_PORT: String(port),
      },
      healthUrl: url,
      healthTimeoutMs: 5000,
      stableMs: 300,
      stdio: "ignore",
      log: () => {},
    });
    sups.push(sup);
    void sup.run();
    return sup;
  };
  const answer = async (expected: string) => {
    const deadline = Date.now() + 15_000;
    let got = "";
    while (Date.now() < deadline) {
      got = await fetch(url)
        .then((r) => r.text())
        .catch(() => "");
      if (got === expected) return got;
      await new Promise((r) => setTimeout(r, 100));
    }
    return got;
  };
  const pnpmCalls = async () => (await readFile(calls, "utf8")).split("\n").filter(Boolean);
  return { image, start, git, supervise, answer, pnpmCalls, src, data };
}

describe.skipIf(process.platform === "win32")("a new image without internet", () => {
  it("starts the image's own build: nothing to install or compile", async () => {
    const w = await world();
    await w.image("1.0.0", "lock 1", "one");
    w.start();
    let sup = w.supervise();
    expect(await w.answer("one")).toBe("one");
    await sup.stop();
    const first = (await readRelease(join(w.data, "release"))).lastGood;
    await writeFile(join(w.src, "node_modules", "left-over.txt"), "of version 1");

    await w.image("2.0.0", "lock 2", "two");
    expect(w.start()).toContain("using the build of Rasgeth 2.0.0 in the image");
    const head = w.git("rev-parse", "HEAD");
    expect((await readRelease(join(w.data, "release"))).built).toBe(head);
    expect(await readFile(join(w.src, INSTALLED_LOCKFILE), "utf8")).toBe("lock 2");
    // A new lockfile: the image's packages replace the old ones.
    expect(existsSync(join(w.src, "node_modules", "left-over.txt"))).toBe(false);
    expect(await readFile(join(w.src, "node_modules", "dep", "index.js"), "utf8")).toBe("lock 2");

    sup = w.supervise();
    expect(await w.answer("two")).toBe("two");
    await expect
      .poll(async () => (await readRelease(join(w.data, "release"))).lastGood, { timeout: 5000 })
      .toBe(head);
    expect(head).not.toBe(first);
    // pnpm was never needed: neither install (no network) nor build.
    expect(await w.pnpmCalls()).toEqual([]);
  });

  it("God's changes on top are compiled without installing: the lockfile is the image's", async () => {
    const w = await world();
    await w.image("1.0.0", "lock 1", "one");
    w.start();
    // God changed something of their own, not the code the image brings.
    await writeFile(join(w.src, "notes.md"), "God was here\n");
    w.git("add", "-A");
    w.git("commit", "-q", "-m", "God's change");
    await writeFile(join(w.src, "node_modules", "kept.txt"), "same lockfile");

    await w.image("2.0.0", "lock 1", "two");
    expect(w.start()).toContain("merged with the changes made here");
    // The same lockfile: the packages stay (1 GB not copied again), the compiled files are new.
    expect(await readFile(join(w.src, "node_modules", "kept.txt"), "utf8")).toBe("same lockfile");
    expect(await readFile(join(w.src, "packages", "a", "dist", "x.js"), "utf8")).toBe("two");
    const head = w.git("rev-parse", "HEAD");
    expect((await readRelease(join(w.data, "release"))).built).not.toBe(head);

    w.supervise();
    expect(await w.answer("two")).toBe("two");
    expect(await w.pnpmCalls()).toEqual(["build"]);
    expect(await readFile(join(w.src, "notes.md"), "utf8")).toBe("God was here\n");
  });

  it("a new lockfile is installed (and fails without a network, as before)", async () => {
    const w = await world();
    await w.image("1.0.0", "lock 1", "one");
    w.start();
    await writeFile(join(w.src, "pnpm-lock.yaml"), "lock of God's");
    w.git("add", "-A");
    w.git("commit", "-q", "-m", "God's packages");
    w.supervise();
    await expect.poll(w.pnpmCalls, { timeout: 5000 }).toContain("install --frozen-lockfile");
  });
});

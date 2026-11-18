// Rasgeth OS (3.8.1): an update as the page follows it. The updater runs as it is (a copy whose
// only changes are the machine's folders, its port and the address of the latest release) on a
// fake root: Docker is a fake socket that answers the pull with the progress of every layer, as the
// real API does, and a fake `docker` for the rest. The state the page reads must say the steps in
// order, what is downloaded with its size, how far it is (bytes, speed, time left) and, at the end,
// the version it came from, or why it stopped and that the previous version runs again.
import { spawn, spawnSync } from "node:child_process";
import { generateKeyPairSync } from "node:crypto";
import {
  chmodSync,
  copyFileSync,
  existsSync,
  mkdirSync,
  mkdtempSync,
  readFileSync,
  writeFileSync,
} from "node:fs";
import { createServer, type Server } from "node:http";
import { tmpdir } from "node:os";
import { dirname, join } from "node:path";
import { fileURLToPath } from "node:url";
import { afterEach, describe, expect, it } from "vitest";
// @ts-expect-error plain JavaScript, no types
import { signManifest } from "../../update/sign.mjs";
// @ts-expect-error plain JavaScript, no types
import { buildFiles } from "../files.mjs";

const LIB = fileURLToPath(new URL("../rootfs/usr/lib/redgiant-os/", import.meta.url));
const JQ_DIR = "/mnt/archive1/officina-dati/rg-test/bin";
const PATH0 = existsSync(join(JQ_DIR, "jq")) ? `${JQ_DIR}:${process.env.PATH}` : process.env.PATH;
const hasTools =
  process.platform === "linux" &&
  spawnSync("jq", ["--version"], { env: { ...process.env, PATH: PATH0 } }).status === 0 &&
  spawnSync("curl", ["--version"]).status === 0;

const hex = (c: string) => c.repeat(64);
const MB = 1_000_000;
type Layer = { id: string; size: number; exists?: boolean };
type Pull = { repo: string; digest: string; id: string; layers: Layer[]; fail?: boolean };

/** Replaces every `from` in `text`, and fails when one is not there (the copy must stay true). */
function swap(text: string, pairs: [string, string][]): string {
  let out = text;
  for (const [from, to] of pairs) {
    expect(out.includes(from), `the script has no ${from}`).toBe(true);
    out = out.split(from).join(to);
  }
  return out;
}

const safe = (ref: string) => ref.replace(/[/:@]/g, "_");

interface Machine {
  root: string;
  updater: string;
  env: NodeJS.ProcessEnv;
  servers: Server[];
}

const open: Server[] = [];
afterEach(async () => {
  await Promise.all(open.splice(0).map((s) => new Promise((r) => s.close(() => r(null)))));
});

/** The fake Docker API: each pull streams its layers' progress over about six seconds. */
function dockerSocket(path: string, images: string, pulls: Pull[]): Promise<Server> {
  const server = createServer((req, res) => {
    const u = new URL(req.url ?? "/", "http://docker");
    const p = pulls.find((x) => x.repo === u.searchParams.get("fromImage"));
    if (req.method !== "POST" || u.pathname !== "/images/create" || !p) {
      res.writeHead(404, { "content-type": "application/json" });
      res.end(`${JSON.stringify({ message: "no such image" })}\n`);
      return;
    }
    expect(u.searchParams.get("tag")).toBe(p.digest);
    res.writeHead(200, { "content-type": "application/json" });
    const say = (o: unknown) => res.write(`${JSON.stringify(o)}\n`);
    say({ status: `Pulling from ${p.repo}`, id: p.digest });
    for (const l of p.layers)
      say({ status: l.exists ? "Already exists" : "Pulling fs layer", id: l.id.slice(0, 12) });
    let tick = 0;
    const timer = setInterval(() => {
      tick++;
      if (p.fail && tick === 4) {
        clearInterval(timer);
        say({ errorDetail: { message: "connection reset" }, error: "connection reset" });
        res.end();
        return;
      }
      for (const l of p.layers.filter((x) => !x.exists))
        say({
          status: "Downloading",
          id: l.id.slice(0, 12),
          progressDetail: { current: Math.min(l.size, (l.size * tick) / 15), total: l.size },
        });
      if (tick < 15) return;
      clearInterval(timer);
      for (const l of p.layers.filter((x) => !x.exists)) {
        say({ status: "Download complete", id: l.id.slice(0, 12) });
        say({ status: "Extracting", id: l.id.slice(0, 12), progressDetail: { current: 1 } });
        say({ status: "Pull complete", id: l.id.slice(0, 12) });
      }
      writeFileSync(join(images, safe(`${p.repo}@${p.digest}`)), p.id);
      say({ status: `Digest: ${p.digest}` });
      say({ status: `Status: Downloaded newer image for ${p.repo}@${p.digest}` });
      res.end();
    }, 400);
  });
  return new Promise((r) => server.listen(path, () => r(server)));
}

function healthServer(ok: boolean): Promise<{ server: Server; port: number }> {
  const server = createServer((_req, res) => {
    res.writeHead(ok ? 200 : 503);
    res.end(ok ? '{"ok":true}' : "starting");
  });
  return new Promise((r) =>
    server.listen(0, "127.0.0.1", () => {
      const a = server.address();
      r({ server, port: typeof a === "object" && a ? a.port : 0 });
    }),
  );
}

const fake = (dir: string, name: string, text: string) =>
  writeFileSync(join(dir, name), text, { mode: 0o755 });

async function machine(o: { fail?: boolean; unhealthy?: boolean } = {}): Promise<Machine> {
  const root = mkdtempSync(join(tmpdir(), "rg-os-upd-"));
  for (const d of ["lib", "share", "state", "feed", "bin", "images", "root", "repo"])
    mkdirSync(join(root, d), { recursive: true });
  const images = join(root, "images");
  const { privateKey, publicKey } = generateKeyPairSync("rsa", { modulusLength: 2048 });
  const pem = privateKey.export({ type: "pkcs8", format: "pem" }).toString();
  writeFileSync(
    join(root, "share/release-key.pem"),
    publicKey.export({ type: "spki", format: "pem" }).toString(),
  );
  const health = await healthServer(!o.unhealthy);
  open.push(health.server);

  // The scripts, pointed at the fake root.
  writeFileSync(
    join(root, "lib/common.sh"),
    swap(readFileSync(join(LIB, "common.sh"), "utf8"), [
      ["STATE=/var/lib/redgiant", `STATE=${root}/state`],
      ["SHARE=/usr/share/redgiant-os", `SHARE=${root}/share`],
      ["PORT=7600", `PORT=${health.port}`],
      ["/etc/redgiant-os/os.conf", `${root}/os.conf`],
    ]),
  );
  copyFileSync(join(LIB, "redgiant-stack"), join(root, "lib/redgiant-stack"));
  chmodSync(join(root, "lib/redgiant-stack"), 0o755);
  const updater = join(root, "lib/redgiant-os-update");
  writeFileSync(
    updater,
    swap(readFileSync(join(LIB, "redgiant-os-update"), "utf8"), [
      ["/usr/lib/redgiant-os/redgiant-stack", `${root}/lib/redgiant-stack`],
      [
        "https://api.github.com/repos/$REPO/releases/latest",
        `file://${root}/feed/release-api.json`,
      ],
      ['files_apply "$WORK" / "$KEY"', `files_apply "$WORK" "${root}/root" "$KEY"`],
      ['files_undo "$WORK" /', `files_undo "$WORK" "${root}/root"`],
      ["$(seq 1 120)", "$(seq 1 3)"],
      ["    sleep 5\n", "    sleep 0.2\n"],
    ]),
    { mode: 0o755 },
  );

  // The stacks: the one built in (3.8.0, running) and the release's (3.8.1).
  const L = (c: string, size: number, exists = false): Layer => ({ id: hex(c), size, exists });
  const pulls: Pull[] = [
    {
      repo: "ghcr.io/frostmoore/redgiant2",
      digest: `sha256:${hex("1")}`,
      id: `sha256:${hex("e")}`,
      layers: [L("a", 50 * MB, true), L("b", 3 * MB), L("c", 2 * MB)],
    },
    {
      repo: "ghcr.io/frostmoore/redgiant2-postgres",
      digest: `sha256:${hex("2")}`,
      id: `sha256:${hex("f")}`,
      // b is shared with Rasgeth's image: downloaded (and counted) once.
      layers: [L("b", 3 * MB), L("d", 1 * MB)],
      fail: o.fail === true,
    },
  ];
  const image = (p: Pull, name: string, env: string, tag: string) => ({
    name,
    env,
    ref: `${p.repo}:${tag}`,
    digest: p.digest,
    id: p.id,
    bytes: p.layers.reduce((n, l) => n + l.size, 0),
    layers: p.layers.map((l) => ({ digest: `sha256:${l.id}`, size: l.size })),
  });
  const [server, postgres] = pulls as [Pull, Pull];
  const list = [
    image(server, "redgiant", "REDGIANT_IMAGE", "3.8.1"),
    image(postgres, "postgres", "REDGIANT_POSTGRES_IMAGE", "17-pgvector0.8.7"),
  ];
  const stack = (version: string, l: unknown[]) =>
    `${JSON.stringify({ format: 1, version, images: { amd64: l, arm64: l }, files: { "compose.yaml": "services: {}\n" } })}\n`;
  writeFileSync(
    join(root, "share/stack.json"),
    stack("3.8.0", [
      { ...list[0], ref: "ghcr.io/frostmoore/redgiant2:3.8.0", id: `sha256:${hex("9")}` },
    ]),
  );
  writeFileSync(join(images, safe("ghcr.io/frostmoore/redgiant2:3.8.0")), `sha256:${hex("9")}`);

  // The release: release.json, the stack and the system's files, signed with the test key.
  const feed = join(root, "feed");
  const put = (base: string, path: string, text: string, mode = 0o644) => {
    mkdirSync(dirname(join(base, path)), { recursive: true });
    writeFileSync(join(base, path), text, { mode });
  };
  put(join(root, "repo"), "packaging/os/setup-chroot.sh", "systemctl enable a.service\n");
  put(join(root, "repo"), "packaging/os/rootfs/usr/lib/redgiant-os/redgiant-tool", "echo new\n");
  put(join(root, "repo"), "packages/server/helpers/redgiant-helper", "echo helper\n", 0o755);
  put(
    join(root, "repo"),
    "packaging/os/lxc/rootfs/etc/systemd/network/70-redgiant-container.network",
    "[Match]\n",
  );
  buildFiles("3.8.1", feed, join(root, "repo"));
  put(join(root, "root"), "usr/lib/redgiant-os/redgiant-tool", "echo old\n", 0o755);
  writeFileSync(join(feed, "release.json"), '{"format":1,"version":"3.8.1","kind":"normal"}\n');
  writeFileSync(join(feed, "rasgeth-os-stack.json"), stack("3.8.1", list));
  for (const f of ["release.json", "rasgeth-os-stack.json", "rasgeth-os-files.json"])
    writeFileSync(join(feed, `${f}.sig`), signManifest(readFileSync(join(feed, f)), pem));
  const archive = "rasgeth-os-files-3.8.1.tar.zst";
  const assets = [
    "release.json",
    "release.json.sig",
    "rasgeth-os-stack.json",
    "rasgeth-os-stack.json.sig",
    "rasgeth-os-files.json",
    "rasgeth-os-files.json.sig",
    archive,
  ].map((name) => ({
    name,
    size: readFileSync(join(feed, name)).length,
    browser_download_url: `file://${feed}/${name}`,
  }));
  writeFileSync(join(feed, "release-api.json"), JSON.stringify({ tag_name: "v3.8.1", assets }));

  // The machine's programs: Docker's CLI, systemd, zstd, the disk's tools.
  const bin = join(root, "bin");
  fake(
    bin,
    "docker",
    `#!/bin/bash
I=${images}
s() { printf '%s' "$1" | tr '/:@' '___'; }
echo "docker $*" >>"${root}/calls.log"
case "$1" in
  image) [ -f "$I/$(s "$5")" ] && cat "$I/$(s "$5")" && echo || exit 1 ;;
  tag) [ -f "$I/$(s "$2")" ] && cp "$I/$(s "$2")" "$I/$(s "$3")" || exit 1 ;;
  compose) exit 0 ;;
  *) exit 1 ;;
esac
`,
  );
  fake(bin, "systemctl", `#!/bin/sh\necho "systemctl $*" >>"${root}/calls.log"\nexit 0\n`);
  fake(bin, "networkctl", "#!/bin/sh\nexit 0\n");
  fake(bin, "findmnt", "#!/bin/sh\necho /dev/sda1\n");
  fake(bin, "lsblk", "#!/bin/sh\necho sda\n");
  fake(bin, "lspci", "#!/bin/sh\nexit 0\n");
  writeFileSync(
    join(bin, "unzstd.cjs"),
    "process.stdout.write(require('node:zlib').zstdDecompressSync(require('node:fs').readFileSync(process.argv[2])));\n",
  );
  fake(
    bin,
    "zstd",
    `#!/bin/sh\n[ "$1" = -dc ] || exit 2\nexec "${process.execPath}" "${bin}/unzstd.cjs" "$2"\n`,
  );

  const sock = join(root, "docker.sock");
  open.push(await dockerSocket(sock, images, pulls));
  return {
    root,
    updater,
    servers: [],
    env: {
      ...process.env,
      PATH: `${bin}:${PATH0}`,
      REDGIANT_DOCKER_SOCK: sock,
    },
  };
}

type State = Record<string, unknown> & {
  state: string;
  step: string | null;
  progress?: {
    done: number;
    total: number;
    bps: number;
    eta: number | null;
    items: { name: string; state: string; done: number; total: number }[];
  } | null;
};

/** Runs the updater, reading its state as the page would, five times a second. */
async function run(m: Machine): Promise<{ code: number; seen: State[]; end: State; err: string }> {
  const file = join(m.root, "state/os-update.json");
  const seen: State[] = [];
  let err = "";
  const child = spawn("bash", [m.updater, "apply"], { env: m.env });
  child.stderr.on("data", (d) => {
    err += d.toString();
  });
  const timer = setInterval(() => {
    try {
      const s = JSON.parse(readFileSync(file, "utf8")) as State;
      if (JSON.stringify(seen.at(-1)) !== JSON.stringify(s)) seen.push(s);
    } catch {
      // not written yet
    }
  }, 200);
  const code = await new Promise<number>((r) => child.on("close", (c) => r(c ?? -1)));
  clearInterval(timer);
  return { code, seen, end: JSON.parse(readFileSync(file, "utf8")) as State, err };
}

describe("redgiant-os-update apply: the page can follow every step", () => {
  it("says the steps, the download with its bar, speed and time left, and where it came from", {
    skip: !hasTools,
    timeout: 60_000,
  }, async () => {
    const m = await machine();
    const r = await run(m);
    expect(r.code, r.err).toBe(0);
    // Every step in order with the time it began (the quick ones pass between two looks).
    const steps = ["check", "download", "files", "install", "restart", "wait"];
    expect(Object.keys(r.end.stepAt as object)).toEqual(steps);
    const looked = r.seen.map((s) => s.step).filter((s, i, a) => s && s !== a[i - 1]);
    expect(looked.filter((s) => s === "download" || s === "files")).toEqual(["download", "files"]);
    const during = r.seen.find((s) => s.step === "download");
    expect(during?.steps).toEqual(["check", "download", "files", "install", "restart", "wait"]);
    expect(during?.from).toBe("3.8.0");
    // What comes down, with the sizes of the release's stack.
    expect(during?.plan).toMatchObject({
      images: [
        { name: "redgiant", bytes: 55 * MB, here: false },
        { name: "postgres", bytes: 4 * MB, here: false },
      ],
      files: { name: "rasgeth-os-files-3.8.1.tar.zst" },
    });
    // The bar: the layer already here is not counted, the shared one once (3 + 2 + 1 MB).
    const bars = r.seen.filter((s) => s.step === "download" && s.progress?.total);
    expect(bars.length).toBeGreaterThan(2);
    for (const s of bars) expect(s.progress?.total).toBe(6 * MB);
    const done = bars.map((s) => s.progress?.done ?? 0);
    expect(done).toEqual([...done].sort((a, b) => a - b));
    expect(done.at(-1)).toBeGreaterThan(0);
    expect(
      bars.some((s) => (s.progress?.bps ?? 0) > 0 && (s.progress?.eta ?? 0) > 0),
      JSON.stringify(
        bars.map((s) => [s.checkedAt, s.progress?.done, s.progress?.bps, s.progress?.eta]),
      ),
    ).toBe(true);
    expect(bars.at(-1)?.progress?.items.map((i) => i.name)).toEqual(["redgiant", "postgres"]);
    // At its end the bar is full, every image done (written once more after the pulls).
    const full = r.seen.filter((s) => s.step === "download" && s.progress?.done === 6 * MB);
    if (full.length)
      expect(full.at(-1)?.progress?.items.map((i) => i.state)).toEqual(["done", "done"]);
    // The system's files: their own bar, of the archive's size.
    const files = r.seen.find((s) => s.step === "files" && s.progress);
    expect(files?.progress?.items[0]?.name).toBe("rasgeth-os-files-3.8.1.tar.zst");
    // The end: the new version, where it came from, when.
    expect(r.end).toMatchObject({ state: "latest", installed: "3.8.1", from: "3.8.0" });
    expect(typeof r.end.finishedAt).toBe("string");
    expect(readFileSync(join(m.root, "root/usr/lib/redgiant-os/redgiant-tool"), "utf8")).toBe(
      "echo new\n",
    );
  });

  it("stops on a failed download with its reason, the running version untouched", {
    skip: !hasTools,
    timeout: 60_000,
  }, async () => {
    const m = await machine({ fail: true });
    const r = await run(m);
    expect(r.code).toBe(1);
    expect(r.end).toMatchObject({ state: "error", reason: "download", installed: "3.8.0" });
    expect(typeof r.end.finishedAt).toBe("string");
    expect(r.err).toContain("connection reset");
    expect(existsSync(join(m.root, "state/stack.json"))).toBe(false);
    expect(readFileSync(join(m.root, "root/usr/lib/redgiant-os/redgiant-tool"), "utf8")).toBe(
      "echo old\n",
    );
  });

  it("goes back when the new version does not answer, and says so", {
    skip: !hasTools,
    timeout: 60_000,
  }, async () => {
    const m = await machine({ unhealthy: true });
    const r = await run(m);
    expect(r.code).toBe(1);
    expect(Object.keys(r.end.stepAt as object).at(-1)).toBe("rollback");
    expect(r.end).toMatchObject({ state: "error", reason: "not_up", installed: "3.8.0" });
    expect((r.end.steps as string[]).at(-1)).toBe("rollback");
    expect(readFileSync(join(m.root, "root/usr/lib/redgiant-os/redgiant-tool"), "utf8")).toBe(
      "echo old\n",
    );
  });
});

// The guided install of the iOS bridge (3.12.2): serve-sim (Apache-2.0, Apple silicon only) is never
// shipped nor installed by itself. Only with the person's yes (`start` with the plan's id) it is
// downloaded from the npm registry into a folder of Rasgeth's own on that Mac (`<data>/ios-bridge`):
// the tarball of the pinned version, checked against the registry's integrity, then installed there
// by the npm that comes with the Node Rasgeth runs with (`--prefix` and `--cache` inside the folder,
// no scripts, nothing global). Removing the folder removes it. Xcode is never installed here.
import { createHash, randomUUID } from "node:crypto";
import { createWriteStream } from "node:fs";
import { access, mkdir, rm } from "node:fs/promises";
import { delimiter, dirname, join } from "node:path";
import { Readable, Transform } from "node:stream";
import { pipeline } from "node:stream/promises";
import {
  IOS_BRIDGE_VERSION,
  type IosBridgeBlock,
  type IosBridgePlan,
  type Job,
} from "@redgiant/protocol";
import type { Jobs } from "../jobs.js";
import { iosBridgeScript } from "./gather.js";
import { InstallError } from "./install.js";
import { type Run, runProgram } from "./ios.js";
import type { EmulatorMachine } from "./machine.js";

const REGISTRY = "https://registry.npmjs.org/serve-sim";

interface Stored {
  ownerId: string;
  at: number;
  tarball: string;
  integrity: string;
  npm: string;
}

export interface IosBridgeInstallerOptions {
  jobs: Jobs;
  machine: Pick<EmulatorMachine, "report">;
  /** The folder it goes into (`<data>/ios-bridge`). */
  dir: string;
  fetch?: typeof fetch;
  run?: Run;
  /** Tests: where npm is, instead of looking next to Node and on the PATH. */
  npm?: () => Promise<string | undefined>;
  env?: () => NodeJS.ProcessEnv;
  now?: () => number;
}

/** npm next to the Node Rasgeth runs with, else the first on the PATH. */
export async function findNpm(
  node = process.execPath,
  env: NodeJS.ProcessEnv = process.env,
): Promise<string | undefined> {
  const names = process.platform === "win32" ? ["npm.cmd", "npm"] : ["npm"];
  const dirs = [dirname(node), ...(env.PATH ?? "").split(delimiter).filter(Boolean)];
  for (const d of dirs)
    for (const n of names) {
      const p = join(d, n);
      if (
        await access(p).then(
          () => true,
          () => false,
        )
      )
        return p;
    }
  return undefined;
}

/** The registry's `sha512-<base64>` integrity of some bytes (so a download is checked). */
export const integrityOf = (bytes: Uint8Array): string =>
  `sha512-${createHash("sha512").update(bytes).digest("base64")}`;

export class IosBridgeInstaller {
  private readonly plans = new Map<string, Stored>();
  private running: string | undefined;

  constructor(private readonly o: IosBridgeInstallerOptions) {}

  private now() {
    return (this.o.now ?? Date.now)();
  }

  /** What would be installed, and why not when it cannot be; a plan that can start has an id. */
  async plan(ownerId: string): Promise<IosBridgePlan> {
    const r = await this.o.machine.report(true);
    const base = {
      folder: this.o.dir,
      version: IOS_BRIDGE_VERSION,
      bytes: 0,
      licence: "Apache-2.0",
    };
    const stop = (blocked: IosBridgeBlock): IosBridgePlan => ({ ...base, blocked });
    if (r.os !== "macos") return stop("not-mac");
    if (r.arch !== "arm64") return stop("intel");
    if (!r.ios?.xcode) return stop("no-xcode");
    if (r.ios.bridge && r.ios.bridgeVersion === IOS_BRIDGE_VERSION) return stop("nothing");
    const npm = await (this.o.npm ?? (() => findNpm()))();
    if (!npm) return stop("no-npm");
    let meta: { dist?: { tarball?: string; integrity?: string; unpackedSize?: number } };
    try {
      const res = await (this.o.fetch ?? fetch)(`${REGISTRY}/${IOS_BRIDGE_VERSION}`, {
        signal: AbortSignal.timeout(30_000),
      });
      if (!res.ok) return stop("offline");
      meta = (await res.json()) as typeof meta;
    } catch {
      return stop("offline");
    }
    const { tarball, integrity, unpackedSize } = meta.dist ?? {};
    // Only the registry's own address and a real integrity: nothing else is downloaded.
    if (
      !tarball ||
      !/^https:\/\/registry\.npmjs\.org\//.test(tarball) ||
      !integrity?.startsWith("sha512-")
    )
      return stop("offline");
    for (const [id, s] of this.plans) if (this.now() - s.at > 30 * 60_000) this.plans.delete(id);
    const planId = randomUUID();
    this.plans.set(planId, { ownerId, at: this.now(), tarball, integrity, npm });
    return { ...base, bytes: unpackedSize ?? 0, planId };
  }

  /** The person's yes: the plan they saw runs once, as a job with a real bar. */
  start(ownerId: string, b: { planId: string }): Job {
    const s = this.plans.get(b.planId);
    if (!s || s.ownerId !== ownerId)
      throw new InstallError("no-plan", "This plan is not known any more: look again");
    if (this.running && this.o.jobs.get(ownerId, this.running)?.state === "running")
      throw new InstallError("busy", "An install is already running");
    this.plans.delete(b.planId);
    const job = this.o.jobs.start(
      ownerId,
      "ios_bridge_install",
      ["ios-download", "ios-install"],
      async (h) => {
        const dir = this.o.dir;
        const work = join(dir, ".download");
        const file = join(work, `serve-sim-${IOS_BRIDGE_VERSION}.tgz`);
        try {
          await mkdir(work, { recursive: true });
          h.step("ios-download");
          const res = await (this.o.fetch ?? fetch)(s.tarball, { signal: h.signal });
          if (!res.ok || !res.body)
            throw new InstallError("download", `registry.npmjs.org answered ${res.status}`);
          const total = Number(res.headers.get("content-length")) || null;
          const hash = createHash("sha512");
          let done = 0;
          const count = new Transform({
            transform(chunk: Buffer, _e, next) {
              hash.update(chunk);
              done += chunk.length;
              h.progress(done, total);
              next(null, chunk);
            },
          });
          await pipeline(Readable.fromWeb(res.body as never), count, createWriteStream(file), {
            signal: h.signal,
          });
          const got = `sha512-${hash.digest("base64")}`;
          if (got !== s.integrity)
            throw new InstallError(
              "checksum",
              "The download did not match the registry's checksum: nothing was installed",
            );
          h.step("ios-install");
          const node = dirname(process.execPath);
          const env = {
            ...Object.fromEntries(
              ["HOME", "USER", "LANG", "TMPDIR"].flatMap((k) =>
                (this.o.env?.() ?? process.env)[k] !== undefined
                  ? [[k, (this.o.env?.() ?? process.env)[k]]]
                  : [],
              ),
            ),
            PATH: [node, (this.o.env?.() ?? process.env).PATH ?? ""].join(delimiter),
          };
          const r = await (this.o.run ?? runProgram)(
            s.npm,
            [
              "install",
              file,
              "--prefix",
              dir,
              "--cache",
              join(dir, "npm-cache"),
              "--ignore-scripts",
              "--no-audit",
              "--no-fund",
              "--no-update-notifier",
            ],
            { timeoutMs: 5 * 60_000, signal: h.signal, env },
          );
          if (r.code !== 0)
            throw new InstallError("program", (r.err || r.out || "npm failed").trim().slice(-600));
          if (
            !(await access(iosBridgeScript(dir)).then(
              () => true,
              () => false,
            ))
          )
            throw new InstallError("program", "serve-sim is not where npm put it");
          await this.o.machine.report(true).catch(() => undefined);
          return { folder: dir, version: IOS_BRIDGE_VERSION };
        } finally {
          await rm(work, { recursive: true, force: true }).catch(() => {});
        }
      },
      { folder: this.o.dir },
    );
    this.running = job.id;
    return job;
  }
}

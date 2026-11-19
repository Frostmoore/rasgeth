import { type ChildProcess, spawn } from "node:child_process";
import { existsSync } from "node:fs";
import { mkdir, mkdtemp, rm, writeFile } from "node:fs/promises";
import { createServer } from "node:net";
import { tmpdir } from "node:os";
import { join } from "node:path";
import { fileURLToPath } from "node:url";
import { afterEach, describe, expect, it } from "vitest";

// The real server, built (`pnpm build` runs before the tests), started on a machine whose
// network is unplugged (3.9.1). An installation in use (provider keys, a Telegram bot) used to
// check them one after the other before opening the port: 70 s and more, and the supervisor
// killed it after 90 s, for ever.

const main = fileURLToPath(new URL("../dist/main.js", import.meta.url));
const noNetwork = fileURLToPath(new URL("./fixtures/no-network.mjs", import.meta.url));
const webIndex = fileURLToPath(new URL("../../web/dist/index.html", import.meta.url));

const freePort = () =>
  new Promise<number>((resolve) => {
    const s = createServer().listen(0, "127.0.0.1", () => {
      const { port } = s.address() as { port: number };
      s.close(() => resolve(port));
    });
  });

let child: ChildProcess | undefined;
let dir: string | undefined;
afterEach(async () => {
  if (child && child.exitCode === null && child.signalCode === null) {
    const gone = new Promise((r) => child?.once("exit", r));
    child.kill("SIGKILL");
    await gone;
  }
  child = undefined;
  if (dir) await rm(dir, { recursive: true, force: true, maxRetries: 10, retryDelay: 200 });
  dir = undefined;
});

describe.skipIf(!existsSync(main))("the server without internet", () => {
  it("opens its port and serves the page within seconds", async () => {
    dir = await mkdtemp(join(tmpdir(), "rg-offline-"));
    const data = join(dir, "data");
    await mkdir(data, { recursive: true });
    // Moved into the keychain at start, as on an installation of before.
    await writeFile(
      join(data, "secrets.json"),
      JSON.stringify({
        keys: {
          anthropic: "sk-ant-offline-test-0000",
          openai: "sk-offline-test-0000",
          deepseek: "sk-offline-test-0000",
          gemini: "offline-test-0000",
        },
        telegramToken: "123456789:offline-test-token-0000000000000000",
        githubToken: "ghp_offline0000000000000000000000000000",
      }),
    );
    const port = await freePort();
    let output = "";
    const t0 = Date.now();
    child = spawn(process.execPath, ["--import", noNetwork, main], {
      cwd: dir,
      env: {
        PATH: process.env.PATH ?? "",
        ...(process.env.SystemRoot && { SystemRoot: process.env.SystemRoot }),
        HOME: dir,
        USERPROFILE: dir,
        LOCALAPPDATA: join(dir, "local"),
        DATABASE_URL: "memory:",
        REDGIANT_DATA_DIR: data,
        REDGIANT_PORT: String(port),
        REDGIANT_HOST: "127.0.0.1",
        REDGIANT_TOKEN: "offline-test-token-0123456789",
        REDGIANT_BROWSER: "docker",
      },
      stdio: ["ignore", "pipe", "pipe"],
    });
    child.stdout?.on("data", (d) => {
      output += d;
    });
    child.stderr?.on("data", (d) => {
      output += d;
    });
    const deadline = t0 + 25_000;
    let healthy = false;
    while (!healthy && Date.now() < deadline && child.exitCode === null) {
      healthy = await fetch(`http://127.0.0.1:${port}/api/health`, {
        signal: AbortSignal.timeout(1000),
      })
        .then((r) => r.ok)
        .catch(() => false);
      if (!healthy) await new Promise((r) => setTimeout(r, 200));
    }
    const took = Date.now() - t0;
    expect(healthy, `no answer in ${took} ms:\n${output.slice(-3000)}`).toBe(true);
    // Before 3.9.1 the keys alone took 20 + 10 + 10 + 10 s here, then Telegram hung.
    expect(took).toBeLessThan(25_000);
    if (existsSync(webIndex)) {
      const page = await fetch(`http://127.0.0.1:${port}/`);
      expect(page.status).toBe(200);
      expect(await page.text()).toContain("<html");
    }
  }, 60_000);
});

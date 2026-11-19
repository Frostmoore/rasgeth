import { mkdir, writeFile } from "node:fs/promises";
import { join } from "node:path";
import { afterEach, describe, expect, it, vi } from "vitest";
import { type SetupHooks, SetupService } from "../src/index.js";
import { isOfflineError, NetworkRetries } from "../src/offline.js";
import { startServer } from "./helpers.js";

// Starting without internet (3.9.1): what needs the network at start never holds the port.

const coded = (code: string) => Object.assign(new Error(`connect ${code}`), { code });

describe("isOfflineError", () => {
  it.each([
    ["DNS without an answer", new TypeError("fetch failed", { cause: coded("EAI_AGAIN") }), true],
    ["no route", new TypeError("fetch failed", { cause: coded("ENETUNREACH") }), true],
    [
      "undici's connect timeout",
      new TypeError("fetch failed", { cause: coded("UND_ERR_CONNECT_TIMEOUT") }),
      true,
    ],
    ["AbortSignal.timeout", new DOMException("The operation timed out.", "TimeoutError"), true],
    [
      "the providers' status 0",
      Object.assign(new Error("Request was aborted."), { status: 0 }),
      true,
    ],
    ["a server error", Object.assign(new Error("HTTP 503"), { status: 503 }), true],
    ["too many requests", Object.assign(new Error("HTTP 429"), { status: 429 }), true],
    [
      "grammY's HttpError",
      Object.assign(new Error("Network request for 'getMe' failed!"), {
        name: "HttpError",
        error: coded("ENOTFOUND"),
      }),
      true,
    ],
    ["a wrong key", Object.assign(new Error("HTTP 401 on /models"), { status: 401 }), false],
    ["a refused token", Object.assign(new Error("Forbidden"), { error_code: 403 }), false],
    [
      "Telegram's 404 for a wrong token",
      Object.assign(new Error("Not Found"), { error_code: 404 }),
      false,
    ],
    ["anything else", new Error('Unknown provider "x"'), false],
    ["not an error", "boom", false],
  ])("%s", (_what, err, offline) => {
    expect(isOfflineError(err)).toBe(offline);
  });
});

describe("NetworkRetries", () => {
  it("tries again while the network is missing, then says it is connected", async () => {
    const log: string[] = [];
    const seen: string[][] = [];
    const r = new NetworkRetries({
      delaysMs: [5],
      log: (l) => log.push(l),
      changed: (w) => seen.push(w.map((p) => p.label)),
    });
    let tries = 0;
    const done = await r.run("key:openai", "OpenAI", async () => {
      if (++tries < 3) throw new TypeError("fetch failed", { cause: coded("EAI_AGAIN") });
    });
    expect(done).toBe(true);
    expect(tries).toBe(3);
    expect(seen).toEqual([["OpenAI"], []]);
    expect(log).toEqual([
      "setup: OpenAI: no network (fetch failed); trying again in the background",
      "setup: OpenAI: connected",
    ]);
  });

  it("gives up at once on a refusal", async () => {
    const r = new NetworkRetries({ delaysMs: [5], log: () => {} });
    let tries = 0;
    const done = await r.run("telegram", "Telegram", async () => {
      tries++;
      throw Object.assign(new Error("Unauthorized"), { error_code: 401 });
    });
    expect(done).toBe(false);
    expect(tries).toBe(1);
    expect(r.waiting).toEqual([]);
  });

  it("a part asked for again replaces the one waiting; stop ends every wait", async () => {
    const r = new NetworkRetries({ delaysMs: [60_000], log: () => {} });
    const first = r.run("key:openai", "OpenAI", async () => {
      throw coded("ECONNREFUSED");
    });
    await vi.waitFor(() => expect(r.waiting).toEqual([{ id: "key:openai", label: "OpenAI" }]));
    r.cancel("key:openai");
    expect(r.waiting).toEqual([]);
    const other = r.run("telegram", "Telegram", async () => {
      throw coded("ENOTFOUND");
    });
    await vi.waitFor(() => expect(r.waiting.map((p) => p.id)).toEqual(["telegram"]));
    r.stop();
    expect(
      await Promise.race([
        Promise.all([first, other]),
        new Promise((ok) => setTimeout(ok, 2000, "late")),
      ]),
    ).toEqual([false, false]);
  });
});

describe("NetworkRetries, one try at a time", () => {
  it("never two tries together; one that hangs holds the others back only for its slot", async () => {
    const r = new NetworkRetries({ delaysMs: [5], slotMs: 100, log: () => {} });
    let running = 0;
    let most = 0;
    const tracked = async () => {
      most = Math.max(most, ++running);
      await new Promise((ok) => setTimeout(ok, 10));
      running--;
    };
    const t0 = Date.now();
    void r.run("hangs", "Hangs", () => new Promise(() => {}));
    const done = await Promise.all([
      r.run("a", "A", tracked),
      r.run("b", "B", tracked),
      r.run("c", "C", tracked),
    ]);
    expect(done).toEqual([true, true, true]);
    expect(most).toBe(1);
    // Behind the hanging one for its 100 ms slot, not for ever.
    expect(Date.now() - t0).toBeGreaterThanOrEqual(90);
    expect(Date.now() - t0).toBeLessThan(2000);
    r.stop();
  });
});

type Server = Awaited<ReturnType<typeof startServer>>;
let s: Server | undefined;
afterEach(async () => {
  await s?.close();
  s = undefined;
});

/** Keys, a Telegram bot and a chat, as on an installation in use. */
async function configured(dir: string) {
  await mkdir(join(dir, "data"), { recursive: true });
  await writeFile(
    join(dir, "data", "secrets.json"),
    JSON.stringify({
      keys: { anthropic: "sk-ant-test-0000", openai: "sk-test-0000" },
      telegramToken: "123456:test-token",
      chats: { discord: { token: "discord-test-token" } },
    }),
  );
}

describe("the start without internet", () => {
  it("never waits for the network: the parts that need it connect later, the page says which", async () => {
    let online = false;
    const unplugged = () =>
      online
        ? Promise.resolve()
        : Promise.reject(new TypeError("fetch failed", { cause: coded("EAI_AGAIN") }));
    const applied: string[] = [];
    const hooks: SetupHooks = {
      key: async (id) => {
        await unplugged();
        applied.push(`key:${id}`);
        return [];
      },
      server: async () => [],
      telegram: async () => {
        await unplugged();
        applied.push("telegram");
        return { username: "bot" };
      },
      chat: async (p) => {
        await unplugged();
        applied.push(`chat:${p}`);
      },
      search: async () => {},
      engine: async () => {},
    };
    let setup: SetupService | undefined;
    s = await startServer([], {}, {}, undefined, undefined, async (core, dir) => {
      await configured(dir);
      setup = new SetupService({
        db: core.db,
        core,
        dataDir: join(dir, "data"),
        ownerId: "me",
        hooks,
        retries: new NetworkRetries({
          delaysMs: [20],
          log: () => {},
          changed: (w) => core.setWaitingNetwork(w),
        }),
      });
      await setup.applyAtStartup();
      return { setup };
    });
    const waiting = async () =>
      (await s?.api<{ waitingNetwork?: { label: string }[] }>("GET", "/api/platform"))?.body
        .waitingNetwork ?? [];
    await vi.waitFor(async () =>
      expect((await waiting()).map((p) => p.label).sort()).toEqual([
        "Anthropic (Claude)",
        "Discord",
        "OpenAI (GPT)",
        "Telegram",
      ]),
    );
    expect(applied).toEqual([]);
    // The network comes back: every part connects and the banner goes.
    online = true;
    await vi.waitFor(async () => expect(await waiting()).toEqual([]));
    expect(applied.sort()).toEqual(["chat:discord", "key:anthropic", "key:openai", "telegram"]);
    setup?.stop();
  });

  it("parts that hang do not hold the start", async () => {
    const hang = () => new Promise<never>(() => {});
    const hooks: SetupHooks = {
      key: hang,
      server: async () => [],
      telegram: hang,
      chat: hang,
      search: async () => {},
      engine: async () => {},
    };
    let took = Number.POSITIVE_INFINITY;
    s = await startServer([], {}, {}, undefined, undefined, async (core, dir) => {
      await configured(dir);
      const setup = new SetupService({
        db: core.db,
        core,
        dataDir: join(dir, "data"),
        ownerId: "me",
        hooks,
      });
      const t0 = Date.now();
      await setup.applyAtStartup();
      took = Date.now() - t0;
      setup.stop();
      return { setup };
    });
    expect(took).toBeLessThan(5000);
    expect((await s.api("GET", "/api/health")).status).toBe(200);
  });
});

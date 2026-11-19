// Starting without internet (3.9.1). What the server connects to at start (the providers' keys,
// Telegram, the chats, the subscriptions) is done in the background: the port opens at once, and
// a part that failed for want of a network is tried again until the network is back.
// Seen on a Rasgeth OS container with its network unplugged: the keys were checked one after the
// other (10-20 s each), then Telegram's getMe hung, and the supervisor killed the server after
// 90 s without a health answer, again and again.

/** Error codes of a network that is not there (no route, no DNS, nobody answering). */
const OFFLINE_CODES = new Set([
  "ENOTFOUND",
  "EAI_AGAIN",
  "EAI_FAIL",
  "ECONNREFUSED",
  "ECONNRESET",
  "ECONNABORTED",
  "ETIMEDOUT",
  "ENETUNREACH",
  "ENETDOWN",
  "EHOSTUNREACH",
  "EHOSTDOWN",
  "EPIPE",
  "UND_ERR_CONNECT_TIMEOUT",
  "UND_ERR_HEADERS_TIMEOUT",
  "UND_ERR_BODY_TIMEOUT",
  "UND_ERR_SOCKET",
]);

const OFFLINE_NAMES = new Set([
  "AbortError",
  "TimeoutError",
  "APIConnectionError",
  "APIConnectionTimeoutError",
]);

const SKIPPED = Symbol("skipped");

const OFFLINE_WORDS =
  /fetch failed|network|timed? ?out|aborted|socket hang up|getaddrinfo|connection error/i;

/**
 * True when an error says the other side could not be reached (or answered "try later"), so
 * trying again later may work; false when it answered with a refusal (a wrong key: 401, 403…).
 * Follows `cause` (fetch, the providers) and `error` (grammY's HttpError).
 */
export function isOfflineError(err: unknown): boolean {
  let e: unknown = err;
  for (let depth = 0; e && typeof e === "object" && depth < 8; depth++) {
    const x = e as {
      code?: unknown;
      name?: unknown;
      message?: unknown;
      status?: unknown;
      error_code?: unknown;
      cause?: unknown;
      error?: unknown;
    };
    const status =
      typeof x.status === "number"
        ? x.status
        : typeof x.error_code === "number"
          ? x.error_code
          : undefined;
    if (status !== undefined) {
      // 0: no answer at all (the providers' "API error 0").
      if (status === 0 || status === 408 || status === 429 || status >= 500) return true;
      if (status >= 400) return false;
    }
    if (typeof x.code === "string" && OFFLINE_CODES.has(x.code)) return true;
    if (typeof x.name === "string" && OFFLINE_NAMES.has(x.name)) return true;
    if (typeof x.message === "string" && OFFLINE_WORDS.test(x.message)) return true;
    e = x.cause ?? x.error;
  }
  return false;
}

/** Waits between tries: quick at first, then every five minutes. */
export const RETRY_DELAYS_MS = [15_000, 30_000, 60_000, 120_000, 300_000];

/**
 * One try at a time, each holding the others back at most this long. Without a network every try
 * leaves a name lookup hanging (about 30 s): Node runs at most half its thread pool's lookups at
 * once, so many tries together held back the database's own lookup too (a page left blank).
 */
export const TRY_SLOT_MS = 30_000;

export interface NetworkRetriesOptions {
  delaysMs?: number[];
  /** How long one try holds the others back (default `TRY_SLOT_MS`). */
  slotMs?: number;
  log?: (line: string) => void;
  /** The parts waiting for the network changed (the page shows them). */
  changed?: (waiting: { id: string; label: string }[]) => void;
}

/**
 * Parts of the start that need the internet, run in the background and tried again while the
 * network is missing. A part asked for again (the person saved a new key) replaces the one still
 * waiting, which never runs again.
 */
export class NetworkRetries {
  private readonly waitingParts = new Map<string, string>();
  private readonly generation = new Map<string, number>();
  private readonly timers = new Set<{ timer: NodeJS.Timeout; wake: () => void }>();
  private stopped = false;
  private lane: Promise<void> = Promise.resolve();
  private readonly delays: number[];
  private readonly log: (line: string) => void;

  constructor(private readonly o: NetworkRetriesOptions = {}) {
    this.delays = o.delaysMs?.length ? o.delaysMs : RETRY_DELAYS_MS;
    this.log = o.log ?? ((l) => console.warn(l));
  }

  /** What waits for the network now, by id with its name for people. */
  get waiting(): { id: string; label: string }[] {
    return [...this.waitingParts].map(([id, label]) => ({ id, label }));
  }

  /**
   * Runs `fn` now and again later while it fails for want of a network. Resolves true once it
   * worked, false when it failed otherwise, was replaced or the service stopped; never rejects.
   */
  async run(id: string, label: string, fn: () => Promise<unknown>): Promise<boolean> {
    const gen = (this.generation.get(id) ?? 0) + 1;
    this.generation.set(id, gen);
    const current = () => !this.stopped && this.generation.get(id) === gen;
    for (let attempt = 0; current(); attempt++) {
      try {
        if ((await this.oneAtATime(current, fn)) === SKIPPED || !current()) return false;
        if (this.waitingParts.has(id)) this.log(`setup: ${label}: connected`);
        this.setWaiting(id, undefined);
        return true;
      } catch (err) {
        if (!current()) return false;
        const message = (err as Error)?.message ?? String(err);
        if (!isOfflineError(err)) {
          this.log(`setup: ${label}: ${message}`);
          this.setWaiting(id, undefined);
          return false;
        }
        const delay = this.delays[Math.min(attempt, this.delays.length - 1)] as number;
        if (attempt === 0)
          this.log(`setup: ${label}: no network (${message}); trying again in the background`);
        this.setWaiting(id, label);
        await this.sleep(delay);
      }
    }
    return false;
  }

  /** Forgets a part still waiting (the person changed or removed it). */
  cancel(id: string): void {
    this.generation.set(id, (this.generation.get(id) ?? 0) + 1);
    this.setWaiting(id, undefined);
  }

  /** Every waiting part stops trying (the server is stopping). */
  stop(): void {
    this.stopped = true;
    for (const t of this.timers) {
      clearTimeout(t.timer);
      t.wake();
    }
    this.timers.clear();
  }

  /** Runs `fn` when the tries before it are done, or held the lane for their time. */
  private oneAtATime(current: () => boolean, fn: () => Promise<unknown>): Promise<unknown> {
    const started = this.lane;
    const turn = started.then(() => (current() ? fn() : SKIPPED));
    const slot = this.o.slotMs ?? TRY_SLOT_MS;
    // The slot counts from the moment this try starts, not from when it joined the line.
    this.lane = started.then(() =>
      Promise.race([
        turn.then(
          () => {},
          () => {},
        ),
        new Promise<void>((resolve) => setTimeout(resolve, slot).unref()),
      ]),
    );
    return turn;
  }

  private setWaiting(id: string, label: string | undefined): void {
    const before = this.waitingParts.get(id);
    if (label === undefined) this.waitingParts.delete(id);
    else this.waitingParts.set(id, label);
    if (before !== label) this.o.changed?.(this.waiting);
  }

  private sleep(ms: number): Promise<void> {
    return new Promise((resolve) => {
      const entry = {
        wake: resolve,
        timer: setTimeout(() => {
          this.timers.delete(entry);
          resolve();
        }, ms),
      };
      entry.timer.unref();
      this.timers.add(entry);
    });
  }
}

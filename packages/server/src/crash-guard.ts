// The server's last safety net (3.9.8, after Coder stopped on 2026-11-20 for an SFTP read stream
// nobody listened to). Every stream, socket and program should handle its own errors, and the
// tests fail on any that does not (vitest reports unhandled errors and rejections); this is for the
// ones still missed. A promise rejected with nobody waiting, or the error of one connection or one
// stream (a reset, a broken pipe, an SSH channel gone), is written down and told to the person,
// and the server goes on: the call that owned it already failed or will time out. Any other
// exception leaves the process in a state nobody knows: it is written down and the server stops,
// so the supervisor starts it again and the cut turns resume (`resumeInterrupted`).

/** Error codes of one connection or stream: the rest of the server is untouched by them. */
const ISOLATED_CODES = new Set([
  "ECONNRESET",
  "ECONNREFUSED",
  "ECONNABORTED",
  "EPIPE",
  "ETIMEDOUT",
  "EHOSTUNREACH",
  "ENETUNREACH",
  "ENOTFOUND",
  "EAI_AGAIN",
  "ENOENT",
  "EACCES",
  "ERR_STREAM_PREMATURE_CLOSE",
  "ERR_STREAM_DESTROYED",
  "ERR_STREAM_WRITE_AFTER_END",
  "ERR_STREAM_PUSH_AFTER_EOF",
  "ERR_HTTP_HEADERS_SENT",
  "ERR_SOCKET_CLOSED",
  "ERR_SOCKET_CONNECTION_TIMEOUT",
  "ABORT_ERR",
  "WS_ERR_UNSUPPORTED_MESSAGE_LENGTH",
  "WS_ERR_INVALID_UTF8",
  "WS_ERR_INVALID_OPCODE",
  "WS_ERR_INVALID_CLOSE_CODE",
  "WS_ERR_UNEXPECTED_MASK",
  "WS_ERR_EXPECTED_MASK",
]);

/** Messages of ssh2 and of sockets whose error belongs to one connection. */
const ISOLATED_MESSAGES = [
  /^No response from server$/,
  /^Channel not open/i,
  /^Not connected$/i,
  /^Unable to start subsystem/i,
  /^socket hang up$/i,
  /^read ECONNRESET$/i,
  /^write EPIPE$/i,
  /^This socket has been ended by the other party$/i,
  /^Keepalive timeout$/i,
];

/** Where an error came from in its stack: libraries of one connection. */
const ISOLATED_FRAMES =
  /[\\/]node_modules[\\/](?:\.pnpm[\\/][^\\/]+[\\/]node_modules[\\/])?(?:ssh2|ws|undici)[\\/]/;

/**
 * Whether an exception nobody caught belongs to one connection or stream only (3.9.8), so the
 * server may go on: by its code, its message, or a stack inside ssh2, ws or undici. Anything else
 * is unknown and stops the server. Tested as a table (`test/crash-guard.test.ts`).
 */
export function isolatedError(err: unknown): boolean {
  if (!(err instanceof Error)) return false;
  const code = (err as { code?: unknown }).code;
  if (typeof code === "string" && ISOLATED_CODES.has(code)) return true;
  if (ISOLATED_MESSAGES.some((re) => re.test(err.message))) return true;
  return ISOLATED_FRAMES.test(err.stack ?? "");
}

export type CrashKind = "rejection" | "isolated" | "fatal";

export interface CrashRecord {
  kind: CrashKind;
  message: string;
  stack: string;
}

export interface CrashGuardOptions {
  /** Writes it down (the console, the debug log, the crash file): already without secrets. */
  record(r: CrashRecord): void;
  /** Tells the person, in words (at most once every `tellEveryMs`). */
  tell?(r: CrashRecord): void;
  /** Hides the server's secrets in a text. */
  redact?(text: string): string;
  /** Ends the process for an unknown state (default `process.exit(1)` after a short pause). */
  exit?(code: number): void;
  tellEveryMs?: number;
  now?: () => number;
  /** Where to listen (tests pass their own emitter). */
  target?: Pick<NodeJS.Process, "on" | "off">;
}

/** Installs the handlers; returns how to remove them. */
export function installCrashGuard(o: CrashGuardOptions): () => void {
  const target = o.target ?? process;
  const now = o.now ?? Date.now;
  const every = o.tellEveryMs ?? 10 * 60_000;
  let toldAt: number | undefined;
  const redact = o.redact ?? ((t: string) => t);
  const handle = (kind: CrashKind, err: unknown) => {
    const e = err instanceof Error ? err : new Error(String(err));
    const r: CrashRecord = {
      kind,
      message: redact(e.message),
      stack: redact(e.stack ?? e.message),
    };
    try {
      o.record(r);
    } catch {}
    if (o.tell && (kind === "fatal" || toldAt === undefined || now() - toldAt >= every)) {
      toldAt = now();
      try {
        o.tell(r);
      } catch {}
    }
    if (kind === "fatal") (o.exit ?? ((c) => setTimeout(() => process.exit(c), 1500)))(1);
  };
  const onRejection = (reason: unknown) => handle("rejection", reason);
  const onException = (err: unknown) => handle(isolatedError(err) ? "isolated" : "fatal", err);
  target.on("unhandledRejection", onRejection);
  target.on("uncaughtException", onException);
  return () => {
    target.off("unhandledRejection", onRejection);
    target.off("uncaughtException", onException);
  };
}

/** What the person reads (their language), short: what happened and that it is written down. */
export function crashText(r: CrashRecord, lang: "it" | "en", product: string): string {
  const first = r.message.split("\n")[0]?.slice(0, 200) ?? "";
  if (lang === "it")
    return r.kind === "fatal"
      ? `${product} ha avuto un errore imprevisto e si riavvia: «${first}». Il lavoro interrotto riprende da solo; i dettagli sono nel registro di debug.`
      : `${product} ha avuto un errore in una connessione o in uno strumento e ha continuato: «${first}». I dettagli sono nel registro di debug.`;
  return r.kind === "fatal"
    ? `${product} hit an unexpected error and is restarting: "${first}". The cut work resumes by itself; the details are in the debug log.`
    : `${product} hit an error in one connection or tool and went on: "${first}". The details are in the debug log.`;
}

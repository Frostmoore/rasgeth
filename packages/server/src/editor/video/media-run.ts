// Running ffmpeg, ffprobe and whisper.cpp for the video editor (G41.4): no shell (the file names
// come from the person's project), cancelled with the job's signal (the program is killed and
// the half-written output is the caller's to remove), progress read as it comes. One runner
// shared by the analysis, the derived files and (G41.3) the render: tests replace it.

import { spawn } from "node:child_process";

export interface RunOptions {
  signal?: AbortSignal;
  /** Every line the program writes on stderr (silencedetect, whisper.cpp's progress). */
  onStderrLine?: (line: string) => void;
  /** Every line on stdout (`-progress pipe:1`). */
  onStdoutLine?: (line: string) => void;
  /** Keep stdout whole (ffprobe's JSON). */
  stdout?: boolean;
  env?: NodeJS.ProcessEnv;
  cwd?: string;
}

export interface RunResult {
  stdout: string;
  /** The last 64 KB, for the error message. */
  stderr: string;
}

/** A program that failed: its exit code and the last lines it wrote. */
export class MediaRunError extends Error {
  constructor(
    readonly program: string,
    readonly code: number | null,
    readonly stderr: string,
  ) {
    const last =
      stderr
        .trim()
        .split(/\r?\n/)
        .filter((l) => l.trim())
        .at(-1) ?? "";
    super(`${program} exited with ${code}${last ? `: ${last.slice(0, 300)}` : ""}`);
  }
}

export type MediaRunner = (program: string, args: string[], o?: RunOptions) => Promise<RunResult>;

const TAIL = 64 * 1024;

function lines(push: ((line: string) => void) | undefined) {
  let rest = "";
  return {
    feed(chunk: string) {
      if (!push) return;
      rest += chunk;
      const parts = rest.split(/\r\n|\n|\r/);
      rest = parts.pop() ?? "";
      for (const p of parts) push(p);
    },
    end() {
      if (push && rest) push(rest);
      rest = "";
    },
  };
}

/** Runs a program to its end; an abort kills it and rejects with an `AbortError`. */
export const runMedia: MediaRunner = (program, args, o = {}) =>
  new Promise((resolve, reject) => {
    if (o.signal?.aborted) {
      reject(abortError());
      return;
    }
    const child = spawn(program, args, {
      stdio: ["ignore", "pipe", "pipe"],
      windowsHide: true,
      ...(o.env && { env: o.env }),
      ...(o.cwd && { cwd: o.cwd }),
    });
    let stdout = "";
    let stderr = "";
    const out = lines(o.onStdoutLine);
    const err = lines(o.onStderrLine);
    child.stdout.setEncoding("utf8");
    child.stderr.setEncoding("utf8");
    child.stdout.on("data", (d: string) => {
      if (o.stdout) stdout += d;
      out.feed(d);
    });
    child.stderr.on("data", (d: string) => {
      stderr = (stderr + d).slice(-TAIL);
      err.feed(d);
    });
    const abort = () => child.kill("SIGKILL");
    o.signal?.addEventListener("abort", abort, { once: true });
    child.once("error", (e) => {
      o.signal?.removeEventListener("abort", abort);
      reject(e);
    });
    child.once("close", (code) => {
      o.signal?.removeEventListener("abort", abort);
      out.end();
      err.end();
      if (o.signal?.aborted) reject(abortError());
      else if (code === 0) resolve({ stdout, stderr });
      else reject(new MediaRunError(program.split(/[\\/]/).at(-1) ?? program, code, stderr));
    });
  });

function abortError(): Error {
  const e = new Error("cancelled");
  e.name = "AbortError";
  return e;
}

/** Seconds done from one line of ffmpeg's `-progress` (`out_time_us=…`), or undefined. */
export function progressSeconds(line: string): number | undefined {
  const m = /^out_time_(us|ms)=(\d+)$/.exec(line.trim());
  // ffmpeg writes microseconds under both names (`out_time_ms` is a historical misnomer).
  return m ? Number(m[2]) / 1_000_000 : undefined;
}

/** ffmpeg's arguments for progress lines on stdout, quiet otherwise. */
export const PROGRESS_ARGS = ["-hide_banner", "-nostdin", "-nostats", "-progress", "pipe:1"];

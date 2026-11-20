// 3.9.8: the server's last safety net. The rule is a table (change it first); the guard writes
// every error down, tells the person at most once in a while, goes on for one connection's error
// and stops only for an unknown state.
import { EventEmitter } from "node:events";
import { describe, expect, it } from "vitest";
import WebSocket from "ws";
import { crashText, installCrashGuard, isolatedError } from "../src/crash-guard.js";
import { startServer } from "./helpers.js";

const coded = (message: string, code: string) => Object.assign(new Error(message), { code });
const fromStack = (message: string, frame: string) => {
  const e = new Error(message);
  e.stack = `Error: ${message}\n    at ${frame}`;
  return e;
};

describe("isolatedError", () => {
  it.each([
    // The crash of 2026-11-20 on Coder: ssh2 failing a pending close.
    [
      "ssh2's dropped request",
      fromStack(
        "No response from server",
        "cleanupRequests (/app/node_modules/.pnpm/ssh2@1/node_modules/ssh2/lib/protocol/SFTP.js:2730:15)",
      ),
      true,
    ],
    ["the same message alone", new Error("No response from server"), true],
    ["a reset socket", coded("read ECONNRESET", "ECONNRESET"), true],
    ["a broken pipe", coded("write EPIPE", "EPIPE"), true],
    ["a stream closed early", coded("Premature close", "ERR_STREAM_PREMATURE_CLOSE"), true],
    ["a program that is missing", coded("spawn llama-server ENOENT", "ENOENT"), true],
    [
      "a page's frame too big",
      coded("Max payload size exceeded", "WS_ERR_UNSUPPORTED_MESSAGE_LENGTH"),
      true,
    ],
    [
      "inside ws",
      fromStack("Invalid frame", "Receiver.getInfo (/app/node_modules/ws/lib/receiver.js:1:1)"),
      true,
    ],
    ["an SSH channel gone", new Error("Channel not open"), true],
    // Unknown: the server stops and starts again.
    ["a TypeError in our code", new TypeError("Cannot read properties of undefined"), false],
    [
      "our code's error with a code we do not know",
      coded("Something odd", "ERR_SOMETHING_ELSE"),
      false,
    ],
    ["a string thrown", "boom", false],
    ["nothing", undefined, false],
  ])("%s", (_name, err, isolated) => {
    expect(isolatedError(err)).toBe(isolated);
  });
});

describe("installCrashGuard", () => {
  const setup = () => {
    const target = new EventEmitter();
    const recorded: { kind: string; message: string; stack: string }[] = [];
    const told: string[] = [];
    const exits: number[] = [];
    let t = 0;
    const off = installCrashGuard({
      target: target as never,
      record: (r) => recorded.push(r),
      tell: (r) => told.push(r.kind),
      redact: (s) => s.replaceAll("sk-secret-123456", "[secret]"),
      exit: (c) => exits.push(c),
      tellEveryMs: 1000,
      now: () => t,
    });
    return { target, recorded, told, exits, off, at: (ms: number) => (t = ms) };
  };

  it("a rejection nobody waited for and one connection's error are written down; the server goes on", () => {
    const g = setup();
    g.target.emit("unhandledRejection", new Error("lost sk-secret-123456"));
    g.target.emit("uncaughtException", new Error("No response from server"));
    expect(g.recorded.map((r) => r.kind)).toEqual(["rejection", "isolated"]);
    // Never a secret in what is kept.
    expect(g.recorded[0]?.message).toBe("lost [secret]");
    expect(g.recorded[0]?.stack).not.toContain("sk-secret");
    expect(g.exits).toEqual([]);
    // Told once, not at every error.
    expect(g.told).toEqual(["rejection"]);
    g.at(1500);
    g.target.emit("uncaughtException", coded("x", "EPIPE"));
    expect(g.told).toEqual(["rejection", "isolated"]);
    g.off();
  });

  it("an unknown exception is written down, told, and stops the server", () => {
    const g = setup();
    g.target.emit("unhandledRejection", new Error("first"));
    g.target.emit("uncaughtException", new TypeError("x is undefined"));
    expect(g.recorded.map((r) => r.kind)).toEqual(["rejection", "fatal"]);
    // Told even right after another: the server is going away.
    expect(g.told).toEqual(["rejection", "fatal"]);
    expect(g.exits).toEqual([1]);
    g.off();
    expect(g.target.listenerCount("uncaughtException")).toBe(0);
  });

  it("says it in the person's language", () => {
    const r = { kind: "isolated" as const, message: "No response from server", stack: "" };
    expect(crashText(r, "it", "Rasgeth")).toMatch(/^Rasgeth ha avuto un errore .*continuato/);
    expect(crashText({ ...r, kind: "fatal" }, "en", "Rasgeth")).toMatch(/restarting/);
  });
});

describe("one connection's error stays in it (3.9.8)", () => {
  it("a malformed frame from a page closes that connection; the server answers on", async () => {
    const s = await startServer([]);
    const crashes: unknown[] = [];
    const onCrash = (err: unknown) => crashes.push(err);
    process.on("uncaughtException", onCrash);
    try {
      const ws = new WebSocket(`${s.url.replace(/^http/, "ws")}/ws`);
      ws.on("error", () => {});
      await new Promise((ok) => ws.once("open", ok));
      const closed = new Promise((ok) => ws.once("close", ok));
      // A frame with a reserved opcode (0x3), masked, empty: ws's receiver refuses it.
      (ws as unknown as { _socket: { write(b: Buffer): void } })._socket.write(
        Buffer.from([0x83, 0x80, 0, 0, 0, 0]),
      );
      await closed;
      await new Promise((r) => setTimeout(r, 100));
      expect(crashes).toEqual([]);
      expect((await s.api("GET", "/api/agents")).status).toBe(200);
    } finally {
      process.off("uncaughtException", onCrash);
      await s.close();
    }
  });
});

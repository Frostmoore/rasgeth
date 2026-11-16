import { ReadBuffer, serializeMessage } from "@modelcontextprotocol/sdk/shared/stdio.js";
import type { Transport } from "@modelcontextprotocol/sdk/shared/transport.js";
import type { JSONRPCMessage } from "@modelcontextprotocol/sdk/types.js";
import type { SpawnedProcess } from "@redgiant/tools";

/**
 * MCP over a program started somewhere else (G41.0): a local server in its own sandbox, reached
 * through `Workspace.spawn` (`docker exec -i` in a container) instead of a process of the
 * RedGiant server. `open` starts it (installing its package first, if needed) when the client
 * connects; its standard error is kept short, for the reason a server stops.
 */
export class SpawnTransport implements Transport {
  onclose?: () => void;
  onerror?: (error: Error) => void;
  onmessage?: (message: JSONRPCMessage) => void;

  private proc: SpawnedProcess | undefined;
  private readonly buffer = new ReadBuffer();
  private closed = false;
  private errText = "";

  constructor(
    private readonly open: () => Promise<SpawnedProcess>,
    /** How much of its standard error to keep (the end of it). */
    private readonly keepErr = 2000,
  ) {}

  /** The end of what the program wrote on its standard error. */
  get stderr(): string {
    return this.errText;
  }

  async start(): Promise<void> {
    if (this.proc) throw new Error("SpawnTransport already started");
    const p = await this.open();
    this.proc = p;
    p.stdout.on("data", (chunk: Buffer | string) => {
      this.buffer.append(typeof chunk === "string" ? Buffer.from(chunk) : chunk);
      for (;;) {
        let message: JSONRPCMessage | null;
        try {
          message = this.buffer.readMessage();
        } catch (err) {
          this.onerror?.(err as Error);
          continue;
        }
        if (!message) break;
        this.onmessage?.(message);
      }
    });
    p.stderr.on("data", (chunk: Buffer | string) => {
      this.errText = (this.errText + chunk.toString()).slice(-this.keepErr);
    });
    p.stdin.on?.("error", (err: Error) => this.onerror?.(err));
    void p.exited.then((code) => {
      if (this.closed) return;
      this.closed = true;
      this.buffer.clear();
      if (code !== 0 && code !== null) {
        const tail = this.errText.trim().split("\n").slice(-3).join(" ").slice(-300);
        this.onerror?.(new Error(`The server stopped (exit ${code})${tail ? `: ${tail}` : ""}`));
      }
      this.onclose?.();
    });
  }

  send(message: JSONRPCMessage): Promise<void> {
    const p = this.proc;
    if (!p || this.closed) return Promise.reject(new Error("The server is not running"));
    return new Promise((ok) => {
      if (p.stdin.write(serializeMessage(message))) ok();
      else p.stdin.once("drain", () => ok());
    });
  }

  async close(): Promise<void> {
    if (this.closed) return;
    this.closed = true;
    this.proc?.kill();
    this.buffer.clear();
    this.onclose?.();
  }
}

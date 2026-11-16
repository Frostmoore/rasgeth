import type { OAuthClientProvider } from "@modelcontextprotocol/sdk/client/auth.js";
import { Client } from "@modelcontextprotocol/sdk/client/index.js";
import { StreamableHTTPClientTransport } from "@modelcontextprotocol/sdk/client/streamableHttp.js";
import type { Transport } from "@modelcontextprotocol/sdk/shared/transport.js";
import type { Tool } from "@redgiant/agent";
import type { SpawnedProcess } from "@redgiant/tools";
import { SpawnTransport } from "./mcp-transport.js";

export type McpTransportConfig =
  | {
      type: "stdio";
      command: string;
      args?: string[];
      env?: Record<string, string>;
      /** Inside its sandbox, under the server's own folder (G41.0). */
      cwd?: string;
      /** Where its sandbox may go (G41.0). */
      hosts?: string[];
      /** Of those, the ones that may be at a private address (the person's own database). */
      privateHosts?: string[];
      /** uvx: versions for the package's open dependencies (uv's `--overrides`). */
      overrides?: string[];
    }
  | {
      type: "http";
      url: string;
      headers?: Record<string, string>;
      /** Signs in with the service's OAuth (G24.9): tokens kept by RedGiant, never here. */
      oauth?: boolean;
    };

export interface McpServerConfig {
  name: string;
  transport: McpTransportConfig;
}

const toolName = (server: string, tool: string) =>
  `mcp__${server}__${tool}`.replace(/[^A-Za-z0-9_-]/g, "_").slice(0, 64);

/** A local server cannot start: there is no sandbox for it (no Docker), never a fallback. */
export class NoSandboxError extends Error {
  constructor() {
    super("Local MCP servers run in a sandbox of their own, and this RedGiant has no Docker");
  }
}

/**
 * One MCP server, connected lazily; its tools become agent tools named
 * `mcp__<server>__<tool>`. Only the user configures servers: a stdio server runs in a sandbox of
 * its own (G41.0, `spawn` starts it there), an http one is reached over the network.
 */
export class McpConnection {
  private client: Client | undefined;
  private connecting: Promise<Client> | undefined;

  private http: StreamableHTTPClientTransport | undefined;

  constructor(
    readonly config: McpServerConfig,
    /** For tests: a ready transport instead of the configured one. */
    private readonly transport?: () => Transport,
    private readonly extra: {
      /** OAuth for remote servers that ask for it (`oauth: true`). */
      authProvider?: OAuthClientProvider;
      /** Keys kept apart from the configuration (headers, or variables for a local server). */
      secrets?: { headers?: Record<string, string>; env?: Record<string, string> };
      /**
       * Starts a local server in its sandbox (G41.0) with these variables (its keys among them,
       * for that process only). Without it a local server does not start.
       */
      spawn?: (env: Record<string, string>) => Promise<SpawnedProcess>;
    } = {},
  ) {}

  /** The code the service gave after sign-in: the tokens are fetched and kept. */
  async finishAuth(code: string): Promise<void> {
    if (!this.http) throw new Error("No sign-in is in progress");
    await this.http.finishAuth(code);
    this.connecting = undefined;
  }

  private connect(): Promise<Client> {
    if (this.client) return Promise.resolve(this.client);
    this.connecting ??= (async () => {
      const c = new Client({ name: "redgiant", version: "2" });
      const tc = this.config.transport;
      let t: Transport;
      if (this.transport) t = this.transport();
      else if (tc.type === "stdio") {
        const spawn = this.extra.spawn;
        if (!spawn) throw new NoSandboxError();
        const env = { ...tc.env, ...this.extra.secrets?.env };
        t = new SpawnTransport(() => spawn(env));
      } else
        t = new StreamableHTTPClientTransport(new URL(tc.url), {
          requestInit: { headers: { ...tc.headers, ...this.extra.secrets?.headers } },
          ...(tc.oauth && this.extra.authProvider && { authProvider: this.extra.authProvider }),
        });
      // Kept to finish an OAuth sign-in on the same transport.
      if (t instanceof StreamableHTTPClientTransport) this.http = t;
      try {
        await c.connect(t);
      } catch (err) {
        // What a local server wrote before stopping says why (the caller hides its keys).
        const tail = t instanceof SpawnTransport ? t.stderr.trim().split("\n").slice(-3).join(" ") : "";
        await t.close().catch(() => {});
        if (tail && !(err as Error).message.includes(tail.slice(-60)))
          throw new Error(`${(err as Error).message}: ${tail.slice(-300)}`);
        throw err;
      }
      this.client = c;
      return c;
    })();
    this.connecting.catch(() => {
      this.connecting = undefined;
    });
    return this.connecting;
  }

  async tools(): Promise<Tool[]> {
    const client = await this.connect();
    const { tools } = await client.listTools();
    return tools
      .map(
        (t): Tool => ({
          def: {
            name: toolName(this.config.name, t.name),
            description: `[MCP ${this.config.name}] ${t.description ?? t.name}`,
            inputSchema: t.inputSchema as Record<string, unknown>,
          },
          run: async (input, ctx) => {
            const r = await client.callTool(
              { name: t.name, arguments: (input ?? {}) as Record<string, unknown> },
              undefined,
              {
                ...(ctx.signal && { signal: ctx.signal }),
                timeout: 300_000,
              },
            );
            const content =
              (r.content as
                | { type: string; text?: string; resource?: { uri?: string; text?: string } }[]
                | undefined) ?? [];
            const text = content
              .map((c) =>
                c.type === "text"
                  ? (c.text ?? "")
                  : c.type === "resource"
                    ? (c.resource?.text ?? `[resource ${c.resource?.uri}]`)
                    : `[${c.type}]`,
              )
              .join("\n");
            return {
              content: text || JSON.stringify(r.structuredContent ?? {}),
              isError: Boolean(r.isError),
            };
          },
        }),
      )
      .sort((a, b) => (a.def.name < b.def.name ? -1 : 1));
  }

  async close(): Promise<void> {
    await this.client?.close().catch(() => {});
    this.client = undefined;
    this.connecting = undefined;
  }
}

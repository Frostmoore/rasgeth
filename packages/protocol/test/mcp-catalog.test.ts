import { describe, expect, it } from "vitest";
import {
  catalogConfig,
  MCP_CATALOG,
  type McpCatalogEntry,
  migrateCatalogStdio,
} from "../src/mcp-catalog.js";
import { HOST_PATTERN, isExactVersion, pinOf } from "../src/mcp-local.js";

/** Made-up values for an entry's fields (only to build its command line). */
const inputFor = (e: McpCatalogEntry) =>
  e.auth.type === "fields"
    ? { fields: Object.fromEntries(e.auth.fields.map((f) => [f.env, "https://x.example/a"])) }
    : { key: "postgresql://u:p@db.example:5432/n" };

describe("MCP catalog", () => {
  it("has entries that can be added as they are", () => {
    expect(MCP_CATALOG.length).toBeGreaterThan(10);
    expect(new Set(MCP_CATALOG.map((e) => e.id)).size).toBe(MCP_CATALOG.length);
    for (const e of MCP_CATALOG) {
      // The id becomes the server's name, which the API accepts only in this form.
      expect(e.id).toMatch(/^[a-z0-9][a-z0-9-]{0,30}$/);
      expect(e.description.it.length, e.id).toBeGreaterThan(20);
      expect(e.description.en.length, e.id).toBeGreaterThan(20);
      expect(e.homepage, e.id).toMatch(/^https:\/\//);
      // A server of the person's own (Home Assistant) may be plain http on their network.
      if (e.transport.type === "http") {
        if (!e.userUrl) expect(e.transport.url, e.id).toMatch(/^https:\/\//);
      } else {
        expect(["npx", "uvx"], e.id).toContain(e.transport.command);
        // G41.0: an exact version, never `@latest` nor a package without its version.
        expect(isExactVersion(e.transport.version), e.id).toBe(true);
        expect(e.transport.package, e.id).not.toMatch(/@\d|@latest|==/);
        const args = catalogConfig(e, inputFor(e)).transport;
        expect(JSON.stringify(args), e.id).not.toContain("@latest");
        if (args.type !== "stdio") throw new Error(e.id);
        expect(pinOf(args.command, args.args)?.version, e.id).toBe(e.transport.version);
        // Somewhere to go (the entry's hosts or the person's own address), checked as hosts.
        expect((e.hosts?.length ?? 0) + (e.hostsFrom?.length ?? 0), e.id).toBeGreaterThan(0);
        for (const h of e.hosts ?? []) expect(h, e.id).toMatch(HOST_PATTERN);
        // A key in an environment variable is declared, so adding it warns the person.
        const secretEnv =
          e.auth.type === "env" || (e.auth.type === "fields" && e.auth.fields.some((f) => f.secret));
        expect(e.keyInEnv === true, e.id).toBe(secretEnv);
      }
      if (e.auth.type === "header" || e.auth.type === "env")
        expect(e.auth.keyUrl, e.id).toMatch(/^https:\/\//);
      // OAuth needs an address the browser is sent from, so only online servers.
      if (e.auth.type === "oauth" || e.auth.type === "app")
        expect(e.transport.type, e.id).toBe("http");
      if (e.auth.type === "header") expect(e.transport.type, e.id).toBe("http");
      if (e.auth.type === "env" || e.auth.type === "fields")
        expect(e.transport.type, e.id).toBe("stdio");
      // A guide says the same in both languages, and an app's guide where the return address goes.
      const guide = "guide" in e.auth ? e.auth.guide : undefined;
      if (guide) {
        expect(guide.it.length, e.id).toBeGreaterThan(1);
        expect(guide.it.length, e.id).toBe(guide.en.length);
      }
      if (e.auth.type === "app") {
        expect(guide?.en.join(" "), e.id).toContain("{redirect}");
        expect(guide?.it.join(" "), e.id).toContain("{redirect}");
        expect(e.auth.consoleUrl, e.id).toMatch(/^https:\/\//);
      }
      if (e.userUrl) expect(e.transport.type, e.id).toBe("http");
    }
  });

  it("lists the services' own servers before the community's", () => {
    const official = MCP_CATALOG.filter((e) => e.official).length;
    expect(official).toBeGreaterThan(0);
    expect(MCP_CATALOG.slice(0, official).every((e) => e.official)).toBe(true);
  });

  it("turns an entry into a configuration, with its key apart", () => {
    const base = {
      name: "X",
      official: true,
      category: "code",
      description: { it: "", en: "" },
      homepage: "https://x.example",
    } as const;
    const oauth: McpCatalogEntry = {
      ...base,
      id: "x",
      transport: { type: "http", url: "https://x.example/mcp" },
      auth: { type: "oauth" },
    };
    expect(catalogConfig(oauth)).toEqual({
      transport: { type: "http", url: "https://x.example/mcp", oauth: true },
    });
    const header: McpCatalogEntry = {
      ...oauth,
      auth: { type: "header", header: "Authorization", prefix: "Bearer ", keyUrl: "https://k" },
    };
    expect(() => catalogConfig(header, "  ")).toThrow(/needs a key/);
    expect(catalogConfig(header, " k1 ")).toEqual({
      transport: { type: "http", url: "https://x.example/mcp" },
      secrets: { headers: { Authorization: "Bearer k1" } },
    });
    const env: McpCatalogEntry = {
      ...base,
      id: "y",
      transport: { type: "stdio", command: "npx", package: "y-mcp", version: "1.0.0", args: ["-q"] },
      hosts: ["api.y.example"],
      auth: { type: "env", env: "Y_KEY", keyUrl: "https://k" },
    };
    expect(catalogConfig(env, "k2")).toEqual({
      transport: { type: "stdio", command: "npx", args: ["-y", "y-mcp@1.0.0", "-q"], hosts: ["api.y.example"] },
      secrets: { env: { Y_KEY: "k2" } },
    });
  });

  it("turns the person's own app, their server's address and several fields into a configuration", () => {
    const gmail = MCP_CATALOG.find((e) => e.id === "gmail") as McpCatalogEntry;
    const c = catalogConfig(gmail, { app: { clientId: "id1", clientSecret: "s1" } });
    expect(c.transport).toMatchObject({ type: "http", oauth: true });
    expect(c.secrets?.app).toMatchObject({
      clientId: "id1",
      clientSecret: "s1",
      authParams: { access_type: "offline", prompt: "consent" },
    });
    expect(c.secrets?.app?.scope).toMatch(/gmail\.readonly/);
    expect(() => catalogConfig(gmail, { app: { clientId: "id1" } })).toThrow(/app's details/);
    const ha = MCP_CATALOG.find((e) => e.id === "home-assistant") as McpCatalogEntry;
    expect(catalogConfig(ha, { url: "http://ha.lan:8123/", key: "t" }).transport).toEqual({
      type: "http",
      url: "http://ha.lan:8123/api/mcp",
    });
    expect(() => catalogConfig(ha, { key: "t" })).toThrow(/address/);
    const wp = MCP_CATALOG.find((e) => e.id === "wordpress") as McpCatalogEntry;
    expect(
      catalogConfig(wp, {
        fields: { WP_API_URL: "https://x/wp-json/mcp", WP_API_USERNAME: "m", WP_API_PASSWORD: "p" },
      }).secrets?.env,
    ).toEqual({ WP_API_URL: "https://x/wp-json/mcp", WP_API_USERNAME: "m", WP_API_PASSWORD: "p" });
    expect(() => catalogConfig(wp, { fields: { WP_API_URL: "x" } })).toThrow(/needs/);
    // The person's own site is where WordPress's server goes, even at a private address.
    expect(
      catalogConfig(wp, {
        fields: { WP_API_URL: "https://blog.lan/wp-json/mcp", WP_API_USERNAME: "m", WP_API_PASSWORD: "p" },
      }).transport,
    ).toEqual({
      type: "stdio",
      command: "npx",
      args: ["-y", "@automattic/mcp-wordpress-remote@0.5.5"],
      hosts: ["blog.lan"],
      privateHosts: ["blog.lan"],
    });
    const pg = MCP_CATALOG.find((e) => e.id === "postgres") as McpCatalogEntry;
    expect(catalogConfig(pg, "postgresql://ro:secret@192.168.1.20:5432/shop").transport).toEqual({
      type: "stdio",
      command: "uvx",
      args: ["postgres-mcp@0.3.0", "--access-mode=restricted"],
      hosts: ["192.168.1.20"],
      privateHosts: ["192.168.1.20"],
      overrides: ["pglast==7.20", "mcp[cli]<2"],
    });
  });

  it("moves the local servers added before G41.0 to their pinned command line", () => {
    const table: [string, { type: string; command?: string; args?: string[] }, Record<string, string>, unknown][] = [
      ["shopify-dev", { type: "stdio", command: "npx", args: ["-y", "@shopify/dev-mcp@latest"] }, {}, {
        type: "stdio", command: "npx", args: ["-y", "@shopify/dev-mcp@1.18.0"], hosts: ["shopify.dev", "cdn.shopify.com"],
      }],
      ["wordpress", { type: "stdio", command: "npx", args: ["-y", "@automattic/mcp-wordpress-remote"] },
        { WP_API_URL: "https://blog.example.com/wp-json/mcp/x", WP_API_PASSWORD: "p" }, {
        type: "stdio", command: "npx", args: ["-y", "@automattic/mcp-wordpress-remote@0.5.5"],
        hosts: ["blog.example.com"], privateHosts: ["blog.example.com"],
      }],
      ["postgres", { type: "stdio", command: "uvx", args: ["postgres-mcp", "--access-mode=restricted"] },
        { DATABASE_URI: "postgresql://u:p@db.lan:5432/x" }, {
        type: "stdio", command: "uvx", args: ["postgres-mcp@0.3.0", "--access-mode=restricted"],
        hosts: ["db.lan"], privateHosts: ["db.lan"], overrides: ["pglast==7.20", "mcp[cli]<2"],
      }],
      // Already pinned, not a catalog entry, another package under the same name, remote.
      ["shopify-dev", { type: "stdio", command: "npx", args: ["-y", "@shopify/dev-mcp@1.17.0"] }, {}, undefined],
      ["mine", { type: "stdio", command: "npx", args: ["-y", "mine"] }, {}, undefined],
      ["postgres", { type: "stdio", command: "node", args: ["pg.js"] }, {}, undefined],
      ["notion", { type: "http" }, {}, undefined],
    ];
    for (const [name, t, env, want] of table)
      expect(migrateCatalogStdio(name, t, env), `${name} ${t.args?.join(" ")}`).toEqual(want);
  });
});

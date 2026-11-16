import { describe, expect, it } from "vitest";
import {
  hostOf,
  isExactVersion,
  mcpPlace,
  parseHosts,
  pinOf,
  stdioProblem,
  withVersion,
} from "../src/mcp-local.js";

describe("local MCP servers (G41.0)", () => {
  it("reads the package and its version from a command line", () => {
    const table: [string, string[], ReturnType<typeof pinOf>][] = [
      [
        "npx",
        ["-y", "@shopify/dev-mcp@1.18.0"],
        { runner: "npx", package: "@shopify/dev-mcp", version: "1.18.0", index: 1 },
      ],
      [
        "npx",
        ["-y", "@shopify/dev-mcp@latest"],
        { runner: "npx", package: "@shopify/dev-mcp", tag: "latest", index: 1 },
      ],
      [
        "npx",
        ["-y", "@automattic/mcp-wordpress-remote"],
        { runner: "npx", package: "@automattic/mcp-wordpress-remote", index: 1 },
      ],
      [
        "npx",
        ["--yes", "--registry", "https://r", "foo@^1", "--x"],
        { runner: "npx", package: "foo", tag: "^1", index: 3 },
      ],
      [
        "npx.cmd",
        ["foo@2.0.0-beta.1"],
        { runner: "npx", package: "foo", version: "2.0.0-beta.1", index: 0 },
      ],
      [
        "uvx",
        ["postgres-mcp", "--access-mode=restricted"],
        { runner: "uvx", package: "postgres-mcp", index: 0 },
      ],
      [
        "uvx",
        ["postgres-mcp@0.3.0"],
        { runner: "uvx", package: "postgres-mcp", version: "0.3.0", index: 0 },
      ],
      [
        "uvx",
        ["--python", "3.12", "mcp-x==1.2.3"],
        { runner: "uvx", package: "mcp-x", version: "1.2.3", index: 2 },
      ],
      [
        "uvx",
        ["--from", "mcp-tools==0.4.1", "mcp-git"],
        { runner: "uvx", package: "mcp-tools", version: "0.4.1", index: 1, executable: "mcp-git" },
      ],
      ["node", ["server.js"], undefined],
      ["npx", ["-y"], undefined],
    ];
    for (const [command, args, want] of table)
      expect(pinOf(command, args), args.join(" ")).toEqual(want);
    expect(isExactVersion("1.2.3")).toBe(true);
    for (const v of ["latest", "^1.2.3", "1.2", "1.x", ">=1"])
      expect(isExactVersion(v), v).toBe(false);
  });

  it("puts a new version in the command line, and refuses what is not one", () => {
    expect(withVersion("npx", ["-y", "@shopify/dev-mcp@1.18.0", "--x"], "1.19.0")).toEqual([
      "-y",
      "@shopify/dev-mcp@1.19.0",
      "--x",
    ]);
    expect(withVersion("npx", ["-y", "foo"], "1.0.0")).toEqual(["-y", "foo@1.0.0"]);
    expect(withVersion("uvx", ["postgres-mcp", "--a"], "0.3.0")).toEqual([
      "postgres-mcp@0.3.0",
      "--a",
    ]);
    expect(withVersion("uvx", ["--from", "t==1.0.0", "x"], "1.1.0")).toEqual([
      "--from",
      "t==1.1.0",
      "x",
    ]);
    expect(() => withVersion("npx", ["-y", "foo"], "latest")).toThrow(/exact/);
    expect(() => withVersion("node", ["s.js"], "1.0.0")).toThrow(/npx or uvx/);
  });

  it("says why a server added by hand cannot run in its sandbox", () => {
    const table: [Parameters<typeof stdioProblem>[0], ReturnType<typeof stdioProblem>][] = [
      [{ command: "npx", args: ["-y", "foo@1.0.0"] }, undefined],
      [{ command: "uvx", args: ["bar"] }, undefined],
      [{ command: "node", args: ["server.mjs"] }, undefined],
      [{ command: "node", args: ["/workspace/server.mjs"] }, undefined],
      [{ command: "./run.sh" }, undefined],
      [{ command: "python3", args: ["-m", "srv", "--url=https://x"] }, undefined],
      [{ command: "docker", args: ["run", "-i", "mcp/x"] }, "docker"],
      [{ command: "podman", args: ["run"] }, "docker"],
      [{ command: "/usr/local/bin/my-mcp" }, "host-path"],
      [{ command: "C:\\Tools\\mcp.exe" }, "host-path"],
      [{ command: "my-mcp" }, "command"],
      [{ command: "deno", args: ["run", "x.ts"] }, "command"],
      [{ command: "node", args: ["/home/me/mcp/index.js"] }, "host-path"],
      [{ command: "node", args: ["--config=/etc/mcp.json", "s.js"] }, "host-path"],
      [{ command: "node", args: ["~/mcp/index.js"] }, "host-path"],
      [{ command: "node", args: ["s.js"], cwd: "/home/me/mcp" }, "host-path"],
      [{ command: "node", args: ["s.js"], cwd: "/workspace" }, undefined],
    ];
    for (const [t, want] of table) expect(stdioProblem(t), JSON.stringify(t)).toBe(want);
  });

  it("reads hosts from addresses and from what the person typed", () => {
    expect(hostOf("https://Blog.example.com/wp-json/mcp")).toBe("blog.example.com");
    expect(hostOf("postgresql://u:p@db.lan:5432/x")).toBe("db.lan");
    expect(hostOf("postgresql://u:p@[::1]:5432/x")).toBe("::1");
    expect(hostOf("")).toBeUndefined();
    expect(
      parseHosts("api.example.com, *.cdn.example.com\nhttps://x.org/a  bad_host! api.example.com"),
    ).toEqual({
      hosts: ["api.example.com", "*.cdn.example.com", "x.org"],
      wrong: ["bad_host!"],
    });
  });

  it("decides where a local server runs: sandbox, computer, or waiting (a table)", () => {
    const table: [Parameters<typeof mcpPlace>[0], ReturnType<typeof mcpPlace>][] = [
      // Docker here: always the sandbox, never the computer, whatever was accepted.
      [{ docker: true, hostOk: false, keyed: false, envOk: false }, { run: "sandbox" }],
      [{ docker: true, hostOk: true, keyed: false, envOk: false }, { run: "sandbox" }],
      [{ docker: true, hostOk: false, keyed: true, envOk: false }, { wait: "key" }],
      [{ docker: true, hostOk: false, keyed: true, envOk: true }, { run: "sandbox" }],
      [
        { docker: true, hostOk: true, keyed: false, envOk: false, problem: "host-path" },
        { wait: "host-path" },
      ],
      [
        { docker: true, hostOk: true, keyed: false, envOk: false, problem: "docker" },
        { wait: "docker" },
      ],
      // No Docker: on the computer only with the person's yes for that server.
      [{ docker: false, hostOk: false, keyed: false, envOk: false }, { wait: "host" }],
      [{ docker: false, hostOk: false, keyed: true, envOk: true }, { wait: "host" }],
      [{ docker: false, hostOk: true, keyed: false, envOk: false }, { run: "host" }],
      [{ docker: false, hostOk: true, keyed: true, envOk: false }, { wait: "key" }],
      [{ docker: false, hostOk: true, keyed: true, envOk: true }, { run: "host" }],
      // What a sandbox could not run still runs on the computer once accepted.
      [
        { docker: false, hostOk: true, keyed: false, envOk: false, problem: "host-path" },
        { run: "host" },
      ],
    ];
    for (const [o, want] of table) expect(mcpPlace(o), JSON.stringify(o)).toEqual(want);
  });
});

// Incremental CI: which changes count as "tests only", as a table. Change the table first, then
// scripts/ci-test-only.mjs. Unknown means everything runs.

import { execFileSync } from "node:child_process";
import { describe, expect, it } from "vitest";
// @ts-expect-error plain JavaScript, no types
import { isTestOnly, isTestPath, parsePaths } from "../ci-test-only.mjs";

const testOnly: string[] = [
  "packages/server/test/foo.test.ts",
  "packages/web/test/components/Chat.test.tsx",
  "packages/protocol/test/fixtures/resolve/a.json",
  "packages/server/test/helpers/pglite.ts",
  "packages/server/test/fixtures/video/clip.mp4",
  "apps/companion/test/widget_test.dart",
  "apps/companion/test/goldens/home.png",
  "apps/companion/test/fixtures/x.json",
  "apps/companion/integration_test/app_test.dart",
  "scripts/test/name-audit.test.ts",
];

const notTestOnly: string[] = [
  "packages/server/src/index.ts",
  "packages/server/src/index.test.ts", // beside the sources: tsc would compile and ship it
  "packages/server/package.json",
  "packages/server/test.ts",
  "packages/test/x.ts",
  "package.json",
  "pnpm-lock.yaml",
  "tsconfig.base.json",
  "vitest.config.ts",
  "vitest.setup.ts",
  ".github/workflows/ci.yml",
  "packaging/os/test/stack.test.ts", // the OS image is made from packaging/os
  "packaging/update/test/pack.test.ts",
  "packaging/release-kind.json",
  "apps/companion/lib/main.dart",
  "apps/companion/pubspec.yaml",
  "apps/companion/tool/gen.dart",
  "apps/companion/third_party/webview_all_linux/linux/test/a.cc",
  "docker/redgiant.Dockerfile",
  "README.md",
  "memory/roadmap.md",
  "scripts/ci-test-only.mjs",
  "scripts/name-audit.mjs",
  "../etc/passwd",
  "packages/server/test/../src/x.ts",
  "/packages/server/test/a.ts",
  "packages/server/test//a.ts",
  "packages/server/test/a b\nc.ts",
  "packages/server/test/a\\b.ts",
  "",
];

describe("isTestPath", () => {
  it.each(testOnly)("test path: %s", (p) => expect(isTestPath(p)).toBe(true));
  it.each(notTestOnly)("not a test path: %j", (p) => expect(isTestPath(p)).toBe(false));
  it("refuses what is not a string", () => {
    expect(isTestPath(undefined as unknown as string)).toBe(false);
    expect(isTestPath(null as unknown as string)).toBe(false);
  });
});

describe("isTestOnly", () => {
  it("is true when every path is a test path", () => {
    expect(isTestOnly(testOnly)).toBe(true);
  });
  it("is false for an empty list (unknown: run everything)", () => {
    expect(isTestOnly([])).toBe(false);
  });
  it("is false when a single path is not a test", () => {
    for (const p of notTestOnly.filter(Boolean)) {
      expect(isTestOnly([...testOnly, p])).toBe(false);
    }
  });
  it("is false for something that is not a list", () => {
    expect(isTestOnly("packages/a/test/x.ts" as unknown as string[])).toBe(false);
  });
});

describe("parsePaths", () => {
  it("splits git's output, ignoring blank lines and CRs", () => {
    expect(parsePaths("a\r\n\nb\n")).toEqual(["a", "b"]);
  });
});

describe("the command line", () => {
  const run = (args: string[], input = "") =>
    execFileSync("node", ["scripts/ci-test-only.mjs", ...args], { input, encoding: "utf8" }).trim();
  it("reads paths from stdin", () => {
    expect(run([], "packages/server/test/a.test.ts\napps/companion/test/b.dart\n")).toBe("true");
    expect(run([], "packages/server/test/a.test.ts\npackages/server/src/a.ts\n")).toBe("false");
    expect(run([], "")).toBe("false");
  });
  it("reads paths from arguments", () => {
    expect(run(["packages/web/test/a.test.tsx"])).toBe("true");
    expect(run(["package.json"])).toBe("false");
  });
});

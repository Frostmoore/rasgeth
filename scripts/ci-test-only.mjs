#!/usr/bin/env node
// Incremental CI: is a change made of test files only? Then the product is byte-identical to the
// one an earlier green run built, and the workflows reuse that run's packages and images instead
// of building them again (scripts/rel-incremental.md, .github/workflows/*.yml `plan` jobs).
//
// Conservative on purpose: a path is "test-only" only when it matches one of the shapes below;
// anything else, an empty list, or anything odd (absolute path, `..`, a quote or newline) is not,
// and the workflows then run everything. Nothing under `packaging/` ever counts (the OS image and
// the installers are made from it), nor does anything under a package's `src/`, a `*.test.ts`
// beside the sources included (tsc compiles `src`, so such a file would ship).
//
//   git diff --name-only <old>..HEAD | node scripts/ci-test-only.mjs      -> prints true or false
//   node scripts/ci-test-only.mjs path/a path/b                          -> the same, from arguments
// The exit code is 0 when it answered; 2 on a usage error (the workflows treat it as false).

import { readFileSync } from "node:fs";

/** The shapes of a test-only path (the only places tests and their data live). */
const TEST_ONLY = [
  // packages/<name>/test/** : the tests, their fixtures and helpers. Never built (tsconfig: src).
  /^packages\/[^/]+\/test\/.+/,
  // The Flutter app's tests (flutter test, integration_test), goldens and fixtures. `tool/` and
  // `third_party/` are not here: they are build inputs.
  /^apps\/companion\/test\/.+/,
  /^apps\/companion\/integration_test\/.+/,
  // The scripts' own tests.
  /^scripts\/test\/.+/,
];

/** True when this one path is a test file or test data and nothing the product is made from. */
export function isTestPath(path) {
  if (typeof path !== "string" || path === "") return false;
  if (path.startsWith("/") || path.includes("\\") || /[\0\r\n"'`$]/.test(path)) return false;
  if (path.split("/").some((part) => part === ".." || part === "." || part === "")) return false;
  return TEST_ONLY.some((re) => re.test(path));
}

/** True when the list is not empty and every path in it is a test path. */
export function isTestOnly(paths) {
  if (!Array.isArray(paths) || paths.length === 0) return false;
  return paths.every(isTestPath);
}

/** Paths from text, one per line (git's `--name-only`); blank lines ignored. */
export function parsePaths(text) {
  return text
    .split("\n")
    .map((line) => line.replace(/\r$/, ""))
    .filter((line) => line !== "");
}

if (process.argv[1]?.endsWith("ci-test-only.mjs")) {
  try {
    const args = process.argv.slice(2);
    const paths = args.length > 0 ? args : parsePaths(readFileSync(0, "utf8"));
    console.log(isTestOnly(paths) ? "true" : "false");
  } catch (e) {
    console.error(`ci-test-only: ${e instanceof Error ? e.message : e}`);
    process.exit(2);
  }
}

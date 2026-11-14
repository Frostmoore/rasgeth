#!/usr/bin/env node
// RedGiant OS (3.7.4): the images are built only when the OS changes, so not every release carries
// them. This finds the newest published release that does (not a draft, not a pre-release, a vX.Y.Z
// tag, SHA256SUMS-os and the x86_64 qcow2 among its assets), and says whether the OS changed since
// it: packaging/os, the OS helper, os.yml and the update key built into the images (git diff
// against that tag). Only Node's own modules, and git.
//
//   node packaging/os/os-release.mjs [--repo owner/name] [--sha <commit>] [--below <x.y.z>]
//     prints `tag=<tag or empty>` and `changed=<true|false>` (GitHub output lines); no release
//     with images, or a tag git does not know: changed=true (build them).
//     --below: only releases older than this version (the release being made is never its own).
import { execFileSync } from "node:child_process";

/** What decides the images: when one of these differs from the images' release, they are built. */
export const OS_PATHS = [
  "packaging/os",
  "packages/server/helpers",
  ".github/workflows/os.yml",
  "packages/server/src/release-key.ts",
];

const VERSION = /^v(\d+)\.(\d+)\.(\d+)$/;
const parts = (tag) => VERSION.exec(tag)?.slice(1).map(Number) ?? null;
const older = (a, b) => {
  for (let i = 0; i < 3; i++) if (a[i] !== b[i]) return a[i] < b[i];
  return false;
};

/** The newest release (by version) that carries RedGiant OS's images, or null. */
export function latestOsRelease(releases, below = "") {
  const limit = below ? parts(`v${below.replace(/^v/, "")}`) : null;
  let best = null;
  for (const r of releases ?? []) {
    if (r.draft || r.prerelease) continue;
    const v = parts(r.tag_name ?? "");
    if (!v || (limit && !older(v, limit))) continue;
    const names = new Set((r.assets ?? []).map((a) => a.name));
    const version = v.join(".");
    if (!names.has("SHA256SUMS-os") || !names.has(`redgiant-os-${version}-x86_64.qcow2`)) continue;
    if (!best || older(best.v, v)) best = { v, tag: r.tag_name };
  }
  return best?.tag ?? null;
}

async function releases(repo) {
  const out = [];
  const headers = { Accept: "application/vnd.github+json" };
  if (process.env.GH_TOKEN) headers.Authorization = `Bearer ${process.env.GH_TOKEN}`;
  for (let page = 1; page <= 5; page++) {
    const r = await fetch(
      `https://api.github.com/repos/${repo}/releases?per_page=100&page=${page}`,
      {
        headers,
      },
    );
    if (!r.ok) throw new Error(`releases of ${repo}: ${r.status}`);
    const list = await r.json();
    out.push(...list);
    if (list.length < 100) break;
  }
  return out;
}

/** True when the OS's files differ between `tag` and `sha` (or git cannot tell). */
export function osChanged(tag, sha, cwd = process.cwd()) {
  try {
    execFileSync("git", ["cat-file", "-e", `${tag}^{commit}`], { cwd, stdio: "ignore" });
    execFileSync("git", ["diff", "--quiet", tag, sha, "--", ...OS_PATHS], { cwd, stdio: "ignore" });
    return false;
  } catch {
    return true;
  }
}

if (process.argv[1]?.endsWith("os-release.mjs")) {
  const arg = (name, fallback) => {
    const i = process.argv.indexOf(name);
    return i > 0 ? process.argv[i + 1] : fallback;
  };
  const repo = arg("--repo", process.env.GITHUB_REPOSITORY || "Frostmoore/redgiant2");
  const sha = arg("--sha", "HEAD");
  const tag = latestOsRelease(await releases(repo), arg("--below", ""));
  const changed = tag ? osChanged(tag, sha) : true;
  console.log(`tag=${tag ?? ""}`);
  console.log(`changed=${changed}`);
}

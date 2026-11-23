#!/usr/bin/env node
// A real-Mac trial of the iOS simulators (3.12.2): run it on a Mac node (macOS, Apple silicon,
// Xcode) after `pnpm build`. It installs serve-sim into a throw-away folder (only with --yes: that
// is the person's yes to the download), then lists the simulators, boots one (or uses the booted
// one), opens its screen through the bridge, saves a frame, taps the middle, presses home, takes a
// `simctl` screenshot, and cleans up: the bridge stopped, a simulator it booted shut down again,
// the temp folder removed. Nothing outside the temp folder is written.
//
// It also prints Settings' first accessibility elements and types an accented string plus an emoji
// into Safari's address bar through the pasteboard (watch whether iOS asks to allow the paste).
//
//   node scripts/ios-trial.mjs --yes [--udid <udid>] [--keep]
import { mkdtemp, rm, writeFile } from "node:fs/promises";
import { tmpdir } from "node:os";
import { join } from "node:path";
import { pathToFileURL } from "node:url";

const args = process.argv.slice(2);
const flag = (n) => args.includes(`--${n}`);
const opt = (n) => (args.includes(`--${n}`) ? args[args.indexOf(`--${n}`) + 1] : undefined);
if (process.platform !== "darwin") {
  console.error("This trial runs on a Mac only.");
  process.exit(2);
}
if (!flag("yes")) {
  console.error(
    "serve-sim (Apache-2.0) will be downloaded from the npm registry into a temp folder and removed at the end.\nAdd --yes to say yes.",
  );
  process.exit(2);
}

const dist = new URL("../packages/server/dist/", import.meta.url);
const load = (p) => import(pathToFileURL(new URL(p, dist).pathname).href);
const { IosHost } = await load("emulators/ios.js");
const { IosBridgeInstaller } = await load("emulators/install-ios.js");
const { gatherEmulatorFacts, iosBridgeScript } = await load("emulators/gather.js");
const { detectEmulators } = await load("emulators/detect.js");
const { parseAxTree } = await load("emulators/tools.js");
const { Jobs } = await load("jobs.js");

const sleep = (ms) => new Promise((r) => setTimeout(r, ms));
const step = (s) => console.log(`\n== ${s}`);
const work = await mkdtemp(join(tmpdir(), "rg-ios-trial-"));
const dir = join(work, "ios-bridge");
let host;
let bootedByUs;
let ok = false;
try {
  step("detect");
  const report = async () =>
    detectEmulators(await gatherEmulatorFacts({ maxRunning: 2, iosBridgeDir: dir }));
  const r = await report();
  console.log(JSON.stringify({ os: r.os, arch: r.arch, ios: r.ios, missing: r.missing }, null, 2));
  if (!r.ios?.xcode) throw new Error("No Xcode on this Mac");

  step("install the bridge into the temp folder");
  const jobs = new Jobs();
  const installer = new IosBridgeInstaller({ jobs, machine: { report }, dir });
  const plan = await installer.plan("trial");
  console.log(plan);
  if (plan.blocked && plan.blocked !== "nothing") throw new Error(`Blocked: ${plan.blocked}`);
  const job = installer.start("trial", { planId: plan.planId });
  for (;;) {
    const j = jobs.get("trial", job.id);
    if (j && j.state !== "running") {
      console.log(`job ${j.state}`, j.error ?? "");
      if (j.state !== "done") throw new Error("install failed");
      break;
    }
    await sleep(500);
  }

  step("list");
  host = new IosHost({ bridge: async () => iosBridgeScript(dir) });
  const sims = await host.simulators();
  console.table(sims);
  const pick =
    sims.find((s) => s.udid === opt("udid")) ??
    sims.find((s) => s.state === "booted") ??
    sims.find((s) => /iPhone/.test(s.name));
  if (!pick) throw new Error("No iOS simulator here");
  console.log("using", pick.name, pick.udid, pick.state);

  step("boot");
  if (pick.state !== "booted") {
    await host.boot(pick.udid);
    bootedByUs = pick.udid;
  }
  console.log((await host.devices()).map((d) => `${d.model} ${d.serial}`));

  step("screen, tap, home");
  let frames = 0;
  let first;
  const ended = [];
  const screen = await host.screen(
    pick.udid,
    (f) => {
      frames++;
      first ??= f;
    },
    (e) => ended.push(e),
  );
  for (let i = 0; i < 50 && !first; i++) await sleep(200);
  if (!first) throw new Error("No frame arrived in 10 s");
  await writeFile(join(work, "frame.jpg"), Buffer.from(first.data, "base64"));
  console.log(`first frame ${first.width}x${first.height}, saved in ${join(work, "frame.jpg")}`);
  await screen.input({ kind: "tap", x: 0.5, y: 0.5 });
  await screen.input({ kind: "button", button: "home" });
  await screen.input({ kind: "swipe", x: 0.5, y: 0.7, x2: 0.5, y2: 0.3, ms: 300 });
  await sleep(1500);
  console.log(`frames so far: ${frames}`);

  step("accessibility: the first elements of Settings");
  const readAx = async () => parseAxTree(await host.shell(pick.udid, ["ax"]));
  console.log(await host.shell(pick.udid, ["launch", "com.apple.Preferences"]));
  await sleep(2500);
  const ax = await readAx();
  console.log("elements", ax.length);
  for (const e of ax.slice(0, 15))
    console.log(`  [${e.ref}] ${e.cls} ${JSON.stringify(e.text)} at ${e.x},${e.y}`);
  if (!ax.length) throw new Error("The accessibility snapshot has no elements");

  step("text in any language: pasteboard and Cmd+V into Safari's address bar");
  const wanted = "Perché sì, è così 😀";
  await host.shell(pick.udid, ["launch", "com.apple.mobilesafari"]);
  await sleep(3000);
  const snap = await readAx();
  const field = snap.find((e) => /TextField|SearchField|Address|URL/i.test(`${e.cls} ${e.text}`));
  if (!field) console.log("  no address bar found: tap a text field by hand within 8 s");
  else await screen.input({ kind: "tap", x: field.x, y: field.y });
  await sleep(field ? 1500 : 8000);
  await screen.input({ kind: "text", text: wanted });
  await sleep(1500);
  const after = await readAx();
  const seen = after.some((e) => `${e.desc} ${e.text}`.includes("Perché sì"));
  console.log(
    seen
      ? "  the text shows in the field: OK (note whether iOS asked to allow the paste)"
      : "  the text is NOT in the accessibility tree: look for a paste prompt on the screen",
  );
  await writeFile(join(work, "after-text.json"), JSON.stringify(after, null, 1));
  console.log("size now", screen.size());
  await screen.close();
  console.log("screen ended callbacks:", ended);
  if (frames < 2) throw new Error("Expected more than one frame after the gestures");
  ok = true;
} catch (e) {
  console.error("TRIAL FAILED:", e instanceof Error ? e.message : e);
} finally {
  step("clean up");
  host?.close();
  if (bootedByUs) {
    await host?.stop(bootedByUs).catch((e) => console.error("shutdown:", e.message));
    console.log("shut down", bootedByUs);
  }
  if (flag("keep")) console.log("kept", work);
  else await rm(work, { recursive: true, force: true });
  console.log(ok ? "\nTRIAL OK" : "\nTRIAL FAILED");
  process.exit(ok ? 0 : 1);
}

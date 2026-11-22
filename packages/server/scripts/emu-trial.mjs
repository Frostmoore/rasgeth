// Phase 2 trial: AndroidHost against a real device, through adb's server on ADB_PORT (e.g. an ssh
// tunnel to another machine's adb). Usage: node emu-trial.mjs <ffmpeg> <outdir> [port]
import { mkdirSync, writeFileSync } from "node:fs";
import { AndroidHost } from "../dist/emulators/android.js";

const [ffmpeg, out, port = "5037"] = process.argv.slice(2);
mkdirSync(out, { recursive: true });
const log = (...a) => console.log(new Date().toISOString().slice(11, 23), ...a);
const sleep = (ms) => new Promise((r) => setTimeout(r, ms));
const host = new AndroidHost({
  tools: async () => ({}),
  ffmpeg: async () => ffmpeg,
  port: Number(port),
});
const devices = await host.devices();
log("devices", devices);
const dev = devices.find((d) => d.kind === "emulator" && d.state === "device");
let frames = 0;
let lastAt = 0;
const waiters = [];
let last;
const t0 = performance.now();
let first = 0;
const screen = await host.screen(
  dev.serial,
  (f) => {
    frames++;
    lastAt = performance.now();
    last = f;
    if (!first) first = lastAt - t0;
    for (const w of waiters.splice(0)) w(lastAt);
  },
  (err) => log("ended", err),
);
const next = () => new Promise((r) => waiters.push(r));
const quiet = async (ms = 700) => {
  while (performance.now() - lastAt < ms) await sleep(50);
};
await sleep(2500);
log("first JPEG after", Math.round(first), "ms; size", screen.size(), "frames", frames);
writeFileSync(`${out}/01-start.jpg`, Buffer.from(last.data, "base64"));
await screen.input({ kind: "button", button: "home" });
await sleep(1500);
await host.shell(dev.serial, ["am", "start", "-a", "android.intent.action.DIAL"]);
await sleep(2500);
const lat = [];
for (let i = 0; i < 10; i++) {
  await quiet();
  const s = performance.now();
  const f = next();
  await screen.input({ kind: "tap", x: 0.5, y: 1480 / 2400 });
  lat.push(Math.round((await Promise.race([f, sleep(3000).then(() => Number.NaN)])) - s));
}
lat.sort((a, b) => a - b);
log("tap->JPEG ms", lat, "median", lat[5]);
await sleep(800);
writeFileSync(`${out}/02-dialer.jpg`, Buffer.from(last.data, "base64"));
await screen.input({ kind: "text", text: "123" });
await sleep(800);
const t = performance.now();
const xml = await host.shell(dev.serial, ["uiautomator", "dump", "/dev/tty"]);
log("uiautomator dump ms", Math.round(performance.now() - t), xml.length, "chars");
await screen.input({ kind: "button", button: "home" });
await sleep(800);
await host.shell(dev.serial, ["am", "start", "-a", "android.settings.SETTINGS"]);
await sleep(2000);
const r0 = performance.now();
await screen.input({ kind: "rotate" });
while (screen.size().width < screen.size().height && performance.now() - r0 < 6000) await sleep(50);
log("rotate ms", Math.round(performance.now() - r0), screen.size());
await sleep(1500);
writeFileSync(`${out}/03-landscape.jpg`, Buffer.from(last.data, "base64"));
await screen.input({ kind: "rotate" });
await sleep(1500);
await screen.input({ kind: "swipe", x: 0.5, y: 0.8, x2: 0.5, y2: 0.3 });
await sleep(1000);
const m0 = frames;
const ms0 = performance.now();
for (let i = 0; i < 4; i++) {
  await screen.input({ kind: "swipe", x: 0.5, y: 0.8, x2: 0.5, y2: 0.3, ms: 250 });
  await sleep(300);
  await screen.input({ kind: "swipe", x: 0.5, y: 0.3, x2: 0.5, y2: 0.8, ms: 250 });
  await sleep(300);
}
log(
  "moving JPEG fps",
  ((frames - m0) / ((performance.now() - ms0) / 1000)).toFixed(1),
  "last",
  last.width,
  "x",
  last.height,
  Math.round((last.data.length * 0.75) / 1024),
  "KB",
);
writeFileSync(`${out}/04-last.jpg`, Buffer.from(last.data, "base64"));
await screen.input({ kind: "button", button: "home" });
await screen.close();
log("done");
process.exit(0);

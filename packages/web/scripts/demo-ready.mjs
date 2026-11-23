// Starts the demo server and checks that it reaches «ready» (its final JSON line, the one the
// shots read) within a time limit: a scripted tour that loops makes it hang there.
// Usage: node packages/web/scripts/demo-ready.mjs [seconds=240] [port=7898]
import { spawn } from "node:child_process";
import { dirname, join } from "node:path";
import { fileURLToPath } from "node:url";

const limit = Number(process.argv[2] ?? 240) * 1000;
const port = process.argv[3] ?? "7898";
const demo = join(dirname(fileURLToPath(import.meta.url)), "demo-server.mjs");
const started = Date.now();
const child = spawn(process.execPath, [demo, port], {
  stdio: ["ignore", "pipe", "inherit"],
  env: { ...process.env, DEMO_HOST: "127.0.0.1" },
});
let out = "";
const finish = (code, text) => {
  clearTimeout(timer);
  child.kill("SIGKILL");
  console.log(text);
  process.exit(code);
};
const timer = setTimeout(
  () => finish(1, `demo NOT ready after ${limit / 1000} s (a scripted tour is probably looping)`),
  limit,
);
child.on("exit", (code) => finish(1, `demo exited early (${code})`));
child.stdout.on("data", (d) => {
  out += d;
  // The last line is the one with the url and the token.
  for (const line of out.split("\n")) {
    try {
      const o = JSON.parse(line);
      if (o.url && o.token) return finish(0, `demo ready in ${(Date.now() - started) / 1000} s`);
    } catch {}
  }
});

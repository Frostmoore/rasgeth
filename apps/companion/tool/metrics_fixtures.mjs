// Writes test/fixtures/metrics_vectors.json: `message.assistant` events' metrics (the shape of
// `MessageMetrics` in @redgiant/protocol) and the strings the page's MetricsBar makes of them with
// its own formatters (packages/web/src/format.ts), so test/metrics_test.dart checks that the app
// writes the very same numbers (G40.17). The clock is the page's `toLocaleTimeString` in UTC.
//
//   node --experimental-strip-types apps/companion/tool/metrics_fixtures.mjs
import { writeFileSync } from "node:fs";
import { dirname, join } from "node:path";
import { fileURLToPath, pathToFileURL } from "node:url";

const here = dirname(fileURLToPath(import.meta.url));
const { kTokens, duration, usd, localModelName } = await import(
  pathToFileURL(join(here, "../../../packages/web/src/format.ts")).href
);

const at = (s) => `2026-11-16T${s}.000Z`;
// Real figures: a cached Anthropic turn, a local llama.cpp turn with server timings and a restore
// from the SSD, a first turn with nothing cached, a full window, tiny and huge counts, halves.
const events = [
  {
    provider: "anthropic",
    model: "claude-opus-4-1",
    costUsd: 0.0123,
    metrics: {
      startedAt: at("01:49:31"),
      firstTokenAt: at("01:49:33"),
      endedAt: at("01:49:36"),
      inputTokens: 30412,
      cachedReadTokens: 30101,
      cacheWriteTokens: 311,
      outputTokens: 53,
      contextUsed: 30465,
      contextWindow: 475000,
      source: "client",
      prefillMs: 0,
      decodeMs: 0,
    },
  },
  {
    provider: "llamacpp",
    model: "C:\\models\\GLM-4.5-Air-Q4_K_S-00001-of-00002.gguf",
    costUsd: 0,
    metrics: {
      startedAt: at("13:02:07"),
      firstTokenAt: at("13:02:09"),
      endedAt: at("13:02:41"),
      inputTokens: 18750,
      cachedReadTokens: 17200,
      cacheWriteTokens: 0,
      outputTokens: 1250,
      contextUsed: 20000,
      contextWindow: 131072,
      prefillMs: 1834.6,
      decodeMs: 31250,
      tokPerSec: 40.5,
      kvRestoredTokens: 17200,
      kvRestoreMs: 412.4,
      source: "server",
    },
  },
  {
    provider: "openai",
    model: "gpt-5",
    costUsd: 0.0042,
    metrics: {
      startedAt: at("23:59:58"),
      inputTokens: 950,
      cachedReadTokens: 0,
      cacheWriteTokens: 0,
      outputTokens: 1999,
      contextUsed: 2949,
      contextWindow: 400000,
      prefillMs: 999.4,
      decodeMs: 125000,
      tokPerSec: 15.99,
      source: "client",
    },
  },
  {
    provider: "anthropic",
    model: "claude-sonnet-4-5",
    costUsd: 2.5,
    costUnknown: false,
    metrics: {
      startedAt: at("08:00:00"),
      endedAt: at("08:01:05"),
      inputTokens: 1_234_567,
      cachedReadTokens: 1_000_000,
      cacheWriteTokens: 0,
      outputTokens: 10_500,
      contextUsed: 1_245_067,
      contextWindow: 1_000_000,
      prefillMs: 59_999,
      decodeMs: 61_500,
      tokPerSec: 0,
      source: "server",
    },
  },
  {
    provider: "ollama",
    model: "qwen3:8b",
    costUsd: 0,
    costUnknown: true,
    metrics: {
      startedAt: at("12:00:00"),
      endedAt: at("12:00:01"),
      inputTokens: 0,
      cachedReadTokens: 0,
      cacheWriteTokens: 0,
      outputTokens: 7,
      contextUsed: 7,
      contextWindow: 32768,
      prefillMs: 0.4,
      decodeMs: 999.5,
      tokPerSec: 7.5,
      source: "server",
    },
  },
];

const pct = (m, n) => Math.min(100, (n / m.contextWindow) * 100);
const vectors = events.map((e) => {
  const m = e.metrics;
  const fresh = Math.max(0, m.inputTokens - m.cachedReadTokens);
  const used = Math.round((m.contextUsed / m.contextWindow) * 1000) / 10;
  return {
    event: { type: "message.assistant", payload: { parts: [], stopReason: "end_turn", ...e } },
    page: {
      input: kTokens(m.inputTokens),
      cache: m.cachedReadTokens > 0 ? kTokens(m.cachedReadTokens) : null,
      output: kTokens(m.outputTokens),
      context: `${used}% / ${kTokens(m.contextWindow)}`,
      prefill: duration(m.prefillMs),
      generation: `${duration(m.decodeMs)}${m.tokPerSec ? ` · ${Math.round(m.tokPerSec)} tok/s` : ""}`,
      ssd:
        m.kvRestoredTokens !== undefined
          ? // Persistar (3.10.3): the page's name for the context restored from the disk.
            `Persistar ${kTokens(m.kvRestoredTokens)} (${duration(m.kvRestoreMs)})`
          : null,
      cost: e.costUnknown ? "unknown" : e.costUsd > 0 ? usd(e.costUsd) : null,
      model: localModelName(e.model),
      clockIt: new Date(m.endedAt ?? m.startedAt).toLocaleTimeString("it-IT", { timeZone: "UTC" }),
      clockEn: new Date(m.endedAt ?? m.startedAt).toLocaleTimeString("en-US", { timeZone: "UTC" }),
      bar: {
        cached: pct(m, m.cachedReadTokens),
        fresh: pct(m, fresh),
        out: pct(m, m.outputTokens),
      },
    },
  };
});

// The formatters alone, over the edges (rounding halves, unit changes).
const counts = [0, 1, 999, 1000, 1049, 1050, 1250, 1950, 9949, 9950, 9999, 10_000, 10_499, 10_500, 99_500, 999_499, 999_500, 1_000_000, 1_049_999, 1_050_000, 12_345_678];
const times = [0, 0.4, 0.5, 1.5, 999, 999.4, 999.5, 1000, 1049, 1050, 1250, 59_949, 59_950, 60_000, 61_499, 61_500, 119_500, 3_600_000];
const dollars = [0, 0.0001, 0.00125, 0.0042, 0.00999, 0.01, 0.125, 1.005, 2.5, 1234.567];
const out = {
  vectors,
  kTokens: counts.map((n) => [n, kTokens(n)]),
  duration: times.map((n) => [n, duration(n)]),
  usd: dollars.map((n) => [n, usd(n)]),
};
writeFileSync(join(here, "../test/fixtures/metrics_vectors.json"), `${JSON.stringify(out, null, 2)}\n`);
console.log(`metrics_vectors.json: ${vectors.length} events`);

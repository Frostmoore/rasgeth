// The router of God's topics with a real model (3.12, phases 0 and 2): the 40 messages of
// `fixtures/topics-routing.json` against five made-up topics, with the router's own instructions
// and request (`ROUTER_SYSTEM`). Only with `pnpm test:live`:
//   ANTHROPIC_API_KEY=…  (REDGIANT_LIVE_ROUTER_MODEL, default claude-haiku-4-5): precision (goal
//     90%) and the time of one call;
//   REDGIANT_LIVE_CLAUDE_TOKEN=… (a `claude setup-token`): the warm engine of the subscription,
//     its time per message once started, and that it holds for 50 requests in a row.
// About 1.5k tokens in and 40 out per message: a few cents for the whole run.
import { readFileSync } from "node:fs";
import { mkdtemp } from "node:fs/promises";
import { tmpdir } from "node:os";
import { dirname, join } from "node:path";
import { fileURLToPath } from "node:url";
import { parseRouterAnswer } from "@redgiant/protocol";
import { AnthropicProvider, complete } from "@redgiant/providers";
import { ClaudeEngine } from "@redgiant/subscriptions";
import { describe, expect, it } from "vitest";
import { ROUTER_SYSTEM, WarmRouter } from "../src/topics.js";

const here = dirname(fileURLToPath(import.meta.url));
const SET = JSON.parse(readFileSync(join(here, "fixtures/topics-routing.json"), "utf8")) as {
  topics: { id: string; title: string; summary: string }[];
  messages: { text: string; want: string; rule?: string }[];
};

/** The request the router makes (`Topics.askRouter`), for one message. */
const prompt = (text: string) =>
  [
    "<topics>",
    ...SET.topics.map(
      (t, i) =>
        `- id: ${t.id} | title: ${t.title} | summary: ${t.summary} | last: 2026-11-2${i}T10:00:00.000Z`,
    ),
    "</topics>",
    "<message>",
    text,
    "</message>",
  ].join("\n");

const ids = SET.topics.map((t) => t.id);
/** The messages the rules leave to the router. */
const asked = SET.messages.filter((m) => !m.rule);

const key = process.env.ANTHROPIC_API_KEY;
describe.skipIf(!key)("the topics' router with an API key (live)", () => {
  it("routes the messages of phase 0 (goal 90%), fast", async () => {
    const p = new AnthropicProvider({ apiKey: key as string });
    const model = process.env.REDGIANT_LIVE_ROUTER_MODEL ?? "claude-haiku-4-5";
    let right = 0;
    const times: number[] = [];
    for (const m of asked) {
      const t0 = Date.now();
      const c = await complete(
        p.stream({
          model,
          system: ROUTER_SYSTEM,
          tools: [],
          messages: [{ role: "user", parts: [{ type: "text", text: prompt(m.text) }] }],
          maxTokens: 200,
        }),
      );
      times.push(Date.now() - t0);
      const text = c.message.parts.flatMap((x) => (x.type === "text" ? [x.text] : [])).join("");
      const r = parseRouterAnswer(text, ids);
      if (r?.to === m.want) right++;
      else console.log(`router: «${m.text}» → ${r?.to ?? text} (want ${m.want})`);
    }
    times.sort((a, b) => a - b);
    console.log(
      `router (${model}): ${right}/${asked.length} right, median ${times[times.length >> 1]} ms, worst ${times.at(-1)} ms`,
    );
    expect(right / asked.length).toBeGreaterThanOrEqual(0.9);
  });
});

const token = process.env.REDGIANT_LIVE_CLAUDE_TOKEN;
describe.skipIf(!token)("the topics' warm router on a subscription (live)", () => {
  it("answers once started, and holds for 50 requests", async () => {
    const dir = await mkdtemp(join(tmpdir(), "rg-warm-live-"));
    const engine = new ClaudeEngine({ token: token as string, configDir: dir, cwd: dir });
    const model = process.env.REDGIANT_LIVE_ROUTER_MODEL ?? "claude-haiku-4-5";
    const times: number[] = [];
    let right = 0;
    // The server's own warm router, with two engines ready (3.12.1).
    const router = new WarmRouter(engine, Date.now, 2);
    const call = (text: string) => ({
      system: ROUTER_SYSTEM,
      text,
      model: { provider: "claude-subscription", model },
    });
    router.warm(call(""));
    await new Promise((r) => setTimeout(r, 15_000));
    for (let i = 0; i < 50; i++) {
      const m = asked[i % asked.length];
      if (!m) break;
      const t0 = Date.now();
      const text = await router.ask(call(prompt(m.text)));
      times.push(Date.now() - t0);
      if (parseRouterAnswer(text, ids)?.to === m.want) right++;
    }
    router.close();
    times.sort((a, b) => a - b);
    console.log(
      `warm router: ${right}/50 right, median ${times[25]} ms, worst ${times.at(-1)} ms, rss ${Math.round(process.memoryUsage().rss / 1e6)} MB (this process; the engine's own is apart)`,
    );
    expect(times).toHaveLength(50);
  }, 900_000);
});

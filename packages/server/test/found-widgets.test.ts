// show_results (3.12.2): pictures, trains and routes as widgets in the answer. The log keeps the
// data (so it survives a reload and rebuildHistory), the model reads a summary in words, the
// instructions say to ask before booking, and bad data is refused without writing anything.
import { FoundWidget } from "@redgiant/protocol";
import type { CompletionRequest, FakeTurn } from "@redgiant/providers";
import { afterEach, describe, expect, it } from "vitest";
import { startServer } from "./helpers.js";

type Server = Awaited<ReturnType<typeof startServer>>;
let s: Server | undefined;
afterEach(async () => {
  await s?.close();
  s = undefined;
}, 60_000);

const textOf = (req: CompletionRequest | undefined) =>
  req?.messages
    .at(-1)
    ?.parts.flatMap((p) =>
      p.type === "text" ? [p.text] : p.type === "tool_result" ? [p.content] : [],
    )
    .join("\n") ?? "";

function script(req: CompletionRequest): FakeTurn {
  const last = req.messages.at(-1);
  if (last?.parts.some((p) => p.type === "tool_result")) return { text: `RESULT: ${textOf(req)}` };
  const m = textOf(req).match(/^CALL (\w+) ([\s\S]+)$/);
  if (m?.[1] && m[2]) return { toolCalls: [{ name: m[1], input: JSON.parse(m[2]) }] };
  return { text: "ok" };
}

async function chatSession(): Promise<string> {
  if (!s) throw new Error("no server");
  await s.api("POST", "/api/agents", { kind: "god", parentId: null, name: "God" });
  const chat = (await s.api<{ id: string }>("GET", "/api/chat/agent")).body.id;
  return (await s.api<{ sessionId: string }>("POST", "/api/sessions", { agentId: chat })).body
    .sessionId;
}

const call = async (sid: string, input: unknown) => {
  if (!s) throw new Error("no server");
  await (await s.core.send("me", sid, `CALL show_results ${JSON.stringify(input)}`)).done;
};

describe("show_results (3.12.2)", () => {
  it("logs a gallery, trains and a route, and tells the model in words", async () => {
    s = await startServer(script);
    const sid = await chatSession();
    await call(sid, {
      kind: "gallery",
      title: "Trevi",
      images: [
        { url: "https://upload.example/trevi.jpg", title: "The fountain" },
        { url: "https://upload.example/trevi2.jpg", thumbUrl: "https://upload.example/t2.jpg" },
      ],
    });
    const first = s.provider.requests[0];
    expect(first?.tools?.map((t) => t.name)).toContain("show_results");
    expect(first?.system).toContain("## Pictures, trains, flights and routes");
    expect(first?.system).toContain('"Yes, book it", "No" and "Change"');
    expect(textOf(s.provider.requests.at(-1))).toContain(
      'Shown to the person inside your answer: a gallery of 2 pictures under "Trevi"',
    );

    await call(sid, {
      kind: "trips",
      mode: "train",
      from: "Milano C.le",
      to: "Roma Termini",
      date: "ven 27 nov",
      offers: [
        {
          departs: "06:20",
          arrives: "09:15",
          duration: "2 h 55",
          stops: 0,
          label: "Frecciarossa 9505",
          price: 39.9,
          currency: "EUR",
        },
      ],
    });
    expect(textOf(s.provider.requests.at(-1))).toContain(
      "1 train option Milano C.le to Roma Termini:\n1. Frecciarossa 9505 06:20-09:15, 39.90 EUR",
    );
    expect(textOf(s.provider.requests.at(-1))).toContain("ask before booking");

    await call(sid, {
      kind: "route",
      from: { name: "Termini", lat: 41.9009, lon: 12.5016 },
      to: { name: "Colosseo", lat: 41.8902, lon: 12.4922 },
      options: [
        { mode: "walk", durationMin: 22, distanceM: 1700, steps: [{ text: "Via Cavour" }] },
      ],
    });
    expect(textOf(s.provider.requests.at(-1))).toContain(
      "a route from Termini to Colosseo (walk 22 min)",
    );

    const events = await s.core.store.list({ types: ["found.shown"] });
    expect(events.map((e) => FoundWidget.parse(e.payload).kind)).toEqual([
      "gallery",
      "trips",
      "route",
    ]);
    // The event comes back from the log whole, as the page and the app read it.
    expect(FoundWidget.parse(events[1]?.payload)).toMatchObject({
      mode: "train",
      offers: [{ stops: 0, label: "Frecciarossa 9505" }],
    });
  });

  it("refuses addresses that are not http(s) and points outside the Earth, and writes nothing", async () => {
    s = await startServer(script);
    const sid = await chatSession();
    await call(sid, {
      kind: "gallery",
      images: [{ url: "javascript:alert(1)" }],
    });
    await call(sid, { kind: "gallery", images: [{ url: "data:text/html,<b>x</b>" }] });
    await call(sid, {
      kind: "route",
      from: { name: "A", lat: 95, lon: 0 },
      to: { name: "B", lat: 1, lon: 1 },
      options: [{ mode: "walk", durationMin: 1 }],
    });
    expect(await s.core.store.list({ types: ["found.shown"] })).toHaveLength(0);
  });
});

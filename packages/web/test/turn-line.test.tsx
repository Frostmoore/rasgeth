// @vitest-environment jsdom
// Agents at work together (3.8.10): the page says «queued (2nd of 3)», a waiting conversation's
// notice moves it first, the setting saves the limit with the other command settings, and the
// line comes from `turns.queue`.
import { cleanup, fireEvent, render, waitFor } from "@testing-library/preact";
import { afterEach, beforeEach, describe, expect, it, vi } from "vitest";
import { lang } from "../src/i18n.js";

const calls: [string, unknown[]][] = [];
const view = (ids: string[]) => ({
  limit: 2,
  working: 2,
  running: [
    { sessionId: "w1", agentId: "a1" },
    { sessionId: "w2", agentId: "a2" },
  ],
  queued: ids.map((sessionId) => ({ sessionId, agentId: "a3", since: new Date().toISOString() })),
});
const settings = {
  maxPerSession: 4,
  maxMs: 86_400_000,
  maxLogBytes: 8_388_608,
  bashMaxMs: 600_000,
  maxAtWork: null,
};
const fakeApi = new Proxy(
  {},
  {
    get: (_t, name: string) => {
      if (name === "then") return undefined;
      return (...args: unknown[]) => {
        calls.push([name, args]);
        if (name === "turnFirst") return Promise.resolve(view(["q3", "q1", "q2"]));
        if (name === "turns") return Promise.resolve(view(["q1", "q2", "q3"]));
        if (name === "commandSettings") return Promise.resolve({ settings, defaults: settings });
        if (name === "setCommandSettings") return Promise.resolve({ id: "ch1" });
        return Promise.resolve({});
      };
    },
  },
);
vi.mock("../src/state.js", async (orig) => ({
  ...(await orig<typeof import("../src/state.js")>()),
  getApi: () => fakeApi,
}));

const { AtWorkCard, QueuedNotice, ordinal, placeWords } = await import(
  "../src/components/TurnLine.js"
);
const { turnQueue, applyMessage } = await import("../src/state.js");

beforeEach(() => {
  calls.length = 0;
  lang.value = "it";
  turnQueue.value = view(["q1", "q2", "q3"]);
});
afterEach(cleanup);

describe("agents at work together (3.8.10)", () => {
  it("ordinals and places, in both languages", () => {
    expect(placeWords("q2")).toBe("in coda (2° di 3)");
    expect(placeWords("w1")).toBeUndefined();
    lang.value = "en";
    expect([1, 2, 3, 4, 11, 12, 13, 21, 22].map(ordinal)).toEqual([
      "1st",
      "2nd",
      "3rd",
      "4th",
      "11th",
      "12th",
      "13th",
      "21st",
      "22nd",
    ]);
    expect(placeWords("q3")).toBe("queued (3rd of 3)");
  });

  it("the notice of a waiting conversation moves it first", async () => {
    const r = render(<QueuedNotice sessionId="q3" />);
    expect(r.getByText("In coda (3° di 3): aspetta che si liberi un posto")).toBeTruthy();
    fireEvent.click(r.getByText("Passa avanti"));
    await waitFor(() =>
      expect(calls.some(([n, a]) => n === "turnFirst" && a[0] === "q3")).toBe(true),
    );
    await waitFor(() => expect(turnQueue.value.queued[0]?.sessionId).toBe("q3"));
    // The first of the line has nothing to pass.
    cleanup();
    const first = render(<QueuedNotice sessionId="q3" />);
    expect(first.queryByText("Passa avanti")).toBeNull();
    expect(render(<QueuedNotice sessionId="w1" />).container.textContent).toBe("");
  });

  it("the setting saves the limit with the other command settings", async () => {
    const r = render(<AtWorkCard />);
    await waitFor(() => expect(r.getByText("Nessun limite")).toBeTruthy());
    fireEvent.click(r.getByText("3"));
    await waitFor(() =>
      expect(calls.find(([n]) => n === "setCommandSettings")?.[1][0]).toEqual({
        ...settings,
        maxAtWork: 3,
      }),
    );
    await waitFor(() => expect(r.getByText(/Salvato/)).toBeTruthy());
  });

  it("the line comes from turns.queue", () => {
    applyMessage({ type: "turns.queue", ...view(["z"]) });
    expect(turnQueue.value.queued.map((q) => q.sessionId)).toEqual(["z"]);
  });
});

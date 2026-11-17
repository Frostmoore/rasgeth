// Agents at work together (3.8.10): the rules of the line as a table, then the places they make.
import { describe, expect, it } from "vitest";
import {
  type Arrival,
  freePlaces,
  type LineEntry,
  lineOrder,
  placeInLine,
  type Seat,
  startsNow,
  TurnSeats,
} from "../src/turn-seats.js";

describe("startsNow", () => {
  it.each<[string, Arrival, number | null, number, number, boolean]>([
    ["no limit", "other", null, 50, 3, true],
    ["a free place, nobody waiting", "other", 2, 1, 0, true],
    ["every place taken", "other", 2, 2, 0, false],
    ["a free place but a line in front", "other", 2, 1, 1, false],
    ["the limit lowered under the turns at work", "other", 1, 3, 0, false],
    ["the person's own message, places taken", "person", 1, 5, 4, true],
    ["a child of a turn that lends its place", "lend", 1, 1, 2, true],
  ])("%s", (_name, arrival, limit, working, waiting, starts) => {
    expect(startsNow(arrival, limit, working, waiting)).toBe(starts);
  });
});

describe("lineOrder", () => {
  const e = (seq: number, child = false, firstAt?: number): LineEntry & { n: number } => ({
    n: seq,
    seq,
    child,
    ...(firstAt !== undefined && { firstAt }),
  });
  it.each<[string, (LineEntry & { n: number })[], number[]]>([
    ["by arrival", [e(2), e(0), e(1)], [0, 1, 2]],
    ["children of a waiting turn first", [e(0), e(1, true), e(2)], [1, 0, 2]],
    ["moved to the front before everything", [e(0), e(1, true), e(2, false, 1)], [2, 1, 0]],
    ["the last moved goes first", [e(0, false, 1), e(1), e(2, false, 2)], [2, 0, 1]],
  ])("%s", (_name, line, order) => {
    expect(lineOrder(line).map((x) => x.n)).toEqual(order);
  });
});

describe("freePlaces and placeInLine", () => {
  it.each<[number | null, number, number]>([
    [null, 9, Number.POSITIVE_INFINITY],
    [3, 1, 2],
    [2, 2, 0],
    [1, 4, 0],
  ])("limit %s with %s at work: %s free", (limit, working, free) => {
    expect(freePlaces(limit, working)).toBe(free);
  });
  it("says «2nd of 3»", () => {
    const q = (sessionId: string) => ({ sessionId, agentId: "a", since: "" });
    const view = { queued: [q("a"), q("b"), q("c")] };
    expect(placeInLine(view, "b")).toEqual({ place: 2, of: 3 });
    expect(placeInLine(view, "z")).toBeUndefined();
  });
});

describe("TurnSeats", () => {
  const make = (limit: number | null) => {
    const box = { limit };
    const seats = new TurnSeats({ limit: () => box.limit });
    const started: string[] = [];
    const held = new Map<string, Seat>();
    const ask = (sessionId: string, o: { person?: boolean; parent?: string } = {}) => {
      const seat = seats.ask(
        "me",
        { id: `q-${sessionId}`, sessionId, agentId: sessionId, ...o },
        (s) => {
          started.push(sessionId);
          held.set(sessionId, s);
        },
      );
      if (seat) {
        started.push(sessionId);
        held.set(sessionId, seat);
      }
      return seat !== undefined;
    };
    const end = (sessionId: string) => held.get(sessionId)?.release();
    const line = () => seats.view("me").queued.map((q) => q.sessionId);
    return { box, seats, started, ask, end, line };
  };

  it("two at work, two in line, then in order", () => {
    const t = make(2);
    expect([t.ask("a"), t.ask("b"), t.ask("c"), t.ask("d")]).toEqual([true, true, false, false]);
    expect(t.line()).toEqual(["c", "d"]);
    t.end("a");
    expect(t.started).toEqual(["a", "b", "c"]);
    t.end("b");
    expect(t.started).toEqual(["a", "b", "c", "d"]);
    expect(t.seats.view("me").working).toBe(2);
  });

  it("the person moves one first; a second release is nothing", () => {
    const t = make(1);
    t.ask("a");
    t.ask("b");
    t.ask("c");
    expect(t.seats.first("me", "c")).toBe(true);
    expect(t.seats.first("me", "a")).toBe(false);
    expect(t.seats.view("me").queued[0]).toMatchObject({ sessionId: "c", first: true });
    t.end("a");
    t.end("a");
    expect(t.started).toEqual(["a", "c"]);
    expect(t.line()).toEqual(["b"]);
  });

  it("the person's message never waits, and the line waits for it", () => {
    const t = make(1);
    t.ask("a");
    expect(t.ask("p", { person: true })).toBe(true);
    t.ask("b");
    t.end("a");
    expect(t.line()).toEqual(["b"]);
    t.end("p");
    expect(t.started).toEqual(["a", "p", "b"]);
  });

  it("a child takes the place of the turn waiting for it; siblings wait first in line", () => {
    const t = make(1);
    t.ask("parent");
    t.ask("other");
    expect(t.ask("kid1", { parent: "parent" })).toBe(true);
    expect(t.ask("kid2", { parent: "parent" })).toBe(false);
    expect(t.line()).toEqual(["kid2", "other"]);
    expect(t.seats.view("me").working).toBe(1);
    t.end("kid1");
    expect(t.started.at(-1)).toBe("kid2");
    t.end("kid2");
    // The parent works again on its place: nothing else starts.
    expect(t.line()).toEqual(["other"]);
    expect(t.seats.view("me").working).toBe(1);
    t.end("parent");
    expect(t.started.at(-1)).toBe("other");
  });

  it("lowering the limit stops nobody; raising it starts who waits", () => {
    const t = make(3);
    t.ask("a");
    t.ask("b");
    t.ask("c");
    t.box.limit = 1;
    t.seats.limitChanged("me");
    t.ask("d");
    t.end("a");
    t.end("b");
    expect(t.line()).toEqual(["d"]);
    t.box.limit = null;
    t.seats.limitChanged("me");
    expect(t.started.at(-1)).toBe("d");
  });

  it("withdraw and admit", () => {
    const t = make(1);
    t.ask("a");
    t.ask("b");
    t.ask("c");
    expect(t.seats.withdraw("me", "q-b")).toBe(true);
    expect(t.seats.withdraw("me", "q-b")).toBe(false);
    expect(t.seats.admit("me", "c")).toBe(true);
    expect(t.started).toEqual(["a", "c"]);
    expect(t.seats.view("me").working).toBe(2);
    expect(t.seats.waiting("me", "c")).toBeUndefined();
  });
});

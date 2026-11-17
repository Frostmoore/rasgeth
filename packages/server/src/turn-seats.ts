// Agents at work together (3.8.10, the person: «dai la possibilità all'utente di poter scegliere un
// numero massimo di agenti che lavorano in parallelo»). A turn holds a place while it runs; past
// the person's limit the next one waits in line and starts when a place is free, in order.
//
// The rules, decided once here and tested as a table (`test/turn-seats.test.ts`):
// - The person's own messages (the page, their chats) never wait: they start at once and hold a
//   place, so the line waits for them too.
// - A turn asked by a running turn that waits for its answer (run_subagent, ask_god,
//   ask_assistant) takes the place of the one that asked, which does nothing meanwhile: a parent
//   never waits for a child that waits for the parent's place. When the place is already lent
//   (run_subagents asks several), the other children wait in line before everything else.
// - The person may move a waiting turn to the front; the last moved goes first.
// - Lowering the limit stops nothing: it holds for the turns that start next.
import type { QueuedTurnView, TurnQueueView } from "@redgiant/protocol";

/** One turn in line, as the pure rules see it. */
export interface LineEntry {
  /** Order of arrival. */
  seq: number;
  /** Asked by a turn that waits for its answer. */
  child: boolean;
  /** When the person moved it to the front (a counter): the last moved goes first. */
  firstAt?: number;
}

/** How a turn arrives. */
export type Arrival = "person" | "lend" | "other";

/**
 * Whether a turn arriving now starts at once. `working`: the places held; `waiting`: the turns
 * already in line (a new one never passes them).
 */
export function startsNow(
  arrival: Arrival,
  limit: number | null,
  working: number,
  waiting: number,
): boolean {
  if (arrival === "person" || arrival === "lend") return true;
  return limit === null || (waiting === 0 && working < limit);
}

/** The line in the order it starts: moved to the front, then children, then by arrival. */
export function lineOrder<T extends LineEntry>(line: readonly T[]): T[] {
  return [...line].sort((a, b) => {
    const fa = a.firstAt ?? -1;
    const fb = b.firstAt ?? -1;
    if (fa !== fb) return fb - fa;
    if (a.child !== b.child) return a.child ? -1 : 1;
    return a.seq - b.seq;
  });
}

/** How many turns of the line may start now. */
export function freePlaces(limit: number | null, working: number): number {
  return limit === null ? Number.POSITIVE_INFINITY : Math.max(0, limit - working);
}

/** 1-based place of a conversation in the line, and the line's length (for «2nd of 3»). */
export function placeInLine(
  view: Pick<TurnQueueView, "queued">,
  sessionId: string,
): { place: number; of: number } | undefined {
  const i = view.queued.findIndex((q) => q.sessionId === sessionId);
  return i < 0 ? undefined : { place: i + 1, of: view.queued.length };
}

/** A place held by a running turn; `release` once it ends (twice does nothing). */
export interface Seat {
  release(): void;
}

interface Holder {
  sessionId: string;
  agentId: string;
  /** Counts against the limit (false while it lends its place to a child). */
  counted: boolean;
  /** The turn whose place it took. */
  parent?: string;
  /** Children it waits for, running or in line. */
  lending: number;
}

interface Waiter extends LineEntry {
  id: string;
  sessionId: string;
  agentId: string;
  since: string;
  parent?: string;
  go: (seat: Seat) => void;
}

interface OwnerLine {
  holders: Map<string, Holder>;
  line: Waiter[];
}

export interface TurnAsk {
  /** The id of its place in line (the log's `queueId`). */
  id: string;
  sessionId: string;
  agentId: string;
  /** The person's own message: it never waits. */
  person?: boolean;
  /** The running turn that waits for this one's answer. */
  parent?: string;
  since?: string;
}

/** The places and the line of every person; the core asks before every turn. */
export class TurnSeats {
  private readonly owners = new Map<string, OwnerLine>();
  private seq = 0;
  private moves = 0;

  constructor(
    private readonly o: {
      limit: (ownerId: string) => number | null;
      /** The view changed (to tell the person's pages and apps). */
      changed?: (ownerId: string) => void;
    },
  ) {}

  private of(ownerId: string): OwnerLine {
    let s = this.owners.get(ownerId);
    if (!s) {
      s = { holders: new Map(), line: [] };
      this.owners.set(ownerId, s);
    }
    return s;
  }

  private working(s: OwnerLine): number {
    let n = 0;
    for (const h of s.holders.values()) if (h.counted) n++;
    return n;
  }

  /**
   * A turn wants to start: a seat when it may start now, else undefined and it waits in line
   * (`go` is called with its seat when its place comes).
   */
  ask(ownerId: string, a: TurnAsk, go: (seat: Seat) => void): Seat | undefined {
    const s = this.of(ownerId);
    const parent = a.parent ? s.holders.get(a.parent) : undefined;
    const arrival: Arrival = a.person ? "person" : parent?.counted ? "lend" : "other";
    const child = parent !== undefined && !a.person;
    if (child && parent) parent.lending++;
    if (startsNow(arrival, this.o.limit(ownerId), this.working(s), s.line.length)) {
      if (arrival === "lend" && parent) parent.counted = false;
      const seat = this.hold(ownerId, s, a.sessionId, a.agentId, child ? a.parent : undefined);
      this.o.changed?.(ownerId);
      return seat;
    }
    s.line.push({
      id: a.id,
      sessionId: a.sessionId,
      agentId: a.agentId,
      seq: this.seq++,
      child,
      since: a.since ?? new Date().toISOString(),
      ...(child && a.parent && { parent: a.parent }),
      go,
    });
    this.o.changed?.(ownerId);
    // A free place with a line in front: the first of the line takes it, maybe this one.
    this.pump(ownerId);
    return undefined;
  }

  private hold(
    ownerId: string,
    s: OwnerLine,
    sessionId: string,
    agentId: string,
    parent?: string,
  ): Seat {
    const h: Holder = { sessionId, agentId, counted: true, lending: 0, ...(parent && { parent }) };
    s.holders.set(sessionId, h);
    let released = false;
    return {
      release: () => {
        if (released) return;
        released = true;
        if (s.holders.get(sessionId) === h) s.holders.delete(sessionId);
        if (h.parent) this.childDone(s, h.parent);
        this.o.changed?.(ownerId);
        this.pump(ownerId);
      },
    };
  }

  /** A child ended or left the line: its parent works again once none is left. */
  private childDone(s: OwnerLine, parentId: string): void {
    const p = s.holders.get(parentId);
    if (!p) return;
    p.lending = Math.max(0, p.lending - 1);
    if (p.lending === 0) p.counted = true;
  }

  /** Starts the first of the line while places are free. */
  private pump(ownerId: string): void {
    const s = this.of(ownerId);
    let started = false;
    while (s.line.length > 0 && freePlaces(this.o.limit(ownerId), this.working(s)) > 0) {
      const next = lineOrder(s.line)[0] as Waiter;
      s.line.splice(s.line.indexOf(next), 1);
      next.go(this.hold(ownerId, s, next.sessionId, next.agentId, next.parent));
      started = true;
    }
    if (started) this.o.changed?.(ownerId);
  }

  /** The limit changed: a higher one starts who waits at once. */
  limitChanged(ownerId: string): void {
    this.o.changed?.(ownerId);
    this.pump(ownerId);
  }

  /** Takes a waiting turn out of the line (stopped, archived): true when it was there. */
  withdraw(ownerId: string, id: string): boolean {
    const s = this.of(ownerId);
    const i = s.line.findIndex((w) => w.id === id);
    if (i < 0) return false;
    const [w] = s.line.splice(i, 1);
    if (w?.parent) this.childDone(s, w.parent);
    this.o.changed?.(ownerId);
    this.pump(ownerId);
    return true;
  }

  /** The person moves a waiting conversation to the front: false when it is not in line. */
  first(ownerId: string, sessionId: string): boolean {
    const w = this.of(ownerId).line.find((x) => x.sessionId === sessionId);
    if (!w) return false;
    w.firstAt = ++this.moves;
    this.o.changed?.(ownerId);
    return true;
  }

  /**
   * The person wrote in a conversation that waits: it starts now, as their own messages do
   * (it holds a place). False when it was not in line.
   */
  admit(ownerId: string, sessionId: string): boolean {
    const s = this.of(ownerId);
    const w = s.line.find((x) => x.sessionId === sessionId);
    if (!w) return false;
    s.line.splice(s.line.indexOf(w), 1);
    w.go(this.hold(ownerId, s, w.sessionId, w.agentId, w.parent));
    this.o.changed?.(ownerId);
    return true;
  }

  /** The waiting place of a conversation, if it waits. */
  waiting(ownerId: string, sessionId: string): string | undefined {
    return this.owners.get(ownerId)?.line.find((w) => w.sessionId === sessionId)?.id;
  }

  view(ownerId: string): TurnQueueView {
    const s = this.of(ownerId);
    return {
      limit: this.o.limit(ownerId),
      working: this.working(s),
      running: [...s.holders.values()].map((h) => ({ sessionId: h.sessionId, agentId: h.agentId })),
      queued: lineOrder(s.line).map(
        (w): QueuedTurnView => ({
          sessionId: w.sessionId,
          agentId: w.agentId,
          since: w.since,
          ...(w.child && { child: true }),
          ...(w.firstAt !== undefined && { first: true }),
        }),
      ),
    };
  }
}

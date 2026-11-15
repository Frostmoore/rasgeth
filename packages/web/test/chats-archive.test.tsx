// @vitest-environment jsdom
// The Chat screen (the person, 2026-11-15): a chat is archived from its card, leaves the list, and
// comes back from «Archived».
import { cleanup, fireEvent, render, screen } from "@testing-library/preact";
import { afterEach, beforeAll, describe, expect, it, vi } from "vitest";
import { lang } from "../src/i18n.js";

const { api, rows } = vi.hoisted(() => ({
  api: {} as Record<string, ReturnType<typeof vi.fn>>,
  rows: [] as Record<string, unknown>[],
}));
vi.mock("../src/api.js", async (orig) => {
  const real = await orig<typeof import("../src/api.js")>();
  class Api {
    constructor() {
      // biome-ignore lint/correctness/noConstructorReturn: a stand-in for the whole API
      return new Proxy(
        {},
        { get: (_t, name) => (api as Record<string, unknown>)[name as string] ?? (async () => []) },
      );
    }
  }
  class Live {
    send() {}
    close() {}
  }
  return { ...real, Api, Live };
});
const row = (id: string, archived: boolean) => ({
  id,
  agentId: "chat",
  projectId: null,
  createdAt: "2026-11-15T08:00:00.000Z",
  lastAt: "2026-11-15T09:00:00.000Z",
  title: `Chat ${id}`,
  pinned: false,
  archived,
  running: false,
});
Object.assign(api, {
  chatAgent: vi.fn(async () => ({ id: "chat" })),
  chatAgentIdOf: vi.fn(async () => ({ id: "chat" })),
  sessions: vi.fn(async () => rows),
  chats: vi.fn(async () => []),
  updateSession: vi.fn(async (id: string, change: { archived?: boolean }) => {
    const r = rows.find((x) => x.id === id);
    if (r && change.archived !== undefined) r.archived = change.archived;
    return {};
  }),
});

const state = await import("../src/state.js");
const { Chats } = await import("../src/components/Chats.js");
beforeAll(async () => {
  await state.signIn("token").catch(() => {});
});
afterEach(cleanup);

describe("the Chat screen: archiving a chat", () => {
  it("archives from the card, hides it, and brings it back from «Archived»", async () => {
    lang.value = "it";
    rows.splice(0, rows.length, row("a", false), row("b", true));
    render(<Chats />);
    await vi.waitFor(() => expect(screen.getByText("Chat a")).toBeTruthy());
    expect(screen.queryByText("Chat b")).toBeNull();
    fireEvent.click(screen.getByLabelText("Archivia"));
    await vi.waitFor(() => expect(screen.queryByText("Chat a")).toBeNull());
    expect(api.updateSession).toHaveBeenCalledWith("a", { archived: true });
    fireEvent.click(screen.getByText("Archiviate (2)"));
    expect(screen.getByText("Chat a")).toBeTruthy();
    expect(screen.getByText("Chat b")).toBeTruthy();
    fireEvent.click(screen.getAllByLabelText("Riporta")[0] as HTMLElement);
    await vi.waitFor(() => expect(screen.getByText("Archiviate (1)")).toBeTruthy());
  });
});

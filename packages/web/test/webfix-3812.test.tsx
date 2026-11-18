// @vitest-environment jsdom
// 3.8.12, two faults of the page: a chat tab kept without its conversation sent the server a
// `session.follow` with no id («Invalid message» on every load), and on a phone the terminal
// opened from the project's files stayed under them. Kept tabs are checked now, and on a phone
// the last thing opened is on top: the area brought forward closes the files.
import { ClientMessage } from "@redgiant/protocol";
import { cleanup, fireEvent, render, waitFor } from "@testing-library/preact";
import { afterEach, beforeEach, describe, expect, it, vi } from "vitest";
import { lang } from "../src/i18n.js";

vi.mock("../src/state.js", async (orig) => ({
  ...(await orig<typeof import("../src/state.js")>()),
  getApi: () => new Proxy({}, { get: () => () => new Promise(() => {}) }) as never,
}));
vi.mock("../src/components/TerminalView.js", () => ({
  TerminalView: () => <div class="terminal" />,
}));

const state = await import("../src/state.js");
const { Explorer } = await import("../src/components/Explorer.js");
const { SideArea } = await import("../src/components/SideArea.js");
const { activeSide, explorerOpen, keptTab, loadTabs, sideViews, toggleExplorer } = state;

describe("kept tabs", () => {
  it.each([
    [{ id: "chat:a", type: "chat", title: "A", sessionId: "s1", agentId: "a" }, true],
    [{ id: "chat:a", type: "chat", title: "A", agentId: "a" }, false],
    [{ id: "chat:a", type: "chat", title: "A", sessionId: "", agentId: "a" }, false],
    [{ id: "t", type: "tavola", title: "T", sessionId: "s1" }, false],
    [{ id: "settings", type: "settings", title: "", section: "code" }, true],
    [{ id: "chats", type: "chats", title: "Chat" }, true],
    [{ id: "b", type: "board", title: "B", projectId: null }, true],
    [{ id: "i", type: "inspector", title: "I" }, false],
    [{ type: "chats", title: "Chat" }, false],
    [null, false],
    ["chat", false],
  ])("%j kept: %s", (tab, ok) => expect(keptTab(tab)).toBe(ok));

  it("a reload leaves out a chat tab without its conversation, and nothing asks to follow it", () => {
    const raw = JSON.stringify({
      tabs: [
        { id: "chat:a", type: "chat", title: "A", agentId: "a" },
        { id: "chats", type: "chats", title: "Chat" },
      ],
      active: "chat:a",
    });
    expect(loadTabs(raw)).toEqual({
      tabs: [{ id: "chats", type: "chats", title: "Chat" }],
      active: "chats",
    });
    expect(loadTabs("not json")).toEqual({ tabs: [], active: null });
  });

  it("the server's schema rejects a follow with no conversation, as it did", () => {
    expect(ClientMessage.safeParse({ type: "session.follow", history: true }).success).toBe(false);
    expect(
      ClientMessage.safeParse({ type: "session.follow", sessionId: "s1", history: true }).success,
    ).toBe(true);
  });
});

describe("the terminal on a phone", () => {
  const before = window.matchMedia;
  const media = (phone: boolean) => {
    window.matchMedia = ((q: string) =>
      ({
        matches: phone,
        media: q,
        addEventListener: () => {},
        removeEventListener: () => {},
      }) as unknown as MediaQueryList) as typeof window.matchMedia;
  };
  const Shell = () => (
    <div class="body">
      <main class="main" />
      {explorerOpen.value && <Explorer />}
      <SideArea />
    </div>
  );
  beforeEach(() => {
    lang.value = "it";
    sideViews.value = [];
    activeSide.value = null;
    toggleExplorer(true);
  });
  afterEach(() => {
    cleanup();
    window.matchMedia = before;
    sideViews.value = [];
    toggleExplorer(false);
  });

  it("opened from the files, the terminal is on top: the files close, and come back over it", async () => {
    media(true);
    const { container } = render(<Shell />);
    fireEvent.click(container.querySelector<HTMLElement>('.explorer button[title="Terminale"]')!);
    await waitFor(() => expect(container.querySelector(".explorer")).toBeNull());
    expect(explorerOpen.value).toBe(false);
    expect(sideViews.value.map((v) => v.type)).toEqual(["terminal"]);
    expect(container.querySelector(".side-area")).not.toBeNull();
    // The files' button again: they cover the terminal, which is still open under them.
    toggleExplorer(true);
    await waitFor(() => expect(container.querySelector(".explorer")).not.toBeNull());
    expect(sideViews.value.map((v) => v.type)).toEqual(["terminal"]);
  });

  it("on a computer the files stay beside the terminal", async () => {
    media(false);
    const { container } = render(<Shell />);
    fireEvent.click(container.querySelector<HTMLElement>('.explorer button[title="Terminale"]')!);
    await waitFor(() => expect(sideViews.value.map((v) => v.type)).toEqual(["terminal"]));
    expect(explorerOpen.value).toBe(true);
    expect(container.querySelector(".explorer")).not.toBeNull();
  });
});

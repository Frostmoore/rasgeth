// @vitest-environment jsdom
// 3.12.3: «Start from…» in the create-agent flow, an agent's connections (any number, by kind) and the
// calendars in Settings.
import { cleanup, fireEvent, render, waitFor } from "@testing-library/preact";
import { afterEach, beforeEach, describe, expect, it, vi } from "vitest";
import { lang } from "../src/i18n.js";

const calls: [string, unknown[]][] = [];
// biome-ignore lint/suspicious/noExplicitAny: a stand-in for the whole API
const fakeApi: any = new Proxy(
  {},
  {
    get: (_t, name: string) => {
      if (name === "then") return undefined;
      return (...args: unknown[]) => {
        calls.push([name, args]);
        if (name === "models") return Promise.resolve([]);
        if (name === "connectionOptions")
          return Promise.resolve({
            mailboxes: [
              { id: "box_1", name: "Work", address: "me@work.example" },
              { id: "box_2", name: "Home", address: "me@home.example" },
            ],
            chats: ["telegram", "whatsapp"],
            calendars: [
              { id: "cal_1", name: "Home calendar", writable: true },
              { id: "cal_2", name: "Google", writable: false },
            ],
            mcp: [],
          });
        if (name === "mcpServers") return Promise.resolve([]);
        if (name === "mcpStatus") return Promise.resolve([]);
        if (name === "calendars")
          return Promise.resolve({
            calendars: [
              {
                id: "cal_1",
                name: "Home calendar",
                kind: "caldav",
                url: "https://dav.example/home/",
                writable: true,
                createdAt: "x",
              },
            ],
          });
        if (name === "createAgent") return Promise.resolve({ id: "new1", name: "Email" });
        if (name === "addCalendar") return Promise.resolve({ id: "cal_9" });
        return Promise.resolve({});
      };
    },
  },
);
vi.mock("../src/state.js", async (orig) => {
  const real = await orig<typeof import("../src/state.js")>();
  real.agents.value = [{ id: "g", kind: "god", name: "Zeus" } as never];
  return {
    ...real,
    getApi: () => fakeApi,
    getLive: () => ({ send: () => {} }),
    refresh: () => Promise.resolve(),
  };
});

const { AssistantWizard } = await import("../src/components/Assistants.js");
const { ConnectionsTab } = await import("../src/components/AgentConnections.js");
const { Calendars } = await import("../src/components/CalendarSettings.js");

beforeEach(() => {
  calls.length = 0;
  lang.value = "en";
});
afterEach(cleanup);

const click = (el: Element) => fireEvent.click(el);
const byText = (c: ParentNode, text: string) => {
  const all = [...c.querySelectorAll("button, strong, h3, h4, li, p, span, label")];
  // The exact words first (a longer text may contain them), then any text that has them.
  return (all.find((e) => e.textContent?.trim() === text) ??
    all.find((e) => e.textContent?.includes(text))) as HTMLElement;
};

describe("«Start from…» (3.12.3)", () => {
  it("shows the five sets and an empty agent, and a set tells what it asks and what is left to connect", async () => {
    const { container } = render(<AssistantWizard onDone={() => {}} />);
    expect(byText(container, "Start from…")).toBeTruthy();
    for (const n of [
      "Researcher",
      "Email",
      "Message secretary",
      "Worksheets",
      "Agenda and reminders",
    ])
      expect(byText(container, n), n).toBeTruthy();
    expect(byText(container, "An empty agent")).toBeTruthy();
    click(byText(container, "Message secretary").closest("button") as HTMLElement);
    await waitFor(() => expect(byText(container, "To connect: chats")).toBeTruthy());
    expect(byText(container, "Asks you first:")?.textContent).toContain("commitment");
    expect(byText(container, "Model: fast, effort low")).toBeTruthy();
  });

  it("is in Italian too", async () => {
    lang.value = "it";
    const { container } = render(<AssistantWizard onDone={() => {}} />);
    expect(byText(container, "Parti da…")).toBeTruthy();
    expect(byText(container, "Segretario sui messaggi")).toBeTruthy();
    expect(byText(container, "Agenda e promemoria")).toBeTruthy();
  });

  it("creates the agent from the set: its name and the set's id go to the server, God's draft is skipped", async () => {
    const { container } = render(<AssistantWizard onDone={() => {}} />);
    click(byText(container, "Email").closest("button") as HTMLElement);
    const create = byText(container, "Create from this set");
    expect(create).toBeTruthy();
    click(create);
    await waitFor(() => expect(calls.some(([n]) => n === "createAgent")).toBe(true));
    const [, args] = calls.find(([n]) => n === "createAgent") as [
      string,
      [Record<string, unknown>],
    ];
    expect(args[0]).toMatchObject({ kind: "assistant", name: "Email", preset: "email" });
    expect(calls.some(([n]) => n === "setAgentPrompt")).toBe(false);
  });
});

describe("an agent's connections (3.12.3)", () => {
  const agent = {
    id: "a1",
    kind: "assistant",
    name: "Ada",
    status: "active",
    connections: [
      { kind: "mailbox", ref: "box_1" },
      { kind: "mailbox", ref: "box_gone" },
    ],
  } as never;

  it("lists what there is by kind, and what is connected but gone", async () => {
    const { container } = render(<ConnectionsTab agent={agent} />);
    await waitFor(() => expect(byText(container, "Work")).toBeTruthy());
    for (const w of [
      "Mailboxes",
      "Chats",
      "Calendars",
      "Services",
      "Telegram",
      "Whatsapp",
      "Google",
      "Home calendar",
    ])
      expect(byText(container, w), w).toBeTruthy();
    expect(byText(container, "Read only")).toBeTruthy();
    expect(byText(container, "Can add events (always asks you)")).toBeTruthy();
    // A mailbox that was connected and is not there any more can be switched off.
    expect(byText(container, "box_gone")).toBeTruthy();
    expect(container.querySelectorAll('input[type="checkbox"], input[type="radio"]').length).toBe(
      0,
    );
  });

  it("any number of connections of every kind are saved, as typed references", async () => {
    const { container } = render(<ConnectionsTab agent={agent} />);
    await waitFor(() => expect(byText(container, "Home")).toBeTruthy());
    const row = (label: string) =>
      [...container.querySelectorAll(".ui-toggle")].find((r) =>
        r.querySelector(".ui-toggle-label")?.textContent?.includes(label),
      ) as HTMLElement;
    for (const l of ["Telegram", "Whatsapp", "Home calendar", "Google"])
      click(row(l).querySelector('[role="switch"]') as Element);
    click(row("box_gone").querySelector('[role="switch"]') as Element);
    click(row("Home").querySelector('[role="switch"]') as Element);
    click(byText(container, "Save"));
    await waitFor(() => expect(calls.some(([n]) => n === "configureAgent")).toBe(true));
    const [, [id, change]] = calls.find(([n]) => n === "configureAgent") as [
      string,
      [string, { connections: { kind: string; ref: string }[] }],
    ];
    expect(id).toBe("a1");
    expect(change.connections).toEqual([
      { kind: "mailbox", ref: "box_1" },
      { kind: "chat", ref: "telegram" },
      { kind: "chat", ref: "whatsapp" },
      { kind: "calendar", ref: "cal_1" },
      { kind: "calendar", ref: "cal_2" },
      { kind: "mailbox", ref: "box_2" },
    ]);
  });
});

describe("calendars in Settings (3.12.3)", () => {
  it("lists them, says what Google can and cannot do, and adds a CalDAV one with its password", async () => {
    const { container } = render(<Calendars />);
    await waitFor(() => expect(byText(container, "Home calendar")).toBeTruthy());
    expect(byText(container, "CalDAV · writable")).toBeTruthy();
    click(byText(container, "Add a calendar").closest("button") as HTMLElement);
    const modal = document.body;
    await waitFor(() => expect(byText(modal, "New calendar")).toBeTruthy());
    // The iCal kind says Google is read only.
    click(byText(modal, "iCal address").closest("button") as HTMLElement);
    expect(
      byText(modal, "Writing to Google Calendar with a sign-in is not part of this"),
    ).toBeTruthy();
    click(byText(modal, "CalDAV").closest("button") as HTMLElement);
    const inputs = [...modal.querySelectorAll("input")] as HTMLInputElement[];
    const set = (i: number, value: string) =>
      fireEvent.input(inputs[i] as Element, { target: { value } });
    set(0, "Work");
    set(1, "https://caldav.example/me/work/");
    set(2, "marta");
    set(3, "s3cret");
    click(byText(modal, "Add").closest("button") as HTMLElement);
    await waitFor(() => expect(calls.some(([n]) => n === "addCalendar")).toBe(true));
    const [, [body]] = calls.find(([n]) => n === "addCalendar") as [
      string,
      [Record<string, unknown>],
    ];
    expect(body).toEqual({
      name: "Work",
      kind: "caldav",
      url: "https://caldav.example/me/work/",
      user: "marta",
      password: "s3cret",
      agents: false,
    });
  });
});

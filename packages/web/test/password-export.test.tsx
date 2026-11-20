// @vitest-environment jsdom
// 3.9.8: a password manager's export pasted in the composer is held before it leaves the page,
// with «Mettile nel Portachiavi» (only counts come back), «Invia senza» (the export taken out) and
// «Invia comunque» behind a second question naming how many. «Cancella per sempre» on a message
// asks in our Modal, with the replies quoting it as a switch. Generated rows only.
import { cleanup, fireEvent, render, waitFor } from "@testing-library/preact";
import { afterEach, beforeEach, describe, expect, it, vi } from "vitest";
import { lang } from "../src/i18n.js";

const fake = (i: number) => `Hx${i}#fake${i * 37}Z`;
const exportText = (n: number) =>
  [
    "name,url,username,password",
    ...Array.from({ length: n }, (_, i) => `Site ${i},https://s${i}.example.com/,u${i},${fake(i)}`),
  ].join("\n");

const calls: [string, unknown[]][] = [];
let closed = false;
const fakeApi = {
  importPasswordText: async (text: string) => {
    calls.push(["importPasswordText", [text]]);
    if (closed) {
      const { ApiError } = await import("../src/api.js");
      throw new ApiError(400, "The keychain is closed", "vault_closed");
    }
    return { added: 3, skipped: 1, names: ["site_0_u0"] };
  },
  erasePreview: async () => ({ quotes: 2, engine: true }),
  eraseMessage: async (...a: unknown[]) => {
    calls.push(["eraseMessage", a]);
    return { erased: 3, seqs: [5, 6, 7], echo: 1, traits: 0, transcripts: 1 };
  },
};

vi.mock("../src/state.js", async (orig) => ({
  ...(await orig<typeof import("../src/state.js")>()),
  getApi: () => fakeApi,
}));

const { Composer } = await import("../src/components/Composer.js");
const { Dialogs } = await import("../src/components/dialogs.js");
const { eraseForGood } = await import("../src/components/ChatTools.js");
const { sessionView } = await import("../src/state.js");

beforeEach(() => {
  lang.value = "it";
  calls.length = 0;
  closed = false;
});
afterEach(cleanup);

function composer() {
  const sent: { text: string; opts?: { secretOk?: boolean } }[] = [];
  const r = render(
    <>
      <Composer
        onSend={async (text, _files, opts) => void sent.push({ text, ...(opts && { opts }) })}
        running={false}
        placeholder="Scrivi"
        lang="it-IT"
        queues={false}
      />
      <Dialogs />
    </>,
  );
  const box = r.container.querySelector("textarea") as HTMLTextAreaElement;
  const write = (v: string) => {
    fireEvent.input(box, { target: { value: v } });
    fireEvent.click(r.container.querySelector("button.send") as HTMLElement);
  };
  return { r, sent, write };
}

describe("a password export in the composer (3.9.8)", () => {
  it("is held, and «Mettile nel Portachiavi» imports it and sends the words without it", async () => {
    const { r, sent, write } = composer();
    write(`ecco le password\n${exportText(3)}`);
    await waitFor(() => r.getByText("Questa è un'esportazione di password"));
    expect(r.getByText(/ci sono 3 password esportate/)).toBeTruthy();
    expect(sent).toEqual([]);
    fireEvent.click(r.getByTestId("pw-export-vault"));
    await waitFor(() => expect(sent).toHaveLength(1));
    expect(calls[0]?.[0]).toBe("importPasswordText");
    expect(sent[0]?.text).toContain("ecco le password");
    for (let i = 0; i < 3; i++) expect(sent[0]?.text).not.toContain(fake(i));
    await waitFor(() => r.getByText("Nel Portachiavi: 3 nuove, 1 c'erano già."));
  });

  it("«Invia senza» takes the export out", async () => {
    const { r, sent, write } = composer();
    write(`ciao\n${exportText(2)}`);
    await waitFor(() => r.getByTestId("pw-export-without"));
    fireEvent.click(r.getByTestId("pw-export-without"));
    await waitFor(() => expect(sent).toHaveLength(1));
    expect(sent[0]).toEqual({ text: "ciao\n[password export removed]" });
    expect(calls).toEqual([]);
  });

  it("«Invia comunque» asks again with the count, then sends it as written", async () => {
    const { r, sent, write } = composer();
    write(exportText(2));
    await waitFor(() => r.getByTestId("pw-export-anyway"));
    fireEvent.click(r.getByTestId("pw-export-anyway"));
    await waitFor(() => r.getByText("Mandare 2 password all'agente?"));
    expect(sent).toEqual([]);
    fireEvent.click(r.getByText("Invia 2 password"));
    await waitFor(() => expect(sent).toHaveLength(1));
    expect(sent[0]).toEqual({ text: exportText(2), opts: { secretOk: true } });
  });

  it("a closed keychain imports nothing, sends nothing and says so", async () => {
    closed = true;
    const { r, sent, write } = composer();
    write(exportText(2));
    await waitFor(() => r.getByTestId("pw-export-vault"));
    fireEvent.click(r.getByTestId("pw-export-vault"));
    await waitFor(() => r.getByText(/Il Portachiavi è chiuso: non ho importato niente/));
    expect(sent).toEqual([]);
  });
});

describe("«Cancella per sempre» (3.9.8)", () => {
  it("asks in our Modal with the replies quoting it as a switch, and the view loses the words", async () => {
    const view = sessionView("s1");
    view.value = {
      ...view.value,
      events: [5, 6, 7, 8].map((seq) => ({
        seq,
        id: `e${seq}`,
        ts: "2026-11-20T10:00:00Z",
        ownerId: "me",
        projectId: null,
        agentId: null,
        sessionId: "s1",
        type: "message.user",
        payload: { text: `message ${seq}` },
      })) as never,
    };
    const r = render(<Dialogs />);
    const done = eraseForGood("s1", 5);
    await waitFor(() => r.getByText("Cancellare per sempre questo messaggio?"));
    expect(r.getByText(/trascrizione del motore/)).toBeTruthy();
    fireEvent.click(r.getByText("Cancella anche 2 risposte e risultati dell'agente che lo riportano"));
    fireEvent.click(r.getByText("Cancella per sempre"));
    expect(await done).toBe(true);
    expect(calls).toEqual([["eraseMessage", ["s1", 5, true]]]);
    expect(view.value.events.map((e) => e.payload === null)).toEqual([true, true, true, false]);
  });
});

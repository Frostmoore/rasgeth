// @vitest-environment jsdom
// G42.0: the page inside RGCompanion. The fragment read once and taken out of the address, the
// token kept in memory only, theme and language from the app and never saved, no bar of the page,
// the bridge's messages (with the nonce) and the page's ways out going to the app; and
// `#open=settings` surviving the password page.
import { cleanup, render, waitFor } from "@testing-library/preact";
import { afterEach, beforeEach, describe, expect, it, vi } from "vitest";

const signIns: [string, unknown][] = [];
vi.mock("../src/state.js", async (orig) => ({
  ...(await orig<typeof import("../src/state.js")>()),
  signIn: async (token: string, o: unknown) => {
    signIns.push([token, o]);
    if (token === "bad") throw new Error("401");
  },
}));

const embed = await import("../src/embed.js");
const { EmbedRoot, embedBack, embedTarget } = await import("../src/components/Embed.js");
const { asking, askConfirm } = await import("../src/components/dialogs.js");
const { lang } = await import("../src/i18n.js");
const { takeOpenIntent } = await import("../src/components/App.js");

const NONCE = "n0nce-n0nce_n0nce";
const sent: unknown[] = [];

beforeEach(() => {
  sent.length = 0;
  signIns.length = 0;
  localStorage.clear();
  sessionStorage.clear();
  lang.value = "it";
  document.documentElement.dataset.theme = "system";
  (window as unknown as Record<string, unknown>).RGEmbed = {
    postMessage: (s: string) => sent.push(JSON.parse(s)),
  };
});
afterEach(() => {
  cleanup();
  embed.resetEmbed();
  delete (window as unknown as Record<string, unknown>).RGEmbed;
});

const open = (hash: string) => {
  history.replaceState(null, "", `/embed.html#${hash}`);
  return embed.takeEmbed();
};

describe("the fragment", () => {
  it("is read once and taken out of the address, the token with it", () => {
    const p = open(`token=rgd_x&embed=probe&bridge=${NONCE}&theme=light&lang=en`);
    expect(p).toMatchObject({ token: "rgd_x", embed: "probe", theme: "light", lang: "en" });
    expect(location.hash).toBe("");
    expect(location.href).not.toContain("rgd_x");
    expect(embed.embedded()).toBe(true);
  });

  it("a fragment the protocol refuses is no embed (and is still taken away)", () => {
    expect(open("token=rgd_x&embed=shell")).toBeNull();
    expect(location.hash).toBe("");
    expect(embed.embedded()).toBe(false);
  });

  it("gives the Canvas its target, the port its own", () => {
    const p = open(
      `token=t&embed=canvas&bridge=${NONCE}&scope=p1&path=a%2Fb.md&line=4&theme=dark&lang=it`,
    );
    expect(p && embedTarget(p)).toEqual({
      kind: "file",
      scope: "p1",
      path: "a/b.md",
      at: { line: 4, page: undefined },
    });
    const q = open(`token=t&embed=port&bridge=${NONCE}&agent=a1&port=3000&theme=dark&lang=it`);
    expect(q && embedTarget(q)).toEqual({ kind: "port", agentId: "a1", port: 3000 });
  });
});

describe("the root", () => {
  it("signs in without keeping the token; theme and language are the app's, not saved; no bar", async () => {
    const p = open(`token=rgd_x&embed=probe&bridge=${NONCE}&theme=dark&lang=en&font=Inter`);
    if (!p) throw new Error("no embed");
    const r = render(<EmbedRoot params={p} />);
    await waitFor(() => expect(sent).toContainEqual({ rg: "embed", n: NONCE, m: { t: "ready" } }));
    expect(signIns).toEqual([["rgd_x", { keep: false }]]);
    expect(localStorage.getItem("rg.token")).toBeNull();
    expect(localStorage.getItem("rg.theme")).toBeNull();
    expect(localStorage.getItem("rg.lang")).toBeNull();
    expect(document.documentElement.dataset.theme).toBe("dark");
    expect(lang.value).toBe("en");
    expect(document.body.style.fontFamily).toBe("Inter");
    expect(sent).toContainEqual({
      rg: "embed",
      n: NONCE,
      m: { t: "title", name: "Web view test" },
    });
    // None of the page's frame: no top bar, no left bar, no tabs.
    expect(
      r.container.querySelector("header.top, .sidebar, .tabs, .canvas-head:not([hidden])"),
    ).toBeNull();
    expect(r.container.querySelector(".embed-root[data-embed=probe]")).toBeTruthy();
  });

  it("follows the app: theme, language, and back (a question first, then «not mine»)", async () => {
    const p = open(`token=rgd_x&embed=probe&bridge=${NONCE}&theme=dark&lang=it`);
    if (!p) throw new Error("no embed");
    render(<EmbedRoot params={p} />);
    await waitFor(() => expect(signIns).toHaveLength(1));
    const post = (m: unknown) =>
      window.dispatchEvent(
        new MessageEvent("message", {
          data: { rg: "app", m },
          source: window,
          origin: location.origin,
        }),
      );
    post({ t: "theme", theme: "light" });
    post({ t: "lang", lang: "en" });
    expect(document.documentElement.dataset.theme).toBe("light");
    expect(lang.value).toBe("en");
    const answer = askConfirm("Sure?");
    post({ t: "back" });
    expect(await answer).toBe(false);
    expect(asking.value).toEqual([]);
    post({ t: "back" });
    const backs = sent.filter((m) => (m as { m: { t: string } }).m.t === "back");
    expect(backs).toEqual([
      { rg: "embed", n: NONCE, m: { t: "back", handled: true } },
      { rg: "embed", n: NONCE, m: { t: "back", handled: false } },
    ]);
    // Messages from elsewhere (another window, a frame) are not the app's.
    window.dispatchEvent(
      new MessageEvent("message", {
        data: { rg: "app", m: { t: "theme", theme: "dark" } },
        origin: location.origin,
      }),
    );
    expect(document.documentElement.dataset.theme).toBe("light");
  });

  it("says so when the device's access does not work", async () => {
    const p = open(`token=bad&embed=probe&bridge=${NONCE}&theme=dark&lang=it`);
    if (!p) throw new Error("no embed");
    const r = render(<EmbedRoot params={p} />);
    await waitFor(() => r.getByRole("alert"));
    expect(r.getByRole("alert").textContent).toMatch(/riapri RedGiant dall'app/);
  });
});

describe("the page's ways out go to the app", () => {
  it("copy, links to other sites, window.open, files from the app", async () => {
    open(`token=t&embed=probe&bridge=${NONCE}&theme=dark&lang=it`);
    const undo = embed.installEmbedWays();
    try {
      await navigator.clipboard?.writeText("hello");
      const a = document.createElement("a");
      a.href = "https://example.com/x";
      document.body.appendChild(a);
      a.click();
      window.open("https://example.org/");
      const files = embed.filesFromApp([".png"], true);
      const ask = sent.find((m) => (m as { m: { t: string } }).m.t === "openFile") as {
        m: { id: string };
      };
      embed.handleAppInput({
        t: "files",
        id: ask.m.id,
        files: [{ name: "a.txt", type: "text/plain", size: 2, data: "aGk=" }],
      });
      const got = await files;
      expect(got.map((f) => f.name)).toEqual(["a.txt"]);
      expect(await got[0]?.text()).toBe("hi");
      const kinds = sent.map((m) => (m as { m: unknown }).m);
      if (navigator.clipboard) expect(kinds).toContainEqual({ t: "copy", text: "hello" });
      expect(kinds).toContainEqual({ t: "external", url: "https://example.com/x" });
      expect(kinds).toContainEqual({ t: "external", url: "https://example.org/" });
      a.remove();
    } finally {
      undo();
    }
  });

  it("«Save as…» of a link of this server goes as its path; no app, nothing sent", async () => {
    open(`token=t&embed=probe&bridge=${NONCE}&theme=dark&lang=it`);
    expect(await embed.saveThroughApp("/api/canvas/raw?x=1", "a.pdf")).toBe(true);
    expect(sent.at(-1)).toEqual({
      rg: "embed",
      n: NONCE,
      m: { t: "saveAs", name: "a.pdf", url: "/api/canvas/raw?x=1" },
    });
    embed.resetEmbed();
    expect(embed.toApp({ t: "ready" })).toBe(false);
  });

  it("back with nothing of the page's open is «not mine»", () => {
    expect(embedBack()).toBe(false);
  });
});

describe("#open=settings after the password page (G42.0)", () => {
  it("waits in the tab's storage and is used once", () => {
    sessionStorage.setItem("rg.open", "settings");
    expect(takeOpenIntent()).toBe("settings");
    expect(takeOpenIntent()).toBeUndefined();
    sessionStorage.setItem("rg.open", "shell");
    expect(takeOpenIntent()).toBeUndefined();
  });
});

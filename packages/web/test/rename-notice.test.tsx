// @vitest-environment jsdom
// Rasgeth (plan 3.9.0, N2 for the page): the page says the new name everywhere, from one place
// (`PRODUCT_NAME`, `{product}` in the words), and says once to whoever knew the old one that it
// changed (choice 17, `rg.renameSeen`).
import { PRODUCT_NAME } from "@redgiant/protocol";
import { cleanup, fireEvent, render, waitFor } from "@testing-library/preact";
import { afterEach, beforeEach, describe, expect, it, vi } from "vitest";
import { dictionaries, type Key, lang, t } from "../src/i18n.js";

// The version the installation was born with; "fail": a server that does not say.
let firstVersion: string | null | "fail" = null;
vi.mock("../src/state.js", async (orig) => ({
  ...(await orig<typeof import("../src/state.js")>()),
  getApi: () => ({
    updateStatus: () =>
      firstVersion === "fail"
        ? Promise.reject(new Error("404"))
        : Promise.resolve({ firstVersion }),
  }),
}));

const { RENAME_SEEN, RENAMED_IN, RenameNotice, renameNoticeDue } = await import(
  "../src/components/RenameNotice.js"
);

beforeEach(() => {
  lang.value = "it";
  localStorage.clear();
  firstVersion = null;
});
afterEach(cleanup);

describe("when the new name is said", () => {
  const table: [string, Parameters<typeof renameNoticeDue>[0], boolean][] = [
    ["closed once: never again", { seen: true, newsSeen: "3.8.14", firstVersion: "3.2.0" }, false],
    [
      "this browser saw 3.8.14's news",
      { seen: false, newsSeen: "3.8.14", firstVersion: null },
      true,
    ],
    ["born with 3.8.12", { seen: false, newsSeen: null, firstVersion: "3.8.12" }, true],
    [
      "born before the version was kept",
      { seen: false, newsSeen: null, firstVersion: "0.0.0" },
      true,
    ],
    ["born with the new name", { seen: false, newsSeen: null, firstVersion: RENAMED_IN }, false],
    ["born later", { seen: false, newsSeen: "3.9.1", firstVersion: "3.9.1" }, false],
    ["nothing known", { seen: false, newsSeen: null, firstVersion: undefined }, false],
    [
      "a stored word that is not a version",
      { seen: false, newsSeen: "x", firstVersion: null },
      false,
    ],
  ];
  for (const [what, o, due] of table)
    it(what, () => {
      expect(renameNoticeDue(o)).toBe(due);
    });
});

describe("the notice", () => {
  it("tells whoever used the old name, once, and remembers it was closed", async () => {
    localStorage.setItem("rg.newsSeen", "3.8.14");
    const r = render(<RenameNotice />);
    await waitFor(() =>
      expect(r.container.textContent).toContain("RedGiant ora si chiama Rasgeth"),
    );
    expect(r.container.textContent).toContain("ràs-ghet");
    fireEvent.click(r.getByText("Ho capito"));
    expect(r.container.textContent).toBe("");
    expect(localStorage.getItem(RENAME_SEEN)).toBe(RENAMED_IN);
    cleanup();
    const again = render(<RenameNotice />);
    await new Promise((ok) => setTimeout(ok, 0));
    expect(again.container.textContent).toBe("");
  });

  it("asks the server when this browser knows nothing, in English too", async () => {
    lang.value = "en";
    firstVersion = "3.8.12";
    const r = render(<RenameNotice />);
    await waitFor(() =>
      expect(r.container.textContent).toContain("RedGiant is now called Rasgeth"),
    );
    fireEvent.click(r.getByLabelText(t("close")));
    expect(localStorage.getItem(RENAME_SEEN)).toBe(RENAMED_IN);
  });

  it("says nothing to a new installation, nor when the server does not answer", async () => {
    firstVersion = RENAMED_IN;
    const fresh = render(<RenameNotice />);
    await new Promise((ok) => setTimeout(ok, 0));
    expect(fresh.container.textContent).toBe("");
    cleanup();
    firstVersion = "fail";
    const old = render(<RenameNotice />);
    await new Promise((ok) => setTimeout(ok, 0));
    expect(old.container.textContent).toBe("");
  });
});

describe("the page's words", () => {
  // Kept on purpose (scripts/name-keep.json): the news of past releases, the notice itself and
  // the description of God's mascot as it is drawn today.
  const kept = (k: string) => /^news\d/.test(k) || k === "renameTitle" || k === "mascotGodHelp";

  // The inside that stays and that some texts must name exactly (plan 3.9.0, «l'interno resta»):
  // variables, folders, the Docker service the tunnel reaches, the webhook's header, the OS's user.
  const INSIDE =
    /REDGIANT_\w+|x-redgiant-secret|\/var\/lib\/redgiant\b|\.redgiant\/|redgiant-helper\.socket|~\/RedGiant-backups|\/mnt\/redgiant-backups|\bredgiant:7600|(?:user|utente) redgiant\b/g;

  it("never say the old name, and fill {product} with the protocol's", () => {
    expect(PRODUCT_NAME).toBe("Rasgeth");
    for (const l of ["it", "en"] as const) {
      lang.value = l;
      for (const k of Object.keys(dictionaries.en) as Key[]) {
        if (kept(k)) continue;
        expect(t(k).replace(INSIDE, ""), `${l}.${k}`).not.toMatch(
          /red ?giant|rgcompanion|\{product\}/i,
        );
      }
    }
  });

  it("write the name from one place: {product}, never by hand", () => {
    for (const l of ["it", "en"] as const)
      for (const [k, words] of Object.entries(dictionaries[l])) {
        if (kept(k)) continue;
        // File names keep their own spelling (Rasgeth-CA.crt, Rasgeth-Setup.exe…).
        expect(words.replace(/Rasgeth-[\w.-]+/g, ""), `${l}.${k}`).not.toContain(PRODUCT_NAME);
      }
  });
});

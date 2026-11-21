// @vitest-environment jsdom
// 3.10: DropChoice, the page's drawn choice that opens a list, instead of a native select. The
// button says what is chosen; the list opens under it with the chosen one marked and focused; the
// arrows, Home and End move, a click chooses (nothing for the same one), Esc and a click away close.
import { cleanup, fireEvent, render } from "@testing-library/preact";
import { useState } from "preact/hooks";
import { afterEach, describe, expect, it, vi } from "vitest";
import { DropChoice } from "../src/components/ui.js";

afterEach(cleanup);

type Mode = "default" | "now" | "propose";
const options = [
  { id: "default" as const, label: "Come per l'agente: subito" },
  { id: "now" as const, label: "Subito", hint: "Le modifiche entrano da sole" },
  { id: "propose" as const, label: "Come proposte da accettare" },
];

function Host({ onChange }: { onChange: (m: Mode) => void }) {
  const [v, setV] = useState<Mode>("default");
  return (
    <DropChoice<Mode>
      value={v}
      options={options}
      label="Modifiche degli agenti"
      onChange={(m) => {
        setV(m);
        onChange(m);
      }}
    />
  );
}

const list = () => document.querySelector<HTMLElement>(".ui-drop-list");
const items = () => [...(list()?.querySelectorAll<HTMLButtonElement>("button") ?? [])];

describe("DropChoice", () => {
  it("says what is chosen; opens a list with it marked and focused", () => {
    const { container } = render(<Host onChange={() => {}} />);
    const btn = container.querySelector<HTMLButtonElement>(".ui-drop-current") as HTMLButtonElement;
    expect(btn.textContent).toBe("Come per l'agente: subito");
    expect(btn.getAttribute("aria-label")).toBe(
      "Modifiche degli agenti: Come per l'agente: subito",
    );
    expect(btn.getAttribute("aria-expanded")).toBe("false");
    expect(container.querySelector("select")).toBeNull();
    fireEvent.click(btn);
    expect(btn.getAttribute("aria-expanded")).toBe("true");
    expect(list()?.getAttribute("role")).toBe("listbox");
    expect(items().map((b) => b.getAttribute("aria-selected"))).toEqual(["true", "false", "false"]);
    expect(document.activeElement).toBe(items()[0]);
    expect(items()[1]?.querySelector("small")?.textContent).toBe("Le modifiche entrano da sole");
  });

  it("the keys move, a click chooses and closes; the same one changes nothing", () => {
    const onChange = vi.fn();
    const { container } = render(<Host onChange={onChange} />);
    const btn = container.querySelector<HTMLButtonElement>(".ui-drop-current") as HTMLButtonElement;
    fireEvent.keyDown(btn, { key: "ArrowDown" });
    expect(list()).toBeTruthy();
    fireEvent.keyDown(list() as HTMLElement, { key: "ArrowDown" });
    expect(document.activeElement).toBe(items()[1]);
    fireEvent.keyDown(list() as HTMLElement, { key: "End" });
    expect(document.activeElement).toBe(items()[2]);
    fireEvent.keyDown(list() as HTMLElement, { key: "ArrowDown" });
    expect(document.activeElement).toBe(items()[0]);
    fireEvent.keyDown(list() as HTMLElement, { key: "ArrowUp" });
    expect(document.activeElement).toBe(items()[2]);
    fireEvent.click(items()[2] as HTMLButtonElement);
    expect(onChange).toHaveBeenCalledWith("propose");
    expect(list()).toBeNull();
    expect(btn.textContent).toBe("Come proposte da accettare");
    expect(document.activeElement).toBe(btn);
    fireEvent.click(btn);
    fireEvent.click(items()[2] as HTMLButtonElement);
    expect(onChange).toHaveBeenCalledTimes(1);
  });

  it("Esc closes the list only; a click away closes it", () => {
    const outer = vi.fn();
    const { container } = render(
      // biome-ignore lint/a11y/noStaticElementInteractions: the editor around it, listening to Esc
      <div onKeyDown={(e) => outer(e.key)}>
        <Host onChange={() => {}} />
      </div>,
    );
    const btn = container.querySelector<HTMLButtonElement>(".ui-drop-current") as HTMLButtonElement;
    fireEvent.click(btn);
    fireEvent.keyDown(list() as HTMLElement, { key: "Escape" });
    expect(list()).toBeNull();
    expect(outer).not.toHaveBeenCalled();
    expect(document.activeElement).toBe(btn);
    fireEvent.click(btn);
    fireEvent.pointerDown(document.body);
    expect(list()).toBeNull();
  });

  it("an action menu: open as it appears, its words kept, closed whatever happens (3.10.1)", () => {
    const onChange = vi.fn();
    const onClose = vi.fn();
    const { container } = render(
      <DropChoice
        label="Aggiungi"
        value=""
        current="Chi?"
        options={[
          { id: "a1", label: "Anna", group: "Personali" },
          { id: "a2", label: "Ugo", group: "Progetto" },
        ]}
        startOpen
        onClose={onClose}
        onChange={onChange}
      />,
    );
    const btn = container.querySelector<HTMLButtonElement>(".ui-drop-current") as HTMLButtonElement;
    expect(btn.getAttribute("aria-label")).toBe("Aggiungi: Chi?");
    expect(list()).toBeTruthy();
    expect(items().map((b) => b.getAttribute("aria-selected"))).toEqual(["false", "false"]);
    expect(
      [...(list()?.querySelectorAll(".ui-drop-group") ?? [])].map((g) => g.textContent),
    ).toEqual(["Personali", "Progetto"]);
    fireEvent.click(items()[1] as HTMLButtonElement);
    expect(onChange).toHaveBeenCalledWith("a2");
    expect(onClose).toHaveBeenCalledTimes(1);
    expect(btn.textContent).toBe("Chi?");
    fireEvent.click(btn);
    fireEvent.pointerDown(document.body);
    expect(onClose).toHaveBeenCalledTimes(2);
    expect(onChange).toHaveBeenCalledTimes(1);
  });
});

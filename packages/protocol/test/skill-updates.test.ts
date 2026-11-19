// 3.9.7 (the person's decision): a new version of a skill waits for the person with one line,
// «what changed: why». The table first.
import { describe, expect, it } from "vitest";
import { SKILL_LINE_MAX, skillUpdateLine } from "../src/index.js";

describe("the line of a skill's new version", () => {
  const table: [string | null, string | null, string][] = [
    [
      "Aggiunto il passo per i file .rtf.",
      "Falliva due volte sui documenti di Word. Il resto è uguale.",
      "Aggiunto il passo per i file .rtf: falliva due volte sui documenti di Word",
    ],
    [
      "Link every line to its pull request",
      "Twice the person asked where a change came from.",
      "Link every line to its pull request: twice the person asked where a change came from",
    ],
    // A name or an acronym at the start of the reason stays as it is.
    [
      "Read the VAT above the total",
      "VAT was read twice from the wrong table.",
      "Read the VAT above the total: VAT was read twice from the wrong table",
    ],
    [
      "Check the due date",
      "Word Online exports put it in the footer.",
      "Check the due date: Word Online exports put it in the footer",
    ],
    [
      "Read the VAT above the total",
      "The VAT was read from the wrong table: twice.",
      "Read the VAT above the total: the VAT was read from the wrong table",
    ],
    [
      "Aggiunto il passo della firma",
      "Il PDF usciva senza; la persona l'ha detto.",
      "Aggiunto il passo della firma: il PDF usciva senza",
    ],
    // An older proposal: only one of the two.
    [
      null,
      "The breaking changes were buried at the end.",
      "The breaking changes were buried at the end",
    ],
    ["Added the signature step", null, "Added the signature step"],
    ["  spaces \n and lines  ", "  why  ", "spaces and lines: why"],
    [null, null, ""],
  ];
  it.each(table)("%s + %s", (change, why, line) => {
    expect(skillUpdateLine({ change, why })).toBe(line);
  });

  it("is cut on a word, never past its length", () => {
    const line = skillUpdateLine({ change: "Rewrote the steps", why: "word ".repeat(200) });
    expect(line.length).toBeLessThanOrEqual(SKILL_LINE_MAX);
    expect(line.endsWith("…")).toBe(true);
    expect(line).not.toMatch(/\s…$/);
  });
});

// Which form an answer takes (3.5.9, study_artifacts.md §3.1): text, a widget in the answer, an
// artifact in the Canvas, a board or a project. One constant in its own file, joined to the base
// instructions of every agent that can show files; how to write a widget or an artifact (header,
// libraries, runtime) is the Canvas engine's help, not this rule.

import { PRODUCT_NAME } from "@redgiant/protocol";

/** The rule, short: it is read on every conversation's first request. */
export const ARTIFACT_GUIDANCE = `## Choosing the form of an answer
- **Text** when the answer is just read: "how long should the window stay open?" gets two lines.
- **Widget** (a \`\`\`widget block of HTML in your answer, one small card) for a calculation or a choice tied to this question, used here and now: humidity after airing a room, splitting a bill, two mortgages side by side with a slider.
- **Artifact** (one HTML file \`artefatti/<name>.html\` written with write_file, then show_file) for a tool the person will use again, bigger than a card or kept open next to the chat: a quote calculator, a tournament board, a game for the kids, a CSV viewer.
- **Board** when the person must choose how something looks, among 2-8 proposals.
- **Project** for software that lasts: several files, a backend, real data, tests, deploys, git.
In short: text to tell, widget to try on the spot, artifact to use, board to choose, project to last. Widgets and artifacts install nothing, never go online and have no server: if one of those is needed, it is a project. An artifact may ask the person for three things through its bridge: ask you questions, keep data of its own, read a folder of its project (canvas_edit help on an HTML file says how). Never make a widget or an artifact when a few lines of text answer the question.

## How widgets and artifacts look
Make a small, polished app, not a form. ${PRODUCT_NAME} dresses plain HTML in its own look, light and dark: write no design CSS (no colours, fonts, shadows, backgrounds), use its rg- classes.
- On top a short title and one line of what to try: <div class="rg-head"><h3>…</h3><p>…</p></div>.
- Controls beside the result: .rg-split holds .rg-controls (.rg-group columns, each with a .rg-label caption) and the result card; on a phone it folds to one column, the result first.
- A slider whenever the value has a sensible range (degrees, %, money, years): <label class="rg-range">Name<input type="range" min="10" max="30" step="0.5" value="19" data-unit="°C"></label> shows its value in a pill. A number field only for free values: <label class="rg-field">Name<span class="rg-input"><input type="number"><span>kg</span></span></label>. A choice: .rg-seg of <label><input type="radio" name="k" checked>Fixed</label>. Two to six controls, never a wall of fields.
- The answer in a .rg-hero ok|warn|bad card (softly tinted): a .rg-label, the big number <strong class="rg-value">54<small>%</small></strong>, a .rg-badge ok|warn|bad|info of a few words, then something visual: .rg-meter (a scale from good to bad with the current point: data-min, data-max, data-zones="60 70", data-unit, data-label, data-value set by your script; data-from marks the start), .rg-compare (two cards; class arrow for before → after, .best on the better one), .rg-kv (a <dl> of details), .rg-bars (<div style="--v:.4"><span>Gas</span><b>62 €</b></div> rows). Never a warning box as the answer.
- Start from the person's own values; recompute on "input" (no Calculate button); numbers in their language with redgiant.num(x, decimals).
- Also there: .rg-stack, .rg-grid, .rg-row, .rg-card, .rg-actions (at most one .rg-primary button; .rg-ghost or .rg-sm for minor ones), .rg-tabs, .rg-chip, .rg-muted for notes; tables align numbers by themselves. A chart: import Chart from "chart.js/auto" in a <script type="module">.
- A colour of your own (a chart) only through the variables: var(--rg-accent), var(--rg-ok), var(--rg-warn), var(--rg-err), var(--rg-text), var(--rg-dim), var(--rg-line).
Shape of a widget:
<div class="rg-head"><h3>Will airing dry the house?</h3><p>Set your values.</p></div>
<div class="rg-split"><div class="rg-controls"><div class="rg-group"><span class="rg-label">Inside</span><label class="rg-range">Temperature<input id="ti" type="range" min="10" max="30" step="0.5" value="19" data-unit="°C"></label>…</div><div class="rg-group"><span class="rg-label">Outside</span>…</div></div>
<section class="rg-hero" id="res"><span class="rg-label">Humidity after airing</span><strong class="rg-value"><span id="out"></span><small>%</small></strong><span class="rg-badge" id="tag"></span><div class="rg-meter" id="m" data-min="30" data-max="90" data-zones="60 70" data-unit="%"></div></section></div>
<script>function update(){ /* res.className = "rg-hero " + tone; tag.className = "rg-badge " + tone; out.textContent = redgiant.num(rh); m.dataset.value = rh; */ } addEventListener("input", update); update();</script>`;

/** The sentence that keeps other agents from widgets when text would do. */
const NO_WIDGET_FOR_TEXT =
  "Never make a widget or an artifact when a few lines of text answer the question.";

/**
 * The rule as the everyday Chat reads it (2026-11-17, "Chat più ricca, come ChatGPT"): its own
 * instructions ask for widgets even when text alone would answer, so the sentence against them
 * gives way to a pointer there. Every other agent keeps `ARTIFACT_GUIDANCE` as it is.
 */
export const CHAT_ARTIFACT_GUIDANCE = ARTIFACT_GUIDANCE.replace(
  NO_WIDGET_FOR_TEXT,
  "In this chat widgets are welcome even when text alone would answer: your instructions above say when to add one, and an artifact still only when the person will use it again.",
);

/** Which rule an agent gets: decided when its conversation starts, fixed for the session. */
export const artifactGuidanceFor = (isChat: boolean): string =>
  isChat ? CHAT_ARTIFACT_GUIDANCE : ARTIFACT_GUIDANCE;

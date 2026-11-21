// Writes test/fixtures/voice_vectors.json (G42.16): hands-free voice as the page does it, from the
// page's own pure code (packages/web/src/voice/machine.ts, vad.ts, wake.ts, speakable.ts), so the
// Dart port (lib/voice/hands_free/) is checked against it and never written by heart:
// every phase × every event of the state machine, the stop phrases, the VAD on synthetic audio
// (the same recipe as the page's test), the wake word's spelling and checks, what is read of an
// answer, the WAV header.
//
//   pnpm build && node --experimental-strip-types apps/companion/tool/voice_vectors.mjs
import { writeFileSync } from "node:fs";
import { dirname, join } from "node:path";
import { fileURLToPath } from "node:url";

const here = dirname(fileURLToPath(import.meta.url));
const voice = join(here, "../../../packages/web/src/voice");
const { stepVoice, isStopPhrase } = await import(join(voice, "machine.ts"));
const { Vad, ratioFor, rms, downsample, encodeWav } = await import(join(voice, "vad.ts"));
const wake = await import(join(voice, "wake.ts"));
const speak = await import(join(voice, "speakable.ts"));

// ---- the state machine ----
const phases = [
  "off",
  "idle",
  "wake",
  "listening",
  "transcribing",
  "thinking",
  "speaking",
  "followup",
];
const events = [
  { type: "start", wake: true },
  { type: "start", wake: false },
  { type: "wake" },
  { type: "ready" },
  { type: "speechStart" },
  { type: "speechEnd" },
  { type: "silence" },
  { type: "transcribed", text: "che ore sono?" },
  { type: "transcribed", text: "  " },
  { type: "transcribed", text: "Basta, grazie." },
  { type: "answer", text: "Sono le tre." },
  { type: "answer", text: " " },
  { type: "spoken" },
  { type: "bargeIn" },
  { type: "stopWord" },
  { type: "followupOver" },
  { type: "failed", error: "offline" },
  { type: "stop" },
  { type: "off" },
];
const starts = [];
for (const phase of phases) {
  starts.push({ phase, wake: true });
  starts.push({ phase, wake: false, error: "before", heard: "ciao" });
}
const machine = [];
for (const from of starts)
  for (const event of events) {
    const { state, effects } = stepVoice(from, event);
    machine.push({ from, event, state, effects });
  }

const stopPhrases = [
  "stop",
  "Basta!",
  "ok basta grazie",
  "basta così",
  "That's all, thanks",
  "enough",
  "Ehi Rasgeth, lascia stare",
  "stop the server",
  "basta con questi errori, sistemali",
  "fine tuning",
  "",
  "  FINE.  ",
].map((text) => ({ text, stop: isStopPhrase(text) }));

// ---- the VAD, on the page's synthetic audio ----
const RATE = 16000;
function noise(seconds, height, seed = 1) {
  let x = seed;
  return Float32Array.from({ length: Math.round(seconds * RATE) }, () => {
    x = (x * 1103515245 + 12345) % 2147483648;
    return (x / 2147483648 - 0.5) * 2 * height;
  });
}
function tone(seconds, height) {
  const n = noise(seconds, height * 0.2, 7);
  return n.map(
    (v, i) =>
      v + Math.sin((2 * Math.PI * 180 * i) / RATE) * height * (0.6 + 0.4 * Math.sin(i / 900)),
  );
}
const make = (parts) => {
  const arrays = parts.map(([kind, s, h]) => (kind === "noise" ? noise(s, h) : tone(s, h)));
  const out = new Float32Array(arrays.reduce((n, p) => n + p.length, 0));
  let at = 0;
  for (const p of arrays) {
    out.set(p, at);
    at += p.length;
  }
  return out;
};
const vadCases = [
  { options: { endSilenceMs: 800 }, parts: [["noise", 1, 0.002], ["voice", 1.5, 0.2], ["noise", 1.5, 0.002]] },
  { options: {}, parts: [["noise", 1, 0.002], ["voice", 0.1, 0.3], ["noise", 1, 0.002]] },
  { options: {}, parts: [["noise", 3, 0.03], ["voice", 1, 0.2], ["noise", 1.5, 0.03]] },
  { options: { sensitivity: 0 }, parts: [["noise", 1, 0.01], ["voice", 1.2, 0.03], ["noise", 1.5, 0.01]] },
  { options: { sensitivity: 1 }, parts: [["noise", 1, 0.01], ["voice", 1.2, 0.03], ["noise", 1.5, 0.01]] },
  { options: {}, parts: [["noise", 1, 0.005], ["voice", 1, 0.05], ["noise", 1.2, 0.005]] },
  { options: { boost: 3, sensitivity: 0.3 }, parts: [["noise", 1, 0.005], ["voice", 1, 0.05], ["noise", 1.2, 0.005]] },
  { options: { maxSpeechMs: 2000 }, parts: [["noise", 0.5, 0.002], ["voice", 4, 0.2]] },
].map((c) => {
  const vad = new Vad({ sampleRate: RATE, ...c.options });
  const audio = make(c.parts);
  const out = [];
  for (let i = 0; i < audio.length; i += 4096) {
    const piece = audio.subarray(i, i + 4096);
    for (const e of vad.push(piece)) out.push([e, Math.round(((i + piece.length) / RATE) * 1000)]);
  }
  return { ...c, events: out, floor: vad.floor, threshold: vad.threshold };
});
const ratios = [0, 0.25, 0.5, 0.75, 1].map((s) => [s, ratioFor(s)]);
const levels = [
  [[], rms(new Float32Array(0))],
  [[0.5, -0.5, 0.5, -0.5], rms(Float32Array.from([0.5, -0.5, 0.5, -0.5]))],
  [[0.1, 0.2, 0.3], rms(Float32Array.from([0.1, 0.2, 0.3]))],
];
const at48 = Float32Array.from({ length: 480 }, (_, i) => Math.sin(i / 20));
const down = Array.from(downsample(at48, 48000, 16000));
const wav = Array.from(encodeWav(Float32Array.from([0, 1, -1, 2, 0.5]), 16000));

// ---- the wake word ----
const spoken = ["  Ehi, Rasgeth! ", "Ciao   Computer", "Ok RedGiant", "Hey RASGETH", "Ehi Giove"].map(
  (t) => [t, wake.spokenWake(t)],
);
const owns = [undefined, "Ehi Rasgeth", "hey RASGETH", "Ok RedGiant", "Ciao computer", " Hey computer "];
const custom = [];
for (const lang of ["it", "en"])
  for (const own of owns)
    custom.push({
      lang,
      own: own ?? null,
      custom: wake.customWake(lang, own) ?? null,
      label: wake.wakeLabel(lang, own),
      phrases: wake.wakePhrases(lang, own),
      grammar: JSON.parse(wake.wakeGrammar(lang, own)),
    });
const problems = [];
for (const lang of ["it", "en"])
  for (const text of [" ", "uno due tre quattro cinque", "Basta", "Enough", "Ehi", "Ciao computer", ...wake.WAKE_EXAMPLES[lang]])
    problems.push({ lang, text, problem: wake.wakeProblem(lang, text) ?? null });
const sure = [
  { word: "ehi", conf: 0.9 },
  { word: "ras", conf: 0.92 },
  { word: "get", conf: 0.88 },
];
const heardCases = [
  ["it", "ehi ras get", sure, 0.5, undefined],
  ["it", "ehi ras get", sure.map((w) => ({ ...w, conf: 0.6 })), 0.5, undefined],
  ["it", "ehi ras get", sure.map((w) => ({ ...w, conf: 0.6 })), 1, undefined],
  ["en", "hey ras get", [{ word: "hey", conf: 0.3 }, ...sure.slice(1)], 0.5, undefined],
  ["en", "hey raz get", [{ word: "raz", conf: 0.6 }, { word: "get", conf: 0.9 }], 0.5, undefined],
  ["en", "hey raz get", [{ word: "raz", conf: 0.6 }, { word: "get", conf: 0.9 }], 1, undefined],
  ["it", "basta", [{ word: "basta", conf: 1 }], 0.5, undefined],
  ["en", "[unk]", undefined, 0.5, undefined],
  ["en", "", undefined, 0.5, undefined],
  ["it", "ciao computer", [{ word: "ciao", conf: 0.9 }, { word: "computer", conf: 0.9 }], 0.5, "Ciao computer"],
  ["it", "ciao computer", [{ word: "ciao", conf: 0.9 }, { word: "computer", conf: 0.5 }], 0.5, "Ciao computer"],
  ["it", "ehi ras get", undefined, 0.5, "Ciao computer"],
  ["it", "allora basta", [{ word: "basta", conf: 0.9 }], 0.5, "Ciao computer"],
].map(([lang, text, words, sensitivity, own]) => ({
  lang,
  text,
  words: words ?? null,
  sensitivity,
  own: own ?? null,
  minConf: wake.minConfFor(sensitivity),
  heard: wake.classifyHeard(lang, text, words, wake.minConfFor(sensitivity), own) ?? null,
}));

// ---- what is read ----
const more = "Il resto è sullo schermo.";
const answers = [
  "Sono le **tre**.",
  "<spoken>Ecco la tabella che hai chiesto.</spoken>\n\n| a | b |\n|---|---|\n| 1 | 2 |",
  "# Titolo\n\n- uno\n- due\n\n```js\nconst x = 1;\n```\n\nVedi [la pagina](https://example.com) e `npm i`.",
  `${"Questa è una frase abbastanza lunga da riempire lo spazio. ".repeat(12)}Fine.`,
  "x".repeat(600),
  "> citazione\n\n---\n\n_corsivo_ e ~~barrato~~ <b>html</b> ![img](a.png)",
].map((md) => ({
  markdown: md,
  plain: speak.plainSpeech(md),
  spoken: speak.spokenPart(md) ?? null,
  speakable: speak.speakable(md, more),
  chunks: speak.chunksForVoice(speak.plainSpeech(md)),
}));
const hint = {
  text: "che ore sono",
  sent: speak.withVoiceHint("che ore sono"),
  stripped: speak.stripVoiceHint(speak.withVoiceHint("che ore sono")),
};

writeFileSync(
  join(here, "../test/fixtures/voice_vectors.json"),
  `${JSON.stringify(
    {
      $comment: "Generated by tool/voice_vectors.mjs from packages/web/src/voice: do not edit.",
      machine,
      stopPhrases,
      vad: { cases: vadCases, ratios, levels, downsample: down, wav },
      wake: {
        spoken,
        custom,
        problems,
        heard: heardCases,
        examples: wake.WAKE_EXAMPLES,
        defaults: wake.DEFAULT_WAKE,
        phrases: wake.WAKE_PHRASES,
        stops: wake.STOP_PHRASES,
        models: wake.WAKE_MODEL_FILES,
      },
      speak: { more, answers, hint, voiceHint: speak.VOICE_HINT },
    },
    null,
    1,
  )}\n`,
);
console.log(`voice vectors: ${machine.length} machine steps, ${vadCases.length} VAD cases`);

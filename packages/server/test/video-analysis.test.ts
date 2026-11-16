// G41.4: the pure parts of the video analysis, as tables. Fixtures are real outputs of ffprobe /
// ffmpeg 9.0.2 and whisper.cpp's whisper-cli (large-v3-turbo, DTW) on a generated 30 s clip:
// 2 s of silence, a sentence, 4.4 s of silence, a sentence, silence to the end.
import { readFileSync } from "node:fs";
import { join } from "node:path";
import { cleanTimeline, type TimeSpan, type TranscriptWord } from "@redgiant/protocol";
import { describe, expect, it } from "vitest";
import {
  breakLines,
  captionLines,
  captionsForTimeline,
  captionsToSrt,
  captionsToVtt,
  timelineWords,
} from "../src/editor/video/captions.js";
import {
  boxFilter,
  filmstripArgs,
  filmstripTiles,
  proxyArgs,
  waveformArgs,
  waveformWidth,
} from "../src/editor/video/derived.js";
import { progressSeconds } from "../src/editor/video/media-run.js";
import { parseProbe, timelineProbes, videoProbeOf } from "../src/editor/video/probe.js";
import {
  parseSilenceDetect,
  silenceArgs,
  silenceCuts,
  soundSpans,
} from "../src/editor/video/silences.js";
import { speechRatio, speechRole, speechSpans } from "../src/editor/video/speech.js";
import {
  chunkPoints,
  fromServiceAnswer,
  fromWhisperCliJson,
  interpolateWords,
  joinTranscripts,
  pcmToWav,
  shiftTranscript,
  transcribeWords,
  whisperCliArgs,
  whisperProgress,
} from "../src/editor/video/transcript.js";

const FX = join(import.meta.dirname, "fixtures", "video");
const fixture = (name: string) => readFileSync(join(FX, name), "utf8");
const json = (name: string) => JSON.parse(fixture(name)) as unknown;

describe("parseProbe (real ffprobe 9.0.2 answers)", () => {
  it.each([
    [
      "probe-clip30.json",
      {
        kind: "video",
        duration: 30,
        width: 1280,
        height: 720,
        rotation: 0,
        rate: { num: 25, den: 1 },
        codec: "h264",
        audio: true,
        audioCodec: "aac",
        createdAt: "2026-11-10T10:00:00.000000Z",
      },
    ],
    [
      // A phone's portrait clip: the display matrix says 90, the sides are swapped; NTSC rate.
      "probe-phone.json",
      {
        kind: "video",
        width: 1080,
        height: 1920,
        rotation: 90,
        rate: { num: 30000, den: 1001 },
        timecode: "01:02:03:04",
        createdAt: "2026-11-09T08:30:00.000000Z",
        audio: true,
      },
    ],
    [
      "probe-photo.json",
      { kind: "image", duration: null, width: 1600, height: 1200, rate: null, audio: false },
    ],
    [
      "probe-music.json",
      {
        kind: "audio",
        width: 0,
        height: 0,
        rate: null,
        audio: true,
        audioCodec: "aac",
        codec: null,
      },
    ],
  ])("%s", (name, want) => {
    const p = parseProbe(json(name), 1234);
    expect(p).toMatchObject({ ...want, size: 1234 });
    if (name === "probe-phone.json") expect(p.duration).toBeCloseTo(2, 1);
    if (name === "probe-music.json") expect(p.duration).toBeCloseTo(5, 1);
  });

  it.each([
    ["no streams", { streams: [], format: {} }],
    ["nothing at all", null],
  ])("refuses a file with no picture and no sound (%s)", (_, raw) => {
    expect(() => parseProbe(raw)).toThrow(/no picture and no sound/);
  });

  it("reads the old `rotate` tag and a cover picture is not the video", () => {
    const p = parseProbe({
      streams: [
        { codec_type: "video", codec_name: "mjpeg", disposition: { attached_pic: 1 } },
        { codec_type: "audio", codec_name: "mp3", sample_rate: "44100", channels: 2 },
      ],
      format: { format_name: "mp3", duration: "12.5" },
    });
    expect(p).toMatchObject({ kind: "audio", duration: 12.5, sampleRate: 44100, channels: 2 });
    const r = parseProbe({
      streams: [
        {
          codec_type: "video",
          codec_name: "h264",
          width: 1920,
          height: 1080,
          tags: { rotate: "-90" },
          avg_frame_rate: "0/0",
          r_frame_rate: "60/1",
        },
      ],
      format: { format_name: "mov,mp4", duration: "3" },
    });
    expect(r).toMatchObject({
      rotation: 270,
      width: 1080,
      height: 1920,
      rate: { num: 60, den: 1 },
    });
  });

  it("gives cleanTimeline the files' lengths at the timeline's rate", () => {
    const clip = parseProbe(json("probe-clip30.json"));
    const photo = parseProbe(json("probe-photo.json"));
    expect(videoProbeOf(clip, { num: 30000, den: 1001 })).toEqual({ frames: 899, audio: true });
    expect(videoProbeOf(clip, { num: 25, den: 1 })).toEqual({ frames: 750, audio: true });
    expect(videoProbeOf(photo, { num: 25, den: 1 })).toEqual({ frames: null });
    const raw = {
      formatVersion: 1,
      format: { width: 1920, height: 1080, rate: { num: 25, den: 1 }, aspect: "16:9" },
      tracks: [
        { id: "V1", kind: "Video" },
        { id: "V2", kind: "Video" },
      ],
      clips: [
        {
          id: "c1",
          track: "V1",
          start: 0,
          sourceRange: { start: 0, duration: 100 },
          ref: { media: "a.mp4" },
        },
        {
          id: "c2",
          track: "V2",
          start: 0,
          sourceRange: { start: 0, duration: 50 },
          ref: { media: "p.jpg" },
        },
      ],
    };
    const doc = cleanTimeline(
      raw,
      timelineProbes(
        { format: { width: 1920, height: 1080, rate: { num: 25, den: 1 }, aspect: "16:9" } },
        { "a.mp4": clip, "p.jpg": photo },
      ),
    );
    expect(doc.clips.find((c) => c.id === "c1")?.ref).toEqual({
      media: "a.mp4",
      frames: 750,
      audio: true,
    });
    expect(doc.clips.find((c) => c.id === "c2")?.ref).toEqual({ media: "p.jpg", still: true });
  });
});

// montatore's tests/test_silences.py, word for word.
const w = (start: number, end: number, text = "parola"): TranscriptWord => ({
  text,
  start,
  end,
  p: 0.9,
});
const WORDS = [w(1.0, 1.4), w(1.5, 2.0), w(3.5, 4.0), w(4.1, 4.5)];

describe("silenceCuts (montatore's compute_cuts)", () => {
  it("head, middle and tail gaps become cuts, with the margin only beside the words", () => {
    expect(
      silenceCuts(
        WORDS,
        [
          [0, 1.0],
          [2.0, 3.5],
          [4.5, 10],
        ],
        10,
        0.8,
        0.15,
      ),
    ).toEqual([
      { start: 0, end: 0.85, kind: "silence", where: "head" },
      { start: 2.15, end: 3.35, kind: "silence", where: "mid" },
      { start: 4.65, end: 10, kind: "silence", where: "tail" },
    ]);
  });

  it.each<
    [string, TranscriptWord[], TimeSpan[], number, number, number, [number, number, string][]]
  >([
    // The 0.1 s gaps and the 0.1 s tail stay; the head (1 s) and the 1.5 s pause go.
    [
      "gaps under the threshold are ignored",
      WORDS,
      [],
      4.6,
      0.8,
      0.15,
      [
        [0, 0.85, "long_pause"],
        [2.15, 3.35, "long_pause"],
      ],
    ],
    ["the margin can swallow a short cut", [w(0, 1.0), w(1.85, 2.0)], [], 2.0, 0.8, 0.3, []],
    ["no words, no cuts", [], [[0, 10]], 10, 0.8, 0.15, []],
    // Half the gap quiet is enough for "silence".
    [
      "half quiet is a silence",
      [w(0, 1), w(3, 4)],
      [[1, 2]],
      4,
      0.8,
      0.15,
      [[1.15, 2.85, "silence"]],
    ],
    [
      "less than half is a long pause",
      [w(0, 1), w(3, 4)],
      [[1, 1.9]],
      4,
      0.8,
      0.15,
      [[1.15, 2.85, "long_pause"]],
    ],
    // Exactly the threshold counts (0.8 written as 1.8 − 1.0 is 0.7999…).
    [
      "a gap of exactly minSec is cut",
      [w(0, 1.0), w(1.8, 2.5)],
      [],
      2.5,
      0.8,
      0.1,
      [[1.1, 1.7, "long_pause"]],
    ],
  ])("%s", (_, words, silent, duration, minSec, padding, want) => {
    expect(
      silenceCuts(words, silent, duration, minSec, padding).map((c) => [c.start, c.end, c.kind]),
    ).toEqual(want);
  });

  it("on the real clip: the head, the 4 s pause and the tail", () => {
    const t = fromWhisperCliJson(json("whisper-cli-clip30.json"), 30);
    const silent = parseSilenceDetect(fixture("silencedetect-clip30.txt"), 30);
    const cuts = silenceCuts(t.words, silent, 30, 0.8, 0.15);
    expect(cuts.map((c) => c.where)).toEqual(["head", "mid", "tail"]);
    expect(cuts.every((c) => c.kind === "silence")).toBe(true);
    // The real speech starts at 2.015 s and stops at 9.795 s; it starts again at 14.199 s.
    expect(cuts[0]?.end).toBeLessThan(2.015);
    expect(cuts[1]?.start).toBeGreaterThan(9.795);
    expect(cuts[1]?.end).toBeLessThan(14.199);
    expect(cuts[2]?.start).toBeGreaterThan(21.38);
    expect(cuts[2]?.end).toBe(30);
  });
});

describe("silencedetect", () => {
  it("reads ffmpeg's lines; one still open runs to the end", () => {
    expect(parseSilenceDetect(fixture("silencedetect-clip30.txt"), 30)).toEqual([
      [0, 2.015],
      [9.795, 14.199],
      [21.386, 30],
    ]);
    expect(parseSilenceDetect("[x] silence_start: 3.5\n", 8)).toEqual([[3.5, 8]]);
    expect(parseSilenceDetect("[x] silence_start: -0.02\n[x] silence_end: 1.2 | d", 8)).toEqual([
      [0, 1.2],
    ]);
    expect(parseSilenceDetect("", 8)).toEqual([]);
  });

  it("asks for half the shortest gap, as montatore", () => {
    expect(silenceArgs("in.wav", -35, 0.8)).toContain("silencedetect=noise=-35dB:d=0.400");
  });

  it.each<[TimeSpan[], number, TimeSpan[]]>([
    [
      [
        [0, 2],
        [9.8, 14.2],
        [21.4, 30],
      ],
      30,
      [
        [2, 9.8],
        [14.2, 21.4],
      ],
    ],
    [[], 5, [[0, 5]]],
    [[[0, 5]], 5, []],
    [
      [
        [1, 3],
        [2, 4],
      ],
      6,
      [
        [0, 1],
        [4, 6],
      ],
    ],
  ])("sound between the quiet stretches %#", (silent, duration, want) => {
    expect(soundSpans(silent, duration)).toEqual(want);
  });
});

describe("speech or coverage (montatore: 25% and 3 s)", () => {
  it.each<[string, "video" | "image" | "audio", number, number, "A" | "B"]>([
    ["enough speech", "video", 0.25, 3, "A"],
    ["a quarter but too short", "video", 0.5, 2.9, "B"],
    ["long but a small part", "video", 0.24, 30, "B"],
    ["a picture is always B", "image", 1, 100, "B"],
    ["sound only is never A", "audio", 1, 100, "B"],
  ])("%s", (_, kind, ratio, seconds, role) => {
    expect(speechRole(kind, ratio, seconds)).toBe(role);
  });

  it("joins words closer than half a second, drops blips", () => {
    expect(speechSpans([w(0, 0.4), w(0.7, 1.0), w(2, 2.1), w(5, 6)])).toEqual([
      [0, 1],
      [5, 6],
    ]);
  });

  it("from the real clip's words, and from the sound without a transcript", () => {
    const t = fromWhisperCliJson(json("whisper-cli-clip30.json"), 30);
    const fromWords = speechRatio({ kind: "video", duration: 30, audio: true }, { words: t.words });
    expect(fromWords.role).toBe("A");
    expect(fromWords.source).toBe("words");
    expect(fromWords.segments).toHaveLength(2);
    expect(fromWords.ratio).toBeGreaterThan(0.45);
    expect(fromWords.ratio).toBeLessThan(0.55);
    const sound = soundSpans(parseSilenceDetect(fixture("silencedetect-clip30.txt"), 30), 30);
    const fromSound = speechRatio({ kind: "video", duration: 30, audio: true }, { sound });
    expect(fromSound).toMatchObject({ source: "sound", role: "A" });
    expect(fromSound.seconds).toBeCloseTo(7.78 + 7.187, 2);
    expect(speechRatio({ kind: "video", duration: 30, audio: false }, { sound })).toMatchObject({
      ratio: 0,
      role: "B",
      source: "none",
    });
  });
});

describe("whisper.cpp's words", () => {
  it("merges DTW tokens into words, punctuation stuck to the word before", () => {
    const t = fromWhisperCliJson(json("whisper-cli-clip30.json"), 30);
    expect(t).toMatchObject({ language: "it", timing: "word", duration: 30 });
    expect(t.words.map((x) => x.text).join(" ")).toBe(
      "Buongiorno a tutti. Oggi vi mostro come si monta un video con Redjunt, partendo dalle riprese della settimana scorsa. Dopo una lunga pausa riprendo il discorso. Le parole hanno i loro tempi, e i silenzi diventano tagli proposti.",
    );
    // DTW: the first word at the sound's start (2.015 s), the second sentence after the pause.
    expect(t.words[0]).toMatchObject({ text: "Buongiorno" });
    expect(t.words[0]?.start).toBeGreaterThan(2);
    expect(t.words[0]?.start).toBeLessThan(2.3);
    const dopo = t.words.find((x) => x.text === "Dopo");
    expect(dopo?.start).toBeGreaterThan(14.1);
    expect(dopo?.start).toBeLessThan(14.5);
    // Times only move forward, and a word ends at the latest where the next starts.
    for (let i = 1; i < t.words.length; i++) {
      const a = t.words[i - 1] as TranscriptWord;
      const b = t.words[i] as TranscriptWord;
      expect(b.start).toBeGreaterThanOrEqual(a.start);
      expect(a.end).toBeLessThanOrEqual(b.start + 1e-9);
      expect(a.end).toBeGreaterThan(a.start);
    }
    expect(t.segments.map((s) => [s.w0, s.w1])).toEqual([
      [0, 18],
      [19, 37],
    ]);
  });

  it("without DTW keeps the tokens' own times, as sentence-level timing", () => {
    const t = fromWhisperCliJson(
      {
        result: { language: "en" },
        transcription: [
          {
            offsets: { from: 0, to: 2000 },
            text: " Hello there.",
            tokens: [
              { text: "[_BEG_]", offsets: { from: 0, to: 0 }, t_dtw: -1 },
              { text: " Hel", offsets: { from: 100, to: 400 }, t_dtw: -1, p: 0.9 },
              { text: "lo", offsets: { from: 400, to: 600 }, t_dtw: -1, p: 0.7 },
              { text: " there", offsets: { from: 700, to: 1200 }, t_dtw: -1 },
              { text: ".", offsets: { from: 1200, to: 1300 }, t_dtw: -1 },
              { text: "[_TT_100]", offsets: { from: 2000, to: 2000 }, t_dtw: -1 },
            ],
          },
        ],
      },
      2,
    );
    expect(t.timing).toBe("segment");
    expect(t.words).toEqual([
      { text: "Hello", start: 0.1, end: 0.6, p: 0.8 },
      { text: "there.", start: 0.7, end: 1.2, p: 1 },
    ]);
  });

  it.each([
    [
      "whisper-cli",
      whisperCliArgs({ model: "m.bin", wav: "a.wav", outBase: "out", language: "it", threads: 7 }),
    ],
  ])("asks %s for DTW without flash attention and the full JSON", (_, args) => {
    expect(args.join(" ")).toBe(
      "-m m.bin -f a.wav -l it -t 7 -dtw large.v3.turbo -nfa -ojf -of out -pp -np",
    );
    expect(whisperCliArgs({ model: "m", wav: "a", outBase: "o", threads: 1 })).toContain("auto");
  });

  it.each([
    ["whisper_print_progress_callback: progress =  45%", 45],
    ["whisper_print_progress_callback: progress = 100%", 100],
    ["output_json: saving output to 'x.json'", undefined],
  ])("progress from %j", (line, want) => {
    expect(whisperProgress(line)).toBe(want);
  });
});

describe("services' answers", () => {
  const sound: TimeSpan[] = [
    [1, 3],
    [5, 7],
  ];

  it("OpenAI / Groq verbose_json with word timestamps", () => {
    const t = fromServiceAnswer(
      JSON.stringify({
        language: "italian",
        duration: 8,
        text: "Ciao a tutti. Come va?",
        words: [
          { word: "Ciao", start: 1.0, end: 1.3 },
          { word: "a", start: 1.35, end: 1.4 },
          { word: "tutti.", start: 1.45, end: 1.9 },
          { word: "Come", start: 5.1, end: 5.4 },
          { word: "va?", start: 5.45, end: 5.8 },
        ],
        segments: [
          { start: 0.9, end: 2.0, text: " Ciao a tutti." },
          { start: 5.0, end: 6.0, text: " Come va?" },
        ],
      }),
      8,
      sound,
    );
    expect(t).toMatchObject({ language: "it", timing: "word" });
    expect(t.words.map((x) => x.text)).toEqual(["Ciao", "a", "tutti.", "Come", "va?"]);
    expect(t.segments).toEqual([
      { start: 1, end: 1.9, text: "Ciao a tutti.", w0: 0, w1: 2 },
      { start: 5.1, end: 5.8, text: "Come va?", w0: 3, w1: 4 },
    ]);
  });

  it("ElevenLabs Scribe: words, spacing and sound events", () => {
    const t = fromServiceAnswer(
      JSON.stringify({
        language_code: "ita",
        text: "Ciao. (risata) Bene.",
        words: [
          { text: "Ciao.", start: 0.5, end: 0.9, type: "word" },
          { text: " ", start: 0.9, end: 1.0, type: "spacing" },
          { text: "(risata)", start: 1.0, end: 2.0, type: "audio_event" },
          { text: "Bene.", start: 2.2, end: 2.6, type: "word" },
        ],
      }),
      3,
      [],
    );
    expect(t.language).toBe("it");
    expect(t.words.map((x) => [x.text, x.start, x.end])).toEqual([
      ["Ciao.", 0.5, 0.9],
      ["Bene.", 2.2, 2.6],
    ]);
    expect(t.segments.map((s) => s.text)).toEqual(["Ciao.", "Bene."]);
  });

  it("whisper-asr-webservice: segments with their own words", () => {
    const t = fromServiceAnswer(
      JSON.stringify({
        language: "en",
        segments: [
          {
            start: 0,
            end: 1,
            text: " Hi all.",
            words: [
              { word: " Hi", start: 0.1, end: 0.3, probability: 0.9 },
              { word: " all.", start: 0.35, end: 0.8 },
            ],
          },
        ],
      }),
      1,
      [],
    );
    expect(t.timing).toBe("word");
    expect(t.words).toEqual([
      { text: "Hi", start: 0.1, end: 0.3, p: 0.9 },
      { text: "all.", start: 0.35, end: 0.8 },
    ]);
  });

  it("segments without words: spread inside each sentence", () => {
    const t = fromServiceAnswer(
      JSON.stringify({ segments: [{ start: 2, end: 4, text: "uno due" }] }),
      5,
      [],
    );
    expect(t.timing).toBe("segment");
    expect(t.words.map((x) => x.text)).toEqual(["uno", "due"]);
    expect(t.words[0]?.start).toBe(2);
    expect(t.words[1]?.end).toBeLessThanOrEqual(4);
  });

  it.each([
    ["plain text", "uno due tre quattro"],
    ["JSON with only text (gpt-4o-transcribe)", JSON.stringify({ text: "uno due tre quattro" })],
  ])("%s: spread over the stretches with sound", (_, body) => {
    const t = fromServiceAnswer(body, 8, sound);
    expect(t.timing).toBe("interpolated");
    expect(t.words.map((x) => x.text)).toEqual(["uno", "due", "tre", "quattro"]);
    for (const x of t.words) {
      const inside = sound.some(([s, e]) => x.start >= s - 1e-9 && x.end <= e + 1e-9);
      expect(inside, `${x.text} ${x.start}-${x.end}`).toBe(true);
    }
  });

  it("interpolation keeps order and gives nothing without sound", () => {
    expect(interpolateWords("a b", [])).toEqual([]);
    expect(interpolateWords("", [[0, 1]])).toEqual([]);
    const ws = interpolateWords("aa bb cc", [[0, 3]]);
    expect(ws.map((x) => x.start)).toEqual([0, 1, 2]);
  });
});

describe("long recordings for the services", () => {
  it.each<[number, TimeSpan[], number[]]>([
    [500, [], []],
    // A hard cut every ten minutes without quiet.
    [1500, [], [600, 1200]],
    // In the middle of the last quiet stretch before the limit.
    [
      1000,
      [
        [400, 420],
        [580, 590],
        [700, 720],
      ],
      [585],
    ],
    // A quiet stretch across the limit: cut in its part before it.
    [1000, [[590, 650]], [595]],
  ])("%s s", (duration, silent, want) => {
    expect(chunkPoints(duration, silent)).toEqual(want);
  });

  it("moves a piece's times and joins the pieces", () => {
    const a = fromServiceAnswer(
      JSON.stringify({ words: [{ word: "uno.", start: 1, end: 2 }] }),
      600,
      [],
    );
    const b = fromServiceAnswer(
      JSON.stringify({ words: [{ word: "due.", start: 0.5, end: 1 }] }),
      400,
      [],
    );
    const joined = joinTranscripts(
      [
        { ...a, engine: "OpenAI" },
        { ...shiftTranscript(b, 600), engine: "OpenAI" },
      ],
      1000,
    );
    expect(joined.words.map((x) => [x.text, x.start])).toEqual([
      ["uno.", 1],
      ["due.", 600.5],
    ]);
    expect(joined.segments.map((s) => [s.w0, s.w1])).toEqual([
      [0, 0],
      [1, 1],
    ]);
  });

  it("wraps raw 16 kHz samples in a WAV header", () => {
    const wav = pcmToWav(new Uint8Array([1, 2, 3, 4, 5]));
    const b = Buffer.from(wav);
    expect(b.length).toBe(48);
    expect(b.toString("latin1", 0, 4)).toBe("RIFF");
    expect(b.readUInt32LE(24)).toBe(16000);
    expect(b.readUInt32LE(40)).toBe(4);
  });
});

describe("transcribeWords (recorded HTTP)", () => {
  function recorder(answer: () => Response) {
    const seen: { url: string; init: RequestInit }[] = [];
    const f = (async (url: string | URL, init: RequestInit = {}) => {
      seen.push({ url: String(url), init });
      return answer();
    }) as typeof fetch;
    return { f, seen };
  }
  const wav = pcmToWav(new Uint8Array(3200));

  it("asks OpenAI for verbose_json with word and segment times", async () => {
    const { f, seen } = recorder(() =>
      Response.json({ language: "english", words: [{ word: "Hi.", start: 0, end: 0.2 }] }),
    );
    const t = await transcribeWords(
      wav,
      {
        api: "openai",
        url: "https://api.example/v1/",
        model: "whisper-1",
        key: "k1",
        name: "OpenAI",
      },
      { duration: 0.1, sound: [], language: "en", fetch: f },
    );
    expect(t).toMatchObject({
      engine: "OpenAI",
      model: "whisper-1",
      language: "en",
      timing: "word",
    });
    expect(seen[0]?.url).toBe("https://api.example/v1/audio/transcriptions");
    expect(seen[0]?.init.headers).toEqual({ authorization: "Bearer k1" });
    const body = seen[0]?.init.body as FormData;
    expect(body.get("response_format")).toBe("verbose_json");
    expect(body.getAll("timestamp_granularities[]")).toEqual(["word", "segment"]);
    expect((body.get("file") as File).type).toBe("audio/wav");
  });

  it("a model that answers only JSON text is asked for json and interpolated", async () => {
    const { f, seen } = recorder(() => Response.json({ text: "ciao mondo" }));
    const t = await transcribeWords(
      wav,
      {
        api: "openai",
        url: "https://api.example/v1",
        model: "gpt-4o-transcribe",
        key: "k",
        json: true,
      },
      { duration: 2, sound: [[0.5, 1.5]], fetch: f },
    );
    expect(t.timing).toBe("interpolated");
    const body = seen[0]?.init.body as FormData;
    expect(body.get("response_format")).toBe("json");
    expect(body.getAll("timestamp_granularities[]")).toEqual([]);
  });

  it("ElevenLabs with its key header; whisper-asr with word_timestamps", async () => {
    const el = recorder(() =>
      Response.json({ words: [{ text: "Ok", start: 0, end: 0.1, type: "word" }] }),
    );
    await transcribeWords(
      wav,
      { api: "elevenlabs", url: "https://api.elevenlabs.io/v1", key: "x" },
      { duration: 1, sound: [], fetch: el.f },
    );
    expect(el.seen[0]?.url).toBe("https://api.elevenlabs.io/v1/speech-to-text");
    expect(el.seen[0]?.init.headers).toEqual({ "xi-api-key": "x" });
    expect((el.seen[0]?.init.body as FormData | undefined)?.get("timestamps_granularity")).toBe(
      "word",
    );
    const asr = recorder(() => Response.json({ segments: [] }));
    await transcribeWords(
      wav,
      { api: "whisper-asr", url: "http://w:9000" },
      { duration: 1, sound: [], language: "it", fetch: asr.f },
    );
    const q = new URL(asr.seen[0]?.url ?? "").searchParams;
    expect([q.get("output"), q.get("word_timestamps"), q.get("language")]).toEqual([
      "json",
      "true",
      "it",
    ]);
  });

  it.each([
    [401, "voice_key_refused"],
    [429, "voice_rate_limited"],
    [500, "voice_service_error"],
  ])("an answer %s is the voice notes' error", async (status, code) => {
    const { f } = recorder(() => new Response("no", { status }));
    await expect(
      transcribeWords(
        wav,
        { api: "openai", url: "https://x/v1", key: "k" },
        { duration: 1, sound: [], fetch: f },
      ),
    ).rejects.toMatchObject({ code });
  });

  it("no key yet: refused before any request", async () => {
    const { f, seen } = recorder(() => Response.json({}));
    await expect(
      transcribeWords(
        wav,
        { api: "elevenlabs", url: "https://x" },
        { duration: 1, sound: [], fetch: f },
      ),
    ).rejects.toMatchObject({ code: "voice_no_key" });
    expect(seen).toHaveLength(0);
  });
});

describe("captions", () => {
  it.each<[string[], number, string[] | null]>([
    [["Ciao", "a", "tutti."], 42, ["Ciao a tutti."]],
    // Two lines as even as possible, preferring a break after a comma.
    [
      [
        "Le",
        "parole",
        "hanno",
        "i",
        "loro",
        "tempi,",
        "e",
        "i",
        "silenzi",
        "diventano",
        "tagli",
        "proposti.",
      ],
      42,
      ["Le parole hanno i loro tempi,", "e i silenzi diventano tagli proposti."],
    ],
    [
      [
        "Oggi",
        "vi",
        "mostro,",
        "come",
        "si",
        "monta",
        "un",
        "video",
        "con",
        "RedGiant",
        "partendo",
        "dalle",
      ],
      42,
      ["Oggi vi mostro, come si monta un", "video con RedGiant partendo dalle"],
    ],
    [["abcdefghij", "abcdefghij"], 15, ["abcdefghij", "abcdefghij"]],
    [["abcdefghijklmnop"], 10, null],
  ])("breakLines %#", (words, max, want) => {
    expect(breakLines(words, max, 2)).toEqual(want);
  });

  it("subtitles at most 2×42, a new one at a sentence's end or a pause, at least a second", () => {
    const t = fromWhisperCliJson(json("whisper-cli-clip30.json"), 30);
    const lines = captionLines(t.words);
    for (const c of lines) {
      const rows = c.text.split("\n");
      expect(rows.length).toBeLessThanOrEqual(2);
      for (const r of rows) expect(r.length).toBeLessThanOrEqual(42);
      expect(c.end - c.start).toBeGreaterThanOrEqual(1 - 1e-9);
    }
    expect(lines.map((c) => c.words.map((x) => x.text).join(" ")).join(" ")).toBe(
      t.words.map((x) => x.text).join(" "),
    );
    expect(lines[0]?.text).toBe("Buongiorno a tutti.");
    // Full at "della": it ends at the comma instead, the rest goes on with the next words.
    expect(lines[1]?.text).toBe("Oggi vi mostro come si\nmonta un video con Redjunt,");
    expect(lines[2]?.text).toBe("partendo dalle riprese\ndella settimana scorsa.");
    // Nothing spans the 4 s pause.
    expect(lines.some((c) => c.start < 10 && c.end > 14)).toBe(false);
  });

  it("a short subtitle is stretched only up to the next one", () => {
    const lines = captionLines([w(0, 0.2, "Sì."), w(0.5, 0.7, "No."), w(5, 5.2, "Forse.")]);
    expect(lines.map((c) => [c.text, c.start, c.end])).toEqual([
      ["Sì. No.", 0, 1],
      ["Forse.", 5, 6],
    ]);
    const tight = captionLines([w(0, 0.2, "Uno."), w(0.3, 0.4, "Due."), w(0.5, 0.6, "Tre.")], {
      minSec: 1,
    });
    // A sentence ends a subtitle once it has two words; the first stops where the next starts.
    expect(tight.map((c) => [c.text, c.start, c.end])).toEqual([
      ["Uno. Due.", 0, 0.5],
      ["Tre.", 0.5, 1.5],
    ]);
  });

  const rate = { num: 25, den: 1 };
  const caps = [
    { start: 50, end: 100, text: "Buongiorno a tutti." },
    { start: 0, end: 25, text: "Prima\nriga" },
    { start: 3600 * 25 + 30, end: 3600 * 25 + 60, text: "Un'ora --> dopo" },
    { start: 120, end: 120, text: "vuoto" },
  ];

  it("SRT: in order, numbered, commas in the times, empty ones out", () => {
    expect(captionsToSrt(caps, rate)).toBe(
      "1\n00:00:00,000 --> 00:00:01,000\nPrima\nriga\n\n2\n00:00:02,000 --> 00:00:04,000\nBuongiorno a tutti.\n\n3\n01:00:01,200 --> 01:00:02,400\nUn'ora --> dopo\n",
    );
  });

  it("WebVTT: the header, dots in the times, the cue text escaped (no arrow inside a cue)", () => {
    expect(captionsToVtt(caps, rate)).toBe(
      "WEBVTT\n\n00:00:00.000 --> 00:00:01.000\nPrima\nriga\n\n00:00:02.000 --> 00:00:04.000\nBuongiorno a tutti.\n\n01:00:01.200 --> 01:00:02.400\nUn'ora --&gt; dopo\n",
    );
    expect(captionsToVtt([], rate)).toBe("WEBVTT\n\n");
    // NTSC: frames to milliseconds at 30000/1001.
    expect(captionsToSrt([{ start: 30, end: 60, text: "x" }], { num: 30000, den: 1001 })).toContain(
      "00:00:01,001 --> 00:00:02,002",
    );
  });

  // A: speaker on V1 with its sound on A1; an L-cut: the sound of clip 1 goes on 1 s over the
  // picture of the coverage on V1.
  const doc = cleanTimeline({
    formatVersion: 1,
    format: { width: 1920, height: 1080, rate: { num: 25, den: 1 }, aspect: "16:9" },
    tracks: [
      { id: "V1", kind: "Video" },
      { id: "A1", kind: "Audio" },
      { id: "A2", kind: "Audio", muted: true },
    ],
    clips: [
      {
        id: "v1",
        track: "V1",
        start: 0,
        sourceRange: { start: 50, duration: 100 },
        ref: { media: "a.mp4" },
        link: "l1",
      },
      // The sound runs 25 frames longer than its picture (L-cut).
      {
        id: "a1",
        track: "A1",
        start: 0,
        sourceRange: { start: 50, duration: 125 },
        ref: { media: "a.mp4" },
        link: "l1",
      },
      {
        id: "a2",
        track: "A1",
        start: 200,
        sourceRange: { start: 0, duration: 50 },
        ref: { media: "b.mp4" },
      },
      {
        id: "off",
        track: "A1",
        start: 300,
        sourceRange: { start: 0, duration: 50 },
        ref: { media: "b.mp4" },
        enabled: false,
      },
      {
        id: "mute",
        track: "A2",
        start: 0,
        sourceRange: { start: 0, duration: 50 },
        ref: { media: "b.mp4" },
      },
    ],
  });
  const transcripts = {
    // a.mp4: words at 1 s (before the part played), 2.5 s, 6.5 s (inside the L-cut), 8 s (after).
    "a.mp4": {
      words: [w(1, 1.4, "prima"), w(2.5, 3, "dentro"), w(6.5, 6.8, "coda."), w(8, 8.5, "fuori")],
    },
    "b.mp4": { words: [w(0.2, 0.6, "altro.")] },
  };

  it("the timeline's words follow its audio clips (an L-cut keeps its words)", () => {
    expect(timelineWords(doc, transcripts).map((x) => [x.text, x.start, x.end, x.clip])).toEqual([
      ["dentro", 13, 25, "a1"],
      ["coda.", 113, 120, "a1"],
      ["altro.", 205, 215, "a2"],
    ]);
  });

  it("subtitles for the timeline in its frames, ready for setCaptionSegments", () => {
    const segs = captionsForTimeline(doc, transcripts);
    expect(segs.map((s) => [s.text, s.start, s.end])).toEqual([
      // The 4 s pause splits them; each stays a second at least.
      ["dentro", 13, 38],
      ["coda.", 113, 138],
      ["altro.", 205, 230],
    ]);
    expect(segs[1]?.words).toEqual([{ start: 113, end: 120, text: "coda." }]);
  });
});

describe("derived files (montatore's parameters)", () => {
  it("proxy: CRF 28, inside 960, a keyframe every 10, AAC 96k, faststart", () => {
    const a = proxyArgs("in.mov", "out.mp4", true).join(" ");
    expect(a).toContain(boxFilter(960));
    expect(a).toContain("-c:v libx264 -preset veryfast -crf 28 -pix_fmt yuv420p -g 10");
    expect(a).toContain("-map 0:a:0 -c:a aac -b:a 96k -ac 2");
    expect(a).toContain("-movflags +faststart");
    expect(a).toContain("-progress pipe:1");
    expect(proxyArgs("in.mov", "out.mp4", false).join(" ")).not.toContain("aac");
  });

  it.each([
    [0.4, 1],
    [30, 30],
    [30.9, 30],
    [600, 120],
  ])("strip of a %s s clip has %s tiles of 160×90", (duration, tiles) => {
    expect(filmstripTiles(duration)).toBe(tiles);
    expect(filmstripArgs("p.mp4", "s.jpg", duration).join(" ")).toContain(
      `scale=160:90:force_original_aspect_ratio=increase,crop=160:90,tile=${tiles}x1`,
    );
  });

  it.each([
    [1, 200],
    [30, 1200],
    [600, 8000],
  ])("waveform of %s s: %s px", (duration, width) => {
    expect(waveformWidth(duration)).toBe(width);
    expect(waveformArgs("a.mp4", "w.png", duration).join(" ")).toContain(
      `showwavespic=s=${width}x64:colors=#ffffff:scale=sqrt`,
    );
  });

  it.each([
    ["out_time_us=1500000", 1.5],
    ["out_time_ms=2000000", 2],
    ["out_time=00:00:01.50", undefined],
    ["progress=end", undefined],
  ])("ffmpeg progress %j", (line, want) => {
    expect(progressSeconds(line)).toBe(want);
  });
});

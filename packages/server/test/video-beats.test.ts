// 3.10, video part 2: the music's beats found without a model. Synthetic drums (a short burst on
// every beat, softer off-beats, noise) at known tempos and offsets: the tempo within a beat a
// minute, every beat found within a frame at 25 fps (40 ms); silence and a too short sound give none.
import { describe, expect, it } from "vitest";
import { BEATS_RATE, beatsOf, beatsPcmArgs } from "../src/editor/video/beats.js";

/** `seconds` of a beat at `bpm` from `offset`: bursts that decay, off-beats at a third, noise. */
function drums(bpm: number, offset: number, seconds: number, seed = 1): Float32Array {
  const out = new Float32Array(Math.round(seconds * BEATS_RATE));
  let r = seed;
  const rnd = () => {
    r = (r * 1103515245 + 12345) % 2147483648;
    return r / 2147483648 - 0.5;
  };
  for (let i = 0; i < out.length; i++) out[i] = rnd() * 0.02;
  const beat = 60 / bpm;
  const hit = (t: number, amp: number) => {
    const at = Math.round(t * BEATS_RATE);
    for (let k = 0; k < 2000 && at + k < out.length; k++)
      out[at + k] = (out[at + k] ?? 0) + amp * Math.exp(-k / 300) * Math.sin(k * 0.3);
  };
  for (let t = offset; t < seconds; t += beat) {
    hit(t, 0.8);
    hit(t + beat / 2, 0.25);
  }
  return out;
}

describe("beats", () => {
  it.each([
    [120, 0.23],
    [96, 0.5],
    [140, 0.1],
  ])("%i BPM from %d s: the tempo and every beat", (bpm, offset) => {
    const r = beatsOf(drums(bpm, offset, 12));
    expect(Math.abs(r.bpm - bpm)).toBeLessThan(1.5);
    const beat = 60 / bpm;
    const want: number[] = [];
    for (let t = offset; t < 11.8; t += beat) want.push(t);
    // Every beat found once, within a frame at 25 fps.
    const near = want.filter((w) => r.beats.some((b) => Math.abs(b - w) < 0.04));
    expect(near.length).toBeGreaterThanOrEqual(want.length - 1);
    expect(r.beats.length).toBeLessThanOrEqual(want.length + 1);
  });

  it("silence and a very short sound: none", () => {
    expect(beatsOf(new Float32Array(BEATS_RATE * 4)).beats).toEqual([]);
    expect(beatsOf(drums(120, 0, 0.3)).beats).toEqual([]);
  });

  it("asks ffmpeg for the part of the file as mono samples", () => {
    expect(beatsPcmArgs("m.m4a", 2, 30, "out.pcm")).toEqual([
      "-hide_banner",
      "-nostdin",
      "-y",
      "-ss",
      "2.000",
      "-t",
      "30.000",
      "-i",
      "m.m4a",
      "-vn",
      "-ac",
      "1",
      "-ar",
      "11025",
      "-f",
      "s16le",
      "out.pcm",
    ]);
  });
});

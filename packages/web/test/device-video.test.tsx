// @vitest-environment jsdom
// 3.11 phase 7: a device's H.264 in the page. The codec read from the SPS, the configuration put in
// front of the next key frame, deltas before it dropped, a browser that cannot decode the profile
// falls back to JPEG once; the view asks for H.264 only where a decoder exists, and goes back to
// JPEG frames when decoding fails.
import { cleanup, render } from "@testing-library/preact";
import { afterEach, beforeEach, describe, expect, it, vi } from "vitest";
import { codecFromSps, H264Canvas } from "../src/device-video.js";

const sent: unknown[] = [];
vi.mock("../src/state.js", async (orig) => ({
  ...(await orig<typeof import("../src/state.js")>()),
  getLive: () => ({ send: (m: unknown) => sent.push(m) }),
}));
const { DeviceScreen } = await import("../src/components/DeviceScreen.js");
const { applyMessage } = await import("../src/state.js");

const b64 = (bytes: number[]) => btoa(String.fromCharCode(...bytes));
// SPS (Baseline 66, constraints 0xC0, level 3.1) and PPS, Annex B.
const CONFIG = [0, 0, 0, 1, 0x67, 66, 0xc0, 31, 0xaa, 0, 0, 0, 1, 0x68, 0xce];
const KEY = [0, 0, 0, 1, 0x65, 1, 2, 3];
const DELTA = [0, 0, 0, 1, 0x41, 9];

class FakeDecoder {
  static supported = true;
  static made: FakeDecoder[] = [];
  state = "unconfigured";
  codec = "";
  chunks: { type: string; data: Uint8Array }[] = [];
  constructor(readonly init: { output: (f: unknown) => void; error: (e: Error) => void }) {
    FakeDecoder.made.push(this);
  }
  static async isConfigSupported() {
    return { supported: FakeDecoder.supported };
  }
  configure(c: { codec: string }) {
    this.codec = c.codec;
    this.state = "configured";
  }
  decode(chunk: { type: string; data: Uint8Array }) {
    this.chunks.push(chunk);
  }
  close() {
    this.state = "closed";
  }
}
class FakeChunk {
  type: string;
  data: Uint8Array;
  constructor(i: { type: string; data: Uint8Array }) {
    this.type = i.type;
    this.data = i.data;
  }
}

beforeEach(() => {
  sent.length = 0;
  FakeDecoder.made = [];
  FakeDecoder.supported = true;
  vi.stubGlobal("VideoDecoder", FakeDecoder);
  vi.stubGlobal("EncodedVideoChunk", FakeChunk);
});
afterEach(() => {
  cleanup();
  vi.unstubAllGlobals();
});

describe("a device's H.264 in the page", () => {
  it.each([
    [CONFIG, "avc1.42C01F"],
    [[0, 0, 1, 0x67, 100, 0, 40], "avc1.640028"],
    [[0, 0, 0, 1, 0x68, 1, 2, 3], undefined],
  ])("the codec of %j is %s", (bytes, want) => {
    expect(codecFromSps(Uint8Array.from(bytes))).toBe(want);
  });

  it("puts the configuration in front of the key frame and drops deltas before it", async () => {
    const failed = vi.fn();
    const h = new H264Canvas(() => null, failed);
    const p = (bytes: number[], config = false, key = false) =>
      h.push({ data: b64(bytes), config, key, width: 576, height: 1280 });
    await p(CONFIG, true, true);
    const d = FakeDecoder.made[0] as FakeDecoder;
    expect(d.codec).toBe("avc1.42C01F");
    await p(DELTA);
    expect(d.chunks).toHaveLength(0);
    await p(KEY, false, true);
    await p(DELTA);
    expect(d.chunks.map((c) => [c.type, c.data.length])).toEqual([
      ["key", CONFIG.length + KEY.length],
      ["delta", DELTA.length],
    ]);
    expect(failed).not.toHaveBeenCalled();
  });

  it("a profile this browser cannot decode: says so once", async () => {
    FakeDecoder.supported = false;
    const failed = vi.fn();
    const h = new H264Canvas(() => null, failed);
    await h.push({ data: b64(CONFIG), config: true, key: true, width: 1, height: 1 });
    await h.push({ data: b64(CONFIG), config: true, key: true, width: 1, height: 1 });
    expect(failed).toHaveBeenCalledTimes(1);
  });

  it("the view asks for H.264 where it can, and goes back to JPEG when decoding fails", async () => {
    FakeDecoder.supported = false;
    render(<DeviceScreen device="avd:P" title="P" />);
    expect(sent[0]).toEqual({ type: "device.watch", id: "avd:P", format: "h264" });
    applyMessage({ type: "device.video", id: "avd:P", data: b64(CONFIG), config: true, key: true, width: 1, height: 1 });
    await vi.waitFor(() => expect(sent).toContainEqual({ type: "device.watch", id: "avd:P" }));
    expect(sent).toContainEqual({ type: "device.unwatch", id: "avd:P" });
  });

  it("without a decoder it asks for JPEG frames", () => {
    vi.unstubAllGlobals();
    render(<DeviceScreen device="avd:Q" title="Q" />);
    expect(sent.filter((m) => (m as { id?: string }).id === "avd:Q")[0]).toEqual({
      type: "device.watch",
      id: "avd:Q",
    });
  });
});

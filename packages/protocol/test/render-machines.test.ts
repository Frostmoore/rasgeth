// G41.7: the machines a video can be rendered on, and where a render goes (R2), as tables.
import { describe, expect, it } from "vitest";
import {
  type FfmpegInfo,
  type NodeCapabilities,
  type RenderMachine,
  type RenderWhere,
  renderMachines,
  renderWhere,
} from "../src/index.js";

const ffmpeg = (version: string, nvenc: boolean): FfmpegInfo => ({
  version,
  major: Number(version.replace(/^n/, "").split(".")[0]),
  source: "path",
  ffprobe: true,
  missing: [],
  encoders: nvenc ? ["h264_nvenc", "libx264"] : ["libx264"],
});

const caps = (o: Partial<NodeCapabilities>): NodeCapabilities => ({
  sandbox: { ok: true, container: false },
  models: [],
  storage: { ok: true },
  ...o,
});

const rig = caps({
  gpus: [
    { vendor: "intel", name: "Intel UHD 770", vramGb: 0, integrated: true },
    { vendor: "nvidia", name: "NVIDIA GeForce RTX 4080 SUPER", vramGb: 16 },
  ],
  media: {
    ffmpeg: ffmpeg("9.0.1-full_build-www.gyan.dev", true),
    download: true,
    nvenc: true,
    encoder: "h264_nvenc",
  },
});
const coder = caps({ gpus: [], media: { download: true, nvenc: false } });
const old = caps({});

describe("renderMachines (G41.7)", () => {
  it("lists this machine first, then each node with what it offers", () => {
    const list = renderMachines(
      { name: "this machine", media: { download: true, nvenc: false, encoder: "libx264" } },
      [
        {
          fingerprint: "SHA256:rig",
          name: "Rig",
          online: true,
          rights: ["use"],
          capabilities: rig,
        },
        { fingerprint: "SHA256:coder", name: "Coder", online: true, capabilities: coder },
        {
          fingerprint: "SHA256:old",
          name: "Old",
          online: true,
          rights: ["use"],
          capabilities: old,
        },
        { fingerprint: "SHA256:off", name: "Monnezza", online: false, capabilities: rig },
        {
          fingerprint: "SHA256:none",
          name: "Nobody",
          online: true,
          rights: [],
          capabilities: rig,
        },
      ],
    );
    expect(list).toEqual<RenderMachine[]>([
      { id: "here", name: "this machine", ok: true, nvenc: false, download: true },
      {
        id: "SHA256:rig",
        name: "Rig",
        ok: true,
        gpu: "NVIDIA GeForce RTX 4080 SUPER",
        nvenc: true,
        ffmpeg: "9.0.1",
      },
      // Rights not reported yet: tried, the node decides.
      { id: "SHA256:coder", name: "Coder", ok: true, nvenc: false, download: true },
      // Before 3.9: no `media` operation there.
      { id: "SHA256:old", name: "Old", ok: false, reason: "no-media", nvenc: false },
      {
        id: "SHA256:off",
        name: "Monnezza",
        ok: false,
        reason: "offline",
        gpu: "NVIDIA GeForce RTX 4080 SUPER",
        nvenc: true,
        ffmpeg: "9.0.1",
      },
      {
        id: "SHA256:none",
        name: "Nobody",
        ok: false,
        reason: "no-right",
        gpu: "NVIDIA GeForce RTX 4080 SUPER",
        nvenc: true,
        ffmpeg: "9.0.1",
      },
    ]);
  });

  it("a machine without ffmpeg and nothing to download cannot render", () => {
    const [here] = renderMachines({ name: "x", media: { download: false, nvenc: false } }, []);
    expect(here).toMatchObject({ ok: false, reason: "no-ffmpeg" });
  });
});

const here: RenderMachine = { id: "here", name: "this machine", ok: true, nvenc: false };
const rigM: RenderMachine = { id: "SHA256:rig", name: "Rig", ok: true, nvenc: true };
const coderM: RenderMachine = { id: "SHA256:coder", name: "Coder", ok: true, nvenc: false };
const offM: RenderMachine = {
  id: "SHA256:off",
  name: "Monnezza",
  ok: false,
  reason: "offline",
  nvenc: false,
};
const all = [here, rigM, coderM, offM];

type Row = [
  string,
  {
    machines: RenderMachine[];
    remembered?: string;
    asked?: string;
    byPerson: boolean;
  },
  RenderWhere,
];
const table: Row[] = [
  // The person (the page) chooses: remembered when it changes.
  [
    "person, first time",
    { machines: all, asked: "SHA256:rig", byPerson: true },
    { kind: "use", id: "SHA256:rig", remember: true },
  ],
  [
    "person, same as before",
    { machines: all, remembered: "SHA256:rig", asked: "SHA256:rig", byPerson: true },
    { kind: "use", id: "SHA256:rig", remember: false },
  ],
  [
    "person changes it",
    { machines: all, remembered: "SHA256:rig", asked: "here", byPerson: true },
    { kind: "use", id: "here", remember: true },
  ],
  [
    "person, by name",
    { machines: all, asked: "coder", byPerson: true },
    { kind: "use", id: "SHA256:coder", remember: true },
  ],
  [
    "person, a machine offline",
    { machines: all, asked: "Monnezza", byPerson: true },
    { kind: "refuse", reason: "offline", id: "SHA256:off" },
  ],
  [
    "person, unknown",
    { machines: all, asked: "Pluto", byPerson: true },
    { kind: "refuse", reason: "unknown" },
  ],
  ["page without a choice, nothing remembered", { machines: all, byPerson: true }, { kind: "ask" }],
  // An agent follows the person's choice.
  [
    "agent, remembered",
    { machines: all, remembered: "SHA256:rig", byPerson: false },
    { kind: "use", id: "SHA256:rig", remember: false },
  ],
  [
    "agent asks the same",
    { machines: all, remembered: "SHA256:rig", asked: "Rig", byPerson: false },
    { kind: "use", id: "SHA256:rig", remember: false },
  ],
  [
    "agent asks another",
    { machines: all, remembered: "SHA256:rig", asked: "here", byPerson: false },
    { kind: "refuse", reason: "person-chose", id: "SHA256:rig" },
  ],
  [
    "agent, remembered «here»",
    { machines: all, remembered: "here", byPerson: false },
    { kind: "use", id: "here", remember: false },
  ],
  [
    "agent, remembered machine offline",
    { machines: all, remembered: "SHA256:off", byPerson: false },
    { kind: "refuse", reason: "offline", id: "SHA256:off" },
  ],
  // Nothing chosen: the person is asked, the agent's pick only suggested.
  ["agent, first render with nodes", { machines: all, byPerson: false }, { kind: "ask" }],
  [
    "agent suggests Rig",
    { machines: all, asked: "Rig", byPerson: false },
    { kind: "ask", suggested: "SHA256:rig" },
  ],
  [
    "agent, unknown machine",
    { machines: all, asked: "Pluto", byPerson: false },
    { kind: "refuse", reason: "unknown" },
  ],
  [
    "agent, remembered node gone",
    { machines: all, remembered: "SHA256:gone", byPerson: false },
    { kind: "ask" },
  ],
  // This machine alone: nothing to ask.
  ["no nodes", { machines: [here], byPerson: false }, { kind: "use", id: "here", remember: false }],
  [
    "no nodes, page",
    { machines: [here], byPerson: true },
    { kind: "use", id: "here", remember: false },
  ],
];

describe("renderWhere (G41.7, R2)", () => {
  it.each(table)("%s", (_name, input, expected) => {
    expect(renderWhere(input)).toEqual(expected);
  });
});

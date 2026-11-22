// Nodes (G39.4): other RedGiant installations paired with this one. Pairing uses a one-time code
// the principal shows; the two machines exchange long-term ed25519 keys and pin each other's
// fingerprint, which the person compares on both sides (with a six-digit number both show) and
// confirms. Afterwards every link is a mutually authenticated, encrypted channel over a WebSocket
// (see `packages/server/src/nodes/channel.ts`). The machines form a tree; who may command whom is
// a separate grant the person gives, kept by the machine it is about. No secret ever crosses:
// a node's keys, its keychain and its providers' keys stay there.
import { z } from "zod";
import type { EmulatorReport } from "./emulators.js";
import type { FfmpegInfo, H264Encoder } from "./ffmpeg.js";

/** `use`: its capabilities (sandbox commands, models, storage); `admin`: also who may command it. */
export const NodeRight = z.enum(["use", "admin"]);
export type NodeRight = z.infer<typeof NodeRight>;

/** A grant, kept by the machine it is about. Machines are named by fingerprint. */
export interface NodeGrant {
  id: string;
  controller: string;
  controllerName: string;
  target: string;
  targetName: string;
  rights: NodeRight[];
  grantedAt: string;
  /** Where the person gave it: on this machine, or from a machine that manages it. */
  grantedFrom: string;
}

/** The one-time code shown by the principal: short, uppercase, ten minutes. */
export const PAIR_CODE = /^[A-HJ-NP-Z2-9]{4}-?[A-HJ-NP-Z2-9]{4}$/;
export const PAIR_CODE_TTL_MS = 10 * 60_000;
export const PAIR_CODE_TRIES = 5;

export interface PairCode {
  code: string;
  expiresAt: string;
}

/** What the person types on the node: the principal's address and its code. */
export const PairBody = z.object({
  address: z
    .string()
    .trim()
    .min(3)
    .max(500)
    .regex(/^(https?|wss?):\/\/[^\s]+$|^[^\s/:]+(:\d+)?$/),
  code: z.string().trim().toUpperCase().regex(PAIR_CODE),
  /** The name this machine shows to the other (default: its host name). */
  name: z.string().trim().min(1).max(40).optional(),
});
export type PairBody = z.infer<typeof PairBody>;

/** The person's yes on one side, with the rights the other side gets on this machine. */
export const PairConfirmBody = z.object({
  /** The fingerprint the person compared (a different one now is refused). */
  fingerprint: z.string().min(10).max(100),
  /** On the node: what the principal may do here (default: use and manage). */
  rights: z.array(NodeRight).max(2).optional(),
  /** The name the person gives the other machine here (default: the one it reports). */
  name: z.string().trim().max(40).optional(),
});

/** The person names a paired machine, here only (empty: the name it reports). */
export const NodeLabelBody = z.object({
  fingerprint: z.string().min(10).max(100),
  name: z.string().trim().max(40),
});

export const GrantBody = z.object({
  controller: z.string().min(10).max(100),
  target: z.string().min(10).max(100),
  rights: z.array(NodeRight).min(1).max(2),
});

export const NODE_NAME = /^[A-Za-z0-9][A-Za-z0-9_.-]{0,39}$/;

/** What a node offers, measured there (G39.3 discovery), never guessed. */
export interface NodeCapabilities {
  /**
   * `container`: commands run in a real container there; without one only a machine that manages
   * it runs commands, on the machine itself (p3.7.2).
   */
  sandbox: { ok: boolean; kind?: string; container?: boolean; cpus?: number; memoryMb?: number };
  /** Its model providers (their keys stay there): id and the models one can pick. */
  models: { provider: string; models: string[] }[];
  storage: { ok: boolean; freeBytes?: number; totalBytes?: number };
  /** How busy it is now. */
  load?: { cpu?: number; memoryUsedPct?: number };
  system?: string;
  /** Its graphics cards (G41.7), as `detectHardware` found them. */
  gpus?: NodeGpu[];
  /** What it offers to render video (G41.7); absent before 3.9 (no `media` operation there). */
  media?: NodeMedia;
  /** Its Android SDK, emulators, attached phones and iOS simulators (3.11); absent before 3.11. */
  emulators?: EmulatorReport;
}

export interface NodeGpu {
  vendor: "nvidia" | "amd" | "intel" | "apple" | "other";
  name: string;
  vramGb: number;
  integrated?: boolean;
}

/** A machine's ffmpeg for renders (G41.7): the one it has, or that it can download. */
export interface NodeMedia {
  /** The ffmpeg found there (none yet: `download` says whether it can get RedGiant's own). */
  ffmpeg?: FfmpegInfo;
  /** It can download the pinned build (G41.1) when it has none. */
  download: boolean;
  /** NVENC really encodes there (`nvencWorks`: a frame tried, not just listed by the build). */
  nvenc: boolean;
  /** The encoder a render uses there (`pickEncoder`); unknown until it has an ffmpeg. */
  encoder?: H264Encoder;
}

export type NodeStatus = "online" | "offline" | "pending" | "connecting" | "refused";

/** One machine of the tree as the page shows it. */
export interface NodeView {
  fingerprint: string;
  name: string;
  /** How it is linked to this machine: its parent, a child, or further in the tree. */
  relation: "self" | "parent" | "child" | "tree";
  status: NodeStatus;
  /** Why it is not online, in English for the log (the page has its own words for the codes). */
  reason?: string;
  lastSeen?: string;
  pairedAt?: string;
  /** The address the node dials (for the parent link). */
  address?: string;
  capabilities?: NodeCapabilities;
  /** Who may command it (its own list, as it reported it). */
  grants: NodeGrant[];
  children: NodeView[];
}

/** A pair waiting for the person's yes on this side. */
export interface PendingPair {
  fingerprint: string;
  name: string;
  /** Six digits both machines show for the same pair. */
  sas: string;
  /** This side is the principal (a node asked) or the node (it asked). */
  side: "principal" | "node";
  at: string;
}

/** Where the person pinned things for a project or an agent (default: here). */
export interface NodePlacement {
  /** `project:<id>` or `agent:<id>`. */
  scope: string;
  /** The node (fingerprint) commands run on. */
  commands?: string;
  /** The node backups are copied to. */
  backups?: string;
  /**
   * Where videos are rendered (G41.7, R2): `here` or a node. Asked at a project's first render,
   * then remembered; unset means not asked yet.
   */
  render?: string;
}

export const PlacementBody = z.object({
  scope: z.string().regex(/^(project|agent):[A-Za-z0-9_-]{1,80}$/),
  commands: z.string().min(10).max(100).nullable().optional(),
  backups: z.string().min(10).max(100).nullable().optional(),
  render: z
    .union([z.literal("here"), z.string().min(10).max(100)])
    .nullable()
    .optional(),
});

/** A machine a video can be rendered on (G41.7), as the panel and the `video` tool show it. */
export interface RenderMachine {
  /** `here` or the node's fingerprint. */
  id: string;
  name: string;
  /** It can render now. */
  ok: boolean;
  /** Why not (the page has its words for each). */
  reason?: "offline" | "no-right" | "no-media" | "no-ffmpeg";
  /** Its best graphics card's name (a dedicated one first). */
  gpu?: string;
  nvenc: boolean;
  /** ffmpeg's version there, or that it is downloaded at the first render. */
  ffmpeg?: string;
  download?: boolean;
}

/** One machine the person may render on: what `Nodes.known` says of it. */
export interface RenderMachineSource {
  fingerprint: string;
  name: string;
  online: boolean;
  rights?: readonly NodeRight[];
  capabilities?: NodeCapabilities;
}

const bestGpu = (gpus: readonly NodeGpu[] | undefined) =>
  [...(gpus ?? [])].sort(
    (a, b) => Number(a.integrated ?? false) - Number(b.integrated ?? false) || b.vramGb - a.vramGb,
  )[0]?.name;

/**
 * The machines a render can go to: this one first, then the nodes with what each offers. A node
 * renders when it is online, this machine may use it (rights unknown: it is tried, the node
 * decides), it is 3.9 or later (`media` reported) and it has or can download ffmpeg.
 */
export function renderMachines(
  here: { name: string; gpus?: readonly NodeGpu[]; media?: NodeMedia },
  nodes: readonly RenderMachineSource[],
): RenderMachine[] {
  const one = (
    id: string,
    name: string,
    gpus: readonly NodeGpu[] | undefined,
    media: NodeMedia | undefined,
    reason?: RenderMachine["reason"],
  ): RenderMachine => {
    const gpu = bestGpu(gpus);
    const why =
      reason ?? (!media ? "no-media" : !media.ffmpeg && !media.download ? "no-ffmpeg" : undefined);
    return {
      id,
      name,
      ok: why === undefined,
      ...(why && { reason: why }),
      ...(gpu && { gpu }),
      nvenc: media?.nvenc ?? false,
      ...(media?.ffmpeg && { ffmpeg: media.ffmpeg.version.replace(/^n/, "").split("-")[0] }),
      ...(media && !media.ffmpeg && media.download && { download: true }),
    };
  };
  const out = [one("here", here.name, here.gpus, here.media ?? { download: true, nvenc: false })];
  for (const n of nodes) {
    const caps = n.capabilities;
    const reason: RenderMachine["reason"] = !n.online
      ? "offline"
      : n.rights !== undefined && !n.rights.includes("use") && !n.rights.includes("admin")
        ? "no-right"
        : undefined;
    out.push(one(n.fingerprint, n.name, caps?.gpus, caps?.media, reason));
  }
  return out;
}

export interface NodesState {
  self: { fingerprint?: string; name: string; ready: boolean; reason?: string };
  tree: NodeView;
  /** The parent link, from this machine's point of view. */
  parent?: NodeView;
  pending: PendingPair[];
  /** Who may command this machine (its own list). */
  grants: NodeGrant[];
  placements: NodePlacement[];
  /** A code being shown (only on the page that asked for it). */
  code?: PairCode;
}

/** Short and readable: `SHA256:abcd…` keeps its first groups for the page. */
export function shortFingerprint(fp: string): string {
  const body = fp.replace(/^SHA256:/, "");
  return `SHA256:${body.slice(0, 16)}`;
}

/** What a render does about where it goes (G41.7, R2). */
export type RenderWhere =
  | { kind: "use"; id: string; remember: boolean }
  | { kind: "ask"; suggested?: string }
  | {
      kind: "refuse";
      reason: "unknown" | "person-chose" | NonNullable<RenderMachine["reason"]>;
      id?: string;
    };

/**
 * Where a render goes (pure, tested as a table). `asked` is `here`, a node's fingerprint or name;
 * `remembered` the project's choice (`NodePlacement.render`). The person (the page) chooses and
 * the choice is remembered; an agent follows the person's choice and never picks another machine
 * by itself: with no choice yet and more than this machine to choose from, the person is asked
 * (the agent's pick only suggested); with this machine alone it renders here without asking.
 */
export function renderWhere(o: {
  machines: readonly RenderMachine[];
  remembered?: string | undefined;
  asked?: string | undefined;
  byPerson: boolean;
}): RenderWhere {
  const find = (x: string) =>
    o.machines.find((m) => m.id === x) ??
    o.machines.find((m) => m.name.toLowerCase() === x.trim().toLowerCase()) ??
    (["here", "this machine", "local"].includes(x.trim().toLowerCase())
      ? o.machines.find((m) => m.id === "here")
      : undefined);
  const usable = (m: RenderMachine, remember: boolean): RenderWhere =>
    m.ok
      ? { kind: "use", id: m.id, remember }
      : { kind: "refuse", reason: m.reason ?? "offline", id: m.id };
  const asked = o.asked?.trim() ? find(o.asked) : undefined;
  if (o.asked?.trim() && !asked) return { kind: "refuse", reason: "unknown" };
  const remembered = o.remembered ? find(o.remembered) : undefined;
  if (o.byPerson && asked) return usable(asked, asked.id !== o.remembered);
  if (remembered) {
    if (asked && asked.id !== remembered.id)
      return { kind: "refuse", reason: "person-chose", id: remembered.id };
    return usable(remembered, false);
  }
  // Nothing chosen yet (or the machine chosen is gone).
  if (o.machines.length <= 1) return { kind: "use", id: "here", remember: false };
  return { kind: "ask", ...(asked && { suggested: asked.id }) };
}

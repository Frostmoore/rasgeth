// Devices and the app's protocol (G40.1, 3.8). A device (RGCompanion on a phone or a computer)
// signs in with a token of its own, bound to the owner: named, with its platform, when it was
// made and last used, revocable on its own. The token in clear exists only in the answer that
// makes it; the server keeps a hash. `GET /api/app/hello` tells an app what this RedGiant is
// before it signs in, and never anything personal.
import { z } from "zod";

/**
 * The app's protocol (an integer, raised when the app and the server stop understanding each
 * other). Separate from `PROTOCOL_VERSION`, the page's WebSocket protocol.
 */
export const APP_PROTOCOL_VERSION = 1;

export const DevicePlatform = z.enum(["android", "ios", "windows", "macos", "linux", "other"]);
export type DevicePlatform = z.infer<typeof DevicePlatform>;

/** A device's name, as the person reads it (Settings › Devices, «answered in the app (…)»). */
export const DeviceName = z
  .string()
  .trim()
  .min(1)
  .max(60)
  .refine((s) => !/[\u0000-\u001f\u007f]/.test(s), "no control characters");

/** A device as the page lists it: never its token nor the token's hash. */
export const DeviceView = z.object({
  id: z.string(),
  name: z.string(),
  platform: DevicePlatform,
  createdAt: z.string(),
  /** null: never used after it was made. */
  lastUsedAt: z.string().nullable(),
  /** The address it was last used from (local network, Tailscale, a proxy's client). */
  lastAddress: z.string().nullable(),
  /** The device asking (the list seen from the app itself). */
  current: z.boolean().optional(),
});
export type DeviceView = z.infer<typeof DeviceView>;

/** `POST /api/devices`: a token for a device, with a password session already valid. */
export const DeviceCreateBody = z.object({ name: DeviceName, platform: DevicePlatform });
export type DeviceCreateBody = z.infer<typeof DeviceCreateBody>;

/** `POST /api/app/pair`: the password (and the code, when on) and the device, in one step. */
export const DevicePairBody = DeviceCreateBody.extend({
  password: z.string().min(1).max(500),
  code: z.string().max(12).optional(),
});
export type DevicePairBody = z.infer<typeof DevicePairBody>;

/** The only answer that carries a device's token in clear. */
export const DeviceCreated = z.object({ token: z.string(), device: DeviceView });
export type DeviceCreated = z.infer<typeof DeviceCreated>;

export const DeviceRenameBody = z.object({ name: DeviceName });

/** `GET /api/app/hello`: what this RedGiant is, with or without a token. */
export const AppHello = z.object({
  app: z.literal("redgiant"),
  /** RedGiant's version (null when run from the sources). */
  version: z.string().nullable(),
  appProtocol: z.number().int(),
  /** The WebSocket protocol (`hello.protocolVersion`). */
  protocolVersion: z.number().int(),
  /** The machine's name (the one the nodes show), never the owner's. */
  machine: z.string(),
  firstStartCompleted: z.boolean(),
  /** How one may sign in here. */
  access: z.object({
    password: z.boolean(),
    /** The authenticator app's code is asked after the password. */
    code: z.boolean(),
    /** Device tokens are accepted (always, from G40.1). */
    token: z.boolean(),
    /** While there is no password (G39.7): what the first access offers. */
    firstAccess: z.enum(["password", "code", "not_here"]).optional(),
  }),
  /** The fingerprint of the nodes' identity (G39.4), once the machine has one. */
  nodeFingerprint: z.string().optional(),
  /** The token sent is valid (false: none, wrong or revoked). */
  signedIn: z.boolean(),
  /** The device the token belongs to. */
  device: z.object({ id: z.string(), name: z.string() }).optional(),
});
export type AppHello = z.infer<typeof AppHello>;

// --- The rules, pure and tested as tables ---------------------------------------------------

/** What a request was signed in with. */
export type Credential = "installation" | "session" | "device";

/**
 * Who may make a device token: a password session or the installation's own token (the command
 * line). Never a device: a stolen token could otherwise make itself a copy that outlives its
 * revocation.
 */
export function mayIssueDevice(by: Credential): boolean {
  return by === "installation" || by === "session";
}

/** The `via` of an answer given in the app (G36.17): «app (<device>)». */
export const appVia = (deviceName: string): string => `app (${deviceName})`;

/** The device's name in a `via` written by `appVia`, or undefined. */
export function appViaName(via: string | undefined): string | undefined {
  return via?.match(/^app \((.+)\)$/s)?.[1];
}

/**
 * Where a request or a question was answered, for the event and the other copies: a device
 * always says it is the app (whatever the message claims); otherwise the editor when the message
 * says so (G38.6), or the page.
 */
export function answerVia(o: {
  device?: string | undefined;
  claimed?: "editor" | undefined;
}): string {
  if (o.device) return appVia(o.device);
  return o.claimed ?? "web";
}

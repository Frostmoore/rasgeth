// The routes of Settings › Devices and of the app's protocol (G40.1, 3.8):
//   GET    /api/app/hello                    open: what this RedGiant is (with a token: whether it is valid)
//   POST   /api/app/pair    {password, code?, name, platform}   open: the password for a device's token
//   POST   /api/devices     {name, platform} a device's token, with a password session (or the
//                                           installation's token); never from a device
//   GET    /api/devices                      the owner's devices (never a token nor its hash)
//   PATCH  /api/devices/:id {name}
//   DELETE /api/devices/:id                  revoked at once: its open connections close
// The token in clear exists only in the answers of the two POSTs.
import {
  APP_PROTOCOL_VERSION,
  type AppHello,
  type Credential,
  DeviceCreateBody,
  DevicePairBody,
  DeviceRenameBody,
  mayIssueDevice,
  PROTOCOL_VERSION,
} from "@redgiant/protocol";
import type { Context, Hono } from "hono";
import { type AuthProvider, bearer, type Principal } from "./auth.js";
import type { RedGiantCore } from "./core.js";
import { DEVICE_TOKEN_PREFIX } from "./devices.js";
import type { FirstAccess } from "./first-access.js";
import { LoginError } from "./login.js";

export interface DeviceRouteOptions<E extends { Variables: { principal: Principal } }> {
  owner: (c: Context<E>) => string;
  clientAddress: (c: Context<E>) => string;
  /** Whose password signs in (one owner per installation). */
  loginOwner: string;
  auth: AuthProvider;
  /** RedGiant's version (null from the sources). */
  version: string | null;
  /** The first start is completed (true without a setup service). */
  completed: () => boolean;
  /** What the first access offers now (G39.7), or null once there is a password. */
  firstAccess: (c: Context<E>, hasPassword: boolean) => Promise<FirstAccess | null>;
}

/** What the request was signed in with (the device's own, a password session, the installation's). */
export function credentialOf(principal: Principal, token: string | undefined): Credential {
  if (principal.device || token?.startsWith(DEVICE_TOKEN_PREFIX)) return "device";
  return token?.startsWith("rgs_") ? "session" : "installation";
}

export function deviceRoutes<E extends { Variables: { principal: Principal } }>(
  app: Hono<E>,
  core: RedGiantCore,
  o: DeviceRouteOptions<E>,
): void {
  const body = async (c: Context<E>) => c.req.json().catch(() => ({}));

  app.get("/api/app/hello", async (c) => {
    const status = await core.logins.status(o.loginOwner);
    const first = await o.firstAccess(c, status.password);
    // A token is optional: a wrong or revoked one is not an error, only «not signed in».
    const who = await o.auth.authenticate(bearer(c.req.header("authorization"))).catch(() => null);
    const fingerprint = core.nodes.knownFingerprint(o.loginOwner);
    const hello: AppHello = {
      app: "redgiant",
      version: o.version,
      appProtocol: APP_PROTOCOL_VERSION,
      protocolVersion: PROTOCOL_VERSION,
      machine: await core.nodes.machineName(o.loginOwner).catch(() => "RedGiant"),
      firstStartCompleted: o.completed(),
      access: {
        password: status.password,
        code: status.code,
        token: true,
        ...(first && { firstAccess: first }),
      },
      ...(fingerprint && { nodeFingerprint: fingerprint }),
      signedIn: Boolean(who),
      ...(who?.device && { device: { id: who.device.id, name: who.device.name } }),
    };
    return c.json(hello, 200);
  });

  // The app signs in with the password once and keeps only the device's token (no session left
  // behind). Same limits as a sign-in: five wrong tries per address every 15 minutes.
  app.post("/api/app/pair", async (c) => {
    const b = DevicePairBody.safeParse(await body(c));
    if (!b.success)
      return c.json({ error: "A password, a name and a platform are needed", code: "bad" }, 400);
    try {
      await core.logins.check(o.loginOwner, b.data.password, b.data.code, o.clientAddress(c));
    } catch (err) {
      if (err instanceof LoginError)
        return c.json(
          { error: err.message, code: err.code },
          err.code === "too_many" ? 429 : err.code === "no_password" ? 409 : 401,
        );
      throw err;
    }
    return c.json(
      await core.devices.create(o.loginOwner, { name: b.data.name, platform: b.data.platform }),
      200,
    );
  });

  app.post("/api/devices", async (c) => {
    const by = credentialOf(c.get("principal"), bearer(c.req.header("authorization")));
    if (!mayIssueDevice(by))
      return c.json(
        { error: "A device cannot make another: sign in with the password", code: "device" },
        403,
      );
    const b = DeviceCreateBody.safeParse(await body(c));
    if (!b.success) return c.json({ error: "A name and a platform are needed" }, 400);
    return c.json(await core.devices.create(o.owner(c), b.data), 200);
  });

  app.get("/api/devices", async (c) => {
    const current = c.get("principal").device?.id;
    const list = await core.devices.list(o.owner(c));
    return c.json(
      list.map((d) => (d.id === current ? { ...d, current: true } : d)),
      200,
    );
  });

  app.patch("/api/devices/:id", async (c) => {
    const b = DeviceRenameBody.safeParse(await body(c));
    if (!b.success) return c.json({ error: "A name of 1 to 60 characters is needed" }, 400);
    const d = await core.devices.rename(o.owner(c), c.req.param("id"), b.data.name);
    return d ? c.json(d, 200) : c.json({ error: "No such device" }, 404);
  });

  app.delete("/api/devices/:id", async (c) => {
    if (!(await core.devices.revoke(o.owner(c), c.req.param("id"))))
      return c.json({ error: "No such device" }, 404);
    return c.json({ ok: true }, 200);
  });
}

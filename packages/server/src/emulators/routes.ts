// The routes of Settings › Emulators (3.11, phase 1; read-only apart from this machine's settings):
//   GET /api/emulators[?fresh=1]   this machine's report and the nodes' (as each last reported)
//   PUT /api/emulators/settings {sdkPath?, maxRunning?}   the SDK folder the person chose (null:
//                                  forget it) and how many emulators at once, on this machine
//   GET /api/emulators/devices     the devices one can open in the Canvas (3.11 phase 2)
//   POST /api/emulators/devices/stop {id}   the person switches an emulator off
//   POST /api/emulators/devices/repair {id}   the person's repair of an iOS simulator's touches
//   POST /api/emulators/install/plan {target?, avdName?, only?}   the guided install's plan for
//                                  this machine (3.11 phase 5): steps, sizes, licence texts, planId
//   POST /api/emulators/install/start {planId, licenceAccepted}   the person's yes: the plan runs
//                                  as a job (followed and cancelled through /api/jobs)
//   POST /api/emulators/ios-bridge/plan   the iOS bridge's guided install (3.12.2): what, where, why not
//   POST /api/emulators/ios-bridge/start {planId}   the person's yes: serve-sim is downloaded as a job
import {
  EmuInstallPlanBody,
  EmuInstallStartBody,
  EmulatorSettingsBody,
  type EmulatorsState,
  IosBridgeStartBody,
} from "@redgiant/protocol";
import type { Context, Hono } from "hono";
import type { RedGiantCore } from "../core.js";
import { DeviceError } from "./devices.js";
import { InstallError } from "./install.js";
import { EmulatorSettingsError } from "./machine.js";

export async function emulatorsState(
  core: RedGiantCore,
  ownerId: string,
  fresh = false,
): Promise<EmulatorsState> {
  const [report, known, name] = await Promise.all([
    core.emulators.report(fresh),
    core.nodes.known(ownerId).catch(() => []),
    core.nodes.machineName(ownerId).catch(() => ""),
  ]);
  return {
    here: { id: "here", name, online: true, report },
    settings: core.emulators.settings(),
    nodes: known.map((n) => ({
      id: n.fingerprint,
      name: n.name,
      online: n.online,
      ...(n.view?.capabilities?.emulators && { report: n.view.capabilities.emulators }),
    })),
  };
}

// biome-ignore lint/suspicious/noExplicitAny: the app's variables vary between servers
export function emulatorRoutes<E extends { Variables: any }>(
  app: Hono<E>,
  core: RedGiantCore,
  owner: (c: Context<E>) => string,
): void {
  app.get("/api/emulators", async (c) =>
    c.json(await emulatorsState(core, owner(c), c.req.query("fresh") === "1")),
  );
  app.get("/api/emulators/devices", async (c) =>
    c.json({ devices: await core.deviceHub.of(owner(c)).list() }),
  );
  app.post("/api/emulators/devices/stop", async (c) => {
    const b = (await c.req.json().catch(() => ({}))) as { id?: unknown };
    if (typeof b.id !== "string" || !b.id) return c.json({ error: "Which device?" }, 400);
    try {
      await core.deviceHub.of(owner(c)).stop(b.id);
    } catch (err) {
      if (err instanceof DeviceError) return c.json({ error: err.message }, 400);
      throw err;
    }
    return c.json({ devices: await core.deviceHub.of(owner(c)).list() });
  });
  // 3.12.2: the person's repair of an iOS simulator's touches (restarts its home screen).
  app.post("/api/emulators/devices/repair", async (c) => {
    const b = (await c.req.json().catch(() => ({}))) as { id?: unknown };
    if (typeof b.id !== "string" || !b.id) return c.json({ error: "Which device?" }, 400);
    try {
      await core.deviceHub.of(owner(c)).repair(b.id);
    } catch (err) {
      if (err instanceof Error) return c.json({ error: err.message }, 400);
      throw err;
    }
    return c.json({ ok: true });
  });
  app.put("/api/emulators/settings", async (c) => {
    const parsed = EmulatorSettingsBody.safeParse(await c.req.json().catch(() => null));
    if (!parsed.success) return c.json({ error: "Invalid settings" }, 400);
    try {
      await core.emulators.update(parsed.data);
    } catch (err) {
      if (err instanceof EmulatorSettingsError) return c.json({ error: err.message }, 400);
      throw err;
    }
    return c.json(await emulatorsState(core, owner(c), true));
  });
  // Phase 5: only the person, from Settings; agents have no tool for this.
  app.post("/api/emulators/install/plan", async (c) => {
    const parsed = EmuInstallPlanBody.safeParse(await c.req.json().catch(() => ({})));
    if (!parsed.success) return c.json({ error: "Invalid folder or name" }, 400);
    return c.json(await core.emuInstall.plan(owner(c), parsed.data));
  });
  app.post("/api/emulators/install/start", async (c) => {
    const parsed = EmuInstallStartBody.safeParse(await c.req.json().catch(() => null));
    if (!parsed.success) return c.json({ error: "Which plan?" }, 400);
    try {
      return c.json({ jobId: core.emuInstall.start(owner(c), parsed.data).id });
    } catch (err) {
      if (err instanceof InstallError)
        return c.json({ error: err.message, code: err.code }, err.code === "busy" ? 409 : 400);
      throw err;
    }
  });
  // 3.12.2: the iOS bridge, the same way: a plan the person sees, then their yes.
  app.post("/api/emulators/ios-bridge/plan", async (c) =>
    c.json(await core.iosInstall.plan(owner(c))),
  );
  app.post("/api/emulators/ios-bridge/start", async (c) => {
    const parsed = IosBridgeStartBody.safeParse(await c.req.json().catch(() => null));
    if (!parsed.success) return c.json({ error: "Which plan?" }, 400);
    try {
      return c.json({ jobId: core.iosInstall.start(owner(c), parsed.data).id });
    } catch (err) {
      if (err instanceof InstallError)
        return c.json({ error: err.message, code: err.code }, err.code === "busy" ? 409 : 400);
      throw err;
    }
  });
}

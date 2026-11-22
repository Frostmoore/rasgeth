// The routes of Settings › Emulators (3.11, phase 1; read-only apart from this machine's settings):
//   GET /api/emulators[?fresh=1]   this machine's report and the nodes' (as each last reported)
//   PUT /api/emulators/settings {sdkPath?, maxRunning?}   the SDK folder the person chose (null:
//                                  forget it) and how many emulators at once, on this machine
import { EmulatorSettingsBody, type EmulatorsState } from "@redgiant/protocol";
import type { Context, Hono } from "hono";
import type { RedGiantCore } from "../core.js";
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
}

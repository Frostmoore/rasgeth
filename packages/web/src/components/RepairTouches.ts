// «Repair touches» (3.12.2): the person's own action for an iOS simulator whose taps and keys no
// longer arrive. It restarts the simulator's home screen and closes its open apps, so it is asked
// through our Modal first and never runs by itself.
import { t } from "../i18n.js";
import { attempt, getApi } from "../state.js";
import { askConfirm } from "./dialogs.js";

/** Asks, then repairs; false when the person said no or it failed (the failure is shown). */
export async function repairTouches(id: string, name: string): Promise<boolean> {
  const yes = await askConfirm(t("dvRepairQ", { name }), {
    text: t("dvRepairText"),
    yes: t("dvRepairYes"),
    danger: true,
  });
  if (!yes) return false;
  return (await attempt(() => getApi().repairDeviceTouches(id))) !== undefined;
}

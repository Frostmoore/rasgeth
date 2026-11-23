// God's friendly nudges (3.12.1): the switch and how often, the same in Settings › General and in
// the simple interface's settings.
import type { NudgeEvery } from "@redgiant/protocol";
import { useEffect } from "preact/hooks";
import { t } from "../i18n.js";
import { loadNudgeSettings, nudgeSettings, saveNudgeSettings } from "../state.js";
import { Seg, Switch } from "./SettingsKit.js";

export function NudgeControls() {
  useEffect(() => {
    void loadNudgeSettings().catch(() => {});
  }, []);
  const s = nudgeSettings.value;
  if (!s) return null;
  return (
    <div class="nudge-controls">
      <Switch
        on={s.on}
        label={t("nudgeTitle")}
        onChange={(on) => void saveNudgeSettings({ ...s, on })}
      />
      {s.on && (
        <Seg<NudgeEvery>
          label={t("nudgeEvery")}
          value={s.every}
          onChange={(every) => void saveNudgeSettings({ ...s, every })}
          options={[
            ["day", t("nudgeDay")],
            ["two_days", t("nudgeTwoDays")],
            ["week", t("nudgeWeek")],
          ]}
        />
      )}
    </div>
  );
}

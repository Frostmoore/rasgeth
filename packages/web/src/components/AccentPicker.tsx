import { ACCENT_SWATCH, ACCENTS, type Accent, accent, setAccent } from "../accent.js";
import { type Key, t } from "../i18n.js";
import { IconCheck } from "../icons.js";

const NAMES: Record<Accent, Key> = {
  red: "accentRed",
  amber: "accentAmber",
  green: "accentGreen",
  blue: "accentBlue",
  violet: "accentViolet",
};

/** The accent colour (3.10.4): five drawn swatches, the chosen one ringed and ticked. */
export function AccentPicker() {
  return (
    <fieldset class="accent-pick" aria-label={t("accentTitle")}>
      {ACCENTS.map((a) => {
        const on = accent.value === a;
        return (
          <button
            type="button"
            key={a}
            class={`accent-sw${on ? " on" : ""}`}
            data-accent-choice={a}
            aria-pressed={on}
            title={t(NAMES[a])}
            onClick={() => setAccent(a)}
          >
            <span class="accent-dot" style={{ background: ACCENT_SWATCH[a] }}>
              {on && <IconCheck size={14} />}
            </span>
            <span class="accent-name">{t(NAMES[a])}</span>
          </button>
        );
      })}
    </fieldset>
  );
}

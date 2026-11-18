// The new name, said once (plan 3.9.0, choice 17): «RedGiant is now called Rasgeth», on top of the
// page for whoever knew the old name, until they close it (`rg.renameSeen`, this browser). Whoever
// installs the product from 3.9.0 on never knew the old name and sees nothing.
import { useEffect, useState } from "preact/hooks";
import { t } from "../i18n.js";
import { IconClose, IconSpark } from "../icons.js";
import { getApi } from "../state.js";
import { compareVersions } from "./WhatsNew.js";

/** The release that brought the new name. */
export const RENAMED_IN = "3.9.0";
export const RENAME_SEEN = "rg.renameSeen";

/**
 * Whether to say it: not once it was closed; yes when this browser saw an older version's news
 * (`rg.newsSeen`) or the installation was born before the new name (the server's `firstVersion`,
 * which a clean install keeps with the data).
 */
export function renameNoticeDue(o: {
  seen: boolean;
  newsSeen: string | null;
  firstVersion: string | null | undefined;
}): boolean {
  if (o.seen) return false;
  const before = (v: string | null | undefined) =>
    !!v && /^\d+\.\d+\.\d+$/.test(v) && compareVersions(v, RENAMED_IN) < 0;
  return before(o.newsSeen) || before(o.firstVersion);
}

const stored = (key: string): string | null => {
  try {
    return localStorage.getItem(key);
  } catch {
    return null;
  }
};

export function RenameNotice() {
  const [due, setDue] = useState(false);
  useEffect(() => {
    if (stored(RENAME_SEEN)) return;
    const newsSeen = stored("rg.newsSeen");
    if (renameNoticeDue({ seen: false, newsSeen, firstVersion: null })) {
      setDue(true);
      return;
    }
    void getApi()
      .updateStatus()
      .then(
        (s) => setDue(renameNoticeDue({ seen: false, newsSeen, firstVersion: s.firstVersion })),
        () => {},
      );
  }, []);
  if (!due) return null;
  const close = () => {
    try {
      localStorage.setItem(RENAME_SEEN, RENAMED_IN);
    } catch {
      // private browsing: it closes for now
    }
    setDue(false);
  };
  return (
    <div class="banner rename-notice" role="status">
      <span class="rename-notice-icon">
        <IconSpark />
      </span>
      <span>
        <span class="rename-notice-title">{t("renameTitle")}</span> {t("renameText")}
      </span>
      <button type="button" class="link" onClick={close}>
        {t("renameOk")}
      </button>
      <button
        type="button"
        class="icon-button"
        title={t("close")}
        aria-label={t("close")}
        onClick={close}
      >
        <IconClose />
      </button>
    </div>
  );
}

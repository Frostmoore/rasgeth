// «Updated to 3.8.x» (3.8.1, the person: «mostrando "Aggiornato alla 3.8.x" alla fine con un link
// alle novità»). A page that followed an update (or saw RedGiant come back as another version)
// remembers it for the next load and reloads; the new page says it once, with what is new in it
// (the release's items, or its notes on GitHub when it brought none).
import { useState } from "preact/hooks";
import { t } from "../i18n.js";
import { IconCheck, IconExternal } from "../icons.js";
import { Modal } from "./ui.js";
import { NewsWindow, newsSince } from "./WhatsNew.js";

const KEY = "rg.updatedTo";
const RELEASES = "https://github.com/Frostmoore/redgiant2/releases/tag/v";

export interface Updated {
  to: string;
  from: string | null;
}

/** Remembered for the page that loads next (this tab only). */
export function rememberUpdated(to: string, from: string | null): void {
  try {
    sessionStorage.setItem(KEY, JSON.stringify({ to, from }));
  } catch {
    // no storage: the page still reloads, without the words
  }
}

/** What the page that loaded after an update has to say; null otherwise. */
export function pendingUpdated(): Updated | null {
  try {
    const v = JSON.parse(sessionStorage.getItem(KEY) ?? "null") as Partial<Updated> | null;
    return v && typeof v.to === "string" && /^\d+\.\d+\.\d+$/.test(v.to)
      ? { to: v.to, from: typeof v.from === "string" ? v.from : null }
      : null;
  } catch {
    return null;
  }
}

/** How the page reloads (tests put their own). */
export const reloader = { reload: () => location.reload() };

/** Reloads the page as the new version, telling it what happened. */
export function reloadAsUpdated(to: string, from: string | null, afterMs = 1500): void {
  rememberUpdated(to, from);
  setTimeout(() => reloader.reload(), afterMs);
}

/** The window the reloaded page shows once: the version, and what is new in it. */
export function UpdatedNotice() {
  const [u, setU] = useState(pendingUpdated);
  const [news, setNews] = useState(false);
  if (!u) return null;
  const close = () => {
    try {
      sessionStorage.removeItem(KEY);
    } catch {
      // nothing kept
    }
    setU(null);
  };
  const groups = u.from ? newsSince(u.from) : [];
  if (news && groups.length > 0)
    return (
      <NewsWindow
        groups={groups}
        onClose={() => {
          localStorage.setItem("rg.newsSeen", u.to);
          close();
        }}
      />
    );
  return (
    <Modal
      title={t("updDoneTitle", { version: u.to })}
      icon={<IconCheck size={20} />}
      {...(u.from && { sub: t("updDoneSub", { version: u.to, from: u.from }) })}
      onClose={close}
      class="upd-modal wz-look upd-done"
      foot={
        <>
          {groups.length > 0 ? (
            <button type="button" class="wz-btn" onClick={() => setNews(true)}>
              {t("updDoneNews")}
            </button>
          ) : (
            <a class="wz-btn" href={`${RELEASES}${u.to}`} target="_blank" rel="noreferrer">
              {t("updDoneNotes")} <IconExternal size={14} />
            </a>
          )}
          <button type="button" class="wz-btn primary" onClick={close}>
            {t("updDoneOk")}
          </button>
        </>
      }
    >
      <div class="upd-body">
        <p class="upd-lead">{t("updDoneText")}</p>
      </div>
    </Modal>
  );
}

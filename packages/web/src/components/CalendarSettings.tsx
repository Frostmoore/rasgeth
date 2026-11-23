// Calendars (3.12.3): CalDAV accounts (iCloud, Nextcloud, Fastmail…) the agents may read and, with
// the person's yes each time, add events to; and read-only iCal addresses (Google's secret address).
// The secret goes to the keychain and never comes back. Squares like the mailboxes', one window to
// add or change.
import type { CalendarInfo } from "@redgiant/protocol";
import { createPortal } from "preact/compat";
import { useEffect, useState } from "preact/hooks";
import { t } from "../i18n.js";
import { IconCalendar, IconPlus } from "../icons.js";
import { attempt, getApi } from "../state.js";
import { explain } from "./Brain.js";
import { Acts, Chips, SwitchRow, Tile } from "./SettingsKit.js";
import { Field, Modal } from "./ui.js";

export function useCalendars(): { calendars: CalendarInfo[]; reload: () => void } {
  const [calendars, setCalendars] = useState<CalendarInfo[]>([]);
  const reload = () =>
    void getApi()
      .calendars()
      .then(
        (r) => setCalendars(r?.calendars ?? []),
        () => setCalendars([]),
      );
  useEffect(reload, []);
  return { calendars, reload };
}

const v = (e: Event) => (e.target as HTMLInputElement).value;

function CalendarEditor({ cal, onClose }: { cal: CalendarInfo | undefined; onClose: () => void }) {
  const [name, setName] = useState(cal?.name ?? "");
  const [kind, setKind] = useState<"caldav" | "ics">(cal?.kind ?? "caldav");
  const [url, setUrl] = useState("");
  const [user, setUser] = useState("");
  const [password, setPassword] = useState("");
  const [agents, setAgents] = useState(cal?.agents === true);
  const [busy, setBusy] = useState(false);
  const [error, setError] = useState<string>();
  const save = async () => {
    setBusy(true);
    setError(undefined);
    try {
      if (cal) await getApi().updateCalendar(cal.id, { name: name.trim(), agents });
      else
        await getApi().addCalendar({
          name: name.trim(),
          kind,
          url: url.trim(),
          ...(kind === "caldav" && { user: user.trim(), password }),
          agents,
        });
      onClose();
    } catch (err) {
      setError(explain(err));
    } finally {
      setBusy(false);
    }
  };
  const ready = cal
    ? true
    : url.trim().length > 8 && (kind === "ics" || (user.trim().length > 0 && password.length > 0));
  return createPortal(
    <div class="wz-look">
      <Modal title={cal ? cal.name : t("calNew")} onClose={onClose}>
        <div class="wz-panel-in cal-editor">
          <p class="wz-lead2">{t("calPurpose")}</p>
          {!cal && (
            <>
              <span class="wz-lb">{t("calKind")}</span>
              <Chips<"caldav" | "ics">
                options={[
                  { id: "caldav", label: t("calKind_caldav") },
                  { id: "ics", label: t("calKind_ics") },
                ]}
                value={[kind]}
                onChange={([k]) => k && setKind(k)}
              />
            </>
          )}
          <Field label={t("calName")} help={t("calNameHelp")}>
            <input value={name} onInput={(e) => setName(v(e))} />
          </Field>
          {!cal && kind === "caldav" && (
            <>
              <Field label={t("calUrlCaldav")} help={t("calUrlCaldavHelp")}>
                <input
                  value={url}
                  placeholder="https://caldav.example.com/calendars/me/home/"
                  onInput={(e) => setUrl(v(e))}
                />
              </Field>
              <Field label={t("calUser")}>
                <input value={user} autocomplete="off" onInput={(e) => setUser(v(e))} />
              </Field>
              <Field label={t("calPassword")} help={t("calPasswordHelp")}>
                <input
                  type="password"
                  autocomplete="off"
                  value={password}
                  onInput={(e) => setPassword(v(e))}
                />
              </Field>
            </>
          )}
          {!cal && kind === "ics" && (
            <>
              <Field label={t("calUrlIcs")} help={t("calUrlIcsHelp")}>
                <input
                  value={url}
                  placeholder="https://calendar.google.com/calendar/ical/…/basic.ics"
                  onInput={(e) => setUrl(v(e))}
                />
              </Field>
              <p class="ui-help">{t("calGoogleNote")}</p>
            </>
          )}
          {cal && <p class="ui-help">{t(`calState_${cal.kind}`)}</p>}
          <SwitchRow
            title={t("calAgents")}
            help={t("calAgentsHelp")}
            on={agents}
            onChange={setAgents}
          />
          {error && <p class="notice error">{error}</p>}
          <Acts>
            {cal && (
              <button
                type="button"
                class="wz-btn quiet"
                onClick={() =>
                  void attempt(() => getApi().removeCalendar(cal.id)).then(() => onClose())
                }
              >
                {t("calRemove")}
              </button>
            )}
            <button
              type="button"
              class="wz-btn primary"
              disabled={busy || !ready}
              onClick={() => void save()}
            >
              {busy ? t("calTesting") : cal ? t("save") : t("calSave")}
            </button>
          </Acts>
        </div>
      </Modal>
    </div>,
    document.body,
  );
}

/** The calendars on the Automations page: one square each, and «Add a calendar». */
export function Calendars() {
  const { calendars, reload } = useCalendars();
  const [open, setOpen] = useState<"new" | CalendarInfo | null>(null);
  const closed = () => {
    setOpen(null);
    reload();
  };
  return (
    <>
      <div class="wz-brain aw-make aw-sources">
        {calendars.map((c) => (
          <Tile
            key={c.id}
            on
            icon={<IconCalendar />}
            title={c.name}
            text={c.url}
            state={t(`calState_${c.kind}`)}
            onClick={() => setOpen(c)}
          />
        ))}
        <Tile
          on={false}
          icon={<IconPlus />}
          title={t("calAdd")}
          text={t("calAddText")}
          onClick={() => setOpen("new")}
        />
      </div>
      {open === "new" && <CalendarEditor cal={undefined} onClose={closed} />}
      {open && typeof open === "object" && <CalendarEditor cal={open} onClose={closed} />}
    </>
  );
}

// Messages (3.12.4): the secretary that answers OTHER people on a WhatsApp Business number or a
// Telegram bot. Here the person connects them with a step-by-step guide (each step checked against
// the platform), reads every contact's conversation, answers the requests the agent passed on (one
// tap to send the ready reply, edit it or refuse), takes a conversation over or pauses the agent for
// one contact. Keys go to the keychain and never come back.
import type {
  SecretaryAccountView,
  SecretaryCheck,
  SecretaryContactView,
  SecretaryMessageView,
  SecretaryPendingView,
} from "@redgiant/protocol";
import { createPortal } from "preact/compat";
import { useEffect, useState } from "preact/hooks";
import { type Key, t } from "../i18n.js";
import { IconChat, IconPlus, IconSend, IconTelegram } from "../icons.js";
import { agents, getApi, openTab } from "../state.js";
import { explain } from "./Brain.js";
import { askConfirm } from "./dialogs.js";
import { Acts, Head, Sub, SwitchRow, Tile, WzPage } from "./SettingsKit.js";
import { Field, Modal } from "./ui.js";

const v = (e: Event) => (e.target as HTMLInputElement).value;

/** The words for a check's code, in the person's language. */
const say = (code: string) => {
  const known = [
    "no_remote",
    "not_https",
    "bad_token",
    "bad_number",
    "bad_secret",
    "no_access",
    "unreachable",
    "webhook_failed",
    "failed",
  ];
  return t(`scErr_${known.includes(code) ? code : "failed"}` as Key);
};

function useSecretary() {
  const [accounts, setAccounts] = useState<SecretaryAccountView[]>([]);
  const [contacts, setContacts] = useState<SecretaryContactView[]>([]);
  const [pending, setPending] = useState<SecretaryPendingView[]>([]);
  const reload = () =>
    void Promise.all([getApi().secretaryAccounts(), getApi().secretaryContacts()]).then(
      ([a, c]) => {
        setAccounts(a.accounts);
        setContacts(c.contacts);
        setPending(c.pending);
      },
      () => {},
    );
  useEffect(() => {
    reload();
    const timer = setInterval(reload, 8000);
    return () => clearInterval(timer);
  }, []);
  return { accounts, contacts, pending, reload };
}

/** Who answers: any agent the person has (the «Message secretary» set is the usual one). */
function AgentPick({ value, onChange }: { value: string; onChange: (id: string) => void }) {
  const list = agents.value.filter((a) => a.kind !== "god" && a.kind !== "assistant");
  return (
    <Field label={t("scAgent")} help={t("scAgentHelp")}>
      {list.length === 0 ? (
        <p class="ui-help">{t("scAgentNone")}</p>
      ) : (
        <Chips<string>
          wrap
          options={list.map((a) => ({ id: a.id, label: a.name }))}
          value={value ? [value] : []}
          onChange={([id]) => onChange(id ?? "")}
        />
      )}
    </Field>
  );
}

function Copy({ text, label }: { text: string; label: string }) {
  const [done, setDone] = useState(false);
  return (
    <div class="sc-copy">
      <code>{text}</code>
      <button
        type="button"
        class="wz-btn quiet"
        aria-label={label}
        onClick={() =>
          void navigator.clipboard?.writeText(text).then(
            () => setDone(true),
            () => {},
          )
        }
      >
        {done ? t("scCopied") : t("scCopy")}
      </button>
    </div>
  );
}

type Result = { ok: boolean; text: string } | undefined;

function ResultLine({ r }: { r: Result }) {
  if (!r) return null;
  return (
    <p class={`notice ${r.ok ? "ok" : "error"}`} role="status">
      {r.text}
    </p>
  );
}

function Step({
  n,
  title,
  current,
  done,
  children,
}: {
  n: number;
  title: string;
  current: boolean;
  done: boolean;
  children?: preact.ComponentChildren;
}) {
  return (
    <li class={`sc-step${current ? " cur" : ""}${done ? " done" : ""}`}>
      <span class="sc-step-n" aria-hidden="true">
        {n}
      </span>
      <div class="sc-step-body">
        <b>{title}</b>
        {current && <div class="sc-step-in">{children}</div>}
      </div>
    </li>
  );
}

const external = (href: string, label: string) => (
  <a href={href} target="_blank" rel="noopener noreferrer">
    {label}
  </a>
);

/** The «remote access» step both guides begin with. */
function RemoteStep({ onOk }: { onOk: () => void }) {
  const [r, setR] = useState<Result>();
  const run = () =>
    void getApi()
      .secretaryCheck({ channel: "whatsapp", step: "remote" })
      .then((c) => {
        setR({ ok: c.ok, text: c.ok ? t("scRemoteOk", { url: c.detail ?? "" }) : say(c.code) });
        if (c.ok) onOk();
      });
  useEffect(run, []);
  return (
    <>
      <p>{t("scRemoteText")}</p>
      <ResultLine r={r} />
      {r && !r.ok && (
        <Acts>
          <button
            type="button"
            class="wz-btn"
            onClick={() =>
              openTab({ id: "settings", type: "settings", title: t("settings"), section: "remote" })
            }
          >
            {t("scOpenRemote")}
          </button>
          <button type="button" class="wz-btn primary" onClick={run}>
            {t("scCheckAgain")}
          </button>
        </Acts>
      )}
    </>
  );
}

const WA_STEPS = ["remote", "app", "number", "token", "secret", "webhook", "subscribe", "finish"];

function WhatsAppGuide({ onClose }: { onClose: () => void }) {
  const [step, setStep] = useState(0);
  const [phone, setPhone] = useState("");
  const [token, setToken] = useState("");
  const [secret, setSecret] = useState("");
  const [tpl, setTpl] = useState("");
  const [lang, setLang] = useState("it");
  const [agentId, setAgentId] = useState("");
  const [account, setAccount] = useState<SecretaryAccountView>();
  const [r, setR] = useState<Result>();
  const [busy, setBusy] = useState(false);
  const go = (n: number) => {
    setR(undefined);
    setStep(n);
  };
  // The webhook step makes the account, so Meta can check it while the form is filled in.
  useEffect(() => {
    if (WA_STEPS[step] !== "webhook" || account) return;
    void getApi()
      .secretaryStartWhatsApp({ name: "" })
      .then(setAccount, (e) => setR({ ok: false, text: explain(e) }));
  }, [step]);
  // Meta's check arrives on its own: the page watches for it.
  useEffect(() => {
    if (!account || account.webhookOk) return;
    const timer = setInterval(
      () =>
        void getApi()
          .secretaryAccounts()
          .then((l) => {
            const a = l.accounts.find((x) => x.id === account.id);
            if (a) setAccount(a);
          }),
      3000,
    );
    return () => clearInterval(timer);
  }, [account?.id, account?.webhookOk]);
  const test = async (next: number) => {
    setBusy(true);
    try {
      const c: SecretaryCheck = await getApi().secretaryCheck({
        channel: "whatsapp",
        step: "token",
        token: token.trim(),
        phoneNumberId: phone.trim(),
      });
      if (c.ok) {
        setR({
          ok: true,
          text: t("scTokenOk", { number: c.number ?? "", name: c.verifiedName ?? "" }),
        });
        setStep(next);
      } else setR({ ok: false, text: say(c.code) });
    } finally {
      setBusy(false);
    }
  };
  const finish = async () => {
    if (!account) return;
    setBusy(true);
    try {
      await getApi().secretaryFinishWhatsApp(account.id, {
        name: "",
        phoneNumberId: phone.trim(),
        token: token.trim(),
        appSecret: secret.trim(),
        ...(agentId && { agentId }),
        ...(tpl.trim() && { template: { name: tpl.trim(), language: lang.trim() || "it" } }),
      });
      onClose();
    } catch (e) {
      setR({ ok: false, text: say((e as { code?: string }).code ?? "failed") || explain(e) });
    } finally {
      setBusy(false);
    }
  };
  const next = (n: number, label = t("scNext"), disabled = false) => (
    <Acts>
      <button type="button" class="wz-btn primary" disabled={disabled} onClick={() => go(n)}>
        {label}
      </button>
    </Acts>
  );
  return createPortal(
    <div class="wz-look">
      <Modal title={t("scWaTitle")} onClose={onClose} wide>
        <div class="wz-panel-in">
          <p class="wz-lead2">{t("scWaLead")}</p>
          <ol class="sc-steps">
            <Step n={1} title={t("scWa_remote")} current={step === 0} done={step > 0}>
              <RemoteStep onOk={() => step === 0 && setTimeout(() => go(1), 600)} />
            </Step>
            <Step n={2} title={t("scWa_app")} current={step === 1} done={step > 1}>
              <p>{t("scWaAppText")}</p>
              <p>{external("https://developers.facebook.com/apps/", t("scWaAppLink"))}</p>
              {next(2)}
            </Step>
            <Step n={3} title={t("scWa_number")} current={step === 2} done={step > 2}>
              <p>{t("scWaNumberText")}</p>
              <Field label={t("scWaNumberLabel")}>
                <input value={phone} inputMode="numeric" onInput={(e) => setPhone(v(e))} />
              </Field>
              {next(3, t("scNext"), !/^\d{5,25}$/.test(phone.trim()))}
            </Step>
            <Step n={4} title={t("scWa_token")} current={step === 3} done={step > 3}>
              <p>{t("scWaTokenText")}</p>
              <Field label={t("scWaTokenLabel")} help={t("scKeyHelp")}>
                <input
                  type="password"
                  autocomplete="off"
                  value={token}
                  onInput={(e) => setToken(v(e))}
                />
              </Field>
              <ResultLine r={r} />
              <Acts>
                <button
                  type="button"
                  class="wz-btn primary"
                  disabled={busy || token.trim().length < 20}
                  onClick={() => void test(4)}
                >
                  {busy ? t("scTesting") : t("scTest")}
                </button>
              </Acts>
            </Step>
            <Step n={5} title={t("scWa_secret")} current={step === 4} done={step > 4}>
              <p>{t("scWaSecretText")}</p>
              <Field label={t("scWaSecretLabel")} help={t("scKeyHelp")}>
                <input
                  type="password"
                  autocomplete="off"
                  value={secret}
                  onInput={(e) => setSecret(v(e))}
                />
              </Field>
              {secret && !/^[0-9a-f]{32}$/i.test(secret.trim()) && (
                <p class="notice error">{say("bad_secret")}</p>
              )}
              {next(5, t("scNext"), !/^[0-9a-f]{32}$/i.test(secret.trim()))}
            </Step>
            <Step n={6} title={t("scWa_webhook")} current={step === 5} done={step > 5}>
              <p>{t("scWaWebhookText")}</p>
              {account?.webhookUrl && (
                <>
                  <span class="wz-lb">{t("scCallback")}</span>
                  <Copy text={account.webhookUrl} label={t("scCallback")} />
                  <span class="wz-lb">{t("scVerify")}</span>
                  <Copy text={account.verifyToken ?? ""} label={t("scVerify")} />
                </>
              )}
              <p class={`notice ${account?.webhookOk ? "ok" : "warn"}`} role="status">
                {account?.webhookOk ? t("scWebhookOk") : t("scWebhookWait")}
              </p>
              <ResultLine r={r} />
              {next(6, t("scNext"), !account?.webhookOk)}
            </Step>
            <Step n={7} title={t("scWa_subscribe")} current={step === 6} done={step > 6}>
              <p>{t("scWaSubscribeText")}</p>
              {next(7, t("scDone"))}
            </Step>
            <Step n={8} title={t("scWa_finish")} current={step === 7} done={false}>
              <AgentPick value={agentId} onChange={setAgentId} />
              <p>{t("scWaTemplateText")}</p>
              <Field label={t("scTemplateName")}>
                <input value={tpl} onInput={(e) => setTpl(v(e))} />
              </Field>
              <Field label={t("scTemplateLang")}>
                <input value={lang} onInput={(e) => setLang(v(e))} />
              </Field>
              <ResultLine r={r} />
              <Acts>
                <button
                  type="button"
                  class="wz-btn primary"
                  disabled={busy || !agentId}
                  onClick={() => void finish()}
                >
                  {busy ? t("scTesting") : t("scConnect")}
                </button>
              </Acts>
            </Step>
          </ol>
        </div>
      </Modal>
    </div>,
    document.body,
  );
}

function TelegramGuide({ onClose }: { onClose: () => void }) {
  const [step, setStep] = useState(0);
  const [token, setToken] = useState("");
  const [agentId, setAgentId] = useState("");
  const [r, setR] = useState<Result>();
  const [busy, setBusy] = useState(false);
  const test = async () => {
    setBusy(true);
    try {
      const c = await getApi().secretaryCheck({
        channel: "telegram",
        step: "token",
        token: token.trim(),
      });
      setR(
        c.ok
          ? { ok: true, text: t("scBotOk", { name: c.username ?? "" }) }
          : { ok: false, text: say(c.code) },
      );
      if (c.ok) setStep(3);
    } finally {
      setBusy(false);
    }
  };
  const connect = async () => {
    setBusy(true);
    try {
      await getApi().secretaryConnectTelegram({
        name: "",
        token: token.trim(),
        ...(agentId && { agentId }),
      });
      onClose();
    } catch (e) {
      setR({ ok: false, text: say((e as { code?: string }).code ?? "failed") });
    } finally {
      setBusy(false);
    }
  };
  return createPortal(
    <div class="wz-look">
      <Modal title={t("scTgTitle")} onClose={onClose} wide>
        <div class="wz-panel-in">
          <p class="wz-lead2">{t("scTgLead")}</p>
          <ol class="sc-steps">
            <Step n={1} title={t("scWa_remote")} current={step === 0} done={step > 0}>
              <RemoteStep onOk={() => step === 0 && setTimeout(() => setStep(1), 600)} />
            </Step>
            <Step n={2} title={t("scTg_botfather")} current={step === 1} done={step > 1}>
              <p>{t("scTgBotfatherText")}</p>
              <p>{external("https://t.me/BotFather", t("scTgBotfatherLink"))}</p>
              <Acts>
                <button type="button" class="wz-btn primary" onClick={() => setStep(2)}>
                  {t("scNext")}
                </button>
              </Acts>
            </Step>
            <Step n={3} title={t("scTg_token")} current={step === 2} done={step > 2}>
              <Field label={t("scTgTokenLabel")} help={t("scKeyHelp")}>
                <input
                  type="password"
                  autocomplete="off"
                  value={token}
                  onInput={(e) => setToken(v(e))}
                />
              </Field>
              <ResultLine r={r} />
              <Acts>
                <button
                  type="button"
                  class="wz-btn primary"
                  disabled={busy || !/^\d+:[\w-]{20,}$/.test(token.trim())}
                  onClick={() => void test()}
                >
                  {busy ? t("scTesting") : t("scTest")}
                </button>
              </Acts>
            </Step>
            <Step n={4} title={t("scTg_finish")} current={step === 3} done={false}>
              <AgentPick value={agentId} onChange={setAgentId} />
              <ResultLine r={r} />
              <Acts>
                <button
                  type="button"
                  class="wz-btn primary"
                  disabled={busy || !agentId}
                  onClick={() => void connect()}
                >
                  {busy ? t("scTesting") : t("scConnect")}
                </button>
              </Acts>
            </Step>
          </ol>
        </div>
      </Modal>
    </div>,
    document.body,
  );
}

function Bubble({ m }: { m: SecretaryMessageView }) {
  const who = m.by === "contact" ? "" : m.by === "agent" ? t("scByAgent") : t("scByYou");
  return (
    <div class={`sc-msg ${m.dir}`}>
      {who && <small>{who}</small>}
      <p>{m.text}</p>
    </div>
  );
}

function PendingCard({ p, onDone }: { p: SecretaryPendingView; onDone: () => void }) {
  const [text, setText] = useState(p.draft);
  const [error, setError] = useState<string>();
  const act = async (f: () => Promise<unknown>) => {
    setError(undefined);
    try {
      await f();
      onDone();
    } catch (e) {
      setError(
        say((e as { code?: string }).code ?? "failed") + (explain(e) ? ` ${explain(e)}` : ""),
      );
    }
  };
  return (
    <div class="sc-pending">
      <b>
        {p.contactName} <small>{t(`scReason_${p.reason}`)}</small>
      </b>
      <p>{p.summary}</p>
      <label class="wz-lb" for={`sc-${p.id}`}>
        {t("scReady")}
      </label>
      <textarea
        id={`sc-${p.id}`}
        rows={3}
        value={text}
        onInput={(e) => setText((e.target as HTMLTextAreaElement).value)}
      />
      {error && <p class="notice error">{error}</p>}
      <Acts>
        <button
          type="button"
          class="wz-btn quiet"
          onClick={() => void act(() => getApi().secretaryRefuse(p.id))}
        >
          {t("scRefuse")}
        </button>
        <button
          type="button"
          class="wz-btn primary"
          disabled={!text.trim()}
          onClick={() =>
            void act(() =>
              getApi().secretaryApprove(p.id, text.trim() === p.draft.trim() ? undefined : text),
            )
          }
        >
          <IconSend size={14} /> {text.trim() === p.draft.trim() ? t("scSend") : t("scSendEdited")}
        </button>
      </Acts>
    </div>
  );
}

function Conversation({ id, onClose }: { id: string; onClose: () => void }) {
  const [data, setData] = useState<{
    contact: SecretaryContactView;
    messages: SecretaryMessageView[];
    pending: SecretaryPendingView[];
  }>();
  const [text, setText] = useState("");
  const [notes, setNotes] = useState("");
  const [error, setError] = useState<string>();
  const load = () =>
    void getApi()
      .secretaryConversation(id)
      .then((d) => {
        setData(d);
        setNotes((n) => n || d.contact.notes);
      });
  useEffect(() => {
    load();
    const timer = setInterval(load, 6000);
    return () => clearInterval(timer);
  }, [id]);
  const c = data?.contact;
  const send = async () => {
    setError(undefined);
    try {
      await getApi().secretarySend(id, text.trim());
      setText("");
      load();
    } catch (e) {
      setError(
        (e as { code?: string }).code === "window_closed" ? t("scWindowClosed") : explain(e),
      );
    }
  };
  return createPortal(
    <div class="wz-look">
      <Modal title={c ? c.name || c.handle : "…"} onClose={onClose} wide>
        <div class="wz-panel-in sc-conv">
          {c && (
            <>
              <p class="ui-help">
                {c.channel === "whatsapp" ? "WhatsApp" : "Telegram"} · {c.handle}
                {c.channel === "whatsapp" &&
                  ` · ${c.windowOpen ? t("scWindowOpen") : t("scWindowShut")}`}
                {c.stopped && ` · ${t("scStopped")}`}
              </p>
              <SwitchRow
                title={t("scPause")}
                help={t("scPauseHelp")}
                on={c.paused}
                onChange={(on) =>
                  void getApi().secretaryPatchContact(id, { paused: on }).then(load)
                }
              />
            </>
          )}
          {data?.pending.map((p) => (
            <PendingCard key={p.id} p={p} onDone={load} />
          ))}
          <div class="sc-thread" role="log" aria-label={t("scThread")}>
            {data?.messages.map((m) => (
              <Bubble key={m.id} m={m} />
            ))}
          </div>
          <Field label={t("scWrite")}>
            <textarea
              rows={2}
              value={text}
              onInput={(e) => setText((e.target as HTMLTextAreaElement).value)}
            />
          </Field>
          {error && <p class="notice error">{error}</p>}
          <Field label={t("scNotes")} help={t("scNotesHelp")}>
            <textarea
              rows={2}
              value={notes}
              onInput={(e) => setNotes((e.target as HTMLTextAreaElement).value)}
              onBlur={() => void getApi().secretaryPatchContact(id, { notes })}
            />
          </Field>
          <Acts>
            <button
              type="button"
              class="wz-btn quiet"
              onClick={() =>
                void askConfirm(t("scDeleteQ"), { danger: true }).then(
                  (ok) => ok && void getApi().secretaryDeleteContact(id).then(onClose),
                )
              }
            >
              {t("scDelete")}
            </button>
            <button
              type="button"
              class="wz-btn primary"
              disabled={!text.trim()}
              onClick={() => void send()}
            >
              <IconSend size={14} /> {t("scSend")}
            </button>
          </Acts>
        </div>
      </Modal>
    </div>,
    document.body,
  );
}

function AccountEditor({ a, onClose }: { a: SecretaryAccountView; onClose: () => void }) {
  const [agentId, setAgentId] = useState(a.agentId ?? "");
  const [limit, setLimit] = useState(String(a.limitPerHour));
  return createPortal(
    <div class="wz-look">
      <Modal title={a.name || a.label} onClose={onClose}>
        <div class="wz-panel-in">
          <p class="ui-help">{a.complete ? a.label : t("scNotFinished")}</p>
          <AgentPick value={agentId} onChange={setAgentId} />
          <Field label={t("scLimit")} help={t("scLimitHelp")}>
            <input value={limit} inputMode="numeric" onInput={(e) => setLimit(v(e))} />
          </Field>
          <Acts>
            <button
              type="button"
              class="wz-btn quiet"
              onClick={() =>
                void askConfirm(t("scRemoveQ"), { danger: true }).then(
                  (ok) => ok && void getApi().secretaryRemoveAccount(a.id).then(onClose),
                )
              }
            >
              {t("scRemove")}
            </button>
            <button
              type="button"
              class="wz-btn primary"
              onClick={() =>
                void getApi()
                  .secretaryUpdateAccount(a.id, {
                    agentId: agentId || null,
                    limitPerHour: Math.max(1, Math.min(60, Number(limit) || 6)),
                  })
                  .then(onClose)
              }
            >
              {t("save")}
            </button>
          </Acts>
        </div>
      </Modal>
    </div>,
    document.body,
  );
}

export function Secretary() {
  const { accounts, contacts, pending, reload } = useSecretary();
  const [guide, setGuide] = useState<"whatsapp" | "telegram">();
  const [open, setOpen] = useState<string>();
  const [edit, setEdit] = useState<SecretaryAccountView>();
  const closed = () => {
    setGuide(undefined);
    setOpen(undefined);
    setEdit(undefined);
    reload();
  };
  return (
    <WzPage>
      <Head eyebrow={t("scSection")} q={t("scQ")} lead={t("scLead")} />

      {pending.length > 0 && (
        <>
          <Sub
            title={t("scPendingTitle", { n: String(pending.length) })}
            lead={t("scPendingLead")}
          />
          <div class="sc-pending-list">
            {pending.map((p) => (
              <PendingCard key={p.id} p={p} onDone={reload} />
            ))}
          </div>
        </>
      )}

      <Sub title={t("scAccountsTitle")} lead={t("scAccountsLead")} />
      <div class="wz-brain aw-make aw-sources">
        {accounts.map((a) => (
          <Tile
            key={a.id}
            on={a.complete}
            icon={a.channel === "telegram" ? <IconTelegram size={20} /> : <IconChat size={20} />}
            title={a.name || (a.channel === "telegram" ? "Telegram" : "WhatsApp Business")}
            text={a.label}
            state={a.complete ? t("scConnected") : t("scNotFinished")}
            onClick={() => setEdit(a)}
          />
        ))}
        <Tile
          on={false}
          icon={<IconPlus />}
          title={t("scAddWa")}
          text={t("scAddWaText")}
          onClick={() => setGuide("whatsapp")}
        />
        <Tile
          on={false}
          icon={<IconPlus />}
          title={t("scAddTg")}
          text={t("scAddTgText")}
          onClick={() => setGuide("telegram")}
        />
      </div>

      <Sub title={t("scContactsTitle")} lead={t("scContactsLead")} />
      {contacts.length === 0 ? (
        <p class="wz-subl">{t("scNoContacts")}</p>
      ) : (
        <ul class="sc-contacts">
          {contacts.map((c) => (
            <li key={c.id}>
              <button type="button" class="sc-contact" onClick={() => setOpen(c.id)}>
                <span class="sc-contact-ico">
                  {c.channel === "telegram" ? <IconTelegram size={18} /> : <IconChat size={18} />}
                </span>
                <span class="sc-contact-text">
                  <b>{c.name || c.handle}</b>
                  <small>{c.lastText}</small>
                </span>
                {c.paused && <span class="wz-badge">{t("scPaused")}</span>}
                {c.pending > 0 && <span class="wz-badge">{t("scAsks")}</span>}
                {c.unread > 0 && <span class="sc-unread">{c.unread}</span>}
              </button>
            </li>
          ))}
        </ul>
      )}
      {guide === "whatsapp" && <WhatsAppGuide onClose={closed} />}
      {guide === "telegram" && <TelegramGuide onClose={closed} />}
      {open && <Conversation id={open} onClose={closed} />}
      {edit && <AccountEditor a={edit} onClose={closed} />}
    </WzPage>
  );
}

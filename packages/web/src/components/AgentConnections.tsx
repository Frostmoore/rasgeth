// What an agent is connected to (3.12.3, decision «ogni agente con collegamenti senza limite»): any
// number of mailboxes, chats, calendars and services, by kind, each a switch of ours. An agent sees
// only what is connected to it. Used in the agent's settings (every agent), in the personal agent's
// page and in the wizard.
import type { AgentConnection, ConnectionKind } from "@redgiant/protocol";
import { MCP_CATALOG } from "@redgiant/protocol";
import { useEffect, useState } from "preact/hooks";
import type { Agent, ConnectionOptions, McpEntry, McpStatus } from "../api.js";
import { t } from "../i18n.js";
import { attempt, getApi, openTab, refresh } from "../state.js";
import { Toggle } from "./ui.js";

export const serviceName = (name: string) => MCP_CATALOG.find((e) => e.id === name)?.name ?? name;

/** The services added for everyone (not for one project), and whether each works. */
export function useServices(): { servers: McpEntry[]; status: McpStatus[] | undefined } {
  const [servers, setServers] = useState<McpEntry[]>([]);
  const [status, setStatus] = useState<McpStatus[]>();
  useEffect(() => {
    void getApi()
      .mcpServers()
      .then(
        (l) => setServers(l.filter((m) => m.project_id === null)),
        () => {},
      );
    void getApi()
      .mcpStatus()
      .then(setStatus, () => setStatus([]));
  }, []);
  return { servers, status };
}

const has = (list: AgentConnection[], kind: ConnectionKind, ref: string) =>
  list.some((c) => c.kind === kind && c.ref === ref);

const without = (list: AgentConnection[], kind: ConnectionKind, ref: string) =>
  list.filter((c) => !(c.kind === kind && c.ref === ref));

/** The platform's name for a chat (telegram → Telegram). */
const platformName = (p: string) => p.charAt(0).toUpperCase() + p.slice(1);

/** Every kind of connection, a switch for each thing there is, and what is connected but gone. */
export function ConnectionsEditor({
  value,
  onChange,
}: {
  value: AgentConnection[];
  onChange: (v: AgentConnection[]) => void;
}) {
  const [options, setOptions] = useState<ConnectionOptions>();
  const { servers, status } = useServices();
  useEffect(() => {
    void getApi()
      .connectionOptions()
      .then(
        (o) =>
          setOptions({
            mailboxes: o.mailboxes ?? [],
            chats: o.chats ?? [],
            calendars: o.calendars ?? [],
            mcp: o.mcp ?? [],
          }),
        () => setOptions({ mailboxes: [], chats: [], calendars: [], mcp: [] }),
      );
  }, []);
  const set = (kind: ConnectionKind, ref: string, on: boolean) =>
    onChange(on ? [...value, { kind, ref }] : without(value, kind, ref));
  const gone = (kind: ConnectionKind, known: string[]) =>
    value.filter((c) => c.kind === kind && !known.includes(c.ref));
  const mcpNames = servers.map((m) => m.name);
  const goneRow = (c: AgentConnection) => (
    <Toggle
      key={`${c.kind}:${c.ref}`}
      label={c.kind === "mcp" ? serviceName(c.ref) : c.ref}
      description={t("connGone")}
      checked
      onChange={() => onChange(without(value, c.kind, c.ref))}
    />
  );
  if (!options) return <p class="ui-help">{t("extChecking")}</p>;
  return (
    <div class="asst-connections conn-editor">
      <h4 class="conn-kind">{t("connMailboxes")}</h4>
      {options.mailboxes.length === 0 && <p class="ui-help">{t("connNoMailboxes")}</p>}
      {options.mailboxes.map((b) => (
        <Toggle
          key={b.id}
          label={b.name}
          description={b.address}
          checked={has(value, "mailbox", b.id)}
          onChange={(on) => set("mailbox", b.id, on)}
        />
      ))}
      {gone(
        "mailbox",
        options.mailboxes.map((b) => b.id),
      ).map(goneRow)}

      <h4 class="conn-kind">{t("connChats")}</h4>
      {options.chats.length === 0 && <p class="ui-help">{t("connNoChats")}</p>}
      {options.chats.map((c) => (
        <Toggle
          key={c}
          label={platformName(c)}
          description={t("connChatHelp")}
          checked={has(value, "chat", c)}
          onChange={(on) => set("chat", c, on)}
        />
      ))}
      {gone("chat", options.chats).map(goneRow)}

      <h4 class="conn-kind">{t("connCalendars")}</h4>
      {options.calendars.length === 0 && <p class="ui-help">{t("connNoCalendars")}</p>}
      {options.calendars.map((c) => (
        <Toggle
          key={c.id}
          label={c.name}
          description={c.writable ? t("connWritable") : t("connReadOnly")}
          checked={has(value, "calendar", c.id)}
          onChange={(on) => set("calendar", c.id, on)}
        />
      ))}
      {gone(
        "calendar",
        options.calendars.map((c) => c.id),
      ).map(goneRow)}

      <h4 class="conn-kind">{t("connServices")}</h4>
      {servers.length === 0 && <p class="ui-help">{t("asstNoServices")}</p>}
      {servers.map((m) => {
        const s = status?.find((x) => x.name === m.name);
        return (
          <Toggle
            key={m.name}
            label={serviceName(m.name)}
            description={
              !s
                ? t("extChecking")
                : s.state === "connected"
                  ? t("extWorks", { n: String(s.tools) })
                  : s.state === "login"
                    ? t("extNeedsLogin")
                    : t("extBroken")
            }
            checked={has(value, "mcp", m.name)}
            onChange={(on) => set("mcp", m.name, on)}
          />
        );
      })}
      {gone("mcp", mcpNames).map(goneRow)}
      <button
        type="button"
        class="link"
        onClick={() =>
          openTab({ id: "settings", type: "settings", title: t("settings"), section: "extensions" })
        }
      >
        {t("asstAddService")}
      </button>
    </div>
  );
}

/** The agent's «Connections» tab: its list, saved with the button. */
export function ConnectionsTab({ agent }: { agent: Agent }) {
  const [value, setValue] = useState<AgentConnection[]>(agent.connections ?? []);
  const [saved, setSaved] = useState(false);
  const same = JSON.stringify(value) === JSON.stringify(agent.connections ?? []);
  const save = async () => {
    if (await attempt(() => getApi().configureAgent(agent.id, { connections: value }))) {
      setSaved(true);
      await refresh();
    }
  };
  return (
    <div class="st-form">
      <p class="ui-help">{t("connHelp")}</p>
      <ConnectionsEditor
        value={value}
        onChange={(v) => {
          setSaved(false);
          setValue(v);
        }}
      />
      <div class="st-save">
        {saved && same && <span class="st-on">{t("connSaved")}</span>}
        {value.length > 0 && (
          <span class="ui-help">{t("connCount", { n: String(value.length) })}</span>
        )}
        <button type="button" class="wz-btn primary" disabled={same} onClick={() => void save()}>
          {t("save")}
        </button>
      </div>
    </div>
  );
}

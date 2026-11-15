// Settings › Devices (G40.1, 3.8): the person's phones and computers with RGCompanion, each with
// its own access. The list says the platform, when it was last used and from where; a device is
// renamed in our window and revoked after our confirmation (it is signed out at once). The
// devices' tokens never reach the page. Each device says where its notifications go (G40.4) and
// can be sent a test.
import type { DevicePlatform, DeviceView } from "@redgiant/protocol";
import { useEffect, useState } from "preact/hooks";
import { t } from "../i18n.js";
import { IconPhone } from "../icons.js";
import { attempt, getApi } from "../state.js";
import { askConfirm, askText } from "./dialogs.js";
import { Box, Head, Row, WzPage } from "./SettingsKit.js";

function when(iso: string): string {
  return new Date(iso).toLocaleString(undefined, { dateStyle: "short", timeStyle: "short" });
}

const platformName = (p: DevicePlatform) => t(`dvPlatform_${p}` as const);

/** «Notifications through ntfy.sh · last sent …», or why there are none. */
export function pushFacts(d: DeviceView): string {
  const p = d.push;
  if (!p) return t("dvPushNone");
  if (p.blocked === "relay_off") return t("dvPushRelayOff");
  if (p.blocked === "keychain_locked") return t("dvPushLocked");
  return [
    t("dvPushOn", { target: p.target }),
    ...(p.lastError
      ? [t("dvPushFailed", { error: p.lastError })]
      : p.lastSentAt
        ? [t("dvPushLast", { when: when(p.lastSentAt) })]
        : []),
  ].join(" · ");
}

/** «Android · last used 15/11/26, 10:00 · from 192.168.1.20». */
export function deviceFacts(d: DeviceView): string {
  return [
    platformName(d.platform),
    d.lastUsedAt ? t("dvLastUsed", { when: when(d.lastUsedAt) }) : t("dvNeverUsed"),
    ...(d.lastAddress ? [t("dvFrom", { address: d.lastAddress })] : []),
    t("dvAdded", { when: when(d.createdAt) }),
  ].join(" · ");
}

export function Devices() {
  const [list, setList] = useState<DeviceView[]>();
  const [done, setDone] = useState<string>();
  const reload = () => void attempt(() => getApi().devices()).then((l) => l && setList(l));
  useEffect(reload, []);

  const rename = async (d: DeviceView) => {
    const next = await askText(t("dvRenameQ", { name: d.name }), d.name, {
      label: t("dvName"),
      yes: t("dvRename"),
    });
    const name = next?.trim().slice(0, 60);
    if (!name || name === d.name) return;
    if ((await attempt(() => getApi().renameDevice(d.id, name))) !== undefined) reload();
  };
  const revoke = async (d: DeviceView) => {
    if (
      !(await askConfirm(t("dvRevokeQ", { name: d.name }), {
        text: t("dvRevokeText"),
        yes: t("dvRevoke"),
        danger: true,
      }))
    )
      return;
    if ((await attempt(() => getApi().revokeDevice(d.id))) !== undefined) {
      setDone(t("dvRevoked", { name: d.name }));
      reload();
    }
  };

  const test = async (d: DeviceView) => {
    setDone(undefined);
    const r = await attempt(() => getApi().testDevicePush(d.id));
    if (!r) return;
    setDone(
      r.ok
        ? t("dvPushTestOk", { name: d.name })
        : r.gone
          ? t("dvPushTestGone", { name: d.name })
          : t("dvPushTestFailed", { name: d.name, error: r.error ?? "?" }),
    );
    reload();
  };

  return (
    <WzPage class="dv-page">
      <Head q={t("dvQ")} lead={t("dvLead")} />
      <Box>
        {list?.length ? (
          list.map((d) => (
            <Row
              key={d.id}
              title={
                <span class="dv-name">
                  <IconPhone size={18} /> {d.name}
                  {d.current && <span class="wz-badge">{t("dvThis")}</span>}
                </span>
              }
              help={
                <>
                  {deviceFacts(d)}
                  <span class="dv-push">{pushFacts(d)}</span>
                </>
              }
            >
              {d.push && !d.push.blocked && (
                <button type="button" class="wz-btn small quiet" onClick={() => void test(d)}>
                  {t("dvPushTest")}
                </button>
              )}
              <button type="button" class="wz-btn small quiet" onClick={() => void rename(d)}>
                {t("dvRename")}
              </button>
              <button
                type="button"
                class="wz-btn small quiet dv-revoke"
                onClick={() => void revoke(d)}
              >
                {t("dvRevoke")}
              </button>
            </Row>
          ))
        ) : list ? (
          <p class="dim">{t("dvNone")}</p>
        ) : null}
      </Box>
      <p class="ui-help">{t("dvKeysNote")}</p>
      {done && (
        <p class="notice ok" role="status">
          {done}
        </p>
      )}
    </WzPage>
  );
}

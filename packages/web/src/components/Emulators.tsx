// Settings › Emulators (3.11, phase 1): what this machine and every node have for Android emulators,
// real Android phones and iOS simulators, as each one found it, and what is missing, in words.
// Read-only apart from this machine's two choices: the folder of an Android SDK (when it is not in
// a place Rasgeth looks at by itself) and how many emulators may run at once. Nothing is installed
// or started from here; the guided install comes later and always asks first.
import type {
  AttachedDevice,
  AvdReport,
  EmuAccel,
  EmuDeviceView,
  EmulatorMachineView,
  EmulatorReport,
  EmulatorsState,
  EmuMissing,
  SdkSource,
} from "@redgiant/protocol";
import type { ComponentChildren } from "preact";
import { useEffect, useState } from "preact/hooks";
import { t } from "../i18n.js";
import { IconAlert, IconEmulator, IconPhone, IconRefresh, IconServer } from "../icons.js";
import { attempt, getApi, openDevice } from "../state.js";
import { EmulatorInstall } from "./EmulatorInstall.js";
import { Box, Chips, Facts, Head, Row, Sub, WzPage } from "./SettingsKit.js";
import { Advanced, Field } from "./ui.js";

const OS_NAMES = { windows: "Windows", macos: "macOS", linux: "Linux" } as const;

const SOURCES: Record<SdkSource, () => string> = {
  custom: () => t("emSrc_custom"),
  ANDROID_HOME: () => t("emSrc_ANDROID_HOME"),
  ANDROID_SDK_ROOT: () => t("emSrc_ANDROID_SDK_ROOT"),
  studio: () => t("emSrc_studio"),
  standard: () => t("emSrc_standard"),
  path: () => t("emSrc_path"),
};
const MISSING: Record<EmuMissing, () => string> = {
  sdk: () => t("emMiss_sdk"),
  emulator: () => t("emMiss_emulator"),
  "platform-tools": () => t("emMiss_platform_tools"),
  "cmdline-tools": () => t("emMiss_cmdline_tools"),
  "system-image": () => t("emMiss_system_image"),
  avd: () => t("emMiss_avd"),
  accel: () => t("emMiss_accel"),
  "emulator-old": () => t("emMiss_emulator_old"),
  xcode: () => t("emMiss_xcode"),
  "ios-bridge": () => t("emMiss_ios_bridge"),
};
const ACCEL_WHY: Record<NonNullable<EmuAccel["reason"]>, () => string> = {
  "no-kvm": () => t("emAccel_no_kvm"),
  "kvm-denied": () => t("emAccel_kvm_denied"),
  container: () => t("emAccel_container"),
  disabled: () => t("emAccel_disabled"),
  unknown: () => t("emAccel_unknown"),
};

export const sourceText = (s: SdkSource) => SOURCES[s]();
export const missingText = (m: EmuMissing) => MISSING[m]();

/** «Android 15 · API 35 · x86_64 · Play Store · medium_phone». */
export function avdFacts(a: AvdReport): string {
  return [
    a.api !== undefined ? t("emApi", { api: String(a.api) }) : undefined,
    a.abi,
    a.playStore ? t("emPlayStore") : a.tag,
    a.device,
  ]
    .filter(Boolean)
    .join(" · ");
}

/** «Phone over USB · SM A525F» or «Emulator · Pixel_8», with adb's state when it is not ready. */
export function attachedFacts(d: AttachedDevice): string {
  const kind =
    d.kind === "emulator"
      ? t("emRunningEmu")
      : d.link === "wifi"
        ? t("emPhoneWifi")
        : t("emPhoneUsb");
  const state =
    d.state === "unauthorized"
      ? t("emUnauthorized")
      : d.state === "offline"
        ? t("emOffline")
        : undefined;
  return [kind, d.avd ?? d.model, state].filter(Boolean).join(" · ");
}

/** The one line that says where a machine stands. */
export function statusLine(r: EmulatorReport): string {
  if (r.ready)
    return t("emReady", { count: String(r.android.avds.filter((a) => !a.imageMissing).length) });
  if (r.container) return t("emContainer");
  if (!r.android.sdk) return t("emNoSdk");
  return t("emNotReady");
}

function accelText(r: EmulatorReport): string {
  const a = r.android.accel;
  const kind = a.kind ? a.kind.toUpperCase() : "";
  if (a.ok) return t("emAccelOk", { kind });
  return ACCEL_WHY[a.reason ?? "unknown"]();
}

/** One machine's report: facts, AVDs, devices attached, what is missing. */
export function MachineReport({ r }: { r: EmulatorReport }) {
  const sdk = r.android.sdk;
  const rows: [string, ComponentChildren][] = [
    [t("emSystem"), `${OS_NAMES[r.os]} ${r.arch}`],
    [
      t("emSdk"),
      sdk ? (
        <>
          <code>{sdk.root}</code> <small class="em-src">{sourceText(sdk.source)}</small>
        </>
      ) : (
        t("emNone")
      ),
    ],
  ];
  if (sdk) {
    rows.push([t("emEmulator"), sdk.emulator ?? t("emNone")]);
    rows.push([t("emAdb"), sdk.platformTools ?? t("emNone")]);
    rows.push([
      t("emImages"),
      sdk.images.length ? sdk.images.map((i) => <code key={i}>{i}</code>) : t("emNone"),
    ]);
  }
  rows.push([t("emAccel"), accelText(r)]);
  if (r.ios) rows.push([t("emXcode"), r.ios.xcode ?? t("emNone")]);
  return (
    <div class="em-report">
      <p class={`em-status${r.ready ? " ok" : ""}`}>{statusLine(r)}</p>
      <Facts rows={rows} />
      {r.android.avds.length > 0 && (
        <>
          <h3 class="em-h">{t("emAvds")}</h3>
          {r.android.avds.map((a) => (
            <Row
              key={a.name}
              title={
                <span class="em-name">
                  <IconEmulator size={16} /> {a.name}
                  {a.imageMissing && <span class="wz-badge">{t("emImageMissing")}</span>}
                </span>
              }
              help={avdFacts(a)}
            />
          ))}
        </>
      )}
      <h3 class="em-h">{t("emAttached")}</h3>
      {r.android.attached.length ? (
        r.android.attached.map((d) => (
          <Row
            key={d.serial}
            title={
              <span class="em-name">
                {d.kind === "emulator" ? <IconEmulator size={16} /> : <IconPhone size={16} />}{" "}
                {d.serial}
              </span>
            }
            help={attachedFacts(d)}
          />
        ))
      ) : (
        <p class="st-note">{r.android.adbIdle ? t("emAdbIdle") : t("emNoneAttached")}</p>
      )}
      {r.ios && r.ios.simulators.length > 0 && (
        <>
          <h3 class="em-h">{t("emSimulators")}</h3>
          <p class="st-note">
            {r.ios.simulators
              .slice(0, 12)
              .map((s) => `${s.name} (${s.runtime})`)
              .join(" · ")}
          </p>
        </>
      )}
      {r.missing.length > 0 && (
        <>
          <h3 class="em-h">{t("emMissing")}</h3>
          <ul class="em-missing">
            {r.missing.map((m) => (
              <li key={m}>
                <IconAlert size={14} /> {missingText(m)}
              </li>
            ))}
          </ul>
        </>
      )}
      {!sdk && r.android.looked.length > 0 && (
        <Advanced label={t("emLooked")}>
          <ul class="em-looked">
            {r.android.looked.map((l) => (
              <li key={l.path}>
                <code>{l.path}</code> <small class="em-src">{sourceText(l.source)}</small>
              </li>
            ))}
          </ul>
        </Advanced>
      )}
    </div>
  );
}

function NodeCard({ n }: { n: EmulatorMachineView }) {
  return (
    <Box class="em-node">
      <p class="em-node-name">
        <IconServer size={16} /> {n.name}
        {!n.online && <span class="wz-badge">{t("emNodeOffline")}</span>}
      </p>
      {n.report ? <MachineReport r={n.report} /> : <p class="st-note">{t("emNodeOld")}</p>}
    </Box>
  );
}

/** The devices one can open: AVDs on or off, running emulators, phones (3.11 phase 2). */
export function DeviceList() {
  const [list, setList] = useState<EmuDeviceView[]>();
  const [error, setError] = useState<string>();
  const load = () =>
    void attempt(() => getApi().emulatorDevices()).then((r) => r && setList(r.devices));
  useEffect(load, []);
  const stop = async (d: EmuDeviceView) => {
    setError(undefined);
    try {
      setList((await getApi().stopEmulatorDevice(d.id)).devices);
    } catch (e) {
      setError(e instanceof Error ? e.message : String(e));
    }
  };
  return (
    <Box class="em-devices">
      {error && <p class="ui-error">{error}</p>}
      {list === undefined ? (
        <p class="st-note">{t("emLooking")}</p>
      ) : list.length === 0 ? (
        <p class="st-note">{t("emNoDevices")}</p>
      ) : (
        list.map((d) => (
          <Row
            key={d.id}
            title={
              <span class="em-name">
                {d.kind === "phone" ? <IconPhone size={16} /> : <IconEmulator size={16} />} {d.name}
                {d.ours && <span class="wz-badge">{t("emStartedHere")}</span>}
              </span>
            }
            help={[
              d.machine,
              d.kind === "phone"
                ? d.link === "wifi"
                  ? t("emPhoneWifi")
                  : t("emPhoneUsb")
                : t("emRunningEmu"),
              t(`dsState_${d.state}` as const),
              d.serial,
            ]
              .filter(Boolean)
              .join(" · ")}
          >
            <button
              type="button"
              class="wz-btn small primary"
              disabled={d.state === "unauthorized" || d.state === "offline"}
              onClick={() => openDevice(d.id, d.machine ? `${d.name} · ${d.machine}` : d.name)}
            >
              {t("emOpen")}
            </button>
            {d.kind === "emulator" && d.state === "on" && (
              <button type="button" class="wz-btn small quiet" onClick={() => void stop(d)}>
                {t("emStop")}
              </button>
            )}
          </Row>
        ))
      )}
    </Box>
  );
}

export function Emulators() {
  const [state, setState] = useState<EmulatorsState>();
  const [path, setPath] = useState("");
  const [error, setError] = useState<string>();
  const [busy, setBusy] = useState(false);
  const load = (fresh = false) => {
    setBusy(true);
    void attempt(() => getApi().emulators(fresh))
      .then((s) => {
        if (!s) return;
        setState(s);
        setPath(s.settings.sdkPath ?? "");
      })
      .finally(() => setBusy(false));
  };
  useEffect(() => load(), []);

  const save = async (b: { sdkPath?: string | null; maxRunning?: number }) => {
    setError(undefined);
    try {
      const s = await getApi().setEmulatorSettings(b);
      setState(s);
      setPath(s.settings.sdkPath ?? "");
    } catch (e) {
      setError(e instanceof Error ? e.message : String(e));
    }
  };

  const here = state?.here.report;
  return (
    <WzPage class="em-page">
      <Head q={t("emQ")} lead={t("emLead")} />
      <Sub
        title={
          <>
            {t("emHere")}
            {state?.here.name ? ` · ${state.here.name}` : ""}
          </>
        }
      />
      <Box>
        {here ? <MachineReport r={here} /> : <p class="st-note">{t("emLooking")}</p>}
        {here && <EmulatorInstall r={here} onDone={() => load(true)} />}
        <div class="em-acts">
          <button
            type="button"
            class="wz-btn small quiet"
            disabled={busy}
            onClick={() => load(true)}
          >
            <IconRefresh size={14} /> {t("emLookAgain")}
          </button>
        </div>
      </Box>
      <Sub title={t("emDevices")} lead={t("emDevicesLead")} />
      <DeviceList />
      <Sub title={t("emFolder")} lead={t("emFolderLead")} />
      <Box>
        <Field label={t("emFolderLabel")} help={t("emFolderHelp")} error={error}>
          <input
            value={path}
            placeholder={here?.os === "windows" ? "D:\\Android\\Sdk" : "/opt/android-sdk"}
            onInput={(e) => setPath((e.target as HTMLInputElement).value)}
          />
        </Field>
        <div class="em-acts">
          <button
            type="button"
            class="wz-btn small primary"
            disabled={!path.trim() || path.trim() === (state?.settings.sdkPath ?? "")}
            onClick={() => void save({ sdkPath: path.trim() })}
          >
            {t("emFolderSave")}
          </button>
          {state?.settings.sdkPath && (
            <button
              type="button"
              class="wz-btn small quiet"
              onClick={() => void save({ sdkPath: null })}
            >
              {t("emFolderForget")}
            </button>
          )}
        </div>
      </Box>
      <Sub title={t("emMax")} lead={t("emMaxLead")} />
      <Box>
        <Chips
          options={[1, 2, 3, 4].map((n) => ({ id: n, label: String(n) }))}
          value={[state?.settings.maxRunning ?? 2]}
          onChange={(v) => v[0] !== undefined && void save({ maxRunning: v[0] })}
        />
      </Box>
      <Sub title={t("emNodes")} lead={t("emNodesLead")} />
      {state?.nodes.length ? (
        state.nodes.map((n) => <NodeCard key={n.id} n={n} />)
      ) : (
        <p class="st-note">{t("emNoNodes")}</p>
      )}
    </WzPage>
  );
}

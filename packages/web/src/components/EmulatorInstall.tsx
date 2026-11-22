// The guided install of the Android SDK pieces (3.11, phase 5), under «What is missing» of this
// machine in Settings › Emulators. A window shows what will be done (steps, folder, sizes), the
// full text of the licences to read and accept, then the install as a job with a real bar
// (percent, speed, time left) and its result; the report is read again at the end. Nothing is
// downloaded before the person presses Install; Xcode and the iOS bridge are only explained.
import type {
  EmuInstallBlock,
  EmuInstallNote,
  EmuInstallPlan,
  EmuInstallStep,
  EmuInstallStepId,
  EmulatorReport,
  EmuMissing,
  Job,
} from "@redgiant/protocol";
import { useEffect, useRef, useState } from "preact/hooks";
import { bytes } from "../format.js";
import { t } from "../i18n.js";
import { IconAlert, IconDownload, IconRefresh } from "../icons.js";
import { attempt, getApi } from "../state.js";
import { Acts, SwitchRow } from "./SettingsKit.js";
import { Advanced, Field, Modal, Progress, useJob } from "./ui.js";

/** The codes the guided install can do something about. */
const INSTALLABLE: EmuMissing[] = [
  "sdk",
  "emulator",
  "platform-tools",
  "cmdline-tools",
  "system-image",
  "avd",
];

/** Which buttons this machine gets: install what is missing, update the emulator. */
export function installOffer(r: EmulatorReport): { install: boolean; update: boolean } {
  if (r.container) return { install: false, update: false };
  return {
    install: r.missing.some((m) => INSTALLABLE.includes(m)),
    update: r.missing.includes("emulator-old"),
  };
}

const STEP: Record<EmuInstallStepId, (s: EmuInstallStep) => string> = {
  "cmdline-tools": (s) => t("eiStep_cmdline_tools", { version: s.version ?? "" }),
  licences: () => t("eiStep_licences"),
  "platform-tools": () => t("eiStep_platform_tools"),
  emulator: () => t("eiStep_emulator"),
  "emulator-update": (s) => t("eiStep_emulator_update", { version: s.version ?? "" }),
  "system-image": () => t("eiStep_system_image"),
  avd: (s) => t("eiStep_avd", { name: s.avd ?? "" }),
};
export const stepText = (s: EmuInstallStep) => STEP[s.id](s);

const BLOCK: Record<EmuInstallBlock, (p: EmuInstallPlan) => string> = {
  container: () => t("eiBlock_container"),
  unsupported: () => t("eiBlock_unsupported"),
  "no-accel": () => t("eiBlock_no_accel"),
  "no-java": () => t("eiBlock_no_java"),
  "java-old": (p) => t("eiBlock_java_old", { major: String(p.java?.major ?? "") }),
  "emulators-running": () => t("eiBlock_emulators_running"),
  "folder-relative": () => t("eiBlock_folder_relative"),
  "folder-not-empty": () => t("eiBlock_folder_not_empty"),
  offline: () => t("eiBlock_offline"),
  nothing: () => t("eiBlock_nothing"),
};
export const blockText = (p: EmuInstallPlan) => (p.blocked ? BLOCK[p.blocked](p) : "");

const NOTE: Record<EmuInstallNote, () => string> = {
  node: () => t("eiNote_node"),
  xcode: () => t("eiNote_xcode"),
  "ios-bridge": () => t("eiNote_ios_bridge"),
  "kvm-group": () => t("eiNote_kvm_group"),
  bios: () => t("eiNote_bios"),
};

type Mode = "install" | "emulator-update";

/** The window: the plan, the licences, the yes, then the job. */
export function InstallWindow({
  mode,
  onClose,
  onDone,
}: {
  mode: Mode;
  onClose: () => void;
  onDone: () => void;
}) {
  const [plan, setPlan] = useState<EmuInstallPlan>();
  const [error, setError] = useState<string>();
  const [folder, setFolder] = useState("");
  const [avdName, setAvdName] = useState("");
  const [accepted, setAccepted] = useState(false);
  const [jobId, setJobId] = useState<string>();
  const job = useJob(jobId);
  const told = useRef(false);

  const load = (b: { target?: string; avdName?: string } = {}) => {
    setError(undefined);
    setAccepted(false);
    setPlan(undefined);
    void getApi()
      .emulatorInstallPlan({
        ...(mode === "emulator-update" && { only: "emulator-update" as const }),
        ...(b.target && { target: b.target }),
        ...(b.avdName && { avdName: b.avdName }),
      })
      .then((p) => {
        setPlan(p);
        setFolder(p.target);
        const avd = p.steps.find((s) => s.id === "avd")?.avd;
        if (avd && !b.avdName) setAvdName(avd);
      })
      .catch((e: unknown) => setError(e instanceof Error ? e.message : String(e)));
  };
  useEffect(() => load(), []);
  useEffect(() => {
    if (job && job.state !== "running" && !told.current) {
      told.current = true;
      onDone();
    }
  }, [job?.state]);

  const start = async () => {
    if (!plan?.planId) return;
    setError(undefined);
    try {
      const r = await getApi().startEmulatorInstall({
        planId: plan.planId,
        licenceAccepted: accepted,
      });
      setJobId(r.jobId);
    } catch (e) {
      setError(e instanceof Error ? e.message : String(e));
    }
  };

  const needsLicences = (plan?.licences.length ?? 0) > 0;
  const canStart = Boolean(plan?.planId) && (!needsLicences || accepted) && !jobId;
  const avdStep = plan?.steps.find((s) => s.id === "avd");
  const title = mode === "emulator-update" ? t("eiTitleUpdate") : t("eiTitle");
  const running = job?.state === "running" || (jobId !== undefined && !job);

  return (
    <Modal
      title={title}
      wide
      class="ei-window"
      locked={running}
      onClose={onClose}
      foot={
        <Acts>
          {jobId ? (
            <>
              {job?.state === "running" && (
                <button
                  type="button"
                  class="wz-btn quiet"
                  onClick={() => void attempt(() => getApi().cancelJob(jobId))}
                >
                  {t("eiStopNow")}
                </button>
              )}
              {job && job.state !== "running" && (
                <button type="button" class="wz-btn primary" onClick={onClose}>
                  {t("eiClose")}
                </button>
              )}
            </>
          ) : (
            <>
              <button type="button" class="wz-btn quiet" onClick={onClose}>
                {t("cancel")}
              </button>
              {plan && !plan.blocked && (
                <button
                  type="button"
                  class="wz-btn primary"
                  disabled={!canStart}
                  onClick={() => void start()}
                >
                  <IconDownload size={14} />{" "}
                  {mode === "emulator-update" ? t("eiStartUpdate") : t("eiStart")}
                </button>
              )}
            </>
          )}
        </Acts>
      }
    >
      {error && <p class="ui-error">{error}</p>}
      {jobId ? (
        job ? (
          <InstallJob job={job} plan={plan} />
        ) : (
          <p class="st-note">{t("eiRunning")}</p>
        )
      ) : !plan ? (
        !error && <p class="st-note">{t("eiReading")}</p>
      ) : (
        <PlanView
          plan={plan}
          mode={mode}
          folder={folder}
          setFolder={setFolder}
          avdName={avdName}
          setAvdName={setAvdName}
          avdStep={avdStep !== undefined}
          accepted={accepted}
          setAccepted={setAccepted}
          reload={(b) => load(b)}
        />
      )}
    </Modal>
  );
}

function PlanView({
  plan,
  mode,
  folder,
  setFolder,
  avdName,
  setAvdName,
  avdStep,
  accepted,
  setAccepted,
  reload,
}: {
  plan: EmuInstallPlan;
  mode: Mode;
  folder: string;
  setFolder: (v: string) => void;
  avdName: string;
  setAvdName: (v: string) => void;
  avdStep: boolean;
  accepted: boolean;
  setAccepted: (v: boolean) => void;
  reload: (b: { target?: string; avdName?: string }) => void;
}) {
  const changed = folder.trim() !== plan.target || (avdStep && avdName.trim() !== "");
  return (
    <div class="ei-plan">
      <p class="wz-lead2">{t("eiLead")}</p>
      {plan.blocked && (
        <p class={`notice${plan.blocked === "nothing" ? " ok" : " error"} ei-block`}>
          {plan.blocked !== "nothing" && <IconAlert size={14} />} {blockText(plan)}
        </p>
      )}
      {plan.notes.length > 0 && (
        <ul class="ei-notes">
          {plan.notes.map((n) => (
            <li key={n}>{NOTE[n]()}</li>
          ))}
        </ul>
      )}
      {plan.steps.length > 0 && (
        <>
          <h3 class="em-h">{t("eiFolder")}</h3>
          <p>
            <code>{plan.target}</code>{" "}
            {plan.targetStandard && <small class="em-src">{t("eiFolderStandard")}</small>}
          </p>
          {mode === "install" && (
            <Advanced label={t("eiFolderOther")}>
              <Field label={t("eiFolder")} help={t("eiFolderHelp")}>
                <input value={folder} onInput={(e) => setFolder(e.currentTarget.value)} />
              </Field>
              {avdStep && (
                <Field label={t("eiAvdName")} help={t("eiAvdNameHelp")}>
                  <input value={avdName} onInput={(e) => setAvdName(e.currentTarget.value)} />
                </Field>
              )}
              <button
                type="button"
                class="wz-btn small quiet"
                disabled={!changed}
                onClick={() =>
                  reload({
                    ...(folder.trim() && { target: folder.trim() }),
                    ...(avdName.trim() && { avdName: avdName.trim() }),
                  })
                }
              >
                <IconRefresh size={14} /> {t("eiFolderApply")}
              </button>
            </Advanced>
          )}
          <h3 class="em-h">{t("eiSteps")}</h3>
          <ol class="ei-steps">
            {plan.steps.map((s) => (
              <li key={s.id}>
                {stepText(s)}
                {s.bytes ? <span class="dim"> · {bytes(s.bytes)}</span> : null}
              </li>
            ))}
          </ol>
          {plan.bytes > 0 && <p class="ei-total">{t("eiTotal", { size: bytes(plan.bytes) })}</p>}
          {plan.java && (
            <p class="st-note">
              {t("eiJava", { major: String(plan.java.major) })} <code>{plan.java.path}</code>
            </p>
          )}
        </>
      )}
      {!plan.blocked && plan.licences.length > 0 && (
        <>
          <h3 class="em-h">{t("eiLicences")}</h3>
          <p class="st-note">{t("eiLicencesLead")}</p>
          {plan.licences.map((l) => (
            <div key={l.id} class="ei-licence">
              <strong>{l.id}</strong>
              <pre tabIndex={0}>{l.text}</pre>
            </div>
          ))}
          <SwitchRow
            title={t("eiLicenceAccept")}
            help={t("eiLicenceHelp")}
            on={accepted}
            onChange={setAccepted}
          />
        </>
      )}
    </div>
  );
}

/** The job: every step, the running one with its bar, and how it ended. */
function InstallJob({ job, plan }: { job: Job; plan: EmuInstallPlan | undefined }) {
  const byId = new Map(plan?.steps.map((s) => [s.id, s]));
  return (
    <div class={`ui-job ${job.state}`} aria-live="polite">
      <ol class="ui-job-steps">
        {job.steps.map((s) => {
          const step = byId.get(s.id as EmuInstallStepId) ?? { id: s.id as EmuInstallStepId };
          return (
            <li key={s.id} class={s.state}>
              <span class="ui-job-icon">
                <span class="ui-dot" />
              </span>
              <span>
                {stepText(step)}
                {s.progress && <Progress progress={s.progress} />}
              </span>
            </li>
          );
        })}
      </ol>
      {job.state === "done" && <p class="notice ok">{t("eiDone")}</p>}
      {job.state === "cancelled" && <p class="notice">{t("eiCancelled")}</p>}
      {job.state === "failed" && (
        <div class="ui-job-error">
          <p class="notice error">
            <IconAlert size={14} /> {t("eiFailed")}
          </p>
          {job.error && (
            <Advanced label={t("uiDetails")}>
              <pre>{job.error.message}</pre>
            </Advanced>
          )}
        </div>
      )}
    </div>
  );
}

/** The buttons under «What is missing» of this machine, and the window they open. */
export function EmulatorInstall({ r, onDone }: { r: EmulatorReport; onDone: () => void }) {
  const [open, setOpen] = useState<Mode>();
  const offer = installOffer(r);
  if (!offer.install && !offer.update) return null;
  return (
    <div class="em-acts ei-acts">
      {offer.install && (
        <button type="button" class="wz-btn small primary" onClick={() => setOpen("install")}>
          <IconDownload size={14} /> {t("eiInstall")}
        </button>
      )}
      {offer.update && (
        <button type="button" class="wz-btn small quiet" onClick={() => setOpen("emulator-update")}>
          <IconRefresh size={14} /> {t("eiUpdate")}
        </button>
      )}
      {open && <InstallWindow mode={open} onClose={() => setOpen(undefined)} onDone={onDone} />}
    </div>
  );
}

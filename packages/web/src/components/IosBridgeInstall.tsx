// The guided install of the iOS bridge (3.12.2), under «What is missing» of this Mac in Settings ›
// Emulators: a window with what will be downloaded (serve-sim, its licence, the folder, the size),
// then the person's yes and the install as a job with a real bar. Nothing is downloaded before the
// person presses the button. Xcode is only explained; the keyboard is never repaired from here.
import type { IosBridgeBlock, IosBridgePlan } from "@redgiant/protocol";
import { useEffect, useRef, useState } from "preact/hooks";
import { bytes } from "../format.js";
import { t } from "../i18n.js";
import { IconAlert, IconDownload } from "../icons.js";
import { attempt, getApi } from "../state.js";
import { Acts, Facts } from "./SettingsKit.js";
import { Modal, Progress, useJob } from "./ui.js";

const BLOCK: Record<IosBridgeBlock, () => string> = {
  "not-mac": () => t("ibBlock_not_mac"),
  intel: () => t("ibBlock_intel"),
  "no-xcode": () => t("ibBlock_no_xcode"),
  "no-npm": () => t("ibBlock_no_npm"),
  offline: () => t("ibBlock_offline"),
  nothing: () => t("ibBlock_nothing"),
};
export const iosBlockText = (b: IosBridgeBlock) => BLOCK[b]();

const STEP: Record<string, () => string> = {
  "ios-download": () => t("ibStepDownload"),
  "ios-install": () => t("ibStepInstall"),
};

export function IosBridgeWindow({ onClose, onDone }: { onClose: () => void; onDone: () => void }) {
  const [plan, setPlan] = useState<IosBridgePlan>();
  const [error, setError] = useState<string>();
  const [jobId, setJobId] = useState<string>();
  const job = useJob(jobId);
  const told = useRef(false);

  useEffect(() => {
    getApi()
      .iosBridgePlan()
      .then(setPlan)
      .catch((e: unknown) => setError(e instanceof Error ? e.message : String(e)));
  }, []);
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
      setJobId((await getApi().startIosBridgeInstall({ planId: plan.planId })).jobId);
    } catch (e) {
      setError(e instanceof Error ? e.message : String(e));
    }
  };
  const running = job?.state === "running" || (jobId !== undefined && !job);

  return (
    <Modal
      title={t("ibTitle")}
      wide
      class="ei-window"
      locked={running}
      onClose={onClose}
      foot={
        <Acts>
          {jobId ? (
            job?.state === "running" ? (
              <button
                type="button"
                class="wz-btn quiet"
                onClick={() => void attempt(() => getApi().cancelJob(jobId))}
              >
                {t("eiStopNow")}
              </button>
            ) : (
              job && (
                <button type="button" class="wz-btn primary" onClick={onClose}>
                  {t("eiClose")}
                </button>
              )
            )
          ) : (
            <>
              <button type="button" class="wz-btn quiet" onClick={onClose}>
                {t("cancel")}
              </button>
              {plan?.planId && (
                <button type="button" class="wz-btn primary" onClick={() => void start()}>
                  <IconDownload size={14} /> {t("ibStart")}
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
          <div class={`ui-job ${job.state}`} aria-live="polite">
            <ol class="ui-job-steps">
              {job.steps.map((s) => (
                <li key={s.id} class={s.state}>
                  <span class="ui-job-icon">
                    <span class="ui-dot" />
                  </span>
                  <span>
                    {(STEP[s.id] ?? (() => s.id))()}
                    {s.progress && <Progress progress={s.progress} />}
                  </span>
                </li>
              ))}
            </ol>
            {job.state === "done" && <p class="notice ok">{t("ibDone")}</p>}
            {job.state === "cancelled" && <p class="notice">{t("eiCancelled")}</p>}
            {job.state === "failed" && (
              <p class="notice error">
                <IconAlert size={14} /> {t("eiFailed")} {job.error?.message}
              </p>
            )}
          </div>
        ) : (
          <p class="st-note">{t("eiRunning")}</p>
        )
      ) : !plan ? (
        !error && <p class="st-note">{t("eiReading")}</p>
      ) : (
        <div class="ei-plan">
          <p class="wz-lead2">{t("ibLead")}</p>
          {plan.blocked && (
            <p class={`notice${plan.blocked === "nothing" ? " ok" : " error"} ei-block`}>
              {plan.blocked !== "nothing" && <IconAlert size={14} />} {iosBlockText(plan.blocked)}
            </p>
          )}
          {!plan.blocked && (
            <Facts
              rows={[
                [t("ibFolder"), <code key="f">{plan.folder}</code>],
                [t("ibVersion"), `serve-sim ${plan.version}`],
                [t("ibLicence"), plan.licence],
                ...(plan.bytes > 0
                  ? ([[t("ibSize"), bytes(plan.bytes)]] as [string, string][])
                  : []),
              ]}
            />
          )}
          {!plan.blocked && <p class="st-note">{t("ibKeyboard")}</p>}
        </div>
      )}
    </Modal>
  );
}

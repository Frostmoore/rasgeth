// RedGiant OS's update followed in the page (3.8.1, the person: «vediti tutto il procedimento di
// aggiornamento e rendilo comprensibile»): the steps numbered, the one running lit, the downloads
// with a real bar (bytes, speed, time left), a guess of the time the whole still needs, RedGiant's
// restart said in plain words and the page reconnecting and reloading by itself as the new
// version; when it stops, why in plain words and what to do.
import type { OsUpdates } from "@redgiant/protocol";
import { useEffect, useRef, useState } from "preact/hooks";
import { bytes } from "../format.js";
import { type Key, t, tOptional } from "../i18n.js";
import { IconAlert, IconCheck, IconExternal } from "../icons.js";
import {
  type OsUpdate,
  planBytes,
  secondsLeft,
  tookSeconds,
  updatedTo,
  updateSteps,
  updating,
} from "../os-update.js";
import { getApi } from "../state.js";
import { StepList } from "./SettingsKit.js";
import { reloadAsUpdated } from "./Updated.js";
import { Progress, timeLeft } from "./ui.js";
import { NewsWindow, newsSince } from "./WhatsNew.js";

/** How often the page reads the updater's state (it writes it once a second); tests shorten it. */
export const followTiming = { every: 2000 };

/**
 * Follows the machine's update: its state every two seconds, through RedGiant's own restart
 * (the server stops answering for a while), then reloads the page as the new version.
 */
export function useOsUpdateFollow(initial: OsUpdates | null) {
  const [u, setU] = useState<OsUpdates | null>(initial);
  const [lost, setLost] = useState(false);
  const [following, setFollowing] = useState(false);
  const [reloading, setReloading] = useState<string | null>(null);
  const [now, setNow] = useState(Date.now());
  const live = useRef(true);
  const running = useRef(false);
  /** `grace`: just asked to start, the unit may not be running yet. */
  const follow = async (before: string | null, grace = 0) => {
    if (running.current) return;
    running.current = true;
    setFollowing(true);
    const started = Date.now();
    const until = started + 45 * 60_000;
    let wasLost = false;
    while (live.current && Date.now() < until) {
      await new Promise((r) => setTimeout(r, followTiming.every));
      const r = await getApi()
        .setupOsUpdates()
        .catch(() => null);
      if (!live.current) break;
      if (!r) {
        wasLost = true;
        setLost(true);
        continue;
      }
      setLost(false);
      if (Date.now() - started < grace && !updating(r.update, r.running) && !wasLost) continue;
      setU(r);
      if (updating(r.update, r.running)) continue;
      const to = r.update?.installed ?? null;
      // Another version answers: this page is the old one, it reloads as the new one.
      if (r.update?.state === "latest" && to && (wasLost || (before && to !== before))) {
        setReloading(to);
        reloadAsUpdated(to, r.update.run?.from ?? before);
      }
      break;
    }
    running.current = false;
    setFollowing(false);
  };
  useEffect(() => {
    live.current = true;
    const start = (x: OsUpdates | null) => {
      if (x && updating(x.update, x.running)) void follow(x.update?.installed ?? null);
    };
    if (initial) start(initial);
    else
      void getApi()
        .setupOsUpdates()
        .then(
          (x) => {
            if (!live.current) return;
            setU(x);
            start(x);
          },
          () => {},
        );
    const tick = setInterval(() => setNow(Date.now()), 1000);
    return () => {
      live.current = false;
      clearInterval(tick);
    };
  }, []);
  const active = !!u && (following || lost || !!reloading || updating(u.update, u.running));
  return { u, setU, lost, following, reloading, active, now, follow };
}

const name = (n: string) => tOptional(`osImg_${n}`) ?? n;

/** How long something took, in words: «less than a minute», «4 min», «1 h 5 min». */
export function duration(seconds: number): string {
  if (seconds < 60) return t("osTookLess");
  const min = Math.round(seconds / 60);
  return min < 60
    ? t("osTookMin", { min: String(min) })
    : t("osTookHours", { h: String(Math.floor(min / 60)), min: String(min % 60) });
}

/** What a step says under its title. */
function stepText(id: string, mark: string, up: OsUpdate, lost: boolean) {
  const run = up.run ?? null;
  const p = run?.progress ?? null;
  const now = mark === "now";
  if (id === "download") {
    const list = run?.plan?.images ?? [];
    const items = p?.items ?? [];
    return (
      <>
        {list.length > 0 && (
          <ul class="os-run-items">
            {list.map((i) => {
              const live = items.find((x) => x.name === i.name);
              return (
                <li key={i.ref}>
                  <span>{name(i.name)}</span>
                  <span class="dim">
                    {i.here
                      ? t("osImgHere")
                      : now && live?.state === "down" && live.total > 0
                        ? t("uiOf", { done: bytes(live.done), total: bytes(live.total) })
                        : now && live?.state === "extract"
                          ? t("osImgExtract")
                          : live?.state === "done" || mark === "done"
                            ? t("osImgDone")
                            : bytes(i.bytes)}
                  </span>
                </li>
              );
            })}
          </ul>
        )}
        {now && (p ? <Bar p={p} /> : <p class="dim">{t("osRunAsking")}</p>)}
        {now && p && p.total > 0 && p.done >= p.total && <p class="dim">{t("osRunExtracting")}</p>}
      </>
    );
  }
  if (id === "files") {
    const f = run?.plan?.files;
    return (
      <>
        {f && <span>{t("osStepText_files", { size: bytes(f.bytes) })}</span>}
        {now && p && <Bar p={p} />}
      </>
    );
  }
  if (id === "restart" && now && lost) return <span>{t("osRunReconnecting")}</span>;
  return now || mark === "failed" ? <span>{tOptional(`osStepText_${id}`) ?? ""}</span> : undefined;
}

function Bar({ p }: { p: NonNullable<NonNullable<OsUpdate["run"]>["progress"]> }) {
  return (
    <Progress
      progress={{
        done: p.done,
        total: p.total > 0 ? p.total : null,
        rate: p.bps > 0 ? p.bps : null,
        secondsLeft: p.eta,
      }}
    />
  );
}

/** The update under way: where it goes, how long it still needs, its steps. */
export function OsRunView({
  u,
  lost,
  reloading,
  now,
}: {
  u: OsUpdates;
  lost: boolean;
  reloading: string | null;
  now: number;
}) {
  const up = u.update;
  if (!up) return null;
  const steps = updateSteps(up, u.running, lost);
  const left = secondsLeft(up, u.running, now, lost);
  const from = up.run?.from ?? up.installed;
  const to = up.latest;
  const total = planBytes(up);
  const current = steps.find((s) => s.mark === "now")?.id;
  const before = current === "check" || current === "download" || current === "files";
  return (
    <div class="os-run" aria-live="polite">
      <div class="os-run-hd">
        <b>
          {from && to
            ? t("osRunTitle", { from, to })
            : t("osRunTitleTo", { to: to ?? up.installed ?? "" })}
        </b>
        <span class="dim">
          {reloading
            ? t("osRunReloading", { version: reloading })
            : left !== null
              ? timeLeft(left)
              : t("osRunLeftUnknown")}
          {total > 0 &&
            (current === "check" || current === "download") &&
            ` · ${t("osRunTotal", { size: bytes(total) })}`}
        </span>
      </div>
      <StepList
        label={t("osRunSteps")}
        steps={steps.map((s) => ({
          id: s.id,
          mark: s.mark,
          title: t(`osStep_${s.id}` as Key),
          text: stepText(s.id, s.mark, up, lost),
        }))}
      />
      <p class="dim">{t(before ? "osRunKeeps" : "osRunComesBack")}</p>
    </div>
  );
}

/** The words of a stop: what happened and what to do. */
export function whyOf(u: OsUpdates): string | null {
  const up = u.update;
  if (!up) return null;
  if (up.state === "error") return up.run?.reason ?? "other";
  // A look that failed is not an update that failed: only when an update ran into it.
  if ((up.state === "unreachable" || up.state === "unsigned") && up.run) return up.state;
  return null;
}

/** How the last update ended: the new version with its news, or why it stopped. */
export function OsRunResult({ u, onRetry }: { u: OsUpdates; onRetry?: () => void }) {
  const [news, setNews] = useState(false);
  const up = u.update;
  if (!up) return null;
  const why = whyOf(u);
  const from = up.run?.from ?? up.installed ?? "";
  if (why) {
    const steps = up.run ? updateSteps(up, false) : [];
    return (
      <div class="os-run os-run-stop">
        <div class="wz-note warn">
          <IconAlert size={18} />
          <span>
            <b>{t(`osWhy_${why}` as Key, { from, to: up.latest ?? "" })}</b>{" "}
            {t(`osWhyText_${why}` as Key, { from, to: up.latest ?? "" })}
          </span>
        </div>
        {steps.length > 0 && (
          <StepList
            label={t("osRunSteps")}
            steps={steps.map((s) => ({
              id: s.id,
              mark: s.mark,
              title: t(`osStep_${s.id}` as Key),
            }))}
          />
        )}
        {onRetry && up.gate !== "breaking" && up.latest && up.latest !== up.installed && (
          <button type="button" class="wz-btn" onClick={onRetry}>
            {t("osRunRetry")}
          </button>
        )}
      </div>
    );
  }
  const done = updatedTo(up);
  // Said for a day after it ended (then the facts say the version).
  const ended = up.run?.finishedAt ? Date.parse(up.run.finishedAt) : 0;
  if (!done || Date.now() - ended > 86_400_000) return null;
  const took = tookSeconds(up);
  const groups = newsSince(done.from);
  return (
    <div class="wz-note ok os-run-done">
      <IconCheck size={18} />
      <span>
        <b>{t("osRunDone", { version: done.to })}</b>{" "}
        {took !== null
          ? t("osRunDoneText", { from: done.from, time: duration(took) })
          : t("osRunDoneFrom", { from: done.from })}{" "}
        {groups.length > 0 ? (
          <button type="button" class="link" onClick={() => setNews(true)}>
            {t("updDoneNews")}
          </button>
        ) : (
          <a
            href={`https://github.com/Frostmoore/redgiant2/releases/tag/v${done.to}`}
            target="_blank"
            rel="noreferrer"
          >
            {t("updDoneNotes")} <IconExternal size={13} />
          </a>
        )}
      </span>
      {news && <NewsWindow groups={groups} onClose={() => setNews(false)} />}
    </div>
  );
}

/** For the mandatory update's window: the update followed until the page reloads. */
export function OsUpdateLive() {
  const f = useOsUpdateFollow(null);
  useEffect(() => {
    // Started a moment ago: the updater may not have written its first state yet.
    void f.follow(f.u?.update?.installed ?? null, 15_000);
  }, []);
  if (!f.u) return null;
  return f.active ? (
    <OsRunView u={f.u} lost={f.lost} reloading={f.reloading} now={f.now} />
  ) : (
    <OsRunResult u={f.u} />
  );
}

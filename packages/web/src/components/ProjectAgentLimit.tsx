// How many agents a project may have besides its orchestrator (2026-11-18, the person: «un'opzione
// per poter limitare i sotto-agenti di ciascun progetto. Default 3, e posso arrivare a 0»). Our
// slider in steps, 0 to 10; it saves a moment after the person lets go, in the history and
// undoable. Lowering it removes nobody: the line under it says so when the team is over it.
import { PROJECT_AGENTS_DEFAULT, PROJECT_AGENTS_MAX } from "@redgiant/protocol";
import { useEffect, useRef, useState } from "preact/hooks";
import type { Project } from "../api.js";
import { explain } from "../explain.js";
import { t } from "../i18n.js";
import { getApi, refreshProjects } from "../state.js";
import { Slider } from "./SettingsKit.js";

/** How long after the last step the choice is saved: one change in the history, not ten. */
export const SAVE_AFTER_MS = 700;

export const agentsWord = (n: number) =>
  n === 0 ? t("palNone") : n === 1 ? t("palOne") : t("palN", { n: String(n) });

export function AgentLimitControl({ project }: { project: Project }) {
  const now = project.maxAgents ?? PROJECT_AGENTS_DEFAULT;
  const [value, setValue] = useState(now);
  const [saved, setSaved] = useState(false);
  const [error, setError] = useState<string>();
  const timer = useRef<ReturnType<typeof setTimeout> | undefined>(undefined);
  // The server's value when it changes elsewhere (another page, the app, an undo).
  useEffect(() => setValue(now), [now]);
  useEffect(() => () => clearTimeout(timer.current), []);
  const pick = (n: number) => {
    setValue(n);
    setSaved(false);
    setError(undefined);
    clearTimeout(timer.current);
    if (n === now) return;
    timer.current = setTimeout(() => {
      void getApi()
        .setProjectMaxAgents(project.id, n)
        .then(
          async () => {
            setSaved(true);
            await refreshProjects().catch(() => {});
          },
          (err) => {
            setError(explain(err));
            setValue(now);
          },
        );
    }, SAVE_AFTER_MS);
  };
  const count = project.agents ?? 0;
  return (
    <div class="pal" data-project={project.id}>
      <Slider
        label={t("palTitle")}
        value={value}
        min={0}
        max={PROJECT_AGENTS_MAX}
        step={1}
        onChange={pick}
        format={(n) => (n === 0 ? t("palZero") : String(n))}
        help={
          <>
            {t("palHelp")} {t("palNow", { n: agentsWord(count) })}
          </>
        }
      />
      {count > value && (
        <p class="notice warn pal-over" role="status">
          {t("palOver", { n: agentsWord(count), max: String(value) })}
        </p>
      )}
      {saved && (
        <p class="pal-saved" role="status">
          {t("palSaved")}
        </p>
      )}
      {error && <p class="notice error">{error}</p>}
    </div>
  );
}

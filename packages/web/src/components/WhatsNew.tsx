// What a big update brings (the user's rule, 2026-10-26): shown once, at the first opening after
// updating, never to whoever installs RedGiant now (they get the introduction). "Updated" means
// the installation was born with an older version (the server's `firstVersion`, 3.7.2: Coder went
// from 3.6.0 to 3.7.1 without a conversation and saw nothing) or it already has conversations.
// Settings › General › «What's new» shows everything again. Every item carries the release it came with
// (3.5.12, the person: «la versione accanto a ogni voce, dalla più recente»): the window shows only
// what is newer than the last version this browser saw, grouped by version, newest first.
import { useEffect, useState } from "preact/hooks";
import { type Key, t } from "../i18n.js";
import { getApi } from "../state.js";
import { Modal } from "./ui.js";

/** Bump with every big update, and write its items below with that version. */
export const NEWS_VERSION = "3.9.0";
const SEEN = "rg.newsSeen";

export interface NewsItem {
  /** The release that brought it ("3.5.9"). */
  version: string;
  title: Key;
  text: Key;
}

export const ITEMS: NewsItem[] = [
  { version: "3.9.0", title: "news390Name", text: "news390NameText" },
  { version: "3.9.0", title: "news390Look", text: "news390LookText" },
  { version: "3.9.0", title: "news390Install", text: "news390InstallText" },
  { version: "3.8.14", title: "news3814Editors", text: "news3814EditorsText" },
  { version: "3.8.14", title: "news3814Automations", text: "news3814AutomationsText" },
  { version: "3.8.14", title: "news3814Knowledge", text: "news3814KnowledgeText" },
  { version: "3.8.13", title: "news3813Canvas", text: "news3813CanvasText" },
  { version: "3.8.13", title: "news3813Limit", text: "news3813LimitText" },
  { version: "3.8.13", title: "news3813Update", text: "news3813UpdateText" },
  { version: "3.8.12", title: "news3812Team", text: "news3812TeamText" },
  { version: "3.8.12", title: "news3812Settings", text: "news3812SettingsText" },
  { version: "3.8.12", title: "news3812Projects", text: "news3812ProjectsText" },
  { version: "3.8.11", title: "news3811Canvas", text: "news3811CanvasText" },
  { version: "3.8.11", title: "news3811Files", text: "news3811FilesText" },
  { version: "3.8.11", title: "news3811Boards", text: "news3811BoardsText" },
  { version: "3.8.10", title: "news3810Live", text: "news3810LiveText" },
  { version: "3.8.10", title: "news3810Menus", text: "news3810MenusText" },
  { version: "3.8.10", title: "news3810Agents", text: "news3810AgentsText" },
  { version: "3.8.10", title: "news3810Queue", text: "news3810QueueText" },
  { version: "3.8.9", title: "news389Asks", text: "news389AsksText" },
  { version: "3.8.9", title: "news389Restart", text: "news389RestartText" },
  { version: "3.8.9", title: "news389Small", text: "news389SmallText" },
  { version: "3.8.8", title: "news388Widgets", text: "news388WidgetsText" },
  { version: "3.8.8", title: "news388Fixes", text: "news388FixesText" },
  { version: "3.8.7", title: "news387Chat", text: "news387ChatText" },
  { version: "3.8.7", title: "news387Turn", text: "news387TurnText" },
  { version: "3.8.7", title: "news387Talk", text: "news387TalkText" },
  { version: "3.8.7", title: "news387Widgets", text: "news387WidgetsText" },
  { version: "3.8.7", title: "news387Agents", text: "news387AgentsText" },
  { version: "3.8.7", title: "news387Settings", text: "news387SettingsText" },
  { version: "3.8.6", title: "news386Sync", text: "news386SyncText" },
  { version: "3.8.5", title: "news385Composer", text: "news385ComposerText" },
  { version: "3.8.5", title: "news385Cursor", text: "news385CursorText" },
  { version: "3.8.4", title: "news384Fixes", text: "news384FixesText" },
  { version: "3.8.3", title: "news383Full", text: "news383FullText" },
  { version: "3.8.3", title: "news383Limits", text: "news383LimitsText" },
  { version: "3.8.3", title: "news383Paste", text: "news383PasteText" },
  { version: "3.8.3", title: "news383Send", text: "news383SendText" },
  { version: "3.8.3", title: "news383New", text: "news383NewText" },
  { version: "3.8.2", title: "news382Room", text: "news382RoomText" },
  { version: "3.8.2", title: "news382Figures", text: "news382FiguresText" },
  { version: "3.8.2", title: "news382Update", text: "news382UpdateText" },
  { version: "3.8.2", title: "news382Standalone", text: "news382StandaloneText" },
  { version: "3.8.2", title: "news382Site", text: "news382SiteText" },
  { version: "3.8.2", title: "news382Icon", text: "news382IconText" },
  { version: "3.8.1", title: "news381App", text: "news381AppText" },
  { version: "3.8.1", title: "news381Saved", text: "news381SavedText" },
  { version: "3.8.1", title: "news381Products", text: "news381ProductsText" },
  { version: "3.8.1", title: "news381Update", text: "news381UpdateText" },
  { version: "3.8.0", title: "news380Setup", text: "news380SetupText" },
  { version: "3.8.0", title: "news380Mascots", text: "news380MascotsText" },
  { version: "3.8.0", title: "news380Devices", text: "news380DevicesText" },
  { version: "3.7.3", title: "news373Voice", text: "news373VoiceText" },
  { version: "3.7.3", title: "news373Home", text: "news373HomeText" },
  { version: "3.7.3", title: "news373Os", text: "news373OsText" },
  { version: "3.7.2", title: "news372Backups", text: "news372BackupsText" },
  { version: "3.7.2", title: "news372Git", text: "news372GitText" },
  { version: "3.7.2", title: "news372Tidy", text: "news372TidyText" },
  { version: "3.7.0", title: "news370Os", text: "news370OsText" },
  { version: "3.7.0", title: "news370Access", text: "news370AccessText" },
  { version: "3.7.0", title: "news370Nodes", text: "news370NodesText" },
  { version: "3.7.0", title: "news370Reach", text: "news370ReachText" },
  { version: "3.6.0", title: "news360Mail", text: "news360MailText" },
  { version: "3.6.0", title: "news360Ssh", text: "news360SshText" },
  { version: "3.6.0", title: "news360Acp", text: "news360AcpText" },
  { version: "3.6.0", title: "news360Magic", text: "news360MagicText" },
  { version: "3.6.0", title: "news360Voice", text: "news360VoiceText" },
  { version: "3.6.0", title: "news360Bridge", text: "news360BridgeText" },
  { version: "3.5.12", title: "news3512Widgets", text: "news3512WidgetsText" },
  { version: "3.5.12", title: "news3512Fixes", text: "news3512FixesText" },
  { version: "3.5.11", title: "news3511Phone", text: "news3511PhoneText" },
  { version: "3.5.11", title: "news3511Keys", text: "news3511KeysText" },
  { version: "3.5.11", title: "news3511Fast", text: "news3511FastText" },
  { version: "3.5.10", title: "news3510Webrtc", text: "news3510WebrtcText" },
  { version: "3.5.9", title: "news359Widgets", text: "news359WidgetsText" },
  { version: "3.5.9", title: "news359Artifacts", text: "news359ArtifactsText" },
  { version: "3.5.8", title: "news358Text", text: "news358TextText" },
  { version: "3.5.8", title: "news358Net", text: "news358NetText" },
  { version: "3.5.7", title: "news357Tools", text: "news357ToolsText" },
  { version: "3.5.7", title: "news357Editors", text: "news357EditorsText" },
  { version: "3.5.7", title: "news357Agents", text: "news357AgentsText" },
  { version: "3.5.6", title: "news356Steps", text: "news356StepsText" },
  { version: "3.5.6", title: "news356Asks", text: "news356AsksText" },
  { version: "3.5.6", title: "news356Editors", text: "news356EditorsText" },
  { version: "3.5.5", title: "news355Images", text: "news355ImagesText" },
  { version: "3.5.5", title: "news355Model", text: "news355ModelText" },
  { version: "3.5.5", title: "news355Fixes", text: "news355FixesText" },
  { version: "3.5.4", title: "news354Live", text: "news354LiveText" },
  { version: "3.5.4", title: "news354Models", text: "news354ModelsText" },
  { version: "3.5.4", title: "news354Bar", text: "news354BarText" },
  { version: "3.5.4", title: "news354Critical", text: "news354CriticalText" },
  { version: "3.5.4", title: "news354Updates", text: "news354UpdatesText" },
  { version: "3.5.3", title: "news353Archive", text: "news353ArchiveText" },
  { version: "3.5.3", title: "news353Knowledge", text: "news353KnowledgeText" },
  { version: "3.5.3", title: "news353Agents", text: "news353AgentsText" },
  { version: "3.5.3", title: "news353Fixes", text: "news353FixesText" },
  { version: "3.5.2", title: "news352Pdf", text: "news352PdfText" },
  { version: "3.5.2", title: "news352Svg", text: "news352SvgText" },
  { version: "3.5.2", title: "news352Docs", text: "news352DocsText" },
  { version: "3.5.0", title: "news350Editor", text: "news350EditorText" },
  { version: "3.5.0", title: "news350Code", text: "news350CodeText" },
  { version: "3.5.0", title: "news350Sheets", text: "news350SheetsText" },
  { version: "3.5.0", title: "news350Docs", text: "news350DocsText" },
  { version: "3.4.0", title: "news340Knowledge", text: "news340KnowledgeText" },
  { version: "3.4.0", title: "news340Import", text: "news340ImportText" },
  { version: "3.4.0", title: "news340Skills", text: "news340SkillsText" },
  { version: "3.4.0", title: "news340Requests", text: "news340RequestsText" },
  { version: "3.4.0", title: "news340Keychain", text: "news340KeychainText" },
  { version: "3.4.0", title: "news340Updates", text: "news340UpdatesText" },
  { version: "3.4.0", title: "news340Windows", text: "news340WindowsText" },
  { version: "3.3.0", title: "news330Canvas", text: "news330CanvasText" },
  { version: "3.3.0", title: "news330Convert", text: "news330ConvertText" },
  { version: "3.3.0", title: "news330Blender", text: "news330BlenderText" },
  { version: "3.3.0", title: "news330Tools", text: "news330ToolsText" },
  { version: "3.2.3", title: "news323Keychain", text: "news323KeychainText" },
  { version: "3.2.3", title: "news323Memory", text: "news323MemoryText" },
  { version: "3.2.3", title: "news323Automations", text: "news323AutomationsText" },
  { version: "3.2.3", title: "news323More", text: "news323MoreText" },
  { version: "3.2.1", title: "news321Settings", text: "news321SettingsText" },
  { version: "3.2.1", title: "news321Linux", text: "news321LinuxText" },
  { version: "3.2.0", title: "news32Setup", text: "news32SetupText" },
  { version: "3.2.0", title: "news32Sources", text: "news32SourcesText" },
  { version: "3.2.0", title: "news32Models", text: "news32ModelsText" },
  { version: "3.2.0", title: "news32Stream", text: "news32StreamText" },
];

/** Release order: negative when `a` came before `b` ("3.5.9" before "3.5.10"). */
export function compareVersions(a: string, b: string): number {
  const pa = a.split(".").map((x) => Number.parseInt(x, 10) || 0);
  const pb = b.split(".").map((x) => Number.parseInt(x, 10) || 0);
  for (let i = 0; i < Math.max(pa.length, pb.length); i++) {
    const d = (pa[i] ?? 0) - (pb[i] ?? 0);
    if (d !== 0) return d;
  }
  return 0;
}

/**
 * What to show to someone who last saw `seen` (none: everything), grouped by version, newest
 * first; items keep their written order inside a version.
 */
export function newsSince(
  seen: string | null,
  items: NewsItem[] = ITEMS,
): { version: string; items: NewsItem[] }[] {
  const groups = new Map<string, NewsItem[]>();
  for (const i of items) {
    if (seen && compareVersions(i.version, seen) <= 0) continue;
    groups.set(i.version, [...(groups.get(i.version) ?? []), i]);
  }
  return [...groups]
    .sort(([a], [b]) => compareVersions(b, a))
    .map(([version, list]) => ({ version, items: list }));
}

/** An update, not a new installation: born with an older version, or with conversations already. */
export function wasUpdated(
  firstVersion: string | null | undefined,
  conversations: number,
): boolean {
  if (conversations > 0) return true;
  return !!firstVersion && compareVersions(firstVersion, NEWS_VERSION) < 0;
}

export function WhatsNew() {
  const [groups, setGroups] = useState<ReturnType<typeof newsSince>>([]);
  useEffect(() => {
    // Just updated from a page that followed it: its own window (Updated.tsx) offers the news.
    if (sessionStorage.getItem("rg.updatedTo")) return;
    const seen = localStorage.getItem(SEEN);
    const news = newsSince(seen);
    // Nothing newer than what this browser saw (also after going back to an older release).
    if (news.length === 0) return;
    const api = getApi();
    void Promise.all([
      api.sessions(),
      api.updateStatus().then(
        (s) => s.firstVersion ?? null,
        () => null,
      ),
    ]).then(
      ([rows, first]) => {
        if (wasUpdated(first, rows.length)) setGroups(news);
        // A new installation: nothing to tell, only remember it was seen.
        else localStorage.setItem(SEEN, NEWS_VERSION);
      },
      () => {},
    );
  }, []);
  if (groups.length === 0) return null;
  const close = () => {
    localStorage.setItem(SEEN, NEWS_VERSION);
    setGroups([]);
  };
  return <NewsWindow groups={groups} onClose={close} />;
}

/** The window itself: the groups given, newest first (also Settings › General, with everything). */
export function NewsWindow({
  groups,
  onClose,
}: {
  groups: ReturnType<typeof newsSince>;
  onClose: () => void;
}) {
  return (
    <Modal title={t("newsTitle", { version: NEWS_VERSION })} onClose={onClose}>
      <div class="whats-new">
        {groups.map((g) => (
          <div key={g.version} class="news-group">
            {groups.length > 1 && (
              <h4 class="news-group-head">{t("newsVersion", { version: g.version })}</h4>
            )}
            {g.items.map((i) => (
              <section key={i.title}>
                <h3>
                  <span class="news-chip">{g.version}</span>
                  {t(i.title)}
                </h3>
                <p>{t(i.text)}</p>
              </section>
            ))}
          </div>
        ))}
        <div class="row">
          <div class="spacer" />
          <button type="button" class="primary" onClick={onClose}>
            {t("newsOk")}
          </button>
        </div>
      </div>
    </Modal>
  );
}

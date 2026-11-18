// Puts the page's words for the conversation (packages/web/src/i18n.ts, it and en) into the app's
// ARB files as `cv<Key>` (G42.1), so the cards in the app say exactly what the page says. Keys
// listed in KEYS; `{name}` placeholders become ARB placeholders. Then run `flutter gen-l10n`.
//
//   node apps/companion/tool/chat_words.mjs
import { readFileSync, writeFileSync } from "node:fs";
import { dirname, join } from "node:path";
import { fileURLToPath } from "node:url";
import { fillProduct } from "./product.mjs";

const KEYS = `permAsks permWhy permDetails permTool permRawReasons showLess showAllInput allow thisChat
thisChatHint always alwaysHint deny denyWhy denyWhyPlaceholder criticalTitle criticalWhat toolReqTitle
toolReqWhy toolReqHint toolReqSession toolReqAlways toolReqNo agTitle agCap agCapHint agHint agAllowCap
agAllow agDeny manyAnswers otherAnswer proposedPlan waitingAnswer notAnswered planFeedback planApprove
planRevise sendFeedback answer todosTitle editMessage editForks editSend cancel forkHere forkHereHint
forkStartsHere forkEdited forkBack forkOrigin compaction_auto compaction_manual compaction_emergency
compaction_engine compactionUndone undo stepLimitContinue stepLimitContinueHint stepLimitGoOn cacheMissed
toolNoResult toolOnMachine toolOnNode viaScript toolSeen openSubagentChat kind_subagent elsewhereAsks
elsewhereWorking elsewhereUntitled elsewhereAnswerHere open unqueue sentWhileWorking writeWhileWorking
writeTo stopWhenBack sendQueued interrupt paBadge paChatReadOnly paRestore impChatNotice viaVoice
viaVoiceHint viaArtifact viaArtifactHint canvasOpened canvasShown boardOpen boardWaiting boardDone fileSave
canvasOpen chSecretTitle chSecretText chSecretFound chSecretKind_key chSecretKind_password
chSecretKind_code chSecretKind_card chSecretKind_iban chSecretBack chSecretSend
chSecretVault attachmentOpen toBottom thinking seeAttachments pastedOpen pastedAsText remove close
pastedSize copy copied startConversation subAsks tooMany acpKind_read acpKind_edit acpKind_delete
acpKind_move acpKind_search acpKind_execute acpKind_think acpKind_fetch acpKind_switch_mode acpKind_other
findVia_everything findVia_spotlight findVia_locate findVia_walk findVia_path findVia_container findTook
findTookCut findTookInterrupted
boardChoose boardChosen boardChoiceWord boardCommentWord boardWriteComment boardSending boardSent
boardOneVariant boardVariants boardScreens boardScreen_computer boardScreen_tablet boardScreen_phone
boardFull boardCommentHere boardSendComment boardWhole boardWholeHint boardSendToAgent boardTab
boardNotFound canvasReload embedPort drawing vwToChat canvasOpen arSection arLead arImport arEmptyTitle arEmpty1 arEmpty2
arPlacePlatform arPlaceAssistants arOpen arExport arDelete arVersion arNoHeader arLibs arFrom arPending
arReadOnly arDeleteQ arDeleteText arExportTitle arExportZip arExportZipText arExportHtml arExportHtmlText
arWhereQ arWhereLead arImported arDataIgnored arDataImported arHasData arExportData arExportDataHint
arPerms arWants arPermGranted arPermNot arGrant arRevoke arSpent
subMain subPath subRow subOpenTab subStatus_running subStatus_done subStatus_failed subStatus_stopped subFresh
subWaits subClose subTask subTaskFrom subEnded_done subEnded_failed subEnded_stopped subInterrupted subTime
subTools subTokens subNoWrite subStop cmdStrip cmdRunningN cmdDoneN cmdOpenStrip cmdShrinkStrip cmdStartedAt
cmdOutput cmdStop cmdFinishedN cmdRemoveFinished cmdRemove cmdStatus_running cmdStatus_done cmdStatus_failed
cmdStatus_stopped cmdStatus_interrupted cmdOutputTitle cmdStarted cmdEnded cmdFolder cmdBy cmdShowTimes
cmdLines cmdNoLog roomAdd roomAnswering roomEmpty roomFirst roomGone roomGroupPersonal roomInspector roomLead
roomPick roomRemove roomUsageHint roomWrite roomJoined roomLeft groups groupsEmpty groupNew chatsArchived
chatsBefore archive unarchive chatHint newChat dailyChat delete deleteChatConfirm chatToGroup
agentModelDefault inspector inspectorHint inspectorAlerts inspectorSummary folderMove folderNew folderName
folderOut exportMd board newThread title reply search summary resolve block reopen postKinds postKindLabels
statusOpen statusResolved statusBlocked emptyBoard noResults agentWholeProject boardSub you screenTitle
screenOpen screenTake screenGiveBack screenAddress screenShared screenYours screenStarting screenUnavailable
teachStart teachHint teachWho teachRecording teachDone teachTitle chatPlaceholder conversations chatInstructions
canvasFullscreen canvasFullscreenExit sideMaximize sideBackToChat vwDownload vwCanvasBack kbTitle
sideTabsLabel canvasAgentOpened vwKind_archive vwKind_audio vwKind_code vwKind_document vwKind_font
vwKind_image vwKind_layers vwKind_markdown vwKind_model vwKind_pdf vwKind_sheet vwKind_site
vwKind_slides vwKind_table vwKind_text vwKind_tree vwKind_unknown vwKind_video`
  .split(/\s+/)
  .filter(Boolean);

const here = dirname(fileURLToPath(import.meta.url));
const src = readFileSync(join(here, "../../../packages/web/src/i18n.ts"), "utf8");
const itAt = src.indexOf("\nconst it:");
const parts = { en: src.slice(0, itAt), it: src.slice(itAt) };
const re = /^ {2}([A-Za-z0-9_]+):\s*\n?\s*"((?:[^"\\]|\\.)*)",?$/gm;
const found = { it: {}, en: {} };
for (const [lang, text] of Object.entries(parts))
  for (const m of text.matchAll(re))
    if (!(m[1] in found[lang])) found[lang][m[1]] = fillProduct(JSON.parse(`"${m[2]}"`));
const camel = (k) =>
  `cv${k[0].toUpperCase()}${k.slice(1).replace(/_([a-zA-Z0-9])/g, (_, c) => c.toUpperCase())}`;
const missing = [];
for (const lang of ["it", "en"]) {
  const file = join(here, `../lib/l10n/app_${lang}.arb`);
  const arb = JSON.parse(readFileSync(file, "utf8"));
  for (const k of KEYS) {
    const v = found[lang][k];
    if (v === undefined) {
      missing.push(`${lang}:${k}`);
      continue;
    }
    const name = camel(k);
    arb[name] = v;
    const ph = [...new Set([...v.matchAll(/\{([a-zA-Z0-9_]+)\}/g)].map((m) => m[1]))];
    if (lang === "en")
      arb[`@${name}`] = {
        description: `The page's \`${k}\` (packages/web/src/i18n.ts, tool/chat_words.mjs).`,
        ...(ph.length && {
          placeholders: Object.fromEntries(ph.map((p) => [p, { type: "String" }])),
        }),
      };
  }
  writeFileSync(file, `${JSON.stringify(arb, null, 2)}\n`);
}
if (missing.length) console.log(`not in the page: ${missing.join(" ")}`);

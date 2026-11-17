// The computers' notifications (G40.10): while the app is open behind other windows, what reaches
// it over the live connection becomes a system notification, with the same rules as the
// server's (`pushFor`, `quickActions`): the same id as a push for the same request, Yes and No
// only for an ordinary request, never for a truly dangerous one nor for a canvas capability
// (its limit is chosen on its own screen).
import '../api/conversation.dart';
import '../l10n/app_localizations.dart';
import '../screens/inbox_screen.dart' show requestSummary;
import 'notice.dart';

/// `ARTIFACT_GRANT_TOOL` (packages/protocol/src/artifact-bridge.ts).
const kArtifactGrantTool = 'artifact_capability';

String _clip(String s, int n) {
  final one = s.replaceAll(RegExp(r'\s+'), ' ').trim();
  return one.length > n ? '${one.substring(0, n - 1).trimRight()}…' : one;
}

/// The notice for a request waiting on the live connection.
PushNotice liveNoticeFor(PersonRequest r, String server, AppLocalizations l) => switch (r) {
  PermissionRequest() => PushNotice(
    id: 'req:${r.requestId}',
    kind: NoticeKind.request,
    server: server,
    title: _clip(r.isCritical ? l.notifyCriticalTitle : l.notifyAsksPermission(r.agentName), 80),
    // In words when the server says them (G42.1, `withRequestWords`), as the push does.
    body: _clip(r.wordsIn(l.localeName)?.what ?? '${r.tool}: ${requestSummary(r)}', 180),
    requestId: r.requestId,
    sessionId: r.sessionId,
    actions: r.isCritical || r.tool == kArtifactGrantTool ? const [] : const ['allow', 'deny'],
    critical: r.isCritical,
  ),
  QuestionRequest() => PushNotice(
    id: 'req:${r.requestId}',
    kind: NoticeKind.question,
    server: server,
    title: _clip(l.notifyAsksYou(r.agentName), 80),
    body: _clip(r.questions.firstOrNull?.question ?? '', 180),
    requestId: r.requestId,
    sessionId: r.sessionId,
  ),
};

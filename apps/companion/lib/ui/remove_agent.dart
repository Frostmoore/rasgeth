// Removing an agent (3.8.9, the page's «Remove»): first what goes with it (the agents below it,
// the open tasks that close, the turns that stop), then the person's yes in our dialog. Nothing
// is deleted: the agent's history stays and «Removed agents» brings it back.
import 'package:flutter/material.dart';

import '../api/types.dart';
import '../app_state.dart';
import '../l10n/app_localizations.dart';
import 'dialogs.dart';

/// Whether [a] may be removed at all: never God, Demi-God or the Chat (the server says so too).
bool canRemoveAgent(AppController app, Agent a) =>
    a.kind != AgentKind.god && a.kind != AgentKind.demigod && !app.isChat(a);

/// The confirmation's text: what removing it takes with it.
String removeAgentText(AppLocalizations l, Agent a, RemovePreview? p) => [
  l.raBody(a.name),
  if (p != null && p.others.isNotEmpty) l.raWith(p.others.map((x) => x.name).join(', ')),
  if (p != null && p.tasks > 0) l.raTasks(p.tasks),
  if (p != null && p.running > 0) l.raRunning(p.running),
].join('\n\n');

/// Asks, then removes [a]; says how it went under [messengerOf]. True when it was removed.
Future<bool> confirmRemoveAgent(BuildContext context, Agent a) async {
  final app = AppScope.read(context);
  final l = AppLocalizations.of(context);
  final messenger = ScaffoldMessenger.maybeOf(context);
  if (!canRemoveAgent(app, a)) return false;
  final preview = await app.removePreview(a);
  if (!context.mounted) return false;
  if (preview != null && !preview.allowed) {
    messenger?.showSnackBar(SnackBar(content: Text(l.raProtected(a.name))));
    return false;
  }
  final yes = await askConfirm(
    context,
    title: l.raTitle(a.name),
    body: removeAgentText(l, a, preview),
    yes: l.raYes(a.name),
    danger: true,
  );
  if (!yes) return false;
  final why = await app.removeAgent(a);
  messenger?.showSnackBar(
    SnackBar(content: Text(why == null ? l.raDone(a.name) : l.raFailed(why))),
  );
  return why == null;
}

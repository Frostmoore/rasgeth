// Stopping and resuming an agent (3.8.9, the page's «Stop» and «Resume»). Stopping is a pause: its
// turns stop, with those under it, and its open tasks wait; «Resume» brings it back and the tasks
// go on in the same conversation. Removing (out of the team) is another thing: remove_agent.dart.
import 'package:flutter/material.dart';

import '../api/types.dart';
import '../app_state.dart';
import '../l10n/app_localizations.dart';
import 'dialogs.dart';

/// Whether [a] may be stopped (paused): a working agent, never God (the server says so too).
bool canPauseAgent(Agent a) => a.active && a.kind != AgentKind.god;

/// Whether [a] is stopped and may be resumed (a removed one is restored instead).
bool canResumeAgent(Agent a) => !a.active && a.kind != AgentKind.god;

/// Asks, then stops [a] (a pause); says how it went. True when it stopped.
Future<bool> confirmPauseAgent(BuildContext context, Agent a) async {
  final app = AppScope.read(context);
  final l = AppLocalizations.of(context);
  final messenger = ScaffoldMessenger.maybeOf(context);
  final yes = await askConfirm(
    context,
    title: l.paTitle(a.name),
    body: l.asStopAsk(a.name),
    yes: l.paYes(a.name),
    danger: true,
  );
  if (!yes) return false;
  final why = await app.stopAgentForGood(a);
  messenger?.hideCurrentSnackBar();
  messenger?.showSnackBar(
    SnackBar(content: Text(why == null ? l.paDone(a.name) : l.asRefused(why))),
  );
  return why == null;
}

/// Resumes [a] (no question: nothing is lost) and says how it went. True when it works again.
Future<bool> resumeAgentNow(BuildContext context, Agent a) async {
  final app = AppScope.read(context);
  final l = AppLocalizations.of(context);
  final messenger = ScaffoldMessenger.maybeOf(context);
  final r = await app.resumeAgent(a);
  final why = r.why;
  // The word of a stop just before gives way to this one.
  messenger?.hideCurrentSnackBar();
  messenger?.showSnackBar(
    SnackBar(
      content: Text(
        why != null
            ? l.paResumeFailed(why)
            : r.tasks > 0
            ? l.paResumedTasks(a.name)
            : l.paResumed(a.name),
      ),
    ),
  );
  return why == null;
}

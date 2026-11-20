// A long job started in a Canvas tab, followed in the system's notifications (G42.18): a video's
// render («Crea il video», G41.6/G41.7) says how far it is while it runs (a bar on Android, the
// percentage on the computers), then that it is done, failed or stopped. The page only says the
// job's id and its title (`job` on the bridge); the state is the server's (`GET /api/jobs/:id`),
// read every few seconds until the job ends, also when the tab is closed.
import 'dart:async';

import '../api/code.dart';
import '../l10n/app_localizations.dart';
import '../push/notice.dart';
import '../push/system_notifier.dart';

/// What a job's notification says now: its words and, while it runs, how far (0-100, or null
/// when the server does not count it yet).
({String body, int? percent, bool running}) jobNotice(JobView j, AppLocalizations l) {
  switch (j.state) {
    case 'done':
      return (body: l.jobNoticeDone, percent: null, running: false);
    case 'failed':
      final why = j.errorMessage?.trim();
      return (
        body: why == null || why.isEmpty ? l.jobNoticeFailed : l.jobNoticeFailedWhy(why),
        percent: null,
        running: false,
      );
    case 'cancelled':
      return (body: l.jobNoticeCancelled, percent: null, running: false);
  }
  // The step that runs and counts (the render after the probe), else the last one that counted.
  JobStepView? counting;
  for (final s in j.steps) {
    if ((s.total ?? 0) > 0 && s.done != null) counting = s;
    if (s.state == 'running') break;
  }
  final total = counting?.total ?? 0;
  final percent = total > 0 ? ((counting!.done! * 100) / total).floor().clamp(0, 100) : null;
  final left = counting?.secondsLeft;
  final body = percent == null
      ? l.jobNoticeStarting
      : left != null && left > 0
      ? l.jobNoticePercentLeft(percent, (left / 60).ceil())
      : l.jobNoticePercent(percent);
  return (body: body, percent: percent, running: true);
}

/// Follows jobs in the system's notifications, one at most per id.
class JobNotices {
  JobNotices({
    required this.notifier,
    required this.fetch,
    required this.words,
    required this.serverId,
    required this.server,
    this.every = const Duration(seconds: 2),
    this.giveUpAfter = 5,
  });

  final SystemNotifier notifier;

  /// The job as the server says it now.
  final Future<JobView> Function(String id) fetch;
  final AppLocalizations Function() words;
  final String serverId;

  /// The server's name, under the title.
  final String server;
  final Duration every;

  /// Reads that fail in a row before the job is left (the server gone): its last words stay.
  final int giveUpAfter;

  final _following = <String, Timer>{};

  /// Whether [id] is followed now (tests).
  bool follows(String id) => _following.containsKey(id);

  /// The notification's id for job [id].
  int notificationOf(String id) => notificationIdOf(serverId, 'job:$id');

  /// Starts following [id] under [title] (again: nothing new); [sessionId] is the conversation a
  /// tap brings back.
  void follow(String id, String title, {String? sessionId}) {
    if (_following.containsKey(id)) return;
    var misses = 0;
    var last = '';
    var busy = false;
    Future<void> tick() async {
      // A slow server: one read at a time.
      if (busy) return;
      busy = true;
      JobView j;
      try {
        j = await fetch(id);
        misses = 0;
      } on Object {
        if (++misses >= giveUpAfter) _stop(id);
        return;
      } finally {
        busy = false;
      }
      final l = words();
      final n = jobNotice(j, l);
      final key = '${n.body}|${n.percent}';
      if (key != last) {
        last = key;
        await notifier.apply(
          ShowNotification(
            notificationOf(id),
            title: title,
            body: n.body,
            server: server,
            channel: NoticeChannel.updates,
            answers: const [],
            progress: n.running ? (n.percent ?? -1) : null,
            payload: NoticeTap(
              serverId: serverId,
              noticeId: 'job:$id',
              kind: NoticeKind.task,
              sessionId: sessionId,
            ).toPayload(),
          ),
          l,
        );
      }
      if (!n.running) _stop(id);
    }

    _following[id] = Timer.periodic(every, (_) => unawaited(tick()));
    unawaited(tick());
  }

  void _stop(String id) => _following.remove(id)?.cancel();

  /// Stops following everything (the app leaves the server): the notifications stay as they are.
  void dispose() {
    for (final t in _following.values) {
      t.cancel();
    }
    _following.clear();
  }
}

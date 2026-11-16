// Follows an update of the RedGiant the app is connected to (the person: «promette di scaricare,
// chiudere l'app e riaprirla e non lo fa»): asks for it, then reads `GET /api/update/status` (and
// RedGiant OS's updater) every second, through RedGiant's own restart (the server stops answering
// for a while: every try is counted), until it answers as the new version, when the app
// reconnects by itself (HTTP and the live socket, [UpdateFollower.onBack]); or until it stops,
// with why. Works with servers that say every step (3.8.1's run and progress) and with older ones
// that say only a state and a step.
import 'dart:async';

import 'package:flutter/foundation.dart';

import 'client.dart';
import 'settings_types.dart';
import 'update_run.dart';

/// Where the follower reads the update (the client; tests put their own).
abstract class UpdateSource {
  Future<UpdateStatus> status();

  /// RedGiant OS's updater, or null where there is none.
  Future<OsUpdates?> os();

  /// Asks RedGiant to update now.
  Future<void> start();
}

class ClientUpdateSource implements UpdateSource {
  const ClientUpdateSource(this.client);

  final RedGiantClient client;

  @override
  Future<UpdateStatus> status() => client.updateStatus();

  @override
  Future<OsUpdates?> os() => client.osUpdates();

  @override
  Future<void> start() => client.updateNow();
}

enum UpdateStage {
  /// Asked: the updater may not have written its first state yet.
  starting,
  running,

  /// The server does not answer: RedGiant is restarting.
  restarting,
  done,
  failed,
}

class UpdateFollower extends ChangeNotifier {
  UpdateFollower({
    required this.source,
    required this.from,
    this.to,
    this.note,
    this.local = false,
    this.every = const Duration(seconds: 1),
    this.grace = 15,
    this.backLimit = 20,
    this.lostLimit = const Duration(minutes: 20),
    this.limit = const Duration(minutes: 45),
    this.onBack,
    DateTime Function()? now,
  }) : _now = now ?? DateTime.now,
       startedAt = (now ?? DateTime.now)();

  final UpdateSource source;

  /// The version installed when it began.
  final String? from;

  /// The version it goes to (from the last look), when known.
  String? to;

  /// The new version's note (`{it, en}`), said again at the end.
  final Map<String, dynamic>? note;

  /// The RedGiant of this very computer: its launcher does the update in a window of its own.
  final bool local;
  final Duration every;

  /// Answers saying «not updating» taken as old while the updater starts (polls).
  final int grace;

  /// Answers of the old version after the restart before it counts as gone back (polls).
  final int backLimit;

  /// How long the server may not answer before the screen says so.
  final Duration lostLimit;

  /// How long an update without any signal is waited for.
  final Duration limit;

  /// RedGiant answers as the new version: the app reconnects (HTTP and the live socket).
  final Future<void> Function()? onBack;
  final DateTime Function() _now;

  UpdateStage stage = UpdateStage.starting;
  UpdateStatus? status;
  OsUpdates? os;
  DateTime startedAt;
  DateTime? endedAt;

  /// Failed tries in a row while the server does not answer, and since when.
  int attempts = 0;
  DateTime? lostSince;

  /// The server stopped answering at least once (RedGiant restarted).
  bool wasLost = false;

  /// The version that answered at the end.
  String? doneVersion;

  /// Why it stopped: download, files, not_up, no_images, breaking, unsigned, unreachable, other,
  /// gone (the server does not come back), start (the request was refused).
  String? why;

  /// The server's words when the request was refused.
  String? error;

  /// The app reconnected by itself after the new version answered.
  bool reconnected = false;

  final Set<String> _phases = {};
  final Map<String, DateTime> _began = {};
  String? _phase;
  int _polls = 0;
  int _backPolls = 0;
  bool _seenUpdating = false;
  int _gen = 0;
  bool _disposed = false;

  DateTime get now => _now();
  Duration get elapsed => (endedAt ?? _now()).difference(startedAt);
  bool get finished => stage == UpdateStage.done || stage == UpdateStage.failed;
  bool get isOs => os != null || status?.install == 'os';

  /// This computer's RedGiant.exe or Mac app: its launcher does the update in its own window.
  bool get byLauncher => local && (status?.install == 'windows' || status?.install == 'mac');

  /// The server said every step (3.8.1): otherwise the steps come from a state and a step.
  bool get detailed => os?.run != null || _phases.isNotEmpty;

  /// «Try again» asks for the update again; after «gone» it only looks for RedGiant again.
  bool get canRetry => stage == UpdateStage.failed && !kNoRetry.contains(why);

  /// Asks for the update, then follows it.
  Future<void> begin() async {
    _reset();
    final gen = _gen;
    try {
      await source.start();
    } on ApiException catch (e) {
      if (gen != _gen) return;
      _fail('start', e.message);
      return;
    }
    if (gen != _gen) return;
    unawaited(_loop(gen));
  }

  /// Follows an update already running (found when the app opened, or after «gone»).
  void follow({bool running = true}) {
    _reset();
    if (running) _seenUpdating = true;
    stage = UpdateStage.running;
    notifyListeners();
    unawaited(_loop(_gen));
  }

  /// «Try again».
  Future<void> retry() => why == 'gone' ? Future.sync(() => follow()) : begin();

  void _reset() {
    _gen++;
    stage = UpdateStage.starting;
    startedAt = _now();
    endedAt = null;
    attempts = 0;
    lostSince = null;
    wasLost = false;
    why = null;
    error = null;
    doneVersion = null;
    reconnected = false;
    _phases.clear();
    _began.clear();
    _phase = null;
    _polls = 0;
    _backPolls = 0;
    _seenUpdating = false;
    notifyListeners();
  }

  Future<void> _loop(int gen) async {
    while (!_disposed && gen == _gen && !finished) {
      await Future<void>.delayed(every);
      if (_disposed || gen != _gen) return;
      await poll();
    }
  }

  /// One look (the loop's; tests call it too).
  @visibleForTesting
  Future<void> poll() async {
    final gen = _gen;
    UpdateStatus s;
    OsUpdates? o;
    try {
      s = await source.status();
      if (s.install == 'os' || os != null) o = await source.os();
    } on ApiException {
      if (_disposed || gen != _gen) return;
      _lost();
      return;
    }
    if (_disposed || gen != _gen) return;
    _answered(s, o);
  }

  void _lost() {
    final t = _now();
    attempts++;
    lostSince ??= t;
    wasLost = true;
    _backPolls = 0;
    stage = UpdateStage.restarting;
    if (t.difference(lostSince!) > lostLimit) {
      _fail('gone');
      return;
    }
    notifyListeners();
  }

  void _answered(UpdateStatus s, OsUpdates? o) {
    final t = _now();
    _polls++;
    attempts = 0;
    lostSince = null;
    status = s;
    if (o != null) os = o;
    // The updater's first «applying» still carries the previous check's latest (the installed version when that
    // check found nothing): the version it goes to is the one it says now.
    final latest = o?.latest ?? s.latest;
    if (latest != null && latest.isNotEmpty && stage != UpdateStage.done) to = latest;
    final p = s.progress;
    if (p != null && s.phase != null) {
      _phase = s.phase;
      if (s.phase != 'failed') {
        _phases.add(s.phase!);
        _began.putIfAbsent(s.phase!, () => t);
      }
    } else {
      _phase = null;
    }
    final step = o?.step;
    if (step != null) _began.putIfAbsent(step, () => t);
    final launcherRunning = p != null && s.phase != 'failed';
    final installed = o?.installed ?? s.installed;
    // A new version answers (RedGiant.exe's «restart» is still said for a while after it).
    if (!(o?.updating ?? false) && installed != null && from != null && installed != from) {
      _done(installed);
      return;
    }
    if ((o?.updating ?? false) || launcherRunning) {
      _seenUpdating = true;
      stage = UpdateStage.running;
      notifyListeners();
      return;
    }
    // Not updating (any more): it stopped, or it has not begun yet.
    if (s.phase == 'failed') {
      _fail('download');
      return;
    }
    final w = osWhy(o);
    if (w != null && (_seenUpdating || wasLost || _polls > grace)) {
      _fail(w);
      return;
    }
    if (wasLost) {
      // Back as the version it left: the new one did not start and the old one came back.
      _backPolls++;
      stage = UpdateStage.running;
      if (_backPolls >= backLimit) {
        _fail('not_up');
        return;
      }
      notifyListeners();
      return;
    }
    if (_polls <= grace && !_seenUpdating) {
      notifyListeners();
      return;
    }
    // A server that says nothing while it updates (before 3.8.1, RedGiant.exe and the Mac app):
    // waited for until it restarts, within the limit.
    if (o == null && !_seenUpdating) {
      stage = UpdateStage.running;
      if (elapsed > limit) {
        _fail('other');
        return;
      }
      notifyListeners();
      return;
    }
    _fail('other');
  }

  void _done(String version) {
    stage = UpdateStage.done;
    doneVersion = version;
    endedAt = _now();
    notifyListeners();
    final back = onBack;
    if (back != null) {
      unawaited(
        back().then((_) {
          if (_disposed) return;
          reconnected = true;
          notifyListeners();
        }, onError: (Object _) {}),
      );
    }
  }

  void _fail(String reason, [String? message]) {
    stage = UpdateStage.failed;
    why = reason;
    error = message;
    endedAt = _now();
    notifyListeners();
  }

  // ---- what the screen shows ----

  /// The steps with their marks.
  List<RunStep> get steps {
    final restarting = stage == UpdateStage.restarting;
    var list = isOs
        ? osSteps(os, restarting: restarting)
        : launcherSteps(
            seen: _phases,
            phase: _phase,
            restarting: restarting,
            back: wasLost && stage == UpdateStage.running,
          );
    // Back after the restart, with a server that does not say its step any more (before 3.8.1).
    if (isOs &&
        wasLost &&
        !restarting &&
        !(os?.updating ?? false) &&
        stage == UpdateStage.running) {
      list = osStepsAt(list, 'wait');
    }
    if (stage == UpdateStage.starting && !list.any((s) => s.mark != StepMark.todo)) {
      list = osStepsAt(list, list.first.id);
    }
    if (stage == UpdateStage.done) return allDone(list);
    if (stage == UpdateStage.failed) {
      if (why == 'start' || why == 'gone') return list;
      return failedAt(list);
    }
    return list;
  }

  /// The download running now (bytes, speed, time left), when the server says it.
  Progress? get progress {
    if (stage != UpdateStage.running) return null;
    if (isOs) {
      final step = os?.step;
      return step == 'download' || step == 'files' ? os?.run?.progress : null;
    }
    return status?.progress;
  }

  /// The seconds the whole still needs, or null when not known yet.
  int? get left {
    if (finished) return null;
    final run = os?.run;
    return secondsLeft(
      steps,
      progress: progress,
      began: {
        ..._began,
        for (final e in (run?.stepAt.entries ?? const <MapEntry<String, String>>[]))
          if (DateTime.tryParse(e.value) != null) e.key: DateTime.parse(e.value),
      },
      now: _now(),
      filesBytes: run?.filesBytes ?? 0,
      imageBytes: run?.imageBytes ?? 0,
    );
  }

  /// What the update downloads in all, in bytes (0: not known).
  double get totalBytes {
    final run = os?.run;
    if (run == null) return 0;
    final p = os?.step == 'download' ? run.progress : null;
    return (p != null && p.total > 0 ? p.total : run.imageBytes) + run.filesBytes;
  }

  /// How long it took, in seconds: the updater's own times when it has them.
  int? get took {
    final run = os?.run;
    final a = DateTime.tryParse(run?.startedAt ?? '');
    final b = DateTime.tryParse(run?.finishedAt ?? '');
    if (a != null && b != null && !b.isBefore(a)) return b.difference(a).inSeconds;
    return endedAt?.difference(startedAt).inSeconds;
  }

  /// The version it left, as the updater says it.
  String? get fromVersion => os?.run?.from ?? from;

  @override
  void dispose() {
    _disposed = true;
    _gen++;
    super.dispose();
  }
}

/// [steps] with [id] as the one running (the ones before it done).
List<RunStep> osStepsAt(List<RunStep> steps, String id) {
  final at = steps.indexWhere((s) => s.id == id);
  if (at < 0) return steps;
  return [
    for (final (i, s) in steps.indexed)
      RunStep(
        s.id,
        i < at
            ? StepMark.done
            : i == at
            ? StepMark.now
            : StepMark.todo,
      ),
  ];
}

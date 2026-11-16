// An update as the app shows it (the person, from the phone: «va fatto bene»), the same rules as
// the page's os-update.ts: the steps in order with which are done, which one runs and which
// failed, how long the whole still needs, and why it stopped. Pure, from what the server says:
// RedGiant OS's updater (`GET /api/setup/os-updates`, with 3.8.1's run) or RedGiant.exe's
// (`GET /api/update/status`, with 3.8.1's progress); older servers give only a state and a step.
import 'dart:math' as math;

import 'settings_types.dart';

enum StepMark { done, now, todo, failed }

class RunStep {
  const RunStep(this.id, this.mark);

  final String id;
  final StepMark mark;

  @override
  String toString() => '$id:${mark.name}';
}

/// RedGiant OS's steps, when its updater does not list them (before 3.8.1).
const kOsSteps = ['check', 'download', 'files', 'install', 'restart', 'wait'];

/// Seconds the steps without a download usually take (measured on Coder and on Windows).
const kStepSeconds = <String, int>{
  'check': 10,
  'install': 10,
  'restart': 45,
  'wait': 45,
  'rollback': 60,
  'scan': 20,
  'build': 20,
};

/// RedGiant OS's steps with their marks (`updateSteps` of os-update.ts). [restarting]: the app
/// lost the server while it followed the update.
List<RunStep> osSteps(OsUpdates? os, {bool restarting = false}) {
  final run = os?.run;
  final steps = (run?.steps.isNotEmpty ?? false) ? run!.steps : kOsSteps;
  final state = os?.state;
  final finished = state == 'latest' && run?.finishedAt != null;
  // Before 3.8.1 «files» was both the download and the install of the system's files.
  var current = restarting ? 'restart' : (os?.step ?? ((os?.running ?? false) ? 'check' : null));
  if (current == 'files' && run == null) current = 'install';
  if (current != null && !steps.contains(current)) current = null;
  if (finished) return [for (final s in steps) RunStep(s, StepMark.done)];
  if (state == 'error' || state == 'breaking') {
    // Stopped: the last step it began failed (rollback itself went through).
    final began = (run?.stepAt.keys ?? const <String>[]).where((s) => s != 'rollback');
    final last = began.isEmpty ? current : began.last;
    final at = last == null ? -1 : steps.indexOf(last);
    return [
      for (final (i, s) in steps.indexed)
        RunStep(
          s,
          s == 'rollback' || i < at
              ? StepMark.done
              : i == at
              ? StepMark.failed
              : StepMark.todo,
        ),
    ];
  }
  return _marked(steps, current);
}

/// RedGiant.exe's steps (Windows, the Mac app): from the phases it reported (3.8.1), else the
/// three every update has (download, restart, wait). [phase] is the one running now.
List<RunStep> launcherSteps({
  required Set<String> seen,
  String? phase,
  bool restarting = false,
  bool back = false,
}) {
  final steps = seen.contains('installer')
      ? const ['installer', 'restart', 'wait']
      : seen.isEmpty
      ? const ['download', 'restart', 'wait']
      : const ['scan', 'download', 'build', 'restart', 'wait'];
  final current = restarting
      ? 'restart'
      : back
      ? 'wait'
      : (phase != null && phase != 'failed' && steps.contains(phase))
      ? phase
      : seen.isEmpty
      ? 'download'
      : steps.lastWhere(seen.contains, orElse: () => steps.first);
  final marks = _marked(steps, current);
  if (phase != 'failed') return marks;
  return [for (final s in marks) s.mark == StepMark.now ? RunStep(s.id, StepMark.failed) : s];
}

List<RunStep> _marked(List<String> steps, String? current) {
  final at = current == null ? -1 : steps.indexOf(current);
  return [
    for (final (i, s) in steps.indexed)
      RunStep(
        s,
        at < 0
            ? StepMark.todo
            : i < at
            ? StepMark.done
            : i == at
            ? StepMark.now
            : StepMark.todo,
      ),
  ];
}

/// Every step done (the update ended well), or the one running marked as failed.
List<RunStep> allDone(List<RunStep> steps) => [for (final s in steps) RunStep(s.id, StepMark.done)];

List<RunStep> failedAt(List<RunStep> steps) {
  if (steps.any((s) => s.mark == StepMark.failed)) return steps;
  final i = steps.indexWhere((s) => s.mark == StepMark.now);
  return [for (final (j, s) in steps.indexed) j == i ? RunStep(s.id, StepMark.failed) : s];
}

/// The seconds the whole update probably still needs, or null when it cannot be said yet (the
/// download's speed is not known). Downloads count by their own speed, the other steps by what
/// they usually take less what the running one already took (never «0 seconds» while it runs).
int? secondsLeft(
  List<RunStep> steps, {
  Progress? progress,
  Map<String, DateTime> began = const {},
  required DateTime now,
  double filesBytes = 0,
  double imageBytes = 0,
}) {
  final current = steps.where((s) => s.mark == StepMark.now).firstOrNull;
  if (current == null) return null;
  final p = progress;
  var left = 0.0;
  for (final s in steps) {
    if (s.mark != StepMark.now && s.mark != StepMark.todo) continue;
    final now_ = s.mark == StepMark.now;
    switch (s.id) {
      case 'download' || 'installer':
        if (now_) {
          if (p == null || p.eta == null || p.bps <= 0) return null;
          left += p.eta! + (s.id == 'download' ? filesBytes / p.bps : 0);
        } else if (imageBytes > 0 || s.id == 'installer') {
          return null;
        } else if (s.id == 'download' && filesBytes == 0 && imageBytes == 0) {
          // RedGiant.exe's download not begun yet: its size comes with the scan.
          if (steps.any((x) => x.id == 'scan')) return null;
        }
      case 'files':
        if (now_) left += p != null && p.bps > 0 ? math.max(0, p.total - p.done) / p.bps : 5;
      default:
        final usual = kStepSeconds[s.id] ?? 10;
        if (now_) {
          final at = began[s.id];
          final took = at == null ? 0 : math.max(0, now.difference(at).inMilliseconds / 1000);
          if (s.id == 'scan' && p != null && p.eta != null) {
            left += p.eta!;
          } else {
            left += math.max(usual / 4, usual - took);
          }
        } else {
          left += usual;
        }
    }
  }
  return left.isFinite ? left.round() : null;
}

/// Why a RedGiant OS update stopped (`whyOf` of OsUpdateRun.tsx), or null when it did not.
String? osWhy(OsUpdates? os) {
  if (os == null) return null;
  if (os.state == 'error') return os.run?.reason ?? 'other';
  if (os.state == 'breaking' && os.run != null) return 'breaking';
  // A look that failed is not an update that failed: only when an update ran into it.
  if ((os.state == 'unreachable' || os.state == 'unsigned') && os.run != null) return os.state;
  return null;
}

/// The reasons «Try again» makes no sense for: nothing to install here, or not over this one.
const kNoRetry = {'no_images', 'breaking', 'unsigned'};

/// «less than a minute», «4 min», «1 h 5 min» as numbers: (hours, minutes), null under a minute.
(int, int)? roundMinutes(int seconds) {
  if (seconds < 60) return null;
  final min = (seconds / 60).round();
  return (min ~/ 60, min % 60);
}

/// «0:07», «4:32», «1:02:05»: a clock that moves every second.
String clock(Duration d) {
  final s = d.inSeconds.abs();
  String two(int n) => n.toString().padLeft(2, '0');
  final h = s ~/ 3600;
  final m = (s % 3600) ~/ 60;
  return h > 0 ? '$h:${two(m)}:${two(s % 60)}' : '$m:${two(s % 60)}';
}

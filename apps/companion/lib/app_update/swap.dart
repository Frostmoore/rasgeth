// The replacement (G41.8b): a small helper outside the app's folder, started just before the app
// closes (Linux: detached; Windows: see `_launch`). It waits for the app to be gone, keeps the folder as it was (`<dir>.previous`),
// puts the new version in (Windows: the downloaded RGCompanion-Setup.exe, silent, for this user,
// no administrator; Linux: the bundle of the downloaded archive, in install-app.sh's folder), then
// starts it with a marker file to write. A new version that does not write it within a minute (or
// stops first) is taken away: the old folder comes back and the old version starts again, told
// which one failed. Every step goes into the helper's log next to it.
//
// 3.9.5: the app writes its own line into that log before starting the helper and closes only once
// the helper has written its `alive` file (its first step after its first line: the app's last
// line comes after it, never over it); a helper that does not start
// leaves the app open, with the reason in the log. 3.9.0-3.9.4's Windows helper never ran, twice
// over: its first line held `$to:`, which PowerShell reads as a drive-qualified variable, so the
// whole file failed to parse; and it was started `detached`, without a console, where Windows
// PowerShell 5.1 exits at once. Nobody saw either: no window, and the app had already closed.
import 'dart:async';
import 'dart:convert';
import 'dart:io';

import '../brand.dart';

/// What the helper needs, all paths absolute.
class SwapPlan {
  const SwapPlan({
    required this.system,
    required this.pid,
    required this.dir,
    required this.exe,
    required this.fromVersion,
    required this.toVersion,
    required this.package,
    required this.marker,
    required this.log,
    required this.alive,
    this.waitSeconds = 60,
  });

  /// 'windows' or 'linux'.
  final String system;

  /// The running app's process, waited for.
  final int pid;

  /// The installed folder, replaced whole.
  final String dir;

  /// The executable started after the swap (in [dir]).
  final String exe;
  final String fromVersion;
  final String toVersion;

  /// Windows: the verified installer. Linux: the bundle folder unpacked from the verified archive.
  final String package;

  /// The file the new version writes once its window is up (`--rg-update-marker=`).
  final String marker;
  final String log;

  /// The file the helper writes right after its first line (it is running); the app closes only
  /// once it is there.
  final String alive;

  /// How long the new version has to write the marker.
  final int waitSeconds;
}

/// The arguments the helper starts the app with.
const kMarkerArg = '--rg-update-marker=';
const kUpdatedFromArg = '--rg-updated-from=';
const kUpdateFailedArg = '--rg-update-failed=';

String _sh(String s) => "'${s.replaceAll("'", r"'\''")}'";
String _ps(String s) => "'${s.replaceAll("'", "''")}'";

/// The Linux helper (POSIX sh).
String linuxSwapScript(SwapPlan p) =>
    '''
#!/bin/sh
# $kAppName's update helper (G41.8b): ${p.fromVersion} -> ${p.toVersion}.
set -u
pid=${p.pid}
dest=${_sh(p.dir)}
exe=${_sh(p.exe)}
new=${_sh(p.package)}
marker=${_sh(p.marker)}
from=${_sh(p.fromVersion)}
to=${_sh(p.toVersion)}
wait_s=${p.waitSeconds}
exec >>${_sh(p.log)} 2>&1
say() { echo "\$(date '+%F %T') \$*"; }
start() {
  if command -v setsid >/dev/null 2>&1; then setsid "\$@" </dev/null >/dev/null 2>&1 &
  else nohup "\$@" </dev/null >/dev/null 2>&1 & fi
  started=\$!
}
say "helper \$\$: update \$from -> \$to, waiting for the app (\$pid) to close"
: >${_sh(p.alive)}
i=0
while kill -0 "\$pid" 2>/dev/null; do
  i=\$((i + 1))
  if [ "\$i" -gt 150 ]; then say "the app did not close: nothing changed"; exit 1; fi
  sleep 0.2
done
[ -x "\$new/$kExeName" ] || { say "no $kExeName in \$new: nothing changed"; start "\$exe" "$kUpdateFailedArg\$to"; exit 1; }
rm -rf "\$dest.new" "\$dest.previous"
if ! { mkdir -p "\$dest.new" && cp -R "\$new/." "\$dest.new/"; }; then
  say "copy failed: nothing changed"; rm -rf "\$dest.new"; start "\$exe" "$kUpdateFailedArg\$to"; exit 1
fi
if ! mv "\$dest" "\$dest.previous"; then
  say "the folder could not be moved: nothing changed"; rm -rf "\$dest.new"; start "\$exe" "$kUpdateFailedArg\$to"; exit 1
fi
if ! mv "\$dest.new" "\$dest"; then
  say "the new folder could not be moved: going back"; mv "\$dest.previous" "\$dest"; start "\$exe" "$kUpdateFailedArg\$to"; exit 1
fi
rm -f "\$marker"
say "starting \$to"
start "\$exe" "$kMarkerArg\$marker" "$kUpdatedFromArg\$from"
npid=\$started
i=0
while [ ! -f "\$marker" ]; do
  i=\$((i + 1))
  if [ "\$i" -gt \$((wait_s * 5)) ] || ! kill -0 "\$npid" 2>/dev/null; then
    [ -f "\$marker" ] && break
    say "\$to did not start: going back to \$from"
    kill "\$npid" 2>/dev/null; sleep 1; kill -9 "\$npid" 2>/dev/null
    rm -rf "\$dest" && mv "\$dest.previous" "\$dest"
    start "\$exe" "$kUpdateFailedArg\$to"
    exit 2
  fi
  sleep 0.2
done
rm -rf "\$dest.previous"
say "\$to started: done"
exit 0
''';

/// The Windows helper (Windows PowerShell 5.1, always there).
String windowsSwapScript(SwapPlan p) =>
    '''
# $kAppName's update helper (G41.8b): ${p.fromVersion} -> ${p.toVersion}.
\$ErrorActionPreference = 'Continue'
\$appPid = ${p.pid}
\$dest = ${_ps(p.dir)}
\$exe = ${_ps(p.exe)}
\$setup = ${_ps(p.package)}
\$marker = ${_ps(p.marker)}
\$from = ${_ps(p.fromVersion)}
\$to = ${_ps(p.toVersion)}
\$log = ${_ps(p.log)}
\$alive = ${_ps(p.alive)}
\$waitS = ${p.waitSeconds}
\$prev = "\${dest}.previous"
function Say(\$t) { Add-Content -LiteralPath \$log -Value ("{0:yyyy-MM-dd HH:mm:ss} {1}" -f (Get-Date), \$t) }
trap { Say "error: \$(\$_)"; continue }
function StartApp([string[]]\$a) { Start-Process -FilePath \$exe -ArgumentList \$a -WorkingDirectory \$dest -PassThru }
function StopInFolder {
  Get-Process -ErrorAction SilentlyContinue | Where-Object { \$_.Path -like "\$dest\\*" } |
    ForEach-Object { if (-not \$_.WaitForExit(0)) { Stop-Process -Id \$_.Id -Force -ErrorAction SilentlyContinue } }
}
function GoBack(\$why) {
  Say "\$(\$why): going back to \$from"
  StopInFolder
  Start-Sleep -Milliseconds 500
  if (Test-Path -LiteralPath \$prev) {
    Remove-Item -LiteralPath \$dest -Recurse -Force -ErrorAction SilentlyContinue
    Move-Item -LiteralPath \$prev -Destination \$dest -Force
  }
  [void](StartApp @("$kUpdateFailedArg\$to"))
}
Say "helper \${PID}: update \${from} -> \${to}, waiting for the app (\${appPid}) to close"
Set-Content -LiteralPath \$alive -Value \$PID
\$p = Get-Process -Id \$appPid -ErrorAction SilentlyContinue
if (\$p -and -not \$p.WaitForExit(30000)) { Say "the app did not close: nothing changed"; exit 1 }
if (-not (Test-Path -LiteralPath \$setup)) { Say "no installer: nothing changed"; [void](StartApp @("$kUpdateFailedArg\$to")); exit 1 }
Remove-Item -LiteralPath \$prev -Recurse -Force -ErrorAction SilentlyContinue
try { Copy-Item -LiteralPath \$dest -Destination \$prev -Recurse -Force -ErrorAction Stop }
catch { Say "the folder could not be kept: nothing changed (\$_)"; [void](StartApp @("$kUpdateFailedArg\$to")); exit 1 }
Say "installing \$to"
\$i = Start-Process -FilePath \$setup -ArgumentList @('/VERYSILENT', '/SUPPRESSMSGBOXES', '/NORESTART', '/NOCANCEL', '/SP-', "/LOG=`"\$log.setup.txt`"") -Wait -PassThru
if (\$i.ExitCode -ne 0) { GoBack "the installer stopped with \$(\$i.ExitCode)"; exit 2 }
Remove-Item -LiteralPath \$marker -Force -ErrorAction SilentlyContinue
Say "starting \$to"
\$n = StartApp @("$kMarkerArg`"\$marker`"", "$kUpdatedFromArg\$from")
\$deadline = (Get-Date).AddSeconds(\$waitS)
while (-not (Test-Path -LiteralPath \$marker)) {
  if ((Get-Date) -gt \$deadline -or \$n.HasExited) {
    if (Test-Path -LiteralPath \$marker) { break }
    GoBack "\$to did not start"
    exit 2
  }
  Start-Sleep -Milliseconds 200
}
Remove-Item -LiteralPath \$prev -Recurse -Force -ErrorAction SilentlyContinue
Say "\$to started: done"
exit 0
''';

/// The helper did not write its `alive` file in time: the app stays open (the reason is in the log).
class SwapNotStarted implements Exception {
  const SwapNotStarted(this.reason);

  final String reason;

  @override
  String toString() => 'SwapNotStarted($reason)';
}

/// The helper as started: its process id, and (Windows) its end and its error output.
class SwapHelper {
  const SwapHelper(this.pid, {this.exitCode, this.stderr});

  final int pid;
  final Future<int>? exitCode;
  final Stream<List<int>>? stderr;
}

/// Starts the helper ([Process.start] by default).
typedef SwapLauncher = Future<SwapHelper> Function(String exe, List<String> args);

Future<SwapHelper> _launch(String exe, List<String> args) async {
  if (!Platform.isWindows) {
    return SwapHelper((await Process.start(exe, args, mode: ProcessStartMode.detached)).pid);
  }
  // Windows: never `detached` (DETACHED_PROCESS, no console at all): Windows PowerShell 5.1 then
  // exits at once without running a line. The normal start gives it a console without a window
  // (CREATE_NO_WINDOW), no job: it outlives the app; its pipes simply break when the app is gone.
  final p = await Process.start(exe, args);
  unawaited(p.stdout.drain<void>().catchError((Object _) {}));
  return SwapHelper(p.pid, exitCode: p.exitCode, stderr: p.stderr);
}

/// Windows PowerShell 5.1 by its full path: never another `powershell.exe` found first in PATH.
String windowsPowerShell(Map<String, String> env) {
  final root = env['SystemRoot'] ?? env['SYSTEMROOT'] ?? r'C:\Windows';
  return '$root\\System32\\WindowsPowerShell\\v1.0\\powershell.exe';
}

String _stamp(DateTime t) {
  String two(int n) => n.toString().padLeft(2, '0');
  return '${t.year}-${two(t.month)}-${two(t.day)} ${two(t.hour)}:${two(t.minute)}:${two(t.second)}';
}

/// One line of the app's own into the helper's log (same format as the helper's).
Future<void> appendSwapLog(String log, String line) async {
  try {
    final end = Platform.isWindows ? '\r\n' : '\n';
    await File(log)
        .writeAsString('${_stamp(DateTime.now())} $line$end', mode: FileMode.append, flush: true);
  } on FileSystemException {
    // The log is for people; the update does not depend on it.
  }
}

/// Writes the helper next to the download, starts it and returns once it runs (its `alive` file
/// is there): only then may the caller close the app. A helper that stops first or does not start
/// within [aliveWithin] (stopped then) throws [SwapNotStarted], with what it said in the log: the
/// app stays open.
Future<void> startSwap(
  SwapPlan p,
  String folder, {
  Duration aliveWithin = const Duration(seconds: 30),
  SwapLauncher launch = _launch,
  Map<String, String>? env,
}) async {
  final String exe;
  final List<String> args;
  if (p.system == 'windows') {
    final script = File('$folder\\swap.ps1');
    // A BOM: Windows PowerShell 5.1 reads a file without one in the system's code page.
    await script.writeAsString('\uFEFF${windowsSwapScript(p)}', flush: true);
    exe = windowsPowerShell(env ?? Platform.environment);
    args = [
      '-NoProfile',
      '-NonInteractive',
      '-ExecutionPolicy',
      'Bypass',
      '-WindowStyle',
      'Hidden',
      '-File',
      script.path,
    ];
  } else {
    final script = File('$folder/swap.sh');
    await script.writeAsString(linuxSwapScript(p), flush: true);
    exe = '/bin/sh';
    args = [script.path];
  }
  final alive = File(p.alive);
  try {
    if (alive.existsSync()) alive.deleteSync();
  } on FileSystemException {
    // A stale file would let the app close too early: better not to start at all.
    await appendSwapLog(p.log, 'app ${p.fromVersion}: an old ${p.alive} is in the way');
    throw const SwapNotStarted('stale alive file');
  }
  await appendSwapLog(p.log, 'app ${p.fromVersion}: starting the helper for ${p.toVersion}');
  final SwapHelper helper;
  try {
    helper = await launch(exe, args);
  } on Object catch (e) {
    await appendSwapLog(p.log, 'app ${p.fromVersion}: the helper could not start ($e)');
    throw SwapNotStarted('$e');
  }
  final errors = StringBuffer();
  final errorsDone = helper.stderr
      ?.transform(const Utf8Decoder(allowMalformed: true))
      .forEach((t) => errors.length < 4000 ? errors.write(t) : null)
      .catchError((Object _) {});
  int? ended;
  unawaited(helper.exitCode?.then((c) => ended = c));
  final deadline = DateTime.now().add(aliveWithin);
  while (!alive.existsSync()) {
    final gone = ended != null;
    if (gone || DateTime.now().isAfter(deadline)) {
      if (gone) {
        await errorsDone?.timeout(const Duration(seconds: 2), onTimeout: () {});
      } else {
        Process.killPid(helper.pid);
      }
      final why = gone
          ? 'stopped with $ended before running'
          : 'did not start within ${aliveWithin.inSeconds} s';
      final said = errors.toString().trim();
      await appendSwapLog(
        p.log,
        'app ${p.fromVersion}: the helper (${helper.pid}) $why: the app stays open'
        '${said.isEmpty ? '' : '\n$said'}',
      );
      throw SwapNotStarted(why);
    }
    await Future<void>.delayed(const Duration(milliseconds: 100));
  }
  await appendSwapLog(
    p.log,
    'app ${p.fromVersion}: the helper (${helper.pid}) runs, the app closes',
  );
}

/// The bundle folder inside the unpacked Linux archive (`<top>/bundle/rgcompanion`), or null.
String? findLinuxBundle(String unpacked) {
  final root = Directory(unpacked);
  if (!root.existsSync()) return null;
  final tops = root.listSync().whereType<Directory>().toList();
  if (tops.length != 1) return null;
  final bundle = '${tops.single.path}/bundle';
  return File('$bundle/$kExeName').existsSync() ? bundle : null;
}

/// The arguments the helper gave this start (null when none).
class UpdateStart {
  const UpdateStart({this.marker, this.updatedFrom, this.failed});

  final String? marker;
  final String? updatedFrom;
  final String? failed;

  static UpdateStart parse(List<String> args) {
    String? arg(String prefix) {
      for (final a in args) {
        if (a.startsWith(prefix)) {
          final v = a.substring(prefix.length);
          return v.isEmpty ? null : v;
        }
      }
      return null;
    }

    return UpdateStart(
      marker: arg(kMarkerArg),
      updatedFrom: arg(kUpdatedFromArg),
      failed: arg(kUpdateFailedArg),
    );
  }
}

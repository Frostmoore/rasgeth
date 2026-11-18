// The replacement (G41.8b): a small helper outside the app's folder, started detached just before
// the app closes. It waits for the app to be gone, keeps the folder as it was (`<dir>.previous`),
// puts the new version in (Windows: the downloaded RGCompanion-Setup.exe, silent, for this user,
// no administrator; Linux: the bundle of the downloaded archive, in install-app.sh's folder), then
// starts it with a marker file to write. A new version that does not write it within a minute (or
// stops first) is taken away: the old folder comes back and the old version starts again, told
// which one failed. Every step goes into the helper's log next to it.
import 'dart:io';

import 'brand.dart';

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
say "update \$from -> \$to: waiting for the app (\$pid) to close"
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
\$waitS = ${p.waitSeconds}
\$prev = "\$dest.previous"
function Say(\$t) { Add-Content -LiteralPath \$log -Value ("{0:yyyy-MM-dd HH:mm:ss} {1}" -f (Get-Date), \$t) }
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
Say "update \$from -> \$to: waiting for the app (\$appPid) to close"
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

/// Writes the helper next to the download and starts it detached; the caller closes the app.
Future<void> startSwap(SwapPlan p, String folder) async {
  if (p.system == 'windows') {
    final script = File('$folder\\swap.ps1');
    // A BOM: Windows PowerShell 5.1 reads a file without one in the system's code page.
    await script.writeAsString('﻿${windowsSwapScript(p)}');
    await Process.start('powershell.exe', [
      '-NoProfile',
      '-NonInteractive',
      '-ExecutionPolicy',
      'Bypass',
      '-WindowStyle',
      'Hidden',
      '-File',
      script.path,
    ], mode: ProcessStartMode.detached);
  } else {
    final script = File('$folder/swap.sh');
    await script.writeAsString(linuxSwapScript(p));
    await Process.start('/bin/sh', [script.path], mode: ProcessStartMode.detached);
  }
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

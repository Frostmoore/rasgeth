// 3.9.5: the update's helper must really run. 3.9.0-3.9.4's Windows helper never did: its first
// line held `$to:`, which PowerShell reads as a drive-qualified variable, so the whole file failed
// to parse and nothing ran (hidden window, detached: nobody saw it; the app had already closed).
// Here: the script's text has no such reference (table of the scopes PowerShell allows), Windows
// PowerShell 5.1's own parser finds no error (on Windows), the handshake (the app writes its line,
// closes only once the helper wrote its first line and its `alive` file, stays open otherwise) and, on Windows, the
// helper run for real on fake folders: replaced and started, put back when the new version does not
// start or the installer fails.
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:rgcompanion/app_update/swap.dart';

const _plan = SwapPlan(
  system: 'windows',
  pid: 7,
  dir: r"C:\Users\O'Brien Ü\AppData\Local\Programs\Rasgeth App",
  exe: r"C:\Users\O'Brien Ü\AppData\Local\Programs\Rasgeth App\rasgeth-app.exe",
  fromVersion: '3.9.0',
  toVersion: '3.9.3',
  package:
      r"C:\Users\O'Brien Ü\AppData\Roaming\Rasgeth\Rasgeth\app-update\3.9.3\Rasgeth-App-Setup.exe",
  marker: r"C:\Users\O'Brien Ü\AppData\Roaming\Rasgeth\Rasgeth\app-update\started-3.9.3",
  log: r"C:\Users\O'Brien Ü\AppData\Roaming\Rasgeth\Rasgeth\app-update\update.log",
  alive: r"C:\Users\O'Brien Ü\AppData\Roaming\Rasgeth\Rasgeth\app-update\helper-alive",
);

/// The scopes and drives PowerShell allows right after `$name:` (anything else breaks the file).
const _allowedScopes = {'env', 'global', 'local', 'private', 'script', 'using'};

String get _ps => windowsPowerShell(Platform.environment);

Future<void> _waitFor(bool Function() ok, {int seconds = 30}) async {
  for (var i = 0; i < seconds * 10 && !ok(); i++) {
    await Future<void>.delayed(const Duration(milliseconds: 100));
  }
}

String _read(String path) => File(path).existsSync() ? File(path).readAsStringSync() : '';

Future<void> _rmRetry(Directory d) async {
  for (var i = 0; i < 50; i++) {
    try {
      if (d.existsSync()) d.deleteSync(recursive: true);
      return;
    } on FileSystemException {
      // A fake app may still hold its folder for a moment (Windows).
      await Future<void>.delayed(const Duration(milliseconds: 200));
    }
  }
}

/// A process that lives [ms] milliseconds: the "app" the helper waits for.
Future<Process> _running(int ms) => Platform.isWindows
    ? Process.start(_ps, ['-NoProfile', '-Command', 'Start-Sleep -Milliseconds $ms'])
    : Process.start('sleep', ['${ms / 1000}']);

void main() {
  test('the Windows helper has no `\$name:` PowerShell would read as a drive (table)', () {
    final s = windowsSwapScript(_plan);
    final bad = RegExp(r'\$([A-Za-z_][A-Za-z0-9_]*):')
        .allMatches(s)
        .map((m) => m.group(1)!)
        .where((n) => !_allowedScopes.contains(n.toLowerCase()))
        .toList();
    expect(bad, isEmpty, reason: 'use \${name} before a colon');
    // The table itself: the 3.9.0 line is caught, the scopes are not.
    bool caught(String line) =>
        RegExp(r'\$([A-Za-z_][A-Za-z0-9_]*):')
            .allMatches(line)
            .any((m) => !_allowedScopes.contains(m.group(1)!.toLowerCase()));
    expect(caught(r'Say "update $from -> $to: waiting"'), isTrue);
    expect(caught(r'Say "update ${from} -> ${to}: waiting"'), isFalse);
    expect(caught(r'$env:SystemRoot'), isFalse);
    expect(caught(r'"$($why): going back"'), isFalse);
  });

  test('the helpers write their alive file right after their first line', () {
    final w = windowsSwapScript(_plan);
    final alive = w.indexOf(r'Set-Content -LiteralPath $alive');
    expect(w.indexOf(r'Say "helper'), lessThan(alive));
    expect(alive, lessThan(w.indexOf('Get-Process -Id')));
    final l = linuxSwapScript(
      const SwapPlan(
        system: 'linux',
        pid: 7,
        dir: '/d',
        exe: '/d/x',
        fromVersion: '3.9.0',
        toVersion: '3.9.3',
        package: '/p',
        marker: '/m',
        log: '/l',
        alive: "/it's/alive",
      ),
    );
    expect(l, contains(r": >'/it'\''s/alive'"));
    expect(l.indexOf('say "helper'), lessThan(l.indexOf(': >')));
    expect(l.indexOf(': >'), lessThan(l.indexOf('while kill -0')));
  });

  test('Windows PowerShell 5.1 by its full path', () {
    expect(
      windowsPowerShell({'SystemRoot': r'D:\Win'}),
      r'D:\Win\System32\WindowsPowerShell\v1.0\powershell.exe',
    );
    expect(windowsPowerShell({}), r'C:\Windows\System32\WindowsPowerShell\v1.0\powershell.exe');
  });

  test(
    'Windows PowerShell 5.1 parses the helper without errors',
    skip: !Platform.isWindows,
    () async {
      final tmp = Directory.systemTemp.createTempSync('g395-parse-');
      addTearDown(() => _rmRetry(tmp));
      final f = File('${tmp.path}\\swap.ps1')
        ..writeAsStringSync('\uFEFF${windowsSwapScript(_plan)}');
      final check = File('${tmp.path}\\check.ps1')
        ..writeAsStringSync(r'''
param($f)
$t = $null; $e = $null
[void][System.Management.Automation.Language.Parser]::ParseFile($f, [ref]$t, [ref]$e)
"$($PSVersionTable.PSVersion.Major) $($e.Count)"
$e | ForEach-Object { "line $($_.Extent.StartLineNumber): $($_.Message)" }
''');
      final r = await Process.run(_ps, [
        '-NoProfile',
        '-ExecutionPolicy',
        'Bypass',
        '-File',
        check.path,
        f.path,
      ]);
      expect(r.exitCode, 0, reason: '${r.stderr}');
      final out = '${r.stdout}'.trim();
      expect(out.split('\n').first.trim(), '5 0', reason: out);
    },
  );

  group('the handshake', () {
    late Directory tmp;
    setUp(() => tmp = Directory.systemTemp.createTempSync('g395-hand-'));
    tearDown(() => _rmRetry(tmp));

    SwapPlan plan(int pid) {
      final sep = Platform.pathSeparator;
      return SwapPlan(
        system: Platform.isWindows ? 'windows' : 'linux',
        pid: pid,
        dir: '${tmp.path}${sep}app',
        exe: '${tmp.path}${sep}app${sep}missing-app',
        fromVersion: '3.9.0',
        toVersion: '3.9.3',
        package: '${tmp.path}${sep}missing-package',
        marker: '${tmp.path}${sep}started',
        log: '${tmp.path}${sep}update.log',
        alive: '${tmp.path}${sep}helper-alive',
        waitSeconds: 2,
      );
    }

    test('the real helper: the app writes its line, returns once the helper runs', () async {
      final app = await _running(1500);
      final p = plan(app.pid);
      final folder = tmp.path;
      await startSwap(p, folder);
      expect(File(p.alive).existsSync(), isTrue);
      final log = _read(p.log);
      expect(log, contains('app 3.9.0: starting the helper for 3.9.3'));
      expect(log, contains('the app closes'));
      // The helper goes on by itself: the app gone, no package, nothing changed.
      await _waitFor(() => _read(p.log).contains('nothing changed'));
      final all = _read(p.log);
      expect(all, contains('helper '));
      expect(all, contains('update 3.9.0 -> 3.9.3, waiting for the app (${app.pid}) to close'));
      expect(all, contains('nothing changed'));
      expect(
        all.indexOf('app 3.9.0: starting the helper'),
        lessThan(all.indexOf('waiting for the app')),
      );
      expect(all.indexOf('waiting for the app'), lessThan(all.indexOf('the app closes')));
    });

    test('a helper that never writes its file: stopped, the app stays open', () async {
      final p = plan(pid);
      int? started;
      Process? quiet;
      final w = Stopwatch()..start();
      await expectLater(
        startSwap(
          p,
          tmp.path,
          aliveWithin: const Duration(seconds: 1),
          launch: (exe, args) async {
            quiet = await _running(20000);
            return started = quiet!.pid;
          },
        ),
        throwsA(isA<SwapNotStarted>()),
      );
      expect(w.elapsed, lessThan(const Duration(seconds: 10)));
      expect(await quiet!.exitCode.timeout(const Duration(seconds: 10)), isNot(0));
      expect(
        _read(p.log),
        contains('the helper ($started) did not start within 1 s: the app stays open'),
      );
    });

    test('a helper that cannot be started: the app stays open, the reason logged', () async {
      final p = plan(pid);
      await expectLater(
        startSwap(
          p,
          tmp.path,
          launch: (exe, args) async => throw const ProcessException('x', [], 'gone'),
        ),
        throwsA(isA<SwapNotStarted>()),
      );
      expect(_read(p.log), contains('app 3.9.0: the helper could not start'));
    });

    test('an old alive file never lets the app close early', () async {
      final p = plan(pid);
      File(p.alive).writeAsStringSync('old');
      await expectLater(
        startSwap(
          p,
          tmp.path,
          aliveWithin: const Duration(seconds: 1),
          launch: (exe, args) async {
            final q = await _running(5000);
            return q.pid;
          },
        ),
        throwsA(isA<SwapNotStarted>()),
      );
    });
  });

  group('the Windows helper, run for real on fake folders', skip: !Platform.isWindows, () {
    late Directory tmp;
    setUp(() => tmp = Directory.systemTemp.createTempSync('g395-win-'));
    tearDown(() => _rmRetry(tmp));

    // A fake app (app.cmd + app.ps1): writes its name and command line into out.txt; the good one
    // writes the marker and stays a moment, the bad one stops at once.
    void fakeApp(String dir, String name) {
      Directory(dir).createSync(recursive: true);
      File('$dir\\version.txt').writeAsStringSync(name);
      File('$dir\\app.cmd').writeAsStringSync(
        '@echo off\r\nset "RGARGS=%*"\r\n"$_ps" -NoProfile -ExecutionPolicy Bypass -File "%~dp0app.ps1"\r\n'
        'exit /b %ERRORLEVEL%\r\n',
      );
      File('$dir\\app.ps1').writeAsStringSync('''
\$name = (Get-Content -LiteralPath (Join-Path \$PSScriptRoot 'version.txt')).Trim()
Add-Content -LiteralPath '${tmp.path}\\out.txt' -Value ("\$name " + \$env:RGARGS)
if (\$name -eq 'bad') { exit 1 }
if (\$env:RGARGS -match '$kMarkerArg"?([^"]+)"?') { Set-Content -LiteralPath \$Matches[1].Trim() -Value ok }
Start-Sleep -Seconds 2
''');
    }

    Future<(int, String, String)> run({String newApp = 'new', int setupExit = 0}) async {
      final dest = '${tmp.path}\\Rasgeth App';
      fakeApp(dest, 'old');
      fakeApp('${tmp.path}\\new', newApp);
      File('${tmp.path}\\setup.cmd').writeAsStringSync(
        '@echo off\r\nxcopy /E /I /Y /Q "${tmp.path}\\new" "$dest" >nul\r\nexit /b $setupExit\r\n',
      );
      final running = await _running(800);
      final plan = SwapPlan(
        system: 'windows',
        pid: running.pid,
        dir: dest,
        exe: '$dest\\app.cmd',
        fromVersion: '3.9.0',
        toVersion: '3.9.3',
        package: '${tmp.path}\\setup.cmd',
        marker: '${tmp.path}\\started-3.9.3',
        log: '${tmp.path}\\update.log',
        alive: '${tmp.path}\\helper-alive',
        waitSeconds: 20,
      );
      File('${tmp.path}\\swap.ps1').writeAsStringSync('\uFEFF${windowsSwapScript(plan)}');
      final r = await Process.run(_ps, [
        '-NoProfile',
        '-NonInteractive',
        '-ExecutionPolicy',
        'Bypass',
        '-File',
        '${tmp.path}\\swap.ps1',
      ]);
      final out = '${tmp.path}\\out.txt';
      final want = r.exitCode == 0 ? 'new ' : 'old ';
      await _waitFor(() => _read(out).contains(want), seconds: 20);
      await Future<void>.delayed(const Duration(milliseconds: 300));
      return (r.exitCode, _read(out), _read('${tmp.path}\\update.log'));
    }

    test('replaced, the new version started with its marker, the old folder gone', () async {
      final (code, out, log) = await run();
      final dest = '${tmp.path}\\Rasgeth App';
      expect(code, 0, reason: log);
      expect(File('$dest\\version.txt').readAsStringSync(), 'new');
      expect(Directory('$dest.previous').existsSync(), isFalse);
      expect(out, contains('new $kMarkerArg"${tmp.path}\\started-3.9.3" ${kUpdatedFromArg}3.9.0'));
      expect(File('${tmp.path}\\helper-alive').existsSync(), isTrue);
      expect(log, contains('3.9.3 started: done'));
    });

    test('the new version does not start: the old folder back, the old version told', () async {
      final (code, out, log) = await run(newApp: 'bad');
      final dest = '${tmp.path}\\Rasgeth App';
      expect(code, 2, reason: log);
      expect(File('$dest\\version.txt').readAsStringSync(), 'old');
      expect(Directory('$dest.previous').existsSync(), isFalse);
      expect(out, contains('old ${kUpdateFailedArg}3.9.3'));
      expect(log, contains('3.9.3 did not start: going back to 3.9.0'));
    });

    test('the installer fails: the old folder back, the old version told', () async {
      final (code, out, log) = await run(setupExit: 3);
      final dest = '${tmp.path}\\Rasgeth App';
      expect(code, 2, reason: log);
      expect(File('$dest\\version.txt').readAsStringSync(), 'old');
      expect(out, contains('old ${kUpdateFailedArg}3.9.3'));
      expect(log, contains('the installer stopped with 3: going back to 3.9.0'));
    });
  });
}

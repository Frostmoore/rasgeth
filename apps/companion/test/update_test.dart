// The update's screen (the person, from the phone: «va fatto bene, non questa monnezza»): the
// steps' rules as tables, the follower against scripted answers, and the screen against the fake
// RedGiant as a 3.8.0 server (a state and a step only) and as a 3.8.1 one (its run, with the
// bar), through the restart (the server stops answering, then comes back as the new version and
// the app reconnects by itself, HTTP and the live socket), a failure and a going back.
import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rgcompanion/api/client.dart';
import 'package:rgcompanion/api/live.dart';
import 'package:rgcompanion/api/servers.dart';
import 'package:rgcompanion/api/settings_types.dart';
import 'package:rgcompanion/api/token_store.dart';
import 'package:rgcompanion/api/types.dart';
import 'package:rgcompanion/api/update_follower.dart';
import 'package:rgcompanion/api/update_run.dart';
import 'package:rgcompanion/app.dart';
import 'package:rgcompanion/app_state.dart';

import 'fake_server.dart';

const _mb = 1024.0 * 1024;

/// RedGiant OS's updater as `GET /api/setup/os-updates` says it.
Map<String, dynamic> osJson({
  bool running = false,
  String state = 'available',
  String installed = '3.8.0',
  String? step,
  Map<String, dynamic>? run,
}) => {
  'available': true,
  'running': running,
  'update': {
    'state': state,
    'installed': installed,
    'latest': '3.8.1',
    'gate': 'normal',
    'note': null,
    'step': step,
    'checkedAt': '2026-11-16T09:00:00.000Z',
    'run': ?run,
  },
  'security': null,
};

/// 3.8.1's run: the steps it began, the plan, the download now.
Map<String, dynamic> run381(
  List<String> began, {
  Map<String, dynamic>? progress,
  String? reason,
  String? finishedAt,
}) => {
  'from': '3.8.0',
  'startedAt': '2026-11-16T10:00:00.000Z',
  'finishedAt': finishedAt,
  'reason': reason,
  'steps': ['check', 'download', 'files', 'install', 'restart', 'wait'],
  'stepAt': {for (final (i, s) in began.indexed) s: '2026-11-16T10:0$i:00.000Z'},
  'plan': {
    'images': [
      {'name': 'redgiant', 'ref': 'ghcr.io/redgiant:3.8.1', 'bytes': 340 * _mb, 'here': false},
      {'name': 'postgres', 'ref': 'postgres:17', 'bytes': 120 * _mb, 'here': true},
    ],
    'files': {'name': 'system.tar.zst', 'bytes': 18 * _mb},
  },
  'progress': progress,
};

Map<String, dynamic> windowsStatus({String installed = '3.8.0', Map<String, dynamic>? progress}) =>
    {
      'install': 'windows',
      'installed': installed,
      'latest': '3.8.1',
      'checkedAt': '2026-11-16T09:00:00.000Z',
      'state': installed == '3.8.1' ? 'latest' : 'available',
      'gate': 'normal',
      'signed': true,
      'note': {'it': 'Aggiornamenti spiegati passo per passo.', 'en': 'Updates explained.'},
      'downloadUrl': null,
      'command': null,
      'backupDir': null,
      'canUpdateHere': true,
      'canUninstall': true,
      'progress': ?progress,
    };

Map<String, dynamic> launcherProgress(
  String phase, {
  double done = 0,
  double total = 0,
  double bps = 0,
  int? eta,
}) => {
  'version': '3.8.1',
  'phase': phase,
  'done': done,
  'total': total,
  'bps': bps,
  'eta': eta,
  'at': '2026-11-16T10:00:00.000Z',
};

/// Scripted answers for the follower alone: a status, RedGiant OS's state, or nothing (down).
class ScriptSource implements UpdateSource {
  Map<String, dynamic>? statusJson = windowsStatus();
  Map<String, dynamic>? osJsonNow;
  bool down = false;
  int starts = 0;
  ApiException? refuse;

  @override
  Future<UpdateStatus> status() async {
    if (down) throw const ApiException(0, 'Connection refused');
    return UpdateStatus.fromJson(statusJson!);
  }

  @override
  Future<OsUpdates?> os() async {
    if (down) throw const ApiException(0, 'Connection refused');
    final o = osJsonNow;
    return o == null ? null : OsUpdates.fromJson(o);
  }

  @override
  Future<void> start() async {
    starts++;
    final r = refuse;
    if (r != null) throw r;
  }
}

UpdateFollower _follower(ScriptSource s, {Future<void> Function()? onBack}) => UpdateFollower(
  source: s,
  from: '3.8.0',
  to: '3.8.1',
  every: const Duration(days: 1),
  grace: 2,
  backLimit: 3,
  onBack: onBack,
);

AppController _app({DevicePlatform platform = DevicePlatform.android, bool live = false}) =>
    AppController(
        tokens: MemoryTokenStore(),
        prefs: MemoryAppPrefs(),
        platform: platform,
        liveEnabled: live,
      )
      ..locale = const Locale('it')
      ..reduceMotion = true
      ..updateEvery = const Duration(seconds: 1);

Future<void> _pump(
  WidgetTester t,
  AppController app, {
  Size size = const Size(1080, 2340),
  double dpr = 3,
}) async {
  t.view.physicalSize = size;
  t.view.devicePixelRatio = dpr;
  addTearDown(t.view.reset);
  await t.pumpWidget(RGCompanionApp(controller: app));
  await _io(t);
}

/// Real time for the requests, then the frames (never pumpAndSettle: the bars move).
Future<void> _io(WidgetTester t, [int rounds = 12]) async {
  for (var i = 0; i < rounds; i++) {
    await t.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 25)));
    await t.pump(const Duration(milliseconds: 50));
  }
}

/// One look of the follower (a second of the fake clock) with its request.
Future<void> _tick(WidgetTester t, [int n = 1]) async {
  for (var i = 0; i < n; i++) {
    await t.pump(const Duration(seconds: 1));
    await _io(t, 8);
  }
}

Future<void> _openSettings(WidgetTester t) async {
  await t.tap(find.byKey(const Key('tab-you')));
  await _io(t, 4);
  await t.tap(find.byKey(const Key('open-server-settings')));
  await _io(t);
}

Future<void> _end(WidgetTester t, AppController app) async {
  app.updateRun?.dispose();
  app.updateRun = null;
  await t.pumpWidget(const SizedBox());
  // The HTTP client's idle connections close after 15 s of the fake clock.
  await t.pump(const Duration(seconds: 20));
}

Finder _stepNow(String id) =>
    find.descendant(of: find.byKey(Key('update-step-$id')), matching: find.text('in corso'));

Finder _stepDone(String id) =>
    find.descendant(of: find.byKey(Key('update-step-$id')), matching: find.text('fatto'));

void main() {
  group('rules', () {
    test('RedGiant OS before 3.8.1: the steps from the state and the step', () {
      String marks(List<RunStep> s) => s.map((x) => '$x').join(' ');
      final applying = OsUpdates.fromJson(
        osJson(running: true, state: 'applying', step: 'download'),
      );
      expect(
        marks(osSteps(applying)),
        'check:done download:now files:todo install:todo restart:todo wait:todo',
      );
      // «files» was the install too before 3.8.1.
      final files = OsUpdates.fromJson(osJson(running: true, state: 'applying', step: 'files'));
      expect(osSteps(files).firstWhere((s) => s.mark == StepMark.now).id, 'install');
      // The server went away while it followed: the restart.
      expect(
        osSteps(applying, restarting: true).firstWhere((s) => s.mark == StepMark.now).id,
        'restart',
      );
      final done = OsUpdates.fromJson(
        osJson(
          state: 'latest',
          installed: '3.8.1',
          run: run381(['check'], finishedAt: 'x'),
        ),
      );
      expect(osSteps(done).every((s) => s.mark == StepMark.done), isTrue);
    });

    test('a stop: the last step begun failed, the rollback went through; why in words', () {
      final os = OsUpdates.fromJson(
        osJson(
          state: 'error',
          run: run381([
            'check',
            'download',
            'files',
            'install',
            'restart',
            'wait',
            'rollback',
          ], reason: 'not_up'),
        ),
      );
      final s = {for (final x in osSteps(os)) x.id: x.mark};
      expect(s['install'], StepMark.done);
      expect(s['wait'], StepMark.failed);
      expect(osWhy(os), 'not_up');
      expect(osWhy(OsUpdates.fromJson(osJson(state: 'error'))), 'other');
      // A look that failed is not an update that failed.
      expect(osWhy(OsUpdates.fromJson(osJson(state: 'unreachable'))), isNull);
    });

    test("RedGiant.exe's steps: from its phases, else download, restart, wait", () {
      String marks(List<RunStep> s) => s.map((x) => '$x').join(' ');
      expect(marks(launcherSteps(seen: {})), 'download:now restart:todo wait:todo');
      expect(
        marks(launcherSteps(seen: {}, restarting: true)),
        'download:done restart:now wait:todo',
      );
      expect(
        marks(launcherSteps(seen: {'scan', 'download'}, phase: 'download')),
        'scan:done download:now build:todo restart:todo wait:todo',
      );
      expect(
        marks(launcherSteps(seen: {'installer'}, phase: 'installer')),
        'installer:now restart:todo wait:todo',
      );
      expect(
        marks(launcherSteps(seen: {'scan', 'download'}, phase: 'failed')),
        'scan:done download:failed build:todo restart:todo wait:todo',
      );
    });

    test('the time left: the download by its speed, the rest by what it usually takes', () {
      final now = DateTime.utc(2026, 11, 16, 10);
      final steps = osSteps(
        OsUpdates.fromJson(osJson(running: true, state: 'applying', step: 'download')),
      );
      const p = Progress(done: 100, total: 400, bps: 10, eta: 30);
      // 30 s of images and the files' 100 bytes at 10 B/s; install, restart and check as usual.
      expect(secondsLeft(steps, progress: p, now: now, filesBytes: 100), 30 + 10 + 10 + 45 + 45);
      expect(secondsLeft(steps, now: now), isNull);
      expect(clock(const Duration(seconds: 7)), '0:07');
      expect(clock(const Duration(minutes: 64, seconds: 5)), '1:04:05');
      expect(roundMinutes(30), isNull);
      expect(roundMinutes(3900), (1, 5));
    });
  });

  group('the follower', () {
    test(
      '3.8.0 RedGiant OS: steps from the step, the restart counted, back as the new version',
      () async {
        final s = ScriptSource()
          ..statusJson = {...windowsStatus(), 'install': 'os'}
          ..osJsonNow = osJson(running: true, state: 'applying', step: 'download');
        var back = 0;
        final f = _follower(s, onBack: () async => back++);
        await f.begin();
        expect(s.starts, 1);
        await f.poll();
        expect(f.stage, UpdateStage.running);
        expect(f.detailed, isFalse);
        expect(f.progress, isNull);
        s.down = true;
        await f.poll();
        await f.poll();
        expect(f.stage, UpdateStage.restarting);
        expect(f.attempts, 2);
        expect(f.steps.firstWhere((x) => x.mark == StepMark.now).id, 'restart');
        s
          ..down = false
          ..osJsonNow = osJson(state: 'latest', installed: '3.8.1');
        await f.poll();
        expect(f.stage, UpdateStage.done);
        expect(f.doneVersion, '3.8.1');
        await Future<void>.delayed(Duration.zero);
        expect(back, 1);
        expect(f.reconnected, isTrue);
        f.dispose();
      },
    );

    test('3.8.1 RedGiant OS: the run, its bar and the time left', () async {
      final s = ScriptSource()
        ..statusJson = {...windowsStatus(), 'install': 'os'}
        ..osJsonNow = osJson(
          running: true,
          state: 'applying',
          step: 'download',
          run: run381(
            ['check', 'download'],
            progress: {
              'done': 85 * _mb,
              'total': 340 * _mb,
              'bps': 4 * _mb,
              'eta': 64,
              'items': [],
            },
          ),
        );
      final f = _follower(s);
      f.follow();
      await f.poll();
      expect(f.detailed, isTrue);
      expect(f.progress!.fraction, .25);
      expect(f.left, greaterThan(64));
      expect(f.totalBytes, 340 * _mb + 18 * _mb);
      f.dispose();
    });

    test(
      '3.8.0 Windows says nothing while it updates: waited for, done when it comes back',
      () async {
        final s = ScriptSource()..statusJson = windowsStatus();
        final f = _follower(s);
        await f.begin();
        for (var i = 0; i < 5; i++) {
          await f.poll();
        }
        expect(f.stage, UpdateStage.running);
        expect(f.steps.map((x) => '$x'), ['download:now', 'restart:todo', 'wait:todo']);
        s.down = true;
        await f.poll();
        s
          ..down = false
          ..statusJson = windowsStatus(installed: '3.8.1');
        await f.poll();
        expect(f.stage, UpdateStage.done);
        f.dispose();
      },
    );

    test(
      '3.8.1 Windows: its phases; «restart» still said after it does not hold it back',
      () async {
        final s = ScriptSource()
          ..statusJson = windowsStatus(
            progress: launcherProgress('download', done: 2 * _mb, total: 8 * _mb, bps: _mb, eta: 6),
          );
        final f = _follower(s);
        await f.begin();
        await f.poll();
        expect(f.steps.map((x) => '$x'), [
          'scan:done',
          'download:now',
          'build:todo',
          'restart:todo',
          'wait:todo',
        ]);
        expect(f.progress!.fraction, .25);
        s.statusJson = windowsStatus(installed: '3.8.1', progress: launcherProgress('restart'));
        await f.poll();
        expect(f.stage, UpdateStage.done);
        f.dispose();
      },
    );

    test('a failure in words, and «Try again» asks again', () async {
      final s = ScriptSource()
        ..statusJson = {...windowsStatus(), 'install': 'os'}
        ..osJsonNow = osJson(
          running: true,
          state: 'applying',
          step: 'download',
          run: run381(['check', 'download']),
        );
      final f = _follower(s);
      await f.begin();
      await f.poll();
      s.osJsonNow = osJson(
        state: 'error',
        run: run381(['check', 'download'], reason: 'download'),
      );
      await f.poll();
      expect(f.stage, UpdateStage.failed);
      expect(f.why, 'download');
      expect(f.canRetry, isTrue);
      expect(f.steps.firstWhere((x) => x.mark == StepMark.failed).id, 'download');
      await f.retry();
      expect(s.starts, 2);
      expect(f.stage, UpdateStage.starting);
      f.dispose();
    });

    test('back as the old version: the new one did not start (gone back)', () async {
      final s = ScriptSource()..statusJson = windowsStatus(progress: launcherProgress('build'));
      final f = _follower(s);
      await f.begin();
      await f.poll();
      s.down = true;
      await f.poll();
      s
        ..down = false
        ..statusJson = windowsStatus();
      await f.poll();
      expect(f.stage, UpdateStage.running);
      expect(f.steps.firstWhere((x) => x.mark == StepMark.now).id, 'wait');
      await f.poll();
      await f.poll();
      expect(f.stage, UpdateStage.failed);
      expect(f.why, 'not_up');
      f.dispose();
    });

    test('a request refused: said with the server\'s words', () async {
      final s = ScriptSource()
        ..refuse = const ApiException(400, 'This installation cannot do that');
      final f = _follower(s);
      await f.begin();
      expect(f.stage, UpdateStage.failed);
      expect(f.why, 'start');
      expect(f.error, 'This installation cannot do that');
      f.dispose();
    });
  });

  group('the app reconnects by itself', () {
    late FakeRedGiant server;
    setUp(() async {
      HttpOverrides.global = null;
      server = await FakeRedGiant.start();
    });
    tearDown(() => server.close());

    test('HTTP and the live socket, as soon as RedGiant answers as the new version', () async {
      final app = AppController(
        tokens: MemoryTokenStore(),
        prefs: MemoryAppPrefs(),
        platform: DevicePlatform.android,
      )..updateEvery = const Duration(milliseconds: 40);
      server.osUpdates = osJson();
      server.onUpdateAct = () {
        server.osUpdates = osJson(running: true, state: 'applying', step: 'check');
        return null;
      };
      expect(await app.connect(server.base.toString(), 'secret'), isTrue);
      await _until(() => app.socket?.status == LiveStatus.open);
      unawaited(app.startUpdate(from: '3.8.0', to: '3.8.1'));
      await _until(() => app.updateRun?.stage == UpdateStage.running);
      await server.goDown();
      await _until(
        () => app.updateRun!.stage == UpdateStage.restarting && app.updateRun!.attempts >= 2,
      );
      expect(app.socket!.status, isNot(LiveStatus.open));
      server
        ..version = '3.8.1'
        ..osUpdates = osJson(state: 'latest', installed: '3.8.1')
        ..down = false;
      await _until(() => app.updateRun!.reconnected);
      expect(app.updateRun!.stage, UpdateStage.done);
      expect(app.hello!.version, '3.8.1');
      expect(app.socket!.status, LiveStatus.open);
      expect(app.socket!.serverVersion, '3.8.1');
      await app.disconnect();
    });
  });

  group('the screen', () {
    late FakeRedGiant server;
    setUp(() async {
      HttpOverrides.global = null;
      server = await FakeRedGiant.start();
    });
    tearDown(() => server.close());

    testWidgets(
      'a 3.8.0 server: steps from the state, a bar that moves with the time, the restart, back',
      (t) async {
        final app = _app();
        server.osUpdates = osJson();
        server.onUpdateAct = () {
          server.osUpdates = osJson(running: true, state: 'applying', step: 'check');
          return null;
        };
        await t.runAsync(() => app.connect(server.base.toString(), 'secret'));
        await _pump(t, app);
        await _openSettings(t);
        expect(find.text('È disponibile la versione 3.8.1'), findsOneWidget);
        await t.ensureVisible(find.byKey(const Key('update-now')));
        await t.pump();
        await t.tap(find.byKey(const Key('update-now')));
        await _io(t, 4);
        // The confirmation says only what happens.
        expect(find.textContaining('Ti mostro ogni passo e mi ricollego da solo'), findsOneWidget);
        expect(find.textContaining('chiude'), findsNothing);
        await t.tap(find.byKey(const Key('dialog-yes')));
        await _io(t);
        expect(server.updateActs, 1);
        expect(find.byKey(const Key('update-screen')), findsOneWidget);
        expect(find.text('Aggiorno RedGiant dalla 3.8.0 alla 3.8.1'), findsOneWidget);
        await _tick(t);
        expect(_stepNow('check'), findsOneWidget);
        server.osUpdates = osJson(running: true, state: 'applying', step: 'download');
        await _tick(t);
        expect(_stepDone('check'), findsOneWidget);
        expect(_stepNow('download'), findsOneWidget);
        // No bytes from this server: a bar without an end and the time gone by, never still.
        expect(
          t.widget<LinearProgressIndicator>(find.byKey(const Key('update-bar'))).value,
          isNull,
        );
        final before = t.widget<Text>(find.byKey(const Key('update-bar-text'))).data;
        expect(before, startsWith('in corso da 0:'));
        await _tick(t, 2);
        expect(t.widget<Text>(find.byKey(const Key('update-bar-text'))).data, isNot(before));
        expect(find.byKey(const Key('update-older')), findsOneWidget);
        // RedGiant restarts: the screen says so with the app's tries.
        await t.runAsync(server.goDown);
        await _tick(t, 2);
        expect(find.text('RedGiant si sta riavviando, mi ricollego…'), findsOneWidget);
        expect(find.textContaining('Tentativo 2'), findsOneWidget);
        expect(_stepNow('restart'), findsOneWidget);
        // Back as the new version: the check, then done, and the app reconnected by itself.
        server
          ..version = '3.8.1'
          ..osUpdates = osJson(running: true, state: 'applying', installed: '3.8.0', step: 'wait')
          ..down = false;
        await _tick(t);
        expect(_stepNow('wait'), findsOneWidget);
        server.osUpdates = osJson(state: 'latest', installed: '3.8.1');
        await _tick(t);
        expect(find.text('Aggiornato alla 3.8.1'), findsOneWidget);
        expect(find.textContaining('Dalla 3.8.0'), findsOneWidget);
        expect(find.text("L'app si è ricollegata da sola."), findsOneWidget);
        expect(app.hello!.version, '3.8.1');
        expect(find.byKey(const Key('update-back')), findsOneWidget);
        await t.tap(find.byKey(const Key('update-back')));
        await _io(t);
        expect(find.byKey(const Key('update-screen')), findsNothing);
        await _end(t, app);
      },
    );

    testWidgets('a 3.8.1 server: its run with the real bar, the time left and the news', (t) async {
      final app = _app();
      server.update = {...server.update};
      server.osUpdates = osJson();
      server.onUpdateAct = () {
        server.osUpdates = osJson(
          running: true,
          state: 'applying',
          step: 'download',
          run: run381(
            ['check', 'download'],
            progress: {
              'done': 85 * _mb,
              'total': 340 * _mb,
              'bps': 4 * _mb,
              'eta': 64,
              'items': [
                {'name': 'redgiant', 'done': 85 * _mb, 'total': 340 * _mb, 'state': 'down'},
              ],
            },
          ),
        );
        return null;
      };
      app.updateClock = () => t.binding.clock.now();
      await t.runAsync(() => app.connect(server.base.toString(), 'secret'));
      await _pump(t, app);
      await _openSettings(t);
      await t.ensureVisible(find.byKey(const Key('update-now')));
      await t.pump();
      await t.tap(find.byKey(const Key('update-now')));
      await _io(t, 4);
      await t.tap(find.byKey(const Key('dialog-yes')));
      await _io(t);
      await _tick(t);
      expect(t.widget<LinearProgressIndicator>(find.byKey(const Key('update-bar'))).value, .25);
      expect(find.text('85.0 MB di 340 MB · 4.0 MB/s · mancano 2 min'), findsOneWidget);
      expect(find.textContaining('mancano circa'), findsOneWidget);
      // The bar says the bytes: the time gone by goes with the time left, above.
      expect(find.textContaining('in corso da'), findsOneWidget);
      expect(find.text('Il database (Postgres)'), findsOneWidget);
      expect(find.text('già qui'), findsOneWidget);
      expect(find.byKey(const Key('update-older')), findsNothing);
      await t.runAsync(server.goDown);
      await _tick(t);
      server
        ..version = '3.8.1'
        ..osUpdates = osJson(
          state: 'latest',
          installed: '3.8.1',
          run: run381([
            'check',
            'download',
            'files',
            'install',
            'restart',
            'wait',
          ], finishedAt: '2026-11-16T10:04:30.000Z'),
        )
        ..down = false;
      await _tick(t);
      expect(find.text('Aggiornato alla 3.8.1'), findsOneWidget);
      expect(
        find.text('Dalla 3.8.0, in 5 min. Conversazioni, agenti e impostazioni sono come prima.'),
        findsOneWidget,
      );
      expect(find.byKey(const Key('update-news')), findsOneWidget);
      expect(find.text('Aggiornamenti spiegati passo per passo.'), findsOneWidget);
      await _end(t, app);
    });

    testWidgets('a failure and the going back: in plain words, with «Riprova»', (t) async {
      final app = _app();
      server.osUpdates = osJson();
      server.onUpdateAct = () {
        server.osUpdates = osJson(
          running: true,
          state: 'applying',
          step: 'install',
          run: run381(['check', 'download', 'files', 'install']),
        );
        return null;
      };
      app.updateClock = () => t.binding.clock.now();
      await t.runAsync(() => app.connect(server.base.toString(), 'secret'));
      await _pump(t, app);
      await _openSettings(t);
      await t.ensureVisible(find.byKey(const Key('update-now')));
      await t.pump();
      await t.tap(find.byKey(const Key('update-now')));
      await _io(t, 4);
      await t.tap(find.byKey(const Key('dialog-yes')));
      await _io(t);
      await _tick(t);
      expect(_stepNow('install'), findsOneWidget);
      // The new version did not start: the previous one comes back.
      server.osUpdates = osJson(
        running: true,
        state: 'applying',
        step: 'rollback',
        run: {
          ...run381(['check', 'download', 'files', 'install', 'restart', 'wait', 'rollback']),
          'steps': ['check', 'download', 'files', 'install', 'restart', 'wait', 'rollback'],
        },
      );
      await _tick(t);
      expect(_stepNow('rollback'), findsOneWidget);
      expect(find.textContaining('rimetto quella di prima'), findsOneWidget);
      server.osUpdates = osJson(
        state: 'error',
        run: {
          ...run381([
            'check',
            'download',
            'files',
            'install',
            'restart',
            'wait',
            'rollback',
          ], reason: 'not_up'),
          'steps': ['check', 'download', 'files', 'install', 'restart', 'wait', 'rollback'],
        },
      );
      await _tick(t);
      expect(find.text('La versione nuova non è partita.'), findsOneWidget);
      expect(find.textContaining('RedGiant è tornato da solo alla 3.8.0'), findsOneWidget);
      expect(find.text('fermo qui'), findsOneWidget);
      expect(find.byKey(const Key('update-retry')), findsOneWidget);
      server.onUpdateAct = () {
        server.osUpdates = osJson(
          running: true,
          state: 'applying',
          step: 'check',
          run: run381(['check']),
        );
        return null;
      };
      await t.tap(find.byKey(const Key('update-retry')));
      await _io(t);
      expect(server.updateActs, 2);
      await _tick(t);
      expect(find.text('Aggiorno RedGiant dalla 3.8.0 alla 3.8.1'), findsOneWidget);
      expect(_stepNow('check'), findsOneWidget);
      await _end(t, app);
    });

    testWidgets('an update found running when the app connects: its screen opens by itself', (
      t,
    ) async {
      final app = _app();
      server.osUpdates = osJson(running: true, state: 'applying', step: 'download');
      app.updateClock = () => t.binding.clock.now();
      await t.runAsync(() => app.connect(server.base.toString(), 'secret'));
      await _pump(t, app);
      expect(find.byKey(const Key('update-screen')), findsOneWidget);
      expect(_stepNow('download'), findsOneWidget);
      // Hidden, it goes on; the settings take it up again.
      await t.tap(find.byKey(const Key('update-hide')));
      await _io(t);
      expect(find.byKey(const Key('update-screen')), findsNothing);
      expect(app.updateRun!.finished, isFalse);
      await _end(t, app);
    });

    testWidgets('a computer: a window; the RedGiant of this computer is updated by its launcher', (
      t,
    ) async {
      final app = _app(platform: DevicePlatform.windows);
      server.update = windowsStatus();
      server.onUpdateAct = () {
        server.update = windowsStatus(
          progress: launcherProgress(
            'download',
            done: 12 * _mb,
            total: 48 * _mb,
            bps: 3 * _mb,
            eta: 12,
          ),
        );
        return null;
      };
      app.updateClock = () => t.binding.clock.now();
      await t.runAsync(() => app.connect(server.base.toString(), 'secret'));
      await _pump(t, app, size: const Size(1280, 800), dpr: 1);
      await _openSettings(t);
      await t.ensureVisible(find.byKey(const Key('update-now')));
      await t.pump();
      await t.tap(find.byKey(const Key('update-now')));
      await _io(t, 4);
      expect(find.textContaining('lo fa RedGiant, con la sua finestra'), findsOneWidget);
      await t.tap(find.byKey(const Key('dialog-yes')));
      await _io(t);
      await _tick(t);
      expect(find.byKey(const Key('update-window')), findsOneWidget);
      expect(find.byKey(const Key('update-local')), findsOneWidget);
      expect(_stepNow('download'), findsOneWidget);
      expect(find.text('12.0 MB di 48.0 MB · 3.0 MB/s · mancano 12 s'), findsOneWidget);
      await t.runAsync(server.goDown);
      await _tick(t);
      expect(find.text('RedGiant si sta riavviando, mi ricollego…'), findsOneWidget);
      server
        ..version = '3.8.1'
        ..update = windowsStatus(installed: '3.8.1', progress: launcherProgress('restart'))
        ..down = false;
      await _tick(t);
      expect(find.text('Aggiornato alla 3.8.1'), findsOneWidget);
      await _end(t, app);
    });
  });
}

Future<void> _until(bool Function() ok, {Duration within = const Duration(seconds: 15)}) async {
  final end = DateTime.now().add(within);
  while (!ok()) {
    if (DateTime.now().isAfter(end)) throw StateError('condition not met');
    await Future<void>.delayed(const Duration(milliseconds: 20));
  }
}

// The update's screen in the real app, every step: a fake RedGiant in this process (the tests'
// FakeRedGiant) plays a 3.8.1 RedGiant OS update (check, images with the bar, system files,
// install, restart without answers, the check, done with the news), a 3.8.0 server (no run: the
// bar that moves with the time), a stop with the going back, and on a computer this computer's
// RedGiant.exe updated by its launcher. Run by tool/linux_shots.sh:
//   RG_SCREEN=430x900 … integration_test/g382_update_shots_test.dart     (phone)
//   RG_SCREEN=1280x800 …                                                 (computer)
// RG_LOCALE=en for the English texts.
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:rgcompanion/api/servers.dart';
import 'package:rgcompanion/api/token_store.dart';
import 'package:rgcompanion/api/types.dart';
import 'package:rgcompanion/api/update_follower.dart';
import 'package:rgcompanion/app.dart';
import 'package:rgcompanion/app_state.dart';

import '../test/fake_server.dart';
import 'shots_test.dart' show frames, shot, waitFor;

final _locale = Platform.environment['RG_LOCALE'] ?? 'it';
const _mb = 1024.0 * 1024;

Map<String, dynamic> _os({
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

const _steps = ['check', 'download', 'files', 'install', 'restart', 'wait', 'rollback'];

Map<String, dynamic> _run(
  List<String> began, {
  Map<String, dynamic>? progress,
  String? reason,
  String? finishedAt,
  bool rollback = false,
}) {
  final now = DateTime.now().toUtc();
  return {
    'from': '3.8.0',
    'startedAt': now.subtract(const Duration(minutes: 1)).toIso8601String(),
    'finishedAt': finishedAt,
    'reason': reason,
    'steps': rollback ? _steps : _steps.take(6).toList(),
    'stepAt': {
      for (final s in began) s: now.subtract(const Duration(seconds: 4)).toIso8601String(),
    },
    'plan': {
      'images': [
        {'name': 'redgiant', 'ref': 'ghcr.io/redgiant:3.8.1', 'bytes': 342 * _mb, 'here': false},
        {'name': 'postgres', 'ref': 'postgres:17', 'bytes': 128 * _mb, 'here': true},
      ],
      'files': {'name': 'system.tar.zst', 'bytes': 18 * _mb},
    },
    'progress': progress,
  };
}

Map<String, dynamic> _down(double done, double total, double bps) => {
  'done': done,
  'total': total,
  'bps': bps,
  'eta': ((total - done) / bps).round(),
  'items': [
    {'name': 'redgiant', 'done': done, 'total': total, 'state': 'down'},
  ],
};

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('the update, step by step', (t) async {
    final phone = t.view.physicalSize.width / t.view.devicePixelRatio < 600;
    if (phone) debugDefaultTargetPlatformOverride = TargetPlatform.android;
    final server = await FakeRedGiant.start();
    final p = 'g382-update-${phone ? 'telefono' : 'computer'}-$_locale';
    final app = AppController(
      tokens: MemoryTokenStore(),
      prefs: MemoryAppPrefs(),
      platform: phone ? DevicePlatform.android : DevicePlatform.linux,
    )..locale = Locale(_locale);
    server.osUpdates = _os();
    await t.pumpWidget(RGCompanionApp(controller: app));
    await frames(t);
    await app.connect(server.base.toString(), 'secret');
    await frames(t, 1500);

    Future<void> openSettings() async {
      await t.tap(find.byKey(const Key('tab-you')));
      await frames(t);
      await t.tap(find.byKey(const Key('open-server-settings')));
      await frames(t, 1500);
    }

    Future<void> reopen() async {
      await t.tap(find.byKey(const Key('settings-back')));
      await frames(t, 900);
      await t.tap(find.byKey(const Key('open-server-settings')));
      await frames(t, 1500);
    }

    Future<void> update() async {
      await t.ensureVisible(find.byKey(const Key('update-now')));
      await frames(t, 400);
      await t.tap(find.byKey(const Key('update-now')));
      await frames(t, 900);
    }

    Future<void> stage(UpdateStage s) => waitFor(t, () => app.updateRun?.stage == s);

    // ---- a 3.8.1 RedGiant OS, every step ----
    await openSettings();
    await shot(t, '$p-01-disponibile');
    // A notice over the cards, with room around it.
    await t.ensureVisible(find.byKey(const Key('push-test')));
    await frames(t, 400);
    await t.tap(find.byKey(const Key('push-test')));
    await frames(t, 900);
    await t.drag(find.byKey(const Key('server-settings')), const Offset(0, 1600));
    await frames(t, 2500);
    await shot(t, '$p-01b-avviso');
    server.onUpdateAct = () {
      server.osUpdates = _os(running: true, state: 'applying', step: 'check', run: _run(['check']));
      return null;
    };
    await update();
    await shot(t, '$p-02-conferma');
    await t.tap(find.byKey(const Key('dialog-yes')));
    await stage(UpdateStage.running);
    await shot(t, '$p-03-firma', wait: 1500);
    server.osUpdates = _os(
      running: true,
      state: 'applying',
      step: 'download',
      run: _run(['check', 'download'], progress: _down(96 * _mb, 342 * _mb, 4.2 * _mb)),
    );
    await shot(t, '$p-04-immagini', wait: 2500);
    server.osUpdates = _os(
      running: true,
      state: 'applying',
      step: 'files',
      run: _run(
        ['check', 'download', 'files'],
        progress: {'done': 6 * _mb, 'total': 18 * _mb, 'bps': 3 * _mb, 'eta': 4, 'items': []},
      ),
    );
    await shot(t, '$p-05-file-sistema', wait: 2500);
    server.osUpdates = _os(
      running: true,
      state: 'applying',
      step: 'install',
      run: _run(['check', 'download', 'files', 'install']),
    );
    await shot(t, '$p-06-installazione', wait: 2500);
    await server.goDown();
    await waitFor(t, () => (app.updateRun?.attempts ?? 0) >= 3);
    await shot(t, '$p-07-riavvio', wait: 600);
    server
      ..version = '3.8.1'
      ..osUpdates = _os(
        running: true,
        state: 'applying',
        step: 'wait',
        run: _run(['check', 'download', 'files', 'install', 'restart', 'wait']),
      )
      ..down = false;
    await waitFor(t, () => app.updateRun?.stage == UpdateStage.running);
    await shot(t, '$p-08-controllo', wait: 1500);
    server.osUpdates = _os(
      state: 'latest',
      installed: '3.8.1',
      run: _run([
        'check',
        'download',
        'files',
        'install',
        'restart',
        'wait',
      ], finishedAt: DateTime.now().toUtc().add(const Duration(minutes: 3)).toIso8601String()),
    );
    await stage(UpdateStage.done);
    await waitFor(t, () => app.updateRun!.reconnected);
    await shot(t, '$p-09-aggiornato', wait: 1200);
    await t.tap(find.byKey(const Key('update-back')));
    await frames(t, 1500);

    // ---- a stop, and the previous version back ----
    server
      ..version = '3.8.0'
      ..osUpdates = _os();
    await app.refresh();
    await reopen();
    server.onUpdateAct = () {
      server.osUpdates = _os(
        running: true,
        state: 'applying',
        step: 'rollback',
        run: _run(_steps, rollback: true),
      );
      return null;
    };
    await update();
    await t.tap(find.byKey(const Key('dialog-yes')));
    await stage(UpdateStage.running);
    await shot(t, '$p-10-ritorno', wait: 1500);
    server.osUpdates = _os(
      state: 'error',
      run: _run(_steps, reason: 'not_up', rollback: true),
    );
    await stage(UpdateStage.failed);
    await shot(t, '$p-11-errore', wait: 900);
    await t.tap(find.byKey(const Key('update-leave')));
    await frames(t, 1200);

    // ---- a 3.8.0 server: a state and a step only ----
    server
      ..osUpdates = _os()
      ..onUpdateAct = () {
        server.osUpdates = _os(running: true, state: 'applying', step: 'download');
        return null;
      };
    await reopen();
    await update();
    await t.tap(find.byKey(const Key('dialog-yes')));
    await stage(UpdateStage.running);
    await shot(t, '$p-12-server-380', wait: 3500);
    await t.tap(find.byKey(const Key('update-hide')));
    await frames(t, 1200);
    app.updateRun?.dispose();
    app.updateRun = null;

    // ---- a computer: this computer's RedGiant.exe, updated by its launcher ----
    if (!phone) {
      server
        ..osUpdates = null
        ..update = {
          ...server.update,
          'install': 'windows',
          'installed': '3.8.0',
          'state': 'available',
          'progress': null,
        }
        ..onUpdateAct = () {
          server.update = {
            ...server.update,
            'progress': {
              'version': '3.8.1',
              'phase': 'download',
              'done': 14 * _mb,
              'total': 52 * _mb,
              'bps': 3.1 * _mb,
              'eta': 12,
              'at': DateTime.now().toUtc().toIso8601String(),
            },
          };
          return null;
        };
      await reopen();
      await update();
      await shot(t, '$p-13-conferma-lanciatore');
      await t.tap(find.byKey(const Key('dialog-yes')));
      await stage(UpdateStage.running);
      await shot(t, '$p-14-lanciatore', wait: 2000);
    }
    debugDefaultTargetPlatformOverride = null;
    await server.close();
  });
}

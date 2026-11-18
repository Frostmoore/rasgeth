// The new name said once (plan 3.9.0, choice 17, as the page's RenameNotice.tsx): «RedGiant ora
// si chiama Rasgeth» over the phone's home and under the computer's top bar, only for whoever knew
// the old name, until closed; closed, it stays closed.
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rgcompanion/api/servers.dart';
import 'package:rgcompanion/api/token_store.dart';
import 'package:rgcompanion/api/types.dart';
import 'package:rgcompanion/app.dart';
import 'package:rgcompanion/app_state.dart';
import 'package:rgcompanion/brand.dart';

import 'fake_server.dart';

AppController _controller(AppPrefs prefs, {DevicePlatform platform = DevicePlatform.android}) =>
    AppController(tokens: MemoryTokenStore(), platform: platform, prefs: prefs)
      ..reduceMotion = true;

/// Prefs as an app older than 3.9.0 left them: one server saved (its address answers nothing).
MemoryAppPrefs _older() => MemoryAppPrefs()
  ..values['servers'] =
      '[{"id":"s1","label":"Casa","address":"http://127.0.0.1:9","fingerprint":null}]';

Future<void> _pump(WidgetTester tester, AppController app, Size size) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(RGCompanionApp(controller: app));
  await tester.pumpAndSettle();
}

void main() {
  test('born before the new name (table)', () {
    for (final (v, want) in [
      ('3.8.14', true),
      ('3.5.11', true),
      ('2.9.9', true),
      ('3.9.0', false),
      ('3.10.1', false),
      ('4.0.0', false),
      (null, false),
      ('', false),
      ('dev', false),
      ('3.8', false),
    ]) {
      expect(bornBeforeRename(v), want, reason: '$v');
    }
  });

  test('nothing before the settings are read, nothing for a new app', () async {
    expect(_controller(MemoryAppPrefs()).renameDue, isFalse);
    final prefs = MemoryAppPrefs();
    final app = _controller(prefs);
    await app.restore();
    expect(app.renameDue, isFalse);
    // Decided once: servers added later do not make this device one that knew the old name.
    expect(await prefs.get('renameKnew'), '0');
  });

  testWidgets('an app that had servers before: shown, «Ho capito», closed at the next start', (
    tester,
  ) async {
    final prefs = _older();
    final app = _controller(prefs);
    await tester.runAsync(app.restore);
    app.locale = const Locale('it');
    expect(app.renameDue, isTrue);
    await _pump(tester, app, const Size(420, 900));
    expect(find.text('RedGiant ora si chiama Rasgeth.'), findsOneWidget);
    expect(find.textContaining('ràs-ghet'), findsOneWidget);
    await tester.tap(find.byKey(const Key('rename-notice-ok')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('rename-notice')), findsNothing);
    expect(await prefs.get('renameSeen'), kRenamedIn);

    final again = _controller(prefs);
    await tester.runAsync(again.restore);
    expect(again.renameDue, isFalse);
  });

  testWidgets('in English on a computer, under the top bar; the cross closes it too', (
    tester,
  ) async {
    final app = _controller(_older(), platform: DevicePlatform.linux);
    await tester.runAsync(app.restore);
    app.locale = const Locale('en');
    await _pump(tester, app, const Size(1280, 800));
    expect(find.text('RedGiant is now called Rasgeth.'), findsOneWidget);
    await tester.tap(find.byKey(const Key('rename-notice-close')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('rename-notice')), findsNothing);
  });

  group('the server in use', () {
    late FakeRedGiant server;
    setUp(() async {
      HttpOverrides.global = null;
      server = await FakeRedGiant.start();
    });
    tearDown(() => server.close());

    for (final (first, due) in [('3.8.12', true), ('3.9.0', false), (null, false)]) {
      testWidgets('born with $first: ${due ? 'said' : 'nothing'}, in a new app', (tester) async {
        server.update = {...server.update, 'firstVersion': first};
        final prefs = MemoryAppPrefs();
        final app = AppController(
          tokens: MemoryTokenStore(),
          prefs: prefs,
          platform: DevicePlatform.android,
          liveEnabled: false,
        );
        await tester.runAsync(app.restore);
        await tester.runAsync(() => app.connect(server.base.toString(), 'secret'));
        expect(app.renameDue, due);
        if (due) {
          app.dismissRenameNotice();
          await tester.runAsync(() => app.connect(server.base.toString(), 'secret'));
          expect(app.renameDue, isFalse);
        }
      });
    }
  });
}

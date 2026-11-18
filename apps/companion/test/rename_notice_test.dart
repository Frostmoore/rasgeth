// The new name said once (plan 3.9.0, choice 17): «RedGiant ora si chiama Rasgeth» over the
// phone's home and under the computer's top bar, until closed; closed, it stays closed.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rgcompanion/api/servers.dart';
import 'package:rgcompanion/api/token_store.dart';
import 'package:rgcompanion/api/types.dart';
import 'package:rgcompanion/app.dart';
import 'package:rgcompanion/app_state.dart';

AppController _controller(AppPrefs prefs) =>
    AppController(tokens: MemoryTokenStore(), platform: DevicePlatform.android, prefs: prefs)
      ..reduceMotion = true;

Future<void> _pump(WidgetTester tester, AppController app, Size size) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(RGCompanionApp(controller: app));
  await tester.pumpAndSettle();
}

void main() {
  test('nothing before the settings are read', () {
    expect(_controller(MemoryAppPrefs()).renameSeen, isTrue);
  });

  testWidgets('shown once, closed, and closed at the next start', (tester) async {
    final prefs = MemoryAppPrefs();
    final app = _controller(prefs);
    await app.restore();
    app.locale = const Locale('it');
    expect(app.renameSeen, isFalse);
    await _pump(tester, app, const Size(420, 900));
    expect(find.text('RedGiant ora si chiama Rasgeth'), findsOneWidget);
    await tester.tap(find.byKey(const Key('rename-notice-close')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('rename-notice')), findsNothing);
    expect(await prefs.get('renameSeen'), '1');

    final again = _controller(prefs);
    await again.restore();
    expect(again.renameSeen, isTrue);
  });

  testWidgets('in English on a computer, under the top bar', (tester) async {
    final app = AppController(
      tokens: MemoryTokenStore(),
      platform: DevicePlatform.linux,
      prefs: MemoryAppPrefs(),
    )..reduceMotion = true;
    await app.restore();
    app.locale = const Locale('en');
    await _pump(tester, app, const Size(1280, 800));
    expect(find.text('RedGiant is now called Rasgeth'), findsOneWidget);
  });
}

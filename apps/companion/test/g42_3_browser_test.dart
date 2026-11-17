// G42.3: the agents' shared browser, native, against the fake server (which answers as ws.ts and
// browser.ts do): watched while the screen is open, a frame shown, nothing goes in while the agents
// have it; control taken, then a tap is a click at the picture's point (0..1), the wheel scrolls,
// the keys and the text go in, the address goes somewhere; given back; an assistant taught a task;
// a server without the browser says so.
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:rgcompanion/api/servers.dart';
import 'package:rgcompanion/api/token_store.dart';
import 'package:rgcompanion/api/types.dart';
import 'package:rgcompanion/app.dart';
import 'package:rgcompanion/app_state.dart';
import 'package:rgcompanion/screens/browser_screen.dart';

import 'fake_server.dart';

Future<void> _settle(WidgetTester tester, [int rounds = 6]) async {
  for (var i = 0; i < rounds; i++) {
    await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 30)));
    await tester.pump(const Duration(milliseconds: 50));
  }
}

/// A small JPEG, as the screencast sends (16:10).
Uint8List _jpeg() =>
    img.encodeJpg(img.Image(width: 160, height: 100)..clear(img.ColorRgb8(30, 90, 200)));

void main() {
  late FakeRedGiant server;
  late AppController app;
  setUp(() async {
    HttpOverrides.global = null;
    server = await FakeRedGiant.start();
    server.permissions.clear();
  });
  tearDown(() => server.close());

  Future<void> open(WidgetTester tester, {Size size = const Size(1280, 800)}) async {
    app = AppController(
      tokens: MemoryTokenStore(),
      prefs: MemoryAppPrefs(),
      platform: DevicePlatform.android,
    )..locale = const Locale('it');
    await tester.runAsync(() => app.connect(server.base.toString(), 'secret'));
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(RGCompanionApp(controller: app));
    await _settle(tester);
    tester
        .state<NavigatorState>(find.byType(Navigator).first)
        .push(MaterialPageRoute<void>(builder: (_) => const BrowserScreen()))
        .ignore();
    await _settle(tester);
  }

  Future<void> done(WidgetTester tester) async {
    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(minutes: 3));
  }

  testWidgets('watch, frames, control, click, scroll, keys, address, give back', (tester) async {
    await open(tester);
    expect(server.browserActs, ['watch']);
    expect(find.byKey(const Key('browser-starting')), findsOneWidget);
    expect(find.text('https://example.org/'), findsOneWidget);
    await tester.runAsync(() async => server.browserFrame(_jpeg()));
    await _settle(tester);
    expect(find.byKey(const Key('browser-frame')), findsOneWidget);
    expect(find.textContaining('Il browser che i tuoi agenti'), findsOneWidget);

    // The agents have it: a tap sends nothing.
    await tester.tap(find.byKey(const Key('browser-view')));
    await _settle(tester, 2);
    expect(server.browserInputs, isEmpty);

    await tester.tap(find.byKey(const Key('browser-take')));
    await _settle(tester);
    expect(server.browserActs.last, 'control true');
    expect(find.byKey(const Key('browser-give-back')), findsOneWidget);
    expect(find.byKey(const Key('browser-address')), findsOneWidget);

    // A click at the picture's top left quarter.
    final view = tester.getRect(find.byKey(const Key('browser-view')));
    await tester.tapAt(view.topLeft + Offset(view.width / 4, view.height / 4));
    await _settle(tester, 2);
    final click = server.browserInputs.single;
    expect(click['kind'], 'click');
    expect((click['x'] as num).toDouble(), closeTo(.25, .01));
    expect((click['y'] as num).toDouble(), closeTo(.25, .01));

    // The wheel.
    final pointer = TestPointer(1, PointerDeviceKind.mouse);
    await tester.sendEventToBinding(pointer.hover(view.center));
    await tester.sendEventToBinding(pointer.scroll(const Offset(0, 120)));
    await _settle(tester, 2);
    expect(server.browserInputs.last['kind'], 'scroll');
    expect(server.browserInputs.last['dy'], 120);

    // Keys: a character as text, Enter as a key.
    await tester.sendKeyEvent(LogicalKeyboardKey.keyA);
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await _settle(tester, 2);
    expect(server.browserInputs.sublist(server.browserInputs.length - 2), [
      {'kind': 'text', 'text': 'a'},
      {'kind': 'key', 'key': 'Enter'},
    ]);

    await tester.enterText(find.byKey(const Key('browser-address')), 'redgiant.dev');
    await tester.testTextInput.receiveAction(TextInputAction.go);
    await _settle(tester);
    expect(server.browserActs.last, 'goto https://redgiant.dev');

    await tester.tap(find.byKey(const Key('browser-give-back')));
    await _settle(tester);
    expect(server.browserActs.last, 'control false');
    expect(find.byKey(const Key('browser-take')), findsOneWidget);

    await tester.tap(find.byKey(const Key('browser-back')));
    for (var i = 0; i < 12; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
    await _settle(tester);
    expect(find.byType(BrowserScreen), findsNothing);
    expect(server.browserActs.last, 'unwatch');
    await done(tester);
  });

  testWidgets('on a phone a finger scrolls and the field types', (tester) async {
    await open(tester, size: const Size(390, 844));
    await tester.runAsync(() async => server.browserFrame(_jpeg()));
    await tester.tap(find.byKey(const Key('browser-take')));
    await _settle(tester);
    await tester.drag(find.byKey(const Key('browser-view')), const Offset(0, -120));
    await _settle(tester, 2);
    expect(server.browserInputs.where((e) => e['kind'] == 'scroll'), isNotEmpty);
    expect((server.browserInputs.last['dy'] as int) > 0, isTrue);
    await tester.enterText(find.byKey(const Key('browser-type')), 'ciao');
    await _settle(tester, 2);
    expect(server.browserInputs.last, {'kind': 'text', 'text': 'ciao'});
    await done(tester);
  });

  testWidgets('teach an assistant a task, then Done with its name', (tester) async {
    await open(tester);
    expect(app.agents.where((a) => a.kind == AgentKind.assistant), isNotEmpty);
    await tester.tap(find.byKey(const Key('teach-start')));
    await _settle(tester);
    // Two assistants (the mail one and the Chat): which one learns it.
    await tester.tap(find.byKey(const Key('teach-who-a5')));
    await _settle(tester);
    expect(server.browserActs.last, 'teach a5 true');
    expect(find.textContaining('Registro per Assistente mail'), findsOneWidget);
    expect(find.byKey(const Key('browser-take')), findsNothing);
    await tester.tap(find.byKey(const Key('teach-done')));
    await _settle(tester);
    await tester.enterText(find.byKey(const Key('teach-title')), 'Scarica le fatture');
    await tester.tap(find.byKey(const Key('dialog-yes')));
    await _settle(tester);
    expect(server.browserActs.last, 'teach a5 false Scarica le fatture');
    await done(tester);
  });

  testWidgets('a RedGiant without the browser says so', (tester) async {
    server.browserMissing = true;
    await open(tester);
    expect(find.byKey(const Key('browser-unavailable')), findsOneWidget);
    await done(tester);
  });
}

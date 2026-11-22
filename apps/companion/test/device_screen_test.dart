// 3.11 phase 2: a device live, native, against the fake server (which answers as ws.ts does for
// `device.*`) and the fake system (`GET /api/emulators/devices`, `POST .../stop`): the list in
// Settings › Emulators with its badge and its buttons, «Open» shows the screen watched, a frame
// shown in the phone's frame, nothing goes in while the agents have it; control taken, then a tap,
// a press held, a swipe (fractions 0..1), the keys, the text field and the drawn buttons go in;
// given back; closed, it is unwatched; «Switch off» stops an emulator.
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:rgcompanion/api/servers.dart';
import 'package:rgcompanion/api/token_store.dart';
import 'package:rgcompanion/api/types.dart';
import 'package:rgcompanion/app.dart';
import 'package:rgcompanion/app_state.dart';
import 'package:rgcompanion/screens/device_screen.dart';
import 'package:rgcompanion/settings/system/emulators_screen.dart';

import 'fake_server.dart';
import 'fake_system.dart';

Future<void> _settle(WidgetTester tester, [int rounds = 6]) async {
  for (var i = 0; i < rounds; i++) {
    await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 30)));
    await tester.pump(const Duration(milliseconds: 50));
  }
}

/// A small JPEG, upright as a phone's screen.
Uint8List _jpeg() =>
    img.encodeJpg(img.Image(width: 90, height: 200)..clear(img.ColorRgb8(30, 90, 200)));

void main() {
  late FakeRedGiant server;
  late FakeSystem sys;
  late AppController app;
  setUp(() async {
    HttpOverrides.global = null;
    server = await FakeRedGiant.start();
    server.permissions.clear();
    sys = FakeSystem();
    server.system = sys;
  });
  tearDown(() => server.close());

  Future<void> open(WidgetTester tester, {Size size = const Size(420, 4000)}) async {
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
        .push(MaterialPageRoute<void>(builder: (_) => const EmulatorsScreen()))
        .ignore();
    await _settle(tester, 10);
  }

  Future<void> done(WidgetTester tester) async {
    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(minutes: 3));
  }

  Future<void> tap(WidgetTester tester, String key) async {
    await tester.ensureVisible(find.byKey(Key(key)));
    await tester.pump();
    await tester.tap(find.byKey(Key(key)));
    await _settle(tester);
  }

  List<Map<String, dynamic>> inputs() => [
    for (final m in server.received)
      if (m['type'] == 'device.input') m,
  ];

  testWidgets('the list, open, a frame, control, gestures, keys, buttons, give back, close', (
    tester,
  ) async {
    await open(tester);
    expect(sys.calls, contains('GET /api/emulators/devices'));
    expect(find.byKey(const Key('sy-em-dev-emulator-5554')), findsOneWidget);
    expect(find.text('Pixel_8'), findsOneWidget);
    expect(find.textContaining('acceso da '), findsOneWidget);
    expect(find.text('Emulatore · acceso · emulator-5554'), findsOneWidget);
    expect(
      find.text('Telefono via USB · aspetta il tuo sì sul telefono · R58N12ABCDE'),
      findsOneWidget,
    );
    // Only a running emulator switches off; a phone waiting for its yes does not open.
    expect(find.byKey(const Key('sy-em-stop-emulator-5554')), findsOneWidget);
    expect(find.byKey(const Key('sy-em-stop-avd:Tablet')), findsNothing);
    expect(find.byKey(const Key('sy-em-stop-R58N12ABCDE')), findsNothing);
    expect(
      tester.widget<ButtonStyleButton>(find.byKey(const Key('sy-em-open-R58N12ABCDE'))).onPressed,
      isNull,
    );

    await tap(tester, 'sy-em-open-emulator-5554');
    await _settle(tester, 8);
    expect(find.byType(DeviceScreen), findsOneWidget);
    expect(find.byKey(const Key('dv-screen')), findsOneWidget);
    expect(server.deviceActs, ['watch emulator-5554']);
    expect(find.byKey(const Key('dv-starting')), findsOneWidget);
    expect(find.textContaining('Il dispositivo degli agenti'), findsOneWidget);
    await tester.runAsync(() async => server.deviceFrame('emulator-5554', _jpeg()));
    await _settle(tester);
    expect(find.byKey(const Key('dv-frame')), findsOneWidget);

    // The agents have it: a tap and the buttons send nothing.
    await tester.tap(find.byKey(const Key('dv-view')));
    await _settle(tester, 2);
    expect(tester.widget<IconButton>(find.byKey(const Key('dv-home'))).onPressed, isNull);
    expect(inputs(), isEmpty);

    await tap(tester, 'dv-take');
    expect(server.deviceActs.last, 'control emulator-5554 true');
    expect(find.textContaining('Adesso è tuo'), findsOneWidget);
    expect(find.text('Restituisci agli agenti'), findsOneWidget);

    // A tap at the screen's top left quarter.
    final view = tester.getRect(find.byKey(const Key('dv-view')));
    await tester.tapAt(view.topLeft + Offset(view.width / 4, view.height / 4));
    await _settle(tester, 2);
    var e = inputs().last;
    expect(e['id'], 'emulator-5554');
    expect(e['event']['kind'], 'tap');
    expect((e['event']['x'] as num).toDouble(), closeTo(.25, .01));
    expect((e['event']['y'] as num).toDouble(), closeTo(.25, .01));

    // A press held 700 ms.
    final g = await tester.startGesture(view.center);
    await g.up(timeStamp: const Duration(milliseconds: 700));
    await _settle(tester, 2);
    e = inputs().last;
    expect(e['event']['kind'], 'long');
    expect(e['event']['ms'], 700);

    // A swipe up.
    await tester.dragFrom(view.center, Offset(0, -view.height / 4));
    await _settle(tester, 2);
    e = inputs().last;
    expect(e['event']['kind'], 'swipe');
    expect((e['event']['y2'] as num) < (e['event']['y'] as num), isTrue);
    expect(e['event']['ms'], 50);

    // Keys: a character as text, space and Enter as keys.
    await tester.sendKeyEvent(LogicalKeyboardKey.keyA);
    await tester.sendKeyEvent(LogicalKeyboardKey.space);
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await _settle(tester, 2);
    expect(
      [for (final m in inputs().skip(inputs().length - 3)) m['event']],
      [
        {'kind': 'text', 'text': 'a'},
        {'kind': 'key', 'key': 'Space'},
        {'kind': 'key', 'key': 'Enter'},
      ],
    );

    // On a phone the field types.
    await tester.enterText(find.byKey(const Key('dv-type')), 'ciao');
    await _settle(tester, 2);
    expect(inputs().last['event'], {'kind': 'text', 'text': 'ciao'});

    // The phone's buttons and turning it.
    for (final k in ['back', 'home', 'recents', 'rotate']) {
      await tap(tester, 'dv-$k');
    }
    expect(
      [for (final m in inputs().skip(inputs().length - 4)) m['event']],
      [
        {'kind': 'button', 'button': 'back'},
        {'kind': 'button', 'button': 'home'},
        {'kind': 'button', 'button': 'recents'},
        {'kind': 'rotate'},
      ],
    );

    await tap(tester, 'dv-take');
    expect(server.deviceActs.last, 'control emulator-5554 false');
    expect(find.text('Prendi il controllo'), findsOneWidget);

    await tester.tap(find.byKey(const Key('dv-close')));
    for (var i = 0; i < 12; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
    await _settle(tester);
    expect(find.byType(DeviceScreen), findsNothing);
    expect(server.deviceActs.last, 'unwatch emulator-5554');
    expect(find.byType(Checkbox), findsNothing);
    await done(tester);
  });

  testWidgets('an error is said, a wide screen turns the frame, «Switch off» stops it', (
    tester,
  ) async {
    await open(tester);
    await tap(tester, 'sy-em-open-emulator-5554');
    await _settle(tester, 8);
    await tester.runAsync(() async {
      server.deviceStateOf = 'off';
      server.deviceState('emulator-5554', error: 'Too many emulators running');
      server.deviceFrame('emulator-5554', _jpeg(), width: 2400, height: 1080);
    });
    await _settle(tester);
    expect(find.textContaining('Non si può mostrare: Too many emulators running'), findsOneWidget);
    // Off: control cannot be taken.
    expect(tester.widget<ButtonStyleButton>(find.byKey(const Key('dv-take'))).onPressed, isNull);
    final view = tester.getRect(find.byKey(const Key('dv-view')));
    expect(view.width > view.height, isTrue);

    await tester.tap(find.byKey(const Key('dv-close')));
    for (var i = 0; i < 12; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
    await _settle(tester);
    await tap(tester, 'sy-em-stop-emulator-5554');
    expect(sys.bodies['POST /api/emulators/devices/stop'], {'id': 'emulator-5554'});
    expect(find.byKey(const Key('sy-em-stop-emulator-5554')), findsNothing);
    expect(find.byKey(const Key('sy-em-dev-avd:Pixel_8')), findsOneWidget);
    await done(tester);
  });

  test('a gesture: tap, press held, swipe (the page\'s rules)', () {
    expect(deviceGesture((x: .5, y: .5), (x: .51, y: .5), 100), {'kind': 'tap', 'x': .5, 'y': .5});
    expect(deviceGesture((x: .5, y: .5), (x: .5, y: .5), 600)['kind'], 'long');
    expect(deviceGesture((x: .5, y: .5), (x: .5, y: .5), 9000)['ms'], 5000);
    final s = deviceGesture((x: .5, y: .8), (x: .5, y: .2), 10);
    expect(s['kind'], 'swipe');
    expect(s['ms'], 50);
  });
}

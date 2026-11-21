// G42.17: the computers keep running in the system tray when the window closes. The keeper's rule
// behind a fake window (close hides while the setting is on, quits when it is off or there is no
// tray; the menu opens and quits; a notification tapped brings the window back), and the setting
// in Tu › Notifiche against the fake Rasgeth.
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rgcompanion/api/servers.dart';
import 'package:rgcompanion/api/token_store.dart';
import 'package:rgcompanion/api/types.dart';
import 'package:rgcompanion/app.dart';
import 'package:rgcompanion/app_state.dart';
import 'package:rgcompanion/desktop/tray.dart';
import 'package:rgcompanion/push/notice.dart';
import 'package:rgcompanion/push/system_notifier.dart';
import 'package:rgcompanion/screens/notifications_screen.dart';

import 'fake_server.dart';

class FakeWindow implements DesktopWindow {
  FakeWindow({this.tray = true});

  final bool tray;
  final log = <String>[];
  bool kept = false;
  bool visible = true;
  bool ended = false;
  List<String> menu = [];
  VoidCallback? close;
  VoidCallback? opened;
  VoidCallback? quitted;

  @override
  set onClose(VoidCallback? f) => close = f;
  @override
  set onOpen(VoidCallback? f) => opened = f;
  @override
  set onQuit(VoidCallback? f) => quitted = f;

  @override
  Future<bool> start({required String tip, required String open, required String quit}) async {
    if (!tray) return false;
    menu = [tip, open, quit];
    return true;
  }

  @override
  Future<void> relabel({required String tip, required String open, required String quit}) async =>
      menu = [tip, open, quit];

  @override
  Future<void> keepOnClose(bool on) async {
    kept = on;
    log.add('keep:$on');
  }

  /// The person clicks the window's close button.
  void clickClose() {
    if (kept) {
      close?.call();
    } else {
      ended = true;
    }
  }

  @override
  Future<void> show() async {
    visible = true;
    log.add('show');
  }

  @override
  Future<void> hide() async {
    visible = false;
    log.add('hide');
  }

  @override
  Future<void> quit() async {
    ended = true;
    log.add('quit');
  }
}

Future<void> _settle(WidgetTester tester, [int rounds = 10]) async {
  for (var i = 0; i < rounds; i++) {
    await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 30)));
    await tester.pump();
  }
  await tester.pumpAndSettle();
}

void main() {
  AppController app0({Locale locale = const Locale('it'), MemoryNotifier? notes}) =>
      AppController(
          tokens: MemoryTokenStore(),
          prefs: MemoryAppPrefs(),
          platform: DevicePlatform.windows,
          liveEnabled: false,
          notifier: notes,
        )
        ..locale = locale
        ..reduceMotion = true;

  group('the keeper', () {
    test('closing hides into the tray while the setting is on, and the menu opens it', () async {
      final app = app0();
      final w = FakeWindow();
      final k = TrayKeeper(app, w);
      await k.start();
      expect(app.trayAvailable, isTrue);
      expect(w.menu, ['Rasgeth', 'Apri', 'Esci']);
      expect(w.kept, isTrue);
      w.clickClose();
      await Future<void>.delayed(Duration.zero);
      expect(w.visible, isFalse);
      expect(w.ended, isFalse);
      expect(k.hidden, isTrue);
      // Hidden: the app is behind, so requests come as notifications.
      expect(app.foreground, isFalse);
      w.opened!();
      await Future<void>.delayed(Duration.zero);
      expect(w.visible, isTrue);
      expect(app.foreground, isTrue);
      w.quitted!();
      await Future<void>.delayed(Duration.zero);
      expect(w.log.last, 'quit');
      expect(w.kept, isFalse);
      expect(w.ended, isTrue);
    });

    test('with the setting off the window closes the app, as before', () async {
      final app = app0();
      final w = FakeWindow();
      await TrayKeeper(app, w).start();
      app.setStayInTray(false);
      await Future<void>.delayed(Duration.zero);
      expect(w.kept, isFalse);
      expect(await app.prefs.get('stayInTray'), '0');
      w.clickClose();
      expect(w.ended, isTrue);
      expect(w.log, isNot(contains('hide')));
      // Back on.
      app.setStayInTray(true);
      await Future<void>.delayed(Duration.zero);
      expect(w.kept, isTrue);
      expect(await app.prefs.get('stayInTray'), isNull);
    });

    test('a desktop without a tray: nothing kept, the window closes the app', () async {
      final app = app0();
      final w = FakeWindow(tray: false);
      await TrayKeeper(app, w).start();
      expect(app.trayAvailable, isFalse);
      expect(w.kept, isFalse);
      w.clickClose();
      expect(w.ended, isTrue);
    });

    test('the menu follows the language', () async {
      final app = app0(locale: const Locale('en'));
      final w = FakeWindow();
      await TrayKeeper(app, w).start();
      expect(w.menu, ['Rasgeth', 'Open', 'Quit']);
      app.setLocale(const Locale('it'));
      await Future<void>.delayed(Duration.zero);
      expect(w.menu, ['Rasgeth', 'Apri', 'Esci']);
    });
  });

  group('with the fake Rasgeth', () {
    late FakeRedGiant server;
    setUp(() async {
      HttpOverrides.global = null;
      server = await FakeRedGiant.start();
    });
    tearDown(() => server.close());

    testWidgets('Tu › Notifiche: the setting, and a notification tapped brings the window back', (
      tester,
    ) async {
      final notes = MemoryNotifier();
      final app = app0(notes: notes);
      final w = FakeWindow();
      await tester.runAsync(() async {
        await app.startSystems();
        await app.connect(server.base.toString(), 'secret');
        await TrayKeeper(app, w).start();
      });
      tester.view.physicalSize = const Size(1290, 2700);
      tester.view.devicePixelRatio = 3;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(RGCompanionApp(controller: app));
      await _settle(tester);
      final nav = tester.state<NavigatorState>(find.byType(Navigator).first);
      nav.push(MaterialPageRoute<void>(builder: (_) => const NotificationsScreen()));
      await _settle(tester);
      await tester.scrollUntilVisible(find.byKey(const Key('stay-in-tray')), 200);
      expect(find.text('Resta nella barra di sistema quando chiudi la finestra'), findsOneWidget);
      expect(find.textContaining('resta nella barra di sistema e le notifiche'), findsOneWidget);
      await tester.tap(find.text('Resta nella barra di sistema quando chiudi la finestra'));
      await tester.pumpAndSettle();
      expect(app.stayInTray, isFalse);
      expect(
        find.textContaining('Con l\'app chiusa questo computer non riceve niente'),
        findsOneWidget,
      );
      await tester.tap(find.text('Resta nella barra di sistema quando chiudi la finestra'));
      await tester.pumpAndSettle();
      expect(app.stayInTray, isTrue);
      // Hidden in the tray, a notification tapped: the window comes back.
      await tester.runAsync(() async {
        w.clickClose();
        await Future<void>.delayed(Duration.zero);
      });
      expect(w.visible, isFalse);
      notes.onResponse!(
        NoticeTap(serverId: app.server!.id, noticeId: 'n1', kind: NoticeKind.values.first),
        null,
      );
      await _settle(tester);
      expect(w.visible, isTrue);
      expect(app.foreground, isTrue);
      await tester.pumpWidget(const SizedBox());
      await tester.pump(const Duration(minutes: 3));
    });
  });
}

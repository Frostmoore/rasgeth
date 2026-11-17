// 3.8.11: «Download» on a file an agent sent and on a message's attachment, as the page's «Save»:
// the same route (`/api/files/raw`), the system's «Save as» (here a stand-in), a bar with how
// much, how fast and how long for a big file, its words in Italian and English.
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rgcompanion/api/servers.dart';
import 'package:rgcompanion/api/token_store.dart';
import 'package:rgcompanion/api/types.dart';
import 'package:rgcompanion/app.dart';
import 'package:rgcompanion/app_state.dart';
import 'package:rgcompanion/l10n/app_localizations.dart';
import 'package:rgcompanion/screens/conversation_screen.dart';
import 'package:rgcompanion/theme/theme.dart';
import 'package:rgcompanion/ui/chat/file_download.dart';

import 'fake_files.dart';
import 'fake_server.dart';

Future<void> _settle(WidgetTester tester, [int rounds = 10]) async {
  for (var i = 0; i < rounds; i++) {
    await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 30)));
    await tester.pump(const Duration(milliseconds: 50));
  }
}

void main() {
  group('the bar of a download', () {
    test('how much, how fast, how long', () {
      var now = DateTime(2026, 11, 17, 10);
      final p = DownloadProgress(total: 4 * 1048576, now: () => now);
      expect(p.fraction, 0);
      expect(p.left, isNull, reason: 'no speed yet');
      now = now.add(const Duration(seconds: 2));
      p.update(1048576, null);
      expect(p.fraction, .25);
      expect(p.perSecond, 524288);
      expect(p.left, const Duration(seconds: 6));
      p.update(2 * 1048576, 8 * 1048576);
      expect(p.total, 8 * 1048576, reason: 'the server said the size');
      expect(p.fraction, .25);
    });

    test('short times', () {
      final table = {
        Duration.zero: '1 s',
        const Duration(seconds: 42): '42 s',
        const Duration(seconds: 61): '2 min',
        const Duration(minutes: 65): '1 h 5 min',
      };
      for (final e in table.entries) {
        expect(shortDuration(e.key), e.value, reason: '${e.key}');
      }
    });

    for (final (lang, words) in [
      ('it', ('Scarico video.mp4', '1,0 MB di 4,0 MB · 512 KB/s · ancora 6 s')),
      ('en', ('Downloading video.mp4', '1.0 MB of 4.0 MB · 512 KB/s · 6 s left')),
    ]) {
      testWidgets('its words ($lang)', (tester) async {
        var now = DateTime(2026, 11, 17, 10);
        final p = DownloadProgress(total: 4 * 1048576, now: () => now);
        now = now.add(const Duration(seconds: 2));
        p.update(1048576, null);
        await tester.pumpWidget(
          MaterialApp(
            locale: Locale(lang),
            theme: buildTheme(Brightness.light),
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: Scaffold(
              body: DownloadBar(name: 'video.mp4', progress: p),
            ),
          ),
        );
        expect(find.text(words.$1), findsOneWidget);
        expect(find.text(words.$2), findsOneWidget);
        expect(find.text('25%'), findsOneWidget);
      });
    }
  });

  group('in the conversation, against the fake server', () {
    late FakeRedGiant server;
    late List<(String, Uint8List)> saved;
    final big = Uint8List.fromList(List<int>.generate(2 * 1048576, (i) => i % 251));

    setUp(() async {
      HttpOverrides.global = null;
      server = await FakeRedGiant.start();
      server.permissions.clear();
      server.files = FakeFiles()
        ..put('platform', 'out/conti.csv', 'mese;totale\nnov;480\n')
        ..put('platform', 'out/video.mp4', big)
        ..put('platform', '.attachments/2026-11-17/a1-nota.txt', 'ricorda\n');
      saved = [];
      debugSaveBytes = (name, bytes) async {
        saved.add((name, bytes));
        return true;
      };
    });
    tearDown(() async {
      debugSaveBytes = null;
      await server.close();
    });

    Future<void> open(WidgetTester tester, Size size) async {
      final app = AppController(
        tokens: MemoryTokenStore(),
        prefs: MemoryAppPrefs(),
        platform: size.width > 700 ? DevicePlatform.linux : DevicePlatform.android,
      )..locale = const Locale('it');
      await tester.runAsync(() => app.connect(server.base.toString(), 'secret'));
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(RGCompanionApp(controller: app));
      await _settle(tester);
      tester
          .state<NavigatorState>(find.byType(Navigator).first)
          .push(
            MaterialPageRoute<void>(
              builder: (_) => ConversationScreen(sessionId: 's1', agent: app.agents.first),
            ),
          )
          .ignore();
      await _settle(tester);
    }

    Future<void> done(WidgetTester tester) async {
      await tester.pumpWidget(const SizedBox());
      await tester.pump(const Duration(minutes: 3));
    }

    for (final (what, size) in [
      ('computer', const Size(1280, 860)),
      ('phone', const Size(390, 844)),
    ]) {
      testWidgets('$what: a file the agent sent and an attachment download', (tester) async {
        await open(tester, size);
        server.store('s1', 'message.user', {
          'text':
              'Tieni la nota\n\n<attachment name="nota.txt" '
              'path=".attachments/2026-11-17/a1-nota.txt" size="8" />',
        });
        server.store('s1', 'file.sent', {
          'scope': 'platform',
          'path': 'out/conti.csv',
          'name': 'conti.csv',
          'mime': 'text/csv',
          'size': 21,
          'caption': 'I conti di novembre',
        });
        await _settle(tester);

        // Both actions on the card: «Scarica» and «Apri».
        expect(find.byKey(const Key('file-open-out/conti.csv')), findsOneWidget);
        await tester.tap(find.byKey(const Key('file-download-out/conti.csv')));
        await _settle(tester);
        expect(saved.single.$1, 'conti.csv');
        expect(String.fromCharCodes(saved.single.$2), 'mese;totale\nnov;480\n');
        expect(find.text('Salvato: conti.csv'), findsOneWidget);
        expect(find.byKey(const Key('download-progress')), findsNothing, reason: 'a small file');

        // The attachment saved in the workspace downloads too.
        await tester.tap(find.byKey(const Key('attachment-download-nota.txt')));
        await _settle(tester);
        expect(saved.last.$1, 'nota.txt');
        expect(String.fromCharCodes(saved.last.$2), 'ricorda\n');
        await done(tester);
      });
    }

    testWidgets('a big file shows its bar while it comes', (tester) async {
      await open(tester, const Size(1280, 860));
      // The person's «Save as» waits: the bar has closed by then, the file whole.
      server.store('s1', 'file.sent', {
        'scope': 'platform',
        'path': 'out/video.mp4',
        'name': 'video.mp4',
        'mime': 'video/mp4',
        'size': big.length,
      });
      await _settle(tester);
      await tester.tap(find.byKey(const Key('file-download-out/video.mp4')));
      await tester.pump();
      expect(find.byKey(const Key('download-progress')), findsOneWidget);
      expect(find.textContaining('Scarico video.mp4'), findsOneWidget);
      await _settle(tester, 20);
      expect(saved.single.$2.length, big.length);
      expect(find.text('Salvato: video.mp4'), findsOneWidget);
      await done(tester);
    });

    testWidgets('a file the server refuses: said, nothing saved', (tester) async {
      await open(tester, const Size(390, 844));
      server.store('s1', 'file.sent', {
        'scope': 'platform',
        'path': 'out/gone.pdf',
        'name': 'gone.pdf',
        'mime': 'application/pdf',
        'size': 10,
      });
      await _settle(tester);
      await tester.tap(find.byKey(const Key('file-download-out/gone.pdf')));
      await _settle(tester);
      expect(saved, isEmpty);
      expect(find.text('Non sono riuscito a scaricare gone.pdf'), findsOneWidget);
      await done(tester);
    });
  });
}

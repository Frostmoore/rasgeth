// 3.8.3: Ctrl+V (Cmd+V on macOS) in a conversation's composer attaches copied files and clipboard
// images with the same rules as «Attach»; with text on the clipboard it pastes the text as before.
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rgcompanion/api/servers.dart';
import 'package:rgcompanion/api/token_store.dart';
import 'package:rgcompanion/api/types.dart';
import 'package:rgcompanion/app.dart';
import 'package:rgcompanion/app_state.dart';
import 'package:rgcompanion/screens/conversation_screen.dart';
import 'package:rgcompanion/ui/paste_files.dart';

import 'fake_server.dart';

class _FakeClipboard extends ClipboardReader {
  _FakeClipboard({this.copied = const [], this.picture, this.text = false});

  final List<PastedFile> copied;
  final Uint8List? picture;
  final bool text;

  @override
  Future<List<PastedFile>> files() async => copied;

  @override
  Future<Uint8List?> image() async => picture;

  @override
  Future<bool> hasText() async => text;
}

// The smallest PNG header is enough: the composer does not decode PNGs.
final _png = Uint8List.fromList([0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A, 1, 2, 3, 4]);

/// A 2x2 24-bit BMP, as Windows gives a screenshot.
Uint8List _bmp() {
  final b = BytesBuilder();
  void u16(int v) => b.add([v & 0xFF, v >> 8 & 0xFF]);
  void u32(int v) => b.add([v & 0xFF, v >> 8 & 0xFF, v >> 16 & 0xFF, v >> 24 & 0xFF]);
  const row = 8; // 2 pixels * 3 bytes, padded to 4
  b.add('BM'.codeUnits);
  u32(54 + row * 2);
  u32(0);
  u32(54);
  u32(40);
  u32(2);
  u32(2);
  u16(1);
  u16(24);
  u32(0);
  u32(row * 2);
  u32(2835);
  u32(2835);
  u32(0);
  u32(0);
  for (var y = 0; y < 2; y++) {
    b.add([0, 0, 255, 0, 255, 0, 0, 0]);
  }
  return b.toBytes();
}

Future<void> _settle(WidgetTester tester, [int rounds = 12]) async {
  for (var i = 0; i < rounds; i++) {
    await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 30)));
    await tester.pump();
  }
  await tester.pump(const Duration(milliseconds: 400));
}

void main() {
  tearDown(() => clipboardReader = const SystemClipboardReader());

  group('what a paste attaches', () {
    test('sniffImage: the types the server takes, nothing else', () {
      expect(sniffImage(_png), 'image/png');
      expect(sniffImage(Uint8List.fromList([0xFF, 0xD8, 0xFF, 0xE0])), 'image/jpeg');
      expect(sniffImage(Uint8List.fromList('GIF89a'.codeUnits)), 'image/gif');
      expect(sniffImage(Uint8List.fromList('RIFF....WEBPVP8 '.codeUnits)), 'image/webp');
      expect(sniffImage(_bmp()), isNull);
      expect(sniffImage(Uint8List(0)), isNull);
    });

    test('pastedName: as the page names what is pasted', () {
      expect(pastedName(DateTime(2026, 11, 6, 9, 5, 7), 'png'), 'pasted-2026-11-06-090507.png');
    });

    test('copied files first, then text wins over an image, then the image', () async {
      final f = [('a.txt', Uint8List.fromList('ciao'.codeUnits))];
      expect(await readPastedFiles(_FakeClipboard(copied: f, picture: _png, text: true)), f);
      expect(await readPastedFiles(_FakeClipboard(picture: _png, text: true)), isEmpty);
      final img = await readPastedFiles(_FakeClipboard(picture: _png));
      expect(img.single.$1, matches(RegExp(r'^pasted-\d{4}-\d\d-\d\d-\d{6}\.png$')));
      expect(img.single.$2, _png);
      expect(await readPastedFiles(_FakeClipboard()), isEmpty);
    });

    testWidgets('a BMP (Windows) becomes a PNG', (tester) async {
      final out = await tester.runAsync(() => pastedImage(_bmp()));
      expect(out!.$1, endsWith('.png'));
      expect(sniffImage(out.$2), 'image/png');
    });
  });

  group('in the composer', () {
    late FakeRedGiant server;
    setUp(() async {
      HttpOverrides.global = null;
      server = await FakeRedGiant.start();
    });
    tearDown(() => server.close());

    Future<void> open(WidgetTester tester) async {
      final app =
          AppController(
              tokens: MemoryTokenStore(),
              prefs: MemoryAppPrefs(),
              platform: DevicePlatform.windows,
              liveEnabled: false,
            )
            ..locale = const Locale('it')
            ..reduceMotion = true;
      await tester.runAsync(() => app.connect(server.base.toString(), 'secret'));
      tester.view.physicalSize = const Size(1440, 900);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(RGCompanionApp(controller: app));
      await _settle(tester);
      final nav = tester.state<NavigatorState>(find.byType(Navigator).first);
      nav
          .push(
            MaterialPageRoute<void>(
              builder: (_) => ConversationScreen(sessionId: 's1', agent: app.agents.first),
            ),
          )
          .ignore();
      await _settle(tester);
      await tester.tap(find.byKey(const Key('composer-text')));
      await tester.pump();
    }

    Future<void> paste(WidgetTester tester) async {
      await tester.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
      await tester.sendKeyEvent(LogicalKeyboardKey.keyV);
      await tester.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);
      await _settle(tester);
    }

    Future<void> done(WidgetTester tester) async {
      await tester.pumpWidget(const SizedBox());
      await tester.pump(const Duration(minutes: 3));
    }

    testWidgets('a screenshot: one image chip, sent as an image', (tester) async {
      clipboardReader = _FakeClipboard(picture: _png);
      await open(tester);
      await paste(tester);
      final chip = tester.widget<InputChip>(find.byType(InputChip));
      expect((chip.label as Text).data, startsWith('pasted-'));
      expect(tester.widget<TextField>(find.byKey(const Key('composer-text'))).controller!.text, '');
      await tester.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);
      await _settle(tester);
      final sent = server.sent.single;
      expect((sent['images'] as List).single['mediaType'], 'image/png');
      await done(tester);
    });

    testWidgets('copied files: one chip each', (tester) async {
      clipboardReader = _FakeClipboard(
        copied: [
          ('note.md', Uint8List.fromList('# Ciao'.codeUnits)),
          ('foto.jpg', Uint8List.fromList([0xFF, 0xD8, 0xFF, 0xE0])),
        ],
        text: true,
      );
      await open(tester);
      await paste(tester);
      expect(find.widgetWithText(InputChip, 'note.md'), findsOneWidget);
      expect(find.widgetWithText(InputChip, 'foto.jpg'), findsOneWidget);
      await done(tester);
    });

    testWidgets('only text: pasted in the field as before, nothing attached', (tester) async {
      clipboardReader = _FakeClipboard(picture: _png, text: true);
      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(SystemChannels.platform, (
        call,
      ) async {
        if (call.method == 'Clipboard.getData') return {'text': 'testo incollato'};
        if (call.method == 'Clipboard.hasStrings') return {'value': true};
        return null;
      });
      addTearDown(
        () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
          SystemChannels.platform,
          null,
        ),
      );
      await open(tester);
      await paste(tester);
      expect(find.byType(InputChip), findsNothing);
      expect(
        tester.widget<TextField>(find.byKey(const Key('composer-text'))).controller!.text,
        'testo incollato',
      );
      await done(tester);
    });
  });
}

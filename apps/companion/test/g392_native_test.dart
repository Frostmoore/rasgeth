// 3.9.2 (2026-11-19): the model's own generation before ours, as the page does it. What is being
// made right now (`generatingNow`, the page's), the «generating a picture» card with no percent,
// every picture an agent sends shown in place (a frame while it loads, «cannot be opened» when it
// cannot), and a picture by a path in an answer said plainly.
import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rgcompanion/api/conversation.dart';
import 'package:rgcompanion/api/live_model.dart';
import 'package:rgcompanion/l10n/app_localizations.dart';
import 'package:rgcompanion/screens/conversation_screen.dart';
import 'package:rgcompanion/theme/theme.dart';
import 'package:rgcompanion/ui/chat/chat_image.dart';
import 'package:rgcompanion/ui/chat/chat_parts.dart';
import 'package:rgcompanion/ui/markdown.dart';

const _png =
    'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mP8z8BQDwAEhQGAhKmMIQAAAABJRU5ErkJggg==';

RgEvent _e(int seq, String type, Map<String, dynamic> payload) =>
    RgEvent(seq: seq, ts: '', type: type, payload: payload, sessionId: 's1');

Widget _app(Widget child, {Brightness b = Brightness.light}) => MaterialApp(
  locale: const Locale('it'),
  supportedLocales: AppLocalizations.supportedLocales,
  localizationsDelegates: AppLocalizations.localizationsDelegates,
  theme: buildTheme(b),
  home: Scaffold(body: child),
);

void main() {
  group('what is being made right now', () {
    test('the last generation call without its result', () {
      final call = _e(1, 'tool.call', {
        'callId': 'native_ig_1',
        'tool': 'image_generation',
        'input': {'by': 'chatgpt-subscription'},
      });
      expect(generatingNow([]), isNull);
      expect(generatingNow([call]), 'image');
      expect(
        generatingNow([
          call,
          _e(2, 'tool.result', {'callId': 'native_ig_1', 'ok': true}),
        ]),
        isNull,
      );
      expect(
        generatingNow([
          _e(1, 'tool.call', {'callId': 'v', 'tool': 'video_generation', 'input': {}}),
        ]),
        'video',
      );
      expect(
        generatingNow([
          _e(1, 'tool.call', {'callId': 'r', 'tool': 'read_file', 'input': {}}),
        ]),
        isNull,
      );
      expect(
        generatingNow([
          call,
          _e(2, 'message.user', {'text': 'stop'}),
        ]),
        isNull,
      );
    });

    test('a tool call ends the model call under way (no «reading the context» while it draws)', () {
      final m = LiveModel();
      m.apply({'type': 'session.state', 'sessionId': 's1', 'state': 'running'});
      expect(m.view('s1').call, isNotNull);
      m.apply({
        'type': 'event',
        'sessionId': 's1',
        'event': {
          'seq': 3,
          'ts': '2026-11-19T10:00:00.000Z',
          'sessionId': 's1',
          'type': 'tool.call',
          'payload': {'callId': 'native_ig_1', 'tool': 'image_generation', 'input': {}},
        },
      });
      expect(m.view('s1').call, isNull);
      expect(generatingNow(m.view('s1').events), 'image');
    });
  });

  testWidgets('the card with no percent: a moving bar and what is being made', (tester) async {
    await tester.pumpWidget(_app(const DrawingCard(label: 'Sta generando un\'immagine…')));
    expect(find.text('Sta generando un\'immagine…'), findsOneWidget);
    expect(
      tester.widget<LinearProgressIndicator>(find.byType(LinearProgressIndicator)).value,
      isNull,
    );
    await tester.pump(const Duration(milliseconds: 300));
    await tester.pumpWidget(const SizedBox());
  });

  group('a picture in the chat', () {
    testWidgets('a frame while it loads, then the picture; a tap opens it', (tester) async {
      var opened = 0;
      await tester.pumpWidget(
        _app(
          ChatImagePreview(
            scope: 'platform',
            path: 'images/a.png',
            alt: 'Una stella rossa',
            onOpen: () => opened++,
            load: () => Future<Uint8List>.delayed(
              const Duration(milliseconds: 50),
              () => base64Decode(_png),
            ),
          ),
        ),
      );
      expect(find.byKey(const Key('chat-image-wait')), findsOneWidget);
      // The test's clock: the bytes come after 50 ms.
      await tester.pump(const Duration(milliseconds: 60));
      await tester.pump();
      expect(find.byKey(const Key('chat-image-wait')), findsNothing);
      expect(find.byType(Image), findsOneWidget);
      // A 1-pixel picture still decoding has no size to tap: its tap, as the list gives it.
      tester.widget<GestureDetector>(find.byKey(const Key('chat-image-images/a.png'))).onTap!();
      expect(opened, 1);
    });

    testWidgets('says plainly when it cannot be read, never an empty card', (tester) async {
      await tester.pumpWidget(
        _app(
          ChatImagePreview(
            scope: 'platform',
            path: 'images/gone.png',
            alt: 'x',
            load: () => Future<Uint8List>.error(Exception('404')),
          ),
          b: Brightness.dark,
        ),
      );
      await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 20)));
      await tester.pump();
      expect(find.byKey(const Key('chat-image-bad')), findsOneWidget);
      expect(find.text('Non riesco ad aprire questa immagine'), findsOneWidget);
    });

    test('which files show in place', () {
      expect(isChatPicture('image/png', 'a.png'), isTrue);
      expect(isChatPicture('image/jpeg', 'a'), isTrue);
      expect(isChatPicture('', 'foto.WEBP'), isTrue);
      expect(isChatPicture('image/svg+xml', 'a.svg'), isFalse);
      expect(isChatPicture('application/pdf', 'a.pdf'), isFalse);
    });
  });

  testWidgets('a picture by a path in an answer says it is not available', (tester) async {
    await tester.pumpWidget(
      _app(const SafeMarkdown('![cavallo](/data/engines/codex/generated_images/t/a.png)')),
    );
    await tester.pump();
    expect(find.textContaining('Immagine non disponibile qui: cavallo'), findsOneWidget);
  });
}

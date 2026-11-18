// 3.8.7: widgets in answers and artifacts in the Canvas, as in the page. The split of an answer is
// checked against the page's own functions (test/fixtures/widget_vectors.json, written by
// tool/widget_fixtures.mjs); the frame's protocol (messages, click rule, nonce, policy, navigation)
// as tables; the relay with real sockets on 127.0.0.1; the screens with a stand-in web view.
import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rgcompanion/api/artifact_frame.dart';
import 'package:rgcompanion/api/conversation.dart';
import 'package:rgcompanion/api/preview_relay.dart';
import 'package:rgcompanion/api/servers.dart';
import 'package:rgcompanion/api/token_store.dart';
import 'package:rgcompanion/api/transport.dart';
import 'package:rgcompanion/api/types.dart';
import 'package:rgcompanion/api/widgets.dart';
import 'package:rgcompanion/app.dart';
import 'package:rgcompanion/app_state.dart';
import 'package:rgcompanion/embed/embed_link.dart';
import 'package:rgcompanion/embed/web_host.dart';
import 'package:rgcompanion/screens/canvas_screen.dart';
import 'package:rgcompanion/screens/conversation_screen.dart';
import 'package:rgcompanion/ui/artifact_frame_view.dart';

import 'fake_server.dart';

Map<String, Object?> segJson(AnswerSegment s) => switch (s) {
  TextSegment(:final text) => {'kind': 'text', 'text': text},
  WidgetSegment(:final index, :final title, :final html, :final closed, :final tooBig) => {
    'kind': 'widget',
    'index': index,
    'title': title,
    'html': html,
    'closed': closed,
    'tooBig': tooBig,
  },
};

/// A web view that is not one: what the wrapper would hand over, and the scripts run in it.
class FakeFrameHost implements FrameHost {
  final _out = StreamController<String>.broadcast();
  final scripts = <String>[];
  RelayFrame? loaded;
  bool? eager;

  @override
  Stream<String> get messages => _out.stream;

  @override
  Future<void> load(RelayFrame frame) async => loaded = frame;

  @override
  Future<void> run(String script) async => scripts.add(script);

  @override
  Widget view({required bool eager}) {
    this.eager = eager;
    return const ColoredBox(color: Color(0xFF80C0FF), child: SizedBox.expand());
  }

  @override
  void dispose() {}

  void emit(Map<String, Object?> e, {String? nonce}) =>
      _out.add(jsonEncode({'n': nonce ?? loaded!.nonce, ...e}));
  void post(Object? data, {bool focused = false, bool activated = false}) =>
      emit({'k': 'msg', 'd': data, 'f': focused, 'a': activated});
  void click() => emit({'k': 'click'});

  Iterable<Map<String, dynamic>> get posted => scripts.map((s) {
    final j = s.substring(s.indexOf('(', s.indexOf('__rgPost(')) + 1, s.lastIndexOf(')'));
    return jsonDecode(j) as Map<String, dynamic>;
  });
}

Map<String, Object?> uiMessage(String text) => {
  'jsonrpc': '2.0',
  'method': 'ui/message',
  'id': 1,
  'params': {
    'role': 'user',
    'content': [
      {'type': 'text', 'text': text},
    ],
  },
};

String short(String s) => jsonEncode(s.length > 30 ? s.substring(0, 30) : s);

void main() {
  final vectors = jsonDecode(
    File('test/fixtures/widget_vectors.json').readAsStringSync(),
  ) as Map<String, dynamic>;

  group('an answer split as the page splits it', () {
    for (final v in [...vectors['segments'] as List, ...vectors['segmentsFrom'] as List]) {
      final text = v['text'] as String;
      test('segments ${short(text)}', () {
        expect(answerSegments(text, v['first'] as int).map(segJson).toList(), v['out']);
      });
    }
    for (final v in vectors['split'] as List) {
      test('splitWidgets ${short(jsonEncode(v['texts']))}', () {
        final r = splitWidgets([for (final t in v['texts'] as List) t as String]);
        expect(r.texts, (v['out'] as Map)['texts']);
        expect([
          for (final w in r.widgets) {'index': w.index, 'title': w.title},
        ], (v['out'] as Map)['widgets']);
      });
    }
    for (final v in vectors['streaming'] as List) {
      test('streaming ${short(v['text'] as String)}', () {
        expect(streamingWithoutWidgets(v['text'] as String, 'Sto preparando un widget…'), v['out']);
      });
    }
    for (final v in vectors['limit'] as List) {
      test('the 64 KB limit: ${v['char']} × ${v['times']}', () {
        final text = '```widget\n${(v['char'] as String) * (v['times'] as int)}\n```';
        expect((answerSegments(text).single as WidgetSegment).tooBig, v['tooBig']);
      });
    }
    test('a widget being written never shows its code', () {
      final s = streamingWithoutWidgets('Ecco:\n```widget Umidità\n<script>let a=1', 'Preparo…');
      expect(s, isNot(contains('<script>')));
      expect(s, contains('_Preparo…_'));
    });
    test('the preview of its words (Linux)', () {
      expect(
        widgetPreviewText(
          '<style>b{}</style><h3>Rata</h3><p>480&nbsp;€ al mese</p><script>x()</script>',
        ),
        'Rata 480 € al mese',
      );
      expect(widgetPreviewText('<p>${'a' * 300}</p>', max: 10), '${'a' * 10}…');
    });
  });

  group('buildItems: widgets after their answer', () {
    RgEvent answer(int seq, List<String> texts) => RgEvent(
      seq: seq,
      ts: '2026-11-17T10:00:00.000Z',
      type: 'message.assistant',
      payload: {
        'parts': [
          for (final t in texts) {'type': 'text', 'text': t},
        ],
        'stopReason': 'end_turn',
      },
    );
    test('numbered across the parts; the text keeps the rest; open blocks stay code', () {
      final items = buildItems([
        answer(4, [
          'Prima\n```widget A\n<b>1</b>\n```',
          'x\n```widget\n<i>2</i>\n```\n```widget C\n<p>aperto',
        ]),
      ], sessionId: 's1');
      expect(items.first, isA<AssistantItem>());
      expect((items.first as AssistantItem).text, 'Prima\n\nx\n\n```html\n<p>aperto');
      final w = items.whereType<WidgetItem>().toList();
      expect(
        [for (final x in w) (x.index, x.title, x.seq, x.sessionId)],
        [(0, 'A', 4, 's1'), (1, '', 4, 's1')],
      );
      expect(w.first.html, '<b>1</b>');
    });
    test('without a conversation id no widget (nothing to ask the server for)', () {
      final items = buildItems([
        answer(4, ['```widget A\n<b>1</b>\n```']),
      ]);
      expect(items.whereType<WidgetItem>(), isEmpty);
    });
  });

  group('the frame\'s messages (FrameMessage)', () {
    final table = <String, (Object?, Type?)>{
      'size': (
        {
          'method': 'ui/notifications/size-changed',
          'params': {'height': 120.5},
        },
        FrameSizeChanged,
      ),
      'size too tall': (
        {
          'method': 'ui/notifications/size-changed',
          'params': {'height': 100001},
        },
        null,
      ),
      'size negative': (
        {
          'method': 'ui/notifications/size-changed',
          'params': {'height': -1},
        },
        null,
      ),
      'size width not a number': (
        {
          'method': 'ui/notifications/size-changed',
          'params': {'height': 1, 'width': 'x'},
        },
        null,
      ),
      'message': (uiMessage('ciao'), FrameUiMessage),
      'message no role': (
        {
          'method': 'ui/message',
          'params': {
            'content': [
              {'type': 'text', 'text': 'a'},
            ],
          },
        },
        FrameUiMessage,
      ),
      'message as assistant': (
        {
          'method': 'ui/message',
          'params': {
            'role': 'assistant',
            'content': [
              {'type': 'text', 'text': 'a'},
            ],
          },
        },
        null,
      ),
      'message empty content': (
        {
          'method': 'ui/message',
          'params': {'content': <Object>[]},
        },
        null,
      ),
      'message 11 parts': (
        {
          'method': 'ui/message',
          'params': {
            'content': [
              for (var i = 0; i < 11; i++) {'type': 'text', 'text': '$i'},
            ],
          },
        },
        null,
      ),
      'message an image': (
        {
          'method': 'ui/message',
          'params': {
            'content': [
              {'type': 'image', 'text': 'a'},
            ],
          },
        },
        null,
      ),
      'message id an object': (
        {
          'method': 'ui/message',
          'id': {'x': 1},
          'params': {
            'content': [
              {'type': 'text', 'text': 'a'},
            ],
          },
        },
        null,
      ),
      'initialized': ({'method': 'ui/notifications/initialized'}, FrameInitialized),
      'initialized params null': ({'method': 'ui/notifications/initialized', 'params': null}, null),
      'error': (
        {
          'method': 'redgiant/error',
          'params': {'kind': 'lib', 'message': 'x', 'where': 'line 3'},
        },
        FrameErrorMessage,
      ),
      'error unknown kind': (
        {
          'method': 'redgiant/error',
          'params': {'kind': 'boom', 'message': 'x'},
        },
        null,
      ),
      'error too long': (
        {
          'method': 'redgiant/error',
          'params': {'kind': 'error', 'message': 'x' * 2001},
        },
        null,
      ),
      'bridge ask': (
        {
          'method': 'redgiant/bridge',
          'id': 3,
          'params': {'op': 'ask', 'prompt': 'quanto?'},
        },
        FrameBridgeCall,
      ),
      'bridge files.read binary': (
        {
          'method': 'redgiant/bridge',
          'id': 4,
          'params': {'op': 'files.read', 'path': 'a.csv', 'as': 'binary'},
        },
        FrameBridgeCall,
      ),
      'bridge unknown op': (
        {
          'method': 'redgiant/bridge',
          'id': 3,
          'params': {'op': 'exec'},
        },
        null,
      ),
      'bridge id fractional': (
        {
          'method': 'redgiant/bridge',
          'id': 1.5,
          'params': {'op': 'storage.list'},
        },
        null,
      ),
      'open a link (not a FrameMessage)': ({'method': 'ui/open-link'}, null),
      'not a map': ('ui/message', null),
    };
    for (final e in table.entries) {
      test(e.key, () {
        final m = parseFrameMessage(e.value.$1);
        expect(m?.runtimeType, e.value.$2);
      });
    }
    test('the text to send: joined, trimmed, at most 4000', () {
      String? text(List<String> parts) => frameMessageText(FrameUiMessage(parts));
      expect(text(['a', ' b ']), 'a\n b');
      expect(text(['  ']), isNull);
      expect(text(['x' * 4000]), 'x' * 4000);
      expect(text(['x' * 4001]), isNull);
    });
    test('a bridge call of the wrong shape gets an error back, never the server', () {
      expect(
        bridgeRejection({
          'method': 'redgiant/bridge',
          'id': 2,
          'params': {'op': 'nope'},
        })?.error['code'],
        'bad_request',
      );
      expect(
        bridgeRejection({
          'method': 'redgiant/bridge',
          'id': 2,
          'params': {'op': 'storage.set', 'key': 'k', 'value': 'x' * (kArtifactStorageMax + 1)},
        })?.error['code'],
        'too_big',
      );
      expect(
        bridgeRejection({
          'method': 'redgiant/bridge',
          'id': 2,
          'params': {'op': 'storage.list'},
        }),
        isNull,
      );
      expect(bridgeRejection({'method': 'redgiant/bridge', 'id': -1, 'params': {}}), isNull);
      expect(bridgeRejection({'method': 'ui/message'}), isNull);
    });
    test('links a frame wants to open: http(s) only', () {
      expect(
        previewLinkOf({'redgiant': 'open-link', 'url': 'https://example.com/a'}),
        Uri.parse('https://example.com/a'),
      );
      expect(previewLinkOf({'redgiant': 'open-link', 'url': 'javascript:alert(1)'}), isNull);
      expect(previewLinkOf({'redgiant': 'open-link', 'url': 'file:///etc/passwd'}), isNull);
      expect(previewLinkOf({'redgiant': 'other', 'url': 'https://x'}), isNull);
    });
  });

  group('the click rule (ARTIFACT_CLICK_MS)', () {
    test('one message within 1.5 s of a click, one per click', () {
      var now = 0;
      final g = ClickGuard(() => now);
      expect(g.take(focused: false, activated: false), isFalse);
      g.clicked();
      now += 1400;
      expect(g.take(focused: true, activated: false), isTrue);
      expect(g.take(focused: true, activated: false), isFalse);
      g.clicked();
      now += 1600;
      expect(g.take(focused: true, activated: false), isFalse);
    });
    test('focus already in the frame: the user activation counts once in 5 s', () {
      var now = 0;
      final g = ClickGuard(() => now);
      expect(g.take(focused: true, activated: true), isTrue);
      now += 2000;
      expect(g.take(focused: true, activated: true), isFalse);
      now += 3500;
      expect(g.take(focused: true, activated: true), isTrue);
      now += 6000;
      expect(g.take(focused: false, activated: true), isFalse);
      expect(g.take(focused: true, activated: false), isFalse);
    });
  });

  group('the wrapper and the relay (pure)', () {
    test('only messages with this load\'s nonce count', () {
      expect(frameEventOf(jsonEncode({'n': 'N', 'k': 'click'}), 'N'), isA<FrameClicked>());
      expect(frameEventOf(jsonEncode({'n': 'N', 'k': 'load'}), 'N'), isA<FrameLoaded>());
      final m = frameEventOf(
        jsonEncode({'n': 'N', 'k': 'msg', 'd': 1, 'f': true, 'a': false}),
        'N',
      );
      expect(m, isA<FramePosted>());
      expect((m! as FramePosted).focused, isTrue);
      expect(frameEventOf(jsonEncode({'n': 'X', 'k': 'click'}), 'N'), isNull);
      expect(frameEventOf(jsonEncode({'k': 'click'}), 'N'), isNull);
      expect(frameEventOf('{nope', 'N'), isNull);
      expect(frameEventOf(jsonEncode({'n': '', 'k': 'click'}), ''), isNull);
    });
    test('the server\'s policy with the relay\'s origin (who frames it, its libraries)', () {
      const csp =
          "sandbox allow-scripts allow-forms; default-src 'none'; script-src 'unsafe-inline' "
          "'unsafe-eval' http://h:7650/preview/T/lib/ https://h:7650/preview/T/lib/; "
          "connect-src 'none'; frame-ancestors http://h:7650 https://h:7650";
      expect(
        relayCsp(csp, 'http://127.0.0.1:5000'),
        "sandbox allow-scripts allow-forms; default-src 'none'; script-src 'unsafe-inline' "
        "'unsafe-eval' http://127.0.0.1:5000/preview/T/lib/; connect-src 'none'; "
        'frame-ancestors http://127.0.0.1:5000',
      );
    });
    test('the wrapper: the sandbox, its nonce, frames only its own preview', () {
      final p = frameWrapperPage(
        src: 'http://127.0.0.1:5000/preview/TOK/widget.html',
        origin: 'http://127.0.0.1:5000',
        nonce: 'NONCE1',
        title: 'Rata "mutuo" <b>',
      );
      expect(p.body, contains('sandbox="allow-scripts allow-forms"'));
      expect(p.body, contains('title="Rata &quot;mutuo&quot; &lt;b&gt;"'));
      expect(p.body, contains('<script nonce="NONCE1">'));
      final csp = p.headers['Content-Security-Policy']!;
      expect(csp, contains("script-src 'nonce-NONCE1'"));
      expect(csp, contains('frame-src http://127.0.0.1:5000/preview/TOK/;'));
      expect(csp, contains("frame-ancestors 'none'"));
      expect(csp, isNot(contains('connect-src *')));
    });
    test('where the web view may go', () {
      final wrapper = Uri.parse('http://127.0.0.1:5000/rg-frame/F');
      final preview = Uri.parse('http://127.0.0.1:5000/preview/TOK/widget.html');
      final table = <(String, bool), bool>{
        ('http://127.0.0.1:5000/rg-frame/F', true): true,
        ('http://127.0.0.1:5000/rg-frame/G', true): false,
        ('http://127.0.0.1:5000/preview/TOK/widget.html', true): false,
        ('https://example.com/', true): false,
        ('http://127.0.0.1:5000/preview/TOK/widget.html', false): true,
        ('http://127.0.0.1:5000/preview/TOK/lib/x.js', false): true,
        ('http://127.0.0.1:5000/preview/OTHER/widget.html', false): false,
        ('http://127.0.0.1:5001/preview/TOK/widget.html', false): false,
        ('https://example.com/preview/TOK/', false): false,
        ('about:blank', false): false,
      };
      for (final e in table.entries) {
        expect(
          frameNavigationAllowed(
            Uri.parse(e.key.$1),
            mainFrame: e.key.$2,
            wrapper: wrapper,
            preview: preview,
          ),
          e.value,
          reason: '${e.key}',
        );
      }
      // 3.8.11, Linux: WebKitGTK says «main frame» for every navigation; the wrapper or the
      // preview's pages pass whoever asks, nothing else does.
      final anyFrame = <String, bool>{
        'http://127.0.0.1:5000/rg-frame/F': true,
        'http://127.0.0.1:5000/preview/TOK/widget.html': true,
        'http://127.0.0.1:5000/preview/TOK/lib/x.js': true,
        'http://127.0.0.1:5000/rg-frame/G': false,
        'http://127.0.0.1:5000/preview/OTHER/widget.html': false,
        'http://127.0.0.1:5001/preview/TOK/widget.html': false,
        'https://example.com/': false,
        'about:blank': false,
      };
      for (final e in anyFrame.entries) {
        expect(
          frameNavigationAllowedAnyFrame(Uri.parse(e.key), wrapper: wrapper, preview: preview),
          e.value,
          reason: e.key,
        );
      }
    });
    test('preview links', () {
      expect(previewTokenOf('/preview/abc/widget.html'), 'abc');
      expect(previewTokenOf('/preview/abc/sub/x.html'), 'abc');
      expect(previewTokenOf('/preview//x'), isNull);
      expect(previewTokenOf('/preview/abc'), isNull);
      expect(previewTokenOf('https://evil/preview/abc/x'), isNull);
      expect(previewTokenOf('/api/preview/abc/x'), isNull);
    });
    test('where frames run', () {
      final table = <(DevicePlatform, TransportKind?), FrameSupport>{
        (DevicePlatform.android, TransportKind.pinnedHttps): FrameSupport.webView,
        (DevicePlatform.ios, TransportKind.publicHttps): FrameSupport.webView,
        (DevicePlatform.macos, TransportKind.loopback): FrameSupport.webView,
        (DevicePlatform.windows, TransportKind.loopback): FrameSupport.windows,
        (DevicePlatform.windows, TransportKind.pinnedHttps): FrameSupport.windows,
        (DevicePlatform.linux, TransportKind.loopback): FrameSupport.linux,
        (DevicePlatform.linux, TransportKind.channel): FrameSupport.none,
        (DevicePlatform.android, TransportKind.channel): FrameSupport.none,
        (DevicePlatform.android, null): FrameSupport.none,
      };
      for (final e in table.entries) {
        expect(frameSupportFor(e.key.$1, e.key.$2), e.value, reason: '${e.key}');
      }
    });
    test('the theme as frames get it', () {
      final c = hostContext(
        {'bg': '#15171c', 'accent': '#ef4b3a', 'nope': 'x'},
        dark: true,
        locale: 'it',
        font: 'system-ui',
      );
      expect(c['theme'], 'dark');
      expect(c['locale'], 'it');
      expect((c['styles']! as Map)['variables'], {
        '--rg-bg': '#15171c',
        '--rg-accent': '#ef4b3a',
        '--rg-font': 'system-ui',
      });
    });
    test('errors: deduplicated, at most 20', () {
      const a = ArtifactErrorInfo(kind: 'error', message: 'a');
      var kept = addErrors([], [a, a]);
      expect(kept, [a]);
      kept = addErrors(kept, [
        for (var i = 0; i < 30; i++) ArtifactErrorInfo(kind: 'console', message: '$i'),
      ]);
      expect(kept.length, 20);
    });
  });

  group('FrameSession', () {
    late List<Map<String, Object?>> posted;
    late List<String> said;
    FrameSession session({
      Map<String, Object?> ref = const {'kind': 'widget', 'sessionId': 's1', 'seq': 3, 'index': 0},
      String? sessionId = 's1',
      int Function()? now,
      bool Function(Map<String, Object?>)? bridge,
      List<(List<ArtifactErrorInfo>, bool)>? reported,
      List<double>? heights,
    }) {
      posted = [];
      said = [];
      return FrameSession(
        nonce: 'N',
        ref: ref,
        sessionId: sessionId,
        auto: true,
        guard: ClickGuard(now),
        postToFrame: posted.add,
        hostContext: () => {'theme': 'light'},
        onHeight: heights?.add,
        onSend: (to, t) => said.add('send $to $t'),
        onAsk: (t) => said.add('ask $t'),
        reportErrors: (b, {required fresh}) => reported?.add((b, fresh)),
        sendBridge: bridge,
        flushAfter: const Duration(milliseconds: 1),
      );
    }

    String msg(Object? d, {bool f = false, bool a = false}) =>
        jsonEncode({'n': 'N', 'k': 'msg', 'd': d, 'f': f, 'a': a});

    test('«send to chat»: at once after a click, otherwise it asks', () {
      var now = 0;
      final s = session(now: () => now);
      s.handle(msg(uiMessage('Rata 480')));
      expect(said, ['ask Rata 480']);
      s.handle(jsonEncode({'n': 'N', 'k': 'click'}));
      now += 500;
      s.handle(msg(uiMessage('Rata 500')));
      expect(said.last, 'send s1 Rata 500');
      // The frame calling the channel by itself, without the nonce: nothing.
      s.handle(jsonEncode({'k': 'click'}));
      s.handle(jsonEncode({'k': 'msg', 'd': uiMessage('finto')}));
      expect(said.length, 2);
    });
    test('without a conversation it always asks', () {
      final s = session(sessionId: null);
      s.handle(jsonEncode({'n': 'N', 'k': 'click'}));
      s.handle(msg(uiMessage('x')));
      expect(said, ['ask x']);
    });
    test('height, theme at load and at «initialized», errors flushed and forgotten', () async {
      final reported = <(List<ArtifactErrorInfo>, bool)>[];
      final heights = <double>[];
      final s = session(reported: reported, heights: heights);
      s.handle(jsonEncode({'n': 'N', 'k': 'load'}));
      expect(posted.single['method'], 'ui/notifications/host-context-changed');
      s.handle(msg({'method': 'ui/notifications/initialized'}));
      expect(reported.single.$2, isTrue);
      s.handle(
        msg({
          'method': 'ui/notifications/size-changed',
          'params': {'height': 3.2},
        }),
      );
      s.handle(
        msg({
          'method': 'ui/notifications/size-changed',
          'params': {'height': 180.2},
        }),
      );
      expect(heights, [24, 181]);
      final err = {
        'method': 'redgiant/error',
        'params': {'kind': 'error', 'message': 'boom'},
      };
      s.handle(msg(err));
      s.handle(msg(err));
      await Future<void>.delayed(const Duration(milliseconds: 20));
      expect(reported.length, 2);
      expect(reported.last.$1.single.message, 'boom');
      expect(s.errors.length, 1);
      s.handle(msg({'method': 'ui/notifications/initialized'}));
      expect(s.errors, isEmpty);
      s.close();
    });
    test('a widget has no bridge; an artifact\'s calls go to the server and come back', () {
      final s = session();
      s.handle(
        msg({
          'method': 'redgiant/bridge',
          'id': 7,
          'params': {'op': 'storage.list'},
        }),
      );
      expect(posted.last['id'], 7);
      expect((posted.last['error']! as Map)['code'], 'unavailable');

      final out = <Map<String, Object?>>[];
      final a = session(
        ref: const {'kind': 'file', 'scope': 'p1', 'path': 'artefatti/conti.html'},
        bridge: (m) {
          out.add(m);
          return true;
        },
      );
      a.handle(
        msg({
          'method': 'redgiant/bridge',
          'id': 8,
          'params': {'op': 'storage.get', 'key': 'k', 'junk': 1},
        }),
      );
      expect(out.single['type'], 'artifact.bridge');
      expect(out.single['call'], {'op': 'storage.get', 'key': 'k'});
      a.bridgeResult({
        'type': 'artifact.bridge.result',
        'requestId': out.single['requestId'],
        'result': {'value': 'v'},
      });
      expect(posted.last, {
        'jsonrpc': '2.0',
        'method': 'redgiant/bridge-result',
        'id': 8,
        'result': {'value': 'v'},
      });
      // Wrong shape: an error back at once, nothing to the server.
      a.handle(
        msg({
          'method': 'redgiant/bridge',
          'id': 9,
          'params': {'op': 'x'},
        }),
      );
      expect((posted.last['error']! as Map)['code'], 'bad_request');
      expect(out.length, 1);
      // Not connected.
      final b = session(
        ref: const {'kind': 'file', 'scope': 'p', 'path': 'a.html'},
        bridge: (_) => false,
      );
      b.handle(
        msg({
          'method': 'redgiant/bridge',
          'id': 1,
          'params': {'op': 'storage.list'},
        }),
      );
      expect((posted.last['error']! as Map)['message'], 'RedGiant is not connected');
      a.close();
      b.close();
      s.close();
    });
  });

  group('the relay, with real sockets', () {
    late HttpServer upstream;
    final seen = <HttpRequest>[];
    setUp(() async {
      HttpOverrides.global = null;
      seen.clear();
      upstream = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
      upstream.listen((r) async {
        seen.add(r);
        r.response.headers
          ..contentType = ContentType.html
          ..set(
            'content-security-policy',
            'sandbox allow-scripts allow-forms; frame-ancestors http://127.0.0.1:${upstream.port}',
          )
          ..set('x-secret-header', 'no');
        r.response.write('<p>widget ${r.uri.path}</p>');
        await r.response.close();
      });
    });
    tearDown(() => upstream.close(force: true));

    Future<({int status, String body, HttpHeaders headers})> get(
      Uri u, {
      String method = 'GET',
      String? host,
    }) async {
      final c = HttpClient();
      try {
        final q = await c.openUrl(method, u);
        if (host != null) q.headers.host = host;
        final a = await q.close();
        return (status: a.statusCode, body: await utf8.decodeStream(a), headers: a.headers);
      } finally {
        c.close(force: true);
      }
    }

    test('serves the wrapper, passes on only its own previews, never the token', () async {
      final relay = await PreviewRelay.forServer(Uri.parse('http://127.0.0.1:${upstream.port}'));
      final f = relay.open('/preview/TOK/widget.html', title: 'Rata');
      final w = await get(f.wrapper);
      expect(w.status, 200);
      expect(w.body, contains(f.nonce));
      expect(w.body, contains('src="${relay.origin}/preview/TOK/widget.html"'));
      expect(w.headers.value('content-security-policy'), contains("frame-ancestors 'none'"));

      final p = await get(f.preview);
      expect(p.status, 200);
      expect(p.body, '<p>widget /preview/TOK/widget.html</p>');
      expect(
        p.headers.value('content-security-policy'),
        'sandbox allow-scripts allow-forms; frame-ancestors ${relay.origin}',
      );
      expect(p.headers.value('x-secret-header'), isNull);
      expect(seen.single.headers.value('authorization'), isNull);

      expect((await get(Uri.parse('${relay.origin}/preview/OTHER/widget.html'))).status, 404);
      expect((await get(Uri.parse('${relay.origin}/api/agents'))).status, 404);
      expect((await get(f.preview, method: 'POST')).status, 405);
      expect((await get(f.preview, host: 'evil.example')).status, 421);
      f.release();
      expect((await get(f.wrapper)).status, 404);
      expect((await get(f.preview)).status, 404);
      expect(seen.length, 1);
      relay.close();
    });
    test('plain http over the network: no relay', () async {
      await expectLater(
        PreviewRelay.forServer(Uri.parse('http://192.168.1.20:7650')),
        throwsA(isA<TransportException>()),
      );
    });
  });

  group('in the app', () {
    late FakeRedGiant server;
    late AppController app;
    late FakeFrameHost host;
    setUp(() async {
      HttpOverrides.global = null;
      server = await FakeRedGiant.start();
      server.extraJson['GET /api/sessions/s1/widgets/3/0/link'] = {
        'url': '/preview/tokW/widget.html',
      };
      server.extraJson['POST /api/sessions/s1/widgets/3/0/keep'] = {
        'scope': 'p1',
        'path': 'artefatti/mutuo.html',
      };
      server.extraJson['POST /api/artifacts/errors'] = {'added': 1};
      server.extraJson['POST /api/canvas/link'] = {
        'url': '/preview/tokA/conti.html',
        'artifact': true,
      };
      host = FakeFrameHost();
      debugFrameHost = (_) => host;
      debugFrameOpener = (app, path, title) async => RelayFrame(
        id: 'F',
        wrapper: Uri.parse('http://127.0.0.1:1/rg-frame/F'),
        preview: Uri.parse('http://127.0.0.1:1$path'),
        nonce: 'NONCE',
      );
    });
    tearDown(() {
      debugFrameHost = null;
      debugFrameOpener = null;
      debugFrameSupport = null;
      return server.close();
    });

    Future<void> settle(WidgetTester tester) async {
      for (var i = 0; i < 6; i++) {
        await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 30)));
        await tester.pump(const Duration(milliseconds: 50));
      }
    }

    Future<void> open(
      WidgetTester tester, {
      DevicePlatform platform = DevicePlatform.android,
    }) async {
      app = AppController(tokens: MemoryTokenStore(), prefs: MemoryAppPrefs(), platform: platform)
        ..locale = const Locale('it');
      await tester.runAsync(() => app.connect(server.base.toString(), 'secret'));
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(RGCompanionApp(controller: app));
      await settle(tester);
      tester
          .state<NavigatorState>(find.byType(Navigator).first)
          .push(
            MaterialPageRoute<void>(
              builder: (_) => ConversationScreen(sessionId: 's1', agent: app.agents.first),
            ),
          )
          .ignore();
      await settle(tester);
    }

    Future<void> done(WidgetTester tester) async {
      await tester.pumpWidget(const SizedBox());
      await tester.pump(const Duration(minutes: 3));
    }

    const answer = 'Ecco il calcolo:\n\n```widget Mutuo\n<div>rata 480 €</div>\n```\n\nFine.';

    testWidgets('a widget in an answer: written as a line, then its frame', (tester) async {
      await open(tester);
      server.streamPiece('s1', 'Ecco il calcolo:\n\n```widget Mutuo\n<div>rata');
      await settle(tester);
      expect(find.textContaining('Sto preparando un widget', findRichText: true), findsOneWidget);
      expect(find.textContaining('<div>', findRichText: true), findsNothing);
      expect(find.byKey(const Key('stream-cursor')), findsOneWidget);
      server.streamEnd('s1', answer);
      await settle(tester);
      expect(find.byKey(const Key('widget-3.0')), findsOneWidget);
      expect(find.textContaining('Fine.', findRichText: true), findsWidgets);
      expect(find.textContaining('<div>', findRichText: true), findsNothing);
      expect(host.loaded?.preview.path, '/preview/tokW/widget.html');
      expect(host.eager, isFalse);

      // Loaded: the theme (light, Italian); then its height.
      host.emit({'k': 'load'});
      host.post({'jsonrpc': '2.0', 'method': 'ui/notifications/initialized', 'params': {}});
      await settle(tester);
      final theme = host.posted.firstWhere(
        (m) => m['method'] == 'ui/notifications/host-context-changed',
      );
      expect((theme['params'] as Map)['locale'], 'it');
      expect(
        ((theme['params'] as Map)['styles'] as Map)['variables'],
        containsPair('--rg-accent', '#d23a2c'),
      );
      host.post({
        'method': 'ui/notifications/size-changed',
        'params': {'height': 212},
      });
      await settle(tester);
      expect(tester.getSize(find.byKey(const Key('artifact-frame-view'))).height, 212);
      // Taller than 70% of the screen: it stops there, then scrolls inside.
      host.post({
        'method': 'ui/notifications/size-changed',
        'params': {'height': 5000},
      });
      await settle(tester);
      expect(
        tester.getSize(find.byKey(const Key('artifact-frame-view'))).height,
        closeTo(844 * 0.7, 0.01),
      );

      // «Manda alla chat» without a click: it waits under the widget.
      host.post(uiMessage('Rata con 25 anni'));
      await settle(tester);
      expect(find.byKey(const Key('artifact-ask')), findsOneWidget);
      expect(find.text('Vuole mandare in chat:'), findsOneWidget);
      await tester.tap(find.byKey(const Key('artifact-ask-send')));
      await settle(tester);
      expect(find.byKey(const Key('artifact-ask')), findsNothing);
      var sent = server.received.where((m) => m['type'] == 'session.send').toList();
      expect(sent.last, containsPair('via', 'artifact'));
      expect(sent.last['text'], 'Rata con 25 anni');

      // After a click in the frame: at once.
      host.click();
      host.post(uiMessage('Rata con 30 anni'));
      await settle(tester);
      expect(find.byKey(const Key('artifact-ask')), findsNothing);
      sent = server.received.where((m) => m['type'] == 'session.send').toList();
      expect(sent.last['text'], 'Rata con 30 anni');

      // Someone else's message (wrong nonce): nothing.
      host.emit({'k': 'msg', 'd': uiMessage('finto')}, nonce: 'other');
      await settle(tester);
      expect(find.byKey(const Key('artifact-ask')), findsNothing);

      // An error: counted on the card, and sent on for the agent.
      host.post({
        'method': 'redgiant/error',
        'params': {'kind': 'error', 'message': 'x is not defined', 'where': 'line 2'},
      });
      await settle(tester);
      await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 500)));
      await settle(tester);
      // The two turns above pushed it up out of sight: it stayed loaded (kept alive), scroll back.
      await tester.ensureVisible(find.byKey(const Key('widget-3.0'), skipOffstage: false));
      await settle(tester);
      expect(find.text('1 errore'), findsOneWidget);
      expect(
        server.requests.where((r) => r == 'POST /api/artifacts/errors').length,
        greaterThanOrEqualTo(2),
      );
      await done(tester);
    });

    testWidgets('«Tienilo» keeps it and opens the Canvas, where the artifact runs', (tester) async {
      // G42.6: the Canvas is the page inside the app (embed=canvas), the artifact runs there.
      final pages = <Uri>[];
      debugWebHost = (_) => _Page(pages);
      addTearDown(() => debugWebHost = null);
      await open(tester);
      server.streamEnd('s1', answer);
      await settle(tester);
      await tester.tap(find.byKey(const Key('widget-keep')));
      await settle(tester);
      expect(server.requests, contains('POST /api/sessions/s1/widgets/3/0/keep'));
      expect(find.byKey(const Key('canvas-screen')), findsOneWidget);
      final p = parseEmbedHash(pages.last.fragment)!;
      expect(
        '${p.embed.name} ${p.scope} ${p.path} ${p.session}',
        'canvas p1 artefatti/mutuo.html s1',
      );
      expect(find.byKey(const Key('canvas-artifact')), findsNothing);
      await done(tester);
    });

    testWidgets('Linux (G42.0): the widget in its frame, WebKitGTK', (tester) async {
      await open(tester, platform: DevicePlatform.linux);
      server.streamEnd('s1', answer);
      await settle(tester);
      expect(find.byKey(const Key('widget-fallback')), findsNothing);
      expect(host.loaded?.wrapper.toString(), 'http://127.0.0.1:1/rg-frame/F');
      // 3.8.11: WebKitGTK's native view follows rectangles and rounded rectangles only; under a
      // path clip touching it (the decoration's clip of a Container) the plugin hides it, and the
      // widget showed an empty frame.
      final paths = <String>[];
      for (
        RenderObject? r = tester.renderObject(find.byKey(const Key('artifact-frame-view')));
        r != null;
        r = r.parent
      ) {
        if (r is RenderClipPath || r is RenderClipRSuperellipse || r is RenderPhysicalShape) {
          paths.add(r.runtimeType.toString());
        }
      }
      expect(paths, isEmpty, reason: 'no path clip above the widget on Linux');
      expect(
        find.ancestor(
          of: find.byKey(const Key('artifact-frame-view')),
          matching: find.byType(ClipRRect),
        ),
        findsWidgets,
        reason: 'the frame keeps its rounded corners with a clip the native view follows',
      );
      await done(tester);
    });

    testWidgets('no safe way to the server: the words and «Apri nella pagina», no frame', (
      tester,
    ) async {
      debugFrameSupport = (_) => FrameSupport.none;
      await open(tester, platform: DevicePlatform.linux);
      server.streamEnd('s1', answer);
      await settle(tester);
      expect(find.byKey(const Key('widget-fallback')), findsOneWidget);
      expect(find.text('rata 480 €'), findsOneWidget);
      expect(find.text('Apri nella pagina'), findsOneWidget);
      expect(host.loaded, isNull);
      expect(server.requests.where((r) => r.contains('/widgets/')), isEmpty);
      await done(tester);
    });

    testWidgets('Canvas with no safe way: an artifact shows its source and «Apri nella pagina»', (
      tester,
    ) async {
      debugFrameSupport = (_) => FrameSupport.none;
      await open(tester, platform: DevicePlatform.linux);
      unawaited(
        openCanvas(
          tester.element(find.byType(ConversationScreen)),
          scope: 'p1',
          path: 'artefatti/conti.html',
        ),
      );
      await settle(tester);
      expect(find.byKey(const Key('artifact-open-page')), findsOneWidget);
      expect(find.byKey(const Key('canvas-text')), findsOneWidget);
      expect(host.loaded, isNull);
      await done(tester);
    });
  });
}

/// The page inside the app (G42.6): only where it was loaded.
class _Page implements WebHost {
  _Page(this.loaded);

  final List<Uri> loaded;

  @override
  Stream<String> get messages => const Stream.empty();

  @override
  Future<void> load(Uri url, WebRules r) async => loaded.add(url);

  @override
  Future<void> run(String script) async {}

  @override
  Future<void> reload() async {}

  @override
  Widget view({required bool eager}) => const SizedBox.expand();

  @override
  void dispose() {}
}

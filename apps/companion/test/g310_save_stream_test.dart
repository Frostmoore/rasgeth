// 3.10: «Save as…» in the app written to disk as it comes (the finished video, the XML for
// Resolve, the Canvas bar's «Download»), never whole in memory. The transport writes a file chunk
// by chunk with its progress and stops on «Annulla»; on a computer the system's window first, the
// download into a part beside the destination, then a rename (nothing left behind; a stopped one
// removes the empty file the window wrote); on a phone the app's temporary folder, then the
// system's save; the bar with how much, how fast, how long and «Annulla».
import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rgcompanion/api/servers.dart';
import 'package:rgcompanion/api/token_store.dart';
import 'package:rgcompanion/api/transport.dart';
import 'package:rgcompanion/api/types.dart';
import 'package:rgcompanion/app.dart';
import 'package:rgcompanion/app_state.dart';
import 'package:rgcompanion/embed/embed_link.dart';
import 'package:rgcompanion/embed/web_host.dart';
import 'package:rgcompanion/screens/conversation_screen.dart';
import 'package:rgcompanion/ui/chat/file_download.dart';

import 'fake_server.dart';

/// A web view of the test's own: what it loaded, the scripts run in it, and the page's voice.
class _Host implements WebHost {
  _Host(this.all);

  final List<_Host> all;
  final out = StreamController<String>.broadcast();
  final scripts = <String>[];
  Uri? loaded;

  EmbedParams get params => parseEmbedHash(loaded!.fragment)!;

  void say(Map<String, Object?> m) =>
      out.add(jsonEncode({'rg': 'embed', 'n': params.bridge, 'm': m}));

  /// The app's messages to the page, decoded.
  List<Map<String, dynamic>> get told => [
    for (final s in scripts)
      if (s.startsWith('window.postMessage('))
        (jsonDecode(s.substring('window.postMessage('.length, s.lastIndexOf(', location.origin')))
                as Map<String, dynamic>)['m']
            as Map<String, dynamic>,
  ];

  @override
  Stream<String> get messages => out.stream;

  @override
  Future<void> load(Uri url, WebRules r) async {
    loaded = url;
    all.add(this);
  }

  @override
  Future<void> run(String script) async => scripts.add(script);

  @override
  Future<void> reload() async {}

  @override
  Widget view({required bool eager}) => const SizedBox.expand(key: Key('fake-web'));

  @override
  void dispose() {}
}

Future<void> _settle(WidgetTester tester, [int rounds = 6]) async {
  for (var i = 0; i < rounds; i++) {
    await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 30)));
    await tester.pump(const Duration(milliseconds: 50));
  }
}

const _video = {'kind': 'file', 'scope': 'platform', 'path': 'video/gita.rgvideo'};
const _chunk = 64 * 1024;

/// A file of [chunks] pieces, each byte its piece's number (to check the order).
List<int> _piece(int i) => List<int>.filled(_chunk, i % 251);

/// Serves [chunks] pieces with [gap] between them, its length said.
Future<void> _serve(HttpRequest r, int chunks, {Duration gap = Duration.zero}) async {
  r.response.headers.contentType = ContentType('video', 'mp4');
  r.response.contentLength = chunks * _chunk;
  for (var i = 0; i < chunks; i++) {
    r.response.add(_piece(i));
    await r.response.flush();
    if (gap > Duration.zero) await Future<void>.delayed(gap);
  }
  await r.response.close();
}

void main() {
  group('the transport writes to a file', () {
    late HttpServer http;
    late Directory dir;
    var gap = Duration.zero;
    setUp(() async {
      dir = await Directory.systemTemp.createTemp('rg-save-');
      http = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
      http.listen((r) async {
        if (r.uri.path == '/missing') {
          r.response.statusCode = 404;
          r.response.headers.contentType = ContentType.json;
          r.response.write(jsonEncode({'error': 'Not found'}));
          return r.response.close();
        }
        await _serve(r, 48, gap: gap).catchError((_) {});
      });
    });
    tearDown(() async {
      await http.close(force: true);
      await dir.delete(recursive: true);
    });
    HttpTransport transport() => HttpTransport(Uri.parse('http://127.0.0.1:${http.port}'));

    test('chunk by chunk, with its progress; no bytes kept in the answer', () async {
      gap = const Duration(milliseconds: 3);
      final out = File('${dir.path}/a.mp4');
      final seen = <(int, int?)>[];
      final r = await transport().downloadTo('/v.mp4', out, onProgress: (g, t) => seen.add((g, t)));
      expect(r.status, 200);
      expect(r.bytes, isEmpty);
      final bytes = await out.readAsBytes();
      expect(bytes.length, 48 * _chunk);
      expect(bytes[47 * _chunk], 47 % 251);
      expect(seen.first, (0, 48 * _chunk));
      expect(seen.last, (48 * _chunk, 48 * _chunk));
      expect(seen.length, greaterThan(3), reason: 'the progress moves while it comes');
    });

    test('«Annulla» stops it; a refusal comes back with its body', () async {
      gap = const Duration(milliseconds: 20);
      final out = File('${dir.path}/b.mp4');
      final cancel = DownloadCancel();
      await expectLater(
        transport().downloadTo(
          '/v.mp4',
          out,
          cancel: cancel,
          onProgress: (g, _) {
            if (g >= 4 * _chunk) cancel.cancel();
          },
        ),
        throwsA(isA<DownloadCancelled>()),
      );
      expect(await out.length(), lessThan(48 * _chunk));
      final r = await transport().downloadTo('/missing', File('${dir.path}/c'));
      expect(r.status, 404);
      expect(r.text, contains('Not found'));
      expect(File('${dir.path}/c').existsSync(), isFalse);
    });
  });

  late FakeRedGiant server;
  late AppController app;
  late List<_Host> hosts;
  late Directory dir;

  setUp(() async {
    HttpOverrides.global = null;
    server = await FakeRedGiant.start();
    server.permissions.clear();
    hosts = [];
    debugWebHost = (_) => _Host(hosts);
    dir = await Directory.systemTemp.createTemp('rg-saveas-');
  });
  tearDown(() async {
    debugWebHost = null;
    debugPickSavePath = null;
    debugPhoneSave = null;
    debugSaveTempDir = null;
    await server.close();
    await dir.delete(recursive: true);
  });

  Future<void> open(WidgetTester tester, DevicePlatform platform, Size size) async {
    app = AppController(tokens: MemoryTokenStore(), prefs: MemoryAppPrefs(), platform: platform)
      ..locale = const Locale('it');
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

  Future<_Host> show(WidgetTester tester) async {
    server.store('s1', 'canvas.show', {'title': 'gita.rgvideo', 'target': _video});
    await _settle(tester);
    final h = hosts.last;
    h
      ..say({'t': 'ready'})
      ..say({'t': 'title', 'name': 'gita.rgvideo', 'kind': 'timeline'});
    await _settle(tester);
    return h;
  }

  const link = '/api/canvas/raw/abc/finale.mp4';

  testWidgets('a computer: the window, the bar while it comes, then the file where chosen', (
    tester,
  ) async {
    server.routes['GET $link'] = (r) => _serve(r, 40, gap: const Duration(milliseconds: 15));
    final dest = '${dir.path}${Platform.pathSeparator}finale.mp4';
    debugPickSavePath = (name) async {
      // As file_picker does: the name written empty first.
      await File(dest).writeAsBytes(const []);
      return dest;
    };
    await open(tester, DevicePlatform.windows, const Size(1400, 900));
    final h = await show(tester);
    h.say({'t': 'saveAs', 'name': 'finale.mp4', 'url': link});
    var barSeen = false;
    bool there() => File(dest).existsSync() && File(dest).lengthSync() == 40 * _chunk;
    for (var i = 0; i < 120 && !there(); i++) {
      await _settle(tester, 1);
      if (find.byKey(const Key('download-progress')).evaluate().isNotEmpty) barSeen = true;
    }
    await _settle(tester, 4);
    expect(barSeen, isTrue, reason: 'the bar while it comes');
    expect(File(dest).lengthSync(), 40 * _chunk);
    expect(File(dest).readAsBytesSync()[39 * _chunk], 39 % 251);
    expect(dir.listSync().map((e) => e.path.split(Platform.pathSeparator).last), ['finale.mp4']);
    // The bar slides away first, then the next snack bar says it.
    for (var i = 0; i < 4; i++) {
      await tester.pump(const Duration(milliseconds: 500));
    }
    expect(find.text('Salvato: finale.mp4'), findsOneWidget);
    await done(tester);
  });

  testWidgets('«Annulla» under the bar: nothing left, the empty file gone, said', (tester) async {
    // Long enough that a loaded machine never finishes it before «Annulla» is pressed.
    server.routes['GET $link'] = (r) =>
        _serve(r, 4000, gap: const Duration(milliseconds: 20)).catchError((_) {});
    final dest = '${dir.path}${Platform.pathSeparator}finale.mp4';
    debugPickSavePath = (name) async {
      await File(dest).writeAsBytes(const []);
      return dest;
    };
    await open(tester, DevicePlatform.windows, const Size(1400, 900));
    final h = await show(tester);
    h.say({'t': 'saveAs', 'name': 'finale.mp4', 'url': link});
    for (var i = 0; i < 40 && find.byKey(const Key('download-cancel')).evaluate().isEmpty; i++) {
      await _settle(tester, 1);
    }
    expect(find.byKey(const Key('download-words')), findsOneWidget);
    // The bar's «Annulla» (the snack bar may still be sliding in: pressed as a person would).
    tester.widget<TextButton>(find.byKey(const Key('download-cancel'))).onPressed!();
    // Under load the stop and the file's removal take longer: waited for, within a limit.
    for (
      var i = 0;
      i < 60 &&
          (find.text('Salvataggio di finale.mp4 fermato').evaluate().isEmpty ||
              dir.listSync().isNotEmpty);
      i++
    ) {
      await _settle(tester, 1);
    }
    expect(find.text('Salvataggio di finale.mp4 fermato'), findsOneWidget);
    expect(dir.listSync(), isEmpty, reason: 'no part, no empty file');
    await done(tester);
  });

  testWidgets('a phone: into the app\'s temporary folder, then the system\'s save', (tester) async {
    server.routes['GET $link'] = (r) => _serve(r, 8);
    int? handed;
    String? where;
    debugPhoneSave = (name, file) async {
      handed = file.lengthSync();
      where = file.path;
      return true;
    };
    debugSaveTempDir = dir;
    await open(tester, DevicePlatform.android, const Size(400, 860));
    final h = await show(tester);
    h.say({'t': 'saveAs', 'name': 'finale.mp4', 'url': link});
    for (var i = 0; i < 40 && handed == null; i++) {
      await _settle(tester, 1);
    }
    await _settle(tester, 3);
    expect(handed, 8 * _chunk);
    expect(File(where!).existsSync(), isFalse, reason: 'the temporary file removed after');
    await done(tester);
  });
}

// G42.18: the video timeline inside the app. Its keys (J, K, L, I, O, Ctrl+B) passed on to the
// page from the app's part of the Canvas, only for a timeline and never while typing; a file of
// the tree dropped on it handed to the page at the pointer; a render the page started followed in
// the system's notifications (how far, then done or why not); «Ask the agent here» into the
// conversation's composer; the viewer kind's word.
import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rgcompanion/api/code.dart';
import 'package:rgcompanion/api/servers.dart';
import 'package:rgcompanion/api/token_store.dart';
import 'package:rgcompanion/api/types.dart';
import 'package:rgcompanion/app.dart';
import 'package:rgcompanion/app_state.dart';
import 'package:rgcompanion/canvas/canvas_shell.dart';
import 'package:rgcompanion/canvas/job_notices.dart';
import 'package:rgcompanion/embed/bridge.dart';
import 'package:rgcompanion/embed/embed_link.dart';
import 'package:rgcompanion/embed/web_host.dart';
import 'package:rgcompanion/push/notice.dart';
import 'package:rgcompanion/push/system_notifier.dart';
import 'package:rgcompanion/screens/conversation_screen.dart';
import 'package:rgcompanion/screens/files/files_explorer.dart';

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
const _ts = {'kind': 'file', 'scope': 'platform', 'path': 'src/a.ts'};

JobView _job(String state, {List<Map<String, dynamic>> steps = const [], String? why}) =>
    JobView.fromJson({
      'id': 'r1',
      'state': state,
      'kind': 'video_render',
      'steps': steps,
      if (why != null) 'error': {'code': 'x', 'message': why},
    });

void main() {
  final it = wordsFor('it');

  group('the pure parts', () {
    test('a timeline\'s keys: J, K, L, I, O alone, B with Ctrl/Cmd; nothing else', () {
      final table = <(LogicalKeyboardKey, bool, EmbedKey?)>[
        (LogicalKeyboardKey.keyJ, false, EmbedKey.shuttleBack),
        (LogicalKeyboardKey.keyK, false, EmbedKey.pause),
        (LogicalKeyboardKey.keyL, false, EmbedKey.shuttleForward),
        (LogicalKeyboardKey.keyI, false, EmbedKey.markIn),
        (LogicalKeyboardKey.keyO, false, EmbedKey.markOut),
        (LogicalKeyboardKey.keyB, true, EmbedKey.blade),
        (LogicalKeyboardKey.keyB, false, null),
        (LogicalKeyboardKey.keyJ, true, null),
        (LogicalKeyboardKey.keyS, false, null),
        (LogicalKeyboardKey.space, false, null),
      ];
      for (final (k, mod, want) in table) {
        expect(timelineKeyOf(k, mod: mod), want, reason: '${k.keyLabel} mod=$mod');
      }
      expect(embedTimelineKeys, {for (final (_, _, k) in table) ?k});
    });

    test('what a render\'s notification says, from the server\'s job', () {
      final table = <(JobView, String, int?, bool)>[
        (_job('running'), 'Sta per partire…', null, true),
        (
          _job(
            'running',
            steps: [
              {
                'id': 'video_probe',
                'state': 'done',
                'progress': {'done': 3, 'total': 3},
              },
              {
                'id': 'video_render',
                'state': 'running',
                'progress': {'done': 450, 'total': 1000},
              },
            ],
          ),
          '45% fatto',
          45,
          true,
        ),
        (
          _job(
            'running',
            steps: [
              {
                'id': 'video_render',
                'state': 'running',
                'progress': {'done': 1, 'total': 3, 'secondsLeft': 130},
              },
            ],
          ),
          '33% fatto, mancano circa 3 min',
          33,
          true,
        ),
        (_job('done'), 'Fatto: aprilo nel Canvas.', null, false),
        (_job('failed', why: 'ffmpeg exited 1'), 'Non è riuscito: ffmpeg exited 1', null, false),
        (_job('failed'), 'Non è riuscito.', null, false),
        (_job('cancelled'), 'Fermato.', null, false),
      ];
      for (final (j, body, percent, running) in table) {
        final n = jobNotice(j, it);
        expect((n.body, n.percent, n.running), (body, percent, running), reason: j.state);
      }
    });

    test(
      'a render followed: its bar, then done; the same job once; a gone server let go',
      () async {
        final shown = MemoryNotifier();
        final answers = <JobView>[
          _job(
            'running',
            steps: [
              {
                'id': 'video_render',
                'state': 'running',
                'progress': {'done': 2, 'total': 10},
              },
            ],
          ),
          _job('done'),
        ];
        var reads = 0;
        final f = JobNotices(
          notifier: shown,
          fetch: (id) async => answers[(reads++).clamp(0, answers.length - 1)],
          words: () => it,
          serverId: 'srv',
          server: 'Rig',
          every: const Duration(milliseconds: 10),
        );
        f.follow('r1', 'Video di gita.rgvideo', sessionId: 's1');
        f.follow('r1', 'Video di gita.rgvideo');
        await Future<void>.delayed(const Duration(milliseconds: 5));
        final first = shown.shown[f.notificationOf('r1')]!;
        expect(
          (first.title, first.body, first.progress),
          ('Video di gita.rgvideo', '20% fatto', 20),
        );
        expect(first.server, 'Rig');
        expect(NoticeTap.fromPayload(first.payload)?.sessionId, 's1');
        await Future<void>.delayed(const Duration(milliseconds: 60));
        final last = shown.shown[f.notificationOf('r1')]!;
        expect((last.body, last.progress), ('Fatto: aprilo nel Canvas.', null));
        expect(f.follows('r1'), isFalse);
        expect(reads, 2);

        var misses = 0;
        final gone = JobNotices(
          notifier: shown,
          fetch: (_) async {
            misses++;
            throw const SocketException('gone');
          },
          words: () => it,
          serverId: 'srv',
          server: 'Rig',
          every: const Duration(milliseconds: 5),
          giveUpAfter: 3,
        );
        gone.follow('r2', 'x');
        await Future<void>.delayed(const Duration(milliseconds: 80));
        expect(gone.follows('r2'), isFalse);
        expect(misses, 3);
        expect(shown.shown.containsKey(gone.notificationOf('r2')), isFalse);
      },
    );

    test('the bridge: a page\'s job read; a drop sent in the page\'s pixels', () async {
      final scripts = <String>[];
      final jobs = <(String, String)>[];
      final b = EmbedBridge(
        nonce: 'n0nce-n0nce_n0nce',
        handlers: EmbedHandlers(job: (id, t) => jobs.add((id, t))),
        run: (s) async => scripts.add(s),
      );
      b.handle(
        jsonEncode({
          'rg': 'embed',
          'n': 'n0nce-n0nce_n0nce',
          'm': {'t': 'job', 'id': 'r-1', 'title': 'Video'},
        }),
      );
      expect(jobs, [('r-1', 'Video')]);
      await b.drop(scope: 'platform', path: 'v/a.mp4', x: 12.5, y: -3);
      expect(
        scripts.single,
        contains('"t":"drop","scope":"platform","path":"v/a.mp4","x":12.5,"y":0'),
      );
      expect(viewerKindWord(it, 'timeline'), 'Timeline video');
    });
  });

  late FakeRedGiant server;
  late AppController app;
  late List<_Host> hosts;

  setUp(() async {
    HttpOverrides.global = null;
    server = await FakeRedGiant.start();
    server.permissions.clear();
    hosts = [];
    debugWebHost = (_) => _Host(hosts);
  });
  tearDown(() async {
    debugWebHost = null;
    await server.close();
  });

  Future<void> open(WidgetTester tester, Size size) async {
    app = AppController(
      tokens: MemoryTokenStore(),
      prefs: MemoryAppPrefs(),
      platform: size.width < 600 ? DevicePlatform.android : DevicePlatform.windows,
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

  Future<_Host> show(
    WidgetTester tester,
    Map<String, Object> target,
    String name,
    String kind,
  ) async {
    server.store('s1', 'canvas.show', {'title': name, 'target': target});
    await _settle(tester);
    final h = hosts.last;
    h
      ..say({'t': 'ready'})
      ..say({'t': 'title', 'name': name, 'kind': kind, 'size': 1200});
    await _settle(tester);
    return h;
  }

  Future<void> press(WidgetTester tester, LogicalKeyboardKey k, {bool ctrl = false}) async {
    if (ctrl) await tester.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
    await tester.sendKeyEvent(k);
    if (ctrl) await tester.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);
  }

  testWidgets('a timeline: J, K, L, I, O and Ctrl+B go to the page; another file keeps them', (
    tester,
  ) async {
    await open(tester, const Size(1400, 900));
    final h = await show(tester, _video, 'gita.rgvideo', 'timeline');
    expect(find.textContaining('Timeline video', findRichText: true), findsWidgets);
    Focus.of(tester.element(find.byKey(const Key('canvas-bar')))).requestFocus();
    await tester.pump();
    for (final k in [
      LogicalKeyboardKey.keyJ,
      LogicalKeyboardKey.keyK,
      LogicalKeyboardKey.keyL,
      LogicalKeyboardKey.keyI,
      LogicalKeyboardKey.keyO,
    ]) {
      await press(tester, k);
    }
    await press(tester, LogicalKeyboardKey.keyB, ctrl: true);
    await press(tester, LogicalKeyboardKey.keyB);
    await _settle(tester, 2);
    expect(h.told.where((m) => m['t'] == 'key').map((m) => m['key']), [
      'shuttleBack',
      'pause',
      'shuttleForward',
      'markIn',
      'markOut',
      'blade',
    ]);
    final code = await show(tester, _ts, 'a.ts', 'code');
    Focus.of(tester.element(find.byKey(const Key('canvas-bar')))).requestFocus();
    await tester.pump();
    await press(tester, LogicalKeyboardKey.keyJ);
    await press(tester, LogicalKeyboardKey.keyB, ctrl: true);
    await _settle(tester, 2);
    expect(code.told.where((m) => m['t'] == 'key'), isEmpty);
    await done(tester);
  });

  testWidgets('a file of the tree dropped on the timeline: to the page at the pointer', (
    tester,
  ) async {
    await open(tester, const Size(1400, 900));
    final h = await show(tester, _video, 'gita.rgvideo', 'timeline');
    final target = find.byWidgetPredicate((w) => w is DragTarget<ExplorerFileDrag>).last;
    final box = tester.renderObject<RenderBox>(find.byKey(const Key('fake-web')).last);
    final at = box.localToGlobal(const Offset(120, 80));
    final drop = tester.widget<DragTarget<ExplorerFileDrag>>(target);
    drop.onAcceptWithDetails!(
      DragTargetDetails(
        data: const ExplorerFileDrag(
          scope: 'platform',
          path: 'girato/clip 2.mp4',
          name: 'clip 2.mp4',
          size: 9,
        ),
        offset: at,
      ),
    );
    await _settle(tester, 2);
    final m = h.told.where((m) => m['t'] == 'drop').single;
    expect(m['scope'], 'platform');
    expect(m['path'], 'girato/clip 2.mp4');
    expect((m['x'] as num).round(), 120);
    expect((m['y'] as num).round(), 80);
    await done(tester);
  });

  testWidgets('a render started in the tab: the notifications follow it to the end', (
    tester,
  ) async {
    await open(tester, const Size(1400, 900));
    final h = await show(tester, _video, 'gita.rgvideo', 'timeline');
    server.jobs['render1'] = 'running';
    h.say({'t': 'job', 'id': 'render1', 'title': 'Video di gita.rgvideo'});
    await _settle(tester, 4);
    final shown = app.notifier as MemoryNotifier;
    final id = notificationIdOf(app.server!.id, 'job:render1');
    expect(shown.shown[id]?.title, 'Video di gita.rgvideo');
    expect(shown.shown[id]?.body, 'Sta per partire…');
    expect(shown.shown[id]?.progress, -1);
    server.jobs['render1'] = 'done';
    // The follower's next read (its timer runs on the test's clock), then the server's answer.
    await tester.pump(const Duration(milliseconds: 2100));
    await _settle(tester, 4);
    expect(shown.shown[id]?.body, 'Fatto: aprilo nel Canvas.');
    expect(shown.shown[id]?.progress, isNull);
    await done(tester);
  });

  testWidgets('«Ask the agent here» from the timeline: into the composer, with its times', (
    tester,
  ) async {
    await open(tester, const Size(1400, 900));
    final h = await show(tester, _video, 'gita.rgvideo', 'timeline');
    h.say({
      't': 'askAgent',
      'text': 'Accorcia questa parte\n\n[Nel montaggio video/gita.rgvideo, da 00:00:04:00]',
      'ref': {'scope': 'platform', 'path': 'video/gita.rgvideo'},
    });
    await _settle(tester, 3);
    expect(
      find.byWidgetPredicate(
        (w) => w is EditableText && w.controller.text.contains('da 00:00:04:00'),
      ),
      findsOneWidget,
    );
    await done(tester);
  });
}

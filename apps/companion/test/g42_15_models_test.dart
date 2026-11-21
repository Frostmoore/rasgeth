// G42.15: Settings › Models and subscriptions native, against the fake server that answers as the
// real one (test/fake_models.dart): the ways as squares, Claude's sign-in with the code pasted
// back (a wrong code said in words), ChatGPT's device code, an API key tried and refused, the
// person's own server, the default model and who uses which in the one sheet, the model on this
// computer with its download bar, start, on and off, the speed test and delete; and the app's
// copies of the protocol's KEY_PROVIDERS and estimatedSpeed against its vectors.
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rgcompanion/api/servers.dart';
import 'package:rgcompanion/api/token_store.dart';
import 'package:rgcompanion/api/types.dart';
import 'package:rgcompanion/app.dart';
import 'package:rgcompanion/app_state.dart';
import 'package:rgcompanion/screens/server_settings_screen.dart';
import 'package:rgcompanion/settings/models/key_providers.dart';
import 'package:rgcompanion/settings/models/local_speed.dart';
import 'package:rgcompanion/settings/models/models_screen.dart';

import 'fake_models.dart';
import 'fake_server.dart';

Future<void> _settle(WidgetTester tester, [int rounds = 14]) async {
  for (var i = 0; i < rounds; i++) {
    await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 30)));
    await tester.pump();
  }
  await tester.pump(const Duration(milliseconds: 400));
}

void main() {
  final v = jsonDecode(
    File('test/fixtures/models_vectors.json').readAsStringSync(),
  ) as Map<String, dynamic>;

  test('the API keys one can connect, as the protocol has them', () {
    expect(
      [
        for (final p in keyProviders) [p.id, p.name, p.keyExample, p.keyUrl],
      ],
      [
        for (final p in v['keyProviders'] as List)
          [(p as Map)['id'], p['name'], p['keyExample'], p['keyUrl']],
      ],
    );
  });

  test('the estimated speed of a local model, as the protocol says it', () {
    for (final s in v['speeds'] as List) {
      final m = (s as Map)['m'] as Map;
      final hw = s['hw'] as Map;
      final out = s['out'] as Map;
      final got = estimatedSpeed(
        totalB: (m['totalB'] as num).toDouble(),
        activeB: (m['activeB'] as num).toDouble(),
        fileGb: (s['fileGb'] as num).toDouble(),
        kind: hw['kind'] as String,
        vramGb: (hw['vramGb'] as num).toDouble(),
        ramGb: (hw['ramGb'] as num?)?.toDouble(),
      );
      final want = out['range'] as List?;
      expect(
        [got.tokensPerSec, got.stars, got.range?.$1, got.range?.$2],
        [out['tokensPerSec'], out['stars'], want?[0], want?[1]],
        reason: jsonEncode(s),
      );
    }
  });

  group('in the app', () {
    late FakeRedGiant server;
    late FakeModels fm;
    setUp(() async {
      HttpOverrides.global = null;
      server = await FakeRedGiant.start();
      fm = FakeModels(server.setup);
      server.modelsFake = fm;
    });
    tearDown(() => server.close());

    Future<AppController> start(WidgetTester tester, {Size size = const Size(420, 5000)}) async {
      final app =
          AppController(
              tokens: MemoryTokenStore(),
              prefs: MemoryAppPrefs(),
              platform: DevicePlatform.android,
              liveEnabled: false,
            )
            ..locale = const Locale('it')
            ..reduceMotion = true;
      await tester.runAsync(() => app.connect(server.base.toString(), 'secret'));
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(RGCompanionApp(controller: app));
      await _settle(tester);
      return app;
    }

    final opened = <Uri>[];
    Future<bool> open(Uri u) async {
      opened.add(u);
      return true;
    }

    Future<void> push(WidgetTester tester) async {
      final nav = tester.state<NavigatorState>(find.byType(Navigator).first);
      nav
          .push(MaterialPageRoute<void>(builder: (_) => ModelsScreen(poll: false, openUrl: open)))
          .ignore();
      await _settle(tester);
    }

    Future<void> tap(WidgetTester tester, String key) async {
      final f = find.byKey(Key(key));
      await tester.ensureVisible(f.first);
      await tester.pump();
      await tester.tap(f.first);
      await _settle(tester);
    }

    Future<void> closeWindow(WidgetTester tester) async {
      await tester.tapAt(const Offset(10, 10));
      await _settle(tester);
    }

    Future<void> done(WidgetTester tester) async {
      await tester.pumpWidget(const SizedBox());
      await tester.pump(const Duration(minutes: 3));
    }

    testWidgets('the ways: lit when connected, the keys tried and refused, removed', (
      tester,
    ) async {
      opened.clear();
      await start(tester);
      await push(tester);
      expect(find.byKey(const Key('models-page')), findsOneWidget);
      expect(find.text('Anthropic (Claude): collegata'), findsOneWidget);
      await tap(tester, 'way-keys');
      expect(find.byKey(const Key('key-connected-anthropic')), findsOneWidget);
      await tap(tester, 'key-provider-openai');
      await tap(tester, 'key-make');
      expect(opened.last.toString(), 'https://platform.openai.com/api-keys');
      await tester.enterText(find.byKey(const Key('key-field')), 'sk-proj-wrong-key');
      await tap(tester, 'key-try');
      expect(find.text('openai: HTTP 401'), findsOneWidget);
      await tester.enterText(find.byKey(const Key('key-field')), 'sk-proj-good-key');
      await tap(tester, 'key-try');
      expect(find.textContaining('2 modelli'), findsOneWidget);
      expect(find.byKey(const Key('key-connected-openai')), findsOneWidget);
      await tap(tester, 'key-remove-anthropic');
      expect((server.setup['secretsSet'] as Map)['keys'], ['openai']);
      await done(tester);
    });

    testWidgets('Claude: the terms first, the page in the browser, a wrong code, signed in', (
      tester,
    ) async {
      opened.clear();
      await start(tester);
      await push(tester);
      await tap(tester, 'way-claude');
      expect(tester.widget<FilledButton>(find.byKey(const Key('claude-open'))).onPressed, isNull);
      await tap(tester, 'models-terms');
      expect(fm.bodies['PUT /api/setup/subscriptions'], {'ack': true});
      await tap(tester, 'claude-open');
      expect(opened.last.host, 'claude.ai');
      await tester.enterText(find.byKey(const Key('claude-code')), 'bad');
      await tap(tester, 'claude-connect');
      expect(find.text('Anthropic did not accept this code'), findsOneWidget);
      await tester.enterText(find.byKey(const Key('claude-code')), 'good-code#abc');
      await tap(tester, 'claude-connect');
      expect(find.byKey(const Key('sub-linked')), findsOneWidget);
      expect(find.textContaining('mario@example.com'), findsOneWidget);
      await tap(tester, 'sub-out');
      expect(fm.claudeOn, isFalse);
      await done(tester);
    });

    testWidgets('ChatGPT: the device code to type on OpenAI\'s page', (tester) async {
      opened.clear();
      await start(tester);
      await push(tester);
      await tap(tester, 'way-chatgpt');
      await tap(tester, 'models-terms');
      await tap(tester, 'chatgpt-start');
      expect(fm.chatgptOn, isTrue);
      expect(find.text('WXYZ-1234'), findsOneWidget);
      await tap(tester, 'chatgpt-url');
      expect(opened.last.toString(), 'https://auth.openai.com/codex/device');
      await done(tester);
    });

    testWidgets('the own server: tried, refused, connected, disconnected', (tester) async {
      await start(tester);
      await push(tester);
      await tap(tester, 'way-server');
      await tester.enterText(find.byKey(const Key('server-url')), 'localhost:11434');
      await tap(tester, 'server-try');
      expect(find.text('Nothing answered at localhost:11434'), findsOneWidget);
      await tester.enterText(find.byKey(const Key('server-url')), 'http://localhost:11434/v1');
      await tap(tester, 'server-try');
      expect((server.setup['config'] as Map)['server'], {'baseUrl': 'http://localhost:11434/v1'});
      await tap(tester, 'server-remove');
      expect((server.setup['config'] as Map).containsKey('server'), isFalse);
      await done(tester);
    });

    testWidgets('the default model and who uses which, in the sheet by provider and way', (
      tester,
    ) async {
      await start(tester);
      await push(tester);
      expect(find.byKey(const Key('models-default')), findsOneWidget);
      await tap(tester, 'models-default');
      expect(find.byKey(const Key('model-group-claude-subscription')), findsOneWidget);
      await tap(tester, 'model-claude-subscription/claude-sonnet-5');
      await tap(tester, 'effort-high');
      await tap(tester, 'model-use');
      expect((server.setup['config'] as Map)['defaultModel'], {
        'provider': 'claude-subscription',
        'model': 'claude-sonnet-5',
        'effort': 'high',
      });
      // The backup model: chosen, then «None» takes it away.
      await tap(tester, 'role-backup');
      await tap(tester, 'model-anthropic/claude-haiku-5');
      await tap(tester, 'model-use');
      expect(
        (server.setup['config'] as Map)['backupModel'],
        containsPair('model', 'claude-haiku-5'),
      );
      await tap(tester, 'role-backup');
      await tap(tester, 'model-inherit');
      expect((server.setup['config'] as Map).containsKey('backupModel'), isFalse);
      // God's own model, through PATCH /api/agents/:id.
      await tap(tester, 'role-god');
      await tap(tester, 'model-anthropic/claude-haiku-5');
      await tap(tester, 'model-use');
      expect(server.patches.last['model'], containsPair('model', 'claude-haiku-5'));
      await done(tester);
    });

    testWidgets('the local model: the computer, download with its bar, start, off, test, delete', (
      tester,
    ) async {
      await start(tester);
      await push(tester);
      await tester.ensureVisible(find.byKey(const Key('lm-machine')));
      expect(find.textContaining('RTX 4080 SUPER'), findsOneWidget);
      expect(find.byKey(const Key('lm-card-qwen3-30b')), findsOneWidget);
      // The big dense model is too slow here: it is in the other group.
      expect(find.byKey(const Key('lm-card-mistral-medium')), findsNothing);
      await tap(tester, 'lm-tab-slow');
      expect(find.byKey(const Key('lm-card-mistral-medium')), findsOneWidget);
      await tap(tester, 'lm-tab-fit');
      await tap(tester, 'lm-card-qwen3-30b');
      expect(find.byKey(const Key('lm-panel-qwen3-30b')), findsOneWidget);
      await tap(tester, 'lm-download');
      expect(fm.bodies['POST /api/setup/local-models/download'], {
        'repo': 'unsloth/Qwen3-30B-A3B-GGUF',
        'file': 'Qwen3-30B-A3B-Q4_K_M.gguf',
        'variant': 'cuda',
      });
      // Halfway: the real bar with its words.
      fm.jobs.last['steps'] = [
        {
          'id': 'model_download',
          'state': 'running',
          'progress': {
            'done': 9250000000,
            'total': 18500000000,
            'rate': 50000000,
            'secondsLeft': 185,
          },
        },
      ];
      await closeWindow(tester);
      await tap(tester, 'lm-card-qwen3-30b');
      expect(find.byKey(const Key('kb-bar')), findsOneWidget);
      expect(find.textContaining('50%'), findsOneWidget);
      await tap(tester, 'lm-pause');
      expect(fm.jobs.last['state'], 'cancelled');
      // Downloaded: start it, switch it off, measure it, delete it.
      fm.files.add({'file': 'Qwen3-30B-A3B-Q4_K_M.gguf', 'bytes': 18500000000, 'partial': false});
      await closeWindow(tester);
      await tap(tester, 'lm-card-qwen3-30b');
      await tap(tester, 'lm-start');
      expect((server.setup['config'] as Map)['engine'], {
        'variant': 'cuda',
        'model': 'Qwen3-30B-A3B-Q4_K_M.gguf',
      });
      await closeWindow(tester);
      await tap(tester, 'lm-card-qwen3-30b');
      await tap(tester, 'lm-power');
      expect(((server.setup['config'] as Map)['engine'] as Map)['off'], isTrue);
      await tap(tester, 'lm-speed-test');
      await tap(tester, 'lm-speed-start');
      expect(find.textContaining('71'), findsOneWidget);
      await closeWindow(tester);
      await done(tester);
    });

    testWidgets('the way in from «Settings of <name>»', (tester) async {
      await start(tester);
      final nav = tester.state<NavigatorState>(find.byType(Navigator).first);
      nav.push(MaterialPageRoute<void>(builder: (_) => const ServerSettingsScreen())).ignore();
      await _settle(tester);
      await tap(tester, 'settings-models');
      expect(find.byKey(const Key('models-page')), findsOneWidget);
      await done(tester);
    });
  });
}

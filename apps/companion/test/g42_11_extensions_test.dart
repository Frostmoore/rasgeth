// G42.11: Settings › Extensions native, against the fake server that answers as the real one
// (test/fake_extensions.dart): the catalog's settings checked with the protocol's own vectors, the
// agents' proposals read and decided (also from the bell), the catalog with its search and a key,
// a service that signs in on its page (the system's browser), a server's window, the hand-made
// skill, server and .zip (asked before replacing), the generation's steps, and a magic
// integration whose missing key is added in its window.
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
import 'package:rgcompanion/settings/extensions/ext_catalog.dart';
import 'package:rgcompanion/settings/extensions/ext_kit.dart';
import 'package:rgcompanion/settings/extensions/extensions_screen.dart';
import 'package:rgcompanion/settings/extensions/proposals_block.dart';

import 'fake_extensions.dart' show FakeExtensions;
import 'fake_server.dart';

Future<void> _settle(WidgetTester tester, [int rounds = 14]) async {
  for (var i = 0; i < rounds; i++) {
    await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 30)));
    await tester.pump();
  }
  await tester.pump(const Duration(milliseconds: 400));
}

void main() {
  test('the catalog\'s settings are the protocol\'s own (catalogConfig, every service)', () {
    final file = jsonDecode(File('test/fixtures/ext_vectors.json').readAsStringSync()) as Map;
    final vectors = (file['vectors'] as List).cast<Map<String, dynamic>>();
    expect(vectors.length, mcpCatalog.length * 2);
    for (final v in vectors) {
      final e = catalogEntry(v['id'] as String)!;
      final i = v['input'] as Map<String, dynamic>;
      final app = i['app'] as Map<String, dynamic>? ?? const {};
      final input = CatalogInput(
        key: i['key'] as String? ?? '',
        url: i['url'] as String? ?? '',
        fields: {
          for (final f in (i['fields'] as Map? ?? const {}).entries) '${f.key}': '${f.value}',
        },
        clientId: app['clientId'] as String? ?? '',
        clientSecret: app['clientSecret'] as String? ?? '',
      );
      if (v.containsKey('ok')) {
        expect(catalogConfig(e, input), v['ok'], reason: e.id);
      } else {
        expect(
          () => catalogConfig(e, input),
          throwsA(isA<FormatException>().having((x) => x.message, 'message', v['error'])),
          reason: e.id,
        );
      }
    }
    expect(catalogCategories.first, 'code');
  });

  group('in the app', () {
    late FakeRedGiant server;
    late FakeExtensions ext;
    final opened = <String>[];
    setUp(() async {
      HttpOverrides.global = null;
      server = await FakeRedGiant.start();
      ext = FakeExtensions(server.setup);
      server.extensions = ext;
      opened.clear();
      debugOpenOutside = (url) async => opened.add(url);
    });
    tearDown(() {
      debugOpenOutside = null;
      return server.close();
    });

    Future<AppController> start(WidgetTester tester, {Size size = const Size(420, 9000)}) async {
      final app =
          AppController(
              tokens: MemoryTokenStore(),
              prefs: MemoryAppPrefs(),
              platform: DevicePlatform.android,
              liveEnabled: false,
            )
            ..locale = const Locale('it')
            ..reduceMotion = true;
      await tester.runAsync(() async {
        await app.connect(server.base.toString(), 'secret');
      });
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(RGCompanionApp(controller: app));
      await _settle(tester);
      return app;
    }

    Future<void> push(WidgetTester tester, Widget screen) async {
      final nav = tester.state<NavigatorState>(find.byType(Navigator).first);
      nav.push(MaterialPageRoute<void>(builder: (_) => screen)).ignore();
      await _settle(tester);
    }

    Future<void> tap(WidgetTester tester, String key) async {
      final f = find.byKey(Key(key));
      await tester.ensureVisible(f.first);
      await tester.pump();
      await tester.tap(f.first);
      await _settle(tester);
    }

    Future<void> type(WidgetTester tester, String key, String text) async {
      await tester.ensureVisible(find.byKey(Key(key)).first);
      await tester.enterText(find.byKey(Key(key)).first, text);
      await tester.pump();
    }

    Future<void> done(WidgetTester tester) async {
      await tester.pumpWidget(const SizedBox());
      await tester.pump(const Duration(minutes: 3));
    }

    testWidgets('the page: magic, what waits, services, generation, catalog, installed', (
      tester,
    ) async {
      await start(tester);
      await push(tester, const ExtensionsScreen());
      expect(find.byKey(const Key('extensions-settings')), findsOneWidget);
      expect(find.byKey(const Key('xt-magic-integration')), findsOneWidget);
      expect(find.byKey(const Key('xt-magic-extension')), findsOneWidget);
      expect(find.byKey(const Key('xt-magic-mx1')), findsOneWidget);
      // Waiting: the tool and the new version; the failed one only behind its link.
      expect(find.byKey(const Key('xt-prop-p_tool')), findsOneWidget);
      expect(find.byKey(const Key('xt-prop-p_skill')), findsOneWidget);
      expect(find.byKey(const Key('xt-prop-p_failed')), findsNothing);
      expect(find.byKey(const Key('xt-mcp-docs')), findsOneWidget);
      expect(find.text('Devi accedere'), findsOneWidget);
      expect(find.byKey(const Key('xt-media-tile-image')), findsOneWidget);
      expect(find.byKey(const Key('xt-cat-entry-github')), findsOneWidget);
      expect(find.byKey(const Key('xt-inst-platform-skill-release-notes')), findsOneWidget);
      await tap(tester, 'xt-failed-open');
      expect(find.byKey(const Key('xt-prop-p_failed')), findsOneWidget);
      await done(tester);
    });

    testWidgets('a new version of a skill: its reason, its scripts, compared, approved', (
      tester,
    ) async {
      await start(tester);
      await push(tester, const ExtensionsScreen());
      await tap(tester, 'xt-prop-p_skill');
      expect(find.byKey(const Key('xt-proposal-p_skill')), findsOneWidget);
      expect(find.byKey(const Key('xt-update-line')), findsOneWidget);
      expect(find.textContaining('check.sh'), findsWidgets);
      await tap(tester, 'xt-proposal-compare');
      expect(find.textContaining('pull request'), findsWidgets);
      await tap(tester, 'xt-approve');
      expect(ext.bodies['POST /api/extensions/proposals/p_skill/decision'], {
        'decision': 'approve',
      });
      expect(find.byKey(const Key('xt-prop-p_skill')), findsNothing);
      await done(tester);
    });

    testWidgets('the catalog: a search, a key pasted, a service that signs in on its page', (
      tester,
    ) async {
      await start(tester);
      await push(tester, const ExtensionsScreen());
      await type(tester, 'xt-search', 'github');
      await _settle(tester);
      expect(find.byKey(const Key('xt-cat-entry-github')), findsOneWidget);
      expect(find.byKey(const Key('xt-cat-entry-linear')), findsNothing);
      await tap(tester, 'xt-cat-entry-github');
      // The button waits for the key.
      expect(tester.widget<FilledButton>(find.byKey(const Key('xt-add'))).onPressed, isNull);
      await type(tester, 'xt-key', ' ghp_test123 ');
      await tap(tester, 'xt-add');
      final body = ext.bodies['PUT /api/extensions/mcp']! as Map<String, dynamic>;
      expect(body['name'], 'github');
      expect(body['projectId'], isNull);
      final want = catalogConfig(catalogEntry('github')!, const CatalogInput(key: 'ghp_test123'));
      expect(body['transport'], want['transport']);
      expect(body['secrets'], want['secrets']);
      expect(find.byKey(const Key('xt-mcp-github')), findsOneWidget);
      // A service that signs in: added, then its page in the system's browser.
      await type(tester, 'xt-search', 'linear');
      await _settle(tester);
      await tap(tester, 'xt-cat-entry-linear');
      await tap(tester, 'xt-add');
      expect(ext.calls, contains('POST /api/extensions/mcp/linear/login'));
      expect(opened.last, 'https://auth.example.com/authorize?server=linear');
      expect(find.byKey(const Key('xt-note')), findsOneWidget);
      await done(tester);
    });

    testWidgets('a server\'s window: sign in again, remove', (tester) async {
      await start(tester);
      await push(tester, const ExtensionsScreen());
      await tap(tester, 'xt-mcp-docs');
      expect(find.text('https://mcp.example.com/mcp'), findsOneWidget);
      await tap(tester, 'xt-server-connect');
      expect(opened.last, contains('server=docs'));
      await tap(tester, 'xt-mcp-docs');
      await tap(tester, 'xt-server-remove');
      expect(ext.calls, contains('DELETE /api/extensions/mcp/docs'));
      expect(find.byKey(const Key('xt-mcp-docs')), findsNothing);
      await done(tester);
    });

    testWidgets('made by hand: a skill, a server by command, a .zip asked before replacing', (
      tester,
    ) async {
      await start(tester);
      var zips = 0;
      await push(
        tester,
        ExtensionsScreen(
          pickZip: () async {
            zips++;
            return ('ponytail.zip', [0x50, 0x4b, 3, 4]);
          },
        ),
      );
      await tap(tester, 'xt-own-skill');
      await type(tester, 'xt-skill-name', 'weekly-report');
      await type(tester, 'xt-skill-description', 'My weekly report, as I like it');
      await type(tester, 'xt-skill-body', 'Three parts: done, doing, blocked. One line each.');
      await tap(tester, 'xt-skill-create');
      final skill = ext.bodies['POST /api/extensions/proposals']! as Map<String, dynamic>;
      expect((skill['input'] as Map)['name'], 'weekly-report');
      expect((skill['input'] as Map)['kind'], 'skill');
      expect(find.byKey(const Key('xt-inst-platform-skill-weekly-report')), findsOneWidget);

      await tap(tester, 'xt-own-server');
      await tap(tester, 'xt-transport-stdio');
      await type(tester, 'xt-server-name', 'files');
      await type(tester, 'xt-server-command', 'npx');
      await type(tester, 'xt-server-args', '-y @scope/files /data');
      await tap(tester, 'xt-server-add');
      final server2 = ext.bodies['PUT /api/extensions/mcp']! as Map<String, dynamic>;
      expect(server2['transport'], {
        'type': 'stdio',
        'command': 'npx',
        'args': ['-y', '@scope/files', '/data'],
      });

      await tap(tester, 'xt-own-import');
      await tap(tester, 'xt-import-pick');
      expect(find.byKey(const Key('xt-imported')), findsOneWidget);
      // Again: the name is taken, our window asks, then it replaces.
      await tap(tester, 'xt-import-pick');
      expect(find.byKey(const Key('dialog-yes')), findsOneWidget);
      await tap(tester, 'dialog-yes');
      expect(zips, 2);
      expect(ext.calls.where((c) => c.contains('skills/import')).last, contains('replace=1'));
      expect(ext.imports.last, [0x50, 0x4b, 3, 4]);
      await done(tester);
    });

    testWidgets('generation: who makes it, its key, its model', (tester) async {
      await start(tester);
      await push(tester, const ExtensionsScreen());
      await tap(tester, 'xt-media-tile-image');
      final first = mediaProviders.firstWhere((p) => p.models('image').isNotEmpty);
      await tap(tester, 'xt-media-provider-${first.id}');
      final choice = ext.bodies['PUT /api/setup/media/image']! as Map<String, dynamic>;
      expect((choice['choice'] as Map)['provider'], first.id);
      expect((choice['choice'] as Map)['model'], first.models('image').first.id);
      // Step 2: its key.
      expect(find.byKey(const Key('xt-media-key')), findsOneWidget);
      await type(tester, 'xt-media-key', 'sk-abcdefghijkl');
      await tap(tester, 'xt-media-key-save');
      expect(ext.bodies['PUT /api/setup/media-keys/${first.id}'], {'key': 'sk-abcdefghijkl'});
      // Step 3: the model, and the key linked.
      expect(find.byKey(const Key('xt-media-model')), findsOneWidget);
      expect(find.byKey(const Key('xt-media-key-linked')), findsOneWidget);
      await done(tester);
    });

    testWidgets('a magic integration: the missing key added in its window, then installed', (
      tester,
    ) async {
      await start(tester, size: const Size(1280, 4000));
      await push(tester, const ExtensionsScreen());
      await tap(tester, 'xt-magic-mx1');
      expect(find.byKey(const Key('xt-package')), findsOneWidget);
      expect(find.byKey(const Key('xt-part-notion-search')), findsOneWidget);
      expect(find.text('query'), findsOneWidget);
      expect(find.text('limit?'), findsOneWidget);
      expect(
        tester.widget<FilledButton>(find.byKey(const Key('xt-magic-approve'))).onPressed,
        isNull,
      );
      await tap(tester, 'xt-check-act-notion_api');
      await type(tester, 'xt-magic-key-value', 'secret_notion');
      await tap(tester, 'xt-magic-key-save');
      expect(ext.bodies['POST /api/magic-ext/mx1/credential'], {
        'name': 'notion_api',
        'value': 'secret_notion',
      });
      await tap(tester, 'xt-magic-approve');
      expect(ext.calls, contains('POST /api/magic-ext/mx1/approve'));
      expect(find.byKey(const Key('xt-installed-package')), findsOneWidget);
      await done(tester);
    });

    testWidgets('the bell\'s proposals: approved there; the way in from the settings', (
      tester,
    ) async {
      await start(tester);
      await push(tester, const Scaffold(body: ProposalsBlock()));
      expect(find.byKey(const Key('bell-proposal-p_tool')), findsOneWidget);
      await tap(tester, 'bell-proposal-approve-p_tool');
      expect(ext.bodies['POST /api/extensions/proposals/p_tool/decision'], {'decision': 'approve'});
      expect(find.byKey(const Key('bell-proposal-p_tool')), findsNothing);
      Navigator.of(tester.element(find.byType(ProposalsBlock))).pop();
      await _settle(tester);
      await push(tester, const ServerSettingsScreen());
      await tap(tester, 'settings-extensions');
      expect(find.byKey(const Key('extensions-settings')), findsOneWidget);
      await done(tester);
    });
  });
}

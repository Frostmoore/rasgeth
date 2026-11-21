// G42.0: the page inside the app on Linux (WebKitGTK), against a real Rasgeth (the demo with
// DEMO_CANVAS=1). «All settings», the web view's test page and two Canvas files in an embed (a PDF
// and a 3D room), light and dark. Run in the agents' Docker with tool/linux_shots.sh (RG_SCREEN for
// the phone's size), RG_SHOTS the folder for the pictures.
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:rgcompanion/api/live.dart';
import 'package:rgcompanion/api/servers.dart';
import 'package:rgcompanion/api/token_store.dart';
import 'package:rgcompanion/app.dart';
import 'package:rgcompanion/app_state.dart';
import 'package:rgcompanion/embed/embed_link.dart';
import 'package:rgcompanion/embed/embed_screen.dart';

import 'shots_test.dart' show frames, shot, waitFor;

final _url = Platform.environment['RG_LIVE_URL'] ?? 'http://127.0.0.1:7651';
final _password = Platform.environment['RG_LIVE_PASSWORD'] ?? 'companion-test-1';
final _tag = Platform.environment['RG_SHOT_TAG'] ?? 'computer';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('the page inside the app on Linux', (t) async {
    final app = AppController(tokens: MemoryTokenStore(), prefs: MemoryAppPrefs())
      ..locale = const Locale('it');
    await t.pumpWidget(RGCompanionApp(controller: app));
    await frames(t);
    await t.runAsync(() => app.connect(_url, _password));
    await waitFor(t, () => app.connected && app.liveStatus == LiveStatus.open);
    final c = app.client!;
    final nav = t.state<NavigatorState>(find.byType(Navigator).first);

    for (final (theme, mode) in [('chiaro', ThemeMode.light), ('scuro', ThemeMode.dark)]) {
      app.setThemeMode(mode);
      await frames(t, 600);
      final look = mode == ThemeMode.dark ? 'dark' : 'light';

      // G42.17: «All settings» (the whole page in a web view) is gone; the embeds stay.
      for (final (name, params) in [
        (
          'prova',
          EmbedParams(
            token: c.token!,
            embed: EmbedKind.probe,
            bridge: newEmbedNonce(),
            theme: look,
            lang: 'it',
          ),
        ),
        (
          'pdf',
          EmbedParams(
            token: c.token!,
            embed: EmbedKind.canvas,
            bridge: newEmbedNonce(),
            scope: 'platform',
            path: 'canvas/modulo.pdf',
            theme: look,
            lang: 'it',
          ),
        ),
        (
          '3d',
          EmbedParams(
            token: c.token!,
            embed: EmbedKind.canvas,
            bridge: newEmbedNonce(),
            scope: 'platform',
            path: 'canvas/stanza.gltf',
            theme: look,
            lang: 'it',
          ),
        ),
      ]) {
        nav
            .push(
              MaterialPageRoute<void>(
                builder: (_) => EmbedScreen(base: c.base, params: params, title: name),
              ),
            )
            .ignore();
        await shot(t, 'g42-0-embed-$name-$_tag-$theme', wait: name == 'prova' ? 14000 : 9000);
        nav.pop();
        await frames(t, 800);
      }
    }
  });
}

// G42.16 in the real app on Linux, against the demo server (FakeProvider, no model), light and
// dark, phone and computer: Settings › Voice with hands-free (its top and its conversation part),
// the indicator waiting for «Talk now» (phone band, conversation header, computer's bar), its
// pop-over, and listening. The microphone is a silent stream (no sound card in the container).
// Run by tool/linux_shots.sh:
//   RG_SCREEN=390x844 … integration_test/g42_16_shots_test.dart
//   RG_SCREEN=1440x900 … integration_test/g42_16_shots_test.dart
import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:rgcompanion/api/live.dart';
import 'package:rgcompanion/api/servers.dart';
import 'package:rgcompanion/api/token_store.dart';
import 'package:rgcompanion/api/types.dart';
import 'package:rgcompanion/app.dart';
import 'package:rgcompanion/app_state.dart';
import 'package:rgcompanion/screens/conversation_screen.dart';
import 'package:rgcompanion/screens/voice_screen.dart';
import 'package:rgcompanion/voice/hands_free/runtime.dart';

import 'shots_test.dart' show frames, shot, waitFor;

final _url = Platform.environment['RG_LIVE_URL'] ?? 'http://127.0.0.1:7651';
final _password = Platform.environment['RG_LIVE_PASSWORD'] ?? 'companion-test-1';
final _phone =
    (int.tryParse((Platform.environment['RG_SCREEN'] ?? '1440x900').split('x').first) ?? 1440) <
    600;

class _SilentMic implements MicStream {
  StreamController<Uint8List>? _c;
  @override
  Future<bool> allowed() async => true;
  @override
  Future<Stream<Uint8List>> start() async => (_c = StreamController<Uint8List>()).stream;
  @override
  Future<void> stop() async => _c?.close();
}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('G42.16: hands-free voice', (t) async {
    final app = AppController(
      tokens: MemoryTokenStore(),
      prefs: MemoryAppPrefs(),
      platform: _phone ? DevicePlatform.android : DevicePlatform.linux,
      mic: _SilentMic(),
      micKeeper: NoMicKeeper(),
    )..locale = const Locale('it');
    await t.runAsync(() => app.connect(_url, _password));
    await t.pumpWidget(RGCompanionApp(controller: app));
    await waitFor(t, () => app.connected && app.liveStatus == LiveStatus.open);
    await frames(t, 2000);
    final nav = t.state<NavigatorState>(find.byType(Navigator).first);
    final p = _phone ? 'telefono' : 'computer';
    final god = app.agents.firstWhere((a) => a.kind == AgentKind.god);
    final sid = app.live.sessions.where((s) => s.agentId == god.id).firstOrNull?.id;

    for (final (theme, mode) in [('chiaro', ThemeMode.light), ('scuro', ThemeMode.dark)]) {
      app.setThemeMode(mode);
      await frames(t, 600);
      final tag = '${p}_$theme';
      await t.runAsync(() => app.handsFree.switchOff());

      unawaited(nav.push(MaterialPageRoute<void>(builder: (_) => const VoiceScreen())));
      await frames(t, 2500);
      await shot(t, '01_voce_spenta_$tag');
      await t.tap(find.byKey(const Key('hf-enabled')));
      await frames(t, 1500);
      await shot(t, '02_voce_accesa_$tag');
      await t.scrollUntilVisible(
        find.byKey(const Key('hf-sensitivity')),
        300,
        scrollable: find
            .descendant(of: find.byKey(const Key('voice-list')), matching: find.byType(Scrollable))
            .first,
      );
      await shot(t, '03_voce_parola_$tag');
      await t.scrollUntilVisible(
        find.byKey(const Key('hf-limits')),
        400,
        scrollable: find
            .descendant(of: find.byKey(const Key('voice-list')), matching: find.byType(Scrollable))
            .first,
      );
      await shot(t, '04_voce_conversazione_$tag');
      nav.pop();
      await frames(t, 1000);
      await shot(t, '05_indicatore_$tag');
      if (sid != null) {
        unawaited(
          nav.push(
            MaterialPageRoute<void>(
              builder: (_) => ConversationScreen(sessionId: sid, agent: god),
            ),
          ),
        );
        await frames(t, 2500);
      }
      await t.tap(find.byKey(const Key('hf-indicator')).last);
      await frames(t, 1200);
      await shot(t, '06_indicatore_aperto_$tag');
      await t.tap(find.byKey(const Key('hf-talk')));
      await frames(t, 1200);
      await shot(t, '07_ti_ascolto_$tag');
      await t.runAsync(() => app.handsFree.switchOff());
      await frames(t, 600);
      if (sid != null) nav.pop();
      await frames(t, 800);
    }
  });
}

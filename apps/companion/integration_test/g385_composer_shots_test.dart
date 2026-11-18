// 3.8.5 in the real app on Linux, against the tests' fake Rasgeth: Officina's composer (one box,
// the text on the whole width, the buttons inside it), empty, with several lines and with two
// attachments, light and dark; on a computer also in the side panel. With RG_SCREEN narrower than 600
// the phone. Run with Xvfb like tool/linux_shots.sh (no demo server needed):
//   RG_SCREEN=390x844 RG_SHOTS=<folder> flutter test integration_test/g385_composer_shots_test.dart -d linux
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:rgcompanion/api/servers.dart';
import 'package:rgcompanion/api/token_store.dart';
import 'package:rgcompanion/api/types.dart';
import 'package:rgcompanion/app.dart';
import 'package:rgcompanion/app_state.dart';
import 'package:rgcompanion/screens/conversation_screen.dart';
import 'package:rgcompanion/ui/paste_files.dart';

import '../test/fake_server.dart';
import 'shots_test.dart' show frames, shot, waitFor;

final _phone =
    (int.tryParse((Platform.environment['RG_SCREEN'] ?? '1440x900').split('x').first) ?? 1440) <
    600;

class _TwoFiles extends ClipboardReader {
  @override
  Future<List<PastedFile>> files() async => [
    ('note-riunione.md', Uint8List.fromList('# Riunione'.codeUnits)),
    ('preventivo.pdf', Uint8List.fromList('%PDF-1.4'.codeUnits)),
  ];

  @override
  Future<Uint8List?> image() async => null;

  @override
  Future<bool> hasText() async => false;
}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('3.8.5: the composer as Officina\'s', (t) async {
    final fake = await FakeRedGiant.start();
    addTearDown(fake.close);
    final app = AppController(
      tokens: MemoryTokenStore(),
      prefs: MemoryAppPrefs(),
      platform: _phone ? DevicePlatform.android : DevicePlatform.linux,
    )..locale = const Locale('it');
    await t.runAsync(() => app.connect(fake.base.toString(), 'secret'));
    await t.pumpWidget(RGCompanionApp(controller: app));
    await waitFor(t, () => app.connected);
    await frames(t, 3000);
    final p = _phone ? 'telefono' : 'computer';

    Future<void> states(String where) async {
      final field = find.byKey(const Key('composer-text')).last;
      await t.tap(field);
      await shot(t, 'g385-$p-$where-01-vuoto');
      await t.enterText(
        field,
        'Mi prepari il punto della settimana?\nCon le tre cose fatte,\nquelle ferme\ne cosa serve '
        'da me entro venerdì.',
      );
      await shot(t, 'g385-$p-$where-02-righe');
      clipboardReader = _TwoFiles();
      await t.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
      await t.sendKeyEvent(LogicalKeyboardKey.keyV);
      await t.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);
      await frames(t, 1500);
      await shot(t, 'g385-$p-$where-03-allegati');
      app.setThemeMode(ThemeMode.dark);
      await shot(t, 'g385-$p-$where-04-scuro', wait: 1500);
      await t.enterText(field, '');
      FocusManager.instance.primaryFocus?.unfocus();
      await shot(t, 'g385-$p-$where-05-scuro-vuoto');
      app.setThemeMode(ThemeMode.light);
      await frames(t, 800);
    }

    if (!_phone) {
      // The side panel, narrow: opened from God's field.
      final god = find.descendant(
        of: find.byKey(const Key('desk-god-field')),
        matching: find.byType(TextField),
      );
      await t.tap(god);
      await t.enterText(god, 'Fai il punto della settimana');
      await t.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
      await t.sendKeyEvent(LogicalKeyboardKey.enter);
      await t.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);
      await frames(t, 2500);
      await states('pannello');
    }
    final nav = t.state<NavigatorState>(find.byType(Navigator).first);
    nav
        .push(
          MaterialPageRoute<void>(
            builder: (_) => ConversationScreen(sessionId: 's1', agent: app.agents.first),
          ),
        )
        .ignore();
    await frames(t, 2500);
    await states('intera');
  });

  testWidgets('3.8.5: the cursor of an answer being written', (t) async {
    final fake = await FakeRedGiant.start();
    addTearDown(fake.close);
    final app = AppController(
      tokens: MemoryTokenStore(),
      prefs: MemoryAppPrefs(),
      platform: _phone ? DevicePlatform.android : DevicePlatform.linux,
    )..locale = const Locale('it');
    await t.runAsync(() => app.connect(fake.base.toString(), 'secret'));
    await t.pumpWidget(RGCompanionApp(controller: app));
    await waitFor(t, () => app.connected);
    await frames(t, 3000);
    final p = _phone ? 'telefono' : 'computer';
    final nav = t.state<NavigatorState>(find.byType(Navigator).first);
    nav
        .push(
          MaterialPageRoute<void>(
            builder: (_) => ConversationScreen(sessionId: 's1', agent: app.agents.first),
          ),
        )
        .ignore();
    await frames(t, 2500);
    const pieces = {
      'paragrafo': 'Ecco come la vedo: la settimana è andata bene, ma due cose sono ferme e ',
      'elenco':
          'aspettano te.\n\n- la bozza del preventivo\n- il rinnovo del dominio\n- la riunione di ',
      'tabella':
          'giovedì\n\n| Giorno | Cosa | Chi |\n|---|---|---|\n| lun | spesa | tu |\n| mar | pale',
      'codice': 'stra | io |\n\n```bash\nrsync -av ~/foto/ /mnt/archivio/foto/\ndf -h /mnt/arch',
    };
    for (final dark in [false, true]) {
      app.setThemeMode(dark ? ThemeMode.dark : ThemeMode.light);
      final theme = dark ? 'scuro' : 'chiaro';
      var all = '';
      for (final (i, e) in pieces.entries.indexed) {
        all += e.value;
        fake.streamPiece('s1', e.value);
        await shot(t, 'g385-$p-cursore-$theme-${i + 1}-${e.key}', wait: 1500);
      }
      if (!dark) {
        // A few frames of the flicker, close together.
        for (var f = 1; f <= 3; f++) {
          await shot(t, 'g385-$p-cursore-fotogramma-$f', wait: 150);
        }
      }
      fake.streamEnd('s1', all, seq: dark ? 4 : 3);
      await shot(t, 'g385-$p-cursore-$theme-5-finito', wait: 1500);
    }
    app.setThemeMode(ThemeMode.light);
  });
}

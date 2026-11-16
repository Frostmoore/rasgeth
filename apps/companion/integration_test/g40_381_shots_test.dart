// G40.14 and G40.16 in the real app against a real RedGiant (the demo server, FakeProvider): the
// Chat's product cards with the pictures the server downloaded, a passage selected with our menu
// and saved with a note and tags, «Rispondi a questo» above the composer, the whole message saved
// from its menu, «Salvati» (search, edit, export) and the way back to the passage lit up. Run by
// tool/linux_shots.sh with
//   RG_SCREEN=430x900 RG_DEMO_ENV="DEMO_PASSWORD=companion-test-1 DEMO_PRODUCTS=1" \
//     … integration_test/g40_381_shots_test.dart
// The touch gestures are a phone's (Android's selection menu after a long press).
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:rgcompanion/api/servers.dart';
import 'package:rgcompanion/api/token_store.dart';
import 'package:rgcompanion/api/types.dart';
import 'package:rgcompanion/app.dart';
import 'package:rgcompanion/app_state.dart';

import 'shots_test.dart' show frames, shot, waitFor;

final _url = Platform.environment['RG_LIVE_URL'] ?? 'http://127.0.0.1:7651';
final _password = Platform.environment['RG_LIVE_PASSWORD'] ?? 'companion-test-1';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  Future<void> tap(WidgetTester t, Finder f, [int ms = 1500]) async {
    await t.ensureVisible(f);
    await frames(t, 200);
    await t.tap(f);
    await frames(t, ms);
  }

  Future<void> select(WidgetTester t, String words) async {
    final f = find.textContaining(words, findRichText: true).first;
    await t.ensureVisible(f);
    await frames(t, 300);
    final g = await t.startGesture(t.getTopLeft(f) + const Offset(30, 10));
    await frames(t, 900);
    // Held and moved, the selection grows word by word (as on a phone).
    for (var i = 0; i < 6; i++) {
      await g.moveBy(const Offset(45, 0));
      await frames(t, 100);
    }
    await g.up();
    await frames(t, 900);
  }

  testWidgets('G40.14 and G40.16: saved passages and product cards', (t) async {
    debugDefaultTargetPlatformOverride = TargetPlatform.android;
    final app = AppController(
      tokens: MemoryTokenStore(),
      prefs: MemoryAppPrefs(),
      platform: DevicePlatform.android,
    )..locale = const Locale('it');
    await t.pumpWidget(RGCompanionApp(controller: app));
    await frames(t);
    await t.tap(find.byKey(const Key('tab-you')));
    await frames(t);
    await t.enterText(find.byKey(const Key('server-address')), _url);
    await t.enterText(find.byKey(const Key('server-password')), _password);
    await t.tap(find.byKey(const Key('server-connect')));
    await waitFor(t, () => app.connected);
    await frames(t, 1500);
    const p = 'g40381';

    // ---- the Chat: a conversation with product cards ----
    await tap(t, find.byKey(const Key('tab-chat')), 2500);
    await shot(t, '$p-01-chat-salvati');
    await tap(t, find.text('Una moka nuova').first, 4000);
    await waitFor(t, () => find.byKey(const Key('product-picture')).evaluate().isNotEmpty);
    final cards = find.byKey(const Key('products-row'));
    await t.ensureVisible(cards);
    await frames(t, 1500);
    await shot(t, '$p-02-schede-prodotto');
    await t.drag(cards, const Offset(-260, 0));
    await frames(t, 1200);
    await shot(t, '$p-03-schede-scorse');

    // ---- a passage selected: our menu, «Salva» ----
    await select(t, 'Per tutti i giorni');
    await shot(t, '$p-04-menu-selezione');
    await tap(t, find.byKey(const Key('sel-save')), 1500);
    await t.enterText(find.byKey(const Key('save-note')), 'Da regalare alla nonna');
    await t.enterText(find.byKey(const Key('save-tags')), 'casa, regali');
    await frames(t, 600);
    await shot(t, '$p-05-salva');
    await tap(t, find.byKey(const Key('save-confirm')), 2000);
    await shot(t, '$p-06-salvato');
    await tap(t, find.byKey(const Key('save-close')), 1200);

    // ---- «Rispondi a questo» ----
    await select(t, 'Se hai un fornello');
    await tap(t, find.byKey(const Key('sel-reply')), 1200);
    await t.enterText(find.byKey(const Key('composer-text')), 'E per due tazze?');
    await frames(t, 600);
    FocusManager.instance.primaryFocus?.unfocus();
    await frames(t, 600);
    await shot(t, '$p-07-rispondi');
    await tap(t, find.byKey(const Key('quote-remove-0')), 600);
    await t.enterText(find.byKey(const Key('composer-text')), '');
    FocusManager.instance.primaryFocus?.unfocus();

    // ---- the whole message from its menu ----
    final menu = find.byWidgetPredicate(
      (w) =>
          w.key is ValueKey<String> &&
          (w.key! as ValueKey<String>).value.startsWith('message-menu-'),
    );
    // The list is upside down: the first in the tree is the newest message.
    await tap(t, menu.first, 1200);
    await shot(t, '$p-08-menu-messaggio');
    await tap(t, find.byKey(const Key('message-save')), 1500);
    await tap(t, find.byKey(const Key('save-confirm')), 2000);
    await tap(t, find.byKey(const Key('save-open-archive')), 2500);

    // ---- «Salvati» ----
    await shot(t, '$p-09-salvati');
    await t.enterText(find.byKey(const Key('saved-search')), 'induzione');
    await frames(t, 2000);
    FocusManager.instance.primaryFocus?.unfocus();
    await frames(t, 600);
    await shot(t, '$p-10-salvati-ricerca');
    await tap(t, find.byKey(const Key('saved-search-clear')), 2000);
    await tap(t, find.byKey(const Key('saved-tag-regali')), 2000);
    await shot(t, '$p-11-salvati-etichetta');
    final edit = find.byWidgetPredicate(
      (w) =>
          w.key is ValueKey<String> && (w.key! as ValueKey<String>).value.startsWith('saved-edit-'),
    );
    await tap(t, edit.first, 1200);
    await shot(t, '$p-12-salvati-modifica');
    final save = find.byWidgetPredicate(
      (w) =>
          w.key is ValueKey<String> && (w.key! as ValueKey<String>).value.startsWith('saved-save-'),
    );
    await tap(t, save.first, 1500);
    await tap(t, find.byKey(const Key('saved-export')), 1200);
    await shot(t, '$p-13-esporta');
    await t.tapAt(const Offset(20, 40));
    await frames(t, 1000);
    final open = find.byWidgetPredicate(
      (w) =>
          w.key is ValueKey<String> && (w.key! as ValueKey<String>).value.startsWith('saved-open-'),
    );
    await tap(t, open.first, 400);
    await frames(t, 900);
    await shot(t, '$p-14-passaggio-evidenziato', wait: 300);
    await frames(t, 5000);
    debugDefaultTargetPlatformOverride = null;
  });
}

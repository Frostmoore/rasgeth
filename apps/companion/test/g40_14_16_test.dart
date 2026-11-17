// G40.14 and G40.16 against the fake RedGiant: an answer selected with our menu («Copia»,
// «Rispondi a questo», «Salva»), a whole message saved from its menu, «Salvati» (pages, search,
// filters, note and tags, deletion, export, back to the passage lit up), the product cards
// (pictures from the server with the token, placeholders, prices, «Apri» only for http/https),
// and the conversation beside the diff without «back». The pure parts first.
import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rgcompanion/api/conversation.dart';
import 'package:rgcompanion/api/products.dart';
import 'package:rgcompanion/api/saved.dart';
import 'package:rgcompanion/api/servers.dart';
import 'package:rgcompanion/api/token_store.dart';
import 'package:rgcompanion/api/types.dart';
import 'package:rgcompanion/app.dart';
import 'package:rgcompanion/app_state.dart';
import 'package:rgcompanion/l10n/app_localizations.dart';
import 'package:rgcompanion/screens/code/project_screen.dart';
import 'package:rgcompanion/screens/conversation_screen.dart';
import 'package:rgcompanion/screens/saved_screen.dart';
import 'package:rgcompanion/ui/product_cards.dart';

import 'fake_server.dart';

/// Brings it into view first (a long list), then taps.
Future<void> _tapV(WidgetTester tester, Finder f) async {
  await tester.ensureVisible(f);
  await tester.pumpAndSettle();
  await tester.tap(f);
}

Future<void> _settle(WidgetTester tester, [int rounds = 12]) async {
  for (var i = 0; i < rounds; i++) {
    await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 30)));
    await tester.pump();
  }
  await tester.pump(const Duration(milliseconds: 400));
}

final _png = base64Decode(
  'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mP8z8BQDwAEhQGAhKmMIQAAAABJRU5ErkJggg==',
);
final _imgA = 'a' * 64;
final _imgB = 'b' * 64;

const _answer =
    'Moka\n\nLa **Venus** in acciaio va anche sull\'induzione [2](https://example.com/venus).\n\n'
    '```\ncode stays\n```';

Map<String, dynamic> _ev(int seq, String type, Map<String, dynamic> payload) => {
  'seq': seq,
  'ts': '2026-11-16T10:00:0$seq.000Z',
  'type': type,
  'payload': payload,
};

List<Map<String, dynamic>> _history() => [
  _ev(2, 'message.user', {'text': 'Mi consigli una moka?'}),
  _ev(3, 'tool.call', {
    'callId': 'c1',
    'tool': 'show_products',
    'input': {'products': []},
  }),
  _ev(4, 'products.shown', {
    'title': 'Moka da 3-4 tazze',
    'products': [
      {
        'name': 'Bialetti Moka Express 3 tazze',
        'price': 32.9,
        'currency': 'EUR',
        'shop': 'Bialetti',
        'url': 'https://www.bialetti.com/moka-express',
        'description': 'La classica in alluminio.',
        'source': 1,
        'image': _imgA,
      },
      {
        'name': 'Bialetti Venus',
        'price': 44.5,
        'currency': 'EUR',
        'shop': 'Amazon',
        'url': 'https://www.amazon.it/dp/B0',
        'source': 2,
        'image': _imgB,
      },
      {'name': 'Senza foto né link buono', 'url': 'javascript:alert(1)'},
    ],
  }),
  _ev(5, 'message.assistant', {
    'parts': [
      {'type': 'text', 'text': _answer},
    ],
    'stopReason': 'end_turn',
  }),
];

/// A span lit up somewhere in the tree (the light theme's `accentDim`; code has a background too).
bool _lit(InlineSpan s) {
  if (s is TextSpan) {
    if (s.style?.backgroundColor == const Color(0xFFF2B8B0) && (s.text ?? '').trim().isNotEmpty) {
      return true;
    }
    return s.children?.any(_lit) ?? false;
  }
  return false;
}

void main() {
  group('pure parts', () {
    test('tags are kept as the server keeps them', () {
      expect(normalizeTags([' #idee ', 'Idee', '', 'casa', '##x']), ['idee', 'casa', 'x']);
      expect(withTyped(['casa'], 'idee, Casa ,  , viaggi'), ['casa', 'idee', 'viaggi']);
      expect(normalizeTags([for (var i = 0; i < 20; i++) 't$i']), hasLength(savedTagsMax));
    });

    test('findPassage: by its place, then its words, then its first line', () {
      const all = 'One two three. Four five.';
      expect(findPassage(all, 'two three', start: 4, end: 13), (from: 4, to: 13));
      expect(findPassage(all, 'Four', start: 0, end: 4), (from: 15, to: 19));
      expect(findPassage(all, 'Four five.\nnothing'), (from: 15, to: 25));
      expect(findPassage(all, 'nothing\nFour five.'), isNull);
      expect(findPassage(all, 'absent'), isNull);
    });

    test('a passage read on screen is found in the Markdown and lit word by word', () {
      const md = 'La **Venus** in acciaio va [qui](https://x.it/a_b) e `code`.\n\n- uno\n- due';
      final at = findInMarkdown(md, 'La Venus in acciaio va qui');
      expect(at, isNotNull);
      expect(md.substring(at!.from, at.to), startsWith('La **Venus**'));
      final marked = markPassage(md, 'La Venus in acciaio va qui')!;
      // Each run of words alone: the bold and the link stay Markdown.
      expect(
        marked,
        contains(
          '$markOpen'
          'La $markClose**${markOpen}Venus$markClose**',
        ),
      );
      expect(marked, contains('[${markOpen}qui$markClose](https://x.it/a_b)'));
      expect(marked.replaceAll(markOpen, '').replaceAll(markClose, ''), md);
      // Across list items, never inside code.
      final list = markPassage(md, 'uno due')!;
      expect(list, contains('- ${markOpen}uno$markClose\n- ${markOpen}due$markClose'));
      expect(markPassage(md, 'code'), isNull);
      expect(markPassage(md, 'not there at all'), isNull);
    });

    test('prices in the person\'s language, links only http and https', () {
      expect(priceText(32.9, 'EUR', 'it'), '32,90 €');
      expect(priceText(45, 'USD', 'en'), r'$45.00');
      expect(priceText(3, null, 'it'), '3,00');
      expect(priceText(null, 'EUR', 'it'), '');
      expect(productLink('https://shop.it/x'), isNotNull);
      expect(productLink('http://shop.it/x'), isNotNull);
      expect(productLink('javascript:alert(1)'), isNull);
      expect(productLink('file:///etc/passwd'), isNull);
      expect(productLink('data:text/html,hi'), isNull);
      final card = ProductCard.fromJson({'name': 'x', 'url': 'https://a.it', 'image': '../etc'});
      expect(card!.image, isNull);
    });

    test('buildItems: product cards, quotes, the answer\'s seq; show_products a tool line', () {
      final items = buildItems([
        for (final e in _history()) RgEvent.fromJson(e),
        RgEvent.fromJson(
          _ev(6, 'message.user', {
            'text': 'E la Brikka?',
            'quotes': [
              {'seq': 5, 'text': 'Venus', 'start': 8, 'end': 13},
            ],
          }),
        ),
      ]);
      // As the page: show_products is a tool line too (only ask_user and propose_plan are not).
      expect(items.whereType<ToolItem>().map((t) => t.tool), ['show_products']);
      final p = items.whereType<ProductsItem>().single;
      expect(p.seq, 4);
      expect(p.products, hasLength(3));
      expect(p.products.first.price, 32.9);
      expect(items.whereType<AssistantItem>().where(showsSomething).single.seq, 5);
      final q = items.whereType<UserItem>().last.quotes.single;
      expect((q.seq, q.text, q.start, q.end), (5, 'Venus', 8, 13));
    });

    test('session.send carries the quotes; the REST route gets them as Markdown quotes', () {
      const q = Quote(text: 'Venus\nin acciaio', seq: 5, start: 8, end: 20);
      final m = sessionSendMessage('s1', 'E la Brikka?', quotes: [q], clientId: 'c1');
      expect(m['quotes'], [
        {'text': 'Venus\nin acciaio', 'seq': 5, 'start': 8, 'end': 20},
      ]);
      expect(sessionSendMessage('s1', 'x').containsKey('quotes'), isFalse);
      expect(withQuotesInText('E la Brikka?', [q]), '> Venus\n> in acciaio\n\nE la Brikka?');
    });
  });

  late FakeRedGiant server;
  final clipboard = <String>[];

  setUp(() async {
    HttpOverrides.global = null;
    server = await FakeRedGiant.start();
    server.productImages[_imgA] = _png;
    clipboard.clear();
  });
  tearDown(() => server.close());

  Future<AppController> start(
    WidgetTester tester, {
    Size size = const Size(1290, 2700),
    Locale locale = const Locale('it'),
  }) async {
    final app =
        AppController(
            tokens: MemoryTokenStore(),
            prefs: MemoryAppPrefs(),
            platform: DevicePlatform.android,
            liveEnabled: false,
          )
          ..locale = locale
          ..reduceMotion = true;
    await tester.runAsync(() async {
      await app.connect(server.base.toString(), 'secret');
    });
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(SystemChannels.platform, (
      call,
    ) async {
      if (call.method == 'Clipboard.setData') {
        clipboard.add((call.arguments as Map)['text'] as String);
      }
      return null;
    });
    addTearDown(
      () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform,
        null,
      ),
    );
    await tester.pumpWidget(RGCompanionApp(controller: app));
    await _settle(tester);
    return app;
  }

  Future<void> push(WidgetTester tester, Widget screen) async {
    final nav = tester.state<NavigatorState>(find.byType(Navigator).first);
    unawaited(nav.push(MaterialPageRoute<void>(builder: (_) => screen)));
    await _settle(tester);
  }

  void history(AppController app) =>
      app.live.apply({'type': 'session.history', 'sessionId': 's1', 'events': _history()});

  Future<void> done(WidgetTester tester) async {
    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(minutes: 3));
  }

  Future<void> selectWord(WidgetTester tester, String word) async {
    // The messages' own actions (G42.1) make them taller: the word is brought into view first.
    await tester.ensureVisible(find.text(word, findRichText: true).first);
    await tester.pumpAndSettle();
    await tester.longPress(find.text(word, findRichText: true).first);
    await tester.pumpAndSettle();
  }

  testWidgets('a selected passage: our menu, «Salva» with a note and tags', (tester) async {
    final app = await start(tester);
    server.saved.add(
      server.savedItem(id: 'old', text: 'x', tags: ['cucina'], createdAt: '2026-11-10T10:00:00Z'),
    );
    await push(tester, ConversationScreen(sessionId: 's1', agent: app.agents.first));
    history(app);
    await _settle(tester);
    await selectWord(tester, 'Moka');
    expect(find.byKey(const Key('passage-menu')), findsOneWidget);
    expect(find.byKey(const Key('sel-copy')), findsOneWidget);
    expect(find.byKey(const Key('sel-reply')), findsOneWidget);
    await tester.tap(find.byKey(const Key('sel-save')));
    await _settle(tester);
    expect(find.text('Salva questo passaggio'), findsOneWidget);
    expect(
      find.descendant(of: find.byKey(const Key('save-preview')), matching: find.text('Moka')),
      findsOneWidget,
    );
    // The tags already used are there to tap; new ones are typed.
    await tester.tap(find.byKey(const Key('tag-pick-cucina')));
    await tester.enterText(find.byKey(const Key('save-note')), 'per la nonna');
    await tester.enterText(find.byKey(const Key('save-tags')), 'regali, #Cucina');
    await tester.tap(find.byKey(const Key('save-confirm')));
    await _settle(tester);
    final b = server.savedPosts.single;
    expect(b['source'], containsPair('kind', 'session'));
    expect(b['source'], containsPair('sessionId', 's1'));
    expect(b['source'], containsPair('seq', 5));
    expect((b['source'] as Map)['start'], 0);
    expect((b['source'] as Map)['end'], 4);
    expect(b['text'], 'Moka');
    expect(b['note'], 'per la nonna');
    expect(b['tags'], ['cucina', 'regali']);
    expect(find.byKey(const Key('save-done')), findsOneWidget);
    // «Apri i Salvati» from there.
    await tester.tap(find.byKey(const Key('save-open-archive')));
    await _settle(tester);
    expect(find.byType(SavedScreen), findsOneWidget);
    await done(tester);
  });

  testWidgets('«Rispondi a questo»: the passage above the composer, sent with the message', (
    tester,
  ) async {
    final app = await start(tester);
    await push(tester, ConversationScreen(sessionId: 's1', agent: app.agents.first));
    history(app);
    await _settle(tester);
    await selectWord(tester, 'Moka');
    await tester.tap(find.byKey(const Key('sel-reply')));
    await _settle(tester);
    expect(find.byKey(const Key('quote-drafts')), findsOneWidget);
    expect(find.text('Stai rispondendo a questo passaggio'), findsOneWidget);
    // The same passage twice is there once.
    await selectWord(tester, 'Moka');
    await tester.tap(find.byKey(const Key('sel-reply')));
    await _settle(tester);
    expect(find.byKey(const Key('quote-draft-1')), findsNothing);
    await tester.enterText(find.byKey(const Key('composer-text')), 'Quale tazza?');
    await tester.tap(find.byKey(const Key('composer-send')));
    await _settle(tester);
    // Without the live socket the route takes the quote as Markdown.
    expect(server.sent.single['text'], '> Moka\n\nQuale tazza?');
    expect(find.byKey(const Key('quote-drafts')), findsNothing);
    // «Copia» copies the selection.
    await selectWord(tester, 'Moka');
    await tester.tap(find.byKey(const Key('sel-copy')));
    await _settle(tester);
    expect(clipboard, ['Moka']);
    await done(tester);
  });

  testWidgets('a whole message from its menu; a sent quote goes back to the passage', (
    tester,
  ) async {
    final app = await start(tester);
    await push(tester, ConversationScreen(sessionId: 's1', agent: app.agents.first));
    app.live.apply({
      'type': 'session.history',
      'sessionId': 's1',
      'events': [
        ..._history(),
        _ev(6, 'message.user', {
          'text': 'E la Brikka?',
          'quotes': [
            {'seq': 5, 'text': 'Venus in acciaio'},
          ],
        }),
      ],
    });
    await _settle(tester);
    await tester.tap(find.byKey(const Key('message-menu-5')));
    await _settle(tester);
    await tester.tap(find.byKey(const Key('message-save')));
    await _settle(tester);
    expect(find.text('Salva questo messaggio'), findsOneWidget);
    await tester.tap(find.byKey(const Key('save-confirm')));
    await _settle(tester);
    final b = server.savedPosts.single;
    expect(b.containsKey('text'), isFalse);
    expect(b['source'], {'kind': 'session', 'sessionId': 's1', 'seq': 5});
    await tester.tap(find.byKey(const Key('save-close')));
    await _settle(tester);
    // The quote in the person's message lights its passage up.
    expect(find.text('Venus in acciaio'), findsOneWidget);
    await tester.tap(find.byKey(const Key('quote-ref-5')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    expect(tester.widgetList<RichText>(find.byType(RichText)).any((r) => _lit(r.text)), isTrue);
    await tester.pump(const Duration(seconds: 5));
    expect(tester.widgetList<RichText>(find.byType(RichText)).any((r) => _lit(r.text)), isFalse);
    await done(tester);
  });

  testWidgets('«Salvati»: pages, search, filters, note and tags, deletion, export', (tester) async {
    server.savedPage = 2;
    server.saved.addAll([
      server.savedItem(
        id: 'i1',
        text: 'La moka va lavata solo con acqua',
        markdown: 'La **moka** va lavata solo con acqua',
        tags: ['cucina'],
        note: 'da ricordare',
        createdAt: '2026-11-16T09:00:00Z',
      ),
      server.savedItem(
        id: 'i2',
        text: 'Il treno delle 7 arriva alle 9',
        tags: ['viaggi'],
        agentId: 'a1',
        agentName: 'Coder',
        title: 'Orari',
        createdAt: '2026-11-15T09:00:00Z',
      ),
      server.savedItem(
        id: 'i3',
        text: 'Una ricetta vecchia',
        whole: true,
        tags: ['cucina'],
        createdAt: '2026-11-01T09:00:00Z',
      ),
    ]);
    final saved = <String, Uint8List>{};
    await start(tester);
    // From the Chat's header.
    await tester.tap(find.byKey(const Key('tab-chat')));
    await _settle(tester);
    await tester.tap(find.byKey(const Key('chat-saved')));
    await _settle(tester);
    expect(find.byType(SavedScreen), findsOneWidget);
    Navigator.of(tester.element(find.byType(SavedScreen))).pop();
    await _settle(tester);
    await push(
      tester,
      SavedScreen(
        saveFile: (name, bytes) async {
          saved[name] = bytes;
          return true;
        },
      ),
    );
    expect(find.byKey(const ValueKey('saved-i1')), findsOneWidget);
    expect(find.byKey(const ValueKey('saved-i2')), findsOneWidget);
    expect(find.byKey(const ValueKey('saved-i3')), findsNothing);
    expect(find.text('da ricordare'), findsOneWidget);
    expect(find.textContaining('Orari · '), findsOneWidget);
    // Older ones.
    final list = find
        .descendant(of: find.byKey(const Key('saved-list')), matching: find.byType(Scrollable))
        .first;
    await tester.scrollUntilVisible(find.byKey(const Key('saved-more')), 300, scrollable: list);
    await _tapV(tester, find.byKey(const Key('saved-more')));
    await _settle(tester);
    await tester.scrollUntilVisible(find.byKey(const ValueKey('saved-i3')), 300, scrollable: list);
    expect(find.byKey(const ValueKey('saved-i3')), findsOneWidget);
    expect(find.text('Messaggio intero'), findsOneWidget);
    expect(server.requests.last, contains('before=2026-11-15T09%3A00%3A00Z'));
    expect(find.byKey(const Key('saved-more')), findsNothing);
    // Filters: a tag, then an agent.
    await _tapV(tester, find.byKey(const Key('saved-tag-viaggi')));
    await _settle(tester);
    expect(find.byKey(const ValueKey('saved-i1')), findsNothing);
    expect(find.byKey(const ValueKey('saved-i2')), findsOneWidget);
    await _tapV(tester, find.byKey(const Key('saved-tag-all')));
    await _settle(tester);
    await _tapV(tester, find.byKey(const Key('saved-agent-a0')));
    await _settle(tester);
    expect(find.byKey(const ValueKey('saved-i2')), findsNothing);
    expect(server.requests.last, contains('agentId=a0'));
    await _tapV(tester, find.byKey(const Key('saved-agent-all')));
    await _settle(tester);
    // Search.
    await tester.enterText(find.byKey(const Key('saved-search')), 'treno');
    await tester.pump(const Duration(milliseconds: 400));
    await _settle(tester);
    expect(find.byKey(const ValueKey('saved-i1')), findsNothing);
    expect(find.byKey(const ValueKey('saved-i2')), findsOneWidget);
    // The export follows the filters: the Markdown copied, then as a file.
    await _tapV(tester, find.byKey(const Key('saved-export')));
    await _settle(tester);
    await tester.tap(find.byKey(const Key('export-copy')));
    await _settle(tester);
    expect(server.savedExports.last, {'q': 'treno', 'lang': 'it'});
    expect(clipboard.single, contains('Il treno delle 7'));
    expect(find.text('Markdown copiato: incollalo dove vuoi.'), findsOneWidget);
    await _tapV(tester, find.byKey(const Key('saved-export')));
    await _settle(tester);
    await tester.tap(find.byKey(const Key('export-file')));
    await _settle(tester);
    expect(utf8.decode(saved['salvati.md']!), startsWith('# Salvati'));
    await tester.enterText(find.byKey(const Key('saved-search')), '');
    await tester.pump(const Duration(milliseconds: 400));
    await _settle(tester);
    // Note and tags.
    await _tapV(tester, find.byKey(const Key('saved-edit-i1')));
    await _settle(tester);
    await tester.enterText(find.byKey(const Key('saved-note-i1')), 'da rifare');
    await _tapV(tester, find.byKey(const Key('tag-pick-cucina')));
    await tester.enterText(find.byKey(const Key('saved-tags-i1')), 'casa');
    await _tapV(tester, find.byKey(const Key('saved-save-i1')));
    await _settle(tester);
    expect(server.savedPatches.single, {
      'id': 'i1',
      'note': 'da rifare',
      'tags': ['casa'],
    });
    expect(find.text('da rifare'), findsOneWidget);
    // Deletion asks first: no keeps it, yes deletes.
    await _tapV(tester, find.byKey(const Key('saved-delete-i1')));
    await _settle(tester);
    expect(find.text('Eliminare questo salvato?'), findsOneWidget);
    await tester.tap(find.byKey(const Key('dialog-no')));
    await _settle(tester);
    expect(server.savedDeletes, isEmpty);
    await _tapV(tester, find.byKey(const Key('saved-delete-i1')));
    await _settle(tester);
    await tester.tap(find.byKey(const Key('dialog-yes')));
    await _settle(tester);
    expect(server.savedDeletes, ['i1']);
    expect(find.byKey(const ValueKey('saved-i1')), findsNothing);
    await done(tester);
  });

  testWidgets('«Salvati» › Apri: the conversation at the message, the passage lit up', (
    tester,
  ) async {
    server.saved.add(
      server.savedItem(
        id: 'i1',
        text: 'Venus in acciaio va anche',
        seq: 5,
        start: 8,
        end: 33,
        createdAt: '2026-11-16T09:00:00Z',
      ),
    );
    final app = await start(tester);
    await push(tester, const SavedScreen());
    await _tapV(tester, find.byKey(const Key('saved-open-i1')));
    await _settle(tester);
    final screen = tester.widget<ConversationScreen>(find.byType(ConversationScreen));
    expect(screen.jump?.seq, 5);
    history(app);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    expect(tester.widgetList<RichText>(find.byType(RichText)).any((r) => _lit(r.text)), isTrue);
    await tester.pump(const Duration(seconds: 5));
    await done(tester);
  });

  testWidgets('a passage not found lights the whole message; a message gone is said', (
    tester,
  ) async {
    final app = await start(tester);
    await push(
      tester,
      ConversationScreen(
        sessionId: 's1',
        agent: app.agents.first,
        jump: const PassageJump(seq: 5, text: 'parole che non ci sono'),
      ),
    );
    history(app);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    final box = tester.widget<AnimatedContainer>(find.byKey(const Key('answer-5')));
    expect((box.decoration! as BoxDecoration).color, isNotNull);
    await tester.pump(const Duration(seconds: 5));
    Navigator.of(tester.element(find.byType(ConversationScreen))).pop();
    await _settle(tester);
    await push(
      tester,
      ConversationScreen(
        sessionId: 's1',
        agent: app.agents.first,
        jump: const PassageJump(seq: 99, text: 'x'),
      ),
    );
    history(app);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.text('Il messaggio non è più nella conversazione.'), findsOneWidget);
    await done(tester);
  });

  testWidgets('product cards in the conversation: pictures from the server, placeholders', (
    tester,
  ) async {
    final app = await start(tester);
    await push(tester, ConversationScreen(sessionId: 's1', agent: app.agents.first));
    history(app);
    await _settle(tester);
    expect(find.byKey(const Key('products-4')), findsOneWidget);
    expect(find.text('Moka da 3-4 tazze'), findsOneWidget);
    expect(find.text('Bialetti Moka Express 3 tazze'), findsOneWidget);
    expect(find.text('32,90 €'), findsOneWidget);
    expect(find.text('Bialetti'), findsOneWidget);
    expect(find.text('La classica in alluminio.'), findsOneWidget);
    // A's picture from the server with the device's token; B's is a 404: the placeholder.
    final asked = server.requests.where((r) => r.contains('/api/products/images/')).toList();
    expect(asked, contains('GET /api/products/images/$_imgA'));
    expect(find.byKey(const Key('product-picture')), findsOneWidget);
    expect(find.byKey(const Key('product-no-picture')), findsWidgets);
    // No tool row for show_products.
    expect(find.text('show_products'), findsNothing);
    await done(tester);
  });

  testWidgets('a card opens only http/https, and only when pressed', (tester) async {
    final opened = <Uri>[];
    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('en'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: ProductCarousel(
            products: [
              ProductCard.fromJson({
                'name': 'Good',
                'url': 'https://shop.example/good',
                'price': 45,
                'currency': 'USD',
                'source': 3,
              })!,
              ProductCard.fromJson({'name': 'Bad', 'url': 'javascript:alert(1)'})!,
            ],
            load: (_) async => null,
            open: (u) async => opened.add(u),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    final semantics = tester.ensureSemantics();
    expect(opened, isEmpty);
    expect(find.text(r'$45.00'), findsOneWidget);
    expect(find.byKey(const Key('product-open')), findsOneWidget);
    expect(find.byKey(const Key('product-source')), findsOneWidget);
    expect(find.bySemanticsLabel('Source 3 of the answer'), findsOneWidget);
    await tester.tap(find.byKey(const Key('product-open')));
    await tester.pump();
    expect(opened, [Uri.parse('https://shop.example/good')]);
    semantics.dispose();
  });

  testWidgets('a tablet held sideways: the chat beside the diff has no «back»', (tester) async {
    server.sessions.add({
      'id': 's9',
      'agentId': 'a1',
      'projectId': 'demo',
      'createdAt': '2026-11-15T09:00:00.000Z',
      'lastAt': '2026-11-15T09:10:00.000Z',
      'title': 'Prices',
      'archived': false,
      'running': false,
    });
    final app = await start(tester, size: const Size(3600, 2400));
    app.setAdvanced(true);
    await _settle(tester);
    await push(
      tester,
      const ProjectScreen(
        project: Project(id: 'demo', name: 'Demo'),
        initial: ProjectTab.diff,
      ),
    );
    await _settle(tester);
    expect(find.byType(ConversationScreen), findsOneWidget);
    expect(find.byKey(const Key('conversation-back')), findsNothing);
    await done(tester);
  });
}

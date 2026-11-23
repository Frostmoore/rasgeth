// Search widgets (3.12.2) in the app: the `found.shown` event becomes an item (the same data as
// the page's), the gallery shows one big and four small with «All», trains and flights have «Choose»
// that only writes to the agent, a route is drawn with the way chips and «Open in Maps», broken or
// unsafe pictures show a placeholder, and every widget keeps to the fixed largest width.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rgcompanion/api/conversation.dart';
import 'package:rgcompanion/api/found.dart';
import 'package:rgcompanion/api/products.dart';
import 'package:rgcompanion/l10n/app_localizations.dart';
import 'package:rgcompanion/ui/found_widgets.dart';
import 'package:rgcompanion/ui/product_cards.dart';

final _gallery = {
  'kind': 'gallery',
  'title': 'Fontana di Trevi',
  'source': 'Wikimedia',
  'images': [
    for (var i = 0; i < 7; i++)
      {
        'url': 'https://img.example/$i.jpg',
        'thumbUrl': 'https://img.example/t$i.jpg',
        'title': 'Foto $i',
        'pageUrl': 'https://page.example/$i',
      },
  ],
};
final _trips = {
  'kind': 'trips',
  'mode': 'train',
  'from': 'Milano C.le',
  'to': 'Roma Termini',
  'date': 'ven 27 nov',
  'operators': 'Trenitalia e Italo',
  'offers': [
    {
      'departs': '06:20',
      'arrives': '09:15',
      'duration': '2 h 55',
      'stops': 0,
      'label': 'Frecciarossa 9505',
      'operator': 'Trenitalia',
      'price': 39.9,
      'currency': 'EUR',
      'availability': 'posti liberi',
    },
    {'departs': '07:35', 'arrives': '10:45', 'stops': 1, 'label': 'Frecciarossa 9515'},
  ],
};
final _route = {
  'kind': 'route',
  'from': {'name': 'Termini', 'lat': 41.9009, 'lon': 12.5016},
  'to': {'name': 'Colosseo', 'lat': 41.8902, 'lon': 12.4922},
  'points': [
    {'lat': 41.9009, 'lon': 12.5016},
    {'lat': 41.8955, 'lon': 12.4985},
    {'lat': 41.8902, 'lon': 12.4922},
  ],
  'options': [
    {
      'mode': 'walk',
      'durationMin': 22,
      'distanceM': 1700,
      'steps': [
        {'text': 'Esci su piazza dei Cinquecento', 'minute': 0},
        {'text': 'Via Cavour', 'minute': 12},
      ],
    },
    {
      'mode': 'transit',
      'durationMin': 8,
      'steps': [
        {'text': 'Metro B, 2 fermate'},
      ],
    },
  ],
  'note': 'Con la metro B sono 2 fermate.',
};

Widget _host(Widget child, {String locale = 'en'}) => MaterialApp(
  locale: Locale(locale),
  localizationsDelegates: AppLocalizations.localizationsDelegates,
  supportedLocales: AppLocalizations.supportedLocales,
  home: Scaffold(body: SingleChildScrollView(child: child)),
);

void main() {
  test('found.shown becomes an item, bad data is left out', () {
    RgEvent e(int seq, Map<String, Object?> p) =>
        RgEvent(seq: seq, ts: '2026-11-23T10:00:00.000Z', type: 'found.shown', payload: p);
    final items = buildItems([
      e(3, _gallery),
      e(4, _trips),
      e(5, _route),
      e(6, {
        'kind': 'gallery',
        'images': [
          {'url': 'javascript:alert(1)'},
        ],
      }),
      e(7, {'kind': 'hologram'}),
    ]);
    expect(items.whereType<FoundItem>().map((i) => i.widget.kind), ['gallery', 'trips', 'route']);
    final g = items.whereType<FoundItem>().first.widget as GalleryFound;
    expect(g.images, hasLength(7));
    expect(g.images.first.pageUrl, 'https://page.example/0');
  });

  test('only http(s) pictures and valid points are kept; the maps link is the page\'s', () {
    expect(webAddress('https://a.example/x.jpg'), isNotNull);
    expect(webAddress('data:text/html,<b>x</b>'), isNull);
    expect(webAddress('file:///etc/passwd'), isNull);
    expect(GeoPoint.fromJson({'lat': 95, 'lon': 0}), isNull);
    final r = FoundWidget.fromJson(_route)! as RouteFound;
    expect(
      r.mapsLink(r.options.first).toString(),
      'https://www.google.com/maps/dir/?api=1&origin=41.900900,12.501600'
      '&destination=41.890200,12.492200&travelmode=walking',
    );
    final d = drawRoute(r.lineOf(r.options.first), 560, 260);
    // North is up: the start (Termini) is north of the end (Colosseo).
    expect(d.start.y, lessThan(d.end.y));
    expect(d.start.x, greaterThanOrEqualTo(28));
  });

  testWidgets('a gallery: one big and four small, «All» opens every picture', (tester) async {
    final opened = <Uri>[];
    await tester.pumpWidget(
      _host(FoundCard(widget: FoundWidget.fromJson(_gallery)!, open: (u) async => opened.add(u))),
    );
    await tester.pumpAndSettle();
    for (var i = 0; i < 5; i++) {
      expect(find.byKey(Key('found-tile-$i')), findsOneWidget);
    }
    expect(find.byKey(const Key('found-tile-5')), findsNothing);
    expect(find.text('+2'), findsOneWidget);
    expect(find.text('Pictures from the web'), findsNothing);
    expect(find.text('Fontana di Trevi'), findsOneWidget);
    // The test client cannot load them: the neutral placeholder, never an error.
    expect(find.byKey(const Key('found-no-picture')), findsWidgets);
    await tester.tap(find.byKey(const Key('found-all')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('found-dialog')), findsOneWidget);
    for (var i = 0; i < 7; i++) {
      expect(find.byKey(Key('found-grid-$i')), findsOneWidget);
    }
    await tester.tap(find.byKey(const Key('found-grid-2')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('found-pic-https://img.example/2.jpg')), findsOneWidget);
    await tester.tap(find.byKey(const Key('found-page')));
    expect(opened, [Uri.parse('https://page.example/2')]);
    await tester.tap(find.byKey(const Key('found-next')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('found-pic-https://img.example/3.jpg')), findsOneWidget);
    await tester.tap(find.byKey(const Key('found-back-all')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('found-grid-6')), findsOneWidget);
  });

  testWidgets('trains: times, stops, price; «Choose» only writes to the agent', (tester) async {
    final said = <String>[];
    await tester.pumpWidget(
      _host(FoundCard(widget: FoundWidget.fromJson(_trips)!, onChoose: (t) async => said.add(t))),
    );
    await tester.pumpAndSettle();
    expect(find.text('Milano C.le → Roma Termini · ven 27 nov'), findsOneWidget);
    expect(find.text('06:20 → 09:15'), findsOneWidget);
    expect(find.text('2 h 55 · direct · Trenitalia'), findsOneWidget);
    expect(find.text('1 stop'), findsOneWidget);
    expect(find.text(r'€39.90'), findsOneWidget);
    expect(find.text('posti liberi'), findsOneWidget);
    expect(said, isEmpty);
    await tester.tap(find.byKey(const Key('found-choose')).first);
    await tester.pump();
    expect(said, hasLength(1));
    expect(said.single, contains('I choose the train Frecciarossa 9505'));
    expect(said.single, contains('Ask me to confirm before you book or pay'));
  });

  testWidgets('trains in Italian: «diretto», «Scegli» and the message in Italian', (tester) async {
    final said = <String>[];
    await tester.pumpWidget(
      _host(
        FoundCard(widget: FoundWidget.fromJson(_trips)!, onChoose: (t) async => said.add(t)),
        locale: 'it',
      ),
    );
    await tester.pumpAndSettle();
    expect(find.textContaining('diretto'), findsOneWidget);
    expect(find.text('Scegli'), findsNWidgets(2));
    await tester.tap(find.byKey(const Key('found-choose')).first);
    expect(said.single, contains('Scelgo il treno Frecciarossa 9505'));
    expect(said.single, contains('Chiedimi conferma prima di prenotare o pagare'));
  });

  testWidgets('a route: the drawn map, the ways, the steps, «Open in Maps»', (tester) async {
    final opened = <Uri>[];
    await tester.pumpWidget(
      _host(FoundCard(widget: FoundWidget.fromJson(_route)!, open: (u) async => opened.add(u))),
    );
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('found-map')), findsOneWidget);
    expect(find.text('22 min'), findsOneWidget);
    expect(find.text('on foot · 1.7 km'), findsOneWidget);
    expect(find.byKey(const Key('found-steps')), findsOneWidget);
    expect(find.text('Via Cavour'), findsOneWidget);
    await tester.tap(find.byKey(const Key('found-maps')));
    expect(opened.single.queryParameters['travelmode'], 'walking');
    await tester.tap(find.byKey(const Key('found-mode-transit')));
    await tester.pumpAndSettle();
    expect(find.text('8 min'), findsOneWidget);
    expect(find.text('Metro B, 2 fermate'), findsOneWidget);
    await tester.tap(find.byKey(const Key('found-maps')));
    expect(opened.last.queryParameters['travelmode'], 'transit');
  });

  testWidgets('a product card shows its stars and opens the shop when tapped', (tester) async {
    final opened = <Uri>[];
    await tester.pumpWidget(
      _host(
        ProductCarousel(
          products: [
            ProductCard.fromJson({
              'name': 'Aurio Wave 3',
              'url': 'https://shop.example/aurio',
              'price': 89.9,
              'currency': 'EUR',
              'rating': 4.6,
              'reviews': 120,
            })!,
          ],
          load: (_) async => null,
          open: (u) async => opened.add(u),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('product-stars')), findsOneWidget);
    expect(find.text('4.6'), findsOneWidget);
    expect(find.text(' (120)'), findsOneWidget);
    await tester.tap(find.byKey(const Key('product-tap')));
    expect(opened, [Uri.parse('https://shop.example/aurio')]);
  });

  testWidgets('every widget keeps to 640 px on a large screen, the whole line on a phone', (
    tester,
  ) async {
    Future<double> widthOf(Size size, Widget child, Key key) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(_host(child));
      await tester.pumpAndSettle();
      return tester.getSize(find.byKey(key)).width;
    }

    final trips = FoundCard(widget: FoundWidget.fromJson(_trips)!);
    expect(await widthOf(const Size(1600, 900), trips, const Key('found-trips')), 640);
    expect(await widthOf(const Size(360, 800), trips, const Key('found-trips')), 360);
    expect(chatWidgetMax, 640);
  });
}

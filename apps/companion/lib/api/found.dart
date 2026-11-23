// Search widgets (3.12.2) as the app reads them: the `found.shown` event's payload
// (`packages/protocol/src/found.ts`), as the page's FoundWidgets. A gallery of pictures, trains or
// flights, a route on a drawn map. Pictures are plain http(s) addresses (never rendered as HTML),
// the map is drawn from the route's points, and «Open in Maps» opens the system's maps.
import 'dart:math' as math;

import 'products.dart' show productLink;

String? _s(Object? o) => o is String && o.trim().isNotEmpty ? o : null;
double? _d(Object? o) => o is num ? o.toDouble() : null;
List<Object?> _l(Object? o) => o is List ? o : const [];

/// An address that may be loaded or opened: http or https with a host, nothing else.
String? webAddress(Object? o) {
  final s = _s(o);
  return s == null || productLink(s) == null ? null : s;
}

class GeoPoint {
  const GeoPoint(this.lat, this.lon);
  final double lat;
  final double lon;

  static GeoPoint? fromJson(Object? o) {
    if (o is! Map) return null;
    final lat = _d(o['lat']);
    final lon = _d(o['lon']);
    if (lat == null || lon == null || lat.abs() > 90 || lon.abs() > 180) return null;
    return GeoPoint(lat, lon);
  }
}

sealed class FoundWidget {
  const FoundWidget();

  /// null: not a widget this app knows (a newer server's kind, or a broken one).
  static FoundWidget? fromJson(Object? o) {
    if (o is! Map) return null;
    return switch (o['kind']) {
      'gallery' => GalleryFound.fromJson(o),
      'trips' => TripsFound.fromJson(o),
      'route' => RouteFound.fromJson(o),
      _ => null,
    };
  }

  String get kind;
}

class GalleryImage {
  const GalleryImage({required this.url, this.thumbUrl, this.title, this.pageUrl});
  final String url;
  final String? thumbUrl;
  final String? title;
  final String? pageUrl;
}

class GalleryFound extends FoundWidget {
  const GalleryFound({required this.images, this.title, this.source});

  static GalleryFound? fromJson(Map<dynamic, dynamic> o) {
    final images = <GalleryImage>[];
    for (final i in _l(o['images'])) {
      if (i is! Map) continue;
      final url = webAddress(i['url']);
      if (url == null) continue;
      images.add(
        GalleryImage(
          url: url,
          thumbUrl: webAddress(i['thumbUrl']),
          title: _s(i['title']),
          pageUrl: webAddress(i['pageUrl']),
        ),
      );
    }
    if (images.isEmpty) return null;
    return GalleryFound(images: images, title: _s(o['title']), source: _s(o['source']));
  }

  final List<GalleryImage> images;
  final String? title;
  final String? source;

  @override
  String get kind => 'gallery';
}

class TripOffer {
  const TripOffer({
    required this.departs,
    required this.arrives,
    required this.label,
    this.duration,
    this.stops = 0,
    this.operator,
    this.price,
    this.currency,
    this.availability,
  });

  final String departs;
  final String arrives;
  final String label;
  final String? duration;
  final int stops;
  final String? operator;
  final double? price;
  final String? currency;
  final String? availability;
}

class TripsFound extends FoundWidget {
  const TripsFound({
    required this.flight,
    required this.from,
    required this.to,
    required this.offers,
    this.date,
    this.operators,
  });

  static TripsFound? fromJson(Map<dynamic, dynamic> o) {
    final from = _s(o['from']);
    final to = _s(o['to']);
    final offers = <TripOffer>[];
    for (final i in _l(o['offers'])) {
      if (i is! Map) continue;
      final departs = _s(i['departs']);
      final arrives = _s(i['arrives']);
      final label = _s(i['label']);
      if (departs == null || arrives == null || label == null) continue;
      final currency = _s(i['currency']);
      offers.add(
        TripOffer(
          departs: departs,
          arrives: arrives,
          label: label,
          duration: _s(i['duration']),
          stops: i['stops'] is num ? (i['stops'] as num).toInt() : 0,
          operator: _s(i['operator']),
          price: _d(i['price']),
          currency: currency != null && RegExp(r'^[A-Z]{3}$').hasMatch(currency) ? currency : null,
          availability: _s(i['availability']),
        ),
      );
    }
    if (from == null || to == null || offers.isEmpty) return null;
    return TripsFound(
      flight: o['mode'] == 'flight',
      from: from,
      to: to,
      offers: offers,
      date: _s(o['date']),
      operators: _s(o['operators']),
    );
  }

  final bool flight;
  final String from;
  final String to;
  final String? date;
  final String? operators;
  final List<TripOffer> offers;

  @override
  String get kind => 'trips';
}

class RouteStep {
  const RouteStep(this.text, this.minute);
  final String text;
  final double? minute;
}

class RouteOption {
  const RouteOption({
    required this.mode,
    required this.durationMin,
    this.distanceM,
    this.steps = const [],
    this.points,
  });

  /// walk, transit or drive.
  final String mode;
  final double durationMin;
  final double? distanceM;
  final List<RouteStep> steps;
  final List<GeoPoint>? points;
}

class RouteFound extends FoundWidget {
  const RouteFound({
    required this.fromName,
    required this.from,
    required this.toName,
    required this.to,
    required this.options,
    this.title,
    this.points,
    this.note,
  });

  static List<GeoPoint>? _points(Object? o) {
    final p = [for (final x in _l(o)) ?GeoPoint.fromJson(x)];
    return p.length >= 2 ? p : null;
  }

  static RouteFound? fromJson(Map<dynamic, dynamic> o) {
    final from = GeoPoint.fromJson(o['from']);
    final to = GeoPoint.fromJson(o['to']);
    final fromName = o['from'] is Map ? _s((o['from'] as Map)['name']) : null;
    final toName = o['to'] is Map ? _s((o['to'] as Map)['name']) : null;
    final options = <RouteOption>[];
    for (final i in _l(o['options'])) {
      if (i is! Map) continue;
      final mode = i['mode'];
      final min = _d(i['durationMin']);
      if (mode is! String || !const ['walk', 'transit', 'drive'].contains(mode) || min == null) {
        continue;
      }
      options.add(
        RouteOption(
          mode: mode,
          durationMin: min,
          distanceM: _d(i['distanceM']),
          steps: [
            for (final s in _l(i['steps']))
              if (s is Map && _s(s['text']) != null) RouteStep(_s(s['text'])!, _d(s['minute'])),
          ],
          points: _points(i['points']),
        ),
      );
    }
    if (from == null || to == null || fromName == null || toName == null || options.isEmpty) {
      return null;
    }
    return RouteFound(
      title: _s(o['title']),
      fromName: fromName,
      from: from,
      toName: toName,
      to: to,
      points: _points(o['points']),
      options: options,
      note: _s(o['note']),
    );
  }

  final String? title;
  final String fromName;
  final GeoPoint from;
  final String toName;
  final GeoPoint to;
  final List<GeoPoint>? points;
  final List<RouteOption> options;
  final String? note;

  @override
  String get kind => 'route';

  /// The line drawn for [o]: its own points, else the shared ones, else a straight line.
  List<GeoPoint> lineOf(RouteOption o) => o.points ?? points ?? [from, to];

  /// The page to open the route in the system's maps (the same as the page's `mapsLink`).
  Uri mapsLink(RouteOption o) {
    final m = switch (o.mode) {
      'walk' => 'walking',
      'transit' => 'transit',
      _ => 'driving',
    };
    String q(GeoPoint p) => '${p.lat.toStringAsFixed(6)},${p.lon.toStringAsFixed(6)}';
    return Uri.parse(
      'https://www.google.com/maps/dir/?api=1&origin=${q(from)}&destination=${q(to)}&travelmode=$m',
    );
  }
}

/// The route's drawing: points in a box, the same projection as the page's `drawRoute`.
class MapDrawing {
  const MapDrawing(this.points, this.start, this.end);
  final List<({double x, double y})> points;
  final ({double x, double y}) start;
  final ({double x, double y}) end;
}

MapDrawing drawRoute(List<GeoPoint> pts, double width, double height, {double pad = 28}) {
  final lats = [for (final p in pts) p.lat];
  final midLat = (lats.reduce(math.min) + lats.reduce(math.max)) / 2;
  final k = math.max(0.05, math.cos(midLat * math.pi / 180));
  final xs = [for (final p in pts) p.lon * k];
  final ys = [for (final p in pts) -p.lat];
  final minX = xs.reduce(math.min);
  final minY = ys.reduce(math.min);
  final spanX = math.max(1e-9, xs.reduce(math.max) - minX);
  final spanY = math.max(1e-9, ys.reduce(math.max) - minY);
  final scale = math.min((width - 2 * pad) / spanX, (height - 2 * pad) / spanY);
  final offX = (width - spanX * scale) / 2;
  final offY = (height - spanY * scale) / 2;
  final out = [
    for (var i = 0; i < pts.length; i++)
      (x: offX + (xs[i] - minX) * scale, y: offY + (ys[i] - minY) * scale),
  ];
  return MapDrawing(out, out.first, out.last);
}

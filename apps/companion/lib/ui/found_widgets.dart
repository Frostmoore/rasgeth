// Search widgets (3.12.2): what `show_results` showed, inside the answer, as the page's
// FoundWidgets. A gallery (one big picture and four small, «All» opens them all), trains or flights
// as rows with «Choose», a route on a drawn map with the steps and «Open in Maps». Pictures are
// plain http(s) addresses loaded by the app, a broken one shows a neutral placeholder; the map is
// drawn from the route's points. «Choose» only tells the agent (a message), which asks the person
// before anything is booked or paid. Like every widget of a conversation, at most 640 px wide.
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart' show NumberFormat;
import 'package:url_launcher/url_launcher.dart';

import '../api/found.dart';
import '../api/products.dart' show priceText;
import '../app_state.dart';
import '../l10n/app_localizations.dart';
import '../theme/colors.dart';
import 'dialogs.dart' show showRgWindow;
import 'icons.dart';

/// The fixed largest width of a widget in a conversation on large screens (the page's
/// `--chat-widget-max`); narrower screens, and phones, take the whole line.
const double chatWidgetMax = 640;

/// Opens a page or the system's maps (tests give their own).
typedef FoundOpener = Future<void> Function(Uri link);

/// Writes to the agent in this conversation (tests give their own).
typedef FoundSender = Future<void> Function(String text);

Future<void> _openOutside(Uri link) async {
  await launchUrl(link, mode: LaunchMode.externalApplication);
}

/// Keeps a widget of a conversation to its largest width, left-aligned.
class ChatWidgetBox extends StatelessWidget {
  const ChatWidgetBox({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) => Align(
    alignment: Alignment.centerLeft,
    child: ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: chatWidgetMax),
      child: child,
    ),
  );
}

/// «22 min», «1 h 05 min».
String minutesText(AppLocalizations l, double n) {
  final m = n.round().clamp(0, 1000000);
  return m < 60
      ? l.cvFoundMinutes('$m')
      : l.cvFoundHours('${m ~/ 60}', (m % 60).toString().padLeft(2, '0'));
}

/// «450 m», «1,7 km».
String distanceText(double m, String locale) {
  if (m < 1000) return '${m.round()} m';
  return '${NumberFormat.decimalPatternDigits(locale: locale, decimalDigits: m / 1000 < 10 ? 1 : 0).format(m / 1000)} km';
}

/// What «Choose» tells the agent (the page's `chooseText`).
String chooseText(AppLocalizations l, TripsFound w, TripOffer o) {
  final price = o.price == null ? '' : ', ${priceText(o.price, o.currency, l.localeName)}';
  return l.cvFoundChooseText(
    w.flight ? l.cvFoundKindFlight : l.cvFoundKindTrain,
    o.label,
    o.departs,
    o.arrives,
    w.from,
    w.to,
    w.date == null ? '' : ', ${w.date}',
    price,
  );
}

class FoundCard extends StatelessWidget {
  const FoundCard({super.key, required this.widget, this.onChoose, this.open});

  final FoundWidget widget;

  /// «Choose» on an offer: null where the conversation cannot be written in (read only).
  final FoundSender? onChoose;
  final FoundOpener? open;

  @override
  Widget build(BuildContext context) {
    final c = RgColors.of(context);
    final opener = open ?? _openOutside;
    return ChatWidgetBox(
      child: Container(
        key: Key('found-${widget.kind}'),
        margin: const EdgeInsets.symmetric(vertical: 4),
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
        decoration: BoxDecoration(
          color: c.panel,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: c.line),
        ),
        child: switch (widget) {
          final GalleryFound g => _Gallery(w: g, open: opener),
          final TripsFound t => _Trips(w: t, onChoose: onChoose),
          final RouteFound r => _Route(w: r, open: opener),
        },
      ),
    );
  }
}

class _Head extends StatelessWidget {
  const _Head({required this.icon, required this.title, this.sub});

  final RgIcons icon;
  final String title;
  final String? sub;

  @override
  Widget build(BuildContext context) {
    final c = RgColors.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Wrap(
        crossAxisAlignment: WrapCrossAlignment.center,
        spacing: 12,
        runSpacing: 2,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              RgIcon(icon, size: 15, color: c.text),
              const SizedBox(width: 7),
              Flexible(
                child: Text(
                  title,
                  style: TextStyle(color: c.text, fontWeight: FontWeight.w700, fontSize: 14),
                ),
              ),
            ],
          ),
          if (sub != null) Text(sub!, style: TextStyle(color: c.dim, fontSize: 12.5)),
        ],
      ),
    );
  }
}

/// One picture: loaded by the app from its http(s) address, a neutral placeholder when it fails.
class _Pic extends StatelessWidget {
  const _Pic({required this.url, this.fit = BoxFit.cover});

  final String url;
  final BoxFit fit;

  @override
  Widget build(BuildContext context) {
    final c = RgColors.of(context);
    final l = AppLocalizations.of(context);
    final empty = Semantics(
      label: l.cvFoundImageBroken,
      child: Container(
        key: const Key('found-no-picture'),
        color: c.panel2,
        alignment: Alignment.center,
        child: RgIcon(RgIcons.image, size: 26, color: c.dim),
      ),
    );
    if (webAddress(url) == null) return empty;
    return Image.network(
      url,
      key: Key('found-pic-$url'),
      fit: fit,
      width: double.infinity,
      height: double.infinity,
      errorBuilder: (_, _, _) => empty,
      loadingBuilder: (_, child, p) => p == null ? child : ColoredBox(color: c.panel2),
    );
  }
}

class _Gallery extends StatelessWidget {
  const _Gallery({required this.w, required this.open});

  final GalleryFound w;
  final FoundOpener open;

  void _all(BuildContext context, [int? at]) {
    unawaited(
      showRgWindow<void>(
        context: context,
        builder: (_) => _GalleryDialog(w: w, open: open, at: at),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final c = RgColors.of(context);
    final shown = w.images.take(5).toList();
    final more = w.images.length - 5;
    Widget tile(int i, {bool main = false}) => GestureDetector(
      key: Key('found-tile-$i'),
      onTap: () => _all(context, i),
      child: Semantics(
        button: true,
        label: shown[i].title ?? l.cvFoundOpenPicture,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: Stack(
            fit: StackFit.expand,
            children: [
              _Pic(url: main ? shown[i].url : (shown[i].thumbUrl ?? shown[i].url)),
              if (i == 4 && more > 0)
                ColoredBox(
                  color: const Color(0x80000000),
                  child: Center(
                    child: Text(
                      '+$more',
                      key: const Key('found-more'),
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        fontSize: 18,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
    final grid = shown.length == 1
        ? tile(0, main: true)
        : Row(
            children: [
              Expanded(flex: 2, child: tile(0, main: true)),
              const SizedBox(width: 6),
              Expanded(
                child: Column(
                  children: [
                    for (var i = 1; i < shown.length; i += 2)
                      Expanded(
                        child: Padding(
                          padding: EdgeInsets.only(bottom: i + 2 < shown.length ? 6 : 0),
                          child: tile(i),
                        ),
                      ),
                  ],
                ),
              ),
              if (shown.length > 2) ...[
                const SizedBox(width: 6),
                Expanded(
                  child: Column(
                    children: [
                      for (var i = 2; i < shown.length; i += 2)
                        Expanded(
                          child: Padding(
                            padding: EdgeInsets.only(bottom: i + 2 < shown.length ? 6 : 0),
                            child: tile(i),
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ],
          );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _Head(icon: RgIcons.image, title: w.title ?? l.cvFoundGalleryTitle, sub: w.source),
        SizedBox(height: 240, child: grid),
        if (w.images.length > 1)
          Padding(
            padding: const EdgeInsets.only(top: 12),
            child: OutlinedButton(
              key: const Key('found-all'),
              style: OutlinedButton.styleFrom(
                foregroundColor: c.text,
                backgroundColor: c.panel2,
                side: BorderSide(color: c.line),
                shape: const StadiumBorder(),
              ),
              onPressed: () => _all(context),
              child: Text('${l.cvFoundAll} (${w.images.length})'),
            ),
          ),
      ],
    );
  }
}

class _GalleryDialog extends StatefulWidget {
  const _GalleryDialog({required this.w, required this.open, this.at});

  final GalleryFound w;
  final FoundOpener open;
  final int? at;

  @override
  State<_GalleryDialog> createState() => _GalleryDialogState();
}

class _GalleryDialogState extends State<_GalleryDialog> {
  int? _at;

  @override
  void initState() {
    super.initState();
    _at = widget.at;
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final c = RgColors.of(context);
    final images = widget.w.images;
    final at = _at;
    final big = at == null ? null : images[at];
    final page = big?.pageUrl == null ? null : Uri.tryParse(big!.pageUrl!);
    return Dialog(
      key: const Key('found-dialog'),
      backgroundColor: c.panel,
      insetPadding: const EdgeInsets.all(16),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 720, maxHeight: 640),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      widget.w.title ?? l.cvFoundAllTitle('${images.length}'),
                      style: TextStyle(color: c.text, fontWeight: FontWeight.w700, fontSize: 15),
                    ),
                  ),
                  IconButton(
                    key: const Key('found-close'),
                    tooltip: l.cvFoundClose,
                    onPressed: () => Navigator.of(context).pop(),
                    icon: RgIcon(RgIcons.x, size: 18, color: c.dim),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Flexible(
                child: big != null
                    ? Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Flexible(
                            child: SizedBox(
                              height: 380,
                              child: _Pic(url: big.url, fit: BoxFit.contain),
                            ),
                          ),
                          Row(
                            children: [
                              IconButton(
                                key: const Key('found-prev'),
                                tooltip: l.cvFoundPrevious,
                                onPressed: at! > 0 ? () => setState(() => _at = at - 1) : null,
                                icon: RgIcon(RgIcons.chevronLeft, size: 18, color: c.text),
                              ),
                              Expanded(
                                child: Column(
                                  children: [
                                    if (big.title != null)
                                      Text(
                                        big.title!,
                                        textAlign: TextAlign.center,
                                        style: TextStyle(color: c.text, fontSize: 13),
                                      ),
                                    if (page != null)
                                      TextButton(
                                        key: const Key('found-page'),
                                        onPressed: () => unawaited(widget.open(page)),
                                        child: Text(
                                          l.cvFoundOpenPage,
                                          style: TextStyle(color: c.accent),
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                              IconButton(
                                key: const Key('found-next'),
                                tooltip: l.cvFoundNext,
                                onPressed: at < images.length - 1
                                    ? () => setState(() => _at = at + 1)
                                    : null,
                                icon: RgIcon(RgIcons.chevronRight, size: 18, color: c.text),
                              ),
                            ],
                          ),
                          TextButton(
                            key: const Key('found-back-all'),
                            onPressed: () => setState(() => _at = null),
                            child: Text(l.cvFoundAll),
                          ),
                        ],
                      )
                    : GridView.count(
                        shrinkWrap: true,
                        crossAxisCount: 3,
                        mainAxisSpacing: 8,
                        crossAxisSpacing: 8,
                        childAspectRatio: 4 / 3,
                        children: [
                          for (var i = 0; i < images.length; i++)
                            GestureDetector(
                              key: Key('found-grid-$i'),
                              onTap: () => setState(() => _at = i),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: _Pic(url: images[i].thumbUrl ?? images[i].url),
                              ),
                            ),
                        ],
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Trips extends StatelessWidget {
  const _Trips({required this.w, required this.onChoose});

  final TripsFound w;
  final FoundSender? onChoose;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final c = RgColors.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _Head(
          icon: w.flight ? RgIcons.plane : RgIcons.train,
          title: '${w.from} → ${w.to}${w.date == null ? '' : ' · ${w.date}'}',
          sub: w.operators,
        ),
        for (var i = 0; i < w.offers.length; i++)
          Padding(
            padding: EdgeInsets.only(bottom: i < w.offers.length - 1 ? 8 : 0),
            child: _Offer(
              key: Key('found-offer-$i'),
              o: w.offers[i],
              onChoose: onChoose == null
                  ? null
                  : () => unawaited(onChoose!(chooseText(l, w, w.offers[i]))),
              c: c,
            ),
          ),
      ],
    );
  }
}

class _Offer extends StatelessWidget {
  const _Offer({super.key, required this.o, required this.onChoose, required this.c});

  final TripOffer o;
  final VoidCallback? onChoose;
  final RgColors c;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final price = priceText(o.price, o.currency, l.localeName);
    final stops = o.stops == 0
        ? l.cvFoundDirect
        : o.stops == 1
        ? l.cvFoundStop1
        : l.cvFoundStopN('${o.stops}');
    final sub = [o.duration, stops, o.operator].whereType<String>().join(' · ');
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: c.line),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                '${o.departs} → ${o.arrives}',
                style: TextStyle(
                  color: c.text,
                  fontWeight: FontWeight.w700,
                  fontSize: 15,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
              const Spacer(),
              if (price.isNotEmpty)
                Text(
                  price,
                  key: const Key('found-price'),
                  style: TextStyle(color: c.text, fontWeight: FontWeight.w700, fontSize: 15),
                ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            o.label,
            style: TextStyle(color: c.text, fontWeight: FontWeight.w600, fontSize: 14),
          ),
          Text(sub, style: TextStyle(color: c.dim, fontSize: 12.5)),
          const SizedBox(height: 8),
          Row(
            children: [
              if (o.availability != null)
                Expanded(
                  child: Text(o.availability!, style: TextStyle(color: c.dim, fontSize: 12.5)),
                )
              else
                const Spacer(),
              FilledButton(
                key: const Key('found-choose'),
                style: FilledButton.styleFrom(
                  backgroundColor: c.accent,
                  foregroundColor: Colors.white,
                  shape: const StadiumBorder(),
                ),
                onPressed: onChoose,
                child: Text(l.cvFoundChoose),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _Route extends StatefulWidget {
  const _Route({required this.w, required this.open});

  final RouteFound w;
  final FoundOpener open;

  @override
  State<_Route> createState() => _RouteState();
}

class _RouteState extends State<_Route> {
  int _at = 0;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final c = RgColors.of(context);
    final w = widget.w;
    final o = w.options[_at.clamp(0, w.options.length - 1)];
    final by = switch (o.mode) {
      'walk' => l.cvFoundModeByWalk,
      'transit' => l.cvFoundModeByTransit,
      _ => l.cvFoundModeByDrive,
    };
    final sub = [by, if (o.distanceM != null) distanceText(o.distanceM!, l.localeName)].join(' · ');
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _Head(icon: RgIcons.mapPin, title: w.title ?? '${w.fromName} → ${w.toName}'),
        Semantics(
          label: l.cvFoundMapAlt(w.fromName, w.toName),
          child: AspectRatio(
            aspectRatio: 560 / 260,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: CustomPaint(
                key: const Key('found-map'),
                painter: _MapPainter(w: w, line: w.lineOf(o), c: c),
              ),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.only(top: 14, bottom: 10),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                minutesText(l, o.durationMin),
                key: const Key('found-duration'),
                style: TextStyle(color: c.text, fontWeight: FontWeight.w700, fontSize: 22),
              ),
              const SizedBox(width: 10),
              Flexible(
                child: Text(sub, style: TextStyle(color: c.dim, fontSize: 12.5)),
              ),
            ],
          ),
        ),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            for (var i = 0; i < w.options.length; i++)
              ChoiceChip(
                key: Key('found-mode-${w.options[i].mode}'),
                selected: i == _at,
                showCheckmark: false,
                avatar: RgIcon(
                  switch (w.options[i].mode) {
                    'walk' => RgIcons.walk,
                    'transit' => RgIcons.bus,
                    _ => RgIcons.car,
                  },
                  size: 14,
                  color: c.text,
                ),
                label: Text(switch (w.options[i].mode) {
                  'walk' => l.cvFoundModeWalk,
                  'transit' => l.cvFoundModeTransit,
                  _ => l.cvFoundModeDrive,
                }),
                shape: const StadiumBorder(),
                onSelected: (_) => setState(() => _at = i),
              ),
            OutlinedButton.icon(
              key: const Key('found-maps'),
              style: OutlinedButton.styleFrom(
                foregroundColor: c.accent,
                side: BorderSide(color: c.accent),
                shape: const StadiumBorder(),
              ),
              iconAlignment: IconAlignment.end,
              icon: RgIcon(RgIcons.external, size: 14, color: c.accent),
              label: Text(l.cvFoundOpenMaps),
              onPressed: () => unawaited(widget.open(w.mapsLink(o))),
            ),
          ],
        ),
        if (o.steps.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 14),
            child: Column(
              key: const Key('found-steps'),
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                for (final s in o.steps)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SizedBox(
                          width: 62,
                          child: Text(
                            s.minute == null ? '' : minutesText(l, s.minute!),
                            style: TextStyle(color: c.dim, fontSize: 13),
                          ),
                        ),
                        Expanded(
                          child: Text(s.text, style: TextStyle(color: c.text, fontSize: 13.5)),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        if (w.note != null)
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(w.note!, style: TextStyle(color: c.dim, fontSize: 13)),
          ),
      ],
    );
  }
}

class _MapPainter extends CustomPainter {
  _MapPainter({required this.w, required this.line, required this.c});

  final RouteFound w;
  final List<GeoPoint> line;
  final RgColors c;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(Offset.zero & size, Paint()..color = c.panel2);
    final grid = Paint()
      ..color = c.line.withValues(alpha: 0.6)
      ..strokeWidth = 1;
    for (var x = 0.0; x < size.width; x += 28) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), grid);
    }
    for (var y = 0.0; y < size.height; y += 28) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), grid);
    }
    final d = drawRoute(line, size.width, size.height, pad: 28);
    final path = Path()..moveTo(d.points.first.x, d.points.first.y);
    for (final p in d.points.skip(1)) {
      path.lineTo(p.x, p.y);
    }
    Paint stroke(Color color, double width) => Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = width
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    canvas.drawPath(path, stroke(c.panel, 9));
    canvas.drawPath(path, stroke(c.accent, 5));
    final s = Offset(d.start.x, d.start.y);
    final e = Offset(d.end.x, d.end.y);
    canvas.drawCircle(s, 7, Paint()..color = c.panel);
    canvas.drawCircle(s, 7, stroke(c.accent, 4)..strokeWidth = 4);
    canvas.drawCircle(e, 8, Paint()..color = c.accent);
    canvas.drawCircle(e, 3, Paint()..color = c.panel);
    void label(String text, Offset at) {
      final tp = TextPainter(
        text: TextSpan(
          text: text,
          style: TextStyle(color: c.text, fontSize: 12, fontWeight: FontWeight.w700),
        ),
        textDirection: TextDirection.ltr,
        maxLines: 1,
        ellipsis: '…',
      )..layout(maxWidth: size.width / 2);
      tp.paint(canvas, at);
    }

    label(w.fromName, s + const Offset(10, -20));
    label(w.toName, e + const Offset(11, -22));
  }

  @override
  bool shouldRepaint(_MapPainter old) => old.line != line || old.c != c || old.w != w;
}

/// Five stars filled to the rating, with the number and the reviews (a product card's rating).
class Stars extends StatelessWidget {
  const Stars({super.key, required this.rating, this.reviews});

  final double rating;
  final int? reviews;

  @override
  Widget build(BuildContext context) {
    final c = RgColors.of(context);
    final l = AppLocalizations.of(context);
    final row = Row(
      mainAxisSize: MainAxisSize.min,
      children: [for (var i = 0; i < 5; i++) RgIcon(RgIcons.star, size: 13, filled: true)],
    );
    return Semantics(
      label: l.cvFoundRating(rating.toStringAsFixed(1)),
      child: Row(
        key: const Key('product-stars'),
        mainAxisSize: MainAxisSize.min,
        children: [
          ExcludeSemantics(
            child: SizedBox(
              width: 65,
              height: 13,
              child: Stack(
                children: [
                  IconTheme(
                    data: IconThemeData(color: c.line),
                    child: _tint(row, c.line),
                  ),
                  ClipRect(clipper: _Frac(rating.clamp(0.0, 5.0) / 5), child: _tint(row, c.warn)),
                ],
              ),
            ),
          ),
          const SizedBox(width: 6),
          Text(
            rating.toStringAsFixed(1),
            style: TextStyle(color: c.text, fontSize: 12, fontWeight: FontWeight.w600),
          ),
          if (reviews != null) Text(' ($reviews)', style: TextStyle(color: c.dim, fontSize: 12)),
        ],
      ),
    );
  }

  Widget _tint(Widget row, Color color) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      for (var i = 0; i < 5; i++) RgIcon(RgIcons.star, size: 13, color: color, filled: true),
    ],
  );
}

class _Frac extends CustomClipper<Rect> {
  const _Frac(this.f);
  final double f;

  @override
  Rect getClip(Size size) => Rect.fromLTWH(0, 0, size.width * f, size.height);

  @override
  bool shouldReclip(_Frac old) => old.f != f;
}

/// «Choose»'s sender in a conversation: the app's own message to the agent.
FoundSender conversationSender(BuildContext context, String sessionId) {
  final app = AppScope.read(context);
  return (text) async {
    await app.send(sessionId, text);
  };
}

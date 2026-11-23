// Product cards (G40.16): what `show_products` showed, as a carousel in the conversation, as the
// page's ProductCards. The pictures come from RedGiant's server with the device's token
// (`GET /api/products/images/<image>`), never from the shop; a drawn placeholder stands in when
// there is none or it cannot be read. «Open» opens the shop's page outside the app, only when
// pressed and only for http and https.
import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../api/products.dart';
import '../app_state.dart';
import '../l10n/app_localizations.dart';
import '../theme/colors.dart';
import 'found_widgets.dart';
import 'icons.dart';

/// Loads a picture's bytes (null: none to show).
typedef PictureLoader = Future<Uint8List?> Function(String image);

/// Opens a shop's page (tests give their own).
typedef LinkOpener = Future<void> Function(Uri link);

Future<void> _openOutside(Uri link) async {
  await launchUrl(link, mode: LaunchMode.externalApplication);
}

/// The pictures already read, for the conversation's life and the next ones (a few dozen at most).
final _pictures = <String, Future<Uint8List?>>{};

PictureLoader _serverLoader(AppController? app) => (image) {
  final key = '${app?.server?.id}/$image';
  return _pictures.putIfAbsent(key, () async {
    if (_pictures.length > 120) unawaited(_pictures.remove(_pictures.keys.first));
    try {
      final c = app?.client;
      if (c == null) return null;
      final bytes = await c.productImage(image);
      return bytes.isEmpty ? null : bytes;
    } on Object {
      // A 404 or a lost connection: the placeholder; tried again when the conversation reopens.
      scheduleMicrotask(() => _pictures.remove(key));
      return null;
    }
  });
};

class ProductCarousel extends StatefulWidget {
  const ProductCarousel({super.key, required this.products, this.title, this.load, this.open});

  final List<ProductCard> products;
  final String? title;
  final PictureLoader? load;
  final LinkOpener? open;

  @override
  State<ProductCarousel> createState() => _ProductCarouselState();
}

class _ProductCarouselState extends State<ProductCarousel> {
  final _row = ScrollController();

  @override
  void dispose() {
    _row.dispose();
    super.dispose();
  }

  void _by(double dx) {
    if (!_row.hasClients) return;
    final to = (_row.offset + dx).clamp(0.0, _row.position.maxScrollExtent);
    unawaited(
      _row.animateTo(to, duration: const Duration(milliseconds: 250), curve: Curves.easeOut),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final c = RgColors.of(context);
    final load = widget.load ?? _serverLoader(AppScope.maybeRead(context));
    final open = widget.open ?? _openOutside;
    const width = 216.0;
    return ChatWidgetBox(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              RgIcon(RgIcons.bag, size: 15, color: c.dim),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  widget.title ?? '',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(color: c.dim, fontSize: 13, fontWeight: FontWeight.w600),
                ),
              ),
              if (widget.products.length > 1) ...[
                IconButton(
                  key: const Key('products-prev'),
                  tooltip: l.productPrevious,
                  visualDensity: VisualDensity.compact,
                  onPressed: () => _by(-(width + 10)),
                  icon: RgIcon(RgIcons.chevronLeft, size: 18, color: c.dim),
                ),
                IconButton(
                  key: const Key('products-next'),
                  tooltip: l.productNext,
                  visualDensity: VisualDensity.compact,
                  onPressed: () => _by(width + 10),
                  icon: RgIcon(RgIcons.chevronRight, size: 18, color: c.dim),
                ),
              ],
            ],
          ),
          const SizedBox(height: 4),
          SizedBox(
            height: 336,
            child: ListView.separated(
              key: const Key('products-row'),
              controller: _row,
              scrollDirection: Axis.horizontal,
              itemCount: widget.products.length,
              separatorBuilder: (_, _) => const SizedBox(width: 10),
              itemBuilder: (context, i) => SizedBox(
                width: width,
                child: _Card(key: Key('product-$i'), p: widget.products[i], load: load, open: open),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Card extends StatelessWidget {
  const _Card({super.key, required this.p, required this.load, required this.open});

  final ProductCard p;
  final PictureLoader load;
  final LinkOpener open;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final c = RgColors.of(context);
    final price = priceText(p.price, p.currency, l.localeName);
    final link = p.link;
    return GestureDetector(
      key: const Key('product-tap'),
      behavior: HitTestBehavior.opaque,
      onTap: link == null ? null : () => unawaited(open(link)),
      child: Container(
        decoration: BoxDecoration(
          color: c.panel,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: c.line),
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SizedBox(
              height: 150,
              child: _Picture(image: p.image, name: p.name, load: load),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(11, 9, 11, 6),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      p.name,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: c.text,
                        fontWeight: FontWeight.w700,
                        fontSize: 14.5,
                        height: 1.25,
                      ),
                    ),
                    if (p.rating != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Stars(rating: p.rating!, reviews: p.reviews),
                      ),
                    if (price.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 3),
                        child: Text(
                          price,
                          key: const Key('product-price'),
                          style: TextStyle(
                            color: c.accent,
                            fontWeight: FontWeight.w700,
                            fontSize: 15,
                          ),
                        ),
                      ),
                    if (p.shop != null && p.shop!.isNotEmpty)
                      Text(
                        p.shop!,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(color: c.dim, fontSize: 12.5),
                      ),
                    if (p.description != null && p.description!.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Text(
                          p.description!,
                          maxLines: 3,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(color: c.text, fontSize: 12.5, height: 1.3),
                        ),
                      ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(11, 0, 4, 6),
              child: Row(
                children: [
                  if (p.source != null)
                    Semantics(
                      container: true,
                      label: l.productSource(p.source!),
                      child: Tooltip(
                        message: l.productSource(p.source!),
                        child: Container(
                          key: const Key('product-source'),
                          constraints: const BoxConstraints(minWidth: 22),
                          height: 22,
                          alignment: Alignment.center,
                          padding: const EdgeInsets.symmetric(horizontal: 6),
                          decoration: BoxDecoration(
                            color: c.panel2,
                            borderRadius: BorderRadius.circular(11),
                            border: Border.all(color: c.line),
                          ),
                          child: ExcludeSemantics(
                            child: Text(
                              '${p.source}',
                              style: TextStyle(
                                color: c.dim,
                                fontSize: 11.5,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  const Spacer(),
                  if (link != null)
                    TextButton.icon(
                      key: const Key('product-open'),
                      onPressed: () => unawaited(open(link)),
                      iconAlignment: IconAlignment.end,
                      icon: RgIcon(RgIcons.external, size: 14, color: c.accent),
                      label: Text(l.productOpen, style: TextStyle(color: c.accent)),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Picture extends StatefulWidget {
  const _Picture({required this.image, required this.name, required this.load});

  final String? image;
  final String name;
  final PictureLoader load;

  @override
  State<_Picture> createState() => _PictureState();
}

class _PictureState extends State<_Picture> {
  Future<Uint8List?>? _bytes;

  @override
  void initState() {
    super.initState();
    final id = widget.image;
    if (id != null) _bytes = widget.load(id);
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final c = RgColors.of(context);
    final empty = Semantics(
      label: l.productNoPicture,
      child: Container(
        key: const Key('product-no-picture'),
        color: c.panel2,
        alignment: Alignment.center,
        child: RgIcon(RgIcons.bag, size: 38, color: c.dim),
      ),
    );
    final f = _bytes;
    if (f == null) return empty;
    return FutureBuilder<Uint8List?>(
      future: f,
      builder: (context, snap) {
        final b = snap.data;
        if (b == null)
          return snap.connectionState == ConnectionState.done ? empty : ColoredBox(color: c.panel2);
        return ColoredBox(
          color: Colors.white,
          child: Image.memory(
            b,
            key: const Key('product-picture'),
            fit: BoxFit.contain,
            semanticLabel: widget.name,
            gaplessPlayback: true,
            errorBuilder: (_, _, _) => empty,
          ),
        );
      },
    );
  }
}

// Product cards (G40.16) as the app reads them: the `products.shown` event's payload
// (`packages/protocol/src/products.ts`). The pictures come from RedGiant's server
// (`GET /api/products/images/<image>`), never from the shop; the shop's page opens outside the
// app only when the person presses «Open», and only for http and https.
import 'package:intl/intl.dart';

String? _str(Object? o) => o is String ? o : null;

class ProductCard {
  const ProductCard({
    required this.name,
    required this.url,
    this.price,
    this.currency,
    this.shop,
    this.description,
    this.source,
    this.image,
  });

  static ProductCard? fromJson(Object? o) {
    if (o is! Map<String, dynamic>) return null;
    final name = _str(o['name']);
    if (name == null || name.isEmpty) return null;
    final image = _str(o['image']);
    final currency = _str(o['currency']);
    return ProductCard(
      name: name,
      url: _str(o['url']) ?? '',
      price: o['price'] is num ? (o['price'] as num).toDouble() : null,
      currency: currency != null && RegExp(r'^[A-Z]{3}$').hasMatch(currency) ? currency : null,
      shop: _str(o['shop']),
      description: _str(o['description']),
      source: o['source'] is num ? (o['source'] as num).toInt() : null,
      // Only the server's cache ids: a hex SHA-256, nothing that could be a path.
      image: image != null && RegExp(r'^[0-9a-f]{64}$').hasMatch(image) ? image : null,
    );
  }

  final String name;
  final String url;
  final double? price;
  final String? currency;
  final String? shop;
  final String? description;
  final int? source;
  final String? image;

  /// The shop's page, when it is one people may open (http or https).
  Uri? get link => productLink(url);
}

/// A page people may open from a card: http or https with a host, nothing else.
Uri? productLink(String url) {
  final u = Uri.tryParse(url);
  if (u == null || !(u.scheme == 'https' || u.scheme == 'http') || u.host.isEmpty) return null;
  return u;
}

/// A price in the person's language: «32,90 €», «$45.00»; the bare number without a currency.
String priceText(double? price, String? currency, String locale) {
  if (price == null) return '';
  try {
    if (currency != null) {
      return NumberFormat.simpleCurrency(locale: locale, name: currency).format(price);
    }
    return NumberFormat.decimalPatternDigits(locale: locale, decimalDigits: 2).format(price);
  } on Object {
    return '${price.toStringAsFixed(2)}${currency == null ? '' : ' $currency'}';
  }
}

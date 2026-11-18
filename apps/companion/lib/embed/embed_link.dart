// The page inside the app (G42.0): the address of the server's page opened on one thing only (a
// Canvas file, an agent's port, a board, the test page), everything after `#` and never in the
// query (a fragment never reaches the server nor a log). The same rules as the page's
// `packages/protocol/src/embed.ts`, checked against `test/fixtures/embed_vectors.json`.
import 'dart:convert';
import 'dart:math';

/// What an embed shows (`EMBED_KINDS`).
enum EmbedKind { canvas, port, board, probe }

/// The web view's channel to the app (`EMBED_CHANNEL`).
const embedChannel = 'RGEmbed';

/// The fragment's keys, in the order the page writes them (`EMBED_HASH_ORDER`).
const embedHashOrder = [
  'token',
  'embed',
  'bridge',
  'scope',
  'path',
  'line',
  'page',
  'session',
  'agent',
  'port',
  'board',
  'variant',
  'screen',
  'theme',
  'lang',
  'font',
];

/// The real screens a board's variants are drawn at (`BOARD_SCREENS`), width × height.
const boardScreens = <String, ({int width, int height})>{
  'computer': (width: 1280, height: 800),
  'tablet': (width: 820, height: 1100),
  'phone': (width: 390, height: 780),
};

/// The most variants a board has (`BOARD_VARIANTS_MAX`).
const boardVariantsMax = 8;

final _nonce = RegExp(r'^[A-Za-z0-9_-]{16,64}$');
final _board = RegExp(r'^[\w-]+\.[0-9a-f]{12}$');
final _number = RegExp(r'^\d{1,9}$');
final _font = RegExp(r'^[^;{}<>]+$');
final _token = RegExp(r'^\S+$');

class EmbedParams {
  const EmbedParams({
    required this.token,
    required this.embed,
    required this.bridge,
    required this.theme,
    required this.lang,
    this.scope,
    this.path,
    this.line,
    this.page,
    this.session,
    this.agent,
    this.port,
    this.board,
    this.variant,
    this.screen,
    this.font,
  });

  final String token;
  final EmbedKind embed;

  /// The bridge's nonce: every page message carries it.
  final String bridge;

  /// `light` | `dark`.
  final String theme;

  /// `it` | `en`.
  final String lang;
  final String? scope;
  final String? path;
  final int? line;
  final int? page;
  final String? session;
  final String? agent;
  final int? port;
  final String? board;

  /// One variant of the board alone (1-based), at [screen]'s width (G42.2).
  final int? variant;

  /// `computer` | `tablet` | `phone` ([boardScreens]).
  final String? screen;
  final String? font;

  Map<String, Object> toJson() => {
    'token': token,
    'embed': embed.name,
    'bridge': bridge,
    'scope': ?scope,
    'path': ?path,
    'line': ?line,
    'page': ?page,
    'session': ?session,
    'agent': ?agent,
    'port': ?port,
    'board': ?board,
    'variant': ?variant,
    'screen': ?screen,
    'theme': theme,
    'lang': lang,
    'font': ?font,
  };

  /// Null when it breaks one of the page's rules (`EmbedParams` in the protocol).
  String? get problem {
    bool len(String? s, int max) => s == null || (s.isNotEmpty && s.length <= max);
    bool count(int? n) => n == null || (n >= 0 && n <= 999999999);
    if (token.isEmpty || token.length > 1000 || !_token.hasMatch(token)) return 'token';
    if (!_nonce.hasMatch(bridge)) return 'bridge';
    if (theme != 'light' && theme != 'dark') return 'theme';
    if (lang != 'it' && lang != 'en') return 'lang';
    if (!len(scope, 200) || !len(path, 4000) || !len(session, 200) || !len(agent, 200)) {
      return 'length';
    }
    if (!count(line) || !count(page)) return 'count';
    if (port != null && (port! < 1 || port! > 65535)) return 'port';
    if (board != null && !_board.hasMatch(board!)) return 'board';
    if (variant != null && (variant! < 1 || variant! > boardVariantsMax)) return 'variant';
    if (screen != null && !boardScreens.containsKey(screen)) return 'screen';
    if (font != null && (font!.isEmpty || font!.length > 200 || !_font.hasMatch(font!))) {
      return 'font';
    }
    switch (embed) {
      case EmbedKind.canvas:
        if (scope == null || path == null) return 'canvas';
      case EmbedKind.port:
        if (agent == null || port == null) return 'port';
      case EmbedKind.board:
        if (board == null) return 'board';
      case EmbedKind.probe:
        break;
    }
    if (embed != EmbedKind.canvas && (scope != null || line != null || page != null)) {
      return 'file';
    }
    if (embed != EmbedKind.port && (agent != null || port != null)) return 'port';
    if (embed != EmbedKind.board && board != null) return 'board';
    if ((embed != EmbedKind.board || variant == null) && (variant != null || screen != null)) {
      return 'variant';
    }
    return null;
  }
}

/// `application/x-www-form-urlencoded` as `URLSearchParams` writes it (`formEncode`).
String formEncode(String s) {
  final out = StringBuffer();
  for (final b in utf8.encode(s)) {
    final keep =
        (b >= 0x30 && b <= 0x39) ||
        (b >= 0x41 && b <= 0x5A) ||
        (b >= 0x61 && b <= 0x7A) ||
        b == 0x2A ||
        b == 0x2D ||
        b == 0x2E ||
        b == 0x5F;
    if (keep) {
      out.writeCharCode(b);
    } else if (b == 0x20) {
      out.write('+');
    } else {
      out.write('%${b.toRadixString(16).toUpperCase().padLeft(2, '0')}');
    }
  }
  return out.toString();
}

/// The fragment (without `#`) for [p], as the page's `embedHash`.
String embedHash(EmbedParams p) {
  final why = p.problem;
  if (why != null) throw ArgumentError.value(why, 'params', 'Not an embed the page takes');
  final values = p.toJson();
  return [
    for (final k in embedHashOrder)
      if (values[k] != null) '$k=${formEncode('${values[k]}')}',
  ].join('&');
}

/// The page at [base] showing [p]: the embed's own entry (`/embed.html`, which does not carry the
/// whole page), no query, all is in the fragment. [isolated] (G42.8): the same page isolated as a
/// whole (`/embed-isolated.html`, the server's `ISOLATED_EMBED`), so that LibreOffice's frame has
/// SharedArrayBuffer in the web views without Document-Isolation-Policy (WKWebView, WebKitGTK).
/// A server without it answers with its page, which sends the fragment on to `/embed.html`.
Uri embedUrl(Uri base, EmbedParams p, {bool isolated = false}) => Uri(
  scheme: base.scheme,
  host: base.host,
  port: base.hasPort ? base.port : null,
  path: isolated ? '/embed-isolated.html' : '/embed.html',
  fragment: embedHash(p),
);

/// Documents and presentations: their tab may run LibreOffice (an ODT/ODP, or the open copy a
/// DOCX/PPTX gets in its own tab), so their embed is the isolated one (G42.8).
final _officeFile = RegExp(
  r'\.(odt|odp|docx|docm|dotx|doc|rtf|pptx|pptm|ppsx|ppt)$',
  caseSensitive: false,
);

/// Whether the Canvas tab for [path] opens the isolated embed (G42.8).
bool embedIsolatedFor(String? path) => path != null && _officeFile.hasMatch(path);

/// The embed a fragment asks for, as the page reads it (`parseEmbedHash`), or null.
EmbedParams? parseEmbedHash(String hash) {
  final h = hash.startsWith('#') ? hash.substring(1) : hash;
  final raw = <String, String>{};
  for (final part in h.split('&')) {
    if (part.isEmpty) continue;
    final i = part.indexOf('=');
    String dec(String s) => Uri.decodeQueryComponent(s);
    final k = dec(i < 0 ? part : part.substring(0, i));
    final v = i < 0 ? '' : dec(part.substring(i + 1));
    if (raw.containsKey(k)) return null;
    raw[k] = v;
  }
  if (!raw.containsKey('embed')) return null;
  if (raw.keys.any((k) => !embedHashOrder.contains(k))) return null;
  int? n(String k) {
    final v = raw[k];
    if (v == null) return null;
    return _number.hasMatch(v) ? int.parse(v) : -1;
  }

  final kind = EmbedKind.values.where((e) => e.name == raw['embed']).firstOrNull;
  if (kind == null) return null;
  final token = raw['token'], bridge = raw['bridge'], theme = raw['theme'], lang = raw['lang'];
  if (token == null || bridge == null || theme == null || lang == null) return null;
  final p = EmbedParams(
    token: token,
    embed: kind,
    bridge: bridge,
    theme: theme,
    lang: lang,
    scope: raw['scope'],
    path: raw['path'],
    line: n('line'),
    page: n('page'),
    session: raw['session'],
    agent: raw['agent'],
    port: n('port'),
    board: raw['board'],
    variant: n('variant'),
    screen: raw['screen'],
    font: raw['font'],
  );
  return p.problem == null ? p : null;
}

/// A fresh nonce for the bridge (24 characters of the allowed ones).
String newEmbedNonce([Random? random]) {
  final r = random ?? Random.secure();
  const abc = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789_-';
  return List.generate(24, (_) => abc[r.nextInt(abc.length)]).join();
}

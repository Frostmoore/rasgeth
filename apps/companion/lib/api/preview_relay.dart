// The app's preview relay (3.8.7): a tiny HTTP server on 127.0.0.1 that the web view of a widget
// or an artifact loads from. It serves one thing of its own, the wrapper page of each frame
// (`frameWrapperPage`), and passes on to RedGiant only `GET`/`HEAD` of the `/preview/<token>/…`
// links the app itself asked for (the page's same routes), with the app's own trust: RedGiant's
// local CA when pinned, the system's roots otherwise; never in clear over the network. The
// preview link is the credential, as in the page: the app's token never goes with it, nor into
// any address the web view sees. The server's policy comes back as it is, with its origins
// (who may frame it, where its libraries are) moved to the relay's (`relayCsp`).
import 'dart:async';
import 'dart:io';
import 'dart:math';

import 'artifact_frame.dart';
import 'transport.dart';

/// One frame the relay serves: the page the web view loads, the preview it holds, its nonce.
class RelayFrame {
  const RelayFrame({
    required this.id,
    required this.wrapper,
    required this.preview,
    required this.nonce,
    this.onRelease,
  });

  final String id;
  final Uri wrapper;
  final Uri preview;
  final String nonce;
  final void Function()? onRelease;

  /// The frame went away: the relay no longer serves it.
  void release() => onRelease?.call();
}

/// The preview's token in a server path (`/preview/<token>/<entry>`), or null.
String? previewTokenOf(String path) {
  final u = Uri.tryParse(path);
  if (u == null || u.hasScheme || u.hasAuthority) return null;
  final s = u.pathSegments;
  if (s.length < 3 || s[0] != 'preview' || s[1].isEmpty || !u.path.startsWith('/preview/')) {
    return null;
  }
  return s[1];
}

/// The request headers passed on to RedGiant (nothing that identifies the app).
const _forwardRequest = ['accept', 'accept-language', 'sec-fetch-dest', 'range', 'if-none-match'];

/// The answer headers passed back (the policy rewritten).
const _forwardAnswer = [
  'content-type',
  'cache-control',
  'x-content-type-options',
  'referrer-policy',
  'x-dns-prefetch-control',
  'access-control-allow-origin',
  'content-range',
  'accept-ranges',
  'etag',
];

String _randomId(Random r, [int bytes = 18]) {
  const abc = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789';
  return List.generate(bytes + bytes ~/ 3, (_) => abc[r.nextInt(abc.length)]).join();
}

class PreviewRelay {
  PreviewRelay._(this._server, this.base, this.caPem, this._client);

  /// One relay for the server in use; another server closes it and starts a new one.
  static PreviewRelay? _shared;

  static Future<PreviewRelay> forServer(Uri base, {String? caPem}) async {
    final s = _shared;
    if (s != null && !s._closed && s.base == base && s.caPem == caPem) return s;
    s?.close();
    final kind = transportFor(base, hasCa: caPem != null);
    if (kind == TransportKind.channel) {
      throw const TransportException('Plain http over the network: no frames');
    }
    final client = HttpClient(
      context: caPem != null && base.scheme == 'https' ? pinnedContext(caPem) : null,
    )..connectionTimeout = const Duration(seconds: 10);
    final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    final relay = PreviewRelay._(server, base, caPem, client);
    server.listen((r) => unawaited(relay._handle(r)));
    return _shared = relay;
  }

  final HttpServer _server;
  final Uri base;
  final String? caPem;
  final HttpClient _client;
  final _random = Random.secure();
  final _frames = <String, ({String src, String nonce, String title, String token})>{};
  bool _closed = false;

  int get port => _server.port;
  String get origin => 'http://127.0.0.1:$port';

  /// A frame for [previewPath] (the server's `/preview/<token>/…`, as the API gave it).
  RelayFrame open(String previewPath, {required String title}) {
    final token = previewTokenOf(previewPath);
    if (token == null) throw ArgumentError.value(previewPath, 'previewPath', 'Not a preview link');
    final id = _randomId(_random);
    final nonce = _randomId(_random, 24);
    final src = '$origin${Uri.parse(previewPath).path}';
    _frames[id] = (src: src, nonce: nonce, title: title, token: token);
    return RelayFrame(
      id: id,
      wrapper: Uri.parse('$origin/rg-frame/$id'),
      preview: Uri.parse(src),
      nonce: nonce,
      onRelease: () => _frames.remove(id),
    );
  }

  bool _tokenKnown(String token) => _frames.values.any((f) => f.token == token);

  Future<void> _handle(HttpRequest r) async {
    final res = r.response;
    Future<void> say(int status, String text) async {
      res
        ..statusCode = status
        ..headers.contentType = ContentType.text
        ..headers.set('cache-control', 'no-store')
        ..write(text);
      await res.close();
    }

    try {
      // Only this address (no other name pointing here), and only reading.
      final host = r.headers.host;
      if (host != '127.0.0.1' || r.headers.port != port) return await say(421, 'Not here');
      if (r.method != 'GET' && r.method != 'HEAD') return await say(405, 'Only reading');
      final seg = r.uri.pathSegments;
      if (seg.length == 2 && seg[0] == 'rg-frame') {
        final f = _frames[seg[1]];
        if (f == null) return await say(404, 'Not found');
        final page = frameWrapperPage(src: f.src, origin: origin, nonce: f.nonce, title: f.title);
        res.statusCode = 200;
        page.headers.forEach(res.headers.set);
        if (r.method == 'GET') res.write(page.body);
        await res.close();
        return;
      }
      final token = previewTokenOf(r.uri.path);
      if (token == null || !_tokenKnown(token)) return await say(404, 'Not found');
      final target = base.replace(path: r.uri.path, query: r.uri.hasQuery ? r.uri.query : null);
      final req = await _client.openUrl(r.method, target);
      req.followRedirects = false;
      for (final h in _forwardRequest) {
        final v = r.headers.value(h);
        if (v != null) req.headers.set(h, v);
      }
      final up = await req.close().timeout(const Duration(seconds: 30));
      res.statusCode = up.statusCode;
      for (final h in _forwardAnswer) {
        final v = up.headers.value(h);
        if (v != null) res.headers.set(h, v);
      }
      final csp = up.headers.value('content-security-policy');
      if (csp != null) res.headers.set('content-security-policy', relayCsp(csp, origin));
      // A redirect would leave the relay: never followed, never passed on.
      if (up.isRedirect) {
        await up.drain<void>();
        return await say(502, 'Redirected');
      }
      await up.pipe(res);
    } on Object {
      try {
        await say(502, 'RedGiant did not answer');
      } on Object {
        // The answer had already started.
      }
    }
  }

  void close() {
    if (_closed) return;
    _closed = true;
    _frames.clear();
    unawaited(_server.close(force: true));
    _client.close(force: true);
    if (identical(_shared, this)) _shared = null;
  }
}

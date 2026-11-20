// How the app reaches a RedGiant (G40.7). The rule is one pure function, [transportFor], tested
// as a table:
//   - plain http only to this very machine (loopback: the launcher's own server);
//   - https with RedGiant's local CA when the app has it (pinning: only that CA is trusted, the
//     system's roots are not), or with the system's roots for a public name (a proxy, Tailscale);
//   - any other http address (the temporary network 10.42.0.1, a RedGiant without HTTPS): the
//     API carried by the encrypted setup channel with the pinned key, never in clear.
import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'setup_channel.dart';

enum TransportKind {
  /// http to 127.0.0.1 / localhost / ::1: this very machine.
  loopback,

  /// https trusting only RedGiant's local CA.
  pinnedHttps,

  /// https with the system's roots (a proxy, Tailscale, a domain of one's own).
  publicHttps,

  /// The API inside the setup channel (no live socket: requests only).
  channel,
}

bool isLoopbackHost(String host) {
  final h = host.toLowerCase();
  return h == 'localhost' ||
      h == '::1' ||
      h == '[::1]' ||
      RegExp(r'^127\.\d+\.\d+\.\d+$').hasMatch(h);
}

/// The temporary network of a first start without a screen (G40.3).
bool isSetupNetworkHost(String host) => host == '10.42.0.1';

TransportKind transportFor(Uri base, {required bool hasCa}) {
  if (base.scheme == 'https') return hasCa ? TransportKind.pinnedHttps : TransportKind.publicHttps;
  if (base.scheme == 'http' && isLoopbackHost(base.host)) return TransportKind.loopback;
  return TransportKind.channel;
}

/// An answer of the API, whatever carried it.
class ApiResponse {
  const ApiResponse(this.status, this.contentType, this.bytes);

  final int status;
  final String contentType;
  final Uint8List bytes;

  String get text => utf8.decode(bytes, allowMalformed: true);
}

class TransportException implements Exception {
  const TransportException(this.message, {this.certificate = false});

  final String message;

  /// The TLS check failed (not RedGiant's CA, or another certificate in its place).
  final bool certificate;

  @override
  String toString() => 'TransportException: $message';
}

abstract class Transport {
  TransportKind get kind;

  /// Whether `/ws` can be opened (live states, streaming): not inside the setup channel.
  bool get live;

  Future<ApiResponse> send(
    String method,
    String pathAndQuery, {
    Map<String, String> headers = const {},
    List<int>? body,
    Duration timeout = const Duration(seconds: 20),
  });

  /// A GET that may be long (a file saved from the chat, 3.8.11): [onProgress] with the bytes
  /// arrived and the size the server said (null: not said); it ends only after [idle] without
  /// bytes, never after a fixed time.
  Future<ApiResponse> download(
    String pathAndQuery, {
    Map<String, String> headers = const {},
    void Function(int got, int? total)? onProgress,
    Duration idle = const Duration(seconds: 30),
  });

  /// The same GET written to [out] as it arrives (3.10: «Save as…» of a finished video or the XML
  /// for Resolve), never kept whole in memory. [cancel] stops it (`DownloadCancelled`); the
  /// answer's status and type come back with no bytes. A refusal's body (not 200) is read as usual.
  Future<ApiResponse> downloadTo(
    String pathAndQuery,
    File out, {
    Map<String, String> headers = const {},
    void Function(int got, int? total)? onProgress,
    DownloadCancel? cancel,
    Duration idle = const Duration(seconds: 30),
  });

  /// A WebSocket at [path] (`/ws`), with the same trust as the requests.
  Future<WebSocket> socket(String path);

  void close();
}

/// Stops a download to a file (3.10): the person's «Cancel» under its bar.
class DownloadCancel {
  bool _done = false;
  final _waiters = <void Function()>[];

  bool get cancelled => _done;

  void cancel() {
    if (_done) return;
    _done = true;
    for (final f in _waiters) {
      f();
    }
    _waiters.clear();
  }

  void _onCancel(void Function() f) => _done ? f() : _waiters.add(f);
}

/// A download stopped by the person.
class DownloadCancelled implements Exception {
  const DownloadCancelled();

  @override
  String toString() => 'DownloadCancelled';
}

/// `SecurityContext` that trusts only [caPem] (PEM text, or the base64 of it as the channel gives).
SecurityContext pinnedContext(String caPem) {
  var pem = caPem.trim();
  if (!pem.startsWith('-----BEGIN')) {
    try {
      pem = utf8.decode(base64.decode(pem));
    } on FormatException {
      // As it is.
    }
  }
  return SecurityContext(withTrustedRoots: false)..setTrustedCertificatesBytes(utf8.encode(pem));
}

class HttpTransport implements Transport {
  HttpTransport(this.base, {String? caPem})
    : kind = transportFor(base, hasCa: caPem != null),
      _client = HttpClient(
        context: caPem != null && base.scheme == 'https' ? pinnedContext(caPem) : null,
      ) {
    if (kind == TransportKind.channel) {
      throw const TransportException('Plain http over the network: use the setup channel');
    }
    _client.connectionTimeout = const Duration(seconds: 10);
  }

  final Uri base;
  @override
  final TransportKind kind;
  final HttpClient _client;

  @override
  bool get live => true;

  @override
  Future<ApiResponse> send(
    String method,
    String pathAndQuery, {
    Map<String, String> headers = const {},
    List<int>? body,
    Duration timeout = const Duration(seconds: 20),
  }) async {
    final url = base.resolve(pathAndQuery);
    try {
      return await () async {
        final req = await _client.openUrl(method, url);
        headers.forEach(req.headers.set);
        if (body != null) {
          req.contentLength = body.length;
          req.add(body);
        }
        final res = await req.close();
        final b = BytesBuilder(copy: false);
        await res.forEach(b.add);
        return ApiResponse(res.statusCode, res.headers.contentType?.mimeType ?? '', b.takeBytes());
      }().timeout(timeout);
    } on TimeoutException {
      throw const TransportException('The server did not answer in time');
    } on HandshakeException catch (e) {
      throw TransportException(
        '${e.message} ${e.osError?.message ?? ''}'.trim(),
        certificate: true,
      );
    } on SocketException catch (e) {
      throw TransportException(e.message);
    } on HttpException catch (e) {
      throw TransportException(e.message);
    }
  }

  @override
  Future<ApiResponse> download(
    String pathAndQuery, {
    Map<String, String> headers = const {},
    void Function(int got, int? total)? onProgress,
    Duration idle = const Duration(seconds: 30),
  }) async {
    final url = base.resolve(pathAndQuery);
    try {
      final req = await _client.getUrl(url).timeout(idle);
      headers.forEach(req.headers.set);
      final res = await req.close().timeout(idle);
      final total = res.contentLength >= 0 ? res.contentLength : null;
      final b = BytesBuilder(copy: false);
      onProgress?.call(0, total);
      await for (final chunk in res.timeout(idle)) {
        b.add(chunk);
        onProgress?.call(b.length, total);
      }
      return ApiResponse(res.statusCode, res.headers.contentType?.mimeType ?? '', b.takeBytes());
    } on TimeoutException {
      throw const TransportException('The server did not answer in time');
    } on HandshakeException catch (e) {
      throw TransportException(
        '${e.message} ${e.osError?.message ?? ''}'.trim(),
        certificate: true,
      );
    } on SocketException catch (e) {
      throw TransportException(e.message);
    } on HttpException catch (e) {
      throw TransportException(e.message);
    }
  }

  @override
  Future<ApiResponse> downloadTo(
    String pathAndQuery,
    File out, {
    Map<String, String> headers = const {},
    void Function(int got, int? total)? onProgress,
    DownloadCancel? cancel,
    Duration idle = const Duration(seconds: 30),
  }) async {
    final url = base.resolve(pathAndQuery);
    HttpClientRequest? req;
    IOSink? sink;
    try {
      if (cancel?.cancelled ?? false) throw const DownloadCancelled();
      req = await _client.getUrl(url).timeout(idle);
      final r = req;
      cancel?._onCancel(() => r.abort(const DownloadCancelled()));
      headers.forEach(req.headers.set);
      final res = await req.close().timeout(idle);
      final type = res.headers.contentType?.mimeType ?? '';
      if (res.statusCode != 200) {
        final b = BytesBuilder(copy: false);
        await for (final chunk in res.timeout(idle)) {
          b.add(chunk);
        }
        return ApiResponse(res.statusCode, type, b.takeBytes());
      }
      final total = res.contentLength >= 0 ? res.contentLength : null;
      sink = out.openWrite();
      var got = 0;
      onProgress?.call(0, total);
      await for (final chunk in res.timeout(idle)) {
        if (cancel?.cancelled ?? false) throw const DownloadCancelled();
        sink.add(chunk);
        got += chunk.length;
        onProgress?.call(got, total);
      }
      await sink.flush();
      await sink.close();
      sink = null;
      if (total != null && got != total) {
        throw const TransportException('The download ended before the whole file came');
      }
      return ApiResponse(res.statusCode, type, Uint8List(0));
    } on DownloadCancelled {
      rethrow;
    } on TimeoutException {
      throw const TransportException('The server did not answer in time');
    } on HandshakeException catch (e) {
      throw TransportException(
        '${e.message} ${e.osError?.message ?? ''}'.trim(),
        certificate: true,
      );
    } on SocketException catch (e) {
      if (cancel?.cancelled ?? false) throw const DownloadCancelled();
      throw TransportException(e.message);
    } on HttpException catch (e) {
      if (cancel?.cancelled ?? false) throw const DownloadCancelled();
      throw TransportException(e.message);
    } finally {
      await sink?.close().catchError((_) {});
    }
  }

  @override
  Future<WebSocket> socket(String path) {
    final u = base.replace(scheme: base.scheme == 'https' ? 'wss' : 'ws', path: path);
    return WebSocket.connect(u.toString(), customClient: _client);
  }

  @override
  void close() => _client.close(force: true);
}

/// The API carried by the setup channel: the channel signs in by itself (its session); the
/// device's token is not sent with each request.
class ChannelTransport implements Transport {
  ChannelTransport(this.channel);

  final SetupChannel channel;

  @override
  TransportKind get kind => TransportKind.channel;

  @override
  bool get live => false;

  @override
  Future<ApiResponse> send(
    String method,
    String pathAndQuery, {
    Map<String, String> headers = const {},
    List<int>? body,
    Duration timeout = const Duration(seconds: 20),
  }) async {
    try {
      final r = await channel.request({
        't': 'http',
        'method': method,
        'path': pathAndQuery,
        if (body != null) 'body': utf8.decode(body),
      }, timeout: timeout);
      final type = r['type'] is String ? r['type'] as String : '';
      return ApiResponse(
        (r['status'] as num?)?.toInt() ?? 0,
        type.split(';').first.trim(),
        Uint8List.fromList(utf8.encode(r['body'] is String ? r['body'] as String : '')),
      );
    } on SetupChannelException catch (e) {
      throw TransportException(e.message);
    } on SetupRequestException catch (e) {
      throw TransportException(e.message);
    }
  }

  /// The channel carries text only: a file comes whole, as any answer.
  @override
  Future<ApiResponse> download(
    String pathAndQuery, {
    Map<String, String> headers = const {},
    void Function(int got, int? total)? onProgress,
    Duration idle = const Duration(seconds: 30),
  }) async {
    final r = await send('GET', pathAndQuery, headers: headers);
    onProgress?.call(r.bytes.length, r.bytes.length);
    return r;
  }

  /// The channel carries text only: the file comes whole, then is written.
  @override
  Future<ApiResponse> downloadTo(
    String pathAndQuery,
    File out, {
    Map<String, String> headers = const {},
    void Function(int got, int? total)? onProgress,
    DownloadCancel? cancel,
    Duration idle = const Duration(seconds: 30),
  }) async {
    if (cancel?.cancelled ?? false) throw const DownloadCancelled();
    final r = await send('GET', pathAndQuery, headers: headers);
    if (cancel?.cancelled ?? false) throw const DownloadCancelled();
    if (r.status != 200) return r;
    await out.writeAsBytes(r.bytes, flush: true);
    onProgress?.call(r.bytes.length, r.bytes.length);
    return ApiResponse(r.status, r.contentType, Uint8List(0));
  }

  @override
  Future<WebSocket> socket(String path) =>
      Future.error(const TransportException('No live connection inside the setup channel'));

  @override
  void close() => unawaited(channel.close());
}

// The minimal client of RedGiant's HTTP API for the app (G40.6): who the server is, pairing with
// the password, the agents and their mascots. Discovery, the fingerprint check and the
// WebSocket come with G40.7.
import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import 'types.dart';

/// An answer the app can explain: the server's message and its `code` when it gives one.
class ApiException implements Exception {
  const ApiException(this.status, this.message, {this.code});

  /// The HTTP status (0: the server could not be reached or did not answer like RedGiant).
  final int status;
  final String message;

  /// `wrong`, `code_needed`, `too_many`, `no_password`… (`LoginError` on the server).
  final String? code;

  bool get unreachable => status == 0;

  @override
  String toString() => 'ApiException($status${code == null ? '' : ', $code'}): $message';
}

class RedGiantClient {
  RedGiantClient(
    Uri base, {
    http.Client? httpClient,
    this.token,
    this.timeout = const Duration(seconds: 15),
  }) : base = normalizeBase(base),
       _http = httpClient ?? http.Client();

  /// The server's address, without a trailing slash nor a path.
  final Uri base;

  /// The device's token (`rgd_…`), once paired.
  String? token;
  final Duration timeout;
  final http.Client _http;

  /// `https://host:port` from what the person typed (`host`, `host:port`, a full URL).
  static Uri normalizeBase(Uri u) {
    // «host:port» parses as a scheme and a path: without a host it is read again as https.
    final withScheme = u.host.isNotEmpty ? u : Uri.parse('https://$u');
    return Uri(
      scheme: withScheme.scheme,
      host: withScheme.host,
      port: withScheme.hasPort ? withScheme.port : null,
    );
  }

  Uri _url(String path, [Map<String, String>? query]) =>
      base.replace(path: path, queryParameters: query == null || query.isEmpty ? null : query);

  Map<String, String> _headers({bool json = false}) => {
    'accept': 'application/json',
    if (json) 'content-type': 'application/json',
    if (token != null) 'authorization': 'Bearer $token',
  };

  Future<http.Response> _send(Future<http.Response> Function() call) async {
    try {
      return await call().timeout(timeout);
    } on TimeoutException {
      throw const ApiException(0, 'The server did not answer in time');
    } on http.ClientException catch (e) {
      throw ApiException(0, e.message);
    } on Exception catch (e) {
      throw ApiException(0, '$e');
    }
  }

  Object? _decode(http.Response r) {
    Object? body;
    try {
      body = r.body.isEmpty ? null : jsonDecode(utf8.decode(r.bodyBytes));
    } on FormatException {
      body = null;
    }
    if (r.statusCode >= 200 && r.statusCode < 300) {
      if (body == null) throw ApiException(0, 'Not a RedGiant answer (${r.statusCode})');
      return body;
    }
    final m = body is Map<String, dynamic> ? body : const <String, dynamic>{};
    throw ApiException(
      r.statusCode,
      m['error'] is String ? m['error'] as String : 'HTTP ${r.statusCode}',
      code: m['code'] is String ? m['code'] as String : null,
    );
  }

  Map<String, dynamic> _object(Object? o) {
    if (o is Map<String, dynamic>) return o;
    throw const ApiException(0, 'Not a RedGiant answer');
  }

  /// `GET /api/app/hello`: open; with a token it also says whether the token is still valid.
  Future<AppHello> hello() async {
    final r = await _send(() => _http.get(_url('/api/app/hello'), headers: _headers()));
    try {
      return AppHello.fromJson(_object(_decode(r)));
    } on FormatException {
      throw const ApiException(0, 'Not a RedGiant');
    }
  }

  /// `POST /api/app/pair`: the password (and the code, when on) for this device's token. The
  /// token is kept on the client; the caller stores it ([TokenStore]).
  Future<DeviceCreated> pair({
    required String password,
    String? code,
    required String name,
    required DevicePlatform platform,
  }) async {
    final body = jsonEncode({
      'password': password,
      if (code != null && code.isNotEmpty) 'code': code,
      'name': name,
      'platform': platform.name,
    });
    final r = await _send(
      () => _http.post(_url('/api/app/pair'), headers: _headers(json: true), body: body),
    );
    try {
      final created = DeviceCreated.fromJson(_object(_decode(r)));
      token = created.token;
      return created;
    } on FormatException {
      throw const ApiException(0, 'Not a RedGiant answer');
    }
  }

  /// `GET /api/agents`, each with its mascot's spec.
  Future<List<Agent>> agents({String? projectId}) async {
    final r = await _send(
      () => _http.get(
        _url('/api/agents', projectId == null ? null : {'projectId': projectId}),
        headers: _headers(),
      ),
    );
    final list = _decode(r);
    if (list is! List) throw const ApiException(0, 'Not a RedGiant answer');
    return [for (final a in list.whereType<Map<String, dynamic>>()) Agent.fromJson(a)];
  }

  /// `GET /api/agents/:id/mascot`: the spec alone.
  Future<MascotSpec> mascotSpec(String agentId) async {
    final r = await _send(
      () => _http.get(
        _url('/api/agents/${Uri.encodeComponent(agentId)}/mascot'),
        headers: _headers(),
      ),
    );
    return MascotSpec.fromJson(_object(_decode(r)));
  }

  /// `GET /api/agents/:id/mascot?format=svg`: the drawing `@redgiant/mascot` makes, with one
  /// theme's colours written in. Sizes up to 20 are the small drawing (body and eyes only).
  Future<String> mascotSvg(
    String agentId, {
    MascotState state = MascotState.idle,
    MascotTheme theme = MascotTheme.light,
    int size = 128,
  }) async {
    final r = await _send(
      () => _http.get(
        _url('/api/agents/${Uri.encodeComponent(agentId)}/mascot', {
          'format': 'svg',
          'state': state.name,
          'theme': theme.name,
          'size': '$size',
        }),
        headers: {..._headers(), 'accept': 'image/svg+xml'},
      ),
    );
    if (r.statusCode != 200) _decode(r);
    final text = utf8.decode(r.bodyBytes);
    if (!text.trimLeft().startsWith('<svg')) throw const ApiException(0, 'Not an SVG');
    return text;
  }

  void close() => _http.close();
}

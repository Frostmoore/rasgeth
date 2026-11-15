// The client of RedGiant's HTTP API for the app (G40.6, G40.7): who the server is, pairing, the
// agents and their mascots, conversations, requests, tasks and files: the same routes as the
// page. Every request goes through a [Transport] (https with the pinned CA, public https, this
// machine's http, or the setup channel), chosen by `transportFor`.
import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'conversation.dart';
import 'transport.dart';
import 'types.dart';

/// An answer the app can explain: the server's message and its `code` when it gives one.
class ApiException implements Exception {
  const ApiException(this.status, this.message, {this.code, this.certificate = false});

  /// The HTTP status (0: the server could not be reached or did not answer like RedGiant).
  final int status;
  final String message;

  /// `wrong`, `code_needed`, `too_many`, `no_password`… (`LoginError` on the server).
  final String? code;

  /// The TLS check failed: not the pinned CA (another machine, or a proxy in the middle).
  final bool certificate;

  bool get unreachable => status == 0;

  @override
  String toString() => 'ApiException($status${code == null ? '' : ', $code'}): $message';
}

class RedGiantClient {
  RedGiantClient(Uri base, {Transport? transport, this.token, String? caPem})
    : base = normalizeBase(base),
      transport = transport ?? HttpTransport(normalizeBase(base), caPem: caPem);

  /// The server's address, without a trailing slash nor a path.
  final Uri base;
  final Transport transport;

  /// The device's token (`rgd_…`), once paired.
  String? token;

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

  static String _path(String path, [Map<String, String>? query]) =>
      Uri(path: path, queryParameters: query == null || query.isEmpty ? null : query).toString();

  Map<String, String> _headers({bool json = false, String accept = 'application/json'}) => {
    'accept': accept,
    if (json) 'content-type': 'application/json',
    if (token != null) 'authorization': 'Bearer $token',
  };

  Future<ApiResponse> _send(
    String method,
    String path, {
    Map<String, String>? query,
    Object? json,
    String accept = 'application/json',
  }) async {
    try {
      return await transport.send(
        method,
        _path(path, query),
        headers: _headers(json: json != null, accept: accept),
        body: json == null ? null : utf8.encode(jsonEncode(json)),
      );
    } on TransportException catch (e) {
      throw ApiException(0, e.message, certificate: e.certificate);
    } on Exception catch (e) {
      throw ApiException(0, '$e');
    }
  }

  Object? _decode(ApiResponse r) {
    Object? body;
    try {
      body = r.bytes.isEmpty ? null : jsonDecode(r.text);
    } on FormatException {
      body = null;
    }
    if (r.status >= 200 && r.status < 300) {
      if (body == null) throw ApiException(0, 'Not a RedGiant answer (${r.status})');
      return body;
    }
    final m = body is Map<String, dynamic> ? body : const <String, dynamic>{};
    throw ApiException(
      r.status,
      m['error'] is String ? m['error'] as String : 'HTTP ${r.status}',
      code: m['code'] is String ? m['code'] as String : null,
    );
  }

  Map<String, dynamic> _object(Object? o) {
    if (o is Map<String, dynamic>) return o;
    throw const ApiException(0, 'Not a RedGiant answer');
  }

  List<Map<String, dynamic>> _array(Object? o) {
    if (o is List) return o.whereType<Map<String, dynamic>>().toList();
    throw const ApiException(0, 'Not a RedGiant answer');
  }

  Future<Object?> _get(String path, [Map<String, String>? query]) async =>
      _decode(await _send('GET', path, query: query));

  Future<Object?> _post(String path, Object body) async =>
      _decode(await _send('POST', path, json: body));

  /// `GET /api/app/hello`: open; with a token it also says whether the token is still valid.
  Future<AppHello> hello() async {
    final r = await _get('/api/app/hello');
    try {
      return AppHello.fromJson(_object(r));
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
    final r = await _post('/api/app/pair', {
      'password': password,
      if (code != null && code.isNotEmpty) 'code': code,
      'name': name,
      'platform': platform.name,
    });
    try {
      final created = DeviceCreated.fromJson(_object(r));
      token = created.token;
      return created;
    } on FormatException {
      throw const ApiException(0, 'Not a RedGiant answer');
    }
  }

  /// `GET /api/agents`, each with its mascot's spec.
  Future<List<Agent>> agents({String? projectId}) async => [
    for (final a in _array(
      await _get('/api/agents', projectId == null ? null : {'projectId': projectId}),
    ))
      Agent.fromJson(a),
  ];

  /// `GET /api/agents/:id/mascot`: the spec alone.
  Future<MascotSpec> mascotSpec(String agentId) async => MascotSpec.fromJson(
    _object(await _get('/api/agents/${Uri.encodeComponent(agentId)}/mascot')),
  );

  /// `GET /api/agents/:id/mascot?format=svg`: the drawing `@redgiant/mascot` makes, with one
  /// theme's colours written in. Sizes up to 20 are the small drawing (body and eyes only).
  Future<String> mascotSvg(
    String agentId, {
    MascotState state = MascotState.idle,
    MascotTheme theme = MascotTheme.light,
    int size = 128,
  }) async {
    final r = await _send(
      'GET',
      '/api/agents/${Uri.encodeComponent(agentId)}/mascot',
      query: {'format': 'svg', 'state': state.name, 'theme': theme.name, 'size': '$size'},
      accept: 'image/svg+xml',
    );
    if (r.status != 200) _decode(r);
    final text = r.text;
    if (!text.trimLeft().startsWith('<svg')) throw const ApiException(0, 'Not an SVG');
    return text;
  }

  /// `GET /api/sessions[?agentId=]`: the conversations, the latest first.
  Future<List<SessionRow>> sessions({String? agentId}) async {
    final rows = [
      for (final s in _array(
        await _get('/api/sessions', agentId == null ? null : {'agentId': agentId}),
      ))
        SessionRow.fromJson(s),
    ]..sort((a, b) => b.when.compareTo(a.when));
    return rows;
  }

  /// `POST /api/sessions`: a new conversation with [agentId].
  Future<String> newSession(String agentId) async {
    final id = _object(await _post('/api/sessions', {'agentId': agentId}))['sessionId'];
    if (id is! String) throw const ApiException(0, 'Not a RedGiant answer');
    return id;
  }

  /// `POST /api/agents/:id/work-session`: God's and Demi-God's shared conversation.
  Future<String> workSession(String agentId) async {
    final id = _object(
      await _post('/api/agents/${Uri.encodeComponent(agentId)}/work-session', const {}),
    )['sessionId'];
    if (id is! String) throw const ApiException(0, 'Not a RedGiant answer');
    return id;
  }

  /// `GET /api/chat/agent`: the everyday Chat (made the first time it is asked for).
  Future<Agent> chatAgent() async => Agent.fromJson(_object(await _get('/api/chat/agent')));

  /// `POST /api/sessions/:id/messages`: without the live socket (inside the setup channel).
  Future<void> sendMessage(
    String sessionId,
    String text, {
    List<Map<String, Object?>>? images,
  }) async {
    await _post('/api/sessions/${Uri.encodeComponent(sessionId)}/messages', {
      'text': text,
      if (images != null && images.isNotEmpty) 'images': images,
    });
  }

  /// `GET /api/permissions`: the requests waiting for the person.
  Future<List<PermissionRequest>> permissions() async => [
    for (final p in _array(await _get('/api/permissions'))) PermissionRequest.fromJson(p),
  ];

  /// `POST /api/app/requests/:id/answer` (G40.4): the app's quick answer. A critical request
  /// refuses `allow` here (`open_app`): its yes is given from its own screen, over the socket.
  Future<void> answerRequest(String requestId, {required bool allow}) async {
    await _post('/api/app/requests/${Uri.encodeComponent(requestId)}/answer', {
      'decision': allow ? 'allow' : 'deny',
    });
  }

  Future<List<Project>> projects() async => [
    for (final p in _array(await _get('/api/projects'))) Project.fromJson(p),
  ];

  /// `GET /api/projects/:id/tasks`, the latest first.
  Future<List<TaskRow>> tasks(String projectId) async => [
    for (final t in _array(await _get('/api/projects/${Uri.encodeComponent(projectId)}/tasks')))
      TaskRow.fromJson(t, projectId: projectId),
  ];

  /// `GET /api/files/content`: text, or base64 for the rest.
  Future<FileContent> fileContent(String scope, String path) async => FileContent.fromJson(
    _object(await _get('/api/files/content', {'scope': scope, 'path': path})),
  );

  /// `GET /api/files/raw`: the file's bytes.
  Future<Uint8List> fileRaw(String scope, String path) async {
    final r = await _send(
      'GET',
      '/api/files/raw',
      query: {'scope': scope, 'path': path},
      accept: '*/*',
    );
    if (r.status != 200) _decode(r);
    return r.bytes;
  }

  void close() => transport.close();
}

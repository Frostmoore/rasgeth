// The client of RedGiant's HTTP API for the app (G40.6, G40.7): who the server is, pairing, the
// agents and their mascots, conversations, requests, tasks and files: the same routes as the
// page. Every request goes through a [Transport] (https with the pinned CA, public https, this
// machine's http, or the setup channel), chosen by `transportFor`.
import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'conversation.dart';
import 'settings_types.dart';
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

  /// `GET /api/mascot/preview`: the face a new agent named [name] would get now (nothing saved).
  Future<String> mascotPreviewSvg(
    String name, {
    required String kind,
    String? parentId,
    MascotTheme theme = MascotTheme.light,
    int size = 128,
  }) async {
    final r = await _send(
      'GET',
      '/api/mascot/preview',
      query: {
        'name': name,
        'kind': kind,
        'parentId': ?parentId,
        'format': 'svg',
        'theme': theme.name,
        'size': '$size',
      },
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

  /// `PATCH /api/sessions/:id`: a conversation's title (the page shows the same).
  Future<void> renameSession(String sessionId, String title) =>
      _call('PATCH', '/api/sessions/${Uri.encodeComponent(sessionId)}', {'title': title});

  /// `POST /api/sessions/:id/interrupt`: stops the turn running (without the live socket).
  Future<void> interruptSession(String sessionId) => _call(
    'POST',
    '/api/sessions/${Uri.encodeComponent(sessionId)}/interrupt',
    const <String, Object?>{},
  );

  /// `PATCH /api/agents/:id`: an agent's model (null: the one above it, or the default) or its
  /// mode, as the page's agent settings and the composer's «…» do.
  Future<Agent> configureAgent(
    String agentId, {
    AgentModel? model,
    bool clearModel = false,
    String? mode,
  }) async => Agent.fromJson(
    _object(
      await _call('PATCH', '/api/agents/${Uri.encodeComponent(agentId)}', {
        if (model != null || clearModel) 'model': model?.toJson(),
        'mode': ?mode,
      }),
    ),
  );

  /// `GET /api/chat/settings`: the Chat's own model (its agent's record follows it).
  Future<AgentModel?> chatModel() async =>
      AgentModel.fromJson(_object(await _get('/api/chat/settings'))['model']);

  /// `PUT /api/chat/settings`: the Chat's model (null: the default), as the page's Chat header.
  Future<void> setChatModel(AgentModel? model) =>
      _call('PUT', '/api/chat/settings', {'model': model?.toJson()});

  /// `PATCH /api/sessions/:id`: one conversation's own model (null: its agent's); refused (409)
  /// while it runs.
  Future<void> setSessionModel(String sessionId, AgentModel? model) =>
      _call('PATCH', '/api/sessions/${Uri.encodeComponent(sessionId)}', {'model': model?.toJson()});

  /// `POST /api/sessions/:id/aside`: a question «meanwhile», outside the conversation.
  Future<({String id, String? answer, String? error})> aside(
    String sessionId,
    String question,
  ) async {
    final a = _object(
      _object(
        await _post('/api/sessions/${Uri.encodeComponent(sessionId)}/aside', {
          'question': question,
        }),
      )['aside'],
    );
    return (
      id: a['id'] is String ? a['id'] as String : '',
      answer: a['answer'] is String ? a['answer'] as String : null,
      error: a['error'] is String ? a['error'] as String : null,
    );
  }

  /// `POST /api/sessions/:id/asides/:asideId/chat`: «Bring into the chat» (only between turns).
  Future<void> asideToChat(String sessionId, String asideId) => _call(
    'POST',
    '/api/sessions/${Uri.encodeComponent(sessionId)}/asides/${Uri.encodeComponent(asideId)}/chat',
    const <String, Object?>{},
  );

  /// `POST /api/rooms`: this conversation becomes a group chat (the page's «Add an agent»).
  Future<String> roomFrom(String agentId, String sessionId) async {
    final id = _object(
      await _post('/api/rooms', {
        'members': const <String>[],
        'from': {'agentId': agentId, 'sessionId': sessionId},
      }),
    )['id'];
    if (id is! String) throw const ApiException(0, 'Not a RedGiant answer');
    return id;
  }

  /// `POST /api/rooms/:id/members`: an agent joins the group chat.
  Future<void> addRoomMember(String roomId, String agentId) =>
      _call('POST', '/api/rooms/${Uri.encodeComponent(roomId)}/members', {'agentId': agentId});

  /// `POST /api/agents`: a new agent, with the page's fields and rules (the server checks kind,
  /// parent and project).
  Future<Agent> createAgent({
    required String kind,
    required String? parentId,
    required String name,
    String? projectId,
    String? role,
    AgentModel? model,
    String? mode,
  }) async => Agent.fromJson(
    _object(
      await _post('/api/agents', {
        'kind': kind,
        'parentId': parentId,
        'name': name,
        'projectId': ?projectId,
        'role': ?role,
        if (model != null) 'model': model.toJson(),
        'mode': ?mode,
      }),
    ),
  );

  /// `PUT /api/agents/:id/tools`: the agent's own on/off per tool (never the essential ones).
  Future<void> setAgentTools(String agentId, Map<String, String> tools) =>
      _call('PUT', '/api/agents/${Uri.encodeComponent(agentId)}/tools', {'tools': tools});

  /// `GET /api/tools`: the tools' catalog (ids, groups, essential or not).
  Future<List<ToolEntry>> tools() async => [
    for (final e in _array(_object(await _get('/api/tools'))['entries'])) ToolEntry.fromJson(e),
  ];

  /// `POST /api/agents/:id/mascot`: a new face, different from every one in use.
  Future<Agent> changeMascot(String agentId) async => Agent.fromJson(
    _object(await _post('/api/agents/${Uri.encodeComponent(agentId)}/mascot', const {})),
  );

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

  // ---- the first start (G40.8) and the settings of this RedGiant ----

  /// A request whose answer may be empty (`{ok: true}`, nothing at all).
  Future<Object?> _call(String method, String path, [Object? body]) async {
    final r = await _send(method, path, json: body);
    if (r.status >= 200 && r.status < 300 && r.bytes.isEmpty) return null;
    return _decode(r);
  }

  /// `GET /api/auth/methods`: password, code and, while there is none, the first access.
  Future<Map<String, dynamic>> authMethods() async => _object(await _get('/api/auth/methods'));

  /// `POST /api/auth/first-access` (G39.7): the first password. Inside the setup channel the
  /// session it opens is the channel's own.
  Future<String> firstAccess(String password) async {
    final t = _object(await _post('/api/auth/first-access', {'password': password}))['token'];
    if (t is! String) throw const ApiException(0, 'Not a RedGiant answer');
    return t;
  }

  /// `POST /api/auth/login`: the password (and the code) for a session.
  Future<String> login(String password, {String? code}) async {
    final t = _object(
      await _post('/api/auth/login', {
        'password': password,
        if (code != null && code.isNotEmpty) 'code': code,
      }),
    )['token'];
    if (t is! String) throw const ApiException(0, 'Not a RedGiant answer');
    return t;
  }

  /// `GET /api/setup-network`: the temporary network, the networks seen, the last try.
  Future<SetupNetworkInfo> setupNetwork() async =>
      SetupNetworkInfo.fromJson(_object(await _get('/api/setup-network')));

  /// `POST /api/setup-network/home`: `{cable: true}` or `{ssid, password?, hidden?}`.
  Future<HomeResult> setupNetworkHome(Map<String, Object?> choice) async =>
      HomeResult.fromJson(_object(await _post('/api/setup-network/home', choice)));

  /// `GET /api/setup`: the wizard's state, as the app reads it.
  Future<Map<String, dynamic>> setupState() async => _object(await _get('/api/setup'));

  Future<SetupSummary> setupSummary() async => SetupSummary.fromJson(await setupState());

  /// `PUT /api/setup/languages`: the interface's and the agents' language.
  Future<void> setupLanguages({String? language, String? agentLanguage}) => _call(
    'PUT',
    '/api/setup/languages',
    {'language': ?language, 'agentLanguage': ?agentLanguage},
  );

  /// `PUT /api/setup/names`: God's and Demi-God's names.
  Future<void> setupNames({required String god, required String demigod, String? language}) =>
      _call('PUT', '/api/setup/names', {'god': god, 'demigod': demigod, 'language': ?language});

  /// `PUT /api/setup/keys/:id`: a provider's key, checked by the server; its models.
  Future<List<String>> setupKey(String provider, String key) async {
    final r = _object(
      await _call('PUT', '/api/setup/keys/${Uri.encodeComponent(provider)}', {'key': key}),
    );
    return [for (final m in (r['models'] is List ? r['models'] as List : const [])) '$m'];
  }

  /// `PUT /api/setup/subscriptions`: the terms read (`ack`), a subscription on or off.
  Future<void> setupSubscriptions(Map<String, Object?> b) =>
      _call('PUT', '/api/setup/subscriptions', b);

  /// `POST /api/subscriptions/claude/login`: Anthropic's page, to open in the browser.
  Future<String> claudeLogin({required bool ack}) async {
    final u = _object(await _post('/api/subscriptions/claude/login', {'ack': ack}))['url'];
    if (u is! String) throw const ApiException(0, 'Not a RedGiant answer');
    return u;
  }

  /// `POST /api/subscriptions/claude/code`: the code Anthropic's page shows.
  Future<Map<String, dynamic>> claudeCode(String code) async =>
      _object(await _post('/api/subscriptions/claude/code', {'code': code}));

  Future<Map<String, dynamic>> claudeStatus() async =>
      _object(await _get('/api/subscriptions/claude'));

  /// `POST /api/subscriptions/chatgpt/login`: OpenAI's page and the code to type there.
  Future<({String url, String code})> chatgptLogin() async {
    final r = _object(await _post('/api/subscriptions/chatgpt/login', const {}));
    return (url: '${r['url'] ?? ''}', code: '${r['code'] ?? ''}');
  }

  Future<Map<String, dynamic>> chatgptStatus() async =>
      _object(await _get('/api/subscriptions/chatgpt'));

  /// `POST /api/setup/complete`: the first start is completed (the temporary network closes).
  Future<void> setupComplete() => _call('POST', '/api/setup/complete', const {});

  /// `GET /api/models`: the models of the ways connected.
  Future<List<ModelChoice>> models() async => [
    for (final m in _array(await _get('/api/models'))) ModelChoice.fromJson(m),
  ];

  /// `PUT /api/setup/models`: the model agents use when nobody chose another.
  Future<void> setDefaultModel(String provider, String model, {String? effort}) =>
      _call('PUT', '/api/setup/models', {
        'defaultModel': {'provider': provider, 'model': model, 'effort': ?effort},
      });

  /// `PUT /api/nodes/name`: the machine's name, for the page, the nodes and the app.
  Future<void> setMachineName(String name) => _call('PUT', '/api/nodes/name', {'name': name});

  /// `GET /api/devices`: the devices with a token (never the token).
  Future<List<DeviceRow>> devices() async => [
    for (final d in _array(await _get('/api/devices'))) DeviceRow.fromJson(d),
  ];

  /// `DELETE /api/devices/:id`: that device is signed out at once.
  Future<void> revokeDevice(String id) =>
      _call('DELETE', '/api/devices/${Uri.encodeComponent(id)}');

  /// `POST /api/devices/:id/push/test`: a test notification; null when it went.
  Future<String?> pushTest(String id) async {
    final r = _object(
      await _call('POST', '/api/devices/${Uri.encodeComponent(id)}/push/test', const {}),
    );
    return r['ok'] == true ? null : '${r['error'] ?? 'failed'}';
  }

  /// `GET /api/update/status`: the last look for a new version.
  Future<UpdateStatus> updateStatus() async =>
      UpdateStatus.fromJson(_object(await _get('/api/update/status')));

  /// `POST /api/update/look`: looks now.
  Future<UpdateStatus> updateLook() async =>
      UpdateStatus.fromJson(_object(await _post('/api/update/look', const {})));

  /// `POST /api/update/act {action: update}`: where this installation updates itself.
  Future<void> updateNow() => _call('POST', '/api/update/act', {'action': 'update'});

  /// `GET /api/setup/os-updates` (RedGiant OS); null where there is none.
  Future<OsUpdates?> osUpdates({bool check = false}) async {
    try {
      final r = check
          ? await _post('/api/setup/os-updates/check', const {})
          : await _get('/api/setup/os-updates');
      final u = OsUpdates.fromJson(_object(r));
      return u.available ? u : null;
    } on ApiException catch (e) {
      if (e.status == 400 || e.status == 404) return null;
      rethrow;
    }
  }

  void close() => transport.close();
}

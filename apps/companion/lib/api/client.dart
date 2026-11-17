// The client of RedGiant's HTTP API for the app (G40.6, G40.7): who the server is, pairing, the
// agents and their mascots, conversations, requests, tasks and files: the same routes as the
// page. Every request goes through a [Transport] (https with the pinned CA, public https, this
// machine's http, or the setup channel), chosen by `transportFor`.
import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'budgets.dart';
import 'code.dart';
import 'conversation.dart';
import 'saved.dart';
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

/// A voice route's refusal, with the code the page explains (`voice_no_service`, `voice_no_key`…)
/// and its words (`name`, `status`).
class VoiceException extends ApiException {
  const VoiceException(super.status, super.message, {super.code, this.vars = const {}});

  final Map<String, String> vars;
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

  /// `POST /api/sessions/:id/fork` (G36.23): a new conversation going on from this one, from a
  /// message (`fromSeq`, «Continua da qui») or before one (`beforeSeq`, to send it edited).
  Future<String> forkSession(String sessionId, {int? fromSeq, int? beforeSeq}) async {
    final r = _object(
      await _post('/api/sessions/${Uri.encodeComponent(sessionId)}/fork', {
        'fromSeq': ?fromSeq,
        'beforeSeq': ?beforeSeq,
      }),
    );
    return r['sessionId'] as String? ?? '';
  }

  /// `POST /api/projects/:id/restore` (p3.5.3): an archived project works again.
  Future<void> restoreProject(String projectId) =>
      _call('POST', '/api/projects/${Uri.encodeComponent(projectId)}/restore', const {});

  /// `POST /api/sessions/:id/compaction/undo`: the last summary asked by hand is undone.
  Future<void> undoCompaction(String sessionId) =>
      _call('POST', '/api/sessions/${Uri.encodeComponent(sessionId)}/compaction/undo', const {});

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

  /// `PATCH /api/agents/:id` with any of the page's fields (name, role, mode, compaction,
  /// projects…), the same body Settings › Agents sends; the server checks every rule.
  Future<Agent> patchAgent(String agentId, Map<String, Object?> change) async => Agent.fromJson(
    _object(await _call('PATCH', '/api/agents/${Uri.encodeComponent(agentId)}', change)),
  );

  /// `POST /api/agents/:id/stop`: the agent and those under it stop (the page's «Stop»).
  /// `POST /api/agents/:id/stop` (3.8.9: a pause): its turns stop, its open tasks wait.
  Future<void> stopAgentForGood(String agentId) => _post(
    '/api/agents/${Uri.encodeComponent(agentId)}/stop',
    const {'reason': 'stopped from RGCompanion'},
  );

  /// `POST /api/agents/:id/resume` (3.8.9): a stopped agent works again (with those stopped under
  /// it); the ids of its open tasks, which go on by themselves.
  Future<List<String>> resumeAgent(String agentId) async {
    final out = _object(
      await _post('/api/agents/${Uri.encodeComponent(agentId)}/resume', const {}),
    );
    return [
      for (final id in (out['tasks'] as List?) ?? const <Object?>[])
        if (id is String) id,
    ];
  }

  /// `GET /api/agents/:id/remove-preview` (3.8.9): who goes with it, tasks and turns that end.
  Future<RemovePreview> removePreview(String agentId) async => RemovePreview.fromJson(
    _object(await _get('/api/agents/${Uri.encodeComponent(agentId)}/remove-preview')),
  );

  /// `POST /api/agents/:id/remove` (3.8.9): out of the team with those below it; its history
  /// stays and it can be restored. The ids removed.
  Future<List<String>> removeAgent(String agentId, {String? reason}) async => [
    for (final id
        in (_object(
                  // No reason of its own: the server writes one in the person's language.
                  await _post('/api/agents/${Uri.encodeComponent(agentId)}/remove', {
                    'reason': ?reason,
                  }),
                )['removed']
                as List?) ??
            const <Object?>[])
      if (id is String) id,
  ];

  /// `GET /api/agents/removed` (3.8.9): the removed agents, the latest first.
  Future<List<RemovedAgent>> removedAgents() async => [
    for (final a in _array(await _get('/api/agents/removed'))) RemovedAgent.fromJson(a),
  ];

  /// `POST /api/agents/:id/restore` (3.8.9): back in the team with those removed with it.
  Future<List<String>> restoreAgent(String agentId) async => [
    for (final id
        in (_object(
                  await _post('/api/agents/${Uri.encodeComponent(agentId)}/restore', const {}),
                )['restored']
                as List?) ??
            const <Object?>[])
      if (id is String) id,
  ];

  /// `GET /api/agents/:id/compaction-defaults`: what its summaries do when it sets nothing.
  Future<({double at, double keep})> compactionDefaults(String agentId) async {
    final o = _object(
      await _get('/api/agents/${Uri.encodeComponent(agentId)}/compaction-defaults'),
    );
    return (at: (o['at'] as num?)?.toDouble() ?? .8, keep: (o['keep'] as num?)?.toDouble() ?? .25);
  }

  /// `GET /api/notes?scope=self|project&agentId=…`: an agent's own notes, or its project's.
  Future<String> notes(String scope, String agentId, {String? projectId}) async =>
      _object(
            await _get('/api/notes', {'scope': scope, 'agentId': agentId, 'projectId': ?projectId}),
          )['text']
          as String? ??
      '';

  /// `PUT /api/notes?…`: the notes' new text.
  Future<void> setNotes(String scope, String agentId, String text, {String? projectId}) async {
    final r = await _send(
      'PUT',
      '/api/notes',
      query: {'scope': scope, 'agentId': agentId, 'projectId': ?projectId},
      json: {'text': text},
    );
    if (r.status < 200 || r.status >= 300 || r.bytes.isNotEmpty) _decode(r);
  }

  /// `PUT /api/budgets`: an agent's (or a project's) limit; no amount removes it.
  Future<void> setBudget(String scope, String id, {double? usd}) =>
      _call('PUT', '/api/budgets', {'scope': scope, 'id': id, 'usd': ?usd});

  /// `GET /api/tools?agentId=…`: every tool as this agent gets it (its own choice, the essential
  /// ones locked).
  Future<List<ToolEntry>> agentTools(String agentId) async => [
    for (final e in _array(_object(await _get('/api/tools', {'agentId': agentId}))['entries']))
      ToolEntry.fromJson(e),
  ];

  /// `GET /api/knowledge/agents/:id`: the collections this agent can read.
  Future<List<AgentCollection>> agentKnowledge(String agentId) async => [
    for (final c in _array(
      _object(await _get('/api/knowledge/agents/${Uri.encodeComponent(agentId)}'))['collections'],
    ))
      AgentCollection.fromJson(c),
  ];

  /// `PUT /api/knowledge/agents/:id`: on, off, or null (by where the collection belongs).
  Future<List<AgentCollection>> setAgentKnowledge(
    String agentId,
    String collection,
    String? pick,
  ) async => [
    for (final c in _array(
      _object(
        await _call('PUT', '/api/knowledge/agents/${Uri.encodeComponent(agentId)}', {
          'collection': collection,
          'pick': pick,
        }),
      )['collections'],
    ))
      AgentCollection.fromJson(c),
  ];

  /// `GET /api/settings/editor`: the agents' edits of open files, at once or proposed.
  Future<Map<String, dynamic>> editorSettings() async =>
      _object(_object(await _get('/api/settings/editor'))['settings']);

  /// `PUT /api/settings/editor`: the whole settings again (the page sends them so).
  Future<void> setEditorSettings(Map<String, dynamic> s) => _call('PUT', '/api/settings/editor', s);

  /// `GET /api/budgets`: spending against the limits (the header's bars, 3.9.0).
  Future<List<Budget>> budgets() async => [
    for (final o in _array(await _get('/api/budgets'))) ?Budget.fromJson(o),
  ];

  /// `GET /api/limits`: the flat subscriptions' windows (5h, 7d…).
  Future<List<PlanLimits>> planLimits() async => [
    for (final o in _array(await _get('/api/limits'))) ?PlanLimits.fromJson(o),
  ];

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

  /// `GET /api/agents/:id/prompt` (or the Chat's `GET /api/chat/prompt`): the instructions in
  /// use, its own or the built-in ones, with the current names.
  Future<PromptView> prompt({String? agentId}) async => PromptView.fromJson(
    _object(
      await _get(
        agentId == null ? '/api/chat/prompt' : '/api/agents/${Uri.encodeComponent(agentId)}/prompt',
      ),
    ),
  );

  /// `PUT /api/agents/:id/prompt` (or `/api/chat/prompt`): new instructions, null for the
  /// built-in ones; conversations already open keep theirs.
  Future<PromptView> setPrompt(String? text, {String? agentId}) async => PromptView.fromJson(
    _object(
      await _call(
        'PUT',
        agentId == null ? '/api/chat/prompt' : '/api/agents/${Uri.encodeComponent(agentId)}/prompt',
        {'text': text},
      ),
    ),
  );

  Map<String, Object?> _refineBody(String? agentId, String text, String request, String lang) => {
    'target': agentId == null ? {'chat': true} : {'agentId': agentId},
    'goal': 'refine',
    'text': text,
    'request': request,
    'lang': lang,
  };

  /// `POST /api/prompts/refine/estimate`: about how much «Improve the instructions» takes.
  Future<RefineCost> refineEstimate({
    String? agentId,
    required String text,
    String request = '',
    String lang = 'it',
  }) async => RefineCost.fromJson(
    _object(await _post('/api/prompts/refine/estimate', _refineBody(agentId, text, request, lang))),
  );

  /// `POST /api/prompts/refine`: a revised text and what changed (nothing is saved).
  Future<({String text, String changes, RefineCost cost})> refine({
    String? agentId,
    required String text,
    String request = '',
    String lang = 'it',
  }) async {
    final j = _object(
      await _post('/api/prompts/refine', _refineBody(agentId, text, request, lang)),
    );
    return (
      text: j['text'] is String ? j['text'] as String : text,
      changes: j['changes'] is String ? j['changes'] as String : '',
      cost: RefineCost.fromJson(j),
    );
  }

  /// `GET /api/chat/agent`: the everyday Chat (made the first time it is asked for).
  Future<Agent> chatAgent() async => Agent.fromJson(_object(await _get('/api/chat/agent')));

  /// `POST /api/sessions/:id/messages`: without the live socket (inside the setup channel). The
  /// route takes no quotes: they go before the text as Markdown quotes.
  Future<void> sendMessage(
    String sessionId,
    String text, {
    List<Map<String, Object?>>? images,
    List<Quote> quotes = const [],
  }) async {
    await _post('/api/sessions/${Uri.encodeComponent(sessionId)}/messages', {
      'text': withQuotesInText(text, quotes),
      if (images != null && images.isNotEmpty) 'images': images,
    });
  }

  // ---- saved passages (G40.14) and product pictures (G40.16) ----

  /// `GET /api/saved`: newest first, with the filters' tags and agents.
  Future<SavedList> savedList({
    String? q,
    String? tag,
    String? agentId,
    String? before,
    int? limit,
  }) async => SavedList.fromJson(
    _object(
      await _get('/api/saved', {
        if (q != null && q.trim().isNotEmpty) 'q': q.trim(),
        'tag': ?tag,
        'agentId': ?agentId,
        'before': ?before,
        if (limit != null) 'limit': '$limit',
      }),
    ),
  );

  /// `POST /api/saved`: a passage (with [text]) or the whole message (without), from an agent's
  /// conversation.
  Future<SavedItem> saveItem({
    required String sessionId,
    required int seq,
    int? start,
    int? end,
    String? text,
    String? markdown,
    String? note,
    List<String> tags = const [],
  }) async => SavedItem.fromJson(
    _object(
      await _post('/api/saved', {
        'source': {
          'kind': 'session',
          'sessionId': sessionId,
          'seq': seq,
          'start': ?start,
          'end': ?end,
        },
        if (text != null && text.trim().isNotEmpty)
          'text': text.length > savedTextMax ? '${text.substring(0, savedTextMax - 1)}…' : text,
        if (markdown != null && markdown.trim().isNotEmpty)
          'markdown': markdown.length > savedMarkdownMax
              ? markdown.substring(0, savedMarkdownMax)
              : markdown,
        if (note != null && note.trim().isNotEmpty) 'note': note.trim(),
        if (tags.isNotEmpty) 'tags': tags,
      }),
    ),
  );

  /// `PATCH /api/saved/:id`: the note and the tags.
  Future<SavedItem> updateSaved(
    String id, {
    required String note,
    required List<String> tags,
  }) async => SavedItem.fromJson(
    _object(
      await _call('PATCH', '/api/saved/${Uri.encodeComponent(id)}', {'note': note, 'tags': tags}),
    ),
  );

  Future<void> deleteSaved(String id) => _call('DELETE', '/api/saved/${Uri.encodeComponent(id)}');

  /// `GET /api/saved/export`: every match as one Markdown file, in the person's language.
  Future<String> savedExport({
    String? q,
    String? tag,
    String? agentId,
    required String lang,
  }) async {
    final r = await _send(
      'GET',
      '/api/saved/export',
      query: {
        if (q != null && q.trim().isNotEmpty) 'q': q.trim(),
        'tag': ?tag,
        'agentId': ?agentId,
        'lang': lang == 'it' ? 'it' : 'en',
      },
      accept: 'text/markdown',
    );
    if (r.status != 200) _decode(r);
    return r.text;
  }

  /// `GET /api/products/images/:id`: a product's picture as the server keeps it.
  Future<Uint8List> productImage(String id) async {
    final r = await _send(
      'GET',
      '/api/products/images/${Uri.encodeComponent(id)}',
      accept: 'image/*',
    );
    if (r.status != 200) _decode(r);
    return r.bytes;
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

  /// `POST /api/projects`: a new project (as the page's «New project»: only its name).
  Future<Project> createProject(String name) async =>
      Project.fromJson(_object(await _post('/api/projects', {'name': name})));

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

  /// The bytes of a link of this server the page inside the app gave (`/…?…`, «Save as…», G42.0).
  Future<Uint8List> serverBytes(String link) async {
    final u = Uri.parse(link);
    if (u.hasScheme || u.hasAuthority || !u.path.startsWith('/')) {
      throw ArgumentError.value(link, 'link', 'Not a link of this server');
    }
    final r = await _send(
      'GET',
      u.path,
      query: u.hasQuery ? u.queryParameters : null,
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

  // ---- notifications (G40.4 on the server, G40.10 here) ----

  /// `GET /api/app/push`: the server's VAPID public key (null while the keychain is locked) and
  /// whether APNs goes anywhere (its relay is switched off until the app is published).
  Future<({String? vapidPublicKey, bool apns})> pushInfo() async {
    final j = _object(await _get('/api/app/push'));
    return (
      vapidPublicKey: j['vapidPublicKey'] is String ? j['vapidPublicKey'] as String : null,
      apns: j['apns'] == true,
    );
  }

  /// `PUT /api/devices/:id/push`: where this device's notifications go (`webpush` with the
  /// distributor's endpoint, or `apns`), with the device's public key and secret.
  Future<Map<String, dynamic>> registerPush(String deviceId, Map<String, Object?> body) async =>
      _object(await _call('PUT', '/api/devices/${Uri.encodeComponent(deviceId)}/push', body));

  /// `DELETE /api/devices/:id/push`; a 404 (nothing registered) is fine.
  Future<void> unregisterPush(String deviceId) async {
    try {
      await _call('DELETE', '/api/devices/${Uri.encodeComponent(deviceId)}/push');
    } on ApiException catch (e) {
      if (e.status != 404) rethrow;
    }
  }

  // ---- voice (the page's own routes) ----

  /// `POST /api/transcribe?lang=`: a recording to text, with the server's transcription.
  Future<String> transcribe(List<int> audio, String mimeType, String lang) async {
    final ApiResponse r;
    try {
      r = await transport.send(
        'POST',
        _path('/api/transcribe', {'lang': lang}),
        headers: {..._headers(), 'content-type': mimeType},
        body: audio,
        timeout: const Duration(seconds: 120),
      );
    } on TransportException catch (e) {
      throw ApiException(0, e.message, certificate: e.certificate);
    }
    final j = _voiceDecode(r);
    return j['text'] is String ? j['text'] as String : '';
  }

  /// `POST /api/voice/speech`: [text] read by the provider chosen, as audio bytes.
  Future<({Uint8List bytes, String mimeType})> speech({
    required String provider,
    required String model,
    String? voice,
    required String text,
  }) async {
    final ApiResponse r;
    try {
      r = await transport.send(
        'POST',
        '/api/voice/speech',
        headers: _headers(json: true, accept: '*/*'),
        body: utf8.encode(
          jsonEncode({'provider': provider, 'model': model, 'voice': ?voice, 'text': text}),
        ),
        timeout: const Duration(seconds: 90),
      );
    } on TransportException catch (e) {
      throw ApiException(0, e.message, certificate: e.certificate);
    }
    if (r.status == 200 && !r.contentType.contains('json')) {
      return (bytes: r.bytes, mimeType: r.contentType);
    }
    _voiceDecode(r);
    throw const ApiException(0, 'Not audio');
  }

  /// A voice answer: its JSON, or a [VoiceException] with the server's code and words.
  Map<String, dynamic> _voiceDecode(ApiResponse r) {
    Object? body;
    try {
      body = r.bytes.isEmpty ? null : jsonDecode(r.text);
    } on FormatException {
      body = null;
    }
    final m = body is Map<String, dynamic> ? body : const <String, dynamic>{};
    if (r.status >= 200 && r.status < 300 && body != null) return m;
    final vars = m['vars'] is Map ? (m['vars'] as Map) : const {};
    throw VoiceException(
      r.status,
      m['error'] is String ? m['error'] as String : 'HTTP ${r.status}',
      code: m['code'] is String ? m['code'] as String : null,
      vars: {for (final e in vars.entries) '${e.key}': '${e.value}'},
    );
  }

  /// `PUT /api/files/content` (base64): a file the composer attaches, in the agent's workspace.
  Future<void> writeFile(String scope, String path, List<int> bytes) => _call(
    'PUT',
    '/api/files/content',
    {'scope': scope, 'path': path, 'content': base64.encode(bytes), 'encoding': 'base64'},
  );

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

  // ---- the advanced interface (G40.11): code-routes.ts and the page's Explorer ----

  String _proj(String id) => '/api/projects/${Uri.encodeComponent(id)}';

  /// `GET /api/projects/:id/git`: branch, upstream, ahead/behind, the changes.
  Future<GitState> gitState(String projectId) async =>
      GitState.fromJson(_object(await _get('${_proj(projectId)}/git')));

  Future<List<GitCommit>> gitLog(
    String projectId, {
    String? agent,
    int limit = 30,
    bool all = false,
  }) async => [
    for (final c in _array(
      await _get('${_proj(projectId)}/git/log', {
        'limit': '$limit',
        'agent': ?agent,
        if (all) 'all': '1',
      }),
    ))
      GitCommit.fromJson(c),
  ];

  Future<List<GitBranch>> gitBranches(String projectId) async => [
    for (final b in _array(await _get('${_proj(projectId)}/git/branches'))) GitBranch.fromJson(b),
  ];

  Future<DiffView> gitDiff(String projectId, DiffSource source) async =>
      DiffView.fromJson(_object(await _get('${_proj(projectId)}/git/diff', source.query)));

  /// `POST /api/projects/:id/git/hunk`: keep (stage) or discard one hunk; the backup's path.
  Future<String?> gitHunk(
    String projectId, {
    required String patch,
    required bool keep,
    String? agent,
  }) async {
    final r = await _call('POST', '${_proj(projectId)}/git/hunk', {
      'patch': patch,
      'action': keep ? 'keep' : 'discard',
      'agent': ?agent,
    });
    return r is Map && r['backup'] is String ? r['backup'] as String : null;
  }

  /// `POST /api/projects/:id/git/commit`: the new commit's short hash.
  Future<String> gitCommit(String projectId, String message, {String? agent}) async {
    final r = _object(
      await _post('${_proj(projectId)}/git/commit', {'message': message, 'agent': ?agent}),
    );
    return '${r['commit'] ?? ''}';
  }

  /// `POST /api/projects/:id/git/push`: a job that waits for the person's yes («For you»).
  Future<JobView> gitPush(String projectId, {String? agent}) async =>
      JobView.fromJson(_object(await _post('${_proj(projectId)}/git/push', {'agent': ?agent})));

  Future<JobView> job(String id) async =>
      JobView.fromJson(_object(await _get('/api/jobs/${Uri.encodeComponent(id)}')));

  /// `GET /api/projects/:id/events`: the project's log, newest first.
  Future<EventsPage> projectEvents(
    String projectId, {
    String? agent,
    String? type,
    bool errors = false,
    int limit = 150,
  }) async => EventsPage.fromJson(
    _object(
      await _get('${_proj(projectId)}/events', {
        'agent': ?agent,
        'type': ?type,
        if (errors) 'errors': '1',
        'limit': '$limit',
      }),
    ),
  );

  /// `GET /api/sessions/:id/events`: a conversation's events (an agent's commands).
  Future<List<Map<String, dynamic>>> sessionEvents(String sessionId) async =>
      _array(await _get('/api/sessions/${Uri.encodeComponent(sessionId)}/events'));

  Future<List<SearchHit>> searchFiles(String scope, String q) async => [
    for (final h in _array(await _get('/api/files/search', {'scope': scope, 'q': q})))
      SearchHit.fromJson(h),
  ];

  /// `GET /api/files/list`: a folder, folders first.
  Future<List<FileEntry>> listFiles(String scope, [String path = '.']) async => [
    for (final e in _array(await _get('/api/files/list', {'scope': scope, 'path': path})))
      FileEntry.fromJson(e),
  ];

  Future<FileText> fileText(String scope, String path) async =>
      FileText.fromJson(_object(await _get('/api/files/content', {'scope': scope, 'path': path})));

  /// `PUT /api/files/content`: a small edit, refused (409) if the file changed since it was read.
  Future<String> saveText(String scope, String path, String text, {String? expected}) async {
    final r = _object(
      await _call('PUT', '/api/files/content', {
        'scope': scope,
        'path': path,
        'content': text,
        'encoding': 'utf8',
        'expectedModifiedAt': ?expected,
      }),
    );
    return '${r['modifiedAt'] ?? ''}';
  }

  /// A shell in [scope]'s sandbox over `/term`.
  Future<TermSession> openTerminal(String scope, {int cols = 80, int rows = 24}) {
    final t = token;
    if (t == null) throw const ApiException(401, 'Not signed in');
    return TermSession.open(transport, token: t, scope: scope, cols: cols, rows: rows);
  }

  // ---- widgets and artifacts (3.8.7, the page's 3.5.9): the same routes as the page ----

  /// `GET /api/sessions/:id/widgets/:seq/:index/link`: the widget's signed `/preview/…` path.
  Future<String> widgetLink(String sessionId, int seq, int index) async {
    final url = _object(
      await _get('/api/sessions/${Uri.encodeComponent(sessionId)}/widgets/$seq/$index/link'),
    )['url'];
    if (url is! String) throw const ApiException(0, 'Not a RedGiant answer');
    return url;
  }

  /// «Tienilo»: the widget becomes `artefatti/<name>.html`.
  Future<({String scope, String path})> keepWidget(String sessionId, int seq, int index) async {
    final r = _object(
      await _post('/api/sessions/${Uri.encodeComponent(sessionId)}/widgets/$seq/$index/keep', {}),
    );
    return (scope: '${r['scope'] ?? ''}', path: '${r['path'] ?? ''}');
  }

  /// `POST /api/canvas/link` for a file: its signed `/preview/…` path, and whether it runs as an
  /// artifact.
  Future<({String url, bool artifact})> canvasLink(String scope, String path) async {
    final r = _object(
      await _post('/api/canvas/link', {'kind': 'file', 'scope': scope, 'path': path}),
    );
    final url = r['url'];
    if (url is! String) throw const ApiException(0, 'Not a RedGiant answer');
    return (url: url, artifact: r['artifact'] == true);
  }

  /// `POST /api/artifacts/errors`: what an artifact or a widget met, for its agent.
  Future<void> artifactErrors({
    required Map<String, Object?> ref,
    String? sessionId,
    required List<Map<String, Object?>> errors,
    bool fresh = false,
  }) => _call('POST', '/api/artifacts/errors', {
    'ref': ref,
    'sessionId': ?sessionId,
    'errors': errors,
    if (fresh) 'fresh': true,
  });

  void close() => transport.close();
}

// The page's routes for Settings › General (G42.4), as packages/web/src/api.ts calls them:
// `GET /api/setup`, `PUT /api/setup/languages|instructions|backup-model|models`, the search's
// `POST /api/setup/search/try` and `POST|DELETE /api/setup/searxng`, debug mode's `/api/debug`, and
// the refiner's `POST /api/prompts/refine[/estimate]` with any target (an agent, the Chat, every
// agent, an agent not made yet).
import 'dart:typed_data';

import '../../api/client.dart';
import '../../api/code.dart' show JobView;
import '../../api/types.dart';
import '../general_types.dart';

/// What «Improve the instructions» is about (`RefineTarget`).
sealed class RefineFor {
  const RefineFor();
  Map<String, Object?> toJson();
}

class RefineAgent extends RefineFor {
  const RefineAgent(this.agentId);
  final String agentId;
  @override
  Map<String, Object?> toJson() => {'agentId': agentId};
}

class RefineChat extends RefineFor {
  const RefineChat();
  @override
  Map<String, Object?> toJson() => {'chat': true};
}

/// The instructions for every agent.
class RefineGeneral extends RefineFor {
  const RefineGeneral();
  @override
  Map<String, Object?> toJson() => {'general': true};
}

/// An agent not made yet (the creation forms): God writes its instructions and chooses its tools.
class RefineDraft extends RefineFor {
  const RefineDraft(this.draft);

  /// `kind`, `name`, `role`, `projectId`, `mode`, `model`…, as the protocol's `draft`.
  final Map<String, Object?> draft;
  @override
  Map<String, Object?> toJson() => {'draft': draft};
}

/// One tool God proposes for a new agent: on or off, why, and what it weighs.
class ToolPick {
  const ToolPick({required this.id, required this.on, this.why = '', this.tokens = 0});

  static ToolPick? fromJson(Object? o) {
    if (o is! Map<String, dynamic> || o['id'] is! String) return null;
    return ToolPick(
      id: o['id'] as String,
      on: o['on'] != false,
      why: o['why'] is String ? o['why'] as String : '',
      tokens: (o['tokens'] as num?)?.toInt() ?? 0,
    );
  }

  final String id;
  final bool on;
  final String why;
  final int tokens;

  ToolPick withOn(bool v) => ToolPick(id: id, on: v, why: why, tokens: tokens);
}

/// The estimate before asking (`RefineEstimate`).
class RefineGuess {
  const RefineGuess({required this.tokens, this.usd, this.base = ''});
  final int tokens;
  final double? usd;

  /// The text the model starts from (a new agent: the built-in one).
  final String base;
}

/// A revised text (`RefineResult`): nothing is saved from here.
class RefineAnswer {
  const RefineAnswer({
    required this.text,
    required this.changes,
    required this.tokens,
    this.usd,
    this.tools,
  });
  final String text;
  final String changes;
  final int tokens;
  final double? usd;

  /// A draft's tools, when God chose them.
  final List<ToolPick>? tools;
}

extension GeneralApi on RedGiantClient {
  Future<GeneralState> generalState() async =>
      GeneralState.fromJson(objectOf(await getJson('/api/setup')));

  /// The interface's language (the server writes its pages and Telegram in it) and the agents'.
  Future<void> setLanguages({String? language, String? agentLanguage}) => callJson(
    'PUT',
    '/api/setup/languages',
    {'language': ?language, 'agentLanguage': ?agentLanguage},
  );

  Future<void> setGeneralInstructions(String text) =>
      callJson('PUT', '/api/setup/instructions', {'text': text});

  /// The model that tries again a task an agent gave up on; null: none.
  Future<void> setBackupModel(AgentModel? m) =>
      callJson('PUT', '/api/setup/backup-model', {'model': m?.toJson()});

  /// The search, the voice messages' or the pictures' part of `PUT /api/setup/models`.
  Future<void> setServices(Map<String, Object?> body) => callJson('PUT', '/api/setup/models', body);

  /// A search service tried before it is saved: how many results, the first's title.
  Future<({int results, String? first})> trySearch(Map<String, Object?> choice) async {
    final j = objectOf(await callJson('POST', '/api/setup/search/try', choice));
    return (
      results: (j['results'] as num?)?.toInt() ?? 0,
      first: j['first'] is String ? j['first'] as String : null,
    );
  }

  /// RedGiant's own search engine (SearXNG): a job to follow; DELETE switches it off.
  Future<JobView> startOwnSearch() async =>
      JobView.fromJson(objectOf(await callJson('POST', '/api/setup/searxng', const {})));
  Future<void> stopOwnSearch() => callJson('DELETE', '/api/setup/searxng');

  Future<DebugState> debugState() async =>
      DebugState.fromJson(objectOf(await getJson('/api/debug')));
  Future<DebugState> setDebug(bool on) async =>
      DebugState.fromJson(objectOf(await callJson('PUT', '/api/debug', {'enabled': on})));
  Future<DebugState> clearDebugLogs() async =>
      DebugState.fromJson(objectOf(await callJson('DELETE', '/api/debug/logs')));

  /// Every log as one archive (`GET /api/debug/logs`), to save and send.
  Future<Uint8List> debugLogs() => serverBytes('/api/debug/logs');

  Map<String, Object?> _refine(
    RefineFor target,
    String goal,
    String text,
    String request,
    String lang,
    AgentModel? model,
  ) => {
    'target': target.toJson(),
    'goal': goal,
    'text': text,
    'request': request,
    'lang': lang,
    if (model != null) 'model': model.toJson(),
  };

  Future<RefineGuess> refineGuess(
    RefineFor target, {
    String goal = 'refine',
    String text = '',
    String request = '',
    String lang = 'it',
    AgentModel? model,
  }) async {
    final j = objectOf(
      await callJson(
        'POST',
        '/api/prompts/refine/estimate',
        _refine(target, goal, text, request, lang, model),
      ),
    );
    return RefineGuess(
      tokens:
          ((j['inputTokens'] as num?) ?? 0).toInt() + ((j['outputTokens'] as num?) ?? 0).toInt(),
      usd: (j['usd'] as num?)?.toDouble(),
      base: j['base'] is String ? j['base'] as String : '',
    );
  }

  Future<RefineAnswer> refineText(
    RefineFor target, {
    String goal = 'refine',
    String text = '',
    String request = '',
    String lang = 'it',
    AgentModel? model,
  }) async {
    final j = objectOf(
      await callJson(
        'POST',
        '/api/prompts/refine',
        _refine(target, goal, text, request, lang, model),
      ),
    );
    final tools = j['tools'];
    return RefineAnswer(
      text: j['text'] is String ? j['text'] as String : text,
      changes: j['changes'] is String ? j['changes'] as String : '',
      tokens:
          ((j['inputTokens'] as num?) ?? 0).toInt() + ((j['outputTokens'] as num?) ?? 0).toInt(),
      usd: (j['usd'] as num?)?.toDouble(),
      tools: tools is List ? [for (final t in tools) ?ToolPick.fromJson(t)] : null,
    );
  }
}

// G42.10: the routes of Settings › Knowledge and Shared memory, as the page calls them
// (`packages/web/src/api.ts`: `knowledgeStatus`, `knowledgeSearch`, `downloadKnowledgeModel`,
// `knowledgeDisk`, `undoMemory`…), with the shapes of `packages/protocol/src/knowledge.ts` and
// `memory.ts` read leniently (a field the server does not send yet is its empty value).
import '../../api/client.dart';
import '../../api/code.dart' show JobStepView;

String? _s(Object? o) => o is String ? o : null;
int _i(Object? o) => o is num ? o.toInt() : 0;
double? _d(Object? o) => o is num ? o.toDouble() : null;
List<Map<String, dynamic>> _list(Object? o) => o is List
    ? [
        for (final x in o)
          if (x is Map<String, dynamic>) x,
      ]
    : const [];
Map<String, dynamic> _map(Object? o) => o is Map<String, dynamic> ? o : const {};
List<String> _strings(Object? o) => o is List
    ? [
        for (final x in o)
          if (x is String) x,
      ]
    : const [];

/// Who a collection is for (`KnowledgeScope`): all | agent (with [id]) | project (with [id]).
class KbScope {
  const KbScope.all() : kind = 'all', id = null;
  const KbScope.agent(String this.id) : kind = 'agent';
  const KbScope.project(String this.id) : kind = 'project';

  factory KbScope.fromJson(Object? o) {
    final j = _map(o);
    return switch (_s(j['kind'])) {
      'agent' => KbScope.agent(_s(j['agentId']) ?? ''),
      'project' => KbScope.project(_s(j['projectId']) ?? ''),
      _ => const KbScope.all(),
    };
  }

  final String kind;
  final String? id;

  Map<String, dynamic> toJson() => switch (kind) {
    'agent' => {'kind': 'agent', 'agentId': id},
    'project' => {'kind': 'project', 'projectId': id},
    _ => {'kind': 'all'},
  };

  @override
  bool operator ==(Object other) => other is KbScope && other.kind == kind && other.id == id;

  @override
  int get hashCode => Object.hash(kind, id);
}

class KbCollection {
  const KbCollection({
    required this.id,
    required this.name,
    required this.scope,
    this.description,
    this.documents = 0,
    this.chunks = 0,
  });

  factory KbCollection.fromJson(Map<String, dynamic> j) => KbCollection(
    id: _s(j['id']) ?? '',
    name: _s(j['name']) ?? '',
    scope: KbScope.fromJson(j['scope']),
    description: _s(j['description']),
    documents: _i(j['documents']),
    chunks: _i(j['chunks']),
  );

  final String id;
  final String name;
  final KbScope scope;
  final String? description;
  final int documents;
  final int chunks;
}

/// One source of a collection: its `spec` as the server keeps it (`KnowledgeSourceInput`).
class KbSource {
  const KbSource({
    required this.id,
    required this.spec,
    required this.state,
    this.error,
    this.documents = 0,
  });

  factory KbSource.fromJson(Map<String, dynamic> j) => KbSource(
    id: _s(j['id']) ?? '',
    spec: _map(j['spec']),
    state: _s(j['state']) ?? 'waiting',
    error: _s(j['error']),
    documents: _i(j['documents']),
  );

  final String id;
  final Map<String, dynamic> spec;

  /// waiting | scanning | ready | failed.
  final String state;
  final String? error;
  final int documents;

  String get kind => _s(spec['kind']) ?? '';
}

/// A document left out (skipped or failed), with its reason.
class KbDocument {
  const KbDocument({required this.id, required this.path, required this.state, this.reason});

  factory KbDocument.fromJson(Map<String, dynamic> j) => KbDocument(
    id: _s(j['id']) ?? '',
    path: _s(j['path']) ?? '',
    state: _s(j['state']) ?? 'skipped',
    reason: _s(j['reason']),
  );

  final String id;
  final String path;
  final String state;
  final String? reason;
}

class KbIndex {
  const KbIndex({
    required this.model,
    required this.state,
    required this.active,
    this.embedded = 0,
    this.total = 0,
  });

  factory KbIndex.fromJson(Map<String, dynamic> j) => KbIndex(
    model: _s(j['model']) ?? '',
    state: _s(j['state']) ?? 'ready',
    active: j['active'] == true,
    embedded: _i(j['embedded']),
    total: _i(j['total']),
  );

  final String model;
  final String state;
  final bool active;
  final int embedded;
  final int total;
}

/// `GET /api/knowledge` (`KnowledgeStatus`).
class KbStatus {
  const KbStatus({
    required this.meaningOn,
    this.meaningOff,
    this.meaningDetail,
    required this.vectorOk,
    this.vectorReason,
    this.embedding,
    this.rerank,
    this.threads = 0,
    this.ocrOn = false,
    this.ocrLanguages = const ['eng'],
    this.backupVectors = false,
    this.indexes = const [],
    this.queueDocuments = 0,
    this.queueChunks = 0,
    this.paused = false,
    this.queueError,
    this.perMinute,
    this.etaSeconds,
    this.collections = 0,
    this.chunks = 0,
    this.ocrReady = false,
    this.ocrWaiting = 0,
  });

  factory KbStatus.fromJson(Map<String, dynamic> j) {
    final m = _map(j['meaning']);
    final v = _map(j['vector']);
    final st = _map(j['settings']);
    final q = _map(j['queue']);
    final o = _map(j['ocr']);
    final so = _map(st['ocr']);
    return KbStatus(
      meaningOn: m['on'] != false,
      meaningOff: _s(m['off']),
      meaningDetail: _s(m['detail']),
      vectorOk: v['ok'] == true,
      vectorReason: _s(v['reason']),
      embedding: st['embedding'] is Map<String, dynamic>
          ? st['embedding'] as Map<String, dynamic>
          : null,
      rerank: st['rerank'] is Map<String, dynamic> ? st['rerank'] as Map<String, dynamic> : null,
      threads: _i(st['threads']),
      ocrOn: so['on'] == true,
      ocrLanguages: _strings(so['languages']).isEmpty ? const ['eng'] : _strings(so['languages']),
      backupVectors: st['backupVectors'] == true,
      indexes: [for (final x in _list(j['indexes'])) KbIndex.fromJson(x)],
      queueDocuments: _i(q['documents']),
      queueChunks: _i(q['chunks']),
      paused: q['paused'] == true,
      queueError: _s(q['error']),
      perMinute: _d(q['perMinute']),
      etaSeconds: q['etaSeconds'] is num ? (q['etaSeconds'] as num).round() : null,
      collections: _i(j['collections']),
      chunks: _i(j['chunks']),
      ocrReady: o['ready'] == true,
      ocrWaiting: _i(o['waiting']),
    );
  }

  final bool meaningOn;

  /// no_vector | no_model | downloading | failed.
  final String? meaningOff;
  final String? meaningDetail;
  final bool vectorOk;
  final String? vectorReason;
  final Map<String, dynamic>? embedding;
  final Map<String, dynamic>? rerank;
  final int threads;
  final bool ocrOn;
  final List<String> ocrLanguages;
  final bool backupVectors;
  final List<KbIndex> indexes;
  final int queueDocuments;
  final int queueChunks;
  final bool paused;
  final String? queueError;
  final double? perMinute;
  final int? etaSeconds;
  final int collections;
  final int chunks;
  final bool ocrReady;
  final int ocrWaiting;

  String? get embeddingProvider => _s(embedding?['provider']);
  String? get embeddingModel => _s(embedding?['model']);
}

/// A local model of the catalog, and whether it is on this computer already.
class KbLocalModel {
  const KbLocalModel({
    required this.id,
    required this.name,
    required this.sizeMb,
    this.defaultDims = 0,
    this.recommended = false,
    this.here = false,
  });

  factory KbLocalModel.fromJson(Map<String, dynamic> j) => KbLocalModel(
    id: _s(j['id']) ?? '',
    name: _s(j['name']) ?? '',
    sizeMb: _i(j['sizeMb']),
    defaultDims: _i(j['defaultDims']),
    recommended: j['recommended'] == true,
    here: j['here'] == true,
  );

  final String id;
  final String name;
  final int sizeMb;
  final int defaultDims;
  final bool recommended;
  final bool here;
}

/// `GET /api/knowledge/models`.
class KbModels {
  const KbModels({
    this.local = const [],
    this.localRerank = const [],
    this.cloud = const [],
    this.ocr = const [],
  });

  factory KbModels.fromJson(Map<String, dynamic> j) => KbModels(
    local: [for (final x in _list(j['local'])) KbLocalModel.fromJson(x)],
    localRerank: [for (final x in _list(j['localRerank'])) KbLocalModel.fromJson(x)],
    cloud: [
      for (final x in _list(j['cloud']))
        (provider: _s(x['provider']) ?? '', model: _s(x['model']) ?? ''),
    ],
    ocr: [
      for (final x in _list(j['ocr']))
        (
          id: _s(x['id']) ?? '',
          name: _s(x['name']) ?? '',
          sizeKb: _i(x['sizeKb']),
          here: x['here'] == true,
        ),
    ],
  );

  final List<KbLocalModel> local;
  final List<KbLocalModel> localRerank;
  final List<({String provider, String model})> cloud;
  final List<({String id, String name, int sizeKb, bool here})> ocr;
}

/// `GET /api/knowledge/disk`: bytes.
typedef KbDisk = ({int texts, int vectors, int models, int ocr});

/// Where a piece is (`KnowledgeCitation`).
class KbCitation {
  const KbCitation({
    required this.chunkId,
    required this.source,
    required this.path,
    required this.title,
    this.heading,
    this.page,
    this.lineStart,
    this.lineEnd,
  });

  factory KbCitation.fromJson(Map<String, dynamic> j) => KbCitation(
    chunkId: _s(j['chunkId']) ?? '',
    source: _s(j['source']) ?? 'file',
    path: _s(j['path']) ?? '',
    title: _s(j['title']) ?? '',
    heading: _s(j['heading']),
    page: j['page'] is num ? _i(j['page']) : null,
    lineStart: j['lineStart'] is num ? _i(j['lineStart']) : null,
    lineEnd: j['lineEnd'] is num ? _i(j['lineEnd']) : null,
  );

  final String chunkId;
  final String source;
  final String path;
  final String title;
  final String? heading;
  final int? page;
  final int? lineStart;
  final int? lineEnd;
}

typedef KbHit = ({KbCitation citation, String text});

/// `POST /api/knowledge/search`.
class KbSearchResult {
  const KbSearchResult({required this.hits, this.ms = 0, this.wordsOnly});

  factory KbSearchResult.fromJson(Map<String, dynamic> j) => KbSearchResult(
    hits: [
      for (final h in _list(j['hits']))
        (citation: KbCitation.fromJson(_map(h['citation'])), text: _s(h['text']) ?? ''),
    ],
    ms: _i(j['ms']),
    wordsOnly: _s(j['wordsOnly']),
  );

  final List<KbHit> hits;
  final int ms;
  final String? wordsOnly;
}

/// `GET /api/knowledge/open/:chunk` (`KnowledgeOpenTarget`): one of a file, an address, a text,
/// a conversation.
class KbOpen {
  const KbOpen({
    required this.title,
    this.scope,
    this.path,
    this.page,
    this.line,
    this.url,
    this.text,
    this.sessionId,
    this.agentId,
  });

  factory KbOpen.fromJson(Map<String, dynamic> j) {
    final t = _map(j['target']);
    final at = _map(t['at']);
    final chat = _map(j['chat']);
    return KbOpen(
      title: _s(j['title']) ?? '',
      scope: _s(t['scope']),
      path: _s(t['path']),
      page: at['page'] is num ? _i(at['page']) : null,
      line: at['line'] is num ? _i(at['line']) : null,
      url: _s(j['url']),
      text: _s(j['text']),
      sessionId: _s(chat['sessionId']),
      agentId: _s(chat['agentId']),
    );
  }

  final String title;
  final String? scope;
  final String? path;
  final int? page;
  final int? line;
  final String? url;
  final String? text;
  final String? sessionId;
  final String? agentId;
}

/// A job of the knowledge (`download_knowledge_model`, `download_ocr`, `download_pgvector`).
class KbJob {
  const KbJob({
    required this.id,
    required this.kind,
    required this.state,
    this.vars = const {},
    this.steps = const [],
    this.errorCode,
    this.errorMessage,
    this.startedAt,
    this.endedAt,
  });

  factory KbJob.fromJson(Map<String, dynamic> j) {
    final e = _map(j['error']);
    return KbJob(
      id: _s(j['id']) ?? '',
      kind: _s(j['kind']) ?? '',
      state: _s(j['state']) ?? 'running',
      vars: {for (final x in _map(j['vars']).entries) x.key: '${x.value}'},
      steps: [for (final s in _list(j['steps'])) JobStepView.fromJson(s)],
      errorCode: _s(e['code']),
      errorMessage: _s(e['message']),
      startedAt: DateTime.tryParse(_s(j['startedAt']) ?? ''),
      endedAt: DateTime.tryParse(_s(j['endedAt']) ?? ''),
    );
  }

  final String id;
  final String kind;
  final String state;
  final Map<String, String> vars;
  final List<JobStepView> steps;
  final String? errorCode;
  final String? errorMessage;
  final DateTime? startedAt;
  final DateTime? endedAt;

  bool get running => state == 'running';
}

/// The kinds of jobs the knowledge page follows.
const kbJobKinds = {'download_knowledge_model', 'download_ocr', 'download_pgvector'};

// ---- Shared memory (`SharedMemoryView`) ----

class MemEntry {
  const MemEntry({
    required this.id,
    required this.text,
    required this.createdAt,
    required this.by,
    this.sessionId,
    this.agentId,
    this.sessionTitle,
    this.agentName,
  });

  factory MemEntry.fromJson(Map<String, dynamic> j) => MemEntry(
    id: _s(j['id']) ?? '',
    text: _s(j['text']) ?? '',
    createdAt: _s(j['createdAt']) ?? '',
    by: _s(j['by']) ?? 'human',
    sessionId: _s(j['sessionId']),
    agentId: _s(j['agentId']),
    sessionTitle: _s(j['sessionTitle']),
    agentName: _s(j['agentName']),
  );

  final String id;
  final String text;
  final String createdAt;
  final String by;
  final String? sessionId;
  final String? agentId;
  final String? sessionTitle;
  final String? agentName;
}

class MemChange {
  const MemChange({
    required this.seq,
    required this.ts,
    required this.memoryId,
    required this.action,
    required this.text,
    this.before,
    required this.by,
    this.undoneBy,
    this.undoOf,
  });

  factory MemChange.fromJson(Map<String, dynamic> j) => MemChange(
    seq: _i(j['seq']),
    ts: _s(j['ts']) ?? '',
    memoryId: _s(j['memoryId']) ?? '',
    action: _s(j['action']) ?? 'added',
    text: _s(j['text']) ?? '',
    before: _s(j['before']),
    by: _s(j['by']) ?? 'human',
    undoneBy: j['undoneBy'] is num ? _i(j['undoneBy']) : null,
    undoOf: j['undoOf'] is num ? _i(j['undoOf']) : null,
  );

  final int seq;
  final String ts;
  final String memoryId;

  /// added | edited | removed | forgotten.
  final String action;
  final String text;
  final String? before;
  final String by;
  final int? undoneBy;
  final int? undoOf;
}

class MemView {
  const MemView({
    required this.auto,
    required this.entries,
    required this.changes,
    required this.used,
    required this.limit,
  });

  factory MemView.fromJson(Map<String, dynamic> j) => MemView(
    auto: j['auto'] == true,
    entries: [for (final x in _list(j['entries'])) MemEntry.fromJson(x)],
    changes: [for (final x in _list(j['changes'])) MemChange.fromJson(x)],
    used: _i(j['used']),
    limit: _i(j['limit']) == 0 ? 10000 : _i(j['limit']),
  );

  final bool auto;
  final List<MemEntry> entries;
  final List<MemChange> changes;
  final int used;
  final int limit;
}

extension KnowledgeApi on RedGiantClient {
  String _e(String s) => Uri.encodeComponent(s);

  Future<KbStatus> knowledgeStatus() async =>
      KbStatus.fromJson(objectOf(await getJson('/api/knowledge')));

  Future<KbSearchResult> knowledgeSearch(String query, {int limit = 8}) async =>
      KbSearchResult.fromJson(
        objectOf(await callJson('POST', '/api/knowledge/search', {'query': query, 'limit': limit})),
      );

  Future<KbOpen> knowledgeOpen(String chunkId) async =>
      KbOpen.fromJson(objectOf(await getJson('/api/knowledge/open/${_e(chunkId)}')));

  Future<KbModels> knowledgeModels() async =>
      KbModels.fromJson(objectOf(await getJson('/api/knowledge/models')));

  /// `PUT /api/knowledge/settings`: only the parts given (embedding, rerank, threads, ocr,
  /// backupVectors); a cloud model is tried once by the server before it is kept.
  Future<void> setKnowledgeSettings(Map<String, Object?> s) =>
      callJson('PUT', '/api/knowledge/settings', s);

  Future<void> downloadKnowledgeModel(String role, String id, {bool gpu = false}) =>
      callJson('POST', '/api/knowledge/models/download', {'role': role, 'id': id, 'gpu': gpu});

  Future<void> downloadOcr(List<String> languages) =>
      callJson('POST', '/api/knowledge/ocr/download', {'languages': languages});

  Future<void> rebuildKnowledge() => callJson('POST', '/api/knowledge/rebuild', const {});

  Future<void> pauseKnowledge(bool paused) =>
      callJson('POST', '/api/knowledge/pause', {'paused': paused});

  Future<KbDisk> knowledgeDisk() async {
    final j = objectOf(await getJson('/api/knowledge/disk'));
    return (
      texts: _i(j['texts']),
      vectors: _i(j['vectors']),
      models: _i(j['models']),
      ocr: _i(j['ocr']),
    );
  }

  Future<List<({String id, String name})>> knowledgeMailboxes() async => [
    for (final b in _list(objectOf(await getJson('/api/knowledge/mailboxes'))['mailboxes']))
      (id: _s(b['id']) ?? '', name: _s(b['name']) ?? ''),
  ];

  Future<List<KbCollection>> knowledgeCollections() async => [
    for (final c in _list(objectOf(await getJson('/api/knowledge/collections'))['collections']))
      KbCollection.fromJson(c),
  ];

  Future<KbCollection> createKnowledgeCollection(String name, KbScope scope) async =>
      KbCollection.fromJson(
        objectOf(
          await callJson('POST', '/api/knowledge/collections', {
            'name': name,
            'scope': scope.toJson(),
          }),
        ),
      );

  Future<void> updateKnowledgeCollection(String id, {KbScope? scope}) =>
      callJson('PUT', '/api/knowledge/collections/${_e(id)}', {'scope': ?scope?.toJson()});

  Future<void> removeKnowledgeCollection(String id) =>
      callJson('DELETE', '/api/knowledge/collections/${_e(id)}');

  Future<List<KbSource>> knowledgeSources(String id) async => [
    for (final s in _list(
      objectOf(await getJson('/api/knowledge/collections/${_e(id)}/sources'))['sources'],
    ))
      KbSource.fromJson(s),
  ];

  Future<void> addKnowledgeSource(String id, Map<String, Object?> spec) =>
      callJson('POST', '/api/knowledge/collections/${_e(id)}/sources', spec);

  Future<void> removeKnowledgeSource(String id, String source) =>
      callJson('DELETE', '/api/knowledge/collections/${_e(id)}/sources/${_e(source)}');

  Future<void> rescanKnowledge(String id, [String? source]) => callJson(
    'POST',
    '/api/knowledge/collections/${_e(id)}/rescan',
    source == null ? const <String, Object?>{} : {'source': source},
  );

  Future<List<KbDocument>> knowledgeDocuments(String id, String state, {int limit = 50}) async => [
    for (final d in _list(
      objectOf(
        await getJson('/api/knowledge/collections/${_e(id)}/documents', {
          'limit': '$limit',
          'state': state,
        }),
      )['documents'],
    ))
      KbDocument.fromJson(d),
  ];

  /// `GET /api/jobs`: the knowledge's downloads, running or ended in the last 15 seconds.
  Future<List<KbJob>> knowledgeJobs([DateTime? now]) async {
    final at = now ?? DateTime.now();
    return [
      for (final j in arrayOf(await getJson('/api/jobs')))
        if (kbJobKinds.contains(j['kind']))
          if (KbJob.fromJson(j) case final job
              when job.running || at.difference(job.endedAt ?? job.startedAt ?? at).inSeconds < 15)
            job,
    ];
  }

  /// `PUT /api/files/content` with `ifExists: replace` (the page's `uploadToCollection`).
  Future<void> writeReplacing(String scope, String path, String base64) => callJson(
    'PUT',
    '/api/files/content',
    {'scope': scope, 'path': path, 'content': base64, 'encoding': 'base64', 'ifExists': 'replace'},
  );

  // ---- Shared memory ----
  Future<MemView> sharedMemory() async => MemView.fromJson(objectOf(await getJson('/api/memory')));

  /// Whether the same fact was there already.
  Future<bool> addMemory(String text) async =>
      objectOf(await callJson('POST', '/api/memory', {'text': text}))['duplicate'] == true;

  Future<void> editMemory(String id, String text) =>
      callJson('PUT', '/api/memory/${_e(id)}', {'text': text});

  Future<void> removeMemory(String id) => callJson('DELETE', '/api/memory/${_e(id)}');

  Future<void> undoMemory(int seq) => callJson('POST', '/api/memory/undo', {'seq': seq});

  Future<void> forgetMemory(String id) =>
      callJson('POST', '/api/memory/${_e(id)}/forget', const {});

  Future<void> setMemoryAuto(bool auto) => callJson('PUT', '/api/memory/settings', {'auto': auto});
}

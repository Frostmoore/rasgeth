// Conversations, requests and tasks as the app reads them (G40.7): the shapes of
// `GET /api/sessions`, the events (`packages/protocol/src/events.ts`), `PermissionRequestInfo`
// and `QuestionRequestInfo` (wire.ts, questions.ts), `GET /api/projects/:id/tasks`. Read
// leniently. [buildItems] is the app's `buildItems` (packages/web/src/state.ts): pure, events in,
// chat items out.
import 'metrics.dart';
import 'products.dart';
import 'types.dart';
import 'widgets.dart';

export 'metrics.dart' show MessageMetrics;

Map<String, dynamic> _map(Object? o) => o is Map<String, dynamic> ? o : const {};
String? _str(Object? o) => o is String ? o : null;
List<dynamic> _list(Object? o) => o is List ? o : const [];

/// A row of `GET /api/sessions`.
class SessionRow {
  const SessionRow({
    required this.id,
    required this.agentId,
    required this.createdAt,
    this.projectId,
    this.lastAt,
    this.repliedAt,
    this.title,
    this.archived = false,
    this.running = false,
    this.task,
    this.model,
    this.pinned = false,
    this.folder,
    this.forkedFrom,
  });

  factory SessionRow.fromJson(Map<String, dynamic> j) => SessionRow(
    id: _str(j['id']) ?? '',
    agentId: _str(j['agentId']) ?? '',
    projectId: _str(j['projectId']),
    createdAt: _str(j['createdAt']) ?? '',
    lastAt: _str(j['lastAt']),
    repliedAt: _str(j['repliedAt']),
    title: _str(j['title']),
    archived: j['archived'] == true,
    running: j['running'] == true,
    task: _str(j['task']),
    model: AgentModel.fromJson(j['model']),
    pinned: j['pinned'] == true,
    folder: _str(j['folder']),
    forkedFrom: _str(j['forkedFrom']),
  );

  final String id;
  final String agentId;
  final String? projectId;
  final String createdAt;
  final String? lastAt;

  /// When the agent last answered the person here (3.8.1): its mascot stays awake a while.
  final String? repliedAt;
  final String? title;
  final bool archived;
  final bool running;

  /// The title of the task open in it.
  final String? task;

  /// The conversation's own model (null: its agent's).
  final AgentModel? model;

  /// Pinned on top of its agent's list (the page's pin).
  final bool pinned;

  /// The folder the person put it in (the page's «Move to folder»), if any.
  final String? folder;

  /// The conversation it goes on from (G36.23), if any.
  final String? forkedFrom;

  String get when => lastAt ?? createdAt;

  SessionRow withTitle(String t) => copy(title: t);

  SessionRow withRunning(bool r) => copy(running: r);

  SessionRow copy({String? title, bool? running, String? repliedAt}) => SessionRow(
    id: id,
    agentId: agentId,
    projectId: projectId,
    createdAt: createdAt,
    lastAt: lastAt,
    repliedAt: repliedAt ?? this.repliedAt,
    title: title ?? this.title,
    archived: archived,
    running: running ?? this.running,
    task: task,
    model: model,
    pinned: pinned,
    folder: folder,
    forkedFrom: forkedFrom,
  );
}

/// One stored event (the fields the app uses).
class RgEvent {
  const RgEvent({
    required this.seq,
    required this.ts,
    required this.type,
    this.payload,
    this.sessionId,
  });

  factory RgEvent.fromJson(Map<String, dynamic> j) => RgEvent(
    seq: (j['seq'] as num?)?.toInt() ?? 0,
    ts: _str(j['ts']) ?? '',
    type: _str(j['type']) ?? '',
    payload: j['erased'] == true || j['payload'] == null ? null : _map(j['payload']),
    sessionId: _str(j['sessionId']),
  );

  final int seq;
  final String ts;
  final String type;
  final String? sessionId;

  /// null when erased.
  final Map<String, dynamic>? payload;
}

/// What a conversation shows, one item after the other: the page's `ChatItem` (state.ts), with
/// the same `key` (`e<seq>`) and the same fields. [toJson] writes them as the page's JSON, for the
/// shared vectors (test/fixtures/items_vectors.json).
sealed class ChatItem {
  const ChatItem({this.key = ''});

  final String key;

  String get kind;

  Map<String, Object?> toJson() => {'kind': kind, 'key': key};
}

/// A passage of an earlier message a message answers (G36.22, `MessageQuote`).
class Quote {
  const Quote({required this.text, this.seq, this.at, this.start, this.end, this.reply});

  static Quote? fromJson(Object? o) {
    if (o is! Map<String, dynamic>) return null;
    final text = _str(o['text']);
    if (text == null || text.isEmpty) return null;
    int? n(Object? v) => v is num ? v.toInt() : null;
    return Quote(
      text: text,
      seq: n(o['seq']),
      at: _str(o['at']),
      start: n(o['start']),
      end: n(o['end']),
      reply: _str(o['reply']),
    );
  }

  final String text;
  final int? seq;
  final String? at;
  final int? start;
  final int? end;
  final String? reply;

  /// As `session.send` carries it.
  Map<String, Object?> toJson() => {
    'text': text,
    'seq': ?seq,
    'at': ?at,
    'start': ?start,
    'end': ?end,
    if (reply != null && reply!.trim().isNotEmpty) 'reply': reply!.trim(),
  };
}

/// An image of a message (`ImagePart`): base64 data and its type.
class ImageData {
  const ImageData({required this.mediaType, required this.data, this.name});

  static ImageData? fromJson(Object? o) {
    if (o is! Map<String, dynamic>) return null;
    final data = _str(o['data']);
    if (data == null || data.isEmpty) return null;
    return ImageData(
      mediaType: _str(o['mediaType']) ?? 'image/png',
      data: data,
      name: _str(o['name']),
    );
  }

  final String mediaType;
  final String data;
  final String? name;

  Map<String, Object?> toJson() => {
    'type': 'image',
    'mediaType': mediaType,
    'data': data,
    'name': ?name,
  };
}

/// The voice note at the end of a message said by voice (G38.4, `stripVoiceHint`).
String stripVoiceHint(String text) {
  const open = '<voice-mode>';
  const close = '</voice-mode>';
  final at = text.lastIndexOf(open);
  if (at < 0 || !text.trimRight().endsWith(close)) return text;
  return text.substring(0, at).trimRight();
}

class UserItem extends ChatItem {
  const UserItem({
    super.key,
    required this.text,
    required this.ts,
    this.imageParts = const [],
    this.from,
    this.quotes = const [],
    this.via,
  });

  final String text;
  final String ts;
  final List<ImageData> imageParts;

  int get images => imageParts.length;

  /// The passages it answers.
  final List<Quote> quotes;

  /// Another agent, an automation, a chat platform (null: the person).
  final String? from;

  /// Said by voice or sent by a button of an artifact or a widget (`voice`, `artifact`).
  final String? via;

  /// Its event (`e<seq>`): what «Modifica» and «Continua da qui» start from.
  int? get seq => int.tryParse(key.replaceFirst('e', ''));

  @override
  String get kind => 'user';

  @override
  Map<String, Object?> toJson() => {
    ...super.toJson(),
    'text': text,
    'ts': ts,
    'images': [for (final i in imageParts) i.toJson()],
    'from': ?from,
    if (quotes.isNotEmpty) 'quotes': [for (final q in quotes) q.toJson()],
    'via': ?via,
  };
}

class AssistantItem extends ChatItem {
  AssistantItem({
    super.key,
    required this.text,
    required this.thinking,
    required this.ts,
    this.seq,
    this.live = false,
    this.metrics,
    this.model,
    this.costUsd,
    this.costUnknown = false,
    this.stopReason = '',
    this.imported = false,
    this.stepLimit = false,
  });

  final String text;
  final String thinking;
  final String ts;

  /// The message's figures as the page shows them under it (G40.17): null while it streams and for
  /// imported or external (ACP) agents' messages, which RedGiant did not count.
  final MessageMetrics? metrics;
  final String? model;
  final double? costUsd;

  /// The model's price is not known (3.5.4).
  final bool costUnknown;

  /// The `message.assistant` event (null while it streams): what «Salva» and quotes point at.
  final int? seq;

  /// Still being written (the deltas not persisted yet).
  final bool live;
  final String stopReason;

  /// Brought in from another assistant or an external agent: no figures.
  final bool imported;

  /// The closing summary at the step limit, nothing written after it yet (3.5.6): «Continua».
  bool stepLimit;

  @override
  String get kind => 'assistant';

  @override
  Map<String, Object?> toJson() => {
    ...super.toJson(),
    'seq': seq,
    'text': text,
    'thinking': thinking,
    'stopReason': stopReason,
    if (imported) 'imported': true,
    if (stepLimit) 'stepLimit': true,
  };
}

class ToolItem extends ChatItem {
  ToolItem({
    super.key,
    required this.callId,
    required this.tool,
    required this.input,
    this.viaScript = false,
  });

  final String callId;
  final String tool;
  final Object? input;

  /// Called by the agent's program (run_script), not by the model directly.
  final bool viaScript;
  bool? ok;
  String? output;

  /// The result never came (the model spoke again, the turn was stopped): the page's `toolNoResult`.
  bool lost = false;

  /// What canvas_look drew for the agent (G36.12): the person sees what it saw.
  List<ImageData> images = const [];

  @override
  String get kind => 'tool';

  @override
  Map<String, Object?> toJson() => {
    ...super.toJson(),
    'callId': callId,
    'tool': tool,
    'input': input,
    if (ok != null)
      'result': {
        'ok': ok,
        'output': lost ? '<toolNoResult>' : output,
        if (images.isNotEmpty) 'images': [for (final i in images) i.toJson()],
      },
    if (viaScript) 'viaScript': true,
  };
}

/// A question (`ask_user`) or a plan (`propose_plan`) asked in the conversation.
class QuestionItem extends ChatItem {
  QuestionItem({super.key, required this.requestId, required this.questions, this.plan});

  final String requestId;
  final List<Question> questions;
  final String? plan;

  /// Answered (with [answers], or null: nobody answered); false while it waits.
  bool answered = false;
  List<List<String>>? answers;

  @override
  String get kind => 'question';

  @override
  Map<String, Object?> toJson() => {
    ...super.toJson(),
    'requestId': requestId,
    'questions': [for (final q in questions) q.toJson()],
    'plan': ?plan,
    if (answered) 'answers': answers,
  };
}

enum NoticeLevel { info, ok, warn, error }

class NoticeItem extends ChatItem {
  const NoticeItem(this.level, this.text, {super.key, this.code, this.params = const {}});

  final NoticeLevel level;
  final String text;

  /// A notice the view says in words (`imported`: brought in from ChatGPT or Claude).
  final String? code;
  final Map<String, String> params;

  @override
  String get kind => 'notice';

  @override
  Map<String, Object?> toJson() => {
    ...super.toJson(),
    'tone': level.name,
    'text': code == null ? text : '<$code>',
  };
}

/// A call that should have been in the cache was not (G24.14c).
class CacheItem extends ChatItem {
  const CacheItem({super.key, required this.expected, required this.cached});

  final int expected;
  final int cached;

  @override
  String get kind => 'cache';

  @override
  Map<String, Object?> toJson() => {...super.toJson(), 'expected': expected, 'cached': cached};
}

/// `canvas.show`: a file (or a port) the agent showed.
class CanvasItem extends ChatItem {
  const CanvasItem({super.key, required this.title, required this.target});

  final String title;
  final Map<String, dynamic> target;

  String? get scope => _str(target['scope']);
  String? get path => _str(target['path']);
  bool get isFile => target['kind'] == 'file';

  /// An agent's port (G42.2): its agent, number and path.
  bool get isPort => target['kind'] == 'port' && agentId != null && port != null;
  String? get agentId => _str(target['agentId']);
  int? get port => (target['port'] as num?)?.toInt();

  @override
  String get kind => 'canvas';

  @override
  Map<String, Object?> toJson() => {...super.toJson(), 'title': title, 'target': target};
}

/// `file.sent`: a file the agent handed over.
class FileItem extends ChatItem {
  const FileItem({
    super.key,
    required this.scope,
    required this.path,
    required this.name,
    required this.mime,
    required this.size,
    this.caption,
  });

  final String scope;
  final String path;
  final String name;
  final String mime;
  final int size;
  final String? caption;

  @override
  String get kind => 'file';

  @override
  Map<String, Object?> toJson() => {
    ...super.toJson(),
    'scope': scope,
    'path': path,
    'name': name,
    'size': size,
    'mime': mime,
    'caption': ?caption,
  };
}

/// `products.shown` (G40.16): a carousel of product cards.
class ProductsItem extends ChatItem {
  const ProductsItem({super.key, required this.seq, required this.products, this.title});

  final int seq;
  final String? title;
  final List<ProductCard> products;

  @override
  String get kind => 'products';

  @override
  Map<String, Object?> toJson() => {...super.toJson(), 'title': ?title, 'count': products.length};
}

/// A board of variants (G25.4): a card that opens it, with what the person said.
class VariantsItem extends ChatItem {
  VariantsItem({
    super.key,
    required this.sessionId,
    required this.proposalId,
    required this.title,
    required this.count,
  });

  final String sessionId;
  final String proposalId;
  final String title;
  final int count;
  int? chosen;

  @override
  String get kind => 'variants';

  @override
  Map<String, Object?> toJson() => {
    ...super.toJson(),
    'sessionId': sessionId,
    'proposalId': proposalId,
    'title': title,
    'count': count,
    'chosen': chosen,
  };
}

/// Where a conversation that goes on from another one starts its own part (G36.23).
class ForkItem extends ChatItem {
  const ForkItem({super.key, required this.fromSessionId, this.fromTitle, this.how = 'edit'});

  final String fromSessionId;
  final String? fromTitle;

  /// `continue` («Continua da qui») or `edit` (a message sent again, edited).
  final String how;

  @override
  String get kind => 'fork';

  @override
  Map<String, Object?> toJson() => {
    ...super.toJson(),
    'fromSessionId': fromSessionId,
    'fromTitle': ?fromTitle,
    'how': how,
  };
}

/// The conversation was summarised here (G24.14).
class CompactionItem extends ChatItem {
  CompactionItem({super.key, required this.seq, required this.summary, required this.reason});

  final int seq;
  final String summary;

  /// `auto`, `manual`, `emergency` or `engine`.
  final String reason;
  bool undone = false;

  /// The last summary asked by hand, nothing said since: it can be undone.
  bool undoable = false;

  @override
  String get kind => 'compaction';

  @override
  Map<String, Object?> toJson() => {
    ...super.toJson(),
    'seq': seq,
    'summary': summary,
    'reason': reason,
    'undone': undone,
    'undoable': undoable,
  };
}

/// A ```widget block of an answer (3.8.7, the page's `widget` item): run in its frame after the
/// answer, whose text keeps the rest. [html] only for the computers that cannot run it.
class WidgetItem extends ChatItem {
  const WidgetItem({
    super.key,
    required this.sessionId,
    required this.seq,
    required this.index,
    required this.title,
    this.html = '',
  });

  final String sessionId;
  final int seq;
  final int index;
  final String title;
  final String html;

  @override
  String get kind => 'widget';

  @override
  Map<String, Object?> toJson() => {
    ...super.toJson(),
    'sessionId': sessionId,
    'seq': seq,
    'index': index,
    'title': title,
  };
}

/// Our tools that make things, by what they make (2026-11-19, the page's `GENERATION_TOOLS`).
const _generationTools = {
  'image_generation': 'image',
  'generate_image': 'image',
  'video_generation': 'video',
  'audio_generation': 'audio',
};

/// What is being made right now (the page's `generatingNow`, 2026-11-19): the last call to a
/// generation tool still without its result, ours or the model's own (logged as ours): `image`,
/// `video`, `audio` or null. The chat shows «generating a picture» for it.
String? generatingNow(List<RgEvent> events) {
  final open = <String, String>{};
  for (final e in events) {
    final p = e.payload;
    if (p == null) continue;
    if (e.type == 'tool.call') {
      final kind = _generationTools[p['tool']];
      if (kind != null) open['${p['callId']}'] = kind;
    } else if (e.type == 'tool.result') {
      open.remove('${p['callId']}');
    } else if (e.type == 'message.user' && p['from'] != 'redgiant') {
      open.clear();
    }
  }
  return open.isEmpty ? null : open.values.last;
}

/// Their question card stands for these calls: no tool line for them. `show_products` shows as
/// its cards (`products.shown`).
const _hiddenTools = {'ask_user', 'propose_plan'};

/// The page's `buildItems` (packages/web/src/state.ts): events in order, plus the text and
/// reasoning still streaming. With [sessionId] (or the events' own) an answer's ```widget blocks
/// become widgets after it. Pure; the same events give the same items as the page's
/// (test/fixtures/items_vectors.json).
List<ChatItem> buildItems(
  List<RgEvent> events, {
  String liveText = '',
  String liveThinking = '',
  String? sessionId,
}) {
  final out = <ChatItem>[];
  // Calls by id, oldest first: an id given twice still pairs each result with its own call.
  final tools = <String, List<ToolItem>>{};
  final open = <ToolItem>{};
  final asked = <String, QuestionItem>{};
  AssistantItem? limited;
  for (final e in events) {
    final key = 'e${e.seq}';
    final p = e.payload;
    if (p == null) {
      out.add(NoticeItem(NoticeLevel.warn, '${e.type} (erased)', key: key));
      continue;
    }
    switch (e.type) {
      case 'message.user':
        final from = _str(p['from']);
        // RedGiant's own note to the model (the step limit): the answer is what the person reads.
        if (from == 'redgiant') break;
        limited?.stepLimit = false;
        limited = null;
        final via = _str(p['via']);
        final text = _str(p['text']) ?? '';
        out.add(
          UserItem(
            key: key,
            text: via == 'voice' ? stripVoiceHint(text) : text,
            ts: e.ts,
            imageParts: [for (final i in _list(p['images'])) ?ImageData.fromJson(i)],
            from: from == null || from.isEmpty ? null : from,
            quotes: [for (final q in _list(p['quotes'])) ?Quote.fromJson(q)],
            via: via,
          ),
        );
      case 'session.forked':
        final title = _str(p['fromTitle']);
        out.add(
          ForkItem(
            key: key,
            fromSessionId: _str(p['fromSessionId']) ?? '',
            fromTitle: title == null || title.isEmpty ? null : title,
            how: _str(p['how']) ?? 'edit',
          ),
        );
      case 'message.assistant':
        // A final answer after these calls: whatever they were, they are over, their result lost.
        if (p['stopReason'] != 'tool_use') {
          for (final c in open) {
            c.ok = false;
            c.output = '';
            c.lost = true;
          }
          open.clear();
        }
        final parts = _list(p['parts']).whereType<Map<String, dynamic>>();
        // Its ```widget blocks become widgets after it (3.8.7, the page's `splitWidgets`).
        final split = splitWidgets([
          for (final x in parts.where((x) => x['type'] == 'text')) _str(x['text']) ?? '',
        ]);
        final text = split.texts;
        final thinking = parts
            .where((x) => x['type'] == 'thinking')
            .map((x) => _str(x['text']) ?? '');
        final provider = _str(p['provider']) ?? '';
        final imported = provider.startsWith('import:') || provider == 'acp';
        final item = AssistantItem(
          key: key,
          text: text.join('\n\n').trim(),
          thinking: thinking.where((x) => x.isNotEmpty).join('\n\n').trim(),
          ts: e.ts,
          seq: e.seq,
          metrics: imported ? null : MessageMetrics.fromJson(p['metrics']),
          model: _str(p['model']),
          costUsd: (p['costUsd'] as num?)?.toDouble(),
          costUnknown: p['costUnknown'] == true,
          stopReason: _str(p['stopReason']) ?? '',
          imported: imported,
        );
        out.add(item);
        if (p['stepLimit'] == true) {
          item.stepLimit = true;
          limited = item;
        }
        final sid = sessionId ?? e.sessionId;
        if (sid != null) {
          for (final w in split.widgets) {
            out.add(
              WidgetItem(
                key: '${key}w${w.index}',
                sessionId: sid,
                seq: e.seq,
                index: w.index,
                title: w.title,
                html: w.html,
              ),
            );
          }
        }
      case 'session.imported':
        final source = switch (_str(p['source'])) {
          'chatgpt' => 'ChatGPT',
          'claude' => 'Claude',
          final s => s ?? '',
        };
        final at = DateTime.tryParse(_str(p['updatedAt']) ?? _str(p['createdAt']) ?? '');
        out.add(
          NoticeItem(
            NoticeLevel.info,
            source,
            key: key,
            code: 'imported',
            params: {'source': source, if (at != null) 'date': at.toIso8601String()},
          ),
        );
      case 'tool.call':
        final tool = _str(p['tool']) ?? '';
        if (_hiddenTools.contains(tool)) break;
        final item = ToolItem(
          key: key,
          callId: _str(p['callId']) ?? '',
          tool: tool,
          input: p['input'],
        );
        (tools[item.callId] ??= []).add(item);
        open.add(item);
        out.add(item);
      case 'tool.result':
        final same = tools[_str(p['callId'])] ?? const <ToolItem>[];
        final call = same.where((c) => c.ok == null).firstOrNull ?? same.lastOrNull;
        if (call != null) {
          open.remove(call);
          call.ok = p['ok'] == true;
          call.output = _str(p['output']) ?? '';
          call.lost = false;
          if (call.tool == 'canvas_look') {
            call.images = [for (final i in _list(p['images'])) ?ImageData.fromJson(i)];
          }
        }
      case 'script.call':
        out.add(
          ToolItem(
              key: key,
              callId: key,
              tool: _str(p['name']) ?? '',
              input: p['input'],
              viaScript: true,
            )
            ..ok = p['ok'] == true
            ..output = _str(p['output']) ?? '',
        );
      case 'question.asked':
        final item = QuestionItem(
          key: key,
          requestId: _str(p['requestId']) ?? '',
          questions: [
            for (final q in _list(p['questions']).whereType<Map<String, dynamic>>())
              Question.fromJson(q),
          ],
          plan: _str(p['plan']),
        );
        asked[item.requestId] = item;
        out.add(item);
      case 'question.answered':
        final item = asked[_str(p['requestId'])];
        if (item != null) {
          item.answered = true;
          final a = p['answers'];
          item.answers = a is List
              ? [for (final x in a) x is List ? x.whereType<String>().toList() : <String>[]]
              : null;
        }
      case 'permission.requested':
        out.add(NoticeItem(NoticeLevel.warn, '${p['reason']} (${p['askedTo']})', key: key));
      case 'permission.resolved':
        final d = p['decision'];
        out.add(
          NoticeItem(
            d == 'allow'
                ? NoticeLevel.ok
                : d == 'deny'
                ? NoticeLevel.error
                : NoticeLevel.info,
            '$d (${p['by']})',
            key: key,
          ),
        );
      case 'hook.blocked':
        out.add(NoticeItem(NoticeLevel.error, _str(p['reason']) ?? '', key: key));
      case 'compaction':
        out.add(
          CompactionItem(
            key: key,
            seq: e.seq,
            summary: _str(p['summary']) ?? '',
            reason: _str(p['reason']) ?? 'auto',
          ),
        );
      case 'engine.compacted':
        out.add(CompactionItem(key: key, seq: e.seq, summary: '', reason: 'engine'));
      case 'variants.proposed':
        out.add(
          VariantsItem(
            key: key,
            sessionId: e.sessionId ?? '',
            proposalId: _str(p['proposalId']) ?? '',
            title: _str(p['title']) ?? '',
            count: _list(p['variants']).length,
          ),
        );
      case 'variants.answered':
        final v = out
            .whereType<VariantsItem>()
            .where((i) => i.proposalId == _str(p['proposalId']))
            .firstOrNull;
        if (v != null && p['choice'] != null && p['choice'] != false) {
          v.chosen = (p['variant'] as num?)?.toInt();
        }
      case 'file.sent':
        out.add(
          FileItem(
            key: key,
            scope: _str(p['scope']) ?? '',
            path: _str(p['path']) ?? '',
            name: _str(p['name']) ?? '',
            mime: _str(p['mime']) ?? '',
            size: (p['size'] as num?)?.toInt() ?? 0,
            caption: _str(p['caption']),
          ),
        );
      case 'products.shown':
        final cards = [for (final c in _list(p['products'])) ?ProductCard.fromJson(c)];
        out.add(ProductsItem(key: key, seq: e.seq, title: _str(p['title']), products: cards));
      case 'canvas.show':
        out.add(CanvasItem(key: key, title: _str(p['title']) ?? '', target: _map(p['target'])));
      case 'cache.missed':
        out.add(
          CacheItem(
            key: key,
            expected: (p['expected'] as num?)?.toInt() ?? 0,
            cached: (p['cached'] as num?)?.toInt() ?? 0,
          ),
        );
      case 'compaction.undone':
        final c = out
            .whereType<CompactionItem>()
            .where((i) => i.seq == (p['compactionSeq'] as num?)?.toInt())
            .firstOrNull;
        c?.undone = true;
      case 'task.opened':
        out.add(NoticeItem(NoticeLevel.info, '${p['taskId']}: ${p['title']}', key: key));
      case 'task.verified':
        out.add(
          NoticeItem(
            p['passed'] == true ? NoticeLevel.ok : NoticeLevel.error,
            _str(p['verifier']) ?? '',
            key: key,
          ),
        );
      case 'task.closed':
        out.add(
          NoticeItem(
            p['outcome'] == 'abandoned' ? NoticeLevel.error : NoticeLevel.ok,
            '${p['taskId']}: ${p['outcome']}',
            key: key,
          ),
        );
      case 'budget.exceeded':
        out.add(
          NoticeItem(
            NoticeLevel.error,
            '\$ budget ${p['scope']}: ${p['used']} / ${p['limit']}',
            key: key,
          ),
        );
      default:
        break;
    }
  }
  final last = out.reversed.whereType<CompactionItem>().where((i) => !i.undone).firstOrNull;
  if (last != null && last.reason == 'manual') {
    final after = out.sublist(out.indexOf(last) + 1);
    last.undoable = !after.any((i) => i is UserItem || i is AssistantItem);
  }
  if (liveText.isNotEmpty || liveThinking.isNotEmpty) {
    out.add(AssistantItem(text: liveText, thinking: liveThinking, ts: '', live: true));
  }
  return out;
}

/// What the view shows of an answer: its text or reasoning, or its figures. The page shows every
/// `message.assistant` bubble; the app leaves out the ones with nothing at all to show.
bool showsSomething(AssistantItem a) =>
    a.live || a.text.isNotEmpty || a.thinking.isNotEmpty || a.metrics != null || a.stepLimit;

/// The steps the panel above the composer shows (`latestTodos`, Chat.tsx): the latest
/// `update_todos` call as soon as it is recorded; one the tool refused (or would refuse: two in
/// progress) leaves the previous list.
List<({String content, String status})> latestTodos(List<ChatItem> items) {
  for (final it in items.reversed) {
    if (it is! ToolItem || it.tool != 'update_todos') continue;
    if (it.ok == false) continue;
    final todos = it.input is Map ? (it.input as Map)['todos'] : null;
    if (todos is! List) continue;
    final steps = [
      for (final x in todos)
        if (x is Map && x['content'] is String && x['status'] is String)
          (content: x['content'] as String, status: x['status'] as String),
    ];
    if (steps.where((x) => x.status == 'in_progress').length > 1) continue;
    return steps;
  }
  return const [];
}

/// Events that leave a conversation blocked until the person does something.
const blockingEvents = {'budget.exceeded', 'hook.blocked'};

/// The todos of a conversation: the last `update_todos` input.
({int done, int total})? todosOf(List<RgEvent> events) {
  for (final e in events.reversed) {
    if (e.type != 'tool.call' || e.payload?['tool'] != 'update_todos') continue;
    final todos = _list(_map(e.payload?['input'])['todos']).whereType<Map<String, dynamic>>();
    if (todos.isEmpty) continue;
    return (done: todos.where((t) => t['status'] == 'completed').length, total: todos.length);
  }
  return null;
}

/// The verifiers a conversation ran for its tasks (`task.verified`), the last first.
List<({String taskId, String verifier, bool passed})> verifiersOf(List<RgEvent> events) => [
  for (final e in events.reversed)
    if (e.type == 'task.verified' && e.payload != null)
      (
        taskId: _str(e.payload!['taskId']) ?? '',
        verifier: _str(e.payload!['verifier']) ?? '',
        passed: e.payload!['passed'] == true,
      ),
];

/// `CriticalDetail`: what a truly dangerous call does.
class CriticalDetail {
  const CriticalDetail({required this.id, required this.action, this.target});

  factory CriticalDetail.fromJson(Map<String, dynamic> j) => CriticalDetail(
    id: _str(j['id']) ?? '',
    action: _str(j['action']) ?? '',
    target: _str(j['target']),
  );

  final String id;
  final String action;
  final String? target;
}

/// A request waiting for the person: a permission (`permission.request`) or a question.
sealed class PersonRequest {
  const PersonRequest();

  String get requestId;
  String get agentId;
  String get agentName;
  String get createdAt;
}

class PermissionRequest extends PersonRequest {
  const PermissionRequest({
    required this.requestId,
    required this.agentId,
    required this.agentName,
    required this.tool,
    required this.input,
    required this.reasons,
    required this.danger,
    required this.critical,
    required this.createdAt,
    this.sessionId,
    this.projectId,
    this.words = const {},
  });

  factory PermissionRequest.fromJson(Map<String, dynamic> j) => PermissionRequest(
    requestId: _str(j['requestId']) ?? '',
    agentId: _str(j['agentId']) ?? '',
    agentName: _str(j['agentName']) ?? '',
    tool: _str(j['tool']) ?? '',
    input: j['input'],
    reasons: _list(j['reasons']).whereType<String>().toList(),
    danger: _list(j['danger']).whereType<String>().toList(),
    critical: [
      for (final c in _list(j['critical']).whereType<Map<String, dynamic>>())
        CriticalDetail.fromJson(c),
    ],
    createdAt: _str(j['createdAt']) ?? '',
    sessionId: _str(j['sessionId']),
    projectId: _str(j['projectId']),
    words: {
      for (final e in _map(j['words']).entries)
        if (e.value case final Map<String, dynamic> w) e.key: RequestWords.fromJson(w),
    },
  );

  @override
  final String requestId;
  @override
  final String agentId;
  @override
  final String agentName;
  final String tool;
  final Object? input;
  final List<String> reasons;
  final List<String> danger;
  final List<CriticalDetail> critical;
  @override
  final String createdAt;
  final String? sessionId;
  final String? projectId;

  /// The request in words by language (`withRequestWords` on the server, G42.1).
  final Map<String, RequestWords> words;

  /// Its words in [lang] (the other language, else none from an older server).
  RequestWords? wordsIn(String lang) => words[lang] ?? words['en'] ?? words.values.firstOrNull;

  /// Truly dangerous (G36.17b): a full screen of its own, never the quick yes. The server says
  /// so with `critical` (from `criticalOf`); the dangers' ids of `critical.ts` count too.
  bool get isCritical => critical.isNotEmpty || danger.any(criticalDangers.contains);
}

/// A request in one language, as the server says it (`RequestWordsLang` in
/// packages/protocol/src/request-words.ts): what it does, its reasons, the red card's sentences,
/// its dangers' names.
class RequestWords {
  const RequestWords({
    required this.what,
    this.reasons = const [],
    this.critical = const [],
    this.dangers = const [],
  });

  factory RequestWords.fromJson(Map<String, dynamic> j) => RequestWords(
    what: _str(j['what']) ?? '',
    reasons: _list(j['reasons']).whereType<String>().toList(),
    critical: _list(j['critical']).whereType<String>().toList(),
    dangers: [
      for (final d in _list(j['dangers']).whereType<Map<String, dynamic>>())
        (id: _str(d['id']) ?? '', name: _str(d['name']) ?? '', hint: _str(d['hint']) ?? ''),
    ],
  );

  final String what;
  final List<String> reasons;
  final List<String> critical;
  final List<({String id, String name, String hint})> dangers;
}

/// The critical dangers' ids (`CRITICAL_IDS` in packages/protocol/src/critical.ts).
const criticalDangers = {
  'critical-system',
  'critical-delete',
  'critical-secret',
  'critical-payment',
  'critical-protections',
};

class QuestionOption {
  const QuestionOption(this.label, [this.description]);

  final String label;
  final String? description;
}

class Question {
  const Question({
    required this.question,
    this.header,
    required this.options,
    this.multiSelect = false,
  });

  factory Question.fromJson(Map<String, dynamic> j) => Question(
    question: _str(j['question']) ?? '',
    header: _str(j['header']),
    options: [
      for (final o in _list(j['options']).whereType<Map<String, dynamic>>())
        QuestionOption(_str(o['label']) ?? '', _str(o['description'])),
    ],
    multiSelect: j['multiSelect'] == true,
  );

  final String question;
  final String? header;
  final List<QuestionOption> options;
  final bool multiSelect;

  Map<String, Object?> toJson() => {
    'question': question,
    'header': ?header,
    'options': [
      for (final o in options) {'label': o.label, 'description': ?o.description},
    ],
    'multiSelect': multiSelect,
  };
}

class QuestionRequest extends PersonRequest {
  const QuestionRequest({
    required this.requestId,
    required this.agentId,
    required this.agentName,
    required this.sessionId,
    required this.questions,
    required this.createdAt,
    this.plan,
  });

  factory QuestionRequest.fromJson(Map<String, dynamic> j) => QuestionRequest(
    requestId: _str(j['requestId']) ?? '',
    agentId: _str(j['agentId']) ?? '',
    agentName: _str(j['agentName']) ?? '',
    sessionId: _str(j['sessionId']) ?? '',
    questions: [
      for (final q in _list(j['questions']).whereType<Map<String, dynamic>>()) Question.fromJson(q),
    ],
    createdAt: _str(j['createdAt']) ?? '',
    plan: _str(j['plan']),
  );

  @override
  final String requestId;
  @override
  final String agentId;
  @override
  final String agentName;
  final String sessionId;
  final List<Question> questions;
  @override
  final String createdAt;
  final String? plan;
}

class Project {
  const Project({
    required this.id,
    required this.name,
    this.archived = false,
    this.git,
    this.gitError,
    this.archivedAt,
    this.path,
    this.maxAgents = projectAgentsDefault,
    this.agents,
  });

  factory Project.fromJson(Map<String, dynamic> j) => Project(
    id: _str(j['id']) ?? '',
    name: _str(j['name']) ?? '',
    archived: j['archivedAt'] != null,
    archivedAt: _str(j['archivedAt']),
    git: j['git'] is bool ? j['git'] as bool : null,
    gitError: _str(j['gitError']),
    path: _str(j['path']),
    maxAgents: j['maxAgents'] is num ? (j['maxAgents'] as num).toInt() : projectAgentsDefault,
    agents: j['agents'] is num ? (j['agents'] as num).toInt() : null,
  );

  /// The page's `PROJECT_AGENTS_DEFAULT` and `PROJECT_AGENTS_MAX` (protocol, 2026-11-18).
  static const projectAgentsDefault = 3;
  static const projectAgentsMax = 10;

  final String id;
  final String name;
  final bool archived;

  /// Its folder on the server (Settings › Projects shows it).
  final String? path;

  /// When it was archived (p3.5.3), as the server says.
  final String? archivedAt;

  /// Whether its folder has a git repository (3.5.12); null from servers that do not say.
  final bool? git;

  /// Why the repository could not be made, when [git] is false on a new folder.
  final String? gitError;

  /// How many agents it may have besides its orchestrator (2026-11-18): 0 to 10, default 3.
  final int maxAgents;

  /// How many count toward [maxAgents] now (its agents and the sub-agents at work); null from
  /// servers that do not say.
  final int? agents;
}

/// A part of a project in its own folder (G24.13, `Subproject` of the page's api.ts).
class Subproject {
  const Subproject({
    required this.id,
    required this.projectId,
    required this.name,
    required this.dir,
    this.createdAt,
  });

  factory Subproject.fromJson(Map<String, dynamic> j) => Subproject(
    id: _str(j['id']) ?? '',
    projectId: _str(j['projectId']) ?? '',
    name: _str(j['name']) ?? '',
    dir: _str(j['dir']) ?? '',
    createdAt: _str(j['createdAt']),
  );

  final String id;
  final String projectId;
  final String name;

  /// Its folder inside the project (the explorer opens there).
  final String dir;
  final String? createdAt;
}

/// `GET /api/projects/:id/work` (p3.5.3): what «Archive» stops, said first.
class ProjectWork {
  const ProjectWork({this.working = const [], this.automations = const []});

  factory ProjectWork.fromJson(Map<String, dynamic> j) => ProjectWork(
    working: [
      for (final w in (j['working'] as List? ?? const []).whereType<Map<String, dynamic>>())
        (
          sessionId: _str(w['sessionId']) ?? '',
          agentName: _str(w['agentName']) ?? '',
          title: _str(w['title']),
        ),
    ],
    automations: [
      for (final a in (j['automations'] as List? ?? const []).whereType<Map<String, dynamic>>())
        _str(a['name']) ?? '',
    ],
  );

  final List<({String sessionId, String agentName, String? title})> working;
  final List<String> automations;
}

enum TaskOutcome { open, verified, notTestable, abandoned }

enum TaskColumn { running, toVerify, done }

TaskOutcome taskOutcomeFrom(String? s) => switch (s) {
  'verified' => TaskOutcome.verified,
  'not_testable' => TaskOutcome.notTestable,
  'abandoned' => TaskOutcome.abandoned,
  _ => TaskOutcome.open,
};

/// A task (RD17) as `GET /api/projects/:id/tasks` lists it.
class TaskRow {
  const TaskRow({
    required this.id,
    required this.title,
    required this.agentName,
    required this.outcome,
    required this.openedAt,
    this.agentId,
    this.sessionId,
    this.projectId,
    this.verifier,
    this.verified,
    this.note,
  });

  factory TaskRow.fromJson(Map<String, dynamic> j, {String? projectId}) => TaskRow(
    id: _str(j['id']) ?? '',
    title: _str(j['title']) ?? '',
    agentId: _str(j['agentId']),
    agentName: _str(j['agentName']) ?? '-',
    sessionId: _str(j['sessionId']),
    outcome: taskOutcomeFrom(_str(j['outcome'])),
    openedAt: _str(j['openedAt']) ?? '',
    projectId: projectId,
    verifier: j['verifier'] is Map ? _str((j['verifier'] as Map)['command']) : null,
    verified: j['verifier'] is Map ? (j['verifier'] as Map)['passed'] == true : null,
    note: _str(j['note']),
  );

  final String id;
  final String title;
  final String? agentId;
  final String agentName;
  final String? sessionId;
  final TaskOutcome outcome;
  final String openedAt;
  final String? projectId;

  /// The last verifier run (G40.11) and its result; null when none ran yet.
  final String? verifier;
  final bool? verified;

  /// Why it closed without a verifier, or was given up on.
  final String? note;

  bool get done => outcome != TaskOutcome.open;

  /// The board's column: in progress, to verify (a verifier ran and did not pass yet), done.
  TaskColumn get column => done
      ? TaskColumn.done
      : verifier != null
      ? TaskColumn.toVerify
      : TaskColumn.running;
}

/// `GET /api/files/content`.
class FileContent {
  const FileContent({
    required this.path,
    required this.text,
    required this.base64,
    required this.size,
  });

  factory FileContent.fromJson(Map<String, dynamic> j) {
    final b64 = j['encoding'] == 'base64';
    return FileContent(
      path: _str(j['path']) ?? '',
      text: b64 ? null : _str(j['content']),
      base64: b64 ? _str(j['content']) : null,
      size: (j['size'] as num?)?.toInt() ?? 0,
    );
  }

  final String path;
  final String? text;
  final String? base64;
  final int size;
}

/// The most passages one message answers (`MAX_QUOTES`).
const maxQuotes = 10;

/// A message with quotes for a route that takes none: each passage as a Markdown quote first.
String withQuotesInText(String text, List<Quote> quotes) {
  if (quotes.isEmpty) return text;
  final parts = [
    for (final q in quotes) ...[
      q.text.split('\n').map((l) => '> $l').join('\n'),
      if (q.reply != null && q.reply!.trim().isNotEmpty) q.reply!.trim(),
    ],
    if (text.trim().isNotEmpty) text.trim(),
  ];
  return parts.join('\n\n');
}

/// `session.send` as the page sends it (wire.ts), with the passages it answers (G36.22).
Map<String, Object?> sessionSendMessage(
  String sessionId,
  String text, {
  List<Map<String, Object?>>? images,
  List<Quote> quotes = const [],
  String? clientId,
}) => {
  'type': 'session.send',
  'sessionId': sessionId,
  'text': text,
  if (images != null && images.isNotEmpty) 'images': images,
  if (quotes.isNotEmpty) 'quotes': [for (final q in quotes.take(maxQuotes)) q.toJson()],
  'clientId': ?clientId,
};

// G42.1: the same events give the same chat items in the app as in the page. The vectors are the
// page's own `buildItems` (packages/web/src/state.ts) run on the demo conversation and on small
// cases (tool/items_fixtures.mjs → test/fixtures/items_vectors.json), widgets after their answer
// included (3.8.7).
import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:rgcompanion/api/conversation.dart';

/// What both sides must agree on, item by item, in the page's terms.
Map<String, Object?> _web(Map<String, dynamic> i) {
  final kind = i['kind'] as String;
  Map<String, Object?> out = {'kind': kind, 'key': i['key']};
  switch (kind) {
    case 'user':
      out = {
        ...out,
        'text': i['text'],
        'images': (i['images'] as List).length,
        'from': i['from'],
        'quotes': [for (final q in (i['quotes'] as List? ?? const [])) (q as Map)['text']],
        'via': i['via'],
      };
    case 'assistant':
      final parts = (i['parts'] as List).cast<Map<String, dynamic>>();
      String join(String type) => parts
          .where((p) => p['type'] == type)
          .map((p) => p['text'] as String? ?? '')
          .where((t) => t.isNotEmpty)
          .join('\n\n')
          .trim();
      out = {
        ...out,
        'seq': i['seq'],
        'text': join('text'),
        'thinking': join('thinking'),
        'stopReason': i['stopReason'],
        'imported': i['imported'] == true,
        'stepLimit': i['stepLimit'] == true,
      };
    case 'tool':
      final r = i['result'] as Map<String, dynamic>?;
      out = {
        ...out,
        'callId': i['callId'],
        'tool': i['tool'],
        'input': i['input'],
        'ok': r?['ok'],
        'output': r?['output'],
        'images': (r?['images'] as List?)?.length ?? 0,
        'viaScript': i['viaScript'] == true,
      };
    case 'question':
      out = {
        ...out,
        'requestId': i['requestId'],
        'questions': i['questions'],
        'plan': i['plan'],
        'answered': i.containsKey('answers'),
        'answers': i['answers'],
      };
    case 'notice':
      out = {...out, 'tone': i['tone'], 'text': i['text']};
    case 'products':
      out = {...out, 'title': i['title'], 'count': (i['products'] as List).length};
    default:
      out = {...i, 'key': i['key']};
  }
  return out;
}

Map<String, Object?> _app(ChatItem it, String toolNoResult, String Function(NoticeItem) notice) {
  final j = it.toJson();
  return switch (it) {
    UserItem() => {
      'kind': 'user',
      'key': it.key,
      'text': it.text,
      'images': it.imageParts.length,
      'from': it.from,
      'quotes': [for (final q in it.quotes) q.text],
      'via': it.via,
    },
    AssistantItem() => {
      'kind': 'assistant',
      'key': it.key,
      'seq': it.seq,
      'text': it.text,
      'thinking': it.thinking,
      'stopReason': it.stopReason,
      'imported': it.imported,
      'stepLimit': it.stepLimit,
    },
    ToolItem() => {
      'kind': 'tool',
      'key': it.key,
      'callId': it.callId,
      'tool': it.tool,
      'input': it.input,
      'ok': it.ok,
      'output': it.lost ? toolNoResult : it.output,
      'images': it.images.length,
      'viaScript': it.viaScript,
    },
    QuestionItem() => {
      'kind': 'question',
      'key': it.key,
      'requestId': it.requestId,
      'questions': j['questions'],
      'plan': it.plan,
      'answered': it.answered,
      'answers': it.answers,
    },
    NoticeItem() => {'kind': 'notice', 'key': it.key, 'tone': it.level.name, 'text': notice(it)},
    ProductsItem() => {
      'kind': 'products',
      'key': it.key,
      'title': it.title,
      'count': it.products.length,
    },
    _ => j,
  };
}

/// JSON round trip, so maps and lists compare by value.
Object? _norm(Object? o) => jsonDecode(jsonEncode(o));

void main() {
  final file = File('test/fixtures/items_vectors.json');
  final vectors = jsonDecode(file.readAsStringSync()) as Map<String, dynamic>;
  // The page's words for what it says with t() (Italian, as the vectors were made).
  final words = (vectors['words'] as Map<String, dynamic>?) ?? const {};
  final toolNoResult = words['toolNoResult'] as String? ?? '';

  void check(String name, List<dynamic> events, List<dynamic> items) {
    test(name, () {
      final app = buildItems([
        for (final e in events.cast<Map<String, dynamic>>()) RgEvent.fromJson(e),
      ]);
      final web = [for (final i in items.cast<Map<String, dynamic>>()) _web(i)];
      // Notices the page says in words keep the page's text in the vectors.
      final webText = {for (final i in web) i['key']: i['text']};
      final mine = [
        for (final i in app)
          _app(i, toolNoResult, (n) => n.code == null ? n.text : '${webText[n.key]}'),
      ];
      expect(
        mine.map((i) => '${i['kind']} ${i['key']}').toList(),
        web.map((i) => '${i['kind']} ${i['key']}').toList(),
      );
      for (final (k, w) in web.indexed) {
        expect(_norm(mine[k]), _norm(w), reason: '${w['kind']} ${w['key']}');
      }
    });
  }

  check('the demo conversation', vectors['events'] as List, vectors['items'] as List);
  if (vectors['fork'] case {'events': final List<dynamic> e, 'items': final List<dynamic> i}) {
    check('its copy (fork)', e, i);
  }
  for (final c in (vectors['cases'] as List? ?? const []).cast<Map<String, dynamic>>()) {
    check(c['name'] as String, c['events'] as List, c['items'] as List);
  }
}

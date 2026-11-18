// The fake Rasgeth's automations (G42.9), answering as `packages/server/src/app.ts` and
// `@redgiant/automations` do: a recipe arrives as YAML and is read (zod's defaults filled in:
// description, agent, project, session, timeout, missed, approve, overlap, notify, webhook,
// startup, handle, files' path, match) and checked with the same rules (a name of lowercase
// letters, digits and dashes; something that starts it; cron or at, not both; events need the
// webhook; instructions or a reminder, one of the two; files need a project); the webhook's secret
// is answered only when made; runs, «run now», the preview with the next times from the
// service's fake clock (`now`, `tick`), magic automations (a test makes God propose with
// [propose]), mailboxes. Every change says `automations.changed` on the live sockets.
import 'dart:convert';
import 'dart:io';

import 'package:yaml/yaml.dart';

Object? _plain(Object? y) {
  if (y is YamlMap) return {for (final e in y.entries) '${e.key}': _plain(e.value)};
  if (y is YamlList) return [for (final v in y) _plain(v)];
  return y;
}

class RecipeError implements Exception {
  RecipeError(this.message);

  final String message;
}

class FakeAutomations {
  FakeAutomations({required this.broadcast});

  /// Sends a message to every live socket of the person.
  final void Function(Map<String, Object?> m) broadcast;

  /// The service's clock (as `now` in AutomationService's options): moved by [tick].
  DateTime now = DateTime.utc(2026, 11, 18, 7, 30);
  void tick(Duration d) => now = now.add(d);

  final list = <Map<String, dynamic>>[];
  final runs = <String, List<Map<String, dynamic>>>{};
  final magic = <Map<String, dynamic>>[];
  final boxes = <Map<String, dynamic>>[];
  final yamls = <String>[];
  final repoHooks = <Map<String, dynamic>>[];
  final previews = <String>[];

  /// The next save fails with this (the server's 400), once.
  String? refuseNext;

  /// Every route answers 403 (a device that may not change automations).
  bool forbidden = false;
  int _n = 0;

  String _iso(DateTime d) => d.toUtc().toIso8601String().replaceFirst(RegExp(r'\.\d+Z$'), '.000Z');

  void _changed(String id) => broadcast({'type': 'automations.changed', 'automationId': id});

  /// The recipe a YAML says, read and checked as the server does.
  Map<String, dynamic> read(String yaml) {
    final Object? doc;
    try {
      doc = _plain(loadYaml(yaml));
    } on YamlException catch (e) {
      throw RecipeError('Invalid YAML: ${e.message}');
    }
    if (doc is! Map<String, dynamic>) throw RecipeError('The recipe must be a YAML object');
    final r = {...doc};
    final name = r['name'];
    if (name is! String || !RegExp(r'^[a-z0-9][a-z0-9-]{0,62}$').hasMatch(name)) {
      throw RecipeError('name: lowercase letters, digits and dashes');
    }
    final on = r['on'] is Map<String, dynamic> ? {...r['on'] as Map<String, dynamic>} : null;
    if (on == null) throw RecipeError('on: Required');
    on['webhook'] ??= false;
    on['startup'] ??= false;
    if (on['message'] is Map<String, dynamic>) {
      on['message'] = {'handle': false, ...on['message'] as Map<String, dynamic>};
    }
    if (on['files'] is Map<String, dynamic>) {
      on['files'] = {'path': '.', ...on['files'] as Map<String, dynamic>};
    }
    final starts =
        ['cron', 'at', 'email', 'message', 'files', 'after', 'task'].any((k) => on[k] != null) ||
        on['webhook'] == true ||
        on['startup'] == true;
    if (!starts) {
      throw RecipeError(
        'on: set a cron expression, a date (at), a webhook, an email, a chat message, files, '
        'another automation, a task or startup',
      );
    }
    if (on['events'] != null && on['webhook'] != true)
      throw RecipeError('on: events need webhook: true');
    if (on['cron'] != null && on['at'] != null) throw RecipeError('on: cron or at, not both');
    if (on['cron'] is String && _cron(on['cron'] as String) == null) {
      throw RecipeError('on.cron: Invalid cron expression');
    }
    if ((r['instructions'] == null) == (r['reminder'] == null)) {
      throw RecipeError(
        'instructions: set instructions (for an agent) or reminder (a message), one of the two',
      );
    }
    final files = on['files'];
    if (files is Map && files['project'] == null && r['project'] == null) {
      throw RecipeError('project: files need a project (the folder is inside it)');
    }
    r['on'] = on;
    r['description'] ??= '';
    r['agent'] ??= 'god';
    r.putIfAbsent('project', () => null);
    r['session'] ??= 'new';
    r['timeoutMinutes'] ??= 30;
    r['missed'] ??= 'skip';
    r['approve'] ??= false;
    r['overlap'] ??= 'skip';
    r['notify'] = {'when': 'always', ...?(r['notify'] as Map<String, dynamic>?)};
    if (r['only'] is Map<String, dynamic>) {
      r['only'] = {'match': 'any', ...r['only'] as Map<String, dynamic>};
    }
    return r;
  }

  /// The next [count] times of a recipe after [now] (UTC, as the fake reads them).
  List<DateTime> next(Map<String, dynamic> recipe, [int count = 5]) {
    final on = recipe['on'] as Map<String, dynamic>;
    final at = on['at'];
    if (at is String) {
      final d = DateTime.tryParse(at.endsWith('Z') ? at : '${at}Z');
      return d != null && d.isAfter(now) ? [d] : const [];
    }
    final cron = on['cron'];
    if (cron is! String) return const [];
    final c = _cron(cron);
    if (c == null) return const [];
    final out = <DateTime>[];
    var t = DateTime.utc(
      now.year,
      now.month,
      now.day,
      now.hour,
      now.minute,
    ).add(const Duration(minutes: 1));
    for (var i = 0; i < 60 * 24 * 400 && out.length < count; i++) {
      if (c[0].contains(t.minute) &&
          c[1].contains(t.hour) &&
          c[2].contains(t.day) &&
          c[3].contains(t.month) &&
          c[4].contains(t.weekday % 7)) {
        out.add(t);
      }
      t = t.add(const Duration(minutes: 1));
    }
    return out;
  }

  static List<Set<int>>? _cron(String cron) {
    final f = cron.trim().split(RegExp(r'\s+'));
    if (f.length != 5) return null;
    const ranges = [(0, 59), (0, 23), (1, 31), (1, 12), (0, 6)];
    final out = <Set<int>>[];
    for (final (i, field) in f.indexed) {
      final (lo, hi) = ranges[i];
      final set = <int>{};
      for (final part in field.split(',')) {
        final m = RegExp(r'^(\*|\d+)(?:-(\d+))?(?:/(\d+))?$').firstMatch(part);
        if (m == null) return null;
        final a = m.group(1) == '*' ? lo : int.parse(m.group(1)!);
        final b = m.group(2) != null ? int.parse(m.group(2)!) : (m.group(1) == '*' ? hi : a);
        final step = m.group(3) != null ? int.parse(m.group(3)!) : 1;
        if (a < lo || b > hi || step < 1) return null;
        for (var v = a; v <= b; v += step) {
          set.add(v);
        }
      }
      out.add(set);
    }
    return out;
  }

  Map<String, dynamic> _row(String id, String yaml, Map<String, dynamic> recipe, bool enabled) {
    final n = enabled ? next(recipe, 1) : const <DateTime>[];
    final last = runs[id]?.firstOrNull;
    return {
      'id': id,
      'ownerId': 'local',
      'name': recipe['name'],
      'yaml': yaml,
      'recipe': recipe,
      'enabled': enabled,
      'hasWebhookSecret': (recipe['on'] as Map)['webhook'] == true,
      'nextRunAt': n.isEmpty ? null : _iso(n.first),
      'lastRun': last,
      'createdAt': '2026-11-10T09:00:00.000Z',
      'updatedAt': _iso(now),
    };
  }

  /// An automation for a test, from its YAML (read as the server would).
  Map<String, dynamic> add(String yaml, {bool enabled = true, String? id}) {
    final recipe = read(yaml);
    final n = ++_n;
    final a = _row(id ?? 'au$n', yaml, recipe, enabled);
    list.add(a);
    return a;
  }

  /// A run for a test (newest first).
  void addRun(String id, Map<String, dynamic> run) {
    runs.putIfAbsent(id, () => []).insert(0, {
      'id': 'run${++_n}',
      'automationId': id,
      'trigger': 'cron',
      'status': 'ok',
      'sessionId': null,
      'summary': '',
      'startedAt': _iso(now),
      'finishedAt': _iso(now.add(const Duration(seconds: 14))),
      'delivery': null,
      ...run,
    });
    _refresh(id);
  }

  void _refresh(String id) {
    final i = list.indexWhere((a) => a['id'] == id);
    if (i < 0) return;
    final a = list[i];
    list[i] = _row(
      id,
      a['yaml'] as String,
      a['recipe'] as Map<String, dynamic>,
      a['enabled'] == true,
    );
  }

  /// God proposes a recipe in a magic automation (as `propose_automation` does).
  void propose(
    String id,
    String yaml, {
    String summary = '',
    List<Map<String, dynamic>> needs = const [],
  }) {
    final m = magic.firstWhere((x) => x['id'] == id);
    m['status'] = 'ready';
    m['proposal'] = {
      'yaml': yaml,
      'recipe': read(yaml),
      'summary': summary,
      'needs': needs,
      'at': _iso(now),
    };
    _changed(id);
  }

  Future<Map<String, dynamic>> _body(HttpRequest r) async {
    final s = await utf8.decodeStream(r);
    if (s.isEmpty) return {};
    final b = jsonDecode(s);
    return b is Map<String, dynamic> ? b : {};
  }

  Map<String, dynamic> _save(String yaml, {String? id}) {
    if (refuseNext case final why?) {
      refuseNext = null;
      throw RecipeError(why);
    }
    final recipe = read(yaml);
    yamls.add(yaml);
    final at = id == null ? -1 : list.indexWhere((a) => a['id'] == id);
    final aid = id ?? 'au${++_n}';
    final enabled = at < 0 || list[at]['enabled'] == true;
    final row = _row(aid, yaml, recipe, enabled);
    final hook = (recipe['on'] as Map)['webhook'] == true;
    final hadHook = at >= 0 && list[at]['hasWebhookSecret'] == true;
    if (at < 0) {
      list.add(row);
    } else {
      list[at] = row;
    }
    _changed(aid);
    return {'automation': row, if (hook && !hadHook) 'webhookSecret': 'rgwh_${aid}_secret'};
  }

  Future<bool> handle(
    HttpRequest r,
    String path,
    Future<void> Function(int status, Object body) json,
  ) async {
    final m = r.method;
    if (!path.startsWith('/api/automations') &&
        !path.startsWith('/api/magic') &&
        path != '/api/settings/mailboxes') {
      return false;
    }
    if (path.startsWith('/api/magic-ext')) return false;
    if (forbidden && m != 'GET') {
      await json(403, {'error': 'Only the person may change automations'});
      return true;
    }
    if (m == 'GET' && path == '/api/settings/mailboxes') {
      await json(200, {
        'boxes': boxes,
        'categories': ['work', 'personal', 'social', 'other'],
      });
      return true;
    }
    if (m == 'GET' && path == '/api/automations') {
      await json(200, list);
      return true;
    }
    if (m == 'POST' && path == '/api/automations/preview') {
      final b = await _body(r);
      final yaml = b['yaml'] as String? ?? '';
      previews.add(yaml);
      try {
        final recipe = read(yaml);
        await json(200, {
          'recipe': recipe,
          'error': null,
          'next': [for (final d in next(recipe, (b['count'] as num?)?.toInt() ?? 5)) _iso(d)],
        });
      } on RecipeError catch (e) {
        await json(200, {'recipe': null, 'error': e.message, 'next': <String>[]});
      }
      return true;
    }
    if (m == 'POST' && path == '/api/automations') {
      try {
        await json(201, _save((await _body(r))['yaml'] as String? ?? ''));
      } on RecipeError catch (e) {
        await json(400, {'error': e.message});
      }
      return true;
    }
    final one = RegExp(r'^/api/automations/([^/]+)(?:/([a-z-]+))?$').firstMatch(path);
    if (one != null) {
      final id = Uri.decodeComponent(one.group(1)!);
      final what = one.group(2);
      final i = list.indexWhere((a) => a['id'] == id);
      if (i < 0) {
        await json(404, {'error': 'Automation "$id" not found'});
        return true;
      }
      switch ((m, what)) {
        case ('PUT', null):
          try {
            await json(200, _save((await _body(r))['yaml'] as String? ?? '', id: id));
          } on RecipeError catch (e) {
            await json(400, {'error': e.message});
          }
        case ('DELETE', null):
          list.removeAt(i);
          _changed(id);
          await json(200, {'ok': true});
        case ('POST', 'enabled'):
          final on = (await _body(r))['enabled'] == true;
          list[i] = _row(
            id,
            list[i]['yaml'] as String,
            list[i]['recipe'] as Map<String, dynamic>,
            on,
          );
          _changed(id);
          await json(200, list[i]);
        case ('POST', 'run'):
          final run = {
            'id': 'run${++_n}',
            'automationId': id,
            'trigger': 'manual',
            'status': 'running',
            'sessionId': 'sess_run$_n',
            'summary': '',
            'startedAt': _iso(now),
            'finishedAt': null,
            'delivery': null,
          };
          runs.putIfAbsent(id, () => []).insert(0, run);
          _refresh(id);
          _changed(id);
          await json(202, run);
        case ('POST', 'secret'):
          _changed(id);
          await json(200, {'webhookSecret': 'rgwh_${id}_new${++_n}'});
        case ('GET', 'runs'):
          await json(200, runs[id] ?? const []);
        case ('POST', 'repo-hook'):
          repoHooks.add({'id': id, ...await _body(r)});
          await json(200, {'ok': true});
        default:
          await json(404, {'error': 'Not found'});
      }
      return true;
    }
    if (m == 'GET' && path == '/api/magic') {
      await json(200, magic);
      return true;
    }
    if (m == 'POST' && path == '/api/magic') {
      final request = ((await _body(r))['request'] as String? ?? '').trim();
      if (request.isEmpty) {
        await json(400, {'error': 'Write what the automation should do'});
        return true;
      }
      final id = 'mg${++_n}';
      final row = <String, dynamic>{
        'id': id,
        'title': request.length > 60 ? '${request.substring(0, 59)}…' : request,
        'request': request,
        'sessionId': 'sess_$id',
        'agentId': 'a0',
        'status': 'building',
        'proposal': null,
        'automationId': null,
        'createdAt': _iso(now),
        'updatedAt': _iso(now),
      };
      magic.insert(0, row);
      await json(201, row);
      return true;
    }
    final mg = RegExp(r'^/api/magic/([^/]+)(?:/([a-z]+))?$').firstMatch(path);
    if (mg != null) {
      final id = mg.group(1)!;
      final row = magic.where((x) => x['id'] == id).firstOrNull;
      if (row == null) {
        await json(404, {'error': 'Magic automation "$id" not found'});
        return true;
      }
      switch ((m, mg.group(2))) {
        case ('GET', null):
          await json(200, row);
        case ('POST', 'approve'):
          final p = row['proposal'] as Map<String, dynamic>?;
          if (row['status'] != 'ready' || p == null) {
            await json(409, {'error': 'No proposal to approve'});
            return true;
          }
          final yaml = (await _body(r))['yaml'] as String? ?? p['yaml'] as String;
          try {
            final saved = _save(yaml);
            row['status'] = 'done';
            row['automationId'] = (saved['automation'] as Map)['id'];
            await json(200, {'magic': row, ...saved});
          } on RecipeError catch (e) {
            await json(400, {'error': e.message});
          }
        case ('POST', 'reject'):
          final b = await _body(r);
          row['status'] = 'building';
          row['proposal'] = null;
          row['rejected'] = b['reason'];
          await json(200, row);
        case ('DELETE', null):
          row['status'] = 'dismissed';
          await json(200, {'ok': true});
        default:
          await json(404, {'error': 'Not found'});
      }
      return true;
    }
    return false;
  }
}

// 3.9.7: Settings › Skills against an in-memory server answering as app.ts does: the installed
// skills, the agents' skills waiting (a new version with what it replaces and what it writes), a
// decision, a skill's versions, one version's SKILL.md and «go back to version N» as a new version.
import 'dart:convert';
import 'dart:io';

typedef Json = Map<String, dynamic>;

class FakeSkills {
  final calls = <String>[];
  final bodies = <String, Object?>{};
  final texts = <int, String>{
    1: '---\nname: invoice-pdf\n---\n\nThe total is on the last page.\n',
    2: '---\nname: invoice-pdf\n---\n\nThe total is on the last page, the VAT in the table above it.\n',
  };
  final versions = <Json>[
    {
      'name': 'invoice-pdf',
      'scope': 'platform',
      'version': 2,
      'how': 'update',
      'author': 'a1',
      'approvedBy': 'auto',
      'reason': 'The VAT was read from the wrong table twice.',
      'fromVersion': null,
      'createdAt': '2026-11-19T10:00:00.000Z',
      'files': <String>[],
      'restorable': true,
      'current': true,
    },
    {
      'name': 'invoice-pdf',
      'scope': 'platform',
      'version': 1,
      'how': 'install',
      'author': 'a1',
      'approvedBy': 'human',
      'reason': 'Invoices read by hand twice.',
      'fromVersion': null,
      'createdAt': '2026-11-18T10:00:00.000Z',
      'files': <String>['suppliers.md'],
      'restorable': true,
      'current': false,
    },
  ];
  final pending = <Json>[
    {
      'id': 'prop_1',
      'projectId': null,
      'kind': 'skill',
      'name': 'invoice-pdf',
      'author': 'a1',
      'status': 'pending',
      'report': [
        {'name': 'no tests', 'passed': true, 'detail': 'Not testable'},
      ],
      'input': {
        'kind': 'skill',
        'name': 'invoice-pdf',
        'description': 'Read a supplier invoice',
        'body': 'The total is on the last page; check the due date too.',
        'summary': 'The due date was missed.',
        'updates': true,
        'files': <String, String>{},
      },
      'previous': {
        'skillMd': 'The total is on the last page.',
        'files': <String>[],
        'scope': 'platform',
      },
      'proposedSkillMd': 'The total is on the last page; check the due date too.',
      'updateLine': 'Added the due date check: the due date was missed',
    },
    {
      'id': 'prop_t',
      'kind': 'tool',
      'name': 'vat-rate',
      'author': 'a1',
      'status': 'pending',
      'report': <Json>[],
      'input': {'kind': 'tool'},
    },
  ];

  Future<bool> handle(
    HttpRequest r,
    String path,
    Future<void> Function(int status, Object body) json,
  ) async {
    if (!path.startsWith('/api/extensions/')) return false;
    final m = r.method;
    calls.add('$m $path${r.uri.query.isEmpty ? '' : '?${r.uri.query}'}');
    Object? body;
    if (m == 'POST') {
      final text = await utf8.decodeStream(r);
      body = text.isEmpty ? <String, dynamic>{} : jsonDecode(text);
      bodies['$m $path'] = body;
    }
    Future<bool> ok(Object o, [int s = 200]) async {
      await json(s, o);
      return true;
    }

    if (m == 'GET' && path == '/api/extensions/installed') {
      return ok([
        {
          'kind': 'skill',
          'name': 'invoice-pdf',
          'description': 'Read a supplier invoice',
          'scope': 'platform',
          'path': 'skills/invoice-pdf/SKILL.md',
        },
        {'kind': 'tool', 'name': 'csv', 'description': 'x', 'scope': 'platform', 'path': 'x'},
      ]);
    }
    if (m == 'GET' && path == '/api/extensions/proposals') {
      return ok(r.uri.queryParameters['status'] == 'pending' ? pending : <Json>[]);
    }
    final decide = RegExp(r'^/api/extensions/proposals/([^/]+)/decision$').firstMatch(path);
    if (m == 'POST' && decide != null) {
      pending.removeWhere((p) => p['id'] == decide.group(1));
      return ok({'ok': true});
    }
    if (m == 'GET' && path == '/api/extensions/skills/invoice-pdf/versions') return ok(versions);
    final one = RegExp(r'^/api/extensions/skills/invoice-pdf/versions/(\d+)$').firstMatch(path);
    if (m == 'GET' && one != null) {
      final v = int.parse(one.group(1)!);
      return ok({'name': 'invoice-pdf', 'version': v, 'skillMd': texts[v] ?? ''});
    }
    if (m == 'POST' && path == '/api/extensions/skills/invoice-pdf/rollback') {
      final from = (body as Json)['version'] as int;
      final next = versions.length + 1;
      for (final v in versions) {
        v['current'] = false;
      }
      texts[next] = texts[from] ?? '';
      versions.insert(0, {
        ...versions.last,
        'version': next,
        'how': 'rollback',
        'author': 'human',
        'approvedBy': null,
        'reason': null,
        'fromVersion': from,
        'current': true,
      });
      return ok({'name': 'invoice-pdf', 'version': next, 'fromVersion': from});
    }
    return false;
  }
}

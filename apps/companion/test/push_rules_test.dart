// What the app shows for a notice (G40.10), as a table: Yes and No only on an ordinary request
// that offered them, never a quick yes on a critical one (whatever the notice says), the same id
// for a notice and its withdrawal, and the live notices of the computers with the server's rules.
import 'dart:convert';

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rgcompanion/api/conversation.dart';
import 'package:rgcompanion/l10n/app_localizations.dart';
import 'package:rgcompanion/push/live_notices.dart';
import 'package:rgcompanion/push/notice.dart';

PushNotice _n(Map<String, Object?> j) => PushNotice.tryParse(
  utf8.encode(jsonEncode({'v': 1, 'server': 'Casa', 'title': 't', 'body': 'b', ...j})),
)!;

PermissionRequest _perm({String tool = 'run_command', List<String> danger = const []}) =>
    PermissionRequest.fromJson({
      'requestId': 'r9',
      'agentId': 'a0',
      'agentName': 'God',
      'tool': tool,
      'input': {'command': 'npm install'},
      'reasons': <String>[],
      'danger': danger,
      'createdAt': '2026-11-16T10:00:00.000Z',
      'sessionId': 's1',
    });

void main() {
  group('planFor', () {
    final rows = <(String, Map<String, Object?>, List<QuickAnswer>, NoticeChannel)>[
      (
        'an ordinary request with both answers',
        {
          'id': 'req:r1',
          'kind': 'request',
          'requestId': 'r1',
          'actions': ['allow', 'deny'],
        },
        [QuickAnswer.allow, QuickAnswer.deny],
        NoticeChannel.requests,
      ),
      (
        'a critical request, even if the notice offered a yes',
        {
          'id': 'req:r2',
          'kind': 'request',
          'requestId': 'r2',
          'critical': true,
          'actions': ['allow', 'deny'],
        },
        [],
        NoticeChannel.requests,
      ),
      (
        'a request without answers (a capability)',
        {'id': 'req:r3', 'kind': 'request', 'requestId': 'r3', 'actions': <String>[]},
        [],
        NoticeChannel.requests,
      ),
      (
        'a no alone is never offered without a yes',
        {
          'id': 'req:r4',
          'kind': 'request',
          'requestId': 'r4',
          'actions': ['deny'],
        },
        [],
        NoticeChannel.requests,
      ),
      (
        'a request without its id',
        {
          'id': 'req:r5',
          'kind': 'request',
          'actions': ['allow', 'deny'],
        },
        [],
        NoticeChannel.requests,
      ),
      (
        'a question opens the app',
        {'id': 'req:q1', 'kind': 'question', 'requestId': 'q1'},
        [],
        NoticeChannel.requests,
      ),
      ('a task', {'id': 'task:t1', 'kind': 'task'}, [], NoticeChannel.updates),
      (
        'a message',
        {'id': 'msg:s1', 'kind': 'message', 'sessionId': 's1'},
        [],
        NoticeChannel.updates,
      ),
      ('the test', {'id': 'test:x', 'kind': 'test'}, [], NoticeChannel.updates),
    ];
    for (final (name, json, answers, channel) in rows) {
      test(name, () {
        final p = planFor(_n(json), 'srv1');
        expect(p, isA<ShowNotification>());
        final s = p as ShowNotification;
        expect(s.answers, answers);
        expect(s.channel, channel);
        expect(s.server, 'Casa');
        expect(s.id, notificationIdOf('srv1', json['id']! as String));
        final tap = NoticeTap.fromPayload(s.payload)!;
        expect(tap.serverId, 'srv1');
        expect(tap.noticeId, json['id']);
        expect(tap.requestId, json['requestId']);
        expect(tap.critical, json['critical'] == true);
      });
    }

    test('a withdrawal takes away the same notification', () {
      final shown = planFor(_n({'id': 'req:r1', 'kind': 'request', 'requestId': 'r1'}), 'srv1');
      final gone = planFor(
        _n({
          'id': 'req:r1',
          'kind': 'request',
          'requestId': 'r1',
          'closed': {'via': 'app (Pixel)'},
        }),
        'srv1',
      );
      expect(gone, isA<WithdrawNotification>());
      expect(gone.id, shown.id);
    });
  });

  test('notification ids: positive, stable, one per Rasgeth', () {
    final a = notificationIdOf('casa', 'req:r1');
    expect(a, notificationIdOf('casa', 'req:r1'));
    expect(a, greaterThanOrEqualTo(0));
    expect(a, lessThan(1 << 31));
    expect(notificationIdOf('lavoro', 'req:r1'), isNot(a));
  });

  test('notices this app does not understand are not shown', () {
    expect(PushNotice.tryParse(utf8.encode('not json')), isNull);
    expect(
      PushNotice.tryParse(utf8.encode(jsonEncode({'v': 2, 'id': 'x', 'kind': 'test'}))),
      isNull,
    );
    expect(
      PushNotice.tryParse(utf8.encode(jsonEncode({'v': 1, 'id': 'x', 'kind': 'other'}))),
      isNull,
    );
    expect(NoticeTap.fromPayload('{"s":1}'), isNull);
    expect(NoticeTap.fromPayload(null), isNull);
  });

  group('the computers\' live notices', () {
    final l = lookupAppLocalizations(const Locale('it'));
    test('an ordinary request: Yes and No, the same id as its push', () {
      final n = liveNoticeFor(_perm(), 'Casa', l);
      final p = planFor(n, 'srv1') as ShowNotification;
      expect(p.answers, [QuickAnswer.allow, QuickAnswer.deny]);
      expect(p.id, notificationIdOf('srv1', 'req:r9'));
      expect(p.title, 'God chiede il permesso');
      expect(p.body, contains('npm install'));
    });

    test('a critical request: no quick answer, the critical title', () {
      final n = liveNoticeFor(_perm(danger: ['critical-delete']), 'Casa', l);
      final p = planFor(n, 'srv1') as ShowNotification;
      expect(p.answers, isEmpty);
      expect(p.title, l.notifyCriticalTitle);
    });

    test('a canvas capability: no quick answer (its limit is chosen on its screen)', () {
      final p = planFor(liveNoticeFor(_perm(tool: kArtifactGrantTool), 'Casa', l), 'srv1');
      expect((p as ShowNotification).answers, isEmpty);
    });
  });
}

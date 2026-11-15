// The mascots never move together (the user, 2026-11-15: «they hop at exactly the same
// instant»): the app's own rhythm from the seed is the library's, the rare events come back at
// irregular times (the library's `rareStarts`, same numbers), six sleeping mascots never hop in
// the same instant, a drawing from an older server (no `--k`) still gets its own rhythm, and the
// «active» state lasts two minutes after the agent answered the person (fake clock).
import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:rgcompanion/api/conversation.dart';
import 'package:rgcompanion/api/live_model.dart';
import 'package:rgcompanion/api/types.dart';
import 'package:rgcompanion/mascot/mascot_view.dart';
import 'package:rgcompanion/mascot/motion.dart';
import 'package:rgcompanion/mascot/rhythm.dart';
import 'package:rgcompanion/mascot/svg_layers.dart';

import 'helpers.dart';

void main() {
  final vectors = (jsonDecode(File('test/fixtures/motion_vectors.json').readAsStringSync()) as List)
      .cast<Map<String, dynamic>>();
  final table = MotionTable.instance;

  MotionTrack trackOf(String key) {
    final [state, ev] = key.split(':');
    return table.states[MascotState.values.byName(state)]!.firstWhere((t) => t.rareEv == ev);
  }

  test('the rhythm from the seed is the library\'s, to the last digit', () {
    for (final v in vectors) {
      expect(rhythmOf(v['seed'] as String), (v['k'] as List).cast<num>().map((n) => n.toDouble()));
    }
  });

  test('the rare events start when the library says, at irregular times', () {
    for (final v in vectors) {
      final k = (v['k'] as List).cast<num>().map((n) => n.toDouble()).toList();
      for (final MapEntry(key: key, value: want) in (v['rare'] as Map<String, dynamic>).entries) {
        final t = trackOf(key);
        final got = t.starts(k, 0, 200);
        expect(got, (want as List).cast<num>().map((n) => n.toDouble()), reason: key);
        final gaps = [for (var i = 1; i < got.length; i++) got[i] - got[i - 1]];
        for (final g in gaps) {
          expect(g, inInclusiveRange(t.gapMin - 1e-3, t.gapMax + 1e-3), reason: key);
        }
        if (gaps.length > 3) expect(gaps.toSet().length, greaterThan(gaps.length ~/ 2));
      }
    }
  });

  test('six sleeping mascots over ten seconds never hop in the same instant', () {
    final hop = table.states[MascotState.idle]!.firstWhere(
      (t) => t.el == 'ev' && t.prop == MotionProp.translate,
    );
    final hops = <({String seed, double at})>[];
    for (final seed in ['God', 'Chat', 'Coder Web', 'Ricercatore', 'Revisore', 'Assistente mail']) {
      for (final at in hop.starts(rhythmOf(seed), 0, 10)) {
        hops.add((seed: seed, at: at));
      }
    }
    hops.sort((a, b) => a.at.compareTo(b.at));
    expect(hops.map((h) => h.seed).toSet().length, greaterThanOrEqualTo(4));
    for (var i = 1; i < hops.length; i++) {
      expect(hops[i].at - hops[i - 1].at, greaterThan(0.15), reason: '${hops[i - 1]} ${hops[i]}');
    }
    // Their body's breath is out of step too.
    final breath = table.states[MascotState.idle]!.firstWhere(
      (t) => t.el == 'core' && t.prop == MotionProp.scale,
    );
    final at3 = {
      for (final seed in ['God', 'Chat', 'Coder Web', 'Ricercatore'])
        breath.progress(3, rhythmOf(seed)).toStringAsFixed(2),
    };
    expect(at3.length, 4);
  });

  test('a hop rests between events and moves during one', () {
    final hop = table.states[MascotState.idle]!.firstWhere(
      (t) => t.el == 'ev' && t.prop == MotionProp.translate,
    );
    final k = rhythmOf('Chat');
    final s = hop.starts(k, 0, 30).first;
    expect(hop.valueAt(s - 0.05, k).y, 0);
    expect(hop.valueAt(s + 0.36, k).y, lessThan(-10));
    expect(hop.valueAt(s + hop.durMin + 0.05, k).y, 0);
  });

  test('a drawing from an older server (no rhythm) still gets the seed\'s own', () {
    final moving = MotionTable.instance.elements;
    final m = loadMascots().firstWhere((m) => m.seed == 'Ricercatore');
    final svg = m.svgOf(MascotTheme.light, MascotState.idle);
    final old = svg.replaceAll(RegExp(r';--k\d+:[\d.]+'), '');
    expect(old, isNot(contains('--k0')));
    final fromServer = splitMascotSvg(svg, moving);
    final fromOld = splitMascotSvg(old, moving);
    expect(fromOld.rhythm, isEmpty);
    // The same numbers the server would have sent.
    expect(rhythmFor(fromOld, seed: m.spec.seed), fromServer.rhythm);
    expect(rhythmFor(fromOld, seed: '', agentId: 'a1'), isNot(rhythmFor(fromOld, agentId: 'a2')));
  });

  group('active: awake for two minutes after answering the person', () {
    var clock = DateTime.utc(2026, 11, 15, 10);
    LiveModel model() => LiveModel(now: () => clock)
      ..setSessions([
        const SessionRow(id: 's1', agentId: 'a', createdAt: '2026-11-15T09:00:00Z'),
        const SessionRow(id: 's2', agentId: 'b', createdAt: '2026-11-15T09:00:00Z'),
      ]);
    // [seconds after the answer, the state]
    const table = [
      (0, MascotState.active),
      (60, MascotState.active),
      (119, MascotState.active),
      (121, MascotState.idle),
      (600, MascotState.idle),
    ];
    for (final (after, want) in table) {
      test('$after s after: ${want.name}', () {
        final m = model();
        clock = DateTime.utc(2026, 11, 15, 10);
        m.apply({
          'type': 'session.activity',
          'sessionId': 's1',
          'agentId': 'a',
          'state': 'running',
        });
        m.apply({
          'type': 'session.activity',
          'sessionId': 's1',
          'agentId': 'a',
          'state': 'idle',
          'repliedAt': '2026-11-15T10:00:00.000Z',
        });
        clock = clock.add(Duration(seconds: after));
        expect(m.mascotStateOf('a'), want);
        // Someone else's answer does not wake b.
        expect(m.mascotStateOf('b'), MascotState.idle);
        m.dispose();
      });
    }

    test('the list says it too, and a request for the person still comes first', () {
      clock = DateTime.utc(2026, 11, 15, 10, 1);
      final m = LiveModel(now: () => clock)
        ..setSessions([
          SessionRow.fromJson({
            'id': 's1',
            'agentId': 'a',
            'createdAt': '2026-11-15T09:00:00Z',
            'repliedAt': '2026-11-15T10:00:00.000Z',
          }),
        ]);
      expect(m.mascotStateOf('a'), MascotState.active);
      m.apply({
        'type': 'permission.request',
        'request': {'requestId': 'r', 'agentId': 'a', 'agentName': 'A', 'danger': <String>[]},
      });
      expect(m.mascotStateOf('a'), MascotState.wait);
      m.dispose();
    });

    test('says when to fall asleep: the mascots hear it at the end of the two minutes', () async {
      clock = DateTime.now().toUtc();
      final m = LiveModel()
        ..setSessions([
          SessionRow(
            id: 's1',
            agentId: 'a',
            createdAt: '2026-11-15T09:00:00Z',
            repliedAt: clock
                .subtract(const Duration(seconds: 119, milliseconds: 900))
                .toIso8601String(),
          ),
        ]);
      var heard = 0;
      m.addListener(() => heard++);
      expect(m.mascotStateOf('a'), MascotState.active);
      await Future<void>.delayed(const Duration(milliseconds: 400));
      expect(heard, greaterThan(0));
      expect(m.mascotStateOf('a'), MascotState.idle);
      m.dispose();
    });
  });

  test('every state has its motion, active included', () {
    for (final s in MascotState.values) {
      expect(table.states[s], isNotEmpty, reason: s.name);
    }
    expect(table.states[MascotState.active]!.map((t) => t.el), isNot(contains('z1')));
  });
}

// A sub-agent's sign instead of a mascot (decision «Mascotte solo per orchestratori e agenti di
// primo livello», 2026-11-19, board choice A): the app's painter against the library's drawing
// (`subagentSignSvg`, test/fixtures/subagent_signs.json), and MascotView showing it for a
// sub-agent wherever the app draws a mascot.
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rgcompanion/api/types.dart';
import 'package:rgcompanion/mascot/mascot_source.dart';
import 'package:rgcompanion/mascot/mascot_view.dart';
import 'package:rgcompanion/mascot/subagent_sign.dart';

import 'helpers.dart';

const _size = 96.0;

/// Share of pixels whose colour differs by more than [tolerance] (0-255 per channel).
double _diff(List<int> a, List<int> b, {int tolerance = 40}) {
  var off = 0;
  for (var i = 0; i < a.length; i += 4) {
    var d = 0;
    for (var k = 0; k < 3; k++) {
      final v = (a[i + k] - b[i + k]).abs();
      if (v > d) d = v;
    }
    if (d > tolerance) off++;
  }
  return off / (a.length / 4);
}

void main() {
  final signs = (jsonDecode(File('test/fixtures/subagent_signs.json').readAsStringSync()) as List)
      .cast<Map<String, dynamic>>();
  MascotSpec? specOf(Map<String, dynamic> s) =>
      s['spec'] == null ? null : MascotSpec.fromJson(s['spec'] as Map<String, dynamic>);
  final coder = specOf(signs.first)!;

  group('the same as the library', () {
    for (final s in signs) {
      final parent = specOf(s);
      final who = parent == null ? 'without a parent' : "in ${s['parent']}'s colour";
      for (final theme in MascotTheme.values) {
        for (final state in MascotState.values) {
          testWidgets('$who, ${state.name}, ${theme.name}', (tester) async {
            final svg = (s['svg'] as Map<String, dynamic>)[theme.name][state.name] as String;
            final bg = theme == MascotTheme.dark ? const Color(0xFF1C1F26) : Colors.white;
            await tester.pumpWidget(
              Row(
                textDirection: TextDirection.ltr,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  onCanvas(
                    key: const Key('app'),
                    bg: bg,
                    // At rest: the arc where the library starts it, every fade full.
                    CustomPaint(
                      size: const Size.square(_size),
                      painter: SubagentSignPainter(
                        colors: SubagentSignColors.of(parent, theme),
                        state: state,
                      ),
                    ),
                  ),
                  onCanvas(
                    key: const Key('lib'),
                    bg: bg,
                    SvgPicture.string(svg, width: _size, height: _size),
                  ),
                ],
              ),
            );
            await settleSvgs(tester);
            final app = await pixelsOf(tester, const Key('app'));
            final lib = await pixelsOf(tester, const Key('lib'));
            expect(app.width, lib.width);
            final d = _diff(app.rgba, lib.rgba);
            expect(d, lessThan(.01), reason: 'diff $d');
          });
        }
      }
    }

    test("the ring is the parent's body colour, the theme's grey without one", () {
      expect(SubagentSignColors.of(coder, MascotTheme.dark).ring, hexColor(coder.dark.body));
      expect(SubagentSignColors.of(null, MascotTheme.light).ring, const Color(0xFF6B7385));
    });
  });

  group('in MascotView', () {
    final agents = {
      for (final j in [
        {
          'id': 'coder',
          'kind': 'agent',
          'parentId': 'orch',
          'name': 'Coder Web',
          'mascot': signs.first['spec'],
        },
        {'id': 'sub', 'kind': 'subagent', 'parentId': 'coder', 'name': 'Test UI'},
        {'id': 'lost', 'kind': 'subagent', 'parentId': 'gone', 'name': 'Orphan'},
      ])
        j['id'] as String: Agent.fromJson(j),
    };
    Widget scoped(Widget child) => MascotScope(agentOf: (id) => agents[id], child: onCanvas(child));

    testWidgets("a sub-agent shows the ring in its parent's colour, named", (tester) async {
      await tester.pumpWidget(
        scoped(
          const MascotView(
            agentId: 'sub',
            state: MascotState.work,
            size: 20,
            label: 'Test UI',
            animate: false,
          ),
        ),
      );
      final sign = tester.widget<SubagentSign>(find.byType(SubagentSign));
      expect(sign.parent?.seed, coder.seed);
      expect(sign.state, MascotState.work);
      expect(sign.size, 20);
      expect(find.bySemanticsLabel('Test UI'), findsOneWidget);
    });

    testWidgets('grey without a known parent; an agent keeps its face', (tester) async {
      await tester.pumpWidget(scoped(const MascotView(agentId: 'lost', animate: false)));
      expect(tester.widget<SubagentSign>(find.byType(SubagentSign)).parent, isNull);
      await tester.pumpWidget(scoped(const MascotView(agentId: 'coder', animate: false)));
      expect(find.byType(SubagentSign), findsNothing);
    });

    testWidgets('with reduced motion nothing moves; working, it asks for frames', (tester) async {
      await tester.pumpWidget(
        scoped(const MascotView(agentId: 'sub', state: MascotState.work, animate: false)),
      );
      await tester.pump();
      expect(tester.binding.hasScheduledFrame, isFalse);
      await tester.pumpWidget(scoped(const MascotView(agentId: 'sub', state: MascotState.work)));
      expect(tester.binding.hasScheduledFrame, isTrue);
      // Asleep it is still: no clock for it.
      await tester.pumpWidget(scoped(const MascotView(agentId: 'sub')));
      await tester.pump();
      expect(tester.binding.hasScheduledFrame, isFalse);
    });

    test("the page's fade: full, 0.3 at half the period, full again", () {
      expect(SubagentSignPainter.fade(null, 1.4), 1);
      expect(SubagentSignPainter.fade(0, 1.4), closeTo(1, 1e-9));
      expect(SubagentSignPainter.fade(.7, 1.4), closeTo(.3, 1e-9));
      expect(SubagentSignPainter.fade(1.4, 1.4), closeTo(1, 1e-9));
    });
  });
}

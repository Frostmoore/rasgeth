// The mascots as the app draws them, against the library that makes them (`@redgiant/mascot`,
// the fixtures in test/fixtures/mascots.json): goldens of a few faces, and a parity check that the
// app's layered drawing matches the library's whole SVG (same colours and shapes, within limits).
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rgcompanion/api/types.dart';
import 'package:rgcompanion/mascot/marks_painter.dart';
import 'package:rgcompanion/mascot/mascot_view.dart';
import 'package:rgcompanion/mascot/motion.dart';
import 'package:rgcompanion/mascot/svg_layers.dart';

import 'helpers.dart';

const _size = 128.0;

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
  final mascots = loadMascots();
  MascotFixture byKind(String kind) => mascots.firstWhere((m) => m.kind == kind);

  group('the fixtures come from the library', () {
    test('every kind is there, with a spec the app reads', () {
      expect(mascots.map((m) => m.kind).toSet(), {
        'god',
        'demigod',
        'orchestrator',
        'agent',
        'assistant',
        'inspector',
        'subagent',
      });
      for (final m in mascots) {
        expect(m.spec.v, 1);
        expect(m.spec.kind.name, m.kind);
        expect(m.spec.bodyPath, startsWith('M'));
        expect(m.spec.light.body, matches(RegExp(r'^#[0-9a-f]{6}$')));
      }
    });

    test('a subagent looks like its parent: same body and hue', () {
      final parent = mascots.firstWhere((m) => m.seed == 'Coder Web');
      final sub = byKind('subagent');
      expect(sub.raw['body'], parent.raw['body']);
      expect(sub.spec.hue, parent.spec.hue);
    });
  });

  group('layers', () {
    test('the sign is cut out; the tool keeps its place and its turning point', () {
      final agent = byKind('agent');
      final svg = agent.svgOf(MascotTheme.light, MascotState.work);
      final l = splitMascotSvg(svg);
      expect(svg, contains('class="mk work"'));
      expect(l.base, isNot(contains('class="mk')));
      expect(l.base, isNot(contains('class="tool"')));
      expect(l.tool, contains('class="tool"'));
      expect(l.toolOrigin, isNotNull);
      expect(l.base.split('<g').length, l.base.split('</g>').length);
    });

    test("a subagent's tool stays inside its parent's scale", () {
      final l = splitMascotSvg(byKind('subagent').svgOf(MascotTheme.light, MascotState.work));
      expect(l.tool, contains('<g transform="translate(10 18) scale(.8)">'));
    });

    test("the orchestrator's headset is a layer of its own", () {
      final l = splitMascotSvg(byKind('orchestrator').svgOf(MascotTheme.dark, MascotState.work));
      expect(l.headset, contains('class="hs"'));
      expect(l.base, isNot(contains('class="hs"')));
    });

    test('God has no tool and keeps its gradients', () {
      final l = splitMascotSvg(byKind('god').svgOf(MascotTheme.light, MascotState.idle));
      expect(l.tool, isNull);
      expect(l.base, contains('radialGradient'));
    });
  });

  group('motion, as the page CSS', () {
    test('idle breathes, work sways, wait hops, think and error keep the body still', () {
      expect(coreMotion(MascotState.idle, 1.8).scaleY, closeTo(1.03, 1e-9));
      expect(coreMotion(MascotState.work, .4).rotate, lessThan(0));
      expect(coreMotion(MascotState.wait, 3 * .86).dy, closeTo(-6, 1e-9));
      expect(coreMotion(MascotState.wait, 1).isStill, isTrue);
      expect(coreMotion(MascotState.think, 1).isStill, isTrue);
      expect(coreMotion(MascotState.error, 1).isStill, isTrue);
    });

    test('the thinking dots go from .3 to 1 and back', () {
      expect(thinkDotOpacity(0), closeTo(.3, 1e-9));
      expect(thinkDotOpacity(.35), closeTo(1, 1e-9));
      expect(thinkDotOpacity(1), closeTo(.3, 1e-9));
    });
  });

  group('drawing', () {
    testWidgets('with reduced motion nothing moves (no frames asked)', (tester) async {
      final m = byKind('agent');
      await tester.pumpWidget(
        MediaQuery(
          data: const MediaQueryData(disableAnimations: true),
          child: onCanvas(
            MascotView(
              svg: m.svgOf(MascotTheme.light, MascotState.work),
              state: MascotState.work,
              theme: MascotTheme.light,
              size: _size,
            ),
          ),
        ),
      );
      await settleSvgs(tester);
      expect(tester.binding.hasScheduledFrame, isFalse);
    });

    testWidgets('moving, it asks for frames', (tester) async {
      final m = byKind('agent');
      await tester.pumpWidget(
        onCanvas(
          MascotView(
            svg: m.svgOf(MascotTheme.light, MascotState.idle),
            theme: MascotTheme.light,
            size: _size,
          ),
        ),
      );
      expect(tester.binding.hasScheduledFrame, isTrue);
    });

    testWidgets('it says who and what, in words', (tester) async {
      await tester.pumpWidget(
        onCanvas(
          MascotView(
            spec: byKind('agent').spec,
            label: 'Mascot of Coder Web, working',
            animate: false,
            size: 64,
          ),
        ),
      );
      expect(find.bySemanticsLabel('Mascot of Coder Web, working'), findsOneWidget);
    });

    for (final theme in MascotTheme.values) {
      for (final m in mascots) {
        for (final state in MascotState.values) {
          testWidgets('${m.seed} ${state.name} ${theme.name}: the same as the library', (
            tester,
          ) async {
            final svg = m.svgOf(theme, state);
            final bg = theme == MascotTheme.dark ? const Color(0xFF1C1F26) : Colors.white;
            await tester.pumpWidget(
              Row(
                textDirection: TextDirection.ltr,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  onCanvas(
                    key: const Key('app'),
                    bg: bg,
                    MascotView(svg: svg, state: state, theme: theme, size: _size, animate: false),
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
            // Something was drawn: a good share of the box is not the background.
            final drawn = _diff(app.rgba, [
              for (var i = 0; i < app.rgba.length; i += 4) ...[
                (bg.r * 255).round(),
                (bg.g * 255).round(),
                (bg.b * 255).round(),
                255,
              ],
            ], tolerance: 10);
            expect(drawn, greaterThan(.15));
            // The sign is painted by the app with the library's shapes: edges may differ a little.
            expect(_diff(app.rgba, lib.rgba), lessThan(.004));
            if (state == MascotState.idle && theme == MascotTheme.light) {
              await expectLater(
                find.byKey(const Key('app')),
                matchesGoldenFile('goldens/${m.slug}-${state.name}-${theme.name}.png'),
              );
            }
          });
        }
      }
    }

    testWidgets("the spec's own drawing has the library's body colour", (tester) async {
      final m = byKind('agent');
      await tester.pumpWidget(
        onCanvas(MascotView(spec: m.spec, theme: MascotTheme.light, size: 100, animate: false)),
      );
      final px = await pixelsOf(tester, const Key('canvas'));
      // The body's middle (50,70 of the box) is the body colour, as in the library's SVG.
      final i = (70 * px.width + 50) * 4;
      final body = hexColor(m.spec.light.body);
      expect(px.rgba[i], closeTo((body.r * 255).round(), 2));
      expect(px.rgba[i + 1], closeTo((body.g * 255).round(), 2));
      expect(px.rgba[i + 2], closeTo((body.b * 255).round(), 2));
    });

    test('the sign uses the library colours of each theme', () {
      expect(MarkColors.light.accent, const Color(0xFFD23A2C));
      expect(MarkColors.dark.accent, const Color(0xFFEF4B3A));
    });
  });
}

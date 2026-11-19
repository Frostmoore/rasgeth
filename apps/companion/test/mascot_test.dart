// The mascots as the app draws them, against the library that makes them (`@redgiant/mascot`,
// the fixtures in test/fixtures/mascots.json): goldens of a few faces, and a parity check that the
// app's layered drawing matches the library's whole SVG (same colours and shapes, within limits).
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rgcompanion/api/types.dart';
import 'package:rgcompanion/mascot/clock.dart';
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

/// The drawing without its hidden groups (none of them has groups inside).
String _withoutHidden(String svg) =>
    svg.replaceAll(RegExp(r'<g class="[^"]*" opacity="0"[^>]*>.*?</g>'), '');

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
    final moving = MotionTable.instance.elements;
    test('every moving group is a layer of its own, in drawing order, with its rhythm', () {
      final svg = byKind('agent').svgOf(MascotTheme.light, MascotState.work);
      final l = splitMascotSvg(svg, moving);
      final els = [for (final x in l.layers) ?x.el];
      expect(els, containsAllInOrder(['eyes', 'mouth', 'hand', 'tool', 'spk', 'w1', 'w2']));
      expect(l.rhythm, hasLength(16));
      expect(l.coreOrigin, const Offset(50, 90));
      final tool = l.layers.firstWhere((x) => x.el == 'tool');
      expect(tool.svg, contains('class="tool"'));
      expect(tool.inCore, isTrue);
      expect(l.layers.firstWhere((x) => x.el == 'w1').inCore, isFalse);
      // Sparks appear only while moving.
      expect(l.layers.firstWhere((x) => x.el == 'spk').restOpacity, 0);
      for (final x in l.layers) {
        expect(x.svg.split('<g').length, x.svg.split('</g>').length, reason: x.svg);
        expect(x.svg, isNot(contains('class="core"')));
      }
    });

    test("a subagent's moving parts stay inside its parent's scale", () {
      final l = splitMascotSvg(
        byKind('subagent').svgOf(MascotTheme.light, MascotState.work),
        moving,
      );
      final tool = l.layers.firstWhere((x) => x.el == 'tool');
      expect(tool.svg, contains('<g transform="translate(10 18) scale(.8)">'));
      expect(tool.parent!.entry(0, 0), closeTo(.8, 1e-9));
    });

    test('God keeps its gradients, its orbit with three companion stars, its halo and its glint', () {
      final l = splitMascotSvg(byKind('god').svgOf(MascotTheme.light, MascotState.idle), moving);
      final els = {for (final x in l.layers) ?x.el};
      expect(
        els,
        containsAll(['hal', 'orbb', 'orbf', 'orbb2', 'orbf2', 'orbb3', 'orbf3', 'gl', 'eyes', 'eyw']),
      );
      expect(els, containsAll(['bub', 'z1']));
      expect(l.layers.every((x) => x.svg.contains('radialGradient')), isTrue);
      // Each companion turns around its own rest place; all three show without motion.
      final f3 = l.layers.firstWhere((x) => x.el == 'orbf3');
      expect(f3.origin.dx, greaterThan(70));
      expect(l.layers.firstWhere((x) => x.el == 'orbb2').restOpacity, 1);
    });

    test("the Demigod is God's drawing at 0.85: its moving parts stay inside that scale", () {
      final l = splitMascotSvg(
        byKind('demigod').svgOf(MascotTheme.light, MascotState.active),
        moving,
      );
      final eyes = l.layers.firstWhere((x) => x.el == 'eyes');
      expect(eyes.parent!.entry(0, 0), closeTo(.85, 1e-9));
      expect(l.layers.where((x) => x.el?.startsWith('orb') ?? false), isEmpty);
    });

    test('at 32 px God and the Demigod keep only body, face and crown (diadem)', () {
      for (final kind in ['god', 'demigod']) {
        final l = splitMascotSvg(byKind(kind).compact, moving);
        final els = {for (final x in l.layers) ?x.el};
        expect(els, contains('eyes'), reason: kind);
        expect(els.intersection({'hal', 'gl', 'orbf', 'orbb', 'orbf2', 'orbb3'}), isEmpty);
        expect(byKind(kind).compact, contains('#8a5a00'), reason: kind);
      }
    });
  });

  group('motion, from the library table', () {
    final table = MotionTable.instance;
    final k = List<double>.filled(16, 0);
    test('every state moves, idle included, and tiny mascots only blink', () {
      for (final s in MascotState.values) {
        expect(table.states[s]!.map((t) => t.el), containsAll(['core', 'ev']), reason: s.name);
      }
      expect(table.tiny.map((t) => t.el).toSet(), {'eyes'});
    });

    test('idle breathes, the z rise and fade, waiting hops, as the page CSS', () {
      final breath = table.states[MascotState.idle]!.firstWhere(
        (t) => t.el == 'core' && t.prop == MotionProp.scale,
      );
      expect(breath.valueAtProgress(.5).y, closeTo(1.065, 1e-9));
      final z = table.states[MascotState.idle]!.firstWhere(
        (t) => t.el == 'z1' && t.prop == MotionProp.opacity,
      );
      expect(z.valueAtProgress(0).x, 0);
      expect(z.valueAtProgress(.12).x, 1);
      final hop = table.states[MascotState.wait]!.firstWhere(
        (t) => t.el == 'core' && t.prop == MotionProp.translate,
      );
      expect(hop.valueAtProgress(.86).y, closeTo(-9, 1e-9));
    });

    test('the rhythm sets period and phase as the CSS delay does', () {
      final blink = table.states[MascotState.idle]!.firstWhere((t) => t.el == 'eyes');
      final slow = List<double>.filled(16, 0)..[1] = 1;
      expect(blink.duration(k), closeTo(3.4, 1e-9));
      expect(blink.duration(slow), closeTo(6.2, 1e-9));
      final half = List<double>.filled(16, 0)..[2] = .5;
      expect(blink.progress(0, half), closeTo(.5, 1e-9));
      // Two mascots: the same moment, different poses.
      final a = table.poses(MascotState.idle, 10, [for (var i = 0; i < 16; i++) i / 17]);
      final b = table.poses(MascotState.idle, 10, [for (var i = 0; i < 16; i++) (i + 7) / 23]);
      expect(a['core']!.sy == b['core']!.sy && a['z1']!.dy == b['z1']!.dy, isFalse);
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
                    // The layers stacked at rest give back the library's drawing.
                    MascotLayersView(
                      layers: splitMascotSvg(svg, MotionTable.instance.elements),
                      size: _size,
                    ),
                  ),
                  onCanvas(
                    key: const Key('lib'),
                    bg: bg,
                    // Without what appears only while moving (flutter_svg would show the
                    // sleep bubble: a hidden group with its own fill-opacity).
                    SvgPicture.string(_withoutHidden(svg), width: _size, height: _size),
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
            // Layers drawn one by one: only edges may differ a little.
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

    testWidgets('moving, the drawing changes with time (a film strip of the same mascot)', (
      tester,
    ) async {
      final m = byKind('agent');
      final svg = m.svgOf(MascotTheme.light, MascotState.idle);
      await tester.pumpWidget(
        Row(
          textDirection: TextDirection.ltr,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            for (final (i, t) in [0.0, 1.2, 2.4].indexed)
              onCanvas(
                key: Key('t$i'),
                MascotView(svg: svg, theme: MascotTheme.light, size: _size, seconds: t),
              ),
          ],
        ),
      );
      await settleSvgs(tester);
      final a = await pixelsOf(tester, const Key('t0'));
      final b = await pixelsOf(tester, const Key('t1'));
      final c = await pixelsOf(tester, const Key('t2'));
      expect(_diff(a.rgba, b.rgba, tolerance: 20), greaterThan(.002));
      expect(_diff(b.rgba, c.rgba, tolerance: 20), greaterThan(.002));
    });

    testWidgets('one clock for all, paused while the app is not in front', (tester) async {
      final m = byKind('agent');
      await tester.pumpWidget(
        Row(
          textDirection: TextDirection.ltr,
          children: [
            for (final s in [MascotState.idle, MascotState.work])
              MascotView(svg: m.svgOf(MascotTheme.light, s), state: s, size: 64),
          ],
        ),
      );
      expect(MascotClock.instance.running, isTrue);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.hidden);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
      expect(MascotClock.instance.running, isFalse);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.hidden);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      expect(MascotClock.instance.running, isTrue);
      await tester.pumpWidget(const SizedBox());
      expect(MascotClock.instance.running, isFalse);
    });
  });
}

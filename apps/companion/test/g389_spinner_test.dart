// The «in progress» mark turns (3.8.9, «the circle by the commands does not turn»): RgSpinner
// rotates while a tool runs, stops when it is replaced by the done mark, and with reduced motion
// (the app's switch or the system's) shows three still dots instead of a frozen arc.
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rgcompanion/mascot/mascot_source.dart';
import 'package:rgcompanion/ui/icons.dart';

Widget _host(Widget child, {bool reduce = false, bool systemReduce = false}) => Directionality(
  textDirection: TextDirection.ltr,
  child: MediaQuery(
    data: MediaQueryData(disableAnimations: systemReduce),
    child: MascotScope(
      reduceMotion: reduce,
      child: Center(
        child: RepaintBoundary(key: const Key('frame'), child: child),
      ),
    ),
  ),
);

double _turns(WidgetTester tester) => tester
    .widget<RotationTransition>(find.byKey(const Key('spinner-turning')))
    .turns
    .value;

void main() {
  testWidgets('it turns while running and stops once replaced by the done mark', (tester) async {
    var running = true;
    late StateSetter set;
    await tester.pumpWidget(
      _host(
        StatefulBuilder(
          builder: (context, s) {
            set = s;
            return running
                ? const RgSpinner(size: 13, color: Color(0xFFE5484D))
                : const SizedBox(key: Key('tool-dot'), width: 9, height: 9);
          },
        ),
      ),
    );
    expect(find.byKey(const Key('spinner-turning')), findsOneWidget);
    final a = _turns(tester);
    await tester.pump(const Duration(milliseconds: 200));
    final b = _turns(tester);
    expect((b - a).abs(), closeTo(0.2, 0.01));
    expect(tester.binding.transientCallbackCount, greaterThan(0));

    // Two frames 200 ms apart, for a look (SPIN_FRAMES=<dir>).
    final dir = Platform.environment['SPIN_FRAMES'];
    if (dir != null) {
      for (final name in ['app-0ms', 'app-200ms']) {
        await tester.runAsync(() async {
          final box = tester.renderObject<RenderRepaintBoundary>(find.byKey(const Key('frame')));
          final img = await box.toImage(pixelRatio: 8);
          final png = await img.toByteData(format: ui.ImageByteFormat.png);
          File('$dir/$name.png').writeAsBytesSync(png!.buffer.asUint8List());
          img.dispose();
        });
        await tester.pump(const Duration(milliseconds: 200));
      }
    }

    set(() => running = false);
    await tester.pump();
    expect(find.byType(RgSpinner), findsNothing);
    expect(find.byKey(const Key('tool-dot')), findsOneWidget);
    expect(tester.binding.transientCallbackCount, 0);
  });

  for (final (name, reduce, system) in [
    ('the app\'s reduce motion', true, false),
    ('the system\'s reduce motion', false, true),
  ]) {
    testWidgets('with $name it shows three still dots', (tester) async {
      await tester.pumpWidget(_host(const RgSpinner(), reduce: reduce, systemReduce: system));
      expect(find.byKey(const Key('spinner-still')), findsOneWidget);
      expect(find.byType(RotationTransition), findsNothing);
      expect(tester.binding.transientCallbackCount, 0);
      expect(tester.widget<RgIcon>(find.byKey(const Key('spinner-still'))).icon, RgIcons.more);
    });
  }

  testWidgets('switching reduce motion on stops it, off starts it again', (tester) async {
    await tester.pumpWidget(_host(const RgSpinner()));
    expect(tester.binding.transientCallbackCount, greaterThan(0));
    await tester.pumpWidget(_host(const RgSpinner(), reduce: true));
    expect(tester.binding.transientCallbackCount, 0);
    expect(find.byKey(const Key('spinner-still')), findsOneWidget);
    await tester.pumpWidget(_host(const RgSpinner()));
    expect(find.byKey(const Key('spinner-turning')), findsOneWidget);
    expect(tester.binding.transientCallbackCount, greaterThan(0));
  });
}

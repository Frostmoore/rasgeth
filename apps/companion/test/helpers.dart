import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rgcompanion/api/types.dart';

/// One mascot made by `@redgiant/mascot` (tool/mascot_fixtures.mjs).
class MascotFixture {
  MascotFixture(Map<String, dynamic> j)
    : seed = j['seed'] as String,
      kind = j['kind'] as String,
      spec = MascotSpec.fromJson(j['spec'] as Map<String, dynamic>),
      raw = j['spec'] as Map<String, dynamic>,
      svg = (j['svg'] as Map<String, dynamic>).map(
        (theme, states) => MapEntry(theme, (states as Map<String, dynamic>).cast<String, String>()),
      ),
      tiny = j['tiny'] as String,
      compact = j['compact'] as String;

  final String seed;
  final String kind;
  final MascotSpec spec;
  final Map<String, dynamic> raw;
  final Map<String, Map<String, String>> svg;
  final String tiny;

  /// The 32 px drawing (idle, light): God and the Demigod without orbit, halo and glints.
  final String compact;

  String svgOf(MascotTheme t, MascotState s) => svg[t.name]![s.name]!;
  String get slug => seed.toLowerCase().replaceAll(' ', '-');
}

List<MascotFixture> loadMascots() {
  final list = jsonDecode(File('test/fixtures/mascots.json').readAsStringSync()) as List<dynamic>;
  return [for (final j in list) MascotFixture(j as Map<String, dynamic>)];
}

/// Lets flutter_svg finish its asynchronous parsing, then paints.
Future<void> settleSvgs(WidgetTester tester) async {
  for (var i = 0; i < 3; i++) {
    await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 20)));
    await tester.pump();
  }
}

/// The pixels (RGBA) under [key]'s RepaintBoundary.
Future<({int width, int height, Uint8List rgba})> pixelsOf(WidgetTester tester, Key key) async {
  final boundary = tester.renderObject<RenderRepaintBoundary>(find.byKey(key));
  final result = await tester.runAsync(() async {
    final image = await boundary.toImage();
    final data = await image.toByteData(format: ui.ImageByteFormat.rawRgba);
    final out = (width: image.width, height: image.height, rgba: data!.buffer.asUint8List());
    image.dispose();
    return out;
  });
  return result!;
}

Widget onCanvas(Widget child, {Key key = const Key('canvas'), Color bg = Colors.white}) =>
    Directionality(
      textDirection: TextDirection.ltr,
      child: Center(
        child: RepaintBoundary(
          key: key,
          child: ColoredBox(color: bg, child: child),
        ),
      ),
    );

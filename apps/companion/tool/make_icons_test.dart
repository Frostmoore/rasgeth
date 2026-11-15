// Draws the app's icons for every platform from assets/icon/rgcompanion.svg (the provisional icon,
// RedGiant's red giant). Run from apps/companion after changing the SVG:
//
//   flutter test tool/make_icons_test.dart
//
// iOS gets the full square (no transparency, as Apple asks); Android, macOS and Windows a rounded
// square with a margin; Windows an .ico of PNG frames.
import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/painting.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_test/flutter_test.dart';

Future<Uint8List> _png(PictureInfo pic, int size, {required bool rounded}) async {
  final rec = ui.PictureRecorder();
  final canvas = Canvas(rec);
  final s = size.toDouble();
  if (rounded) {
    // macOS-like proportions: 10% margin, 22% corner radius.
    final m = s * .1;
    final r = Rect.fromLTWH(m, m, s - 2 * m, s - 2 * m);
    canvas.clipRRect(RRect.fromRectAndRadius(r, Radius.circular(r.width * .225)));
    canvas.translate(m, m);
    canvas.scale(r.width / pic.size.width);
  } else {
    canvas.scale(s / pic.size.width);
  }
  canvas.drawPicture(pic.picture);
  final image = await rec.endRecording().toImage(size, size);
  final data = await image.toByteData(format: ui.ImageByteFormat.png);
  image.dispose();
  return data!.buffer.asUint8List();
}

Uint8List _ico(List<(int, Uint8List)> frames) {
  final b = BytesBuilder();
  final head = ByteData(6)
    ..setUint16(0, 0, Endian.little)
    ..setUint16(2, 1, Endian.little)
    ..setUint16(4, frames.length, Endian.little);
  b.add(head.buffer.asUint8List());
  var offset = 6 + 16 * frames.length;
  for (final (size, png) in frames) {
    final e = ByteData(16)
      ..setUint8(0, size >= 256 ? 0 : size)
      ..setUint8(1, size >= 256 ? 0 : size)
      ..setUint16(4, 1, Endian.little)
      ..setUint16(6, 32, Endian.little)
      ..setUint32(8, png.length, Endian.little)
      ..setUint32(12, offset, Endian.little);
    b.add(e.buffer.asUint8List());
    offset += png.length;
  }
  for (final (_, png) in frames) {
    b.add(png);
  }
  return b.toBytes();
}

void main() {
  test('make the icons', () async {
    final svg = File('assets/icon/rgcompanion.svg').readAsStringSync();
    final pic = await vg.loadPicture(SvgStringLoader(svg), null);
    Future<void> write(String path, int size, {bool rounded = true}) async =>
        File(path).writeAsBytesSync(await _png(pic, size, rounded: rounded));

    const android = {'mdpi': 48, 'hdpi': 72, 'xhdpi': 96, 'xxhdpi': 144, 'xxxhdpi': 192};
    for (final MapEntry(key: d, value: s) in android.entries) {
      await write('android/app/src/main/res/mipmap-$d/ic_launcher.png', s);
    }
    const ios = 'ios/Runner/Assets.xcassets/AppIcon.appiconset';
    for (final (base, scale) in [
      (20.0, 1),
      (20.0, 2),
      (20.0, 3),
      (29.0, 1),
      (29.0, 2),
      (29.0, 3),
      (40.0, 1),
      (40.0, 2),
      (40.0, 3),
      (60.0, 2),
      (60.0, 3),
      (76.0, 1),
      (76.0, 2),
      (83.5, 2),
      (1024.0, 1),
    ]) {
      final name = base == base.roundToDouble() ? '${base.toInt()}' : '$base';
      await write(
        '$ios/Icon-App-${name}x$name@${scale}x.png',
        (base * scale).round(),
        rounded: false,
      );
    }
    const mac = 'macos/Runner/Assets.xcassets/AppIcon.appiconset';
    for (final s in [16, 32, 64, 128, 256, 512, 1024]) {
      await write('$mac/app_icon_$s.png', s);
    }
    final frames = [
      for (final s in [16, 24, 32, 48, 64, 128, 256]) (s, await _png(pic, s, rounded: true)),
    ];
    File('windows/runner/resources/app_icon.ico').writeAsBytesSync(_ico(frames));
    await write('assets/icon/rgcompanion-512.png', 512);
    pic.picture.dispose();
  });
}

// Draws the app's icons for every platform from RedGiant's own logo (G40.18): the master of
// packaging/icon/redgiant-icon.jpg (the red giant the page's icon-*.png come from). Run from
// apps/companion after changing the logo:
//
//   flutter test tool/make_icons_test.dart
//
// The master is a rounded tile on black. The tool finds the tile, then makes:
// - the tile with its corners transparent: Android (before 8), macOS (with Apple's margin),
//   Windows (.ico of PNG frames), Linux and assets/icon/rgcompanion-512.png;
// - the tile's inside, edge to edge and opaque: iOS (Apple rounds it) and the foreground of
//   Android's adaptive icon, on a background of the logo's own edge colour.
// test/icons_test.dart checks the results.
import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/painting.dart';
import 'package:flutter_test/flutter_test.dart';

const master = '../../packaging/icon/redgiant-icon.jpg';

/// The tile's corner radius, as a share of its side (the master's rounded square).
const tileRadius = .2;

/// How far inside the tile the edge-to-edge picture starts: past the glowing border and the
/// rounded corners (at a radius of 20% the corner's curve leaves the diagonal by 5.9%).
const bleedInset = .075;

/// Android's adaptive icon: a 108dp layer, 72dp of it seen through the launcher's mask.
const adaptiveLayer = 108.0;
const adaptiveSeen = 72.0;

class _Master {
  _Master(this.image, this.tile);

  final ui.Image image;

  /// The rounded tile within the master.
  final Rect tile;

  Rect get bleed => tile.deflate(tile.width * bleedInset);
}

/// The first and last bright pixels of the middle row and column: the tile's glowing border.
Future<_Master> _load() async {
  final codec = await ui.instantiateImageCodec(File(master).readAsBytesSync());
  final image = (await codec.getNextFrame()).image;
  final px = (await image.toByteData(format: ui.ImageByteFormat.rawRgba))!;
  final w = image.width, h = image.height;
  bool bright(int x, int y) => px.getUint8((y * w + x) * 4) > 90;
  int first(int n, bool Function(int) at) {
    for (var i = 0; i < n; i++) {
      if (at(i)) return i;
    }
    throw StateError('no tile in $master');
  }

  int last(int n, bool Function(int) at) => n - 1 - first(n, (i) => at(n - 1 - i));
  final left = first(w, (x) => bright(x, h ~/ 2));
  final right = last(w, (x) => bright(x, h ~/ 2));
  final top = first(h, (y) => bright(w ~/ 2, y));
  final bottom = last(h, (y) => bright(w ~/ 2, y));
  final side = ((right - left) + (bottom - top)) / 2 + 1;
  final centre = Offset((left + right) / 2, (top + bottom) / 2);
  return _Master(image, Rect.fromCenter(center: centre, width: side, height: side));
}

final _paint = Paint()
  ..filterQuality = FilterQuality.high
  ..isAntiAlias = true;

Future<Uint8List> _encode(ui.Picture picture, int size) async {
  final image = await picture.toImage(size, size);
  final data = await image.toByteData(format: ui.ImageByteFormat.png);
  image.dispose();
  picture.dispose();
  return data!.buffer.asUint8List();
}

/// The rounded tile, corners transparent, [margin] (share of the side) all around.
Future<Uint8List> _tile(_Master m, int size, {double margin = 0}) {
  final rec = ui.PictureRecorder();
  final canvas = Canvas(rec);
  final s = size.toDouble();
  final r = Rect.fromLTWH(s * margin, s * margin, s * (1 - 2 * margin), s * (1 - 2 * margin));
  canvas.clipRRect(RRect.fromRectAndRadius(r, Radius.circular(r.width * tileRadius)));
  canvas.drawImageRect(m.image, m.tile, r, _paint);
  return _encode(rec.endRecording(), size);
}

/// The tile's inside, edge to edge; within an adaptive layer it fills the part the mask shows.
Future<Uint8List> _bleed(_Master m, int size, {double fill = 1}) {
  final rec = ui.PictureRecorder();
  final canvas = Canvas(rec);
  final s = size.toDouble();
  final d = s * fill;
  canvas.drawImageRect(
    m.image,
    m.bleed,
    Rect.fromCenter(center: Offset(s / 2, s / 2), width: d, height: d),
    _paint,
  );
  return _encode(rec.endRecording(), size);
}

/// The average colour of the inside's outer ring of pixels: the adaptive icon's background.
Future<String> _edgeColour(_Master m) async {
  final png = await _bleed(m, 64);
  final codec = await ui.instantiateImageCodec(png);
  final img = (await codec.getNextFrame()).image;
  final px = (await img.toByteData(format: ui.ImageByteFormat.rawRgba))!;
  var r = 0, g = 0, b = 0, n = 0;
  for (var i = 0; i < 64; i++) {
    for (final (x, y) in [(i, 0), (i, 63), (0, i), (63, i)]) {
      final o = (y * 64 + x) * 4;
      r += px.getUint8(o);
      g += px.getUint8(o + 1);
      b += px.getUint8(o + 2);
      n++;
    }
  }
  String hex(int v) => (v ~/ n).toRadixString(16).padLeft(2, '0').toUpperCase();
  return '#FF${hex(r)}${hex(g)}${hex(b)}';
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
    final m = await _load();
    // A tile of the expected shape: most of the master.
    expect(m.tile.width / m.image.width, inInclusiveRange(.7, .98));
    Future<void> write(String path, Future<Uint8List> png) async =>
        File(path).writeAsBytesSync(await png);

    // Android: the legacy icon (a small margin, as launcher icons have) and the adaptive one.
    const android = {'mdpi': 1.0, 'hdpi': 1.5, 'xhdpi': 2.0, 'xxhdpi': 3.0, 'xxxhdpi': 4.0};
    const res = 'android/app/src/main/res';
    for (final MapEntry(key: d, value: k) in android.entries) {
      await write('$res/mipmap-$d/ic_launcher.png', _tile(m, (48 * k).round(), margin: .04));
      await write(
        '$res/mipmap-$d/ic_launcher_foreground.png',
        _bleed(m, (adaptiveLayer * k).round(), fill: (adaptiveSeen + 2) / adaptiveLayer),
      );
    }
    Directory('$res/mipmap-anydpi-v26').createSync(recursive: true);
    File('$res/mipmap-anydpi-v26/ic_launcher.xml').writeAsStringSync(
      '<?xml version="1.0" encoding="utf-8"?>\n'
      '<!-- RedGiant\'s logo (G40.18), made by tool/make_icons_test.dart. -->\n'
      '<adaptive-icon xmlns:android="http://schemas.android.com/apk/res/android">\n'
      '    <background android:drawable="@color/ic_launcher_background"/>\n'
      '    <foreground android:drawable="@mipmap/ic_launcher_foreground"/>\n'
      '</adaptive-icon>\n',
    );
    File('$res/values/ic_launcher_background.xml').writeAsStringSync(
      '<?xml version="1.0" encoding="utf-8"?>\n'
      '<!-- The edge colour of RedGiant\'s logo, made by tool/make_icons_test.dart. -->\n'
      '<resources>\n'
      '    <color name="ic_launcher_background">${await _edgeColour(m)}</color>\n'
      '</resources>\n',
    );

    // iOS: the full square, opaque (Apple rounds it).
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
      await write('$ios/Icon-App-${name}x$name@${scale}x.png', _bleed(m, (base * scale).round()));
    }

    // macOS: the tile inside Apple's grid (824 of 1024).
    const mac = 'macos/Runner/Assets.xcassets/AppIcon.appiconset';
    for (final s in [16, 32, 64, 128, 256, 512, 1024]) {
      await write('$mac/app_icon_$s.png', _tile(m, s, margin: 100 / 1024));
    }

    // Windows: an .ico of PNG frames; Linux and the app's own copy: the tile.
    final frames = [
      for (final s in [16, 24, 32, 48, 64, 128, 256]) (s, await _tile(m, s, margin: .02)),
    ];
    File('windows/runner/resources/app_icon.ico').writeAsBytesSync(_ico(frames));
    await write('assets/icon/rgcompanion-512.png', _tile(m, 512));
    m.image.dispose();
  });
}

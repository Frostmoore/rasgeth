// Draws every size of the product's icon (Rasgeth, plan 3.8.13 N8) from the approved masters in
// packaging/icon/: the app's icons for every platform, the page's (packages/web/public), the
// site's (site/assets/img), the Windows program's .ico and the silhouettes (Android
// notifications and themed icon, the Mac's menu bar, the Windows tray). Run from
// apps/companion after changing a master:
//
//   flutter test tool/make_icons_test.dart
//
// The masters (never redrawn here):
// - rasgeth-icon.png: 1024, the squircle tile with transparent corners;
// - rasgeth-icon-ios.png: 1024, the same picture square and opaque (Apple rounds it);
// - rasgeth-icon-fg.png, -bg.png: Android's adaptive layers (108dp, the 72dp seen are the tile);
// - rasgeth-icon-small-16/24/32.png: drawn on the pixel grid for the smallest sizes;
// - rasgeth-silhouette.svg (no face) and rasgeth-silhouette-volto.svg (with the face, only for
//   Android 13's themed icon): one even-odd path of M/L/Z in a 64 box.
// test/icons_test.dart checks the results.
import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/painting.dart';
import 'package:flutter_test/flutter_test.dart';

const icons = '../../packaging/icon';

/// Android's adaptive icon: a 108dp layer, 72dp of it seen through the launcher's mask.
const adaptiveLayer = 108.0;
const adaptiveSeen = 72.0;

/// Apple's grid for the Mac: the tile is 824 of 1024, centred.
const macMargin = 100 / 1024;

/// A maskable web icon must keep what matters inside the middle 80% circle: the tile fills 80%.
const maskableTile = .8;

class _Masters {
  _Masters(this.tile, this.ios, this.fg, this.bg, this.small);

  final ui.Image tile, ios, fg, bg;

  /// The pixel-grid tiles, by size.
  final Map<int, ui.Image> small;

  /// The tile at [side] pixels: the pixel-grid drawing up to 32, the master above. Between two
  /// drawings the larger one is scaled down (sharper than the smaller scaled up).
  ui.Image tileFor(double side) {
    for (final s in [16, 24, 32]) {
      if (side <= s + .01) return small[s]!;
    }
    return tile;
  }
}

Future<ui.Image> _image(String path) async {
  final codec = await ui.instantiateImageCodec(File(path).readAsBytesSync());
  return (await codec.getNextFrame()).image;
}

Future<_Masters> _load() async => _Masters(
  await _image('$icons/rasgeth-icon.png'),
  await _image('$icons/rasgeth-icon-ios.png'),
  await _image('$icons/rasgeth-icon-fg.png'),
  await _image('$icons/rasgeth-icon-bg.png'),
  {
    for (final s in [16, 24, 32]) s: await _image('$icons/rasgeth-icon-small-$s.png'),
  },
);

final _paint = Paint()
  ..filterQuality = FilterQuality.high
  ..isAntiAlias = true;

Rect _whole(ui.Image i) => Rect.fromLTWH(0, 0, i.width.toDouble(), i.height.toDouble());

/// Draws [paint] on a [size] square and returns the pixels.
Future<ui.Image> _draw(int size, void Function(Canvas canvas, double s) paint) async {
  final rec = ui.PictureRecorder();
  paint(Canvas(rec), size.toDouble());
  final picture = rec.endRecording();
  final image = await picture.toImage(size, size);
  picture.dispose();
  return image;
}

Future<Uint8List> _png(ui.Image image) async {
  final data = await image.toByteData(format: ui.ImageByteFormat.png);
  image.dispose();
  return data!.buffer.asUint8List();
}

// --- PNG without an alpha channel (Apple refuses one in the 1024 icon; the others are opaque too).

final _crcTable = List<int>.generate(256, (n) {
  var c = n;
  for (var k = 0; k < 8; k++) {
    c = (c & 1) != 0 ? 0xEDB88320 ^ (c >> 1) : c >> 1;
  }
  return c;
});

int _crc(List<int> bytes) {
  var c = 0xFFFFFFFF;
  for (final b in bytes) {
    c = _crcTable[(c ^ b) & 0xFF] ^ (c >> 8);
  }
  return c ^ 0xFFFFFFFF;
}

void _chunk(BytesBuilder out, String type, List<int> data) {
  final body = [...type.codeUnits, ...data];
  out
    ..add((ByteData(4)..setUint32(0, data.length)).buffer.asUint8List())
    ..add(body)
    ..add((ByteData(4)..setUint32(0, _crc(body))).buffer.asUint8List());
}

/// An RGB PNG (colour type 2) of an opaque [image], rows filtered with Paeth.
Future<Uint8List> _rgbPng(ui.Image image) async {
  final w = image.width, h = image.height;
  final px = (await image.toByteData(format: ui.ImageByteFormat.rawRgba))!;
  image.dispose();
  int at(int x, int y, int c) => x < 0 || y < 0 ? 0 : px.getUint8((y * w + x) * 4 + c);
  final raw = Uint8List(h * (1 + w * 3));
  var o = 0;
  for (var y = 0; y < h; y++) {
    raw[o++] = 4; // Paeth
    for (var x = 0; x < w; x++) {
      if (at(x, y, 3) != 255) throw StateError('not opaque at $x,$y');
      for (var c = 0; c < 3; c++) {
        final a = at(x - 1, y, c), b = at(x, y - 1, c), d = at(x - 1, y - 1, c);
        final p = a + b - d;
        final pa = (p - a).abs(), pb = (p - b).abs(), pd = (p - d).abs();
        final pred = pa <= pb && pa <= pd ? a : (pb <= pd ? b : d);
        raw[o++] = (at(x, y, c) - pred) & 0xFF;
      }
    }
  }
  final out = BytesBuilder()..add([0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A]);
  final ihdr = ByteData(13)
    ..setUint32(0, w)
    ..setUint32(4, h)
    ..setUint8(8, 8)
    ..setUint8(9, 2);
  _chunk(out, 'IHDR', ihdr.buffer.asUint8List());
  _chunk(out, 'IDAT', ZLibCodec(level: 9).encode(raw));
  _chunk(out, 'IEND', const []);
  return out.toBytes();
}

// --- The pictures.

/// The tile, corners transparent, [margin] (share of the side) all around.
Future<ui.Image> _tile(_Masters m, int size, {double margin = 0}) => _draw(size, (canvas, s) {
  final r = Rect.fromLTWH(s * margin, s * margin, s * (1 - 2 * margin), s * (1 - 2 * margin));
  final src = m.tileFor(r.width);
  canvas.drawImageRect(src, _whole(src), r, _paint);
});

/// The square, opaque picture (iOS, the page's touch icon).
Future<ui.Image> _square(_Masters m, int size) => _draw(
  size,
  (canvas, s) => canvas.drawImageRect(m.ios, _whole(m.ios), Offset.zero & Size(s, s), _paint),
);

/// An adaptive layer at [size] pixels.
Future<ui.Image> _layer(ui.Image layer, int size) => _draw(
  size,
  (canvas, s) => canvas.drawImageRect(layer, _whole(layer), Offset.zero & Size(s, s), _paint),
);

/// Both adaptive layers together, the middle [seen] dp of the 108dp layer filling the square:
/// by default the tile (72dp) fills [maskableTile] of it.
Future<ui.Image> _adaptive(_Masters m, int size, {double seen = adaptiveSeen / maskableTile}) =>
    _draw(size, (canvas, s) {
      final k = s / seen; // pixels per dp
      final r = Rect.fromCenter(
        center: Offset(s / 2, s / 2),
        width: adaptiveLayer * k,
        height: adaptiveLayer * k,
      );
      canvas.drawImageRect(m.bg, _whole(m.bg), r, _paint);
      canvas.drawImageRect(m.fg, _whole(m.fg), r, _paint);
    });

/// The silhouette's single path (M, L and Z, absolute) as written and as a [Path], in its 64 box.
({String d, Path path}) _silhouette(String name) {
  final svg = File('$icons/$name').readAsStringSync();
  final d = RegExp(r' d="([^"]+)"').firstMatch(svg)!.group(1)!;
  if (RegExp(r'[^MLZ0-9.\s-]').hasMatch(d)) throw StateError('$name: only M, L and Z expected');
  final path = Path()..fillType = PathFillType.evenOdd;
  for (final c in RegExp(r'([MLZ])([^MLZ]*)').allMatches(d)) {
    final n = RegExp(r'-?[\d.]+').allMatches(c.group(2)!).map((e) => double.parse(e[0]!)).toList();
    switch (c.group(1)) {
      case 'M':
        path.moveTo(n[0], n[1]);
        for (var i = 2; i < n.length; i += 2) {
          path.lineTo(n[i], n[i + 1]);
        }
      case 'L':
        for (var i = 0; i < n.length; i += 2) {
          path.lineTo(n[i], n[i + 1]);
        }
      case 'Z':
        path.close();
    }
  }
  return (d: d, path: path);
}

/// The silhouette in one colour at [size] pixels: its 64 box fills the square.
Future<ui.Image> _mono(Path path, int size, Color colour) => _draw(size, (canvas, s) {
  canvas.scale(s / 64);
  canvas.drawPath(
    path,
    Paint()
      ..color = colour
      ..isAntiAlias = true,
  );
});

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

/// The bounding box of the pixels of [image] with an alpha of at least [min].
Future<Rect> _opaqueBox(ui.Image image, int min) async {
  final px = (await image.toByteData(format: ui.ImageByteFormat.rawRgba))!;
  final w = image.width, h = image.height;
  var l = w, t = h, r = -1, b = -1;
  for (var y = 0; y < h; y++) {
    for (var x = 0; x < w; x++) {
      if (px.getUint8((y * w + x) * 4 + 3) >= min) {
        if (x < l) l = x;
        if (x > r) r = x;
        if (y < t) t = y;
        if (y > b) b = y;
      }
    }
  }
  return Rect.fromLTRB(l.toDouble(), t.toDouble(), r + 1.0, b + 1.0);
}

String _n(double v) => v.toStringAsFixed(3).replaceFirst(RegExp(r'\.?0+$'), '');

void main() {
  test('make the icons', () async {
    final m = await _load();
    expect((m.tile.width, m.ios.width, m.fg.width, m.bg.width), (1024, 1024, 1024, 1024));
    Future<void> write(String path, Future<ui.Image> image) async {
      File(path)
        ..parent.createSync(recursive: true)
        ..writeAsBytesSync(await _png(await image));
    }

    Future<void> writeRgb(String path, Future<ui.Image> image) async {
      File(path)
        ..parent.createSync(recursive: true)
        ..writeAsBytesSync(await _rgbPng(await image));
    }

    Future<Uint8List> ico(List<int> sizes, Future<ui.Image> Function(int) frame) async =>
        _ico([for (final s in sizes) (s, await _png(await frame(s)))]);

    final plain = _silhouette('rasgeth-silhouette.svg');
    final face = _silhouette('rasgeth-silhouette-volto.svg');

    // Android: the legacy icon (a small margin, as launcher icons have), the adaptive layers and
    // the monochrome one for Android 13's themed icons.
    const android = {'mdpi': 1.0, 'hdpi': 1.5, 'xhdpi': 2.0, 'xxhdpi': 3.0, 'xxxhdpi': 4.0};
    const res = 'android/app/src/main/res';
    for (final MapEntry(key: d, value: k) in android.entries) {
      final layer = (adaptiveLayer * k).round();
      await write('$res/mipmap-$d/ic_launcher.png', _tile(m, (48 * k).round(), margin: .04));
      await write('$res/mipmap-$d/ic_launcher_foreground.png', _layer(m.fg, layer));
      await write('$res/mipmap-$d/ic_launcher_background.png', _layer(m.bg, layer));
    }
    File('$res/mipmap-anydpi-v26/ic_launcher.xml')
      ..parent.createSync(recursive: true)
      ..writeAsStringSync(
        '<?xml version="1.0" encoding="utf-8"?>\n'
        '<!-- The product\'s icon (plan 3.8.13 N8), made by tool/make_icons_test.dart. -->\n'
        '<adaptive-icon xmlns:android="http://schemas.android.com/apk/res/android">\n'
        '    <background android:drawable="@mipmap/ic_launcher_background"/>\n'
        '    <foreground android:drawable="@mipmap/ic_launcher_foreground"/>\n'
        '    <monochrome android:drawable="@drawable/ic_launcher_monochrome"/>\n'
        '</adaptive-icon>\n',
      );
    final oldColour = File('$res/values/ic_launcher_background.xml');
    if (oldColour.existsSync()) oldColour.deleteSync();
    // The silhouette with the face where the foreground's mascot is (its opaque part, halo out).
    final body = await _opaqueBox(m.fg, 230);
    final shape = face.path.getBounds();
    final fit = body.height / shape.height * adaptiveLayer / m.fg.height;
    final dx = body.center.dx * adaptiveLayer / m.fg.width - shape.center.dx * fit;
    final dy = body.center.dy * adaptiveLayer / m.fg.height - shape.center.dy * fit;
    File('$res/drawable/ic_launcher_monochrome.xml').writeAsStringSync(
      '<?xml version="1.0" encoding="utf-8"?>\n'
      '<!-- Android 13\'s themed icon: the silhouette with the face (packaging/icon/\n'
      '     rasgeth-silhouette-volto.svg) where the adaptive foreground has the mascot; the system\n'
      '     tints it. Made by tool/make_icons_test.dart. -->\n'
      '<vector xmlns:android="http://schemas.android.com/apk/res/android"\n'
      '    android:width="108dp"\n'
      '    android:height="108dp"\n'
      '    android:viewportWidth="108"\n'
      '    android:viewportHeight="108">\n'
      '    <group\n'
      '        android:scaleX="${_n(fit)}"\n'
      '        android:scaleY="${_n(fit)}"\n'
      '        android:translateX="${_n(dx)}"\n'
      '        android:translateY="${_n(dy)}">\n'
      '        <path\n'
      '            android:fillColor="#FFFFFFFF"\n'
      '            android:fillType="evenOdd"\n'
      '            android:pathData="${face.d}"/>\n'
      '    </group>\n'
      '</vector>\n',
    );
    File('$res/drawable/ic_notification.xml').writeAsStringSync(
      '<?xml version="1.0" encoding="utf-8"?>\n'
      '<!-- The notifications\' small icon (G40.10, plan 3.8.13 N8): the white silhouette, as\n'
      '     Android wants it (packaging/icon/rasgeth-silhouette.svg, no face). Made by\n'
      '     tool/make_icons_test.dart. -->\n'
      '<vector xmlns:android="http://schemas.android.com/apk/res/android"\n'
      '    android:width="24dp"\n'
      '    android:height="24dp"\n'
      '    android:viewportWidth="64"\n'
      '    android:viewportHeight="64">\n'
      '    <path\n'
      '        android:fillColor="#FFFFFFFF"\n'
      '        android:fillType="evenOdd"\n'
      '        android:pathData="${plain.d}"/>\n'
      '</vector>\n',
    );

    // iOS: the full square, opaque and without an alpha channel (Apple rounds it).
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
      await writeRgb(
        '$ios/Icon-App-${name}x$name@${scale}x.png',
        _square(m, (base * scale).round()),
      );
    }

    // macOS: the tile inside Apple's grid (824 of 1024).
    const mac = 'macos/Runner/Assets.xcassets/AppIcon.appiconset';
    for (final s in [16, 32, 64, 128, 256, 512, 1024]) {
      await write('$mac/app_icon_$s.png', _tile(m, s, margin: macMargin));
    }
    // The Mac's menu bar: a template image (black, the alpha is the shape), 18pt at 2x.
    await write('$icons/rasgeth-menubar.png', _mono(plain.path, 36, const Color(0xFF000000)));

    // Windows: the app's and the program's .ico (the pixel-grid tiles up to 32); the tray's
    // silhouettes, white for a dark taskbar and black for a light one.
    final winIco = await ico([
      16,
      24,
      32,
      48,
      64,
      128,
      256,
    ], (s) => _tile(m, s, margin: s <= 32 ? 0 : .02));
    File('windows/runner/resources/app_icon.ico').writeAsBytesSync(winIco);
    File('../../packaging/windows/redgiant.ico').writeAsBytesSync(winIco);
    for (final (name, colour) in [
      ('dark', const Color(0xFFFFFFFF)),
      ('light', const Color(0xFF000000)),
    ]) {
      File('$icons/rasgeth-tray-$name.ico').writeAsBytesSync(
        await ico([16, 20, 24, 32, 40, 48, 64], (s) => _mono(plain.path, s, colour)),
      );
    }

    // Linux and the app's own copy: the tile.
    await write('assets/icon/rgcompanion-512.png', _tile(m, 512));

    // The page: favicons (an .ico of 16, 32 and 48, and a 32 PNG), the touch icon (opaque, no
    // alpha), the manifest's icons (the tile) and the maskable one (the tile in the 80% circle).
    const web = '../../packages/web/public';
    File('$web/favicon.ico').writeAsBytesSync(await ico([16, 32, 48], (s) => _tile(m, s)));
    await write('$web/favicon.png', _tile(m, 32));
    await writeRgb('$web/apple-touch-icon.png', _square(m, 180));
    await write('$web/icon-192.png', _tile(m, 192));
    await write('$web/icon-512.png', _tile(m, 512));
    await writeRgb('$web/icon-maskable-512.png', _adaptive(m, 512));

    // The site: the same files under its names (site/tools/build.mjs copies them too).
    const site = '../../site/assets/img';
    File('$web/favicon.png').copySync('$site/favicon.png');
    File('$web/apple-touch-icon.png').copySync('$site/apple-touch-icon.png');
    File('$web/icon-192.png').copySync('$site/logo.png');

    for (final i in [m.tile, m.ios, m.fg, m.bg, ...m.small.values]) {
      i.dispose();
    }
  });
}

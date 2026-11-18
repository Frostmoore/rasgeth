// The product's icon at every size (plan 3.8.13 N8): the files tool/make_icons_test.dart makes
// from the masters in packaging/icon are there for every platform, at their sizes, with an alpha
// channel where corners are transparent and without one where it is forbidden (iOS, the touch
// icon), small enough to ship, and they are the page's logo, not another drawing.
import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter_test/flutter_test.dart';

typedef _Px = ({int w, int h, ByteData px, int colourType});

Future<ui.Image> _decode(Uint8List bytes) async =>
    (await (await ui.instantiateImageCodec(bytes)).getNextFrame()).image;

Future<_Px> _pngBytes(Uint8List bytes) async {
  // The PNG signature, then IHDR: width, height, bit depth, colour type (2 RGB, 6 RGBA).
  expect(bytes.sublist(1, 4), 'PNG'.codeUnits);
  final img = await _decode(bytes);
  final px = (await img.toByteData(format: ui.ImageByteFormat.rawRgba))!;
  final out = (w: img.width, h: img.height, px: px, colourType: bytes[25]);
  img.dispose();
  return out;
}

Future<_Px> _png(String path) => _pngBytes(File(path).readAsBytesSync());

int _alpha(_Px i, int x, int y) => i.px.getUint8((y * i.w + x) * 4 + 3);

(int, int, int) _rgb(_Px i, int x, int y) {
  final o = (y * i.w + x) * 4;
  return (i.px.getUint8(o), i.px.getUint8(o + 1), i.px.getUint8(o + 2));
}

bool _opaque(_Px i) {
  for (var o = 3; o < i.px.lengthInBytes; o += 4) {
    if (i.px.getUint8(o) != 255) return false;
  }
  return true;
}

/// Mean difference per channel (0-255) of two pictures of the same size.
double _difference(_Px a, _Px b) {
  var sum = 0;
  for (var i = 0; i < a.px.lengthInBytes; i++) {
    sum += (a.px.getUint8(i) - b.px.getUint8(i)).abs();
  }
  return sum / a.px.lengthInBytes;
}

/// The frames of an .ico of PNGs, checked against the directory's sizes.
Future<List<_Px>> _ico(String path) async {
  final ico = File(path).readAsBytesSync();
  final head = ByteData.sublistView(ico);
  expect(head.getUint16(2, Endian.little), 1, reason: path);
  final frames = <_Px>[];
  for (var i = 0; i < head.getUint16(4, Endian.little); i++) {
    final e = 6 + 16 * i;
    final w = head.getUint8(e);
    final len = head.getUint32(e + 8, Endian.little);
    final at = head.getUint32(e + 12, Endian.little);
    final f = await _pngBytes(Uint8List.sublistView(ico, at, at + len));
    expect(f.w, w == 0 ? 256 : w, reason: path);
    frames.add(f);
  }
  return frames;
}

int _bytes(String path) => File(path).lengthSync();

/// The colours of the pixels that are not fully transparent (a silhouette has one).
Set<(int, int, int)> _colours(_Px i) => {
  for (var y = 0; y < i.h; y++)
    for (var x = 0; x < i.w; x++)
      if (_alpha(i, x, y) > 0) _rgb(i, x, y),
};

String _pathOf(String svg) => RegExp(r' d="([^"]+)"').firstMatch(svg)!.group(1)!;

const _icons = '../../packaging/icon';
const _web = '../../packages/web/public';

void main() {
  test('the masters are the approved Rasgeth files, and the old logo is gone', () async {
    final tile = await _png('$_icons/rasgeth-icon.png');
    expect((tile.w, tile.h, tile.colourType), (1024, 1024, 6));
    expect(_alpha(tile, 0, 0), 0);
    expect(_alpha(tile, 512, 512), 255);
    final ios = await _png('$_icons/rasgeth-icon-ios.png');
    expect((ios.w, ios.colourType), (1024, 2));
    expect((await _png('$_icons/rasgeth-icon-bg.png')).colourType, 2);
    final fg = await _png('$_icons/rasgeth-icon-fg.png');
    expect((fg.w, _alpha(fg, 0, 0), _alpha(fg, 512, 512)), (1024, 0, 255));
    for (final s in [16, 24, 32]) {
      expect((await _png('$_icons/rasgeth-icon-small-$s.png')).w, s);
    }
    for (final svg in ['rasgeth-silhouette.svg', 'rasgeth-silhouette-volto.svg']) {
      expect(File('$_icons/$svg').readAsStringSync(), contains('viewBox="0 0 64 64"'));
    }
    expect(File('$_icons/redgiant-icon.jpg').existsSync(), isFalse);
  });

  test('the app\'s icon is the page\'s logo', () async {
    final ours = await _png('assets/icon/rgcompanion-512.png');
    final page = await _png('$_web/icon-512.png');
    expect((ours.w, ours.h), (512, 512));
    // The same picture: a few levels of difference from resampling, where another drawing is
    // far off.
    expect(_difference(ours, page), lessThan(12));
    // Rounded: the corners are transparent, the middle is not.
    expect(_alpha(ours, 2, 2), 0);
    expect(_alpha(ours, 256, 256), 255);
  });

  test('Android: legacy, adaptive (background, foreground, monochrome) at every density', () async {
    const res = 'android/app/src/main/res';
    const k = {'mdpi': 1.0, 'hdpi': 1.5, 'xhdpi': 2.0, 'xxhdpi': 3.0, 'xxxhdpi': 4.0};
    for (final MapEntry(key: d, value: s) in k.entries) {
      final legacy = await _png('$res/mipmap-$d/ic_launcher.png');
      expect(legacy.w, (48 * s).round());
      expect(_alpha(legacy, 0, 0), 0);
      final layer = (108 * s).round();
      final fg = await _png('$res/mipmap-$d/ic_launcher_foreground.png');
      expect(fg.w, layer);
      // The mascot in the middle; the layer's edge (outside the mask) is transparent.
      expect(_alpha(fg, layer ~/ 2, layer ~/ 2), 255);
      expect(_alpha(fg, 0, 0), 0);
      final bg = await _png('$res/mipmap-$d/ic_launcher_background.png');
      expect(bg.w, layer);
      expect(_opaque(bg), isTrue, reason: 'the sky fills the whole background layer');
    }
    final adaptive = File('$res/mipmap-anydpi-v26/ic_launcher.xml').readAsStringSync();
    expect(adaptive, contains('<background android:drawable="@mipmap/ic_launcher_background"/>'));
    expect(adaptive, contains('<foreground android:drawable="@mipmap/ic_launcher_foreground"/>'));
    expect(adaptive, contains('<monochrome android:drawable="@drawable/ic_launcher_monochrome"/>'));
    expect(File('$res/values/ic_launcher_background.xml').existsSync(), isFalse);

    // The themed icon: the silhouette with the face, inside the 66dp safe circle of the layer.
    final mono = File('$res/drawable/ic_launcher_monochrome.xml').readAsStringSync();
    expect(mono, contains('android:viewportWidth="108"'));
    final d = _pathOf(File('$_icons/rasgeth-silhouette-volto.svg').readAsStringSync());
    expect(mono, contains('android:pathData="$d"'));
    double attr(String name) =>
        double.parse(RegExp('android:$name="([-0-9.]+)"').firstMatch(mono)!.group(1)!);
    final scale = attr('scaleX'), tx = attr('translateX'), ty = attr('translateY');
    expect(attr('scaleY'), scale);
    final n = RegExp(r'-?[\d.]+').allMatches(d).map((e) => double.parse(e[0]!)).toList();
    var far = 0.0;
    for (var i = 0; i < n.length; i += 2) {
      final x = n[i] * scale + tx - 54, y = n[i + 1] * scale + ty - 54;
      if (x * x + y * y > far) far = x * x + y * y;
    }
    expect(far, lessThanOrEqualTo(33.0 * 33.0));
    expect(far, greaterThan(24.0 * 24.0), reason: 'not lost in the middle either');

    // Notifications: the white silhouette without the face.
    final note = File('$res/drawable/ic_notification.xml').readAsStringSync();
    final plain = _pathOf(File('$_icons/rasgeth-silhouette.svg').readAsStringSync());
    expect(note, contains('android:pathData="$plain"'));
    expect(note, contains('android:fillColor="#FFFFFFFF"'));
    expect(note, contains('android:viewportWidth="64"'));
  });

  test('iOS: opaque squares without an alpha channel, at every size', () async {
    const ios = 'ios/Runner/Assets.xcassets/AppIcon.appiconset';
    final names = [
      for (final f in Directory(ios).listSync().whereType<File>())
        if (f.path.endsWith('.png')) f.uri.pathSegments.last,
    ]..sort();
    expect(names, hasLength(15));
    for (final name in names) {
      final m = RegExp(r'Icon-App-([\d.]+)x[\d.]+@(\d)x\.png').firstMatch(name)!;
      final side = (double.parse(m[1]!) * int.parse(m[2]!)).round();
      final p = await _png('$ios/$name');
      expect((p.w, p.h, p.colourType), (side, side, 2), reason: name);
    }
    final big = await _png('$ios/Icon-App-1024x1024@1x.png');
    expect((await _png('$ios/Icon-App-83.5x83.5@2x.png')).w, 167);
    // The sky reaches the corners (Apple rounds it): no black or white frame.
    final (r, g, b) = _rgb(big, 2, 2);
    expect(b, greaterThan(r));
    expect(b, greaterThan(g));
    expect(_bytes('$ios/Icon-App-1024x1024@1x.png'), lessThan(2000000));
  });

  test('macOS: the tile in Apple\'s grid; the menu bar\'s template', () async {
    const mac = 'macos/Runner/Assets.xcassets/AppIcon.appiconset';
    for (final s in [16, 32, 64, 128, 256, 512, 1024]) {
      final p = await _png('$mac/app_icon_$s.png');
      expect((p.w, p.h), (s, s));
      // Apple's margin (100 of 1024) is transparent, the middle is not.
      expect(_alpha(p, (s * 40 / 1024).floor(), s ~/ 2), 0, reason: 'app_icon_$s');
      expect(_alpha(p, s ~/ 2, s ~/ 2), 255, reason: 'app_icon_$s');
    }
    final m = await _png('$mac/app_icon_1024.png');
    expect(_alpha(m, 90, 512), 0);
    expect(_alpha(m, 130, 512), 255);
    final bar = await _png('$_icons/rasgeth-menubar.png');
    expect((bar.w, bar.h), (36, 36));
    expect(_colours(bar), {(0, 0, 0)}, reason: 'a template is black; the alpha is the shape');
    expect(_alpha(bar, 0, 0), 0);
    expect(_alpha(bar, 18, 24), 255);
  });

  test('Windows: the .ico of the app and of the program, the tray\'s silhouettes', () async {
    final app = await _ico('windows/runner/resources/app_icon.ico');
    expect([for (final f in app) f.w], [16, 24, 32, 48, 64, 128, 256]);
    // The smallest frames are the pixel-grid drawings, not the master scaled down.
    for (final (i, s) in [(0, 16), (1, 24), (2, 32)]) {
      expect(_difference(app[i], await _png('$_icons/rasgeth-icon-small-$s.png')), lessThan(1));
    }
    for (final f in app) {
      expect(_alpha(f, 0, 0), 0);
      expect(_alpha(f, f.w ~/ 2, f.w ~/ 2), 255);
    }
    expect(
      File('../../packaging/windows/redgiant.ico').readAsBytesSync(),
      File('windows/runner/resources/app_icon.ico').readAsBytesSync(),
    );
    for (final (name, colour) in [('dark', (255, 255, 255)), ('light', (0, 0, 0))]) {
      final tray = await _ico('$_icons/rasgeth-tray-$name.ico');
      expect([for (final f in tray) f.w], [16, 20, 24, 32, 40, 48, 64]);
      for (final f in tray) {
        expect(_colours(f), {colour}, reason: 'tray $name ${f.w}');
        expect(_alpha(f, 0, 0), 0);
      }
    }
    expect(_bytes('windows/runner/resources/app_icon.ico'), lessThan(400000));
  });

  test('the page and the site: favicons, touch icon, manifest and maskable icons', () async {
    final fav = await _ico('$_web/favicon.ico');
    expect([for (final f in fav) f.w], [16, 32, 48]);
    expect(_difference(fav[0], await _png('$_icons/rasgeth-icon-small-16.png')), lessThan(1));
    final favPng = await _png('$_web/favicon.png');
    expect((favPng.w, _alpha(favPng, 0, 0)), (32, 0));
    final touch = await _png('$_web/apple-touch-icon.png');
    expect((touch.w, touch.colourType), (180, 2));
    for (final s in [192, 512]) {
      final p = await _png('$_web/icon-$s.png');
      expect((p.w, p.colourType, _alpha(p, 1, 1), _alpha(p, s ~/ 2, s ~/ 2)), (s, 6, 0, 255));
    }
    // Maskable: opaque to the edges (no alpha channel), the sky all around the mascot.
    final mask = await _png('$_web/icon-maskable-512.png');
    expect((mask.w, mask.colourType), (512, 2));
    final (r, g, b) = _rgb(mask, 4, 4);
    expect(b > r && b > g, isTrue);
    expect(_bytes('$_web/icon-512.png'), lessThan(600000));
    expect(_bytes('$_web/favicon.ico'), lessThan(20000));
    expect(_bytes('$_web/favicon.png'), lessThan(8000));
    for (final (site, page) in [
      ('favicon.png', 'favicon.png'),
      ('apple-touch-icon.png', 'apple-touch-icon.png'),
      ('logo.png', 'icon-192.png'),
    ]) {
      expect(
        File('../../site/assets/img/$site').readAsBytesSync(),
        File('$_web/$page').readAsBytesSync(),
        reason: site,
      );
    }
  });
}

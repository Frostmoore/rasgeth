// RGCompanion's icon is RedGiant's (G40.18): the icons tool/make_icons_test.dart makes are there
// for every platform, at their sizes, with the right transparency, and they are the page's logo
// (packages/web/public/icon-512.png), not another drawing.
import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter_test/flutter_test.dart';

import 'repo_files.dart';

Future<ui.Image> _decode(Uint8List bytes) async =>
    (await (await ui.instantiateImageCodec(bytes)).getNextFrame()).image;

Future<({int w, int h, ByteData px})> _png(String path) async {
  final img = await _decode(File(path).readAsBytesSync());
  final px = (await img.toByteData(format: ui.ImageByteFormat.rawRgba))!;
  final out = (w: img.width, h: img.height, px: px);
  img.dispose();
  return out;
}

int _alpha(({int w, int h, ByteData px}) i, int x, int y) => i.px.getUint8((y * i.w + x) * 4 + 3);

/// Mean difference per channel (0-255) of two pictures of the same size.
double _difference(({int w, int h, ByteData px}) a, ({int w, int h, ByteData px}) b) {
  var sum = 0;
  for (var i = 0; i < a.px.lengthInBytes; i++) {
    sum += (a.px.getUint8(i) - b.px.getUint8(i)).abs();
  }
  return sum / a.px.lengthInBytes;
}

const _logo = 'packages/web/public/icon-512.png';

void main() {
  test('the app\'s icon is the page\'s logo', skip: repoSkip(_logo), () async {
    final ours = await _png('assets/icon/rgcompanion-512.png');
    final page = await _png(repoFile(_logo)!.path);
    expect((ours.w, ours.h), (512, 512));
    // The same picture: a few levels of difference from resampling, where another drawing
    // (the provisional icon) is far off.
    expect(_difference(ours, page), lessThan(12));
    // Rounded: the corners are transparent, the middle is not.
    expect(_alpha(ours, 2, 2), 0);
    expect(_alpha(ours, 256, 256), 255);
  });

  test('Android: legacy and adaptive icons at every density', () async {
    const res = 'android/app/src/main/res';
    const k = {'mdpi': 1.0, 'hdpi': 1.5, 'xhdpi': 2.0, 'xxhdpi': 3.0, 'xxxhdpi': 4.0};
    for (final MapEntry(key: d, value: s) in k.entries) {
      final legacy = await _png('$res/mipmap-$d/ic_launcher.png');
      expect(legacy.w, (48 * s).round());
      final fg = await _png('$res/mipmap-$d/ic_launcher_foreground.png');
      expect(fg.w, (108 * s).round());
      // The part the launcher shows is covered; the layer's edge is not.
      expect(_alpha(fg, fg.w ~/ 2, (fg.w * 20 / 108).round()), 255);
      expect(_alpha(fg, 0, 0), 0);
    }
    final adaptive = File('$res/mipmap-anydpi-v26/ic_launcher.xml').readAsStringSync();
    expect(adaptive, contains('@mipmap/ic_launcher_foreground'));
    expect(adaptive, contains('@color/ic_launcher_background'));
    expect(
      File('$res/values/ic_launcher_background.xml').readAsStringSync(),
      matches(RegExp(r'<color name="ic_launcher_background">#FF[0-9A-F]{6}</color>')),
    );
  });

  test('iOS: opaque squares; macOS: the tile in Apple\'s grid', () async {
    const ios = 'ios/Runner/Assets.xcassets/AppIcon.appiconset';
    final big = await _png('$ios/Icon-App-1024x1024@1x.png');
    expect(big.w, 1024);
    for (final (x, y) in [(0, 0), (1023, 0), (0, 1023), (1023, 1023), (512, 512)]) {
      expect(_alpha(big, x, y), 255);
    }
    expect((await _png('$ios/Icon-App-83.5x83.5@2x.png')).w, 167);
    const mac = 'macos/Runner/Assets.xcassets/AppIcon.appiconset';
    final m = await _png('$mac/app_icon_1024.png');
    expect(m.w, 1024);
    expect(_alpha(m, 50, 512), 0);
    expect(_alpha(m, 512, 512), 255);
  });

  test('Windows: an .ico of PNG frames up to 256', () async {
    final ico = File('windows/runner/resources/app_icon.ico').readAsBytesSync();
    final head = ByteData.sublistView(ico);
    expect(head.getUint16(2, Endian.little), 1);
    final n = head.getUint16(4, Endian.little);
    final sizes = <int>[];
    for (var i = 0; i < n; i++) {
      final e = 6 + 16 * i;
      final w = head.getUint8(e);
      final len = head.getUint32(e + 8, Endian.little);
      final at = head.getUint32(e + 12, Endian.little);
      final img = await _decode(Uint8List.sublistView(ico, at, at + len));
      expect(img.width, w == 0 ? 256 : w);
      sizes.add(img.width);
      img.dispose();
    }
    expect(sizes, [16, 24, 32, 48, 64, 128, 256]);
  });
}

// Photos for the model (G42.1): kept as they are when small and of a known type, otherwise
// redrawn with the long side at 2000 px on white as JPEG, as the page's `asImage`.
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:rgcompanion/api/image_shrink.dart';

Uint8List _png(int w, int h, {int alpha = 255}) {
  final i = img.Image(width: w, height: h, numChannels: 4);
  img.fill(i, color: img.ColorRgba8(200, 30, 40, alpha));
  return img.encodePng(i);
}

void main() {
  test('a large PNG becomes a JPEG with its long side at 2000 px', () async {
    final out = (await shrinkForModel('wide.png', _png(4000, 1000), mediaType: 'image/png'))!;
    expect(out.mediaType, 'image/jpeg');
    expect(out.name, 'wide.png');
    final d = img.decodeJpg(out.bytes)!;
    expect((d.width, d.height), (2000, 500));
    final tall = (await shrinkForModel('tall.png', _png(900, 3000)))!;
    final t = img.decodeJpg(tall.bytes)!;
    expect((t.width, t.height), (600, 2000));
  });

  test('a small PNG, JPEG or GIF stays as it is', () async {
    final png = _png(300, 200);
    final out = (await shrinkForModel('small.png', png, mediaType: 'image/png'))!;
    expect(out.mediaType, 'image/png');
    expect(out.bytes, png, reason: 'the very bytes');
    final jpg = img.encodeJpg(img.Image(width: 2000, height: 1500));
    final j = (await shrinkForModel('photo.JPG', jpg))!;
    expect(j.mediaType, 'image/jpeg');
    expect(j.bytes, jpg);
    final gif = img.encodeGif(img.Image(width: 40, height: 40));
    expect((await shrinkForModel('a.gif', gif, mediaType: 'image/gif'))!.mediaType, 'image/gif');
  });

  test('a BMP or an unknown type is redrawn as JPEG, at its own size', () async {
    final bmp = img.encodeBmp(img.Image(width: 120, height: 80));
    final b = (await shrinkForModel('scan.bmp', bmp, mediaType: 'image/bmp'))!;
    expect(b.mediaType, 'image/jpeg');
    final d = img.decodeJpg(b.bytes)!;
    expect((d.width, d.height), (120, 80));
    final u = (await shrinkForModel('picture.dat', _png(50, 50)))!;
    expect(u.mediaType, 'image/jpeg');
    expect((await shrinkForModel('', bmp))!.name, 'image.jpg');
  });

  test('a heavy photo of fine size is redrawn; transparency lands on white', () async {
    final r = math.Random(4);
    final noise = img.Image(width: 1200, height: 1200);
    for (final p in noise) {
      p
        ..r = r.nextInt(256)
        ..g = r.nextInt(256)
        ..b = r.nextInt(256);
    }
    final heavy = img.encodePng(noise, level: 0);
    expect(heavy.length, greaterThan(kImageKeepBytes));
    final h = (await shrinkForModel('noise.png', heavy, mediaType: 'image/png'))!;
    expect(h.mediaType, 'image/jpeg');
    expect(img.decodeJpg(h.bytes)!.width, 1200);

    final clear = (await shrinkForModel('clear.webp', _png(10, 10, alpha: 0), mediaType: 'x/y'))!;
    final px = img.decodeJpg(clear.bytes)!.getPixel(5, 5);
    expect(px.r, greaterThan(245));
    expect(px.g, greaterThan(245));
    expect(px.b, greaterThan(245));
  });

  test('what does not decode is not a photo', () async {
    expect(await shrinkForModel('a.png', Uint8List.fromList([1, 2, 3, 4, 5])), isNull);
    expect(await shrinkForModel('a.heic', Uint8List(0)), isNull);
  });
}

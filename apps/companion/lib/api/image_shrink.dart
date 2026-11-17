// A photo for the model (G42.1), as the page's `asImage` (packages/web/src/components/Composer.tsx):
// kept as it is when it is PNG, JPEG, GIF or WebP, its long side at most 2000 px and at most
// 1,500,000 bytes; otherwise redrawn with its long side at 2000 px on white, as JPEG at quality 85
// (what the providers accept and what is worth paying for). The work runs in another isolate.
import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:image/image.dart' as img;

import 'attachments.dart';

/// The long side a photo is redrawn at.
const int kImageLongSide = 2000;

/// A photo above this many bytes is redrawn even when its size is fine.
const int kImageKeepBytes = 1500000;

/// The JPEG quality of a redrawn photo.
const int kImageJpegQuality = 85;

const _known = {'image/png', 'image/jpeg', 'image/gif', 'image/webp'};

typedef ShrunkImage = ({Uint8List bytes, String mediaType, String name});

/// The photo as the model gets it, or null when it cannot be decoded (then it is a file).
/// [mediaType] is what the system said; without it the file's extension decides.
Future<ShrunkImage?> shrinkForModel(String name, Uint8List bytes, {String? mediaType}) =>
    compute(_shrink, (name: name, bytes: bytes, mediaType: mediaType));

ShrunkImage? _shrink(({String name, Uint8List bytes, String? mediaType}) a) {
  final img.Image? decoded;
  try {
    decoded = img.decodeImage(a.bytes);
  } on Object {
    return null;
  }
  if (decoded == null || decoded.width == 0 || decoded.height == 0) return null;
  final name = a.name.isEmpty ? 'image.jpg' : a.name;
  final raw = a.mediaType?.toLowerCase().split(';').first.trim();
  final type = raw == 'image/jpg' ? 'image/jpeg' : (raw ?? imageTypeOf(a.name));
  final known = type != null && _known.contains(type);
  final scale = math.min(1.0, kImageLongSide / math.max(decoded.width, decoded.height));
  if (known && scale >= 1 && a.bytes.length <= kImageKeepBytes) {
    return (bytes: a.bytes, mediaType: type, name: name);
  }
  final w = math.max(1, (decoded.width * scale).round());
  final h = math.max(1, (decoded.height * scale).round());
  final frame = decoded.frames.first;
  final sized = scale < 1
      ? img.copyResize(frame, width: w, height: h, interpolation: img.Interpolation.average)
      : frame;
  final canvas = img.Image(width: w, height: h, numChannels: 3);
  img.fill(canvas, color: img.ColorRgb8(255, 255, 255));
  img.compositeImage(canvas, sized);
  final jpeg = img.encodeJpg(canvas, quality: kImageJpegQuality);
  return (bytes: jpeg, mediaType: 'image/jpeg', name: name);
}

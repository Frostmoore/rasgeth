// Ctrl+V (Cmd+V on macOS) in a conversation's composer (3.8.3): files copied in Explorer, Finder or
// a file manager, or an image on the clipboard (a screenshot), become attachments with the same
// rules as «Attach» (`classify`); with text on the clipboard the field pastes it as before. The
// clipboard is read with `pasteboard` (Windows, macOS, Linux; images on iOS and Android too).
// On a phone the keyboard's own image insertion goes the same way (`contentInsertion`).
import 'dart:async';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:pasteboard/pasteboard.dart';

typedef PastedFile = (String name, Uint8List bytes);

/// What the clipboard holds, as the composer needs it.
abstract class ClipboardReader {
  const ClipboardReader();

  /// Files copied from the computer's file manager (folders left out).
  Future<List<PastedFile>> files();

  /// An image on the clipboard, in whatever form the system gives it.
  Future<Uint8List?> image();

  /// Text on the clipboard.
  Future<bool> hasText();
}

class SystemClipboardReader extends ClipboardReader {
  const SystemClipboardReader();

  static bool get _desktop =>
      !kIsWeb && (Platform.isWindows || Platform.isMacOS || Platform.isLinux);

  @override
  Future<List<PastedFile>> files() async {
    // On Android the paths are content URIs, on iOS there are none: computers only.
    if (!_desktop) return const [];
    final out = <PastedFile>[];
    for (final path in await Pasteboard.files()) {
      final f = File(path);
      if (!f.existsSync()) continue;
      try {
        out.add((f.uri.pathSegments.lastWhere((s) => s.isNotEmpty), await f.readAsBytes()));
      } on Object {
        // A file the system does not let us read: left out.
      }
    }
    return out;
  }

  @override
  Future<Uint8List?> image() => Pasteboard.image;

  @override
  Future<bool> hasText() => Clipboard.hasStrings();
}

/// The clipboard the composers read (tests put a fake one here).
ClipboardReader clipboardReader = const SystemClipboardReader();

/// The media type of an image the server takes, from its first bytes.
String? sniffImage(Uint8List b) {
  bool at(List<int> sig, [int from = 0]) {
    if (b.length < from + sig.length) return false;
    for (var i = 0; i < sig.length; i++) {
      if (b[from + i] != sig[i]) return false;
    }
    return true;
  }

  if (at([0x89, 0x50, 0x4E, 0x47])) return 'image/png';
  if (at([0xFF, 0xD8, 0xFF])) return 'image/jpeg';
  if (at([0x47, 0x49, 0x46, 0x38])) return 'image/gif';
  if (at([0x52, 0x49, 0x46, 0x46]) && at([0x57, 0x45, 0x42, 0x50], 8)) return 'image/webp';
  return null;
}

/// `pasted-YYYY-MM-DD-hhmmss.<ext>`, as the page names what is pasted.
String pastedName(DateTime at, String ext) {
  String two(int n) => n.toString().padLeft(2, '0');
  return 'pasted-${at.year}-${two(at.month)}-${two(at.day)}-'
      '${two(at.hour)}${two(at.minute)}${two(at.second)}.$ext';
}

/// A clipboard image as a file the server takes: PNG, JPEG, GIF and WebP as they are, anything
/// else (the BMP Windows gives) turned into PNG; null when it cannot be read.
Future<PastedFile?> pastedImage(Uint8List bytes, {DateTime? now}) async {
  final at = now ?? DateTime.now();
  final type = sniffImage(bytes);
  if (type != null)
    return (pastedName(at, type == 'image/jpeg' ? 'jpg' : type.split('/').last), bytes);
  try {
    final codec = await ui.instantiateImageCodec(bytes);
    final frame = await codec.getNextFrame();
    final png = await frame.image.toByteData(format: ui.ImageByteFormat.png);
    frame.image.dispose();
    codec.dispose();
    if (png == null) return null;
    return (pastedName(at, 'png'), png.buffer.asUint8List());
  } on Object {
    return null;
  }
}

/// What a paste should attach: copied files first; then nothing when there is text (the field
/// pastes it); then the image.
Future<List<PastedFile>> readPastedFiles(ClipboardReader r) async {
  try {
    final files = await r.files();
    if (files.isNotEmpty) return files;
    if (await r.hasText()) return const [];
    final img = await r.image();
    if (img == null || img.isEmpty) return const [];
    final p = await pastedImage(img);
    return p == null ? const [] : [p];
  } on Object {
    // No clipboard plugin (or a broken one): the field pastes as before.
    return const [];
  }
}

/// [child]'s text field: a paste with files or an image calls [onFiles]; with text, the field's
/// own paste.
class PasteFiles extends StatelessWidget {
  const PasteFiles({super.key, required this.onFiles, required this.child});

  final ValueChanged<List<PastedFile>> onFiles;
  final Widget child;

  @override
  Widget build(BuildContext context) =>
      Actions(actions: {PasteTextIntent: _PasteAction(onFiles)}, child: child);
}

class _PasteAction extends Action<PasteTextIntent> {
  _PasteAction(this.onFiles);

  final ValueChanged<List<PastedFile>> onFiles;

  @override
  bool isEnabled(PasteTextIntent intent) => callingAction?.isEnabled(intent) ?? true;

  @override
  Object? invoke(PasteTextIntent intent) {
    // The field's own paste: only reachable now, while it calls this one.
    final own = callingAction;
    unawaited(() async {
      final files = await readPastedFiles(clipboardReader);
      if (files.isNotEmpty) {
        onFiles(files);
      } else {
        own?.invoke(intent);
      }
    }());
    return null;
  }
}

/// The keyboard's image insertion on a phone (Gboard's clipboard, stickers): as an attachment.
ContentInsertionConfiguration contentInsertion(ValueChanged<List<PastedFile>> onFiles) =>
    ContentInsertionConfiguration(
      onContentInserted: (c) async {
        final data = c.data;
        if (data == null || data.isEmpty) return;
        final p = await pastedImage(data);
        if (p != null) onFiles([p]);
      },
    );

// What goes with a message (G40.10), as the page's composer does it (`packMessage` in
// packages/web/src/components/Composer.tsx): photos go to the model as images, small text files
// inside the message, anything else is written to `.attachments/YYYY-MM-DD/` in the agent's
// workspace (its project's, or God's) and the message names its path. The composer and
// «Share to RedGiant» use the same rules.
import 'dart:convert';
import 'dart:typed_data';

import 'types.dart';

const int kMaxImageBytes = 5 * 1024 * 1024;
const int kMaxFileBytes = 25 * 1024 * 1024;
const int kMaxTextChars = 200000;
const int kMaxAttached = 10;

const _imageTypes = {'image/png', 'image/jpeg', 'image/gif', 'image/webp'};
final _textNames = RegExp(
  r'\.(txt|md|csv|tsv|json|ya?ml|toml|ini|xml|html?|css|js|mjs|cjs|ts|tsx|jsx|py|rb|go|rs|java|kt|c|h|cpp|hpp|cs|php|sh|sql|log|env\.example)$',
  caseSensitive: false,
);
final _textTypes = RegExp(r'^(text/|application/(json|xml|javascript|x-yaml|x-sh|toml))');

sealed class Attached {
  const Attached(this.name);

  final String name;
}

class AttachedImage extends Attached {
  const AttachedImage(super.name, this.mediaType, this.bytes);

  final String mediaType;
  final Uint8List bytes;
}

class AttachedText extends Attached {
  const AttachedText(super.name, this.content);

  final String content;
}

class AttachedFile extends Attached {
  const AttachedFile(super.name, this.bytes);

  final Uint8List bytes;
}

/// The image types the server takes, from the media type or the file's extension.
String? imageTypeOf(String name, [String? mimeType]) {
  final m = mimeType?.toLowerCase().split(';').first.trim();
  if (m != null && _imageTypes.contains(m)) return m == 'image/jpg' ? 'image/jpeg' : m;
  return switch (name.split('.').last.toLowerCase()) {
    'png' => 'image/png',
    'jpg' || 'jpeg' => 'image/jpeg',
    'gif' => 'image/gif',
    'webp' => 'image/webp',
    _ => null,
  };
}

/// A file as the composer holds it, or null when it is too big to send at all.
Attached? classify(String name, Uint8List bytes, {String? mimeType}) {
  final image = imageTypeOf(name, mimeType);
  if (image != null && bytes.length <= kMaxImageBytes) return AttachedImage(name, image, bytes);
  final texty = (mimeType != null && _textTypes.hasMatch(mimeType)) || _textNames.hasMatch(name);
  if (texty && bytes.length <= kMaxTextChars) {
    try {
      return AttachedText(name, utf8.decode(bytes));
    } on FormatException {
      // Not UTF-8 after all: a file.
    }
  }
  if (bytes.length > kMaxFileBytes) return null;
  return AttachedFile(name, bytes);
}

/// The workspace an agent's attachments land in: its project's, or God's.
String attachmentScope(Agent? a) => a?.projectId != null ? 'project:${a!.projectId}' : 'platform';

/// A name that is safe as a file name inside the workspace.
String safeFileName(String name) {
  final s = name
      .replaceAll(RegExp(r'[^\p{L}\p{N}._\- ()]+', unicode: true), '_')
      .replaceFirst(RegExp(r'^\.+'), '');
  return s.isEmpty ? 'file' : s;
}

typedef Upload = Future<void> Function(String path, Uint8List bytes);

/// The message's text and images, files written with [upload] first (none: named as not sent).
Future<({String text, List<Map<String, Object?>> images})> packMessage(
  String text,
  List<Attached> files, {
  Upload? upload,
  String notSent = 'not sent',
  DateTime? now,
}) async {
  final out = StringBuffer(text);
  final images = <Map<String, Object?>>[];
  final at = now ?? DateTime.now();
  final day = at.toUtc().toIso8601String().substring(0, 10);
  var n = 0;
  for (final f in files) {
    switch (f) {
      case AttachedText(:final name, :final content):
        out.write('\n\n<attachment name="$name">\n$content\n</attachment>');
      case AttachedImage(:final name, :final mediaType, :final bytes):
        images.add({
          'type': 'image',
          'mediaType': mediaType,
          'data': base64.encode(bytes),
          'name': name,
        });
      case AttachedFile(:final name, :final bytes):
        if (upload != null) {
          final stamp = (at.millisecondsSinceEpoch + n++).toRadixString(36);
          final path = '.attachments/$day/$stamp-${safeFileName(name)}';
          await upload(path, bytes);
          out.write('\n\n<attachment name="$name" path="$path" size="${bytes.length}" />');
        } else {
          out.write('\n\n<attachment name="$name" size="${bytes.length}">($notSent)</attachment>');
        }
    }
  }
  return (text: out.toString(), images: images);
}

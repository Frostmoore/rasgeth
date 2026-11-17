// A long paste becomes a file (G42.1, the page's p3.3.1, as ChatGPT and Claude do): a port of
// `PASTE_CHARS`, `PASTE_LINES`, `pastedExt` and `pastedAttachment` of
// packages/web/src/components/Composer.tsx. The file travels as `AttachedPasted`
// (lib/api/attachments.dart): saved in `.attachments/<day>/` and, when not too long, its text
// inside the message too.
import 'dart:convert';

import 'attachments.dart';

/// A paste longer than this (characters, UTF-16 as in JavaScript) becomes a file.
const int kPasteChars = 2000;

/// A paste with more lines than this becomes a file.
const int kPasteLines = 40;

final _markdownLine = RegExp(r'^(#{1,6} |```|[-*+] |\d+\. |> |\|.*\|)');

/// The kind of text a paste is, for its file's extension: json, csv, md or txt.
String pastedExt(String text) {
  final s = text.trim();
  if (s.startsWith('[') || s.startsWith('{')) {
    try {
      jsonDecode(s);
      return 'json';
    } on FormatException {
      // Not JSON after all.
    }
  }
  final lines = s.split(RegExp(r'\r?\n')).where((l) => l.trim().isNotEmpty).take(50).toList();
  for (final sep in [',', ';', '\t']) {
    final counts = [for (final l in lines) l.split(sep).length - 1];
    if (lines.length >= 3 && counts.first >= 1 && counts.every((c) => c == counts.first)) {
      return 'csv';
    }
  }
  final marks = lines.where(_markdownLine.hasMatch).length;
  if (marks >= 2) return 'md';
  return 'txt';
}

/// A pasted text as an attachment when it is long (over [kPasteChars] characters or
/// [kPasteLines] lines), named after the local moment: pasted-2026-11-07-183012.md. Null for a
/// short paste.
AttachedPasted? pastedAttachment(String text, {DateTime? now}) {
  final lines = (text.endsWith('\n') ? text.substring(0, text.length - 1) : text)
      .split('\n')
      .length;
  if (text.length <= kPasteChars && lines <= kPasteLines) return null;
  final t = (now ?? DateTime.now()).toLocal();
  String two(int n) => n.toString().padLeft(2, '0');
  final stamp =
      '${t.year}-${two(t.month)}-${two(t.day)}-${two(t.hour)}${two(t.minute)}${two(t.second)}';
  return AttachedPasted('pasted-$stamp.${pastedExt(text)}', text);
}

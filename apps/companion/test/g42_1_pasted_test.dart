// Long pastes (G42.1): the same rules and the same message as the page's composer (the cases of
// packages/web/test/ui.test.tsx, «long pastes (p3.3.1)»).
import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:rgcompanion/api/attachments.dart';
import 'package:rgcompanion/api/pasted.dart';

void main() {
  test('become files past 2,000 characters or 40 lines, named and typed by their content', () {
    final at = DateTime(2026, 11, 7, 18, 30, 12);
    expect(pastedAttachment('a' * 2000, now: at), isNull);
    expect(pastedAttachment('a\n' * 40, now: at), isNull);
    final long = pastedAttachment('a' * 2001, now: at)!;
    expect(long.name, 'pasted-2026-11-07-183012.txt');
    expect(long.content, 'a' * 2001);
    expect(pastedAttachment('a\n' * 41, now: at)?.name, 'pasted-2026-11-07-183012.txt');
    expect(pastedAttachment('# T\n\n- one\n${'- x\n' * 50}', now: at)?.name, endsWith('.md'));
    expect(
      pastedAttachment('x' * 3000, now: DateTime(2026, 1, 2, 3, 4, 5))?.name,
      'pasted-2026-01-02-030405.txt',
    );
    expect(pastedExt('{"a": [1, 2]}'), 'json');
    expect(pastedExt('a,b,c\n1,2,3\n4,5,6'), 'csv');
    expect(pastedExt('# Title\n\n- one\n- two'), 'md');
    expect(pastedExt('just words\nand more'), 'txt');
    expect(pastedExt('{not json'), 'txt');
    expect(pastedExt('a;b\n1;2\n3;4'), 'csv');
    expect(pastedExt('a\tb\n1\t2\n3\t4'), 'csv');
    expect(pastedExt('a,b\n1,2'), 'txt', reason: 'three lines at least');
    expect(pastedExt(''), 'txt');
  });

  test('are saved in .attachments and travel with their text', () async {
    final uploads = <(String, Uint8List)>[];
    final content = 'x' * 3000;
    final msg = await packMessage('see', [
      AttachedPasted('pasted-2026-11-07-183012.txt', content),
    ], upload: (path, bytes) async => uploads.add((path, bytes)));
    expect(
      uploads.single.$1,
      matches(RegExp(r'^\.attachments/\d{4}-\d{2}-\d{2}/[a-z0-9]+-pasted-2026-11-07-183012\.txt$')),
    );
    expect(utf8.decode(uploads.single.$2), content);
    expect(
      msg.text,
      'see\n\n<attachment name="pasted-2026-11-07-183012.txt" path="${uploads.single.$1}" '
      'size="3000" pasted="true">\n$content\n</attachment>',
    );
    expect(msg.images, isEmpty);
    // Without a workspace (a room): inline only.
    final room = await packMessage('see', [AttachedPasted('p.txt', content)]);
    expect(room.text, contains('<attachment name="p.txt" pasted="true">\n$content'));
  });

  test('the size is in bytes, and a text too long to carry stays in the file only', () async {
    final uploads = <String>[];
    final accented = 'è' * 2500;
    final a = await packMessage('', [
      AttachedPasted('a.txt', accented),
    ], upload: (path, bytes) async => uploads.add(path));
    expect(a.text, contains('size="5000" pasted="true">\n$accented\n</attachment>'));
    final huge = 'y' * (kMaxTextChars + 1);
    final b = await packMessage('', [
      AttachedPasted('b.txt', huge),
    ], upload: (path, bytes) async => uploads.add(path));
    expect(
      b.text,
      '\n\n<attachment name="b.txt" path="${uploads.last}" size="${huge.length}" '
      'pasted="true" />',
    );
    // In a room it is cut at the limit instead.
    final c = await packMessage('', [AttachedPasted('c.txt', huge)]);
    expect(
      c.text,
      '\n\n<attachment name="c.txt" pasted="true">\n${'y' * kMaxTextChars}\n</attachment>',
    );
    // The bubble shows its name and path, as for any saved file.
    expect(splitAttachments('hi${a.text}').files.single, (name: 'a.txt', path: uploads.first));
  });
}

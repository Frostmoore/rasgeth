// Attachments as the page's composer packs them (G40.10), for the composer and «Share to
// RedGiant»: photos as images, small text files inside the message, the rest written to the
// agent's workspace with its path in the text; the Share sheet's items into the message.
import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:rgcompanion/api/attachments.dart';
import 'package:rgcompanion/api/types.dart';
import 'package:rgcompanion/screens/share_screen.dart';
import 'package:rgcompanion/share/share_intake.dart';

Uint8List _b(int n) => Uint8List(n);

void main() {
  test('classify: photos, text, files, too big', () {
    expect(classify('a.png', _b(10)), isA<AttachedImage>());
    expect(
      (classify('a', _b(10), mimeType: 'image/jpeg')! as AttachedImage).mediaType,
      'image/jpeg',
    );
    expect(classify('notes.md', Uint8List.fromList(utf8.encode('# Ciao'))), isA<AttachedText>());
    expect(
      classify('x', Uint8List.fromList(utf8.encode('{}')), mimeType: 'application/json'),
      isA<AttachedText>(),
    );
    expect(classify('report.pdf', _b(1000)), isA<AttachedFile>());
    // A photo over 5 MB is saved as a file; over 25 MB nothing is sent.
    expect(classify('big.jpg', _b(6 * 1024 * 1024)), isA<AttachedFile>());
    expect(classify('huge.bin', _b(26 * 1024 * 1024)), isNull);
    // Not UTF-8 after all: a file.
    expect(classify('bad.txt', Uint8List.fromList([0xff, 0xfe, 0xfd])), isA<AttachedFile>());
  });

  test('packMessage: inline text, images as parts, files uploaded with their path', () async {
    final uploads = <String, int>{};
    final out = await packMessage(
      'Guarda',
      [
        AttachedText('n.txt', 'riga'),
        AttachedImage('p.png', 'image/png', _b(3)),
        AttachedFile('r.pdf', _b(5)),
      ],
      upload: (path, bytes) async => uploads[path] = bytes.length,
      now: DateTime.utc(2026, 11, 16, 10),
    );
    expect(out.text, startsWith('Guarda\n\n<attachment name="n.txt">\nriga\n</attachment>'));
    final path = uploads.keys.single;
    expect(path, startsWith('.attachments/2026-11-16/'));
    expect(path, endsWith('-r.pdf'));
    expect(out.text, contains('<attachment name="r.pdf" path="$path" size="5" />'));
    expect(out.images.single['mediaType'], 'image/png');
    expect(out.images.single['data'], base64.encode(_b(3)));
  });

  test('without an upload a file is named as not sent', () async {
    final out = await packMessage('x', [AttachedFile('r.pdf', _b(5))], notSent: 'non inviato');
    expect(out.text, contains('<attachment name="r.pdf" size="5">(non inviato)</attachment>'));
  });

  test('the workspace: the agent project, else God', () {
    const a = Agent(id: 'a', kind: AgentKind.agent, name: 'A', active: true, projectId: 'p1');
    expect(attachmentScope(a), 'project:p1');
    expect(attachmentScope(null), 'platform');
    expect(safeFileName('../a b?.txt'), '_a b_.txt');
  });

  test('what is shared makes the message, the note first', () {
    final items = [
      const SharedItem(kind: SharedKind.url, text: 'https://example.com/a'),
      const SharedItem(kind: SharedKind.text, text: '  un pezzo di testo '),
      const SharedItem(kind: SharedKind.image, path: '/tmp/p.jpg'),
    ];
    expect(sharedText('Leggi', items), 'Leggi\n\nhttps://example.com/a\n\nun pezzo di testo');
    expect(sharedText('', items.sublist(2)), '');
  });
}

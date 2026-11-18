// G42.0: the bridge's messages as the page's protocol takes them (test/fixtures/embed_vectors.json):
// the page's envelopes taken only with the nonce and only well formed, each to its handler; the
// app's messages as the page reads them, and none it would refuse.
import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:rgcompanion/embed/bridge.dart';

void main() {
  final v = jsonDecode(File('test/fixtures/embed_vectors.json').readAsStringSync()) as Map;
  final nonce = v['nonce'] as String;

  test('every envelope taken or refused as the page does', () {
    for (final e in (v['envelopes'] as List).cast<Map<String, Object?>>()) {
      expect(readEmbedEnvelope(e['raw'] as String, nonce), e['message'], reason: '${e['raw']}');
    }
  });

  test('each message reaches its handler', () {
    final got = <String>[];
    final b = EmbedBridge(
      nonce: nonce,
      run: (_) async {},
      handlers: EmbedHandlers(
        ready: () => got.add('ready'),
        title: (n, k, s) => got.add('title $n $k $s'),
        saveState: (s, e) => got.add('save $s $e'),
        saveAs: (n, {url, data, mime}) => got.add('saveAs $n $url $data'),
        openFile: (id, a, m) => got.add('open $id $a $m'),
        copy: (t) => got.add('copy $t'),
        share: ({title, text, url}) => got.add('share $url'),
        askAgent: (t, r) => got.add('ask $t ${r['line']}'),
        external: (u) => got.add('external $u'),
        previewLink: (u) => got.add('previewLink $u'),
        close: () => got.add('close'),
        back: (h) => got.add('back $h'),
      ),
    );
    for (final e in (v['envelopes'] as List).cast<Map<String, Object?>>()) {
      b.handle(e['raw'] as String);
    }
    expect(got, [
      'ready',
      'title a.xlsx sheet 2048',
      'title b null null',
      'save saving null',
      'save error disk full',
      'saveAs a.pdf /api/files/raw?x=1 null',
      'saveAs a.txt null aGVsbG8=',
      'open f1 [.png] true',
      'copy x',
      'share https://example.com/a',
      'share null',
      'ask why this? 3',
      'ask page null',
      'external https://example.com',
      'previewLink https://example.com/a?b=1',
      'close',
      'back false',
      // The editors (G42.7).
      'save saved null',
      'saveAs foto.png null iVBORw0KGgo=',
      'ask riga\naltra 4',
    ]);
  });

  test('the app\'s messages: the ones the page takes, as a script posted to its own window', () {
    for (final m in (v['appMessages'] as List).cast<Map<String, Object?>>()) {
      final msg = m.cast<String, Object?>();
      expect(appToEmbedOk(msg), isTrue, reason: '$m');
      final s = appMessageScript(msg);
      expect(s, startsWith('window.postMessage({"rg":"app","m":'));
      expect(s, endsWith(', location.origin);'));
    }
    expect(appToEmbedOk({'t': 'key', 'key': 'quit'}), isFalse);
    expect(appToEmbedOk({'t': 'font', 'family': 'a;}'}), isFalse);
    expect(appToEmbedOk({'t': 'back', 'x': 1}), isFalse);
    expect(() => appMessageScript({'t': 'shell'}), throwsArgumentError);
  });

  test('the helpers write what the page takes', () async {
    final sent = <String>[];
    final b = EmbedBridge(
      nonce: nonce,
      run: (s) async => sent.add(s),
      handlers: const EmbedHandlers(),
    );
    await b.theme(dark: true);
    await b.lang('en');
    await b.key(EmbedKey.redo);
    await b.files([embedFile('a.txt', 'text/plain', utf8.encode('hi'))], id: 'f1');
    await b.paste(text: 'x');
    await b.back();
    expect(sent, hasLength(6));
    expect(sent[3], contains('"data":"aGk="'));
  });

  test('G42.7: the app\'s messages the page refuses, the app refuses too', () {
    for (final m in (v['badAppMessages'] as List).cast<Map<String, Object?>>()) {
      expect(appToEmbedOk(m.cast<String, Object?>()), isFalse, reason: '$m');
    }
  });

  test(
    'G42.7: the editors\' bar (paste, read only, «Ask the agent») and the pasted picture',
    () async {
      final bars = <EmbedBar>[];
      final asked = <String>[];
      final b = EmbedBridge(
        nonce: nonce,
        run: (_) async {},
        handlers: EmbedHandlers(
          bar: bars.add,
          askAgent: (t, r) =>
              asked.add('$t|${r['scope']}|${r['path']}|${r['line']}-${r['lineEnd']}'),
        ),
      );
      for (final e in (v['envelopes'] as List).cast<Map<String, Object?>>()) {
        b.handle(e['raw'] as String);
      }
      final ask = bars.where((x) => x.actions.any((a) => a.id == embedAskAction)).single;
      expect(ask.actions.single.icon, 'chat');
      expect(ask.actions.single.primary, isTrue);
      expect(bars.where((x) => x.paste).length, 1);
      final ro = bars.where((x) => x.readOnly).single;
      expect(ro.download, isTrue);
      expect(ro.paste, isFalse);
      expect(asked, contains('riga\naltra|project:p1|src/a.ts|4-9'));

      final sent = <String>[];
      final out = EmbedBridge(
        nonce: nonce,
        run: (s) async => sent.add(s),
        handlers: const EmbedHandlers(),
      );
      final png = [0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A];
      await out.paste(files: [embedFile('pasted.png', 'image/png', png)]);
      await out.action(embedAskAction);
      final m = jsonDecode(
        sent[0].substring('window.postMessage('.length, sent[0].lastIndexOf(', location.origin);')),
      ) as Map;
      expect(m['m'], {
        't': 'paste',
        'files': [
          {'name': 'pasted.png', 'type': 'image/png', 'size': 8, 'data': 'iVBORw0KGgo='},
        ],
      });
      // The page's own vector carries the same bytes, as the app encodes them.
      final vec = (v['appMessages'] as List).cast<Map<String, dynamic>>().firstWhere(
        (x) => x['t'] == 'paste' && ((x['files'] as List?) ?? const []).isNotEmpty,
      );
      expect(((vec['files'] as List).single as Map)['data'], 'iVBORw0KGgo=');
      expect(sent[1], contains('"t":"action","id":"ask"'));
    },
  );
}

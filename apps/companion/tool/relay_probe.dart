// 3.8.7: the app's preview relay against a real RedGiant (the demo with DEMO_ARTIFACTS=1), for a
// real browser engine to load (tool/frame_probe.mjs): the widget of God's humidity answer and the
// CSV explorer artifact, through the very routes the app uses. Writes what the probe needs (the
// wrappers' addresses and nonces) as JSON to the given file, then keeps serving until killed.
//
//   dart run tool/relay_probe.dart <demo log> <out.json>
import 'dart:convert';
import 'dart:io';

import 'package:rgcompanion/api/preview_relay.dart';

Future<void> main(List<String> args) async {
  final demo = File(args[0])
      .readAsLinesSync()
      .where((l) => l.startsWith('{') && l.contains('widgetSession'))
      .map((l) => jsonDecode(l) as Map<String, dynamic>)
      .last;
  final base = Uri.parse((demo['url'] as String).replaceFirst('0.0.0.0', '127.0.0.1'));
  final token = demo['token'] as String;
  final http = HttpClient();
  Future<Object?> call(String method, String path, [Object? body]) async {
    final q = await http.openUrl(method, base.resolve(path));
    q.headers.set('authorization', 'Bearer $token');
    if (body != null) {
      q.headers.contentType = ContentType.json;
      q.write(jsonEncode(body));
    }
    final a = await q.close();
    final text = await utf8.decodeStream(a);
    if (a.statusCode != 200) throw StateError('$method $path: ${a.statusCode} $text');
    return jsonDecode(text);
  }

  // The widget: the answer that carries it, then its link (GET …/widgets/:seq/0/link).
  final events = await call('GET', '/api/sessions/${demo['widgetSession']}/events') as List;
  final seq = events.cast<Map<String, dynamic>>().lastWhere(
    (e) => e['type'] == 'message.assistant' && jsonEncode(e['payload']).contains('```widget'),
  )['seq'];
  final widgetPath =
      (await call('GET', '/api/sessions/${demo['widgetSession']}/widgets/$seq/0/link')
              as Map)['url']
          as String;
  // The artifact: what the agent showed (canvas.show), then POST /api/canvas/link.
  final shown =
      (await call('GET', '/api/sessions/${demo['artifactSession']}/events') as List)
              .cast<Map<String, dynamic>>()
              .lastWhere((e) => e['type'] == 'canvas.show')['payload']['target']
          as Map;
  final link = await call('POST', '/api/canvas/link', {
    'kind': 'file',
    'scope': shown['scope'],
    'path': shown['path'],
  }) as Map;
  if (link['artifact'] != true) throw StateError('not an artifact: $link');

  final relay = await PreviewRelay.forServer(base);
  final w = relay.open(widgetPath, title: 'Umidità');
  final a = relay.open(link['url'] as String, title: 'esplora-csv.html');
  File(args[1]).writeAsStringSync(
    jsonEncode({
      'origin': relay.origin,
      'widget': {'wrapper': '${w.wrapper}', 'nonce': w.nonce, 'path': widgetPath},
      'artifact': {'wrapper': '${a.wrapper}', 'nonce': a.nonce, 'path': link['url']},
    }),
  );
  stdout.writeln('relay on ${relay.origin}');
}

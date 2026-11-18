// The app's pure rules, as tables: how a Rasgeth is reached, what discovery keeps, the
// conversation's items, the mascots' states, the artifact's document, the Chat's days.
import 'package:flutter_test/flutter_test.dart';
import 'package:rgcompanion/api/conversation.dart';
import 'package:rgcompanion/api/discovery.dart';
import 'package:rgcompanion/api/live_model.dart';
import 'package:rgcompanion/api/transport.dart';
import 'package:rgcompanion/api/types.dart';
import 'package:rgcompanion/screens/activity_screen.dart';
import 'package:rgcompanion/screens/canvas_screen.dart';
import 'package:rgcompanion/screens/chat_screen.dart';
import 'package:rgcompanion/ui/markdown.dart';

Map<String, dynamic> ev(int seq, String type, Map<String, dynamic> p) => {
  'seq': seq,
  'ts': '2026-11-15T10:00:00.000Z',
  'type': type,
  'payload': p,
};

void main() {
  test('transportFor: plain http only to this machine; never in clear over the network', () {
    final table = <(String, bool, TransportKind)>[
      ('http://127.0.0.1:7600', false, TransportKind.loopback),
      ('http://localhost:7600', false, TransportKind.loopback),
      ('http://[::1]:7600', false, TransportKind.loopback),
      ('http://10.42.0.1', false, TransportKind.channel),
      ('http://192.168.1.20:7600', false, TransportKind.channel),
      ('http://rasgeth.local:7600', true, TransportKind.channel),
      ('https://rasgeth.local', true, TransportKind.pinnedHttps),
      ('https://rasgeth.local', false, TransportKind.publicHttps),
      ('https://casa.tail1234.ts.net', false, TransportKind.publicHttps),
    ];
    for (final (url, ca, kind) in table) {
      expect(transportFor(Uri.parse(url), hasCa: ca), kind, reason: url);
    }
    expect(isSetupNetworkHost('10.42.0.1'), isTrue);
    expect(isSetupNetworkHost('10.42.0.2'), isFalse);
  });

  test('discovery keeps an IPv4 address first, else the .local name; the channel path', () {
    final f = foundFrom(
      name: 'Rasgeth on casa',
      addresses: ['fe80::1', '192.168.1.20'],
      hostname: 'casa.local.',
      port: 7600,
      attributes: {'channel': '/api/setup-channel', 'proto': '1'},
    )!;
    expect(f.host, '192.168.1.20');
    expect(f.base.toString(), 'http://192.168.1.20:7600');
    expect(f.machine, 'casa');
    expect(f.proto, 1);
    // A server older than 3.9.0 still announces itself with the old name.
    expect(
      foundFrom(
        name: 'RedGiant on salotto',
        addresses: ['192.168.1.21'],
        hostname: 'salotto.local.',
        port: 7600,
      )!.machine,
      'salotto',
    );
    expect(
      foundFrom(name: 'x', addresses: ['fe80::1'], hostname: 'casa.local.', port: 7600)!.host,
      'casa.local',
    );
    expect(foundFrom(name: 'x', addresses: const [], port: 7600), isNull);
    // A record cannot send the app elsewhere than an API path.
    expect(
      foundFrom(
        name: 'x',
        addresses: ['10.0.0.2'],
        port: 7600,
        attributes: {'channel': 'https://evil.example/'},
      )!.channelPath,
      '/api/setup-channel',
    );
  });

  test('buildItems: user, answer with reasoning, tools closed, hidden ones, erased', () {
    final events = [
      ev(1, 'message.user', {'text': 'Ciao'}),
      ev(2, 'message.user', {'text': 'internal', 'from': 'redgiant'}),
      ev(3, 'message.assistant', {
        'parts': [
          {'type': 'thinking', 'text': 'hmm'},
          {'type': 'text', 'text': 'Eseguo'},
          {'type': 'tool_call', 'callId': 'c1', 'name': 'run_command', 'input': {}},
        ],
        'stopReason': 'tool_use',
      }),
      ev(4, 'tool.call', {
        'callId': 'c1',
        'tool': 'run_command',
        'input': {'command': 'ls'},
      }),
      ev(5, 'tool.call', {'callId': 'c2', 'tool': 'ask_user', 'input': {}}),
      ev(6, 'tool.result', {'callId': 'c1', 'ok': true, 'output': 'a b'}),
      ev(7, 'tool.call', {'callId': 'c3', 'tool': 'read_file', 'input': {}}),
      ev(8, 'message.assistant', {
        'parts': [
          {'type': 'text', 'text': 'Fatto'},
        ],
        'stopReason': 'end_turn',
      }),
      {'seq': 9, 'ts': '', 'type': 'message.user', 'erased': true, 'payload': null},
      ev(10, 'canvas.show', {
        'title': 'Report',
        'target': {'kind': 'file', 'scope': 'project:demo', 'path': 'docs/report.pdf'},
      }),
    ].map(RgEvent.fromJson).toList();
    final items = buildItems(events, liveText: 'Sto', liveThinking: '');
    expect(items.whereType<UserItem>().map((u) => u.text), ['Ciao']);
    final tools = items.whereType<ToolItem>().toList();
    expect(tools.map((t) => t.tool), ['run_command', 'read_file']);
    expect(tools.first.ok, isTrue);
    // Without a result when the turn ended: closed as not done.
    expect(tools.last.ok, isFalse);
    final answers = items.whereType<AssistantItem>().toList();
    expect(answers.first.thinking, 'hmm');
    expect(answers.first.text, 'Eseguo');
    expect(answers.last.live, isTrue);
    expect(items.whereType<NoticeItem>().single.text, contains('erased'));
    final canvas = items.whereType<CanvasItem>().single;
    expect((canvas.scope, canvas.path, canvas.isFile), ('project:demo', 'docs/report.pdf', true));
  });

  test('todos and verifiers of a conversation', () {
    final events = [
      ev(1, 'tool.call', {
        'callId': 'a',
        'tool': 'update_todos',
        'input': {
          'todos': [
            {'content': 'x', 'status': 'completed'},
            {'content': 'y', 'status': 'in_progress'},
            {'content': 'z', 'status': 'pending'},
          ],
        },
      }),
      ev(2, 'task.verified', {'taskId': 't1', 'verifier': 'pnpm test', 'passed': false}),
      ev(3, 'task.verified', {'taskId': 't1', 'verifier': 'pnpm test', 'passed': true}),
    ].map(RgEvent.fromJson).toList();
    expect(todosOf(events), (done: 1, total: 3));
    expect(verifiersOf(events).first.passed, isTrue);
    expect(verifiersOf(events), hasLength(2));
  });

  group('mascot states, as the page (mascot-state.ts)', () {
    LiveModel model() => LiveModel()
      ..setSessions([
        const SessionRow(id: 's1', agentId: 'a', createdAt: '2026-11-15T09:00:00Z'),
        const SessionRow(id: 's2', agentId: 'b', createdAt: '2026-11-15T09:00:00Z'),
      ]);

    test('idle, then working, then thinking while the model has not written', () {
      final m = model();
      expect(m.mascotStateOf('a'), MascotState.idle);
      m.apply({'type': 'session.activity', 'sessionId': 's1', 'agentId': 'a', 'state': 'running'});
      expect(m.mascotStateOf('a'), MascotState.work);
      expect(m.inProgress, 1);
      m.view('s1');
      m.apply({'type': 'session.state', 'sessionId': 's1', 'state': 'running'});
      expect(m.mascotStateOf('a'), MascotState.think);
      m.apply({'type': 'delta', 'sessionId': 's1', 'kind': 'thinking', 'text': '...'});
      expect(m.mascotStateOf('a'), MascotState.think);
      m.apply({'type': 'delta', 'sessionId': 's1', 'kind': 'text', 'text': 'Ciao'});
      expect(m.mascotStateOf('a'), MascotState.work);
      m.apply({
        'type': 'event',
        'sessionId': 's1',
        'event': ev(1, 'message.assistant', {'parts': [], 'stopReason': 'tool_use'}),
      });
      // The tools run: working, not thinking.
      expect(m.mascotStateOf('a'), MascotState.work);
      m.apply({'type': 'session.state', 'sessionId': 's1', 'state': 'idle'});
      expect(m.mascotStateOf('a'), MascotState.idle);
      expect(m.inProgress, 0);
    });

    test('waiting for the person beats everything; blocked after a budget', () {
      final m = model();
      m.apply({
        'type': 'permission.request',
        'request': {'requestId': 'r', 'agentId': 'a', 'agentName': 'A', 'danger': <String>[]},
      });
      m.apply({'type': 'session.activity', 'sessionId': 's1', 'agentId': 'a', 'state': 'running'});
      expect(m.mascotStateOf('a'), MascotState.wait);
      expect(m.forYou, 1);
      m.apply({'type': 'permission.closed', 'requestId': 'r', 'decision': 'deny', 'via': 'web'});
      expect(m.forYou, 0);
      expect(m.lastClosedVia, 'web');
      m.view('s2');
      m.apply({
        'type': 'session.history',
        'sessionId': 's2',
        'events': [
          ev(1, 'budget.exceeded', {'scope': 'global', 'limit': 20, 'used': 21}),
        ],
        'lastSeq': 1,
        'incremental': false,
      });
      expect(m.mascotStateOf('b'), MascotState.error);
    });
  });

  test('critical requests: by the server\'s details or by the danger\'s id', () {
    PermissionRequest r(Map<String, dynamic> extra) => PermissionRequest.fromJson({
      'requestId': 'x',
      'agentId': 'a',
      'agentName': 'A',
      'tool': 't',
      'danger': <String>[],
      ...extra,
    });
    expect(r({}).isCritical, isFalse);
    expect(
      r({
        'danger': ['network'],
      }).isCritical,
      isFalse,
    );
    expect(
      r({
        'danger': ['critical-secret'],
      }).isCritical,
      isTrue,
    );
    expect(
      r({
        'critical': [
          {'id': 'critical-payment', 'action': 'pay-tool'},
        ],
      }).isCritical,
      isTrue,
    );
  });

  test("the artifact's document: our policy first, the artifact only inside the sandbox", () {
    const evil =
        '<!-- <head> --><html><head><meta http-equiv="Content-Security-Policy" content="default-src *">'
        '</head><body><script>fetch("https://evil.example")</script>"quoted"</body></html>';
    final doc = artifactDocument(evil);
    final head = doc.substring(0, doc.indexOf('<iframe'));
    expect(head, contains("connect-src 'none'"));
    expect(head, contains("default-src 'none'"));
    expect(doc, contains('<iframe sandbox="allow-scripts allow-forms"'));
    // Nothing of the artifact is markup of our document: all of it is the srcdoc's text.
    expect(doc.split('<script').length, 1);
    expect(doc, isNot(contains('"quoted"')));
    expect(doc, contains('&quot;quoted&quot;'));
    expect(canvasKindOf('a/b.HTML'), CanvasKind.html);
    expect(canvasKindOf('r.pdf'), CanvasKind.pdf);
    expect(canvasKindOf('x.md'), CanvasKind.markdown);
    expect(canvasKindOf('p.webp'), CanvasKind.image);
    expect(canvasKindOf('d.svg'), CanvasKind.svg);
    expect(canvasKindOf('main.py'), CanvasKind.text);
  });

  test('only http(s) and mailto links open, outside the app', () {
    for (final (href, ok) in [
      ('https://example.com', true),
      ('http://example.com', true),
      ('mailto:a@b.c', true),
      ('javascript:alert(1)', false),
      ('file:///etc/passwd', false),
      ('intent://x', false),
      (null, false),
    ]) {
      expect(openableLink(href), ok, reason: href);
    }
  });

  test("the Chat's days and the tasks by agent", () {
    final rows = [
      const SessionRow(id: 'a', agentId: 'c', createdAt: '2026-11-15T08:00:00Z'),
      const SessionRow(
        id: 'b',
        agentId: 'c',
        createdAt: '2026-11-14T08:00:00Z',
        lastAt: '2026-11-15T09:00:00Z',
      ),
      const SessionRow(id: 'd', agentId: 'c', createdAt: '2026-11-13T12:00:00Z'),
    ];
    final days = byDay(rows);
    expect(days, hasLength(2));
    expect(days.first.rows.map((r) => r.id), ['b', 'a']);
    final groups = tasksByAgent([
      const TaskRow(
        id: '1',
        title: 'old',
        agentName: 'Z',
        outcome: TaskOutcome.verified,
        openedAt: '1',
      ),
      const TaskRow(
        id: '2',
        title: 'new',
        agentName: 'Z',
        outcome: TaskOutcome.open,
        openedAt: '2',
      ),
      const TaskRow(
        id: '3',
        title: 'b',
        agentName: 'A',
        outcome: TaskOutcome.verified,
        openedAt: '3',
      ),
    ]);
    // Agents with something in progress first; in progress before done.
    expect(groups.map((g) => g.agent), ['Z', 'A']);
    expect(groups.first.tasks.map((t) => t.title), ['new', 'old']);
  });
}

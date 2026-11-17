// 3.8.9: on the person's Coder (3.8.7) God made a project with an orchestrator and two agents on
// the web page; the Windows app open at the same time still said «no other agents», without the
// project or God's new conversation. The server now says `lists.changed` to every connection of
// the owner when agents, projects or conversation rows change anywhere (core.ts `listsChanged`);
// the fake server sends it from the same routes, and the app reads those lists again at once.
import 'dart:async';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:rgcompanion/api/live.dart';
import 'package:rgcompanion/api/live_model.dart';
import 'package:rgcompanion/api/servers.dart';
import 'package:rgcompanion/api/token_store.dart';
import 'package:rgcompanion/api/types.dart';
import 'package:rgcompanion/app_state.dart';
import 'package:rgcompanion/desktop/wall.dart' show wallAgents;

import 'fake_server.dart';

Future<void> until(
  bool Function() ok, {
  String what = 'condition',
  Duration within = const Duration(seconds: 5),
}) async {
  final end = DateTime.now().add(within);
  while (!ok()) {
    if (DateTime.now().isAfter(end)) throw TimeoutException('$what not met');
    await Future<void>.delayed(const Duration(milliseconds: 20));
  }
}

void main() {
  late FakeRedGiant server;
  setUp(() async {
    HttpOverrides.global = null;
    server = await FakeRedGiant.start();
  });
  tearDown(() => server.close());

  Future<AppController> device(DevicePlatform p) async {
    final a = AppController(tokens: MemoryTokenStore(), prefs: MemoryAppPrefs(), platform: p);
    expect(await a.connect(server.base.toString(), 'secret'), isTrue, reason: '${a.error}');
    await until(() => a.liveStatus == LiveStatus.open, what: 'live');
    addTearDown(a.disconnect);
    return a;
  }

  test('what God makes on the page reaches the wall, the projects and the conversations', () async {
    final pc = await device(DevicePlatform.windows);
    var told = 0;
    pc.addListener(() => told++);
    expect(pc.projects.any((p) => p.id == 'gaia'), isFalse);

    server.projectMadeElsewhere('gaia', 'GAIA ITAS - Plugin WordPress');
    server.agentMadeElsewhere('orch_1', 'Orchestratore', kind: 'orchestrator', projectId: 'gaia');
    server.agentMadeElsewhere('agent_qa', 'Ambiente e QA', projectId: 'gaia', parentId: 'orch_1');
    server.agentMadeElsewhere('agent_dev', 'Sviluppatore plugin', projectId: 'gaia');
    final god = server.sessionMadeElsewhere('a0', title: 'Progetto GAIA');

    await until(() => pc.projects.any((p) => p.id == 'gaia'), what: 'the project');
    await until(
      () => {
        'Orchestratore',
        'Ambiente e QA',
        'Sviluppatore plugin',
      }.every((n) => wallAgents(pc).any((a) => a.name == n)),
      what: 'the agents on the wall',
    );
    await until(() => pc.live.sessions.any((s) => s.id == god), what: "God's conversation");
    // The screens were told (the wall, the mascots' bar and the lists draw from these).
    expect(told, greaterThan(0));
    // A burst is read once per list, not once per message.
    final agentReads = server.requests.where((r) => r == 'GET /api/agents').length;
    expect(agentReads, lessThanOrEqualTo(3));
  });

  test('renamed, archived, a new face: elsewhere, and seen here', () async {
    final pc = await device(DevicePlatform.windows);
    server.sessionChangedElsewhere('s1', {'title': 'Rinominata'});
    await until(
      () => pc.live.sessions.firstWhere((s) => s.id == 's1').title == 'Rinominata',
      what: 'the new title',
    );
    server.sessionChangedElsewhere('s1', {'archived': true});
    await until(() => pc.live.sessions.firstWhere((s) => s.id == 's1').archived, what: 'archived');
    final a = server.agentMadeElsewhere('agent_x', 'Mascotte');
    await until(() => pc.agents.any((x) => x.id == 'agent_x'), what: 'the agent');
    a['mascotSeed'] = 'Mascotte~new';
    server.listsChanged(['agents']);
    await until(
      () => pc.agents.firstWhere((x) => x.id == 'agent_x').mascotSeed == 'Mascotte~new',
      what: 'the new face',
    );
  });

  test('what changed while the link was down is there once it is back', () async {
    final pc = await device(DevicePlatform.windows);
    await server.goDown();
    await until(() => pc.liveStatus != LiveStatus.open, what: 'down');
    // Made while nobody could hear: no message reaches the app.
    server.projectMadeElsewhere('later', 'Più tardi');
    server.agentMadeElsewhere('agent_later', 'Arrivato dopo', projectId: 'later');
    server.down = false;
    pc.socket?.retryNow();
    await until(
      () => pc.liveStatus == LiveStatus.open,
      what: 'back',
      within: const Duration(seconds: 20),
    );
    await until(() => pc.projects.any((p) => p.id == 'later'), what: 'the project');
    await until(() => pc.agents.any((a) => a.id == 'agent_later'), what: 'the agent');
  });

  test('an agent made in the app shows on the other device, and its conversation', () async {
    final phone = await device(DevicePlatform.android);
    final pc = await device(DevicePlatform.windows);
    final made = await phone.createAgent(kind: 'agent', parentId: 'a0', name: 'Dal telefono');
    await until(() => pc.agents.any((a) => a.id == made.id), what: 'the agent on the computer');
    final sid = await phone.client!.newSession(made.id);
    await until(() => pc.live.sessions.any((s) => s.id == sid), what: 'its conversation');
  });

  test('removed, restored, stopped and resumed on another device: this one follows', () async {
    // One message for all of it (`lists.changed`, no `agents.changed` any more).
    final phone = await device(DevicePlatform.android);
    final pc = await device(DevicePlatform.windows);
    expect(pc.agents.any((a) => a.id == 'a3'), isTrue);
    await phone.client!.removeAgent('a3', reason: 'not needed');
    await until(() => !pc.agents.any((a) => a.id == 'a3'), what: 'removed on the computer');
    expect((await pc.removedAgents()).any((r) => r.agent.id == 'a3'), isTrue);
    await phone.client!.restoreAgent('a3');
    await until(() => pc.agents.any((a) => a.id == 'a3'), what: 'back on the computer');
    await phone.client!.stopAgentForGood('a3');
    await until(
      () => pc.agents.any((a) => a.id == 'a3' && !a.active),
      what: 'stopped on the computer',
    );
    await phone.client!.resumeAgent('a3');
    await until(
      () => pc.agents.any((a) => a.id == 'a3' && a.active),
      what: 'resumed on the computer',
    );
  });

  test('a conversation of an agent the app does not know reads the team again', () async {
    final pc = await device(DevicePlatform.windows);
    // An older server: no `lists.changed`, only the activity of a conversation of a new agent.
    server.created.add({
      'id': 'agent_quiet',
      'kind': 'agent',
      'parentId': 'a0',
      'projectId': null,
      'persistent': true,
      'name': 'Silenzioso',
      'mascotSeed': 'Silenzioso',
      'status': 'active',
    });
    server.sessions.add({
      'id': 'sq',
      'agentId': 'agent_quiet',
      'createdAt': '2026-11-17T10:00:00.000Z',
      'lastAt': null,
      'title': null,
      'archived': false,
      'running': false,
    });
    server.turnStart('sq');
    await until(() => pc.agents.any((a) => a.id == 'agent_quiet'), what: 'the agent');
    await until(() => pc.live.sessions.any((s) => s.id == 'sq'), what: 'the conversation');
  });

  test(
    'a link that opens and never says welcome is tried again (a server still starting)',
    () async {
      server.tokens.add('rgd_wait');
      server.mute = true;
      final s = LiveSocket(
        open: () => WebSocket.connect('ws://${server.base.authority}/ws'),
        token: 'rgd_wait',
        welcomeWithin: const Duration(milliseconds: 300),
      );
      addTearDown(s.close);
      final model = LiveModel();
      final sub = s.messages.listen(model.apply);
      addTearDown(sub.cancel);
      unawaited(s.start());
      await until(() => s.status == LiveStatus.down, what: 'given up on the silent link');
      // The server is ready now: the next try gets welcome and the waiting requests.
      server.mute = false;
      server.request({
        'requestId': 'r-after',
        'sessionId': 's1',
        'agentId': 'a0',
        'agentName': 'God',
        'projectId': null,
        'tool': 'run_command',
        'input': {'command': 'ls'},
        'reasons': ['lists files'],
        'danger': <String>[],
        'createdAt': '2026-11-17T10:00:00.000Z',
      });
      await until(
        () => s.status == LiveStatus.open,
        what: 'open',
        within: const Duration(seconds: 10),
      );
      await until(() => model.approvals.any((r) => r.requestId == 'r-after'), what: 'the request');
    },
  );
}

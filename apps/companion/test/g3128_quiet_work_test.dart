// 3.12.8, the person's report («God lavora ma non appare nulla che mostri che sta lavorando»): when the agent works
// and nothing else on screen shows it, a quiet line says it works, since its last step, and the tool under way.
import 'package:flutter_test/flutter_test.dart';
import 'package:rgcompanion/api/conversation.dart';
import 'package:rgcompanion/api/live_model.dart';

RgEvent _ev(int seq, String type, Map<String, dynamic> payload) => RgEvent(
  seq: seq,
  ts: DateTime.utc(2026, 11, 26, 10, 0, seq).toIso8601String(),
  type: type,
  payload: payload,
  sessionId: 's1',
);

SessionView _view(List<RgEvent> events) {
  final v = SessionView('s1')..running = true;
  v.events.addAll(events);
  return v;
}

void main() {
  test('shows between steps, timed from the last one', () {
    final v = _view([
      _ev(1, 'message.user', {'text': 'go'}),
      _ev(2, 'message.assistant', {
        'parts': [
          {'type': 'text', 'text': 'Ok'},
        ],
      }),
    ]);
    final q = quietWork(v, v.items);
    expect(q, isNotNull);
    expect(q!.since, DateTime.utc(2026, 11, 26, 10, 0, 2));
    expect(q.tool, isNull);
  });

  test('names the tool under way when its card is not what shows', () {
    final v = _view([
      _ev(1, 'message.user', {'text': 'go'}),
      _ev(2, 'tool.call', {'callId': 'c1', 'tool': 'fetch', 'input': <String, dynamic>{}}),
    ]);
    // the tool's own card, still turning: nothing more
    expect(quietWork(v, v.items), isNull);
    // when its card is not the last thing on screen, the line names it
    expect(quietWork(v, const [])?.tool, 'fetch');
  });

  test('stays away when something else shows the work, or nothing runs', () {
    final v = _view([
      _ev(1, 'message.user', {'text': 'go'}),
    ]);
    v.liveText = 'Sto';
    expect(quietWork(v, const []), isNull);
    v.liveText = '';
    v.compacting = true;
    expect(quietWork(v, const []), isNull);
    v.compacting = false;
    v.drawing = (percent: 10, preview: null);
    expect(quietWork(v, const []), isNull);
    v.drawing = null;
    v.running = false;
    expect(quietWork(v, const []), isNull);
  });

  test('a tool that answered is not under way any more', () {
    final v = _view([
      _ev(1, 'tool.call', {'callId': 'c1', 'tool': 'fetch', 'input': <String, dynamic>{}}),
      _ev(2, 'tool.result', {'callId': 'c1', 'ok': false, 'output': '404'}),
    ]);
    expect(quietWork(v, const [])?.tool, isNull);
  });
}

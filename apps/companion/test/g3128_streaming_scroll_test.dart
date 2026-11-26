// Scrolling while an agent writes (3.12.8, the user: «l'app lagga quando scorro la conversazione
// mentre l'agente sta scrivendo»): each piece of streamed text built the whole history from every
// event three times and woke the whole app. Now the history is built once per new event and a
// piece of text is news for its conversation only.
import 'package:flutter_test/flutter_test.dart';
import 'package:rgcompanion/api/conversation.dart';
import 'package:rgcompanion/api/live_model.dart';

void main() {
  late LiveModel live;
  setUp(() => live = LiveModel());
  Map<String, dynamic> ev(int seq, String type, [Map<String, dynamic> payload = const {}]) => {
    'type': 'event',
    'sessionId': 's1',
    'event': {
      'id': 'e$seq',
      'seq': seq,
      'ts': '',
      'sessionId': 's1',
      'type': type,
      'payload': payload,
    },
  };
  Map<String, dynamic> delta(String text, [String kind = 'text']) => {
    'type': 'delta',
    'sessionId': 's1',
    'kind': kind,
    'text': text,
  };

  test('the history is built once per event; streamed text only adds the live answer', () {
    live.apply({'type': 'session.state', 'sessionId': 's1', 'state': 'running'});
    live.apply(ev(1, 'message.user', {'text': 'Ciao'}));
    final v = live.view('s1');
    final stored = v.storedItems;
    live.apply(delta('Ecco '));
    live.apply(delta('la risposta'));
    expect(v.storedItems, same(stored));
    final items = v.items;
    expect(items.length, stored.length + 1);
    expect(items.first, same(stored.first));
    expect((items.last as AssistantItem).live, isTrue);
    expect((items.last as AssistantItem).text, 'Ecco la risposta');
    // A new event: built again, with the answer stored.
    live.apply(ev(2, 'message.assistant', {'text': 'Ecco la risposta'}));
    expect(v.storedItems, isNot(same(stored)));
    expect(v.items.whereType<AssistantItem>().single.live, isFalse);
    // «Cancella per sempre» changes events in place: built again too.
    final before = v.storedItems;
    v.erase([1]);
    expect(v.storedItems, isNot(same(before)));
  });

  test(
    'a piece of text wakes its conversation, the whole app only when the agent changes doing',
    () {
      live.apply({'type': 'session.state', 'sessionId': 's1', 'state': 'running'});
      final v = live.view('s1');
      var app = 0;
      var view = 0;
      live.addListener(() => app++);
      v.addListener(() => view++);
      live.apply(delta('Vediamo', 'thinking'));
      expect((app, view), (1, 1));
      live.apply(delta(' bene', 'thinking'));
      expect((app, view), (1, 2));
      live.apply(delta('Ecco'));
      expect((app, view), (2, 3));
      for (final t in [' la', ' risposta', ' intera']) {
        live.apply(delta(t));
      }
      expect((app, view), (2, 6));
    },
  );
}

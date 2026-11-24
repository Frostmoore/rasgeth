// The steps above the composer (3.12.5): a list written before the latest message to the agent
// counts only while it has open steps, as on the page (`latestTodos`, Chat.tsx).
import 'package:flutter_test/flutter_test.dart';
import 'package:rgcompanion/api/conversation.dart';

List<Map<String, String>> _list(int done, int all) => [
  for (var i = 0; i < all; i++)
    {
      'content': 'Step ${i + 1}',
      'status': i < done
          ? 'completed'
          : i == done
          ? 'in_progress'
          : 'pending',
    },
];

ToolItem _todos(String id, List<Map<String, String>> todos) =>
    ToolItem(callId: id, tool: 'update_todos', input: {'todos': todos})..ok = true;

UserItem _user(String text) => UserItem(text: text, ts: '2026-11-24T17:00:00Z');

void main() {
  test('a finished list goes away when a new message starts new work', () {
    final items = <ChatItem>[
      _user('first task'),
      _todos('t1', _list(8, 8)),
      _user('a new task'),
      ToolItem(callId: 'c1', tool: 'bash', input: {'command': 'ls'}),
    ];
    expect(latestTodos(items), isEmpty);
    items.add(_todos('t2', _list(0, 3)));
    expect(latestTodos(items), hasLength(3));
  });

  test('a list with open steps stays across messages', () {
    final items = <ChatItem>[_user('go'), _todos('t1', _list(2, 5)), _user('go on')];
    expect(latestTodos(items).where((x) => x.status == 'completed'), hasLength(2));
  });

  test('a finished list stays in the turn that finished it', () {
    final items = <ChatItem>[_user('go'), _todos('t1', _list(4, 4))];
    expect(latestTodos(items), hasLength(4));
  });
}

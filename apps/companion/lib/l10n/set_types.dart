/// A text in both languages, as the protocol's `Words` (3.12.3).
class Words {
  const Words({required this.it, required this.en});

  final String it;
  final String en;

  String of(String lang) => lang == 'it' ? it : en;
}

/// One of the ready-made agent sets (3.12.3); the table is generated from the protocol.
class AgentSet {
  const AgentSet({
    required this.id,
    required this.name,
    required this.description,
    required this.speed,
    required this.effort,
    required this.wants,
    required this.asks,
  });

  final String id;
  final Words name;
  final Words description;

  /// `fast` or `default`: a hint, never a model.
  final String speed;

  /// low | medium | high | max.
  final String effort;

  /// The connection kinds it wants: mailbox, chat, calendar, mcp.
  final List<String> wants;

  /// What it always asks the person first.
  final List<Words> asks;
}

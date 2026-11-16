// Ctrl+Enter (Cmd+Enter on macOS) sends from every field that writes to a conversation (3.9.0):
// the full conversation, the Quick chat, the panels, God's and the agents' fields on the wall.
// Plain Enter keeps its own meaning (a new line in the conversation's composer, «send» in the
// one-line fields of the wall).
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../api/types.dart';
import '../app_state.dart';

/// The keys that send: Ctrl+Enter, or Cmd+Enter on macOS (the numpad's Enter too).
List<SingleActivator> sendActivators({required bool mac}) => [
  for (final k in [LogicalKeyboardKey.enter, LogicalKeyboardKey.numpadEnter])
    SingleActivator(k, control: !mac, meta: mac),
];

class SendKeys extends StatelessWidget {
  const SendKeys({super.key, required this.onSend, required this.child});

  /// null while sending: the keys are taken, nothing happens.
  final VoidCallback? onSend;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final mac = AppScope.maybeRead(context)?.platform == DevicePlatform.macos;
    return CallbackShortcuts(
      bindings: {for (final a in sendActivators(mac: mac)) a: () => onSend?.call()},
      child: child,
    );
  }
}

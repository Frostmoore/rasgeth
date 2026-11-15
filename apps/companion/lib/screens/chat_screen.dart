// Chat (decision D9, variant 3): the everyday conversations, day by day. The field over the bar
// opens a new one; sending and the history come with G40.7 and G40.9.
import 'package:flutter/material.dart';

import '../app_state.dart';
import '../l10n/app_localizations.dart';
import '../theme/colors.dart';
import '../ui/common.dart';
import '../ui/icons.dart';

class ChatScreen extends StatelessWidget {
  const ChatScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    final l = AppLocalizations.of(context);
    final c = RgColors.of(context);
    final draft = app.chatDraft;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ScreenHeader(title: draft == null ? l.tabChat : l.chatNew),
        Expanded(
          child: draft == null
              ? EmptyState(icon: RgIcons.chat, text: l.chatEmpty)
              : ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    Align(
                      alignment: Alignment.centerRight,
                      child: Container(
                        key: const Key('chat-draft'),
                        constraints: const BoxConstraints(maxWidth: 520),
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        decoration: BoxDecoration(
                          color: c.user,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Text(draft, style: TextStyle(color: c.text, fontSize: 15)),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      l.chatDraftNote,
                      textAlign: TextAlign.right,
                      style: TextStyle(color: c.dim, fontSize: 12),
                    ),
                  ],
                ),
        ),
      ],
    );
  }
}

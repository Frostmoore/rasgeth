// Proposal A «La squadra» (study G40 section 4.1, decision D9): the bar at the bottom
// (Team | Chat | For you | Activity | You) and, right over it, the Chat's field, always there: it
// starts a new conversation with Chat at once.
import 'package:flutter/material.dart';

import '../app_state.dart';
import '../l10n/app_localizations.dart';
import '../theme/colors.dart';
import '../ui/icons.dart';
import 'activity_screen.dart';
import 'chat_screen.dart';
import 'inbox_screen.dart';
import 'team_screen.dart';
import 'you_screen.dart';

class HomeShell extends StatelessWidget {
  const HomeShell({super.key});

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            Expanded(
              child: IndexedStack(
                index: app.tab.index,
                children: const [
                  TeamScreen(),
                  ChatScreen(),
                  InboxScreen(),
                  ActivityScreen(),
                  YouScreen(),
                ],
              ),
            ),
            const ChatField(),
          ],
        ),
      ),
      bottomNavigationBar: const TabBarA(),
    );
  }
}

/// The Chat's field over the bar.
class ChatField extends StatefulWidget {
  const ChatField({super.key});

  @override
  State<ChatField> createState() => _ChatFieldState();
}

class _ChatFieldState extends State<ChatField> {
  final _text = TextEditingController();

  @override
  void dispose() {
    _text.dispose();
    super.dispose();
  }

  void _send() {
    final t = _text.text;
    if (t.trim().isEmpty) return;
    AppScope.of(context).startChat(t);
    _text.clear();
  }

  @override
  Widget build(BuildContext context) {
    final c = RgColors.of(context);
    final l = AppLocalizations.of(context);
    return Container(
      color: c.bg,
      padding: const EdgeInsets.fromLTRB(12, 6, 12, 8),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              key: const Key('chat-field'),
              controller: _text,
              minLines: 1,
              maxLines: 4,
              textInputAction: TextInputAction.send,
              onSubmitted: (_) => _send(),
              decoration: InputDecoration(hintText: l.composerHint, isDense: true),
            ),
          ),
          const SizedBox(width: 8),
          Semantics(
            button: true,
            label: l.composerSend,
            child: Material(
              color: c.accent,
              shape: const CircleBorder(),
              child: InkWell(
                key: const Key('chat-send'),
                customBorder: const CircleBorder(),
                onTap: _send,
                child: const SizedBox(
                  width: 42,
                  height: 42,
                  child: Center(child: RgIcon(RgIcons.send, size: 19, color: Colors.white)),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class TabBarA extends StatelessWidget {
  const TabBarA({super.key});

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    final c = RgColors.of(context);
    final l = AppLocalizations.of(context);
    final items = [
      (AppTab.team, RgIcons.users, l.tabTeam),
      (AppTab.chat, RgIcons.chat, l.tabChat),
      (AppTab.inbox, RgIcons.bell, l.tabInbox),
      (AppTab.activity, RgIcons.list, l.tabActivity),
      (AppTab.you, RgIcons.user, l.tabYou),
    ];
    return DecoratedBox(
      decoration: BoxDecoration(
        color: c.panel,
        border: Border(top: BorderSide(color: c.line)),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(6, 7, 6, 6),
          child: Row(
            children: [
              for (final (tab, icon, label) in items)
                Expanded(
                  child: _TabButton(
                    key: Key('tab-${tab.name}'),
                    icon: icon,
                    label: label,
                    selected: app.tab == tab,
                    onTap: () => app.setTab(tab),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TabButton extends StatelessWidget {
  const _TabButton({
    super.key,
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final RgIcons icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = RgColors.of(context);
    final color = selected ? c.accent : c.dim;
    return Semantics(
      button: true,
      selected: selected,
      label: label,
      excludeSemantics: true,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              RgIcon(icon, size: 22, color: color),
              const SizedBox(height: 2),
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600, color: color),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

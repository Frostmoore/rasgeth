// Proposal A «La squadra» (study G40 section 4.1, decision D9): the bar at the bottom
// (Team | Chat | For you | Activity | Projects | You; G42.5: Projects always, as the page's bar,
// no longer only with the advanced interface) and, right over it, the Chat's field, always there: it
// starts a new conversation with Chat at once.
import 'dart:async';

import 'package:flutter/material.dart';

import '../app_state.dart';
import '../l10n/app_localizations.dart';
import '../theme/colors.dart';
import '../ui/icons.dart';
import '../ui/no_internet_notice.dart';
import '../ui/rename_notice.dart';
import '../ui/send_keys.dart';
import '../voice/hands_free/indicator.dart';
import 'activity_screen.dart';
import 'chat_screen.dart';
import 'conversation_screen.dart';
import 'inbox_screen.dart';
import 'projects_screen.dart';
import 'share_screen.dart';
import 'team_screen.dart';
import 'update_screen.dart';
import 'voice_screen.dart' show openVoiceSettings;
import 'you_screen.dart';

class HomeShell extends StatefulWidget {
  const HomeShell({super.key});

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  late final AppController _app;
  bool _sharing = false;

  @override
  void initState() {
    super.initState();
    _app = AppScope.read(context);
    _app.addListener(_opens);
    WidgetsBinding.instance.addPostFrameCallback((_) => _opens());
  }

  @override
  void dispose() {
    _app.removeListener(_opens);
    super.dispose();
  }

  /// What came from outside: something shared from another app (G40.10), or a notification's
  /// conversation.
  void _opens() {
    if (!mounted || !_app.connected) return;
    final items = _app.pendingShare;
    if (items != null && !_sharing) {
      _sharing = true;
      unawaited(
        Navigator.of(context)
            .push(MaterialPageRoute<void>(builder: (_) => ShareScreen(items: items)))
            .whenComplete(() {
              _sharing = false;
              // Gone back without sending: put aside.
              if (identical(_app.pendingShare, items)) _app.shareHandled();
            }),
      );
    }
    // An update found running when the app connected: its screen, by itself.
    if (_app.takeUpdateToOpen() && !updateScreenOpen) unawaited(openUpdateScreen(context));
    final sid = _app.takePendingSession();
    if (sid != null) {
      unawaited(
        Navigator.of(context)
            .push(MaterialPageRoute<void>(builder: (_) => ConversationScreen(sessionId: sid))),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            const RenameNotice(),
            const NoInternetNotice(),
            // G42.16: hands-free voice's indicator, always there while it is on.
            const _HandsFreeBand(),
            Expanded(
              child: IndexedStack(
                index: app.tab.index,
                children: [
                  const TeamScreen(),
                  const ChatScreen(),
                  const InboxScreen(),
                  const ActivityScreen(),
                  // G42.5: always, as the page's projects in its bar (git with the advanced one).
                  // Its spinner never ticks out of sight.
                  TickerMode(enabled: app.tab == AppTab.projects, child: const ProjectsScreen()),
                  const YouScreen(),
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
            child: SendKeys(
              onSend: _send,
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
      (AppTab.projects, RgIcons.box, l.tabProjects),
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

/// G42.16: the phone's band at the top with hands-free voice's indicator (nothing when off).
class _HandsFreeBand extends StatelessWidget {
  const _HandsFreeBand();

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    return ListenableBuilder(
      listenable: app.handsFree,
      builder: (context, _) => !app.handsFree.settings.enabled
          ? const SizedBox.shrink()
          : Padding(
              padding: const EdgeInsets.fromLTRB(12, 6, 12, 0),
              child: Align(
                alignment: Alignment.centerRight,
                child: HandsFreeIndicator(onSettings: () => openVoiceSettings(context)),
              ),
            ),
    );
  }
}

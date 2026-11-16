// The quick Chat (G40.17, board C 4): the everyday Chat in a small window over the room, called
// with a shortcut (inside the app: a shortcut for the whole system is not reliable on every
// computer yet, Linux above all). It opens today's Chat conversation, or a new one; «expand» moves
// it to the side panel.
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../api/conversation.dart';
import '../app_state.dart';
import '../l10n/app_localizations.dart';
import '../screens/conversation_screen.dart';
import '../theme/colors.dart';
import '../ui/icons.dart';
import 'desk_controller.dart';
import 'drops.dart';
import 'side_panel.dart';

/// Today's Chat conversation, if there is one (the latest of today).
SessionRow? todaysChat(AppController app, {DateTime? now}) {
  final id = app.chatAgentId;
  if (id == null) return null;
  final day = now ?? DateTime.now();
  final rows = app.live.sessions.where((s) {
    if (s.agentId != id || s.archived) return false;
    final t = DateTime.tryParse(s.when)?.toLocal();
    return t != null && t.year == day.year && t.month == day.month && t.day == day.day;
  }).toList()..sort((a, b) => b.when.compareTo(a.when));
  return rows.firstOrNull;
}

Future<void> showQuickChat(
  BuildContext context, {
  required DeskController desk,
  String? shortcut,
}) async {
  final app = desk.app;
  final l = AppLocalizations.of(context);
  final messenger = ScaffoldMessenger.maybeOf(context);
  await app.ensureChatAgent();
  final sid = todaysChat(app)?.id ?? await app.newChatSession();
  if (sid == null) {
    messenger?.showSnackBar(SnackBar(content: Text(l.openFailed)));
    return;
  }
  if (!context.mounted) return;
  await showGeneralDialog<void>(
    context: context,
    barrierDismissible: true,
    barrierLabel: l.deskQuickChat,
    barrierColor: Colors.black.withValues(alpha: .25),
    transitionDuration: const Duration(milliseconds: 140),
    pageBuilder: (ctx, _, _) => DeskScope(
      desk: desk,
      child: QuickChat(sessionId: sid, shortcut: shortcut),
    ),
  );
}

class QuickChat extends StatefulWidget {
  const QuickChat({super.key, required this.sessionId, this.shortcut});

  final String sessionId;
  final String? shortcut;

  @override
  State<QuickChat> createState() => _QuickChatState();
}

class _QuickChatState extends State<QuickChat> {
  final _drops = FileDrops();

  @override
  void dispose() {
    _drops.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    final desk = DeskScope.of(context);
    final l = AppLocalizations.of(context);
    final c = RgColors.of(context);
    final size = MediaQuery.sizeOf(context);
    return CallbackShortcuts(
      // Esc closes it from anywhere inside (its own navigator would keep the key otherwise).
      bindings: {
        const SingleActivator(LogicalKeyboardKey.escape): () => Navigator.of(context).pop(),
      },
      child: Center(
        child: Material(
          key: const Key('quick-chat'),
          color: c.bg,
          elevation: 20,
          shadowColor: Colors.black54,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
            side: BorderSide(color: c.line),
          ),
          clipBehavior: Clip.antiAlias,
          child: SizedBox(
            width: (size.width - 60).clamp(360, 720),
            height: (size.height - 120).clamp(360, 560),
            child: Column(
              children: [
                if (widget.shortcut != null)
                  Container(
                    width: double.infinity,
                    color: c.panel2,
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                    child: Text(
                      l.deskQuickChatHint(widget.shortcut!),
                      textAlign: TextAlign.right,
                      style: TextStyle(fontSize: 11.5, color: c.dim),
                    ),
                  ),
                Expanded(
                  child: FileDropZone(
                    drops: _drops,
                    child: Navigator(
                      onGenerateRoute: (_) => PageRouteBuilder<void>(
                        pageBuilder: (_, _, _) => Material(
                          color: c.bg,
                          child: ConversationScreen(
                            sessionId: widget.sessionId,
                            agent: app.chatAgent,
                            embedded: true,
                            drops: _drops,
                            headerActions: [
                              PanelButton(
                                key: const Key('quick-chat-expand'),
                                icon: RgIcons.minimize,
                                tooltip: l.deskQuickChatExpand,
                                onTap: () {
                                  Navigator.of(context).pop();
                                  desk.show(
                                    PanelConversation(widget.sessionId, agent: app.chatAgent),
                                  );
                                },
                              ),
                              PanelButton(
                                key: const Key('quick-chat-close'),
                                icon: RgIcons.x,
                                tooltip: l.deskPanelClose,
                                onTap: () => Navigator.of(context).pop(),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

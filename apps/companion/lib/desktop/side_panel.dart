// The side panel and the floating panels (G40.17). The panel holds a conversation or one of the
// app's screens, inside a navigator of its own (what opens from it stays in it); its left edge
// is dragged to resize it. A conversation can be taken out: it floats over the window, moved by
// its title, resized from its corner, and put back with one click. Files dropped on a
// conversation go to its composer.
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../app_state.dart';
import '../l10n/app_localizations.dart';
import '../screens/agent_conversations_screen.dart';
import '../screens/echo_search.dart';
import '../screens/project_overview_screen.dart';
import '../ui/agent_menu.dart';
import '../screens/chat_screen.dart';
import '../screens/conversation_screen.dart';
import '../screens/inbox_screen.dart';
import '../screens/saved_screen.dart';
import '../screens/you_screen.dart';
import '../theme/colors.dart';
import '../ui/icons.dart';
import 'desk_controller.dart';
import 'drops.dart';

String panelTitle(AppLocalizations l, PanelScreen s) => switch (s) {
  PanelScreen.inbox => l.tabInbox,
  PanelScreen.chat => l.tabChat,
  PanelScreen.saved => l.savedTitle,
  PanelScreen.you => l.tabYou,
  PanelScreen.echo => l.echoSearch,
};

Widget _screen(PanelScreen s) => switch (s) {
  PanelScreen.inbox => const InboxScreen(),
  PanelScreen.chat => const ChatScreen(),
  PanelScreen.saved => const SavedScreen(),
  PanelScreen.you => const YouScreen(),
  // Echo (3.9.6): the past conversations' search, from the palette.
  PanelScreen.echo => const EchoSearch(autofocus: true),
};

/// A small round button of a panel's header.
class PanelButton extends StatelessWidget {
  const PanelButton({super.key, required this.icon, required this.tooltip, required this.onTap});

  final RgIcons icon;
  final String tooltip;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = RgColors.of(context);
    return IconButton(
      tooltip: tooltip,
      visualDensity: VisualDensity.compact,
      onPressed: onTap,
      icon: RgIcon(icon, size: 17, color: c.dim),
    );
  }
}

class SidePanel extends StatefulWidget {
  const SidePanel({super.key, required this.content, this.full = false});

  final PanelContent content;

  /// The conversation «full window» (3.8.3), beside the mascots' bar.
  final bool full;

  @override
  State<SidePanel> createState() => _SidePanelState();
}

class _SidePanelState extends State<SidePanel> {
  final _drops = FileDrops();

  @override
  void dispose() {
    _drops.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final desk = DeskScope.of(context);
    final l = AppLocalizations.of(context);
    final c = RgColors.of(context);
    final content = widget.content;
    final close = PanelButton(
      key: const Key('panel-close'),
      icon: RgIcons.x,
      tooltip: l.deskPanelClose,
      onTap: desk.closePanel,
    );
    final Widget body = switch (content) {
      PanelConversation() => FileDropZone(
        drops: _drops,
        child: ConversationScreen(
          key: ValueKey(content.sessionId),
          sessionId: content.sessionId,
          agent: content.agent,
          firstMessage: content.firstMessage,
          embedded: true,
          drops: _drops,
          headerActions: [
            const _FullButton(),
            PanelButton(
              key: const Key('panel-detach'),
              icon: RgIcons.external,
              tooltip: l.deskPanelDetach,
              onTap: () => desk.detach(MediaQuery.sizeOf(context)),
            ),
            close,
          ],
        ),
      ),
      PanelPage(:final screen) => Column(
        children: [
          _PageHead(screen: screen, close: close),
          Expanded(child: _screen(screen)),
        ],
      ),
      PanelAgent(:final agentId) => _AgentPanel(agentId: agentId, close: close),
      PanelProject(:final projectId) => Column(
        children: [
          ProjectPanelHead(projectId: projectId, close: close),
          Expanded(child: ProjectOverview(projectId: projectId)),
        ],
      ),
    };
    return Container(
      key: const Key('desk-panel'),
      decoration: BoxDecoration(
        color: c.bg,
        border: widget.full ? null : Border(left: BorderSide(color: c.line)),
      ),
      child: ClipRect(
        child: Navigator(
          key: ValueKey(content.id),
          onGenerateRoute: (_) =>
              PageRouteBuilder<void>(pageBuilder: (_, _, _) => PanelSurface(child: body)),
        ),
      ),
    );
  }
}

/// «Full window» and back (3.8.3). Reads the room itself: the panel's page is built once, and
/// keeps its state when the conversation goes full.
class _FullButton extends StatelessWidget {
  const _FullButton();

  @override
  Widget build(BuildContext context) {
    final desk = DeskScope.of(context);
    final l = AppLocalizations.of(context);
    return desk.full
        ? PanelButton(
            key: const Key('panel-unfull'),
            icon: RgIcons.minimize,
            tooltip: l.deskFullWindowOff,
            onTap: () => desk.setFull(false),
          )
        : PanelButton(
            key: const Key('panel-full'),
            icon: RgIcons.maximize,
            tooltip: l.deskFullWindow,
            onTap: () => desk.setFull(true),
          );
  }
}

/// The panel's left edge: dragged to resize, arrows with the keyboard.
class PanelResizer extends StatelessWidget {
  const PanelResizer({
    super.key,
    required this.onDrag,
    required this.onKey,
    this.onReset,
    this.onEnd,
  });

  final ValueChanged<double> onDrag;

  /// A double tap (or Enter on the focused edge): back to the normal width.
  final VoidCallback? onReset;

  /// The drag is over (the width is kept then).
  final VoidCallback? onEnd;

  /// +1 wider, -1 narrower (the arrows when the edge has the focus).
  final ValueChanged<int> onKey;

  @override
  Widget build(BuildContext context) {
    final c = RgColors.of(context);
    final l = AppLocalizations.of(context);
    return Semantics(
      label: l.deskPanelResize,
      slider: true,
      child: Focus(
        onKeyEvent: (_, e) {
          if (e is! KeyDownEvent && e is! KeyRepeatEvent) return KeyEventResult.ignored;
          if (e.logicalKey == LogicalKeyboardKey.arrowLeft) {
            onKey(1);
            return KeyEventResult.handled;
          }
          if (e.logicalKey == LogicalKeyboardKey.arrowRight) {
            onKey(-1);
            return KeyEventResult.handled;
          }
          if (onReset != null &&
              (e.logicalKey == LogicalKeyboardKey.enter ||
                  e.logicalKey == LogicalKeyboardKey.numpadEnter)) {
            onReset!();
            return KeyEventResult.handled;
          }
          return KeyEventResult.ignored;
        },
        child: MouseRegion(
          cursor: SystemMouseCursors.resizeColumn,
          child: GestureDetector(
            key: const Key('panel-resizer'),
            behavior: HitTestBehavior.translucent,
            onHorizontalDragUpdate: (d) => onDrag(d.delta.dx),
            onHorizontalDragEnd: onEnd == null ? null : (_) => onEnd!(),
            onDoubleTap: onReset,
            child: SizedBox(
              width: 7,
              child: Center(
                child: Container(
                  width: 3,
                  height: 36,
                  decoration: BoxDecoration(color: c.line, borderRadius: BorderRadius.circular(2)),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// The conversations taken out of the panel, over the window.
class FloatingLayer extends StatelessWidget {
  const FloatingLayer({super.key});

  @override
  Widget build(BuildContext context) {
    final desk = DeskScope.of(context);
    return LayoutBuilder(
      builder: (context, box) {
        final size = box.biggest;
        return Stack(
          children: [
            for (final f in desk.floating)
              Positioned.fromRect(
                key: ObjectKey(f),
                rect: f.rect,
                child: _Floating(panel: f, window: size),
              ),
          ],
        );
      },
    );
  }
}

class _Floating extends StatefulWidget {
  const _Floating({required this.panel, required this.window});

  final FloatingPanel panel;
  final Size window;

  @override
  State<_Floating> createState() => _FloatingState();
}

class _FloatingState extends State<_Floating> {
  final _drops = FileDrops();

  @override
  void dispose() {
    _drops.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final desk = DeskScope.of(context);
    final l = AppLocalizations.of(context);
    final c = RgColors.of(context);
    final f = widget.panel;
    final name = f.content.agent?.name ?? '';
    return Listener(
      onPointerDown: (_) => desk.raise(f),
      child: Material(
        key: Key('floating-${f.content.sessionId}'),
        elevation: 16,
        shadowColor: Colors.black54,
        color: c.bg,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: c.line),
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          children: [
            // The title: dragged to move.
            GestureDetector(
              key: Key('floating-title-${f.content.sessionId}'),
              onPanUpdate: (d) => desk.moveFloating(f, f.rect.shift(d.delta), widget.window),
              child: MouseRegion(
                cursor: SystemMouseCursors.move,
                child: Container(
                  height: 30,
                  color: c.panel2,
                  padding: const EdgeInsets.only(left: 12),
                  child: Row(
                    children: [
                      RgIcon(RgIcons.chat, size: 13, color: c.dim),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(fontSize: 12.5, color: c.dim),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            Expanded(
              child: Stack(
                children: [
                  Positioned.fill(
                    child: FileDropZone(
                      drops: _drops,
                      child: Navigator(
                        key: ValueKey('floating:${f.content.sessionId}'),
                        onGenerateRoute: (_) => PageRouteBuilder<void>(
                          pageBuilder: (_, _, _) => PanelSurface(
                            child: ConversationScreen(
                              key: ValueKey(f.content.sessionId),
                              sessionId: f.content.sessionId,
                              agent: f.content.agent,
                              embedded: true,
                              drops: _drops,
                              headerActions: [
                                PanelButton(
                                  key: Key('floating-dock-${f.content.sessionId}'),
                                  icon: RgIcons.minimize,
                                  tooltip: l.deskPanelDock,
                                  onTap: () => desk.dock(f),
                                ),
                                PanelButton(
                                  key: Key('floating-close-${f.content.sessionId}'),
                                  icon: RgIcons.x,
                                  tooltip: l.deskPanelClose,
                                  onTap: () => desk.closeFloating(f),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  // The corner: dragged to resize.
                  Positioned(
                    right: 0,
                    bottom: 0,
                    child: MouseRegion(
                      cursor: SystemMouseCursors.resizeDownRight,
                      child: GestureDetector(
                        key: Key('floating-resize-${f.content.sessionId}'),
                        onPanUpdate: (d) => desk.moveFloating(
                          f,
                          Rect.fromLTWH(
                            f.rect.left,
                            f.rect.top,
                            f.rect.width + d.delta.dx,
                            f.rect.height + d.delta.dy,
                          ),
                          widget.window,
                        ),
                        child: SizedBox(
                          width: 18,
                          height: 18,
                          child: CustomPaint(painter: _Grip(c.dim)),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Grip extends CustomPainter {
  _Grip(this.color);

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()
      ..color = color
      ..strokeWidth = 1.4;
    for (var i = 1; i <= 3; i++) {
      final d = i * 4.0;
      canvas.drawLine(
        Offset(size.width - d, size.height - 2),
        Offset(size.width - 2, size.height - d),
        p,
      );
    }
  }

  @override
  bool shouldRepaint(_Grip old) => old.color != color;
}

/// A page inside the room's own navigators, in the theme's background: read when it paints, so
/// switching between light and dark repaints it (the route keeps the page it built first).
class PanelSurface extends StatelessWidget {
  const PanelSurface({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) => Material(color: RgColors.of(context).bg, child: child);
}

/// The title over a screen in the panel (its colours read when it paints, as [PanelSurface]).
/// An agent's conversations in the panel (3.8.8): its head with the agent's menu, then the list.
class _AgentPanel extends StatelessWidget {
  const _AgentPanel({required this.agentId, required this.close});

  final String agentId;
  final Widget close;

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    final l = AppLocalizations.of(context);
    final c = RgColors.of(context);
    final a = app.agents.where((x) => x.id == agentId).firstOrNull;
    return Column(
      key: Key('panel-agent-$agentId'),
      children: [
        Container(
          padding: const EdgeInsets.fromLTRB(14, 8, 6, 8),
          decoration: BoxDecoration(
            border: Border(bottom: BorderSide(color: c.line)),
          ),
          child: Row(
            children: [
              Expanded(
                child: a == null
                    ? Text(l.statusUnreachable, style: TextStyle(color: c.dim))
                    : AgentListHead(
                        agent: a,
                        trailing: [
                          Builder(
                            builder: (ctx) => PanelButton(
                              key: const Key('panel-agent-more'),
                              icon: RgIcons.more,
                              tooltip: l.asOpen,
                              onTap: () {
                                final box = ctx.findRenderObject()! as RenderBox;
                                showAgentMenu(
                                  ctx,
                                  a,
                                  box.localToGlobal(box.size.bottomLeft(Offset.zero)),
                                );
                              },
                            ),
                          ),
                        ],
                      ),
              ),
              close,
            ],
          ),
        ),
        Expanded(
          child: a == null
              ? const SizedBox.shrink()
              : AgentConversations(agent: a, readOnly: app.isAgentReadOnly(a)),
        ),
      ],
    );
  }
}

class _PageHead extends StatelessWidget {
  const _PageHead({required this.screen, required this.close});

  final PanelScreen screen;
  final Widget close;

  @override
  Widget build(BuildContext context) {
    final c = RgColors.of(context);
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 4, 6, 4),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: c.line)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              panelTitle(AppLocalizations.of(context), screen),
              style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15, color: c.text),
            ),
          ),
          close,
        ],
      ),
    );
  }
}

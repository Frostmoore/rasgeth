// An agent's quick actions wherever its tile or mascot shows (G38.7): a right click on a computer
// opens a context menu at the pointer, a long press (on a phone, or anywhere) the sheet from below
// with the same actions. Both end with «Agent settings…», every setting of Settings › Agents.
import 'package:flutter/material.dart';

import '../api/types.dart';
import '../app_state.dart';
import '../desktop/desk_controller.dart';
import '../l10n/app_localizations.dart';
import '../screens/agent_conversations_screen.dart';
import '../screens/agent_settings_screen.dart';
import '../screens/instructions_screen.dart';
import '../screens/team_screen.dart';
import '../theme/colors.dart';
import 'dialogs.dart';
import 'icons.dart';
import 'model_sheet.dart';
import 'pause_agent.dart';
import 'remove_agent.dart';

/// Right click: the context menu at the pointer; long press: the sheet from below.
class AgentPress extends StatelessWidget {
  const AgentPress({
    super.key,
    required this.agent,
    required this.child,
    this.longPress = true,
    this.onTap,
  });

  final Agent? agent;
  final Widget child;

  /// A plain click (a mascot that shows the agent's conversations).
  final VoidCallback? onTap;

  /// False where the child keeps its own long press (it opens the same sheet).
  final bool longPress;

  @override
  Widget build(BuildContext context) {
    final a = agent;
    if (a == null) return child;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      onSecondaryTapUp: (d) => showAgentMenu(context, a, d.globalPosition),
      onLongPress: longPress ? () => showAgentSheet(context, a) : null,
      child: child,
    );
  }
}

enum _Act {
  open,
  list,
  fresh,
  model,
  instructions,
  mascot,
  favourite,
  stopTurn,
  pause,
  resume,
  remove,
  settings,
}

/// The computer's context menu for [a], at [at] (global coordinates).
Future<void> showAgentMenu(BuildContext context, Agent a, Offset at, {VoidCallback? opened}) async {
  final app = AppScope.read(context);
  final l = AppLocalizations.of(context);
  final c = RgColors.of(context);
  final overlay = Overlay.of(context).context.findRenderObject()! as RenderBox;
  final local = overlay.globalToLocal(at);
  final fav = app.isFavourite(a.id);
  final running = app.runningOf(a.id).isNotEmpty;
  PopupMenuItem<_Act> item(_Act v, RgIcons icon, String text, {Color? color}) => PopupMenuItem(
    key: Key('agent-menu-${v.name}'),
    value: v,
    height: 40,
    child: Row(
      children: [
        RgIcon(icon, size: 17, color: color ?? c.dim),
        const SizedBox(width: 12),
        Flexible(
          child: Text(
            text,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(color: color ?? c.text, fontSize: 14),
          ),
        ),
      ],
    ),
  );
  final pick = await showMenu<_Act>(
    context: context,
    position: RelativeRect.fromRect(local & const Size(1, 1), Offset.zero & overlay.size),
    color: c.panel,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(12),
      side: BorderSide(color: c.line),
    ),
    items: [
      item(_Act.open, RgIcons.chat, l.agentOpenChat),
      item(_Act.list, RgIcons.list, l.cmConversationsOf(a.name)),
      item(_Act.fresh, RgIcons.plus, l.asMenuNew),
      const PopupMenuDivider(height: 8),
      item(_Act.model, RgIcons.zap, l.asMenuModel),
      item(_Act.instructions, RgIcons.edit, l.asMenuInstructions),
      if (a.kind != AgentKind.god && a.active) item(_Act.mascot, RgIcons.refresh, l.mascotChange),
      item(_Act.favourite, RgIcons.star, fav ? l.favouriteRemove : l.favouriteAdd),
      if (running) item(_Act.stopTurn, RgIcons.stop, l.asMenuStopTurn, color: c.err),
      // 3.8.9: «Stop…» is a pause («Resume» brings it back); «Remove…» takes it out of the team.
      if (canResumeAgent(a)) item(_Act.resume, RgIcons.play, l.paResume),
      if (canPauseAgent(a)) item(_Act.pause, RgIcons.pause, l.paMenu, color: c.err),
      if (canRemoveAgent(app, a)) item(_Act.remove, RgIcons.trash, l.raMenu, color: c.err),
      const PopupMenuDivider(height: 8),
      item(_Act.settings, RgIcons.settings, l.asOpen),
    ],
  );
  if (pick == null || !context.mounted) return;
  await _run(context, a, pick);
  if (pick == _Act.open || pick == _Act.fresh || pick == _Act.list) opened?.call();
}

Future<void> _run(BuildContext context, Agent a, _Act act) async {
  final app = AppScope.read(context);
  final l = AppLocalizations.of(context);
  final messenger = ScaffoldMessenger.maybeOf(context);
  final desk = DeskScope.maybeRead(context);
  switch (act) {
    case _Act.open || _Act.fresh:
      final fresh = act == _Act.fresh;
      if (desk != null) {
        if (!await desk.openAgent(a, fresh: fresh)) {
          messenger?.showSnackBar(SnackBar(content: Text(l.openFailed)));
        }
      } else {
        await openAgentConversation(context, a, fresh: fresh);
      }
    case _Act.list:
      await openAgentList(context, a);
    case _Act.model:
      await pickAgentModel(context, a);
    case _Act.instructions:
      await openInstructions(context, a);
    case _Act.mascot:
      final yes = await askConfirm(
        context,
        title: l.mascotChange,
        body: l.mascotChangeAsk(a.name),
        yes: l.mascotChangeYes,
      );
      if (!yes) return;
      if (await app.changeMascot(a) != null) {
        messenger?.showSnackBar(SnackBar(content: Text(l.mascotChanged(a.name))));
      }
    case _Act.favourite:
      app.toggleFavourite(a.id);
    case _Act.stopTurn:
      final ok = await app.stopAgent(a.id);
      messenger?.showSnackBar(
        SnackBar(content: Text(ok ? l.agentStopped(a.name) : l.agentStopFailed)),
      );
    case _Act.pause:
      await confirmPauseAgent(context, a);
    case _Act.resume:
      await resumeAgentNow(context, a);
    case _Act.remove:
      await confirmRemoveAgent(context, a);
    case _Act.settings:
      await openAgentSettings(context, a);
  }
}

/// [a]'s conversations (3.8.8): the Chat's own screen for the Chat, the list for the others.
Future<void> openAgentList(BuildContext context, Agent a) async {
  final app = AppScope.read(context);
  final desk = DeskScope.maybeRead(context);
  if (app.isChat(a)) {
    if (desk != null) {
      desk.show(const PanelPage(PanelScreen.chat));
    } else {
      app.setTab(AppTab.chat);
      Navigator.of(context).popUntil((r) => r.isFirst);
    }
    return;
  }
  await openAgentConversations(context, a);
}

/// The model sheet for [a] (the page's own API: the Chat through its settings), with a word on
/// how it went.
Future<bool> pickAgentModel(BuildContext context, Agent a) async {
  final app = AppScope.read(context);
  final l = AppLocalizations.of(context);
  final messenger = ScaffoldMessenger.maybeOf(context);
  final own = await app.ownModelOf(a);
  final models = await app.modelChoices(again: true);
  if (!context.mounted) return false;
  if (models.isEmpty) {
    messenger?.showSnackBar(SnackBar(content: Text(l.noModels)));
    return false;
  }
  final up = a.kind == AgentKind.god || app.isChat(a) ? null : app.inheritedModelOf(a);
  final inherit = a.kind == AgentKind.god || app.isChat(a)
      ? l.agentModelDefault
      : up == null
      ? l.agentModelInherit
      : l.modelInheritOf(l.agentModelInherit, modelWords(l, app.knownModels, up));
  final pick = await showModelPicker(
    context,
    title: l.agentModelTitle(a.name),
    models: models,
    current: own,
    inheritLabel: inherit,
  );
  if (pick == null) return false;
  final ok = await app.setAgentModel(a, pick.model);
  messenger?.showSnackBar(SnackBar(content: Text(ok ? l.agentModelSaved : l.agentModelFailed)));
  return ok;
}

/// The sheet's and the menu's last line: «Agent settings…».
class AgentSettingsRow extends StatelessWidget {
  const AgentSettingsRow({super.key, required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = RgColors.of(context);
    final l = AppLocalizations.of(context);
    return Material(
      color: c.panel,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(color: c.line),
      ),
      child: InkWell(
        key: const Key('agent-settings'),
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 13),
          child: Row(
            children: [
              RgIcon(RgIcons.settings, size: 18, color: c.dim),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  l.asOpen,
                  style: TextStyle(fontWeight: FontWeight.w700, color: c.text),
                ),
              ),
              RgIcon(RgIcons.chevronRight, size: 18, color: c.dim),
            ],
          ),
        ),
      ),
    );
  }
}

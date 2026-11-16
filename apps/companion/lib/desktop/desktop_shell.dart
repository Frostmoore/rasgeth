// RGCompanion on computers (G40.17): the «control room» of board C instead of the phone's screens
// made wider. At the top the menus (the system's bar on macOS), the views and the window's
// title; then God, the Chat and «For you»; the view in the middle; the side panel with a
// conversation; the status bar at the bottom. The palette (Ctrl/Cmd+K), the quick Chat and the
// floating panels go over it. The phone keeps its own shell (HomeShell).
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../api/live.dart';
import '../app_state.dart';
import '../l10n/app_localizations.dart';
import '../screens/activity_screen.dart';
import '../screens/new_agent_screen.dart';
import '../screens/share_screen.dart';
import '../screens/you_screen.dart';
import '../theme/colors.dart';
import '../ui/common.dart';
import '../ui/icons.dart';
import 'advanced/code_view.dart';
import 'advanced/common.dart';
import 'advanced/git_view.dart';
import 'advanced/log_view.dart';
import 'advanced/projects_wall.dart';
import 'advanced/terminals_view.dart';
import 'desk_controller.dart';
import 'desk_menu.dart';
import 'palette.dart';
import 'quick_chat.dart';
import 'side_panel.dart';
import 'wall.dart';
import 'wall_feed.dart';

String viewLabel(AppLocalizations l, DeskView v) => switch (v) {
  DeskView.team => l.tabTeam,
  DeskView.projects => l.tabProjects,
  DeskView.activity => l.tabActivity,
  DeskView.code => l.deskViewCode,
  DeskView.terminals => l.deskViewTerminals,
  DeskView.git => l.codeTabGit,
  DeskView.log => l.codeTabLog,
};

RgIcons viewIcon(DeskView v) => switch (v) {
  DeskView.team => RgIcons.users,
  DeskView.projects => RgIcons.folder,
  DeskView.activity => RgIcons.list,
  DeskView.code => RgIcons.code,
  DeskView.terminals => RgIcons.terminal,
  DeskView.git => RgIcons.gitBranch,
  DeskView.log => RgIcons.activity,
};

class DesktopShell extends StatefulWidget {
  const DesktopShell({super.key});

  @override
  State<DesktopShell> createState() => _DesktopShellState();
}

class _DesktopShellState extends State<DesktopShell> {
  late final AppController _app = AppScope.read(context);
  late final DeskController _desk = DeskController(_app);
  late final WallFeed _feed = WallFeed(_app);
  bool _advanced = false;
  bool _sharing = false;

  @override
  void initState() {
    super.initState();
    _advanced = _app.advanced;
    _app.addListener(_appChanged);
    _desk.addListener(_deskChanged);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _opens();
      _deskChanged();
    });
  }

  @override
  void dispose() {
    _app.removeListener(_appChanged);
    _desk.removeListener(_deskChanged);
    _feed.dispose();
    _desk.dispose();
    super.dispose();
  }

  void _appChanged() {
    if (_app.advanced != _advanced) {
      _advanced = _app.advanced;
      _desk.advancedChanged();
      _feed.withStatus = _advanced;
      if (_advanced) unawaited(_feed.refresh(status: true));
    }
    _opens();
    _deskChanged();
  }

  /// The wall's feed runs while a wall is in sight.
  void _deskChanged() {
    final wall = _desk.view == DeskView.team || _desk.view == DeskView.projects;
    _feed.withStatus = _app.advanced;
    if (wall && _app.connected) {
      _feed.start();
    } else {
      _feed.stop();
    }
  }

  /// What came from outside: a notification's conversation (in the panel), something shared.
  void _opens() {
    if (!mounted || !_app.connected) return;
    final sid = _app.takePendingSession();
    if (sid != null) _desk.show(PanelConversation(sid));
    final items = _app.pendingShare;
    if (items != null && !_sharing) {
      _sharing = true;
      unawaited(
        Navigator.of(context)
            .push(MaterialPageRoute<void>(builder: (_) => ShareScreen(items: items)))
            .whenComplete(() {
              _sharing = false;
              if (identical(_app.pendingShare, items)) _app.shareHandled();
            }),
      );
    }
  }

  // ---- commands ----

  bool get _mac => isMacLike(_app);

  SingleActivator _k(LogicalKeyboardKey k, {bool shift = false, bool alt = false}) =>
      cmdKey(k, mac: _mac, shift: shift, alt: alt);

  void _palette([String initial = '']) {
    final menus = _menus(AppLocalizations.of(context));
    unawaited(
      showPalette(
        context,
        desk: _desk,
        commands: [for (final m in menus) ...m.items.whereType<DeskCommand>()],
        initial: initial,
      ),
    );
  }

  SingleActivator get _quickKey => _k(LogicalKeyboardKey.space, shift: true);

  void _quickChat() => unawaited(
    showQuickChat(
      context,
      desk: _desk,
      shortcut: shortcutLabel(_quickKey, AppLocalizations.of(context), mac: _mac),
    ),
  );

  void _edit(Intent intent) {
    final ctx = FocusManager.instance.primaryFocus?.context;
    if (ctx != null) Actions.maybeInvoke(ctx, intent);
  }

  void _focusField(FocusNode n) {
    if (!basicViews.contains(_desk.view) && !_app.advanced) _desk.setView(DeskView.team);
    n.requestFocus();
  }

  Future<void> _newConversation() async {
    final id = _desk.panelAgentId;
    final a = _app.agents.where((x) => x.id == id).firstOrNull;
    if (a == null) {
      _palette('@');
      return;
    }
    await _desk.openAgent(a, fresh: true);
  }

  void _stopOpen() {
    final id = _desk.panelAgentId;
    if (id != null) unawaited(_app.stopAgent(id));
  }

  List<DeskMenu> _menus(AppLocalizations l) {
    final adv = _app.advanced;
    final hasPanelConversation = _desk.panel is PanelConversation;
    final pid = _desk.projectOr();
    return [
      DeskMenu(l.deskMenuFile, [
        DeskCommand(
          id: 'new-agent',
          label: l.teamNewAgent,
          group: l.deskMenuFile,
          icon: RgIcons.userPlus,
          shortcut: _k(LogicalKeyboardKey.keyN),
          run: () => openNewAgent(context),
        ),
        DeskCommand(
          id: 'quick-chat',
          label: l.deskQuickChat,
          group: l.deskMenuFile,
          icon: RgIcons.chat,
          shortcut: _quickKey,
          run: _quickChat,
        ),
        DeskCommand(
          id: 'saved',
          label: l.savedTitle,
          group: l.deskMenuFile,
          icon: RgIcons.bookmark,
          run: () => _desk.show(const PanelPage(PanelScreen.saved)),
        ),
        null,
        DeskCommand(
          id: 'settings',
          label: l.deskSettings,
          group: l.deskMenuFile,
          icon: RgIcons.settings,
          shortcut: _k(LogicalKeyboardKey.comma),
          run: () => _desk.show(const PanelPage(PanelScreen.you)),
        ),
      ]),
      DeskMenu(l.deskMenuEdit, [
        DeskCommand(
          id: 'undo',
          label: l.deskUndo,
          group: l.deskMenuEdit,
          bound: false,
          shortcut: _k(LogicalKeyboardKey.keyZ),
          run: () => _edit(const UndoTextIntent(SelectionChangedCause.keyboard)),
        ),
        DeskCommand(
          id: 'redo',
          label: l.deskRedo,
          group: l.deskMenuEdit,
          bound: false,
          shortcut: _k(LogicalKeyboardKey.keyZ, shift: true),
          run: () => _edit(const RedoTextIntent(SelectionChangedCause.keyboard)),
        ),
        null,
        DeskCommand(
          id: 'cut',
          label: l.deskCut,
          group: l.deskMenuEdit,
          bound: false,
          shortcut: _k(LogicalKeyboardKey.keyX),
          run: () => _edit(const CopySelectionTextIntent.cut(SelectionChangedCause.keyboard)),
        ),
        DeskCommand(
          id: 'copy',
          label: l.deskCopy,
          group: l.deskMenuEdit,
          bound: false,
          shortcut: _k(LogicalKeyboardKey.keyC),
          run: () => _edit(CopySelectionTextIntent.copy),
        ),
        DeskCommand(
          id: 'paste',
          label: l.deskPaste,
          group: l.deskMenuEdit,
          bound: false,
          shortcut: _k(LogicalKeyboardKey.keyV),
          run: () => _edit(const PasteTextIntent(SelectionChangedCause.keyboard)),
        ),
        DeskCommand(
          id: 'select-all',
          label: l.deskSelectAll,
          group: l.deskMenuEdit,
          bound: false,
          shortcut: _k(LogicalKeyboardKey.keyA),
          run: () => _edit(const SelectAllTextIntent(SelectionChangedCause.keyboard)),
        ),
        null,
        if (adv)
          DeskCommand(
            id: 'goto-file',
            label: l.deskGoToFile,
            group: l.deskMenuEdit,
            icon: RgIcons.file,
            shortcut: _k(LogicalKeyboardKey.keyP),
            run: () => _palette('# '),
          ),
        DeskCommand(
          id: 'palette',
          label: l.deskPaletteTitle,
          group: l.deskMenuEdit,
          icon: RgIcons.search,
          shortcut: _k(LogicalKeyboardKey.keyK),
          run: _palette,
        ),
      ]),
      DeskMenu(l.deskMenuView, [
        for (final (i, v) in _desk.views.indexed)
          DeskCommand(
            id: 'view-${v.name}',
            label: viewLabel(l, v),
            group: l.deskMenuView,
            icon: viewIcon(v),
            checked: _desk.view == v,
            shortcut: _k(LogicalKeyboardKey(LogicalKeyboardKey.digit1.keyId + i)),
            run: () => _desk.setView(v),
          ),
        null,
        DeskCommand(
          id: 'panel',
          label: l.deskTogglePanel,
          group: l.deskMenuView,
          shortcut: _k(LogicalKeyboardKey.backslash),
          run: _desk.togglePanel,
        ),
        DeskCommand(
          id: 'advanced',
          label: adv ? l.deskAdvancedOff : l.deskAdvancedOn,
          group: l.deskMenuView,
          icon: RgIcons.code,
          checked: adv,
          shortcut: _k(LogicalKeyboardKey.keyA, shift: true),
          run: () => _app.setAdvanced(!adv),
        ),
        null,
        for (final (m, label) in [
          (ThemeMode.light, l.themeLight),
          (ThemeMode.dark, l.themeDark),
          (ThemeMode.system, l.themeSystem),
        ])
          DeskCommand(
            id: 'theme-${m.name}',
            label: l.deskTheme(label),
            group: l.deskMenuView,
            checked: _app.themeMode == m,
            run: () => _app.setThemeMode(m),
          ),
      ]),
      DeskMenu(l.deskMenuAgents, [
        DeskCommand(
          id: 'agents',
          label: l.deskFindAgent,
          group: l.deskMenuAgents,
          icon: RgIcons.users,
          shortcut: _k(LogicalKeyboardKey.keyK, shift: true),
          run: () => _palette('@'),
        ),
        DeskCommand(
          id: 'ask-god',
          label: l.deskAskGod,
          group: l.deskMenuAgents,
          shortcut: _k(LogicalKeyboardKey.keyG),
          run: () => _focusField(_desk.godFocus),
        ),
        DeskCommand(
          id: 'ask-chat',
          label: l.deskAskChat,
          group: l.deskMenuAgents,
          shortcut: _k(LogicalKeyboardKey.keyJ),
          run: () => _focusField(_desk.chatFocus),
        ),
        DeskCommand(
          id: 'for-you',
          label: l.tabInbox,
          group: l.deskMenuAgents,
          icon: RgIcons.bell,
          shortcut: _k(LogicalKeyboardKey.keyD, shift: true),
          run: () => _desk.show(const PanelPage(PanelScreen.inbox)),
        ),
        null,
        DeskCommand(
          id: 'stop-open',
          label: l.deskStopOpen,
          group: l.deskMenuAgents,
          icon: RgIcons.stop,
          enabled: hasPanelConversation,
          shortcut: _k(LogicalKeyboardKey.period),
          run: _stopOpen,
        ),
      ]),
      DeskMenu(l.deskMenuConversation, [
        DeskCommand(
          id: 'new-conversation',
          label: l.deskNewConversation,
          group: l.deskMenuConversation,
          icon: RgIcons.plus,
          shortcut: _k(LogicalKeyboardKey.keyN, shift: true),
          run: () => unawaited(_newConversation()),
        ),
        DeskCommand(
          id: 'detach',
          label: l.deskPanelDetach,
          group: l.deskMenuConversation,
          icon: RgIcons.external,
          enabled: hasPanelConversation,
          shortcut: _k(LogicalKeyboardKey.keyO, shift: true),
          run: () => _desk.detach(MediaQuery.sizeOf(context)),
        ),
        DeskCommand(
          id: 'close-panel',
          label: l.deskPanelClose,
          group: l.deskMenuConversation,
          enabled: _desk.panel != null,
          shortcut: _k(LogicalKeyboardKey.keyW),
          run: _desk.closePanel,
        ),
      ]),
      if (adv)
        DeskMenu(l.codeTabGit, [
          DeskCommand(
            id: 'git-commit',
            label: l.deskGitCommit,
            group: l.codeTabGit,
            icon: RgIcons.gitCommit,
            enabled: pid != null,
            shortcut: _k(LogicalKeyboardKey.keyC, shift: true),
            run: () => unawaited(commitInProject(context, _app, pid!)),
          ),
          DeskCommand(
            id: 'git-push',
            label: l.deskGitPush,
            group: l.codeTabGit,
            icon: RgIcons.upload,
            enabled: pid != null,
            shortcut: _k(LogicalKeyboardKey.keyP, shift: true),
            run: () => unawaited(pushProject(context, _app, pid!)),
          ),
          DeskCommand(
            id: 'git-history',
            label: l.deskGitHistory,
            group: l.codeTabGit,
            run: () => _desk.setView(DeskView.git),
          ),
        ]),
      DeskMenu(l.deskMenuWindow, [
        DeskCommand(
          id: 'dock-all',
          label: l.deskDockAll,
          group: l.deskMenuWindow,
          enabled: _desk.floating.isNotEmpty,
          run: _desk.dockAll,
        ),
        DeskCommand(
          id: 'close-floating',
          label: l.deskCloseFloating,
          group: l.deskMenuWindow,
          enabled: _desk.floating.isNotEmpty,
          run: () {
            for (final f in List.of(_desk.floating)) {
              _desk.closeFloating(f);
            }
          },
        ),
      ]),
      DeskMenu(l.deskMenuHelp, [
        DeskCommand(
          id: 'shortcuts',
          label: l.deskShortcuts,
          group: l.deskMenuHelp,
          shortcut: _k(LogicalKeyboardKey.slash),
          run: () => unawaited(_showShortcuts()),
        ),
        DeskCommand(
          id: 'about',
          label: l.deskAbout,
          group: l.deskMenuHelp,
          run: () => showAboutDialog(context: context, applicationName: 'RGCompanion'),
        ),
      ]),
    ];
  }

  Future<void> _showShortcuts() {
    final l = AppLocalizations.of(context);
    final menus = _menus(l);
    return showDialog<void>(
      context: context,
      builder: (ctx) {
        final c = RgColors.of(ctx);
        return AlertDialog(
          title: Text(l.deskShortcuts),
          content: SizedBox(
            width: 520,
            child: ListView(
              shrinkWrap: true,
              children: [
                for (final m in menus)
                  for (final it in m.items.whereType<DeskCommand>())
                    if (it.shortcut != null)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: Row(
                          children: [
                            SizedBox(
                              width: 170,
                              child: Align(
                                alignment: Alignment.centerLeft,
                                child: KeyCap(shortcutLabel(it.shortcut!, l, mac: _mac)),
                              ),
                            ),
                            Expanded(
                              child: Text(it.label, style: TextStyle(color: c.text)),
                            ),
                          ],
                        ),
                      ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: Text(l.deskClose)),
          ],
        );
      },
    );
  }

  // ---- layout ----

  Widget _view(DeskView v) => switch (v) {
    DeskView.team => TeamWall(feed: _feed),
    DeskView.projects => ProjectsWall(feed: _feed),
    DeskView.activity => Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 960),
        child: const ActivityScreen(),
      ),
    ),
    DeskView.code => const CodeView(),
    DeskView.terminals => const TerminalsView(),
    DeskView.git => const GitView(),
    DeskView.log => const LogView(),
  };

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    final l = AppLocalizations.of(context);
    final c = RgColors.of(context);
    return DeskScope(
      desk: _desk,
      child: ListenableBuilder(
        listenable: Listenable.merge([_desk, app.live]),
        builder: (context, _) {
          final menus = _menus(l);
          final bindings = deskBindings(menus, const [], mac: _mac);
          final size = MediaQuery.sizeOf(context);
          final connected = app.connected;
          final v = _desk.view;
          final panel = _desk.panel;
          Widget main;
          if (!connected) {
            main = Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 620),
                child: const YouScreen(),
              ),
            );
          } else {
            main = Column(
              children: [
                if (v != DeskView.team && v != DeskView.projects) const HeroStrip(),
                Expanded(
                  child: KeyedSubtree(key: ValueKey(v), child: _view(v)),
                ),
              ],
            );
          }
          final body = Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(child: main),
              if (panel != null && connected) ...[
                PanelResizer(
                  onDrag: (dx) => _desk.setPanelWidth(_desk.panelWidth - dx, size.width),
                  onKey: (dir) => _desk.setPanelWidth(_desk.panelWidth + dir * 24, size.width),
                ),
                SizedBox(
                  width: _desk.panelWidth.clamp(DeskController.minPanel, size.width * .6),
                  child: SidePanel(content: panel),
                ),
              ],
            ],
          );
          Widget room = Scaffold(
            backgroundColor: c.bg,
            body: Column(
              children: [
                _TopBar(menus: _mac ? null : menus, onPalette: _palette),
                Expanded(
                  child: Stack(
                    children: [
                      Positioned.fill(child: body),
                      if (_desk.floating.isNotEmpty) const Positioned.fill(child: FloatingLayer()),
                    ],
                  ),
                ),
                const _StatusBar(),
              ],
            ),
          );
          room = CallbackShortcuts(
            bindings: bindings,
            child: FocusScope(autofocus: true, child: room),
          );
          if (_mac) room = PlatformMenuBar(menus: platformMenus(menus, l), child: room);
          return room;
        },
      ),
    );
  }
}

class _TopBar extends StatelessWidget {
  const _TopBar({required this.menus, required this.onPalette});

  /// null on macOS: the menus are in the system's bar.
  final List<DeskMenu>? menus;
  final VoidCallback onPalette;

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    final desk = DeskScope.of(context);
    final l = AppLocalizations.of(context);
    final c = RgColors.of(context);
    final mac = isMacLike(app);
    final m = menus;
    final title = app.connected
        ? '${viewLabel(l, desk.view)} · ${app.displayName}'
        : 'RGCompanion';
    return Container(
      height: 44,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        color: c.panel,
        border: Border(bottom: BorderSide(color: c.line)),
      ),
      child: Row(
        children: [
          if (m != null) ...[
            DrawnMenuBar(menus: m),
            const SizedBox(width: 12),
          ],
          if (app.connected)
            _ViewTabs(views: desk.views, selected: desk.view, onSelect: desk.setView),
          Expanded(
            child: Text(
              title,
              key: const Key('desk-title'),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(fontSize: 13, color: c.dim, fontWeight: FontWeight.w500),
            ),
          ),
          if (app.connected)
            Tooltip(
              message: l.deskPaletteTitle,
              child: InkWell(
                key: const Key('desk-open-palette'),
                borderRadius: BorderRadius.circular(8),
                onTap: onPalette,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: c.bg,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: c.line),
                  ),
                  child: Row(
                    children: [
                      RgIcon(RgIcons.search, size: 14, color: c.dim),
                      const SizedBox(width: 6),
                      Text(l.deskSearchShort, style: TextStyle(fontSize: 12.5, color: c.dim)),
                      const SizedBox(width: 8),
                      KeyCap(
                        shortcutLabel(cmdKey(LogicalKeyboardKey.keyK, mac: mac), l, mac: mac),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _ViewTabs extends StatelessWidget {
  const _ViewTabs({required this.views, required this.selected, required this.onSelect});

  final List<DeskView> views;
  final DeskView selected;
  final ValueChanged<DeskView> onSelect;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final c = RgColors.of(context);
    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: c.panel2,
        borderRadius: BorderRadius.circular(9),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (final v in views)
            Semantics(
              button: true,
              selected: v == selected,
              child: Material(
                color: v == selected ? c.bg : Colors.transparent,
                borderRadius: BorderRadius.circular(7),
                child: InkWell(
                  key: Key('view-${v.name}'),
                  borderRadius: BorderRadius.circular(7),
                  onTap: () => onSelect(v),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    child: Row(
                      children: [
                        RgIcon(viewIcon(v), size: 14, color: v == selected ? c.text : c.dim),
                        const SizedBox(width: 6),
                        Text(
                          viewLabel(l, v),
                          style: TextStyle(
                            fontSize: 12.5,
                            color: v == selected ? c.text : c.dim,
                            fontWeight: v == selected ? FontWeight.w600 : FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _StatusBar extends StatelessWidget {
  const _StatusBar();

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    final desk = DeskScope.of(context);
    final l = AppLocalizations.of(context);
    final c = RgColors.of(context);
    final mac = isMacLike(app);
    final working = app.live.sessions.where((s) => s.running && !s.archived).map((s) => s.agentId).toSet().length;
    final reconnecting = app.isLive && app.liveStatus != LiveStatus.open;
    final style = TextStyle(fontSize: 12, color: c.dim);
    Widget item(RgIcons icon, String text, {Key? key, VoidCallback? onTap, Color? color}) => InkWell(
      key: key,
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            RgIcon(icon, size: 13, color: color ?? c.dim),
            const SizedBox(width: 5),
            Text(text, style: style.copyWith(color: color)),
          ],
        ),
      ),
    );
    return Container(
      key: const Key('desk-status'),
      height: 28,
      padding: const EdgeInsets.symmetric(horizontal: 6),
      decoration: BoxDecoration(
        color: c.panel,
        border: Border(top: BorderSide(color: c.line)),
      ),
      child: Row(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 6),
            child: Dot(!app.connected ? c.dim : (reconnecting ? c.warn : c.ok)),
          ),
          Text(
            !app.connected
                ? l.statusUnreachable
                : reconnecting
                ? l.statusReconnecting
                : app.displayName,
            style: style,
          ),
          if (app.connected) ...[
            const SizedBox(width: 6),
            item(
              RgIcons.bell,
              l.deskForYouCount(app.live.forYou),
              key: const Key('status-foryou'),
              color: app.live.forYou > 0 ? c.accent : null,
              onTap: () => desk.show(const PanelPage(PanelScreen.inbox)),
            ),
            item(RgIcons.users, l.deskWorkingCount(working)),
            if (app.advanced) ProjectStatusItem(desk: desk),
          ],
          const Spacer(),
          if (desk.floating.isNotEmpty)
            item(
              RgIcons.external,
              l.deskFloatingCount(desk.floating.length),
              onTap: desk.dockAll,
            ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Text(
              l.deskStatusPalette(
                shortcutLabel(cmdKey(LogicalKeyboardKey.keyK, mac: mac), l, mac: mac),
              ),
              style: style,
            ),
          ),
          if (app.connected)
            AdvancedPill(on: app.advanced, onTap: () => app.setAdvanced(!app.advanced)),
        ],
      ),
    );
  }
}

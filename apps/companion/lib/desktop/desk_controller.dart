// The computers' «control room» (G40.17, board C): what the window shows. The view in the middle
// (the wall, projects, activity and, with the advanced interface, code, terminals, git and log),
// the side panel (a conversation or a screen, resizable) and the panels taken out of it, which
// float inside the window. One ChangeNotifier per window, given to the tree by [DeskScope].
import 'dart:async';

import 'package:flutter/material.dart';

import '../api/code.dart';
import '../api/types.dart';
import '../app_state.dart';

/// The places in the bar at the top. The last four only with the advanced interface.
enum DeskView { team, projects, activity, code, terminals, git, log }

const basicViews = [DeskView.team, DeskView.projects, DeskView.activity];
const advancedViews = [DeskView.code, DeskView.terminals, DeskView.git, DeskView.log];

/// The wall's filter (the chips over it).
enum WallFilter { all, working, waiting, blocked }

/// What the side panel holds: a conversation, or one of the app's screens.
sealed class PanelContent {
  const PanelContent();

  /// Two contents with the same id are the same panel (its state is kept).
  String get id;
}

class PanelConversation extends PanelContent {
  const PanelConversation(this.sessionId, {this.agent, this.firstMessage});

  final String sessionId;
  final Agent? agent;

  /// Sent once the conversation opens (the God and Chat fields on the wall).
  final String? firstMessage;

  /// With a first message the conversation is made again, so that the message goes (a second
  /// question from God's field while God's conversation is open).
  @override
  String get id => firstMessage == null
      ? 'conversation:$sessionId'
      : 'conversation:$sessionId:${identityHashCode(this)}';
}

/// The screens that open in the panel (the phone's, reused as they are).
enum PanelScreen { inbox, chat, saved, you }

class PanelPage extends PanelContent {
  const PanelPage(this.screen);

  final PanelScreen screen;

  @override
  String get id => 'page:${screen.name}';
}

/// A conversation taken out of the panel: it floats inside the window (Flutter's own windows are
/// not stable enough on every system yet), moved by its title and resized from its corner.
class FloatingPanel {
  FloatingPanel(this.content, this.rect);

  final PanelConversation content;
  Rect rect;
}

/// A command the terminals view runs in the person's own shell (the palette's «!»).
class PendingCommand {
  const PendingCommand(this.projectId, this.command);

  final String projectId;
  final String command;
}

/// A file the code view opens (the palette's «#» and «:»).
class PendingFile {
  const PendingFile(this.projectId, this.path, {this.line});

  final String projectId;
  final String path;
  final int? line;
}

class DeskController extends ChangeNotifier {
  DeskController(this.app);

  final AppController app;

  DeskView view = DeskView.team;
  PanelContent? panel;
  double panelWidth = 440;
  final floating = <FloatingPanel>[];
  WallFilter wallFilter = WallFilter.all;

  /// The wall grouped by project (true) or by state.
  bool byProject = true;

  /// The project the advanced views look at (code, terminals, git, log).
  String? projectId;

  /// The Log's search, from the palette's «?».
  String? logQuery;
  PendingCommand? pendingCommand;
  PendingFile? pendingFile;

  static const minPanel = 320.0;

  /// The God and Chat fields at the top (Ctrl/Cmd+G and the Chat's shortcut focus them).
  final godFocus = FocusNode(debugLabel: 'god-field');
  final chatFocus = FocusNode(debugLabel: 'chat-field');

  @override
  void dispose() {
    godFocus.dispose();
    chatFocus.dispose();
    super.dispose();
  }

  List<DeskView> get views => [...basicViews, if (app.advanced) ...advancedViews];

  void setView(DeskView v) {
    if (!views.contains(v)) return;
    if (view == v) return;
    view = v;
    notifyListeners();
  }

  /// Back to a basic view when the advanced interface goes off.
  void advancedChanged() {
    if (!views.contains(view)) {
      view = DeskView.projects;
      notifyListeners();
    }
  }

  void setFilter(WallFilter f) {
    wallFilter = wallFilter == f ? WallFilter.all : f;
    notifyListeners();
  }

  void setByProject(bool v) {
    byProject = v;
    notifyListeners();
  }

  void setProject(String? id) {
    if (projectId == id) return;
    projectId = id;
    notifyListeners();
  }

  /// The project the advanced views use: the chosen one, else the first not archived.
  String? projectOr() => projectId ?? app.projects.where((p) => !p.archived).firstOrNull?.id;

  // ---- the side panel ----

  void show(PanelContent c) {
    // Already floating: brought to the front instead of shown twice.
    if (c is PanelConversation) {
      final f = floating.where((x) => x.content.sessionId == c.sessionId).firstOrNull;
      if (f != null) {
        final first = c.firstMessage;
        if (first != null) unawaited(app.send(c.sessionId, first));
        floating
          ..remove(f)
          ..add(f);
        notifyListeners();
        return;
      }
    }
    panel = c;
    notifyListeners();
  }

  void closePanel() {
    if (panel == null) return;
    panel = null;
    notifyListeners();
  }

  /// Ctrl+\: the panel shows again what it showed last, or the requests for the person.
  PanelContent? _last;
  void togglePanel() {
    final p = panel;
    if (p != null) {
      _last = p is PanelConversation ? PanelConversation(p.sessionId, agent: p.agent) : p;
      panel = null;
    } else {
      panel = _last ?? const PanelPage(PanelScreen.inbox);
    }
    notifyListeners();
  }

  void setPanelWidth(double w, double window) {
    final max = (window * .6).clamp(minPanel, 1400.0);
    panelWidth = w.clamp(minPanel, max);
    notifyListeners();
  }

  /// The agent whose conversation the panel shows (its tile is lit on the wall).
  String? get panelAgentId {
    final p = panel;
    if (p is! PanelConversation) return null;
    return p.agent?.id ?? app.live.sessions.where((s) => s.id == p.sessionId).firstOrNull?.agentId;
  }

  /// Takes the panel's conversation out: it floats over the window.
  void detach(Size window) {
    final p = panel;
    if (p is! PanelConversation) return;
    panel = null;
    final n = floating.length;
    final w = (window.width * .38).clamp(360.0, 560.0);
    final h = (window.height * .7).clamp(360.0, 760.0);
    final left = (window.width - w - 40 - n * 28).clamp(0.0, window.width - w);
    // Without its first message: it was sent when the panel opened.
    floating.add(
      FloatingPanel(
        PanelConversation(p.sessionId, agent: p.agent),
        Rect.fromLTWH(left, 70.0 + n * 28, w, h),
      ),
    );
    notifyListeners();
  }

  /// Opens a conversation floating at once (the palette's Ctrl+Enter).
  void showFloating(PanelConversation c, Size window) {
    panel = c;
    detach(window);
  }

  void moveFloating(FloatingPanel f, Rect r, Size window) {
    final w = r.width.clamp(300.0, window.width);
    final h = r.height.clamp(260.0, window.height);
    f.rect = Rect.fromLTWH(
      r.left.clamp(0.0, (window.width - 120).clamp(0.0, double.infinity)),
      r.top.clamp(0.0, (window.height - 48).clamp(0.0, double.infinity)),
      w,
      h,
    );
    notifyListeners();
  }

  void raise(FloatingPanel f) {
    if (floating.last == f) return;
    floating
      ..remove(f)
      ..add(f);
    notifyListeners();
  }

  /// Back into the side panel (the one there goes away).
  void dock(FloatingPanel f) {
    floating.remove(f);
    panel = f.content;
    notifyListeners();
  }

  void closeFloating(FloatingPanel f) {
    floating.remove(f);
    notifyListeners();
  }

  void dockAll() {
    if (floating.isEmpty) return;
    panel = floating.last.content;
    floating.clear();
    notifyListeners();
  }

  // ---- what the palette asks other views to do ----

  void runInTerminal(String projectId, String command) {
    this.projectId = projectId;
    pendingCommand = PendingCommand(projectId, command);
    view = app.advanced ? DeskView.terminals : view;
    notifyListeners();
  }

  PendingCommand? takeCommand() {
    final c = pendingCommand;
    pendingCommand = null;
    return c;
  }

  /// A diff for the code view (a commit's, from Git).
  ({String projectId, DiffSource source})? pendingDiff;

  void openDiff(String projectId, DiffSource source) {
    this.projectId = projectId;
    pendingDiff = (projectId: projectId, source: source);
    view = DeskView.code;
    notifyListeners();
  }

  ({String projectId, DiffSource source})? takeDiff() {
    final d = pendingDiff;
    pendingDiff = null;
    return d;
  }

  void openFile(String projectId, String path, {int? line}) {
    this.projectId = projectId;
    pendingFile = PendingFile(projectId, path, line: line);
    view = DeskView.code;
    notifyListeners();
  }

  PendingFile? takeFile() {
    final f = pendingFile;
    pendingFile = null;
    return f;
  }

  void searchLog(String q, {String? projectId}) {
    if (projectId != null) this.projectId = projectId;
    logQuery = q;
    view = DeskView.log;
    notifyListeners();
  }

  // ---- opening agents ----

  /// [a]'s conversation in the panel (God's shared one, else the latest); false when it failed.
  Future<bool> openAgent(Agent a, {bool fresh = false, String? firstMessage}) async {
    final id = await app.openAgent(a, fresh: fresh);
    if (id == null) return false;
    show(PanelConversation(id, agent: a, firstMessage: firstMessage));
    return true;
  }

  /// A new Chat conversation that starts with [text].
  Future<bool> startChat(String text) async {
    final id = await app.newChatSession();
    if (id == null) return false;
    show(PanelConversation(id, agent: app.chatAgent, firstMessage: text));
    return true;
  }

  /// Sends [text] to [a] without opening its conversation (the palette's Tab).
  Future<bool> askQuietly(Agent a, String text) async {
    final id = await app.openAgent(a);
    if (id == null) return false;
    return app.send(id, text);
  }
}

class DeskScope extends InheritedNotifier<DeskController> {
  const DeskScope({super.key, required DeskController desk, required super.child})
    : super(notifier: desk);

  static DeskController of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<DeskScope>()!.notifier!;

  static DeskController read(BuildContext context) =>
      context.getInheritedWidgetOfExactType<DeskScope>()!.notifier!;

  static DeskController? maybeRead(BuildContext context) =>
      context.getInheritedWidgetOfExactType<DeskScope>()?.notifier;
}

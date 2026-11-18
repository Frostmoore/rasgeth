// The Canvas's tabs (G42.2, G42.6), as the page's side area keeps them (`sideViews`,
// `activeSide`, `openCanvas`, `closeSide` in state.ts): one tab per file and one per agent's port,
// the same thing again brings its tab forward, the area closes with its last tab. Per tab, what the
// page inside said of it (its kind and weight, the save state, its bar), and which tabs were seen
// last: only a few web views stay alive together (the page's WARM_TABS), the others load again
// when they come back.
import 'dart:math' as math;

import 'package:flutter/foundation.dart';

import '../embed/bridge.dart';

/// One thing in the Canvas: its tab's id (the page's `canvasViewId`), its name and target.
class CanvasTab {
  const CanvasTab({required this.id, required this.title, required this.target});

  final String id;
  final String title;
  final Map<String, dynamic> target;

  bool get isPort => target['kind'] == 'port';
  String? get scope => target['scope'] as String?;
  String? get path => target['path'] as String?;
  String? get agentId => target['agentId'] as String?;
  int? get port => (target['port'] as num?)?.toInt();

  /// The page's `at`: where a citation opens (a PDF's page, a text's line).
  int? get page => ((target['at'] as Map?)?['page'] as num?)?.toInt();
  int? get line => ((target['at'] as Map?)?['line'] as num?)?.toInt();

  /// Whether the app can show it: a file with its place, or a port of an agent.
  bool get valid => isPort
      ? agentId != null && port != null
      : target['kind'] == 'file' && scope != null && path != null;

  /// The file's own name (the tab's words when it has none).
  String get fileName => (path ?? '').split(RegExp(r'[\\/]')).where((s) => s.isNotEmpty).lastOrNull ?? '';

  /// The target as the protocol's `CanvasTargetSchema` has it (for the page's `tabs`).
  Map<String, Object?> get wireTarget => isPort
      ? {'kind': 'port', 'agentId': agentId, 'port': port, 'path': ?path}
      : {
          'kind': 'file',
          'scope': scope,
          'path': path,
          if (page != null || line != null) 'at': {'page': ?page, 'line': ?line},
        };
}

/// The page's `canvasViewId`: one tab per file, one per agent's port and path.
String canvasTabId(Map<String, dynamic> target) => target['kind'] == 'file'
    ? 'canvas:${target['scope']}:${target['path']}'
    : 'canvas:${target['agentId']}:${target['port']}:${target['path'] ?? ''}';

/// What the page inside a tab said of it.
class CanvasTabInfo {
  const CanvasTabInfo({this.name, this.kind, this.size, this.save, this.saveError, this.bar});

  /// The page's `title`: the name, the viewer's kind (`vwKind_*`), the weight.
  final String? name;
  final String? kind;
  final int? size;

  /// The editor's `saveState` (G42.7): saving, saved, error.
  final String? save;
  final String? saveError;

  /// The tab's own buttons, the agent's move, the signed link (`bar`).
  final EmbedBar? bar;

  CanvasTabInfo copyWith({
    String? name,
    String? kind,
    int? size,
    String? save,
    String? saveError,
    EmbedBar? bar,
  }) => CanvasTabInfo(
    name: name ?? this.name,
    kind: kind ?? this.kind,
    size: size ?? this.size,
    save: save ?? this.save,
    saveError: save != null ? saveError : this.saveError,
    bar: bar ?? this.bar,
  );
}

/// How many web views stay alive together: the page's WARM_TABS (3) on a computer, two on a
/// phone (memory), one on Linux (WebKitGTK's views are native windows over Flutter: a hidden one
/// must not stay drawn).
int canvasAliveMax({required bool phone, required bool linux}) => linux ? 1 : (phone ? 2 : 3);

/// The Canvas of one conversation screen: its tabs, the one in front, whether it shows, its width.
class CanvasPanelModel extends ChangeNotifier {
  final List<CanvasTab> tabs = [];
  String? active;
  bool open = false;

  /// The panel's width, set by the divider (null: the default, 46% of the screen).
  double? width;

  /// «Maximize» (the page's `sideMax`): the area over the conversation, on a computer.
  bool max = false;

  /// The whole screen (the page's Fullscreen button): only the content, its own way out.
  bool full = false;

  /// What the page said of each tab.
  final Map<String, CanvasTabInfo> info = {};

  /// Tabs seen, most recent first (the page's `recentSide`).
  final List<String> recent = [];

  CanvasTab? get current => tabs.where((t) => t.id == active).firstOrNull;

  /// The tabs whose web view stays alive: the one in front and the last ones seen, [most] in all.
  Set<String> alive(int most) {
    final out = <String>{?active};
    for (final id in recent) {
      if (out.length >= most) break;
      if (tabs.any((t) => t.id == id)) out.add(id);
    }
    return out;
  }

  void _seen(String id) {
    recent
      ..remove(id)
      ..insert(0, id);
    if (recent.length > 20) recent.removeRange(20, recent.length);
  }

  /// The page's `openCanvas`: a new tab, or the same one brought forward (with the new name and
  /// target, unless [keep]: an agent moving in a tab leaves it as it is); the panel shows.
  void show(String title, Map<String, dynamic> target, {bool keep = false}) {
    final tab = CanvasTab(id: canvasTabId(target), title: title, target: target);
    if (!tab.valid) return;
    final at = tabs.indexWhere((t) => t.id == tab.id);
    if (at < 0) {
      tabs.add(tab);
    } else if (!keep) {
      tabs[at] = tab;
    }
    active = tab.id;
    _seen(tab.id);
    open = true;
    notifyListeners();
  }

  /// A tab closed; the area closes with its last one.
  void close(String id) {
    final at = tabs.indexWhere((t) => t.id == id);
    if (at < 0) return;
    tabs.removeAt(at);
    info.remove(id);
    recent.remove(id);
    if (active == id) active = tabs.isEmpty ? null : tabs[math.min(at, tabs.length - 1)].id;
    if (tabs.isEmpty) {
      open = false;
      max = false;
      full = false;
    }
    notifyListeners();
  }

  void select(String id) {
    if (!tabs.any((t) => t.id == id)) return;
    active = id;
    _seen(id);
    notifyListeners();
  }

  /// «Back to the chat»: the area goes, its tabs stay (the line in the chat brings it back).
  void hide() {
    open = false;
    max = false;
    full = false;
    notifyListeners();
  }

  void resize(double w) {
    width = w;
    notifyListeners();
  }

  /// The divider's double tap: back to the normal width.
  void resetWidth() {
    width = null;
    notifyListeners();
  }

  void setMax(bool v) {
    if (max == v) return;
    max = v;
    notifyListeners();
  }

  void setFull(bool v) {
    if (full == v) return;
    full = v;
    notifyListeners();
  }

  /// What the page inside [id] said; nothing for a tab that is gone.
  void tell(String id, CanvasTabInfo Function(CanvasTabInfo was) change) {
    if (!tabs.any((t) => t.id == id)) return;
    info[id] = change(info[id] ?? const CanvasTabInfo());
    notifyListeners();
  }

  /// The app's tabs as the page's `tabs` message names them (G42.6).
  List<Map<String, Object?>> wireTabs() => [
    for (final t in tabs.length > 50 ? tabs.sublist(tabs.length - 50) : tabs)
      {
        'title': t.title.length > 300 ? t.title.substring(0, 300) : t.title,
        'target': t.wireTarget,
        'active': t.id == active,
      },
  ];
}

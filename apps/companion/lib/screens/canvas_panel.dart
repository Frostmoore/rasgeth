// The Canvas next to the conversation (G42.2), as the page's area on the right (SideArea.tsx,
// `openCanvas` and `canvasEvent` in state.ts): what an agent shows (a file, or a site on one of
// its ports) opens by itself while the person watches, in a tab of its own (the same thing
// again brings its tab forward), even after the person closed the area; never when the log
// replays. On a computer it is a panel on the right of the conversation, its width dragged by
// the divider, with the page alive in a web view (`embed=port`, `embed=canvas`) and the page's
// commands (reload, open in the browser, close). Where the conversation is narrow (a phone, a
// tablet with a finger) it covers the chat as the page's area does: the screen opens whole.
import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../app_state.dart';
import '../embed/embed_link.dart';
import '../embed/embed_screen.dart';
import '../embed/embed_view.dart';
import '../l10n/app_localizations.dart';
import '../theme/colors.dart';
import '../ui/icons.dart';
import 'canvas_screen.dart';
import 'first_start_screen.dart' show openExternal;

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

  /// Whether the app can show it: a file with its place, or a port of an agent.
  bool get valid => isPort
      ? agentId != null && port != null
      : target['kind'] == 'file' && scope != null && path != null;
}

/// The page's `canvasViewId`: one tab per file, one per agent's port and path.
String canvasTabId(Map<String, dynamic> target) => target['kind'] == 'file'
    ? 'canvas:${target['scope']}:${target['path']}'
    : 'canvas:${target['agentId']}:${target['port']}:${target['path'] ?? ''}';

/// The narrowest a conversation is drawn with the panel beside it; below this the Canvas covers
/// the chat (the page's `COVER_MAX` with a finger, `PHONE_MAX` with a mouse).
double canvasBesideFrom(TargetPlatform p) =>
    p == TargetPlatform.android || p == TargetPlatform.iOS ? 1100 : 760;

/// The Canvas of one conversation screen: its tabs, the one in front, whether it shows, its width.
class CanvasPanelModel extends ChangeNotifier {
  final List<CanvasTab> tabs = [];
  String? active;
  bool open = false;

  /// The panel's width, set by the divider (null: the default, 46% of the screen).
  double? width;

  CanvasTab? get current => tabs.where((t) => t.id == active).firstOrNull;

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
    open = true;
    notifyListeners();
  }

  /// A tab closed; the area closes with its last one.
  void close(String id) {
    final at = tabs.indexWhere((t) => t.id == id);
    if (at < 0) return;
    tabs.removeAt(at);
    if (active == id) active = tabs.isEmpty ? null : tabs[math.min(at, tabs.length - 1)].id;
    if (tabs.isEmpty) open = false;
    notifyListeners();
  }

  void select(String id) {
    active = id;
    notifyListeners();
  }

  /// «Back to the chat»: the area goes, its tabs stay (the line in the chat brings it back).
  void hide() {
    open = false;
    notifyListeners();
  }

  void resize(double w) {
    width = w;
    notifyListeners();
  }
}

/// The whole screen for one thing (the narrow way): a port is the page in `embed=port`, a file
/// opens in the Canvas screen.
Future<void> openCanvasTab(BuildContext context, CanvasTab t, {String? sessionId}) {
  if (t.isPort) {
    return openPortPreview(
      context,
      agentId: t.agentId!,
      port: t.port!,
      path: t.path,
      title: t.title,
      sessionId: sessionId,
    );
  }
  return openCanvas(context, scope: t.scope!, path: t.path!, title: t.title, sessionId: sessionId);
}

/// The address of the page for [t] (`embed=port` or `embed=canvas`).
EmbedParams canvasEmbed(EmbedContext e, CanvasTab t, String nonce, {String? sessionId}) => t.isPort
    ? EmbedParams(
        token: e.token,
        embed: EmbedKind.port,
        bridge: nonce,
        theme: e.theme,
        lang: e.lang,
        agent: t.agentId,
        port: t.port,
        path: t.path,
        session: sessionId,
      )
    : EmbedParams(
        token: e.token,
        embed: EmbedKind.canvas,
        bridge: nonce,
        theme: e.theme,
        lang: e.lang,
        scope: t.scope,
        path: t.path,
        session: sessionId,
      );

/// The panel on the right: the divider, the bar (tabs, reload, open in the browser, back to the
/// chat), and the tab in front as the page shows it.
class CanvasPanel extends StatefulWidget {
  const CanvasPanel({super.key, required this.model, required this.maxWidth, this.sessionId});

  final CanvasPanelModel model;

  /// The whole width the conversation and the panel share.
  final double maxWidth;
  final String? sessionId;

  @override
  State<CanvasPanel> createState() => _CanvasPanelState();
}

class _CanvasPanelState extends State<CanvasPanel> {
  EmbedContext? _embed;
  final _nonces = <String, String>{};
  final _views = <String, GlobalKey<EmbedViewState>>{};

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    unawaited(
      embedContextOf(context).then((e) {
        if (mounted && (e?.theme != _embed?.theme || e?.lang != _embed?.lang || _embed == null)) {
          setState(() => _embed = e);
        }
      }),
    );
  }

  double get _width {
    final w = widget.model.width ?? widget.maxWidth * .46;
    return w.clamp(320.0, math.max(320.0, widget.maxWidth - 360));
  }

  Future<void> _outside(CanvasTab t) async {
    final l = AppLocalizations.of(context);
    final app = AppScope.read(context);
    try {
      final c = app.client ?? (throw StateError('Not connected'));
      final link = t.isPort
          ? await c.portLink(t.agentId!, t.port!, path: t.path)
          : (await c.canvasLink(t.scope!, t.path!)).url;
      await openExternal(c.base.resolve(link));
    } on Object catch (e) {
      if (mounted) {
        ScaffoldMessenger.maybeOf(context)
            ?.showSnackBar(SnackBar(content: Text(l.errGeneric('$e'))));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = RgColors.of(context);
    final l = AppLocalizations.of(context);
    final m = widget.model;
    final t = m.current;
    final e = _embed;
    return SizedBox(
      key: const Key('canvas-panel'),
      width: _width,
      child: Row(
        children: [
          // The divider: dragged, the panel grows or shrinks (the page's `Divider`).
          MouseRegion(
            cursor: SystemMouseCursors.resizeColumn,
            child: GestureDetector(
              key: const Key('canvas-divider'),
              behavior: HitTestBehavior.opaque,
              onHorizontalDragUpdate: (d) => m.resize(_width - d.delta.dx),
              child: SizedBox(
                width: 7,
                child: Center(child: Container(width: 1, color: c.line)),
              ),
            ),
          ),
          Expanded(
            child: ColoredBox(
              color: c.bg,
              child: Column(
                children: [
                  Container(
                    height: 44,
                    decoration: BoxDecoration(
                      color: c.panel,
                      border: Border(bottom: BorderSide(color: c.line)),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: ListView(
                            scrollDirection: Axis.horizontal,
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
                            children: [
                              for (final tab in m.tabs)
                                _Tab(
                                  key: Key('canvas-tab-${tab.id}'),
                                  tab: tab,
                                  on: tab.id == m.active,
                                  onTap: () => m.select(tab.id),
                                  onClose: () => m.close(tab.id),
                                ),
                            ],
                          ),
                        ),
                        if (t != null) ...[
                          IconButton(
                            key: const Key('canvas-panel-reload'),
                            tooltip: l.cvCanvasReload,
                            onPressed: () => _views[t.id]?.currentState?.reload(),
                            icon: RgIcon(RgIcons.refresh, size: 16, color: c.dim),
                          ),
                          IconButton(
                            key: const Key('canvas-panel-outside'),
                            tooltip: l.embedOpenInBrowser,
                            onPressed: () => _outside(t),
                            icon: RgIcon(RgIcons.external, size: 16, color: c.dim),
                          ),
                        ],
                        IconButton(
                          key: const Key('canvas-panel-hide'),
                          tooltip: l.cvVwToChat,
                          onPressed: m.hide,
                          icon: RgIcon(RgIcons.x, size: 16, color: c.dim),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: t == null || e == null
                        ? const SizedBox.expand()
                        : EmbedView(
                            // One web view, the tab in front: another tab loads its own page.
                            key: _views.putIfAbsent(t.id, GlobalKey<EmbedViewState>.new),
                            url: embedUrl(
                              e.base,
                              canvasEmbed(
                                e,
                                t,
                                _nonces.putIfAbsent(t.id, newEmbedNonce),
                                sessionId: widget.sessionId,
                              ),
                            ),
                            nonce: _nonces[t.id],
                            leaf: e.leaf,
                            handleBack: false,
                          ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Tab extends StatelessWidget {
  const _Tab({
    super.key,
    required this.tab,
    required this.on,
    required this.onTap,
    required this.onClose,
  });

  final CanvasTab tab;
  final bool on;
  final VoidCallback onTap;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    final c = RgColors.of(context);
    final l = AppLocalizations.of(context);
    return Padding(
      padding: const EdgeInsets.only(right: 4),
      child: Material(
        color: on ? c.bg : Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: BorderSide(color: on ? c.line : Colors.transparent),
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(8),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.only(left: 10, right: 2),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                RgIcon(tab.isPort ? RgIcons.globe : RgIcons.file, size: 13, color: c.dim),
                const SizedBox(width: 6),
                ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 180),
                  child: Text(
                    tab.title.isEmpty ? (tab.path ?? l.cvEmbedPort('${tab.port}')) : tab.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: on ? c.text : c.dim,
                      fontSize: 13,
                      fontWeight: on ? FontWeight.w600 : FontWeight.w400,
                    ),
                  ),
                ),
                IconButton(
                  key: Key('canvas-tab-close-${tab.id}'),
                  tooltip: l.cvClose,
                  visualDensity: VisualDensity.compact,
                  iconSize: 14,
                  onPressed: onClose,
                  icon: RgIcon(RgIcons.x, size: 12, color: c.dim),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// The Canvas's frame (G42.6), native around the page's own viewers. As the page's side area
// (SideArea.tsx) and the Canvas's head (Canvas.tsx): a strip of tabs with «Chat» and «Maximize»,
// then the tab's bar (its name, kind and weight from the page's `title`, the save state, what the
// agent just did, the tab's own buttons the page sends with `bar`, the keyboard map, «Reload»,
// «Download», «Full screen», «Open in the browser»). The content is the page in `embed=canvas`
// (a file: every viewer the page has, from its bytes) or `embed=port` (an agent's site), one web
// view per tab, a few alive together (`canvasAliveMax`), the others loaded again on return. When
// the page cannot be shown (the first start's channel, plain http over the network) or does not
// answer, the app's own viewers stand in (`CanvasNativeBody`).
//
// On a computer it is a panel beside the conversation, its width dragged by the divider, that can
// be maximized over the conversation; where the conversation is narrow (a phone) it is a screen of
// its own, with the same tabs. The page inside answers an agent that looks (`canvas.query`) for
// the app's Canvas: the app tells every page its tabs and which one is in view (`tabs`).
import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../api/types.dart';
import '../app_state.dart';
import '../embed/bridge.dart';
import '../embed/embed_link.dart';
import '../embed/embed_screen.dart';
import '../embed/embed_view.dart';
import '../l10n/app_localizations.dart';
import '../screens/canvas_screen.dart';
import '../screens/first_start_screen.dart' show openExternal;
import '../theme/colors.dart';
import '../ui/artifact_frame_view.dart' show FrameSupport, frameSupportOf;
import '../ui/chat/file_download.dart' show saveChatFile;
import '../ui/file_icons.dart';
import '../ui/icons.dart';
import 'canvas_model.dart';

export 'canvas_model.dart';

/// The narrowest a conversation is drawn with the panel beside it; below this the Canvas covers
/// the chat (the page's `COVER_MAX` with a finger, `PHONE_MAX` with a mouse).
double canvasBesideFrom(TargetPlatform p) =>
    p == TargetPlatform.android || p == TargetPlatform.iOS ? 1100 : 760;

/// The panel's width in [maxWidth]: the divider's, else 46%; the conversation keeps 360.
double canvasPanelWidth(CanvasPanelModel m, double maxWidth) {
  final w = m.width ?? maxWidth * .46;
  return w.clamp(320.0, math.max(320.0, maxWidth - 360));
}

/// Whether the page can be shown inside the app (a safe way to the server, a web view here).
bool canvasEmbedWay(AppController app) => frameSupportOf(app) != FrameSupport.none;

/// The conversation's Canvas, for what opens a file from inside it (a card, an attachment, a
/// widget): its tab, not a screen of its own.
class CanvasHost extends InheritedWidget {
  const CanvasHost({super.key, required this.show, required super.child});

  /// Opens (or brings forward) [target] in the conversation's Canvas.
  final void Function(String title, Map<String, dynamic> target) show;

  static CanvasHost? maybeOf(BuildContext context) =>
      context.getInheritedWidgetOfExactType<CanvasHost>();

  @override
  bool updateShouldNotify(CanvasHost old) => false;
}

/// Opens [target] in the Canvas: the conversation's around [context], else a Canvas screen of its
/// own; a file opens on the native screen when the page cannot be shown inside the app.
Future<void> showInCanvas(
  BuildContext context, {
  required String title,
  required Map<String, dynamic> target,
  String? sessionId,
}) async {
  final host = CanvasHost.maybeOf(context);
  if (host != null) {
    host.show(title, target);
    return;
  }
  final app = AppScope.read(context);
  if (!canvasEmbedWay(app) && target['kind'] == 'file') {
    return openNativeCanvas(
      context,
      scope: target['scope'] as String,
      path: target['path'] as String,
      title: title,
      sessionId: sessionId,
    );
  }
  final m = CanvasPanelModel()..show(title, target);
  await openCanvasScreen(context, m, sessionId: sessionId);
  m.dispose();
}

/// The Canvas on a screen of its own (a phone, or a file opened outside a conversation).
Future<void> openCanvasScreen(
  BuildContext context,
  CanvasPanelModel model, {
  String? sessionId,
  void Function(String text, Map<String, Object?> ref)? onAskAgent,
}) => Navigator.of(context).push(
  MaterialPageRoute<void>(
    settings: const RouteSettings(name: canvasRouteName),
    builder: (_) => CanvasScreenShell(model: model, sessionId: sessionId, onAskAgent: onAskAgent),
  ),
);

/// The Canvas screen's route name (a conversation knows its Canvas is in front).
const canvasRouteName = 'canvas';

/// The Canvas as a whole screen.
class CanvasScreenShell extends StatelessWidget {
  const CanvasScreenShell({super.key, required this.model, this.sessionId, this.onAskAgent});

  final CanvasPanelModel model;
  final String? sessionId;
  final void Function(String text, Map<String, Object?> ref)? onAskAgent;

  @override
  Widget build(BuildContext context) {
    final c = RgColors.of(context);
    return ListenableBuilder(
      listenable: model,
      // The whole screen ends first with back, then the Canvas goes.
      builder: (context, _) => PopScope(
        canPop: !model.full,
        onPopInvokedWithResult: (didPop, _) {
          if (!didPop && model.full) model.setFull(false);
        },
        child: Scaffold(
          key: const Key('canvas-screen'),
          backgroundColor: c.bg,
          body: SafeArea(
            top: !model.full,
            bottom: !model.full,
            child: CanvasShell(
              model: model,
              sessionId: sessionId,
              whole: true,
              onAskAgent: onAskAgent,
              onClose: () => Navigator.of(context).maybePop(),
            ),
          ),
        ),
      ),
    );
  }
}

/// The panel on the right of the conversation: the divider, then the frame.
class CanvasPanel extends StatelessWidget {
  const CanvasPanel({
    super.key,
    required this.model,
    required this.maxWidth,
    this.sessionId,
    this.top,
    this.visible = true,
    this.onAskAgent,
  });

  final CanvasPanelModel model;

  /// The whole width the conversation and the panel share.
  final double maxWidth;
  final String? sessionId;

  /// Above the strip: the right column's tabs (Files, Canvas) when both are open.
  final Widget? top;

  /// Whether the panel is in front (not behind the files' tab).
  final bool visible;
  final void Function(String text, Map<String, Object?> ref)? onAskAgent;

  @override
  Widget build(BuildContext context) {
    final c = RgColors.of(context);
    final m = model;
    final width = canvasPanelWidth(m, maxWidth);
    final over = m.max || m.full;
    return SizedBox(
      key: const Key('canvas-panel'),
      width: over ? maxWidth : width,
      child: Row(
        children: [
          // The divider: dragged, the panel grows or shrinks (the page's `Divider`); a double tap
          // gives back the normal width.
          if (!over)
            MouseRegion(
              cursor: SystemMouseCursors.resizeColumn,
              child: GestureDetector(
                key: const Key('canvas-divider'),
                behavior: HitTestBehavior.opaque,
                onHorizontalDragUpdate: (d) => m.resize(width - d.delta.dx),
                onDoubleTap: m.resetWidth,
                child: SizedBox(
                  width: 7,
                  child: Center(child: Container(width: 1, color: c.line)),
                ),
              ),
            ),
          Expanded(
            child: ColoredBox(
              color: c.bg,
              child: CanvasShell(
                model: m,
                sessionId: sessionId,
                top: top,
                visible: visible,
                onAskAgent: onAskAgent,
                onClose: m.hide,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// The page's words for a viewer's kind (`vwKind_*`).
String viewerKindWord(AppLocalizations l, String kind) => switch (kind) {
  'video' => l.cvVwKindVideo,
  'audio' => l.cvVwKindAudio,
  'image' => l.cvVwKindImage,
  'pdf' => l.cvVwKindPdf,
  'markdown' => l.cvVwKindMarkdown,
  'code' => l.cvVwKindCode,
  'text' => l.cvVwKindText,
  'table' => l.cvVwKindTable,
  'sheet' => l.cvVwKindSheet,
  'document' => l.cvVwKindDocument,
  'slides' => l.cvVwKindSlides,
  'model' => l.cvVwKindModel,
  'archive' => l.cvVwKindArchive,
  'font' => l.cvVwKindFont,
  'tree' => l.cvVwKindTree,
  'site' => l.cvVwKindSite,
  'layers' => l.cvVwKindLayers,
  _ => l.cvVwKindUnknown,
};

String _bytes(int n) => n < 1024
    ? '$n B'
    : n < 1024 * 1024
    ? '${(n / 1024).toStringAsFixed(0)} KB'
    : '${(n / 1024 / 1024).toStringAsFixed(1)} MB';

RgIcons _actionIcon(String? icon) => switch (icon) {
  'play' => RgIcons.play,
  'code' => RgIcons.code,
  'folderPlus' => RgIcons.folderPlus,
  'pencil' => RgIcons.pencil,
  'brush' => RgIcons.brush,
  'alert' => RgIcons.alert,
  'keyboard' => RgIcons.keyboard,
  _ => RgIcons.zap,
};

/// The frame: strip, bar, content.
class CanvasShell extends StatefulWidget {
  const CanvasShell({
    super.key,
    required this.model,
    this.sessionId,
    this.top,
    this.whole = false,
    this.visible = true,
    this.onClose,
    this.onAskAgent,
  });

  final CanvasPanelModel model;
  final String? sessionId;
  final Widget? top;

  /// A screen of its own (a phone): «Back» instead of «Chat», no «Maximize».
  final bool whole;
  final bool visible;

  /// «Chat» (the area goes, the tabs stay) or, on a screen of its own, back.
  final VoidCallback? onClose;

  /// «Ask the agent» from the page (a selection and where it is): to the conversation.
  final void Function(String text, Map<String, Object?> ref)? onAskAgent;

  @override
  State<CanvasShell> createState() => CanvasShellState();
}

class CanvasShellState extends State<CanvasShell> with WidgetsBindingObserver {
  EmbedContext? _embed;
  bool _asked = false;
  final _nonces = <String, String>{};
  final _views = <String, GlobalKey<EmbedViewState>>{};
  bool _resumed = true;

  CanvasPanelModel get _m => widget.model;
  final _tabKeys = <String, GlobalKey>{};
  String? _shownTab;

  /// The tab in front is always in sight in the strip, however many there are (as the page's).
  void _revealTab() {
    final id = _m.active;
    if (id == null || id == _shownTab) return;
    _shownTab = id;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final ctx = _tabKeys[id]?.currentContext;
      if (ctx != null && ctx.mounted) {
        unawaited(
          Scrollable.ensureVisible(
            ctx,
            duration: const Duration(milliseconds: 150),
            alignmentPolicy: ScrollPositionAlignmentPolicy.keepVisibleAtEnd,
          ),
        );
        unawaited(
          Scrollable.ensureVisible(
            ctx,
            duration: const Duration(milliseconds: 150),
            alignmentPolicy: ScrollPositionAlignmentPolicy.keepVisibleAtStart,
          ),
        );
      }
    });
  }

  /// Tests: the web view of a tab, when it is alive.
  EmbedViewState? viewOf(String id) => _views[id]?.currentState;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _m.addListener(_changed);
  }

  @override
  void didUpdateWidget(CanvasShell oldWidget) {
    super.didUpdateWidget(oldWidget);
    final old = oldWidget;
    if (old.model != widget.model) {
      old.model.removeListener(_changed);
      widget.model.addListener(_changed);
    }
    if (old.visible != widget.visible) _tellTabs();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _m.removeListener(_changed);
    if (_m.full) unawaited(SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge));
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final now = state == AppLifecycleState.resumed || state == AppLifecycleState.inactive;
    if (now != _resumed) {
      _resumed = now;
      _tellTabs();
    }
  }

  bool _wasFull = false;

  void _changed() {
    if (!mounted) return;
    // Views of tabs that closed go, with their nonce.
    final ids = {for (final t in _m.tabs) t.id};
    _views.removeWhere((id, _) => !ids.contains(id));
    _nonces.removeWhere((id, _) => !ids.contains(id));
    if (_m.full != _wasFull && _phone) {
      _wasFull = _m.full;
      unawaited(
        SystemChrome.setEnabledSystemUIMode(
          _m.full ? SystemUiMode.immersiveSticky : SystemUiMode.edgeToEdge,
        ),
      );
    }
    setState(() {});
    _tellTabs();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final app = AppScope.read(context);
    if (!canvasEmbedWay(app)) {
      _asked = true;
      return;
    }
    unawaited(
      embedContextOf(context).then((e) {
        if (!mounted) return;
        if (!_asked || e?.theme != _embed?.theme || e?.lang != _embed?.lang) {
          setState(() {
            _asked = true;
            _embed = e;
          });
        }
      }),
    );
  }

  bool get _phone {
    final p = AppScope.read(context).platform;
    return p == DevicePlatform.android || p == DevicePlatform.ios;
  }

  /// Every page alive learns the app's tabs and whether it is the one in view.
  void _tellTabs() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final tabs = _m.wireTabs();
      final shown = widget.visible && _m.open && _resumed;
      for (final e in _views.entries) {
        unawaited(
          e.value.currentState?.tabs(visible: shown && e.key == _m.active, tabs: tabs) ??
              Future<void>.value(),
        );
      }
    });
  }

  Future<void> _outside(CanvasTab t) async {
    final l = AppLocalizations.of(context);
    final app = AppScope.read(context);
    try {
      final c = app.client ?? (throw StateError('Not connected'));
      final signed = _m.info[t.id]?.bar?.link;
      final link =
          signed ??
          (t.isPort
              ? await c.portLink(t.agentId!, t.port!, path: t.path)
              : (await c.canvasLink(t.scope!, t.path!)).url);
      await openExternal(c.base.resolve(link));
    } on Object catch (e) {
      if (mounted) {
        ScaffoldMessenger.maybeOf(context)
            ?.showSnackBar(SnackBar(content: Text(l.errGeneric('$e'))));
      }
    }
  }

  void _download(CanvasTab t) {
    final info = _m.info[t.id];
    unawaited(
      saveChatFile(
        context,
        scope: t.scope!,
        path: t.path!,
        name: t.fileName,
        size: info?.size ?? 0,
      ),
    );
  }

  void _key(EmbedKey k) {
    final id = _m.active;
    if (id != null) unawaited(_views[id]?.currentState?.key(k) ?? Future<void>.value());
  }

  EmbedParams _params(EmbedContext e, CanvasTab t, String nonce) => t.isPort
      ? EmbedParams(
          token: e.token,
          embed: EmbedKind.port,
          bridge: nonce,
          theme: e.theme,
          lang: e.lang,
          agent: t.agentId,
          port: t.port,
          path: t.path,
          session: widget.sessionId,
        )
      : EmbedParams(
          token: e.token,
          embed: EmbedKind.canvas,
          bridge: nonce,
          theme: e.theme,
          lang: e.lang,
          scope: t.scope,
          path: t.path,
          line: t.line,
          page: t.page,
          session: widget.sessionId,
        );

  Widget? _fallbackOf(CanvasTab t) => t.isPort
      ? null
      : CanvasNativeBody(
          key: ValueKey('canvas-native-${t.id}'),
          scope: t.scope!,
          path: t.path!,
          title: t.title,
          sessionId: widget.sessionId,
        );

  Widget _content(CanvasTab t) {
    final e = _embed;
    if (e == null) {
      if (!_asked) return const SizedBox.expand();
      // No page inside the app here: the app's own viewers.
      return _fallbackOf(t) ??
          Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Text(
                AppLocalizations.of(context).embedFallbackNote,
                textAlign: TextAlign.center,
                style: TextStyle(color: RgColors.of(context).dim),
              ),
            ),
          );
    }
    final nonce = _nonces.putIfAbsent(t.id, newEmbedNonce);
    final fallback = _fallbackOf(t);
    return EmbedView(
      key: _views.putIfAbsent(t.id, GlobalKey<EmbedViewState>.new),
      url: embedUrl(e.base, _params(e, t, nonce)),
      nonce: nonce,
      leaf: e.leaf,
      // The system's back asks the page in front first (its own panels), never one behind.
      handleBack: widget.whole && t.id == _m.active && !_m.full,
      fallback: fallback == null ? null : (_) => fallback,
      onReady: _tellTabs,
      onClose: widget.onClose,
      // A port's name is the agent's own words for it (the page only knows its number).
      onTitle: (x) => _m.tell(
        t.id,
        (was) => was.copyWith(name: t.isPort ? null : x.name, kind: x.kind, size: x.size),
      ),
      onSaveState: (s, err) => _m.tell(t.id, (was) => was.copyWith(save: s, saveError: err)),
      onBar: (b) => _m.tell(t.id, (was) => was.copyWith(bar: b)),
      onOpen: (title, target) => _m.show(title, target),
      onAskAgent: widget.onAskAgent,
    );
  }

  @override
  Widget build(BuildContext context) {
    final c = RgColors.of(context);
    final m = _m;
    final t = m.current;
    final app = AppScope.read(context);
    final most = canvasAliveMax(phone: _phone, linux: app.platform == DevicePlatform.linux);
    final alive = m.alive(most);
    final meta = _apple(app.platform);
    return CallbackShortcuts(
      bindings: {
        SingleActivator(LogicalKeyboardKey.keyS, control: !meta, meta: meta): () =>
            _key(EmbedKey.save),
        SingleActivator(LogicalKeyboardKey.keyZ, control: !meta, meta: meta): () =>
            _key(EmbedKey.undo),
        SingleActivator(LogicalKeyboardKey.keyZ, control: !meta, meta: meta, shift: true): () =>
            _key(EmbedKey.redo),
        SingleActivator(LogicalKeyboardKey.keyF, control: !meta, meta: meta): () =>
            _key(EmbedKey.find),
        const SingleActivator(LogicalKeyboardKey.escape): () {
          if (m.full) {
            m.setFull(false);
          } else if (m.max) {
            m.setMax(false);
          }
        },
      },
      child: Focus(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // The whole screen keeps one slim line with its way out: nothing native is drawn over
            // a web view everywhere (WebKitGTK's is a window above Flutter).
            if (m.full)
              Container(
                height: 30,
                color: c.panel,
                alignment: Alignment.centerRight,
                child: IconButton(
                  key: const Key('canvas-full-exit'),
                  tooltip: AppLocalizations.of(context).cvCanvasFullscreenExit,
                  visualDensity: VisualDensity.compact,
                  padding: EdgeInsets.zero,
                  onPressed: () => m.setFull(false),
                  icon: RgIcon(RgIcons.fullscreenExit, size: 15, color: c.dim),
                ),
              ),
            if (!m.full) ?widget.top,
            if (!m.full) _strip(context),
            if (!m.full && t != null)
              _CanvasBar(
                tab: t,
                info: m.info[t.id],
                phone: _phone,
                onAction: (id) =>
                    unawaited(_views[t.id]?.currentState?.action(id) ?? Future<void>.value()),
                onReload: () =>
                    unawaited(_views[t.id]?.currentState?.reload() ?? Future<void>.value()),
                onDownload: t.isPort ? null : () => _download(t),
                onFull: () => m.setFull(true),
                onOutside: _embed == null && t.isPort ? null : () => _outside(t),
              ),
            Expanded(
              child: Stack(
                fit: StackFit.expand,
                children: [
                  for (final tab in m.tabs)
                    if (alive.contains(tab.id))
                      Offstage(
                        key: ValueKey('canvas-content-${tab.id}'),
                        offstage: tab.id != m.active,
                        child: TickerMode(enabled: tab.id == m.active, child: _content(tab)),
                      ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// The strip (the page's `side-bar`): «Chat» (or back), the tabs, «Maximize».
  Widget _strip(BuildContext context) {
    final c = RgColors.of(context);
    final l = AppLocalizations.of(context);
    final m = _m;
    _tabKeys.removeWhere((id, _) => !m.tabs.any((t) => t.id == id));
    _revealTab();
    return Container(
      key: const Key('canvas-strip'),
      height: 42,
      decoration: BoxDecoration(
        color: c.panel2,
        border: Border(bottom: BorderSide(color: c.line)),
      ),
      child: Row(
        children: [
          const SizedBox(width: 4),
          if (widget.whole)
            IconButton(
              key: const Key('canvas-back'),
              tooltip: l.back,
              onPressed: widget.onClose,
              icon: RgIcon(RgIcons.arrowLeft, size: 18, color: c.text),
            )
          else
            TextButton.icon(
              key: const Key('canvas-panel-hide'),
              onPressed: () => m.max ? m.setMax(false) : widget.onClose?.call(),
              style: TextButton.styleFrom(
                foregroundColor: c.text,
                padding: const EdgeInsets.symmetric(horizontal: 10),
                minimumSize: const Size(0, 32),
              ),
              icon: RgIcon(RgIcons.chat, size: 15, color: c.dim),
              label: Text(
                m.max ? l.cvSideBackToChat : l.cvVwToChat,
                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
              ),
            ),
          Expanded(
            child: Semantics(
              label: l.cvSideTabsLabel,
              child: ListView(
                key: const Key('canvas-tabs'),
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 5),
                children: [
                  for (final tab in m.tabs)
                    KeyedSubtree(
                      key: _tabKeys.putIfAbsent(tab.id, GlobalKey.new),
                      child: _Tab(
                        key: Key('canvas-tab-${tab.id}'),
                        tab: tab,
                        on: tab.id == m.active,
                        onTap: () => m.select(tab.id),
                        onClose: () => m.close(tab.id),
                      ),
                    ),
                ],
              ),
            ),
          ),
          if (!widget.whole && !m.max)
            IconButton(
              key: const Key('canvas-max'),
              tooltip: l.cvSideMaximize,
              onPressed: () => m.setMax(true),
              icon: RgIcon(RgIcons.maximize, size: 15, color: c.dim),
            ),
          const SizedBox(width: 2),
        ],
      ),
    );
  }
}

/// Command instead of Control: Apple's systems.
bool _apple(DevicePlatform p) => p == DevicePlatform.macos || p == DevicePlatform.ios;

/// The tab's bar (the page's `canvas-head`).
class _CanvasBar extends StatelessWidget {
  const _CanvasBar({
    required this.tab,
    required this.info,
    required this.phone,
    required this.onAction,
    required this.onReload,
    required this.onFull,
    this.onDownload,
    this.onOutside,
  });

  final CanvasTab tab;
  final CanvasTabInfo? info;
  final bool phone;
  final void Function(String id) onAction;
  final VoidCallback onReload;
  final VoidCallback onFull;
  final VoidCallback? onDownload;
  final VoidCallback? onOutside;

  @override
  Widget build(BuildContext context) {
    final c = RgColors.of(context);
    final l = AppLocalizations.of(context);
    final i = info;
    final bar = i?.bar;
    final agent = tab.isPort
        ? AppScope.read(context).agents.where((a) => a.id == tab.agentId).firstOrNull?.name
        : null;
    final site = tab.isPort || i?.kind == null && bar != null && !bar.download;
    final save = switch (i?.save) {
      'saving' => l.embedSaving,
      'saved' => l.embedSavedState,
      'error' => l.errGeneric(i?.saveError ?? ''),
      _ => null,
    };
    final meta = [
      // A port: whose computer it is and its number (the agent's words are the title).
      if (tab.isPort) ?agent,
      if (tab.isPort && tab.title.isNotEmpty) l.cvEmbedPort('${tab.port}'),
      if (i?.kind != null && !site) viewerKindWord(l, i!.kind!),
      if (i?.size != null && !site) _bytes(i!.size!),
      ?save,
    ].join(' · ');
    final name = tab.isPort
        ? (tab.title.isEmpty ? l.cvEmbedPort('${tab.port}') : tab.title)
        : (i?.name ?? (tab.title.isEmpty ? tab.fileName : tab.title));
    // The keyboard map is one of the bar's tools (a computer's: a phone has no keys to map).
    final all = bar?.actions ?? const <EmbedAction>[];
    final keys = all.where((a) => a.id == 'keys').firstOrNull;
    final actions = [for (final a in all) if (a.id != 'keys') a];
    final note = bar?.note;
    final download = onDownload != null && (bar?.download ?? true);
    Widget icon(Key key, RgIcons ic, String tip, VoidCallback? on) => IconButton(
      key: key,
      tooltip: tip,
      visualDensity: VisualDensity.compact,
      onPressed: on,
      icon: RgIcon(ic, size: 16, color: c.dim),
    );
    final buttons = <Widget>[
      if (keys != null && !phone)
        icon(const Key('canvas-keys'), RgIcons.keyboard, keys.label, () => onAction(keys.id)),
      icon(const Key('canvas-panel-reload'), RgIcons.refresh, l.cvCanvasReload, onReload),
      if (download)
        icon(const Key('canvas-download'), RgIcons.download, l.cvVwDownload, onDownload),
      icon(const Key('canvas-full'), RgIcons.fullscreen, l.cvCanvasFullscreen, onFull),
      if (onOutside != null)
        icon(const Key('canvas-panel-outside'), RgIcons.external, l.embedOpenInBrowser, onOutside),
    ];
    final extras = <Widget>[
      if (note != null)
        Container(
          key: const Key('canvas-agent-note'),
          margin: const EdgeInsets.only(right: 6),
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          decoration: BoxDecoration(color: c.accentSoft, borderRadius: BorderRadius.circular(999)),
          child: Text(
            note,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(color: c.accent, fontSize: 12, fontWeight: FontWeight.w600),
          ),
        ),
      for (final a in actions) _ActionButton(action: a, onTap: () => onAction(a.id)),
    ];
    final title = Row(
      children: [
        Padding(
          padding: const EdgeInsets.only(right: 8),
          child: tab.isPort
              ? RgIcon(RgIcons.globe, size: 16, color: c.dim)
              : FileIcon(name: tab.path ?? '', size: 16),
        ),
        Flexible(
          child: Text(
            name,
            key: const Key('canvas-title'),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(color: c.text, fontWeight: FontWeight.w700, fontSize: 13.5),
          ),
        ),
        if (meta.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(left: 8),
            child: Text(
              meta,
              key: const Key('canvas-meta'),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(color: c.dim, fontSize: 12),
            ),
          ),
      ],
    );
    return LayoutBuilder(
      builder: (context, box) {
        // Narrow: the tab's own buttons on a second line that scrolls sideways.
        final narrow = box.maxWidth < 640;
        return Container(
          key: const Key('canvas-bar'),
          decoration: BoxDecoration(
            color: c.panel,
            border: Border(bottom: BorderSide(color: c.line)),
          ),
          padding: const EdgeInsets.fromLTRB(12, 2, 4, 2),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SizedBox(
                height: 40,
                child: Row(
                  children: [
                    Expanded(child: title),
                    if (!narrow && extras.isNotEmpty)
                      Flexible(
                        flex: 2,
                        child: SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          reverse: true,
                          child: Row(mainAxisSize: MainAxisSize.min, children: extras),
                        ),
                      ),
                    ...buttons,
                  ],
                ),
              ),
              if (narrow && extras.isNotEmpty)
                SizedBox(
                  height: 38,
                  child: ListView(
                    key: const Key('canvas-bar-more'),
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.only(bottom: 4),
                    children: extras,
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}

/// One of the page's buttons, drawn the app's way.
class _ActionButton extends StatelessWidget {
  const _ActionButton({required this.action, required this.onTap});

  final EmbedAction action;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = RgColors.of(context);
    final a = action;
    final on = a.on;
    final primary = a.primary;
    final alert = a.icon == 'alert';
    final fg = primary
        ? Colors.white
        : alert
        ? c.err
        : on
        ? c.accent
        : c.text;
    final child = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (a.icon != null) ...[
          RgIcon(_actionIcon(a.icon), size: 13, color: fg),
          const SizedBox(width: 6),
        ],
        Text(
          a.label,
          style: TextStyle(color: fg, fontSize: 12.5, fontWeight: FontWeight.w600),
        ),
      ],
    );
    final button = Padding(
      padding: const EdgeInsets.only(right: 6),
      child: Material(
        color: primary
            ? c.accent
            : on
            ? c.accentSoft
            : Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: BorderSide(color: primary ? c.accent : (on ? c.accent : c.line)),
        ),
        child: InkWell(
          key: Key('canvas-action-${a.id}'),
          borderRadius: BorderRadius.circular(8),
          onTap: a.disabled || alert ? null : onTap,
          child: Opacity(
            opacity: a.disabled ? .55 : 1,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              child: child,
            ),
          ),
        ),
      ),
    );
    final hint = a.hint;
    return Center(
      child: hint == null || hint.isEmpty ? button : Tooltip(message: hint, child: button),
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
                if (tab.isPort)
                  RgIcon(RgIcons.globe, size: 13, color: c.dim)
                else
                  FileIcon(name: tab.path ?? '', size: 14),
                const SizedBox(width: 6),
                ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 180),
                  child: Text(
                    tab.title.isEmpty
                        ? (tab.isPort ? l.cvEmbedPort('${tab.port}') : tab.fileName)
                        : tab.title,
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

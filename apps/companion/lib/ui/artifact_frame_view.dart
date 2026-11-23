// Widgets and artifacts in the app (3.8.7), as the page shows them (`ArtifactFrame.tsx`): one frame
// for both, a web view that loads the page of our preview relay (`api/preview_relay.dart`), which
// holds the server's `/preview/<token>/…` in the sandbox. The frame's height follows its content
// (a widget, at most 70% of the screen), the app's theme and language reach it, its errors go to
// the server for the agent, and «send to chat» goes at once only right after the person's click
// in it; otherwise it waits in a strip under it for «Send» or «Leave it».
//
// Android, iOS and macOS: webview_flutter (WebView, WKWebView). Windows: webview_flutter_windows
// (WebView2, drawn into Flutter). Linux (G42.0): WebKitGTK (webview_all_linux), a native view over
// Flutter clipped to its place. Without a safe way to the server (plain http over the network): a
// card with the widget's words and «Open in the page» (the browser, on the same preview link).
import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:webview_all_linux/webview_all_linux.dart' as gtk;
import 'package:webview_flutter_windows/webview_flutter_windows.dart' as win;
import 'package:webview_platform_interface/webview_platform_interface.dart' as gtkp;

import '../api/artifact_frame.dart';
import '../api/client.dart';
import '../api/conversation.dart';
import '../api/preview_relay.dart';
import '../api/transport.dart';
import '../api/types.dart';
import '../api/widgets.dart';
import '../app_state.dart';
import '../l10n/app_localizations.dart';
import '../theme/colors.dart';
import 'dialogs.dart';
import 'found_widgets.dart' show chatWidgetMax;
import 'icons.dart';

/// Where frames can run.
enum FrameSupport {
  /// webview_flutter: Android, iOS, macOS.
  webView,

  /// WebView2: Windows.
  windows,

  /// WebKitGTK: Linux (G42.0).
  linux,

  /// No safe way to the server (plain http over the network).
  none,
}

/// Where frames run on [p] reaching RedGiant over [k] (pure, a table in the tests).
FrameSupport frameSupportFor(DevicePlatform p, TransportKind? k) {
  if (k == null || k == TransportKind.channel) return FrameSupport.none;
  return switch (p) {
    DevicePlatform.android || DevicePlatform.ios || DevicePlatform.macos => FrameSupport.webView,
    DevicePlatform.windows => FrameSupport.windows,
    DevicePlatform.linux => FrameSupport.linux,
    DevicePlatform.other => FrameSupport.none,
  };
}

/// Tests set these: where frames run, the web view, and the relay.
@visibleForTesting
FrameSupport Function(AppController app)? debugFrameSupport;
@visibleForTesting
FrameHost Function(FrameSupport support)? debugFrameHost;
@visibleForTesting
Future<RelayFrame> Function(AppController app, String previewPath, String title)? debugFrameOpener;

FrameSupport frameSupportOf(AppController app) =>
    debugFrameSupport?.call(app) ?? frameSupportFor(app.platform, app.client?.transport.kind);

/// A web view holding one wrapper page: its messages out, scripts in.
abstract class FrameHost {
  /// The wrapper's raw messages (`{n, k, d, f, a}` as JSON).
  Stream<String> get messages;

  Future<void> load(RelayFrame frame);

  /// Runs [script] in the wrapper (never in the frame: it reaches the frame only by message).
  Future<void> run(String script);

  /// The view; [eager]: it takes every gesture (the Canvas), else only taps and sideways drags
  /// (a widget in a scrolling chat).
  Widget view({required bool eager});

  void dispose();
}

FrameHost _hostFor(FrameSupport s) =>
    debugFrameHost?.call(s) ??
    switch (s) {
      FrameSupport.windows => _WindowsHost(),
      FrameSupport.linux => _LinuxHost(),
      _ => _FlutterHost(),
    };

/// Linux: WebKitGTK over the Flutter view, clipped to the frame's place.
class _LinuxHost implements FrameHost {
  final _out = StreamController<String>.broadcast();
  final _c = gtk.LinuxWebViewController(const gtkp.PlatformWebViewControllerCreationParams());

  @override
  Stream<String> get messages => _out.stream;

  @override
  Future<void> load(RelayFrame f) async {
    await _c.setJavaScriptMode(gtkp.JavaScriptMode.unrestricted);
    await _c.addJavaScriptChannel(
      gtkp.JavaScriptChannelParams(name: 'RGHost', onMessageReceived: (m) => _out.add(m.message)),
    );
    await _c.setBackgroundColor(const Color(0x00000000));
    final nav = gtk.LinuxNavigationDelegate(const gtkp.PlatformNavigationDelegateCreationParams());
    await nav.setOnNavigationRequest((r) {
      final u = Uri.tryParse(r.url);
      // `r.isMainFrame` is always true here (WebKitGTK does not say which frame navigates).
      final ok =
          u != null && frameNavigationAllowedAnyFrame(u, wrapper: f.wrapper, preview: f.preview);
      return ok ? gtkp.NavigationDecision.navigate : gtkp.NavigationDecision.prevent;
    });
    await _c.setPlatformNavigationDelegate(nav);
    await _c.loadRequest(gtkp.LoadRequestParams(uri: f.wrapper));
  }

  @override
  Future<void> run(String script) => _c.runJavaScript(script);

  @override
  Widget view({required bool eager}) => Builder(
    builder: (context) =>
        gtk.LinuxWebViewWidget(gtkp.PlatformWebViewWidgetCreationParams(controller: _c))
            .build(context),
  );

  @override
  void dispose() {
    unawaited(_out.close());
    unawaited(_c.dispose());
  }
}

/// Android, iOS, macOS.
class _FlutterHost implements FrameHost {
  final _out = StreamController<String>.broadcast();
  final _web = WebViewController();

  @override
  Stream<String> get messages => _out.stream;

  @override
  Future<void> load(RelayFrame f) async {
    await _web.setJavaScriptMode(JavaScriptMode.unrestricted);
    // The channel reaches every frame on Android: only the wrapper knows the nonce.
    await _web.addJavaScriptChannel('RGHost', onMessageReceived: (m) => _out.add(m.message));
    await _web.setNavigationDelegate(
      NavigationDelegate(
        onNavigationRequest: (r) {
          final u = Uri.tryParse(r.url);
          final ok =
              u != null &&
              frameNavigationAllowed(
                u,
                mainFrame: r.isMainFrame,
                wrapper: f.wrapper,
                preview: f.preview,
              );
          return ok ? NavigationDecision.navigate : NavigationDecision.prevent;
        },
      ),
    );
    try {
      await _web.setBackgroundColor(const Color(0x00000000));
    } on Object {
      // macOS's WKWebView has no background colour to set: it stays the page's.
    }
    await _web.loadRequest(f.wrapper);
  }

  @override
  Future<void> run(String script) => _web.runJavaScript(script);

  @override
  Widget view({required bool eager}) => WebViewWidget(
    controller: _web,
    gestureRecognizers: {
      if (eager) Factory<OneSequenceGestureRecognizer>(EagerGestureRecognizer.new),
      if (!eager) Factory<OneSequenceGestureRecognizer>(HorizontalDragGestureRecognizer.new),
    },
  );

  @override
  void dispose() => unawaited(_out.close());
}

/// Windows: WebView2 drawn into a Flutter texture.
class _WindowsHost implements FrameHost {
  final _out = StreamController<String>.broadcast();
  final _c = win.WebviewController();
  StreamSubscription<dynamic>? _msgs;
  StreamSubscription<String>? _urls;
  bool _gone = false;

  @override
  Stream<String> get messages => _out.stream;

  @override
  Future<void> load(RelayFrame f) async {
    await _c.initialize();
    if (_gone) return;
    await _c.setPopupWindowPolicy(win.WebviewPopupWindowPolicy.deny);
    await _c.setBackgroundColor(Colors.transparent);
    await _c.setZoomControlEnabled(false);
    _msgs = _c.webMessage.listen((m) => _out.add(m is String ? m : jsonEncode(m)));
    // WebView2 has no veto on a navigation here: the frame cannot take the top anyway (its
    // sandbox), and if the top ever leaves the wrapper it is brought back.
    _urls = _c.url.listen((u) {
      final x = Uri.tryParse(u);
      if (x == null || x.scheme == 'about') return;
      if (!frameNavigationAllowed(x, mainFrame: true, wrapper: f.wrapper, preview: f.preview)) {
        unawaited(_c.loadUrl(f.wrapper.toString()));
      }
    });
    await _c.loadUrl(f.wrapper.toString());
  }

  @override
  Future<void> run(String script) async {
    if (_c.value.isInitialized) await _c.executeScript(script);
  }

  @override
  Widget view({required bool eager}) => ValueListenableBuilder<win.WebviewValue>(
    valueListenable: _c,
    builder: (context, v, _) => v.isInitialized
        ? win.Webview(
            _c,
            permissionRequested: (url, kind, user) => win.WebviewPermissionDecision.deny,
          )
        : const SizedBox.shrink(),
  );

  @override
  void dispose() {
    _gone = true;
    unawaited(_msgs?.cancel());
    unawaited(_urls?.cancel());
    unawaited(_out.close());
    unawaited(_c.dispose());
  }
}

String _hex(Color c) => '#${(c.toARGB32() & 0xFFFFFF).toRadixString(16).padLeft(6, '0')}';

/// The page's theme variables, from the app's colours (the same values as `styles.css`).
Map<String, String> frameThemeVars(RgColors c) => {
  'bg': _hex(c.bg),
  'panel': _hex(c.panel),
  'panel-2': _hex(c.panel2),
  'line': _hex(c.line),
  'text': _hex(c.text),
  'dim': _hex(c.dim),
  'accent': _hex(c.accent),
  'accent-2': _hex(c.accent2),
  'accent-soft': _hex(c.accentSoft),
  'ok': _hex(c.ok),
  'warn': _hex(c.warn),
  'warn-text': _hex(c.warnText),
  'err': _hex(c.err),
  'radius': '10px',
  'mono': 'ui-monospace, "JetBrains Mono", "Cascadia Code", Consolas, monospace',
};

const _font = 'system-ui, -apple-system, "Segoe UI", Roboto, sans-serif';

Future<RelayFrame> _openWithRelay(AppController app, String previewPath, String title) async {
  final s = app.server;
  final c = app.client;
  if (s == null || c == null) throw const ApiException(0, 'Not connected');
  final relay = await PreviewRelay.forServer(c.base, caPem: s.caPem);
  return relay.open(previewPath, title: title);
}

/// The frame of an artifact (the Canvas) or a widget (in an answer, [auto] height).
class ArtifactFrame extends StatefulWidget {
  const ArtifactFrame({
    super.key,
    required this.src,
    required this.title,
    required this.ref,
    this.sessionId,
    this.auto = false,
    this.onErrors,
  });

  /// The server's `/preview/<token>/…` path.
  final String src;
  final String title;

  /// What its errors belong to (`ArtifactRef`).
  final Map<String, Object?> ref;

  /// The conversation it sends to.
  final String? sessionId;
  final bool auto;
  final void Function(List<ArtifactErrorInfo> errors)? onErrors;

  @override
  State<ArtifactFrame> createState() => _ArtifactFrameState();
}

class _ArtifactFrameState extends State<ArtifactFrame> {
  FrameHost? _host;
  FrameSession? _session;
  RelayFrame? _frame;
  StreamSubscription<String>? _msgs;
  StreamSubscription<Map<String, dynamic>>? _live;
  double _height = 48;
  String? _asking;
  String? _failed;
  bool _linkOpen = false;
  Map<String, Object?> _theme = const {};
  String _themeKey = '';

  @override
  void initState() {
    super.initState();
    unawaited(_start());
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final c = RgColors.of(context);
    final dark = Theme.of(context).brightness == Brightness.dark;
    final locale = Localizations.localeOf(context).languageCode;
    _theme = hostContext(frameThemeVars(c), dark: dark, locale: locale, font: _font);
    final key = jsonEncode(_theme);
    if (key != _themeKey) {
      _themeKey = key;
      _session?.sendTheme();
    }
  }

  Future<void> _start() async {
    final app = AppScope.read(context);
    try {
      final frame = await (debugFrameOpener ?? _openWithRelay)(app, widget.src, widget.title);
      if (!mounted) {
        frame.release();
        return;
      }
      final host = _hostFor(frameSupportOf(app));
      final session = FrameSession(
        nonce: frame.nonce,
        ref: widget.ref,
        sessionId: widget.sessionId,
        auto: widget.auto,
        postToFrame: (m) => unawaited(host.run(postToFrameScript(m)).catchError((Object _) {})),
        hostContext: () => _theme,
        onHeight: (h) {
          if (mounted && h != _height) setState(() => _height = h);
        },
        onSend: (to, text) => _sendAsPerson(app, to, text),
        onAsk: (t) {
          if (mounted) setState(() => _asking = t);
        },
        onErrors: (e) => widget.onErrors?.call(e),
        reportErrors: (batch, {required fresh}) => unawaited(
          app.client
              ?.artifactErrors(
                ref: widget.ref,
                sessionId: widget.sessionId,
                errors: [for (final e in batch) e.toJson()],
                fresh: fresh,
              )
              .catchError((Object _) {}),
        ),
        onLink: (u) async {
          if (_linkOpen || !mounted) return;
          _linkOpen = true;
          try {
            await askOpenPreviewLink(context, u);
          } finally {
            _linkOpen = false;
          }
        },
        sendBridge: (m) => app.socket?.send(m) ?? false,
      );
      _msgs = host.messages.listen(session.handle);
      _live = app.socket?.messages.listen((m) {
        if (m['type'] == 'artifact.bridge.result') session.bridgeResult(m);
      });
      setState(() {
        _frame = frame;
        _host = host;
        _session = session;
      });
      await host.load(frame);
    } on Object catch (e) {
      if (mounted) setState(() => _failed = '$e');
    }
  }

  void _sendAsPerson(AppController app, String sessionId, String text) {
    final id =
        'a${DateTime.now().millisecondsSinceEpoch}${Random().nextInt(1 << 20).toRadixString(36)}';
    final sent =
        app.socket?.send({
          'type': 'session.send',
          'sessionId': sessionId,
          'text': text,
          'via': 'artifact',
          'clientId': id,
        }) ??
        false;
    if (!sent) unawaited(app.send(sessionId, text));
  }

  @override
  void dispose() {
    _session?.close();
    unawaited(_msgs?.cancel());
    unawaited(_live?.cancel());
    _host?.dispose();
    _frame?.release();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = RgColors.of(context);
    final l = AppLocalizations.of(context);
    final host = _host;
    Widget frame;
    if (_failed != null) {
      frame = Padding(
        padding: const EdgeInsets.all(10),
        child: Text(_failed!, style: TextStyle(color: c.err, fontSize: 13)),
      );
    } else if (host == null) {
      frame = SizedBox(
        height: widget.auto ? _height : null,
        child: Center(
          child: Text(l.widgetLoading, style: TextStyle(color: c.dim, fontSize: 13)),
        ),
      );
    } else {
      final view = KeyedSubtree(
        key: const Key('artifact-frame-view'),
        child: host.view(eager: !widget.auto),
      );
      frame = widget.auto
          ? SizedBox(height: min(_height, MediaQuery.sizeOf(context).height * 0.7), child: view)
          : view;
    }
    final to = widget.sessionId;
    final asking = _asking;
    return Column(
      mainAxisSize: widget.auto ? MainAxisSize.min : MainAxisSize.max,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (widget.auto) frame else Expanded(child: frame),
        if (asking != null)
          Container(
            key: const Key('artifact-ask'),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            decoration: BoxDecoration(
              color: c.panel2,
              border: Border(top: BorderSide(color: c.line)),
            ),
            child: Wrap(
              spacing: 8,
              runSpacing: 6,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                RgIcon(RgIcons.send, size: 13, color: c.dim),
                Text(
                  to != null ? l.widgetAsks : l.widgetNoChat,
                  style: TextStyle(color: c.dim, fontSize: 12.5),
                ),
                Text(
                  '«${asking.length > 300 ? '${asking.substring(0, 300)}…' : asking}»',
                  style: TextStyle(color: c.text, fontSize: 13),
                ),
                FilledButton.icon(
                  key: const Key('artifact-ask-send'),
                  onPressed: to == null
                      ? null
                      : () {
                          _sendAsPerson(AppScope.read(context), to, asking);
                          setState(() => _asking = null);
                        },
                  icon: const RgIcon(RgIcons.check, size: 12, color: Colors.white),
                  label: Text(l.widgetSend),
                ),
                OutlinedButton.icon(
                  key: const Key('artifact-ask-dismiss'),
                  onPressed: () => setState(() => _asking = null),
                  icon: RgIcon(RgIcons.x, size: 12, color: c.text),
                  label: Text(l.widgetDismiss),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

/// Opens the preview [path] of the server in use in the browser («Open in the page»).
Future<void> openPreviewInPage(AppController app, String path) async {
  final c = app.client;
  if (c == null) return;
  await launchUrl(c.base.resolve(path), mode: LaunchMode.externalApplication);
}

/// A widget in the chat (the page's `WidgetCard`): the frame, its name, «Open in the Canvas» and
/// «Keep it». Both make it `artefatti/<name>.html` the first time; the Canvas opens it.
class WidgetCard extends StatefulWidget {
  const WidgetCard({super.key, required this.item, this.openCanvas});

  final WidgetItem item;

  /// Opens a file in the app's Canvas (`openCanvas` of `canvas_screen.dart`).
  final void Function(String scope, String path, String title)? openCanvas;

  @override
  State<WidgetCard> createState() => _WidgetCardState();
}

class _WidgetCardState extends State<WidgetCard> with AutomaticKeepAliveClientMixin {
  Future<String>? _link;
  FrameSupport _support = FrameSupport.none;
  List<ArtifactErrorInfo> _errors = const [];
  ({String scope, String path})? _kept;
  bool _busy = false;
  String? _error;

  WidgetItem get it => widget.item;

  /// Like the page's frame, it stays loaded while the conversation scrolls it out of sight: what it
  /// counted, what it waits to send and its state are not lost to a reload.
  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    final app = AppScope.read(context);
    _support = frameSupportOf(app);
    final c = app.client;
    if (_support != FrameSupport.none && c != null) {
      _link = c.widgetLink(it.sessionId, it.seq, it.index);
    }
  }

  Future<({String scope, String path})?> _keep() async {
    if (_kept != null) return _kept;
    final c = AppScope.read(context).client;
    if (c == null) return null;
    setState(() => _busy = true);
    try {
      final k = await c.keepWidget(it.sessionId, it.seq, it.index);
      if (mounted) setState(() => _kept = k);
      return k;
    } on Object catch (e) {
      if (mounted) setState(() => _error = '$e');
      return null;
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _open() async {
    final k = await _keep();
    if (k == null || !mounted) return;
    widget.openCanvas?.call(k.scope, k.path, k.path.split('/').last);
  }

  Future<void> _openInPage() async {
    final app = AppScope.read(context);
    try {
      final link = await (_link ?? app.client!.widgetLink(it.sessionId, it.seq, it.index));
      await openPreviewInPage(app, link);
    } on Object catch (e) {
      if (mounted) setState(() => _error = '$e');
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final c = RgColors.of(context);
    final l = AppLocalizations.of(context);
    final name = it.title.isEmpty ? l.widgetTitle : it.title;
    final kept = _kept;
    final small = TextStyle(color: c.dim, fontSize: 12.5);
    // On a narrow screen the actions are their icons only (the words in their tooltip).
    final narrow = MediaQuery.sizeOf(context).width < 520;
    Widget act(Key key, RgIcons icon, String label, VoidCallback? onTap, {String? tip}) => Tooltip(
      message: tip ?? label,
      child: narrow
          ? IconButton(
              key: key,
              visualDensity: VisualDensity.compact,
              constraints: const BoxConstraints(minWidth: 34, minHeight: 34),
              onPressed: onTap,
              icon: RgIcon(icon, size: 15, color: c.dim),
            )
          : TextButton.icon(
              key: key,
              style: TextButton.styleFrom(
                foregroundColor: c.dim,
                padding: const EdgeInsets.symmetric(horizontal: 6),
                minimumSize: const Size(0, 30),
                textStyle: const TextStyle(fontSize: 12.5),
              ),
              onPressed: onTap,
              icon: RgIcon(icon, size: 13, color: c.dim),
              label: Text(label),
            ),
    );
    final Widget body;
    if (_error != null) {
      body = Padding(
        padding: const EdgeInsets.all(10),
        child: Text(_error!, style: TextStyle(color: c.err, fontSize: 13)),
      );
    } else if (_support == FrameSupport.none) {
      final words = widgetPreviewText(it.html);
      body = Padding(
        key: const Key('widget-fallback'),
        padding: const EdgeInsets.fromLTRB(12, 4, 12, 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (words.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Text(words, style: TextStyle(color: c.text, fontSize: 13.5)),
              ),
            Text(l.widgetNoFrameHere, style: small),
            const SizedBox(height: 6),
            OutlinedButton.icon(
              key: const Key('widget-open-page'),
              onPressed: _openInPage,
              icon: RgIcon(RgIcons.external, size: 14, color: c.text),
              label: Text(l.widgetOpenInPage),
            ),
          ],
        ),
      );
    } else {
      body = FutureBuilder<String>(
        future: _link,
        builder: (context, s) {
          if (s.hasError) {
            return Padding(
              padding: const EdgeInsets.all(10),
              child: Text('${s.error}', style: TextStyle(color: c.err, fontSize: 13)),
            );
          }
          if (!s.hasData) {
            return SizedBox(
              height: 48,
              child: Center(child: Text(l.widgetLoading, style: small)),
            );
          }
          return ArtifactFrame(
            src: s.data!,
            title: name,
            ref: {'kind': 'widget', 'sessionId': it.sessionId, 'seq': it.seq, 'index': it.index},
            sessionId: it.sessionId,
            auto: true,
            onErrors: (e) {
              if (mounted) setState(() => _errors = e);
            },
          );
        },
      );
    }
    // A ClipRRect, never the decoration's clip (Container's clipBehavior): that one is a ClipPath,
    // which WebKitGTK's native view on Linux cannot follow, so the plugin hid the widget (3.8.11).
    return ConstrainedBox(
      key: Key('widget-${it.seq}.${it.index}'),
      constraints: const BoxConstraints(maxWidth: chatWidgetMax),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(10),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: c.panel,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: c.line),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(14, 8, 8, 2),
                child: Row(
                  children: [
                    RgIcon(RgIcons.canvas, size: 12, color: c.dim),
                    const SizedBox(width: 6),
                    Flexible(
                      child: Text(name, overflow: TextOverflow.ellipsis, style: small),
                    ),
                    if (_errors.isNotEmpty) ...[
                      const SizedBox(width: 8),
                      Tooltip(
                        message: _errors.map((e) => e.message).join('\n'),
                        child: Row(
                          key: const Key('widget-errors'),
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            RgIcon(RgIcons.alert, size: 12, color: c.warnText),
                            const SizedBox(width: 3),
                            Text(
                              _errors.length == 1 ? l.artError1 : l.artErrors(_errors.length),
                              style: TextStyle(color: c.warnText, fontSize: 12),
                            ),
                          ],
                        ),
                      ),
                    ],
                    const Spacer(),
                    act(
                      const Key('widget-open-canvas'),
                      RgIcons.maximize,
                      l.widgetOpenCanvas,
                      _busy || widget.openCanvas == null ? null : _open,
                    ),
                    act(
                      const Key('widget-keep'),
                      kept != null ? RgIcons.check : RgIcons.pin,
                      kept != null ? l.widgetKeptShort : l.widgetKeep,
                      _busy || kept != null || widget.openCanvas == null ? null : _open,
                      tip: kept != null ? l.widgetKept(kept.path) : l.widgetKeepHint,
                    ),
                  ],
                ),
              ),
              Padding(padding: const EdgeInsets.fromLTRB(8, 0, 8, 10), child: body),
              if (kept != null)
                Padding(
                  padding: const EdgeInsets.fromLTRB(10, 0, 10, 6),
                  child: Row(
                    children: [
                      RgIcon(RgIcons.check, size: 11, color: c.ok),
                      const SizedBox(width: 4),
                      Flexible(child: Text(l.widgetKept(kept.path), style: small)),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/// The Canvas without a safe way to the server: «Open in the page» above the source.
class ArtifactInPage extends StatelessWidget {
  const ArtifactInPage({super.key, required this.previewPath, required this.source});

  final String previewPath;
  final String source;

  @override
  Widget build(BuildContext context) {
    final c = RgColors.of(context);
    final l = AppLocalizations.of(context);
    return ListView(
      padding: const EdgeInsets.all(14),
      children: [
        Text(l.widgetNoFrameHere, style: TextStyle(color: c.dim, fontSize: 13)),
        const SizedBox(height: 8),
        Align(
          alignment: Alignment.centerLeft,
          child: FilledButton.icon(
            key: const Key('artifact-open-page'),
            onPressed: () => unawaited(openPreviewInPage(AppScope.read(context), previewPath)),
            icon: const RgIcon(RgIcons.external, size: 14, color: Colors.white),
            label: Text(l.widgetOpenInPage),
          ),
        ),
        const SizedBox(height: 12),
        SelectableText(
          source.length > 200000 ? '${source.substring(0, 200000)}…' : source,
          key: const Key('canvas-text'),
          style: TextStyle(fontFamily: 'monospace', fontSize: 12.5, color: c.text),
        ),
      ],
    );
  }
}

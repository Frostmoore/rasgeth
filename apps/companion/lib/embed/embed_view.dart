// The page inside the app (G42.0), one widget for every use: an embed (`#embed=…`, the Canvas's
// editors and viewers, an agent's port, a board, the test page) or the whole page (`All settings`,
// `#open=settings`). Over the web view: the app's background and its own indicator until the page
// says it is drawn (no white flash), a native error with «Try again», the system's back asked to
// the page first, the app's theme and language followed, and the bridge's messages handled the
// app's way (the clipboard, «Save as…», files, sharing, links outside, «ask the agent»).
import 'dart:async';
import 'dart:convert';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../app_state.dart';
import '../l10n/app_localizations.dart';
import '../screens/first_start_screen.dart' show openExternal;
import '../theme/colors.dart';
import '../ui/dialogs.dart';
import '../ui/icons.dart';
import 'bridge.dart';
import 'web_host.dart';

/// What the app knows of the page shown (its `title` message).
class EmbedTitle {
  const EmbedTitle(this.name, {this.kind, this.size});
  final String name;
  final String? kind;
  final int? size;
}

class EmbedView extends StatefulWidget {
  const EmbedView({
    super.key,
    required this.url,
    this.nonce,
    this.leaf,
    this.onTitle,
    this.onSaveState,
    this.onAskAgent,
    this.onClose,
    this.onReady,
    this.onBar,
    this.onOpen,
    this.fallback,
    this.readyWithin = const Duration(seconds: 25),
    this.eager = true,
    this.handleBack = true,
  });

  /// The page's address (`embedUrl`, or the whole page with its fragment).
  final Uri url;

  /// The bridge's nonce (the fragment's `bridge`); null: the whole page, no bridge.
  final String? nonce;

  /// The certificate checked against the local CA.
  final Uint8List? leaf;
  final void Function(EmbedTitle title)? onTitle;
  final void Function(String state, String? error)? onSaveState;

  /// «Ask the agent»: to the app's own conversation (the Canvas's, G42.6).
  final void Function(String text, Map<String, Object?> ref)? onAskAgent;
  final VoidCallback? onClose;

  /// The page said it is drawn.
  final VoidCallback? onReady;

  /// The Canvas's bar as the page says it (G42.6).
  final void Function(EmbedBar bar)? onBar;

  /// Something to open in another tab of the app's Canvas (G42.6).
  final void Function(String title, Map<String, dynamic> target)? onOpen;

  /// What shows when the page cannot be loaded or does not answer in [readyWithin] (G42.6: the
  /// Canvas's native viewers), under a line that says so and «Try again». Null: the error alone.
  final WidgetBuilder? fallback;
  final Duration readyWithin;
  final bool eager;

  /// Whether the system's back is asked to this page first. Off where a screen holds several
  /// pages side by side (a board's variants, G42.2): the screen's own back goes back.
  final bool handleBack;

  @override
  State<EmbedView> createState() => EmbedViewState();
}

class EmbedViewState extends State<EmbedView> {
  late final WebHost _host;
  EmbedBridge? _bridge;
  StreamSubscription<String>? _msgs;
  bool _ready = false;
  int _progress = 0;
  String? _error;
  String _look = '';
  Completer<bool>? _back;

  /// Whether the page said it is drawn (tests).
  bool get ready => _ready;

  @override
  void initState() {
    super.initState();
    final app = AppScope.read(context);
    _host = webHostFor(webEngineFor(app.platform));
    final nonce = widget.nonce;
    if (nonce != null) {
      _bridge = EmbedBridge(
        nonce: nonce,
        run: _host.run,
        handlers: EmbedHandlers(
          ready: () => _setReady(),
          title: (n, k, s) => widget.onTitle?.call(EmbedTitle(n, kind: k, size: s)),
          saveState: (s, e) => widget.onSaveState?.call(s, e),
          saveAs: _saveAs,
          openFile: _openFile,
          copy: _copy,
          share: _share,
          askAgent: (t, r) => widget.onAskAgent?.call(t, r),
          external: (u) => unawaited(openExternal(u)),
          previewLink: (u) {
            if (mounted) unawaited(askOpenPreviewLink(context, u));
          },
          close: () => widget.onClose?.call(),
          bar: (b) => widget.onBar?.call(b),
          open: (t, target) => widget.onOpen?.call(t, target),
          back: (handled) {
            final b = _back;
            if (b != null && !b.isCompleted) b.complete(handled);
          },
        ),
      );
      _msgs = _host.messages.listen(_bridge!.handle);
    }
  }

  bool _started = false;
  Timer? _slow;

  /// Whether the native fallback shows (the page failed or is silent).
  bool get fellBack => _error != null && widget.fallback != null;

  void _watch() {
    _slow?.cancel();
    if (widget.fallback == null) return;
    _slow = Timer(widget.readyWithin, () {
      if (mounted && !_ready && _error == null) setState(() => _error = 'timeout');
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final c = RgColors.of(context);
    if (!_started) {
      _started = true;
      _watch();
      unawaited(_load(c.bg));
    }
    final dark = Theme.of(context).brightness == Brightness.dark;
    final lang = Localizations.localeOf(context).languageCode == 'it' ? 'it' : 'en';
    final look = '$dark/$lang';
    if (look != _look) {
      final first = _look.isEmpty;
      _look = look;
      final b = _bridge;
      if (!first && b != null && _ready) {
        unawaited(b.theme(dark: dark).catchError((Object _) {}));
        unawaited(b.lang(lang).catchError((Object _) {}));
      }
    }
  }

  Future<void> _load(Color background) async {
    try {
      await _host.load(
        widget.url,
        WebRules(
          origin: widget.url,
          background: background,
          leaf: widget.leaf,
          onOutside: (u) => unawaited(openExternal(u)),
          onProgress: (p) {
            if (!mounted) return;
            setState(() => _progress = p);
            // The whole page has no bridge: loaded is drawn.
            if (p >= 100 && _bridge == null) _setReady();
          },
          onError: (e) {
            if (mounted) setState(() => _error = e);
          },
        ),
      );
    } on Object catch (e) {
      if (mounted) setState(() => _error = '$e');
    }
  }

  void _setReady() {
    _slow?.cancel();
    if (mounted && !_ready) {
      setState(() {
        _ready = true;
        if (_error == 'timeout') _error = null;
      });
      widget.onReady?.call();
    }
  }

  /// Loads the page again (the bar's «Reload»): the indicator until it says it is drawn.
  Future<void> reload() async {
    if (!mounted) return;
    setState(() {
      _error = null;
      _ready = false;
    });
    _watch();
    await _host.reload();
  }

  /// One of the bar's actions used (G42.6).
  Future<void> action(String id) async {
    if (_ready) await _bridge?.action(id).catchError((Object _) {});
  }

  /// The app's Canvas tabs, for the page's answer to an agent that looks (G42.6).
  Future<void> tabs({required bool visible, required List<Map<String, Object?>> tabs}) async {
    if (_ready) await _bridge?.tabs(visible: visible, tabs: tabs).catchError((Object _) {});
  }

  /// The system's back: the page's own panels first; true when the page took it.
  Future<bool> pageTookBack() async {
    final b = _bridge;
    if (b == null || !_ready) return false;
    final wait = _back = Completer<bool>();
    try {
      await b.back();
      return await wait.future.timeout(const Duration(milliseconds: 600), onTimeout: () => false);
    } on Object {
      return false;
    } finally {
      _back = null;
    }
  }

  /// A key the web view did not hold (a Flutter shortcut), passed on to the page.
  Future<void> key(EmbedKey k) async => _bridge?.key(k);

  /// Files dropped on the app over the page.
  Future<void> drop(List<({String name, String type, Uint8List bytes})> files) async =>
      _bridge?.files([for (final f in files) embedFile(f.name, f.type, f.bytes)]);

  void _say(String text) {
    if (!mounted) return;
    ScaffoldMessenger.maybeOf(context)?.showSnackBar(SnackBar(content: Text(text)));
  }

  void _copy(String text) {
    unawaited(Clipboard.setData(ClipboardData(text: text)));
    _say(AppLocalizations.of(context).embedCopied);
  }

  // No share sheet in the app yet: what would be shared is copied, and said so.
  void _share({String? title, String? text, String? url}) {
    final what = [?text, ?url].join('\n');
    unawaited(Clipboard.setData(ClipboardData(text: what)));
    _say(AppLocalizations.of(context).embedShareCopied);
  }

  Future<void> _saveAs(String name, {String? url, String? data, String? mime}) async {
    final app = AppScope.read(context);
    final l = AppLocalizations.of(context);
    try {
      final bytes = data != null
          ? base64Decode(data)
          : await (app.client ?? (throw StateError('Not connected'))).serverBytes(url!);
      final saved = await FilePicker.saveFile(fileName: name, bytes: bytes);
      if (saved != null) _say(l.embedSaved(name));
    } on Object catch (e) {
      _say(l.errGeneric('$e'));
    }
  }

  Future<void> _openFile(String id, List<String> accept, bool multiple) async {
    final exts = [
      for (final a in accept)
        if (a.startsWith('.') && a.length > 1) a.substring(1),
    ];
    List<Map<String, Object?>> files = const [];
    try {
      final picked = await FilePicker.pickFiles(
        type: exts.isEmpty ? FileType.any : FileType.custom,
        allowedExtensions: exts.isEmpty ? null : exts,
      );
      final out = <Map<String, Object?>>[];
      for (final f in picked.take(multiple ? embedFilesMax : 1)) {
        final bytes = await f.readAsBytes();
        if (bytes.length <= embedFileMax) out.add(embedFile(f.name, _typeOf(f.name), bytes));
      }
      files = out;
    } on Object {
      files = const [];
    }
    await _bridge?.files(files, id: id);
  }

  static String _typeOf(String name) {
    final ext = name.split('.').last.toLowerCase();
    return const {
          'png': 'image/png',
          'jpg': 'image/jpeg',
          'jpeg': 'image/jpeg',
          'gif': 'image/gif',
          'webp': 'image/webp',
          'svg': 'image/svg+xml',
          'pdf': 'application/pdf',
          'txt': 'text/plain',
          'md': 'text/markdown',
          'csv': 'text/csv',
          'json': 'application/json',
        }[ext] ??
        'application/octet-stream';
  }

  @override
  void dispose() {
    _slow?.cancel();
    unawaited(_msgs?.cancel());
    _host.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = RgColors.of(context);
    final l = AppLocalizations.of(context);
    final error = _error;
    return PopScope(
      canPop: !widget.handleBack || _bridge == null || !_ready,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) return;
        final nav = Navigator.of(context);
        if (!await pageTookBack() && mounted) nav.pop();
      },
      child: ColoredBox(
        color: c.bg,
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Linux draws its web view over Flutter: on an error it leaves, so the words show.
            if (error == null)
              KeyedSubtree(
                key: const Key('embed-web'),
                child: _host.view(eager: widget.eager),
              ),
            if (!_ready && error == null)
              ColoredBox(
                key: const Key('embed-wait'),
                color: c.bg,
                child: Center(
                  child: SizedBox(
                    width: 160,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        RgIcon(RgIcons.canvas, size: 22, color: c.dim),
                        const SizedBox(height: 12),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(2),
                          child: LinearProgressIndicator(
                            value: _progress <= 0 || _progress >= 100 ? null : _progress / 100,
                            minHeight: 3,
                            color: c.accent,
                            backgroundColor: c.panel2,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            if (error != null && widget.fallback != null)
              Column(
                key: const Key('embed-fallback'),
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Container(
                    padding: const EdgeInsets.fromLTRB(12, 6, 6, 6),
                    decoration: BoxDecoration(
                      color: c.panel2,
                      border: Border(bottom: BorderSide(color: c.line)),
                    ),
                    child: Row(
                      children: [
                        RgIcon(RgIcons.info, size: 14, color: c.dim),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            l.embedFallbackNote,
                            style: TextStyle(color: c.dim, fontSize: 12.5),
                          ),
                        ),
                        TextButton.icon(
                          key: const Key('embed-fallback-retry'),
                          onPressed: () => unawaited(reload()),
                          icon: RgIcon(RgIcons.refresh, size: 13, color: c.accent),
                          label: Text(l.refresh),
                        ),
                      ],
                    ),
                  ),
                  Expanded(child: Builder(builder: widget.fallback!)),
                ],
              ),
            if (error != null && widget.fallback == null)
              ColoredBox(
                key: const Key('embed-error'),
                color: c.bg,
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        RgIcon(RgIcons.alert, size: 22, color: c.err),
                        const SizedBox(height: 10),
                        Text(
                          error == 'certificate' ? l.errCertificate : l.errGeneric(error),
                          textAlign: TextAlign.center,
                          style: TextStyle(color: c.text),
                        ),
                        const SizedBox(height: 14),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          alignment: WrapAlignment.center,
                          children: [
                            FilledButton.icon(
                              key: const Key('embed-retry'),
                              onPressed: () => unawaited(reload()),
                              icon: const RgIcon(RgIcons.refresh, size: 14, color: Colors.white),
                              label: Text(l.refresh),
                            ),
                            if (widget.nonce == null)
                              OutlinedButton.icon(
                                key: const Key('embed-browser'),
                                onPressed: () => unawaited(
                                  openExternal(widget.url.replace(fragment: 'open=settings')),
                                ),
                                icon: RgIcon(RgIcons.external, size: 14, color: c.text),
                                label: Text(l.embedOpenInBrowser),
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// Tests: what the indicator waits for.
@visibleForTesting
const embedWaitKey = Key('embed-wait');

// One web view for the page inside the app (G42.0), on every system: webview_flutter on Android,
// iOS and macOS (WebView, WKWebView), WebView2 on Windows (webview_flutter_windows, drawn into
// Flutter), WebKitGTK on Linux (webview_all_linux, a native view over Flutter clipped to its place).
// The rules are the same everywhere: only the server's origin stays inside (anything else opens
// outside the app), a certificate the system does not trust goes on only when it is the very one
// the app checked against RedGiant's local CA (`sslProceed`), the page's channel is one
// (`embedChannel`, `chrome.webview` on Windows), and the background is the app's (no white flash).
import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:webview_all_linux/webview_all_linux.dart' as gtk;
import 'package:webview_flutter/webview_flutter.dart';
import 'package:webview_flutter_windows/webview_flutter_windows.dart' as win;
import 'package:webview_platform_interface/webview_platform_interface.dart' as gtkp;

import '../api/types.dart';
import '../api/web_settings.dart';
import 'embed_link.dart';

/// Which web view a system has (pure, a table in the tests).
enum WebEngine { flutter, windows, linux }

WebEngine webEngineFor(DevicePlatform p) => switch (p) {
  DevicePlatform.windows => WebEngine.windows,
  DevicePlatform.linux => WebEngine.linux,
  _ => WebEngine.flutter,
};

/// What a web view may do and tells.
class WebRules {
  const WebRules({
    required this.origin,
    required this.background,
    this.leaf,
    this.onOutside,
    this.onProgress,
    this.onError,
  });

  /// The server: navigations elsewhere open outside.
  final Uri origin;
  final Color background;

  /// The certificate checked against the local CA (null: the system's trust only).
  final Uint8List? leaf;
  final void Function(Uri url)? onOutside;
  final void Function(int percent)? onProgress;

  /// A main-frame error: `certificate`, or the engine's words.
  final void Function(String error)? onError;

  /// Whether a navigation stays in the view.
  bool stays(Uri u) =>
      u.scheme == 'about' || u.scheme == 'data' || u.scheme == 'blob' || sameOrigin(u, origin);
}

abstract class WebHost {
  /// The page's raw messages on the channel.
  Stream<String> get messages;
  Future<void> load(Uri url, WebRules rules);
  Future<void> run(String script);
  Future<void> reload();

  /// [eager]: it takes every gesture (a whole screen), else taps and sideways drags only.
  Widget view({required bool eager});
  void dispose();
}

/// Tests set this: a web view of their own.
@visibleForTesting
WebHost Function(WebEngine engine)? debugWebHost;

WebHost webHostFor(WebEngine e) =>
    debugWebHost?.call(e) ??
    switch (e) {
      WebEngine.windows => _WindowsWebHost(),
      WebEngine.linux => _LinuxWebHost(),
      WebEngine.flutter => _FlutterWebHost(),
    };

/// Android, iOS, macOS.
class _FlutterWebHost implements WebHost {
  final _out = StreamController<String>.broadcast();
  final _web = WebViewController();

  @override
  Stream<String> get messages => _out.stream;

  @override
  Future<void> load(Uri url, WebRules rules) async {
    await _web.setJavaScriptMode(JavaScriptMode.unrestricted);
    await _web.addJavaScriptChannel(embedChannel, onMessageReceived: (m) => _out.add(m.message));
    try {
      await _web.setBackgroundColor(rules.background);
    } on Object {
      // macOS's WKWebView has no background colour to set: the page's own shows.
    }
    await _web.setNavigationDelegate(
      NavigationDelegate(
        onProgress: rules.onProgress,
        onNavigationRequest: (r) {
          final u = Uri.tryParse(r.url);
          if (u == null) return NavigationDecision.prevent;
          if (rules.stays(u)) return NavigationDecision.navigate;
          if (r.isMainFrame) rules.onOutside?.call(u);
          return NavigationDecision.prevent;
        },
        onSslAuthError: (e) {
          if (sslProceed(e.certificate?.data, rules.leaf)) {
            unawaited(e.proceed());
          } else {
            unawaited(e.cancel());
            rules.onError?.call('certificate');
          }
        },
        onWebResourceError: (e) {
          if (e.isForMainFrame == true) rules.onError?.call(e.description);
        },
      ),
    );
    await _web.loadRequest(url);
  }

  @override
  Future<void> run(String script) => _web.runJavaScript(script);

  @override
  Future<void> reload() => _web.reload();

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

/// Windows: WebView2 drawn into a Flutter texture. It has no veto on a navigation: when the top
/// leaves the server it is brought back and the link opens outside.
class _WindowsWebHost implements WebHost {
  final _out = StreamController<String>.broadcast();
  final _c = win.WebviewController();
  final _subs = <StreamSubscription<dynamic>>[];
  Uri? _url;
  bool _gone = false;

  @override
  Stream<String> get messages => _out.stream;

  @override
  Future<void> load(Uri url, WebRules rules) async {
    _url = url;
    await _c.initialize();
    if (_gone) return;
    await _c.setPopupWindowPolicy(win.WebviewPopupWindowPolicy.deny);
    await _c.setBackgroundColor(rules.background);
    await _c.setZoomControlEnabled(false);
    _subs
      ..add(_c.webMessage.listen((m) => _out.add(m is String ? m : jsonEncode(m))))
      ..add(
        _c.url.listen((u) {
          final x = Uri.tryParse(u);
          if (x == null || rules.stays(x)) return;
          rules.onOutside?.call(x);
          unawaited(_c.goBack());
        }),
      )
      ..add(_c.onLoadError.listen((e) => rules.onError?.call(e.name)))
      ..add(
        _c.loadingState.listen((s) {
          if (s == win.LoadingState.navigationCompleted) rules.onProgress?.call(100);
        }),
      );
    // The page's channel is chrome.webview there; the same name as elsewhere, for the page.
    await _c.addScriptToExecuteOnDocumentCreated(
      'window.$embedChannel={postMessage:(s)=>window.chrome.webview.postMessage(s)};',
    );
    await _c.loadUrl(url.toString());
  }

  @override
  Future<void> run(String script) async {
    if (_c.value.isInitialized) await _c.executeScript(script);
  }

  @override
  Future<void> reload() async {
    if (_c.value.isInitialized) {
      await _c.reload();
    } else if (_url != null) {
      await _c.loadUrl(_url.toString());
    }
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
    for (final s in _subs) {
      unawaited(s.cancel());
    }
    unawaited(_out.close());
    unawaited(_c.dispose());
  }
}

/// Linux: WebKitGTK placed over the Flutter view where this widget is, clipped to it.
class _LinuxWebHost implements WebHost {
  final _out = StreamController<String>.broadcast();
  final _c = gtk.LinuxWebViewController(const gtkp.PlatformWebViewControllerCreationParams());

  @override
  Stream<String> get messages => _out.stream;

  @override
  Future<void> load(Uri url, WebRules rules) async {
    await _c.setJavaScriptMode(gtkp.JavaScriptMode.unrestricted);
    await _c.addJavaScriptChannel(
      gtkp.JavaScriptChannelParams(
        name: embedChannel,
        onMessageReceived: (m) => _out.add(m.message),
      ),
    );
    await _c.setBackgroundColor(rules.background);
    final nav = gtk.LinuxNavigationDelegate(const gtkp.PlatformNavigationDelegateCreationParams());
    await nav.setOnNavigationRequest((r) {
      final u = Uri.tryParse(r.url);
      if (u == null) return gtkp.NavigationDecision.prevent;
      if (rules.stays(u)) return gtkp.NavigationDecision.navigate;
      if (r.isMainFrame) rules.onOutside?.call(u);
      return gtkp.NavigationDecision.prevent;
    });
    await nav.setOnProgress((p) => rules.onProgress?.call(p));
    await nav.setOnSSlAuthError((e) {
      if (sslProceed(e.certificate?.data, rules.leaf)) {
        unawaited(e.proceed());
      } else {
        unawaited(e.cancel());
        rules.onError?.call('certificate');
      }
    });
    await nav.setOnWebResourceError((e) {
      if (e.isForMainFrame == true) rules.onError?.call(e.description);
    });
    await _c.setPlatformNavigationDelegate(nav);
    await _c.loadRequest(gtkp.LoadRequestParams(uri: url));
  }

  @override
  Future<void> run(String script) => _c.runJavaScript(script);

  @override
  Future<void> reload() => _c.reload();

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

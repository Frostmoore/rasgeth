// The frame of artifacts and widgets, on the app's side (the page's `artifact-frame.ts`,
// `ArtifactFrame.tsx` and `artifact-bridge.ts`, in Dart). The web view loads a small page of ours
// (`frameWrapperPage`) from the app's own preview relay on 127.0.0.1 (`preview_relay.dart`); that
// page holds the server's `/preview/<token>/…` in an `<iframe sandbox="allow-scripts allow-forms">`
// (an opaque origin, the server's policy with no network), listens only to that frame and hands
// its messages to the app with a secret of this load (the nonce: the frame cannot read it, so it
// cannot speak to the app by itself, even where the web view's channel reaches every frame).
// Everything here is pure and tested as tables (`test/g387_web_test.dart`).
import 'dart:async';
import 'dart:convert';

import 'widgets.dart';

export 'widgets.dart' show kArtifactSandbox, kArtifactClickMs, kArtifactMessageMax;

/// Calls one frame may have waiting at once (`ARTIFACT_PENDING_MAX`).
const int kArtifactPendingMax = 16;

/// The biggest value `storage.set` takes (`ARTIFACT_STORAGE_MAX`).
const int kArtifactStorageMax = 5 * 1024 * 1024;

/// How long a bridge call waits (a grant waits for the person, then the model answers).
const Duration kBridgeWait = Duration(minutes: 15);

const _errorKinds = {'error', 'rejection', 'console', 'lib', 'compile', 'blocked'};

/// One error an artifact or widget met (`ArtifactError`).
class ArtifactErrorInfo {
  const ArtifactErrorInfo({required this.kind, required this.message, this.where});

  final String kind;
  final String message;
  final String? where;

  Map<String, Object?> toJson() => {'kind': kind, 'message': message, 'where': ?where};

  @override
  bool operator ==(Object other) =>
      other is ArtifactErrorInfo &&
      other.kind == kind &&
      other.message == message &&
      other.where == where;

  @override
  int get hashCode => Object.hash(kind, message, where);
}

/// What a frame's runtime posts (`FrameMessage`, JSON-RPC shapes with MCP Apps' names).
sealed class FrameMessage {
  const FrameMessage();
}

class FrameSizeChanged extends FrameMessage {
  const FrameSizeChanged(this.height, [this.width]);

  final double height;
  final double? width;
}

class FrameUiMessage extends FrameMessage {
  const FrameUiMessage(this.texts, [this.id]);

  final List<String> texts;
  final Object? id;
}

class FrameInitialized extends FrameMessage {
  const FrameInitialized();
}

class FrameErrorMessage extends FrameMessage {
  const FrameErrorMessage(this.error);

  final ArtifactErrorInfo error;
}

/// A bridge call (3.6, G38.7): `ask`, `storage.*`, `files.*`; only artifacts, never widgets.
class FrameBridgeCall extends FrameMessage {
  const FrameBridgeCall(this.id, this.call);

  final int id;

  /// The call as the server takes it (`BridgeCall`), with only its known fields.
  final Map<String, Object?> call;
}

int? _int(Object? o) {
  if (o is int) return o;
  if (o is double && o.isFinite && o == o.truncateToDouble()) return o.toInt();
  return null;
}

bool _str(Object? o, {int min = 0, required int max}) =>
    o is String && o.length >= min && o.length <= max;

/// A bridge call of the right shape, with only its known fields (`BridgeCall`), or null.
Map<String, Object?>? bridgeCallOf(Object? p) {
  if (p is! Map) return null;
  switch (p['op']) {
    case 'ask':
      return _str(p['prompt'], min: 1, max: 20000) ? {'op': 'ask', 'prompt': p['prompt']} : null;
    case 'storage.get' || 'storage.delete':
      return _str(p['key'], min: 1, max: 200) ? {'op': p['op'], 'key': p['key']} : null;
    case 'storage.set':
      return _str(p['key'], min: 1, max: 200) && _str(p['value'], max: kArtifactStorageMax)
          ? {'op': 'storage.set', 'key': p['key'], 'value': p['value']}
          : null;
    case 'storage.list':
      if (!p.containsKey('prefix')) return {'op': 'storage.list'};
      return _str(p['prefix'], max: 200) ? {'op': 'storage.list', 'prefix': p['prefix']} : null;
    case 'files.read':
      final as = p.containsKey('as') ? p['as'] : 'text';
      if (!_str(p['path'], min: 1, max: 1000) || (as != 'text' && as != 'binary')) return null;
      return {'op': 'files.read', 'path': p['path'], 'as': as};
    case 'files.list':
      return _str(p['dir'], max: 1000) ? {'op': 'files.list', 'dir': p['dir']} : null;
  }
  return null;
}

/// A frame's message if it is one of ours (the page's `FrameMessage.safeParse`), else null.
FrameMessage? parseFrameMessage(Object? d) {
  if (d is! Map) return null;
  final params = d['params'];
  switch (d['method']) {
    case 'ui/notifications/size-changed':
      if (params is! Map) return null;
      final h = params['height'];
      final w = params['width'];
      if (h is! num || h.isNaN || h < 0 || h > 100000) return null;
      if (params.containsKey('width') && w is! num) return null;
      return FrameSizeChanged(h.toDouble(), (w as num?)?.toDouble());
    case 'ui/message':
      final id = d['id'];
      if (d.containsKey('id') && id is! num && id is! String) return null;
      if (params is! Map) return null;
      if (params.containsKey('role') && params['role'] != 'user') return null;
      final content = params['content'];
      if (content is! List || content.isEmpty || content.length > 10) return null;
      final texts = <String>[];
      for (final c in content) {
        if (c is! Map || c['type'] != 'text' || c['text'] is! String) return null;
        texts.add(c['text'] as String);
      }
      return FrameUiMessage(texts, id);
    case 'ui/notifications/initialized':
      if (d.containsKey('params') && params is! Map) return null;
      return const FrameInitialized();
    case 'redgiant/error':
      if (params is! Map) return null;
      final kind = params['kind'];
      final where = params['where'];
      if (kind is! String || !_errorKinds.contains(kind)) return null;
      if (!_str(params['message'], max: 2000)) return null;
      if (params.containsKey('where') && !_str(where, max: 200)) return null;
      return FrameErrorMessage(
        ArtifactErrorInfo(
          kind: kind,
          message: params['message'] as String,
          where: where as String?,
        ),
      );
    case 'redgiant/bridge':
      final id = _int(d['id']);
      if (id == null || id < 0 || id > 1000000000) return null;
      final call = bridgeCallOf(params);
      return call == null ? null : FrameBridgeCall(id, call);
  }
  return null;
}

/// The text a frame's `ui/message` asks to send, or null when it is empty or too long.
String? frameMessageText(FrameMessage m) {
  if (m is! FrameUiMessage) return null;
  final text = m.texts.join('\n').trim();
  return text.isNotEmpty && text.length <= kArtifactMessageMax ? text : null;
}

/// A bridge call of the wrong shape (the page's `bridgeRejection`): answered with an error, so
/// the artifact's promise does not wait for ever; it never reaches the server. Null otherwise.
({int id, Map<String, String> error})? bridgeRejection(Object? d) {
  if (d is! Map || d['method'] != 'redgiant/bridge') return null;
  final id = d['id'];
  if (id is! num || _int(id) == null || id < 0 || id > 1e9) return null;
  if (parseFrameMessage(d) != null) return null;
  final p = d['params'];
  final big =
      p is Map &&
      p['op'] == 'storage.set' &&
      p['value'] is String &&
      (p['value'] as String).length > kArtifactStorageMax;
  return (
    id: _int(id)!,
    error: big
        ? {
            'code': 'too_big',
            'message': 'The storage holds at most ${kArtifactStorageMax ~/ 1024 ~/ 1024} MB',
          }
        : {
            'code': 'bad_request',
            'message': 'Not a bridge call RedGiant knows (see canvas_edit help)',
          },
  );
}

/// A link a frame asks to open (`{redgiant: "open-link", url}`, `preview-links.ts`): http(s) only.
Uri? previewLinkOf(Object? d) {
  if (d is! Map || d['redgiant'] != 'open-link' || d['url'] is! String) return null;
  final u = Uri.tryParse(d['url'] as String);
  if (u == null || !u.hasAuthority || (u.scheme != 'http' && u.scheme != 'https')) return null;
  return u;
}

/// The click rule (the page's `ClickGuard`): a click in a frame makes the page around it lose its
/// focus to the frame; a message within [kArtifactClickMs] of it is the person's, one per click.
/// When focus already sits in the frame, the browser's own user activation (which a frame's code
/// cannot fake) counts once, and not again for 5 s.
class ClickGuard {
  ClickGuard([int Function()? now]) : _now = now ?? (() => DateTime.now().millisecondsSinceEpoch);

  final int Function() _now;
  int? _clickedAt;
  bool _used = true;
  int? _lastActivated;

  /// The page lost focus to this frame.
  void clicked() {
    _clickedAt = _now();
    _used = false;
  }

  /// Whether a message arriving now may go at once.
  bool take({required bool focused, required bool activated}) {
    final now = _now();
    final at = _clickedAt;
    if (!_used && at != null && now - at <= kArtifactClickMs) {
      _used = true;
      _lastActivated = now;
      return true;
    }
    final last = _lastActivated;
    if (focused && activated && (last == null || now - last > 5000)) {
      _lastActivated = now;
      return true;
    }
    return false;
  }
}

/// Errors of one frame, deduplicated, at most [kArtifactErrorsMax] (`addErrors`).
List<ArtifactErrorInfo> addErrors(List<ArtifactErrorInfo> kept, List<ArtifactErrorInfo> more) {
  final out = [...kept];
  for (final e in more) {
    if (out.length >= kArtifactErrorsMax) break;
    if (!out.contains(e)) out.add(e);
  }
  return out;
}

/// The theme variables a frame gets (`--rg-*`), from the page's names (`VARS`) to their values.
const kFrameThemeVars = [
  'bg',
  'panel',
  'panel-2',
  'line',
  'text',
  'dim',
  'accent',
  'accent-2',
  'accent-soft',
  'ok',
  'warn',
  'warn-text',
  'err',
  'radius',
  'mono',
];

/// The app's theme and language as frames get them (`ui/notifications/host-context-changed`,
/// the page's `hostContext`). [vars] holds the page's variable names without `--`.
Map<String, Object?> hostContext(
  Map<String, String> vars, {
  required bool dark,
  required String locale,
  String? font,
}) {
  final variables = <String, String>{
    for (final v in kFrameThemeVars)
      if ((vars[v] ?? '').trim().isNotEmpty) '--rg-$v': vars[v]!.trim(),
    if (font != null && font.isNotEmpty) '--rg-font': font,
  };
  return {
    'theme': dark ? 'dark' : 'light',
    'locale': locale,
    'styles': {'variables': variables},
  };
}

/// The message that carries [hostContext] to the frame.
Map<String, Object?> hostContextMessage(Map<String, Object?> context) => {
  'jsonrpc': '2.0',
  'method': 'ui/notifications/host-context-changed',
  'params': context,
};

/// What the wrapper page hands to the app, once its nonce is checked.
sealed class FrameEvent {
  const FrameEvent();
}

/// The person clicked in the frame (the wrapper lost its focus to it).
class FrameClicked extends FrameEvent {
  const FrameClicked();
}

/// The frame (re)loaded.
class FrameLoaded extends FrameEvent {
  const FrameLoaded();
}

/// A message the frame posted: as it came, plus where the focus was and whether the wrapper had
/// the browser's user activation at that moment.
class FramePosted extends FrameEvent {
  const FramePosted(this.data, {required this.focused, required this.activated});

  final Object? data;
  final bool focused;
  final bool activated;
}

/// A message of the wrapper (`{n, k, d, f, a}` as JSON), or null when it is not one or its nonce
/// is not this load's.
FrameEvent? frameEventOf(String raw, String nonce) {
  if (nonce.isEmpty || raw.length > 12 * 1024 * 1024) return null;
  Object? j;
  try {
    j = jsonDecode(raw);
  } on FormatException {
    return null;
  }
  if (j is! Map || j['n'] != nonce) return null;
  return switch (j['k']) {
    'click' => const FrameClicked(),
    'load' => const FrameLoaded(),
    'msg' => FramePosted(j['d'], focused: j['f'] == true, activated: j['a'] == true),
    _ => null,
  };
}

/// The JavaScript that hands [message] to the frame (only to it) from the wrapper.
String postToFrameScript(Map<String, Object?> message) =>
    'window.__rgPost&&window.__rgPost(${jsonEncode(message)});';

String _attr(String s) => s
    .replaceAll('&', '&amp;')
    .replaceAll('"', '&quot;')
    .replaceAll('<', '&lt;')
    .replaceAll('>', '&gt;');

/// The page the web view loads (served by the relay at `/rg-frame/<id>`): the frame and one script
/// of ours, by nonce. [src] is the relay's `/preview/<token>/…`; [origin] the relay's origin.
({String body, Map<String, String> headers}) frameWrapperPage({
  required String src,
  required String origin,
  required String nonce,
  required String title,
  String sandbox = kArtifactSandbox,
}) {
  final preview = Uri.parse(src).pathSegments;
  final prefix = preview.length >= 2 ? '/${preview[0]}/${preview[1]}/' : '/preview/';
  // `RGHost` is the channel of webview_flutter (Android, iOS, macOS); `chrome.webview` WebView2's.
  final script =
      '(()=>{const N=${jsonEncode(nonce)};const f=document.querySelector("iframe");'
      'const up=o=>{try{o.n=N;const s=JSON.stringify(o);if(window.RGHost&&RGHost.postMessage)RGHost.postMessage(s);'
      'else if(window.chrome&&chrome.webview)chrome.webview.postMessage(s)}catch(_){}};'
      'addEventListener("message",e=>{if(e.source!==f.contentWindow)return;const u=navigator.userActivation;'
      'up({k:"msg",d:e.data,f:document.activeElement===f,a:!!(u&&u.isActive)})});'
      'addEventListener("blur",()=>setTimeout(()=>{if(document.activeElement===f)up({k:"click"})},0));'
      'f.addEventListener("load",()=>up({k:"load"}));'
      // The wrapper takes the frame's colour scheme too: a scheme different from the frame's
      // makes the engine paint the frame opaque (the page's «black box», styles.css).
      'const T=m=>{const p=m&&m.method==="ui/notifications/host-context-changed"&&m.params;'
      'if(p&&(p.theme==="dark"||p.theme==="light"))document.documentElement.style.colorScheme=p.theme};'
      'Object.defineProperty(window,"__rgPost",{value:m=>{try{T(m);f.contentWindow.postMessage(m,"*")}catch(_){}}});})();';
  final body =
      '<!doctype html><html><head><meta charset="utf-8">'
      '<meta name="viewport" content="width=device-width, initial-scale=1">'
      '<meta name="referrer" content="no-referrer"><title>${_attr(title)}</title>'
      '<style nonce="$nonce">html,body{margin:0;height:100%;background:transparent;overflow:hidden}'
      'iframe{border:0;width:100%;height:100%;display:block;background:transparent}</style></head>'
      '<body><iframe src="${_attr(src)}" sandbox="${_attr(sandbox)}" referrerpolicy="no-referrer" '
      'title="${_attr(title)}"></iframe><script nonce="$nonce">$script</script></body></html>';
  return (
    body: body,
    headers: {
      'Content-Type': 'text/html; charset=utf-8',
      'Cache-Control': 'no-store',
      'X-Content-Type-Options': 'nosniff',
      'Referrer-Policy': 'no-referrer',
      'Content-Security-Policy':
          "default-src 'none'; script-src 'nonce-$nonce'; style-src 'nonce-$nonce'; "
          'frame-src $origin$prefix; form-action \'none\'; base-uri \'none\'; '
          "frame-ancestors 'none'",
    },
  );
}

final RegExp _origin = RegExp(r'^https?://[^/\s;]+(/.*)?$', caseSensitive: false);

/// The server's policy for a page seen through the relay: every origin it names (the server's own,
/// where it allows libraries and who may frame it) becomes the relay's, nothing else changes.
String relayCsp(String csp, String origin) => csp
    .split(';')
    .map((d) {
      final words = d.trim().split(RegExp(r'\s+')).where((w) => w.isNotEmpty);
      final out = <String>[];
      for (final w in words) {
        final m = _origin.firstMatch(w);
        final v = m == null ? w : '$origin${m.group(1) ?? ''}';
        if (!out.contains(v)) out.add(v);
      }
      return out.join(' ');
    })
    .where((d) => d.isNotEmpty)
    .join('; ');

/// Whether the web view may go to [url]: the top only to the wrapper page, a frame only inside its
/// own preview (`/preview/<token>/`) on the relay. Everything else stays where it is.
bool frameNavigationAllowed(
  Uri url, {
  required bool mainFrame,
  required Uri wrapper,
  required Uri preview,
}) {
  bool sameOrigin(Uri a, Uri b) =>
      a.scheme == b.scheme && a.host.toLowerCase() == b.host.toLowerCase() && a.port == b.port;
  if (mainFrame) return sameOrigin(url, wrapper) && url.path == wrapper.path;
  final p = preview.pathSegments;
  if (p.length < 2) return false;
  return sameOrigin(url, preview) && url.path.startsWith('/${p[0]}/${p[1]}/');
}

/// What the app does with the frame's messages: the page's `ArtifactFrame` listener, without a
/// browser. The screen gives it the ways out; [handle] takes the wrapper's raw messages.
class FrameSession {
  FrameSession({
    required this.nonce,
    required this.ref,
    required this.postToFrame,
    required this.hostContext,
    this.sessionId,
    this.auto = false,
    ClickGuard? guard,
    this.onHeight,
    this.onSend,
    this.onAsk,
    this.onErrors,
    this.reportErrors,
    this.onLink,
    this.sendBridge,
    this.flushAfter = const Duration(milliseconds: 400),
  }) : guard = guard ?? ClickGuard();

  final String nonce;

  /// What its errors belong to (`ArtifactRef`): `{kind: file, scope, path}` or
  /// `{kind: widget, sessionId, seq, index}`.
  final Map<String, Object?> ref;

  /// The conversation it sends to: a widget's own, or the one the Canvas was opened from.
  final String? sessionId;
  final bool auto;
  final ClickGuard guard;
  final void Function(Map<String, Object?> message) postToFrame;
  final Map<String, Object?> Function() hostContext;
  final void Function(double height)? onHeight;

  /// A message sent as the person's (right after their click in the frame).
  final void Function(String sessionId, String text)? onSend;

  /// A message that waits for «Send» or «Leave it» (no click, or no conversation).
  final void Function(String text)? onAsk;
  final void Function(List<ArtifactErrorInfo> errors)? onErrors;

  /// To the server (`POST /api/artifacts/errors`), for the agent.
  final void Function(List<ArtifactErrorInfo> batch, {required bool fresh})? reportErrors;
  final void Function(Uri url)? onLink;

  /// `artifact.bridge` over the live connection; false when it cannot go.
  final bool Function(Map<String, Object?> message)? sendBridge;
  final Duration flushAfter;

  var errors = <ArtifactErrorInfo>[];
  final _queued = <ArtifactErrorInfo>[];
  Timer? _timer;
  int loads = 0;
  final _pending = <String, ({int id, int load, Timer timer})>{};
  static int _seq = 0;
  bool _closed = false;

  void sendTheme() => postToFrame(hostContextMessage(hostContext()));

  void _flush({bool fresh = false}) {
    final batch = [..._queued];
    _queued.clear();
    if (batch.isEmpty && !fresh) return;
    reportErrors?.call(batch, fresh: fresh);
  }

  void _bridgeReply(int id, Map<String, Object?> body) =>
      postToFrame({'jsonrpc': '2.0', 'method': 'redgiant/bridge-result', 'id': id, ...body});

  /// One raw message of the wrapper.
  void handle(String raw) {
    if (_closed) return;
    final e = frameEventOf(raw, nonce);
    switch (e) {
      case null:
        return;
      case FrameClicked():
        guard.clicked();
        return;
      case FrameLoaded():
        // Loaded: the theme again (its first messages may come before the app listens).
        sendTheme();
        return;
      case FramePosted(:final data, :final focused, :final activated):
        final link = previewLinkOf(data);
        if (link != null) {
          onLink?.call(link);
          return;
        }
        final m = parseFrameMessage(data);
        if (m == null) {
          final no = bridgeRejection(data);
          if (no != null) _bridgeReply(no.id, {'error': no.error});
          return;
        }
        _message(m, focused: focused, activated: activated);
    }
  }

  void _message(FrameMessage m, {required bool focused, required bool activated}) {
    switch (m) {
      case FrameInitialized():
        sendTheme();
        // Every load: what it said before (an older version, an earlier visit) is forgotten.
        if (loads++ > 0 || errors.isNotEmpty) {
          errors = [];
          onErrors?.call(errors);
        }
        _queued.clear();
        _timer?.cancel();
        _flush(fresh: true);
      case FrameSizeChanged(:final height):
        if (auto) onHeight?.call(height.ceilToDouble() < 24 ? 24 : height.ceilToDouble());
      case FrameErrorMessage(:final error):
        final before = errors.length;
        errors = addErrors(errors, [error]);
        if (errors.length == before) return;
        onErrors?.call(errors);
        _queued.add(error);
        _timer?.cancel();
        _timer = Timer(flushAfter, _flush);
      case FrameBridgeCall(:final id, :final call):
        _bridge(id, call);
      case FrameUiMessage():
        final text = frameMessageText(m);
        if (text == null) return;
        final to = sessionId;
        final clicked = guard.take(focused: focused, activated: activated);
        if (clicked && to != null) {
          onSend?.call(to, text);
        } else {
          onAsk?.call(text);
        }
    }
  }

  void _bridge(int id, Map<String, Object?> call) {
    Map<String, String> err(String code, String message) => {'code': code, 'message': message};
    if (ref['kind'] != 'file') {
      _bridgeReply(id, {
        'error': err(
          'unavailable',
          'Widgets have no bridge: keep it as an artifact first («Keep it»)',
        ),
      });
      return;
    }
    if (_pending.length >= kArtifactPendingMax) {
      _bridgeReply(id, {'error': err('rate_limited', 'Too many bridge calls waiting')});
      return;
    }
    final requestId =
        'b${DateTime.now().millisecondsSinceEpoch.toRadixString(36)}${(++_seq).toRadixString(36)}';
    final load = loads;
    final timer = Timer(kBridgeWait, () {
      if (_pending.remove(requestId) == null) return;
      _bridgeReply(id, {'error': err('failed', 'No answer from RedGiant')});
    });
    _pending[requestId] = (id: id, load: load, timer: timer);
    final ok =
        sendBridge?.call({
          'type': 'artifact.bridge',
          'requestId': requestId,
          'ref': ref,
          'sessionId': ?sessionId,
          'call': call,
        }) ??
        false;
    if (!ok) {
      timer.cancel();
      _pending.remove(requestId);
      _bridgeReply(id, {'error': err('failed', 'RedGiant is not connected')});
    }
  }

  /// The server's answer (`artifact.bridge.result`): to the frame, if it still shows that load.
  void bridgeResult(Map<String, dynamic> m) {
    final p = _pending.remove(m['requestId']);
    if (p == null) return;
    p.timer.cancel();
    if (p.load != loads || _closed) return;
    final error = m['error'];
    _bridgeReply(p.id, error is Map ? {'error': error} : {'result': m['result'] ?? const {}});
  }

  /// The frame goes away: its errors go to the server, what it asked is forgotten.
  void close() {
    if (_closed) return;
    _timer?.cancel();
    _flush();
    _closed = true;
    for (final p in _pending.values) {
      p.timer.cancel();
    }
    _pending.clear();
  }
}

// The bridge between the app and the page inside it (G42.0): the page's messages, read with the
// nonce the app put in the fragment and checked as the protocol's `EmbedToApp` checks them, and the
// app's (`AppToEmbed`) posted to the page's own window. The same rules as
// `packages/protocol/src/embed.ts`, checked against `test/fixtures/embed_vectors.json`.
import 'dart:convert';

/// Files one message carries, and the biggest one (`EMBED_FILES_MAX`, `EMBED_FILE_MAX`).
const embedFilesMax = 20;
const embedFileMax = 25 * 1024 * 1024;

/// The keys the app passes on (`EMBED_KEYS`).
enum EmbedKey { save, undo, redo, find }

/// The drawn icons a Canvas action may carry (`EMBED_ACTION_ICONS`, G42.6).
const embedActionIcons = [
  'play',
  'code',
  'folderPlus',
  'pencil',
  'brush',
  'alert',
  'keyboard',
  'chat',
];

/// The most actions one bar carries (`EMBED_ACTIONS_MAX`).
const embedActionsMax = 12;

/// «Ask the agent» about what is selected (`EMBED_ASK_ACTION`, G42.7): shown only where the app
/// has a conversation's composer for it.
const embedAskAction = 'ask';

final _actionId = RegExp(r'^[a-z][a-z0-9.-]*$');

final _serverPath = RegExp(r'^/(?!/)');
final _webLink = RegExp(r'^https?://\S+$', caseSensitive: false);
final _base64 = RegExp(r'^[A-Za-z0-9+/]*={0,2}$');
final _font = RegExp(r'^[^;{}<>]+$');

bool _str(Object? v, {int min = 0, required int max}) =>
    v is String && v.length >= min && v.length <= max;
bool _optStr(Object? v, {int min = 0, required int max}) =>
    v == null || _str(v, min: min, max: max);
bool _count(Object? v) => v is int && v >= 0 && v <= 999999999;
bool _optCount(Object? v) => v == null || _count(v);
bool _only(Map<String, Object?> m, Set<String> keys) => m.keys.every(keys.contains);
bool _optBool(Object? v) => v == null || v is bool;
bool _id(Object? v) => _str(v, min: 1, max: 40) && _actionId.hasMatch(v! as String);
bool _positive(Object? v) => v == null || (v is int && v > 0);

/// A Canvas target as the protocol's `CanvasTargetSchema` takes it (a file or an agent's port).
bool embedTargetOk(Object? t) {
  if (t is! Map) return false;
  final x = t.cast<String, Object?>();
  return switch (x['kind']) {
    'file' =>
      x['scope'] is String &&
          x['path'] is String &&
          (x['at'] == null ||
              (x['at'] is Map &&
                  _positive((x['at']! as Map)['page']) &&
                  _positive((x['at']! as Map)['line']))),
    'port' =>
      x['agentId'] is String && x['port'] is int && (x['path'] == null || x['path'] is String),
    _ => false,
  };
}

/// One of the bar's actions (`EmbedAction`).
bool _action(Object? a) {
  if (a is! Map) return false;
  final x = a.cast<String, Object?>();
  return _only(x, {'id', 'label', 'icon', 'on', 'disabled', 'primary', 'hint'}) &&
      _id(x['id']) &&
      _str(x['label'], min: 1, max: 80) &&
      (x['icon'] == null || embedActionIcons.contains(x['icon'])) &&
      _optBool(x['on']) &&
      _optBool(x['disabled']) &&
      _optBool(x['primary']) &&
      _optStr(x['hint'], max: 300);
}

/// A page message (`EmbedToApp`) if [m] is one, as it came; null otherwise.
Map<String, Object?>? embedToApp(Object? m) {
  if (m is! Map) return null;
  final x = m.cast<String, Object?>();
  final ok = switch (x['t']) {
    'ready' => _only(x, {'t'}),
    'title' =>
      _only(x, {'t', 'name', 'kind', 'size'}) &&
          _str(x['name'], max: 300) &&
          _optStr(x['kind'], max: 40) &&
          _optCount(x['size']),
    'saveState' =>
      _only(x, {'t', 'state', 'error'}) &&
          const ['saved', 'saving', 'error'].contains(x['state']) &&
          _optStr(x['error'], max: 500),
    'saveAs' =>
      _only(x, {'t', 'name', 'url', 'data', 'mime'}) &&
          _str(x['name'], min: 1, max: 255) &&
          (x['url'] == null) != (x['data'] == null) &&
          (x['url'] == null ||
              (_str(x['url'], max: 4000) && _serverPath.hasMatch(x['url']! as String))) &&
          (x['data'] == null ||
              (_str(x['data'], max: (embedFileMax / 3).ceil() * 4) &&
                  _base64.hasMatch(x['data']! as String))) &&
          _optStr(x['mime'], max: 200),
    'openFile' =>
      _only(x, {'t', 'id', 'accept', 'multiple'}) &&
          _str(x['id'], min: 1, max: 64) &&
          (x['accept'] == null ||
              (x['accept'] is List &&
                  (x['accept']! as List).length <= 20 &&
                  (x['accept']! as List).every((a) => _str(a, max: 100)))) &&
          (x['multiple'] == null || x['multiple'] is bool),
    'copy' => _only(x, {'t', 'text'}) && _str(x['text'], max: 1000000),
    'share' =>
      _only(x, {'t', 'title', 'text', 'url'}) &&
          _optStr(x['title'], max: 300) &&
          _optStr(x['text'], max: 100000) &&
          (x['url'] == null ||
              (_str(x['url'], max: 4000) && _webLink.hasMatch(x['url']! as String))) &&
          (x['text'] != null || x['url'] != null),
    'askAgent' =>
      _only(x, {'t', 'text', 'ref'}) && _str(x['text'], min: 1, max: 20000) && _ref(x['ref']),
    'external' || 'previewLink' =>
      _only(x, {'t', 'url'}) && _str(x['url'], max: 4000) && _webLink.hasMatch(x['url']! as String),
    'close' => _only(x, {'t'}),
    'back' => _only(x, {'t', 'handled'}) && x['handled'] is bool,
    'bar' =>
      _only(x, {'t', 'actions', 'note', 'link', 'download', 'paste', 'readOnly'}) &&
          x['actions'] is List &&
          (x['actions']! as List).length <= embedActionsMax &&
          (x['actions']! as List).every(_action) &&
          _optStr(x['note'], max: 300) &&
          (x['link'] == null ||
              (_str(x['link'], max: 4000) && _serverPath.hasMatch(x['link']! as String))) &&
          _optBool(x['download']) &&
          _optBool(x['paste']) &&
          _optBool(x['readOnly']),
    'open' =>
      _only(x, {'t', 'title', 'target'}) &&
          _str(x['title'], max: 300) &&
          embedTargetOk(x['target']),
    _ => false,
  };
  return ok ? x : null;
}

bool _ref(Object? r) {
  if (r is! Map) return false;
  final x = r.cast<String, Object?>();
  return _only(x, {'scope', 'path', 'line', 'lineEnd', 'page'}) &&
      _optStr(x['scope'], max: 200) &&
      _optStr(x['path'], max: 4000) &&
      _optCount(x['line']) &&
      _optCount(x['lineEnd']) &&
      _optCount(x['page']);
}

/// A page's raw message (`{ rg: "embed", n, m }`): its message when the nonce is [nonce] and it is
/// well formed, null otherwise (`readEmbedEnvelope`).
Map<String, Object?>? readEmbedEnvelope(String raw, String nonce) {
  Object? v;
  try {
    v = jsonDecode(raw);
  } on FormatException {
    return null;
  }
  if (v is! Map || v['rg'] != 'embed' || v['n'] != nonce) return null;
  return embedToApp(v['m']);
}

/// A file for the page (`EmbedFile`).
Map<String, Object?> embedFile(String name, String type, List<int> bytes) => {
  'name': name,
  'type': type,
  'size': bytes.length,
  'data': base64Encode(bytes),
};

/// Whether [m] is an app message the page takes (`AppToEmbed`).
bool appToEmbedOk(Map<String, Object?> m) {
  bool files(Object? f) =>
      f is List &&
      f.length <= embedFilesMax &&
      f.every(
        (e) =>
            e is Map &&
            _only(e.cast<String, Object?>(), {'name', 'type', 'size', 'data'}) &&
            _str(e['name'], min: 1, max: 255) &&
            _str(e['type'], max: 200) &&
            e['size'] is int &&
            (e['size'] as int) >= 0 &&
            (e['size'] as int) <= embedFileMax &&
            _str(e['data'], max: (embedFileMax / 3).ceil() * 4) &&
            _base64.hasMatch(e['data']! as String),
      );
  return switch (m['t']) {
    'theme' => _only(m, {'t', 'theme'}) && const ['light', 'dark'].contains(m['theme']),
    'lang' => _only(m, {'t', 'lang'}) && const ['it', 'en'].contains(m['lang']),
    'font' =>
      _only(m, {'t', 'family'}) &&
          _str(m['family'], min: 1, max: 200) &&
          _font.hasMatch(m['family']! as String),
    'back' => _only(m, {'t'}),
    'key' => _only(m, {'t', 'key'}) && EmbedKey.values.any((k) => k.name == m['key']),
    'files' =>
      _only(m, {'t', 'id', 'files'}) && _optStr(m['id'], min: 1, max: 64) && files(m['files']),
    'paste' =>
      _only(m, {'t', 'text', 'files'}) &&
          _optStr(m['text'], max: 1000000) &&
          (m['files'] == null || files(m['files'])),
    'action' => _only(m, {'t', 'id'}) && _id(m['id']),
    'tabs' =>
      _only(m, {'t', 'visible', 'tabs'}) &&
          m['visible'] is bool &&
          m['tabs'] is List &&
          (m['tabs']! as List).length <= 50 &&
          (m['tabs']! as List).every(
            (t) =>
                t is Map &&
                _only(t.cast<String, Object?>(), {'title', 'target', 'active'}) &&
                _str(t['title'], max: 300) &&
                embedTargetOk(t['target']) &&
                t['active'] is bool,
          ),
    _ => false,
  };
}

/// The script that hands [m] to the page (posted to its own window, as the page listens).
String appMessageScript(Map<String, Object?> m) {
  if (!appToEmbedOk(m)) throw ArgumentError.value(m, 'm', 'Not a message the page takes');
  return 'window.postMessage(${jsonEncode({'rg': 'app', 'm': m})}, location.origin);';
}

/// What the app does with the page's messages. Each one is optional: a page message nobody
/// handles is dropped.
class EmbedHandlers {
  const EmbedHandlers({
    this.ready,
    this.title,
    this.saveState,
    this.saveAs,
    this.openFile,
    this.copy,
    this.share,
    this.askAgent,
    this.external,
    this.previewLink,
    this.close,
    this.back,
    this.bar,
    this.open,
  });

  final void Function()? ready;
  final void Function(String name, String? kind, int? size)? title;
  final void Function(String state, String? error)? saveState;
  final void Function(String name, {String? url, String? data, String? mime})? saveAs;
  final void Function(String id, List<String> accept, bool multiple)? openFile;
  final void Function(String text)? copy;
  final void Function({String? title, String? text, String? url})? share;
  final void Function(String text, Map<String, Object?> ref)? askAgent;
  final void Function(Uri url)? external;

  /// A link an agent-made page inside wants to open: the app asks the person first (G42.2).
  final void Function(Uri url)? previewLink;
  final void Function()? close;
  final void Function(bool handled)? back;

  /// The Canvas's bar (G42.6): its own buttons, the agent's move, the signed link, downloadable.
  final void Function(EmbedBar bar)? bar;

  /// Something to open in another tab of the app's Canvas (G42.6).
  final void Function(String title, Map<String, dynamic> target)? open;
}

/// One of the Canvas's own buttons, drawn by the app (`EmbedAction`).
class EmbedAction {
  const EmbedAction({
    required this.id,
    required this.label,
    this.icon,
    this.on = false,
    this.disabled = false,
    this.primary = false,
    this.hint,
  });

  factory EmbedAction.fromJson(Map<String, Object?> m) => EmbedAction(
    id: m['id']! as String,
    label: m['label']! as String,
    icon: m['icon'] as String?,
    on: m['on'] == true,
    disabled: m['disabled'] == true,
    primary: m['primary'] == true,
    hint: m['hint'] as String?,
  );

  final String id;
  final String label;
  final String? icon;
  final bool on;
  final bool disabled;
  final bool primary;
  final String? hint;
}

/// The Canvas's bar as the page said it last (`bar`).
class EmbedBar {
  const EmbedBar({
    this.actions = const [],
    this.note,
    this.link,
    this.download = false,
    this.paste = false,
    this.readOnly = false,
  });

  factory EmbedBar.fromJson(Map<String, Object?> m) => EmbedBar(
    actions: [
      for (final a in m['actions']! as List)
        EmbedAction.fromJson((a as Map).cast<String, Object?>()),
    ],
    note: m['note'] as String?,
    link: m['link'] as String?,
    download: m['download'] == true,
    paste: m['paste'] == true,
    readOnly: m['readOnly'] == true,
  );

  final List<EmbedAction> actions;
  final String? note;

  /// The signed link of what is shown (a path of the server).
  final String? link;
  final bool download;

  /// The tab takes a picture from the system's clipboard (G42.7): «Paste a picture», Ctrl/Cmd+V.
  final bool paste;

  /// An archived project's file: only looked at (G42.7).
  final bool readOnly;
}

/// One page's bridge: its nonce, the page's messages to [handlers], the app's out through [run].
class EmbedBridge {
  EmbedBridge({required this.nonce, required this.handlers, required this.run});

  final String nonce;
  final EmbedHandlers handlers;

  /// Runs a script in the page (the web view's).
  final Future<void> Function(String script) run;

  /// A raw message from the page's channel; returns the message when it was taken.
  Map<String, Object?>? handle(String raw) {
    final m = readEmbedEnvelope(raw, nonce);
    if (m == null) return null;
    final h = handlers;
    switch (m['t']) {
      case 'ready':
        h.ready?.call();
      case 'title':
        h.title?.call(m['name']! as String, m['kind'] as String?, m['size'] as int?);
      case 'saveState':
        h.saveState?.call(m['state']! as String, m['error'] as String?);
      case 'saveAs':
        h.saveAs?.call(
          m['name']! as String,
          url: m['url'] as String?,
          data: m['data'] as String?,
          mime: m['mime'] as String?,
        );
      case 'openFile':
        h.openFile?.call(m['id']! as String, [
          ...(m['accept'] as List? ?? const []).cast<String>(),
        ], m['multiple'] == true);
      case 'copy':
        h.copy?.call(m['text']! as String);
      case 'share':
        h.share?.call(
          title: m['title'] as String?,
          text: m['text'] as String?,
          url: m['url'] as String?,
        );
      case 'askAgent':
        h.askAgent?.call(m['text']! as String, (m['ref']! as Map).cast<String, Object?>());
      case 'external':
        h.external?.call(Uri.parse(m['url']! as String));
      case 'previewLink':
        h.previewLink?.call(Uri.parse(m['url']! as String));
      case 'close':
        h.close?.call();
      case 'back':
        h.back?.call(m['handled'] == true);
      case 'bar':
        h.bar?.call(EmbedBar.fromJson(m));
      case 'open':
        h.open?.call(m['title']! as String, Map<String, dynamic>.from(m['target']! as Map));
    }
    return m;
  }

  Future<void> send(Map<String, Object?> m) => run(appMessageScript(m));

  Future<void> theme({required bool dark}) =>
      send({'t': 'theme', 'theme': dark ? 'dark' : 'light'});
  Future<void> lang(String lang) => send({'t': 'lang', 'lang': lang});
  Future<void> font(String family) => send({'t': 'font', 'family': family});
  Future<void> back() => send({'t': 'back'});
  Future<void> key(EmbedKey k) => send({'t': 'key', 'key': k.name});
  Future<void> files(List<Map<String, Object?>> files, {String? id}) =>
      send({'t': 'files', 'id': ?id, 'files': files});
  Future<void> paste({String? text, List<Map<String, Object?>>? files}) =>
      send({'t': 'paste', 'text': ?text, 'files': ?files});
  Future<void> action(String id) => send({'t': 'action', 'id': id});

  /// The app's Canvas tabs, and whether this page is the one in view (G42.6).
  Future<void> tabs({required bool visible, required List<Map<String, Object?>> tabs}) =>
      send({'t': 'tabs', 'visible': visible, 'tabs': tabs});
}

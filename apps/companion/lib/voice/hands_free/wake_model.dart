// Hands-free voice (G42.16): what the wake word needs on this device, brought once when the person
// asks for it (Settings › Voice, «Download the model», or switching the wake word on): on Windows
// and Linux the recogniser's library from alphacephei's release (checked against its SHA-256 before
// it is kept), then the language's small model from Rasgeth, which downloads it once for the page
// too (`POST /api/voice/wake-model`, a job with its bar) and hands it over as a `.tar.gz`
// (`/api/voice/wake-models/<file>`). Every step has its real bar: bytes, speed and time left.
// Kept under the app's own folder (`wake/`), so later starts find it without asking.
import 'dart:async';
import 'dart:io';

import 'package:archive/archive.dart' show TarDecoder, ZipDecoder;
import 'package:cryptography/cryptography.dart' show Sha256;
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';

import '../../api/client.dart';
import '../../api/settings_types.dart' show Progress;
import 'vosk.dart';
import 'wake.dart';

enum WakeStage {
  /// Nothing yet on this device.
  idle,

  /// Rasgeth is downloading the model for itself (its job's bar).
  server,

  /// The recogniser's library comes down to this computer.
  engine,

  /// The model comes down from Rasgeth to this device.
  model,

  /// Starting the recogniser.
  loading,
  ready,
  error,
}

/// A file from the web written to [out] as it arrives.
typedef WebFetch = Future<void> Function(
  Uri url,
  File out,
  void Function(int got, int? total) onProgress,
);

/// The files the recogniser starts from.
typedef WakeFiles = ({List<String> libs, String modelDir});

class WakeModelStore extends ChangeNotifier {
  WakeModelStore({required this.engine, Future<Directory> Function()? dir, WebFetch? fetch})
    : _dir = dir,
      _fetch = fetch ?? _httpFetch;

  final WakeEngine engine;
  final Future<Directory> Function()? _dir;
  final WebFetch _fetch;

  WakeStage stage = WakeStage.idle;
  Progress? progress;

  /// Why it stopped ([WakeStage.error]): a code the view says in words (`failed`, `broken`,
  /// `server`, `checksum`).
  String? error;

  /// What went wrong, for whoever helps (never shown as it is).
  Object? cause;

  bool _busy = false;
  bool get busy => _busy;

  /// The model's name for a language (the `.tar.gz` without its extension).
  static String modelName(WakeLang lang) =>
      wakeModelFiles[lang]!.replaceAll(RegExp(r'\.tar\.gz$'), '');

  Future<Directory> _root() async =>
      Directory('${(await (_dir ?? getApplicationSupportDirectory)()).path}/wake');

  void _set(WakeStage s, {Progress? p, String? err}) {
    stage = s;
    progress = p;
    error = err;
    notifyListeners();
  }

  void loading() => _set(WakeStage.loading);
  void ready() => _set(WakeStage.ready);
  void failed(String code) => _set(WakeStage.error, err: code);

  /// The files when they are all on this device already (null: not yet, or none here).
  Future<WakeFiles?> have(WakeLang lang) async {
    if (engine.source == null) return null;
    try {
      final root = await _root();
      final model = Directory('${root.path}/${modelName(lang)}');
      if (!File('${model.path}/am/final.mdl').existsSync()) return null;
      final libs = _libs(root);
      if (libs == null) return null;
      return (libs: libs, modelDir: model.path);
    } on Object {
      return null;
    }
  }

  /// The library's files: by name when the APK carries it, else under [root] once downloaded.
  List<String>? _libs(Directory root) {
    final e = engine.download;
    if (engine.source == 'bundled') return ['libvosk.so'];
    if (e == null) return null;
    final paths = [for (final l in e.libs) '${root.path}/${e.folder}/$l'];
    return paths.every((p) => File(p).existsSync()) ? paths : null;
  }

  /// Bytes still to download for [lang] (the library, and the model when [modelSize] is known).
  Future<int?> sizeToGet(WakeLang lang, int? modelSize) async {
    final root = await _root().catchError((_) => Directory(''));
    var n = 0;
    final e = engine.download;
    if (e != null && _libs(root) == null) n += e.size;
    if (!File('${root.path}/${modelName(lang)}/am/final.mdl').existsSync()) {
      if (modelSize == null) return null;
      n += modelSize;
    }
    return n;
  }

  /// Brings what is missing for [lang] (each step with its bar); null when it could not.
  Future<WakeFiles?> fetch(RedGiantClient c, WakeLang lang) async {
    if (_busy || engine.source == null) return null;
    _busy = true;
    try {
      final root = await _root();
      await root.create(recursive: true);
      final e = engine.download;
      if (e != null && _libs(root) == null) {
        _set(WakeStage.engine, p: Progress(done: 0, total: e.size.toDouble(), bps: 0));
        await _getEngine(root, e);
      }
      final name = modelName(lang);
      if (!File('${root.path}/$name/am/final.mdl').existsSync()) {
        final size = await _serverModel(c, lang);
        _set(WakeStage.model, p: Progress(done: 0, total: (size ?? 0).toDouble(), bps: 0));
        final part = File('${root.path}/$name.tar.gz.part');
        final timer = _Rate((p) => _set(WakeStage.model, p: p));
        await c.serverDownloadTo(
          '/api/voice/wake-models/${wakeModelFiles[lang]}',
          part,
          onProgress: timer.update,
        );
        await _unpackModel(part, root, name);
      }
      final files = await have(lang);
      if (files == null) throw const _WakeFail('broken');
      return files;
    } on _WakeFail catch (x) {
      failed(x.code);
      return null;
    } on Object catch (x) {
      cause = x;
      failed('failed');
      return null;
    } finally {
      _busy = false;
    }
  }

  /// Asks Rasgeth for the model and waits for its download; the model's size.
  Future<int?> _serverModel(RedGiantClient c, WakeLang lang) async {
    var state = await c.getJson('/api/voice/wake-model', {'lang': lang.name});
    if (state is Map && state['ready'] == true) return (state['size'] as num?)?.toInt();
    final started = await c.callJson('POST', '/api/voice/wake-model', {'lang': lang.name});
    var job = started is Map ? started['job'] : null;
    while (job is Map && job['state'] == 'running') {
      _set(WakeStage.server, p: _jobProgress(job));
      await Future<void>.delayed(const Duration(seconds: 1));
      job = await c.getJson('/api/jobs/${Uri.encodeComponent('${job['id']}')}');
    }
    if (job is Map && job['state'] != 'done') throw const _WakeFail('server');
    state = await c.getJson('/api/voice/wake-model', {'lang': lang.name});
    if (state is! Map || state['ready'] != true) throw const _WakeFail('server');
    return (state['size'] as num?)?.toInt();
  }

  static Progress? _jobProgress(Map<dynamic, dynamic> job) {
    final steps = job['steps'];
    if (steps is! List) return null;
    for (final s in steps.reversed) {
      final p = s is Map ? s['progress'] : null;
      if (p is Map) {
        final total = p['total'];
        return Progress(
          done: (p['done'] as num? ?? 0).toDouble(),
          total: total is num ? total.toDouble() : 0,
          bps: (p['rate'] as num? ?? 0).toDouble(),
          eta: (p['secondsLeft'] as num?)?.round(),
        );
      }
    }
    return null;
  }

  Future<void> _getEngine(Directory root, VoskEngine e) async {
    final zip = File('${root.path}/${e.folder}.zip.part');
    final rate = _Rate((p) => _set(WakeStage.engine, p: p), e.size);
    await _fetch(Uri.parse(e.url), zip, rate.update);
    final bytes = await zip.readAsBytes();
    final sum = await Sha256().hash(bytes);
    final hex = sum.bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
    if (hex != e.sha256) {
      await zip.delete().catchError((_) => zip);
      throw const _WakeFail('checksum');
    }
    final into = Directory('${root.path}/${e.folder}.part');
    if (into.existsSync()) await into.delete(recursive: true);
    for (final f in ZipDecoder().decodeBytes(bytes)) {
      final base = f.name.split('/').last;
      if (!f.isFile || !e.libs.contains(base)) continue;
      await File('${into.path}/$base').create(recursive: true);
      await File('${into.path}/$base').writeAsBytes(f.content, flush: true);
    }
    await zip.delete();
    final done = Directory('${root.path}/${e.folder}');
    if (done.existsSync()) await done.delete(recursive: true);
    await into.rename(done.path);
  }

  /// The `.tar.gz` (one folder on top, the model's name) unpacked next to the others.
  static Future<void> _unpackModel(File part, Directory root, String name) async {
    final tar = await compute(_untar, (part.path, '${root.path}/$name.part'));
    await part.delete();
    if (!tar) throw const _WakeFail('broken');
    final done = Directory('${root.path}/$name');
    if (done.existsSync()) await done.delete(recursive: true);
    await Directory('${root.path}/$name.part').rename(done.path);
  }

  /// Forgets what this device keeps (the model and the library).
  Future<void> forget() async {
    try {
      final root = await _root();
      if (root.existsSync()) await root.delete(recursive: true);
    } on Object {
      // Nothing to forget.
    }
    _set(WakeStage.idle);
  }
}

/// In an isolate: the archive's files under [into], without its top folder; false when it is
/// not a Vosk model. Names are kept inside [into].
bool _untar((String, String) a) {
  final (from, into) = a;
  final out = Directory(into);
  if (out.existsSync()) out.deleteSync(recursive: true);
  final files = TarDecoder().decodeBytes(gzip.decode(File(from).readAsBytesSync()));
  var model = false;
  for (final f in files) {
    final parts = f.name.split('/').where((p) => p.isNotEmpty).toList();
    if (parts.length < 2 || parts.any((p) => p == '..' || p == '.' || p.contains('\\'))) continue;
    final rel = parts.sublist(1).join('/');
    if (!f.isFile) {
      Directory('$into/$rel').createSync(recursive: true);
      continue;
    }
    File('$into/$rel')
      ..createSync(recursive: true)
      ..writeAsBytesSync(f.content, flush: true);
    if (rel == 'am/final.mdl') model = true;
  }
  return model;
}

class _WakeFail implements Exception {
  const _WakeFail(this.code);
  final String code;
}

/// Bytes so far into a [Progress] with speed and time left, at most five times a second.
class _Rate {
  _Rate(this.show, [this.known]);

  final void Function(Progress p) show;
  final int? known;
  final _clock = Stopwatch()..start();
  int _shown = -1000;

  void update(int got, int? total) {
    final now = _clock.elapsedMilliseconds;
    final all = total ?? known;
    if (now - _shown < 200 && (all == null || got < all)) return;
    _shown = now;
    final seconds = now / 1000;
    final bps = seconds > 0.5 ? got / seconds : 0.0;
    show(
      Progress(
        done: got.toDouble(),
        total: (all ?? 0).toDouble(),
        bps: bps,
        eta: bps > 0 && all != null ? ((all - got) / bps).ceil().clamp(0, 1 << 30) : null,
      ),
    );
  }
}

Future<void> _httpFetch(Uri url, File out, void Function(int got, int? total) onProgress) async {
  final http = HttpClient()..connectionTimeout = const Duration(seconds: 20);
  try {
    final req = await http.getUrl(url);
    final res = await req.close();
    if (res.statusCode != 200) throw HttpException('HTTP ${res.statusCode}', uri: url);
    final total = res.contentLength >= 0 ? res.contentLength : null;
    await out.parent.create(recursive: true);
    final sink = out.openWrite();
    var got = 0;
    try {
      await for (final chunk in res) {
        sink.add(chunk);
        got += chunk.length;
        onProgress(got, total);
      }
    } finally {
      await sink.close();
    }
  } finally {
    http.close();
  }
}

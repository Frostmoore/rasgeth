// The app on its own updates itself (G41.8b, the person on 2026-11-16: «a system that updates the
// companion apps automatically, at least on computers; on phones the stores do it»).
//
// 1. check: GitHub's newest release (or, when GitHub cannot be read, the connected RedGiant's
//    version: `chooseUpdate`), its SHA256SUMS-companion and the .sig, the signature checked with
//    the update key before anything in the list is read;
// 2. download: the package for this system, with its bytes, speed and time left, cancellable,
//    hashed as it arrives and kept only when the sha256 is the signed one;
// 3. apply («Update and restart»): where the person is is kept, a helper outside the folder
//    replaces it (swap.dart) and the app closes; the new version opens where the person was, or
//    the old one comes back.
// Never without a valid signature; never for a copy RedGiant carries; never on a phone.
import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../api/servers.dart';
import '../api/settings_types.dart';
import '../brand.dart';
import 'choice.dart';
import 'install.dart';
import 'signature.dart';
import 'swap.dart';

enum AppUpdateStage { idle, checking, upToDate, available, downloading, ready, applying, failed }

enum AppUpdateError {
  /// GitHub (or the download) could not be reached.
  network,

  /// The list's signature is missing or not valid: nothing is used.
  signature,

  /// The release does not list a package for this system.
  notListed,

  /// The downloaded file is not the signed one (deleted).
  checksum,

  /// The download could not be kept or unpacked.
  disk,

  /// The helper could not be started (nothing changed).
  swap,
}

/// The release the check found, with its signed sums.
class FoundRelease {
  const FoundRelease({
    required this.version,
    required this.asset,
    required this.url,
    required this.sha256,
    required this.size,
    required this.why,
  });

  final String version;
  final String asset;
  final Uri url;
  final String sha256;
  final int size;
  final UpdateWhy why;
}

/// Where the person was, given back to the version that opens next (read once, then deleted).
class ResumeState {
  const ResumeState({this.sessionId, this.view, this.full = false});

  final String? sessionId;
  final String? view;
  final bool full;

  Map<String, dynamic> toJson() => {
    'v': 1,
    if (sessionId != null) 'sessionId': sessionId,
    if (view != null) 'view': view,
    if (full) 'full': true,
  };

  static ResumeState? fromJson(Object? j) {
    if (j is! Map<String, dynamic> || j['v'] != 1) return null;
    final s = j['sessionId'];
    final v = j['view'];
    return ResumeState(
      sessionId: s is String && s.isNotEmpty && s.length < 200 ? s : null,
      view: v is String && v.length < 40 ? v : null,
      full: j['full'] == true,
    );
  }
}

const _skipPref = 'appUpdateSkip';
const _maxSmall = 64 * 1024;

class AppUpdater extends ChangeNotifier {
  AppUpdater({
    required this.spot,
    required this.current,
    required this.prefs,
    required this.folder,
    http.Client? client,
    this.serverVersion,
    DateTime Function()? now,
    Future<void> Function(SwapPlan plan, String folder)? swap,
    Future<String?> Function(String archive, String into)? unpack,
    void Function()? quit,
    int Function()? processId,
    UpdateKey? key,
    this.apiBase = 'https://api.github.com',
  }) : _client = client ?? http.Client(),
       _now = now ?? DateTime.now,
       _swap = swap ?? startSwap,
       _unpack = unpack ?? unpackLinux,
       _quit = quit ?? (() => exit(0)),
       _pid = processId ?? (() => pid),
       _key = key ?? UpdateKey.builtIn;

  /// The install this app replaces (null: it never updates itself).
  final InstallSpot? spot;

  /// This app's version (`kAppVersion`).
  final String current;
  final AppPrefs prefs;

  /// The folder for the downloads and the helper (outside the app's own folder).
  final Future<String> Function() folder;

  /// The connected RedGiant's version.
  final String? Function()? serverVersion;
  final String apiBase;

  final http.Client _client;
  final DateTime Function() _now;
  final Future<void> Function(SwapPlan, String) _swap;
  final Future<String?> Function(String, String) _unpack;
  final void Function() _quit;
  final int Function() _pid;
  final UpdateKey _key;

  AppUpdateStage stage = AppUpdateStage.idle;
  AppUpdateError? error;
  FoundRelease? found;
  Progress? progress;

  /// The version the helper reported at this start: updated to (from [updatedFrom]), or failed.
  String? updatedFrom;
  String? failedVersion;

  /// The file ready to apply (Windows: the installer; Linux: the unpacked bundle).
  String? _ready;
  StreamSubscription<List<int>>? _sub;
  Completer<void>? _download;

  /// The download in flight: cancelled by [cancel], done once its file is closed and cleaned
  /// (Windows cannot delete a file that is still open).
  _Run? _run;

  /// A download is running or still closing and cleaning its file.
  bool get busy => _run != null;

  /// Whether this app can update itself at all.
  bool get enabled => spot != null && parseVersion(current) != null;

  /// The window should be shown without the person asking (a new version found or downloaded).
  bool get wantsAttention =>
      stage == AppUpdateStage.available ||
      stage == AppUpdateStage.downloading ||
      stage == AppUpdateStage.ready;

  void _set(AppUpdateStage s, {AppUpdateError? err}) {
    stage = s;
    error = err;
    notifyListeners();
  }

  Future<Map<String, dynamic>?> _json(Uri u) async {
    final r = await _client
        .get(u, headers: {'accept': 'application/vnd.github+json', 'user-agent': kExeName})
        .timeout(const Duration(seconds: 20));
    if (r.statusCode != 200 || r.bodyBytes.length > 2 * 1024 * 1024) return null;
    final j = jsonDecode(utf8.decode(r.bodyBytes));
    return j is Map<String, dynamic> ? j : null;
  }

  Future<List<int>?> _small(Uri u) async {
    final r = await _client
        .get(u, headers: {'user-agent': kExeName})
        .timeout(const Duration(seconds: 20));
    if (r.statusCode != 200 || r.bodyBytes.length > _maxSmall) return null;
    return r.bodyBytes;
  }

  /// Looks for a newer version. [asked]: from the menu (a skipped version is offered again).
  Future<void> check({bool asked = false}) async {
    if (!enabled) return;
    if (stage == AppUpdateStage.checking ||
        stage == AppUpdateStage.downloading ||
        stage == AppUpdateStage.applying) {
      return;
    }
    if (stage == AppUpdateStage.ready && !asked) return;
    _set(AppUpdateStage.checking);
    final skipped = await prefs.get(_skipPref);
    Map<String, dynamic>? latest;
    try {
      latest = await _json(Uri.parse('$apiBase/repos/$kReleaseRepo/releases/latest'));
    } on Object {
      latest = null;
    }
    final choice = chooseUpdate(
      current: current,
      latest: latest?['tag_name'] as String?,
      server: serverVersion?.call(),
      skipped: skipped,
      asked: asked,
    );
    if (!choice.offered) {
      if (choice.why == UpdateWhy.unknown)
        return _set(AppUpdateStage.failed, err: AppUpdateError.network);
      return _set(choice.why == UpdateWhy.upToDate ? AppUpdateStage.upToDate : AppUpdateStage.idle);
    }
    var release = latest;
    if (choice.why == UpdateWhy.server) {
      try {
        release = await _json(
          Uri.parse('$apiBase/repos/$kReleaseRepo/releases/tags/v${choice.version}'),
        );
      } on Object {
        release = null;
      }
      if (release == null) return _set(AppUpdateStage.failed, err: AppUpdateError.network);
    }
    final assets = <String, Map<String, dynamic>>{
      for (final a in (release!['assets'] as List<dynamic>? ?? const []))
        if (a is Map<String, dynamic> && a['name'] is String) a['name'] as String: a,
    };
    Uri? urlOf(String name) {
      final u = assets[name]?['browser_download_url'];
      if (u is! String) return null;
      final parsed = Uri.tryParse(u);
      return parsed != null && parsed.scheme == 'https' ? parsed : null;
    }

    final sumsUrl = urlOf(kSumsAsset);
    final sigUrl = urlOf('$kSumsAsset.sig');
    if (sumsUrl == null || sigUrl == null) {
      return _set(AppUpdateStage.failed, err: AppUpdateError.signature);
    }
    List<int>? sums;
    List<int>? sig;
    try {
      sums = await _small(sumsUrl);
      sig = await _small(sigUrl);
    } on Object {
      return _set(AppUpdateStage.failed, err: AppUpdateError.network);
    }
    if (sums == null || sig == null)
      return _set(AppUpdateStage.failed, err: AppUpdateError.network);
    final String sigText;
    try {
      sigText = ascii.decode(sig);
    } on FormatException {
      return _set(AppUpdateStage.failed, err: AppUpdateError.signature);
    }
    // The signature first: an unsigned or badly signed list is never read.
    final listed = signedSums(sums, sigText, key: _key);
    if (listed == null) return _set(AppUpdateStage.failed, err: AppUpdateError.signature);
    final name = assetFor(spot!.system, listed.keys.toList());
    final url = name == null ? null : urlOf(name);
    if (name == null || url == null)
      return _set(AppUpdateStage.failed, err: AppUpdateError.notListed);
    final size = assets[name]?['size'];
    found = FoundRelease(
      version: choice.version!,
      asset: name,
      url: url,
      sha256: listed[name]!,
      size: size is int ? size : 0,
      why: choice.why,
    );
    _ready = null;
    _set(AppUpdateStage.available);
  }

  /// Downloads [found], hashed as it arrives; [cancel] stops it and deletes the part.
  Future<void> download() async {
    final f = found;
    if (f == null || stage == AppUpdateStage.downloading) return;
    final run = _Run();
    final previous = _run;
    _run = run;
    final dir = Directory('${await folder()}${Platform.pathSeparator}${f.version}');
    final sep = Platform.pathSeparator;
    final part = File('${dir.path}$sep${f.asset}.part');
    final file = File('${dir.path}$sep${f.asset}');
    progress = Progress(done: 0, total: f.size.toDouble(), bps: 0);
    _set(AppUpdateStage.downloading);
    IOSink? out;
    try {
      // A cancelled download still closing its part: wait, it deletes the same file.
      await previous?.done.future;
      await dir.create(recursive: true);
      // Downloaded before (the person chose «Later»): used again only with the signed sha256.
      if (await file.exists()) {
        final h = Sha256Sink();
        await file.openRead().forEach(h.add);
        if (run.cancelled) return;
        if (h.close() == f.sha256) return await _prepare(file, dir, await file.length());
        await file.delete();
      }
      final req = http.Request('GET', f.url)..headers['user-agent'] = kExeName;
      final res = await _client.send(req).timeout(const Duration(seconds: 30));
      if (run.cancelled) {
        unawaited(res.stream.listen(null).cancel());
        return;
      }
      if (res.statusCode != 200) throw const HttpException('status');
      final total = (res.contentLength ?? 0) > 0
          ? res.contentLength!.toDouble()
          : f.size.toDouble();
      out = part.openWrite();
      final hash = Sha256Sink();
      var done = 0;
      final started = _now();
      // The speed over the last few seconds, as the page's bar.
      final window = <(DateTime, int)>[(started, 0)];
      var shown = started;
      final finished = Completer<void>();
      _download = finished;
      _sub = res.stream.listen(
        (chunk) {
          hash.add(chunk);
          out!.add(chunk);
          done += chunk.length;
          final t = _now();
          window.add((t, done));
          while (window.length > 2 && t.difference(window.first.$1).inMilliseconds > 3000) {
            window.removeAt(0);
          }
          if (t.difference(shown).inMilliseconds >= 100 || done == total) {
            shown = t;
            final span = t.difference(window.first.$1).inMilliseconds / 1000;
            final bps = span > 0 ? (done - window.first.$2) / span : 0.0;
            final left = total - done;
            progress = Progress(
              done: done.toDouble(),
              total: total,
              bps: bps,
              eta: bps > 0 && left > 0 ? (left / bps).ceil() : null,
            );
            notifyListeners();
          }
        },
        onError: (Object e) {
          if (!finished.isCompleted) finished.completeError(e);
        },
        onDone: () {
          if (!finished.isCompleted) finished.complete();
        },
        cancelOnError: true,
      );
      await finished.future;
      _sub = null;
      await out.close();
      out = null;
      if (run.cancelled) return await _delete(part);
      if (hash.close() != f.sha256) {
        await _delete(part);
        return _set(AppUpdateStage.failed, err: AppUpdateError.checksum);
      }
      await part.rename(file.path);
      await _prepare(file, dir, done);
    } on Object {
      await _sub?.cancel();
      _sub = null;
      await out?.close().catchError((Object _) {});
      await _delete(part);
      if (run.cancelled) return;
      _set(AppUpdateStage.failed, err: AppUpdateError.network);
    } finally {
      _download = null;
      run.done.complete();
      if (identical(_run, run)) _run = null;
    }
  }

  Future<void> _prepare(File file, Directory dir, int size) async {
    progress = Progress(done: size.toDouble(), total: size.toDouble(), bps: 0);
    if (spot!.system == 'linux') {
      final bundle = await _unpack(file.path, '${dir.path}${Platform.pathSeparator}unpacked');
      if (bundle == null) return _set(AppUpdateStage.failed, err: AppUpdateError.disk);
      _ready = bundle;
    } else {
      _ready = file.path;
    }
    _set(AppUpdateStage.ready);
  }

  /// Stops the download; the part is deleted and the version stays offered.
  Future<void> cancel() async {
    if (stage != AppUpdateStage.downloading) return;
    final run = _run;
    run?.cancelled = true;
    await _sub?.cancel();
    _sub = null;
    final d = _download;
    if (d != null && !d.isCompleted) d.complete();
    progress = null;
    _set(AppUpdateStage.available);
    // The download closes its part and deletes it (in that order: Windows keeps open files).
    await run?.done.future;
  }

  /// «Skip this version»: not offered again until a newer one, or the person asks.
  Future<void> skip() async {
    final f = found;
    if (f == null) return;
    if (stage == AppUpdateStage.downloading) await cancel();
    await prefs.set(_skipPref, f.version);
    found = null;
    _set(AppUpdateStage.idle);
  }

  /// «Update and restart»: where the person is ([resume]), the helper, then the app closes, only
  /// once the helper runs (a helper that does not start leaves the app open, `failed`).
  Future<void> apply(ResumeState resume) async {
    final f = found;
    final ready = _ready;
    final s = spot;
    if (f == null || ready == null || s == null || stage != AppUpdateStage.ready) return;
    _set(AppUpdateStage.applying);
    final base = await folder();
    final sep = Platform.pathSeparator;
    try {
      await File('$base${sep}resume.json').writeAsString(jsonEncode(resume.toJson()));
      await _swap(
        SwapPlan(
          system: s.system,
          pid: _pid(),
          dir: s.dir,
          exe: s.exe,
          fromVersion: current,
          toVersion: f.version,
          package: ready,
          marker: '$base${sep}started-${f.version}',
          log: '$base${sep}update.log',
          alive: '$base${sep}helper-alive',
        ),
        base,
      );
    } on Object {
      return _set(AppUpdateStage.failed, err: AppUpdateError.swap);
    }
    _quit();
  }

  /// At start: the helper's arguments. The new version writes its marker (its window is up) and
  /// says it was updated; the old one, back, says which version did not start and skips it.
  Future<void> started(UpdateStart s) async {
    final m = s.marker;
    if (m != null) {
      try {
        await File(m).writeAsString('ok');
      } on FileSystemException {
        // The helper waits for it; without it the old version comes back, which is safe.
      }
    }
    updatedFrom = s.updatedFrom;
    failedVersion = parseVersion(s.failed) == null ? null : s.failed;
    if (failedVersion != null) await prefs.set(_skipPref, failedVersion);
    if (updatedFrom != null || failedVersion != null) notifyListeners();
    if (updatedFrom != null) unawaited(_clean());
  }

  /// The resume left by the version that closed for the update (deleted once read).
  Future<ResumeState?> takeResume() async {
    final f = File('${await folder()}${Platform.pathSeparator}resume.json');
    try {
      if (!await f.exists() || await f.length() > 4096) return null;
      final text = await f.readAsString();
      await f.delete();
      return ResumeState.fromJson(jsonDecode(text));
    } on Object {
      return null;
    }
  }

  void dismissNotice() {
    updatedFrom = null;
    failedVersion = null;
    notifyListeners();
  }

  /// Old downloads (after a good update).
  Future<void> _clean() async {
    try {
      final d = Directory(await folder());
      if (!await d.exists()) return;
      await for (final e in d.list()) {
        if (e is Directory && parseVersion(e.path.split(Platform.pathSeparator).last) != null) {
          await e.delete(recursive: true);
        }
      }
    } on Object {
      // Nothing that matters: the next update cleans again.
    }
  }

  static Future<void> _delete(File f) async {
    try {
      if (await f.exists()) await f.delete();
    } on FileSystemException {
      // Left for the next try.
    }
  }

  /// Checks now (after a short wait at start) and then every [every].
  Timer? _timer;
  void startChecking({
    Duration first = const Duration(seconds: 20),
    Duration every = const Duration(hours: 6),
  }) {
    if (!enabled || _timer != null) return;
    _timer = Timer(first, () {
      unawaited(_auto());
      _timer = Timer.periodic(every, (_) => unawaited(_auto()));
    });
  }

  Future<void> _auto() async {
    await check();
    // Found: downloaded at once, then the person is asked.
    if (stage == AppUpdateStage.available) await download();
  }

  @override
  void dispose() {
    _timer?.cancel();
    unawaited(_sub?.cancel());
    super.dispose();
  }
}

/// Unpacks the Linux archive with the system's tar (no shell) and finds its bundle.
Future<String?> unpackLinux(String archive, String into) async {
  final d = Directory(into);
  if (await d.exists()) await d.delete(recursive: true);
  await d.create(recursive: true);
  final r = await Process.run('tar', ['-xzf', archive, '-C', into, '--no-same-owner']);
  if (r.exitCode != 0) return null;
  return findLinuxBundle(into);
}

class _Run {
  bool cancelled = false;
  final done = Completer<void>();
}

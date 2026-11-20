// Saving a file from the chat (3.8.11), as the page's «Save» on a file card: a file an agent sent
// (`send_file`) or an attachment of a message saved in the workspace. The same route as the page
// (`GET /api/files/raw`), then the system's own «Save as»: a window on a computer, the system's
// picker on a phone (Android's documents, Downloads included; iOS's Files). A file over
// [kDownloadBarFrom] shows a bar under the chat while it comes: how much, how fast, how long.
import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';

import '../../api/transport.dart' show DownloadCancel, DownloadCancelled;
import '../../api/types.dart';
import '../../app_state.dart';
import '../../l10n/app_localizations.dart';
import '../../theme/colors.dart';

/// Tests set this: where the bytes go instead of the system's «Save as» (true: saved).
@visibleForTesting
Future<bool> Function(String name, Uint8List bytes)? debugSaveBytes;

/// From this size the download shows its bar.
const kDownloadBarFrom = 1024 * 1024;

Future<bool> _saveWithSystem(String name, Uint8List bytes) async =>
    await FilePicker.saveFile(fileName: name, bytes: bytes) != null;

/// How a download goes: bytes arrived, the size (null: not said), speed and time left.
class DownloadProgress extends ChangeNotifier {
  DownloadProgress({this.total, DateTime Function()? now}) : _now = now ?? DateTime.now {
    _start = _now();
  }

  final DateTime Function() _now;
  late final DateTime _start;
  int got = 0;
  int? total;

  void update(int got, int? total) {
    this.got = got;
    if (total != null && total > 0) this.total = total;
    notifyListeners();
  }

  /// 0..1, or null while the size is not known.
  double? get fraction => total == null ? null : (got / total!).clamp(0.0, 1.0).toDouble();

  /// Bytes a second so far.
  double get perSecond {
    final ms = _now().difference(_start).inMilliseconds;
    return ms <= 0 ? 0 : got * 1000 / ms;
  }

  /// What remains at this speed (null: size or speed not known yet).
  Duration? get left {
    final t = total;
    final v = perSecond;
    if (t == null || v <= 0) return null;
    return Duration(milliseconds: ((t - got).clamp(0, t) * 1000 / v).round());
  }
}

/// «12 s», «3 min», «1 h 5 min»: a short time left, the same in Italian and English.
String shortDuration(Duration d) {
  final s = d.inSeconds;
  if (s < 60) return '${s < 1 ? 1 : s} s';
  if (s < 3600) return '${(s / 60).ceil()} min';
  return '${d.inHours} h ${d.inMinutes.remainder(60)} min';
}

/// «3,1 MB» in Italian, «3.1 MB» in English.
String byteWords(int n, String lang) {
  final String text;
  if (n < 1024) {
    text = '$n B';
  } else if (n < 1048576) {
    text = '${(n / 1024).round()} KB';
  } else if (n < 1073741824) {
    text = '${(n / 1048576).toStringAsFixed(1)} MB';
  } else {
    text = '${(n / 1073741824).toStringAsFixed(2)} GB';
  }
  return lang == 'it' ? text.replaceAll('.', ',') : text;
}

/// Downloads [path] of [scope] and offers it to the system's «Save as» under [name]; [size] (when
/// known) decides the bar at once.
Future<void> saveChatFile(
  BuildContext context, {
  required String scope,
  required String path,
  required String name,
  int size = 0,
}) async {
  final app = AppScope.read(context);
  final l = AppLocalizations.of(context);
  final client = app.client;
  final messenger = ScaffoldMessenger.maybeOf(context);
  if (client == null) return;
  final progress = DownloadProgress(total: size > 0 ? size : null);
  ScaffoldFeatureController<SnackBar, SnackBarClosedReason>? bar;
  void showBar() {
    if (bar != null || messenger == null) return;
    bar = messenger.showSnackBar(
      SnackBar(
        duration: const Duration(days: 1),
        content: DownloadBar(name: name, progress: progress),
      ),
    );
  }

  if ((progress.total ?? 0) >= kDownloadBarFrom) showBar();
  try {
    final bytes = await client.fileDownload(
      scope,
      path,
      onProgress: (got, total) {
        progress.update(got, total);
        if ((progress.total ?? got) >= kDownloadBarFrom) showBar();
      },
    );
    bar?.close();
    final saved = await (debugSaveBytes ?? _saveWithSystem)(name, bytes);
    if (saved) messenger?.showSnackBar(SnackBar(content: Text(l.chatFileSaved(name))));
  } on Object {
    // The server refused (ApiException), or the system's window could not open (a picker that
    // failed, no portal on this Linux).
    bar?.close();
    messenger?.showSnackBar(SnackBar(content: Text(l.chatFileDownloadFailed(name))));
  } finally {
    progress.dispose();
  }
}

/// The bar of a download under way: its name, the bar, how much of how much, speed, time left.
class DownloadBar extends StatelessWidget {
  const DownloadBar({super.key, required this.name, required this.progress, this.onCancel});

  final String name;
  final DownloadProgress progress;

  /// «Annulla» beside the percentage (3.10, a «Save as…» written to disk as it comes).
  final VoidCallback? onCancel;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final c = RgColors.of(context);
    final lang = Localizations.localeOf(context).languageCode;
    return ListenableBuilder(
      listenable: progress,
      builder: (context, _) {
        final p = progress;
        final f = p.fraction;
        final speed = byteWords(p.perSecond.round(), lang);
        final left = p.left;
        final words = p.total == null
            ? l.chatFileDownloadSoFar(byteWords(p.got, lang), speed)
            : l.chatFileDownloadOf(
                byteWords(p.got, lang),
                byteWords(p.total!, lang),
                speed,
                left == null ? '…' : shortDuration(left),
              );
        return Column(
          key: const Key('download-progress'),
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    l.chatFileDownloading(name),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (f != null) Text('${(f * 100).floor()}%'),
                if (onCancel != null) ...[
                  const SizedBox(width: 8),
                  TextButton(
                    key: const Key('download-cancel'),
                    onPressed: onCancel,
                    child: Text(l.cancel),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 6),
            ClipRRect(
              borderRadius: BorderRadius.circular(3),
              child: LinearProgressIndicator(
                value: f,
                minHeight: 5,
                color: c.accent,
                backgroundColor: c.line,
              ),
            ),
            const SizedBox(height: 4),
            Text(words, key: const Key('download-words'), style: const TextStyle(fontSize: 12.5)),
          ],
        );
      },
    );
  }
}

// ---- «Save as…» written to disk as it comes (3.10) ----------------------------------------------

/// Tests set this: the path a computer's «Save as» window gives (null: the person closed it).
@visibleForTesting
Future<String?> Function(String name)? debugPickSavePath;

/// Tests set this: what a phone's save gets, the downloaded file (true: saved).
@visibleForTesting
Future<bool> Function(String name, File file)? debugPhoneSave;

/// The biggest file a phone hands to the system's save: file_picker 13 takes the bytes there
/// (Android's documents, iOS's Files), so the whole file is read once at the end. A bigger one is
/// said, never loaded.
const kPhoneSaveMax = 512 * 1024 * 1024;

/// A computer's «Save as» window: its path. The window writes the name empty first (file_picker
/// needs bytes); the download replaces it.
Future<String?> _pickSavePath(String name) async {
  final u = await FilePicker.saveFile(fileName: name, bytes: Uint8List(0));
  return u?.toFilePath();
}

/// Where the download goes while it comes: beside the destination (one rename at the end, the
/// same disk), else the system's temporary folder (a sandbox that only gives the chosen file).
Future<File> _partBeside(String dest, String name) async {
  final beside = File('${File(dest).parent.path}${Platform.pathSeparator}.$name.rgpart');
  try {
    await beside.writeAsBytes(const [], flush: true);
    return beside;
  } on FileSystemException {
    return _tempPart(name);
  }
}

/// Tests set this: the temporary folder (no path_provider in a widget test).
@visibleForTesting
Directory? debugSaveTempDir;

Future<File> _tempPart(String name) async {
  final dir = debugSaveTempDir ?? await getTemporaryDirectory();
  final at = DateTime.now().microsecondsSinceEpoch;
  return File('${dir.path}${Platform.pathSeparator}rg-save-$at-$name');
}

/// The part becomes the destination: a rename, or a copy where the two are on different disks.
Future<void> _moveInto(File part, String dest) async {
  try {
    await part.rename(dest);
  } on FileSystemException {
    await part.copy(dest);
    await part.delete();
  }
}

Future<bool> _phoneSave(String name, File file) async =>
    await FilePicker.saveFile(fileName: name, bytes: await file.readAsBytes()) != null;

/// «Save as…» of a link of this server (3.10: the finished video, the XML for Resolve), written to
/// disk as it comes, never whole in memory: on a computer the system's window first, then the
/// download into a part beside the destination and a rename; on a phone into the app's temporary
/// folder, then the system's save. The bar says how much, how fast and how long, with «Annulla».
Future<void> saveServerLink(
  BuildContext context, {
  required String link,
  required String name,
  int size = 0,
}) async {
  final app = AppScope.read(context);
  final l = AppLocalizations.of(context);
  final lang = Localizations.localeOf(context).languageCode;
  final client = app.client;
  final messenger = ScaffoldMessenger.maybeOf(context);
  if (client == null) return;
  final phone = app.platform == DevicePlatform.android || app.platform == DevicePlatform.ios;
  String? dest;
  if (!phone) {
    try {
      dest = await (debugPickSavePath ?? _pickSavePath)(name);
    } on Object {
      messenger?.showSnackBar(SnackBar(content: Text(l.chatFileDownloadFailed(name))));
      return;
    }
    if (dest == null) return;
  }
  final progress = DownloadProgress(total: size > 0 ? size : null);
  final cancel = DownloadCancel();
  final bar = messenger?.showSnackBar(
    SnackBar(
      duration: const Duration(days: 1),
      content: DownloadBar(name: name, progress: progress, onCancel: cancel.cancel),
    ),
  );
  File? part;
  try {
    part = dest != null ? await _partBeside(dest, name) : await _tempPart(name);
    await client.serverDownloadTo(
      link,
      part,
      cancel: cancel,
      onProgress: (got, total) => progress.update(got, total),
    );
    bar?.close();
    var saved = true;
    if (dest != null) {
      await _moveInto(part, dest);
      part = null;
    } else {
      final got = await part.length();
      if (got > kPhoneSaveMax) {
        messenger?.showSnackBar(
          SnackBar(content: Text(l.saveTooBigPhone(name, byteWords(got, lang)))),
        );
        saved = false;
      } else {
        saved = await (debugPhoneSave ?? _phoneSave)(name, part);
      }
    }
    if (saved) messenger?.showSnackBar(SnackBar(content: Text(l.chatFileSaved(name))));
  } on DownloadCancelled {
    bar?.close();
    await _dropEmpty(dest);
    messenger?.showSnackBar(SnackBar(content: Text(l.saveCancelled(name))));
  } on Object {
    bar?.close();
    await _dropEmpty(dest);
    messenger?.showSnackBar(SnackBar(content: Text(l.chatFileDownloadFailed(name))));
  } finally {
    final left = part;
    if (left != null) {
      try {
        if (await left.exists()) await left.delete();
      } on FileSystemException {
        // A part the system holds: the temporary folder empties itself.
      }
    }
    progress.dispose();
  }
}

/// The empty file the «Save as» window wrote before a download that did not finish.
Future<void> _dropEmpty(String? dest) async {
  if (dest == null) return;
  final f = File(dest);
  try {
    if (await f.exists() && await f.length() == 0) await f.delete();
  } on FileSystemException {
    // Left as it is.
  }
}

// Saving a file from the chat (3.8.11), as the page's «Save» on a file card: a file an agent sent
// (`send_file`) or an attachment of a message saved in the workspace. The same route as the page
// (`GET /api/files/raw`), then the system's own «Save as»: a window on a computer, the system's
// picker on a phone (Android's documents, Downloads included; iOS's Files). A file over
// [kDownloadBarFrom] shows a bar under the chat while it comes: how much, how fast, how long.
import 'dart:async';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

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
  const DownloadBar({super.key, required this.name, required this.progress});

  final String name;
  final DownloadProgress progress;

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

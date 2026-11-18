// The window of the app's own update (G41.8b): what the updater does now, in the person's words;
// the download with its bar, bytes, speed and time left (cancellable); «Update and restart» once
// the signed file is here. It opens by itself when a new version is found, and from the Help menu.
import 'dart:async';

import 'package:flutter/material.dart';

import '../app_state.dart';
import '../l10n/app_localizations.dart';
import '../screens/server_settings_screen.dart' show progressText;
import '../theme/colors.dart';
import '../ui/dialogs.dart';
import '../ui/icons.dart';
import '../brand.dart';
import 'choice.dart';
import 'updater.dart';

bool _open = false;

/// Opens the window (once at a time). [asked]: from the menu, so it checks again.
Future<void> openAppUpdateWindow(
  BuildContext context,
  AppUpdater u, {
  bool asked = false,
  ResumeState Function()? resume,
}) async {
  if (_open) return;
  _open = true;
  if (asked) unawaited(u.check(asked: true));
  try {
    await showRgWindow<void>(
      context: context,
      builder: (_) => AppUpdateWindow(updater: u, resume: resume),
    );
  } finally {
    _open = false;
  }
}

class AppUpdateWindow extends StatelessWidget {
  const AppUpdateWindow({super.key, required this.updater, this.resume});

  final AppUpdater updater;
  final ResumeState Function()? resume;

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: updater,
    builder: (context, _) {
      final l = AppLocalizations.of(context);
      final c = RgColors.of(context);
      final u = updater;
      final f = u.found;
      void close() => Navigator.of(context).pop();
      final body = <Widget>[];
      final actions = <Widget>[];
      Widget text(String s, {Key? key, Color? color}) => Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: Text(
          s,
          key: key,
          style: TextStyle(fontSize: 14, height: 1.4, color: color),
        ),
      );
      Widget bar(double? value) => Padding(
        padding: const EdgeInsets.only(top: 4, bottom: 8),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: LinearProgressIndicator(
            key: const Key('app-update-bar'),
            value: value,
            minHeight: 8,
            backgroundColor: c.line,
            color: c.accent,
          ),
        ),
      );
      TextButton plain(String key, String label, VoidCallback run) =>
          TextButton(key: Key(key), onPressed: run, child: Text(label));
      FilledButton main(String key, String label, VoidCallback run) =>
          FilledButton(key: Key(key), onPressed: run, child: Text(label));

      final notice = u.updatedFrom != null
          ? l.appUpdDone(kAppName, u.current, u.updatedFrom!)
          : u.failedVersion != null
          ? l.appUpdWentBack(u.failedVersion!, kAppName, u.current)
          : null;
      if (notice != null && !u.wantsAttention && u.stage != AppUpdateStage.checking) {
        body.add(text(notice, key: const Key('app-update-notice')));
        actions.add(
          main('app-update-ok', l.appUpdClose, () {
            u.dismissNotice();
            close();
          }),
        );
      } else if (!u.enabled) {
        body.add(text(parseVersion(u.current) == null ? l.appUpdDev : l.appUpdCarried(kAppName)));
        actions.add(main('app-update-close', l.appUpdClose, close));
      } else {
        switch (u.stage) {
          case AppUpdateStage.idle:
          case AppUpdateStage.checking:
            body
              ..add(text(l.appUpdChecking))
              ..add(bar(null));
            actions.add(plain('app-update-close', l.appUpdClose, close));
          case AppUpdateStage.upToDate:
            body.add(text(l.appUpdUpToDate(kAppName, u.current)));
            actions.add(main('app-update-close', l.appUpdClose, close));
          case AppUpdateStage.available:
            body.add(text(l.appUpdAvailable(f!.version, u.current)));
            if (f.why == UpdateWhy.server) body.add(text(l.appUpdFromServer, color: c.dim));
            actions
              ..add(
                plain('app-update-skip', l.appUpdSkip, () {
                  unawaited(u.skip());
                  close();
                }),
              )
              ..add(plain('app-update-later', l.appUpdLater, close))
              ..add(main('app-update-download', l.appUpdDownload, () => unawaited(u.download())));
          case AppUpdateStage.downloading:
            final p = u.progress;
            body
              ..add(
                Text(
                  l.appUpdDownloading(f!.version),
                  style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
                ),
              )
              ..add(const SizedBox(height: 10))
              ..add(bar(p != null && p.total > 0 ? (p.done / p.total).clamp(0.0, 1.0) : null))
              ..add(
                Text(
                  p == null ? '' : progressText(l, p),
                  key: const Key('app-update-bar-text'),
                  style: TextStyle(
                    color: c.dim,
                    fontSize: 13,
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                ),
              );
            actions
              ..add(plain('app-update-cancel', l.cancel, () => unawaited(u.cancel())))
              ..add(plain('app-update-hide', l.appUpdHide, close));
          case AppUpdateStage.ready:
            body
              ..add(text(l.appUpdReady(f!.version, kAppName)))
              ..add(
                Row(
                  children: [
                    RgIcon(RgIcons.shield, size: 16, color: c.ok),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(l.appUpdVerified, style: TextStyle(color: c.dim, fontSize: 13)),
                    ),
                  ],
                ),
              );
            actions
              ..add(plain('app-update-later', l.appUpdLater, close))
              ..add(
                main(
                  'app-update-apply',
                  l.appUpdRestart,
                  () => unawaited(u.apply(resume?.call() ?? const ResumeState())),
                ),
              );
          case AppUpdateStage.applying:
            body
              ..add(text(l.appUpdApplying(kAppName)))
              ..add(bar(null));
          case AppUpdateStage.failed:
            body.add(
              text(_errorText(l, u.error), key: const Key('app-update-error'), color: c.err),
            );
            actions
              ..add(plain('app-update-close', l.appUpdClose, close))
              ..add(main('app-update-retry', l.appUpdRetry, () => unawaited(u.check(asked: true))));
        }
      }
      return AlertDialog(
        key: const Key('app-update-window'),
        title: Row(
          children: [
            RgIcon(RgIcons.download, size: 20, color: c.accent),
            const SizedBox(width: 10),
            Expanded(child: Text(l.appUpdTitle(kAppName))),
          ],
        ),
        content: SizedBox(
          width: 460,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: body,
          ),
        ),
        actions: actions,
      );
    },
  );
}

String _errorText(AppLocalizations l, AppUpdateError? e) => switch (e) {
  AppUpdateError.signature => l.appUpdErrSignature,
  AppUpdateError.notListed => l.appUpdErrNotListed(kAppName),
  AppUpdateError.checksum => l.appUpdErrChecksum,
  AppUpdateError.disk => l.appUpdErrDisk,
  AppUpdateError.swap => l.appUpdErrSwap,
  AppUpdateError.network || null => l.appUpdErrNetwork,
};

/// Opens the window by itself: a new version found or downloaded (once per version), and the
/// helper's word after an update (done, or gone back).
class AppUpdateWatcher extends StatefulWidget {
  const AppUpdateWatcher({super.key, required this.child});

  final Widget child;

  @override
  State<AppUpdateWatcher> createState() => _AppUpdateWatcherState();
}

class _AppUpdateWatcherState extends State<AppUpdateWatcher> {
  AppUpdater? _u;
  final _shown = <String>{};

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final u = AppScope.read(context).appUpdater;
    if (u == _u) return;
    _u?.removeListener(_changed);
    _u = u?..addListener(_changed);
    WidgetsBinding.instance.addPostFrameCallback((_) => _changed());
  }

  @override
  void dispose() {
    _u?.removeListener(_changed);
    super.dispose();
  }

  void _changed() {
    final u = _u;
    if (u == null || !mounted || _open) return;
    final String? why;
    if (u.updatedFrom != null || u.failedVersion != null) {
      why = 'notice:${u.updatedFrom}:${u.failedVersion}';
    } else if (u.wantsAttention && u.found != null) {
      why = 'found:${u.found!.version}:${u.stage == AppUpdateStage.ready}';
    } else {
      why = null;
    }
    if (why == null || !_shown.add(why)) return;
    // A version still downloading shows once; once ready it asks again.
    if (u.stage == AppUpdateStage.downloading) _shown.add('found:${u.found!.version}:false');
    final app = AppScope.read(context);
    unawaited(openAppUpdateWindow(context, u, resume: app.resumeNow));
  }

  @override
  Widget build(BuildContext context) => widget.child;
}

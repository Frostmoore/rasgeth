// The updater made at start (G41.8b), on the computers that have an app on its own: Windows and
// Linux. macOS's app comes only inside RedGiant.app (updated with it); phones use their stores.
import 'dart:io';

import 'package:path_provider/path_provider.dart';

import '../app_state.dart';
import 'choice.dart';
import 'install.dart';
import 'updater.dart';

/// The updater for this app (disabled for RedGiant's copy and for builds from the sources), with
/// where the person was before an update, or null where the app never updates itself.
Future<AppUpdater?> prepareAppUpdater(AppController app, List<String> args) async {
  if (!Platform.isWindows && !Platform.isLinux) return null;
  final spot = standaloneSpot(
    system: Platform.operatingSystem,
    exePath: Platform.resolvedExecutable,
    env: Platform.environment,
    exists: (p) => File(p).existsSync(),
  );
  final u = AppUpdater(
    spot: spot,
    current: kAppVersion,
    prefs: app.prefs,
    folder: () async {
      final d = await getApplicationSupportDirectory();
      return '${d.path}${Platform.pathSeparator}app-update';
    },
    serverVersion: () => app.hello?.version,
  );
  app.appUpdater = u;
  app.resume = await u.takeResume();
  return u;
}

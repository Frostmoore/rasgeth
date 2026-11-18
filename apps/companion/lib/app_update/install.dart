// Where the app runs from, and whether it updates itself (G41.8b). Only the app installed on its
// own updates itself: Windows' RGCompanion-Setup.exe (its folder has Inno Setup's uninstaller and
// no RedGiant.exe above it) and Linux's install-app.sh (`$XDG_DATA_HOME/rgcompanion`). The copy a
// launcher carries (RedGiant-Setup.exe's app\, RedGiant.app's Helpers) is updated with RedGiant,
// never here; the Mac's app comes only with RedGiant; phones update from their stores.
import 'brand.dart';

class InstallSpot {
  const InstallSpot({required this.system, required this.dir, required this.exe});

  /// 'windows' or 'linux'.
  final String system;

  /// The folder the app is in (replaced whole by an update).
  final String dir;

  /// The executable started after the update.
  final String exe;

  @override
  bool operator ==(Object other) =>
      other is InstallSpot && other.system == system && other.dir == dir && other.exe == exe;

  @override
  int get hashCode => Object.hash(system, dir, exe);

  @override
  String toString() => 'InstallSpot($system, $dir)';
}

String _parent(String path, String sep) {
  final i = path.lastIndexOf(sep);
  return i <= 0 ? path : path.substring(0, i);
}

String _trimEnd(String p, String sep) =>
    p.length > 1 && p.endsWith(sep) ? p.substring(0, p.length - 1) : p;

/// The install this app updates by itself, or null. [system]: `Platform.operatingSystem`;
/// [exePath]: `Platform.resolvedExecutable`; [env]: the process's environment; [exists]: whether a
/// file is there (the tests give a list).
InstallSpot? standaloneSpot({
  required String system,
  required String exePath,
  required Map<String, String> env,
  required bool Function(String path) exists,
}) {
  // Opened by a launcher (G40.12): RedGiant's own copy, whatever the folder.
  if ((env['RGCOMPANION_HANDOFF_FILE'] ?? '').isNotEmpty) return null;
  if ((env['RGCOMPANION_HANDOFF'] ?? '').isNotEmpty) return null;
  switch (system) {
    case 'windows':
      final dir = _parent(exePath, r'\');
      if (dir == exePath || !exePath.toLowerCase().endsWith('\\$kExeName.exe')) return null;
      // RedGiant-Setup.exe's copy: <RedGiant>\app\rgcompanion.exe, RedGiant.exe one folder up.
      if (exists('${_parent(dir, r'\')}\\RedGiant.exe')) return null;
      // RGCompanion-Setup.exe's folder has its uninstaller.
      if (!exists('$dir\\unins000.exe')) return null;
      return InstallSpot(system: system, dir: dir, exe: exePath);
    case 'linux':
      final dir = _parent(exePath, '/');
      if (dir == exePath || !exePath.endsWith('/$kExeName')) return null;
      final home = env['HOME'] ?? '';
      final xdg = env['XDG_DATA_HOME'] ?? '';
      final data = _trimEnd(xdg.isNotEmpty ? xdg : '$home/.local/share', '/');
      if (!data.startsWith('/')) return null;
      for (final name in kLinuxInstallDirs) {
        if (dir == '$data/$name') return InstallSpot(system: system, dir: dir, exe: exePath);
      }
      return null;
    default:
      return null;
  }
}

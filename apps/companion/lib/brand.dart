// The product's name as a person sees it, and the names of the files a release carries for the
// app (G41.8b; plan 3.9.0, N1): one place, the app's twin of packages/protocol/src/brand.ts
// (test/brand_test.dart keeps them equal). The inside (the package `rgcompanion`, the executable,
// the settings' keys, the ids nobody sees) keeps its name. scripts/name-audit.mjs guards the old
// names.

/// The product's name, everywhere a person reads it (protocol `PRODUCT_NAME`).
const kProductName = 'Rasgeth';

/// The app alone on a computer, next to which the whole installation may sit (protocol
/// `DESKTOP_APP_NAME`, plan 3.9.0 choice 4); on the phones the app is just [kProductName].
const kDesktopAppName = '$kProductName App';

/// The name in the windows, the menus and the update's texts. Still the old one until the app's
/// texts move to the new name (plan 3.9.0, N2 and N5), then [kProductName].
const kAppName = 'RGCompanion';

/// Where the releases are (GitHub: `releases/latest`, `releases/tags/v<version>`).
const kReleaseRepo = 'Frostmoore/redgiant2';

/// The list of the app's own packages with their sha256, signed with the update key
/// (`<name>.sig`, packaging/update/sign.mjs), attached to every release.
const kSumsAsset = 'SHA256SUMS-companion';

/// The Windows installer for this user (packaging/windows/RGCompanion.iss).
const kWindowsSetupAsset = 'RGCompanion-Setup.exe';

/// The Linux archive with `install-app.sh` (packaging/linux-app).
const kLinuxTarAsset = 'rgcompanion-linux-x64.tar.gz';

/// The folder install-app.sh fills in `$XDG_DATA_HOME` (`~/.local/share`), first the current one.
const kLinuxInstallDirs = ['rgcompanion'];

/// The executable's name inside the folder (the inside does not change with the name).
const kExeName = 'rgcompanion';

/// The file this release wants for a system, by its name; when a release names it differently
/// (an older app reading a newer release after a rename) the one line of the signed list that
/// has the system's shape is taken: the list holds only the app's packages.
String? assetFor(String system, List<String> listed) {
  final preferred = switch (system) {
    'windows' => kWindowsSetupAsset,
    'linux' => kLinuxTarAsset,
    _ => null,
  };
  if (preferred == null) return null;
  if (listed.contains(preferred)) return preferred;
  bool shaped(String n) => switch (system) {
    'windows' => n.toLowerCase().endsWith('-setup.exe'),
    _ => n.toLowerCase().endsWith('-linux-x64.tar.gz'),
  };
  final shapedNames = listed.where(shaped).toList();
  return shapedNames.length == 1 ? shapedNames.single : null;
}

// Which version the app on its own offers (G41.8b): a pure function, tested as a table
// (test/g41_8b_app_update_test.dart). Change the table first.

/// The app's version, given at build time (companion.yml: `--dart-define=RG_APP_VERSION=` from
/// packaging/release-kind.json, the tag's). Empty in a build from the sources: such a build never
/// updates itself.
const kAppVersion = String.fromEnvironment('RG_APP_VERSION');

/// `3.9.0` → [3, 9, 0]; null for anything else (`v3.9.0` is read without its `v`; a pre-release
/// such as `3.9.0-rc1`, or a build from the sources, is not a version to compare).
List<int>? parseVersion(String? v) {
  if (v == null) return null;
  final m = RegExp(r'^v?(\d{1,4})\.(\d{1,4})\.(\d{1,4})$').firstMatch(v.trim());
  if (m == null) return null;
  return [for (var i = 1; i <= 3; i++) int.parse(m.group(i)!)];
}

/// <0, 0, >0 as [a] is older than, the same as, newer than [b] (both parsed).
int compareVersions(List<int> a, List<int> b) {
  for (var i = 0; i < 3; i++) {
    if (a[i] != b[i]) return a[i].compareTo(b[i]);
  }
  return 0;
}

enum UpdateWhy {
  /// A build from the sources (no version): never updated.
  dev,

  /// The newest release could not be read, and the RedGiant says nothing newer.
  unknown,

  /// The app is the newest release (or newer).
  upToDate,

  /// The person chose «Skip this version» for exactly this one.
  skipped,

  /// The newest release on GitHub.
  latest,

  /// The version of the RedGiant the app is connected to, when GitHub could not be read.
  server,
}

class UpdateChoice {
  const UpdateChoice(this.why, [this.version]);

  final UpdateWhy why;

  /// The version offered (`X.Y.Z`), only for [UpdateWhy.latest] and [UpdateWhy.server].
  final String? version;

  bool get offered => version != null;

  @override
  bool operator ==(Object other) =>
      other is UpdateChoice && other.why == why && other.version == version;

  @override
  int get hashCode => Object.hash(why, version);

  @override
  String toString() => 'UpdateChoice($why, $version)';
}

/// [current]: this app's version. [latest]: GitHub's `releases/latest` tag (null when it could
/// not be read). [server]: the connected RedGiant's version (null: none, or from the sources).
/// [skipped]: the version the person chose to skip. [asked]: the person asked from the menu
/// («Check for updates»), so a skipped version is offered again.
UpdateChoice chooseUpdate({
  required String current,
  String? latest,
  String? server,
  String? skipped,
  bool asked = false,
}) {
  final cur = parseVersion(current);
  if (cur == null) return const UpdateChoice(UpdateWhy.dev);
  String text(List<int> v) => v.join('.');
  final skip = parseVersion(skipped);
  bool isSkipped(List<int> v) => !asked && skip != null && compareVersions(skip, v) == 0;
  final lat = parseVersion(latest);
  if (lat != null) {
    if (compareVersions(lat, cur) <= 0) return const UpdateChoice(UpdateWhy.upToDate);
    if (isSkipped(lat)) return const UpdateChoice(UpdateWhy.skipped);
    return UpdateChoice(UpdateWhy.latest, text(lat));
  }
  final srv = parseVersion(server);
  if (srv != null && compareVersions(srv, cur) > 0) {
    if (isSkipped(srv)) return const UpdateChoice(UpdateWhy.skipped);
    return UpdateChoice(UpdateWhy.server, text(srv));
  }
  return const UpdateChoice(UpdateWhy.unknown);
}

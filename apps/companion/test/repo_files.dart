// Files of the monorepo some tests compare the app with (the page's colours, its logo, the
// launcher's update key). Found going up from the app (`apps/companion`), whatever the system's
// separator, so they work from the repository on every system. Where the app is copied alone
// (Rig's build folder) without them, the test is skipped and says why; inside the repository a
// missing file fails.
import 'dart:io';

/// A file of the repository, found going up from the app, or null.
File? repoFile(String rel) {
  for (var d = Directory.current.absolute; ; d = d.parent) {
    final f = File('${d.path}/$rel');
    if (f.existsSync()) return f;
    if (d.parent.path == d.path) return null;
  }
}

/// `skip:` for a test that needs [rel]: false when it is there or inside the repository (so a
/// missing file fails there), else why it is skipped.
Object repoSkip(String rel) => repoFile(rel) == null && repoFile('pnpm-workspace.yaml') == null
    ? 'the app was copied without the repository: no $rel above it'
    : false;

// «All settings» (G40.8): the page's Settings inside the app, so nothing is missing from the
// native ones. The page is opened with the device's token in the fragment (`#token=…`, read by
// the page's `takeFromLink` and taken out of the address at once; a fragment never reaches the
// server nor a log), never in the query. The rules are pure functions, tested as tables.
import 'dart:io';
import 'dart:typed_data';

import 'transport.dart';
import 'types.dart';

enum FullSettingsMode {
  /// A WebView inside the app (Android, iOS, macOS), with the app's own trust.
  webView,

  /// The system's browser, without the token (Windows and Linux have no WebView until G40.12):
  /// the person signs in there as usual.
  browser,

  /// Not over plain http on the network: the token would travel in clear.
  unavailable,
}

FullSettingsMode fullSettingsMode(DevicePlatform p, TransportKind k) {
  if (k == TransportKind.channel) return FullSettingsMode.unavailable;
  return switch (p) {
    DevicePlatform.android ||
    DevicePlatform.ios ||
    DevicePlatform.macos => FullSettingsMode.webView,
    _ => FullSettingsMode.browser,
  };
}

/// The page at [base] opening on Settings, signed in with [token] (null: as usual).
Uri fullSettingsUrl(Uri base, {String? token}) => Uri(
  scheme: base.scheme,
  host: base.host,
  port: base.hasPort ? base.port : null,
  path: '/',
  fragment: token == null ? 'open=settings' : 'token=${Uri.encodeComponent(token)}&open=settings',
);

/// Whether the WebView may go on past a certificate the system does not trust: only when it is
/// exactly the one the app checked against RedGiant's local CA a moment before (the same bytes).
bool sslProceed(List<int>? presented, List<int>? pinnedLeaf) {
  if (presented == null || pinnedLeaf == null || presented.isEmpty) return false;
  if (presented.length != pinnedLeaf.length) return false;
  for (var i = 0; i < presented.length; i++) {
    if (presented[i] != pinnedLeaf[i]) return false;
  }
  return true;
}

/// Whether a navigation stays in the page (same scheme, host and port); anything else opens
/// outside the app.
bool sameOrigin(Uri a, Uri b) =>
    a.scheme == b.scheme && a.host.toLowerCase() == b.host.toLowerCase() && a.port == b.port;

/// The certificate RedGiant shows at [base], checked against [caPem] only (the app's pinning):
/// its DER bytes, or null when it is not RedGiant's.
Future<Uint8List?> pinnedLeaf(Uri base, String caPem) async {
  final client = HttpClient(context: pinnedContext(caPem))
    ..connectionTimeout = const Duration(seconds: 8);
  try {
    final req = await client.getUrl(base.replace(path: '/api/app/hello', query: null));
    final res = await req.close();
    await res.drain<void>();
    return res.certificate?.der;
  } on Object {
    return null;
  } finally {
    client.close(force: true);
  }
}

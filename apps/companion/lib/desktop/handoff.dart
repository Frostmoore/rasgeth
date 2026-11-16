// The computers' launchers hand the app its local RedGiant (G40.12): RedGiant.exe on Windows and
// RedGiant.app on macOS start this window instead of the browser, with the local server's address
// and a device token they made for it (`POST /api/devices` with the installation's token).
//
// The token never travels on the command line (other processes read it there):
// - RGCOMPANION_HANDOFF_FILE: the path of a file only this user can read (Windows: an ACL with
//   the user alone; elsewhere 0600). The app reads it and deletes it at once, whatever it holds.
// - RGCOMPANION_HANDOFF: the same JSON in the child's own environment (macOS: the sandboxed app
//   cannot read the launcher's files; only this user's processes see another's environment).
//
// What it holds: {"v":1,"address":"http://127.0.0.1:7600","token":"rgd_…","deviceId":"…",
// "machine":"…"}. Only a server on this computer (loopback http) is taken: a handoff can never
// point the app at another machine.
import 'dart:convert';
import 'dart:io';

import '../api/transport.dart';

const kHandoffFileVar = 'RGCOMPANION_HANDOFF_FILE';
const kHandoffVar = 'RGCOMPANION_HANDOFF';

/// The local RedGiant a launcher handed over, with the device token it made for this app.
class LaunchHandoff {
  const LaunchHandoff({required this.address, required this.token, this.deviceId, this.machine});

  /// `http://127.0.0.1:<port>`: always this computer.
  final String address;
  final String token;
  final String? deviceId;
  final String? machine;

  /// The handoff in [text], or null when it is not one this app takes.
  static LaunchHandoff? parse(String text) {
    Object? j;
    try {
      j = jsonDecode(text);
    } on FormatException {
      return null;
    }
    if (j is! Map<String, dynamic> || j['v'] != 1) return null;
    final address = j['address'];
    final token = j['token'];
    if (address is! String || token is! String) return null;
    if (token.length < 16 || token.length > 200 || token.contains(RegExp(r'\s'))) return null;
    final Uri base;
    try {
      base = Uri.parse(address);
    } on FormatException {
      return null;
    }
    if (base.scheme != 'http' || !isLoopbackHost(base.host) || base.port <= 0) return null;
    if (base.path.isNotEmpty && base.path != '/') return null;
    final id = j['deviceId'];
    final machine = j['machine'];
    return LaunchHandoff(
      address: Uri(scheme: 'http', host: base.host, port: base.port).toString(),
      token: token,
      deviceId: id is String && id.isNotEmpty ? id : null,
      machine: machine is String && machine.trim().isNotEmpty ? machine.trim() : null,
    );
  }
}

/// Reads the launcher's handoff once (the file is deleted even when it is not valid).
/// [environment] for the tests; the process's own by default.
Future<LaunchHandoff?> takeLaunchHandoff({Map<String, String>? environment}) async {
  final env = environment ?? Platform.environment;
  final path = env[kHandoffFileVar];
  if (path != null && path.isNotEmpty) {
    final f = File(path);
    String? text;
    try {
      // Never a big file: the launcher writes a few hundred bytes.
      if (await f.length() <= 16384) text = await f.readAsString();
    } on FileSystemException {
      text = null;
    } finally {
      try {
        await f.delete();
      } on FileSystemException {
        // Gone already, or not ours to delete: nothing else to do.
      }
    }
    if (text != null) {
      final h = LaunchHandoff.parse(text);
      if (h != null) return h;
    }
  }
  final inline = env[kHandoffVar];
  if (inline != null && inline.isNotEmpty && inline.length <= 16384) {
    return LaunchHandoff.parse(inline);
  }
  return null;
}

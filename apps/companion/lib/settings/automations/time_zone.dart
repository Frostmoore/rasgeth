// G42.9: the device's time zone by its IANA name («Europe/Rome»), as the page writes the
// browser's in a recipe (`Intl.DateTimeFormat().resolvedOptions().timeZone`). Dart only knows
// an abbreviation («CET»), so: TZ when it names a zone, the link of /etc/localtime on Linux and
// macOS, /etc/timezone, Android's own (`rgcompanion/timezone`, MainActivity.kt). Null when it
// cannot be known (Windows, iOS): the recipe then says UTC, as the page does without a zone.
import 'dart:io';

import 'package:flutter/services.dart';

const _channel = MethodChannel('rgcompanion/timezone');

String? _cached;

/// A zone's IANA name found in a path or a text, else null.
String? zoneFrom(String? s) {
  if (s == null) return null;
  final t = s.trim();
  final at = t.indexOf('zoneinfo/');
  final name = at >= 0 ? t.substring(at + 'zoneinfo/'.length) : t;
  return RegExp(r'^[A-Za-z_]+(/[A-Za-z0-9_+\-]+)+$').hasMatch(name) || name == 'UTC' ? name : null;
}

Future<String?> deviceTimeZone() async {
  if (_cached != null) return _cached;
  String? found = zoneFrom(Platform.environment['TZ']);
  try {
    if (found == null && Platform.isAndroid) {
      found = zoneFrom(await _channel.invokeMethod<String>('zone'));
    }
    if (found == null && (Platform.isLinux || Platform.isMacOS)) {
      final link = File('/etc/localtime');
      if (link.existsSync()) found = zoneFrom(link.resolveSymbolicLinksSync());
      final file = File('/etc/timezone');
      if (found == null && file.existsSync()) found = zoneFrom(file.readAsStringSync());
    }
  } on Object {
    found = null;
  }
  return _cached = found;
}

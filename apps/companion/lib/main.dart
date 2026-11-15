// RGCompanion (G40, 3.8): the RedGiant app for Android, iOS, Windows, macOS and Linux. One
// Flutter project; on computers the launchers stay the local server's keeper.
import 'package:flutter/material.dart';

import 'api/discovery.dart';
import 'api/servers.dart';
import 'app.dart';
import 'app_state.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  final controller = AppController(prefs: SharedAppPrefs(), discovery: BonsoirRedGiantDiscovery());
  runApp(RGCompanionApp(controller: controller));
  controller.restore();
}

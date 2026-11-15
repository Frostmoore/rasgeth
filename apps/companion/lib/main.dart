// RGCompanion (G40, 3.8): the RedGiant app for Android, iOS, Windows, macOS and Linux. One
// Flutter project; on computers the launchers stay the local server's keeper.
import 'package:flutter/material.dart';

import 'app.dart';
import 'app_state.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  final controller = AppController();
  runApp(RGCompanionApp(controller: controller));
  controller.restore();
}

// «Agenti al lavoro insieme, al massimo» (3.8.10) lives in Settings › Commands since G42.4
// (`lib/settings/commands_screen.dart`, one page with the background commands' limits and the
// line): what opened it opens that page.
import 'package:flutter/widgets.dart';

import '../settings/commands_screen.dart';

export '../settings/commands_screen.dart' show atWorkChoices, atWorkSummary, CommandsScreen;

/// Opens Settings › Commands, where the agents at work together are.
Future<void> openAtWork(BuildContext context) => openCommandsSettings(context);

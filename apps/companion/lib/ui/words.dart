import '../api/types.dart';
import '../l10n/app_localizations.dart';

/// A mascot's state in words: never left to the animation alone.
String stateWord(AppLocalizations l, MascotState s) => switch (s) {
  MascotState.idle => l.stateIdle,
  MascotState.think => l.stateThink,
  MascotState.work => l.stateWork,
  MascotState.wait => l.stateWait,
  MascotState.error => l.stateError,
};

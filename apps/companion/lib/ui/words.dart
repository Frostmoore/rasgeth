import '../api/model_routes.dart';
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

/// How a model goes, in a word (G40.9b): «Abbonamento», «Chiave API», «Tramite Rig», «Locale».
String wayWord(AppLocalizations l, ModelWay w) => switch (w.route.kind) {
  ModelRouteKind.subscription => l.modelWaySubscription,
  ModelRouteKind.key => l.modelWayKey,
  ModelRouteKind.node => l.modelWayNode(w.route.node ?? ''),
  ModelRouteKind.local => l.modelWayLocal,
  ModelRouteKind.other => w.choice.provider,
};

/// What a way means for the person, in one line.
String wayHint(AppLocalizations l, ModelWay w) => switch (w.route.kind) {
  ModelRouteKind.subscription => l.modelHintSubscription,
  ModelRouteKind.key => l.modelHintKey,
  ModelRouteKind.node => l.modelHintNode(w.route.node ?? ''),
  ModelRouteKind.local => l.modelHintLocal,
  ModelRouteKind.other => l.modelHintOther,
};

// Where the mascots' drawings come from: the server (`GET /api/agents/:id/mascot?format=svg`),
// kept in memory per agent, state, theme and size class.
import 'package:flutter/widgets.dart';

import '../api/client.dart';
import '../api/types.dart';

abstract class MascotSource {
  /// The drawing of [agentId] in [state] and [theme]; [tiny] is the 16-20 px drawing, [compact]
  /// the 21-32 px one (God and the Demigod keep only body, face and crown or diadem there).
  Future<String> svg(
    String agentId,
    MascotState state,
    MascotTheme theme, {
    bool tiny = false,
    bool compact = false,
  });
}

class ClientMascotSource implements MascotSource {
  ClientMascotSource(this.client);

  final RedGiantClient client;
  final Map<String, Future<String>> _cache = {};

  @override
  Future<String> svg(
    String agentId,
    MascotState state,
    MascotTheme theme, {
    bool tiny = false,
    bool compact = false,
  }) {
    final key = '$agentId|${state.name}|${theme.name}|$tiny|$compact';
    return _cache[key] ??= client
        .mascotSvg(agentId, state: state, theme: theme, size: tiny ? 20 : (compact ? 32 : 128))
        .catchError((Object e) {
          _cache.remove(key);
          throw e;
        });
  }

  /// After «Change mascot» (or a new seed from the server).
  void forget(String agentId) => _cache.removeWhere((k, _) => k.startsWith('$agentId|'));
}

/// Gives the mascots under it their source and the app's «Reduce motion».
class MascotScope extends InheritedWidget {
  const MascotScope({super.key, this.source, this.reduceMotion = false, required super.child});

  final MascotSource? source;
  final bool reduceMotion;

  static MascotScope? maybeOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<MascotScope>();

  @override
  bool updateShouldNotify(MascotScope old) =>
      old.source != source || old.reduceMotion != reduceMotion;
}

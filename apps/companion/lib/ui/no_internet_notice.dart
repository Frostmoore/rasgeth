// Without internet (3.9.1, as the page's banner in App.tsx): the parts of the server's start that
// need it (a provider's key, Telegram, a chat, a subscription) connect once the network is back;
// meanwhile a line says which, over the phone's home and under the computer's top bar. The server
// lists them in `GET /api/platform` (`waitingNetwork`); read with the other lists and, while
// something waits, every 30 seconds until the list is empty.
import 'dart:async';

import 'package:flutter/material.dart';

import '../api/client.dart';
import '../app_state.dart';
import '../l10n/app_localizations.dart';
import '../theme/colors.dart';
import 'icons.dart';

class NoInternetModel extends ChangeNotifier {
  /// The parts waiting, by their names for people (Anthropic, Telegram…).
  List<String> parts = const [];
  Timer? _again;
  bool _reading = false;

  /// How often the list is read again while something waits (tests put theirs).
  Duration every = const Duration(seconds: 30);

  /// The labels in `GET /api/platform`'s `waitingNetwork`.
  static List<String> labelsOf(Object? platform) {
    final list = platform is Map<String, dynamic> ? platform['waitingNetwork'] : null;
    if (list is! List) return const [];
    return [
      for (final p in list)
        if (p is Map<String, dynamic> && p['label'] is String) p['label'] as String,
    ];
  }

  Future<void> refresh(RedGiantClient? c) async {
    if (c == null || _reading) return;
    _reading = true;
    try {
      final now = labelsOf(await c.getJson('/api/platform'));
      if (now.join('\n') != parts.join('\n')) {
        parts = now;
        notifyListeners();
      }
    } on Object {
      // An older server, or none at the moment: nothing to say.
    } finally {
      _reading = false;
    }
    _again?.cancel();
    _again = parts.isEmpty ? null : Timer(every, () => unawaited(refresh(c)));
  }

  void clear() {
    _again?.cancel();
    _again = null;
    if (parts.isEmpty) return;
    parts = const [];
    notifyListeners();
  }

  @override
  void dispose() {
    _again?.cancel();
    super.dispose();
  }
}

class NoInternetNotice extends StatelessWidget {
  const NoInternetNotice({super.key});

  @override
  Widget build(BuildContext context) {
    final model = AppScope.of(context).noInternet;
    return ListenableBuilder(
      listenable: model,
      builder: (context, _) {
        if (model.parts.isEmpty) return const SizedBox.shrink();
        final l = AppLocalizations.of(context);
        final c = RgColors.of(context);
        return Container(
          key: const Key('no-internet-notice'),
          margin: const EdgeInsets.fromLTRB(12, 8, 12, 4),
          padding: const EdgeInsets.fromLTRB(14, 10, 14, 10),
          decoration: BoxDecoration(
            color: c.accentSoft,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: c.accent.withValues(alpha: .35)),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.only(top: 1, right: 10),
                child: RgIcon(RgIcons.wifi, size: 18, color: c.dim),
              ),
              Expanded(
                child: Text(
                  l.noInternetNotice(model.parts.join(', ')),
                  style: TextStyle(color: c.text, fontSize: 13),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

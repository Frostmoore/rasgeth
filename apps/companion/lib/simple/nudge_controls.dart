// God's friendly nudges (3.12.1, the page's components/NudgeControls.tsx): the switch and how
// often, the same in Settings › General and in the simple interface's settings.
import 'dart:async';

import 'package:flutter/material.dart';

import '../api/client.dart';
import '../api/topics.dart';
import '../app_state.dart';
import '../l10n/app_localizations.dart';
import '../screens/new_agent_screen.dart' show RgSwitch;
import '../ui/model_sheet.dart' show ChoiceRow;

class NudgeControls extends StatefulWidget {
  const NudgeControls({super.key});

  @override
  State<NudgeControls> createState() => _NudgeControlsState();
}

class _NudgeControlsState extends State<NudgeControls> {
  NudgeSettings? _s;

  @override
  void initState() {
    super.initState();
    unawaited(_load());
  }

  Future<void> _load() async {
    final c = AppScope.read(context).client;
    if (c == null) return;
    try {
      final s = await c.nudgeSettings();
      if (mounted) setState(() => _s = s);
    } on ApiException {
      // An older server: nothing to show.
    }
  }

  Future<void> _save(NudgeSettings s) async {
    final before = _s;
    setState(() => _s = s);
    try {
      await AppScope.read(context).client?.setNudgeSettings(s);
    } on ApiException {
      if (mounted) setState(() => _s = before);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final s = _s;
    if (s == null) return const SizedBox.shrink();
    return Wrap(
      spacing: 10,
      runSpacing: 8,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        Semantics(
          label: l.nudgeTitle,
          child: GestureDetector(
            key: const Key('nudge-switch'),
            onTap: () => unawaited(_save(NudgeSettings(on: !s.on, every: s.every))),
            child: RgSwitch(on: s.on),
          ),
        ),
        if (s.on)
          ChoiceRow(
            keyPrefix: 'nudge-every',
            values: const ['day', 'two_days', 'week'],
            selected: s.every,
            label: (v) => switch (v) {
              'two_days' => l.nudgeTwoDays,
              'week' => l.nudgeWeek,
              _ => l.nudgeDay,
            },
            onChanged: (v) => unawaited(_save(NudgeSettings(on: s.on, every: v))),
          ),
      ],
    );
  }
}

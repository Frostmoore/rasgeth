// Activity: tasks in progress and done, grouped by agent (G40.9).
import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import '../ui/common.dart';
import '../ui/icons.dart';

class ActivityScreen extends StatelessWidget {
  const ActivityScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ScreenHeader(title: l.tabActivity),
        Expanded(
          child: EmptyState(icon: RgIcons.list, text: l.activityEmpty),
        ),
      ],
    );
  }
}

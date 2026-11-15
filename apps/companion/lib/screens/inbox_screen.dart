// For you: requests, questions and choices waiting for the person (G40.9: the stack of cards,
// critical requests full screen).
import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import '../ui/common.dart';
import '../ui/icons.dart';

class InboxScreen extends StatelessWidget {
  const InboxScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ScreenHeader(title: l.tabInbox),
        Expanded(
          child: EmptyState(icon: RgIcons.bell, text: l.inboxEmpty),
        ),
      ],
    );
  }
}

// The new name, said once (plan 3.9.0, choice 17, as the page's RenameNotice.tsx): «RedGiant is
// now called Rasgeth» over the phone's home and under the computer's top bar, for whoever knew the
// old name (AppController.renameDue), until closed with «Got it» or the cross (`renameSeen`, this
// device). The old name is in its title on purpose.
import 'package:flutter/material.dart';

import '../app_state.dart';
import '../l10n/app_localizations.dart';
import '../theme/colors.dart';
import 'icons.dart';

class RenameNotice extends StatelessWidget {
  const RenameNotice({super.key});

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    if (!app.renameDue) return const SizedBox.shrink();
    final l = AppLocalizations.of(context);
    final c = RgColors.of(context);
    return Container(
      key: const Key('rename-notice'),
      margin: const EdgeInsets.fromLTRB(12, 8, 12, 4),
      padding: const EdgeInsets.fromLTRB(14, 10, 4, 10),
      decoration: BoxDecoration(
        color: c.accentSoft,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: c.accent.withValues(alpha: .35)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l.renameNoticeTitle,
                  style: TextStyle(color: c.text, fontSize: 14, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 3),
                Text(l.renameNoticeText, style: TextStyle(color: c.dim, fontSize: 13)),
              ],
            ),
          ),
          TextButton(
            key: const Key('rename-notice-ok'),
            onPressed: app.dismissRenameNotice,
            child: Text(l.renameNoticeOk),
          ),
          IconButton(
            key: const Key('rename-notice-close'),
            tooltip: l.close,
            onPressed: app.dismissRenameNotice,
            icon: RgIcon(RgIcons.x, size: 18, color: c.dim),
          ),
        ],
      ),
    );
  }
}

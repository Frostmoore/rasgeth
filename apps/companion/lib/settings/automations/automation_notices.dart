// G42.9: the automations' messages for the person (`automation.notice`, a recipe's
// `notify.to: [web]`), in «For you» as in the page's bell (Bell.tsx): the automation's name, its
// state when it did not go well, the message, its conversation, «Dismiss».
import 'package:flutter/material.dart';

import '../../app_state.dart';
import '../../l10n/app_localizations.dart';
import '../../theme/colors.dart';
import '../../ui/icons.dart';
import 'automation_types.dart';
import 'automations_screen.dart' show openRunConversation;

class AutomationNotices extends StatelessWidget {
  const AutomationNotices({super.key, required this.notices, this.shrink = false});

  final List<AutomationNotice> notices;

  /// Above the requests' stack: only as tall as it needs.
  final bool shrink;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final c = RgColors.of(context);
    return LayoutBuilder(
      builder: (context, box) {
        final side = 16 + ((box.maxWidth - 32 - 640) / 2).clamp(0, 9999).toDouble();
        return ListView(
          key: const Key('au-notices'),
          shrinkWrap: shrink,
          padding: EdgeInsets.fromLTRB(side, 4, side, 8),
          children: [
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Text(
                '${l.auAutomationNotices} (${notices.length})',
                style: TextStyle(fontWeight: FontWeight.w800, color: c.text, fontSize: 15),
              ),
            ),
            for (final n in notices) _NoticeCard(notice: n),
          ],
        );
      },
    );
  }
}

class _NoticeCard extends StatelessWidget {
  const _NoticeCard({required this.notice});

  final AutomationNotice notice;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final c = RgColors.of(context);
    final app = AppScope.of(context);
    final n = notice;
    final ok = n.status == 'ok';
    return Container(
      key: Key('au-notice-${n.runId}'),
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.fromLTRB(14, 10, 6, 12),
      decoration: BoxDecoration(
        color: c.panel,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: ok ? c.line : c.err.withValues(alpha: .5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              RgIcon(RgIcons.clock, size: 17, color: ok ? c.accent : c.err),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  n.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontWeight: FontWeight.w800, color: c.text),
                ),
              ),
              if (!ok)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: c.err.withValues(alpha: .12),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    n.status,
                    style: TextStyle(color: c.err, fontSize: 12, fontWeight: FontWeight.w700),
                  ),
                ),
              if (n.sessionId != null)
                TextButton(
                  key: Key('au-notice-open-${n.runId}'),
                  onPressed: () => openRunConversation(context, n.sessionId!, null),
                  child: Text(l.auOwnNoticeOpen),
                ),
              IconButton(
                key: Key('au-notice-dismiss-${n.runId}'),
                tooltip: l.auDismiss,
                onPressed: () => app.live.dismissNotice(n.runId),
                icon: RgIcon(RgIcons.x, size: 16, color: c.dim),
              ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: Text(n.text, style: TextStyle(color: c.text, height: 1.45)),
          ),
        ],
      ),
    );
  }
}

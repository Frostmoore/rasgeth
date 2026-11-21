// G42.11: the agents' proposals in the bell (the page's Bell.tsx «Proposals waiting for you»):
// read when the bell or «For you» opens, each with approve, reject and «open» (Settings ›
// Extensions, where it can be read in full).
import 'dart:async';

import 'package:flutter/material.dart';

import '../../api/client.dart';
import '../../app_state.dart';
import '../../l10n/app_localizations.dart';
import '../../theme/colors.dart';
import '../api/extensions_api.dart';
import 'extensions_screen.dart' show kindLabel, openExtensionsSettings, whoOf;

class ProposalsBlock extends StatefulWidget {
  const ProposalsBlock({super.key, this.hideEmpty = false, this.onOpen});

  /// «For you» on a phone shows the block only when something waits.
  final bool hideEmpty;

  /// Opens Extensions in place of the block (the bell closes itself first).
  final VoidCallback? onOpen;

  @override
  State<ProposalsBlock> createState() => _ProposalsBlockState();
}

class _ProposalsBlockState extends State<ProposalsBlock> {
  List<ExtProposal>? _list;
  final _busy = <String>{};

  @override
  void initState() {
    super.initState();
    unawaited(_load());
  }

  Future<void> _load() async {
    final c = AppScope.read(context).client;
    if (c == null) return;
    try {
      final l = await c.extProposals(status: 'pending');
      if (mounted) setState(() => _list = l);
    } on ApiException {
      if (mounted) setState(() => _list = const []);
    }
  }

  Future<void> _decide(ExtProposal p, bool approve) async {
    final c = AppScope.read(context).client;
    if (c == null) return;
    setState(() => _busy.add(p.id));
    try {
      await c.decideExtension(p.id, approve: approve);
    } on ApiException {
      // Read again below: the list says how it stands.
    }
    if (mounted) setState(() => _busy.remove(p.id));
    await _load();
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final c = RgColors.of(context);
    final app = AppScope.of(context);
    final list = _list ?? const <ExtProposal>[];
    if (widget.hideEmpty && list.isEmpty) return const SizedBox.shrink();
    return Column(
      key: const Key('bell-proposals'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(6, 12, 6, 4),
          child: Text(
            '${l.xtProposals} (${list.length})',
            style: TextStyle(color: c.dim, fontWeight: FontWeight.w800, fontSize: 12.5),
          ),
        ),
        if (list.isEmpty)
          Padding(
            padding: const EdgeInsets.fromLTRB(6, 2, 6, 6),
            child: Text(l.xtNoProposals, style: TextStyle(color: c.dim, fontSize: 13)),
          ),
        for (final p in list)
          Container(
            key: Key('bell-proposal-${p.id}'),
            margin: const EdgeInsets.only(bottom: 6),
            padding: const EdgeInsets.fromLTRB(10, 8, 6, 6),
            decoration: BoxDecoration(
              color: c.bg,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: c.line),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                      decoration: BoxDecoration(
                        color: c.panel2,
                        borderRadius: BorderRadius.circular(99),
                      ),
                      child: Text(
                        kindLabel(l, p.kind),
                        style: TextStyle(color: c.dim, fontSize: 11),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        p.name,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(color: c.text, fontWeight: FontWeight.w800),
                      ),
                    ),
                    TextButton(
                      key: Key('bell-proposal-open-${p.id}'),
                      onPressed: () => widget.onOpen != null
                          ? widget.onOpen!()
                          : unawaited(openExtensionsSettings(context)),
                      child: Text(l.xtOpen),
                    ),
                  ],
                ),
                Text(
                  '${p.updateLine ?? p.description} · ${l.xtBy} ${whoOf(l, app, p.author)}',
                  style: TextStyle(color: c.dim, fontSize: 12.5, height: 1.35),
                ),
                Wrap(
                  alignment: WrapAlignment.end,
                  spacing: 4,
                  children: [
                    TextButton(
                      key: Key('bell-proposal-reject-${p.id}'),
                      style: TextButton.styleFrom(foregroundColor: c.err),
                      onPressed: _busy.contains(p.id) ? null : () => _decide(p, false),
                      child: Text(l.xtReject),
                    ),
                    FilledButton(
                      key: Key('bell-proposal-approve-${p.id}'),
                      onPressed: _busy.contains(p.id) ? null : () => _decide(p, true),
                      child: Text(l.xtApprove),
                    ),
                  ],
                ),
              ],
            ),
          ),
      ],
    );
  }
}

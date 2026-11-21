// «Removed agents» (3.8.9, the page's section of Settings › Agents): the agents taken out of the
// team, by the person or by God, with when, by whom, why and who went with them. Nothing was
// deleted: «Restore» brings each back with those removed with it, and their conversations open
// read only.
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../api/conversation.dart';
import '../api/types.dart';
import '../app_state.dart';
import '../l10n/app_localizations.dart';
import '../mascot/mascot_view.dart';
import '../theme/colors.dart';
import '../ui/common.dart';
import '../ui/icons.dart';
import '../ui/settings_kit.dart';
import 'agent_settings_screen.dart' show kindWords;
import 'conversation_screen.dart';

Future<void> openRemovedAgents(BuildContext context) =>
    Navigator.of(context)
        .push(MaterialPageRoute<void>(builder: (_) => const RemovedAgentsScreen()));

class RemovedAgentsScreen extends StatefulWidget {
  const RemovedAgentsScreen({super.key});

  @override
  State<RemovedAgentsScreen> createState() => _RemovedAgentsScreenState();
}

class _RemovedAgentsScreenState extends State<RemovedAgentsScreen> {
  List<RemovedAgent>? _list;
  String? _note;
  bool _noteBad = false;
  final Set<String> _busy = {};
  List<Agent>? _team;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Read again whenever the team does (`lists.changed`: removed, restored, stopped or resumed
    // here or elsewhere).
    final team = AppScope.of(context).agents;
    if (_list == null || !identical(team, _team)) {
      _team = team;
      _load();
    }
  }

  Future<void> _load() async {
    final list = await AppScope.read(context).removedAgents();
    if (mounted) setState(() => _list = list);
  }

  Future<void> _restore(RemovedAgent r) async {
    final l = AppLocalizations.of(context);
    setState(() => _busy.add(r.agent.id));
    final why = await AppScope.read(context).restoreAgent(r.agent);
    if (!mounted) return;
    setState(() {
      _busy.remove(r.agent.id);
      _noteBad = why != null;
      _note = why == null ? l.raRestored(r.agent.name) : l.raRestoreFailed(why);
    });
    if (why == null) await _load();
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final c = RgColors.of(context);
    final list = _list;
    return SettingsScaffold(
      title: l.raListTitle,
      backKey: const Key('removed-back'),
      backLabel: l.back,
      listKey: const Key('removed-list'),
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
          child: Text(l.raListHelp, style: TextStyle(color: c.dim, fontSize: 13.5, height: 1.35)),
        ),
        if (_note != null)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: NoticeBanner(key: const Key('removed-note'), text: _note!, error: _noteBad),
          ),
        if (list == null)
          const Padding(
            padding: EdgeInsets.all(32),
            child: Center(child: CircularProgressIndicator()),
          )
        else if (list.isEmpty)
          EmptyState(icon: RgIcons.users, text: l.raNone)
        else
          for (final r in list)
            _RemovedCard(
              key: Key('removed-${r.agent.id}'),
              entry: r,
              busy: _busy.contains(r.agent.id),
              onRestore: () => _restore(r),
            ),
      ],
    );
  }
}

class _RemovedCard extends StatefulWidget {
  const _RemovedCard({super.key, required this.entry, required this.busy, required this.onRestore});

  final RemovedAgent entry;
  final bool busy;
  final VoidCallback onRestore;

  @override
  State<_RemovedCard> createState() => _RemovedCardState();
}

class _RemovedCardState extends State<_RemovedCard> {
  bool _open = false;
  List<SessionRow>? _sessions;

  Future<void> _toggle() async {
    setState(() => _open = !_open);
    if (_open && _sessions == null) {
      final rows = await AppScope.read(context).removedSessions(widget.entry.agent.id);
      if (mounted) setState(() => _sessions = rows);
    }
  }

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    final l = AppLocalizations.of(context);
    final c = RgColors.of(context);
    final r = widget.entry;
    final a = r.agent;
    final at = DateTime.tryParse(r.at)?.toLocal();
    final when = at == null ? r.at : DateFormat.yMMMd(l.localeName).add_Hm().format(at);
    final project = app.projects.where((p) => p.id == a.projectId).firstOrNull?.name ?? a.projectId;
    final sessions = _sessions;
    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: SettingsCard(
        children: [
          Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Opacity(
                  opacity: .7,
                  child: MascotView(agentId: a.id, spec: a.mascot, size: 56, label: a.name),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        a.name,
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: c.text),
                      ),
                      Text(
                        [kindWords(l, app, a), ?project].join(' · '),
                        style: TextStyle(color: c.dim, fontSize: 13),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        l.raWhen(when, r.byPerson ? l.raByYou : r.by),
                        key: const Key('removed-when'),
                        style: TextStyle(color: c.text, fontSize: 13.5),
                      ),
                      if (r.reason.isNotEmpty)
                        Text(l.raReason(r.reason), style: TextStyle(color: c.dim, fontSize: 13)),
                      if (r.others.isNotEmpty)
                        Text(
                          l.raWith(r.others.map((x) => x.name).join(', ')),
                          key: const Key('removed-with'),
                          style: TextStyle(color: c.dim, fontSize: 13),
                        ),
                      for (final k in r.kept) ...[
                        const SizedBox(height: 6),
                        Text(
                          [
                            if (k.id != a.id) k.name,
                            k.error ? l.raKeptError : l.raKept(k.commits, k.changes),
                          ].join(' · '),
                          key: Key('removed-kept-${k.id}'),
                          style: TextStyle(
                            color: c.warnText,
                            fontSize: 13.5,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text(l.raKeptHow(k.branch), style: TextStyle(color: c.dim, fontSize: 13)),
                      ],
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                FilledButton.icon(
                  key: Key('removed-restore-${a.id}'),
                  onPressed: widget.busy ? null : widget.onRestore,
                  icon: const RgIcon(RgIcons.refresh, size: 16, color: Colors.white),
                  label: Text(l.raRestore),
                ),
              ],
            ),
          ),
          InkWell(
            key: Key('removed-conversations-${a.id}'),
            onTap: _toggle,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
              child: Row(
                children: [
                  RgIcon(RgIcons.chat, size: 16, color: c.dim),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      l.raConversations(sessions?.length ?? r.sessions),
                      style: TextStyle(color: c.text, fontWeight: FontWeight.w600),
                    ),
                  ),
                  RgIcon(
                    _open ? RgIcons.chevronDown : RgIcons.chevronRight,
                    size: 16,
                    color: c.dim,
                  ),
                ],
              ),
            ),
          ),
          if (_open)
            if (sessions == null)
              const Padding(
                padding: EdgeInsets.all(12),
                child: Center(child: CircularProgressIndicator()),
              )
            else if (sessions.isEmpty)
              Padding(
                padding: const EdgeInsets.fromLTRB(38, 0, 14, 12),
                child: Text(l.raNoConversations, style: TextStyle(color: c.dim)),
              )
            else
              for (final s in sessions)
                ListTile(
                  key: Key('removed-session-${s.id}'),
                  dense: true,
                  contentPadding: const EdgeInsets.only(left: 38, right: 14),
                  title: Text(
                    s.title?.isNotEmpty == true ? s.title! : s.id,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(color: c.text),
                  ),
                  trailing: RgIcon(RgIcons.chevronRight, size: 16, color: c.dim),
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => ConversationScreen(sessionId: s.id, agent: a, removed: true),
                    ),
                  ),
                ),
        ],
      ),
    );
  }
}

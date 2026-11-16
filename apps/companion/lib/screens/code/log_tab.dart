// Log (G40.11): the project's events, newest first, filtered by agent, by type and to errors
// only; a tap opens the event's JSON (why it stopped).
import 'package:flutter/material.dart';

import '../../api/client.dart';
import '../../api/code.dart';
import '../../l10n/app_localizations.dart';
import '../../theme/colors.dart';
import '../../ui/common.dart';
import '../../ui/highlight.dart';
import '../../ui/icons.dart';
import '../conversation_screen.dart';
import 'project_screen.dart';

class LogTab extends StatefulWidget {
  const LogTab({super.key, required this.ctx, this.startAgent});

  final ProjectCtx ctx;
  final String? startAgent;

  @override
  State<LogTab> createState() => _LogTabState();
}

class _LogTabState extends State<LogTab> with AutomaticKeepAliveClientMixin {
  EventsPage? _page;
  Object? _error;
  late String? _agent = widget.startAgent;
  String? _type;
  bool _errors = false;
  final _open = <int>{};

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final p = await widget.ctx.client.projectEvents(
        widget.ctx.project.id,
        agent: _agent,
        type: _type,
        errors: _errors,
      );
      if (mounted)
        setState(() {
          _page = p;
          _error = null;
        });
    } on ApiException catch (e) {
      if (mounted) setState(() => _error = e);
    }
  }

  Future<void> _pickAgent(AppLocalizations l) async {
    final agents = _page?.agents ?? const [];
    final a = await pickFrom<String>(
      context,
      title: l.codeLogAgent,
      options: [('', l.codeLogAllAgents, null), for (final a in agents) (a.id, a.name, null)],
    );
    if (a == null) return;
    setState(() => _agent = a.isEmpty ? null : a);
    await _load();
  }

  Future<void> _pickType(AppLocalizations l) async {
    final t = await pickFrom<String>(
      context,
      title: l.codeLogType,
      options: [
        ('', l.codeLogAllTypes, null),
        for (final t in _page?.types ?? const <String>[]) (t, t, null),
      ],
    );
    if (t == null) return;
    setState(() => _type = t.isEmpty ? null : t);
    await _load();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final l = AppLocalizations.of(context);
    final c = RgColors.of(context);
    final p = _page;
    final agentName = _agent == null
        ? l.codeLogAllAgents
        : p?.agents.where((a) => a.id == _agent).firstOrNull?.name ??
              widget.ctx.agentById(_agent)?.name ??
              _agent!;
    return Column(
      children: [
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.fromLTRB(12, 8, 12, 6),
          child: Row(
            children: [
              PickChip(
                key: const Key('log-agent'),
                icon: RgIcons.user,
                selected: _agent != null,
                label: agentName,
                onTap: () => _pickAgent(l),
              ),
              const SizedBox(width: 6),
              PickChip(
                key: const Key('log-type'),
                icon: RgIcons.list,
                selected: _type != null,
                label: _type ?? l.codeLogAllTypes,
                onTap: () => _pickType(l),
              ),
              const SizedBox(width: 6),
              PickChip(
                key: const Key('log-errors'),
                icon: RgIcons.alert,
                danger: true,
                selected: _errors,
                label: l.codeLogErrors,
                onTap: () {
                  setState(() => _errors = !_errors);
                  _load();
                },
              ),
            ],
          ),
        ),
        Expanded(
          child: p == null
              ? (_error == null
                    ? const Center(child: CircularProgressIndicator())
                    : EmptyState(icon: RgIcons.alert, text: l.codeLoadFailed))
              : p.events.isEmpty
              ? EmptyState(icon: RgIcons.activity, text: l.codeLogEmpty)
              : RefreshIndicator(
                  onRefresh: _load,
                  child: ListView.builder(
                    key: const Key('log-list'),
                    padding: const EdgeInsets.fromLTRB(12, 0, 12, 24),
                    itemCount: p.events.length,
                    itemBuilder: (context, i) => _row(l, c, p.events[i]),
                  ),
                ),
        ),
      ],
    );
  }

  Widget _row(AppLocalizations l, RgColors c, ProjectEvent e) {
    final open = _open.contains(e.seq);
    final summary = e.summary;
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Material(
        color: e.error ? c.criticalSoft : c.panel,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: e.error ? c.critical.withValues(alpha: .4) : c.line),
        ),
        child: InkWell(
          key: Key('log-${e.seq}'),
          borderRadius: BorderRadius.circular(12),
          onTap: () => setState(() => open ? _open.remove(e.seq) : _open.add(e.seq)),
          child: Padding(
            padding: const EdgeInsets.all(10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      clockOf(e.ts),
                      style: TextStyle(
                        color: c.dim,
                        fontSize: 12,
                        fontFamily: monoFamily,
                        fontFamilyFallback: monoFallback,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 1),
                      decoration: BoxDecoration(
                        color: e.error ? c.critical : c.panel2,
                        borderRadius: BorderRadius.circular(99),
                      ),
                      child: Text(
                        e.type,
                        style: TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w700,
                          color: e.error ? c.criticalInk : c.dim,
                          fontFamily: monoFamily,
                          fontFamilyFallback: monoFallback,
                        ),
                      ),
                    ),
                    const Spacer(),
                    if (e.agentName != null)
                      Text(e.agentName!, style: TextStyle(color: c.dim, fontSize: 12)),
                  ],
                ),
                if (summary.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 5),
                    child: Text(
                      summary,
                      maxLines: open ? 20 : 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(color: e.error ? c.criticalText : c.text, fontSize: 13.5),
                    ),
                  ),
                if (open) ...[
                  Container(
                    key: Key('log-json-${e.seq}'),
                    width: double.infinity,
                    margin: const EdgeInsets.only(top: 8),
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: c.code,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: SelectableText(
                      e.json,
                      style: const TextStyle(
                        fontFamily: monoFamily,
                        fontFamilyFallback: monoFallback,
                        fontSize: 12,
                        color: Color(0xFFE8E6E3),
                      ),
                    ),
                  ),
                  if (e.sessionId != null)
                    Align(
                      alignment: Alignment.centerLeft,
                      child: TextButton.icon(
                        onPressed: () => Navigator.of(context).push(
                          MaterialPageRoute<void>(
                            builder: (_) => ConversationScreen(
                              sessionId: e.sessionId!,
                              agent: widget.ctx.agentById(e.agentId),
                            ),
                          ),
                        ),
                        icon: RgIcon(RgIcons.chat, size: 16, color: c.accent),
                        label: Text(l.codeLogOpenChat),
                      ),
                    ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

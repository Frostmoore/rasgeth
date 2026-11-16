// The log on computers (G40.17, board C advanced 5): the project's events as a table, filtered
// on the left (agents, types, only errors, only requests, when) and in one search line that says
// the same in words (`agente:"Coder Web" tipo:tool.*,approval.* pnpm`); on the right the chosen
// event as JSON, its conversation and the other events of the same turn. The search line is
// parsed and written by pure functions ([parseLogQuery], [formatLogQuery]), tested.
import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../api/client.dart';
import '../../api/code.dart';
import '../../app_state.dart';
import '../../l10n/app_localizations.dart';
import '../../mascot/mascot_view.dart';
import '../../screens/new_agent_screen.dart' show RgSwitch;
import '../../theme/colors.dart';
import '../../ui/common.dart';
import '../../ui/highlight.dart';
import '../../ui/icons.dart';
import '../desk_controller.dart';
import '../wall.dart' show clockShort;
import 'common.dart';
import 'projects_wall.dart' show EventType;

enum LogWhen { hour, today, week, all }

class LogQuery {
  const LogQuery({
    this.agents = const [],
    this.types = const [],
    this.text = '',
    this.errors = false,
    this.requests = false,
    this.when = LogWhen.all,
  });

  /// Agents' names (any of them).
  final List<String> agents;

  /// Types, with `*` for any end (`tool.*`).
  final List<String> types;
  final String text;
  final bool errors;
  final bool requests;
  final LogWhen when;

  LogQuery copy({
    List<String>? agents,
    List<String>? types,
    String? text,
    bool? errors,
    bool? requests,
    LogWhen? when,
  }) => LogQuery(
    agents: agents ?? this.agents,
    types: types ?? this.types,
    text: text ?? this.text,
    errors: errors ?? this.errors,
    requests: requests ?? this.requests,
    when: when ?? this.when,
  );
}

final _token = RegExp(r'(\w+):((?:"[^"]*"|[^\s,"]+)(?:,(?:"[^"]*"|[^\s,"]+))*)|("[^"]*"|\S+)');

List<String> _values(String raw) => [
  for (final m in RegExp(r'"([^"]*)"|([^,]+)').allMatches(raw))
    if ((m.group(1) ?? m.group(2) ?? '').trim().isNotEmpty) (m.group(1) ?? m.group(2))!.trim(),
];

/// `agente:"Coder Web","Tester" tipo:tool.*,approval.* solo:errori pnpm` (Italian or English
/// words: agent/agente, type/tipo, only/solo with errors/errori and requests/richieste,
/// when/quando with hour/ora, today/oggi, week/settimana).
LogQuery parseLogQuery(String raw) {
  final agents = <String>[];
  final types = <String>[];
  final words = <String>[];
  var errors = false, requests = false;
  var when = LogWhen.all;
  for (final m in _token.allMatches(raw)) {
    final key = m.group(1)?.toLowerCase();
    final value = m.group(2);
    if (key != null && value != null) {
      switch (key) {
        case 'agente' || 'agent':
          agents.addAll(_values(value));
          continue;
        case 'tipo' || 'type':
          types.addAll(_values(value));
          continue;
        case 'solo' || 'only':
          for (final v in _values(value)) {
            if (v == 'errori' || v == 'errors') errors = true;
            if (v == 'richieste' || v == 'requests') requests = true;
          }
          continue;
        case 'quando' || 'when':
          when = switch (_values(value).firstOrNull) {
            'ora' || 'hour' => LogWhen.hour,
            'oggi' || 'today' => LogWhen.today,
            'settimana' || 'week' => LogWhen.week,
            _ => LogWhen.all,
          };
          continue;
      }
      words.add(m.group(0)!);
      continue;
    }
    final w = m.group(3);
    if (w != null) words.add(w.replaceAll('"', ''));
  }
  return LogQuery(
    agents: agents,
    types: types,
    text: words.join(' '),
    errors: errors,
    requests: requests,
    when: when,
  );
}

String formatLogQuery(LogQuery q, {bool italian = true}) {
  String quote(String s) => s.contains(RegExp(r'[\s,]')) ? '"$s"' : s;
  final parts = <String>[
    if (q.agents.isNotEmpty) '${italian ? 'agente' : 'agent'}:${q.agents.map((a) => '"$a"').join(',')}',
    if (q.types.isNotEmpty) '${italian ? 'tipo' : 'type'}:${q.types.map(quote).join(',')}',
    if (q.errors || q.requests)
      '${italian ? 'solo' : 'only'}:${[
        if (q.errors) italian ? 'errori' : 'errors',
        if (q.requests) italian ? 'richieste' : 'requests',
      ].join(',')}',
    if (q.when != LogWhen.all)
      '${italian ? 'quando' : 'when'}:${switch (q.when) {
        LogWhen.hour => italian ? 'ora' : 'hour',
        LogWhen.today => italian ? 'oggi' : 'today',
        _ => italian ? 'settimana' : 'week',
      }}',
    if (q.text.isNotEmpty) q.text,
  ];
  return parts.join(' ');
}

bool _typeMatches(String type, String pattern) => pattern.endsWith('*')
    ? type.startsWith(pattern.substring(0, pattern.length - 1))
    : type == pattern;

/// Whether [e] passes [q] at [now].
bool logMatches(ProjectEvent e, LogQuery q, {DateTime? now}) {
  if (q.agents.isNotEmpty &&
      !q.agents.any((a) => a.toLowerCase() == (e.agentName ?? '').toLowerCase())) {
    return false;
  }
  if (q.types.isNotEmpty && !q.types.any((t) => _typeMatches(e.type, t))) return false;
  if (q.errors && !e.error) return false;
  if (q.requests && !(e.type.startsWith('approval.') || e.type.startsWith('permission.') || e.type.startsWith('question.'))) {
    return false;
  }
  if (q.when != LogWhen.all) {
    final t = DateTime.tryParse(e.ts)?.toLocal();
    final n = now ?? DateTime.now();
    if (t == null) return false;
    final ok = switch (q.when) {
      LogWhen.hour => n.difference(t) <= const Duration(hours: 1),
      LogWhen.today => t.year == n.year && t.month == n.month && t.day == n.day,
      _ => n.difference(t) <= const Duration(days: 7),
    };
    if (!ok) return false;
  }
  if (q.text.isNotEmpty) {
    final hay = '${e.summary} ${e.type} ${e.agentName ?? ''}'.toLowerCase();
    for (final w in q.text.toLowerCase().split(RegExp(r'\s+'))) {
      if (w.isNotEmpty && !hay.contains(w)) return false;
    }
  }
  return true;
}

const _typeGroups = ['tool.*', 'approval.*', 'task.*', 'session.*', 'message.*', 'ci.*'];

class LogView extends StatefulWidget {
  const LogView({super.key});

  @override
  State<LogView> createState() => _LogViewState();
}

class _LogViewState extends State<LogView> {
  final _field = TextEditingController();
  LogQuery _q = const LogQuery();
  String? _for;
  EventsPage? _page;
  Object? _error;
  ProjectEvent? _sel;
  Timer? _timer;
  late final DeskController _desk = DeskScope.read(context);

  @override
  void initState() {
    super.initState();
    final asked = _desk.logQuery;
    if (asked != null) {
      _desk.logQuery = null;
      _q = parseLogQuery(asked);
    }
    _timer = Timer.periodic(const Duration(seconds: 10), (_) {
      if (_for != null) unawaited(_load(_for!));
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _field.text = formatLogQuery(_q, italian: Localizations.localeOf(context).languageCode == 'it');
  }

  @override
  void dispose() {
    _timer?.cancel();
    _field.dispose();
    super.dispose();
  }

  Future<void> _load(String pid) async {
    final c = AppScope.read(context).client;
    if (c == null) return;
    try {
      final p = await c.projectEvents(pid, limit: 500);
      if (!mounted || pid != _for) return;
      setState(() {
        _page = p;
        _error = null;
      });
    } on ApiException catch (e) {
      if (mounted) setState(() => _error = e);
    }
  }

  void _set(LogQuery q) {
    setState(() => _q = q);
    _field.text = formatLogQuery(q, italian: Localizations.localeOf(context).languageCode == 'it');
  }

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    final desk = DeskScope.of(context);
    final l = AppLocalizations.of(context);
    final c = RgColors.of(context);
    final asked = desk.logQuery;
    if (asked != null) {
      desk.logQuery = null;
      WidgetsBinding.instance.addPostFrameCallback((_) => _set(parseLogQuery(asked)));
    }
    final p = deskProject(app, desk);
    if (p == null) return const NoProject();
    if (_for != p.id) {
      _for = p.id;
      _page = null;
      _sel = null;
      unawaited(_load(p.id));
    }
    final events = (_page?.events ?? const <ProjectEvent>[]).where((e) => logMatches(e, _q)).toList();
    final mono = TextStyle(
      fontFamily: monoFamily,
      fontFamilyFallback: monoFallback,
      fontSize: 12,
      color: c.dim,
    );
    final agentNames = <String>{
      for (final a in _page?.agents ?? const <({String id, String name})>[]) a.name,
    };
    Widget chip(String label, bool on, VoidCallback onTap, {Key? key}) => Padding(
      padding: const EdgeInsets.only(right: 6, bottom: 6),
      child: Material(
        color: on ? c.text : c.panel2,
        borderRadius: BorderRadius.circular(99),
        child: InkWell(
          key: key,
          borderRadius: BorderRadius.circular(99),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
            child: Text(
              label,
              style: mono.copyWith(color: on ? c.bg : c.dim, fontWeight: FontWeight.w700),
            ),
          ),
        ),
      ),
    );
    Widget switchRow(String label, bool on, VoidCallback onTap, {Key? key}) => InkWell(
      key: key,
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
        child: Row(
          children: [
            Expanded(child: Text(label, style: TextStyle(fontSize: 13, color: c.text))),
            RgSwitch(on: on),
          ],
        ),
      ),
    );
    final left = ListView(
      children: [
        SideHead(l.deskProject),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14),
          child: Wrap(
            children: [
              for (final x in app.projects.where((x) => !x.archived))
                chip(x.name, x.id == p.id, () => desk.setProject(x.id)),
            ],
          ),
        ),
        SideHead(l.deskAgentsHead),
        for (final name in agentNames)
          switchRow(
            name,
            _q.agents.contains(name),
            () => _set(
              _q.copy(
                agents: _q.agents.contains(name)
                    ? (List.of(_q.agents)..remove(name))
                    : [..._q.agents, name],
              ),
            ),
            key: Key('log-agent-$name'),
          ),
        SideHead(l.deskTypeHead),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14),
          child: Wrap(
            children: [
              for (final t in _typeGroups)
                chip(
                  t,
                  _q.types.contains(t),
                  () => _set(
                    _q.copy(
                      types: _q.types.contains(t)
                          ? (List.of(_q.types)..remove(t))
                          : [..._q.types, t],
                    ),
                  ),
                  key: Key('log-type-$t'),
                ),
            ],
          ),
        ),
        SideHead(l.deskOnly),
        switchRow(
          l.deskOnlyErrors,
          _q.errors,
          () => _set(_q.copy(errors: !_q.errors)),
          key: const Key('log-only-errors'),
        ),
        switchRow(
          l.deskOnlyRequests,
          _q.requests,
          () => _set(_q.copy(requests: !_q.requests)),
          key: const Key('log-only-requests'),
        ),
        SideHead(l.deskWhen),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14),
          child: Wrap(
            children: [
              for (final (w, label) in [
                (LogWhen.hour, l.deskWhenHour),
                (LogWhen.today, l.deskWhenToday),
                (LogWhen.week, l.deskWhenWeek),
                (LogWhen.all, l.deskWhenAll),
              ])
                chip(label, _q.when == w, () => _set(_q.copy(when: w)), key: Key('log-when-${w.name}')),
            ],
          ),
        ),
      ],
    );
    final search = Padding(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 8),
      child: TextField(
        key: const Key('log-search'),
        controller: _field,
        onChanged: (v) => setState(() => _q = parseLogQuery(v)),
        style: mono.copyWith(color: c.text, fontSize: 13),
        decoration: InputDecoration(
          isDense: true,
          prefixIcon: Padding(
            padding: const EdgeInsets.all(9),
            child: RgIcon(RgIcons.search, size: 16, color: c.dim),
          ),
          prefixIconConstraints: const BoxConstraints(minWidth: 34),
          hintText: l.deskLogSearchHint,
          suffixText: _page == null ? null : l.deskOfTotal(events.length, _page!.events.length),
        ),
      ),
    );
    final head = TextStyle(fontSize: 11, letterSpacing: .5, fontWeight: FontWeight.w700, color: c.dim);
    Widget table;
    if (_page == null) {
      table = _error == null
          ? const Center(child: CircularProgressIndicator())
          : EmptyState(icon: RgIcons.alert, text: l.codeLoadFailed);
    } else if (events.isEmpty) {
      table = EmptyState(icon: RgIcons.activity, text: l.codeLogEmpty);
    } else {
      table = ListView.builder(
        key: const Key('log-table'),
        itemCount: events.length,
        itemExtent: 31,
        itemBuilder: (context, i) {
          final e = events[i];
          final a = app.agents.where((x) => x.id == e.agentId).firstOrNull;
          final sel = _sel?.seq == e.seq;
          final dur = e.payload is Map ? (e.payload! as Map)['output'] : null;
          final ms = dur is Map && dur['durationMs'] is num ? (dur['durationMs'] as num) / 1000 : null;
          return Material(
            color: sel ? c.accentSoft : (e.error ? c.criticalSoft : Colors.transparent),
            child: InkWell(
              key: Key('log-row-${e.seq}'),
              onTap: () => setState(() => _sel = e),
              child: Container(
                decoration: BoxDecoration(
                  border: Border(left: BorderSide(color: sel ? c.accent : Colors.transparent, width: 3)),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 10),
                child: Row(
                  children: [
                    SizedBox(width: 72, child: Text(clockShort(e.ts), style: mono)),
                    SizedBox(width: 56, child: Text('${e.seq}', style: mono)),
                    SizedBox(
                      width: 140,
                      child: Row(
                        children: [
                          if (a != null)
                            MascotView(agentId: a.id, spec: a.mascot, size: 18, label: a.name),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              e.agentName ?? '',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(fontSize: 12.5, color: c.text),
                            ),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(
                      width: 150,
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: EventType(type: e.type, error: e.error),
                      ),
                    ),
                    Expanded(
                      child: Text(
                        e.summary.replaceAll(RegExp(r'\s+'), ' '),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(fontSize: 12.5, color: c.text),
                      ),
                    ),
                    SizedBox(
                      width: 60,
                      child: Text(
                        ms == null ? '' : '${ms.toStringAsFixed(1)} s',
                        textAlign: TextAlign.right,
                        style: mono,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      );
    }
    final center = Column(
      children: [
        search,
        Container(
          padding: const EdgeInsets.fromLTRB(13, 4, 10, 6),
          decoration: BoxDecoration(border: Border(bottom: BorderSide(color: c.line))),
          child: Row(
            children: [
              SizedBox(width: 72, child: Text(l.deskColTime, style: head)),
              SizedBox(width: 56, child: Text('N.', style: head)),
              SizedBox(width: 140, child: Text(l.deskColAgent, style: head)),
              SizedBox(width: 150, child: Text(l.deskColType, style: head)),
              Expanded(child: Text(l.deskColSummary, style: head)),
              SizedBox(width: 60, child: Text(l.deskColDuration, style: head, textAlign: TextAlign.right)),
            ],
          ),
        ),
        Expanded(child: table),
      ],
    );
    final sel = _sel;
    final turn = sel == null
        ? const <ProjectEvent>[]
        : (_page?.events ?? const <ProjectEvent>[])
              .where((e) => e.sessionId == sel.sessionId && e.seq != sel.seq && (e.seq - sel.seq).abs() <= 12)
              .take(6)
              .toList();
    final right = sel == null
        ? EmptyState(icon: RgIcons.list, text: l.deskPickEvent)
        : ListView(
            key: const Key('log-detail'),
            padding: const EdgeInsets.all(14),
            children: [
              Row(
                children: [
                  EventType(type: sel.type, error: sel.error),
                  const SizedBox(width: 8),
                  Text(
                    l.deskEventN(sel.seq),
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: c.text),
                  ),
                  const Spacer(),
                  IconButton(
                    key: const Key('log-copy'),
                    tooltip: l.deskCopyJson,
                    onPressed: () => Clipboard.setData(
                      ClipboardData(
                        text: const JsonEncoder.withIndent('  ').convert({
                          'seq': sel.seq,
                          'type': sel.type,
                          'at': sel.ts,
                          'session': sel.sessionId,
                          'agent': sel.agentName,
                          'payload': sel.payload,
                        }),
                      ),
                    ),
                    icon: RgIcon(RgIcons.copy, size: 16, color: c.dim),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                [sel.agentName, sel.sessionId, clockShort(sel.ts)].whereType<String>().join(' · '),
                style: TextStyle(fontSize: 12.5, color: c.dim),
              ),
              Container(
                margin: const EdgeInsets.only(top: 10),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(color: c.code, borderRadius: BorderRadius.circular(8)),
                child: SelectableText(
                  sel.json,
                  key: const Key('log-json'),
                  style: const TextStyle(
                    fontFamily: monoFamily,
                    fontFamilyFallback: monoFallback,
                    fontSize: 12,
                    color: Color(0xFFE8E6E3),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  if (sel.sessionId != null)
                    FilledButton.icon(
                      key: const Key('log-open-chat'),
                      onPressed: () => desk.show(
                        PanelConversation(
                          sel.sessionId!,
                          agent: app.agents.where((x) => x.id == sel.agentId).firstOrNull,
                        ),
                      ),
                      icon: const RgIcon(RgIcons.chat, size: 15, color: Colors.white),
                      label: Text(l.codeLogOpenChat),
                    ),
                ],
              ),
              if (turn.isNotEmpty) ...[
                SideHead(l.deskSameTurn),
                for (final e in turn)
                  InkWell(
                    onTap: () => setState(() => _sel = e),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 3),
                      child: Row(
                        children: [
                          EventType(type: e.type, error: e.error),
                          const SizedBox(width: 6),
                          Text('${e.seq}', style: mono),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              e.summary,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(fontSize: 12.5, color: c.text),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ],
          );
    return Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          width: 220,
          decoration: BoxDecoration(border: Border(right: BorderSide(color: c.line))),
          child: left,
        ),
        Expanded(child: center),
        Container(
          width: 380,
          decoration: BoxDecoration(border: Border(left: BorderSide(color: c.line))),
          child: right,
        ),
      ],
    );
  }
}

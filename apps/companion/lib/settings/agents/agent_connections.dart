// 3.12.3: what an agent is connected to, native, as the page's AgentConnections.tsx: any number of
// mailboxes, chats, calendars and services, by kind, a switch for each. An agent sees only what is
// connected to it. [ConnectionsEditor] is the list (used in the agent's settings and in the new
// agent's steps); [AgentConnectionsGroup] is the agent's «Connections» group with its Save.
import 'dart:async';

import 'package:flutter/material.dart';

import '../../api/client.dart';
import '../../api/types.dart';
import '../../app_state.dart';
import '../../l10n/app_localizations.dart';
import '../../screens/new_agent_screen.dart' show RgSwitch;
import '../../theme/colors.dart';
import '../../ui/icons.dart';
import '../../ui/settings_kit.dart';
import '../api/agents_api.dart';
import 'assistant_parts.dart' show serviceName, serviceState;

/// The platform's name for a chat (telegram → Telegram).
String chatName(String p) => p.isEmpty ? p : p[0].toUpperCase() + p.substring(1);

class ConnectionsEditor extends StatefulWidget {
  const ConnectionsEditor({
    super.key,
    required this.value,
    required this.onChanged,
    this.readOnly = false,
  });

  final List<AgentConnection> value;
  final ValueChanged<List<AgentConnection>> onChanged;
  final bool readOnly;

  @override
  State<ConnectionsEditor> createState() => _ConnectionsEditorState();
}

class _ConnectionsEditorState extends State<ConnectionsEditor> {
  ConnectionOptions? _options;
  List<ServiceEntry>? _services;

  @override
  void initState() {
    super.initState();
    unawaited(_load());
  }

  Future<void> _load() async {
    final c = AppScope.read(context).client;
    if (c == null) return;
    Future<T?> soft<T>(Future<T> f) async {
      try {
        return await f;
      } on ApiException {
        return null;
      }
    }

    final r = await Future.wait<Object?>([
      soft(c.connectionOptions()),
      soft(c.assistantServices()),
    ]);
    if (!mounted) return;
    setState(() {
      _options = r[0] as ConnectionOptions? ?? const ConnectionOptions();
      _services = r[1] as List<ServiceEntry>? ?? const [];
    });
  }

  bool _has(String kind, String ref) => widget.value.any((c) => c.kind == kind && c.ref == ref);

  void _set(String kind, String ref, bool on) {
    final next = [...widget.value.where((c) => !(c.kind == kind && c.ref == ref))];
    if (on) next.add(AgentConnection(kind: kind, ref: ref));
    widget.onChanged(next);
  }

  Widget _row(
    String key, {
    required String title,
    String? text,
    Color? textColor,
    required bool on,
    required void Function(bool) onTap,
  }) {
    final c = RgColors.of(context);
    return InkWell(
      key: Key(key),
      onTap: widget.readOnly ? null : () => onTap(!on),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(fontWeight: FontWeight.w700, color: c.text),
                  ),
                  if (text != null)
                    Text(text, style: TextStyle(fontSize: 12.5, color: textColor ?? c.dim)),
                ],
              ),
            ),
            RgSwitch(on: on),
          ],
        ),
      ),
    );
  }

  /// Connected but not there any more: shown, so it can be switched off.
  Iterable<Widget> _gone(AppLocalizations l, String kind, Set<String> known) => [
    for (final g in widget.value.where((c) => c.kind == kind && !known.contains(c.ref)))
      _row(
        'conn-gone-$kind-${g.ref}',
        title: kind == 'mcp' ? serviceName(g.ref) : g.ref,
        text: l.sxConnGone,
        on: true,
        onTap: (_) => _set(kind, g.ref, false),
      ),
  ];

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final c = RgColors.of(context);
    final o = _options;
    final services = _services;
    if (o == null || services == null) {
      return const Padding(
        padding: EdgeInsets.all(16),
        child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
      );
    }
    Widget kind(String title, List<Widget> rows, String empty) => Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SectionHead(title),
        SettingsCard(
          children: rows.isEmpty ? [NoteLine(icon: RgIcons.info, text: empty)] : rows,
        ),
      ],
    );
    return Column(
      key: const Key('conn-editor'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        kind(l.sxConnMailboxes, [
          for (final b in o.mailboxes)
            _row(
              'conn-mailbox-${b.id}',
              title: b.name,
              text: b.address,
              on: _has('mailbox', b.id),
              onTap: (v) => _set('mailbox', b.id, v),
            ),
          ..._gone(l, 'mailbox', {for (final b in o.mailboxes) b.id}),
        ], l.sxConnNoMailboxes),
        kind(l.sxConnChats, [
          for (final ch in o.chats)
            _row(
              'conn-chat-$ch',
              title: chatName(ch),
              text: l.sxConnChatHelp,
              on: _has('chat', ch),
              onTap: (v) => _set('chat', ch, v),
            ),
          ..._gone(l, 'chat', o.chats.toSet()),
        ], l.sxConnNoChats),
        kind(l.sxConnCalendars, [
          for (final cal in o.calendars)
            _row(
              'conn-calendar-${cal.id}',
              title: cal.name,
              text: cal.writable ? l.sxConnWritable : l.sxConnReadOnly,
              on: _has('calendar', cal.id),
              onTap: (v) => _set('calendar', cal.id, v),
            ),
          ..._gone(l, 'calendar', {for (final cal in o.calendars) cal.id}),
        ], l.sxConnNoCalendars),
        kind(l.sxConnServices, [
          for (final s in services)
            _row(
              'conn-mcp-${s.name}',
              title: serviceName(s.name),
              text: serviceState(l, s),
              textColor: s.state == 'connected'
                  ? c.ok
                  : s.state == null
                  ? c.dim
                  : c.warn,
              on: _has('mcp', s.name),
              onTap: (v) => _set('mcp', s.name, v),
            ),
          ..._gone(l, 'mcp', {for (final s in services) s.name}),
        ], l.g4AgNoServices),
        NoteLine(icon: RgIcons.info, text: l.g4AgAddServiceHint),
      ],
    );
  }
}

/// The agent's «Connections» group: the list and Save.
class AgentConnectionsGroup extends StatefulWidget {
  const AgentConnectionsGroup({super.key, required this.agent, this.readOnly = false});

  final Agent agent;
  final bool readOnly;

  @override
  State<AgentConnectionsGroup> createState() => _AgentConnectionsGroupState();
}

class _AgentConnectionsGroupState extends State<AgentConnectionsGroup> {
  late List<AgentConnection> _value = [...widget.agent.connections];
  String? _said;
  bool _bad = false;

  bool get _changed {
    final was = widget.agent.connections.toSet();
    return was.length != _value.length || !was.containsAll(_value);
  }

  Future<void> _save() async {
    final l = AppLocalizations.of(context);
    final why = await AppScope.read(context).saveAgent(widget.agent, {
      'connections': [for (final c in _value) c.toJson()],
    });
    if (!mounted) return;
    setState(() {
      _said = why == null ? l.sxConnSaved : l.asRefused(why);
      _bad = why != null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return Column(
      key: const Key('as-connections'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (_said != null)
          NoticeBanner(key: const Key('as-connections-note'), text: _said!, error: _bad),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 0),
          child: Text(
            l.sxConnHelp,
            style: TextStyle(fontSize: 13, color: RgColors.of(context).dim),
          ),
        ),
        ConnectionsEditor(
          value: _value,
          readOnly: widget.readOnly,
          onChanged: (v) => setState(() {
            _said = null;
            _value = v;
          }),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
          child: Align(
            alignment: Alignment.centerRight,
            child: FilledButton(
              key: const Key('as-save-connections'),
              onPressed: !widget.readOnly && _changed ? _save : null,
              child: Text(l.save),
            ),
          ),
        ),
      ],
    );
  }
}

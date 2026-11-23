// 3.12.3: the calendars, native, as the page's CalendarSettings.tsx: on Settings › Automations one
// square per calendar and «Add a calendar»; each opens its window: the kind (CalDAV, or a read-only
// iCal address), the name, the address, the user and password (CalDAV), «Agents may use it». A new
// calendar is tried before it is kept; the secret goes to the keychain and never comes back (an
// iCal address is shown only by its host). Writing to Google with a sign-in is not part of this.
import 'dart:async';

import 'package:flutter/material.dart';

import '../../api/client.dart';
import '../../app_state.dart';
import '../../l10n/app_localizations.dart';
import '../../theme/colors.dart';
import '../../ui/icons.dart';
import '../automations/automation_kit.dart' show AutoChips;
import '../knowledge_kit.dart';
import '../rules_kit.dart';

/// One calendar as the server shows it (never its secret).
class CalendarInfo {
  const CalendarInfo({
    required this.id,
    required this.name,
    required this.kind,
    required this.url,
    this.user,
    required this.writable,
    required this.agents,
  });

  factory CalendarInfo.fromJson(Map<String, dynamic> j) => CalendarInfo(
    id: '${j['id']}',
    name: '${j['name'] ?? ''}',
    kind: j['kind'] == 'ics' ? 'ics' : 'caldav',
    url: '${j['url'] ?? ''}',
    user: j['user'] as String?,
    writable: j['writable'] == true,
    agents: j['agents'] == true,
  );

  final String id;
  final String name;

  /// `caldav` or `ics`.
  final String kind;
  final String url;
  final String? user;
  final bool writable;
  final bool agents;
}

extension CalendarsApi on RedGiantClient {
  /// `GET /api/settings/calendars`.
  Future<List<CalendarInfo>> calendarList() async {
    final j = objectOf(await getJson('/api/settings/calendars'));
    return [
      for (final o in j['calendars'] is List ? j['calendars'] as List : const [])
        if (o is Map<String, dynamic>) CalendarInfo.fromJson(o),
    ];
  }

  /// `POST /api/settings/calendars`: a new calendar, tried before it is kept.
  Future<void> addCalendar(Map<String, Object?> b) =>
      callJson('POST', '/api/settings/calendars', b);

  /// `PUT /api/settings/calendars/:id`: the name and «Agents may use it».
  Future<void> updateCalendar(String id, Map<String, Object?> b) =>
      callJson('PUT', '/api/settings/calendars/${Uri.encodeComponent(id)}', b);

  /// `DELETE /api/settings/calendars/:id`.
  Future<void> removeCalendar(String id) =>
      callJson('DELETE', '/api/settings/calendars/${Uri.encodeComponent(id)}');
}

String calendarState(AppLocalizations l, String kind) =>
    kind == 'ics' ? l.sxCalState_ics : l.sxCalState_caldav;

class CalendarsSection extends StatefulWidget {
  const CalendarsSection({super.key});

  @override
  State<CalendarsSection> createState() => _CalendarsSectionState();
}

class _CalendarsSectionState extends State<CalendarsSection> {
  List<CalendarInfo>? _list;

  @override
  void initState() {
    super.initState();
    unawaited(_load());
  }

  Future<void> _load() async {
    final c = AppScope.read(context).client;
    if (c == null) return;
    List<CalendarInfo> list = const [];
    try {
      list = await c.calendarList();
    } on Object {
      // None to show.
    }
    if (mounted) setState(() => _list = list);
  }

  Future<void> _open(CalendarInfo? cal) async {
    final l = AppLocalizations.of(context);
    await kbWindow<void>(
      context,
      key: Key('calendar-window-${cal?.id ?? 'new'}'),
      title: cal?.name ?? l.sxCalNew,
      wide: true,
      body: (ctx, close) => CalendarEditor(cal: cal, onDone: close),
    );
    await _load();
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final list = _list;
    if (list == null) return const RulesLoading(key: Key('au-calendars'));
    return KbTiles(
      key: const Key('au-calendars'),
      children: [
        for (final cal in list)
          KbTile(
            key: Key('calendar-${cal.id}'),
            icon: RgIcons.clock,
            title: cal.name,
            text: cal.url,
            on: true,
            state: calendarState(l, cal.kind),
            onTap: () => _open(cal),
          ),
        KbTile(
          key: const Key('calendar-add'),
          icon: RgIcons.plus,
          title: l.sxCalAdd,
          text: l.sxCalAddText,
          on: false,
          onTap: () => _open(null),
        ),
      ],
    );
  }
}

class CalendarEditor extends StatefulWidget {
  const CalendarEditor({super.key, required this.cal, required this.onDone});

  final CalendarInfo? cal;
  final void Function([void]) onDone;

  @override
  State<CalendarEditor> createState() => _CalendarEditorState();
}

class _CalendarEditorState extends State<CalendarEditor> {
  late final _name = TextEditingController(text: widget.cal?.name ?? '');
  late String _kind = widget.cal?.kind ?? 'caldav';
  final _url = TextEditingController();
  final _user = TextEditingController();
  final _password = TextEditingController();
  late bool _agents = widget.cal?.agents ?? false;
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    for (final c in [_name, _url, _user, _password]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _save() async {
    final c = AppScope.read(context).client;
    if (c == null) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final cal = widget.cal;
      if (cal != null) {
        await c.updateCalendar(cal.id, {'name': _name.text.trim(), 'agents': _agents});
      } else {
        await c.addCalendar({
          'name': _name.text.trim(),
          'kind': _kind,
          'url': _url.text.trim(),
          if (_kind == 'caldav') ...{'user': _user.text.trim(), 'password': _password.text},
          'agents': _agents,
        });
      }
      _password.clear();
      widget.onDone();
    } on Object catch (e) {
      if (mounted) setState(() => _error = rulesWhy(e));
    }
    if (mounted) setState(() => _busy = false);
  }

  Future<void> _remove() async {
    final c = AppScope.read(context).client;
    final cal = widget.cal;
    if (c == null || cal == null) return;
    try {
      await c.removeCalendar(cal.id);
      widget.onDone();
    } on Object catch (e) {
      if (mounted) setState(() => _error = rulesWhy(e));
    }
  }

  Widget _field(
    String k,
    String label,
    TextEditingController c, {
    String? help,
    String? hint,
    bool secret = false,
  }) => Padding(
    padding: const EdgeInsets.only(top: 10),
    child: TextField(
      key: Key(k),
      controller: c,
      obscureText: secret,
      autocorrect: false,
      enableSuggestions: !secret,
      onChanged: (_) => setState(() {}),
      decoration: InputDecoration(
        labelText: label,
        helperText: help,
        hintText: hint,
        helperMaxLines: 3,
      ),
    ),
  );

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final c = RgColors.of(context);
    final cal = widget.cal;
    final ready =
        cal != null ||
        (_url.text.trim().length > 8 &&
            (_kind == 'ics' || (_user.text.trim().isNotEmpty && _password.text.isNotEmpty)));
    return Column(
      key: const Key('calendar-editor'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        KbLine(l.sxCalPurpose),
        if (cal == null) ...[
          Padding(
            padding: const EdgeInsets.only(top: 14, bottom: 6),
            child: Text(
              l.sxCalKind,
              style: TextStyle(fontWeight: FontWeight.w700, color: c.text),
            ),
          ),
          AutoChips<String>(
            options: [('caldav', l.sxCalKind_caldav), ('ics', l.sxCalKind_ics)],
            value: [_kind],
            keyOf: (x) => 'cal-kind-$x',
            onChanged: (v) => setState(() {
              if (v.isNotEmpty) _kind = v.first;
            }),
          ),
        ],
        _field('cal-name', l.sxCalName, _name, help: l.sxCalNameHelp),
        if (cal == null && _kind == 'caldav') ...[
          _field(
            'cal-url',
            l.sxCalUrlCaldav,
            _url,
            help: l.sxCalUrlCaldavHelp,
            hint: 'https://caldav.example.com/calendars/me/home/',
          ),
          _field('cal-user', l.sxCalUser, _user),
          _field(
            'cal-password',
            l.sxCalPassword,
            _password,
            help: l.sxCalPasswordHelp,
            secret: true,
          ),
        ],
        if (cal == null && _kind == 'ics') ...[
          _field('cal-url', l.sxCalUrlIcs, _url, help: l.sxCalUrlIcsHelp),
          KbLine(l.sxCalGoogleNote),
        ],
        if (cal != null) KbLine(calendarState(l, cal.kind)),
        const SizedBox(height: 8),
        KbSwitchRow(
          key: const Key('cal-agents'),
          title: l.sxCalAgents,
          help: l.sxCalAgentsHelp,
          on: _agents,
          onChanged: (v) => setState(() => _agents = v),
        ),
        if (_error != null) KbLine(_error!, error: true),
        KbActs(
          children: [
            if (cal != null)
              TextButton(
                key: const Key('cal-remove'),
                onPressed: _busy ? null : _remove,
                child: Text(l.sxCalRemove, style: TextStyle(color: c.err)),
              ),
            FilledButton(
              key: const Key('cal-save'),
              onPressed: _busy || !ready ? null : _save,
              child: Text(_busy ? l.sxCalTesting : (cal != null ? l.save : l.sxCalSave)),
            ),
          ],
        ),
      ],
    );
  }
}

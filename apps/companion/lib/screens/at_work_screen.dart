// «Agenti al lavoro insieme, al massimo» (3.8.10), native: the person's limit of turns at work at
// once (`maxAtWork` in `/api/settings/commands`, saved with the other limits as they are) and,
// under it, the queue as it is now. The page has the same in Settings > Commands.
import 'dart:async';

import 'package:flutter/material.dart';

import '../api/client.dart';
import '../app_state.dart';
import '../l10n/app_localizations.dart';
import '../theme/colors.dart';
import '../ui/icons.dart';
import '../ui/settings_kit.dart';
import '../ui/turn_queue_view.dart';

/// The ready choices (null: no limit).
const atWorkChoices = <int?>[null, 1, 2, 3, 4, 6, 8, 12, 20];

/// Opens the screen: a panel over the window on a computer, a whole screen on a phone.
Future<void> openAtWork(BuildContext context) =>
    Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => const AtWorkScreen()));

/// The limit in words, for the row that opens this screen.
String atWorkSummary(AppLocalizations l, int? limit) =>
    limit == null ? l.atWorkNoLimit : l.atWorkSummary(limit);

class AtWorkScreen extends StatefulWidget {
  const AtWorkScreen({super.key});

  @override
  State<AtWorkScreen> createState() => _AtWorkScreenState();
}

class _AtWorkScreenState extends State<AtWorkScreen> {
  Map<String, dynamic>? _settings;
  String? _said;
  String? _error;

  @override
  void initState() {
    super.initState();
    unawaited(_load());
  }

  Future<void> _load() async {
    final app = AppScope.read(context);
    final c = app.client;
    if (c == null) return;
    unawaited(app.refreshTurns());
    try {
      final s = await c.commandSettings();
      if (mounted) setState(() => _settings = s);
    } on ApiException catch (e) {
      if (mounted) setState(() => _error = e.message);
    }
  }

  int? get _limit => (_settings?['maxAtWork'] as num?)?.toInt();

  Future<void> _pick(int? v) async {
    final l = AppLocalizations.of(context);
    final c = AppScope.read(context).client;
    final s = _settings;
    if (c == null || s == null || v == _limit) return;
    final next = {...s, 'maxAtWork': v};
    setState(() {
      _settings = next;
      _said = null;
      _error = null;
    });
    try {
      await c.setCommandSettings(next);
      if (mounted) setState(() => _said = l.atWorkSaved);
    } on ApiException catch (e) {
      if (mounted) {
        setState(() {
          _settings = s;
          _error = l.errGeneric(e.message);
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final c = RgColors.of(context);
    final limit = _limit;
    final choices = [...atWorkChoices, if (!atWorkChoices.contains(limit)) limit];
    return SettingsScaffold(
      title: l.atWorkTitle,
      backKey: const Key('at-work-back'),
      backLabel: l.back,
      listKey: const Key('at-work'),
      children: [
        if (_error != null) NoticeBanner(text: _error!, error: true),
        if (_said != null) NoticeBanner(text: _said!),
        SectionHead(l.atWorkAtMost),
        SettingsCard(
          children: [
            NoteLine(icon: RgIcons.users, text: l.atWorkHelp),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 2, 16, 14),
              child: _settings == null
                  ? Text(l.loading, style: TextStyle(color: c.dim))
                  : Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        for (final v in choices)
                          ChoiceChip(
                            key: Key('at-work-${v ?? 'none'}'),
                            showCheckmark: false,
                            label: Text(v == null ? l.atWorkNoLimit : '$v'),
                            selected: v == limit,
                            selectedColor: c.accentSoft,
                            side: BorderSide(color: v == limit ? c.accent : c.line),
                            labelStyle: TextStyle(
                              color: v == limit ? c.accent : c.text,
                              fontWeight: v == limit ? FontWeight.w700 : FontWeight.w500,
                            ),
                            onSelected: (_) => _pick(v),
                          ),
                      ],
                    ),
            ),
            if (_settings != null)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
                child: Text(
                  limit == null ? l.atWorkNoLimitHint : l.atWorkSummary(limit),
                  style: TextStyle(color: c.dim, fontSize: 12.5),
                ),
              ),
          ],
        ),
        SectionHead(l.atWorkNow),
        const SettingsCard(
          children: [Padding(padding: EdgeInsets.only(top: 8, bottom: 4), child: TurnQueueList())],
        ),
      ],
    );
  }
}

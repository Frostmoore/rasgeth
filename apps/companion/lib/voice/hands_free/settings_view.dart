// Hands-free voice (G42.16): its part of Settings › Voice, as the page's VoiceSettings.tsx: on
// this device or not, the wake word (the person's own, checked with the server's speech model),
// sensitivity, the language, who writes down what is said (the server's transcription, General's
// panel), the follow-up window, speaking over the answer, where what is said goes, and how it
// works on this device. Who reads and how loud stay in [VoiceScreen]'s own part (G40.10).
import 'dart:async';

import 'package:flutter/material.dart';

import '../../api/client.dart';
import '../../app_state.dart';
import '../../l10n/app_localizations.dart';
import '../../screens/new_agent_screen.dart' show RgSwitch;
import '../../settings/general_screen.dart' show openTranscriptionPanel;
import '../../theme/colors.dart';
import '../../ui/icons.dart';
import '../../ui/model_sheet.dart' show ChoiceRow;
import '../../ui/settings_kit.dart';
import 'indicator.dart';
import 'runtime.dart';
import 'settings.dart';
import 'wake.dart';

/// The top of Settings › Voice: hands-free on this device, the wake word, the language, the
/// transcription.
class HandsFreeSection extends StatefulWidget {
  const HandsFreeSection({super.key});

  @override
  State<HandsFreeSection> createState() => _HandsFreeSectionState();
}

class _HandsFreeSectionState extends State<HandsFreeSection> {
  late final AppController app = AppScope.read(context);
  ({bool? transcription, String? name})? _stt;
  final _wakeText = TextEditingController();
  WakeLang? _textFor;
  ({bool ok, String text})? _wakeResult;
  bool _checking = false;

  HandsFreeRuntime get r => app.handsFree;

  @override
  void initState() {
    super.initState();
    unawaited(_loadStt());
  }

  @override
  void dispose() {
    _wakeText.dispose();
    super.dispose();
  }

  Future<void> _loadStt() async {
    final c = app.client;
    if (c == null) return;
    try {
      final s = await c.setupSummary();
      if (mounted) setState(() => _stt = (transcription: s.transcription != null, name: s.transcription));
    } on ApiException {
      if (mounted) setState(() => _stt = (transcription: null, name: null));
    }
  }

  void _set(HandsFreeSettings next) => unawaited(r.update(next));

  Future<void> _useWake(String value) async {
    final s = r.settings;
    final lang = s.lang;
    setState(() => _wakeResult = null);
    final problem = wakeProblem(lang, value);
    if (problem != null) {
      setState(() => _wakeResult = (ok: false, text: hfWord(context, 'vcWakeProblem_$problem')));
      return;
    }
    if (customWake(lang, value) == null) {
      _set(s.copyWith(wakeWords: {...s.wakeWords}..remove(lang)));
      _wakeText.text = wakeLabel(lang, null);
      setState(
        () => _wakeResult = (
          ok: true,
          text: hfWord(context, 'vcWakeSaved', {'wake': wakeLabel(lang, null)}),
        ),
      );
      return;
    }
    final c = app.client;
    if (c == null) return;
    setState(() => _checking = true);
    try {
      final check = await c.wakeWords(lang, spokenWake(value).split(' '));
      if (!mounted) return;
      if (!check.ready) {
        setState(() => _wakeResult = (ok: false, text: hfWord(context, 'vcWakeNeedsModel')));
        return;
      }
      if (check.missing.isNotEmpty) {
        setState(
          () => _wakeResult = (
            ok: false,
            text: hfWord(context, 'vcWakeUnknown', {
              'words': check.missing.map((w) => '«$w»').join(', '),
              'lang': hfWord(context, lang == WakeLang.it ? 'vcLangIt' : 'vcLangEn'),
            }),
          ),
        );
        return;
      }
      _set(s.copyWith(wakeWords: {...s.wakeWords, lang: value.trim()}));
      setState(
        () => _wakeResult = (ok: true, text: hfWord(context, 'vcWakeSaved', {'wake': value.trim()})),
      );
    } on ApiException catch (e) {
      if (mounted) setState(() => _wakeResult = (ok: false, text: e.message));
    } finally {
      if (mounted) setState(() => _checking = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return ListenableBuilder(
      listenable: r,
      builder: (context, _) {
        final c = RgColors.of(context);
        final s = r.settings;
        String w(String k, [Map<String, String> v = const {}]) => hfWord(context, k, v);
        if (_textFor != s.lang) {
          _textFor = s.lang;
          _wakeText.text = s.currentWake;
          _wakeResult = null;
        }
        final sens = (s.sensitivity * 4).round() + 1;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
              child: Text(
                w('vcLead', {'wake': s.currentWake}),
                style: TextStyle(color: c.dim, fontSize: 13.5, height: 1.35),
              ),
            ),
            if (_stt?.transcription == false)
              NoticeBanner(
                key: const Key('hf-no-stt'),
                text: w('vcNoTranscription'),
                error: true,
              ),
            const SizedBox(height: 10),
            SettingsCard(
              children: [
                _SwitchLine(
                  key: const Key('hf-enabled'),
                  title: w('vcEnabled'),
                  help: w('vcEnabledHelp'),
                  on: s.enabled,
                  onChanged: (on) => _set(s.copyWith(enabled: on)),
                ),
              ],
            ),
            SectionHead(w('vcWakeTitle')),
            SettingsCard(
              children: [
                _SwitchLine(
                  key: const Key('hf-wake'),
                  title: w('vcWake', {'wake': s.currentWake}),
                  help: r.wakeHeard ? w('vcWakeWordHelp') : l.hfWakeNotHere,
                  on: s.wake,
                  onChanged: (on) => _set(s.copyWith(wake: on)),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    spacing: 8,
                    children: [
                      Row(
                        spacing: 8,
                        children: [
                          Expanded(
                            child: TextField(
                              key: const Key('hf-wake-word'),
                              controller: _wakeText,
                              maxLength: 40,
                              decoration: InputDecoration(
                                labelText: w('vcWakeWord'),
                                counterText: '',
                              ),
                              onSubmitted: (v) => unawaited(_useWake(v)),
                            ),
                          ),
                          FilledButton(
                            key: const Key('hf-wake-use'),
                            onPressed: _checking ? null : () => unawaited(_useWake(_wakeText.text)),
                            child: Text(w('vcWakeUse')),
                          ),
                        ],
                      ),
                      Text(w('vcWakeExamples'), style: TextStyle(color: c.dim, fontSize: 12.5)),
                      ChoiceRow(
                        keyPrefix: 'hf-wake-example',
                        values: wakeExamples[s.lang]!,
                        selected: s.currentWake,
                        label: (x) => x,
                        onChanged: (x) {
                          _wakeText.text = x;
                          unawaited(_useWake(x));
                        },
                      ),
                      if (_wakeResult != null)
                        Text(
                          _wakeResult!.text,
                          key: const Key('hf-wake-result'),
                          style: TextStyle(color: _wakeResult!.ok ? c.ok : c.err),
                        ),
                      Text(l.hfWakeHelp, style: TextStyle(color: c.dim, fontSize: 12.5)),
                    ],
                  ),
                ),
              ],
            ),
            SectionHead(w('vcSensitivity')),
            _Steps(
              key: const Key('hf-sensitivity'),
              value: sens,
              min: 1,
              max: 5,
              label: (v) => w('vcSens$v'),
              help: w('vcSensitivityHelp'),
              onChanged: (v) => _set(s.copyWith(sensitivity: (v - 1) / 4)),
            ),
            SectionHead(w('vcLangTitle')),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: ChoiceRow(
                keyPrefix: 'hf-lang',
                values: const ['it', 'en'],
                selected: s.lang.name,
                label: (x) => w(x == 'it' ? 'vcLangIt' : 'vcLangEn'),
                onChanged: (x) => _set(s.copyWith(lang: wakeLangOf(x))),
              ),
            ),
            SectionHead(w('vcSttTitle')),
            SettingsCard(
              children: [
                ListTile(
                  key: const Key('hf-stt'),
                  leading: RgIcon(RgIcons.mic, color: c.accent),
                  title: Text(l.hfSttRow),
                  subtitle: Text(
                    [
                      w('vcSttLead'),
                      _stt?.name ?? (_stt?.transcription == false ? l.hfSttNone : ''),
                    ].where((x) => x.isNotEmpty).join('\n'),
                  ),
                  trailing: RgIcon(RgIcons.chevronRight, color: c.dim),
                  onTap: () async {
                    await openTranscriptionPanel(context);
                    if (mounted) await _loadStt();
                  },
                ),
              ],
            ),
          ],
        );
      },
    );
  }
}

/// The bottom of Settings › Voice: the conversation by voice and how it works here.
class HandsFreeTalkSection extends StatelessWidget {
  const HandsFreeTalkSection({super.key});

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    final r = app.handsFree;
    final l = AppLocalizations.of(context);
    return ListenableBuilder(
      listenable: r,
      builder: (context, _) {
        final c = RgColors.of(context);
        final s = r.settings;
        String w(String k, [Map<String, String> v = const {}]) => hfWord(context, k, v);
        final recent = [
          for (final x in app.live.sessions)
            if (!x.archived) x,
        ]..sort((a, b) => b.when.compareTo(a.when));
        final shown = recent.take(8).toList();
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SectionHead(w('vcTalkTitle')),
            _Steps(
              key: const Key('hf-followup'),
              value: s.followupSec,
              min: 0,
              max: 20,
              label: (v) => v == 0 ? w('vcFollowupOff') : w('vcSeconds', {'n': '$v'}),
              help: w('vcFollowupHelp'),
              title: w('vcFollowup'),
              onChanged: (v) => unawaited(r.update(s.copyWith(followupSec: v))),
            ),
            const SizedBox(height: 8),
            SettingsCard(
              children: [
                _SwitchLine(
                  key: const Key('hf-barge'),
                  title: w('vcBargeIn'),
                  help: w('vcBargeInHelp'),
                  on: s.bargeIn,
                  onChanged: (on) => unawaited(r.update(s.copyWith(bargeIn: on))),
                ),
              ],
            ),
            SectionHead(w('vcTarget')),
            SettingsCard(
              children: [
                PickRow(
                  key: const Key('hf-target-open'),
                  title: w('vcTargetOpen'),
                  selected: !s.target.fixed,
                  onTap: () => unawaited(r.update(s.copyWith(target: const HandsFreeTarget.open()))),
                ),
                PickRow(
                  key: const Key('hf-target-fixed'),
                  title: w('vcTargetFixed'),
                  subtitle: s.target.fixed && s.target.title.isNotEmpty ? s.target.title : null,
                  selected: s.target.fixed,
                  onTap: shown.isEmpty
                      ? null
                      : () => unawaited(
                          r.update(
                            s.copyWith(
                              target: HandsFreeTarget.session(shown.first.id, shown.first.title ?? ''),
                            ),
                          ),
                        ),
                ),
              ],
            ),
            if (s.target.fixed) ...[
              SectionHead(l.hfPickConversation),
              SettingsCard(
                children: [
                  if (shown.isEmpty)
                    NoteLine(icon: RgIcons.chat, text: l.hfNoRecent)
                  else
                    for (final x in shown)
                      PickRow(
                        key: Key('hf-target-${x.id}'),
                        title: x.title?.isNotEmpty ?? false ? x.title! : l.tabChat,
                        selected: s.target.sessionId == x.id,
                        onTap: () => unawaited(
                          r.update(s.copyWith(target: HandsFreeTarget.session(x.id, x.title ?? ''))),
                        ),
                      ),
                ],
              ),
            ],
            SectionHead(w('vcLimitsTitle')),
            SettingsCard(
              key: const Key('hf-limits'),
              children: [
                NoteLine(icon: RgIcons.lock, text: l.hfLimitPrivacy),
                NoteLine(icon: RgIcons.phone, text: l.hfLimitAndroid),
                NoteLine(icon: RgIcons.monitor, text: l.hfLimitOthers),
                NoteLine(icon: RgIcons.speaker, text: l.voiceTalkWhere),
              ],
            ),
          ],
        );
      },
    );
  }
}

class _SwitchLine extends StatelessWidget {
  const _SwitchLine({
    super.key,
    required this.title,
    required this.help,
    required this.on,
    required this.onChanged,
  });

  final String title;
  final String help;
  final bool on;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final c = RgColors.of(context);
    return InkWell(
      onTap: () => onChanged(!on),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          spacing: 12,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                spacing: 2,
                children: [
                  Text(title, style: TextStyle(color: c.text, fontWeight: FontWeight.w700)),
                  Text(help, style: TextStyle(color: c.dim, fontSize: 12.5)),
                ],
              ),
            ),
            RgSwitch(on: on),
          ],
        ),
      ),
    );
  }
}

/// A few steps on a line (the page's Slider), with the step's word.
class _Steps extends StatelessWidget {
  const _Steps({
    super.key,
    required this.value,
    required this.min,
    required this.max,
    required this.label,
    required this.help,
    required this.onChanged,
    this.title,
  });

  final int value;
  final int min;
  final int max;
  final String Function(int) label;
  final String help;
  final String? title;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    final c = RgColors.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (title != null)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
            child: Text(title!, style: TextStyle(color: c.text, fontWeight: FontWeight.w600)),
          ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: Row(
            children: [
              Expanded(
                child: Slider(
                  min: min.toDouble(),
                  max: max.toDouble(),
                  divisions: max - min,
                  value: value.clamp(min, max).toDouble(),
                  label: label(value),
                  onChanged: (x) => onChanged(x.round()),
                ),
              ),
              SizedBox(
                width: 120,
                child: Text(
                  label(value),
                  textAlign: TextAlign.right,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(color: c.text, fontWeight: FontWeight.w600),
                ),
              ),
              const SizedBox(width: 8),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
          child: Text(help, style: TextStyle(color: c.dim, fontSize: 12.5)),
        ),
      ],
    );
  }
}

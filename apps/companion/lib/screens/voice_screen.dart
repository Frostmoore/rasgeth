// Tu › Voce (G40.10): who reads the answers aloud on this device (a provider whose key RedGiant
// keeps, through `POST /api/voice/speech`, the same as the page), with its model, its voice and
// the volume; and where «press and talk» is written down (RedGiant's transcription).
import 'dart:async';

import 'package:flutter/material.dart';

import '../app_state.dart';
import '../l10n/app_localizations.dart';
import '../theme/colors.dart';
import '../ui/icons.dart';
import '../ui/model_sheet.dart' show ChoiceRow;
import '../ui/settings_kit.dart';
import '../voice/hands_free/settings_view.dart';
import '../voice/voice_types.dart';

class VoiceScreen extends StatefulWidget {
  const VoiceScreen({super.key});

  @override
  State<VoiceScreen> createState() => _VoiceScreenState();
}

class _VoiceScreenState extends State<VoiceScreen> {
  late final AppController app;

  @override
  void initState() {
    super.initState();
    app = AppScope.read(context);
    unawaited(app.voice.loadKeys());
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final c = RgColors.of(context);
    final v = app.voice;
    return ListenableBuilder(
      listenable: v,
      builder: (context, _) {
        final available = v.available;
        final r = v.reader;
        final provider = available.where((p) => p.id == r?.provider).firstOrNull;
        final model = provider?.models.where((m) => m.id == r?.model).firstOrNull;
        return SettingsScaffold(
          title: l.voiceTitle,
          backKey: const Key('voice-back'),
          backLabel: l.back,
          listKey: const Key('voice-list'),
          children: [
            if (v.problem != null)
              NoticeBanner(key: const Key('voice-said'), text: v.problem!, error: true),
            // G42.16: hands-free voice, as the page's Settings › Voice (its top part).
            const HandsFreeSection(),
            SectionHead(l.voiceReaderHead),
            if (v.keyed == null)
              NoteLine(icon: RgIcons.spinner, text: l.loading)
            else if (available.isEmpty)
              SettingsCard(
                key: const Key('voice-no-reader'),
                children: [
                  NoteLine(icon: RgIcons.volume, strong: true, text: l.voiceNoReader),
                  NoteLine(icon: RgIcons.settings, text: l.voiceNoReaderHow),
                ],
              )
            else ...[
              SettingsCard(
                key: const Key('voice-providers'),
                children: [
                  for (final p in available)
                    PickRow(
                      key: Key('reader-${p.id}'),
                      title: p.name,
                      selected: p.id == r?.provider,
                      onTap: () => v.setReader(
                        ReaderChoice(
                          provider: p.id,
                          model: p.models.first.id,
                          voice: p.models.first.voices.firstOrNull?.id,
                        ),
                      ),
                    ),
                ],
              ),
              if (provider != null && r != null) ...[
                SectionHead(l.voiceModelHead),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: ChoiceRow(
                    keyPrefix: 'voice-model',
                    values: [for (final m in provider.models) m.id],
                    selected: r.model,
                    label: (id) => provider.models.firstWhere((m) => m.id == id).label,
                    onChanged: (id) {
                      final m = provider.models.firstWhere((x) => x.id == id);
                      final keep = m.voices.any((x) => x.id == r.voice);
                      unawaited(
                        v.setReader(
                          ReaderChoice(
                            provider: provider.id,
                            model: id,
                            voice: keep ? r.voice : m.voices.firstOrNull?.id,
                          ),
                        ),
                      );
                    },
                  ),
                ),
                if (model != null && model.voices.isNotEmpty) ...[
                  SectionHead(l.voiceVoiceHead),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: ChoiceRow(
                      keyPrefix: 'voice-voice',
                      values: [for (final x in model.voices) x.id],
                      selected: r.voice,
                      label: (id) => model.voices.firstWhere((x) => x.id == id).label,
                      onChanged: (id) => unawaited(
                        v.setReader(
                          ReaderChoice(provider: provider.id, model: model.id, voice: id),
                        ),
                      ),
                    ),
                  ),
                ] else if (model != null)
                  NoteLine(icon: RgIcons.user, text: l.voiceAccountVoice),
              ],
              SectionHead(l.voiceVolumeHead),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Row(
                  children: [
                    Expanded(
                      child: Slider(
                        key: const Key('voice-volume'),
                        min: kMinVolume.toDouble(),
                        max: kMaxVolume.toDouble(),
                        divisions: (kMaxVolume - kMinVolume) ~/ 5,
                        value: v.settings.volume.toDouble(),
                        label: '${v.settings.volume}%',
                        onChanged: (x) => unawaited(v.setVolume(x.round())),
                      ),
                    ),
                    SizedBox(
                      width: 52,
                      child: Text(
                        '${v.settings.volume}%',
                        textAlign: TextAlign.right,
                        style: TextStyle(color: c.text, fontWeight: FontWeight.w600),
                      ),
                    ),
                    const SizedBox(width: 8),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
                child: Text(l.voiceVolumeHint, style: TextStyle(color: c.dim, fontSize: 12.5)),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: OutlinedButton.icon(
                    key: const Key('voice-try'),
                    onPressed: () => unawaited(v.speak('voice-try', l.voiceTrySentence, l)),
                    icon: RgIcon(
                      v.speaking == 'voice-try' ? RgIcons.stop : RgIcons.volume,
                      size: 18,
                      color: c.accent,
                    ),
                    label: Text(v.speaking == 'voice-try' ? l.voiceStop : l.voiceTry),
                  ),
                ),
              ),
            ],
            SectionHead(l.voiceTalkHead),
            SettingsCard(
              children: [
                NoteLine(icon: RgIcons.mic, text: l.voiceTalkWhat),
                NoteLine(icon: RgIcons.settings, text: l.voiceTalkWhere),
              ],
            ),
            // G42.16: the conversation by voice and how it works on this device.
            const HandsFreeTalkSection(),
          ],
        );
      },
    );
  }
}

/// Settings › Voice (G42.16: from hands-free's indicator too).
Future<void> openVoiceSettings(BuildContext context) =>
    Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => const VoiceScreen()));

// Hands-free voice (G42.16): the indicator at the top, as the page's VoiceIndicator.tsx. While
// hands-free is on it is always there and says what the app is doing with the microphone:
// listening to the person, writing it down, waiting for the answer, speaking, paused. Never
// silently. A tap opens what the page's pop-over has: the state, what was heard, the error, «Talk
// now» or «Stop», «Switch off» and the voice settings.
import 'dart:async';

import 'package:flutter/material.dart';

import '../../api/types.dart' show DevicePlatform;
import '../../app_state.dart';
import '../../l10n/app_localizations.dart';
import '../../theme/colors.dart';
import '../../ui/dialogs.dart' show showRgWindow;
import '../../ui/icons.dart';
import 'hf_words.g.dart';
import 'machine.dart';
import 'runtime.dart';

/// A word of the page's voice, in the interface's language, with its {names} filled.
String hfWord(BuildContext context, String key, [Map<String, String> vars = const {}]) {
  final lang = Localizations.localeOf(context).languageCode == 'it' ? 'it' : 'en';
  var s = hfWords[lang]![key] ?? hfWords['en']![key] ?? key;
  vars.forEach((k, v) => s = s.replaceAll('{$k}', v));
  return s;
}

enum HfTone { dim, on, hot, busy, error }

typedef HfLook = ({RgIcons icon, String label, bool live, HfTone tone});

/// The indicator's look for a moment, as the page's `voiceLook`.
HfLook handsFreeLook(BuildContext context, HandsFreeRuntime r, {bool paused = false}) {
  final l = AppLocalizations.of(context);
  String w(String k, [Map<String, String> v = const {}]) => hfWord(context, k, v);
  if (r.micState == MicState.denied) {
    return (icon: RgIcons.alert, label: w('voiceMicDenied'), live: false, tone: HfTone.error);
  }
  if (r.micState == MicState.failed) {
    return (icon: RgIcons.alert, label: l.voiceMicFailed, live: false, tone: HfTone.error);
  }
  if (paused) return (icon: RgIcons.mic, label: l.hfPaused, live: false, tone: HfTone.dim);
  switch (r.state.phase) {
    case VoicePhase.wake:
    case VoicePhase.listening:
      return (icon: RgIcons.mic, label: w('voiceListening'), live: true, tone: HfTone.hot);
    case VoicePhase.followup:
      return (icon: RgIcons.mic, label: w('voiceFollowup'), live: true, tone: HfTone.hot);
    case VoicePhase.transcribing:
      return (icon: RgIcons.spinner, label: w('voiceTranscribing'), live: false, tone: HfTone.busy);
    case VoicePhase.thinking:
      return (icon: RgIcons.spinner, label: w('voiceThinking'), live: false, tone: HfTone.busy);
    case VoicePhase.speaking:
      return (icon: RgIcons.speaker, label: w('voiceSpeaking'), live: true, tone: HfTone.busy);
    case VoicePhase.idle:
    case VoicePhase.off:
      if (r.settings.wake && r.wakeHeard) {
        return (
          icon: RgIcons.wave,
          label: w('voiceWaiting', {'wake': r.settings.currentWake}),
          live: true,
          tone: HfTone.on,
        );
      }
      return (icon: RgIcons.mic, label: w('voiceTapToTalk'), live: false, tone: HfTone.dim);
  }
}

/// The pill at the top: icon and words on a computer, the icon alone where room is short.
class HandsFreeIndicator extends StatefulWidget {
  const HandsFreeIndicator({super.key, this.compact = false, this.onSettings});

  final bool compact;

  /// Opens Settings › Voice (the computers' room opens it in its own way).
  final VoidCallback? onSettings;

  @override
  State<HandsFreeIndicator> createState() => _HandsFreeIndicatorState();
}

class _HandsFreeIndicatorState extends State<HandsFreeIndicator>
    with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  late final _pulse = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1400),
  );
  bool _paused = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState s) {
    // Android keeps listening behind (its foreground service); the others pause.
    final app = AppScope.read(context);
    final behind = s != AppLifecycleState.resumed && s != AppLifecycleState.inactive;
    final keeps = app.platform == DevicePlatform.android;
    if (mounted) setState(() => _paused = behind && !keeps);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    final r = app.handsFree;
    return ListenableBuilder(
      listenable: r,
      builder: (context, _) {
        if (!r.settings.enabled) return const SizedBox.shrink();
        final c = RgColors.of(context);
        final look = handsFreeLook(context, r, paused: _paused);
        final reduce = MediaQuery.maybeDisableAnimationsOf(context) ?? false;
        if (look.live && !reduce) {
          if (!_pulse.isAnimating) _pulse.repeat(reverse: true);
        } else if (_pulse.isAnimating) {
          _pulse.stop();
          _pulse.value = 0;
        }
        final (fg, border, bg) = switch (look.tone) {
          HfTone.on => (c.text, Color.lerp(c.ok, c.line, .45)!, Colors.transparent),
          HfTone.hot => (c.accent, c.accent, c.accentSoft),
          HfTone.busy => (c.text, c.line, Colors.transparent),
          HfTone.error => (c.err, c.err, Colors.transparent),
          HfTone.dim => (c.dim, c.line, Colors.transparent),
        };
        final icon = look.icon == RgIcons.spinner
            ? RgSpinner(size: 16, color: fg)
            : FadeTransition(
                opacity: Tween<double>(begin: 1, end: .45).animate(_pulse),
                child: RgIcon(look.icon, size: 16, color: fg),
              );
        return Semantics(
          button: true,
          label: '${hfWord(context, 'voiceTitle')}: ${look.label}',
          child: Tooltip(
            message: look.label,
            child: InkWell(
              key: const Key('hf-indicator'),
              borderRadius: BorderRadius.circular(8),
              onTap: () => unawaited(_open(context)),
              child: Container(
                height: 30,
                padding: EdgeInsets.symmetric(horizontal: widget.compact ? 8 : 10),
                decoration: BoxDecoration(
                  color: bg,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: border),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    icon,
                    if (!widget.compact) ...[
                      const SizedBox(width: 6),
                      ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 220),
                        child: Text(
                          look.label,
                          key: const Key('hf-indicator-label'),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(color: fg, fontSize: 12.5, fontWeight: FontWeight.w600),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Future<void> _open(BuildContext context) async {
    final phone = MediaQuery.sizeOf(context).width < 700;
    final body = _HandsFreePop(paused: _paused, onSettings: widget.onSettings);
    if (phone) {
      await showModalBottomSheet<void>(
        context: context,
        showDragHandle: true,
        builder: (_) => SafeArea(child: body),
      );
    } else {
      await showRgWindow<void>(
        context: context,
        builder: (ctx) => Align(
          alignment: Alignment.topRight,
          child: Padding(
            padding: const EdgeInsets.only(top: 56, right: 16),
            child: Material(
              color: RgColors.of(ctx).panel,
              elevation: 6,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
                side: BorderSide(color: RgColors.of(ctx).line),
              ),
              child: SizedBox(width: 330, child: body),
            ),
          ),
        ),
      );
    }
  }
}

class _HandsFreePop extends StatelessWidget {
  const _HandsFreePop({required this.paused, this.onSettings});

  final bool paused;
  final VoidCallback? onSettings;

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    final r = app.handsFree;
    return ListenableBuilder(
      listenable: Listenable.merge([r, app.voice]),
      builder: (context, _) {
        final c = RgColors.of(context);
        final l = AppLocalizations.of(context);
        final look = handsFreeLook(context, r, paused: paused);
        final s = r.state;
        final busy = s.phase != VoicePhase.idle && s.phase != VoicePhase.off;
        final problem = s.error ?? app.voice.problem;
        return Padding(
          key: const Key('hf-pop'),
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            spacing: 10,
            children: [
              Text(
                look.label,
                key: const Key('hf-pop-state'),
                style: TextStyle(color: c.text, fontWeight: FontWeight.w700, fontSize: 15),
              ),
              if (!r.wakeHeard && r.settings.wake && !busy)
                Text(l.hfWakeNotHere, style: TextStyle(color: c.dim, fontSize: 12.5)),
              if (s.heard != null && s.heard!.isNotEmpty)
                Text(
                  '«${s.heard}»',
                  key: const Key('hf-heard'),
                  style: TextStyle(color: c.text, fontStyle: FontStyle.italic),
                ),
              if (problem != null)
                Text(
                  problem,
                  key: const Key('hf-error'),
                  style: TextStyle(color: c.err),
                ),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  if (busy)
                    OutlinedButton.icon(
                      key: const Key('hf-stop'),
                      onPressed: r.stopTalking,
                      icon: RgIcon(RgIcons.stop, size: 16, color: c.text),
                      label: Text(hfWord(context, 'voiceStop')),
                    )
                  else
                    FilledButton.icon(
                      key: const Key('hf-talk'),
                      onPressed: () {
                        app.voice.clearProblem();
                        unawaited(r.talkNow());
                      },
                      icon: const RgIcon(RgIcons.mic, size: 16, color: Colors.white),
                      label: Text(hfWord(context, 'voiceTalk')),
                    ),
                  OutlinedButton(
                    key: const Key('hf-off'),
                    onPressed: () {
                      Navigator.of(context).maybePop();
                      unawaited(r.switchOff());
                    },
                    child: Text(hfWord(context, 'voiceSwitchOff')),
                  ),
                  if (onSettings != null)
                    IconButton(
                      key: const Key('hf-settings'),
                      tooltip: hfWord(context, 'voiceSettings'),
                      onPressed: () {
                        Navigator.of(context).maybePop();
                        onSettings!();
                      },
                      icon: RgIcon(RgIcons.settings, size: 18, color: c.dim),
                    ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}

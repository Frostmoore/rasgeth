// Hands-free voice (G42.16): the state machine at work, as the page's
// packages/web/src/voice/controller.ts. The app gives it the microphone's samples (16 kHz) and
// what the wake-word listener heard; it keeps what is said, finds where speech ends ([Vad]), and
// through its ports transcribes, asks the conversation, reads the answer and keeps time. The ports
// are the only way out, so a whole conversation is tested with fakes.
import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/foundation.dart';

import 'machine.dart';
import 'speakable.dart';
import 'vad.dart';

abstract class VoicePorts {
  Future<String> transcribe(Uint8List wav);

  /// Sends the person's words to the conversation; completes with the agent's final answer.
  /// [stop] completes when the answer is no longer wanted.
  Future<String> ask(String text, Future<void> stop);

  /// Reads aloud; completes when done or hushed.
  Future<void> speak(String text);
  void hush();
  void chime();

  /// «The rest is on the screen», in the person's language.
  String more();
  Object setTimer(void Function() fn, Duration after);
  void clearTimer(Object id);
}

class HandsFreeOptions {
  const HandsFreeOptions({
    required this.sensitivity,
    required this.bargeIn,
    required this.followup,
    this.listen = const Duration(seconds: 7),
    this.endSilenceMs = 900,
  });

  final double Function() sensitivity;
  final bool Function() bargeIn;
  final Duration Function() followup;

  /// After the wake word, how long to wait for the first word.
  final Duration listen;

  /// A pause this long ends the request.
  final int endSilenceMs;
}

const _rate = 16000;

/// Kept from before speech is noticed, so its first syllable is not lost.
const _preroll = _rate ~/ 2;

class HandsFreeController extends ChangeNotifier {
  HandsFreeController(this.ports, this.o)
    : _vad = Vad(sampleRate: _rate, sensitivity: o.sensitivity(), endSilenceMs: o.endSilenceMs);

  final VoicePorts ports;
  final HandsFreeOptions o;
  final Vad _vad;
  VoiceState state = VoiceState.initial;
  bool _recording = false;
  List<Float32List> _kept = [];
  final List<Float32List> _prerollParts = [];
  int _prerollLen = 0;
  Object? _timer;
  int _turn = 0;
  _Stop? _asking;

  /// Which reading is the current one: an older one ending late says nothing.
  int _reading = 0;

  VoicePhase get phase => state.phase;

  void dispatch(VoiceEvent e) {
    final before = state;
    final step = stepVoice(before, e);
    final next = step.state;
    if (next.phase != before.phase) {
      // A new phase counts its speech afresh; leaving a turn makes its late answers stale.
      _vad.reset();
      _vad.boost = next.phase == VoicePhase.speaking ? 3 : 1;
      _vad.sensitivity = o.sensitivity();
      if (next.phase == VoicePhase.idle || next.phase == VoicePhase.off) _turn++;
    }
    state = next;
    for (final fx in step.effects) {
      _run(fx);
    }
    notifyListeners();
    // The microphone is always open while the conversation runs: recording is ready at once.
    if (next.phase == VoicePhase.wake) dispatch(const VoiceReady());
  }

  /// What the wake-word listener heard: wake or stop.
  void heard(String what) {
    final p = phase;
    if (what == 'stop') {
      if (p != VoicePhase.idle && p != VoicePhase.off) dispatch(const VoiceStopWord());
      return;
    }
    if (p == VoicePhase.idle || p == VoicePhase.speaking || p == VoicePhase.followup) {
      dispatch(const VoiceWake());
    }
  }

  /// The microphone's samples, mono at 16 kHz.
  void feed(Float32List samples) {
    _prerollParts.add(samples);
    _prerollLen += samples.length;
    while (_prerollParts.isNotEmpty && _prerollLen - _prerollParts.first.length >= _preroll) {
      _prerollLen -= _prerollParts.removeAt(0).length;
    }
    if (_recording) _kept.add(samples);
    final p = phase;
    final watching =
        p == VoicePhase.listening ||
        p == VoicePhase.followup ||
        (p == VoicePhase.speaking && o.bargeIn());
    if (!watching) {
      // The room's noise is still learned while waiting.
      if (p == VoicePhase.idle) _vad.push(samples);
      return;
    }
    for (final ev in _vad.push(samples)) {
      final now = phase;
      if (ev == VadEvent.start) {
        if (now == VoicePhase.speaking) {
          dispatch(const VoiceBargeIn());
          dispatch(const VoiceSpeechStart());
        } else {
          dispatch(const VoiceSpeechStart());
        }
      } else if (ev == VadEvent.end && now == VoicePhase.listening) {
        dispatch(const VoiceSpeechEnd());
      }
    }
  }

  void _run(VoiceEffect fx) {
    final turn = _turn;
    bool live() => turn == _turn;
    switch (fx.kind) {
      case 'chime':
        ports.chime();
      case 'record':
        _recording = true;
        _kept = [..._prerollParts];
      case 'discard':
        _recording = false;
        _kept = [];
      case 'transcribe':
        _recording = false;
        final total = _kept.fold<int>(0, (n, k) => n + k.length);
        final pcm = Float32List(total);
        var at = 0;
        for (final k in _kept) {
          pcm.setAll(at, k);
          at += k.length;
        }
        _kept = [];
        ports
            .transcribe(encodeWav(pcm, _rate))
            .then(
              (text) {
                if (live()) dispatch(VoiceTranscribed(text));
              },
              onError: (Object err) {
                if (live()) dispatch(VoiceFailed(_said(err)));
              },
            );
      case 'send':
        final ask = _Stop();
        _asking = ask;
        ports
            .ask(fx.text!, ask.future)
            .then(
              (answer) {
                if (live()) dispatch(VoiceAnswer(speakable(answer, ports.more())));
              },
              onError: (Object err) {
                if (live() && !ask.stopped) dispatch(VoiceFailed(_said(err)));
              },
            );
      case 'abandon':
        _asking?.stop();
        _asking = null;
      case 'speak':
        final reading = ++_reading;
        ports.speak(fx.text!).whenComplete(() {
          if (live() && reading == _reading && phase == VoicePhase.speaking) {
            dispatch(const VoiceSpoken());
          }
        });
      case 'hush':
        ports.hush();
      case 'timer':
        _clear();
        final listen = fx.timer == 'listen';
        final VoiceEvent ev = listen ? const VoiceSilence() : const VoiceFollowupOver();
        _timer = ports.setTimer(() {
          _timer = null;
          if (live()) dispatch(ev);
        }, listen ? o.listen : o.followup());
      case 'cancelTimer':
        _clear();
    }
  }

  void _clear() {
    final t = _timer;
    if (t != null) ports.clearTimer(t);
    _timer = null;
  }

  @override
  void dispose() {
    _clear();
    _asking?.stop();
    super.dispose();
  }
}

/// An error already in the person's words, or its message.
String _said(Object err) => err is SaidError ? err.text : '$err';

/// A failure already said in the person's language.
class SaidError implements Exception {
  const SaidError(this.text);
  final String text;

  @override
  String toString() => text;
}

class _Stop {
  final _c = Completer<void>();
  Future<void> get future => _c.future;
  bool get stopped => _c.isCompleted;

  void stop() {
    if (!_c.isCompleted) _c.complete();
  }
}

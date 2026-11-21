// Hands-free voice (G42.16): the page's state machine (packages/web/src/voice/machine.ts) in Dart,
// checked against the page's own results (test/fixtures/voice_vectors.json, tool/voice_vectors.mjs).
// The app feeds it what happens (the wake word heard, speech starting and ending, the text, the
// answer, the voice done) and runs the effects it returns; nothing here touches the microphone or
// the network.
//
//   off → idle ⇄ (wake word) → wake → listening → transcribing → thinking → speaking → followup
//   followup: speech again → listening without the wake word; silence for the window → idle
//   speaking: the person speaks (barge-in) → listening; «stop»/«basta» anywhere → idle

enum VoicePhase { off, idle, wake, listening, transcribing, thinking, speaking, followup }

class VoiceState {
  const VoiceState({required this.phase, required this.wake, this.error, this.heard});

  final VoicePhase phase;

  /// The wake word is listened for while idle.
  final bool wake;

  /// Something went wrong in the last turn, in words for the person.
  final String? error;

  /// What was understood last, shown under the indicator.
  final String? heard;

  static const initial = VoiceState(phase: VoicePhase.off, wake: false);

  Map<String, Object?> toJson() => {
    'phase': phase.name,
    'wake': wake,
    'error': ?error,
    'heard': ?heard,
  };

  static VoiceState fromJson(Map<String, Object?> j) => VoiceState(
    phase: VoicePhase.values.byName(j['phase']! as String),
    wake: j['wake'] == true,
    error: j['error'] as String?,
    heard: j['heard'] as String?,
  );
}

/// What happens, as the page's `VoiceEvent`.
sealed class VoiceEvent {
  const VoiceEvent();

  static VoiceEvent fromJson(Map<String, Object?> j) => switch (j['type']) {
    'start' => VoiceStart(wake: j['wake'] == true),
    'wake' => const VoiceWake(),
    'ready' => const VoiceReady(),
    'speechStart' => const VoiceSpeechStart(),
    'speechEnd' => const VoiceSpeechEnd(),
    'silence' => const VoiceSilence(),
    'transcribed' => VoiceTranscribed(j['text']! as String),
    'answer' => VoiceAnswer(j['text']! as String),
    'spoken' => const VoiceSpoken(),
    'bargeIn' => const VoiceBargeIn(),
    'stopWord' => const VoiceStopWord(),
    'followupOver' => const VoiceFollowupOver(),
    'failed' => VoiceFailed(j['error']! as String),
    'stop' => const VoiceStopEvent(),
    'off' => const VoiceOff(),
    final t => throw ArgumentError('voice event $t'),
  };
}

/// Hands-free switched on; [wake]: listen for the wake word while idle.
class VoiceStart extends VoiceEvent {
  const VoiceStart({required this.wake});
  final bool wake;
}

/// The wake word heard, or «Speak» tapped.
class VoiceWake extends VoiceEvent {
  const VoiceWake();
}

/// The microphone is recording.
class VoiceReady extends VoiceEvent {
  const VoiceReady();
}

class VoiceSpeechStart extends VoiceEvent {
  const VoiceSpeechStart();
}

class VoiceSpeechEnd extends VoiceEvent {
  const VoiceSpeechEnd();
}

/// Nothing said for the listening window.
class VoiceSilence extends VoiceEvent {
  const VoiceSilence();
}

class VoiceTranscribed extends VoiceEvent {
  const VoiceTranscribed(this.text);
  final String text;
}

class VoiceAnswer extends VoiceEvent {
  const VoiceAnswer(this.text);
  final String text;
}

/// The voice finished reading.
class VoiceSpoken extends VoiceEvent {
  const VoiceSpoken();
}

/// The person spoke over the answer.
class VoiceBargeIn extends VoiceEvent {
  const VoiceBargeIn();
}

/// «stop», «basta», «enough» heard by the wake-word listener.
class VoiceStopWord extends VoiceEvent {
  const VoiceStopWord();
}

class VoiceFollowupOver extends VoiceEvent {
  const VoiceFollowupOver();
}

class VoiceFailed extends VoiceEvent {
  const VoiceFailed(this.error);
  final String error;
}

/// The person stops this turn (the indicator's button).
class VoiceStopEvent extends VoiceEvent {
  const VoiceStopEvent();
}

/// Hands-free switched off.
class VoiceOff extends VoiceEvent {
  const VoiceOff();
}

/// What to do, as the page's `VoiceEffect` (`do`, with its text or timer).
class VoiceEffect {
  const VoiceEffect(this.kind, {this.text, this.timer});

  /// chime, record, transcribe, discard, send, speak, hush, abandon, timer, cancelTimer.
  final String kind;
  final String? text;

  /// listen or followup, for [kind] timer.
  final String? timer;

  static const chime = VoiceEffect('chime');
  static const record = VoiceEffect('record');
  static const transcribe = VoiceEffect('transcribe');
  static const discard = VoiceEffect('discard');
  static const hush = VoiceEffect('hush');
  static const abandon = VoiceEffect('abandon');
  static const cancelTimer = VoiceEffect('cancelTimer');
  static const listenTimer = VoiceEffect('timer', timer: 'listen');
  static const followupTimer = VoiceEffect('timer', timer: 'followup');

  Map<String, Object?> toJson() => {'do': kind, 'text': ?text, 'which': ?timer};
}

/// Words that end the conversation by voice, said alone (with a thank-you or an «ok» at most).
const _stopWords = [
  'stop',
  'basta',
  'fine',
  'finito',
  'smettila',
  'basta così',
  'ho finito',
  'enough',
  "that's all",
  'that is all',
  'stop it',
  'never mind',
  'lascia stare',
  'lascia perdere',
];
final _filler = RegExp(
  r'\b(ok|okay|grazie|thanks|thank you|allora|va bene|rasgeth|ras get|raz get|ehi|hey)\b',
);
final _notWord = RegExp(r"[^\p{L}\p{N}' ]+", unicode: true);
final _spaces = RegExp(r'\s+');

/// The text is only a request to stop (not a sentence that happens to contain «stop»).
bool isStopPhrase(String text) {
  final plain = text
      .toLowerCase()
      .replaceAll(_notWord, ' ')
      .replaceAll(_filler, ' ')
      .replaceAll(_spaces, ' ')
      .trim();
  return _stopWords.contains(plain);
}

typedef VoiceStep = ({VoiceState state, List<VoiceEffect> effects});

/// The next state and what to do, for one event.
VoiceStep stepVoice(VoiceState s, VoiceEvent e) {
  VoiceStep go(
    VoicePhase phase, [
    List<VoiceEffect> effects = const [],
    bool? wake,
    String? error,
    Object? heard = _keep,
  ]) => (
    state: VoiceState(
      phase: phase,
      wake: wake ?? s.wake,
      error: error,
      heard: identical(heard, _keep) ? s.heard : heard as String?,
    ),
    effects: effects,
  );
  final VoiceStep stay = (state: s, effects: const []);
  // Back to waiting: everything running stops.
  VoiceStep rest(VoicePhase phase, {bool? wake, String? error}) {
    final effects = <VoiceEffect>[VoiceEffect.cancelTimer];
    if (s.phase == VoicePhase.listening ||
        s.phase == VoicePhase.followup ||
        s.phase == VoicePhase.wake) {
      effects.add(VoiceEffect.discard);
    }
    if (s.phase == VoicePhase.speaking) effects.add(VoiceEffect.hush);
    if (s.phase == VoicePhase.thinking) effects.add(VoiceEffect.abandon);
    return go(phase, effects, wake, error);
  }

  if (e is VoiceOff) return s.phase == VoicePhase.off ? stay : rest(VoicePhase.off, wake: false);
  if (e is VoiceStart) {
    return s.phase == VoicePhase.off
        ? go(VoicePhase.idle, const [], e.wake)
        : (
            state: VoiceState(phase: s.phase, wake: e.wake, error: s.error, heard: s.heard),
            effects: const [],
          );
  }
  if (s.phase == VoicePhase.off) return stay;
  if (e is VoiceStopEvent || e is VoiceStopWord) {
    return s.phase == VoicePhase.idle ? stay : rest(VoicePhase.idle);
  }
  if (e is VoiceFailed) return rest(VoicePhase.idle, error: e.error);

  switch (s.phase) {
    case VoicePhase.idle:
      if (e is VoiceWake) return go(VoicePhase.wake, const [VoiceEffect.chime, VoiceEffect.record]);
      return stay;
    case VoicePhase.wake:
      if (e is VoiceReady) return go(VoicePhase.listening, const [VoiceEffect.listenTimer]);
      return stay;
    case VoicePhase.listening:
      if (e is VoiceSpeechStart) return go(VoicePhase.listening, const [VoiceEffect.cancelTimer]);
      if (e is VoiceSpeechEnd) {
        return go(VoicePhase.transcribing, const [VoiceEffect.cancelTimer, VoiceEffect.transcribe]);
      }
      if (e is VoiceSilence) return go(VoicePhase.idle, const [VoiceEffect.discard]);
      return stay;
    case VoicePhase.transcribing:
      if (e is VoiceTranscribed) {
        final text = e.text.trim();
        // Nothing understood: back to waiting, quietly.
        if (text.isEmpty) return go(VoicePhase.idle, const [], null, null, '');
        if (isStopPhrase(text)) return go(VoicePhase.idle, const [], null, null, text);
        return go(VoicePhase.thinking, [VoiceEffect('send', text: text)], null, null, text);
      }
      return stay;
    case VoicePhase.thinking:
      if (e is VoiceAnswer) {
        return e.text.trim().isNotEmpty
            ? go(VoicePhase.speaking, [VoiceEffect('speak', text: e.text)])
            : go(VoicePhase.followup, const [VoiceEffect.record, VoiceEffect.followupTimer]);
      }
      return stay;
    case VoicePhase.speaking:
      if (e is VoiceSpoken) {
        return go(VoicePhase.followup, const [VoiceEffect.record, VoiceEffect.followupTimer]);
      }
      if (e is VoiceBargeIn || e is VoiceWake) {
        return go(VoicePhase.listening, const [
          VoiceEffect.hush,
          VoiceEffect.record,
          VoiceEffect.listenTimer,
        ]);
      }
      return stay;
    case VoicePhase.followup:
      if (e is VoiceSpeechStart) return go(VoicePhase.listening, const [VoiceEffect.cancelTimer]);
      // The wake word said again in the window: a new request, as if it had just been heard.
      if (e is VoiceWake) {
        return go(VoicePhase.listening, const [VoiceEffect.chime, VoiceEffect.listenTimer]);
      }
      if (e is VoiceFollowupOver) return go(VoicePhase.idle, const [VoiceEffect.discard]);
      return stay;
    case VoicePhase.off:
      return stay;
  }
}

const Object _keep = Object();

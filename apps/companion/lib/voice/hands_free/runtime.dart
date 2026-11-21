// Hands-free voice (G42.16): the page's runtime (packages/web/src/voice/runtime.ts) in the app. The
// microphone stays open while hands-free is on (16 kHz PCM from `record`'s stream), every sample
// goes to [HandsFreeController]; its ports transcribe with the server's transcription, send the
// words to the conversation (marked as said by voice, with the note for the model) and wait for
// the turn's final answer, read it with the voice chosen (G40.10) and keep time. On Android the
// microphone is kept by a foreground service with its notification while it runs.
//
// The wake word: the page listens for it with Vosk in the browser; the app has no recogniser yet
// ([WakeSpotter] is the place for one), so on this device a turn starts from «Speak» in the
// indicator, and the indicator says so: never silently.
import 'dart:async';
import 'dart:io' show Platform;
import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' show Locale, PlatformDispatcher;

import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:record/record.dart';

import '../../api/client.dart';
import '../../api/conversation.dart' show sessionSendMessage;
import '../../app_state.dart';
import '../../l10n/app_localizations.dart';
import '../voice_words.dart';
import 'controller.dart';
import 'machine.dart';
import 'settings.dart';
import 'speakable.dart';
import 'vad.dart';
import 'wake.dart';

/// The microphone as a stream of 16 kHz mono 16-bit PCM.
abstract class MicStream {
  Future<bool> allowed();
  Future<Stream<Uint8List>> start();
  Future<void> stop();
}

class SystemMicStream implements MicStream {
  AudioRecorder? _rec;

  @override
  Future<bool> allowed() => (_rec ??= AudioRecorder()).hasPermission();

  @override
  Future<Stream<Uint8List>> start() => (_rec ??= AudioRecorder()).startStream(
    const RecordConfig(
      encoder: AudioEncoder.pcm16bits,
      sampleRate: 16000,
      numChannels: 1,
      echoCancel: true,
      noiseSuppress: true,
      autoGain: true,
    ),
  );

  @override
  Future<void> stop() async {
    await _rec?.stop();
  }
}

/// What keeps the microphone while the app is behind (Android's foreground service).
abstract class MicKeeper {
  Future<void> keep(AppLocalizations l, String wake);
  Future<void> release();
}

class NoMicKeeper implements MicKeeper {
  int kept = 0;
  int released = 0;

  @override
  Future<void> keep(AppLocalizations l, String wake) async => kept++;

  @override
  Future<void> release() async => released++;
}

/// Android: flutter_local_notifications' foreground service, microphone type (the manifest's).
class AndroidMicKeeper implements MicKeeper {
  final _plugin = FlutterLocalNotificationsPlugin();
  bool _on = false;

  AndroidFlutterLocalNotificationsPlugin? get _android =>
      _plugin.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();

  @override
  Future<void> keep(AppLocalizations l, String wake) async {
    try {
      await _android?.startForegroundService(
        id: 4216,
        title: l.hfServiceTitle,
        body: l.hfServiceBody,
        notificationDetails: AndroidNotificationDetails(
          'rg.handsfree',
          l.hfServiceChannel,
          channelDescription: l.hfServiceChannelText,
          importance: Importance.low,
          priority: Priority.low,
          ongoing: true,
          playSound: false,
          enableVibration: false,
        ),
        foregroundServiceTypes: {AndroidServiceForegroundType.foregroundServiceTypeMicrophone},
      );
      _on = true;
    } on Object {
      // Without the service the microphone still works while the app is in front.
    }
  }

  @override
  Future<void> release() async {
    if (!_on) return;
    _on = false;
    await _android?.stopForegroundService().catchError((_) {});
  }
}

MicKeeper defaultMicKeeper() {
  if (kIsWeb) return NoMicKeeper();
  return Platform.isAndroid ? AndroidMicKeeper() : NoMicKeeper();
}

/// The microphone's state, as the page's `micState`.
enum MicState { closed, opening, open, denied, failed }

/// The two notes of the page's chime (660 and 990 Hz), as a short WAV.
Uint8List chimeWav() {
  const rate = 16000;
  final pcm = Float32List((rate * 0.24).round());
  for (final (i, hz) in [660, 990].indexed) {
    final from = (i * 0.12 * rate).round();
    for (var n = 0; n < (0.11 * rate).round(); n++) {
      final t = n / rate;
      final env = t < 0.02 ? t / 0.02 : math.max(0, 1 - (t - 0.02) / 0.09);
      pcm[from + n] += math.sin(2 * math.pi * hz * t) * 0.15 * env;
    }
  }
  return encodeWav(pcm, rate);
}

class HandsFreeRuntime extends ChangeNotifier implements VoicePorts {
  HandsFreeRuntime(this.app, {MicStream? mic, MicKeeper? keeper})
    : _mic = mic,
      _keeper = keeper;

  final AppController app;
  MicStream? _mic;
  MicKeeper? _keeper;
  MicStream get mic => _mic ??= SystemMicStream();
  MicKeeper get keeper => _keeper ??= defaultMicKeeper();

  HandsFreeSettings settings = const HandsFreeSettings();
  MicState micState = MicState.closed;
  String? _serverId;
  StreamSubscription<Uint8List>? _sub;
  int _odd = -1;

  /// A recogniser for the wake word; none in the app yet (see the head of this file).
  WakeSpotter? spotter;

  /// The wake word can be heard on this device.
  bool get wakeHeard => spotter != null;

  late final HandsFreeController controller = HandsFreeController(
    this,
    HandsFreeOptions(
      sensitivity: () => settings.sensitivity,
      bargeIn: () => settings.bargeIn,
      followup: () => Duration(seconds: settings.followupSec),
    ),
  )..addListener(notifyListeners);

  VoiceState get state => controller.state;

  AppLocalizations get _l => lookupAppLocalizations(app.locale ?? _systemLocale());

  static Locale _systemLocale() {
    final code = PlatformDispatcher.instance.locale.languageCode;
    return Locale(code == 'it' ? 'it' : 'en');
  }

  String get _key => 'handsfree:${_serverId ?? '-'}';

  /// The RedGiant in use changed: its settings, and hands-free off until switched on again.
  Future<void> attach(String? serverId) async {
    if (serverId == _serverId) return;
    await switchOff(save: false);
    _serverId = serverId;
    settings = HandsFreeSettings.fromJson(
      serverId == null ? null : await app.prefs.get(_key),
      (app.locale ?? _systemLocale()).languageCode,
    );
    notifyListeners();
    // Switched on before on this device: back on (the indicator says so at once).
    if (settings.enabled) unawaited(start());
  }

  Future<void> update(HandsFreeSettings next) async {
    final was = settings;
    settings = next;
    notifyListeners();
    await app.prefs.set(_key, next.toJson());
    if (next.enabled && !was.enabled) await start();
    if (!next.enabled && was.enabled) await switchOff(save: false);
    if (next.enabled && was.wake != next.wake) {
      controller.dispatch(VoiceStart(wake: next.wake && wakeHeard));
    }
  }

  /// Hands-free on: the microphone opens and the machine waits.
  Future<void> start() async {
    await _openMic();
    if (micState != MicState.open) return;
    controller.dispatch(VoiceStart(wake: settings.wake && wakeHeard));
    unawaited(keeper.keep(_l, settings.currentWake));
  }

  /// «Speak»: a turn starts as if the wake word had been heard.
  Future<void> talkNow() async {
    if (!settings.enabled) await update(settings.copyWith(enabled: true));
    if (micState != MicState.open) await start();
    if (micState != MicState.open) return;
    if (controller.phase == VoicePhase.off) {
      controller.dispatch(VoiceStart(wake: settings.wake && wakeHeard));
    }
    controller.dispatch(const VoiceWake());
  }

  /// «Stop»: this turn ends, hands-free stays on.
  void stopTalking() => controller.dispatch(const VoiceStopEvent());

  /// Hands-free off: the microphone closes, the service ends.
  Future<void> switchOff({bool save = true}) async {
    controller.dispatch(const VoiceOff());
    await _closeMic();
    await keeper.release();
    if (save && settings.enabled) {
      settings = settings.copyWith(enabled: false);
      await app.prefs.set(_key, settings.toJson());
    }
    notifyListeners();
  }

  Future<void> _openMic() async {
    if (micState == MicState.open || micState == MicState.opening) return;
    micState = MicState.opening;
    notifyListeners();
    try {
      if (!await mic.allowed()) {
        micState = MicState.denied;
        notifyListeners();
        return;
      }
      final stream = await mic.start();
      _odd = -1;
      _sub = stream.listen(_onPcm, onError: (_) => _lost());
      micState = MicState.open;
    } on Object {
      micState = MicState.failed;
    }
    notifyListeners();
  }

  void _lost() {
    micState = MicState.failed;
    controller.dispatch(VoiceFailed(_l.voiceMicFailed));
    notifyListeners();
  }

  Future<void> _closeMic() async {
    await _sub?.cancel();
    _sub = null;
    if (micState == MicState.open || micState == MicState.opening) {
      await mic.stop().catchError((_) {});
    }
    if (micState != MicState.denied) micState = MicState.closed;
  }

  /// 16-bit samples, a byte left over kept for the next piece.
  void _onPcm(Uint8List bytes) {
    var data = bytes;
    if (_odd >= 0) {
      data = Uint8List(bytes.length + 1)
        ..[0] = _odd
        ..setAll(1, bytes);
      _odd = -1;
    }
    if (data.length.isOdd) {
      _odd = data.last;
      data = Uint8List.sublistView(data, 0, data.length - 1);
    }
    if (data.isEmpty) return;
    feed(pcm16ToFloat(data));
  }

  /// Samples at 16 kHz (the microphone's, or a test's).
  void feed(Float32List samples) {
    final p = controller.phase;
    final s = spotter;
    if (s != null &&
        settings.wake &&
        (p == VoicePhase.idle || p == VoicePhase.speaking || p == VoicePhase.followup)) {
      s.feed(samples);
    }
    controller.feed(samples);
  }

  // ---- the ports ----

  /// The conversation the words go to: the one set in Settings, or the one open in front.
  String? get target => settings.target.sessionId ?? app.frontSession;

  @override
  Future<String> transcribe(Uint8List wav) async {
    final c = app.client;
    if (c == null) throw SaidError(_l.voiceErrServer);
    try {
      return await c.transcribe(wav, 'audio/wav', settings.lang.name);
    } on Object catch (e) {
      throw SaidError(voiceErrorText(_l, e));
    }
  }

  @override
  Future<String> ask(String text, Future<void> stop) async {
    final sid = target;
    if (sid == null) throw SaidError(_l.hfNoConversation);
    final view = app.follow(sid);
    final sent = withVoiceHint(text);
    final after = view.events.isEmpty ? -1 : view.events.last.seq;
    final m = sessionSendMessage(sid, sent, clientId: 'v${DateTime.now().microsecondsSinceEpoch}')
      ..['via'] = 'voice';
    final socket = app.socket;
    if (socket == null || !socket.send(m)) {
      app.unfollow(sid);
      throw SaidError(_l.voiceErrServer);
    }
    final done = Completer<String>();
    var mine = -1;
    void check() {
      if (done.isCompleted) return;
      if (mine < 0) {
        final e = view.events
            .where((x) => x.seq > after && x.type == 'message.user' && x.payload?['text'] == sent)
            .firstOrNull;
        if (e == null) return;
        mine = e.seq;
      }
      if (view.running) return;
      final last = view.events
          .where((x) => x.seq > mine && x.type == 'message.assistant')
          .lastOrNull;
      if (last == null || last.payload?['stopReason'] == 'tool_use') return;
      done.complete(answerText(last.payload));
    }

    view.addListener(check);
    check();
    final timer = Timer(const Duration(minutes: 15), () {
      if (!done.isCompleted) done.completeError(SaidError(_l.hfTooLong));
    });
    unawaited(
      stop.then((_) {
        if (!done.isCompleted) done.completeError(const SaidError('stopped'));
      }),
    );
    try {
      return await done.future;
    } finally {
      timer.cancel();
      view.removeListener(check);
      app.unfollow(sid);
    }
  }

  @override
  Future<void> speak(String text) async {
    final read = await app.voice.say(text, _l);
    if (!read && app.voice.problem == null) {
      // Nobody can read here: the answer stays on the screen.
      app.voice.problem = _l.voiceNoReader;
    }
  }

  @override
  void hush() => unawaited(app.voice.stopSpeaking());

  @override
  void chime() => unawaited(
    app.voice.chimePlayer.play(chimeWav(), 'audio/wav', volume: 80).catchError((_) {}),
  );

  @override
  String more() => _l.hfRestOnScreen;

  @override
  Object setTimer(void Function() fn, Duration after) => Timer(after, fn);

  @override
  void clearTimer(Object id) => (id as Timer).cancel();

  @override
  void dispose() {
    unawaited(_closeMic());
    controller.dispose();
    super.dispose();
  }
}

/// The text of an assistant message's payload (its text parts, joined).
String answerText(Map<String, dynamic>? payload) {
  final parts = payload?['parts'];
  if (parts is! List) return '';
  return [
    for (final p in parts)
      if (p is Map && p['type'] == 'text' && p['text'] is String) p['text'] as String,
  ].join('\n');
}

/// The page's `wake-words` check: whether the language's model knows these words.
extension WakeWordsApi on RedGiantClient {
  Future<({bool ready, List<String> missing})> wakeWords(WakeLang lang, List<String> words) async {
    final j = await getJson('/api/voice/wake-words', {'lang': lang.name, 'words': words.join(',')});
    final m = j is Map ? j : const {};
    return (
      ready: m['ready'] == true,
      missing: [for (final w in (m['missing'] as List? ?? const [])) '$w'],
    );
  }
}

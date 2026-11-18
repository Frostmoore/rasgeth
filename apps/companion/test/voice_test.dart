// The voice of the app (G40.10): who reads (the chosen provider while its key is there, else the
// first one with a key), the text a reader gets, the volume's bounds, the server's failures in
// both languages, and «press and talk» and reading aloud against the fake Rasgeth with a fake
// microphone and loudspeaker.
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rgcompanion/api/client.dart';
import 'package:rgcompanion/api/servers.dart';
import 'package:rgcompanion/l10n/app_localizations.dart';
import 'package:rgcompanion/voice/audio.dart';
import 'package:rgcompanion/voice/voice_catalog.g.dart';
import 'package:rgcompanion/voice/voice_controller.dart';
import 'package:rgcompanion/voice/voice_types.dart';
import 'package:rgcompanion/voice/voice_words.dart';

import 'fake_server.dart';

class FakeRecorder implements VoiceRecorder {
  bool allow = true;
  bool on = false;
  Recording? next = Recording(Uint8List(16000), 'audio/wav', const Duration(seconds: 2));

  @override
  Future<bool> allowed() async => allow;

  @override
  Future<void> start() async => on = true;

  @override
  Future<Recording?> stop() async {
    on = false;
    return next;
  }

  @override
  Future<void> cancel() async => on = false;
}

class FakePlayer implements VoicePlayer {
  final played = <({int bytes, String mime, int volume})>[];

  @override
  Future<void> play(Uint8List bytes, String mimeType, {required int volume}) async =>
      played.add((bytes: bytes.length, mime: mimeType, volume: volume));

  @override
  Future<void> stop() async {}
}

final _it = lookupAppLocalizations(const Locale('it'));
final _en = lookupAppLocalizations(const Locale('en'));

void main() {
  group('who reads', () {
    final openai = speechProviders.firstWhere((p) => p.id == 'openai');
    final eleven = speechProviders.firstWhere((p) => p.id == 'elevenlabs');

    test('only providers with a key and a reading model', () {
      expect(readersWithKeys(speechProviders, ['groq', 'openai']).map((p) => p.id), ['openai']);
      expect(readersWithKeys(speechProviders, []), isEmpty);
    });

    test('the first with a key when nothing was chosen', () {
      final r = effectiveReader(const VoicePrefs(), [openai, eleven]);
      expect(r, ReaderChoice(provider: 'openai', model: openai.models.first.id, voice: 'marin'));
    });

    test('the choice while its key is there; else the first with a key', () {
      const mine = ReaderChoice(provider: 'elevenlabs', model: 'eleven_v4');
      expect(effectiveReader(const VoicePrefs(reader: mine), [openai, eleven]), mine);
      expect(effectiveReader(const VoicePrefs(reader: mine), [openai])?.provider, 'openai');
      expect(effectiveReader(const VoicePrefs(reader: mine), []), isNull);
    });

    test('a voice the model does not know falls back to its first', () {
      const r = ReaderChoice(provider: 'openai', model: 'tts-1', voice: 'marin');
      expect(effectiveReader(const VoicePrefs(reader: r), [openai])?.voice, 'alloy');
    });

    test('the volume stays within the bounds', () {
      expect(const VoicePrefs().copyWith(volume: 500).volume, kMaxVolume);
      expect(const VoicePrefs().copyWith(volume: 1).volume, kMinVolume);
      expect(VoicePrefs.fromJson('{"volume":3000}').volume, kMaxVolume);
      expect(VoicePrefs.fromJson('garbage').volume, kDefaultVolume);
      final back = VoicePrefs.fromJson(
        const VoicePrefs(
          reader: ReaderChoice(provider: 'google', model: 'm', voice: 'Kore'),
          volume: 60,
        ).toJson(),
      );
      expect(back.reader?.voice, 'Kore');
      expect(back.volume, 60);
    });
  });

  test('the text a reader gets: no Markdown marks nor code, at most the route limit', () {
    expect(
      textForSpeech(
        '# Title\n\n**Bold** and `code` and [a link](https://x.y).\n\n```js\nx()\n```\n- one',
      ),
      'Title Bold and code and a link. one',
    );
    final long = List.filled(900, 'Una frase.').join(' ');
    final t = textForSpeech(long);
    expect(t.length, lessThanOrEqualTo(4000));
    expect(t.endsWith('.'), isTrue);
  });

  group('failures in the person language', () {
    test('the server codes, with the provider name', () {
      const e = VoiceException(502, 'x', code: 'voice_key_refused', vars: {'name': 'OpenAI'});
      expect(
        voiceErrorText(_it, e),
        'OpenAI ha rifiutato la chiave: controllala in Impostazioni, Voce.',
      );
      expect(voiceErrorText(_en, e), 'OpenAI refused the key: check it in Settings, Voice.');
      expect(
        voiceErrorText(_it, const VoiceException(400, 'x', code: 'voice_no_service')),
        startsWith('Rasgeth non ha un servizio di trascrizione'),
      );
      expect(
        voiceErrorText(
          _it,
          const VoiceException(
            502,
            'x',
            code: 'voice_service_error',
            vars: {'name': 'Groq', 'status': '500'},
          ),
        ),
        'Groq ha risposto con un errore (500).',
      );
    });

    test('unreachable and unknown', () {
      expect(voiceErrorText(_it, const ApiException(0, 'down')), _it.voiceErrServer);
      expect(voiceErrorText(_en, StateError('x')), _en.voiceErrOther);
    });
  });

  group('against the fake Rasgeth', () {
    late FakeRedGiant fake;
    late RedGiantClient client;
    late FakeRecorder mic;
    late FakePlayer speaker;
    late VoiceController v;

    setUp(() async {
      HttpOverrides.global = null;
      fake = await FakeRedGiant.start();
      fake.tokens.add('rgd_1');
      client = RedGiantClient(fake.base, token: 'rgd_1');
      mic = FakeRecorder();
      speaker = FakePlayer();
      v = VoiceController(prefs: MemoryAppPrefs(), recorder: mic, player: speaker);
      await v.attach(client, 'srv1');
    });
    tearDown(() async {
      client.close();
      await fake.close();
    });

    test('press and talk: the WAV goes to /api/transcribe with the language', () async {
      expect(await v.startRecording(_it), isTrue);
      expect(v.recording, isTrue);
      expect(await v.stopAndTranscribe(_it, 'it'), 'che ore sono a Roma');
      expect(fake.transcribed.single.mime, 'audio/wav');
      expect(fake.transcribed.single.lang, 'it');
      expect(fake.transcribed.single.bytes, 16000);
      expect(v.problem, isNull);
    });

    test('a transcription failure is said in Italian', () async {
      fake.transcribeError = {
        'error': 'Groq is unreachable',
        'code': 'voice_unreachable',
        'vars': {'name': 'Groq'},
      };
      await v.startRecording(_it);
      expect(await v.stopAndTranscribe(_it, 'it'), isNull);
      expect(v.problem, 'Groq non si raggiunge: controlla che sia acceso e il suo indirizzo.');
    });

    test('no microphone, or a press too short', () async {
      mic.allow = false;
      expect(await v.startRecording(_it), isFalse);
      expect(v.problem, _it.voiceMicDenied);
      mic.allow = true;
      mic.next = Recording(Uint8List(100), 'audio/wav', const Duration(milliseconds: 100));
      await v.startRecording(_it);
      expect(await v.stopAndTranscribe(_it, 'it'), isNull);
      expect(v.problem, _it.voiceTooShort);
      expect(fake.transcribed, isEmpty);
    });

    test('reading aloud: the voice chosen, the text without marks, the volume', () async {
      fake.setup = {
        ...fake.setup,
        'secretsSet': {
          'keys': ['anthropic'],
          'voice': ['openai'],
        },
      };
      await v.setVolume(70);
      await v.speak('a1', '**Ciao** a tutti', _it);
      expect(fake.speeches.single, {
        'provider': 'openai',
        'model': 'gpt-4o-mini-tts',
        'voice': 'marin',
        'text': 'Ciao a tutti',
      });
      expect(speaker.played.single.volume, 70);
      expect(speaker.played.single.mime, startsWith('audio/mpeg'));
      expect(v.speaking, isNull);
    });

    test('no voice in Rasgeth: said, nothing asked', () async {
      await v.speak('a1', 'Ciao', _en);
      expect(v.problem, _en.voiceNoReader);
      expect(fake.speeches, isEmpty);
    });

    test('the provider refusing: said in the person language', () async {
      fake.setup = {
        ...fake.setup,
        'secretsSet': {
          'voice': ['google'],
        },
      };
      fake.speechError = {
        'error': 'x',
        'code': 'voice_rate_limited',
        'vars': {'name': 'Google Gemini'},
      };
      await v.speak('a1', 'Ciao', _it);
      expect(v.problem, 'Google Gemini dice troppe richieste o credito finito.');
      expect(speaker.played, isEmpty);
    });
  });
}

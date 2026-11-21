// G42.16: hands-free voice's Dart port against the page's own results (tool/voice_vectors.mjs):
// every phase × every event of the state machine, the stop phrases, the VAD on the page test's
// synthetic audio, the wake word's spelling and checks, what is read of an answer, the WAV.
import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:rgcompanion/voice/hands_free/machine.dart';
import 'package:rgcompanion/voice/hands_free/speakable.dart';
import 'package:rgcompanion/voice/hands_free/vad.dart';
import 'package:rgcompanion/voice/hands_free/wake.dart';

const _rate = 16000;

/// The page test's noise: the same LCG, in doubles as JavaScript computes it.
Float32List noise(double seconds, double height, [double seed = 1]) {
  var x = seed;
  final out = Float32List(jsRound(seconds * _rate));
  for (var i = 0; i < out.length; i++) {
    x = (x * 1103515245 + 12345) % 2147483648;
    out[i] = (x / 2147483648 - 0.5) * 2 * height;
  }
  return out;
}

Float32List tone(double seconds, double height) {
  final n = noise(seconds, height * 0.2, 7);
  final out = Float32List(n.length);
  for (var i = 0; i < n.length; i++) {
    out[i] =
        n[i] + math.sin((2 * math.pi * 180 * i) / _rate) * height * (0.6 + 0.4 * math.sin(i / 900));
  }
  return out;
}

Float32List make(List<dynamic> parts) {
  final arrays = [
    for (final p in parts.cast<List<dynamic>>())
      p[0] == 'noise'
          ? noise((p[1] as num).toDouble(), (p[2] as num).toDouble())
          : tone((p[1] as num).toDouble(), (p[2] as num).toDouble()),
  ];
  final out = Float32List(arrays.fold(0, (n, a) => n + a.length));
  var at = 0;
  for (final a in arrays) {
    out.setAll(at, a);
    at += a.length;
  }
  return out;
}

void main() {
  final v =
      jsonDecode(File('test/fixtures/voice_vectors.json').readAsStringSync())
          as Map<String, dynamic>;
  WakeLang lang(Object? x) => wakeLangOf(x as String?);

  test('every phase × every event as the page', () {
    final rows = (v['machine'] as List).cast<Map<String, dynamic>>();
    expect(rows.length, greaterThan(200));
    for (final r in rows) {
      final from = VoiceState.fromJson((r['from'] as Map).cast<String, Object?>());
      final e = VoiceEvent.fromJson((r['event'] as Map).cast<String, Object?>());
      final step = stepVoice(from, e);
      final why = '${r['from']} + ${r['event']}';
      expect(step.state.toJson(), r['state'], reason: why);
      expect([for (final x in step.effects) x.toJson()], r['effects'], reason: why);
    }
  });

  test('tells a request to stop from a sentence that says stop', () {
    for (final r in (v['stopPhrases'] as List).cast<Map<String, dynamic>>()) {
      expect(isStopPhrase(r['text'] as String), r['stop'], reason: r['text'] as String);
    }
  });

  test('the VAD finds speech where the page does, with the same room noise', () {
    final vad = v['vad'] as Map<String, dynamic>;
    for (final c in (vad['cases'] as List).cast<Map<String, dynamic>>()) {
      final o = (c['options'] as Map).cast<String, dynamic>();
      final d = Vad(
        sampleRate: _rate,
        sensitivity: (o['sensitivity'] as num?)?.toDouble() ?? 0.5,
        endSilenceMs: (o['endSilenceMs'] as num?)?.toInt() ?? 900,
        maxSpeechMs: (o['maxSpeechMs'] as num?)?.toInt() ?? 30000,
        boost: (o['boost'] as num?)?.toDouble() ?? 1,
      );
      final audio = make(c['parts'] as List);
      final out = <List<Object>>[];
      for (var i = 0; i < audio.length; i += 4096) {
        final end = math.min(audio.length, i + 4096);
        final piece = Float32List.sublistView(audio, i, end);
        for (final e in d.push(piece)) {
          out.add([e.name, jsRound(end / _rate * 1000)]);
        }
      }
      expect(out, c['events'], reason: '${c['parts']}');
      expect(d.floor, closeTo((c['floor'] as num).toDouble(), 1e-12));
      expect(d.threshold, closeTo((c['threshold'] as num).toDouble(), 1e-12));
    }
    for (final r in (vad['ratios'] as List).cast<List<dynamic>>()) {
      expect(ratioFor((r[0] as num).toDouble()), closeTo((r[1] as num).toDouble(), 1e-12));
    }
    for (final r in (vad['levels'] as List).cast<List<dynamic>>()) {
      final f = Float32List.fromList([for (final x in r[0] as List) (x as num).toDouble()]);
      expect(rms(f), closeTo((r[1] as num).toDouble(), 1e-9));
    }
    final at48 = Float32List(480);
    for (var i = 0; i < 480; i++) {
      at48[i] = math.sin(i / 20);
    }
    final down = downsample(at48, 48000, 16000);
    final want = (vad['downsample'] as List).cast<num>();
    expect(down.length, want.length);
    for (var i = 0; i < want.length; i++) {
      expect(down[i], closeTo(want[i].toDouble(), 1e-6));
    }
    expect(
      encodeWav(Float32List.fromList([0, 1, -1, 2, 0.5]), 16000),
      (vad['wav'] as List).cast<int>(),
    );
  });

  test('the wake word is spelled, checked and heard as the page does', () {
    final w = v['wake'] as Map<String, dynamic>;
    for (final r in (w['spoken'] as List).cast<List<dynamic>>()) {
      expect(spokenWake(r[0] as String), r[1]);
    }
    for (final r in (w['custom'] as List).cast<Map<String, dynamic>>()) {
      final l = lang(r['lang']);
      final own = r['own'] as String?;
      expect(customWake(l, own), r['custom'], reason: '$own');
      expect(wakeLabel(l, own), r['label'], reason: '$own');
      expect(wakePhrases(l, own), r['phrases'], reason: '$own');
      expect(jsonDecode(wakeGrammar(l, own)), r['grammar'], reason: '$own');
    }
    for (final r in (w['problems'] as List).cast<Map<String, dynamic>>()) {
      expect(wakeProblem(lang(r['lang']), r['text'] as String), r['problem'], reason: r['text']);
    }
    for (final r in (w['heard'] as List).cast<Map<String, dynamic>>()) {
      final words = (r['words'] as List?)
          ?.cast<Map<String, dynamic>>()
          .map((x) => (word: x['word'] as String, conf: (x['conf'] as num).toDouble()))
          .toList();
      final sens = (r['sensitivity'] as num).toDouble();
      expect(minConfFor(sens), closeTo((r['minConf'] as num).toDouble(), 1e-12));
      expect(
        classifyHeard(lang(r['lang']), r['text'] as String, words, minConfFor(sens), r['own']),
        r['heard'],
        reason: '${r['text']} ${r['own']}',
      );
    }
    for (final l in WakeLang.values) {
      expect(wakeExamples[l], (w['examples'] as Map)[l.name]);
      expect(defaultWake[l], (w['defaults'] as Map)[l.name]);
      expect(wakePhrasesByLang[l], (w['phrases'] as Map)[l.name]);
      expect(stopPhrasesByLang[l], (w['stops'] as Map)[l.name]);
      expect(wakeModelFiles[l], (w['models'] as Map)[l.name]);
    }
  });

  test('reads an answer as the page: its spoken version, or plain and cut', () {
    final s = v['speak'] as Map<String, dynamic>;
    expect(voiceHint, s['voiceHint']);
    final hint = s['hint'] as Map<String, dynamic>;
    expect(withVoiceHint(hint['text'] as String), hint['sent']);
    for (final a in (s['answers'] as List).cast<Map<String, dynamic>>()) {
      final md = a['markdown'] as String;
      expect(plainSpeech(md), a['plain'], reason: md);
      expect(spokenPart(md), a['spoken'], reason: md);
      expect(speakable(md, s['more'] as String), a['speakable'], reason: md);
      expect(chunksForVoice(plainSpeech(md)), a['chunks'], reason: md);
    }
  });
}

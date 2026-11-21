// Hands-free voice (G42.16): the wake word as the page spells and checks it
// (packages/web/src/voice/wake.ts, checked with its vectors): the default phrases, the person's
// own wake word, what is wrong with one before the server is asked, and what a recogniser's final
// result means. The recogniser itself (Vosk on the page) is behind [WakeSpotter].
import 'dart:convert';
import 'dart:typed_data';

import '../../brand.dart';

enum WakeLang { it, en }

WakeLang wakeLangOf(String? code) => code == 'it' ? WakeLang.it : WakeLang.en;

/// The name as the models spell it: they know «ras», «raz» and «get».
const spokenName = ['ras get', 'raz get'];

/// The phrases that wake the product, as the models spell them.
const wakePhrasesByLang = <WakeLang, List<String>>{
  WakeLang.it: ['ehi ras get', 'hey ras get', 'ei ras get', 'ehi raz get', 'ras get', 'raz get'],
  WakeLang.en: ['hey ras get', 'hi ras get', 'okay ras get', 'hey raz get', 'ras get', 'raz get'],
};

/// Said while the answer is read: it stops (the wake word instead asks something new).
const stopPhrasesByLang = <WakeLang, List<String>>{
  WakeLang.it: ['stop', 'basta', 'basta così', 'zitto'],
  WakeLang.en: ['stop', 'enough', 'stop it', 'be quiet'],
};

/// The default wake word as people write it.
const defaultWake = <WakeLang, String>{
  WakeLang.it: 'Ehi $kProductName',
  WakeLang.en: 'Hey $kProductName',
};

/// A few wake words of one's own, every word known to the language's small model.
const wakeExamples = <WakeLang, List<String>>{
  WakeLang.it: ['Ehi $kProductName', 'Ciao computer', 'Ehi Giove', 'Ok Aurora', 'Senti amico'],
  WakeLang.en: ['Hey $kProductName', 'Hey computer', 'Okay Jupiter', 'Hi Aurora', 'Listen friend'],
};

/// The file name the server serves for a language's model (`wake-models.ts`).
const wakeModelFiles = <WakeLang, String>{
  WakeLang.it: 'vosk-model-small-it-0.22.tar.gz',
  WakeLang.en: 'vosk-model-small-en-us-0.15.tar.gz',
};

final _notWord = RegExp(r"[^\p{L}\p{N}' ]+", unicode: true);
final _spaces = RegExp(r'\s+');

/// A wake word as the model spells it: small letters, no punctuation, «Rasgeth» as «ras get».
String spokenWake(String text) => text
    .toLowerCase()
    .replaceAll('rasgeth', ' ${spokenName[0]} ')
    .replaceAll('redgiant', 'red giant')
    .replaceAll(_notWord, ' ')
    .replaceAll(_spaces, ' ')
    .trim();

/// The person's own wake word, when it is one; null: the default.
String? customWake(WakeLang lang, String? own) {
  final spoken = own == null || own.isEmpty ? '' : spokenWake(own);
  return spoken.isNotEmpty && spoken != spokenWake(defaultWake[lang]!) ? spoken : null;
}

/// The wake word as the page names it.
String wakeLabel(WakeLang lang, String? own) =>
    customWake(lang, own) != null ? own!.trim() : defaultWake[lang]!;

/// What is wrong with a wake word before the server is asked: empty, tooLong, stopWord, short.
String? wakeProblem(WakeLang lang, String text) {
  final spoken = spokenWake(text);
  if (spoken.isEmpty) return 'empty';
  final words = spoken.split(' ');
  if (words.length > 4 || spoken.length > 40) return 'tooLong';
  if (stopPhrasesByLang[lang]!.contains(spoken)) return 'stopWord';
  if (words.length < 2 && spoken.length < 8) return 'short';
  return null;
}

/// The phrases that wake the product: the default ones, or the person's own.
List<String> wakePhrases(WakeLang lang, [String? own]) {
  final custom = customWake(lang, own);
  return custom != null ? [custom] : wakePhrasesByLang[lang]!;
}

/// What the recogniser may hear: the phrases, and anything else as "[unk]".
String wakeGrammar(WakeLang lang, [String? own]) =>
    jsonEncode([...wakePhrases(lang, own), ...stopPhrasesByLang[lang]!, '[unk]']);

typedef HeardWord = ({String word, double conf});

/// What a final result means: wake, stop or nothing (null). [minConf] from the sensitivity.
String? classifyHeard(
  WakeLang lang,
  String text,
  List<HeardWord>? words,
  double minConf, [
  String? own,
]) {
  final said = text.toLowerCase().replaceAll(_spaces, ' ').trim();
  if (said.isEmpty) return null;
  bool sure(String phrase) {
    if (words == null || words.isEmpty) return true;
    final need = phrase.split(' ').toSet();
    final mine = words.where((w) => need.contains(w.word)).toList();
    return mine.isNotEmpty && mine.every((w) => w.conf >= minConf);
  }

  final custom = customWake(lang, own);
  if (custom != null) {
    if (said.contains(custom)) return sure(custom) ? 'wake' : null;
  } else {
    final wake = wakePhrasesByLang[lang]!.where(said.contains).firstOrNull;
    // The name's two words must be sure; the greeting before them may be heard loosely.
    if (wake != null) {
      final name = wake.split(' ');
      return sure(name.sublist(name.length - 2).join(' ')) ? 'wake' : null;
    }
  }
  final stop = stopPhrasesByLang[lang]!
      .where((p) => said == p || said.endsWith(' $p'))
      .firstOrNull;
  if (stop != null) return sure(stop) ? 'stop' : null;
  return null;
}

/// Word confidence needed for a sensitivity (0…1): 0 → 0.95, 0.5 → 0.75, 1 → 0.55.
double minConfFor(double sensitivity) => 0.95 - sensitivity.clamp(0.0, 1.0) * 0.4;

/// A running wake-word listener: feed it 16 kHz samples, it calls back what it heard.
abstract class WakeSpotter {
  void feed(Float32List samples);

  /// Forgets what it heard so far (after it fired, so the same words do not fire twice).
  void reset();
  void dispose();
}

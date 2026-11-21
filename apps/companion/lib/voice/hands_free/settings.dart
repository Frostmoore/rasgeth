// Hands-free voice (G42.16): its settings belong to this device, as the page's
// packages/web/src/voice/settings.ts (a phone on the kitchen table and the computer in the study
// want different ones), kept in the app's preferences for each RedGiant. Who reads and how loud
// stay in [VoicePrefs] (G40.10); who writes down what is said is the server's (Settings ›
// General › Voice messages).
import 'dart:convert';

import 'wake.dart';

class HandsFreeTarget {
  const HandsFreeTarget.open() : sessionId = null, title = '';
  const HandsFreeTarget.session(String this.sessionId, this.title);

  /// Null: the conversation open in front.
  final String? sessionId;
  final String title;

  bool get fixed => sessionId != null;

  Map<String, Object?> toJson() =>
      fixed ? {'kind': 'session', 'sessionId': sessionId, 'title': title} : {'kind': 'open'};
}

class HandsFreeSettings {
  const HandsFreeSettings({
    this.enabled = false,
    this.wake = true,
    this.wakeWords = const {},
    this.sensitivity = 0.5,
    this.lang = WakeLang.en,
    this.followupSec = 8,
    this.bargeIn = true,
    this.target = const HandsFreeTarget.open(),
  });

  /// Hands-free on this device: the indicator at the top, the conversation by voice.
  final bool enabled;

  /// Listen for the wake word while the app is in front.
  final bool wake;

  /// The person's own wake word for a language, as they wrote it.
  final Map<WakeLang, String> wakeWords;

  /// 0…1: how easily the wake word and speech are taken.
  final double sensitivity;

  /// The language spoken and heard.
  final WakeLang lang;

  /// Seconds after the answer during which speaking again needs no wake word (0: none).
  final int followupSec;

  /// Speaking over the answer stops it.
  final bool bargeIn;

  /// Where what is said goes.
  final HandsFreeTarget target;

  static HandsFreeSettings defaults(String lang) => HandsFreeSettings(lang: wakeLangOf(lang));

  /// What was saved, clamped as the page's `loadVoiceSettings`.
  static HandsFreeSettings fromJson(String? raw, String lang) {
    final base = defaults(lang);
    if (raw == null) return base;
    try {
      final j = jsonDecode(raw);
      if (j is! Map<String, dynamic>) return base;
      final words = j['wakeWords'];
      final target = j['target'];
      final sens = j['sensitivity'];
      final follow = j['followupSec'];
      return HandsFreeSettings(
        enabled: j['enabled'] == true,
        wake: j['wake'] != false,
        wakeWords: {
          for (final l in WakeLang.values)
            if (words is Map && words[l.name] is String)
              l: (words[l.name] as String).length > 60
                  ? (words[l.name] as String).substring(0, 60)
                  : words[l.name] as String,
        },
        sensitivity: sens is num ? sens.toDouble().clamp(0.0, 1.0) : base.sensitivity,
        lang: j['lang'] == 'it' || j['lang'] == 'en' ? wakeLangOf(j['lang'] as String) : base.lang,
        followupSec: follow is num ? follow.round().clamp(0, 30) : base.followupSec,
        bargeIn: j['bargeIn'] != false,
        target: target is Map && target['kind'] == 'session' && target['sessionId'] is String
            ? HandsFreeTarget.session(target['sessionId'] as String, '${target['title'] ?? ''}')
            : const HandsFreeTarget.open(),
      );
    } on FormatException {
      return base;
    }
  }

  String toJson() => jsonEncode({
    'enabled': enabled,
    'wake': wake,
    'wakeWords': {for (final e in wakeWords.entries) e.key.name: e.value},
    'sensitivity': sensitivity,
    'lang': lang.name,
    'followupSec': followupSec,
    'bargeIn': bargeIn,
    'target': target.toJson(),
  });

  HandsFreeSettings copyWith({
    bool? enabled,
    bool? wake,
    Map<WakeLang, String>? wakeWords,
    double? sensitivity,
    WakeLang? lang,
    int? followupSec,
    bool? bargeIn,
    HandsFreeTarget? target,
  }) => HandsFreeSettings(
    enabled: enabled ?? this.enabled,
    wake: wake ?? this.wake,
    wakeWords: wakeWords ?? this.wakeWords,
    sensitivity: (sensitivity ?? this.sensitivity).clamp(0.0, 1.0),
    lang: lang ?? this.lang,
    followupSec: (followupSec ?? this.followupSec).clamp(0, 30),
    bargeIn: bargeIn ?? this.bargeIn,
    target: target ?? this.target,
  );

  /// The wake word this device listens for, as the page names it.
  String get currentWake => wakeLabel(lang, wakeWords[lang]);
}

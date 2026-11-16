// A message's figures (G40.17): the `metrics` of a `message.assistant` event (`MessageMetrics` in
// @redgiant/protocol) and the page's formatters (packages/web/src/format.ts), the same numbers the
// page's MetricsBar shows. test/metrics_test.dart checks them against the page's own functions
// (test/fixtures/metrics_vectors.json, from tool/metrics_fixtures.mjs).
import 'dart:math' as math;

import 'package:intl/intl.dart';

class MessageMetrics {
  const MessageMetrics({
    required this.startedAt,
    this.firstTokenAt,
    this.endedAt,
    required this.inputTokens,
    this.cachedReadTokens = 0,
    this.cacheWriteTokens = 0,
    required this.outputTokens,
    required this.contextUsed,
    required this.contextWindow,
    this.prefillMs,
    this.decodeMs,
    this.tokPerSec,
    this.kvRestoredTokens,
    this.kvRestoreMs,
    this.source = 'server',
  });

  /// null when the event has no usable figures (older or hand-made events, a window of 0).
  static MessageMetrics? fromJson(Object? o) {
    if (o is! Map<String, dynamic>) return null;
    int? count(String k) => (o[k] as num?)?.toInt();
    double? real(String k) => (o[k] as num?)?.toDouble();
    final started = o['startedAt'];
    final input = count('inputTokens');
    final output = count('outputTokens');
    final window = count('contextWindow');
    if (started is! String || input == null || output == null || window == null || window <= 0) {
      return null;
    }
    return MessageMetrics(
      startedAt: started,
      firstTokenAt: o['firstTokenAt'] as String?,
      endedAt: o['endedAt'] as String?,
      inputTokens: input,
      cachedReadTokens: count('cachedReadTokens') ?? 0,
      cacheWriteTokens: count('cacheWriteTokens') ?? 0,
      outputTokens: output,
      contextUsed: count('contextUsed') ?? input + output,
      contextWindow: window,
      prefillMs: real('prefillMs'),
      decodeMs: real('decodeMs'),
      tokPerSec: real('tokPerSec'),
      kvRestoredTokens: count('kvRestoredTokens'),
      kvRestoreMs: real('kvRestoreMs'),
      source: o['source'] == 'client' ? 'client' : 'server',
    );
  }

  final String startedAt;
  final String? firstTokenAt;
  final String? endedAt;
  final int inputTokens;
  final int cachedReadTokens;
  final int cacheWriteTokens;
  final int outputTokens;
  final int contextUsed;
  final int contextWindow;
  final double? prefillMs;
  final double? decodeMs;
  final double? tokPerSec;
  final int? kvRestoredTokens;
  final double? kvRestoreMs;

  /// "server" (llama.cpp, Ollama report them) or "client" (measured from the stream).
  final String source;

  /// Read new, not from the cache.
  int get fresh => math.max(0, inputTokens - cachedReadTokens);

  /// The bar's three pieces, as fractions of the window (each at most 1).
  double share(int n) => math.min(1.0, n / contextWindow);

  /// The context used, in percent with one decimal, as the page writes it ("6.4", "12", "100").
  String get usedPercent => jsNumber((contextUsed / contextWindow * 1000).round() / 10);

  /// Tokens per second as the page writes them, or null when there are none.
  String? get tokPerSecText {
    final v = tokPerSec;
    return v == null || v == 0 ? null : '${jsRound(v)} tok/s';
  }
}

/// JavaScript's `Math.round` (halves go up, also below zero).
int jsRound(num v) => (v + 0.5).floor();

/// A number as JavaScript's `String(n)` writes it: no ".0" on whole numbers.
String jsNumber(num v) => v == v.roundToDouble() ? '${v.toInt()}' : '$v';

/// `kTokens`: 950, 1.5k, 30k, 1.2M.
String kTokens(int n) => n >= 1000000
    ? '${(n / 1000000).toStringAsFixed(1)}M'
    : n >= 10000
    ? '${jsRound(n / 1000)}k'
    : n >= 1000
    ? '${(n / 1000).toStringAsFixed(1)}k'
    : '$n';

/// `duration`: 850ms, 1.2s, 2m5s; "–" when unknown.
String duration(num? ms) => ms == null
    ? '–'
    : ms >= 60000
    ? '${(ms / 60000).floor()}m${jsRound((ms % 60000) / 1000)}s'
    : ms >= 1000
    ? '${(ms / 1000).toStringAsFixed(1)}s'
    : '${jsRound(ms)}ms';

/// `usd`: $0, $0.0042, $1.25.
String usd(double v) =>
    v == 0 ? r'$0' : (v < 0.01 ? '\$${v.toStringAsFixed(4)}' : '\$${v.toStringAsFixed(2)}');

/// `clock`: the time of day in the person's language (`toLocaleTimeString`): 01:49:36, 1:49:36 AM.
String clock(String? iso, String locale) {
  final t = iso == null ? null : DateTime.tryParse(iso);
  return t == null ? '–' : clockOf(t.toLocal(), locale);
}

/// CLDR puts a narrow no-break space before AM/PM; browsers and Node write a plain one.
String clockOf(DateTime t, String locale) =>
    DateFormat.jms(locale).format(t).replaceAll(RegExp('[\u202f\u00a0]'), ' ');

/// The page's `localModelName`: a local model's readable name from its file ("GLM-4.5 Air Q4_K_S").
String localModelName(String id) {
  final gguf = RegExp(r'\.gguf$', caseSensitive: false);
  final file = gguf.hasMatch(id) || RegExp(r'[\\/]').hasMatch(id)
      ? id.split(RegExp(r'[\\/]')).last
      : id;
  if (file == id && !gguf.hasMatch(id)) return id;
  final stem = file
      .replaceFirst(gguf, '')
      .replaceFirst(RegExp(r'-\d{5}-of-\d{5}$', caseSensitive: false), '');
  final parts = stem.split('-').where((p) => p.isNotEmpty).toList();
  var out = parts.isEmpty ? stem : parts.first;
  for (final cur in parts.skip(1)) {
    out += (RegExp(r'^\d').hasMatch(cur) ? '-' : ' ') + cur;
  }
  return out.isEmpty ? id : out;
}

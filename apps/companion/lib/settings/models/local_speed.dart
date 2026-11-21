// G42.15: about how many tokens a second a local model writes here, the app's copy of the
// protocol's `estimatedSpeed` (packages/protocol/src/local-models.ts), checked with its vectors
// (tool/models_vectors.mjs → test/fixtures/models_vectors.json). Keep both together.
import 'dart:math' as math;

/// What each place gives to a model's reads at each token, in GB a second.
const _card = 500.0;
const _ram = 30.0;
const _igpu = 60.0;
const _cpu = 40.0;
const _unknown = 120.0;
const _ssd = 3.0;

/// The model writes this many tokens a second here (a range when it is uncertain), and as 1 to 5.
typedef LocalSpeed = ({int tokensPerSec, int stars, (int, int)? range});

int _starsFor(int n) => n >= 80 ? 5 : (n >= 40 ? 4 : (n >= 20 ? 3 : (n >= 10 ? 2 : 1)));

/// JavaScript's `Math.round` (halves go up, also below zero).
int _round(double x) => (x + .5).floorToDouble().toInt();

LocalSpeed estimatedSpeed({
  required double totalB,
  required double activeB,
  required double fileGb,
  required String kind,
  required double vramGb,
  double? ramGb,
}) {
  final perToken = math.max(.2, (fileGb * activeB) / totalB);
  final size = math.max(fileGb, .1);
  final card = kind == 'gpu' ? vramGb * .8 : 0.0;
  final memory = (ramGb ?? 16) * .9;
  final inCard = math.min(size, card);
  final inRam = math.min(size - inCard, memory);
  final moe = activeB < totalB * .5;
  final beyond = size - inCard - inRam;
  final onSsd = beyond * (moe ? .1 : 1);
  final ramSpeed = switch (kind) {
    'gpu' => _ram,
    'igpu' => _igpu,
    'gpu-unknown' => _unknown,
    _ => _cpu,
  };
  int speedWith(double ssd) {
    final seconds =
        (perToken / size) * (inCard / _card + (size - inCard - ssd) / ramSpeed + ssd / _ssd);
    return math.max(0, _round(1 / math.max(seconds, .001)));
  }

  final tokensPerSec = speedWith(onSsd);
  final range = moe && beyond > 0 ? (speedWith(beyond), speedWith(0)) : null;
  return (tokensPerSec: tokensPerSec, stars: _starsFor(tokensPerSec), range: range);
}

/// Usable here (the page's `USABLE_TPS`): at least this many tokens a second, or measured so.
const usableTps = 10;

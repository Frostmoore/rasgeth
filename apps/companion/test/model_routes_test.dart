// Subscription or API key (G40.9b): the app's copy of the protocol's rule, as the same tables
// (packages/protocol/test/model-routes.test.ts).
import 'package:flutter_test/flutter_test.dart';
import 'package:rgcompanion/api/model_routes.dart';
import 'package:rgcompanion/api/settings_types.dart';
import 'package:rgcompanion/l10n/app_localizations_en.dart';
import 'package:rgcompanion/l10n/app_localizations_it.dart';
import 'package:rgcompanion/ui/words.dart';

const _s = ModelRouteKind.subscription;
const _k = ModelRouteKind.key;
const _n = ModelRouteKind.node;
const _l = ModelRouteKind.local;
const _o = ModelRouteKind.other;

void main() {
  test('modelRoute: how each provider reaches a model', () {
    final table = <(String, String, String?, ModelRoute)>[
      (
        'claude-subscription',
        'claude-opus-5-5',
        null,
        const ModelRoute(_s, 'anthropic', 'claude-opus-5-5'),
      ),
      ('anthropic', 'claude-opus-5-5', null, const ModelRoute(_k, 'anthropic', 'claude-opus-5-5')),
      ('chatgpt-subscription', 'gpt-5.5', null, const ModelRoute(_s, 'openai', 'gpt-5.5')),
      ('openai', 'gpt-5.5', null, const ModelRoute(_k, 'openai', 'gpt-5.5')),
      ('gemini', 'gemini-3-pro', null, const ModelRoute(_k, 'gemini', 'gemini-3-pro')),
      (
        'node-rig',
        'claude-subscription:claude-opus-5-5',
        'Opus 5.5 (via Rig)',
        const ModelRoute(_n, 'anthropic', 'claude-opus-5-5', node: 'Rig', through: _s),
      ),
      (
        'node-rig',
        'openai:gpt-5.5',
        null,
        const ModelRoute(_n, 'openai', 'gpt-5.5', node: 'rig', through: _k),
      ),
      ('node-rig', 'local:qwen3', null, const ModelRoute(_n, 'local', 'qwen3', node: 'rig')),
      ('local', 'qwen3-8b', null, const ModelRoute(_l, 'local', 'qwen3-8b')),
      ('server', 'llama', null, const ModelRoute(_l, 'server', 'llama')),
      ('fake', 'm1', null, const ModelRoute(_o, 'fake', 'm1')),
    ];
    for (final (p, m, name, want) in table) {
      expect(modelRoute(p, m, name), want, reason: '$p $m');
    }
  });

  test('modelFamilies: each model once, its ways with the subscription first', () {
    final choices = [
      const ModelChoice(provider: 'anthropic', model: 'claude-opus-5-5', name: 'Claude Opus 5.5'),
      const ModelChoice(
        provider: 'claude-subscription',
        model: 'claude-opus-5-5',
        name: 'Claude Opus 5.5',
      ),
      const ModelChoice(provider: 'claude-subscription', model: 'claude-haiku-4-5'),
      const ModelChoice(provider: 'openai', model: 'gpt-5.5'),
      const ModelChoice(
        provider: 'node-rig',
        model: 'anthropic:claude-opus-5-5',
        name: 'Claude Opus 5.5 (via Rig)',
      ),
      const ModelChoice(provider: 'local', model: 'qwen3'),
    ];
    final f = modelFamilies(choices);
    expect(
      [for (final x in f) '${x.id} ${x.ways.map((w) => w.route.kind.name).join(',')}'],
      [
        'anthropic/claude-opus-5-5 subscription,key,node',
        'anthropic/claude-haiku-4-5 subscription',
        'openai/gpt-5.5 key',
        'local/qwen3 local',
      ],
    );
    expect(f.first.label, 'Claude Opus 5.5');
    // Without a name, the id as people say it.
    expect(f[1].label, 'Haiku 4.5');
    expect(modelName('gpt-5.5'), 'gpt-5.5');
    expect(modelFamilies([choices[4]]).first.label, 'Claude Opus 5.5');
    final at = familyOf(f, 'anthropic/claude-opus-5-5');
    expect(at?.$1.ways[at.$2].route.kind, _k);
    expect(familyOf(f, 'anthropic/nope'), isNull);
  });

  test('the words of a way and what it means, in both languages', () {
    final it = AppLocalizationsIt();
    final en = AppLocalizationsEn();
    ModelWay w(String p, String m, [String? name]) =>
        ModelWay(modelRoute(p, m, name), ModelChoice(provider: p, model: m));
    final table = <(ModelWay, String, String, String, String)>[
      (
        w('claude-subscription', 'm'),
        'Abbonamento',
        'Subscription',
        'Nei limiti del tuo piano: non paghi a consumo.',
        "Within your plan's limits: nothing is paid per use.",
      ),
      (
        w('anthropic', 'm'),
        'Chiave API',
        'API key',
        'A consumo con la tua chiave API: conta per il tetto di spesa.',
        'Paid per use with your API key: it counts toward the spending cap.',
      ),
      (
        w('node-rig', 'openai:m', 'M (via Rig)'),
        'Tramite Rig',
        'Via Rig',
        'Passa dal computer Rig.',
        'Goes through the computer Rig.',
      ),
      (
        w('local', 'm'),
        'Locale',
        'Local',
        'Gira su un computer tuo: niente costi a consumo.',
        'Runs on a computer of yours: nothing is paid per use.',
      ),
    ];
    for (final (way, wi, we, hi, he) in table) {
      expect(wayWord(it, way), wi);
      expect(wayWord(en, way), we);
      expect(wayHint(it, way), hi);
      expect(wayHint(en, way), he);
    }
  });
}

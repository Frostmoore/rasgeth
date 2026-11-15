// How a model is reached (G40.9b), the app's copy of `@redgiant/protocol`'s model-routes.ts:
// the subscription, the API key, a node, a local engine. The menus show one entry per model
// family (same company, same model) with the ways it can go. Keep both tables together.
import 'settings_types.dart';

enum ModelRouteKind { subscription, key, node, local, other }

class ModelRoute {
  const ModelRoute(this.kind, this.vendor, this.model, {this.node, this.through});

  final ModelRouteKind kind;

  /// The company behind the model (`anthropic`, `openai`…), or the provider when unknown.
  final String vendor;

  /// The model's id at that company (without a node's `<provider>:` prefix).
  final String model;

  /// For `node`: the node's name.
  final String? node;

  /// For `node`: how the node itself reaches the model, when it says.
  final ModelRouteKind? through;

  @override
  bool operator ==(Object other) =>
      other is ModelRoute &&
      other.kind == kind &&
      other.vendor == vendor &&
      other.model == model &&
      other.node == node &&
      other.through == through;

  @override
  int get hashCode => Object.hash(kind, vendor, model, node, through);

  @override
  String toString() => 'ModelRoute($kind, $vendor, $model, $node, $through)';
}

const _subscriptionVendor = {'claude-subscription': 'anthropic', 'chatgpt-subscription': 'openai'};
const _local = {'local', 'server'};
const _keys = {
  'anthropic',
  'openai',
  'gemini',
  'mistral',
  'deepseek',
  'xai',
  'groq',
  'openrouter',
  'together',
  'fireworks',
  'cerebras',
};

final _via = RegExp(r'\(via ([^)]+)\)\s*$');

/// How `provider` reaches `model`; `name` is the menu's name (a node's says «(via Rig)»).
ModelRoute modelRoute(String provider, String model, [String? name]) {
  final sub = _subscriptionVendor[provider];
  if (sub != null) return ModelRoute(ModelRouteKind.subscription, sub, model);
  if (provider.startsWith('node-')) {
    final i = model.indexOf(':');
    final inner = i > 0 ? model.substring(0, i) : '';
    final id = i > 0 ? model.substring(i + 1) : model;
    final r = modelRoute(inner, id);
    final through = r.kind == ModelRouteKind.subscription || r.kind == ModelRouteKind.key
        ? r.kind
        : null;
    final node = name == null ? null : _via.firstMatch(name)?.group(1)?.trim();
    return ModelRoute(
      ModelRouteKind.node,
      inner.isEmpty ? provider : r.vendor,
      id,
      node: node ?? provider.substring(5),
      through: through,
    );
  }
  if (_local.contains(provider)) return ModelRoute(ModelRouteKind.local, provider, model);
  if (_keys.contains(provider)) return ModelRoute(ModelRouteKind.key, provider, model);
  return ModelRoute(ModelRouteKind.other, provider, model);
}

class ModelWay {
  const ModelWay(this.route, this.choice);
  final ModelRoute route;
  final ModelChoice choice;
}

/// One model with every way it can go, the subscription first.
class ModelFamily {
  ModelFamily(this.id, this.vendor, this.model, this.name);

  /// `<vendor>/<model>`: the same for every way.
  final String id;
  final String vendor;
  final String model;

  /// The menus' name without a node's «(via …)».
  String? name;
  final List<ModelWay> ways = [];

  String get label => name ?? modelName(model);
}

final _claude = RegExp(r'^claude-([a-z]+)-(\d+)(?:-(\d+))?$');

/// A model's id as people say it, like the page's `modelName`: claude-opus-5-5 → Opus 5.5.
String modelName(String id) {
  final m = _claude.firstMatch(id);
  if (m == null) return id;
  final family = m.group(1)!;
  return '${family[0].toUpperCase()}${family.substring(1)} ${m.group(2)}${m.group(3) != null ? '.${m.group(3)}' : ''}';
}

/// The models in families, in the order they first appear; each family's ways in kind order.
List<ModelFamily> modelFamilies(List<ModelChoice> choices) {
  final out = <ModelFamily>[];
  final byId = <String, ModelFamily>{};
  for (final c in choices) {
    final r = modelRoute(c.provider, c.model, c.name);
    final id = '${r.vendor}/${r.model}';
    var f = byId[id];
    if (f == null) {
      final name = c.name?.replaceFirst(RegExp(r'\s*\(via [^)]+\)\s*$'), '');
      f = ModelFamily(id, r.vendor, r.model, (name?.isEmpty ?? true) ? null : name);
      byId[id] = f;
      out.add(f);
    } else if (f.name == null && c.name != null && r.kind != ModelRouteKind.node) {
      f.name = c.name;
    }
    f.ways.add(ModelWay(r, c));
  }
  for (final f in out) {
    // A stable sort: ways of the same kind keep their order.
    final sorted = [...f.ways.indexed]
      ..sort((a, b) {
        final k = a.$2.route.kind.index.compareTo(b.$2.route.kind.index);
        return k != 0 ? k : a.$1.compareTo(b.$1);
      });
    f.ways
      ..clear()
      ..addAll(sorted.map((e) => e.$2));
  }
  return out;
}

/// The family and the way of a chosen `provider/model`; null when it is not among them.
(ModelFamily, int)? familyOf(List<ModelFamily> families, String key) {
  for (final f in families) {
    final i = f.ways.indexWhere((w) => w.choice.key == key);
    if (i >= 0) return (f, i);
  }
  return null;
}

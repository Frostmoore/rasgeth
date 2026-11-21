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

/// The model menus by provider and by how one pays (2026-11-20, the person), the app's copy of
/// the protocol's `modelGroups`: every way a model goes is its own entry under a clear heading,
/// companies first (subscription before key), then the nodes, then this computer and the
/// person's own server; inside a group the newest first (the catalog's release day), the undated
/// after in the provider's order. Checked with test/fixtures/model_groups_vectors.json.
class ModelGroup {
  ModelGroup(this.id, this.kind, this.vendor, this.provider, this.node);

  final String id;
  final ModelRouteKind kind;
  final String vendor;
  final String provider;
  final String? node;
  final List<ModelChoice> choices = [];
}

const _vendors = [
  'anthropic',
  'openai',
  'gemini',
  'xai',
  'deepseek',
  'mistral',
  'groq',
  'cerebras',
  'together',
  'fireworks',
  'openrouter',
];
const _groupOrder = [
  ModelRouteKind.subscription,
  ModelRouteKind.key,
  ModelRouteKind.other,
  ModelRouteKind.node,
  ModelRouteKind.local,
];

int _vendorRank(String v) {
  final i = _vendors.indexOf(v);
  return i < 0 ? _vendors.length : i;
}

List<ModelGroup> modelGroups(List<ModelChoice> choices) {
  final groups = <ModelGroup>[];
  final byId = <String, ModelGroup>{};
  for (final c in choices) {
    final r = modelRoute(c.provider, c.model, c.name);
    final id = r.kind == ModelRouteKind.node ? '${c.provider}|${r.vendor}' : c.provider;
    final g = byId.putIfAbsent(id, () {
      final n = ModelGroup(id, r.kind, r.vendor, c.provider, r.node);
      groups.add(n);
      return n;
    });
    g.choices.add(c);
  }
  List<int> place(ModelGroup g) {
    final outer = g.kind == ModelRouteKind.node ? 1 : (g.kind == ModelRouteKind.local ? 2 : 0);
    return [
      outer,
      outer == 1 ? 0 : _vendorRank(g.vendor),
      _groupOrder.indexOf(g.kind),
      g.kind == ModelRouteKind.local && g.provider == 'local' ? 0 : 1,
    ];
  }

  int cmp(ModelGroup a, ModelGroup b) {
    final pa = place(a);
    final pb = place(b);
    for (var i = 0; i < pa.length; i++) {
      if (pa[i] != pb[i]) return pa[i] - pb[i];
    }
    if (a.kind == ModelRouteKind.node && b.kind == ModelRouteKind.node) {
      final n = (a.node ?? '').compareTo(b.node ?? '');
      if (n != 0) return n;
      final v = _vendorRank(a.vendor) - _vendorRank(b.vendor);
      return v != 0 ? v : a.vendor.compareTo(b.vendor);
    }
    return a.vendor.compareTo(b.vendor);
  }

  // A stable sort, as the page's.
  final indexed = [...groups.indexed]
    ..sort((a, b) {
      final k = cmp(a.$2, b.$2);
      return k != 0 ? k : a.$1 - b.$1;
    });
  final out = [for (final e in indexed) e.$2];
  for (final g in out) {
    final dated = [...g.choices.indexed]
      ..sort((a, b) {
        final ra = a.$2.released;
        final rb = b.$2.released;
        if (ra != null && rb != null && ra != rb) return ra.compareTo(rb) < 0 ? 1 : -1;
        if (ra != null && rb == null) return -1;
        if (ra == null && rb != null) return 1;
        return a.$1 - b.$1;
      });
    g.choices
      ..clear()
      ..addAll(dated.map((e) => e.$2));
  }
  return out;
}

const _vendorNames = {
  'anthropic': 'Anthropic',
  'openai': 'OpenAI',
  'gemini': 'Google',
  'xai': 'xAI',
  'deepseek': 'DeepSeek',
  'mistral': 'Mistral',
  'groq': 'Groq',
  'cerebras': 'Cerebras',
  'together': 'Together AI',
  'fireworks': 'Fireworks AI',
  'openrouter': 'OpenRouter',
};

/// A group's heading, as the protocol's `groupTitle`: «Anthropic · Abbonamento Claude».
String groupTitle(ModelGroup g, String lang) {
  final it = lang == 'it';
  final vendor = _vendorNames[g.vendor] ?? g.vendor;
  switch (g.kind) {
    case ModelRouteKind.subscription:
      final plan = g.provider == 'claude-subscription'
          ? 'Claude'
          : (g.provider == 'chatgpt-subscription' ? 'ChatGPT' : '');
      if (it) return '$vendor · Abbonamento${plan.isEmpty ? '' : ' $plan'}';
      return '$vendor · ${plan.isEmpty ? 'Subscription' : '$plan subscription'}';
    case ModelRouteKind.key:
      return '$vendor · ${it ? 'Chiave API' : 'API key'}';
    case ModelRouteKind.node:
      final own = g.vendor == 'local' || g.vendor == 'server';
      return '${it ? 'Tramite' : 'Via'} ${g.node} · ${own ? (it ? 'Locale' : 'Local') : vendor}';
    case ModelRouteKind.local:
      return g.provider == 'local'
          ? (it ? 'Su questo computer' : 'On this computer')
          : (it ? 'Il tuo server' : 'Your own server');
    case ModelRouteKind.other:
      return vendor;
  }
}

/// Whether a model answers a search: its name, its id or its group's heading.
bool modelMatches(ModelChoice m, String heading, String query) {
  final q = query.trim().toLowerCase();
  if (q.isEmpty) return true;
  return [m.name ?? '', m.model, heading].any((s) => s.toLowerCase().contains(q));
}

// G42.15: Settings › Models and subscriptions, native, as the page's (ModelsPage.tsx, Brain.tsx,
// SetupAssign.tsx): the ways of thinking as squares, lit when connected, each opening its window
// (Claude Pro or Max signed in from the browser with the code pasted back; ChatGPT with the code
// typed on OpenAI's page; an API key per provider, tried by the server; the person's own server);
// «Which one should I pick?»; the model agents use when nobody chose another, with its effort;
// who uses which model (God, Demi-God, the assistants, the backup for tasks given up on), each
// changed in the one model sheet (by provider and way, the newest first); then the model on this
// computer (local_models.dart). Keys only go out, and never show again.
import 'dart:async';

import 'package:flutter/material.dart';

import '../../api/model_routes.dart';
import '../../api/settings_types.dart';
import '../../api/types.dart';
import '../../app_state.dart';
import '../../l10n/app_localizations.dart';
import '../../screens/first_start_screen.dart' show openExternal;
import '../../theme/colors.dart';
import '../../ui/icons.dart';
import '../../ui/model_sheet.dart';
import '../api/general_api.dart';
import '../api/models_api.dart';
import '../channels/channels_kit.dart' show CodePill, OpenLink;
import '../knowledge_kit.dart';
import '../rules_kit.dart';
import 'key_providers.dart';
import 'local_models.dart';

Future<void> openModelsSettings(BuildContext context, {OpenLink? openUrl}) =>
    openRulesPage(context, (panel) => ModelsScreen(panel: panel, openUrl: openUrl ?? openExternal));

const _terms = [
  ('Anthropic', 'https://www.anthropic.com/legal/consumer-terms'),
  ('OpenAI', 'https://openai.com/policies/terms-of-use'),
];

/// A provider in words (the page's `providerName`).
String providerWords(AppLocalizations l, String id) => switch (id) {
  'claude-subscription' => l.moBrainClaude,
  'chatgpt-subscription' => l.moBrainChatgpt,
  'local' => l.moBrainLocal,
  'server' => l.moBrainServer,
  _ => keyProviderName(id),
};

String effortWords(AppLocalizations l, String e) => switch (e) {
  'low' => l.moEffort_low,
  'high' => l.moEffort_high,
  'max' => l.moEffort_max,
  _ => l.moEffort_medium,
};

class ModelsScreen extends StatefulWidget {
  const ModelsScreen({
    super.key,
    this.panel = false,
    this.openUrl = openExternal,
    this.poll = true,
  });

  final bool panel;
  final OpenLink openUrl;

  /// Follow downloads and sign-ins every second or so (tests pump by hand).
  final bool poll;

  @override
  State<ModelsScreen> createState() => _ModelsScreenState();
}

class _ModelsScreenState extends State<ModelsScreen> {
  ModelsSetup? _s;
  List<ModelChoice> _models = const [];
  AgentModel? _chatModel;
  String? _error;
  String? _said;
  final _local = GlobalKey();

  @override
  void initState() {
    super.initState();
    unawaited(_load());
  }

  Future<void> _load() async {
    if (!mounted) return;
    final app = AppScope.read(context);
    final c = app.client;
    if (c == null) return;
    try {
      final s = await c.modelsSetup();
      final models = await app.modelChoices(again: true);
      AgentModel? chat;
      try {
        chat = await c.chatModel();
      } on Object {
        chat = null;
      }
      if (!mounted) return;
      setState(() {
        _s = s;
        _models = models;
        _chatModel = chat;
        _error = null;
      });
    } on Object catch (e) {
      if (mounted) setState(() => _error = rulesWhy(e));
    }
  }

  String _wayState(AppLocalizations l, String w) {
    final s = _s!;
    return switch (w) {
      'keys' =>
        s.keys.length == 1
            ? l.moWzStateKey(providerWords(l, s.keys.first))
            : l.moWzStateKeys('${s.keys.isEmpty ? 1 : s.keys.length}'),
      'server' => s.serverUrl != null ? l.moWzStateServer(s.serverUrl!) : l.moWzStateLinked,
      'local' =>
        s.activeModel != null
            ? '${l.moWzStateLocal(modelName(s.activeModel!))}${s.engineOff ? ' · ${l.moLmOff}' : ''}'
            : l.moWzStateLocalNext,
      _ => l.moWzStateLinked,
    };
  }

  Future<void> _openWay(String w, String title) async {
    if (w == 'local') {
      final ctx = _local.currentContext;
      if (ctx != null) {
        await Scrollable.ensureVisible(ctx, duration: const Duration(milliseconds: 300));
      }
      return;
    }
    await kbWindow<void>(
      context,
      key: Key('way-window-$w'),
      title: title,
      wide: true,
      body: (ctx, close) => switch (w) {
        'claude' => _ClaudePanel(s: _s!, openUrl: widget.openUrl, onChange: _load, onDone: close),
        'chatgpt' => _ChatgptPanel(
          s: _s!,
          openUrl: widget.openUrl,
          poll: widget.poll,
          onChange: _load,
          onDone: close,
        ),
        'keys' => _KeysPanel(openUrl: widget.openUrl, onChange: _load, onDone: close),
        _ => _ServerPanel(s: _s!, onChange: _load, onDone: close),
      },
    );
    await _load();
  }

  AgentModel? _spec(({String provider, String model, String? effort})? m) =>
      m == null ? null : AgentModel(provider: m.provider, model: m.model, effort: m.effort);

  Future<void> _pickDefault() async {
    final l = AppLocalizations.of(context);
    if (!mounted) return;
    final c = AppScope.read(context).client;
    if (c == null || _models.isEmpty) return;
    final pick = await showModelPicker(
      context,
      title: l.moBrainDefault,
      models: _models,
      current: _spec(_s?.defaultModel),
    );
    final m = pick?.model;
    if (m == null || !mounted) return;
    try {
      await c.setDefaultModel(m.provider, m.model, effort: m.effort);
      setState(() => _said = l.moBrainDefaultSaved);
    } on Object catch (e) {
      setState(() => _said = rulesWhy(e));
    }
    await _load();
  }

  /// Who uses which model: God, Demi-God, the assistants (the Chat), the backup.
  Future<void> _pickRole(String role) async {
    final l = AppLocalizations.of(context);
    if (!mounted) return;
    final app = AppScope.read(context);
    final c = app.client;
    if (c == null || _models.isEmpty) return;
    final agent = switch (role) {
      'god' => app.agents.where((a) => a.kind == AgentKind.god).firstOrNull,
      'demigod' => app.agents.where((a) => a.kind == AgentKind.demigod).firstOrNull,
      _ => null,
    };
    final current = switch (role) {
      'chat' => _chatModel,
      'backup' => _spec(_s?.backupModel),
      _ => agent?.model,
    };
    final pick = await showModelPicker(
      context,
      title: _roleTitle(l, role),
      models: _models,
      current: current,
      inheritLabel: role == 'backup' ? l.moWzNone : l.moAgentModelDefault,
    );
    if (pick == null || !mounted) return;
    var ok = true;
    try {
      switch (role) {
        case 'chat':
          await c.setChatModel(pick.model);
        case 'backup':
          await c.setBackupModel(pick.model);
        default:
          ok = agent != null && await app.setAgentModel(agent, pick.model);
      }
    } on Object catch (e) {
      ok = false;
      setState(() => _said = rulesWhy(e));
    }
    if (ok && mounted) setState(() => _said = l.moBrainDefaultSaved);
    await _load();
  }

  String _roleTitle(AppLocalizations l, String role) {
    final names = _s?.names ?? const {};
    return switch (role) {
      'god' => names['god'] is String ? names['god'] as String : 'God',
      'demigod' => names['demigod'] is String ? names['demigod'] as String : 'Demi-God',
      'chat' => l.moWzAssistants,
      _ => l.moBackupModelTitle,
    };
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final app = AppScope.of(context);
    final c = RgColors.of(context);
    final s = _s;
    if (s == null) {
      return RulesPage(
        pageKey: const Key('models-page'),
        title: l.moSubscriptions,
        question: l.moWzBrainQ,
        panel: widget.panel,
        children: [RulesLoading(error: _error)],
      );
    }
    final ways = s.ways;
    final tiles = [
      ('claude', RgIcons.spark, l.moBrainClaude, l.moWzBrainClaude),
      ('chatgpt', RgIcons.chat, l.moBrainChatgpt, l.moWzBrainChatgpt),
      ('keys', RgIcons.key, l.moWzBrainKeysTitle, l.moWzBrainKeys),
      ('server', RgIcons.server, l.moBrainServer, l.moWzBrainServer),
      ('local', RgIcons.monitor, l.moBrainLocal, l.moWzBrainLocal),
    ];
    final d = s.defaultModel;
    String words(AgentModel? m, String none) => m == null ? none : modelWords(l, _models, m);
    final god = app.agents.where((a) => a.kind == AgentKind.god).firstOrNull;
    final demigod = app.agents.where((a) => a.kind == AgentKind.demigod).firstOrNull;
    return RulesPage(
      pageKey: const Key('models-page'),
      title: l.moSubscriptions,
      question: l.moWzBrainQ,
      lead: l.moMpLead,
      panel: widget.panel,
      children: [
        if (_said != null) KbLine(_said!, dim: true),
        KbTiles(
          children: [
            for (final (w, icon, title, text) in tiles)
              KbTile(
                key: Key('way-$w'),
                icon: icon,
                title: title,
                text: text,
                on: ways.contains(w),
                state: ways.contains(w) ? _wayState(l, w) : null,
                onTap: () => _openWay(w, title),
              ),
          ],
        ),
        Align(
          alignment: Alignment.centerLeft,
          child: TextButton(
            key: const Key('models-which'),
            onPressed: () => kbWindow<void>(
              context,
              key: const Key('models-which-window'),
              title: l.moWzWhich,
              body: (ctx, close) => Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  KbLine(l.moBrainWhyText),
                  KbActs(
                    children: [FilledButton(onPressed: close, child: Text(l.moWzUnderstood))],
                  ),
                ],
              ),
            ),
            child: Text(l.moWzWhich),
          ),
        ),
        RulesSub(title: l.moBrainDefault, lead: l.moBrainDefaultHint),
        KbTiles(
          minWidth: 260,
          children: [
            KbTile(
              key: const Key('models-default'),
              icon: RgIcons.star,
              title: d == null ? l.moMpNoDefault : modelName(d.model.split('/').last),
              text: d == null
                  ? l.moMpNoDefaultText
                  : [
                      modelWords(
                        l,
                        _models,
                        AgentModel(provider: d.provider, model: d.model),
                      ).split(' · ').skip(1).join(' · '),
                      effortWords(l, d.effort ?? 'medium'),
                    ].where((x) => x.isNotEmpty).join(' · '),
              on: d != null,
              state: s.lockedOf('defaultModel') ? l.moWzLocked : l.moMpChange,
              onTap: s.lockedOf('defaultModel') || _models.isEmpty ? null : _pickDefault,
            ),
          ],
        ),
        if (_models.isEmpty) KbLine(l.moBrainNoModel, dim: true),
        RulesSub(title: l.moWzAssign, lead: l.moWzAssignLead),
        KbBox(
          children: [
            _RoleRow(
              key: const Key('role-god'),
              icon: RgIcons.star,
              title: _roleTitle(l, 'god'),
              sub: l.moWzAssignGod,
              model: words(god?.model, l.moAgentModelDefault),
              onTap: god == null ? null : () => _pickRole('god'),
            ),
            _RoleRow(
              key: const Key('role-demigod'),
              icon: RgIcons.send,
              title: _roleTitle(l, 'demigod'),
              sub: l.moWzAssignDemigod2,
              model: words(demigod?.model, l.moAgentModelDefault),
              onTap: demigod == null ? null : () => _pickRole('demigod'),
            ),
            _RoleRow(
              key: const Key('role-chat'),
              icon: RgIcons.chat,
              title: l.moWzAssistants,
              sub: l.moWzAssignChat,
              model: words(_chatModel, l.moAgentModelDefault),
              onTap: () => _pickRole('chat'),
            ),
            _RoleRow(
              key: const Key('role-others'),
              icon: RgIcons.users,
              title: l.moWzAssignOthers,
              sub: l.moWzAssignOthersHelp,
              model: words(_spec(d), l.moMpNoDefault),
              onTap: s.lockedOf('defaultModel') ? null : _pickDefault,
            ),
            _RoleRow(
              key: const Key('role-backup'),
              icon: RgIcons.refresh,
              title: l.moBackupModelTitle,
              sub: l.moWzBackupText,
              model: words(_spec(s.backupModel), l.moBackupModelNone),
              onTap: () => _pickRole('backup'),
              last: true,
            ),
          ],
        ),
        Padding(
          key: _local,
          padding: const EdgeInsets.only(top: 18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                l.moWzLocalQ,
                style: TextStyle(
                  fontSize: 21,
                  fontWeight: FontWeight.w800,
                  color: c.text,
                  height: 1.25,
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(top: 4, bottom: 10),
                child: Text(
                  l.moMpLocalLead,
                  style: TextStyle(color: c.dim, fontSize: 14, height: 1.4),
                ),
              ),
              LocalModelsSection(s: s, poll: widget.poll, onChange: _load),
            ],
          ),
        ),
      ],
    );
  }
}

/// One role of «Who uses which model»: who, what it does, its model; a tap changes it.
class _RoleRow extends StatelessWidget {
  const _RoleRow({
    super.key,
    required this.icon,
    required this.title,
    required this.sub,
    required this.model,
    required this.onTap,
    this.last = false,
  });

  final RgIcons icon;
  final String title;
  final String sub;
  final String model;
  final VoidCallback? onTap;
  final bool last;

  @override
  Widget build(BuildContext context) {
    final c = RgColors.of(context);
    return InkWell(
      borderRadius: BorderRadius.circular(10),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          border: last ? null : Border(bottom: BorderSide(color: c.line)),
        ),
        child: Row(
          children: [
            Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(shape: BoxShape.circle, color: c.accentSoft),
              child: Center(child: RgIcon(icon, size: 17, color: c.accent)),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(fontWeight: FontWeight.w800, color: c.text),
                  ),
                  Text(
                    sub,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(color: c.dim, fontSize: 12.5),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(top: 3),
                    child: Text(
                      model,
                      style: TextStyle(color: c.accent, fontSize: 13, fontWeight: FontWeight.w700),
                    ),
                  ),
                ],
              ),
            ),
            if (onTap != null) RgIcon(RgIcons.chevronRight, size: 16, color: c.dim),
          ],
        ),
      ),
    );
  }
}

/// The warning on the providers' terms, read once for every subscription (RD23): our switch and
/// the links to their terms.
class _Terms extends StatelessWidget {
  const _Terms({required this.ack, required this.onChanged, required this.openUrl});

  final bool ack;
  final ValueChanged<bool> onChanged;
  final OpenLink openUrl;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        KbSwitchRow(
          key: const Key('models-terms'),
          title: l.moWzSubscription,
          on: ack,
          onChanged: onChanged,
        ),
        Wrap(
          spacing: 4,
          children: [
            for (final (name, url) in _terms)
              TextButton(onPressed: () => openUrl(Uri.parse(url)), child: Text(l.moTermsOf(name))),
          ],
        ),
      ],
    );
  }
}

/// Where a subscription's program comes from, said before it is switched on.
class _ProgramNote extends StatelessWidget {
  const _ProgramNote({required this.name, required this.s});

  final String name;
  final SubStatus? s;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final st = s;
    if (st == null) return const SizedBox.shrink();
    if (st.sharedLogin) return KbLine(l.moSubsSharedLogin(name));
    if (st.program == 'system') return KbLine(l.moSubsProgramSystem(name), dim: true);
    if (st.program == 'none') return KbLine(l.moSubsProgramDownload(name), dim: true);
    return const SizedBox.shrink();
  }
}

/// A connected account: who, and a way out.
class _Linked extends StatelessWidget {
  const _Linked({required this.who, required this.onOut});

  final String who;
  final VoidCallback onOut;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final c = RgColors.of(context);
    return KbBox(
      key: const Key('sub-linked'),
      tone: c.ok,
      children: [
        Text(
          who,
          style: TextStyle(color: c.text, fontWeight: FontWeight.w700),
        ),
        Align(
          alignment: Alignment.centerLeft,
          child: TextButton(
            key: const Key('sub-out'),
            onPressed: onOut,
            child: Text(l.moBrainDisconnect),
          ),
        ),
      ],
    );
  }
}

Future<void> _saveAck(BuildContext context, bool v) async {
  try {
    await AppScope.read(context).client?.setupSubscriptions({'ack': v});
  } on Object {
    // The switch says what the person chose; the server reads it again next time.
  }
}

/// Claude Pro or Max: Anthropic's page in the browser, then the code it shows pasted here.
class _ClaudePanel extends StatefulWidget {
  const _ClaudePanel({
    required this.s,
    required this.openUrl,
    required this.onChange,
    required this.onDone,
  });

  final ModelsSetup s;
  final OpenLink openUrl;
  final Future<void> Function() onChange;
  final void Function([void]) onDone;

  @override
  State<_ClaudePanel> createState() => _ClaudePanelState();
}

class _ClaudePanelState extends State<_ClaudePanel> {
  SubStatus? _status;
  late bool _ack = widget.s.ack;
  String? _page;
  final _code = TextEditingController();
  bool _busy = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    unawaited(_load());
  }

  @override
  void dispose() {
    _code.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    try {
      final s = await AppScope.read(context).client?.claudeSub();
      if (mounted) setState(() => _status = s);
    } on Object catch (e) {
      if (mounted) setState(() => _error = rulesWhy(e));
    }
  }

  Future<void> _run(Future<void> Function() f) async {
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await f();
    } on Object catch (e) {
      if (mounted) setState(() => _error = rulesWhy(e));
    }
    if (mounted) setState(() => _busy = false);
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final c = AppScope.of(context).client;
    final st = _status;
    final account = st != null && st.signedIn ? st : null;
    return Column(
      key: const Key('claude-panel'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        KbLine(l.moBrainClaudeHint, dim: true),
        if (account == null) _ProgramNote(name: 'Claude Code', s: st),
        if (account != null)
          _Linked(
            who: l.moSubsLoggedAs(account.plan ?? '', account.email ?? 'Claude'),
            onOut: () => _run(() async {
              await c?.claudeLogout();
              await _load();
              await widget.onChange();
            }),
          )
        else ...[
          _Terms(
            ack: _ack,
            openUrl: widget.openUrl,
            onChanged: (v) {
              setState(() => _ack = v);
              unawaited(_saveAck(context, v));
            },
          ),
          if (st?.sharedLogin ?? false)
            Align(
              alignment: Alignment.centerLeft,
              child: FilledButton(
                key: const Key('claude-shared'),
                onPressed: !_ack || _busy
                    ? null
                    : () => _run(() async {
                        await c?.setupSubscriptions({'ack': _ack, 'claude': <String, Object?>{}});
                        await _load();
                        await widget.onChange();
                      }),
                child: Text(l.moSubsUseShared),
              ),
            ),
          _Numbered(
            n: 1,
            children: [
              Align(
                alignment: Alignment.centerLeft,
                child: FilledButton.icon(
                  key: const Key('claude-open'),
                  onPressed: !_ack || _busy
                      ? null
                      : () => _run(() async {
                          final url = await c!.claudeLogin(ack: _ack);
                          setState(() => _page = url);
                          await widget.openUrl(Uri.parse(url));
                        }),
                  icon: const RgIcon(RgIcons.external, size: 16, color: Colors.white),
                  label: Text(l.moBrainClaudeOpen),
                ),
              ),
              if (_page != null)
                TextButton(
                  key: const Key('claude-open-again'),
                  onPressed: () => widget.openUrl(Uri.parse(_page!)),
                  child: Text('${l.moBrainNotOpened} ${l.moBrainOpenHere}'),
                ),
            ],
          ),
          _Numbered(n: 2, children: [KbLine(l.moBrainClaudeStep2)]),
          _Numbered(
            n: 3,
            children: [
              TextField(
                key: const Key('claude-code'),
                controller: _code,
                enabled: _page != null,
                autocorrect: false,
                onChanged: (_) => setState(() {}),
                decoration: InputDecoration(labelText: l.moBrainClaudeCode),
              ),
              const SizedBox(height: 8),
              Align(
                alignment: Alignment.centerLeft,
                child: FilledButton(
                  key: const Key('claude-connect'),
                  onPressed: _page == null || _busy || _code.text.trim().isEmpty
                      ? null
                      : () => _run(() async {
                          await c?.claudeCode(_code.text.trim());
                          _code.clear();
                          setState(() => _page = null);
                          await _load();
                          await widget.onChange();
                        }),
                  child: Text(_busy ? l.moWzTrying : l.moBrainConnect),
                ),
              ),
            ],
          ),
        ],
        if (_error != null) KbLine(_error!, error: true),
        KbActs(
          children: [FilledButton(onPressed: widget.onDone, child: Text(l.moWzDoneBtn))],
        ),
      ],
    );
  }
}

/// ChatGPT Plus or Pro: a code to type on OpenAI's page; the window notices when it is done.
class _ChatgptPanel extends StatefulWidget {
  const _ChatgptPanel({
    required this.s,
    required this.openUrl,
    required this.poll,
    required this.onChange,
    required this.onDone,
  });

  final ModelsSetup s;
  final OpenLink openUrl;
  final bool poll;
  final Future<void> Function() onChange;
  final void Function([void]) onDone;

  @override
  State<_ChatgptPanel> createState() => _ChatgptPanelState();
}

class _ChatgptPanelState extends State<_ChatgptPanel> {
  SubStatus? _status;
  late bool _ack = widget.s.ack;
  ({String url, String code})? _login;
  String? _error;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    unawaited(_load());
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _load() async {
    try {
      final s = await AppScope.read(context).client?.chatgptSub();
      if (!mounted) return;
      setState(() => _status = s);
      if (_login != null && s != null && s.on && (s.email != null || s.plan != null)) {
        _timer?.cancel();
        setState(() => _login = null);
        await widget.onChange();
      }
    } on Object catch (e) {
      if (mounted) setState(() => _error = rulesWhy(e));
    }
  }

  Future<void> _start() async {
    if (!mounted) return;
    final c = AppScope.read(context).client;
    if (c == null) return;
    setState(() => _error = null);
    try {
      if (!(_status?.on ?? false)) await c.setupSubscriptions({'ack': _ack, 'chatgpt': true});
      final now = await c.chatgptSub();
      setState(() => _status = now);
      // Already signed in with the person's own Codex: nothing more to do.
      if (now.email != null || now.plan != null) {
        await widget.onChange();
        return;
      }
      final login = await c.chatgptLogin();
      setState(() => _login = login);
      if (widget.poll) {
        _timer = Timer.periodic(const Duration(seconds: 3), (_) => _load());
      }
    } on Object catch (e) {
      if (mounted) setState(() => _error = rulesWhy(e));
    }
  }

  Future<void> _out() async {
    if (!mounted) return;
    final c = AppScope.read(context).client;
    try {
      await c?.chatgptLogout();
      await c?.setupSubscriptions({'chatgpt': false});
      await _load();
      await widget.onChange();
    } on Object catch (e) {
      if (mounted) setState(() => _error = rulesWhy(e));
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final st = _status;
    final account = st != null && st.on && (st.email != null || st.plan != null) ? st : null;
    final login = _login;
    return Column(
      key: const Key('chatgpt-panel'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        KbLine(l.moBrainChatgptHint, dim: true),
        if (account == null) _ProgramNote(name: 'Codex', s: st),
        if (account != null)
          _Linked(
            who: l.moSubsLoggedAs(account.plan ?? '', account.email ?? 'ChatGPT'),
            onOut: _out,
          )
        else if (login != null) ...[
          _Numbered(
            n: 1,
            children: [
              KbLine(l.moBrainChatgptStep1),
              Align(
                alignment: Alignment.centerLeft,
                child: TextButton(
                  key: const Key('chatgpt-url'),
                  onPressed: () => widget.openUrl(Uri.parse(login.url)),
                  child: Text(login.url),
                ),
              ),
            ],
          ),
          _Numbered(
            n: 2,
            children: [
              KbLine(l.moBrainChatgptStep2),
              CodePill(login.code, key: const Key('chatgpt-code')),
            ],
          ),
          KbLine(l.moSubsDeviceWait, dim: true),
          KbLine(l.moBrainChatgptDevice, dim: true),
        ] else ...[
          _Terms(
            ack: _ack,
            openUrl: widget.openUrl,
            onChanged: (v) {
              setState(() => _ack = v);
              unawaited(_saveAck(context, v));
            },
          ),
          Align(
            alignment: Alignment.centerLeft,
            child: FilledButton(
              key: const Key('chatgpt-start'),
              onPressed: _ack ? _start : null,
              child: Text(l.moBrainChatgptStart),
            ),
          ),
        ],
        if (_error != null) KbLine(_error!, error: true),
        KbActs(
          children: [FilledButton(onPressed: widget.onDone, child: Text(l.moWzDoneBtn))],
        ),
      ],
    );
  }
}

/// The API keys: the providers as chips, one key at a time, tried by the server.
class _KeysPanel extends StatefulWidget {
  const _KeysPanel({required this.openUrl, required this.onChange, required this.onDone});

  final OpenLink openUrl;
  final Future<void> Function() onChange;
  final void Function([void]) onDone;

  @override
  State<_KeysPanel> createState() => _KeysPanelState();
}

class _KeysPanelState extends State<_KeysPanel> {
  ModelsSetup? _s;
  String _prov = keyProviders.first.id;
  final _key = TextEditingController();
  bool _busy = false;
  (bool, String)? _result;

  @override
  void initState() {
    super.initState();
    unawaited(_load());
  }

  @override
  void dispose() {
    _key.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    try {
      final s = await AppScope.read(context).client?.modelsSetup();
      if (mounted) setState(() => _s = s);
    } on Object {
      // The list shows what it knew.
    }
  }

  Future<void> _save() async {
    final l = AppLocalizations.of(context);
    if (!mounted) return;
    final c = AppScope.read(context).client;
    if (c == null) return;
    setState(() {
      _busy = true;
      _result = null;
    });
    try {
      final models = await c.setupKey(_prov, _key.text.trim());
      _key.clear();
      setState(() => _result = (true, l.moBrainKeyWorks('${models.length}')));
      await _load();
      await widget.onChange();
    } on Object catch (e) {
      setState(() => _result = (false, rulesWhy(e)));
    }
    if (mounted) setState(() => _busy = false);
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final c = RgColors.of(context);
    final s = _s;
    final p = keyProviders.firstWhere((x) => x.id == _prov);
    final connected = s?.keys ?? const <String>[];
    return Column(
      key: const Key('keys-panel'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        KbLine(l.moWzKeysLead),
        if (connected.isNotEmpty || (s?.lockedOf('anthropic') ?? false))
          KbBox(
            children: [
              if ((s?.lockedOf('anthropic') ?? false) && !connected.contains('anthropic'))
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        providerWords(l, 'anthropic'),
                        style: TextStyle(fontWeight: FontWeight.w700, color: c.text),
                      ),
                    ),
                    Text(l.moWzLocked, style: TextStyle(color: c.dim)),
                  ],
                ),
              for (final k in connected)
                Row(
                  key: Key('key-connected-$k'),
                  children: [
                    Expanded(
                      child: Text(
                        providerWords(l, k),
                        style: TextStyle(fontWeight: FontWeight.w700, color: c.text),
                      ),
                    ),
                    TextButton(
                      key: Key('key-remove-$k'),
                      onPressed: () async {
                        try {
                          await AppScope.read(context).client?.removeKey(k);
                        } on Object {
                          // Read again below.
                        }
                        await _load();
                        await widget.onChange();
                      },
                      child: Text(l.moWzRemove),
                    ),
                  ],
                ),
            ],
          ),
        Padding(
          padding: const EdgeInsets.only(top: 6, bottom: 6),
          child: Text(
            l.moWzProvider,
            style: TextStyle(fontWeight: FontWeight.w700, color: c.text),
          ),
        ),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final x in keyProviders)
              Semantics(
                button: true,
                selected: x.id == _prov,
                child: Material(
                  color: x.id == _prov ? c.accentSoft : c.panel2,
                  shape: StadiumBorder(side: BorderSide(color: x.id == _prov ? c.accent : c.line)),
                  child: InkWell(
                    key: Key('key-provider-${x.id}'),
                    customBorder: const StadiumBorder(),
                    onTap: () => setState(() {
                      _prov = x.id;
                      _result = null;
                    }),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                      child: Text(
                        x.name,
                        style: TextStyle(
                          color: c.text,
                          fontWeight: x.id == _prov ? FontWeight.w700 : FontWeight.w500,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 10),
        TextField(
          key: const Key('key-field'),
          controller: _key,
          obscureText: true,
          autocorrect: false,
          enableSuggestions: false,
          onChanged: (_) => setState(() {}),
          decoration: InputDecoration(
            labelText: l.moWzKeyOf(p.name),
            helperText: l.moBrainKeyExample(p.keyExample),
          ),
        ),
        Align(
          alignment: Alignment.centerLeft,
          child: TextButton(
            key: const Key('key-make'),
            onPressed: () => widget.openUrl(Uri.parse(p.keyUrl)),
            child: Text(l.moBrainKeyMake(p.name)),
          ),
        ),
        if (_result != null) KbLine(_result!.$2, error: !_result!.$1),
        KbActs(
          children: [
            TextButton(onPressed: widget.onDone, child: Text(l.close)),
            FilledButton(
              key: const Key('key-try'),
              onPressed: _busy || _key.text.trim().length < 8 ? null : _save,
              child: Text(_busy ? l.moWzTrying : l.moBrainKeyTry),
            ),
          ],
        ),
      ],
    );
  }
}

/// The person's own OpenAI-compatible server: Ollama, LM Studio, vLLM…
class _ServerPanel extends StatefulWidget {
  const _ServerPanel({required this.s, required this.onChange, required this.onDone});

  final ModelsSetup s;
  final Future<void> Function() onChange;
  final void Function([void]) onDone;

  @override
  State<_ServerPanel> createState() => _ServerPanelState();
}

class _ServerPanelState extends State<_ServerPanel> {
  late final _url = TextEditingController(text: widget.s.serverUrl ?? '');
  final _key = TextEditingController();
  late bool _connected = widget.s.serverUrl != null;
  bool _busy = false;
  (bool, String)? _result;

  @override
  void dispose() {
    _url.dispose();
    _key.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final l = AppLocalizations.of(context);
    if (!mounted) return;
    final c = AppScope.read(context).client;
    if (c == null) return;
    setState(() {
      _busy = true;
      _result = null;
    });
    try {
      final models = await c.setupServer(
        _url.text.trim(),
        key: _key.text.isEmpty ? null : _key.text,
      );
      _key.clear();
      setState(() {
        _connected = true;
        _result = (true, l.moBrainKeyWorks('${models.length}'));
      });
      await widget.onChange();
    } on Object catch (e) {
      setState(() => _result = (false, rulesWhy(e)));
    }
    if (mounted) setState(() => _busy = false);
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    if (widget.s.lockedOf('server')) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          KbLine(l.moBrainServerHint, dim: true),
          KbLine(l.moWzLocked),
          KbActs(
            children: [FilledButton(onPressed: widget.onDone, child: Text(l.moWzDoneBtn))],
          ),
        ],
      );
    }
    return Column(
      key: const Key('server-panel'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        KbLine(l.moBrainServerHint, dim: true),
        const SizedBox(height: 6),
        TextField(
          key: const Key('server-url'),
          controller: _url,
          autocorrect: false,
          keyboardType: TextInputType.url,
          onChanged: (_) => setState(() {}),
          decoration: InputDecoration(
            labelText: l.moBrainServerUrl,
            helperText: l.moBrainServerUrlHelp,
            helperMaxLines: 3,
            hintText: 'http://localhost:11434/v1',
          ),
        ),
        const SizedBox(height: 10),
        TextField(
          key: const Key('server-key'),
          controller: _key,
          obscureText: true,
          autocorrect: false,
          decoration: InputDecoration(
            labelText: l.moBrainServerKey,
            helperText: widget.s.serverKeySet ? l.moWzAlreadySet : l.moBrainServerKeyHelp,
            helperMaxLines: 3,
          ),
        ),
        if (_result != null) KbLine(_result!.$2, error: !_result!.$1),
        KbActs(
          children: [
            if (_connected)
              TextButton(
                key: const Key('server-remove'),
                onPressed: () async {
                  try {
                    await AppScope.read(context).client?.removeServer();
                    setState(() => _connected = false);
                    await widget.onChange();
                  } on Object catch (e) {
                    setState(() => _result = (false, rulesWhy(e)));
                  }
                },
                child: Text(l.moBrainDisconnect),
              ),
            FilledButton(
              key: const Key('server-try'),
              onPressed: _busy || _url.text.trim().isEmpty ? null : _save,
              child: Text(_busy ? l.moWzTrying : l.moBrainKeyTry),
            ),
          ],
        ),
      ],
    );
  }
}

/// A numbered step of a sign-in (the page's `brain-steps`).
class _Numbered extends StatelessWidget {
  const _Numbered({required this.n, required this.children});

  final int n;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final c = RgColors.of(context);
    return Padding(
      padding: const EdgeInsets.only(top: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 24,
            height: 24,
            margin: const EdgeInsets.only(right: 10, top: 2),
            decoration: BoxDecoration(shape: BoxShape.circle, color: c.accentSoft),
            child: Center(
              child: Text(
                '$n',
                style: TextStyle(color: c.accent, fontWeight: FontWeight.w800, fontSize: 12.5),
              ),
            ),
          ),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: children),
          ),
        ],
      ),
    );
  }
}

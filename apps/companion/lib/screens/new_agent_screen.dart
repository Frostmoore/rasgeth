// A new agent from the app (3.8.1, the user: «the app has no way to make a new agent»): the
// page's steps (AgentWizard, NewAgentForm, AssistantWizard) for the phone, with the same API
// (`POST /api/agents`, the same fields and the server's rules):
// 1. the kind: a project's agent (under its orchestrator), a project's orchestrator (under God,
//    one per project) or a personal assistant (under God): the ones the page lets the person make;
// 2. the project, for the first two;
// 3. the name and its job in the person's words, with the face it will get (`/api/mascot/preview`);
// 4. the model, optional (the families with Subscription / API key): by default the one above;
// 5. tools to switch off, optional (`PUT /api/agents/:id/tools`, never the essential ones);
// then a look at it all and «Create». At the end: its mascot, «Change mascot», and its
// conversation.
import 'dart:async';

import 'package:flutter/material.dart';

import '../api/client.dart';
import '../api/conversation.dart';
import '../api/types.dart';
import '../app_state.dart';
import '../l10n/app_localizations.dart';
import '../l10n/tool_words.g.dart';
import '../mascot/mascot_view.dart';
import '../theme/colors.dart';
import '../ui/dialogs.dart';
import '../ui/icons.dart';
import '../ui/model_sheet.dart';
import 'team_screen.dart';

Future<void> openNewAgent(BuildContext context) =>
    Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => const NewAgentScreen()));

enum NewKind { agent, orchestrator, assistant }

enum _Step { kind, project, name, model, tools, review, done }

class NewAgentScreen extends StatefulWidget {
  const NewAgentScreen({super.key});

  @override
  State<NewAgentScreen> createState() => _NewAgentScreenState();
}

class _NewAgentScreenState extends State<NewAgentScreen> {
  NewKind? _kind;
  Project? _project;
  final _name = TextEditingController();
  final _role = TextEditingController();
  AgentModel? _model;
  final _off = <String>{};
  List<ToolEntry>? _tools;
  _Step _step = _Step.kind;
  bool _creating = false;
  String? _error;
  Agent? _made;
  Timer? _debounce;
  String _previewName = '';

  @override
  void initState() {
    super.initState();
    _name.addListener(() {
      _debounce?.cancel();
      _debounce = Timer(const Duration(milliseconds: 350), () {
        if (mounted) setState(() => _previewName = _name.text.trim());
      });
      setState(() {});
    });
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _name.dispose();
    _role.dispose();
    super.dispose();
  }

  List<_Step> get _steps => [
    _Step.kind,
    if (_kind != NewKind.assistant) _Step.project,
    _Step.name,
    _Step.model,
    _Step.tools,
    _Step.review,
  ];

  Agent? _god(AppController app) => app.god;

  Agent? _orchestratorOf(AppController app, String projectId) => app.agents
      .where((a) => a.kind == AgentKind.orchestrator && a.projectId == projectId && a.active)
      .firstOrNull;

  /// The parent the server needs: the project's orchestrator for an agent, God otherwise.
  Agent? _parent(AppController app) => switch (_kind) {
    NewKind.agent => _project == null ? null : _orchestratorOf(app, _project!.id),
    _ => _god(app),
  };

  String get _kindName => switch (_kind) {
    NewKind.agent => 'agent',
    NewKind.orchestrator => 'orchestrator',
    _ => 'assistant',
  };

  bool _canGoOn(AppController app) => switch (_step) {
    _Step.kind => _kind != null,
    _Step.project => _project != null && _projectOk(app, _project!),
    _Step.name => _name.text.trim().isNotEmpty && _name.text.trim().length <= 60,
    _ => true,
  };

  bool _projectOk(AppController app, Project p) => switch (_kind) {
    NewKind.agent => _orchestratorOf(app, p.id) != null,
    NewKind.orchestrator => _orchestratorOf(app, p.id) == null,
    _ => true,
  };

  void _next(AppController app) {
    final i = _steps.indexOf(_step);
    if (_step == _Step.review) {
      unawaited(_create(app));
      return;
    }
    setState(() => _step = _steps[i + 1]);
    if (_step == _Step.tools && _tools == null) unawaited(_loadTools(app));
  }

  void _back() {
    final i = _steps.indexOf(_step);
    if (i <= 0 || _step == _Step.done) {
      Navigator.of(context).maybePop();
      return;
    }
    setState(() => _step = _steps[i - 1]);
  }

  Future<void> _loadTools(AppController app) async {
    try {
      final t = await app.client?.tools() ?? const <ToolEntry>[];
      if (mounted) setState(() => _tools = t);
    } on ApiException {
      if (mounted) setState(() => _tools = const []);
    }
  }

  Future<void> _create(AppController app) async {
    final l = AppLocalizations.of(context);
    final parent = _parent(app);
    if (parent == null) {
      setState(() => _error = l.newAgentNeedsGod);
      return;
    }
    setState(() {
      _creating = true;
      _error = null;
    });
    try {
      final role = _role.text.trim();
      final made = await app.createAgent(
        kind: _kindName,
        parentId: parent.id,
        name: _name.text.trim(),
        projectId: _kind == NewKind.assistant ? null : _project?.id,
        role: role.isEmpty ? null : (role.length > 120 ? role.substring(0, 120) : role),
        model: _model,
        toolsOff: _off,
      );
      if (!mounted) return;
      setState(() {
        _made = made;
        _step = _Step.done;
      });
    } on ApiException catch (e) {
      if (mounted) setState(() => _error = l.newAgentFailed(e.message));
    } finally {
      if (mounted) setState(() => _creating = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    final l = AppLocalizations.of(context);
    final c = RgColors.of(context);
    final steps = _steps;
    final n = steps.indexOf(_step) + 1;
    return Scaffold(
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(4, 6, 16, 6),
              child: Row(
                children: [
                  IconButton(
                    key: const Key('new-agent-close'),
                    tooltip: l.back,
                    onPressed: () => Navigator.of(context).maybePop(),
                    icon: RgIcon(RgIcons.x, color: c.text),
                  ),
                  Expanded(
                    child: Text(
                      l.newAgentTitle,
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: c.text),
                    ),
                  ),
                  if (_step != _Step.done)
                    Text(
                      l.newAgentStep(n, steps.length),
                      key: const Key('new-agent-step'),
                      style: TextStyle(color: c.dim, fontSize: 13),
                    ),
                ],
              ),
            ),
            if (_step != _Step.done)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: n / steps.length,
                    minHeight: 4,
                    backgroundColor: c.line,
                    color: c.accent,
                  ),
                ),
              ),
            Expanded(
              child: SingleChildScrollView(
                key: const Key('new-agent-body'),
                padding: const EdgeInsets.fromLTRB(20, 18, 20, 20),
                child: switch (_step) {
                  _Step.kind => _kindStep(l, c),
                  _Step.project => _projectStep(app, l, c),
                  _Step.name => _nameStep(app, l, c),
                  _Step.model => _modelStep(app, l, c),
                  _Step.tools => _toolsStep(l, c),
                  _Step.review => _reviewStep(app, l, c),
                  _Step.done => _doneStep(app, l, c),
                },
              ),
            ),
            if (_error != null)
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
                child: Text(
                  _error!,
                  key: const Key('new-agent-error'),
                  style: TextStyle(color: c.err),
                ),
              ),
            if (_step != _Step.done)
              Container(
                padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
                decoration: BoxDecoration(
                  border: Border(top: BorderSide(color: c.line)),
                ),
                child: Row(
                  children: [
                    if (n > 1)
                      OutlinedButton(
                        key: const Key('new-agent-back'),
                        style: OutlinedButton.styleFrom(minimumSize: const Size(0, 48)),
                        onPressed: _creating ? null : _back,
                        child: Text(l.newAgentBack),
                      ),
                    if (n > 1) const SizedBox(width: 10),
                    Expanded(
                      child: FilledButton(
                        key: const Key('new-agent-next'),
                        style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(48)),
                        onPressed: _canGoOn(app) && !_creating ? () => _next(app) : null,
                        child: Text(
                          _step == _Step.review
                              ? (_creating ? l.newAgentCreating : l.newAgentCreate)
                              : l.newAgentNext,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _title(RgColors c, String t) => Padding(
    padding: const EdgeInsets.only(bottom: 14),
    child: Text(
      t,
      style: TextStyle(fontSize: 21, fontWeight: FontWeight.w800, color: c.text),
    ),
  );

  Widget _kindStep(AppLocalizations l, RgColors c) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      _title(c, l.newAgentKindQ),
      for (final (k, title, text, icon) in [
        (NewKind.agent, l.newAgentKindAgent, l.newAgentKindAgentText, RgIcons.tool),
        (NewKind.orchestrator, l.newAgentKindOrch, l.newAgentKindOrchText, RgIcons.users),
        (NewKind.assistant, l.newAgentKindAsst, l.newAgentKindAsstText, RgIcons.user),
      ])
        _Choice(
          key: Key('new-kind-${k.name}'),
          icon: icon,
          title: title,
          text: text,
          on: _kind == k,
          onTap: () => setState(() {
            _kind = k;
            _project = null;
          }),
        ),
    ],
  );

  Widget _projectStep(AppController app, AppLocalizations l, RgColors c) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      _title(c, l.newAgentProjectQ),
      if (app.projects.isEmpty) Text(l.newAgentNoProjects, style: TextStyle(color: c.dim)),
      for (final p in app.projects)
        _Choice(
          key: Key('new-project-${p.id}'),
          icon: RgIcons.folder,
          title: p.name,
          text: _projectOk(app, p)
              ? null
              : (_kind == NewKind.agent ? l.newAgentNoOrch : l.newAgentHasOrch),
          on: _project?.id == p.id,
          enabled: _projectOk(app, p),
          onTap: () => setState(() => _project = p),
        ),
    ],
  );

  Widget _nameStep(AppController app, AppLocalizations l, RgColors c) {
    final client = app.client;
    final name = _previewName;
    final dark = Theme.of(context).brightness == Brightness.dark;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _title(c, l.newAgentNameQ),
        TextField(
          key: const Key('new-agent-name'),
          controller: _name,
          maxLength: 60,
          textCapitalization: TextCapitalization.sentences,
          decoration: InputDecoration(labelText: l.newAgentName),
        ),
        const SizedBox(height: 8),
        TextField(
          key: const Key('new-agent-role'),
          controller: _role,
          minLines: 2,
          maxLines: 4,
          maxLength: 120,
          decoration: InputDecoration(labelText: l.newAgentRole, hintText: l.newAgentRoleHint),
        ),
        const SizedBox(height: 14),
        Text(
          l.newAgentMascotPreview,
          style: TextStyle(fontWeight: FontWeight.w700, color: c.dim, fontSize: 13),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            SizedBox(
              width: 96,
              height: 96,
              child: name.isEmpty || client == null
                  ? Center(child: RgIcon(RgIcons.user, size: 40, color: c.line))
                  : FutureBuilder<String>(
                      key: ValueKey('$name|$_kindName|$dark'),
                      future: client.mascotPreviewSvg(
                        name,
                        kind: _kindName,
                        parentId: _parent(app)?.id,
                        theme: dark ? MascotTheme.dark : MascotTheme.light,
                      ),
                      builder: (context, snap) => snap.hasData
                          ? MascotView(
                              key: const Key('new-agent-mascot'),
                              svg: snap.data,
                              size: 96,
                              state: MascotState.idle,
                            )
                          : const SizedBox(),
                    ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(l.newAgentMascotLater, style: TextStyle(color: c.dim, fontSize: 13)),
            ),
          ],
        ),
      ],
    );
  }

  String _inheritLabel(AppController app, AppLocalizations l) {
    if (_kind != NewKind.agent) return l.newAgentModelGod;
    final up = _parent(app);
    final m = up?.model ?? (up == null ? null : app.inheritedModelOf(up));
    return m == null
        ? l.agentModelInherit
        : l.modelInheritOf(l.agentModelInherit, modelWords(l, app.knownModels, m));
  }

  Widget _modelStep(AppController app, AppLocalizations l, RgColors c) {
    final m = _model;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _title(c, l.newAgentModelQ),
        Text(l.newAgentModelLead, style: TextStyle(color: c.dim)),
        const SizedBox(height: 12),
        _Choice(
          key: const Key('new-agent-model'),
          icon: RgIcons.zap,
          title: m == null ? _inheritLabel(app, l) : modelWords(l, app.knownModels, m),
          text: l.agentModel,
          on: m != null,
          onTap: () async {
            final models = await app.modelChoices(again: true);
            if (!mounted) return;
            if (models.isEmpty) {
              setState(() => _error = l.noModels);
              return;
            }
            final pick = await showModelPicker(
              context,
              title: l.agentModel,
              models: models,
              current: _model,
              inheritLabel: _inheritLabel(app, l),
            );
            if (pick != null && mounted) setState(() => _model = pick.model);
          },
        ),
      ],
    );
  }

  String _word(String key, String fallback) {
    final lang = Localizations.localeOf(context).languageCode == 'en' ? 'en' : 'it';
    return toolWords[lang]?[key] ?? fallback;
  }

  Widget _toolsStep(AppLocalizations l, RgColors c) {
    final tools = _tools;
    final groups = <String, List<ToolEntry>>{};
    for (final t in tools ?? const <ToolEntry>[]) {
      if (t.essential || !t.globalOn) continue;
      (groups[t.group] ??= []).add(t);
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _title(c, l.newAgentToolsQ),
        Text(l.newAgentToolsLead, style: TextStyle(color: c.dim)),
        const SizedBox(height: 12),
        if (tools == null) const Center(child: CircularProgressIndicator()),
        for (final MapEntry(key: g, value: list) in groups.entries) ...[
          Padding(
            padding: const EdgeInsets.only(top: 8, bottom: 6),
            child: Text(
              _word('toolGrp_$g', g),
              style: TextStyle(fontWeight: FontWeight.w800, color: c.dim, fontSize: 13),
            ),
          ),
          for (final t in list)
            Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Material(
                color: c.panel,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(color: c.line),
                ),
                child: InkWell(
                  key: Key('new-tool-${t.id}'),
                  borderRadius: BorderRadius.circular(12),
                  onTap: () =>
                      setState(() => _off.contains(t.id) ? _off.remove(t.id) : _off.add(t.id)),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _word('tool_${t.id}', t.id),
                                style: TextStyle(fontWeight: FontWeight.w700, color: c.text),
                              ),
                              if (toolWords['it']?['toolDo_${t.id}'] != null)
                                Text(
                                  _word('toolDo_${t.id}', ''),
                                  style: TextStyle(color: c.dim, fontSize: 12.5),
                                ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 10),
                        RgSwitch(on: !_off.contains(t.id)),
                      ],
                    ),
                  ),
                ),
              ),
            ),
        ],
      ],
    );
  }

  Widget _reviewStep(AppController app, AppLocalizations l, RgColors c) {
    final kind = switch (_kind) {
      NewKind.agent => l.newAgentKindAgent,
      NewKind.orchestrator => l.newAgentKindOrch,
      _ => l.newAgentKindAsst,
    };
    Widget line(String k, String v) => Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 110,
            child: Text(k, style: TextStyle(color: c.dim)),
          ),
          Expanded(
            child: Text(
              v,
              style: TextStyle(color: c.text, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _title(c, l.newAgentReview),
        line(l.newAgentName, _name.text.trim()),
        line(l.reviewKind, kind),
        if (_project != null && _kind != NewKind.assistant) line(l.reviewProject, _project!.name),
        if (_role.text.trim().isNotEmpty) line(l.newAgentRole, _role.text.trim()),
        line(
          l.agentModel,
          _model == null ? _inheritLabel(app, l) : modelWords(l, app.knownModels, _model!),
        ),
        line(l.reviewTools, _off.isEmpty ? l.reviewAllTools : l.newAgentToolsOff(_off.length)),
      ],
    );
  }

  Widget _doneStep(AppController app, AppLocalizations l, RgColors c) {
    final made = app.agents.where((a) => a.id == _made?.id).firstOrNull ?? _made!;
    return Column(
      key: const Key('new-agent-done'),
      children: [
        MascotView(
          key: ValueKey('done-${made.mascotSeed}'),
          agentId: made.id,
          spec: made.mascot,
          state: MascotState.active,
          size: 150,
        ),
        const SizedBox(height: 10),
        Text(
          l.newAgentMade(made.name),
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: c.text),
        ),
        const SizedBox(height: 18),
        FilledButton.icon(
          key: const Key('new-agent-open'),
          style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(48)),
          onPressed: () async {
            final nav = Navigator.of(context);
            final parent = nav.context;
            nav.pop();
            await openAgentConversation(parent, made);
          },
          icon: const RgIcon(RgIcons.chat, size: 18, color: Colors.white),
          label: Text(l.newAgentOpen(made.name)),
        ),
        const SizedBox(height: 8),
        OutlinedButton.icon(
          key: const Key('new-agent-mascot-change'),
          style: OutlinedButton.styleFrom(minimumSize: const Size.fromHeight(46)),
          onPressed: () async {
            final yes = await askConfirm(
              context,
              title: l.mascotChange,
              body: l.mascotChangeAsk(made.name),
              yes: l.mascotChangeYes,
            );
            if (!yes || !mounted) return;
            final updated = await app.changeMascot(made);
            if (updated != null && mounted) setState(() => _made = updated);
          },
          icon: RgIcon(RgIcons.refresh, size: 18, color: c.text),
          label: Text(l.mascotChange),
        ),
      ],
    );
  }
}

class _Choice extends StatelessWidget {
  const _Choice({
    super.key,
    required this.icon,
    required this.title,
    this.text,
    required this.on,
    required this.onTap,
    this.enabled = true,
  });

  final RgIcons icon;
  final String title;
  final String? text;
  final bool on;
  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = RgColors.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Semantics(
        selected: on,
        button: true,
        enabled: enabled,
        child: Material(
          color: on ? c.accentSoft : c.panel,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(color: on ? c.accent : c.line, width: on ? 1.6 : 1),
          ),
          child: InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: enabled ? onTap : null,
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Row(
                children: [
                  RgIcon(icon, size: 22, color: enabled ? c.text : c.dim),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 15.5,
                            color: enabled ? c.text : c.dim,
                          ),
                        ),
                        if (text != null) Text(text!, style: TextStyle(color: c.dim, fontSize: 13)),
                      ],
                    ),
                  ),
                  if (on) RgIcon(RgIcons.check, size: 20, color: c.accent),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Our own drawn on/off (never a native switch): the whole row is the tap.
class RgSwitch extends StatelessWidget {
  const RgSwitch({super.key, required this.on});

  final bool on;

  @override
  Widget build(BuildContext context) {
    final c = RgColors.of(context);
    return Semantics(
      toggled: on,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        width: 44,
        height: 26,
        padding: const EdgeInsets.all(3),
        decoration: BoxDecoration(
          color: on ? c.accent : c.line,
          borderRadius: BorderRadius.circular(13),
        ),
        child: AnimatedAlign(
          duration: const Duration(milliseconds: 160),
          alignment: on ? Alignment.centerRight : Alignment.centerLeft,
          child: Container(
            width: 20,
            height: 20,
            decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
          ),
        ),
      ),
    );
  }
}

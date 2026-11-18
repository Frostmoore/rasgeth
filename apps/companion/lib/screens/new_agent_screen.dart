// A new agent from the app (3.8.1, the user: «the app has no way to make a new agent»; G42.4:
// every step of the page's wizards, AgentWizard and AssistantWizard), with the same API
// (`POST /api/agents`, the same fields and the server's rules):
// 1. the kind: a project's agent (under its orchestrator), a project's orchestrator (under God,
//    one per project) or a personal assistant (under God): the ones the page lets the person make;
//    for an assistant, «Ask God» too (God proposes two or three, made only after a yes);
// 2. the project, for the first two, and where in it a project's agent works (a subproject);
// 3. what it does: the page's ready roles (programmer, reviewer…) or jobs (secretary…), or the
//    person's own words;
// 4. the name (and an orchestrator's or an assistant's job), with the face it will get;
// 5. an assistant's services (MCP servers added for everyone);
// 6. the model, optional (the families with Subscription / API key): by default the one above;
// 7. how much it may do alone (the four modes; an assistant's two);
// 8. its instructions and tools: God writes them from the built-in ones and what was chosen here
//    and proposes its tools (`goal: "draft"`); the person reads, changes, or keeps the built-in
//    ones; when God cannot, the tools to switch off by hand (never the essential ones);
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
import '../settings/agents/assistant_parts.dart' show serviceName, serviceState;
import '../settings/api/agents_api.dart';
import '../settings/api/general_api.dart';
import '../settings/prompt_refiner.dart';
import '../theme/colors.dart';
import '../ui/dialogs.dart';
import '../ui/icons.dart';
import '../ui/model_sheet.dart';
import 'conversation_screen.dart';
import 'team_screen.dart';

Future<void> openNewAgent(BuildContext context) =>
    Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => const NewAgentScreen()));

enum NewKind { agent, orchestrator, assistant }

enum _Step { kind, project, job, name, services, model, mode, instructions, review, done }

/// The page's ready roles for a project's agent; their instructions are for the model, so in
/// English like every prompt (AgentWizard.tsx `ROLES`).
const agentRoles = <String, String>{
  'coder': "Write and change the project's code. Run its tests before saying you are done, and keep commits small and clear.",
  'reviewer': 'Review changes for bugs, risks and unclear code. Report each finding with file and line and why it matters; do not change code unless asked.',
  'researcher': "Look things up on the web and in the project's files. Report what you find with its sources, and say what you could not confirm.",
  'writer': 'Write and keep the documentation, READMEs and texts clear, correct and up to date with the code.',
  'tester':
      'Write and run tests, reproduce reported bugs and describe them with the steps to see them.',
  'custom': '',
};

/// The page's ready jobs for a personal assistant (Assistants.tsx `JOBS`): the job text is the
/// person's, in their language.
const assistantJobs = ['secretary', 'researcher', 'social', 'accounts', 'tech', 'custom'];

String agentRoleTitle(AppLocalizations l, String r) => switch (r) {
  'coder' => l.g4AgRole_coder,
  'reviewer' => l.g4AgRole_reviewer,
  'researcher' => l.g4AgRole_researcher,
  'writer' => l.g4AgRole_writer,
  'tester' => l.g4AgRole_tester,
  _ => l.g4AgRole_custom,
};

String agentRoleText(AppLocalizations l, String r) => switch (r) {
  'coder' => l.g4AgRoleText_coder,
  'reviewer' => l.g4AgRoleText_reviewer,
  'researcher' => l.g4AgRoleText_researcher,
  'writer' => l.g4AgRoleText_writer,
  'tester' => l.g4AgRoleText_tester,
  _ => l.g4AgRoleText_custom,
};

String jobTitle(AppLocalizations l, String j) => switch (j) {
  'secretary' => l.g4AgJob_secretary,
  'researcher' => l.g4AgJob_researcher,
  'social' => l.g4AgJob_social,
  'accounts' => l.g4AgJob_accounts,
  'tech' => l.g4AgJob_tech,
  _ => l.g4AgJob_custom,
};

String jobHint(AppLocalizations l, String j) => switch (j) {
  'secretary' => l.g4AgJobHint_secretary,
  'researcher' => l.g4AgJobHint_researcher,
  'social' => l.g4AgJobHint_social,
  'accounts' => l.g4AgJobHint_accounts,
  'tech' => l.g4AgJobHint_tech,
  _ => l.g4AgJobHint_custom,
};

String jobText(AppLocalizations l, String j) => switch (j) {
  'secretary' => l.g4AgJobText_secretary,
  'researcher' => l.g4AgJobText_researcher,
  'social' => l.g4AgJobText_social,
  'accounts' => l.g4AgJobText_accounts,
  'tech' => l.g4AgJobText_tech,
  _ => '',
};

class NewAgentScreen extends StatefulWidget {
  const NewAgentScreen({super.key});

  @override
  State<NewAgentScreen> createState() => _NewAgentScreenState();
}

class _NewAgentScreenState extends State<NewAgentScreen> {
  NewKind? _kind;
  Project? _project;
  List<Subproject>? _subs;
  String? _sub;
  String _role = 'coder';
  String _job = 'secretary';
  final _own = TextEditingController();
  final _name = TextEditingController();
  final _jobWords = TextEditingController();
  bool _named = false;
  AgentModel? _model;
  String _mode = 'auto';
  List<ServiceEntry>? _services;
  final _connections = <String>{};
  final _off = <String>{};
  List<ToolEntry>? _tools;
  DraftOutcome? _outcome;
  String? _estimate;
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
    _own.addListener(() => setState(() {}));
    _jobWords.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _name.dispose();
    _own.dispose();
    _jobWords.dispose();
    super.dispose();
  }

  List<_Step> get _steps => [
    _Step.kind,
    if (_kind != NewKind.assistant) _Step.project,
    if (_kind != NewKind.orchestrator) _Step.job,
    _Step.name,
    if (_kind == NewKind.assistant) _Step.services,
    _Step.model,
    _Step.mode,
    _Step.instructions,
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

  /// What it does, as sent to the server (`role`, at most 120 characters for an agent).
  String? get _roleSent {
    final l = AppLocalizations.of(context);
    final String r = switch (_kind) {
      NewKind.agent => _role == 'custom' ? _own.text.trim() : agentRoleTitle(l, _role),
      _ => _jobWords.text.trim(),
    };
    if (r.isEmpty) return null;
    return _kind == NewKind.agent && r.length > 120 ? r.substring(0, 120) : r;
  }

  /// The job God reads (for a project's agent the ready role's own instructions).
  String get _draftJob => switch (_kind) {
    NewKind.agent => _role == 'custom' ? _own.text.trim() : agentRoles[_role]!,
    _ => _jobWords.text.trim(),
  };

  Map<String, Object?> get _draft => {
    'kind': _kindName,
    'name': _name.text.trim().length > 80 ? _name.text.trim().substring(0, 80) : _name.text.trim(),
    if (_draftJob.isNotEmpty)
      'role': _draftJob.length > 2000 ? _draftJob.substring(0, 2000) : _draftJob,
    if (_kind != NewKind.assistant && _project != null) 'projectId': _project!.id,
    'mode': _mode,
    if (_model != null) 'model': _model!.key,
  };

  bool _canGoOn(AppController app) => switch (_step) {
    _Step.kind => _kind != null,
    _Step.project => _project != null && _projectOk(app, _project!),
    _Step.job => _kind == NewKind.agent ? (_role != 'custom' || _own.text.trim().isNotEmpty) : true,
    _Step.name =>
      _name.text.trim().isNotEmpty &&
          _name.text.trim().length <= 60 &&
          (_kind != NewKind.assistant || _jobWords.text.trim().isNotEmpty),
    _Step.instructions => _outcome != null,
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
    // The ready role or job names it, until the person types a name of their own.
    if (_step == _Step.job && !_named) {
      final l = AppLocalizations.of(context);
      _name.text = _kind == NewKind.agent
          ? (_role == 'custom' ? '' : agentRoleTitle(l, _role))
          : (_job == 'custom' ? '' : jobTitle(l, _job));
    }
    setState(() {
      _step = _steps[i + 1];
      _error = null;
    });
    if (_step == _Step.services && _services == null) unawaited(_loadServices(app));
    if (_step == _Step.mode) unawaited(_loadEstimate(app));
    if (_step == _Step.instructions) {
      _outcome = null;
      if (_tools == null) unawaited(_loadTools(app));
    }
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

  Future<void> _loadSubs(AppController app, Project p) async {
    setState(() {
      _subs = null;
      _sub = null;
    });
    try {
      final s = await app.client?.subprojects(p.id) ?? const <Subproject>[];
      if (mounted && _project?.id == p.id) setState(() => _subs = s);
    } on ApiException {
      if (mounted) setState(() => _subs = const []);
    }
  }

  Future<void> _loadServices(AppController app) async {
    try {
      final s = await app.client?.assistantServices() ?? const <ServiceEntry>[];
      if (mounted) setState(() => _services = s);
    } on ApiException {
      if (mounted) setState(() => _services = const []);
    }
  }

  /// The line under «Next: God writes its instructions»: about what it costs (nothing spent yet).
  Future<void> _loadEstimate(AppController app) async {
    final l = AppLocalizations.of(context);
    final lang = Localizations.localeOf(context).languageCode == 'en' ? 'en' : 'it';
    setState(() => _estimate = null);
    try {
      final g = await app.client!.refineGuess(
        RefineDraft(_draft),
        goal: 'draft',
        lang: lang,
        model: await readWriterModel(app),
      );
      if (mounted) setState(() => _estimate = refineCostWords(l, g.tokens, g.usd));
    } on Object {
      // No estimate: the line says only what happens next.
    }
  }

  /// «Ask God» (assistants): a new conversation with God asking which personal agents would
  /// help, made only after the person's yes.
  Future<void> _askGod(AppController app) async {
    final l = AppLocalizations.of(context);
    final god = app.god;
    if (god == null) {
      setState(() => _error = l.newAgentNeedsGod);
      return;
    }
    final nav = Navigator.of(context);
    final id = await app.openAgent(god, fresh: true);
    if (id == null || !mounted) return;
    nav.pop();
    unawaited(
      nav.push(
        MaterialPageRoute<void>(
          builder: (_) =>
              ConversationScreen(sessionId: id, agent: god, firstMessage: l.g4AgAskGodMessage),
        ),
      ),
    );
  }

  Future<void> _create(AppController app) async {
    final l = AppLocalizations.of(context);
    final parent = _parent(app);
    final c = app.client;
    if (parent == null || c == null) {
      setState(() => _error = l.newAgentNeedsGod);
      return;
    }
    setState(() {
      _creating = true;
      _error = null;
    });
    try {
      final a = await c.createAgentWith(
        kind: _kindName,
        parentId: parent.id,
        name: _name.text.trim(),
        projectId: _kind == NewKind.assistant ? null : _project?.id,
        subprojectId: _kind == NewKind.agent ? _sub : null,
        role: _roleSent,
        model: _model,
        mode: _mode,
        connections: _kind == NewKind.assistant ? (_connections.toList()..sort()) : null,
      );
      // Its instructions as God wrote them (or as the person changed them), and the tools it
      // starts without: God's proposal, or the ones switched off by hand.
      final text = _outcome?.text.trim() ?? '';
      if (text.isNotEmpty) await c.setPrompt(_outcome!.text, agentId: a.id);
      final proposed = _outcome?.tools;
      final off = proposed != null
          ? {
              for (final t in proposed)
                if (!t.on) t.id,
            }
          : _off;
      if (off.isNotEmpty) await c.setAgentTools(a.id, {for (final t in off) t: 'off'});
      await app.refresh();
      if (!mounted) return;
      setState(() {
        _made = app.agents.where((x) => x.id == a.id).firstOrNull ?? a;
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
    final god = app.god?.name ?? 'God';
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
              child: Align(
                alignment: Alignment.topCenter,
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 720),
                  child: SingleChildScrollView(
                    key: const Key('new-agent-body'),
                    padding: const EdgeInsets.fromLTRB(20, 18, 20, 20),
                    child: switch (_step) {
                      _Step.kind => _kindStep(app, l, c),
                      _Step.project => _projectStep(app, l, c),
                      _Step.job => _jobStep(l, c),
                      _Step.name => _nameStep(app, l, c),
                      _Step.services => _servicesStep(l, c),
                      _Step.model => _modelStep(app, l, c),
                      _Step.mode => _modeStep(l, c, god),
                      _Step.instructions => _instructionsStep(l, c),
                      _Step.review => _reviewStep(app, l, c),
                      _Step.done => _doneStep(app, l, c),
                    },
                  ),
                ),
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
                // On a computer the buttons keep the steps' measure, in the middle.
                alignment: Alignment.topCenter,
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 680),
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
                                : _step == _Step.mode
                                ? l.g4AgDraftNext(god)
                                : l.newAgentNext,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ),
                    ],
                  ),
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

  Widget _lead(RgColors c, String t) => Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: Text(t, style: TextStyle(color: c.dim, height: 1.35)),
  );

  Widget _kindStep(AppController app, AppLocalizations l, RgColors c) => Column(
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
            _subs = null;
            _sub = null;
            _named = false;
            _mode = 'auto';
            if (k == NewKind.assistant && _jobWords.text.isEmpty) {
              _jobWords.text = jobText(l, _job);
            }
          }),
        ),
      if (_kind == NewKind.assistant)
        Padding(
          padding: const EdgeInsets.only(top: 6),
          child: Wrap(
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Text(l.g4AgOrAskGod, style: TextStyle(color: c.dim)),
              TextButton(
                key: const Key('new-agent-ask-god'),
                onPressed: () => _askGod(app),
                child: Text(l.g4AgAskGod(app.god?.name ?? 'God')),
              ),
            ],
          ),
        ),
    ],
  );

  Widget _projectStep(AppController app, AppLocalizations l, RgColors c) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      _title(c, l.newAgentProjectQ),
      if (_kind == NewKind.agent) _lead(c, l.g4AgStep2Help),
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
          onTap: () {
            setState(() => _project = p);
            if (_kind == NewKind.agent) unawaited(_loadSubs(app, p));
          },
        ),
      // Where in it (a subproject): only when the project has some.
      if (_kind == NewKind.agent && (_subs?.isNotEmpty ?? false)) ...[
        const SizedBox(height: 10),
        Text(
          l.g4AgWhere,
          style: TextStyle(fontWeight: FontWeight.w800, color: c.text, fontSize: 16),
        ),
        _lead(c, l.g4AgWhereHelp),
        _Choice(
          key: const Key('new-sub-whole'),
          icon: RgIcons.folder,
          title: l.g4AgWholeProject,
          on: _sub == null,
          onTap: () => setState(() => _sub = null),
        ),
        for (final s in _subs!)
          _Choice(
            key: Key('new-sub-${s.id}'),
            icon: RgIcons.branch,
            title: s.name,
            text: '${s.dir}/',
            on: _sub == s.id,
            onTap: () => setState(() => _sub = s.id),
          ),
      ],
    ],
  );

  Widget _jobStep(AppLocalizations l, RgColors c) {
    if (_kind == NewKind.assistant) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _title(c, l.g4AgStep1),
          _lead(c, l.g4AgAsstPurpose),
          for (final j in assistantJobs)
            _Choice(
              key: Key('new-job-$j'),
              icon: j == 'custom' ? RgIcons.edit : RgIcons.user,
              title: jobTitle(l, j),
              text: jobHint(l, j),
              on: _job == j,
              onTap: () => setState(() {
                _job = j;
                _jobWords.text = jobText(l, j);
              }),
            ),
        ],
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _title(c, l.g4AgStep1),
        for (final r in agentRoles.keys)
          _Choice(
            key: Key('new-role-$r'),
            icon: r == 'custom' ? RgIcons.edit : RgIcons.tool,
            title: agentRoleTitle(l, r),
            text: agentRoleText(l, r),
            on: _role == r,
            onTap: () => setState(() => _role = r),
          ),
        if (_role == 'custom') ...[
          const SizedBox(height: 4),
          TextField(
            key: const Key('new-agent-own'),
            controller: _own,
            minLines: 2,
            maxLines: 4,
            decoration: InputDecoration(
              labelText: l.g4AgOwnWords,
              helperText: l.g4AgOwnWordsHelp,
              helperMaxLines: 3,
            ),
          ),
        ],
      ],
    );
  }

  Widget _nameStep(AppController app, AppLocalizations l, RgColors c) {
    final client = app.client;
    final name = _previewName;
    final dark = Theme.of(context).brightness == Brightness.dark;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _title(c, _kind == NewKind.agent ? l.g4AgStep3 : l.newAgentNameQ),
        TextField(
          key: const Key('new-agent-name'),
          controller: _name,
          maxLength: 60,
          textCapitalization: TextCapitalization.sentences,
          decoration: InputDecoration(labelText: l.newAgentName),
          onChanged: (_) => _named = true,
        ),
        if (_kind != NewKind.agent) ...[
          const SizedBox(height: 8),
          TextField(
            key: const Key('new-agent-role'),
            controller: _jobWords,
            minLines: 2,
            maxLines: 5,
            maxLength: _kind == NewKind.orchestrator ? 120 : 2000,
            decoration: InputDecoration(
              labelText: _kind == NewKind.assistant ? l.g4AgAsstRole : l.newAgentRole,
              hintText: _kind == NewKind.assistant ? null : l.newAgentRoleHint,
              helperText: _kind == NewKind.assistant ? l.g4AgAsstRoleHelp : null,
              helperMaxLines: 3,
            ),
          ),
        ],
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

  Widget _servicesStep(AppLocalizations l, RgColors c) {
    final list = _services;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _title(c, l.g4AgStep2Asst),
        _lead(c, l.g4AgStep2AsstHelp),
        if (list == null) const Center(child: CircularProgressIndicator()),
        if (list != null && list.isEmpty)
          Text(
            l.g4AgNoServices,
            key: const Key('new-no-services'),
            style: TextStyle(color: c.dim),
          ),
        for (final s in list ?? const <ServiceEntry>[])
          _SwitchCard(
            key: Key('new-service-${s.name}'),
            title: serviceName(s.name),
            text: serviceState(l, s),
            on: _connections.contains(s.name),
            onTap: () => setState(
              () => _connections.contains(s.name)
                  ? _connections.remove(s.name)
                  : _connections.add(s.name),
            ),
          ),
        const SizedBox(height: 6),
        Text(l.g4AgAddServiceHint, style: TextStyle(color: c.dim, fontSize: 12.5)),
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
        Text(
          _kind == NewKind.agent ? l.g4AgStep4Help : l.newAgentModelLead,
          style: TextStyle(color: c.dim),
        ),
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

  Widget _modeStep(AppLocalizations l, RgColors c, String god) {
    final List<(String, String, String)> modes = _kind == NewKind.assistant
        ? [
            ('auto', l.g4AgAsstMode_auto, l.g4AgAsstModeText_auto),
            ('manual', l.g4AgAsstMode_manual, l.g4AgAsstModeText_manual),
          ]
        : [
            ('auto', l.asMode_auto, l.g4AgModeText_auto),
            ('manual', l.asMode_manual, l.g4AgModeText_manual),
            ('plan', l.asMode_plan, l.g4AgModeText_plan),
            ('readonly', l.asMode_readonly, l.g4AgModeText_readonly),
          ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _title(c, _kind == NewKind.assistant ? l.g4AgStep3Asst : l.g4AgStep5),
        for (final (m, title, text) in modes)
          _Choice(
            key: Key('new-mode-$m'),
            icon: switch (m) {
              'auto' => RgIcons.zap,
              'manual' => RgIcons.help,
              'plan' => RgIcons.list,
              _ => RgIcons.lock,
            },
            title: m == 'auto' ? '$title · ${l.g4AgRecommended}' : title,
            text: text,
            on: _mode == m,
            onTap: () => setState(() => _mode = m),
          ),
        const SizedBox(height: 6),
        Text(
          [l.g4AgDraftNextHint(god), if (_estimate != null) l.refineEstimate(_estimate!)].join(' '),
          key: const Key('new-agent-estimate'),
          style: TextStyle(color: c.dim, fontSize: 12.5),
        ),
      ],
    );
  }

  String _word(String key, String fallback) {
    final lang = Localizations.localeOf(context).languageCode == 'en' ? 'en' : 'it';
    return toolWords[lang]?[key] ?? fallback;
  }

  Widget _instructionsStep(AppLocalizations l, RgColors c) {
    final job = _draftJob;
    final failed = _outcome != null && _outcome!.tools == null;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _title(c, l.g4AgDraftTitle),
        DraftInstructions(
          key: const Key('new-agent-draft'),
          draft: _draft,
          fallback: (base) => _kind == NewKind.agent && job.isNotEmpty ? '$base\n\n$job' : base,
          onChange: (o) => setState(() => _outcome = o),
        ),
        // Without God's choice of tools (it could not write, or the built-in ones were kept):
        // the tools to switch off by hand, never the essential ones.
        if (failed) ...[const SizedBox(height: 14), ..._manualTools(l, c)],
      ],
    );
  }

  List<Widget> _manualTools(AppLocalizations l, RgColors c) {
    final tools = _tools;
    final groups = <String, List<ToolEntry>>{};
    for (final t in tools ?? const <ToolEntry>[]) {
      if (t.essential || !t.globalOn) continue;
      (groups[t.group] ??= []).add(t);
    }
    return [
      Text(
        l.newAgentToolsQ,
        style: TextStyle(fontWeight: FontWeight.w800, color: c.text, fontSize: 16),
      ),
      Text(l.newAgentToolsLead, style: TextStyle(color: c.dim)),
      const SizedBox(height: 8),
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
          _SwitchCard(
            key: Key('new-tool-${t.id}'),
            title: _word('tool_${t.id}', t.id),
            text: toolWords['it']?['toolDo_${t.id}'] != null ? _word('toolDo_${t.id}', '') : null,
            on: !_off.contains(t.id),
            onTap: () => setState(() => _off.contains(t.id) ? _off.remove(t.id) : _off.add(t.id)),
          ),
      ],
    ];
  }

  Widget _reviewStep(AppController app, AppLocalizations l, RgColors c) {
    final kind = switch (_kind) {
      NewKind.agent => l.newAgentKindAgent,
      NewKind.orchestrator => l.newAgentKindOrch,
      _ => l.newAgentKindAsst,
    };
    final mode = switch (_mode) {
      'manual' => _kind == NewKind.assistant ? l.g4AgAsstMode_manual : l.asMode_manual,
      'plan' => l.asMode_plan,
      'readonly' => l.asMode_readonly,
      _ => _kind == NewKind.assistant ? l.g4AgAsstMode_auto : l.asMode_auto,
    };
    final proposed = _outcome?.tools;
    final off = proposed != null ? proposed.where((t) => !t.on).length : _off.length;
    final sub = _subs?.where((s) => s.id == _sub).firstOrNull;
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
        if (sub != null) line(l.g4AgWhere, '${sub.name} (${sub.dir}/)'),
        if (_roleSent != null) line(l.newAgentRole, _roleSent!),
        if (_kind == NewKind.assistant)
          line(
            l.g4AgServices,
            _connections.isEmpty
                ? l.g4AgNoneChosen
                : (_connections.map(serviceName).toList()..sort()).join(', '),
          ),
        line(
          l.agentModel,
          _model == null ? _inheritLabel(app, l) : modelWords(l, app.knownModels, _model!),
        ),
        line(l.asMode, mode),
        line(
          l.agentInstructions,
          (_outcome?.text.trim().isNotEmpty ?? false) ? l.g4AgReviewWritten : l.g4AgReviewBuiltIn,
        ),
        line(l.reviewTools, off == 0 ? l.reviewAllTools : l.newAgentToolsOff(off)),
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

/// A row with our switch: the whole card is the tap.
class _SwitchCard extends StatelessWidget {
  const _SwitchCard({
    super.key,
    required this.title,
    this.text,
    required this.on,
    required this.onTap,
  });

  final String title;
  final String? text;
  final bool on;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = RgColors.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Material(
        color: c.panel,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: c.line),
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: TextStyle(fontWeight: FontWeight.w700, color: c.text),
                      ),
                      if (text != null && text!.isNotEmpty)
                        Text(text!, style: TextStyle(color: c.dim, fontSize: 12.5)),
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                RgSwitch(on: on),
              ],
            ),
          ),
        ),
      ),
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

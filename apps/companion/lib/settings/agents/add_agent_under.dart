// G42.4: «Add an agent under {name}», the page's technical form (Hierarchy.tsx, NewAgentForm):
// the kind among those that may hang there, the name, what it does, the project (a lead or an
// inspector), the model (by default the one above it) and how freely it works. A window on a
// computer, a whole screen on a phone; `POST /api/agents` with the page's fields.
import 'package:flutter/material.dart';

import '../../api/client.dart';
import '../../api/types.dart';
import '../../app_state.dart';
import '../../l10n/app_localizations.dart';
import '../../screens/agent_settings_screen.dart' show kindWords;
import '../../theme/colors.dart';
import '../../ui/dialogs.dart';
import '../../ui/icons.dart';
import '../../ui/model_sheet.dart';
import '../../ui/settings_kit.dart';
import '../api/agents_api.dart';
import 'agent_tree.dart' show addableUnder;

Future<void> openAddUnder(BuildContext context, Agent parent) {
  final size = MediaQuery.sizeOf(context);
  if (size.width >= 760) {
    return showRgWindow<void>(
      context: context,
      builder: (_) => Dialog(
        insetPadding: const EdgeInsets.all(28),
        clipBehavior: Clip.antiAlias,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: 620, maxHeight: size.height * .9),
          child: AddAgentUnder(parent: parent, panel: true),
        ),
      ),
    );
  }
  return Navigator.of(context)
      .push(MaterialPageRoute<void>(builder: (_) => AddAgentUnder(parent: parent)));
}

String kindName(AgentKind k) => switch (k) {
  AgentKind.god => 'god',
  AgentKind.demigod => 'demigod',
  AgentKind.orchestrator => 'orchestrator',
  AgentKind.agent => 'agent',
  AgentKind.subagent => 'subagent',
  AgentKind.inspector => 'inspector',
  AgentKind.assistant => 'assistant',
};

class AddAgentUnder extends StatefulWidget {
  const AddAgentUnder({super.key, required this.parent, this.panel = false});

  final Agent parent;
  final bool panel;

  @override
  State<AddAgentUnder> createState() => _AddAgentUnderState();
}

class _AddAgentUnderState extends State<AddAgentUnder> {
  late final List<AgentKind> _kinds = addableUnder(widget.parent);
  late AgentKind _kind = _kinds.first;
  final _name = TextEditingController();
  final _role = TextEditingController();
  String? _project;
  AgentModel? _model;
  String _mode = 'auto';
  bool _busy = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _name.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _name.dispose();
    _role.dispose();
    super.dispose();
  }

  bool get _needsProject => _kind == AgentKind.orchestrator || _kind == AgentKind.inspector;

  Future<void> _create() async {
    final app = AppScope.read(context);
    final l = AppLocalizations.of(context);
    final c = app.client;
    final project = _project ?? widget.parent.projectId ?? app.projects.firstOrNull?.id;
    if (c == null) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await c.createAgentWith(
        kind: kindName(_kind),
        parentId: widget.parent.id,
        name: _name.text.trim(),
        role: _role.text.trim().isEmpty ? null : _role.text.trim(),
        projectId: _needsProject ? project : null,
        model: _model,
        mode: _mode,
      );
      await app.refresh();
      if (mounted) Navigator.of(context).pop();
    } on ApiException catch (e) {
      if (mounted) setState(() => _error = l.newAgentFailed(e.message));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    final l = AppLocalizations.of(context);
    final c = RgColors.of(context);
    final project = _project ?? widget.parent.projectId ?? app.projects.firstOrNull?.id;
    final inherit = _kind == AgentKind.god ? l.g4AgModelDefault : l.agentModelInherit;
    final body = ListView(
      key: const Key('add-under'),
      padding: const EdgeInsets.only(bottom: 20),
      children: [
        if (_kinds.length > 1) ...[
          SectionHead(l.g4AgKind),
          SettingsCard(
            children: [
              for (final k in _kinds)
                PickRow(
                  key: Key('add-kind-${kindName(k)}'),
                  title: kindWords(l, app, _stub(k)),
                  selected: _kind == k,
                  onTap: () => setState(() => _kind = k),
                ),
            ],
          ),
        ],
        SectionHead(l.newAgentName),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: TextField(
            key: const Key('add-name'),
            controller: _name,
            maxLength: 60,
            decoration: const InputDecoration(counterText: ''),
          ),
        ),
        SectionHead(l.g4AgWhatItDoes),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: TextField(key: const Key('add-role'), controller: _role, minLines: 1, maxLines: 3),
        ),
        if (_needsProject && app.projects.isNotEmpty) ...[
          SectionHead(l.reviewProject),
          SettingsCard(
            children: [
              for (final p in app.projects)
                PickRow(
                  key: Key('add-project-${p.id}'),
                  leading: RgIcon(RgIcons.folder, size: 18, color: c.dim),
                  title: p.name,
                  selected: project == p.id,
                  onTap: () => setState(() => _project = p.id),
                ),
            ],
          ),
        ],
        SectionHead(l.agentModel),
        SettingsCard(
          children: [
            ListTile(
              key: const Key('add-model'),
              leading: RgIcon(RgIcons.zap, size: 18, color: c.accent),
              title: Text(_model == null ? inherit : modelWords(l, app.knownModels, _model!)),
              trailing: RgIcon(RgIcons.chevronRight, size: 18, color: c.dim),
              onTap: () async {
                final models = await app.modelChoices(again: true);
                if (!context.mounted || models.isEmpty) return;
                final pick = await showModelPicker(
                  context,
                  title: l.agentModel,
                  models: models,
                  current: _model,
                  inheritLabel: inherit,
                );
                if (pick != null && mounted) setState(() => _model = pick.model);
              },
            ),
          ],
        ),
        SectionHead(l.asMode),
        SettingsCard(
          children: [
            for (final (m, title, text) in modeChoices(l))
              PickRow(
                key: Key('add-mode-$m'),
                title: title,
                subtitle: text,
                selected: _mode == m,
                onTap: () => setState(() => _mode = m),
              ),
          ],
        ),
        // The server's refusal, where the person is looking: by the button.
        if (_error != null)
          NoticeBanner(key: const Key('add-under-error'), text: _error!, error: true),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 18, 16, 0),
          child: Wrap(
            alignment: WrapAlignment.spaceBetween,
            spacing: 8,
            runSpacing: 8,
            children: [
              OutlinedButton(
                key: const Key('add-cancel'),
                onPressed: () => Navigator.of(context).pop(),
                child: Text(l.cancel),
              ),
              FilledButton(
                key: const Key('add-create'),
                onPressed: _name.text.trim().isEmpty || _busy ? null : _create,
                child: Text(_busy ? l.newAgentCreating : l.newAgentCreate),
              ),
            ],
          ),
        ),
      ],
    );
    final title = l.g4AgAddUnder(widget.parent.name);
    if (widget.panel) {
      return Material(
        color: c.bg,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 14, 8, 4),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      title,
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: c.text),
                    ),
                  ),
                  IconButton(
                    key: const Key('add-close'),
                    tooltip: l.asClose,
                    onPressed: () => Navigator.of(context).pop(),
                    icon: RgIcon(RgIcons.x, color: c.dim),
                  ),
                ],
              ),
            ),
            Expanded(child: body),
          ],
        ),
      );
    }
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          key: const Key('add-back'),
          tooltip: l.back,
          onPressed: () => Navigator.of(context).pop(),
          icon: RgIcon(RgIcons.arrowLeft, color: c.text),
        ),
        title: Text(title),
      ),
      body: Align(
        alignment: Alignment.topCenter,
        child: ConstrainedBox(constraints: const BoxConstraints(maxWidth: 680), child: body),
      ),
    );
  }

  Agent _stub(AgentKind k) => Agent(id: '', kind: k, name: '', active: true);
}

/// The four ways of working, as the page's (mode, title, what it means).
List<(String, String, String)> modeChoices(AppLocalizations l) => [
  ('auto', l.asMode_auto, l.asModeExplain_auto),
  ('manual', l.asMode_manual, l.asModeExplain_manual),
  ('plan', l.asMode_plan, l.asModeExplain_plan),
  ('readonly', l.asMode_readonly, l.asModeExplain_readonly),
];

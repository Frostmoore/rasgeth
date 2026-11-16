// The composer's «…» (3.8.1, the user: «those are essential, I want them in the app too»): the
// page's panel (Chat.tsx `MainChat`, Composer.tsx `MoreMenu`) as a sheet for the phone, with the
// same items, effects and states:
// - Mode (Ask / Automatic / Plan / Read only): the agent's, for all its conversations
//   (`PATCH /api/agents/:id {mode}`);
// - Model and effort of this conversation, with the way (Subscription / API key), or the agent's
//   (`PATCH /api/sessions/:id {model}`), not while it works;
// - «Meanwhile»: a question on the side (`POST /api/sessions/:id/aside`), «Bring into the chat»
//   between turns, once the agent has answered at least once;
// - «Summarise»: `/compact [what to keep]` over the same send, with more than two items and not
//   while it works;
// - «Add an agent»: the conversation becomes a group chat (`POST /api/rooms` from it, then
//   `POST /api/rooms/:id/members`), not for Demi-God nor subagents, not while it works.
import 'package:flutter/material.dart';

import '../api/live_model.dart';
import '../api/types.dart';
import '../app_state.dart';
import '../l10n/app_localizations.dart';
import '../mascot/mascot_view.dart';
import '../theme/colors.dart';
import '../ui/dialogs.dart';
import '../ui/icons.dart';
import '../ui/model_sheet.dart';
import '../ui/send_keys.dart';

String modeWord(AppLocalizations l, String mode) => switch (mode) {
  'manual' => l.mode_manual,
  'plan' => l.mode_plan,
  'readonly' => l.mode_readonly,
  _ => l.mode_auto,
};

/// Something is not as it starts: the «…» shows a mark (the page's `moreChanged`).
bool moreChanged(AppController app, String sessionId, Agent? agent) {
  final a = agent == null ? null : app.agents.where((x) => x.id == agent.id).firstOrNull ?? agent;
  final row = app.live.sessions.where((s) => s.id == sessionId).firstOrNull;
  return (a?.mode ?? 'auto') != 'auto' || row?.model != null;
}

Future<void> showMoreSheet(
  BuildContext context, {
  required String sessionId,
  required Agent? agent,
  required SessionView view,
}) => showModalBottomSheet<void>(
  context: context,
  showDragHandle: true,
  isScrollControlled: true,
  builder: (_) => MoreSheet(sessionId: sessionId, agent: agent, view: view, parent: context),
);

class MoreSheet extends StatefulWidget {
  const MoreSheet({
    super.key,
    required this.sessionId,
    required this.agent,
    required this.view,
    required this.parent,
  });

  final String sessionId;
  final Agent? agent;
  final SessionView view;
  final BuildContext parent;

  @override
  State<MoreSheet> createState() => _MoreSheetState();
}

class _MoreSheetState extends State<MoreSheet> {
  String? _note;

  @override
  void initState() {
    super.initState();
    AppScope.read(context).modelChoices().then((_) {
      if (mounted) setState(() {});
    });
  }

  Agent? _agent(AppController app) {
    final a = widget.agent;
    if (a == null) return null;
    return app.agents.where((x) => x.id == a.id).firstOrNull ?? a;
  }

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    final l = AppLocalizations.of(context);
    final c = RgColors.of(context);
    return ListenableBuilder(
      listenable: Listenable.merge([app, app.live, widget.view]),
      builder: (context, _) {
        final a = _agent(app);
        final v = widget.view;
        final running = v.running;
        final mode = a?.mode ?? 'auto';
        final row = app.live.sessions.where((s) => s.id == widget.sessionId).firstOrNull;
        final own = row?.model;
        final model = own ?? a?.model ?? (a == null ? null : app.inheritedModelOf(a));
        final answered = v.events.any((e) => e.type == 'message.assistant');
        final items = v.items.length;
        final canRoom = a != null && a.kind != AgentKind.demigod && a.kind != AgentKind.subagent;
        return SafeArea(
          child: SingleChildScrollView(
            key: const Key('more-sheet'),
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _Section(l.moreSectionHow),
                if (a != null) ...[
                  Text(
                    l.moreMode(modeWord(l, mode)),
                    key: const Key('more-mode-now'),
                    style: TextStyle(fontWeight: FontWeight.w700, color: c.text),
                  ),
                  const SizedBox(height: 8),
                  ChoiceRow(
                    keyPrefix: 'mode',
                    values: agentModes,
                    selected: mode,
                    label: (m) => modeWord(l, m),
                    onChanged: (m) async {
                      final ok = await app.setAgentMode(a, m);
                      if (mounted) setState(() => _note = ok ? null : l.modeFailed);
                    },
                  ),
                  const SizedBox(height: 4),
                  Text(l.moreModeHint(a.name), style: TextStyle(color: c.dim, fontSize: 12.5)),
                  const SizedBox(height: 14),
                ],
                _Item(
                  key: const Key('more-model'),
                  icon: RgIcons.zap,
                  title: l.moreModel(
                    model == null ? l.agentModelDefault : modelWords(l, app.knownModels, model),
                  ),
                  hint: running ? l.sessionModelBusy : l.moreModelHint,
                  enabled: !running,
                  onTap: () => _pickModel(app, l, a, own),
                ),
                const SizedBox(height: 10),
                _Section(l.moreSectionMore),
                if (answered)
                  _Item(
                    key: const Key('more-aside'),
                    icon: RgIcons.coffee,
                    title: l.asideChip,
                    hint: l.asideHint,
                    onTap: () => _aside(context),
                  ),
                if (items > 2)
                  _Item(
                    key: const Key('more-compact'),
                    icon: RgIcons.minimize,
                    title: l.compactNow,
                    hint: running ? l.whileRunning : l.compactNowHint,
                    enabled: !running,
                    onTap: () => _compact(app, l),
                  ),
                if (canRoom)
                  _Item(
                    key: const Key('more-room'),
                    icon: RgIcons.userPlus,
                    title: l.roomFromChat,
                    hint: running ? l.whileRunning : l.roomFromChatHint,
                    enabled: !running,
                    onTap: () => _room(app, l, a),
                  ),
                if (_note != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      _note!,
                      key: const Key('more-note'),
                      style: TextStyle(color: c.err, fontSize: 13),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _pickModel(AppController app, AppLocalizations l, Agent? a, AgentModel? own) async {
    final models = await app.modelChoices(again: true);
    if (!mounted) return;
    if (models.isEmpty) {
      setState(() => _note = l.noModels);
      return;
    }
    final follows = a?.model ?? (a == null ? null : app.inheritedModelOf(a));
    final pick = await showModelPicker(
      context,
      title: l.sessionModelTitle,
      models: models,
      current: own,
      inheritLabel: follows == null
          ? l.agentsModel
          : l.modelInheritOf(l.agentsModel, modelWords(l, models, follows)),
    );
    if (pick == null || !mounted) return;
    final err = await app.setSessionModel(widget.sessionId, pick.model);
    if (mounted)
      setState(() => _note = err == null ? null : (err == 'busy' ? l.sessionModelBusy : err));
  }

  Future<void> _compact(AppController app, AppLocalizations l) async {
    final messenger = ScaffoldMessenger.of(widget.parent);
    final keep = await askText(context, title: l.compactNowAsk, yes: l.compactNowYes);
    if (keep == null || !mounted) return;
    final ok = await app.send(widget.sessionId, '/compact ${keep.trim()}'.trim());
    if (!mounted) return;
    Navigator.of(context).pop();
    messenger.showSnackBar(SnackBar(content: Text(ok ? l.compactNowSent : l.sendFailed)));
  }

  Future<void> _room(AppController app, AppLocalizations l, Agent a) async {
    final c = app.client;
    if (c == null) return;
    final messenger = ScaffoldMessenger.of(widget.parent);
    final others = app.agents
        .where(
          (x) =>
              x.id != a.id &&
              x.active &&
              x.kind != AgentKind.demigod &&
              x.kind != AgentKind.subagent,
        )
        .toList();
    final who = await showModalBottomSheet<Agent>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (context) => _AgentPicker(title: l.roomPickTitle, agents: others),
    );
    if (who == null || !mounted) return;
    try {
      final room = await c.roomFrom(a.id, widget.sessionId);
      await c.addRoomMember(room, who.id);
      if (!mounted) return;
      Navigator.of(context).pop();
      messenger.showSnackBar(SnackBar(content: Text(l.roomAdded(who.name))));
    } on Exception {
      if (mounted) setState(() => _note = l.roomFailed);
    }
  }

  Future<void> _aside(BuildContext context) => showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    isScrollControlled: true,
    builder: (_) => AsideSheet(sessionId: widget.sessionId, view: widget.view),
  );
}

class _Section extends StatelessWidget {
  const _Section(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    final c = RgColors.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 8, top: 4),
      child: Semantics(
        header: true,
        child: Text(
          text.toUpperCase(),
          style: TextStyle(
            fontSize: 12,
            letterSpacing: .6,
            fontWeight: FontWeight.w800,
            color: c.dim,
          ),
        ),
      ),
    );
  }
}

class _Item extends StatelessWidget {
  const _Item({
    super.key,
    required this.icon,
    required this.title,
    required this.hint,
    required this.onTap,
    this.enabled = true,
  });

  final RgIcons icon;
  final String title;
  final String hint;
  final VoidCallback onTap;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final c = RgColors.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Semantics(
        button: true,
        enabled: enabled,
        child: Material(
          color: c.panel,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
            side: BorderSide(color: c.line),
          ),
          child: InkWell(
            borderRadius: BorderRadius.circular(14),
            onTap: enabled ? onTap : null,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
              child: Row(
                children: [
                  RgIcon(icon, size: 19, color: enabled ? c.text : c.dim),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            color: enabled ? c.text : c.dim,
                          ),
                        ),
                        Text(hint, style: TextStyle(color: c.dim, fontSize: 12.5)),
                      ],
                    ),
                  ),
                  if (enabled) RgIcon(RgIcons.chevronRight, size: 18, color: c.dim),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _AgentPicker extends StatelessWidget {
  const _AgentPicker({required this.title, required this.agents});

  final String title;
  final List<Agent> agents;

  @override
  Widget build(BuildContext context) {
    final c = RgColors.of(context);
    final l = AppLocalizations.of(context);
    return SafeArea(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxHeight: MediaQuery.sizeOf(context).height * .7),
        child: ListView(
          shrinkWrap: true,
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          children: [
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Text(
                title,
                style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: c.text),
              ),
            ),
            for (final a in agents)
              ListTile(
                key: Key('room-pick-${a.id}'),
                leading: MascotView(agentId: a.id, spec: a.mascot, size: 36),
                title: Text(a.name),
                subtitle: a.role == null ? null : Text(a.role!, maxLines: 1),
                onTap: () => Navigator.pop(context, a),
              ),
            if (agents.isEmpty) Text(l.teamNoAgents, style: TextStyle(color: c.dim)),
          ],
        ),
      ),
    );
  }
}

/// «Meanwhile»: questions on the side and their answers (the `aside` events), a field to ask one,
/// and «Bring into the chat» between turns.
class AsideSheet extends StatefulWidget {
  const AsideSheet({super.key, required this.sessionId, required this.view});

  final String sessionId;
  final SessionView view;

  @override
  State<AsideSheet> createState() => _AsideSheetState();
}

class _AsideSheetState extends State<AsideSheet> {
  final _q = TextEditingController();
  final _mine = <({String id, String question, String? answer, String? error})>[];
  final _brought = <String>{};
  bool _asking = false;

  @override
  void dispose() {
    _q.dispose();
    super.dispose();
  }

  List<({String id, String question, String? answer, String? error})> _all() {
    final ev = widget.view.events;
    final promoted = {
      for (final e in ev)
        if (e.type == 'aside.promoted' && e.payload?['asideId'] is String)
          e.payload!['asideId'] as String,
    };
    final out = [
      for (final e in ev)
        if (e.type == 'aside' && e.payload != null)
          (
            id: '${e.payload!['id']}',
            question: '${e.payload!['question'] ?? ''}',
            answer: e.payload!['answer'] as String?,
            error: e.payload!['error'] as String?,
          ),
    ];
    for (final m in _mine) {
      if (!out.any((o) => o.id == m.id)) out.add(m);
    }
    _brought.addAll(promoted);
    return out;
  }

  Future<void> _ask() async {
    final app = AppScope.read(context);
    final q = _q.text.trim();
    final c = app.client;
    if (q.isEmpty || c == null) return;
    setState(() => _asking = true);
    try {
      final a = await c.aside(widget.sessionId, q);
      _mine.add((id: a.id, question: q, answer: a.answer, error: a.error));
      _q.clear();
    } on Exception catch (e) {
      _mine.add((id: 'x${_mine.length}', question: q, answer: null, error: '$e'));
    }
    if (mounted) setState(() => _asking = false);
  }

  Future<void> _bring(String id) async {
    final c = AppScope.read(context).client;
    if (c == null) return;
    try {
      await c.asideToChat(widget.sessionId, id);
      if (mounted) setState(() => _brought.add(id));
    } on Exception {
      // The button stays.
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final c = RgColors.of(context);
    return ListenableBuilder(
      listenable: widget.view,
      builder: (context, _) {
        final all = _all();
        final running = widget.view.running;
        return SafeArea(
          child: Padding(
            padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
            child: ConstrainedBox(
              constraints: BoxConstraints(maxHeight: MediaQuery.sizeOf(context).height * .8),
              child: Column(
                key: const Key('aside-sheet'),
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 2),
                    child: Text(
                      l.asideTitle,
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: c.text),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
                    child: Text(l.asideSub, style: TextStyle(color: c.dim, fontSize: 13)),
                  ),
                  Flexible(
                    child: ListView(
                      shrinkWrap: true,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      children: [
                        if (all.isEmpty)
                          Text(l.asideEmpty, style: TextStyle(color: c.dim, fontSize: 13.5)),
                        for (final a in all)
                          Container(
                            margin: const EdgeInsets.only(bottom: 8),
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: c.panel,
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(color: c.line),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              spacing: 6,
                              children: [
                                Text(
                                  a.question,
                                  style: TextStyle(fontWeight: FontWeight.w700, color: c.text),
                                ),
                                Text(
                                  a.error != null ? l.asideFailed(a.error!) : (a.answer ?? ''),
                                  key: Key('aside-answer-${a.id}'),
                                  style: TextStyle(color: a.error != null ? c.err : c.text),
                                ),
                                if (a.error == null && a.answer != null)
                                  _brought.contains(a.id)
                                      ? Text(l.asideBrought, style: TextStyle(color: c.dim))
                                      : TextButton(
                                          key: Key('aside-to-chat-${a.id}'),
                                          onPressed: running ? null : () => _bring(a.id),
                                          child: Text(l.asideToChat),
                                        ),
                              ],
                            ),
                          ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 6, 16, 12),
                    child: Row(
                      children: [
                        Expanded(
                          child: SendKeys(
                            onSend: _asking ? null : _ask,
                            child: TextField(
                              key: const Key('aside-field'),
                              controller: _q,
                              minLines: 1,
                              maxLines: 4,
                              decoration: InputDecoration(
                                isDense: true,
                                hintText: running ? l.asidePlaceholderBusy : l.asidePlaceholder,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        FilledButton(
                          key: const Key('aside-ask'),
                          onPressed: _asking ? null : _ask,
                          child: Text(_asking ? l.asideThinking : l.asideAsk),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

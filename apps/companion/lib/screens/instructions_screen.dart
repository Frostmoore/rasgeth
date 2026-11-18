// An agent's instructions (its system prompt) from the app (3.8.1), as the page's PromptEditor:
// the text in use, its own or the built-in one as a starting point, with the agents' names as
// they are now; Save, «Restore the built-in ones», and «Improve the instructions» (the page's
// PromptRefiner, native in lib/settings/prompt_refiner.dart since G42.4: the writer model, an
// estimate, the before and after with the differences lit, a revised text that only fills the
// field). God's and
// every agent's through `/api/agents/:id/prompt`, the Chat's through `/api/chat/prompt`. A
// conversation keeps the instructions it started with (the prompt prefix stays stable): new
// ones apply to new conversations, and the screen says so.
import 'package:flutter/material.dart';

import '../api/client.dart';
import '../api/types.dart';
import '../app_state.dart';
import '../l10n/app_localizations.dart';
import '../settings/api/general_api.dart' show RefineAgent, RefineChat;
import '../settings/prompt_refiner.dart';
import '../theme/colors.dart';
import '../ui/dialogs.dart';
import '../ui/icons.dart';

Future<void> openInstructions(BuildContext context, Agent agent) => Navigator.of(context).push(
  MaterialPageRoute<void>(fullscreenDialog: true, builder: (_) => InstructionsScreen(agent: agent)),
);

class InstructionsScreen extends StatefulWidget {
  const InstructionsScreen({super.key, required this.agent});

  final Agent agent;

  @override
  State<InstructionsScreen> createState() => _InstructionsScreenState();
}

class _InstructionsScreenState extends State<InstructionsScreen> {
  final _text = TextEditingController();
  PromptView? _view;
  String? _note;
  bool _noteBad = false;

  late final AppController app = AppScope.read(context);

  /// null: the Chat (its own endpoints), else the agent's id.
  String? get _id => app.isChat(widget.agent) ? null : widget.agent.id;

  @override
  void initState() {
    super.initState();
    _text.addListener(() => setState(() {}));
    _load();
  }

  @override
  void dispose() {
    _text.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    try {
      final v = await app.client!.prompt(agentId: _id);
      if (!mounted) return;
      setState(() {
        _view = v;
        _text.text = v.text;
      });
    } on ApiException catch (e) {
      if (mounted) setState(() => _say(e.message, bad: true));
    }
  }

  void _say(String? s, {bool bad = false}) {
    _note = s;
    _noteBad = bad;
  }

  bool get _changed => _view != null && _text.text.trim() != _view!.text.trim();

  Future<void> _store(String? text) async {
    final l = AppLocalizations.of(context);
    try {
      final v = await app.client!.setPrompt(text, agentId: _id);
      if (!mounted) return;
      setState(() {
        _view = v;
        _text.text = v.text;
        _say(l.promptSaved);
      });
    } on ApiException catch (e) {
      if (mounted) setState(() => _say(l.promptSaveFailed(e.message), bad: true));
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final c = RgColors.of(context);
    final v = _view;
    final title = app.isChat(widget.agent)
        ? l.chatInstructions
        : l.agentInstructionsOf(widget.agent.name);
    return Scaffold(
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(4, 6, 12, 4),
              child: Row(
                children: [
                  IconButton(
                    key: const Key('prompt-close'),
                    tooltip: l.back,
                    onPressed: () => Navigator.of(context).maybePop(),
                    icon: RgIcon(RgIcons.x, color: c.text),
                  ),
                  Expanded(
                    child: Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: c.text),
                    ),
                  ),
                  if (v != null)
                    Container(
                      key: const Key('prompt-tag'),
                      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
                      decoration: BoxDecoration(
                        color: v.isDefault ? c.panel : c.accentSoft,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: v.isDefault ? c.line : c.accentDim),
                      ),
                      child: Text(
                        v.isDefault ? l.promptDefault : l.promptOwn,
                        style: TextStyle(fontSize: 12, color: c.text),
                      ),
                    ),
                ],
              ),
            ),
            Expanded(
              child: v == null
                  ? Center(
                      child: Text(_note ?? l.loading, style: TextStyle(color: c.dim)),
                    )
                  : ListView(
                      key: const Key('prompt-body'),
                      padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
                      children: [
                        TextField(
                          key: const Key('prompt-text'),
                          controller: _text,
                          minLines: 12,
                          maxLines: null,
                          style: const TextStyle(fontSize: 14, height: 1.4),
                          decoration: const InputDecoration(border: OutlineInputBorder()),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          l.promptNewChats,
                          key: const Key('prompt-new-chats'),
                          style: TextStyle(color: c.dim, fontSize: 12.5),
                        ),
                        const SizedBox(height: 10),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            if (!v.isDefault)
                              OutlinedButton.icon(
                                key: const Key('prompt-reset'),
                                onPressed: () async {
                                  final yes = await askConfirm(
                                    context,
                                    title: l.promptReset,
                                    body: l.promptResetConfirm,
                                    yes: l.promptReset,
                                  );
                                  if (yes) await _store(null);
                                },
                                icon: RgIcon(RgIcons.refresh, size: 16, color: c.text),
                                label: Text(l.promptReset),
                              ),
                            if (_changed)
                              TextButton(
                                key: const Key('prompt-undo'),
                                onPressed: () => setState(() => _text.text = v.text),
                                child: Text(l.promptUndo),
                              ),
                          ],
                        ),
                        const SizedBox(height: 14),
                        PromptRefiner(
                          target: _id == null ? const RefineChat() : RefineAgent(_id!),
                          text: _text.text,
                          onUse: (t) => setState(() {
                            _text.text = t;
                            _say(null);
                          }),
                        ),
                      ],
                    ),
            ),
            if (_note != null && v != null)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 6),
                child: Text(
                  _note!,
                  key: const Key('prompt-note'),
                  style: TextStyle(color: _noteBad ? c.err : c.ok),
                ),
              ),
            Container(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
              decoration: BoxDecoration(
                border: Border(top: BorderSide(color: c.line)),
              ),
              child: FilledButton(
                key: const Key('prompt-save'),
                style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(48)),
                onPressed: _changed ? () => _store(_text.text) : null,
                child: Text(l.promptSave),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

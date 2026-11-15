// An agent's instructions (its system prompt) from the app (3.8.1), as the page's PromptEditor:
// the text in use, its own or the built-in one as a starting point, with the agents' names as
// they are now; Save, «Restore the built-in ones», and «Improve the instructions» (the page's
// PromptRefiner: an estimate first, then a revised text that only fills the field). God's and
// every agent's through `/api/agents/:id/prompt`, the Chat's through `/api/chat/prompt`. A
// conversation keeps the instructions it started with (the prompt prefix stays stable): new
// ones apply to new conversations, and the screen says so.
import 'package:flutter/material.dart';

import '../api/client.dart';
import '../api/types.dart';
import '../app_state.dart';
import '../l10n/app_localizations.dart';
import '../theme/colors.dart';
import '../ui/dialogs.dart';
import '../ui/icons.dart';

Future<void> openInstructions(BuildContext context, Agent agent) => Navigator.of(context).push(
  MaterialPageRoute<void>(fullscreenDialog: true, builder: (_) => InstructionsScreen(agent: agent)),
);

/// «about 3,200 tokens, less than a cent», as the page's `costWords`.
String costWords(AppLocalizations l, RefineCost c) {
  final tokens = c.tokens < 1000 ? '${c.tokens}' : '${(c.tokens / 100).round() * 100}';
  final usd = c.usd;
  final cost = usd == null
      ? l.refineFree
      : usd < .01
      ? l.refineCostTiny
      : l.refineCost('\$${usd.toStringAsFixed(2)}');
  return l.refineCostLine(tokens, cost);
}

class InstructionsScreen extends StatefulWidget {
  const InstructionsScreen({super.key, required this.agent});

  final Agent agent;

  @override
  State<InstructionsScreen> createState() => _InstructionsScreenState();
}

class _InstructionsScreenState extends State<InstructionsScreen> {
  final _text = TextEditingController();
  final _wish = TextEditingController();
  PromptView? _view;
  String? _note;
  bool _noteBad = false;
  bool _refining = false;
  bool _refineOpen = false;
  String? _estimate;
  ({String text, String changes, RefineCost cost})? _result;

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
    _wish.dispose();
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

  String get _lang => Localizations.localeOf(context).languageCode == 'en' ? 'en' : 'it';

  Future<void> _openRefine() async {
    final l = AppLocalizations.of(context);
    setState(() {
      _refineOpen = true;
      _estimate = null;
    });
    try {
      final e = await app.client!.refineEstimate(agentId: _id, text: _text.text, lang: _lang);
      if (mounted) setState(() => _estimate = l.refineEstimate(costWords(l, e)));
    } on ApiException {
      if (mounted) setState(() => _estimate = l.refineNoEstimate);
    }
  }

  String _refineError(AppLocalizations l, ApiException e) => switch (e.code) {
    'budget' => l.refineErr_budget,
    'no_model' => l.refineErr_no_model,
    'no_answer' => l.refineErr_no_answer,
    'removed_parts' => l.refineErr_removed_parts,
    _ => e.message,
  };

  Future<void> _refine() async {
    final l = AppLocalizations.of(context);
    setState(() {
      _refining = true;
      _result = null;
      _say(null);
    });
    try {
      final r = await app.client!.refine(
        agentId: _id,
        text: _text.text,
        request: _wish.text.trim(),
        lang: _lang,
      );
      if (mounted) setState(() => _result = r);
    } on ApiException catch (e) {
      if (mounted) setState(() => _say(_refineError(l, e), bad: true));
    } finally {
      if (mounted) setState(() => _refining = false);
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
                        if (!_refineOpen)
                          OutlinedButton.icon(
                            key: const Key('refine-open'),
                            style: OutlinedButton.styleFrom(minimumSize: const Size.fromHeight(46)),
                            onPressed: _openRefine,
                            icon: RgIcon(RgIcons.edit, size: 18, color: c.text),
                            label: Text(l.refineOpen),
                          )
                        else
                          _refineBox(l, c),
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

  Widget _refineBox(AppLocalizations l, RgColors c) {
    final r = _result;
    return Container(
      key: const Key('refine-box'),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: c.panel,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: c.line),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: 8,
        children: [
          Text(
            l.refineOpen,
            style: TextStyle(fontWeight: FontWeight.w800, color: c.text),
          ),
          Text(l.refineLead, style: TextStyle(color: c.dim, fontSize: 12.5)),
          TextField(
            key: const Key('refine-wish'),
            controller: _wish,
            minLines: 1,
            maxLines: 4,
            decoration: InputDecoration(
              labelText: l.refineWish,
              hintText: l.refineWishPlaceholder,
              hintMaxLines: 3,
            ),
          ),
          if (_estimate != null)
            Text(
              _estimate!,
              key: const Key('refine-estimate'),
              style: TextStyle(color: c.dim, fontSize: 12.5),
            ),
          if (r == null)
            FilledButton(
              key: const Key('refine-go'),
              onPressed: _refining ? null : _refine,
              child: Text(_refining ? l.refineWorking : l.refineGo),
            )
          else ...[
            Text(
              l.refineChanges,
              style: TextStyle(fontWeight: FontWeight.w700, color: c.text),
            ),
            Text(
              r.text.trim() == _text.text.trim() ? l.refineSame : r.changes,
              key: const Key('refine-changes'),
              style: TextStyle(color: c.text),
            ),
            Text(
              l.refineSpent(costWords(l, r.cost)),
              style: TextStyle(color: c.dim, fontSize: 12.5),
            ),
            Row(
              children: [
                Expanded(
                  child: FilledButton(
                    key: const Key('refine-use'),
                    onPressed: () => setState(() {
                      _text.text = r.text;
                      _result = null;
                      _refineOpen = false;
                      _say(l.refineUsed);
                    }),
                    child: Text(l.refineUse),
                  ),
                ),
                const SizedBox(width: 8),
                OutlinedButton(
                  key: const Key('refine-retry'),
                  onPressed: _refine,
                  child: Text(l.refineRetry),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

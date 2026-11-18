// G42.10: Settings › Shared memory, native, as the page's `SharedMemory.tsx`: what every agent
// knows about the person, the two kinds of memory side by side so the difference reads at once,
// «learns by itself» on our switch, a memory added, changed, deleted (with «Undo» under the list)
// or forgotten for good (said plainly first), where each came from (its conversation opens), the
// space used, and the last changes, each one undoable once. Routes: `/api/memory` (api.ts).
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../app_state.dart';
import '../l10n/app_localizations.dart';
import '../screens/conversation_screen.dart' show ConversationScreen;
import '../theme/colors.dart';
import '../ui/icons.dart';
import 'api/knowledge_api.dart';
import 'knowledge_kit.dart';
import 'rules_kit.dart';

/// Opens the page: a panel over the window on a computer, a whole screen on a phone.
Future<void> openSharedMemory(BuildContext context) =>
    openRulesPage(context, (panel) => SharedMemoryScreen(panel: panel));

/// Who wrote a memory first, in words (the page's `byWords`).
String memByWords(AppLocalizations l, String by, String? agentName) => switch (by) {
  'auto' => l.knMemByAuto,
  'human' => l.knMemByHuman,
  'import' => l.knMemByImport,
  _ => agentName != null ? l.knMemByAgent(agentName) : l.knMemByAgentUnknown,
};

String memCountWords(AppLocalizations l, int n) => n == 1 ? l.knMemCountOne : l.knMemCount('$n');

class SharedMemoryScreen extends StatefulWidget {
  const SharedMemoryScreen({super.key, this.panel = false});

  final bool panel;

  @override
  State<SharedMemoryScreen> createState() => _SharedMemoryScreenState();
}

class _SharedMemoryScreenState extends State<SharedMemoryScreen> {
  MemView? _v;
  String? _error;
  String? _note;

  /// The last deletion, to take it back from the bar under the list.
  int? _removed;
  bool _all = false;
  final _add = TextEditingController();

  @override
  void initState() {
    super.initState();
    unawaited(_load());
  }

  @override
  void dispose() {
    _add.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final c = AppScope.read(context).client;
    if (c == null) return;
    try {
      final v = await c.sharedMemory();
      if (mounted) setState(() => _v = v);
    } on Exception catch (e) {
      if (mounted) setState(() => _error = memWhy(AppLocalizations.of(context), e));
    }
  }

  /// Does [f], then reads the memory again; an error is said in words.
  Future<bool> _run(Future<void> Function() f) async {
    final l = AppLocalizations.of(context);
    setState(() {
      _error = null;
      _note = null;
    });
    try {
      await f();
      await _load();
      return true;
    } on Exception catch (e) {
      if (mounted) setState(() => _error = memWhy(l, e));
      return false;
    }
  }

  Future<void> _addOne() async {
    final c = AppScope.read(context).client;
    final text = _add.text;
    if (c == null || text.trim().isEmpty) return;
    var duplicate = false;
    final ok = await _run(() async => duplicate = await c.addMemory(text));
    if (ok && mounted) {
      _add.clear();
      setState(() {
        _removed = null;
        if (duplicate) _note = AppLocalizations.of(context).knMemAlready;
      });
    }
  }

  Future<void> _remove(MemEntry e) async {
    final c = AppScope.read(context).client;
    if (c == null) return;
    setState(() => _removed = null);
    final ok = await _run(() => c.removeMemory(e.id));
    if (!ok || !mounted) return;
    final change = _v?.changes
        .where((x) => x.memoryId == e.id && x.action == 'removed')
        .firstOrNull;
    setState(() => _removed = change?.seq);
  }

  Future<void> _edit(MemEntry e) async {
    final saved = await kbWindow<bool>(
      context,
      key: const Key('mem-edit'),
      title: AppLocalizations.of(context).knMemEditTitle,
      body: (ctx, close) => _EditMemory(entry: e, onDone: close),
    );
    if (saved == true && mounted) await _load();
  }

  Future<void> _forget(String id, String text) async {
    final l = AppLocalizations.of(context);
    final c = AppScope.read(context).client;
    final yes = await kbWindow<bool>(
      context,
      key: const Key('mem-forget-window'),
      title: l.knMemForgetTitle,
      body: (ctx, close) => _ForgetBody(text: text, onDone: close),
    );
    if (yes != true || c == null || !mounted) return;
    setState(() => _removed = null);
    await _run(() => c.forgetMemory(id));
  }

  Future<void> _openFrom(MemEntry e) async {
    final app = AppScope.read(context);
    final agent = app.agents.where((a) => a.id == e.agentId).firstOrNull;
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => ConversationScreen(sessionId: e.sessionId!, agent: agent),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final c = RgColors.of(context);
    final v = _v;
    final client = AppScope.of(context).client;
    return RulesPage(
      pageKey: const Key('memory-settings'),
      title: l.knMemEyebrow,
      panel: widget.panel,
      question: l.knMemTitle,
      lead: l.knMemLead,
      children: [
        if (v == null) RulesLoading(error: _error),
        if (v != null) ...[
          _TwoKinds(),
          KbBox(
            children: [
              KbSwitchRow(
                key: const Key('mem-auto'),
                title: l.knMemAutoTitle,
                help: v.auto ? l.knMemAutoOn : l.knMemAutoOff,
                on: v.auto,
                onChanged: client == null ? null : (on) => _run(() => client.setMemoryAuto(on)),
              ),
            ],
          ),
          RulesSub(
            title: '${l.knMemListTitle} · ${memCountWords(l, v.entries.length)}',
            lead: l.knMemListLead,
          ),
          KbBox(
            children: [
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      key: const Key('mem-add-field'),
                      controller: _add,
                      maxLength: 400,
                      textInputAction: TextInputAction.done,
                      onSubmitted: (_) => _addOne(),
                      onChanged: (_) => setState(() {}),
                      decoration: InputDecoration(
                        hintText: l.knMemAddPlaceholder,
                        counterText: '',
                        isDense: true,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  FilledButton.icon(
                    key: const Key('mem-add'),
                    onPressed: _add.text.trim().isEmpty ? null : _addOne,
                    icon: const RgIcon(RgIcons.plus, size: 16, color: Colors.white),
                    label: Text(l.knMemAdd),
                  ),
                ],
              ),
              if (_error != null) KbLine(_error!, error: true, key: const Key('mem-error')),
              if (_note != null)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    _note!,
                    key: const Key('mem-note'),
                    style: TextStyle(color: c.ok, fontSize: 13),
                  ),
                ),
              if (_removed != null)
                Container(
                  key: const Key('mem-undo-bar'),
                  margin: const EdgeInsets.only(top: 10),
                  padding: const EdgeInsets.fromLTRB(12, 6, 6, 6),
                  decoration: BoxDecoration(
                    color: c.panel2,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: c.line),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(l.knMemRemoved, style: TextStyle(color: c.text)),
                      ),
                      TextButton(
                        key: const Key('mem-undo-removed'),
                        onPressed: client == null
                            ? null
                            : () {
                                final seq = _removed!;
                                setState(() => _removed = null);
                                unawaited(_run(() => client.undoMemory(seq)));
                              },
                        child: Text(l.knMemUndo),
                      ),
                    ],
                  ),
                ),
              const SizedBox(height: 6),
              if (v.entries.isEmpty)
                KbLine(l.knMemEmpty, dim: true)
              else
                for (final e in v.entries.reversed)
                  _Entry(
                    key: Key('mem-entry-${e.id}'),
                    e: e,
                    onEdit: () => _edit(e),
                    onRemove: () => _remove(e),
                    onForget: () => _forget(e.id, e.text),
                    onFrom: e.sessionId != null && e.agentId != null ? () => _openFrom(e) : null,
                  ),
              _Used(used: v.used, limit: v.limit),
            ],
          ),
          if (v.changes.isNotEmpty) ...[
            RulesSub(title: l.knMemHistory, lead: l.knMemHistoryLead),
            KbBox(children: _history(l, v, client == null)),
          ],
        ],
      ],
    );
  }

  List<Widget> _history(AppLocalizations l, MemView v, bool off) {
    final client = AppScope.read(context).client;
    final present = {for (final e in v.entries) e.id};
    final latest = <String, int>{};
    for (final c in v.changes) {
      latest.putIfAbsent(c.memoryId, () => c.seq);
    }
    final shown = _all ? v.changes : v.changes.take(5);
    return [
      for (final ch in shown)
        _Change(
          key: Key('mem-change-${ch.seq}'),
          c: ch,
          onUndo: off ? null : () => _run(() => client!.undoMemory(ch.seq)),
          onForget:
              ch.action == 'removed' &&
                  latest[ch.memoryId] == ch.seq &&
                  !present.contains(ch.memoryId)
              ? () => _forget(ch.memoryId, ch.text)
              : null,
        ),
      if (v.changes.length > 5)
        Align(
          alignment: Alignment.centerLeft,
          child: TextButton(
            key: const Key('mem-history-more'),
            onPressed: () => setState(() => _all = !_all),
            child: Text(_all ? l.knMemHistoryLess : l.knMemHistoryMore),
          ),
        ),
    ];
  }
}

/// The two kinds of memory side by side (one under the other on a phone): this page's, lit.
class _TwoKinds extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final shared = RuleCard(
      key: const Key('mem-card-shared'),
      icon: RgIcons.users,
      title: l.knMemSharedCard,
      question: l.knMemSharedCardQ,
      children: [KbLine(l.knMemSharedCardText)],
    );
    final own = RuleCard(
      key: const Key('mem-card-own'),
      icon: RgIcons.user,
      tone: RgColors.of(context).dim,
      title: l.knMemOwnCard,
      question: l.knMemOwnCardQ,
      children: [KbLine(l.knMemOwnCardText, dim: true)],
    );
    return LayoutBuilder(
      builder: (context, box) => box.maxWidth >= 560
          ? IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(child: shared),
                  const SizedBox(width: 12),
                  Expanded(child: own),
                ],
              ),
            )
          : Column(children: [shared, own]),
    );
  }
}

String _day(AppLocalizations l, String iso) {
  final d = DateTime.tryParse(iso)?.toLocal();
  if (d == null) return '';
  final f = d.year == DateTime.now().year
      ? DateFormat.MMMd(l.localeName)
      : DateFormat.yMMMd(l.localeName);
  return f.format(d);
}

class _Entry extends StatelessWidget {
  const _Entry({
    super.key,
    required this.e,
    required this.onEdit,
    required this.onRemove,
    required this.onForget,
    this.onFrom,
  });

  final MemEntry e;
  final VoidCallback onEdit;
  final VoidCallback onRemove;
  final VoidCallback onForget;
  final VoidCallback? onFrom;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final c = RgColors.of(context);
    final small = TextStyle(color: c.dim, fontSize: 12.5);
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: c.line)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(e.text, style: TextStyle(color: c.text, fontSize: 14.5, height: 1.4)),
          const SizedBox(height: 4),
          Wrap(
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Text('${memByWords(l, e.by, e.agentName)} · ${_day(l, e.createdAt)}', style: small),
              if (onFrom != null) ...[
                Text(' · ', style: small),
                InkWell(
                  key: Key('mem-from-${e.id}'),
                  onTap: onFrom,
                  child: Text(
                    e.sessionTitle != null ? l.knMemFrom(e.sessionTitle!) : l.knMemFromUntitled,
                    style: small.copyWith(color: c.accent, decoration: TextDecoration.underline),
                  ),
                ),
                if (e.by == 'auto' && e.agentName != null)
                  Text(' ${l.knMemWith(e.agentName!)}', style: small),
              ],
            ],
          ),
          Wrap(
            spacing: 2,
            children: [
              TextButton.icon(
                key: Key('mem-edit-${e.id}'),
                onPressed: onEdit,
                icon: RgIcon(RgIcons.edit, size: 15, color: c.dim),
                label: Text(l.knMemEdit, style: TextStyle(color: c.text)),
              ),
              TextButton.icon(
                key: Key('mem-remove-${e.id}'),
                onPressed: onRemove,
                icon: RgIcon(RgIcons.trash, size: 15, color: c.dim),
                label: Text(l.knMemRemove, style: TextStyle(color: c.text)),
              ),
              TextButton(
                key: Key('mem-forget-${e.id}'),
                onPressed: onForget,
                child: Text(l.knMemForget, style: TextStyle(color: c.err)),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// The space used, as the page's meter: the whole memory goes into every new conversation.
class _Used extends StatelessWidget {
  const _Used({required this.used, required this.limit});

  final int used;
  final int limit;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final c = RgColors.of(context);
    final pct = limit == 0 ? 0.0 : (used / limit).clamp(0.0, 1.0);
    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              key: const Key('mem-used'),
              value: pct,
              minHeight: 6,
              color: pct > .9 ? c.warn : c.accent,
              backgroundColor: c.line,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            l.knMemUsed(kbNum(l, limit), kbNum(l, used)),
            style: TextStyle(color: c.dim, fontSize: 12.5),
          ),
        ],
      ),
    );
  }
}

class _Change extends StatelessWidget {
  const _Change({super.key, required this.c, required this.onUndo, this.onForget});

  final MemChange c;
  final VoidCallback? onUndo;
  final VoidCallback? onForget;

  String _what(AppLocalizations l) {
    if (c.undoOf != null) {
      return switch (c.action) {
        'added' => l.knMemUndid_added,
        'edited' => l.knMemUndid_edited,
        _ => l.knMemUndid_removed,
      };
    }
    return switch (c.action) {
      'added' => l.knMemDid_added,
      'edited' => l.knMemDid_edited,
      'removed' => l.knMemDid_removed,
      _ => l.knMemDid_forgotten,
    };
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final col = RgColors.of(context);
    final undone = c.undoneBy != null;
    final ts = DateTime.tryParse(c.ts)?.toLocal();
    final when = [_day(l, c.ts), if (ts != null) DateFormat.Hm(l.localeName).format(ts)].join(' ');
    final forgotten = c.action == 'forgotten';
    return Opacity(
      opacity: undone ? .55 : 1,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          border: Border(bottom: BorderSide(color: col.line)),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _what(l),
                    style: TextStyle(fontWeight: FontWeight.w700, color: col.text, fontSize: 13.5),
                  ),
                  const SizedBox(height: 2),
                  if (forgotten)
                    Text(
                      l.knMemForgottenText,
                      style: TextStyle(color: col.dim, fontStyle: FontStyle.italic),
                    )
                  else
                    Text.rich(
                      TextSpan(
                        children: [
                          if (c.action == 'edited' && c.before != null)
                            TextSpan(
                              text: '${c.before} ',
                              style: TextStyle(
                                color: col.dim,
                                decoration: TextDecoration.lineThrough,
                              ),
                            ),
                          TextSpan(text: c.text),
                        ],
                      ),
                      style: TextStyle(color: col.text, fontSize: 13.5, height: 1.35),
                    ),
                  const SizedBox(height: 2),
                  Text(
                    forgotten ? when : '${memByWords(l, c.by, null)} · $when',
                    style: TextStyle(color: col.dim, fontSize: 12),
                  ),
                ],
              ),
            ),
            if (!forgotten)
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  if (undone)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: col.panel2,
                        borderRadius: BorderRadius.circular(99),
                        border: Border.all(color: col.line),
                      ),
                      child: Text(l.knMemUndone, style: TextStyle(color: col.dim, fontSize: 12)),
                    )
                  else
                    OutlinedButton(
                      key: Key('mem-undo-${c.seq}'),
                      onPressed: onUndo,
                      child: Text(l.knMemUndo),
                    ),
                  if (onForget != null)
                    TextButton(
                      key: Key('mem-forget-change-${c.seq}'),
                      onPressed: onForget,
                      child: Text(l.knMemForget, style: TextStyle(color: col.err)),
                    ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}

class _EditMemory extends StatefulWidget {
  const _EditMemory({required this.entry, required this.onDone});

  final MemEntry entry;
  final void Function([bool?]) onDone;

  @override
  State<_EditMemory> createState() => _EditMemoryState();
}

class _EditMemoryState extends State<_EditMemory> {
  late final _text = TextEditingController(text: widget.entry.text);
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    _text.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final l = AppLocalizations.of(context);
    final c = AppScope.read(context).client;
    if (c == null) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await c.editMemory(widget.entry.id, _text.text);
      widget.onDone(true);
    } on Exception catch (e) {
      if (mounted) setState(() => _error = memWhy(l, e));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextField(
          key: const Key('mem-edit-field'),
          controller: _text,
          minLines: 3,
          maxLines: 6,
          maxLength: 400,
          onChanged: (_) => setState(() {}),
          decoration: InputDecoration(
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
          ),
        ),
        if (_error != null) KbLine(_error!, error: true, key: const Key('mem-edit-error')),
        KbActs(
          children: [
            OutlinedButton(onPressed: () => widget.onDone(false), child: Text(l.cancel)),
            FilledButton(
              key: const Key('mem-edit-save'),
              onPressed: _busy || _text.text.trim().isEmpty ? null : _save,
              child: Text(l.save),
            ),
          ],
        ),
      ],
    );
  }
}

/// «Forget for good», said plainly: it cannot come back.
class _ForgetBody extends StatelessWidget {
  const _ForgetBody({required this.text, required this.onDone});

  final String text;
  final void Function([bool?]) onDone;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final c = RgColors.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
          decoration: BoxDecoration(
            border: Border(left: BorderSide(color: c.err.withValues(alpha: .6), width: 3)),
            color: c.panel2,
          ),
          child: Text(
            text,
            style: TextStyle(color: c.text, fontStyle: FontStyle.italic),
          ),
        ),
        KbLine(l.knMemForgetText, dim: true),
        KbActs(
          children: [
            OutlinedButton(onPressed: () => onDone(false), child: Text(l.cancel)),
            FilledButton(
              key: const Key('mem-forget-yes'),
              style: FilledButton.styleFrom(backgroundColor: c.critical),
              onPressed: () => onDone(true),
              child: Text(l.knMemForget),
            ),
          ],
        ),
      ],
    );
  }
}

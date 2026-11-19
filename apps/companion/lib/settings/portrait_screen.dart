// 3.9.4: Settings › Portrait («Mirror»), native, as the page's `Portrait.tsx`: how the agents
// see the person, built by itself from the conversations. The switch for the whole thing, which
// agents read it, the traits grouped (how sure, how often seen, «Where it comes from» opens the
// conversation, «Change», «Remove», «Not true»), a trait added by hand, the text the agents read,
// and «Forget everything» said plainly first. Routes: `/api/portrait` (api.ts).
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../api/client.dart' show ApiException;
import '../app_state.dart';
import '../l10n/app_localizations.dart';
import '../screens/conversation_screen.dart' show ConversationScreen;
import '../theme/colors.dart';
import '../ui/icons.dart';
import 'api/portrait_api.dart';
import 'knowledge_kit.dart';
import 'rules_kit.dart';

/// Opens the page: a panel over the window on a computer, a whole screen on a phone.
Future<void> openPortrait(BuildContext context) =>
    openRulesPage(context, (panel) => PortraitScreen(panel: panel));

String portraitCategoryWords(AppLocalizations l, String c) => switch (c) {
  'preference' => l.ptrCat_preference,
  'style' => l.ptrCat_style,
  'habit' => l.ptrCat_habit,
  'project' => l.ptrCat_project,
  'avoid' => l.ptrCat_avoid,
  _ => l.ptrCat_about,
};

/// How sure a trait is, in words (the page's `sureWords`).
String portraitSureWords(AppLocalizations l, PortraitTrait t) {
  if (t.edited) return l.ptrByYou;
  if (t.confidence >= .7) return l.ptrSure;
  if (t.confidence >= .35) return l.ptrLikely;
  return l.ptrUnsure;
}

String _who(AppLocalizations l, String k) => switch (k) {
  'god' => l.ptrWho_god,
  'orchestrators' => l.ptrWho_orchestrators,
  'chat' => l.ptrWho_chat,
  _ => l.ptrWho_others,
};

/// The server's reason in plain words (`portrait_<code>`), or its message.
String portraitWhy(AppLocalizations l, Object e) {
  if (e is! ApiException) return '$e';
  return switch (e.code) {
    'portrait_empty' => l.ptrErr_empty,
    'portrait_long' => l.ptrErr_long,
    'portrait_secret' => l.ptrErr_secret,
    'portrait_private' => l.ptrErr_private,
    'portrait_gone' => l.ptrErr_gone,
    _ => e.message,
  };
}

String _day(AppLocalizations l, String iso) {
  final d = DateTime.tryParse(iso)?.toLocal();
  if (d == null) return '';
  final f = d.year == DateTime.now().year
      ? DateFormat.MMMd(l.localeName)
      : DateFormat.yMMMd(l.localeName);
  return f.format(d);
}

class PortraitScreen extends StatefulWidget {
  const PortraitScreen({super.key, this.panel = false});

  final bool panel;

  @override
  State<PortraitScreen> createState() => _PortraitScreenState();
}

class _PortraitScreenState extends State<PortraitScreen> {
  PortraitView? _v;
  String? _error;
  bool _showText = false;
  String _cat = 'preference';
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
      final v = await c.portrait();
      if (mounted) setState(() => _v = v);
    } on Exception catch (e) {
      if (mounted) setState(() => _error = portraitWhy(AppLocalizations.of(context), e));
    }
  }

  Future<bool> _run(Future<void> Function() f) async {
    final l = AppLocalizations.of(context);
    setState(() => _error = null);
    try {
      await f();
      await _load();
      return true;
    } on Exception catch (e) {
      if (mounted) setState(() => _error = portraitWhy(l, e));
      return false;
    }
  }

  Future<void> _addOne() async {
    final c = AppScope.read(context).client;
    final text = _add.text;
    if (c == null || text.trim().isEmpty) return;
    if (await _run(() => c.addTrait(text, _cat)) && mounted) setState(_add.clear);
  }

  Future<void> _edit(PortraitTrait t) async {
    final saved = await kbWindow<bool>(
      context,
      key: const Key('portrait-edit'),
      title: AppLocalizations.of(context).ptrEditTitle,
      body: (ctx, close) => _EditTrait(trait: t, onDone: close),
    );
    if (saved == true && mounted) await _load();
  }

  Future<void> _sources(PortraitTrait t) async {
    final l = AppLocalizations.of(context);
    final app = AppScope.read(context);
    final open = await kbWindow<PortraitSource>(
      context,
      key: const Key('portrait-sources'),
      title: l.ptrWhere,
      body: (ctx, close) => _Sources(trait: t, onOpen: close),
    );
    if (open == null || !mounted) return;
    final agent = app.agents.where((a) => a.id == open.agentId).firstOrNull;
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => ConversationScreen(sessionId: open.sessionId, agent: agent),
      ),
    );
  }

  Future<void> _forget() async {
    final l = AppLocalizations.of(context);
    final c = AppScope.read(context).client;
    final yes = await kbWindow<bool>(
      context,
      key: const Key('portrait-forget-window'),
      title: l.ptrForgetTitle,
      body: (ctx, close) => _ForgetBody(onDone: close),
    );
    if (yes != true || c == null || !mounted) return;
    await _run(c.forgetPortrait);
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final col = RgColors.of(context);
    final v = _v;
    final client = AppScope.of(context).client;
    return RulesPage(
      pageKey: const Key('portrait-settings'),
      title: l.ptrSection,
      panel: widget.panel,
      question: l.ptrTitle,
      lead: l.ptrLead,
      children: [
        if (v == null) RulesLoading(error: _error),
        if (v != null) ...[
          KbBox(
            children: [
              KbSwitchRow(
                key: const Key('portrait-on'),
                title: l.ptrOnTitle,
                help: v.on ? l.ptrOnOn : l.ptrOnOff,
                on: v.on,
                onChanged: client == null ? null : (on) => _run(() => client.setPortrait(on: on)),
              ),
            ],
          ),
          RulesSub(title: l.ptrWhoTitle, lead: l.ptrWhoLead),
          KbBox(
            children: [
              for (final k in PortraitAgents.keys)
                KbSwitchRow(
                  key: Key('portrait-who-$k'),
                  title: _who(l, k),
                  on: v.agents.of(k),
                  onChanged: client == null || !v.on
                      ? null
                      : (on) => _run(() => client.setPortrait(agents: v.agents.withValue(k, on))),
                ),
            ],
          ),
          RulesSub(
            title:
                '${l.ptrListTitle} · ${v.traits.length == 1 ? l.ptrCountOne : l.ptrCount('${v.traits.length}')}',
            lead: l.ptrListLead,
          ),
          KbBox(
            children: [
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      key: const Key('portrait-add-field'),
                      controller: _add,
                      maxLength: 200,
                      textInputAction: TextInputAction.done,
                      onSubmitted: (_) => _addOne(),
                      onChanged: (_) => setState(() {}),
                      decoration: InputDecoration(
                        hintText: l.ptrAddPlaceholder,
                        counterText: '',
                        isDense: true,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  FilledButton.icon(
                    key: const Key('portrait-add'),
                    onPressed: _add.text.trim().isEmpty ? null : _addOne,
                    icon: const RgIcon(RgIcons.plus, size: 16, color: Colors.white),
                    label: Text(l.ptrAdd),
                  ),
                ],
              ),
              if (_add.text.trim().isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: RgChoice<String>(
                    options: [for (final c in portraitCategories) (c, portraitCategoryWords(l, c))],
                    value: _cat,
                    keyOf: (c) => 'portrait-add-cat-$c',
                    onChanged: (c) => setState(() => _cat = c),
                  ),
                ),
              if (_error != null) KbLine(_error!, error: true, key: const Key('portrait-error')),
              const SizedBox(height: 6),
              if (v.traits.isEmpty)
                KbLine(v.on ? l.ptrEmpty : l.ptrEmptyOff, dim: true)
              else
                for (final cat in portraitCategories)
                  if (v.traits.any((t) => t.category == cat)) ...[
                    Padding(
                      padding: const EdgeInsets.only(top: 12, bottom: 2),
                      child: Text(
                        portraitCategoryWords(l, cat).toUpperCase(),
                        key: Key('portrait-group-$cat'),
                        style: TextStyle(
                          color: col.dim,
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          letterSpacing: .4,
                        ),
                      ),
                    ),
                    for (final t in v.traits.where((t) => t.category == cat))
                      _Trait(
                        key: Key('portrait-trait-${t.id}'),
                        t: t,
                        onEdit: () => _edit(t),
                        onRemove: client == null
                            ? null
                            : () => _run(() => client.removeTrait(t.id)),
                        onDeny: client == null ? null : () => _run(() => client.denyTrait(t.id)),
                        onSources: t.sources.isEmpty ? null : () => _sources(t),
                      ),
                  ],
              if (v.denied > 0)
                Padding(
                  padding: const EdgeInsets.only(top: 10),
                  child: Text(
                    v.denied == 1 ? l.ptrDeniedOne : l.ptrDenied('${v.denied}'),
                    key: const Key('portrait-denied'),
                    style: TextStyle(color: col.dim, fontSize: 13),
                  ),
                ),
            ],
          ),
          if (v.text.isNotEmpty) ...[
            RulesSub(title: l.ptrTextTitle, lead: l.ptrTextLead),
            KbBox(
              children: [
                Align(
                  alignment: Alignment.centerLeft,
                  child: OutlinedButton.icon(
                    key: const Key('portrait-text-toggle'),
                    onPressed: () => setState(() => _showText = !_showText),
                    icon: RgIcon(RgIcons.eye, size: 15, color: col.dim),
                    label: Text(_showText ? l.ptrTextHide : l.ptrTextShow),
                  ),
                ),
                if (_showText)
                  Container(
                    key: const Key('portrait-text'),
                    margin: const EdgeInsets.only(top: 10),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: col.panel2,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: SelectableText(
                      v.text,
                      style: TextStyle(color: col.text, fontSize: 13, height: 1.45),
                    ),
                  ),
              ],
            ),
          ],
          RulesSub(title: l.ptrForgetTitle, lead: l.ptrForgetLead),
          Align(
            alignment: Alignment.centerLeft,
            child: OutlinedButton.icon(
              key: const Key('portrait-forget'),
              onPressed: client == null || (v.traits.isEmpty && v.denied == 0) ? null : _forget,
              icon: RgIcon(RgIcons.trash, size: 15, color: col.err),
              label: Text(l.ptrForget, style: TextStyle(color: col.err)),
            ),
          ),
        ],
      ],
    );
  }
}

class _Trait extends StatelessWidget {
  const _Trait({
    super.key,
    required this.t,
    required this.onEdit,
    required this.onRemove,
    required this.onDeny,
    this.onSources,
  });

  final PortraitTrait t;
  final VoidCallback onEdit;
  final VoidCallback? onRemove;
  final VoidCallback? onDeny;
  final VoidCallback? onSources;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final c = RgColors.of(context);
    final small = TextStyle(color: c.dim, fontSize: 12.5);
    final sure = t.edited || t.confidence >= .7;
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: c.line)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(t.text, style: TextStyle(color: c.text, fontSize: 14.5, height: 1.4)),
          const SizedBox(height: 4),
          Wrap(
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 1),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(99),
                  border: Border.all(color: sure ? c.accent : c.line),
                ),
                child: Text(
                  portraitSureWords(l, t),
                  style: TextStyle(color: sure ? c.accent : c.dim, fontSize: 12),
                ),
              ),
              Text(
                ' · ${t.confirmations > 0 ? l.ptrSeen('${t.confirmations + 1}') : l.ptrSeenOnce}'
                ' · ${_day(l, t.seenAt)}',
                style: small,
              ),
              if (onSources != null) ...[
                Text(' · ', style: small),
                InkWell(
                  key: Key('portrait-where-${t.id}'),
                  onTap: onSources,
                  child: Text(
                    l.ptrWhere,
                    style: small.copyWith(color: c.accent, decoration: TextDecoration.underline),
                  ),
                ),
              ],
            ],
          ),
          Wrap(
            spacing: 2,
            children: [
              TextButton.icon(
                key: Key('portrait-edit-${t.id}'),
                onPressed: onEdit,
                icon: RgIcon(RgIcons.edit, size: 15, color: c.dim),
                label: Text(l.ptrEdit, style: TextStyle(color: c.text)),
              ),
              TextButton.icon(
                key: Key('portrait-remove-${t.id}'),
                onPressed: onRemove,
                icon: RgIcon(RgIcons.trash, size: 15, color: c.dim),
                label: Text(l.ptrRemove, style: TextStyle(color: c.text)),
              ),
              TextButton.icon(
                key: Key('portrait-deny-${t.id}'),
                onPressed: onDeny,
                icon: RgIcon(RgIcons.x, size: 15, color: c.err),
                label: Text(l.ptrDeny, style: TextStyle(color: c.err)),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// «Where it comes from»: each conversation that showed the trait; a tap opens it.
class _Sources extends StatelessWidget {
  const _Sources({required this.trait, required this.onOpen});

  final PortraitTrait trait;
  final void Function([PortraitSource?]) onOpen;

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
            border: Border(left: BorderSide(color: c.accent, width: 3)),
            color: c.panel2,
          ),
          child: Text(
            trait.text,
            style: TextStyle(color: c.text, fontStyle: FontStyle.italic),
          ),
        ),
        const SizedBox(height: 8),
        for (final s in trait.sources)
          ListTile(
            key: Key('portrait-source-${s.sessionId}'),
            contentPadding: EdgeInsets.zero,
            title: Text(
              s.sessionTitle != null ? '«${s.sessionTitle}»' : l.ptrUntitled,
              style: TextStyle(color: c.accent),
            ),
            subtitle: Text(
              [if (s.agentName != null) l.ptrWith(s.agentName!), _day(l, s.at)].join(' · '),
              style: TextStyle(color: c.dim, fontSize: 12.5),
            ),
            trailing: RgIcon(RgIcons.chevronRight, color: c.dim),
            onTap: () => onOpen(s),
          ),
        KbActs(
          children: [OutlinedButton(onPressed: () => onOpen(), child: Text(l.close))],
        ),
      ],
    );
  }
}

class _EditTrait extends StatefulWidget {
  const _EditTrait({required this.trait, required this.onDone});

  final PortraitTrait trait;
  final void Function([bool?]) onDone;

  @override
  State<_EditTrait> createState() => _EditTraitState();
}

class _EditTraitState extends State<_EditTrait> {
  late final _text = TextEditingController(text: widget.trait.text);
  late String _cat = widget.trait.category;
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
      await c.editTrait(widget.trait.id, text: _text.text, category: _cat);
      widget.onDone(true);
    } on Exception catch (e) {
      if (mounted) setState(() => _error = portraitWhy(l, e));
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
          key: const Key('portrait-edit-field'),
          controller: _text,
          minLines: 2,
          maxLines: 5,
          maxLength: 200,
          onChanged: (_) => setState(() {}),
          decoration: InputDecoration(
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
          ),
        ),
        RgChoice<String>(
          options: [for (final c in portraitCategories) (c, portraitCategoryWords(l, c))],
          value: _cat,
          keyOf: (c) => 'portrait-edit-cat-$c',
          onChanged: (c) => setState(() => _cat = c),
        ),
        KbLine(l.ptrEditNote, dim: true),
        if (_error != null) KbLine(_error!, error: true, key: const Key('portrait-edit-error')),
        KbActs(
          children: [
            OutlinedButton(onPressed: () => widget.onDone(false), child: Text(l.cancel)),
            FilledButton(
              key: const Key('portrait-edit-save'),
              onPressed: _busy || _text.text.trim().isEmpty ? null : _save,
              child: Text(l.save),
            ),
          ],
        ),
      ],
    );
  }
}

/// «Forget everything», said plainly: it cannot be undone.
class _ForgetBody extends StatelessWidget {
  const _ForgetBody({required this.onDone});

  final void Function([bool?]) onDone;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final c = RgColors.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        KbLine(l.ptrForgetText, dim: true),
        KbActs(
          children: [
            OutlinedButton(onPressed: () => onDone(false), child: Text(l.cancel)),
            FilledButton(
              key: const Key('portrait-forget-yes'),
              style: FilledButton.styleFrom(backgroundColor: c.critical),
              onPressed: () => onDone(true),
              child: Text(l.ptrForget),
            ),
          ],
        ),
      ],
    );
  }
}

// Settings › Tools (G42.4, native; the page's `ToolsPage.tsx`, G34.5): every common tool in its
// group, with what it does and what it weighs on every message, and a switch for every agent. The
// essential ones (`TOOL_CATALOG`, `essential`) keep a locked switch and say why: they never switch
// off. On top, the weight now and what the switched off ones save; a search; the agents whose own
// choice differs, with the way back to the rule for everyone; the extensions' tools. New
// conversations only (the tool set is fixed when a conversation starts).
import 'dart:async';

import 'package:flutter/material.dart';

import '../app_state.dart';
import '../l10n/app_localizations.dart';
import '../l10n/tool_words.g.dart';
import '../screens/new_agent_screen.dart' show RgSwitch;
import '../theme/colors.dart';
import '../ui/icons.dart';
import 'api/rules_api.dart';
import 'rules_kit.dart';
import 'tool_kits.dart';

Future<void> openToolsSettings(BuildContext context) =>
    openRulesPage(context, (panel) => ToolsScreen(panel: panel));

const _groupIcons = <String, RgIcons>{
  'files': RgIcons.file,
  'web': RgIcons.globe,
  'memory': RgIcons.bookmark,
  'credentials': RgIcons.lock,
  'canvas': RgIcons.canvas,
  'mail': RgIcons.mail,
  'talk': RgIcons.chat,
  'agents': RgIcons.users,
  'platform': RgIcons.layers,
};

String _word(AppLocalizations l, String key, [String fallback = '']) =>
    toolWords[l.localeName.startsWith('it') ? 'it' : 'en']?[key] ?? fallback;

/// Tokens as people say them («circa 320»), as the page's `aboutTokens`.
String aboutTokens(AppLocalizations l, int n) {
  final v = n < 20 ? n : (n / 10).round() * 10;
  final s = '$v';
  final sep = l.localeName.startsWith('it') ? '.' : ',';
  final out = StringBuffer();
  for (var i = 0; i < s.length; i++) {
    if (i > 0 && (s.length - i) % 3 == 0) out.write(sep);
    out.write(s[i]);
  }
  return out.toString();
}

String _fold(String s) {
  const from = 'àáâäèéêëìíîïòóôöùúûüç';
  const to = 'aaaaeeeeiiiioooouuuuc';
  final low = s.toLowerCase();
  final b = StringBuffer();
  for (final ch in low.split('')) {
    final i = from.indexOf(ch);
    b.write(i < 0 ? ch : to[i]);
  }
  return b.toString();
}

/// The entries a search finds: by the name in words, the real name and what it does (`findTools`).
List<ToolView> findTools(AppLocalizations l, List<ToolView> entries, String q) {
  final words = _fold(q).split(RegExp(r'\s+')).where((w) => w.isNotEmpty).toList();
  if (words.isEmpty) return entries;
  return [
    for (final e in entries)
      if (words.every(
        (w) => _fold(
          '${_word(l, 'tool_${e.id}', e.id)} ${e.id} ${e.id.replaceAll('_', ' ')} '
          '${_word(l, 'toolDo_${e.id}')}',
        ).contains(w),
      ))
        e,
  ];
}

/// The tools off for every agent if [id] goes [on]: never an essential one.
List<String> toolsOffAfter(List<ToolView> entries, String id, bool on) => [
  for (final x in entries)
    if (!x.essential && (x.id == id ? !on : !x.global)) x.id,
];

class ToolsScreen extends StatefulWidget {
  const ToolsScreen({super.key, this.panel = false});

  final bool panel;

  @override
  State<ToolsScreen> createState() => _ToolsScreenState();
}

class _ToolsScreenState extends State<ToolsScreen> {
  ToolsView? _view;
  List<({String name, String description})> _ext = const [];
  String? _error;
  bool _busy = false;
  String _q = '';

  @override
  void initState() {
    super.initState();
    unawaited(_load());
    unawaited(_loadExt());
  }

  Future<void> _load() async {
    final c = AppScope.read(context).client;
    if (c == null) return;
    try {
      final v = await c.toolsView();
      if (mounted) {
        setState(() {
          _view = v;
          _error = null;
        });
      }
    } on Exception catch (e) {
      if (mounted) setState(() => _error = rulesWhy(e));
    }
  }

  Future<void> _loadExt() async {
    final c = AppScope.read(context).client;
    if (c == null) return;
    try {
      final x = await c.extensionTools();
      if (mounted) setState(() => _ext = x);
    } on Exception {
      // No extensions' section: nothing to show.
    }
  }

  Future<void> _flip(ToolView e, bool on) async {
    final c = AppScope.read(context).client;
    final v = _view;
    if (c == null || v == null || e.essential || _busy) return;
    final off = toolsOffAfter(v.entries, e.id, on);
    setState(() {
      _view = v.flipped(e.id, on);
      _busy = true;
    });
    try {
      await c.setToolsOff(off);
    } on Exception catch (err) {
      if (mounted) setState(() => _error = rulesWhy(err));
    } finally {
      if (mounted) setState(() => _busy = false);
      await _load();
    }
  }

  Future<void> _reset(ToolView e) async {
    final c = AppScope.read(context).client;
    if (c == null) return;
    setState(() => _busy = true);
    try {
      for (final x in e.exceptions) {
        await c.setAgentTools(x.agentId, {e.id: 'default'});
      }
    } on Exception catch (err) {
      if (mounted) setState(() => _error = rulesWhy(err));
    } finally {
      if (mounted) setState(() => _busy = false);
      await _load();
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final c = RgColors.of(context);
    final v = _view;
    final children = <Widget>[];
    if (_error != null) {
      children.add(
        Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: RulesLoading(error: l.g4TlError(_error!)),
        ),
      );
    }
    if (v == null) {
      if (_error == null) {
        children.add(
          Padding(
            padding: const EdgeInsets.all(24),
            child: Center(
              child: Text(l.g4TlLoading, style: TextStyle(color: c.dim)),
            ),
          ),
        );
      }
    } else {
      final on = v.entries.where((e) => e.state == 'on').length;
      children.addAll([
        IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            spacing: 10,
            children: [
              Expanded(
                child: _SumBox(
                  key: const Key('tl-total'),
                  strong: l.tkStartTotal(aboutTokens(l, v.total)),
                  small: l.g4TlHowMany('$on', '${v.entries.length}'),
                ),
              ),
              Expanded(
                child: _SumBox(
                  key: const Key('tl-saved'),
                  strong: v.saved > 0 ? l.tkRest(aboutTokens(l, v.saved)) : l.g4TlNoneSaved,
                  lit: v.saved > 0,
                ),
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(4, 12, 4, 10),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              RgIcon(RgIcons.info, size: 16, color: c.dim),
              const SizedBox(width: 8),
              Expanded(
                child: Text(l.g4TlNewOnly, style: TextStyle(color: c.dim, fontSize: 13)),
              ),
            ],
          ),
        ),
        // The groups (3.9.4): off by default, always on, or off by the person.
        ToolKitsSection(
          view: v,
          onView: (n) => setState(() => _view = n),
          onError: (e) => setState(() => _error = e),
          reload: _load,
        ),
        const SizedBox(height: 12),
        TextField(
          key: const Key('tl-search'),
          decoration: InputDecoration(
            hintText: l.g4TlSearch,
            isDense: true,
            prefixIcon: Padding(
              padding: const EdgeInsets.all(12),
              child: RgIcon(RgIcons.search, size: 18, color: c.dim),
            ),
            prefixIconConstraints: const BoxConstraints(minWidth: 42, minHeight: 42),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          ),
          onChanged: (q) => setState(() => _q = q),
        ),
        ..._groups(l, c, v),
        if (_ext.isNotEmpty) ...[
          RulesSub(title: l.g4TlExtTitle, lead: l.g4TlExtLead, icon: RgIcons.layers),
          _Card(
            children: [
              for (final x in _ext)
                Padding(
                  key: Key('tl-ext-${x.name}'),
                  padding: const EdgeInsets.fromLTRB(14, 10, 14, 10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _Name(name: x.name, id: x.name),
                      if (x.description.isNotEmpty)
                        Text(x.description, style: TextStyle(color: c.dim, fontSize: 12.5)),
                    ],
                  ),
                ),
            ],
          ),
        ],
      ]);
    }
    return RulesPage(
      pageKey: const Key('tools-settings'),
      title: l.g4TlSection,
      question: l.g4TlQ,
      lead: l.g4TlLead,
      panel: widget.panel,
      children: children,
    );
  }

  List<Widget> _groups(AppLocalizations l, RgColors c, ToolsView v) {
    final found = findTools(l, v.entries, _q);
    if (found.isEmpty) {
      return [
        Padding(
          key: const Key('tl-none'),
          padding: const EdgeInsets.all(20),
          child: Text(l.g4TlNoMatch(_q.trim()), style: TextStyle(color: c.dim)),
        ),
      ];
    }
    final groups = <String, List<ToolView>>{};
    for (final e in found) {
      (groups[e.group] ??= []).add(e);
    }
    return [
      for (final g in groups.entries) ...[
        RulesSub(
          title: _word(l, 'toolGrp_${g.key}', g.key),
          icon: _groupIcons[g.key] ?? RgIcons.tool,
        ),
        _Card(
          children: [
            for (final (i, e) in g.value.indexed) ...[
              if (i > 0) Divider(height: 1, color: c.line),
              _ToolRow(e: e, busy: _busy, onFlip: (on) => _flip(e, on), onReset: () => _reset(e)),
            ],
          ],
        ),
      ],
    ];
  }
}

class _Card extends StatelessWidget {
  const _Card({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final c = RgColors.of(context);
    return Material(
      color: c.panel,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(color: c.line),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: children),
    );
  }
}

class _SumBox extends StatelessWidget {
  const _SumBox({super.key, required this.strong, this.small, this.lit = false});

  final String strong;
  final String? small;
  final bool lit;

  @override
  Widget build(BuildContext context) {
    final c = RgColors.of(context);
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: lit ? c.accentSoft : c.panel,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: lit ? c.accent : c.line),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            strong,
            style: TextStyle(fontWeight: FontWeight.w800, color: c.text, fontSize: 14, height: 1.3),
          ),
          if (small != null)
            Padding(
              padding: const EdgeInsets.only(top: 3),
              child: Text(small!, style: TextStyle(color: c.dim, fontSize: 12.5)),
            ),
        ],
      ),
    );
  }
}

class _Name extends StatelessWidget {
  const _Name({required this.name, required this.id});

  final String name;
  final String id;

  @override
  Widget build(BuildContext context) {
    final c = RgColors.of(context);
    return Wrap(
      spacing: 8,
      runSpacing: 2,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        Text(
          name,
          style: TextStyle(fontWeight: FontWeight.w700, color: c.text, fontSize: 14.5),
        ),
        // The real name: the one in the chat's lines and in request_tool.
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
          decoration: BoxDecoration(color: c.panel2, borderRadius: BorderRadius.circular(6)),
          child: Text(
            id,
            style: TextStyle(fontFamily: 'monospace', fontSize: 11.5, color: c.dim),
          ),
        ),
      ],
    );
  }
}

class _ToolRow extends StatelessWidget {
  const _ToolRow({
    required this.e,
    required this.busy,
    required this.onFlip,
    required this.onReset,
  });

  final ToolView e;
  final bool busy;
  final ValueChanged<bool> onFlip;
  final VoidCallback onReset;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final c = RgColors.of(context);
    final name = _word(l, 'tool_${e.id}', e.id);
    final does = _word(l, 'toolDo_${e.id}');
    final why = _word(l, 'toolWhy_${e.id}');
    final names = e.exceptions.map((x) => x.name).join(', ');
    return Semantics(
      toggled: e.global,
      enabled: !e.essential,
      label: name,
      child: InkWell(
        key: Key('tl-tool-${e.id}'),
        onTap: e.essential || busy ? null : () => onFlip(!e.global),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _Name(name: name, id: e.id),
                    if (does.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 3),
                        child: Text(
                          does,
                          style: TextStyle(color: c.dim, fontSize: 12.5, height: 1.35),
                        ),
                      ),
                    Padding(
                      padding: const EdgeInsets.only(top: 3),
                      child: Text(
                        [
                          l.g4TlWeight(aboutTokens(l, e.tokens)),
                          // Off at the start: the agent switches it on with its group (3.9.4).
                          if (e.state == 'auto') l.tkStateAuto,
                        ].join(' · '),
                        style: TextStyle(color: c.dim, fontSize: 11.5),
                      ),
                    ),
                    if (e.essential)
                      Padding(
                        key: Key('tl-tool-${e.id}-locked'),
                        padding: const EdgeInsets.only(top: 4),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Padding(
                              padding: const EdgeInsets.only(top: 1),
                              child: RgIcon(RgIcons.lock, size: 13, color: c.accent),
                            ),
                            const SizedBox(width: 5),
                            Expanded(
                              child: Text(
                                l.g4TlNeeded(why),
                                style: TextStyle(color: c.accent, fontSize: 12),
                              ),
                            ),
                          ],
                        ),
                      ),
                    if (e.exceptions.isNotEmpty)
                      Padding(
                        key: Key('tl-tool-${e.id}-except'),
                        padding: const EdgeInsets.only(top: 6),
                        child: Wrap(
                          crossAxisAlignment: WrapCrossAlignment.center,
                          spacing: 4,
                          children: [
                            RgIcon(RgIcons.info, size: 13, color: c.warnText),
                            Text(
                              e.global ? l.g4TlExceptOff(names) : l.g4TlExceptOn(names),
                              style: TextStyle(color: c.warnText, fontSize: 12),
                            ),
                            TextButton(
                              key: Key('tl-tool-${e.id}-reset'),
                              onPressed: busy ? null : onReset,
                              style: TextButton.styleFrom(
                                visualDensity: VisualDensity.compact,
                                padding: const EdgeInsets.symmetric(horizontal: 6),
                              ),
                              child: Text(l.g4TlExceptReset),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Opacity(
                opacity: e.essential ? .55 : 1,
                child: RgSwitch(on: e.global),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// The palette (G40.17, Ctrl/Cmd+K): one field for agents, requests, conversations, files and
// commands. Up and Down choose, Enter opens, Tab asks the chosen agent without opening its
// conversation, Ctrl/Cmd+Enter opens it in a floating panel. With the advanced interface the
// prefixes narrow it: «>» commands, «@» agents, «#» files, «:» lines of code, «!» a command in
// your terminal, «?» the Log's events («/» works as «>» everywhere). The ranking is pure
// ([parsePaletteQuery], [filterPalette]) and tested as a table.
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../api/client.dart';
import '../api/conversation.dart';
import '../api/types.dart';
import '../app_state.dart';
import '../l10n/app_localizations.dart';
import '../mascot/mascot_view.dart';
import '../screens/inbox_screen.dart';
import '../screens/new_agent_screen.dart';
import '../theme/colors.dart';
import '../ui/highlight.dart';
import '../ui/icons.dart';
import '../ui/words.dart';
import 'desk_controller.dart';
import 'desk_menu.dart';

enum PaletteSection { agents, requests, conversations, files, lines, commands, terminal, events }

class PaletteItem {
  PaletteItem({
    required this.key,
    required this.section,
    required this.title,
    required this.run,
    this.subtitle,
    this.hint,
    this.icon,
    this.agent,
    this.detail,
    this.ask,
    this.float,
  });

  final String key;
  final PaletteSection section;
  final String title;
  final String? subtitle;

  /// A shortcut shown on the right.
  final String? hint;
  final RgIcons? icon;

  /// An agent's row shows its mascot.
  final Agent? agent;

  /// A few lines for the side of the advanced palette.
  final String? detail;
  final FutureOr<void> Function() run;

  /// Tab: ask without opening (agents only).
  final Agent? ask;

  /// Ctrl/Cmd+Enter: in a floating panel.
  final VoidCallback? float;
}

class PaletteQuery {
  const PaletteQuery(this.text, {this.only});

  final String text;

  /// A prefix narrowed the palette to one section.
  final PaletteSection? only;
}

/// The prefixes: «>» and «/» commands, «@» agents everywhere; with the advanced interface «#»
/// files, «:» lines, «!» a terminal command and «?» the Log's events.
PaletteQuery parsePaletteQuery(String raw, {required bool advanced}) {
  final t = raw.trimLeft();
  if (t.isEmpty) return const PaletteQuery('');
  final rest = t.substring(1).trimLeft();
  return switch (t[0]) {
    '>' || '/' => PaletteQuery(rest, only: PaletteSection.commands),
    '@' => PaletteQuery(rest, only: PaletteSection.agents),
    '#' when advanced => PaletteQuery(rest, only: PaletteSection.files),
    ':' when advanced => PaletteQuery(rest, only: PaletteSection.lines),
    '!' when advanced => PaletteQuery(rest, only: PaletteSection.terminal),
    '?' when advanced => PaletteQuery(rest, only: PaletteSection.events),
    _ => PaletteQuery(t.trim()),
  };
}

const _plain = {
  'à': 'a',
  'á': 'a',
  'è': 'e',
  'é': 'e',
  'ì': 'i',
  'í': 'i',
  'ò': 'o',
  'ó': 'o',
  'ù': 'u',
  'ú': 'u',
};

String _fold(String s) {
  final b = StringBuffer();
  for (final ch in s.toLowerCase().split('')) {
    b.write(_plain[ch] ?? ch);
  }
  return b.toString();
}

/// How well [title] (and [subtitle]) match [query]: lower is better, null is no match. The
/// beginning of the title, then the beginning of a word, then anywhere, then the subtitle, then
/// the letters in order («cdw» finds «Coder Web»).
int? matchScore(String query, String title, [String? subtitle]) {
  final q = _fold(query.trim());
  if (q.isEmpty) return 5;
  final t = _fold(title);
  if (t.startsWith(q)) return 0;
  if (RegExp('(^|[\\s/._«-])${RegExp.escape(q)}').hasMatch(t)) return 1;
  if (t.contains(q)) return 2;
  if (subtitle != null && _fold(subtitle).contains(q)) return 3;
  var i = 0;
  for (final ch in t.split('')) {
    if (i < q.length && ch == q[i]) i++;
  }
  if (i == q.length && q.length >= 2) return 4;
  return null;
}

/// The palette's rows: the sections in [PaletteSection]'s order, each sorted by [matchScore]
/// (stable), at most [perSection] each (all of one section when a prefix chose it). Items whose
/// section always matches (terminal, events: they repeat the text) are kept as they are.
List<PaletteItem> filterPalette(List<PaletteItem> items, PaletteQuery q, {int perSection = 5}) {
  final out = <PaletteItem>[];
  for (final s in PaletteSection.values) {
    if (q.only != null && q.only != s) continue;
    final scored = <(int, int, PaletteItem)>[];
    for (final (i, it) in items.indexed) {
      if (it.section != s) continue;
      final always =
          s == PaletteSection.terminal ||
          s == PaletteSection.events ||
          s == PaletteSection.lines ||
          (s == PaletteSection.files && q.text.isNotEmpty);
      final score = always ? 0 : matchScore(q.text, it.title, it.subtitle);
      if (score != null) scored.add((score, i, it));
    }
    scored.sort((a, b) => a.$1 != b.$1 ? a.$1 - b.$1 : a.$2 - b.$2);
    final max = q.only != null ? 30 : perSection;
    out.addAll(scored.take(max).map((e) => e.$3));
  }
  return out;
}

String sectionLabel(AppLocalizations l, PaletteSection s) => switch (s) {
  PaletteSection.agents => l.deskPaletteAgents,
  PaletteSection.requests => l.deskPaletteRequests,
  PaletteSection.conversations => l.deskPaletteConversations,
  PaletteSection.files => l.deskPaletteFiles,
  PaletteSection.lines => l.deskPaletteLines,
  PaletteSection.commands => l.deskPaletteCommands,
  PaletteSection.terminal => l.deskPaletteTerminal,
  PaletteSection.events => l.deskPaletteEvents,
};

/// One line about a request for the person.
String requestLine(PersonRequest r) => switch (r) {
  PermissionRequest() => requestSummary(r),
  QuestionRequest(:final questions) => questions.firstOrNull?.question ?? '',
};

/// Opens the palette over the window; [initial] is written in its field (a prefix).
Future<void> showPalette(
  BuildContext context, {
  required DeskController desk,
  required List<DeskCommand> commands,
  String initial = '',
}) => showGeneralDialog<void>(
  context: context,
  barrierDismissible: true,
  barrierLabel: AppLocalizations.of(context).deskPaletteTitle,
  barrierColor: Colors.black.withValues(alpha: .28),
  transitionDuration: const Duration(milliseconds: 120),
  pageBuilder: (ctx, _, _) => DeskScope(
    desk: desk,
    child: CommandPalette(commands: commands, initial: initial),
  ),
);

class CommandPalette extends StatefulWidget {
  const CommandPalette({super.key, required this.commands, this.initial = ''});

  final List<DeskCommand> commands;
  final String initial;

  @override
  State<CommandPalette> createState() => _CommandPaletteState();
}

class _CommandPaletteState extends State<CommandPalette> {
  late final _text = TextEditingController(text: widget.initial);
  final _focus = FocusNode();
  final _list = ScrollController();
  int _sel = 0;
  Agent? _asking;
  List<SearchHitRow> _hits = const [];
  Timer? _search;
  String _searched = '';

  @override
  void initState() {
    super.initState();
    _text.addListener(_changed);
    _text.selection = TextSelection.collapsed(offset: _text.text.length);
    WidgetsBinding.instance.addPostFrameCallback((_) => _changed());
  }

  @override
  void dispose() {
    _search?.cancel();
    _text.dispose();
    _focus.dispose();
    _list.dispose();
    super.dispose();
  }

  void _changed() {
    if (!mounted) return;
    setState(() => _sel = 0);
    final app = AppScope.read(context);
    final desk = DeskScope.read(context);
    final q = parsePaletteQuery(_text.text, advanced: app.advanced);
    final wantFiles =
        app.advanced &&
        q.text.length >= 2 &&
        (q.only == null || q.only == PaletteSection.files || q.only == PaletteSection.lines);
    final pid = desk.projectOr();
    if (!wantFiles || pid == null) {
      _search?.cancel();
      if (_hits.isNotEmpty) setState(() => _hits = const []);
      return;
    }
    final key = '$pid\n${q.text}';
    if (key == _searched) return;
    _search?.cancel();
    _search = Timer(const Duration(milliseconds: 220), () async {
      _searched = key;
      try {
        final hits = await app.client?.searchFiles('project:$pid', q.text) ?? const [];
        if (!mounted) return;
        setState(
          () => _hits = [for (final h in hits.take(40)) SearchHitRow(pid, h.path, h.line, h.text)],
        );
      } on ApiException {
        // Nothing found, as far as the palette knows.
      }
    });
  }

  List<PaletteItem> _items(AppController app, DeskController desk, AppLocalizations l, bool mac) {
    final q = parsePaletteQuery(_text.text, advanced: app.advanced);
    final size = MediaQuery.sizeOf(context);
    final items = <PaletteItem>[];
    final firstLevel = app.agents.where((a) => a.kind != AgentKind.subagent).toList();
    for (final a in firstLevel) {
      final state = app.live.mascotStateOf(a.id);
      final project = app.projects.where((p) => p.id == a.projectId).firstOrNull?.name;
      items.add(
        PaletteItem(
          key: 'agent-${a.id}',
          section: PaletteSection.agents,
          title: a.name,
          subtitle: [stateWord(l, state), ?project].join(' · '),
          agent: a,
          hint: l.deskKeyEnter,
          detail: a.role,
          run: () => desk.openAgent(a),
          ask: a,
          float: () async {
            final id = await app.openAgent(a);
            if (id != null) desk.showFloating(PanelConversation(id, agent: a), size);
          },
        ),
      );
    }
    for (final r in app.live.requests) {
      items.add(
        PaletteItem(
          key: 'request-${r.requestId}',
          section: PaletteSection.requests,
          title: l.deskPaletteAnswer(requestLine(r)),
          subtitle: r.agentName,
          icon: r is PermissionRequest && r.isCritical ? RgIcons.shield : RgIcons.alert,
          run: () => desk.show(const PanelPage(PanelScreen.inbox)),
        ),
      );
    }
    final rows = app.live.sessions.where((s) => !s.archived && (s.title ?? '').isNotEmpty).toList()
      ..sort((a, b) => b.when.compareTo(a.when));
    for (final s in rows.take(200)) {
      final agent = app.agents.where((a) => a.id == s.agentId).firstOrNull;
      items.add(
        PaletteItem(
          key: 'session-${s.id}',
          section: PaletteSection.conversations,
          title: s.title!,
          subtitle: agent?.name,
          icon: RgIcons.chat,
          run: () => desk.show(PanelConversation(s.id, agent: agent)),
          float: () => desk.showFloating(PanelConversation(s.id, agent: agent), size),
        ),
      );
    }
    final seen = <String>{};
    for (final h in _hits) {
      if (seen.add(h.path)) {
        items.add(
          PaletteItem(
            key: 'file-${h.path}',
            section: PaletteSection.files,
            title: l.deskPaletteOpenFile(h.path),
            subtitle: app.projects.where((p) => p.id == h.projectId).firstOrNull?.name,
            icon: RgIcons.file,
            detail: h.path,
            run: () => desk.openFile(h.projectId, h.path),
          ),
        );
      }
      if (h.line != null) {
        items.add(
          PaletteItem(
            key: 'line-${h.path}:${h.line}',
            section: PaletteSection.lines,
            title: '${h.path}:${h.line}',
            subtitle: h.text?.trim(),
            icon: RgIcons.code,
            detail: h.text,
            run: () => desk.openFile(h.projectId, h.path, line: h.line),
          ),
        );
      }
    }
    // The commands of the menus, and a few made from the text.
    for (final c in widget.commands) {
      if (!c.enabled) continue;
      items.add(
        PaletteItem(
          key: 'command-${c.id}',
          section: PaletteSection.commands,
          title: c.label,
          subtitle: c.group,
          icon: c.icon,
          hint: c.shortcut == null ? null : shortcutLabel(c.shortcut!, l, mac: mac),
          run: c.run,
        ),
      );
    }
    final top = firstLevel.where((a) => matchScore(q.text, a.name) != null).toList();
    if (q.text.isNotEmpty) {
      for (final a in top.take(2)) {
        if (app.runningOf(a.id).isNotEmpty) {
          items.add(
            PaletteItem(
              key: 'stop-${a.id}',
              section: PaletteSection.commands,
              title: l.deskStopAgent(a.name),
              icon: RgIcons.stop,
              run: () => app.stopAgent(a.id),
            ),
          );
        }
      }
      items.add(
        PaletteItem(
          key: 'new-agent',
          section: PaletteSection.commands,
          title: l.deskNewAgentNamed(q.text),
          icon: RgIcons.plus,
          run: () => openNewAgent(context),
        ),
      );
    }
    if (app.advanced && q.text.isNotEmpty) {
      final pid = desk.projectOr();
      final projects = [
        ...app.projects.where((p) => p.id == pid),
        ...app.projects.where((p) => p.id != pid && !p.archived),
      ];
      for (final p in projects.take(4)) {
        items.add(
          PaletteItem(
            key: 'term-${p.id}',
            section: PaletteSection.terminal,
            title: l.deskRunInTerminal(q.text, p.name),
            icon: RgIcons.terminal,
            detail: l.deskRunInTerminalDetail,
            run: () => desk.runInTerminal(p.id, q.text),
          ),
        );
      }
      items.add(
        PaletteItem(
          key: 'events',
          section: PaletteSection.events,
          title: l.deskSearchEvents(q.text),
          icon: RgIcons.list,
          run: () => desk.searchLog(q.text),
        ),
      );
    }
    return filterPalette(items, q);
  }

  Future<void> _run(PaletteItem it, {bool float = false}) async {
    final nav = Navigator.of(context);
    nav.pop();
    if (float && it.float != null) {
      it.float!();
      return;
    }
    await it.run();
  }

  Future<void> _askNow(String text) async {
    final a = _asking;
    if (a == null || text.trim().isEmpty) return;
    final desk = DeskScope.read(context);
    final messenger = ScaffoldMessenger.maybeOf(context);
    final l = AppLocalizations.of(context);
    Navigator.of(context).pop();
    final ok = await desk.askQuietly(a, text.trim());
    messenger?.showSnackBar(SnackBar(content: Text(ok ? l.deskAsked(a.name) : l.openFailed)));
  }

  KeyEventResult _key(List<PaletteItem> items, KeyEvent e) {
    if (e is! KeyDownEvent && e is! KeyRepeatEvent) return KeyEventResult.ignored;
    final k = e.logicalKey;
    final hw = HardwareKeyboard.instance;
    if (k == LogicalKeyboardKey.escape) {
      if (_asking != null) {
        setState(() {
          _asking = null;
          _text.clear();
        });
      } else {
        Navigator.of(context).pop();
      }
      return KeyEventResult.handled;
    }
    if (_asking != null) {
      if (k == LogicalKeyboardKey.enter || k == LogicalKeyboardKey.numpadEnter) {
        unawaited(_askNow(_text.text));
        return KeyEventResult.handled;
      }
      return KeyEventResult.ignored;
    }
    if (k == LogicalKeyboardKey.arrowDown) {
      setState(() => _sel = items.isEmpty ? 0 : (_sel + 1) % items.length);
      _reveal();
      return KeyEventResult.handled;
    }
    if (k == LogicalKeyboardKey.arrowUp) {
      setState(() => _sel = items.isEmpty ? 0 : (_sel - 1 + items.length) % items.length);
      _reveal();
      return KeyEventResult.handled;
    }
    if (items.isEmpty) return KeyEventResult.ignored;
    final it = items[_sel.clamp(0, items.length - 1)];
    if (k == LogicalKeyboardKey.tab && it.ask != null) {
      setState(() {
        _asking = it.ask;
        _text.clear();
      });
      return KeyEventResult.handled;
    }
    if (k == LogicalKeyboardKey.enter || k == LogicalKeyboardKey.numpadEnter) {
      unawaited(_run(it, float: hw.isControlPressed || hw.isMetaPressed));
      return KeyEventResult.handled;
    }
    return KeyEventResult.ignored;
  }

  void _reveal() {
    if (!_list.hasClients) return;
    final y = _sel * 40.0;
    final view = _list.position.viewportDimension;
    if (y < _list.offset) _list.jumpTo(y);
    if (y + 40 > _list.offset + view)
      _list.jumpTo((y + 40 - view).clamp(0, _list.position.maxScrollExtent));
  }

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    final desk = DeskScope.of(context);
    final l = AppLocalizations.of(context);
    final c = RgColors.of(context);
    final mac = isMacLike(app);
    final items = _asking == null ? _items(app, desk, l, mac) : const <PaletteItem>[];
    final sel = items.isEmpty ? null : items[_sel.clamp(0, items.length - 1)];
    final size = MediaQuery.sizeOf(context);
    final wide = app.advanced && size.width >= 1100;
    final width = wide ? 940.0 : 660.0;
    final q = parsePaletteQuery(_text.text, advanced: app.advanced);
    final rows = <Widget>[];
    PaletteSection? last;
    for (final (i, it) in items.indexed) {
      if (it.section != last) {
        last = it.section;
        rows.add(
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 4),
            child: Text(
              sectionLabel(l, it.section).toUpperCase(),
              style: TextStyle(
                fontSize: 11.5,
                letterSpacing: .6,
                fontWeight: FontWeight.w700,
                color: c.dim,
              ),
            ),
          ),
        );
      }
      rows.add(_Row(item: it, selected: i == _sel, onTap: () => _run(it)));
    }
    final list = items.isEmpty
        ? Padding(
            padding: const EdgeInsets.all(24),
            child: Text(
              _asking != null ? l.deskAskHint(_asking!.name) : l.deskPaletteNothing,
              style: TextStyle(color: c.dim),
            ),
          )
        : ListView(
            key: const Key('palette-list'),
            controller: _list,
            shrinkWrap: true,
            padding: const EdgeInsets.only(bottom: 8),
            children: rows,
          );
    return Align(
      alignment: const Alignment(0, -.55),
      child: Material(
        key: const Key('palette'),
        color: c.panel,
        elevation: 18,
        shadowColor: Colors.black54,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: BorderSide(color: c.line),
        ),
        clipBehavior: Clip.antiAlias,
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: (size.width - 48).clamp(320, width),
            maxHeight: (size.height * .72).clamp(240, 640),
          ),
          child: Focus(
            onKeyEvent: (_, e) => _key(items, e),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 10, 12, 10),
                  child: Row(
                    children: [
                      RgIcon(RgIcons.search, size: 19, color: c.text),
                      const SizedBox(width: 10),
                      if (_asking != null)
                        Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: _Tag(text: l.deskAskTag(_asking!.name), color: c.accent),
                        )
                      else if (q.only != null)
                        Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: _Tag(text: _text.text.trimLeft()[0], color: c.accent),
                        ),
                      Expanded(
                        child: TextField(
                          key: const Key('palette-field'),
                          controller: _text,
                          focusNode: _focus,
                          autofocus: true,
                          style: TextStyle(fontSize: 17, color: c.text),
                          decoration: InputDecoration(
                            isCollapsed: true,
                            filled: false,
                            border: InputBorder.none,
                            enabledBorder: InputBorder.none,
                            focusedBorder: InputBorder.none,
                            hintText: _asking != null
                                ? l.deskAskHint(_asking!.name)
                                : l.deskPaletteHint,
                          ),
                        ),
                      ),
                      KeyCap(l.deskKeyEsc),
                    ],
                  ),
                ),
                if (app.advanced && _asking == null)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(14, 0, 14, 8),
                    child: Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: [
                        for (final (p, label) in [
                          ('>', l.deskPaletteCommands),
                          ('@', l.deskPaletteAgents),
                          ('#', l.deskPaletteFiles),
                          (':', l.deskPaletteLines),
                          ('!', l.deskPaletteTerminal),
                          ('?', l.deskPaletteEvents),
                        ])
                          _PrefixChip(
                            key: Key('palette-prefix-$p'),
                            prefix: p,
                            label: label,
                            on: _text.text.trimLeft().startsWith(p),
                            onTap: () {
                              _text.text = '$p ';
                              _text.selection = TextSelection.collapsed(offset: _text.text.length);
                              _focus.requestFocus();
                            },
                          ),
                      ],
                    ),
                  ),
                Divider(height: 1, color: c.line),
                Flexible(
                  child: wide && sel != null
                      ? Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(flex: 3, child: list),
                            VerticalDivider(width: 1, color: c.line),
                            Expanded(flex: 2, child: _Detail(item: sel)),
                          ],
                        )
                      : list,
                ),
                Divider(height: 1, color: c.line),
                Padding(
                  padding: const EdgeInsets.fromLTRB(14, 8, 14, 9),
                  child: Wrap(
                    spacing: 10,
                    runSpacing: 4,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      _Hint(keys: [l.deskKeyUp, l.deskKeyDown], text: l.deskHintChoose),
                      _Hint(keys: [l.deskKeyEnter], text: l.deskHintOpen),
                      _Hint(keys: [l.deskKeyTab], text: l.deskHintAsk),
                      _Hint(
                        keys: ['${mac ? 'Cmd' : 'Ctrl'}+${l.deskKeyEnter}'],
                        text: l.deskHintFloat,
                      ),
                      Text(
                        app.advanced ? l.deskHintPrefixesAdvanced : l.deskHintPrefixes,
                        style: TextStyle(color: c.dim, fontSize: 12),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class SearchHitRow {
  const SearchHitRow(this.projectId, this.path, this.line, this.text);

  final String projectId;
  final String path;
  final int? line;
  final String? text;
}

class _Row extends StatelessWidget {
  const _Row({required this.item, required this.selected, required this.onTap});

  final PaletteItem item;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = RgColors.of(context);
    final l = AppLocalizations.of(context);
    final app = AppScope.of(context);
    final a = item.agent;
    return Semantics(
      button: true,
      selected: selected,
      child: Material(
        color: selected ? c.accentSoft : Colors.transparent,
        child: InkWell(
          key: Key('palette-${item.key}'),
          onTap: onTap,
          child: Container(
            height: 40,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              border: Border(
                left: BorderSide(color: selected ? c.accent : Colors.transparent, width: 3),
              ),
            ),
            child: Row(
              children: [
                if (a != null)
                  MascotView(
                    agentId: a.id,
                    spec: a.mascot,
                    state: app.live.mascotStateOf(a.id),
                    size: 24,
                    label: l.mascotLabel(a.name, stateWord(l, app.live.mascotStateOf(a.id))),
                  )
                else
                  RgIcon(item.icon ?? RgIcons.chevronRight, size: 17, color: c.dim),
                const SizedBox(width: 10),
                Expanded(
                  child: Text.rich(
                    TextSpan(
                      children: [
                        TextSpan(
                          text: item.title,
                          style: TextStyle(
                            fontSize: 14,
                            color: c.text,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        if (item.subtitle != null && item.subtitle!.isNotEmpty)
                          TextSpan(
                            text: '   ${item.subtitle}',
                            style: TextStyle(fontSize: 12.5, color: c.dim),
                          ),
                      ],
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 8),
                if (item.hint != null) KeyCap(item.hint!),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Detail extends StatelessWidget {
  const _Detail({required this.item});

  final PaletteItem item;

  @override
  Widget build(BuildContext context) {
    final c = RgColors.of(context);
    final l = AppLocalizations.of(context);
    final app = AppScope.of(context);
    final a = item.agent;
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          if (a != null) ...[
            MascotView(
              agentId: a.id,
              spec: a.mascot,
              state: app.live.mascotStateOf(a.id),
              size: 56,
              label: l.mascotLabel(a.name, stateWord(l, app.live.mascotStateOf(a.id))),
            ),
            const SizedBox(height: 8),
          ],
          Text(
            item.title,
            style: TextStyle(fontSize: 15.5, fontWeight: FontWeight.w700, color: c.text),
          ),
          if (item.subtitle != null)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(item.subtitle!, style: TextStyle(color: c.dim, fontSize: 13)),
            ),
          if (item.detail != null && item.detail!.isNotEmpty)
            Container(
              margin: const EdgeInsets.only(top: 12),
              padding: const EdgeInsets.all(10),
              width: double.infinity,
              decoration: BoxDecoration(color: c.code, borderRadius: BorderRadius.circular(8)),
              child: Text(
                item.detail!,
                maxLines: 8,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontFamily: monoFamily,
                  fontFamilyFallback: monoFallback,
                  fontSize: 12.5,
                  color: Color(0xFFE8E6E3),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _PrefixChip extends StatelessWidget {
  const _PrefixChip({
    super.key,
    required this.prefix,
    required this.label,
    required this.on,
    required this.onTap,
  });

  final String prefix;
  final String label;
  final bool on;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = RgColors.of(context);
    return Material(
      color: on ? c.accentSoft : c.panel2,
      shape: StadiumBorder(side: BorderSide(color: on ? c.accentDim : c.line)),
      child: InkWell(
        customBorder: const StadiumBorder(),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
          child: Text.rich(
            TextSpan(
              children: [
                TextSpan(
                  text: '$prefix  ',
                  style: const TextStyle(
                    fontFamily: monoFamily,
                    fontFamilyFallback: monoFallback,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                TextSpan(text: label),
              ],
            ),
            style: TextStyle(fontSize: 12.5, color: on ? c.accent : c.dim),
          ),
        ),
      ),
    );
  }
}

class _Tag extends StatelessWidget {
  const _Tag({required this.text, required this.color});

  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
    decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(6)),
    child: Text(
      text,
      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 13),
    ),
  );
}

class _Hint extends StatelessWidget {
  const _Hint({required this.keys, required this.text});

  final List<String> keys;
  final String text;

  @override
  Widget build(BuildContext context) {
    final c = RgColors.of(context);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (final k in keys) Padding(padding: const EdgeInsets.only(right: 4), child: KeyCap(k)),
        Text(text, style: TextStyle(color: c.dim, fontSize: 12)),
      ],
    );
  }
}

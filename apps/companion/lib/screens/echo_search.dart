// Echo (3.9.6): the search box over past conversations, as the page's left bar has it
// (EchoSearch.tsx): on the team's screen, and on a computer as a page of the panel (the palette's
// «Search past conversations»). While a search is typed its results take [child]'s place;
// clearing it brings [child] back. The results are the agents' search_conversations ones.
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../api/echo_api.dart';
import '../app_state.dart';
import '../desktop/desk_controller.dart';
import '../l10n/app_localizations.dart';
import '../theme/colors.dart';
import '../ui/icons.dart';
import 'conversation_screen.dart';

/// Opens a conversation found: the panel on a computer, the whole screen on a phone.
Future<void> openEchoHit(BuildContext context, EchoHit h) async {
  final app = AppScope.read(context);
  final a = app.agents.where((x) => x.id == h.agentId).firstOrNull;
  final desk = DeskScope.maybeRead(context);
  if (desk != null) {
    desk.show(PanelConversation(h.sessionId, agent: a));
    return;
  }
  await Navigator.of(context).push(
    MaterialPageRoute<void>(
      builder: (_) => ConversationScreen(sessionId: h.sessionId, agent: a),
    ),
  );
}

/// A snippet with the words found marked (offsets from the server, the text as it is).
TextSpan echoSpan(EchoSnippet s, TextStyle base, Color mark) {
  final out = <TextSpan>[];
  var at = 0;
  for (final (a, b) in s.marks) {
    if (a < at || b > s.text.length) continue;
    out.add(TextSpan(text: s.text.substring(at, a)));
    out.add(
      TextSpan(
        text: s.text.substring(a, b),
        style: TextStyle(backgroundColor: mark, fontWeight: FontWeight.w600),
      ),
    );
    at = b;
  }
  out.add(TextSpan(text: s.text.substring(at)));
  return TextSpan(style: base, children: out);
}

class EchoSearch extends StatefulWidget {
  const EchoSearch({super.key, this.child, this.autofocus = false, this.enabled = true});

  /// What is shown while nothing is typed (null: a hint).
  final Widget? child;
  final bool autofocus;

  /// Off: only [child] (no server or no team yet).
  final bool enabled;

  @override
  State<EchoSearch> createState() => _EchoSearchState();
}

class _EchoSearchState extends State<EchoSearch> {
  final _text = TextEditingController();
  Timer? _timer;
  int _asked = 0;
  List<EchoHit>? _hits;
  bool _failed = false;

  @override
  void dispose() {
    _timer?.cancel();
    _text.dispose();
    super.dispose();
  }

  void _changed(String v) {
    _timer?.cancel();
    final q = v.trim();
    final n = ++_asked;
    setState(() {
      _failed = false;
      if (q.length < 2) _hits = null;
    });
    if (q.length < 2) return;
    _timer = Timer(const Duration(milliseconds: 250), () async {
      final c = AppScope.read(context).client;
      if (c == null) return;
      try {
        final r = await c.searchConversations(q);
        // Only the latest question's answer is shown.
        if (mounted && n == _asked) setState(() => _hits = r);
      } catch (_) {
        if (mounted && n == _asked) setState(() => _failed = true);
      }
    });
  }

  void _clear() {
    _asked++;
    _timer?.cancel();
    _text.clear();
    setState(() {
      _hits = null;
      _failed = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.enabled && widget.child != null) return widget.child!;
    final l = AppLocalizations.of(context);
    final c = RgColors.of(context);
    final q = _text.text.trim();
    final box = Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
      child: TextField(
        key: const Key('echo-box'),
        controller: _text,
        autofocus: widget.autofocus,
        onChanged: _changed,
        textInputAction: TextInputAction.search,
        decoration: InputDecoration(
          isDense: true,
          hintText: l.echoSearch,
          prefixIcon: Padding(
            padding: const EdgeInsets.all(10),
            child: RgIcon(RgIcons.search, size: 16, color: c.dim),
          ),
          prefixIconConstraints: const BoxConstraints(minWidth: 36, minHeight: 36),
          suffixIcon: q.isEmpty
              ? null
              : IconButton(
                  key: const Key('echo-clear'),
                  tooltip: l.echoClear,
                  onPressed: _clear,
                  icon: RgIcon(RgIcons.x, size: 15, color: c.dim),
                ),
          filled: true,
          fillColor: c.panel,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide(color: c.line),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide(color: c.line),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide(color: c.accent),
          ),
        ),
      ),
    );
    final Widget below;
    if (q.isEmpty && widget.child != null) {
      below = widget.child!;
    } else if (q.length < 2) {
      below = _Note(l.echoHint);
    } else if (_failed) {
      below = _Note(l.statusUnreachable);
    } else if (_hits == null) {
      below = const Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: SizedBox.square(dimension: 20, child: CircularProgressIndicator(strokeWidth: 2)),
        ),
      );
    } else if (_hits!.isEmpty) {
      below = _Note(l.echoNone);
    } else {
      below = ListView.separated(
        key: const Key('echo-results'),
        padding: const EdgeInsets.fromLTRB(12, 0, 12, 16),
        itemCount: _hits!.length,
        separatorBuilder: (_, _) => const SizedBox(height: 4),
        itemBuilder: (context, i) => _HitTile(hit: _hits![i]),
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        box,
        Expanded(child: below),
      ],
    );
  }
}

class _Note extends StatelessWidget {
  const _Note(this.text);
  final String text;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(20, 8, 20, 8),
    child: Text(text, style: TextStyle(color: RgColors.of(context).dim)),
  );
}

class _HitTile extends StatelessWidget {
  const _HitTile({required this.hit});
  final EchoHit hit;

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    final l = AppLocalizations.of(context);
    final c = RgColors.of(context);
    final agent = app.agents.where((x) => x.id == hit.agentId).firstOrNull?.name ?? '';
    final project =
        app.projects.where((p) => p.id == hit.projectId).firstOrNull?.name ??
        app.archivedProjects.where((p) => p.id == hit.projectId).firstOrNull?.name;
    final when = DateTime.tryParse(hit.at)?.toLocal();
    final small = TextStyle(fontSize: 12, color: c.dim);
    return Material(
      color: c.panel,
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        key: Key('echo-hit-${hit.sessionId}'),
        borderRadius: BorderRadius.circular(10),
        onTap: () => openEchoHit(context, hit),
        child: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: c.line),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                hit.title ?? l.untitled,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(fontWeight: FontWeight.w600, color: c.text),
              ),
              const SizedBox(height: 2),
              Row(
                children: [
                  Flexible(
                    child: Text(
                      project == null ? agent : '$project · $agent',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: small,
                    ),
                  ),
                  if (hit.archived) ...[
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 5),
                      decoration: BoxDecoration(
                        border: Border.all(color: c.line),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(l.echoArchived, style: small.copyWith(fontSize: 11)),
                    ),
                  ],
                ],
              ),
              Text(
                [
                  if (when != null) DateFormat.yMMMd(l.localeName).format(when),
                  hit.matches == 1 ? l.echoMatch : l.echoMatches('${hit.matches}'),
                ].join(' · '),
                style: small,
              ),
              for (final s in hit.snippets.where((s) => s.text.isNotEmpty))
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text.rich(
                    TextSpan(
                      children: [
                        TextSpan(
                          text: '${s.role == 'person' ? l.echoYou : agent}: ',
                          style: TextStyle(color: c.dim, fontWeight: FontWeight.w600),
                        ),
                        echoSpan(
                          s,
                          TextStyle(fontSize: 13, color: c.text, height: 1.35),
                          c.warn.withValues(alpha: 0.35),
                        ),
                      ],
                    ),
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

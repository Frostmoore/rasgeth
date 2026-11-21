// G42.17: «Search the conversations», the page's Search.tsx (`GET /api/search`): the words in
// every conversation, the agents' and the daily Chat's and the project inspectors', each hit with
// where it is, when, and the excerpt with the words marked (the text as it is, never HTML). A
// hit opens its conversation (the panel on a computer, the whole screen on a phone), its chat or
// the project's inspector.
import 'dart:async';

import 'package:flutter/material.dart';

import '../api/client.dart';
import '../api/groups.dart' show ChatSummary;
import '../app_state.dart';
import '../desktop/desk_controller.dart';
import '../l10n/app_localizations.dart';
import '../theme/colors.dart';
import '../ui/icons.dart';
import 'conversation_screen.dart';
import 'daily_chat_screen.dart';
import 'project_board_screen.dart' show localWhen;

/// One hit of `GET /api/search` (the page's `SearchHit`).
class TextHit {
  const TextHit({
    required this.kind,
    required this.id,
    this.agentId,
    this.projectId,
    this.title,
    required this.at,
    required this.excerpt,
  });

  factory TextHit.fromJson(Map<String, dynamic> j) => TextHit(
    kind: '${j['kind'] ?? 'session'}',
    id: '${j['id'] ?? ''}',
    agentId: j['agentId'] as String?,
    projectId: j['projectId'] as String?,
    title: j['title'] as String?,
    at: '${j['at'] ?? ''}',
    excerpt: '${j['excerpt'] ?? ''}',
  );

  /// session, chat or inspector.
  final String kind;
  final String id;
  final String? agentId;
  final String? projectId;
  final String? title;
  final String at;
  final String excerpt;
}

extension TextSearchApi on RedGiantClient {
  Future<List<TextHit>> searchText(String q) async {
    final j = await getJson('/api/search', {'q': q});
    return [
      for (final x in j is List ? j : const [])
        if (x is Map<String, dynamic>) TextHit.fromJson(x),
    ];
  }
}

/// The excerpt with the first place of [q] marked, as the page's `Marked`.
TextSpan markedExcerpt(String text, String q, TextStyle base, Color mark) {
  final i = q.isEmpty ? -1 : text.toLowerCase().indexOf(q.toLowerCase());
  if (i < 0) return TextSpan(text: text, style: base);
  return TextSpan(
    style: base,
    children: [
      TextSpan(text: text.substring(0, i)),
      TextSpan(
        text: text.substring(i, i + q.length),
        style: TextStyle(backgroundColor: mark, fontWeight: FontWeight.w700),
      ),
      TextSpan(text: text.substring(i + q.length)),
    ],
  );
}

Future<void> openFullSearch(BuildContext context) => Navigator.of(
  context,
).push(MaterialPageRoute<void>(builder: (_) => const FullSearchScreen()));

class FullSearchScreen extends StatefulWidget {
  const FullSearchScreen({super.key});

  @override
  State<FullSearchScreen> createState() => _FullSearchScreenState();
}

class _FullSearchScreenState extends State<FullSearchScreen> {
  final _q = TextEditingController();
  List<TextHit>? _hits;
  String _searched = '';
  String? _error;
  bool _busy = false;

  @override
  void dispose() {
    _q.dispose();
    super.dispose();
  }

  Future<void> _run() async {
    final q = _q.text.trim();
    final c = AppScope.read(context).client;
    if (q.length < 2 || c == null) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final hits = await c.searchText(q);
      if (mounted) {
        setState(() {
          _hits = hits;
          _searched = q;
        });
      }
    } on ApiException catch (e) {
      if (mounted) setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  String _where(AppLocalizations l, AppController app, TextHit h) {
    final project = app.projects.where((p) => p.id == h.projectId).firstOrNull?.name;
    if (h.kind == 'chat') return l.tabChat;
    if (h.kind == 'inspector') return '${l.fsrInspector} · ${project ?? ''}';
    final agent = app.agents.where((a) => a.id == h.agentId).firstOrNull?.name ?? '';
    return project != null ? '$project · $agent' : agent;
  }

  Future<void> _open(TextHit h) async {
    final app = AppScope.read(context);
    final nav = Navigator.of(context);
    if (h.kind == 'session') {
      final a = app.agents.where((x) => x.id == h.agentId).firstOrNull;
      final desk = DeskScope.maybeRead(context);
      if (desk != null) {
        desk.show(PanelConversation(h.id, agent: a));
        nav.pop();
        return;
      }
      await nav.push(
        MaterialPageRoute<void>(
          builder: (_) => ConversationScreen(sessionId: h.id, agent: a),
        ),
      );
    } else if (h.kind == 'chat') {
      await openDailyChat(
        context,
        chat: ChatSummary(id: h.id, title: h.title ?? '', createdAt: h.at, updatedAt: h.at),
      );
    } else if (h.projectId != null) {
      final name = app.projects.where((p) => p.id == h.projectId).firstOrNull?.name;
      await openDailyChat(context, projectId: h.projectId, projectName: name);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final c = RgColors.of(context);
    final app = AppScope.of(context);
    final hits = _hits;
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          key: const Key('fsr-back'),
          tooltip: l.back,
          onPressed: () => Navigator.of(context).pop(),
          icon: RgIcon(RgIcons.arrowLeft, color: c.text),
        ),
        title: Text(l.fsrTitle),
      ),
      body: Align(
        alignment: Alignment.topCenter,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 760),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                child: Row(
                  spacing: 8,
                  children: [
                    Expanded(
                      child: TextField(
                        key: const Key('fsr-field'),
                        controller: _q,
                        autofocus: true,
                        textInputAction: TextInputAction.search,
                        onChanged: (_) => setState(() {}),
                        onSubmitted: (_) => unawaited(_run()),
                        decoration: InputDecoration(
                          hintText: l.fsrTitle,
                          prefixIcon: Padding(
                            padding: const EdgeInsets.all(12),
                            child: RgIcon(RgIcons.search, size: 18, color: c.dim),
                          ),
                        ),
                      ),
                    ),
                    FilledButton(
                      key: const Key('fsr-go'),
                      onPressed: _busy || _q.text.trim().length < 2 ? null : () => unawaited(_run()),
                      child: Text(l.fsrGo),
                    ),
                  ],
                ),
              ),
              if (_error != null)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Text(_error!, style: TextStyle(color: c.err)),
                ),
              if (_busy) const LinearProgressIndicator(minHeight: 2),
              Expanded(
                child: hits == null
                    ? Padding(
                        padding: const EdgeInsets.all(16),
                        child: Text(l.fsrHint, style: TextStyle(color: c.dim)),
                      )
                    : hits.isEmpty
                    ? Padding(
                        key: const Key('fsr-none'),
                        padding: const EdgeInsets.all(16),
                        child: Text(l.fsrNone, style: TextStyle(color: c.dim)),
                      )
                    : ListView.separated(
                        key: const Key('fsr-hits'),
                        padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
                        itemCount: hits.length,
                        separatorBuilder: (_, _) => const SizedBox(height: 8),
                        itemBuilder: (context, i) {
                          final h = hits[i];
                          return Material(
                            color: c.panel,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                              side: BorderSide(color: c.line),
                            ),
                            child: InkWell(
                              key: Key('fsr-hit-$i'),
                              borderRadius: BorderRadius.circular(12),
                              onTap: () => unawaited(_open(h)),
                              child: Padding(
                                padding: const EdgeInsets.all(12),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  spacing: 4,
                                  children: [
                                    Row(
                                      spacing: 8,
                                      children: [
                                        Expanded(
                                          child: Text(
                                            h.title?.isNotEmpty ?? false ? h.title! : l.fsrUntitled,
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: TextStyle(
                                              color: c.text,
                                              fontWeight: FontWeight.w700,
                                            ),
                                          ),
                                        ),
                                        Text(
                                          localWhen(h.at, Localizations.localeOf(context).toLanguageTag()),
                                          style: TextStyle(color: c.dim, fontSize: 12),
                                        ),
                                      ],
                                    ),
                                    Text(
                                      _where(l, app, h),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(color: c.dim, fontSize: 12.5),
                                    ),
                                    Text.rich(
                                      markedExcerpt(
                                        h.excerpt,
                                        _searched,
                                        TextStyle(color: c.text, fontSize: 13.5, height: 1.35),
                                        c.accentSoft,
                                      ),
                                      maxLines: 4,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

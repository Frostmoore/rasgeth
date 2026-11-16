// Git on computers (G40.17, board C advanced 4): branches, remotes and tags on the left; the
// commits of every branch as a graph in the middle; on the right the push waiting in «For you»
// (answered here as there: the same card) and the chosen commit with its files. The graph's
// lanes are pure ([layoutGraph]) and tested.
import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../api/client.dart';
import '../../api/code.dart';
import '../../api/conversation.dart';
import '../../app_state.dart';
import '../../l10n/app_localizations.dart';
import '../../mascot/mascot_view.dart';
import '../../screens/inbox_screen.dart';
import '../../theme/colors.dart';
import '../../ui/common.dart';
import '../../ui/highlight.dart';
import '../../ui/icons.dart';
import '../desk_controller.dart';
import 'common.dart';
import 'projects_wall.dart' show ageOf;

/// One row of the graph: the commit's lane, the lanes that go through, where lines meet.
class GraphRow {
  const GraphRow({
    required this.col,
    required this.through,
    required this.fromTop,
    required this.toBottom,
    required this.mergesIn,
    required this.branchesOut,
    required this.width,
  });

  /// The commit's lane.
  final int col;

  /// Lanes that pass by this row without touching the commit.
  final List<int> through;

  /// A child above reaches this commit in its own lane.
  final bool fromTop;

  /// Its first parent continues below in the same lane.
  final bool toBottom;

  /// Other lanes whose line ends in this commit (children on other branches).
  final List<int> mergesIn;

  /// Lanes the commit's other parents continue in (a merge's).
  final List<int> branchesOut;

  /// Lanes in use in this row.
  final int width;

  @override
  String toString() =>
      'GraphRow(col: $col, through: $through, top: $fromTop, bottom: $toBottom, in: $mergesIn, out: $branchesOut)';
}

/// The lanes of [commits] (newest first, children before parents, as `git log --date-order`).
List<GraphRow> layoutGraph(List<GitCommit> commits) {
  final lanes = <String?>[];
  int free() {
    final i = lanes.indexOf(null);
    if (i >= 0) return i;
    lanes.add(null);
    return lanes.length - 1;
  }

  final rows = <GraphRow>[];
  for (final c in commits) {
    var col = lanes.indexOf(c.hash);
    final fromTop = col >= 0;
    if (!fromTop) col = free();
    final mergesIn = <int>[];
    for (var i = 0; i < lanes.length; i++) {
      if (i != col && lanes[i] == c.hash) {
        mergesIn.add(i);
        lanes[i] = null;
      }
    }
    final before = [
      for (var i = 0; i < lanes.length; i++)
        if (i != col && lanes[i] != null) i,
    ];
    // Parents not in the list (older than the page) are drawn as going on below.
    final parents = c.parents;
    lanes[col] = parents.isEmpty ? null : parents.first;
    final out = <int>[];
    for (final p in parents.skip(1)) {
      var at = lanes.indexOf(p);
      if (at < 0) {
        at = free();
        lanes[at] = p;
      }
      if (at != col) out.add(at);
    }
    while (lanes.isNotEmpty && lanes.last == null) {
      lanes.removeLast();
    }
    rows.add(
      GraphRow(
        col: col,
        through: before,
        fromTop: fromTop,
        toBottom: parents.isNotEmpty,
        mergesIn: mergesIn,
        branchesOut: out,
        width: math.max(lanes.length, [col, ...before, ...mergesIn, ...out].fold(0, math.max) + 1),
      ),
    );
  }
  return rows;
}

/// The refs git prints (`HEAD -> p2.4.0, github/p2.4.0, tag: v2.3.2`), as names.
List<String> refNames(String refs) => [
  for (final r in refs.split(','))
    if (r.trim().isNotEmpty) r.trim().replaceFirst('HEAD -> ', ''),
];

const _laneColors = [
  Color(0xFFE5484D),
  Color(0xFF8E4EC6),
  Color(0xFF12A594),
  Color(0xFFF76B15),
  Color(0xFF3E63DD),
  Color(0xFFD6409F),
];

class _GraphPainter extends CustomPainter {
  _GraphPainter(this.row, this.dot, this.bg);

  final GraphRow row;
  final Color dot;
  final Color bg;
  static const lane = 16.0;

  double x(int i) => 10 + i * lane;

  @override
  void paint(Canvas canvas, Size size) {
    final h = size.height;
    final mid = h / 2;
    Paint p(int i) => Paint()
      ..color = _laneColors[i % _laneColors.length]
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;
    for (final i in row.through) {
      canvas.drawLine(Offset(x(i), 0), Offset(x(i), h), p(i));
    }
    if (row.fromTop) canvas.drawLine(Offset(x(row.col), 0), Offset(x(row.col), mid), p(row.col));
    if (row.toBottom) {
      canvas.drawLine(Offset(x(row.col), mid), Offset(x(row.col), h), p(row.col));
    }
    for (final i in row.mergesIn) {
      final path = Path()
        ..moveTo(x(i), 0)
        ..cubicTo(x(i), mid * .8, x(row.col), mid * .4, x(row.col), mid);
      canvas.drawPath(path, p(i));
    }
    for (final i in row.branchesOut) {
      final path = Path()
        ..moveTo(x(row.col), mid)
        ..cubicTo(x(row.col), mid + mid * .6, x(i), mid + mid * .2, x(i), h);
      canvas.drawPath(path, p(i));
    }
    canvas.drawCircle(Offset(x(row.col), mid), 5.5, Paint()..color = bg);
    canvas.drawCircle(
      Offset(x(row.col), mid),
      5.5,
      Paint()
        ..color = _laneColors[row.col % _laneColors.length]
        ..strokeWidth = 2.2
        ..style = PaintingStyle.stroke,
    );
  }

  @override
  bool shouldRepaint(_GraphPainter old) => old.row != row || old.bg != bg;
}

/// The push of [project] waiting for the person, if any.
PermissionRequest? pendingPush(AppController app, Project project) => app.live.approvals.where((r) {
  final i = r.input;
  if (i is! Map) return false;
  final cmd = i['command'];
  return cmd is String && cmd.startsWith('git push') && i['project'] == project.name;
}).firstOrNull;

class GitView extends StatefulWidget {
  const GitView({super.key});

  @override
  State<GitView> createState() => _GitViewState();
}

class _GitViewState extends State<GitView> {
  String? _for;
  List<GitCommit>? _commits;
  List<GitBranch> _branches = const [];
  GitState? _git;
  GitCommit? _sel;
  DiffView? _selDiff;
  Object? _error;
  String _q = '';

  Future<void> _load(String pid) async {
    final c = AppScope.read(context).client;
    if (c == null) return;
    try {
      final git = await c.gitState(pid);
      final commits = git.repo ? await c.gitLog(pid, limit: 150, all: true) : <GitCommit>[];
      final branches = git.repo ? await c.gitBranches(pid) : <GitBranch>[];
      if (!mounted || _for != pid) return;
      setState(() {
        _git = git;
        _commits = commits;
        _branches = branches;
        _error = null;
        _sel ??= commits.firstOrNull;
      });
      if (_sel != null) unawaited(_choose(_sel!));
    } on ApiException catch (e) {
      if (mounted) setState(() => _error = e);
    }
  }

  Future<void> _choose(GitCommit commit) async {
    setState(() {
      _sel = commit;
      _selDiff = null;
    });
    final pid = _for;
    final c = AppScope.read(context).client;
    if (pid == null || c == null) return;
    try {
      final d = await c.gitDiff(pid, DiffSource.commit(commit.short, label: commit.subject));
      if (mounted && _sel == commit) setState(() => _selDiff = d);
    } on ApiException {
      // The files stay unknown.
    }
  }

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    final desk = DeskScope.of(context);
    final l = AppLocalizations.of(context);
    final c = RgColors.of(context);
    final p = deskProject(app, desk);
    if (p == null) return const NoProject();
    if (_for != p.id) {
      _for = p.id;
      _commits = null;
      _sel = null;
      _selDiff = null;
      unawaited(_load(p.id));
    }
    final commits = _commits;
    final shown = commits == null
        ? null
        : _q.isEmpty
        ? commits
        : commits
              .where(
                (x) =>
                    x.subject.toLowerCase().contains(_q.toLowerCase()) ||
                    x.short.startsWith(_q) ||
                    x.author.toLowerCase().contains(_q.toLowerCase()),
              )
              .toList();
    final rows = shown == null || _q.isNotEmpty ? null : layoutGraph(shown);
    final mono = TextStyle(
      fontFamily: monoFamily,
      fontFamilyFallback: monoFallback,
      fontSize: 12,
      color: c.dim,
    );
    final tags = <String>{
      for (final x in commits ?? const <GitCommit>[])
        for (final r in refNames(x.refs))
          if (r.startsWith('tag: ')) r.substring(5),
    };
    final remotes = <String>{
      for (final b in _branches)
        if (b.upstream != null) b.upstream!,
    };
    final push = pendingPush(app, p);
    final left = ListView(
      children: [
        const Padding(padding: EdgeInsets.fromLTRB(8, 8, 8, 0), child: ProjectPicker()),
        SideHead(l.codeBranches),
        for (final b in _branches)
          _SideRow(
            icon: RgIcons.gitBranch,
            text: b.name,
            strong: b.current,
            trailing: b.ahead > 0 ? l.deskToSend(b.ahead) : null,
          ),
        if (remotes.isNotEmpty) ...[
          SideHead(l.deskRemotes),
          for (final r in remotes) _SideRow(icon: RgIcons.globe, text: r),
        ],
        if (tags.isNotEmpty) ...[
          SideHead(l.deskTags),
          for (final t in tags) _SideRow(icon: RgIcons.bookmark, text: t),
        ],
      ],
    );
    final toolbar = Padding(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 8),
      child: Row(
        children: [
          Flexible(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  if (_git?.branch != null)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
                      decoration: BoxDecoration(
                        color: c.panel2,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: c.line),
                      ),
                      child: Row(
                        children: [
                          RgIcon(RgIcons.gitBranch, size: 14, color: c.text),
                          const SizedBox(width: 6),
                          Text(
                            _git!.branch!,
                            style: mono.copyWith(color: c.text, fontWeight: FontWeight.w700),
                          ),
                        ],
                      ),
                    ),
                  const SizedBox(width: 8),
                  OutlinedButton.icon(
                    key: const Key('git-reload'),
                    onPressed: () => _load(p.id),
                    icon: RgIcon(RgIcons.refresh, size: 15, color: c.text),
                    label: Text(l.codeReload),
                  ),
                  const SizedBox(width: 8),
                  OutlinedButton.icon(
                    key: const Key('git-commit'),
                    onPressed: p.archived
                        ? null
                        : () => commitInProject(context, app, p.id).then((_) => _load(p.id)),
                    icon: RgIcon(RgIcons.gitCommit, size: 15, color: c.text),
                    label: Text(l.deskGitCommit),
                  ),
                  const SizedBox(width: 8),
                  FilledButton.icon(
                    key: const Key('git-push'),
                    onPressed: p.archived || push != null
                        ? null
                        : () => pushProject(context, app, p.id),
                    icon: const RgIcon(RgIcons.upload, size: 15, color: Colors.white),
                    label: Text(l.deskGitPush),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 12),
          SizedBox(
            width: 220,
            height: 34,
            child: TextField(
              key: const Key('git-search'),
              onChanged: (v) => setState(() => _q = v.trim()),
              style: const TextStyle(fontSize: 13),
              decoration: InputDecoration(
                isDense: true,
                prefixIcon: Padding(
                  padding: const EdgeInsets.all(8),
                  child: RgIcon(RgIcons.search, size: 15, color: c.dim),
                ),
                prefixIconConstraints: const BoxConstraints(minWidth: 30),
                hintText: l.deskSearchCommits,
              ),
            ),
          ),
        ],
      ),
    );
    Widget center;
    if (shown == null) {
      center = _error == null
          ? const Center(child: CircularProgressIndicator())
          : EmptyState(icon: RgIcons.alert, text: l.codeLoadFailed);
    } else if (_git?.repo == false) {
      center = EmptyState(icon: RgIcons.gitBranch, text: l.codeNoRepo);
    } else {
      final graphW = rows == null
          ? 0.0
          : 20 + rows.fold(1, (m, r) => math.max(m, r.width)) * _GraphPainter.lane;
      center = ListView.builder(
        key: const Key('git-graph'),
        itemCount: shown.length,
        itemExtent: 34,
        itemBuilder: (context, i) {
          final x = shown[i];
          final sel = _sel?.hash == x.hash;
          final agent = app.agents.where((a) => a.name == x.author).firstOrNull;
          return Material(
            color: sel ? c.accentSoft : Colors.transparent,
            child: InkWell(
              key: Key('commit-${x.short}'),
              onTap: () => _choose(x),
              child: Row(
                children: [
                  if (rows != null)
                    SizedBox(
                      width: graphW,
                      height: 34,
                      child: CustomPaint(painter: _GraphPainter(rows[i], c.accent, c.bg)),
                    )
                  else
                    const SizedBox(width: 12),
                  if (x.refs.isNotEmpty)
                    ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 260),
                      child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        physics: const NeverScrollableScrollPhysics(),
                        child: Row(
                          children: [
                            for (final r in refNames(x.refs).take(4))
                              Padding(
                                padding: const EdgeInsets.only(right: 5),
                                child: _RefPill(name: r),
                              ),
                          ],
                        ),
                      ),
                    ),
                  Expanded(
                    child: Text(
                      x.subject,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(fontSize: 13, color: c.text),
                    ),
                  ),
                  SizedBox(
                    width: 150,
                    child: Row(
                      children: [
                        if (agent != null)
                          MascotView(
                            agentId: agent.id,
                            spec: agent.mascot,
                            size: 18,
                            label: agent.name,
                          )
                        else
                          RgIcon(RgIcons.user, size: 14, color: c.dim),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            x.author,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(fontSize: 12.5, color: c.dim),
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(width: 74, child: Text(x.short, style: mono)),
                  SizedBox(
                    width: 64,
                    child: Text(
                      ageOf(l, x.date),
                      textAlign: TextAlign.right,
                      style: TextStyle(fontSize: 12, color: c.dim),
                    ),
                  ),
                  const SizedBox(width: 12),
                ],
              ),
            ),
          );
        },
      );
    }
    final sel = _sel;
    final right = ListView(
      padding: const EdgeInsets.all(12),
      children: [
        if (push != null) ...[
          Text(
            l.deskForYouPush.toUpperCase(),
            style: TextStyle(
              fontSize: 11.5,
              letterSpacing: .6,
              fontWeight: FontWeight.w700,
              color: c.accent,
            ),
          ),
          const SizedBox(height: 6),
          PermissionCard(key: Key('git-push-request-${push.requestId}'), request: push),
          const SizedBox(height: 14),
        ],
        if (sel != null) ...[
          Text(
            l.deskChosenCommit.toUpperCase(),
            style: TextStyle(
              fontSize: 11.5,
              letterSpacing: .6,
              fontWeight: FontWeight.w700,
              color: c.dim,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            sel.subject,
            style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: c.text),
          ),
          const SizedBox(height: 2),
          Text('${sel.short} · ${sel.author} · ${ageOf(l, sel.date)}', style: mono),
          const SizedBox(height: 10),
          if (_selDiff == null)
            const LinearProgressIndicator(minHeight: 2)
          else ...[
            Text(
              '${l.deskFiles.toUpperCase()} · ${_selDiff!.files.length}',
              style: TextStyle(fontSize: 11.5, letterSpacing: .6, color: c.dim),
            ),
            const SizedBox(height: 4),
            for (final f in _selDiff!.files)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 2),
                child: Row(
                  children: [
                    SizedBox(
                      width: 16,
                      child: Text(
                        f.isNew ? 'A' : (f.isDeleted ? 'D' : 'M'),
                        style: mono.copyWith(
                          color: f.isNew ? c.ok : (f.isDeleted ? c.err : c.warnText),
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    Expanded(
                      child: Text(
                        f.path,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: mono.copyWith(color: c.text),
                      ),
                    ),
                    if (f.added > 0) Text('+${f.added} ', style: mono.copyWith(color: c.ok)),
                    if (f.removed > 0) Text('−${f.removed}', style: mono.copyWith(color: c.err)),
                  ],
                ),
              ),
          ],
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              OutlinedButton.icon(
                key: const Key('git-open-diff'),
                onPressed: () {
                  desk.openDiff(p.id, DiffSource.commit(sel.short, label: sel.subject));
                },
                icon: RgIcon(RgIcons.code, size: 15, color: c.text),
                label: Text(l.codeTabDiff),
              ),
              if (app.agents.any((a) => a.name == sel.author))
                OutlinedButton.icon(
                  key: const Key('git-ask-author'),
                  onPressed: () {
                    final a = app.agents.firstWhere((a) => a.name == sel.author);
                    unawaited(desk.openAgent(a));
                  },
                  icon: RgIcon(RgIcons.chat, size: 15, color: c.text),
                  label: Text(l.deskInConversation),
                ),
            ],
          ),
        ],
      ],
    );
    return Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          width: 230,
          decoration: BoxDecoration(
            border: Border(right: BorderSide(color: c.line)),
          ),
          child: left,
        ),
        Expanded(
          child: Column(
            children: [
              toolbar,
              Divider(height: 1, color: c.line),
              Expanded(child: MinWidth(min: 700, child: center)),
            ],
          ),
        ),
        Container(
          width: 360,
          decoration: BoxDecoration(
            border: Border(left: BorderSide(color: c.line)),
          ),
          child: right,
        ),
      ],
    );
  }
}

class _SideRow extends StatelessWidget {
  const _SideRow({required this.icon, required this.text, this.strong = false, this.trailing});

  final RgIcons icon;
  final String text;
  final bool strong;
  final String? trailing;

  @override
  Widget build(BuildContext context) {
    final c = RgColors.of(context);
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 1),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: strong ? c.panel2 : null,
        borderRadius: BorderRadius.circular(7),
      ),
      child: Row(
        children: [
          RgIcon(icon, size: 14, color: c.dim),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 13,
                color: c.text,
                fontWeight: strong ? FontWeight.w700 : FontWeight.w400,
              ),
            ),
          ),
          if (trailing != null)
            Flexible(
              child: Text(
                trailing!,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(fontSize: 12, color: c.dim),
              ),
            ),
        ],
      ),
    );
  }
}

class _RefPill extends StatelessWidget {
  const _RefPill({required this.name});

  final String name;

  @override
  Widget build(BuildContext context) {
    final c = RgColors.of(context);
    final tag = name.startsWith('tag: ');
    final remote = name.contains('/');
    final color = tag ? c.warnText : (remote ? const Color(0xFF3E63DD) : c.accent);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
      decoration: BoxDecoration(
        color: color.withValues(alpha: .12),
        borderRadius: BorderRadius.circular(5),
        border: Border.all(color: color.withValues(alpha: .5)),
      ),
      child: Text(
        tag ? name.substring(5) : name,
        style: TextStyle(
          fontSize: 11,
          color: color,
          fontFamily: monoFamily,
          fontFamilyFallback: monoFallback,
        ),
      ),
    );
  }
}

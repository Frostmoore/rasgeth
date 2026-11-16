// Git (G40.11): the branch and its changes, a commit, the push (a request to the person: it waits
// in «For you», like an agent's push), the branches and the commits (a tap opens the commit's
// diff).
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../api/client.dart';
import '../../api/code.dart';
import '../../l10n/app_localizations.dart';
import '../../theme/colors.dart';
import '../../ui/common.dart';
import '../../ui/highlight.dart';
import '../../ui/icons.dart';
import 'project_screen.dart';

class GitTab extends StatefulWidget {
  const GitTab({super.key, required this.ctx});

  final ProjectCtx ctx;

  @override
  State<GitTab> createState() => _GitTabState();
}

class _GitTabState extends State<GitTab> with AutomaticKeepAliveClientMixin {
  List<GitCommit>? _commits;
  List<GitBranch>? _branches;
  final _message = TextEditingController();
  bool _busy = false;

  /// The push waiting for the person's answer.
  JobView? _push;
  Timer? _poll;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _poll?.cancel();
    _message.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final c = widget.ctx.client;
    await widget.ctx.reloadGit();
    if (widget.ctx.git?.repo == false) return;
    try {
      final log = await c.gitLog(widget.ctx.project.id);
      final br = await c.gitBranches(widget.ctx.project.id);
      if (mounted)
        setState(() {
          _commits = log;
          _branches = br;
        });
    } on ApiException catch (e) {
      if (mounted) showApiError(context, e);
    }
  }

  Future<void> _commit() async {
    final l = AppLocalizations.of(context);
    final m = _message.text.trim();
    if (m.isEmpty) return;
    setState(() => _busy = true);
    try {
      final h = await widget.ctx.client.gitCommit(widget.ctx.project.id, m);
      _message.clear();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l.codeCommitted(h))));
      }
      await _load();
    } on ApiException catch (e) {
      if (mounted) {
        if (e.code == 'nothing') {
          ScaffoldMessenger.of(context)
              .showSnackBar(SnackBar(content: Text(l.codeNothingToCommit)));
        } else {
          showApiError(context, e);
        }
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _startPush() async {
    final l = AppLocalizations.of(context);
    setState(() => _busy = true);
    try {
      final job = await widget.ctx.client.gitPush(widget.ctx.project.id);
      if (!mounted) return;
      setState(() => _push = job);
      _poll?.cancel();
      _poll = Timer.periodic(const Duration(milliseconds: 1500), (_) => _follow());
    } on ApiException catch (e) {
      if (!mounted) return;
      if (e.code == 'no_remote') {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l.codeNoRemote)));
      } else {
        showApiError(context, e);
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _follow() async {
    final p = _push;
    if (p == null) return;
    try {
      final j = await widget.ctx.client.job(p.id);
      if (!mounted || j.running) return;
      _poll?.cancel();
      final l = AppLocalizations.of(context);
      setState(() => _push = null);
      final text = j.state == 'done'
          ? l.codePushDone
          : j.errorCode == 'denied'
          ? l.codePushDenied
          : l.codePushFailed(j.errorMessage ?? j.state);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
      await _load();
    } on ApiException {
      // Tried again at the next tick.
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final l = AppLocalizations.of(context);
    final c = RgColors.of(context);
    final g = widget.ctx.git;
    if (g == null) return const Center(child: CircularProgressIndicator());
    if (!g.repo) return EmptyState(icon: RgIcons.gitBranch, text: l.codeNoRepo);
    final ro = widget.ctx.readOnly;
    final mono = TextStyle(
      fontFamily: monoFamily,
      fontFamilyFallback: monoFallback,
      fontSize: 13,
      color: c.text,
    );
    return RefreshIndicator(
      onRefresh: _load,
      child: ListView(
        key: const Key('git-list'),
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 24),
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: c.panel,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: c.line),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    RgIcon(RgIcons.gitBranch, size: 18, color: c.accent),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        g.branch ?? l.codeDetached,
                        key: const Key('git-branch'),
                        style: TextStyle(fontWeight: FontWeight.w800, color: c.text, fontSize: 16),
                      ),
                    ),
                    AheadBehind(ahead: g.ahead, behind: g.behind),
                  ],
                ),
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(
                    g.upstream == null ? l.codeNoUpstream : l.codeUpstream(g.upstream!),
                    style: TextStyle(color: c.dim, fontSize: 12.5),
                  ),
                ),
                const SizedBox(height: 8),
                if (g.clean)
                  Text(
                    l.codeClean,
                    style: TextStyle(color: c.ok, fontWeight: FontWeight.w600),
                  )
                else
                  for (final ch in g.changes.take(30))
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 1),
                      child: Text.rich(
                        TextSpan(
                          style: mono,
                          children: [
                            TextSpan(
                              text: '${ch.status == '?' ? 'U' : ch.status} ',
                              style: TextStyle(
                                color: ch.status == 'D'
                                    ? c.err
                                    : ch.status == '?' || ch.status == 'A'
                                    ? c.ok
                                    : c.warnText,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            TextSpan(text: ch.path),
                          ],
                        ),
                      ),
                    ),
              ],
            ),
          ),
          if (!ro) ...[
            const SizedBox(height: 12),
            TextField(
              key: const Key('git-message'),
              controller: _message,
              minLines: 1,
              maxLines: 4,
              decoration: InputDecoration(isDense: true, hintText: l.codeCommitHint),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: FilledButton.icon(
                    key: const Key('git-commit'),
                    onPressed: _busy || g.clean ? null : _commit,
                    icon: const RgIcon(RgIcons.gitCommit, size: 18, color: Colors.white),
                    label: Text(l.codeCommit),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton.icon(
                    key: const Key('git-push'),
                    onPressed: _busy || _push != null ? null : _startPush,
                    icon: RgIcon(RgIcons.upload, size: 18, color: c.text),
                    label: Text(l.codePush),
                  ),
                ),
              ],
            ),
          ],
          if (_push != null)
            Container(
              key: const Key('git-push-waiting'),
              margin: const EdgeInsets.only(top: 10),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: c.accentSoft,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: c.accentDim),
              ),
              child: Row(
                children: [
                  RgIcon(RgIcons.bell, size: 18, color: c.accent),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(l.codePushAsked, style: TextStyle(color: c.text)),
                  ),
                ],
              ),
            ),
          _Head(l.codeBranches),
          for (final b in _branches ?? const <GitBranch>[])
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 3),
              child: Row(
                children: [
                  RgIcon(RgIcons.gitBranch, size: 15, color: b.current ? c.accent : c.dim),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      b.name,
                      style: mono.copyWith(fontWeight: b.current ? FontWeight.w800 : null),
                    ),
                  ),
                  if (b.upstream != null) AheadBehind(ahead: b.ahead, behind: b.behind),
                ],
              ),
            ),
          _Head(l.codeCommits),
          for (final cm in _commits ?? const <GitCommit>[])
            InkWell(
              key: Key('commit-${cm.short}'),
              onTap: () => widget.ctx.openDiff(DiffSource.commit(cm.short, label: cm.subject)),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 7),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      cm.short,
                      style: mono.copyWith(color: c.accent2, fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            cm.subject,
                            style: TextStyle(color: c.text, fontWeight: FontWeight.w600),
                          ),
                          Text(
                            '${cm.author} · ${_when(cm.date, l.localeName)}',
                            style: TextStyle(color: c.dim, fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                    RgIcon(RgIcons.chevronRight, size: 16, color: c.dim),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  String _when(String iso, String locale) {
    final d = DateTime.tryParse(iso)?.toLocal();
    return d == null ? '' : DateFormat.MMMd(locale).add_Hm().format(d);
  }
}

class _Head extends StatelessWidget {
  const _Head(this.text);

  final String text;

  @override
  Widget build(BuildContext context) => Semantics(
    header: true,
    child: Padding(
      padding: const EdgeInsets.fromLTRB(0, 20, 0, 6),
      child: Text(
        text,
        style: TextStyle(
          fontWeight: FontWeight.w800,
          color: RgColors.of(context).dim,
          fontSize: 13,
        ),
      ),
    ),
  );
}

/// Commits ahead and behind, with drawn arrows.
class AheadBehind extends StatelessWidget {
  const AheadBehind({super.key, required this.ahead, required this.behind});

  final int ahead;
  final int behind;

  @override
  Widget build(BuildContext context) {
    final c = RgColors.of(context);
    final l = AppLocalizations.of(context);
    return Semantics(
      label: l.codeAheadBehind(ahead, behind),
      excludeSemantics: true,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          RgIcon(RgIcons.arrowUp, size: 13, color: ahead > 0 ? c.accent : c.dim),
          Text(
            '$ahead',
            style: TextStyle(
              color: ahead > 0 ? c.accent : c.dim,
              fontWeight: FontWeight.w700,
              fontSize: 12.5,
            ),
          ),
          const SizedBox(width: 6),
          RgIcon(RgIcons.arrowDown, size: 13, color: behind > 0 ? c.warnText : c.dim),
          Text(
            '$behind',
            style: TextStyle(
              color: behind > 0 ? c.warnText : c.dim,
              fontWeight: FontWeight.w700,
              fontSize: 12.5,
            ),
          ),
        ],
      ),
    );
  }
}

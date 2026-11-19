// 3.9.7: Settings › Skills, native, as the page's Settings › Extensions has them (`Extensions.tsx`:
// `ProposalView`, `SkillHistory`): the agents' skills waiting for the person (a new version shows
// what changes word by word, with its reason), approved or rejected here; the installed skills,
// each with its versions (who, why, when, the one in use), compared with the one in use and brought
// back after the person confirms. Routes in `api/skills_api.dart`.
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../app_state.dart';
import '../l10n/app_localizations.dart';
import '../theme/colors.dart';
import '../ui/icons.dart';
import 'api/skills_api.dart';
import 'knowledge_kit.dart';
import 'prompt_refiner.dart' show WordDiffView;
import 'rules_kit.dart';

/// Opens the page: a panel over the window on a computer, a whole screen on a phone.
Future<void> openSkills(BuildContext context) =>
    openRulesPage(context, (panel) => SkillsScreen(panel: panel));

/// How a version came, in words (the page's `versionHow`).
String skillVersionHow(AppLocalizations l, SkillVersion v) => switch (v.how) {
  'baseline' => l.skHow_baseline,
  'edited' => l.skHow_edited,
  'update' => l.skHow_update,
  'import' => l.skHow_import,
  'rollback' => l.skHow_rollback('${v.fromVersion ?? ''}'),
  _ => l.skHow_install,
};

String _when(AppLocalizations l, String iso) {
  final d = DateTime.tryParse(iso)?.toLocal();
  if (d == null) return '';
  return DateFormat.yMMMd(l.localeName).add_Hm().format(d);
}

class SkillsScreen extends StatefulWidget {
  const SkillsScreen({super.key, this.panel = false});

  final bool panel;

  @override
  State<SkillsScreen> createState() => _SkillsScreenState();
}

class _SkillsScreenState extends State<SkillsScreen> {
  List<SkillProposal>? _waiting;
  List<InstalledSkill>? _installed;
  String? _error;
  final _busy = <String>{};
  final _comparing = <String>{};

  @override
  void initState() {
    super.initState();
    unawaited(_load());
  }

  Future<void> _load() async {
    final c = AppScope.read(context).client;
    if (c == null) return;
    try {
      final r = await Future.wait([c.waitingSkills(), c.installedSkills()]);
      if (!mounted) return;
      setState(() {
        _waiting = r[0] as List<SkillProposal>;
        _installed = r[1] as List<InstalledSkill>;
      });
    } on Exception catch (e) {
      if (mounted) setState(() => _error = rulesWhy(e));
    }
  }

  Future<void> _decide(SkillProposal p, bool approve) async {
    final c = AppScope.read(context).client;
    if (c == null) return;
    setState(() {
      _busy.add(p.id);
      _error = null;
    });
    try {
      await c.decideSkill(p.id, approve: approve);
      await _load();
    } on Exception catch (e) {
      if (mounted) setState(() => _error = rulesWhy(e));
    } finally {
      if (mounted) setState(() => _busy.remove(p.id));
    }
  }

  String _who(String? id) {
    final l = AppLocalizations.of(context);
    if (id == null) return l.skUnknown;
    if (id == 'human') return l.skYou;
    return AppScope.read(context).agents.where((a) => a.id == id).firstOrNull?.name ?? id;
  }

  Future<void> _open(InstalledSkill s) async {
    await kbWindow<void>(
      context,
      key: const Key('skill-versions-window'),
      title: s.name,
      sub: s.description,
      wide: true,
      body: (ctx, close) => SkillHistoryView(skill: s, who: _who),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final col = RgColors.of(context);
    final waiting = _waiting;
    final installed = _installed;
    return RulesPage(
      pageKey: const Key('skills-settings'),
      title: l.skSection,
      panel: widget.panel,
      question: l.skQuestion,
      lead: l.skLead,
      children: [
        if (waiting == null || installed == null) RulesLoading(error: _error),
        if (waiting != null && installed != null) ...[
          if (_error != null) KbLine(_error!, error: true, key: const Key('skills-error')),
          RulesSub(title: l.skWaitingTitle, lead: l.skWaitingLead),
          if (waiting.isEmpty)
            KbBox(children: [KbLine(l.skNoneWaiting, dim: true)])
          else
            for (final p in waiting)
              KbBox(
                key: Key('skill-waiting-${p.id}'),
                tone: col.accent,
                children: [
                  Text(
                    p.name,
                    style: TextStyle(color: col.text, fontWeight: FontWeight.w800, fontSize: 16),
                  ),
                  Text(
                    '${p.isUpdate ? l.skUpdate : l.skNew} · ${l.skBy(_who(p.author))}',
                    style: TextStyle(color: col.dim, fontSize: 13),
                  ),
                  if (p.description.isNotEmpty) KbLine(p.description),
                  if (p.summary != null && p.updateLine == null) ...[
                    const SizedBox(height: 4),
                    Text(
                      l.skWhy,
                      style: TextStyle(color: col.text, fontWeight: FontWeight.w700, fontSize: 13),
                    ),
                    KbLine(p.summary!),
                  ],
                  if (p.isUpdate && p.updateLine != null) ...[
                    Container(
                      key: Key('skill-line-${p.id}'),
                      margin: const EdgeInsets.only(top: 8),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: col.bg,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: col.accent),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            l.skLineTitle,
                            style: TextStyle(
                              color: col.dim,
                              fontWeight: FontWeight.w700,
                              fontSize: 12.5,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(p.updateLine!, style: TextStyle(color: col.text, fontSize: 15)),
                        ],
                      ),
                    ),
                  ],
                  if (p.isUpdate && p.proposedSkillMd != null) ...[
                    const SizedBox(height: 8),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: OutlinedButton(
                        key: Key('skill-compare-${p.id}'),
                        onPressed: () => setState(
                          () => _comparing.contains(p.id)
                              ? _comparing.remove(p.id)
                              : _comparing.add(p.id),
                        ),
                        child: Text(_comparing.contains(p.id) ? l.skHideCompare : l.skCompareFull),
                      ),
                    ),
                    if (_comparing.contains(p.id)) ...[
                      const SizedBox(height: 6),
                      KeyedSubtree(
                        key: Key('skill-diff-${p.id}'),
                        child: WordDiffView(before: p.previousSkillMd!, after: p.proposedSkillMd!),
                      ),
                    ],
                  ] else if (p.body.isNotEmpty)
                    Container(
                      margin: const EdgeInsets.only(top: 6),
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: col.bg,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: col.line),
                      ),
                      child: SelectableText(
                        p.body,
                        style: TextStyle(color: col.text, fontSize: 13.5, height: 1.45),
                      ),
                    ),
                  if (p.passed) KbLine(l.skTestsOk, dim: true),
                  if (p.scripts.isNotEmpty) KbLine(l.skScripts(p.scripts.join(', ')), dim: true),
                  KbLine(l.skNextSession, dim: true),
                  KbActs(
                    children: [
                      OutlinedButton(
                        key: Key('skill-reject-${p.id}'),
                        onPressed: _busy.contains(p.id) ? null : () => _decide(p, false),
                        child: Text(l.skReject),
                      ),
                      FilledButton(
                        key: Key('skill-approve-${p.id}'),
                        onPressed: _busy.contains(p.id) ? null : () => _decide(p, true),
                        child: Text(l.skApprove),
                      ),
                    ],
                  ),
                ],
              ),
          RulesSub(title: l.skInstalledTitle, lead: l.skInstalledLead),
          KbBox(
            children: [
              if (installed.isEmpty) KbLine(l.skNoneInstalled, dim: true),
              for (final s in installed)
                Material(
                  type: MaterialType.transparency,
                  child: ListTile(
                    key: Key('skill-installed-${s.name}'),
                    contentPadding: EdgeInsets.zero,
                    leading: RgIcon(RgIcons.spark, color: col.accent),
                    title: Text(s.name),
                    subtitle: Text(
                      '${s.description}\n${s.scope == 'platform' ? l.skEverywhere : l.skProject(s.scope.replaceFirst('project:', ''))}',
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                    ),
                    trailing: RgIcon(RgIcons.chevronRight, color: col.dim),
                    onTap: () => _open(s),
                  ),
                ),
            ],
          ),
        ],
      ],
    );
  }
}

/// A skill's versions, newest first: who, why, when, the one in use; an earlier one compared
/// with it and brought back once the person confirms.
class SkillHistoryView extends StatefulWidget {
  const SkillHistoryView({super.key, required this.skill, required this.who});

  final InstalledSkill skill;
  final String Function(String? id) who;

  @override
  State<SkillHistoryView> createState() => _SkillHistoryViewState();
}

class _SkillHistoryViewState extends State<SkillHistoryView> {
  List<SkillVersion>? _list;
  String? _error;
  String? _done;
  ({int version, String before, String after})? _compare;

  @override
  void initState() {
    super.initState();
    unawaited(_load());
  }

  Future<void> _load() async {
    final c = AppScope.read(context).client;
    if (c == null) return;
    try {
      final v = await c.skillVersions(widget.skill.name, widget.skill.scope);
      if (mounted) setState(() => _list = v);
    } on Exception catch (e) {
      if (mounted) setState(() => _error = rulesWhy(e));
    }
  }

  Future<void> _toggleCompare(SkillVersion v) async {
    final c = AppScope.read(context).client;
    final cur = _list?.where((x) => x.current).firstOrNull;
    if (c == null || cur == null) return;
    if (_compare?.version == v.version) return setState(() => _compare = null);
    try {
      final r = await Future.wait([
        c.skillVersionText(widget.skill.name, widget.skill.scope, v.version),
        c.skillVersionText(widget.skill.name, widget.skill.scope, cur.version),
      ]);
      if (mounted) setState(() => _compare = (version: v.version, before: r[0], after: r[1]));
    } on Exception catch (e) {
      if (mounted) setState(() => _error = rulesWhy(e));
    }
  }

  Future<void> _rollback(SkillVersion v) async {
    final l = AppLocalizations.of(context);
    final c = AppScope.read(context).client;
    final yes = await kbWindow<bool>(
      context,
      key: const Key('skill-rollback-window'),
      title: l.skRollbackTitle('${v.version}'),
      body: (ctx, close) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          KbLine(l.skRollbackText(widget.skill.name), dim: true),
          KbActs(
            children: [
              OutlinedButton(onPressed: () => close(false), child: Text(l.cancel)),
              FilledButton(
                key: const Key('skill-rollback-yes'),
                onPressed: () => close(true),
                child: Text(l.skRollback('${v.version}')),
              ),
            ],
          ),
        ],
      ),
    );
    if (yes != true || c == null || !mounted) return;
    try {
      final now = await c.rollbackSkill(widget.skill.name, widget.skill.scope, v.version);
      if (!mounted) return;
      setState(() {
        _compare = null;
        _done = l.skRolledBack('${v.version}', '$now');
      });
      await _load();
    } on Exception catch (e) {
      if (mounted) setState(() => _error = rulesWhy(e));
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final col = RgColors.of(context);
    final list = _list;
    return Column(
      key: const Key('skill-history'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          l.skVersionsTitle,
          style: TextStyle(color: col.text, fontWeight: FontWeight.w800, fontSize: 15),
        ),
        KbLine(l.skVersionsLead, dim: true),
        if (_done != null) KbLine(_done!, key: const Key('skill-rolled-back')),
        if (_error != null) KbLine(_error!, error: true),
        if (list == null && _error == null)
          const Padding(padding: EdgeInsets.all(12), child: LinearProgressIndicator()),
        if (list != null && list.isEmpty) KbLine(l.skNoVersions, dim: true),
        for (final v in list ?? const <SkillVersion>[])
          Container(
            key: Key('skill-version-${v.version}'),
            margin: const EdgeInsets.only(top: 8),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: v.current ? col.accent.withValues(alpha: .08) : col.panel,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: v.current ? col.accent : col.line),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Wrap(
                  spacing: 8,
                  runSpacing: 4,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    Text(
                      l.skVersion('${v.version}'),
                      style: TextStyle(color: col.text, fontWeight: FontWeight.w800),
                    ),
                    if (v.current)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 1),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(999),
                          border: Border.all(color: col.accent),
                        ),
                        child: Text(
                          l.skCurrent,
                          style: TextStyle(
                            color: col.accent,
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    Text(skillVersionHow(l, v), style: TextStyle(color: col.dim)),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  [
                    v.author == null ? l.skUnknown : l.skBy(widget.who(v.author)),
                    if (v.approvedBy == 'human' && v.author != 'human') l.skApprovedYou,
                    if (v.approvedBy == 'auto') l.skApprovedAuto,
                    _when(l, v.createdAt),
                  ].join(' · '),
                  style: TextStyle(color: col.dim, fontSize: 13),
                ),
                if (v.reason != null) ...[
                  const SizedBox(height: 4),
                  Text.rich(
                    TextSpan(
                      children: [
                        TextSpan(
                          text: '${l.skWhy}: ',
                          style: const TextStyle(fontWeight: FontWeight.w700),
                        ),
                        TextSpan(text: v.reason),
                      ],
                    ),
                    style: TextStyle(color: col.text, fontSize: 13.5, height: 1.4),
                  ),
                ],
                if (!v.current)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        OutlinedButton(
                          key: Key('skill-compare-${v.version}'),
                          onPressed: () => _toggleCompare(v),
                          child: Text(
                            _compare?.version == v.version ? l.skHideCompare : l.skCompare,
                          ),
                        ),
                        if (v.restorable)
                          FilledButton.tonal(
                            key: Key('skill-rollback-${v.version}'),
                            onPressed: () => _rollback(v),
                            child: Text(l.skRollback('${v.version}')),
                          )
                        else
                          Text(l.skNotRestorable, style: TextStyle(color: col.dim, fontSize: 13)),
                      ],
                    ),
                  ),
                if (_compare case final cmp? when cmp.version == v.version)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: WordDiffView(before: cmp.before, after: cmp.after),
                  ),
              ],
            ),
          ),
      ],
    );
  }
}

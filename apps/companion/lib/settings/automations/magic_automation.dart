// G42.9: magic automations, native, as the page's MagicAutomation.tsx (G33.3): the person writes
// what they want, a conversation with God starts and builds it. The conversation is a real one
// (the app's own conversation screen, embedded), with God's proposal beside it on a computer and
// above it on a phone, as a preview in words: approve it, change it in the editor first, or say
// what is wrong. Nothing becomes an automation before the person's yes. While something is
// missing (a chat linked, a key added) the proposal is read again now and then, so what the
// person makes elsewhere lights up here by itself.
import 'dart:async';

import 'package:flutter/material.dart';

import '../../api/client.dart';
import '../../app_state.dart';
import '../../l10n/app_localizations.dart';
import '../../screens/conversation_screen.dart';
import '../../theme/colors.dart';
import '../../ui/icons.dart';
import '../api/automations_api.dart';
import 'automation_draft.dart';
import 'automation_editor.dart';
import 'automation_kit.dart';
import 'automation_types.dart';

/// Where a magic automation stands, in words.
String magicStateLabel(AppLocalizations l, String status) => switch (status) {
  'building' => l.auAxMagicState_building,
  'ready' => l.auAxMagicState_ready,
  'done' => l.auAxMagicState_done,
  _ => l.auAxMagicState_dismissed,
};

/// The window where the person says what the automation should do; the magic one started.
Future<MagicAutomation?> openMagicStart(BuildContext context) {
  final l = AppLocalizations.of(context);
  return openAutoWindow<MagicAutomation>(
    context,
    title: l.auAxMagic,
    icon: const GodOrb(size: 32),
    key: const Key('au-magic-start'),
    child: (ctx, close) => _MagicStart(onStarted: close),
  );
}

class _MagicStart extends StatefulWidget {
  const _MagicStart({required this.onStarted});

  final void Function([MagicAutomation?]) onStarted;

  @override
  State<_MagicStart> createState() => _MagicStartState();
}

class _MagicStartState extends State<_MagicStart> {
  String _text = '';
  bool _busy = false;
  String? _error;

  Future<void> _go() async {
    final c = AppScope.read(context).client;
    if (c == null) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      widget.onStarted(await c.startMagic(_text.trim()));
    } on ApiException catch (e) {
      if (mounted) {
        setState(() {
          _busy = false;
          _error = AppLocalizations.of(context).errGeneric(e.message);
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final c = RgColors.of(context);
    final god = godColor(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Text(l.auAxMagicLead, style: TextStyle(color: c.dim, height: 1.45)),
        ),
        AutoField(
          label: l.auAxMagicAsk,
          hint: l.auAxMagicPlaceholder,
          value: _text,
          lines: 5,
          fieldKey: const Key('au-magic-ask'),
          onChanged: (v) => setState(() => _text = v),
        ),
        AutoLb(l.auAxMagicExamples),
        for (final (i, ex) in [l.auAxMagicEx1, l.auAxMagicEx2, l.auAxMagicEx3].indexed)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Material(
              color: c.panel,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
                side: BorderSide(color: godLine(context)),
              ),
              child: InkWell(
                key: Key('au-magic-ex-$i'),
                borderRadius: BorderRadius.circular(14),
                onTap: () => setState(() => _text = ex),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(14, 10, 14, 10),
                  child: Text(ex, style: TextStyle(color: c.text, height: 1.4, fontSize: 13.5)),
                ),
              ),
            ),
          ),
        const SizedBox(height: 6),
        for (final p in [l.auAxMagicPromise1, l.auAxMagicPromise2, l.auAxMagicPromise3])
          Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.only(top: 2),
                  child: RgIcon(RgIcons.check, size: 15, color: god),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(p, style: TextStyle(color: c.dim, fontSize: 13, height: 1.4)),
                ),
              ],
            ),
          ),
        if (_error != null) AutoNotice(_error!, error: true, key: const Key('au-error')),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            TextButton(onPressed: () => widget.onStarted(), child: Text(l.auCancel)),
            const SizedBox(width: 8),
            FilledButton.icon(
              key: const Key('au-magic-go'),
              style: FilledButton.styleFrom(backgroundColor: god, foregroundColor: Colors.white),
              onPressed: _busy || _text.trim().isEmpty ? null : _go,
              icon: const RgIcon(RgIcons.spark, size: 17, color: Colors.white),
              label: Text(_busy ? l.auAxMagicStarting : l.auAxMagicGo),
            ),
          ],
        ),
      ],
    );
  }
}

/// A magic automation's window: God's proposal beside (on a phone above) the conversation; what
/// it became once approved, or null.
Future<AutomationSaved?> openMagicChat(
  BuildContext context,
  MagicAutomation m, {
  required VoidCallback onChange,
}) {
  final l = AppLocalizations.of(context);
  return openAutoWindow<AutomationSaved>(
    context,
    title: '${l.auAxMagic}: ${m.title}',
    sub: magicStateLabel(l, m.status),
    icon: const GodOrb(size: 32),
    wide: true,
    full: true,
    scroll: false,
    key: const Key('au-magic-chat'),
    child: (ctx, close) => MagicChat(magic: m, onChange: onChange, onDone: close),
  );
}

class MagicChat extends StatefulWidget {
  const MagicChat({super.key, required this.magic, required this.onChange, required this.onDone});

  final MagicAutomation magic;
  final VoidCallback onChange;
  final void Function([AutomationSaved?]) onDone;

  @override
  State<MagicChat> createState() => _MagicChatState();
}

class _MagicChatState extends State<MagicChat> {
  late MagicAutomation _m = widget.magic;
  Timer? _timer;
  late final ValueNotifier<int> _changed = AppScope.read(context).live.automationsChanged;

  @override
  void initState() {
    super.initState();
    _changed.addListener(_reload);
    // God works in the conversation; the proposal (or what is still missing) is read again.
    _timer = Timer.periodic(const Duration(seconds: 4), (_) {
      final missing = _m.proposal?.needs.any((n) => n.ready == false) ?? false;
      if (_m.status == 'building' || missing) unawaited(_reload());
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _changed.removeListener(_reload);
    super.dispose();
  }

  Future<void> _reload() async {
    final c = AppScope.read(context).client;
    if (c == null) return;
    try {
      final m = await c.magicAutomation(_m.id);
      if (mounted) setState(() => _m = m);
    } on ApiException {
      // Read again at the next tick.
    }
  }

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    final agent = app.agents.where((a) => a.id == _m.agentId).firstOrNull;
    final side = _Side(
      magic: _m,
      onReload: _reload,
      onDone: widget.onDone,
      onChange: widget.onChange,
    );
    final chat = ConversationScreen(
      key: Key('au-magic-conv-${_m.sessionId}'),
      sessionId: _m.sessionId,
      agent: agent,
      embedded: true,
    );
    final c = RgColors.of(context);
    if (isWide(context)) {
      return SizedBox(
        height: MediaQuery.sizeOf(context).height * .8,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SizedBox(
              width: 340,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  border: Border(right: BorderSide(color: c.line)),
                ),
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(20, 4, 16, 20),
                  child: side,
                ),
              ),
            ),
            Expanded(child: chat),
          ],
        ),
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ConstrainedBox(
          constraints: BoxConstraints(maxHeight: MediaQuery.sizeOf(context).height * .42),
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
            child: side,
          ),
        ),
        Divider(height: 1, color: c.line),
        Expanded(child: chat),
      ],
    );
  }
}

/// The steps, God's proposal and the choice.
class _Side extends StatelessWidget {
  const _Side({
    required this.magic,
    required this.onReload,
    required this.onDone,
    required this.onChange,
  });

  final MagicAutomation magic;
  final Future<void> Function() onReload;
  final void Function([AutomationSaved?]) onDone;
  final VoidCallback onChange;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final c = RgColors.of(context);
    final m = magic;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        MagicSteps(status: m.status),
        if (m.status == 'ready' && m.proposal != null)
          _Proposal(magic: m, onReload: onReload, onDone: onDone),
        if (m.status == 'done') AutoNotice(l.auAxMagicDone, key: const Key('au-magic-done')),
        if (m.status == 'building')
          Container(
            margin: const EdgeInsets.only(top: 10),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: c.panel2,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(l.auAxMagicBuilding, style: TextStyle(color: c.dim, height: 1.4)),
                TextButton(
                  key: const Key('au-magic-dismiss'),
                  onPressed: () async {
                    final cl = AppScope.read(context).client;
                    if (cl == null) return;
                    try {
                      await cl.dismissMagic(m.id);
                      onChange();
                      onDone();
                    } on ApiException {
                      await onReload();
                    }
                  },
                  child: Text(l.auAxMagicDismiss),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

/// Where the conversation stands, in three steps lit by border and background.
class MagicSteps extends StatelessWidget {
  const MagicSteps({super.key, required this.status});

  final String status;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final c = RgColors.of(context);
    final at = status == 'building'
        ? 2
        : status == 'ready' || status == 'testing'
        ? 3
        : 4;
    final labels = [l.auAxMagicStep1, l.auAxMagicStep2, l.auAxMagicStep3];
    return Column(
      key: const Key('au-magic-steps'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final (i, label) in labels.indexed)
          Builder(
            builder: (context) {
              final cur = i + 1 == at;
              final past = i + 1 < at;
              return Container(
                margin: const EdgeInsets.only(bottom: 6),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
                decoration: BoxDecoration(
                  color: cur ? c.accentSoft : (past ? c.panel : Colors.transparent),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: cur ? c.accent : c.line),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 22,
                      height: 22,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: cur || past ? c.accent : c.panel2,
                      ),
                      child: Center(
                        child: past
                            ? const RgIcon(RgIcons.check, size: 12, color: Colors.white)
                            : Text(
                                '${i + 1}',
                                style: TextStyle(
                                  color: cur ? Colors.white : c.dim,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        label,
                        style: TextStyle(
                          color: cur ? c.text : c.dim,
                          fontWeight: cur ? FontWeight.w700 : FontWeight.w500,
                          fontSize: 13.5,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
      ],
    );
  }
}

class _Proposal extends StatefulWidget {
  const _Proposal({required this.magic, required this.onReload, required this.onDone});

  final MagicAutomation magic;
  final Future<void> Function() onReload;
  final void Function([AutomationSaved?]) onDone;

  @override
  State<_Proposal> createState() => _ProposalState();
}

class _ProposalState extends State<_Proposal> {
  String? _why;
  String? _error;
  bool _busy = false;

  Future<void> _approve() async {
    final c = AppScope.read(context).client;
    if (c == null) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      widget.onDone(await c.approveMagic(widget.magic.id));
    } on ApiException catch (e) {
      if (mounted) {
        setState(() {
          _busy = false;
          _error = AppLocalizations.of(context).errGeneric(e.message);
        });
      }
    }
  }

  Future<void> _reject() async {
    final c = AppScope.read(context).client;
    if (c == null) return;
    try {
      final why = _why?.trim() ?? '';
      await c.rejectMagic(widget.magic.id, why.isEmpty ? null : why);
      if (mounted) setState(() => _why = null);
      await widget.onReload();
    } on ApiException catch (e) {
      if (mounted) setState(() => _error = AppLocalizations.of(context).errGeneric(e.message));
    }
  }

  Future<void> _edit() async {
    final l = AppLocalizations.of(context);
    final c = AppScope.read(context).client;
    final p = widget.magic.proposal!;
    final s = await openAutomationEditor(
      context,
      title: p.recipe['description'] is String && (p.recipe['description'] as String).isNotEmpty
          ? p.recipe['description'] as String
          : widget.magic.title,
      seed: p.recipe,
      submitLabel: l.auAxMagicApprove,
      submit: (yaml) => c!.approveMagic(widget.magic.id, yaml),
    );
    if (s != null) widget.onDone(s);
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final c = RgColors.of(context);
    final app = AppScope.of(context);
    final p = widget.magic.proposal!;
    final who = whoOptions(l, app.agents);
    final said = sentence(l, fromRecipe(p.recipe, who, app.projects), who);
    final missing = p.needs.where((n) => n.ready == false).toList();
    final others = p.needs.where((n) => n.ready != false).toList();
    final title = p.recipe['description'] is String && (p.recipe['description'] as String).isNotEmpty
        ? p.recipe['description'] as String
        : (p.recipe['name'] as String? ?? widget.magic.title);
    return Container(
      key: const Key('au-proposal'),
      margin: const EdgeInsets.only(top: 10),
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
      decoration: BoxDecoration(
        color: c.panel,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: godLine(context)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              const GodOrb(size: 24),
              const SizedBox(width: 8),
              Text(
                l.auAxMagicProposal,
                style: TextStyle(fontWeight: FontWeight.w800, color: c.text),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            title,
            style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: c.text),
          ),
          if (p.summary.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 4, bottom: 6),
              child: Text(p.summary, style: TextStyle(color: c.dim, height: 1.4)),
            ),
          if (missing.isNotEmpty)
            Container(
              key: const Key('au-missing'),
              margin: const EdgeInsets.only(top: 6, bottom: 8),
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: c.warn.withValues(alpha: .10),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: c.warn.withValues(alpha: .4)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      RgIcon(RgIcons.alert, size: 16, color: c.warnText),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          l.auAxMagicMissing,
                          style: TextStyle(color: c.warnText, fontWeight: FontWeight.w700),
                        ),
                      ),
                    ],
                  ),
                  for (final n in missing) _Need(need: n),
                ],
              ),
            ),
          SaysBox(lines: said, icon: false),
          if (others.isNotEmpty) ...[
            AutoLb(l.auAxMagicNeeds),
            for (final n in others) _Need(need: n),
          ],
          if (p.needs.isNotEmpty && missing.isEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Text(l.auAxMagicAllSet, style: TextStyle(color: c.ok, fontSize: 13)),
            ),
          if (_why != null)
            Padding(
              padding: const EdgeInsets.only(top: 10),
              child: AutoField(
                label: l.auAxMagicWhy,
                value: _why!,
                lines: 2,
                fieldKey: const Key('au-magic-why'),
                onChanged: (v) => setState(() => _why = v),
              ),
            ),
          if (_error != null) AutoNotice(_error!, error: true, key: const Key('au-error')),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            alignment: WrapAlignment.end,
            children: [
              if (_why == null)
                TextButton(
                  key: const Key('au-magic-reject'),
                  onPressed: () => setState(() => _why = ''),
                  child: Text(l.auAxMagicReject),
                )
              else
                TextButton(
                  key: const Key('au-magic-send-no'),
                  onPressed: _reject,
                  child: Text(l.auAxMagicSendNo),
                ),
              OutlinedButton(
                key: const Key('au-magic-edit'),
                onPressed: _edit,
                child: Text(l.auAxMagicEdit),
              ),
              FilledButton(
                key: const Key('au-magic-approve'),
                onPressed: _busy || missing.isNotEmpty ? null : _approve,
                child: Text(l.auAxMagicApprove),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// One thing the automation needs: what, why, whether it is there, and where it is made.
class _Need extends StatelessWidget {
  const _Need({required this.need});

  final MagicNeed need;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final c = RgColors.of(context);
    final n = need;
    final what = platformNames[n.what.toLowerCase()] ?? n.service ?? n.what;
    final title = switch (n.kind) {
      'chat' => l.auAxNeed_chat(what),
      'email' => l.auAxNeed_email,
      'extension' => l.auAxNeed_extension(what),
      'credential' => l.auAxNeed_credential(what),
      _ => l.auAxNeed_other(what),
    };
    final icon = switch (n.kind) {
      'chat' => RgIcons.chat,
      'email' => RgIcons.send,
      'credential' => RgIcons.key,
      _ => RgIcons.puzzle,
    };
    final where = switch (n.kind) {
      'chat' || 'email' => l.auOwnWhereChats,
      'credential' => l.auOwnWhereKeychain,
      _ => l.auOwnWhereExtensions,
    };
    final tone = n.ready == true ? c.ok : (n.ready == false ? c.warnText : c.dim);
    return Padding(
      key: Key('au-need-${n.kind}-${n.what}'),
      padding: const EdgeInsets.only(top: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 2),
            child: RgIcon(icon, size: 17, color: tone),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: TextStyle(fontWeight: FontWeight.w700, color: c.text)),
                if (n.why.isNotEmpty)
                  Text(n.why, style: TextStyle(color: c.dim, fontSize: 12.5, height: 1.35)),
                if (n.ready == false)
                  Text(
                    l.auOwnNeedOpenWhere(where),
                    style: TextStyle(color: c.warnText, fontSize: 12.5),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Text(
            n.ready == true
                ? l.auAxNeedReady
                : n.ready == false
                ? l.auAxNeedMissing
                : '',
            style: TextStyle(color: tone, fontSize: 12.5, fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }
}

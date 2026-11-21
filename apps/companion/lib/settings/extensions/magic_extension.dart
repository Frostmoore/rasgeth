// G42.11: magic integrations and extensions, native, as the page's MagicExtension.tsx (G38.3):
// the same window as the magic automations. The person writes what they want, God asks in a real
// conversation (the app's conversation screen, embedded) and proposes one package; beside it (above
// it on a phone) what the package is (its tools with their arguments, the hosts it reaches, the
// keys it needs), how its tests went in the throwaway sandbox and what is still missing. «Approve
// and install» stays off until nothing is; the keys are added right here, into the keychain,
// never in the chat. While God works or something is missing the package is read again now and
// then, so what the person adds lights up by itself.
import 'dart:async';

import 'package:flutter/material.dart';

import '../../api/client.dart';
import '../../app_state.dart';
import '../../l10n/app_localizations.dart';
import '../../screens/conversation_screen.dart';
import '../../theme/colors.dart';
import '../../ui/dialogs.dart';
import '../../ui/icons.dart';
import '../api/extensions_api.dart';
import '../automations/automation_kit.dart';
import '../automations/magic_automation.dart' show MagicSteps;
import 'ext_kit.dart';

/// Where a magic package stands, in words.
String magicExtState(AppLocalizations l, String status) => switch (status) {
  'building' => l.xtMxState_building,
  'testing' => l.xtMxState_testing,
  'ready' => l.xtMxState_ready,
  'done' => l.xtMxState_done,
  _ => l.xtMxState_dismissed,
};

/// The window where the person says what the integration or extension should do.
Future<MagicExt?> openMagicExtStart(BuildContext context, String kind) {
  final l = AppLocalizations.of(context);
  return openAutoWindow<MagicExt>(
    context,
    title: kind == 'integration' ? l.xtMxIntegration : l.xtMxExtension,
    icon: const GodOrb(size: 32),
    key: const Key('xt-magic-start'),
    child: (ctx, close) => _MagicStart(kind: kind, onStarted: close),
  );
}

class _MagicStart extends StatefulWidget {
  const _MagicStart({required this.kind, required this.onStarted});

  final String kind;
  final void Function([MagicExt?]) onStarted;

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
      widget.onStarted(await c.startMagicExt(widget.kind, _text.trim()));
    } on ApiException catch (e) {
      if (mounted) {
        setState(() {
          _busy = false;
          _error = e.message;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final c = RgColors.of(context);
    final god = godColor(context);
    final integration = widget.kind == 'integration';
    final examples = integration
        ? [l.xtMxIntegrationEx1, l.xtMxIntegrationEx2, l.xtMxIntegrationEx3]
        : [l.xtMxExtensionEx1, l.xtMxExtensionEx2, l.xtMxExtensionEx3];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Text(
            integration ? l.xtMxIntegrationLead : l.xtMxExtensionLead,
            style: TextStyle(color: c.dim, height: 1.45),
          ),
        ),
        AutoField(
          label: integration ? l.xtMxIntegrationAsk : l.xtMxExtensionAsk,
          hint: integration ? l.xtMxIntegrationPlaceholder : l.xtMxExtensionPlaceholder,
          value: _text,
          lines: 5,
          fieldKey: const Key('xt-magic-ask'),
          onChanged: (v) => setState(() => _text = v),
        ),
        AutoLb(l.xtAxMagicExamples),
        for (final (i, ex) in examples.indexed)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Material(
              color: c.panel,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
                side: BorderSide(color: godLine(context)),
              ),
              child: InkWell(
                key: Key('xt-magic-ex-$i'),
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
        for (final p in [l.xtMxPromise1, l.xtMxPromise2, l.xtMxPromise3])
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
        if (_error != null) AutoNotice(_error!, error: true),
        WindowActs(
          children: [
            TextButton(onPressed: () => widget.onStarted(), child: Text(l.xtCancel)),
            FilledButton.icon(
              key: const Key('xt-magic-go'),
              style: FilledButton.styleFrom(backgroundColor: god, foregroundColor: Colors.white),
              onPressed: _busy || _text.trim().isEmpty ? null : _go,
              icon: const RgIcon(RgIcons.spark, size: 17, color: Colors.white),
              label: Text(_busy ? l.xtAxMagicStarting : l.xtAxMagicGo),
            ),
          ],
        ),
      ],
    );
  }
}

/// A magic package's window: the package beside (on a phone above) the conversation.
Future<void> openMagicExtChat(
  BuildContext context,
  MagicExt m, {
  required Future<void> Function() onChange,
}) {
  final l = AppLocalizations.of(context);
  return openAutoWindow<void>(
    context,
    title: '${m.kind == 'integration' ? l.xtMxIntegration : l.xtMxExtension}: ${m.title}',
    sub: magicExtState(l, m.status),
    icon: const GodOrb(size: 32),
    wide: true,
    full: true,
    scroll: false,
    key: const Key('xt-magic-chat'),
    child: (ctx, close) => MagicExtChat(magic: m, onChange: onChange, close: close),
  );
}

class MagicExtChat extends StatefulWidget {
  const MagicExtChat({
    super.key,
    required this.magic,
    required this.onChange,
    required this.close,
    this.poll = true,
  });

  final MagicExt magic;
  final Future<void> Function() onChange;
  final void Function([void]) close;
  final bool poll;

  @override
  State<MagicExtChat> createState() => _MagicExtChatState();
}

class _MagicExtChatState extends State<MagicExtChat> {
  late MagicExt _m = widget.magic;
  Timer? _timer;

  bool get _waiting =>
      _m.status == 'building' || _m.status == 'testing' || (_m.status == 'ready' && !_m.canApprove);

  @override
  void initState() {
    super.initState();
    if (widget.poll) {
      _timer = Timer.periodic(const Duration(seconds: 3), (_) {
        if (_waiting) unawaited(_reload());
      });
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _reload() async {
    final c = AppScope.read(context).client;
    if (c == null) return;
    try {
      final m = await c.magicExt(_m.id);
      if (mounted) setState(() => _m = m);
    } on ApiException {
      // Read again at the next tick.
    }
  }

  /// After a change: the package and the page's list read again.
  Future<void> _changed([MagicExt? m]) async {
    if (m != null && mounted) setState(() => _m = m);
    await _reload();
    await widget.onChange();
  }

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    final l = AppLocalizations.of(context);
    final c = RgColors.of(context);
    final m = _m;
    final side = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        MagicSteps(status: m.status, labels: [l.xtMxStep1, l.xtMxStep2, l.xtMxStep3]),
        if ((m.status == 'ready' || m.status == 'testing') && m.proposal != null)
          _Package(m: m, onChange: _changed),
        if (m.status == 'done') _InstalledPackage(m: m, onChange: _changed, close: widget.close),
        if (m.status == 'building')
          Container(
            key: const Key('xt-magic-building'),
            margin: const EdgeInsets.only(top: 10),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: c.panel2, borderRadius: BorderRadius.circular(14)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  m.installed.isNotEmpty ? l.xtMxChanging : l.xtMxBuilding,
                  style: TextStyle(color: c.dim, height: 1.4),
                ),
                if (m.installed.isEmpty)
                  TextButton(
                    key: const Key('xt-magic-dismiss'),
                    onPressed: () async {
                      final cl = app.client;
                      if (cl == null) return;
                      try {
                        await cl.dismissMagicExt(m.id);
                        await widget.onChange();
                        widget.close();
                      } on ApiException {
                        await _reload();
                      }
                    },
                    child: Text(l.xtAxMagicDismiss),
                  ),
              ],
            ),
          ),
      ],
    );
    final agent = app.agents.where((a) => a.id == m.agentId).firstOrNull;
    final chat = ConversationScreen(
      key: Key('xt-magic-conv-${m.sessionId}'),
      sessionId: m.sessionId,
      agent: agent,
      embedded: true,
    );
    if (isWide(context)) {
      return SizedBox(
        height: MediaQuery.sizeOf(context).height * .8,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SizedBox(
              width: 360,
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
          constraints: BoxConstraints(maxHeight: MediaQuery.sizeOf(context).height * .45),
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

/// God's package as a preview: what it is, its tests, what is missing, and the choice.
class _Package extends StatefulWidget {
  const _Package({required this.m, required this.onChange});

  final MagicExt m;
  final Future<void> Function([MagicExt?]) onChange;

  @override
  State<_Package> createState() => _PackageState();
}

class _PackageState extends State<_Package> {
  String? _why;
  String? _error;

  Future<void> _run(Future<MagicExt?> Function(RedGiantClient c) f) async {
    final c = AppScope.read(context).client;
    if (c == null) return;
    setState(() => _error = null);
    try {
      await widget.onChange(await f(c));
    } on ApiException catch (e) {
      if (mounted) setState(() => _error = e.message);
    }
  }

  Future<void> _bind(MagicCheck ch) async {
    final l = AppLocalizations.of(context);
    final m = widget.m;
    final yes = await askConfirm(
      context,
      title: l.xtMxGiveKeyTitle(ch.what),
      body: l.xtMxGiveKeyText(
        ch.hosts.join(', '),
        [
          for (final p in m.parts)
            if (p.kind == 'tool') p.name,
        ].join(', '),
      ),
      yes: l.xtMxGiveKey,
    );
    if (yes) await _run((c) => c.bindMagicExtCredential(m.id, ch.what));
  }

  Future<void> _key(MagicCheck ch) async {
    final l = AppLocalizations.of(context);
    final m = widget.m;
    final cred = m.credentials.where((x) => x['name'] == ch.what).firstOrNull;
    final changed = await openAutoWindow<bool>(
      context,
      title: l.xtMxKeyTitle(ch.service ?? ch.what),
      icon: const RgIcon(RgIcons.key, size: 20),
      key: const Key('xt-magic-key'),
      child: (ctx, close) => _KeyWindow(m: m, check: ch, cred: cred, close: close),
    );
    if (changed == true) await widget.onChange();
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final c = RgColors.of(context);
    final m = widget.m;
    final missing = [
      for (final x in m.checks)
        if (!x.ok) x,
    ];
    final there = [
      for (final x in m.checks)
        if (x.ok && x.kind == 'credential') x,
    ];
    final testing = m.status == 'testing';
    return Container(
      key: const Key('xt-package'),
      margin: const EdgeInsets.only(top: 10),
      padding: const EdgeInsets.all(14),
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
              const GodOrb(size: 22),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  l.xtMxProposal,
                  style: TextStyle(color: c.dim, fontWeight: FontWeight.w700),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            m.pTitle,
            style: TextStyle(color: c.text, fontSize: 17, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 4),
          Text(m.pSummary, style: TextStyle(color: c.text, height: 1.45)),
          if (testing)
            AutoNotice(l.xtMxTesting, key: const Key('xt-testing'))
          else if (missing.isNotEmpty) ...[
            const SizedBox(height: 10),
            WarnLine(l.xtMxMissing),
            for (final ch in missing)
              _Check(check: ch, onKey: () => _key(ch), onBind: () => _bind(ch)),
          ],
          AutoLb(l.xtMxReaches),
          if (m.hosts.isEmpty)
            AutoHelp(l.xtMxReachesNothing)
          else
            Wrap(spacing: 6, runSpacing: 6, children: [for (final h in m.hosts) _CodeChip(h)]),
          if (there.isNotEmpty) ...[
            AutoLb(l.xtMxKeys),
            for (final ch in there) _Check(check: ch, onKey: () {}, onBind: () {}),
          ],
          AutoLb(l.xtMxParts),
          for (final p in m.parts) _Part(p: p),
          if (_why != null)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: AutoField(
                label: l.xtAxMagicWhy,
                value: _why!,
                lines: 2,
                fieldKey: const Key('xt-magic-why'),
                onChanged: (v) => setState(() => _why = v),
              ),
            ),
          if (_error != null) AutoNotice(_error!, error: true),
          WindowActs(
            children: [
              if (_why == null)
                TextButton(
                  key: const Key('xt-magic-reject'),
                  onPressed: () => setState(() => _why = ''),
                  child: Text(l.xtAxMagicReject),
                )
              else
                TextButton(
                  key: const Key('xt-magic-send-no'),
                  onPressed: () => _run((cl) async {
                    final r = await cl.rejectMagicExt(
                      m.id,
                      _why!.trim().isEmpty ? null : _why!.trim(),
                    );
                    if (mounted) setState(() => _why = null);
                    return r;
                  }),
                  child: Text(l.xtAxMagicSendNo),
                ),
              OutlinedButton.icon(
                key: const Key('xt-magic-retest'),
                onPressed: testing ? null : () => _run((cl) => cl.retestMagicExt(m.id)),
                icon: const RgIcon(RgIcons.refresh, size: 16),
                label: Text(l.xtMxRetest),
              ),
              FilledButton(
                key: const Key('xt-magic-approve'),
                onPressed: m.canApprove ? () => _run((cl) => cl.approveMagicExt(m.id)) : null,
                child: Text(l.xtMxApprove),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _CodeChip extends StatelessWidget {
  const _CodeChip(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    final c = RgColors.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(color: c.panel2, borderRadius: BorderRadius.circular(8)),
      child: Text(
        text,
        style: TextStyle(fontFamily: 'monospace', fontSize: 12, color: c.text),
      ),
    );
  }
}

/// One thing still missing (or there), with the person's way to make it.
class _Check extends StatelessWidget {
  const _Check({required this.check, required this.onKey, required this.onBind});

  final MagicCheck check;
  final VoidCallback onKey;
  final VoidCallback onBind;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final c = RgColors.of(context);
    final x = check;
    final words = x.kind == 'credential'
        ? x.detail == 'undeclared'
              ? l.xtMxCheckKeyUndeclared(x.what)
              : l.xtMxCheckKey(x.service ?? x.what)
        : x.kind == 'host'
        ? l.xtMxCheckHost(x.what)
        : l.xtMxCheckTest(x.what);
    final why = x.ok
        ? ''
        : x.kind == 'credential'
        ? x.detail == 'undeclared'
              ? l.xtMxWhyGod
              : x.exists
              ? l.xtMxWhyNotGiven
              : l.xtMxWhyMissing
        : x.kind == 'host'
        ? l.xtMxWhyHost
        : l.xtMxWhyTest;
    final tone = x.ok ? c.ok : c.warnText;
    return Container(
      key: Key('xt-check-${x.kind}-${x.what}'),
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: tone.withValues(alpha: .06),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: tone.withValues(alpha: .3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              RgIcon(
                x.kind == 'credential'
                    ? RgIcons.key
                    : x.kind == 'host'
                    ? RgIcons.globe
                    : RgIcons.tool,
                size: 17,
                color: tone,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      words,
                      style: TextStyle(color: c.text, fontWeight: FontWeight.w700),
                    ),
                    if (why.isNotEmpty)
                      Text(why, style: TextStyle(color: c.dim, fontSize: 12.5, height: 1.4)),
                  ],
                ),
              ),
              Text(
                x.ok ? l.xtAxNeedReady : l.xtAxNeedMissing,
                style: TextStyle(color: tone, fontSize: 12, fontWeight: FontWeight.w700),
              ),
            ],
          ),
          if (!x.ok && x.kind == 'credential' && x.detail != 'undeclared')
            Align(
              alignment: Alignment.centerRight,
              child: FilledButton(
                key: Key('xt-check-act-${x.what}'),
                onPressed: x.exists ? onBind : onKey,
                child: Text(x.exists ? l.xtMxGiveKey : l.xtAxNeedVault),
              ),
            ),
        ],
      ),
    );
  }
}

/// One part of the package: what it does, its arguments, its tests, its files.
class _Part extends StatelessWidget {
  const _Part({required this.p});

  final MagicPart p;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final c = RgColors.of(context);
    final bad = p.tests.any((x) => !x.passed) || p.status == 'failed';
    return Container(
      key: Key('xt-part-${p.name}'),
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: c.bg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: bad ? c.err.withValues(alpha: .5) : c.line),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              RgIcon(p.kind == 'tool' ? RgIcons.tool : RgIcons.book, size: 17, color: c.accent),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  p.name,
                  style: TextStyle(color: c.text, fontWeight: FontWeight.w800),
                ),
              ),
              Text(
                p.kind == 'tool' ? l.xtExtKindTool : l.xtExtKindSkill,
                style: TextStyle(color: c.dim, fontSize: 12),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(p.description, style: TextStyle(color: c.text, height: 1.4)),
          if (p.args.isNotEmpty) ...[
            const SizedBox(height: 6),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                Text(l.xtMxArgs, style: TextStyle(color: c.dim, fontSize: 12.5)),
                for (final a in p.args) _CodeChip(a),
              ],
            ),
          ],
          const SizedBox(height: 6),
          for (final t in p.tests)
            Padding(
              padding: const EdgeInsets.only(bottom: 3),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  RgIcon(
                    t.passed ? RgIcons.check : RgIcons.x,
                    size: 15,
                    color: t.passed ? c.ok : c.err,
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      t.passed
                          ? t.name
                          : '${t.name} · ${t.detail.split('\n').where((s) => s.isNotEmpty).take(3).join(' · ')}',
                      style: TextStyle(color: c.text, fontSize: 12.5),
                    ),
                  ),
                ],
              ),
            ),
          if (p.files.isNotEmpty)
            Details(
              title: l.xtMxCode,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (p.command != null) CodeBox(p.command!),
                  for (final f in p.files.entries) ...[MonoText(f.key), CodeBox(f.value)],
                ],
              ),
            ),
        ],
      ),
    );
  }
}

/// The key's window: the value goes into the keychain, used by this package only.
class _KeyWindow extends StatefulWidget {
  const _KeyWindow({required this.m, required this.check, required this.cred, required this.close});

  final MagicExt m;
  final MagicCheck check;
  final Map<String, dynamic>? cred;
  final void Function([bool?]) close;

  @override
  State<_KeyWindow> createState() => _KeyWindowState();
}

class _KeyWindowState extends State<_KeyWindow> {
  String _value = '';
  bool _busy = false;
  String? _error;

  Future<void> _save() async {
    final c = AppScope.read(context).client;
    if (c == null) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await c.addMagicExtCredential(widget.m.id, widget.check.what, _value);
      _value = '';
      widget.close(true);
    } on ApiException catch (e) {
      if (mounted) {
        setState(() {
          _busy = false;
          _error = e.message;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final c = RgColors.of(context);
    final cred = widget.cred;
    final x = widget.check;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(l.xtMxKeyLead, style: TextStyle(color: c.text, height: 1.45)),
        if (cred?['why'] is String) AutoHelp(cred!['why'] as String),
        if (cred?['help'] is String) AutoHelp(cred!['help'] as String),
        const SizedBox(height: 10),
        SecretField(
          label: l.xtMxKeyValue,
          fieldKey: const Key('xt-magic-key-value'),
          onChanged: (v) => setState(() => _value = v),
        ),
        Facts(
          rows: [(l.xtMxKeyName, MonoText(x.what)), (l.xtMxKeyHosts, MonoText(x.hosts.join(', ')))],
        ),
        AutoHelp(l.xtMxKeyOnly),
        if (_error != null) AutoNotice(_error!, error: true),
        WindowActs(
          children: [
            TextButton(onPressed: () => widget.close(false), child: Text(l.xtCancel)),
            FilledButton.icon(
              key: const Key('xt-magic-key-save'),
              onPressed: _busy || _value.trim().isEmpty ? null : _save,
              icon: const RgIcon(RgIcons.key, size: 16, color: Colors.white),
              label: Text(l.xtMxKeySave),
            ),
          ],
        ),
      ],
    );
  }
}

/// An installed package: what it gave, a change through the same conversation, uninstall.
class _InstalledPackage extends StatelessWidget {
  const _InstalledPackage({required this.m, required this.onChange, required this.close});

  final MagicExt m;
  final Future<void> Function([MagicExt?]) onChange;
  final void Function([void]) close;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final c = RgColors.of(context);
    final app = AppScope.of(context);
    return Container(
      key: const Key('xt-installed-package'),
      margin: const EdgeInsets.only(top: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AutoNotice(l.xtMxDone),
          Wrap(spacing: 6, runSpacing: 6, children: [for (final n in m.installed) _CodeChip(n)]),
          WindowActs(
            children: [
              TextButton(
                key: const Key('xt-magic-uninstall'),
                style: TextButton.styleFrom(foregroundColor: c.err),
                onPressed: () async {
                  final yes = await askConfirm(
                    context,
                    title: l.xtMxUninstallTitle(m.title),
                    body: l.xtMxUninstallText(m.installed.join(', ')),
                    yes: l.xtMxUninstall,
                    danger: true,
                  );
                  if (!yes) return;
                  try {
                    await app.client?.uninstallMagicExt(m.id);
                    await onChange();
                    close();
                  } on ApiException {
                    await onChange();
                  }
                },
                child: Text(l.xtMxUninstall),
              ),
              FilledButton(
                key: const Key('xt-magic-change'),
                onPressed: () async {
                  final text = await askText(
                    context,
                    title: l.xtMxChange,
                    hint: l.xtMxChangeLabel,
                    yes: l.xtMxChangeGo,
                    fieldKey: const Key('xt-magic-change-text'),
                  );
                  if (text == null || text.trim().isEmpty) return;
                  try {
                    await onChange(await app.client?.updateMagicExt(m.id, text.trim()));
                  } on ApiException {
                    await onChange();
                  }
                },
                child: Text(l.xtMxChange),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

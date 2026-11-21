// Settings › Nodes (G42.14), the page's Nodes.tsx: other RedGiant machines working with this one.
// This machine's name and fingerprint; the pairs waiting for the person's yes, with the six digits
// and both fingerprints to compare; the tree with each machine's state, capabilities and load, who
// may command it (control is separate from the tree and never implicit), rename and unpair after a
// yes; who may command this machine, with «Take away»; «Add a node» (a code for ten minutes);
// pairing this machine under another one; where each project's commands, backups and videos go.
// Read again every few seconds while open. Nothing pairs without the person's yes on both screens.
import 'dart:async';

import 'package:flutter/material.dart';

import '../../api/client.dart';
import '../../app_state.dart';
import '../../l10n/app_localizations.dart';
import '../../theme/colors.dart';
import '../../ui/dialogs.dart';
import '../../ui/icons.dart';
import '../../ui/settings_kit.dart';
import '../api/system_api.dart';
import 'system_kit.dart';

Future<void> openNodesSettings(BuildContext context) =>
    openSystemScreen(context, const NodesScreen());

/// How often the state is read again (a test sets it longer).
Duration nodesEvery = const Duration(seconds: 4);

String _gb(Object? b) => b is num ? '${(b / (1024 * 1024 * 1024)).round()}' : '?';

class NodesScreen extends StatefulWidget {
  const NodesScreen({super.key});

  @override
  State<NodesScreen> createState() => _NodesScreenState();
}

class _NodesScreenState extends State<NodesScreen> {
  NodesState? _s;
  String? _error;
  Timer? _timer;
  final _name = TextEditingController();
  final _nameFocus = FocusNode();

  @override
  void initState() {
    super.initState();
    unawaited(_load());
    _timer = Timer.periodic(nodesEvery, (_) => unawaited(_load()));
    _nameFocus.addListener(() {
      if (!_nameFocus.hasFocus) unawaited(_saveName());
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _name.dispose();
    _nameFocus.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final c = sysClient(context);
    if (c == null) return;
    try {
      final s = await c.nodes();
      if (!mounted) return;
      setState(() {
        _s = s;
        _error = null;
        if (!_nameFocus.hasFocus) _name.text = s.selfName;
      });
    } on ApiException catch (e) {
      if (mounted) setState(() => _error = sysError(AppLocalizations.of(context), e));
    }
  }

  Future<void> _saveName() async {
    final s = _s;
    final n = _name.text.trim();
    if (s == null || n.isEmpty || n == s.selfName) return;
    await _act((c) => c.setMachineName(n));
  }

  Future<void> _act(Future<void> Function(RedGiantClient c) f) async {
    final l = AppLocalizations.of(context);
    final c = sysClient(context);
    if (c == null) return;
    try {
      await f(c);
      await _load();
    } on ApiException catch (e) {
      if (mounted) setState(() => _error = sysError(l, e));
    }
  }

  Future<void> _unpair(NodeView v) async {
    final l = AppLocalizations.of(context);
    final yes = await askConfirm(
      context,
      title: sw(l, 'ndUnpairQ', {'name': v.name}),
      body: l.syNdUnpairText,
      yes: l.syNdUnpair,
      danger: true,
    );
    if (yes) await _act((c) => c.unpairNode(v.fingerprint));
  }

  Future<void> _rename(NodeView v) async {
    final l = AppLocalizations.of(context);
    final next = await askText(
      context,
      title: sw(l, 'ndRenameQ', {'name': v.name}),
      initial: v.name,
      hint: l.syNdNodeName,
      yes: l.syNdRename,
      fieldKey: const Key('sy-nd-rename-field'),
    );
    if (next == null || next.trim() == v.name || next.trim().isEmpty) return;
    await _act((c) => c.setNodeLabel(v.fingerprint, next.trim()));
  }

  Future<void> _revoke(String target, Map<dynamic, dynamic> g) async {
    final l = AppLocalizations.of(context);
    final yes = await askConfirm(
      context,
      title: sw(l, 'ndRevokeQ', {'name': '${g['controllerName']}'}),
      body: '',
      yes: l.syNdRevoke,
      danger: true,
    );
    if (yes) await _act((c) => c.revokeNodeGrant(target, '${g['id']}'));
  }

  Future<void> _control(NodeView target, List<NodeView> all) async {
    await showRgWindow<void>(
      context: context,
      builder: (_) => _ControlWindow(target: target, all: all, revoke: _revoke),
    );
    await _load();
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final c = RgColors.of(context);
    final s = _s;
    final all = s == null ? const <NodeView>[] : [?s.parent, ...s.tree.flat()];
    return SettingsScaffold(
      title: l.syNdSection,
      backKey: const Key('sy-nodes-back'),
      backLabel: l.back,
      listKey: const Key('sy-nodes-list'),
      children: [
        SysHead(q: l.syNdQ, lead: l.syNdLead),
        if (_error != null) NoticeBanner(text: _error!, error: true),
        if (s == null && _error == null)
          const Padding(
            padding: EdgeInsets.all(24),
            child: Center(child: RgSpinner(size: 22)),
          ),
        if (s != null) ...[
          if (!s.ready) NoticeBanner(text: l.syNdNotReady, error: true),
          SysSub(l.syNdThis),
          SysBox(
            children: [
              SysField(
                label: l.syNdName,
                help: l.syNdNameHelp,
                controller: _name,
                fieldKey: const Key('sy-nd-name'),
                focusNode: _nameFocus,
              ),
              if (s.selfFingerprint != null)
                SysFacts([(l.syNdFingerprint, SysMono(s.selfFingerprint!, size: 11.5))]),
            ],
          ),
          PendingCards(s: s, reload: _load),
          SysSub(l.syNdTree, lead: l.syNdTreeLead),
          if (s.parent != null)
            SysBox(
              key: const Key('sy-nd-parent'),
              children: [
                Text(
                  l.syNdParent,
                  style: TextStyle(color: c.dim, fontWeight: FontWeight.w700, fontSize: 12.5),
                ),
                _NodeLine(
                  v: s.parent!,
                  extra: [
                    if (s.parent!.address != null) SysText(s.parent!.address!),
                    if (s.parent!.reason != null && s.parent!.status != 'online')
                      SysText('${l.syNdReason}: ${s.parent!.reason}'),
                  ],
                  actions: [
                    OutlinedButton(onPressed: () => _unpair(s.parent!), child: Text(l.syNdUnpair)),
                  ],
                ),
              ],
            ),
          SysBox(
            key: const Key('sy-nd-tree'),
            children: [
              for (final (v, depth) in _rows(s.tree, 0))
                Padding(
                  padding: EdgeInsets.only(left: depth * 18.0),
                  child: _NodeLine(
                    key: Key('sy-nd-${v.fingerprint}'),
                    v: v,
                    self: s.selfFingerprint,
                    actions: [
                      OutlinedButton.icon(
                        key: Key('sy-nd-control-${v.fingerprint}'),
                        onPressed: () => _control(v, all),
                        icon: RgIcon(RgIcons.shield, size: 14, color: c.text),
                        label: Text(l.syNdControl),
                      ),
                      if (v.relation == 'child') ...[
                        OutlinedButton(
                          key: Key('sy-nd-rename-${v.fingerprint}'),
                          onPressed: () => _rename(v),
                          child: Text(l.syNdRename),
                        ),
                        OutlinedButton(
                          key: Key('sy-nd-unpair-${v.fingerprint}'),
                          onPressed: () => _unpair(v),
                          child: Text(l.syNdUnpair),
                        ),
                      ],
                    ],
                  ),
                ),
              if (s.tree.children.isEmpty) SysText(l.syNdNoNodes),
            ],
          ),
          SysSub(l.syNdGrantsHere, lead: l.syNdGrantsLead),
          SysBox(
            key: const Key('sy-nd-grants'),
            children: [
              if (s.grants.isEmpty) SysText(l.syNdWhoNobody),
              for (final g in s.grants)
                SysRow(
                  title: '${g['controllerName']}',
                  help: (g['rights'] as List? ?? const []).contains('admin')
                      ? l.syNdAdmin
                      : l.syNdUse,
                  trailing: [
                    TextButton(
                      onPressed: () => _revoke(s.selfFingerprint ?? '', g),
                      child: Text(l.syNdRevoke),
                    ),
                  ],
                ),
            ],
          ),
          SysSub(l.syNdAddTitle, lead: l.syNdAddLead),
          _AddNode(s: s, reload: _load),
          if (s.parent == null && !s.pending.any((p) => p['side'] == 'node')) ...[
            SysSub(l.syNdJoinTitle, lead: l.syNdJoinLead),
            SysBox(children: [PairForm(reload: _load)]),
          ],
          _Placements(s: s, reload: _load),
        ],
      ],
    );
  }

  static List<(NodeView, int)> _rows(NodeView v, int depth) => [
    (v, depth),
    for (final c in v.children) ..._rows(c, depth + 1),
  ];
}

class _StatePill extends StatelessWidget {
  const _StatePill({required this.status});

  final String status;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final c = RgColors.of(context);
    final (label, tone) = switch (status) {
      'online' => (l.syNdOnline, c.ok),
      'pending' => (l.syNdPending, c.accent),
      'connecting' => (l.syNdConnecting, c.accent),
      'refused' => (l.syNdRefused, c.err),
      _ => (l.syNdOffline, c.dim),
    };
    return SysPill(label, tone: tone);
  }
}

/// One machine: its name, its state, what it can do, who may command it, its buttons.
class _NodeLine extends StatelessWidget {
  const _NodeLine({
    super.key,
    required this.v,
    this.self,
    this.extra = const [],
    this.actions = const [],
  });

  final NodeView v;
  final String? self;
  final List<Widget> extra;
  final List<Widget> actions;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final c = RgColors.of(context);
    final noRights =
        v.relation == 'child' &&
        v.status == 'online' &&
        self != null &&
        !v.grants.any(
          (g) => g['controller'] == self && (g['rights'] as List? ?? const []).isNotEmpty,
        );
    final caps = v.capabilities;
    final sandbox = caps?['sandbox'] is Map ? caps!['sandbox'] as Map : null;
    final storage = caps?['storage'] is Map ? caps!['storage'] as Map : null;
    final load = caps?['load'] is Map ? caps!['load'] as Map : null;
    final models = [
      for (final p in caps?['models'] is List ? caps!['models'] as List : const [])
        if (p is Map) ...(p['models'] as List? ?? const []),
    ].length;
    final facts = <(RgIcons?, String)>[
      if (sandbox != null)
        sandbox['ok'] == true
            ? (RgIcons.cpu, sw(l, 'ndCpu', {'n': '${sandbox['cpus'] ?? '?'}'}))
            : (null, l.syNdNoSandbox),
      if (sandbox?['memoryMb'] is num)
        (
          RgIcons.layers,
          sw(l, 'ndRam', {'n': '${((sandbox!['memoryMb'] as num) / 1024).round()}'}),
        ),
      if (storage?['ok'] == true)
        (RgIcons.database, sw(l, 'ndFree', {'n': _gb(storage!['freeBytes'])})),
      if (models > 0) (RgIcons.zap, sw(l, 'ndModels', {'n': '$models'})),
      if (load?['cpu'] != null) (null, sw(l, 'ndLoad', {'n': '${load!['cpu']}'})),
      if (sandbox?['ok'] == true && sandbox?['container'] == false) (null, l.syNdNoContainer),
    ];
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              RgIcon(
                v.relation == 'self' ? RgIcons.server : RgIcons.nodes,
                size: 20,
                color: c.accent,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Wrap(
                  spacing: 6,
                  runSpacing: 4,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    Text(
                      v.name,
                      style: TextStyle(fontWeight: FontWeight.w800, color: c.text),
                    ),
                    if (v.relation != 'self') _StatePill(status: v.status),
                    if (noRights) SysPill(l.syNdNoRights, tone: c.err),
                    if (v.status != 'online' && v.lastSeen != null)
                      Text(
                        sw(l, 'ndLastSeen', {'when': sysWhen(v.lastSeen)}),
                        style: TextStyle(color: c.dim, fontSize: 12),
                      ),
                  ],
                ),
              ),
            ],
          ),
          if (facts.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(left: 28, top: 4),
              child: Wrap(
                spacing: 12,
                runSpacing: 4,
                children: [
                  for (final (icon, text) in facts)
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (icon != null) ...[
                          RgIcon(icon, size: 14, color: c.dim),
                          const SizedBox(width: 4),
                        ],
                        Text(text, style: TextStyle(color: c.dim, fontSize: 12.5)),
                      ],
                    ),
                ],
              ),
            ),
          Padding(
            padding: const EdgeInsets.only(left: 28, top: 4),
            child: Text.rich(
              TextSpan(
                children: [
                  TextSpan(
                    text: '${l.syNdWho} ',
                    style: TextStyle(color: c.dim, fontWeight: FontWeight.w700),
                  ),
                  TextSpan(
                    text: v.grants.isEmpty
                        ? l.syNdWhoNobody
                        : [
                            for (final g in v.grants)
                              '${g['controllerName']} ${(g['rights'] as List? ?? const []).contains('admin') ? l.syNdAdmin : l.syNdUse}',
                          ].join(', '),
                    style: TextStyle(color: c.text),
                  ),
                ],
              ),
              style: const TextStyle(fontSize: 12.5),
            ),
          ),
          ...extra.map((w) => Padding(padding: const EdgeInsets.only(left: 28), child: w)),
          if (actions.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(left: 28, top: 6),
              child: Wrap(spacing: 6, runSpacing: 6, children: actions),
            ),
        ],
      ),
    );
  }
}

/// Who may command a machine: the person picks a machine and what it may do there.
class _ControlWindow extends StatefulWidget {
  const _ControlWindow({required this.target, required this.all, required this.revoke});

  final NodeView target;
  final List<NodeView> all;
  final Future<void> Function(String target, Map<dynamic, dynamic> g) revoke;

  @override
  State<_ControlWindow> createState() => _ControlWindowState();
}

class _ControlWindowState extends State<_ControlWindow> {
  late final _others = widget.all.where((x) => x.fingerprint != widget.target.fingerprint).toList();
  late String _controller = _others.isNotEmpty ? _others.first.fingerprint : '';
  String _rights = 'use';
  String? _error;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return AlertDialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 24),
      title: Text(sw(l, 'ndControlTitle', {'name': widget.target.name})),
      content: SizedBox(
        width: 460,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SysText(l.syNdControlLead),
              for (final g in widget.target.grants)
                SysRow(
                  title: '${g['controllerName']}',
                  help: (g['rights'] as List? ?? const []).contains('admin')
                      ? l.syNdAdmin
                      : l.syNdUse,
                  trailing: [
                    TextButton(
                      onPressed: () async {
                        await widget.revoke(widget.target.fingerprint, g);
                        if (context.mounted) Navigator.of(context).pop();
                      },
                      child: Text(l.syNdRevoke),
                    ),
                  ],
                ),
              if (_others.isNotEmpty) ...[
                SysText(l.syNdController, dim: false, strong: true),
                SysSeg<String>(
                  keyPrefix: 'sy-nd-controller',
                  value: _controller,
                  onChanged: (v) => setState(() => _controller = v),
                  options: [for (final o in _others) (o.fingerprint, o.name)],
                ),
                SysText(l.syNdRights, dim: false, strong: true),
                SysSeg<String>(
                  keyPrefix: 'sy-nd-rights',
                  value: _rights,
                  onChanged: (v) => setState(() => _rights = v),
                  options: [('use', l.syNdRightUse), ('admin', l.syNdRightAdmin)],
                ),
              ],
              if (_error != null) SysSaid(text: _error!),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.of(context).pop(), child: Text(l.syCancel)),
        if (_others.isNotEmpty)
          FilledButton(
            key: const Key('sy-nd-give'),
            onPressed: _controller.isEmpty
                ? null
                : () async {
                    final c = sysClient(context);
                    if (c == null) return;
                    try {
                      await c.grantNode(
                        _controller,
                        widget.target.fingerprint,
                        _rights == 'admin' ? ['use', 'admin'] : ['use'],
                      );
                      if (context.mounted) Navigator.of(context).pop();
                    } on ApiException catch (e) {
                      setState(() => _error = sysError(l, e));
                    }
                  },
            child: Text(l.syNdGive),
          ),
      ],
    );
  }
}

/// A pair waiting for the yes here: the six digits, both fingerprints and, on a node, the rights.
class PendingCards extends StatefulWidget {
  const PendingCards({super.key, required this.s, required this.reload});

  final NodesState s;
  final Future<void> Function() reload;

  @override
  State<PendingCards> createState() => _PendingCardsState();
}

class _PendingCardsState extends State<PendingCards> {
  bool _use = true;
  bool _admin = true;
  final _names = <String, TextEditingController>{};
  String? _error;

  @override
  void dispose() {
    for (final c in _names.values) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _do(Future<void> Function(RedGiantClient c) f) async {
    final l = AppLocalizations.of(context);
    final c = sysClient(context);
    if (c == null) return;
    try {
      await f(c);
      await widget.reload();
    } on ApiException catch (e) {
      if (mounted) setState(() => _error = sysError(l, e));
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final c = RgColors.of(context);
    final s = widget.s;
    if (s.pending.isEmpty) return const SizedBox.shrink();
    return Column(
      key: const Key('sy-nd-pending'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SysSub(l.syNdPendingTitle, lead: l.syNdPendingLead),
        for (final p in s.pending)
          SysBox(
            key: Key('sy-nd-pending-${p['fingerprint']}'),
            children: [
              Row(
                children: [
                  RgIcon(RgIcons.key, size: 20, color: c.accent),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      sw(
                        l,
                        p['side'] == 'principal' ? 'ndPendingFromNode' : 'ndPendingFromPrincipal',
                        {'name': '${p['name']}'},
                      ),
                      style: TextStyle(fontWeight: FontWeight.w800, color: c.text),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                l.syNdSas,
                style: TextStyle(color: c.dim, fontWeight: FontWeight.w700),
              ),
              SelectableText(
                '${p['sas']}',
                key: const Key('sy-nd-sas'),
                style: TextStyle(
                  fontSize: 30,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 6,
                  color: c.text,
                  fontFamily: 'monospace',
                ),
              ),
              SysFacts([
                (l.syNdTheirFp, SysMono('${p['fingerprint']}', size: 11.5)),
                (l.syNdFingerprint, SysMono(s.selfFingerprint ?? '', size: 11.5)),
              ]),
              if (p['side'] == 'principal')
                SysField(
                  label: l.syNdNodeName,
                  help: l.syNdNodeNameHelp,
                  controller: _names.putIfAbsent(
                    '${p['fingerprint']}',
                    () => TextEditingController(text: '${p['name']}'),
                  ),
                ),
              if (p['side'] == 'node') ...[
                SysText(sw(l, 'ndRightsTitle', {'name': '${p['name']}'}), dim: false, strong: true),
                SwitchLine(
                  title: l.syNdRightUse,
                  help: l.syNdRightUseHelp,
                  on: _use,
                  onChanged: (v) => setState(() => _use = v),
                ),
                SwitchLine(
                  title: l.syNdRightAdmin,
                  help: l.syNdRightAdminHelp,
                  on: _admin,
                  onChanged: (v) => setState(() => _admin = v),
                ),
              ],
              SysActs(
                children: [
                  OutlinedButton(
                    key: const Key('sy-nd-reject'),
                    onPressed: () => _do((c) => c.rejectNode('${p['fingerprint']}')),
                    child: Text(l.syNdReject),
                  ),
                  FilledButton(
                    key: const Key('sy-nd-confirm'),
                    onPressed: () => _do((c) {
                      final fp = '${p['fingerprint']}';
                      if (p['side'] == 'node') {
                        return c.confirmNode(fp, rights: [if (_use) 'use', if (_admin) 'admin']);
                      }
                      final name = _names[fp]?.text.trim();
                      return c.confirmNode(
                        fp,
                        name: name != null && name.isNotEmpty && name != '${p['name']}'
                            ? name
                            : null,
                      );
                    }),
                    child: Text(l.syNdConfirm),
                  ),
                ],
              ),
            ],
          ),
        if (_error != null) SysSaid(text: _error!),
      ],
    );
  }
}

final _pairCode = RegExp(r'^[A-Za-z0-9]{4}-?[A-Za-z0-9]{4}$');

/// On the node: the principal's address and its code.
class PairForm extends StatefulWidget {
  const PairForm({super.key, required this.reload});

  final Future<void> Function() reload;

  @override
  State<PairForm> createState() => _PairFormState();
}

class _PairFormState extends State<PairForm> {
  final _address = TextEditingController();
  final _code = TextEditingController();
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    _address.dispose();
    _code.dispose();
    super.dispose();
  }

  Future<void> _pair() async {
    final l = AppLocalizations.of(context);
    final c = sysClient(context);
    if (c == null) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await c.pairNode(_address.text.trim(), _code.text.trim().toUpperCase());
      _code.clear();
      await widget.reload();
    } on ApiException catch (e) {
      if (mounted) setState(() => _error = sysError(l, e));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final ready = _address.text.trim().length > 2 && _pairCode.hasMatch(_code.text.trim());
    return Column(
      key: const Key('sy-nd-pair'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SysField(
          label: l.syNdAddress,
          hint: l.syNdAddressPh,
          controller: _address,
          fieldKey: const Key('sy-nd-pair-address'),
          onChanged: (_) => setState(() {}),
        ),
        SysField(
          label: l.syNdCodeField,
          hint: l.syNdCodePh,
          controller: _code,
          fieldKey: const Key('sy-nd-pair-code'),
          onChanged: (_) => setState(() {}),
        ),
        if (_error != null) SysSaid(text: _error!),
        SysActs(
          children: [
            FilledButton(
              key: const Key('sy-nd-pair-go'),
              onPressed: !ready || _busy ? null : _pair,
              child: Text(_busy ? l.syNdPairing : l.syNdPair),
            ),
          ],
        ),
      ],
    );
  }
}

/// «Add a node»: a code for ten minutes, with the address to write on the other machine.
class _AddNode extends StatefulWidget {
  const _AddNode({required this.s, required this.reload});

  final NodesState s;
  final Future<void> Function() reload;

  @override
  State<_AddNode> createState() => _AddNodeState();
}

class _AddNodeState extends State<_AddNode> {
  Timer? _tick;

  @override
  void initState() {
    super.initState();
    _tick = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted && widget.s.code != null) setState(() {});
    });
  }

  @override
  void dispose() {
    _tick?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final c = RgColors.of(context);
    final code = widget.s.code;
    final until = DateTime.tryParse('${code?['expiresAt'] ?? ''}');
    final left = until == null ? Duration.zero : until.difference(DateTime.now());
    final client = sysClient(context);
    final address = AppScope.read(context).client?.base.origin ?? '';
    return SysBox(
      key: const Key('sy-nd-add'),
      children: [
        if (code != null && left > Duration.zero) ...[
          Text(
            l.syNdCode,
            style: TextStyle(color: c.dim, fontWeight: FontWeight.w700),
          ),
          SelectableText(
            '${code['code']}',
            key: const Key('sy-nd-code'),
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w800,
              letterSpacing: 4,
              color: c.text,
              fontFamily: 'monospace',
            ),
          ),
          SysText(sw(l, 'ndCodeExpires', {'min': '${(left.inSeconds / 60).round().clamp(1, 99)}'})),
          SysText(sw(l, 'ndCodeAddress', {'address': address})),
          SysActs(
            children: [
              OutlinedButton(
                key: const Key('sy-nd-code-stop'),
                onPressed: client == null
                    ? null
                    : () async {
                        try {
                          await client.cancelNodeCode();
                        } on ApiException {
                          // Read again below either way.
                        }
                        await widget.reload();
                      },
                child: Text(l.syNdCodeStop),
              ),
            ],
          ),
        ] else
          SysActs(
            start: true,
            children: [
              FilledButton.icon(
                key: const Key('sy-nd-add-go'),
                onPressed: !widget.s.ready || client == null
                    ? null
                    : () async {
                        try {
                          await client.nodeCode();
                        } on ApiException {
                          // Read again below either way.
                        }
                        await widget.reload();
                      },
                icon: const RgIcon(RgIcons.plus, size: 14, color: Colors.white),
                label: Text(l.syNdAddButton),
              ),
            ],
          ),
      ],
    );
  }
}

/// Where each project's commands, backups and videos go: here by default.
class _Placements extends StatefulWidget {
  const _Placements({required this.s, required this.reload});

  final NodesState s;
  final Future<void> Function() reload;

  @override
  State<_Placements> createState() => _PlacementsState();
}

class _PlacementsState extends State<_Placements> {
  String? _done;
  String? _error;

  Future<void> _set(String scope, String what, String? v) async {
    final l = AppLocalizations.of(context);
    final c = sysClient(context);
    if (c == null) return;
    try {
      await c.setNodePlacement(scope, what, v);
      await widget.reload();
    } on ApiException catch (e) {
      if (mounted) setState(() => _error = sysError(l, e));
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final c = RgColors.of(context);
    final s = widget.s;
    final nodes = [?s.parent, ...s.tree.flat().where((n) => n.relation != 'self')];
    if (nodes.isEmpty) return const SizedBox.shrink();
    final projects = AppScope.of(context).projects;
    final opts = [('', l.syNdHere), for (final n in nodes) (n.fingerprint, n.name)];
    return Column(
      key: const Key('sy-nd-places'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SysSub(l.syNdPlaces, lead: l.syNdPlacesLead),
        if (projects.isEmpty) SysBox(children: [SysText(l.syNdNoProjects)]),
        for (final p in projects)
          Builder(
            builder: (context) {
              final scope = 'project:${p.id}';
              final pl = s.placements.where((x) => x['scope'] == scope).firstOrNull ?? const {};
              return SysBox(
                key: Key('sy-nd-place-${p.id}'),
                children: [
                  Text(
                    p.name,
                    style: TextStyle(fontWeight: FontWeight.w800, color: c.text),
                  ),
                  SysText(l.syNdCommandsOn, dim: false),
                  SysSeg<String>(
                    keyPrefix: 'sy-nd-cmd-${p.id}',
                    value: '${pl['commands'] ?? ''}',
                    onChanged: (v) => _set(scope, 'commands', v.isEmpty ? null : v),
                    options: opts,
                  ),
                  SysText(l.syNdBackupsOn, dim: false),
                  SysSeg<String>(
                    keyPrefix: 'sy-nd-bk-${p.id}',
                    value: '${pl['backups'] ?? ''}',
                    onChanged: (v) => _set(scope, 'backups', v.isEmpty ? null : v),
                    options: opts,
                  ),
                  SysText(l.syNdRenderOn, dim: false),
                  SysSeg<String>(
                    keyPrefix: 'sy-nd-render-${p.id}',
                    value: pl['render'] == null
                        ? null
                        : (pl['render'] == 'here' ? '' : '${pl['render']}'),
                    onChanged: (v) => _set(scope, 'render', v.isEmpty ? 'here' : v),
                    options: opts,
                  ),
                  if (pl['backups'] != null)
                    SysActs(
                      start: true,
                      children: [
                        OutlinedButton.icon(
                          onPressed: () async {
                            final cl = sysClient(context);
                            if (cl == null) return;
                            try {
                              final name = await cl.nodeBackup(p.id);
                              if (mounted) {
                                setState(() => _done = sw(l, 'ndBackupDone', {'name': name}));
                              }
                            } on ApiException catch (e) {
                              if (mounted) setState(() => _error = sysError(l, e));
                            }
                          },
                          icon: RgIcon(RgIcons.archive, size: 14, color: c.text),
                          label: Text(l.syNdBackupNow),
                        ),
                      ],
                    ),
                ],
              );
            },
          ),
        if (_done != null) SysNote(tone: 'ok', icon: RgIcons.check, text: _done!),
        if (_error != null) SysSaid(text: _error!),
      ],
    );
  }
}

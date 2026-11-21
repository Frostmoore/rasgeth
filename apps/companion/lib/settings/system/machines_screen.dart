// Settings › Machines (G42.14), the page's Machines.tsx: the person's other computers, reached by
// the agents over SSH. Each machine with its name, where it is, who logs in and how (a key RedGiant
// makes, a key the person pastes, or a password: kept only in the keychain), a working folder and
// who may use it. «Test the connection» shows the machine's own key the first time, with its
// fingerprint, and the person trusts it; afterwards a different key is refused, in red, and only
// replaced after a yes. Add, change (the secrets stay unless new ones are written), new key,
// remove after a yes.
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../api/client.dart';
import '../../api/types.dart' show AgentKind;
import '../../app_state.dart';
import '../../l10n/app_localizations.dart';
import '../../theme/colors.dart';
import '../../ui/dialogs.dart';
import '../../ui/icons.dart';
import '../../ui/settings_kit.dart';
import '../api/system_api.dart';
import 'system_kit.dart';

Future<void> openMachinesSettings(BuildContext context) =>
    openSystemScreen(context, const MachinesScreen());

final _machineName = RegExp(r'^[a-z0-9][a-z0-9_.-]{0,39}$', caseSensitive: false);

/// What a test found, in the person's words.
String testText(AppLocalizations l, Map<String, dynamic> r) => switch (r['code']) {
  'ok' => sw(l, 'mcTestOk', {'system': '${r['system'] ?? ''}'}),
  'auth' => l.syMcTestAuth,
  'unreachable' => l.syMcTestUnreachable,
  'timeout' => l.syMcTestTimeout,
  'no-secret' => l.syMcTestNoSecret,
  _ => sw(l, 'mcTestError', {'message': '${r['message'] ?? ''}'}),
};

class MachinesScreen extends StatefulWidget {
  const MachinesScreen({super.key});

  @override
  State<MachinesScreen> createState() => _MachinesScreenState();
}

class _MachinesScreenState extends State<MachinesScreen> {
  List<MachineView>? _list;

  @override
  void initState() {
    super.initState();
    unawaited(_load());
  }

  Future<void> _load() async {
    final c = sysClient(context);
    if (c == null) return;
    try {
      final m = await c.machines();
      if (mounted) setState(() => _list = m);
    } on ApiException {
      if (mounted) setState(() => _list = const []);
    }
  }

  Future<void> _edit(MachineView? m) async {
    await showRgWindow<void>(
      context: context,
      builder: (_) => MachineEditor(m: m),
    );
    await _load();
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final list = _list;
    return SettingsScaffold(
      title: l.syMcSection,
      backKey: const Key('sy-machines-back'),
      backLabel: l.back,
      listKey: const Key('sy-machines-list'),
      children: [
        SysHead(q: l.syMcTitle, lead: l.syMcLead),
        if (list == null)
          const Padding(
            padding: EdgeInsets.all(24),
            child: Center(child: RgSpinner(size: 22)),
          ),
        if (list != null && list.isEmpty)
          Padding(padding: const EdgeInsets.symmetric(horizontal: 16), child: SysText(l.syMcEmpty)),
        for (final m in list ?? const <MachineView>[])
          _MachineCard(key: Key('sy-mc-${m.id}'), m: m, onEdit: () => _edit(m), reload: _load),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: SysActs(
            children: [
              FilledButton.icon(
                key: const Key('sy-mc-new'),
                onPressed: () => _edit(null),
                icon: const RgIcon(RgIcons.plus, size: 14, color: Colors.white),
                label: Text(l.syMcNew),
              ),
            ],
          ),
        ),
        Padding(padding: const EdgeInsets.fromLTRB(16, 10, 16, 0), child: SysText(l.syMcSafety)),
      ],
    );
  }
}

class _MachineCard extends StatefulWidget {
  const _MachineCard({super.key, required this.m, required this.onEdit, required this.reload});

  final MachineView m;
  final VoidCallback onEdit;
  final Future<void> Function() reload;

  @override
  State<_MachineCard> createState() => _MachineCardState();
}

class _MachineCardState extends State<_MachineCard> {
  bool _busy = false;
  Map<String, dynamic>? _result;
  bool _copied = false;

  Future<void> _test() async {
    final c = sysClient(context);
    if (c == null) return;
    setState(() {
      _busy = true;
      _result = null;
    });
    try {
      final r = await c.testMachine(widget.m.id);
      if (mounted) setState(() => _result = r);
    } on ApiException catch (e) {
      if (mounted) {
        setState(() => _result = {'ok': false, 'code': 'error', 'message': e.message});
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
    await widget.reload();
  }

  Future<void> _trust(String fingerprint, bool replace) async {
    final l = AppLocalizations.of(context);
    if (replace) {
      final yes = await askConfirm(
        context,
        title: sw(l, 'mcReplaceQ', {'name': widget.m.name}),
        body: l.syMcReplaceText,
        yes: l.syMcReplaceYes,
        danger: true,
      );
      if (!yes || !mounted) return;
    }
    final c = sysClient(context);
    if (c == null) return;
    try {
      await c.trustMachine(widget.m.id, fingerprint);
      await _test();
    } on ApiException catch (e) {
      if (mounted) setState(() => _result = {'ok': false, 'code': 'error', 'message': e.message});
    }
  }

  Future<void> _remove() async {
    final l = AppLocalizations.of(context);
    final yes = await askConfirm(
      context,
      title: sw(l, 'mcRemoveQ', {'name': widget.m.name}),
      body: l.syMcRemoveText,
      yes: l.syRemove,
      danger: true,
    );
    if (!yes || !mounted) return;
    final c = sysClient(context);
    if (c == null) return;
    try {
      await c.removeMachine(widget.m.id);
    } on ApiException {
      // Read again below.
    }
    await widget.reload();
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final c = RgColors.of(context);
    final m = widget.m;
    final app = AppScope.of(context);
    final who = m.everyone
        ? l.syMcWhoEveryone
        : [
            for (final id in m.agents) app.agents.where((a) => a.id == id).firstOrNull?.name ?? id,
            for (final id in m.projects)
              '${l.syMcProject} ${app.projects.where((p) => p.id == id).firstOrNull?.name ?? id}',
          ].join(', ');
    final failed = m.lastTest != null && m.lastTest!['ok'] == false;
    final (state, tone) = m.hostKey == null
        ? (l.syMcStateNew, c.accent)
        : (failed ? (l.syMcStateFailed, c.err) : (l.syMcStateTrusted, c.ok));
    final r = _result;
    final hk = r?['hostKey'] is Map ? r!['hostKey'] as Map : null;
    return SysBox(
      children: [
        Row(
          children: [
            RgIcon(RgIcons.server, size: 22, color: c.accent),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    m.name,
                    style: TextStyle(fontWeight: FontWeight.w800, color: c.text),
                  ),
                  Text(
                    '${m.user}@${m.host}${m.port == 22 ? '' : ':${m.port}'}',
                    style: TextStyle(color: c.dim, fontSize: 12.5),
                  ),
                ],
              ),
            ),
            SysPill(state, tone: tone),
          ],
        ),
        const SizedBox(height: 8),
        SysFacts([
          (l.syMcFolder, (m.folder?.isNotEmpty ?? false) ? m.folder! : l.syMcFolderNone),
          (
            l.syMcLogin,
            m.auth == 'password'
                ? l.syMcLoginPassword
                : (m.keySource == 'imported' ? l.syMcLoginImported : l.syMcLoginGenerated),
          ),
          (l.syMcWho, who.isEmpty ? l.syMcWhoNobody : who),
          if (m.hostKey != null)
            (
              l.syMcHostKey,
              SysMono('${m.hostKey!['type']} ${m.hostKey!['fingerprint']}', size: 11.5),
            ),
        ]),
        if (m.auth == 'key' && m.publicKey != null) ...[
          SysText(l.syMcPublicKey, dim: false, strong: true),
          SysText(l.syMcPublicKeyHelp),
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: c.bg,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: c.line),
            ),
            child: SysMono(m.publicKey!, size: 11.5),
          ),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton.icon(
              key: Key('sy-mc-copy-${m.id}'),
              onPressed: () async {
                await Clipboard.setData(ClipboardData(text: m.publicKey!));
                if (mounted) setState(() => _copied = true);
              },
              icon: RgIcon(RgIcons.copy, size: 14, color: c.accent),
              label: Text(_copied ? l.syMcCopied : l.syMcCopy),
            ),
          ),
        ],
        if (r?['code'] == 'host-key-new' && hk != null)
          Container(
            key: const Key('sy-mc-tofu'),
            margin: const EdgeInsets.only(top: 8),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: c.accentSoft,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: c.accentDim),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    RgIcon(RgIcons.shield, size: 16, color: c.accent),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        l.syMcTofuTitle,
                        style: TextStyle(fontWeight: FontWeight.w800, color: c.text),
                      ),
                    ),
                  ],
                ),
                SysText(l.syMcTofuText, dim: false),
                SysMono('${hk['type']} ${hk['fingerprint']}', size: 11.5),
                SysText(l.syMcTofuHow),
                SysActs(
                  children: [
                    TextButton(
                      onPressed: () => setState(() => _result = null),
                      child: Text(l.syCancel),
                    ),
                    FilledButton(
                      key: const Key('sy-mc-trust'),
                      onPressed: () => _trust('${hk['fingerprint']}', false),
                      child: Text(l.syMcTrust),
                    ),
                  ],
                ),
              ],
            ),
          ),
        if (r?['code'] == 'host-key-changed')
          Container(
            key: const Key('sy-mc-changed'),
            margin: const EdgeInsets.only(top: 8),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: c.err.withValues(alpha: .08),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: c.err.withValues(alpha: .4)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    RgIcon(RgIcons.alert, size: 16, color: c.err),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        l.syMcChangedTitle,
                        style: TextStyle(fontWeight: FontWeight.w800, color: c.err),
                      ),
                    ),
                  ],
                ),
                SysText(sw(l, 'mcChangedText', {'name': m.name}), dim: false),
                SysFacts([
                  (l.syMcChangedWas, SysMono('${r!['expected'] ?? ''}', size: 11.5)),
                  (l.syMcChangedNow, SysMono('${hk?['fingerprint'] ?? ''}', size: 11.5)),
                ]),
                SysActs(
                  children: [
                    FilledButton(
                      key: const Key('sy-mc-replace'),
                      style: FilledButton.styleFrom(backgroundColor: c.err),
                      onPressed: () => _trust('${hk?['fingerprint'] ?? ''}', true),
                      child: Text(l.syMcReplaceYes),
                    ),
                  ],
                ),
              ],
            ),
          ),
        if (r != null && r['code'] != 'host-key-new' && r['code'] != 'host-key-changed')
          SysNote(
            key: const Key('sy-mc-result'),
            tone: r['ok'] == true ? 'ok' : 'error',
            icon: r['ok'] == true ? RgIcons.check : RgIcons.alert,
            text: testText(l, r),
          ),
        SysActs(
          children: [
            TextButton(
              key: Key('sy-mc-remove-${m.id}'),
              onPressed: _remove,
              child: Text(l.syRemove),
            ),
            OutlinedButton(
              key: Key('sy-mc-edit-${m.id}'),
              onPressed: widget.onEdit,
              child: Text(l.syMcEdit),
            ),
            FilledButton(
              key: Key('sy-mc-test-${m.id}'),
              onPressed: _busy ? null : _test,
              child: Text(_busy ? l.syMcTesting : l.syMcTest),
            ),
          ],
        ),
      ],
    );
  }
}

/// Adding a machine, or changing one (its secrets stay unless new ones are written).
class MachineEditor extends StatefulWidget {
  const MachineEditor({super.key, this.m});

  final MachineView? m;

  @override
  State<MachineEditor> createState() => _MachineEditorState();
}

class _MachineEditorState extends State<MachineEditor> {
  late final MachineView? m = widget.m;
  late final _name = TextEditingController(text: m?.name ?? '');
  late final _host = TextEditingController(text: m?.host ?? '');
  late final _user = TextEditingController(text: m?.user ?? '');
  late final _folder = TextEditingController(text: m?.folder ?? '');
  late final _port = TextEditingController(text: '${m?.port ?? 22}');
  final _privateKey = TextEditingController();
  final _passphrase = TextEditingController();
  final _password = TextEditingController();
  late String _auth = m?.auth ?? 'key';
  late String _keyWay = m?.keySource == 'imported' ? 'paste' : 'generate';
  late bool _everyone = m?.everyone ?? false;
  late final Set<String> _agents = {...?m?.agents};
  late final Set<String> _projects = {...?m?.projects};
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    for (final c in [_name, _host, _user, _folder, _port, _privateKey, _passphrase, _password]) {
      c.dispose();
    }
    super.dispose();
  }

  bool get _ready {
    final ok =
        _machineName.hasMatch(_name.text.trim()) &&
        _host.text.trim().isNotEmpty &&
        _user.text.trim().isNotEmpty;
    if (!ok) return false;
    if (_auth == 'key') {
      return _keyWay == 'generate' || _privateKey.text.trim().isNotEmpty || m?.auth == 'key';
    }
    return _password.text.isNotEmpty || (m?.hasPassword ?? false);
  }

  Map<String, Object?> get _access => {
    'everyone': _everyone,
    'agents': [..._agents],
    'projects': [..._projects],
  };

  Future<void> _save() async {
    final l = AppLocalizations.of(context);
    final c = sysClient(context);
    if (c == null) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    final port = int.tryParse(_port.text.trim()) ?? 22;
    try {
      final mm = m;
      if (mm != null) {
        await c.updateMachine(mm.id, {
          'name': _name.text.trim(),
          'host': _host.text.trim(),
          'port': port,
          'user': _user.text.trim(),
          'folder': _folder.text.trim().isEmpty ? null : _folder.text.trim(),
          'access': _access,
          if (_auth == 'password' && _password.text.isNotEmpty) 'password': _password.text,
          if (_auth == 'key' && _keyWay == 'paste' && _privateKey.text.trim().isNotEmpty) ...{
            'privateKey': _privateKey.text,
            'passphrase': _passphrase.text.isEmpty ? null : _passphrase.text,
          },
          if (_auth == 'key' && _keyWay == 'generate' && mm.auth == 'password') 'newKey': true,
        });
      } else {
        await c.addMachine({
          'name': _name.text.trim(),
          'host': _host.text.trim(),
          'port': port,
          'user': _user.text.trim(),
          'auth': _auth,
          if (_folder.text.trim().isNotEmpty) 'folder': _folder.text.trim(),
          if (_auth == 'key' && _keyWay == 'paste') ...{
            'privateKey': _privateKey.text,
            if (_passphrase.text.isNotEmpty) 'passphrase': _passphrase.text,
          },
          if (_auth == 'password') 'password': _password.text,
          'access': _access,
        });
      }
      if (mounted) Navigator.of(context).pop();
    } on ApiException catch (e) {
      if (mounted) setState(() => _error = sysError(l, e));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _newKey() async {
    final l = AppLocalizations.of(context);
    final mm = m;
    if (mm == null) return;
    final yes = await askConfirm(
      context,
      title: l.syMcNewKeyQ,
      body: l.syMcNewKeyText,
      yes: l.syMcNewKey,
    );
    if (!yes || !mounted) return;
    final c = sysClient(context);
    if (c == null) return;
    try {
      await c.updateMachine(mm.id, {'newKey': true});
      if (mounted) Navigator.of(context).pop();
    } on ApiException catch (e) {
      if (mounted) setState(() => _error = sysError(l, e));
    }
  }

  Widget _chips(List<(String, String)> options, Set<String> chosen) {
    final c = RgColors.of(context);
    return Wrap(
      spacing: 6,
      runSpacing: 6,
      children: [
        for (final (id, label) in options)
          Semantics(
            button: true,
            selected: chosen.contains(id),
            child: InkWell(
              key: Key('sy-mc-chip-$id'),
              borderRadius: BorderRadius.circular(99),
              onTap: () => setState(() => chosen.contains(id) ? chosen.remove(id) : chosen.add(id)),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: chosen.contains(id) ? c.accentSoft : c.panel2,
                  borderRadius: BorderRadius.circular(99),
                  border: Border.all(color: chosen.contains(id) ? c.accent : c.line),
                ),
                child: Text(label, style: TextStyle(color: c.text, fontSize: 13)),
              ),
            ),
          ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final c = RgColors.of(context);
    final app = AppScope.of(context);
    final workers = app.agents
        .where((a) => a.kind != AgentKind.demigod && a.kind != AgentKind.inspector)
        .toList();
    void touch(String _) => setState(() {});
    return AlertDialog(
      title: Text(m?.name ?? l.syMcNew),
      content: SizedBox(
        width: 520,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SysText(l.syMcEditorLead),
              SysField(
                label: l.syMcName,
                help: l.syMcNameHelp,
                controller: _name,
                hint: 'web',
                fieldKey: const Key('sy-mc-name'),
                onChanged: touch,
              ),
              SysField(
                label: l.syMcHost,
                help: l.syMcHostHelp,
                controller: _host,
                hint: 'server.example.com',
                fieldKey: const Key('sy-mc-host'),
                onChanged: touch,
              ),
              SysField(
                label: l.syMcUser,
                controller: _user,
                hint: 'deploy',
                fieldKey: const Key('sy-mc-user'),
                onChanged: touch,
              ),
              SysField(
                label: l.syMcFolder,
                help: l.syMcFolderHelp,
                controller: _folder,
                hint: '/srv/app',
              ),
              SysText(l.syMcLogin, dim: false, strong: true),
              SysSeg<String>(
                keyPrefix: 'sy-mc-auth',
                value: _auth,
                onChanged: (v) => setState(() => _auth = v),
                options: [('key', l.syMcAuthKey), ('password', l.syMcAuthPassword)],
              ),
              if (_auth == 'key') ...[
                SysSeg<String>(
                  keyPrefix: 'sy-mc-keyway',
                  value: _keyWay,
                  onChanged: (v) => setState(() => _keyWay = v),
                  options: [
                    ('generate', m?.auth == 'key' ? l.syMcKeyKeep : l.syMcKeyGenerate),
                    ('paste', l.syMcKeyPaste),
                  ],
                ),
                if (_keyWay == 'generate')
                  SysText(m?.auth == 'key' ? l.syMcKeyKeepHelp : l.syMcKeyGenerateHelp),
                if (_keyWay == 'paste') ...[
                  SysField(
                    label: l.syMcPrivateKey,
                    help: l.syMcPrivateKeyHelp,
                    hint: l.syMcPrivateKeyPlaceholder,
                    controller: _privateKey,
                    lines: 5,
                    onChanged: touch,
                  ),
                  SysField(label: l.syMcPassphrase, controller: _passphrase, secret: true),
                ],
              ],
              if (_auth == 'password')
                SysField(
                  label: l.syMcPassword,
                  help: (m?.hasPassword ?? false) ? l.syMcPasswordKept : l.syMcPasswordHelp,
                  controller: _password,
                  fieldKey: const Key('sy-mc-password'),
                  secret: true,
                  onChanged: touch,
                ),
              SysSub(l.syMcWho, lead: l.syMcWhoLead, inside: true),
              SwitchLine(
                key: const Key('sy-mc-everyone'),
                title: l.syMcWhoEveryone,
                help: l.syMcWhoEveryoneHelp,
                on: _everyone,
                onChanged: (v) => setState(() => _everyone = v),
              ),
              if (!_everyone) ...[
                SysText(l.syMcWhoAgents, dim: false, strong: true),
                if (workers.isEmpty)
                  SysText(l.syMcWhoNoAgents)
                else
                  _chips([for (final a in workers) (a.id, a.name)], _agents),
                if (app.projects.isNotEmpty) ...[
                  SysText(l.syMcWhoProjects, dim: false, strong: true),
                  _chips([for (final p in app.projects) (p.id, p.name)], _projects),
                ],
              ],
              SysFold(
                label: l.syUiAdvanced,
                children: [
                  SysField(label: l.syMcPort, controller: _port),
                  if (m?.auth == 'key')
                    Align(
                      alignment: Alignment.centerLeft,
                      child: TextButton.icon(
                        key: const Key('sy-mc-newkey'),
                        onPressed: _newKey,
                        icon: RgIcon(RgIcons.key, size: 14, color: c.accent),
                        label: Text(l.syMcNewKey),
                      ),
                    ),
                ],
              ),
              if (_error != null) SysSaid(text: _error!),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.of(context).pop(), child: Text(l.syCancel)),
        FilledButton(
          key: const Key('sy-mc-save'),
          onPressed: _busy || !_ready ? null : _save,
          child: Text(m == null ? l.syMcAdd : l.syMcSave),
        ),
      ],
    );
  }
}

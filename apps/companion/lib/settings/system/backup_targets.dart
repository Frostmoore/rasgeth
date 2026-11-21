// G42.14: backups anywhere (the page's BackupTargets.tsx, inside Settings › System): a folder on
// the network reached without mounting anything (one of the person's SSH machines, an SMB share, a
// paired RedGiant), the host's disks when RedGiant runs in a container (named, with the host's
// steps filled in and looked at again every 10 s, «Do it for me» when the Proxmox host is one of
// the machines, after a yes or the disk's name typed to format it), and the backups there, each
// restorable after a yes.
import 'dart:async';

import 'package:flutter/material.dart';

import '../../api/client.dart';
import '../../l10n/app_localizations.dart';
import '../../theme/colors.dart';
import '../../ui/dialogs.dart';
import '../../ui/icons.dart';
import '../api/system_api.dart';
import 'infra_rules.dart';
import 'system_kit.dart';

/// A folder on the network, reached without mounting anything (works in containers too).
class NetworkTargets extends StatefulWidget {
  const NetworkTargets({super.key, required this.st, required this.reload});

  final StorageState st;
  final Future<void> Function() reload;

  @override
  State<NetworkTargets> createState() => _NetworkTargetsState();
}

class _NetworkTargetsState extends State<NetworkTargets> {
  late final Map<String, dynamic>? _dest = widget.st.destination;
  late String _kind = _dest?['kind'] == 'smb' || _dest?['kind'] == 'node'
      ? '${_dest!['kind']}'
      : 'sftp';
  Map<String, dynamic>? _tg;
  late String _machine = _dest?['kind'] == 'sftp' ? '${_dest!['machineId']}' : '';
  late final _path = TextEditingController(
    text: _dest?['kind'] == 'sftp' ? '${_dest!['path']}' : '',
  );
  late final _smbAddress = TextEditingController(text: _smbOf(_dest));
  late final _smbUser = TextEditingController(
    text: _dest?['kind'] == 'smb' ? '${_dest!['user']}' : '',
  );
  final _smbPassword = TextEditingController();
  late final _smbDomain = TextEditingController(
    text: _dest?['kind'] == 'smb' ? '${_dest!['domain'] ?? ''}' : '',
  );
  bool _busy = false;
  String? _error;

  static String _smbOf(Map<String, dynamic>? d) {
    if (d?['kind'] != 'smb') return '';
    final f = '${d!['folder'] ?? ''}';
    return '\\\\${d['host']}\\${d['share']}${f.isNotEmpty ? '\\${f.replaceAll('/', '\\')}' : ''}';
  }

  @override
  void initState() {
    super.initState();
    unawaited(_load());
  }

  @override
  void dispose() {
    for (final c in [_path, _smbAddress, _smbUser, _smbPassword, _smbDomain]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _load() async {
    final c = sysClient(context);
    if (c == null) return;
    try {
      final t = await c.setupBackupTargets();
      if (mounted) setState(() => _tg = t);
    } on ApiException catch (e) {
      if (mounted) setState(() => _error = sysError(AppLocalizations.of(context), e));
    }
  }

  Future<void> _done(Future<void> Function(RedGiantClient c) f) async {
    final l = AppLocalizations.of(context);
    final c = sysClient(context);
    if (c == null) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await f(c);
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
    final c = RgColors.of(context);
    final tg = _tg;
    final machines = [
      for (final m in tg?['machines'] is List ? tg!['machines'] as List : const [])
        if (m is Map) m,
    ];
    final nodes = [
      for (final n in tg?['nodes'] is List ? tg!['nodes'] as List : const [])
        if (n is Map) n,
    ];
    final smb = tg?['smb'] is Map ? tg!['smb'] as Map : const {};
    return Column(
      key: const Key('sy-net-targets'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SysSub(l.syFbNetTitle, lead: l.syFbNetLead, inside: true),
        SysSeg<String>(
          keyPrefix: 'sy-net',
          value: _kind,
          onChanged: (v) => setState(() => _kind = v),
          options: [('sftp', l.syFbNetSftp), ('smb', l.syFbNetSmb), ('node', l.syFbNetNode)],
        ),
        if (tg == null)
          const Padding(padding: EdgeInsets.all(8), child: RgSpinner(size: 16))
        else if (_kind == 'sftp') ...[
          if (machines.isEmpty)
            SysText(l.syFbNetNoMachines)
          else ...[
            SysTiles(
              children: [
                for (final m in machines)
                  SysTile(
                    key: Key('sy-sftp-${m['id']}'),
                    on: _machine == '${m['id']}',
                    icon: RgIcons.server,
                    title: '${m['name']}',
                    text: '${m['user']}@${m['host']}',
                    state: m['trusted'] == true ? l.syFbNetPick : l.syFbNetNotTrusted,
                    onTap: m['trusted'] == true
                        ? () => setState(() => _machine = '${m['id']}')
                        : null,
                  ),
              ],
            ),
            if (_machine.isNotEmpty) ...[
              SysField(
                label: l.syFbNetFolder,
                help: l.syFbNetFolderHelp,
                controller: _path,
                fieldKey: const Key('sy-sftp-path'),
                hint: '~/RedGiant-backups',
                onChanged: (_) => setState(() {}),
              ),
              SysActs(
                children: [
                  OutlinedButton.icon(
                    key: const Key('sy-sftp-use'),
                    onPressed: _busy || _path.text.trim().isEmpty
                        ? null
                        : () => _done((cl) => cl.setupBackupSftp(_machine, _path.text.trim())),
                    icon: RgIcon(RgIcons.folder, size: 16, color: c.text),
                    label: Text(l.syFbUseFolder),
                  ),
                ],
              ),
            ],
          ],
        ] else if (_kind == 'smb') ...[
          if (smb['available'] != true) SysNote(text: l.syFbSmbMissing),
          SysField(
            label: l.syFbSmbAddress,
            help: l.syFbSmbAddressHelp,
            controller: _smbAddress,
            fieldKey: const Key('sy-smb-address'),
            hint: r'\\nas\backup\Rasgeth',
            onChanged: (_) => setState(() {}),
          ),
          SysField(
            label: l.syFbSmbUser,
            controller: _smbUser,
            fieldKey: const Key('sy-smb-user'),
            onChanged: (_) => setState(() {}),
          ),
          SysField(
            label: l.syFbSmbPassword,
            help: smb['password'] == true ? l.syFbSmbPasswordKept : l.syFbSmbPasswordHelp,
            controller: _smbPassword,
            secret: true,
          ),
          SysField(label: l.syFbSmbDomain, help: l.syFbSmbDomainHelp, controller: _smbDomain),
          SysActs(
            children: [
              OutlinedButton.icon(
                key: const Key('sy-smb-use'),
                onPressed: _busy || _smbAddress.text.trim().isEmpty || _smbUser.text.trim().isEmpty
                    ? null
                    : () => _done((cl) async {
                        await cl.setupBackupSmb({
                          'address': _smbAddress.text.trim(),
                          'user': _smbUser.text.trim(),
                          if (_smbPassword.text.isNotEmpty) 'password': _smbPassword.text,
                          if (_smbDomain.text.trim().isNotEmpty) 'domain': _smbDomain.text.trim(),
                        });
                        _smbPassword.clear();
                      }),
                icon: RgIcon(RgIcons.folder, size: 16, color: c.text),
                label: Text(l.syFbUseShare),
              ),
            ],
          ),
        ] else if (nodes.isEmpty)
          SysText(l.syFbNetNoNodes)
        else
          SysTiles(
            children: [
              for (final n in nodes)
                SysTile(
                  on: _dest?['kind'] == 'node' && _dest?['fingerprint'] == n['fingerprint'],
                  icon: RgIcons.nodes,
                  title: '${n['name']}',
                  text: n['online'] == true ? l.syFbNodeOnline : l.syFbNodeOffline,
                  state: l.syFbUsePlace,
                  onTap: _busy
                      ? null
                      : () => _done((cl) => cl.setupBackupNode('${n['fingerprint']}')),
                ),
            ],
          ),
        if (_error != null) SysSaid(text: _error!),
      ],
    );
  }
}

const _hostKinds = {'lxc': 'proxmox', 'docker': 'docker'};

/// RedGiant in a container: the host's disks it sees, the host's steps to pass one in, a look
/// every 10 s for the folder to arrive, and «Do it for me» on Proxmox.
class HostDiskGuide extends StatefulWidget {
  const HostDiskGuide({super.key, required this.st, required this.reload});

  final StorageState st;
  final Future<void> Function() reload;

  @override
  State<HostDiskGuide> createState() => _HostDiskGuideState();
}

class _HostDiskGuideState extends State<HostDiskGuide> {
  late String _pick = widget.st.hostDisks.isNotEmpty ? '${widget.st.hostDisks.first['path']}' : '';
  late String _kind = _hostKinds[widget.st.container] ?? 'other';
  late final _ctid = TextEditingController(text: '${widget.st.containerHint?['id'] ?? ''}');
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 10), (_) => unawaited(widget.reload()));
  }

  @override
  void dispose() {
    _timer?.cancel();
    _ctid.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final c = RgColors.of(context);
    final disks = widget.st.hostDisks;
    final disk = disks.where((d) => '${d['path']}' == _pick).firstOrNull;
    final name = folderName('${disk?['title'] ?? 'backups'}');
    final guide = hostMountGuide(
      kind: _kind,
      name: name,
      device: disk == null ? null : '${disk['path']}',
      containerId: _kind == 'proxmox' && _ctid.text.trim().isNotEmpty ? _ctid.text.trim() : null,
      base: widget.st.backupBase,
    );
    String how(Map<dynamic, dynamic> d) =>
        d['transport'] == 'usb' ? 'USB' : '${d['transport'] ?? ''}';
    return Column(
      key: const Key('sy-host-guide'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SysSub(l.syFbHostTitle, lead: l.syFbHostLead, inside: true),
        if (disks.isNotEmpty) ...[
          SysText(
            disks.length == 1
                ? sw(l, 'fbHostOne', {
                    'title': '${disks.first['title']}',
                    'how': how(disks.first),
                    'size': sysSize(context, disks.first['sizeBytes'] as num? ?? 0, small: true),
                  })
                : sw(l, 'fbHostMany', {'n': '${disks.length}'}),
            dim: false,
          ),
          if (disks.length > 1)
            SysTiles(
              children: [
                for (final d in disks)
                  SysTile(
                    on: _pick == '${d['path']}',
                    icon: RgIcons.database,
                    title: '${d['title']}',
                    text: [
                      sysSize(context, d['sizeBytes'] as num? ?? 0, small: true),
                      how(d),
                      '${d['path']}',
                    ].where((x) => x.isNotEmpty).join(' · '),
                    onTap: () => setState(() => _pick = '${d['path']}'),
                  ),
              ],
            ),
        ] else
          SysText(l.syFbHostNone),
        SysSeg<String>(
          keyPrefix: 'sy-host-kind',
          value: _kind,
          onChanged: (v) => setState(() => _kind = v),
          options: [('proxmox', 'Proxmox'), ('docker', 'Docker'), ('other', l.syFbHostOther)],
        ),
        if (_kind == 'proxmox')
          SysField(
            label: l.syFbHostId,
            help: sw(l, 'fbHostIdHelp', {
              'hostname': '${widget.st.containerHint?['hostname'] ?? ''}',
            }),
            controller: _ctid,
            hint: '105',
            onChanged: (_) => setState(() {}),
          ),
        if (guide.ok)
          CopyBlock(text: guide.lines.join('\n'), label: l.syFbHostSteps)
        else
          SysNote(tone: 'error', icon: RgIcons.alert, text: sw(l, 'fbHostBad_${guide.why}')),
        Row(
          children: [
            RgIcon(RgIcons.refresh, size: 14, color: c.dim),
            const SizedBox(width: 6),
            Expanded(
              child: SysText(sw(l, 'fbHostWatching', {'target': guide.ok ? guide.target : ''})),
            ),
          ],
        ),
        if (_kind == 'proxmox')
          _DoItForMe(name: name, ctid: _ctid.text.trim(), reload: widget.reload),
      ],
    );
  }
}

/// «Do it for me»: the Proxmox host is one of the machines; RedGiant runs the steps after a yes.
class _DoItForMe extends StatefulWidget {
  const _DoItForMe({required this.name, required this.ctid, required this.reload});

  final String name;
  final String ctid;
  final Future<void> Function() reload;

  @override
  State<_DoItForMe> createState() => _DoItForMeState();
}

class _DoItForMeState extends State<_DoItForMe> {
  Map<String, dynamic>? _hosts;
  bool _looking = false;
  String? _jobId;
  Map<String, String>? _ended;
  String? _error;

  Future<void> _look() async {
    final l = AppLocalizations.of(context);
    final c = sysClient(context);
    if (c == null) return;
    setState(() => _looking = true);
    try {
      final h = await c.setupProxmoxHosts();
      if (mounted) setState(() => _hosts = h);
    } on ApiException catch (e) {
      if (mounted) setState(() => _error = sysError(l, e));
    } finally {
      if (mounted) setState(() => _looking = false);
    }
  }

  Future<void> _run(Map<dynamic, dynamic> h, Map<dynamic, dynamic> d, bool format) async {
    final l = AppLocalizations.of(context);
    final c = sysClient(context);
    if (c == null) return;
    final id = widget.ctid.isNotEmpty ? widget.ctid : '${h['guess'] ?? ''}';
    if (id.isEmpty) {
      setState(() => _error = l.syFbPveNeedId);
      return;
    }
    String? typed;
    if (format) {
      typed = await askText(
        context,
        title: sw(l, 'fbPveFormatQ', {'title': '${d['title']}'}),
        hint: sw(l, 'fbPveFormatLabel', {'title': '${d['title']}'}),
        yes: l.syFbPveFormatYes,
      );
      if (typed == null) return;
    } else {
      final yes = await askConfirm(
        context,
        title: sw(l, 'fbPveQ', {'title': '${d['title']}', 'host': '${h['name']}', 'id': id}),
        body: l.syFbPveText,
        yes: l.syFbPveYes,
      );
      if (!yes) return;
    }
    try {
      final f = folderName('${d['title']}');
      final j = await c.setupProxmoxMount({
        'machineId': h['machineId'],
        'ctid': id,
        'device': d['path'],
        'name': f.isEmpty ? widget.name : f,
        'format': ?typed,
      });
      if (mounted) {
        setState(() {
          _jobId = j.id;
          _ended = null;
        });
      }
    } on ApiException catch (e) {
      if (mounted) setState(() => _error = sysError(l, e));
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final c = RgColors.of(context);
    final hosts = [
      for (final h in _hosts?['hosts'] is List ? _hosts!['hosts'] as List : const [])
        if (h is Map) h,
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SysSub(l.syFbPveTitle, lead: l.syFbPveLead, inside: true),
        SysActs(
          start: true,
          children: [
            OutlinedButton.icon(
              key: const Key('sy-pve-look'),
              onPressed: _looking ? null : _look,
              icon: RgIcon(RgIcons.server, size: 16, color: c.text),
              label: Text(l.syFbPveLook),
            ),
          ],
        ),
        if (_hosts != null && hosts.isEmpty)
          SysText(sw(l, 'fbPveNone', {'n': '${_hosts!['checked'] ?? 0}'})),
        for (final h in hosts) ...[
          SysText(
            [
              sw(l, 'fbPveHost', {'name': '${h['name']}', 'version': '${h['proxmox']}'}),
              if (h['guess'] != null) sw(l, 'fbPveGuess', {'id': '${h['guess']}'}),
            ].join(' '),
            dim: false,
          ),
          if ((h['disks'] as List? ?? const []).isEmpty)
            SysText(l.syFbPveNoDisks)
          else
            SysTiles(
              children: [
                for (final d in (h['disks'] as List).whereType<Map<dynamic, dynamic>>())
                  SysTile(
                    on: false,
                    icon: RgIcons.database,
                    title: '${d['title']}',
                    text: [
                      sysSize(context, d['sizeBytes'] as num? ?? 0, small: true),
                      d['transport'] == 'usb' ? 'USB' : '${d['transport'] ?? ''}',
                      '${d['fstype'] ?? ''}',
                      '${d['path']}',
                    ].where((x) => x.isNotEmpty).join(' · '),
                    state: d['usable'] == true
                        ? l.syFbPveDo
                        : (d['why'] == 'no_filesystem' ? l.syFbPveFormat : l.syFbWhyFs),
                    onTap: d['usable'] == true
                        ? () => _run(h, d, false)
                        : (d['why'] == 'no_filesystem' ? () => _run(h, d, true) : null),
                  ),
              ],
            ),
        ],
        if (_jobId != null)
          SysJob(
            id: _jobId!,
            onEnd: (state, vars) {
              if (mounted && state == 'done') setState(() => _ended = vars);
              if (state == 'done') unawaited(widget.reload());
            },
          ),
        if (_ended != null)
          SysNote(
            tone: 'ok',
            icon: RgIcons.check,
            text: sw(l, _ended!['arrived'] == '1' ? 'fbPveDone' : 'fbPveRestart', {
              'target': _ended!['target'] ?? '',
            }),
          ),
        if (_error != null) SysSaid(text: _error!),
      ],
    );
  }
}

/// The backups in the destination, newest first, each one restorable after a yes.
class BackupList extends StatefulWidget {
  const BackupList({super.key});

  @override
  State<BackupList> createState() => _BackupListState();
}

class _BackupListState extends State<BackupList> {
  Map<String, dynamic>? _list;
  bool _busy = false;
  String? _jobId;
  bool _restoring = false;
  Map<String, String>? _done;
  String? _error;

  Future<void> _load() async {
    final l = AppLocalizations.of(context);
    final c = sysClient(context);
    if (c == null) return;
    setState(() => _busy = true);
    try {
      final r = await c.setupBackupList();
      if (mounted) setState(() => _list = r);
    } on ApiException catch (e) {
      if (mounted) setState(() => _error = sysError(l, e));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _restore(Map<dynamic, dynamic> b) async {
    final l = AppLocalizations.of(context);
    final c = sysClient(context);
    if (c == null) return;
    final when = b['at'] is String ? sysWhen(b['at'] as String) : '${b['folder']}';
    final yes = await askConfirm(
      context,
      title: sw(l, 'fbRestoreQ', {'when': when}),
      body: l.syFbRestoreText,
      yes: l.syFbRestoreYes,
    );
    if (!yes) return;
    try {
      final j = await c.setupBackupRestore('${b['id']}');
      if (mounted) {
        setState(() {
          _jobId = j.id;
          _restoring = true;
          _done = null;
        });
      }
    } on ApiException catch (e) {
      if (mounted) setState(() => _error = sysError(l, e));
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final c = RgColors.of(context);
    final list = _list;
    final items = [
      for (final b in list?['backups'] is List ? list!['backups'] as List : const [])
        if (b is Map) b,
    ];
    return Column(
      key: const Key('sy-backup-list'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SysSub(l.syFbListTitle, lead: l.syFbListLead, inside: true),
        SysActs(
          start: true,
          children: [
            OutlinedButton.icon(
              key: const Key('sy-list-show'),
              onPressed: _busy ? null : _load,
              icon: RgIcon(RgIcons.refresh, size: 16, color: c.text),
              label: Text(list == null ? l.syFbListShow : l.syFbListAgain),
            ),
          ],
        ),
        if (list != null && items.isEmpty)
          SysText(sw(l, 'fbListEmpty', {'where': '${list['where']}'})),
        for (final b in items)
          SysRow(
            key: Key('sy-bk-${b['id']}'),
            title: b['at'] is String ? sysWhen(b['at'] as String) : '${b['folder']}',
            help: '${b['file']} · ${sysSize(context, b['bytes'] as num? ?? 0, small: true)}',
            trailing: [
              OutlinedButton.icon(
                key: Key('sy-restore-${b['id']}'),
                onPressed: _restoring ? null : () => _restore(b),
                icon: RgIcon(RgIcons.restore, size: 16, color: c.text),
                label: Text(l.syFbRestore),
              ),
            ],
          ),
        if (_jobId != null)
          SysJob(
            id: _jobId!,
            showDone: false,
            onEnd: (state, vars) {
              if (!mounted) return;
              setState(() {
                _restoring = false;
                if (state == 'done') _done = vars;
              });
            },
          ),
        if (_done != null)
          SysNote(
            tone: 'ok',
            icon: RgIcons.check,
            text: sw(l, 'backupImported', {
              'projects': _done!['projects'] ?? '0',
              'agents': _done!['agents'] ?? '0',
              'conversations': _done!['conversations'] ?? '0',
            }),
          ),
        if (_error != null) SysSaid(text: _error!),
      ],
    );
  }
}

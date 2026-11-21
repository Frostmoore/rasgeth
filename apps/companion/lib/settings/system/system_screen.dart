// Settings › System (G42.14), the page's SystemSettings (FirstBoot.tsx): what the machine is
// (processor, memory, architecture, virtual or not, cards, disks: what the system does not tell is
// said so), what it can run, the role (a complete RedGiant or a node of another one, changed only
// after a yes, with the node's pairing), where the data lives and where backups go (a folder the
// host mounted, a removable disk, a folder, a folder on the network; when they run, how many stay,
// the last one, «a backup now», the backups there to restore), RedGiant OS's network (Wi-Fi,
// HTTPS in the home network), SSH into the machine and the system's updates with the restart.
import 'dart:async';

import 'package:flutter/material.dart';

import '../../api/client.dart';
import '../../l10n/app_localizations.dart';
import '../../theme/colors.dart';
import '../../ui/dialogs.dart';
import '../../ui/icons.dart';
import '../../ui/settings_kit.dart';
import '../api/system_api.dart';
import 'backup_targets.dart';
import 'nodes_screen.dart' show PairForm, PendingCards;
import 'os_panels.dart';
import 'system_kit.dart';

Future<void> openSystemSettings(BuildContext context) =>
    openSystemScreen(context, const SystemSettingsScreen());

const virtNames = {
  'kvm': 'KVM',
  'qemu': 'QEMU',
  'vmware': 'VMware',
  'oracle': 'VirtualBox',
  'microsoft': 'Hyper-V',
  'xen': 'Xen',
  'docker': 'Docker',
  'podman': 'Podman',
  'lxc': 'LXC',
  'wsl': 'WSL',
  'kubernetes': 'Kubernetes',
};

class SystemSettingsScreen extends StatefulWidget {
  const SystemSettingsScreen({super.key});

  @override
  State<SystemSettingsScreen> createState() => _SystemSettingsScreenState();
}

class _SystemSettingsScreenState extends State<SystemSettingsScreen> {
  SystemSetup? _s;
  String? _error;

  @override
  void initState() {
    super.initState();
    unawaited(_load());
  }

  Future<void> _load() async {
    final c = sysClient(context);
    if (c == null) return;
    try {
      final s = await c.systemSetup();
      if (mounted) setState(() => _s = s);
    } on ApiException catch (e) {
      if (mounted) setState(() => _error = sysError(AppLocalizations.of(context), e));
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final s = _s;
    return SettingsScaffold(
      title: l.syFbSystemSection,
      backKey: const Key('sy-system-back'),
      backLabel: l.back,
      listKey: const Key('sy-system-list'),
      children: [
        SysHead(q: l.syFbSystemQ, lead: l.syFbSystemLead),
        if (_error != null) NoticeBanner(text: _error!, error: true),
        if (s == null && _error == null)
          const Padding(
            padding: EdgeInsets.all(24),
            child: Center(child: RgSpinner(size: 22)),
          ),
        if (s != null) ...[
          SysBox(
            key: const Key('sy-machine'),
            icon: RgIcons.cpu,
            title: l.syFbMachineTitle,
            children: [
              if (s.system != null) MachineFacts(sys: s.system!),
              _OfferNote(offer: s.offer),
            ],
          ),
          SysSub(l.syFbRoleTitle, lead: l.syFbRoleSettingsLead),
          _RoleChoice(s: s, reload: _load),
          SysSub(l.syWzStorage),
          const StoragePanel(),
          const OsNetworkSection(),
          const SshPanel(),
          const OsUpdatesSection(),
        ],
      ],
    );
  }
}

/// A reading, or why it is missing («not available here», «not readable»…).
String foundText(AppLocalizations l, Found f, String Function(Object v) show) =>
    f.missing == null ? show(f.value!) : sw(l, 'fbMissing_${f.missing}');

/// What the machine is: processor, memory, architecture, disks, cards, virtual or not.
class MachineFacts extends StatelessWidget {
  const MachineFacts({super.key, required this.sys});

  final SystemInfo sys;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    String n(num x) => sysNum(context, x);
    final disks = sys.disks.missing == null
        ? [
            for (final d in sys.disks.value as List? ?? const [])
              if (d is Map<String, dynamic>) BlockDisk(d),
          ]
        : const <BlockDisk>[];
    final parts = {
      for (final d in disks)
        if (d.type == 'part') d.disk,
    };
    final whole = [
      for (final d in disks)
        if (d.type == 'part' || !parts.contains(d.name)) d,
    ];
    return SysFacts([
      (l.syWzCpu, '${sys.cpuModel} · ${sw(l, 'wzThreads', {'n': '${sys.cores}'})}'),
      (
        l.syWzMemory,
        '${sw(l, 'fbRamTotal', {'gb': n(sys.ramGb)})} · ${foundText(l, sys.ramFree, (g) => sw(l, 'fbRamFree', {'gb': n(g as num)}))}',
      ),
      (
        l.syFbArch,
        '${sys.arch} · ${sys.os == 'win32' ? 'Windows' : (sys.os == 'darwin' ? 'macOS' : 'Linux')}',
      ),
      (
        l.syFbVirt,
        foundText(l, sys.virt, (v) {
          final m = v as Map;
          if (m['kind'] == 'none') return l.syFbVirtNone;
          return sw(l, m['kind'] == 'vm' ? 'fbVirtVm' : 'fbVirtContainer', {
            'name': virtNames['${m['name']}'] ?? '${m['name']}',
          });
        }),
      ),
      (
        l.syWzGpu,
        foundText(l, sys.gpus, (g) {
          final list = g as List;
          if (list.isEmpty) return l.syWzNoGpu;
          return [
            for (final x in list.whereType<Map<dynamic, dynamic>>())
              '${x['name']}${x['vramGb'] is num && x['vramGb'] != 0 ? ' (${n(x['vramGb'] as num)} GB)' : ''}',
          ].join(', ');
        }),
      ),
      (
        l.syFbDisks,
        sys.disks.missing != null
            ? sw(l, 'fbMissing_${sys.disks.missing}')
            : Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [for (final d in whole) _DiskLine(d: d)],
              ),
      ),
    ]);
  }
}

class _DiskLine extends StatelessWidget {
  const _DiskLine({required this.d});

  final BlockDisk d;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final c = RgColors.of(context);
    final kind = d.transport == 'usb' ? 'USB' : (d.removable || d.hotplug ? l.syFbRemovable : '');
    final rest = [
      sysSize(context, d.sizeBytes),
      if (d.freeBytes != null) sw(l, 'fbFreeOf', {'free': sysSize(context, d.freeBytes!)}),
      kind,
      d.mountpoint,
    ].where((x) => x.isNotEmpty).join(' · ');
    return Padding(
      padding: const EdgeInsets.only(bottom: 2),
      child: Text.rich(
        TextSpan(
          children: [
            TextSpan(
              text: d.title,
              style: TextStyle(fontWeight: FontWeight.w700, color: c.text),
            ),
            TextSpan(
              text: '  $rest',
              style: TextStyle(color: c.dim),
            ),
          ],
        ),
        style: const TextStyle(fontSize: 13.5),
      ),
    );
  }
}

class _OfferNote extends StatelessWidget {
  const _OfferNote({required this.offer});

  final Map<String, dynamic> offer;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final max = offer['maxModelGb'] is num ? offer['maxModelGb'] as num : 0;
    return SysNote(
      icon: RgIcons.zap,
      text:
          '${l.syFbOfferCloud} ${offer['local'] == true ? sw(l, offer['reason'] == 'gpu' ? 'fbOfferLocalGpu' : 'fbOfferLocalCpu', {'max': sysNum(context, max)}) : l.syFbOfferNoLocal}',
    );
  }
}

// ---- the role ----

class _RoleChoice extends StatelessWidget {
  const _RoleChoice({required this.s, required this.reload});

  final SystemSetup s;
  final Future<void> Function() reload;

  Future<void> _choose(BuildContext context, String r) async {
    if (r == s.role) return;
    final l = AppLocalizations.of(context);
    final node = r == 'node';
    final yes = await askConfirm(
      context,
      title: node ? l.syFbToNodeQ : l.syFbToFullQ,
      body: node ? l.syFbToNodeText : l.syFbToFullText,
      yes: node ? l.syFbToNodeYes : l.syFbToFullYes,
      danger: node,
    );
    if (!yes || !context.mounted) return;
    final c = sysClient(context);
    if (c == null) return;
    try {
      await c.setupRole(r, confirm: true);
      await reload();
    } on ApiException catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(sysError(l, e))));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final tiles = [
      SysTile(
        key: const Key('sy-role-full'),
        on: s.role == 'full',
        icon: RgIcons.home,
        title: l.syFbRoleFull,
        badge: l.syWzRecommended,
        text: l.syFbRoleFullText,
        onTap: () => _choose(context, 'full'),
      ),
      SysTile(
        key: const Key('sy-role-node'),
        on: s.role == 'node',
        icon: RgIcons.nodes,
        title: l.syFbRoleNode,
        text: l.syFbRoleNodeText,
        onTap: () => _choose(context, 'node'),
      ),
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: SysTiles(children: tiles),
        ),
        if (s.role == 'node') const _NodePairing(),
      ],
    );
  }
}

/// The node's pairing (G39.4): the principal's address and its code, then the six digits.
class _NodePairing extends StatefulWidget {
  const _NodePairing();

  @override
  State<_NodePairing> createState() => _NodePairingState();
}

class _NodePairingState extends State<_NodePairing> {
  NodesState? _s;

  @override
  void initState() {
    super.initState();
    unawaited(_load());
  }

  Future<void> _load() async {
    final c = sysClient(context);
    if (c == null) return;
    try {
      final s = await c.nodes();
      if (mounted) setState(() => _s = s);
    } on ApiException {
      // Nothing to show yet.
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final s = _s;
    if (s == null) return const SizedBox.shrink();
    final p = s.parent;
    return SysBox(
      children: [
        if (p != null)
          SysText(
            '${l.syNdParent}: ${p.name} (${p.status == 'online' ? l.syNdOnline : l.syNdOffline})',
          )
        else if (s.pending.isNotEmpty)
          PendingCards(s: s, reload: _load)
        else ...[
          SysText(l.syFbPairLater),
          PairForm(reload: _load),
        ],
      ],
    );
  }
}

// ---- storage and backups ----

const _days = ['fbSun', 'fbMon', 'fbTue', 'fbWed', 'fbThu', 'fbFri', 'fbSat'];
const _whyDisk = {
  'not_removable': 'fbWhyNotRemovable',
  'system_disk': 'fbWhySystem',
  'no_filesystem': 'fbWhyNoFs',
  'unsupported_filesystem': 'fbWhyFs',
  'no_uuid': 'fbWhyNoUuid',
  'not_a_disk': 'fbWhyNotDisk',
};

/// Where backups go, in a sentence (BackupTargets' `destText`).
String destText(AppLocalizations l, Map<String, dynamic> d) {
  String s(String k) => '${d[k] ?? ''}';
  return switch (d['kind']) {
    'disk' => sw(l, 'fbDestDisk', {'label': s('label'), 'path': s('path')}),
    'folder' => sw(l, 'fbDestFolder', {'path': s('path')}),
    'sftp' => sw(l, 'fbDestSftp', {'machine': s('machineName'), 'path': s('path')}),
    'smb' => sw(l, 'fbDestSmb', {
      'path':
          '\\\\${s('host')}\\${s('share')}${s('folder').isNotEmpty ? '\\${s('folder').replaceAll('/', '\\')}' : ''}',
      'user': s('user'),
    }),
    _ => sw(l, 'fbDestNode', {'name': s('name')}),
  };
}

/// Why the last backup failed, in the page's words when the code is known.
String failText(AppLocalizations l, Map<String, dynamic> last) {
  final code = last['code'];
  return (code is String ? syWordOrNull(l, 'fbErr_$code') : null) ?? '${last['error'] ?? ''}';
}

String? syWordOrNull(AppLocalizations l, String key) {
  final w = sw(l, key);
  return w == key ? null : w;
}

/// The data folder, the places and disks for backups (or a folder), when they run, «a backup
/// now», the backups there.
class StoragePanel extends StatefulWidget {
  const StoragePanel({super.key});

  @override
  State<StoragePanel> createState() => _StoragePanelState();
}

class _StoragePanelState extends State<StoragePanel> {
  StorageState? _st;
  final _folder = TextEditingController();
  String? _msg;
  String? _error;

  @override
  void initState() {
    super.initState();
    unawaited(_load());
  }

  @override
  void dispose() {
    _folder.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final c = sysClient(context);
    if (c == null) return;
    try {
      final st = await c.setupStorage();
      if (mounted) setState(() => _st = st);
    } on ApiException catch (e) {
      if (mounted) setState(() => _error = sysError(AppLocalizations.of(context), e));
    }
  }

  Future<void> _do(Future<void> Function(RedGiantClient c) f) async {
    final c = sysClient(context);
    if (c == null) return;
    final l = AppLocalizations.of(context);
    setState(() => _error = null);
    try {
      await f(c);
      await _load();
    } on ApiException catch (e) {
      if (mounted) setState(() => _error = sysError(l, e));
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final st = _st;
    if (st == null) {
      return _error != null
          ? NoticeBanner(text: _error!, error: true)
          : const Padding(
              padding: EdgeInsets.all(16),
              child: Center(child: RgSpinner(size: 18)),
            );
    }
    final dest = st.destination;
    final sch = st.schedule;
    final every = '${sch['every'] ?? 'daily'}';
    final hour = sch['hour'] is num ? (sch['hour'] as num).toInt() : 3;
    final keep = sch['keep'] is num ? (sch['keep'] as num).toInt() : 7;
    final weekday = sch['weekday'] is num ? (sch['weekday'] as num).toInt() : 0;
    final last = st.last;
    String n(num? x) => sysNum(context, x ?? 0);
    return Column(
      key: const Key('sy-storage'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SysBox(
          icon: RgIcons.database,
          title: l.syFbDataTitle,
          q: l.syFbDataQ,
          children: [
            SysFacts([
              (l.syFbDataDir, SysMono(st.dataDir)),
              (
                l.syWzFree,
                st.dataFreeGb != null
                    ? sw(l, 'fbFreeOfTotal', {'free': n(st.dataFreeGb), 'total': n(st.dataTotalGb)})
                    : sw(l, 'fbMissing_unreadable'),
              ),
            ]),
          ],
        ),
        SysBox(
          key: const Key('sy-backups'),
          icon: RgIcons.archive,
          title: l.syFbBackupTitle,
          q: l.syFbBackupQ,
          children: [
            if (dest != null)
              SysNote(key: const Key('sy-dest'), icon: RgIcons.archive, text: destText(l, dest)),
            if (st.places.isNotEmpty) ...[
              SysSub(l.syFbPlacesTitle, lead: l.syFbPlacesLead, inside: true),
              SysTiles(
                children: [
                  for (final p in st.places)
                    SysTile(
                      on:
                          dest?['kind'] == 'folder' &&
                          ('${dest?['path']}' == '${p['path']}' ||
                              '${dest?['path']}'.startsWith('${p['path']}/')),
                      icon: RgIcons.folder,
                      title: '${p['name']}',
                      text: [
                        '${p['path']}',
                        if (p['freeGb'] is num)
                          sw(l, 'fbPlaceFree', {
                            'free': n(p['freeGb'] as num),
                            'total': n(p['totalGb'] is num ? p['totalGb'] as num : 0),
                          }),
                      ].join(' · '),
                      state: p['usable'] == true ? l.syFbUsePlace : l.syFbPlaceNotWritable,
                      onTap: p['usable'] == true
                          ? () => _do((c) => c.setupBackupPlace('${p['path']}'))
                          : null,
                    ),
                ],
              ),
            ],
            if (st.container != null)
              SysNote(
                text: sw(l, 'fbContainerDisks', {'name': virtNames[st.container] ?? st.container!}),
              )
            else
              SysSub(l.syFbDisksTitle, lead: sw(l, 'fbMethod_${st.method}'), inside: true),
            if (st.container != null) HostDiskGuide(st: st, reload: _load),
            if (st.container == null)
              st.candidates.isEmpty
                  ? SysText(l.syFbNoDisks)
                  : SysTiles(
                      children: [
                        for (final d in st.candidates)
                          SysTile(
                            key: Key('sy-disk-${d.uuid}'),
                            on: dest?['kind'] == 'disk' && dest?['uuid'] == d.uuid,
                            icon: RgIcons.database,
                            title: d.title,
                            text: [
                              sysSize(context, d.sizeBytes),
                              d.transport == 'usb' ? 'USB' : l.syFbRemovable,
                              d.fstype,
                            ].where((x) => x.isNotEmpty).join(' · '),
                            state: d.usable
                                ? (st.method == 'none' && d.mountpoint.isEmpty
                                      ? l.syFbCannotMount
                                      : l.syFbUseDisk)
                                : sw(l, _whyDisk[d.why ?? ''] ?? 'fbWhyNotDisk'),
                            onTap: d.usable && (st.method != 'none' || d.mountpoint.isNotEmpty)
                                ? () => _do((c) => c.setupBackupDisk(d.uuid))
                                : null,
                          ),
                      ],
                    ),
            SysSub(l.syFbFolderTitle, lead: l.syFbFolderLead, inside: true),
            SysField(
              label: l.syFbFolderPath,
              controller: _folder,
              fieldKey: const Key('sy-folder'),
              hint: st.places.isNotEmpty ? '${st.places.first['path']}' : null,
              onChanged: (_) => setState(() {}),
            ),
            SysActs(
              children: [
                OutlinedButton.icon(
                  key: const Key('sy-folder-use'),
                  onPressed: _folder.text.trim().isEmpty
                      ? null
                      : () => _do((c) async {
                          await c.setupBackupFolder(_folder.text.trim());
                          _folder.clear();
                        }),
                  icon: RgIcon(RgIcons.folder, size: 16, color: RgColors.of(context).text),
                  label: Text(l.syFbUseFolder),
                ),
              ],
            ),
            NetworkTargets(st: st, reload: _load),
            if (dest != null) ...[
              SysSub(l.syFbWhenTitle, inside: true),
              SysSeg<String>(
                keyPrefix: 'sy-every',
                value: every,
                onChanged: (v) => _do(
                  (c) => c.setupBackupSchedule({'every': v, if (v == 'weekly') 'weekday': 0}),
                ),
                options: [('daily', l.syFbDaily), ('weekly', l.syFbWeekly), ('off', l.syFbOff)],
              ),
              if (every != 'off') ...[
                if (every == 'weekly')
                  SysSeg<int>(
                    keyPrefix: 'sy-day',
                    value: weekday,
                    onChanged: (d) => _do((c) => c.setupBackupSchedule({'weekday': d})),
                    options: [for (final (i, k) in _days.indexed) (i, sw(l, k))],
                  ),
                SysStepper(
                  keyPrefix: 'sy-hour',
                  label: l.syFbHour,
                  value: hour,
                  min: 0,
                  max: 23,
                  show: (h) => '${h.toString().padLeft(2, '0')}:00',
                  onChanged: (h) => _do((c) => c.setupBackupSchedule({'hour': h})),
                ),
                SysStepper(
                  keyPrefix: 'sy-keep',
                  label: l.syFbKeep,
                  value: keep,
                  min: 1,
                  max: 60,
                  show: (k) => sw(l, 'fbKeepN', {'n': '$k'}),
                  onChanged: (k) => _do((c) => c.setupBackupSchedule({'keep': k})),
                ),
              ],
              if (last != null)
                last['ok'] == true
                    ? SysText(sw(l, 'fbLastOk', {'when': sysWhen('${last['at']}')}))
                    : SysNote(
                        tone: 'error',
                        icon: RgIcons.alert,
                        text: sw(l, 'fbLastFailed', {
                          'when': sysWhen('${last['at']}'),
                          'why': failText(l, last),
                        }),
                      ),
              SysActs(
                children: [
                  FilledButton.icon(
                    key: const Key('sy-backup-now'),
                    onPressed: st.running
                        ? null
                        : () async {
                            final c = sysClient(context);
                            if (c == null) return;
                            try {
                              final started = await c.setupBackupRun();
                              if (mounted) {
                                setState(
                                  () => _msg = started ? l.syFbBackupStarted : l.syFbBackupBusy,
                                );
                              }
                            } on ApiException catch (e) {
                              if (mounted) setState(() => _error = sysError(l, e));
                            }
                          },
                    icon: const RgIcon(RgIcons.archive, size: 16, color: Colors.white),
                    label: Text(l.syFbBackupNow),
                  ),
                ],
              ),
              if (_msg != null) SysText(_msg!),
              const BackupList(),
            ],
            if (_error != null) SysSaid(text: _error!),
          ],
        ),
      ],
    );
  }
}

// ---- SSH into the machine ----

const _sshWhy = ['no_helper', 'unreachable', 'timeout', 'not_installed'];

/// SSH into the machine (RedGiant OS): off by default, keys only.
class SshPanel extends StatefulWidget {
  const SshPanel({super.key});

  @override
  State<SshPanel> createState() => _SshPanelState();
}

class _SshPanelState extends State<SshPanel> {
  Map<String, dynamic>? _ssh;
  final _key = TextEditingController();
  bool _needKey = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    unawaited(_load());
  }

  @override
  void dispose() {
    _key.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final c = sysClient(context);
    if (c == null) return;
    try {
      final s = await c.setupSsh();
      if (mounted) setState(() => _ssh = s);
    } on ApiException {
      // A request that fails still shows the card, with why.
      if (mounted) setState(() => _ssh = {'available': false, 'why': 'unreachable'});
    }
  }

  Future<void> _set(bool on, String? key) async {
    final l = AppLocalizations.of(context);
    final c = sysClient(context);
    if (c == null) return;
    setState(() => _error = null);
    try {
      final s = await c.setSetupSsh(on, key);
      if (mounted) {
        setState(() => _ssh = s);
        _key.clear();
      }
    } on ApiException catch (e) {
      if (mounted) setState(() => _error = sysError(l, e));
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final s = _ssh;
    if (s == null) return const SizedBox.shrink();
    final available = s['available'] == true;
    final why = available ? '' : '${s['why'] ?? 'no_helper'}';
    final on = s['on'] == true;
    final container = s['container'] is String
        ? virtNames[s['container']] ?? '${s['container']}'
        : null;
    return SysBox(
      key: const Key('sy-ssh'),
      icon: RgIcons.terminal,
      title: l.syFbSshTitle,
      q: l.syFbSshQ,
      children: [
        if (!available)
          SysText(
            _sshWhy.contains(why) ? sw(l, 'fbSshWhy_$why') : sw(l, 'fbSshWhy_other', {'why': why}),
          )
        else ...[
          SwitchLine(
            key: const Key('sy-ssh-on'),
            title: l.syFbSshOn,
            help: on ? sw(l, 'fbSshKeys', {'n': '${s['keys'] ?? 0}'}) : l.syFbSshOffHelp,
            on: on,
            onChanged: (v) {
              final missing = v && _key.text.trim().isEmpty;
              setState(() => _needKey = missing);
              if (missing) return;
              unawaited(_set(v, v ? _key.text : null));
            },
          ),
          if (_needKey) SysNote(tone: 'error', icon: RgIcons.alert, text: l.syFbSshNeedKey),
          if (container != null) SysText(sw(l, 'fbSshContainer', {'name': container})),
          SysField(
            label: l.syFbSshKey,
            help: l.syFbSshKeyHelp,
            hint: l.syFbSshKeyPlaceholder,
            controller: _key,
            fieldKey: const Key('sy-ssh-key'),
            lines: 3,
            onChanged: (_) => setState(() {}),
          ),
          if (on)
            SysActs(
              children: [
                OutlinedButton.icon(
                  key: const Key('sy-ssh-add'),
                  onPressed: _key.text.trim().isEmpty ? null : () => _set(true, _key.text),
                  icon: RgIcon(RgIcons.key, size: 16, color: RgColors.of(context).text),
                  label: Text(l.syFbSshAddKey),
                ),
              ],
            ),
        ],
        if (_error != null) SysSaid(text: _error!),
      ],
    );
  }
}

// Settings › Emulators (3.11 phase 1), the page's Emulators.tsx: what this machine and every node
// have for Android emulators, Android phones (USB or Wi-Fi) and iOS simulators, and what is missing,
// in words. Read-only apart from this machine's two choices: the folder of an Android SDK (when it
// is not in a place Rasgeth looks at by itself; the server refuses a folder without an SDK, in its
// words) and how many emulators may run at once. Nothing is installed from here. The devices one
// can open (3.11 phase 2, the page's DeviceList): «Open» shows one live (an emulator that is off
// starts without a window), «Switch off» stops a running emulator.
import 'dart:async';

import 'package:flutter/material.dart';

import '../../api/client.dart';
import '../../l10n/app_localizations.dart';
import '../../screens/device_screen.dart';
import '../../theme/colors.dart';
import '../../ui/icons.dart';
import '../../ui/settings_kit.dart';
import '../api/system_api.dart';
import 'system_kit.dart';

Future<void> openEmulatorsSettings(BuildContext context) =>
    openSystemScreen(context, const EmulatorsScreen());

const _osNames = {'windows': 'Windows', 'macos': 'macOS', 'linux': 'Linux'};

/// The page's key for a code with dashes (`platform-tools` → `emMiss_platform_tools`).
String _k(String prefix, String code) => '$prefix${code.replaceAll('-', '_')}';

/// The one line that says where a machine stands (the page's `statusLine`).
String emulatorStatus(AppLocalizations l, EmulatorReport r) {
  if (r.ready) {
    final n = r.avds.where((a) => a['imageMissing'] != true).length;
    return sw(l, 'emReady', {'count': '$n'});
  }
  if (r.container) return l.syEmContainer;
  if (r.sdk == null) return l.syEmNoSdk;
  return l.syEmNotReady;
}

/// «Phone over USB · SM A525F» (the page's `attachedFacts`).
String attachedFacts(AppLocalizations l, Map<String, dynamic> d) {
  final kind = d['kind'] == 'emulator'
      ? l.syEmRunningEmu
      : d['link'] == 'wifi'
      ? l.syEmPhoneWifi
      : l.syEmPhoneUsb;
  final state = switch (d['state']) {
    'unauthorized' => l.syEmUnauthorized,
    'offline' => l.syEmOffline,
    _ => null,
  };
  return [kind, d['avd'] ?? d['model'], ?state].whereType<String>().join(' · ');
}

String _avdFacts(AppLocalizations l, Map<String, dynamic> a) => [
  if (a['api'] is num) sw(l, 'emApi', {'api': '${a['api']}'}),
  ?a['abi'] as String?,
  if (a['playStore'] == true) l.syEmPlayStore else ?a['tag'] as String?,
  ?a['device'] as String?,
].join(' · ');

class EmulatorsScreen extends StatefulWidget {
  const EmulatorsScreen({super.key});

  @override
  State<EmulatorsScreen> createState() => _EmulatorsScreenState();
}

class _EmulatorsScreenState extends State<EmulatorsScreen> {
  EmulatorsState? _s;
  String? _error;
  String? _pathError;
  bool _busy = false;
  final _path = TextEditingController();

  @override
  void initState() {
    super.initState();
    unawaited(_load());
  }

  @override
  void dispose() {
    _path.dispose();
    super.dispose();
  }

  void _show(EmulatorsState s) => setState(() {
    _s = s;
    _error = null;
    _path.text = s.sdkPath ?? '';
  });

  Future<void> _load({bool fresh = false}) async {
    final c = sysClient(context);
    if (c == null) return;
    setState(() => _busy = true);
    try {
      final s = await c.emulators(fresh: fresh);
      if (mounted) _show(s);
    } on ApiException catch (e) {
      if (mounted) setState(() => _error = sysError(AppLocalizations.of(context), e));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _save({bool setPath = false, String? sdkPath, int? maxRunning}) async {
    final l = AppLocalizations.of(context);
    final c = sysClient(context);
    if (c == null) return;
    setState(() => _pathError = null);
    try {
      final s = await c.setEmulatorSettings(
        setPath: setPath,
        sdkPath: sdkPath,
        maxRunning: maxRunning,
      );
      if (mounted) _show(s);
    } on ApiException catch (e) {
      if (mounted) setState(() => _pathError = sysError(l, e));
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final s = _s;
    final here = s?.here.report;
    return SettingsScaffold(
      title: l.syEmSection,
      backKey: const Key('sy-emulators-back'),
      backLabel: l.back,
      listKey: const Key('sy-emulators-list'),
      children: [
        SysHead(q: l.syEmQ, lead: l.syEmLead),
        if (_error != null) NoticeBanner(text: _error!, error: true),
        if (s == null && _error == null)
          const Padding(
            padding: EdgeInsets.all(24),
            child: Center(child: RgSpinner(size: 22)),
          ),
        if (s != null) ...[
          SysSub(s.here.name.isEmpty ? l.syEmHere : '${l.syEmHere} · ${s.here.name}'),
          SysBox(
            key: const Key('sy-em-here'),
            children: [
              if (here != null) EmulatorReportView(r: here) else SysText(l.syEmLooking),
              SysActs(
                start: true,
                children: [
                  OutlinedButton.icon(
                    key: const Key('sy-em-again'),
                    onPressed: _busy ? null : () => _load(fresh: true),
                    icon: const RgIcon(RgIcons.refresh, size: 14),
                    label: Text(l.syEmLookAgain),
                  ),
                ],
              ),
            ],
          ),
          SysSub(l.syEmDevices, lead: l.syEmDevicesLead),
          const DeviceList(),
          SysSub(l.syEmFolder, lead: l.syEmFolderLead),
          SysBox(
            children: [
              SysField(
                label: l.syEmFolderLabel,
                help: l.syEmFolderHelp,
                error: _pathError,
                hint: here?.os == 'windows' ? r'D:\Android\Sdk' : '/opt/android-sdk',
                controller: _path,
                fieldKey: const Key('sy-em-path'),
                onChanged: (_) => setState(() {}),
              ),
              SysActs(
                start: true,
                children: [
                  FilledButton(
                    key: const Key('sy-em-path-save'),
                    onPressed: _path.text.trim().isEmpty || _path.text.trim() == (s.sdkPath ?? '')
                        ? null
                        : () => _save(setPath: true, sdkPath: _path.text.trim()),
                    child: Text(l.syEmFolderSave),
                  ),
                  if (s.sdkPath != null)
                    OutlinedButton(
                      key: const Key('sy-em-path-forget'),
                      onPressed: () => _save(setPath: true),
                      child: Text(l.syEmFolderForget),
                    ),
                ],
              ),
            ],
          ),
          SysSub(l.syEmMax, lead: l.syEmMaxLead),
          SysBox(
            children: [
              SysSeg<int>(
                keyPrefix: 'sy-em-max',
                options: [
                  for (final n in [1, 2, 3, 4]) (n, '$n'),
                ],
                value: s.maxRunning,
                onChanged: (n) => _save(maxRunning: n),
              ),
            ],
          ),
          SysSub(l.syEmNodes, lead: l.syEmNodesLead),
          if (s.nodes.isEmpty)
            SysBox(children: [SysText(l.syEmNoNodes, dim: true)])
          else
            for (final n in s.nodes) _NodeBox(n: n),
        ],
      ],
    );
  }
}

/// The devices one can open (the page's `DeviceList`): name, kind or link, state, serial, «started
/// by Rasgeth», «Open» and, for an emulator that is on, «Switch off».
class DeviceList extends StatefulWidget {
  const DeviceList({super.key});

  @override
  State<DeviceList> createState() => _DeviceListState();
}

class _DeviceListState extends State<DeviceList> {
  List<EmuDeviceView>? _list;
  String? _error;

  @override
  void initState() {
    super.initState();
    unawaited(_run((c) => c.emulatorDevices()));
  }

  Future<void> _run(Future<List<EmuDeviceView>> Function(RedGiantClient c) f) async {
    final c = sysClient(context);
    if (c == null) return;
    setState(() => _error = null);
    try {
      final list = await f(c);
      if (mounted) setState(() => _list = list);
    } on ApiException catch (e) {
      if (mounted) setState(() => _error = sysError(AppLocalizations.of(context), e));
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final list = _list;
    return SysBox(
      key: const Key('sy-em-devices'),
      children: [
        if (_error != null) SysNote(text: _error!, icon: RgIcons.alert, tone: 'error'),
        if (list == null && _error == null)
          SysText(l.syEmLooking, dim: true)
        else if (list != null && list.isEmpty)
          SysText(l.syEmNoDevices, dim: true)
        else
          for (final d in list ?? const <EmuDeviceView>[])
            _DeviceRow(d: d, onStop: () => _run((c) => c.stopEmulatorDevice(d.id))),
      ],
    );
  }
}

class _DeviceRow extends StatelessWidget {
  const _DeviceRow({required this.d, required this.onStop});

  final EmuDeviceView d;
  final VoidCallback onStop;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final c = RgColors.of(context);
    final help = [
      d.kind == 'phone' ? (d.link == 'wifi' ? l.syEmPhoneWifi : l.syEmPhoneUsb) : l.syEmRunningEmu,
      sw(l, 'dsState_${d.state}'),
      ?d.serial,
    ].where((x) => x.isNotEmpty).join(' · ');
    return Padding(
      key: Key('sy-em-dev-${d.id}'),
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          RgIcon(d.kind == 'phone' ? RgIcons.phone : RgIcons.emulator, size: 18, color: c.dim),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Wrap(
                  spacing: 8,
                  runSpacing: 4,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    Text(
                      d.name,
                      style: TextStyle(color: c.text, fontWeight: FontWeight.w700),
                    ),
                    if (d.ours)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 1),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(999),
                          border: Border.all(color: c.line),
                        ),
                        child: Text(
                          l.syEmStartedHere,
                          style: TextStyle(color: c.dim, fontSize: 11.5),
                        ),
                      ),
                  ],
                ),
                Text(help, style: TextStyle(color: c.dim, fontSize: 12.5)),
              ],
            ),
          ),
          const SizedBox(width: 8),
          FilledButton(
            key: Key('sy-em-open-${d.id}'),
            onPressed: d.state == 'unauthorized' || d.state == 'offline'
                ? null
                : () => openDeviceScreen(context, d.id, d.name),
            child: Text(l.syEmOpen),
          ),
          if (d.kind == 'emulator' && d.state == 'on') ...[
            const SizedBox(width: 6),
            OutlinedButton(
              key: Key('sy-em-stop-${d.id}'),
              onPressed: onStop,
              child: Text(l.syEmStop),
            ),
          ],
        ],
      ),
    );
  }
}

class _NodeBox extends StatelessWidget {
  const _NodeBox({required this.n});

  final EmulatorMachineView n;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return SysBox(
      key: Key('sy-em-node-${n.id}'),
      icon: RgIcons.server,
      title: n.name,
      q: n.online ? null : l.syEmNodeOffline,
      children: [
        if (n.report != null)
          EmulatorReportView(r: n.report!)
        else
          SysText(l.syEmNodeOld, dim: true),
      ],
    );
  }
}

/// One machine's report: facts, virtual devices, devices attached, what is missing.
class EmulatorReportView extends StatelessWidget {
  const EmulatorReportView({super.key, required this.r});

  final EmulatorReport r;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final c = RgColors.of(context);
    final sdk = r.sdk;
    final accel = r.accel;
    final kind = '${accel['kind'] ?? ''}'.toUpperCase();
    final facts = <(String, Object)>[
      (l.syEmSystem, '${_osNames[r.os] ?? r.os} ${r.arch}'),
      (
        l.syEmSdk,
        sdk == null ? l.syEmNone : '${sdk['root']} · ${sw(l, _k('emSrc_', '${sdk['source']}'))}',
      ),
      if (sdk != null) ...[
        (l.syEmEmulator, '${sdk['emulator'] ?? l.syEmNone}'),
        (l.syEmAdb, '${sdk['platformTools'] ?? l.syEmNone}'),
        (
          l.syEmImages,
          (sdk['images'] as List? ?? const []).isEmpty
              ? l.syEmNone
              : (sdk['images'] as List).join('\n'),
        ),
      ],
      (
        l.syEmAccel,
        accel['ok'] == true
            ? sw(l, 'emAccelOk', {'kind': kind})
            : sw(l, _k('emAccel_', '${accel['reason'] ?? 'unknown'}')),
      ),
      if (r.ios != null) (l.syEmXcode, '${r.ios!['xcode'] ?? l.syEmNone}'),
    ];
    final sims = [
      for (final x in r.ios?['simulators'] as List? ?? const [])
        if (x is Map) '${x['name']} (${x['runtime']})',
    ];
    final head = TextStyle(color: c.text, fontWeight: FontWeight.w700, fontSize: 13.5);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          emulatorStatus(l, r),
          key: const Key('sy-em-status'),
          style: TextStyle(color: r.ready ? c.ok : c.text, fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 8),
        SysFacts(facts),
        if (r.avds.isNotEmpty) ...[
          const SizedBox(height: 8),
          Text(l.syEmAvds, style: head),
          for (final a in r.avds)
            SysRow(
              title: a['imageMissing'] == true
                  ? '${a['name']} · ${l.syEmImageMissing}'
                  : '${a['name']}',
              help: _avdFacts(l, a),
            ),
        ],
        const SizedBox(height: 8),
        Text(l.syEmAttached, style: head),
        if (r.attached.isEmpty)
          SysText(r.adbIdle ? l.syEmAdbIdle : l.syEmNoneAttached, dim: true)
        else
          for (final d in r.attached) SysRow(title: '${d['serial']}', help: attachedFacts(l, d)),
        if (sims.isNotEmpty) ...[
          const SizedBox(height: 8),
          Text(l.syEmSimulators, style: head),
          SysText(sims.take(12).join(' · '), dim: true),
        ],
        if (r.missing.isNotEmpty) ...[
          const SizedBox(height: 8),
          Text(l.syEmMissing, style: head),
          for (final m in r.missing)
            SysNote(text: sw(l, _k('emMiss_', m)), icon: RgIcons.alert, tone: 'warn'),
        ],
        if (sdk == null && r.looked.isNotEmpty)
          SysFold(
            label: l.syEmLooked,
            children: [
              for (final x in r.looked)
                SysText('${x['path']} · ${sw(l, _k('emSrc_', '${x['source']}'))}', dim: true),
            ],
          ),
      ],
    );
  }
}

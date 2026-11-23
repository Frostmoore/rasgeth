// G42.14: the system's routes, the same the page calls (packages/web/src/api.ts): access from
// outside home (`loginMethods`, `setPassword`, `newCodeSecret`, `enableCode`, `disableCode`,
// `revokeSessions`, `startRemote`, `stopRemote`, `setReachable`, `setupNet`, `probeName`,
// `startPihole`, `stopPihole`, `piholePassword`), Settings › System (`setupRole`, `setupStorage`,
// the backups' destinations, `setupSsh`, `setupWifi…`, `setupHttps`, `setupReboot`), the SSH
// machines (`machines`…), the nodes (`nodes`…), the emulators (`emulators`, `setEmulatorSettings`), the backup file (`exportBackup`, `uploadBackup`,
// `importBackup`), the updates' gate (`updateAct`, `safetyBackup`, `foundBackups`). Passwords and
// keys go to the server and are never kept here.
import 'dart:typed_data';

import '../../api/client.dart';
import '../../api/code.dart' show JobView;

String _e(String s) => Uri.encodeComponent(s);

Map<String, dynamic> _m(Object? o) => o is Map<String, dynamic> ? o : const {};
List<Map<String, dynamic>> _l(Object? o) => [
  for (final x in o is List ? o : const []) x is Map<String, dynamic> ? x : const {},
];
String? _s(Object? o) => o is String ? o : null;
int _i(Object? o) => o is num ? o.toInt() : 0;
double? _d(Object? o) => o is num ? o.toDouble() : null;
List<String> _ss(Object? o) => [for (final x in o is List ? o : const []) '$x'];

/// `Found<T>`: a value, or why it is missing.
typedef Found = ({Object? value, String? missing});
Found _found(Object? o) {
  final j = _m(o);
  return j.containsKey('value')
      ? (value: j['value'], missing: null)
      : (value: null, missing: _s(j['missing']) ?? 'unsupported');
}

/// `EmulatorReport` (3.11): what a machine has for emulators, phones and simulators.
class EmulatorReport {
  EmulatorReport(Map<String, dynamic> j)
    : os = _s(j['os']) ?? 'linux',
      arch = _s(j['arch']) ?? 'x64',
      container = j['container'] == true,
      sdk = _m(_m(j['android'])['sdk']).isEmpty ? null : _m(_m(j['android'])['sdk']),
      looked = _l(_m(j['android'])['looked']),
      avds = _l(_m(j['android'])['avds']),
      attached = _l(_m(j['android'])['attached']),
      adbIdle = _m(j['android'])['adbIdle'] == true,
      accel = _m(_m(j['android'])['accel']),
      ios = _m(j['ios']).isEmpty ? null : _m(j['ios']),
      missing = _ss(j['missing']),
      ready = j['ready'] == true,
      maxRunning = _i(j['maxRunning']);

  final String os, arch;
  final bool container, adbIdle, ready;

  /// `{root, source, emulator?, platformTools?, cmdlineTools, images}`.
  final Map<String, dynamic>? sdk;
  final List<Map<String, dynamic>> looked, avds, attached;

  /// `{ok, kind?, reason?}`.
  final Map<String, dynamic> accel;

  /// `{xcode?, simulators, bridge?, bridgeVersion?, bridgeDir?, ready}` (macOS only).
  final Map<String, dynamic>? ios;
  final List<String> missing;
  final int maxRunning;
}

/// `EmuInstallPlan` (3.11 phase 5): the guided install's steps, folder, sizes, licences; a
/// `planId` only when it can start.
class EmuInstallPlan {
  EmuInstallPlan(Map<String, dynamic> j)
    : planId = _s(j['planId']),
      target = _s(j['target']) ?? '',
      targetStandard = j['targetStandard'] == true,
      steps = _l(j['steps']),
      licences = _l(j['licences']),
      bytes = _i(j['bytes']),
      blocked = _s(j['blocked']),
      notes = _ss(j['notes']),
      java = _m(j['java']).isEmpty ? null : _m(j['java']);

  final String? planId;
  final String target;
  final bool targetStandard;

  /// `{id, package?, bytes?, version?, avd?}`.
  final List<Map<String, dynamic>> steps;

  /// `{id, text}`: the full text to read and accept.
  final List<Map<String, dynamic>> licences;
  final int bytes;
  final String? blocked;
  final List<String> notes;

  /// `{path, major}`.
  final Map<String, dynamic>? java;
}

/// `IosBridgePlan` (3.12.2): what the iOS bridge's install would download and where; a `planId`
/// only when it can start.
class IosBridgePlan {
  IosBridgePlan(Map<String, dynamic> j)
    : planId = _s(j['planId']),
      folder = _s(j['folder']) ?? '',
      version = _s(j['version']) ?? '',
      bytes = _i(j['bytes']),
      licence = _s(j['licence']) ?? '',
      blocked = _s(j['blocked']);

  final String? planId, blocked;
  final String folder, version, licence;
  final int bytes;
}

/// `EmulatorMachineView`: this machine or a node, with its report when it gave one.
class EmulatorMachineView {
  EmulatorMachineView(Map<String, dynamic> j)
    : id = _s(j['id']) ?? '',
      name = _s(j['name']) ?? '',
      online = j['online'] == true,
      report = _m(j['report']).isEmpty ? null : EmulatorReport(_m(j['report']));

  final String id, name;
  final bool online;
  final EmulatorReport? report;
}

/// `EmulatorsState`: Settings › Emulators.
class EmulatorsState {
  EmulatorsState(Map<String, dynamic> j)
    : here = EmulatorMachineView(_m(j['here'])),
      sdkPath = _s(_m(j['settings'])['sdkPath']),
      maxRunning = _m(j['settings'])['maxRunning'] is num ? _i(_m(j['settings'])['maxRunning']) : 2,
      nodes = [for (final n in _l(j['nodes'])) EmulatorMachineView(n)];

  final EmulatorMachineView here;
  final String? sdkPath;
  final int maxRunning;
  final List<EmulatorMachineView> nodes;
}

/// `EmuDeviceView` (3.11 phase 2): a device one can open, an AVD (on or off), a running
/// emulator, a phone over USB or Wi-Fi.
class EmuDeviceView {
  EmuDeviceView(Map<String, dynamic> j)
    : id = _s(j['id']) ?? '',
      name = _s(j['name']) ?? '',
      kind = j['kind'] == 'phone' ? 'phone' : 'emulator',
      state = _s(j['state']) ?? 'off',
      serial = _s(j['serial']),
      link = _s(j['link']),
      machine = _s(j['machine']),
      ours = j['ours'] == true,
      platform = j['platform'] == 'ios' ? 'ios' : 'android',
      runtime = _s(j['runtime']);

  final String id, name;

  /// android | ios (3.12.2).
  final String platform;

  /// For an iOS simulator: `iOS 27.2`.
  final String? runtime;

  /// emulator | phone.
  final String kind;

  /// off | starting | on | unauthorized | offline.
  final String state;
  final String? serial, link;

  /// On a node (3.11 phase 4): its name; the id ends with `@<fingerprint>`.
  final String? machine;

  /// Rasgeth started it.
  final bool ours;
}

/// `BlockDisk`.
class BlockDisk {
  BlockDisk(Map<String, dynamic> j)
    : name = _s(j['name']) ?? '',
      path = _s(j['path']) ?? '',
      type = _s(j['type']) ?? 'other',
      sizeBytes = _i(j['sizeBytes']),
      removable = j['removable'] == true,
      hotplug = j['hotplug'] == true,
      transport = _s(j['transport']) ?? '',
      model = _s(j['model']) ?? '',
      label = _s(j['label']) ?? '',
      uuid = _s(j['uuid']) ?? '',
      fstype = _s(j['fstype']) ?? '',
      mountpoint = _s(j['mountpoint']) ?? '',
      freeBytes = j['freeBytes'] is num ? _i(j['freeBytes']) : null,
      disk = _s(j['disk']) ?? '',
      usable = j['usable'] == true,
      why = _s(j['why']);

  final String name, path, type, transport, model, label, uuid, fstype, mountpoint, disk;
  final int sizeBytes;
  final int? freeBytes;
  final bool removable, hotplug, usable;
  final String? why;

  String get title => label.isNotEmpty ? label : (model.isNotEmpty ? model : name);
}

/// `SystemInfo`.
class SystemInfo {
  SystemInfo(Map<String, dynamic> j)
    : os = _s(j['os']) ?? 'linux',
      arch = _s(j['arch']) ?? '',
      cpuModel = _s(_m(j['cpu'])['model']) ?? '',
      cores = _i(_m(j['cpu'])['cores']),
      ramGb = _d(_m(j['ram'])['totalGb']) ?? 0,
      ramFree = _found(_m(j['ram'])['freeGb']),
      disks = _found(j['disks']),
      gpus = _found(j['gpus']),
      virt = _found(j['virt']);

  final String os, arch, cpuModel;
  final int cores;
  final double ramGb;
  final Found ramFree, disks, gpus, virt;
}

/// `GET /api/setup`'s parts this area reads.
class SystemSetup {
  SystemSetup(Map<String, dynamic> j)
    : raw = j,
      role = _s(_m(j['config'])['role']) ?? 'full',
      remote = _m(j['config'])['remote'] is Map ? _m(_m(j['config'])['remote']) : null,
      reachable = _m(j['config'])['reachable'] is Map ? _m(_m(j['config'])['reachable']) : null,
      pihole = _m(j['config'])['pihole'] is Map ? _m(_m(j['config'])['pihole']) : null,
      system = j['system'] is Map ? SystemInfo(_m(j['system'])) : null,
      offer = _m(j['offer']);

  final Map<String, dynamic> raw;
  final String role;

  /// `{way, url}` while a way out is on.
  final Map<String, dynamic>? remote;

  /// «I am reachable already» (G39.8): `{url?}`.
  final Map<String, dynamic>? reachable;

  /// `{lanIp, domain?, adminUrl}`.
  final Map<String, dynamic>? pihole;
  final SystemInfo? system;

  /// `LocalOffer`: `{local, maxModelGb, reason}`.
  final Map<String, dynamic> offer;
}

/// `StorageInfo & {backups, running}`.
class StorageState {
  StorageState(Map<String, dynamic> j)
    : dataDir = _s(j['dataDir']) ?? '',
      dataFreeGb = _d(j['dataFreeGb']),
      dataTotalGb = _d(j['dataTotalGb']),
      method = _s(j['method']) ?? 'none',
      candidates = [for (final d in _l(j['candidates'])) BlockDisk(d)],
      container = _s(j['container']),
      places = _l(j['places']),
      hostDisks = _l(j['hostDiskList']),
      containerHint = j['containerHint'] is Map ? _m(j['containerHint']) : null,
      backupBase = _s(j['backupBase']),
      backups = j['backups'] is Map ? _m(j['backups']) : null,
      running = j['running'] == true;

  final String dataDir, method;
  final double? dataFreeGb, dataTotalGb;
  final List<BlockDisk> candidates;
  final String? container, backupBase;
  final List<Map<String, dynamic>> places, hostDisks;
  final Map<String, dynamic>? containerHint;

  /// `BackupSettings`: `{destination?, schedule, last?}`.
  final Map<String, dynamic>? backups;
  final bool running;

  Map<String, dynamic>? get destination =>
      backups?['destination'] is Map ? _m(backups!['destination']) : null;
  Map<String, dynamic> get schedule => backups?['schedule'] is Map
      ? _m(backups!['schedule'])
      : const {'every': 'daily', 'hour': 3, 'keep': 7};
  Map<String, dynamic>? get last => backups?['last'] is Map ? _m(backups!['last']) : null;
}

/// `MachineView` (G38.2): public keys and fingerprints, never a secret.
class MachineView {
  MachineView(Map<String, dynamic> j)
    : id = _s(j['id']) ?? '',
      name = _s(j['name']) ?? '',
      host = _s(j['host']) ?? '',
      port = j['port'] is num ? _i(j['port']) : 22,
      user = _s(j['user']) ?? '',
      auth = _s(j['auth']) ?? 'key',
      keySource = _s(j['keySource']),
      publicKey = _s(j['publicKey']),
      hasPassword = j['hasPassword'] == true,
      hostKey = j['hostKey'] is Map ? _m(j['hostKey']) : null,
      folder = _s(j['folder']),
      everyone = _m(j['access'])['everyone'] == true,
      agents = _ss(_m(j['access'])['agents']),
      projects = _ss(_m(j['access'])['projects']),
      lastTest = j['lastTest'] is Map ? _m(j['lastTest']) : null;

  final String id, name, host, user, auth;
  final int port;
  final String? keySource, publicKey, folder;
  final bool hasPassword, everyone;
  final Map<String, dynamic>? hostKey, lastTest;
  final List<String> agents, projects;
}

/// `NodeView`.
class NodeView {
  NodeView(Map<String, dynamic> j)
    : fingerprint = _s(j['fingerprint']) ?? '',
      name = _s(j['name']) ?? '',
      relation = _s(j['relation']) ?? 'tree',
      status = _s(j['status']) ?? 'offline',
      reason = _s(j['reason']),
      lastSeen = _s(j['lastSeen']),
      address = _s(j['address']),
      capabilities = j['capabilities'] is Map ? _m(j['capabilities']) : null,
      grants = _l(j['grants']),
      children = [for (final c in _l(j['children'])) NodeView(c)];

  final String fingerprint, name, relation, status;
  final String? reason, lastSeen, address;
  final Map<String, dynamic>? capabilities;

  /// `NodeGrant`: `{id, controller, controllerName, rights}`.
  final List<Map<String, dynamic>> grants;
  final List<NodeView> children;

  /// This machine and, under it, its own nodes, flat.
  List<NodeView> flat() => [this, for (final c in children) ...c.flat()];
}

/// `NodesState`.
class NodesState {
  NodesState(Map<String, dynamic> j)
    : selfName = _s(_m(j['self'])['name']) ?? '',
      selfFingerprint = _s(_m(j['self'])['fingerprint']),
      ready = _m(j['self'])['ready'] == true,
      tree = NodeView(_m(j['tree'])),
      parent = j['parent'] is Map ? NodeView(_m(j['parent'])) : null,
      pending = _l(j['pending']),
      grants = _l(j['grants']),
      placements = _l(j['placements']),
      code = j['code'] is Map ? _m(j['code']) : null;

  final String selfName;
  final String? selfFingerprint;
  final bool ready;
  final NodeView tree;
  final NodeView? parent;

  /// `PendingPair`: `{fingerprint, name, sas, side}`.
  final List<Map<String, dynamic>> pending;
  final List<Map<String, dynamic>> grants;

  /// `NodePlacement`: `{scope, commands?, backups?, render?}`.
  final List<Map<String, dynamic>> placements;

  /// `PairCode`: `{code, expiresAt}`.
  final Map<String, dynamic>? code;
}

/// A refusal's code, as the page's `tryApi` reads it.
String errorCode(Object e) => e is ApiException ? (e.code ?? 'failed') : 'failed';

extension SystemApi on RedGiantClient {
  Future<Map<String, dynamic>> _get(String path) async => objectOf(await getJson(path));
  Future<Map<String, dynamic>> _do(String method, String path, [Object? body]) async =>
      _m(await callJson(method, path, body));
  Future<JobView> _job(String method, String path, [Object? body]) async =>
      JobView.fromJson(objectOf(await callJson(method, path, body)));

  /// `GET /api/setup`.
  Future<SystemSetup> systemSetup() async => SystemSetup(await _get('/api/setup'));

  // ---- access from outside home ----

  /// `GET /api/auth/methods`: `{password, code}`.
  Future<({bool password, bool code})> loginMethods() async {
    final j = await _get('/api/auth/methods');
    return (password: j['password'] == true, code: j['code'] == true);
  }

  /// `PUT /api/auth/password`.
  Future<void> setPassword(String password, {bool signOutOthers = false}) =>
      callJson('PUT', '/api/auth/password', {'password': password, 'signOutOthers': signOutOthers});

  /// `POST /api/auth/code/new`: the authenticator's secret and its `otpauth://` address.
  Future<({String secret, String url})> newCodeSecret() async {
    final j = await _do('POST', '/api/auth/code/new');
    return (secret: _s(j['secret']) ?? '', url: _s(j['url']) ?? '');
  }

  /// `POST /api/auth/code`.
  Future<void> enableCode(String secret, String code) =>
      callJson('POST', '/api/auth/code', {'secret': secret, 'code': code});

  /// `DELETE /api/auth/code`.
  Future<void> disableCode() => callJson('DELETE', '/api/auth/code');

  /// `POST /api/auth/sessions/revoke`: every other signed in browser signs in again.
  Future<void> revokeSessions() => callJson('POST', '/api/auth/sessions/revoke');

  /// `POST /api/setup/remote`: `{way: tailscale}`, `{way: cloudflare, token, hostname}`,
  /// `{way: caddy, domain}`; the job to follow.
  Future<JobView> startRemote(Map<String, Object?> body) => _job('POST', '/api/setup/remote', body);

  /// `DELETE /api/setup/remote`.
  Future<void> stopRemote() => callJson('DELETE', '/api/setup/remote');

  /// `PUT /api/setup/reachable`: «I am reachable already» (G39.8).
  Future<void> setReachable(bool on, [String? url]) =>
      callJson('PUT', '/api/setup/reachable', {'on': on, 'url': ?url});

  /// `GET /api/setup/net`: what reaches this machine already.
  Future<Map<String, dynamic>> setupNet() => _get('/api/setup/net');

  /// `POST /api/setup/net/probe`: a home service's name as RedGiant sees it.
  Future<Map<String, dynamic>> probeName(String name) =>
      _do('POST', '/api/setup/net/probe', {'name': name});

  /// `POST /api/setup/pihole`.
  Future<JobView> startPihole(String lanIp, [String? domain]) =>
      _job('POST', '/api/setup/pihole', {'lanIp': lanIp, 'domain': ?domain});

  /// `DELETE /api/setup/pihole`.
  Future<void> stopPihole() => callJson('DELETE', '/api/setup/pihole');

  /// `GET /api/setup/pihole/password`.
  Future<String> piholePassword() async =>
      _s((await _get('/api/setup/pihole/password'))['password']) ?? '';

  // ---- Settings › System ----

  /// `PUT /api/setup/role`.
  Future<void> setupRole(String role, {bool confirm = false}) =>
      callJson('PUT', '/api/setup/role', {'role': role, if (confirm) 'confirm': true});

  /// `GET /api/setup/storage`.
  Future<StorageState> setupStorage() async => StorageState(await _get('/api/setup/storage'));

  Future<void> setupBackupDisk(String uuid) =>
      callJson('POST', '/api/setup/backups/disk', {'uuid': uuid});
  Future<void> setupBackupPlace(String path) =>
      callJson('POST', '/api/setup/backups/place', {'path': path});
  Future<void> setupBackupFolder(String path) =>
      callJson('PUT', '/api/setup/backups/folder', {'path': path});

  /// `PUT /api/setup/backups`: `{schedule: {…}}`.
  Future<void> setupBackupSchedule(Map<String, Object?> schedule) =>
      callJson('PUT', '/api/setup/backups', {'schedule': schedule});

  /// `POST /api/setup/backups/run`: started, or one is running already.
  Future<bool> setupBackupRun() async =>
      (await _do('POST', '/api/setup/backups/run'))['started'] == true;

  /// `GET /api/setup/backups/targets`: `{machines, smb, nodes}`.
  Future<Map<String, dynamic>> setupBackupTargets() => _get('/api/setup/backups/targets');
  Future<void> setupBackupSftp(String machineId, String path) =>
      callJson('PUT', '/api/setup/backups/sftp', {'machineId': machineId, 'path': path});
  Future<void> setupBackupSmb(Map<String, Object?> body) =>
      callJson('PUT', '/api/setup/backups/smb', body);
  Future<void> setupBackupNode(String fingerprint) =>
      callJson('PUT', '/api/setup/backups/node', {'fingerprint': fingerprint});

  /// `GET /api/setup/backups/list`: `{where, backups}`.
  Future<Map<String, dynamic>> setupBackupList() => _get('/api/setup/backups/list');
  Future<JobView> setupBackupRestore(String id) =>
      _job('POST', '/api/setup/backups/restore', {'id': id});

  /// `GET /api/setup/backups/proxmox`: `{checked, hosts}`.
  Future<Map<String, dynamic>> setupProxmoxHosts() => _get('/api/setup/backups/proxmox');
  Future<JobView> setupProxmoxMount(Map<String, Object?> body) =>
      _job('POST', '/api/setup/backups/proxmox', body);

  /// `GET /api/setup/ssh`.
  Future<Map<String, dynamic>> setupSsh() => _get('/api/setup/ssh');

  /// `PUT /api/setup/ssh`.
  Future<Map<String, dynamic>> setSetupSsh(bool on, [String? key]) =>
      _do('PUT', '/api/setup/ssh', {'on': on, 'key': ?key});

  Future<Map<String, dynamic>> setupWifi() => _get('/api/setup/wifi');
  Future<Map<String, dynamic>> setupWifiScan() => _do('POST', '/api/setup/wifi/scan');

  /// `POST /api/setup/wifi/connect`: `{state: joined|saved, wifi}`.
  Future<Map<String, dynamic>> setupWifiConnect(String ssid, String password, bool hidden) => _do(
    'POST',
    '/api/setup/wifi/connect',
    {'ssid': ssid, 'password': password, if (hidden) 'hidden': true},
  );
  Future<Map<String, dynamic>> setupWifiForget(String ssid) =>
      _do('POST', '/api/setup/wifi/forget', {'ssid': ssid});

  Future<Map<String, dynamic>> setupHttps() => _get('/api/setup/https');
  Future<Map<String, dynamic>> setSetupHttps(Map<String, Object?> body) =>
      _do('PUT', '/api/setup/https', body);

  /// `GET /api/setup/os-updates` as the page reads it (security updates included).
  Future<Map<String, dynamic>> setupOsUpdatesRaw({bool check = false}) =>
      check ? _do('POST', '/api/setup/os-updates/check') : _get('/api/setup/os-updates');

  /// `POST /api/setup/os/reboot`.
  Future<void> setupReboot() => callJson('POST', '/api/setup/os/reboot', {'confirm': true});

  // ---- SSH machines ----

  Future<List<MachineView>> machines() async => [
    for (final m in _l((await _get('/api/settings/machines'))['machines'])) MachineView(m),
  ];
  Future<MachineView> addMachine(Map<String, Object?> body) async =>
      MachineView(await _do('POST', '/api/settings/machines', body));
  Future<MachineView> updateMachine(String id, Map<String, Object?> body) async =>
      MachineView(await _do('PUT', '/api/settings/machines/${_e(id)}', body));
  Future<void> removeMachine(String id) => callJson('DELETE', '/api/settings/machines/${_e(id)}');

  /// `MachineTest`: `{ok, code, message, hostKey?, expected?, system?}`.
  Future<Map<String, dynamic>> testMachine(String id) =>
      _do('POST', '/api/settings/machines/${_e(id)}/test');
  Future<void> trustMachine(String id, String fingerprint) =>
      callJson('POST', '/api/settings/machines/${_e(id)}/trust', {'fingerprint': fingerprint});

  // ---- emulators (3.11) ----

  Future<EmulatorsState> emulators({bool fresh = false}) async =>
      EmulatorsState(objectOf(await getJson('/api/emulators', fresh ? {'fresh': '1'} : null)));

  /// `PUT /api/emulators/settings`: the SDK folder (`null` forgets it) and how many at once.
  Future<EmulatorsState> setEmulatorSettings({
    bool setPath = false,
    String? sdkPath,
    int? maxRunning,
  }) async => EmulatorsState(
    await _do('PUT', '/api/emulators/settings', {
      if (setPath) 'sdkPath': sdkPath,
      'maxRunning': ?maxRunning,
    }),
  );

  /// `GET /api/emulators/devices`: the devices one can open (3.11 phase 2).
  Future<List<EmuDeviceView>> emulatorDevices() async => [
    for (final d in _l((await _get('/api/emulators/devices'))['devices'])) EmuDeviceView(d),
  ];

  /// `POST /api/emulators/devices/stop`: switches an emulator off; the devices after it.
  Future<List<EmuDeviceView>> stopEmulatorDevice(String id) async => [
    for (final d in _l((await _do('POST', '/api/emulators/devices/stop', {'id': id}))['devices']))
      EmuDeviceView(d),
  ];

  /// `POST /api/emulators/install/plan` (3.11 phase 5): what the guided install would do here.
  Future<EmuInstallPlan> emulatorInstallPlan({
    String? target,
    String? avdName,
    String? only,
  }) async => EmuInstallPlan(
    await _do('POST', '/api/emulators/install/plan', {
      'target': ?target,
      'avdName': ?avdName,
      'only': ?only,
    }),
  );

  /// `POST /api/emulators/install/start`: the person's yes; the job's id.
  Future<String> startEmulatorInstall(String planId, {required bool licenceAccepted}) async =>
      _s(
        (await _do('POST', '/api/emulators/install/start', {
          'planId': planId,
          'licenceAccepted': licenceAccepted,
        }))['jobId'],
      ) ??
      '';

  /// `POST /api/emulators/ios-bridge/plan`: what would be downloaded, and why not when it cannot.
  Future<IosBridgePlan> iosBridgePlan() async =>
      IosBridgePlan(await _do('POST', '/api/emulators/ios-bridge/plan', const {}));

  /// `POST /api/emulators/ios-bridge/start`: the person's yes; the job's id.
  Future<String> startIosBridgeInstall(String planId) async =>
      _s((await _do('POST', '/api/emulators/ios-bridge/start', {'planId': planId}))['jobId']) ?? '';

  /// `POST /api/jobs/:id/cancel`.
  Future<void> cancelEmulatorInstall(String jobId) =>
      callJson('POST', '/api/jobs/${_e(jobId)}/cancel', const {});

  // ---- nodes ----

  Future<NodesState> nodes() async => NodesState(await _get('/api/nodes'));
  Future<void> nodeCode() => callJson('POST', '/api/nodes/code');
  Future<void> cancelNodeCode() => callJson('DELETE', '/api/nodes/code');

  /// `POST /api/nodes/pair`: this machine asks to work under another one.
  Future<void> pairNode(String address, String code) =>
      callJson('POST', '/api/nodes/pair', {'address': address, 'code': code});
  Future<void> confirmNode(String fingerprint, {List<String>? rights, String? name}) => callJson(
    'POST',
    '/api/nodes/confirm',
    {'fingerprint': fingerprint, 'rights': ?rights, 'name': ?name},
  );
  Future<void> setNodeLabel(String fingerprint, String name) =>
      callJson('PUT', '/api/nodes/label', {'fingerprint': fingerprint, 'name': name});
  Future<void> rejectNode(String fingerprint) =>
      callJson('POST', '/api/nodes/reject', {'fingerprint': fingerprint});
  Future<void> unpairNode(String fingerprint) =>
      callJson('POST', '/api/nodes/unpair', {'fingerprint': fingerprint});
  Future<void> grantNode(String controller, String target, List<String> rights) => callJson(
    'POST',
    '/api/nodes/grants',
    {'controller': controller, 'target': target, 'rights': rights},
  );
  Future<void> revokeNodeGrant(String target, String id) =>
      callJson('POST', '/api/nodes/grants/revoke', {'target': target, 'id': id});
  Future<void> setNodePlacement(String scope, String what, String? value) =>
      callJson('PUT', '/api/nodes/placements', {'scope': scope, what: value});

  /// `POST /api/nodes/backup`: the project's backup on its node, now.
  Future<String> nodeBackup(String projectId) async =>
      _s((await _do('POST', '/api/nodes/backup', {'projectId': projectId}))['name']) ?? '';

  // ---- the backup file ----

  /// `POST /api/backup/export`: the job that makes it (`vars.file` once done).
  Future<JobView> exportBackup([String? keychainPassphrase]) =>
      _job('POST', '/api/backup/export', {'keychainPassphrase': ?keychainPassphrase});

  /// `GET /api/backup/file/:name`, its bytes as they arrive.
  Future<Uint8List> downloadBackup(String name, {void Function(int got, int? total)? onProgress}) =>
      getBytes('/api/backup/file/${_e(name)}', onProgress: onProgress);

  /// `POST /api/backup/upload`: the file sent, what it holds.
  Future<({String id, Map<String, dynamic> preview})> uploadBackup(Uint8List bytes) async {
    final j = _m(await postBytes('/api/backup/upload', bytes));
    return (id: _s(j['id']) ?? '', preview: _m(j['preview']));
  }

  /// `POST /api/backup/import`.
  Future<JobView> importBackup(Map<String, Object?> body) =>
      _job('POST', '/api/backup/import', body);

  // ---- the updates' gate ----

  /// `POST /api/update/act`: update, quit or uninstall.
  Future<void> updateAct(String action) => callJson('POST', '/api/update/act', {'action': action});

  /// `POST /api/update/safety-backup`: a full backup into a folder the person sees, read back.
  Future<JobView> safetyBackup([String? keychainPassphrase]) =>
      _job('POST', '/api/update/safety-backup', {'keychainPassphrase': ?keychainPassphrase});

  /// `GET /api/vault`: how many keys the keychain holds (the breaking update asks to seal them).
  Future<int> vaultCount() async => _l((await _get('/api/vault'))['entries']).length;

  /// `GET /api/jobs/:id` with its words' values (`vars`).
  Future<({JobView job, Map<String, String> vars})> jobWithVars(String id) async {
    final j = objectOf(await getJson('/api/jobs/${_e(id)}'));
    return (
      job: JobView.fromJson(j),
      vars: {for (final e in _m(j['vars']).entries) e.key: '${e.value}'},
    );
  }
}

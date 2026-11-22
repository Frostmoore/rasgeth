// The fake Rasgeth's system (G42.14), answering as `packages/server/src/app.ts` does for access
// from outside home (the password, the authenticator's code, the sessions, the ways out with their
// job, «reachable already», «Try a name», Pi-hole), Settings › System (the machine, the role, the
// storage and the backups' destinations, SSH, Wi-Fi, HTTPS, the OS's updates and restart), the SSH
// machines (the first key shown, trusted, a changed key refused), the nodes (a code, a pair
// waiting with its six digits, grants, placements), the emulators (3.11: a report, a folder refused,
// how many at once), the backup file (made, downloaded, sent,
// imported) and the updates' gate (the safety backup). Every action is recorded in [calls] with
// its body; nothing reaches a real machine.
import 'dart:convert';
import 'dart:io';

class FakeSystem {
  final calls = <String>[];
  final bodies = <String, Object?>{};

  // ---- access ----
  bool password = true;
  bool code = false;
  Map<String, dynamic>? remote;
  Map<String, dynamic>? reachable;
  Map<String, dynamic>? pihole;
  String role = 'full';

  /// The next password is refused with this code, once.
  String? refusePassword;

  Map<String, dynamic> net = {
    'tailscale': {'state': 'running', 'name': 'rasgeth.tail1234.ts.net', 'ip': '100.64.0.7'},
    'proxyInFront': null,
    'proxiesRunning': <String>[],
    'localDns': '192.168.1.12',
    'hostName': 'rasgeth.local',
    'reachedAs': null,
    'lan': {'address': '192.168.1.50', 'port': 7600},
  };

  Map<String, dynamic> systemInfo = {
    'os': 'linux',
    'arch': 'x64',
    'cpu': {'model': 'AMD Ryzen 7 5800X', 'cores': 16},
    'ram': {
      'totalGb': 31.3,
      'freeGb': {'value': 18.4},
    },
    'disks': {
      'value': [
        {
          'name': 'nvme0n1',
          'path': '/dev/nvme0n1',
          'type': 'disk',
          'sizeBytes': 512 * 1073741824,
          'removable': false,
          'hotplug': false,
          'transport': 'nvme',
          'model': 'Fanxiang S500',
          'label': '',
          'uuid': '',
          'fstype': '',
          'mountpoint': '',
          'freeBytes': null,
          'disk': 'nvme0n1',
        },
        {
          'name': 'nvme0n1p2',
          'path': '/dev/nvme0n1p2',
          'type': 'part',
          'sizeBytes': 511 * 1073741824,
          'removable': false,
          'hotplug': false,
          'transport': '',
          'model': '',
          'label': '',
          'uuid': '1111-2222',
          'fstype': 'ext4',
          'mountpoint': '/',
          'freeBytes': 320 * 1073741824,
          'disk': 'nvme0n1',
        },
      ],
    },
    'gpus': {
      'value': [
        {'maker': 'nvidia', 'name': 'NVIDIA GeForce RTX 3070', 'vramGb': 8},
      ],
    },
    'virt': {
      'value': {'kind': 'none', 'name': ''},
    },
  };

  // ---- storage ----
  Map<String, dynamic>? destination;
  Map<String, dynamic> schedule = {'every': 'daily', 'hour': 3, 'keep': 7};
  Map<String, dynamic>? last;
  String? container;
  final candidates = <Map<String, dynamic>>[
    {
      'name': 'sda1',
      'path': '/dev/sda1',
      'type': 'part',
      'sizeBytes': 2000 * 1073741824,
      'removable': false,
      'hotplug': true,
      'transport': 'usb',
      'model': 'Elements 25A3',
      'label': 'Eternatus',
      'uuid': '5E3A-91F0',
      'fstype': 'exfat',
      'mountpoint': '',
      'freeBytes': null,
      'disk': 'sda',
      'usable': true,
    },
  ];
  final backups = <Map<String, dynamic>>[
    {
      'id': 'rasgeth-2026-11-20/backup.rgbackup',
      'folder': 'rasgeth-2026-11-20',
      'file': 'backup.rgbackup',
      'bytes': 48 * 1048576,
      'at': '2026-11-20T03:00:00.000Z',
    },
  ];

  // ---- the OS ----
  Map<String, dynamic> ssh = {'available': true, 'on': false, 'keys': 0};
  Map<String, dynamic> wifi = {
    'available': true,
    'device': 'wlan0',
    'state': 'connected',
    'connected': 'Casa',
    'networks': [
      {'ssid': 'Casa', 'security': 'psk', 'signal': 82, 'connected': true, 'known': true},
      {'ssid': 'Ospiti', 'security': 'open', 'signal': 55, 'connected': false, 'known': false},
      {'ssid': 'Ufficio', 'security': 'psk', 'signal': 31, 'connected': false, 'known': false},
    ],
    'known': ['Casa', 'Montagna'],
    'wired': false,
    'address': '192.168.1.50',
  };
  Map<String, dynamic> https = {
    'available': true,
    'on': true,
    'ca': '-----BEGIN CERTIFICATE-----\nMIIBdemo\n-----END CERTIFICATE-----\n',
    'fingerprint': '98:33:81:41:31:D2:1F:B1:48:B1:4E:06:50:19:A5:63',
    'until': 'Dec 16 00:11:48 2027 GMT',
    'names': ['rasgeth.local', '192.168.1.50'],
    'redirect': false,
    'viaLocal': false,
    'inFront': null,
  };
  Map<String, dynamic> osUpdates = {
    'available': true,
    'running': false,
    'update': {
      'state': 'latest',
      'installed': '3.10.0',
      'latest': '3.10.0',
      'gate': 'none',
      'note': null,
      'step': null,
      'checkedAt': '2026-11-21T06:00:00.000Z',
    },
    'security': {
      'lastRun': '2026-11-21T04:10:00.000Z',
      'result': 'ok',
      'upgraded': 3,
      'rebootRequired': true,
      'packages': ['linux-image-amd64'],
    },
  };

  // ---- machines ----
  final machines = <Map<String, dynamic>>[];

  /// What the next test of a machine finds, by id (default: ok).
  final testCode = <String, String>{};

  // ---- nodes ----
  Map<String, dynamic>? code_;
  final pending = <Map<String, dynamic>>[];
  final children = <Map<String, dynamic>>[];
  final grants = <Map<String, dynamic>>[];
  final placements = <Map<String, dynamic>>[];
  String machineName = 'Severino';

  // ---- jobs ----
  final jobs = <String, Map<String, dynamic>>{};

  /// How many reads a new job stays running (0: done at once).
  int jobReads = 0;
  int _n = 0;

  String job(String kind, List<String> steps, Map<String, String> vars, {String state = 'done'}) {
    final id = 'job${++_n}';
    jobs[id] = {
      'id': id,
      'kind': kind,
      'state': state,
      'steps': [
        for (final s in steps) {'id': s, 'state': state == 'done' ? 'done' : 'running'},
      ],
      'vars': vars,
      'reads': jobReads,
    };
    return id;
  }

  Map<String, dynamic> _setup() => {
    'config': {'role': role, 'remote': ?remote, 'reachable': ?reachable, 'pihole': ?pihole},
    'system': systemInfo,
    'offer': {'cloud': true, 'local': true, 'maxModelGb': 6.5, 'reason': 'gpu'},
  };

  Map<String, dynamic> _storage() => {
    'dataDir': '/var/lib/redgiant/data',
    'dataFreeGb': 320.4,
    'dataTotalGb': 476.9,
    'method': 'helper',
    'candidates': candidates,
    'container': container,
    'places': <Object>[],
    'hostDiskList': container == null
        ? <Object>[]
        : [
            {
              'name': 'sdb1',
              'path': '/dev/sdb1',
              'title': 'Tech',
              'sizeBytes': 1000 * 1073741824,
              'transport': 'usb',
              'fstype': '',
            },
          ],
    'containerHint': container == null ? null : {'hostname': 'rasgeth', 'id': '105'},
    'backupBase': '/var/lib/redgiant/backups',
    'backups': {'destination': ?destination, 'schedule': schedule, 'last': ?last},
    'running': false,
  };

  Map<String, dynamic> _nodes() => {
    'self': {'fingerprint': 'SHA256:selfSelfSelfSelf1234', 'name': machineName, 'ready': true},
    'tree': {
      'fingerprint': 'SHA256:selfSelfSelfSelf1234',
      'name': machineName,
      'relation': 'self',
      'status': 'online',
      'grants': <Object>[],
      'children': children,
    },
    'pending': pending,
    'grants': grants,
    'placements': placements,
    'code': ?code_,
  };

  // ---- emulators (3.11) ----
  Map<String, dynamic> emulatorSettings = {'sdkPath': null, 'maxRunning': 2};
  Map<String, dynamic> emulatorReport = {
    'os': 'windows',
    'arch': 'x64',
    'container': false,
    'android': {
      'sdk': {
        'root': r'D:\Android\Sdk',
        'source': 'studio',
        'emulator': '35.2.10',
        'platformTools': '37.0.1',
        'cmdlineTools': true,
        'images': ['android-35/google_apis_playstore/x86_64'],
      },
      'looked': [
        {'path': r'D:\Android\Sdk', 'source': 'studio'},
      ],
      'avds': [
        {'name': 'Medium_Phone_API_35', 'api': 35, 'abi': 'x86_64', 'playStore': true},
      ],
      'attached': [
        {
          'serial': 'emulator-5554',
          'kind': 'emulator',
          'state': 'device',
          'avd': 'Medium_Phone_API_35',
        },
        {'serial': '192.168.1.40:5555', 'kind': 'phone', 'state': 'unauthorized', 'link': 'wifi'},
      ],
      'accel': {'ok': true, 'kind': 'whpx'},
    },
    'missing': ['emulator-old'],
    'ready': true,
    'maxRunning': 2,
    'at': '2026-11-22T10:00:00.000Z',
  };
  List<Map<String, dynamic>> emulatorNodes = [
    {
      'id': 'SHA256:macMacMac',
      'name': 'Mac mini',
      'online': true,
      'report': {
        'os': 'macos',
        'arch': 'arm64',
        'container': false,
        'android': {
          'looked': [
            {'path': '/Users/ana/Library/Android/sdk', 'source': 'standard'},
          ],
          'avds': <Object>[],
          'attached': <Object>[],
          'adbIdle': true,
          'accel': {'ok': true, 'kind': 'hvf'},
        },
        'ios': {
          'xcode': '27.2',
          'simulators': [
            {'name': 'iPhone 18', 'udid': 'U1', 'runtime': 'iOS 27.2', 'state': 'shutdown'},
          ],
        },
        'missing': ['sdk', 'ios-bridge'],
        'ready': false,
        'maxRunning': 2,
        'at': '2026-11-22T10:00:00.000Z',
      },
    },
    {'id': 'SHA256:oldOldOld', 'name': 'Vecchio', 'online': false},
  ];

  Map<String, dynamic> _emulators() => {
    'here': {
      'id': 'here',
      'name': 'Severino',
      'online': true,
      'report': {
        ...emulatorReport,
        'maxRunning': emulatorSettings['maxRunning'],
        if (emulatorSettings['sdkPath'] != null)
          'android': {
            ...(emulatorReport['android'] as Map<String, dynamic>),
            'sdk': {
              ...((emulatorReport['android'] as Map)['sdk'] as Map<String, dynamic>),
              'root': emulatorSettings['sdkPath'],
              'source': 'custom',
            },
          },
      },
    },
    'settings': emulatorSettings,
    'nodes': emulatorNodes,
  };

  Future<bool> handle(
    HttpRequest r,
    String path,
    Future<void> Function(int status, Object body) json,
  ) async {
    final m = r.method;
    final key = '$m $path';
    final mine =
        path == '/api/setup' ||
        path.startsWith('/api/setup/') ||
        path.startsWith('/api/auth/') && path != '/api/auth/login' ||
        path.startsWith('/api/settings/machines') ||
        path.startsWith('/api/nodes') ||
        path.startsWith('/api/emulators') ||
        path.startsWith('/api/backup/') ||
        path == '/api/update/safety-backup' ||
        path == '/api/vault' ||
        path.startsWith('/api/jobs/');
    if (!mine) return false;
    Object? body;
    if (m != 'GET') {
      final bytes = await r.fold<List<int>>([], (a, b) => a..addAll(b));
      if (path == '/api/backup/upload') {
        body = bytes.length;
      } else {
        final text = utf8.decode(bytes);
        body = text.isEmpty ? <String, dynamic>{} : jsonDecode(text);
      }
      bodies[key] = body;
    }
    calls.add(key);
    final b = body is Map<String, dynamic> ? body : const <String, dynamic>{};
    Future<bool> ok([Object? v]) async {
      await json(200, v ?? {'ok': true});
      return true;
    }

    Future<bool> no(int status, String error, [String? code]) async {
      await json(status, {'error': error, 'code': ?code});
      return true;
    }

    // ---- jobs ----
    final jm = RegExp(r'^/api/jobs/([^/]+)$').firstMatch(path);
    if (jm != null) {
      final j = jobs[jm.group(1)];
      if (j == null) return false;
      final reads = j['reads'] as int;
      if (reads > 0) {
        j['reads'] = reads - 1;
        return ok({...j, 'state': 'running'});
      }
      return ok(j);
    }

    switch (key) {
      case 'GET /api/setup':
        return ok(_setup());
      // ---- access from outside ----
      case 'GET /api/auth/methods':
        return ok({'password': password, 'code': code});
      case 'PUT /api/auth/password':
        if (refusePassword != null) {
          final c = refusePassword;
          refusePassword = null;
          return no(400, 'Too short', c);
        }
        password = true;
        return ok();
      case 'POST /api/auth/code/new':
        return ok({
          'secret': 'JBSWY3DPEHPK3PXP',
          'url': 'otpauth://totp/Rasgeth:local?secret=JBSWY3DPEHPK3PXP&issuer=Rasgeth',
        });
      case 'POST /api/auth/code':
        if (b['code'] != '123456') return no(400, 'Wrong code', 'wrong');
        code = true;
        return ok();
      case 'DELETE /api/auth/code':
        code = false;
        return ok();
      case 'POST /api/auth/sessions/revoke':
        return ok();
      case 'POST /api/setup/remote':
        final id = job(
          'remote',
          ['tailscale', 'tailscale_up'],
          {'url': 'https://rasgeth.tail1234.ts.net'},
        );
        remote = {'way': b['way'], 'url': 'https://rasgeth.tail1234.ts.net'};
        return ok({'id': id, 'state': 'running', 'kind': 'remote', 'steps': <Object>[]});
      case 'DELETE /api/setup/remote':
        remote = null;
        return ok();
      case 'PUT /api/setup/reachable':
        reachable = b['on'] == true ? {'url': ?b['url']} : null;
        return ok();
      case 'GET /api/setup/net':
        return ok(net);
      case 'POST /api/setup/net/probe':
        final n = '${b['name']}';
        return ok(
          n.startsWith('git.')
              ? {
                  'name': n,
                  'address': '100.80.1.2',
                  'reachable': false,
                  'status': null,
                  'why': 'unreachable',
                }
              : {
                  'name': n,
                  'address': null,
                  'reachable': false,
                  'status': null,
                  'why': 'not_found',
                },
        );
      case 'POST /api/setup/pihole':
        pihole = {
          'lanIp': b['lanIp'],
          'domain': ?b['domain'],
          'adminUrl': 'http://192.168.1.50:8053/admin',
        };
        return ok({
          'id': job('pihole', ['pihole_image', 'pihole_start'], {}),
          'state': 'running',
        });
      case 'DELETE /api/setup/pihole':
        pihole = null;
        return ok();
      case 'GET /api/setup/pihole/password':
        return ok({'password': 'pi-hole-word'});
      // ---- the system ----
      case 'PUT /api/setup/role':
        role = '${b['role']}';
        return ok();
      case 'GET /api/setup/storage':
        return ok(_storage());
      case 'POST /api/setup/backups/disk':
        destination = {
          'kind': 'disk',
          'uuid': b['uuid'],
          'label': 'Eternatus',
          'path': '/var/lib/redgiant/backups/Eternatus',
        };
        return ok({'destination': destination, 'schedule': schedule});
      case 'PUT /api/setup/backups/folder':
        destination = {'kind': 'folder', 'path': b['path']};
        return ok({'destination': destination, 'schedule': schedule});
      case 'PUT /api/setup/backups':
        schedule = {...schedule, ...(b['schedule'] as Map<String, dynamic>? ?? const {})};
        return ok({'destination': ?destination, 'schedule': schedule});
      case 'POST /api/setup/backups/run':
        return ok({'started': true});
      case 'GET /api/setup/backups/targets':
        return ok({
          'machines': [
            for (final mm in machines)
              {
                'id': mm['id'],
                'name': mm['name'],
                'host': mm['host'],
                'user': mm['user'],
                'trusted': mm['hostKey'] != null,
              },
          ],
          'smb': {'available': true, 'password': false},
          'nodes': <Object>[],
        });
      case 'PUT /api/setup/backups/sftp':
        final mm = machines.firstWhere((x) => x['id'] == b['machineId']);
        destination = {
          'kind': 'sftp',
          'machineId': mm['id'],
          'machineName': mm['name'],
          'path': b['path'],
        };
        return ok({'destination': destination, 'schedule': schedule});
      case 'GET /api/setup/backups/list':
        return ok({'where': '${destination?['path'] ?? ''}', 'backups': backups});
      case 'POST /api/setup/backups/restore':
        return ok({
          'id': job(
            'restore',
            ['read', 'projects', 'conversations'],
            {'projects': '2', 'agents': '5', 'conversations': '14'},
          ),
        });
      case 'GET /api/setup/ssh':
        return ok(ssh);
      case 'PUT /api/setup/ssh':
        ssh = {'available': true, 'on': b['on'] == true, 'keys': b['key'] != null ? 1 : 0};
        return ok(ssh);
      case 'GET /api/setup/wifi':
        return ok(wifi);
      case 'POST /api/setup/wifi/scan':
        return ok(wifi);
      case 'POST /api/setup/wifi/connect':
        if (b['password'] == 'sbagliata') return no(400, 'Wrong password', 'wrong_password');
        wifi = {...wifi, 'connected': b['ssid']};
        return ok({'state': 'connected', 'wifi': wifi});
      case 'POST /api/setup/wifi/forget':
        wifi = {
          ...wifi,
          'known': [
            for (final k in wifi['known'] as List)
              if (k != b['ssid']) k,
          ],
        };
        return ok(wifi);
      case 'GET /api/setup/https':
        return ok(https);
      case 'PUT /api/setup/https':
        https = {
          ...https,
          if (b['local'] != null) 'on': b['local'],
          if (b['redirect'] != null) 'redirect': b['redirect'],
        };
        return ok(https);
      case 'GET /api/setup/os-updates':
      case 'POST /api/setup/os-updates/check':
        return ok(osUpdates);
      case 'POST /api/setup/os/reboot':
        return ok({'in': 5});
      // ---- machines ----
      case 'GET /api/settings/machines':
        return ok({'machines': machines});
      case 'POST /api/settings/machines':
        final id = 'm${machines.length + 1}';
        final mm = {
          'id': id,
          'name': b['name'],
          'host': b['host'],
          'port': b['port'] ?? 22,
          'user': b['user'],
          'auth': b['auth'] ?? 'key',
          if (b['auth'] != 'password') ...{
            'keySource': b['privateKey'] != null ? 'imported' : 'generated',
            'publicKey': 'ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIDemoKey rasgeth@$id',
          },
          'hasPassword': b['password'] != null,
          'folder': ?b['folder'],
          'access': b['access'],
          'createdAt': '2026-11-21T10:00:00.000Z',
          'updatedAt': '2026-11-21T10:00:00.000Z',
        };
        machines.add(mm);
        return ok(mm);
    }
    final mt = RegExp(r'^/api/settings/machines/([^/]+)(/test|/trust)?$').firstMatch(path);
    if (mt != null) {
      final id = mt.group(1);
      final mm = machines.where((x) => x['id'] == id).firstOrNull;
      if (mm == null) return no(404, 'No such machine');
      switch ((m, mt.group(2))) {
        case ('DELETE', null):
          machines.remove(mm);
          return ok();
        case ('PUT', null):
          mm.addAll({
            for (final k in ['name', 'host', 'port', 'user', 'folder', 'access'])
              if (b.containsKey(k)) k: b[k],
          });
          return ok(mm);
        case ('POST', '/test'):
          final code = testCode.remove(id) ?? (mm['hostKey'] == null ? 'host-key-new' : 'ok');
          if (code == 'host-key-new' || code == 'host-key-changed') {
            return ok({
              'ok': false,
              'code': code,
              'message': '',
              'hostKey': {'type': 'ssh-ed25519', 'fingerprint': 'SHA256:newKeyNewKeyNewKey'},
              if (code == 'host-key-changed') 'expected': 'SHA256:oldKeyOldKeyOldKey',
            });
          }
          mm['lastTest'] = {'at': '2026-11-21T10:01:00.000Z', 'ok': code == 'ok', 'code': code};
          return ok({
            'ok': code == 'ok',
            'code': code,
            'message': code == 'ok' ? '' : 'Permission denied',
            if (code == 'ok') 'system': 'Debian 13',
          });
        case ('POST', '/trust'):
          mm['hostKey'] = {
            'type': 'ssh-ed25519',
            'fingerprint': b['fingerprint'],
            'pinnedAt': '2026-11-21T10:01:00.000Z',
          };
          return ok(mm);
      }
    }
    // ---- nodes ----
    switch (key) {
      // ---- emulators (3.11) ----
      case 'GET /api/emulators':
        return ok(_emulators());
      case 'PUT /api/emulators/settings':
        if (b.containsKey('sdkPath')) {
          final p = b['sdkPath'];
          if (p is String && !p.toLowerCase().contains('sdk')) {
            return no(
              400,
              'No Android SDK in that folder (no platform-tools, emulator, cmdline-tools or system-images)',
            );
          }
          emulatorSettings['sdkPath'] = p;
        }
        if (b['maxRunning'] is int) emulatorSettings['maxRunning'] = b['maxRunning'];
        return ok(_emulators());
      case 'GET /api/nodes':
        return ok(_nodes());
      case 'POST /api/nodes/code':
        code_ = {
          'code': 'K7QM-4XRP',
          'expiresAt': DateTime.now().toUtc().add(const Duration(minutes: 10)).toIso8601String(),
        };
        return ok(code_);
      case 'DELETE /api/nodes/code':
        code_ = null;
        return ok();
      case 'PUT /api/nodes/name':
        machineName = '${b['name']}';
        return ok();
      case 'POST /api/nodes/pair':
        if (b['code'] != 'K7QM-4XRP') return no(400, 'Wrong code', 'pair_code');
        return ok({'fingerprint': 'SHA256:principal', 'name': 'Severino', 'sas': '482 913'});
      case 'POST /api/nodes/confirm':
        final p = pending.where((x) => x['fingerprint'] == b['fingerprint']).firstOrNull;
        if (p == null) return no(404, 'No pair');
        pending.remove(p);
        children.add({
          'fingerprint': p['fingerprint'],
          'name': b['name'] ?? p['name'],
          'relation': 'child',
          'status': 'online',
          'capabilities': {
            'sandbox': {'ok': true, 'cpus': 8, 'memoryMb': 16384, 'container': true},
            'models': [
              {
                'provider': 'local',
                'models': ['qwen3-8b'],
              },
            ],
            'storage': {'ok': true, 'freeBytes': 400 * 1073741824},
            'load': {'cpu': 12},
          },
          'grants': [
            {
              'id': 'g1',
              'controller': 'SHA256:selfSelfSelfSelf1234',
              'controllerName': machineName,
              'rights': ['use'],
            },
          ],
          'children': <Object>[],
        });
        return ok(_nodes());
      case 'POST /api/nodes/reject':
        pending.removeWhere((x) => x['fingerprint'] == b['fingerprint']);
        return ok();
      case 'POST /api/nodes/unpair':
        children.removeWhere((x) => x['fingerprint'] == b['fingerprint']);
        return ok();
      case 'PUT /api/nodes/label':
        for (final c in children) {
          if (c['fingerprint'] == b['fingerprint']) c['name'] = b['name'];
        }
        return ok();
      case 'POST /api/nodes/grants':
        return ok({'id': 'g${grants.length + 2}'});
      case 'PUT /api/nodes/placements':
        final scope = b['scope'];
        final pl = placements.where((x) => x['scope'] == scope).firstOrNull;
        final next = {...?pl, ...b}..removeWhere((k, v) => v == null);
        placements
          ..remove(pl)
          ..add(next);
        return ok({'placements': placements});
      // ---- the backup file ----
      case 'POST /api/backup/export':
        return ok({
          'id': job(
            'backup',
            ['projects', 'conversations', 'write'],
            {'file': 'rasgeth-2026-11-21.rgbackup'},
          ),
        });
      case 'POST /api/backup/upload':
        return ok({
          'id': 'up1',
          'preview': {
            'createdAt': '2026-11-19T18:30:00.000Z',
            'projects': [
              {'id': 'p1', 'name': 'Sito', 'exists': false},
              {'id': 'p2', 'name': 'Demo', 'exists': true},
            ],
            'agents': 4,
            'conversations': 12,
            'chats': 3,
            'filesBytes': 25 * 1048576,
            'keychain': false,
            'names': [
              {'kind': 'god', 'backup': 'Zeus', 'here': 'God'},
            ],
          },
        });
      case 'POST /api/backup/import':
        return ok({
          'id': job(
            'import',
            ['read', 'projects', 'conversations'],
            {'projects': '1', 'agents': '4', 'conversations': '15'},
          ),
        });
      case 'POST /api/update/safety-backup':
        return ok({
          'id': job(
            'safety_backup',
            ['projects', 'conversations', 'write', 'verify'],
            {
              'folder': '/home/mario/Documents/Rasgeth backup',
              'file': 'rasgeth-3.10.0.rgbackup',
              'bytes': '${52 * 1048576}',
              'projects': '3',
              'conversations': '27',
              if (b['keychainPassphrase'] != null) 'keychain': 'true',
            },
          ),
        });
      case 'GET /api/vault':
        return ok({
          'entries': [
            {'id': 'k1'},
            {'id': 'k2'},
          ],
        });
    }
    final file = RegExp(r'^/api/backup/file/(.+)$').firstMatch(path);
    if (m == 'GET' && file != null) {
      final bytes = List<int>.filled(4096, 7);
      r.response
        ..statusCode = 200
        ..headers.contentType = ContentType.binary
        ..contentLength = bytes.length
        ..add(bytes);
      await r.response.close();
      return true;
    }
    return false;
  }
}

// Joining the temporary network (G40.8), system by system, with the programs acted out: what is
// run, with which arguments, and that nothing of the person's own is ever removed.
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rgcompanion/api/types.dart';
import 'package:rgcompanion/setup/wifi.dart';

/// Records every program run and answers from a table (`exe args…` prefix → result).
class FakeRunner {
  FakeRunner(this.answers);

  final Map<String, CmdResult> answers;
  final calls = <String>[];

  Future<CmdResult> call(String exe, List<String> args) async {
    final line = [exe, ...args].join(' ');
    calls.add(line);
    for (final e in answers.entries) {
      if (line.startsWith(e.key)) return e.value;
    }
    return const CmdResult(0, '');
  }
}

void main() {
  group('names', () {
    test('only the temporary network\'s own names', () {
      for (final (s, ok) in [
        ('RedGiant-Setup-A1B2', true),
        ('RedGiant-Setup-D3M0', true),
        ('RedGiant-Setup-', false),
        ('RedGiant-Setup-A1 B2', false),
        ('RedGiant-Setup-A1B2"; rm -rf /', false),
        ('Casa Rossi', false),
        ('redgiant-setup-a1b2', false),
        ('RedGiant-Setup-${'A' * 17}', false),
      ]) {
        expect(isSetupSsid(s), ok, reason: s);
      }
      expect(setupSsidFrom('a1b2'), 'RedGiant-Setup-a1b2');
      expect(setupSsidFrom(' RedGiant-Setup-Z9 '), 'RedGiant-Setup-Z9');
      expect(setupSsidFrom('a b'), isNull);
      expect(setupSsidFrom(''), isNull);
    });

    test('each system its way in', () {
      expect(setupWifiFor(DevicePlatform.android), isA<PlatformChannelWifi>());
      expect(setupWifiFor(DevicePlatform.ios), isA<PlatformChannelWifi>());
      expect(setupWifiFor(DevicePlatform.windows), isA<WindowsNetshWifi>());
      expect(setupWifiFor(DevicePlatform.linux), isA<LinuxNmcliWifi>());
      expect(setupWifiFor(DevicePlatform.macos), isA<ManualWifi>());
      expect(setupWifiFor(DevicePlatform.macos).automatic, isFalse);
    });
  });

  group('Linux, NetworkManager', () {
    test('nmcli\'s terse output, escapes included', () {
      expect(nmcliFields(r'Casa\: Rossi:80'), ['Casa: Rossi', '80']);
      expect(nmcliFields(r'a\\b:c'), [r'a\b', 'c']);
      expect(
        parseNmcliWifiList(
          'RedGiant-Setup-AB12:54\nCasa Rossi:90\nRedGiant-Setup-ZZ99:71\n'
          'RedGiant-Setup-AB12:60\n:40\n',
        ),
        [
          const SeenNetwork('RedGiant-Setup-ZZ99', 71),
          const SeenNetwork('RedGiant-Setup-AB12', 60),
        ],
      );
      expect(
        parseNmcliActiveWifi('Wired connection 1:802-3-ethernet\nCasa\\: Rossi:802-11-wireless\n'),
        'Casa: Rossi',
      );
      expect(parseNmcliActiveWifi('rgcompanion-setup:802-11-wireless\n'), isNull);
    });

    test('a connection of our own: added, never the default route, deleted after; the one '
        'before comes back', () async {
      final run = FakeRunner({
        'nmcli -t -f RUNNING general': const CmdResult(0, 'running\n'),
        'nmcli -t -f NAME,TYPE connection show --active': const CmdResult(
          0,
          'Casa Rossi:802-11-wireless\n',
        ),
      });
      final w = LinuxNmcliWifi(run: run.call);
      expect(await w.join(ssid: 'Casa'), isA<JoinResult>().having((r) => r.ok, 'ok', false));
      expect(run.calls, isEmpty);
      final r = await w.join(ssid: 'RedGiant-Setup-AB12');
      expect(r.ok, isTrue);
      expect(r.ssid, 'RedGiant-Setup-AB12');
      final add = run.calls.firstWhere((c) => c.startsWith('nmcli connection add'));
      expect(add, contains('con-name rgcompanion-setup ssid RedGiant-Setup-AB12'));
      expect(add, contains('wifi-sec.psk redgiant'));
      expect(add, contains('ipv4.never-default yes'));
      expect(add, contains('connection.autoconnect no'));
      expect(run.calls, contains('nmcli --wait 30 connection up id rgcompanion-setup'));
      run.calls.clear();
      await w.leave();
      expect(run.calls, [
        'nmcli connection delete id rgcompanion-setup',
        'nmcli connection up id Casa Rossi',
      ]);
      // Only our own name is ever deleted.
      expect(
        run.calls.where((c) => c.contains('delete') && !c.endsWith('rgcompanion-setup')),
        isEmpty,
      );
    });

    test('without NetworkManager: by hand', () async {
      final run = FakeRunner({'nmcli': const CmdResult(127, '', 'not found')});
      final r = await LinuxNmcliWifi(run: run.call).join(ssid: 'RedGiant-Setup-AB12');
      expect(r.state, JoinState.unsupported);
    });

    test('a connection that does not come up is removed at once', () async {
      final run = FakeRunner({
        'nmcli -t -f RUNNING general': const CmdResult(0, 'running\n'),
        'nmcli --wait 30 connection up': const CmdResult(4, '', 'Secrets were required'),
      });
      final r = await LinuxNmcliWifi(run: run.call).join(ssid: 'RedGiant-Setup-AB12');
      expect(r.state, JoinState.failed);
      expect(run.calls.last, 'nmcli connection delete id rgcompanion-setup');
    });
  });

  group('Windows, netsh', () {
    // An Italian Windows: the labels are translated, «SSID» is not.
    const networks = '''
Nome interfaccia : Wi-Fi
Attualmente sono visibili 3 reti.

SSID 1 : Casa Rossi
    Tipo di rete            : Infrastruttura
    Autenticazione          : WPA2-Personal

SSID 2 : RedGiant-Setup-AB12
    Tipo di rete            : Infrastruttura

SSID 3 : RedGiant-Setup-AB12
''';
    const iface = '''
    Nome                   : Wi-Fi
    Stato                  : connessa
    SSID                   : Casa Rossi
    BSSID                  : 12:34:56:78:9a:bc
    Profilo                : Casa Rossi
''';

    test('the networks and the one in use, in any language', () {
      expect(parseNetshNetworks(networks), [const SeenNetwork('RedGiant-Setup-AB12', 0)]);
      expect(parseNetshCurrentSsid(iface), 'Casa Rossi');
      expect(parseNetshCurrentSsid('    Stato : disconnessa\n'), isNull);
    });

    test('the profile: WPA2-PSK with AES, by hand only, escaped', () {
      final x = windowsProfileXml('RedGiant-Setup-AB12');
      expect(x, contains('<name>RedGiant-Setup-AB12</name>'));
      expect(x, contains('<authentication>WPA2PSK</authentication>'));
      expect(x, contains('<encryption>AES</encryption>'));
      expect(x, contains('<connectionMode>manual</connectionMode>'));
      expect(x, contains('<keyMaterial>redgiant</keyMaterial>'));
      expect(windowsProfileXml('a<b>&"\''), contains('a&lt;b&gt;&amp;&quot;&apos;'));
    });

    Future<Directory> temp() => Directory.systemTemp.createTemp('rgc-test-');

    test('no profile of the person\'s: ours is added, then deleted; the network before comes '
        'back', () async {
      var connected = false;
      final calls = <String>[];
      Future<CmdResult> run(String exe, List<String> args) async {
        final line = [exe, ...args].join(' ');
        calls.add(line);
        if (line == 'netsh wlan show interfaces') {
          return CmdResult(
            0,
            connected ? iface.replaceAll('Casa Rossi', 'RedGiant-Setup-AB12') : iface,
          );
        }
        if (line.startsWith('netsh wlan show profiles')) return const CmdResult(1, 'not found');
        if (line.startsWith('netsh wlan add profile')) {
          final path = args.firstWhere((a) => a.startsWith('filename=')).substring(9);
          expect(File(path).readAsStringSync(), contains('RedGiant-Setup-AB12'));
          return const CmdResult(0, 'added');
        }
        if (line.startsWith('netsh wlan connect name=RedGiant')) connected = true;
        return const CmdResult(0, '');
      }

      final w = WindowsNetshWifi(run: run, tempDir: temp, settle: Duration.zero);
      final r = await w.join(ssid: 'RedGiant-Setup-AB12');
      expect(r.ok, isTrue, reason: '${r.message}');
      expect(calls.where((c) => c.startsWith('netsh wlan add profile')), hasLength(1));
      expect(
        calls,
        contains('netsh wlan connect name=RedGiant-Setup-AB12 ssid=RedGiant-Setup-AB12'),
      );
      calls.clear();
      await w.leave();
      expect(calls, [
        'netsh wlan delete profile name=RedGiant-Setup-AB12',
        'netsh wlan connect name=Casa Rossi',
      ]);
    });

    test('the person\'s own profile for that network stays as it is', () async {
      var connected = false;
      final calls = <String>[];
      Future<CmdResult> run(String exe, List<String> args) async {
        final line = [exe, ...args].join(' ');
        calls.add(line);
        if (line == 'netsh wlan show interfaces') {
          return CmdResult(
            0,
            connected ? iface.replaceAll('Casa Rossi', 'RedGiant-Setup-AB12') : iface,
          );
        }
        if (line.startsWith('netsh wlan connect name=RedGiant')) connected = true;
        return const CmdResult(0, '');
      }

      final w = WindowsNetshWifi(run: run, tempDir: temp, settle: Duration.zero);
      expect((await w.join(ssid: 'RedGiant-Setup-AB12')).ok, isTrue);
      await w.leave();
      expect(
        calls.where((c) => c.contains('add profile') || c.contains('delete profile')),
        isEmpty,
      );
    });

    test('a network that never comes: ours is deleted, a failure', () async {
      final calls = <String>[];
      Future<CmdResult> run(String exe, List<String> args) async {
        final line = [exe, ...args].join(' ');
        calls.add(line);
        if (line == 'netsh wlan show interfaces') return const CmdResult(0, iface);
        if (line.startsWith('netsh wlan show profiles')) return const CmdResult(1, '');
        return const CmdResult(0, '');
      }

      final w = WindowsNetshWifi(run: run, tempDir: temp, settle: Duration.zero, tries: 3);
      final r = await w.join(ssid: 'RedGiant-Setup-AB12');
      expect(r.state, JoinState.failed);
      expect(calls, contains('netsh wlan delete profile name=RedGiant-Setup-AB12'));
    });

    test('a name that is not the temporary network\'s: nothing runs', () async {
      final run = FakeRunner({});
      final r = await WindowsNetshWifi(run: run.call).join(ssid: 'Casa" & del');
      expect(r.state, JoinState.failed);
      expect(run.calls, isEmpty);
    });
  });

  group('Android and iOS, the platform channel', () {
    TestWidgetsFlutterBinding.ensureInitialized();
    const ch = MethodChannel('rgcompanion/setup_wifi-test');

    test('the prefix and the public password go; the answer comes back', () async {
      final seen = <MethodCall>[];
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(
        ch,
        (call) async {
          seen.add(call);
          if (call.method == 'join') {
            return {'state': 'joined', 'ssid': 'RedGiant-Setup-AB12'};
          }
          return null;
        },
      );
      final w = PlatformChannelWifi(channel: ch);
      final r = await w.join();
      expect(r.ok, isTrue);
      expect(r.ssid, 'RedGiant-Setup-AB12');
      expect(seen.single.arguments, {'prefix': 'RedGiant-Setup-', 'passphrase': 'redgiant'});
      await w.leave();
      expect(seen.last.method, 'leave');
    });

    test('a refusal, a missing permission, an odd name, no plugin', () async {
      final answers = <Object?>[
        {'state': 'cancelled'},
        {'state': 'denied', 'message': 'android.permission.NEARBY_WIFI_DEVICES'},
        {'state': 'joined', 'ssid': 'Casa Rossi'},
        {'state': 'something else'},
      ];
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(
        ch,
        (call) async => answers.removeAt(0),
      );
      final w = PlatformChannelWifi(channel: ch);
      expect((await w.join()).state, JoinState.cancelled);
      expect((await w.join()).state, JoinState.denied);
      // A name that is not the temporary network's is never taken as the one joined.
      expect((await w.join()).ssid, isNull);
      expect((await w.join()).state, JoinState.failed);
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(
        ch,
        null,
      );
      expect((await w.join()).state, JoinState.unsupported);
    });
  });
}

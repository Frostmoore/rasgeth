// Joining RedGiant OS's temporary network, RedGiant-Setup-XXXX (G40.8; study G40 section 2.4),
// system by system. The network has a public password, `redgiant` (iwd makes no open access
// points; the security is the setup channel's, never the Wi-Fi's).
//   - Android 10+: WifiNetworkSpecifier with the prefix, through the app's own platform channel
//     (MainActivity.kt): a network without internet bound to the app alone, the phone's own
//     connection stays the default one; NEARBY_WIFI_DEVICES on 13+, the location before.
//   - iOS: NEHotspotConfiguration with the prefix, joinOnce (AppDelegate.swift), the Hotspot
//     Configuration entitlement.
//   - Windows: netsh wlan with a temporary profile, added only when the person has none for that
//     network and deleted afterwards; the network the computer was on comes back.
//   - Linux: NetworkManager (nmcli) with a connection of our own that is never the default route
//     and never connects by itself, deleted afterwards.
//   - macOS (CoreWLAN needs the location and a scan to see a name) and anything else: the person
//     joins by hand, with the name and the password on screen, and comes back.
// Every program runs without a shell, with arguments checked first ([isSetupSsid]).
import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/services.dart';

import '../api/types.dart';

const String kSetupSsidPrefix = 'RedGiant-Setup-';
const String kSetupPassphrase = 'redgiant';

/// The temporary network's name as the app shows it before it knows the four last characters.
const String kSetupSsidPattern = 'RedGiant-Setup-XXXX';

/// RedGiant-Setup- and a few letters or digits (the machine's own, from its fingerprint).
bool isSetupSsid(String s) => RegExp(r'^RedGiant-Setup-[A-Za-z0-9]{1,16}$').hasMatch(s);

/// The four last characters the person typed (they read them in the system's Wi-Fi list), as the
/// full name; null when they are not letters or digits.
String? setupSsidFrom(String typed) {
  final t = typed.trim();
  final full = t.startsWith(kSetupSsidPrefix) ? t : '$kSetupSsidPrefix$t';
  return isSetupSsid(full) ? full : null;
}

/// A temporary network seen around, with its signal (0-100).
class SeenNetwork {
  const SeenNetwork(this.ssid, this.signal);

  final String ssid;
  final int signal;

  @override
  bool operator ==(Object other) => other is SeenNetwork && other.ssid == ssid;

  @override
  int get hashCode => ssid.hashCode;
}

enum JoinState {
  /// On the temporary network: the setup channel can be dialled.
  joined,

  /// The person said no (the system's sheet, a permission).
  cancelled,

  /// A permission is missing (location, nearby devices).
  denied,

  /// This system cannot join by itself: by hand.
  unsupported,

  /// It tried and it did not work (no such network, a timeout).
  failed,
}

class JoinResult {
  const JoinResult(this.state, {this.ssid, this.message});

  final JoinState state;
  final String? ssid;
  final String? message;

  bool get ok => state == JoinState.joined;
}

abstract class SetupWifi {
  /// Whether this system joins by itself (false: only by hand).
  bool get automatic;

  /// Whether it needs the network's exact name ([scan] or the person's four characters).
  bool get needsName;

  /// The temporary networks around, the strongest first ([] when the system does not say).
  Future<List<SeenNetwork>> scan();

  /// Joins [ssid] (or any network with the prefix, where the system offers it).
  Future<JoinResult> join({String? ssid});

  /// Leaves the temporary network: what was added is removed, the network before comes back.
  Future<void> leave();
}

/// By hand: the person joins from the system's Wi-Fi list and comes back.
class ManualWifi implements SetupWifi {
  const ManualWifi();

  @override
  bool get automatic => false;

  @override
  bool get needsName => false;

  @override
  Future<List<SeenNetwork>> scan() async => const [];

  @override
  Future<JoinResult> join({String? ssid}) async => const JoinResult(JoinState.unsupported);

  @override
  Future<void> leave() async {}
}

/// A program's answer.
class CmdResult {
  const CmdResult(this.exitCode, this.stdout, [this.stderr = '']);

  final int exitCode;
  final String stdout;
  final String stderr;

  bool get ok => exitCode == 0;
}

/// Runs a program without a shell.
typedef RunCommand = Future<CmdResult> Function(String exe, List<String> args);

Future<CmdResult> runProcess(String exe, List<String> args) async {
  try {
    final r = await Process.run(
      exe,
      args,
      runInShell: false,
      stdoutEncoding: utf8,
      stderrEncoding: utf8,
    ).timeout(const Duration(seconds: 60));
    return CmdResult(r.exitCode, '${r.stdout}', '${r.stderr}');
  } on ProcessException catch (e) {
    return CmdResult(127, '', e.message);
  } on TimeoutException {
    return const CmdResult(124, '', 'timeout');
  }
}

// ---- Linux: NetworkManager ---------------------------------------------------------------------

/// nmcli's terse output: fields split on unescaped colons, `\:` and `\\` read back.
List<String> nmcliFields(String line) {
  final out = <String>[];
  final b = StringBuffer();
  for (var i = 0; i < line.length; i++) {
    final ch = line[i];
    if (ch == r'\' && i + 1 < line.length) {
      b.write(line[++i]);
    } else if (ch == ':') {
      out.add(b.toString());
      b.clear();
    } else {
      b.write(ch);
    }
  }
  out.add(b.toString());
  return out;
}

/// `nmcli -t -f SSID,SIGNAL device wifi list`: the temporary networks, strongest first.
List<SeenNetwork> parseNmcliWifiList(String out) {
  final best = <String, int>{};
  for (final line in const LineSplitter().convert(out)) {
    final f = nmcliFields(line);
    if (f.length < 2 || !isSetupSsid(f[0])) continue;
    final signal = int.tryParse(f[1].trim()) ?? 0;
    if ((best[f[0]] ?? -1) < signal) best[f[0]] = signal;
  }
  return [for (final e in best.entries) SeenNetwork(e.key, e.value)]
    ..sort((a, b) => b.signal.compareTo(a.signal));
}

/// `nmcli -t -f NAME,TYPE connection show --active`: the Wi-Fi connection in use, if any.
String? parseNmcliActiveWifi(String out) {
  for (final line in const LineSplitter().convert(out)) {
    final f = nmcliFields(line);
    if (f.length >= 2 && f[1] == '802-11-wireless' && f[0] != LinuxNmcliWifi.connectionName) {
      return f[0];
    }
  }
  return null;
}

class LinuxNmcliWifi implements SetupWifi {
  LinuxNmcliWifi({RunCommand? run}) : _run = run ?? runProcess;

  /// The connection of our own: a name no person's connection has.
  static const connectionName = 'rgcompanion-setup';

  final RunCommand _run;
  String? _previous;
  bool _added = false;

  Future<CmdResult> _nm(List<String> args) => _run('nmcli', args);

  @override
  bool get automatic => true;

  @override
  bool get needsName => true;

  @override
  Future<List<SeenNetwork>> scan() async {
    final r = await _nm(['-t', '-f', 'SSID,SIGNAL', 'device', 'wifi', 'list', '--rescan', 'yes']);
    return r.ok ? parseNmcliWifiList(r.stdout) : const [];
  }

  @override
  Future<JoinResult> join({String? ssid}) async {
    if (ssid == null || !isSetupSsid(ssid)) {
      return const JoinResult(JoinState.failed, message: 'no_name');
    }
    final general = await _nm(['-t', '-f', 'RUNNING', 'general']);
    if (!general.ok || !general.stdout.contains('running')) {
      return const JoinResult(JoinState.unsupported, message: 'no_networkmanager');
    }
    final active = await _nm(['-t', '-f', 'NAME,TYPE', 'connection', 'show', '--active']);
    _previous = active.ok ? parseNmcliActiveWifi(active.stdout) : null;
    // A leftover of ours (an app stopped halfway): only our own name is ever deleted.
    await _nm(['connection', 'delete', 'id', connectionName]);
    final add = await _nm([
      'connection', 'add', 'type', 'wifi', 'con-name', connectionName, 'ssid', ssid, //
      'wifi-sec.key-mgmt', 'wpa-psk', 'wifi-sec.psk', kSetupPassphrase,
      'ipv4.method', 'auto', 'ipv4.never-default', 'yes', 'ipv6.method', 'ignore',
      'connection.autoconnect', 'no',
    ]);
    if (!add.ok) return JoinResult(JoinState.failed, message: add.stderr.trim());
    _added = true;
    final up = await _nm(['--wait', '30', 'connection', 'up', 'id', connectionName]);
    if (!up.ok) {
      await leave();
      return JoinResult(JoinState.failed, message: up.stderr.trim());
    }
    return JoinResult(JoinState.joined, ssid: ssid);
  }

  @override
  Future<void> leave() async {
    if (_added) {
      await _nm(['connection', 'delete', 'id', connectionName]);
      _added = false;
    }
    final p = _previous;
    _previous = null;
    if (p != null) await _nm(['connection', 'up', 'id', p]);
  }
}

// ---- Windows: netsh wlan -----------------------------------------------------------------------

/// `netsh wlan show networks`: the temporary networks (the lines «SSID n : name»).
List<SeenNetwork> parseNetshNetworks(String out) {
  final seen = <String>{};
  final list = <SeenNetwork>[];
  for (final line in const LineSplitter().convert(out)) {
    final m = RegExp(r'^\s*SSID\s+\d+\s*:\s*(.*?)\s*$').firstMatch(line);
    final s = m?.group(1);
    if (s != null && isSetupSsid(s) && seen.add(s)) list.add(SeenNetwork(s, 0));
  }
  return list;
}

/// `netsh wlan show interfaces`: the network the card is on (the line «SSID : name», not BSSID).
String? parseNetshCurrentSsid(String out) {
  for (final line in const LineSplitter().convert(out)) {
    final m = RegExp(r'^\s*SSID\s*:\s*(.+?)\s*$').firstMatch(line);
    if (m != null) return m.group(1);
  }
  return null;
}

String _xml(String s) => s
    .replaceAll('&', '&amp;')
    .replaceAll('<', '&lt;')
    .replaceAll('>', '&gt;')
    .replaceAll('"', '&quot;')
    .replaceAll("'", '&apos;');

/// The temporary profile: WPA2-PSK with AES (iwd's access point), connected by hand only.
String windowsProfileXml(String ssid, {String passphrase = kSetupPassphrase}) {
  final n = _xml(ssid);
  return '<?xml version="1.0"?>\n'
      '<WLANProfile xmlns="http://www.microsoft.com/networking/WLAN/profile/v1">\n'
      '  <name>$n</name>\n'
      '  <SSIDConfig><SSID><name>$n</name></SSID></SSIDConfig>\n'
      '  <connectionType>ESS</connectionType>\n'
      '  <connectionMode>manual</connectionMode>\n'
      '  <MSM><security>\n'
      '    <authEncryption><authentication>WPA2PSK</authentication>'
      '<encryption>AES</encryption><useOneX>false</useOneX></authEncryption>\n'
      '    <sharedKey><keyType>passPhrase</keyType><protected>false</protected>'
      '<keyMaterial>${_xml(passphrase)}</keyMaterial></sharedKey>\n'
      '  </security></MSM>\n'
      '</WLANProfile>\n';
}

class WindowsNetshWifi implements SetupWifi {
  WindowsNetshWifi({
    RunCommand? run,
    Future<Directory> Function()? tempDir,
    Duration settle = const Duration(seconds: 1),
    int tries = 20,
  }) : _run = run ?? runProcess,
       _tempDir = tempDir ?? (() => Directory.systemTemp.createTemp('rgcompanion-')),
       _settle = settle,
       _tries = tries;

  final RunCommand _run;
  final Future<Directory> Function() _tempDir;
  final Duration _settle;
  final int _tries;
  String? _previous;
  String? _added;

  Future<CmdResult> _netsh(List<String> args) => _run('netsh', ['wlan', ...args]);

  @override
  bool get automatic => true;

  @override
  bool get needsName => true;

  /// Since Windows 11 24H2 the list asks for the location's consent: [] when refused.
  @override
  Future<List<SeenNetwork>> scan() async {
    final r = await _netsh(['show', 'networks']);
    return r.ok ? parseNetshNetworks(r.stdout) : const [];
  }

  @override
  Future<JoinResult> join({String? ssid}) async {
    if (ssid == null || !isSetupSsid(ssid)) {
      return const JoinResult(JoinState.failed, message: 'no_name');
    }
    final iface = await _netsh(['show', 'interfaces']);
    if (!iface.ok) return JoinResult(JoinState.unsupported, message: iface.stderr.trim());
    final before = parseNetshCurrentSsid(iface.stdout);
    _previous = before == ssid ? null : before;
    // The person's own profile for this network stays as it is: only ours is added and deleted.
    final own = await _netsh(['show', 'profiles', 'name=$ssid']);
    if (!own.ok) {
      final dir = await _tempDir();
      final file = File('${dir.path}${Platform.pathSeparator}$ssid.xml');
      try {
        await file.writeAsString(windowsProfileXml(ssid));
        final add = await _netsh(['add', 'profile', 'filename=${file.path}', 'user=current']);
        if (!add.ok) return JoinResult(JoinState.failed, message: add.stdout.trim());
        _added = ssid;
      } finally {
        try {
          await dir.delete(recursive: true);
        } on FileSystemException {
          // A temporary folder: the system cleans it.
        }
      }
    }
    final c = await _netsh(['connect', 'name=$ssid', 'ssid=$ssid']);
    if (!c.ok) {
      await leave();
      return JoinResult(JoinState.failed, message: c.stdout.trim());
    }
    for (var i = 0; i < _tries; i++) {
      final now = await _netsh(['show', 'interfaces']);
      if (now.ok && parseNetshCurrentSsid(now.stdout) == ssid) {
        return JoinResult(JoinState.joined, ssid: ssid);
      }
      await Future<void>.delayed(_settle);
    }
    await leave();
    return const JoinResult(JoinState.failed, message: 'timeout');
  }

  @override
  Future<void> leave() async {
    final a = _added;
    _added = null;
    if (a != null) await _netsh(['delete', 'profile', 'name=$a']);
    final p = _previous;
    _previous = null;
    if (p != null) await _netsh(['connect', 'name=$p']);
  }
}

// ---- Android and iOS: the app's own platform channel --------------------------------------------

/// The system's own way (Android WifiNetworkSpecifier, iOS NEHotspotConfiguration), with the
/// prefix: the system shows its sheet, the person picks the network.
class PlatformChannelWifi implements SetupWifi {
  PlatformChannelWifi({MethodChannel? channel})
    : _ch = channel ?? const MethodChannel('rgcompanion/setup_wifi');

  final MethodChannel _ch;

  @override
  bool get automatic => true;

  @override
  bool get needsName => false;

  @override
  Future<List<SeenNetwork>> scan() async => const [];

  @override
  Future<JoinResult> join({String? ssid}) async {
    try {
      final r = await _ch.invokeMapMethod<String, Object?>('join', {
        'prefix': kSetupSsidPrefix,
        'passphrase': kSetupPassphrase,
        if (ssid != null && isSetupSsid(ssid)) 'ssid': ssid,
      });
      final state = JoinState.values.firstWhere(
        (s) => s.name == r?['state'],
        orElse: () => JoinState.failed,
      );
      final got = r?['ssid'];
      return JoinResult(
        state,
        ssid: got is String && isSetupSsid(got) ? got : ssid,
        message: r?['message'] is String ? r!['message'] as String : null,
      );
    } on MissingPluginException {
      return const JoinResult(JoinState.unsupported);
    } on PlatformException catch (e) {
      return JoinResult(JoinState.failed, message: e.message);
    }
  }

  @override
  Future<void> leave() async {
    try {
      await _ch.invokeMethod<void>('leave');
    } on MissingPluginException {
      // Nothing to leave.
    } on PlatformException {
      // The system drops it with the app anyway.
    }
  }
}

/// This system's way in.
SetupWifi setupWifiFor(DevicePlatform p) => switch (p) {
  DevicePlatform.android || DevicePlatform.ios => PlatformChannelWifi(),
  DevicePlatform.windows => WindowsNetshWifi(),
  DevicePlatform.linux => LinuxNmcliWifi(),
  DevicePlatform.macos || DevicePlatform.other => const ManualWifi(),
};

// G42.14: the page's pure rules of the system's settings, in Dart: the blocks to copy for one's own
// infrastructure (packages/web/src/own-infra.ts: a reverse proxy, a VPN, a home DNS, the home
// services), «Try a name»'s verdict (`probeVerdict`) and the host's steps to pass a disk into a
// container (`hostMountGuide`, packages/protocol/src/backup-host.ts). Checked against the page's
// own answers (test/fixtures/system_vectors.json, tool/system_vectors.mjs).
import '../../brand.dart';

typedef InfraData = ({String name, String address, int port});

const placeholderName = 'rasgeth.example.com';
const placeholderAddress = '192.168.1.50';

InfraData infraData(String? name, String? address, int? port) => (
  name: (name?.trim().isEmpty ?? true) ? placeholderName : name!.trim(),
  address: (address?.trim().isEmpty ?? true) ? placeholderAddress : address!.trim(),
  port: port != null && port > 0 && port < 65536 ? port : 7600,
);

/// rasgeth.home.example.com → home.example.com.
String parentDomain(String name) {
  final parts = name.split('.');
  return parts.length > 2 ? parts.skip(1).join('.') : name;
}

/// The /24 of an IPv4 address, as a subnet router announces it.
String subnetOf(String address) {
  final m = RegExp(r'^(\d+\.\d+\.\d+)\.\d+$').firstMatch(address);
  return m != null ? '${m[1]}.0/24' : '192.168.1.0/24';
}

String caddyBlock(InfraData d) => '${d.name} {\n\treverse_proxy ${d.address}:${d.port}\n}';

String caddyWildcardBlock(InfraData d) =>
    '*.${parentDomain(d.name)} {\n\t@rasgeth host ${d.name}\n\thandle @rasgeth {\n\t\treverse_proxy ${d.address}:${d.port}\n\t}\n\t# … the other names of the wildcard\n}';

String traefikBlock(InfraData d) => [
  'http:',
  '  routers:',
  '    rasgeth:',
  '      rule: Host(`${d.name}`)',
  '      entryPoints: [websecure]',
  '      service: rasgeth',
  '      tls:',
  '        certResolver: letsencrypt',
  '  services:',
  '    rasgeth:',
  '      loadBalancer:',
  '        servers:',
  '          - url: http://${d.address}:${d.port}',
].join('\n');

String caddyForwardAuthBypass(InfraData d) =>
    '${d.name} {\n\t@app path /api/* /ws\n\thandle @app {\n\t\treverse_proxy ${d.address}:${d.port}\n\t}\n\thandle {\n\t\tforward_auth authelia:9091 {\n\t\t\turi /api/authz/forward-auth\n\t\t\tcopy_headers Remote-User Remote-Groups\n\t\t}\n\t\treverse_proxy ${d.address}:${d.port}\n\t}\n}';

String tailscaleServe(InfraData d) => 'tailscale serve --bg ${d.port}';

String tailscaleSubnet(InfraData d) => 'tailscale up --advertise-routes=${subnetOf(d.address)}';

String dnsmasqWildcard(InfraData d) => 'address=/${parentDomain(d.name)}/${d.address}';

String healthCheck(String url) => 'curl -s ${url.replaceAll(RegExp(r'/$'), '')}/api/health';

String reachUrl(String name, {bool https = true}) => '${https ? 'https' : 'http'}://$name';

typedef HomeService = ({String name, String proxy});

const placeholderService = 'git.home.example.com';
const placeholderProxy = '192.168.1.12';

HomeService homeService(String? name, String? proxy) => (
  name: (name?.trim().isEmpty ?? true) ? placeholderService : name!.trim().toLowerCase(),
  proxy: (proxy?.trim().isEmpty ?? true) ? placeholderProxy : proxy!.trim(),
);

String homeHostsLine(HomeService h) => '${h.proxy} ${h.name}';
String homeDnsmasq(HomeService h) => 'address=/${h.name}/${h.proxy}';
String homeLookup(HomeService h) => 'resolvectl query ${h.name}';
const whichDns = 'resolvectl status';

bool isTailscaleAddress(String address) {
  final m = RegExp(r'^100\.(\d+)\.\d+\.\d+$').firstMatch(address);
  if (m != null) {
    final n = int.parse(m[1]!);
    return n >= 64 && n <= 127;
  }
  return RegExp(r'^fd7a:115c:a1e0:', caseSensitive: false).hasMatch(address);
}

/// «Try a name»'s answer in words: the page's key, its tone and its values.
({String key, bool ok, Map<String, String> params}) probeVerdict(Map<String, dynamic> p) {
  final params = {
    'name': '${p['name'] ?? ''}',
    'address': p['address'] is String ? p['address'] as String : '',
    'status': p['status'] is num ? '${(p['status'] as num).toInt()}' : '',
  };
  ({String key, bool ok, Map<String, String> params}) say(String key, [bool ok = false]) =>
      (key: key, ok: ok, params: params);
  final why = p['why'];
  if (why == 'not_found') return say('oiProbeNotFound');
  if (why == 'dns_failed') return say('oiProbeDnsFailed');
  if (why == 'ok') return say('oiProbeOk', true);
  if (why == 'tls') return say('oiProbeTls');
  final a = p['address'];
  if (a is String && a.isNotEmpty && isTailscaleAddress(a)) return say('oiProbeTailscale');
  return say(why == 'timeout' ? 'oiProbeTimeout' : 'oiProbeUnreachable');
}

// ---- the host's steps (backup-host.ts) ----

const hostBackupDir = '/mnt/redgiant-backups';
const containerBackupBase = '/var/lib/redgiant/backups';
final _folderName = RegExp(r'^[A-Za-z0-9][A-Za-z0-9._-]{0,39}$');
final _device = RegExp(
  r'^/dev/(?:[a-z]{1,8}[0-9a-z]{0,12}|mapper/[A-Za-z0-9_.-]{1,64}|disk/by-(?:uuid|id|label|partuuid)/[A-Za-z0-9_.:+-]{1,120})$',
);
final _proxmoxId = RegExp(r'^[1-9][0-9]{2,8}$');

typedef HostGuide = ({bool ok, String? why, List<String> lines, String target});

/// [kind]: proxmox, docker, other.
HostGuide hostMountGuide({
  required String kind,
  required String name,
  String? device,
  String? containerId,
  int mp = 0,
  bool unprivileged = true,
  String? base,
}) {
  HostGuide no(String why) => (ok: false, why: why, lines: const [], target: '');
  if (!_folderName.hasMatch(name) || name.contains('..')) return no('bad_name');
  if (device != null && device.isNotEmpty && !_device.hasMatch(device)) return no('bad_device');
  if (containerId != null && containerId.isNotEmpty && !_proxmoxId.hasMatch(containerId)) {
    return no('bad_id');
  }
  if (mp < 0 || mp > 255) return no('bad_mp');
  final dev = (device?.isEmpty ?? true) ? '/dev/sdX1' : device!;
  final b = (base ?? containerBackupBase).replaceAll(RegExp(r'/+$'), '');
  final disk = '$hostBackupDir/$name';
  final hostDir = '$disk/RedGiant';
  final target = '$b/$name';
  final lines = [
    '# 1. Mount the disk on the host, also after a restart (nofail: the host starts without it)',
    'mkdir -p $disk',
    'mount $dev $disk',
    'echo "UUID=\$(blkid -s UUID -o value $dev) $disk auto defaults,nofail 0 2" >> /etc/fstab',
    "# 2. $kProductName's own folder on it (the rest of the disk stays out of the container)",
    'mkdir -p $hostDir',
  ];
  if (kind == 'proxmox') {
    final id = (containerId?.isEmpty ?? true) ? '<id>' : containerId!;
    if (unprivileged) lines.add('chown 100000:100000 $hostDir');
    lines.addAll([
      '# 3. Pass it to the container (a mount point; restart the container if it does not appear)',
      'pct set $id -mp$mp $hostDir,mp=$target',
    ]);
  } else if (kind == 'docker') {
    lines.addAll([
      'chown 1000:1000 $hostDir',
      '# 3. In compose.yaml, under the redgiant service, then: docker compose up -d',
      '    volumes:',
      '      - $hostDir:$target',
    ]);
  } else {
    lines.add('# 3. Make $hostDir appear inside $kProductName at $target (a bind mount)');
  }
  return (ok: true, why: null, lines: lines, target: target);
}

/// A cleaned folder name from a disk's title ("WD Elements" → "WD-Elements"), as the page's.
String folderName(String title) {
  var s = title.replaceAll(RegExp(r'[^\w.-]+'), '-');
  s = s.replaceAll(RegExp(r'^[.-]+|-+$'), '');
  if (s.length > 40) s = s.substring(0, 40);
  return s.isEmpty ? 'backups' : s;
}

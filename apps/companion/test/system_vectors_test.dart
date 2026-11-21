// G42.14: the system's pure rules in Dart against the page's own answers
// (test/fixtures/system_vectors.json from tool/system_vectors.mjs): the blocks to copy for one's
// own infrastructure, «Try a name»'s verdict, the host's steps for a disk in a container, and the
// QR codes as the page draws them (qrcode-generator), square by square.
import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:rgcompanion/settings/system/infra_rules.dart';
import 'package:rgcompanion/ui/qr.dart';

void main() {
  final v = jsonDecode(
    File('test/fixtures/system_vectors.json').readAsStringSync(),
  ) as Map<String, dynamic>;

  test('the blocks to copy, as the page fills them', () {
    for (final c in (v['infra'] as List).cast<Map<String, dynamic>>()) {
      final d = infraData(c['name'] as String, c['address'] as String, c['port'] as int?);
      final want = c['data'] as Map<String, dynamic>;
      expect((d.name, d.address, d.port), (want['name'], want['address'], want['port']));
      expect(parentDomain(d.name), c['parent']);
      expect(subnetOf(d.address), c['subnet']);
      expect(caddyBlock(d), c['caddy']);
      expect(caddyWildcardBlock(d), c['caddyWildcard']);
      expect(traefikBlock(d), c['traefik']);
      expect(caddyForwardAuthBypass(d), c['forwardAuth']);
      expect(tailscaleServe(d), c['serve']);
      expect(tailscaleSubnet(d), c['subnetUp']);
      expect(dnsmasqWildcard(d), c['dnsmasq']);
      expect(healthCheck(reachUrl(d.name)), c['health']);
      expect(healthCheck('${reachUrl(d.name, https: false)}/'), c['healthHttp']);
    }
    for (final c in (v['homes'] as List).cast<Map<String, dynamic>>()) {
      final h = homeService(c['name'] as String, c['proxy'] as String);
      final want = c['service'] as Map<String, dynamic>;
      expect((h.name, h.proxy), (want['name'], want['proxy']));
      expect(homeHostsLine(h), c['hosts']);
      expect(homeDnsmasq(h), c['dnsmasq']);
      expect(homeLookup(h), c['lookup']);
    }
  });

  test('«Try a name» in the same words', () {
    for (final c in (v['probes'] as List).cast<Map<String, dynamic>>()) {
      final got = probeVerdict(c['probe'] as Map<String, dynamic>);
      final want = c['verdict'] as Map<String, dynamic>;
      expect(got.key, want['key'], reason: '${c['probe']}');
      expect(got.ok, want['ok']);
      expect(got.params, want['params']);
    }
  });

  test('the host\'s steps for a disk, refused where the page refuses', () {
    for (final c in (v['guides'] as List).cast<Map<String, dynamic>>()) {
      final i = c['input'] as Map<String, dynamic>;
      final g = hostMountGuide(
        kind: i['kind'] as String,
        name: i['name'] as String,
        device: i['device'] as String?,
        containerId: i['containerId'] as String?,
        mp: i['mp'] as int? ?? 0,
        unprivileged: i['unprivileged'] as bool? ?? true,
        base: i['base'] as String?,
      );
      final want = c['guide'] as Map<String, dynamic>;
      expect(g.ok, want['ok'], reason: '$i');
      if (g.ok) {
        expect(g.lines, want['lines'], reason: '$i');
        expect(g.target, want['target']);
      } else {
        expect(g.why, want['why'], reason: '$i');
      }
    }
  });

  test('a QR code with the very same squares as the page\'s', () {
    for (final c in (v['qrs'] as List).cast<Map<String, dynamic>>()) {
      final m = qrModules(c['text'] as String)!;
      final rows = [for (final r in m) r.map((x) => x ? '1' : '0').join()];
      expect(rows, c['rows'], reason: c['text'] as String);
    }
  });
}

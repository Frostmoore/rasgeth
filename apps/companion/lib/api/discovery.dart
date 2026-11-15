// Finding RedGiants on the local network (G40.7): RedGiant OS announces `_redgiant._tcp` with
// avahi (port 7600, TXT `channel=/api/setup-channel`, `proto=1`). The record is only a hint: who
// the machine is, is checked over the setup channel (its pinned key), never from the record.
//
// Package: bonsoir, the one maintained Zeroconf plugin on all five systems, through each one's
// own service (Android NsdManager, Apple's Bonjour, Windows DNS-SD, Linux Avahi over D-Bus):
// no multicast socket of our own (which iOS forbids without a special entitlement, and Android
// drops without a multicast lock).
import 'dart:async';

import 'package:bonsoir/bonsoir.dart';

const String kRedGiantServiceType = '_redgiant._tcp';

/// One RedGiant announced on the network.
class FoundServer {
  const FoundServer({
    required this.name,
    required this.host,
    required this.port,
    this.channelPath = '/api/setup-channel',
    this.proto,
  });

  /// «RedGiant on» and the machine's name.
  final String name;

  /// An address (or the `.local` name) to reach it.
  final String host;
  final int port;
  final String channelPath;
  final int? proto;

  /// The plain-http address the setup channel rides on (`http://host:7600`).
  Uri get base => Uri(scheme: 'http', host: host, port: port);

  /// Without the «RedGiant on » the record adds.
  String get machine => name.replaceFirst(RegExp(r'^RedGiant on\s+'), '');

  @override
  bool operator ==(Object other) =>
      other is FoundServer && other.host == host && other.port == port;

  @override
  int get hashCode => Object.hash(host, port);
}

/// A resolved service as the app keeps it; null when it lacks an address. IPv4 first (IPv6
/// link-local addresses need a zone the URL cannot carry).
FoundServer? foundFrom({
  required String name,
  required List<String> addresses,
  String? hostname,
  required int port,
  Map<String, String> attributes = const {},
}) {
  final v4 = addresses.where((a) => RegExp(r'^\d+\.\d+\.\d+\.\d+$').hasMatch(a));
  final host = v4.isNotEmpty
      ? v4.first
      : (hostname != null && hostname.isNotEmpty
            ? hostname.replaceFirst(RegExp(r'\.$'), '')
            : null);
  if (host == null || port <= 0) return null;
  final ch = attributes['channel'];
  return FoundServer(
    name: name,
    host: host,
    port: port,
    channelPath: ch != null && ch.startsWith('/api/') ? ch : '/api/setup-channel',
    proto: int.tryParse(attributes['proto'] ?? ''),
  );
}

abstract class Discovery {
  /// The RedGiants found so far, again each time the list changes.
  Stream<List<FoundServer>> watch();
  Future<void> stop();
}

class BonsoirRedGiantDiscovery implements Discovery {
  BonsoirDiscovery? _d;
  final _found = <String, FoundServer>{};
  final _out = StreamController<List<FoundServer>>.broadcast();
  StreamSubscription<BonsoirDiscoveryEvent>? _sub;

  @override
  Stream<List<FoundServer>> watch() {
    unawaited(_start());
    return _out.stream;
  }

  Future<void> _start() async {
    if (_d != null) return;
    try {
      final d = _d = BonsoirDiscovery(type: kRedGiantServiceType, printLogs: false);
      await d.initialize();
      _sub = d.eventStream?.listen((e) {
        switch (e) {
          case BonsoirDiscoveryServiceFoundEvent(:final service):
            unawaited(service.resolve(d.serviceResolver));
          case BonsoirDiscoveryServiceResolvedEvent(:final service) ||
              BonsoirDiscoveryServiceUpdatedEvent(:final service):
            final f = foundFrom(
              name: service.name,
              addresses: service.hostAddresses,
              hostname: service.hostname,
              port: service.port,
              attributes: service.attributes,
            );
            if (f != null) _found[service.name] = f;
            _out.add(_found.values.toList());
          case BonsoirDiscoveryServiceLostEvent(:final service):
            _found.remove(service.name);
            _out.add(_found.values.toList());
          default:
            break;
        }
      });
      await d.start();
    } on Object {
      // No discovery on this system or network: the address typed by hand still works.
      _out.add(const []);
    }
  }

  @override
  Future<void> stop() async {
    await _sub?.cancel();
    await _d?.stop();
    _d = null;
  }
}

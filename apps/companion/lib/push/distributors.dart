// UnifiedPush on Android (G40.10): the person chooses the distributor (ntfy, their own ntfy,
// Sunup, NextPush…), the app registers one instance per RedGiant (its id in the app) with the
// server's VAPID key, and sends each endpoint the distributor gives to `PUT /api/devices/:id/push`
// with its own keys. Without a distributor nothing is sent: Tu › Notifiche says so plainly.
import 'dart:async';
import 'dart:io' show Platform;

import 'package:flutter/foundation.dart';
import 'package:unifiedpush/unifiedpush.dart';

import 'push_center.dart';

/// What happened to a registration, for the screen that asked.
sealed class DistributorEvent {
  const DistributorEvent(this.serverId);

  final String serverId;
}

class EndpointReady extends DistributorEvent {
  const EndpointReady(super.serverId, this.endpoint, {required this.sent});

  final String endpoint;

  /// The server took it (false: it could not be reached, the app tries again at the next start).
  final bool sent;
}

class RegistrationFailed extends DistributorEvent {
  const RegistrationFailed(super.serverId, this.reason);

  /// `network`, `actionRequired`, `vapidRequired`, `internalError`.
  final String reason;
}

class Unregistered extends DistributorEvent {
  const Unregistered(super.serverId);
}

abstract class Distributors {
  /// UnifiedPush exists here (Android).
  bool get supported;

  /// The distributors installed (their package names).
  Future<List<String>> list();

  /// The one in use, if the person chose one.
  Future<String?> current();
  Future<void> choose(String id);
  Future<void> register(String serverId, {String? vapid});
  Future<void> unregister(String serverId);
  Stream<DistributorEvent> get events;
}

/// How people call a distributor (the brand, the same in every language).
String distributorLabel(String id) => switch (id) {
  'io.heckel.ntfy' => 'ntfy',
  'org.unifiedpush.distributor.sunup' => 'Sunup',
  'org.unifiedpush.distributor.nextpush' => 'NextPush',
  'org.unifiedpush.distributor.fcm' => 'FCM',
  'chat.schildi.android' || 'im.vector.app' => 'Element',
  'org.unifiedpush.distributor.noprovider2push' => 'NoProvider2Push',
  'com.github.gotify' => 'Gotify',
  'org.unifiedpush.distributor.mollysocket' => 'MollySocket',
  _ => id.split('.').last,
};

/// For tests and for the systems without UnifiedPush.
class NoDistributors implements Distributors {
  NoDistributors({this.supported = false, List<String>? installed}) : installed = installed ?? [];

  @override
  final bool supported;
  final List<String> installed;
  String? chosen;
  final registered = <String, String?>{};
  final _events = StreamController<DistributorEvent>.broadcast();

  /// A test's distributor gives an endpoint.
  void give(DistributorEvent e) => _events.add(e);

  @override
  Future<List<String>> list() async => installed;

  @override
  Future<String?> current() async => chosen;

  @override
  Future<void> choose(String id) async => chosen = id;

  @override
  Future<void> register(String serverId, {String? vapid}) async => registered[serverId] = vapid;

  @override
  Future<void> unregister(String serverId) async => registered.remove(serverId);

  @override
  Stream<DistributorEvent> get events => _events.stream;
}

class UnifiedPushDistributors implements Distributors {
  UnifiedPushDistributors._(this.center);

  static UnifiedPushDistributors? _one;

  /// Starts listening (once per engine: the app's, or the background one the system starts for
  /// a message). Messages are shown by [center] in both.
  static Future<UnifiedPushDistributors> start(PushCenter center) async {
    final d = _one ??= UnifiedPushDistributors._(center);
    if (!d._started && d.supported) {
      d._started = true;
      await UnifiedPush.initialize(
        onNewEndpoint: (e, instance) async {
          final sent = await center.onEndpoint(instance, e.url);
          d._events.add(EndpointReady(instance, e.url, sent: sent));
        },
        onRegistrationFailed: (r, instance) => d._events.add(RegistrationFailed(instance, r.name)),
        onUnregistered: (instance) async {
          await center.onUnregistered(instance);
          d._events.add(Unregistered(instance));
        },
        onMessage: (m, instance) =>
            unawaited(center.onMessage(instance, m.content, decrypted: m.decrypted)),
      );
    }
    return d;
  }

  final PushCenter center;
  bool _started = false;
  final _events = StreamController<DistributorEvent>.broadcast();

  @override
  bool get supported => !kIsWeb && Platform.isAndroid;

  @override
  Future<List<String>> list() => UnifiedPush.getDistributors();

  @override
  Future<String?> current() => UnifiedPush.getDistributor();

  @override
  Future<void> choose(String id) => UnifiedPush.saveDistributor(id);

  @override
  Future<void> register(String serverId, {String? vapid}) =>
      UnifiedPush.register(instance: serverId, vapid: vapid);

  @override
  Future<void> unregister(String serverId) => UnifiedPush.unregister(serverId);

  @override
  Stream<DistributorEvent> get events => _events.stream;
}

// 3.9.8: the old Windows folder's data, faked (test/p398_legacy_test.dart, p398_pair_again_test.dart).
import 'dart:io';

import 'package:rgcompanion/api/legacy_data.dart';
import 'package:rgcompanion/api/token_store.dart';

class FakeLegacy implements LegacySource {
  FakeLegacy(this.data, {this.fails = false});

  LegacyAppData? data;
  bool fails;
  int reads = 0;
  int forgotten = 0;

  @override
  Future<LegacyAppData?> read() async {
    reads++;
    if (fails) throw const FileSystemException('held by another program');
    return data;
  }

  @override
  Future<void> forgetSecrets() async {
    forgotten++;
    data = LegacyAppData(servers: data?.servers ?? const [], current: data?.current);
  }
}

/// A keystore whose writes do not stick (or throw) for some names.
class FlakyTokens extends MemoryTokenStore {
  FlakyTokens({this.lose = const {}, this.throwOn = const {}});

  final Set<String> lose;
  final Set<String> throwOn;

  @override
  Future<void> write(String server, String token) async {
    if (throwOn.contains(server)) throw StateError('keystore refused');
    if (lose.contains(server)) return;
    await super.write(server, token);
  }
}

/// A keystore that cannot be read at all (the plugin drops its file and throws).
class BrokenTokens extends MemoryTokenStore {
  @override
  Future<String?> read(String server) async => throw StateError('CryptUnprotectData');
}

const kCoder = {
  'id': '833ct6le3fg8',
  'label': 'Coder',
  'address': 'https://coder.example.test',
  'fingerprint': 'SHA256:coder',
  'deviceId': 'dev_old',
};

LegacyAppData oldData({Map<String, String>? secrets, List<Map<String, dynamic>>? servers}) =>
    LegacyAppData(
      servers: servers ?? [kCoder],
      current: '833ct6le3fg8',
      secrets:
          secrets ??
          {
            'rgcompanion.token.833ct6le3fg8': 'rgd_old_token',
            'rgcompanion.token.identity': 'c2VlZA==',
            'rgcompanion.token.push.833ct6le3fg8': '{"k":1}',
            'someone.else': 'not ours',
          },
    );

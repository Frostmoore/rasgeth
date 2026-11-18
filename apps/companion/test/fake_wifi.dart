import 'package:rgcompanion/setup/wifi.dart';

/// The temporary network joined without touching any real one.
class FakeWifi implements SetupWifi {
  FakeWifi({this.answer = JoinState.joined, this.isAutomatic = true, this.name = false});

  JoinState answer;
  final bool isAutomatic;
  final bool name;
  int joins = 0;
  int leaves = 0;
  String? lastSsid;

  @override
  bool get automatic => isAutomatic;

  @override
  bool get needsName => name;

  @override
  Future<List<SeenNetwork>> scan() async => const [SeenNetwork('Rasgeth-Setup-D3M0', 80)];

  @override
  Future<JoinResult> join({String? ssid}) async {
    joins++;
    lastSsid = ssid;
    return JoinResult(answer, ssid: ssid ?? 'Rasgeth-Setup-D3M0');
  }

  @override
  Future<void> leave() async => leaves++;
}

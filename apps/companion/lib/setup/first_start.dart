// The first start from the app (G40.8; study G40 section 2): a RedGiant OS machine that has never
// been set up opens RedGiant-Setup-XXXX for 30 minutes; the app joins it ([SetupWifi]), dials the
// setup channel (the nodes' handshake, the machine's key pinned at first use), creates the access
// (the password, inside the channel), takes its device token and the local CA, chooses the home
// network (the networks the machine saw, or the cable), and while RedGiant moves there it waits
// for the phone to be back on its own network, finds RedGiant again (the address it said, mDNS,
// redgiant.local) with the same key, and goes on with what the page's wizard asks first: the
// languages, a way of thinking (a subscription or a key), the names. Then the first start is
// completed and the temporary network closes.
//
// Nothing here turns a failure into a yes: a different key, a busy channel, a password refused
// or a home network that did not work are said, and the person chooses again. The password is
// kept in memory only while the flow runs (to sign in again if RedGiant has to be met on the
// temporary network once more) and dropped at the end.
import 'dart:async';

import 'package:flutter/foundation.dart';

import '../api/client.dart';
import '../api/discovery.dart';
import '../api/servers.dart';
import '../api/settings_types.dart';
import '../api/setup_channel.dart';
import '../api/transport.dart';
import '../app_state.dart';
import 'wifi.dart';
import '../brand.dart';

/// Where RedGiant answers on its temporary network (Caddy on 80, the server itself on 7600).
final List<Uri> kSetupBases = [Uri.parse('http://10.42.0.1'), Uri.parse('http://10.42.0.1:7600')];

enum FsStep {
  /// What is about to happen; join automatically or by hand.
  intro,

  /// The person joins from the system's list and comes back.
  manual,
  joining,
  connecting,

  /// A new RedGiant: the password that will open it.
  access,

  /// It has a password already (maintenance, a first start begun before): the password.
  signIn,

  /// The home network: a Wi-Fi network it saw, or the cable.
  home,

  /// RedGiant moves to the home network; the app finds it there.
  homeWait,

  /// Not found at home, nor on the temporary network: look again or join by hand.
  homeLost,
  language,
  brain,
  names,
  finishing,
  done,
}

enum FsError {
  /// No RedGiant on the temporary network (not joined, or it closed).
  notFound,

  /// Another device is setting it up.
  busy,

  /// It answered with another key than the one pinned a moment ago.
  keyChanged,

  /// The first access is not open from here (a code is asked, or not from this network).
  notHere,
  wrongPassword,
  tooMany,

  /// The person said no to the system's sheet, or a permission.
  cancelled,
  denied,

  /// The system could not join (no NetworkManager, no such network…).
  joinFailed,

  /// The home network was refused before trying (a short password, busy…): [FirstStartFlow.code].
  homeRefused,

  /// The home Wi-Fi did not work: RedGiant came back on the temporary network with the reason.
  homeFailed,

  /// The server said no ([FirstStartFlow.detail]).
  other,
}

/// Finds RedGiant on the home network: the base to use, or null (not there yet).
typedef HomeFinder = Future<Uri?> Function(SavedServer saved, String? address);

class FirstStartFlow extends ChangeNotifier {
  FirstStartFlow(
    this.app, {
    SetupWifi? wifi,
    List<Uri>? setupBases,
    HomeFinder? findHome,
    this.homeTimeout = const Duration(seconds: 150),
    this.channelTimeout = const Duration(seconds: 25),
    this.poll = const Duration(seconds: 3),
    Future<bool> Function(Uri url)? openUrl,
  }) : wifi = wifi ?? setupWifiFor(app.platform),
       setupBases = setupBases ?? kSetupBases,
       _openUrl = openUrl ?? ((_) async => false) {
    _findHome = findHome ?? _defaultFindHome;
  }

  final AppController app;
  final SetupWifi wifi;
  final List<Uri> setupBases;
  final Duration homeTimeout;
  final Duration channelTimeout;
  final Duration poll;
  final Future<bool> Function(Uri url) _openUrl;
  late final HomeFinder _findHome;

  FsStep step = FsStep.intro;
  bool busy = false;
  FsError? error;

  /// The server's or the system's own words, or a helper's code (bad_password, connect_failed…).
  String? detail;
  String? code;

  /// Temporary networks seen around (the systems that need the exact name).
  List<SeenNetwork> seen = const [];

  /// The temporary network joined (or to join).
  String? ssid;

  /// RedGiant's key, pinned at the first handshake.
  String? fingerprint;

  /// The RedGiant set up: kept by the app with its device token.
  SavedServer? saved;

  /// What the requests go through: the setup channel, then the app's own client at home.
  RedGiantClient? client;
  SetupChannel? _ch;
  Uri? _base;

  /// RedGiant had a password already, or its first start was completed: only the home network.
  bool maintenance = false;

  /// The temporary network as RedGiant says it (the networks it saw, the last try).
  SetupNetworkStatus? network;

  /// The home network chosen (null: the cable).
  String? homeSsid;
  String? homeAddress;
  SetupSummary? summary;

  /// ChatGPT's code to type on OpenAI's page, while it waits.
  ({String url, String code})? chatgpt;

  /// Anthropic's page opened: the code it shows comes next.
  String? claudePage;
  String? _password;
  bool _disposed = false;
  Timer? _chatgptTimer;

  bool get remembersPassword => _password != null;

  void _set(FsStep s) {
    step = s;
    if (!_disposed) notifyListeners();
  }

  void _fail(FsError e, [String? d, String? c]) {
    error = e;
    detail = d;
    code = c;
    if (!_disposed) notifyListeners();
  }

  void _clear() {
    error = null;
    detail = null;
    code = null;
  }

  int _depth = 0;

  /// One action at a time; inside another one it runs as part of it (the outer one reports).
  Future<T?> _run<T>(Future<T> Function() f) async {
    if (_depth > 0) return f();
    if (busy) return null;
    _depth++;
    busy = true;
    _clear();
    if (!_disposed) notifyListeners();
    try {
      return await f();
    } on ApiException catch (e) {
      _fail(_apiError(e), e.message, e.code);
      return null;
    } on SetupChannelException catch (e) {
      _fail(_channelError(e), e.message);
      return null;
    } on SetupRequestException catch (e) {
      _fail(FsError.other, e.message, e.code);
      return null;
    } finally {
      _depth--;
      busy = false;
      if (!_disposed) notifyListeners();
    }
  }

  static FsError _apiError(ApiException e) => switch (e.code) {
    'wrong' => FsError.wrongPassword,
    'too_many' => FsError.tooMany,
    'not_here' || 'code' || 'closed' => FsError.notHere,
    _ => e.unreachable ? FsError.notFound : FsError.other,
  };

  static FsError _channelError(SetupChannelException e) => switch (e.code) {
    SetupChannelErrorCode.busy => FsError.busy,
    SetupChannelErrorCode.fingerprintChanged => FsError.keyChanged,
    SetupChannelErrorCode.unreachable ||
    SetupChannelErrorCode.timeout ||
    SetupChannelErrorCode.closed => FsError.notFound,
    SetupChannelErrorCode.protocol => FsError.other,
  };

  // ---- the temporary network ----

  /// Looks for the temporary networks (Windows, Linux): one alone is chosen at once.
  Future<void> scan() async {
    if (!wifi.needsName) return;
    await _run(() async {
      seen = await wifi.scan();
      if (seen.length == 1) ssid = seen.first.ssid;
    });
  }

  void chooseSsid(String? s) {
    ssid = s;
    notifyListeners();
  }

  /// Joins by itself (the system's sheet on a phone); by hand when it cannot.
  Future<void> joinAutomatically() async {
    if (!wifi.automatic) return _set(FsStep.manual);
    if (wifi.needsName && (ssid == null || !isSetupSsid(ssid!))) {
      return _fail(FsError.joinFailed, null, 'no_name');
    }
    _clear();
    _set(FsStep.joining);
    final r = await wifi.join(ssid: ssid);
    if (_disposed) return;
    if (!r.ok) {
      _set(r.state == JoinState.unsupported ? FsStep.manual : FsStep.intro);
      return _fail(switch (r.state) {
        JoinState.cancelled => FsError.cancelled,
        JoinState.denied => FsError.denied,
        _ => FsError.joinFailed,
      }, r.message);
    }
    ssid = r.ssid ?? ssid;
    await _open();
  }

  /// The person joined by hand (or the computer is on the network already).
  Future<void> joinedByHand() => _open();

  /// A new RedGiant found on the home network (a container or a VM, no Wi-Fi): the same steps
  /// through its setup channel there, without the temporary network.
  Future<void> startAt(Uri base) => _open(bases: [base]);

  /// Dials the setup channel at the temporary network's address, for a while (DHCP may still be
  /// answering), then reads where it is and what the first access allows.
  Future<void> _open({List<Uri>? bases}) async {
    _clear();
    _set(FsStep.connecting);
    final deadline = DateTime.now().add(channelTimeout);
    SetupChannelException? last;
    while (!_disposed) {
      for (final b in bases ?? setupBases) {
        try {
          final ch = await app.dialSetup(b, expect: fingerprint);
          _ch = ch;
          _base = b;
          fingerprint = ch.peerFingerprint;
          client = RedGiantClient(b, transport: ChannelTransport(ch));
          await _afterOpen();
          return;
        } on SetupChannelException catch (e) {
          last = e;
          // A different key or another device: said at once, never retried silently.
          if (e.code == SetupChannelErrorCode.fingerprintChanged ||
              e.code == SetupChannelErrorCode.busy) {
            _set(wifi.automatic ? FsStep.intro : FsStep.manual);
            return _fail(_channelError(e), e.message);
          }
        }
      }
      if (DateTime.now().isAfter(deadline)) break;
      await Future<void>.delayed(poll);
    }
    if (_disposed) return;
    _set(wifi.automatic ? FsStep.intro : FsStep.manual);
    _fail(FsError.notFound, last?.message);
  }

  Future<void> _afterOpen() async {
    final c = client!;
    final ch = _ch!;
    await _run(() async {
      final info = await ch.info();
      final net = SetupNetworkInfo.fromJson(info);
      network = net.status;
      final h = await c.hello();
      maintenance = info['here'] == 'maintenance' || h.firstStartCompleted;
      final auth = info['auth'] is Map<String, dynamic>
          ? info['auth'] as Map<String, dynamic>
          : const <String, dynamic>{};
      if (auth['password'] == true || maintenance) {
        // Met again on the temporary network after a home network that did not work.
        final pw = _password;
        if (pw != null) {
          await c.login(pw);
          return _afterSignIn();
        }
        return _set(FsStep.signIn);
      }
      if (auth['firstAccess'] != 'password') {
        _set(FsStep.intro);
        return _fail(FsError.notHere, null, '${auth['firstAccess']}');
      }
      _set(FsStep.access);
    });
  }

  // ---- the access ----

  /// A new RedGiant: the first password, then this device's token.
  Future<void> createAccess(String password) async {
    final c = client;
    if (c == null || password.isEmpty) return;
    await _run(() async {
      await c.firstAccess(password);
      _password = password;
      await _afterSignIn();
    });
  }

  Future<void> signIn(String password, {String? code}) async {
    final c = client;
    if (c == null || password.isEmpty) return;
    await _run(() async {
      await c.login(password, code: code);
      _password = password;
      await _afterSignIn();
    });
  }

  Future<void> _afterSignIn() async {
    final ch = _ch!;
    if (saved == null) {
      final d = await ch.device(app.deviceName, app.platform.name);
      final base = _base!.toString();
      final s = SavedServer(
        id: app.servers.where((x) => x.fingerprint == d.fingerprint).firstOrNull?.id ?? _newId(),
        label: kProductName,
        address: base,
        fingerprint: d.fingerprint,
        caPem: d.ca,
        deviceId: d.deviceId,
        setupAddress: base,
      );
      await app.adoptServer(s, d.token);
      saved = s;
    }
    final net = await client!.setupNetwork();
    network = net.status;
    final tried = network?.lastTry;
    if (tried != null && tried.failed && homeSsid != null && tried.ssid == homeSsid) {
      _fail(FsError.homeFailed, null, tried.error);
    }
    if (net.here == 'home' || network == null || !network!.active) {
      // Already on the home network (a RedGiant found there): straight on.
      return _reachHome(_base!);
    }
    _set(FsStep.home);
  }

  static String _newId() {
    final t = DateTime.now().microsecondsSinceEpoch.toRadixString(36);
    return 'fs$t';
  }

  // ---- the home network ----

  Future<void> chooseCable() => _chooseHome(const {'cable': true}, null);

  Future<void> chooseWifi(String name, String password, {bool hidden = false}) => _chooseHome({
    'ssid': name,
    if (password.isNotEmpty) 'password': password,
    if (hidden) 'hidden': true,
  }, name);

  Future<void> _chooseHome(Map<String, Object?> choice, String? name) async {
    final c = client;
    if (c == null) return;
    final r = await _run(() => c.setupNetworkHome(choice));
    if (r == null) {
      if (error == FsError.other) error = FsError.homeRefused;
      return;
    }
    homeSsid = name;
    homeAddress = r.address;
    _set(FsStep.homeWait);
    unawaited(_goHome());
  }

  /// RedGiant moves to the home network: the app leaves the temporary one and finds it there;
  /// not found in time, it goes back to the temporary network for the reason.
  Future<void> _goHome() async {
    await _closeChannel();
    await wifi.leave();
    final s = saved;
    if (s == null) return;
    final deadline = DateTime.now().add(homeTimeout);
    while (!_disposed && step == FsStep.homeWait) {
      Uri? found;
      try {
        found = await _findHome(s, homeAddress);
      } on Object {
        found = null;
      }
      if (found != null) return _reachHome(found);
      if (DateTime.now().isAfter(deadline)) return _backToTemporary();
      await Future<void>.delayed(poll);
    }
  }

  /// Not at home: on the temporary network again (RedGiant reopens it with the reason).
  Future<void> _backToTemporary() async {
    if (wifi.automatic && (!wifi.needsName || ssid != null)) {
      final r = await wifi.join(ssid: ssid);
      if (r.ok) {
        await _open();
        if (step != FsStep.connecting && step != FsStep.intro && step != FsStep.manual) return;
      }
    }
    _set(FsStep.homeLost);
  }

  /// From [FsStep.homeLost]: look at home once more.
  Future<void> lookAgain() async {
    _clear();
    _set(FsStep.homeWait);
    unawaited(_goHome());
  }

  /// From [FsStep.homeLost]: the person joins the temporary network by hand.
  void joinTemporaryByHand() => _set(FsStep.manual);

  /// At home: the app's own connection (https with the local CA, or the setup channel there when
  /// RedGiant has no HTTPS), then a look at the home network's try.
  Future<void> _reachHome(Uri base) async {
    final s = saved!;
    await _closeChannel();
    var ok = false;
    if (transportFor(base, hasCa: s.caPem != null) == TransportKind.channel) {
      final pw = _password;
      if (pw == null) return _set(FsStep.homeLost);
      ok = await app.pairViaChannel(base, pw, label: kProductName);
      final now = app.server;
      if (ok && now != null && now.deviceId != s.deviceId) {
        // Paired again over the channel at home: the first token goes.
        final old = s.deviceId;
        if (old != null && old.isNotEmpty) {
          try {
            await app.client?.revokeDevice(old);
          } on ApiException {
            // It expires with nothing using it.
          }
        }
        if (now.id != s.id) await app.dropToken(s.id);
        saved = now;
      }
    } else {
      ok = await app.useServer(s.copyWith(address: base.toString()));
      if (ok) saved = app.server;
    }
    if (!ok) {
      _set(FsStep.homeLost);
      return _fail(FsError.other, app.errorMessage);
    }
    client = app.client;
    await _run(() async {
      // A Wi-Fi network still being tried: its answer first.
      final until = DateTime.now().add(homeTimeout);
      SetupNetworkInfo net;
      do {
        net = await client!.setupNetwork();
        if (net.status?.trying != true || DateTime.now().isAfter(until)) break;
        await Future<void>.delayed(poll);
      } while (!_disposed);
      network = net.status;
      final tried = network?.lastTry;
      if (tried != null && tried.failed && homeSsid != null && tried.ssid == homeSsid) {
        _set(FsStep.home);
        return _fail(FsError.homeFailed, null, tried.error);
      }
      if (maintenance) return _set(FsStep.done);
      summary = await client!.setupSummary();
      _set(FsStep.language);
    });
  }

  /// The default way to find Rasgeth at home: the address it said (the cable), what mDNS shows,
  /// rasgeth.local; each checked against the pinned key.
  Future<Uri?> _defaultFindHome(SavedServer s, String? address) async {
    final hosts = <String>[
      ?address,
      for (final f in _found) '${f.host}:${f.port}',
      'rasgeth.local',
    ];
    for (final h in hosts) {
      final u = await probeHome(s, h);
      if (u != null) return u;
    }
    return null;
  }

  List<FoundServer> _found = const [];
  StreamSubscription<List<FoundServer>>? _discoverySub;

  /// Starts listening to mDNS while RedGiant moves (the app's own discovery).
  void watch(Discovery? d) {
    _discoverySub ??= d?.watch().listen((f) => _found = f);
  }

  /// [host] (`name`, `name:port`) is RedGiant with the pinned key: the base to use, else null.
  Future<Uri?> probeHome(SavedServer s, String host) async {
    final at = Uri.tryParse('http://$host');
    if (at == null || at.host.isEmpty) return null;
    final port = at.hasPort ? at.port : null;
    if (s.caPem != null) {
      final https = Uri(scheme: 'https', host: at.host, port: port == 7600 ? null : port);
      if (await _helloMatches(https, s)) return https;
    }
    if (isLoopbackHost(at.host)) {
      final local = Uri(scheme: 'http', host: at.host, port: port ?? 7600);
      return await _helloMatches(local, s) ? local : null;
    }
    final lan = Uri(scheme: 'http', host: at.host, port: port ?? 7600);
    try {
      final ch = await app
          .dialSetup(lan, expect: s.fingerprint)
          .timeout(const Duration(seconds: 6));
      await ch.close();
      return lan;
    } on Object {
      return null;
    }
  }

  Future<bool> _helloMatches(Uri base, SavedServer s) async {
    final c = RedGiantClient(base, caPem: s.caPem);
    try {
      final h = await c.hello().timeout(const Duration(seconds: 6));
      return h.nodeFingerprint != null && h.nodeFingerprint == s.fingerprint;
    } on Object {
      return false;
    } finally {
      c.close();
    }
  }

  // ---- what the page's wizard asks first ----

  Future<void> saveLanguages(String language, String agentLanguage) async {
    final c = client;
    if (c == null) return;
    final ok = await _run(() async {
      await c.setupLanguages(language: language, agentLanguage: agentLanguage);
      return true;
    });
    if (ok == true) _set(FsStep.brain);
  }

  Future<void> _reloadSummary() async {
    final c = client;
    if (c != null) summary = await c.setupSummary();
  }

  /// A provider's key (the server checks it and lists its models).
  Future<bool> saveKey(String provider, String key) async {
    final c = client;
    if (c == null || key.trim().isEmpty) return false;
    final r = await _run(() async {
      await c.setupKey(provider, key.trim());
      await _reloadSummary();
      return true;
    });
    return r == true;
  }

  /// Claude Pro or Max: the terms read, Anthropic's page in the browser, then its code.
  Future<void> claudeOpen() async {
    final c = client;
    if (c == null) return;
    await _run(() async {
      await c.setupSubscriptions({'ack': true});
      final url = await c.claudeLogin(ack: true);
      claudePage = url;
      await _openUrl(Uri.parse(url));
    });
  }

  Future<bool> claudeFinish(String code) async {
    final c = client;
    if (c == null || code.trim().isEmpty) return false;
    final r = await _run(() async {
      await c.claudeCode(code.trim());
      claudePage = null;
      await _reloadSummary();
      return true;
    });
    return r == true;
  }

  /// ChatGPT Plus or Pro: a code to type on OpenAI's page; noticed as soon as it is done.
  Future<void> chatgptOpen() async {
    final c = client;
    if (c == null) return;
    await _run(() async {
      await c.setupSubscriptions({'ack': true, 'chatgpt': true});
      final now = await c.chatgptStatus();
      if (now['account'] != null) {
        await _reloadSummary();
        return;
      }
      final login = await c.chatgptLogin();
      chatgpt = login;
      await _openUrl(Uri.parse(login.url));
      _chatgptTimer?.cancel();
      _chatgptTimer = Timer.periodic(const Duration(seconds: 3), (_) async {
        try {
          final s = await c.chatgptStatus();
          if (s['account'] != null) {
            _chatgptTimer?.cancel();
            chatgpt = null;
            await _reloadSummary();
            if (!_disposed) notifyListeners();
          }
        } on ApiException {
          // Next time.
        }
      });
    });
  }

  void brainNext() => _set(FsStep.names);

  /// God's and Demi-God's names; then the first start is completed.
  Future<void> saveNames(String god, String demigod, {required String language}) async {
    final c = client;
    if (c == null) return;
    final ok = await _run(() async {
      await c.setupNames(
        god: god.trim().isEmpty ? 'God' : god.trim(),
        demigod: demigod.trim().isEmpty ? 'Demi-God' : demigod.trim(),
        language: language,
      );
      return true;
    });
    if (ok != true) return;
    _set(FsStep.finishing);
    final done = await _run(() async {
      await c.setupComplete();
      return true;
    });
    if (done != true) return _set(FsStep.names);
    _password = null;
    await app.refresh();
    _set(FsStep.done);
  }

  // ---- the end ----

  Future<void> _closeChannel() async {
    final ch = _ch;
    _ch = null;
    if (ch != null) await ch.close();
  }

  /// Leaves the flow: the channel closes, the temporary network is left, the password forgotten.
  Future<void> cancel() async {
    _password = null;
    _chatgptTimer?.cancel();
    await _closeChannel();
    await wifi.leave();
  }

  @override
  void dispose() {
    _disposed = true;
    _password = null;
    _chatgptTimer?.cancel();
    unawaited(_discoverySub?.cancel());
    unawaited(_closeChannel());
    super.dispose();
  }
}

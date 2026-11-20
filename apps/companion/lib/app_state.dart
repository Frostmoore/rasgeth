// The app's state (G40.6, G40.7): appearance and language (kept between starts), the RedGiants
// the app knows and the one in use, the live connection and what the screens show. One
// ChangeNotifier, given to the tree by [AppScope]; the screens rebuild from it.
import 'dart:async';
import 'dart:convert';
import 'dart:io' show Platform;
import 'dart:math';
import 'dart:typed_data';

import 'package:flutter/material.dart';

import 'api/budgets.dart';
import 'brand.dart';
import 'app_update/updater.dart';
import 'api/client.dart';
import 'api/conversation.dart';
import 'api/discovery.dart';
import 'api/live.dart';
import 'api/live_model.dart';
import 'api/names.dart';
import 'api/legacy_data.dart';
import 'api/servers.dart';
import 'api/settings_types.dart';
import 'api/setup_channel.dart';
import 'api/token_store.dart';
import 'api/update_follower.dart';
import 'api/transport.dart';
import 'api/types.dart';
import 'desktop/handoff.dart';
import 'l10n/app_localizations.dart';
import 'mascot/mascot_source.dart';
import 'push/apns.dart';
import 'push/background.dart' show quickAnswerOf;
import 'push/distributors.dart';
import 'push/live_notices.dart';
import 'push/notice.dart';
import 'push/push_center.dart';
import 'push/registrar.dart';
import 'push/system_notifier.dart';
import 'share/share_intake.dart';
import 'ui/no_internet_notice.dart';
import 'voice/audio.dart';
import 'voice/voice_controller.dart';

/// The computers' layout from this width (G40.17): a 1024-pixel window still gets it, a window
/// made as narrow as a phone gets the phone's.
const int kDesktopFrom = 900;

/// The five places of proposal A, in the bar's order.
/// The bar's places (G42.5: Projects always, as the page's bar has them).
enum AppTab { team, chat, inbox, activity, projects, you }

/// Why connecting did not work, for the person (translated by the screens).
enum ConnectError {
  unreachable,
  wrong,
  codeNeeded,
  tooMany,
  noPassword,
  tooOld,
  tooNew,

  /// RedGiant answered with another key than the pinned one: nothing was sent.
  keyChanged,

  /// The certificate is not the pinned CA's (or not trusted at all).
  certificate,

  /// Another device is setting this RedGiant up.
  busy,

  /// The password is needed again (a revoked token, or requests that ride the setup channel).
  signInAgain,
  other,
}

typedef ClientFactory = RedGiantClient Function(SavedServer server, String? token);
typedef ChannelDialer = Future<SetupChannel> Function(
  Uri base,
  DeviceIdentity identity,
  String? expect,
);

DevicePlatform currentPlatform() {
  try {
    return devicePlatformFrom(Platform.operatingSystem);
  } on UnsupportedError {
    return DevicePlatform.other;
  }
}

class AppController extends ChangeNotifier {
  AppController({
    TokenStore? tokens,
    AppPrefs? prefs,
    ClientFactory? clientFactory,
    ChannelDialer? dialChannel,
    DevicePlatform? platform,
    this.discovery,
    this.liveEnabled = true,
    SystemNotifier? notifier,
    Future<Distributors> Function(PushCenter center)? distributors,
    ShareIntake? share,
    VoiceRecorder? recorder,
    VoicePlayer? player,
    this.legacy,
  }) : tokens = tokens ?? SecureTokenStore(),
       prefs = prefs ?? MemoryAppPrefs(),
       platform = platform ?? currentPlatform(),
       notifier = notifier ?? MemoryNotifier(),
       share = share ?? NoShareIntake(),
       _startDistributors = distributors,
       _recorder = recorder,
       _player = player,
       _clientFactory = clientFactory,
       _dial =
           dialChannel ?? ((b, id, expect) => SetupChannel.dial(b, identity: id, expect: expect)) {
    book = ServerBook(this.prefs);
    live.onUnknownSession = _soonReloadSessions;
    live.onListsChanged = (lists) => _soonReload(
      agents: lists.contains('agents'),
      projects: lists.contains('projects'),
      sessions: lists.contains('sessions'),
    );
    live.knowsAgent = (id) => agents.any((a) => a.id == id);
    live.onTurnEnded = () => spend.refreshSoon(client);
    live.addListener(_onLiveChanged);
  }

  // The notifications, the voice and the Share sheet (G40.10).
  final SystemNotifier notifier;
  final ShareIntake share;
  final Future<Distributors> Function(PushCenter center)? _startDistributors;
  final VoiceRecorder? _recorder;
  final VoicePlayer? _player;
  late final PushCenter pushCenter = PushCenter(
    prefs: prefs,
    tokens: tokens,
    notifier: notifier,
    clients: _clientFactory == null ? null : (s, t) => _clientFor(s, t),
  );
  Distributors distributors = NoDistributors();
  late final VoiceController voice = VoiceController(
    prefs: prefs,
    recorder: _recorder,
    player: _player,
  );

  /// The app on its own updating itself (G41.8b): set at start on Windows and Linux (disabled
  /// for RedGiant's own copy and builds from the sources), null on phones and in tests.
  AppUpdater? appUpdater;

  /// Where the person was before an update (taken once by the computers' room).
  ResumeState? resume;

  /// Where the person is now, given by the computers' room (kept for the update's restart).
  ResumeState Function()? resumeNow;

  final TokenStore tokens;

  /// The app's data under its name before 3.9.0, carried once at start (Windows; null elsewhere).
  final LegacySource? legacy;
  final AppPrefs prefs;
  final DevicePlatform platform;
  final ClientFactory? _clientFactory;
  final ChannelDialer _dial;
  final Discovery? discovery;

  /// Tests of the screens alone: no socket.
  final bool liveEnabled;
  late final ServerBook book;

  ThemeMode themeMode = ThemeMode.system;

  /// null: the system's language.
  Locale? locale;
  bool reduceMotion = false;

  /// The one-time «RedGiant is now called Rasgeth» is due on this device (plan 3.9.0, choice 17,
  /// the page's `RenameNotice`): not closed yet (`renameSeen`), and the person knew the old name:
  /// this app had servers before the version that brought the new name, or the server in use was
  /// installed before it (`firstVersion`). Whoever starts with Rasgeth sees nothing.
  bool renameDue = false;
  bool _renameSeen = true;

  /// The advanced interface (G40.11, Tu › Interfaccia), per RedGiant: the projects' git state
  /// and Files, Diff and Terminal in every agent's sheet (Projects is in the bar anyway, G42.5).
  bool advanced = false;

  AppTab tab = AppTab.team;

  List<SavedServer> servers = const [];
  SavedServer? server;
  RedGiantClient? client;
  MascotSource? mascots;
  AppHello? hello;
  List<Agent> agents = const [];
  String? chatAgentId;
  bool connecting = false;
  ConnectError? error;
  String? errorMessage;

  /// The key RedGiant showed when it was not the pinned one.
  String? seenFingerprint;

  final LiveModel live = LiveModel();

  /// Spending and limits for the conversations' header (3.9.0).
  final SpendModel spend = SpendModel();

  /// What on the server waits for the internet (3.9.1): a notice over the home.
  final NoInternetModel noInternet = NoInternetModel();
  LiveSocket? socket;
  LiveStatus? liveStatus;
  StreamSubscription<Map<String, dynamic>>? _liveSub;
  StreamSubscription<LiveStatus>? _statusSub;
  Timer? _reloadTimer;

  /// The update of the RedGiant in use the app follows (one at a time, kept across screens).
  UpdateFollower? updateRun;
  bool _updateToOpen = false;

  /// How often an update is read, and the clock it counts the time with (tests put theirs).
  Duration updateEvery = const Duration(seconds: 1);
  DateTime Function() updateClock = DateTime.now;

  /// The Chat's new conversation, started from the field over the bar: opened by the Chat screen.
  String? chatDraft;

  /// The projects of the RedGiant in use (Team's filter).
  List<Project> projects = const [];

  /// The archived projects (p3.5.3): their conversations are read only (G42.1).
  List<Project> archivedProjects = const [];

  List<SessionRow>? _seenSessions;
  List<PermissionRequest>? _seenApprovals;
  List<QuestionRequest>? _seenQuestions;

  /// Moves every time the projects are read again (p3.8.9): screens with their own copy of the
  /// projects (Projects, with git and tasks) read theirs again.
  int projectsVersion = 0;

  /// Every project's subprojects (G24.13), read with the projects.
  List<Subproject> subprojects = const [];

  List<Subproject> subprojectsOf(String projectId) => [
    for (final x in subprojects)
      if (x.projectId == projectId) x,
  ];

  /// The archived project a conversation belongs to (its own, or its agent's), if any.
  Project? archivedProjectOf(String sessionId) {
    final row = live.sessions.where((r) => r.id == sessionId).firstOrNull;
    final agent = agents.where((a) => a.id == row?.agentId).firstOrNull;
    for (final id in [row?.projectId, agent?.projectId]) {
      final p = archivedProjects.where((x) => x.id == id).firstOrNull;
      if (p != null) return p;
    }
    return null;
  }

  /// [a] belongs to an archived project (p3.5.3): its conversations are only read.
  bool isAgentReadOnly(Agent a) => archivedProjects.any((p) => p.id == a.projectId);

  /// Team's favourites, per RedGiant (kept on this device).
  Set<String> favourites = const {};

  /// Team's filter: [TeamFilter.all], [TeamFilter.favourites] or a project's id.
  String teamFilter = TeamFilter.all;

  /// The window is in front (the computers notify only when it is not).
  bool foreground = true;

  /// The computers' notifications while the app is open behind other windows (Tu › Notifiche).
  bool desktopNotify = true;

  /// What another app shared, waiting for the Share screen (G40.10).
  List<SharedItem>? pendingShare;

  /// A conversation a notification asked to open (the shell opens it).
  String? pendingSession;

  bool get connected => client != null && hello?.signedIn == true;

  /// The RedGiant in use as people read it (never a container's id).
  String get displayName => readableName(label: server?.label, machine: hello?.machine);

  /// Whether conversations stream (false inside the setup channel).
  bool get isLive => client?.transport.live == true && socket != null;

  bool get mobile => platform == DevicePlatform.android || platform == DevicePlatform.ios;

  // ---- appearance, kept between starts ----

  void setTab(AppTab t) {
    if (tab == t) return;
    tab = t;
    notifyListeners();
  }

  void setThemeMode(ThemeMode m) {
    themeMode = m;
    unawaited(prefs.set('theme', m.name));
    notifyListeners();
  }

  void setLocale(Locale? l) {
    locale = l;
    unawaited(prefs.set('locale', l?.languageCode));
    notifyListeners();
  }

  String get _advancedKey => 'advanced:${server?.id ?? '-'}';

  void setAdvanced(bool v) {
    advanced = v;
    unawaited(prefs.set(_advancedKey, v ? '1' : null));
    notifyListeners();
  }

  /// The places in the bar now.
  List<AppTab> get tabs => AppTab.values;

  void dismissRenameNotice() {
    renameDue = false;
    _renameSeen = true;
    unawaited(prefs.set('renameSeen', kRenamedIn));
    notifyListeners();
  }

  /// The server in use was born before the new name: the notice is due, unless closed.
  void _renameFromServer(String? firstVersion) {
    if (_renameSeen || renameDue || !bornBeforeRename(firstVersion)) return;
    renameDue = true;
    notifyListeners();
  }

  void setReduceMotion(bool v) {
    reduceMotion = v;
    unawaited(prefs.set('reduceMotion', v ? '1' : null));
    notifyListeners();
  }

  /// The field over the bar: a new conversation with Chat, at once.
  void startChat(String text) {
    final t = text.trim();
    if (t.isEmpty) return;
    chatDraft = t;
    tab = AppTab.chat;
    notifyListeners();
  }

  String? takeChatDraft() {
    final d = chatDraft;
    chatDraft = null;
    return d;
  }

  /// The device's name on the server (Settings › Devices).
  String get deviceName => switch (platform) {
    DevicePlatform.android => '$kAppName (Android)',
    DevicePlatform.ios => '$kAppName (iOS)',
    DevicePlatform.windows => '$kAppName (Windows)',
    DevicePlatform.macos => '$kAppName (macOS)',
    DevicePlatform.linux => '$kAppName (Linux)',
    DevicePlatform.other => kAppName,
  };

  RedGiantClient _clientFor(SavedServer s, String? token, {Transport? transport}) {
    final f = _clientFactory;
    if (transport == null && f != null) return f(s, token);
    return RedGiantClient(s.base, token: token, caPem: s.caPem, transport: transport);
  }

  Future<DeviceIdentity> _identity() async {
    final seed = await tokens.read('identity');
    if (seed != null) {
      try {
        return await DeviceIdentity.fromSeed(base64.decode(seed));
      } on FormatException {
        // A new one below.
      }
    }
    final made = await DeviceIdentity.create();
    await tokens.write('identity', base64.encode(made.seed));
    return made.identity;
  }

  static String _newId() {
    final r = Random.secure();
    return List.generate(12, (_) => r.nextInt(36).toRadixString(36)).join();
  }

  // ---- start ----

  /// At start: the settings, the RedGiants, the last one in use if its token still works.
  /// [handoff]: the local RedGiant a computer's launcher opened this window for (G40.12).
  Future<void> restore({LaunchHandoff? handoff}) async {
    final theme = await prefs.get('theme');
    themeMode = ThemeMode.values.firstWhere((m) => m.name == theme, orElse: () => ThemeMode.system);
    final lang = await prefs.get('locale');
    locale = lang == null ? null : Locale(lang);
    reduceMotion = await prefs.get('reduceMotion') == '1';
    commandStripMin = await prefs.get('cmdStrip') == 'min';
    try {
      final seen = jsonDecode(await prefs.get('subSeen') ?? '{}');
      if (seen is Map) {
        subSeen = {
          for (final e in seen.entries)
            if (e.key is String && e.value is num) e.key as String: (e.value as num).toInt(),
        };
      }
    } on FormatException {
      subSeen = {};
    }
    desktopNotify = await prefs.get('desktopNotify') != '0';
    desktopFrom = int.tryParse(await prefs.get('desktopFrom') ?? '') ?? kDesktopFrom;
    try {
      await carryLegacyData(source: legacy, prefs: prefs, tokens: tokens);
    } on Object {
      // The next start tries again; what the app has now is used as it is.
    }
    servers = await book.load();
    _renameSeen = await prefs.get('renameSeen') != null;
    // The app's own memory: the first start of a version with the new name finds servers saved
    // by an older one (this device knew the old name) or none (it never did); kept once decided.
    var knew = await prefs.get('renameKnew');
    if (knew == null) {
      knew = servers.isEmpty ? '0' : '1';
      await prefs.set('renameKnew', knew);
    }
    renameDue = !_renameSeen && knew == '1';
    notifyListeners();
    if (handoff != null && await adoptHandoff(handoff)) return;
    final current = await prefs.get('current');
    final s = servers.where((x) => x.id == current).firstOrNull ?? servers.firstOrNull;
    if (s != null) await useServer(s);
  }

  /// Switches to [s] (its token from the keystore).
  Future<bool> useServer(SavedServer s) async {
    await _drop();
    server = s;
    error = null;
    errorMessage = null;
    await prefs.set('current', s.id);
    String? token;
    try {
      token = await tokens.read(s.id);
    } on Object {
      // An unreadable keystore (the plugin drops its file then): paired again, never forgotten.
      token = null;
    }
    if (token == null) return _fail(ConnectError.signInAgain);
    if (transportFor(s.base, hasCa: s.caPem != null) == TransportKind.channel) {
      // The channel carries its own sign-in, not the device's token: the password again.
      return _fail(ConnectError.signInAgain);
    }
    connecting = true;
    notifyListeners();
    try {
      await _use(_clientFor(s, token));
      return connected;
    } on ApiException catch (e) {
      return _fail(_errorOf(e), e.message);
    } on _KeyChanged catch (e) {
      seenFingerprint = e.seen;
      return _fail(ConnectError.keyChanged);
    } finally {
      connecting = false;
      notifyListeners();
    }
  }

  /// The launcher's local RedGiant (G40.12): its token replaces the one kept for that address,
  /// and the device the app had there before is revoked (one entry per app in Settings ›
  /// Devices). The launcher hands a token over only when this window was not open, so no running
  /// connection uses the old one.
  Future<bool> adoptHandoff(LaunchHandoff h) async {
    final known = servers.where((s) => s.address == h.address).firstOrNull;
    final old = known?.deviceId;
    final saved = known != null
        ? known.copyWith(deviceId: h.deviceId)
        : SavedServer(
            id: _newId(),
            label: h.machine ?? Uri.parse(h.address).host,
            address: h.address,
            deviceId: h.deviceId,
          );
    await _keep(saved, h.token);
    notifyListeners();
    final ok = await useServer(saved);
    if (ok && old != null && old != h.deviceId) {
      unawaited(client?.revokeDevice(old).catchError((Object _) {}));
    }
    return ok;
  }

  // ---- pairing ----

  /// Pairs with what the person typed. https (a proxy, Tailscale) and this machine's http:
  /// `POST /api/app/pair`, then the key the server shows is pinned. Any other http address
  /// (the temporary network, a RedGiant without HTTPS) and a RedGiant found on the network:
  /// through the setup channel, which also hands over the local CA.
  Future<bool> connect(String address, String password, {String? code}) async {
    final typed = address.trim();
    if (typed.isEmpty) return false;
    final base = RedGiantClient.normalizeBase(Uri.parse(typed));
    if (transportFor(base, hasCa: false) == TransportKind.channel) {
      return pairViaChannel(base, password, code: code);
    }
    return _pairDirect(base, password, code: code);
  }

  /// A RedGiant found on the network: always through its setup channel.
  Future<bool> connectFound(FoundServer f, String password, {String? code}) =>
      pairViaChannel(f.base, password, code: code, label: f.machine);

  Future<bool> _pairDirect(Uri base, String password, {String? code}) async {
    _begin();
    final draft = SavedServer(id: _newId(), label: base.host, address: base.toString());
    final c = _clientFor(draft, null);
    var viaChannel = false;
    try {
      final h = await c.hello();
      final compat = compatibilityOf(h);
      if (compat != Compatibility.ok) {
        return _fail(
          compat == Compatibility.serverTooOld ? ConnectError.tooOld : ConnectError.tooNew,
        );
      }
      final created = await c.pair(
        password: password,
        code: code,
        name: deviceName,
        platform: platform,
      );
      final saved = draft.copyWith(
        label: h.machine,
        fingerprint: h.nodeFingerprint,
        deviceId: created.device.id,
      );
      await _keep(saved, created.token);
      await _use(c, checked: true);
      return connected;
    } on ApiException catch (e) {
      // A local name with RedGiant's own CA, not trusted yet: the setup channel gets the CA.
      if (e.certificate && _lan(base.host)) viaChannel = true;
      if (!viaChannel) return _fail(_errorOf(e), e.message);
    } finally {
      if (!viaChannel) {
        connecting = false;
        notifyListeners();
      }
    }
    return pairViaChannel(base.replace(scheme: 'http', port: 7600), password, code: code);
  }

  static bool _lan(String host) =>
      host.endsWith('.local') ||
      RegExp(r'^(10\.|192\.168\.|172\.(1[6-9]|2\d|3[01])\.)').hasMatch(host);

  /// Through the setup channel: RedGiant's key is checked (pinned when it is new), the password
  /// signs in inside the channel, the device's token and the local CA come back encrypted.
  Future<bool> pairViaChannel(
    Uri channelBase,
    String password, {
    String? code,
    String? label,
  }) async {
    _begin();
    SetupChannel? ch;
    try {
      final known = servers.where((s) => s.setupAddress == channelBase.toString()).firstOrNull;
      ch = await _dial(channelBase, await _identity(), known?.fingerprint);
      final info = await ch.info();
      final r = await ch.http(
        'POST',
        '/api/auth/login',
        json: {'password': password, if (code != null && code.isNotEmpty) 'code': code},
      );
      if (r.status != 200) {
        Map<String, dynamic> body = const {};
        try {
          body = jsonDecode(r.body) as Map<String, dynamic>;
        } on Object {
          // As below.
        }
        throw ApiException(
          r.status,
          body['error'] is String ? body['error'] as String : 'HTTP ${r.status}',
          code: body['code'] is String ? body['code'] as String : null,
        );
      }
      final device = await ch.device(deviceName, platform.name);
      final host = channelBase.host;
      var saved = SavedServer(
        id: known?.id ?? _newId(),
        label: label ?? (info['machine'] is String ? info['machine'] as String : host),
        address: channelBase.toString(),
        fingerprint: device.fingerprint,
        caPem: device.ca,
        deviceId: device.deviceId,
        setupAddress: channelBase.toString(),
      );
      // With the local CA and not on the temporary network: https from now on, only that CA.
      if (device.ca != null && !isSetupNetworkHost(host)) {
        final https = saved.copyWith(
          address: Uri(scheme: 'https', host: host).toString(),
        );
        final c = _clientFor(https, device.token);
        try {
          server = https;
          await _check(c, https);
          saved = https;
          await _keep(saved, device.token);
          await ch.close();
          ch = null;
          await _use(c, checked: true);
          return connected;
        } on ApiException {
          // No https at that address yet: the channel keeps carrying the requests.
          c.close();
        }
      }
      await _keep(saved, device.token);
      final c = _clientFor(saved, device.token, transport: ChannelTransport(ch!));
      ch = null;
      await _use(c, checked: true);
      return connected;
    } on SetupChannelException catch (e) {
      seenFingerprint = e.seen;
      return _fail(switch (e.code) {
        SetupChannelErrorCode.fingerprintChanged => ConnectError.keyChanged,
        SetupChannelErrorCode.busy => ConnectError.busy,
        SetupChannelErrorCode.unreachable ||
        SetupChannelErrorCode.timeout => ConnectError.unreachable,
        _ => ConnectError.other,
      }, e.message);
    } on SetupRequestException catch (e) {
      return _fail(ConnectError.other, e.message);
    } on ApiException catch (e) {
      return _fail(_errorOf(e), e.message);
    } on _KeyChanged catch (e) {
      seenFingerprint = e.seen;
      return _fail(ConnectError.keyChanged);
    } finally {
      await ch?.close();
      connecting = false;
      notifyListeners();
    }
  }

  void _begin() {
    connecting = true;
    error = null;
    errorMessage = null;
    seenFingerprint = null;
    notifyListeners();
  }

  Future<void> _keep(SavedServer s, String token) async {
    await tokens.write(s.id, token);
    servers = await book.put(s);
    server = s;
    await prefs.set('current', s.id);
  }

  /// The first start from the app (G40.8): the RedGiant set up over its setup channel is kept
  /// with its device token, before the app reaches it at home.
  Future<void> adoptServer(SavedServer s, String token) async {
    await _keep(s, token);
    notifyListeners();
  }

  /// Opens the setup channel with the app's own identity ([expect]: the pinned key).
  Future<SetupChannel> dialSetup(Uri base, {String? expect}) async =>
      _dial(base, await _identity(), expect);

  /// Renames the RedGiant in use: in the app, and on the server for the page and the nodes.
  /// The server's name stays as it was when the server refuses (an older one, a node).
  Future<void> renameRedGiant(String name) async {
    final s = server;
    final t = name.trim();
    if (s == null || t.isEmpty) return;
    await renameServer(s, t);
    try {
      await client?.setMachineName(t.length > 40 ? t.substring(0, 40) : t);
      hello = await client?.hello() ?? hello;
    } on ApiException {
      // The app's own name is enough.
    }
    notifyListeners();
  }

  /// The RedGiant in use has no valid token (lost, refused): it stays in the list, to be paired
  /// again with its password ([pairAgain]); forgetting it is the person's own choice.
  bool get needsPairing => server != null && error == ConnectError.signInAgain;

  /// Pairs [s] again at its address: the same entry (its name, the app's settings for it), a
  /// new device token, and the device the app had there before revoked.
  Future<bool> pairAgain(SavedServer s, String password, {String? code}) async {
    final ok = await connect(s.address, password, code: code);
    final now = server;
    if (!ok || now == null) return ok;
    if (now.label != s.label) {
      final n = now.copyWith(label: s.label);
      servers = await book.put(n);
      server = n;
    }
    final old = s.deviceId;
    if (old != null && old != now.deviceId) {
      unawaited(client?.revokeDevice(old).catchError((Object _) {}));
    }
    if (now.id != s.id) {
      servers = await book.remove(s.id);
      unawaited(tokens.delete(s.id).catchError((Object _) {}));
    }
    notifyListeners();
    return ok;
  }

  /// Forgets a token the app no longer uses (a RedGiant paired again under another id).
  Future<void> dropToken(String serverId) => tokens.delete(serverId);

  /// The key RedGiant shows over https must be the pinned one.
  Future<AppHello> _check(RedGiantClient c, SavedServer s) async {
    final h = await c.hello();
    final pinned = s.fingerprint;
    if (pinned != null && h.nodeFingerprint != null && h.nodeFingerprint != pinned) {
      throw _KeyChanged(h.nodeFingerprint);
    }
    return h;
  }

  Future<void> _use(RedGiantClient c, {bool checked = false}) async {
    final s = server;
    final h = s != null && !checked ? await _check(c, s) : await c.hello();
    client = c;
    hello = h;
    mascots = ClientMascotSource(c);
    if (!h.signedIn) {
      error = ConnectError.signInAgain;
      return;
    }
    agents = await c.agents();
    unawaited(ensureChatAgent());
    await _loadTeamPrefs();
    await _loadLists();
    _startLive();
    unawaited(voice.attach(c, s?.id));
    unawaited(_renewPush());
    await _lookForUpdate();
  }

  // ---- updates of the RedGiant in use ----

  /// The RedGiant of this very computer (the launcher's): its launcher does the update.
  bool get localRedGiant => desktop && client?.transport.kind == TransportKind.loopback;

  UpdateFollower _newFollower({String? from, String? to, Map<String, dynamic>? note}) {
    updateRun?.dispose();
    return updateRun = UpdateFollower(
      source: ClientUpdateSource(client!),
      from: from,
      to: to,
      note: note,
      local: localRedGiant,
      every: updateEvery,
      now: updateClock,
      onBack: _afterUpdate,
    );
  }

  /// «Update»: asks RedGiant to update, then follows it.
  Future<void> startUpdate({String? from, String? to, Map<String, dynamic>? note}) async {
    if (client == null) return;
    final f = _newFollower(from: from, to: to, note: note);
    notifyListeners();
    await f.begin();
  }

  /// An update found running: followed, and its screen opened ([takeUpdateToOpen]).
  void followUpdate(UpdateStatus? s, OsUpdates? os, {bool open = true}) {
    if (client == null) return;
    if (updateRun != null && !updateRun!.finished) return;
    _newFollower(
      from: os?.run?.from ?? os?.installed ?? s?.installed,
      to: os?.latest ?? s?.latest,
      note: s?.note,
    ).follow();
    if (open) _updateToOpen = true;
    notifyListeners();
  }

  /// The update's screen should open (once).
  bool takeUpdateToOpen() {
    final v = _updateToOpen;
    _updateToOpen = false;
    return v;
  }

  /// Whether the RedGiant in use is updating now: then its update is followed and shown.
  Future<void> _lookForUpdate() async {
    final c = client;
    if (c == null) return;
    try {
      final s = await c.updateStatus();
      _renameFromServer(s.firstVersion);
      final os = s.install == 'os' ? await c.osUpdates() : null;
      final running = (os?.updating ?? false) || (s.progress != null && s.phase != 'failed');
      if (running) followUpdate(s, os);
    } on ApiException {
      // An older server, or one that does not say: nothing to follow.
    }
  }

  /// RedGiant answers as the new version: the app reconnects by itself, HTTP and the live socket.
  Future<void> _afterUpdate() async {
    final c = client;
    if (c == null) return;
    hello = await c.hello();
    error = null;
    errorMessage = null;
    agents = await c.agents();
    await _loadLists();
    final sock = socket;
    if (sock != null && sock.status != LiveStatus.open) {
      sock.reconnectNow();
      await sock.statuses
          .firstWhere((st) => st == LiveStatus.open)
          .timeout(const Duration(seconds: 10), onTimeout: () => LiveStatus.down);
    }
    notifyListeners();
  }

  // ---- Team: favourites and the project filter (G40.9) ----

  String get _favKey => 'favourites:${server?.id ?? '-'}';

  Future<void> _loadTeamPrefs() async {
    final raw = await prefs.get(_favKey);
    favourites = raw == null || raw.isEmpty ? <String>{} : raw.split(',').toSet();
    teamFilter = await prefs.get('teamFilter:${server?.id ?? '-'}') ?? TeamFilter.all;
    advanced = await prefs.get(_advancedKey) == '1';
  }

  bool isFavourite(String agentId) => favourites.contains(agentId);

  void toggleFavourite(String agentId) {
    final f = {...favourites};
    if (!f.remove(agentId)) f.add(agentId);
    favourites = f;
    unawaited(prefs.set(_favKey, f.isEmpty ? null : (f.toList()..sort()).join(',')));
    notifyListeners();
  }

  void setTeamFilter(String f) {
    teamFilter = f;
    unawaited(prefs.set('teamFilter:${server?.id ?? '-'}', f == TeamFilter.all ? null : f));
    notifyListeners();
  }

  /// God, shown on its own card at the top of Team.
  Agent? get god => agents.where((a) => a.kind == AgentKind.god).firstOrNull;

  /// The Chat's agent, shown on its own wide card under God's.
  Agent? get chatAgent => agents.where((a) => a.id == chatAgentId).firstOrNull;

  /// Team's «Agents» grid: first level without God, the Chat and Demi-God (Telegram's voice: it
  /// stays in the full list in the settings), favourites first, then by name; filtered.
  /// The agent with [id] among those the app knows (the mascots ask: a sub-agent shows its sign).
  Agent? agentWithId(String id) {
    for (final a in agents) {
      if (a.id == id) return a;
    }
    return null;
  }

  List<Agent> teamShown() {
    final first = agents
        .where(
          (a) =>
              a.kind != AgentKind.subagent &&
              a.kind != AgentKind.inspector &&
              a.kind != AgentKind.god &&
              a.kind != AgentKind.demigod &&
              a.id != chatAgentId,
        )
        .toList();
    first.sort((a, b) {
      final f = (isFavourite(b.id) ? 1 : 0) - (isFavourite(a.id) ? 1 : 0);
      if (f != 0) return f;
      return a.name.toLowerCase().compareTo(b.name.toLowerCase());
    });
    final f = teamFilter;
    if (f == TeamFilter.favourites) return first.where((a) => isFavourite(a.id)).toList();
    if (f != TeamFilter.all) {
      // A project's agents, and those that worked in it (God, Chat…).
      final worked = {
        for (final s in live.sessions)
          if (s.projectId == f) s.agentId,
      };
      return first.where((a) => a.projectId == f || worked.contains(a.id)).toList();
    }
    return first;
  }

  // ---- Models (3.8.1): an agent's, the Chat's, a conversation's ----

  List<ModelChoice>? _models;

  /// The models one can pick (`GET /api/models`), asked once per connection.
  Future<List<ModelChoice>> modelChoices({bool again = false}) async {
    final c = client;
    if (c == null) return const [];
    if (_models != null && !again) return _models!;
    try {
      return _models = await c.models();
    } on ApiException {
      return const [];
    }
  }

  /// Models already asked for (for words; empty before the first [modelChoices]).
  List<ModelChoice> get knownModels => _models ?? const [];

  bool isChat(Agent a) => a.id == chatAgentId;

  /// [a]'s own model: the Chat's from its settings (the page's Chat header), the others' from
  /// their record.
  Future<AgentModel?> ownModelOf(Agent a) async {
    if (!isChat(a)) return agents.where((x) => x.id == a.id).firstOrNull?.model ?? a.model;
    try {
      return await client?.chatModel();
    } on ApiException {
      return a.model;
    }
  }

  /// The model [a] follows without one of its own: the first one up its parents (the page's
  /// `inheritedModel`); null means the default model.
  AgentModel? inheritedModelOf(Agent a) {
    var p = agents.where((x) => x.id == a.parentId).firstOrNull;
    final seen = <String>{};
    while (p != null && seen.add(p.id)) {
      if (p.model != null) return p.model;
      final up = p.parentId;
      p = agents.where((x) => x.id == up).firstOrNull;
    }
    return null;
  }

  /// Changes [a]'s model with the page's own API: the Chat through its settings, every other
  /// agent (God included) through `PATCH /api/agents/:id`. Null: back to the one above.
  Future<bool> setAgentModel(Agent a, AgentModel? model) async {
    final c = client;
    if (c == null) return false;
    try {
      if (isChat(a)) {
        await c.setChatModel(model);
        agents = [for (final x in agents) x.id == a.id ? x.withModel(model) : x];
      } else {
        final updated = await c.configureAgent(a.id, model: model, clearModel: model == null);
        agents = [for (final x in agents) x.id == a.id ? updated : x];
      }
      notifyListeners();
      return true;
    } on ApiException {
      return false;
    }
  }

  /// The composer's mode: the agent's, for all its conversations (`PATCH /api/agents/:id`).
  Future<bool> setAgentMode(Agent a, String mode) async {
    final c = client;
    if (c == null) return false;
    try {
      final updated = await c.configureAgent(a.id, mode: mode);
      agents = [for (final x in agents) x.id == a.id ? updated : x];
      notifyListeners();
      return true;
    } on ApiException {
      return false;
    }
  }

  /// Saves a change to [a] with the page's own `PATCH /api/agents/:id` (Settings › Agents);
  /// null when it went, else the server's own words.
  Future<String?> saveAgent(Agent a, Map<String, Object?> change) async {
    final c = client;
    if (c == null) return 'offline';
    try {
      final updated = await c.patchAgent(a.id, change);
      agents = [for (final x in agents) x.id == a.id ? updated : x];
      notifyListeners();
      return null;
    } on ApiException catch (e) {
      return e.message;
    }
  }

  /// The page's «Stop» (`POST /api/agents/:id/stop`, 3.8.9: a pause): the agent and those under
  /// it stop working, their open tasks wait; «Resume» brings them back. Never God.
  Future<String?> stopAgentForGood(Agent a) async {
    final c = client;
    if (c == null) return 'offline';
    try {
      await c.stopAgentForGood(a.id);
      try {
        agents = await c.agents();
      } on ApiException {
        agents = [
          for (final x in agents)
            x.id == a.id
                ? Agent(
                    id: x.id,
                    kind: x.kind,
                    name: x.name,
                    active: false,
                    parentId: x.parentId,
                    projectId: x.projectId,
                    role: x.role,
                    mascot: x.mascot,
                    model: x.model,
                    mode: x.mode,
                    mascotSeed: x.mascotSeed,
                  )
                : x,
        ];
      }
      notifyListeners();
      return null;
    } on ApiException catch (e) {
      return e.message;
    }
  }

  /// «Resume» (3.8.9, `POST /api/agents/:id/resume`): a stopped agent works again and its open
  /// tasks go on in their conversations. `why` null when done (with how many tasks go on).
  Future<({String? why, int tasks})> resumeAgent(Agent a) async {
    final c = client;
    if (c == null) return (why: 'offline', tasks: 0);
    try {
      final tasks = await c.resumeAgent(a.id);
      await _reloadTeamNow();
      return (why: null, tasks: tasks.length);
    } on ApiException catch (e) {
      return (why: e.message, tasks: 0);
    }
  }

  /// What removing [a] takes with it (3.8.9): null when the server cannot say.
  Future<RemovePreview?> removePreview(Agent a) async {
    try {
      return await client?.removePreview(a.id);
    } on ApiException {
      return null;
    }
  }

  /// «Remove» (3.8.9, `POST /api/agents/:id/remove`): the agent and those below it leave the
  /// team; their history stays and «Removed agents» restores them. Null when done, else why not.
  Future<String?> removeAgent(Agent a) async {
    final c = client;
    if (c == null) return 'offline';
    try {
      final gone = (await c.removeAgent(a.id)).toSet()..add(a.id);
      agents = agents.where((x) => !gone.contains(x.id)).toList();
      notifyListeners();
      _reloadTeam();
      return null;
    } on ApiException catch (e) {
      return e.message;
    }
  }

  /// The removed agents (3.8.9), the latest first; empty when the server cannot say.
  Future<List<RemovedAgent>> removedAgents() async {
    try {
      return await client?.removedAgents() ?? const [];
    } on ApiException {
      return const [];
    }
  }

  /// A removed agent's conversations (3.8.9), the latest first: read only.
  Future<List<SessionRow>> removedSessions(String agentId) async {
    try {
      return await client?.sessions(agentId: agentId) ?? const [];
    } on ApiException {
      return const [];
    }
  }

  /// «Restore» (3.8.9): [a] back in the team with those removed with it. Null when done.
  Future<String?> restoreAgent(Agent a) async {
    final c = client;
    if (c == null) return 'offline';
    try {
      await c.restoreAgent(a.id);
      await _reloadTeamNow();
      return null;
    } on ApiException catch (e) {
      return e.message;
    }
  }

  /// The team and the conversations again (an agent removed or restored, here or elsewhere).
  void _reloadTeam() => unawaited(_reloadTeamNow());

  Future<void> _reloadTeamNow() async {
    final c = client;
    if (c == null) return;
    try {
      agents = await c.agents();
      live.setSessions(await c.sessions());
      notifyListeners();
    } on ApiException {
      // Next time.
    }
  }

  /// One conversation's own model (null: its agent's), then the rows again.
  Future<String?> setSessionModel(String sessionId, AgentModel? model) async {
    final c = client;
    if (c == null) return 'offline';
    try {
      await c.setSessionModel(sessionId, model);
      live.setSessions(await c.sessions());
      return null;
    } on ApiException catch (e) {
      return e.status == 409 ? 'busy' : e.message;
    }
  }

  /// A new agent with the page's own API (3.8.1): `POST /api/agents`, then its tools switched
  /// off (`PUT /api/agents/:id/tools`, never the essential ones); the team again.
  Future<Agent> createAgent({
    required String kind,
    required String? parentId,
    required String name,
    String? projectId,
    String? role,
    AgentModel? model,
    Set<String> toolsOff = const {},
  }) async {
    final c = client;
    if (c == null) throw const ApiException(0, 'offline');
    final a = await c.createAgent(
      kind: kind,
      parentId: parentId,
      name: name,
      projectId: projectId,
      role: role,
      model: model,
      mode: 'auto',
    );
    if (toolsOff.isNotEmpty) {
      await c.setAgentTools(a.id, {for (final t in toolsOff) t: 'off'});
    }
    try {
      agents = await c.agents();
    } on ApiException {
      agents = [...agents, a];
    }
    notifyListeners();
    return agents.where((x) => x.id == a.id).firstOrNull ?? a;
  }

  /// «Change mascot»: a new face, different from every one in use (the person's, never God's).
  Future<Agent?> changeMascot(Agent a) async {
    final c = client;
    if (c == null) return null;
    try {
      final updated = await c.changeMascot(a.id);
      final m = mascots;
      if (m is ClientMascotSource) m.forget(a.id);
      agents = [for (final x in agents) x.id == a.id ? updated : x];
      notifyListeners();
      return updated;
    } on ApiException {
      return null;
    }
  }

  /// [agentId]'s latest conversation (not archived), if any.
  SessionRow? latestOf(String agentId) {
    final rows = live.sessions.where((s) => s.agentId == agentId && !s.archived).toList()
      ..sort((x, y) => y.when.compareTo(x.when));
    return rows.firstOrNull;
  }

  /// The conversations [agentId] is running now, the latest first.
  List<SessionRow> runningOf(String agentId) =>
      live.sessions.where((s) => s.agentId == agentId && s.running && !s.archived).toList();

  /// Stops every turn [agentId] is running (over the socket, else by REST).
  Future<bool> stopAgent(String agentId) async {
    var ok = true;
    for (final s in runningOf(agentId)) {
      final sock = socket;
      if (sock != null && sock.send({'type': 'session.interrupt', 'sessionId': s.id})) continue;
      try {
        await client?.interruptSession(s.id);
      } on ApiException {
        ok = false;
      }
    }
    return ok;
  }

  Future<void> _loadLists() async {
    final c = client;
    if (c == null) return;
    unawaited(spend.refresh(c));
    unawaited(noInternet.refresh(c));
    await _loadProjects(c);
    try {
      live.setSessions(await c.sessions());
    } on ApiException {
      // Shown empty; the next refresh tries again.
    }
    // With the link open the requests are the ones the server sent after `welcome` and since:
    // a list read a moment earlier would drop one just asked (p3.8.9, «0 da te»).
    if (socket?.status == LiveStatus.open) return;
    try {
      final list = await c.permissions();
      if (socket?.status != LiveStatus.open) live.setApprovals(list);
    } on ApiException {
      // Idem.
    }
  }

  Future<void> _loadProjects(RedGiantClient c) async {
    try {
      final all = await c.projects();
      projects = [
        for (final p in all)
          if (!p.archived) p,
      ];
      archivedProjects = [
        for (final p in all)
          if (p.archived) p,
      ];
      // Each project's subprojects, as the page's `refreshSubprojects` (a project that cannot
      // say has none).
      final subs = await Future.wait([
        for (final p in projects) c.subprojects(p.id).catchError((Object _) => <Subproject>[]),
      ]);
      subprojects = [for (final l in subs) ...l];
      projectsVersion++;
    } on ApiException {
      // The filter shows no projects.
    }
  }

  /// The team read again: a face changed elsewhere («Change mascot» on the page) is drawn again.
  Future<void> _loadAgents(RedGiantClient c) async {
    final list = await c.agents();
    final m = mascots;
    if (m is ClientMascotSource) {
      final seeds = {for (final a in agents) a.id: a.mascotSeed};
      for (final a in list) {
        if (seeds.containsKey(a.id) && seeds[a.id] != a.mascotSeed) m.forget(a.id);
      }
    }
    agents = list;
  }

  void _startLive() {
    final c = client;
    final t = c?.token;
    if (!liveEnabled || c == null || t == null || !c.transport.live) return;
    final s = socket = LiveSocket.over(c.transport, t);
    _liveSub = s.messages.listen((m) {
      live.apply(m);
      // The shared browser watched again after a drop (the server forgets the watchers).
      if (m['type'] == 'welcome' && live.browser.watching) s.send({'type': 'browser.watch'});
    });
    var opened = false;
    _statusSub = s.statuses.listen((st) {
      // Back after a drop: what changed meanwhile (conversations started or ended elsewhere).
      // The team and the projects too: what was made, renamed or archived while the link was
      // down never reaches the app as a message (p3.8.9).
      if (st == LiveStatus.open) {
        if (opened) _soonReload(agents: true, projects: true, sessions: true, fresh: true);
        opened = true;
        // «Stop» pressed while the link was down.
        for (final id in _stopWhenBack.toList()) {
          if (s.send({'type': 'session.interrupt', 'sessionId': id})) _stopWhenBack.remove(id);
        }
      }
      liveStatus = st;
      if (st == LiveStatus.refused) error = ConnectError.signInAgain;
      notifyListeners();
    });
    unawaited(s.start());
  }

  void _soonReloadSessions({bool fresh = false}) => _soonReload(sessions: true, fresh: fresh);

  // What the next reload reads: a burst of news (God making a project and its agents) is read
  // once, with every list any of it named.
  bool _reloadAgents = false;
  bool _reloadProjects = false;
  bool _reloadSessions = false;
  bool _reloadFresh = false;

  /// The lists named, read again soon (once for a burst) and shown: the wall, the mascots' bar,
  /// the conversations, the projects, «working» and the counters all follow from them.
  void _soonReload({
    bool agents = false,
    bool projects = false,
    bool sessions = false,
    bool fresh = false,
  }) {
    _reloadAgents |= agents;
    _reloadProjects |= projects;
    _reloadSessions |= sessions;
    _reloadFresh |= fresh;
    _reloadTimer?.cancel();
    _reloadTimer = Timer(const Duration(milliseconds: 250), () async {
      final c = client;
      if (c == null) return;
      final a = _reloadAgents, p = _reloadProjects, s = _reloadSessions, f = _reloadFresh;
      _reloadAgents = _reloadProjects = _reloadSessions = _reloadFresh = false;
      try {
        await Future.wait([
          if (a) _loadAgents(c),
          if (p) _loadProjects(c),
          if (s) c.sessions().then((rows) => live.setSessions(rows, fresh: f)),
        ]);
      } on Object {
        // Next time: the next news or the next refresh reads them.
      }
      if (identical(client, c) && (a || p)) notifyListeners();
    });
  }

  Future<void> refresh() async {
    final c = client;
    if (c == null) return;
    try {
      hello = await c.hello();
      agents = await c.agents();
      await _loadLists();
      socket?.retryNow();
    } on ApiException catch (e) {
      _fail(_errorOf(e), e.message);
    }
    notifyListeners();
  }

  /// The Chat agent's id (made by the server the first time).
  Future<String?> ensureChatAgent() async {
    if (chatAgentId != null) return chatAgentId;
    try {
      final a = await client?.chatAgent();
      chatAgentId = a?.id;
      if (a != null && !agents.any((x) => x.id == a.id)) agents = [...agents, a];
      notifyListeners();
    } on ApiException {
      // Without God there is no Chat yet.
    }
    return chatAgentId;
  }

  // ---- conversations ----

  SessionView follow(String sessionId) {
    socket?.follow(sessionId);
    return live.view(sessionId);
  }

  void unfollow(String sessionId) => socket?.unfollow(sessionId);

  /// Sends a message: over the socket (queued while the agent works), else by REST. A message
  /// sent while the agent works waits in line (`queued`, G42.1) until the log has it, and can be
  /// taken back with [unqueue].
  Future<bool> send(
    String sessionId,
    String text, {
    List<Map<String, Object?>>? images,
    List<Quote> quotes = const [],
    String? shown,
    bool secretOk = false,
  }) async {
    // A Chat conversation's first message names it (G40.9), unless the server named it already.
    final row = live.sessions.where((r) => r.id == sessionId).firstOrNull;
    final first =
        row != null &&
        row.agentId == chatAgentId &&
        row.title?.isNotEmpty != true &&
        !(live.views[sessionId]?.events.any((e) => e.type == 'message.user') ?? false);
    final sent = await _send(
      sessionId,
      text,
      images: images,
      quotes: quotes,
      shown: shown,
      secretOk: secretOk,
    );
    if (sent && first) unawaited(nameNewChat(sessionId, text));
    return sent;
  }

  Future<bool> _send(
    String sessionId,
    String text, {
    List<Map<String, Object?>>? images,
    List<Quote> quotes = const [],
    String? shown,
    bool secretOk = false,
  }) async {
    final s = socket;
    final clientId = 'app-${DateTime.now().microsecondsSinceEpoch}';
    final view = live.views[sessionId];
    if (s != null &&
        s.send(
          sessionSendMessage(
            sessionId,
            text,
            images: images,
            quotes: quotes,
            clientId: clientId,
            secretOk: secretOk,
          ),
        )) {
      // Sent while it works (as the page): shown at once in line, until the log has it.
      if (view != null && view.running) {
        view.queue(QueuedMessage(clientId: clientId, text: shown ?? text, match: text));
      }
      return true;
    }
    try {
      await client?.sendMessage(
        sessionId,
        text,
        images: images,
        quotes: quotes,
        secretOk: secretOk,
      );
      return true;
    } on ApiException {
      return false;
    }
  }

  /// Stops the turn. With the link down, «Stop» waits for it (the page's `stopWhenBack`): sent as
  /// soon as the link is back; [interrupt] says so by returning false.
  bool interrupt(String sessionId) {
    final m = {'type': 'session.interrupt', 'sessionId': sessionId};
    if (socket?.send(m) ?? false) return true;
    _stopWhenBack.add(sessionId);
    return false;
  }

  /// Conversations to stop as soon as the link is back.
  final _stopWhenBack = <String>{};

  /// «Passa avanti» (3.8.10): a conversation waiting for a place goes to the front of the line.
  /// Shown at once; the server's `turns.queue` follows. False when it no longer waits.
  Future<bool> moveFirst(String sessionId) async {
    final c = client;
    if (c == null) return false;
    final before = live.turns;
    live.turns = before.withFirst(sessionId);
    live.changed();
    try {
      live.turns = await c.turnFirst(sessionId);
      live.changed();
      return true;
    } on ApiException {
      live.turns = before;
      live.changed();
      await refreshTurns();
      return false;
    }
  }

  /// The line waiting for a place, read again (the screens that show it, on opening).
  Future<void> refreshTurns() async {
    final c = client;
    if (c == null) return;
    try {
      live.turns = await c.turns();
      live.changed();
    } on ApiException {
      // The socket's `turns.queue` keeps it up to date anyway.
    }
  }

  /// The background commands' strip reduced to one line (the page's `rg.cmdStrip`, this device).
  bool commandStripMin = false;

  void setCommandStripMin(bool v) {
    commandStripMin = v;
    unawaited(prefs.set('cmdStrip', v ? 'min' : null));
    notifyListeners();
  }

  /// «Ferma» a background command (`command.stop`, no confirmation, as the page).
  void stopCommand(String sessionId, String id) =>
      socket?.send({'type': 'command.stop', 'sessionId': sessionId, 'id': id});

  /// Takes a finished command off the strip (`command.close`: off on every device).
  void closeCommand(String sessionId, String id) =>
      socket?.send({'type': 'command.close', 'sessionId': sessionId, 'id': id});

  /// The last event of each sub-agent's conversation the person has seen (its «new» ring).
  Map<String, int> subSeen = {};

  void markSubSeen(String childSessionId, int seq) {
    if ((subSeen[childSessionId] ?? 0) >= seq) return;
    subSeen = {...subSeen, childSessionId: seq};
    unawaited(prefs.set('subSeen', jsonEncode(subSeen)));
  }

  /// Which sub-agent's tab is open in each conversation, level by level (the page's `subPath`).
  final Map<String, List<String>> subPath = {};

  void openSubPath(String rootSessionId, List<String> path) {
    subPath[rootSessionId] = List.unmodifiable(path);
    notifyListeners();
  }

  /// Closes a finished sub-agent's tab (`subagent.close`): closed stays closed everywhere.
  void closeSubagent(String parentSessionId, String childSessionId) => socket?.send({
    'type': 'subagent.close',
    'sessionId': parentSessionId,
    'childSessionId': childSessionId,
  });

  /// Watches the agents' shared browser (`browser.watch`) or stops (`browser.unwatch`).
  void watchBrowser(bool on) {
    final b = live.browser;
    if (b.watching == on) return;
    b.watching = on;
    if (on) b.reset();
    socket?.send({'type': on ? 'browser.watch' : 'browser.unwatch'});
  }

  /// Takes control of the shared browser, or gives it back to the agents.
  void browserControl(bool take) => socket?.send({'type': 'browser.control', 'take': take});

  /// Goes to an address (only with the person's control; the server adds https://).
  void browserGoto(String url) => socket?.send({'type': 'browser.goto', 'url': url});

  /// A click, a scroll, text or a key on the shared browser (x, y between 0 and 1).
  void browserInput(Map<String, Object?> event) =>
      socket?.send({'type': 'browser.input', 'event': event});

  /// Starts or ends teaching an assistant a task in the shared browser.
  void browserTeach(String agentId, {required bool start, String? title}) => socket?.send({
    'type': 'browser.teach',
    'agentId': agentId,
    'start': start,
    if (title != null && title.trim().isNotEmpty) 'title': title.trim(),
  });

  /// Takes back a message still waiting in line (`session.unqueue`, 2026-11-05 in the page).
  void unqueue(String sessionId, String clientId) {
    socket?.send({'type': 'session.unqueue', 'sessionId': sessionId, 'clientId': clientId});
    live.views[sessionId]?.unqueue(clientId);
  }

  /// «Continua da qui» or «Modifica» (G36.23): a new conversation from this message on, or up to
  /// before it (the edited text is then sent there). Null when it failed.
  Future<String?> forkSession(String sessionId, {int? fromSeq, int? beforeSeq}) async {
    final c = client;
    if (c == null) return null;
    try {
      final id = await c.forkSession(sessionId, fromSeq: fromSeq, beforeSeq: beforeSeq);
      live.setSessions(await c.sessions());
      return id;
    } on ApiException {
      return null;
    }
  }

  /// A conversation pinned, archived or moved to a folder (the page's row actions, the same
  /// `PATCH /api/sessions/:id`); the rows are read again. False when it failed.
  Future<bool> updateSession(
    String sessionId, {
    bool? pinned,
    bool? archived,
    String? folder,
    bool clearFolder = false,
  }) async {
    final c = client;
    if (c == null) return false;
    try {
      await c.updateSession(
        sessionId,
        pinned: pinned,
        archived: archived,
        folder: folder,
        clearFolder: clearFolder,
      );
      live.setSessions(await c.sessions());
      return true;
    } on ApiException {
      return false;
    }
  }

  /// The conversation as Markdown (the page's «Export»); null when it failed.
  Future<Uint8List?> exportSession(String sessionId) async {
    try {
      return await client?.exportSession(sessionId);
    } on ApiException {
      return null;
    }
  }

  /// What «Archive» would stop in a project (said first, as the page does); null when it failed.
  Future<ProjectWork?> projectWork(String projectId) async {
    try {
      return await client?.projectWork(projectId);
    } on ApiException {
      return null;
    }
  }

  /// «Archive» a whole project (p3.5.3): its agents stop, its automations pause, read only.
  Future<String?> archiveProject(String projectId) async {
    try {
      await client?.archiveProject(projectId);
      await _loadLists();
      notifyListeners();
      return null;
    } on ApiException catch (e) {
      return e.message;
    }
  }

  /// The projects and their subprojects read again (a subproject made or brought in).
  Future<void> reloadProjects() async {
    final c = client;
    if (c == null) return;
    await _loadProjects(c);
    notifyListeners();
  }

  /// How many agents [projectId] may have besides its orchestrator (2026-11-18): null when saved,
  /// else what went wrong (in the person's words when the server gives a code).
  Future<String?> setProjectMaxAgents(String projectId, int maxAgents) async {
    try {
      await client?.setProjectMaxAgents(projectId, maxAgents);
      await _loadLists();
      notifyListeners();
      return null;
    } on ApiException catch (e) {
      return e.message;
    }
  }

  /// «Initialise git» (3.5.12) for a project made without its repository.
  Future<bool> initProjectGit(String projectId) async {
    try {
      await client?.initProjectGit(projectId);
      await _loadLists();
      notifyListeners();
      return true;
    } on ApiException {
      return false;
    }
  }

  /// «Ripristina» an archived project (from its conversation, read only until then).
  Future<bool> restoreProject(String projectId) async {
    try {
      await client?.restoreProject(projectId);
      await _loadLists();
      notifyListeners();
      return true;
    } on ApiException {
      return false;
    }
  }

  /// Undoes the last summary asked by hand (G24.14): the `compaction.undone` event marks it.
  Future<bool> undoCompaction(String sessionId) async {
    try {
      await client?.undoCompaction(sessionId);
      return true;
    } on ApiException {
      return false;
    }
  }

  /// The conversation to open with [a]: God and Demi-God their shared one, the others their
  /// latest (or a new one with [fresh]).
  Future<String?> openAgent(Agent a, {bool fresh = false}) async {
    final c = client;
    if (c == null) return null;
    try {
      if (!fresh && (a.kind == AgentKind.god || a.kind == AgentKind.demigod)) {
        return await c.workSession(a.id);
      }
      if (!fresh) {
        final last = live.sessions.where((s) => s.agentId == a.id && !s.archived).firstOrNull;
        if (last != null) return last.id;
      }
      final id = await c.newSession(a.id);
      _soonReloadSessions();
      return id;
    } on ApiException {
      return null;
    }
  }

  /// A new Chat conversation's title from its first message (G40.9), unless the server gave one
  /// already: its first line, at most [max] characters, cut at a word.
  static String titleFrom(String text, {int max = 60}) {
    final line = text.trim().split('\n').first.trim().replaceAll(RegExp(r'\s+'), ' ');
    if (line.length <= max) return line;
    final cut = line.substring(0, max);
    final sp = cut.lastIndexOf(' ');
    return '${(sp > max ~/ 2 ? cut.substring(0, sp) : cut).trimRight()}…';
  }

  Future<void> nameNewChat(String sessionId, String firstMessage) async {
    final row = live.sessions.where((s) => s.id == sessionId).firstOrNull;
    if (row?.title?.isNotEmpty == true || firstMessage.trim().isEmpty) return;
    final title = titleFrom(firstMessage);
    try {
      await client?.renameSession(sessionId, title);
      live.setSessions([for (final s in live.sessions) s.id == sessionId ? s.withTitle(title) : s]);
    } on ApiException {
      // Untitled until the next try; the page can name it too.
    }
  }

  Future<String?> newChatSession() async {
    final id = await ensureChatAgent();
    final c = client;
    if (id == null || c == null) return null;
    try {
      final sid = await c.newSession(id);
      live.setSessions(await c.sessions());
      return sid;
    } on ApiException {
      return null;
    }
  }

  // ---- requests (G36.17: the app is one of the channels) ----

  /// Yes or no to a permission. A critical request's yes only from its full screen
  /// ([fromFullScreen]), never the quick one.
  ///
  /// From the card in the conversation (G42.1, as the page's `ToolPermission`): [scope] `session`
  /// allows it for this conversation, `always` for the agent (`remember`); [reason] is the «Nega e
  /// spiega» the agent reads; [capUsd] an artifact's spending cap. Those go only over the socket.
  Future<bool> resolvePermission(
    PermissionRequest r, {
    required bool allow,
    bool fromFullScreen = false,
    String scope = 'once',
    String? reason,
    double? capUsd,
  }) async {
    if (allow && r.isCritical && !fromFullScreen) return false;
    final s = socket;
    final why = reason?.trim();
    if (s != null &&
        s.send({
          'type': 'permission.resolve',
          'requestId': r.requestId,
          'decision': allow ? 'allow' : 'deny',
          if (scope != 'once' || why != null || capUsd != null) ...{
            'remember': scope == 'always',
            'scope': scope,
          },
          if (why != null && why.isNotEmpty) 'reason': why,
          if (allow && capUsd != null) 'capUsd': capUsd,
        })) {
      return true;
    }
    // Without the socket only the plain yes or no (the notification's route).
    if (scope != 'once' || capUsd != null || (why != null && why.isNotEmpty)) return false;
    try {
      await client?.answerRequest(r.requestId, allow: allow);
      live.apply({
        'type': 'permission.closed',
        'requestId': r.requestId,
        'decision': allow ? 'allow' : 'deny',
        'via': 'app',
      });
      return true;
    } on ApiException {
      return false;
    }
  }

  bool answerQuestion(QuestionRequest q, List<List<String>> answers) =>
      answerQuestionId(q.requestId, answers);

  /// `question.answer` (the card in the conversation answers by the request's id).
  bool answerQuestionId(String requestId, List<List<String>> answers) =>
      socket?.send({'type': 'question.answer', 'requestId': requestId, 'answers': answers}) ??
      false;

  // ---- notifications, voice and sharing (G40.10) ----

  bool get desktop =>
      platform == DevicePlatform.windows ||
      platform == DevicePlatform.macos ||
      platform == DevicePlatform.linux;

  /// Once at start, before [restore]: the system's notifications and the distributor's events.
  Future<void> startSystems() async {
    try {
      await notifier.init(onResponse: _onNoticeResponse);
    } on Object {
      // A system without notifications: the app works without them.
    }
    final start = _startDistributors;
    if (start != null) {
      try {
        distributors = await start(pushCenter);
      } on Object {
        // No UnifiedPush here.
      }
    }
    try {
      share.incoming.listen(_shared, onError: (_) {});
    } on Object {
      // No Share sheet here.
    }
  }

  /// After [restore]: a tap that started the app, and what another app shared.
  Future<void> takeLaunch() async {
    final tap = await notifier.launchTap().catchError((_) => null);
    if (tap != null) await openTap(tap);
    try {
      final first = await share.initial();
      if (first.isNotEmpty) _shared(first);
    } on Object {
      // No Share sheet here.
    }
  }

  void _shared(List<SharedItem> items) {
    if (items.isEmpty) return;
    pendingShare = items;
    notifyListeners();
  }

  /// The Share screen took it (sent or put aside).
  void shareHandled() {
    pendingShare = null;
    unawaited(share.done().catchError((_) {}));
    notifyListeners();
  }

  String? takePendingSession() {
    final s = pendingSession;
    pendingSession = null;
    return s;
  }

  void setForeground(bool v) {
    if (foreground == v) return;
    foreground = v;
    // Back from the background the socket may look open and be dead: asked at once.
    if (v) socket?.checkNow();
  }

  /// G40.17: from which window width (logical pixels) a computer uses its own layout, the
  /// «control room»; 0 always, -1 never (the phone's, as before). Phones and tablets never do.
  int desktopFrom = kDesktopFrom;

  bool desktopLayoutFor(double width) => desktop && desktopFrom >= 0 && width >= desktopFrom;

  void setDesktopFrom(int v) {
    desktopFrom = v;
    unawaited(prefs.set('desktopFrom', v == kDesktopFrom ? null : '$v'));
    notifyListeners();
  }

  void setDesktopNotify(bool v) {
    desktopNotify = v;
    unawaited(prefs.set('desktopNotify', v ? null : '0'));
    notifyListeners();
  }

  AppLocalizations get _words => wordsFor(locale?.languageCode);

  /// A tap on a notification (or on one of its answers) while the app runs.
  void _onNoticeResponse(NoticeTap tap, String? action) {
    final a = quickAnswerOf(action);
    if (a == null) {
      unawaited(openTap(tap));
      return;
    }
    final here = tap.serverId == server?.id;
    final r = live.approvals.where((x) => x.requestId == tap.requestId).firstOrNull;
    if (here && r != null && socket != null) {
      // Over the live connection, with the same rule: never a quick yes to a critical request.
      unawaited(resolvePermission(r, allow: a == QuickAnswer.allow));
      return;
    }
    unawaited(pushCenter.answer(tap, a));
  }

  /// Opens what a notification is about: its RedGiant, then For you or the conversation.
  Future<void> openTap(NoticeTap tap) async {
    if (tap.serverId != server?.id) {
      final s = servers.where((x) => x.id == tap.serverId).firstOrNull;
      if (s != null) await useServer(s);
    }
    if (tap.kind == NoticeKind.request ||
        tap.kind == NoticeKind.question ||
        (tap.kind == NoticeKind.automation && tap.sessionId == null)) {
      tab = AppTab.inbox;
    } else if (tap.sessionId != null) {
      pendingSession = tap.sessionId;
    }
    notifyListeners();
  }

  Set<String> _seenRequests = const {};
  Set<String> _seenNotices = const {};
  Object? _seenNoticeList;

  /// Requests that come and go on the live connection: the notification of one answered
  /// anywhere is withdrawn; on a computer behind other windows a new one is notified.
  void _onLiveChanged() {
    // The conversations, the requests and the questions are new lists whenever they change (a
    // stream's delta changes none of them): every screen that reads them through [AppScope]
    // draws again (p3.8.9: the status bar said «0 da te» while the wall showed the agent
    // waiting, being a const piece under a builder that listened to the live model only).
    if (!identical(live.sessions, _seenSessions) ||
        !identical(live.approvals, _seenApprovals) ||
        !identical(live.questions, _seenQuestions) ||
        !identical(live.notices, _seenNoticeList)) {
      _seenNoticeList = live.notices;
      _seenSessions = live.sessions;
      _seenApprovals = live.approvals;
      _seenQuestions = live.questions;
      notifyListeners();
    }
    final sid = server?.id;
    final all = <PersonRequest>[...live.approvals, ...live.questions];
    final now = {for (final r in all) r.requestId};
    if (sid == null) {
      _seenRequests = now;
      return;
    }
    for (final gone in _seenRequests.difference(now)) {
      unawaited(notifier.cancel(notificationIdOf(sid, 'req:$gone')).catchError((_) {}));
    }
    if (desktop && desktopNotify && !foreground) {
      final l = _words;
      for (final r in all.where((r) => !_seenRequests.contains(r.requestId))) {
        final n = liveNoticeFor(r, displayName, l);
        unawaited(notifier.apply(planFor(n, sid), l).catchError((_) {}));
      }
      // G42.9: an automation's message, as the page's `notifyHidden`.
      for (final n in live.notices.where((n) => !_seenNotices.contains(n.runId))) {
        final p = automationNoticeFor(n, displayName, l);
        unawaited(notifier.apply(planFor(p, sid), l).catchError((_) {}));
      }
    }
    _seenRequests = now;
    _seenNotices = {for (final n in live.notices) n.runId};
  }

  /// What the person sees in Tu › Notifiche for the RedGiant in use.
  Future<PushChannelState?> pushState() async {
    final s = server;
    return s == null ? null : pushCenter.registrar.stateOf(s.id);
  }

  String? get _deviceId => hello?.deviceId ?? server?.deviceId;

  /// Turns on this phone's notifications for the RedGiant in use through [distributor]. The
  /// endpoint arrives later ([Distributors.events]).
  Future<bool> enablePush(String distributor) async {
    final s = server;
    final c = client;
    if (s == null || c == null || _deviceId == null) return false;
    await notifier.askPermission().catchError((_) => false);
    await distributors.choose(distributor);
    final vapid = (await c.pushInfo()).vapidPublicKey;
    await distributors.register(s.id, vapid: vapid);
    return true;
  }

  /// No more notifications from the RedGiant in use on this device.
  Future<void> disablePush() async {
    final s = server;
    if (s == null) return;
    await distributors.unregister(s.id).catchError((_) {});
    try {
      await pushCenter.registrar.unregister(client, s.id, _deviceId);
    } on ApiException {
      await pushCenter.registrar.forget(s.id);
    }
    notifyListeners();
  }

  /// UnifiedPush wants `register` at every start with the same distributor; iOS registers once
  /// APNs is on (prepared, off).
  Future<void> _renewPush() async {
    final s = server;
    final c = client;
    final id = _deviceId;
    if (s == null || c == null || id == null) return;
    try {
      final st = await pushCenter.registrar.stateOf(s.id);
      if (st?.kind == 'webpush' && distributors.supported && await distributors.current() != null) {
        await distributors.register(s.id, vapid: (await c.pushInfo()).vapidPublicKey);
      } else if (st?.kind == 'apns' && ApnsRegistration.available) {
        await ApnsRegistration.register(pushCenter, c, s.id, id);
      }
    } on Object {
      // The next start tries again.
    }
  }

  // ---- servers ----

  Future<void> disconnect() async {
    final s = server;
    await _drop();
    if (s != null) {
      unawaited(distributors.unregister(s.id).catchError((_) {}));
      unawaited(pushCenter.registrar.forget(s.id).catchError((_) {}));
      await tokens.delete(s.id);
      servers = await book.remove(s.id);
    }
    server = null;
    await prefs.set('current', null);
    notifyListeners();
  }

  Future<void> renameServer(SavedServer s, String label) async {
    final t = label.trim();
    if (t.isEmpty) return;
    final n = s.copyWith(label: t);
    servers = await book.put(n);
    if (server?.id == s.id) server = n;
    notifyListeners();
  }

  Future<void> _drop() async {
    _reloadTimer?.cancel();
    updateRun?.dispose();
    updateRun = null;
    _updateToOpen = false;
    await _liveSub?.cancel();
    await _statusSub?.cancel();
    final s = socket;
    socket = null;
    await s?.close();
    liveStatus = null;
    client?.close();
    client = null;
    hello = null;
    mascots = null;
    agents = const [];
    projects = const [];
    subprojects = const [];
    favourites = const {};
    teamFilter = TeamFilter.all;
    chatAgentId = null;
    _models = null;
    _seenRequests = const {};
    live.clear();
    spend.clear();
    noInternet.clear();
    unawaited(voice.attach(null, null));
  }

  bool _fail(ConnectError e, [String? message]) {
    error = e;
    errorMessage = message;
    return false;
  }

  static ConnectError _errorOf(ApiException e) {
    if (e.certificate) return ConnectError.certificate;
    if (e.unreachable) return ConnectError.unreachable;
    return switch (e.code) {
      'wrong' => ConnectError.wrong,
      'code_needed' => ConnectError.codeNeeded,
      'too_many' => ConnectError.tooMany,
      'no_password' => ConnectError.noPassword,
      _ => e.status == 401 ? ConnectError.signInAgain : ConnectError.other,
    };
  }
}

class _KeyChanged implements Exception {
  const _KeyChanged(this.seen);

  final String? seen;
}

/// Team's filter values besides a project's id.
abstract final class TeamFilter {
  static const all = '';
  static const favourites = '*';
}

class AppScope extends InheritedNotifier<AppController> {
  const AppScope({super.key, required AppController controller, required super.child})
    : super(notifier: controller);

  static AppController of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<AppScope>()!.notifier!;

  /// Without depending on it (initState, callbacks).
  static AppController read(BuildContext context) =>
      context.getInheritedWidgetOfExactType<AppScope>()!.notifier!;

  /// Null outside the app (a piece shown alone, as the tests do).
  static AppController? maybeRead(BuildContext context) =>
      context.getInheritedWidgetOfExactType<AppScope>()?.notifier;
}

/// The tasks of every project, for Activity.
Future<List<TaskRow>> allTasks(RedGiantClient c) async {
  final out = <TaskRow>[];
  for (final p in await c.projects()) {
    if (p.archived) continue;
    try {
      out.addAll(await c.tasks(p.id));
    } on ApiException {
      // A project without tasks to show.
    }
  }
  return out;
}

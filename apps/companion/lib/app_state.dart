// The app's state (G40.6, G40.7): appearance and language (kept between starts), the RedGiants
// the app knows and the one in use, the live connection and what the screens show. One
// ChangeNotifier, given to the tree by [AppScope]; the screens rebuild from it.
import 'dart:async';
import 'dart:convert';
import 'dart:io' show Platform;
import 'dart:math';

import 'package:flutter/material.dart';

import 'api/client.dart';
import 'api/conversation.dart';
import 'api/discovery.dart';
import 'api/live.dart';
import 'api/live_model.dart';
import 'api/names.dart';
import 'api/servers.dart';
import 'api/settings_types.dart';
import 'api/setup_channel.dart';
import 'api/token_store.dart';
import 'api/transport.dart';
import 'api/types.dart';
import 'mascot/mascot_source.dart';

/// The five places of proposal A, in the bar's order.
enum AppTab { team, chat, inbox, activity, you }

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
  }) : tokens = tokens ?? SecureTokenStore(),
       prefs = prefs ?? MemoryAppPrefs(),
       platform = platform ?? currentPlatform(),
       _clientFactory = clientFactory,
       _dial =
           dialChannel ?? ((b, id, expect) => SetupChannel.dial(b, identity: id, expect: expect)) {
    book = ServerBook(this.prefs);
    live.onUnknownSession = _soonReloadSessions;
  }

  final TokenStore tokens;
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
  LiveSocket? socket;
  LiveStatus? liveStatus;
  StreamSubscription<Map<String, dynamic>>? _liveSub;
  StreamSubscription<LiveStatus>? _statusSub;
  Timer? _reloadTimer;

  /// The Chat's new conversation, started from the field over the bar: opened by the Chat screen.
  String? chatDraft;

  /// The projects of the RedGiant in use (Team's filter).
  List<Project> projects = const [];

  /// Team's favourites, per RedGiant (kept on this device).
  Set<String> favourites = const {};

  /// Team's filter: [TeamFilter.all], [TeamFilter.favourites] or a project's id.
  String teamFilter = TeamFilter.all;

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
    DevicePlatform.android => 'RGCompanion (Android)',
    DevicePlatform.ios => 'RGCompanion (iOS)',
    DevicePlatform.windows => 'RGCompanion (Windows)',
    DevicePlatform.macos => 'RGCompanion (macOS)',
    DevicePlatform.linux => 'RGCompanion (Linux)',
    DevicePlatform.other => 'RGCompanion',
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
  Future<void> restore() async {
    final theme = await prefs.get('theme');
    themeMode = ThemeMode.values.firstWhere((m) => m.name == theme, orElse: () => ThemeMode.system);
    final lang = await prefs.get('locale');
    locale = lang == null ? null : Locale(lang);
    reduceMotion = await prefs.get('reduceMotion') == '1';
    servers = await book.load();
    notifyListeners();
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
    final token = await tokens.read(s.id);
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
  }

  // ---- Team: favourites and the project filter (G40.9) ----

  String get _favKey => 'favourites:${server?.id ?? '-'}';

  Future<void> _loadTeamPrefs() async {
    final raw = await prefs.get(_favKey);
    favourites = raw == null || raw.isEmpty ? <String>{} : raw.split(',').toSet();
    teamFilter = await prefs.get('teamFilter:${server?.id ?? '-'}') ?? TeamFilter.all;
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
    try {
      projects = [
        for (final p in await c.projects())
          if (!p.archived) p,
      ];
    } on ApiException {
      // The filter shows no projects.
    }
    try {
      live.setSessions(await c.sessions());
    } on ApiException {
      // Shown empty; the next refresh tries again.
    }
    try {
      live.setApprovals(await c.permissions());
    } on ApiException {
      // Idem.
    }
  }

  void _startLive() {
    final c = client;
    final t = c?.token;
    if (!liveEnabled || c == null || t == null || !c.transport.live) return;
    final s = socket = LiveSocket.over(c.transport, t);
    _liveSub = s.messages.listen(live.apply);
    _statusSub = s.statuses.listen((st) {
      liveStatus = st;
      if (st == LiveStatus.refused) error = ConnectError.signInAgain;
      notifyListeners();
    });
    unawaited(s.start());
  }

  void _soonReloadSessions() {
    _reloadTimer?.cancel();
    _reloadTimer = Timer(const Duration(milliseconds: 250), () async {
      final c = client;
      if (c == null) return;
      try {
        live.setSessions(await c.sessions());
      } on ApiException {
        // Next time.
      }
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

  /// Sends a message: over the socket (queued while the agent works), else by REST.
  Future<bool> send(String sessionId, String text, {List<Map<String, Object?>>? images}) async {
    // A Chat conversation's first message names it (G40.9), unless the server named it already.
    final row = live.sessions.where((r) => r.id == sessionId).firstOrNull;
    final first =
        row != null &&
        row.agentId == chatAgentId &&
        row.title?.isNotEmpty != true &&
        !(live.views[sessionId]?.events.any((e) => e.type == 'message.user') ?? false);
    final sent = await _send(sessionId, text, images: images);
    if (sent && first) unawaited(nameNewChat(sessionId, text));
    return sent;
  }

  Future<bool> _send(String sessionId, String text, {List<Map<String, Object?>>? images}) async {
    final s = socket;
    if (s != null &&
        s.send({
          'type': 'session.send',
          'sessionId': sessionId,
          'text': text,
          if (images != null && images.isNotEmpty) 'images': images,
          'clientId': 'app-${DateTime.now().microsecondsSinceEpoch}',
        })) {
      return true;
    }
    try {
      await client?.sendMessage(sessionId, text, images: images);
      return true;
    } on ApiException {
      return false;
    }
  }

  void interrupt(String sessionId) =>
      socket?.send({'type': 'session.interrupt', 'sessionId': sessionId});

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
  Future<bool> resolvePermission(
    PermissionRequest r, {
    required bool allow,
    bool fromFullScreen = false,
  }) async {
    if (allow && r.isCritical && !fromFullScreen) return false;
    final s = socket;
    if (s != null &&
        s.send({
          'type': 'permission.resolve',
          'requestId': r.requestId,
          'decision': allow ? 'allow' : 'deny',
        })) {
      return true;
    }
    try {
      await client?.answerRequest(r.requestId, allow: allow);
      live.apply({'type': 'permission.closed', 'requestId': r.requestId, 'via': 'app'});
      return true;
    } on ApiException {
      return false;
    }
  }

  bool answerQuestion(QuestionRequest q, List<List<String>> answers) =>
      socket?.send({'type': 'question.answer', 'requestId': q.requestId, 'answers': answers}) ??
      false;

  // ---- servers ----

  Future<void> disconnect() async {
    final s = server;
    await _drop();
    if (s != null) {
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
    favourites = const {};
    teamFilter = TeamFilter.all;
    chatAgentId = null;
    _models = null;
    live.clear();
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

// The app's state (G40.6): appearance, the connected RedGiant and what the screens show. One
// ChangeNotifier, given to the tree by [AppScope]; the screens rebuild from it.
import 'dart:io' show Platform;

import 'package:flutter/material.dart';

import 'api/client.dart';
import 'api/token_store.dart';
import 'api/types.dart';
import 'mascot/mascot_source.dart';

/// The five places of proposal A, in the bar's order.
enum AppTab { team, chat, inbox, activity, you }

/// Why connecting did not work, for the person (translated by the screens).
enum ConnectError { unreachable, wrong, codeNeeded, tooMany, noPassword, tooOld, tooNew, other }

typedef ClientFactory = RedGiantClient Function(Uri base, String? token);

DevicePlatform currentPlatform() {
  try {
    return devicePlatformFrom(Platform.operatingSystem);
  } on UnsupportedError {
    return DevicePlatform.other;
  }
}

class AppController extends ChangeNotifier {
  AppController({TokenStore? tokens, ClientFactory? clientFactory, DevicePlatform? platform})
    : tokens = tokens ?? SecureTokenStore(),
      platform = platform ?? currentPlatform(),
      _clientFactory = clientFactory ?? ((b, t) => RedGiantClient(b, token: t));

  final TokenStore tokens;
  final DevicePlatform platform;
  final ClientFactory _clientFactory;

  ThemeMode themeMode = ThemeMode.system;

  /// null: the system's language.
  Locale? locale;
  bool reduceMotion = false;

  AppTab tab = AppTab.team;

  RedGiantClient? client;
  MascotSource? mascots;
  AppHello? hello;
  List<Agent> agents = const [];
  bool connecting = false;
  ConnectError? error;
  String? errorMessage;

  /// The Chat's new conversation, started from the field over the bar.
  String? chatDraft;

  bool get connected => client != null && hello?.signedIn == true;

  void setTab(AppTab t) {
    if (tab == t) return;
    tab = t;
    notifyListeners();
  }

  void setThemeMode(ThemeMode m) {
    themeMode = m;
    notifyListeners();
  }

  void setLocale(Locale? l) {
    locale = l;
    notifyListeners();
  }

  void setReduceMotion(bool v) {
    reduceMotion = v;
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

  String _serverKey(Uri base) => RedGiantClient.normalizeBase(base).toString();

  /// The device's name on the server (Settings › Devices).
  String get deviceName => switch (platform) {
    DevicePlatform.android => 'RGCompanion (Android)',
    DevicePlatform.ios => 'RGCompanion (iOS)',
    DevicePlatform.windows => 'RGCompanion (Windows)',
    DevicePlatform.macos => 'RGCompanion (macOS)',
    DevicePlatform.linux => 'RGCompanion (Linux)',
    DevicePlatform.other => 'RGCompanion',
  };

  /// Pairs with [address] using the password once; keeps only the device's token.
  Future<bool> connect(String address, String password, {String? code}) async {
    final base = RedGiantClient.normalizeBase(Uri.parse(address.trim()));
    connecting = true;
    error = null;
    errorMessage = null;
    notifyListeners();
    final c = _clientFactory(base, null);
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
      await tokens.write(_serverKey(base), created.token);
      await tokens.write('last', base.toString());
      await _use(c);
      return connected;
    } on ApiException catch (e) {
      return _fail(_errorOf(e), e.message);
    } finally {
      connecting = false;
      notifyListeners();
    }
  }

  /// At start: the last RedGiant, if its token still works.
  Future<void> restore() async {
    final last = await tokens.read('last');
    if (last == null) return;
    final base = Uri.parse(last);
    final token = await tokens.read(_serverKey(base));
    if (token == null) return;
    try {
      await _use(_clientFactory(base, token));
    } on ApiException {
      // Unreachable for now: the screens say so; a later start tries again.
    }
    notifyListeners();
  }

  Future<void> _use(RedGiantClient c) async {
    final h = await c.hello();
    client = c;
    hello = h;
    mascots = ClientMascotSource(c);
    agents = h.signedIn ? await c.agents() : const [];
  }

  Future<void> refresh() async {
    final c = client;
    if (c == null) return;
    try {
      await _use(c);
    } on ApiException catch (e) {
      _fail(_errorOf(e), e.message);
    }
    notifyListeners();
  }

  Future<void> disconnect() async {
    final c = client;
    if (c != null) await tokens.delete(_serverKey(c.base));
    await tokens.delete('last');
    client = null;
    hello = null;
    mascots = null;
    agents = const [];
    notifyListeners();
  }

  bool _fail(ConnectError e, [String? message]) {
    error = e;
    errorMessage = message;
    return false;
  }

  static ConnectError _errorOf(ApiException e) {
    if (e.unreachable) return ConnectError.unreachable;
    return switch (e.code) {
      'wrong' => ConnectError.wrong,
      'code_needed' => ConnectError.codeNeeded,
      'too_many' => ConnectError.tooMany,
      'no_password' => ConnectError.noPassword,
      _ => ConnectError.other,
    };
  }
}

class AppScope extends InheritedNotifier<AppController> {
  const AppScope({super.key, required AppController controller, required super.child})
    : super(notifier: controller);

  static AppController of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<AppScope>()!.notifier!;
}

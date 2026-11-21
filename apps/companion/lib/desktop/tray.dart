// The computers keep running in the system tray (G42.17, notifications with the window closed):
// closing the window hides it while «Stay in the system tray» is on, so requests, questions and
// task reports still arrive as the system's notifications; the tray icon's menu opens the window
// again or quits. Behind [DesktopWindow], so the rule is tested without a real window.
import 'dart:async';
import 'dart:io' show Platform, Process;
import 'dart:ui' show Locale, PlatformDispatcher;

import 'package:flutter/foundation.dart';
import 'package:tray_manager/tray_manager.dart';
import 'package:window_manager/window_manager.dart';

import '../app_state.dart';
import '../brand.dart';
import '../l10n/app_localizations.dart';

/// The window and the tray icon, as [TrayKeeper] needs them.
abstract class DesktopWindow {
  /// Puts the icon in the tray with its menu; false when this desktop has no tray.
  Future<bool> start({required String tip, required String open, required String quit});

  /// The menu's words again (the language changed).
  Future<void> relabel({required String tip, required String open, required String quit});

  /// Whether closing the window asks [onClose] instead of ending the app.
  Future<void> keepOnClose(bool on);

  /// The person closed the window (only while [keepOnClose] is on).
  set onClose(VoidCallback? f);

  /// The icon or its «Open» was clicked.
  set onOpen(VoidCallback? f);

  /// The menu's «Quit».
  set onQuit(VoidCallback? f);

  Future<void> show();
  Future<void> hide();

  /// The app ends.
  Future<void> quit();
}

/// Keeps the window and the tray in line with the setting, and answers the window's close.
class TrayKeeper {
  TrayKeeper(this.app, this.window);

  final AppController app;
  final DesktopWindow window;

  /// The tray icon is there (some Linux desktops have no tray: the window closes as before).
  bool available = false;

  /// The window is hidden in the tray.
  bool hidden = false;

  bool? _kept;
  String? _lang;

  AppLocalizations get _l => lookupAppLocalizations(app.locale ?? _systemLocale());

  static Locale _systemLocale() =>
      Locale(PlatformDispatcher.instance.locale.languageCode == 'it' ? 'it' : 'en');

  Future<void> start() async {
    window
      ..onClose = _closed
      ..onOpen = _openSoon
      ..onQuit = _quitSoon;
    final l = _l;
    _lang = l.localeName;
    try {
      available = await window.start(tip: kAppName, open: l.trayOpen, quit: l.trayQuit);
    } on Object {
      available = false;
    }
    app.trayAvailable = available;
    app.bringToFront = _openSoon;
    app.addListener(_sync);
    await _sync0();
  }

  void _sync() => unawaited(_sync0());

  void _openSoon() => unawaited(open());

  void _quitSoon() => unawaited(quit());

  Future<void> _sync0() async {
    final keep = available && app.stayInTray;
    if (keep != _kept) {
      _kept = keep;
      await window.keepOnClose(keep).catchError((_) {});
    }
    final l = _l;
    if (available && l.localeName != _lang) {
      _lang = l.localeName;
      await window.relabel(tip: kAppName, open: l.trayOpen, quit: l.trayQuit).catchError((_) {});
    }
  }

  void _closed() {
    if (available && app.stayInTray) {
      hidden = true;
      unawaited(window.hide());
      // Hidden: requests and questions come as the system's notifications.
      app.setForeground(false);
    } else {
      unawaited(quit());
    }
  }

  /// The window back in front (the tray, or a notification tapped).
  Future<void> open() async {
    hidden = false;
    await window.show();
    app.setForeground(true);
  }

  Future<void> quit() async {
    app.removeListener(_sync);
    await window.keepOnClose(false).catchError((_) {});
    await window.quit();
  }
}

/// The real window and tray: window_manager and tray_manager.
class SystemDesktopWindow with WindowListener, TrayListener implements DesktopWindow {
  VoidCallback? _onClose;
  VoidCallback? _onOpen;
  VoidCallback? _onQuit;

  @override
  set onClose(VoidCallback? f) => _onClose = f;
  @override
  set onOpen(VoidCallback? f) => _onOpen = f;
  @override
  set onQuit(VoidCallback? f) => _onQuit = f;

  /// Before runApp: the window's plugin is ready.
  static Future<void> prepare() => windowManager.ensureInitialized();

  @override
  Future<bool> start({required String tip, required String open, required String quit}) async {
    windowManager.addListener(this);
    if (Platform.isLinux && !await linuxHasTray()) return false;
    trayManager.addListener(this);
    await trayManager.setIcon(Platform.isWindows ? 'assets/tray/tray.ico' : 'assets/tray/tray.png');
    await relabel(tip: tip, open: open, quit: quit);
    return true;
  }

  @override
  Future<void> relabel({required String tip, required String open, required String quit}) async {
    // Linux's indicators have no tooltip.
    if (!Platform.isLinux) await trayManager.setToolTip(tip);
    await trayManager.setContextMenu(
      Menu(
        items: [
          MenuItem(key: 'open', label: open),
          MenuItem.separator(),
          MenuItem(key: 'quit', label: quit),
        ],
      ),
    );
  }

  @override
  Future<void> keepOnClose(bool on) => windowManager.setPreventClose(on);

  @override
  Future<void> show() async {
    if (await windowManager.isMinimized()) await windowManager.restore();
    await windowManager.show();
    await windowManager.focus();
  }

  @override
  Future<void> hide() => windowManager.hide();

  @override
  Future<void> quit() async {
    await trayManager.destroy().catchError((_) {});
    await windowManager.destroy();
  }

  @override
  void onWindowClose() => _onClose?.call();

  @override
  void onTrayIconMouseDown() => _onOpen?.call();

  @override
  void onTrayIconRightMouseDown() => unawaited(trayManager.popUpContextMenu());

  @override
  void onTrayMenuItemClick(MenuItem menuItem) {
    if (menuItem.key == 'open') _onOpen?.call();
    if (menuItem.key == 'quit') _onQuit?.call();
  }
}

/// A Linux desktop shows tray icons only with a StatusNotifier host (KDE, Ubuntu's GNOME, Xfce
/// with its plugin…): without one a hidden window could not come back.
Future<bool> linuxHasTray() async {
  try {
    final r = await Process.run('gdbus', [
      'call',
      '--session',
      '--dest',
      'org.freedesktop.DBus',
      '--object-path',
      '/org/freedesktop/DBus',
      '--method',
      'org.freedesktop.DBus.NameHasOwner',
      'org.kde.StatusNotifierWatcher',
    ]);
    return r.exitCode == 0 && '${r.stdout}'.contains('true');
  } on Object {
    return false;
  }
}

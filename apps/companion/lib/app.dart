import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'api/live_model.dart';
import 'app_state.dart';
import 'brand.dart';
import 'app_update/update_window.dart';
import 'desktop/desktop_shell.dart';
import 'l10n/app_localizations.dart';
import 'mascot/mascot_source.dart';
import 'screens/home_shell.dart';
import 'simple/simple_shell.dart';
import 'theme/theme.dart';

class RGCompanionApp extends StatelessWidget {
  const RGCompanionApp({super.key, required this.controller});

  final AppController controller;

  @override
  Widget build(BuildContext context) => AppScope(
    controller: controller,
    child: ListenableBuilder(
      listenable: controller,
      builder: (context, _) => MaterialApp(
        title: kAppName,
        scaffoldMessengerKey: serverErrorMessenger,
        debugShowCheckedModeBanner: false,
        theme: buildTheme(Brightness.light, controller.accent),
        darkTheme: buildTheme(Brightness.dark, controller.accent),
        themeMode: controller.themeMode,
        locale: controller.locale,
        supportedLocales: AppLocalizations.supportedLocales,
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        // Without a match the app speaks English; Italian when the system does.
        localeResolutionCallback: (locale, supported) => supported.firstWhere(
          (s) => s.languageCode == locale?.languageCode,
          orElse: () => const Locale('en'),
        ),
        builder: (context, child) => _ServerErrors(
          live: controller.live,
          child: MascotScope(
            source: controller.mascots,
            reduceMotion: controller.reduceMotion,
            agentOf: controller.agentWithId,
            child: child!,
          ),
        ),
        home: const AppHome(),
      ),
    ),
  );
}

/// The phone's shell, or the computers' control room (G40.17) when the app runs on a computer
/// and its window is at least as wide as the person chose (Tu › Aspetto).
class AppHome extends StatelessWidget {
  const AppHome({super.key});

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    return AppUpdateWatcher(
      child: LayoutBuilder(
        builder: (context, box) => app.simpleUi && app.server != null
            // 3.12: the simple interface, on phones and computers alike.
            ? const SimpleShell()
            : app.desktopLayoutFor(box.maxWidth)
            ? const DesktopShell()
            : const HomeShell(),
      ),
    );
  }
}

/// Where the server's errors on the live link appear (3.10, G42.17b).
final serverErrorMessenger = GlobalKey<ScaffoldMessengerState>();

/// Shows the server's own error on the live link once, as the page does (`lastError`).
class _ServerErrors extends StatefulWidget {
  const _ServerErrors({required this.live, required this.child});

  final LiveModel live;
  final Widget child;

  @override
  State<_ServerErrors> createState() => _ServerErrorsState();
}

class _ServerErrorsState extends State<_ServerErrors> {
  @override
  void initState() {
    super.initState();
    widget.live.serverError.addListener(_show);
  }

  @override
  void dispose() {
    widget.live.serverError.removeListener(_show);
    super.dispose();
  }

  void _show() {
    final text = widget.live.serverError.value;
    if (text == null) return;
    widget.live.serverError.value = null;
    serverErrorMessenger.currentState?.showSnackBar(
      SnackBar(key: const Key('server-error'), content: Text(text)),
    );
  }

  @override
  Widget build(BuildContext context) => widget.child;
}

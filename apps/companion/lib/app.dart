import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'app_state.dart';
import 'brand.dart';
import 'app_update/update_window.dart';
import 'desktop/desktop_shell.dart';
import 'l10n/app_localizations.dart';
import 'mascot/mascot_source.dart';
import 'screens/home_shell.dart';
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
        debugShowCheckedModeBanner: false,
        theme: buildTheme(Brightness.light),
        darkTheme: buildTheme(Brightness.dark),
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
        builder: (context, child) => MascotScope(
          source: controller.mascots,
          reduceMotion: controller.reduceMotion,
          child: child!,
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
        builder: (context, box) =>
            app.desktopLayoutFor(box.maxWidth) ? const DesktopShell() : const HomeShell(),
      ),
    );
  }
}

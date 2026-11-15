import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'app_state.dart';
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
        title: 'RGCompanion',
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
        home: const HomeShell(),
      ),
    ),
  );
}

// You: the app's settings (theme, language, motion) and the RedGiant it is connected to. The
// discovery, the fingerprint and the advanced interface come with G40.7 and G40.11.
import 'package:flutter/material.dart';

import '../app_state.dart';
import '../l10n/app_localizations.dart';
import '../theme/colors.dart';
import '../ui/common.dart';

class YouScreen extends StatelessWidget {
  const YouScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    final l = AppLocalizations.of(context);
    final c = RgColors.of(context);
    Widget section(String title) => Padding(
      padding: const EdgeInsets.fromLTRB(16, 18, 16, 8),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w700,
          color: c.dim,
          letterSpacing: .3,
        ),
      ),
    );
    return ListView(
      children: [
        ScreenHeader(title: l.tabYou),
        section(l.sectionAppearance),
        _Row(
          label: l.themeLabel,
          child: SegmentedButton<ThemeMode>(
            key: const Key('theme-choice'),
            showSelectedIcon: false,
            segments: [
              ButtonSegment(value: ThemeMode.system, label: Text(l.themeSystem)),
              ButtonSegment(value: ThemeMode.light, label: Text(l.themeLight)),
              ButtonSegment(value: ThemeMode.dark, label: Text(l.themeDark)),
            ],
            selected: {app.themeMode},
            onSelectionChanged: (s) => app.setThemeMode(s.first),
          ),
        ),
        _Row(
          label: l.languageLabel,
          child: SegmentedButton<String>(
            key: const Key('language-choice'),
            showSelectedIcon: false,
            segments: [
              ButtonSegment(value: '', label: Text(l.languageSystem)),
              const ButtonSegment(value: 'it', label: Text('Italiano')),
              const ButtonSegment(value: 'en', label: Text('English')),
            ],
            selected: {app.locale?.languageCode ?? ''},
            onSelectionChanged: (s) => app.setLocale(s.first.isEmpty ? null : Locale(s.first)),
          ),
        ),
        MergeSemantics(
          child: ListTile(
            title: Text(l.reduceMotion),
            subtitle: Text(l.reduceMotionHint),
            trailing: Switch(
              key: const Key('reduce-motion'),
              value: app.reduceMotion,
              onChanged: app.setReduceMotion,
            ),
            onTap: () => app.setReduceMotion(!app.reduceMotion),
          ),
        ),
        section(l.sectionServer),
        const ServerCard(),
        const SizedBox(height: 24),
      ],
    );
  }
}

class _Row extends StatelessWidget {
  const _Row({required this.label, required this.child});

  final String label;
  final Widget child;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
        const SizedBox(height: 6),
        child,
      ],
    ),
  );
}

/// Pairing with a RedGiant by its address and the password (the token is all the app keeps).
class ServerCard extends StatefulWidget {
  const ServerCard({super.key});

  @override
  State<ServerCard> createState() => _ServerCardState();
}

class _ServerCardState extends State<ServerCard> {
  final _address = TextEditingController();
  final _password = TextEditingController();
  final _code = TextEditingController();

  @override
  void dispose() {
    _address.dispose();
    _password.dispose();
    _code.dispose();
    super.dispose();
  }

  String _error(AppLocalizations l, AppController app) => switch (app.error) {
    ConnectError.unreachable => l.errUnreachable,
    ConnectError.wrong => l.errWrong,
    ConnectError.codeNeeded => l.errCodeNeeded,
    ConnectError.tooMany => l.errTooMany,
    ConnectError.noPassword => l.errNoPassword,
    ConnectError.tooOld => l.errServerTooOld,
    ConnectError.tooNew => l.errServerTooNew,
    _ => l.errGeneric(app.errorMessage ?? ''),
  };

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    final l = AppLocalizations.of(context);
    final c = RgColors.of(context);
    if (app.connected) {
      return ListTile(
        title: Text(l.connectedTo(app.hello!.machine)),
        subtitle: Text(app.client!.base.toString()),
        trailing: TextButton(onPressed: app.disconnect, child: Text(l.disconnect)),
      );
    }
    final needsCode = app.error == ConnectError.codeNeeded || (app.hello?.access.code ?? false);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: AutofillGroup(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              key: const Key('server-address'),
              controller: _address,
              keyboardType: TextInputType.url,
              autocorrect: false,
              decoration: InputDecoration(
                labelText: l.serverAddress,
                hintText: l.serverAddressHint,
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              key: const Key('server-password'),
              controller: _password,
              obscureText: true,
              autofillHints: const [AutofillHints.password],
              decoration: InputDecoration(labelText: l.serverPassword),
            ),
            if (needsCode) ...[
              const SizedBox(height: 8),
              TextField(
                key: const Key('server-code'),
                controller: _code,
                keyboardType: TextInputType.number,
                autofillHints: const [AutofillHints.oneTimeCode],
                decoration: InputDecoration(labelText: l.serverCode),
              ),
            ],
            if (app.error != null) ...[
              const SizedBox(height: 8),
              Text(_error(l, app), style: TextStyle(color: c.err)),
            ],
            const SizedBox(height: 12),
            FilledButton(
              key: const Key('server-connect'),
              onPressed: app.connecting
                  ? null
                  : () async {
                      final ok = await app.connect(_address.text, _password.text, code: _code.text);
                      if (ok) _password.clear();
                    },
              child: Text(app.connecting ? l.connecting : l.connect),
            ),
          ],
        ),
      ),
    );
  }
}

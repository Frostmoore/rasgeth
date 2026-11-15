// You: the app's settings (theme, language, motion; kept between starts) and the RedGiants it
// knows (G40.7): home, work…, each with its pinned key; the ones found on the network
// (`_redgiant._tcp`) and an address typed by hand. The advanced interface comes with G40.11.
import 'dart:async';

import 'package:flutter/material.dart';

import '../api/discovery.dart';
import '../api/servers.dart';
import '../api/transport.dart';
import '../app_state.dart';
import '../l10n/app_localizations.dart';
import '../theme/colors.dart';
import '../ui/common.dart';
import '../ui/dialogs.dart';
import '../ui/icons.dart';

class YouScreen extends StatelessWidget {
  const YouScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    final l = AppLocalizations.of(context);
    return ListView(
      key: const Key('you-list'),
      children: [
        ScreenHeader(title: l.tabYou),
        _Section(l.sectionServer),
        const ServersList(),
        const AddServer(),
        _Section(l.sectionAppearance),
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
        const SizedBox(height: 24),
      ],
    );
  }
}

class _Section extends StatelessWidget {
  const _Section(this.title);

  final String title;

  @override
  Widget build(BuildContext context) {
    final c = RgColors.of(context);
    return Semantics(
      header: true,
      child: Padding(
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
      ),
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

/// How a saved RedGiant is reached, in words.
String reachWord(AppLocalizations l, SavedServer s) =>
    switch (transportFor(s.base, hasCa: s.caPem != null)) {
      TransportKind.pinnedHttps => l.reachPinned,
      TransportKind.publicHttps => l.reachPublic,
      TransportKind.loopback => l.reachLoopback,
      TransportKind.channel => l.reachChannel,
    };

/// The RedGiants the app knows; a tap switches to one.
class ServersList extends StatelessWidget {
  const ServersList({super.key});

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    final l = AppLocalizations.of(context);
    final c = RgColors.of(context);
    if (app.servers.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        child: Text(l.noServers, style: TextStyle(color: c.dim)),
      );
    }
    return Column(
      children: [
        for (final s in app.servers) _ServerTile(server: s, current: app.server?.id == s.id),
      ],
    );
  }
}

class _ServerTile extends StatelessWidget {
  const _ServerTile({required this.server, required this.current});

  final SavedServer server;
  final bool current;

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    final l = AppLocalizations.of(context);
    final c = RgColors.of(context);
    final s = server;
    final on = current && app.connected;
    return Container(
      key: Key('server-${s.id}'),
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      decoration: BoxDecoration(
        color: c.panel,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: current ? c.accentDim : c.line),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ListTile(
            leading: RgIcon(RgIcons.server, color: on ? c.ok : c.dim),
            title: Text(s.label, style: const TextStyle(fontWeight: FontWeight.w700)),
            subtitle: Text('${s.address}\n${reachWord(l, s)}'),
            isThreeLine: true,
            trailing: current
                ? Text(
                    on ? l.statusConnected : l.statusUnreachable,
                    style: TextStyle(color: on ? c.ok : c.dim),
                  )
                : TextButton(
                    key: Key('use-${s.id}'),
                    onPressed: () => app.useServer(s),
                    child: Text(l.useServer),
                  ),
          ),
          if (s.fingerprint != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 6),
              child: Row(
                children: [
                  RgIcon(RgIcons.lock, size: 14, color: c.dim),
                  const SizedBox(width: 6),
                  Expanded(
                    child: SelectableText(
                      l.pinnedKey(s.fingerprint!),
                      style: TextStyle(fontFamily: 'monospace', fontSize: 11.5, color: c.dim),
                    ),
                  ),
                ],
              ),
            ),
          Padding(
            padding: const EdgeInsets.fromLTRB(8, 0, 8, 6),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton.icon(
                  key: Key('rename-${s.id}'),
                  onPressed: () async {
                    final t = await askText(
                      context,
                      title: l.renameServer,
                      initial: s.label,
                      yes: l.save,
                    );
                    if (t != null) await app.renameServer(s, t);
                  },
                  icon: RgIcon(RgIcons.edit, size: 16, color: c.dim),
                  label: Text(l.rename),
                ),
                if (current)
                  TextButton.icon(
                    key: const Key('server-forget'),
                    onPressed: () async {
                      final ok = await askConfirm(
                        context,
                        title: l.forgetServer,
                        body: l.forgetServerBody(s.label),
                        yes: l.disconnect,
                      );
                      if (ok) await app.disconnect();
                    },
                    icon: RgIcon(RgIcons.trash, size: 16, color: c.err),
                    label: Text(l.disconnect, style: TextStyle(color: c.err)),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Adding a RedGiant: one found on the network, or an address; then the password once.
class AddServer extends StatefulWidget {
  const AddServer({super.key});

  @override
  State<AddServer> createState() => _AddServerState();
}

class _AddServerState extends State<AddServer> {
  final _address = TextEditingController();
  final _password = TextEditingController();
  final _code = TextEditingController();
  List<FoundServer> _found = const [];
  FoundServer? _picked;
  StreamSubscription<List<FoundServer>>? _sub;

  @override
  void initState() {
    super.initState();
    final d = AppScope.read(context).discovery;
    _sub = d?.watch().listen((f) {
      if (mounted) setState(() => _found = f);
    });
  }

  @override
  void dispose() {
    unawaited(_sub?.cancel());
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
    ConnectError.keyChanged => l.errKeyChanged(app.seenFingerprint ?? '-'),
    ConnectError.certificate => l.errCertificate,
    ConnectError.busy => l.errBusy,
    ConnectError.signInAgain => l.errSignInAgain,
    _ => l.errGeneric(app.errorMessage ?? ''),
  };

  Future<void> _connect(AppController app) async {
    final p = _picked;
    final ok = p != null
        ? await app.connectFound(p, _password.text, code: _code.text)
        : await app.connect(
            _address.text.isEmpty ? (app.server?.address ?? '') : _address.text,
            _password.text,
            code: _code.text,
          );
    if (ok) {
      _password.clear();
      _code.clear();
      _address.clear();
      setState(() => _picked = null);
    }
  }

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    final l = AppLocalizations.of(context);
    final c = RgColors.of(context);
    final needsCode = app.error == ConnectError.codeNeeded || (app.hello?.access.code ?? false);
    final known = {for (final s in app.servers) s.setupAddress};
    final found = _found.where((f) => !known.contains(f.base.toString())).toList();
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      child: AutofillGroup(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              app.servers.isEmpty || app.error == ConnectError.signInAgain
                  ? l.addServerFirst
                  : l.addServer,
              style: TextStyle(fontWeight: FontWeight.w600, color: c.text),
            ),
            const SizedBox(height: 6),
            if (found.isNotEmpty) ...[
              Text(l.foundOnNetwork, style: TextStyle(color: c.dim, fontSize: 13)),
              const SizedBox(height: 4),
              Wrap(
                spacing: 8,
                runSpacing: 6,
                children: [
                  for (final f in found)
                    ChoiceChip(
                      key: Key('found-${f.host}'),
                      showCheckmark: false,
                      avatar: RgIcon(RgIcons.server, size: 16, color: c.dim),
                      label: Text('${f.machine} (${f.host})'),
                      selected: _picked == f,
                      onSelected: (on) => setState(() => _picked = on ? f : null),
                    ),
                ],
              ),
              const SizedBox(height: 8),
            ],
            if (_picked == null)
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
              onSubmitted: (_) => _connect(app),
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
              Text(
                _error(l, app),
                key: const Key('server-error'),
                style: TextStyle(color: app.error == ConnectError.keyChanged ? c.critical : c.err),
              ),
            ],
            const SizedBox(height: 12),
            FilledButton(
              key: const Key('server-connect'),
              onPressed: app.connecting ? null : () => _connect(app),
              child: Text(app.connecting ? l.connecting : l.connect),
            ),
            const SizedBox(height: 6),
            Text(l.pairingNote, style: TextStyle(color: c.dim, fontSize: 12.5)),
          ],
        ),
      ),
    );
  }
}

// You: the app's settings (theme, language, motion; kept between starts) and the RedGiants it
// knows (G40.7): home, work…, each with its pinned key; the ones found on the network
// (`_redgiant._tcp`) and an address typed by hand; the advanced interface (G40.11).
import 'dart:async';

import 'package:flutter/material.dart';

import '../api/discovery.dart';
import '../api/names.dart';
import '../api/servers.dart';
import '../api/transport.dart';
import '../app_state.dart';
import '../l10n/app_localizations.dart';
import '../theme/colors.dart';
import '../ui/accent_picker.dart';
import '../ui/model_sheet.dart' show ChoiceRow;
import '../ui/common.dart';
import '../ui/dialogs.dart';
import '../ui/icons.dart';
import 'first_start_screen.dart';
import 'new_agent_screen.dart' show RgSwitch;
import 'notifications_screen.dart';
import 'server_settings_screen.dart';
import 'voice_screen.dart';
import '../setup/wizard/wizard_screen.dart' show openSetupWizard;

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
        if (app.connected)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: Material(
              color: RgColors.of(context).accentDim,
              borderRadius: BorderRadius.circular(14),
              child: ListTile(
                key: const Key('open-server-settings'),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                leading: RgIcon(RgIcons.settings, color: RgColors.of(context).accent),
                title: Text(
                  l.serverSettingsTitle(app.displayName),
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
                subtitle: Text(l.serverSettingsSub),
                trailing: RgIcon(RgIcons.chevronRight, color: RgColors.of(context).dim),
                onTap: () => Navigator.of(context)
                    .push(MaterialPageRoute<void>(builder: (_) => const ServerSettingsScreen())),
              ),
            ),
          ),
        if (app.connected) ...[
          _DeviceRow(
            key: const Key('open-notifications'),
            icon: RgIcons.bell,
            title: l.notificationsTitle,
            subtitle: l.notificationsSub,
            open: () => const NotificationsScreen(),
          ),
          _DeviceRow(
            key: const Key('open-voice'),
            icon: RgIcons.volume,
            title: l.voiceTitle,
            subtitle: l.voiceSub,
            open: () => const VoiceScreen(),
          ),
        ],
        // Keyed: the settings' row above them comes and goes without remaking their state.
        const ServersList(key: Key('servers-list')),
        const AddServer(key: Key('add-server')),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 0),
          child: OutlinedButton.icon(
            key: const Key('setup-new'),
            onPressed: () =>
                Navigator.of(context)
                    .push(MaterialPageRoute<void>(builder: (_) => const FirstStartScreen())),
            icon: RgIcon(RgIcons.wifi, size: 18, color: RgColors.of(context).accent),
            label: Text(l.setupNew),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 0),
          child: Text(
            l.setupNewHint,
            style: TextStyle(color: RgColors.of(context).dim, fontSize: 12.5),
          ),
        ),
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
        // 3.12: the simple interface or the full one, on this device.
        if (app.server != null)
          _Row(
            label: l.uiTitle,
            child: ChoiceRow(
              keyPrefix: 'you-ui',
              values: const ['simple', 'full'],
              selected: app.simpleUi ? 'simple' : 'full',
              label: (v) => v == 'simple' ? l.uiSimple : l.uiFull,
              onChanged: app.setUi,
            ),
          ),
        _Row(
          label: l.accentLabel,
          child: AccentPicker(key: const Key('accent-choice'), app: app),
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
        // G40.17: on computers, from which width the window is the control room.
        if (app.desktop)
          _Row(
            label: l.deskLayoutTitle,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SegmentedButton<int>(
                  key: const Key('desktop-layout'),
                  showSelectedIcon: false,
                  segments: [
                    ButtonSegment(value: 0, label: Text(l.deskLayoutAlways)),
                    ButtonSegment(value: kDesktopFrom, label: Text(l.deskLayoutFrom(kDesktopFrom))),
                    ButtonSegment(value: 1200, label: Text(l.deskLayoutFrom(1200))),
                    ButtonSegment(value: -1, label: Text(l.deskLayoutNever)),
                  ],
                  selected: {
                    if ([0, kDesktopFrom, 1200, -1].contains(app.desktopFrom))
                      app.desktopFrom
                    else
                      kDesktopFrom,
                  },
                  onSelectionChanged: (s) => app.setDesktopFrom(s.first),
                ),
                const SizedBox(height: 4),
                Text(
                  l.deskLayoutHint,
                  style: TextStyle(color: RgColors.of(context).dim, fontSize: 12.5),
                ),
              ],
            ),
          ),
        // G40.11: the advanced interface, kept for the RedGiant in use.
        if (app.connected) ...[
          _Section(l.sectionCoders),
          MergeSemantics(
            child: ListTile(
              key: const Key('advanced-toggle'),
              title: Row(
                children: [
                  Flexible(child: Text(l.advancedTitle)),
                  const SizedBox(width: 8),
                  _NewTag(l.advancedNew),
                ],
              ),
              subtitle: Text(l.advancedHint),
              trailing: RgSwitch(on: app.advanced),
              onTap: () => app.setAdvanced(!app.advanced),
            ),
          ),
          if (app.advanced)
            ListTile(
              key: const Key('advanced-terminals'),
              title: Text(l.advancedTerminals),
              subtitle: Text(l.advancedTerminalsHint),
              trailing: RgIcon(RgIcons.lock, size: 18, color: RgColors.of(context).dim),
            ),
          _Section(l.sectionMascots),
        ],
        MergeSemantics(
          child: ListTile(
            title: Text(l.reduceMotion),
            subtitle: Text(l.reduceMotionHint),
            trailing: RgSwitch(key: const Key('reduce-motion'), on: app.reduceMotion),
            onTap: () => app.setReduceMotion(!app.reduceMotion),
          ),
        ),
        const SizedBox(height: 24),
      ],
    );
  }
}

/// One of this device's settings for the RedGiant in use (Notifiche, Voce).
class _DeviceRow extends StatelessWidget {
  const _DeviceRow({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.open,
  });

  final RgIcons icon;
  final String title;
  final String subtitle;
  final Widget Function() open;

  @override
  Widget build(BuildContext context) {
    final c = RgColors.of(context);
    return ListTile(
      leading: RgIcon(icon, color: c.accent),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
      subtitle: Text(subtitle),
      trailing: RgIcon(RgIcons.chevronRight, color: c.dim),
      onTap: () => Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => open())),
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
    // A RedGiant without a valid token stays here: paired again, never dropped (3.9.8).
    final pair = current && app.needsPairing;
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
            title: Text(
              current ? app.displayName : readableName(label: s.label),
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
            subtitle: Text('${s.address}\n${reachWord(l, s)}'),
            isThreeLine: true,
            trailing: current
                ? Text(
                    on
                        ? l.statusConnected
                        : pair
                        ? l.statusPairAgain
                        : l.statusUnreachable,
                    key: Key('server-status-${s.id}'),
                    style: TextStyle(color: on ? c.ok : (pair ? c.warnText : c.dim)),
                  )
                : TextButton(
                    key: Key('use-${s.id}'),
                    onPressed: () => app.useServer(s),
                    child: Text(l.useServer),
                  ),
          ),
          if (pair)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(l.pairAgainNote, style: TextStyle(color: c.text, fontSize: 13)),
                  const SizedBox(height: 8),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: FilledButton.icon(
                      key: Key('pair-again-${s.id}'),
                      onPressed: app.connecting ? null : () => askPairAgain(context, s),
                      icon: const RgIcon(RgIcons.lock, size: 16),
                      label: Text(l.pairAgain),
                    ),
                  ),
                ],
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
            child: Wrap(
              alignment: WrapAlignment.end,
              children: [
                TextButton.icon(
                  key: Key('rename-${s.id}'),
                  onPressed: () async {
                    final t = await askText(
                      context,
                      title: l.renameServer,
                      initial: current ? app.displayName : readableName(label: s.label),
                      yes: l.save,
                    );
                    if (t == null) return;
                    // The one in use is renamed on the server too (the page, the nodes).
                    current && app.connected
                        ? await app.renameRedGiant(t)
                        : await app.renameServer(s, t);
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

/// «Abbina di nuovo»: the password for [s] at its own address, the same entry kept.
Future<void> askPairAgain(BuildContext context, SavedServer s) async {
  final app = AppScope.read(context);
  final name = readableName(label: s.label);
  final password = await showRgWindow<String>(
    context: context,
    builder: (_) => _PairAgainDialog(name: name),
  );
  if (password == null || password.isEmpty) return;
  await app.pairAgain(s, password);
}

class _PairAgainDialog extends StatefulWidget {
  const _PairAgainDialog({required this.name});

  final String name;

  @override
  State<_PairAgainDialog> createState() => _PairAgainDialogState();
}

class _PairAgainDialogState extends State<_PairAgainDialog> {
  final _password = TextEditingController();

  @override
  void dispose() {
    _password.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return AlertDialog(
      title: Text(l.pairAgainTitle(widget.name)),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(l.pairAgainBody(widget.name)),
          const SizedBox(height: 12),
          TextField(
            key: const Key('pair-again-password'),
            controller: _password,
            obscureText: true,
            autofocus: true,
            autofillHints: const [AutofillHints.password],
            decoration: InputDecoration(labelText: l.serverPassword),
            onSubmitted: (v) => Navigator.pop(context, v),
          ),
        ],
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: Text(l.cancel)),
        FilledButton(
          key: const Key('pair-again-yes'),
          onPressed: () => Navigator.pop(context, _password.text),
          child: Text(l.pairAgain),
        ),
      ],
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
    ConnectError.keystore => l.errKeystore,
    _ => l.errGeneric(app.errorMessage ?? ''),
  };

  /// G42.17: a first start's setup code instead of a password (none chosen yet).
  bool _setupCode = false;

  Future<void> _connect(AppController app) async {
    final p = _picked;
    final address =
        p?.base.toString() ?? (_address.text.isEmpty ? (app.server?.address ?? '') : _address.text);
    final ok = _setupCode
        ? await app.connectWithSetupCode(address, _password.text)
        : p != null
        ? await app.connectFound(p, _password.text, code: _code.text)
        : await app.connect(
            _address.text.isEmpty ? (app.server?.address ?? '') : _address.text,
            _password.text,
            code: _code.text,
          );
    if (!mounted) return;
    // G42.17: in with the setup code, the wizard goes on (its password step cannot be skipped).
    if (ok && _setupCode) unawaited(openSetupWizard(context));
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
              autofillHints: const [AutofillHints.password],
              obscureText: !_setupCode,
              decoration: InputDecoration(labelText: _setupCode ? l.g7SetupCode : l.serverPassword),
              onSubmitted: (_) => _connect(app),
            ),
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton(
                key: const Key('server-setup-code'),
                onPressed: () => setState(() => _setupCode = !_setupCode),
                child: Text(_setupCode ? l.g7SetupCodeNo : l.g7SetupCodeYes),
              ),
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
              // 3.10.1: what the keystore said, for whoever looks into it (on Rig: DPAPI's
              // «Could not get the master key», 0x8009000B, gone after a restart).
              if (app.error == ConnectError.keystore && (app.errorMessage ?? '').isNotEmpty)
                ErrorDetails(app.errorMessage!),
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

/// «new» next to a setting just arrived.
class _NewTag extends StatelessWidget {
  const _NewTag(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    final c = RgColors.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 1),
      decoration: BoxDecoration(color: c.accentSoft, borderRadius: BorderRadius.circular(99)),
      child: Text(
        text,
        style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: c.accent),
      ),
    );
  }
}

/// A small «Dettagli» under an error, opening the technical words as they came (selectable).
class ErrorDetails extends StatefulWidget {
  const ErrorDetails(this.detail, {super.key});

  final String detail;

  @override
  State<ErrorDetails> createState() => _ErrorDetailsState();
}

class _ErrorDetailsState extends State<ErrorDetails> {
  bool _open = false;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final c = RgColors.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        InkWell(
          key: const Key('server-error-details'),
          borderRadius: BorderRadius.circular(6),
          onTap: () => setState(() => _open = !_open),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                RgIcon(_open ? RgIcons.chevronDown : RgIcons.chevronRight, size: 13, color: c.dim),
                const SizedBox(width: 4),
                Text(l.errKeystoreDetails, style: TextStyle(color: c.dim, fontSize: 12.5)),
              ],
            ),
          ),
        ),
        if (_open)
          SelectableText(
            widget.detail,
            key: const Key('server-error-detail'),
            style: TextStyle(color: c.dim, fontSize: 12, fontFamily: 'monospace', height: 1.4),
          ),
      ],
    );
  }
}

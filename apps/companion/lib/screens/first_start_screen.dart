// The first start from the app (G40.8), one step at a time, as the page's wizard shows it (a thin
// line at the top, one question per screen): the temporary network, the access, the home
// network, the wait while RedGiant moves there, then the languages, a way of thinking and the
// names. The logic is [FirstStartFlow]; this is only how it looks.
import '../ui/dialogs.dart';

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

import '../api/settings_types.dart';
import '../api/types.dart';
import '../app_state.dart';
import '../l10n/app_localizations.dart';
import '../setup/first_start.dart';
import '../setup/wifi.dart';
import '../theme/colors.dart';
import '../ui/icons.dart';

/// Opens [u] in the system's browser (Anthropic's and OpenAI's pages).
Future<bool> openExternal(Uri u) async {
  try {
    return await launchUrl(u, mode: LaunchMode.externalApplication);
  } on Object {
    return false;
  }
}

/// A helper's or the server's code, in words.
String homeErrorText(AppLocalizations l, String? code) => switch (code) {
  'connect_failed' => l.homeErrConnectFailed,
  'not_found' => l.homeErrNotFound,
  'bad_password' => l.homeErrBadPassword,
  'bad_ssid' => l.homeErrBadSsid,
  'busy' => l.homeErrBusy,
  'wifi_off' => l.homeErrWifiOff,
  'no_cable' => l.homeErrNoCable,
  _ => l.homeErrFailed,
};

/// The flow's error, in words.
String flowErrorText(AppLocalizations l, FirstStartFlow f) => switch (f.error) {
  FsError.notFound => l.fsErrNotFound,
  FsError.busy => l.errBusy,
  FsError.keyChanged => l.errKeyChanged(f.fingerprint ?? '-'),
  FsError.notHere => l.fsErrNotHere,
  FsError.wrongPassword => l.errWrong,
  FsError.tooMany => l.errTooMany,
  FsError.cancelled => l.fsErrCancelled,
  FsError.denied => l.fsErrDenied,
  FsError.joinFailed => f.code == 'no_name' ? l.fsErrNoName : l.fsErrJoinFailed,
  FsError.homeRefused || FsError.homeFailed => homeErrorText(l, f.code),
  FsError.other || null => l.errGeneric(f.detail ?? ''),
};

/// The steps the line at the top counts.
const _counted = [
  FsStep.intro,
  FsStep.access,
  FsStep.home,
  FsStep.homeWait,
  FsStep.language,
  FsStep.brain,
  FsStep.names,
  FsStep.done,
];

double progressOf(FsStep s) {
  final at = switch (s) {
    FsStep.manual || FsStep.joining || FsStep.connecting => FsStep.intro,
    FsStep.signIn => FsStep.access,
    FsStep.homeLost => FsStep.homeWait,
    FsStep.finishing => FsStep.names,
    _ => s,
  };
  return (_counted.indexOf(at) + 1) / _counted.length;
}

class FirstStartScreen extends StatefulWidget {
  const FirstStartScreen({super.key, this.flow, this.at});

  /// Tests: a flow made outside.
  final FirstStartFlow? flow;

  /// A new RedGiant found on the home network: its setup channel there.
  final Uri? at;

  @override
  State<FirstStartScreen> createState() => _FirstStartScreenState();
}

class _FirstStartScreenState extends State<FirstStartScreen> {
  late final FirstStartFlow flow;
  bool _own = false;

  @override
  void initState() {
    super.initState();
    final app = AppScope.read(context);
    if (widget.flow != null) {
      flow = widget.flow!;
    } else {
      _own = true;
      flow = FirstStartFlow(app, openUrl: openExternal)..watch(app.discovery);
    }
    final at = widget.at;
    if (at != null) {
      unawaited(flow.startAt(at));
    } else if (flow.step == FsStep.intro) {
      unawaited(flow.scan());
    }
  }

  @override
  void dispose() {
    if (_own) {
      unawaited(flow.cancel());
      flow.dispose();
    }
    super.dispose();
  }

  Future<void> _close() async {
    final l = AppLocalizations.of(context);
    final s = flow.step;
    if (s != FsStep.done && s != FsStep.intro && s != FsStep.manual) {
      final ok = await showRgWindow<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: Text(l.fsLeaveTitle),
          content: Text(l.fsLeaveBody),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context, false), child: Text(l.cancel)),
            FilledButton(
              key: const Key('fs-leave-yes'),
              onPressed: () => Navigator.pop(context, true),
              child: Text(l.fsLeave),
            ),
          ],
        ),
      );
      if (ok != true) return;
    }
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final c = RgColors.of(context);
    final l = AppLocalizations.of(context);
    return ListenableBuilder(
      listenable: flow,
      builder: (context, _) => PopScope(
        canPop: flow.step == FsStep.done || flow.step == FsStep.intro,
        onPopInvokedWithResult: (did, _) {
          if (!did) unawaited(_close());
        },
        child: Scaffold(
          body: SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                LinearProgressIndicator(
                  value: progressOf(flow.step),
                  minHeight: 3,
                  backgroundColor: c.line,
                  color: c.accent,
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(4, 4, 12, 0),
                  child: Row(
                    children: [
                      IconButton(
                        key: const Key('fs-close'),
                        tooltip: l.fsLeave,
                        onPressed: _close,
                        icon: RgIcon(RgIcons.x, color: c.dim),
                      ),
                      Expanded(
                        child: Text(
                          l.fsTitle,
                          style: TextStyle(color: c.dim, fontWeight: FontWeight.w600),
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 560),
                      child: KeyedSubtree(
                        key: Key('fs-step-${flow.step.name}'),
                        child: _body(context),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _body(BuildContext context) => switch (flow.step) {
    FsStep.intro => _Intro(flow),
    FsStep.manual => _Manual(flow),
    FsStep.joining => _Wait(
      text: AppLocalizations.of(context).fsJoining,
      sub: flow.app.mobile ? AppLocalizations.of(context).fsJoiningSheet : null,
    ),
    FsStep.connecting => _Wait(text: AppLocalizations.of(context).fsConnecting),
    FsStep.access => _Access(flow),
    FsStep.signIn => _SignIn(flow),
    FsStep.home => _Home(flow),
    FsStep.homeWait => _HomeWait(flow),
    FsStep.homeLost => _HomeLost(flow),
    FsStep.language => _Language(flow),
    FsStep.brain => _Brain(flow),
    FsStep.names => _Names(flow),
    FsStep.finishing => _Wait(text: AppLocalizations.of(context).fsFinishing),
    FsStep.done => _Done(flow),
  };
}

// ---- the pieces ----

class _Page extends StatelessWidget {
  const _Page({required this.title, this.lead, required this.items, this.actions = const []});

  final String title;
  final String? lead;
  final List<Widget> items;
  final List<Widget> actions;

  @override
  Widget build(BuildContext context) {
    final c = RgColors.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
            children: [
              Semantics(
                header: true,
                child: Text(
                  title,
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.w700, color: c.text),
                ),
              ),
              if (lead != null) ...[
                const SizedBox(height: 8),
                Text(lead!, style: TextStyle(color: c.dim, fontSize: 15, height: 1.35)),
              ],
              const SizedBox(height: 18),
              ...items,
            ],
          ),
        ),
        if (actions.isNotEmpty)
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                for (final (i, a) in actions.indexed) ...[if (i > 0) const SizedBox(height: 8), a],
              ],
            ),
          ),
      ],
    );
  }
}

class _ErrorLine extends StatelessWidget {
  const _ErrorLine(this.flow);

  final FirstStartFlow flow;

  @override
  Widget build(BuildContext context) {
    if (flow.error == null) return const SizedBox.shrink();
    final c = RgColors.of(context);
    final l = AppLocalizations.of(context);
    final critical = flow.error == FsError.keyChanged;
    return Container(
      key: const Key('fs-error'),
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: (critical ? c.critical : c.err).withValues(alpha: .08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: (critical ? c.critical : c.err).withValues(alpha: .35)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          RgIcon(RgIcons.alert, size: 18, color: critical ? c.critical : c.err),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              flowErrorText(l, flow),
              style: TextStyle(color: critical ? c.critical : c.err),
            ),
          ),
        ],
      ),
    );
  }
}

class _Wait extends StatelessWidget {
  const _Wait({required this.text, this.sub});

  final String text;
  final String? sub;

  @override
  Widget build(BuildContext context) {
    final c = RgColors.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 36,
              height: 36,
              child: CircularProgressIndicator(strokeWidth: 3, color: c.accent),
            ),
            const SizedBox(height: 18),
            Text(
              text,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600, color: c.text),
            ),
            if (sub != null) ...[
              const SizedBox(height: 8),
              Text(
                sub!,
                textAlign: TextAlign.center,
                style: TextStyle(color: c.dim),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// The temporary network's name and password, large, to copy.
class _NetworkCard extends StatelessWidget {
  const _NetworkCard({required this.ssid});

  final String ssid;

  @override
  Widget build(BuildContext context) {
    final c = RgColors.of(context);
    final l = AppLocalizations.of(context);
    Widget row(String k, String v, Key key) => Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          SizedBox(
            width: 92,
            child: Text(k, style: TextStyle(color: c.dim)),
          ),
          Expanded(
            child: SelectableText(
              v,
              key: key,
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: c.text),
            ),
          ),
          IconButton(
            tooltip: l.copy,
            onPressed: () => Clipboard.setData(ClipboardData(text: v)),
            icon: RgIcon(RgIcons.copy, size: 18, color: c.dim),
          ),
        ],
      ),
    );
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 8, 4, 8),
      decoration: BoxDecoration(
        color: c.panel,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: c.line),
      ),
      child: Column(
        children: [
          row(l.fsNetworkName, ssid, const Key('fs-ssid')),
          row(l.fsNetworkPassword, kSetupPassphrase, const Key('fs-passphrase')),
        ],
      ),
    );
  }
}

class _Intro extends StatefulWidget {
  const _Intro(this.flow);

  final FirstStartFlow flow;

  @override
  State<_Intro> createState() => _IntroState();
}

class _IntroState extends State<_Intro> {
  final _letters = TextEditingController();

  @override
  void dispose() {
    _letters.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final f = widget.flow;
    final l = AppLocalizations.of(context);
    final c = RgColors.of(context);
    final needs = f.wifi.automatic && f.wifi.needsName;
    return _Page(
      title: l.fsIntroTitle,
      lead: l.fsIntroLead,
      items: [
        _ErrorLine(f),
        if (needs) ...[
          if (f.seen.isNotEmpty) ...[
            Text(l.fsSeen, style: const TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(height: 6),
            Wrap(
              spacing: 8,
              runSpacing: 6,
              children: [
                for (final s in f.seen)
                  ChoiceChip(
                    key: Key('fs-seen-${s.ssid}'),
                    showCheckmark: false,
                    avatar: RgIcon(
                      RgIcons.wifi,
                      size: 16,
                      color: f.ssid == s.ssid ? Colors.white : c.dim,
                    ),
                    label: Text(s.ssid),
                    selected: f.ssid == s.ssid,
                    onSelected: (on) => f.chooseSsid(on ? s.ssid : null),
                  ),
              ],
            ),
            const SizedBox(height: 10),
          ] else ...[
            Text(l.fsNoScan, style: TextStyle(color: c.dim)),
            const SizedBox(height: 6),
            // Only when the system does not show the networks around.
            TextField(
              key: const Key('fs-letters'),
              controller: _letters,
              autocorrect: false,
              decoration: InputDecoration(
                labelText: l.fsLetters,
                prefixText: kSetupSsidPrefix,
                hintText: 'A1B2',
              ),
              onChanged: (v) => f.chooseSsid(setupSsidFrom(v)),
            ),
          ],
          const SizedBox(height: 6),
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton.icon(
              key: const Key('fs-scan'),
              onPressed: f.busy ? null : f.scan,
              icon: RgIcon(RgIcons.refresh, size: 16, color: c.accent),
              label: Text(l.fsScanAgain),
            ),
          ),
        ],
        const SizedBox(height: 8),
        _Hint(icon: RgIcons.shield, text: l.fsIntroSafe),
      ],
      actions: [
        if (f.wifi.automatic)
          FilledButton(
            key: const Key('fs-join'),
            onPressed: f.busy ? null : f.joinAutomatically,
            child: Text(l.fsJoin),
          ),
        OutlinedButton(
          key: const Key('fs-by-hand'),
          onPressed: f.busy ? null : () => f.joinTemporaryByHand(),
          child: Text(l.fsByHand),
        ),
      ],
    );
  }
}

class _Hint extends StatelessWidget {
  const _Hint({required this.icon, required this.text});

  final RgIcons icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    final c = RgColors.of(context);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 2),
          child: RgIcon(icon, size: 16, color: c.dim),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(text, style: TextStyle(color: c.dim, fontSize: 13.5)),
        ),
      ],
    );
  }
}

class _Manual extends StatelessWidget {
  const _Manual(this.flow);

  final FirstStartFlow flow;

  @override
  Widget build(BuildContext context) {
    final f = flow;
    final l = AppLocalizations.of(context);
    final where = switch (f.app.platform) {
      DevicePlatform.android => l.fsWhereAndroid,
      DevicePlatform.ios => l.fsWhereIos,
      DevicePlatform.macos => l.fsWhereMac,
      DevicePlatform.windows => l.fsWhereWindows,
      _ => l.fsWhereOther,
    };
    return _Page(
      title: l.fsManualTitle,
      lead: l.fsManualLead(f.ssid ?? kSetupSsidPattern, kSetupPassphrase),
      items: [
        _ErrorLine(f),
        _NetworkCard(ssid: f.ssid ?? kSetupSsidPattern),
        const SizedBox(height: 14),
        _Hint(icon: RgIcons.wifi, text: where),
        const SizedBox(height: 8),
        _Hint(icon: RgIcons.help, text: l.fsManualNoInternet),
      ],
      actions: [
        FilledButton(
          key: const Key('fs-joined'),
          onPressed: f.busy ? null : f.joinedByHand,
          child: Text(l.fsJoinedContinue),
        ),
      ],
    );
  }
}

String? _passwordProblem(AppLocalizations l, String a, String b) {
  if (a.isEmpty) return l.fsPasswordNeeded;
  if (a.length < 10 || RegExp(r'^(.)\1+$').hasMatch(a)) return l.fsPasswordWeak;
  if (a != b) return l.fsPasswordDiffer;
  return null;
}

class _Access extends StatefulWidget {
  const _Access(this.flow);

  final FirstStartFlow flow;

  @override
  State<_Access> createState() => _AccessState();
}

class _AccessState extends State<_Access> {
  final _a = TextEditingController();
  final _b = TextEditingController();
  String? _problem;

  @override
  void dispose() {
    _a.dispose();
    _b.dispose();
    super.dispose();
  }

  void _go() {
    final l = AppLocalizations.of(context);
    final p = _passwordProblem(l, _a.text, _b.text);
    setState(() => _problem = p);
    if (p == null) unawaited(widget.flow.createAccess(_a.text));
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final c = RgColors.of(context);
    final f = widget.flow;
    return _Page(
      title: l.fsAccessTitle,
      lead: l.fsAccessLead,
      items: [
        _ErrorLine(f),
        AutofillGroup(
          child: Column(
            children: [
              TextField(
                key: const Key('fs-password'),
                controller: _a,
                obscureText: true,
                autofillHints: const [AutofillHints.newPassword],
                decoration: InputDecoration(labelText: l.fsPassword),
              ),
              const SizedBox(height: 8),
              TextField(
                key: const Key('fs-password-again'),
                controller: _b,
                obscureText: true,
                autofillHints: const [AutofillHints.newPassword],
                decoration: InputDecoration(labelText: l.fsPasswordAgain),
                onSubmitted: (_) => _go(),
              ),
            ],
          ),
        ),
        if (_problem != null) ...[
          const SizedBox(height: 8),
          Text(
            _problem!,
            key: const Key('fs-password-problem'),
            style: TextStyle(color: c.err),
          ),
        ],
        const SizedBox(height: 12),
        _Hint(icon: RgIcons.lock, text: l.fsAccessSafe),
        if (f.fingerprint != null) ...[
          const SizedBox(height: 8),
          _Hint(icon: RgIcons.shield, text: l.pinnedKey(f.fingerprint!)),
        ],
      ],
      actions: [
        FilledButton(
          key: const Key('fs-access-go'),
          onPressed: f.busy ? null : _go,
          child: Text(f.busy ? l.connecting : l.fsAccessGo),
        ),
      ],
    );
  }
}

class _SignIn extends StatefulWidget {
  const _SignIn(this.flow);

  final FirstStartFlow flow;

  @override
  State<_SignIn> createState() => _SignInState();
}

class _SignInState extends State<_SignIn> {
  final _pw = TextEditingController();
  final _code = TextEditingController();

  @override
  void dispose() {
    _pw.dispose();
    _code.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final f = widget.flow;
    final needsCode = f.code == 'code_needed';
    void go() => unawaited(f.signIn(_pw.text, code: _code.text));
    return _Page(
      title: f.maintenance ? l.fsMaintenanceTitle : l.fsSignInTitle,
      lead: f.maintenance ? l.fsMaintenanceLead : l.fsSignInLead,
      items: [
        _ErrorLine(f),
        TextField(
          key: const Key('fs-signin-password'),
          controller: _pw,
          obscureText: true,
          autofillHints: const [AutofillHints.password],
          decoration: InputDecoration(labelText: l.serverPassword),
          onSubmitted: (_) => go(),
        ),
        if (needsCode) ...[
          const SizedBox(height: 8),
          TextField(
            key: const Key('fs-signin-code'),
            controller: _code,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(labelText: l.serverCode),
          ),
        ],
      ],
      actions: [
        FilledButton(
          key: const Key('fs-signin-go'),
          onPressed: f.busy ? null : go,
          child: Text(f.busy ? l.connecting : l.connect),
        ),
      ],
    );
  }
}

/// Four bars drawn for a network's signal.
class SignalBars extends StatelessWidget {
  const SignalBars(this.quality, {super.key});

  final int quality;

  @override
  Widget build(BuildContext context) {
    final c = RgColors.of(context);
    final on = quality >= 75 ? 4 : (quality >= 50 ? 3 : (quality >= 25 ? 2 : 1));
    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        for (var i = 0; i < 4; i++)
          Container(
            margin: const EdgeInsets.only(left: 2),
            width: 4,
            height: 5.0 + i * 3,
            decoration: BoxDecoration(
              color: i < on ? c.text : c.line,
              borderRadius: BorderRadius.circular(1),
            ),
          ),
      ],
    );
  }
}

class _Home extends StatefulWidget {
  const _Home(this.flow);

  final FirstStartFlow flow;

  @override
  State<_Home> createState() => _HomeState();
}

class _HomeState extends State<_Home> {
  HomeWifi? _pick;
  bool _hidden = false;
  final _name = TextEditingController();
  final _pw = TextEditingController();

  @override
  void dispose() {
    _name.dispose();
    _pw.dispose();
    super.dispose();
  }

  bool get _needsPassword => _hidden || (_pick != null && !_pick!.open);

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final c = RgColors.of(context);
    final f = widget.flow;
    final nets = f.network?.networks ?? const <HomeWifi>[];
    final target = _hidden ? _name.text.trim() : (_pick?.ssid ?? '');
    return _Page(
      title: l.fsHomeTitle,
      lead: l.fsHomeLead,
      items: [
        _ErrorLine(f),
        if (nets.isEmpty)
          Text(l.fsHomeNone, style: TextStyle(color: c.dim))
        else
          for (final n in nets)
            Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Material(
                color: _pick?.ssid == n.ssid && !_hidden ? c.accentDim : c.panel,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(color: _pick?.ssid == n.ssid && !_hidden ? c.accent : c.line),
                ),
                child: ListTile(
                  key: Key('fs-net-${n.ssid}'),
                  enabled: n.usable && !f.busy,
                  leading: RgIcon(n.open ? RgIcons.wifi : RgIcons.lock, size: 18, color: c.dim),
                  title: Text(n.ssid, style: const TextStyle(fontWeight: FontWeight.w600)),
                  subtitle: n.usable ? null : Text(l.fsHomeUnusable),
                  trailing: SignalBars(n.quality),
                  onTap: () => setState(() {
                    _pick = n;
                    _hidden = false;
                    _pw.clear();
                  }),
                ),
              ),
            ),
        Align(
          alignment: Alignment.centerLeft,
          child: TextButton(
            key: const Key('fs-hidden'),
            onPressed: () => setState(() {
              _hidden = true;
              _pick = null;
            }),
            child: Text(l.fsHomeHidden),
          ),
        ),
        if (_hidden)
          TextField(
            key: const Key('fs-hidden-name'),
            controller: _name,
            maxLength: 32,
            autocorrect: false,
            decoration: InputDecoration(labelText: l.fsHomeHiddenName),
            onChanged: (_) => setState(() {}),
          ),
        if (_needsPassword) ...[
          const SizedBox(height: 4),
          TextField(
            key: const Key('fs-home-password'),
            controller: _pw,
            obscureText: true,
            maxLength: 63,
            decoration: InputDecoration(labelText: l.fsHomePassword(target.isEmpty ? '…' : target)),
          ),
        ],
        const SizedBox(height: 8),
        _Hint(icon: RgIcons.lock, text: l.fsHomeSafe),
      ],
      actions: [
        if (_pick != null || _hidden)
          FilledButton(
            key: const Key('fs-home-join'),
            onPressed: f.busy || target.isEmpty
                ? null
                : () => f.chooseWifi(target, _needsPassword ? _pw.text : '', hidden: _hidden),
            child: Text(l.fsHomeJoin(target.isEmpty ? '…' : target)),
          ),
        OutlinedButton.icon(
          key: const Key('fs-cable'),
          onPressed: f.busy ? null : f.chooseCable,
          icon: RgIcon(RgIcons.server, size: 18, color: c.accent),
          label: Text(l.fsHomeCable),
        ),
      ],
    );
  }
}

class _HomeWait extends StatelessWidget {
  const _HomeWait(this.flow);

  final FirstStartFlow flow;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return _Wait(
      text: flow.homeSsid == null ? l.fsHomeWaitCable : l.fsHomeWaitWifi(flow.homeSsid!),
      sub: l.fsHomeWaitSub,
    );
  }
}

class _HomeLost extends StatelessWidget {
  const _HomeLost(this.flow);

  final FirstStartFlow flow;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return _Page(
      title: l.fsLostTitle,
      lead: l.fsLostLead(flow.ssid ?? kSetupSsidPattern),
      items: [_ErrorLine(flow)],
      actions: [
        FilledButton(
          key: const Key('fs-look-again'),
          onPressed: flow.lookAgain,
          child: Text(l.fsLookAgain),
        ),
        OutlinedButton(
          key: const Key('fs-lost-by-hand'),
          onPressed: flow.joinTemporaryByHand,
          child: Text(l.fsByHand),
        ),
      ],
    );
  }
}

/// The agents' languages the app offers (the page has the full list in Settings).
const _agentLanguages = [
  ('it', 'Italiano'),
  ('en', 'English'),
  ('es', 'Español'),
  ('fr', 'Français'),
  ('de', 'Deutsch'),
  ('pt', 'Português'),
];

class _Language extends StatefulWidget {
  const _Language(this.flow);

  final FirstStartFlow flow;

  @override
  State<_Language> createState() => _LanguageState();
}

class _LanguageState extends State<_Language> {
  String? _agents;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final f = widget.flow;
    final app = AppScope.of(context);
    final ui = Localizations.localeOf(context).languageCode == 'it' ? 'it' : 'en';
    final agents = _agents ?? ui;
    return _Page(
      title: l.fsLanguageTitle,
      lead: l.fsLanguageLead,
      items: [
        _ErrorLine(f),
        Text(l.fsLanguageUi, style: const TextStyle(fontWeight: FontWeight.w600)),
        const SizedBox(height: 6),
        SegmentedButton<String>(
          key: const Key('fs-ui-language'),
          showSelectedIcon: false,
          segments: const [
            ButtonSegment(value: 'it', label: Text('Italiano')),
            ButtonSegment(value: 'en', label: Text('English')),
          ],
          selected: {ui},
          onSelectionChanged: (s) => app.setLocale(Locale(s.first)),
        ),
        const SizedBox(height: 18),
        Text(l.fsLanguageAgents, style: const TextStyle(fontWeight: FontWeight.w600)),
        const SizedBox(height: 6),
        Wrap(
          spacing: 8,
          runSpacing: 6,
          children: [
            for (final (id, name) in _agentLanguages)
              ChoiceChip(
                key: Key('fs-agents-$id'),
                showCheckmark: false,
                label: Text(name),
                selected: agents == id,
                onSelected: (_) => setState(() => _agents = id),
              ),
          ],
        ),
      ],
      actions: [
        FilledButton(
          key: const Key('fs-language-go'),
          onPressed: f.busy ? null : () => f.saveLanguages(ui, agents),
          child: Text(l.fsNext),
        ),
      ],
    );
  }
}

enum _Way { claude, chatgpt, key }

class _Brain extends StatefulWidget {
  const _Brain(this.flow);

  final FirstStartFlow flow;

  @override
  State<_Brain> createState() => _BrainState();
}

class _BrainState extends State<_Brain> {
  _Way? _open;
  bool _ack = false;
  String _provider = kKeyProviders.first.id;
  final _key = TextEditingController();
  final _code = TextEditingController();
  String? _saved;

  @override
  void dispose() {
    _key.dispose();
    _code.dispose();
    super.dispose();
  }

  Widget _tile(_Way w, RgIcons icon, String title, String text, bool on) {
    final c = RgColors.of(context);
    final open = _open == w;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: open ? c.accentDim : c.panel,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: BorderSide(color: open || on ? c.accent : c.line),
        ),
        child: ListTile(
          key: Key('fs-way-${w.name}'),
          leading: RgIcon(icon, color: on ? c.ok : c.accent),
          title: Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
          subtitle: Text(text),
          trailing: on
              ? RgIcon(RgIcons.check, color: c.ok)
              : RgIcon(open ? RgIcons.chevronDown : RgIcons.chevronRight, color: c.dim),
          onTap: () => setState(() => _open = open ? null : w),
        ),
      ),
    );
  }

  Widget _terms(AppLocalizations l) => MergeSemantics(
    child: SwitchListTile(
      key: const Key('fs-terms'),
      contentPadding: EdgeInsets.zero,
      value: _ack,
      onChanged: (v) => setState(() => _ack = v),
      title: Text(l.fsTerms),
    ),
  );

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final c = RgColors.of(context);
    final f = widget.flow;
    final s = f.summary;
    final p = kKeyProviders.firstWhere((x) => x.id == _provider);
    return _Page(
      title: l.fsBrainTitle,
      lead: l.fsBrainLead,
      items: [
        _ErrorLine(f),
        _tile(_Way.claude, RgIcons.zap, l.fsClaude, l.fsClaudeText, s?.claude ?? false),
        if (_open == _Way.claude && !(s?.claude ?? false)) ...[
          _terms(l),
          FilledButton.tonal(
            key: const Key('fs-claude-open'),
            onPressed: !_ack || f.busy ? null : f.claudeOpen,
            child: Text(l.fsClaudeOpen),
          ),
          if (f.claudePage != null) ...[
            const SizedBox(height: 8),
            TextField(
              key: const Key('fs-claude-code'),
              controller: _code,
              decoration: InputDecoration(labelText: l.fsClaudeCode),
            ),
            const SizedBox(height: 6),
            FilledButton(
              key: const Key('fs-claude-go'),
              onPressed: f.busy ? null : () => f.claudeFinish(_code.text),
              child: Text(l.connect),
            ),
          ],
          const SizedBox(height: 12),
        ],
        _tile(_Way.chatgpt, RgIcons.chat, l.fsChatgpt, l.fsChatgptText, s?.chatgpt ?? false),
        if (_open == _Way.chatgpt && !(s?.chatgpt ?? false)) ...[
          _terms(l),
          if (f.chatgpt == null)
            FilledButton.tonal(
              key: const Key('fs-chatgpt-open'),
              onPressed: !_ack || f.busy ? null : f.chatgptOpen,
              child: Text(l.fsChatgptOpen),
            )
          else ...[
            Text(l.fsChatgptCode, style: TextStyle(color: c.dim)),
            const SizedBox(height: 4),
            SelectableText(
              f.chatgpt!.code,
              key: const Key('fs-chatgpt-code'),
              style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w800, letterSpacing: 2),
            ),
            TextButton(
              onPressed: () => openExternal(Uri.parse(f.chatgpt!.url)),
              child: Text(l.fsChatgptOpenAgain),
            ),
          ],
          const SizedBox(height: 12),
        ],
        _tile(_Way.key, RgIcons.lock, l.fsKey, l.fsKeyText, s?.keys.isNotEmpty ?? false),
        if (_open == _Way.key) ...[
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              for (final x in kKeyProviders)
                ChoiceChip(
                  key: Key('fs-provider-${x.id}'),
                  showCheckmark: false,
                  label: Text(x.name),
                  selected: _provider == x.id,
                  avatar: (s?.keys.contains(x.id) ?? false)
                      ? RgIcon(RgIcons.check, size: 14, color: c.ok)
                      : null,
                  onSelected: (_) => setState(() => _provider = x.id),
                ),
            ],
          ),
          const SizedBox(height: 8),
          TextField(
            key: const Key('fs-key'),
            controller: _key,
            obscureText: true,
            autocorrect: false,
            decoration: InputDecoration(labelText: l.fsKeyOf(p.name), hintText: p.example),
          ),
          const SizedBox(height: 6),
          FilledButton.tonal(
            key: const Key('fs-key-save'),
            onPressed: f.busy
                ? null
                : () async {
                    final ok = await f.saveKey(_provider, _key.text);
                    if (ok && mounted) {
                      _key.clear();
                      setState(() => _saved = p.name);
                    }
                  },
            child: Text(f.busy ? l.connecting : l.save),
          ),
          if (_saved != null)
            Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Text(l.fsKeySaved(_saved!), style: TextStyle(color: c.ok)),
            ),
        ],
        const SizedBox(height: 6),
        _Hint(icon: RgIcons.help, text: l.fsBrainLater),
      ],
      actions: [
        FilledButton(
          key: const Key('fs-brain-go'),
          onPressed: f.busy ? null : f.brainNext,
          child: Text((s?.hasBrain ?? false) ? l.fsNext : l.fsLater),
        ),
      ],
    );
  }
}

class _Names extends StatefulWidget {
  const _Names(this.flow);

  final FirstStartFlow flow;

  @override
  State<_Names> createState() => _NamesState();
}

class _NamesState extends State<_Names> {
  late final _god = TextEditingController(text: widget.flow.summary?.godName ?? 'God');
  late final _demi = TextEditingController(text: widget.flow.summary?.demigodName ?? 'Demi-God');

  @override
  void dispose() {
    _god.dispose();
    _demi.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final f = widget.flow;
    final lang = Localizations.localeOf(context).languageCode == 'it' ? 'it' : 'en';
    return _Page(
      title: l.fsNamesTitle,
      lead: l.fsNamesLead,
      items: [
        _ErrorLine(f),
        TextField(
          key: const Key('fs-god'),
          controller: _god,
          maxLength: 40,
          decoration: InputDecoration(labelText: l.fsGodName, helperText: l.fsGodHelp),
        ),
        const SizedBox(height: 8),
        TextField(
          key: const Key('fs-demigod'),
          controller: _demi,
          maxLength: 40,
          decoration: InputDecoration(labelText: l.fsDemigodName, helperText: l.fsDemigodHelp),
        ),
      ],
      actions: [
        FilledButton(
          key: const Key('fs-names-go'),
          onPressed: f.busy ? null : () => f.saveNames(_god.text, _demi.text, language: lang),
          child: Text(l.fsFinish),
        ),
      ],
    );
  }
}

class _Done extends StatelessWidget {
  const _Done(this.flow);

  final FirstStartFlow flow;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final c = RgColors.of(context);
    return _Page(
      title: l.fsDoneTitle,
      lead: flow.maintenance ? l.fsDoneMaintenance : l.fsDoneLead,
      items: [
        Center(child: RgIcon(RgIcons.check, size: 56, color: c.ok)),
        const SizedBox(height: 12),
        _Hint(icon: RgIcons.tool, text: l.fsDoneMore),
      ],
      actions: [
        FilledButton(
          key: const Key('fs-done'),
          onPressed: () {
            flow.app.setTab(AppTab.team);
            Navigator.of(context).pop();
          },
          child: Text(l.fsDoneGo),
        ),
      ],
    );
  }
}

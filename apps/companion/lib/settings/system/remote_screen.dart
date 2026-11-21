// Settings › Access from outside home (G42.14), the page's RemoteSettings with RemoteAccess,
// OwnInfra and Pihole: the password that signs in from anywhere (twice, at least 10 letters; on a
// change the person chooses whether the others sign in again), the authenticator's code (its
// secret and QR, then six digits), «Sign out everywhere», then one of the three ways out
// (Tailscale, Cloudflare Tunnel, one's own domain with Caddy) with its guide and the job followed,
// the address once on with its QR and «Switch off»; «You already have your own infrastructure»
// (the blocks to copy filled with this machine's data, «Try a name», «Skip: I am reachable
// already»); Pi-hole explained before it starts, then its address and password. Same routes;
// passwords and tokens go to the server, never kept here.
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../../api/client.dart';
import '../../l10n/app_localizations.dart';
import '../../screens/first_start_screen.dart' show openExternal;
import '../../theme/colors.dart';
import '../../ui/dialogs.dart';
import '../../ui/icons.dart';
import '../../ui/qr.dart';
import '../../ui/settings_kit.dart';
import '../api/system_api.dart';
import 'infra_rules.dart';
import 'system_kit.dart';

Future<void> openRemoteSettings(BuildContext context) =>
    openSystemScreen(context, const RemoteSettingsScreen());

/// How a link outside opens (a test records it).
Future<bool> Function(Uri u) remoteOpenLink = openExternal;

class RemoteSettingsScreen extends StatefulWidget {
  const RemoteSettingsScreen({super.key});

  @override
  State<RemoteSettingsScreen> createState() => _RemoteSettingsScreenState();
}

class _RemoteSettingsScreenState extends State<RemoteSettingsScreen> {
  SystemSetup? _s;
  bool? _hasPassword;
  String? _error;

  @override
  void initState() {
    super.initState();
    unawaited(_load());
  }

  Future<void> _load() async {
    final c = sysClient(context);
    if (c == null) return;
    try {
      final s = await c.systemSetup();
      final m = await c.loginMethods();
      if (mounted) {
        setState(() {
          _s = s;
          _hasPassword = m.password;
          _error = null;
        });
      }
    } on ApiException catch (e) {
      if (mounted) setState(() => _error = sysError(AppLocalizations.of(context), e));
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final s = _s;
    return SettingsScaffold(
      title: l.syWzRemote,
      backKey: const Key('sy-remote-back'),
      backLabel: l.back,
      listKey: const Key('sy-remote-list'),
      children: [
        SysHead(eyebrow: l.syWzRemote, q: l.syStRemoteQ, lead: l.syRemotePurpose),
        if (_error != null) NoticeBanner(text: _error!, error: true),
        if (s == null && _error == null)
          const Padding(
            padding: EdgeInsets.all(24),
            child: Center(child: RgSpinner(size: 22)),
          ),
        if (s != null) ...[
          SysBox(children: [_PasswordPanel(onChange: _load)]),
          SysBox(
            children: [_Ways(s: s, hasPassword: _hasPassword ?? false, onChange: _load)],
          ),
          SysSub(l.syOiTitle, lead: l.syOiLead),
          SysBox(
            children: [_OwnInfra(s: s, onChange: _load)],
          ),
          SysSub(l.syPiholeTitle),
          SysBox(
            children: [_Pihole(s: s, onChange: _load)],
          ),
        ],
      ],
    );
  }
}

// ---- the password, the code, the sessions ----

class _PasswordPanel extends StatefulWidget {
  const _PasswordPanel({required this.onChange});

  final Future<void> Function() onChange;

  @override
  State<_PasswordPanel> createState() => _PasswordPanelState();
}

class _PasswordPanelState extends State<_PasswordPanel> {
  ({bool password, bool code})? _m;
  final _pw = TextEditingController();
  final _again = TextEditingController();
  final _code = TextEditingController();
  ({String secret, String url})? _secret;
  bool _changing = false;
  ({bool ok, String text})? _msg;

  @override
  void initState() {
    super.initState();
    unawaited(_load());
  }

  @override
  void dispose() {
    _pw.dispose();
    _again.dispose();
    _code.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final c = sysClient(context);
    if (c == null) return;
    try {
      final m = await c.loginMethods();
      if (mounted) setState(() => _m = m);
    } on ApiException {
      // The panel stays as it is.
    }
  }

  Future<bool> _run(Future<void> Function() f, String ok) async {
    final l = AppLocalizations.of(context);
    setState(() => _msg = null);
    try {
      await f();
      if (mounted) setState(() => _msg = (ok: true, text: ok));
      await _load();
      await widget.onChange();
      return true;
    } on ApiException catch (e) {
      if (mounted) setState(() => _msg = (ok: false, text: sysError(l, e)));
      return false;
    }
  }

  Future<void> _save() async {
    final l = AppLocalizations.of(context);
    final c = sysClient(context);
    final m = _m;
    if (c == null || m == null) return;
    var others = false;
    if (m.password) {
      others = await askConfirm(
        context,
        title: l.syPwSignOutOthersQ,
        body: l.syPwSignOutOthersText,
        yes: l.syPwSignOutOthersYes,
      );
      if (!mounted) return;
    }
    final pw = _pw.text;
    final done = await _run(
      () => c.setPassword(pw, signOutOthers: others),
      l.syRemotePasswordSaved,
    );
    if (done && mounted) {
      _pw.clear();
      _again.clear();
      setState(() => _changing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final c = RgColors.of(context);
    final m = _m;
    if (m == null) return const SizedBox.shrink();
    final client = sysClient(context);
    final mismatch = _again.text.isNotEmpty && _again.text != _pw.text;
    return Column(
      key: const Key('sy-password'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SysSub(l.syRemotePassword, lead: l.syRemotePasswordHint, inside: true),
        if (m.password && !_changing)
          Wrap(
            spacing: 8,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              SysPill(l.syRemotePasswordSet, tone: c.ok),
              TextButton(
                key: const Key('sy-password-change'),
                onPressed: () => setState(() => _changing = true),
                child: Text(l.syRemotePasswordChange),
              ),
            ],
          )
        else ...[
          SysField(
            label: l.syRemoteNewPassword,
            help: l.syRemotePasswordRule,
            controller: _pw,
            fieldKey: const Key('sy-password-new'),
            secret: true,
            onChanged: (_) => setState(() {}),
          ),
          SysField(
            label: l.syGitGiteaAgain,
            controller: _again,
            fieldKey: const Key('sy-password-again'),
            secret: true,
            error: mismatch ? l.syGitGiteaMismatch : null,
            onChanged: (_) => setState(() {}),
          ),
          SysActs(
            children: [
              FilledButton(
                key: const Key('sy-password-save'),
                onPressed: _pw.text.length < 10 || _pw.text != _again.text ? null : _save,
                child: Text(l.sySave),
              ),
            ],
          ),
        ],
        if (m.password && client != null) ...[
          SysSub(l.syRemoteCode, lead: l.syRemoteCodeHint, inside: true),
          if (m.code)
            Wrap(
              spacing: 8,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                SysPill(l.syRemoteCodeOn, tone: c.ok),
                TextButton(
                  key: const Key('sy-code-off'),
                  onPressed: () => _run(client.disableCode, l.syRemoteCodeOff),
                  child: Text(l.syBrainDisconnect),
                ),
              ],
            )
          else if (_secret != null)
            _secretPart(l, client)
          else
            SysActs(
              start: true,
              children: [
                OutlinedButton(
                  key: const Key('sy-code-start'),
                  onPressed: () async {
                    try {
                      final s = await client.newCodeSecret();
                      if (mounted) setState(() => _secret = s);
                    } on ApiException catch (e) {
                      if (mounted) setState(() => _msg = (ok: false, text: sysError(l, e)));
                    }
                  },
                  child: Text(l.syRemoteCodeStart),
                ),
              ],
            ),
          SysFold(
            label: l.syRemoteSessions,
            foldKey: const Key('sy-sessions'),
            children: [
              SysText(l.syRemoteSessionsHint),
              SysActs(
                start: true,
                children: [
                  OutlinedButton(
                    key: const Key('sy-sign-out-all'),
                    style: OutlinedButton.styleFrom(foregroundColor: c.err),
                    onPressed: () => _run(client.revokeSessions, l.syRemoteSignedOut),
                    child: Text(l.syRemoteSignOutAll),
                  ),
                ],
              ),
            ],
          ),
        ],
        if (_msg != null) SysSaid(text: _msg!.text, ok: _msg!.ok),
      ],
    );
  }

  Widget _secretPart(AppLocalizations l, RedGiantClient client) {
    final s = _secret!;
    final steps = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SysText(l.syRemoteCodeScan, dim: false),
        CopyBlock(text: s.secret),
        SysField(
          label: l.syLoginCode,
          controller: _code,
          fieldKey: const Key('sy-code-digits'),
          hint: '123456',
          onChanged: (_) => setState(() {}),
        ),
        SysActs(
          children: [
            FilledButton(
              key: const Key('sy-code-confirm'),
              onPressed: _code.text.trim().length < 6
                  ? null
                  : () async {
                      final ok = await _run(
                        () => client.enableCode(s.secret, _code.text.trim()),
                        l.syRemoteCodeOn,
                      );
                      if (ok && mounted) setState(() => _secret = null);
                    },
              child: Text(l.syRemoteCodeConfirm),
            ),
          ],
        ),
      ],
    );
    return _WithQr(qr: s.url, label: l.syRemoteCodeQr, child: steps);
  }
}

/// The words beside a QR on a computer, the QR under them on a phone (the page's `tg-pair`).
class _WithQr extends StatelessWidget {
  const _WithQr({required this.qr, required this.label, required this.child});

  final String qr;
  final String label;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final c = RgColors.of(context);
    final code = Column(
      children: [
        QrCode(key: const Key('sy-qr'), text: qr, label: label),
        const SizedBox(height: 4),
        SizedBox(
          width: 168,
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(color: c.dim, fontSize: 12),
          ),
        ),
      ],
    );
    return LayoutBuilder(
      builder: (context, box) => box.maxWidth >= 520
          ? Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(child: child),
                const SizedBox(width: 16),
                code,
              ],
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                child,
                const SizedBox(height: 10),
                Center(child: code),
              ],
            ),
    );
  }
}

// ---- the ways out ----

class _Ways extends StatefulWidget {
  const _Ways({required this.s, required this.hasPassword, required this.onChange});

  final SystemSetup s;
  final bool hasPassword;
  final Future<void> Function() onChange;

  @override
  State<_Ways> createState() => _WaysState();
}

class _WaysState extends State<_Ways> {
  late String _way = '${widget.s.remote?['way'] ?? 'tailscale'}';
  String? _jobId;
  bool _running = false;
  String? _signIn;
  String? _error;
  final _token = TextEditingController();
  final _host = TextEditingController();

  @override
  void dispose() {
    _token.dispose();
    _host.dispose();
    super.dispose();
  }

  Future<void> _start(Map<String, Object?> req) async {
    final l = AppLocalizations.of(context);
    final c = sysClient(context);
    if (c == null) return;
    setState(() => _error = null);
    try {
      final j = await c.startRemote(req);
      if (mounted) {
        setState(() {
          _jobId = j.id;
          _running = true;
          _signIn = null;
        });
      }
    } on ApiException catch (e) {
      if (mounted) setState(() => _error = sysError(l, e));
    }
  }

  Widget _link(String label, String url, {Key? key}) => Padding(
    padding: const EdgeInsets.only(top: 6),
    child: Align(
      alignment: Alignment.centerLeft,
      child: OutlinedButton.icon(
        key: key,
        onPressed: () => unawaited(remoteOpenLink(Uri.parse(url))),
        icon: RgIcon(RgIcons.external, size: 14, color: RgColors.of(context).text),
        label: Text(label),
      ),
    ),
  );

  Widget _guide(AppLocalizations l) {
    final c = RgColors.of(context);
    switch (_way) {
      case 'tailscale':
        return SysSteps(
          steps: [
            (l.syTsStep1, [_link(l.syTsSignUp, 'https://login.tailscale.com/start')]),
            (l.syTsStep2, [_link(l.syTsDns, 'https://login.tailscale.com/admin/dns')]),
            (
              l.syTsStep3,
              [
                Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: FilledButton(
                      key: const Key('sy-remote-connect'),
                      onPressed: () => _start({'way': 'tailscale'}),
                      child: Text(l.syRemoteConnect),
                    ),
                  ),
                ),
              ],
            ),
            (l.syTsStep4, [_link(l.syTsApps, 'https://tailscale.com/download')]),
          ],
        );
      case 'cloudflare':
        return SysSteps(
          steps: [
            (
              l.syCfStep1,
              [_link(l.syCfBuy, 'https://dash.cloudflare.com/?to=/:account/domains/register')],
            ),
            (
              l.syCfStep2,
              [
                _link(
                  l.syCfTunnels,
                  'https://one.dash.cloudflare.com/?to=/:account/networks/tunnels',
                ),
              ],
            ),
            (l.syCfStep3, const []),
            (
              l.syCfStep4,
              [
                SysField(
                  label: l.syCfToken,
                  help: l.syCfTokenHelp,
                  controller: _token,
                  fieldKey: const Key('sy-cf-token'),
                  secret: true,
                  onChanged: (_) => setState(() {}),
                ),
                SysField(
                  label: l.syCfHost,
                  help: l.syCfHostHelp,
                  controller: _host,
                  fieldKey: const Key('sy-cf-host'),
                  hint: 'rasgeth.example.com',
                  onChanged: (_) => setState(() {}),
                ),
                SysActs(
                  children: [
                    FilledButton(
                      key: const Key('sy-remote-connect'),
                      onPressed: _token.text.trim().length < 40 || !_host.text.contains('.')
                          ? null
                          : () => _start({
                              'way': 'cloudflare',
                              'token': _token.text.trim(),
                              'hostname': _host.text.trim(),
                            }),
                      child: Text(l.syRemoteConnect),
                    ),
                  ],
                ),
              ],
            ),
            (l.syCfAccess, const []),
          ],
        );
      default:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SysNote(text: l.syCaddyWarning, icon: RgIcons.alert, tone: 'warn'),
            SysSteps(
              steps: [
                (l.syCaddyStep1, const []),
                (l.syCaddyStep2, const []),
                (
                  l.syCaddyDomain,
                  [
                    SysField(
                      label: l.syCaddyDomain,
                      help: l.syCaddyDomainHelp,
                      controller: _host,
                      fieldKey: const Key('sy-caddy-domain'),
                      hint: 'rasgeth.example.com',
                      onChanged: (_) => setState(() {}),
                    ),
                    SysActs(
                      children: [
                        FilledButton(
                          key: const Key('sy-remote-connect'),
                          onPressed: !_host.text.contains('.')
                              ? null
                              : () => _start({'way': 'caddy', 'domain': _host.text.trim()}),
                          child: Text(l.syRemoteConnect),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
            Text(l.syCaddyPihole, style: TextStyle(color: c.dim, fontSize: 12.5)),
          ],
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final c = RgColors.of(context);
    final active = widget.s.remote;
    final ways = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final (id, title, text, badge) in [
          ('tailscale', 'Tailscale', l.syRemoteTailscale, l.syLmRecommended),
          ('cloudflare', 'Cloudflare Tunnel', l.syRemoteCloudflare, null),
          ('caddy', l.syRemoteOwnDomain, l.syRemoteCaddy, null),
        ])
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: SysTile(
              key: Key('sy-way-$id'),
              on: _way == id,
              icon: switch (id) {
                'tailscale' => RgIcons.shield,
                'cloudflare' => RgIcons.cloud,
                _ => RgIcons.globe,
              },
              title: title,
              text: text,
              badge: badge,
              onTap: () => setState(() => _way = id),
            ),
          ),
        if (!_running) _guide(l),
      ],
    );
    return Column(
      key: const Key('sy-ways'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SysSub(l.syRemoteHow, inside: true),
        if (!widget.hasPassword)
          SysNote(text: l.syRemoteNeedsPassword, icon: RgIcons.lock, tone: 'warn'),
        if (active != null)
          _WithQr(
            qr: '${active['url'] ?? ''}',
            label: l.syTgQr,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SysPill(l.syRemoteOn, tone: c.ok),
                const SizedBox(height: 8),
                FilledButton.icon(
                  key: const Key('sy-remote-url'),
                  onPressed: () => unawaited(remoteOpenLink(Uri.parse('${active['url']}'))),
                  icon: const RgIcon(RgIcons.external, size: 14, color: Colors.white),
                  label: Text('${active['url']}'),
                ),
                TextButton(
                  key: const Key('sy-remote-off'),
                  onPressed: () async {
                    final cl = sysClient(context);
                    if (cl == null) return;
                    try {
                      await cl.stopRemote();
                    } on ApiException catch (e) {
                      if (mounted) setState(() => _error = sysError(l, e));
                    }
                    await widget.onChange();
                  },
                  child: Text(l.syRemoteOff),
                ),
              ],
            ),
          )
        else if (widget.hasPassword)
          widget.s.reachable != null
              ? SysFold(label: l.syRemoteWaysFolded, children: [ways])
              : ways,
        if (_running && _signIn != null) ...[
          SysNote(text: l.syTsSignIn, icon: RgIcons.lock, tone: 'warn'),
          _link(l.syTsOpenSignIn, _signIn!, key: const Key('sy-remote-signin')),
        ],
        if (_jobId != null)
          SysJob(
            id: _jobId!,
            onUpdate: (j, vars) {
              final u = vars['url'];
              if (j.running && u != null && u != _signIn) setState(() => _signIn = u);
            },
            onEnd: (state, _) {
              if (mounted) setState(() => _running = false);
              if (state == 'done') unawaited(widget.onChange());
            },
          ),
        if (_error != null) SysSaid(text: _error!),
      ],
    );
  }
}

// ---- one's own infrastructure ----

class _OwnInfra extends StatefulWidget {
  const _OwnInfra({required this.s, required this.onChange});

  final SystemSetup s;
  final Future<void> Function() onChange;

  @override
  State<_OwnInfra> createState() => _OwnInfraState();
}

class _OwnInfraState extends State<_OwnInfra> {
  Map<String, dynamic>? _net;
  bool _open = false;
  String _part = 'proxy';
  String _proxy = 'caddy';
  final _name = TextEditingController();
  final _address = TextEditingController();
  String? _check;
  String? _error;

  @override
  void initState() {
    super.initState();
    unawaited(_load());
  }

  @override
  void dispose() {
    _name.dispose();
    _address.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final c = sysClient(context);
    if (c == null) return;
    try {
      final n = await c.setupNet();
      if (!mounted) return;
      final reached = n['reachedAs'] is Map ? n['reachedAs'] as Map : null;
      final lan = n['lan'] is Map ? n['lan'] as Map : null;
      setState(() {
        _net = n;
        if (_name.text.isEmpty) _name.text = '${reached?['host'] ?? n['hostName'] ?? ''}';
        if (_address.text.isEmpty) _address.text = '${lan?['address'] ?? ''}';
      });
    } on ApiException {
      // Nothing found: the fields stay empty, with their placeholders.
    }
  }

  Future<void> _skip(bool on, String url) async {
    final l = AppLocalizations.of(context);
    final c = sysClient(context);
    if (c == null) return;
    setState(() => _error = null);
    try {
      await c.setReachable(on, on && _name.text.trim().isNotEmpty ? url : null);
      await widget.onChange();
    } on ApiException catch (e) {
      if (mounted) setState(() => _error = sysError(l, e));
    }
  }

  /// Whether the address answers as RedGiant (the page's `checkReach`): from the app, any
  /// answer of its health is read.
  Future<void> _reach(String url) async {
    setState(() => _check = 'busy');
    final c = sysClient(context);
    var said = 'no';
    try {
      final u = Uri.parse(url);
      if (c != null && u.host == c.base.host) {
        await c.getJson('/api/health');
        said = 'redgiant';
      } else {
        final ok = await probeHealth(u);
        said = ok ? 'answers' : 'no';
      }
    } on Object {
      said = 'no';
    }
    if (mounted) setState(() => _check = said);
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final c = RgColors.of(context);
    final net = _net;
    final reached = net?['reachedAs'] is Map ? net!['reachedAs'] as Map : null;
    final said = widget.s.reachable;
    final lan = net?['lan'] is Map ? net!['lan'] as Map : null;
    final d = infraData(
      _name.text,
      _address.text,
      lan?['port'] is num ? (lan!['port'] as num).toInt() : null,
    );
    final https = reached == null || reached['https'] == true;
    final url = said?['url'] is String ? said!['url'] as String : reachUrl(d.name, https: https);
    final ts = net?['tailscale'] is Map ? net!['tailscale'] as Map : const {};
    return Column(
      key: const Key('sy-own-infra'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (reached != null)
          SysNote(
            icon: RgIcons.check,
            tone: 'ok',
            text:
                '${sw(l, 'oiReachedAs', {'host': '${reached['host']}'})} ${reached['through'] == 'proxy' ? l.syOiReachedProxy : l.syOiReachedName}',
          ),
        if (said != null)
          Row(
            children: [
              Expanded(
                child: SysNote(
                  icon: RgIcons.shield,
                  tone: 'ok',
                  text: said['url'] is String
                      ? sw(l, 'oiSaidUrl', {'url': '${said['url']}'})
                      : l.syOiSaid,
                ),
              ),
              TextButton(
                key: const Key('sy-oi-undo'),
                onPressed: () => _skip(false, url),
                child: Text(l.syOiSaidUndo),
              ),
            ],
          ),
        InkWell(
          key: const Key('sy-oi-fold'),
          borderRadius: BorderRadius.circular(10),
          onTap: () => setState(() => _open = !_open),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Row(
              children: [
                RgIcon(RgIcons.server, size: 18, color: c.accent),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _open ? l.syOiClose : l.syOiOpen,
                    style: TextStyle(color: c.text, fontWeight: FontWeight.w700),
                  ),
                ),
                RgIcon(_open ? RgIcons.chevronDown : RgIcons.chevronRight, size: 18, color: c.dim),
              ],
            ),
          ),
        ),
        if (_open) ...[
          SysField(
            label: l.syOiName,
            help: l.syOiNameHelp,
            controller: _name,
            fieldKey: const Key('sy-oi-name'),
            hint: placeholderName,
            onChanged: (_) => setState(() {}),
          ),
          SysField(
            label: l.syOiAddress,
            help: sw(l, 'oiAddressHelp', {'port': '${d.port}'}),
            controller: _address,
            fieldKey: const Key('sy-oi-address'),
            hint: placeholderAddress,
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: 6),
          SysSeg<String>(
            keyPrefix: 'sy-oi-part',
            value: _part,
            onChanged: (v) => setState(() => _part = v),
            options: [
              ('proxy', l.syOiPartProxy),
              ('vpn', l.syOiPartVpn),
              ('dns', l.syOiPartDns),
              ('home', l.syOiPartHome),
            ],
          ),
          if (_part == 'proxy') ...[
            SysText(l.syOiProxyLead),
            SysSeg<String>(
              keyPrefix: 'sy-oi-proxy',
              value: _proxy,
              onChanged: (v) => setState(() => _proxy = v),
              options: const [
                ('caddy', 'Caddy'),
                ('traefik', 'Traefik'),
                ('npm', 'Nginx Proxy Manager'),
              ],
            ),
            if (_proxy == 'caddy') ...[
              CopyBlock(label: l.syOiCaddy, text: caddyBlock(d)),
              CopyBlock(
                label: sw(l, 'oiCaddyWildcard', {'domain': parentDomain(d.name)}),
                text: caddyWildcardBlock(d),
              ),
              SysText(l.syOiCaddyReload),
            ],
            if (_proxy == 'traefik') ...[
              CopyBlock(label: l.syOiTraefik, text: traefikBlock(d)),
              SysText(l.syOiTraefikNote),
            ],
            if (_proxy == 'npm')
              SysSteps(
                steps: [
                  (sw(l, 'oiNpm1', {'name': d.name}), const []),
                  (sw(l, 'oiNpm2', {'address': d.address, 'port': '${d.port}'}), const []),
                  (l.syOiNpm3, const []),
                  (l.syOiNpm4, const []),
                ],
              ),
            SysNote(text: l.syOiWs),
            SysSub(l.syOiAuthTitle, inside: true),
            SysText(l.syOiAuthWhy, dim: false),
            SysText(l.syOiAuthIf),
            if (_proxy == 'caddy')
              CopyBlock(label: l.syOiAuthCaddy, text: caddyForwardAuthBypass(d)),
          ],
          if (_part == 'vpn') ...[
            SysSub(l.syOiTsHere, inside: true),
            SysText(
              ts['state'] == 'running'
                  ? sw(l, 'oiTsRunning', {'name': '${ts['name'] ?? ts['ip'] ?? ''}'})
                  : l.syOiTsHereLead,
            ),
            CopyBlock(label: l.syOiTsServe, text: tailscaleServe(d)),
            SysSub(l.syOiTsSubnet, inside: true),
            SysText(sw(l, 'oiTsSubnetLead', {'subnet': subnetOf(d.address)})),
            CopyBlock(text: tailscaleSubnet(d)),
            SysText(sw(l, 'oiTsSubnetThen', {'address': d.address, 'port': '${d.port}'})),
            SysSub(l.syOiOtherVpn, inside: true),
            SysText(sw(l, 'oiOtherVpnLead', {'subnet': subnetOf(d.address)})),
          ],
          if (_part == 'dns') ...[
            SysText(l.syOiDnsLead),
            SysSteps(
              numbered: false,
              steps: [
                (sw(l, 'oiDnsPihole', {'name': d.name, 'address': d.address}), const []),
                (
                  sw(l, 'oiDnsAdguard', {'domain': parentDomain(d.name), 'address': d.address}),
                  const [],
                ),
                (l.syOiDnsRouter, const []),
              ],
            ),
            CopyBlock(
              label: sw(l, 'oiDnsWildcard', {'domain': parentDomain(d.name)}),
              text: dnsmasqWildcard(d),
            ),
            SysText(l.syOiDnsTs),
          ],
          if (_part == 'home') _HomeServices(net: net),
          SysSub(l.syOiCheck, lead: sw(l, 'oiCheckLead'), inside: true),
          CopyBlock(text: healthCheck(url)),
          SysActs(
            start: true,
            children: [
              OutlinedButton.icon(
                key: const Key('sy-oi-check'),
                onPressed: _check == 'busy' ? null : () => _reach(url),
                icon: RgIcon(RgIcons.globe, size: 16, color: c.text),
                label: Text(sw(l, 'oiCheckGo', {'url': url})),
              ),
            ],
          ),
          if (_check != null && _check != 'busy')
            SysNote(
              tone: _check == 'no' ? 'warn' : 'ok',
              icon: _check == 'no' ? RgIcons.alert : RgIcons.check,
              text: switch (_check) {
                'redgiant' => l.syOiCheckRedgiant,
                'answers' => l.syOiCheckAnswers,
                _ => l.syOiCheckNo,
              },
            ),
          if (said == null) ...[
            SysActs(
              start: true,
              children: [
                FilledButton.icon(
                  key: const Key('sy-oi-skip'),
                  onPressed: () => _skip(true, url),
                  icon: const RgIcon(RgIcons.check, size: 16, color: Colors.white),
                  label: Text(l.syOiSkip),
                ),
              ],
            ),
            SysText(l.syOiSkipNote),
          ],
        ],
        if (_error != null) SysSaid(text: _error!),
      ],
    );
  }
}

/// Whether anything answers `<url>/api/health` (another origin: only that an answer came).
Future<bool> Function(Uri url) probeHealth = (url) async {
  try {
    await http
        .get(url.replace(path: '${url.path.replaceAll(RegExp(r'/$'), '')}/api/health'))
        .timeout(const Duration(seconds: 8));
    return true;
  } on Object {
    return false;
  }
};

class _HomeServices extends StatefulWidget {
  const _HomeServices({required this.net});

  final Map<String, dynamic>? net;

  @override
  State<_HomeServices> createState() => _HomeServicesState();
}

class _HomeServicesState extends State<_HomeServices> {
  final _name = TextEditingController();
  final _proxy = TextEditingController();
  Map<String, dynamic>? _probe;
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    _name.dispose();
    _proxy.dispose();
    super.dispose();
  }

  Future<void> _try() async {
    final l = AppLocalizations.of(context);
    final c = sysClient(context);
    if (c == null) return;
    setState(() {
      _error = null;
      _busy = true;
      _probe = null;
    });
    try {
      final p = await c.probeName(_name.text.trim());
      if (mounted) setState(() => _probe = p);
    } on ApiException catch (e) {
      if (mounted) setState(() => _error = sysError(l, e));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final c = RgColors.of(context);
    final h = homeService(_name.text, _proxy.text);
    final typed = _name.text.trim();
    final v = _probe == null ? null : probeVerdict(_probe!);
    final dns = widget.net?['localDns'];
    final hv = {'name': h.name, 'address': h.proxy};
    return Column(
      key: const Key('sy-oi-home'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            RgIcon(RgIcons.home, size: 18, color: c.accent),
            const SizedBox(width: 6),
            Expanded(child: SysSub(l.syOiHomeTitle, inside: true)),
          ],
        ),
        SysText(l.syOiHomeWhy, dim: false),
        SysText(l.syOiHomeWhich),
        if (dns is String) SysText(sw(l, 'oiHomeSeen', {'dns': dns})),
        CopyBlock(label: l.syOiHomeWhichCmd, text: whichDns),
        SysField(
          label: l.syOiService,
          help: l.syOiServiceHelp,
          controller: _name,
          fieldKey: const Key('sy-oi-service'),
          hint: placeholderService,
          onChanged: (_) => setState(() {}),
        ),
        SysField(
          label: l.syOiProxyAddr,
          help: l.syOiProxyAddrHelp,
          controller: _proxy,
          hint: placeholderProxy,
          onChanged: (_) => setState(() {}),
        ),
        SysText(l.syOiHomeWhat, dim: false),
        SysSteps(
          numbered: false,
          steps: [
            (sw(l, 'oiHomeRouter', hv), const []),
            (sw(l, 'oiHomePihole', hv), const []),
            (sw(l, 'oiHomeAdguard', hv), const []),
          ],
        ),
        CopyBlock(label: l.syOiHomeHosts, text: homeHostsLine(h)),
        CopyBlock(label: l.syOiHomeDnsmasq, text: homeDnsmasq(h)),
        SysNote(text: l.syOiHomeTs),
        SysText(l.syOiHomeV6),
        CopyBlock(label: l.syOiHomeLookup, text: homeLookup(h)),
        SysSub(l.syOiProbe, lead: sw(l, 'oiProbeLead', {'name': h.name}), inside: true),
        SysActs(
          start: true,
          children: [
            OutlinedButton.icon(
              key: const Key('sy-oi-probe'),
              onPressed: typed.isEmpty || _busy ? null : _try,
              icon: RgIcon(RgIcons.search, size: 16, color: c.text),
              label: Text(sw(l, 'oiProbeGo', {'name': typed.isEmpty ? h.name : typed})),
            ),
          ],
        ),
        if (v != null)
          SysNote(
            key: const Key('sy-oi-verdict'),
            tone: v.ok ? 'ok' : 'warn',
            icon: v.ok ? RgIcons.check : RgIcons.alert,
            text: sw(l, v.key, v.params),
          ),
        if (_error != null) SysSaid(text: _error!),
      ],
    );
  }
}

// ---- Pi-hole ----

final _ipv4 = RegExp(
  r'^(25[0-5]|2[0-4]\d|1\d\d|[1-9]?\d)(\.(25[0-5]|2[0-4]\d|1\d\d|[1-9]?\d)){3}$',
);
final _domain = RegExp(r'^(?=.{1,253}$)([a-z0-9-]{1,63}\.)+[a-z]{2,63}$', caseSensitive: false);

class _Pihole extends StatefulWidget {
  const _Pihole({required this.s, required this.onChange});

  final SystemSetup s;
  final Future<void> Function() onChange;

  @override
  State<_Pihole> createState() => _PiholeState();
}

class _PiholeState extends State<_Pihole> {
  final _ip = TextEditingController();
  late final _domainField = TextEditingController(text: _ownDomain());
  String? _jobId;
  bool _running = false;
  String? _password;
  String? _error;

  String _ownDomain() {
    final r = widget.s.remote;
    if (r?['way'] != 'caddy') return '';
    return Uri.tryParse('${r?['url'] ?? ''}')?.host ?? '';
  }

  @override
  void dispose() {
    _ip.dispose();
    _domainField.dispose();
    super.dispose();
  }

  Future<void> _run(Future<void> Function() f) async {
    final l = AppLocalizations.of(context);
    setState(() => _error = null);
    try {
      await f();
    } on ApiException catch (e) {
      if (mounted) setState(() => _error = sysError(l, e));
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final c = RgColors.of(context);
    final client = sysClient(context);
    final active = widget.s.pihole;
    final ip = _ip.text.trim();
    final dom = _domainField.text.trim();
    final ipOk = _ipv4.hasMatch(ip);
    final domainOk = dom.isEmpty || _domain.hasMatch(dom);
    if (client == null) return const SizedBox.shrink();
    return Column(
      key: const Key('sy-pihole'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (active != null) ...[
          SysNote(
            tone: 'ok',
            icon: RgIcons.check,
            text: sw(l, 'piholeOn', {'ip': '${active['lanIp']}'}),
          ),
          if (active['domain'] is String)
            SysText(
              sw(l, 'piholeAnswers', {'domain': '${active['domain']}', 'ip': '${active['lanIp']}'}),
            ),
          SysSteps(
            steps: [
              (sw(l, 'piholeNowRouter', {'ip': '${active['lanIp']}'}), const []),
              (
                l.syPiholeAdmin,
                [
                  Wrap(
                    spacing: 8,
                    runSpacing: 6,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      OutlinedButton.icon(
                        onPressed: () =>
                            unawaited(remoteOpenLink(Uri.parse('${active['adminUrl']}'))),
                        icon: RgIcon(RgIcons.external, size: 14, color: c.text),
                        label: Text(l.syPiholeOpenAdmin),
                      ),
                      if (_password != null)
                        SysMono(_password!)
                      else
                        TextButton(
                          key: const Key('sy-pihole-password'),
                          onPressed: () => _run(() async {
                            final p = await client.piholePassword();
                            if (mounted) setState(() => _password = p);
                          }),
                          child: Text(l.syPiholeShowPassword),
                        ),
                    ],
                  ),
                ],
              ),
            ],
          ),
          SysFold(
            label: l.syPiholeChanges,
            children: [
              SysSteps(
                steps: [
                  (l.syPiholeSecond, const []),
                  (l.syPiholeAllow, const []),
                  (l.syPiholeOff, const []),
                ],
              ),
            ],
          ),
          SysActs(
            start: true,
            children: [
              OutlinedButton(
                key: const Key('sy-pihole-stop'),
                style: OutlinedButton.styleFrom(foregroundColor: c.err),
                onPressed: () => _run(() async {
                  await client.stopPihole();
                  if (mounted) setState(() => _password = null);
                  await widget.onChange();
                }),
                child: Text(l.syPiholeStop),
              ),
            ],
          ),
        ] else ...[
          SysText(l.syPiholeWhat, dim: false),
          LayoutBuilder(
            builder: (context, box) {
              final need = Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  SysText(l.syPiholeNeedTitle, dim: false, strong: true),
                  SysText(l.syPiholeNeed),
                  SysText(l.syPiholeTest),
                ],
              );
              final noNeed = Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  SysText(l.syPiholeNoNeedTitle, dim: false, strong: true),
                  SysText(l.syPiholeNoNeed),
                ],
              );
              return box.maxWidth >= 520
                  ? Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(child: need),
                        const SizedBox(width: 16),
                        Expanded(child: noNeed),
                      ],
                    )
                  : Column(children: [need, noNeed]);
            },
          ),
          SysFold(
            label: l.syPiholeChanges,
            children: [
              SysSteps(
                steps: [
                  (l.syPiholeRouter, const []),
                  (l.syPiholeDevice, const []),
                  (l.syPiholeSecond, const []),
                  (l.syPiholeOff, const []),
                ],
              ),
            ],
          ),
          SysFold(
            label: l.syPiholeAds,
            children: [SysText(l.syPiholeAdsText), SysText(l.syPiholeAllow)],
          ),
          SysFold(label: l.syPiholePort, children: [SysText(l.syPiholePortText)]),
          if (!_running) ...[
            SysField(
              label: l.syPiholeIp,
              help: l.syPiholeIpHelp,
              controller: _ip,
              fieldKey: const Key('sy-pihole-ip'),
              hint: '192.168.1.50',
              error: ip.isNotEmpty && !ipOk ? l.syPiholeIpWrong : null,
              onChanged: (_) => setState(() {}),
            ),
            SysField(
              label: l.syPiholeDomain,
              help: l.syPiholeDomainHelp,
              controller: _domainField,
              hint: 'rasgeth.example.com',
              error: domainOk ? null : l.syPiholeDomainWrong,
              onChanged: (_) => setState(() {}),
            ),
            SysActs(
              children: [
                FilledButton(
                  key: const Key('sy-pihole-start'),
                  onPressed: !ipOk || !domainOk
                      ? null
                      : () => _run(() async {
                          final j = await client.startPihole(ip, dom.isEmpty ? null : dom);
                          if (mounted) {
                            setState(() {
                              _jobId = j.id;
                              _running = true;
                            });
                          }
                        }),
                  child: Text(l.syPiholeStart),
                ),
              ],
            ),
          ],
        ],
        if (_jobId != null && active == null)
          SysJob(
            id: _jobId!,
            showDone: false,
            onEnd: (state, _) {
              if (mounted) setState(() => _running = false);
              if (state == 'done') unawaited(widget.onChange());
            },
          ),
        if (_error != null) SysSaid(text: _error!),
      ],
    );
  }
}

// G42.14: RedGiant OS in Settings › System (the page's OsSystem.tsx): Wi-Fi (the networks in reach,
// join with a password, a hidden one, forget after a yes), HTTPS in the home network (on or off,
// the machine's certificate with its QR to download it, the steps per system, «This device trusts
// it» before http goes to https), the updates (RedGiant's own, applied and followed as Settings ›
// Updates does, and the system's security ones with the restart asked in plain words). Nothing is
// shown where the installation is not RedGiant OS.
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../../api/client.dart';
import '../../app_state.dart';
import '../../l10n/app_localizations.dart';
import '../../screens/update_screen.dart' show openUpdateScreen;
import '../../theme/colors.dart';
import '../../ui/dialogs.dart';
import '../../ui/icons.dart';
import '../../ui/qr.dart';
import '../api/system_api.dart';
import 'system_kit.dart';

/// The page's word for a refusal's code (`osErr_<code>`), else «it did not work».
String osError(AppLocalizations l, Object e) {
  final w = sw(l, 'osErr_${errorCode(e)}');
  return w.startsWith('osErr_') ? l.syOsErr_failed : w;
}

String _bars(AppLocalizations l, num signal) =>
    signal >= 70 ? l.syOsWifiStrong : (signal >= 40 ? l.syOsWifiGood : l.syOsWifiWeak);

/// «Network»: Wi-Fi and HTTPS with their heading; nothing at all where it is not RedGiant OS.
class OsNetworkSection extends StatefulWidget {
  const OsNetworkSection({super.key});

  @override
  State<OsNetworkSection> createState() => _OsNetworkSectionState();
}

class _OsNetworkSectionState extends State<OsNetworkSection> {
  Map<String, dynamic>? _w, _h;
  bool _got = false;

  @override
  void initState() {
    super.initState();
    unawaited(_load());
  }

  Future<void> _load() async {
    final c = sysClient(context);
    if (c == null) return;
    Map<String, dynamic>? w, h;
    try {
      w = await c.setupWifi();
    } on ApiException {
      w = null;
    }
    try {
      h = await c.setupHttps();
    } on ApiException {
      h = null;
    }
    if (mounted) {
      setState(() {
        _w = w;
        _h = h;
        _got = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    if (!_got) return const SizedBox.shrink();
    final w = _w;
    final wifi =
        w != null &&
        (w['available'] == true || (w['available'] == false && w['why'] != 'no_helper'));
    final https = _h?['available'] == true;
    if (!wifi && !https) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SysSub(l.syOsNetSub, lead: l.syOsNetSubLead),
        if (wifi) WifiPanel(initial: w),
        if (https) HttpsPanel(initial: _h!),
      ],
    );
  }
}

/// Wi-Fi of the machine: the networks in reach, join, forget.
class WifiPanel extends StatefulWidget {
  const WifiPanel({super.key, required this.initial});

  final Map<String, dynamic> initial;

  @override
  State<WifiPanel> createState() => _WifiPanelState();
}

class _WifiPanelState extends State<WifiPanel> {
  late Map<String, dynamic> _w = widget.initial;
  bool _busy = false;
  Map<dynamic, dynamic>? _pick;
  bool _hidden = false;
  final _name = TextEditingController();
  final _password = TextEditingController();
  ({bool ok, String text})? _said;

  @override
  void dispose() {
    _name.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _scan() async {
    final c = sysClient(context);
    if (c == null) return;
    setState(() => _busy = true);
    try {
      final w = await c.setupWifiScan();
      if (mounted) setState(() => _w = w);
    } on ApiException catch (e) {
      if (mounted)
        setState(() => _said = (ok: false, text: osError(AppLocalizations.of(context), e)));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _join() async {
    final l = AppLocalizations.of(context);
    final c = sysClient(context);
    final ssid = _hidden ? _name.text.trim() : '${_pick?['ssid'] ?? ''}';
    if (c == null || ssid.isEmpty) return;
    setState(() {
      _busy = true;
      _said = null;
    });
    final pw = _password.text;
    // The password leaves the app's memory at once, whatever happened.
    _password.clear();
    try {
      final r = await c.setupWifiConnect(ssid, pw, _hidden);
      if (!mounted) return;
      setState(() {
        if (r['wifi'] is Map<String, dynamic>) _w = r['wifi'] as Map<String, dynamic>;
        _pick = null;
        _hidden = false;
        _name.clear();
        _said = (
          ok: true,
          text: sw(l, r['state'] == 'saved' ? 'osWifiSaved' : 'osWifiJoined', {'name': ssid}),
        );
      });
    } on ApiException catch (e) {
      if (mounted) setState(() => _said = (ok: false, text: osError(l, e)));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _forget(String ssid) async {
    final l = AppLocalizations.of(context);
    final yes = await askConfirm(
      context,
      title: sw(l, 'osWifiForgetQ', {'name': ssid}),
      body: l.syOsWifiForgetText,
      yes: l.syOsWifiForget,
    );
    if (!yes || !mounted) return;
    final c = sysClient(context);
    if (c == null) return;
    try {
      final w = await c.setupWifiForget(ssid);
      if (mounted) setState(() => _w = w);
    } on ApiException catch (e) {
      if (mounted) setState(() => _said = (ok: false, text: osError(l, e)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final c = RgColors.of(context);
    final w = _w;
    final networks = [
      for (final n in w['networks'] is List ? w['networks'] as List : const [])
        if (n is Map) n,
    ];
    final known = [for (final k in w['known'] is List ? w['known'] as List : const []) '$k'];
    final away = known.where((k) => !networks.any((n) => n['ssid'] == k)).toList();
    final needsPassword = _hidden || (_pick != null && _pick!['security'] != 'open');
    return SysBox(
      key: const Key('sy-wifi'),
      icon: RgIcons.wifi,
      title: l.syOsWifiTitle,
      q: l.syOsWifiQ,
      children: [
        if (w['available'] != true)
          SysText(sw(l, 'osWifiWhy_${w['why']}'))
        else ...[
          SysFacts([
            (
              l.syOsWifiNow,
              w['connected'] is String
                  ? sw(l, 'osWifiConnectedTo', {
                      'name': '${w['connected']}',
                      'ip': '${w['address'] ?? '…'}',
                    })
                  : l.syOsWifiNotConnected,
            ),
          ]),
          if (w['wired'] == true) SysNote(icon: RgIcons.check, text: l.syOsWifiWired),
          SysSub(l.syOsWifiInReach, inside: true),
          if (networks.isEmpty)
            SysText(l.syOsWifiNone)
          else
            for (final n in networks)
              Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Row(
                  children: [
                    Expanded(
                      child: SysTile(
                        key: Key('sy-wifi-${n['ssid']}'),
                        on: _pick?['ssid'] == n['ssid'],
                        icon: n['security'] == 'open' ? RgIcons.wifi : RgIcons.lock,
                        title: '${n['ssid']}',
                        text: [
                          _bars(l, n['signal'] is num ? n['signal'] as num : 0),
                          if (n['connected'] == true)
                            l.syOsWifiInUse
                          else if (n['known'] == true)
                            l.syOsWifiKnown
                          else if (n['security'] == '8021x')
                            l.syOsWifi8021x,
                        ].join(' · '),
                        onTap:
                            n['connected'] == true ||
                                n['security'] == '8021x' ||
                                n['security'] == 'wep'
                            ? null
                            : () => setState(() {
                                _pick = n;
                                _hidden = false;
                                _password.clear();
                                _said = null;
                              }),
                      ),
                    ),
                    if (n['known'] == true)
                      IconButton(
                        key: Key('sy-wifi-forget-${n['ssid']}'),
                        tooltip: l.syOsWifiForget,
                        onPressed: () => _forget('${n['ssid']}'),
                        icon: RgIcon(RgIcons.trash, size: 18, color: c.dim),
                      ),
                  ],
                ),
              ),
          if (away.isNotEmpty) SysText(sw(l, 'osWifiKnownAway', {'names': away.join(', ')})),
          if (_hidden)
            SysField(
              label: l.syOsWifiHiddenName,
              controller: _name,
              fieldKey: const Key('sy-wifi-hidden-name'),
              onChanged: (_) => setState(() {}),
            ),
          if (needsPassword)
            SysField(
              label: sw(l, 'osWifiPassword', {
                'name': _hidden ? (_name.text.isEmpty ? '…' : _name.text) : '${_pick?['ssid']}',
              }),
              help: l.syOsWifiPasswordHelp,
              controller: _password,
              fieldKey: const Key('sy-wifi-password'),
              secret: true,
              onChanged: (_) => setState(() {}),
            ),
          if (_said != null) SysSaid(text: _said!.text, ok: _said!.ok),
          SysActs(
            children: [
              OutlinedButton.icon(
                key: const Key('sy-wifi-scan'),
                onPressed: _busy ? null : _scan,
                icon: RgIcon(RgIcons.refresh, size: 16, color: c.text),
                label: Text(_busy ? l.syOsWifiLooking : l.syOsWifiScan),
              ),
              if (_pick == null && !_hidden)
                TextButton(
                  key: const Key('sy-wifi-hidden'),
                  onPressed: () => setState(() {
                    _hidden = true;
                    _said = null;
                  }),
                  child: Text(l.syOsWifiHidden),
                ),
              if (_pick != null || _hidden)
                FilledButton.icon(
                  key: const Key('sy-wifi-join'),
                  onPressed:
                      _busy ||
                          (_hidden && _name.text.trim().isEmpty) ||
                          (needsPassword && _password.text.length < 8)
                      ? null
                      : _join,
                  icon: const RgIcon(RgIcons.wifi, size: 16, color: Colors.white),
                  label: Text(_busy ? l.syOsWifiJoining : l.syOsWifiJoin),
                ),
            ],
          ),
        ],
      ],
    );
  }
}

/// HTTPS in the home network: the machine's certificate, how to trust it, then https only.
class HttpsPanel extends StatefulWidget {
  const HttpsPanel({super.key, required this.initial});

  final Map<String, dynamic> initial;

  @override
  State<HttpsPanel> createState() => _HttpsPanelState();
}

/// Whether this device trusts the machine's certificate (the page's `trustedHere`): https on the
/// same name answers through the system's own trust, as a browser would see it.
Future<bool> Function(RedGiantClient c) httpsTrustedHere = (c) async {
  if (c.base.scheme == 'https') return true;
  try {
    await http
        .get(Uri(scheme: 'https', host: c.base.host, path: '/api/health'))
        .timeout(const Duration(seconds: 8));
    return true;
  } on Object {
    return false;
  }
};

class _HttpsPanelState extends State<HttpsPanel> {
  late Map<String, dynamic> _h = widget.initial;
  late String _device = _guess();
  bool _busy = false;
  ({bool ok, String text})? _said;

  String _guess() => switch (Theme.of(context).platform) {
    TargetPlatform.iOS => 'iphone',
    TargetPlatform.android => 'android',
    TargetPlatform.macOS => 'mac',
    TargetPlatform.windows => 'windows',
    _ => 'linux',
  };

  Future<bool> _set(Map<String, Object?> b) async {
    final l = AppLocalizations.of(context);
    final c = sysClient(context);
    if (c == null) return false;
    setState(() => _busy = true);
    try {
      final h = await c.setSetupHttps(b);
      if (mounted) setState(() => _h = h);
      return true;
    } on ApiException catch (e) {
      if (mounted) setState(() => _said = (ok: false, text: osError(l, e)));
      return false;
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _check() async {
    final l = AppLocalizations.of(context);
    final c = sysClient(context);
    if (c == null) return;
    setState(() {
      _said = null;
      _busy = true;
    });
    final ok = await httpsTrustedHere(c);
    if (!mounted) return;
    setState(() => _busy = false);
    if (!ok) {
      setState(() => _said = (ok: false, text: l.syOsHttpsNotYet));
      return;
    }
    if (await _set({'redirect': true, 'trusted': true}) && mounted) {
      setState(() => _said = (ok: true, text: l.syOsHttpsNowOnly));
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final c = RgColors.of(context);
    final h = _h;
    final on = h['on'] == true;
    final redirect = h['redirect'] == true;
    final names = [for (final n in h['names'] is List ? h['names'] as List : const []) '$n'];
    final name = names.where((n) => n.endsWith('.local')).firstOrNull ?? 'rasgeth.local';
    final client = sysClient(context);
    final host = client?.base.host ?? name;
    final crt = 'http://$host/redgiant-ca.crt';
    return SysBox(
      key: const Key('sy-https'),
      icon: RgIcons.shield,
      title: l.syOsHttpsTitle,
      q: l.syOsHttpsQ,
      children: [
        if (h['inFront'] is String)
          SysNote(icon: RgIcons.check, text: sw(l, 'osHttpsInFront', {'name': '${h['inFront']}'})),
        SwitchLine(
          key: const Key('sy-https-on'),
          title: l.syOsHttpsLocal,
          help: on ? sw(l, 'osHttpsLocalOn', {'name': name}) : l.syOsHttpsLocalOff,
          on: on,
          onChanged: _busy
              ? null
              : (v) async {
                  if (!v && redirect) {
                    final yes = await askConfirm(
                      context,
                      title: l.syOsHttpsOffQ,
                      body: l.syOsHttpsOffText,
                      yes: l.syOsHttpsOffYes,
                    );
                    if (!yes) return;
                  }
                  await _set({'local': v});
                },
        ),
        if (on && h['ca'] != null) ...[
          SysFacts([
            (l.syOsHttpsAddress, SysMono('https://$name')),
            (l.syOsHttpsFingerprint, SysMono('${h['fingerprint'] ?? '…'}', size: 11.5)),
            if (h['until'] is String) (l.syOsHttpsUntil, '${h['until']}'),
          ]),
          SysSub(l.syOsHttpsTrustTitle, lead: l.syOsHttpsTrustLead, inside: true),
          Wrap(
            spacing: 16,
            runSpacing: 10,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              QrCode(key: const Key('sy-https-qr'), text: crt, label: l.syOsHttpsQr, size: 140),
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 360),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SysMono(crt),
                    const SizedBox(height: 6),
                    Text(l.syOsHttpsQrHelp, style: TextStyle(color: c.dim, fontSize: 12.5)),
                  ],
                ),
              ),
            ],
          ),
          SysSeg<String>(
            keyPrefix: 'sy-https-device',
            value: _device,
            onChanged: (v) => setState(() => _device = v),
            options: const [
              ('windows', 'Windows'),
              ('mac', 'macOS'),
              ('iphone', 'iPhone / iPad'),
              ('android', 'Android'),
              ('linux', 'Linux'),
            ],
          ),
          SysText(sw(l, 'osHttpsHow_$_device'), dim: false),
          SysText(l.syOsHttpsFirefox),
          if (redirect)
            SwitchLine(
              key: const Key('sy-https-redirect'),
              title: l.syOsHttpsRedirect,
              help: l.syOsHttpsRedirectOn,
              on: true,
              onChanged: (v) {
                if (!v) unawaited(_set({'redirect': false}));
              },
            )
          else if (h['inFront'] is! String)
            SysActs(
              children: [
                FilledButton.icon(
                  key: const Key('sy-https-check'),
                  onPressed: _busy ? null : _check,
                  icon: const RgIcon(RgIcons.lock, size: 16, color: Colors.white),
                  label: Text(l.syOsHttpsCheck),
                ),
              ],
            ),
        ],
        if (_said != null) SysSaid(text: _said!.text, ok: _said!.ok),
      ],
    );
  }
}

/// «Updates»: RedGiant's and the system's, with the restart; nothing where it is not RedGiant OS.
class OsUpdatesSection extends StatefulWidget {
  const OsUpdatesSection({super.key});

  @override
  State<OsUpdatesSection> createState() => _OsUpdatesSectionState();
}

class _OsUpdatesSectionState extends State<OsUpdatesSection> {
  Map<String, dynamic>? _u;
  bool _busy = false;
  ({bool ok, String text})? _said;

  @override
  void initState() {
    super.initState();
    unawaited(_load());
  }

  Future<void> _load({bool check = false}) async {
    final c = sysClient(context);
    if (c == null) return;
    try {
      final u = await c.setupOsUpdatesRaw(check: check);
      if (mounted) setState(() => _u = u);
    } on ApiException catch (e) {
      if (check && mounted) {
        setState(() => _said = (ok: false, text: osError(AppLocalizations.of(context), e)));
      }
    }
  }

  Future<void> _apply(String version) async {
    final l = AppLocalizations.of(context);
    final app = AppScope.read(context);
    final yes = await askConfirm(
      context,
      title: sw(l, 'osUpdApplyQ', {'version': version}),
      body: l.syOsUpdApplyText,
      yes: l.syOsUpdApplyYes,
    );
    if (!yes || !mounted) return;
    final up = _u?['update'] is Map ? _u!['update'] as Map : const {};
    unawaited(
      app.startUpdate(from: up['installed'] as String?, to: version.isEmpty ? null : version),
    );
    await openUpdateScreen(context);
    await _load();
  }

  Future<void> _restart() async {
    final l = AppLocalizations.of(context);
    final yes = await askConfirm(
      context,
      title: l.syOsRebootQ,
      body: l.syOsRebootText,
      yes: l.syOsRebootYes,
      danger: true,
    );
    if (!yes || !mounted) return;
    final c = sysClient(context);
    if (c == null) return;
    try {
      await c.setupReboot();
      if (mounted) setState(() => _said = (ok: true, text: l.syOsRebooting));
    } on ApiException catch (e) {
      if (mounted) setState(() => _said = (ok: false, text: osError(l, e)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final c = RgColors.of(context);
    final u = _u;
    if (u == null || u['available'] != true) return const SizedBox.shrink();
    final up = u['update'] is Map ? u['update'] as Map : null;
    final state = u['running'] == true ? 'applying' : '${up?['state'] ?? 'unknown'}';
    final sec = u['security'] is Map ? u['security'] as Map : null;
    final latest = '${up?['latest'] ?? ''}';
    final breaking = up?['gate'] == 'breaking';
    final pkgs = [
      for (final p in sec?['packages'] is List ? sec!['packages'] as List : const []) '$p',
    ];
    return Column(
      key: const Key('sy-os-updates'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SysSub(l.syOsUpdSub, lead: l.syOsUpdSubLead),
        SysBox(
          icon: RgIcons.download,
          title: l.syOsUpdTitle,
          q: l.syOsUpdQ,
          children: [
            SysFacts([
              (l.syOsUpdInstalled, '${up?['installed'] ?? '…'}'),
              (l.syOsUpdState, sw(l, 'osUpd_$state', {'version': latest})),
              if (up?['checkedAt'] is String)
                (l.syOsUpdChecked, sysWhen(up!['checkedAt'] as String)),
            ]),
            if (breaking) SysNote(tone: 'warn', icon: RgIcons.alert, text: l.syOsUpdBreaking),
            if (_said != null) SysSaid(text: _said!.text, ok: _said!.ok),
            SysActs(
              children: [
                OutlinedButton.icon(
                  key: const Key('sy-os-look'),
                  onPressed: _busy || state == 'applying'
                      ? null
                      : () async {
                          setState(() {
                            _busy = true;
                            _said = null;
                          });
                          await _load(check: true);
                          if (mounted) setState(() => _busy = false);
                        },
                  icon: RgIcon(RgIcons.refresh, size: 16, color: c.text),
                  label: Text(_busy ? l.syUpdLooking : l.syUpdLook),
                ),
                if (state == 'applying')
                  FilledButton.icon(
                    key: const Key('sy-os-follow'),
                    onPressed: () => openUpdateScreen(context),
                    icon: const RgIcon(RgIcons.download, size: 16, color: Colors.white),
                    label: Text(l.updFollow),
                  )
                else if (up?['state'] == 'available' && !breaking)
                  FilledButton.icon(
                    key: const Key('sy-os-apply'),
                    onPressed: () => _apply(latest),
                    icon: const RgIcon(RgIcons.download, size: 16, color: Colors.white),
                    label: Text(sw(l, 'osUpdApply', {'version': latest})),
                  ),
              ],
            ),
          ],
        ),
        if (sec != null)
          SysBox(
            key: const Key('sy-os-security'),
            icon: RgIcons.shield,
            title: l.syOsSecTitle,
            q: l.syOsSecQ,
            children: [
              SysFacts([
                (
                  l.syOsSecLast,
                  sec['lastRun'] is String
                      ? sw(l, sec['upgraded'] == null ? 'osSecLastAt' : 'osSecLastN', {
                          'when': sysWhen(sec['lastRun'] as String),
                          'n': '${sec['upgraded'] ?? 0}',
                        })
                      : l.syOsSecNever,
                ),
              ]),
              if (sec['rebootRequired'] == true) ...[
                SysNote(
                  tone: 'warn',
                  icon: RgIcons.restore,
                  text: [
                    l.syOsSecReboot,
                    if (pkgs.isNotEmpty) '(${pkgs.take(6).join(', ')})',
                  ].join(' '),
                ),
                SysActs(
                  children: [
                    FilledButton.icon(
                      key: const Key('sy-os-reboot'),
                      onPressed: _restart,
                      icon: const RgIcon(RgIcons.restore, size: 16, color: Colors.white),
                      label: Text(l.syOsRebootNow),
                    ),
                  ],
                ),
              ] else
                SysText(l.syOsSecNoReboot),
            ],
          ),
      ],
    );
  }
}

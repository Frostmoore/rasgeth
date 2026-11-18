// «Settings of <name>» (G40.8, the person's request): the settings of the RedGiant the app is
// connected to that are used most, made for the phone: its name, its state and updates («Update»
// opens the update's own screen, update_screen.dart), the devices connected (and signing
// one out), this device's notifications, the default model, the voice, the access from outside
// (to read, with its link); and «All settings», the page's Settings inside the app.
import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../api/client.dart';
import '../api/model_routes.dart';
import '../api/settings_types.dart';
import '../api/transport.dart';
import '../api/web_settings.dart';
import '../app_state.dart';
import '../l10n/app_localizations.dart';
import '../theme/colors.dart';
import '../settings/code_settings.dart';
import '../settings/projects_settings.dart';
import '../ui/dialogs.dart';
import '../ui/icons.dart';
import '../ui/words.dart';
import '../embed/embed_screen.dart';
import 'at_work_screen.dart';
import 'artifacts_screen.dart';
import 'first_start_screen.dart' show openExternal;
import 'full_settings_screen.dart';
import 'update_screen.dart';
import 'you_screen.dart' show reachWord;

/// «12 MB of 340 MB · 2.1 MB/s · 2 min left», as the page says a download.
String progressText(AppLocalizations l, Progress p) {
  String mb(double b) => (b / (1024 * 1024)).toStringAsFixed(b >= 100 * 1024 * 1024 ? 0 : 1);
  final parts = <String>[
    if (p.total > 0) l.updBytes(mb(p.done), mb(p.total)),
    if (p.bps > 0) l.updSpeed(mb(p.bps)),
    if (p.eta != null)
      p.eta! >= 60 ? l.updEtaMin('${(p.eta! / 60).ceil()}') : l.updEtaSec('${p.eta}'),
  ];
  return parts.join(' · ');
}

String updateStepText(AppLocalizations l, String step) => switch (step) {
  'check' => l.updStepCheck,
  'download' => l.updStepDownload,
  'files' => l.updStepFiles,
  'install' || 'installer' => l.updStepInstall,
  'restart' => l.updStepRestart,
  'wait' => l.updStepWait,
  'rollback' => l.updStepRollback,
  'scan' => l.updStepScan,
  'build' => l.updStepBuild,
  'failed' => l.updStepFailed,
  _ => step,
};

class ServerSettingsScreen extends StatefulWidget {
  const ServerSettingsScreen({super.key});

  @override
  State<ServerSettingsScreen> createState() => _ServerSettingsScreenState();
}

class _ServerSettingsScreenState extends State<ServerSettingsScreen> {
  UpdateStatus? _update;
  OsUpdates? _os;
  List<DeviceRow>? _devices;
  SetupSummary? _setup;
  List<ModelChoice>? _models;
  String? _error;
  String? _said;
  bool _looking = false;

  RedGiantClient? get _c => AppScope.read(context).client;

  @override
  void initState() {
    super.initState();
    unawaited(_load());
  }

  Future<T?> _try<T>(Future<T> Function() f) async {
    try {
      return await f();
    } on ApiException catch (e) {
      if (mounted) setState(() => _error = e.message);
      return null;
    }
  }

  Future<void> _load() async {
    final c = _c;
    if (c == null) return;
    final r = await Future.wait<Object?>([
      _try(c.updateStatus),
      _try<OsUpdates?>(() => c.osUpdates()),
      _try(c.devices),
      _try(c.setupSummary),
      _try(c.models),
    ]);
    if (!mounted) return;
    setState(() {
      _update = r[0] as UpdateStatus?;
      _os = r[1] as OsUpdates?;
      _devices = r[2] as List<DeviceRow>?;
      _setup = r[3] as SetupSummary?;
      _models = r[4] as List<ModelChoice>?;
    });
    _followIfApplying();
  }

  bool get _applying {
    final run = AppScope.read(context).updateRun;
    if (run != null && !run.finished) return true;
    return (_os?.updating ?? false) || (_update?.progress != null && _update?.phase != 'failed');
  }

  /// An update found running: the app follows it and its screen opens by itself.
  void _followIfApplying() {
    final app = AppScope.read(context);
    final run = app.updateRun;
    if (run != null && !run.finished) return;
    if (!_applying) return;
    app.followUpdate(_update, _os, open: false);
    unawaited(_openRun());
  }

  Future<void> _openRun() async {
    await openUpdateScreen(context);
    if (mounted) await _load();
  }

  Future<void> _look() async {
    final c = _c;
    if (c == null) return;
    setState(() {
      _looking = true;
      _error = null;
    });
    final u = await _try(c.updateLook);
    final os = _os != null ? await _try(() => c.osUpdates(check: true)) : null;
    if (!mounted) return;
    setState(() {
      _looking = false;
      _update = u ?? _update;
      _os = os ?? _os;
    });
  }

  Future<void> _updateNow() async {
    final app = AppScope.read(context);
    final l = AppLocalizations.of(context);
    final to = _os?.latest ?? _update?.latest ?? '';
    final ok = await askConfirm(
      context,
      title: l.updNowTitle,
      // Only what really happens: on this computer RedGiant's own window does it.
      body: app.localRedGiant && (_update?.install == 'windows' || _update?.install == 'mac')
          ? l.updNowBodyLocal(to)
          : l.updNowBody(to),
      yes: l.updNow,
    );
    if (!ok || !mounted) return;
    setState(() {
      _error = null;
      _said = null;
    });
    unawaited(
      app.startUpdate(
        from: _os?.installed ?? _update?.installed,
        to: to.isEmpty ? null : to,
        note: _update?.note,
      ),
    );
    await _openRun();
  }

  Future<void> _rename() async {
    final app = AppScope.read(context);
    final l = AppLocalizations.of(context);
    final t = await askText(context, title: l.renameServer, initial: app.displayName, yes: l.save);
    if (t != null && t.trim().isNotEmpty) await app.renameRedGiant(t);
  }

  Future<void> _revoke(DeviceRow d) async {
    final l = AppLocalizations.of(context);
    final ok = await askConfirm(
      context,
      title: l.devRevokeTitle,
      body: l.devRevokeBody(d.name),
      yes: l.devRevoke,
      danger: true,
    );
    if (!ok || !mounted) return;
    await _try(() => _c!.revokeDevice(d.id));
    final list = await _try(_c!.devices);
    if (mounted && list != null) setState(() => _devices = list);
  }

  Future<void> _pushTest(DeviceRow d) async {
    final l = AppLocalizations.of(context);
    final r = await _try(() => _c!.pushTest(d.id));
    if (!mounted) return;
    setState(() => _said = r == null ? l.pushTestSent : l.pushTestFailed(r));
  }

  Future<void> _pickModel() async {
    final models = _models ?? const <ModelChoice>[];
    if (models.isEmpty) return;
    final chosen = await showModalBottomSheet<ModelChoice>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (context) => ModelSheet(models: models, current: _setup?.defaultModel),
    );
    if (chosen == null || !mounted) return;
    final ok = await _try<bool>(() async {
      await _c!.setDefaultModel(chosen.provider, chosen.model, effort: _setup?.defaultEffort);
      return true;
    });
    if (ok != true) return;
    final s = await _try(_c!.setupSummary);
    if (mounted) setState(() => _setup = s ?? _setup);
  }

  Future<void> _openAll() async {
    final app = AppScope.read(context);
    final l = AppLocalizations.of(context);
    final s = app.server;
    final c = app.client;
    final token = c?.token;
    if (s == null || c == null || token == null) return;
    switch (fullSettingsMode(app.platform, c.transport.kind)) {
      case FullSettingsMode.unavailable:
        setState(() => _said = l.allSettingsNoHttps);
      case FullSettingsMode.webView:
        final leaf = s.caPem != null && c.transport.kind == TransportKind.pinnedHttps
            ? await pinnedLeaf(c.base, s.caPem!)
            : null;
        if (!mounted) return;
        await Navigator.of(context).push(
          MaterialPageRoute<void>(
            fullscreenDialog: true,
            builder: (_) => FullSettingsScreen(
              base: c.base,
              token: token,
              leaf: leaf,
              title: l.serverSettingsTitle(app.displayName),
            ),
          ),
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    final l = AppLocalizations.of(context);
    final c = RgColors.of(context);
    final s = app.server;
    final h = app.hello;
    final kind = app.client?.transport.kind;
    final mode = kind == null ? null : fullSettingsMode(app.platform, kind);
    final current = _devices?.where((d) => d.current).firstOrNull;
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          key: const Key('settings-back'),
          tooltip: l.back,
          onPressed: () => Navigator.of(context).pop(),
          icon: RgIcon(RgIcons.arrowLeft, color: c.text),
        ),
        title: Text(l.serverSettingsTitle(app.displayName)),
      ),
      body: RefreshIndicator(
        onRefresh: _load,
        // On a computer the cards keep a phone's measure, in the middle.
        child: Align(
          alignment: Alignment.topCenter,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 680),
            child: ListView(
              key: const Key('server-settings'),
              // Room above the first card (or the notice): never stuck to the bar.
              padding: const EdgeInsets.only(top: 8, bottom: 24),
              children: [
                if (_error != null) _Banner(text: l.errGeneric(_error!), error: true),
                if (_said != null) _Banner(text: _said!),
                // ---- name and state ----
                _Card(
                  children: [
                    ListTile(
                      key: const Key('settings-name'),
                      leading: RgIcon(RgIcons.server, color: app.connected ? c.ok : c.dim),
                      title: Text(
                        app.displayName,
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                      ),
                      subtitle: Text(
                        [
                          app.connected ? l.statusConnected : l.statusUnreachable,
                          if (h?.version != null) l.versionOf(h!.version!),
                        ].join(' · '),
                      ),
                      trailing: TextButton.icon(
                        key: const Key('settings-rename'),
                        onPressed: _rename,
                        icon: RgIcon(RgIcons.edit, size: 16, color: c.accent),
                        label: Text(l.rename),
                      ),
                    ),
                    if (s != null)
                      _Fact(icon: RgIcons.globe, text: '${s.address} · ${reachWord(l, s)}'),
                    if (s?.fingerprint != null)
                      _Fact(icon: RgIcons.lock, text: l.pinnedKey(s!.fingerprint!), mono: true),
                  ],
                ),
                // ---- updates ----
                _Head(l.sectionUpdates),
                _Card(key: const Key('settings-updates'), children: _updates(l, c)),
                // ---- devices ----
                _Head(l.sectionDevices),
                _Card(
                  key: const Key('settings-devices'),
                  children: [
                    if (_devices == null)
                      _Fact(icon: RgIcons.spinner, text: l.loading)
                    else if (_devices!.isEmpty)
                      _Fact(icon: RgIcons.phone, text: l.devNone)
                    else
                      for (final d in _devices!)
                        ListTile(
                          key: Key('device-${d.id}'),
                          leading: RgIcon(
                            d.platform == 'android' || d.platform == 'ios'
                                ? RgIcons.phone
                                : RgIcons.monitor,
                            color: d.current ? c.accent : c.dim,
                          ),
                          title: Text(d.name),
                          subtitle: Text(
                            d.current
                                ? l.devThis
                                : (d.lastUsedAt == null
                                      ? l.devNeverUsed
                                      : l.devLastUsed(_when(d.lastUsedAt!))),
                          ),
                          trailing: d.current
                              ? null
                              : IconButton(
                                  key: Key('revoke-${d.id}'),
                                  tooltip: l.devRevoke,
                                  onPressed: () => _revoke(d),
                                  icon: RgIcon(RgIcons.trash, size: 18, color: c.err),
                                ),
                        ),
                  ],
                ),
                // ---- this device's notifications ----
                _Head(l.sectionNotifications),
                _Card(
                  key: const Key('settings-push'),
                  children: [
                    if (current?.push == null)
                      _Fact(icon: RgIcons.bell, text: l.pushOff)
                    else ...[
                      _Fact(
                        icon: RgIcons.bell,
                        text: l.pushOn('${current!.push!['target'] ?? ''}'),
                      ),
                      if (current.push!['blocked'] != null)
                        _Fact(icon: RgIcons.alert, text: l.pushBlocked),
                      if (current.push!['lastError'] is String)
                        _Fact(icon: RgIcons.alert, text: '${current.push!['lastError']}'),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(8, 0, 8, 8),
                        child: Align(
                          alignment: Alignment.centerRight,
                          child: TextButton(
                            key: const Key('push-test'),
                            onPressed: () => _pushTest(current),
                            child: Text(l.pushTest),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                // ---- model and voice ----
                _Head(l.sectionModel),
                _Card(
                  children: [
                    ListTile(
                      key: const Key('settings-model'),
                      leading: RgIcon(RgIcons.cpu, color: c.accent),
                      title: Text(l.defaultModel),
                      subtitle: Text(_modelName() ?? l.modelNone),
                      trailing: (_models?.isNotEmpty ?? false) && !(_setup?.lockedModel ?? false)
                          ? RgIcon(RgIcons.chevronRight, color: c.dim)
                          : null,
                      onTap: (_models?.isNotEmpty ?? false) && !(_setup?.lockedModel ?? false)
                          ? _pickModel
                          : null,
                    ),
                    ListTile(
                      key: const Key('settings-voice'),
                      leading: RgIcon(RgIcons.mic, color: c.accent),
                      title: Text(l.voice),
                      subtitle: Text(
                        [
                          l.voiceHear(_setup?.transcription ?? l.voiceNone),
                          l.voiceRead(_setup?.speech ?? l.voiceBrowser),
                        ].join('\n'),
                      ),
                      isThreeLine: true,
                    ),
                  ],
                ),
                // ---- agents at work together (3.8.10) ----
                _Head(l.atWorkTitle),
                _Card(
                  children: [
                    ListTile(
                      key: const Key('settings-at-work'),
                      leading: RgIcon(RgIcons.users, color: c.accent),
                      title: Text(l.atWorkAtMost),
                      subtitle: Text(
                        [
                          atWorkSummary(l, app.live.turns.limit),
                          if (app.live.turns.queued.isNotEmpty)
                            l.statusQueued(app.live.turns.queued.length),
                        ].join(' · '),
                      ),
                      trailing: RgIcon(RgIcons.chevronRight, color: c.dim),
                      onTap: () => openAtWork(context),
                    ),
                  ],
                ),
                // ---- projects and code (G42.5: native, Settings › Projects and › Code) ----
                _Head(l.psSection),
                _Card(
                  children: [
                    ListTile(
                      key: const Key('settings-projects'),
                      leading: RgIcon(RgIcons.box, color: c.accent),
                      title: Text(l.psTitle),
                      subtitle: Text(l.psRowHint),
                      trailing: RgIcon(RgIcons.chevronRight, color: c.dim),
                      onTap: () => openProjectsSettings(context),
                    ),
                    ListTile(
                      key: const Key('settings-code'),
                      leading: RgIcon(RgIcons.gitBranch, color: c.accent),
                      title: Text(l.csTitle),
                      subtitle: Text(l.csRowHint),
                      trailing: RgIcon(RgIcons.chevronRight, color: c.dim),
                      onTap: () => openCodeSettings(context),
                    ),
                  ],
                ),
                // ---- artifacts (G42.2: native, as the page's Settings › Artifacts) ----
                _Head(l.sectionArtifacts),
                _Card(
                  children: [
                    ListTile(
                      key: const Key('settings-artifacts'),
                      leading: RgIcon(RgIcons.code, color: c.accent),
                      title: Text(l.cvArSection),
                      subtitle: Text(l.artifactsRowHint),
                      trailing: RgIcon(RgIcons.chevronRight, color: c.dim),
                      onTap: () => openArtifacts(context),
                    ),
                  ],
                ),
                // ---- from outside ----
                _Head(l.sectionOutside),
                _Card(key: const Key('settings-outside'), children: _outside(l, c)),
                // ---- everything else ----
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 18, 16, 0),
                  child: FilledButton.icon(
                    key: const Key('settings-all'),
                    onPressed: mode == null || mode == FullSettingsMode.unavailable
                        ? null
                        : _openAll,
                    icon: const RgIcon(RgIcons.settings, size: 18, color: Colors.white),
                    label: Text(l.allSettings),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                  child: Text(switch (mode) {
                    FullSettingsMode.webView => l.allSettingsHint,
                    _ => l.allSettingsNoHttps,
                  }, style: TextStyle(color: c.dim, fontSize: 12.5)),
                ),
                if (mode == FullSettingsMode.webView)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: OutlinedButton.icon(
                        key: const Key('settings-embed-probe'),
                        onPressed: () => openEmbedProbe(context),
                        icon: RgIcon(RgIcons.canvas, size: 16, color: c.text),
                        label: Text(l.embedProbeOpen),
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

  String? _modelName() {
    final m = _setup?.defaultModel;
    if (m == null) return null;
    final at = familyOf(modelFamilies(_models ?? const []), m);
    if (at == null) return m.split('/').skip(1).join('/');
    final (f, i) = at;
    return '${f.label} · ${wayWord(AppLocalizations.of(context), f.ways[i])}';
  }

  static String _when(String iso) {
    final t = DateTime.tryParse(iso)?.toLocal();
    if (t == null) return iso;
    String two(int n) => n.toString().padLeft(2, '0');
    return '${two(t.day)}/${two(t.month)} ${two(t.hour)}:${two(t.minute)}';
  }

  List<Widget> _updates(AppLocalizations l, RgColors c) {
    final u = _update;
    final os = _os;
    if (u == null && os == null) return [_Fact(icon: RgIcons.spinner, text: l.loading)];
    final lang = Localizations.localeOf(context).languageCode;
    final latest = os?.latest ?? u?.latest;
    final available = (os?.state == 'available') || (u?.available ?? false);
    final breaking = u?.gate == 'breaking' || os?.state == 'breaking';
    final canHere = (u?.canUpdateHere ?? false) && !breaking;
    final installed = os?.installed ?? u?.installed;
    final facts = [
      if (installed != null) l.updInstalled(installed),
      if (u?.checkedAt != null) l.updChecked(_when(u!.checkedAt!)),
    ];
    final out = <Widget>[
      ListTile(
        leading: RgIcon(
          available ? RgIcons.download : RgIcons.check,
          color: available ? c.accent : c.ok,
        ),
        title: Text(
          _applying
              ? l.updApplying(latest ?? '')
              : available
              ? l.updAvailable(latest ?? '')
              : l.updLatest,
        ),
        subtitle: facts.isEmpty ? null : Text(facts.join(' · ')),
      ),
    ];
    if (_applying) {
      out.add(
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
          child: Align(
            alignment: Alignment.centerLeft,
            child: FilledButton.icon(
              key: const Key('update-follow'),
              onPressed: () {
                final app = AppScope.read(context);
                if (app.updateRun == null) app.followUpdate(_update, _os, open: false);
                unawaited(_openRun());
              },
              icon: const RgIcon(RgIcons.download, size: 16, color: Colors.white),
              label: Text(l.updFollow),
            ),
          ),
        ),
      );
    }
    final note = u?.noteIn(lang);
    if (available && note != null && note.isNotEmpty) {
      out.add(_Fact(icon: RgIcons.file, text: note));
    }
    if (available && breaking) out.add(_Fact(icon: RgIcons.alert, text: l.updBreaking));
    if (available && !canHere && u?.command != null) {
      out.add(_Fact(icon: RgIcons.tool, text: l.updDockerHint));
      out.add(
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
          child: SelectableText(
            u!.command!,
            style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
          ),
        ),
      );
    }
    if (os?.rebootRequired ?? false) out.add(_Fact(icon: RgIcons.refresh, text: l.updReboot));
    out.add(
      Padding(
        padding: const EdgeInsets.fromLTRB(8, 0, 8, 8),
        child: Wrap(
          alignment: WrapAlignment.end,
          spacing: 8,
          children: [
            TextButton.icon(
              key: const Key('update-look'),
              onPressed: _looking || _applying ? null : _look,
              icon: RgIcon(RgIcons.refresh, size: 16, color: c.accent),
              label: Text(_looking ? l.updLooking : l.updLook),
            ),
            if (available && canHere && !_applying)
              FilledButton(
                key: const Key('update-now'),
                onPressed: _updateNow,
                child: Text(l.updNow),
              ),
          ],
        ),
      ),
    );
    return out;
  }

  List<Widget> _outside(AppLocalizations l, RgColors c) {
    final s = _setup;
    if (s == null) return [_Fact(icon: RgIcons.spinner, text: l.loading)];
    final url = s.remoteUrl ?? s.reachableUrl;
    if (url == null) return [_Fact(icon: RgIcons.home, text: l.outsideNone)];
    final way = switch (s.remoteWay) {
      'tailscale' => 'Tailscale',
      'cloudflare' => 'Cloudflare',
      'caddy' => l.outsideOwnName,
      _ => l.outsideOwn,
    };
    return [
      ListTile(
        key: const Key('outside-link'),
        leading: RgIcon(RgIcons.globe, color: c.accent),
        title: Text(url),
        subtitle: Text(way),
        trailing: RgIcon(RgIcons.external, size: 18, color: c.dim),
        onTap: () {
          final u = Uri.tryParse(url);
          if (u != null) unawaited(openExternal(u));
        },
      ),
    ];
  }
}

class _Head extends StatelessWidget {
  const _Head(this.title);

  final String title;

  @override
  Widget build(BuildContext context) {
    final c = RgColors.of(context);
    return Semantics(
      header: true,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 18, 16, 6),
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

class _Card extends StatelessWidget {
  const _Card({super.key, required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final c = RgColors.of(context);
    // A Material of its own: the tiles' ink shows on it.
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Material(
        color: c.panel,
        clipBehavior: Clip.antiAlias,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: BorderSide(color: c.line),
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: children),
      ),
    );
  }
}

class _Fact extends StatelessWidget {
  const _Fact({required this.icon, required this.text, this.mono = false});

  final RgIcons icon;
  final String text;
  final bool mono;

  @override
  Widget build(BuildContext context) {
    final c = RgColors.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 6, 16, 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 2),
            child: RgIcon(icon, size: 15, color: c.dim),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: SelectableText(
              text,
              style: TextStyle(
                color: c.dim,
                fontSize: mono ? 11.5 : 13.5,
                fontFamily: mono ? 'monospace' : null,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Banner extends StatelessWidget {
  const _Banner({required this.text, this.error = false});

  final String text;
  final bool error;

  @override
  Widget build(BuildContext context) {
    final c = RgColors.of(context);
    final col = error ? c.err : c.ok;
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: col.withValues(alpha: .08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: col.withValues(alpha: .35)),
      ),
      child: Text(text, style: TextStyle(color: col)),
    );
  }
}

/// The models by family (G40.9b): a model that goes both through the subscription and through the
/// API key shows once, with the drawn choice of the way and a line on what it means; a model with
/// one way says it under its name. A tap on the model takes it with the way shown.
class ModelSheet extends StatefulWidget {
  const ModelSheet({super.key, required this.models, this.current});

  final List<ModelChoice> models;

  /// The `provider/model` in use now.
  final String? current;

  @override
  State<ModelSheet> createState() => _ModelSheetState();
}

class _ModelSheetState extends State<ModelSheet> {
  late final List<ModelFamily> _families = modelFamilies(widget.models);

  /// The way shown per family: the one in use, else the first (the subscription).
  late final Map<String, int> _way = {
    for (final f in _families)
      f.id: math.max(0, f.ways.indexWhere((w) => w.choice.key == widget.current)),
  };

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final c = RgColors.of(context);
    return SafeArea(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxHeight: MediaQuery.sizeOf(context).height * .8),
        child: ListView(
          shrinkWrap: true,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
              child: Text(l.setModel, style: const TextStyle(fontWeight: FontWeight.w700)),
            ),
            for (final f in _families) _family(context, l, c, f),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  Widget _family(BuildContext context, AppLocalizations l, RgColors c, ModelFamily f) {
    final i = _way[f.id] ?? 0;
    final way = f.ways[i];
    final inUse = f.ways.any((w) => w.choice.key == widget.current);
    final many = f.ways.length > 1;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ListTile(
          key: Key('model-${f.id}'),
          title: Text(f.label),
          subtitle: Text(
            many ? f.ways.map((w) => wayWord(l, w)).join(' ${l.modelWayOr} ') : wayWord(l, way),
          ),
          trailing: inUse ? const RgIcon(RgIcons.check) : null,
          onTap: () => Navigator.pop(context, way.choice),
        ),
        if (many)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              spacing: 6,
              children: [
                SegmentedButton<int>(
                  key: Key('ways-${f.id}'),
                  showSelectedIcon: false,
                  segments: [
                    for (final (j, w) in f.ways.indexed)
                      ButtonSegment(
                        value: j,
                        label: Text(wayWord(l, w), key: Key('way-${w.choice.key}')),
                      ),
                  ],
                  selected: {i},
                  onSelectionChanged: (s) => setState(() => _way[f.id] = s.first),
                ),
                Text(wayHint(l, way), style: TextStyle(color: c.dim, fontSize: 12.5)),
              ],
            ),
          ),
      ],
    );
  }
}

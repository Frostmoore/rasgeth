// «Settings of <name>» (G40.8, the person's request): the settings of the RedGiant the app is
// connected to that are used most, made for the phone: its name, its state and updates («Update»
// opens the update's own screen, update_screen.dart), the devices connected (and signing
// one out), this device's notifications, the default model, the voice, the access from outside
// (to read, with its link); and «All settings», the page's Settings inside the app.
import 'dart:async';

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
import '../api/types.dart' show AgentModel;
import '../ui/dialogs.dart';
import '../ui/model_sheet.dart' show showModelPicker;
import '../ui/icons.dart';
import '../ui/words.dart';
import '../embed/embed_screen.dart';
import '../settings/agents/agent_tree.dart';
import '../settings/budgets_screen.dart';
import '../settings/commands_screen.dart';
import '../settings/general_screen.dart';
import '../settings/requests_screen.dart';
import '../settings/safety_screen.dart';
import '../settings/tools_screen.dart';
import 'artifacts_screen.dart';
import 'first_start_screen.dart' show openExternal;
import '../settings/automations/automations_screen.dart';
import 'full_settings_screen.dart';
import 'update_screen.dart';
import 'you_screen.dart' show reachWord;
// G42.10: Settings › Knowledge and Shared memory, native.
import '../settings/knowledge_screen.dart' show openKnowledgeSettings;
import '../settings/memory_screen.dart' show openSharedMemory;
import '../settings/portrait_screen.dart' show openPortrait;
import '../settings/skills_screen.dart' show openSkills;
// G42.13 and G42.15: Telegram, Chats, Models and subscriptions, native.
import '../settings/channels/chats_screen.dart' show openChatPlatforms;
import '../settings/channels/telegram_screen.dart' show openTelegramSettings;
import '../settings/models/models_screen.dart' show openModelsSettings;

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

  /// «Togli quelli mai usati» (3.9.8, as the page's Settings › Devices).
  Future<void> _forgetUnused() async {
    final l = AppLocalizations.of(context);
    final ok = await askConfirm(
      context,
      title: l.devForgetUnusedTitle,
      body: l.devForgetUnusedBody,
      yes: l.devForgetUnused,
      danger: true,
    );
    if (!ok || !mounted) return;
    final n = await _try(_c!.forgetUnusedDevices);
    final list = await _try(_c!.devices);
    if (!mounted) return;
    setState(() => _devices = list ?? _devices);
    if (n != null) {
      ScaffoldMessenger.maybeOf(context)
          ?.showSnackBar(SnackBar(content: Text(l.devForgetUnusedDone(n))));
    }
  }

  Future<void> _renameDevice(DeviceRow d) async {
    final l = AppLocalizations.of(context);
    final t = await askText(
      context,
      title: l.g4DvRenameQ(d.name),
      initial: d.name,
      yes: l.rename,
      fieldKey: const Key('device-name'),
    );
    final name = t?.trim() ?? '';
    final cut = name.length > 60 ? name.substring(0, 60) : name;
    if (cut.isEmpty || cut == d.name || !mounted) return;
    final ok = await _try<bool>(() async {
      await _c!.renameDevice(d.id, cut);
      return true;
    });
    if (ok != true) return;
    final list = await _try(_c!.devices);
    if (!mounted) return;
    setState(() {
      if (list != null) _devices = list;
      _said = l.g4DvRenamed(cut);
    });
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
    final l = AppLocalizations.of(context);
    final cur = _setup?.defaultModel;
    final i = cur?.indexOf('/') ?? -1;
    // The same sheet as every other model choice: by provider and way, the newest first.
    final pick = await showModelPicker(
      context,
      title: l.setModel,
      models: models,
      current: cur == null || i < 0
          ? null
          : AgentModel(
              provider: cur.substring(0, i),
              model: cur.substring(i + 1),
              effort: _setup?.defaultEffort,
            ),
    );
    final chosen = pick?.model;
    if (chosen == null || !mounted) return;
    final ok = await _try<bool>(() async {
      await _c!.setDefaultModel(chosen.provider, chosen.model, effort: chosen.effort);
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
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                key: Key('rename-${d.id}'),
                                tooltip: l.rename,
                                onPressed: () => _renameDevice(d),
                                icon: RgIcon(RgIcons.edit, size: 18, color: c.dim),
                              ),
                              if (!d.current)
                                IconButton(
                                  key: Key('revoke-${d.id}'),
                                  tooltip: l.devRevoke,
                                  onPressed: () => _revoke(d),
                                  icon: RgIcon(RgIcons.trash, size: 18, color: c.err),
                                ),
                            ],
                          ),
                        ),
                    if (_devices?.any((d) => d.lastUsedAt == null && !d.current) ?? false)
                      Padding(
                        padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
                        child: Align(
                          alignment: Alignment.centerLeft,
                          child: TextButton.icon(
                            key: const Key('devices-forget-unused'),
                            onPressed: _forgetUnused,
                            icon: RgIcon(RgIcons.trash, size: 16, color: c.err),
                            label: Text(l.devForgetUnused, style: TextStyle(color: c.err)),
                          ),
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
                // ---- the settings of every day (G42.4, native as the page's sections) ----
                _Head(l.g4HubTitle),
                _Card(
                  key: const Key('settings-hub'),
                  children: [
                    _hub(
                      c,
                      'general',
                      RgIcons.settings,
                      l.g4GenTitle,
                      l.g4HubGeneral,
                      () => openGeneralSettings(context),
                    ),
                    _hub(
                      c,
                      'agents',
                      RgIcons.users,
                      l.g4AgTreeTitle,
                      l.g4HubAgents,
                      () => openAgentTree(context),
                    ),
                    // G42.5: Settings › Projects, after the agents as on the page.
                    _hub(
                      c,
                      'projects',
                      RgIcons.box,
                      l.psTitle,
                      l.psRowHint,
                      () => openProjectsSettings(context),
                    ),
                    // G42.9: Settings › Automations, native, where the page has it (after the
                    // projects and the knowledge).
                    _hub(
                      c,
                      'automations',
                      RgIcons.clock,
                      l.auAutomations,
                      l.auOwnHubHint,
                      () => openAutomationsSettings(context),
                    ),
                    _hub(
                      c,
                      'tools',
                      RgIcons.tool,
                      l.g4TlSection,
                      l.g4HubTools,
                      () => openToolsSettings(context),
                    ),
                    // 3.9.7: the agents' skills, their versions and the way back, native.
                    _hub(
                      c,
                      'skills',
                      RgIcons.spark,
                      l.skSection,
                      l.skHub,
                      () => openSkills(context),
                    ),
                    _hub(
                      c,
                      'commands',
                      RgIcons.terminal,
                      l.g4CmSection,
                      [
                        l.g4HubCommands,
                        atWorkSummary(l, app.live.turns.limit),
                        if (app.live.turns.queued.isNotEmpty)
                          l.statusQueued(app.live.turns.queued.length),
                      ].join(' · '),
                      () => openCommandsSettings(context),
                    ),
                    _hub(
                      c,
                      'requests',
                      RgIcons.bell,
                      l.g4RqSection,
                      l.g4HubRequests,
                      () => openRequestsSettings(context),
                    ),
                    _hub(
                      c,
                      'safety',
                      RgIcons.shield,
                      l.g4SfTitle,
                      l.g4HubSafety,
                      () => openSafetySettings(context),
                    ),
                    // G42.13 and G42.15: the page's «Where» group (Telegram, Chats) and
                    // Models and subscriptions, before the budgets as on the page.
                    _hub(
                      c,
                      'telegram',
                      RgIcons.send,
                      l.chTelegram,
                      l.chHubTelegram,
                      () => openTelegramSettings(context),
                    ),
                    _hub(
                      c,
                      'chats',
                      RgIcons.chat,
                      l.chChats,
                      l.chHubChats,
                      () => openChatPlatforms(context),
                    ),
                    _hub(
                      c,
                      'models',
                      RgIcons.cpu,
                      l.moSubscriptions,
                      l.moHubModels,
                      () => openModelsSettings(context),
                    ),
                    _hub(
                      c,
                      'budgets',
                      RgIcons.dollar,
                      l.g4BuTitle,
                      l.g4BuRowHint,
                      () => openBudgetsSettings(context),
                    ),
                    // G42.5: Settings › Code (the page's «Home» group, after the models').
                    _hub(
                      c,
                      'code',
                      RgIcons.gitBranch,
                      l.csTitle,
                      l.csRowHint,
                      () => openCodeSettings(context),
                    ),
                    // G42.10: Knowledge and Shared memory, native.
                    _hub(
                      c,
                      'knowledge',
                      RgIcons.database,
                      l.knKbSection,
                      l.knHubKnowledge,
                      () => openKnowledgeSettings(context),
                    ),
                    _hub(
                      c,
                      'memory',
                      RgIcons.bookmark,
                      l.knMemEyebrow,
                      l.knHubMemory,
                      () => openSharedMemory(context),
                    ),
                    // 3.9.4: the person's portrait («Mirror»), native.
                    _hub(
                      c,
                      'portrait',
                      RgIcons.user,
                      l.ptrSection,
                      l.ptrHub,
                      () => openPortrait(context),
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

  Widget _hub(RgColors c, String id, RgIcons icon, String title, String sub, VoidCallback onTap) =>
      ListTile(
        key: Key('settings-$id'),
        leading: RgIcon(icon, color: c.accent),
        title: Text(title),
        subtitle: Text(sub),
        trailing: RgIcon(RgIcons.chevronRight, color: c.dim),
        onTap: onTap,
      );

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

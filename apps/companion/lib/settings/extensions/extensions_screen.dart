// G42.11: Settings › Extensions, native, as the page's Extensions.tsx (G24.9, drawn as the wizard
// on 2026-11-06): the magic integration and extension right under the question (God writes them,
// magic_extension.dart), what waits for the person (the agents' proposals, tested in a throwaway
// sandbox), the services connected (signing in opens the service's page in the system's browser,
// then the state is read again until it works), the generation of pictures, video and sound, the
// catalog of services (the protocol's MCP_CATALOG, ext_catalog.dart), the skills and tools
// installed, and the hand-made ones (a skill's .zip imported, a skill written, an MCP server by
// address or command). Every square opens a window (a sheet from below on a phone). Routes in
// api/extensions_api.dart.
import 'dart:async';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

import '../../api/client.dart';
import '../../app_state.dart';
import '../../l10n/app_localizations.dart';
import '../../screens/canvas_screen.dart' show openCanvas;
import '../../theme/colors.dart';
import '../../ui/dialogs.dart';
import '../../ui/icons.dart';
import '../../ui/markdown.dart';
import '../api/extensions_api.dart';
import '../api/skills_api.dart' show InstalledSkill;
import '../automations/automation_kit.dart';
import '../prompt_refiner.dart' show WordDiffView;
import '../rules_kit.dart';
import '../skills_screen.dart' show SkillHistoryView;
import 'ext_catalog.dart';
import 'ext_kit.dart';
import 'magic_extension.dart';
import 'media_kind.dart';

/// Opens the page: a panel over the window on a computer, a whole screen on a phone.
Future<void> openExtensionsSettings(BuildContext context) =>
    openRulesPage(context, (panel) => ExtensionsScreen(panel: panel));

/// A .zip from this device: its name and bytes (the system's chooser; a test gives its own).
typedef PickZip = Future<(String, List<int>)?> Function();

/// Where the bytes of a download go: the system's «Save as» (a test gives its own).
typedef SaveBytes = Future<bool> Function(String name, Uint8List bytes);

Future<(String, List<int>)?> _systemZip() async {
  final f = await FilePicker.pickFiles(type: FileType.custom, allowedExtensions: ['zip']);
  final one = f.firstOrNull;
  return one == null ? null : (one.name, await one.readAsBytes());
}

Future<bool> _systemSave(String name, Uint8List bytes) async =>
    await FilePicker.saveFile(fileName: name, bytes: bytes) != null;

/// A drawn icon by kind of service (the page's CATEGORY_ICON).
RgIcons categoryIcon(String c) => switch (c) {
  'code' => RgIcons.terminal,
  'docs' => RgIcons.file,
  'web' => RgIcons.compass,
  'data' => RgIcons.layers,
  'work' => RgIcons.board,
  'design' => RgIcons.pencil,
  'cloud' => RgIcons.cpu,
  _ => RgIcons.monitor,
};

String categoryLabel(AppLocalizations l, String c) => switch (c) {
  'code' => l.xtExtCat_code,
  'docs' => l.xtExtCat_docs,
  'web' => l.xtExtCat_web,
  'data' => l.xtExtCat_data,
  'work' => l.xtExtCat_work,
  'design' => l.xtExtCat_design,
  'cloud' => l.xtExtCat_cloud,
  'home' => l.xtExtCat_home,
  _ => l.xtExtCatAll,
};

String _authLabel(AppLocalizations l, String type) => switch (type) {
  'app' => l.xtExtAuth_app,
  'oauth' => l.xtExtAuth_oauth,
  'none' => l.xtExtAuth_none,
  _ => l.xtExtAuth_header,
};

/// A server's state in words, for its square and its window.
String serviceState(AppLocalizations l, McpState? s) {
  if (s == null) return l.xtExtChecking;
  if (s.state == 'connected') return l.xtExtWorks('${s.tools}');
  if (s.state == 'login') return l.xtExtNeedsLogin;
  return l.xtExtBroken;
}

String kindLabel(AppLocalizations l, String kind) =>
    kind == 'tool' ? l.xtExtKindTool : l.xtExtKindSkill;

/// The project's name, or «platform».
String scopeLabel(AppLocalizations l, AppController app, String? projectId) => projectId == null
    ? l.xtScopePlatform
    : app.projects.where((p) => p.id == projectId).firstOrNull?.name ?? projectId;

/// `platform` or `project:<id>`, in words.
String installedScope(AppLocalizations l, AppController app, String scope) =>
    scope == 'platform' ? l.xtScopePlatform : scopeLabel(l, app, scope.substring(8));

/// Who an id is: «You», an agent's name, or the id.
String whoOf(AppLocalizations l, AppController app, String id) =>
    id == 'human' ? l.xtYou : app.agents.where((a) => a.id == id).firstOrNull?.name ?? id;

class ExtensionsScreen extends StatefulWidget {
  const ExtensionsScreen({super.key, this.panel = false, this.pickZip, this.saveBytes});

  final bool panel;
  final PickZip? pickZip;
  final SaveBytes? saveBytes;

  @override
  State<ExtensionsScreen> createState() => _ExtensionsScreenState();
}

class _ExtensionsScreenState extends State<ExtensionsScreen> {
  List<ExtProposal>? _proposals;
  List<MagicExt> _magic = const [];
  List<Installed> _installed = const [];
  List<McpServer> _mcp = const [];
  List<McpState>? _status;
  MediaSetup? _media;
  String? _error;
  String? _note;

  /// Until when to look again for a sign-in finished in the browser.
  DateTime _watchUntil = DateTime(0);
  Timer? _watch;
  late final ValueNotifier<int> _changed = AppScope.read(context).live.automationsChanged;

  @override
  void initState() {
    super.initState();
    _changed.addListener(_reloadQuiet);
    unawaited(_load());
  }

  @override
  void dispose() {
    _watch?.cancel();
    _changed.removeListener(_reloadQuiet);
    super.dispose();
  }

  void _reloadQuiet() => unawaited(_load());

  RedGiantClient? get _client => AppScope.read(context).client;

  Future<void> _load() async {
    final c = _client;
    if (c == null) return;
    try {
      final r = await Future.wait<Object>([
        c.extProposals(),
        c.installedExtensions(),
        c.mcpServers(),
      ]);
      if (!mounted) return;
      setState(() {
        _proposals = r[0] as List<ExtProposal>;
        _installed = r[1] as List<Installed>;
        _mcp = r[2] as List<McpServer>;
        _error = null;
      });
    } on Exception catch (e) {
      if (mounted) setState(() => _error = rulesWhy(e));
    }
    unawaited(_loadStatus());
    unawaited(
      c.magicExts().then(
        (l) => mounted ? setState(() => _magic = l) : null,
        onError: (_) => mounted ? setState(() => _magic = const []) : null,
      ),
    );
    unawaited(
      c.mediaSetup().then((m) => mounted ? setState(() => _media = m) : null, onError: (_) {}),
    );
  }

  Future<void> _loadStatus() async {
    final c = _client;
    if (c == null) return;
    try {
      final s = await c.mcpStatus();
      if (!mounted) return;
      setState(() => _status = s);
      // A sign-in in the browser: read again every three seconds until it works (five minutes).
      _watch?.cancel();
      if (DateTime.now().isBefore(_watchUntil) && s.any((x) => x.state == 'login')) {
        _watch = Timer(const Duration(seconds: 3), _loadStatus);
      }
    } on Exception {
      if (mounted) setState(() => _status = const []);
    }
  }

  /// Signs in to [name]: the service's page in the system's browser, or done already.
  Future<void> _signIn(String name) async {
    final c = _client;
    if (c == null) return;
    final l = AppLocalizations.of(context);
    final url = await c.mcpLogin(name, c.base.origin);
    if (url == null) {
      await _load();
      return;
    }
    _watchUntil = DateTime.now().add(const Duration(minutes: 5));
    if (mounted) setState(() => _note = l.g4211SignInOpened);
    await openOutside(url);
    await _loadStatus();
  }

  Future<void> _openProposal(ExtProposal p) async {
    await openAutoWindow<void>(
      context,
      title: p.name,
      wide: true,
      key: Key('xt-proposal-${p.id}'),
      child: (ctx, close) => _ProposalView(p: p, onDone: _load, close: close),
    );
  }

  Future<void> _openCatalog(CatalogEntry e) async {
    final added = _mcp.any((m) => m.name == e.id);
    await openAutoWindow<void>(
      context,
      title: e.name,
      key: Key('xt-entry-${e.id}'),
      child: (ctx, close) => _CatalogWindow(
        entry: e,
        added: added,
        close: close,
        onAdded: (signsIn) async {
          close();
          await _load();
          if (signsIn) {
            try {
              await _signIn(e.id);
            } on ApiException catch (err) {
              if (mounted) setState(() => _error = err.message);
            }
          }
        },
      ),
    );
  }

  Future<void> _openServer(McpServer m) async {
    final l = AppLocalizations.of(context);
    final app = AppScope.read(context);
    final e = catalogEntry(m.name);
    final s = _status?.where((x) => x.name == m.name).firstOrNull;
    await openAutoWindow<void>(
      context,
      title: e?.name ?? m.name,
      key: Key('xt-server-${m.name}'),
      child: (ctx, close) => _ServerWindow(
        server: m,
        state: s,
        scope: scopeLabel(l, app, m.projectId),
        onRemove: () async {
          await _client?.removeMcp(m.name);
          close();
          await _load();
        },
        onConnect: () async {
          close();
          await _signIn(m.name);
        },
        close: close,
      ),
    );
  }

  Future<void> _openInstalled(Installed x) async {
    final l = AppLocalizations.of(context);
    final app = AppScope.read(context);
    await openAutoWindow<void>(
      context,
      title: x.name,
      wide: x.kind == 'skill',
      key: Key('xt-installed-${x.name}'),
      child: (ctx, close) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (x.description.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Text(x.description, style: TextStyle(color: RgColors.of(ctx).dim)),
            ),
          Facts(
            rows: [
              (l.xtXwKind, factText(kindLabel(l, x.kind))),
              (l.xtScope, factText(installedScope(l, app, x.scope))),
              (l.xtXwFile, MonoText(x.path)),
            ],
          ),
          if (x.kind == 'skill') ...[
            AutoHelp(l.xtSkillDownloadHelp),
            SkillHistoryView(
              skill: InstalledSkill(name: x.name, description: x.description, scope: x.scope),
              who: (id) => id == null ? l.xtSvUnknown : whoOf(l, app, id),
            ),
          ],
          WindowActs(
            children: [
              if (x.kind == 'skill')
                OutlinedButton.icon(
                  key: const Key('xt-skill-download'),
                  onPressed: () async {
                    final c = _client;
                    if (c == null) return;
                    try {
                      final bytes = await c.exportSkill(x.name, x.scope);
                      await (widget.saveBytes ?? _systemSave)('${x.name}.zip', bytes);
                    } on ApiException catch (e) {
                      if (mounted) setState(() => _error = e.message);
                    }
                  },
                  icon: const RgIcon(RgIcons.download, size: 17),
                  label: Text(l.xtSkillDownload),
                ),
              FilledButton.icon(
                key: const Key('xt-open-file'),
                onPressed: () {
                  close();
                  unawaited(openCanvas(context, scope: x.scope, path: x.path, title: x.name));
                },
                icon: const RgIcon(RgIcons.pencil, size: 17, color: Colors.white),
                label: Text(l.xtXwOpenFile),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _openMedia(String kind) async {
    final l = AppLocalizations.of(context);
    await openAutoWindow<void>(
      context,
      title: mediaKindLabel(l, kind),
      key: Key('xt-media-$kind'),
      child: (ctx, close) => MediaKindView(kind: kind, onChanged: _load, close: close),
    );
  }

  Future<void> _startMagic(String kind) async {
    final m = await openMagicExtStart(context, kind);
    if (m == null || !mounted) return;
    setState(() => _magic = [m, ..._magic.where((x) => x.id != m.id)]);
    await _openMagic(m);
  }

  Future<void> _openMagic(MagicExt m) async {
    await openMagicExtChat(context, m, onChange: _load);
    await _load();
  }

  Future<void> _newSkill() async {
    final l = AppLocalizations.of(context);
    await openAutoWindow<void>(
      context,
      title: l.xtNewSkill,
      wide: true,
      key: const Key('xt-new-skill'),
      child: (ctx, close) => _NewSkill(
        onDone: () {
          close();
          unawaited(_load());
        },
        close: close,
      ),
    );
  }

  Future<void> _addServer() async {
    final l = AppLocalizations.of(context);
    await openAutoWindow<void>(
      context,
      title: l.xtAddServer,
      key: const Key('xt-add-server'),
      child: (ctx, close) => _McpForm(
        onDone: () {
          close();
          unawaited(_load());
        },
        close: close,
      ),
    );
  }

  Future<void> _importSkill() async {
    final l = AppLocalizations.of(context);
    await openAutoWindow<void>(
      context,
      title: l.xtSkillImport,
      key: const Key('xt-import'),
      child: (ctx, close) =>
          _ImportSkill(pick: widget.pickZip ?? _systemZip, onDone: _load, close: close),
    );
  }

  Future<void> _openFailed(List<ExtProposal> failed) async {
    final l = AppLocalizations.of(context);
    final app = AppScope.read(context);
    await openAutoWindow<void>(
      context,
      title: l.xtFailedTests,
      wide: true,
      key: const Key('xt-failed'),
      child: (ctx, close) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AutoHelp(l.xtXwFailedLead),
          AutoGrid(
            children: [
              for (final p in failed)
                _proposalTile(
                  l,
                  app,
                  p,
                  waiting: false,
                  onTap: () {
                    close();
                    unawaited(_openProposal(p));
                  },
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _proposalTile(
    AppLocalizations l,
    AppController app,
    ExtProposal p, {
    required bool waiting,
    required VoidCallback onTap,
  }) => AutoTile(
    key: Key('xt-prop-${p.id}'),
    icon: p.isTool ? RgIcons.tool : RgIcons.book,
    title: p.name,
    badge: kindLabel(l, p.kind),
    text: p.updateLine ?? p.description,
    state: '${waiting ? l.xtXwWaitsYou : l.xtXwTestsFailed} · ${l.xtBy} ${whoOf(l, app, p.author)}',
    onTap: onTap,
  );

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final c = RgColors.of(context);
    final app = AppScope.of(context);
    final proposals = _proposals;
    final inMagic = {
      for (final m in _magic)
        for (final p in m.parts) p.proposalId,
    };
    final pending = [
      for (final p in proposals ?? const <ExtProposal>[])
        if (p.status == 'pending' && !inMagic.contains(p.id)) p,
    ];
    final failed = [
      for (final p in proposals ?? const <ExtProposal>[])
        if (p.status == 'failed') p,
    ].take(5).toList();
    final status = _status;
    return RulesPage(
      pageKey: const Key('extensions-settings'),
      title: l.xtExtensions,
      panel: widget.panel,
      question: l.xtExtAskTitle,
      lead: l.xtExtAskHelp,
      children: [
        for (final kind in const ['integration', 'extension'])
          MagicExtButton(kind: kind, onTap: () => _startMagic(kind)),
        if (_error != null) RulesLoading(error: _error),
        if (_note != null) AutoNotice(_note!, key: const Key('xt-note')),
        if (proposals == null && _error == null) const RulesLoading(),
        if (_magic.isNotEmpty) ...[
          RulesSub(title: l.xtMxListTitle, lead: l.xtMxListLead, icon: RgIcons.spark),
          AutoGrid(
            children: [
              for (final m in _magic)
                AutoTile(
                  key: Key('xt-magic-${m.id}'),
                  icon: RgIcons.spark,
                  gold: true,
                  on: m.status == 'ready' || m.status == 'done',
                  title: m.title,
                  badge: m.status == 'ready'
                      ? (m.canApprove ? l.xtMxBadgeApprove : l.xtMxBadgeMissing)
                      : m.status == 'done'
                      ? l.xtMxBadgeInstalled
                      : null,
                  text: m.request,
                  state: magicExtState(l, m.status),
                  onTap: () => _openMagic(m),
                ),
            ],
          ),
        ],
        if (pending.isNotEmpty) ...[
          RulesSub(title: l.xtExtProposals, lead: l.xtExtProposalsHelp, icon: RgIcons.bell),
          AutoGrid(
            key: const Key('xt-pending'),
            children: [
              for (final p in pending)
                _proposalTile(l, app, p, waiting: true, onTap: () => _openProposal(p)),
            ],
          ),
        ],
        if (_mcp.isNotEmpty) ...[
          RulesSub(title: l.xtExtConnected, lead: l.xtXwConnectedLead),
          AutoGrid(
            key: const Key('xt-connected'),
            children: [
              for (final m in _mcp)
                Builder(
                  builder: (context) {
                    final st = status?.where((y) => y.name == m.name).firstOrNull;
                    final e = catalogEntry(m.name);
                    return AutoTile(
                      key: Key('xt-mcp-${m.name}'),
                      on: st?.state == 'connected',
                      icon: e == null ? RgIcons.server : categoryIcon(e.category),
                      title: e?.name ?? m.name,
                      badge: st?.state == 'error' ? l.xtExtBroken : null,
                      text: scopeLabel(l, app, m.projectId),
                      state: serviceState(l, st),
                      onTap: () => _openServer(m),
                    );
                  },
                ),
            ],
          ),
          if (status?.any((x) => x.state == 'error') ?? false) AutoHelp(l.xtExtBrokenHelp),
        ],
        if (_media case final media?) ...[
          RulesSub(title: l.xtMediaTitle, lead: l.xtMediaPurpose),
          SwitchLine(
            key: const Key('xt-media-native'),
            title: l.xtMediaNativeTitle,
            help: l.xtMediaNativeHelp,
            on: media.native,
            onChanged: (on) async {
              try {
                await _client?.setMediaNative(on);
              } on ApiException catch (e) {
                if (mounted) setState(() => _error = e.message);
              }
              await _load();
            },
          ),
          AutoGrid(
            key: const Key('xt-media'),
            children: [
              for (final k in mediaKinds)
                if (mediaProviders.any((p) => p.models(k).isNotEmpty))
                  AutoTile(
                    key: Key('xt-media-tile-$k'),
                    on: mediaReady(media, k),
                    icon: mediaKindIcon(k),
                    title: mediaKindLabel(l, k),
                    text: mediaKindHelp(l, k),
                    state: mediaKindState(l, media, k),
                    onTap: () => _openMedia(k),
                  ),
            ],
          ),
        ],
        _Catalog(added: {for (final m in _mcp) m.name}, onOpen: _openCatalog),
        if (_installed.isNotEmpty) ...[
          RulesSub(title: l.xtExtSkills, lead: l.xtExtSkillsHelp),
          AutoGrid(
            key: const Key('xt-installed'),
            children: [
              for (final x in _installed)
                AutoTile(
                  key: Key('xt-inst-${x.scope}-${x.kind}-${x.name}'),
                  on: true,
                  icon: x.kind == 'tool' ? RgIcons.tool : RgIcons.book,
                  title: x.name,
                  badge: kindLabel(l, x.kind),
                  text: x.description,
                  state: installedScope(l, app, x.scope),
                  onTap: () => _openInstalled(x),
                ),
            ],
          ),
        ],
        RulesSub(title: l.xtXwOwnTitle, lead: l.xtXwOwnLead),
        AutoGrid(
          children: [
            AutoTile(
              key: const Key('xt-own-import'),
              icon: RgIcons.upload,
              title: l.xtSkillImport,
              text: l.xtXwImportText,
              onTap: _importSkill,
            ),
            AutoTile(
              key: const Key('xt-own-skill'),
              icon: RgIcons.plus,
              title: l.xtNewSkill,
              text: l.xtXwNewSkillText,
              onTap: _newSkill,
            ),
            AutoTile(
              key: const Key('xt-own-server'),
              icon: RgIcons.server,
              title: l.xtAddServer,
              text: l.xtXwServerText,
              onTap: _addServer,
            ),
          ],
        ),
        if (failed.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 12),
            child: Align(
              alignment: Alignment.centerLeft,
              child: TextButton.icon(
                key: const Key('xt-failed-open'),
                onPressed: () => _openFailed(failed),
                icon: RgIcon(RgIcons.shield, size: 16, color: c.accent),
                label: Text('${l.xtFailedTests} (${failed.length})'),
              ),
            ),
          ),
      ],
    );
  }
}

/// The gold buttons of the magic integration and extension (the page's `mg-cta`).
class MagicExtButton extends StatelessWidget {
  const MagicExtButton({super.key, required this.kind, required this.onTap});

  final String kind;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final c = RgColors.of(context);
    final god = godColor(context);
    final integration = kind == 'integration';
    return Padding(
      padding: const EdgeInsets.only(top: 6, bottom: 8),
      child: Material(
        color: Colors.transparent,
        child: Ink(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: godLine(context)),
            gradient: RadialGradient(
              center: Alignment.topLeft,
              radius: 1.6,
              colors: [Color.alphaBlend(god.withValues(alpha: .22), c.panel), c.panel],
              stops: const [0, .6],
            ),
          ),
          child: InkWell(
            key: Key('xt-magic-$kind'),
            borderRadius: BorderRadius.circular(22),
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  const GodOrb(size: 48),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          integration ? l.xtMxIntegration : l.xtMxExtension,
                          style: TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w800,
                            color: c.text,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          integration ? l.xtMxIntegrationTile : l.xtMxExtensionTile,
                          style: TextStyle(color: c.dim, fontSize: 13.5, height: 1.4),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// An agent's proposal, read in full: what it does, its files, how its tests went.
class _ProposalView extends StatefulWidget {
  const _ProposalView({required this.p, required this.onDone, required this.close});

  final ExtProposal p;
  final Future<void> Function() onDone;
  final void Function([void]) close;

  @override
  State<_ProposalView> createState() => _ProposalViewState();
}

class _ProposalViewState extends State<_ProposalView> {
  bool _comparing = false;
  bool _busy = false;
  String? _error;

  Future<void> _decide(bool approve) async {
    final c = AppScope.read(context).client;
    if (c == null) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await c.decideExtension(widget.p.id, approve: approve);
      await widget.onDone();
      widget.close();
    } on ApiException catch (e) {
      if (mounted) {
        setState(() {
          _busy = false;
          _error = e.message;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final c = RgColors.of(context);
    final app = AppScope.of(context);
    final p = widget.p;
    final update = p.isUpdate;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Facts(
          rows: [
            (l.xtXwKind, factText(update ? l.xtXwUpdates : kindLabel(l, p.kind))),
            (l.xtScope, factText(scopeLabel(l, app, p.projectId))),
            (l.xtXwAuthor, factText(whoOf(l, app, p.author))),
          ],
        ),
        if (p.description.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Text(p.description, style: TextStyle(color: c.text, height: 1.45)),
          ),
        if (p.summary != null && !(update && p.updateLine != null))
          _Card(title: l.xtXwSummary, text: p.summary!),
        if (p.scripts.isNotEmpty && p.status == 'pending' && p.author != 'human')
          WarnLine(l.xtXwScripts(p.scripts.join(', '))),
        if (update && p.updateLine != null)
          _Card(title: l.xtSvLineTitle, text: p.updateLine!, key: const Key('xt-update-line')),
        if (update && p.previousSkillMd != null && p.proposedSkillMd != null) ...[
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton(
              key: const Key('xt-proposal-compare'),
              onPressed: () => setState(() => _comparing = !_comparing),
              child: Text(_comparing ? l.xtSvHideCompare : l.xtSvCompareFull),
            ),
          ),
          if (_comparing) WordDiffView(before: p.previousSkillMd!, after: p.proposedSkillMd!),
          if (p.status == 'pending') AutoHelp(l.xtSvNextSession),
        ],
        if (update && p.previousSkillMd != null) ...[
          Details(title: l.xtXwPrevious, child: CodeBox(p.previousSkillMd!)),
          if (p.kept.isNotEmpty) AutoHelp(l.xtXwKeptFiles(p.kept.join(', '))),
        ],
        if (p.command != null) CodeBox(p.command!),
        if (p.body != null && p.body!.isNotEmpty)
          Padding(padding: const EdgeInsets.only(bottom: 8), child: SafeMarkdown(p.body!)),
        for (final f in p.files.entries) Details(title: f.key, mono: true, child: CodeBox(f.value)),
        if (p.report.isNotEmpty) AutoLb(l.xtXwTests),
        for (final r in p.report)
          AutoNotice(
            '${r.name}: ${r.detail.split('\n').first}',
            error: !r.passed,
            key: Key('xt-test-${r.name}'),
          ),
        if (_error != null) AutoNotice(_error!, error: true),
        WindowActs(
          children: p.status == 'pending'
              ? [
                  TextButton(
                    key: const Key('xt-reject'),
                    style: TextButton.styleFrom(foregroundColor: c.err),
                    onPressed: _busy ? null : () => _decide(false),
                    child: Text(l.xtReject),
                  ),
                  FilledButton(
                    key: const Key('xt-approve'),
                    onPressed: _busy ? null : () => _decide(true),
                    child: Text(l.xtApprove),
                  ),
                ]
              : [FilledButton(onPressed: () => widget.close(), child: Text(l.xtWzDoneBtn))],
        ),
      ],
    );
  }
}

/// A card with a title and its text (the page's `wz-card wz-left`).
class _Card extends StatelessWidget {
  const _Card({super.key, required this.title, required this.text});

  final String title;
  final String text;

  @override
  Widget build(BuildContext context) {
    final c = RgColors.of(context);
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: c.panel,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: c.line),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(color: c.text, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 4),
          Text(text, style: TextStyle(color: c.text, height: 1.45)),
        ],
      ),
    );
  }
}

/// The catalog: a search, the kinds as chips, one square per service. On a phone one kind at a
/// time (the first at the start), or what the search finds among all of them.
class _Catalog extends StatefulWidget {
  const _Catalog({required this.added, required this.onOpen});

  final Set<String> added;
  final ValueChanged<CatalogEntry> onOpen;

  @override
  State<_Catalog> createState() => _CatalogState();
}

class _CatalogState extends State<_Catalog> {
  String _q = '';
  String _category = '';

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final phone = !isWide(context);
    final words = _q.trim().toLowerCase();
    final kind = phone
        ? (words.isNotEmpty ? '' : (_category.isEmpty ? catalogCategories.first : _category))
        : _category;
    final lang = l.localeName.startsWith('it') ? 'it' : 'en';
    final shown = [
      for (final e in mcpCatalog)
        if ((kind.isEmpty || e.category == kind) &&
            (words.isEmpty ||
                '${e.name} ${e.description(lang)} ${e.id}'.toLowerCase().contains(words)))
          e,
    ]..sort((x, y) => (y.official ? 1 : 0) - (x.official ? 1 : 0));
    final cats = phone ? catalogCategories : ['', ...catalogCategories];
    return Column(
      key: const Key('xt-catalog'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        RulesSub(title: l.xtExtCatalog, lead: l.xtExtCatalogHelp),
        SearchField(
          hint: l.xtExtSearch,
          value: _q,
          fieldKey: const Key('xt-search'),
          onChanged: (v) => setState(() => _q = v),
        ),
        const SizedBox(height: 8),
        AutoChips<String>(
          options: [for (final c in cats) (c, categoryLabel(l, c))],
          value: [kind],
          keyOf: (c) => 'xt-cat-${c.isEmpty ? 'all' : c}',
          onChanged: (v) => setState(() {
            _category = v.firstOrNull ?? '';
            if (phone) _q = '';
          }),
        ),
        const SizedBox(height: 10),
        if (shown.isEmpty) AutoHelp(l.xtExtNothingFound),
        AutoGrid(
          children: [
            for (final e in shown)
              AutoTile(
                key: Key('xt-cat-entry-${e.id}'),
                on: widget.added.contains(e.id),
                icon: categoryIcon(e.category),
                title: e.name,
                badge: e.official ? l.xtExtOfficial : null,
                text: e.description(lang),
                state: widget.added.contains(e.id) ? l.xtExtAdded : null,
                onTap: () => widget.onOpen(e),
              ),
          ],
        ),
      ],
    );
  }
}

/// A catalog entry's window: what it is, how it signs in, and adding it.
class _CatalogWindow extends StatelessWidget {
  const _CatalogWindow({
    required this.entry,
    required this.added,
    required this.close,
    required this.onAdded,
  });

  final CatalogEntry entry;
  final bool added;
  final void Function([void]) close;
  final Future<void> Function(bool signsIn) onAdded;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final c = RgColors.of(context);
    final lang = l.localeName.startsWith('it') ? 'it' : 'en';
    final e = entry;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: Text(e.description(lang), style: TextStyle(color: c.text, height: 1.45)),
        ),
        Facts(
          rows: [
            (l.xtXwSource, factText(e.official ? l.xtExtOfficial : l.xtExtCommunity)),
            (
              l.xtXwSignIn,
              factText(
                '${_authLabel(l, e.authType)}${e.unverified ? ' · ${l.xtExtUnverifiedShort}' : ''}',
              ),
            ),
          ],
        ),
        if (e.homepage.isNotEmpty) OutsideLink(label: l.xtExtMore, url: e.homepage),
        if (added) ...[
          AutoNotice(l.xtExtAdded),
          WindowActs(
            children: [FilledButton(onPressed: () => close(), child: Text(l.xtWzDoneBtn))],
          ),
        ] else
          _AddForm(entry: e, onDone: onAdded, onCancel: () => close()),
      ],
    );
  }
}

/// Adding one entry: where it works and what it needs from the person (a key, their app…).
class _AddForm extends StatefulWidget {
  const _AddForm({required this.entry, required this.onDone, required this.onCancel});

  final CatalogEntry entry;
  final Future<void> Function(bool signsIn) onDone;
  final VoidCallback onCancel;

  @override
  State<_AddForm> createState() => _AddFormState();
}

class _AddFormState extends State<_AddForm> {
  String _scope = '';
  String _key = '';
  String _url = '';
  String _clientId = '';
  String _clientSecret = '';
  final _fields = <String, String>{};
  bool _busy = false;
  String? _error;

  CatalogEntry get e => widget.entry;

  bool get _ready =>
      (!e.needsKey || _key.trim().isNotEmpty) &&
      (e.userUrl == null || _url.trim().isNotEmpty) &&
      (e.authType != 'app' ||
          (_clientId.trim().isNotEmpty &&
              (e.auth['secret'] != true || _clientSecret.trim().isNotEmpty))) &&
      (e.authType != 'fields' ||
          e.fields.every((f) => f.optional || (_fields[f.env] ?? '').trim().isNotEmpty));

  Future<void> _add() async {
    final c = AppScope.read(context).client;
    if (c == null) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final config = catalogConfig(
        e,
        CatalogInput(
          key: _key,
          url: _url,
          fields: Map.of(_fields),
          clientId: _clientId,
          clientSecret: _clientSecret,
        ),
      );
      await c.setMcp({'name': e.id, 'projectId': _scope.isEmpty ? null : _scope, ...config});
      await widget.onDone(e.signsIn);
    } on FormatException catch (err) {
      if (mounted) setState(() => _error = err.message);
    } on ApiException catch (err) {
      if (mounted) setState(() => _error = err.message);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final app = AppScope.of(context);
    final lang = l.localeName.startsWith('it') ? 'it' : 'en';
    final a = e.auth;
    final origin = app.client?.base.origin ?? '';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (e.note(lang) case final n?) WarnLine(n),
        if (e.unverified) AutoHelp(l.xtExtUnverified),
        if (e.guide != null)
          Details(
            key: const Key('xt-guide'),
            open: e.authType == 'app' || e.authType == 'fields',
            title: e.authType == 'app' ? l.xtExtAppGuide(e.name) : l.xtExtGuide(e.name),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _GuideSteps(
                  steps: guideSteps(e.guide, lang),
                  redirect: '$origin/api/extensions/oauth/callback',
                ),
                if (e.authType == 'app' && a['consoleUrl'] is String)
                  OutsideLink(label: l.xtExtAppConsole(e.name), url: a['consoleUrl'] as String),
              ],
            ),
          ),
        PickBox<String>(
          label: l.xtExtWhere,
          help: l.xtExtWhereHelp,
          boxKey: const Key('xt-where'),
          options: [
            ('', l.xtExtEverywhere),
            for (final p in app.projects) (p.id, l.xtExtOnlyProject(p.name)),
          ],
          value: _scope,
          onChanged: (v) => setState(() => _scope = v),
        ),
        const SizedBox(height: 10),
        if (e.userUrl case final u?)
          AutoField(
            label: l.xtExtServerUrl(e.name),
            help: l.xtExtServerUrlHelp,
            hint: '${u['example'] ?? ''}',
            value: _url,
            fieldKey: const Key('xt-user-url'),
            onChanged: (v) => setState(() => _url = v),
          ),
        if (e.authType == 'app') ...[
          AutoField(
            label: l.xtExtClientId,
            value: _clientId,
            fieldKey: const Key('xt-client-id'),
            onChanged: (v) => setState(() => _clientId = v),
          ),
          const SizedBox(height: 10),
          SecretField(
            label: a['secret'] == true ? l.xtExtClientSecret : l.xtExtClientSecretOptional,
            help: l.xtExtKeyHelp,
            fieldKey: const Key('xt-client-secret'),
            onChanged: (v) => setState(() => _clientSecret = v),
          ),
        ],
        if (e.authType == 'fields')
          for (final f in e.fields)
            f.secret
                ? SecretField(
                    label: f.label(lang),
                    hint: f.example,
                    fieldKey: Key('xt-field-${f.env}'),
                    onChanged: (v) => setState(() => _fields[f.env] = v),
                  )
                : Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: AutoField(
                      label: f.label(lang),
                      hint: f.example,
                      value: _fields[f.env] ?? '',
                      fieldKey: Key('xt-field-${f.env}'),
                      onChanged: (v) => setState(() => _fields[f.env] = v),
                    ),
                  ),
        if (e.needsKey) ...[
          SecretField(
            label: l.xtExtKey(e.name),
            help: l.xtExtKeyHelp,
            hint: a['keyExample'] as String?,
            fieldKey: const Key('xt-key'),
            onChanged: (v) => setState(() => _key = v),
          ),
          if (a['keyUrl'] is String)
            OutsideLink(label: l.xtExtKeyWhere(e.name), url: a['keyUrl'] as String),
        ],
        if (e.signsIn) AutoHelp(l.xtExtOauthHelp(e.name)),
        if (_error != null) AutoNotice(_error!, error: true, key: const Key('xt-add-error')),
        WindowActs(
          children: [
            TextButton(onPressed: widget.onCancel, child: Text(l.xtCancel)),
            FilledButton(
              key: const Key('xt-add'),
              onPressed: _busy || !_ready ? null : _add,
              child: Text(e.signsIn ? l.xtExtAddAndConnect : l.xtExtAdd),
            ),
          ],
        ),
      ],
    );
  }
}

/// A guide in steps, with the server's return address ready to copy where it is needed.
class _GuideSteps extends StatelessWidget {
  const _GuideSteps({required this.steps, required this.redirect});

  final List<String> steps;
  final String redirect;

  @override
  Widget build(BuildContext context) {
    final c = RgColors.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final (i, step) in steps.indexed)
          Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  width: 22,
                  child: Text('${i + 1}.', style: TextStyle(color: c.dim)),
                ),
                Expanded(
                  child: Builder(
                    builder: (context) {
                      final parts = step.split('{redirect}');
                      if (parts.length < 2) {
                        return Text(step, style: TextStyle(color: c.text, height: 1.4));
                      }
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(parts.first, style: TextStyle(color: c.text, height: 1.4)),
                          Row(
                            children: [
                              Expanded(child: MonoText(redirect)),
                              CopyButton(text: redirect, buttonKey: const Key('xt-copy-redirect')),
                            ],
                          ),
                          if (parts.last.isNotEmpty)
                            Text(parts.last, style: TextStyle(color: c.text, height: 1.4)),
                        ],
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

/// A server added: its state and address; sign in again or remove it.
class _ServerWindow extends StatefulWidget {
  const _ServerWindow({
    required this.server,
    required this.state,
    required this.scope,
    required this.onRemove,
    required this.onConnect,
    required this.close,
  });

  final McpServer server;
  final McpState? state;
  final String scope;
  final Future<void> Function() onRemove;
  final Future<void> Function() onConnect;
  final void Function([void]) close;

  @override
  State<_ServerWindow> createState() => _ServerWindowState();
}

class _ServerWindowState extends State<_ServerWindow> {
  String? _error;

  Future<void> _run(Future<void> Function() f) async {
    setState(() => _error = null);
    try {
      await f();
    } on ApiException catch (e) {
      if (mounted) setState(() => _error = e.message);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final c = RgColors.of(context);
    final s = widget.state;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Facts(
          rows: [
            (l.xtScope, factText(widget.scope)),
            (l.xtXwState, factText(serviceState(l, s))),
            (l.xtXwAddress, MonoText(widget.server.address)),
          ],
        ),
        if (s?.state == 'error' && s?.error != null) AutoNotice(s!.error!, error: true),
        if (s?.state == 'error') AutoHelp(l.xtExtBrokenHelp),
        if (_error != null) AutoNotice(_error!, error: true),
        WindowActs(
          children: [
            TextButton(
              key: const Key('xt-server-remove'),
              style: TextButton.styleFrom(foregroundColor: c.err),
              onPressed: () => _run(widget.onRemove),
              child: Text(l.xtRemove),
            ),
            if (s?.state == 'login')
              FilledButton(
                key: const Key('xt-server-connect'),
                onPressed: () => _run(widget.onConnect),
                child: Text(l.xtExtConnect),
              )
            else
              FilledButton(onPressed: () => widget.close(), child: Text(l.xtWzDoneBtn)),
          ],
        ),
      ],
    );
  }
}

/// Where a hand-made thing works: every project, or one.
List<(String, String)> _scopes(AppLocalizations l, AppController app) => [
  ('', l.xtScopePlatform),
  for (final p in app.projects) (p.id, p.name),
];

/// A skill written by hand: its name, what it is for, where it works, its instructions.
class _NewSkill extends StatefulWidget {
  const _NewSkill({required this.onDone, required this.close});

  final VoidCallback onDone;
  final void Function([void]) close;

  @override
  State<_NewSkill> createState() => _NewSkillState();
}

class _NewSkillState extends State<_NewSkill> {
  String _name = '';
  String _description = '';
  String _body = '';
  String _scope = '';
  bool _busy = false;
  String? _error;

  static final _nameRe = RegExp(r'^[a-z0-9][a-z0-9-]{1,48}$');

  bool get _ok =>
      _nameRe.hasMatch(_name) && _description.trim().length >= 10 && _body.trim().length >= 20;

  Future<void> _create() async {
    final c = AppScope.read(context).client;
    if (c == null) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await c.createSkill(
        projectId: _scope.isEmpty ? null : _scope,
        name: _name,
        description: _description,
        body: _body,
      );
      widget.onDone();
    } on ApiException catch (e) {
      if (mounted) setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final app = AppScope.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AutoField(
          label: l.xtName,
          help: l.xtXwSkillNameHelp,
          value: _name,
          mono: true,
          fieldKey: const Key('xt-skill-name'),
          onChanged: (v) => setState(() => _name = v),
        ),
        const SizedBox(height: 10),
        AutoField(
          label: l.xtDescription,
          value: _description,
          fieldKey: const Key('xt-skill-description'),
          onChanged: (v) => setState(() => _description = v),
        ),
        const SizedBox(height: 10),
        PickBox<String>(
          label: l.xtScope,
          boxKey: const Key('xt-skill-scope'),
          options: _scopes(l, app),
          value: _scope,
          onChanged: (v) => setState(() => _scope = v),
        ),
        const SizedBox(height: 10),
        AutoField(
          label: l.xtInstructions,
          value: _body,
          lines: 7,
          fieldKey: const Key('xt-skill-body'),
          onChanged: (v) => setState(() => _body = v),
        ),
        if (_error != null) AutoNotice(_error!, error: true),
        WindowActs(
          children: [
            TextButton(onPressed: () => widget.close(), child: Text(l.xtCancel)),
            FilledButton(
              key: const Key('xt-skill-create'),
              onPressed: _busy || !_ok ? null : _create,
              child: Text(l.xtCreate),
            ),
          ],
        ),
      ],
    );
  }
}

/// A server not in the catalog: its address (or command), and how it signs in.
class _McpForm extends StatefulWidget {
  const _McpForm({required this.onDone, required this.close});

  final VoidCallback onDone;
  final void Function([void]) close;

  @override
  State<_McpForm> createState() => _McpFormState();
}

class _McpFormState extends State<_McpForm> {
  String _name = '';
  String _type = 'http';
  String _command = '';
  String _args = '';
  String _url = '';
  bool _oauth = false;
  String _token = '';
  String _scope = '';
  bool _busy = false;
  String? _error;

  static final _nameRe = RegExp(r'^[a-z0-9][a-z0-9-]{0,30}$');

  bool get _ok =>
      _nameRe.hasMatch(_name) &&
      (_type == 'http' ? Uri.tryParse(_url)?.hasScheme == true : _command.trim().isNotEmpty);

  Future<void> _add() async {
    final c = AppScope.read(context).client;
    if (c == null) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    final transport = _type == 'http'
        ? {'type': 'http', 'url': _url.trim(), if (_oauth) 'oauth': true}
        : {
            'type': 'stdio',
            'command': _command.trim(),
            'args': [
              for (final a in _args.split(' '))
                if (a.isNotEmpty) a,
            ],
          };
    try {
      await c.setMcp({
        'name': _name,
        'projectId': _scope.isEmpty ? null : _scope,
        'transport': transport,
        if (_type == 'http' && !_oauth && _token.trim().isNotEmpty)
          'secrets': {
            'headers': {'Authorization': 'Bearer ${_token.trim()}'},
          },
      });
      widget.onDone();
    } on ApiException catch (e) {
      if (mounted) setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final app = AppScope.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AutoField(
          label: l.xtName,
          value: _name,
          mono: true,
          fieldKey: const Key('xt-server-name'),
          onChanged: (v) => setState(() => _name = v),
        ),
        const SizedBox(height: 10),
        PickBox<String>(
          label: l.xtScope,
          boxKey: const Key('xt-server-scope'),
          options: _scopes(l, app),
          value: _scope,
          onChanged: (v) => setState(() => _scope = v),
        ),
        AutoLb(l.xtExtTransport),
        RgChoice<String>(
          options: [('http', l.xtExtTransportHttp), ('stdio', l.xtExtTransportStdio)],
          value: _type,
          keyOf: (v) => 'xt-transport-$v',
          onChanged: (v) => setState(() => _type = v),
        ),
        const SizedBox(height: 10),
        if (_type == 'http') ...[
          AutoField(
            label: l.xtUrl,
            value: _url,
            fieldKey: const Key('xt-server-url'),
            onChanged: (v) => setState(() => _url = v),
          ),
          SwitchLine(
            key: const Key('xt-server-oauth'),
            title: l.xtExtManualOauth,
            on: _oauth,
            onChanged: (v) => setState(() => _oauth = v),
          ),
          if (!_oauth)
            SecretField(
              label: l.xtExtManualToken,
              fieldKey: const Key('xt-server-token'),
              onChanged: (v) => setState(() => _token = v),
            ),
        ] else ...[
          AutoField(
            label: l.xtCommand,
            value: _command,
            mono: true,
            fieldKey: const Key('xt-server-command'),
            onChanged: (v) => setState(() => _command = v),
          ),
          const SizedBox(height: 10),
          AutoField(
            label: l.xtArgs,
            value: _args,
            mono: true,
            fieldKey: const Key('xt-server-args'),
            onChanged: (v) => setState(() => _args = v),
          ),
        ],
        if (_error != null) AutoNotice(_error!, error: true),
        WindowActs(
          children: [
            TextButton(onPressed: () => widget.close(), child: Text(l.xtCancel)),
            FilledButton(
              key: const Key('xt-server-add'),
              onPressed: _busy || !_ok ? null : _add,
              child: Text(l.xtAddServer),
            ),
          ],
        ),
      ],
    );
  }
}

/// A shared skill (.zip) into the platform or a project; asks before replacing one.
class _ImportSkill extends StatefulWidget {
  const _ImportSkill({required this.pick, required this.onDone, required this.close});

  final PickZip pick;
  final Future<void> Function() onDone;
  final void Function([void]) close;

  @override
  State<_ImportSkill> createState() => _ImportSkillState();
}

class _ImportSkillState extends State<_ImportSkill> {
  String _scope = 'platform';
  String? _done;
  String? _error;
  bool _busy = false;

  Future<void> _go() async {
    final c = AppScope.read(context).client;
    if (c == null) return;
    final l = AppLocalizations.of(context);
    final file = await widget.pick();
    if (file == null || !mounted) return;
    setState(() {
      _busy = true;
      _done = null;
      _error = null;
    });
    try {
      String name;
      try {
        name = await c.importSkill(file.$2, _scope);
      } on ApiException catch (e) {
        if (e.status != 409 || !mounted) rethrow;
        final yes = await askConfirm(
          context,
          title: l.xtSkillImport,
          body: l.xtSkillReplaceConfirm,
          yes: l.xtSkillImport,
        );
        if (!yes) return;
        name = await c.importSkill(file.$2, _scope, replace: true);
      }
      if (mounted) setState(() => _done = name);
      await widget.onDone();
    } on ApiException catch (e) {
      if (mounted) setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final app = AppScope.of(context);
    final c = RgColors.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Text(l.xtSkillImportHelp, style: TextStyle(color: c.dim, height: 1.45)),
        ),
        PickBox<String>(
          label: l.xtSkillImportWhere,
          boxKey: const Key('xt-import-where'),
          options: [
            ('platform', l.xtScopePlatform),
            for (final p in app.projects) ('project:${p.id}', p.name),
          ],
          value: _scope,
          onChanged: (v) => setState(() => _scope = v),
        ),
        if (_done != null) AutoNotice(l.xtSkillImported(_done!), key: const Key('xt-imported')),
        if (_error != null) AutoNotice(_error!, error: true),
        WindowActs(
          children: [
            TextButton(
              onPressed: () => widget.close(),
              child: Text(_done != null ? l.xtWzDoneBtn : l.xtCancel),
            ),
            FilledButton.icon(
              key: const Key('xt-import-pick'),
              onPressed: _busy ? null : _go,
              icon: const RgIcon(RgIcons.upload, size: 17, color: Colors.white),
              label: Text(l.xtSkillImportFile),
            ),
          ],
        ),
      ],
    );
  }
}

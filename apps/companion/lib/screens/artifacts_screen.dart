// Settings › Artifacts in the app (G42.2), as the page's `Artifacts.tsx`: every artifact of the
// person in every place they see (God's folder, the assistants' desk, every project), grouped by
// place, with its facts, what it asks for (granted with `ask`'s spending and cap and «Take back»,
// or «Allow») and «Open» (the Canvas), «Export» (a `.rgartifact`, with its saved data when the
// person switches it on, or the bare HTML with its warning, saved where the person picks), «Delete»
// (our window, then the file explorer's own deletion) and «Import» (a `.rgartifact` into the place
// the person picks). An archived project's artifacts are read only. Native: no web view here.
import 'dart:async';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../api/artifacts.dart';
import '../app_state.dart';
import '../l10n/app_localizations.dart';
import '../theme/colors.dart';
import '../ui/chat/request_cards.dart' show capUsd;
import '../ui/dialogs.dart';
import '../ui/icons.dart';
import '../ui/settings_kit.dart';
import 'canvas_screen.dart';
import 'new_agent_screen.dart' show RgSwitch;

Future<void> openArtifacts(BuildContext context) =>
    Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => const ArtifactsScreen()));

class ArtifactsScreen extends StatefulWidget {
  const ArtifactsScreen({super.key});

  @override
  State<ArtifactsScreen> createState() => _ArtifactsScreenState();
}

class _ArtifactsScreenState extends State<ArtifactsScreen> {
  List<ArtifactInfo>? _list;
  String? _error;
  String? _note;
  bool _started = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) return;
    _started = true;
    unawaited(_load());
  }

  Future<void> _load() async {
    final c = AppScope.read(context).client;
    if (c == null) return;
    try {
      final list = await c.artifacts();
      if (mounted) setState(() => _list = list);
    } on Object catch (e) {
      if (mounted) {
        setState(() {
          _error = '$e';
          _list ??= const [];
        });
      }
    }
  }

  /// A place's name as the page says it: God's folder and the desk in the person's language.
  String _placeName(String scope, String fallback) {
    final l = AppLocalizations.of(context);
    if (scope == 'platform') return l.cvArPlacePlatform;
    if (scope == 'assistants') return l.cvArPlaceAssistants;
    final id = scope.replaceFirst('project:', '');
    final p = AppScope.read(context).projects.where((p) => p.id == id).firstOrNull;
    return p?.name ?? fallback;
  }

  Future<void> _act(Future<void> Function() f) async {
    try {
      await f();
      await _load();
    } on Object catch (e) {
      if (mounted) setState(() => _error = '$e');
    }
  }

  Future<void> _import() async {
    final l = AppLocalizations.of(context);
    final picked = await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: const ['rgartifact'],
    );
    final f = picked.firstOrNull;
    if (f == null || !mounted) return;
    if (!isRgArtifact(f.name)) {
      setState(() => _error = l.cvArWhereLead);
      return;
    }
    final bytes = await f.readAsBytes();
    if (!mounted) return;
    final app = AppScope.read(context);
    final places = [
      for (final p in app.projects)
        if (!p.archived) (scope: 'project:${p.id}', name: p.name),
      (scope: 'platform', name: l.cvArPlacePlatform),
      (scope: 'assistants', name: l.cvArPlaceAssistants),
    ];
    final place = await showRgWindow<({String scope, String name})>(
      context: context,
      builder: (context) => _WhereWindow(file: f.name, places: places),
    );
    if (place == null || !mounted) return;
    final c = app.client;
    try {
      if (c == null) throw StateError('Not connected');
      final r = await c.artifactImport(place.scope, bytes);
      if (!mounted) return;
      setState(() {
        _error = null;
        _note = [
          l.cvArImported(r.name, place.name),
          if (r.dataImported) l.cvArDataImported else if (r.dataIgnored) l.cvArDataIgnored,
        ].join(' ');
      });
      await _load();
    } on Object catch (e) {
      if (mounted) setState(() => _error = '$e');
    }
  }

  Future<void> _export(ArtifactInfo a) async {
    final l = AppLocalizations.of(context);
    final c = AppScope.read(context).client;
    final how = await showRgWindow<({bool html, bool data})>(
      context: context,
      builder: (context) => _ExportWindow(a: a),
    );
    if (how == null || c == null || !mounted) return;
    try {
      final bytes = await c.artifactExport(a.scope, a.path, html: how.html, data: how.data);
      final name = how.html
          ? a.file
          : a.file.replaceFirst(RegExp(r'\.html?$', caseSensitive: false), '.rgartifact');
      final saved = await FilePicker.saveFile(fileName: name, bytes: bytes);
      if (saved != null && mounted) {
        ScaffoldMessenger.maybeOf(context)
            ?.showSnackBar(SnackBar(content: Text(l.embedSaved(name))));
      }
    } on Object catch (e) {
      if (mounted) setState(() => _error = '$e');
    }
  }

  Future<void> _delete(ArtifactInfo a) async {
    final l = AppLocalizations.of(context);
    final yes = await askConfirm(
      context,
      title: l.cvArDeleteQ(a.name),
      body: l.cvArDeleteText,
      yes: l.cvArDelete,
      danger: true,
    );
    if (!yes || !mounted) return;
    final c = AppScope.read(context).client;
    await _act(() => (c ?? (throw StateError('Not connected'))).deleteFile(a.scope, a.path));
  }

  @override
  Widget build(BuildContext context) {
    final c = RgColors.of(context);
    final l = AppLocalizations.of(context);
    final list = _list;
    return SettingsScaffold(
      title: l.cvArSection,
      backKey: const Key('artifacts-back'),
      backLabel: l.back,
      listKey: const Key('artifacts-list'),
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
          child: Text(l.cvArLead, style: TextStyle(color: c.dim, fontSize: 13.5, height: 1.4)),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
          child: Align(
            alignment: Alignment.centerLeft,
            child: FilledButton.icon(
              key: const Key('artifacts-import'),
              onPressed: list == null ? null : _import,
              icon: const RgIcon(RgIcons.upload, size: 16, color: Colors.white),
              label: Text(l.cvArImport),
            ),
          ),
        ),
        if (_note != null)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            child: NoticeBanner(key: const Key('artifacts-note'), text: _note!),
          ),
        if (_error != null)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            child: NoticeBanner(key: const Key('artifacts-error'), text: _error!, error: true),
          ),
        if (list == null)
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(l.loading, style: TextStyle(color: c.dim)),
          ),
        if (list != null && list.isEmpty) _empty(context),
        for (final (scope, items) in artifactGroups(list ?? const [])) ...[
          SectionHead(_placeName(scope, items.first.place)),
          SettingsCard(
            key: Key('artifacts-place-$scope'),
            children: [
              for (final (i, a) in items.indexed) ...[
                if (i > 0) Divider(height: 1, color: c.line),
                _ArtifactRow(
                  a: a,
                  onOpen: () => openCanvas(context, scope: a.scope, path: a.path, title: a.file),
                  onExport: () => _export(a),
                  onDelete: () => _delete(a),
                  onGrant: (word, cap) => _act(
                    () =>
                        AppScope.read(context).client!
                            .artifactGrant(a.scope, a.path, word, capUsd: cap),
                  ),
                  onRevoke: (word) => _act(
                    () => AppScope.read(context).client!.artifactRevoke(a.scope, a.path, word),
                  ),
                ),
              ],
            ],
          ),
        ],
      ],
    );
  }

  Widget _empty(BuildContext context) {
    final c = RgColors.of(context);
    final l = AppLocalizations.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(0, 16, 0, 0),
      child: SettingsCard(
        key: const Key('artifacts-empty'),
        children: [
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(color: c.accentDim, shape: BoxShape.circle),
                  child: Center(child: RgIcon(RgIcons.archive, size: 26, color: c.accent)),
                ),
                const SizedBox(height: 12),
                Text(
                  l.cvArEmptyTitle,
                  style: TextStyle(color: c.text, fontWeight: FontWeight.w700, fontSize: 15),
                ),
                const SizedBox(height: 6),
                Text(
                  l.cvArEmpty1,
                  textAlign: TextAlign.center,
                  style: TextStyle(color: c.dim),
                ),
                const SizedBox(height: 4),
                Text(
                  l.cvArEmpty2,
                  textAlign: TextAlign.center,
                  style: TextStyle(color: c.dim),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// One artifact: its name and facts, what it asks for, then Open, Export, Delete.
class _ArtifactRow extends StatelessWidget {
  const _ArtifactRow({
    required this.a,
    required this.onOpen,
    required this.onExport,
    required this.onDelete,
    required this.onGrant,
    required this.onRevoke,
  });

  final ArtifactInfo a;
  final VoidCallback onOpen;
  final VoidCallback onExport;
  final VoidCallback onDelete;
  final void Function(String word, double? cap) onGrant;
  final void Function(String word) onRevoke;

  @override
  Widget build(BuildContext context) {
    final c = RgColors.of(context);
    final l = AppLocalizations.of(context);
    final app = AppScope.read(context);
    String agentName(String? id) =>
        app.agents.where((x) => x.id == id).firstOrNull?.name ?? id ?? '';
    final day = DateTime.tryParse(a.modifiedAt)?.toLocal();
    final facts = [
      a.file,
      if (a.version != null) l.cvArVersion('${a.version}') else l.cvArNoHeader,
      if (a.libs.isNotEmpty) l.cvArLibs(a.libs.join(', ')),
      if (a.from != null) l.cvArFrom(agentName(a.from)),
      if (a.hasData) l.cvArHasData,
      artifactBytes(a.size),
      if (day != null) DateFormat.yMMMd(l.localeName).format(day),
    ];
    final small = ButtonStyle(
      visualDensity: VisualDensity.compact,
      padding: WidgetStateProperty.all(const EdgeInsets.symmetric(horizontal: 10)),
    );
    return Padding(
      key: Key('artifact-${a.scope}:${a.path}'),
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              RgIcon(RgIcons.code, size: 15, color: c.accent),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  a.name,
                  style: TextStyle(color: c.text, fontWeight: FontWeight.w700, fontSize: 15),
                ),
              ),
              if (a.pendingRun) ...[
                const SizedBox(width: 8),
                _Chip(text: l.cvArPending, color: c.warn),
              ],
            ],
          ),
          const SizedBox(height: 4),
          Text.rich(
            TextSpan(
              text: facts.join(' · '),
              children: [
                if (a.readOnly)
                  TextSpan(
                    text: ' · ${l.cvArReadOnly}',
                    style: TextStyle(color: c.warn),
                  ),
              ],
            ),
            style: TextStyle(color: c.dim, fontSize: 12.5, height: 1.35),
          ),
          if (a.wanted.isNotEmpty)
            _Permissions(a: a, agentName: agentName, onGrant: onGrant, onRevoke: onRevoke),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              OutlinedButton.icon(
                key: Key('artifact-open-${a.path}'),
                style: small,
                onPressed: onOpen,
                icon: RgIcon(RgIcons.external, size: 14, color: c.text),
                label: Text(l.cvArOpen),
              ),
              OutlinedButton.icon(
                key: Key('artifact-export-${a.path}'),
                style: small,
                onPressed: onExport,
                icon: RgIcon(RgIcons.download, size: 14, color: c.text),
                label: Text(l.cvArExport),
              ),
              if (!a.readOnly)
                OutlinedButton.icon(
                  key: Key('artifact-delete-${a.path}'),
                  style: small.copyWith(
                    foregroundColor: WidgetStateProperty.all(c.err),
                    side: WidgetStateProperty.all(BorderSide(color: c.err.withValues(alpha: .5))),
                  ),
                  onPressed: onDelete,
                  icon: RgIcon(RgIcons.trash, size: 14, color: c.err),
                  label: Text(l.cvArDelete),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

/// What an artifact asks for, each with its state: granted (with `ask`'s spending and cap) and
/// «Take back», or «Allow». Granted only here or on the first use's card, never by the file.
class _Permissions extends StatefulWidget {
  const _Permissions({
    required this.a,
    required this.agentName,
    required this.onGrant,
    required this.onRevoke,
  });

  final ArtifactInfo a;
  final String Function(String? id) agentName;
  final void Function(String word, double? cap) onGrant;
  final void Function(String word) onRevoke;

  @override
  State<_Permissions> createState() => _PermissionsState();
}

class _PermissionsState extends State<_Permissions> {
  double _cap = artifactAskCapDefault;

  @override
  Widget build(BuildContext context) {
    final c = RgColors.of(context);
    final l = AppLocalizations.of(context);
    final a = widget.a;
    return Container(
      margin: const EdgeInsets.only(top: 10),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: c.panel2,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: c.line),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l.cvArPerms,
            style: TextStyle(color: c.dim, fontSize: 12, fontWeight: FontWeight.w700),
          ),
          for (final cap in a.wanted) _one(context, cap),
        ],
      ),
    );
  }

  Widget _one(BuildContext context, ArtifactCapability cap) {
    final c = RgColors.of(context);
    final l = AppLocalizations.of(context);
    final a = widget.a;
    final word = cap.word;
    final g = a.grantOf(word);
    final isAsk = word == 'ask';
    final what = capabilitySentence(
      l.localeName,
      word,
      g?.agentId != null || a.from != null ? widget.agentName(g?.agentId ?? a.from) : null,
    );
    return Padding(
      key: Key('artifact-perm-${a.path}-$word'),
      padding: const EdgeInsets.only(top: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.only(top: 2),
                child: RgIcon(RgIcons.shield, size: 14, color: g != null ? c.ok : c.dim),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  l.cvArWants(what),
                  style: TextStyle(color: c.text, fontSize: 13, height: 1.35),
                ),
              ),
              const SizedBox(width: 6),
              _Chip(
                text: g != null ? l.cvArPermGranted : l.cvArPermNot,
                color: g != null ? c.ok : c.dim,
              ),
            ],
          ),
          if (g != null && isAsk && g.capUsd != null)
            Padding(
              padding: const EdgeInsets.only(left: 20, top: 2),
              child: Text(
                l.cvArSpent(capUsd(g.spentUsd ?? 0), capUsd(g.capUsd!)),
                style: TextStyle(color: c.dim, fontSize: 12),
              ),
            ),
          if (!a.readOnly)
            Padding(
              padding: const EdgeInsets.only(left: 20, top: 6),
              child: Wrap(
                spacing: 6,
                runSpacing: 6,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  if (isAsk)
                    for (final x in artifactAskCaps)
                      _CapPill(
                        key: Key('artifact-cap-${a.path}-$x'),
                        label: capUsd(x),
                        on: (g?.capUsd ?? _cap) == x,
                        onTap: () {
                          setState(() => _cap = x);
                          // Granted already: the new cap applies at once.
                          if (g != null) widget.onGrant(word, x);
                        },
                      ),
                  if (g != null)
                    TextButton(
                      key: Key('artifact-revoke-${a.path}-$word'),
                      onPressed: () => widget.onRevoke(word),
                      child: Text(l.cvArRevoke),
                    )
                  else
                    Tooltip(
                      message: a.pendingRun ? l.cvArPending : '',
                      child: TextButton(
                        key: Key('artifact-grant-${a.path}-$word'),
                        onPressed: a.pendingRun
                            ? null
                            : () => widget.onGrant(word, isAsk ? _cap : null),
                        child: Text(l.cvArGrant),
                      ),
                    ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip({required this.text, required this.color});

  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
    decoration: BoxDecoration(
      color: color.withValues(alpha: .12),
      borderRadius: BorderRadius.circular(999),
      border: Border.all(color: color.withValues(alpha: .4)),
    ),
    child: Text(
      text,
      style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w700),
    ),
  );
}

class _CapPill extends StatelessWidget {
  const _CapPill({super.key, required this.label, required this.on, required this.onTap});

  final String label;
  final bool on;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = RgColors.of(context);
    return Semantics(
      selected: on,
      button: true,
      child: Material(
        color: on ? c.accent : c.panel,
        shape: StadiumBorder(side: BorderSide(color: on ? c.accent : c.line)),
        child: InkWell(
          customBorder: const StadiumBorder(),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            child: Text(label, style: TextStyle(color: on ? Colors.white : c.text, fontSize: 12)),
          ),
        ),
      ),
    );
  }
}

/// «Export»: the `.rgartifact` (its saved data only when switched on) or the bare HTML.
class _ExportWindow extends StatefulWidget {
  const _ExportWindow({required this.a});

  final ArtifactInfo a;

  @override
  State<_ExportWindow> createState() => _ExportWindowState();
}

class _ExportWindowState extends State<_ExportWindow> {
  bool _data = false;

  @override
  Widget build(BuildContext context) {
    final c = RgColors.of(context);
    final l = AppLocalizations.of(context);
    return AlertDialog(
      title: Text(l.cvArExportTitle(widget.a.name)),
      content: SizedBox(
        width: 460,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (widget.a.hasData)
                InkWell(
                  key: const Key('artifact-export-data'),
                  borderRadius: BorderRadius.circular(10),
                  onTap: () => setState(() => _data = !_data),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                l.cvArExportData,
                                style: TextStyle(color: c.text, fontWeight: FontWeight.w600),
                              ),
                              Text(
                                l.cvArExportDataHint,
                                style: TextStyle(color: c.dim, fontSize: 12.5),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 10),
                        RgSwitch(on: _data),
                      ],
                    ),
                  ),
                ),
              _BoxButton(
                key: const Key('artifact-export-zip'),
                title: l.cvArExportZip,
                pill: '.rgartifact',
                text: l.cvArExportZipText,
                onTap: () => Navigator.of(context).pop((html: false, data: _data)),
              ),
              const SizedBox(height: 10),
              _BoxButton(
                key: const Key('artifact-export-html'),
                warn: true,
                title: l.cvArExportHtml,
                pill: '.html',
                text: l.cvArExportHtmlText,
                onTap: () => Navigator.of(context).pop((html: true, data: false)),
              ),
            ],
          ),
        ),
      ),
      actions: [TextButton(onPressed: () => Navigator.of(context).pop(), child: Text(l.cvCancel))],
    );
  }
}

/// «Import»: the place the picked `.rgartifact` goes into.
class _WhereWindow extends StatelessWidget {
  const _WhereWindow({required this.file, required this.places});

  final String file;
  final List<({String scope, String name})> places;

  @override
  Widget build(BuildContext context) {
    final c = RgColors.of(context);
    final l = AppLocalizations.of(context);
    return AlertDialog(
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(l.cvArWhereQ),
          Text(
            file,
            style: TextStyle(color: c.dim, fontSize: 13, fontWeight: FontWeight.w400),
          ),
        ],
      ),
      content: SizedBox(
        width: 460,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(l.cvArWhereLead, style: TextStyle(color: c.dim, fontSize: 13)),
              for (final p in places) ...[
                const SizedBox(height: 10),
                _BoxButton(
                  key: Key('artifact-place-${p.scope}'),
                  title: p.name,
                  text: '$artifactDir/',
                  mono: true,
                  onTap: () => Navigator.of(context).pop(p),
                ),
              ],
            ],
          ),
        ),
      ),
      actions: [TextButton(onPressed: () => Navigator.of(context).pop(), child: Text(l.cvCancel))],
    );
  }
}

/// A choice drawn as a box (the page's `BoxButton`): its title, a small pill, a line about it.
class _BoxButton extends StatelessWidget {
  const _BoxButton({
    super.key,
    required this.title,
    required this.text,
    required this.onTap,
    this.pill,
    this.warn = false,
    this.mono = false,
  });

  final String title;
  final String text;
  final String? pill;
  final bool warn;
  final bool mono;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = RgColors.of(context);
    final edge = warn ? c.warn : c.line;
    return Material(
      color: warn ? c.warn.withValues(alpha: .08) : c.panel,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: edge),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      title,
                      style: TextStyle(color: c.text, fontWeight: FontWeight.w700),
                    ),
                  ),
                  if (pill != null) _Chip(text: pill!, color: warn ? c.warn : c.accent),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                text,
                style: TextStyle(
                  color: c.dim,
                  fontSize: 12.5,
                  fontFamily: mono ? 'monospace' : null,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

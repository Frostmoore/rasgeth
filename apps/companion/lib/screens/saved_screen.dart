// «Salva» and «Salvati» (G40.14), as the page's Saved.tsx: a passage of an answer (selected) or a
// whole message goes into the person's own archive, with a note and tags if they like; the
// archive is a screen of its own, opened from the Chat: newest first with «Mostra i più vecchi»,
// search, filters by tag and agent, the way back to the conversation with the passage lit up,
// note and tags edited, deletion after a yes, and the export as Markdown (a file or the text).
import 'dart:async';
import 'dart:convert';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

import '../api/client.dart';
import '../api/saved.dart';
import '../app_state.dart';
import '../l10n/app_localizations.dart';
import '../theme/colors.dart';
import '../ui/common.dart';
import '../ui/dialogs.dart';
import '../ui/icons.dart';
import '../ui/markdown.dart';
import 'conversation_screen.dart';

/// Saves a file the person chose where to put (tests give their own).
typedef FileSaver = Future<bool> Function(String name, Uint8List bytes);

Future<bool> _saveWithPicker(String name, Uint8List bytes) async =>
    await FilePicker.saveFile(fileName: name, bytes: bytes, mimeType: 'text/markdown') != null;

String _when(AppLocalizations l, String? iso) {
  final t = iso == null ? null : DateTime.tryParse(iso)?.toLocal();
  return t == null ? '' : DateFormat.yMMMd(l.localeName).add_Hm().format(t);
}

/// «Salva»: the sheet with the passage, a note and tags (both optional).
Future<void> showSaveSheet(
  BuildContext context, {
  required String sessionId,
  required int seq,
  required String preview,
  String? text,
  int? start,
  int? end,
}) => showModalBottomSheet<void>(
  context: context,
  isScrollControlled: true,
  showDragHandle: true,
  builder: (_) => _SaveSheet(
    sessionId: sessionId,
    seq: seq,
    preview: preview,
    text: text,
    start: start,
    end: end,
  ),
);

class _SaveSheet extends StatefulWidget {
  const _SaveSheet({
    required this.sessionId,
    required this.seq,
    required this.preview,
    this.text,
    this.start,
    this.end,
  });

  final String sessionId;
  final int seq;
  final String preview;

  /// The selected passage (null: the whole message).
  final String? text;
  final int? start;
  final int? end;

  @override
  State<_SaveSheet> createState() => _SaveSheetState();
}

class _SaveSheetState extends State<_SaveSheet> {
  final _note = TextEditingController();
  final _typed = TextEditingController();
  List<String> _chosen = const [];
  List<String> _known = const [];
  bool _busy = false;
  bool _done = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    final c = AppScope.read(context).client;
    unawaited(
      c?.savedList(limit: 1).then((r) {
        if (mounted) setState(() => _known = [for (final t in r.tags) t.tag]);
      }, onError: (_) {}),
    );
  }

  @override
  void dispose() {
    _note.dispose();
    _typed.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final c = AppScope.read(context).client;
    final l = AppLocalizations.of(context);
    if (c == null) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await c.saveItem(
        sessionId: widget.sessionId,
        seq: widget.seq,
        start: widget.text == null ? null : widget.start,
        end: widget.text == null ? null : widget.end,
        text: widget.text,
        note: _note.text,
        tags: withTyped(_chosen, _typed.text),
      );
      if (mounted) setState(() => _done = true);
    } on ApiException catch (e) {
      if (mounted) setState(() => _error = l.savedFailed(e.message));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final c = RgColors.of(context);
    final inset = MediaQuery.viewInsetsOf(context).bottom;
    if (_done) {
      return Padding(
        key: const Key('save-done'),
        padding: EdgeInsets.fromLTRB(20, 0, 20, 20 + inset),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                RgIcon(RgIcons.check, size: 20, color: c.ok),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(l.savedDone, style: TextStyle(color: c.text, fontSize: 15)),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Wrap(
              alignment: WrapAlignment.end,
              spacing: 8,
              runSpacing: 6,
              children: [
                TextButton(
                  key: const Key('save-close'),
                  onPressed: () => Navigator.pop(context),
                  child: Text(l.close),
                ),
                FilledButton.icon(
                  key: const Key('save-open-archive'),
                  onPressed: () {
                    final nav = Navigator.of(context);
                    nav.pop();
                    unawaited(
                      nav.push(MaterialPageRoute<void>(builder: (_) => const SavedScreen())),
                    );
                  },
                  icon: const RgIcon(RgIcons.bookmark, size: 16, color: Colors.white),
                  label: Text('${l.savedOpenArchive} ${l.savedTitle}'),
                ),
              ],
            ),
          ],
        ),
      );
    }
    return Padding(
      key: const Key('save-sheet'),
      padding: EdgeInsets.fromLTRB(20, 0, 20, 16 + inset),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                RgIcon(RgIcons.bookmark, size: 19, color: c.accent),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    widget.text == null ? l.savedSaveMessageTitle : l.savedSaveTitle,
                    style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: c.text),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Container(
              key: const Key('save-preview'),
              constraints: const BoxConstraints(maxHeight: 180),
              padding: const EdgeInsets.fromLTRB(12, 6, 8, 6),
              decoration: BoxDecoration(
                border: Border(left: BorderSide(color: c.accentDim, width: 3)),
                color: c.panel2,
              ),
              child: SingleChildScrollView(
                child: Text(widget.preview, style: TextStyle(color: c.text, fontSize: 14)),
              ),
            ),
            const SizedBox(height: 14),
            TextField(
              key: const Key('save-note'),
              controller: _note,
              minLines: 2,
              maxLines: 5,
              maxLength: savedNoteMax,
              decoration: InputDecoration(
                labelText: l.savedNote,
                hintText: l.savedNotePlaceholder,
                counterText: '',
              ),
            ),
            const SizedBox(height: 10),
            Text(l.savedTags, style: TextStyle(color: c.dim, fontSize: 13)),
            const SizedBox(height: 6),
            TagPicker(
              chosen: _chosen,
              known: _known,
              typed: _typed,
              onChosen: (t) => setState(() => _chosen = t),
              fieldKey: const Key('save-tags'),
            ),
            if (_error != null)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(_error!, style: TextStyle(color: c.err, fontSize: 13)),
              ),
            const SizedBox(height: 14),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(onPressed: () => Navigator.pop(context), child: Text(l.cancel)),
                const SizedBox(width: 8),
                FilledButton.icon(
                  key: const Key('save-confirm'),
                  onPressed: _busy ? null : _save,
                  icon: RgIcon(
                    _busy ? RgIcons.spinner : RgIcons.bookmark,
                    size: 16,
                    color: Colors.white,
                  ),
                  label: Text(l.savedSave),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// A drawn on/off chip (never the system's checkbox).
class RgChip extends StatelessWidget {
  const RgChip({super.key, required this.label, required this.on, required this.onTap, this.icon});

  final String label;
  final bool on;
  final VoidCallback onTap;
  final RgIcons? icon;

  @override
  Widget build(BuildContext context) {
    final c = RgColors.of(context);
    return Semantics(
      button: true,
      selected: on,
      child: Material(
        color: on ? c.accentSoft : c.panel,
        shape: StadiumBorder(side: BorderSide(color: on ? c.accent : c.line)),
        child: InkWell(
          customBorder: const StadiumBorder(),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 6),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (icon != null) ...[
                  RgIcon(icon!, size: 12, color: on ? c.accent : c.dim),
                  const SizedBox(width: 4),
                ],
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 13,
                    color: on ? c.accent2 : c.text,
                    fontWeight: on ? FontWeight.w700 : FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// The tags: the known ones to tap, and a field for new ones (separated by commas).
class TagPicker extends StatelessWidget {
  const TagPicker({
    super.key,
    required this.chosen,
    required this.known,
    required this.typed,
    required this.onChosen,
    this.fieldKey,
  });

  final List<String> chosen;
  final List<String> known;
  final TextEditingController typed;
  final ValueChanged<List<String>> onChosen;
  final Key? fieldKey;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final all = normalizeTags([...known, ...chosen]);
    bool isOn(String t) => chosen.any((c) => c.toLowerCase() == t.toLowerCase());
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (all.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                for (final t in all)
                  RgChip(
                    key: Key('tag-pick-$t'),
                    label: t,
                    icon: RgIcons.tag,
                    on: isOn(t),
                    onTap: () => onChosen(
                      isOn(t)
                          ? chosen.where((c) => c.toLowerCase() != t.toLowerCase()).toList()
                          : normalizeTags([...chosen, t]),
                    ),
                  ),
              ],
            ),
          ),
        TextField(
          key: fieldKey,
          controller: typed,
          decoration: InputDecoration(hintText: l.savedTagsPlaceholder, isDense: true),
        ),
      ],
    );
  }
}

/// Back to where a saved passage comes from: the conversation opens with the passage lit up.
Future<void> openSavedSource(BuildContext context, SavedItem item) async {
  final l = AppLocalizations.of(context);
  final app = AppScope.read(context);
  final s = item.source;
  if (!s.isSession) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l.savedFromDailyChat)));
    return;
  }
  final agentId =
      s.agentId ?? app.live.sessions.where((r) => r.id == s.sessionId).firstOrNull?.agentId;
  final agent = app.agents.where((a) => a.id == agentId).firstOrNull;
  await Navigator.of(context).push(
    MaterialPageRoute<void>(
      builder: (_) => ConversationScreen(
        sessionId: s.sessionId!,
        agent: agent,
        jump: PassageJump(seq: s.seq!, text: item.text, start: s.start, end: s.end),
      ),
    ),
  );
}

/// «Salvati»: the person's archive.
class SavedScreen extends StatefulWidget {
  const SavedScreen({super.key, this.saveFile});

  final FileSaver? saveFile;

  @override
  State<SavedScreen> createState() => _SavedScreenState();
}

class _SavedScreenState extends State<SavedScreen> {
  final _search = TextEditingController();
  Timer? _timer;
  String _query = '';
  String? _tag;
  String? _agentId;
  SavedList? _list;
  List<SavedItem> _items = const [];
  bool _loading = false;
  bool _loadingMore = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    unawaited(_load());
  }

  @override
  void dispose() {
    _timer?.cancel();
    _search.dispose();
    super.dispose();
  }

  RedGiantClient? get _client => AppScope.read(context).client;

  Future<void> _load() async {
    final c = _client;
    if (c == null) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    final asked = (_query, _tag, _agentId);
    try {
      final r = await c.savedList(q: _query, tag: _tag, agentId: _agentId, limit: 30);
      if (!mounted || asked != (_query, _tag, _agentId)) return;
      setState(() {
        _list = r;
        _items = r.items;
      });
    } on ApiException catch (e) {
      if (mounted) setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _more() async {
    final c = _client;
    final last = _items.lastOrNull;
    if (c == null || last == null) return;
    setState(() => _loadingMore = true);
    try {
      final r = await c.savedList(
        q: _query,
        tag: _tag,
        agentId: _agentId,
        before: last.createdAt,
        limit: 30,
      );
      if (!mounted) return;
      setState(() {
        _list = SavedList(items: r.items, more: r.more, tags: r.tags, agents: r.agents);
        _items = [..._items, ...r.items.where((i) => !_items.any((x) => x.id == i.id))];
      });
    } on ApiException catch (e) {
      if (mounted) setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _loadingMore = false);
    }
  }

  void _typed(String v) {
    // The clear button comes and goes with the text.
    if (v.isEmpty != _query.isEmpty) setState(() {});
    _timer?.cancel();
    _timer = Timer(const Duration(milliseconds: 300), () {
      if (!mounted || v.trim() == _query) return;
      _query = v.trim();
      unawaited(_load());
    });
  }

  Future<void> _export() async {
    final l = AppLocalizations.of(context);
    final messenger = ScaffoldMessenger.of(context);
    final c = _client;
    if (c == null) return;
    final how = await showModalBottomSheet<String>(
      context: context,
      showDragHandle: true,
      builder: (context) {
        final rc = RgColors.of(context);
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                key: const Key('export-file'),
                leading: RgIcon(RgIcons.download, color: rc.text),
                title: Text(l.savedExportFile),
                onTap: () => Navigator.pop(context, 'file'),
              ),
              ListTile(
                key: const Key('export-copy'),
                leading: RgIcon(RgIcons.copy, color: rc.text),
                title: Text(l.savedExportCopy),
                onTap: () => Navigator.pop(context, 'copy'),
              ),
            ],
          ),
        );
      },
    );
    if (how == null) return;
    try {
      final md = await c.savedExport(
        q: _query,
        tag: _tag,
        agentId: _agentId,
        lang: l.localeName.startsWith('it') ? 'it' : 'en',
      );
      if (how == 'copy') {
        await Clipboard.setData(ClipboardData(text: md));
        messenger.showSnackBar(SnackBar(content: Text(l.savedExportCopied)));
        return;
      }
      final saved = await (widget.saveFile ?? _saveWithPicker)(
        l.savedFileName,
        Uint8List.fromList(utf8.encode(md)),
      );
      if (saved) messenger.showSnackBar(SnackBar(content: Text(l.savedExportSaved)));
    } on Object catch (e) {
      messenger.showSnackBar(
        SnackBar(content: Text(l.savedExportFailed(e is ApiException ? e.message : '$e'))),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final c = RgColors.of(context);
    final list = _list;
    final tags = list?.tags ?? const [];
    final agents = list?.agents ?? const [];
    final filtered = _query.isNotEmpty || _tag != null || _agentId != null;
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          key: const Key('saved-back'),
          tooltip: l.back,
          onPressed: () => Navigator.of(context).pop(),
          icon: RgIcon(RgIcons.arrowLeft, color: c.text),
        ),
        title: Text(l.savedTitle),
        actions: [
          IconButton(
            key: const Key('saved-export'),
            tooltip: l.savedExport,
            onPressed: _items.isEmpty ? null : _export,
            icon: RgIcon(RgIcons.download, color: _items.isEmpty ? c.line : c.text),
          ),
        ],
      ),
      body: Align(
        alignment: Alignment.topCenter,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 720),
          child: RefreshIndicator(
            onRefresh: _load,
            child: ListView(
              key: const Key('saved-list'),
              padding: const EdgeInsets.fromLTRB(14, 4, 14, 24),
              children: [
                Text(l.savedHint, style: TextStyle(color: c.dim, fontSize: 13)),
                const SizedBox(height: 10),
                TextField(
                  key: const Key('saved-search'),
                  controller: _search,
                  onChanged: _typed,
                  textInputAction: TextInputAction.search,
                  decoration: InputDecoration(
                    hintText: l.savedSearch,
                    isDense: true,
                    prefixIcon: Padding(
                      padding: const EdgeInsets.all(11),
                      child: RgIcon(RgIcons.search, size: 18, color: c.dim),
                    ),
                    prefixIconConstraints: const BoxConstraints(minWidth: 40),
                    suffixIcon: _search.text.isEmpty
                        ? null
                        : IconButton(
                            key: const Key('saved-search-clear'),
                            tooltip: l.savedSearchClear,
                            onPressed: () {
                              _search.clear();
                              _typed('');
                              setState(() {});
                            },
                            icon: RgIcon(RgIcons.x, size: 16, color: c.dim),
                          ),
                  ),
                ),
                if (tags.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  _FilterRow(
                    children: [
                      RgChip(
                        key: const Key('saved-tag-all'),
                        label: l.savedAllTags,
                        on: _tag == null,
                        onTap: () {
                          setState(() => _tag = null);
                          unawaited(_load());
                        },
                      ),
                      for (final t in tags)
                        RgChip(
                          key: Key('saved-tag-${t.tag}'),
                          label: '${t.tag} (${t.count})',
                          icon: RgIcons.tag,
                          on: _tag?.toLowerCase() == t.tag.toLowerCase(),
                          onTap: () {
                            setState(() => _tag = _tag == t.tag ? null : t.tag);
                            unawaited(_load());
                          },
                        ),
                    ],
                  ),
                ],
                if (agents.length > 1 || _agentId != null) ...[
                  const SizedBox(height: 8),
                  _FilterRow(
                    children: [
                      RgChip(
                        key: const Key('saved-agent-all'),
                        label: l.savedAllAgents,
                        on: _agentId == null,
                        onTap: () {
                          setState(() => _agentId = null);
                          unawaited(_load());
                        },
                      ),
                      for (final a in agents)
                        RgChip(
                          key: Key('saved-agent-${a.id}'),
                          label: '${a.name} (${a.count})',
                          on: _agentId == a.id,
                          onTap: () {
                            setState(() => _agentId = _agentId == a.id ? null : a.id);
                            unawaited(_load());
                          },
                        ),
                    ],
                  ),
                ],
                const SizedBox(height: 12),
                if (_error != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: Text(_error!, style: TextStyle(color: c.err, fontSize: 13)),
                  ),
                if (_items.isEmpty)
                  SizedBox(
                    height: 260,
                    child: EmptyState(
                      icon: RgIcons.bookmark,
                      text: _loading || list == null
                          ? l.loading
                          : (filtered ? l.savedNoMatch : l.savedEmpty),
                    ),
                  ),
                for (final it in _items)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: SavedCard(
                      key: ValueKey('saved-${it.id}'),
                      item: it,
                      known: [for (final t in tags) t.tag],
                      onChanged: (n) =>
                          setState(() => _items = [for (final x in _items) x.id == n.id ? n : x]),
                      onRemoved: (id) {
                        setState(() => _items = _items.where((x) => x.id != id).toList());
                        unawaited(_load());
                      },
                    ),
                  ),
                if (list?.more == true && _items.isNotEmpty)
                  Center(
                    child: OutlinedButton.icon(
                      key: const Key('saved-more'),
                      onPressed: _loadingMore ? null : _more,
                      icon: RgIcon(
                        _loadingMore ? RgIcons.spinner : RgIcons.chevronDown,
                        size: 16,
                        color: c.text,
                      ),
                      label: Text(l.savedMore),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _FilterRow extends StatelessWidget {
  const _FilterRow({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) => SingleChildScrollView(
    scrollDirection: Axis.horizontal,
    child: Row(
      children: [
        for (final w in children) Padding(padding: const EdgeInsets.only(right: 6), child: w),
      ],
    ),
  );
}

/// One saved passage: where it comes from, the passage, the note and the tags, and what to do.
class SavedCard extends StatefulWidget {
  const SavedCard({
    super.key,
    required this.item,
    required this.known,
    required this.onChanged,
    required this.onRemoved,
  });

  final SavedItem item;
  final List<String> known;
  final ValueChanged<SavedItem> onChanged;
  final ValueChanged<String> onRemoved;

  @override
  State<SavedCard> createState() => _SavedCardState();
}

class _SavedCardState extends State<SavedCard> {
  bool _editing = false;
  late final _note = TextEditingController(text: widget.item.note);
  final _typed = TextEditingController();
  late List<String> _chosen = widget.item.tags;
  String? _error;

  @override
  void dispose() {
    _note.dispose();
    _typed.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final c = AppScope.read(context).client;
    if (c == null) return;
    try {
      final n = await c.updateSaved(
        widget.item.id,
        note: _note.text,
        tags: withTyped(_chosen, _typed.text),
      );
      if (!mounted) return;
      _typed.clear();
      setState(() {
        _editing = false;
        _error = null;
        _chosen = n.tags;
      });
      widget.onChanged(n);
    } on ApiException catch (e) {
      if (mounted) setState(() => _error = e.message);
    }
  }

  Future<void> _remove() async {
    final l = AppLocalizations.of(context);
    final c = AppScope.read(context).client;
    final yes = await askConfirm(
      context,
      title: l.savedDeleteTitle,
      body: l.savedDeleteText,
      yes: l.savedDelete,
      danger: true,
    );
    if (!yes || c == null) return;
    try {
      await c.deleteSaved(widget.item.id);
      widget.onRemoved(widget.item.id);
    } on ApiException catch (e) {
      if (mounted) setState(() => _error = e.message);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final c = RgColors.of(context);
    final app = AppScope.of(context);
    final it = widget.item;
    final s = it.source;
    final agentName = app.agents.where((a) => a.id == s.agentId).firstOrNull?.name ?? s.agentName;
    final from = [s.title, agentName].whereType<String>().where((x) => x.isNotEmpty).join(' · ');
    Widget action(Key key, RgIcons icon, String label, VoidCallback onTap, {Color? color}) =>
        TextButton.icon(
          key: key,
          style: TextButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            minimumSize: const Size(0, 34),
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
          onPressed: onTap,
          icon: RgIcon(icon, size: 14, color: color ?? c.dim),
          label: Text(label, style: TextStyle(color: color ?? c.dim, fontSize: 13)),
        );
    return Container(
      decoration: BoxDecoration(
        color: c.panel,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: c.line),
      ),
      padding: const EdgeInsets.fromLTRB(14, 10, 8, 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(right: 6),
            child: Row(
              children: [
                RgIcon(RgIcons.bookmark, size: 14, color: c.accent),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    from.isEmpty ? l.savedUnknownOrigin : from,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(color: c.text, fontWeight: FontWeight.w700, fontSize: 13.5),
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  _when(l, s.messageAt ?? it.createdAt),
                  style: TextStyle(color: c.dim, fontSize: 12),
                ),
              ],
            ),
          ),
          if (it.whole)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                l.savedWhole,
                style: TextStyle(color: c.dim, fontSize: 12, fontStyle: FontStyle.italic),
              ),
            ),
          Padding(
            padding: const EdgeInsets.fromLTRB(0, 8, 6, 4),
            child: it.markdown != null
                ? SafeMarkdown(it.markdown!)
                : SelectableText(it.text, style: TextStyle(color: c.text, fontSize: 15)),
          ),
          if (_editing) ...[
            const SizedBox(height: 6),
            TextField(
              key: Key('saved-note-${it.id}'),
              controller: _note,
              minLines: 2,
              maxLines: 5,
              maxLength: savedNoteMax,
              decoration: InputDecoration(
                labelText: l.savedNote,
                hintText: l.savedNotePlaceholder,
                counterText: '',
              ),
            ),
            const SizedBox(height: 8),
            TagPicker(
              chosen: _chosen,
              known: widget.known,
              typed: _typed,
              onChosen: (t) => setState(() => _chosen = t),
              fieldKey: Key('saved-tags-${it.id}'),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => setState(() {
                    _editing = false;
                    _note.text = it.note;
                    _chosen = it.tags;
                    _typed.clear();
                  }),
                  child: Text(l.cancel),
                ),
                FilledButton(
                  key: Key('saved-save-${it.id}'),
                  onPressed: _save,
                  child: Text(l.save),
                ),
              ],
            ),
          ] else ...[
            if (it.note.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 4, right: 6),
                child: Text(
                  it.note,
                  key: Key('saved-note-text-${it.id}'),
                  style: TextStyle(color: c.dim, fontSize: 13.5, fontStyle: FontStyle.italic),
                ),
              ),
            if (it.tags.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Wrap(
                  spacing: 6,
                  runSpacing: 4,
                  children: [
                    for (final t in it.tags)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: c.panel2,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            RgIcon(RgIcons.tag, size: 11, color: c.dim),
                            const SizedBox(width: 4),
                            Text(t, style: TextStyle(color: c.text, fontSize: 12)),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
          ],
          if (_error != null)
            Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Text(_error!, style: TextStyle(color: c.err, fontSize: 13)),
            ),
          const SizedBox(height: 4),
          Wrap(
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Padding(
                padding: const EdgeInsets.only(right: 4),
                child: Text(
                  l.savedOn(_when(l, it.createdAt)),
                  style: TextStyle(color: c.dim, fontSize: 12),
                ),
              ),
              action(
                Key('saved-open-${it.id}'),
                RgIcons.external,
                l.savedOpen,
                () => unawaited(openSavedSource(context, it)),
              ),
              if (!_editing)
                action(
                  Key('saved-edit-${it.id}'),
                  RgIcons.edit,
                  l.savedEdit,
                  () => setState(() => _editing = true),
                ),
              action(
                Key('saved-delete-${it.id}'),
                RgIcons.trash,
                l.savedDelete,
                _remove,
                color: c.err,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

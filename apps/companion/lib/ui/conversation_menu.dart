// A conversation's menu (3.8.8), in every list of conversations (an agent's, the Chat's, a
// project's, the palette): right click on a computer, long press on a phone. The page's row
// actions (Sidebar.tsx `SessionLine`, Chats.tsx `SessionCard`) with the same routes: open, pin,
// move to a folder, archive or bring back (`PATCH /api/sessions/:id`), export as Markdown
// (`GET /api/sessions/:id/export`). The page has no «Rename» for a conversation, so neither do we.
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

import '../api/conversation.dart';
import '../api/types.dart';
import '../app_state.dart';
import '../desktop/desk_controller.dart';
import '../l10n/app_localizations.dart';
import '../screens/conversation_screen.dart';
import '../theme/colors.dart';
import 'dialogs.dart';
import 'icons.dart';
import 'rg_menu.dart';

/// Saves a file the person chose where to put (tests give their own).
typedef ExportSaver = Future<bool> Function(String name, Uint8List bytes);

Future<bool> _saveWithPicker(String name, Uint8List bytes) async =>
    await FilePicker.saveFile(fileName: name, bytes: bytes, mimeType: 'text/markdown') != null;

/// Where «Export as Markdown» saves (the system's «Save as»; tests put their own).
ExportSaver conversationSaver = _saveWithPicker;

/// The file's name as the server gives it (`/api/sessions/:id/export`'s content-disposition).
String exportName(String title) {
  final clean = title.replaceAll(RegExp(r'[^\p{L}\p{N} _-]+', unicode: true), '').trim();
  final cut = clean.length > 60 ? clean.substring(0, 60) : clean;
  return '${cut.isEmpty ? 'conversation' : cut}.md';
}

/// A row's title as the lists show it: its task, its title, or «Conversation».
String sessionTitle(AppLocalizations l, SessionRow r) =>
    r.task != null ? l.cmTask(r.task!) : (r.title?.isNotEmpty == true ? r.title! : l.untitled);

/// Opens [r]: in the control room's panel, else over the screen.
Future<void> openSessionRow(BuildContext context, SessionRow r, {Agent? agent}) async {
  final app = AppScope.read(context);
  final a = agent ?? app.agents.where((x) => x.id == r.agentId).firstOrNull;
  final desk = DeskScope.maybeRead(context);
  if (desk != null) {
    desk.show(PanelConversation(r.id, agent: a));
    return;
  }
  await Navigator.of(context).push(
    MaterialPageRoute<void>(
      builder: (_) => ConversationScreen(sessionId: r.id, agent: a),
    ),
  );
}

/// Right click or long press on a conversation's row.
class ConversationPress extends StatelessWidget {
  const ConversationPress({super.key, required this.row, required this.child, this.opened});

  final SessionRow row;
  final Widget child;

  /// After «Open» (the palette closes itself).
  final VoidCallback? opened;

  @override
  Widget build(BuildContext context) => RgPress(
    onMenu: (at) => showConversationMenu(context, row, at: at, opened: opened),
    child: child,
  );
}

enum _C { open, pin, folder, archive, export }

/// [r]'s menu: at [at] on a computer, the sheet from below without it.
Future<void> showConversationMenu(
  BuildContext context,
  SessionRow r, {
  Offset? at,
  VoidCallback? opened,
}) async {
  final app = AppScope.read(context);
  final l = AppLocalizations.of(context);
  final c = RgColors.of(context);
  final entries = <RgMenuEntry<_C>?>[
    RgMenuEntry(_C.open, RgIcons.chat, l.cmOpen, key: const Key('conv-menu-open')),
    null,
    RgMenuEntry(
      _C.pin,
      RgIcons.pin,
      r.pinned ? l.cmUnpin : l.cmPin,
      key: const Key('conv-menu-pin'),
    ),
    if (!r.archived)
      RgMenuEntry(_C.folder, RgIcons.folder, l.cmFolder, key: const Key('conv-menu-folder')),
    RgMenuEntry(
      _C.archive,
      r.archived ? RgIcons.restore : RgIcons.archive,
      r.archived ? l.cmUnarchive : l.cmArchive,
      key: const Key('conv-menu-archive'),
    ),
    RgMenuEntry(_C.export, RgIcons.download, l.cmExport, key: const Key('conv-menu-export')),
  ];
  final agent = app.agents.where((a) => a.id == r.agentId).firstOrNull;
  final pick = at != null
      ? await showRgMenu(context, at, entries)
      : await showRgSheet(
          context,
          key: Key('conv-sheet-${r.id}'),
          head: RgSheetHead(
            leading: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(color: c.panel2, borderRadius: BorderRadius.circular(12)),
              alignment: Alignment.center,
              child: RgIcon(r.archived ? RgIcons.archive : RgIcons.chat, size: 20, color: c.dim),
            ),
            title: sessionTitle(l, r),
            subtitle: agent?.name,
          ),
          entries: entries,
        );
  if (pick == null || !context.mounted) return;
  final messenger = ScaffoldMessenger.maybeOf(context);
  void say(String text) => messenger?.showSnackBar(SnackBar(content: Text(text)));
  switch (pick) {
    case _C.open:
      await openSessionRow(context, r, agent: agent);
      opened?.call();
    case _C.pin:
      if (!await app.updateSession(r.id, pinned: !r.pinned)) say(l.cmFailed);
    case _C.folder:
      await _pickFolder(context, r, at);
    case _C.archive:
      final ok = await app.updateSession(r.id, archived: !r.archived);
      say(ok ? (r.archived ? l.cmUnarchived : l.cmArchived) : l.cmFailed);
    case _C.export:
      final bytes = await app.exportSession(r.id);
      if (bytes == null) {
        say(l.cmFailed);
        return;
      }
      if (await conversationSaver(exportName(r.title ?? agent?.name ?? r.id), bytes)) {
        say(l.cmExported);
      }
  }
}

/// «Move to a folder»: the folders already used next to it, a new one, or out of it (the page's
/// `FolderMenu`).
Future<void> _pickFolder(BuildContext context, SessionRow r, Offset? at) async {
  final app = AppScope.read(context);
  final l = AppLocalizations.of(context);
  final folders = {
    for (final s in app.live.sessions)
      if (s.agentId == r.agentId && !s.archived && s.folder != null) s.folder!,
  }.toList()..sort();
  const fresh = '\u0000new';
  const out = '\u0000out';
  final entries = <RgMenuEntry<String>?>[
    for (final f in folders)
      RgMenuEntry(
        f,
        f == r.folder ? RgIcons.check : RgIcons.folder,
        f,
        key: Key('conv-folder-$f'),
        enabled: f != r.folder,
      ),
    if (folders.isNotEmpty) null,
    RgMenuEntry(fresh, RgIcons.plus, l.cmFolderNew, key: const Key('conv-folder-new')),
    if (r.folder != null)
      RgMenuEntry(out, RgIcons.x, l.cmFolderOut, key: const Key('conv-folder-out')),
  ];
  final pick = at != null
      ? await showRgMenu(context, at, entries)
      : await showRgSheet(
          context,
          head: RgSheetHead(
            leading: RgIcon(RgIcons.folder, size: 22, color: RgColors.of(context).dim),
            title: l.cmFolder,
            subtitle: sessionTitle(l, r),
          ),
          entries: entries,
        );
  if (pick == null || !context.mounted) return;
  var ok = true;
  if (pick == out) {
    ok = await app.updateSession(r.id, clearFolder: true);
  } else if (pick == fresh) {
    final name = await askText(
      context,
      title: l.cmFolderNewTitle,
      yes: l.cmFolderNewYes,
      fieldKey: const Key('conv-folder-name'),
    );
    final n = name?.trim() ?? '';
    if (n.isEmpty || !context.mounted) return;
    // The server's limit (60 characters), as the page's field.
    ok = await app.updateSession(r.id, folder: n.length > 60 ? n.substring(0, 60) : n);
  } else {
    ok = await app.updateSession(r.id, folder: pick);
  }
  if (!ok && context.mounted) {
    ScaffoldMessenger.maybeOf(context)?.showSnackBar(SnackBar(content: Text(l.cmFailed)));
  }
}

/// «Move to a folder» for anything that has one (an old chat, G42.3): [folders] to choose from, a
/// new one, or out of it. The folder picked, '' to take it out, null when nothing changes.
Future<String?> askFolder(
  BuildContext context, {
  required List<String> folders,
  String? current,
  String? subtitle,
}) async {
  final l = AppLocalizations.of(context);
  const fresh = '\u0000new';
  const out = '\u0000out';
  final entries = <RgMenuEntry<String>?>[
    for (final f in folders)
      RgMenuEntry(
        f,
        f == current ? RgIcons.check : RgIcons.folder,
        f,
        key: Key('conv-folder-$f'),
        enabled: f != current,
      ),
    if (folders.isNotEmpty) null,
    RgMenuEntry(fresh, RgIcons.plus, l.cmFolderNew, key: const Key('conv-folder-new')),
    if (current != null)
      RgMenuEntry(out, RgIcons.x, l.cmFolderOut, key: const Key('conv-folder-out')),
  ];
  final pick = await showRgSheet(
    context,
    head: RgSheetHead(
      leading: RgIcon(RgIcons.folder, size: 22, color: RgColors.of(context).dim),
      title: l.cmFolder,
      subtitle: subtitle,
    ),
    entries: entries,
  );
  if (pick == null || !context.mounted) return null;
  if (pick == out) return '';
  if (pick != fresh) return pick;
  final name = await askText(
    context,
    title: l.cmFolderNewTitle,
    yes: l.cmFolderNewYes,
    fieldKey: const Key('conv-folder-name'),
  );
  final n = name?.trim() ?? '';
  if (n.isEmpty) return null;
  return n.length > 60 ? n.substring(0, 60) : n;
}

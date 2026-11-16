// Files dropped from the computer onto a conversation (G40.17): read here, then taken by the
// conversation's composer with the same rules as «Attach» (`classify`). The drop target is the
// `desktop_drop` plugin (Windows, macOS, Linux); a folder is skipped.
import 'package:desktop_drop/desktop_drop.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import '../theme/colors.dart';
import '../ui/icons.dart';

/// Files waiting for a conversation's composer.
class FileDrops extends ChangeNotifier {
  final _items = <(String, Uint8List)>[];

  bool get isEmpty => _items.isEmpty;

  void add(String name, Uint8List bytes) {
    _items.add((name, bytes));
    notifyListeners();
  }

  /// What came, once.
  List<(String, Uint8List)> take() {
    final out = List.of(_items);
    _items.clear();
    return out;
  }
}

/// [child] takes files dropped from the computer into [drops], with a frame while they hover.
class FileDropZone extends StatefulWidget {
  const FileDropZone({super.key, required this.drops, required this.child, this.enabled = true});

  final FileDrops drops;
  final Widget child;
  final bool enabled;

  @override
  State<FileDropZone> createState() => _FileDropZoneState();
}

class _FileDropZoneState extends State<FileDropZone> {
  bool _over = false;

  Future<void> _done(DropDoneDetails d) async {
    setState(() => _over = false);
    for (final f in d.files) {
      if (f is DropItemDirectory) continue;
      final mark = f.extraAppleBookmark;
      if (mark != null && mark.isNotEmpty) {
        try {
          await DesktopDrop.instance.startAccessingSecurityScopedResource(bookmark: mark);
        } on Object {
          // Read anyway: the system may allow it.
        }
      }
      try {
        widget.drops.add(f.name, await f.readAsBytes());
      } on Object {
        // A file the system does not let us read: left out.
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = RgColors.of(context);
    final l = AppLocalizations.of(context);
    return DropTarget(
      enable: widget.enabled,
      onDragEntered: (_) => setState(() => _over = true),
      onDragExited: (_) => setState(() => _over = false),
      onDragDone: _done,
      child: Stack(
        children: [
          widget.child,
          if (_over)
            Positioned.fill(
              child: IgnorePointer(
                child: Container(
                  margin: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: c.accentSoft.withValues(alpha: .85),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: c.accent, width: 2),
                  ),
                  alignment: Alignment.center,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      RgIcon(RgIcons.paperclip, size: 20, color: c.accent),
                      const SizedBox(width: 8),
                      Text(
                        l.deskDropHere,
                        style: TextStyle(color: c.accent, fontWeight: FontWeight.w700),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

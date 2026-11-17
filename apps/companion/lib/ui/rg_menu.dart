// Our context menus (3.8.8), drawn like the agents' (G38.7): on a computer a menu at the pointer
// (right click), on a phone the same items in a sheet from below (long press). The conversations'
// and the projects' menus are made of these, so every list of the app speaks the same way.
import 'package:flutter/material.dart';

import '../theme/colors.dart';
import 'icons.dart';

/// One line of a menu; a null in the list is a divider.
class RgMenuEntry<T> {
  const RgMenuEntry(this.value, this.icon, this.label, {this.color, this.key, this.enabled = true});

  final T value;
  final RgIcons icon;
  final String label;

  /// A colour of its own (a stop in red).
  final Color? color;
  final Key? key;
  final bool enabled;
}

/// The menu at [at] (global coordinates); the value picked, or null.
Future<T?> showRgMenu<T>(BuildContext context, Offset at, List<RgMenuEntry<T>?> entries) {
  final c = RgColors.of(context);
  final overlay = Overlay.of(context).context.findRenderObject()! as RenderBox;
  final local = overlay.globalToLocal(at);
  return showMenu<T>(
    context: context,
    position: RelativeRect.fromRect(local & const Size(1, 1), Offset.zero & overlay.size),
    color: c.panel,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(12),
      side: BorderSide(color: c.line),
    ),
    items: [
      for (final e in entries)
        if (e == null)
          const PopupMenuDivider(height: 8)
        else
          PopupMenuItem<T>(
            key: e.key,
            value: e.value,
            enabled: e.enabled,
            height: 40,
            child: Row(
              children: [
                RgIcon(e.icon, size: 17, color: e.color ?? c.dim),
                const SizedBox(width: 12),
                Flexible(
                  child: Text(
                    e.label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(color: e.enabled ? (e.color ?? c.text) : c.dim, fontSize: 14),
                  ),
                ),
              ],
            ),
          ),
    ],
  );
}

/// The same items in a sheet from below, under a [head] (what they act on).
Future<T?> showRgSheet<T>(
  BuildContext context, {
  required Widget head,
  required List<RgMenuEntry<T>?> entries,
  Key? key,
}) => showModalBottomSheet<T>(
  context: context,
  showDragHandle: true,
  isScrollControlled: true,
  builder: (ctx) {
    final c = RgColors.of(ctx);
    return SafeArea(
      child: SingleChildScrollView(
        key: key,
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(padding: const EdgeInsets.fromLTRB(4, 0, 4, 12), child: head),
            Container(
              decoration: BoxDecoration(
                color: c.panel,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: c.line),
              ),
              clipBehavior: Clip.antiAlias,
              child: Column(
                children: [
                  for (final e in entries)
                    if (e == null)
                      Divider(height: 1, color: c.line)
                    else
                      Material(
                        color: Colors.transparent,
                        child: InkWell(
                          key: e.key,
                          onTap: e.enabled ? () => Navigator.of(ctx).pop(e.value) : null,
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                            child: Row(
                              children: [
                                RgIcon(e.icon, size: 19, color: e.color ?? c.dim),
                                const SizedBox(width: 14),
                                Expanded(
                                  child: Text(
                                    e.label,
                                    style: TextStyle(
                                      color: e.enabled ? (e.color ?? c.text) : c.dim,
                                      fontSize: 15,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  },
);

/// A head for [showRgSheet]: an icon (or a mascot), a title and a line under it.
class RgSheetHead extends StatelessWidget {
  const RgSheetHead({super.key, required this.leading, required this.title, this.subtitle});

  final Widget leading;
  final String title;
  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    final c = RgColors.of(context);
    return Row(
      children: [
        leading,
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: c.text),
              ),
              if (subtitle != null)
                Text(
                  subtitle!,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 13, color: c.dim),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

/// Right click: the menu at the pointer; long press: the sheet. [onMenu] gets where it was asked
/// (null for the long press).
class RgPress extends StatelessWidget {
  const RgPress({super.key, required this.onMenu, required this.child, this.longPress = true});

  final void Function(Offset? at) onMenu;
  final Widget child;
  final bool longPress;

  @override
  Widget build(BuildContext context) => GestureDetector(
    behavior: HitTestBehavior.opaque,
    onSecondaryTapUp: (d) => onMenu(d.globalPosition),
    onLongPress: longPress ? () => onMenu(null) : null,
    child: child,
  );
}

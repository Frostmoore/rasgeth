// The app's menus and shortcuts on computers (G40.17): one list of commands, shown in the system's
// menu bar on macOS (`PlatformMenuBar`), in a drawn menu bar on Windows and Linux, in the palette,
// and bound to the keyboard. Ctrl on Windows and Linux, Cmd on macOS.
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../api/types.dart';
import '../app_state.dart';
import '../l10n/app_localizations.dart';
import '../theme/colors.dart';
import '../ui/highlight.dart';
import '../ui/icons.dart';

class DeskCommand {
  const DeskCommand({
    required this.id,
    required this.label,
    required this.run,
    this.group,
    this.shortcut,
    this.icon,
    this.enabled = true,
    this.checked,
    this.bound = true,
  });

  /// Bound to the keyboard by the room (false: the text fields answer it themselves, as Copy).
  final bool bound;

  final String id;
  final String label;

  /// The menu it is in, as the palette shows it.
  final String? group;
  final VoidCallback run;
  final SingleActivator? shortcut;
  final RgIcons? icon;
  final bool enabled;

  /// A command that is on or off (shown with a check in the menu).
  final bool? checked;
}

class DeskMenu {
  const DeskMenu(this.label, this.items);

  final String label;

  /// null: a line between groups.
  final List<DeskCommand?> items;
}

/// macOS uses Cmd and the system's menu bar.
bool isMacLike(AppController app) => app.platform == DevicePlatform.macos;

/// Ctrl (Cmd on macOS) with [key].
SingleActivator cmdKey(
  LogicalKeyboardKey key, {
  required bool mac,
  bool shift = false,
  bool alt = false,
}) => SingleActivator(key, control: !mac, meta: mac, shift: shift, alt: alt);

/// «Ctrl+Maiusc+D», «Cmd+K», «Opz+Spazio»: in the person's words.
String shortcutLabel(SingleActivator a, AppLocalizations l, {required bool mac}) {
  final parts = <String>[
    if (a.control) 'Ctrl',
    if (a.meta) mac ? 'Cmd' : 'Win',
    if (a.alt) mac ? l.deskKeyOption : 'Alt',
    if (a.shift) l.deskKeyShift,
  ];
  final k = a.trigger;
  final name = switch (k) {
    LogicalKeyboardKey.space => l.deskKeySpace,
    LogicalKeyboardKey.enter => l.deskKeyEnter,
    LogicalKeyboardKey.escape => l.deskKeyEsc,
    LogicalKeyboardKey.tab => l.deskKeyTab,
    LogicalKeyboardKey.backslash => r'\',
    LogicalKeyboardKey.comma => ',',
    LogicalKeyboardKey.period => '.',
    LogicalKeyboardKey.slash => '/',
    _ => k.keyLabel.toUpperCase(),
  };
  return [...parts, name].join('+');
}

/// A key as it is drawn in the palette and the bars.
class KeyCap extends StatelessWidget {
  const KeyCap(this.text, {super.key, this.light = false});

  final String text;

  /// On a coloured button.
  final bool light;

  @override
  Widget build(BuildContext context) {
    final c = RgColors.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
      decoration: BoxDecoration(
        color: light ? Colors.white.withValues(alpha: .18) : c.panel2,
        borderRadius: BorderRadius.circular(5),
        border: Border.all(color: light ? Colors.white54 : c.line),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontFamily: monoFamily,
          fontFamilyFallback: monoFallback,
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: light ? Colors.white : c.dim,
        ),
      ),
    );
  }
}

/// Every command with a shortcut, bound to the keyboard. On macOS the system's menu bar answers
/// its own shortcuts: bound here are only those not in it ([extra]).
Map<ShortcutActivator, VoidCallback> deskBindings(
  List<DeskMenu> menus,
  List<DeskCommand> extra, {
  required bool mac,
}) => {
  for (final c in [
    if (!mac)
      for (final m in menus) ...m.items.whereType<DeskCommand>(),
    ...extra,
  ])
    if (c.shortcut != null && c.enabled && c.bound) c.shortcut!: c.run,
};

/// macOS: the menus in the system's menu bar (with the app's own menu first).
List<PlatformMenuItem> platformMenus(List<DeskMenu> menus, AppLocalizations l) => [
  PlatformMenu(
    label: 'RGCompanion',
    menus: [
      if (PlatformProvidedMenuItem.hasMenu(PlatformProvidedMenuItemType.about))
        const PlatformProvidedMenuItem(type: PlatformProvidedMenuItemType.about),
      // Empty where the system has neither (a group may not be empty).
      if (PlatformProvidedMenuItem.hasMenu(PlatformProvidedMenuItemType.hide) ||
          PlatformProvidedMenuItem.hasMenu(PlatformProvidedMenuItemType.quit))
        PlatformMenuItemGroup(
          members: [
            if (PlatformProvidedMenuItem.hasMenu(PlatformProvidedMenuItemType.hide))
              const PlatformProvidedMenuItem(type: PlatformProvidedMenuItemType.hide),
            if (PlatformProvidedMenuItem.hasMenu(PlatformProvidedMenuItemType.quit))
              const PlatformProvidedMenuItem(type: PlatformProvidedMenuItemType.quit),
          ],
        ),
    ],
  ),
  for (final m in menus)
    PlatformMenu(
      label: m.label,
      menus: [
        for (final group in _groups(m.items))
          PlatformMenuItemGroup(
            members: [
              for (final c in group)
                PlatformMenuItem(
                  label: c.label,
                  shortcut: c.shortcut,
                  onSelected: c.enabled ? c.run : null,
                ),
            ],
          ),
      ],
    ),
];

List<List<DeskCommand>> _groups(List<DeskCommand?> items) {
  final out = <List<DeskCommand>>[[]];
  for (final c in items) {
    if (c == null) {
      if (out.last.isNotEmpty) out.add([]);
    } else {
      out.last.add(c);
    }
  }
  return out.where((g) => g.isNotEmpty).toList();
}

/// Windows and Linux: the menus drawn in the window's top bar.
class DrawnMenuBar extends StatelessWidget {
  const DrawnMenuBar({super.key, required this.menus});

  final List<DeskMenu> menus;

  @override
  Widget build(BuildContext context) {
    final c = RgColors.of(context);
    final l = AppLocalizations.of(context);
    final style = MenuStyle(
      backgroundColor: WidgetStatePropertyAll(c.panel),
      side: WidgetStatePropertyAll(BorderSide(color: c.line)),
      shape: WidgetStatePropertyAll(
        RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
      padding: const WidgetStatePropertyAll(EdgeInsets.symmetric(vertical: 6)),
    );
    return MenuBar(
      key: const Key('desk-menubar'),
      style: MenuStyle(
        backgroundColor: const WidgetStatePropertyAll(Colors.transparent),
        elevation: const WidgetStatePropertyAll(0),
        padding: const WidgetStatePropertyAll(EdgeInsets.zero),
        shape: const WidgetStatePropertyAll(RoundedRectangleBorder()),
      ),
      children: [
        for (final m in menus)
          SubmenuButton(
            key: Key('menu-${m.label}'),
            menuStyle: style,
            style: ButtonStyle(
              padding: const WidgetStatePropertyAll(EdgeInsets.symmetric(horizontal: 9)),
              minimumSize: const WidgetStatePropertyAll(Size(0, 30)),
              foregroundColor: WidgetStatePropertyAll(c.text),
              textStyle: const WidgetStatePropertyAll(TextStyle(fontSize: 13.5)),
            ),
            menuChildren: [
              for (final it in m.items)
                if (it == null)
                  Divider(height: 9, color: c.line)
                else
                  MenuItemButton(
                    key: Key('menuitem-${it.id}'),
                    onPressed: it.enabled ? it.run : null,
                    leadingIcon: SizedBox(
                      width: 18,
                      child: it.checked == true
                          ? RgIcon(RgIcons.check, size: 15, color: c.accent)
                          : (it.icon == null ? null : RgIcon(it.icon!, size: 15, color: c.dim)),
                    ),
                    trailingIcon: it.shortcut == null
                        ? null
                        : Padding(
                            padding: const EdgeInsets.only(left: 18),
                            child: Text(
                              shortcutLabel(it.shortcut!, l, mac: false),
                              style: TextStyle(
                                fontSize: 12,
                                color: c.dim,
                                fontFamily: monoFamily,
                                fontFamilyFallback: monoFallback,
                              ),
                            ),
                          ),
                    style: ButtonStyle(
                      minimumSize: const WidgetStatePropertyAll(Size(240, 34)),
                      foregroundColor: WidgetStatePropertyAll(c.text),
                      textStyle: const WidgetStatePropertyAll(TextStyle(fontSize: 13.5)),
                    ),
                    child: Text(it.label),
                  ),
            ],
            child: Text(m.label),
          ),
      ],
    );
  }
}

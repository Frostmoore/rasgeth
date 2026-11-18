// G42.9: the pieces Settings › Automations is drawn with, as the page's (`SettingsKit.tsx`,
// `ui.tsx` and the `aw-`/`ax-`/`mg-` styles): big tiles lit when on, chips that choose one or many,
// a switch row, a field with its label and help, a drawn picker in place of the browser's
// <select>, time and date pickers drawn by us, the numbered parts of the editor, the sentence box,
// God's orb, and the window (a panel over the window on a computer, a sheet or a whole screen on
// a phone). Never a native checkbox, radio, switch or dialog.
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../l10n/app_localizations.dart';
import '../../screens/new_agent_screen.dart' show RgSwitch;
import '../../theme/colors.dart';
import '../../ui/dialogs.dart';
import '../../ui/icons.dart';

/// God's gold, as the page's `--god` and `--god-line`.
Color godColor(BuildContext context) =>
    Theme.of(context).brightness == Brightness.dark ? const Color(0xFFF0C24E) : const Color(0xFFB8860B);
Color godLine(BuildContext context) =>
    Theme.of(context).brightness == Brightness.dark ? const Color(0xFF6B5418) : const Color(0xFFE7CF86);

bool isWide(BuildContext context) => MediaQuery.sizeOf(context).width >= 760;

/// A window: over the page on a computer; on a phone a sheet from below, or a whole screen
/// ([full], for the editor and the magic conversation). [child] gets the way to close it.
Future<T?> openAutoWindow<T>(
  BuildContext context, {
  required String title,
  String? sub,
  Widget? icon,
  bool wide = false,
  bool full = false,
  bool scroll = true,
  Key? key,
  required Widget Function(BuildContext ctx, void Function([T?]) close) child,
}) {
  final c = RgColors.of(context);
  Widget head(BuildContext ctx, {required bool sheet}) => Padding(
    padding: EdgeInsets.fromLTRB(20, sheet ? 0 : 16, 8, 8),
    child: Row(
      children: [
        if (icon != null) ...[icon, const SizedBox(width: 12)],
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: c.text),
              ),
              if (sub != null)
                Text(sub, style: TextStyle(fontSize: 13, color: c.dim)),
            ],
          ),
        ),
        IconButton(
          key: const Key('au-window-close'),
          tooltip: AppLocalizations.of(ctx).close,
          onPressed: () => Navigator.of(ctx).pop(),
          icon: RgIcon(RgIcons.x, color: c.dim, size: 20),
        ),
      ],
    ),
  );
  Widget body(BuildContext ctx) {
    void close([T? v]) => Navigator.of(ctx).pop(v);
    final inner = child(ctx, close);
    return scroll
        ? SingleChildScrollView(
            padding: EdgeInsets.fromLTRB(20, 4, 20, 20 + MediaQuery.viewInsetsOf(ctx).bottom),
            child: inner,
          )
        : inner;
  }

  if (isWide(context)) {
    final size = MediaQuery.sizeOf(context);
    return showRgWindow<T>(
      context: context,
      builder: (ctx) => Dialog(
        key: key,
        insetPadding: const EdgeInsets.all(28),
        clipBehavior: Clip.antiAlias,
        backgroundColor: c.bg,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: wide ? 880 : 540,
            maxHeight: size.height * .92,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              head(ctx, sheet: false),
              Flexible(child: body(ctx)),
            ],
          ),
        ),
      ),
    );
  }
  if (full) {
    return Navigator.of(context).push<T>(
      MaterialPageRoute<T>(
        fullscreenDialog: true,
        builder: (ctx) => Scaffold(
          key: key,
          backgroundColor: c.bg,
          body: SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                head(ctx, sheet: false),
                Expanded(child: body(ctx)),
              ],
            ),
          ),
        ),
      ),
    );
  }
  return showModalBottomSheet<T>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    backgroundColor: c.bg,
    builder: (ctx) => SafeArea(
      child: KeyedSubtree(
        key: key ?? const Key('au-sheet'),
        child: ConstrainedBox(
          constraints: BoxConstraints(maxHeight: MediaQuery.sizeOf(ctx).height * .9),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              head(ctx, sheet: true),
              Flexible(child: body(ctx)),
            ],
          ),
        ),
      ),
    ),
  );
}

/// God's orb (the page's `mg-orb`): the spark on a gold-to-accent circle.
class GodOrb extends StatelessWidget {
  const GodOrb({super.key, this.size = 36});

  final double size;

  @override
  Widget build(BuildContext context) {
    final c = RgColors.of(context);
    final god = godColor(context);
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [god, c.accent],
        ),
        boxShadow: [BoxShadow(color: god.withValues(alpha: .18), spreadRadius: 4)],
      ),
      child: Center(child: RgIcon(RgIcons.spark, size: size * .5, color: Colors.white)),
    );
  }
}

/// A big square (the page's `Tile`): an icon, a title, a line, its state; lit when [on].
class AutoTile extends StatelessWidget {
  const AutoTile({
    super.key,
    required this.icon,
    required this.title,
    this.text,
    this.state,
    this.badge,
    this.on = false,
    required this.onTap,
    this.trailing,
  });

  final RgIcons icon;
  final String title;
  final String? text;
  final String? state;
  final String? badge;
  final bool on;
  final VoidCallback onTap;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final c = RgColors.of(context);
    return Semantics(
      button: true,
      selected: on,
      child: Material(
        color: on ? c.accentSoft : c.panel,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
          side: BorderSide(color: on ? c.accent : c.line, width: 2),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 46,
                  height: 46,
                  decoration: BoxDecoration(
                    color: on ? c.accent : c.panel2,
                    borderRadius: BorderRadius.circular(13),
                  ),
                  child: Center(child: RgIcon(icon, size: 22, color: on ? Colors.white : c.text)),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (badge != null)
                        Container(
                          margin: const EdgeInsets.only(bottom: 6),
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: c.warn.withValues(alpha: .16),
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: Text(
                            badge!.toUpperCase(),
                            style: TextStyle(
                              fontSize: 11,
                              letterSpacing: .4,
                              fontWeight: FontWeight.w800,
                              color: c.warnText,
                            ),
                          ),
                        ),
                      Text(
                        title,
                        style: TextStyle(
                          fontSize: 16.5,
                          fontWeight: FontWeight.w800,
                          color: c.text,
                          height: 1.25,
                        ),
                      ),
                      if (text != null && text!.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Text(
                            text!,
                            maxLines: 3,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(color: c.dim, fontSize: 14, height: 1.4),
                          ),
                        ),
                      if (state != null && state!.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Text(
                            state!,
                            style: TextStyle(
                              color: on ? c.accent : c.dim,
                              fontSize: 12.5,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                ?trailing,
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Tiles two in a row when there is room (the page's `wz-brain`).
class AutoGrid extends StatelessWidget {
  const AutoGrid({super.key, required this.children, this.min = 300});

  final List<Widget> children;
  final double min;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, box) {
      final two = box.maxWidth >= min * 2 + 12;
      final w = two ? (box.maxWidth - 12) / 2 : box.maxWidth;
      return Wrap(
        spacing: 12,
        runSpacing: 12,
        children: [for (final ch in children) SizedBox(width: w, child: ch)],
      );
    },
  );
}

/// Chips that choose one or many (the page's `Chips`): drawn, never a native checkbox.
class AutoChips<T> extends StatelessWidget {
  const AutoChips({
    super.key,
    required this.options,
    required this.value,
    required this.onChanged,
    required this.keyOf,
    this.multiple = false,
  });

  final List<(T, String)> options;
  final List<T> value;
  final ValueChanged<List<T>>? onChanged;
  final String Function(T) keyOf;
  final bool multiple;

  @override
  Widget build(BuildContext context) {
    final c = RgColors.of(context);
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (final (v, label) in options)
          Builder(
            builder: (context) {
              final on = value.contains(v);
              return Semantics(
                button: true,
                selected: on,
                child: Material(
                  color: on ? c.accentSoft : c.panel2,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(999),
                    side: BorderSide(color: on ? c.accent : c.line, width: on ? 1.5 : 1),
                  ),
                  child: InkWell(
                    key: Key(keyOf(v)),
                    borderRadius: BorderRadius.circular(999),
                    onTap: onChanged == null
                        ? null
                        : () {
                            if (multiple) {
                              onChanged!(on ? value.where((x) => x != v).toList() : [...value, v]);
                            } else if (!on) {
                              onChanged!([v]);
                            }
                          },
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 8),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (multiple && on) ...[
                            RgIcon(RgIcons.check, size: 13, color: c.accent),
                            const SizedBox(width: 5),
                          ],
                          Flexible(
                            child: Text(
                              label,
                              style: TextStyle(
                                fontSize: 13.5,
                                color: on ? c.text : c.dim,
                                fontWeight: on ? FontWeight.w700 : FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
      ],
    );
  }
}

/// A row with a title, its help and our switch (the page's `SwitchRow`).
class SwitchLine extends StatelessWidget {
  const SwitchLine({
    super.key,
    required this.title,
    this.help,
    required this.on,
    required this.onChanged,
  });

  final String title;
  final String? help;
  final bool on;
  final ValueChanged<bool>? onChanged;

  @override
  Widget build(BuildContext context) {
    final c = RgColors.of(context);
    return Semantics(
      toggled: on,
      button: true,
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: onChanged == null ? null : () => onChanged!(!on),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(fontWeight: FontWeight.w700, color: c.text, fontSize: 14.5),
                    ),
                    if (help != null && help!.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 2),
                        child: Text(
                          help!,
                          style: TextStyle(color: c.dim, fontSize: 12.5, height: 1.35),
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Opacity(opacity: onChanged == null ? .5 : 1, child: RgSwitch(on: on)),
            ],
          ),
        ),
      ),
    );
  }
}

/// A label over its control, with a line of help (the page's `Field`).
class AutoLabel extends StatelessWidget {
  const AutoLabel({super.key, required this.label, this.help, required this.child});

  final String label;
  final String? help;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final c = RgColors.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            label,
            style: TextStyle(fontWeight: FontWeight.w700, color: c.text, fontSize: 13.5),
          ),
          const SizedBox(height: 6),
          child,
          if (help != null && help!.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(help!, style: TextStyle(color: c.dim, fontSize: 12.5, height: 1.35)),
            ),
        ],
      ),
    );
  }
}

InputDecoration autoInput(BuildContext context, {String? hint, String? prefix}) {
  final c = RgColors.of(context);
  OutlineInputBorder b(Color col, [double w = 1]) => OutlineInputBorder(
    borderRadius: BorderRadius.circular(12),
    borderSide: BorderSide(color: col, width: w),
  );
  return InputDecoration(
    isDense: true,
    hintText: hint,
    prefixText: prefix,
    filled: true,
    fillColor: c.panel,
    hintStyle: TextStyle(color: c.dim),
    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
    border: b(c.line),
    enabledBorder: b(c.line),
    focusedBorder: b(c.accent, 1.6),
  );
}

/// A text field that keeps its own controller in step with [value] (a template may change it).
class AutoField extends StatefulWidget {
  const AutoField({
    super.key,
    required this.label,
    this.help,
    required this.value,
    required this.onChanged,
    this.hint,
    this.lines = 1,
    this.mono = false,
    this.number = false,
    this.decimal = false,
    this.fieldKey,
    this.enabled = true,
    this.prefix,
  });

  final String label;
  final String? help;
  final String value;
  final ValueChanged<String> onChanged;
  final String? hint;
  final int lines;
  final bool mono;
  final bool number;
  final bool decimal;
  final Key? fieldKey;
  final bool enabled;
  final String? prefix;

  @override
  State<AutoField> createState() => _AutoFieldState();
}

class _AutoFieldState extends State<AutoField> {
  late final _ctl = TextEditingController(text: widget.value);

  @override
  void didUpdateWidget(AutoField old) {
    super.didUpdateWidget(old);
    if (widget.value != _ctl.text && widget.value.trim() != _ctl.text.trim()) {
      _ctl.text = widget.value;
    }
  }

  @override
  void dispose() {
    _ctl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = RgColors.of(context);
    return AutoLabel(
      label: widget.label,
      help: widget.help,
      child: TextField(
        key: widget.fieldKey,
        controller: _ctl,
        enabled: widget.enabled,
        minLines: widget.lines,
        maxLines: widget.lines == 1 ? 1 : widget.lines + 6,
        keyboardType: widget.number
            ? TextInputType.numberWithOptions(decimal: widget.decimal)
            : (widget.lines > 1 ? TextInputType.multiline : TextInputType.text),
        inputFormatters: widget.number
            ? [FilteringTextInputFormatter.allow(RegExp(widget.decimal ? r'[\d.,]' : r'\d'))]
            : null,
        style: TextStyle(
          color: c.text,
          fontSize: 14.5,
          fontFamily: widget.mono ? 'monospace' : null,
        ),
        decoration: autoInput(context, hint: widget.hint, prefix: widget.prefix),
        onChanged: widget.onChanged,
      ),
    );
  }
}

/// A drawn box that opens a choice ([pickOne]): the page's <select>, never the native one.
class PickBox<T> extends StatelessWidget {
  const PickBox({
    super.key,
    required this.label,
    this.help,
    required this.options,
    required this.value,
    required this.onChanged,
    this.boxKey,
    this.keyOf,
  });

  final String label;
  final String? help;
  final List<(T, String)> options;
  final T value;
  final ValueChanged<T>? onChanged;
  final Key? boxKey;
  final String Function(T)? keyOf;

  @override
  Widget build(BuildContext context) {
    final c = RgColors.of(context);
    final shown = options.where((o) => o.$1 == value).firstOrNull?.$2 ?? '';
    return AutoLabel(
      label: label,
      help: help,
      child: Material(
        color: c.panel,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: c.line),
        ),
        child: InkWell(
          key: boxKey,
          borderRadius: BorderRadius.circular(12),
          onTap: onChanged == null
              ? null
              : () async {
                  final v = await pickOne<T>(
                    context,
                    title: label,
                    options: options,
                    value: value,
                    keyOf: keyOf,
                  );
                  if (v != null) onChanged!(v.$1);
                },
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    shown,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(color: c.text, fontSize: 14.5),
                  ),
                ),
                RgIcon(RgIcons.chevronDown, size: 18, color: c.dim),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// One choice among [options], in our window: the value (in a record, so null can be chosen too),
/// or null when closed.
Future<(T,)?> pickOne<T>(
  BuildContext context, {
  required String title,
  required List<(T, String)> options,
  required T value,
  String Function(T)? keyOf,
}) {
  return openAutoWindow<(T,)>(
    context,
    title: title,
    key: const Key('au-pick'),
    child: (ctx, close) {
      final c = RgColors.of(ctx);
      return Container(
        decoration: BoxDecoration(
          color: c.panel,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: c.line),
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          children: [
            for (final (i, (v, label)) in options.indexed) ...[
              if (i > 0) Divider(height: 1, color: c.line),
              _PickLine(
                key: Key(keyOf != null ? keyOf(v) : 'au-pick-$i'),
                label: label,
                selected: v == value,
                onTap: () => close((v,)),
              ),
            ],
          ],
        ),
      );
    },
  );
}

class _PickLine extends StatelessWidget {
  const _PickLine({super.key, required this.label, required this.selected, required this.onTap});

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = RgColors.of(context);
    return Semantics(
      selected: selected,
      button: true,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(
                    color: c.text,
                    fontSize: 15,
                    fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                  ),
                ),
              ),
              Container(
                width: 20,
                height: 20,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: selected ? c.accent : Colors.transparent,
                  border: Border.all(color: selected ? c.accent : c.line, width: 2),
                ),
                child: selected
                    ? const Center(child: RgIcon(RgIcons.check, size: 12, color: Colors.white))
                    : null,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

String _two(int n) => n.toString().padLeft(2, '0');

/// A time of day, «HH:MM», chosen on a drawn dial of hours and minutes (never the system's).
class TimeBox extends StatelessWidget {
  const TimeBox({
    super.key,
    required this.label,
    required this.value,
    required this.onChanged,
    this.boxKey,
  });

  final String label;
  final String value;
  final ValueChanged<String> onChanged;
  final Key? boxKey;

  @override
  Widget build(BuildContext context) => _ValueBox(
    label: label,
    shown: value,
    icon: RgIcons.clock,
    boxKey: boxKey,
    onTap: () async {
      final v = await pickTime(context, title: label, value: value);
      if (v != null) onChanged(v);
    },
  );
}

/// A day, «YYYY-MM-DD», on a drawn month.
class DateBox extends StatelessWidget {
  const DateBox({
    super.key,
    required this.label,
    required this.value,
    required this.onChanged,
    this.boxKey,
    this.empty = '',
  });

  final String label;
  final String value;
  final ValueChanged<String> onChanged;
  final Key? boxKey;
  final String empty;

  @override
  Widget build(BuildContext context) => _ValueBox(
    label: label,
    shown: value.isEmpty ? empty : value,
    icon: RgIcons.clock,
    boxKey: boxKey,
    onTap: () async {
      final v = await pickDate(context, title: label, value: value);
      if (v != null) onChanged(v);
    },
  );
}

class _ValueBox extends StatelessWidget {
  const _ValueBox({
    required this.label,
    required this.shown,
    required this.icon,
    required this.onTap,
    this.boxKey,
  });

  final String label;
  final String shown;
  final RgIcons icon;
  final VoidCallback onTap;
  final Key? boxKey;

  @override
  Widget build(BuildContext context) {
    final c = RgColors.of(context);
    return AutoLabel(
      label: label,
      child: Material(
        color: c.panel,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: c.line),
        ),
        child: InkWell(
          key: boxKey,
          borderRadius: BorderRadius.circular(12),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            child: Row(
              children: [
                RgIcon(icon, size: 17, color: c.accent),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    shown,
                    style: TextStyle(
                      color: c.text,
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      fontFeatures: const [FontFeature.tabularFigures()],
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
}

/// Our time picker: the hours in a grid, then the minutes (every five, or one written).
Future<String?> pickTime(BuildContext context, {required String title, required String value}) {
  final m = RegExp(r'^(\d{1,2}):(\d{2})$').firstMatch(value);
  var h = m == null ? 9 : int.parse(m.group(1)!).clamp(0, 23);
  var min = m == null ? 0 : int.parse(m.group(2)!).clamp(0, 59);
  return openAutoWindow<String>(
    context,
    title: title,
    key: const Key('au-time'),
    child: (ctx, close) => StatefulBuilder(
      builder: (ctx, set) {
        final c = RgColors.of(ctx);
        final l = AppLocalizations.of(ctx);
        Widget cell(String text, bool on, VoidCallback tap, Key key) => Material(
          color: on ? c.accent : c.panel2,
          borderRadius: BorderRadius.circular(10),
          child: InkWell(
            key: key,
            borderRadius: BorderRadius.circular(10),
            onTap: tap,
            child: SizedBox(
              width: 50,
              height: 40,
              child: Center(
                child: Text(
                  text,
                  style: TextStyle(
                    color: on ? Colors.white : c.text,
                    fontWeight: on ? FontWeight.w800 : FontWeight.w600,
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                ),
              ),
            ),
          ),
        );
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Text(
                '${_two(h)}:${_two(min)}',
                key: const Key('au-time-shown'),
                style: TextStyle(
                  fontSize: 40,
                  fontWeight: FontWeight.w800,
                  color: c.text,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              alignment: WrapAlignment.center,
              children: [
                for (var i = 0; i < 24; i++)
                  cell(_two(i), i == h, () => set(() => h = i), Key('au-time-h-$i')),
              ],
            ),
            const SizedBox(height: 14),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              alignment: WrapAlignment.center,
              children: [
                for (var i = 0; i < 60; i += 5)
                  cell(':${_two(i)}', i == min, () => set(() => min = i), Key('au-time-m-$i')),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(onPressed: () => close(), child: Text(l.cancel)),
                const SizedBox(width: 8),
                FilledButton(
                  key: const Key('au-time-ok'),
                  onPressed: () => close('${_two(h)}:${_two(min)}'),
                  child: Text(l.auOwnPickTitle),
                ),
              ],
            ),
          ],
        );
      },
    ),
  );
}

/// Our date picker: a month drawn as a grid, Monday first.
Future<String?> pickDate(BuildContext context, {required String title, required String value}) {
  final start = DateTime.tryParse(value) ?? DateTime.now();
  var month = DateTime(start.year, start.month);
  var chosen = DateTime.tryParse(value);
  return openAutoWindow<String>(
    context,
    title: title,
    key: const Key('au-date'),
    child: (ctx, close) => StatefulBuilder(
      builder: (ctx, set) {
        final c = RgColors.of(ctx);
        final l = AppLocalizations.of(ctx);
        final first = DateTime(month.year, month.month);
        final lead = (first.weekday + 6) % 7;
        final days = DateTime(month.year, month.month + 1, 0).day;
        String iso(DateTime d) => '${d.year}-${_two(d.month)}-${_two(d.day)}';
        final names = MaterialLocalizations.of(ctx);
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                IconButton(
                  key: const Key('au-date-prev'),
                  onPressed: () => set(() => month = DateTime(month.year, month.month - 1)),
                  icon: RgIcon(RgIcons.chevronLeft, color: c.text),
                ),
                Expanded(
                  child: Text(
                    names.formatMonthYear(month),
                    textAlign: TextAlign.center,
                    style: TextStyle(fontWeight: FontWeight.w800, color: c.text, fontSize: 16),
                  ),
                ),
                IconButton(
                  key: const Key('au-date-next'),
                  onPressed: () => set(() => month = DateTime(month.year, month.month + 1)),
                  icon: RgIcon(RgIcons.chevronRight, color: c.text),
                ),
              ],
            ),
            const SizedBox(height: 6),
            GridView.count(
              crossAxisCount: 7,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              mainAxisSpacing: 4,
              crossAxisSpacing: 4,
              children: [
                for (var i = 0; i < 7; i++)
                  Center(
                    child: Text(
                      names.narrowWeekdays[(i + 1) % 7],
                      style: TextStyle(color: c.dim, fontWeight: FontWeight.w700, fontSize: 12),
                    ),
                  ),
                for (var i = 0; i < lead; i++) const SizedBox(),
                for (var d = 1; d <= days; d++)
                  Builder(
                    builder: (_) {
                      final day = DateTime(month.year, month.month, d);
                      final on = chosen != null && iso(chosen!) == iso(day);
                      return Material(
                        color: on ? c.accent : Colors.transparent,
                        shape: const CircleBorder(),
                        child: InkWell(
                          key: Key('au-date-${iso(day)}'),
                          customBorder: const CircleBorder(),
                          onTap: () => set(() => chosen = day),
                          child: Center(
                            child: Text(
                              '$d',
                              style: TextStyle(
                                color: on ? Colors.white : c.text,
                                fontWeight: on ? FontWeight.w800 : FontWeight.w500,
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                if (value.isNotEmpty)
                  TextButton(
                    key: const Key('au-date-clear'),
                    onPressed: () => close(''),
                    child: Text(l.auAxNone),
                  ),
                const Spacer(),
                TextButton(onPressed: () => close(), child: Text(l.cancel)),
                const SizedBox(width: 8),
                FilledButton(
                  key: const Key('au-date-ok'),
                  onPressed: chosen == null ? null : () => close(iso(chosen!)),
                  child: Text(l.auOwnPickTitle),
                ),
              ],
            ),
          ],
        );
      },
    ),
  );
}

/// One part of the editor: a numbered head, a line of help, the choices (the page's `Part`).
class AutoPart extends StatelessWidget {
  const AutoPart({
    super.key,
    required this.n,
    required this.icon,
    required this.title,
    required this.help,
    required this.children,
  });

  final int n;
  final RgIcons icon;
  final String title;
  final String help;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final c = RgColors.of(context);
    return Container(
      margin: const EdgeInsets.only(top: 14),
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
      decoration: BoxDecoration(
        color: c.panel,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: c.line),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(color: c.accentSoft, shape: BoxShape.circle),
                child: Center(
                  child: Text(
                    '$n',
                    style: TextStyle(color: c.accent, fontWeight: FontWeight.w800),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              RgIcon(icon, size: 18, color: c.dim),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: c.text),
                    ),
                    Text(help, style: TextStyle(color: c.dim, fontSize: 12.5, height: 1.3)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...children,
        ],
      ),
    );
  }
}

/// A condition that opens its fields when switched on (the page's `Cond`).
class AutoCond extends StatelessWidget {
  const AutoCond({
    super.key,
    required this.title,
    this.help,
    required this.on,
    required this.onChanged,
    this.children = const [],
  });

  final String title;
  final String? help;
  final bool on;
  final ValueChanged<bool> onChanged;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final c = RgColors.of(context);
    return AnimatedContainer(
      duration: const Duration(milliseconds: 160),
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.fromLTRB(12, 2, 12, 2),
      decoration: BoxDecoration(
        color: on ? c.accentSoft.withValues(alpha: .45) : c.panel2,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: on ? c.accent.withValues(alpha: .6) : c.line),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SwitchLine(title: title, help: help, on: on, onChanged: onChanged),
          if (on && children.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 6, bottom: 8),
              child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: children),
            ),
        ],
      ),
    );
  }
}

/// A detail under «When» (the page's `ax-detail`): a small title and its fields.
class AutoDetail extends StatelessWidget {
  const AutoDetail({super.key, required this.icon, required this.title, required this.children});

  final RgIcons icon;
  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final c = RgColors.of(context);
    return Container(
      margin: const EdgeInsets.only(top: 12),
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 6),
      decoration: BoxDecoration(
        color: c.panel2,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: c.line),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              RgIcon(icon, size: 16, color: c.accent),
              const SizedBox(width: 8),
              Text(
                title,
                style: TextStyle(fontWeight: FontWeight.w800, color: c.text, fontSize: 14),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ...children,
        ],
      ),
    );
  }
}

/// Fields side by side when there is room (the page's `aw-when-row`).
class AutoRow extends StatelessWidget {
  const AutoRow({super.key, required this.children, this.min = 200});

  final List<Widget> children;
  final double min;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, box) {
      final n = children.length;
      var per = n;
      while (per > 1 && (box.maxWidth - 12 * (per - 1)) / per < min) {
        per--;
      }
      final w = (box.maxWidth - 12 * (per - 1)) / per;
      return Wrap(
        spacing: 12,
        children: [for (final ch in children) SizedBox(width: w, child: ch)],
      );
    },
  );
}

/// The automation in words, live (the page's `ax-says`).
class SaysBox extends StatelessWidget {
  const SaysBox({super.key, required this.lines, this.icon = true});

  final List<String> lines;
  final bool icon;

  @override
  Widget build(BuildContext context) {
    final c = RgColors.of(context);
    return Semantics(
      liveRegion: true,
      child: Container(
        key: const Key('au-says'),
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
        decoration: BoxDecoration(
          color: Color.alphaBlend(c.ok.withValues(alpha: .15), c.panel),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: c.ok.withValues(alpha: .45)),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (icon) ...[
              Padding(
                padding: const EdgeInsets.only(top: 2),
                child: RgIcon(RgIcons.zap, size: 20, color: c.ok),
              ),
              const SizedBox(width: 12),
            ],
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  for (final (i, line) in lines.indexed)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 2),
                      child: Text(
                        line,
                        style: TextStyle(
                          color: c.text,
                          height: 1.45,
                          fontSize: 14.5,
                          fontWeight: i == 0 ? FontWeight.w700 : FontWeight.w400,
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
  }
}

/// A notice (the page's `notice ok` / `notice error`).
class AutoNotice extends StatelessWidget {
  const AutoNotice(this.text, {super.key, this.error = false, this.child});

  final String text;
  final bool error;
  final Widget? child;

  @override
  Widget build(BuildContext context) {
    final c = RgColors.of(context);
    final col = error ? c.err : c.ok;
    return Container(
      margin: const EdgeInsets.only(top: 10, bottom: 4),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: col.withValues(alpha: .08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: col.withValues(alpha: .35)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(text, style: TextStyle(color: c.text, fontSize: 13.5, height: 1.4)),
          ?child,
        ],
      ),
    );
  }
}

/// A small label over a group (the page's `wz-lb`).
class AutoLb extends StatelessWidget {
  const AutoLb(this.text, {super.key});

  final String text;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(top: 6, bottom: 8),
    child: Text(
      text,
      style: TextStyle(
        fontWeight: FontWeight.w700,
        color: RgColors.of(context).text,
        fontSize: 13.5,
      ),
    ),
  );
}

/// A line of help (the page's `ui-help`).
class AutoHelp extends StatelessWidget {
  const AutoHelp(this.text, {super.key});

  final String text;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(top: 6, bottom: 4),
    child: Text(
      text,
      style: TextStyle(color: RgColors.of(context).dim, fontSize: 12.5, height: 1.4),
    ),
  );
}

/// The copy button of a secret or an address: copied, then «Copied» for a moment.
class CopyButton extends StatefulWidget {
  const CopyButton({super.key, required this.text, this.buttonKey});

  final String text;
  final Key? buttonKey;

  @override
  State<CopyButton> createState() => _CopyButtonState();
}

class _CopyButtonState extends State<CopyButton> {
  bool _done = false;
  Timer? _t;

  @override
  void dispose() {
    _t?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final c = RgColors.of(context);
    return TextButton.icon(
      key: widget.buttonKey,
      onPressed: () async {
        await Clipboard.setData(ClipboardData(text: widget.text));
        if (!mounted) return;
        setState(() => _done = true);
        _t?.cancel();
        _t = Timer(const Duration(seconds: 2), () {
          if (mounted) setState(() => _done = false);
        });
      },
      icon: RgIcon(_done ? RgIcons.check : RgIcons.copy, size: 16, color: c.accent),
      label: Text(_done ? l.auOwnCopied : l.auOwnCopy),
    );
  }
}

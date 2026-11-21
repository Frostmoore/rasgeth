// G42.14: the pieces the system's settings share, drawn as the page's SettingsKit (Head, Sub, Box,
// SCard, Facts, Tile, Seg, Acts, the wizard's notes), ui.tsx (Field, Advanced, JobView) and
// OwnInfra's CopyBlock. Our drawn controls only: no native switch, checkbox or radio, no emoji, no
// symbol as an icon.
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../api/client.dart';
import '../../api/code.dart' show JobView;
import '../../app_state.dart';
import '../../l10n/app_localizations.dart';
import '../../theme/colors.dart';
import '../../ui/chat/file_download.dart' show byteWords, shortDuration;
import '../../ui/icons.dart';
import '../../ui/labeled_field.dart';
import '../../ui/settings_kit.dart';
import '../api/system_api.dart';
import 'system_words.g.dart';

export '../automations/automation_kit.dart' show SwitchLine;

/// The client, or null when the app is not connected.
RedGiantClient? sysClient(BuildContext context) => AppScope.read(context).client;

/// A screen of the system's settings, pushed.
Future<void> openSystemScreen(BuildContext context, Widget screen) =>
    Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => screen));

/// An error in the person's words: the page's `fbErr_<code>`, `osErr_<code>`, `err_<code>`, else
/// the server's message (the page's `explain` and `tryIt`).
String sysError(AppLocalizations l, Object e) {
  if (e is ApiException) {
    final code = e.code;
    if (code != null) {
      for (final p in const ['fbErr_', 'err_', 'osErr_']) {
        final w = syWord(l, '$p$code', e.vars);
        if (w != null) return w;
      }
    }
    return e.message;
  }
  return '$e';
}

/// The page's word, or the key itself when the page has none.
String sw(AppLocalizations l, String key, [Map<String, String> v = const {}]) =>
    syWord(l, key, v) ?? key;

/// A number as people read it, one decimal at most (the page's `num`).
String sysNum(BuildContext context, num n) {
  final it = Localizations.localeOf(context).languageCode == 'it';
  final r = (n * 10).round() / 10;
  final s = r == r.roundToDouble() ? r.toInt().toString() : r.toStringAsFixed(1);
  return it ? s.replaceAll('.', ',') : s;
}

/// «1,8 TB», «512 GB» (FirstBoot's `size`); below 10 GB with a decimal, MB below 1 GB
/// (BackupTargets' `size`).
String sysSize(BuildContext context, num bytes, {bool small = false}) {
  final gb = bytes / (1024 * 1024 * 1024);
  if (gb >= 1000) return '${sysNum(context, (gb / 102.4).round() / 10)} TB';
  if (!small || gb >= 10) return '${sysNum(context, gb.round())} GB';
  if (gb >= 1) return '${sysNum(context, (gb * 10).round() / 10)} GB';
  return '${sysNum(context, (bytes / (1024 * 1024)).round())} MB';
}

/// A date and time, short (the page's `toLocaleString`).
String sysWhen(String? iso) {
  final t = iso == null ? null : DateTime.tryParse(iso)?.toLocal();
  if (t == null) return iso ?? '';
  String two(int n) => n.toString().padLeft(2, '0');
  return '${two(t.day)}/${two(t.month)}/${t.year} ${two(t.hour)}:${two(t.minute)}';
}

/// The page's big heading: a small eyebrow, the question, its lead.
class SysHead extends StatelessWidget {
  const SysHead({super.key, this.eyebrow, required this.q, this.lead});

  final String? eyebrow;
  final String q;
  final String? lead;

  @override
  Widget build(BuildContext context) {
    final c = RgColors.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (eyebrow != null)
            Text(
              eyebrow!.toUpperCase(),
              style: TextStyle(
                fontSize: 11.5,
                letterSpacing: .8,
                fontWeight: FontWeight.w700,
                color: c.accent,
              ),
            ),
          Semantics(
            header: true,
            child: Text(
              q,
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: c.text),
            ),
          ),
          if (lead != null)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(lead!, style: TextStyle(color: c.dim, fontSize: 14, height: 1.4)),
            ),
        ],
      ),
    );
  }
}

/// A part's title and its lead (the page's `Sub`).
class SysSub extends StatelessWidget {
  const SysSub(this.title, {super.key, this.lead, this.inside = false});

  final String title;
  final String? lead;

  /// Inside a card (no outer margin).
  final bool inside;

  @override
  Widget build(BuildContext context) {
    final c = RgColors.of(context);
    return Padding(
      padding: EdgeInsets.fromLTRB(inside ? 0 : 16, 18, inside ? 0 : 16, 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Semantics(
            header: true,
            child: Text(
              title,
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: c.text),
            ),
          ),
          if (lead != null && lead!.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 2),
              child: Text(lead!, style: TextStyle(color: c.dim, fontSize: 13, height: 1.4)),
            ),
        ],
      ),
    );
  }
}

/// A box (the page's `Box`), or a card with its icon, title and question (`SCard`).
class SysBox extends StatelessWidget {
  const SysBox({super.key, required this.children, this.icon, this.title, this.q});

  final List<Widget> children;
  final RgIcons? icon;
  final String? title;
  final String? q;

  @override
  Widget build(BuildContext context) {
    final c = RgColors.of(context);
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 6, 16, 6),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: c.panel,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: c.line),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (title != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (icon != null) ...[
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: c.accentSoft,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Center(child: RgIcon(icon!, size: 20, color: c.accent)),
                    ),
                    const SizedBox(width: 10),
                  ],
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title!,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            color: c.text,
                          ),
                        ),
                        if (q != null)
                          Text(q!, style: TextStyle(color: c.dim, fontSize: 13, height: 1.35)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ...children,
        ],
      ),
    );
  }
}

/// Facts in two columns (the page's `Facts`): the label dim, the value beside or under it.
class SysFacts extends StatelessWidget {
  const SysFacts(this.rows, {super.key});

  /// (label, a text or a widget).
  final List<(String, Object)> rows;

  @override
  Widget build(BuildContext context) {
    final c = RgColors.of(context);
    return LayoutBuilder(
      builder: (context, box) {
        final wide = box.maxWidth > 420;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            for (final (k, v) in rows)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Flex(
                  direction: wide ? Axis.horizontal : Axis.vertical,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(
                      width: wide ? 150 : null,
                      child: Text(
                        k,
                        style: TextStyle(color: c.dim, fontSize: 13, fontWeight: FontWeight.w600),
                      ),
                    ),
                    if (wide) Expanded(child: _value(c, v)) else _value(c, v),
                  ],
                ),
              ),
          ],
        );
      },
    );
  }

  Widget _value(RgColors c, Object v) =>
      v is Widget ? v : SelectableText('$v', style: TextStyle(color: c.text, fontSize: 14));
}

/// Monospaced text that can be selected (a fingerprint, a path, a key).
class SysMono extends StatelessWidget {
  const SysMono(this.text, {super.key, this.size = 12.5});

  final String text;
  final double size;

  @override
  Widget build(BuildContext context) => SelectableText(
    text,
    style: TextStyle(fontFamily: 'monospace', fontSize: size, color: RgColors.of(context).text),
  );
}

/// The wizard's square (the page's `Tile`): lit by border and background when chosen.
class SysTile extends StatelessWidget {
  const SysTile({
    super.key,
    required this.on,
    required this.icon,
    required this.title,
    this.text,
    this.state,
    this.badge,
    this.onTap,
  });

  final bool on;
  final RgIcons icon;
  final String title;
  final String? text;
  final String? state;
  final String? badge;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final c = RgColors.of(context);
    return Semantics(
      button: true,
      selected: on,
      child: Material(
        color: on ? c.accentSoft : c.panel2,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: on ? c.accent : c.line, width: on ? 1.6 : 1),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                RgIcon(icon, size: 22, color: on ? c.accent : c.dim),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Wrap(
                        spacing: 6,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          Text(
                            title,
                            style: TextStyle(
                              fontWeight: FontWeight.w800,
                              color: c.text,
                              fontSize: 14.5,
                            ),
                          ),
                          if (badge != null) SysPill(badge!, tone: c.accent),
                        ],
                      ),
                      if (text != null && text!.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 2),
                          child: Text(
                            text!,
                            style: TextStyle(color: c.dim, fontSize: 12.5, height: 1.35),
                          ),
                        ),
                      if (state != null)
                        Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Text(
                            state!,
                            style: TextStyle(
                              color: on ? c.accent : c.dim,
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                    ],
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

/// Squares two by two on a computer, one under the other on a phone.
class SysTiles extends StatelessWidget {
  const SysTiles({super.key, required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 6),
    child: LayoutBuilder(
      builder: (context, box) {
        final two = box.maxWidth >= 520;
        final w = two ? (box.maxWidth - 10) / 2 : box.maxWidth;
        return Wrap(
          spacing: 10,
          runSpacing: 10,
          children: [for (final t in children) SizedBox(width: w, child: t)],
        );
      },
    ),
  );
}

/// A small coloured word (a state, a badge).
class SysPill extends StatelessWidget {
  const SysPill(this.text, {super.key, required this.tone});

  final String text;
  final Color tone;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
    decoration: BoxDecoration(
      color: tone.withValues(alpha: .14),
      borderRadius: BorderRadius.circular(99),
    ),
    child: Text(
      text,
      style: TextStyle(color: tone, fontSize: 11.5, fontWeight: FontWeight.w700),
    ),
  );
}

/// One choice among a few (the page's `Seg`), our own drawn segments; they wrap on a phone.
class SysSeg<T> extends StatelessWidget {
  const SysSeg({
    super.key,
    required this.options,
    required this.value,
    required this.onChanged,
    this.keyPrefix = 'seg',
  });

  final List<(T, String)> options;
  final T? value;
  final ValueChanged<T>? onChanged;
  final String keyPrefix;

  @override
  Widget build(BuildContext context) {
    final c = RgColors.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Wrap(
        spacing: 6,
        runSpacing: 6,
        children: [
          for (final (v, label) in options)
            Semantics(
              button: true,
              selected: v == value,
              child: Material(
                color: v == value ? c.accentSoft : c.panel2,
                borderRadius: BorderRadius.circular(9),
                child: InkWell(
                  key: Key('$keyPrefix-$v'),
                  borderRadius: BorderRadius.circular(9),
                  onTap: onChanged == null ? null : () => onChanged!(v),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(9),
                      border: Border.all(color: v == value ? c.accent : c.line),
                    ),
                    child: Text(
                      label,
                      style: TextStyle(
                        color: v == value ? c.text : c.dim,
                        fontWeight: v == value ? FontWeight.w700 : FontWeight.w500,
                        fontSize: 13.5,
                      ),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// The buttons at the end of a part (the page's `Acts`).
class SysActs extends StatelessWidget {
  const SysActs({super.key, required this.children, this.start = false});

  final List<Widget> children;
  final bool start;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(top: 10),
    child: Wrap(
      alignment: start ? WrapAlignment.start : WrapAlignment.end,
      spacing: 8,
      runSpacing: 8,
      children: children,
    ),
  );
}

/// The wizard's note with its icon; ok, warn or error colour it.
class SysNote extends StatelessWidget {
  const SysNote({super.key, required this.text, this.icon = RgIcons.info, this.tone});

  final String text;
  final RgIcons icon;

  /// ok, warn, error, or null for a plain note.
  final String? tone;

  @override
  Widget build(BuildContext context) {
    final c = RgColors.of(context);
    final col = switch (tone) {
      'ok' => c.ok,
      'warn' => c.warn,
      'error' => c.err,
      _ => c.dim,
    };
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 6),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: tone == null ? c.panel2 : col.withValues(alpha: .08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: tone == null ? c.line : col.withValues(alpha: .35)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          RgIcon(icon, size: 18, color: tone == null ? c.accent : col),
          const SizedBox(width: 8),
          Expanded(
            child: Text(text, style: TextStyle(color: c.text, fontSize: 13.5, height: 1.4)),
          ),
        ],
      ),
    );
  }
}

/// A paragraph of the page (dim or plain).
class SysText extends StatelessWidget {
  const SysText(this.text, {super.key, this.dim = true, this.strong = false});

  final String text;
  final bool dim;
  final bool strong;

  @override
  Widget build(BuildContext context) {
    final c = RgColors.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Text(
        text,
        style: TextStyle(
          color: dim ? c.dim : c.text,
          fontSize: 13.5,
          height: 1.4,
          fontWeight: strong ? FontWeight.w700 : FontWeight.w400,
        ),
      ),
    );
  }
}

/// Numbered steps (the page's `brain-steps` and `oi-steps`).
class SysSteps extends StatelessWidget {
  const SysSteps({super.key, required this.steps, this.numbered = true});

  /// Each step: its words and, under them, what it needs.
  final List<(String, List<Widget>)> steps;
  final bool numbered;

  @override
  Widget build(BuildContext context) {
    final c = RgColors.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final (i, (text, more)) in steps.indexed)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 5),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 22,
                  height: 22,
                  margin: const EdgeInsets.only(top: 1),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: numbered ? c.accentSoft : Colors.transparent,
                  ),
                  child: Center(
                    child: numbered
                        ? Text(
                            '${i + 1}',
                            style: TextStyle(
                              color: c.accent,
                              fontSize: 12,
                              fontWeight: FontWeight.w800,
                            ),
                          )
                        : Container(
                            width: 6,
                            height: 6,
                            decoration: BoxDecoration(shape: BoxShape.circle, color: c.dim),
                          ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(text, style: TextStyle(color: c.text, fontSize: 13.5, height: 1.4)),
                      ...more,
                    ],
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

/// A block to copy, with its button (OwnInfra's `CopyBlock`).
class CopyBlock extends StatefulWidget {
  const CopyBlock({super.key, required this.text, this.label});

  final String text;
  final String? label;

  @override
  State<CopyBlock> createState() => _CopyBlockState();
}

class _CopyBlockState extends State<CopyBlock> {
  bool _copied = false;

  @override
  void didUpdateWidget(CopyBlock old) {
    super.didUpdateWidget(old);
    if (old.text != widget.text) _copied = false;
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final c = RgColors.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (widget.label != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Text(
                widget.label!,
                style: TextStyle(color: c.dim, fontSize: 12.5, fontWeight: FontWeight.w700),
              ),
            ),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: c.bg,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: c.line),
            ),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: SelectableText(
                widget.text.replaceAll('\t', '    '),
                style: TextStyle(fontFamily: 'monospace', fontSize: 12.5, color: c.text),
              ),
            ),
          ),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton.icon(
              onPressed: () async {
                await Clipboard.setData(ClipboardData(text: widget.text));
                if (mounted) setState(() => _copied = true);
              },
              icon: RgIcon(_copied ? RgIcons.check : RgIcons.copy, size: 14, color: c.accent),
              label: Text(_copied ? l.syOiCopied : l.syOiCopy),
            ),
          ),
        ],
      ),
    );
  }
}

/// Folded until opened (the page's `Advanced`).
class SysFold extends StatefulWidget {
  const SysFold({super.key, required this.label, required this.children, this.foldKey});

  final String label;
  final List<Widget> children;
  final Key? foldKey;

  @override
  State<SysFold> createState() => _SysFoldState();
}

class _SysFoldState extends State<SysFold> {
  bool _open = false;

  @override
  Widget build(BuildContext context) {
    final c = RgColors.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        InkWell(
          key: widget.foldKey,
          borderRadius: BorderRadius.circular(8),
          onTap: () => setState(() => _open = !_open),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Row(
              children: [
                AnimatedRotation(
                  turns: _open ? .25 : 0,
                  duration: const Duration(milliseconds: 150),
                  child: RgIcon(RgIcons.chevronRight, size: 16, color: c.dim),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    widget.label,
                    style: TextStyle(color: c.text, fontWeight: FontWeight.w700, fontSize: 13.5),
                  ),
                ),
              ],
            ),
          ),
        ),
        if (_open)
          Padding(
            padding: const EdgeInsets.only(left: 22),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: widget.children,
            ),
          ),
      ],
    );
  }
}

/// A field (the page's `Field`): [LabeledField], or several lines for a key.
class SysField extends StatelessWidget {
  const SysField({
    super.key,
    required this.label,
    required this.controller,
    this.fieldKey,
    this.help,
    this.error,
    this.hint,
    this.secret = false,
    this.lines = 1,
    this.onChanged,
    this.focusNode,
  });

  final String label;
  final TextEditingController controller;
  final Key? fieldKey;
  final String? help;
  final String? error;
  final String? hint;
  final bool secret;
  final int lines;
  final ValueChanged<String>? onChanged;
  final FocusNode? focusNode;

  @override
  Widget build(BuildContext context) {
    final c = RgColors.of(context);
    return Padding(
      padding: const EdgeInsets.only(top: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            label,
            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: c.text),
          ),
          const SizedBox(height: 4),
          TextField(
            key: fieldKey,
            controller: controller,
            focusNode: focusNode,
            obscureText: secret,
            autocorrect: false,
            enableSuggestions: !secret,
            minLines: lines,
            maxLines: secret ? 1 : lines,
            onChanged: onChanged,
            style: lines > 1 ? const TextStyle(fontFamily: 'monospace', fontSize: 12.5) : null,
            decoration: fieldDecoration(c, hint: hint),
          ),
          if (error != null)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(error!, style: TextStyle(fontSize: 12.5, color: c.err)),
            )
          else if (help != null)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(help!, style: TextStyle(fontSize: 12.5, color: c.dim, height: 1.35)),
            ),
        ],
      ),
    );
  }
}

/// A number with − and + (FirstBoot's `Stepper`: big buttons, no native number field).
class SysStepper extends StatelessWidget {
  const SysStepper({
    super.key,
    required this.label,
    required this.value,
    required this.min,
    required this.max,
    required this.show,
    required this.onChanged,
    this.keyPrefix = 'step',
  });

  final String label;
  final int value, min, max;
  final String Function(int) show;
  final ValueChanged<int> onChanged;
  final String keyPrefix;

  @override
  Widget build(BuildContext context) {
    final c = RgColors.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: TextStyle(color: c.text, fontWeight: FontWeight.w600),
            ),
          ),
          IconButton(
            key: Key('$keyPrefix-minus'),
            tooltip: '$label: -',
            onPressed: value <= min ? null : () => onChanged(value - 1),
            icon: RgIcon(RgIcons.minus, size: 18, color: value <= min ? c.line : c.text),
          ),
          SizedBox(
            width: 96,
            child: Text(
              show(value),
              textAlign: TextAlign.center,
              style: TextStyle(color: c.text, fontWeight: FontWeight.w800),
            ),
          ),
          IconButton(
            key: Key('$keyPrefix-plus'),
            tooltip: '$label: +',
            onPressed: value >= max ? null : () => onChanged(value + 1),
            icon: RgIcon(RgIcons.plus, size: 18, color: value >= max ? c.line : c.text),
          ),
        ],
      ),
    );
  }
}

/// A row with a title, its help and its buttons (the page's `Row`).
class SysRow extends StatelessWidget {
  const SysRow({super.key, required this.title, this.help, this.trailing = const []});

  final String title;
  final String? help;
  final List<Widget> trailing;

  @override
  Widget build(BuildContext context) {
    final c = RgColors.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(color: c.text, fontWeight: FontWeight.w700),
                ),
                if (help != null) Text(help!, style: TextStyle(color: c.dim, fontSize: 12.5)),
              ],
            ),
          ),
          ...trailing,
        ],
      ),
    );
  }
}

/// A job followed (ui.tsx's `useJob` and `JobView`): read every second while it runs, its title
/// (`job_<kind>`) and each step (`job_step_<id>`) with its mark and a download's bar; «Done.» or
/// what went wrong. [onEnd] hears the job end once, with its values (`vars`).
class SysJob extends StatefulWidget {
  const SysJob({super.key, required this.id, this.onEnd, this.onUpdate, this.showDone = true});

  final String id;
  final void Function(String state, Map<String, String> vars)? onEnd;

  /// Every reading while it runs (the sign-in address a job gives on the way).
  final void Function(JobView job, Map<String, String> vars)? onUpdate;
  final bool showDone;

  @override
  State<SysJob> createState() => _SysJobState();
}

class _SysJobState extends State<SysJob> {
  JobView? _job;
  Map<String, String> _vars = const {};
  Timer? _timer;
  bool _ended = false;

  @override
  void initState() {
    super.initState();
    unawaited(_tick());
  }

  @override
  void didUpdateWidget(SysJob old) {
    super.didUpdateWidget(old);
    if (old.id != widget.id) {
      _timer?.cancel();
      _job = null;
      _ended = false;
      unawaited(_tick());
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _tick() async {
    final c = sysClient(context);
    if (c == null) return;
    try {
      final r = await c.jobWithVars(widget.id);
      if (!mounted) return;
      setState(() {
        _job = r.job;
        _vars = r.vars;
      });
      widget.onUpdate?.call(r.job, r.vars);
      if (!r.job.running && !_ended) {
        _ended = true;
        widget.onEnd?.call(r.job.state, r.vars);
      }
    } on ApiException {
      // Not there yet: look again.
    }
    if (mounted && (_job == null || _job!.running)) {
      _timer = Timer(const Duration(seconds: 1), () => unawaited(_tick()));
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final c = RgColors.of(context);
    final j = _job;
    if (j == null) {
      return const Padding(
        padding: EdgeInsets.all(12),
        child: Center(child: RgSpinner(size: 18)),
      );
    }
    final lang = Localizations.localeOf(context).languageCode;
    return Container(
      key: Key('sys-job-${j.state}'),
      margin: const EdgeInsets.symmetric(vertical: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: c.panel2,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: j.state == 'failed' ? c.err.withValues(alpha: .4) : c.line),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            syWord(l, 'job_${j.kind}', _vars) ?? j.kind,
            style: TextStyle(fontWeight: FontWeight.w700, color: c.text),
          ),
          const SizedBox(height: 6),
          for (final s in j.steps)
            Padding(
              key: Key('sys-job-step-${s.id}'),
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    width: 18,
                    height: 18,
                    child: Center(
                      child: switch (s.state) {
                        'running' => RgSpinner(size: 14, color: c.accent),
                        'failed' => RgIcon(RgIcons.x, size: 14, color: c.err),
                        _ => Container(
                          width: 9,
                          height: 9,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: s.state == 'done' ? c.ok : Colors.transparent,
                            border: Border.all(color: s.state == 'done' ? c.ok : c.dim, width: 1.5),
                          ),
                        ),
                      },
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          [
                            syWord(l, 'job_step_${s.id}', _vars) ?? s.id,
                            if (s.state == 'skipped') l.syUiNotNeeded,
                          ].join(' · '),
                          style: TextStyle(
                            color: s.state == 'waiting' || s.state == 'skipped' ? c.dim : c.text,
                          ),
                        ),
                        if (s.done != null && s.state == 'running') ...[
                          const SizedBox(height: 4),
                          LinearProgressIndicator(
                            value: (s.total ?? 0) > 0 ? s.done! / s.total! : null,
                            minHeight: 5,
                            borderRadius: BorderRadius.circular(3),
                            color: c.accent,
                            backgroundColor: c.line,
                          ),
                          const SizedBox(height: 2),
                          Text(
                            [
                              s.total != null
                                  ? '${byteWords(s.done!, lang)} / ${byteWords(s.total!, lang)}'
                                  : byteWords(s.done!, lang),
                              if (s.rate != null) '${byteWords(s.rate!.round(), lang)}/s',
                              if (s.secondsLeft != null)
                                shortDuration(Duration(seconds: s.secondsLeft!.round())),
                            ].join(' · '),
                            style: TextStyle(color: c.dim, fontSize: 12),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
          if (j.state == 'done' && widget.showDone)
            Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Text(
                l.syUiDone,
                style: TextStyle(color: c.ok, fontWeight: FontWeight.w700),
              ),
            ),
          if (j.state == 'failed')
            Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Text(
                (j.errorCode != null ? syWord(l, 'err_${j.errorCode}', _vars) : null) ??
                    j.errorMessage ??
                    j.state,
                style: TextStyle(color: c.err),
              ),
            ),
        ],
      ),
    );
  }
}

/// The server's word went wrong, at the end of a part.
class SysSaid extends StatelessWidget {
  const SysSaid({super.key, required this.text, this.ok = false});

  final String text;
  final bool ok;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(top: 8),
    child: NoticeBanner(text: text, error: !ok),
  );
}

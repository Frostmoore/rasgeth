// G42.4: the pieces the native Settings › Requests, Safety, Tools and Commands share, drawn as the
// page's settings kit (`SettingsKit.tsx`): a page with its question and lead, a card with an icon,
// a title and its question (`SCard`), a row of drawn chips (`Chips`/`Seg`), a warning, and the
// save row with «Undo». A panel over the window on a computer, a whole screen on a phone.
import 'package:flutter/material.dart';

import '../api/client.dart';
import '../l10n/app_localizations.dart';
import '../theme/colors.dart';
import '../ui/dialogs.dart';
import '../ui/icons.dart';
import '../ui/systems.dart';

/// Opens a settings page: a panel over the window on a computer, a whole screen on a phone.
Future<void> openRulesPage(BuildContext context, Widget Function(bool panel) page) {
  final size = MediaQuery.sizeOf(context);
  if (size.width >= 760) {
    return showRgWindow<void>(
      context: context,
      builder: (_) => Dialog(
        insetPadding: const EdgeInsets.all(28),
        clipBehavior: Clip.antiAlias,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: 780, maxHeight: size.height * .9),
          child: page(true),
        ),
      ),
    );
  }
  return Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => page(false)));
}

String rulesWhy(Object e) => e is ApiException ? e.message : '$e';

/// «10 min», «6 ore», «7 giorni», as the page's `spanWords`.
String spanWords(AppLocalizations l, int ms) {
  const minute = 60000;
  const hour = 60 * minute;
  const day = 24 * hour;
  if (ms % day == 0) return ms == day ? l.g4CmOneDay : l.g4CmDays('${ms ~/ day}');
  if (ms == hour) return l.g4CmOneHour;
  if (ms % hour == 0) return l.g4CmHours('${ms ~/ hour}');
  return l.g4CmMinutes('${(ms / minute).round()}');
}

/// A settings page: its bar (back, or close in a panel), the question and its lead, the cards.
class RulesPage extends StatelessWidget {
  const RulesPage({
    super.key,
    required this.title,
    required this.question,
    this.lead,
    required this.panel,
    required this.children,
    required this.pageKey,
    this.system,
  });

  final String title;
  final String question;
  final String? lead;

  /// One of Rasgeth's named systems (3.10.3): its name and what it is, above the question.
  final RgSystem? system;
  final bool panel;
  final List<Widget> children;
  final Key pageKey;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final c = RgColors.of(context);
    return Scaffold(
      key: pageKey,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        leading: IconButton(
          key: const Key('rules-back'),
          tooltip: panel ? l.close : l.back,
          onPressed: () => Navigator.of(context).pop(),
          icon: RgIcon(panel ? RgIcons.x : RgIcons.arrowLeft, color: c.text),
        ),
        title: Text(title),
      ),
      body: Align(
        alignment: Alignment.topCenter,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 720),
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
            children: [
              if (system != null)
                Padding(padding: const EdgeInsets.fromLTRB(4, 8, 4, 0), child: SysTitle(system!)),
              Padding(
                padding: const EdgeInsets.fromLTRB(4, 8, 4, 4),
                child: Text(
                  question,
                  style: TextStyle(
                    fontSize: 21,
                    height: 1.25,
                    fontWeight: FontWeight.w800,
                    color: c.text,
                  ),
                ),
              ),
              if (lead != null)
                Padding(
                  padding: const EdgeInsets.fromLTRB(4, 2, 4, 10),
                  child: Text(lead!, style: TextStyle(color: c.dim, fontSize: 14, height: 1.4)),
                ),
              ...children,
            ],
          ),
        ),
      ),
    );
  }
}

/// A heading between groups of cards, with its lead (the page's `Sub`).
class RulesSub extends StatelessWidget {
  const RulesSub({super.key, required this.title, this.lead, this.icon});

  final String title;
  final String? lead;
  final RgIcons? icon;

  @override
  Widget build(BuildContext context) {
    final c = RgColors.of(context);
    return Semantics(
      header: true,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(4, 22, 4, 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                if (icon != null) ...[
                  RgIcon(icon!, size: 18, color: c.accent),
                  const SizedBox(width: 8),
                ],
                Expanded(
                  child: Text(
                    title,
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: c.text),
                  ),
                ),
              ],
            ),
            if (lead != null)
              Padding(
                padding: const EdgeInsets.only(top: 3),
                child: Text(lead!, style: TextStyle(color: c.dim, fontSize: 13, height: 1.35)),
              ),
          ],
        ),
      ),
    );
  }
}

/// A card with its drawn icon, a title and its question (the page's `SCard`).
class RuleCard extends StatelessWidget {
  const RuleCard({
    super.key,
    required this.icon,
    required this.title,
    this.question,
    required this.children,
    this.tone,
  });

  final RgIcons icon;
  final String title;
  final String? question;
  final List<Widget> children;

  /// A colour for the icon (the truly dangerous card: [RgColors.critical]).
  final Color? tone;

  @override
  Widget build(BuildContext context) {
    final c = RgColors.of(context);
    final t = tone ?? c.accent;
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
      decoration: BoxDecoration(
        color: c.panel,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: c.line),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: t.withValues(alpha: .12),
                  borderRadius: BorderRadius.circular(11),
                ),
                child: Center(child: RgIcon(icon, size: 20, color: t)),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(fontSize: 15.5, fontWeight: FontWeight.w800, color: c.text),
                    ),
                    if (question != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 2),
                        child: Text(
                          question!,
                          style: TextStyle(fontSize: 13.5, color: c.dim, height: 1.35),
                        ),
                      ),
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

/// A row in a card: a title, its help, and the control under them (the page's `Row`).
class RuleRow extends StatelessWidget {
  const RuleRow({super.key, required this.title, this.help, required this.child});

  final String title;
  final String? help;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final c = RgColors.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(fontWeight: FontWeight.w700, color: c.text, fontSize: 14.5),
          ),
          if (help != null)
            Padding(
              padding: const EdgeInsets.only(top: 2, bottom: 2),
              child: Text(help!, style: TextStyle(color: c.dim, fontSize: 12.5, height: 1.35)),
            ),
          const SizedBox(height: 8),
          child,
        ],
      ),
    );
  }
}

/// One choice among several, drawn: chips in a row, or full-width rows one under the other
/// (the page's `Chips` and `Seg vertical`). Never a native radio button.
class RgChoice<T> extends StatelessWidget {
  const RgChoice({
    super.key,
    required this.options,
    required this.value,
    required this.onChanged,
    required this.keyOf,
    this.vertical = false,
  });

  final List<(T, String)> options;
  final T? value;
  final ValueChanged<T>? onChanged;
  final String Function(T) keyOf;
  final bool vertical;

  @override
  Widget build(BuildContext context) {
    final c = RgColors.of(context);
    Widget one(T v, String label) {
      final on = v == value;
      return Semantics(
        button: true,
        selected: on,
        child: Material(
          color: on ? c.accentSoft : c.panel2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(vertical ? 12 : 999),
            side: BorderSide(color: on ? c.accent : c.line, width: on ? 1.5 : 1),
          ),
          child: InkWell(
            key: Key(keyOf(v)),
            borderRadius: BorderRadius.circular(vertical ? 12 : 999),
            onTap: onChanged == null || on ? null : () => onChanged!(v),
            child: Padding(
              padding: vertical
                  ? const EdgeInsets.symmetric(horizontal: 14, vertical: 12)
                  : const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              child: Row(
                mainAxisSize: vertical ? MainAxisSize.max : MainAxisSize.min,
                children: [
                  if (vertical) ...[
                    Container(
                      width: 18,
                      height: 18,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: on ? c.accent : Colors.transparent,
                        border: Border.all(color: on ? c.accent : c.line, width: 2),
                      ),
                      child: on
                          ? const Center(
                              child: RgIcon(RgIcons.check, size: 11, color: Colors.white),
                            )
                          : null,
                    ),
                    const SizedBox(width: 10),
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
    }

    if (vertical) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: 8,
        children: [for (final (v, label) in options) one(v, label)],
      );
    }
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [for (final (v, label) in options) one(v, label)],
    );
  }
}

/// A line of explanation under a choice (the page's `wz-say`).
class RuleSay extends StatelessWidget {
  const RuleSay(this.text, {super.key});

  final String text;

  @override
  Widget build(BuildContext context) {
    final c = RgColors.of(context);
    return Padding(
      padding: const EdgeInsets.only(top: 10),
      child: Text(text, style: TextStyle(color: c.dim, fontSize: 13, height: 1.4)),
    );
  }
}

/// A plain warning, never a block (the page's `cl-warn`).
class RuleWarn extends StatelessWidget {
  const RuleWarn(this.text, {super.key});

  final String text;

  @override
  Widget build(BuildContext context) {
    final c = RgColors.of(context);
    return Container(
      margin: const EdgeInsets.only(top: 2, bottom: 12),
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
      decoration: BoxDecoration(
        color: c.warn.withValues(alpha: .10),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: c.warn.withValues(alpha: .40)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 1),
            child: RgIcon(RgIcons.alert, size: 15, color: c.warnText),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(text, style: TextStyle(color: c.warnText, fontSize: 12.5, height: 1.35)),
          ),
        ],
      ),
    );
  }
}

/// Saving's outcome: what was saved (with «Undo» while it can be taken back), or what failed.
class RuleSaveRow extends StatelessWidget {
  const RuleSaveRow({
    super.key,
    required this.onSave,
    this.saving = false,
    this.saved,
    this.undone = false,
    this.onUndo,
    this.extra,
    this.error,
  });

  final VoidCallback? onSave;
  final bool saving;

  /// The words after a save (null: not saved since the last change).
  final String? saved;
  final bool undone;
  final VoidCallback? onUndo;
  final Widget? extra;
  final String? error;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final c = RgColors.of(context);
    return Padding(
      padding: const EdgeInsets.only(top: 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (error != null)
            Container(
              key: const Key('rules-error'),
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: c.err.withValues(alpha: .08),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: c.err.withValues(alpha: .35)),
              ),
              child: Text(error!, style: TextStyle(color: c.text, fontSize: 13.5)),
            ),
          Wrap(
            spacing: 10,
            runSpacing: 8,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              FilledButton(
                key: const Key('rules-save'),
                onPressed: saving ? null : onSave,
                child: Text(l.save),
              ),
              ?extra,
              if (undone)
                Text(
                  l.g4CmUndone,
                  key: const Key('rules-undone'),
                  style: TextStyle(color: c.ok, fontSize: 13),
                )
              else if (saved != null) ...[
                Text(
                  saved!,
                  key: const Key('rules-saved'),
                  style: TextStyle(color: c.ok, fontSize: 13),
                ),
                if (onUndo != null)
                  TextButton(
                    key: const Key('rules-undo'),
                    onPressed: onUndo,
                    child: Text(l.g4CmUndo),
                  ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

/// While a page loads, or what stopped it.
class RulesLoading extends StatelessWidget {
  const RulesLoading({super.key, this.error});

  final String? error;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final c = RgColors.of(context);
    if (error != null) {
      return Container(
        key: const Key('rules-error'),
        margin: const EdgeInsets.only(top: 12),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: c.err.withValues(alpha: .08),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: c.err.withValues(alpha: .35)),
        ),
        child: Text(error!, style: TextStyle(color: c.text)),
      );
    }
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Center(
        child: Text(l.loading, style: TextStyle(color: c.dim)),
      ),
    );
  }
}

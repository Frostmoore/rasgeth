// The pieces of a settings screen (Tu › Notifiche, Tu › Voce): a section's title, a card, a line
// with its icon, a banner. Drawn controls only (no native switches or radios: [PickRow]).
import 'package:flutter/material.dart';

import '../theme/colors.dart';
import 'icons.dart';

class SectionHead extends StatelessWidget {
  const SectionHead(this.title, {super.key});

  final String title;

  @override
  Widget build(BuildContext context) {
    final c = RgColors.of(context);
    return Semantics(
      header: true,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 18, 16, 6),
        child: Text(
          title,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: c.dim,
            letterSpacing: .3,
          ),
        ),
      ),
    );
  }
}

class SettingsCard extends StatelessWidget {
  const SettingsCard({super.key, required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final c = RgColors.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Material(
        color: c.panel,
        clipBehavior: Clip.antiAlias,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: BorderSide(color: c.line),
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: children),
      ),
    );
  }
}

/// A line of explanation with its icon.
class NoteLine extends StatelessWidget {
  const NoteLine({
    super.key,
    required this.icon,
    required this.text,
    this.color,
    this.strong = false,
  });

  final RgIcons icon;
  final String text;
  final Color? color;
  final bool strong;

  @override
  Widget build(BuildContext context) {
    final c = RgColors.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 2),
            child: RgIcon(icon, size: 16, color: color ?? c.dim),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                color: strong ? c.text : c.dim,
                fontSize: 14,
                fontWeight: strong ? FontWeight.w600 : FontWeight.w400,
                height: 1.35,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Something that went well or not, at the top of the screen.
class NoticeBanner extends StatelessWidget {
  const NoticeBanner({super.key, required this.text, this.error = false});

  final String text;
  final bool error;

  @override
  Widget build(BuildContext context) {
    final c = RgColors.of(context);
    final col = error ? c.err : c.ok;
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 10, 16, 0),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: col.withValues(alpha: .08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: col.withValues(alpha: .35)),
      ),
      child: Text(text, style: TextStyle(color: c.text, fontSize: 13.5)),
    );
  }
}

/// One choice among several: a drawn mark, never a native radio button.
class PickRow extends StatelessWidget {
  const PickRow({
    super.key,
    required this.title,
    this.subtitle,
    this.leading,
    required this.selected,
    required this.onTap,
  });

  final String title;
  final String? subtitle;
  final Widget? leading;
  final bool selected;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final c = RgColors.of(context);
    return Semantics(
      selected: selected,
      button: true,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              if (leading != null) ...[leading!, const SizedBox(width: 12)],
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        color: c.text,
                        fontSize: 15,
                        fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                      ),
                    ),
                    if (subtitle != null)
                      Text(subtitle!, style: TextStyle(color: c.dim, fontSize: 12.5)),
                  ],
                ),
              ),
              Container(
                width: 22,
                height: 22,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: selected ? c.accent : Colors.transparent,
                  border: Border.all(color: selected ? c.accent : c.line, width: 2),
                ),
                child: selected
                    ? const Center(child: RgIcon(RgIcons.check, size: 14, color: Colors.white))
                    : null,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// A screen of settings with its back arrow, a phone's measure on a computer.
class SettingsScaffold extends StatelessWidget {
  const SettingsScaffold({
    super.key,
    required this.title,
    required this.backKey,
    required this.backLabel,
    required this.children,
    this.listKey,
  });

  final String title;
  final Key backKey;
  final String backLabel;
  final List<Widget> children;
  final Key? listKey;

  @override
  Widget build(BuildContext context) {
    final c = RgColors.of(context);
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          key: backKey,
          tooltip: backLabel,
          onPressed: () => Navigator.of(context).pop(),
          icon: RgIcon(RgIcons.arrowLeft, color: c.text),
        ),
        title: Text(title),
      ),
      body: Align(
        alignment: Alignment.topCenter,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 680),
          child: ListView(
            key: listKey,
            padding: const EdgeInsets.only(bottom: 24),
            children: children,
          ),
        ),
      ),
    );
  }
}

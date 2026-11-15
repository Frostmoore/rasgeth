import 'package:flutter/material.dart';

import '../theme/colors.dart';
import 'icons.dart';

/// A screen's title row (the board's `.appbar`).
class ScreenHeader extends StatelessWidget {
  const ScreenHeader({super.key, required this.title, this.subtitle, this.leading, this.trailing});

  final String title;
  final Widget? subtitle;
  final Widget? leading;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final c = RgColors.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
      child: Row(
        children: [
          if (leading != null) ...[leading!, const SizedBox(width: 10)],
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: c.text),
                ),
                if (subtitle != null)
                  DefaultTextStyle.merge(
                    style: TextStyle(fontSize: 12.5, color: c.dim),
                    child: subtitle!,
                  ),
              ],
            ),
          ),
          ?trailing,
        ],
      ),
    );
  }
}

/// What a place shows while it has nothing (or until its part of the app arrives).
class EmptyState extends StatelessWidget {
  const EmptyState({super.key, required this.icon, required this.text});

  final RgIcons icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    final c = RgColors.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            RgIcon(icon, size: 40, color: c.dim),
            const SizedBox(height: 12),
            Text(
              text,
              textAlign: TextAlign.center,
              style: TextStyle(color: c.dim, fontSize: 14.5),
            ),
          ],
        ),
      ),
    );
  }
}

/// A small coloured dot before a state word.
class Dot extends StatelessWidget {
  const Dot(this.color, {super.key});

  final Color color;

  @override
  Widget build(BuildContext context) => Container(
    width: 7,
    height: 7,
    decoration: BoxDecoration(color: color, shape: BoxShape.circle),
  );
}

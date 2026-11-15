// Drawn icons, the same paths as the page (packages/web/src/icons.tsx, Feather style, MIT): no
// emoji and no symbol characters as icons anywhere. They follow the text colour.
import 'package:flutter/widgets.dart';
import 'package:flutter_svg/flutter_svg.dart';

enum RgIcons {
  users(
    '<circle cx="9" cy="8" r="3.5"/><path d="M2.5 20v-1a5.5 5.5 0 0 1 5.5-5.5h2a5.5 5.5 0 0 1 5.5 5.5v1"/><path d="M16 4.6a3.5 3.5 0 0 1 0 6.8M18 13.6a5.5 5.5 0 0 1 3.5 5.4v1"/>',
  ),
  chat('<path d="M21 15a2 2 0 0 1-2 2H7l-4 4V5a2 2 0 0 1 2-2h14a2 2 0 0 1 2 2z"/>'),
  bell(
    '<path d="M18 8a6 6 0 0 0-12 0c0 7-3 9-3 9h18s-3-2-3-9"/><path d="M13.7 21a2 2 0 0 1-3.4 0"/>',
  ),
  list('<path d="M8 6h13M8 12h13M8 18h13M3 6h.01M3 12h.01M3 18h.01"/>'),
  user('<circle cx="12" cy="8" r="4"/><path d="M4 21v-1a6 6 0 0 1 6-6h4a6 6 0 0 1 6 6v1"/>'),
  send('<path d="M22 2L11 13M22 2l-7 20-4-9-9-4z"/>'),
  spinner('<path d="M21 12a9 9 0 1 1-6.2-8.6"/>'),
  plus('<path d="M12 5v14M5 12h14"/>'),
  chevronDown('<path d="M6 9l6 6 6-6"/>'),
  server(
    '<rect x="3" y="4" width="18" height="7" rx="2"/><rect x="3" y="13" width="18" height="7" rx="2"/><path d="M7 7.5h.01M7 16.5h.01"/>',
  );

  const RgIcons(this.paths);
  final String paths;
}

class RgIcon extends StatelessWidget {
  const RgIcon(this.icon, {super.key, this.size = 22, this.color});

  final RgIcons icon;
  final double size;

  /// Default: the surrounding text colour.
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final c = color ?? DefaultTextStyle.of(context).style.color ?? const Color(0xFF888888);
    return SvgPicture.string(
      '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="none" '
      'stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">'
      '${icon.paths}</svg>',
      width: size,
      height: size,
      theme: SvgTheme(currentColor: c),
      excludeFromSemantics: true,
    );
  }
}

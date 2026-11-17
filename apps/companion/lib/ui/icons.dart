// Drawn icons, the same paths as the page (packages/web/src/icons.tsx, Feather style, MIT): no
// emoji and no symbol characters as icons anywhere. They follow the text colour.
import 'package:flutter/widgets.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../mascot/mascot_source.dart' show MascotScope;

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
  ),
  image(
    '<rect x="3" y="3" width="18" height="18" rx="2"/><circle cx="8.5" cy="8.5" r="1.5"/><path d="M21 15l-5-5L5 21"/>',
  ),
  checkSquare(
    '<path d="M9 11l3 3L22 4"/><path d="M21 12v7a2 2 0 0 1-2 2H5a2 2 0 0 1-2-2V5a2 2 0 0 1 2-2h11"/>',
  ),
  square('<rect x="3" y="3" width="18" height="18" rx="2"/>'),
  paperclip(
    '<path d="M21.44 11.05l-9.19 9.19a6 6 0 0 1-8.49-8.49l9.19-9.19a4 4 0 0 1 5.66 5.66l-9.2 9.19a2 2 0 0 1-2.83-2.83l8.49-8.48"/>',
  ),
  stop('<rect x="6" y="6" width="12" height="12" rx="2"/>'),
  x('<path d="M18 6L6 18M6 6l12 12"/>'),
  check('<path d="M20 6L9 17l-5-5"/>'),
  alert(
    '<path d="M10.29 3.86L1.82 18a2 2 0 0 0 1.71 3h16.94a2 2 0 0 0 1.71-3L13.71 3.86a2 2 0 0 0-3.42 0z"/><path d="M12 9v4M12 17h.01"/>',
  ),
  chevronRight('<path d="M9 18l6-6-6-6"/>'),
  arrowLeft('<path d="M19 12H5M12 19l-7-7 7-7"/>'),
  file(
    '<path d="M14 2H6a2 2 0 0 0-2 2v16a2 2 0 0 0 2 2h12a2 2 0 0 0 2-2V8z"/><path d="M14 2v6h6"/>',
  ),
  refresh(
    '<path d="M23 4v6h-6M1 20v-6h6"/><path d="M3.51 9a9 9 0 0 1 14.85-3.36L23 10M1 14l5.64 5.36A9 9 0 0 0 20.49 15"/>',
  ),
  shield('<path d="M12 22s8-4 8-10V5l-8-3-8 3v7c0 6 8 10 8 10z"/>'),
  search('<circle cx="11" cy="11" r="8"/><path d="M21 21l-4.35-4.35"/>'),
  trash(
    '<path d="M3 6h18M19 6l-1 14a2 2 0 0 1-2 2H8a2 2 0 0 1-2-2L5 6M10 11v6M14 11v6M9 6V4a1 1 0 0 1 1-1h4a1 1 0 0 1 1 1v2"/>',
  ),
  lock('<rect x="3" y="11" width="18" height="11" rx="2"/><path d="M7 11V7a5 5 0 0 1 10 0v4"/>'),
  help(
    '<circle cx="12" cy="12" r="10"/><path d="M9.09 9a3 3 0 0 1 5.83 1c0 2-3 3-3 3M12 17h.01"/>',
  ),
  tool(
    '<path d="M14.7 6.3a1 1 0 0 0 0 1.4l1.6 1.6a1 1 0 0 0 1.4 0l3.77-3.77a6 6 0 0 1-7.94 7.94l-6.91 6.91a2.12 2.12 0 0 1-3-3l6.91-6.91a6 6 0 0 1 7.94-7.94l-3.76 3.76z"/>',
  ),
  edit('<path d="M12 20h9"/><path d="M16.5 3.5a2.12 2.12 0 0 1 3 3L7 19l-4 1 1-4z"/>'),
  wifi('<path d="M5 12.5a10 10 0 0 1 14 0M8.5 16a5 5 0 0 1 7 0M2 9a15 15 0 0 1 20 0M12 20h.01"/>'),
  zap('<path d="M13 2L3 14h9l-1 8 10-12h-9z"/>'),
  settings(
    '<circle cx="12" cy="12" r="3"/><path d="M19.4 15a1.7 1.7 0 0 0 .3 1.8l.1.1a2 2 0 1 1-2.8 2.8l-.1-.1a1.7 1.7 0 0 0-1.8-.3 1.7 1.7 0 0 0-1 1.5V21a2 2 0 1 1-4 0v-.1a1.7 1.7 0 0 0-1.1-1.5 1.7 1.7 0 0 0-1.8.3l-.1.1a2 2 0 1 1-2.8-2.8l.1-.1a1.7 1.7 0 0 0 .3-1.8 1.7 1.7 0 0 0-1.5-1H3a2 2 0 1 1 0-4h.1a1.7 1.7 0 0 0 1.5-1.1 1.7 1.7 0 0 0-.3-1.8l-.1-.1a2 2 0 1 1 2.8-2.8l.1.1a1.7 1.7 0 0 0 1.8.3H9a1.7 1.7 0 0 0 1-1.5V3a2 2 0 1 1 4 0v.1a1.7 1.7 0 0 0 1 1.5 1.7 1.7 0 0 0 1.8-.3l.1-.1a2 2 0 1 1 2.8 2.8l-.1.1a1.7 1.7 0 0 0-.3 1.8V9a1.7 1.7 0 0 0 1.5 1H21a2 2 0 1 1 0 4h-.1a1.7 1.7 0 0 0-1.5 1z"/>',
  ),
  globe(
    '<circle cx="12" cy="12" r="10"/><path d="M2 12h20M12 2a15 15 0 0 1 0 20a15 15 0 0 1 0-20"/>',
  ),
  mic(
    '<rect x="9" y="2" width="6" height="12" rx="3"/><path d="M19 10v1a7 7 0 0 1-14 0v-1M12 18v4M8 22h8"/>',
  ),
  phone('<rect x="6" y="2" width="12" height="20" rx="2.5"/><path d="M11 18h2"/>'),
  monitor('<rect x="2" y="3" width="20" height="14" rx="2"/><path d="M8 21h8M12 17v4"/>'),
  external(
    '<path d="M14 4h6v6M20 4l-9 9"/><path d="M18 14v5a1 1 0 0 1-1 1H5a1 1 0 0 1-1-1V7a1 1 0 0 1 1-1h5"/>',
  ),
  download('<path d="M21 15v4a2 2 0 0 1-2 2H5a2 2 0 0 1-2-2v-4M7 10l5 5 5-5M12 15V3"/>'),
  cpu(
    '<rect x="4" y="4" width="16" height="16" rx="2"/><rect x="9" y="9" width="6" height="6"/><path d="M9 1v3M15 1v3M9 20v3M15 20v3M20 9h3M20 14h3M1 9h3M1 14h3"/>',
  ),
  home('<path d="M3 9l9-7 9 7v11a2 2 0 0 1-2 2H5a2 2 0 0 1-2-2zM9 22V12h6v10"/>'),
  copy(
    '<rect x="9" y="9" width="13" height="13" rx="2"/><path d="M5 15H4a2 2 0 0 1-2-2V4a2 2 0 0 1 2-2h9a2 2 0 0 1 2 2v1"/>',
  ),
  star(
    '<path d="M12 2l3.09 6.26L22 9.27l-5 4.87 1.18 6.88L12 17.77l-6.18 3.25L7 14.14 2 9.27l6.91-1.01z"/>',
  ),
  folder('<path d="M22 19a2 2 0 0 1-2 2H4a2 2 0 0 1-2-2V5a2 2 0 0 1 2-2h5l2 3h9a2 2 0 0 1 2 2z"/>'),
  more(
    '<circle cx="5" cy="12" r="1.6"/><circle cx="12" cy="12" r="1.6"/><circle cx="19" cy="12" r="1.6"/>',
  ),
  minimize('<path d="M4 14h6v6M20 10h-6V4M14 10l7-7M3 21l7-7"/>'),
  maximize('<path d="M15 3h6v6M9 21H3v-6M21 3l-7 7M3 21l7-7"/>'),
  userPlus(
    '<circle cx="9" cy="8" r="4"/><path d="M2 21v-1a6 6 0 0 1 6-6h2a6 6 0 0 1 6 6v1M19 8v6M16 11h6"/>',
  ),
  coffee(
    '<path d="M17 8h1a4 4 0 0 1 0 8h-1M3 8h14v9a4 4 0 0 1-4 4H7a4 4 0 0 1-4-4z"/><path d="M6 2v2M10 2v2M14 2v2"/>',
  ),
  volume(
    '<path d="M11 5L6 9H2v6h4l5 4V5z"/><path d="M19.07 4.93a10 10 0 0 1 0 14.14M15.54 8.46a5 5 0 0 1 0 7.07"/>',
  ),
  share('<path d="M4 12v8a2 2 0 0 0 2 2h12a2 2 0 0 0 2-2v-8M16 6l-4-4-4 4M12 2v13"/>'),
  bellOff(
    '<path d="M13.7 21a2 2 0 0 1-3.4 0M18.6 13A17.9 17.9 0 0 1 18 8M6.3 6.3A6 6 0 0 0 6 8c0 7-3 9-3 9h14M18 8a6 6 0 0 0-9.3-5M1 1l22 22"/>',
  ),
  link(
    '<path d="M10 13a5 5 0 0 0 7.54.54l3-3a5 5 0 0 0-7.07-7.07l-1.72 1.71"/><path d="M14 11a5 5 0 0 0-7.54-.54l-3 3a5 5 0 0 0 7.07 7.07l1.71-1.71"/>',
  ),
  // G40.11: the advanced interface.
  code('<path d="M16 18l6-6-6-6M8 6l-6 6 6 6"/>'),
  gitBranch(
    '<circle cx="6" cy="5.5" r="2.5"/><circle cx="6" cy="18.5" r="2.5"/><circle cx="18" cy="7.5" r="2.5"/><path d="M6 8v8M18 10c0 4.5-6 3.5-11 6.5"/>',
  ),
  gitCommit('<circle cx="12" cy="12" r="3.5"/><path d="M2 12h6.5M15.5 12H22"/>'),
  terminal('<rect x="2" y="3" width="20" height="18" rx="2"/><path d="M6 9l4 3-4 3M12 15h6"/>'),
  diff('<path d="M12 3v8M8 7h8M8 17h8"/><rect x="3" y="2" width="18" height="20" rx="2"/>'),
  upload('<path d="M21 15v4a2 2 0 0 1-2 2H5a2 2 0 0 1-2-2v-4M17 8l-5-5-5 5M12 3v12"/>'),
  minus('<path d="M5 12h14"/>'),
  arrowUp('<path d="M12 19V5M5 12l7-7 7 7"/>'),
  arrowDown('<path d="M12 5v14M19 12l-7 7-7-7"/>'),
  arrowRight('<path d="M5 12h14M12 5l7 7-7 7"/>'),
  activity('<path d="M22 12h-4l-3 9L9 3l-3 9H2"/>'),
  bookmark('<path d="M19 21l-7-5-7 5V5a2 2 0 0 1 2-2h10a2 2 0 0 1 2 2z"/>'),
  reply('<path d="M9 17l-5-5 5-5"/><path d="M20 18v-2a4 4 0 0 0-4-4H4"/>'),
  tag(
    '<path d="M20.6 13.4l-7.2 7.2a2 2 0 0 1-2.8 0L3 13V3h10l7.6 7.6a2 2 0 0 1 0 2.8z"/><circle cx="7.5" cy="7.5" r="1.5"/>',
  ),
  bag(
    '<path d="M6 2L3 6v14a2 2 0 0 0 2 2h14a2 2 0 0 0 2-2V6l-3-4z"/><path d="M3 6h18"/><path d="M16 10a4 4 0 0 1-8 0"/>',
  ),
  chevronLeft('<path d="M15 18l-6-6 6-6"/>'),
  info('<circle cx="12" cy="12" r="10"/><path d="M12 16v-4M12 8h.01"/>'),
  archive('<path d="M21 8v13H3V8M1 3h22v5H1zM10 12h4"/>'),
  canvas(
    '<rect x="3" y="3" width="18" height="18" rx="2"/><circle cx="9" cy="9" r="1.6"/><path d="M21 15l-4.5-4.5L7 20"/>',
  ),
  play('<path d="M7 4l13 8-13 8z"/>'),
  pause('<rect x="6" y="4" width="4" height="16" rx="1"/><rect x="14" y="4" width="4" height="16" rx="1"/>'),
  layers('<path d="M12 2L2 7l10 5 10-5zM2 17l10 5 10-5M2 12l10 5 10-5"/>'),
  branch(
    '<circle cx="6" cy="5" r="2"/><circle cx="6" cy="19" r="2"/><circle cx="18" cy="8" r="2"/><path d="M6 7v10"/><path d="M18 10c0 4-6 3-11.3 7.4"/>',
  ),
  mail(
    '<path d="M4 4h16a2 2 0 0 1 2 2v12a2 2 0 0 1-2 2H4a2 2 0 0 1-2-2V6a2 2 0 0 1 2-2z"/><path d="M22 6l-10 7L2 6"/>',
  ),
  nodes(
    '<path d="M5 18C8 6 16 18 19 6"/><rect x="3" y="16" width="4" height="4"/><rect x="17" y="4" width="4" height="4"/>',
  ),
  // 3.8.7: widgets and artifacts (the page's IconPin).
  pin('<path d="M12 17v5M9 3h6l-1 6 4 4H6l4-4z"/>');

  const RgIcons(this.paths);
  final String paths;
}

class RgIcon extends StatelessWidget {
  const RgIcon(this.icon, {super.key, this.size = 22, this.color, this.filled = false});

  final RgIcons icon;
  final double size;

  /// Filled with the colour too (a favourite's star).
  final bool filled;

  /// Default: the surrounding text colour.
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final c = color ?? DefaultTextStyle.of(context).style.color ?? const Color(0xFF888888);
    return SvgPicture.string(
      '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" '
      'fill="${filled ? 'currentColor' : 'none'}" '
      'stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">'
      '${icon.paths}</svg>',
      width: size,
      height: size,
      theme: SvgTheme(currentColor: c),
      excludeFromSemantics: true,
    );
  }
}

/// Something in progress (3.8.9, «the circle by the commands does not turn»): the spinner arc
/// turning once a second. With reduced motion (the app's switch or the system's) it stays still
/// and shows three dots instead, a clear «waiting» rather than an arc that looks stuck.
class RgSpinner extends StatefulWidget {
  const RgSpinner({super.key, this.size = 22, this.color});

  final double size;

  /// Default: the surrounding text colour.
  final Color? color;

  @override
  State<RgSpinner> createState() => _RgSpinnerState();
}

class _RgSpinnerState extends State<RgSpinner> with SingleTickerProviderStateMixin {
  late final AnimationController _turn = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 1),
  );

  bool get _still =>
      (MediaQuery.maybeDisableAnimationsOf(context) ?? false) ||
      (MascotScope.maybeOf(context)?.reduceMotion ?? false);

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_still) {
      _turn.stop();
    } else if (!_turn.isAnimating) {
      _turn.repeat();
    }
  }

  @override
  void dispose() {
    _turn.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_still) {
      return RgIcon(
        RgIcons.more,
        key: const Key('spinner-still'),
        size: widget.size,
        color: widget.color,
      );
    }
    return RotationTransition(
      key: const Key('spinner-turning'),
      turns: _turn,
      child: RgIcon(RgIcons.spinner, size: widget.size, color: widget.color),
    );
  }
}

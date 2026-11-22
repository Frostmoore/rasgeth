// RedGiant's colours, the same as the page's CSS variables (packages/web/src/styles.css,
// `:root` and `html[data-theme="dark"]`): keep the two in step.
import 'package:flutter/material.dart';

@immutable
class RgColors extends ThemeExtension<RgColors> {
  const RgColors({
    required this.bg,
    required this.panel,
    required this.panel2,
    required this.line,
    required this.text,
    required this.dim,
    required this.accent,
    required this.accent2,
    required this.accentSoft,
    required this.accentDim,
    required this.ok,
    required this.warn,
    required this.warnText,
    required this.err,
    required this.critical,
    required this.criticalInk,
    required this.criticalSoft,
    required this.criticalText,
    required this.user,
    required this.code,
  });

  /// `:root`.
  static const light = RgColors(
    bg: Color(0xFFF6F7F9),
    panel: Color(0xFFFFFFFF),
    panel2: Color(0xFFEEF0F4),
    line: Color(0xFFDDE1E8),
    text: Color(0xFF1C2230),
    dim: Color(0xFF6B7385),
    accent: Color(0xFFD23A2C),
    accent2: Color(0xFFB8301F),
    accentSoft: Color(0xFFFBE0DC),
    accentDim: Color(0xFFF2B8B0),
    ok: Color(0xFF2E9D5B),
    warn: Color(0xFFC99A14),
    warnText: Color(0xFF7A5600),
    err: Color(0xFFD23D3D),
    critical: Color(0xFFB0151C),
    criticalInk: Color(0xFFFFFFFF),
    criticalSoft: Color(0xFFFFF4F4),
    criticalText: Color(0xFFB0151C),
    user: Color(0xFFF3E6E4),
    code: Color(0xFF0F131A),
  );

  /// `html[data-theme="dark"]` (`--ok`, `--warn` and `--err` are the light theme's).
  static const dark = RgColors(
    bg: Color(0xFF15171C),
    panel: Color(0xFF1C1F26),
    panel2: Color(0xFF252932),
    line: Color(0xFF313642),
    text: Color(0xFFE8E6E3),
    dim: Color(0xFF8F96A3),
    accent: Color(0xFFEF4B3A),
    accent2: Color(0xFFFF7A68),
    accentSoft: Color(0xFF3A1F1C),
    accentDim: Color(0xFF5A2722),
    ok: Color(0xFF2E9D5B),
    warn: Color(0xFFC99A14),
    warnText: Color(0xFFE0B23A),
    err: Color(0xFFD23D3D),
    critical: Color(0xFFC8242C),
    criticalInk: Color(0xFFFFFFFF),
    criticalSoft: Color(0xFF2A1214),
    criticalText: Color(0xFFFF8A8F),
    user: Color(0xFF33211F),
    code: Color(0xFF0D1016),
  );

  final Color bg;
  final Color panel;
  final Color panel2;
  final Color line;
  final Color text;
  final Color dim;
  final Color accent;
  final Color accent2;
  final Color accentSoft;
  final Color accentDim;
  final Color ok;
  final Color warn;
  final Color warnText;
  final Color err;
  final Color critical;
  final Color criticalInk;
  final Color criticalSoft;
  final Color criticalText;
  final Color user;
  final Color code;

  /// This palette with [accent]'s shades for its brightness (3.10.4, styles.css
  /// `html[data-accent=…]`): red is the palette's own.
  RgColors withAccent(RgAccent accent, Brightness brightness) {
    final s = accent.shades(brightness);
    if (s == null) return this;
    return RgColors(
      bg: bg,
      panel: panel,
      panel2: panel2,
      line: line,
      text: text,
      dim: dim,
      accent: s.accent,
      accent2: s.accent2,
      accentSoft: s.accentSoft,
      accentDim: s.accentDim,
      ok: ok,
      warn: warn,
      warnText: warnText,
      err: err,
      critical: critical,
      criticalInk: criticalInk,
      criticalSoft: criticalSoft,
      criticalText: criticalText,
      user: s.user,
      code: code,
    );
  }

  static RgColors of(BuildContext context) =>
      Theme.of(context).extension<RgColors>() ??
      (Theme.of(context).brightness == Brightness.dark ? dark : light);

  @override
  RgColors copyWith() => this;

  @override
  RgColors lerp(RgColors? other, double t) {
    if (other == null) return this;
    Color l(Color a, Color b) => Color.lerp(a, b, t)!;
    return RgColors(
      bg: l(bg, other.bg),
      panel: l(panel, other.panel),
      panel2: l(panel2, other.panel2),
      line: l(line, other.line),
      text: l(text, other.text),
      dim: l(dim, other.dim),
      accent: l(accent, other.accent),
      accent2: l(accent2, other.accent2),
      accentSoft: l(accentSoft, other.accentSoft),
      accentDim: l(accentDim, other.accentDim),
      ok: l(ok, other.ok),
      warn: l(warn, other.warn),
      warnText: l(warnText, other.warnText),
      err: l(err, other.err),
      critical: l(critical, other.critical),
      criticalInk: l(criticalInk, other.criticalInk),
      criticalSoft: l(criticalSoft, other.criticalSoft),
      criticalText: l(criticalText, other.criticalText),
      user: l(user, other.user),
      code: l(code, other.code),
    );
  }
}

/// One accent's shades for one theme (the page's `--accent`, `--accent-2`, `--accent-soft`,
/// `--accent-dim` and `--user`).
@immutable
class AccentShades {
  const AccentShades(this.accent, this.accent2, this.accentSoft, this.accentDim, this.user);

  final Color accent;
  final Color accent2;
  final Color accentSoft;
  final Color accentDim;
  final Color user;
}

/// The accent colour chosen in «Tu › Aspetto» (3.10.4), the page's `accent.ts`: Rasgeth's red
/// (the default) or one of four others, the same shades as styles.css (colors_parity_test).
/// Each is checked for contrast: white on [AccentShades.accent] 4.5:1 (light) and 3.5:1 (dark),
/// [AccentShades.accent2] (links, list marks) 4.5:1 on the panel.
enum RgAccent {
  red(null, null),
  amber(
    AccentShades(
      Color(0xFFA8640C),
      Color(0xFF8F5208),
      Color(0xFFF8E3C4),
      Color(0xFFEABF7F),
      Color(0xFFEFE8DC),
    ),
    AccentShades(
      Color(0xFFBD7810),
      Color(0xFFEB9A2A),
      Color(0xFF2E2516),
      Color(0xFF45331A),
      Color(0xFF2B241A),
    ),
  ),
  green(
    AccentShades(
      Color(0xFF2C8156),
      Color(0xFF226F49),
      Color(0xFFC3F0DA),
      Color(0xFF7BD8AA),
      Color(0xFFDDECE5),
    ),
    AccentShades(
      Color(0xFF22985D),
      Color(0xFF3EC27F),
      Color(0xFF182A21),
      Color(0xFF1E3C2D),
      Color(0xFF1C2822),
    ),
  ),
  blue(
    AccentShades(
      Color(0xFF3273BF),
      Color(0xFF2563AB),
      Color(0xFFD9E7F9),
      Color(0xFFA9C9EC),
      Color(0xFFE3E9F1),
    ),
    AccentShades(
      Color(0xFF3587E4),
      Color(0xFF5FA5F7),
      Color(0xFF1C2735),
      Color(0xFF223750),
      Color(0xFF1E2630),
    ),
  ),
  violet(
    AccentShades(
      Color(0xFF8A59CB),
      Color(0xFF7C41CB),
      Color(0xFFEBE2F8),
      Color(0xFFD2BDED),
      Color(0xFFEBE7F2),
    ),
    AccentShades(
      Color(0xFF9F6CE3),
      Color(0xFFB98EF2),
      Color(0xFF2D213B),
      Color(0xFF412C5E),
      Color(0xFF2A2233),
    ),
  );

  const RgAccent(this._light, this._dark);

  final AccentShades? _light;
  final AccentShades? _dark;

  /// Null for red: the palette's own shades.
  AccentShades? shades(Brightness b) => b == Brightness.dark ? _dark : _light;

  /// The swatch: the light theme's accent.
  Color get swatch => _light?.accent ?? RgColors.light.accent;

  static RgAccent parse(String? name) =>
      RgAccent.values.firstWhere((a) => a.name == name, orElse: () => RgAccent.red);
}

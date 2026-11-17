// The drawn icon of a file's family, as the page's Canvas tabs and explorer (G34.4,
// `viewers/kind.ts` `tabIconFor`, `components/viewers/FileIcon.tsx`): one icon and one colour per
// family, so a video and a sheet tell apart at a glance. No emoji, no symbol characters.
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../theme/colors.dart';

/// The page's `TabIcon`.
enum FileFamily {
  video,
  audio,
  image,
  pdf,
  document,
  sheet,
  slides,
  model,
  archive,
  code,
  font,
  data,
  design,
  site,
  file,
}

final _byExt = <String, FileFamily>{};

void _put(FileFamily f, String exts) {
  for (final e in exts.split(' ')) {
    _byExt[e] = f;
  }
}

/// The page's `BY_EXT` (viewer kinds) folded into families, then `PAGED` and `DESIGN` on top.
void _fill() {
  if (_byExt.isNotEmpty) return;
  _put(FileFamily.video, 'mp4 m4v webm ogv mov mkv avi wmv flv mpg mpeg 3gp');
  _put(FileFamily.audio, 'mp3 wav ogg oga m4a flac aac opus weba wma aiff aif mid midi amr');
  _put(FileFamily.image, 'png jpg jpeg gif webp avif bmp ico svg tif tiff heic heif');
  _put(FileFamily.pdf, 'pdf');
  _put(FileFamily.document, 'md markdown mdx');
  _put(
    FileFamily.code,
    'js mjs cjs jsx ts mts cts tsx py rb go rs java kt kts swift c h cc cpp hpp cxx cs php sh '
    'bash zsh fish ps1 bat cmd sql css scss sass less vue svelte lua r dart scala clj ex exs erl '
    'hs ml fs pl pm toml ini cfg conf dockerfile makefile cmake gradle tf hcl proto graphql gql '
    'diff patch vim el nix zig',
  );
  _put(
    FileFamily.document,
    'txt log text rst adoc tex bib srt vtt env gitignore editorconfig license readme',
  );
  _put(FileFamily.sheet, 'csv tsv');
  _put(FileFamily.sheet, 'xlsx xlsm xls ods fods numbers');
  _put(FileFamily.document, 'docx odt fodt rtf');
  _put(FileFamily.slides, 'pptx odp');
  _put(FileFamily.model, 'glb gltf obj stl fbx ply');
  _put(FileFamily.archive, 'zip tar tgz gz jar apk');
  _put(FileFamily.font, 'ttf otf woff woff2');
  _put(FileFamily.data, 'json jsonc json5 geojson yaml yml xml plist');
  _put(FileFamily.site, 'html htm xhtml');
  _put(FileFamily.document, 'docx docm dotx dotm doc dot rtf wpd wps odt ott fodt pages');
  _put(FileFamily.sheet, 'xlsx xlsm xltx xls xlsb xlt ods ots fods numbers');
  _put(FileFamily.slides, 'pptx pptm potx ppsx ppt pps pot odp otp fodp key');
  _put(FileFamily.design, 'odg otg fodg vsd vsdx vsdm vdx pub');
  _put(
    FileFamily.design,
    'psd psb ai eps indd idml sketch fig xd afdesign afphoto afpub cdr cmx ora kra xcf sla',
  );
}

/// The lower-case extension ("tar.gz" counts as "tgz"), or "" (the page's `extensionOf`).
String extensionOf(String name) {
  final base = name.split(RegExp(r'[\\/]')).last.toLowerCase();
  if (base.endsWith('.tar.gz')) return 'tgz';
  return RegExp(r'\.([a-z0-9]+)$').firstMatch(base)?.group(1) ?? '';
}

/// The family of a file, from its name (the page's `tabIconFor`).
FileFamily fileFamilyOf(String name) {
  _fill();
  final base = name.split(RegExp(r'[\\/]')).last.toLowerCase();
  if (base == 'dockerfile' || base == 'makefile') return FileFamily.code;
  if (base == 'license' || base == 'readme') return FileFamily.document;
  return _byExt[extensionOf(name)] ?? FileFamily.file;
}

const _outline = 'M14 2H6a2 2 0 0 0-2 2v16a2 2 0 0 0 2 2h12a2 2 0 0 0 2-2V8z';

/// The page's drawings (`icons.tsx`: IconFilm, IconMusic, IconImage, IconFilePdf…).
String _paths(FileFamily f) => switch (f) {
  FileFamily.video =>
    '<rect x="2" y="5" width="14" height="14" rx="2"/><path d="M16 10l6-4v12l-6-4"/>',
  FileFamily.audio =>
    '<path d="M9 18V5l12-2v13"/><circle cx="6" cy="18" r="3"/><circle cx="18" cy="16" r="3"/>',
  FileFamily.image =>
    '<rect x="3" y="3" width="18" height="18" rx="2"/><circle cx="8.5" cy="8.5" r="1.5"/>'
        '<path d="M21 15l-5-5L5 21"/>',
  FileFamily.pdf =>
    '<path d="$_outline"/><path d="M14 2v6h6"/><rect x="7" y="12" width="10" height="6" rx="1"/>',
  FileFamily.document => '<path d="$_outline"/><path d="M14 2v6h6M8 13h8M8 17h8M8 9h2"/>',
  FileFamily.sheet =>
    '<rect x="3" y="3" width="18" height="18" rx="2"/><path d="M3 9h18M3 15h18M9 3v18"/>',
  FileFamily.slides =>
    '<path d="M2 3h20M4 3v11a1 1 0 0 0 1 1h14a1 1 0 0 0 1-1V3M12 15v4M8 21l4-2 4 2"/>',
  FileFamily.model => '<path d="M12 2l9 5v10l-9 5-9-5V7z"/><path d="M3 7l9 5 9-5M12 12v10"/>',
  FileFamily.archive => '<path d="$_outline"/><path d="M10 2v2M10 6v2M10 10v2M8 15h4v4H8z"/>',
  FileFamily.code => '<path d="M16 18l6-6-6-6M8 6l-6 6 6 6"/>',
  FileFamily.font => '<path d="M4 7V4h16v3M9 20h6M12 4v16"/>',
  FileFamily.data =>
    '<path d="M8 3H7a2 2 0 0 0-2 2v4a2 2 0 0 1-2 2 2 2 0 0 1 2 2v4a2 2 0 0 0 2 2h1"/>'
        '<path d="M16 3h1a2 2 0 0 1 2 2v4a2 2 0 0 0 2 2 2 2 0 0 0-2 2v4a2 2 0 0 1-2 2h-1"/>',
  FileFamily.design =>
    '<path d="M12 19l7-7 3 3-7 7-3-3z"/><path d="M18 13l-1.5-7.5L2 2l3.5 14.5L13 18l5-5zM2 2l7.6 7.6"/>'
        '<circle cx="11" cy="11" r="2"/>',
  FileFamily.site =>
    '<circle cx="12" cy="12" r="10"/><path d="M2 12h20M12 2a15 15 0 0 1 0 20a15 15 0 0 1 0-20"/>',
  FileFamily.file => '<path d="$_outline"/><path d="M14 2v6h6"/>',
};

/// The page's `.file-icon.fi-*` colours (styles.css); the rest take the dim text colour.
Color fileFamilyColor(FileFamily f, RgColors c) => switch (f) {
  FileFamily.video || FileFamily.audio => const Color(0xFF8A5CD1),
  FileFamily.image || FileFamily.design => const Color(0xFFC2588F),
  FileFamily.pdf => c.err,
  FileFamily.document => const Color(0xFF3B78C4),
  FileFamily.sheet => c.ok,
  FileFamily.slides => const Color(0xFFD07A1F),
  FileFamily.model || FileFamily.code || FileFamily.data => const Color(0xFF2B9A9A),
  _ => c.dim,
};

const _folder =
    '<path d="M22 19a2 2 0 0 1-2 2H4a2 2 0 0 1-2-2V5a2 2 0 0 1 2-2h5l2 3h9a2 2 0 0 1 2 2z"/>';
const _folderOpen =
    '<path d="M2 19V5a2 2 0 0 1 2-2h5l2 3h7a2 2 0 0 1 2 2v2"/>'
    '<path d="M2 19l2.6-7.4A2 2 0 0 1 6.5 10H21a1 1 0 0 1 .95 1.3L19.6 18.6A2 2 0 0 1 17.7 20H4a2 2 0 0 1-2-1z"/>';

Widget _svg(String paths, double size, Color color, {bool soft = false}) => SvgPicture.string(
  '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" '
  'fill="${soft ? 'currentColor' : 'none'}" fill-opacity="${soft ? '0.16' : '1'}" '
  'stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">'
  '$paths</svg>',
  width: size,
  height: size,
  theme: SvgTheme(currentColor: color),
  excludeFromSemantics: true,
);

/// A file's drawn icon, in its family's colour.
class FileIcon extends StatelessWidget {
  const FileIcon({super.key, required this.name, this.size = 16});

  final String name;
  final double size;

  @override
  Widget build(BuildContext context) {
    final f = fileFamilyOf(name);
    return KeyedSubtree(
      key: ValueKey('file-icon-${f.name}'),
      child: _svg(_paths(f), size, fileFamilyColor(f, RgColors.of(context))),
    );
  }
}

/// A folder, closed or open, in the accent colour with a light fill.
class FolderIcon extends StatelessWidget {
  const FolderIcon({super.key, this.open = false, this.size = 16, this.color});

  final bool open;
  final double size;
  final Color? color;

  @override
  Widget build(BuildContext context) =>
      _svg(open ? _folderOpen : _folder, size, color ?? RgColors.of(context).accent, soft: true);
}

/// The page's explorer buttons that `RgIcons` does not have (`IconFilePlus`, `IconFolderPlus`,
/// `IconEye`, `IconPencil`).
enum FileGlyph {
  filePlus('<path d="$_outline"/><path d="M14 2v6h6M12 18v-6M9 15h6"/>'),
  folderPlus(
    '<path d="M22 19a2 2 0 0 1-2 2H4a2 2 0 0 1-2-2V5a2 2 0 0 1 2-2h5l2 3h9a2 2 0 0 1 2 2z"/>'
    '<path d="M12 11v6M9 14h6"/>',
  ),
  eye('<path d="M1 12s4-8 11-8 11 8 11 8-4 8-11 8S1 12 1 12z"/><circle cx="12" cy="12" r="3"/>'),
  pencil('<path d="M17 3a2.8 2.8 0 0 1 4 4L7.5 20.5 2 22l1.5-5.5z"/>');

  const FileGlyph(this.paths);
  final String paths;
}

class FileGlyphIcon extends StatelessWidget {
  const FileGlyphIcon(this.glyph, {super.key, this.size = 18, this.color});

  final FileGlyph glyph;
  final double size;
  final Color? color;

  @override
  Widget build(BuildContext context) => _svg(
    glyph.paths,
    size,
    color ?? DefaultTextStyle.of(context).style.color ?? RgColors.of(context).dim,
  );
}

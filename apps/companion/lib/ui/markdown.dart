// Markdown, safely (the page's `renderMarkdown` with DOMPurify, in Flutter terms): no raw HTML is
// ever interpreted (a tag shows as the text it is), no image is fetched from the network (the
// alt text shows instead: nothing leaks where the person reads), links open outside the app only
// for http(s) and mailto, after the person says yes. Task lists use our drawn marks, never the
// system's checkboxes. A passage between `markOpen` and `markClose` (api/saved.dart) is lit up:
// a saved passage or a quote, found again in its message.
import 'package:flutter/material.dart';
import 'package:flutter_markdown_plus/flutter_markdown_plus.dart';
import 'package:markdown/markdown.dart' as md;
import 'package:url_launcher/url_launcher.dart';

import '../api/saved.dart';
import '../l10n/app_localizations.dart';
import '../theme/colors.dart';
import 'dialogs.dart';
import 'icons.dart';

/// GitHub's Markdown without the inline HTML syntax: `<b>` stays the text «<b>».
final md.ExtensionSet safeExtensions = md.ExtensionSet(
  md.ExtensionSet.gitHubFlavored.blockSyntaxes,
  md.ExtensionSet.gitHubFlavored.inlineSyntaxes.where((s) => s is! md.InlineHtmlSyntax).toList(),
);

/// The words of a lit passage: `markOpen` … `markClose`, never with Markdown marks inside.
class _MarkSyntax extends md.InlineSyntax {
  _MarkSyntax() : super('$markOpen([^$markOpen$markClose]*)$markClose');

  @override
  bool onMatch(md.InlineParser parser, Match match) {
    parser.addNode(md.Element.text('rgmark', match[1]!));
    return true;
  }
}

class _MarkBuilder extends MarkdownElementBuilder {
  _MarkBuilder(this.color);

  final Color color;

  @override
  Widget? visitElementAfterWithContext(
    BuildContext context,
    md.Element element,
    TextStyle? preferredStyle,
    TextStyle? parentStyle,
  ) => Text.rich(
    TextSpan(
      text: element.textContent,
      style: (parentStyle ?? const TextStyle()).copyWith(backgroundColor: color),
    ),
  );
}

/// The links the app may open (outside, in the system's browser or mail app).
bool openableLink(String? href) {
  final u = Uri.tryParse(href ?? '');
  return u != null && (u.scheme == 'https' || u.scheme == 'http' || u.scheme == 'mailto');
}

class SafeMarkdown extends StatelessWidget {
  const SafeMarkdown(this.data, {super.key, this.selectable = true});

  final String data;
  final bool selectable;

  Future<void> _open(BuildContext context, String? href) async {
    if (!openableLink(href)) return;
    final l = AppLocalizations.of(context);
    final ok = await askConfirm(context, title: l.linkOpenTitle, body: href!, yes: l.linkOpen);
    if (ok) await launchUrl(Uri.parse(href), mode: LaunchMode.externalApplication);
  }

  @override
  Widget build(BuildContext context) {
    final c = RgColors.of(context);
    final base = Theme.of(context).textTheme.bodyMedium!
        .copyWith(color: c.text, fontSize: 15, height: 1.4);
    return MarkdownBody(
      data: data,
      selectable: selectable,
      extensionSet: safeExtensions,
      inlineSyntaxes: data.contains(markOpen) ? [_MarkSyntax()] : null,
      builders: data.contains(markOpen) ? {'rgmark': _MarkBuilder(c.accentDim)} : const {},
      onTapLink: (text, href, title) => _open(context, href),
      imageBuilder: (uri, title, alt) => Container(
        margin: const EdgeInsets.symmetric(vertical: 2),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: c.panel2,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: c.line),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            RgIcon(RgIcons.image, size: 15, color: c.dim),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                (alt == null || alt.isEmpty) ? uri.toString() : alt,
                style: TextStyle(color: c.dim, fontSize: 13),
              ),
            ),
          ],
        ),
      ),
      checkboxBuilder: (v) => Padding(
        padding: const EdgeInsets.only(right: 6),
        child: RgIcon(v ? RgIcons.checkSquare : RgIcons.square, size: 16, color: v ? c.ok : c.dim),
      ),
      styleSheet: MarkdownStyleSheet.fromTheme(Theme.of(context)).copyWith(
        p: base,
        listBullet: base,
        a: base.copyWith(color: c.accent, decoration: TextDecoration.underline),
        code: base.copyWith(fontFamily: 'monospace', fontSize: 13.5, backgroundColor: c.panel2),
        codeblockDecoration: BoxDecoration(
          color: c.panel2,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: c.line),
        ),
        blockquoteDecoration: BoxDecoration(
          border: Border(left: BorderSide(color: c.accentDim, width: 3)),
        ),
        h1: base.copyWith(fontSize: 21, fontWeight: FontWeight.w700),
        h2: base.copyWith(fontSize: 18.5, fontWeight: FontWeight.w700),
        h3: base.copyWith(fontSize: 16.5, fontWeight: FontWeight.w700),
        tableBody: base,
        tableHead: base.copyWith(fontWeight: FontWeight.w700),
      ),
    );
  }
}

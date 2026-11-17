// A code block in an answer (G42.1), as the page's (`marked`'s `code` renderer in
// packages/web/src/markdown.ts): a head with its language and «Copia» («Copiato» for a moment),
// then the code coloured (`highlight.dart`), scrolling sideways rather than wrapping.
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_markdown_plus/flutter_markdown_plus.dart';
import 'package:markdown/markdown.dart' as md;

import '../l10n/app_localizations.dart';
import '../theme/colors.dart';
import 'highlight.dart';

/// The `pre` element of a finished answer.
class CodeBlockBuilder extends MarkdownElementBuilder {
  @override
  bool isBlockElement() => true;

  @override
  Widget? visitElementAfterWithContext(
    BuildContext context,
    md.Element element,
    TextStyle? preferredStyle,
    TextStyle? parentStyle,
  ) {
    final code = element.children?.whereType<md.Element>().firstOrNull;
    final cls = code?.attributes['class'] ?? '';
    final lang = cls.startsWith('language-') ? cls.substring(9).split(' ').first.toLowerCase() : '';
    final text = (code ?? element).textContent.replaceFirst(RegExp(r'\n$'), '');
    return CodeBlock(code: text, lang: lang);
  }
}

/// Names the page's highlighter knows, mapped to the app's highlighter's extensions.
String? _extOf(String lang) => switch (lang) {
  'typescript' => 'ts',
  'javascript' => 'js',
  'python' => 'py',
  'shell' || 'bash' || 'zsh' || 'console' => 'sh',
  'yaml' => 'yml',
  'rust' => 'rs',
  'kotlin' => 'kt',
  'csharp' => 'cs',
  'markdown' || 'text' || 'plaintext' || '' => null,
  final l => l,
};

/// The head's grey (`.code-head`).
const _head = Color(0xFF8F96A3);

class CodeBlock extends StatefulWidget {
  const CodeBlock({super.key, required this.code, this.lang = ''});

  final String code;
  final String lang;

  @override
  State<CodeBlock> createState() => _CodeBlockState();
}

class _CodeBlockState extends State<CodeBlock> {
  bool _copied = false;
  Timer? _back;

  @override
  void dispose() {
    _back?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = RgColors.of(context);
    final l = AppLocalizations.of(context);
    final ext = _extOf(widget.lang);
    const mono = TextStyle(fontFamily: 'monospace', fontSize: 13, height: 1.45);
    return Container(
      key: const Key('code-block'),
      margin: const EdgeInsets.symmetric(vertical: 4),
      decoration: BoxDecoration(
        // Always dark, as the page's `.code` (`--code`), with the dark theme's colours inside.
        color: c.code,
        borderRadius: BorderRadius.circular(8),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.fromLTRB(12, 2, 4, 2),
            decoration: const BoxDecoration(
              border: Border(bottom: BorderSide(color: Color(0x14FFFFFF))),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(widget.lang, style: const TextStyle(color: _head, fontSize: 11)),
                ),
                TextButton(
                  key: const Key('code-copy'),
                  style: TextButton.styleFrom(
                    visualDensity: VisualDensity.compact,
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    minimumSize: const Size(0, 28),
                  ),
                  onPressed: () async {
                    await Clipboard.setData(ClipboardData(text: widget.code));
                    if (!mounted) return;
                    setState(() => _copied = true);
                    _back?.cancel();
                    _back = Timer(const Duration(milliseconds: 1500), () {
                      if (mounted) setState(() => _copied = false);
                    });
                  },
                  child: Text(
                    _copied ? l.cvCopied : l.cvCopy,
                    style: const TextStyle(color: _head, fontSize: 11.5),
                  ),
                ),
              ],
            ),
          ),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.all(10),
            child: SelectableText.rich(
              TextSpan(
                style: mono.copyWith(color: RgColors.dark.text),
                children: [
                  for (final (i, line) in widget.code.split('\n').indexed) ...[
                    if (i > 0) const TextSpan(text: '\n'),
                    ...highlightLine(line, ext, RgColors.dark),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// A tool call in the conversation (G42.1), as the page's `ToolLine` (Chat.tsx): one line with a
// mark (a spinner while it runs, a green dot when done, a red X when it failed: no check marks),
// its name (an external agent's action in words, `toolHead`), the machine or node it works on,
// «dal programma» for a call of run_script, the gist of its input, how find_files searched, and
// what a file tool changed (+n −m). Under it what canvas_look saw, the mail cards, the diff, the
// picture generate_image made, the sub-agents' conversations as links; a tap unfolds the input
// and the result.
import '../dialogs.dart';

import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';

import '../../api/conversation.dart';
import '../../api/mail.dart' show mailSummary;
import '../../app_state.dart';
import '../../l10n/app_localizations.dart';
import '../../theme/colors.dart';
import '../icons.dart';
import 'mail_cards.dart';

/// `toolHead` (Chat.tsx): the name, and the gist of the input.
({String name, String summary}) toolHead(AppLocalizations l, String tool, Object? raw) {
  final input = raw is Map ? raw : null;
  final acp = RegExp(r'^acp_([a-z_]+)$').firstMatch(tool)?.group(1);
  String? first(List<Object?> v) => v.whereType<String>().where((x) => x.isNotEmpty).firstOrNull;
  if (acp != null) {
    final name = switch (acp) {
      'read' => l.cvAcpKindRead,
      'edit' => l.cvAcpKindEdit,
      'delete' => l.cvAcpKindDelete,
      'move' => l.cvAcpKindMove,
      'search' => l.cvAcpKindSearch,
      'execute' => l.cvAcpKindExecute,
      'think' => l.cvAcpKindThink,
      'fetch' => l.cvAcpKindFetch,
      'switch_mode' => l.cvAcpKindSwitchMode,
      _ => l.cvAcpKindOther,
    };
    return (name: name, summary: first([input?['title'], input?['command'], input?['path']]) ?? '');
  }
  return (name: tool, summary: input == null ? '' : _gist(input));
}

String _gist(Map<dynamic, dynamic> input, [String? copy]) {
  for (final v in [
    copy,
    input['command'],
    input['path'],
    input['pattern'],
    input['query'],
    input['url'],
  ]) {
    if (v != null) return '$v';
  }
  return jsonEncode(input);
}

/// The line find_files ends its answer with (`parseFindTiming`, find-timing.ts), in words.
String? findTimingText(AppLocalizations l, String output, String lang) {
  final line = output.split('\n').reversed.where((x) => x.startsWith('Search: ')).firstOrNull;
  if (line == null) return null;
  final m = RegExp(r'^Search: (.+), (\d+(?:\.\d+)?) s(?: \((?:cut at (\d+) s|(interrupted))\))?\.$')
      .firstMatch(line);
  if (m == null) return null;
  final via = switch (m.group(1)) {
    "Everything's index" => l.cvFindViaEverything,
    "Spotlight's index" => l.cvFindViaSpotlight,
    'the locate database' => l.cvFindViaLocate,
    'walked the folders' => l.cvFindViaWalk,
    'the programs on the PATH' => l.cvFindViaPath,
    'find in the container' => l.cvFindViaContainer,
    _ => null,
  };
  if (via == null) return null;
  String n(String s, int digits) {
    final t = double.parse(s).toStringAsFixed(digits);
    return lang == 'it' ? t.replaceAll('.', ',') : t;
  }

  final seconds = n(m.group(2)!, 1);
  if (m.group(3) != null) return l.cvFindTookCut(via, seconds, n(m.group(3)!, 0));
  if (m.group(4) != null) return l.cvFindTookInterrupted(via, seconds);
  return l.cvFindTook(via, seconds);
}

/// A file tool's diff (the ```diff block of its answer) and its lines added and removed.
({String diff, int added, int removed})? diffOf(String? output) {
  final m = RegExp(r'```diff\n([\s\S]*?)```').firstMatch(output ?? '');
  if (m == null) return null;
  final d = m.group(1)!;
  final lines = d.split('\n');
  return (
    diff: d,
    added: lines.where((x) => x.startsWith('+')).length,
    removed: lines.where((x) => x.startsWith('-')).length,
  );
}

/// The sub-agents' conversations a report names (`Conversation: <id> (<agent>)`).
List<({String sessionId, String agentId})> talksOf(String? output) => [
  for (final m in RegExp(
    r'^Conversation: (\S+) \((\S+)\)$',
    multiLine: true,
  ).allMatches(output ?? ''))
    (sessionId: m.group(1)!, agentId: m.group(2)!),
];

class ToolLine extends StatefulWidget {
  const ToolLine({super.key, required this.item, this.scope, this.onOpenSession});

  final ToolItem item;

  /// Where the agent's files are (its project's, or God's): for the picture it drew.
  final String? scope;

  /// Opens a sub-agent's conversation.
  final void Function(String sessionId, String agentId)? onOpenSession;

  @override
  State<ToolLine> createState() => _ToolLineState();
}

class _ToolLineState extends State<ToolLine> {
  bool _open = false;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final c = RgColors.of(context);
    final app = AppScope.maybeRead(context);
    final lang = Localizations.localeOf(context).languageCode;
    final it = widget.item;
    final input = it.input is Map ? it.input as Map : null;
    final head = toolHead(l, it.tool, it.input);
    final copy = it.tool == 'ssh_copy' && input != null
        ? input['direction'] == 'download'
              ? '${input['remote'] ?? ''} -> ${input['local'] ?? ''}'
              : '${input['local'] ?? ''} -> ${input['remote'] ?? ''}'
        : null;
    final machine = it.tool.startsWith('ssh_') && (input?['machine'] is String)
        ? input!['machine'] as String
        : null;
    final node = it.tool == 'node_run'
        ? (input?['node'] is String)
              ? input!['node'] as String
              : RegExp(r'^Node: ([^\n,]+)', multiLine: true).firstMatch(it.output ?? '')?.group(1)
        : null;
    final summary = it.tool.startsWith('acp_')
        ? head.summary
        : (mailSummary(l, it.tool, it.input) ?? (input == null ? '' : _gist(input, copy)));
    final state = it.ok == null ? 'running' : (it.ok! ? 'done' : 'failed');
    final output = it.lost ? l.cvToolNoResult : (it.output ?? '');
    final picture = RegExp(r'^Saved (images/\S+\.png)').firstMatch(output)?.group(1);
    final diff = diffOf(it.output);
    final talks = talksOf(it.output);
    final took = it.tool == 'find_files' && it.ok != null ? findTimingText(l, output, lang) : null;
    final shortSum = summary.replaceAll(RegExp(r'\s+'), ' ');
    final mono = TextStyle(fontFamily: 'monospace', fontSize: 12, color: c.dim);
    return Column(
      key: Key('tool-${it.key}'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Semantics(
          button: true,
          expanded: _open,
          child: Material(
            color: c.panel2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
              side: BorderSide(color: c.line),
            ),
            child: InkWell(
              key: Key('tool-head-${it.key}'),
              borderRadius: BorderRadius.circular(8),
              onTap: () => setState(() => _open = !_open),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SizedBox(
                      width: 15,
                      child: Center(
                        child: switch (state) {
                          'running' => RgSpinner(size: 13, color: c.accent),
                          'done' => Container(
                            key: const Key('tool-dot'),
                            width: 9,
                            height: 9,
                            decoration: BoxDecoration(color: c.ok, shape: BoxShape.circle),
                          ),
                          _ => RgIcon(RgIcons.x, size: 13, color: c.err),
                        },
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      head.name,
                      style: TextStyle(color: c.text, fontSize: 13, fontWeight: FontWeight.w600),
                    ),
                    if (machine != null) ...[
                      const SizedBox(width: 8),
                      _Chip(
                        icon: RgIcons.server,
                        text: machine,
                        tooltip: l.cvToolOnMachine(machine),
                      ),
                    ],
                    if (node != null) ...[
                      const SizedBox(width: 8),
                      _Chip(icon: RgIcons.nodes, text: l.cvToolOnNode(node)),
                    ],
                    if (it.viaScript) ...[
                      const SizedBox(width: 8),
                      Text(
                        l.cvViaScript,
                        style: TextStyle(color: c.dim, fontSize: 12, fontStyle: FontStyle.italic),
                      ),
                    ],
                    if (shortSum.isNotEmpty) ...[
                      const SizedBox(width: 8),
                      Flexible(
                        child: Text(
                          shortSum.length > 140 ? shortSum.substring(0, 140) : shortSum,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: mono,
                        ),
                      ),
                    ],
                    if (took != null) ...[
                      const SizedBox(width: 8),
                      Text(took, style: TextStyle(color: c.dim, fontSize: 12)),
                    ],
                    if (diff != null) ...[
                      const SizedBox(width: 8),
                      Text(
                        '+${diff.added}',
                        key: const Key('tool-diff-count'),
                        style: TextStyle(color: c.ok, fontSize: 12, fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '-${diff.removed}',
                        style: TextStyle(color: c.err, fontSize: 12, fontWeight: FontWeight.w600),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ),
        if (it.images.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 6),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(l.cvToolSeen, style: TextStyle(color: c.dim, fontSize: 12.5)),
                const SizedBox(height: 4),
                ImageStrip(images: it.images),
              ],
            ),
          ),
        if (it.ok == true && it.tool.startsWith('mail_'))
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: MailToolCard(tool: it.tool, output: it.output ?? ''),
          ),
        if (diff != null)
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: DiffBlock(diff: diff.diff),
          ),
        if (_open)
          Container(
            key: Key('tool-detail-${it.key}'),
            margin: const EdgeInsets.only(top: 4),
            padding: const EdgeInsets.all(8),
            constraints: const BoxConstraints(maxHeight: 260),
            decoration: BoxDecoration(
              color: c.code,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: c.line),
            ),
            child: SingleChildScrollView(
              child: SelectableText(
                '${const JsonEncoder.withIndent('  ').convert(it.input)}${it.ok == null ? '' : '\n\n$output'}',
                style: TextStyle(fontFamily: 'monospace', fontSize: 12, color: c.text),
              ),
            ),
          ),
        if (talks.isNotEmpty)
          Wrap(
            spacing: 10,
            children: [
              for (final t in talks)
                TextButton(
                  key: Key('tool-talk-${t.sessionId}'),
                  onPressed: widget.onOpenSession == null
                      ? null
                      : () => widget.onOpenSession!(t.sessionId, t.agentId),
                  child: Text(
                    l.cvOpenSubagentChat(
                      app?.agents.where((a) => a.id == t.agentId).firstOrNull?.name ??
                          l.cvKindSubagent,
                    ),
                  ),
                ),
            ],
          ),
        if (it.tool == 'generate_image' && it.ok == true && picture != null && widget.scope != null)
          Padding(
            padding: const EdgeInsets.only(top: 6),
            child: WorkspaceImage(scope: widget.scope!, path: picture),
          ),
      ],
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip({required this.icon, required this.text, this.tooltip});

  final RgIcons icon;
  final String text;
  final String? tooltip;

  @override
  Widget build(BuildContext context) {
    final c = RgColors.of(context);
    final chip = Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
      decoration: BoxDecoration(
        color: c.panel,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: c.line),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          RgIcon(icon, size: 12, color: c.dim),
          const SizedBox(width: 4),
          Text(text, style: TextStyle(color: c.dim, fontSize: 12)),
        ],
      ),
    );
    return tooltip == null ? chip : Tooltip(message: tooltip, child: chip);
  }
}

/// A diff shown at once (`.tool-diff`): added lines green, removed red, the hunks' heads dim.
class DiffBlock extends StatelessWidget {
  const DiffBlock({super.key, required this.diff});

  final String diff;

  @override
  Widget build(BuildContext context) {
    final c = RgColors.of(context);
    final lines = diff.endsWith('\n')
        ? diff.substring(0, diff.length - 1).split('\n')
        : diff.split('\n');
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 860, maxHeight: 320),
      child: Container(
        key: const Key('tool-diff'),
        decoration: BoxDecoration(
          color: c.code,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: c.line),
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                for (final line in lines)
                  Container(
                    color: line.startsWith('+') && !line.startsWith('+++')
                        ? c.ok.withValues(alpha: .13)
                        : line.startsWith('-') && !line.startsWith('---')
                        ? c.err.withValues(alpha: .13)
                        : null,
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    child: Text(
                      line.isEmpty ? ' ' : line,
                      style: TextStyle(
                        fontFamily: 'monospace',
                        fontSize: 12,
                        height: 1.45,
                        color: line.startsWith('@@')
                            ? c.dim
                            : line.startsWith('+')
                            ? c.ok
                            : line.startsWith('-')
                            ? c.err
                            : c.text,
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
}

/// Pictures of a message or of what a tool saw: small, side by side; a tap shows one whole.
class ImageStrip extends StatelessWidget {
  const ImageStrip({super.key, required this.images, this.size = 96});

  final List<ImageData> images;
  final double size;

  @override
  Widget build(BuildContext context) {
    final c = RgColors.of(context);
    return Wrap(
      spacing: 6,
      runSpacing: 6,
      children: [
        for (final (i, im) in images.indexed)
          Builder(
            builder: (context) {
              Uint8List? bytes;
              try {
                bytes = base64Decode(im.data);
              } on FormatException {
                bytes = null;
              }
              if (bytes == null) return const SizedBox.shrink();
              final b = bytes;
              return GestureDetector(
                key: Key('image-thumb-$i'),
                onTap: () => showRgWindow<void>(
                  context: context,
                  builder: (_) => Dialog(
                    backgroundColor: c.panel,
                    insetPadding: const EdgeInsets.all(16),
                    child: InteractiveViewer(child: Image.memory(b, fit: BoxFit.contain)),
                  ),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    decoration: BoxDecoration(border: Border.all(color: c.line)),
                    child: Image.memory(
                      b,
                      width: size,
                      height: size,
                      fit: BoxFit.cover,
                      semanticLabel: im.name,
                      errorBuilder: (_, _, _) => SizedBox(width: size, height: size),
                    ),
                  ),
                ),
              );
            },
          ),
      ],
    );
  }
}

/// A picture from the workspace (generate_image's result), read with the device's token.
class WorkspaceImage extends StatefulWidget {
  const WorkspaceImage({super.key, required this.scope, required this.path});

  final String scope;
  final String path;

  @override
  State<WorkspaceImage> createState() => _WorkspaceImageState();
}

class _WorkspaceImageState extends State<WorkspaceImage> {
  Uint8List? _bytes;
  bool _failed = false;

  @override
  void initState() {
    super.initState();
    final c = AppScope.read(context).client;
    if (c == null) {
      _failed = true;
      return;
    }
    unawaited(
      c
          .fileRaw(widget.scope, widget.path)
          .then(
            (b) {
              if (mounted) setState(() => _bytes = b);
            },
            onError: (Object _) {
              if (mounted) setState(() => _failed = true);
            },
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final c = RgColors.of(context);
    if (_failed) return Text(widget.path, style: TextStyle(color: c.dim, fontSize: 12.5));
    final b = _bytes;
    return ClipRRect(
      borderRadius: BorderRadius.circular(10),
      child: Container(
        constraints: const BoxConstraints(
          maxWidth: 360,
          maxHeight: 360,
          minWidth: 120,
          minHeight: 120,
        ),
        color: c.panel2,
        child: b == null
            ? const SizedBox(width: 200, height: 200)
            : Image.memory(b, fit: BoxFit.contain, semanticLabel: widget.path),
      ),
    );
  }
}

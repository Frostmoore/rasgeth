// G42.13: the pieces Settings › Telegram and Chats share, drawn as the page's (SetupTelegram.tsx
// `Chat`, the phone beside the steps, the steps on a path `wz-path`, the code `wz-code`, an
// account with Unlink `sb-account`). Our drawn controls only; no emoji, no symbols as icons.
import 'package:flutter/material.dart';

import '../../theme/colors.dart';
import '../../ui/icons.dart';

/// How a link outside opens (the system's browser; a test records it).
typedef OpenLink = Future<bool> Function(Uri u);

/// A chat as Telegram shows it: who, the messages, what is at the bottom.
class ChatPreview extends StatelessWidget {
  const ChatPreview({
    super.key,
    this.caption,
    this.ours = false,
    required this.name,
    required this.sub,
    required this.messages,
    this.bottom,
    this.startBar,
  });

  /// Above the chat on a phone: «You will see» / «Your bot».
  final String? caption;

  /// Our bot (the product's spark) rather than someone else's.
  final bool ours;
  final String name;
  final String sub;

  /// (sent by the person, text).
  final List<(bool, String)> messages;

  /// The field at the bottom («Message»).
  final String? bottom;

  /// The big «Start» bar at the bottom.
  final String? startBar;

  @override
  Widget build(BuildContext context) {
    final c = RgColors.of(context);
    return Container(
      margin: const EdgeInsets.only(top: 10),
      decoration: BoxDecoration(
        color: c.panel2,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: c.line),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (caption != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
              child: Text(
                caption!.toUpperCase(),
                style: TextStyle(
                  color: c.dim,
                  fontSize: 10.5,
                  fontWeight: FontWeight.w800,
                  letterSpacing: .5,
                ),
              ),
            ),
          Container(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
            decoration: BoxDecoration(
              border: Border(bottom: BorderSide(color: c.line)),
            ),
            child: Row(
              children: [
                Container(
                  width: 30,
                  height: 30,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: ours ? c.accent : c.dim.withValues(alpha: .25),
                  ),
                  child: Center(
                    child: RgIcon(
                      ours ? RgIcons.spark : RgIcons.send,
                      size: 16,
                      color: ours ? Colors.white : c.text,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontWeight: FontWeight.w800,
                          color: c.text,
                          fontSize: 13.5,
                        ),
                      ),
                      Text(sub, style: TextStyle(color: c.dim, fontSize: 11.5)),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              spacing: 6,
              children: [
                for (final (me, text) in messages)
                  Align(
                    alignment: me ? Alignment.centerRight : Alignment.centerLeft,
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 260),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                        decoration: BoxDecoration(
                          color: me ? c.accentSoft : c.panel,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: me ? c.accentDim : c.line),
                        ),
                        child: Text(
                          text,
                          style: TextStyle(color: c.text, fontSize: 12.5, height: 1.3),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          if (startBar != null)
            Container(
              padding: const EdgeInsets.symmetric(vertical: 10),
              color: c.accent,
              alignment: Alignment.center,
              child: Text(
                startBar!,
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800),
              ),
            ),
          if (bottom != null)
            Container(
              margin: const EdgeInsets.fromLTRB(10, 0, 10, 10),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: c.panel,
                borderRadius: BorderRadius.circular(99),
                border: Border.all(color: c.line),
              ),
              child: Text(bottom!, style: TextStyle(color: c.dim, fontSize: 12.5)),
            ),
        ],
      ),
    );
  }
}

/// A phone around a chat, beside the steps on a computer (the page's `wz-phone`).
class PhoneFrame extends StatelessWidget {
  const PhoneFrame({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final c = RgColors.of(context);
    return ExcludeSemantics(
      child: Container(
        padding: const EdgeInsets.fromLTRB(8, 10, 8, 14),
        decoration: BoxDecoration(
          color: c.panel,
          borderRadius: BorderRadius.circular(30),
          border: Border.all(color: c.line, width: 2),
        ),
        child: Column(
          children: [
            Container(
              width: 70,
              height: 6,
              decoration: BoxDecoration(color: c.line, borderRadius: BorderRadius.circular(99)),
            ),
            const SizedBox(height: 4),
            ConstrainedBox(constraints: const BoxConstraints(minHeight: 330), child: child),
          ],
        ),
      ),
    );
  }
}

/// One step on the path: its number in a circle (ticked when done), its title with the state,
/// its words and what it needs.
class PathStep extends StatelessWidget {
  const PathStep({
    super.key,
    required this.n,
    required this.state,
    required this.lit,
    required this.done,
    required this.title,
    required this.text,
    this.children = const [],
    this.last = false,
  });

  final int n;
  final String state;
  final bool lit;
  final bool done;
  final String title;
  final String text;
  final List<Widget> children;
  final bool last;

  @override
  Widget build(BuildContext context) {
    final c = RgColors.of(context);
    final tone = done ? c.ok : (lit ? c.accent : c.dim);
    // The line down to the next step is the content's left border; the number sits on it.
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          margin: const EdgeInsets.only(left: 15),
          padding: EdgeInsets.only(left: 29, bottom: last ? 4 : 22),
          decoration: BoxDecoration(
            border: last
                ? null
                : Border(
                    left: BorderSide(color: done ? c.ok.withValues(alpha: .5) : c.line, width: 2),
                  ),
          ),
          child: Opacity(
            opacity: done || lit ? 1 : .6,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Wrap(
                    spacing: 8,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          fontWeight: FontWeight.w800,
                          color: c.text,
                          fontSize: 15.5,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                        decoration: BoxDecoration(
                          color: tone.withValues(alpha: .14),
                          borderRadius: BorderRadius.circular(99),
                        ),
                        child: Text(
                          state,
                          style: TextStyle(
                            color: tone,
                            fontSize: 11.5,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(top: 4, bottom: 8),
                  child: Text(text, style: TextStyle(color: c.dim, fontSize: 13.5, height: 1.4)),
                ),
                ...children,
              ],
            ),
          ),
        ),
        Positioned(
          left: 0,
          top: 0,
          child: Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: done || lit ? tone : c.bg,
              border: Border.all(color: tone, width: 2),
            ),
            child: Center(
              child: done
                  ? const RgIcon(RgIcons.check, size: 15, color: Colors.white)
                  : Text(
                      '$n',
                      style: TextStyle(
                        color: lit ? Colors.white : c.dim,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
            ),
          ),
        ),
      ],
    );
  }
}

/// A pairing code, big and selectable (the page's `wz-code`).
class CodePill extends StatelessWidget {
  const CodePill(this.code, {super.key});

  final String code;

  @override
  Widget build(BuildContext context) {
    final c = RgColors.of(context);
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: c.accentSoft,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: c.accentDim),
        ),
        child: SelectableText(
          code,
          style: TextStyle(
            color: c.text,
            fontSize: 20,
            fontWeight: FontWeight.w800,
            letterSpacing: 2,
            fontFamily: 'monospace',
          ),
        ),
      ),
    );
  }
}

/// An account that talks to the bot, with Unlink.
class AccountRow extends StatelessWidget {
  const AccountRow({
    super.key,
    required this.name,
    this.help,
    required this.unlinkLabel,
    required this.onUnlink,
  });

  final String name;
  final String? help;
  final String unlinkLabel;
  final VoidCallback onUnlink;

  @override
  Widget build(BuildContext context) {
    final c = RgColors.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Container(
            width: 30,
            height: 30,
            decoration: BoxDecoration(shape: BoxShape.circle, color: c.accentSoft),
            child: Center(child: RgIcon(RgIcons.chat, size: 15, color: c.accent)),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: TextStyle(fontWeight: FontWeight.w700, color: c.text),
                ),
                if (help != null) Text(help!, style: TextStyle(color: c.dim, fontSize: 12.5)),
              ],
            ),
          ),
          OutlinedButton(onPressed: onUnlink, child: Text(unlinkLabel)),
        ],
      ),
    );
  }
}

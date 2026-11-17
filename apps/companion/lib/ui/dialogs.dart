// Our own dialogs (as the page's `askConfirm`/`askText`): never a system prompt. Every window the
// app opens over a screen goes through this file (`showRgWindow`, `showRgOverlay`), as the page's
// Modal: test/no_native_controls_test.dart fails on a `showDialog` anywhere else (G42.0).
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../l10n/app_localizations.dart';
import '../theme/colors.dart';

/// A link an agent-made page wants to open (the page's `listenPreviewLinks`, 3.5.8): opened
/// outside the app only after the person says yes. Artifacts, widgets and every embed (G42.2).
Future<void> askOpenPreviewLink(BuildContext context, Uri url) async {
  if (url.scheme != 'http' && url.scheme != 'https') return;
  final l = AppLocalizations.of(context);
  final yes = await askConfirm(
    context,
    title: l.previewLinkTitle,
    body: url.toString(),
    yes: l.previewLinkOpen,
  );
  if (yes) await launchUrl(url, mode: LaunchMode.externalApplication);
}

Future<bool> askConfirm(
  BuildContext context, {
  required String title,
  required String body,
  required String yes,
  bool danger = false,
}) async {
  final l = AppLocalizations.of(context);
  final c = RgColors.of(context);
  final r = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text(title),
      content: SelectableText(body),
      actions: [
        TextButton(
          key: const Key('dialog-no'),
          onPressed: () => Navigator.pop(context, false),
          child: Text(l.cancel),
        ),
        FilledButton(
          key: const Key('dialog-yes'),
          style: danger ? FilledButton.styleFrom(backgroundColor: c.critical) : null,
          onPressed: () => Navigator.pop(context, true),
          child: Text(yes),
        ),
      ],
    ),
  );
  return r ?? false;
}

Future<String?> askText(
  BuildContext context, {
  required String title,
  String initial = '',
  required String yes,
  String? hint,
  Key? fieldKey,
}) => showDialog<String>(
  context: context,
  builder: (context) =>
      _TextDialog(title: title, initial: initial, yes: yes, hint: hint, fieldKey: fieldKey),
);

/// The dialog owns its field: the controller lives as long as the dialog (its closing animation
/// included), never disposed under it.
class _TextDialog extends StatefulWidget {
  const _TextDialog({
    required this.title,
    required this.initial,
    required this.yes,
    this.hint,
    this.fieldKey,
  });

  final String title;
  final String initial;
  final String yes;
  final String? hint;
  final Key? fieldKey;

  @override
  State<_TextDialog> createState() => _TextDialogState();
}

class _TextDialogState extends State<_TextDialog> {
  late final _t = TextEditingController(text: widget.initial);

  @override
  void dispose() {
    _t.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return AlertDialog(
      title: Text(widget.title),
      content: TextField(
        key: widget.fieldKey ?? const Key('dialog-text'),
        controller: _t,
        autofocus: true,
        decoration: widget.hint == null ? null : InputDecoration(hintText: widget.hint),
        onSubmitted: (v) => Navigator.pop(context, v),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: Text(l.cancel)),
        FilledButton(
          key: const Key('dialog-yes'),
          onPressed: () => Navigator.pop(context, _t.text),
          child: Text(widget.yes),
        ),
      ],
    );
  }
}

/// A window over the screen (drawn by us: `AlertDialog`, `Dialog` with our colours).
Future<T?> showRgWindow<T>({
  required BuildContext context,
  required WidgetBuilder builder,
  bool barrierDismissible = true,
}) => showDialog<T>(context: context, barrierDismissible: barrierDismissible, builder: builder);

/// A layer over the screen with no frame of its own (the palette, the quick chat).
Future<T?> showRgOverlay<T>({
  required BuildContext context,
  required RoutePageBuilder pageBuilder,
  required String barrierLabel,
  required Color barrierColor,
  Duration transitionDuration = const Duration(milliseconds: 140),
}) => showGeneralDialog<T>(
  context: context,
  barrierDismissible: true,
  barrierLabel: barrierLabel,
  barrierColor: barrierColor,
  transitionDuration: transitionDuration,
  pageBuilder: pageBuilder,
);

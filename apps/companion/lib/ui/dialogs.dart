// Our own dialogs (as the page's `askConfirm`/`askText`): never a system prompt.
import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import '../theme/colors.dart';

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
}) async {
  final l = AppLocalizations.of(context);
  final t = TextEditingController(text: initial);
  final r = await showDialog<String>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text(title),
      content: TextField(
        key: const Key('dialog-text'),
        controller: t,
        autofocus: true,
        onSubmitted: (v) => Navigator.pop(context, v),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: Text(l.cancel)),
        FilledButton(
          key: const Key('dialog-yes'),
          onPressed: () => Navigator.pop(context, t.text),
          child: Text(yes),
        ),
      ],
    ),
  );
  t.dispose();
  return r;
}

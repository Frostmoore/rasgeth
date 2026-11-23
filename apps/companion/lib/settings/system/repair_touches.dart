// «Repair touches» (3.12.2), the page's RepairTouches.ts: the person's own action for an iOS
// simulator whose taps and keys no longer arrive. It restarts the simulator's home screen and
// closes its open apps, so it is asked first and never runs by itself.
import 'package:flutter/material.dart';

import '../../api/client.dart';

import '../../l10n/app_localizations.dart';
import '../../ui/dialogs.dart';
import '../api/system_api.dart';
import 'system_kit.dart';

/// Asks, then repairs; false when the person said no or it failed (the failure is told).
Future<bool> repairTouches(BuildContext context, String id, String name) async {
  final l = AppLocalizations.of(context);
  final client = sysClient(context);
  final yes = await askConfirm(
    context,
    title: sw(l, 'dvRepairQ', {'name': name}),
    body: l.syDvRepairText,
    yes: l.syDvRepairYes,
    danger: true,
  );
  if (!yes || !context.mounted || client == null) return false;
  try {
    await client.repairDeviceTouches(id);
    return true;
  } on ApiException catch (e) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(sysError(l, e))));
    }
    return false;
  }
}

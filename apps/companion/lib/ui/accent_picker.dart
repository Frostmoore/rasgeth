// The accent colour (3.10.4), the page's `AccentPicker`: five drawn swatches, the chosen one ringed
// and ticked. Never a native radio button.
import 'package:flutter/material.dart';

import '../app_state.dart';
import '../l10n/app_localizations.dart';
import '../theme/colors.dart';
import 'icons.dart';

String accentName(AppLocalizations l, RgAccent a) => switch (a) {
  RgAccent.red => l.accentRed,
  RgAccent.amber => l.accentAmber,
  RgAccent.green => l.accentGreen,
  RgAccent.blue => l.accentBlue,
  RgAccent.violet => l.accentViolet,
};

class AccentPicker extends StatelessWidget {
  const AccentPicker({super.key, required this.app});

  final AppController app;

  @override
  Widget build(BuildContext context) {
    final c = RgColors.of(context);
    final l = AppLocalizations.of(context);
    return Wrap(
      spacing: 6,
      runSpacing: 6,
      children: [
        for (final a in RgAccent.values)
          Semantics(
            selected: a == app.accent,
            button: true,
            label: accentName(l, a),
            child: Material(
              color: a == app.accent ? c.panel2 : Colors.transparent,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(color: a == app.accent ? c.line : Colors.transparent),
              ),
              child: InkWell(
                key: Key('accent-${a.name}'),
                borderRadius: BorderRadius.circular(12),
                onTap: () => app.setAccent(a),
                child: SizedBox(
                  width: 68,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 2),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 34,
                          height: 34,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: a.swatch,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: a == app.accent ? c.text : Colors.transparent,
                              width: 2,
                            ),
                          ),
                          child: a == app.accent
                              ? const RgIcon(RgIcons.check, size: 16, color: Colors.white)
                              : null,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          accentName(l, a),
                          textAlign: TextAlign.center,
                          maxLines: 2,
                          style: TextStyle(
                            fontSize: 12,
                            color: a == app.accent ? c.text : c.dim,
                            fontWeight: a == app.accent ? FontWeight.w600 : FontWeight.w400,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

// «All settings»: the page's Settings inside the app (G40.8), on all five systems since G42.0: an
// `EmbedView` of the whole page (no `embed=`) with `#token=…&open=settings`, under the app's own bar.
// The web view trusts what the system trusts; a certificate the system does not know goes on only
// when it is the very one the app checked against RedGiant's local CA ([sslProceed]). Links
// elsewhere open outside the app.
import 'dart:typed_data';

import 'package:flutter/material.dart';

import '../api/web_settings.dart';
import '../embed/embed_view.dart';
import '../l10n/app_localizations.dart';
import '../theme/colors.dart';
import '../ui/icons.dart';

class FullSettingsScreen extends StatefulWidget {
  const FullSettingsScreen({
    super.key,
    required this.base,
    required this.token,
    required this.title,
    this.leaf,
  });

  final Uri base;
  final String token;
  final String title;

  /// The certificate checked against the local CA (null: the system's trust only).
  final Uint8List? leaf;

  @override
  State<FullSettingsScreen> createState() => _FullSettingsScreenState();
}

class _FullSettingsScreenState extends State<FullSettingsScreen> {
  Key _view = UniqueKey();

  @override
  Widget build(BuildContext context) {
    final c = RgColors.of(context);
    final l = AppLocalizations.of(context);
    return Scaffold(
      backgroundColor: c.bg,
      body: SafeArea(
        child: Column(
          children: [
            Container(
              decoration: BoxDecoration(
                color: c.panel,
                border: Border(bottom: BorderSide(color: c.line)),
              ),
              child: Row(
                children: [
                  IconButton(
                    key: const Key('full-settings-close'),
                    tooltip: l.close,
                    onPressed: () => Navigator.of(context).pop(),
                    icon: RgIcon(RgIcons.x, color: c.dim),
                  ),
                  Expanded(
                    child: Text(
                      widget.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(fontWeight: FontWeight.w700, color: c.text),
                    ),
                  ),
                  IconButton(
                    key: const Key('full-settings-refresh'),
                    tooltip: l.refresh,
                    onPressed: () => setState(() => _view = UniqueKey()),
                    icon: RgIcon(RgIcons.refresh, size: 18, color: c.dim),
                  ),
                ],
              ),
            ),
            Expanded(
              child: EmbedView(
                key: _view,
                url: fullSettingsUrl(widget.base, token: widget.token),
                leaf: widget.leaf,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

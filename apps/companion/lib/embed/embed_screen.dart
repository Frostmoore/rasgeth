// A screen for one embed (G42.0): the app's own bar (back, the name the page gives, its kind and
// weight, the save state) over an `EmbedView`. The Canvas uses it from G42.6; today it opens the
// web view's test page (Settings of the server › «Web view test»).
import 'dart:typed_data';

import 'package:flutter/material.dart';

import '../api/web_settings.dart';
import '../app_state.dart';
import '../l10n/app_localizations.dart';
import '../theme/colors.dart';
import '../ui/icons.dart';
import 'embed_link.dart';
import 'embed_view.dart';

class EmbedScreen extends StatefulWidget {
  const EmbedScreen({
    super.key,
    required this.base,
    required this.params,
    this.leaf,
    required this.title,
  });

  final Uri base;
  final EmbedParams params;
  final Uint8List? leaf;
  final String title;

  @override
  State<EmbedScreen> createState() => _EmbedScreenState();
}

class _EmbedScreenState extends State<EmbedScreen> {
  late String _title = widget.title;
  String? _meta;
  String? _save;

  @override
  Widget build(BuildContext context) {
    final c = RgColors.of(context);
    final l = AppLocalizations.of(context);
    final meta = [?_meta, ?_save].join(' · ');
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
                    key: const Key('embed-back'),
                    tooltip: l.back,
                    onPressed: () => Navigator.of(context).maybePop(),
                    icon: RgIcon(RgIcons.arrowLeft, color: c.text),
                  ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          _title,
                          key: const Key('embed-title'),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(fontWeight: FontWeight.w700, color: c.text),
                        ),
                        if (meta.isNotEmpty)
                          Text(meta, style: TextStyle(color: c.dim, fontSize: 12)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: EmbedView(
                url: embedUrl(widget.base, widget.params),
                nonce: widget.params.bridge,
                leaf: widget.leaf,
                onClose: () => Navigator.of(context).maybePop(),
                onTitle: (t) => setState(() {
                  _title = t.name;
                  _meta = [?t.kind, if (t.size != null) _bytes(t.size!)].join(' · ');
                  if (_meta!.isEmpty) _meta = null;
                }),
                onSaveState: (s, e) => setState(
                  () => _save = switch (s) {
                    'saving' => l.embedSaving,
                    'saved' => l.embedSavedState,
                    _ => l.errGeneric(e ?? ''),
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  static String _bytes(int n) => n < 1024
      ? '$n B'
      : n < 1024 * 1024
      ? '${(n / 1024).toStringAsFixed(0)} KB'
      : '${(n / 1024 / 1024).toStringAsFixed(1)} MB';
}

/// Opens the web view's test page (`#embed=probe`) for the server in use.
Future<void> openEmbedProbe(BuildContext context) async {
  final app = AppScope.read(context);
  final c = app.client;
  final s = app.server;
  final token = c?.token;
  if (c == null || s == null || token == null) return;
  final dark = Theme.of(context).brightness == Brightness.dark;
  final lang = Localizations.localeOf(context).languageCode == 'it' ? 'it' : 'en';
  final title = AppLocalizations.of(context).embedProbeTitle;
  final leaf = s.caPem != null ? await pinnedLeaf(c.base, s.caPem!) : null;
  if (!context.mounted) return;
  await Navigator.of(context).push(
    MaterialPageRoute<void>(
      builder: (_) => EmbedScreen(
        base: c.base,
        leaf: leaf,
        title: title,
        params: EmbedParams(
          token: token,
          embed: EmbedKind.probe,
          bridge: newEmbedNonce(),
          theme: dark ? 'dark' : 'light',
          lang: lang,
        ),
      ),
    ),
  );
}

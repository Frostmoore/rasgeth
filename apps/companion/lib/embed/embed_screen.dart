// A screen for one embed (G42.0): the app's own bar (back, the name the page gives, its kind and
// weight, the save state, «Reload» and, where there is one, «Open in the browser») over an
// `EmbedView`. It shows the web view's test page (Settings of the server › «Web view test») and,
// since G42.2, an agent's port (`embed=port`: a site the agent serves in its computer, from a
// «shown in the Canvas» line of the chat). The Canvas uses it from G42.6.
import 'dart:typed_data';

import 'package:flutter/material.dart';

import '../api/web_settings.dart';
import '../app_state.dart';
import '../l10n/app_localizations.dart';
import '../screens/first_start_screen.dart' show openExternal;
import '../theme/colors.dart';
import '../ui/icons.dart';
import 'embed_link.dart';
import 'embed_view.dart';

/// What every embed takes from the app: the server, the device's token and the certificate
/// checked against the local CA, the app's theme and language.
class EmbedContext {
  const EmbedContext({
    required this.base,
    required this.token,
    required this.theme,
    required this.lang,
    this.accent,
    this.leaf,
  });

  final Uri base;
  final String token;
  final String theme;
  final String lang;

  /// The chosen accent's name (3.10.4); null: Rasgeth's red.
  final String? accent;
  final Uint8List? leaf;
}

/// The app's [EmbedContext] now, or null when it is not connected.
Future<EmbedContext?> embedContextOf(BuildContext context) async {
  final app = AppScope.read(context);
  final c = app.client;
  final s = app.server;
  final token = c?.token;
  if (c == null || s == null || token == null) return null;
  final dark = Theme.of(context).brightness == Brightness.dark;
  final lang = Localizations.localeOf(context).languageCode == 'it' ? 'it' : 'en';
  final leaf = s.caPem != null ? await pinnedLeaf(c.base, s.caPem!) : null;
  return EmbedContext(
    base: c.base,
    token: token,
    theme: dark ? 'dark' : 'light',
    lang: lang,
    accent: app.accent == RgAccent.red ? null : app.accent.name,
    leaf: leaf,
  );
}

class EmbedScreen extends StatefulWidget {
  const EmbedScreen({
    super.key,
    required this.base,
    required this.params,
    this.leaf,
    required this.title,
    this.subtitle,
    this.outside,
  });

  final Uri base;
  final EmbedParams params;
  final Uint8List? leaf;
  final String title;

  /// A line under the name before the page says more (an agent's name for its port).
  final String? subtitle;

  /// «Open in the browser»: the address to open outside the app (a signed link), when there is one.
  final Future<Uri> Function()? outside;

  @override
  State<EmbedScreen> createState() => _EmbedScreenState();
}

class _EmbedScreenState extends State<EmbedScreen> {
  final _view = GlobalKey<EmbedViewState>();
  late String _title = widget.title;
  late final Uri _url = embedUrl(widget.base, widget.params);
  String? _meta;
  String? _save;

  Future<void> _openOutside() async {
    final l = AppLocalizations.of(context);
    try {
      await openExternal(await widget.outside!());
    } on Object catch (e) {
      if (mounted) {
        ScaffoldMessenger.maybeOf(context)
            ?.showSnackBar(SnackBar(content: Text(l.errGeneric('$e'))));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = RgColors.of(context);
    final l = AppLocalizations.of(context);
    final sub = _meta ?? widget.subtitle;
    final meta = [if (sub != null && sub.isNotEmpty) sub, ?_save].join(' · ');
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
                          Text(
                            meta,
                            key: const Key('embed-meta'),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(color: c.dim, fontSize: 12),
                          ),
                      ],
                    ),
                  ),
                  IconButton(
                    key: const Key('embed-reload'),
                    tooltip: l.cvCanvasReload,
                    onPressed: () => _view.currentState?.reload(),
                    icon: RgIcon(RgIcons.refresh, size: 18, color: c.dim),
                  ),
                  if (widget.outside != null)
                    IconButton(
                      key: const Key('embed-outside'),
                      tooltip: l.embedOpenInBrowser,
                      onPressed: _openOutside,
                      icon: RgIcon(RgIcons.external, size: 18, color: c.dim),
                    ),
                  const SizedBox(width: 4),
                ],
              ),
            ),
            Expanded(
              child: EmbedView(
                key: _view,
                url: _url,
                nonce: widget.params.bridge,
                leaf: widget.leaf,
                onClose: () => Navigator.of(context).maybePop(),
                // A port's name is the agent's own words for it (the page only knows its number).
                onTitle: widget.params.embed == EmbedKind.port
                    ? null
                    : (t) => setState(() {
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

/// Opens an embed for the server in use; [params] makes its parameters from the app's.
Future<void> openEmbed(
  BuildContext context, {
  required String title,
  String? subtitle,
  required EmbedParams Function(EmbedContext e, String nonce) params,
  Future<Uri> Function()? outside,
}) async {
  final e = await embedContextOf(context);
  if (e == null || !context.mounted) return;
  await Navigator.of(context).push(
    MaterialPageRoute<void>(
      builder: (_) => EmbedScreen(
        base: e.base,
        leaf: e.leaf,
        title: title,
        subtitle: subtitle,
        params: params(e, newEmbedNonce()),
        outside: outside,
      ),
    ),
  );
}

/// Opens the web view's test page (`#embed=probe`) for the server in use.
Future<void> openEmbedProbe(BuildContext context) => openEmbed(
  context,
  title: AppLocalizations.of(context).embedProbeTitle,
  params: (e, nonce) => EmbedParams(
    token: e.token,
    embed: EmbedKind.probe,
    bridge: nonce,
    theme: e.theme,
    accent: e.accent,
    lang: e.lang,
  ),
);

/// An agent's port in the page (`embed=port`, G42.2): the site it serves in its computer, as the
/// page's Canvas shows it, with «Open in the browser» on the port's signed link.
Future<void> openPortPreview(
  BuildContext context, {
  required String agentId,
  required int port,
  String? path,
  String? title,
  String? sessionId,
}) {
  final app = AppScope.read(context);
  final l = AppLocalizations.of(context);
  final portName = l.cvEmbedPort('$port');
  final agent = app.agents.where((a) => a.id == agentId).firstOrNull?.name;
  final name = title == null || title.isEmpty ? portName : title;
  return openEmbed(
    context,
    title: name,
    subtitle: [?agent, if (name != portName) portName].join(' · '),
    params: (e, nonce) => EmbedParams(
      token: e.token,
      embed: EmbedKind.port,
      bridge: nonce,
      theme: e.theme,
      accent: e.accent,
      lang: e.lang,
      agent: agentId,
      port: port,
      path: path,
      session: sessionId,
    ),
    outside: () async {
      final c = app.client ?? (throw StateError('Not connected'));
      return c.base.resolve(await c.portLink(agentId, port, path: path));
    },
  );
}

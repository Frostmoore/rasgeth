// «All settings»: the page's Settings in a WebView over the whole screen (Android, iOS, macOS),
// signed in with the device's token in the fragment. The WebView trusts what the system trusts;
// a certificate the system does not know goes on only when it is the very one the app checked
// against RedGiant's local CA ([sslProceed]). Links elsewhere open outside the app.
import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

import '../api/web_settings.dart';
import '../l10n/app_localizations.dart';
import '../theme/colors.dart';
import '../ui/icons.dart';
import 'first_start_screen.dart' show openExternal;

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
  late final WebViewController _web;
  int _progress = 0;
  String? _error;

  @override
  void initState() {
    super.initState();
    _web = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onProgress: (p) {
            if (mounted) setState(() => _progress = p);
          },
          onNavigationRequest: (r) {
            final u = Uri.tryParse(r.url);
            if (u == null || u.scheme == 'about' || u.scheme == 'data' || u.scheme == 'blob') {
              return NavigationDecision.navigate;
            }
            if (sameOrigin(u, widget.base)) return NavigationDecision.navigate;
            unawaited(openExternal(u));
            return NavigationDecision.prevent;
          },
          onSslAuthError: (e) {
            if (sslProceed(e.certificate?.data, widget.leaf)) {
              unawaited(e.proceed());
            } else {
              unawaited(e.cancel());
              if (mounted) setState(() => _error = 'certificate');
            }
          },
          onWebResourceError: (e) {
            if (e.isForMainFrame == true && mounted) setState(() => _error = e.description);
          },
        ),
      )
      ..loadRequest(fullSettingsUrl(widget.base, token: widget.token));
  }

  @override
  Widget build(BuildContext context) {
    final c = RgColors.of(context);
    final l = AppLocalizations.of(context);
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Row(
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
                  tooltip: l.refresh,
                  onPressed: () {
                    setState(() => _error = null);
                    unawaited(_web.reload());
                  },
                  icon: RgIcon(RgIcons.refresh, size: 18, color: c.dim),
                ),
              ],
            ),
            if (_progress < 100) LinearProgressIndicator(value: _progress / 100, minHeight: 2),
            if (_error != null)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                color: c.err.withValues(alpha: .08),
                child: Text(
                  _error == 'certificate' ? l.errCertificate : l.errGeneric(_error!),
                  style: TextStyle(color: c.err),
                ),
              ),
            Expanded(child: WebViewWidget(controller: _web)),
          ],
        ),
      ),
    );
  }
}

// The Canvas (G40.7): a file the agent showed or handed over. Images, SVG, PDF and Markdown are
// shown natively. An artifact (3.8.7: `artefatti/*.html`, or an HTML file with its header, as the
// server says from `POST /api/canvas/link`) runs as in the page: the server's signed
// `/preview/<token>/` in the frame of `ui/artifact_frame_view.dart` (no network, RedGiant's
// libraries, its errors for the agent, «send to chat» with the click rule, the bridge); on Linux,
// «Open in the page» above its source. Another HTML file, where there is a WebView, goes into an
// isolated document of ours whose Content-Security-Policy allows no network at all, holding it in
// an iframe with `sandbox="allow-scripts allow-forms"` through `srcdoc`; the WebView navigates
// nowhere after it.
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdfx/pdfx.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:webview_flutter/webview_flutter.dart';

import '../api/client.dart';
import '../api/widgets.dart';
import '../app_state.dart';
import '../l10n/app_localizations.dart';
import '../theme/colors.dart';
import '../ui/artifact_frame_view.dart';
import '../ui/icons.dart';
import '../ui/markdown.dart';

enum CanvasKind { image, svg, pdf, markdown, html, text }

CanvasKind canvasKindOf(String path) => switch (path.split('.').last.toLowerCase()) {
  'png' || 'jpg' || 'jpeg' || 'gif' || 'webp' || 'bmp' => CanvasKind.image,
  'svg' => CanvasKind.svg,
  'pdf' => CanvasKind.pdf,
  'md' || 'markdown' => CanvasKind.markdown,
  'html' || 'htm' => CanvasKind.html,
  _ => CanvasKind.text,
};

/// No network, no frames of its own, no workers, no forms sent anywhere (artifact-engine.ts).
const String kArtifactCsp =
    "default-src 'none'; script-src 'unsafe-inline' 'unsafe-eval'; style-src 'unsafe-inline'; "
    "img-src data: blob:; font-src data:; media-src data: blob:; connect-src 'none'; "
    "frame-src 'none'; child-src 'none'; worker-src 'none'; object-src 'none'; "
    "manifest-src 'none'; form-action 'none'; base-uri 'none'";

String _attr(String s) => s
    .replaceAll('&', '&amp;')
    .replaceAll('"', '&quot;')
    .replaceAll('<', '&lt;')
    .replaceAll('>', '&gt;');

/// The document the WebView loads: our policy first, the artifact only inside the sandbox.
String artifactDocument(String html) =>
    '<!doctype html><html><head><meta charset="utf-8">'
    '<meta http-equiv="Content-Security-Policy" content="${_attr(kArtifactCsp)}">'
    '<meta name="viewport" content="width=device-width, initial-scale=1">'
    '<meta name="referrer" content="no-referrer">'
    '<style>html,body{margin:0;height:100%;background:#fff}iframe{border:0;width:100%;height:100%}</style>'
    '</head><body><iframe sandbox="$kArtifactSandbox" referrerpolicy="no-referrer" '
    'srcdoc="${_attr(html)}"></iframe></body></html>';

bool get webViewHere => !kIsWeb && (Platform.isAndroid || Platform.isIOS || Platform.isMacOS);

bool get pdfHere =>
    !kIsWeb && (Platform.isAndroid || Platform.isIOS || Platform.isMacOS || Platform.isWindows);

Future<void> openCanvas(
  BuildContext context, {
  required String scope,
  required String path,
  String? title,
  String? sessionId,
}) => Navigator.of(context).push(
  MaterialPageRoute<void>(
    builder: (_) => CanvasScreen(scope: scope, path: path, title: title, sessionId: sessionId),
  ),
);

class CanvasScreen extends StatefulWidget {
  const CanvasScreen({
    super.key,
    required this.scope,
    required this.path,
    this.title,
    this.sessionId,
  });

  final String scope;
  final String path;
  final String? title;

  /// The conversation it was opened from: where an artifact's «send to chat» goes.
  final String? sessionId;

  @override
  State<CanvasScreen> createState() => _CanvasScreenState();
}

class _CanvasScreenState extends State<CanvasScreen> {
  late Future<Widget> _body;

  @override
  void initState() {
    super.initState();
    _body = _load(AppScope.read(context));
  }

  Future<Widget> _load(AppController app) async {
    final c = app.client;
    if (c == null) throw const ApiException(0, 'Not connected');
    final kind = canvasKindOf(widget.path);
    switch (kind) {
      case CanvasKind.image:
        final b = await c.fileRaw(widget.scope, widget.path);
        return InteractiveViewer(
          maxScale: 6,
          child: Center(child: Image.memory(b, key: const Key('canvas-image'))),
        );
      case CanvasKind.svg:
        // flutter_svg draws, never runs scripts nor fetches anything.
        final b = await c.fileRaw(widget.scope, widget.path);
        return InteractiveViewer(
          maxScale: 6,
          child: Center(child: SvgPicture.memory(b, key: const Key('canvas-svg'))),
        );
      case CanvasKind.pdf:
        final b = await c.fileRaw(widget.scope, widget.path);
        if (pdfHere) return _Pdf(bytes: b);
        return _OpenOutside(bytes: b, name: widget.path.split('/').last);
      case CanvasKind.markdown:
        final f = await c.fileContent(widget.scope, widget.path);
        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: SafeMarkdown(f.text ?? '', key: const Key('canvas-markdown')),
        );
      case CanvasKind.html:
        // An artifact runs as in the page (3.8.7); the server says which HTML files are.
        ({String url, bool artifact})? link;
        try {
          link = await c.canvasLink(widget.scope, widget.path);
        } on ApiException {
          link = null;
        }
        if (link != null && link.artifact) {
          if (frameSupportOf(app) != FrameSupport.none) {
            return ArtifactFrame(
              key: const Key('canvas-artifact'),
              src: link.url,
              title: widget.title?.isNotEmpty == true ? widget.title! : widget.path.split('/').last,
              ref: {'kind': 'file', 'scope': widget.scope, 'path': widget.path},
              sessionId: widget.sessionId,
            );
          }
          final f = await c.fileContent(widget.scope, widget.path);
          return ArtifactInPage(previewPath: link.url, source: f.text ?? '');
        }
        final f = await c.fileContent(widget.scope, widget.path);
        final html = f.text ?? '';
        if (webViewHere) return ArtifactView(html: html);
        return _Source(text: html, note: true);
      case CanvasKind.text:
        final f = await c.fileContent(widget.scope, widget.path);
        return _Source(text: f.text ?? '');
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final c = RgColors.of(context);
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          tooltip: l.back,
          onPressed: () => Navigator.maybePop(context),
          icon: RgIcon(RgIcons.arrowLeft, color: c.text),
        ),
        title: Text(
          widget.title?.isNotEmpty == true ? widget.title! : widget.path.split('/').last,
          overflow: TextOverflow.ellipsis,
        ),
      ),
      body: FutureBuilder<Widget>(
        future: _body,
        builder: (context, s) {
          if (s.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(l.canvasFailed('${s.error}'), style: TextStyle(color: c.err)),
              ),
            );
          }
          if (!s.hasData) return const Center(child: CircularProgressIndicator());
          return s.data!;
        },
      ),
    );
  }
}

/// An artifact in a WebView that loads only our document and goes nowhere after it.
class ArtifactView extends StatefulWidget {
  const ArtifactView({super.key, required this.html});

  final String html;

  @override
  State<ArtifactView> createState() => _ArtifactViewState();
}

class _ArtifactViewState extends State<ArtifactView> {
  late final WebViewController _web;

  @override
  void initState() {
    super.initState();
    var loaded = false;
    _web = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onNavigationRequest: (r) {
            // The first load is our document; the iframe's own srcdoc is about:srcdoc.
            if (!loaded || r.url == 'about:srcdoc' || r.url == 'about:blank') {
              loaded = true;
              return NavigationDecision.navigate;
            }
            return NavigationDecision.prevent;
          },
        ),
      )
      ..loadHtmlString(artifactDocument(widget.html));
  }

  @override
  Widget build(BuildContext context) => WebViewWidget(controller: _web);
}

class _Pdf extends StatefulWidget {
  const _Pdf({required this.bytes});

  final Uint8List bytes;

  @override
  State<_Pdf> createState() => _PdfState();
}

class _PdfState extends State<_Pdf> {
  late final PdfControllerPinch _pdf = PdfControllerPinch(
    document: PdfDocument.openData(widget.bytes),
  );

  @override
  void dispose() {
    _pdf.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => PdfViewPinch(controller: _pdf);
}

/// Linux (no PDF renderer of the system): the file in the system's own viewer.
class _OpenOutside extends StatelessWidget {
  const _OpenOutside({required this.bytes, required this.name});

  final Uint8List bytes;
  final String name;

  Future<void> _open() async {
    final dir = await getTemporaryDirectory();
    final f = File('${dir.path}/rgcompanion-$name');
    await f.writeAsBytes(bytes);
    await launchUrl(Uri.file(f.path));
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return Center(
      child: FilledButton.icon(
        onPressed: _open,
        icon: const RgIcon(RgIcons.file, color: Colors.white),
        label: Text(l.openWithSystem),
      ),
    );
  }
}

class _Source extends StatelessWidget {
  const _Source({required this.text, this.note = false});

  final String text;
  final bool note;

  @override
  Widget build(BuildContext context) {
    final c = RgColors.of(context);
    final l = AppLocalizations.of(context);
    return ListView(
      padding: const EdgeInsets.all(14),
      children: [
        if (note)
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Text(l.artifactSourceOnly, style: TextStyle(color: c.dim, fontSize: 13)),
          ),
        SelectableText(
          text.length > 200000 ? '${text.substring(0, 200000)}…' : text,
          key: const Key('canvas-text'),
          style: TextStyle(fontFamily: 'monospace', fontSize: 12.5, color: c.text),
        ),
      ],
    );
  }
}

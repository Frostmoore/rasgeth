// G42.10: a citation of the person's own documents (`#kb:<piece>`, from `search_knowledge`) opens
// where it points, as the page's `openCitation` (state.ts): a file in the Canvas, a web page in the
// system's browser after the person's yes, a conversation, or a mail's text in a window (it lives
// in the mailbox, not in a file here). `GET /api/knowledge/open/:chunk`.
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../app_state.dart';
import '../l10n/app_localizations.dart';
import '../screens/canvas_screen.dart' show openCanvas;
import '../screens/conversation_screen.dart' show ConversationScreen;
import '../theme/colors.dart';
import '../ui/dialogs.dart';
import 'api/knowledge_api.dart';
import 'knowledge_kit.dart';

/// The piece a `#kb:` link points at, or null when [href] is not one.
String? kbChunkOf(String? href) {
  final m = RegExp(r'^#kb:(\d+)$').firstMatch(href ?? '');
  return m?.group(1);
}

Future<void> openKbCitation(BuildContext context, String chunkId) async {
  final app = AppScope.read(context);
  final l = AppLocalizations.of(context);
  final messenger = ScaffoldMessenger.of(context);
  final c = app.client;
  if (c == null) return;
  final KbOpen r;
  try {
    r = await c.knowledgeOpen(chunkId);
  } on Exception catch (e) {
    messenger.showSnackBar(SnackBar(content: Text(kbWhy(l, e))));
    return;
  }
  if (!context.mounted) return;
  if (r.url != null) {
    final url = Uri.tryParse(r.url!);
    if (url == null || !(url.scheme == 'https' || url.scheme == 'http')) return;
    final ok = await askConfirm(context, title: l.linkOpenTitle, body: r.url!, yes: l.linkOpen);
    if (ok) await launchUrl(url, mode: LaunchMode.externalApplication);
    return;
  }
  if (r.sessionId != null) {
    final agent = app.agents.where((a) => a.id == r.agentId).firstOrNull;
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => ConversationScreen(sessionId: r.sessionId!, agent: agent),
      ),
    );
    return;
  }
  if (r.text != null) {
    final col = RgColors.of(context);
    await kbWindow<void>(
      context,
      key: const Key('kb-cite-note'),
      wide: true,
      title: r.title,
      body: (ctx, close) => SelectableText(
        r.text!,
        style: TextStyle(color: col.text, fontFamily: 'monospace', fontSize: 13, height: 1.45),
      ),
    );
    return;
  }
  if (r.scope != null && r.path != null) {
    await openCanvas(context, scope: r.scope!, path: r.path!, title: r.title);
  }
}

/// The tool's English place words said in the person's language (the page's `linkCitations`):
/// «manuale.pdf, p. 3» → «manuale.pdf, pag. 3».
String kbCiteTitle(AppLocalizations l, String text) {
  final t = text
      .trim()
      .replaceAllMapped(RegExp(r', p\. (\d+)$'), (m) => ', ${l.knKbPage(m[1]!)}')
      .replaceAllMapped(RegExp(r', lines (\d+)-(\d+)$'), (m) => ', ${l.knKbLines(m[1]!, m[2]!)}')
      .replaceAllMapped(RegExp(r', line (\d+)$'), (m) => ', ${l.knKbLine(m[1]!)}');
  return t.isEmpty ? l.knKbCiteFallback : t;
}

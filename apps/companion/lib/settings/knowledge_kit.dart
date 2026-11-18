// G42.10: the pieces Settings › Knowledge and Shared memory share, drawn as the page's settings
// kit: the server's reasons in plain words, who a collection is for, where a piece is, a box, a row
// with our switch, a real bar with its words (amounts, speed, time left), a download as the page's
// `JobView`, and a window over the page on a computer that is a sheet from below on a phone.
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../api/client.dart';
import '../api/code.dart' show JobStepView;
import '../app_state.dart';
import '../l10n/app_localizations.dart';
import '../screens/new_agent_screen.dart' show RgSwitch;
import '../theme/colors.dart';
import '../ui/chat/file_download.dart' show byteWords;
import '../ui/dialogs.dart';
import '../ui/icons.dart';
import 'api/knowledge_api.dart';

/// A count as the page writes it (`toLocaleString`): «1.234» in Italian, «1,234» in English.
String kbNum(AppLocalizations l, num n) => NumberFormat.decimalPattern(l.localeName).format(n);

/// The knowledge server's reason in plain words (`kbErr_<code>`), or its message.
String kbWhy(AppLocalizations l, Object e) {
  if (e is! ApiException) return '$e';
  return switch (e.code) {
    'not_found' => l.knKbErr_not_found,
    'bad_source' => l.knKbErr_bad_source,
    'bad_choice' => l.knKbErr_bad_choice,
    'no_vector' => l.knKbErr_no_vector,
    'embedding_failed' => l.knKbErr_embedding_failed,
    _ => e.message,
  };
}

/// The shared memory's reason in plain words (`err_memory_<code>`), or its message.
String memWhy(AppLocalizations l, Object e) {
  if (e is! ApiException) return '$e';
  return switch (e.code) {
    'memory_empty' => l.knErr_memory_empty,
    'memory_long' => l.knErr_memory_long,
    'memory_secret' => l.knErr_memory_secret,
    'memory_full' => l.knErr_memory_full,
    'memory_gone' => l.knErr_memory_gone,
    'memory_same' => l.knErr_memory_same,
    'memory_moved' => l.knErr_memory_moved,
    'memory_undone' => l.knErr_memory_undone,
    'memory_forgotten' => l.knErr_memory_forgotten,
    _ => e.message,
  };
}

/// Who a collection is for, in words (the page's `scopeWords`).
String kbScopeWords(AppLocalizations l, AppController app, KbScope s) => switch (s.kind) {
  'agent' => l.knKbForAgent(app.agents.where((a) => a.id == s.id).firstOrNull?.name ?? s.id ?? ''),
  'project' => l.knKbForProject(
    app.projects.where((p) => p.id == s.id).firstOrNull?.name ?? s.id ?? '',
  ),
  _ => l.knKbForAll,
};

/// Where a piece is, in words: its page or lines (the page's `placeWords`).
String kbPlaceWords(AppLocalizations l, KbCitation c) {
  if (c.page != null) return l.knKbPage('${c.page}');
  if (c.lineStart != null) {
    return c.lineEnd != null && c.lineEnd != c.lineStart
        ? l.knKbLines('${c.lineStart}', '${c.lineEnd}')
        : l.knKbLine('${c.lineStart}');
  }
  if (c.source == 'mail') return l.knKbMail;
  if (c.source == 'chats') return l.knKbChat;
  return '';
}

/// The time left as the page says it (`timeLeft`).
String kbTimeLeft(AppLocalizations l, int seconds) {
  if (seconds < 60) return l.knUiLessThanMinute;
  final min = (seconds / 60).round();
  if (min < 60) return l.knUiAboutMinutes('$min');
  return l.knUiAboutHours('${min ~/ 60}', '${min % 60}');
}

/// A box of the page's settings (`Box`): the panel's colour, its line, round corners.
class KbBox extends StatelessWidget {
  const KbBox({super.key, required this.children, this.tone});

  final List<Widget> children;

  /// A colour for the border (a box that warns).
  final Color? tone;

  @override
  Widget build(BuildContext context) {
    final c = RgColors.of(context);
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
      decoration: BoxDecoration(
        color: tone == null ? c.panel : tone!.withValues(alpha: .06),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: tone?.withValues(alpha: .4) ?? c.line),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: children),
    );
  }
}

/// A title, its help and our switch on the right (the page's `SwitchRow`): the whole row taps.
class KbSwitchRow extends StatelessWidget {
  const KbSwitchRow({
    super.key,
    required this.title,
    this.help,
    required this.on,
    required this.onChanged,
  });

  final String title;
  final String? help;
  final bool on;
  final ValueChanged<bool>? onChanged;

  @override
  Widget build(BuildContext context) {
    final c = RgColors.of(context);
    return Semantics(
      toggled: on,
      button: true,
      label: title,
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: onChanged == null ? null : () => onChanged!(!on),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(fontWeight: FontWeight.w700, color: c.text, fontSize: 14.5),
                    ),
                    if (help != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 2),
                        child: Text(
                          help!,
                          style: TextStyle(color: c.dim, fontSize: 12.5, height: 1.35),
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              RgSwitch(on: on),
            ],
          ),
        ),
      ),
    );
  }
}

/// A real bar with its words (the page's `Progress`): «40% · 120 di 300 · 2.5/s · circa 3 min».
class KbBar extends StatelessWidget {
  const KbBar({
    super.key,
    required this.done,
    this.total,
    this.rate,
    this.secondsLeft,
    this.bytes = false,
  });

  final int done;
  final int? total;

  /// Units per second.
  final double? rate;
  final int? secondsLeft;
  final bool bytes;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final c = RgColors.of(context);
    final lang = Localizations.localeOf(context).languageCode;
    String amount(num n) => bytes ? byteWords(n.round(), lang) : '${n.round()}';
    final t = total;
    final pct = t != null && t > 0 ? ((done / t) * 100).round().clamp(0, 100) : null;
    final words = [
      t != null ? l.knUiOf(amount(done), amount(t)) : amount(done),
      if (rate != null) bytes ? '${amount(rate!)}/s' : '${rate!.toStringAsFixed(1)}/s',
      if (secondsLeft != null && t != null && done < t) kbTimeLeft(l, secondsLeft!),
    ].join(' · ');
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Semantics(
            label: words,
            value: pct == null ? null : '$pct%',
            child: ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                key: const Key('kb-bar'),
                value: pct == null ? null : pct / 100,
                minHeight: 7,
                color: c.accent,
                backgroundColor: c.line,
              ),
            ),
          ),
          const SizedBox(height: 5),
          Text(
            '${pct == null ? '' : '$pct% · '}$words',
            key: const Key('kb-bar-words'),
            style: TextStyle(color: c.dim, fontSize: 12.5),
          ),
        ],
      ),
    );
  }
}

/// A download of the knowledge as the page's `JobView`: its title, its steps, the bar of the one
/// running, its end or why it failed.
class KbJobView extends StatelessWidget {
  const KbJobView({super.key, required this.job});

  final KbJob job;

  String _title(AppLocalizations l) => switch (job.kind) {
    'download_knowledge_model' => l.knJob_download_knowledge_model(
      job.vars['model'] ?? '',
      job.vars['size'] ?? '',
    ),
    'download_ocr' => l.knJob_download_ocr(job.vars['languages'] ?? '', job.vars['size'] ?? ''),
    'download_pgvector' => l.knJob_download_pgvector,
    _ => job.kind,
  };

  String _step(AppLocalizations l, JobStepView s) => switch (s.id) {
    'tool_download' => l.knJob_step_tool_download,
    'model_download' => l.knJob_step_model_download,
    'ocr_program' => l.knJob_step_ocr_program,
    'ocr_languages' => l.knJob_step_ocr_languages,
    _ => s.id,
  };

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final c = RgColors.of(context);
    final failed = job.state == 'failed';
    return Container(
      key: Key('kb-job-${job.id}'),
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: c.panel2,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: failed ? c.err.withValues(alpha: .4) : c.line),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            _title(l),
            style: TextStyle(fontWeight: FontWeight.w700, color: c.text),
          ),
          for (final s in job.steps)
            Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    width: 18,
                    height: 18,
                    child: Center(
                      child: switch (s.state) {
                        'running' => RgSpinner(size: 14, color: c.accent),
                        'failed' => RgIcon(RgIcons.x, size: 14, color: c.err),
                        'done' => RgIcon(RgIcons.check, size: 14, color: c.ok),
                        _ => Container(
                          width: 9,
                          height: 9,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(color: c.dim, width: 1.5),
                          ),
                        ),
                      },
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          _step(l, s),
                          style: TextStyle(color: s.state == 'waiting' ? c.dim : c.text),
                        ),
                        if (s.state == 'running' && s.done != null)
                          KbBar(
                            done: s.done!,
                            total: s.total,
                            rate: s.rate,
                            secondsLeft: s.secondsLeft,
                            bytes: true,
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          if (failed)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(switch (job.errorCode) {
                'checksum' => l.knJob_error_checksum,
                'pgvector_unavailable' => l.knJob_error_pgvector_unavailable,
                _ => job.errorMessage ?? '',
              }, style: TextStyle(color: c.err, fontSize: 13)),
            ),
        ],
      ),
    );
  }
}

/// A plain line of the page (`kb-p`, `kb-dim`), or an error (`kb-error`).
class KbLine extends StatelessWidget {
  const KbLine(this.text, {super.key, this.dim = false, this.error = false});

  final String text;
  final bool dim;
  final bool error;

  @override
  Widget build(BuildContext context) {
    final c = RgColors.of(context);
    if (error) {
      return Container(
        margin: const EdgeInsets.symmetric(vertical: 6),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: c.err.withValues(alpha: .08),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: c.err.withValues(alpha: .35)),
        ),
        child: Semantics(
          liveRegion: true,
          child: Text(text, style: TextStyle(color: c.text, fontSize: 13.5)),
        ),
      );
    }
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Text(
        text,
        style: TextStyle(color: dim ? c.dim : c.text, fontSize: dim ? 13 : 14, height: 1.4),
      ),
    );
  }
}

/// A window over the page on a computer, a sheet from below on a phone (the page's Modal):
/// a title, maybe a line under it, the body, and the buttons at the bottom.
Future<T?> kbWindow<T>(
  BuildContext context, {
  required String title,
  String? sub,
  required Key key,
  required Widget Function(BuildContext ctx, void Function([T?]) close) body,
  bool wide = false,
}) {
  final c = RgColors.of(context);
  Widget page(BuildContext ctx) {
    void close([T? v]) => Navigator.of(ctx).pop(v);
    return Padding(
      padding: EdgeInsets.fromLTRB(20, 18, 20, 20 + MediaQuery.viewInsetsOf(ctx).bottom),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: c.text),
                    ),
                    if (sub != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 2),
                        child: Text(sub, style: TextStyle(color: c.dim, fontSize: 13)),
                      ),
                  ],
                ),
              ),
              IconButton(
                key: const Key('kb-window-close'),
                tooltip: AppLocalizations.of(ctx).close,
                onPressed: close,
                icon: RgIcon(RgIcons.x, size: 18, color: c.dim),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Flexible(child: SingleChildScrollView(child: body(ctx, close))),
        ],
      ),
    );
  }

  final size = MediaQuery.sizeOf(context);
  if (size.width >= 760) {
    return showRgWindow<T>(
      context: context,
      builder: (ctx) => Dialog(
        key: key,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: wide ? 680 : 480, maxHeight: size.height * .88),
          child: page(ctx),
        ),
      ),
    );
  }
  return showModalBottomSheet<T>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (ctx) => SafeArea(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxHeight: MediaQuery.sizeOf(ctx).height * .9),
        child: KeyedSubtree(key: key, child: page(ctx)),
      ),
    ),
  );
}

/// The buttons at the bottom of a window (the page's `Acts`): on the right, wrapping on a phone.
class KbActs extends StatelessWidget {
  const KbActs({super.key, required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(top: 14),
    child: Wrap(alignment: WrapAlignment.end, spacing: 10, runSpacing: 8, children: children),
  );
}

/// A drawn tile to choose (the page's `Tile`): icon, title, words, a badge and its state.
class KbTile extends StatelessWidget {
  const KbTile({
    super.key,
    required this.icon,
    required this.title,
    this.text,
    this.badge,
    this.state,
    required this.on,
    required this.onTap,
  });

  final RgIcons icon;
  final String title;
  final String? text;
  final String? badge;
  final String? state;
  final bool on;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final c = RgColors.of(context);
    return Semantics(
      button: true,
      selected: on,
      child: Material(
        color: on ? c.accentSoft : c.panel,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: BorderSide(color: on ? c.accent : c.line, width: on ? 1.5 : 1),
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    RgIcon(icon, size: 22, color: on ? c.accent : c.dim),
                    const Spacer(),
                    if (on) RgIcon(RgIcons.check, size: 16, color: c.accent),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  title,
                  style: TextStyle(fontWeight: FontWeight.w800, color: c.text, fontSize: 14),
                ),
                if (badge != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                      decoration: BoxDecoration(
                        color: c.accent.withValues(alpha: .14),
                        borderRadius: BorderRadius.circular(99),
                      ),
                      child: Text(
                        badge!,
                        style: TextStyle(
                          color: c.accent,
                          fontSize: 11.5,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                if (text != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(text!, style: TextStyle(color: c.dim, fontSize: 12.5, height: 1.3)),
                  ),
                if (state != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Text(
                      state!,
                      style: TextStyle(color: c.text, fontSize: 12, fontWeight: FontWeight.w600),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Tiles in a grid: two on a phone, three or four where there is room (the page's `Tiles`).
class KbTiles extends StatelessWidget {
  const KbTiles({super.key, required this.children, this.minWidth = 170});

  final List<Widget> children;
  final double minWidth;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, box) {
      final n = (box.maxWidth / minWidth).floor().clamp(1, 4);
      final w = (box.maxWidth - (n - 1) * 10) / n;
      return Wrap(
        spacing: 10,
        runSpacing: 10,
        children: [for (final t in children) SizedBox(width: w, child: t)],
      );
    },
  );
}

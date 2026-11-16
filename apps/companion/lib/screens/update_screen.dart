// The update, followed (the person, from the phone: «l'aggiornamento "comprensibile" ancora non
// è comprensibile … non c'è una barra di caricamento. Va fatto bene»). The whole screen on a
// phone, a window on a computer; opened by «Update» and again by itself when the app finds an
// update running. The steps numbered as the page says them (signature, images, system files,
// install, restart, check), the running one lit and the done ones ticked, how long the whole
// still needs; a real bar with the bytes, the speed and the time left from the server, or one
// that moves with the time gone by when the server does not say (before 3.8.1); RedGiant's
// restart with the tries the app makes to reach it, and the app reconnecting by itself as the
// new version; at the end «Updated to x.y.z» with what is new, or why it stopped and what to do.
import 'dart:async';

import 'package:flutter/material.dart';

import '../api/settings_types.dart';
import '../api/update_follower.dart';
import '../api/update_run.dart';
import '../app_state.dart';
import '../l10n/app_localizations.dart';
import '../theme/colors.dart';
import '../ui/icons.dart';
import 'first_start_screen.dart' show openExternal;
import 'server_settings_screen.dart' show progressText;

const _releases = 'https://github.com/Frostmoore/redgiant2/releases/tag/v';

/// The screens on view, and one asked for that has not shown yet.
int _shown = 0;
bool _asked = false;

/// The update's screen is on view (or about to be).
bool get updateScreenOpen => _shown > 0 || _asked;

/// Opens the screen of the update the app follows: the whole screen on a phone, a window on a
/// computer (or any screen wider than a phone's).
Future<void> openUpdateScreen(BuildContext context) async {
  if (updateScreenOpen) return;
  _asked = true;
  try {
    final wide = MediaQuery.sizeOf(context).width >= 720;
    if (wide) {
      await showDialog<void>(
        context: context,
        barrierDismissible: false,
        builder: (_) => Dialog(
          key: const Key('update-window'),
          insetPadding: const EdgeInsets.all(24),
          clipBehavior: Clip.antiAlias,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 620, maxHeight: 780),
            child: const UpdateScreen(window: true),
          ),
        ),
      );
    } else {
      await Navigator.of(
        context,
      ).push(MaterialPageRoute<void>(fullscreenDialog: true, builder: (_) => const UpdateScreen()));
    }
  } finally {
    _asked = false;
  }
}

String _mb(double b) => '${(b / (1024 * 1024)).toStringAsFixed(b >= 100 * 1024 * 1024 ? 0 : 1)} MB';

/// «less than a minute», «4 min», «1 h 5 min».
String tookWords(AppLocalizations l, int seconds) {
  final r = roundMinutes(seconds);
  if (r == null) return l.upd2TookLess;
  final (h, m) = r;
  return h == 0 ? l.upd2TookMin('$m') : l.upd2TookHours('$h', '$m');
}

String _leftWords(AppLocalizations l, int seconds) =>
    seconds < 60 ? '${_by5(seconds)} s' : tookWords(l, seconds);

/// Seconds under a minute by fives, so the guess does not flicker.
int _by5(int s) => s <= 5 ? s : (s / 5).ceil() * 5;

String stepTitle(AppLocalizations l, String id) => switch (id) {
  'check' => l.upd2Step_check,
  'download' => l.upd2Step_download,
  'files' => l.upd2Step_files,
  'install' => l.upd2Step_install,
  'restart' => l.upd2Step_restart,
  'wait' => l.upd2Step_wait,
  'rollback' => l.upd2Step_rollback,
  'scan' => l.upd2Step_scan,
  'build' => l.upd2Step_build,
  'installer' => l.upd2Step_installer,
  _ => id,
};

String? stepText(AppLocalizations l, String id) => switch (id) {
  'check' => l.upd2StepText_check,
  'download' => l.upd2StepText_download,
  'files' => l.upd2StepText_files,
  'install' => l.upd2StepText_install,
  'restart' => l.upd2StepText_restart,
  'wait' => l.upd2StepText_wait,
  'rollback' => l.upd2StepText_rollback,
  'scan' => l.upd2StepText_scan,
  'build' => l.upd2StepText_build,
  'installer' => l.upd2StepText_installer,
  _ => null,
};

String whyTitle(AppLocalizations l, String why) => switch (why) {
  'download' => l.upd2Why_download,
  'files' => l.upd2Why_files,
  'not_up' => l.upd2Why_not_up,
  'no_images' => l.upd2Why_no_images,
  'breaking' => l.upd2Why_breaking,
  'unsigned' => l.upd2Why_unsigned,
  'unreachable' => l.upd2Why_unreachable,
  'gone' => l.upd2Why_gone,
  'start' => l.upd2Why_start,
  _ => l.upd2Why_other,
};

String whyText(AppLocalizations l, String why, String from) => switch (why) {
  'download' => l.upd2WhyText_download(from),
  'files' => l.upd2WhyText_files(from),
  'not_up' => l.upd2WhyText_not_up(from),
  'no_images' => l.upd2WhyText_no_images(from),
  'breaking' => l.upd2WhyText_breaking(from),
  'unsigned' => l.upd2WhyText_unsigned,
  'unreachable' => l.upd2WhyText_unreachable,
  'gone' => l.upd2WhyText_gone,
  'start' => l.upd2WhyText_start(from),
  _ => l.upd2WhyText_other(from),
};

class UpdateScreen extends StatefulWidget {
  const UpdateScreen({super.key, this.window = false});

  /// Shown as a window over the app (a computer), not as a screen of its own.
  final bool window;

  @override
  State<UpdateScreen> createState() => _UpdateScreenState();
}

class _UpdateScreenState extends State<UpdateScreen> {
  Timer? _clock;

  @override
  void initState() {
    super.initState();
    _shown++;
    _asked = false;
    // The time gone by moves every second: never a still line.
    _clock = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _shown--;
    _clock?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    final f = app.updateRun;
    final l = AppLocalizations.of(context);
    final c = RgColors.of(context);
    final body = f == null
        ? const SizedBox.shrink()
        : ListenableBuilder(
            listenable: f,
            builder: (context, _) => _Body(f: f, app: app),
          );
    final close = IconButton(
      key: const Key('update-close'),
      tooltip: f == null || f.finished ? l.upd2Close : l.upd2Hide,
      onPressed: () => Navigator.of(context).pop(),
      icon: RgIcon(RgIcons.x, color: c.text),
    );
    if (widget.window) {
      return Material(
        color: c.bg,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 8, 0),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      l.sectionUpdates,
                      style: TextStyle(color: c.dim, fontWeight: FontWeight.w700, fontSize: 13),
                    ),
                  ),
                  close,
                ],
              ),
            ),
            Flexible(child: body),
          ],
        ),
      );
    }
    return Scaffold(
      appBar: AppBar(leading: close, title: Text(l.sectionUpdates)),
      body: SafeArea(top: false, child: body),
    );
  }
}

class _Body extends StatelessWidget {
  const _Body({required this.f, required this.app});

  final UpdateFollower f;
  final AppController app;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final c = RgColors.of(context);
    final lang = Localizations.localeOf(context).languageCode;
    final steps = f.steps;
    final from = f.fromVersion ?? '';
    final to = f.to;
    final stage = f.stage;
    final current = steps.where((s) => s.mark == StepMark.now).firstOrNull?.id;

    final String title;
    final RgIcons icon;
    final Color tone;
    switch (stage) {
      case UpdateStage.done:
        title = l.upd2Done(f.doneVersion ?? to ?? '');
        icon = RgIcons.check;
        tone = c.ok;
      case UpdateStage.failed:
        title = whyTitle(l, f.why ?? 'other');
        icon = RgIcons.alert;
        tone = c.err;
      default:
        title = from.isNotEmpty && to != null ? l.upd2Title(from, to) : l.upd2TitleTo(to ?? '');
        icon = stage == UpdateStage.restarting ? RgIcons.refresh : RgIcons.download;
        tone = c.accent;
    }

    // The time: how long it still needs and in all, how long it has been running.
    final left = f.left;
    final elapsed = clock(f.elapsed);
    final time = <String>[
      if (stage == UpdateStage.starting) l.upd2Starting,
      if (!f.finished && stage != UpdateStage.starting)
        left != null
            ? '${l.upd2Left(_leftWords(l, left))} · ${l.upd2Total(tookWords(l, f.elapsed.inSeconds + left))}'
            : l.upd2LeftUnknown,
      if (!f.finished) l.upd2Elapsed(elapsed),
      if (!f.finished && f.totalBytes > 0 && (current == 'check' || current == 'download'))
        l.upd2ToDownload(_mb(f.totalBytes)),
    ];

    final children = <Widget>[
      // ---- where it is ----
      Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(color: tone.withValues(alpha: .12), shape: BoxShape.circle),
            alignment: Alignment.center,
            child: RgIcon(icon, size: 22, color: tone),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  key: const Key('update-title'),
                  style: const TextStyle(fontSize: 19, fontWeight: FontWeight.w700, height: 1.25),
                ),
                if (time.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    time.join(' · '),
                    key: const Key('update-time'),
                    style: TextStyle(color: c.dim, fontSize: 13.5),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
      const SizedBox(height: 18),
    ];

    if (!f.finished) children.add(_Live(f: f, current: current));

    if (stage == UpdateStage.done) children.addAll(_done(context, l, c, lang));
    if (stage == UpdateStage.failed) children.addAll(_failed(context, l, c, from));

    // ---- the steps ----
    if (!(stage == UpdateStage.failed && (f.why == 'start' || f.why == 'gone'))) {
      children.addAll([
        const SizedBox(height: 22),
        Semantics(
          header: true,
          child: Text(
            l.upd2Steps,
            style: TextStyle(color: c.dim, fontSize: 13, fontWeight: FontWeight.w700),
          ),
        ),
        const SizedBox(height: 8),
        for (final (i, s) in steps.indexed) _StepRow(n: i + 1, step: s, f: f),
      ]);
    }

    // ---- what to know ----
    if (!f.finished) {
      children.add(const SizedBox(height: 14));
      if (f.local) {
        children.add(
          _Note(key: const Key('update-local'), icon: RgIcons.monitor, text: l.upd2Local),
        );
      }
      if (!f.detailed && stage != UpdateStage.starting) {
        children.add(_Note(key: const Key('update-older'), icon: RgIcons.help, text: l.upd2Older));
      }
      final before =
          current == 'check' ||
          current == 'download' ||
          current == 'files' ||
          current == 'scan' ||
          current == 'build' ||
          current == 'installer';
      children.add(_Note(icon: RgIcons.server, text: before ? l.upd2Keeps : l.upd2ComesBack));
    }

    final buttons = _buttons(context, l);
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Flexible(
          child: Align(
            alignment: Alignment.topCenter,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 640),
              child: SingleChildScrollView(
                key: const Key('update-screen'),
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
                child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: children),
              ),
            ),
          ),
        ),
        if (buttons.isNotEmpty)
          Container(
            decoration: BoxDecoration(
              border: Border(top: BorderSide(color: c.line)),
            ),
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
            child: Wrap(alignment: WrapAlignment.end, spacing: 8, runSpacing: 8, children: buttons),
          ),
      ],
    );
  }

  List<Widget> _done(BuildContext context, AppLocalizations l, RgColors c, String lang) {
    final v = f.doneVersion ?? f.to ?? '';
    final took = f.took;
    final from = f.fromVersion;
    final note = v == f.to ? (f.note?[lang] ?? f.note?['en']) : null;
    return [
      _Card(
        tone: c.ok,
        children: [
          Text(
            from == null
                ? l.upd2DoneFrom('')
                : took != null
                ? l.upd2DoneText(from, tookWords(l, took))
                : l.upd2DoneFrom(from),
            key: const Key('update-done-text'),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              RgIcon(
                f.reconnected ? RgIcons.check : RgIcons.refresh,
                size: 15,
                color: f.reconnected ? c.ok : c.dim,
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  f.reconnected ? l.upd2Reconnected : l.upd2Reconnecting,
                  key: const Key('update-reconnected'),
                  style: TextStyle(color: c.dim, fontSize: 13),
                ),
              ),
            ],
          ),
        ],
      ),
      if (note is String && note.isNotEmpty) ...[
        const SizedBox(height: 16),
        Text(
          l.upd2News(v),
          style: TextStyle(color: c.dim, fontSize: 13, fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 6),
        _Card(key: const Key('update-news'), tone: c.line, children: [SelectableText(note)]),
      ],
    ];
  }

  List<Widget> _failed(BuildContext context, AppLocalizations l, RgColors c, String from) {
    final why = f.why ?? 'other';
    return [
      _Card(
        key: const Key('update-why'),
        tone: c.err,
        children: [
          Text(whyText(l, why, from.isEmpty ? 'RedGiant' : from)),
          if (f.error != null) ...[
            const SizedBox(height: 6),
            Text(l.upd2WhySaid(f.error!), style: TextStyle(color: c.dim, fontSize: 13)),
          ],
        ],
      ),
    ];
  }

  List<Widget> _buttons(BuildContext context, AppLocalizations l) {
    final c = RgColors.of(context);
    switch (f.stage) {
      case UpdateStage.done:
        final v = f.doneVersion ?? '';
        return [
          TextButton.icon(
            key: const Key('update-notes'),
            onPressed: () => unawaited(openExternal(Uri.parse('$_releases$v'))),
            icon: RgIcon(RgIcons.external, size: 16, color: c.accent),
            label: Text(l.upd2Notes),
          ),
          FilledButton(
            key: const Key('update-back'),
            onPressed: () => Navigator.of(context).pop(),
            child: Text(l.upd2BackHome),
          ),
        ];
      case UpdateStage.failed:
        return [
          TextButton(
            key: const Key('update-leave'),
            onPressed: () => Navigator.of(context).pop(),
            child: Text(l.upd2Close),
          ),
          if (f.canRetry)
            FilledButton.icon(
              key: const Key('update-retry'),
              onPressed: () => unawaited(f.retry()),
              icon: const RgIcon(RgIcons.refresh, size: 16, color: Colors.white),
              label: Text(l.upd2Retry),
            ),
        ];
      default:
        return [
          TextButton(
            key: const Key('update-hide'),
            onPressed: () => Navigator.of(context).pop(),
            child: Text(l.upd2Hide),
          ),
        ];
    }
  }
}

/// The bar of what runs now: the download with its bytes, speed and time left; the restart with
/// the app's tries; a bar that moves with the time gone by when the server does not say more.
class _Live extends StatelessWidget {
  const _Live({required this.f, this.current});

  final UpdateFollower f;
  final String? current;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final c = RgColors.of(context);
    final restarting = f.stage == UpdateStage.restarting;
    final p = f.progress;
    final String head;
    final String line;
    if (restarting) {
      head = l.upd2Restarting;
      final since = f.lostSince == null ? Duration.zero : f.now.difference(f.lostSince!);
      line = l.upd2Attempt('${f.attempts}', clock(since));
    } else if (f.wasLost && current == 'wait') {
      head = l.upd2Back;
      line = l.upd2Elapsed(clock(f.elapsed));
    } else {
      head = current == null ? l.upd2Starting : stepTitle(l, current!);
      line = p != null && p.total > 0 ? progressText(l, p) : l.upd2Elapsed(clock(f.elapsed));
    }
    return _Card(
      key: Key(restarting ? 'update-restarting' : 'update-live'),
      tone: c.accent,
      children: [
        Text(head, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
        const SizedBox(height: 10),
        ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: LinearProgressIndicator(
            key: const Key('update-bar'),
            value: restarting ? null : p?.fraction,
            minHeight: 8,
            backgroundColor: c.line,
            color: c.accent,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          line,
          key: const Key('update-bar-text'),
          style: TextStyle(
            color: c.dim,
            fontSize: 13,
            fontFeatures: const [FontFeature.tabularFigures()],
          ),
        ),
      ],
    );
  }
}

class _StepRow extends StatelessWidget {
  const _StepRow({required this.n, required this.step, required this.f});

  final int n;
  final RunStep step;
  final UpdateFollower f;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final c = RgColors.of(context);
    final mark = step.mark;
    final now = mark == StepMark.now;
    final failed = mark == StepMark.failed;
    final Widget badge = switch (mark) {
      StepMark.done => Container(
        decoration: BoxDecoration(color: c.ok, shape: BoxShape.circle),
        alignment: Alignment.center,
        child: const RgIcon(RgIcons.check, size: 15, color: Colors.white),
      ),
      StepMark.failed => Container(
        decoration: BoxDecoration(color: c.err, shape: BoxShape.circle),
        alignment: Alignment.center,
        child: const RgIcon(RgIcons.alert, size: 15, color: Colors.white),
      ),
      StepMark.now => Container(
        decoration: BoxDecoration(color: c.accent, shape: BoxShape.circle),
        alignment: Alignment.center,
        child: Text(
          '$n',
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 13),
        ),
      ),
      StepMark.todo => Container(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: c.line, width: 1.5),
        ),
        alignment: Alignment.center,
        child: Text('$n', style: TextStyle(color: c.dim, fontSize: 13)),
      ),
    };
    final word = switch (mark) {
      StepMark.done => l.upd2StepDone,
      StepMark.now => l.upd2StepNow,
      StepMark.todo => l.upd2StepTodo,
      StepMark.failed => l.upd2StepFailed,
    };
    final text = now || failed ? stepText(l, step.id) : null;
    final images = step.id == 'download' && (now || mark == StepMark.done)
        ? f.os?.run?.images ?? const []
        : const <({String name, double bytes, bool here})>[];
    final items = f.os?.run?.progress?.items ?? const [];
    return Semantics(
      label: '$n. ${stepTitle(l, step.id)}: $word',
      excludeSemantics: true,
      child: Container(
        key: Key('update-step-${step.id}'),
        margin: const EdgeInsets.only(bottom: 6),
        padding: const EdgeInsets.fromLTRB(10, 10, 12, 10),
        decoration: BoxDecoration(
          color: now
              ? c.accent.withValues(alpha: .08)
              : failed
              ? c.err.withValues(alpha: .08)
              : null,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: now
                ? c.accent.withValues(alpha: .45)
                : failed
                ? c.err.withValues(alpha: .45)
                : Colors.transparent,
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(width: 26, height: 26, child: badge),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(top: 3),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            stepTitle(l, step.id),
                            style: TextStyle(
                              fontWeight: now || failed ? FontWeight.w700 : FontWeight.w500,
                              color: mark == StepMark.todo ? c.dim : c.text,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          word,
                          style: TextStyle(
                            fontSize: 12,
                            color: now
                                ? c.accent
                                : failed
                                ? c.err
                                : mark == StepMark.done
                                ? c.ok
                                : c.dim,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (text != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      step.id == 'files' && (f.os?.run?.filesBytes ?? 0) > 0
                          ? '${_mb(f.os!.run!.filesBytes)} · $text'
                          : text,
                      style: TextStyle(color: c.dim, fontSize: 12.5),
                    ),
                  ],
                  for (final i in images)
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              i.name == 'postgres'
                                  ? l.upd2ImgDatabase
                                  : (i.name == 'redgiant' ? 'RedGiant' : i.name),
                              style: TextStyle(fontSize: 12.5, color: c.text),
                            ),
                          ),
                          Text(
                            _imageState(l, i, items, mark),
                            style: TextStyle(fontSize: 12.5, color: c.dim),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _imageState(
    AppLocalizations l,
    ({String name, double bytes, bool here}) i,
    List<ProgressItem> items,
    StepMark mark,
  ) {
    if (i.here) return l.upd2ImgHere;
    final live = items.where((x) => x.name == i.name).firstOrNull;
    if (mark == StepMark.done || live?.state == 'done') return l.upd2ImgDone;
    if (live != null && live.state == 'down' && live.total > 0) {
      return '${_mb(live.done)} / ${_mb(live.total)}';
    }
    return _mb(i.bytes);
  }
}

class _Card extends StatelessWidget {
  const _Card({super.key, required this.tone, required this.children});

  final Color tone;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final c = RgColors.of(context);
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Color.alphaBlend(tone.withValues(alpha: .06), c.panel),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: tone.withValues(alpha: .4)),
      ),
      child: DefaultTextStyle.merge(
        style: TextStyle(color: c.text, fontSize: 14, height: 1.35),
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: children),
      ),
    );
  }
}

class _Note extends StatelessWidget {
  const _Note({super.key, required this.icon, required this.text});

  final RgIcons icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    final c = RgColors.of(context);
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 2),
            child: RgIcon(icon, size: 15, color: c.dim),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(text, style: TextStyle(color: c.dim, fontSize: 13, height: 1.35)),
          ),
        ],
      ),
    );
  }
}

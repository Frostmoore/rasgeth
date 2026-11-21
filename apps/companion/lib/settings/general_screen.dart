// Settings › General, native (G42.4), as the page's General.tsx: a big heading, the look and the
// languages (the interface's and, apart, the agents': G33.5), then squares lit when something is
// set (never a check mark), each opening its own panel (a window on a computer, a whole screen on
// a phone): instructions for every agent (with the refiner), the backup model, web search, voice
// messages, pictures; then updates, what's new and the debug log; the account at the bottom.
// Every save goes through the page's own routes (`lib/settings/api/general_api.dart`); what the
// environment set is shown and never changed.
import 'dart:async';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

import '../api/client.dart';
import '../api/code.dart' show JobView;
import '../api/settings_types.dart';
import '../app_state.dart';
import '../l10n/app_localizations.dart';
import '../screens/first_start_screen.dart' show openExternal;
import '../screens/new_agent_screen.dart' show RgSwitch;
import '../screens/update_screen.dart' show openUpdateScreen;
import '../theme/colors.dart';
import '../ui/dialogs.dart';
import '../ui/icons.dart';
import '../ui/model_sheet.dart';
import '../ui/settings_kit.dart';
import 'api/general_api.dart';
import 'general_types.dart';
import 'general_words.g.dart';
import 'prompt_refiner.dart';

/// Tests set this: where the debug logs go instead of the system's «Save as» (true: saved).
@visibleForTesting
Future<bool> Function(String name, Uint8List bytes)? debugSaveLogs;

/// Opens Settings › General: a panel over the window on a computer, a whole screen on a phone.
Future<void> openGeneralSettings(BuildContext context) {
  final size = MediaQuery.sizeOf(context);
  if (size.width >= 760) {
    return showRgWindow<void>(
      context: context,
      builder: (_) => Dialog(
        key: const Key('general-window'),
        insetPadding: const EdgeInsets.all(28),
        clipBehavior: Clip.antiAlias,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: 780, maxHeight: size.height * .9),
          child: const GeneralSettingsScreen(panel: true),
        ),
      ),
    );
  }
  return Navigator.of(context)
      .push(MaterialPageRoute<void>(builder: (_) => const GeneralSettingsScreen()));
}

/// G42.16: «Who writes down what you say» from Settings › Voice: General's voice-messages panel
/// (the same choice: the server's transcription), read fresh; false when it could not be read.
Future<bool> openTranscriptionPanel(BuildContext context) async {
  final c = AppScope.read(context).client;
  if (c == null) return false;
  final GeneralState s;
  try {
    s = await c.generalState();
  } on ApiException {
    return false;
  }
  if (!context.mounted) return false;
  await _openPanel<void>(
    context,
    title: AppLocalizations.of(context).g4GenVoiceTitle,
    key: const Key('general-voice'),
    body: (_) => _VoicePanel(initial: s),
  );
  return true;
}

/// One of General's panels: a window on a computer, a whole screen on a phone.
Future<T?> _openPanel<T>(
  BuildContext context, {
  required String title,
  required Key key,
  required WidgetBuilder body,
}) {
  final size = MediaQuery.sizeOf(context);
  Widget frame(BuildContext ctx, {required bool window}) {
    final c = RgColors.of(ctx);
    final l = AppLocalizations.of(ctx);
    return Material(
      key: key,
      color: c.bg,
      child: SafeArea(
        top: !window,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(6, 8, 12, 4),
              child: Row(
                children: [
                  IconButton(
                    key: const Key('general-panel-close'),
                    tooltip: window ? l.close : l.back,
                    onPressed: () => Navigator.of(ctx).maybePop(),
                    icon: RgIcon(window ? RgIcons.x : RgIcons.arrowLeft, color: c.text),
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: c.text),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(child: body(ctx)),
          ],
        ),
      ),
    );
  }

  if (size.width >= 760) {
    return showRgWindow<T>(
      context: context,
      builder: (ctx) => Dialog(
        insetPadding: const EdgeInsets.all(32),
        clipBehavior: Clip.antiAlias,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: 640, maxHeight: size.height * .86),
          child: frame(ctx, window: true),
        ),
      ),
    );
  }
  return Navigator.of(context)
      .push(MaterialPageRoute<T>(builder: (ctx) => Scaffold(body: frame(ctx, window: false))));
}

String _lang(BuildContext context) =>
    Localizations.localeOf(context).languageCode == 'en' ? 'en' : 'it';

/// The page's word for [key] (news, search services), in the interface's language.
String pageWord(BuildContext context, String key) =>
    generalWords[_lang(context)]?[key] ?? generalWords['en']?[key] ?? key;

String _bytes(int n) {
  if (n < 1024) return '$n B';
  if (n < 1024 * 1024) return '${(n / 1024).toStringAsFixed(1)} KB';
  if (n < 1024 * 1024 * 1024) return '${(n / (1024 * 1024)).toStringAsFixed(1)} MB';
  return '${(n / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
}

class GeneralSettingsScreen extends StatefulWidget {
  const GeneralSettingsScreen({super.key, this.panel = false});

  /// Inside a window (a computer): a close button instead of the back arrow.
  final bool panel;

  @override
  State<GeneralSettingsScreen> createState() => _GeneralSettingsScreenState();
}

class _GeneralSettingsScreenState extends State<GeneralSettingsScreen> {
  GeneralState? _s;
  DebugState? _debug;
  UpdateStatus? _update;
  List<ModelChoice>? _models;
  String? _error;
  String? _said;
  bool _looking = false;

  RedGiantClient? get _c => AppScope.read(context).client;

  @override
  void initState() {
    super.initState();
    unawaited(_load());
  }

  Future<void> _load() async {
    final c = _c;
    if (c == null) return;
    try {
      final s = await c.generalState();
      if (mounted) setState(() => _s = s);
    } on ApiException catch (e) {
      if (mounted) setState(() => _error = e.message);
    }
    unawaited(() async {
      try {
        final d = await c.debugState();
        if (mounted) setState(() => _debug = d);
      } on ApiException {
        // An older server: no debug square, as the page.
      }
    }());
    unawaited(() async {
      try {
        final u = await c.updateStatus();
        if (mounted) setState(() => _update = u);
      } on ApiException {
        // Said by the square: nothing known.
      }
    }());
    unawaited(() async {
      try {
        final m = await c.models();
        if (mounted) setState(() => _models = m);
      } on ApiException {
        if (mounted) setState(() => _models = const []);
      }
    }());
  }

  Future<bool> _try(Future<void> Function() f) async {
    final l = AppLocalizations.of(context);
    setState(() {
      _error = null;
      _said = null;
    });
    try {
      await f();
      return true;
    } on ApiException catch (e) {
      if (mounted) setState(() => _error = l.errGeneric(e.message));
      return false;
    }
  }

  Future<void> _uiLanguage(String code) async {
    final app = AppScope.read(context);
    app.setLocale(Locale(code));
    // The server writes its own pages and, failing the agents' language, Telegram in it.
    if (await _try(() => _c!.setLanguages(language: code))) await _load();
  }

  Future<void> _agentLanguage() async {
    final s = _s;
    if (s == null) return;
    final current = s.agentLanguage ?? s.language ?? _lang(context);
    final code = await showAgentLanguagePicker(context, current: current);
    if (code == null || code == current || !mounted) return;
    if (await _try(() => _c!.setLanguages(agentLanguage: code))) await _load();
  }

  Future<void> _instructions() async {
    final s = _s;
    if (s == null) return;
    await _openPanel<void>(
      context,
      title: AppLocalizations.of(context).g4GenInstructionsTitle,
      key: const Key('general-instructions'),
      body: (_) => _InstructionsPanel(initial: s.instructions),
    );
    if (mounted) await _load();
  }

  Future<void> _backup() async {
    final l = AppLocalizations.of(context);
    final s = _s;
    final models = _models;
    if (s == null || models == null || models.isEmpty) return;
    final p = await showModelPicker(
      context,
      title: l.g4GenBackupTitle,
      models: models,
      current: s.backupModel,
      inheritLabel: l.g4GenBackupNone,
    );
    if (p == null || !mounted || p.model == s.backupModel) return;
    if (await _try(() => _c!.setBackupModel(p.model))) {
      setState(() => _said = l.g4GenBackupSaved);
      await _load();
    }
  }

  Future<void> _service(String part) async {
    final s = _s;
    if (s == null) return;
    final l = AppLocalizations.of(context);
    await _openPanel<void>(
      context,
      title: switch (part) {
        'search' => l.g4GenSearchTitle,
        'voice' => l.g4GenVoiceTitle,
        _ => l.g4GenImagesTitle,
      },
      key: Key('general-$part'),
      body: (_) => switch (part) {
        'search' => _SearchPanel(initial: s),
        'voice' => _VoicePanel(initial: s),
        _ => _ImagesPanel(initial: s),
      },
    );
    if (mounted) await _load();
  }

  Future<void> _news() => _openPanel<void>(
    context,
    title: AppLocalizations.of(context).g4GenNewsTitle(newsVersion),
    key: const Key('general-news'),
    body: (_) => const NewsList(),
  );

  Future<void> _debugPanel() async {
    final d = _debug;
    if (d == null) return;
    await _openPanel<void>(
      context,
      title: AppLocalizations.of(context).g4GenDebugTitle,
      key: const Key('general-debug'),
      body: (_) => _DebugPanel(initial: d),
    );
    if (mounted) await _load();
  }

  Future<void> _look() async {
    final c = _c;
    if (c == null) return;
    setState(() => _looking = true);
    try {
      final u = await c.updateLook();
      if (mounted) setState(() => _update = u);
    } on ApiException catch (e) {
      if (mounted) setState(() => _error = AppLocalizations.of(context).errGeneric(e.message));
    } finally {
      if (mounted) setState(() => _looking = false);
    }
  }

  /// As the server's settings: the person says yes, the app follows the update on its screen.
  Future<void> _updateNow() async {
    final app = AppScope.read(context);
    final l = AppLocalizations.of(context);
    final u = _update;
    final to = u?.latest ?? '';
    final ok = await askConfirm(
      context,
      title: l.updNowTitle,
      body: app.localRedGiant && (u?.install == 'windows' || u?.install == 'mac')
          ? l.updNowBodyLocal(to)
          : l.updNowBody(to),
      yes: l.updNow,
    );
    if (!ok || !mounted) return;
    unawaited(app.startUpdate(from: u?.installed, to: to.isEmpty ? null : to, note: u?.note));
    await openUpdateScreen(context);
  }

  Future<void> _signOut() async {
    final app = AppScope.read(context);
    final l = AppLocalizations.of(context);
    final ok = await askConfirm(
      context,
      title: l.forgetServer,
      body: l.forgetServerBody(app.displayName),
      yes: l.g4GenLogout,
      danger: true,
    );
    if (!ok || !mounted) return;
    final nav = Navigator.of(context);
    await app.disconnect();
    nav.popUntil((r) => r.isFirst);
  }

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    final l = AppLocalizations.of(context);
    final c = RgColors.of(context);
    final s = _s;
    final ui = app.locale?.languageCode ?? s?.language ?? _lang(context);
    final agentLang = agentLanguageOf(s?.agentLanguage ?? s?.language ?? _lang(context));
    final instructions = s?.instructions.trim() ?? '';
    final backup = s?.backupModel;
    final d = _debug;
    final u = _update;
    final list = ListView(
      key: const Key('general-list'),
      padding: const EdgeInsets.only(bottom: 28),
      children: [
        if (_error != null)
          NoticeBanner(key: const Key('general-error'), text: _error!, error: true),
        if (_said != null) NoticeBanner(key: const Key('general-said'), text: _said!),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 4),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            spacing: 6,
            children: [
              Text(
                l.g4GenQ,
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: c.text),
              ),
              Text(l.g4GenLead, style: TextStyle(color: c.dim, fontSize: 13.5, height: 1.35)),
            ],
          ),
        ),
        // ---- look and languages ----
        SectionHead(l.g4GenLook),
        SettingsCard(
          key: const Key('general-look'),
          children: [
            _Line(
              title: l.themeLabel,
              child: ChoiceRow(
                keyPrefix: 'general-theme',
                values: const ['system', 'light', 'dark'],
                selected: app.themeMode.name,
                label: (v) => switch (v) {
                  'light' => l.themeLight,
                  'dark' => l.themeDark,
                  _ => l.themeSystem,
                },
                onChanged: (v) => app.setThemeMode(ThemeMode.values.byName(v)),
              ),
            ),
            Divider(height: 1, color: c.line),
            _Line(
              title: l.g4GenUiLangTitle,
              help: l.g4GenUiLangHelp,
              child: ChoiceRow(
                keyPrefix: 'general-ui-lang',
                values: const ['it', 'en'],
                selected: ui,
                label: (v) => v == 'it' ? 'Italiano' : 'English',
                onChanged: _uiLanguage,
              ),
            ),
            Divider(height: 1, color: c.line),
            _Line(
              title: l.g4GenAgentLangTitle,
              help: l.g4GenAgentLangHelp,
              child: _AgentLanguageBox(
                language: agentLang,
                onTap: s == null ? null : _agentLanguage,
              ),
            ),
          ],
        ),
        // ---- for every agent ----
        SectionHead(l.g4GenAgents),
        _Lead(l.g4GenAgentsLead),
        _Tiles(
          children: [
            _Tile(
              key: const Key('general-tile-instructions'),
              on: instructions.isNotEmpty,
              icon: RgIcons.edit,
              title: l.g4GenInstructionsTitle,
              text: instructions.isNotEmpty
                  ? (instructions.length > 90 ? '${instructions.substring(0, 90)}…' : instructions)
                  : l.g4GenInstrText,
              state: instructions.isNotEmpty ? l.g4GenWritten : null,
              onTap: s == null ? null : _instructions,
            ),
            _Tile(
              key: const Key('general-tile-backup'),
              on: backup != null,
              icon: RgIcons.refresh,
              title: l.g4GenBackupTitle,
              text: l.g4GenBackupText,
              state: backup == null ? null : modelWords(l, _models ?? const [], backup),
              onTap: s == null || (_models?.isEmpty ?? true) ? null : _backup,
            ),
          ],
        ),
        // ---- services ----
        SectionHead(l.g4GenServices),
        _Lead(l.g4GenServicesHint),
        _Tiles(
          children: [
            _Tile(
              key: const Key('general-tile-search'),
              on: s?.searchProvider != null,
              icon: RgIcons.search,
              title: l.g4GenSearchTitle,
              text: l.g4GenSearchText,
              state: s?.searchProvider == null ? null : l.g4GenInUse,
              onTap: s == null ? null : () => _service('search'),
            ),
            _Tile(
              key: const Key('general-tile-voice'),
              on: s?.transcription != null,
              icon: RgIcons.mic,
              title: l.g4GenVoiceTitle,
              text: l.g4GenVoiceHelp,
              state: s?.transcription == null ? null : l.g4GenOn,
              onTap: s == null ? null : () => _service('voice'),
            ),
            _Tile(
              key: const Key('general-tile-images'),
              on: s?.imagesKey ?? false,
              icon: RgIcons.image,
              title: l.g4GenImagesTitle,
              text: l.g4GenImagesHelp,
              state: (s?.imagesKey ?? false) ? (s?.imagesModel ?? l.g4GenOn) : null,
              onTap: s == null ? null : () => _service('images'),
            ),
          ],
        ),
        // ---- updates and diagnostics ----
        SectionHead(l.g4GenCare),
        _Lead(l.g4GenCareLead),
        SettingsCard(
          key: const Key('general-updates'),
          children: [
            NoteLine(icon: RgIcons.download, text: l.g4GenUpdHelp),
            if (u != null)
              NoteLine(
                icon: u.available ? RgIcons.download : RgIcons.check,
                color: u.available ? c.accent : c.ok,
                strong: true,
                text: u.available ? l.updAvailable(u.latest ?? '') : l.updLatest,
              ),
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 0, 12, 10),
              child: Wrap(
                alignment: WrapAlignment.end,
                spacing: 8,
                runSpacing: 6,
                children: [
                  TextButton.icon(
                    key: const Key('general-update-look'),
                    onPressed: _looking ? null : _look,
                    icon: RgIcon(RgIcons.refresh, size: 16, color: c.accent),
                    label: Text(_looking ? l.updLooking : l.updLook),
                  ),
                  if (u != null && u.available && u.canUpdateHere && u.gate != 'breaking')
                    FilledButton(
                      key: const Key('general-update-now'),
                      onPressed: _updateNow,
                      child: Text(l.updNow),
                    ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        _Tiles(
          children: [
            _Tile(
              key: const Key('general-tile-news'),
              on: false,
              icon: RgIcons.star,
              title: l.g4GenNews,
              text: l.g4GenNewsText,
              onTap: _news,
            ),
            if (d != null)
              _Tile(
                key: const Key('general-tile-debug'),
                on: d.enabled,
                icon: RgIcons.tool,
                title: l.g4GenDebugTitle,
                text: l.g4GenDebugText,
                state: d.enabled ? l.g4GenOn : null,
                onTap: _debugPanel,
              ),
          ],
        ),
        // ---- account ----
        SectionHead(l.g4GenAccount),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Align(
            alignment: Alignment.centerLeft,
            child: OutlinedButton.icon(
              key: const Key('general-logout'),
              onPressed: _signOut,
              style: OutlinedButton.styleFrom(
                side: BorderSide(color: c.err.withValues(alpha: .5)),
                foregroundColor: c.err,
              ),
              icon: RgIcon(RgIcons.arrowLeft, size: 16, color: c.err),
              label: Text(l.g4GenLogout),
            ),
          ),
        ),
      ],
    );
    final body = Align(
      alignment: Alignment.topCenter,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 720),
        child: s == null && _error == null
            ? Center(
                child: Text(l.loading, style: TextStyle(color: c.dim)),
              )
            : RefreshIndicator(onRefresh: _load, child: list),
      ),
    );
    return Scaffold(
      key: const Key('general-screen'),
      appBar: AppBar(
        automaticallyImplyLeading: false,
        leading: IconButton(
          key: const Key('general-back'),
          tooltip: widget.panel ? l.close : l.back,
          onPressed: () => Navigator.of(context).maybePop(),
          icon: RgIcon(widget.panel ? RgIcons.x : RgIcons.arrowLeft, color: c.text),
        ),
        title: Text(l.g4GenTitle),
      ),
      body: body,
    );
  }
}

/// A row of the look card: its title (and help) above, the control under it.
class _Line extends StatelessWidget {
  const _Line({required this.title, this.help, required this.child});

  final String title;
  final String? help;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final c = RgColors.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        spacing: 8,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            spacing: 2,
            children: [
              Text(
                title,
                style: TextStyle(color: c.text, fontWeight: FontWeight.w700, fontSize: 15),
              ),
              if (help != null) Text(help!, style: TextStyle(color: c.dim, fontSize: 12.5)),
            ],
          ),
          child,
        ],
      ),
    );
  }
}

class _Lead extends StatelessWidget {
  const _Lead(this.text);

  final String text;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
    child: Text(text, style: TextStyle(color: RgColors.of(context).dim, fontSize: 13)),
  );
}

/// The squares, two in a row on a phone, three on a computer.
class _Tiles extends StatelessWidget {
  const _Tiles({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 16),
    child: LayoutBuilder(
      builder: (context, box) {
        final cols = box.maxWidth >= 600 ? 3 : (box.maxWidth >= 340 ? 2 : 1);
        final w = (box.maxWidth - (cols - 1) * 10) / cols;
        return Wrap(
          spacing: 10,
          runSpacing: 10,
          children: [for (final t in children) SizedBox(width: w, child: t)],
        );
      },
    ),
  );
}

/// A square of the wizard: lit by border and background when set, never a check mark.
class _Tile extends StatelessWidget {
  const _Tile({
    super.key,
    required this.on,
    required this.icon,
    required this.title,
    required this.text,
    this.state,
    required this.onTap,
  });

  final bool on;
  final RgIcons icon;
  final String title;
  final String text;
  final String? state;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final c = RgColors.of(context);
    return Semantics(
      button: true,
      label: title,
      child: Material(
        color: on ? c.accentSoft : c.panel,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: BorderSide(color: on ? c.accent : c.line, width: on ? 1.5 : 1),
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: onTap,
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 132),
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                spacing: 6,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: on ? c.accent : c.bg,
                          borderRadius: BorderRadius.circular(10),
                          border: on ? null : Border.all(color: c.line),
                        ),
                        child: Center(
                          child: RgIcon(icon, size: 19, color: on ? Colors.white : c.accent),
                        ),
                      ),
                      const Spacer(),
                      if (state != null)
                        Flexible(
                          flex: 3,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: c.bg,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: c.accentDim),
                            ),
                            child: Text(
                              state!,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: c.accent,
                                fontSize: 11.5,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                  Text(
                    title,
                    style: TextStyle(color: c.text, fontWeight: FontWeight.w800, fontSize: 14.5),
                  ),
                  Text(
                    text,
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(color: c.dim, fontSize: 12.5, height: 1.3),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ---- the agents' language ----

/// The language with that code (case does not matter), or the second of the list (English).
AgentLanguageRow agentLanguageOf(String code) =>
    agentLanguages.where((l) => l.code.toLowerCase() == code.toLowerCase()).firstOrNull ??
    agentLanguages[1];

String _fold(String s) {
  const from = 'àáâãäåçèéêëìíîïñòóôõöùúûüýÿ';
  const to = 'aaaaaaceeeeiiiinooooouuuuyy';
  final out = StringBuffer();
  for (final ch in s.toLowerCase().split('')) {
    final i = from.indexOf(ch);
    out.write(i < 0 ? ch : to[i]);
  }
  return out.toString();
}

/// The languages that match a search (native name, both translations, code), in list order.
List<AgentLanguageRow> matchLanguages(String query) {
  final q = _fold(query.trim());
  if (q.isEmpty) return agentLanguages;
  return [
    for (final l in agentLanguages)
      if ([l.native, l.en, l.it, l.code].any((n) => _fold(n).contains(q))) l,
  ];
}

class _AgentLanguageBox extends StatelessWidget {
  const _AgentLanguageBox({required this.language, required this.onTap});

  final AgentLanguageRow language;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final c = RgColors.of(context);
    final l = AppLocalizations.of(context);
    final other = language.nameIn(_lang(context));
    return Material(
      color: c.bg,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: c.line),
      ),
      child: InkWell(
        key: const Key('general-agent-lang'),
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: c.accentSoft,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Center(child: RgIcon(RgIcons.chat, size: 20, color: c.accent)),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      language.native,
                      style: TextStyle(color: c.text, fontWeight: FontWeight.w800, fontSize: 16),
                    ),
                    Text(
                      '${other != language.native ? '$other · ' : ''}${l.g4GenAgentLangChange}',
                      style: TextStyle(color: c.dim, fontSize: 12.5),
                    ),
                  ],
                ),
              ),
              RgIcon(RgIcons.chevronDown, size: 18, color: c.dim),
            ],
          ),
        ),
      ),
    );
  }
}

/// The window (a sheet on a phone) to choose the agents' language: a search box, the most
/// common first, then every other in the interface's alphabetical order. Gives back its code.
Future<String?> showAgentLanguagePicker(BuildContext context, {required String current}) =>
    _openPanel<String>(
      context,
      title: AppLocalizations.of(context).g4GenAgentLangTitle,
      key: const Key('general-languages'),
      body: (_) => _LanguageChooser(current: current),
    );

class _LanguageChooser extends StatefulWidget {
  const _LanguageChooser({required this.current});

  final String current;

  @override
  State<_LanguageChooser> createState() => _LanguageChooserState();
}

class _LanguageChooserState extends State<_LanguageChooser> {
  final _q = TextEditingController();

  @override
  void initState() {
    super.initState();
    _q.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _q.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final c = RgColors.of(context);
    final lang = _lang(context);
    final q = _q.text.trim();
    final found = matchLanguages(q);
    final common = [
      for (final x in agentLanguages)
        if (x.common) x,
    ];
    final others = [
      for (final x in agentLanguages)
        if (!x.common) x,
    ]..sort((a, b) => _fold(a.nameIn(lang)).compareTo(_fold(b.nameIn(lang))));
    void pick(String code) => Navigator.of(context).pop(code);
    Widget grid(List<AgentLanguageRow> list) => LayoutBuilder(
      builder: (context, box) {
        final cols = box.maxWidth >= 520 ? 3 : 2;
        final w = (box.maxWidth - (cols - 1) * 8) / cols;
        return Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final x in list)
              SizedBox(
                width: w,
                child: _LanguageOption(
                  language: x,
                  on: x.code.toLowerCase() == widget.current.toLowerCase(),
                  onTap: () => pick(x.code),
                ),
              ),
          ],
        );
      },
    );
    Widget head(String t) => Padding(
      padding: const EdgeInsets.only(top: 14, bottom: 8),
      child: Text(
        t,
        style: TextStyle(color: c.dim, fontWeight: FontWeight.w700, fontSize: 13),
      ),
    );
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
      children: [
        Text(l.g4GenAgentLangSub, style: TextStyle(color: c.dim, fontSize: 13)),
        const SizedBox(height: 10),
        TextField(
          key: const Key('general-lang-search'),
          controller: _q,
          textInputAction: TextInputAction.search,
          onSubmitted: (_) {
            if (found.isNotEmpty) pick(found.first.code);
          },
          decoration: InputDecoration(
            hintText: l.g4GenAgentLangSearch,
            prefixIcon: Padding(
              padding: const EdgeInsets.all(12),
              child: RgIcon(RgIcons.search, size: 18, color: c.dim),
            ),
            border: const OutlineInputBorder(),
          ),
        ),
        if (q.isNotEmpty)
          found.isEmpty
              ? Padding(
                  padding: const EdgeInsets.only(top: 16),
                  child: Text(l.g4GenAgentLangNone(q), style: TextStyle(color: c.dim)),
                )
              : Padding(padding: const EdgeInsets.only(top: 14), child: grid(found))
        else ...[
          head(l.g4GenAgentLangCommon),
          grid(common),
          head(l.g4GenAgentLangAll),
          grid(others),
        ],
      ],
    );
  }
}

class _LanguageOption extends StatelessWidget {
  const _LanguageOption({required this.language, required this.on, required this.onTap});

  final AgentLanguageRow language;
  final bool on;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = RgColors.of(context);
    final other = language.nameIn(_lang(context));
    return Semantics(
      selected: on,
      button: true,
      child: Material(
        color: on ? c.accentSoft : c.panel,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: on ? c.accent : c.line, width: on ? 1.5 : 1),
        ),
        child: InkWell(
          key: Key('lang-${language.code}'),
          borderRadius: BorderRadius.circular(12),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  language.native,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(color: c.text, fontWeight: FontWeight.w700),
                ),
                if (other != language.native)
                  Text(
                    other,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(color: c.dim, fontSize: 12),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ---- panels ----

/// The panels' common body: their lead, then the parts, a phone's measure.
class _PanelBody extends StatelessWidget {
  const _PanelBody({required this.lead, required this.children});

  final String lead;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) => ListView(
    padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
    children: [
      Text(lead, style: TextStyle(color: RgColors.of(context).dim, fontSize: 13.5, height: 1.35)),
      const SizedBox(height: 12),
      ...children,
    ],
  );
}

/// A result under a panel's buttons.
class _Result extends StatelessWidget {
  const _Result({super.key, required this.ok, required this.text});

  final bool ok;
  final String text;

  @override
  Widget build(BuildContext context) {
    final c = RgColors.of(context);
    final col = ok ? c.ok : c.err;
    return Container(
      margin: const EdgeInsets.only(top: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: col.withValues(alpha: .08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: col.withValues(alpha: .35)),
      ),
      child: Text(text, style: TextStyle(color: c.text, fontSize: 13.5)),
    );
  }
}

class _InstructionsPanel extends StatefulWidget {
  const _InstructionsPanel({required this.initial});

  final String initial;

  @override
  State<_InstructionsPanel> createState() => _InstructionsPanelState();
}

class _InstructionsPanelState extends State<_InstructionsPanel> {
  late final _text = TextEditingController(text: widget.initial);
  late String _saved = widget.initial.trim();
  bool _saving = false;
  bool _done = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _text.addListener(() => setState(() => _done = false));
  }

  @override
  void dispose() {
    _text.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      await AppScope.read(context).client!.setGeneralInstructions(_text.text);
      if (!mounted) return;
      setState(() {
        _saved = _text.text.trim();
        _done = true;
      });
    } on ApiException catch (e) {
      if (mounted) setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return _PanelBody(
      lead: l.g4GenInstructionsHint,
      children: [
        TextField(
          key: const Key('general-instructions-text'),
          controller: _text,
          minLines: 8,
          maxLines: 18,
          style: const TextStyle(fontSize: 14, height: 1.4),
          decoration: InputDecoration(
            hintText: l.g4GenInstructionsPlaceholder,
            hintMaxLines: 3,
            border: const OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 12),
        PromptRefiner(
          target: const RefineGeneral(),
          text: _text.text,
          onUse: (t) => _text.text = t,
        ),
        if (_done)
          _Result(
            key: const Key('general-instructions-saved'),
            ok: true,
            text: l.g4GenInstructionsSaved,
          ),
        if (_error != null) _Result(ok: false, text: l.errGeneric(_error!)),
        const SizedBox(height: 12),
        Align(
          alignment: Alignment.centerRight,
          child: FilledButton(
            key: const Key('general-instructions-save'),
            onPressed: _saving || _text.text.trim() == _saved ? null : _save,
            child: Text(l.save),
          ),
        ),
      ],
    );
  }
}

/// A choice among cards: lit by border and background, never a radio button.
class _ChoiceCard extends StatelessWidget {
  const _ChoiceCard({
    super.key,
    required this.title,
    required this.text,
    required this.on,
    this.badge,
    required this.onTap,
  });

  final String title;
  final String text;
  final bool on;
  final String? badge;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final c = RgColors.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Semantics(
        selected: on,
        button: true,
        child: Material(
          color: on ? c.accentSoft : c.panel,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(color: on ? c.accent : c.line, width: on ? 1.5 : 1),
          ),
          child: InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                spacing: 3,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          title,
                          style: TextStyle(color: c.text, fontWeight: FontWeight.w700),
                        ),
                      ),
                      if (badge != null)
                        Text(
                          badge!,
                          style: TextStyle(
                            color: c.ok,
                            fontSize: 11.5,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                    ],
                  ),
                  Text(text, style: TextStyle(color: c.dim, fontSize: 12.5, height: 1.3)),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

Widget _field(
  BuildContext context, {
  required Key key,
  required TextEditingController controller,
  required String label,
  String? help,
  String? hint,
  bool secret = false,
  bool enabled = true,
}) => Padding(
  padding: const EdgeInsets.only(top: 10),
  child: TextField(
    key: key,
    controller: controller,
    obscureText: secret,
    enabled: enabled,
    autocorrect: false,
    enableSuggestions: !secret,
    decoration: InputDecoration(
      labelText: label,
      helperText: help,
      helperMaxLines: 3,
      hintText: hint,
      border: const OutlineInputBorder(),
    ),
  ),
);

class _SearchPanel extends StatefulWidget {
  const _SearchPanel({required this.initial});

  final GeneralState initial;

  @override
  State<_SearchPanel> createState() => _SearchPanelState();
}

class _SearchPanelState extends State<_SearchPanel> {
  late GeneralState _s = widget.initial;
  late String _pick = _s.searchProvider ?? 'searxng';
  late final _url = TextEditingController(text: _s.searxngUrl ?? '');
  final _key = TextEditingController();
  String? _busy;
  ({bool ok, String text})? _result;
  late bool _ownOn = _s.searxngManaged;
  JobView? _job;
  Timer? _poll;

  RedGiantClient get _c => AppScope.read(context).client!;

  @override
  void initState() {
    super.initState();
    _url.addListener(() => setState(() {}));
    _key.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _poll?.cancel();
    _url.dispose();
    _key.dispose();
    super.dispose();
  }

  SearchProviderRow get _info =>
      searchProviders.firstWhere((p) => p.id == _pick, orElse: () => searchProviders.first);

  Map<String, Object?> _choice() => {
    'provider': _pick,
    if (_pick == 'searxng' && _url.text.trim().isNotEmpty) 'url': _url.text.trim(),
    if (_pick != 'searxng' && _key.text.trim().isNotEmpty) 'key': _key.text.trim(),
  };

  bool get _ready => _pick == 'searxng'
      ? _url.text.trim().isNotEmpty
      : _key.text.trim().isNotEmpty || _s.searchKeys.contains(_pick);

  Future<void> _run(String what) async {
    final l = AppLocalizations.of(context);
    setState(() {
      _busy = what;
      _result = null;
    });
    try {
      if (what == 'try') {
        final r = await _c.trySearch(_choice());
        _result = (
          ok: true,
          text: r.results > 0
              ? l.g4GenSearchTried('${r.results}', r.first ?? '')
              : l.g4GenSearchTriedEmpty,
        );
      } else {
        await _c.setServices({'search': _choice()});
        _key.clear();
        _result = (ok: true, text: l.g4GenSearchSaved(_info.name));
        final s = await _c.generalState();
        _s = s;
      }
    } on ApiException catch (e) {
      _result = (ok: false, text: e.message);
    }
    if (mounted) setState(() => _busy = null);
  }

  Future<void> _startOwn() async {
    try {
      final j = await _c.startOwnSearch();
      if (!mounted) return;
      setState(() => _job = j);
      _poll = Timer.periodic(const Duration(seconds: 1), (_) => _follow());
    } on ApiException catch (e) {
      if (mounted) setState(() => _result = (ok: false, text: e.message));
    }
  }

  Future<void> _follow() async {
    final j = _job;
    if (j == null) return;
    try {
      final next = await _c.job(j.id);
      if (!mounted) return;
      setState(() => _job = next);
      if (next.state != 'running') {
        _poll?.cancel();
        if (next.state == 'done') {
          final s = await _c.generalState();
          if (!mounted) return;
          setState(() {
            _ownOn = true;
            _s = s;
            _url.text = s.searxngUrl ?? '';
          });
        }
      }
    } on ApiException {
      // The next tick tries again.
    }
  }

  Future<void> _stopOwn() async {
    try {
      await _c.stopOwnSearch();
      if (!mounted) return;
      setState(() {
        _ownOn = false;
        _url.clear();
      });
    } on ApiException catch (e) {
      if (mounted) setState(() => _result = (ok: false, text: e.message));
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final c = RgColors.of(context);
    if (_s.locked.contains('search')) {
      return _PanelBody(
        lead: l.g4GenSearchText,
        children: [NoteLine(icon: RgIcons.lock, text: l.g4GenLocked)],
      );
    }
    final info = _info;
    final current = _s.searchProvider;
    final hasKey = _s.searchKeys.contains(_pick);
    final steps = pageWord(
      context,
      info.id == 'searxng' && !_s.canRunSearch ? 'searchHow_searxng_own' : 'searchHow_${info.id}',
    ).split('\n');
    final job = _job;
    return _PanelBody(
      lead: l.g4GenSearchText,
      children: [
        if (_s.canRunSearch)
          Container(
            key: const Key('general-own-search'),
            margin: const EdgeInsets.only(bottom: 14),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: _ownOn ? c.accentSoft : c.panel,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: _ownOn ? c.accent : c.line),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              spacing: 10,
              children: [
                Text(
                  _ownOn ? l.g4GenOwnSearchOn : l.g4GenOwnSearchHint,
                  style: TextStyle(color: c.text),
                ),
                if (job != null && job.state == 'running')
                  LinearProgressIndicator(color: c.accent, backgroundColor: c.line)
                else if (job != null && job.state == 'failed')
                  Text(job.errorMessage ?? job.state, style: TextStyle(color: c.err))
                else if (_ownOn)
                  OutlinedButton(
                    key: const Key('general-own-search-stop'),
                    onPressed: _stopOwn,
                    child: Text(l.g4GenOwnSearchStop),
                  )
                else
                  FilledButton(
                    key: const Key('general-own-search-start'),
                    onPressed: _startOwn,
                    child: Text(l.g4GenOwnSearchStart),
                  ),
              ],
            ),
          ),
        Text(l.g4GenSearchWho, style: TextStyle(color: c.dim, fontSize: 13)),
        const SizedBox(height: 10),
        for (final p in searchProviders)
          _ChoiceCard(
            key: Key('search-${p.id}'),
            title: p.id == current ? '${p.name} · ${l.g4GenInUse}' : p.name,
            text: pageWord(context, 'searchCard_${p.id}'),
            on: p.id == _pick,
            onTap: () => setState(() {
              _pick = p.id;
              _result = null;
            }),
          ),
        const SizedBox(height: 6),
        Container(
          key: const Key('search-how'),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: c.panel,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: c.line),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                l.g4GenSearchHowTitle(info.name),
                style: TextStyle(color: c.text, fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 8),
              for (final (i, step) in steps.indexed)
                Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 22,
                        height: 22,
                        margin: const EdgeInsets.only(right: 10),
                        decoration: BoxDecoration(color: c.accentSoft, shape: BoxShape.circle),
                        child: Center(
                          child: Text(
                            '${i + 1}',
                            style: TextStyle(
                              color: c.accent,
                              fontSize: 12,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                      ),
                      Expanded(
                        child: Text(step, style: TextStyle(color: c.text, fontSize: 13.5)),
                      ),
                    ],
                  ),
                ),
              Align(
                alignment: Alignment.centerLeft,
                child: TextButton.icon(
                  key: const Key('search-key-page'),
                  onPressed: () => unawaited(openExternal(Uri.parse(info.keyUrl))),
                  icon: RgIcon(RgIcons.external, size: 15, color: c.accent),
                  label: Text(info.needsUrl ? l.g4GenSearchDocs : l.g4GenSearchKeyPage(info.name)),
                ),
              ),
              if (info.needsUrl)
                _field(
                  context,
                  key: const Key('search-url'),
                  controller: _url,
                  label: l.g4GenSearchUrl,
                  help: l.g4GenSearchUrlHelp,
                  hint: 'http://searxng:8080',
                )
              else
                _field(
                  context,
                  key: const Key('search-key'),
                  controller: _key,
                  label: l.g4GenSearchKey,
                  help: hasKey ? l.g4GenSearchKeyKept : null,
                  hint: hasKey ? '••••••••' : info.keyExample,
                  secret: true,
                ),
              const SizedBox(height: 12),
              Wrap(
                alignment: WrapAlignment.end,
                spacing: 8,
                children: [
                  OutlinedButton(
                    key: const Key('search-try'),
                    onPressed: !_ready || _busy != null ? null : () => _run('try'),
                    child: Text(_busy == 'try' ? l.g4GenTrying : l.g4GenSearchTry),
                  ),
                  FilledButton(
                    key: const Key('search-use'),
                    onPressed: !_ready || _busy != null ? null : () => _run('save'),
                    child: Text(l.g4GenSearchUse),
                  ),
                ],
              ),
              if (_result != null)
                _Result(key: const Key('search-result'), ok: _result!.ok, text: _result!.text),
            ],
          ),
        ),
      ],
    );
  }
}

/// An indicative price in the person's words, as the page's `priceText`.
String? _priceText(AppLocalizations l, SttModelRow m) {
  final usd = m.usd;
  if (usd == null) return null;
  final p = double.parse(usd.toStringAsPrecision(2));
  final s = '\$${p.toString().replaceFirst(RegExp(r'\.0$'), '')}';
  return switch (m.per) {
    'minute' => l.g4GenPriceMinute(s),
    'kchars' => l.g4GenPriceKchars(s),
    _ => l.g4GenPriceMtokens(s),
  };
}

class _VoicePanel extends StatefulWidget {
  const _VoicePanel({required this.initial});

  final GeneralState initial;

  @override
  State<_VoicePanel> createState() => _VoicePanelState();
}

class _VoicePanelState extends State<_VoicePanel> {
  late final GeneralState _s = widget.initial;
  late String? _kind = _s.transcription?.kind;
  late final _url = TextEditingController(
    text: _s.transcription != null && _s.transcription!.api != 'local' ? _s.transcription!.url : '',
  );
  late String _model = _s.transcription?.model ?? '';
  late final _modelText = TextEditingController(
    text: _s.transcription?.api == 'openai' ? (_s.transcription?.model ?? '') : '',
  );
  final _key = TextEditingController();
  bool _changeKey = false;
  bool _busy = false;
  ({bool ok, String text})? _result;

  bool get _locked => _s.locked.contains('voice');
  SttProviderRow? get _cloud => sttProviders.where((p) => p.id == _kind).firstOrNull;
  bool _linked(String id) => _s.voiceKeys.contains(id);

  @override
  void dispose() {
    _url.dispose();
    _modelText.dispose();
    _key.dispose();
    super.dispose();
  }

  Map<String, Object?>? _body() {
    final cloud = _cloud;
    final k = _key.text.trim();
    return switch (_kind) {
      'local' => {'api': 'local', 'url': ''},
      'remote' => {'api': 'whisper-asr', 'url': _url.text.trim()},
      'compatible' => {
        'api': 'openai',
        'url': _url.text.trim(),
        if (_modelText.text.trim().isNotEmpty) 'model': _modelText.text.trim(),
        if (k.isNotEmpty) 'key': k,
      },
      _ when cloud != null => {
        'api': 'cloud',
        'url': '',
        'provider': cloud.id,
        'model': (cloud.models.where((m) => m.id == _model).firstOrNull ?? cloud.models.first).id,
        if (k.isNotEmpty) 'key': k,
      },
      _ => null,
    };
  }

  Future<void> _save() async {
    final l = AppLocalizations.of(context);
    final cloud = _cloud;
    final missing = (_kind == 'remote' || _kind == 'compatible') && _url.text.trim().isEmpty
        ? l.g4GenVoiceNeedsUrl
        : cloud != null && !_linked(cloud.id) && _key.text.trim().length < 8
        ? l.g4GenVoiceNeedsKey(cloud.name)
        : null;
    final b = _body();
    if (b == null || missing != null) {
      if (missing != null) setState(() => _result = (ok: false, text: missing));
      return;
    }
    setState(() {
      _busy = true;
      _result = null;
    });
    try {
      await AppScope.read(context).client!.setServices({'transcription': b});
      _key.clear();
      if (mounted) setState(() => _result = (ok: true, text: l.g4GenSaved));
    } on ApiException catch (e) {
      if (mounted) setState(() => _result = (ok: false, text: e.message));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final c = RgColors.of(context);
    final cloud = _cloud;
    final chosen = cloud == null
        ? null
        : (cloud.models.where((m) => m.id == _model).firstOrNull ?? cloud.models.first);
    void choose(String k) {
      if (_locked) return;
      setState(() {
        _kind = k;
        _result = null;
        _changeKey = false;
        _model = sttProviders.where((p) => p.id == k).firstOrNull?.models.first.id ?? '';
      });
    }

    return _PanelBody(
      lead: l.g4GenVoiceHelp,
      children: [
        if (_locked) NoteLine(icon: RgIcons.lock, text: l.g4GenLocked),
        _ChoiceCard(
          key: const Key('voice-kind-local'),
          title: l.g4GenSttLocal,
          text: l.g4GenSttLocalHelp,
          on: _kind == 'local',
          onTap: () => choose('local'),
        ),
        _ChoiceCard(
          key: const Key('voice-kind-remote'),
          title: l.g4GenSttRemote,
          text: l.g4GenSttRemoteHelp,
          on: _kind == 'remote',
          onTap: () => choose('remote'),
        ),
        for (final p in sttProviders)
          _ChoiceCard(
            key: Key('voice-kind-${p.id}'),
            title: p.name,
            text: l.g4GenSttCloudHelp(
              p.models.map((m) => m.label).join(', '),
              _priceText(l, p.models.first) ?? '',
            ),
            badge: _linked(p.id) ? l.g4GenHasKey : null,
            on: _kind == p.id,
            onTap: () => choose(p.id),
          ),
        _ChoiceCard(
          key: const Key('voice-kind-compatible'),
          title: l.g4GenSttCompatible,
          text: l.g4GenSttCompatibleHelp,
          on: _kind == 'compatible',
          onTap: () => choose('compatible'),
        ),
        if (_kind == 'local') NoteLine(icon: RgIcons.info, text: l.g4GenVoiceLocalHint),
        if (_kind == 'remote' || _kind == 'compatible')
          _field(
            context,
            key: const Key('voice-url'),
            controller: _url,
            label: l.g4GenVoiceUrl,
            hint: _kind == 'remote' ? 'http://192.168.1.20:9000' : 'http://192.168.1.20:8000/v1',
            enabled: !_locked,
          ),
        if (_kind == 'compatible') ...[
          _field(
            context,
            key: const Key('voice-model-text'),
            controller: _modelText,
            label: l.g4GenVoiceModel,
            hint: 'whisper-1',
            enabled: !_locked,
          ),
          _field(
            context,
            key: const Key('voice-key'),
            controller: _key,
            label: l.g4GenVoiceKey,
            help: _s.transcriptionKey ? l.g4GenAlreadySet : l.g4GenKeyHelp,
            secret: true,
            enabled: !_locked,
          ),
        ],
        if (cloud != null && chosen != null) ...[
          const SizedBox(height: 6),
          Text(
            l.g4GenVoiceModelHead,
            style: TextStyle(color: c.dim, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 8),
          ChoiceRow(
            keyPrefix: 'voice-model',
            values: [for (final m in cloud.models) m.id],
            selected: chosen.id,
            enabled: !_locked,
            label: (id) {
              final m = cloud.models.firstWhere((x) => x.id == id);
              final p = _priceText(l, m);
              return p == null ? m.label : '${m.label} · $p';
            },
            onChanged: (m) => setState(() => _model = m),
          ),
          if (chosen.closes != null)
            NoteLine(icon: RgIcons.alert, text: l.g4GenModelCloses(chosen.closes!)),
          if (_linked(cloud.id) && !_changeKey)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _Result(ok: true, text: l.g4GenKeyLinked(cloud.name)),
                  if (!_locked)
                    TextButton(
                      key: const Key('voice-key-change'),
                      onPressed: () => setState(() => _changeKey = true),
                      child: Text(l.g4GenKeyChange),
                    ),
                ],
              ),
            )
          else ...[
            _field(
              context,
              key: const Key('voice-key'),
              controller: _key,
              label: l.g4GenKeyLabel(cloud.name),
              help: l.g4GenKeyHelp,
              hint: cloud.keyExample,
              secret: true,
              enabled: !_locked,
            ),
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton.icon(
                onPressed: () => unawaited(openExternal(Uri.parse(cloud.keyUrl))),
                icon: RgIcon(RgIcons.external, size: 15, color: c.accent),
                label: Text(l.g4GenKeyGet(cloud.name)),
              ),
            ),
          ],
          NoteLine(icon: RgIcons.shield, text: l.g4GenCloudPrivacy(cloud.name)),
        ],
        if (_result != null)
          _Result(key: const Key('voice-result'), ok: _result!.ok, text: _result!.text),
        if (_kind != null && !_locked)
          Padding(
            padding: const EdgeInsets.only(top: 12),
            child: Align(
              alignment: Alignment.centerRight,
              child: FilledButton(
                key: const Key('voice-save'),
                onPressed: _busy ? null : _save,
                child: Text(l.save),
              ),
            ),
          ),
      ],
    );
  }
}

class _ImagesPanel extends StatefulWidget {
  const _ImagesPanel({required this.initial});

  final GeneralState initial;

  @override
  State<_ImagesPanel> createState() => _ImagesPanelState();
}

class _ImagesPanelState extends State<_ImagesPanel> {
  late final GeneralState _s = widget.initial;
  final _key = TextEditingController();
  late final _model = TextEditingController(text: _s.imagesModel ?? '');
  late bool _native = _s.mediaNative;
  String? _nativeError;

  Future<void> _setNative(bool on) async {
    setState(() {
      _native = on;
      _nativeError = null;
    });
    try {
      await AppScope.read(context).client!.setMediaNative(on);
    } on ApiException catch (e) {
      if (mounted) {
        setState(() {
          _native = !on;
          _nativeError = e.message;
        });
      }
    }
  }

  bool _busy = false;
  ({bool ok, String text})? _result;

  @override
  void dispose() {
    _key.dispose();
    _model.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final l = AppLocalizations.of(context);
    final key = _key.text.trim();
    final model = _model.text.trim();
    setState(() {
      _busy = true;
      _result = null;
    });
    try {
      await AppScope.read(context).client!.setServices({
        if (key.isNotEmpty || model != (_s.imagesModel ?? ''))
          'images': {if (key.isNotEmpty) 'key': key, if (model.isNotEmpty) 'model': model},
      });
      _key.clear();
      if (mounted) setState(() => _result = (ok: true, text: l.g4GenSaved));
    } on ApiException catch (e) {
      if (mounted) setState(() => _result = (ok: false, text: e.message));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final locked = _s.locked.contains('images');
    final c = RgColors.of(context);
    return _PanelBody(
      lead: l.g4GenImagesHelp,
      children: [
        // 2026-11-19: the model's own tool first (on by default), as the page's Generation.
        SettingsCard(
          children: [
            InkWell(
              key: const Key('media-native-switch'),
              onTap: () => _setNative(!_native),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Row(
                  spacing: 12,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        spacing: 2,
                        children: [
                          Text(
                            l.cvMediaNativeTitle,
                            style: TextStyle(color: c.text, fontWeight: FontWeight.w700),
                          ),
                          Text(l.cvMediaNativeHelp, style: TextStyle(color: c.dim, fontSize: 12.5)),
                        ],
                      ),
                    ),
                    RgSwitch(on: _native),
                  ],
                ),
              ),
            ),
          ],
        ),
        if (_nativeError != null) _Result(ok: false, text: l.errGeneric(_nativeError!)),
        const SizedBox(height: 12),
        if (locked) NoteLine(icon: RgIcons.lock, text: l.g4GenLocked),
        _field(
          context,
          key: const Key('images-key'),
          controller: _key,
          label: l.g4GenImagesKey,
          help: _s.imagesKey ? l.g4GenAlreadySet : null,
          hint: 'sk-…',
          secret: true,
          enabled: !locked,
        ),
        _field(
          context,
          key: const Key('images-model'),
          controller: _model,
          label: l.g4GenImagesModel,
          hint: 'gpt-image-2.5-flare',
          enabled: !locked,
        ),
        if (_result != null)
          _Result(key: const Key('images-result'), ok: _result!.ok, text: _result!.text),
        Padding(
          padding: const EdgeInsets.only(top: 12),
          child: Align(
            alignment: Alignment.centerRight,
            child: FilledButton(
              key: const Key('images-save'),
              onPressed: _busy || locked ? null : _save,
              child: Text(l.save),
            ),
          ),
        ),
      ],
    );
  }
}

class _DebugPanel extends StatefulWidget {
  const _DebugPanel({required this.initial});

  final DebugState initial;

  @override
  State<_DebugPanel> createState() => _DebugPanelState();
}

class _DebugPanelState extends State<_DebugPanel> {
  late DebugState _d = widget.initial;
  String? _error;
  String? _said;

  RedGiantClient get _c => AppScope.read(context).client!;

  Future<void> _do(Future<DebugState> Function() f) async {
    setState(() {
      _error = null;
      _said = null;
    });
    try {
      final d = await f();
      if (mounted) setState(() => _d = d);
    } on ApiException catch (e) {
      if (mounted) setState(() => _error = e.message);
    }
  }

  Future<void> _clear() async {
    final l = AppLocalizations.of(context);
    final ok = await askConfirm(
      context,
      title: l.g4GenDebugClear,
      body: l.g4GenDebugClearConfirm,
      yes: l.g4GenDebugClear,
      danger: true,
    );
    if (ok && mounted) await _do(_c.clearDebugLogs);
  }

  Future<void> _download() async {
    final l = AppLocalizations.of(context);
    try {
      final bytes = await _c.debugLogs();
      const name = 'rasgeth-logs.tar.gz';
      final saved =
          await (debugSaveLogs ??
              (n, b) async =>
                  await FilePicker.saveFile(fileName: n, bytes: b) != null)(name, bytes);
      if (mounted && saved) setState(() => _said = l.g4GenDebugSaved(name));
    } on ApiException catch (e) {
      if (mounted) setState(() => _error = e.message);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final c = RgColors.of(context);
    final size = l.g4GenDebugSize(_bytes(_d.bytes), '${_d.files}');
    return _PanelBody(
      lead: l.g4GenDebugHelp,
      children: [
        SettingsCard(
          children: [
            InkWell(
              key: const Key('debug-switch'),
              onTap: _d.forced ? null : () => _do(() => _c.setDebug(!_d.enabled)),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        spacing: 2,
                        children: [
                          Text(
                            l.g4GenDebugSwitch,
                            style: TextStyle(color: c.text, fontWeight: FontWeight.w700),
                          ),
                          Text(
                            _d.forced ? l.g4GenDebugForced : size,
                            key: const Key('debug-size'),
                            style: TextStyle(color: c.dim, fontSize: 12.5),
                          ),
                        ],
                      ),
                    ),
                    Opacity(
                      opacity: _d.forced ? .5 : 1,
                      child: RgSwitch(on: _d.enabled),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
        if (_d.forced)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(size, style: TextStyle(color: c.dim, fontSize: 12.5)),
          ),
        if (_error != null) _Result(ok: false, text: l.errGeneric(_error!)),
        if (_said != null) _Result(ok: true, text: _said!),
        const SizedBox(height: 14),
        Wrap(
          alignment: WrapAlignment.end,
          spacing: 8,
          runSpacing: 8,
          children: [
            OutlinedButton.icon(
              key: const Key('debug-clear'),
              onPressed: _d.files == 0 ? null : _clear,
              icon: RgIcon(RgIcons.trash, size: 16, color: _d.files == 0 ? c.line : c.err),
              label: Text(l.g4GenDebugClear),
            ),
            FilledButton.icon(
              key: const Key('debug-download'),
              onPressed: _d.files == 0 ? null : _download,
              icon: const RgIcon(RgIcons.download, size: 16, color: Colors.white),
              label: Text(l.g4GenDebugDownload),
            ),
          ],
        ),
      ],
    );
  }
}

/// «What's new», everything, release by release, newest first (the page's NewsWindow).
class NewsList extends StatelessWidget {
  const NewsList({super.key});

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final c = RgColors.of(context);
    final groups = newsSince(null, newsRows);
    return ListView(
      key: const Key('news-list'),
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
      children: [
        for (final g in groups) ...[
          Padding(
            padding: const EdgeInsets.only(top: 12, bottom: 8),
            child: Text(
              l.g4GenNewsVersion(g.version),
              style: TextStyle(color: c.dim, fontWeight: FontWeight.w800, fontSize: 13),
            ),
          ),
          for (final i in g.items)
            Container(
              key: Key('news-${i.title}'),
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: c.panel,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: c.line),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                spacing: 6,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                        margin: const EdgeInsets.only(right: 8, top: 1),
                        decoration: BoxDecoration(
                          color: c.accentSoft,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          g.version,
                          style: TextStyle(
                            color: c.accent,
                            fontSize: 11.5,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                      Expanded(
                        child: Text(
                          pageWord(context, i.title),
                          style: TextStyle(color: c.text, fontWeight: FontWeight.w800),
                        ),
                      ),
                    ],
                  ),
                  Text(
                    pageWord(context, i.text),
                    style: TextStyle(color: c.text, fontSize: 13.5, height: 1.4),
                  ),
                ],
              ),
            ),
        ],
      ],
    );
  }
}

// Settings › Code (G42.5), the page's `CodeSettings` with `GitCode.tsx`: where the code lives.
// GitHub and Gitea as the wizard's two squares, lit when linked, each opening its window: GitHub
// with the page's guide for a fine-grained token (which boxes to tick) and «Try and save», or the
// account linked and «Disconnect»; Gitea started here (user, password twice, the job followed
// with its steps and the download's bar) or one the person already has (address, user, token,
// with the page's words when the name or the address does not answer), then «Open Gitea» and
// «Switch off» or «Disconnect». With one of them, every project's repository made again where
// it is missing. The same routes; tokens and passwords go to the server and are never kept here.
import 'dart:async';

import 'package:flutter/material.dart';

import '../api/client.dart';
import '../api/code.dart';
import '../app_state.dart';
import '../l10n/app_localizations.dart';
import '../screens/first_start_screen.dart' show openExternal;
import '../theme/colors.dart';
import '../ui/chat/file_download.dart' show byteWords, shortDuration;
import '../ui/dialogs.dart';
import '../ui/icons.dart';
import '../ui/labeled_field.dart';
import '../ui/settings_kit.dart';

const _githubNewToken = 'https://github.com/settings/personal-access-tokens/new';

Future<void> openCodeSettings(BuildContext context) =>
    Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => const CodeSettingsScreen()));

/// What `GET /api/setup` says of git (`config.git`).
class GitSetup {
  const GitSetup({this.githubLogin, this.giteaUser, this.giteaUrl, this.giteaExternal = false});

  factory GitSetup.fromSetup(Map<String, dynamic> s) {
    final g = (s['config'] as Map?)?['git'];
    final gh = g is Map ? g['github'] : null;
    final gt = g is Map ? g['gitea'] : null;
    return GitSetup(
      githubLogin: gh is Map ? '${gh['login'] ?? ''}' : null,
      giteaUser: gt is Map ? '${gt['user'] ?? ''}' : null,
      giteaUrl: gt is Map ? '${gt['publicUrl'] ?? ''}' : null,
      giteaExternal: gt is Map && gt['external'] == true,
    );
  }

  final String? githubLogin;
  final String? giteaUser;
  final String? giteaUrl;
  final bool giteaExternal;

  bool get github => githubLogin != null;
  bool get gitea => giteaUser != null;
}

/// The host in what the person typed as Gitea's address (with or without https://).
String hostOf(String text) {
  final t = text.trim();
  final u = Uri.tryParse(
    RegExp(r'^[a-z][a-z0-9+.-]*://', caseSensitive: false).hasMatch(t) ? t : 'https://$t',
  );
  return (u?.host.isNotEmpty ?? false) ? u!.host : t;
}

final _giteaUser = RegExp(r'^[a-zA-Z0-9][a-zA-Z0-9_.-]{1,38}$');
final _externalUser = RegExp(r'^[a-zA-Z0-9][a-zA-Z0-9_.-]{0,39}$');

class CodeSettingsScreen extends StatefulWidget {
  const CodeSettingsScreen({super.key});

  @override
  State<CodeSettingsScreen> createState() => _CodeSettingsScreenState();
}

class _CodeSettingsScreenState extends State<CodeSettingsScreen> {
  GitSetup? _git;
  bool _failed = false;
  List<GitSyncRow>? _sync;
  bool _syncing = false;

  @override
  void initState() {
    super.initState();
    unawaited(_load());
  }

  Future<void> _load() async {
    final c = AppScope.read(context).client;
    if (c == null) return;
    try {
      final s = await c.setupState();
      if (mounted) {
        setState(() {
          _git = GitSetup.fromSetup(s);
          _failed = false;
        });
      }
    } on ApiException {
      if (mounted) setState(() => _failed = true);
    }
  }

  Future<void> _open(bool github) async {
    await showRgWindow<void>(
      context: context,
      builder: (_) => _GitWindow(github: github, git: _git ?? const GitSetup(), changed: _load),
    );
    await _load();
  }

  Future<void> _runSync() async {
    final c = AppScope.read(context).client;
    if (c == null) return;
    setState(() => _syncing = true);
    try {
      final r = await c.gitSync();
      if (mounted) setState(() => _sync = r);
    } on ApiException catch (e) {
      if (mounted) setState(() => _sync = [GitSyncRow(project: '', ok: false, error: e.message)]);
    } finally {
      if (mounted) setState(() => _syncing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final c = RgColors.of(context);
    final g = _git;
    return SettingsScaffold(
      title: l.csTitle,
      backKey: const Key('cs-back'),
      backLabel: l.back,
      listKey: const Key('cs-list'),
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 2),
          child: Text(
            l.csEyebrow.toUpperCase(),
            style: TextStyle(
              fontSize: 11.5,
              letterSpacing: .8,
              fontWeight: FontWeight.w700,
              color: c.accent,
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 4),
          child: Text(
            l.csQuestion,
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: c.text),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
          child: Text(l.csPurpose, style: TextStyle(color: c.dim, fontSize: 14, height: 1.4)),
        ),
        if (_failed) NoticeBanner(text: l.codeLoadFailed, error: true),
        if (g == null && !_failed)
          const Padding(
            padding: EdgeInsets.all(24),
            child: Center(child: RgSpinner(size: 22)),
          ),
        if (g != null) ...[
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 6, 16, 0),
            child: LayoutBuilder(
              builder: (context, box) {
                final tiles = [
                  _Tile(
                    key: const Key('cs-github'),
                    on: g.github,
                    icon: RgIcons.cloud,
                    title: 'GitHub',
                    text: l.csGithubTile,
                    state: g.github ? l.csLinked : null,
                    onTap: () => _open(true),
                  ),
                  _Tile(
                    key: const Key('cs-gitea'),
                    on: g.gitea,
                    icon: RgIcons.server,
                    title: l.csGiteaTitle,
                    text: l.csGiteaTile,
                    state: g.gitea ? l.csLinked : null,
                    onTap: () => _open(false),
                  ),
                ];
                if (box.maxWidth < 520) {
                  return Column(children: [tiles[0], const SizedBox(height: 10), tiles[1]]);
                }
                return IntrinsicHeight(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Expanded(child: tiles[0]),
                      const SizedBox(width: 10),
                      Expanded(child: tiles[1]),
                    ],
                  ),
                );
              },
            ),
          ),
          if (g.github && g.gitea) NoteLine(icon: RgIcons.info, text: l.csBoth),
          if (g.github || g.gitea) ...[
            SectionHead(l.csProjects),
            NoteLine(icon: RgIcons.box, text: l.csProjectsHint),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
              child: Align(
                alignment: Alignment.centerLeft,
                child: FilledButton.icon(
                  key: const Key('cs-sync'),
                  onPressed: _syncing ? null : _runSync,
                  icon: _syncing
                      ? const RgSpinner(size: 16, color: Colors.white)
                      : const RgIcon(RgIcons.gitBranch, size: 16, color: Colors.white),
                  label: Text(l.csSync),
                ),
              ),
            ),
            if (_sync != null)
              Padding(
                padding: const EdgeInsets.only(top: 10),
                child: SettingsCard(
                  key: const Key('cs-sync-list'),
                  children: [
                    if (_sync!.isEmpty) NoteLine(icon: RgIcons.box, text: l.psNone),
                    for (final r in _sync!)
                      NoteLine(
                        icon: r.ok ? RgIcons.check : RgIcons.alert,
                        color: r.ok ? c.ok : c.err,
                        strong: true,
                        text: [
                          if (r.project.isNotEmpty) r.project,
                          r.ok ? l.csSynced : (r.error ?? l.cmFailed),
                        ].join(' · '),
                      ),
                  ],
                ),
              ),
          ],
        ],
      ],
    );
  }
}

/// One of the two squares (the wizard's `Tile`): lit and marked «connected» when linked.
class _Tile extends StatelessWidget {
  const _Tile({
    super.key,
    required this.on,
    required this.icon,
    required this.title,
    required this.text,
    required this.onTap,
    this.state,
  });

  final bool on;
  final RgIcons icon;
  final String title;
  final String text;
  final String? state;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = RgColors.of(context);
    return Semantics(
      button: true,
      selected: on,
      child: Material(
        color: on ? c.accentSoft : c.panel,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: on ? c.accent : c.line, width: on ? 1.5 : 1),
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: on ? c.accent : c.panel2,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  alignment: Alignment.center,
                  child: RgIcon(icon, size: 21, color: on ? Colors.white : c.dim),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16, color: c.text),
                      ),
                      const SizedBox(height: 3),
                      Text(text, style: TextStyle(color: c.dim, fontSize: 13, height: 1.35)),
                      if (state != null) ...[
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            RgIcon(RgIcons.check, size: 14, color: c.ok),
                            const SizedBox(width: 4),
                            Text(
                              state!,
                              style: TextStyle(
                                color: c.ok,
                                fontWeight: FontWeight.w700,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
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

/// The window of one square: GitHub or Gitea, with «Done» at the bottom.
class _GitWindow extends StatefulWidget {
  const _GitWindow({required this.github, required this.git, required this.changed});

  final bool github;
  final GitSetup git;
  final Future<void> Function() changed;

  @override
  State<_GitWindow> createState() => _GitWindowState();
}

class _GitWindowState extends State<_GitWindow> {
  late GitSetup _git = widget.git;

  Future<void> _reload() async {
    final c = AppScope.read(context).client;
    await widget.changed();
    if (c == null) return;
    try {
      final s = await c.setupState();
      if (mounted) setState(() => _git = GitSetup.fromSetup(s));
    } on ApiException {
      // The window keeps what it had.
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return AlertDialog(
      key: Key(widget.github ? 'cs-window-github' : 'cs-window-gitea'),
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      title: Text(widget.github ? 'GitHub' : l.csGiteaTitle),
      content: SizedBox(
        width: 480,
        child: SingleChildScrollView(
          child: widget.github
              ? GithubPanel(git: _git, changed: _reload)
              : GiteaPanel(git: _git, changed: _reload),
        ),
      ),
      actions: [
        FilledButton(
          key: const Key('cs-done'),
          onPressed: () => Navigator.of(context).pop(),
          child: Text(l.csDone),
        ),
      ],
    );
  }
}

/// A line of text in a window, dim.
class _Help extends StatelessWidget {
  const _Help(this.text);

  final String text;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 10),
    child: Text(
      text,
      style: TextStyle(color: RgColors.of(context).dim, fontSize: 13.5, height: 1.4),
    ),
  );
}

/// A linked account: the green line and its buttons.
class _Linked extends StatelessWidget {
  const _Linked({required this.text, required this.actions});

  final String text;
  final List<Widget> actions;

  @override
  Widget build(BuildContext context) {
    final c = RgColors.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          key: const Key('cs-linked'),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: c.ok.withValues(alpha: .08),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: c.ok.withValues(alpha: .35)),
          ),
          child: Row(
            children: [
              RgIcon(RgIcons.check, size: 16, color: c.ok),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  text,
                  style: TextStyle(color: c.text, fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Wrap(spacing: 8, runSpacing: 6, children: actions),
      ],
    );
  }
}

class _Error extends StatelessWidget {
  const _Error(this.text);

  final String text;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(top: 10),
    child: Text(
      text,
      key: const Key('cs-error'),
      style: TextStyle(color: RgColors.of(context).err),
    ),
  );
}

/// GitHub: the guide for a fine-grained token, or the account linked.
class GithubPanel extends StatefulWidget {
  const GithubPanel({super.key, required this.git, required this.changed});

  final GitSetup git;
  final Future<void> Function() changed;

  @override
  State<GithubPanel> createState() => _GithubPanelState();
}

class _GithubPanelState extends State<GithubPanel> {
  final _token = TextEditingController();
  bool _busy = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _token.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _token.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final c = AppScope.read(context).client;
    if (c == null) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await c.setupGithub(_token.text.trim());
      _token.clear();
      await widget.changed();
    } on ApiException catch (e) {
      if (mounted) setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _remove() async {
    final c = AppScope.read(context).client;
    if (c == null) return;
    try {
      await c.removeGithub();
      await widget.changed();
    } on ApiException catch (e) {
      if (mounted) setState(() => _error = e.message);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final c = RgColors.of(context);
    final login = widget.git.githubLogin;
    Widget step(int n, Widget child) => Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(color: c.accentSoft, shape: BoxShape.circle),
            alignment: Alignment.center,
            child: Text(
              '$n',
              style: TextStyle(color: c.accent, fontWeight: FontWeight.w800, fontSize: 12.5),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(child: child),
        ],
      ),
    );
    return Column(
      key: const Key('cs-github-panel'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _Help(l.csGithubHint),
        if (login != null)
          _Linked(
            text: l.csGithubLinked(login),
            actions: [
              TextButton(
                key: const Key('cs-github-remove'),
                onPressed: _remove,
                child: Text(l.csDisconnect),
              ),
            ],
          )
        else ...[
          step(
            1,
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(l.csGithubStep1, style: TextStyle(color: c.text)),
                const SizedBox(height: 6),
                OutlinedButton.icon(
                  key: const Key('cs-github-open'),
                  onPressed: () => unawaited(openExternal(Uri.parse(_githubNewToken))),
                  icon: RgIcon(RgIcons.external, size: 15, color: c.accent),
                  label: Text(l.csGithubOpen),
                ),
              ],
            ),
          ),
          step(
            2,
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(l.csGithubStep2, style: TextStyle(color: c.text)),
                const SizedBox(height: 4),
                for (final p in [l.csPermName, l.csPermExpiry, l.csPermRepos, l.csPermList])
                  Padding(
                    padding: const EdgeInsets.only(top: 3),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.only(top: 7, right: 8),
                          child: Container(
                            width: 5,
                            height: 5,
                            decoration: BoxDecoration(color: c.dim, shape: BoxShape.circle),
                          ),
                        ),
                        Expanded(
                          child: Text(p, style: TextStyle(color: c.dim, fontSize: 13.5)),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
          step(
            3,
            Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(l.csGithubStep3, style: TextStyle(color: c.text)),
                const SizedBox(height: 6),
                TextField(
                  key: const Key('cs-github-token'),
                  controller: _token,
                  obscureText: true,
                  autocorrect: false,
                  enableSuggestions: false,
                  enabled: !_busy,
                  decoration: fieldDecoration(c, hint: 'github_pat_…'),
                ),
                const SizedBox(height: 4),
                Text(l.csGithubTokenHelp, style: TextStyle(fontSize: 12.5, color: c.dim)),
                const SizedBox(height: 10),
                Align(
                  alignment: Alignment.centerLeft,
                  child: FilledButton(
                    key: const Key('cs-github-save'),
                    onPressed: _busy || _token.text.trim().length < 20 ? null : _save,
                    child: _busy
                        ? const RgSpinner(size: 16, color: Colors.white)
                        : Text(l.csTryAndSave),
                  ),
                ),
              ],
            ),
          ),
        ],
        if (_error != null) _Error(_error!),
      ],
    );
  }
}

/// Gitea: started here, or one the person has; then open it, switch it off or disconnect.
class GiteaPanel extends StatefulWidget {
  const GiteaPanel({super.key, required this.git, required this.changed, this.every});

  final GitSetup git;
  final Future<void> Function() changed;

  /// How often the job is read again (tests: shorter).
  final Duration? every;

  @override
  State<GiteaPanel> createState() => _GiteaPanelState();
}

class _GiteaPanelState extends State<GiteaPanel> {
  final _user = TextEditingController();
  final _password = TextEditingController();
  final _again = TextEditingController();
  final _url = TextEditingController();
  final _extUser = TextEditingController();
  final _token = TextEditingController();
  bool _existing = false;
  bool _busy = false;
  String? _error;
  JobView? _job;
  Timer? _poll;

  @override
  void initState() {
    super.initState();
    for (final t in [_user, _password, _again, _url, _extUser, _token]) {
      t.addListener(() => setState(() {}));
    }
  }

  @override
  void dispose() {
    _poll?.cancel();
    for (final t in [_user, _password, _again, _url, _extUser, _token]) {
      t.dispose();
    }
    super.dispose();
  }

  RedGiantClient? get _client => AppScope.read(context).client;

  Future<void> _start() async {
    final c = _client;
    if (c == null) return;
    setState(() {
      _error = null;
      _busy = true;
    });
    try {
      final j = await c.startGitea(_user.text.trim(), _password.text);
      _password.clear();
      _again.clear();
      if (!mounted) return;
      setState(() => _job = j);
      _follow(j.id);
    } on ApiException catch (e) {
      if (mounted) setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  /// The job read every second until it ends, as the page's `useJob`; done: the settings again.
  void _follow(String id) {
    _poll?.cancel();
    _poll = Timer.periodic(widget.every ?? const Duration(seconds: 1), (t) async {
      final c = _client;
      if (c == null) return;
      try {
        final j = await c.job(id);
        if (!mounted) return;
        setState(() => _job = j);
        if (!j.running) {
          t.cancel();
          if (j.state == 'done') await widget.changed();
        }
      } on ApiException {
        // Read again at the next tick.
      }
    });
  }

  Future<void> _connect() async {
    final l = AppLocalizations.of(context);
    final c = _client;
    if (c == null) return;
    setState(() {
      _error = null;
      _busy = true;
    });
    try {
      await c.connectGitea(_url.text.trim(), _extUser.text.trim(), _token.text.trim());
      _token.clear();
      await widget.changed();
    } on ApiException catch (e) {
      final host = hostOf(_url.text);
      if (mounted) {
        setState(
          () => _error = e.code == 'name_not_found'
              ? l.csGiteaNameNotFound(host)
              : e.code == 'host_unreachable'
              ? l.csGiteaHostUnreachable(host)
              : e.message,
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _stop() async {
    final c = _client;
    if (c == null) return;
    try {
      await c.stopGitea();
      await widget.changed();
    } on ApiException catch (e) {
      if (mounted) setState(() => _error = e.message);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final c = RgColors.of(context);
    final g = widget.git;
    final job = _job;
    Widget field(
      TextEditingController t,
      String label, {
      String? help,
      String? error,
      bool secret = false,
      required Key key,
      String? hint,
    }) => LabeledField(
      label: label,
      controller: t,
      help: help,
      error: error,
      secret: secret,
      fieldKey: key,
      hint: hint,
      enabled: !_busy,
    );
    final Widget body;
    if (g.gitea) {
      final url = g.giteaUrl ?? '';
      body = _Linked(
        text: g.giteaExternal
            ? l.csGiteaLinked(url, g.giteaUser ?? '')
            : l.csGiteaReady(g.giteaUser ?? ''),
        actions: [
          if (url.isNotEmpty)
            OutlinedButton.icon(
              key: const Key('cs-gitea-open'),
              onPressed: () => unawaited(openExternal(Uri.parse(url))),
              icon: RgIcon(RgIcons.external, size: 15, color: c.accent),
              label: Text(l.csGiteaOpen),
            ),
          TextButton(
            key: const Key('cs-gitea-stop'),
            onPressed: _stop,
            child: Text(g.giteaExternal ? l.csDisconnect : l.csGiteaStop),
          ),
        ],
      );
    } else if (job?.running ?? false) {
      body = const SizedBox.shrink();
    } else {
      final validOwn =
          _giteaUser.hasMatch(_user.text.trim()) &&
          _password.text.length >= 10 &&
          _again.text == _password.text;
      final validExt =
          _url.text.trim().length >= 3 &&
          _externalUser.hasMatch(_extUser.text.trim()) &&
          _token.text.trim().length >= 8;
      body = Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(l.csGiteaKind, style: TextStyle(color: c.dim, fontSize: 13)),
          const SizedBox(height: 4),
          Material(
            color: c.panel2,
            clipBehavior: Clip.antiAlias,
            borderRadius: BorderRadius.circular(12),
            child: Column(
              children: [
                PickRow(
                  key: const Key('cs-gitea-own'),
                  title: l.csGiteaKindOwn,
                  leading: RgIcon(RgIcons.server, size: 18, color: c.accent),
                  selected: !_existing,
                  onTap: () => setState(() => _existing = false),
                ),
                PickRow(
                  key: const Key('cs-gitea-existing'),
                  title: l.csGiteaKindExisting,
                  leading: RgIcon(RgIcons.link, size: 18, color: c.dim),
                  selected: _existing,
                  onTap: () => setState(() => _existing = true),
                ),
              ],
            ),
          ),
          if (_existing) ...[
            field(
              _url,
              l.csGiteaUrl,
              help: l.csGiteaUrlHelp,
              hint: 'https://git.example.org',
              key: const Key('cs-gitea-url'),
            ),
            field(_extUser, l.csGiteaExtUser, key: const Key('cs-gitea-ext-user')),
            field(
              _token,
              l.csGiteaToken,
              help: l.csGiteaTokenHelp,
              secret: true,
              key: const Key('cs-gitea-token'),
            ),
            const SizedBox(height: 12),
            Align(
              alignment: Alignment.centerLeft,
              child: FilledButton(
                key: const Key('cs-gitea-connect'),
                onPressed: _busy || !validExt ? null : _connect,
                child: _busy
                    ? const RgSpinner(size: 16, color: Colors.white)
                    : Text(l.csGiteaConnect),
              ),
            ),
          ] else ...[
            field(_user, l.csGiteaUser, help: l.csGiteaUserHelp, key: const Key('cs-gitea-user')),
            field(
              _password,
              l.csGiteaPassword,
              help: l.csGiteaPasswordHelp,
              secret: true,
              key: const Key('cs-gitea-password'),
            ),
            field(
              _again,
              l.csGiteaAgain,
              secret: true,
              error: _again.text.isNotEmpty && _again.text != _password.text
                  ? l.csGiteaMismatch
                  : null,
              key: const Key('cs-gitea-again'),
            ),
            const SizedBox(height: 12),
            Align(
              alignment: Alignment.centerLeft,
              child: FilledButton(
                key: const Key('cs-gitea-create'),
                onPressed: _busy || !validOwn ? null : _start,
                child: _busy
                    ? const RgSpinner(size: 16, color: Colors.white)
                    : Text(l.csGiteaCreate),
              ),
            ),
          ],
        ],
      );
    }
    return Column(
      key: const Key('cs-gitea-panel'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _Help(l.csGiteaHint),
        body,
        if (job != null)
          Padding(
            padding: const EdgeInsets.only(top: 14),
            child: JobSteps(job: job),
          ),
        if (_error != null) _Error(_error!),
      ],
    );
  }
}

/// A job followed (the page's `JobView`): its title, each step with its mark (a dot, filled once
/// done; a spinner while it runs; an X when it fails), a download's bar with how much, how fast
/// and how long still, then «Done.» or what went wrong.
class JobSteps extends StatelessWidget {
  const JobSteps({super.key, required this.job});

  final JobView job;

  String _step(AppLocalizations l, String id) => switch (id) {
    'gitea_image' => l.csJobGiteaImage,
    'gitea_start' => l.csJobGiteaStart,
    'account' => l.csJobAccount,
    _ => id,
  };

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final c = RgColors.of(context);
    final lang = Localizations.localeOf(context).languageCode;
    return Container(
      key: const Key('cs-job'),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: c.panel2,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: job.state == 'failed' ? c.err.withValues(alpha: .4) : c.line),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            job.kind == 'gitea' ? l.csJobGitea : job.kind,
            style: TextStyle(fontWeight: FontWeight.w700, color: c.text),
          ),
          const SizedBox(height: 6),
          for (final s in job.steps)
            Padding(
              key: Key('cs-job-step-${s.id}'),
              padding: const EdgeInsets.symmetric(vertical: 4),
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
                        _ => Container(
                          width: 9,
                          height: 9,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: s.state == 'done' ? c.ok : Colors.transparent,
                            border: Border.all(color: s.state == 'done' ? c.ok : c.dim, width: 1.5),
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
                          [_step(l, s.id), if (s.state == 'skipped') l.csNotNeeded].join(' · '),
                          style: TextStyle(
                            color: s.state == 'waiting' || s.state == 'skipped' ? c.dim : c.text,
                          ),
                        ),
                        if (s.done != null && s.state == 'running') ...[
                          const SizedBox(height: 6),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(3),
                            child: LinearProgressIndicator(
                              key: Key('cs-job-bar-${s.id}'),
                              value: s.total == null || s.total == 0 ? null : s.done! / s.total!,
                              minHeight: 5,
                              color: c.accent,
                              backgroundColor: c.line,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            s.total == null
                                ? l.chatFileDownloadSoFar(
                                    byteWords(s.done!, lang),
                                    byteWords((s.rate ?? 0).round(), lang),
                                  )
                                : l.chatFileDownloadOf(
                                    byteWords(s.done!, lang),
                                    byteWords(s.total!, lang),
                                    byteWords((s.rate ?? 0).round(), lang),
                                    s.secondsLeft == null
                                        ? '…'
                                        : shortDuration(Duration(seconds: s.secondsLeft!)),
                                  ),
                            key: Key('cs-job-words-${s.id}'),
                            style: TextStyle(fontSize: 12.5, color: c.dim),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
          if (job.state == 'done')
            Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Text(
                l.csJobDone,
                style: TextStyle(color: c.ok, fontWeight: FontWeight.w600),
              ),
            ),
          if (job.state == 'failed')
            Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(l.csJobFailed, style: TextStyle(color: c.err)),
                  if ((job.errorMessage ?? '').isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: SelectableText(
                        job.errorMessage!,
                        style: TextStyle(fontSize: 12, color: c.dim),
                      ),
                    ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

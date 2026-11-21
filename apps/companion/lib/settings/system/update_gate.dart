// Mandatory and breaking updates (G42.14), the page's UpdateGate.tsx. Mandatory: a screen that does
// not close, «Update now» (followed as Settings › Updates does) or «Close RedGiant», or the steps
// for where the app cannot update it (Docker's command, the Mac's download, from source); until
// then agents and automations wait. Breaking: it explains in plain words, makes a full backup by
// itself into a folder the person can see, reads it back and says where it is (the keychain
// sealed with a passphrase if the person wants it in), then walks through uninstalling, installing
// the new version and restoring (the new wizard finds the backup). «Later» closes it until the
// app connects again. Opened by itself when the app connects (home_shell) and from Settings.
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../api/client.dart';
import '../../api/settings_types.dart';
import '../../app_state.dart';
import '../../l10n/app_localizations.dart';
import '../../screens/first_start_screen.dart' show openExternal;
import '../../screens/update_screen.dart' show openUpdateScreen;
import '../../theme/colors.dart';
import '../../ui/chat/file_download.dart' show byteWords;
import '../../ui/icons.dart';
import '../api/system_api.dart';
import 'system_kit.dart';

/// Whether the gate's screen is showing now (it opens once).
bool updateGateOpen = false;

/// The gate for [s] (mandatory or breaking), once.
Future<void> openUpdateGate(BuildContext context, UpdateStatus s) async {
  if (updateGateOpen || (s.gate != 'mandatory' && s.gate != 'breaking')) return;
  updateGateOpen = true;
  try {
    await Navigator.of(
      context,
    ).push(MaterialPageRoute<void>(fullscreenDialog: true, builder: (_) => UpdateGateScreen(s: s)));
  } finally {
    updateGateOpen = false;
  }
}

class UpdateGateScreen extends StatelessWidget {
  const UpdateGateScreen({super.key, required this.s});

  final UpdateStatus s;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final c = RgColors.of(context);
    final mandatory = s.gate == 'mandatory';
    final v = {'version': s.latest ?? '', 'installed': s.installed ?? ''};
    return PopScope(
      canPop: !mandatory,
      child: Scaffold(
        appBar: AppBar(
          automaticallyImplyLeading: false,
          leading: mandatory
              ? Padding(
                  padding: const EdgeInsets.all(14),
                  child: RgIcon(RgIcons.lock, color: c.accent),
                )
              : IconButton(
                  key: const Key('sy-gate-later-x'),
                  tooltip: l.syUpdLater,
                  onPressed: () => Navigator.of(context).pop(),
                  icon: RgIcon(RgIcons.x, color: c.text),
                ),
          title: Text(mandatory ? l.syUpdReqTitle : l.syUpdBrkTitle),
        ),
        body: Align(
          alignment: Alignment.topCenter,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 680),
            child: ListView(
              key: const Key('sy-gate'),
              padding: const EdgeInsets.only(bottom: 24),
              children: [
                SysHead(
                  q: mandatory ? l.syUpdReqTitle : l.syUpdBrkTitle,
                  lead: sw(l, mandatory ? 'updReqSub' : 'updBrkSub', v),
                ),
                if (mandatory) _Mandatory(s: s) else _Breaking(s: s),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// A command to copy (the page's `Command`).
class _Command extends StatefulWidget {
  const _Command({required this.text});

  final String text;

  @override
  State<_Command> createState() => _CommandState();
}

class _CommandState extends State<_Command> {
  bool _copied = false;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final c = RgColors.of(context);
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 6),
      padding: const EdgeInsets.fromLTRB(10, 4, 4, 4),
      decoration: BoxDecoration(
        color: c.bg,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: c.line),
      ),
      child: Row(
        children: [
          Expanded(child: SysMono(widget.text)),
          TextButton.icon(
            onPressed: () async {
              await Clipboard.setData(ClipboardData(text: widget.text));
              if (mounted) setState(() => _copied = true);
            },
            icon: RgIcon(RgIcons.copy, size: 14, color: c.accent),
            label: Text(_copied ? l.syUpdCopied : l.syUpdCopy),
          ),
        ],
      ),
    );
  }
}

class _Mandatory extends StatefulWidget {
  const _Mandatory({required this.s});

  final UpdateStatus s;

  @override
  State<_Mandatory> createState() => _MandatoryState();
}

class _MandatoryState extends State<_Mandatory> {
  bool _busy = false;
  String? _said;
  String? _error;

  Future<void> _act(String action) async {
    final l = AppLocalizations.of(context);
    final c = sysClient(context);
    final s = widget.s;
    if (c == null) return;
    setState(() => _busy = true);
    try {
      if (action == 'update') {
        final app = AppScope.read(context);
        unawaited(app.startUpdate(from: s.installed, to: s.latest, note: s.note));
        if (mounted)
          setState(() => _said = s.install == 'os' ? l.syUpdReqUpdatingOs : l.syUpdReqUpdating);
        await openUpdateScreen(context);
      } else {
        await c.updateAct(action);
        if (mounted) setState(() => _said = l.syUpdReqClosing);
      }
    } on ApiException catch (e) {
      if (mounted) setState(() => _error = sysError(l, e));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final s = widget.s;
    final lang = Localizations.localeOf(context).languageCode;
    final note = s.noteIn(lang);
    final v = {'version': s.latest ?? '', 'installed': s.installed ?? ''};
    final buttons = <Widget>[
      if (s.install == 'os' && s.canUpdateHere)
        FilledButton.icon(
          key: const Key('sy-gate-update'),
          onPressed: _busy ? null : () => _act('update'),
          icon: const RgIcon(RgIcons.download, size: 16, color: Colors.white),
          label: Text(l.syUpdReqNow),
        )
      else if (s.install == 'windows' && s.canUpdateHere) ...[
        OutlinedButton(
          key: const Key('sy-gate-quit'),
          onPressed: _busy ? null : () => _act('quit'),
          child: Text(l.syUpdReqClose),
        ),
        FilledButton.icon(
          key: const Key('sy-gate-update'),
          onPressed: _busy ? null : () => _act('update'),
          icon: const RgIcon(RgIcons.download, size: 16, color: Colors.white),
          label: Text(l.syUpdReqNow),
        ),
      ] else if (s.install == 'mac') ...[
        OutlinedButton(
          key: const Key('sy-gate-quit'),
          onPressed: _busy ? null : () => _act('quit'),
          child: Text(l.syUpdReqClose),
        ),
        if (s.downloadUrl != null)
          FilledButton.icon(
            onPressed: () => unawaited(openExternal(Uri.parse(s.downloadUrl!))),
            icon: const RgIcon(RgIcons.download, size: 16, color: Colors.white),
            label: Text(l.syUpdDownloadNew),
          ),
      ] else
        FilledButton.icon(
          key: const Key('sy-gate-again'),
          onPressed: () async {
            final c = sysClient(context);
            if (c == null) return;
            try {
              final st = await c.updateLook();
              if (st.gate != 'mandatory' && context.mounted) Navigator.of(context).pop();
            } on ApiException catch (e) {
              if (mounted) setState(() => _error = sysError(l, e));
            }
          },
          icon: const RgIcon(RgIcons.refresh, size: 16, color: Colors.white),
          label: Text(l.syUpdReqAgain),
        ),
    ];
    return SysBox(
      children: [
        SysText(sw(l, 'updReqLead', v), dim: false),
        if (note != null && note.isNotEmpty) SysNote(icon: RgIcons.file, text: note),
        SysText(l.syUpdReqSafe),
        if (s.install == 'mac') SysText(l.syUpdReqMac, dim: false),
        if (s.install == 'docker' && s.command != null) ...[
          SysText(l.syUpdReqDocker, dim: false),
          _Command(text: s.command!),
        ],
        if (s.install == 'source') SysText(l.syUpdReqSource, dim: false),
        if (s.install == 'windows' && s.downloadUrl != null)
          TextButton.icon(
            onPressed: () => unawaited(openExternal(Uri.parse(s.downloadUrl!))),
            icon: RgIcon(RgIcons.external, size: 14, color: RgColors.of(context).accent),
            label: Text('${l.syUpdReqInstaller} ${l.syUpdReqInstallerLink}'),
          ),
        if (_said != null) SysNote(tone: 'ok', icon: RgIcons.check, text: _said!),
        if (_error != null) SysSaid(text: _error!),
        SysActs(children: buttons),
      ],
    );
  }
}

class _Breaking extends StatefulWidget {
  const _Breaking({required this.s});

  final UpdateStatus s;

  @override
  State<_Breaking> createState() => _BreakingState();
}

class _BreakingState extends State<_Breaking> {
  String _step = 'backup';
  String? _jobId;
  String? _jobState;
  Map<String, String> _vars = const {};
  int _keys = 0;
  bool _asked = false;
  final _pass = TextEditingController();
  bool _sure = false;
  String? _said;
  String? _error;

  @override
  void initState() {
    super.initState();
    // The backup starts by itself: nobody has to remember it.
    unawaited(_start());
    unawaited(() async {
      final c = sysClient(context);
      if (c == null) return;
      try {
        final n = await c.vaultCount();
        if (mounted) setState(() => _keys = n);
      } on ApiException {
        // No keychain to speak of.
      }
    }());
  }

  @override
  void dispose() {
    _pass.dispose();
    super.dispose();
  }

  Future<void> _start([String? passphrase]) async {
    final c = sysClient(context);
    if (c == null) return;
    try {
      final j = await c.safetyBackup(passphrase);
      if (mounted) {
        setState(() {
          _jobId = j.id;
          _jobState = 'running';
        });
      }
    } on ApiException catch (e) {
      if (mounted) setState(() => _error = sysError(AppLocalizations.of(context), e));
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final c = RgColors.of(context);
    final s = widget.s;
    final lang = Localizations.localeOf(context).languageCode;
    final note = s.noteIn(lang);
    final v = {'version': s.latest ?? '', 'installed': s.installed ?? ''};
    final done = _jobState == 'done';
    final withKeys = _vars['keychain'] == 'true';
    if (_step == 'guide') {
      final step1 = switch (s.install) {
        'windows' => l.syUpdBrkStep1Win,
        'mac' => l.syUpdBrkStep1Mac,
        'docker' => l.syUpdBrkStep1Docker,
        'os' => l.syUpdBrkStep1Os,
        _ => l.syUpdBrkStep1Source,
      };
      return SysBox(
        key: const Key('sy-gate-guide'),
        children: [
          SysSteps(
            steps: [
              (
                l.syUpdBrkStep1,
                [
                  SysText(step1),
                  if (s.install == 'docker') const _Command(text: 'docker compose down -v'),
                  if (s.canUninstall)
                    if (_sure) ...[
                      SysText(sw(l, 'updBrkSure', {'folder': _vars['folder'] ?? ''}), dim: false),
                      SysActs(
                        start: true,
                        children: [
                          TextButton(
                            onPressed: () => setState(() => _sure = false),
                            child: Text(l.syCancel),
                          ),
                          FilledButton(
                            key: const Key('sy-gate-uninstall-yes'),
                            onPressed: () async {
                              final cl = sysClient(context);
                              if (cl == null) return;
                              try {
                                await cl.updateAct('uninstall');
                                if (mounted) setState(() => _said = l.syUpdBrkUninstalling);
                              } on ApiException catch (e) {
                                if (mounted) setState(() => _error = sysError(l, e));
                              }
                            },
                            child: Text(l.syUpdBrkUninstallYes),
                          ),
                        ],
                      ),
                    ] else
                      Align(
                        alignment: Alignment.centerLeft,
                        child: OutlinedButton(
                          key: const Key('sy-gate-uninstall'),
                          onPressed: () => setState(() => _sure = true),
                          child: Text(l.syUpdBrkUninstall),
                        ),
                      ),
                  if (_said != null) SysNote(tone: 'ok', icon: RgIcons.check, text: _said!),
                ],
              ),
              (
                sw(l, 'updBrkStep2', v),
                [
                  if (s.downloadUrl != null)
                    Align(
                      alignment: Alignment.centerLeft,
                      child: FilledButton.icon(
                        onPressed: () => unawaited(openExternal(Uri.parse(s.downloadUrl!))),
                        icon: const RgIcon(RgIcons.download, size: 16, color: Colors.white),
                        label: Text(l.syUpdDownloadNew),
                      ),
                    )
                  else if (s.command != null)
                    _Command(text: s.command!),
                ],
              ),
              (
                l.syUpdBrkStep3,
                [
                  SysText(switch (s.install) {
                    'docker' => l.syUpdBrkStep3Docker,
                    'os' => l.syUpdBrkStep3Os,
                    _ => l.syUpdBrkStep3Text,
                  }),
                ],
              ),
            ],
          ),
          if (_error != null) SysSaid(text: _error!),
          SysActs(
            children: [
              OutlinedButton(
                onPressed: () => setState(() => _step = 'backup'),
                child: Text(l.syWzBack),
              ),
              FilledButton(
                key: const Key('sy-gate-done'),
                onPressed: () => Navigator.of(context).pop(),
                child: Text(l.syUpdBrkDone),
              ),
            ],
          ),
        ],
      );
    }
    return SysBox(
      key: const Key('sy-gate-backup'),
      children: [
        SysText(sw(l, 'updBrkLead', v), dim: false),
        if (note != null && note.isNotEmpty) SysNote(icon: RgIcons.file, text: note),
        SysText(l.syUpdBrkWhy),
        if (_jobId != null)
          Offstage(
            offstage: done,
            child: SysJob(
              id: _jobId!,
              showDone: false,
              onUpdate: (j, vars) {
                if (mounted) setState(() => _vars = vars);
              },
              onEnd: (state, vars) {
                if (mounted) {
                  setState(() {
                    _jobState = state;
                    _vars = vars;
                  });
                }
              },
            ),
          ),
        if (_jobState == 'failed')
          Align(
            alignment: Alignment.centerLeft,
            child: OutlinedButton.icon(
              key: const Key('sy-gate-retry'),
              onPressed: () => _start(),
              icon: RgIcon(RgIcons.refresh, size: 16, color: c.text),
              label: Text(l.syUpdBrkRetry),
            ),
          ),
        if (done)
          Container(
            key: const Key('sy-gate-where'),
            margin: const EdgeInsets.symmetric(vertical: 8),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: c.ok.withValues(alpha: .08),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: c.ok.withValues(alpha: .35)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  l.syUpdBrkSaved,
                  style: TextStyle(fontWeight: FontWeight.w800, color: c.text),
                ),
                const SizedBox(height: 4),
                SysMono(_vars['folder'] ?? ''),
                SysText(
                  sw(l, 'updBrkChecked', {
                    'file': _vars['file'] ?? '',
                    'size': byteWords(int.tryParse(_vars['bytes'] ?? '') ?? 0, lang),
                    'projects': _vars['projects'] ?? '0',
                    'conversations': _vars['conversations'] ?? '0',
                  }),
                ),
                if (s.install == 'docker') ...[
                  SysText(l.syUpdBrkDockerCopy, dim: false),
                  _Command(text: 'docker compose cp redgiant:${_vars['path'] ?? ''} .'),
                ],
              ],
            ),
          ),
        if (done && _keys > 0 && !withKeys) ...[
          SysText(sw(l, 'updBrkKeys', {'n': '$_keys'}), dim: false),
          if (_asked) ...[
            SysField(
              label: l.syKcPassphrase,
              help: l.syKcPassphraseHelp,
              controller: _pass,
              fieldKey: const Key('sy-gate-pass'),
              secret: true,
              onChanged: (_) => setState(() {}),
            ),
            SysActs(
              start: true,
              children: [
                FilledButton(
                  key: const Key('sy-gate-keys-again'),
                  onPressed: _pass.text.length < 8 ? null : () => _start(_pass.text),
                  child: Text(l.syUpdBrkKeysAgain),
                ),
              ],
            ),
          ] else
            Align(
              alignment: Alignment.centerLeft,
              child: OutlinedButton.icon(
                key: const Key('sy-gate-keys-add'),
                onPressed: () => setState(() => _asked = true),
                icon: RgIcon(RgIcons.lock, size: 16, color: c.text),
                label: Text(l.syUpdBrkKeysAdd),
              ),
            ),
        ],
        if (done && withKeys) SysNote(tone: 'ok', icon: RgIcons.key, text: l.syUpdBrkKeysIn),
        if (_error != null) SysSaid(text: _error!),
        SysActs(
          children: [
            OutlinedButton(
              key: const Key('sy-gate-later'),
              onPressed: () => Navigator.of(context).pop(),
              child: Text(l.syUpdLater),
            ),
            FilledButton(
              key: const Key('sy-gate-next'),
              onPressed: done ? () => setState(() => _step = 'guide') : null,
              child: Text(l.syUpdBrkNext),
            ),
          ],
        ),
      ],
    );
  }
}

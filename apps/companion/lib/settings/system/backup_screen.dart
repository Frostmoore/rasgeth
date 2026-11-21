// Settings › Backup (G42.14), the page's Backup.tsx: every project with its files, the agents and
// the conversations in one file, made by the server (the job followed with its steps; the keychain
// goes in only sealed with a passphrase of the person's), then saved on this device with its bar;
// and a file chosen here sent to the server with its bar, what it holds shown before anything is
// imported (projects already here stay, God's and Demi-God's names chosen by the person, the
// keychain's passphrase if it carries one), then imported with its steps.
import 'dart:async';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

import '../../api/client.dart';
import '../../l10n/app_localizations.dart';
import '../../theme/colors.dart';
import '../../ui/chat/file_download.dart' show byteWords;
import '../../ui/icons.dart';
import '../../ui/settings_kit.dart';
import '../api/system_api.dart';
import 'system_kit.dart';

Future<void> openBackupSettings(BuildContext context) =>
    openSystemScreen(context, const BackupScreen());

/// Where a backup goes on this device (the system's «Save as»; a test gives its own).
Future<bool> Function(String name, Uint8List bytes) backupSave = (name, bytes) async =>
    await FilePicker.saveFile(fileName: name, bytes: bytes) != null;

/// A `.rgbackup` chosen on this device (the system's chooser; a test gives its own).
Future<(String, Uint8List)?> Function() backupPick = () async {
  final f = await FilePicker.pickFiles(
    type: FileType.custom,
    allowedExtensions: const ['rgbackup'],
  );
  final one = f.firstOrNull;
  if (one == null) return null;
  return (one.name, await one.readAsBytes());
};

class BackupScreen extends StatelessWidget {
  const BackupScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return SettingsScaffold(
      title: l.syBackup,
      backKey: const Key('sy-backup-back'),
      backLabel: l.back,
      listKey: const Key('sy-backup-list-screen'),
      children: [
        SysHead(eyebrow: l.syBackup, q: l.sySbBackupQ, lead: l.syBackupPurpose),
        const _Export(),
        const _Import(),
      ],
    );
  }
}

/// A transfer's bar: how much, of how much.
class _Bar extends StatelessWidget {
  const _Bar({required this.got, this.total});

  final int got;
  final int? total;

  @override
  Widget build(BuildContext context) {
    final c = RgColors.of(context);
    final lang = Localizations.localeOf(context).languageCode;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          LinearProgressIndicator(
            value: (total ?? 0) > 0 ? got / total! : null,
            minHeight: 6,
            borderRadius: BorderRadius.circular(3),
            color: c.accent,
            backgroundColor: c.line,
          ),
          const SizedBox(height: 3),
          Text(
            total != null
                ? '${byteWords(got, lang)} / ${byteWords(total!, lang)}'
                : byteWords(got, lang),
            style: TextStyle(color: c.dim, fontSize: 12),
          ),
        ],
      ),
    );
  }
}

class _Export extends StatefulWidget {
  const _Export();

  @override
  State<_Export> createState() => _ExportState();
}

class _ExportState extends State<_Export> {
  String? _jobId;
  bool _running = false;
  String? _file;
  bool _withKeys = false;
  final _pass = TextEditingController();
  (int, int?)? _down;
  bool _saved = false;
  String? _error;

  @override
  void dispose() {
    _pass.dispose();
    super.dispose();
  }

  Future<void> _make() async {
    final l = AppLocalizations.of(context);
    final c = sysClient(context);
    if (c == null) return;
    setState(() {
      _saved = false;
      _file = null;
      _error = null;
    });
    try {
      final j = await c.exportBackup(_withKeys ? _pass.text : null);
      if (mounted) {
        setState(() {
          _jobId = j.id;
          _running = true;
        });
      }
    } on ApiException catch (e) {
      if (mounted) setState(() => _error = sysError(l, e));
    }
  }

  Future<void> _save(String name) async {
    final l = AppLocalizations.of(context);
    final c = sysClient(context);
    if (c == null) return;
    setState(() => _down = (0, null));
    try {
      final bytes = await c.downloadBackup(
        name,
        onProgress: (got, total) {
          if (mounted) setState(() => _down = (got, total));
        },
      );
      if (!mounted) return;
      setState(() => _down = null);
      final ok = await backupSave(name, bytes);
      if (mounted) setState(() => _saved = ok);
    } on ApiException catch (e) {
      if (mounted) {
        setState(() {
          _down = null;
          _error = sysError(l, e);
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final file = _file;
    return SysBox(
      key: const Key('sy-export'),
      icon: RgIcons.download,
      title: l.syBackupExport,
      q: l.syBackupExportHint,
      children: [
        if (_jobId != null)
          SysJob(
            id: _jobId!,
            onEnd: (state, vars) {
              if (!mounted) return;
              setState(() {
                _running = false;
                if (state == 'done') _file = vars['file'];
              });
            },
          ),
        if (_down != null) _Bar(got: _down!.$1, total: _down!.$2),
        if (_saved) SysNote(tone: 'ok', icon: RgIcons.check, text: l.syBackupSaved),
        if (!_running) ...[
          SwitchLine(
            key: const Key('sy-export-keys'),
            title: l.syBackupKeys,
            help: l.syBackupKeysHelp,
            on: _withKeys,
            onChanged: (v) => setState(() => _withKeys = v),
          ),
          if (_withKeys)
            SysField(
              label: l.syKcPassphrase,
              help: l.syKcPassphraseHelp,
              controller: _pass,
              fieldKey: const Key('sy-export-pass'),
              secret: true,
              onChanged: (_) => setState(() {}),
            ),
        ],
        SysActs(
          children: [
            if (file != null && _down == null)
              FilledButton.icon(
                key: const Key('sy-export-download'),
                onPressed: () => _save(file),
                icon: const RgIcon(RgIcons.download, size: 16, color: Colors.white),
                label: Text(sw(l, 'backupDownload', {'file': file})),
              ),
            if (!_running && _down == null)
              (file == null
                  ? FilledButton.icon(
                      key: const Key('sy-export-make'),
                      onPressed: _withKeys && _pass.text.length < 8 ? null : _make,
                      icon: const RgIcon(RgIcons.download, size: 16, color: Colors.white),
                      label: Text(l.syBackupMake),
                    )
                  : OutlinedButton(
                      key: const Key('sy-export-make'),
                      onPressed: _withKeys && _pass.text.length < 8 ? null : _make,
                      child: Text(l.syBackupMakeAgain),
                    )),
          ],
        ),
        if (_error != null) SysSaid(text: _error!),
      ],
    );
  }
}

class _Import extends StatefulWidget {
  const _Import();

  @override
  State<_Import> createState() => _ImportState();
}

class _ImportState extends State<_Import> {
  (int, int)? _up;
  ({String id, Map<String, dynamic> preview})? _found;
  final _names = <String, String>{};
  String? _jobId;
  bool _running = false;
  Map<String, String>? _done;
  final _pass = TextEditingController();
  String? _error;

  @override
  void dispose() {
    _pass.dispose();
    super.dispose();
  }

  Future<void> _pick() async {
    final l = AppLocalizations.of(context);
    final c = sysClient(context);
    if (c == null) return;
    final f = await backupPick();
    if (f == null || !mounted) return;
    setState(() {
      _found = null;
      _jobId = null;
      _done = null;
      _error = null;
      _up = (0, f.$2.length);
    });
    try {
      final r = await c.uploadBackup(f.$2);
      if (!mounted) return;
      setState(() {
        _up = null;
        _found = r;
        _names.clear();
        // This installation's names stay unless the person says otherwise.
        for (final n
            in (r.preview['names'] as List? ?? const []).whereType<Map<dynamic, dynamic>>()) {
          _names['${n['kind']}'] = '${n['here'] ?? n['backup']}';
        }
      });
    } on ApiException catch (e) {
      if (mounted) {
        setState(() {
          _up = null;
          _error = sysError(l, e);
        });
      }
    }
  }

  Future<void> _go() async {
    final l = AppLocalizations.of(context);
    final c = sysClient(context);
    final f = _found;
    if (c == null || f == null) return;
    try {
      final j = await c.importBackup({
        'id': f.id,
        if (_names['god'] != null) 'godName': _names['god'],
        if (_names['demigod'] != null) 'demigodName': _names['demigod'],
        if (_pass.text.isNotEmpty) 'keychainPassphrase': _pass.text,
      });
      if (mounted) {
        setState(() {
          _jobId = j.id;
          _running = true;
        });
      }
    } on ApiException catch (e) {
      if (mounted) setState(() => _error = sysError(l, e));
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final c = RgColors.of(context);
    final p = _found?.preview;
    final projects = [
      for (final x in p?['projects'] as List? ?? const [])
        if (x is Map) x,
    ];
    final fresh = projects.where((x) => x['exists'] != true);
    final lang = Localizations.localeOf(context).languageCode;
    return SysBox(
      key: const Key('sy-import'),
      icon: RgIcons.upload,
      title: l.syBackupImport,
      q: l.syBackupImportHint,
      children: [
        if (_up == null && _jobId == null)
          SysActs(
            start: true,
            children: [
              (p == null
                  ? FilledButton.icon(
                      key: const Key('sy-import-choose'),
                      onPressed: _pick,
                      icon: const RgIcon(RgIcons.upload, size: 16, color: Colors.white),
                      label: Text(l.syBackupChoose),
                    )
                  : OutlinedButton.icon(
                      key: const Key('sy-import-choose'),
                      onPressed: _pick,
                      icon: RgIcon(RgIcons.upload, size: 16, color: c.text),
                      label: Text(l.syBackupChoose),
                    )),
            ],
          ),
        if (_up != null) ...[SysText(l.syBackupSending), _Bar(got: _up!.$1, total: _up!.$2)],
        if (p != null && _jobId == null) ...[
          SysText(
            sw(l, 'backupFrom', {'when': sysWhen('${p['createdAt']}')}),
            dim: false,
            strong: true,
          ),
          for (final x in projects)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 2),
              child: Row(
                children: [
                  RgIcon(RgIcons.folder, size: 14, color: x['exists'] == true ? c.dim : c.accent),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text('${x['name']}', style: TextStyle(color: c.text)),
                  ),
                  if (x['exists'] == true)
                    Text(l.syBackupAlreadyHere, style: TextStyle(color: c.dim, fontSize: 12.5)),
                ],
              ),
            ),
          SysText(
            sw(l, 'backupCounts', {
              'agents': '${p['agents'] ?? 0}',
              'conversations':
                  '${((p['conversations'] as num?) ?? 0) + ((p['chats'] as num?) ?? 0)}',
              'size': byteWords(((p['filesBytes'] as num?) ?? 0).toInt(), lang),
            }),
          ),
          for (final n in (p['names'] as List? ?? const []).whereType<Map<dynamic, dynamic>>())
            if (n['here'] != null && n['here'] != n['backup']) ...[
              SysText(
                sw(l, 'backupNameQuestion', {
                  'who': n['kind'] == 'god' ? 'God' : 'Demi-God',
                  'here': '${n['here']}',
                  'backup': '${n['backup']}',
                }),
                dim: false,
              ),
              SysSeg<String>(
                keyPrefix: 'sy-import-name-${n['kind']}',
                value: _names['${n['kind']}'],
                onChanged: (v) => setState(() => _names['${n['kind']}'] = v),
                options: [
                  ('${n['here']}', sw(l, 'backupKeepName', {'name': '${n['here']}'})),
                  ('${n['backup']}', sw(l, 'backupTakeName', {'name': '${n['backup']}'})),
                ],
              ),
            ],
          if (p['keychain'] == true)
            SysField(
              label: l.syBackupKeysIn,
              help: l.syBackupKeysInHelp,
              controller: _pass,
              fieldKey: const Key('sy-import-pass'),
              secret: true,
            ),
          SysText(fresh.isNotEmpty ? l.syBackupAddsHint : l.syBackupNothingNew),
          SysActs(
            children: [
              TextButton(onPressed: () => setState(() => _found = null), child: Text(l.syCancel)),
              FilledButton(
                key: const Key('sy-import-go'),
                onPressed: _go,
                child: Text(l.syBackupImportNow),
              ),
            ],
          ),
        ],
        if (_jobId != null)
          SysJob(
            id: _jobId!,
            showDone: false,
            onEnd: (state, vars) {
              if (!mounted) return;
              setState(() {
                _running = false;
                if (state == 'done') _done = vars;
              });
            },
          ),
        if (_done != null) ...[
          SysNote(
            key: const Key('sy-import-done'),
            tone: 'ok',
            icon: RgIcons.check,
            text: sw(l, 'backupImported', {
              'projects': _done!['projects'] ?? '0',
              'agents': _done!['agents'] ?? '0',
              'conversations': _done!['conversations'] ?? '0',
            }),
          ),
          if (_done!['keychain'] != null)
            SysNote(
              tone: _done!['keychain'] == 'wrong' ? 'error' : 'ok',
              icon: RgIcons.key,
              text: _done!['keychain'] == 'wrong'
                  ? l.syBackupKeysWrong
                  : sw(l, 'kcImported', {'n': _done!['keychain']!}),
            ),
        ],
        if (_jobId != null && !_running)
          SysActs(
            start: true,
            children: [
              OutlinedButton(
                key: const Key('sy-import-another'),
                onPressed: () => setState(() {
                  _jobId = null;
                  _found = null;
                  _done = null;
                }),
                child: Text(l.syBackupAnother),
              ),
            ],
          ),
        if (_error != null) SysSaid(text: _error!),
      ],
    );
  }
}

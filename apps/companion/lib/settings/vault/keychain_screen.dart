// G42.12: Settings › Keychain, native, as the page's Keychain.tsx and KeychainBrowsers.tsx (G33.4,
// G36.20, G36.21): every key and password in one place, sealed on the server. The list with its
// search and kinds, the keys the server keeps for itself (`system`, managed where they were set),
// a credential's window (what it is, its value shown or copied only after the device's own lock,
// fingerprint, face or PIN, 3.10.1, or the person's yes where there is none,
// where it may go, who may use it and whether to ask; the entries a part of the server uses carry
// «Used by» and cannot be deleted here), the password generator, its last uses, importing a
// password manager's CSV (a preview first) or a sealed keychain file, exporting a sealed one, and
// the browsers linked with a code. A value shown is dropped when hidden or when the window closes;
// a value copied leaves the clipboard after 30 seconds, as on the page. Routes in
// api/keychain_api.dart.
import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

import '../../api/client.dart';
import '../../app_state.dart';
import '../../brand.dart';
import '../../l10n/app_localizations.dart';
import '../../theme/colors.dart';
import '../../ui/icons.dart';
import '../api/automations_api.dart';
import '../api/extensions_api.dart';
import '../api/keychain_api.dart';
import '../automations/automation_kit.dart';
import '../extensions/ext_catalog.dart';
import 'device_unlock.dart';
import '../extensions/ext_kit.dart';
import '../rules_kit.dart';

/// Opens the page: a panel over the window on a computer, a whole screen on a phone.
Future<void> openKeychainSettings(BuildContext context) =>
    openRulesPage(context, (panel) => KeychainScreen(panel: panel));

/// A credential to write in the keychain, filled in from elsewhere (a secret held back from a
/// chat, a magic automation's need): the page's `vaultDraft`.
class VaultDraft {
  const VaultDraft({this.service, this.name, this.hosts = const [], this.value});
  final String? service;
  final String? name;
  final List<String> hosts;
  final String? value;
}

/// A file from this device: its name and text (the system's chooser; a test gives its own).
typedef PickText = Future<(String, String)?> Function();

/// Where an export goes: the system's «Save as» (a test gives its own).
typedef SaveText = Future<bool> Function(String name, String text);

Future<(String, String)?> _systemPick() async {
  final f = (await FilePicker.pickFiles()).firstOrNull;
  if (f == null) return null;
  return (f.name, utf8.decode(await f.readAsBytes(), allowMalformed: true));
}

Future<bool> _systemSave(String name, String text) async =>
    await FilePicker.saveFile(fileName: name, bytes: Uint8List.fromList(utf8.encode(text))) != null;

/// Opens a credential's window: a new one ([draft]) or one to see and change; true when saved.
Future<bool> openCredentialWindow(
  BuildContext context, {
  VaultEntry? entry,
  VaultDraft? draft,
  List<VaultUse> uses = const [],
}) async {
  final l = AppLocalizations.of(context);
  final saved = await openAutoWindow<bool>(
    context,
    title: entry?.service ?? l.vkKcAddTitle,
    sub: entry != null ? l.vkKcUseAs(entry.name) : l.vkKcAddSub,
    icon: RgIcon(
      vaultCategoryIcon(entry?.category ?? 'api'),
      size: 22,
      color: RgColors.of(context).accent,
    ),
    wide: true,
    key: const Key('kc-window'),
    child: (ctx, close) => _CredentialForm(entry: entry, draft: draft, uses: uses, close: close),
  );
  return saved ?? false;
}

const _categories = ['api', 'login', 'bank', 'email', 'server', 'other'];
const _clipboardFor = Duration(seconds: 30);

RgIcons vaultCategoryIcon(String c) => switch (c) {
  'api' => RgIcons.key,
  'login' => RgIcons.user,
  'bank' => RgIcons.wallet,
  'email' => RgIcons.send,
  'server' => RgIcons.server,
  _ => RgIcons.lock,
};

String vaultCategoryLabel(AppLocalizations l, String c) => switch (c) {
  'api' => l.vkKcCat_api,
  'login' => l.vkKcCat_login,
  'bank' => l.vkKcCat_bank,
  'email' => l.vkKcCat_email,
  'server' => l.vkKcCat_server,
  _ => l.vkKcCat_other,
};

/// The Settings page a part of the server sets its keys in (the page's PAGE_OF).
String vaultPageOf(AppLocalizations l, String section) => switch (section) {
  'setup' || 'subscriptions' => l.vkSubscriptions,
  'telegram' => l.vkTelegram,
  'chats' => l.vkChats,
  'code' => l.vkWzCode,
  'remote' => l.vkWzRemote,
  'machines' => l.vkMcSection,
  'devices' => l.vkDvSection,
  'automations' => l.vkAutomations,
  'extensions' => l.vkExtensions,
  _ => l.vkSettings,
};

String _systemWhat(AppLocalizations l, VaultSystemEntry e) => switch (e.kind) {
  'provider' => l.vkKcSys_provider(e.what),
  'chat' => l.vkKcSys_chat(e.what),
  'email' => l.vkKcSys_email(e.what),
  'mcp' => l.vkKcSys_mcp(e.what),
  'git' => l.vkKcSys_git(e.what),
  'search' => l.vkKcSys_search(e.what),
  'ssh' => l.vkKcSys_ssh(e.what),
  _ => l.vkKcSys_other(e.what),
};

String _protection(AppLocalizations l, String? p) => switch (p) {
  'dpapi' => l.vkKcProt_dpapi,
  'keychain' => l.vkKcProt_keychain,
  'env' => l.vkKcProt_env,
  _ => l.vkKcProt_file,
};

String _when(AppLocalizations l, String iso) {
  final d = DateTime.tryParse(iso)?.toLocal();
  if (d == null) return '';
  return DateFormat.MMMd(l.localeName).add_Hm().format(d);
}

/// Days until it stops working (negative: already), or null without a date.
int? daysLeft(String? expires, [DateTime? now]) {
  if (expires == null) return null;
  final at = DateTime.tryParse(expires);
  if (at == null) return null;
  return (at.difference(now ?? DateTime.now()).inMilliseconds / 86400000).ceil();
}

String? expiryText(AppLocalizations l, int? n) => n == null
    ? null
    : n < 0
    ? l.vkKcExpired
    : n == 0
    ? l.vkKcExpiresToday
    : n <= 30
    ? l.vkKcExpiresIn('$n')
    : null;

/// The host names of a text: scheme and path dropped, lower case (the page's `hostsOf`).
List<String> hostsOf(String text) => [
  for (final h in text.split(RegExp(r'[\s,]+')))
    if (h.trim().isNotEmpty)
      h
          .trim()
          .replaceFirst(RegExp(r'^https?://'), '')
          .replaceFirst(RegExp(r'/.*$'), '')
          .toLowerCase(),
]..removeWhere((h) => h.isEmpty);

// ---- the password generator ----

const passwordSets = {
  'letters': 'abcdefghijkmnopqrstuvwxyzABCDEFGHJKLMNPQRSTUVWXYZ23456789',
  'symbols': 'abcdefghijkmnopqrstuvwxyzABCDEFGHJKLMNPQRSTUVWXYZ23456789!#\$%&*+-=?@_~',
  'digits': '0123456789',
};

/// A random password from the system's own cryptography, without bias (rejection sampling), as
/// the page's `generatePassword`.
String generatePassword(int length, String kind, [Random? random]) {
  final chars = passwordSets[kind]!;
  final r = random ?? Random.secure();
  final limit = 256 - (256 % chars.length);
  final out = StringBuffer();
  while (out.length < length) {
    final b = r.nextInt(256);
    if (b < limit) out.write(chars[b % chars.length]);
  }
  return out.toString();
}

class _Generator extends StatefulWidget {
  const _Generator({required this.onUse});

  final ValueChanged<String> onUse;

  @override
  State<_Generator> createState() => _GeneratorState();
}

class _GeneratorState extends State<_Generator> {
  int _length = 24;
  String _kind = 'symbols';
  late String _made = generatePassword(24, 'symbols');

  void _again([int? length, String? kind]) =>
      setState(() => _made = generatePassword(length ?? _length, kind ?? _kind));

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final c = RgColors.of(context);
    final digits = _kind == 'digits';
    final min = digits ? 4 : 8;
    final max = digits ? 12 : 64;
    final step = digits ? 1 : 4;
    return Container(
      key: const Key('kc-generator'),
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: c.panel,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: c.line),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AutoLb(l.vkKcGenKind),
          RgChoice<String>(
            options: [
              ('symbols', l.vkKcGenSymbols),
              ('letters', l.vkKcGenLetters),
              ('digits', l.vkKcGenDigits),
            ],
            value: _kind,
            keyOf: (k) => 'kc-gen-$k',
            onChanged: (k) {
              final len = k == 'digits'
                  ? (_length > 12 ? 12 : _length)
                  : (_length < 8 ? 8 : _length);
              setState(() {
                _kind = k;
                _length = len;
              });
              _again(len, k);
            },
          ),
          const SizedBox(height: 8),
          Text(
            '${l.vkKcGenLength}: ${l.vkKcGenChars('$_length')}',
            style: TextStyle(color: c.text, fontWeight: FontWeight.w700, fontSize: 13),
          ),
          Slider(
            key: const Key('kc-gen-length'),
            value: _length.toDouble().clamp(min.toDouble(), max.toDouble()),
            min: min.toDouble(),
            max: max.toDouble(),
            divisions: (max - min) ~/ step,
            label: l.vkKcGenChars('$_length'),
            onChanged: (v) {
              final n = v.round();
              setState(() => _length = n);
              _again(n);
            },
          ),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: c.panel2, borderRadius: BorderRadius.circular(10)),
            child: SelectableText(
              _made,
              key: const Key('kc-gen-out'),
              style: TextStyle(fontFamily: 'monospace', fontSize: 14, color: c.text),
            ),
          ),
          WindowActs(
            children: [
              TextButton(
                key: const Key('kc-gen-again'),
                onPressed: () => _again(),
                child: Text(l.vkKcGenAgain),
              ),
              FilledButton(
                key: const Key('kc-gen-use'),
                onPressed: () => widget.onUse(_made),
                child: Text(l.vkKcGenUse),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ---- a credential's window ----

class _CredentialForm extends StatefulWidget {
  const _CredentialForm({
    required this.entry,
    required this.draft,
    required this.uses,
    required this.close,
  });

  final VaultEntry? entry;
  final VaultDraft? draft;
  final List<VaultUse> uses;
  final void Function([bool?]) close;

  @override
  State<_CredentialForm> createState() => _CredentialFormState();
}

class _CredentialFormState extends State<_CredentialForm> {
  VaultEntry? get e => widget.entry;
  late String _service = e?.service ?? widget.draft?.service ?? '';
  late String _name =
      e?.name ??
      widget.draft?.name ??
      (widget.draft?.service != null ? vaultName(widget.draft!.service!) : '');
  late bool _nameTouched = e != null || widget.draft?.name != null;
  late String _category = e?.category ?? 'api';
  late String _tags = e?.tags.join(', ') ?? '';
  late String _username = e?.username ?? '';
  late String _value = widget.draft?.value ?? '';
  late String _url = e?.url ?? '';
  late String _hosts = e?.hosts.join(', ') ?? widget.draft?.hosts.join(', ') ?? '';
  late String _notes = e?.notes ?? '';
  late String _expires = (e?.expires?.length ?? 0) >= 10 ? e!.expires!.substring(0, 10) : '';
  late String _ask = e?.ask ?? 'session';
  late bool _allAgents = e?.allAgents ?? true;
  late List<String> _agents = e?.agents ?? const [];
  late List<String> _tools = e?.tools ?? const [];
  late List<String> _autos = e?.automations ?? const [];
  late String _header = e?.header ?? 'Authorization';
  late String _format = e?.format ?? 'Bearer {value}';
  late bool _changing = e == null;
  bool _gen = false;
  bool _busy = false;
  String? _error;
  List<Installed> _toolList = const [];
  List<(String, String)> _autoList = const [];

  /// The value shown on the person's request; dropped when hidden or when the window closes.
  String? _shown;
  bool _copied = false;
  Timer? _clipboard;

  @override
  void initState() {
    super.initState();
    final c = AppScope.read(context).client;
    if (c == null) return;
    unawaited(
      c.installedExtensions().then(
        (l) => mounted
            ? setState(
                () => _toolList = [
                  for (final x in l)
                    if (x.kind == 'tool') x,
                ],
              )
            : null,
        onError: (_) {},
      ),
    );
    unawaited(
      c.automations().then(
        (l) => mounted
            ? setState(
                () => _autoList = [
                  for (final a in l)
                    (
                      a.id,
                      '${a.recipe['description'] ?? ''}'.isEmpty
                          ? a.name
                          : '${a.recipe['description']}',
                    ),
                ],
              )
            : null,
        onError: (_) {},
      ),
    );
  }

  @override
  void dispose() {
    _shown = null;
    _value = '';
    super.dispose();
  }

  Future<String?> _reveal() async {
    final c = AppScope.read(context).client;
    final id = e?.id;
    if (c == null || id == null) return null;
    try {
      return await c.revealVault(id);
    } on ApiException catch (err) {
      if (mounted) setState(() => _error = err.message);
      return null;
    }
  }

  /// 3.10.1: the device's own lock first (fingerprint, face, PIN); a device without one says so
  /// and asks; where the lock cannot be asked, our window for showing (copying asked nothing).
  Future<bool> _unlocked({required bool copy}) async {
    final l = AppLocalizations.of(context);
    setState(() => _error = null);
    final r = await deviceUnlock.unlock(copy ? l.vkKcUnlockCopy : l.vkKcUnlockShow);
    if (!mounted) return false;
    switch (r) {
      case DeviceUnlockResult.unlocked:
        return true;
      case DeviceUnlockResult.refused:
        setState(() => _error = l.vkKcUnlockRefused);
        return false;
      case DeviceUnlockResult.noLock:
        return askVaultConfirm(
          context,
          title: l.vkKcNoLockQ,
          body: l.vkKcNoLockText,
          yes: copy ? l.vkKcCopy : l.vkKcShow,
        );
      case DeviceUnlockResult.unsupported:
        if (copy) return true;
        return askVaultConfirm(context, title: l.vkKcShowQ, body: l.vkKcShowText, yes: l.vkKcShow);
    }
  }

  Future<void> _show() async {
    if (!await _unlocked(copy: false) || !mounted) return;
    final v = await _reveal();
    if (mounted) setState(() => _shown = v);
  }

  Future<void> _copy() async {
    // A value already on the screen was unlocked to be shown.
    if (_shown == null && (!await _unlocked(copy: true) || !mounted)) return;
    final v = _shown ?? await _reveal();
    if (v == null) return;
    await Clipboard.setData(ClipboardData(text: v));
    if (!mounted) return;
    setState(() => _copied = true);
    _clipboard?.cancel();
    // The clipboard is emptied after 30 s, unless something else was copied since.
    _clipboard = Timer(_clipboardFor, () async {
      final now = await Clipboard.getData(Clipboard.kTextPlain);
      if (now?.text == v) await Clipboard.setData(const ClipboardData(text: ''));
      if (mounted) setState(() => _copied = false);
    });
  }

  bool get _nameOk => vaultNameRe.hasMatch(_name);

  Future<void> _save() async {
    final c = AppScope.read(context).client;
    if (c == null) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    final body = <String, dynamic>{
      'name': _name,
      'service': _service.trim(),
      'category': _category,
      'tags': [
        for (final t in _tags.split(','))
          if (t.trim().isNotEmpty) t.trim(),
      ].take(12).toList(),
      'username': _username,
      if (_changing && _value.isNotEmpty) 'value': _value,
      'url': _url.trim(),
      'hosts': hostsOf(_hosts),
      'notes': _notes,
      'expires': _expires.isEmpty
          ? null
          : DateTime.parse('${_expires}T12:00:00').toUtc().toIso8601String(),
      'ask': _ask,
      'allow': {'allAgents': _allAgents, 'agents': _agents, 'tools': _tools, 'automations': _autos},
      'inject': {
        'header': _header.trim(),
        'format': _format.trim().isEmpty ? '{value}' : _format.trim(),
      },
    };
    try {
      if (e != null) {
        await c.editVault(e!.id, body);
      } else {
        await c.addVault(body);
      }
      _value = '';
      widget.close(true);
    } on ApiException catch (err) {
      if (mounted) setState(() => _error = err.message);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _remove() async {
    final l = AppLocalizations.of(context);
    final entry = e;
    if (entry == null) return;
    final yes = await askVaultConfirm(
      context,
      title: l.vkKcRemoveQ(entry.service),
      body: l.vkKcRemoveText,
      yes: l.vkKcRemove,
      danger: true,
    );
    if (!yes || !mounted) return;
    try {
      await AppScope.read(context).client?.removeVault(entry.id);
      widget.close(true);
    } on ApiException catch (err) {
      if (mounted) setState(() => _error = err.message);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final c = RgColors.of(context);
    final app = AppScope.of(context);
    final entry = e;
    final hosts = hostsOf(_hosts);
    final valueOk = !_changing || _value.isNotEmpty;
    final mine = [
      for (final u in widget.uses)
        if (entry != null && u.entryId == entry.id) u,
    ].take(8).toList();
    final workers = [
      for (final a in app.agents)
        if (a.kind.name != 'demigod' && a.kind.name != 'inspector') a,
    ];
    final ref = '{{vault:${l.localeName.startsWith('it') ? 'nome' : 'name'}}}';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (entry?.usedBy case final u?) UsedByNote(usedBy: u),
        AutoRow(
          children: [
            AutoField(
              label: l.vkKcService,
              help: l.vkKcServiceHelp,
              hint: l.vkKcServiceExample,
              value: _service,
              fieldKey: const Key('kc-service'),
              onChanged: (v) => setState(() {
                _service = v;
                if (!_nameTouched) _name = vaultName(v);
              }),
            ),
            AutoField(
              label: l.vkKcName,
              help: _name.isNotEmpty && !_nameOk ? l.vkKcNameBad : l.vkKcNameHelp,
              hint: 'revolut_api',
              value: _name,
              mono: true,
              fieldKey: const Key('kc-name'),
              onChanged: (v) => setState(() {
                _name = v.toLowerCase();
                _nameTouched = true;
              }),
            ),
          ],
        ),
        AutoLb(l.vkKcCategory),
        AutoChips<String>(
          options: [for (final k in _categories) (k, vaultCategoryLabel(l, k))],
          value: [_category],
          keyOf: (k) => 'kc-cat-$k',
          onChanged: (v) => setState(() => _category = v.firstOrNull ?? _category),
        ),
        const SizedBox(height: 10),
        AutoRow(
          children: [
            AutoField(
              label: l.vkKcUser,
              value: _username,
              fieldKey: const Key('kc-user'),
              onChanged: (v) => setState(() => _username = v),
            ),
            AutoField(
              label: l.vkKcUrl,
              hint: 'https://b2b.revolut.com/api/1.0',
              value: _url,
              fieldKey: const Key('kc-url'),
              onChanged: (v) => setState(() {
                _url = v;
                final h = hostsOf(v).firstOrNull;
                if (_hosts.trim().isEmpty && h != null) _hosts = h;
              }),
            ),
          ],
        ),
        RulesSub(title: l.vkKcSecret, lead: l.vkKcSecretLead),
        if (!_changing && entry != null)
          Column(
            key: const Key('kc-secret'),
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(color: c.panel2, borderRadius: BorderRadius.circular(10)),
                child: SelectableText(
                  _shown ?? '•' * entry.length.clamp(8, 16),
                  key: const Key('kc-secret-value'),
                  style: TextStyle(fontFamily: 'monospace', color: c.text, fontSize: 14),
                ),
              ),
              Wrap(
                spacing: 4,
                children: [
                  if (_shown == null)
                    TextButton.icon(
                      key: const Key('kc-show'),
                      onPressed: _show,
                      icon: RgIcon(RgIcons.eye, size: 16, color: c.accent),
                      label: Text(l.vkKcShow),
                    )
                  else
                    TextButton(
                      key: const Key('kc-hide'),
                      onPressed: () => setState(() => _shown = null),
                      child: Text(l.vkKcHide),
                    ),
                  TextButton.icon(
                    key: const Key('kc-copy'),
                    onPressed: _copy,
                    icon: RgIcon(_copied ? RgIcons.check : RgIcons.copy, size: 16, color: c.accent),
                    label: Text(_copied ? l.vkKcCopied : l.vkKcCopy),
                  ),
                  TextButton.icon(
                    key: const Key('kc-change'),
                    onPressed: () => setState(() {
                      _shown = null;
                      _changing = true;
                    }),
                    icon: RgIcon(RgIcons.pencil, size: 16, color: c.accent),
                    label: Text(l.vkKcChange),
                  ),
                ],
              ),
              if (_copied) AutoHelp(l.vkKcCopiedNote),
            ],
          )
        else ...[
          SecretField(
            label: l.vkKcSecret,
            hint: l.vkKcSecretPlaceholder,
            obscure: !(_gen || widget.draft?.value != null),
            initial: _value,
            fieldKey: const Key('kc-value'),
            onChanged: (v) => setState(() => _value = v),
          ),
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton.icon(
              key: const Key('kc-generate'),
              onPressed: () => setState(() => _gen = !_gen),
              icon: RgIcon(RgIcons.spark, size: 16, color: c.accent),
              label: Text(l.vkKcGenerate),
            ),
          ),
          if (_gen)
            _Generator(
              onUse: (v) => setState(() {
                _value = v;
                _gen = false;
              }),
            ),
        ],
        RulesSub(title: l.vkKcWhere, lead: l.vkKcWhereLead),
        AutoField(
          label: l.vkKcHosts,
          help: l.vkKcHostsHelp,
          hint: 'b2b.revolut.com',
          value: _hosts,
          mono: true,
          fieldKey: const Key('kc-hosts'),
          onChanged: (v) => setState(() => _hosts = v),
        ),
        if (hosts.isEmpty) WarnLine(l.vkKcNoHosts),
        RulesSub(title: l.vkKcWho, lead: l.vkKcWhoLead),
        SwitchLine(
          key: const Key('kc-all-agents'),
          title: l.vkKcAllAgents,
          help: l.vkKcAllAgentsHelp,
          on: _allAgents,
          onChanged: (v) => setState(() => _allAgents = v),
        ),
        if (!_allAgents && workers.isNotEmpty) ...[
          AutoLb(l.vkKcSomeAgents),
          AutoChips<String>(
            multiple: true,
            options: [for (final a in workers) (a.id, a.name)],
            value: _agents,
            keyOf: (id) => 'kc-agent-$id',
            onChanged: (v) => setState(() => _agents = v),
          ),
        ],
        if (_toolList.isNotEmpty) ...[
          AutoLb(l.vkKcTools),
          AutoHelp(l.vkKcToolsHelp),
          AutoChips<String>(
            multiple: true,
            options: [for (final x in _toolList) (x.name, x.name)],
            value: _tools,
            keyOf: (n) => 'kc-tool-$n',
            onChanged: (v) => setState(() => _tools = v),
          ),
        ],
        if (_autoList.isNotEmpty) ...[
          AutoLb(l.vkKcAutos),
          AutoChips<String>(
            multiple: true,
            options: _autoList,
            value: _autos,
            keyOf: (id) => 'kc-auto-$id',
            onChanged: (v) => setState(() => _autos = v),
          ),
        ],
        AutoLb(l.vkKcAsk),
        RgChoice<String>(
          vertical: true,
          options: [
            ('session', l.vkKcAsk_session),
            ('always', l.vkKcAsk_always),
            ('never', l.vkKcAsk_never),
          ],
          value: _ask,
          keyOf: (v) => 'kc-ask-$v',
          onChanged: (v) => setState(() => _ask = v),
        ),
        RulesSub(title: l.vkKcMore),
        AutoRow(
          children: [
            DateBox(
              label: l.vkKcExpires,
              value: _expires,
              boxKey: const Key('kc-expires'),
              onChanged: (v) => setState(() => _expires = v),
            ),
            AutoField(
              label: l.vkKcTags,
              help: l.vkKcTagsHelp,
              value: _tags,
              fieldKey: const Key('kc-tags'),
              onChanged: (v) => setState(() => _tags = v),
            ),
          ],
        ),
        AutoHelp(l.vkKcExpiresHelp),
        const SizedBox(height: 8),
        AutoField(
          label: l.vkKcNotes,
          value: _notes,
          lines: 3,
          fieldKey: const Key('kc-notes'),
          onChanged: (v) => setState(() => _notes = v),
        ),
        const SizedBox(height: 8),
        Details(
          title: l.vkKcHow,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              AutoHelp(l.vkKcHowHelp(ref, '{value}')),
              const SizedBox(height: 6),
              AutoRow(
                children: [
                  AutoField(
                    label: l.vkKcHeader,
                    value: _header,
                    mono: true,
                    fieldKey: const Key('kc-header'),
                    onChanged: (v) => setState(() => _header = v),
                  ),
                  AutoField(
                    label: l.vkKcFormat,
                    value: _format,
                    mono: true,
                    fieldKey: const Key('kc-format'),
                    onChanged: (v) => setState(() => _format = v),
                  ),
                ],
              ),
            ],
          ),
        ),
        if (entry != null) ...[
          RulesSub(title: l.vkKcUsesOne),
          if (mine.isEmpty) AutoHelp(l.vkKcNeverUsed) else for (final u in mine) UseLine(use: u),
        ],
        if (_error != null) AutoNotice(_error!, error: true, key: const Key('kc-error')),
        WindowActs(
          children: [
            if (entry != null && entry.usedBy == null)
              TextButton.icon(
                key: const Key('kc-remove'),
                style: TextButton.styleFrom(foregroundColor: c.err),
                onPressed: _remove,
                icon: RgIcon(RgIcons.trash, size: 16, color: c.err),
                label: Text(l.vkKcRemove),
              ),
            TextButton(onPressed: () => widget.close(false), child: Text(l.vkCancel)),
            FilledButton(
              key: const Key('kc-save'),
              onPressed: _busy || _service.trim().isEmpty || !_nameOk || !valueOk ? null : _save,
              child: Text(l.vkSave),
            ),
          ],
        ),
      ],
    );
  }
}

/// Our confirmation window (askConfirm), here so the keychain's tests can find its buttons.
Future<bool> askVaultConfirm(
  BuildContext context, {
  required String title,
  required String body,
  required String yes,
  bool danger = false,
}) async {
  final l = AppLocalizations.of(context);
  final c = RgColors.of(context);
  final r = await openAutoWindow<bool>(
    context,
    title: title,
    key: const Key('kc-confirm'),
    child: (ctx, close) => Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(body, style: TextStyle(color: c.text, height: 1.45)),
        WindowActs(
          children: [
            TextButton(
              key: const Key('kc-confirm-no'),
              onPressed: () => close(false),
              child: Text(l.vkCancel),
            ),
            FilledButton(
              key: const Key('kc-confirm-yes'),
              style: danger ? FilledButton.styleFrom(backgroundColor: c.critical) : null,
              onPressed: () => close(true),
              child: Text(yes),
            ),
          ],
        ),
      ],
    ),
  );
  return r ?? false;
}

/// «Used by: Models and subscriptions»: a key a part of the server uses by itself.
class UsedByNote extends StatelessWidget {
  const UsedByNote({super.key, required this.usedBy});

  final VaultUsedBy usedBy;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final c = RgColors.of(context);
    return Container(
      key: const Key('kc-used-by'),
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: c.accentSoft,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: c.accent.withValues(alpha: .35)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          RgIcon(RgIcons.lock, size: 18, color: c.accent),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${l.vkKcUsedBy} ${vaultPageOf(l, usedBy.section)}',
                  style: TextStyle(color: c.text, fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 2),
                Text(l.vkKcUsedByText, style: TextStyle(color: c.dim, fontSize: 12.5, height: 1.4)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// One use of a credential: who, what, towards where, when.
class UseLine extends StatelessWidget {
  const UseLine({super.key, required this.use});

  final VaultUse use;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final c = RgColors.of(context);
    final u = use;
    final who = u.tool == 'browser_extension' && u.agentName != null
        ? l.vkKcUseBrowser(u.agentName!)
        : u.agentName ?? (u.agentId == null && u.sessionId == null ? kProductName : l.vkKcSomeone);
    final what = switch (u.outcome) {
      'denied' => l.vkKcUse_denied(u.host, u.name),
      'refused' => l.vkKcUse_refused(u.host, u.name),
      'moved' => l.vkKcUse_moved(u.host, u.name),
      _ => l.vkKcUse_used(u.host, u.name),
    };
    final bad = u.outcome == 'denied' || u.outcome == 'refused';
    return Padding(
      key: Key('kc-use-${u.id}'),
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 5),
            child: Container(
              width: 7,
              height: 7,
              decoration: BoxDecoration(shape: BoxShape.circle, color: bad ? c.err : c.ok),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text.rich(
                  TextSpan(
                    children: [
                      TextSpan(
                        text: who,
                        style: const TextStyle(fontWeight: FontWeight.w800),
                      ),
                      TextSpan(text: ' $what'),
                    ],
                  ),
                  style: TextStyle(color: c.text, fontSize: 13.5),
                ),
                if (u.reason != null && u.outcome != 'used' && u.outcome != 'moved')
                  Text(u.reason!, style: TextStyle(color: c.dim, fontSize: 12.5)),
              ],
            ),
          ),
          Text(_when(l, u.at), style: TextStyle(color: c.dim, fontSize: 12)),
        ],
      ),
    );
  }
}

// ---- the page ----

class KeychainScreen extends StatefulWidget {
  const KeychainScreen({
    super.key,
    this.panel = false,
    this.pickFile,
    this.saveFile,
    this.draft,
    this.poll = true,
  });

  final bool panel;
  final PickText? pickFile;
  final SaveText? saveFile;

  /// A credential to add as soon as the page opens (the page's `vaultDraft`).
  final VaultDraft? draft;
  final bool poll;

  @override
  State<KeychainScreen> createState() => _KeychainScreenState();
}

class _KeychainScreenState extends State<KeychainScreen> {
  VaultView? _view;
  String? _error;
  String _q = '';
  String _filter = 'all';

  @override
  void initState() {
    super.initState();
    unawaited(_load());
    final d = widget.draft;
    if (d != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        if (!mounted) return;
        if (await openCredentialWindow(context, draft: d)) await _load();
      });
    }
  }

  Future<void> _load() async {
    final c = AppScope.read(context).client;
    if (c == null) return;
    try {
      final v = await c.vault();
      if (mounted) {
        setState(() {
          _view = v;
          _error = null;
        });
      }
    } on ApiException catch (e) {
      if (mounted) setState(() => _error = e.message);
    }
  }

  Future<void> _open({VaultEntry? entry}) async {
    if (await openCredentialWindow(context, entry: entry, uses: _view?.uses ?? const [])) {
      await _load();
    }
  }

  Future<void> _import() async {
    final l = AppLocalizations.of(context);
    final changed = await openAutoWindow<bool>(
      context,
      title: l.vkKcImportTitle,
      wide: true,
      key: const Key('kc-import'),
      child: (ctx, close) => _ImportView(pick: widget.pickFile ?? _systemPick, close: close),
    );
    if (changed == true) await _load();
  }

  Future<void> _export() async {
    final l = AppLocalizations.of(context);
    await openAutoWindow<void>(
      context,
      title: l.vkKcExportTitle,
      key: const Key('kc-export'),
      child: (ctx, close) => _ExportView(save: widget.saveFile ?? _systemSave, close: close),
    );
  }

  int _count(String f) {
    final v = _view;
    if (v == null) return 0;
    if (f == 'all') return v.entries.length;
    if (f == 'system') return v.system.length + v.entries.where((e) => e.usedBy != null).length;
    return v.entries.where((e) => e.category == f).length;
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final c = RgColors.of(context);
    final v = _view;
    final words = _q.trim().toLowerCase();
    bool match(String s) => words.isEmpty || s.toLowerCase().contains(words);
    final entries = [
      for (final e in v?.entries ?? const <VaultEntry>[])
        if ((_filter == 'all' ||
                _filter == e.category ||
                (_filter == 'system' && e.usedBy != null)) &&
            match('${e.service} ${e.name} ${e.username} ${e.url} ${e.tags.join(' ')} ${e.notes}'))
          e,
    ];
    final system = [
      for (final e in v?.system ?? const <VaultSystemEntry>[])
        if ((_filter == 'all' || _filter == 'system' || _filter == e.category) &&
            match('${e.service} ${e.what}'))
          e,
    ];
    final expiring = [
      for (final e in v?.entries ?? const <VaultEntry>[])
        if (expiryText(l, daysLeft(e.expires)) != null) e,
    ];
    final filters = [
      'all',
      for (final k in _categories)
        if (_count(k) > 0) k,
      'system',
    ];
    return RulesPage(
      pageKey: const Key('keychain-settings'),
      title: l.vkKcEyebrow,
      panel: widget.panel,
      question: l.vkKcQ,
      lead: l.vkKcLead,
      children: [
        if (_error != null) RulesLoading(error: _error),
        if (v == null && _error == null) const RulesLoading(),
        if (v != null && !v.ready)
          Container(
            key: const Key('kc-closed'),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: c.panel,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: c.warnText.withValues(alpha: .4)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    RgIcon(RgIcons.alert, size: 18, color: c.warnText),
                    const SizedBox(width: 8),
                    Text(
                      l.vkKcClosed,
                      style: TextStyle(color: c.text, fontWeight: FontWeight.w800),
                    ),
                  ],
                ),
                if (v.reason != null) AutoHelp(v.reason!),
                AutoHelp(l.vkKcClosedKeys),
              ],
            ),
          ),
        if (v != null && v.ready) ...[
          Container(
            key: const Key('kc-safe'),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: c.ok.withValues(alpha: .07),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: c.ok.withValues(alpha: .3)),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                RgIcon(RgIcons.shield, size: 22, color: c.ok),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _protection(l, v.protection),
                        style: TextStyle(color: c.text, fontWeight: FontWeight.w800),
                      ),
                      Text(
                        l.vkKcSafeText,
                        style: TextStyle(color: c.dim, fontSize: 12.5, height: 1.4),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          if (expiring.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 10),
              child: Wrap(
                key: const Key('kc-expiring'),
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  RgIcon(RgIcons.alert, size: 16, color: c.warnText),
                  const SizedBox(width: 6),
                  Text(l.vkKcExpiringLead, style: TextStyle(color: c.text)),
                  for (final e in expiring)
                    TextButton(
                      onPressed: () => _open(entry: e),
                      child: Text('${e.service} (${expiryText(l, daysLeft(e.expires))})'),
                    ),
                ],
              ),
            ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: SearchField(
                  hint: l.vkKcSearch,
                  fieldKey: const Key('kc-search'),
                  onChanged: (s) => setState(() => _q = s),
                ),
              ),
              const SizedBox(width: 10),
              FilledButton.icon(
                key: const Key('kc-add'),
                onPressed: () => _open(),
                icon: const RgIcon(RgIcons.plus, size: 17, color: Colors.white),
                label: Text(l.vkKcAdd),
              ),
            ],
          ),
          const SizedBox(height: 10),
          AutoChips<String>(
            options: [
              for (final f in filters)
                (
                  f,
                  '${f == 'all'
                      ? l.vkKcAllCats
                      : f == 'system'
                      ? l.vkKcSystem
                      : vaultCategoryLabel(l, f)} ${_count(f)}',
                ),
            ],
            value: [_filter],
            keyOf: (f) => 'kc-filter-$f',
            onChanged: (x) => setState(() => _filter = x.firstOrNull ?? 'all'),
          ),
          const SizedBox(height: 10),
          if (_filter != 'system' || entries.isNotEmpty)
            if (entries.isEmpty)
              Padding(
                key: const Key('kc-empty'),
                padding: const EdgeInsets.symmetric(vertical: 20),
                child: Column(
                  children: [
                    RgIcon(RgIcons.key, size: 26, color: c.dim),
                    const SizedBox(height: 8),
                    Text(
                      v.entries.isEmpty ? l.vkKcEmpty : l.vkKcNoMatch,
                      textAlign: TextAlign.center,
                      style: TextStyle(color: c.dim, height: 1.4),
                    ),
                  ],
                ),
              )
            else
              for (final e in entries)
                _Item(
                  entry: e,
                  onOpen: () => _open(entry: e),
                ),
          if (system.isNotEmpty) ...[
            RulesSub(title: l.vkKcSystemTitle, lead: l.vkKcSystemLead),
            for (final e in system) _SystemItem(entry: e),
          ],
          RulesSub(title: l.vkKcUsesTitle, lead: l.vkKcUsesLead),
          if (v.uses.isEmpty)
            AutoHelp(l.vkKcNoUses)
          else
            for (final u in v.uses.take(12)) UseLine(use: u),
          BrowsersPart(poll: widget.poll),
          RulesSub(title: l.vkKcMoveTitle, lead: l.vkKcMoveLead),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              OutlinedButton.icon(
                key: const Key('kc-import-open'),
                onPressed: _import,
                icon: const RgIcon(RgIcons.upload, size: 17),
                label: Text(l.vkKcImport),
              ),
              OutlinedButton.icon(
                key: const Key('kc-export-open'),
                onPressed: v.entries.isEmpty ? null : _export,
                icon: const RgIcon(RgIcons.download, size: 17),
                label: Text(l.vkKcExport),
              ),
            ],
          ),
          const SizedBox(height: 10),
          AutoHelp(v.proxy ? l.vkKcAgentsHow : l.vkKcAgentsHowNoProxy),
        ],
      ],
    );
  }
}

class _Item extends StatelessWidget {
  const _Item({required this.entry, required this.onOpen});

  final VaultEntry entry;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final c = RgColors.of(context);
    final e = entry;
    final left = expiryText(l, daysLeft(e.expires));
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: c.panel,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: BorderSide(color: left != null ? c.warnText.withValues(alpha: .5) : c.line),
        ),
        child: InkWell(
          key: Key('kc-item-${e.id}'),
          borderRadius: BorderRadius.circular(14),
          onTap: onOpen,
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                _Ico(vaultCategoryIcon(e.category)),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        e.service,
                        style: TextStyle(color: c.text, fontWeight: FontWeight.w800),
                      ),
                      Text.rich(
                        TextSpan(
                          children: [
                            TextSpan(
                              text: e.name,
                              style: const TextStyle(fontFamily: 'monospace'),
                            ),
                            if (e.username.isNotEmpty) TextSpan(text: ' · ${e.username}'),
                          ],
                        ),
                        style: TextStyle(color: c.dim, fontSize: 12.5),
                      ),
                      if (e.usedBy case final u?)
                        Text(
                          '${l.vkKcUsedBy} ${vaultPageOf(l, u.section)}',
                          key: Key('kc-item-used-by-${e.id}'),
                          style: TextStyle(
                            color: c.accent,
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      if (e.tags.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Wrap(
                            spacing: 4,
                            runSpacing: 4,
                            children: [
                              for (final t in e.tags)
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: c.panel2,
                                    borderRadius: BorderRadius.circular(99),
                                  ),
                                  child: Text(t, style: TextStyle(color: c.dim, fontSize: 11.5)),
                                ),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Flexible(
                  flex: 0,
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 150),
                    child: Text(
                      left ??
                          (e.lastUsedAt != null
                              ? l.vkKcUsedTimes('${e.uses}', _when(l, e.lastUsedAt!))
                              : l.vkKcNeverUsed),
                      textAlign: TextAlign.right,
                      style: TextStyle(
                        color: left != null ? c.warnText : c.dim,
                        fontSize: 12,
                        fontWeight: left != null ? FontWeight.w700 : FontWeight.w400,
                      ),
                    ),
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

class _Ico extends StatelessWidget {
  const _Ico(this.icon);

  final RgIcons icon;

  @override
  Widget build(BuildContext context) {
    final c = RgColors.of(context);
    return Container(
      width: 38,
      height: 38,
      decoration: BoxDecoration(color: c.accentSoft, borderRadius: BorderRadius.circular(10)),
      child: Center(child: RgIcon(icon, size: 19, color: c.accent)),
    );
  }
}

/// A key the server keeps for itself: read only here, managed in its own page.
class _SystemItem extends StatelessWidget {
  const _SystemItem({required this.entry});

  final VaultSystemEntry entry;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final c = RgColors.of(context);
    final e = entry;
    return Container(
      key: Key('kc-system-${e.id}'),
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: c.panel,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: c.line),
      ),
      child: Row(
        children: [
          _Ico(vaultCategoryIcon(e.category)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  e.service,
                  style: TextStyle(color: c.text, fontWeight: FontWeight.w800),
                ),
                Text(_systemWhat(l, e), style: TextStyle(color: c.dim, fontSize: 12.5)),
                Text(
                  e.locked ? l.vkKcLockedAdmin : '${l.vkKcManage}: ${vaultPageOf(l, e.section)}',
                  style: TextStyle(color: c.accent, fontSize: 12, fontWeight: FontWeight.w700),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ---- importing and exporting ----

class _ImportView extends StatefulWidget {
  const _ImportView({required this.pick, required this.close});

  final PickText pick;
  final void Function([bool?]) close;

  @override
  State<_ImportView> createState() => _ImportViewState();
}

class _ImportViewState extends State<_ImportView> {
  VaultImportPreview? _preview;
  List<int> _keep = [];
  String? _sealed;
  String _pass = '';
  bool _busy = false;
  String? _error;
  int? _done;

  @override
  void dispose() {
    _sealed = null;
    _pass = '';
    super.dispose();
  }

  Future<void> _read() async {
    final c = AppScope.read(context).client;
    if (c == null) return;
    final f = await widget.pick();
    if (f == null || !mounted) return;
    setState(() => _error = null);
    final text = f.$2;
    if (text.startsWith('REDGIANT-KEYCHAIN')) {
      setState(() => _sealed = text);
      return;
    }
    try {
      final p = await c.previewVaultImport(text);
      if (mounted) {
        setState(() {
          _preview = p;
          _keep = [for (var i = 0; i < p.rows.length; i++) i];
        });
      }
    } on ApiException catch (e) {
      if (mounted) setState(() => _error = e.message);
    }
  }

  Future<void> _go() async {
    final c = AppScope.read(context).client;
    if (c == null) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final n = _sealed != null
          ? await c.importVaultFile(_sealed!, _pass)
          : await c.confirmVaultImport(_preview!.id, _keep);
      if (mounted) setState(() => _done = n);
    } on ApiException catch (e) {
      if (mounted) setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  String _format(AppLocalizations l, String f) => switch (f) {
    'bitwarden' => l.vkKcFormat_bitwarden,
    '1password' => l.vkKcFormat_1password,
    'chrome' => l.vkKcFormat_chrome,
    'firefox' => l.vkKcFormat_firefox,
    _ => l.vkKcFormat_generic,
  };

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final c = RgColors.of(context);
    final p = _preview;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (_done != null)
          AutoNotice(l.vkKcImported('$_done'), key: const Key('kc-imported'))
        else if (p == null && _sealed == null) ...[
          Text(l.vkKcImportLead, style: TextStyle(color: c.text, height: 1.45)),
          const SizedBox(height: 8),
          for (final s in [
            l.vkKcImportBitwarden,
            l.vkKcImport1password,
            l.vkKcImportChrome,
            l.vkKcImportFirefox,
          ])
            Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Text('· $s', style: TextStyle(color: c.dim, fontSize: 13)),
            ),
          const SizedBox(height: 10),
          Align(
            alignment: Alignment.centerLeft,
            child: FilledButton.icon(
              key: const Key('kc-import-pick'),
              onPressed: _read,
              icon: const RgIcon(RgIcons.upload, size: 17, color: Colors.white),
              label: Text(l.vkKcImportPick),
            ),
          ),
          const SizedBox(height: 8),
          AutoHelp(l.vkKcImportSafe),
        ] else if (_sealed != null)
          SecretField(
            label: l.vkKcPassphrase,
            help: l.vkKcImportSealedHelp,
            fieldKey: const Key('kc-import-pass'),
            onChanged: (v) => setState(() => _pass = v),
          )
        else if (p != null) ...[
          Text(
            '${l.vkKcImportFound(_format(l, p.format), '${p.rows.length}')}'
            '${p.skipped > 0 ? ' ${l.vkKcImportSkipped('${p.skipped}')}' : ''}',
            key: const Key('kc-import-found'),
            style: TextStyle(color: c.text, height: 1.45),
          ),
          AutoHelp(l.vkKcImportLogins),
          Wrap(
            spacing: 4,
            children: [
              TextButton(
                key: const Key('kc-import-all'),
                onPressed: () =>
                    setState(() => _keep = [for (var i = 0; i < p.rows.length; i++) i]),
                child: Text(l.vkKcAll),
              ),
              TextButton(
                key: const Key('kc-import-none'),
                onPressed: () => setState(() => _keep = []),
                child: Text(l.vkKcNone),
              ),
            ],
          ),
          for (final (i, row) in p.rows.indexed)
            Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Material(
                color: _keep.contains(i) ? c.accentSoft : c.panel,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(color: _keep.contains(i) ? c.accent : c.line),
                ),
                child: InkWell(
                  key: Key('kc-import-row-$i'),
                  borderRadius: BorderRadius.circular(12),
                  onTap: () => setState(
                    () => _keep = _keep.contains(i) ? ([..._keep]..remove(i)) : [..._keep, i],
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(10),
                    child: Row(
                      children: [
                        RgIcon(
                          _keep.contains(i) ? RgIcons.check : RgIcons.user,
                          size: 17,
                          color: _keep.contains(i) ? c.accent : c.dim,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                row.service,
                                style: TextStyle(color: c.text, fontWeight: FontWeight.w700),
                              ),
                              Text(
                                row.username.isNotEmpty ? row.username : row.url,
                                style: TextStyle(color: c.dim, fontSize: 12.5),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
        ],
        if (_error != null) AutoNotice(_error!, error: true, key: const Key('kc-import-error')),
        WindowActs(
          children: _done != null
              ? [
                  FilledButton(
                    key: const Key('kc-import-close'),
                    onPressed: () => widget.close(true),
                    child: Text(l.vkClose),
                  ),
                ]
              : [
                  TextButton(onPressed: () => widget.close(false), child: Text(l.vkCancel)),
                  if (p != null || _sealed != null)
                    FilledButton(
                      key: const Key('kc-import-go'),
                      onPressed:
                          _busy ||
                              (_sealed == null && _keep.isEmpty) ||
                              (_sealed != null && _pass.isEmpty)
                          ? null
                          : _go,
                      child: Text(
                        _sealed != null ? l.vkKcImportSealedGo : l.vkKcImportGo('${_keep.length}'),
                      ),
                    ),
                ],
        ),
      ],
    );
  }
}

class _ExportView extends StatefulWidget {
  const _ExportView({required this.save, required this.close});

  final SaveText save;
  final void Function([void]) close;

  @override
  State<_ExportView> createState() => _ExportViewState();
}

class _ExportViewState extends State<_ExportView> {
  String _a = '';
  String _b = '';
  String? _error;
  bool _done = false;

  Future<void> _go() async {
    final c = AppScope.read(context).client;
    if (c == null) return;
    setState(() => _error = null);
    try {
      final file = await c.exportVault(_a);
      final day = DateTime.now().toIso8601String().substring(0, 10);
      final saved = await widget.save('rasgeth-keychain-$day.rgkeychain', file);
      if (mounted && saved) setState(() => _done = true);
    } on ApiException catch (e) {
      if (mounted) setState(() => _error = e.message);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final c = RgColors.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (_done)
          AutoNotice(l.vkKcExported, key: const Key('kc-exported'))
        else ...[
          Text(l.vkKcExportLead, style: TextStyle(color: c.text, height: 1.45)),
          const SizedBox(height: 10),
          SecretField(
            label: l.vkKcPassphrase,
            help: l.vkKcPassphraseHelp,
            fieldKey: const Key('kc-export-a'),
            onChanged: (v) => setState(() => _a = v),
          ),
          SecretField(
            label: l.vkKcPassphraseAgain,
            error: _b.isNotEmpty && _a != _b ? l.vkKcPassphraseDiffer : null,
            fieldKey: const Key('kc-export-b'),
            onChanged: (v) => setState(() => _b = v),
          ),
        ],
        if (_error != null) AutoNotice(_error!, error: true),
        WindowActs(
          children: [
            TextButton(
              onPressed: () => widget.close(),
              child: Text(_done ? l.vkClose : l.vkCancel),
            ),
            if (!_done)
              FilledButton.icon(
                key: const Key('kc-export-go'),
                onPressed: _a.length < 8 || _a != _b ? null : _go,
                icon: const RgIcon(RgIcons.download, size: 17, color: Colors.white),
                label: Text(l.vkKcExportGo),
              ),
          ],
        ),
      ],
    );
  }
}

// ---- the browsers (G36.21) ----

const _browserLabel = {
  'opera': 'Opera',
  'chrome': 'Chrome',
  'edge': 'Edge',
  'brave': 'Brave',
  'firefox': 'Firefox',
  'other': 'Browser',
};
const _extensionPages = {
  'opera': 'opera://extensions',
  'chrome': 'chrome://extensions',
  'edge': 'edge://extensions',
  'brave': 'brave://extensions',
};
const _releases = 'https://github.com/Frostmoore/rasgeth/releases/latest/download';

/// «In your browser»: the linked browsers and the button that links one more.
class BrowsersPart extends StatefulWidget {
  const BrowsersPart({super.key, this.poll = true});

  final bool poll;

  @override
  State<BrowsersPart> createState() => _BrowsersPartState();
}

class _BrowsersPartState extends State<BrowsersPart> {
  List<VaultBrowser>? _list;
  String? _error;

  @override
  void initState() {
    super.initState();
    unawaited(_load());
  }

  Future<void> _load() async {
    final c = AppScope.read(context).client;
    if (c == null) return;
    try {
      final l = await c.vaultBrowsers();
      if (mounted) setState(() => _list = l);
    } on ApiException catch (e) {
      if (mounted) setState(() => _error = e.message);
    }
  }

  Future<void> _link() async {
    final l = AppLocalizations.of(context);
    final changed = await openAutoWindow<bool>(
      context,
      title: l.vkKcBrWinTitle,
      icon: RgIcon(RgIcons.globe, size: 22, color: RgColors.of(context).accent),
      key: const Key('kc-link-browser'),
      child: (ctx, close) => _LinkBrowser(close: close, poll: widget.poll),
    );
    if (changed ?? true) await _load();
  }

  Future<void> _unlink(VaultBrowser b) async {
    final l = AppLocalizations.of(context);
    final yes = await askVaultConfirm(
      context,
      title: l.vkKcBrUnlinkQ(b.name),
      body: l.vkKcBrUnlinkText,
      yes: l.vkKcBrUnlink,
      danger: true,
    );
    if (!yes || !mounted) return;
    try {
      await AppScope.read(context).client?.unlinkVaultBrowser(b.id);
    } on ApiException catch (e) {
      if (mounted) setState(() => _error = e.message);
    }
    await _load();
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final c = RgColors.of(context);
    final list = _list;
    return Column(
      key: const Key('kc-browsers'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        RulesSub(title: l.vkKcBrTitle, lead: l.vkKcBrLead),
        if (list != null && list.isEmpty) AutoHelp(l.vkKcBrNone),
        for (final b in list ?? const <VaultBrowser>[])
          Container(
            key: Key('kc-browser-${b.id}'),
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: c.panel,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: c.line),
            ),
            child: Row(
              children: [
                const _Ico(RgIcons.globe),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        b.name,
                        style: TextStyle(color: c.text, fontWeight: FontWeight.w800),
                      ),
                      Text(
                        [
                          _browserLabel[b.browser] ?? b.browser,
                          l.vkKcBrLinked(_when(l, b.createdAt)),
                          b.lastSeenAt != null
                              ? l.vkKcBrSeen(_when(l, b.lastSeenAt!))
                              : l.vkKcBrNever,
                        ].join(' · '),
                        style: TextStyle(color: c.dim, fontSize: 12.5),
                      ),
                    ],
                  ),
                ),
                TextButton.icon(
                  key: Key('kc-unlink-${b.id}'),
                  onPressed: () => _unlink(b),
                  icon: RgIcon(RgIcons.trash, size: 15, color: c.err),
                  label: Text(l.vkKcBrUnlink, style: TextStyle(color: c.err)),
                ),
              ],
            ),
          ),
        Align(
          alignment: Alignment.centerLeft,
          child: OutlinedButton.icon(
            key: const Key('kc-link'),
            onPressed: _link,
            icon: const RgIcon(RgIcons.globe, size: 17),
            label: Text(l.vkKcBrLink),
          ),
        ),
        if (_error != null) AutoNotice(_error!, error: true),
      ],
    );
  }
}

class _LinkBrowser extends StatefulWidget {
  const _LinkBrowser({required this.close, required this.poll});

  final void Function([bool?]) close;
  final bool poll;

  @override
  State<_LinkBrowser> createState() => _LinkBrowserState();
}

class _LinkBrowserState extends State<_LinkBrowser> {
  String _browser = 'opera';
  ({String code, String expiresAt})? _code;
  VaultBrowser? _linked;
  bool _expired = false;
  String? _error;
  Set<String> _known = {};
  Timer? _timer;

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _make() async {
    final c = AppScope.read(context).client;
    if (c == null) return;
    setState(() {
      _error = null;
      _expired = false;
    });
    try {
      _known = {for (final b in await c.vaultBrowsers()) b.id};
      final code = await c.vaultBrowserCode();
      if (!mounted) return;
      setState(() => _code = code);
      _timer?.cancel();
      // While a code is shown: is a new browser there yet? (every three seconds, until it expires)
      if (widget.poll) _timer = Timer.periodic(const Duration(seconds: 3), (_) => _check());
    } on ApiException catch (e) {
      if (mounted) setState(() => _error = e.message);
    }
  }

  Future<void> _check() async {
    final code = _code;
    final c = AppScope.read(context).client;
    if (code == null || c == null || _linked != null) return;
    final until = DateTime.tryParse(code.expiresAt);
    if (until != null && until.isBefore(DateTime.now())) {
      _timer?.cancel();
      if (mounted) {
        setState(() {
          _expired = true;
          _code = null;
        });
      }
      return;
    }
    try {
      final fresh = (await c.vaultBrowsers()).where((b) => !_known.contains(b.id)).firstOrNull;
      if (fresh != null && mounted) {
        _timer?.cancel();
        setState(() => _linked = fresh);
      }
    } on ApiException {
      // Asked again at the next tick.
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final c = RgColors.of(context);
    final app = AppScope.of(context);
    final base = app.client?.base;
    final address = base?.origin ?? '';
    final local = RegExp(r'^(localhost|127\.|10\.|192\.168\.|172\.(1[6-9]|2\d|3[01])\.|\[::1\])')
        .hasMatch(base?.host ?? '');
    final away = base?.scheme == 'http' && !local && (base?.host.contains('.') ?? false);
    final firefox = _browser == 'firefox';
    final how = firefox
        ? l.vkKcBrHowFirefox
        : _browser == 'opera'
        ? l.vkKcBrHowOpera
        : l.vkKcBrHowChromium(_extensionPages[_browser]!);
    final zip = firefox ? 'rasgeth-keychain-firefox.zip' : 'rasgeth-keychain-chromium.zip';
    final code = _code;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(l.vkKcBrWinLead, style: TextStyle(color: c.text, height: 1.45)),
        AutoLb(l.vkKcBrStep1),
        RgChoice<String>(
          options: [
            for (final b in const ['opera', 'chrome', 'edge', 'brave', 'firefox'])
              (b, _browserLabel[b]!),
          ],
          value: _browser,
          keyOf: (b) => 'kc-br-$b',
          onChanged: (b) => setState(() => _browser = b),
        ),
        const SizedBox(height: 8),
        Align(
          alignment: Alignment.centerLeft,
          child: FilledButton.icon(
            key: const Key('kc-br-download'),
            // The zips this server serves (built with it), else the latest release's.
            onPressed: () => openOutside(address.isEmpty ? '$_releases/$zip' : '$address/$zip'),
            icon: const RgIcon(RgIcons.download, size: 17, color: Colors.white),
            label: Text(firefox ? l.vkKcBrDownloadFirefox : l.vkKcBrDownload),
          ),
        ),
        const SizedBox(height: 6),
        AutoHelp(how),
        AutoHelp(l.vkKcBrStore),
        AutoLb(l.vkKcBrStep2),
        if (away) WarnLine(l.vkKcBrHttpNote),
        if (_linked != null)
          AutoNotice(l.vkKcBrDone(_linked!.name), key: const Key('kc-br-done'))
        else if (code != null) ...[
          AutoHelp(l.vkKcBrCodeLead),
          _CopyRow(label: l.vkKcBrAddress, value: address),
          _CopyRow(label: l.vkKcBrCode, value: code.code, big: true),
          AutoHelp(
            l.vkKcBrExpires(
              DateTime.tryParse(code.expiresAt) == null
                  ? ''
                  : DateFormat.Hm(l.localeName).format(DateTime.parse(code.expiresAt).toLocal()),
            ),
          ),
        ] else ...[
          if (_expired) WarnLine(l.vkKcBrExpired),
          Align(
            alignment: Alignment.centerLeft,
            child: FilledButton.icon(
              key: const Key('kc-br-make'),
              onPressed: _make,
              icon: const RgIcon(RgIcons.key, size: 17, color: Colors.white),
              label: Text(l.vkKcBrMakeCode),
            ),
          ),
        ],
        if (_error != null) AutoNotice(_error!, error: true),
        WindowActs(
          children: [
            TextButton(onPressed: () => widget.close(_linked != null), child: Text(l.vkClose)),
          ],
        ),
      ],
    );
  }
}

class _CopyRow extends StatelessWidget {
  const _CopyRow({required this.label, required this.value, this.big = false});

  final String label;
  final String value;
  final bool big;

  @override
  Widget build(BuildContext context) {
    final c = RgColors.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: TextStyle(color: c.dim, fontSize: 12.5)),
          Row(
            children: [
              Expanded(
                child: SelectableText(
                  value,
                  key: Key(big ? 'kc-br-code' : 'kc-br-address'),
                  style: TextStyle(
                    fontFamily: 'monospace',
                    color: c.text,
                    fontSize: big ? 24 : 13.5,
                    fontWeight: big ? FontWeight.w800 : FontWeight.w500,
                    letterSpacing: big ? 3 : 0,
                  ),
                ),
              ),
              CopyButton(text: value),
            ],
          ),
        ],
      ),
    );
  }
}

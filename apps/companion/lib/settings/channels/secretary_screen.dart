// 3.12.4: Settings › Messages, native, as the page's Secretary.tsx: the secretary that answers
// OTHER people on a WhatsApp Business number or a Telegram bot. The requests waiting for the person
// (summary and a ready reply: send, edit, refuse), the business accounts with the step-by-step
// guides (each step checked against the platform by the server), and every contact's conversation
// (take over, pause the agent for one person). Keys go out once and never come back.
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../api/client.dart';
import '../../api/types.dart' show AgentKind;
import '../../app_state.dart';
import '../../l10n/app_localizations.dart';
import '../../theme/colors.dart';
import '../../ui/dialogs.dart' show askConfirm;
import '../../ui/icons.dart';
import '../knowledge_kit.dart';
import '../rules_kit.dart';
import '../system/remote_screen.dart' show openRemoteSettings;

Future<void> openSecretarySettings(BuildContext context) =>
    openRulesPage(context, (panel) => SecretaryScreen(panel: panel));

Map<String, dynamic> _obj(Object? o) => o is Map<String, dynamic> ? o : <String, dynamic>{};
List<Map<String, dynamic>> _list(Object? o) => [
  for (final x in o is List ? o : const [])
    if (x is Map<String, dynamic>) x,
];
String _id(String id) => Uri.encodeComponent(id);

/// The account as the server shows it (never a key).
class SecretaryAccount {
  const SecretaryAccount(this.j);
  final Map<String, dynamic> j;
  String get id => '${j['id']}';
  String get channel => '${j['channel']}';
  String get name => '${j['name'] ?? ''}';
  String get label => '${j['label'] ?? ''}';
  String? get agentId => j['agentId'] as String?;
  String? get webhookUrl => j['webhookUrl'] as String?;
  String? get verifyToken => j['verifyToken'] as String?;
  bool get webhookOk => j['webhookOk'] == true;
  bool get complete => j['complete'] == true;
  int get limitPerHour => (j['limitPerHour'] as num?)?.toInt() ?? 6;
}

class SecretaryContact {
  const SecretaryContact(this.j);
  final Map<String, dynamic> j;
  String get id => '${j['id']}';
  String get channel => '${j['channel']}';
  String get handle => '${j['handle']}';
  String get name => '${j['name'] ?? ''}';
  String get notes => '${j['notes'] ?? ''}';
  String get lastText => '${j['lastText'] ?? ''}';
  bool get paused => j['paused'] == true;
  bool get stopped => j['stopped'] == true;
  bool get windowOpen => j['windowOpen'] == true;
  int get unread => (j['unread'] as num?)?.toInt() ?? 0;
  int get pending => (j['pending'] as num?)?.toInt() ?? 0;
  String get who => name.isEmpty ? handle : name;
}

class SecretaryPending {
  const SecretaryPending(this.j);
  final Map<String, dynamic> j;
  String get id => '${j['id']}';
  String get contactName => '${j['contactName'] ?? ''}';
  String get reason => '${j['reason']}';
  String get summary => '${j['summary'] ?? ''}';
  String get draft => '${j['draft'] ?? ''}';
}

class SecretaryMessage {
  const SecretaryMessage(this.j);
  final Map<String, dynamic> j;
  bool get incoming => j['dir'] == 'in';
  String get by => '${j['by']}';
  String get text => '${j['text'] ?? ''}';
}

/// What a guide step's check answered.
class SecretaryCheck {
  const SecretaryCheck(this.j);
  final Map<String, dynamic> j;
  bool get ok => j['ok'] == true;
  String get code => '${j['code'] ?? 'failed'}';
  String? get detail => j['detail'] as String?;
  String get number => '${j['number'] ?? ''}';
  String get verifiedName => '${j['verifiedName'] ?? ''}';
  String get username => '${j['username'] ?? ''}';
}

extension SecretaryApi on RedGiantClient {
  Future<List<SecretaryAccount>> secretaryAccounts() async => [
    for (final o in _list(_obj(await getJson('/api/secretary/accounts'))['accounts']))
      SecretaryAccount(o),
  ];

  Future<({List<SecretaryContact> contacts, List<SecretaryPending> pending})>
  secretaryContacts() async {
    final j = _obj(await getJson('/api/secretary/contacts'));
    return (
      contacts: [for (final o in _list(j['contacts'])) SecretaryContact(o)],
      pending: [for (final o in _list(j['pending'])) SecretaryPending(o)],
    );
  }

  Future<SecretaryCheck> secretaryCheck(
    String channel,
    String step, {
    String? token,
    String? phoneNumberId,
  }) async => SecretaryCheck(
    _obj(
      await callJson('POST', '/api/secretary/check', {
        'channel': channel,
        'step': step,
        'token': ?token,
        'phoneNumberId': ?phoneNumberId,
      }),
    ),
  );

  Future<SecretaryAccount> secretaryStartWhatsApp() async =>
      SecretaryAccount(_obj(await callJson('POST', '/api/secretary/whatsapp/start', {'name': ''})));

  Future<void> secretaryFinishWhatsApp(String id, Map<String, Object?> b) =>
      callJson('POST', '/api/secretary/whatsapp/${_id(id)}/finish', b);

  Future<void> secretaryConnectTelegram(Map<String, Object?> b) =>
      callJson('POST', '/api/secretary/telegram', b);

  Future<void> secretaryUpdateAccount(String id, Map<String, Object?> b) =>
      callJson('PATCH', '/api/secretary/accounts/${_id(id)}', b);

  Future<void> secretaryRemoveAccount(String id) =>
      callJson('DELETE', '/api/secretary/accounts/${_id(id)}');

  Future<
    ({SecretaryContact contact, List<SecretaryMessage> messages, List<SecretaryPending> pending})
  >
  secretaryConversation(String id) async {
    final j = _obj(await getJson('/api/secretary/contacts/${_id(id)}'));
    return (
      contact: SecretaryContact(_obj(j['contact'])),
      messages: [for (final o in _list(j['messages'])) SecretaryMessage(o)],
      pending: [for (final o in _list(j['pending'])) SecretaryPending(o)],
    );
  }

  Future<void> secretaryPatchContact(String id, Map<String, Object?> b) =>
      callJson('PATCH', '/api/secretary/contacts/${_id(id)}', b);

  Future<void> secretaryDeleteContact(String id) =>
      callJson('DELETE', '/api/secretary/contacts/${_id(id)}');

  Future<void> secretarySend(String id, String text) =>
      callJson('POST', '/api/secretary/contacts/${_id(id)}/send', {'text': text});

  Future<void> secretaryApprove(String id, [String? text]) =>
      callJson('POST', '/api/secretary/pending/${_id(id)}/approve', {'text': ?text});

  Future<void> secretaryRefuse(String id) =>
      callJson('POST', '/api/secretary/pending/${_id(id)}/refuse');
}

/// The words for a check's code, as the page says them.
String secretaryWhy(AppLocalizations l, String code) => switch (code) {
  'no_remote' => l.scErr_no_remote,
  'not_https' => l.scErr_not_https,
  'bad_token' => l.scErr_bad_token,
  'bad_number' => l.scErr_bad_number,
  'bad_secret' => l.scErr_bad_secret,
  'no_access' => l.scErr_no_access,
  'unreachable' => l.scErr_unreachable,
  'webhook_failed' => l.scErr_webhook_failed,
  _ => l.scErr_failed,
};

String _failure(AppLocalizations l, Object e) =>
    e is ApiException && e.code != null ? secretaryWhy(l, e.code!) : rulesWhy(e);

String _reasonWords(AppLocalizations l, String r) => switch (r) {
  'commitment' => l.scReason_commitment,
  'price' => l.scReason_price,
  'file' => l.scReason_file,
  'limit' => l.scReason_limit,
  'unknown' => l.scReason_unknown,
  _ => l.scReason_other,
};

final _phoneId = RegExp(r'^\d{5,25}$');
final _appSecret = RegExp(r'^[0-9a-fA-F]{32}$');
final _botToken = RegExp(r'^\d+:[\w-]{20,}$');

class SecretaryScreen extends StatefulWidget {
  const SecretaryScreen({super.key, this.panel = false, this.poll = true});

  final bool panel;

  /// Read again every few seconds (tests pump by hand).
  final bool poll;

  @override
  State<SecretaryScreen> createState() => _SecretaryScreenState();
}

class _SecretaryScreenState extends State<SecretaryScreen> {
  List<SecretaryAccount>? _accounts;
  List<SecretaryContact> _contacts = const [];
  List<SecretaryPending> _pending = const [];
  String? _error;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    unawaited(_load());
    if (widget.poll) _timer = Timer.periodic(const Duration(seconds: 8), (_) => _load());
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _load() async {
    if (!mounted) return;
    final c = AppScope.read(context).client;
    if (c == null) return;
    try {
      final a = await c.secretaryAccounts();
      final k = await c.secretaryContacts();
      if (!mounted) return;
      setState(() {
        _accounts = a;
        _contacts = k.contacts;
        _pending = k.pending;
        _error = null;
      });
    } on Object catch (e) {
      if (mounted) setState(() => _error = rulesWhy(e));
    }
  }

  Future<void> _window(
    String key,
    String title,
    Widget Function(void Function([void])) body,
  ) async {
    await kbWindow<void>(
      context,
      key: Key(key),
      title: title,
      wide: true,
      body: (ctx, close) => body(close),
    );
    await _load();
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final c = RgColors.of(context);
    final accounts = _accounts;
    return RulesPage(
      pageKey: const Key('secretary-page'),
      title: l.scSection,
      question: l.scQ,
      lead: l.scLead,
      panel: widget.panel,
      children: [
        if (accounts == null)
          RulesLoading(error: _error)
        else ...[
          if (_pending.isNotEmpty) ...[
            RulesSub(title: l.scPendingTitle('${_pending.length}'), lead: l.scPendingLead),
            for (final p in _pending)
              PendingCard(key: Key('sc-pending-${p.id}'), p: p, onDone: _load),
          ],
          RulesSub(title: l.scAccountsTitle, lead: l.scAccountsLead),
          KbTiles(
            children: [
              for (final a in accounts)
                KbTile(
                  key: Key('sc-account-${a.id}'),
                  icon: a.channel == 'telegram' ? RgIcons.send : RgIcons.chat,
                  title: a.name.isEmpty
                      ? (a.channel == 'telegram' ? 'Telegram' : 'WhatsApp Business')
                      : a.name,
                  text: a.label,
                  on: a.complete,
                  state: a.complete ? l.scConnected : l.scNotFinished,
                  onTap: () => _window(
                    'sc-account-window',
                    a.name.isEmpty ? a.label : a.name,
                    (close) => _AccountEditor(a: a, onDone: close),
                  ),
                ),
              KbTile(
                key: const Key('sc-add-wa'),
                icon: RgIcons.plus,
                title: l.scAddWa,
                text: l.scAddWaText,
                on: false,
                onTap: () =>
                    _window('sc-wa-guide', l.scWaTitle, (close) => WhatsAppGuide(onDone: close)),
              ),
              KbTile(
                key: const Key('sc-add-tg'),
                icon: RgIcons.plus,
                title: l.scAddTg,
                text: l.scAddTgText,
                on: false,
                onTap: () =>
                    _window('sc-tg-guide', l.scTgTitle, (close) => TelegramGuide(onDone: close)),
              ),
            ],
          ),
          RulesSub(title: l.scContactsTitle, lead: l.scContactsLead),
          if (_contacts.isEmpty)
            Padding(
              padding: const EdgeInsets.all(4),
              child: Text(l.scNoContacts, style: TextStyle(color: c.dim)),
            ),
          for (final k in _contacts)
            Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: InkWell(
                key: Key('sc-contact-${k.id}'),
                borderRadius: BorderRadius.circular(12),
                onTap: () => _window(
                  'sc-conversation',
                  k.who,
                  (close) => Conversation(id: k.id, onDone: close, poll: widget.poll),
                ),
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: c.panel,
                    border: Border.all(color: c.line),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        k.channel == 'telegram' ? Icons.send : Icons.chat_bubble_outline,
                        size: 18,
                        color: c.dim,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              k.who,
                              style: TextStyle(fontWeight: FontWeight.w700, color: c.text),
                            ),
                            Text(
                              k.lastText,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(color: c.dim, fontSize: 13),
                            ),
                          ],
                        ),
                      ),
                      if (k.paused) Text(l.scPaused, style: TextStyle(color: c.dim, fontSize: 12)),
                      if (k.pending > 0)
                        Padding(
                          padding: const EdgeInsets.only(left: 8),
                          child: Text(l.scAsks, style: TextStyle(color: c.warn, fontSize: 12)),
                        ),
                      if (k.unread > 0)
                        Container(
                          margin: const EdgeInsets.only(left: 8),
                          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                          decoration: BoxDecoration(
                            color: c.accent,
                            borderRadius: BorderRadius.circular(11),
                          ),
                          child: Text(
                            '${k.unread}',
                            style: const TextStyle(color: Colors.white, fontSize: 12),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ],
    );
  }
}

/// A request for the person: the summary and the ready reply (send as it is, edit, refuse).
class PendingCard extends StatefulWidget {
  const PendingCard({super.key, required this.p, required this.onDone});

  final SecretaryPending p;
  final Future<void> Function() onDone;

  @override
  State<PendingCard> createState() => _PendingCardState();
}

class _PendingCardState extends State<PendingCard> {
  late final _text = TextEditingController(text: widget.p.draft);
  String? _error;

  @override
  void dispose() {
    _text.dispose();
    super.dispose();
  }

  Future<void> _act(Future<void> Function(RedGiantClient c) f) async {
    final c = AppScope.read(context).client;
    if (c == null) return;
    try {
      await f(c);
      await widget.onDone();
    } on Object catch (e) {
      if (mounted) setState(() => _error = _failure(AppLocalizations.of(context), e));
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final c = RgColors.of(context);
    final edited = _text.text.trim() != widget.p.draft.trim();
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: c.panel,
        border: Border.all(color: c.warn),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            widget.p.contactName,
            style: TextStyle(fontWeight: FontWeight.w700, color: c.text),
          ),
          Text(_reasonWords(l, widget.p.reason), style: TextStyle(color: c.dim, fontSize: 12)),
          const SizedBox(height: 6),
          Text(widget.p.summary, style: TextStyle(color: c.text)),
          const SizedBox(height: 8),
          TextField(
            key: Key('sc-draft-${widget.p.id}'),
            controller: _text,
            minLines: 2,
            maxLines: 6,
            onChanged: (_) => setState(() {}),
            decoration: InputDecoration(labelText: l.scReady),
          ),
          if (_error != null) KbLine(_error!, error: true),
          KbActs(
            children: [
              TextButton(
                key: Key('sc-refuse-${widget.p.id}'),
                onPressed: () => _act((c) => c.secretaryRefuse(widget.p.id)),
                child: Text(l.scRefuse),
              ),
              FilledButton(
                key: Key('sc-send-${widget.p.id}'),
                onPressed: _text.text.trim().isEmpty
                    ? null
                    : () => _act(
                        (c) => c.secretaryApprove(widget.p.id, edited ? _text.text.trim() : null),
                      ),
                child: Text(edited ? l.scSendEdited : l.scSend),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _AccountEditor extends StatefulWidget {
  const _AccountEditor({required this.a, required this.onDone});

  final SecretaryAccount a;
  final void Function([void]) onDone;

  @override
  State<_AccountEditor> createState() => _AccountEditorState();
}

class _AccountEditorState extends State<_AccountEditor> {
  late String _agent = widget.a.agentId ?? '';
  late final _limit = TextEditingController(text: '${widget.a.limitPerHour}');

  @override
  void dispose() {
    _limit.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final c = RgColors.of(context);
    final client = AppScope.read(context).client;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        KbLine(widget.a.complete ? widget.a.label : l.scNotFinished),
        AgentPicker(value: _agent, onChanged: (v) => setState(() => _agent = v)),
        TextField(
          key: const Key('sc-limit'),
          controller: _limit,
          keyboardType: TextInputType.number,
          decoration: InputDecoration(labelText: l.scLimit, helperText: l.scLimitHelp),
        ),
        KbActs(
          children: [
            TextButton(
              key: const Key('sc-remove'),
              onPressed: client == null
                  ? null
                  : () async {
                      await client.secretaryRemoveAccount(widget.a.id);
                      widget.onDone();
                    },
              child: Text(l.scRemove, style: TextStyle(color: c.err)),
            ),
            FilledButton(
              key: const Key('sc-account-save'),
              onPressed: client == null
                  ? null
                  : () async {
                      await client.secretaryUpdateAccount(widget.a.id, {
                        'agentId': _agent.isEmpty ? null : _agent,
                        'limitPerHour': (int.tryParse(_limit.text) ?? 6).clamp(1, 60),
                      });
                      widget.onDone();
                    },
              child: Text(l.save),
            ),
          ],
        ),
      ],
    );
  }
}

/// Who answers: any agent the person has.
class AgentPicker extends StatelessWidget {
  const AgentPicker({super.key, required this.value, required this.onChanged});

  final String value;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final agents = AppScope.read(context).agents
        .where((a) => a.kind != AgentKind.god && a.kind != AgentKind.assistant)
        .toList();
    return Padding(
      padding: const EdgeInsets.only(top: 10),
      child: DropdownButtonFormField<String>(
        key: const Key('sc-agent'),
        initialValue: agents.any((a) => a.id == value) ? value : '',
        isExpanded: true,
        decoration: InputDecoration(
          labelText: l.scAgent,
          helperText: l.scAgentHelp,
          helperMaxLines: 3,
        ),
        items: [
          DropdownMenuItem(value: '', child: Text(l.scAgentNone)),
          for (final a in agents) DropdownMenuItem(value: a.id, child: Text(a.name)),
        ],
        onChanged: (v) => onChanged(v ?? ''),
      ),
    );
  }
}

/// One numbered step of a guide: open only when it is the current one.
class GuideStep extends StatelessWidget {
  const GuideStep({
    super.key,
    required this.n,
    required this.title,
    required this.current,
    required this.done,
    required this.children,
  });

  final int n;
  final String title;
  final bool current;
  final bool done;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final c = RgColors.of(context);
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: c.panel,
        border: Border.all(color: current ? c.accent : c.line),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 26,
            height: 26,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: current || done ? c.accent : c.panel2,
            ),
            child: Text(
              '$n',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: current || done ? Colors.white : c.text,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  title,
                  style: TextStyle(fontWeight: FontWeight.w700, color: c.text),
                ),
                if (current) ...children,
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _CopyLine extends StatelessWidget {
  const _CopyLine({required this.label, required this.text});

  final String label;
  final String text;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final c = RgColors.of(context);
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: TextStyle(fontSize: 12, color: c.dim)),
                SelectableText(text, style: TextStyle(color: c.text, fontSize: 13)),
              ],
            ),
          ),
          TextButton(
            onPressed: () => Clipboard.setData(ClipboardData(text: text)),
            child: Text(l.scCopy),
          ),
        ],
      ),
    );
  }
}

Future<void> _openLink(BuildContext context, String url) async {
  final l = AppLocalizations.of(context);
  final yes = await askConfirm(context, title: l.linkOpenTitle, body: url, yes: l.linkOpen);
  if (yes) await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
}

Widget _field(
  String k,
  String label,
  TextEditingController c, {
  bool secret = false,
  String? help,
  VoidCallback? changed,
}) => Padding(
  padding: const EdgeInsets.only(top: 10),
  child: TextField(
    key: Key(k),
    controller: c,
    obscureText: secret,
    autocorrect: false,
    enableSuggestions: !secret,
    onChanged: (_) => changed?.call(),
    decoration: InputDecoration(labelText: label, helperText: help, helperMaxLines: 3),
  ),
);

/// The «remote access» step both guides begin with: checked as soon as it opens.
class _RemoteStep extends StatefulWidget {
  const _RemoteStep({required this.onOk});

  final VoidCallback onOk;

  @override
  State<_RemoteStep> createState() => _RemoteStepState();
}

class _RemoteStepState extends State<_RemoteStep> {
  String? _text;
  bool _ok = false;

  @override
  void initState() {
    super.initState();
    unawaited(_run());
  }

  Future<void> _run() async {
    final c = AppScope.read(context).client;
    if (c == null) return;
    // Called from initState: the words are read after the first await, never before the build.
    await Future<void>.value();
    if (!mounted) return;
    final l = AppLocalizations.of(context);
    try {
      final r = await c.secretaryCheck('whatsapp', 'remote');
      if (!mounted) return;
      setState(() {
        _ok = r.ok;
        _text = r.ok ? l.scRemoteOk(r.detail ?? '') : secretaryWhy(l, r.code);
      });
      if (r.ok) widget.onOk();
    } on Object catch (e) {
      if (mounted) setState(() => _text = _failure(l, e));
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        KbLine(l.scRemoteText),
        if (_text != null) KbLine(_text!, error: !_ok),
        if (_text != null && !_ok)
          KbActs(
            children: [
              TextButton(
                key: const Key('sc-open-remote'),
                onPressed: () => openRemoteSettings(context),
                child: Text(l.scOpenRemote),
              ),
              FilledButton(
                key: const Key('sc-check-again'),
                onPressed: _run,
                child: Text(l.scCheckAgain),
              ),
            ],
          ),
      ],
    );
  }
}

Widget _next(String key, String label, VoidCallback? onTap) => KbActs(
  children: [FilledButton(key: Key(key), onPressed: onTap, child: Text(label))],
);

class WhatsAppGuide extends StatefulWidget {
  const WhatsAppGuide({super.key, required this.onDone});

  final void Function([void]) onDone;

  @override
  State<WhatsAppGuide> createState() => _WhatsAppGuideState();
}

class _WhatsAppGuideState extends State<WhatsAppGuide> {
  int _step = 0;
  bool _busy = false;
  String? _msg;
  bool _msgOk = false;
  SecretaryAccount? _account;
  String _agent = '';
  Timer? _poll;
  final _phone = TextEditingController();
  final _token = TextEditingController();
  final _secret = TextEditingController();
  final _tpl = TextEditingController();
  final _lang = TextEditingController(text: 'it');

  @override
  void dispose() {
    _poll?.cancel();
    for (final c in [_phone, _token, _secret, _tpl, _lang]) {
      c.dispose();
    }
    super.dispose();
  }

  void _go(int n) => setState(() {
    _msg = null;
    _step = n;
  });

  /// The account exists before Meta calls, so Meta can check the webhook while the form is filled.
  Future<void> _startAccount() async {
    final c = AppScope.read(context).client;
    if (c == null || _account != null) return;
    try {
      final a = await c.secretaryStartWhatsApp();
      if (!mounted) return;
      setState(() => _account = a);
      _poll = Timer.periodic(const Duration(seconds: 3), (_) async {
        final list = await c.secretaryAccounts().catchError((Object _) => <SecretaryAccount>[]);
        final fresh = list.where((x) => x.id == a.id).firstOrNull;
        if (mounted && fresh != null) setState(() => _account = fresh);
      });
    } on Object catch (e) {
      if (mounted) setState(() => _msg = _failure(AppLocalizations.of(context), e));
    }
  }

  Future<void> _test() async {
    final c = AppScope.read(context).client;
    if (c == null) return;
    final l = AppLocalizations.of(context);
    setState(() => _busy = true);
    try {
      final r = await c.secretaryCheck(
        'whatsapp',
        'token',
        token: _token.text.trim(),
        phoneNumberId: _phone.text.trim(),
      );
      if (!mounted) return;
      setState(() {
        _msgOk = r.ok;
        _msg = r.ok ? l.scTokenOk(r.number, r.verifiedName) : secretaryWhy(l, r.code);
        if (r.ok) _step = 4;
      });
    } on Object catch (e) {
      if (mounted) setState(() => _msg = _failure(l, e));
    }
    if (mounted) setState(() => _busy = false);
  }

  Future<void> _finish() async {
    final c = AppScope.read(context).client;
    final a = _account;
    if (c == null || a == null) return;
    setState(() => _busy = true);
    try {
      await c.secretaryFinishWhatsApp(a.id, {
        'name': '',
        'phoneNumberId': _phone.text.trim(),
        'token': _token.text.trim(),
        'appSecret': _secret.text.trim(),
        if (_agent.isNotEmpty) 'agentId': _agent,
        if (_tpl.text.trim().isNotEmpty)
          'template': {
            'name': _tpl.text.trim(),
            'language': _lang.text.trim().isEmpty ? 'it' : _lang.text.trim(),
          },
      });
      _token.clear();
      _secret.clear();
      widget.onDone();
      return;
    } on Object catch (e) {
      if (mounted) {
        setState(() {
          _msgOk = false;
          _msg = _failure(AppLocalizations.of(context), e);
        });
      }
    }
    if (mounted) setState(() => _busy = false);
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final a = _account;
    final secretBad = _secret.text.isNotEmpty && !_appSecret.hasMatch(_secret.text.trim());
    return Column(
      key: const Key('sc-wa-guide-body'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        KbLine(l.scWaLead),
        const SizedBox(height: 8),
        GuideStep(
          n: 1,
          title: l.scWa_remote,
          current: _step == 0,
          done: _step > 0,
          children: [
            _RemoteStep(
              onOk: () => Future<void>.delayed(const Duration(milliseconds: 600), () {
                if (mounted && _step == 0) _go(1);
              }),
            ),
          ],
        ),
        GuideStep(
          n: 2,
          title: l.scWa_app,
          current: _step == 1,
          done: _step > 1,
          children: [
            KbLine(l.scWaAppText),
            TextButton(
              onPressed: () => _openLink(context, 'https://developers.facebook.com/apps/'),
              child: Text(l.scWaAppLink),
            ),
            _next('sc-wa-next-2', l.scNext, () => _go(2)),
          ],
        ),
        GuideStep(
          n: 3,
          title: l.scWa_number,
          current: _step == 2,
          done: _step > 2,
          children: [
            KbLine(l.scWaNumberText),
            _field('sc-wa-phone', l.scWaNumberLabel, _phone, changed: () => setState(() {})),
            _next(
              'sc-wa-next-3',
              l.scNext,
              _phoneId.hasMatch(_phone.text.trim()) ? () => _go(3) : null,
            ),
          ],
        ),
        GuideStep(
          n: 4,
          title: l.scWa_token,
          current: _step == 3,
          done: _step > 3,
          children: [
            KbLine(l.scWaTokenText),
            _field(
              'sc-wa-token',
              l.scWaTokenLabel,
              _token,
              secret: true,
              help: l.scKeyHelp,
              changed: () => setState(() {}),
            ),
            if (_msg != null) KbLine(_msg!, error: !_msgOk),
            _next(
              'sc-wa-test',
              _busy ? l.scTesting : l.scTest,
              _busy || _token.text.trim().length < 20 ? null : _test,
            ),
          ],
        ),
        GuideStep(
          n: 5,
          title: l.scWa_secret,
          current: _step == 4,
          done: _step > 4,
          children: [
            KbLine(l.scWaSecretText),
            _field(
              'sc-wa-secret',
              l.scWaSecretLabel,
              _secret,
              secret: true,
              help: l.scKeyHelp,
              changed: () => setState(() {}),
            ),
            if (secretBad) KbLine(l.scErr_bad_secret, error: true),
            _next(
              'sc-wa-next-5',
              l.scNext,
              _appSecret.hasMatch(_secret.text.trim())
                  ? () {
                      _go(5);
                      unawaited(_startAccount());
                    }
                  : null,
            ),
          ],
        ),
        GuideStep(
          n: 6,
          title: l.scWa_webhook,
          current: _step == 5,
          done: _step > 5,
          children: [
            KbLine(l.scWaWebhookText),
            if (a?.webhookUrl != null) _CopyLine(label: l.scCallback, text: a!.webhookUrl!),
            if (a?.verifyToken != null) _CopyLine(label: l.scVerify, text: a!.verifyToken!),
            KbLine(a?.webhookOk == true ? l.scWebhookOk : l.scWebhookWait, error: false),
            if (_msg != null) KbLine(_msg!, error: true),
            _next('sc-wa-next-6', l.scNext, a?.webhookOk == true ? () => _go(6) : null),
          ],
        ),
        GuideStep(
          n: 7,
          title: l.scWa_subscribe,
          current: _step == 6,
          done: _step > 6,
          children: [KbLine(l.scWaSubscribeText), _next('sc-wa-next-7', l.scDone, () => _go(7))],
        ),
        GuideStep(
          n: 8,
          title: l.scWa_finish,
          current: _step == 7,
          done: false,
          children: [
            AgentPicker(value: _agent, onChanged: (v) => setState(() => _agent = v)),
            KbLine(l.scWaTemplateText),
            _field('sc-wa-tpl', l.scTemplateName, _tpl),
            _field('sc-wa-lang', l.scTemplateLang, _lang),
            if (_msg != null) KbLine(_msg!, error: !_msgOk),
            _next(
              'sc-wa-connect',
              _busy ? l.scTesting : l.scConnect,
              _busy || _agent.isEmpty ? null : _finish,
            ),
          ],
        ),
      ],
    );
  }
}

class TelegramGuide extends StatefulWidget {
  const TelegramGuide({super.key, required this.onDone});

  final void Function([void]) onDone;

  @override
  State<TelegramGuide> createState() => _TelegramGuideState();
}

class _TelegramGuideState extends State<TelegramGuide> {
  int _step = 0;
  bool _busy = false;
  String? _msg;
  bool _msgOk = false;
  String _agent = '';
  final _token = TextEditingController();

  @override
  void dispose() {
    _token.dispose();
    super.dispose();
  }

  Future<void> _test() async {
    final c = AppScope.read(context).client;
    if (c == null) return;
    final l = AppLocalizations.of(context);
    setState(() => _busy = true);
    try {
      final r = await c.secretaryCheck('telegram', 'token', token: _token.text.trim());
      if (!mounted) return;
      setState(() {
        _msgOk = r.ok;
        _msg = r.ok ? l.scBotOk(r.username) : secretaryWhy(l, r.code);
        if (r.ok) _step = 3;
      });
    } on Object catch (e) {
      if (mounted) setState(() => _msg = _failure(l, e));
    }
    if (mounted) setState(() => _busy = false);
  }

  Future<void> _connect() async {
    final c = AppScope.read(context).client;
    if (c == null) return;
    setState(() => _busy = true);
    try {
      await c.secretaryConnectTelegram({
        'name': '',
        'token': _token.text.trim(),
        if (_agent.isNotEmpty) 'agentId': _agent,
      });
      _token.clear();
      widget.onDone();
      return;
    } on Object catch (e) {
      if (mounted) {
        setState(() {
          _msgOk = false;
          _msg = _failure(AppLocalizations.of(context), e);
        });
      }
    }
    if (mounted) setState(() => _busy = false);
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return Column(
      key: const Key('sc-tg-guide-body'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        KbLine(l.scTgLead),
        const SizedBox(height: 8),
        GuideStep(
          n: 1,
          title: l.scWa_remote,
          current: _step == 0,
          done: _step > 0,
          children: [
            _RemoteStep(
              onOk: () => Future<void>.delayed(const Duration(milliseconds: 600), () {
                if (mounted && _step == 0) setState(() => _step = 1);
              }),
            ),
          ],
        ),
        GuideStep(
          n: 2,
          title: l.scTg_botfather,
          current: _step == 1,
          done: _step > 1,
          children: [
            KbLine(l.scTgBotfatherText),
            TextButton(
              onPressed: () => _openLink(context, 'https://t.me/BotFather'),
              child: Text(l.scTgBotfatherLink),
            ),
            _next('sc-tg-next-2', l.scNext, () => setState(() => _step = 2)),
          ],
        ),
        GuideStep(
          n: 3,
          title: l.scTg_token,
          current: _step == 2,
          done: _step > 2,
          children: [
            _field(
              'sc-tg-token',
              l.scTgTokenLabel,
              _token,
              secret: true,
              help: l.scKeyHelp,
              changed: () => setState(() {}),
            ),
            if (_msg != null) KbLine(_msg!, error: !_msgOk),
            _next(
              'sc-tg-test',
              _busy ? l.scTesting : l.scTest,
              _busy || !_botToken.hasMatch(_token.text.trim()) ? null : _test,
            ),
          ],
        ),
        GuideStep(
          n: 4,
          title: l.scTg_finish,
          current: _step == 3,
          done: false,
          children: [
            AgentPicker(value: _agent, onChanged: (v) => setState(() => _agent = v)),
            if (_msg != null) KbLine(_msg!, error: !_msgOk),
            _next(
              'sc-tg-connect',
              _busy ? l.scTesting : l.scConnect,
              _busy || _agent.isEmpty ? null : _connect,
            ),
          ],
        ),
      ],
    );
  }
}

/// One contact's conversation: read, answer by hand (taking over), pause the agent, notes.
class Conversation extends StatefulWidget {
  const Conversation({super.key, required this.id, required this.onDone, this.poll = true});

  final String id;
  final void Function([void]) onDone;
  final bool poll;

  @override
  State<Conversation> createState() => _ConversationState();
}

class _ConversationState extends State<Conversation> {
  SecretaryContact? _contact;
  List<SecretaryMessage> _messages = const [];
  List<SecretaryPending> _pending = const [];
  final _text = TextEditingController();
  final _notes = TextEditingController();
  String? _error;
  Timer? _timer;
  bool _notesLoaded = false;

  @override
  void initState() {
    super.initState();
    unawaited(_load());
    if (widget.poll) _timer = Timer.periodic(const Duration(seconds: 6), (_) => _load());
  }

  @override
  void dispose() {
    _timer?.cancel();
    _text.dispose();
    _notes.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final c = AppScope.read(context).client;
    if (c == null || !mounted) return;
    try {
      final r = await c.secretaryConversation(widget.id);
      if (!mounted) return;
      setState(() {
        _contact = r.contact;
        _messages = r.messages;
        _pending = r.pending;
        if (!_notesLoaded) {
          _notes.text = r.contact.notes;
          _notesLoaded = true;
        }
      });
    } on Object catch (e) {
      if (mounted) setState(() => _error = rulesWhy(e));
    }
  }

  Future<void> _send() async {
    final c = AppScope.read(context).client;
    if (c == null) return;
    final l = AppLocalizations.of(context);
    try {
      await c.secretarySend(widget.id, _text.text.trim());
      _text.clear();
      setState(() => _error = null);
      await _load();
    } on Object catch (e) {
      if (mounted) {
        setState(
          () => _error = e is ApiException && e.code == 'window_closed'
              ? l.scWindowClosed
              : rulesWhy(e),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final c = RgColors.of(context);
    final k = _contact;
    final client = AppScope.read(context).client;
    if (k == null) return RulesLoading(error: _error);
    return Column(
      key: const Key('sc-conversation-body'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        KbLine(
          '${k.channel == 'whatsapp' ? 'WhatsApp' : 'Telegram'} · ${k.handle}'
          '${k.channel == 'whatsapp' ? ' · ${k.windowOpen ? l.scWindowOpen : l.scWindowShut}' : ''}'
          '${k.stopped ? ' · ${l.scStopped}' : ''}',
        ),
        KbSwitchRow(
          key: const Key('sc-pause'),
          title: l.scPause,
          help: l.scPauseHelp,
          on: k.paused,
          onChanged: client == null
              ? null
              : (v) async {
                  await client.secretaryPatchContact(widget.id, {'paused': v});
                  await _load();
                },
        ),
        for (final p in _pending) PendingCard(key: Key('sc-pending-${p.id}'), p: p, onDone: _load),
        Container(
          margin: const EdgeInsets.symmetric(vertical: 8),
          padding: const EdgeInsets.all(8),
          constraints: const BoxConstraints(maxHeight: 320),
          decoration: BoxDecoration(
            color: c.bg,
            border: Border.all(color: c.line),
            borderRadius: BorderRadius.circular(12),
          ),
          child: ListView(
            shrinkWrap: true,
            children: [
              for (final m in _messages)
                Align(
                  alignment: m.incoming ? Alignment.centerLeft : Alignment.centerRight,
                  child: Container(
                    margin: const EdgeInsets.symmetric(vertical: 3),
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                    constraints: const BoxConstraints(maxWidth: 420),
                    decoration: BoxDecoration(
                      color: m.incoming ? c.panel : c.accentSoft,
                      border: Border.all(color: m.incoming ? c.line : c.accentDim),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (!m.incoming)
                          Text(
                            m.by == 'agent' ? l.scByAgent : l.scByYou,
                            style: TextStyle(color: c.dim, fontSize: 11),
                          ),
                        Text(m.text, style: TextStyle(color: c.text)),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),
        TextField(
          key: const Key('sc-write'),
          controller: _text,
          minLines: 2,
          maxLines: 5,
          onChanged: (_) => setState(() {}),
          decoration: InputDecoration(labelText: l.scWrite),
        ),
        if (_error != null) KbLine(_error!, error: true),
        TextField(
          key: const Key('sc-notes'),
          controller: _notes,
          minLines: 2,
          maxLines: 4,
          decoration: InputDecoration(labelText: l.scNotes, helperText: l.scNotesHelp),
          onEditingComplete: () => client?.secretaryPatchContact(widget.id, {'notes': _notes.text}),
          onTapOutside: (_) => client?.secretaryPatchContact(widget.id, {'notes': _notes.text}),
        ),
        KbActs(
          children: [
            TextButton(
              key: const Key('sc-delete'),
              onPressed: client == null
                  ? null
                  : () async {
                      final yes = await askConfirm(
                        context,
                        title: l.scDeleteQ,
                        body: '',
                        yes: l.scDelete,
                        danger: true,
                      );
                      if (!yes) return;
                      await client.secretaryDeleteContact(widget.id);
                      widget.onDone();
                    },
              child: Text(l.scDelete, style: TextStyle(color: c.err)),
            ),
            FilledButton(
              key: const Key('sc-send'),
              onPressed: _text.text.trim().isEmpty ? null : _send,
              child: Text(l.scSend),
            ),
          ],
        ),
      ],
    );
  }
}

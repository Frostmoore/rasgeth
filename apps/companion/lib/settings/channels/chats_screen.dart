// G42.13: Settings › Chats, native, as the page's (ChatPlatforms.tsx): Demi-God on Discord, Slack,
// Signal, WhatsApp, Matrix, Microsoft Teams and iMessage, one square per platform lit when it is
// on (with who is linked), each opening a window (a sheet from below on a phone) with what it
// needs and the numbered steps where there are some; once on, the accounts with Unlink, the code to
// send from the chat, Teams' app to download, «Turn off» and «Change». The same conversation
// everywhere: begun on Telegram, it goes on here, and on the web.
import 'dart:async';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

import '../../app_state.dart';
import '../../l10n/app_localizations.dart';
import '../../theme/colors.dart';
import '../../ui/icons.dart';
import '../api/channels_api.dart';
import '../knowledge_kit.dart';
import '../rules_kit.dart';
import 'channels_kit.dart';

Future<void> openChatPlatforms(BuildContext context) =>
    openRulesPage(context, (panel) => ChatPlatformsScreen(panel: panel));

/// One thing a platform needs: its key in the settings, its words, hidden or not, or a switch.
typedef _Field = ({String id, String Function(AppLocalizations) label, bool secret, bool toggle});

_Field _f(
  String id,
  String Function(AppLocalizations) label, {
  bool secret = false,
  bool toggle = false,
}) => (id: id, label: label, secret: secret, toggle: toggle);

final Map<String, List<_Field>> _fields = {
  'discord': [_f('token', (l) => l.chChatDiscordToken, secret: true)],
  'slack': [
    _f('botToken', (l) => l.chChatSlackBot, secret: true),
    _f('appToken', (l) => l.chChatSlackApp, secret: true),
  ],
  'signal': [_f('url', (l) => l.chChatSignalUrl), _f('number', (l) => l.chChatSignalNumber)],
  'whatsapp': [
    _f('token', (l) => l.chChatWaToken, secret: true),
    _f('phoneNumberId', (l) => l.chChatWaPhoneId),
    _f('appSecret', (l) => l.chChatWaSecret, secret: true),
    _f('verifyToken', (l) => l.chChatWaVerify, secret: true),
  ],
  'matrix': [
    _f('homeserver', (l) => l.chChatMatrixHomeserver),
    _f('accessToken', (l) => l.chChatMatrixToken, secret: true),
  ],
  'teams': [
    _f('appId', (l) => l.chChatTeamsAppId),
    _f('tenantId', (l) => l.chChatTeamsTenant),
    _f('appPassword', (l) => l.chChatTeamsSecret, secret: true),
  ],
  'imessage': [
    _f('url', (l) => l.chChatImUrl),
    _f('password', (l) => l.chChatImPassword, secret: true),
    _f('privateApi', (l) => l.chChatImPrivate, toggle: true),
  ],
};

const _names = {
  'discord': 'Discord',
  'slack': 'Slack',
  'signal': 'Signal',
  'whatsapp': 'WhatsApp',
  'matrix': 'Matrix',
  'teams': 'Microsoft Teams',
  'imessage': 'iMessage',
};

const _icons = {
  'discord': RgIcons.chat,
  'slack': RgIcons.users,
  'signal': RgIcons.phone,
  'whatsapp': RgIcons.phone,
  'matrix': RgIcons.chat,
  'teams': RgIcons.board,
  'imessage': RgIcons.phone,
};

String _how(AppLocalizations l, String p) => switch (p) {
  'discord' => l.chChatDiscordHow,
  'slack' => l.chChatSlackHow,
  'signal' => l.chChatSignalHow,
  'whatsapp' => l.chChatWaHow,
  'matrix' => l.chChatMatrixHow,
  'teams' => l.chChatTeamsHow,
  _ => l.chChatImHow,
};

String _text(AppLocalizations l, String p) => switch (p) {
  'discord' => l.chSbChatDiscordText,
  'slack' => l.chSbChatSlackText,
  'signal' => l.chSbChatSignalText,
  'whatsapp' => l.chSbChatWaText,
  'matrix' => l.chSbChatMatrixText,
  'teams' => l.chSbChatTeamsText,
  _ => l.chSbChatImText,
};

/// The numbered steps for the platforms that need more than a token (G36.9).
List<String> _steps(AppLocalizations l, String p, String endpoint) => switch (p) {
  'matrix' => [l.chChatMatrixStep1, l.chChatMatrixStep2, l.chChatMatrixStep3, l.chChatMatrixStep4],
  'teams' => [
    l.chChatTeamsStep1,
    l.chChatTeamsStep2,
    l.chChatTeamsStep3(endpoint),
    l.chChatTeamsStep4,
    l.chChatTeamsStep5,
    l.chChatTeamsStep6,
  ],
  'imessage' => [
    l.chChatImStep1,
    l.chChatImStep2,
    l.chChatImStep3,
    l.chChatImStep4,
    l.chChatImStep5,
  ],
  _ => const [],
};

/// What to know besides, under the steps and once on.
String? _note(AppLocalizations l, String p) => switch (p) {
  'matrix' => l.chChatMatrixE2ee,
  'teams' => l.chChatTeamsFiles,
  'imessage' => l.chChatImLimits,
  _ => null,
};

class ChatPlatformsScreen extends StatefulWidget {
  const ChatPlatformsScreen({super.key, this.panel = false, this.poll = true});

  final bool panel;

  /// Read who is linked again every few seconds while a code waits (tests pump by hand).
  final bool poll;

  @override
  State<ChatPlatformsScreen> createState() => _ChatPlatformsScreenState();
}

class _ChatPlatformsScreenState extends State<ChatPlatformsScreen> {
  List<String>? _on;
  String? _error;
  final Map<String, List<ChatLink>> _links = {};

  @override
  void initState() {
    super.initState();
    unawaited(_load());
  }

  Future<void> _load() async {
    if (!mounted) return;
    final c = AppScope.read(context).client;
    if (c == null) return;
    try {
      final s = await c.setupState();
      final set = s['secretsSet'] is Map ? (s['secretsSet'] as Map)['chats'] : null;
      final on = [for (final p in set is List ? set : const []) '$p'];
      final links = <String, List<ChatLink>>{};
      for (final p in on) {
        links[p] = await c.chatLinks(p).catchError((Object _) => const <ChatLink>[]);
      }
      if (!mounted) return;
      setState(() {
        _on = on;
        _error = null;
        _links
          ..clear()
          ..addAll(links);
      });
    } on Object catch (e) {
      if (mounted) setState(() => _error = rulesWhy(e));
    }
  }

  Future<void> _open(String p) async {
    final l = AppLocalizations.of(context);
    await kbWindow<void>(
      context,
      key: Key('chat-window-$p'),
      title: _names[p]!,
      wide: true,
      body: (ctx, close) => _Panel(
        p: p,
        set: _on?.contains(p) ?? false,
        poll: widget.poll,
        onChange: _load,
        onClose: close,
        l: l,
      ),
    );
    await _load();
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final on = _on;
    return RulesPage(
      pageKey: const Key('chats-page'),
      title: l.chChats,
      question: l.chSbChatsQ,
      lead: l.chChatsHint,
      panel: widget.panel,
      children: [
        if (on == null)
          RulesLoading(error: _error)
        else
          KbTiles(
            children: [
              for (final p in chatPlatforms)
                KbTile(
                  key: Key('chat-tile-$p'),
                  icon: _icons[p]!,
                  title: _names[p]!,
                  text: _text(l, p),
                  on: on.contains(p),
                  state: !on.contains(p)
                      ? null
                      : ((_links[p] ?? const []).isEmpty
                            ? l.chSbChatOnWaiting
                            : l.chChatLinked(_links[p]!.map((x) => x.who).join(', '))),
                  onTap: () => _open(p),
                ),
            ],
          ),
      ],
    );
  }
}

/// The window of one platform: its settings, or (once on) the accounts and the pairing code.
class _Panel extends StatefulWidget {
  const _Panel({
    required this.p,
    required this.set,
    required this.poll,
    required this.onChange,
    required this.onClose,
    required this.l,
  });

  final String p;
  final bool set;
  final bool poll;
  final Future<void> Function() onChange;
  final void Function([void]) onClose;
  final AppLocalizations l;

  @override
  State<_Panel> createState() => _PanelState();
}

class _PanelState extends State<_Panel> {
  late bool _set = widget.set;
  final Map<String, TextEditingController> _values = {};
  final Map<String, bool> _switches = {};
  bool _busy = false;
  String? _error;
  String? _code;
  List<ChatLink> _links = const [];
  bool _changing = false;
  Timer? _timer;

  String get _p => widget.p;

  TextEditingController _field(String id) => _values.putIfAbsent(id, TextEditingController.new);

  @override
  void initState() {
    super.initState();
    if (_set) unawaited(_start());
  }

  @override
  void dispose() {
    _timer?.cancel();
    for (final v in _values.values) {
      v.dispose();
    }
    super.dispose();
  }

  Future<void> _start() async {
    if (!mounted) return;
    final c = AppScope.read(context).client;
    await _loadLinks();
    if (c == null || !mounted) return;
    try {
      final r = await c.chatPair(_p);
      if (!mounted) return;
      setState(() => _code = r.code);
      // While the code waits, the account shows up as soon as it is sent from the chat.
      _timer?.cancel();
      if (widget.poll) {
        _timer = Timer.periodic(const Duration(milliseconds: 2500), (_) {
          if (_links.isEmpty) unawaited(_loadLinks());
        });
      }
    } on Object catch (e) {
      if (mounted) setState(() => _error = rulesWhy(e));
    }
  }

  Future<void> _loadLinks() async {
    if (!mounted) return;
    final c = AppScope.read(context).client;
    if (c == null) return;
    try {
      final l = await c.chatLinks(_p);
      if (mounted) setState(() => _links = l);
    } on Object {
      // Read again in a moment.
    }
  }

  Future<void> _save(Map<String, String>? settings) async {
    if (!mounted) return;
    final c = AppScope.read(context).client;
    if (c == null) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await c.setupChat(_p, settings);
      for (final v in _values.values) {
        v.clear();
      }
      setState(() {
        _changing = false;
        _set = settings != null;
        _code = null;
        _links = const [];
      });
      await widget.onChange();
      if (_set) await _start();
    } on Object catch (e) {
      if (mounted) setState(() => _error = rulesWhy(e));
    }
    if (mounted) setState(() => _busy = false);
  }

  Future<void> _teams() async {
    if (!mounted) return;
    final c = AppScope.read(context).client;
    if (c == null) return;
    try {
      final bytes = await c.teamsApp();
      await FilePicker.saveFile(fileName: 'rasgeth-teams.zip', bytes: bytes);
    } on Object catch (e) {
      if (mounted) setState(() => _error = rulesWhy(e));
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final c = RgColors.of(context);
    final base = AppScope.of(context).client?.base;
    final origin = base == null ? '' : base.origin;
    final endpoint = '$origin/api/chats/teams/messages';
    final note = _note(l, _p);
    if (_set && !_changing) {
      return Column(
        key: const Key('chat-on'),
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            l.chSbChatAccounts,
            style: TextStyle(fontWeight: FontWeight.w800, color: c.text),
          ),
          const SizedBox(height: 6),
          if (_links.isEmpty)
            KbLine(l.chSbChatNoAccount, dim: true)
          else
            for (final a in _links)
              AccountRow(
                key: Key('chat-account-${a.userId}'),
                name: a.who,
                unlinkLabel: l.chUnlink,
                onUnlink: () async {
                  await AppScope.read(context).client?.chatUnlink(_p, a.userId);
                  await _loadLinks();
                },
              ),
          if (_p == 'teams') ...[
            const SizedBox(height: 10),
            KbLine(l.chChatTeamsEndpoint(endpoint), dim: true),
            Align(
              alignment: Alignment.centerLeft,
              child: OutlinedButton.icon(
                key: const Key('chat-teams-download'),
                onPressed: _teams,
                icon: RgIcon(RgIcons.download, size: 16, color: c.text),
                label: Text(l.chChatTeamsDownload),
              ),
            ),
            KbLine(l.chChatTeamsUpload, dim: true),
          ],
          if (_code != null) ...[
            const SizedBox(height: 10),
            KbLine(l.chChatSendCode),
            CodePill('/start $_code', key: const Key('chat-code')),
            if (_links.isEmpty) KbLine(l.chSbChatWaiting, dim: true),
          ],
          if (_p == 'whatsapp')
            KbLine(l.chChatWaWebhook('$origin/api/chats/whatsapp/webhook'), dim: true),
          if (note != null) KbLine(note, dim: true),
          if (_error != null) KbLine(_error!, error: true),
          KbActs(
            children: [
              TextButton(
                key: const Key('chat-off'),
                onPressed: _busy ? null : () => _save(null),
                child: Text(l.chChatTurnOff),
              ),
              OutlinedButton(
                key: const Key('chat-change'),
                onPressed: () => setState(() => _changing = true),
                child: Text(l.chChatChange),
              ),
              FilledButton(
                key: const Key('chat-done'),
                onPressed: widget.onClose,
                child: Text(l.chWzDoneBtn),
              ),
            ],
          ),
        ],
      );
    }
    final fields = _fields[_p]!;
    final complete = fields.every((f) => f.toggle || _field(f.id).text.trim().isNotEmpty);
    final steps = _steps(l, _p, endpoint);
    return Column(
      key: const Key('chat-form'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        KbLine(_how(l, _p)),
        if (steps.isNotEmpty)
          KbBox(
            children: [
              Text(
                l.chChatSteps,
                style: TextStyle(fontWeight: FontWeight.w800, color: c.text),
              ),
              for (final (i, s) in steps.indexed)
                Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(
                        width: 22,
                        child: Text(
                          '${i + 1}.',
                          style: TextStyle(color: c.accent, fontWeight: FontWeight.w800),
                        ),
                      ),
                      Expanded(
                        child: Text(
                          s,
                          style: TextStyle(color: c.text, fontSize: 13.5, height: 1.35),
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        for (final f in fields)
          if (f.toggle)
            KbSwitchRow(
              key: Key('chat-field-${f.id}'),
              title: f.label(l),
              on: _switches[f.id] ?? false,
              onChanged: (v) => setState(() => _switches[f.id] = v),
            )
          else
            Padding(
              padding: const EdgeInsets.only(top: 10),
              child: TextField(
                key: Key('chat-field-${f.id}'),
                controller: _field(f.id),
                obscureText: f.secret,
                autocorrect: false,
                enableSuggestions: false,
                onChanged: (_) => setState(() {}),
                decoration: InputDecoration(labelText: f.label(l)),
              ),
            ),
        if (note != null) KbLine(note, dim: true),
        if (_error != null) KbLine(_error!, error: true),
        KbActs(
          children: [
            TextButton(
              key: const Key('chat-cancel'),
              onPressed: () => _changing ? setState(() => _changing = false) : widget.onClose(),
              child: Text(l.cancel),
            ),
            FilledButton(
              key: const Key('chat-connect'),
              onPressed: _busy || !complete
                  ? null
                  : () => _save({
                      for (final f in fields)
                        f.id: f.toggle
                            ? ((_switches[f.id] ?? false) ? 'on' : 'off')
                            : _field(f.id).text.trim(),
                    }),
              child: Text(_busy ? l.chWzTrying : l.chWzConnect),
            ),
          ],
        ),
      ],
    );
  }
}

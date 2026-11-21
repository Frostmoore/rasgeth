// G42.13: Settings › Telegram, native, as the page's (Telegram.tsx and the wizard's step,
// SetupTelegram.tsx): three steps on a path, each lit when it is its turn and ticked when done —
// make the bot with BotFather, paste its token (the server tries it), open the bot and press Start
// (the link carries the pairing code) — with the chat Telegram will show beside them on a computer
// and inside the step on a phone; then every linked account, each with Unlink, and «Change bot».
import 'dart:async';

import 'package:flutter/material.dart';

import '../../app_state.dart';
import '../../l10n/app_localizations.dart';
import '../../screens/first_start_screen.dart' show openExternal;
import '../../theme/colors.dart';
import '../../ui/icons.dart';
import '../api/channels_api.dart';
import '../knowledge_kit.dart';
import '../rules_kit.dart';
import 'channels_kit.dart';

const _botFather = 'https://t.me/BotFather';

Future<void> openTelegramSettings(BuildContext context, {OpenLink? openUrl}) => openRulesPage(
  context,
  (panel) => TelegramScreen(panel: panel, openUrl: openUrl ?? openExternal),
);

class TelegramScreen extends StatefulWidget {
  const TelegramScreen({
    super.key,
    this.panel = false,
    this.openUrl = openExternal,
    this.poll = true,
  });

  final bool panel;
  final OpenLink openUrl;

  /// Read the accounts again every few seconds (tests switch it off and pump by hand).
  final bool poll;

  @override
  State<TelegramScreen> createState() => _TelegramScreenState();
}

enum _Stage { done, now, later }

class _TelegramScreenState extends State<TelegramScreen> {
  Map<String, dynamic>? _setup;
  String? _loadError;
  List<ChatLink> _links = const [];
  PairCode? _pairing;
  bool _opened = false;
  bool _accepted = false;
  bool _changing = false;
  bool _busy = false;
  String? _error;
  final _token = TextEditingController();
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    unawaited(_load(first: true));
    if (widget.poll) {
      _timer = Timer.periodic(const Duration(milliseconds: 2500), (_) => _loadLinks());
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _token.dispose();
    super.dispose();
  }

  Map<String, dynamic> _part(String k) =>
      _setup?[k] is Map ? (_setup![k] as Map).cast<String, dynamic>() : const {};

  bool get _locked => _part('locked')['telegram'] == true;
  bool get _hasBot =>
      (_accepted || _part('secretsSet')['telegram'] == true || _locked) && !_changing;

  Future<void> _load({bool first = false}) async {
    if (!mounted) return;
    final c = AppScope.read(context).client;
    if (c == null) return;
    try {
      final s = await c.setupState();
      if (!mounted) return;
      setState(() {
        _setup = s;
        _loadError = null;
      });
      await _loadLinks();
      if (first && _hasBot) await _pair();
    } on Object catch (e) {
      if (mounted) setState(() => _loadError = rulesWhy(e));
    }
  }

  Future<void> _loadLinks() async {
    if (!mounted) return;
    final c = AppScope.read(context).client;
    if (c == null) return;
    try {
      final l = await c.telegramLinks();
      if (mounted) setState(() => _links = l);
    } on Object {
      // The accounts are read again in a moment.
    }
  }

  Future<void> _pair() async {
    if (!mounted) return;
    final c = AppScope.read(context).client;
    if (c == null) return;
    try {
      final p = await c.telegramPair();
      if (mounted) setState(() => _pairing = p);
    } on Object catch (e) {
      if (mounted) setState(() => _error = rulesWhy(e));
    }
  }

  Future<void> _check() async {
    if (!mounted) return;
    final c = AppScope.read(context).client;
    if (c == null) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await c.setupTelegram(_token.text.trim());
      _token.clear();
      setState(() {
        _accepted = true;
        _changing = false;
      });
      await _pair();
      await _load();
    } on Object catch (e) {
      if (mounted) setState(() => _error = rulesWhy(e));
    }
    if (mounted) setState(() => _busy = false);
  }

  Future<void> _unlink(ChatLink a) async {
    if (!mounted) return;
    final c = AppScope.read(context).client;
    if (c == null) return;
    try {
      await c.telegramUnlink(a.userId);
      setState(() {
        // Unlinking starts the steps again from what the server says.
        _pairing = null;
        _opened = false;
      });
      await _loadLinks();
      if (_hasBot) await _pair();
    } on Object catch (e) {
      if (mounted) setState(() => _error = rulesWhy(e));
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final c = RgColors.of(context);
    final names = _part('names');
    final demigod = names['demigod'] is String ? names['demigod'] as String : 'Demi-God';
    final god = names['god'] is String ? names['god'] as String : 'God';
    final wide = MediaQuery.sizeOf(context).width >= 760;
    if (_setup == null) {
      return RulesPage(
        pageKey: const Key('telegram-page'),
        title: l.chTelegram,
        question: l.chWzTgQ,
        panel: widget.panel,
        children: [RulesLoading(error: _loadError)],
      );
    }
    final linked = _changing ? null : _links.firstOrNull;
    final hasBot = _hasBot;
    final s1 = _opened || hasBot ? _Stage.done : _Stage.now;
    final s2 = hasBot ? _Stage.done : (_opened ? _Stage.now : _Stage.later);
    final s3 = linked != null ? _Stage.done : (hasBot ? _Stage.now : _Stage.later);
    final bot = _pairing?.bot ?? l.chWzTgExampleBot;
    final botFather = ChatPreview(
      caption: wide ? null : l.chWzTgYouWillSee,
      name: 'BotFather',
      sub: l.chWzTgOfficial,
      messages: [
        (true, '/newbot'),
        (false, l.chWzTgBf1),
        (true, l.chWzTgBfName),
        (false, l.chWzTgBf2),
        (true, l.chWzTgExampleBot),
        if (_opened || wide) (false, l.chWzTgBf3),
      ],
      bottom: wide ? l.chWzTgMessage : null,
    );
    final botChat = ChatPreview(
      caption: wide ? null : l.chWzTgYouWillSee,
      ours: true,
      name: '@$bot',
      sub: 'bot',
      messages: [(false, l.chWzTgPressStart)],
      startBar: l.chWzTgStart,
    );
    final greeting = ChatPreview(
      caption: wide ? null : l.chWzTgYourBot,
      ours: true,
      name: demigod,
      sub: l.chWzTgOnline,
      messages: [(true, '/start'), (false, l.chWzTgHello(demigod, god)), (false, l.chWzTgAsks)],
      bottom: wide ? l.chWzTgMessage : null,
    );
    String word(_Stage s) => switch (s) {
      _Stage.done => l.chWzTgDone,
      _Stage.now => l.chWzTgNow,
      _Stage.later => l.chWzTgLater,
    };
    final steps = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        PathStep(
          key: const Key('tg-step-1'),
          n: 1,
          state: word(s1),
          lit: s1 == _Stage.now,
          done: s1 == _Stage.done,
          title: l.chWzTgStep1,
          text: l.chWzTgStep1Text,
          children: [
            Wrap(
              spacing: 10,
              runSpacing: 8,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                FilledButton.icon(
                  key: const Key('tg-open-botfather'),
                  onPressed: () {
                    setState(() => _opened = true);
                    unawaited(widget.openUrl(Uri.parse(_botFather)));
                  },
                  icon: const RgIcon(RgIcons.send, size: 16, color: Colors.white),
                  label: Text(l.chWzTgOpenBf),
                ),
                TextButton(
                  key: const Key('tg-have-token'),
                  onPressed: () => setState(() => _opened = true),
                  child: Text(l.chWzTgHaveToken),
                ),
              ],
            ),
            if (!wide && !hasBot) botFather,
          ],
        ),
        PathStep(
          key: const Key('tg-step-2'),
          n: 2,
          state: word(s2),
          lit: s2 == _Stage.now,
          done: s2 == _Stage.done,
          title: l.chWzTgStep2,
          text: l.chWzTgStep2Text,
          children: [
            if (!_locked) ...[
              TextField(
                key: const Key('tg-token'),
                controller: _token,
                obscureText: true,
                autocorrect: false,
                enableSuggestions: false,
                onChanged: (_) => setState(() {}),
                onSubmitted: (_) => _token.text.trim().length >= 20 && !_busy ? _check() : null,
                decoration: InputDecoration(labelText: l.chWzTgToken, hintText: '123456789:AAH…'),
              ),
              const SizedBox(height: 8),
              Align(
                alignment: Alignment.centerLeft,
                child: FilledButton.tonal(
                  key: const Key('tg-check'),
                  onPressed: _busy || _token.text.trim().length < 20 ? null : _check,
                  child: Text(_busy ? l.chWzTgChecking : l.chWzTgCheck),
                ),
              ),
            ],
            if (_error != null) KbLine(_error!, error: true),
          ],
        ),
        PathStep(
          key: const Key('tg-step-3'),
          n: 3,
          state: word(s3),
          lit: s3 == _Stage.now,
          done: s3 == _Stage.done,
          title: l.chWzTgStep3,
          text: linked != null
              ? l.chWzTgLinkedShort
              : l.chWzTgStep3Text(_pairing != null ? '@${_pairing!.bot}' : l.chWzTgYourBotName),
          last: true,
          children: [
            if (linked == null && _pairing != null) ...[
              CodePill(_pairing!.code, key: const Key('tg-code')),
              if (!wide) botChat,
              Align(
                alignment: Alignment.centerLeft,
                child: FilledButton.icon(
                  key: const Key('tg-open-bot'),
                  onPressed: () => widget.openUrl(Uri.parse(_pairing!.url!)),
                  icon: const RgIcon(RgIcons.send, size: 16, color: Colors.white),
                  label: Text(l.chTgOpenBot(_pairing!.bot ?? '')),
                ),
              ),
              KbLine(l.chTgWaiting, dim: true),
            ],
          ],
        ),
      ],
    );
    final shown = linked != null ? greeting : (hasBot ? botChat : botFather);
    return RulesPage(
      pageKey: const Key('telegram-page'),
      title: l.chTelegram,
      question: l.chWzTgQ,
      lead: l.chWzTgLead(demigod),
      panel: widget.panel,
      children: [
        if (wide)
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(width: 250, child: PhoneFrame(child: shown)),
              const SizedBox(width: 22),
              Expanded(child: steps),
            ],
          )
        else
          steps,
        if (linked != null) ...[
          KbBox(
            key: const Key('tg-linked'),
            tone: c.ok,
            children: [
              Row(
                children: [
                  RgIcon(RgIcons.send, size: 20, color: c.ok),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      l.chWzTgLinked(
                        demigod,
                        linked.username != null ? '@${linked.username}' : linked.userId,
                      ),
                      style: TextStyle(color: c.text, fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ),
            ],
          ),
          if (!wide) greeting,
          if (!_locked)
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton(
                key: const Key('tg-change'),
                onPressed: () => setState(() {
                  _changing = true;
                  _accepted = false;
                  _pairing = null;
                  _opened = true;
                }),
                child: Text(l.chTgChangeBot),
              ),
            ),
        ],
        if (_locked) KbLine(l.chWzLocked, dim: true),
        if (_links.isNotEmpty) ...[
          RulesSub(title: l.chStTgAccounts, lead: l.chTgLinkedHint),
          KbBox(
            children: [
              for (final a in _links)
                AccountRow(
                  key: Key('tg-account-${a.userId}'),
                  name: a.username != null ? '@${a.username}' : a.userId,
                  help: l.chTgLinked(a.username != null ? '@${a.username}' : a.userId),
                  unlinkLabel: l.chUnlink,
                  onUnlink: () => _unlink(a),
                ),
            ],
          ),
        ],
      ],
    );
  }
}

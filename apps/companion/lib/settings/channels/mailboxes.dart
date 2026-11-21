// G42.13: the mailboxes, native, as the page's (EmailSettings.tsx): on Settings › Automations one
// square per mailbox grouped by category and «Add a mailbox» (with none yet, the single square of
// before, «Mailbox, not connected»); each opens its window: the name, the category (the usual
// ones or the person's own), the server, the user and the password for apps, «Agents can use it»,
// port, encryption and the sending server under «Advanced». A new mailbox is tried before it is
// kept; the password of one already there stays unless a new one is written.
import 'dart:async';

import 'package:flutter/material.dart';

import '../../app_state.dart';
import '../../l10n/app_localizations.dart';
import '../../theme/colors.dart';
import '../../ui/icons.dart';
import '../api/channels_api.dart';
import '../automations/automation_kit.dart' show AutoChips;
import '../knowledge_kit.dart';
import '../rules_kit.dart';

/// A category in words: the usual ones translated, the person's own as written.
String mailCategoryWords(AppLocalizations l, String c) => switch (c) {
  'work' => l.chAxCat_work,
  'personal' => l.chAxCat_personal,
  'social' => l.chAxCat_social,
  'other' => l.chAxCat_other,
  _ => c,
};

/// The mailboxes' squares, for Settings › Automations («Sources»); [onChange] after a window.
class MailboxesSection extends StatefulWidget {
  const MailboxesSection({super.key, this.onChange});

  final VoidCallback? onChange;

  @override
  State<MailboxesSection> createState() => _MailboxesSectionState();
}

class _MailboxesSectionState extends State<MailboxesSection> {
  List<Mailbox>? _boxes;
  List<String> _categories = mailCategories;
  SingleMailbox? _one;

  @override
  void initState() {
    super.initState();
    unawaited(_load());
  }

  Future<void> _load() async {
    if (!mounted) return;
    final c = AppScope.read(context).client;
    if (c == null) return;
    List<Mailbox> boxes = const [];
    var cats = mailCategories;
    try {
      final r = await c.mailboxList();
      boxes = r.boxes;
      cats = r.categories;
    } on Object {
      // None to show.
    }
    SingleMailbox one;
    try {
      one = await c.emailSettings();
    } on Object {
      one = const SingleMailbox(configured: false);
    }
    if (!mounted) return;
    setState(() {
      _boxes = boxes;
      _categories = cats;
      _one = one;
    });
  }

  Future<void> _open(Mailbox? box, {bool single = false}) async {
    final l = AppLocalizations.of(context);
    await kbWindow<void>(
      context,
      key: Key(single ? 'mailbox-window-one' : 'mailbox-window-${box?.id ?? 'new'}'),
      title: single ? l.chEmailTitle : (box?.name ?? l.chAxMailboxNew),
      wide: true,
      body: (ctx, close) => single
          ? SingleMailboxForm(onDone: close)
          : MailboxEditor(box: box, categories: _categories, onDone: close),
    );
    await _load();
    widget.onChange?.call();
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final boxes = _boxes;
    if (boxes == null) return RulesLoading(key: const Key('au-sources'));
    if (boxes.isEmpty) {
      final one = _one;
      return KbTiles(
        key: const Key('au-sources'),
        children: [
          KbTile(
            key: const Key('mailbox-one'),
            icon: RgIcons.mail,
            title: l.chEmailTitle,
            text: l.chEmailTileText,
            on: one?.configured ?? false,
            state: (one?.configured ?? false) ? one!.user : l.chEmailNotConnected,
            onTap: () => _open(null, single: true),
          ),
        ],
      );
    }
    final groups = {for (final b in boxes) b.category}.toList()
      ..sort((a, b) {
        int rank(String x) {
          final i = mailCategories.indexOf(x);
          return i < 0 ? 99 : i;
        }

        final r = rank(a) - rank(b);
        return r != 0 ? r : a.compareTo(b);
      });
    return Column(
      key: const Key('au-sources'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final g in groups) ...[
          Padding(
            padding: const EdgeInsets.fromLTRB(2, 10, 2, 6),
            child: Text(
              mailCategoryWords(l, g),
              style: TextStyle(fontWeight: FontWeight.w800, color: RgColors.of(context).text),
            ),
          ),
          KbTiles(
            children: [
              for (final b in boxes.where((b) => b.category == g))
                KbTile(
                  key: Key('mailbox-${b.id}'),
                  icon: RgIcons.mail,
                  title: b.name,
                  text: b.user,
                  on: true,
                  state: '${mailCategoryWords(l, b.category)} · ${b.host}',
                  onTap: () => _open(b),
                ),
            ],
          ),
        ],
        const SizedBox(height: 10),
        KbTiles(
          children: [
            KbTile(
              key: const Key('mailbox-add'),
              icon: RgIcons.plus,
              title: l.chAxMailboxAdd,
              text: l.chAxMailboxAddText,
              on: false,
              onTap: () => _open(null),
            ),
          ],
        ),
      ],
    );
  }
}

/// A field of the mailbox's window, with its label and help.
class _Field extends StatelessWidget {
  const _Field({
    required this.k,
    required this.label,
    this.help,
    required this.controller,
    this.secret = false,
    this.number = false,
    this.hint,
    this.onChanged,
  });

  final String k;
  final String label;
  final String? help;
  final TextEditingController controller;
  final bool secret;
  final bool number;
  final String? hint;
  final ValueChanged<String>? onChanged;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(top: 10),
    child: TextField(
      key: Key(k),
      controller: controller,
      obscureText: secret,
      autocorrect: false,
      enableSuggestions: !secret,
      keyboardType: number ? TextInputType.number : null,
      onChanged: onChanged,
      decoration: InputDecoration(
        labelText: label,
        helperText: help,
        hintText: hint,
        helperMaxLines: 3,
      ),
    ),
  );
}

/// One mailbox's window (G33.3): a new one, or one already there.
class MailboxEditor extends StatefulWidget {
  const MailboxEditor({
    super.key,
    required this.box,
    required this.categories,
    required this.onDone,
  });

  final Mailbox? box;
  final List<String> categories;
  final void Function([void]) onDone;

  @override
  State<MailboxEditor> createState() => _MailboxEditorState();
}

class _MailboxEditorState extends State<MailboxEditor> {
  late final _name = TextEditingController(text: widget.box?.name ?? '');
  late String _category = widget.box?.category ?? 'personal';
  final _custom = TextEditingController();
  late final _host = TextEditingController(text: widget.box?.host ?? '');
  late final _port = TextEditingController(text: '${widget.box?.port ?? 993}');
  late bool _secure = widget.box?.secure ?? true;
  late final _user = TextEditingController(text: widget.box?.user ?? '');
  final _password = TextEditingController();
  late final _smtpHost = TextEditingController(text: widget.box?.smtpHost ?? '');
  late final _smtpPort = TextEditingController(text: '${widget.box?.smtpPort ?? 465}');
  late bool _agents = widget.box?.agents ?? false;
  bool _advanced = false;
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    for (final c in [_name, _custom, _host, _port, _user, _password, _smtpHost, _smtpPort]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _save() async {
    if (!mounted) return;
    final c = AppScope.read(context).client;
    if (c == null) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    final port = int.tryParse(_port.text.trim()) ?? 993;
    final smtpPort = int.tryParse(_smtpPort.text.trim()) ?? 465;
    final smtp = _smtpHost.text.trim().isEmpty
        ? null
        : {'host': _smtpHost.text.trim(), 'port': smtpPort, 'secure': smtpPort == 465};
    final cat = _custom.text.trim().isNotEmpty ? _custom.text.trim() : _category;
    final body = <String, Object?>{
      'name': _name.text.trim(),
      'category': cat,
      'host': _host.text.trim(),
      'port': port,
      'secure': _secure,
      'user': _user.text.trim(),
      'agents': _agents,
    };
    try {
      final box = widget.box;
      if (box != null) {
        await c.updateMailbox(box.id, {
          ...body,
          if (_password.text.isNotEmpty) 'password': _password.text,
          'smtp': smtp,
        });
      } else {
        await c.addMailbox({...body, 'password': _password.text, 'smtp': ?smtp});
      }
      _password.clear();
      widget.onDone();
    } on Object catch (e) {
      if (mounted) setState(() => _error = rulesWhy(e));
    }
    if (mounted) setState(() => _busy = false);
  }

  Future<void> _remove() async {
    if (!mounted) return;
    final c = AppScope.read(context).client;
    final box = widget.box;
    if (c == null || box == null) return;
    try {
      await c.removeMailbox(box.id);
      widget.onDone();
    } on Object catch (e) {
      if (mounted) setState(() => _error = rulesWhy(e));
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final c = RgColors.of(context);
    final box = widget.box;
    final cats = {...mailCategories, ...widget.categories, _category}.toList();
    final ready =
        _host.text.trim().isNotEmpty &&
        _user.text.trim().isNotEmpty &&
        (box != null || _password.text.isNotEmpty);
    void again(String _) => setState(() {});
    return Column(
      key: const Key('mailbox-editor'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        KbLine(l.chAxMailboxPurpose),
        _Field(
          k: 'mb-name',
          label: l.chAxMailboxName,
          help: l.chAxMailboxNameHelp,
          controller: _name,
        ),
        Padding(
          padding: const EdgeInsets.only(top: 14, bottom: 6),
          child: Text(
            l.chAxMailboxCategory,
            style: TextStyle(fontWeight: FontWeight.w700, color: c.text),
          ),
        ),
        AutoChips<String>(
          options: [for (final x in cats) (x, mailCategoryWords(l, x))],
          value: _custom.text.trim().isNotEmpty ? const [] : [_category],
          keyOf: (x) => 'mb-cat-$x',
          onChanged: (v) => setState(() {
            if (v.isNotEmpty) _category = v.first;
            _custom.clear();
          }),
        ),
        _Field(
          k: 'mb-custom',
          label: l.chAxMailboxNewCategory,
          hint: l.chAxMailboxNewCategoryPlaceholder,
          controller: _custom,
          onChanged: again,
        ),
        _Field(
          k: 'mb-host',
          label: l.chEmailHost,
          help: l.chEmailHostHelp,
          hint: 'imap.gmail.com',
          controller: _host,
          onChanged: again,
        ),
        _Field(k: 'mb-user', label: l.chEmailUser, controller: _user, onChanged: again),
        _Field(
          k: 'mb-password',
          label: l.chEmailPassword,
          help: box != null ? l.chAxMailboxPasswordKept : l.chEmailPasswordHelp,
          controller: _password,
          secret: true,
          onChanged: again,
        ),
        const SizedBox(height: 8),
        KbSwitchRow(
          key: const Key('mb-agents'),
          title: l.chAxMailboxAgents,
          help: l.chAxMailboxAgentsHelp,
          on: _agents,
          onChanged: (v) => setState(() => _agents = v),
        ),
        _Advanced(
          open: _advanced,
          onToggle: () => setState(() => _advanced = !_advanced),
          children: [
            _Field(k: 'mb-port', label: l.chEmailPort, controller: _port, number: true),
            KbSwitchRow(
              key: const Key('mb-secure'),
              title: l.chEmailSecure,
              on: _secure,
              onChanged: (v) => setState(() => _secure = v),
            ),
            _Field(
              k: 'mb-smtp-host',
              label: l.chAxSmtpHost,
              help: l.chAxSmtpHostHelp,
              hint: _host.text.trim().isEmpty
                  ? 'smtp.gmail.com'
                  : _host.text.trim().replaceFirst(
                      RegExp(r'^imap\.', caseSensitive: false),
                      'smtp.',
                    ),
              controller: _smtpHost,
            ),
            _Field(k: 'mb-smtp-port', label: l.chAxSmtpPort, controller: _smtpPort, number: true),
          ],
        ),
        if (_error != null) KbLine(_error!, error: true),
        KbActs(
          children: [
            if (box != null)
              TextButton(
                key: const Key('mb-remove'),
                onPressed: _busy ? null : _remove,
                child: Text(l.chRemove, style: TextStyle(color: c.err)),
              ),
            FilledButton(
              key: const Key('mb-save'),
              onPressed: _busy || !ready ? null : _save,
              child: Text(_busy ? l.chEmailTesting : (box != null ? l.save : l.chEmailSave)),
            ),
          ],
        ),
      ],
    );
  }
}

/// The single mailbox of before (with no mailboxes yet): server, user, password, tried on save.
class SingleMailboxForm extends StatefulWidget {
  const SingleMailboxForm({super.key, required this.onDone});

  final void Function([void]) onDone;

  @override
  State<SingleMailboxForm> createState() => _SingleMailboxFormState();
}

class _SingleMailboxFormState extends State<SingleMailboxForm> {
  SingleMailbox? _shown;
  final _host = TextEditingController();
  final _port = TextEditingController(text: '993');
  bool _secure = true;
  final _user = TextEditingController();
  final _password = TextEditingController();
  bool _advanced = false;
  bool _busy = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    unawaited(_load());
  }

  @override
  void dispose() {
    for (final c in [_host, _port, _user, _password]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _load() async {
    if (!mounted) return;
    final c = AppScope.read(context).client;
    if (c == null) return;
    SingleMailbox s;
    try {
      s = await c.emailSettings();
    } on Object {
      s = const SingleMailbox(configured: false);
    }
    if (!mounted) return;
    setState(() {
      _shown = s;
      if (s.configured) {
        _host.text = s.host ?? '';
        _port.text = '${s.port ?? 993}';
        _secure = s.secure ?? true;
        _user.text = s.user ?? '';
      }
    });
  }

  Future<void> _save() async {
    if (!mounted) return;
    final c = AppScope.read(context).client;
    if (c == null) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await c.setEmailSettings(
        host: _host.text.trim(),
        port: int.tryParse(_port.text.trim()) ?? 993,
        secure: _secure,
        user: _user.text.trim(),
        password: _password.text,
      );
      _password.clear();
      await _load();
    } on Object catch (e) {
      if (mounted) setState(() => _error = rulesWhy(e));
    }
    if (mounted) setState(() => _busy = false);
  }

  Future<void> _remove() async {
    if (!mounted) return;
    final c = AppScope.read(context).client;
    if (c == null) return;
    try {
      await c.removeEmailSettings();
      await _load();
    } on Object catch (e) {
      if (mounted) setState(() => _error = rulesWhy(e));
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final c = RgColors.of(context);
    final s = _shown;
    if (s == null) return const RulesLoading();
    void again(String _) => setState(() {});
    final ready =
        _host.text.trim().isNotEmpty && _user.text.trim().isNotEmpty && _password.text.isNotEmpty;
    return Column(
      key: const Key('mailbox-one-form'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        KbLine(l.chEmailPurpose),
        if (s.configured) KbLine(l.chEmailConnected(s.host ?? '', s.user ?? '')),
        _Field(
          k: 'em-host',
          label: l.chEmailHost,
          help: l.chEmailHostHelp,
          hint: 'imap.gmail.com',
          controller: _host,
          onChanged: again,
        ),
        _Field(k: 'em-user', label: l.chEmailUser, controller: _user, onChanged: again),
        _Field(
          k: 'em-password',
          label: l.chEmailPassword,
          help: l.chEmailPasswordHelp,
          controller: _password,
          secret: true,
          onChanged: again,
        ),
        _Advanced(
          open: _advanced,
          onToggle: () => setState(() => _advanced = !_advanced),
          children: [
            _Field(k: 'em-port', label: l.chEmailPort, controller: _port, number: true),
            KbSwitchRow(
              title: l.chEmailSecure,
              on: _secure,
              onChanged: (v) => setState(() => _secure = v),
            ),
          ],
        ),
        if (_error != null) KbLine(_error!, error: true),
        KbActs(
          children: [
            if (s.configured)
              TextButton(
                key: const Key('em-remove'),
                onPressed: _remove,
                child: Text(l.chRemove, style: TextStyle(color: c.err)),
              ),
            FilledButton(
              key: const Key('em-save'),
              onPressed: _busy || !ready ? null : _save,
              child: Text(_busy ? l.chEmailTesting : l.chEmailSave),
            ),
          ],
        ),
      ],
    );
  }
}

/// «Advanced», closed at first (the page's `Advanced`): a drawn row that opens what is under it.
class _Advanced extends StatelessWidget {
  const _Advanced({required this.open, required this.onToggle, required this.children});

  final bool open;
  final VoidCallback onToggle;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final c = RgColors.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: 6),
        InkWell(
          key: const Key('mb-advanced'),
          borderRadius: BorderRadius.circular(8),
          onTap: onToggle,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Row(
              children: [
                RgIcon(open ? RgIcons.chevronDown : RgIcons.chevronRight, size: 16, color: c.dim),
                const SizedBox(width: 6),
                Text(
                  l.chUiAdvanced,
                  style: TextStyle(color: c.dim, fontWeight: FontWeight.w700),
                ),
              ],
            ),
          ),
        ),
        if (open) ...children,
      ],
    );
  }
}

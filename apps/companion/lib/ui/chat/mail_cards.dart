// Email for the agents in the conversation (G42.1), as the page's MailCards.tsx: a search shows
// its senders and subjects, a message read shows its headers, attachments and the start of its
// text, a draft or a send says to whom and about what. The request to send shows the email field
// by field, its text whole. Everything an email says is plain text (never Markdown or HTML).
// Sizes and colours follow the page's `.mail-card`, `.mail-list`, `.mail-request` (styles.css).
import 'package:flutter/material.dart';

import '../../api/mail.dart';
import '../../l10n/app_localizations.dart';
import '../../theme/colors.dart';
import '../icons.dart';

/// Messages shown before «N more».
const int kMailShown = 8;

/// Characters of a message's text shown before «Show all».
const int kMailPreview = 600;

const _tabular = [FontFeature.tabularFigures()];

/// «it» or «en», as the protocol's and the page's functions take it.
String _lang(AppLocalizations l) => l.localeName.split('_').first;

/// What a mail tool did, under its line: the list, the message, the draft or the email sent;
/// nothing for the others (or for an answer that is not one of these).
class MailToolCard extends StatelessWidget {
  const MailToolCard({super.key, required this.tool, required this.output});

  final String tool;
  final String output;

  @override
  Widget build(BuildContext context) {
    switch (tool) {
      case 'mail_search':
        return _SearchCard(list: parseMailList(output));
      case 'mail_read':
        final m = parseMailMessage(output);
        return m == null ? const SizedBox.shrink() : _ReadCard(m: m);
      case 'mail_draft':
        final d = parseMailDraft(output);
        return d == null ? const SizedBox.shrink() : _DraftCard(d: d);
      case 'mail_send':
        final s = parseMailSent(output);
        return s == null ? const SizedBox.shrink() : _SentCard(s: s);
    }
    return const SizedBox.shrink();
  }
}

/// `.mail-card`: the frame every mail card shares.
class _Frame extends StatelessWidget {
  const _Frame({required this.kind, required this.child});

  final String kind;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final c = RgColors.of(context);
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        key: Key('mail-$kind'),
        margin: const EdgeInsets.only(top: 4),
        constraints: const BoxConstraints(maxWidth: 640),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: c.panel,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: c.line),
        ),
        child: DefaultTextStyle.merge(
          style: TextStyle(color: c.text, fontSize: 13, height: 1.35),
          child: child,
        ),
      ),
    );
  }
}

/// `.mail-card-where`: an icon and a dim line.
class _Where extends StatelessWidget {
  const _Where({required this.icon, required this.text});

  final RgIcons icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    final c = RgColors.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          RgIcon(icon, size: 13, color: c.dim),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              text,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(color: c.dim, fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }
}

/// `button.link`: «N more», «Show all».
class _Link extends StatelessWidget {
  const _Link({super.key, required this.text, required this.onTap});

  final String text;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = RgColors.of(context);
    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Semantics(
        button: true,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(4),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 2),
            child: Text(text, style: TextStyle(color: c.accent, fontSize: 13)),
          ),
        ),
      ),
    );
  }
}

class _SearchCard extends StatefulWidget {
  const _SearchCard({required this.list});

  final MailList list;

  @override
  State<_SearchCard> createState() => _SearchCardState();
}

class _SearchCardState extends State<_SearchCard> {
  bool _all = false;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final c = RgColors.of(context);
    final r = widget.list;
    final shown = _all ? r.mails : r.mails.take(kMailShown).toList();
    return _Frame(
      kind: 'search',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          if (r.mailbox != null)
            _Where(icon: RgIcons.mail, text: l.mailCardFolder(r.mailbox!, r.folder ?? '')),
          if (r.mails.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 2),
              child: Text(l.mailCardNone, style: TextStyle(color: c.dim)),
            )
          else
            LayoutBuilder(
              builder: (context, box) {
                // `minmax(80px, 160px)` for the sender.
                final fromWidth = (box.maxWidth * 0.3).clamp(80.0, 160.0);
                return Column(
                  children: [
                    for (var i = 0; i < shown.length; i++)
                      _Row(m: shown[i], first: i == 0, fromWidth: fromWidth),
                  ],
                );
              },
            ),
          if (r.mails.length > kMailShown)
            _Link(
              key: const Key('mail-more'),
              text: _all ? l.mailCardShowLess : l.mailCardMore(r.mails.length - kMailShown),
              onTap: () => setState(() => _all = !_all),
            ),
        ],
      ),
    );
  }
}

class _Row extends StatelessWidget {
  const _Row({required this.m, required this.first, required this.fromWidth});

  final MailSummary m;
  final bool first;
  final double fromWidth;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final c = RgColors.of(context);
    final weight = m.unread ? FontWeight.w600 : FontWeight.w400;
    final dot = Container(
      width: 7,
      height: 7,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: m.unread ? c.accent : Colors.transparent,
      ),
    );
    return Container(
      key: Key('mail-row-${m.id}'),
      padding: const EdgeInsets.symmetric(vertical: 3),
      decoration: BoxDecoration(
        border: first ? null : Border(top: BorderSide(color: c.line)),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 10,
            child: m.unread ? Tooltip(message: l.mailCardUnread, child: dot) : dot,
          ),
          const SizedBox(width: 8),
          SizedBox(
            width: fromWidth,
            child: Text(
              mailWho(m.from),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(fontWeight: weight),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              m.subject.isEmpty ? '—' : m.subject,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(fontWeight: weight),
            ),
          ),
          if (m.attachments > 0) ...[
            const SizedBox(width: 8),
            Tooltip(
              message: m.attachments == 1
                  ? l.mailCardAttachment
                  : l.mailCardAttachments(m.attachments),
              child: RgIcon(RgIcons.paperclip, size: 12, color: c.dim),
            ),
          ],
          const SizedBox(width: 8),
          Text(
            mailDate(m.date, _lang(l)),
            style: TextStyle(color: c.dim, fontSize: 12, fontFeatures: _tabular),
          ),
        ],
      ),
    );
  }
}

/// `.chip` (11 px inside `.mail-files`).
class _Chip extends StatelessWidget {
  const _Chip(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    final c = RgColors.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 1),
      decoration: BoxDecoration(
        color: c.panel,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: c.line),
      ),
      child: Text(text, style: TextStyle(color: c.dim, fontSize: 11)),
    );
  }
}

/// `.attachment`: a file with its clip, name and size.
class _File extends StatelessWidget {
  const _File({required this.name, this.size, this.tip, this.saved = false});

  final String name;
  final String? size;
  final String? tip;
  final bool saved;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final c = RgColors.of(context);
    final box = Container(
      constraints: const BoxConstraints(maxWidth: 220),
      padding: const EdgeInsets.fromLTRB(10, 4, 6, 4),
      decoration: BoxDecoration(
        color: c.panel2,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: c.line),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          RgIcon(RgIcons.paperclip, size: 12, color: c.text),
          const SizedBox(width: 6),
          Flexible(child: Text(name, maxLines: 1, overflow: TextOverflow.ellipsis)),
          if (size != null) ...[
            const SizedBox(width: 6),
            Text(size!, maxLines: 1, style: TextStyle(color: c.dim)),
          ],
          if (saved) ...[const SizedBox(width: 6), _Chip(l.mailCardSaved)],
        ],
      ),
    );
    return tip == null || tip!.isEmpty ? box : Tooltip(message: tip, child: box);
  }
}

class _Files extends StatelessWidget {
  const _Files(this.children);

  final List<Widget> children;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 6),
    child: Wrap(spacing: 6, runSpacing: 6, children: children),
  );
}

/// `.mail-body`: the text, plain, under a line.
class _Body extends StatelessWidget {
  const _Body({super.key, required this.text, this.maxHeight, this.scroll = false});

  final String text;
  final double? maxHeight;
  final bool scroll;

  @override
  Widget build(BuildContext context) {
    final c = RgColors.of(context);
    Widget body = Text(text, style: const TextStyle(height: 1.45));
    if (maxHeight != null) {
      body = ConstrainedBox(
        constraints: BoxConstraints(maxHeight: maxHeight!),
        child: scroll
            ? SingleChildScrollView(child: body)
            : ClipRect(
                child: SingleChildScrollView(
                  physics: const NeverScrollableScrollPhysics(),
                  child: body,
                ),
              ),
      );
    }
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(top: 6),
      padding: const EdgeInsets.only(top: 6),
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: c.line)),
      ),
      child: body,
    );
  }
}

class _ReadCard extends StatefulWidget {
  const _ReadCard({required this.m});

  final MailMessageView m;

  @override
  State<_ReadCard> createState() => _ReadCardState();
}

class _ReadCardState extends State<_ReadCard> {
  bool _all = false;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final c = RgColors.of(context);
    final m = widget.m;
    final long = m.body.length > kMailPreview;
    return _Frame(
      kind: 'read',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            m.subject.isEmpty ? '—' : m.subject,
            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
          ),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: Text(m.from)),
              const SizedBox(width: 10),
              Text(
                mailDate(m.date, _lang(l)),
                style: TextStyle(color: c.dim, fontSize: 12, fontFeatures: _tabular),
              ),
            ],
          ),
          Text(
            '${l.mailCardTo}: ${m.to}${m.cc != null && m.cc!.isNotEmpty ? ' · Cc: ${m.cc}' : ''}',
            style: TextStyle(color: c.dim),
          ),
          if (m.attachments.isNotEmpty)
            _Files([
              for (final a in m.attachments)
                _File(
                  name: a.name,
                  size: mailSize(a.size, _lang(l)),
                  tip: a.saved ?? a.type,
                  saved: a.saved != null,
                ),
            ]),
          _Body(
            key: const Key('mail-body'),
            text: _all || !long ? m.body : '${m.body.substring(0, kMailPreview)}…',
            maxHeight: _all ? null : 180,
          ),
          if (long)
            _Link(
              key: const Key('mail-show-all'),
              text: _all ? l.mailCardShowLess : l.mailCardShowAll,
              onTap: () => setState(() => _all = !_all),
            ),
        ],
      ),
    );
  }
}

/// A label and its value, as `.mail-request-row` (90 px for the label).
class _Field extends StatelessWidget {
  const _Field({super.key, required this.label, required this.value, this.strong = false});

  final String label;
  final String value;
  final bool strong;

  @override
  Widget build(BuildContext context) {
    final c = RgColors.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 90,
            child: Text(label, style: TextStyle(color: c.dim)),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              value,
              style: TextStyle(fontWeight: strong ? FontWeight.w600 : FontWeight.w400),
            ),
          ),
        ],
      ),
    );
  }
}

class _DraftCard extends StatelessWidget {
  const _DraftCard({required this.d});

  final MailDraftDone d;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final title = d.changed ? l.mailCardDraftChanged : l.mailCardDraftSaved;
    return _Frame(
      kind: 'draft',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          _Where(icon: RgIcons.edit, text: d.id == null ? title : '$title · #${d.id}'),
          _Field(
            label: l.mailCardTo,
            value: d.to.isEmpty ? l.mailCardNobody : d.to.join(', '),
            strong: true,
          ),
          if (d.cc.isNotEmpty) _Field(label: 'Cc', value: d.cc.join(', '), strong: true),
          if (d.bcc.isNotEmpty)
            _Field(label: _lang(l) == 'it' ? 'Ccn' : 'Bcc', value: d.bcc.join(', '), strong: true),
          _Field(label: l.mailCardSubject, value: d.subject.isEmpty ? '—' : d.subject),
          if (d.attachments.isNotEmpty) _Files([for (final a in d.attachments) _File(name: a)]),
        ],
      ),
    );
  }
}

class _SentCard extends StatelessWidget {
  const _SentCard({required this.s});

  final MailSentDone s;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return _Frame(
      kind: 'sent',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          _Where(icon: RgIcons.send, text: l.mailCardSentFrom(s.mailbox)),
          _Field(label: l.mailCardTo, value: s.to.join(', '), strong: true),
          _Field(label: l.mailCardSubject, value: s.subject.isEmpty ? '—' : s.subject),
        ],
      ),
    );
  }
}

/// The email of a request to send, field by field, its text whole (the page's
/// `MailRequestPreview`); nothing when the request carries no prepared message.
class MailRequestPreview extends StatelessWidget {
  const MailRequestPreview({super.key, required this.input});

  final Object? input;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final c = RgColors.of(context);
    final fields = mailRequestFields(_lang(l), input);
    if (fields.isEmpty) return const SizedBox.shrink();
    final text = fields.where((f) => f.key == 'text').firstOrNull;
    return Container(
      key: const Key('mail-request'),
      width: double.infinity,
      margin: const EdgeInsets.symmetric(vertical: 6),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: c.panel,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: c.line),
      ),
      child: DefaultTextStyle.merge(
        style: TextStyle(color: c.text, fontSize: 13, height: 1.35),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Row(
                children: [
                  RgIcon(RgIcons.mail, size: 14, color: c.text),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      l.mailCardPermTitle,
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ),
            ),
            for (final f in fields)
              if (f.key != 'text')
                _Field(
                  key: Key('mail-request-${f.key}'),
                  label: f.label,
                  value: f.value,
                  strong: f.key == 'to' || f.key == 'cc' || f.key == 'bcc',
                ),
            if (text != null)
              _Body(
                key: const Key('mail-request-body'),
                text: text.value,
                maxHeight: 320,
                scroll: true,
              ),
          ],
        ),
      ),
    );
  }
}

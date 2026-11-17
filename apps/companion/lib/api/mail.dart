// Email for the agents (G42.1), a port of packages/protocol/src/mail.ts (`parseMailList`,
// `parseMailMessage`, `preparedMailOf`, `mailRequestFields`, `mailSize`) and of the page's
// `mailSummary` and `mailDate` (packages/web/src/components/MailCards.tsx). Everything an email
// says is data: the app shows it as plain text, never as Markdown or HTML.
// test/g42_1_mail_test.dart checks the port against vectors made by the protocol's and the page's
// own code (tool/mail_vectors.mjs).
import 'dart:convert';

import '../l10n/app_localizations.dart';

/// The JavaScript string of a JSON value inside a template (`${x}`): 3, not 3.0.
String _js(Object? v) => switch (v) {
  null => 'null',
  final double d when d.isFinite && d == d.truncateToDouble() => d.toInt().toString(),
  _ => '$v',
};

/// What JavaScript's `typeof v === "object"` and truthy says: a map or a list.
bool _isObject(Object? v) => v is Map || v is List;

Object? _field(Object? o, String k) => o is Map ? o[k] : null;

String? _str(Object? v) => v is String ? v : null;

/// One message in a list (mail_search).
class MailSummary {
  const MailSummary({
    required this.id,
    required this.date,
    required this.from,
    this.to,
    required this.subject,
    required this.unread,
    this.flagged,
    required this.attachments,
    this.snippet,
  });

  factory MailSummary.fromJson(Map<String, dynamic> j) => MailSummary(
    id: (j['id'] as num).toInt(),
    date: _str(j['date']) ?? '',
    from: _str(j['from']) ?? '',
    to: _str(j['to']),
    subject: _str(j['subject']) ?? '',
    unread: j['unread'] == true,
    flagged: j['flagged'] is bool ? j['flagged'] as bool : null,
    attachments: j['attachments'] is num ? (j['attachments'] as num).toInt() : 0,
    snippet: _str(j['snippet']),
  );

  final int id;
  final String date;
  final String from;
  final String? to;
  final String subject;
  final bool unread;
  final bool? flagged;
  final int attachments;
  final String? snippet;

  Map<String, Object?> toJson() => {
    'id': id,
    'date': date,
    'from': from,
    if (to != null) 'to': to,
    'subject': subject,
    'unread': unread,
    if (flagged != null) 'flagged': flagged,
    'attachments': attachments,
    if (snippet != null) 'snippet': snippet,
  };
}

/// The messages of a mail_search answer (for the card); empty when it is not one.
class MailList {
  const MailList({this.mailbox, this.folder, required this.mails});

  final String? mailbox;
  final String? folder;
  final List<MailSummary> mails;

  Map<String, Object?> toJson() => {
    if (mailbox != null) 'mailbox': mailbox,
    if (folder != null) 'folder': folder,
    'mails': [for (final m in mails) m.toJson()],
  };
}

final _listHead = RegExp(r'^Mailbox "(.*?)" \(.*?\), folder (.+?): ');
final _listBlock = RegExp(r'\n<emails>\n([\s\S]*?)\n<\/emails>');

/// The messages of a mail_search answer; no mails when it is not one.
MailList parseMailList(String text) {
  final head = _listHead.firstMatch(text);
  final block = _listBlock.firstMatch(text);
  final mails = <MailSummary>[];
  for (final l in block?[1]?.split('\n') ?? const <String>[]) {
    try {
      final m = jsonDecode(l);
      if (m is Map<String, dynamic> && m['id'] is num) mails.add(MailSummary.fromJson(m));
    } on FormatException {
      // Not ours: skipped.
    }
  }
  return MailList(mailbox: head?[1], folder: head?[2], mails: mails);
}

/// An attachment of a message read: its name, type and size, and where it was saved.
class MailAttachmentInfo {
  const MailAttachmentInfo({
    required this.name,
    required this.type,
    required this.size,
    this.saved,
  });

  factory MailAttachmentInfo.fromJson(Object? j) => MailAttachmentInfo(
    name: _str(_field(j, 'name')) ?? '',
    type: _str(_field(j, 'type')) ?? '',
    size: _field(j, 'size') is num ? (_field(j, 'size') as num).toInt() : 0,
    saved: _str(_field(j, 'saved')),
  );

  final String name;
  final String type;
  final int size;

  /// The workspace path it was saved to (mail_read with save_attachments).
  final String? saved;

  Map<String, Object?> toJson() => {
    'name': name,
    'type': type,
    'size': size,
    if (saved != null) 'saved': saved,
  };
}

/// One message read (mail_read).
class MailMessageView {
  const MailMessageView({
    required this.id,
    required this.folder,
    required this.mailbox,
    required this.from,
    required this.to,
    this.cc,
    required this.date,
    required this.subject,
    this.messageId,
    required this.attachments,
    required this.body,
  });

  final int id;
  final String folder;
  final String mailbox;
  final String from;
  final String to;
  final String? cc;
  final String date;
  final String subject;
  final String? messageId;
  final List<MailAttachmentInfo> attachments;
  final String body;

  Map<String, Object?> toJson() => {
    'id': id,
    'folder': folder,
    'mailbox': mailbox,
    'from': from,
    'to': to,
    if (cc != null) 'cc': cc,
    'date': date,
    'subject': subject,
    if (messageId != null) 'messageId': messageId,
    'attachments': [for (final a in attachments) a.toJson()],
    'body': body,
  };
}

final _message = RegExp(r'\n<email>\n(.*)\n<body>\n([\s\S]*)\n<\/body>\n<\/email>\s*$');

/// The message of a mail_read answer (for the card), or null.
MailMessageView? parseMailMessage(String text) {
  final m = _message.firstMatch(text);
  if (m == null) return null;
  final Object? h;
  try {
    h = jsonDecode(m[1] ?? '');
  } on FormatException {
    return null;
  }
  if (h is! Map<String, dynamic> || h['id'] is! num) return null;
  final files = h['attachments'];
  return MailMessageView(
    id: (h['id'] as num).toInt(),
    folder: _str(h['folder']) ?? '',
    mailbox: _str(h['mailbox']) ?? '',
    from: _str(h['from']) ?? '',
    to: _str(h['to']) ?? '',
    cc: _str(h['cc']),
    date: _str(h['date']) ?? '',
    subject: _str(h['subject']) ?? '',
    messageId: _str(h['messageId']),
    attachments: files is List ? [for (final a in files) MailAttachmentInfo.fromJson(a)] : const [],
    body: m[2] ?? '',
  );
}

/// One file of a message about to leave.
class PreparedAttachment {
  const PreparedAttachment({required this.name, required this.size, this.type});

  final String name;
  final num size;
  final String? type;

  Map<String, Object?> toJson() => {'name': name, 'size': size, if (type != null) 'type': type};
}

/// A message ready to leave (mail_send, after the server prepared it from the draft or the
/// fields): what the person approves and what is sent, the same thing.
class PreparedMail {
  const PreparedMail({
    required this.mailbox,
    required this.from,
    required this.to,
    required this.cc,
    required this.bcc,
    required this.subject,
    required this.body,
    required this.attachments,
    this.inReplyTo,
    this.draft,
  });

  /// The mailbox's name, and the address it is sent from.
  final String mailbox;
  final String from;
  final List<String> to;
  final List<String> cc;
  final List<String> bcc;
  final String subject;
  final String body;
  final List<PreparedAttachment> attachments;
  final String? inReplyTo;

  /// The draft it comes from (deleted once sent).
  final num? draft;

  Map<String, Object?> toJson() => {
    'mailbox': mailbox,
    'from': from,
    'to': to,
    'cc': cc,
    'bcc': bcc,
    'subject': subject,
    'body': body,
    'attachments': [for (final a in attachments) a.toJson()],
    if (inReplyTo != null) 'inReplyTo': inReplyTo,
    if (draft != null) 'draft': draft,
  };
}

List<String> _strings(Object? v) => v is List
    ? [
        for (final x in v)
          if (x is String) x,
      ]
    : const [];

/// The prepared message of a mail_send request, if the server put one there.
PreparedMail? preparedMailOf(Object? input) {
  final m = _isObject(input) ? _field(input, 'message') : null;
  if (!_isObject(m)) return null;
  final files = _field(m, 'attachments');
  return PreparedMail(
    mailbox: _str(_field(m, 'mailbox')) ?? '',
    from: _str(_field(m, 'from')) ?? '',
    to: _strings(_field(m, 'to')),
    cc: _strings(_field(m, 'cc')),
    bcc: _strings(_field(m, 'bcc')),
    subject: _str(_field(m, 'subject')) ?? '',
    body: _str(_field(m, 'body')) ?? '',
    attachments: files is List
        ? [
            for (final a in files)
              if (a is Map && a['name'] is String)
                PreparedAttachment(
                  name: a['name'] as String,
                  size: a['size'] is num ? a['size'] as num : 0,
                  type: _str(a['type']),
                ),
          ]
        : const [],
    inReplyTo: _str(_field(m, 'inReplyTo')),
    draft: _field(m, 'draft') is num ? _field(m, 'draft') as num : null,
  );
}

/// A size as people read it.
String mailSize(num bytes, String lang) {
  final it = lang == 'it';
  if (bytes < 1024) return '${_js(bytes)} B';
  if (bytes < 1024 * 1024) return '${(bytes / 1024).round()} KB';
  final mb = (bytes / 1048576).toStringAsFixed(1);
  return '${it ? mb.replaceFirst('.', ',') : mb} MB';
}

/// One field of an email about to leave, in the person's language.
class MailField {
  const MailField(this.key, this.label, this.value);

  /// from, to, cc, bcc, subject, files, text.
  final String key;
  final String label;
  final String value;

  Map<String, String> toJson() => {'key': key, 'label': label, 'value': value};
}

const _labels = {
  'it': {
    'from': 'Da',
    'to': 'A',
    'cc': 'Cc',
    'bcc': 'Ccn',
    'subject': 'Oggetto',
    'files': 'Allegati',
    'text': 'Testo',
  },
  'en': {
    'from': 'From',
    'to': 'To',
    'cc': 'Cc',
    'bcc': 'Bcc',
    'subject': 'Subject',
    'files': 'Attachments',
    'text': 'Text',
  },
};

/// What an email about to leave says, field by field, in the person's language (the request's
/// card shows it; the text is whole). Empty when the request carries no prepared message.
List<MailField> mailRequestFields(String lang, Object? input) {
  final l = lang == 'it' ? 'it' : 'en';
  final m = preparedMailOf(input);
  if (m == null) return const [];
  final w = _labels[l]!;
  final none = l == 'it' ? 'nessuno' : 'none';
  String or(String s, String other) => s.isEmpty ? other : s;
  return [
    MailField('from', w['from']!, m.mailbox.isNotEmpty ? '${m.from} (${m.mailbox})' : m.from),
    MailField('to', w['to']!, or(m.to.join(', '), none)),
    if (m.cc.isNotEmpty) MailField('cc', w['cc']!, m.cc.join(', ')),
    if (m.bcc.isNotEmpty) MailField('bcc', w['bcc']!, m.bcc.join(', ')),
    MailField(
      'subject',
      w['subject']!,
      or(m.subject, l == 'it' ? '(senza oggetto)' : '(no subject)'),
    ),
    MailField(
      'files',
      w['files']!,
      m.attachments.isNotEmpty
          ? m.attachments.map((a) => '${a.name} (${mailSize(a.size, l)})').join(', ')
          : none,
    ),
    MailField('text', w['text']!, m.body),
  ];
}

/// A sender as people say it: the name, or the address (the page's `who`).
String mailWho(String s) {
  final out = s.replaceFirst(RegExp(r'\s*<[^>]*>\s*$'), '').replaceAll(RegExp(r'^"|"$'), '');
  return out.isEmpty ? s : out;
}

List<String> _recipients(Object? v) => v is List
    ? [
        for (final x in v)
          if (x is String) x,
      ]
    : v is String
    ? [for (final x in v.split(RegExp('[,;]'))) x.trim()]
    : const [];

/// The tool line's summary for a mail tool: what it looked for, which message, to whom (the
/// page's `mailSummary`); null when [tool] is not a mail tool.
String? mailSummary(AppLocalizations l, String tool, Object? input) =>
    mailSummaryWith(tool, input, unread: l.mailCardUnread, draft: l.mailCardDraft);

/// [mailSummary] with its words given: [unread] and [draft] are `mailCardUnread` and
/// `mailCardDraft`.
String? mailSummaryWith(
  String tool,
  Object? input, {
  required String unread,
  required String draft,
}) {
  if (!tool.startsWith('mail_') || !_isObject(input)) return null;
  Object? i(String k) => _field(input, k);
  if (tool == 'mail_search') {
    final s = ['from', 'to', 'subject', 'text', 'since', 'before', 'folder']
        .where((k) => i(k) is String && (i(k) as String).isNotEmpty)
        .map((k) => '$k: ${i(k)}')
        .join(' · ');
    return s.isNotEmpty ? s : (i('unread') == true ? unread : '');
  }
  if (tool == 'mail_read' || tool == 'mail_move') {
    final ids = i('ids');
    return [
      i('id') is num ? '#${_js(i('id'))}' : '',
      ids is List ? ids.map((x) => '#${_js(x)}').join(' ') : '',
      i('action') is String ? i('action') as String : '',
      i('folder') is String ? i('folder') as String : '',
    ].where((s) => s.isNotEmpty).join(' · ');
  }
  final m = preparedMailOf(input);
  final to = m != null ? [...m.to, ...m.cc] : _recipients(i('to'));
  final subject = m?.subject ?? (i('subject') is String ? i('subject') as String : '');
  final ref = i('draft_id') is num
      ? '$draft #${_js(i('draft_id'))}'
      : i('reply_to') is num
      ? 'Re #${_js(i('reply_to'))}'
      : i('forward') is num
      ? 'Fwd #${_js(i('forward'))}'
      : '';
  return [ref, to.map(mailWho).join(', '), subject].where((s) => s.isNotEmpty).join(' · ');
}

const _months = {
  // ICU's short months (Node's toLocaleString, it-IT and en-GB), as in the vectors.
  'it': ['gen', 'feb', 'mar', 'apr', 'mag', 'giu', 'lug', 'ago', 'set', 'ott', 'nov', 'dic'],
  'en': ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sept', 'Oct', 'Nov', 'Dec'],
};

final _serverDate = RegExp(r'^(\d{4})-(\d{2})-(\d{2}) (\d{2}):(\d{2}) UTC$');

/// «2026-11-02 10:00 UTC» in the person's time and words («2 nov 2026, 11:00»); anything else as
/// it is (the page's `mailDate`). [toLocal] turns the UTC moment into the person's (tests: UTC).
String mailDate(String s, String lang, {DateTime Function(DateTime utc)? toLocal}) {
  final m = _serverDate.firstMatch(s);
  if (m == null) return s;
  final [y, mo, d, h, mi] = [for (var g = 1; g <= 5; g++) int.parse(m[g]!)];
  // What JavaScript's Date takes in an ISO string: days up to 31 (30 February rolls over).
  if (mo < 1 || mo > 12 || d < 1 || d > 31 || h > 24 || (h == 24 && mi > 0) || mi > 59) return s;
  final t = (toLocal ?? (u) => u.toLocal())(DateTime.utc(y, mo, d, h, mi));
  String two(int n) => n.toString().padLeft(2, '0');
  final names = _months[lang == 'it' ? 'it' : 'en']!;
  return '${t.day} ${names[t.month - 1]} ${t.year}, ${two(t.hour)}:${two(t.minute)}';
}

/// What a mail_draft answered: where the draft is, to whom and about what (app only: the page
/// says it in the tool line).
class MailDraftDone {
  const MailDraftDone({
    required this.changed,
    this.id,
    required this.to,
    required this.cc,
    required this.bcc,
    required this.subject,
    required this.attachments,
  });

  final bool changed;
  final int? id;
  final List<String> to;
  final List<String> cc;
  final List<String> bcc;
  final String subject;
  final List<String> attachments;
}

final _draftHead = RegExp(r'^(Saved|Changed) the draft(?: (\d+))? in ');

List<String> _commaList(String s) => s.isEmpty
    ? const []
    : [
        for (final x in s.split(', '))
          if (x.trim().isNotEmpty) x.trim(),
      ];

/// The draft a mail_draft answer describes (MailService's sentence), or null.
MailDraftDone? parseMailDraft(String text) {
  final lines = text.split('\n');
  final head = _draftHead.firstMatch(lines.first);
  if (head == null) return null;
  var to = <String>[], cc = <String>[], bcc = <String>[], files = <String>[];
  var subject = '';
  for (final l in lines.skip(1)) {
    if (l.startsWith('To: ')) {
      for (final part in l.substring(4).split(' | ')) {
        if (part.startsWith('Cc: ')) {
          cc = _commaList(part.substring(4));
        } else if (part.startsWith('Bcc: ')) {
          bcc = _commaList(part.substring(5));
        } else if (part != '(nobody yet)') {
          to = _commaList(part);
        }
      }
    } else if (l.startsWith('Subject: ')) {
      final s = l.substring(9);
      subject = s == '(none)' ? '' : s;
    } else if (l.startsWith('Attachments: ')) {
      files = _commaList(l.substring(13));
    }
  }
  return MailDraftDone(
    changed: head[1] == 'Changed',
    id: head[2] == null ? null : int.parse(head[2]!),
    to: to,
    cc: cc,
    bcc: bcc,
    subject: subject,
    attachments: files,
  );
}

/// What a mail_send answered: what left, from which mailbox, to whom.
class MailSentDone {
  const MailSentDone({required this.subject, required this.mailbox, required this.to});

  final String subject;
  final String mailbox;
  final List<String> to;
}

final _sent = RegExp(r'^Sent "(.*)" from "(.*?)" to (.*?)\.(?: |$)');

/// The email a mail_send answer says left (MailService's sentence), or null.
MailSentDone? parseMailSent(String text) {
  final m = _sent.firstMatch(text);
  if (m == null) return null;
  return MailSentDone(subject: m[1]!, mailbox: m[2]!, to: _commaList(m[3]!));
}

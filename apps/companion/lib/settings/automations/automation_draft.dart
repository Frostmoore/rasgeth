// G42.9: the automation editor's pure part, ported from the page's AutomationEditor.tsx line by
// line: the schedule in words and its cron (`When`, `toCron`, `fromCron`, `fromOn`, `whenWords`),
// the draft with everything the person can choose (`Draft`, `blankDraft`, `fromRecipe`), the YAML
// it becomes (`toYaml`, strings quoted as JSON as the page writes them) and the sentence that
// reads it back (`sentence`). Checked against the page's own functions with
// test/fixtures/automation_vectors.json (tool/automation_vectors.mjs).
import 'dart:convert';

import 'package:intl/intl.dart';

import '../../api/conversation.dart' show Project;
import '../../api/types.dart';
import '../../l10n/app_localizations.dart';

// --- When it runs on a schedule, in words ---------------------------------------------------

/// The kinds of `When`, as the page's union.
const whenKinds = [
  'daily',
  'weekdays',
  'weekly',
  'hours',
  'monthly',
  'webhook',
  'repo',
  'email',
  'custom',
  'minutes',
  'once',
];

/// A schedule (the page's `When`): only the fields its kind uses mean anything.
class When {
  const When(
    this.kind, {
    this.time = '08:00',
    this.days = const [],
    this.every = 1,
    this.day = 1,
    this.at = '',
    this.cron = '',
    this.project = '',
    this.events = const [],
    this.from = '',
    this.subject = '',
  });

  final String kind;
  final String time;
  final List<int> days;
  final int every;
  final int day;
  final String at;
  final String cron;
  final String project;
  final List<String> events;
  final String from;
  final String subject;

  /// Whether this kind has a time of day (the page's `"time" in w`).
  bool get hasTime => const ['daily', 'weekdays', 'weekly', 'monthly'].contains(kind);

  When copy({
    String? time,
    List<int>? days,
    int? every,
    int? day,
    String? at,
    String? cron,
  }) => When(
    kind,
    time: time ?? this.time,
    days: days ?? this.days,
    every: every ?? this.every,
    day: day ?? this.day,
    at: at ?? this.at,
    cron: cron ?? this.cron,
    project: project,
    events: events,
    from: from,
    subject: subject,
  );

  /// From the page's object (the vectors).
  factory When.fromJson(Map<String, dynamic> j) => When(
    _s(j['kind']) ?? 'daily',
    time: _s(j['time']) ?? '08:00',
    days: [
      for (final d in j['days'] is List ? j['days'] as List : const [])
        if (d is num) d.toInt(),
    ],
    every: _int(j['every'], 1),
    day: _int(j['day'], 1),
    at: _s(j['at']) ?? '',
    cron: _s(j['cron']) ?? '',
    project: _s(j['project']) ?? '',
    events: _strs(j['events']),
    from: _s(j['from']) ?? '',
    subject: _s(j['subject']) ?? '',
  );

  /// As the page's object (for the vectors).
  Map<String, Object?> toJson() => switch (kind) {
    'daily' || 'weekdays' => {'kind': kind, 'time': time},
    'weekly' => {'kind': kind, 'time': time, 'days': days},
    'hours' || 'minutes' => {'kind': kind, 'every': every},
    'monthly' => {'kind': kind, 'time': time, 'day': day},
    'webhook' => {'kind': kind},
    'repo' => {'kind': kind, 'project': project, 'events': events},
    'email' => {'kind': kind, 'from': from, 'subject': subject},
    'once' => {'kind': kind, 'at': at},
    _ => {'kind': kind, 'cron': cron},
  };
}

String _pad(int n) => n.toString().padLeft(2, '0');

({int h, int m}) _hm(String time) {
  final p = time.split(':');
  return (h: int.tryParse(p.isNotEmpty ? p[0] : '8') ?? 0, m: int.tryParse(p.length > 1 ? p[1] : '0') ?? 0);
}

/// The cron expression of a choice (null: no schedule).
String? toCron(When w) {
  if (const ['webhook', 'repo', 'email', 'once'].contains(w.kind)) return null;
  if (w.kind == 'custom') return w.cron;
  if (w.kind == 'hours') return '0 */${w.every.clamp(1, 23)} * * *';
  if (w.kind == 'minutes') return '*/${w.every.clamp(1, 59)} * * * *';
  final t = _hm(w.time);
  final h = t.h;
  final m = t.m;
  if (w.kind == 'daily') return '$m $h * * *';
  if (w.kind == 'weekdays') return '$m $h * * 1-5';
  if (w.kind == 'monthly') return '$m $h ${w.day} * *';
  if (w.kind == 'weekly') {
    final days = ([...w.days.map((d) => '$d')]..sort()).join(',');
    return '$m $h * * ${days.isEmpty ? '1' : days}';
  }
  return '$m $h * * *';
}

Map<String, dynamic> _obj(Object? o) => o is Map<String, dynamic> ? o : const {};
String? _s(Object? o) => o is String ? o : null;
List<String> _strs(Object? o) => [
  for (final x in o is List ? o : const [])
    if (x is String) x,
];

/// The choice a recipe's `on` came from: repository events and email first, then the cron.
When fromOn(Map<String, dynamic> on, String? project) {
  final email = on['email'];
  if (email is Map) {
    return When('email', from: _s(email['from']) ?? '', subject: _s(email['subject']) ?? '');
  }
  if (on['events'] is List && on['cron'] == null) {
    return When('repo', project: project ?? '', events: _strs(on['events']));
  }
  if (_s(on['at']) case final at?) return When('once', at: at);
  return fromCron(_s(on['cron']), on['webhook'] == true);
}

/// The choice a cron expression came from, when it is one of ours; otherwise "custom".
When fromCron(String? cron, bool webhook) {
  if (cron == null || cron.isEmpty) {
    return webhook ? const When('webhook') : const When('daily', time: '08:00');
  }
  final f = cron.trim().split(RegExp(r'\s+'));
  String? at(int i) => i < f.length ? f[i] : null;
  final m = at(0);
  final h = at(1);
  final dom = at(2);
  final mon = at(3);
  final dow = at(4);
  int? num(String? x) => x != null && RegExp(r'^\d+$').hasMatch(x) ? int.parse(x) : null;
  final every = h == null ? null : RegExp(r'^\*/(\d+)$').firstMatch(h);
  if (f.length == 5 && m == '0' && every != null && dom == '*' && mon == '*' && dow == '*') {
    return When('hours', every: int.parse(every.group(1)!));
  }
  final everyMin = m == null ? null : RegExp(r'^\*/(\d+)$').firstMatch(m);
  if (f.length == 5 && everyMin != null && h == '*' && dom == '*' && mon == '*' && dow == '*') {
    return When('minutes', every: int.parse(everyMin.group(1)!));
  }
  final mm = num(m);
  final hh = num(h);
  if (f.length != 5 || mm == null || hh == null || mon != '*') return When('custom', cron: cron);
  final time = '${_pad(hh)}:${_pad(mm)}';
  if (dom == '*' && dow == '*') return When('daily', time: time);
  if (dom == '*' && dow == '1-5') return When('weekdays', time: time);
  if (dom == '*' && dow != null && RegExp(r'^[0-6](,[0-6])*$').hasMatch(dow)) {
    return When('weekly', time: time, days: dow.split(',').map(int.parse).toList());
  }
  if (num(dom) != null && dow == '*') return When('monthly', time: time, day: int.parse(dom!));
  return When('custom', cron: cron);
}

/// Monday first, as the page's `DAYS`.
const weekDays = [1, 2, 3, 4, 5, 6, 0];

String dayName(AppLocalizations l, int d) => switch (d) {
  0 => l.auDay_0,
  1 => l.auDay_1,
  2 => l.auDay_2,
  3 => l.auDay_3,
  4 => l.auDay_4,
  5 => l.auDay_5,
  _ => l.auDay_6,
};

/// A date and time as the page's `toLocaleString()` would say it, in the app's language.
String dateTimeWords(AppLocalizations l, String iso) {
  final d = DateTime.tryParse(iso);
  if (d == null) return iso;
  return DateFormat.yMd(l.localeName).add_Hm().format(d.toLocal());
}

String _emailFilter(AppLocalizations l, String from, String subject) {
  final parts = [
    if (from.isNotEmpty) '${l.auEmailFrom} $from',
    if (subject.isNotEmpty) '«$subject»',
  ];
  return parts.isEmpty ? l.auEmailAny : parts.join(' · ');
}

/// A sentence for people: "Every weekday at 08:00".
String whenWords(AppLocalizations l, When w) => switch (w.kind) {
  'daily' => l.auWhenDaily(w.time),
  'weekdays' => l.auWhenWeekdays(w.time),
  'weekly' => l.auWhenWeekly(w.days.map((d) => dayName(l, d)).join(', '), w.time),
  'hours' => l.auWhenHours('${w.every}'),
  'minutes' => l.auAxWhenMinutes('${w.every}'),
  'monthly' => l.auWhenMonthly('${w.day}', w.time),
  'once' => l.auWhenAt(w.at.isEmpty ? '' : dateTimeWords(l, w.at)),
  'webhook' => l.auWhenWebhook,
  'repo' => l.auWhenRepo(w.events.join(', ')),
  'email' => l.auWhenEmail(_emailFilter(l, w.from, w.subject)),
  _ => l.auWhenCustom(w.cron),
};

// --- The draft ----------------------------------------------------------------------------

/// What can start an automation (one or more of them).
const starts = [
  'time',
  'email',
  'message',
  'files',
  'repo',
  'after',
  'task',
  'startup',
  'webhook',
];

const platforms = [
  'telegram',
  'whatsapp',
  'discord',
  'slack',
  'signal',
  'matrix',
  'teams',
  'imessage',
];

const platformNames = {
  'telegram': 'Telegram',
  'whatsapp': 'WhatsApp',
  'discord': 'Discord',
  'slack': 'Slack',
  'signal': 'Signal',
  'matrix': 'Matrix',
  'teams': 'Teams',
  'imessage': 'iMessage',
};

const repoEvents = ['push', 'pull_request', 'issues', 'issue_comment', 'release'];
const schedules = ['daily', 'weekdays', 'weekly', 'monthly', 'hours', 'minutes', 'once'];

/// Everything the person can choose (the page's `Draft`). Changed in place by the editor.
class Draft {
  Draft({
    this.title = '',
    List<String>? starts,
    this.time = const When('daily', time: '09:00'),
    this.emailFrom = '',
    this.emailSubject = '',
    this.emailText = '',
    this.emailScope = 'all',
    this.emailCategories = const [],
    this.emailBoxes = const [],
    this.messagePlatforms = const [],
    this.messageFrom = '',
    this.messageChat = '',
    this.messageWords = '',
    this.messageHandle = false,
    this.filesProject = '',
    this.filesPath = '.',
    this.filesPattern = '',
    this.filesChanges = const [],
    this.repoProject = '',
    this.repoEvents = const ['pull_request'],
    this.afterAutomation = '',
    this.afterStatus = const [],
    this.taskProject = '',
    this.taskOutcome = const [],
    this.onlyHours = false,
    this.onlyFrom = '09:00',
    this.onlyTo = '18:00',
    this.onlyDays,
    this.onlyDates = false,
    this.onlyDateFrom = '',
    this.onlyDateTo = '',
    this.onlySenders = '',
    this.onlyWords = '',
    this.onlyMatch = 'any',
    this.onlyWithout = '',
    this.onlyMaxPerDay = 0,
    this.onlyCooldown = 0,
    this.does = 'agent',
    this.whoKey = 'god',
    this.instructions = '',
    this.reminder = '',
    this.session = 'new',
    this.approve = false,
    this.budget = 0,
    this.timeout = 30,
    this.notifyWhen = 'always',
    this.notifyTo = const [],
    this.notifyEmail = '',
    this.notifyBox = '',
    this.retries = 0,
    this.retryMinutes = 5,
    this.fallback = '',
    this.overlap = 'skip',
    this.missed = 'skip',
    this.model = '',
    this.effort = '',
    this.timezone,
  }) : starts = starts ?? ['time'];

  String title;
  List<String> starts;
  When time;
  String emailFrom;
  String emailSubject;
  String emailText;

  /// all, categories, boxes.
  String emailScope;
  List<String> emailCategories;
  List<String> emailBoxes;
  List<String> messagePlatforms;
  String messageFrom;
  String messageChat;
  String messageWords;
  bool messageHandle;
  String filesProject;
  String filesPath;
  String filesPattern;
  List<String> filesChanges;
  String repoProject;
  List<String> repoEvents;
  String afterAutomation;
  List<String> afterStatus;
  String taskProject;
  List<String> taskOutcome;
  bool onlyHours;
  String onlyFrom;
  String onlyTo;
  List<int>? onlyDays;
  bool onlyDates;
  String onlyDateFrom;
  String onlyDateTo;
  String onlySenders;
  String onlyWords;
  String onlyMatch;
  String onlyWithout;
  int onlyMaxPerDay;
  int onlyCooldown;

  /// agent, reminder.
  String does;
  String whoKey;
  String instructions;
  String reminder;
  String session;
  bool approve;
  double budget;
  int timeout;
  String notifyWhen;
  List<String> notifyTo;
  String notifyEmail;
  String notifyBox;
  int retries;
  int retryMinutes;
  String fallback;
  String overlap;
  String missed;
  String model;
  String effort;

  /// Kept from the recipe as it was.
  String? timezone;

  bool has(String s) => starts.contains(s);

  /// From the page's object (the vectors).
  factory Draft.fromJson(Map<String, dynamic> j) {
    final email = _obj(j['email']);
    final message = _obj(j['message']);
    final files = _obj(j['files']);
    final repo = _obj(j['repo']);
    final after = _obj(j['after']);
    final task = _obj(j['task']);
    final only = _obj(j['only']);
    return Draft(
      title: _s(j['title']) ?? '',
      starts: _strs(j['starts']),
      time: When.fromJson(_obj(j['time'])),
      emailFrom: _s(email['from']) ?? '',
      emailSubject: _s(email['subject']) ?? '',
      emailText: _s(email['text']) ?? '',
      emailScope: _s(email['scope']) ?? 'all',
      emailCategories: _strs(email['categories']),
      emailBoxes: _strs(email['boxes']),
      messagePlatforms: _strs(message['platforms']),
      messageFrom: _s(message['from']) ?? '',
      messageChat: _s(message['chat']) ?? '',
      messageWords: _s(message['words']) ?? '',
      messageHandle: message['handle'] == true,
      filesProject: _s(files['project']) ?? '',
      filesPath: _s(files['path']) ?? '.',
      filesPattern: _s(files['pattern']) ?? '',
      filesChanges: _strs(files['changes']),
      repoProject: _s(repo['project']) ?? '',
      repoEvents: _strs(repo['events']),
      afterAutomation: _s(after['automation']) ?? '',
      afterStatus: _strs(after['status']),
      taskProject: _s(task['project']) ?? '',
      taskOutcome: _strs(task['outcome']),
      onlyHours: only['hours'] == true,
      onlyFrom: _s(only['from']) ?? '09:00',
      onlyTo: _s(only['to']) ?? '18:00',
      onlyDays: only['days'] is List
          ? [
              for (final d in only['days'] as List)
                if (d is num) d.toInt(),
            ]
          : null,
      onlyDates: only['dates'] == true,
      onlyDateFrom: _s(only['dateFrom']) ?? '',
      onlyDateTo: _s(only['dateTo']) ?? '',
      onlySenders: _s(only['senders']) ?? '',
      onlyWords: _s(only['words']) ?? '',
      onlyMatch: _s(only['match']) ?? 'any',
      onlyWithout: _s(only['without']) ?? '',
      onlyMaxPerDay: _int(only['maxPerDay'], 0),
      onlyCooldown: _int(only['cooldown'], 0),
      does: _s(j['does']) ?? 'agent',
      whoKey: _s(j['whoKey']) ?? 'god',
      instructions: _s(j['instructions']) ?? '',
      reminder: _s(j['reminder']) ?? '',
      session: _s(j['session']) ?? 'new',
      approve: j['approve'] == true,
      budget: j['budget'] is num ? (j['budget'] as num).toDouble() : 0,
      timeout: _int(j['timeout'], 30),
      notifyWhen: _s(j['notifyWhen']) ?? 'always',
      notifyTo: _strs(j['notifyTo']),
      notifyEmail: _s(j['notifyEmail']) ?? '',
      notifyBox: _s(j['notifyBox']) ?? '',
      retries: _int(j['retries'], 0),
      retryMinutes: _int(j['retryMinutes'], 5),
      fallback: _s(j['fallback']) ?? '',
      overlap: _s(j['overlap']) ?? 'skip',
      missed: _s(j['missed']) ?? 'skip',
      model: _s(j['model']) ?? '',
      effort: _s(j['effort']) ?? '',
      timezone: _s(j['timezone']),
    );
  }

  /// As the page's object (for the vectors).
  Map<String, Object?> toJson() => {
    'title': title,
    'starts': starts,
    'time': time.toJson(),
    'email': {
      'from': emailFrom,
      'subject': emailSubject,
      'text': emailText,
      'scope': emailScope,
      'categories': emailCategories,
      'boxes': emailBoxes,
    },
    'message': {
      'platforms': messagePlatforms,
      'from': messageFrom,
      'chat': messageChat,
      'words': messageWords,
      'handle': messageHandle,
    },
    'files': {
      'project': filesProject,
      'path': filesPath,
      'pattern': filesPattern,
      'changes': filesChanges,
    },
    'repo': {'project': repoProject, 'events': repoEvents},
    'after': {'automation': afterAutomation, 'status': afterStatus},
    'task': {'project': taskProject, 'outcome': taskOutcome},
    'only': {
      'hours': onlyHours,
      'from': onlyFrom,
      'to': onlyTo,
      'days': onlyDays,
      'dates': onlyDates,
      'dateFrom': onlyDateFrom,
      'dateTo': onlyDateTo,
      'senders': onlySenders,
      'words': onlyWords,
      'match': onlyMatch,
      'without': onlyWithout,
      'maxPerDay': onlyMaxPerDay,
      'cooldown': onlyCooldown,
    },
    'does': does,
    'whoKey': whoKey,
    'instructions': instructions,
    'reminder': reminder,
    'session': session,
    'approve': approve,
    'budget': budget,
    'timeout': timeout,
    'notifyWhen': notifyWhen,
    'notifyTo': notifyTo,
    'notifyEmail': notifyEmail,
    'notifyBox': notifyBox,
    'retries': retries,
    'retryMinutes': retryMinutes,
    'fallback': fallback,
    'overlap': overlap,
    'missed': missed,
    'model': model,
    'effort': effort,
    'timezone': timezone,
  };
}

/// A new draft: the first project chosen for files and repositories, as the page's `blankDraft`.
Draft blankDraft(List<Project> projects) {
  final first = projects.firstOrNull?.id ?? '';
  return Draft(filesProject: first, repoProject: first);
}

/// One who can be asked: God, a personal assistant, a project's lead, a project agent.
class WhoOption {
  const WhoOption({
    required this.key,
    required this.label,
    required this.agent,
    required this.project,
  });

  final String key;
  final String label;
  final String agent;
  final String? project;
}

/// Who can be asked, as the page's `whoOptions`.
List<WhoOption> whoOptions(AppLocalizations l, List<Agent> agents) {
  final out = <WhoOption>[];
  final god = agents.where((a) => a.kind == AgentKind.god).firstOrNull;
  if (god != null) out.add(WhoOption(key: 'god', label: god.name, agent: 'god', project: null));
  for (final a in agents) {
    if (a.kind == AgentKind.assistant && a.status == 'active') {
      out.add(WhoOption(key: 'p:${a.id}', label: a.name, agent: a.id, project: null));
    }
  }
  for (final a in agents) {
    final p = a.projectId;
    if (a.status != 'active' || p == null || p.isEmpty) continue;
    if (a.kind == AgentKind.orchestrator) {
      out.add(WhoOption(key: 'o:$p', label: l.auWhoLead(p), agent: 'orchestrator', project: p));
    } else if (a.kind == AgentKind.agent) {
      out.add(WhoOption(key: 'a:${a.id}', label: '${a.name} ($p)', agent: a.name, project: p));
    }
  }
  return out;
}

String _whoKeyOf(Map<String, dynamic> r, List<WhoOption> who) {
  final agent = _s(r['agent']) ?? 'god';
  final project = _s(r['project']);
  if (agent == 'god') return 'god';
  if (agent == 'orchestrator') return 'o:$project';
  return who.where((x) => x.agent == agent && x.project == project).firstOrNull?.key ??
      who.where((x) => x.agent == agent).firstOrNull?.key ??
      'god';
}

int _int(Object? o, int or) => o is num ? o.toInt() : or;

/// The draft a saved (or proposed) recipe becomes. Nothing it says is lost.
Draft fromRecipe(Map<String, dynamic> r, List<WhoOption> who, List<Project> projects) {
  final on = _obj(r['on']);
  final project = _s(r['project']);
  final s = <String>[
    if (on['cron'] != null || on['at'] != null) 'time',
    if (on['email'] != null) 'email',
    if (on['message'] != null) 'message',
    if (on['files'] != null) 'files',
    if (on['events'] != null) 'repo',
    if (on['after'] != null) 'after',
    if (on['task'] != null) 'task',
    if (on['startup'] == true) 'startup',
    if (on['webhook'] == true && on['events'] == null) 'webhook',
  ];
  final only = r['only'] is Map<String, dynamic> ? r['only'] as Map<String, dynamic> : null;
  final b = blankDraft(projects);
  final email = _obj(on['email']);
  final message = _obj(on['message']);
  final files = _obj(on['files']);
  final after = _obj(on['after']);
  final task = _obj(on['task']);
  final hours = only == null ? null : only['hours'];
  final dates = only == null ? null : only['dates'];
  final notify = _obj(r['notify']);
  final onFailure = _obj(r['onFailure']);
  final description = _s(r['description']) ?? '';
  return Draft(
    title: description.isNotEmpty ? description : (_s(r['name']) ?? ''),
    starts: s,
    time: on['at'] is String
        ? When('once', at: on['at'] as String)
        : on['cron'] is String
        ? fromCron(on['cron'] as String, false)
        : b.time,
    emailFrom: _s(email['from']) ?? '',
    emailSubject: _s(email['subject']) ?? '',
    emailText: _s(email['text']) ?? '',
    emailScope: email['boxes'] != null
        ? 'boxes'
        : email['categories'] != null
        ? 'categories'
        : 'all',
    emailCategories: _strs(email['categories']),
    emailBoxes: _strs(email['boxes']),
    messagePlatforms: _strs(message['platforms']),
    messageFrom: _s(message['from']) ?? '',
    messageChat: _s(message['chat']) ?? '',
    messageWords: _strs(message['words']).join(', '),
    messageHandle: message['handle'] == true,
    filesProject: _s(files['project']) ?? project ?? b.filesProject,
    filesPath: _s(files['path']) ?? '.',
    filesPattern: _s(files['pattern']) ?? '',
    filesChanges: _strs(files['changes']),
    repoProject: project ?? b.repoProject,
    repoEvents: on['events'] is List ? _strs(on['events']) : b.repoEvents,
    afterAutomation: _s(after['automation']) ?? '',
    afterStatus: _strs(after['status']),
    taskProject: _s(task['project']) ?? '',
    taskOutcome: _strs(task['outcome']),
    onlyHours: hours is Map,
    onlyFrom: hours is Map ? (_s(hours['from']) ?? '09:00') : '09:00',
    onlyTo: hours is Map ? (_s(hours['to']) ?? '18:00') : '18:00',
    onlyDays: only != null && only['days'] is List
        ? [
            for (final d in only['days'] as List)
              if (d is num) d.toInt(),
          ]
        : null,
    onlyDates: dates is Map,
    onlyDateFrom: dates is Map ? (_s(dates['from']) ?? '') : '',
    onlyDateTo: dates is Map ? (_s(dates['to']) ?? '') : '',
    onlySenders: _strs(only?['from']).join(', '),
    onlyWords: _strs(only?['words']).join(', '),
    onlyMatch: _s(only?['match']) ?? 'any',
    onlyWithout: _strs(only?['without']).join(', '),
    onlyMaxPerDay: _int(only?['maxPerDay'], 0),
    onlyCooldown: _int(only?['cooldownMinutes'], 0),
    does: r['reminder'] != null ? 'reminder' : 'agent',
    whoKey: _whoKeyOf(r, who),
    instructions: _s(r['instructions']) ?? '',
    reminder: _s(r['reminder']) ?? '',
    session: _s(r['session']) ?? 'new',
    approve: r['approve'] == true,
    budget: r['budgetUsd'] is num ? (r['budgetUsd'] as num).toDouble() : 0,
    timeout: _int(r['timeoutMinutes'], 30),
    notifyWhen: _s(notify['when']) ?? 'always',
    notifyTo: _strs(notify['to']),
    notifyEmail: _s(notify['email']) ?? '',
    notifyBox: _s(notify['box']) ?? '',
    retries: _int(onFailure['retries'], 0),
    retryMinutes: _int(onFailure['retryMinutes'], 5),
    fallback: _s(onFailure['run']) ?? '',
    overlap: _s(r['overlap']) ?? 'skip',
    missed: _s(r['missed']) ?? 'skip',
    model: _s(r['model']) ?? '',
    effort: _s(r['effort']) ?? '',
    timezone: _s(on['timezone']),
  );
}

// --- The YAML -----------------------------------------------------------------------------

/// A value as JavaScript's JSON.stringify writes it (whole numbers without «.0»).
String _js(Object? v) {
  if (v is double && v.isFinite && v == v.truncateToDouble()) return '${v.toInt()}';
  if (v is List) return '[${v.map(_js).join(',')}]';
  return jsonEncode(v);
}

/// The page's `yamlLines`: strings quoted as JSON (YAML reads it), lists inline; null skipped.
List<String> _yamlLines(Map<String, Object?> obj, [int indent = 0]) {
  final out = <String>[];
  final sp = '  ' * indent;
  for (final MapEntry(:key, :value) in obj.entries) {
    if (value == null) continue;
    if (value is Map<String, Object?>) {
      final inner = _yamlLines(value, indent + 1);
      out.add(inner.isNotEmpty ? '$sp$key:' : '$sp$key: {}');
      out.addAll(inner);
    } else {
      out.add('$sp$key: ${_js(value)}');
    }
  }
  return out;
}

List<String> _words(String s) => [
  for (final w in s.split(','))
    if (w.trim().isNotEmpty) w.trim(),
];
List<T>? _some<T>(List<T> l) => l.isEmpty ? null : l;
int? _set(int n) => n > 0 ? n : null;
String? _nonEmpty(String s) => s.isEmpty ? null : s;
bool _anySet(Map<String, Object?> m) => m.values.any((v) => v != null);

/// The recipe a draft becomes, as YAML. [zone] is the device's time zone (the page's browser's).
String toYaml(Draft d, String name, List<WhoOption> who, {String? zone}) {
  final w = who.where((x) => x.key == d.whoKey).firstOrNull;
  final whoAgent = w?.agent ?? 'god';
  final whoProject = w?.project;
  final cron = d.has('time') ? toCron(d.time) : null;
  final at = d.has('time') && d.time.kind == 'once' ? d.time.at : null;
  final project = whoProject ?? (d.has('repo') ? _nonEmpty(d.repoProject) : null);
  final o = d;
  // As the page: an empty list of days still counts (JavaScript's `[]` is true).
  final needsZone =
      cron != null ||
      (at != null && at.isNotEmpty) ||
      o.onlyHours ||
      o.onlyDays != null ||
      o.onlyDates ||
      o.onlyMaxPerDay != 0;
  final on = <String, Object?>{
    if (cron != null && cron.isNotEmpty) 'cron': cron,
    if (at != null && at.isNotEmpty) 'at': at,
    if (needsZone) 'timezone': d.timezone ?? zone ?? 'UTC',
    if (d.has('webhook') || d.has('repo')) 'webhook': true,
    if (d.has('repo')) 'events': d.repoEvents.isNotEmpty ? d.repoEvents : ['push'],
    if (d.has('email'))
      'email': <String, Object?>{
        'from': _nonEmpty(d.emailFrom.trim()),
        'subject': _nonEmpty(d.emailSubject.trim()),
        'text': _nonEmpty(d.emailText.trim()),
        'boxes': d.emailScope == 'boxes' ? _some(d.emailBoxes) : null,
        'categories': d.emailScope == 'categories' ? _some(d.emailCategories) : null,
      },
    if (d.has('message'))
      'message': <String, Object?>{
        'platforms': _some(d.messagePlatforms),
        'from': _nonEmpty(d.messageFrom.trim()),
        'chat': _nonEmpty(d.messageChat.trim()),
        'words': _some(_words(d.messageWords)),
        'handle': d.messageHandle ? true : null,
      },
    if (d.has('files'))
      'files': <String, Object?>{
        'project': d.filesProject.isNotEmpty && d.filesProject != project ? d.filesProject : null,
        'path': d.filesPath.trim().isEmpty ? '.' : d.filesPath.trim(),
        'pattern': _nonEmpty(d.filesPattern.trim()),
        'changes': _some(d.filesChanges),
      },
    if (d.has('after'))
      'after': <String, Object?>{
        'automation': d.afterAutomation,
        'status': _some(d.afterStatus),
      },
    if (d.has('task'))
      'task': <String, Object?>{
        'project': _nonEmpty(d.taskProject),
        'outcome': _some(d.taskOutcome),
      },
    if (d.has('startup')) 'startup': true,
  };
  final days = o.onlyDays;
  final only = <String, Object?>{
    'hours': o.onlyHours ? <String, Object?>{'from': o.onlyFrom, 'to': o.onlyTo} : null,
    'days': days != null && days.isNotEmpty ? ([...days]..sort((a, b) => '$a'.compareTo('$b'))) : null,
    'dates': o.onlyDates && (o.onlyDateFrom.isNotEmpty || o.onlyDateTo.isNotEmpty)
        ? <String, Object?>{'from': _nonEmpty(o.onlyDateFrom), 'to': _nonEmpty(o.onlyDateTo)}
        : null,
    'from': _some(_words(o.onlySenders)),
    'words': _some(_words(o.onlyWords)),
    'match': o.onlyMatch == 'all' && _words(o.onlyWords).isNotEmpty ? 'all' : null,
    'without': _some(_words(o.onlyWithout)),
    'maxPerDay': _set(o.onlyMaxPerDay),
    'cooldownMinutes': _set(o.onlyCooldown),
  };
  final notify = <String, Object?>{
    'when': d.notifyWhen == 'always' ? null : d.notifyWhen,
    'to': _some(d.notifyTo),
    'email': d.notifyTo.contains('email') && d.notifyEmail.trim().isNotEmpty
        ? d.notifyEmail.trim()
        : null,
    'box': d.notifyTo.contains('email') && d.notifyBox.isNotEmpty ? d.notifyBox : null,
  };
  final onFailure = <String, Object?>{
    'retries': _set(d.retries),
    'retryMinutes': d.retries > 0 && d.retryMinutes != 5 ? d.retryMinutes : null,
    'run': _nonEmpty(d.fallback),
  };
  final reminder = d.does == 'reminder';
  final lines = _yamlLines({
    'name': name,
    'description': d.title.trim(),
    'on': on,
    'only': _anySet(only) ? only : null,
    'agent': reminder ? null : whoAgent,
    'project': project,
    'model': !reminder && d.model.trim().isNotEmpty ? d.model.trim() : null,
    'effort': !reminder && d.effort.isNotEmpty ? d.effort : null,
    'instructions': reminder ? null : d.instructions.trim(),
    'reminder': reminder ? d.reminder.trim() : null,
    'session': !reminder && d.session == 'continue' ? 'continue' : null,
    'approve': d.approve ? true : null,
    'budgetUsd': !reminder && d.budget > 0 ? d.budget : null,
    'timeoutMinutes': d.timeout != 30 ? d.timeout : null,
    'overlap': d.overlap == 'queue' ? 'queue' : null,
    'missed': d.missed == 'run' && (at == null || at.isEmpty) ? 'run' : null,
    'onFailure': _anySet(onFailure) ? onFailure : null,
    'notify': _anySet(notify) ? notify : null,
  });
  return '${lines.join('\n')}\n';
}

// --- The sentence -------------------------------------------------------------------------

String _cut(String s, [int n = 90]) => s.length > n ? '${s.substring(0, n - 1).trimRight()}…' : s;

/// What starts an automation, in words (the chips of «When»).
String startLabel(AppLocalizations l, String s) => switch (s) {
  'email' => l.auWhenKind_email,
  'repo' => l.auWhenKind_repo,
  'webhook' => l.auWhenKind_webhook,
  'time' => l.auAxStart_time,
  'message' => l.auAxStart_message,
  'files' => l.auAxStart_files,
  'after' => l.auAxStart_after,
  'task' => l.auAxStart_task,
  _ => l.auAxStart_startup,
};

/// Where a message goes, in words.
String targetLabel(AppLocalizations l, String x) => x == 'web'
    ? l.auAxToWeb
    : x == 'email'
    ? l.auAxToEmail
    : (platformNames[x] ?? x);

/// The automation in words, as it stands: what starts it, only if, what it does, where it
/// tells. [others]: the other automations, by name and title (for «after»).
List<String> sentence(
  AppLocalizations l,
  Draft d,
  List<WhoOption> who, [
  Map<String, String> others = const {},
]) {
  final out = <String>[];
  final parts = <String>[];
  for (final s in d.starts) {
    switch (s) {
      case 'time':
        parts.add(whenWords(l, d.time));
      case 'email':
        parts.add(l.auAxSayEmail(_emailFilter(l, d.emailFrom, d.emailSubject)));
      case 'message':
        parts.add(
          l.auAxSayMessage(
                d.messagePlatforms.isNotEmpty
                    ? d.messagePlatforms.map((p) => platformNames[p] ?? p).join(', ')
                    : l.auAxAnyChat,
              ) +
              (d.messageWords.isNotEmpty ? ' ${l.auAxSayWith(d.messageWords)}' : ''),
        );
      case 'files':
        parts.add(
          d.filesPath.isEmpty || d.filesPath == '.'
              ? l.auAxSayFilesAll
              : l.auAxSayFiles(d.filesPath),
        );
      case 'repo':
        parts.add(l.auWhenRepo(d.repoEvents.join(', ')));
      case 'after':
        final title = others[d.afterAutomation];
        parts.add(
          l.auAxSayAfter(
            title != null && title.isNotEmpty
                ? title
                : (d.afterAutomation.isNotEmpty ? d.afterAutomation : '…'),
          ),
        );
      case 'task':
        parts.add(l.auAxSayTask);
      case 'startup':
        parts.add(l.auAxSayStartup);
      case 'webhook':
        parts.add(l.auWhenWebhook);
    }
  }
  // "Every day at 8 or when an email arrives": the parts after the first in lower case.
  final lowered = [
    for (final (i, x) in parts.indexed)
      i == 0 || x.isEmpty ? x : x[0].toLowerCase() + x.substring(1),
  ];
  out.add(lowered.isNotEmpty ? '${lowered.join(' ${l.auAxOr} ')}.' : l.auAxSayNever);
  final o = d;
  final conds = <String>[
    if (o.onlyHours) l.auAxSayHours(o.onlyFrom, o.onlyTo),
    if (o.onlyDays case final days? when days.isNotEmpty)
      l.auAxSayDays(days.map((x) => dayName(l, x)).join(', ')),
    if (o.onlyDates && (o.onlyDateFrom.isNotEmpty || o.onlyDateTo.isNotEmpty))
      l.auAxSayDates(
        o.onlyDateFrom.isEmpty ? '…' : o.onlyDateFrom,
        o.onlyDateTo.isEmpty ? '…' : o.onlyDateTo,
      ),
    if (o.onlySenders.isNotEmpty) l.auAxSayFrom(o.onlySenders),
    if (o.onlyWords.isNotEmpty)
      o.onlyMatch == 'all' ? l.auAxSayWordsAll(o.onlyWords) : l.auAxSayWordsAny(o.onlyWords),
    if (o.onlyWithout.isNotEmpty) l.auAxSayWithout(o.onlyWithout),
    if (o.onlyMaxPerDay > 0) l.auAxSayMax('${o.onlyMaxPerDay}'),
    if (o.onlyCooldown > 0) l.auAxSayCooldown('${o.onlyCooldown}'),
  ];
  if (conds.isNotEmpty) out.add('${l.auAxSayOnly} ${conds.join(', ')}.');
  final whoLabel = who.where((x) => x.key == d.whoKey).firstOrNull?.label ?? 'God';
  if (d.does == 'reminder') {
    out.add(l.auAxSayReminder(_cut(d.reminder.trim().isEmpty ? '…' : d.reminder.trim())));
  } else {
    out.add(
      l.auAxSayDoes(whoLabel, _cut(d.instructions.trim().isEmpty ? '…' : d.instructions.trim())),
    );
  }
  if (d.approve) out.add(l.auAxSayApprove);
  if (d.does == 'agent' && d.budget > 0) out.add(l.auAxSayBudget(d.budget.toStringAsFixed(2)));
  if (d.notifyWhen == 'never') {
    out.add(l.auAxSayQuiet);
  } else {
    final where = d.notifyTo.isNotEmpty
        ? d.notifyTo.map((x) => targetLabel(l, x)).join(', ')
        : l.auAxToAllChats;
    out.add(d.notifyWhen == 'failure' ? l.auAxSayTellFailure(where) : l.auAxSayTell(where));
  }
  return out;
}

// --- Templates and names ------------------------------------------------------------------

const templates = ['morning', 'weekly', 'spending'];

const templateWhen = {
  'morning': When('weekdays', time: '08:00'),
  'weekly': When('weekly', time: '17:00', days: [5]),
  'spending': When('monthly', time: '09:00', day: 1),
};

String templateTitle(AppLocalizations l, String x) => switch (x) {
  'morning' => l.auTplTitle_morning,
  'weekly' => l.auTplTitle_weekly,
  'spending' => l.auTplTitle_spending,
  _ => l.auTplTitle_blank,
};

String templateDesc(AppLocalizations l, String x) => switch (x) {
  'morning' => l.auTplDesc_morning,
  'weekly' => l.auTplDesc_weekly,
  'spending' => l.auTplDesc_spending,
  _ => l.auTplDesc_blank,
};

String templateText(AppLocalizations l, String x) => switch (x) {
  'morning' => l.auTplText_morning,
  'weekly' => l.auTplText_weekly,
  _ => l.auTplText_spending,
};

/// A recipe's name from its title (the page's `slug`): lowercase letters, digits and dashes.
String slug(String s) {
  const from = 'àáâãäåèéêëìíîïòóôõöùúûüñçÀÁÂÃÄÅÈÉÊËÌÍÎÏÒÓÔÕÖÙÚÛÜÑÇ';
  const to = 'aaaaaaeeeeiiiiooooouuuuncAAAAAAEEEEIIIIOOOOOUUUUNC';
  final b = StringBuffer();
  for (final ch in s.split('')) {
    final i = from.indexOf(ch);
    b.write(i >= 0 ? to[i] : ch);
  }
  var out = b
      .toString()
      .toLowerCase()
      .replaceAll(RegExp('[^a-z0-9]+'), '-')
      .replaceAll(RegExp(r'^-+|-+$'), '');
  if (out.length > 50) out = out.substring(0, 50);
  return out.isEmpty ? 'automation' : out;
}

/// The kind of schedule, keeping the time already written (the page's `scheduleOf`).
When scheduleOf(String kind, When current, {DateTime? now}) {
  final time = current.hasTime ? current.time : '08:00';
  switch (kind) {
    case 'weekly':
      return When(kind, time: time, days: const [5]);
    case 'monthly':
      return When(kind, time: time, day: 1);
    case 'hours':
      return const When('hours', every: 3);
    case 'minutes':
      return const When('minutes', every: 15);
    case 'once':
      final d = (now ?? DateTime.now()).add(const Duration(days: 1));
      return When(kind, at: '${d.year}-${_pad(d.month)}-${_pad(d.day)}T$time');
    case 'custom':
      return When(kind, cron: toCron(current) ?? '0 9 * * *');
    default:
      return When(kind, time: time);
  }
}

/// A mailbox category in words (the default ones translated, the person's own as written).
String categoryLabel(AppLocalizations l, String c) => switch (c) {
  'work' => l.auAxCat_work,
  'personal' => l.auAxCat_personal,
  'social' => l.auAxCat_social,
  'other' => l.auAxCat_other,
  _ => c,
};

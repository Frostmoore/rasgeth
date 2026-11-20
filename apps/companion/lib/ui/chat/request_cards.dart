// A request waiting for the person, inside the conversation it belongs to (G42.1), as the page's
// `PermissionCard` (packages/web/src/components/Chat.tsx): a switched-off tool asked back
// (`ToolRequestCard.tsx`), an artifact's first use of a capability (`ArtifactGrantCard.tsx`), or
// any other call (`ToolPermission`): what it does in words (the server's `words`, the page's
// `requestSentence`), why, its dangers, the details folded, then «Consenti», «Consenti sempre per
// questo lavoro» (a danger, 3.9.8), «Per questa chat», «Sempre», «Nega» and «Nega e spiega». The buttons wait a moment once shown (the page's
// `useArmed`, 800 ms): a tap meant for something else decides nothing. A truly dangerous request
// (G36.17b) shows red here too, but its yes is given only from its own screen
// (`CriticalRequestScreen`). The first answer, here or anywhere, closes every copy.
import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';

import '../../api/conversation.dart';
import '../../app_state.dart';
import '../../l10n/app_localizations.dart';
import '../../l10n/tool_words.g.dart';
import '../../screens/inbox_screen.dart' show CriticalRequestScreen, requestSummary;
import '../../theme/colors.dart';
import '../icons.dart';
import 'mail_cards.dart';

/// The page's `ARM_MS`.
const armDelay = Duration(milliseconds: 800);

/// `ARTIFACT_GRANT_TOOL`, `ARTIFACT_ASK_CAPS`, `ARTIFACT_ASK_CAP_DEFAULT` (artifact-bridge.ts).
const artifactGrantTool = 'artifact_capability';
const artifactAskCaps = [0.1, 0.5, 2.0, 5.0];
const artifactAskCapDefault = 0.5;

/// A cap in dollars, as the page writes money (`usd` in ArtifactGrantCard.tsx).
String capUsd(double n) =>
    '${n < 1 ? n.toStringAsFixed(2) : n.toStringAsFixed(n % 1 == 0 ? 0 : 1)} \$';

/// The request's card in the chat, of the right kind.
class ChatRequestCard extends StatelessWidget {
  const ChatRequestCard({super.key, required this.request});

  final PermissionRequest request;

  @override
  Widget build(BuildContext context) => switch (request.tool) {
    'request_tool' => ToolRequestCard(request: request),
    artifactGrantTool => ArtifactGrantCard(request: request),
    _ => ToolPermissionCard(request: request),
  };
}

/// Off for [armDelay] once built, then on (`useArmed`).
mixin _Armed<T extends StatefulWidget> on State<T> {
  bool armed = false;
  Timer? _arm;

  @override
  void initState() {
    super.initState();
    _arm = Timer(armDelay, () {
      if (mounted) setState(() => armed = true);
    });
  }

  @override
  void dispose() {
    _arm?.cancel();
    super.dispose();
  }
}

enum ActKind { yes, always, no, critical, plain }

/// One of a card's buttons, as `.permission-actions button` (yes green, always plain, no red).
class ActButton extends StatelessWidget {
  const ActButton({
    super.key,
    required this.label,
    required this.kind,
    required this.onTap,
    this.tooltip,
  });

  final String label;
  final ActKind kind;
  final VoidCallback? onTap;
  final String? tooltip;

  @override
  Widget build(BuildContext context) {
    final c = RgColors.of(context);
    final (bg, fg, border) = switch (kind) {
      ActKind.yes => (c.ok, Colors.white, null),
      ActKind.no => (c.err, Colors.white, null),
      ActKind.critical => (c.critical, c.criticalInk, null),
      ActKind.always || ActKind.plain => (c.panel, c.text, c.line),
    };
    final button = Opacity(
      opacity: onTap == null ? .5 : 1,
      child: Material(
        color: bg,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: border == null ? BorderSide.none : BorderSide(color: border),
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(8),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
            child: Text(
              label,
              style: TextStyle(color: fg, fontWeight: FontWeight.w600, fontSize: 14),
            ),
          ),
        ),
      ),
    );
    return tooltip == null ? button : Tooltip(message: tooltip, child: button);
  }
}

/// At most [width] wide, on the left (`.permission`: `align-self: stretch; max-width: 860px`): in
/// a list the width is imposed, so the limit needs room to be smaller.
class MaxWidthLeft extends StatelessWidget {
  const MaxWidthLeft({super.key, required this.child, this.width = 860});

  final Widget child;
  final double width;

  @override
  Widget build(BuildContext context) => Align(
    alignment: Alignment.centerLeft,
    child: ConstrainedBox(
      constraints: BoxConstraints(maxWidth: width),
      child: child,
    ),
  );
}

/// The card's frame: accent border on the accent's soft colour (`.permission`), red for a truly
/// dangerous one.
class RequestFrame extends StatelessWidget {
  const RequestFrame({super.key, required this.child, this.critical = false, this.id});

  final Widget child;
  final bool critical;
  final String? id;

  @override
  Widget build(BuildContext context) {
    final c = RgColors.of(context);
    return MaxWidthLeft(
      child: Container(
        key: id == null ? null : Key('chat-request-$id'),
        width: double.infinity,
        decoration: BoxDecoration(
          color: critical ? c.criticalSoft : c.accentSoft,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: critical ? c.critical : c.accent, width: critical ? 3 : 2),
        ),
        clipBehavior: Clip.antiAlias,
        child: child,
      ),
    );
  }
}

String _lang(BuildContext context) => Localizations.localeOf(context).languageCode;

/// Any call that asks for the person's yes.
class ToolPermissionCard extends StatefulWidget {
  const ToolPermissionCard({super.key, required this.request});

  final PermissionRequest request;

  @override
  State<ToolPermissionCard> createState() => _ToolPermissionCardState();
}

class _ToolPermissionCardState extends State<ToolPermissionCard> with _Armed {
  bool _details = false;
  bool _all = false;

  /// «Nega e spiega»: the words the agent reads (null: not asked).
  TextEditingController? _why;
  bool _sent = false;

  @override
  void dispose() {
    _why?.dispose();
    super.dispose();
  }

  Future<void> _resolve(bool allow, {String scope = 'once', String? reason}) async {
    if (!armed || _sent) return;
    setState(() => _sent = true);
    final ok = await AppScope.read(context)
        .resolvePermission(widget.request, allow: allow, scope: scope, reason: reason);
    if (!ok && mounted) setState(() => _sent = false);
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final c = RgColors.of(context);
    final r = widget.request;
    final w = r.wordsIn(_lang(context));
    final critical = r.isCritical;
    final what = w?.what ?? requestSummary(r);
    final input = const JsonEncoder.withIndent('  ').convert(r.input);
    final long = input.split('\n').length > 8;
    final on = armed && !_sent;
    final dangers = w?.dangers ?? [for (final d in r.danger) (id: d, name: d, hint: '')];
    return RequestFrame(
      id: r.requestId,
      critical: critical,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (critical)
            Container(
              width: double.infinity,
              color: c.critical,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              child: Row(
                children: [
                  RgIcon(RgIcons.alert, size: 22, color: c.criticalInk),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      l.cvCriticalTitle,
                      style: TextStyle(
                        color: c.criticalInk,
                        fontWeight: FontWeight.w700,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (critical && (w?.critical.isNotEmpty ?? false)) ...[
                  Text(
                    l.cvCriticalWhat.toUpperCase(),
                    style: TextStyle(
                      color: c.criticalText,
                      fontSize: 11.5,
                      letterSpacing: .5,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  for (final s in w!.critical)
                    Padding(
                      padding: const EdgeInsets.only(top: 3, left: 4),
                      child: Text(
                        s,
                        style: TextStyle(color: c.text, fontWeight: FontWeight.w600, fontSize: 15),
                      ),
                    ),
                  const SizedBox(height: 8),
                ],
                Row(
                  children: [
                    RgIcon(RgIcons.shield, size: 16, color: critical ? c.criticalText : c.accent),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        l.cvPermAsks(r.agentName),
                        style: TextStyle(color: c.text, fontWeight: FontWeight.w600),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  what,
                  key: Key('request-what-${r.requestId}'),
                  style: TextStyle(color: c.text, fontSize: 15, height: 1.35),
                ),
                if (r.tool == 'mail_send')
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: MailRequestPreview(input: r.input),
                  ),
                if ((w?.reasons.isNotEmpty ?? false) || dangers.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Wrap(
                      spacing: 6,
                      runSpacing: 4,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        if (w?.reasons.isNotEmpty ?? false)
                          Text(
                            '${l.cvPermWhy}: ${w!.reasons.join('; ')}',
                            style: TextStyle(color: c.dim, fontSize: 13),
                          ),
                        for (final d in dangers)
                          Tooltip(
                            message: d.hint,
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: c.err.withValues(alpha: .12),
                                borderRadius: BorderRadius.circular(999),
                                border: Border.all(color: c.err.withValues(alpha: .5)),
                              ),
                              child: Text(d.name, style: TextStyle(color: c.err, fontSize: 12)),
                            ),
                          ),
                      ],
                    ),
                  ),
                InkWell(
                  key: Key('request-details-${r.requestId}'),
                  onTap: () => setState(() => _details = !_details),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        RgIcon(
                          _details ? RgIcons.chevronDown : RgIcons.chevronRight,
                          size: 14,
                          color: c.dim,
                        ),
                        const SizedBox(width: 4),
                        Text(l.cvPermDetails, style: TextStyle(color: c.dim, fontSize: 13)),
                      ],
                    ),
                  ),
                ),
                if (_details) ...[
                  Text.rich(
                    TextSpan(
                      text: '${l.cvPermTool}: ',
                      children: [
                        TextSpan(
                          text: r.tool,
                          style: const TextStyle(fontFamily: 'monospace'),
                        ),
                      ],
                    ),
                    style: TextStyle(color: c.dim, fontSize: 13),
                  ),
                  if (r.reasons.isNotEmpty)
                    Text(
                      '${l.cvPermRawReasons}: ${r.reasons.join('; ')}',
                      style: TextStyle(color: c.dim, fontSize: 13),
                    ),
                  Container(
                    margin: const EdgeInsets.symmetric(vertical: 6),
                    padding: const EdgeInsets.all(8),
                    width: double.infinity,
                    constraints: BoxConstraints(maxHeight: _all ? double.infinity : 140),
                    decoration: BoxDecoration(
                      color: c.code,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: c.line),
                    ),
                    child: SingleChildScrollView(
                      child: SelectableText(
                        input,
                        style: TextStyle(fontFamily: 'monospace', fontSize: 12, color: c.text),
                      ),
                    ),
                  ),
                  if (long)
                    TextButton(
                      onPressed: () => setState(() => _all = !_all),
                      child: Text(_all ? l.cvShowLess : l.cvShowAllInput),
                    ),
                ],
                const SizedBox(height: 6),
                Wrap(
                  key: Key('request-actions-${r.requestId}'),
                  spacing: 8,
                  runSpacing: 8,
                  children: critical
                      ? [
                          ActButton(
                            key: Key('chat-open-${r.requestId}'),
                            label: l.requestLook,
                            kind: ActKind.critical,
                            onTap: on
                                ? () => Navigator.of(context).push(
                                    MaterialPageRoute<void>(
                                      fullscreenDialog: true,
                                      builder: (_) => CriticalRequestScreen(request: r),
                                    ),
                                  )
                                : null,
                          ),
                          ActButton(
                            key: Key('chat-deny-${r.requestId}'),
                            label: l.cvDeny,
                            kind: ActKind.plain,
                            onTap: on ? () => _resolve(false) : null,
                          ),
                        ]
                      : [
                          ActButton(
                            key: Key('chat-allow-${r.requestId}'),
                            label: l.cvAllow,
                            kind: ActKind.yes,
                            onTap: on ? () => _resolve(true) : null,
                          ),
                          if (r.offersWorkAllow)
                            ActButton(
                              key: Key('chat-work-${r.requestId}'),
                              label: l.cvAllowWork,
                              tooltip: l.cvAllowWorkHint,
                              kind: ActKind.always,
                              onTap: on ? () => _resolve(true, scope: 'work') : null,
                            ),
                          if (r.danger.isEmpty && r.sessionId != null)
                            ActButton(
                              key: Key('chat-session-${r.requestId}'),
                              label: l.cvThisChat,
                              tooltip: l.cvThisChatHint(r.tool),
                              kind: ActKind.always,
                              onTap: on ? () => _resolve(true, scope: 'session') : null,
                            ),
                          if (r.danger.isEmpty)
                            ActButton(
                              key: Key('chat-always-${r.requestId}'),
                              label: l.cvAlways,
                              tooltip: l.cvAlwaysHint(r.tool),
                              kind: ActKind.always,
                              onTap: on ? () => _resolve(true, scope: 'always') : null,
                            ),
                          ActButton(
                            key: Key('chat-deny-${r.requestId}'),
                            label: l.cvDeny,
                            kind: ActKind.no,
                            onTap: on ? () => _resolve(false) : null,
                          ),
                          if (_why == null)
                            TextButton(
                              key: Key('chat-why-${r.requestId}'),
                              onPressed: on
                                  ? () => setState(() => _why = TextEditingController())
                                  : null,
                              child: Text(l.cvDenyWhy),
                            ),
                        ],
                ),
                if (_why != null && !critical)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Row(
                      children: [
                        Expanded(
                          child: TextField(
                            key: Key('chat-why-text-${r.requestId}'),
                            controller: _why,
                            autofocus: true,
                            maxLength: 1000,
                            onChanged: (_) => setState(() {}),
                            onSubmitted: (t) {
                              if (t.trim().isNotEmpty) _resolve(false, reason: t);
                            },
                            decoration: InputDecoration(
                              isDense: true,
                              counterText: '',
                              hintText: l.cvDenyWhyPlaceholder,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        ActButton(
                          key: Key('chat-why-send-${r.requestId}'),
                          label: l.cvDeny,
                          kind: ActKind.no,
                          onTap: _why!.text.trim().isEmpty || _sent
                              ? null
                              : () => _resolve(false, reason: _why!.text),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// A switched-off tool asked back (G36.15): this conversation, always for this agent, or no.
class ToolRequestCard extends StatefulWidget {
  const ToolRequestCard({super.key, required this.request});

  final PermissionRequest request;

  @override
  State<ToolRequestCard> createState() => _ToolRequestCardState();
}

class _ToolRequestCardState extends State<ToolRequestCard> with _Armed {
  bool _sent = false;

  Future<void> _resolve(bool allow, [String scope = 'session']) async {
    if (!armed || _sent) return;
    setState(() => _sent = true);
    final ok = await AppScope.read(context)
        .resolvePermission(widget.request, allow: allow, scope: allow ? scope : 'session');
    if (!ok && mounted) setState(() => _sent = false);
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final c = RgColors.of(context);
    final r = widget.request;
    final input = r.input is Map ? r.input as Map : const {};
    final tool = input['tool'] is String ? input['tool'] as String : '';
    final why = input['why'] is String ? input['why'] as String : null;
    final on = armed && !_sent;
    return RequestFrame(
      id: r.requestId,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                RgIcon(RgIcons.tool, size: 18, color: c.accent),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    l.cvToolReqTitle(r.agentName, toolWords[_lang(context)]?['tool_$tool'] ?? tool),
                    style: TextStyle(color: c.text, fontWeight: FontWeight.w700, fontSize: 15),
                  ),
                ),
              ],
            ),
            if (why != null && why.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(l.cvToolReqWhy(why), style: TextStyle(color: c.text, fontSize: 14.5)),
              ),
            Padding(
              padding: const EdgeInsets.only(top: 6, bottom: 10),
              child: Text(
                l.cvToolReqHint(r.agentName),
                style: TextStyle(color: c.dim, fontSize: 13),
              ),
            ),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                ActButton(
                  key: Key('chat-session-${r.requestId}'),
                  label: l.cvToolReqSession,
                  kind: ActKind.yes,
                  onTap: on ? () => _resolve(true, 'session') : null,
                ),
                ActButton(
                  key: Key('chat-always-${r.requestId}'),
                  label: l.cvToolReqAlways(r.agentName),
                  kind: ActKind.always,
                  onTap: on ? () => _resolve(true, 'always') : null,
                ),
                ActButton(
                  key: Key('chat-deny-${r.requestId}'),
                  label: l.cvToolReqNo,
                  kind: ActKind.no,
                  onTap: on ? () => _resolve(false) : null,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// An artifact's first use of a capability (3.6, G38.7): for `ask`, the spending cap first.
class ArtifactGrantCard extends StatefulWidget {
  const ArtifactGrantCard({super.key, required this.request});

  final PermissionRequest request;

  @override
  State<ArtifactGrantCard> createState() => _ArtifactGrantCardState();
}

class _ArtifactGrantCardState extends State<ArtifactGrantCard> with _Armed {
  double _cap = artifactAskCapDefault;
  bool _sent = false;

  Future<void> _resolve(bool allow, bool isAsk) async {
    if (!armed || _sent) return;
    setState(() => _sent = true);
    final ok = await AppScope.read(context).resolvePermission(
      widget.request,
      allow: allow,
      // The page sends `remember: false` and no scope: a plain once.
      capUsd: allow && isAsk ? _cap : null,
    );
    if (!ok && mounted) setState(() => _sent = false);
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final c = RgColors.of(context);
    final r = widget.request;
    final input = r.input is Map ? r.input as Map : const {};
    final isAsk = input['capability'] == 'ask';
    final path = input['path'] is String ? input['path'] as String : null;
    final on = armed && !_sent;
    return RequestFrame(
      id: r.requestId,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                RgIcon(RgIcons.canvas, size: 18, color: c.accent),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    l.cvAgTitle,
                    style: TextStyle(color: c.text, fontWeight: FontWeight.w700, fontSize: 15),
                  ),
                ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Text(
                r.wordsIn(_lang(context))?.what ?? requestSummary(r),
                style: TextStyle(color: c.text, fontSize: 15),
              ),
            ),
            if (path != null)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  path,
                  style: TextStyle(color: c.dim, fontFamily: 'monospace', fontSize: 12.5),
                ),
              ),
            if (isAsk) ...[
              const SizedBox(height: 10),
              Text(l.cvAgCap, style: TextStyle(color: c.text, fontSize: 14)),
              const SizedBox(height: 6),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: [
                  for (final cap in artifactAskCaps)
                    _CapChip(
                      key: Key('chat-cap-$cap'),
                      label: capUsd(cap),
                      on: cap == _cap,
                      onTap: () => setState(() => _cap = cap),
                    ),
                ],
              ),
              const SizedBox(height: 4),
              Text(l.cvAgCapHint, style: TextStyle(color: c.dim, fontSize: 12.5)),
            ],
            Padding(
              padding: const EdgeInsets.only(top: 8, bottom: 10),
              child: Text(l.cvAgHint, style: TextStyle(color: c.dim, fontSize: 13)),
            ),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                ActButton(
                  key: Key('chat-allow-${r.requestId}'),
                  label: isAsk ? l.cvAgAllowCap(capUsd(_cap)) : l.cvAgAllow,
                  kind: ActKind.yes,
                  onTap: on ? () => _resolve(true, isAsk) : null,
                ),
                ActButton(
                  key: Key('chat-deny-${r.requestId}'),
                  label: l.cvAgDeny,
                  kind: ActKind.no,
                  onTap: on ? () => _resolve(false, isAsk) : null,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// One choice among a few (the page's `Chips`): drawn, never a native radio.
class _CapChip extends StatelessWidget {
  const _CapChip({super.key, required this.label, required this.on, required this.onTap});

  final String label;
  final bool on;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = RgColors.of(context);
    return Semantics(
      selected: on,
      button: true,
      child: Material(
        color: on ? c.accent : c.panel,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(999),
          side: BorderSide(color: on ? c.accent : c.line),
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(999),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            child: Text(
              label,
              style: TextStyle(
                color: on ? Colors.white : c.text,
                fontWeight: on ? FontWeight.w600 : FontWeight.w400,
                fontSize: 13.5,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

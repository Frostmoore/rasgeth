// The agents' shared browser (G42.3), native as the page's Screen.tsx: the pictures of its screen
// on the wire (`browser.frame`, JPEG) and the person's input back (`browser.input`), never a web
// view. The agents have it until the person takes control (`browser.control`); then a tap is a
// click, a drag or the wheel scrolls, the keys and the text go in, and the address bar goes
// somewhere (`browser.goto`). An assistant can be taught a task (`browser.teach`): the person does
// it once, every page, click and text is written down (never passwords) and becomes a skill.
import 'dart:async';

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../api/live_model.dart';
import '../api/types.dart';
import '../app_state.dart';
import '../l10n/app_localizations.dart';
import '../theme/colors.dart';
import '../ui/dialogs.dart';
import '../ui/icons.dart';
import '../ui/rg_menu.dart';

/// The keys that go as keys (the page's list); a single character goes as text.
final _named = {
  LogicalKeyboardKey.enter: 'Enter',
  LogicalKeyboardKey.numpadEnter: 'Enter',
  LogicalKeyboardKey.backspace: 'Backspace',
  LogicalKeyboardKey.delete: 'Delete',
  LogicalKeyboardKey.tab: 'Tab',
  LogicalKeyboardKey.escape: 'Escape',
  LogicalKeyboardKey.arrowUp: 'ArrowUp',
  LogicalKeyboardKey.arrowDown: 'ArrowDown',
  LogicalKeyboardKey.arrowLeft: 'ArrowLeft',
  LogicalKeyboardKey.arrowRight: 'ArrowRight',
  LogicalKeyboardKey.home: 'Home',
  LogicalKeyboardKey.end: 'End',
  LogicalKeyboardKey.pageUp: 'PageUp',
  LogicalKeyboardKey.pageDown: 'PageDown',
};

/// What a key press sends, or null (the page's `onKeyDown`): a named key, or one character typed
/// without Ctrl or Meta.
Map<String, Object?>? browserKey(KeyEvent e) {
  if (e is! KeyDownEvent && e is! KeyRepeatEvent) return null;
  final named = _named[e.logicalKey];
  if (named != null) return {'kind': 'key', 'key': named};
  final pressed = HardwareKeyboard.instance;
  final ch = e.character;
  if (ch != null && ch.runes.length == 1 && !pressed.isControlPressed && !pressed.isMetaPressed) {
    if (ch.codeUnitAt(0) < 32) return null;
    return {'kind': 'text', 'text': ch};
  }
  return null;
}

/// A point of the picture, between 0 and 1 (the page's `at`).
({double x, double y}) browserPoint(Offset local, Size size) =>
    (x: (local.dx / size.width).clamp(0.0, 1.0), y: (local.dy / size.height).clamp(0.0, 1.0));

Future<void> openBrowserScreen(BuildContext context) =>
    Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => const BrowserScreen()));

class BrowserScreen extends StatefulWidget {
  const BrowserScreen({super.key});

  @override
  State<BrowserScreen> createState() => _BrowserScreenState();
}

class _BrowserScreenState extends State<BrowserScreen> {
  late final AppController app = AppScope.read(context);
  final _address = TextEditingController();
  final _typing = TextEditingController();
  final _focus = FocusNode(debugLabel: 'browser-screen');
  String? _learner;
  double _drag = 0;

  BrowserView get b => app.live.browser;

  @override
  void initState() {
    super.initState();
    app.watchBrowser(true);
  }

  @override
  void dispose() {
    app.watchBrowser(false);
    _address.dispose();
    _typing.dispose();
    _focus.dispose();
    super.dispose();
  }

  void _input(Map<String, Object?> e) {
    if (b.mine) app.browserInput(e);
  }

  Future<void> _teach(List<Agent> assistants) async {
    final l = AppLocalizations.of(context);
    final c = RgColors.of(context);
    var who = _learner ?? assistants.firstOrNull?.id;
    if (assistants.length > 1) {
      who = await showRgSheet<String>(
        context,
        key: const Key('teach-who'),
        head: RgSheetHead(
          leading: RgIcon(RgIcons.user, size: 22, color: c.dim),
          title: l.cvTeachWho,
          subtitle: l.cvTeachHint,
        ),
        entries: [
          for (final a in assistants)
            RgMenuEntry(a.id, RgIcons.user, a.name, key: Key('teach-who-${a.id}')),
        ],
      );
    }
    if (who == null) return;
    setState(() => _learner = who);
    app.browserTeach(who, start: true);
  }

  Future<void> _teachDone() async {
    final l = AppLocalizations.of(context);
    final who = b.teaching ?? _learner;
    if (who == null) return;
    final title = await askText(
      context,
      title: l.cvTeachTitle,
      yes: l.cvTeachDone,
      fieldKey: const Key('teach-title'),
    );
    // Closed without a name: it stops all the same, without one (the page's `?? ""`).
    app.browserTeach(who, start: false, title: title);
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final c = RgColors.of(context);
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          key: const Key('browser-back'),
          tooltip: l.back,
          onPressed: () => Navigator.of(context).pop(),
          icon: RgIcon(RgIcons.arrowLeft, color: c.text),
        ),
        titleSpacing: 0,
        title: Row(
          children: [
            RgIcon(RgIcons.monitor, size: 18, color: c.dim),
            const SizedBox(width: 8),
            Expanded(child: Text(l.cvScreenTitle, maxLines: 1, overflow: TextOverflow.ellipsis)),
          ],
        ),
      ),
      body: ListenableBuilder(
        listenable: Listenable.merge([b, app]),
        builder: (context, _) {
          if (b.unavailable) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  l.cvScreenUnavailable,
                  key: const Key('browser-unavailable'),
                  textAlign: TextAlign.center,
                  style: TextStyle(color: c.dim, fontSize: 15),
                ),
              ),
            );
          }
          final assistants = app.agents
              .where((a) => a.kind == AgentKind.assistant && a.active)
              .toList();
          final teaching = b.teaching;
          final learner = app.agents.where((a) => a.id == teaching).firstOrNull?.name ?? '';
          final narrow = MediaQuery.sizeOf(context).width < 700;
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 10, 12, 6),
                child: Row(
                  children: [
                    Expanded(
                      child: b.mine
                          ? TextField(
                              key: const Key('browser-address'),
                              controller: _address,
                              keyboardType: TextInputType.url,
                              textInputAction: TextInputAction.go,
                              onSubmitted: (v) {
                                if (v.trim().isNotEmpty) app.browserGoto(v.trim());
                              },
                              decoration: InputDecoration(
                                isDense: true,
                                labelText: l.cvScreenAddress,
                                hintText: b.url,
                              ),
                            )
                          : Text(
                              b.url.isEmpty ? 'about:blank' : b.url,
                              key: const Key('browser-url'),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(color: c.dim, fontSize: 13.5),
                            ),
                    ),
                    const SizedBox(width: 10),
                    // The button may shrink on a phone: its words then end with «…».
                    if (teaching == null)
                      Flexible(
                        flex: 0,
                        child: ConstrainedBox(
                          constraints: BoxConstraints(maxWidth: narrow ? 170 : 320),
                          child: b.mine
                              ? OutlinedButton(
                                  key: const Key('browser-give-back'),
                                  onPressed: () => app.browserControl(false),
                                  child: Text(
                                    l.cvScreenGiveBack,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                )
                              : FilledButton(
                                  key: const Key('browser-take'),
                                  onPressed: () => app.browserControl(true),
                                  child: Text(
                                    l.cvScreenTake,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                        ),
                      ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 0, 12, 6),
                child: Text(
                  teaching != null
                      ? l.cvTeachRecording(learner)
                      : b.mine
                      ? l.cvScreenYours
                      : l.cvScreenShared,
                  key: const Key('browser-help'),
                  style: TextStyle(color: c.dim, fontSize: 12.5),
                ),
              ),
              if (assistants.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
                  child: Row(
                    children: [
                      if (teaching == null)
                        Tooltip(
                          message: l.cvTeachHint,
                          child: OutlinedButton.icon(
                            key: const Key('teach-start'),
                            onPressed: () => _teach(assistants),
                            icon: RgIcon(RgIcons.play, size: 14, color: c.text),
                            label: Text(
                              assistants.length == 1
                                  ? '${l.cvTeachStart} · ${assistants.first.name}'
                                  : l.cvTeachStart,
                            ),
                          ),
                        )
                      else
                        FilledButton.icon(
                          key: const Key('teach-done'),
                          onPressed: _teachDone,
                          icon: const RgIcon(RgIcons.check, size: 14, color: Colors.white),
                          label: Text(l.cvTeachDone),
                        ),
                    ],
                  ),
                ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                  child: _view(context, l, c),
                ),
              ),
              if (b.mine && narrow)
                SafeArea(
                  top: false,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(12, 0, 12, 10),
                    // On a phone the keyboard is a field: what is written goes in at once,
                    // «invio» presses Enter.
                    child: TextField(
                      key: const Key('browser-type'),
                      controller: _typing,
                      textInputAction: TextInputAction.send,
                      onChanged: (v) {
                        if (v.isEmpty) return;
                        _input({'kind': 'text', 'text': v});
                        _typing.clear();
                      },
                      onSubmitted: (_) => _input({'kind': 'key', 'key': 'Enter'}),
                      decoration: InputDecoration(
                        isDense: true,
                        prefixIcon: Padding(
                          padding: const EdgeInsets.all(10),
                          child: RgIcon(RgIcons.edit, size: 16, color: c.dim),
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }

  Widget _view(BuildContext context, AppLocalizations l, RgColors c) {
    final frame = b.frame;
    final ratio = b.width > 0 && b.height > 0 ? b.width / b.height : 16 / 10;
    final mine = b.mine;
    final picture = frame == null
        ? Center(
            child: Text(
              l.cvScreenStarting,
              key: const Key('browser-starting'),
              style: const TextStyle(color: Color(0xFFB0B4BC)),
            ),
          )
        : LayoutBuilder(
            builder: (context, box) {
              final size = Size(box.maxWidth, box.maxHeight);
              return Listener(
                onPointerSignal: (s) {
                  if (s is PointerScrollEvent) {
                    final p = browserPoint(s.localPosition, size);
                    _input({
                      'kind': 'scroll',
                      'x': p.x,
                      'y': p.y,
                      'dy': s.scrollDelta.dy.clamp(-5000, 5000).round(),
                    });
                  }
                },
                child: GestureDetector(
                  key: const Key('browser-view'),
                  behavior: HitTestBehavior.opaque,
                  onTapUp: (d) {
                    _focus.requestFocus();
                    final p = browserPoint(d.localPosition, size);
                    _input({'kind': 'click', 'x': p.x, 'y': p.y});
                  },
                  // A finger scrolls the page as the wheel does (gathered, then sent).
                  onVerticalDragUpdate: (d) {
                    _drag -= d.delta.dy;
                    if (_drag.abs() >= 40) {
                      final p = browserPoint(d.localPosition, size);
                      _input({'kind': 'scroll', 'x': p.x, 'y': p.y, 'dy': (_drag * 2).round()});
                      _drag = 0;
                    }
                  },
                  onVerticalDragEnd: (_) => _drag = 0,
                  child: Image.memory(
                    frame,
                    key: const Key('browser-frame'),
                    gaplessPlayback: true,
                    fit: BoxFit.fill,
                    filterQuality: FilterQuality.medium,
                  ),
                ),
              );
            },
          );
    return Center(
      child: AspectRatio(
        aspectRatio: ratio,
        child: Focus(
          focusNode: _focus,
          autofocus: mine,
          onKeyEvent: (node, e) {
            if (!mine) return KeyEventResult.ignored;
            final k = browserKey(e);
            if (k == null) return KeyEventResult.ignored;
            _input(k);
            return KeyEventResult.handled;
          },
          child: Container(
            decoration: BoxDecoration(
              color: Colors.black,
              border: Border.all(color: mine ? c.accent : c.line, width: mine ? 2 : 1),
            ),
            clipBehavior: Clip.hardEdge,
            child: picture,
          ),
        ),
      ),
    );
  }
}

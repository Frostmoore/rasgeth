// An Android emulator or phone live (3.11 phase 2), native as the page's DeviceScreen.tsx and the
// agents' browser (browser_screen.dart): the pictures of its screen on the wire (`device.frame`,
// JPEG) and the person's input back (`device.input`), never a web view. The agents have it until
// the person takes control (`device.control`); then a tap, a press held, a swipe, the keyboard and
// the phone's own buttons (drawn under it) go in, never logged and never seen by a model.
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../api/live_model.dart';
import '../app_state.dart';
import '../l10n/app_localizations.dart';
import '../settings/system/system_kit.dart' show sw;
import '../theme/colors.dart';
import '../ui/icons.dart';

/// The keys that go as keys (the page's `KEYS`); space is `Space`, one character goes as text.
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
};

/// What a key press sends to a device, or null (the page's `onKeyDown`).
Map<String, Object?>? deviceKey(KeyEvent e) {
  if (e is! KeyDownEvent && e is! KeyRepeatEvent) return null;
  final named = _named[e.logicalKey];
  if (named != null) return {'kind': 'key', 'key': named};
  if (e.logicalKey == LogicalKeyboardKey.space) return {'kind': 'key', 'key': 'Space'};
  final pressed = HardwareKeyboard.instance;
  final ch = e.character;
  if (ch != null && ch.runes.length == 1 && !pressed.isControlPressed && !pressed.isMetaPressed) {
    if (ch.codeUnitAt(0) < 32) return null;
    if (ch == ' ') return {'kind': 'key', 'key': 'Space'};
    return {'kind': 'text', 'text': ch};
  }
  return null;
}

typedef DevicePoint = ({double x, double y});

/// A pointer's path on the screen: a tap, a press held, or a swipe (the page's `gesture`). Pure.
Map<String, Object?> deviceGesture(DevicePoint from, DevicePoint to, int ms) {
  final dx = to.x - from.x;
  final dy = to.y - from.y;
  final moved = dx * dx + dy * dy;
  if (moved > 0.02 * 0.02) {
    return {
      'kind': 'swipe',
      'x': from.x,
      'y': from.y,
      'x2': to.x,
      'y2': to.y,
      'ms': ms.clamp(50, 5000),
    };
  }
  if (ms >= 500) return {'kind': 'long', 'x': from.x, 'y': from.y, 'ms': ms.clamp(0, 5000)};
  return {'kind': 'tap', 'x': from.x, 'y': from.y};
}

DevicePoint _at(Offset local, Size size) =>
    (x: (local.dx / size.width).clamp(0.0, 1.0), y: (local.dy / size.height).clamp(0.0, 1.0));

Future<void> openDeviceScreen(BuildContext context, String id, String title) =>
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => DeviceScreen(id: id, title: title),
      ),
    );

class DeviceScreen extends StatefulWidget {
  const DeviceScreen({super.key, required this.id, required this.title});

  /// `avd:<name>`, `ios:<udid>` or adb's serial.
  final String id;
  final String title;

  @override
  State<DeviceScreen> createState() => _DeviceScreenState();
}

class _DeviceScreenState extends State<DeviceScreen> {
  late final AppController app = AppScope.read(context);
  final _typing = TextEditingController();
  final _focus = FocusNode(debugLabel: 'device-screen');
  ({DevicePoint p, Duration at})? _down;

  DeviceViews get views => app.live.devices;
  DeviceView get d => views.of(widget.id);

  @override
  void initState() {
    super.initState();
    app.watchDevice(widget.id, true);
  }

  @override
  void dispose() {
    app.watchDevice(widget.id, false);
    _typing.dispose();
    _focus.dispose();
    super.dispose();
  }

  void _input(Map<String, Object?> e) {
    if (d.mine) app.deviceInput(widget.id, e);
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final c = RgColors.of(context);
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          key: const Key('dv-close'),
          tooltip: l.back,
          onPressed: () => Navigator.of(context).pop(),
          icon: RgIcon(RgIcons.arrowLeft, color: c.text),
        ),
        titleSpacing: 0,
        title: Row(
          children: [
            RgIcon(RgIcons.emulator, size: 18, color: c.dim),
            const SizedBox(width: 8),
            Expanded(child: Text(widget.title, maxLines: 1, overflow: TextOverflow.ellipsis)),
          ],
        ),
      ),
      body: ListenableBuilder(
        key: const Key('dv-screen'),
        listenable: views,
        builder: (context, _) {
          final mine = d.mine;
          final narrow = MediaQuery.sizeOf(context).width < 700;
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 10, 12, 6),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        '${widget.title} · ${sw(l, 'dsState_${d.state}')}',
                        key: const Key('dv-state'),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(color: c.dim, fontSize: 13.5),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Flexible(
                      flex: 0,
                      child: ConstrainedBox(
                        constraints: BoxConstraints(maxWidth: narrow ? 240 : 320),
                        child: mine
                            ? OutlinedButton(
                                key: const Key('dv-take'),
                                onPressed: d.state == 'on'
                                    ? () => app.deviceControl(widget.id, false)
                                    : null,
                                child: Text(
                                  l.syScreenGiveBack,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              )
                            : FilledButton(
                                key: const Key('dv-take'),
                                onPressed: d.state == 'on'
                                    ? () => app.deviceControl(widget.id, true)
                                    : null,
                                child: Text(
                                  l.syScreenTake,
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
                padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
                child: Text(
                  d.error != null
                      ? l.syDsError(d.error!)
                      : mine
                      ? l.syDsYours
                      : l.syDsShared,
                  key: const Key('dv-note'),
                  style: TextStyle(
                    color: d.error != null ? c.err : (mine ? c.accent : c.dim),
                    fontSize: 12.5,
                  ),
                ),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
                  child: _frame(context, l, c, mine),
                ),
              ),
              _keys(l, c, mine),
              if (mine && narrow)
                SafeArea(
                  top: false,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(12, 0, 12, 10),
                    // On a phone the keyboard is a field: what is written goes in at once,
                    // «invio» presses Enter.
                    child: TextField(
                      key: const Key('dv-type'),
                      controller: _typing,
                      textInputAction: TextInputAction.send,
                      onChanged: (v) {
                        if (v.isEmpty) return;
                        _input({
                          'kind': 'text',
                          'text': v.length > 2000 ? v.substring(0, 2000) : v,
                        });
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

  /// The picture in a phone's frame: a dark rounded bezel, turned when the screen is wide.
  Widget _frame(BuildContext context, AppLocalizations l, RgColors c, bool mine) {
    final frame = d.frame;
    final wide = d.wide;
    final ratio = frame != null && d.width > 0 && d.height > 0
        ? d.width / d.height
        : (wide ? 19.5 / 9 : 9 / 19.5);
    final picture = frame == null
        ? Center(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                d.state == 'starting' ? l.syDsStarting : l.syScreenStarting,
                key: const Key('dv-starting'),
                textAlign: TextAlign.center,
                style: const TextStyle(color: Color(0xFFB0B4BC)),
              ),
            ),
          )
        : Image.memory(
            frame,
            key: const Key('dv-frame'),
            gaplessPlayback: true,
            fit: BoxFit.fill,
            filterQuality: FilterQuality.medium,
          );
    return Center(
      child: Container(
        padding: EdgeInsets.all(wide ? 10 : 9),
        decoration: BoxDecoration(
          color: const Color(0xFF15171C),
          borderRadius: BorderRadius.circular(26),
          // A lighter edge so the phone stands out on the dark theme too.
          border: Border.all(color: mine ? c.accent : const Color(0xFF4A4F5A), width: 2),
        ),
        child: AspectRatio(
          aspectRatio: ratio,
          child: Focus(
            focusNode: _focus,
            autofocus: mine,
            onKeyEvent: (node, e) {
              if (!mine) return KeyEventResult.ignored;
              // Paste goes in as text (the page's `onPaste`).
              final keys = HardwareKeyboard.instance;
              if (e is KeyDownEvent &&
                  e.logicalKey == LogicalKeyboardKey.keyV &&
                  (keys.isControlPressed || keys.isMetaPressed)) {
                unawaited(
                  Clipboard.getData(Clipboard.kTextPlain).then((v) {
                    final t = v?.text ?? '';
                    if (t.isNotEmpty) {
                      _input({'kind': 'text', 'text': t.length > 2000 ? t.substring(0, 2000) : t});
                    }
                  }),
                );
                return KeyEventResult.handled;
              }
              final k = deviceKey(e);
              if (k == null) return KeyEventResult.ignored;
              _input(k);
              return KeyEventResult.handled;
            },
            child: ClipRRect(
              borderRadius: BorderRadius.circular(18),
              child: ColoredBox(
                color: Colors.black,
                child: Semantics(
                  image: true,
                  label: l.syDsScreen(widget.title),
                  child: LayoutBuilder(
                    builder: (context, box) {
                      final size = Size(box.maxWidth, box.maxHeight);
                      return Listener(
                        key: const Key('dv-view'),
                        behavior: HitTestBehavior.opaque,
                        onPointerDown: (e) {
                          if (!mine) return;
                          _focus.requestFocus();
                          _down = (p: _at(e.localPosition, size), at: e.timeStamp);
                        },
                        onPointerCancel: (_) => _down = null,
                        onPointerUp: (e) {
                          final start = _down;
                          _down = null;
                          if (!mine || start == null) return;
                          final ms = (e.timeStamp - start.at).inMilliseconds;
                          _input(deviceGesture(start.p, _at(e.localPosition, size), ms));
                        },
                        child: SizedBox.expand(child: picture),
                      );
                    },
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// The phone's own buttons and turning it, drawn under the frame. An iPhone has no back and no
  /// recents button (3.12.2): only home and turning.
  Widget _keys(AppLocalizations l, RgColors c, bool mine) {
    Widget key(String k, RgIcons icon, String tip, Map<String, Object?> event, double size) =>
        IconButton(
          key: Key('dv-$k'),
          tooltip: tip,
          onPressed: mine ? () => _input(event) : null,
          icon: RgIcon(icon, size: size, color: mine ? c.text : c.dim),
        );
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (!widget.id.startsWith('ios:')) ...[
            key('back', RgIcons.chevronLeft, l.syDsBack, {'kind': 'button', 'button': 'back'}, 18),
            const SizedBox(width: 12),
          ],
          key('home', RgIcons.home, l.syDsHome, {'kind': 'button', 'button': 'home'}, 18),
          const SizedBox(width: 12),
          if (!widget.id.startsWith('ios:')) ...[
            key('recents', RgIcons.square, l.syDsRecents, {
              'kind': 'button',
              'button': 'recents',
            }, 15),
            const SizedBox(width: 12),
          ],
          key('rotate', RgIcons.rotate, l.syDsRotate, {'kind': 'rotate'}, 18),
        ],
      ),
    );
  }
}

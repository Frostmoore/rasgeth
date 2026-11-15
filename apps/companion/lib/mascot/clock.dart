// One clock for every mascot on screen (as the page's CSS animations share the page's clock): a
// single ticker, about thirty updates a second, running only while some mascot moves and the app
// is in front. Each mascot reads the same seconds and applies its own rhythm.
import 'package:flutter/scheduler.dart';
import 'package:flutter/widgets.dart';

class MascotClock extends ChangeNotifier with WidgetsBindingObserver {
  MascotClock._();

  static final MascotClock instance = MascotClock._();

  /// How often the mascots are moved: enough for their slow motion, half the work of 60 fps.
  static const step = 1 / 30;

  Ticker? _ticker;
  bool _observing = false;
  bool _foreground = true;
  int _users = 0;
  double _offset = 0;
  double _seconds = 0;
  double _shown = -1;

  /// Seconds since the clock first ran (it stands still while paused).
  double get seconds => _seconds;

  bool get running => _ticker?.isActive ?? false;

  void attach(VoidCallback listener) {
    addListener(listener);
    _users++;
    if (!_observing) {
      _observing = true;
      WidgetsBinding.instance.addObserver(this);
      final s = WidgetsBinding.instance.lifecycleState;
      _foreground = s == null || s == AppLifecycleState.resumed;
    }
    _sync();
  }

  void detach(VoidCallback listener) {
    removeListener(listener);
    _users--;
    _sync();
  }

  void _sync() {
    final want = _users > 0 && _foreground;
    final t = _ticker ??= Ticker(_tick, debugLabel: 'mascots');
    if (want && !t.isActive) {
      t.start();
    } else if (!want && t.isActive) {
      _offset = _seconds;
      t.stop();
    }
  }

  void _tick(Duration elapsed) {
    _seconds = _offset + elapsed.inMicroseconds / 1e6;
    if (_seconds - _shown >= step - 1e-6 || _seconds < _shown) {
      _shown = _seconds;
      notifyListeners();
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _foreground = state == AppLifecycleState.resumed;
    _sync();
  }
}

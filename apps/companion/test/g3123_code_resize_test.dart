// 3.12.3: the Canvas panel's divider (between the conversation and the side area) is dragged, moved
// with the arrows, reset by a double tap or Enter, kept inside its limits and remembered on this
// device; and the Code view opens a file in the page's own editor (the Canvas) when it can.
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rgcompanion/api/servers.dart';
import 'package:rgcompanion/api/token_store.dart';
import 'package:rgcompanion/api/types.dart';
import 'package:rgcompanion/app_state.dart';
import 'package:rgcompanion/canvas/canvas_shell.dart';
import 'package:rgcompanion/l10n/app_localizations.dart';
import 'package:rgcompanion/theme/theme.dart';

const _file = {'kind': 'file', 'scope': 'platform', 'path': 'note.md'};

void main() {
  test('the panel width: the divider\'s, else the saved one, else 46%, within its limits', () {
    final m = CanvasPanelModel();
    expect(canvasPanelWidth(m, 1400), closeTo(644, .01));
    expect(canvasPanelWidth(m, 1400, saved: 500), 500);
    m.resize(700);
    expect(canvasPanelWidth(m, 1400, saved: 500), 700);
    m.resize(100);
    expect(canvasPanelWidth(m, 1400), 320);
    m.resize(5000);
    expect(canvasPanelWidth(m, 1400), 1040);
  });

  group('the divider', () {
    late AppController app;
    late MemoryAppPrefs prefs;
    late CanvasPanelModel model;

    Future<void> open(WidgetTester tester) async {
      prefs = MemoryAppPrefs();
      app = AppController(
        tokens: MemoryTokenStore(),
        prefs: prefs,
        platform: DevicePlatform.windows,
      );
      model = CanvasPanelModel()..show('Note', _file);
      tester.view.physicalSize = const Size(1400, 900);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(
        AppScope(
          controller: app,
          child: MaterialApp(
            theme: buildTheme(Brightness.light),
            localizationsDelegates: const [
              AppLocalizations.delegate,
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            supportedLocales: AppLocalizations.supportedLocales,
            home: Scaffold(
              body: Align(
                alignment: Alignment.centerRight,
                child: CanvasPanel(model: model, maxWidth: 1400),
              ),
            ),
          ),
        ),
      );
      await tester.pump();
    }

    double width(WidgetTester tester) =>
        tester.getSize(find.byKey(const Key('canvas-panel'))).width;

    testWidgets('a drag changes the width, within its limits, and it is remembered', (
      tester,
    ) async {
      await open(tester);
      final first = width(tester);
      expect(first, closeTo(644, 1));
      final handle = find.descendant(
        of: find.byKey(const Key('canvas-divider')),
        matching: find.byKey(const Key('panel-resizer')),
      );
      await tester.drag(handle, const Offset(-100, 0));
      await tester.pump();
      expect(width(tester), greaterThan(first + 50));
      expect(prefs.values['canvasWidth'], isNotNull);
      expect(app.canvasWidth, width(tester));
      // Far to the left: the chat keeps its 360.
      await tester.drag(find.byKey(const Key('panel-resizer')), const Offset(-2000, 0));
      await tester.pump();
      expect(width(tester), 1040);
      // Far to the right: never under 320.
      await tester.drag(find.byKey(const Key('panel-resizer')), const Offset(2000, 0));
      await tester.pump();
      expect(width(tester), 320);
      expect(prefs.values['canvasWidth'], '320');
      // A double tap: back to the normal width, nothing kept.
      await tester.tap(find.byKey(const Key('panel-resizer')));
      await tester.pump(const Duration(milliseconds: 40));
      await tester.tap(find.byKey(const Key('panel-resizer')));
      await tester.pump(const Duration(milliseconds: 400));
      expect(width(tester), closeTo(first, 1));
      expect(prefs.values.containsKey('canvasWidth'), isFalse);
    });

    testWidgets('the arrows on the focused divider widen and narrow it', (tester) async {
      await open(tester);
      final first = width(tester);
      Element el() => tester.element(find.byKey(const Key('panel-resizer')));
      Focus.of(el()).requestFocus();
      await tester.pump();
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowLeft);
      await tester.pump();
      expect(width(tester), first + 24);
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
      await tester.pump();
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
      await tester.pump();
      expect(width(tester), first - 24);
      expect(prefs.values['canvasWidth'], '${(first - 24).round()}');
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pump();
      expect(width(tester), closeTo(first, 1));
      expect(prefs.values.containsKey('canvasWidth'), isFalse);
    });

    testWidgets('a width kept on this device is the next panel\'s', (tester) async {
      await open(tester);
      app.setCanvasWidth(500);
      model = CanvasPanelModel()..show('Note', _file);
      await tester.pumpWidget(
        AppScope(
          controller: app,
          child: MaterialApp(
            localizationsDelegates: const [
              AppLocalizations.delegate,
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            supportedLocales: AppLocalizations.supportedLocales,
            home: Scaffold(
              body: Align(
                alignment: Alignment.centerRight,
                child: CanvasPanel(model: model, maxWidth: 1400),
              ),
            ),
          ),
        ),
      );
      await tester.pump();
      expect(width(tester), 500);
    });
  });
}

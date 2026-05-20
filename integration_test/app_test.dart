import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:nobu_slate/main.dart' as app;
import 'package:nobu_slate/models/slate_colors.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
  });

  // Resolve a Text widget showing the given (trimmed) value inside the
  // BoxWithSwipe identified by `keyName`. FittedValue wraps the text in
  // a leading + trailing space, so we trim before comparing.
  bool boxHasValue(WidgetTester tester, String keyName, String expected) {
    final boxFinder = find.byKey(ValueKey(keyName));
    final texts = find.descendant(of: boxFinder, matching: find.byType(Text));
    return texts
        .evaluate()
        .map((e) => (e.widget as Text).data?.trim())
        .contains(expected);
  }

  // Read the live background color of the slate root Container.
  Color? slateBg(WidgetTester tester) {
    final el = tester.element(find.byKey(const ValueKey('slate-root')));
    final c = (el.widget as Container).color;
    return c;
  }

  testWidgets('renders defaults', (tester) async {
    app.main();
    await tester.pumpAndSettle();

    expect(boxHasValue(tester, 'scene', '1'), true);
    expect(boxHasValue(tester, 'take', '1'), true);
    expect(boxHasValue(tester, 'audioFile', '001'), true);
    final titleTexts = find.descendant(
      of: find.byKey(const ValueKey('title')),
      matching: find.byType(Text),
    );
    expect(
      titleTexts.evaluate().any(
            (e) => (e.widget as Text).data?.trim() == 'Title',
          ),
      true,
    );
    expect(find.textContaining('L: Lav'), findsOneWidget);
    expect(find.textContaining('R: Boom'), findsOneWidget);
  });

  testWidgets('swipe up on Scene increments value', (tester) async {
    app.main();
    await tester.pumpAndSettle();

    await tester.fling(find.byKey(const ValueKey('scene')),
        const Offset(0, -200), 1000);
    await tester.pumpAndSettle();

    expect(boxHasValue(tester, 'scene', '2'), true);
  });

  testWidgets('swipe down on Scene floors at 1', (tester) async {
    app.main();
    await tester.pumpAndSettle();

    // Scene starts at 1; swiping down should keep it at 1.
    await tester.fling(find.byKey(const ValueKey('scene')),
        const Offset(0, 200), 1000);
    await tester.pumpAndSettle();

    expect(boxHasValue(tester, 'scene', '1'), true);
  });

  testWidgets('swipe up on Take multiple times', (tester) async {
    app.main();
    await tester.pumpAndSettle();

    for (var i = 0; i < 3; i++) {
      await tester.fling(find.byKey(const ValueKey('take')),
          const Offset(0, -200), 1000);
      await tester.pumpAndSettle();
    }

    expect(boxHasValue(tester, 'take', '4'), true);
  });

  testWidgets('swipe up on AudioFile preserves digit width', (tester) async {
    app.main();
    await tester.pumpAndSettle();

    await tester.fling(find.byKey(const ValueKey('audioFile')),
        const Offset(0, -200), 1000);
    await tester.pumpAndSettle();

    // 001 → 002 (three-digit padding preserved)
    expect(boxHasValue(tester, 'audioFile', '002'), true);
  });

  testWidgets('horizontal swipe across slate does not crash', (tester) async {
    app.main();
    await tester.pumpAndSettle();

    await tester.fling(find.byKey(const ValueKey('scene')),
        const Offset(300, 0), 1000);
    await tester.pump(const Duration(milliseconds: 100));

    expect(boxHasValue(tester, 'scene', '1'), true,
        reason: 'horizontal swipe should not have changed scene value');

    // Let the 1.5s mark sequence finish before the test tears down.
    await tester.pump(const Duration(milliseconds: 1600));
    await tester.pumpAndSettle();
  });

  testWidgets('tap Scene opens edit screen, submit updates value',
      (tester) async {
    app.main();
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('scene')));
    await tester.pumpAndSettle();

    final field = find.byType(TextField);
    expect(field, findsOneWidget);

    await tester.enterText(field, '42');
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pumpAndSettle();

    expect(find.byType(TextField), findsNothing);
    expect(boxHasValue(tester, 'scene', '42'), true);
  });

  testWidgets('edited value trims whitespace and persists across restart',
      (tester) async {
    app.main();
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('title')));
    await tester.pumpAndSettle();
    await tester.enterText(
        find.byType(TextField), '  Handcuff Hands  ');
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pumpAndSettle();

    final titleTexts = find.descendant(
      of: find.byKey(const ValueKey('title')),
      matching: find.byType(Text),
    );
    expect(
      titleTexts
          .evaluate()
          .any((e) => (e.widget as Text).data?.trim() == 'Handcuff Hands'),
      true,
      reason: 'leading/trailing whitespace should be trimmed',
    );

    // Relaunch from scratch; persisted value should load.
    await tester.pumpWidget(const SizedBox());
    app.main();
    await tester.pumpAndSettle();

    final reloaded = find.descendant(
      of: find.byKey(const ValueKey('title')),
      matching: find.byType(Text),
    );
    expect(
      reloaded
          .evaluate()
          .any((e) => (e.widget as Text).data?.trim() == 'Handcuff Hands'),
      true,
      reason: 'value should persist across app restart',
    );
  });

  // ---- Sharper mark (PR #1 / design/sharper-mark.md) ----

  testWidgets('mark RED flash is brief (~150ms then white)', (tester) async {
    app.main();
    await tester.pumpAndSettle();

    expect(slateBg(tester), SlateColors.markWhite.background,
        reason: 'pre-mark baseline');

    // Fire horizontal swipe → mark.
    await tester.fling(
      find.byKey(const ValueKey('scene')),
      const Offset(300, 0),
      1000,
    );
    // Inside the 150ms flash window.
    await tester.pump(const Duration(milliseconds: 50));
    expect(slateBg(tester), SlateColors.markRed.background,
        reason: 'RED should be showing inside the 150ms flash window');

    // Past the 150ms flash window, before the 1000ms cadence.
    await tester.pump(const Duration(milliseconds: 200)); // total ~250ms
    expect(slateBg(tester), SlateColors.markWhite.background,
        reason: 'should be back to WHITE between RED and GREEN');

    // Wait out the rest of the cadence so the test tears down cleanly.
    await tester.pump(const Duration(milliseconds: 1200));
    await tester.pumpAndSettle();
  });

  testWidgets('mark GREEN flash is brief at ~t=1000ms', (tester) async {
    app.main();
    await tester.pumpAndSettle();

    await tester.fling(
      find.byKey(const ValueKey('scene')),
      const Offset(300, 0),
      1000,
    );
    // Inside the GREEN flash window (1000–1150ms).
    await tester.pump(const Duration(milliseconds: 1050));
    expect(slateBg(tester), SlateColors.markGreen.background,
        reason: 'GREEN should be showing just after t=1000ms');

    // Past the GREEN flash window.
    await tester.pump(const Duration(milliseconds: 200)); // total ~1250ms
    expect(slateBg(tester), SlateColors.markWhite.background,
        reason: 'should be back to WHITE after the GREEN flash');

    await tester.pumpAndSettle();
  });

  testWidgets('re-mark is blocked during cadence', (tester) async {
    app.main();
    await tester.pumpAndSettle();

    // First mark → into cadence.
    await tester.fling(
      find.byKey(const ValueKey('scene')),
      const Offset(300, 0),
      1000,
    );
    // Past the 150ms RED flash, in the white gap before the green.
    await tester.pump(const Duration(milliseconds: 300));
    expect(slateBg(tester), SlateColors.markWhite.background,
        reason: 'baseline: in the white gap between RED and GREEN');

    // Try to fire a second mark; should be ignored because _isMarking=true.
    await tester.fling(
      find.byKey(const ValueKey('scene')),
      const Offset(300, 0),
      1000,
    );
    await tester.pump(const Duration(milliseconds: 20));
    // If the second mark were honored it would have set RED again.
    expect(slateBg(tester), SlateColors.markWhite.background,
        reason: 'second swipe mid-cadence must not restart the sequence');

    // Wait out the full cadence so the test tears down cleanly.
    await tester.pump(const Duration(milliseconds: 1500));
    await tester.pumpAndSettle();
  });
}

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'package:nobu_slate/main.dart' as app;

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

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

    // Mark gesture is wired but visual/audio effect lands in M4. For now,
    // assert the gesture is handled (no exception, app still rendered).
    await tester.fling(find.byKey(const ValueKey('scene')),
        const Offset(300, 0), 1000);
    await tester.pumpAndSettle();

    expect(boxHasValue(tester, 'scene', '1'), true,
        reason: 'horizontal swipe should not have changed scene value');
  });
}

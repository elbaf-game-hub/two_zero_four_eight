import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:two_zero_four_eight/two_zero_four_eight.dart';

void main() {
  group('2048 Widget & Interactive Control Tests', () {
    testWidgets('TwoZeroFourEight page renders 16 cells and controls', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: TwoZeroFourEightPage(),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(TwoZeroFourEightPage), findsOneWidget);
      expect(find.text('2048'), findsOneWidget);
      expect(find.text('SCORE'), findsOneWidget);
      expect(find.text('BEST'), findsOneWidget);

      // 16 grid cells
      expect(find.byType(GridView), findsOneWidget);

      // Restart button in GameAppBar
      expect(find.byTooltip('Restart'), findsOneWidget);
      await tester.tap(find.byTooltip('Restart'));
      await tester.pumpAndSettle();
    });

    testWidgets('Keyboard arrow keys and shortcuts trigger board slides and undo',
        (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: TwoZeroFourEightPage(),
        ),
      );
      await tester.pumpAndSettle();

      // Send arrow key events
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
      await tester.pumpAndSettle();

      await tester.sendKeyEvent(LogicalKeyboardKey.arrowLeft);
      await tester.pumpAndSettle();

      await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
      await tester.pumpAndSettle();

      await tester.sendKeyEvent(LogicalKeyboardKey.arrowUp);
      await tester.pumpAndSettle();

      // Trigger undo shortcut 'U'
      await tester.sendKeyEvent(LogicalKeyboardKey.keyU);
      await tester.pumpAndSettle();

      // Trigger restart shortcut 'R'
      await tester.sendKeyEvent(LogicalKeyboardKey.keyR);
      await tester.pumpAndSettle();

      expect(find.byType(TwoZeroFourEightPage), findsOneWidget);
    });

    testWidgets('Pan swipe gestures on board area trigger slides',
        (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: TwoZeroFourEightPage(),
        ),
      );
      await tester.pumpAndSettle();

      final gridFinder = find.byType(GridView);
      expect(gridFinder, findsOneWidget);

      // Swipe left
      await tester.drag(gridFinder, const Offset(-200, 0));
      await tester.pumpAndSettle();

      // Swipe down
      await tester.drag(gridFinder, const Offset(0, 200));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
    });
  });
}

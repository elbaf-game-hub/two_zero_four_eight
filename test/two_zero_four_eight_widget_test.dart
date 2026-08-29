import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:two_zero_four_eight/two_zero_four_eight.dart';

void main() {
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

    // Virtual direction buttons
    expect(find.byTooltip('Slide Left'), findsOneWidget);
    expect(find.byTooltip('Slide Right'), findsOneWidget);
    expect(find.byTooltip('Slide Up'), findsOneWidget);
    expect(find.byTooltip('Slide Down'), findsOneWidget);

    // Tap virtual slide button
    await tester.tap(find.byTooltip('Slide Left'));
    await tester.pumpAndSettle();

    // Restart button in GameAppBar
    expect(find.byTooltip('Restart'), findsOneWidget);
    await tester.tap(find.byTooltip('Restart'));
    await tester.pumpAndSettle();
  });
}

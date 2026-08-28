# 06 — Tests

Two test files: `test/two_zero_four_eight_state_test.dart` (engine) and
`test/two_zero_four_eight_widget_test.dart` (page).

## Engine tests (state)

> Target: ≥90% line coverage on `lib/src/two_zero_four_eight_state.dart`.

1. Initial board has 2 random tiles, both 2 or one 4
2. slide(left) compresses each row to the left, merging adjacent equal tiles once per slide
3. slide doesn't double-merge in a single pass (e.g. [2,2,4,4] → [4,8,null,null], not [8,4,null,null])
4. slide returns false if no tile moved (used to detect game-over)
5. After every successful slide, spawn() adds one new tile (90% value 2, 10% value 4) in a random empty cell
6. Score += sum of merged values
7. undo() restores the previous board and score, removes from stack
8. undo() is a no-op when stack is empty
9. Win triggered exactly once when 2048 is created; user can choose to continue (won → playing)
10. Lost when no direction produces a movement or a merge
11. Widget test: 4×4 board renders 16 cells, all initially empty except 2

## Widget tests (page)

A minimal smoke test that the page renders and the primary
interaction works:

```dart
// test/two_zero_four_eight_widget_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:two_zero_four_eight/two_zero_four_eight.dart';

void main() {
  testWidgets('TwoZeroFourEight page renders', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: TwoZeroFourEightPage()));
    expect(find.byType(TwoZeroFourEightPage), findsOneWidget);
  });
}
```

## Coverage bar

```bash
cd game_hub_modules/two_zero_four_eight
flutter test --coverage
# open coverage/lcov-report.html
```

Required: lines covered on `lib/src/two_zero_four_eight_state.dart` ≥ 90%.
The CI step in the wrapper fails the build otherwise.

## What NOT to test

- Pure widget rendering details (e.g. "the title is centered").
- SFX firing (you'd have to mock `audioplayers`; not worth it).
- The `GameModule` descriptor — it's a static const.

## How to run a single test

```bash
flutter test test/two_zero_four_eight_state_test.dart --plain-name "tap places"
```

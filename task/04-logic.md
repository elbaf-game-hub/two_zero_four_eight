# 04 — Logic

> The engine lives in `lib/src/two_zero_four_eight_state.dart`. **No imports of
> `package:flutter/*` allowed in this file.** The page imports the
> state, not the other way around.

## Class diagram

```
two_zero_four_eight_state.dart (pure Dart)
  └── classes listed below
two_zero_four_eight_page.dart (Flutter)
  └── owns the State subclass that wraps two_zero_four_eight_state
```

## Classes

### `Direction`

enum { up, down, left, right }

### `TwentyFortyEightStatus`

enum { playing, won, lost }

### `TwentyFortyEightState`

Owns List<List<int?>> board (4x4, null = empty), int score, int bestScore, TwentyFortyEightStatus status, Deque<BoardSnapshot> undoStack (cap 10). Methods: slide(Direction), spawn(), undo(), reset().

### `BoardSnapshot`

Immutable record of (board, score) for undo.

## Hard rules

1. **No `Widget` or `BuildContext` references** in the state file.
   If a UI helper is needed, put it in `*_page.dart`.
2. **No `import 'package:flutter/...'`** in the state file.
   Use only `dart:core`, `dart:math`, `dart:collection`.
3. **Constructor takes everything it needs** — no global state.
   The page passes initial values and listens via `Stream` or
   `Listenable` if needed.
4. **Methods return new state, not mutate** when possible. For
   performance-critical loops (e.g. 2048 slide), in-place mutation
   is OK as long as the previous state is captured for undo.
5. **Seedable RNG** for any shuffle/random. Use `Random(seed)` so
   tests can be deterministic.

## Integration with the page

```dart
class TwoZeroFourEightPage extends StatefulWidget {{
  const TwoZeroFourEightPage({{super.key}});
  @override
  State<TwoZeroFourEightPage> createState() => _TwoZeroFourEightPageState();
}}

class _TwoZeroFourEightPageState extends State<TwoZeroFourEightPage> {{
  late TwoZeroFourEightState _state;

  @override
  void initState() {{
    super.initState();
    _state = TwoZeroFourEightState.initial();
  }}

  void _onAction(...) {{
    setState(() {{
      _state = _state.copyWith(...);
    }});
    SfxPlayer.instance.play('tap');
  }}

  @override
  Widget build(BuildContext context) => /* see 05-ui.md */;
}}
```

# 02 — Assets

All assets come from `package:game_assets`. The module declares a
path-dependency on it in `pubspec.yaml`. The wrapper's `game_assets`
package owns the actual files.

## Source of truth

- **Declarative YAML**: `game_hub_core/game_assets/tool/definitions/two_zero_four_eight.yaml`
- **Procedural Python**: `game_hub_core/game_assets/tool/generate_tiles.py`
- **Regenerate**:
  ```bash
  cd game_hub_core/game_assets
  python3 tool/generate_svgs.py
  python3 tool/generate_tiles.py
  ```

## Core SVG assets

These are the visual primitives the page must reference. The table
maps each to a file under `game_assets/assets/svg/two_zero_four_eight/`.

| File | Size | Purpose |
| --- | --- | --- |
| `tile_2.svg` | 100x100 | Value 2, cream |
| `tile_4.svg` | 100x100 | Value 4, lighter cream |
| `tile_8.svg` | 100x100 | Value 8, orange |
| `tile_16.svg` | 100x100 | Value 16, deeper orange |
| `tile_32.svg` | 100x100 | Value 32, red-orange |
| `tile_64.svg` | 100x100 | Value 64, red |
| `tile_128.svg` | 100x100 | Value 128, gold |
| `tile_256.svg` | 100x100 | Value 256, gold |
| `tile_512.svg` | 100x100 | Value 512, gold |
| `tile_1024.svg` | 100x100 | Value 1024, bright gold |
| `tile_2048.svg` | 100x100 | Value 2048, brightest gold |
| `tile_super.svg` | 100x100 | Fallback for 4096+ |

## Fonts

System default (digits rendered in SVG).

## How the page loads an asset

```dart
import 'package:flutter_svg/flutter_svg.dart';

SvgPicture.asset(
  'assets/svg/two_zero_four_eight/<file>.svg',
  package: 'game_assets',
  width: 48,
)
```

## Asset budget

- **Hard cap**: total `assets/` in this module ≤ 200 KB
  (CI step in `game_hub_wrapper/.github/workflows/ci.yml`).
- This module's known usage: see sizes in the table above.

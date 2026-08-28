# 2048

> Sprint 3 · Game Hub module

Combine matching tiles to reach 2048.

**Rules**: https://en.wikipedia.org/wiki/2048_(video_game)

> **Status**: this task spec is the contract. Update the spec,
> not the code, when scope changes. The implementation in
> `lib/src/` should be a faithful translation of the docs here.

## At a glance

| | |
| --- | --- |
| Module id | `two_zero_four_eight` |
| Game name | 2048 |
| Tagline | Combine matching tiles to reach 2048. |
| Sprint | 3 |
| Estimated effort | see `PLAN.md` |
| States | playing, won, lost |
| Persistence keys | best_score, continued |

## What you implement

1. **`lib/src/two_zero_four_eight_state.dart`** — pure-Dart game engine. No
   `BuildContext`, no `Widget`. ≥90% unit-tested.
2. **`lib/src/two_zero_four_eight_page.dart`** — the Flutter page. Imports state,
   `game_assets`, `flutter_svg`, and `audioplayers`.
3. **`lib/src/two_zero_four_eight_module.dart`** — the `GameModule` descriptor.
   Already exists in the stub; no edits needed.
4. **`test/two_zero_four_eight_state_test.dart`** — unit tests on the engine.
5. **`test/two_zero_four_eight_widget_test.dart`** — smoke test that the page
   renders and basic interactions work.

## Read order

Implement in this order; each file is independent enough to be
written in one sitting:

1. `04-logic.md` — design the state classes, then write the engine
2. `02-assets.md` + `03-sound.md` — confirm assets/SFX exist
3. `05-ui.md` — build the page
4. `06-tests.md` — write tests against the engine
5. `01-gameplay.md` — re-read for any UX detail missed
6. `07-publish.md` — final checklist

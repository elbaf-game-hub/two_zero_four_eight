# 01 — Gameplay

## Rules summary

Combine matching tiles to reach 2048.

> Full rules: https://en.wikipedia.org/wiki/2048_(video_game)

## Controls

Swipe up/down/left/right (or arrow keys) to slide all tiles. Tap a tile to undo (single-step).

## Screen flow

1. Game (board + score + best + new game)
2. Win toast at 2048 (option to continue)
3. Game-over dialog with score, best, 'Try again'

## Difficulty

Single difficulty. Win target is 2048; user can keep playing past it.

## Scoring

Sum of merged values (e.g. merging two 64s scores +128). Persist 'best_score'.

## State machine

The game moves through these states: **playing, won, lost**.

```
      ┌──────────────┐
      │   playing    │
      └──┬───┬───┬───┘
         │   │   │
         │   │   └──► won
         │   └──────► lost
```

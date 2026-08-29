import 'dart:math';
import 'package:flutter_test/flutter_test.dart';
import 'package:two_zero_four_eight/src/two_zero_four_eight_state.dart';

void main() {
  group('TwentyFortyEightState Engine Tests', () {
    test('Initial board has exactly 2 spawned tiles (2 or 4) on a 4x4 grid', () {
      final state = TwentyFortyEightState.initial(bestScore: 500);

      expect(state.score, equals(0));
      expect(state.bestScore, equals(500));
      expect(state.status, equals(TwentyFortyEightStatus.playing));
      expect(state.hasWon, isFalse);
      expect(state.continued, isFalse);
      expect(state.undoStack, isEmpty);

      var nonNullCount = 0;
      for (var r = 0; r < 4; r++) {
        for (var c = 0; c < 4; c++) {
          final val = state.board[r][c];
          if (val != null) {
            nonNullCount++;
            expect(val == 2 || val == 4, isTrue);
          }
        }
      }
      expect(nonNullCount, equals(2));
    });

    test('Random spawn distribution approximates 90% 2s and 10% 4s over 1000 spawns', () {
      final rng = Random(42);
      var twos = 0;
      var fours = 0;

      for (var i = 0; i < 1000; i++) {
        final state = TwentyFortyEightState.initial(random: rng);
        for (final row in state.board) {
          for (final cell in row) {
            if (cell == 2) twos++;
            if (cell == 4) fours++;
          }
        }
      }

      final total = twos + fours;
      expect(total, equals(2000));
      final ratioTwo = twos / total;
      expect(ratioTwo, greaterThan(0.85));
      expect(ratioTwo, lessThan(0.95));
    });

    test('slide left compresses and merges row without double-merging in single pass', () {
      // Row with [2, 2, 4, 4] -> should become [4, 8, null, null]
      final initialBoard = [
        [2, 2, 4, 4],
        [2, 2, 2, 2],
        [null, 2, null, 2],
        [4, 2, 2, null],
      ];

      final state = TwentyFortyEightState.fromBoard(board: initialBoard);
      final nextState = state.slide(Direction.left, random: Random(1));

      // Row 0: [2,2,4,4] -> [4, 8, null, null] (merged 2+2=4, 4+4=8, total score +12)
      // Row 1: [2,2,2,2] -> [4, 4, null, null] (merged 2+2=4, 2+2=4, total score +8)
      // Row 2: [null, 2, null, 2] -> [4, null, null, null] (+4)
      // Row 3: [4, 2, 2, null] -> [4, 4, null, null] (+4)
      // Plus exactly 1 newly spawned tile somewhere in the empty cells.

      expect(nextState.board[0][0], equals(4));
      expect(nextState.board[0][1], equals(8));
      expect(nextState.board[1][0], equals(4));
      expect(nextState.board[1][1], equals(4));
      expect(nextState.board[2][0], equals(4));
      expect(nextState.board[3][0], equals(4));
      expect(nextState.board[3][1], equals(4));

      expect(nextState.score, equals(12 + 8 + 4 + 4));
      expect(nextState.lastMoveMerged, isTrue);
      expect(nextState.undoStack.length, equals(1));
    });

    test('slide right compresses and merges correctly', () {
      final initialBoard = [
        [2, 2, 4, 4],
        [null, null, 2, 2],
        [2, 4, 2, 4],
        [null, null, null, null],
      ];

      final state = TwentyFortyEightState.fromBoard(board: initialBoard);
      final nextState = state.slide(Direction.right, random: Random(2));

      // Row 0: [2, 2, 4, 4] sliding right -> [null, null, 4, 8] (+12)
      // Row 1: [null, null, 2, 2] -> [null, null, null, 4] (+4)
      // Row 2: [2, 4, 2, 4] -> unchanged except aligned right -> [2, 4, 2, 4] (0)
      expect(nextState.board[0][2], equals(4));
      expect(nextState.board[0][3], equals(8));
      expect(nextState.board[1][3], equals(4));
      expect(nextState.board[2][0], equals(2));
      expect(nextState.board[2][1], equals(4));
      expect(nextState.board[2][2], equals(2));
      expect(nextState.board[2][3], equals(4));
      expect(nextState.score, equals(16));
    });

    test('slide up compresses and merges columns', () {
      final initialBoard = [
        [2, null, 4, 2],
        [2, null, 4, 2],
        [4, 2, null, 4],
        [4, 2, null, 4],
      ];

      final state = TwentyFortyEightState.fromBoard(board: initialBoard);
      final nextState = state.slide(Direction.up, random: Random(3));

      // Col 0: [2, 2, 4, 4] -> [4, 8, null, null] (+12)
      // Col 1: [null, null, 2, 2] -> [4, null, null, null] (+4)
      // Col 2: [4, 4, null, null] -> [8, null, null, null] (+8)
      // Col 3: [2, 2, 4, 4] -> [4, 8, null, null] (+12)
      expect(nextState.board[0][0], equals(4));
      expect(nextState.board[1][0], equals(8));
      expect(nextState.board[0][1], equals(4));
      expect(nextState.board[0][2], equals(8));
      expect(nextState.board[0][3], equals(4));
      expect(nextState.board[1][3], equals(8));
      expect(nextState.score, equals(36));
    });

    test('slide down compresses and merges columns downwards', () {
      final initialBoard = [
        [2, 2, null, 4],
        [2, 2, null, 4],
        [4, 4, null, 2],
        [4, 4, null, 2],
      ];

      final state = TwentyFortyEightState.fromBoard(board: initialBoard);
      final nextState = state.slide(Direction.down, random: Random(4));

      // Col 0: [2, 2, 4, 4] down -> [null, null, 4, 8] (+12)
      // Col 1: [2, 2, 4, 4] down -> [null, null, 4, 8] (+12)
      // Col 3: [4, 4, 2, 2] down -> [null, null, 8, 4] (+12)
      expect(nextState.board[2][0], equals(4));
      expect(nextState.board[3][0], equals(8));
      expect(nextState.board[2][1], equals(4));
      expect(nextState.board[3][1], equals(8));
      expect(nextState.board[2][3], equals(8));
      expect(nextState.board[3][3], equals(4));
      expect(nextState.score, equals(36));
    });

    test('slide is no-op when no tile can move or merge in that direction', () {
      final initialBoard = [
        [2, 4, 2, 4],
        [4, 2, 4, 2],
        [2, 4, 2, 4],
        [4, 2, 4, 2],
      ];

      final state = TwentyFortyEightState.fromBoard(board: initialBoard);
      expect(state.canMoveInDirection(Direction.left), isFalse);
      expect(state.canMoveInDirection(Direction.right), isFalse);
      expect(state.canMoveInDirection(Direction.up), isFalse);
      expect(state.canMoveInDirection(Direction.down), isFalse);
      expect(state.canMove(), isFalse);

      final nextState = state.slide(Direction.left);
      expect(nextState.board, equals(initialBoard));
      expect(nextState.undoStack, isEmpty);
      expect(nextState.score, equals(0));
    });

    test('undo stack records up to 10 moves and restores state properly', () {
      var state = TwentyFortyEightState.fromBoard(
        board: [
          [2, null, null, null],
          [null, null, null, null],
          [null, null, null, null],
          [null, null, null, null],
        ],
        score: 0,
      );

      final initialCopy = state.board.map((r) => List<int?>.from(r)).toList();

      // Perform 12 valid moves (cycling right and left)
      for (var i = 0; i < 12; i++) {
        final dir = i.isEven ? Direction.right : Direction.left;
        state = state.slide(dir, random: Random(i));
      }

      expect(state.undoStack.length, equals(10));

      // Perform 10 undos
      for (var i = 0; i < 10; i++) {
        expect(state.undoStack.isNotEmpty, isTrue);
        state = state.undo();
      }

      expect(state.undoStack, isEmpty);

      // 11th undo is a no-op on empty stack
      final noOpState = state.undo();
      expect(noOpState, equals(state));
    });

    test('Win condition triggers on reaching 2048 and keepGoing allows continuation', () {
      final winBoard = [
        [1024, 1024, null, null],
        [null, null, null, null],
        [null, null, null, null],
        [null, null, null, null],
      ];

      final state = TwentyFortyEightState.fromBoard(board: winBoard);
      expect(state.status, equals(TwentyFortyEightStatus.playing));
      expect(state.hasWon, isFalse);

      final wonState = state.slide(Direction.left, random: Random(10));
      expect(wonState.board[0][0], equals(2048));
      expect(wonState.status, equals(TwentyFortyEightStatus.won));
      expect(wonState.hasWon, isTrue);
      expect(wonState.lastMoveWon, isTrue);

      // Keep going allows playing further
      final continuedState = wonState.keepGoing();
      expect(continuedState.status, equals(TwentyFortyEightStatus.playing));
      expect(continuedState.continued, isTrue);

      // Additional merges do not trigger won status again
      final nextState = continuedState.slide(Direction.right, random: Random(11));
      expect(nextState.status, equals(TwentyFortyEightStatus.playing));
      expect(nextState.lastMoveWon, isFalse);
    });

    test('Game over detection when board is completely full and no moves exist', () {
      final fullBoard = [
        [2, 4, 2, 4],
        [4, 2, 4, 2],
        [2, 4, 2, 4],
        [4, 2, 4, null], // 1 empty spot
      ];

      final state = TwentyFortyEightState.fromBoard(board: fullBoard);
      expect(state.canMove(), isTrue);

      // Slide right will compress the last row and spawn into the last empty spot
      // Make sure the spawned tile creates no merges
      final lostState = state.slide(Direction.right, random: Random(999));
      expect(lostState.status, equals(TwentyFortyEightStatus.lost));
      expect(lostState.canMove(), isFalse);

      // Sliding while lost is a no-op
      final afterLostSlide = lostState.slide(Direction.up);
      expect(afterLostSlide, equals(lostState));
    });

    test('reset creates fresh game with clean score and preserved bestScore', () {
      final state = TwentyFortyEightState.fromBoard(
        board: [
          [2, 4, 8, 16],
          [32, 64, 128, 256],
          [null, null, null, null],
          [null, null, null, null],
        ],
        score: 1000,
        bestScore: 2500,
        status: TwentyFortyEightStatus.playing,
        undoStack: [BoardSnapshot(board: [], score: 0)],
      );

      final resetState = state.reset(random: Random(5));
      expect(resetState.score, equals(0));
      expect(resetState.bestScore, equals(2500));
      expect(resetState.undoStack, isEmpty);
      expect(resetState.status, equals(TwentyFortyEightStatus.playing));
    });

    test('BoardSnapshot equality, clone, hashCode, and toString', () {
      final board1 = [
        [2, 4],
        [8, 16],
      ];
      final snap1 = BoardSnapshot(board: board1, score: 100);
      final snap2 = snap1.clone();
      final snap3 = BoardSnapshot(board: board1, score: 200);

      expect(snap1, equals(snap2));
      expect(snap1.hashCode, equals(snap2.hashCode));
      expect(snap1 == snap3, isFalse);
      expect(snap1.toString(), contains('score: 100'));
    });

    test('TwentyFortyEightState equality, hashCode, toString, and copyWith', () {
      final state1 = TwentyFortyEightState.initial(bestScore: 100);
      final state2 = state1.copyWith(score: 50);

      expect(state2.score, equals(50));
      expect(state2.bestScore, equals(100));
      expect(state1 == state2, isFalse);
      expect(state1.toString(), contains('TwentyFortyEightState'));
    });
  });
}

import 'dart:math';

/// Slide directions for the 2048 game grid.
enum Direction { up, down, left, right }

/// Game status states for 2048.
enum TwentyFortyEightStatus { playing, won, lost }

/// Immutable snapshot of a board configuration and score for the undo stack.
class BoardSnapshot {
  final List<List<int?>> board;
  final int score;

  const BoardSnapshot({required this.board, required this.score});

  /// Deep clones this snapshot.
  BoardSnapshot clone() => BoardSnapshot(
        board: board.map((row) => List<int?>.from(row)).toList(),
        score: score,
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is BoardSnapshot &&
          score == other.score &&
          _boardEquals(board, other.board);

  @override
  int get hashCode => Object.hash(score, _hashBoard(board));

  @override
  String toString() => 'BoardSnapshot(score: $score, board: $board)';
}

/// Pure Dart state engine for 2048.
class TwentyFortyEightState {
  static const int size = 4;
  static const int winTarget = 2048;
  static const int maxUndoHistory = 10;

  final List<List<int?>> board;
  final int score;
  final int bestScore;
  final TwentyFortyEightStatus status;
  final bool hasWon;
  final bool continued;
  final List<BoardSnapshot> undoStack;
  final bool lastMoveMerged;
  final bool lastMoveWon;

  const TwentyFortyEightState({
    required this.board,
    required this.score,
    required this.bestScore,
    required this.status,
    required this.hasWon,
    required this.continued,
    required this.undoStack,
    this.lastMoveMerged = false,
    this.lastMoveWon = false,
  });

  /// Factory creating an initial game state with 2 spawned tiles.
  factory TwentyFortyEightState.initial({
    int bestScore = 0,
    Random? random,
  }) {
    final rng = random ?? Random();
    final emptyBoard = List.generate(
      size,
      (_) => List<int?>.filled(size, null),
    );

    _spawnRandomTile(emptyBoard, rng);
    _spawnRandomTile(emptyBoard, rng);

    return TwentyFortyEightState(
      board: emptyBoard,
      score: 0,
      bestScore: bestScore,
      status: TwentyFortyEightStatus.playing,
      hasWon: false,
      continued: false,
      undoStack: const [],
      lastMoveMerged: false,
      lastMoveWon: false,
    );
  }

  /// Factory creating custom state for deterministic testing or recovery.
  factory TwentyFortyEightState.fromBoard({
    required List<List<int?>> board,
    int score = 0,
    int bestScore = 0,
    TwentyFortyEightStatus status = TwentyFortyEightStatus.playing,
    bool hasWon = false,
    bool continued = false,
    List<BoardSnapshot> undoStack = const [],
    bool lastMoveMerged = false,
    bool lastMoveWon = false,
  }) {
    return TwentyFortyEightState(
      board: board.map((row) => List<int?>.from(row)).toList(),
      score: score,
      bestScore: bestScore,
      status: status,
      hasWon: hasWon,
      continued: continued,
      undoStack: List<BoardSnapshot>.from(undoStack),
      lastMoveMerged: lastMoveMerged,
      lastMoveWon: lastMoveWon,
    );
  }

  /// Returns true if any legal moves remain in any of the 4 directions.
  bool canMove() => _canMoveOnBoard(board);

  /// Returns true if sliding in [direction] causes tiles to move or merge.
  bool canMoveInDirection(Direction direction) {
    final (newBoard, _, moved) = _slideBoard(board, direction);
    return moved || !_boardEquals(board, newBoard);
  }

  /// Slides all tiles in [direction].
  ///
  /// - Merges equal adjacent tiles in single pass without double-merging.
  /// - Accumulates merged value into score.
  /// - Pushes previous board to undo stack (capped at 10).
  /// - Spawns 1 new tile (90% chance 2, 10% chance 4).
  /// - Detects win (first 2048) and game over (no moves left).
  TwentyFortyEightState slide(Direction direction, {Random? random}) {
    if (status == TwentyFortyEightStatus.lost) {
      return this;
    }

    final (newBoard, scoreGained, didMove) = _slideBoard(board, direction);

    if (!didMove) {
      return copyWith(lastMoveMerged: false, lastMoveWon: false);
    }

    // Save snapshot before mutating for undo
    final currentSnapshot = BoardSnapshot(
      board: _cloneBoard(board),
      score: score,
    );
    final updatedUndoStack = List<BoardSnapshot>.from(undoStack)
      ..add(currentSnapshot);
    if (updatedUndoStack.length > maxUndoHistory) {
      updatedUndoStack.removeRange(
        0,
        updatedUndoStack.length - maxUndoHistory,
      );
    }

    // Spawn 1 new tile in an empty cell
    final rng = random ?? Random();
    _spawnRandomTile(newBoard, rng);

    final newScore = score + scoreGained;
    final newBestScore = max(bestScore, newScore);

    // Win condition check
    var newHasWon = hasWon;
    var newStatus = status;
    var didWinNow = false;

    if (!hasWon && _hasTileValue(newBoard, winTarget)) {
      newHasWon = true;
      newStatus = TwentyFortyEightStatus.won;
      didWinNow = true;
    } else if (status == TwentyFortyEightStatus.won && continued) {
      newStatus = TwentyFortyEightStatus.playing;
    }

    // Game over check
    if (!_canMoveOnBoard(newBoard)) {
      if (newStatus != TwentyFortyEightStatus.won || continued) {
        newStatus = TwentyFortyEightStatus.lost;
      }
    }

    return TwentyFortyEightState(
      board: newBoard,
      score: newScore,
      bestScore: newBestScore,
      status: newStatus,
      hasWon: newHasWon,
      continued: continued,
      undoStack: updatedUndoStack,
      lastMoveMerged: scoreGained > 0,
      lastMoveWon: didWinNow,
    );
  }

  /// Restores the previous board and score from the undo stack.
  TwentyFortyEightState undo() {
    if (undoStack.isEmpty) return this;

    final popped = undoStack.last;
    final remainingUndoStack =
        undoStack.sublist(0, undoStack.length - 1);

    return TwentyFortyEightState(
      board: popped.clone().board,
      score: popped.score,
      bestScore: bestScore,
      status: TwentyFortyEightStatus.playing,
      hasWon: hasWon,
      continued: continued,
      undoStack: remainingUndoStack,
      lastMoveMerged: false,
      lastMoveWon: false,
    );
  }

  /// Allows the player to keep playing past 2048.
  TwentyFortyEightState keepGoing() {
    if (status != TwentyFortyEightStatus.won) return this;
    final nextStatus = _canMoveOnBoard(board)
        ? TwentyFortyEightStatus.playing
        : TwentyFortyEightStatus.lost;
    return copyWith(
      status: nextStatus,
      continued: true,
      lastMoveMerged: false,
      lastMoveWon: false,
    );
  }

  /// Resets the game to initial state, keeping bestScore.
  TwentyFortyEightState reset({Random? random}) {
    return TwentyFortyEightState.initial(
      bestScore: bestScore,
      random: random,
    );
  }

  /// Creates a copy of this state with specified fields replaced.
  TwentyFortyEightState copyWith({
    List<List<int?>>? board,
    int? score,
    int? bestScore,
    TwentyFortyEightStatus? status,
    bool? hasWon,
    bool? continued,
    List<BoardSnapshot>? undoStack,
    bool? lastMoveMerged,
    bool? lastMoveWon,
  }) {
    return TwentyFortyEightState(
      board: board ?? _cloneBoard(this.board),
      score: score ?? this.score,
      bestScore: bestScore ?? this.bestScore,
      status: status ?? this.status,
      hasWon: hasWon ?? this.hasWon,
      continued: continued ?? this.continued,
      undoStack: undoStack ?? List<BoardSnapshot>.from(this.undoStack),
      lastMoveMerged: lastMoveMerged ?? this.lastMoveMerged,
      lastMoveWon: lastMoveWon ?? this.lastMoveWon,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TwentyFortyEightState &&
          score == other.score &&
          bestScore == other.bestScore &&
          status == other.status &&
          hasWon == other.hasWon &&
          continued == other.continued &&
          _boardEquals(board, other.board);

  @override
  int get hashCode => Object.hash(
        score,
        bestScore,
        status,
        hasWon,
        continued,
        _hashBoard(board),
      );

  @override
  String toString() =>
      'TwentyFortyEightState(score: $score, status: $status, board: $board)';
}

/// Clones a 4x4 board.
List<List<int?>> _cloneBoard(List<List<int?>> b) =>
    b.map((row) => List<int?>.from(row)).toList();

/// Compares two 4x4 boards for equality.
bool _boardEquals(List<List<int?>> a, List<List<int?>> b) {
  if (a.length != b.length) return false;
  for (var r = 0; r < a.length; r++) {
    if (a[r].length != b[r].length) return false;
    for (var c = 0; c < a[r].length; c++) {
      if (a[r][c] != b[r][c]) return false;
    }
  }
  return true;
}

/// Generates hash code for 4x4 board.
int _hashBoard(List<List<int?>> b) {
  final values = <int?>[];
  for (final row in b) {
    values.addAll(row);
  }
  return Object.hashAll(values);
}

/// Spawns a new tile in a random empty cell (90% chance 2, 10% chance 4).
bool _spawnRandomTile(List<List<int?>> board, Random random) {
  final emptyCells = <(int, int)>[];
  for (var r = 0; r < TwentyFortyEightState.size; r++) {
    for (var c = 0; c < TwentyFortyEightState.size; c++) {
      if (board[r][c] == null) {
        emptyCells.add((r, c));
      }
    }
  }

  if (emptyCells.isEmpty) return false;

  final (row, col) = emptyCells[random.nextInt(emptyCells.length)];
  final value = (random.nextDouble() < 0.9) ? 2 : 4;
  board[row][col] = value;
  return true;
}

/// Checks if any cell on the board matches [targetValue].
bool _hasTileValue(List<List<int?>> board, int targetValue) {
  for (var r = 0; r < TwentyFortyEightState.size; r++) {
    for (var c = 0; c < TwentyFortyEightState.size; c++) {
      if (board[r][c] == targetValue) {
        return true;
      }
    }
  }
  return false;
}

/// Checks if any slide/merge is possible on the given board.
bool _canMoveOnBoard(List<List<int?>> board) {
  for (var r = 0; r < TwentyFortyEightState.size; r++) {
    for (var c = 0; c < TwentyFortyEightState.size; c++) {
      if (board[r][c] == null) return true;

      // Check right neighbor
      if (c + 1 < TwentyFortyEightState.size &&
          board[r][c] == board[r][c + 1]) {
        return true;
      }

      // Check down neighbor
      if (r + 1 < TwentyFortyEightState.size &&
          board[r][c] == board[r + 1][c]) {
        return true;
      }
    }
  }
  return false;
}

/// Slides and merges a single 1D line of length 4 towards the front (index 0).
(List<int?>, int, bool) _slideLine(List<int?> line) {
  final nonNulls = line.whereType<int>().toList();
  final merged = <int>[];
  var scoreGained = 0;
  var i = 0;

  while (i < nonNulls.length) {
    if (i + 1 < nonNulls.length && nonNulls[i] == nonNulls[i + 1]) {
      final combined = nonNulls[i] * 2;
      merged.add(combined);
      scoreGained += combined;
      i += 2; // Advance 2 to prevent double-merge in single slide
    } else {
      merged.add(nonNulls[i]);
      i += 1;
    }
  }

  final result = List<int?>.filled(TwentyFortyEightState.size, null);
  for (var k = 0; k < merged.length; k++) {
    result[k] = merged[k];
  }

  var changed = false;
  for (var k = 0; k < TwentyFortyEightState.size; k++) {
    if (result[k] != line[k]) {
      changed = true;
      break;
    }
  }

  return (result, scoreGained, changed);
}

/// Executes slide transformation on the entire board for the given [direction].
(List<List<int?>>, int, bool) _slideBoard(
  List<List<int?>> board,
  Direction direction,
) {
  final newBoard = List.generate(
    TwentyFortyEightState.size,
    (_) => List<int?>.filled(TwentyFortyEightState.size, null),
  );
  var totalScoreGained = 0;
  var anyChanged = false;

  switch (direction) {
    case Direction.left:
      for (var r = 0; r < TwentyFortyEightState.size; r++) {
        final (newLine, scoreGained, changed) = _slideLine(board[r]);
        newBoard[r] = newLine;
        totalScoreGained += scoreGained;
        if (changed) anyChanged = true;
      }
      break;

    case Direction.right:
      for (var r = 0; r < TwentyFortyEightState.size; r++) {
        final reversedLine = board[r].reversed.toList();
        final (slidLine, scoreGained, changed) = _slideLine(reversedLine);
        newBoard[r] = slidLine.reversed.toList();
        totalScoreGained += scoreGained;
        if (changed) anyChanged = true;
      }
      break;

    case Direction.up:
      for (var c = 0; c < TwentyFortyEightState.size; c++) {
        final colLine = [
          board[0][c],
          board[1][c],
          board[2][c],
          board[3][c],
        ];
        final (slidLine, scoreGained, changed) = _slideLine(colLine);
        for (var r = 0; r < TwentyFortyEightState.size; r++) {
          newBoard[r][c] = slidLine[r];
        }
        totalScoreGained += scoreGained;
        if (changed) anyChanged = true;
      }
      break;

    case Direction.down:
      for (var c = 0; c < TwentyFortyEightState.size; c++) {
        final colLine = [
          board[3][c],
          board[2][c],
          board[1][c],
          board[0][c],
        ];
        final (slidLine, scoreGained, changed) = _slideLine(colLine);
        final reversedCol = slidLine.reversed.toList();
        for (var r = 0; r < TwentyFortyEightState.size; r++) {
          newBoard[r][c] = reversedCol[r];
        }
        totalScoreGained += scoreGained;
        if (changed) anyChanged = true;
      }
      break;
  }

  return (newBoard, totalScoreGained, anyChanged);
}

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:game_assets/game_assets.dart';

import 'two_zero_four_eight_state.dart';

/// Flutter UI page for 2048.
class TwoZeroFourEightPage extends StatefulWidget {
  const TwoZeroFourEightPage({super.key});

  @override
  State<TwoZeroFourEightPage> createState() => _TwoZeroFourEightPageState();
}

class _TwoZeroFourEightPageState extends State<TwoZeroFourEightPage> {
  late TwentyFortyEightState _state;
  final FocusNode _focusNode = FocusNode();
  Offset? _dragStart;

  @override
  void initState() {
    super.initState();
    _state = TwentyFortyEightState.initial();
  }

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  void _handleSlide(Direction direction) {
    if (_state.status == TwentyFortyEightStatus.lost) return;

    final nextState = _state.slide(direction);
    if (nextState == _state && !nextState.lastMoveWon && !nextState.lastMoveMerged) {
      return;
    }

    setState(() {
      _state = nextState;
    });

    if (_state.lastMoveWon) {
      SfxPlayer.instance.play('win');
    } else if (_state.lastMoveMerged) {
      SfxPlayer.instance.play('merge');
    }
  }

  void _handleUndo() {
    if (_state.undoStack.isEmpty) return;
    setState(() {
      _state = _state.undo();
    });
    SfxPlayer.instance.play('tap');
  }

  void _handleRestart() {
    setState(() {
      _state = _state.reset();
    });
    SfxPlayer.instance.play('tap');
  }

  void _handleKeepGoing() {
    setState(() {
      _state = _state.keepGoing();
    });
  }

  void _onPanStart(DragStartDetails details) {
    _dragStart = details.localPosition;
  }

  void _onPanEnd(DragEndDetails details) {
    if (_dragStart == null) return;
    final velocity = details.velocity.pixelsPerSecond;
    final dx = velocity.dx;
    final dy = velocity.dy;

    if (dx.abs() > dy.abs() && dx.abs() > 80) {
      if (dx > 0) {
        _handleSlide(Direction.right);
      } else {
        _handleSlide(Direction.left);
      }
    } else if (dy.abs() > dx.abs() && dy.abs() > 80) {
      if (dy > 0) {
        _handleSlide(Direction.down);
      } else {
        _handleSlide(Direction.up);
      }
    }
    _dragStart = null;
  }

  KeyEventResult _handleKeyEvent(FocusNode node, KeyEvent event) {
    if (event is! KeyDownEvent) return KeyEventResult.ignored;

    final key = event.logicalKey;
    if (key == LogicalKeyboardKey.arrowUp || key == LogicalKeyboardKey.keyW) {
      _handleSlide(Direction.up);
      return KeyEventResult.handled;
    } else if (key == LogicalKeyboardKey.arrowDown ||
        key == LogicalKeyboardKey.keyS) {
      _handleSlide(Direction.down);
      return KeyEventResult.handled;
    } else if (key == LogicalKeyboardKey.arrowLeft ||
        key == LogicalKeyboardKey.keyA) {
      _handleSlide(Direction.left);
      return KeyEventResult.handled;
    } else if (key == LogicalKeyboardKey.arrowRight ||
        key == LogicalKeyboardKey.keyD) {
      _handleSlide(Direction.right);
      return KeyEventResult.handled;
    } else if (key == LogicalKeyboardKey.keyU) {
      _handleUndo();
      return KeyEventResult.handled;
    } else if (key == LogicalKeyboardKey.keyR) {
      _handleRestart();
      return KeyEventResult.handled;
    }

    return KeyEventResult.ignored;
  }

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: buildGameTheme(Brightness.light),
      child: Focus(
        focusNode: _focusNode,
        autofocus: true,
        onKeyEvent: _handleKeyEvent,
        child: Scaffold(
          appBar: GameAppBar(
            title: '2048',
            score: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _ScorePill(label: 'SCORE', value: _state.score),
                const SizedBox(width: GameTokens.xs),
                _ScorePill(label: 'BEST', value: _state.bestScore),
              ],
            ),
            onRestart: _handleRestart,
            onSettings: () => _showSettingsSheet(context),
          ),
          body: SafeArea(
            child: Column(
              children: [
                const SizedBox(height: GameTokens.sm),
                // Action Bar (Undo & Controls helper)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: GameTokens.md),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Join numbers to reach 2048!',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Colors.black54,
                              fontWeight: FontWeight.w500,
                            ),
                      ),
                      ElevatedButton.icon(
                        onPressed:
                            _state.undoStack.isNotEmpty ? _handleUndo : null,
                        icon: const Icon(Icons.undo, size: 18),
                        label: Text('Undo (${_state.undoStack.length})'),
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                            horizontal: GameTokens.sm,
                            vertical: GameTokens.xs,
                          ),
                          textStyle: const TextStyle(fontSize: 12),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: GameTokens.sm),
                // Main Board
                Expanded(
                  child: Center(
                    child: GestureDetector(
                      onPanStart: _onPanStart,
                      onPanEnd: _onPanEnd,
                      behavior: HitTestBehavior.opaque,
                      child: GameBoardArea(
                        aspectRatio: 1.0,
                        maxSide: 460,
                        background: GameTokens.boardDark,
                        padding: const EdgeInsets.all(GameTokens.sm),
                        borderRadius: GameTokens.radiusLg,
                        child: Stack(
                          children: [
                            // 4x4 Grid
                            GridView.builder(
                              physics: const NeverScrollableScrollPhysics(),
                              gridDelegate:
                                  const SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 4,
                                mainAxisSpacing: GameTokens.sm,
                                crossAxisSpacing: GameTokens.sm,
                              ),
                              itemCount: 16,
                              itemBuilder: (context, index) {
                                final row = index ~/ 4;
                                final col = index % 4;
                                final val = _state.board[row][col];
                                return _buildTileCell(val);
                              },
                            ),
                            // Win Overlay
                            if (_state.status == TwentyFortyEightStatus.won &&
                                !_state.continued)
                              _buildWinOverlay(context),
                            // Loss Overlay
                            if (_state.status == TwentyFortyEightStatus.lost)
                              _buildGameOverOverlay(context),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                // Virtual Directional Swipe Buttons for accessibility / touch
                Padding(
                  padding: const EdgeInsets.all(GameTokens.sm),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      IconButton.filledTonal(
                        icon: const Icon(Icons.arrow_back),
                        tooltip: 'Slide Left',
                        onPressed: () => _handleSlide(Direction.left),
                      ),
                      const SizedBox(width: GameTokens.xs),
                      Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton.filledTonal(
                            icon: const Icon(Icons.arrow_upward),
                            tooltip: 'Slide Up',
                            onPressed: () => _handleSlide(Direction.up),
                          ),
                          const SizedBox(height: GameTokens.xs),
                          IconButton.filledTonal(
                            icon: const Icon(Icons.arrow_downward),
                            tooltip: 'Slide Down',
                            onPressed: () => _handleSlide(Direction.down),
                          ),
                        ],
                      ),
                      const SizedBox(width: GameTokens.xs),
                      IconButton.filledTonal(
                        icon: const Icon(Icons.arrow_forward),
                        tooltip: 'Slide Right',
                        onPressed: () => _handleSlide(Direction.right),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTileCell(int? value) {
    if (value == null) {
      return Container(
        decoration: BoxDecoration(
          color: GameTokens.board,
          borderRadius: BorderRadius.circular(GameTokens.radiusMd),
        ),
      );
    }

    final assetName = value <= 2048 ? 'tile_$value' : 'tile_super';

    return Container(
      decoration: BoxDecoration(
        color: _getFallbackColor(value),
        borderRadius: BorderRadius.circular(GameTokens.radiusMd),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(GameTokens.radiusMd),
        child: Stack(
          fit: StackFit.expand,
          children: [
            SvgPicture.asset(
              'assets/svg/two_zero_four_eight/$assetName.svg',
              package: 'game_assets',
              fit: BoxFit.contain,
            ),
            Center(
              child: Text(
                '$value',
                style: TextStyle(
                  fontSize: value > 512 ? 20 : 26,
                  fontWeight: FontWeight.w900,
                  color: value <= 4 ? const Color(0xFF776E65) : Colors.white,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _getFallbackColor(int val) {
    switch (val) {
      case 2:
        return GameTokens.tile2;
      case 4:
        return GameTokens.tile4;
      case 8:
        return GameTokens.tile8;
      case 16:
        return GameTokens.tile16;
      case 32:
        return GameTokens.tile32;
      case 64:
        return GameTokens.tile64;
      case 128:
        return GameTokens.tile128;
      case 256:
        return GameTokens.tile256;
      case 512:
        return GameTokens.tile512;
      case 1024:
        return GameTokens.tile1024;
      case 2048:
        return GameTokens.tile2048;
      default:
        return const Color(0xFF3C3A32);
    }
  }

  Widget _buildWinOverlay(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.amber.withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(GameTokens.radiusLg),
      ),
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(GameTokens.md),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                '2048 Reached!',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: GameTokens.sm),
              const Text(
                'Congratulations! You created the 2048 tile!',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 14, color: Colors.white),
              ),
              const SizedBox(height: GameTokens.md),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ElevatedButton(
                    onPressed: _handleKeepGoing,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: Colors.amber.shade900,
                    ),
                    child: const Text('Keep Going'),
                  ),
                  const SizedBox(width: GameTokens.sm),
                  OutlinedButton(
                    onPressed: _handleRestart,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.white,
                      side: const BorderSide(color: Colors.white),
                    ),
                    child: const Text('New Game'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildGameOverOverlay(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.82),
        borderRadius: BorderRadius.circular(GameTokens.radiusLg),
      ),
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(GameTokens.md),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Game Over!',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: GameTokens.sm),
              Text(
                'Final Score: ${_state.score}',
                style: const TextStyle(fontSize: 18, color: Colors.white70),
              ),
              const SizedBox(height: GameTokens.md),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (_state.undoStack.isNotEmpty) ...[
                    OutlinedButton(
                      onPressed: _handleUndo,
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.white,
                        side: const BorderSide(color: Colors.white),
                      ),
                      child: const Text('Undo Move'),
                    ),
                    const SizedBox(width: GameTokens.sm),
                  ],
                  ElevatedButton(
                    onPressed: _handleRestart,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: GameTokens.primary,
                      foregroundColor: Colors.white,
                    ),
                    child: const Text('Try Again'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showSettingsSheet(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            return SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(GameTokens.md),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Game Settings',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const Divider(),
                    SwitchListTile(
                      title: const Text('Mute Sound Effects'),
                      value: SfxPlayer.instance.isMuted,
                      onChanged: (val) {
                        setSheetState(() {
                          SfxPlayer.instance.setMuted(val);
                        });
                        setState(() {});
                      },
                    ),
                    ListTile(
                      leading: const Icon(Icons.refresh),
                      title: const Text('Reset High Score'),
                      onTap: () {
                        setState(() {
                          _state = _state.copyWith(bestScore: 0);
                        });
                        Navigator.of(context).pop();
                      },
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}

class _ScorePill extends StatelessWidget {
  final String label;
  final int value;

  const _ScorePill({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: GameTokens.sm,
        vertical: GameTokens.xs,
      ),
      decoration: BoxDecoration(
        color: GameTokens.boardDark,
        borderRadius: BorderRadius.circular(GameTokens.radiusSm),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.bold,
              color: Colors.black54,
            ),
          ),
          Text(
            '$value',
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w800,
              color: Colors.black87,
            ),
          ),
        ],
      ),
    );
  }
}

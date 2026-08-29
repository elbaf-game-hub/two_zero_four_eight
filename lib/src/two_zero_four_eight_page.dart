import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Theme(
      data: buildGameTheme(Theme.of(context).brightness),
      child: Focus(
        focusNode: _focusNode,
        autofocus: true,
        onKeyEvent: _handleKeyEvent,
        child: Scaffold(
          backgroundColor: isDark ? const Color(0xFF0B1120) : const Color(0xFFF1F5F9),
          appBar: GameAppBar(
            title: '2048',
            score: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _ScorePill(label: 'SCORE', value: _state.score, color: GameTokens.primary),
                const SizedBox(width: 8),
                _ScorePill(label: 'BEST', value: _state.bestScore, color: GameTokens.warning),
              ],
            ),
            onRestart: _handleRestart,
            onSettings: () => _showSettingsSheet(context),
          ),
          body: SafeArea(
            child: Column(
              children: [
                const SizedBox(height: 8),
                // Action Bar (Undo & Controls helper)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Swipe to merge numbers',
                        style: TextStyle(
                          color: Colors.white60,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      FilledButton.tonalIcon(
                        onPressed:
                            _state.undoStack.isNotEmpty ? _handleUndo : null,
                        icon: const Icon(Icons.undo_rounded, size: 16),
                        label: Text('Undo (${_state.undoStack.length})'),
                        style: FilledButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          textStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                // Main Board
                Expanded(
                  child: Center(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      child: GestureDetector(
                        onPanStart: _onPanStart,
                        onPanEnd: _onPanEnd,
                        behavior: HitTestBehavior.opaque,
                        child: Container(
                          constraints: const BoxConstraints(maxWidth: 420),
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: const Color(0xFF030712),
                            borderRadius: BorderRadius.circular(GameTokens.radiusLg),
                            border: Border.all(
                              color: const Color(0xFF1E293B),
                              width: 2,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.5),
                                blurRadius: 24,
                                offset: const Offset(0, 10),
                              ),
                            ],
                          ),
                          child: AspectRatio(
                            aspectRatio: 1.0,
                            child: Stack(
                              children: [
                                // 4x4 Grid
                                GridView.builder(
                                  physics: const NeverScrollableScrollPhysics(),
                                  gridDelegate:
                                      const SliverGridDelegateWithFixedCrossAxisCount(
                                    crossAxisCount: 4,
                                    mainAxisSpacing: 8,
                                    crossAxisSpacing: 8,
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
                  ),
                ),
                const SizedBox(height: 16),
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
          color: const Color(0xFF0F172A),
          borderRadius: BorderRadius.circular(GameTokens.radiusMd),
          border: Border.all(color: const Color(0xFF1E293B), width: 1),
        ),
      );
    }

    final colors = _getGradientColors(value);
    final color1 = colors.$1;
    final color2 = colors.$2;
    final fontSize = value > 512 ? 18.0 : (value > 64 ? 22.0 : 26.0);

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [color1, color2],
        ),
        borderRadius: BorderRadius.circular(GameTokens.radiusMd),
        border: Border.all(color: Colors.white.withValues(alpha: 0.2), width: 1),
        boxShadow: [
          BoxShadow(
            color: color2.withValues(alpha: 0.4),
            blurRadius: 6,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Center(
        child: Text(
          '$value',
          style: TextStyle(
            fontSize: fontSize,
            fontWeight: FontWeight.w900,
            color: Colors.white,
            shadows: const [
              Shadow(
                color: Colors.black38,
                offset: Offset(0, 1),
                blurRadius: 3,
              ),
            ],
          ),
        ),
      ),
    );
  }

  (Color, Color) _getGradientColors(int val) {
    switch (val) {
      case 2:
        return (const Color(0xFF64748B), const Color(0xFF475569));
      case 4:
        return (const Color(0xFF0EA5E9), const Color(0xFF0284C7));
      case 8:
        return (const Color(0xFFF97316), const Color(0xFFEA580C));
      case 16:
        return (const Color(0xFFFB923C), const Color(0xFFC2410C));
      case 32:
        return (const Color(0xFFF43F5E), const Color(0xFFE11D48));
      case 64:
        return (const Color(0xFFEF4444), const Color(0xFFDC2626));
      case 128:
        return (const Color(0xFFFBBF24), const Color(0xFFD97706));
      case 256:
        return (const Color(0xFFF59E0B), const Color(0xFFB45309));
      case 512:
        return (const Color(0xFF10B981), const Color(0xFF059669));
      case 1024:
        return (const Color(0xFF06B6D4), const Color(0xFF0891B2));
      case 2048:
        return (const Color(0xFFA855F7), const Color(0xFF7C3AED));
      default:
        return (const Color(0xFFEC4899), const Color(0xFFBE185D));
    }
  }

  Widget _buildWinOverlay(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF0F172A).withValues(alpha: 0.92),
        borderRadius: BorderRadius.circular(GameTokens.radiusLg),
        border: Border.all(color: Colors.amber, width: 2),
      ),
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(GameTokens.md),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.emoji_events_rounded, color: Colors.amber, size: 48),
              const SizedBox(height: 8),
              const Text(
                '2048 Reached!',
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.w900,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Congratulations! You created the 2048 tile!',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 14, color: Colors.white70),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  FilledButton(
                    onPressed: _handleKeepGoing,
                    style: FilledButton.styleFrom(
                      backgroundColor: Colors.amber.shade600,
                      foregroundColor: Colors.white,
                    ),
                    child: const Text('Keep Going'),
                  ),
                  const SizedBox(width: 8),
                  OutlinedButton(
                    onPressed: _handleRestart,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.white,
                      side: const BorderSide(color: Colors.white60),
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
        color: const Color(0xFF030712).withValues(alpha: 0.92),
        borderRadius: BorderRadius.circular(GameTokens.radiusLg),
        border: Border.all(color: GameTokens.danger, width: 2),
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
                  fontWeight: FontWeight.w900,
                  color: GameTokens.danger,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Final Score: ${_state.score}',
                style: const TextStyle(fontSize: 18, color: Colors.white70, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (_state.undoStack.isNotEmpty) ...[
                    OutlinedButton(
                      onPressed: _handleUndo,
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.white,
                        side: const BorderSide(color: Colors.white60),
                      ),
                      child: const Text('Undo Move'),
                    ),
                    const SizedBox(width: 8),
                  ],
                  FilledButton(
                    onPressed: _handleRestart,
                    style: FilledButton.styleFrom(
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
  final Color color;

  const _ScorePill({required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(GameTokens.radiusSm),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(width: 4),
          Text(
            '$value',
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w900,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}

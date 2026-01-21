/// Debug tools widget for procedural level generation.
///
/// Provides UI for generating, solving, and tracing levels.
/// Only shown in debug builds.
library;

import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import '../game/procedural/procedural.dart';

/// Debug panel for procedural generation testing.
class DebugToolsWidget extends StatefulWidget {
  final void Function(GeneratedLevel level)? onLevelGenerated;
  final void Function(Solution solution)? onSolved;
  final void Function(List<SolutionMove> moves)? onAnimateSolution;
  final void Function(bool enabled)? onToggleRays;
  final void Function(Hint hint)? onHintRequested;
  final GameState Function()? getCurrentState;
  final GeneratedLevel? currentLevel;

  const DebugToolsWidget({
    super.key,
    this.onLevelGenerated,
    this.onSolved,
    this.onAnimateSolution,
    this.onToggleRays,
    this.onHintRequested,
    this.getCurrentState,
    this.currentLevel,
  });

  @override
  State<DebugToolsWidget> createState() => _DebugToolsWidgetState();
}

class _DebugToolsWidgetState extends State<DebugToolsWidget> {
  int _selectedEpisode = 1;
  int _seedInput = 12345;
  bool _showRays = true;
  bool _isGenerating = false;
  bool _isSolving = false;
  bool _isHinting = false;

  // Results
  GeneratedLevel? _lastGeneratedLevel;
  Solution? _lastSolution;
  Hint? _lastHint;
  String _statusMessage = '';
  Duration _lastOperationTime = Duration.zero;

  final _levelGenerator = LevelGenerator();
  final _solver = Solver();
  final _hintEngine = HintEngine();

  @override
  Widget build(BuildContext context) {
    // Only show in debug mode
    if (!kDebugMode) {
      return const SizedBox.shrink();
    }

    return Container(
      margin: const EdgeInsets.all(8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.black87,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.purple.shade400, width: 2),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Icon(Icons.bug_report, color: Colors.purple.shade300, size: 20),
              const SizedBox(width: 8),
              Text(
                'Debug Tools',
                style: TextStyle(
                  color: Colors.purple.shade300,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ],
          ),
          const Divider(color: Colors.purple, height: 16),

          // Episode Selector
          Row(
            children: [
              const Text('Episode:', style: TextStyle(color: Colors.white70, fontSize: 12)),
              const SizedBox(width: 8),
              ...List.generate(5, (i) => _episodeButton(i + 1)),
            ],
          ),
          const SizedBox(height: 8),

          // Seed Input
          Row(
            children: [
              const Text('Seed:', style: TextStyle(color: Colors.white70, fontSize: 12)),
              const SizedBox(width: 8),
              SizedBox(
                width: 80,
                height: 28,
                child: TextField(
                  controller: TextEditingController(text: _seedInput.toString()),
                  keyboardType: TextInputType.number,
                  style: const TextStyle(color: Colors.white, fontSize: 12),
                  decoration: InputDecoration(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(4),
                      borderSide: BorderSide(color: Colors.purple.shade400),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(4),
                      borderSide: BorderSide(color: Colors.purple.shade400),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(4),
                      borderSide: BorderSide(color: Colors.purple.shade200),
                    ),
                  ),
                  onChanged: (v) => _seedInput = int.tryParse(v) ?? _seedInput,
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                icon: const Icon(Icons.shuffle, size: 18, color: Colors.white70),
                onPressed: () {
                  setState(() {
                    _seedInput = DateTime.now().millisecondsSinceEpoch % 100000;
                  });
                },
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Action Buttons Row 1
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _actionButton(
                'Generate',
                Icons.create,
                _isGenerating ? null : _generateLevel,
                _isGenerating,
              ),
              _actionButton(
                'Solve',
                Icons.lightbulb,
                _isSolving ? null : _solveLevel,
                _isSolving,
              ),
              _actionButton(
                'Animate',
                Icons.play_arrow,
                _lastSolution != null ? _animateSolution : null,
                false,
              ),
              _actionButton(
                _showRays ? 'Rays ON' : 'Rays OFF',
                Icons.visibility,
                _toggleRays,
                false,
                highlight: _showRays,
              ),
            ],
          ),
          const SizedBox(height: 8),

          // Hint Buttons Row
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _actionButton(
                'Light Hint',
                Icons.lightbulb_outline,
                _isHinting ? null : () => _testHint(HintType.light),
                _isHinting,
                color: Colors.cyan.shade800,
              ),
              _actionButton(
                'Medium Hint',
                Icons.tips_and_updates,
                _isHinting ? null : () => _testHint(HintType.medium),
                _isHinting,
                color: Colors.cyan.shade700,
              ),
              _actionButton(
                'Full Hint',
                Icons.auto_fix_high,
                _isHinting ? null : () => _testHint(HintType.full),
                _isHinting,
                color: Colors.cyan.shade600,
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Status Display
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.black54,
              borderRadius: BorderRadius.circular(4),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (_lastGeneratedLevel != null) ...[
                  _statusRow('Level', 'E${_lastGeneratedLevel!.episode}L${_lastGeneratedLevel!.index}'),
                  _statusRow('Seed', '${_lastGeneratedLevel!.seed}'),
                  _statusRow('Optimal', '${_lastGeneratedLevel!.meta.optimalMoves} moves'),
                  _statusRow('Difficulty', _lastGeneratedLevel!.meta.difficultyBand.name),
                ],
                if (_lastSolution != null) ...[
                  const Divider(color: Colors.white24, height: 8),
                  _statusRow('Solvable', _lastSolution!.solvable ? 'YES ✓' : 'NO ✗'),
                  if (_lastSolution!.solvable)
                    _statusRow('Solution', '${_lastSolution!.optimalMoves} moves'),
                  _statusRow('States', '${_lastSolution!.statesExplored}'),
                  _statusRow('Time', '${_lastOperationTime.inMilliseconds}ms'),
                ],
                if (_lastHint != null) ...[
                  const Divider(color: Colors.white24, height: 8),
                  _statusRow('Hint', _lastHint!.available ? '${_lastHint!.type.name}' : 'N/A'),
                  if (_lastHint!.available) ...[
                    _statusRow('Moves', '${_lastHint!.moves.length}'),
                    _statusRow('Fallback', _lastHint!.isFallback ? 'YES' : 'NO'),
                  ],
                  _statusRow('Hint Time', '${_lastHint!.solveTimeMs}ms'),
                  _statusRow('States', '${_lastHint!.statesExplored}'),
                ],
                if (_statusMessage.isNotEmpty) ...[
                  const Divider(color: Colors.white24, height: 8),
                  Text(
                    _statusMessage,
                    style: TextStyle(
                      color: _statusMessage.contains('Error') ? Colors.red.shade300 : Colors.green.shade300,
                      fontSize: 11,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _episodeButton(int episode) {
    final isSelected = _selectedEpisode == episode;
    return Padding(
      padding: const EdgeInsets.only(right: 4),
      child: InkWell(
        onTap: () => setState(() => _selectedEpisode = episode),
        child: Container(
          width: 24,
          height: 24,
          decoration: BoxDecoration(
            color: isSelected ? Colors.purple.shade600 : Colors.transparent,
            borderRadius: BorderRadius.circular(4),
            border: Border.all(
              color: isSelected ? Colors.purple.shade400 : Colors.white30,
            ),
          ),
          child: Center(
            child: Text(
              '$episode',
              style: TextStyle(
                color: isSelected ? Colors.white : Colors.white70,
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _actionButton(
    String label,
    IconData icon,
    VoidCallback? onPressed,
    bool isLoading, {
    bool highlight = false,
    Color? color,
  }) {
    return ElevatedButton.icon(
      onPressed: onPressed,
      icon: isLoading
          ? const SizedBox(
              width: 14,
              height: 14,
              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
            )
          : Icon(icon, size: 14),
      label: Text(label, style: const TextStyle(fontSize: 11)),
      style: ElevatedButton.styleFrom(
        backgroundColor: color ?? (highlight ? Colors.purple.shade700 : Colors.purple.shade900),
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        minimumSize: const Size(0, 28),
      ),
    );
  }

  Widget _statusRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 1),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '$label: ',
            style: const TextStyle(color: Colors.white54, fontSize: 11),
          ),
          Text(
            value,
            style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }

  void _generateLevel() async {
    setState(() {
      _isGenerating = true;
      _statusMessage = 'Generating...';
    });

    final stopwatch = Stopwatch()..start();

    try {
      final level = _levelGenerator.generate(_selectedEpisode, 1, _seedInput);
      stopwatch.stop();

      if (level != null) {
        setState(() {
          _lastGeneratedLevel = level;
          _lastSolution = null;
          _lastOperationTime = stopwatch.elapsed;
          _statusMessage = 'Generated in ${stopwatch.elapsedMilliseconds}ms';
        });

        widget.onLevelGenerated?.call(level);

        // Log details
        debugPrint('=== LEVEL GENERATED ===');
        debugPrint('Episode: ${level.episode}, Index: ${level.index}');
        debugPrint('Seed: ${level.seed}');
        debugPrint('Optimal moves: ${level.meta.optimalMoves}');
        debugPrint('Difficulty: ${level.meta.difficultyBand.name}');
        debugPrint('Mirrors: ${level.mirrors.length} (${level.mirrors.where((m) => m.rotatable).length} rotatable)');
        debugPrint('Prisms: ${level.prisms.length}');
        debugPrint('Targets: ${level.targets.length}');
        debugPrint('Walls: ${level.walls.length}');
        debugPrint('Gen time: ${level.meta.solveTime.inMilliseconds}ms');
        debugPrint('Attempts: ${level.meta.generationAttempts}');
      } else {
        setState(() {
          _statusMessage = 'Error: Generation failed';
        });
        debugPrint('Level generation failed for seed $_seedInput');
      }
    } catch (e) {
      setState(() {
        _statusMessage = 'Error: $e';
      });
      debugPrint('Generation error: $e');
    } finally {
      setState(() => _isGenerating = false);
    }
  }

  void _solveLevel() async {
    final level = _lastGeneratedLevel ?? widget.currentLevel;
    if (level == null) {
      setState(() => _statusMessage = 'No level to solve');
      return;
    }

    setState(() {
      _isSolving = true;
      _statusMessage = 'Solving...';
    });

    final stopwatch = Stopwatch()..start();

    try {
      // Get current state if available, otherwise use initial
      final state = widget.getCurrentState?.call() ?? GameState.fromLevel(level);
      final solution = _solver.solve(level, state);
      stopwatch.stop();

      setState(() {
        _lastSolution = solution;
        _lastOperationTime = stopwatch.elapsed;
        _statusMessage = solution.solvable
            ? 'Solved in ${stopwatch.elapsedMilliseconds}ms'
            : 'No solution found';
      });

      widget.onSolved?.call(solution);

      // Log details
      debugPrint('=== SOLVE RESULT ===');
      debugPrint('Solvable: ${solution.solvable}');
      debugPrint('Optimal moves: ${solution.optimalMoves}');
      debugPrint('States explored: ${solution.statesExplored}');
      debugPrint('Time: ${stopwatch.elapsedMilliseconds}ms');
      if (solution.solvable) {
        debugPrint('Solution: ${solution.moves.map((m) => '${m.type.name}[${m.objectIndex}]').join(', ')}');
      }
    } catch (e) {
      setState(() {
        _statusMessage = 'Error: $e';
      });
      debugPrint('Solve error: $e');
    } finally {
      setState(() => _isSolving = false);
    }
  }

  void _animateSolution() {
    final solution = _lastSolution;
    if (solution == null || !solution.solvable || solution.moves.isEmpty) {
      setState(() => _statusMessage = 'No solution to animate');
      return;
    }

    widget.onAnimateSolution?.call(solution.moves);
    setState(() => _statusMessage = 'Animating ${solution.moves.length} moves...');
  }

  void _toggleRays() {
    setState(() => _showRays = !_showRays);
    widget.onToggleRays?.call(_showRays);
  }

  void _testHint(HintType type) async {
    final level = _lastGeneratedLevel ?? widget.currentLevel;
    if (level == null) {
      setState(() => _statusMessage = 'No level for hint');
      return;
    }

    setState(() {
      _isHinting = true;
      _statusMessage = 'Getting ${type.name} hint...';
    });

    try {
      // Get current state if available, otherwise use initial
      final state = widget.getCurrentState?.call() ?? GameState.fromLevel(level);
      
      final hint = _hintEngine.getHint(level, state, type);

      setState(() {
        _lastHint = hint;
        _statusMessage = hint.available
            ? 'Hint: ${hint.moves.length} moves (${hint.isFallback ? "fallback" : "optimal"})'
            : 'Hint unavailable: ${hint.errorMessage}';
      });

      widget.onHintRequested?.call(hint);

      // Detailed logging
      debugPrint('=== HINT TEST RESULT ===');
      debugPrint('Type: ${type.name}');
      debugPrint('Available: ${hint.available}');
      debugPrint('Fallback: ${hint.isFallback}');
      debugPrint('Moves: ${hint.moves.length}');
      debugPrint('Raw moves: ${hint.rawMoves.length}');
      debugPrint('Solve time: ${hint.solveTimeMs}ms');
      debugPrint('States explored: ${hint.statesExplored}');
      if (hint.available) {
        debugPrint('First move: ${hint.highlightObjectType?.name}[${hint.highlightObjectIndex}]');
        debugPrint('Consolidated: ${hint.moves.map((m) => "${m.type.name}[${m.objectIndex}]x${m.tapsRequired}").join(", ")}');
      }
      if (hint.errorMessage != null) {
        debugPrint('Error/Note: ${hint.errorMessage}');
      }
    } catch (e) {
      setState(() {
        _statusMessage = 'Hint error: $e';
      });
      debugPrint('Hint error: $e');
    } finally {
      setState(() => _isHinting = false);
    }
  }
}

/// Overlay for displaying debug tools on top of the game.
class DebugToolsOverlay extends StatelessWidget {
  final Widget child;
  final DebugToolsWidget debugTools;

  const DebugToolsOverlay({
    super.key,
    required this.child,
    required this.debugTools,
  });

  @override
  Widget build(BuildContext context) {
    if (!kDebugMode) {
      return child;
    }

    return Stack(
      children: [
        child,
        Positioned(
          right: 8,
          top: 50,
          child: debugTools,
        ),
      ],
    );
  }
}


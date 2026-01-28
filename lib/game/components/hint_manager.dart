import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'dart:math';
import 'dart:ui';
import 'dart:typed_data';
import '../prismaze_game.dart';
import 'beam_system.dart';
import 'mirror.dart';
import 'prism.dart';
import '../procedural/models/models.dart' as proc;
import '../procedural/hint_engine.dart' as proc;
import '../procedural/ray_tracer_adapter.dart' as proc;

/// Manages hints for both legacy and procedural/campaign modes.
///
/// In campaign/procedural mode, uses HintEngine with current state solving.
/// In legacy mode, uses old solution-based hint behavior.
class HintManager extends Component with HasGameRef<PrismazeGame> {
  
  // Legacy hint support
  List<dynamic> _solutionSteps = [];
  Map<int, PositionComponent> _objectMap = {};
  
  // Procedural hint support
  final proc.HintEngine _hintEngine = proc.HintEngine();
  proc.HintSession? _activeSession;
  proc.GeneratedLevel? _currentLevel;
  
  // Hint State
  Component? _activeHintEffect;
  bool get isShowingHint => _activeHintEffect != null || _activeSession != null;
  
  // Mode flag
  bool useProceduralHints = false;
  
  // Animation state
  bool _isAnimating = false;
  double _animationTimer = 0;
  static const double _animationStepDelay = 0.5; // seconds between steps
  VoidCallback? _onAnimationComplete;
  
  /// Set the current procedural level.
  void setLevel(proc.GeneratedLevel level) {
    _currentLevel = level;
    useProceduralHints = true;
    clearHint();
  }
  
  /// Load legacy solution (for non-procedural levels).
  void loadSolution(List<dynamic> solution, Map<int, PositionComponent> objects) {
    _solutionSteps = solution;
    _objectMap = objects;
    useProceduralHints = false;
    clearHint();
  }
  
  /// Clear any active hint display.
  void clearHint() {
    if (_activeHintEffect != null) {
      _activeHintEffect!.removeFromParent();
      _activeHintEffect = null;
    }
    
    // CRITICAL FIX: Ensure external beam segments are cleared when hint is cleared
    final beamSystem = gameRef.world.children.whereType<BeamSystem>().firstOrNull;
    beamSystem?.clearExternalSegments();
    
    _activeSession = null;
    _isAnimating = false;
    _onAnimationComplete = null;
  }
  
  /// Show a light hint - highlights the next object to change.
  void showLightHint({VoidCallback? onComplete}) {
    if (!_checkAndSpendHints(1)) return;
    
    if (useProceduralHints) {
      _showProceduralHint(proc.HintType.light, onComplete: onComplete);
    } else {
      _findLegacyHint();
    }
  }
  
  /// Show a medium hint - shows next 3 moves with animation.
  void showMediumHint({VoidCallback? onComplete}) {
    if (!_checkAndSpendHints(2)) return;
    
    if (useProceduralHints) {
      _showProceduralHint(proc.HintType.medium, animate: true, onComplete: onComplete);
    } else {
      _findLegacyHint();
    }
  }
  
  /// Show full hint - shows complete solution with animation.
  void showFullHint({VoidCallback? onComplete}) {
    if (!_checkAndSpendHints(3)) return;
    
    if (useProceduralHints) {
      _showProceduralHint(proc.HintType.full, animate: true, onComplete: onComplete);
    } else {
      _findLegacyHint();
    }
  }
  
  /// Check hint balance and spend if sufficient.
  bool _checkAndSpendHints(int cost) {
    final unlimited = gameRef.economyManager.hasUnlimitedHints();
    
    if (!unlimited) {
      if (gameRef.economyManager.hints < cost) {
        debugPrint("Not enough hints for hint (need $cost, have ${gameRef.economyManager.hints})");
        // Could trigger "Out of Hints" UI here
        return false;
      }
      gameRef.economyManager.spendHints(cost);
    } else {
      debugPrint("Using Unlimited Hint!");
    }
    
    return true;
  }
  
  /// Show procedural hint using HintEngine.
  void _showProceduralHint(
    proc.HintType type, {
    bool animate = false,
    VoidCallback? onComplete,
  }) {
    final level = _currentLevel;
    if (level == null) {
      debugPrint("No level set for procedural hints");
      return;
    }
    
    // Get current state from game
    final currentState = _getCurrentGameState(level);
    if (currentState == null) {
      debugPrint("Could not determine current game state");
      return;
    }
    
    // Get hint from engine
    final hint = _hintEngine.getHint(level, currentState, type);
    
    // Log hint result
    if (kDebugMode) {
      debugPrint('=== HINT RESULT ===');
      debugPrint('Type: ${type.name}');
      debugPrint('Available: ${hint.available}');
      debugPrint('Fallback: ${hint.isFallback}');
      debugPrint('Moves: ${hint.moves.length}');
      debugPrint('Solve time: ${hint.solveTimeMs}ms');
      debugPrint('States explored: ${hint.statesExplored}');
      if (hint.errorMessage != null) {
        debugPrint('Error: ${hint.errorMessage}');
      }
    }
    
    if (!hint.available) {
      debugPrint("Hint not available: ${hint.errorMessage}");
      return;
    }
    
    if (animate && hint.rawMoves.isNotEmpty) {
      // Start animation session
      _activeSession = proc.HintSession(
        level: level!,
        originalState: currentState,
        hint: hint,
      );
      _startAnimation(onComplete);
    } else {
      // Just highlight object
      _highlightObject(hint);
      onComplete?.call();
    }
  }
  
  /// Get current game state from game components.
  proc.GameState? _getCurrentGameState(proc.GeneratedLevel level) {
    try {
      final mirrors = gameRef.world.children.whereType<Mirror>().toList();
      final prisms = gameRef.world.children.whereType<Prism>().toList();
      
      // Build state from current orientations
      final mirrorOrientations = <int>[];
      final prismOrientations = <int>[];
      
      for (int i = 0; i < level.mirrors.length && i < mirrors.length; i++) {
        mirrorOrientations.add(mirrors[i].discreteOrientation);
      }
      
      for (int i = 0; i < level.prisms.length && i < prisms.length; i++) {
        prismOrientations.add(prisms[i].discreteOrientation);
      }
      
      return proc.GameState(
        mirrorOrientations: Uint8List.fromList(mirrorOrientations),
        prismOrientations: Uint8List.fromList(prismOrientations),
        targetCollected: Uint8List(level.targets.length), // Hints start from fresh collection state
      );
    } catch (e) {
      debugPrint("Error getting current game state: $e");
      return null;
    }
  }
  
  /// Highlight an object based on hint.
  void _highlightObject(proc.Hint hint) {
    final objectIndex = hint.highlightObjectIndex;
    final objectType = hint.highlightObjectType;
    
    if (objectIndex == null || objectType == null) return;
    
    PositionComponent? target;
    
    switch (objectType) {
      case proc.MoveType.rotateMirror:
        final mirrors = gameRef.world.children.whereType<Mirror>().toList();
        if (objectIndex < mirrors.length) {
          target = mirrors[objectIndex];
        }
        break;
      case proc.MoveType.rotatePrism:
        final prisms = gameRef.world.children.whereType<Prism>().toList();
        if (objectIndex < prisms.length) {
          target = prisms[objectIndex];
        }
        break;
    }
    
    if (target != null) {
      _addHighlightEffect(target, objectType);
    }
  }
  
  /// Add visual highlight effect to a component.
  void _addHighlightEffect(PositionComponent target, proc.MoveType type) {
    // Remove existing effect
    clearHint();
    
    // Add pulsing highlight
    final effect = HintHighlightEffect(target: target, moveType: type);
    gameRef.world.add(effect);
    _activeHintEffect = effect;
  }
  
  /// Start hint animation.
  void _startAnimation(VoidCallback? onComplete) {
    _isAnimating = true;
    _animationTimer = 0;
    _onAnimationComplete = onComplete;
    
    // Show first highlight immediately
    final highlight = _activeSession?.getCurrentHighlight();
    if (highlight != null) {
      _highlightAnimationStep(highlight.$1, highlight.$2);
    }
  }
  
  /// Update animation (called from update loop).
  @override
  void update(double dt) {
    super.update(dt);
    
    if (!_isAnimating || _activeSession == null) return;
    
    _animationTimer += dt;
    
    if (_animationTimer >= _animationStepDelay) {
      _animationTimer = 0;
      
      final step = _activeSession!.playNextMove();
      
      if (step != null) {
        // Update visual state for this step
        _applyAnimationStep(step);
        
        // Update rays via BeamSystem
        _updateRaysForAnimation(step);
        
        // Highlight next object if not complete
        if (!step.isLastStep) {
          final nextHighlight = _activeSession!.getCurrentHighlight();
          if (nextHighlight != null) {
            _highlightAnimationStep(nextHighlight.$1, nextHighlight.$2);
          }
        }
      }
      
      if (_activeSession!.isComplete) {
        _finishAnimation();
      }
    }
  }
  
  /// Highlight object during animation step.
  void _highlightAnimationStep(proc.MoveType type, int objectIndex) {
    PositionComponent? target;
    
    switch (type) {
      case proc.MoveType.rotateMirror:
        final mirrors = gameRef.world.children.whereType<Mirror>().toList();
        if (objectIndex < mirrors.length) {
          target = mirrors[objectIndex];
        }
        break;
      case proc.MoveType.rotatePrism:
        final prisms = gameRef.world.children.whereType<Prism>().toList();
        if (objectIndex < prisms.length) {
          target = prisms[objectIndex];
        }
        break;
    }
    
    if (target != null) {
      _addHighlightEffect(target, type);
    }
  }
  
  /// Apply animation step visually (shadow state, doesn't affect undo).
  void _applyAnimationStep(proc.HintAnimationStep step) {
    // Note: We're animating on a shadow state. The actual game components
    // are NOT modified. This is just for visual feedback.
    // In a full implementation, you'd show the rotation animation
    // on the component without actually changing its state.
    
    debugPrint('Animation step ${step.stepIndex + 1}: ${step.move.type.name}[${step.move.objectIndex}]');
  }
  
  /// Update ray visualization during animation.
  void _updateRaysForAnimation(proc.HintAnimationStep step) {
    // Use the RayTracerAdapter with correct board offset (matches LevelLoader)
    final adapter = proc.RayTracerAdapter(
      boardOffset: Vector2(35.0, 112.5),
    );
    final segments = adapter.convertToPixelSegments(step.traceResult);
    
    // Update BeamSystem with new segments
    final beamSystem = gameRef.world.children.whereType<BeamSystem>().firstOrNull;
    if (beamSystem != null) {
      beamSystem.setExternalSegments(segments);
    }
  }
  
  /// Finish animation and restore state.
  void _finishAnimation() {
    _isAnimating = false;
    clearHint();
    
    // Restore original ray state
    final beamSystem = gameRef.world.children.whereType<BeamSystem>().firstOrNull;
    beamSystem?.clearExternalSegments();
    gameRef.requestBeamUpdate();
    
    _onAnimationComplete?.call();
    _onAnimationComplete = null;
    _activeSession = null;
    
    debugPrint('Hint animation complete');
  }
  
  /// Legacy hint behavior for non-procedural levels.
  void _findLegacyHint() {
    debugPrint("Showing Legacy Hint Visuals...");
    // Legacy logic: compare current state vs solution state
    // and highlight the first divergent object.
  }
}

/// Visual effect for highlighting an object during hints.
class HintHighlightEffect extends PositionComponent with HasGameRef<PrismazeGame> {
  final PositionComponent target;
  final proc.MoveType moveType;
  double _time = 0;
  
  HintHighlightEffect({required this.target, required this.moveType});
  
  @override
  void update(double dt) {
    super.update(dt);
    _time += dt;
    
    // Follow target
    position = target.position;
    size = target.size * 1.5;
    anchor = Anchor.center;
    
    // Auto-remove after 3 seconds
    if (_time > 3.0) {
      removeFromParent();
    }
  }
  
  @override
  void render(Canvas canvas) {
    final pulseScale = 1.0 + 0.1 * sin(_time * 4);
    final alpha = (0.5 + 0.3 * sin(_time * 3)).clamp(0.0, 1.0);
    
    final color = moveType == proc.MoveType.rotateMirror
        ? Colors.cyan.withOpacity(alpha)
        : Colors.purple.withOpacity(alpha);
    
    // Outer glow ring
    canvas.drawCircle(
      Offset(size.x / 2, size.y / 2),
      size.x * 0.4 * pulseScale,
      Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = 4
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8),
    );
    
    // Inner ring
    canvas.drawCircle(
      Offset(size.x / 2, size.y / 2),
      size.x * 0.35 * pulseScale,
      Paint()
        ..color = color.withOpacity(alpha * 0.5)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );
  }
}


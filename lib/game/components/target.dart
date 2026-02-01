import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import 'dart:math';
import '../utils/physics_utils.dart';
import '../utils/color_blindness_utils.dart';
import '../audio_manager.dart';
import '../prismaze_game.dart'; // For settings access
import '../procedural/models/models.dart'; // For LightColor and ColorMixer

class TargetParticle {
  Vector2 position;
  Vector2 velocity;
  Color color;
  double life;
  double size;

  TargetParticle({
    required this.position,
    required this.velocity,
    required this.color,
    this.life = 1.0,
    this.size = 4.0,
  });
}

class Target extends PositionComponent with HasGameRef<PrismazeGame> {
  final Color requiredColor;
  final int sequenceIndex;
  
  bool _isLit = false;
  bool _wasLit = false;
  
  @override
  void update(double dt) {
    super.update(dt);
    _time += dt;
    _scaleAnim = 1.0 + 0.05 * sin(_time * 3);
    scale = Vector2.all(_scaleAnim);

    double targetFill = _isLit ? 1.0 : _getCompletionRatio();
    
    if (_fillProgress < targetFill) {
        _fillProgress += dt * 0.7;
        if (_fillProgress > targetFill) _fillProgress = targetFill;
    } else if (_fillProgress > targetFill) {
        _fillProgress -= dt * 1.5;
        if (_fillProgress < targetFill) _fillProgress = targetFill;
    }
    _fillProgress = _fillProgress.clamp(0.0, 1.0);
    
    for (int i = _confetti.length - 1; i >= 0; i--) {
        final p = _confetti[i];
        p.position += p.velocity * dt;
        p.life -= dt;
        p.velocity *= 0.95;
        if (p.life <= 0) _confetti.removeAt(i);
    }
  }
  
  // Per-frame tracking for simultaneous arrival (NOW USING LightColor)
  final Set<LightColor> _currentFrameColors = {};
  
  // Derived mask for visual helpers
  int get collectedMask => ColorMask.fromColors(_currentFrameColors);
  
  // Derived LightColor for required color
  LightColor get requiredLightColor => LightColorExtension.fromFlutterColor(requiredColor);

  // Animation State
  double _time = 0;
  double _fillProgress = 0.0; // 0.0 -> 1.0
  double _scaleAnim = 1.0;
  
  // Particles
  final List<TargetParticle> _confetti = [];
  final Random _rng = Random();

  // === OPTIMIZATION: CACHED PAINTS ===
  final Paint _basePaint = Paint();
  final Paint _strokePaint = Paint()..style = PaintingStyle.stroke;
  final Paint _glowPaint = Paint();
  final Paint _fillPaint = Paint();
  
  // Static MaskFilters for reuse
  static const _blur6 = MaskFilter.blur(BlurStyle.normal, 6);
  static const _blur8 = MaskFilter.blur(BlurStyle.normal, 8);
  static const _blur10 = MaskFilter.blur(BlurStyle.normal, 10);
  static const _blur15 = MaskFilter.blur(BlurStyle.normal, 15);
  static const _blur4 = MaskFilter.blur(BlurStyle.normal, 4);

  bool get isLit => _isLit;

  double opacity = 1.0;

  final int? procIndex; // Link to procedural GameState index

  // Visual offsets for shake animation
  double _shakeTimer = 0;
  Vector2 _visualOffset = Vector2.zero();

  Target({
    required Vector2 position,
    required this.requiredColor,
    this.sequenceIndex = 0,
    this.procIndex,
  }) : super(
          position: position,
          size: Vector2(65, 65),
          anchor: Anchor.center,
        );

  set isLit(bool value) => _isLit = value;

  /// Called at START of each beam trace
  void resetHits() {
    _currentFrameColors.clear();
  }
  
  /// Called when beam hits this target
  void addBeamColor(Color color) {
    if (color.opacity < 0.1) return;
    _currentFrameColors.add(LightColorExtension.fromFlutterColor(color));
  }
  
  /// Called for procedural tracing
  void addBeamLightColor(LightColor color) {
    _currentFrameColors.add(color);
  }
  
  void setLockedState() {
    _isLit = false;
  }

  /// Called at END of beam trace to check satisfaction
  void checkStatus() {
    // Must have received actual light (not just empty set)
    if (_currentFrameColors.isEmpty) {
      _isLit = false;
      _visualOffset = Vector2.zero();
      _shakeTimer = 0;
      return;
    }
    
    bool match = ColorMixer.satisfiesTarget(_currentFrameColors, requiredLightColor);
    _isLit = match;
    
    // Trigger explosion on rising edge
    if (_isLit && !_wasLit) {
      _spawnConfetti();
      AudioManager().vibrateCorrectTarget();
    }
    _wasLit = _isLit;
    
    // Visual Feedback: Shake if wrong color but receiving light
    if (!match) {
      _shakeTimer += 0.016;
      final offset = sin(_shakeTimer * 50) * 2;
      _visualOffset = Vector2(offset, 0);
    } else {
      _visualOffset = Vector2.zero();
      _shakeTimer = 0;
    }
  }
  
  /// Apply procedural lighting state from RayTracer.
  /// Populates _currentFrameColors to drive visual helpers.
  void applyProceduralMask(int mask) {
    _currentFrameColors.clear();
    
    // Decompose mask into base colors for visual logic
    if ((mask & ColorMask.red) != 0) _currentFrameColors.add(LightColor.red);
    if ((mask & ColorMask.blue) != 0) _currentFrameColors.add(LightColor.blue);
    if ((mask & ColorMask.yellow) != 0) _currentFrameColors.add(LightColor.yellow);
    if ((mask & ColorMask.white) != 0) _currentFrameColors.add(LightColor.white);
    
    // Set Lit state based on procedural result (strict verification)
    final reqMask = requiredLightColor.requiredMask;
    bool lit = ColorMask.satisfies(mask, reqMask);
    
    if (lit && !_wasLit) {
      _spawnConfetti();
      AudioManager().vibrateCorrectTarget();
    }
    _wasLit = lit;
    _isLit = lit;
  }

  /// Get completion ratio for visual progress
  double _getCompletionRatio() {
    if (_isLit) return 1.0;
    final req = requiredLightColor;
    if (!req.isMixed) return 0.0;
    
    final reqMask = req.requiredMask;
    final collected = collectedMask & reqMask;
    
    int reqCount = 0;
    int colCount = 0;
    for (int i = 0; i < 4; i++) {
        if ((reqMask & (1 << i)) != 0) reqCount++;
        if ((collected & (1 << i)) != 0) colCount++;
    }
    if (reqCount == 0) return 0.0;
    return colCount / reqCount;
  }
  
  /// Get color for a bitmask value
  Color _getMaskColor(int mask) {
    switch (mask) {
      case ColorMask.red: return const Color(0xFFFF4444); // Red
      case ColorMask.blue: return const Color(0xFF4488FF); // Blue
      case ColorMask.yellow: return const Color(0xFFFFDD44); // Yellow
      case ColorMask.white: return Colors.white;
      default: 
        return Colors.white;
    }
  }
  
  void _spawnConfetti() {
      if (gameRef.settingsManager.reducedGlowEnabled) return;
      for(int i=0; i<10; i++) {
          double angle = _rng.nextDouble() * 2 * pi;
          double speed = 50.0 + _rng.nextDouble() * 100.0;
          _confetti.add(TargetParticle(
              position: size / 2,
              velocity: Vector2(cos(angle), sin(angle)) * speed,
              color: requiredColor.withOpacity(0.8),
              life: 1.0 + _rng.nextDouble() * 0.5,
              size: 3.0 + _rng.nextDouble() * 3.0,
          ));
      }
  }

  bool _isMixedTarget() {
    return requiredLightColor.isMixed;
  }

  List<int> _getRequiredComponents() {
    final req = requiredLightColor;
    if (req == LightColor.purple) return [ColorMask.red, ColorMask.blue];
    if (req == LightColor.orange) return [ColorMask.red, ColorMask.yellow];
    if (req == LightColor.green) return [ColorMask.blue, ColorMask.yellow];
    return [];
  }
  
  void _drawProgressSlots(Canvas canvas, Offset center, double radius) {
    final components = _getRequiredComponents();
    if (components.isEmpty) return;
    
    final slotRadius = radius * 0.25;
    final spacing = slotRadius * 2.5;
    final startX = center.dx - (spacing * (components.length - 1) / 2);
    final slotY = center.dy + radius + slotRadius + 4;
    
    // Derive collected mask from current frame colors
    final mask = collectedMask;

    for (int i = 0; i < components.length; i++) {
      final compMask = components[i];
      final isCollected = (mask & compMask) != 0;
      final slotCenter = Offset(startX + i * spacing, slotY);
      
      canvas.drawCircle(
        slotCenter,
        slotRadius,
        Paint()
          ..color = isCollected 
              ? _getMaskColor(compMask).withOpacity(opacity)
              : Colors.grey.shade800.withOpacity(opacity * 0.7)
          ..style = PaintingStyle.fill,
      );
      
      // Add glow to collected slots
      if (isCollected && !gameRef.settingsManager.reducedGlowEnabled) {
        canvas.drawCircle(
          slotCenter,
          slotRadius + 2,
          Paint()
            ..color = _getMaskColor(compMask).withOpacity(0.3 * opacity)
            ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4),
        );
      }
      
      canvas.drawCircle(
        slotCenter,
        slotRadius,
        Paint()
          ..color = (isCollected ? Colors.white : Colors.grey.shade600).withOpacity(opacity)
          ..style = PaintingStyle.stroke
          ..strokeWidth = isCollected ? 2.0 : 1.5,
      );
      
      if (isCollected) {
        final checkSize = slotRadius * 0.5;
        final checkPath = Path();
        checkPath.moveTo(slotCenter.dx - checkSize * 0.5, slotCenter.dy);
        checkPath.lineTo(slotCenter.dx - checkSize * 0.1, slotCenter.dy + checkSize * 0.4);
        checkPath.lineTo(slotCenter.dx + checkSize * 0.5, slotCenter.dy - checkSize * 0.3);
        
        canvas.drawPath(
          checkPath,
          Paint()
            ..color = Colors.white.withOpacity(opacity)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 2
            ..strokeCap = StrokeCap.round
            ..strokeJoin = StrokeJoin.round,
        );
      }
    }
  }

  @override
  void render(Canvas canvas) {
    if (opacity == 0) return;
    
    canvas.save();
    canvas.translate(_visualOffset.x, _visualOffset.y);
    
    final center = Offset(size.x / 2, size.y / 2);
    final radius = size.x / 2;
    final safeColor = ColorBlindnessUtils.getSafeColor(requiredColor);
    final bool reducedGlow = gameRef.settingsManager.reducedGlowEnabled;
    final bool highContrast = gameRef.settingsManager.highContrastEnabled;

    if (highContrast) {
      _basePaint
        ..color = (_isLit ? Colors.white : Colors.grey.shade700).withOpacity(opacity)
        ..style = _isLit ? PaintingStyle.fill : PaintingStyle.stroke
        ..strokeWidth = 3;
      canvas.drawCircle(center, radius, _basePaint);
      canvas.restore();
      return;
    }

    if (!reducedGlow) {
      _glowPaint
        ..color = Colors.black.withOpacity(0.3 * opacity)
        ..maskFilter = _blur6;
      canvas.drawCircle(center + const Offset(2, 3), radius + 2, _glowPaint);
    }

    if (!reducedGlow && _fillProgress < 1.0) {
      final haloAlpha = 0.15 + 0.1 * sin(_time * 2.5);
      _glowPaint
        ..color = safeColor.withOpacity(haloAlpha.clamp(0.0, 0.3) * opacity)
        ..maskFilter = _blur15;
      canvas.drawCircle(center, radius + 5, _glowPaint);
    }

    if (_fillProgress < 1.0) {
      final pulseWidth = 2.5 + 1.0 * sin(_time * 4);
      final pulseAlpha = 0.5 + 0.3 * sin(_time * 5);
      
      if (!reducedGlow) {
        _strokePaint
          ..color = safeColor.withOpacity(pulseAlpha * 0.4 * opacity)
          ..strokeWidth = pulseWidth + 4
          ..maskFilter = _blur4;
        canvas.drawCircle(center, radius, _strokePaint);
      }
      
      _strokePaint
        ..color = safeColor.withOpacity(pulseAlpha.clamp(0.3, 0.8) * opacity)
        ..strokeWidth = pulseWidth
        ..maskFilter = null;
      canvas.drawCircle(center, radius, _strokePaint);
      
      _strokePaint
        ..color = Colors.black.withOpacity(0.15 * opacity)
        ..strokeWidth = 1;
      canvas.drawCircle(center, radius - 4, _strokePaint);
    }

    if (!reducedGlow && _fillProgress < 0.5) {
      const int particleCount = 4;
      for (int i = 0; i < particleCount; i++) {
        final angle = (_time * 0.6) + (i * 2 * pi / particleCount);
        final particleX = center.dx + cos(angle) * (radius + 5);
        final particleY = center.dy + sin(angle) * (radius + 5);
        final particleAlpha = 0.4 + 0.2 * sin(_time * 2 + i);
        
        _basePaint.color = safeColor.withOpacity(particleAlpha * opacity);
        canvas.drawCircle(Offset(particleX, particleY), 2.5, _basePaint);
      }
    }

    if (_fillProgress < 0.5) {
      final hintGradient = RadialGradient(
        colors: [
          safeColor.withOpacity(0.15 * opacity),
          safeColor.withOpacity(0.0),
        ],
      );
      canvas.drawCircle(
        center,
        radius - 5,
        Paint()..shader = hintGradient.createShader(Rect.fromCircle(center: center, radius: radius - 5)),
      );
    }

    if (_fillProgress > 0.01) {
      if (!reducedGlow) {
        _glowPaint
          ..color = safeColor.withOpacity(0.3 * _fillProgress * opacity)
          ..maskFilter = _blur8;
        canvas.drawCircle(center, radius * _fillProgress + 5, _glowPaint);
      }
      
      final fillGradient = RadialGradient(
        colors: [
          Colors.white.withOpacity(0.9 * _fillProgress * opacity),
          safeColor.withOpacity(0.95 * _fillProgress * opacity),
          safeColor.withOpacity(0.7 * _fillProgress * opacity),
        ],
        stops: const [0.0, 0.4, 1.0],
      );
      
      _fillPaint.shader = fillGradient.createShader(Rect.fromCircle(center: center, radius: radius * _fillProgress));
      canvas.drawCircle(center, radius * _fillProgress, _fillPaint);
      
      if (_fillProgress > 0.3) {
        _strokePaint
          ..color = Colors.white.withOpacity(0.6 * opacity)
          ..strokeWidth = 2
          ..maskFilter = null;
        canvas.drawCircle(center, radius * _fillProgress, _strokePaint);
      }
    }

    if (_fillProgress >= 0.95) {
      if (!reducedGlow) {
        _glowPaint
          ..color = safeColor.withOpacity(0.5 * opacity)
          ..maskFilter = _blur10;
        canvas.drawCircle(center, radius + 8, _glowPaint);
      }
      
      _basePaint.color = Colors.white.withOpacity(0.95 * opacity);
      canvas.drawCircle(center, radius * 0.6, _basePaint);
      
      final checkPath = Path();
      final cx = center.dx;
      final cy = center.dy;
      final checkSize = radius * 0.4;
      
      checkPath.moveTo(cx - checkSize * 0.6, cy);
      checkPath.lineTo(cx - checkSize * 0.1, cy + checkSize * 0.5);
      checkPath.lineTo(cx + checkSize * 0.6, cy - checkSize * 0.4);
      
      _strokePaint
        ..color = safeColor.withOpacity(opacity)
        ..strokeWidth = 3
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..maskFilter = null;
      canvas.drawPath(checkPath, _strokePaint);
    }

    if (_fillProgress < 0.95 && _isMixedTarget()) {
      _drawProgressSlots(canvas, center, radius);
    }

    if (_fillProgress < 0.95) {
      ColorBlindnessUtils.drawSymbol(canvas, center, requiredColor, size.x / 2);
    }

    for (final p in _confetti) {
      _basePaint.color = Colors.white.withOpacity(p.life.clamp(0.0, 1.0));
      canvas.drawCircle(p.position.toOffset(), p.size * p.life, _basePaint);
    }
    
    canvas.restore();
  }
}



import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import 'dart:math';
import '../utils/physics_utils.dart';
import '../utils/color_blindness_utils.dart';
import '../audio_manager.dart';
import '../prismaze_game.dart'; // For settings access

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
  
  // Logic Accumulator
  Color _accumulatedColor = const Color(0xFF000000);
  
  // Bitmask tracking for mixed colors (R=1, B=2, Y=4, W=8)
  int _collectedMask = 0;
  int get collectedMask => _collectedMask;

  // Animation State
  double _time = 0;
  double _fillProgress = 0.0; // 0.0 -> 1.0
  double _scaleAnim = 1.0;
  
  // Particles
  final List<TargetParticle> _confetti = [];
  final Random _rng = Random();

  // === OPTIMIZATION: CACHED PAINTS ===
  // Reuse Paint objects to avoid GC churn in render()
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

  Target({
    required Vector2 position,
    required this.requiredColor,
    this.sequenceIndex = 0,
  }) : super(
          position: position,
          size: Vector2(65, 65), // Larger for 85px cell (was 50x50)
          anchor: Anchor.center,
        );

  set isLit(bool value) => _isLit = value;

  void addBeamColor(Color color) {
    // Reject near-transparent beams
    if (color.opacity < 0.1) return;
    _accumulatedColor = _mixColors(_accumulatedColor, color);
    
    // Update bitmask for mixed color tracking
    _collectedMask |= _colorToBitmask(color);
  }
  
  /// Convert Flutter Color to bitmask (R=1, B=2, Y=4, W=8)
  int _colorToBitmask(Color c) {
    // Map common game colors to bitmask
    // Red-ish colors
    if (c.red > 200 && c.green < 100 && c.blue < 100) return 1; // R
    // Blue-ish colors
    if (c.blue > 200 && c.red < 100 && c.green < 150) return 2; // B
    // Yellow-ish colors
    if (c.red > 200 && c.green > 200 && c.blue < 100) return 4; // Y
    // White
    if (c.red > 200 && c.green > 200 && c.blue > 200) return 8; // W
    return 0;
  }
  
  // ... (keeping resetHits etc as is)
  void resetHits() {
    _accumulatedColor = const Color(0xFF000000);
    _collectedMask = 0;
  }
  
  void setLockedState() {
      _isLit = false;
  }

  void checkStatus() {
     // Must have received actual light (not just black)
     if (_accumulatedColor == const Color(0xFF000000)) {
       _isLit = false;
       _visualOffset = Vector2.zero();
       _shakeTimer = 0;
       return;
     }
     
     bool match = _colorMatch(_accumulatedColor, requiredColor);
     _isLit = match;
     
     // Trigger explosion on rising edge
     if (_isLit && !_wasLit) {
         _spawnConfetti();
         AudioManager().vibrateCorrectTarget(); // 50ms
     }
     _wasLit = _isLit;
     
     // Visual Feedback: Shake if wrong color but receiving light
     if (!match && _accumulatedColor != const Color(0xFF000000)) {
         _shakeTimer += 0.016; // Approx dt
         final offset = sin(_shakeTimer * 50) * 2;
         // position += Vector2(offset, 0); // NO: changing Physics position causes issues.
         // Use render offset
         _visualOffset = Vector2(offset, 0);
     } else {
         _visualOffset = Vector2.zero();
         _shakeTimer = 0;
     }
  }
  
  // Expose accumulated color for level completion check
  Color get accumulatedColor => _accumulatedColor;
  
  // ... (keep shakeTimer etc)
  double _shakeTimer = 0;
  Vector2 _visualOffset = Vector2.zero();
  
  void _spawnConfetti() {
      // OPTIMIZATION: Skip if reduced glow
      if (gameRef.settingsManager.reducedGlowEnabled) return;
      
      // OPTIMIZATION: Reduced from 20 to 10 particles
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

  @override
  void update(double dt) {
    super.update(dt);
    _time += dt;
    
    // OPTIMIZATION: Skip complex animations if reduced glow
    if (gameRef.settingsManager.reducedGlowEnabled) {
         _confetti.clear();
         // Still do logic updates for game state (fill progress)
         if (_isLit) {
            _fillProgress += dt * 0.7;
         } else {
            _fillProgress -= dt * 1.5;
         }
         _fillProgress = _fillProgress.clamp(0.0, 1.0);
         return;
    }
    
    // 1. Continuous Scale Animation (Breathing)
    // Sine wave: period ~2s
    _scaleAnim = 1.0 + 0.05 * sin(_time * 3);
    scale = Vector2.all(_scaleAnim);

    // 2. Fill Animation (Slower for more satisfaction)
    if (_isLit) {
        _fillProgress += dt * 0.7; // Fill in ~1.5s (slower)
    } else {
        _fillProgress -= dt * 1.5; // Empty faster
    }
    _fillProgress = _fillProgress.clamp(0.0, 1.0);
    
    // 3. Update Particles
    for (int i = _confetti.length - 1; i >= 0; i--) {
        final p = _confetti[i];
        p.position += p.velocity * dt;
        p.life -= dt;
        p.velocity *= 0.95; // Drag
        if (p.life <= 0) {
            _confetti.removeAt(i);
        }
    }
  }

  @override
  void render(Canvas canvas) {
    if (opacity == 0) return;
    
    final bool reducedGlow = gameRef.settingsManager.reducedGlowEnabled;
    final bool highContrast = gameRef.settingsManager.highContrastEnabled;
    
    // FAST PATH: Reduced Glow
    if (reducedGlow) {
        _renderSimple(canvas);
        return;
    }
    
    canvas.save();
    canvas.translate(_visualOffset.x, _visualOffset.y);
    
    final center = Offset(size.x / 2, size.y / 2);
    final radius = size.x / 2;
    final safeColor = ColorBlindnessUtils.getSafeColor(requiredColor);

    // High contrast mode: simple solid circles
    if (highContrast) {
      _basePaint.color = (_isLit ? Colors.white : Colors.grey.shade700).withOpacity(opacity);
      _basePaint.style = _isLit ? PaintingStyle.fill : PaintingStyle.stroke;
      _basePaint.strokeWidth = 3;
      _basePaint.maskFilter = null; // Clear mask
      
      canvas.drawCircle(center, radius, _basePaint);
      canvas.restore();
      return;
    }

    // === LAYER 1: Drop Shadow ===
    if (!reducedGlow) {
      _glowPaint.color = Colors.black.withOpacity(0.3 * opacity);
      _glowPaint.maskFilter = _blur6;
      _glowPaint.style = PaintingStyle.fill;
      canvas.drawCircle(center + const Offset(2, 3), radius + 2, _glowPaint);
    }

    // === LAYER 2: Outer Halo (Atmospheric Glow) ===
    if (!reducedGlow && _fillProgress < 1.0) {
      final haloAlpha = 0.15 + 0.1 * sin(_time * 2.5);
      _glowPaint.color = safeColor.withOpacity(haloAlpha.clamp(0.0, 0.3) * opacity);
      _glowPaint.maskFilter = _blur15;
      _glowPaint.style = PaintingStyle.fill;
      canvas.drawCircle(center, radius + 15, _glowPaint);
    }

    // === LAYER 3: Pulsing Outer Ring (Empty State) ===
    if (_fillProgress < 1.0) {
      final pulseWidth = 2.5 + 1.0 * sin(_time * 4);
      final pulseAlpha = 0.5 + 0.3 * sin(_time * 5);
      
      // Outer glow ring
      if (!reducedGlow) {
        _strokePaint.color = safeColor.withOpacity(pulseAlpha * 0.4 * opacity);
        _strokePaint.strokeWidth = pulseWidth + 4;
        _strokePaint.maskFilter = _blur4;
        _strokePaint.style = PaintingStyle.stroke;
        canvas.drawCircle(center, radius, _strokePaint);
      }
      
      // Crisp ring
      _strokePaint.color = safeColor.withOpacity(pulseAlpha.clamp(0.3, 0.8) * opacity);
      _strokePaint.strokeWidth = pulseWidth;
      _strokePaint.maskFilter = null;
      _strokePaint.style = PaintingStyle.stroke;
      canvas.drawCircle(center, radius, _strokePaint);
      
      // Inner depth ring
      _strokePaint.color = Colors.black.withOpacity(0.15 * opacity);
      _strokePaint.strokeWidth = 1;
      _strokePaint.maskFilter = null;
      _strokePaint.style = PaintingStyle.stroke;
      canvas.drawCircle(center, radius - 4, _strokePaint);
    }

    // === LAYER 4: Orbiting Particles (Empty State) - OPTIMIZED ===
    if (!reducedGlow && _fillProgress < 0.5) {
      _basePaint.style = PaintingStyle.fill;
      _basePaint.maskFilter = null;
      
      const int particleCount = 4; // Reduced from 6
      for (int i = 0; i < particleCount; i++) {
        final angle = (_time * 0.6) + (i * 2 * pi / particleCount); // Slower
        final particleX = center.dx + cos(angle) * (radius + 5);
        final particleY = center.dy + sin(angle) * (radius + 5);
        final particleAlpha = 0.4 + 0.2 * sin(_time * 2 + i);
        
        _basePaint.color = safeColor.withOpacity(particleAlpha * opacity);
        canvas.drawCircle(Offset(particleX, particleY), 2.5, _basePaint);
      }
    }

    // === LAYER 5: Inner Hint Gradient (Empty State) ===
    if (_fillProgress < 0.5) {
      final hintGradient = RadialGradient(
        colors: [
          safeColor.withOpacity(0.15 * opacity),
          safeColor.withOpacity(0.0),
        ],
      );
      _fillPaint.shader = hintGradient.createShader(Rect.fromCircle(center: center, radius: radius - 5));
      _fillPaint.style = PaintingStyle.fill;
      _fillPaint.maskFilter = null;
      
      canvas.drawCircle(center, radius - 5, _fillPaint);
      _fillPaint.shader = null; // Clear shader
    }

    // === LAYER 6: Fill Animation (Radial gradient fill) ===
    if (_fillProgress > 0.01) {
      // Outer fill glow
      if (!reducedGlow) {
        _glowPaint.color = safeColor.withOpacity(0.3 * _fillProgress * opacity);
        _glowPaint.maskFilter = _blur8;
        _glowPaint.style = PaintingStyle.fill;
        canvas.drawCircle(center, radius * _fillProgress + 5, _glowPaint);
      }
      
      // Main fill with radial gradient
      final fillGradient = RadialGradient(
        colors: [
          Colors.white.withOpacity(0.9 * _fillProgress * opacity),
          safeColor.withOpacity(0.95 * _fillProgress * opacity),
          safeColor.withOpacity(0.7 * _fillProgress * opacity),
        ],
        stops: const [0.0, 0.4, 1.0],
      );
      
      _fillPaint.shader = fillGradient.createShader(Rect.fromCircle(center: center, radius: radius * _fillProgress));
      _fillPaint.style = PaintingStyle.fill;
      _fillPaint.maskFilter = null;
      canvas.drawCircle(center, radius * _fillProgress, _fillPaint);
      _fillPaint.shader = null; // Clear shader
      
      // Edge highlight ring
      if (_fillProgress > 0.3) {
        _strokePaint.color = Colors.white.withOpacity(0.6 * opacity);
        _strokePaint.strokeWidth = 2;
        _strokePaint.maskFilter = null;
        _strokePaint.style = PaintingStyle.stroke;
        canvas.drawCircle(center, radius * _fillProgress, _strokePaint);
      }
    }

    // === LAYER 7: Completion State (Checkmark + Intense glow) ===
    if (_fillProgress >= 0.95) {
      // Bright halo
      if (!reducedGlow) {
        _glowPaint.color = safeColor.withOpacity(0.5 * opacity);
        _glowPaint.maskFilter = _blur10;
        _glowPaint.style = PaintingStyle.fill;
        canvas.drawCircle(center, radius + 8, _glowPaint);
      }
      
      // White core
      _basePaint.color = Colors.white.withOpacity(0.95 * opacity);
      _basePaint.style = PaintingStyle.fill;
      _basePaint.maskFilter = null;
      canvas.drawCircle(center, radius * 0.6, _basePaint);
      
      // Draw checkmark
      final checkPath = Path();
      final cx = center.dx;
      final cy = center.dy;
      final checkSize = radius * 0.4;
      
      checkPath.moveTo(cx - checkSize * 0.6, cy);
      checkPath.lineTo(cx - checkSize * 0.1, cy + checkSize * 0.5);
      checkPath.lineTo(cx + checkSize * 0.6, cy - checkSize * 0.4);
      
      _strokePaint.color = safeColor.withOpacity(opacity);
      _strokePaint.strokeWidth = 3;
      _strokePaint.strokeCap = StrokeCap.round;
      _strokePaint.strokeJoin = StrokeJoin.round;
      _strokePaint.maskFilter = null;
      _strokePaint.style = PaintingStyle.stroke;
      canvas.drawPath(checkPath, _strokePaint);
    }

    // === LAYER 8: Mixed Color Progress Slots ===
    if (_fillProgress < 0.95 && _isMixedTarget()) {
      _drawProgressSlots(canvas, center, radius);
    }

    // === LAYER 9: Accessibility Symbol ===
    if (_fillProgress < 0.95) {
      ColorBlindnessUtils.drawSymbol(canvas, center, requiredColor, size.x / 2);
    }

    // === Render Confetti Particles (OPTIMIZED - no glow) ===
    _basePaint.style = PaintingStyle.fill;
    _basePaint.maskFilter = null;
    for (final p in _confetti) {
      _basePaint.color = Colors.white.withOpacity(p.life.clamp(0.0, 1.0));
      canvas.drawCircle(p.position.toOffset(), p.size * p.life, _basePaint);
    }
    
    canvas.restore();
  }
  
  void _renderSimple(Canvas canvas) {
      final center = Offset(size.x / 2, size.y / 2);
      final radius = size.x / 2;
      final safeColor = ColorBlindnessUtils.getSafeColor(requiredColor);
      
      // Fill when lit
      if (_fillProgress > 0) {
          _basePaint.color = safeColor.withOpacity(opacity * 0.8);
          _basePaint.style = PaintingStyle.fill;
          _basePaint.maskFilter = null;
          canvas.drawCircle(center, radius * _fillProgress, _basePaint);
      }
      
      // Border
      _strokePaint.color = (_isLit ? safeColor : Colors.white).withOpacity(opacity);
      _strokePaint.style = PaintingStyle.stroke;
      _strokePaint.strokeWidth = 2;
      _strokePaint.maskFilter = null;
      canvas.drawCircle(center, radius, _strokePaint);
        
      if (_isLit && _fillProgress > 0.9) {
          // Checkmark
           final checkPath = Path();
           final cx = center.dx;
           final cy = center.dy;
           final checkSize = radius * 0.4;
           
           checkPath.moveTo(cx - checkSize * 0.6, cy);
           checkPath.lineTo(cx - checkSize * 0.1, cy + checkSize * 0.5);
           checkPath.lineTo(cx + checkSize * 0.6, cy - checkSize * 0.4);
           
           _strokePaint.color = Colors.white;
           _strokePaint.style = PaintingStyle.stroke;
           _strokePaint.strokeWidth = 3;
           _strokePaint.maskFilter = null;
           canvas.drawPath(checkPath, _strokePaint);
      }
      
      // Mixed slots if needed
      if (_fillProgress < 0.9 && _isMixedTarget()) {
          _drawProgressSlots(canvas, center, radius);
      }
      
      // Symbol
      if (_fillProgress < 0.9) {
          ColorBlindnessUtils.drawSymbol(canvas, center, requiredColor, size.x / 2);
      }
  }

  bool _colorMatch(Color c1, Color c2) {
      const int tolerance = 50; // Stricter tolerance for better gameplay
      return (c1.red - c2.red).abs() < tolerance &&
             (c1.green - c2.green).abs() < tolerance &&
             (c1.blue - c2.blue).abs() < tolerance;
  }

  Color _mixColors(Color c1, Color c2) {
    int r = (c1.red + c2.red).clamp(0, 255);
    int g = (c1.green + c2.green).clamp(0, 255);
    int b = (c1.blue + c2.blue).clamp(0, 255);
    return Color.fromARGB(255, r, g, b);
  }
  
  /// Check if this target requires a mixed color (purple/orange/green).
  bool _isMixedTarget() {
    // Purple = R + B (magenta-ish)
    if (requiredColor.red > 150 && requiredColor.blue > 150 && requiredColor.green < 100) return true;
    // Orange = R + Y
    if (requiredColor.red > 200 && requiredColor.green > 100 && requiredColor.green < 200 && requiredColor.blue < 100) return true;
    // Green = B + Y
    if (requiredColor.green > 150 && requiredColor.blue < 150 && requiredColor.red < 150) return true;
    return false;
  }
  
  /// Get required components for this mixed target.
  List<int> _getRequiredComponents() {
    // Purple = R + B
    if (requiredColor.red > 150 && requiredColor.blue > 150 && requiredColor.green < 100) {
      return [1, 2]; // R, B
    }
    // Orange = R + Y  
    if (requiredColor.red > 200 && requiredColor.green > 100 && requiredColor.green < 200 && requiredColor.blue < 100) {
      return [1, 4]; // R, Y
    }
    // Green = B + Y
    if (requiredColor.green > 150 && requiredColor.blue < 150 && requiredColor.red < 150) {
      return [2, 4]; // B, Y
    }
    return [];
  }
  
  /// Draw progress slots showing which color components have been collected.
  void _drawProgressSlots(Canvas canvas, Offset center, double radius) {
    final components = _getRequiredComponents();
    if (components.isEmpty) return;
    
    final slotRadius = radius * 0.25;
    final spacing = slotRadius * 2.5;
    final startX = center.dx - (spacing * (components.length - 1) / 2);
    final slotY = center.dy + radius + slotRadius + 4;
    
    for (int i = 0; i < components.length; i++) {
      final mask = components[i];
      final isCollected = (_collectedMask & mask) != 0;
      final slotCenter = Offset(startX + i * spacing, slotY);
      
      // Draw slot background
      canvas.drawCircle(
        slotCenter,
        slotRadius,
        Paint()
          ..color = isCollected 
              ? _getMaskColor(mask).withOpacity(opacity)
              : Colors.grey.shade800.withOpacity(opacity * 0.7)
          ..style = PaintingStyle.fill,
      );
      
      // Draw slot border
      canvas.drawCircle(
        slotCenter,
        slotRadius,
        Paint()
          ..color = (isCollected ? Colors.white : Colors.grey.shade600).withOpacity(opacity)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.5,
      );
      
      // Draw check if collected
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
  
  /// Get color for a bitmask value.
  Color _getMaskColor(int mask) {
    switch (mask) {
      case 1: return const Color(0xFFFF4444); // Red
      case 2: return const Color(0xFF4488FF); // Blue
      case 4: return const Color(0xFFFFDD44); // Yellow
      default: return Colors.white;
    }
  }
}



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

  // Animation State
  double _time = 0;
  double _fillProgress = 0.0; // 0.0 -> 1.0
  double _scaleAnim = 1.0;
  
  // Particles
  final List<TargetParticle> _confetti = [];
  final Random _rng = Random();

  bool get isLit => _isLit;

  double opacity = 1.0;

  Target({
    required Vector2 position,
    required this.requiredColor,
    this.sequenceIndex = 0,
  }) : super(
          position: position,
          size: Vector2(50, 50), // Larger for better visibility
          anchor: Anchor.center,
        );

  set isLit(bool value) => _isLit = value;

  void addBeamColor(Color color) {
    // Reject near-transparent beams
    if (color.opacity < 0.1) return;
    _accumulatedColor = _mixColors(_accumulatedColor, color);
  }
  
  // ... (keeping resetHits etc as is)
  void resetHits() {
    _accumulatedColor = const Color(0xFF000000);
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
    
    canvas.save();
    canvas.translate(_visualOffset.x, _visualOffset.y);
    
    final center = Offset(size.x / 2, size.y / 2);
    final radius = size.x / 2;
    final safeColor = ColorBlindnessUtils.getSafeColor(requiredColor);
    final bool reducedGlow = gameRef.settingsManager.reducedGlowEnabled;
    final bool highContrast = gameRef.settingsManager.highContrastEnabled;

    // High contrast mode: simple solid circles
    if (highContrast) {
      canvas.drawCircle(center, radius, Paint()
        ..color = (_isLit ? Colors.white : Colors.grey.shade700).withOpacity(opacity)
        ..style = _isLit ? PaintingStyle.fill : PaintingStyle.stroke
        ..strokeWidth = 3);
      canvas.restore();
      return;
    }

    // === LAYER 1: Drop Shadow ===
    if (!reducedGlow) {
      canvas.drawCircle(
        center + const Offset(2, 3),
        radius + 2,
        Paint()
          ..color = Colors.black.withOpacity(0.3 * opacity)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6),
      );
    }

    // === LAYER 2: Outer Halo (Atmospheric Glow) ===
    if (!reducedGlow && _fillProgress < 1.0) {
      final haloAlpha = 0.15 + 0.1 * sin(_time * 2.5);
      canvas.drawCircle(
        center,
        radius + 15,
        Paint()
          ..color = safeColor.withOpacity(haloAlpha.clamp(0.0, 0.3) * opacity)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 15),
      );
    }

    // === LAYER 3: Pulsing Outer Ring (Empty State) ===
    if (_fillProgress < 1.0) {
      final pulseWidth = 2.5 + 1.0 * sin(_time * 4);
      final pulseAlpha = 0.5 + 0.3 * sin(_time * 5);
      
      // Outer glow ring
      if (!reducedGlow) {
        canvas.drawCircle(
          center,
          radius,
          Paint()
            ..color = safeColor.withOpacity(pulseAlpha * 0.4 * opacity)
            ..style = PaintingStyle.stroke
            ..strokeWidth = pulseWidth + 4
            ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4),
        );
      }
      
      // Crisp ring
      canvas.drawCircle(
        center,
        radius,
        Paint()
          ..color = safeColor.withOpacity(pulseAlpha.clamp(0.3, 0.8) * opacity)
          ..style = PaintingStyle.stroke
          ..strokeWidth = pulseWidth,
      );
      
      // Inner depth ring
      canvas.drawCircle(
        center,
        radius - 4,
        Paint()
          ..color = Colors.black.withOpacity(0.15 * opacity)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1,
      );
    }

    // === LAYER 4: Orbiting Particles (Empty State) - OPTIMIZED ===
    if (!reducedGlow && _fillProgress < 0.5) {
      const int particleCount = 4; // Reduced from 6
      for (int i = 0; i < particleCount; i++) {
        final angle = (_time * 0.6) + (i * 2 * pi / particleCount); // Slower
        final particleX = center.dx + cos(angle) * (radius + 5);
        final particleY = center.dy + sin(angle) * (radius + 5);
        final particleAlpha = 0.4 + 0.2 * sin(_time * 2 + i);
        
        canvas.drawCircle(
          Offset(particleX, particleY),
          2.5, // Smaller
          Paint()..color = safeColor.withOpacity(particleAlpha * opacity),
        );
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
      canvas.drawCircle(
        center,
        radius - 5,
        Paint()..shader = hintGradient.createShader(Rect.fromCircle(center: center, radius: radius - 5)),
      );
    }

    // === LAYER 6: Fill Animation (Radial gradient fill) ===
    if (_fillProgress > 0.01) {
      // Outer fill glow
      if (!reducedGlow) {
        canvas.drawCircle(
          center,
          radius * _fillProgress + 5,
          Paint()
            ..color = safeColor.withOpacity(0.3 * _fillProgress * opacity)
            ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8),
        );
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
      
      canvas.drawCircle(
        center,
        radius * _fillProgress,
        Paint()..shader = fillGradient.createShader(Rect.fromCircle(center: center, radius: radius * _fillProgress)),
      );
      
      // Edge highlight ring
      if (_fillProgress > 0.3) {
        canvas.drawCircle(
          center,
          radius * _fillProgress,
          Paint()
            ..color = Colors.white.withOpacity(0.6 * opacity)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 2,
        );
      }
    }

    // === LAYER 7: Completion State (Checkmark + Intense glow) ===
    if (_fillProgress >= 0.95) {
      // Bright halo
      if (!reducedGlow) {
        canvas.drawCircle(
          center,
          radius + 8,
          Paint()
            ..color = safeColor.withOpacity(0.5 * opacity)
            ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10),
        );
      }
      
      // White core
      canvas.drawCircle(
        center,
        radius * 0.6,
        Paint()..color = Colors.white.withOpacity(0.95 * opacity),
      );
      
      // Draw checkmark
      final checkPath = Path();
      final cx = center.dx;
      final cy = center.dy;
      final checkSize = radius * 0.4;
      
      checkPath.moveTo(cx - checkSize * 0.6, cy);
      checkPath.lineTo(cx - checkSize * 0.1, cy + checkSize * 0.5);
      checkPath.lineTo(cx + checkSize * 0.6, cy - checkSize * 0.4);
      
      canvas.drawPath(
        checkPath,
        Paint()
          ..color = safeColor.withOpacity(opacity)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 3
          ..strokeCap = StrokeCap.round
          ..strokeJoin = StrokeJoin.round,
      );
    }

    // === LAYER 8: Accessibility Symbol ===
    if (_fillProgress < 0.95) {
      ColorBlindnessUtils.drawSymbol(canvas, center, requiredColor, size.x / 2);
    }

    // === Render Confetti Particles (OPTIMIZED - no glow) ===
    for (final p in _confetti) {
      canvas.drawCircle(
        p.position.toOffset(),
        p.size * p.life,
        Paint()..color = Colors.white.withOpacity(p.life.clamp(0.0, 1.0)),
      );
    }
    
    canvas.restore();
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
}


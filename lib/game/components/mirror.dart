import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flutter/material.dart';
import '../audio_manager.dart';
import '../prismaze_game.dart';
import '../utils/visual_effects.dart';
import '../procedural/models/models.dart' as proc;
import 'wall.dart';
import 'prism.dart';
import 'dart:math';

class Mirror extends PositionComponent with TapCallbacks, HasGameRef<PrismazeGame> {
  // Global index for GameState
  final int index;
  // Visual state
  double _shineOffset = -1.0;
  bool _isRotating = false;
  bool isLocked = false;
  double _time = 0;
  double _lightHitIntensity = 0; // Glow when light hits
  
  /// Discrete orientation (0-3) for the new procedural system.
  /// 0 = horizontal "_", 1 = slash "/", 2 = vertical "|", 3 = backslash "\"
  /// Discrete orientation (0-3) linked to GameState
  int get _discreteOrientation => gameRef.currentState.mirrorOrientations[index];
  set _discreteOrientation(int value) => gameRef.currentState = gameRef.currentState.withMirrorOrientation(index, value);
  
  /// Whether this mirror uses discrete orientation (campaign mode).
  /// When true, tap rotates through 4 states.
  bool useDiscreteOrientation = false;
  
  double opacity = 1.0;
  
  // Premium color scheme
  static const _frameGoldDark = Color(0xFFB8860B);     // Dark gold
  static const _frameGoldLight = Color(0xFFFFD700);    // Bright gold
  static const _frameGoldMid = Color(0xFFD4AF37);      // Classic gold
  static const _chromeDark = Color(0xFF8A9BAE);        // Dark chrome
  static const _chromeLight = Color(0xFFE8EEF4);       // Bright chrome
  static const _chromeMid = Color(0xFFB8C5D6);         // Mid chrome
  static const _glowColor = Color(0xFF64FFDA);         // Cyan accent glow
  static const _impactColor = Color(0xFFFFFFFF);       // White impact flash

  // === OPTIMIZATION: CACHED PAINTS ===
  final Paint _basePaint = Paint();
  final Paint _strokePaint = Paint()..style = PaintingStyle.stroke;
  final Paint _glowPaint = Paint();
  final Paint _shaderPaint = Paint();
  
  // Static MaskFilters
  static const _blur3 = MaskFilter.blur(BlurStyle.solid, 3);
  static const _blur4 = MaskFilter.blur(BlurStyle.normal, 4);

  Mirror({
    required Vector2 position,
    double angle = 0,
    this.isLocked = false,
    int discreteOrientation = 0,
    this.useDiscreteOrientation = false,
    required this.index,
  }) : super(
          position: position,
          size: Vector2(75, 20), // Wider for 85px cell (was 54x14)
          angle: angle,
          anchor: Anchor.center,
        );
  
  /// Called by BeamSystem when light hits this mirror
  void onLightHit() {
    _lightHitIntensity = 1.0;
  }
  
  /// Get discrete orientation for procedural system.
  int get discreteOrientation => _discreteOrientation;
  
  /// Set discrete orientation and update visual angle.
  set discreteOrientation(int value) {
    _discreteOrientation = value % 4;
    angle = _discreteOrientationToAngle(_discreteOrientation);
  }
  
  /// Convert discrete orientation to visual angle (45° increments).
  static double _discreteOrientationToAngle(int orientation) {
    // 0 = 0°, 1 = 45°, 2 = 90°, 3 = 135° (consistent increments)
    return (orientation % 4) * pi / 4;
  }
  
  /// Convert from procedural model.
  factory Mirror.fromProcedural(proc.Mirror m, int index) {
    final angle = _discreteOrientationToAngle(m.orientation.index);
    return Mirror(
      position: Vector2(
        m.position.x * proc.GridPosition.cellSize + proc.GridPosition.cellSize / 2,
        m.position.y * proc.GridPosition.cellSize + proc.GridPosition.cellSize / 2,
      ),
      angle: angle,
      isLocked: !m.rotatable,
      discreteOrientation: m.orientation.index,
      useDiscreteOrientation: true,
      index: index,
    );
  }

  // ===== TAP TO ROTATE =====
  @override
  void onTapUp(TapUpEvent event) {
      // Rotate on single tap
      _rotate();
  }

  void _rotate() {
    if (isLocked) {
         AudioManager().playSfx('error_sound.mp3');
         return;
    }
    
    final startPos = position.clone();
    final startAngle = angle;
    
    if (useDiscreteOrientation) {
        _discreteOrientation = (_discreteOrientation + 1) % 4;
        angle = _discreteOrientationToAngle(_discreteOrientation);
    } else {
        angle += pi / 4;
        if (angle >= 2 * pi) angle -= 2 * pi;
        _discreteOrientation = ((angle / (pi / 4)).round() % 4).abs();
    }
    
    print('MIRROR ROTATE! orientation=$_discreteOrientation');
    _triggerShine();
    AudioManager().playSfx('mirror_tap_sound.mp3');
    
    gameRef.recordMove(hashCode, startPos, startAngle);
    gameRef.requestBeamUpdate();
  }

  @override
  bool containsLocalPoint(Vector2 point) {
      // Expand hitbox for easier tapping (especially for thin mirror)
      // 54x14 is very thin. Add 20px padding.
      final r = size.toRect().inflate(20);
      return r.contains(point.toOffset());
  }

  @override
  void update(double dt) {
      super.update(dt);
      _time += dt;
      
      // Animate shine if rotating (or just triggered)
      if (_shineOffset > -1.0) {
          _shineOffset += dt * 2.5; // Speed
          if (_shineOffset > 2.0) {
              _shineOffset = -1.0; // Reset
              _isRotating = false;
          }
      }
      
      // Decay light hit intensity
      if (_lightHitIntensity > 0) {
        _lightHitIntensity -= dt * 3.0; // Fade over ~0.3s
        if (_lightHitIntensity < 0) _lightHitIntensity = 0;
      }
  }

  @override
  void render(Canvas canvas) {
    if (opacity == 0) return;
    
    final rect = size.toRect();
    // ... [Render code kept mostly same, compacted for brevity in replacement if unchanged, but I must provide valid replacement]
    // Since I'm replacing a large block, I need to keep the render code.
    // I will use render_diffs logic by just copying the render method essentially or just replacing the top part if I can focus the chunk.
    // But Drag methods are at the bottom.
    // I'll rewrite the whole class structure in the replacement to be safe, but keep render body.
    
    final rrect = RRect.fromRectAndRadius(rect, const Radius.circular(6));
    
    // Check accessibility settings
    final bool reducedGlow = gameRef.settingsManager.reducedGlowEnabled;
    final bool highContrast = gameRef.settingsManager.highContrastEnabled;
    
    if (highContrast) {
      _basePaint.color = Colors.grey.shade800.withOpacity(opacity);
      canvas.drawRRect(rrect, _basePaint);
      _strokePaint
        ..color = Colors.white.withOpacity(opacity)
        ..strokeWidth = 2
        ..maskFilter = null;
      canvas.drawRRect(rrect, _strokePaint);
      return;
    }

    // === LAYER 1: Drop Shadow ===
    if (!reducedGlow) {
      final shadowRRect = rrect.shift(const Offset(2, 3));
      _glowPaint
        ..color = Colors.black.withOpacity(0.35 * opacity)
        ..maskFilter = _blur4;
      canvas.drawRRect(shadowRRect, _glowPaint);
    }

    // === LAYER 2: Golden Frame ===
    final frameGradient = LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [
        _frameGoldDark.withOpacity(opacity),
        _frameGoldLight.withOpacity(opacity),
        _frameGoldMid.withOpacity(opacity),
        _frameGoldDark.withOpacity(opacity),
      ],
      stops: const [0.0, 0.35, 0.65, 1.0],
    );
    
    _shaderPaint.shader = frameGradient.createShader(rect);
    canvas.drawRRect(rrect, _shaderPaint);
    
    // Frame inner shadow
    final innerShadowRRect = RRect.fromRectAndRadius(
      rect.deflate(1),
      const Radius.circular(5),
    );
    _strokePaint
      ..color = Colors.black.withOpacity(0.3 * opacity)
      ..strokeWidth = 1
      ..maskFilter = null;
    canvas.drawRRect(innerShadowRRect, _strokePaint);

    // === LAYER 3: Chrome Mirror Surface ===
    final innerRect = Rect.fromCenter(
      center: rect.center,
      width: size.x - 8,
      height: size.y - 5,
    );
    final innerRRect = RRect.fromRectAndRadius(innerRect, const Radius.circular(3));
    
    final chromeGradient = LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [
        _chromeDark.withOpacity(opacity),
        _chromeLight.withOpacity(0.95 * opacity),
        _chromeMid.withOpacity(opacity),
        _chromeDark.withOpacity(opacity),
      ],
      stops: const [0.0, 0.3, 0.7, 1.0],
    );
    
    _shaderPaint.shader = chromeGradient.createShader(innerRect);
    canvas.drawRRect(innerRRect, _shaderPaint);

    // === LAYER 4: Idle Shimmer ===
    if (!reducedGlow) {
      final shimmerPhase = (_time * 0.3) % 3.0; // Slow sweep every 3 seconds
      if (shimmerPhase < 1.0) {
        final shimmerPos = shimmerPhase * (size.x + 30) - 15;
        canvas.save();
        canvas.clipRRect(innerRRect);
        canvas.drawRect(
          Rect.fromLTWH(shimmerPos - 10, 0, 20, size.y),
          Paint()
            ..shader = LinearGradient(
              colors: [
                Colors.white.withOpacity(0.0),
                Colors.white.withOpacity(0.25 * opacity),
                Colors.white.withOpacity(0.0),
              ],
            ).createShader(Rect.fromLTWH(shimmerPos - 10, 0, 20, size.y)),
        );
        canvas.restore();
      }
    }

    // === LAYER 5: Rotation Shine Effect ===
    if (_shineOffset > -1.0 || _isRotating) {
      canvas.save();
      canvas.clipRRect(innerRRect);
      
      final glarePos = _shineOffset * size.x;
      canvas.drawRect(
        innerRect,
        Paint()
          ..shader = LinearGradient(
            colors: [
              Colors.white.withOpacity(0.0),
              Colors.white.withOpacity(0.95 * opacity),
              Colors.white.withOpacity(0.0),
            ],
            stops: const [0.0, 0.5, 1.0],
          ).createShader(Rect.fromLTWH(glarePos - 25, 0, 50, size.y)),
      );
      canvas.restore();
    }

    // === LAYER 6: Light Impact Glow ===
    if (_lightHitIntensity > 0 && !reducedGlow) {
      VisualEffects.drawCrystalGlow(
        canvas,
        rrect,
        _impactColor,
        intensity: _lightHitIntensity * 0.8,
        opacity: opacity,
        reducedGlow: false,
      );
      
      _glowPaint
        ..color = _impactColor.withOpacity(_lightHitIntensity * 0.4 * opacity)
        ..maskFilter = _blur3;
      canvas.drawRRect(innerRRect, _glowPaint);
    }

    // === LAYER 7: Frame Glow (Pulsing) ===
    if (!reducedGlow) {
      final pulseIntensity = 0.3 + 0.1 * sin(_time * 2.5);
      _strokePaint
        ..color = _glowColor.withOpacity(pulseIntensity * opacity)
        ..strokeWidth = 2
        ..maskFilter = _blur3;
      canvas.drawRRect(rrect, _strokePaint);
    }
    
    // === LAYER 8: Crisp Frame Border ===
    _strokePaint
      ..color = _frameGoldLight.withOpacity(0.9 * opacity)
      ..strokeWidth = 1
      ..maskFilter = null;
    canvas.drawRRect(rrect, _strokePaint);
    
    // Locked Indicator
    if (isLocked) {
      _basePaint.color = Colors.redAccent.withOpacity(opacity);
      canvas.drawCircle(Offset(size.x / 2, size.y / 2), 4, _basePaint);
      _basePaint.color = Colors.white.withOpacity(opacity);
      canvas.drawCircle(Offset(size.x / 2, size.y / 2), 2, _basePaint);
    }
  }
  
  // Physics Line Segment (Restored for DebugOverlay)
  Vector2 get startPoint {
    final localStart = Vector2(0, size.y / 2);
    return absolutePositionOf(localStart);
  }

  Vector2 get endPoint {
    final localEnd = Vector2(size.x, size.y / 2);
    return absolutePositionOf(localEnd);
  }

  void _triggerShine() {
      _isRotating = true;
      _shineOffset = -0.5; // Start off-left
  }
}


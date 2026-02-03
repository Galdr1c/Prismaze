import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import '../audio_manager.dart';
import '../prismaze_game.dart';
// import '../utils/visual_effects.dart'; // Removed broken import
import 'dart:math';

class Mirror extends PositionComponent with HasGameRef<PrismazeGame> {
  // Visual state
  double _shineOffset = -1.0;
  bool _isRotating = false;
  
  // Logic state
  bool isFixed;
  int discreteOrientation; // 0..3 (45 degree increments relative to base?)
  // Actually Mirror orientations are 0..7 in model, but often 4 visual states?
  // Model: 0..7.
  // Visual: 
  // 0: |
  // 1: /
  // 2: -
  // 3: \
  // Let's assume input maps 4 visual states.
  
  double opacity = 1.0;
  
  // Premium color scheme
  static const _frameGoldDark = Color(0xFFB8860B);
  static const _frameGoldLight = Color(0xFFFFD700);
  static const _frameGoldMid = Color(0xFFD4AF37); 
  static const _chromeDark = Color(0xFF8A9BAE);
  static const _chromeLight = Color(0xFFE8EEF4);
  static const _chromeMid = Color(0xFFB8C5D6);
  static const _glowColor = Color(0xFF64FFDA);
  static const _impactColor = Color(0xFFFFFFFF);

  // Cached Paints
  final Paint _basePaint = Paint();
  final Paint _strokePaint = Paint()..style = PaintingStyle.stroke;
  final Paint _glowPaint = Paint();
  final Paint _shaderPaint = Paint();
  
  static const _blur3 = MaskFilter.blur(BlurStyle.solid, 3);
  static const _blur4 = MaskFilter.blur(BlurStyle.normal, 4);

  Mirror({
    required Vector2 position,
    required int orientation, // 0..7 from model
    this.isFixed = false,
  }) : discreteOrientation = orientation,
       super(
          position: position,
          size: Vector2(75, 20),
          angle: _orientationToAngle(orientation),
          anchor: Anchor.center,
        );
  
  static double _orientationToAngle(int orientation) {
    // Model: 0..7.
    // 0: Vertical | (Angle 90 deg? or 0?)
    // In RayTracer, 0 assumed Vertical.
    // In Flame, Angle 0 is usually ---> (East) or ^ (North)?
    // Default Flame: 0 is Right (East), PI/2 is Down (South).
    // If Mirror 0 is |, it stands VERTICALLY.
    // A horizontal sprite rotated 90 deg.
    // Let's assume sprite is horizontal (width > height).
    // So 0 (|) -> 90 deg (PI/2).
    
    // RayTracer:
    // 0: |
    // 1: /
    // 2: -
    // 3: \
    
    // Mapping:
    switch (orientation % 4) {
      case 0: return pi / 2;    // |
      case 1: return pi / 4;    // \ (Wait, / is -45?)
             // / (NE-SW) means BottomLeft via TopRight.
             // Horizontal rotated -45 (CCW 45).
             // Flame +angle is CW.
             // Horizontal rotated -45 is /. 
             // Angle: -pi/4 (or 7pi/4).
             return -pi / 4;
      case 2: return 0;         // - (Horizontal)
      case 3: return pi / 4;    // \ (NW-SE)
      default: return 0;
    }
  }

  void rotate() {
      if (isFixed) return;
      
      // Cycle: 0 (|) -> 1 (/) -> 2 (-) -> 3 (\) -> 0
      // RayTracer logic: (ori + 1) % 4
      discreteOrientation = (discreteOrientation + 1) % 4;
      angle = _orientationToAngle(discreteOrientation);
      
      _triggerShine();
      // Sound played by Game
  }
  
  @override
  bool containsLocalPoint(Vector2 point) {
      // Standardize to grid cell size (85) with circular falloff for priority
      const double threshold = 42.5; // 85 / 2
      final center = size / 2;
      return (point - center).length <= threshold;
  }

  @override
  void update(double dt) {
      super.update(dt);
      
      if (_shineOffset > -1.0) {
          _shineOffset += dt * 2.5; 
          if (_shineOffset > 2.0) {
              _shineOffset = -1.0; 
              _isRotating = false;
          }
      }
  }

  @override
  void render(Canvas canvas) {
    if (opacity == 0) return;
    
    final rect = size.toRect();
    final rrect = RRect.fromRectAndRadius(rect, const Radius.circular(6));
    
    // Draw based on isFixed (Locked)
    // Reuse visual logic simplified
    
    // Shadow
    canvas.drawRRect(rrect.shift(const Offset(2, 3)), Paint()..color = Colors.black38..maskFilter=_blur4);
    
    // Frame
    _basePaint.color = isFixed ? Colors.grey[700]! : _frameGoldMid;
    canvas.drawRRect(rrect, _basePaint);
    
    // Inner Mirror
    final inner = rect.deflate(4);
    final innerR = RRect.fromRectAndRadius(inner, const Radius.circular(2));
    _basePaint.color = Colors.blueGrey[100]!;
    canvas.drawRRect(innerR, _basePaint);
    
    // Shine
    if (_shineOffset > -1.0) {
       canvas.save();
       canvas.clipRRect(innerR);
       final pos = _shineOffset * size.x;
       canvas.drawRect(
          Rect.fromLTWH(pos - 10, 0, 20, size.y), 
          Paint()..color=Colors.white.withOpacity(0.5)..blendMode=BlendMode.srcATop
       );
       canvas.restore();
    }
    
    // Lock Indicator
    if (isFixed) {
        canvas.drawCircle(Offset(size.x/2, size.y/2), 3, Paint()..color=Colors.red);
    }
  }

  void _triggerShine() {
      _isRotating = true;
      _shineOffset = -0.5;
  }
}

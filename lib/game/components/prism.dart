import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import '../prismaze_game.dart';
import 'dart:math';

class Prism extends PositionComponent with HasGameRef<PrismazeGame> {
  // Logic
  bool isFixed;
  int discreteOrientation; // 0..3 (90 degree increments)
  
  double opacity = 1.0;
  
  final Paint _basePaint = Paint();
  final Paint _strokePaint = Paint()..style = PaintingStyle.stroke;

  Prism({
    required Vector2 position,
    required int orientation,
    this.isFixed = false,
  }) : discreteOrientation = orientation,
       super(
          position: position,
          size: Vector2(75, 75),
          angle: _orientationToAngle(orientation),
          anchor: Anchor.center,
        );
        
  static double _orientationToAngle(int orientation) {
    return (orientation % 4) * pi / 2;
  }
  
  void rotate() {
      if (isFixed) return;
      discreteOrientation = (discreteOrientation + 1) % 4;
      angle = _orientationToAngle(discreteOrientation);
  }

  @override
  bool containsLocalPoint(Vector2 point) {
      // Standardize to grid cell size (85)
      const double threshold = 42.5;
      final center = size / 2;
      return (point - center).length <= threshold;
  }

  @override
  void render(Canvas canvas) {
    if (opacity == 0) return;
    
    final w = size.x;
    final h = size.y;
    final center = Offset(w/2, h/2);
    
    // Simple Diamond Shape
    final path = Path()
      ..moveTo(w/2, 0)
      ..lineTo(w, h/2)
      ..lineTo(w/2, h)
      ..lineTo(0, h/2)
      ..close();
      
    // Shadow
    canvas.drawPath(path.shift(const Offset(2, 3)), Paint()..color=Colors.black26..maskFilter=const MaskFilter.blur(BlurStyle.normal, 4));
    
    // Body
    _basePaint.color = const Color(0xFFE8F4FC).withOpacity(0.9);
    canvas.drawPath(path, _basePaint);
    
    // Outline
    _strokePaint
      ..color = isFixed ? Colors.grey : Colors.white
      ..strokeWidth = 2;
    canvas.drawPath(path, _strokePaint);
    
    // Inner Detail (Orientation Indicator)
    // Draw a small arrow or dot to show "North" if it matters for splitting?
    // Prism split usually T-shape. 
    // Let's draw the T-shape emitter ports?
    // N, E, W (relative).
    // Draw 3 dots.
    
    final r = w * 0.25;
    
    void drawDot(double theta, Color c) {
        final cx = w/2 + r * sin(theta);
        final cy = h/2 - r * cos(theta);
        canvas.drawCircle(Offset(cx, cy), 3, Paint()..color=c);
    }
    
    // Relative directions
    drawDot(0, Colors.red);      // N
    drawDot(pi/2, Colors.green); // E
    drawDot(-pi/2, Colors.blue); // W
    
    if (isFixed) {
        canvas.drawCircle(center, 4, Paint()..color=Colors.red);
    }
  }
}

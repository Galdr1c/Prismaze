import 'package:flame/components.dart';
import 'package:flutter/material.dart';

class GlassWall extends PositionComponent {
  
  GlassWall({
    required Vector2 position,
    required Vector2 size,
  }) : super(
         position: position,
         size: size,
         anchor: Anchor.center,
       );

  @override
  void render(Canvas canvas) {
    // Glassy body with simple pattern
    final rect = size.toRect();
    canvas.drawRect(
      rect,
      Paint()
        ..color = Colors.cyan.withOpacity(0.1)
        ..style = PaintingStyle.fill,
    );
    
    // Diagonal lines for texture
    final linePaint = Paint()
      ..color = Colors.cyan.withOpacity(0.3)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
      
    for (double i = 0; i < size.x + size.y; i += 10) {
        canvas.drawLine(
            Offset(0, i),
            Offset(i, 0), // Incorrect math for strict diagonal but creates a pattern
            linePaint
        );
    }
    
    // Border
    canvas.drawRect(
      rect,
      Paint()
        ..color = Colors.cyan.withOpacity(0.5)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1,
    );
  }
}


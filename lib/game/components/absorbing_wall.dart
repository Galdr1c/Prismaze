import 'package:flame/components.dart';
import 'package:flutter/material.dart';

/// AbsorbingWall - A wall that completely absorbs light (no reflection/refraction)
/// Light beams that hit this wall are stopped completely.
class AbsorbingWall extends PositionComponent {
  
  AbsorbingWall({
    required Vector2 position,
    required Vector2 size,
  }) : super(
         position: position,
         size: size,
         anchor: Anchor.center,
       );

  /// Returns the four corners for collision detection
  List<Vector2> get corners {
    final halfW = size.x / 2;
    final halfH = size.y / 2;
    return [
      absolutePosition + Vector2(-halfW, -halfH),
      absolutePosition + Vector2(halfW, -halfH),
      absolutePosition + Vector2(halfW, halfH),
      absolutePosition + Vector2(-halfW, halfH),
    ];
  }

  @override
  void render(Canvas canvas) {
    final rect = size.toRect();
    
    // Dark absorbing body
    canvas.drawRect(
      rect,
      Paint()
        ..color = const Color(0xFF1a1a2e)
        ..style = PaintingStyle.fill,
    );
    
    // Subtle dark purple glow
    canvas.drawRect(
      rect,
      Paint()
        ..color = const Color(0xFF4a1a5c).withOpacity(0.3)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8),
    );
    
    // Cross pattern indicating "no light passes"
    final centerX = size.x / 2;
    final centerY = size.y / 2;
    final crossSize = size.x * 0.3;
    
    final crossPaint = Paint()
      ..color = Colors.red.withOpacity(0.5)
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;
    
    canvas.drawLine(
      Offset(centerX - crossSize, centerY - crossSize),
      Offset(centerX + crossSize, centerY + crossSize),
      crossPaint,
    );
    canvas.drawLine(
      Offset(centerX + crossSize, centerY - crossSize),
      Offset(centerX - crossSize, centerY + crossSize),
      crossPaint,
    );
    
    // Border
    canvas.drawRect(
      rect,
      Paint()
        ..color = const Color(0xFF2d2d44)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );
  }
}


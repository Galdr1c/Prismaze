import 'package:flame/components.dart';
import 'package:flutter/material.dart';

class Splitter extends PositionComponent {
  
  Splitter({
    required Vector2 position,
    required Vector2 size,
    double angle = 0,
  }) : super(
         position: position,
         size: size,
         anchor: Anchor.center,
         angle: angle,
       );

  // Line segment representing surface
  Vector2 get startPoint => absolutePosition + (Vector2(-size.x/2, 0)..rotate(angle));
  Vector2 get endPoint => absolutePosition + (Vector2(size.x/2, 0)..rotate(angle));

  @override
  void render(Canvas canvas) {
    // Looks like a half-silvered mirror
    // Dashed line or specific icon?
    // Let's draw a box with a diagonal line
    
    // Rotate canvas for local drawing
    // Actually PositionComponent handles rotation for paint?
    // Yes if we draw relative to 0,0 (center if anchor is center? no, top left of component?)
    // PositionComponent.render receives canvas transformed to local coordinates?
    // Flame 1.0+: Yes, render is in local coordinates.
    // My previous components (Mirror) used absolute coordinates in render? 
    // Wait. Mirror render used `localStart`.
    
    final localStart = Vector2(0, size.y / 2);
    final localEnd = Vector2(size.x, size.y / 2);
    
    // Draw frame
    canvas.drawRect(size.toRect(), Paint()..color = Colors.grey.withOpacity(0.3)..style = PaintingStyle.stroke);
    
    // Draw "Splitter" diagonal
    canvas.drawLine(
        Offset(0,0),
        Offset(size.x, size.y),
        Paint()..color = Colors.white..strokeWidth = 2
    );
     canvas.drawLine(
        Offset(size.x,0),
        Offset(0, size.y),
        Paint()..color = Colors.white..strokeWidth = 2
    );
  }
}

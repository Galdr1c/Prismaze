import 'package:flame/components.dart';
import 'package:flutter/material.dart';

class Filter extends PositionComponent {
  final Color color;
  
  Filter({
    required Vector2 position,
    required Vector2 size,
    required this.color,
  }) : super(
         position: position,
         size: size,
         anchor: Anchor.center,
       );

  @override
  void render(Canvas canvas) {
    // Glassy body
    canvas.drawRect(
      size.toRect(),
      Paint()
        ..color = color.withOpacity(0.3)
        ..style = PaintingStyle.fill,
    );
    
    // Outline
    canvas.drawRect(
      size.toRect(),
      Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );
     
    // Inner Glow
    canvas.drawRect(
      size.toRect(),
      Paint()
        ..color = color.withOpacity(0.5)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10),
    );
  }
}

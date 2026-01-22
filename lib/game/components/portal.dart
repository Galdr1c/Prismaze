import 'package:flame/components.dart';
import 'package:flutter/material.dart';

class Portal extends PositionComponent {
  final int id;
  final int linkedPortalId;
  final Color color;
  
  Portal({
    required Vector2 position,
    required Vector2 size,
    required this.id,
    required this.linkedPortalId,
    this.color = Colors.purpleAccent,
    double angle = 0,
  }) : super(
         position: position,
         size: size,
         anchor: Anchor.center,
         angle: angle,
       );

  // Surface for intersection (flat portal)
  Vector2 get startPoint => absolutePosition + (Vector2(-size.x/2, 0)..rotate(angle));
  Vector2 get endPoint => absolutePosition + (Vector2(size.x/2, 0)..rotate(angle));

  @override
  void render(Canvas canvas) {
    // Glowing oval/portal effect
    final rect = size.toRect();
    
    // Outer Glow
    canvas.drawOval(
        rect, 
        Paint()
            ..color = color.withOpacity(0.5)
            ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 15)
    );
    
    // Core
    canvas.drawOval(
        rect.deflate(5),
        Paint()
            ..color = color
            ..style = PaintingStyle.stroke
            ..strokeWidth = 3
    );
    
    // Swirl/Vortex detail (Static for now)
    canvas.drawArc(
        rect.deflate(10), 
        0, 
        3.14, 
        false, 
        Paint()..color = Colors.white.withOpacity(0.5)..style = PaintingStyle.stroke..strokeWidth = 2
    );
  }
}


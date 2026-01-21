import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import '../prismaze_game.dart';
import '../game_bounds.dart';
import 'wall.dart';
import 'mirror.dart';
import 'prism.dart';
import 'target.dart';
import 'light_source.dart';

/// Debug visualization component for showing hitboxes and ray paths
/// Toggle via SettingsManager.debugModeEnabled
class DebugOverlay extends Component with HasGameRef<PrismazeGame> {
  // Intersection points collected during beam calculation
  final List<Vector2> _intersectionPoints = [];
  
  // Store current debug state
  bool _debugEnabled = false;
  
  @override
  int get priority => 1000; // Render on top of everything
  
  void addIntersectionPoint(Vector2 point) {
    _intersectionPoints.add(point);
  }
  
  void clearIntersectionPoints() {
    _intersectionPoints.clear();
  }
  
  @override
  void update(double dt) {
    // Check if debug mode changed
    _debugEnabled = gameRef.settingsManager.debugModeEnabled;
  }
  
  @override
  void render(Canvas canvas) {
    if (!_debugEnabled) return;
    
    // 1. Draw Play Area Boundary
    _drawPlayAreaBounds(canvas);
    
    // 2. Draw Wall Hitboxes
    _drawWallHitboxes(canvas);
    
    // 3. Draw Mirror Hitboxes
    _drawMirrorHitboxes(canvas);
    
    // 4. Draw Prism Hitboxes
    _drawPrismHitboxes(canvas);
    
    // 5. Draw Target Hitboxes
    _drawTargetHitboxes(canvas);
    
    // 6. Draw Light Source Hitboxes
    _drawLightSourceHitboxes(canvas);
    
    // 7. Draw Intersection Points
    _drawIntersectionPoints(canvas);
  }
  
  void _drawPlayAreaBounds(Canvas canvas) {
    final area = GameBounds.playArea;
    canvas.drawRect(
      area,
      Paint()
        ..color = Colors.cyan.withOpacity(0.3)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3,
    );
    
    // Draw grid
    const gridSize = 55.0;
    final gridPaint = Paint()
      ..color = Colors.cyan.withOpacity(0.1)
      ..strokeWidth = 1;
    
    for (double x = area.left; x <= area.right; x += gridSize) {
      canvas.drawLine(
        Offset(x, area.top),
        Offset(x, area.bottom),
        gridPaint,
      );
    }
    for (double y = area.top; y <= area.bottom; y += gridSize) {
      canvas.drawLine(
        Offset(area.left, y),
        Offset(area.right, y),
        gridPaint,
      );
    }
  }
  
  void _drawWallHitboxes(Canvas canvas) {
    final paint = Paint()
      ..color = Colors.red.withOpacity(0.5)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    
    for (final wall in gameRef.world.children.whereType<Wall>()) {
      final rect = Rect.fromLTWH(
        wall.position.x,
        wall.position.y,
        wall.size.x,
        wall.size.y,
      );
      canvas.drawRect(rect, paint);
      
      // Draw corner points
      for (final corner in wall.corners) {
        canvas.drawCircle(
          corner.toOffset(),
          4,
          Paint()..color = Colors.red,
        );
      }
    }
  }
  
  void _drawMirrorHitboxes(Canvas canvas) {
    final paint = Paint()
      ..color = Colors.green.withOpacity(0.5)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    
    for (final mirror in gameRef.world.children.whereType<Mirror>()) {
      // Draw collision rect
      final rect = Rect.fromCenter(
        center: Offset(mirror.position.x, mirror.position.y),
        width: mirror.size.x + 10,
        height: mirror.size.y + 10,
      );
      canvas.drawRect(rect, paint);
      
      // Draw reflection line
      canvas.drawLine(
        mirror.startPoint.toOffset(),
        mirror.endPoint.toOffset(),
        Paint()
          ..color = Colors.greenAccent
          ..strokeWidth = 3,
      );
      
      // Draw normal vector
      final center = (mirror.startPoint + mirror.endPoint) / 2;
      final surfaceDir = mirror.endPoint - mirror.startPoint;
      final normal = Vector2(-surfaceDir.y, surfaceDir.x).normalized() * 20;
      canvas.drawLine(
        center.toOffset(),
        (center + normal).toOffset(),
        Paint()
          ..color = Colors.yellow
          ..strokeWidth = 2,
      );
    }
  }
  
  void _drawPrismHitboxes(Canvas canvas) {
    final paint = Paint()
      ..color = Colors.purple.withOpacity(0.5)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    
    for (final prism in gameRef.world.children.whereType<Prism>()) {
      // Draw hitbox rect matching sprite bounds (60x60)
      final rect = Rect.fromCenter(
        center: Offset(prism.position.x, prism.position.y),
        width: prism.size.x,
        height: prism.size.y,
      );
      canvas.drawRect(rect, paint);
      
      // Draw center point
      canvas.drawCircle(
        Offset(prism.position.x, prism.position.y),
        4,
        Paint()..color = Colors.purple,
      );
      
      // Draw corner points for hitbox
      final corners = [
        Offset(rect.left, rect.top),
        Offset(rect.right, rect.top),
        Offset(rect.right, rect.bottom),
        Offset(rect.left, rect.bottom),
      ];
      for (final corner in corners) {
        canvas.drawCircle(corner, 3, Paint()..color = Colors.purpleAccent);
      }
    }
  }
  
  void _drawTargetHitboxes(Canvas canvas) {
    final paint = Paint()
      ..color = Colors.orange.withOpacity(0.5)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    
    for (final target in gameRef.world.children.whereType<Target>()) {
      canvas.drawCircle(
        target.position.toOffset(),
        target.size.x / 2,
        paint,
      );
      
      // Show status
      final statusText = target.isLit ? 'LIT' : 'OFF';
      final textPainter = TextPainter(
        text: TextSpan(
          text: statusText,
          style: TextStyle(
            color: target.isLit ? Colors.green : Colors.red,
            fontSize: 10,
            fontWeight: FontWeight.bold,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      
      textPainter.paint(
        canvas,
        Offset(target.position.x - 10, target.position.y + target.size.y / 2 + 5),
      );
    }
  }
  
  void _drawLightSourceHitboxes(Canvas canvas) {
    for (final source in gameRef.world.children.whereType<LightSource>()) {
      // Draw position
      canvas.drawCircle(
        source.position.toOffset(),
        10,
        Paint()
          ..color = Colors.white.withOpacity(0.5)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2,
      );
      
      // Draw beam direction
      final dir = Vector2(1, 0)..rotate(source.beamAngle);
      canvas.drawLine(
        source.position.toOffset(),
        (source.position + dir * 30).toOffset(),
        Paint()
          ..color = Colors.white
          ..strokeWidth = 3,
      );
    }
  }
  
  void _drawIntersectionPoints(Canvas canvas) {
    for (final point in _intersectionPoints) {
      // Outer ring
      canvas.drawCircle(
        point.toOffset(),
        8,
        Paint()
          ..color = Colors.yellow.withOpacity(0.5)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2,
      );
      // Inner dot
      canvas.drawCircle(
        point.toOffset(),
        3,
        Paint()..color = Colors.yellow,
      );
    }
  }
}

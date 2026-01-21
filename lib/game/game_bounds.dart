import 'package:flame/components.dart';
import 'package:flutter/widgets.dart';

class GameBounds {
  // Margins matching actual maze wall thickness (20px each side)
  static const double topMargin = 25.0;    // Just inside top wall
  static const double bottomMargin = 25.0; // Just inside bottom wall
  static const double sideMargin = 25.0;   // Just inside side walls
  
  static const double worldWidth = 1280.0;
  static const double worldHeight = 720.0;
  
  static Rect get playArea {
    return Rect.fromLTRB(
      sideMargin,
      topMargin,
      worldWidth - sideMargin,
      worldHeight - bottomMargin,
    );
  }
  
  // Clamp using Vector2 for Flame components
  static Vector2 clampPosition(Vector2 position, Vector2 objectSize) {
    final area = playArea;
    final halfW = objectSize.x / 2;
    final halfH = objectSize.y / 2;
    
    return Vector2(
      position.x.clamp(area.left + halfW, area.right - halfW),
      position.y.clamp(area.top + halfH, area.bottom - halfH),
    );
  }
}

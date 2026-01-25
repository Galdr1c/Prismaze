import 'package:flame/components.dart';
import '../procedural/models/game_objects.dart';

/// Centralized configuration for the game grid layout.
class GridConstants {
  // Grid dimensions
  static const int columns = 14;
  static const int rows = 7;
  
  // Cell sizing
  static const double cellSize = 85.0;
  static const double cellSizeHalf = cellSize / 2;
  
  // Offsets (to center grid in 1344x756 canvas)
  static const double offsetX = 45.0;
  static const double offsetY = 62.5;
  
  // Calculated values
  static const double gridWidth = columns * cellSize;
  static const double gridHeight = rows * cellSize;
  
  // Helper methods
  static Vector2 gridToWorld(GridPosition pos) {
    return Vector2(
      offsetX + pos.x * cellSize + cellSizeHalf,
      offsetY + pos.y * cellSize + cellSizeHalf,
    );
  }
  
  static GridPosition worldToGrid(Vector2 world) {
    final x = ((world.x - offsetX) / cellSize).floor();
    final y = ((world.y - offsetY) / cellSize).floor();
    return GridPosition(x, y);
  }
  
  static bool isValidPosition(GridPosition pos) {
    return pos.x >= 0 && 
           pos.x < columns && 
           pos.y >= 0 && 
           pos.y < rows;
  }
}

import '../../core/models/models.dart';
import '../../core/models/objects.dart';

/// Manages the generation of border wall objects around the playable grid.
class BorderManager {
  /// Creates a perimeter of WallObjects around the 6x12 grid.
  /// Play area is (0,0) to (5,11).
  /// Border is at x=-1, x=6, y=-1, y=12.
  static List<WallObject> createBorder() {
    final walls = <WallObject>[];
    
    // Top border (y = -1)
    // Range: x = -1 to 6
    for (int x = -1; x <= 6; x++) {
      walls.add(WallObject(
        position: GridPosition(x, -1),
        id: 'border_top_$x',
      ));
    }
    
    // Bottom border (y = 12)
    // Range: x = -1 to 6
    for (int x = -1; x <= 6; x++) {
      walls.add(WallObject(
        position: GridPosition(x, 12),
        id: 'border_bottom_$x',
      ));
    }
    
    // Left border (x = -1)
    // Range: y = 0 to 11 (corners handled by top/bottom loops)
    for (int y = 0; y < 12; y++) {
      walls.add(WallObject(
        position: GridPosition(-1, y),
        id: 'border_left_$y',
      ));
    }
    
    // Right border (x = 6)
    // Range: y = 0 to 11
    for (int y = 0; y < 12; y++) {
      walls.add(WallObject(
        position: GridPosition(6, y),
        id: 'border_right_$y',
      ));
    }
    
    return walls;
  }
}

import 'dart:ui';
import 'package:flame/components.dart'; // Provides Vector2
import 'package:flutter/foundation.dart';
import '../../core/constants/constants.dart';
import 'direction.dart';

/// Immutable position on the 6x12 grid.
@immutable
class GridPosition {
  final int x;
  final int y;

  const GridPosition(this.x, this.y);

  /// Creates a GridPosition from an index (y * width + x)
  factory GridPosition.fromIndex(int index, {int width = 6}) {
    return GridPosition(index % width, index ~/ width);
  }

  /// Returns true if the position is within the 6x12 grid bounds.
  bool get isValid => x >= 0 && x < 6 && y >= 0 && y < 12;

  /// Returns a new GridPosition moved one step in the given direction.
  GridPosition step(Direction dir) {
    return GridPosition(x + dir.dx, y + dir.dy);
  }

  /// Returns a new GridPosition shifted by a custom amount.
  GridPosition shift(int dx, int dy) {
    return GridPosition(x + dx, y + dy);
  }

  /// Checks if this position is a neighbor of the other position.
  bool isNeighbor(GridPosition other) {
    var diffX = (x - other.x).abs();
    var diffY = (y - other.y).abs();
    return (diffX == 1 && diffY == 0) || (diffX == 0 && diffY == 1);
  }

  /// Converts pixel coordinates back to a GridPosition.
  factory GridPosition.fromPixel(Vector2 pixelPos, double cellSize) {
    int x = (pixelPos.x / cellSize).floor();
    int y = (pixelPos.y / cellSize).floor();
    return GridPosition(x, y);
  }

  /// Converts grid position to pixel coordinates (center of the cell).
  /// [cellSize] is the size of one grid square in pixels.
  Offset toPixel(double cellSize) {
    // x * cellSize + cellSize / 2
    return Offset((x + 0.5) * cellSize, (y + 0.5) * cellSize);
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is GridPosition && other.x == x && other.y == y;
  }

  /// Deterministic hashCode: index in row-major order.
  /// Uniquely identifies position for grids up to thousands of columns.
  @override
  int get hashCode => y * 1000 + x;

  @override
  String toString() => 'GridPosition($x, $y)';
}

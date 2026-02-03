import 'package:flutter/foundation.dart';
import '../../core/models/grid_position.dart';
import '../../core/models/direction.dart';

/// Base class for all interactive objects on the grid.
@immutable
abstract class GameObject {
  final GridPosition position;
  final int orientation; // 0=North, 1=East, 2=South, 3=West
  final bool rotatable;
  final String id; // Optional unique ID for serialization clarity

  const GameObject({
    required this.position,
    this.orientation = 0,
    this.rotatable = false,
    String? id,
  }) : id = id ?? '';

  /// Returns the current Direction based on orientation index.
  Direction get direction => Direction.fromInt(orientation);

  /// Creates a copy of this object with a new position.
  GameObject moveTo(GridPosition newPosition);
  
  /// Creates a copy of this object with a new orientation (if rotatable).
  GameObject rotateRight({bool force = false}) {
    if (!rotatable && !force) return this;
    return copyWith(orientation: (orientation + 1) % 4);
  }

  /// Creates a copy of this object with a new orientation (if rotatable).
  GameObject rotateLeft({bool force = false}) {
    if (!rotatable && !force) return this;
    return copyWith(orientation: (orientation - 1 + 4) % 4);
  }
  
  /// Abstract copyWith to be implemented by subclasses
  GameObject copyWith({
    GridPosition? position,
    int? orientation,
    bool? rotatable,
  });

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is GameObject &&
        other.runtimeType == runtimeType &&
        other.position == position &&
        other.orientation == orientation &&
        other.rotatable == rotatable;
  }

  @override
  int get hashCode => Object.hash(position, orientation, rotatable, runtimeType);
  
  @override
  String toString() {
    return '$runtimeType(pos: $position, ori: $direction)';
  }
}

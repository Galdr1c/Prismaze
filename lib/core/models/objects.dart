import 'game_object.dart';
import 'light_color.dart';
import 'package:prismaze/core/models/models.dart'; // For GridPosition

class SourceObject extends GameObject {
  final int orientation; // 0..3 (North, East, South, West)
  final LightColor color;

  const SourceObject({
    required super.position,
    required this.orientation,
    required this.color,
    super.id,
    super.rotatable = false,
  });

  @override
  SourceObject copyWith({
    GridPosition? position,
    int? orientation,
    bool? rotatable,
    LightColor? color,
  }) {
    return SourceObject(
      position: position ?? this.position,
      orientation: orientation ?? this.orientation,
      color: color ?? this.color,
      id: id,
      rotatable: rotatable ?? this.rotatable,
    );
  }

  @override
  SourceObject moveTo(GridPosition newPosition) {
    return copyWith(position: newPosition);
  }

  @override
  String toString() => 'SourceObject(pos: $position, ori: $orientation, color: $color)';
}

class MirrorObject extends GameObject {
  final int orientation; // 0..7

  const MirrorObject({
    required super.position,
    required this.orientation,
    super.id,
    super.rotatable = true, // Mirrors usually rotatable
  });

  @override
  MirrorObject copyWith({
    GridPosition? position,
    int? orientation,
    bool? rotatable,
  }) {
    return MirrorObject(
      position: position ?? this.position,
      orientation: orientation ?? this.orientation,
      id: id,
      rotatable: rotatable ?? this.rotatable,
    );
  }

  @override
  MirrorObject moveTo(GridPosition newPosition) {
    return copyWith(position: newPosition);
  }
  
  @override
  String toString() => 'MirrorObject(pos: $position, ori: $orientation)';
}

class TargetObject extends GameObject {
  final LightColor requiredColor;

  const TargetObject({
    required super.position,
    required this.requiredColor,
    super.id,
    super.rotatable = false,
  });

  @override
  TargetObject copyWith({
    GridPosition? position,
    int? orientation,
    bool? rotatable,
    LightColor? requiredColor,
  }) {
    return TargetObject(
      position: position ?? this.position,
      requiredColor: requiredColor ?? this.requiredColor,
      id: id,
      rotatable: rotatable ?? this.rotatable,
    );
  }

  @override
  TargetObject moveTo(GridPosition newPosition) {
    return copyWith(position: newPosition);
  }
  
  @override
  String toString() => 'TargetObject(pos: $position, color: $requiredColor)';
}

class WallObject extends GameObject {
  const WallObject({
    required super.position,
    super.id,
  });

  @override
  WallObject copyWith({
    GridPosition? position,
    int? orientation,
    bool? rotatable,
  }) {
    return WallObject(
      position: position ?? this.position,
      id: id,
    );
  }

  @override
  WallObject moveTo(GridPosition newPosition) {
    return copyWith(position: newPosition);
  }
  
  @override
  String toString() => 'WallObject(pos: $position)';
}

class PrismObject extends GameObject {
  const PrismObject({
    required super.position,
    super.orientation = 0,
    super.id,
    super.rotatable = true, // Prisms usually rotatable
  });

  @override
  PrismObject copyWith({
    GridPosition? position,
    int? orientation,
    bool? rotatable,
  }) {
    return PrismObject(
      position: position ?? this.position,
      orientation: orientation ?? this.orientation,
      id: id,
      rotatable: rotatable ?? this.rotatable,
    );
  }

  @override
  PrismObject moveTo(GridPosition newPosition) {
    return copyWith(position: newPosition);
  }
  
  @override
  String toString() => 'PrismObject(pos: $position, ori: $orientation)';
}

class BlockerObject extends GameObject {
  const BlockerObject({
    required super.position,
    super.id,
  });

  @override
  BlockerObject copyWith({
    GridPosition? position,
    int? orientation,
    bool? rotatable,
  }) {
    return BlockerObject(
      position: position ?? this.position,
      id: id,
    );
  }

  @override
  BlockerObject moveTo(GridPosition newPosition) {
    return copyWith(position: newPosition);
  }
  
  @override
  String toString() => 'BlockerObject(pos: $position)';
}

class PortalObject extends GameObject {
  final int linkedId;
  final bool isEntry;

  const PortalObject({
    required super.position,
    required this.linkedId,
    this.isEntry = true,
  });

  @override
  PortalObject copyWith({
    GridPosition? position,
    int? orientation,
    bool? rotatable,
    int? linkedId,
    bool? isEntry,
  }) {
    return PortalObject(
      position: position ?? this.position,
      linkedId: linkedId ?? this.linkedId,
      isEntry: isEntry ?? this.isEntry,
    );
  }

  @override
  PortalObject moveTo(GridPosition newPosition) {
    return copyWith(position: newPosition);
  }
  
  @override
  String toString() => 'PortalObject(pos: $position, link: $linkedId)';
}

import 'package:flame/components.dart';
import 'package:flutter/material.dart'; // For Offset
import '../../generator/models/generated_level.dart';
import '../../core/models/objects.dart';
import '../../core/models/light_color.dart'; // Explicit Import
import 'light_source.dart';
import 'mirror.dart';
import 'wall.dart';
import 'target.dart';
import 'prism.dart';
import 'absorbing_wall.dart';

/// Factory to convert immutable Data Objects into Flame Components.
class ObjectFactory {
  // Prismaze Constants
  static const double cellSize = 85.0;

  /// Creates a list of Flame components representing the level.
  static List<PositionComponent> createComponents(GeneratedLevel level) {
    final components = <PositionComponent>[];
    
    for (var obj in level.objects) {
       // Convert GridPosition -> Vector2
       final off = obj.position.toPixel(cellSize);
       final vecPos = Vector2(off.dx, off.dy);
       
       if (obj is SourceObject) {
         components.add(LightSource(
            position: vecPos,
            // SourceObject orientation usually int 0-3 (N,E,S,W).
            // LightSource expects radians.
            // Map int -> rads.
            angle: _orientationToRad(obj.orientation),
            color: obj.color.toFlutterColor(),
         ));
       } else if (obj is MirrorObject) {
         components.add(Mirror(
            position: vecPos,
            orientation: obj.orientation, // Passes int model ori
            isFixed: !obj.rotatable, 
         ));
       } else if (obj is WallObject) {
         components.add(Wall(
            position: vecPos,
            size: Vector2(cellSize, cellSize),
         ));
       } else if (obj is TargetObject) {
         components.add(Target(
            position: vecPos,
            requiredColor: obj.requiredColor.toFlutterColor(),
         ));
       } else if (obj is PrismObject) {
         components.add(Prism(
            position: vecPos,
            orientation: obj.orientation,
            isFixed: !obj.rotatable,
         ));
       } else if (obj is BlockerObject) {
         components.add(AbsorbingWall(
            position: vecPos,
            size: Vector2(cellSize, cellSize),
         ));
       }
    }
    
    return components;
  }
  
  static double _orientationToRad(int ori) {
      // 0: N, 1: E, 2: S, 3: W
      // Standard Flame: 0 is Right (E). 
      // If 0 is N, then -pi/2.
      // But typically check Direction.dart?
      // Direction(0,-1) -> N.
      // E(1,0). S(0,1). W(-1,0).
      
      // Let's assume standard geometric:
      // 0 (N) -> -pi/2
      // 1 (E) -> 0
      // 2 (S) -> pi/2
      // 3 (W) -> pi
      
      // OR Prismaze Direction enum order?
      // 0: N, 1: E, 2: S, 3: W.
      switch (ori % 4) {
          case 0: return -3.14159 / 2;
          case 1: return 0;
          case 2: return 3.14159 / 2;
          case 3: return 3.14159;
          default: return 0;
      }
  }
}

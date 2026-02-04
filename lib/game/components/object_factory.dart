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
import 'border_frame.dart';
import '../../core/models/grid_position.dart';
import 'wall_cluster.dart';

/// Factory to convert immutable Data Objects into Flame Components.
class ObjectFactory {
  // Prismaze Constants
  static const double cellSize = 85.0;

  /// Creates a list of Flame components representing the level.
  static List<PositionComponent> createComponents(GeneratedLevel level) {
    final components = <PositionComponent>[];
    
    // 1. Separate Walls for Clustering
    final wallObjects = <WallObject>[];
    
    // 2. Process non-wall objects immediately, collect walls
    for (var obj in level.objects) {
       // Convert GridPosition -> Vector2
       final off = obj.position.toPixel(cellSize);
       final vecPos = Vector2(off.dx, off.dy);
       
       if (obj is SourceObject) {
         components.add(LightSource(
            position: vecPos,
            angle: _orientationToRad(obj.orientation),
            color: obj.color.toFlutterColor(),
         ));
       } else if (obj is MirrorObject) {
         components.add(Mirror(
            position: vecPos,
            orientation: obj.orientation,
            isFixed: !obj.rotatable, 
         ));
       } else if (obj is WallObject) {
         // Skip border walls - they're only for logic
         if (obj.id?.startsWith('border_') ?? false) continue;
         wallObjects.add(obj);
       } else if (obj is BlockerObject) {
         // User requested to treat Blockers as normal walls
         // Create a temporary WallObject wrapper or just add to walls if logic permits
         // WallObject and BlockerObject roughly same data?
         // Converting Blocker to Wall for visual clustering
         wallObjects.add(WallObject(
           position: obj.position,
           id: obj.id, 
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
       }

    }
    
    // 3. Cluster Walls
    final clusters = _clusterWalls(wallObjects);
    for (final clusterSet in clusters) {
      components.add(WallCluster(gridPositions: clusterSet));
    }
    
    // Add thin aesthetic border frame around the grid
    final gridWidth = 6 * cellSize;  // 510
    final gridHeight = 12 * cellSize; // 1020
    components.add(BorderFrame(
      position: Vector2(0, 0),
      gridWidth: gridWidth,
      gridHeight: gridHeight,
    ));
    
    return components;
  }
  
  /// Group adjacent wall positions into clusters
  static List<Set<GridPosition>> _clusterWalls(List<WallObject> walls) {
    final positions = walls.map((w) => w.position).toSet();
    final clusters = <Set<GridPosition>>[];
    
    while (positions.isNotEmpty) {
      final start = positions.first;
      final currentCluster = <GridPosition>{};
      final queue = <GridPosition>[start];
      
      positions.remove(start);
      currentCluster.add(start);
      
      while (queue.isNotEmpty) {
        final current = queue.removeAt(0);
        
        // Check 4 directions
        final neighbors = [
          GridPosition(current.x + 1, current.y),
          GridPosition(current.x - 1, current.y),
          GridPosition(current.x, current.y + 1),
          GridPosition(current.x, current.y - 1),
        ];
        
        for (final n in neighbors) {
          if (positions.contains(n)) {
            positions.remove(n);
            currentCluster.add(n);
            queue.add(n);
          }
        }
      }
      clusters.add(currentCluster);
    }
    return clusters;
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

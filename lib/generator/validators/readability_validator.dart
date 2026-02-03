import '../models/generated_level.dart';
import '../../core/models/models.dart';
import '../pipeline/headless_ray_tracer.dart';
import '../../core/utils/deterministic_hash.dart';

class ReadabilityValidator {
  static const int sourceSafeZoneRadius = 2;
  static const int targetSafeZoneRadius = 1;
  static const int maxBeamCrossings = 8; // Recommended for vertical grid

  /// Validates readability and ergonomics metrics.
  static List<String> validate(GeneratedLevel level) {
    final errors = <String>[];
    
    // 1. Safe Zone Carving
    errors.addAll(_validateSafeZones(level));
    
    // 2. Beam Crossing Limit
    final stats = HeadlessRayTracer.trace(level);
    if (stats.crossingCount > maxBeamCrossings) {
      errors.add('Too much visual noise: $maxBeamCrossings crossings allowed, found ${stats.crossingCount}');
    }
    
    return errors;
  }

  static List<String> _validateSafeZones(GeneratedLevel level) {
    final errors = <String>[];
    final interactivePositions = level.objects
        .where((obj) => obj is! WallObject && obj is! BlockerObject)
        .map((obj) => obj.position)
        .toSet();

    for (var obj in level.objects) {
      if (obj is SourceObject) {
        // Source should have no interactive objects or walls within radius 2?
        // Actually, "Safe-Zone" usually means "no other rotatable objects" 
        // to avoid tap collisions.
        for (int dx = -sourceSafeZoneRadius; dx <= sourceSafeZoneRadius; dx++) {
          for (int dy = -sourceSafeZoneRadius; dy <= sourceSafeZoneRadius; dy++) {
            if (dx == 0 && dy == 0) continue;
            final pos = GridPosition(obj.position.x + dx, obj.position.y + dy);
            if (interactivePositions.contains(pos)) {
              errors.add('Source safe-zone violation at ${obj.position}: interactive object at $pos');
            }
          }
        }
      } else if (obj is TargetObject) {
        for (int dx = -targetSafeZoneRadius; dx <= targetSafeZoneRadius; dx++) {
          for (int dy = -targetSafeZoneRadius; dy <= targetSafeZoneRadius; dy++) {
            if (dx == 0 && dy == 0) continue;
            final pos = GridPosition(obj.position.x + dx, obj.position.y + dy);
            if (interactivePositions.contains(pos)) {
              errors.add('Target safe-zone violation at ${obj.position}: interactive object at $pos');
            }
          }
        }
      }
    }
    return errors;
  }

  /// Calculates a silhouette hash for diversity tracking.
  static String calculateSilhouetteHash(GeneratedLevel level) {
    final buffer = StringBuffer();
    
    // 1. Wall Mask
    final wallPositions = level.objects
        .where((obj) => obj is WallObject)
        .map((obj) => obj.position)
        .toList()
      ..sort((a, b) => a.hashCode.compareTo(b.hashCode));
    
    buffer.write('walls:');
    for (var p in wallPositions) {
      buffer.write('${p.x},${p.y};');
    }

    // 2. Object Distribution (Types and Positions)
    final otherObjects = level.objects
        .where((obj) => obj is! WallObject)
        .toList()
      ..sort((a, b) => a.position.hashCode.compareTo(b.position.hashCode));
    
    buffer.write('objs:');
    for (var obj in otherObjects) {
      buffer.write('${obj.runtimeType}@${obj.position.x},${obj.position.y};');
    }

    return DeterministicHash.hash(buffer.toString()).toString();
  }
}

import '../models/generated_level.dart';
import '../../core/models/models.dart';

class GeometryValidator {
  static const int _width = 6;
  static const int _height = 12;

  /// Validates the geometry of the generated level.
  /// Returns a list of failure reasons. Empty if valid.
  static List<String> validate(GeneratedLevel level) {
    final errors = <String>[];
    final grid = <int, GameObject>{};

    for (var obj in level.objects) {
      // Skip border walls - they're intentionally at out-of-bounds positions
      if (obj is WallObject && (obj.id?.startsWith('border_') ?? false)) {
        continue;
      }
      
      // 1. Bounds Check
      if (!obj.position.isValid) {
        errors.add('Object out of bounds at ${obj.position}: ${obj.runtimeType}');
        continue;
      }

      // 2. Overlap Check
      final hash = obj.position.hashCode;
      if (grid.containsKey(hash)) {
        errors.add('Overlap detected at ${obj.position}: ${grid[hash].runtimeType} vs ${obj.runtimeType}');
      } else {
        grid[hash] = obj;
      }
    }

    // 3. Safe Zone Checks (Optional but requested)
    // Source should have at least 1 empty neighbor?
    // Target should be accessible?
    // For now, bounds and overlap are CRITICAL.
    
    return errors;
  }
}

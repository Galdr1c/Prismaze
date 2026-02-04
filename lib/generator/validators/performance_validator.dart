import '../models/generated_level.dart';
import '../../core/models/models.dart';
import '../../core/models/objects.dart';

class PerformanceValidator {
  static const int maxTotalObjects = 50;
  static const int maxInteractiveObjects = 15;

  static bool validate(GeneratedLevel level) {
    // Exclude border walls from count - they're infrastructure, not content
    final nonBorderObjects = level.objects.where((o) => 
      !(o is WallObject && (o.id?.startsWith('border_') ?? false))
    ).length;
    if (nonBorderObjects > maxTotalObjects) return false;
    
    final interactive = level.objects.where((o) => 
      o is MirrorObject || o is PrismObject || o is PortalObject
    ).length;
    
    if (interactive > maxInteractiveObjects) return false;
    
    return true;
  }
}

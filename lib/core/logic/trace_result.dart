import '../models/models.dart';

/// Represents a single segment of a light beam for visualization.
class RaySegment {
  final GridPosition start;
  final GridPosition end;
  final LightColor color;

  const RaySegment(this.start, this.end, this.color);
  
  @override
  String toString() => 'Ray($start -> $end, $color)';
}

/// The result of a full ray trace simulation.
class TraceResult {
  /// All beam segments generated during the trace.
  final List<RaySegment> segments;

  /// Map of Hit Object ID (or Position Hash) to the set of colors it received.
  /// Using Position Hash for now as IDs might overlap or be missing.
  final Map<int, Set<int>> hitMap; // PosHash -> Set<ColorMask>

  /// Whether all target objects in the level have their required colors met AND
  /// only those received.
  final bool success;

  const TraceResult({
    required this.segments,
    required this.hitMap,
    required this.success,
  });
  
  static TraceResult empty() => const TraceResult(segments: [], hitMap: {}, success: false);
}

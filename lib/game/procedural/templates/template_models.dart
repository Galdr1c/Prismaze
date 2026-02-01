import '../models/models.dart';

enum ObjectType {
  source,
  target,
  mirror,
  prism,
  wall,
}

/// Core template definition for hybrid generation
class LevelTemplate {
  /// Unique identifier (e.g., 'e1_simple_reflection')
  final String id;
  
  /// Display name (localized key)
  final String nameKey;
  
  /// Target episode
  final int episode;
  
  /// Difficulty rating (1-10)
  final int difficulty;
  
  /// Template family (for grouping/selection)
  final String family;
  
  /// Fixed objects (guaranteed positions/types)
  final List<FixedObject> fixedObjects;
  
  /// Variable objects (randomized positions/orientations)
  final List<VariableObject> variableObjects;
  
  /// Parameters that can vary between instances
  final List<TemplateVariable> variables;
  
  /// Solved state (for scrambling reference)
  final SolvedState solvedState;
  
  /// Generation constraints
  final TemplateConstraints constraints;
  
  /// Metadata
  final TemplateMetadata metadata;

  const LevelTemplate({
    required this.id,
    required this.nameKey,
    required this.episode,
    required this.difficulty,
    required this.family,
    required this.fixedObjects,
    required this.variableObjects,
    required this.variables,
    required this.solvedState,
    this.constraints = const TemplateConstraints(),
    this.metadata = const TemplateMetadata(),
  });
}

/// Fixed object (exact position/type)
class FixedObject {
  final ObjectType type;
  final GridPosition position;  // Exact cell
  final int orientation;        // 0-3
  final Map<String, dynamic> properties;  // color, locked, etc.
  
  const FixedObject({
    required this.type,
    required this.position,
    required this.orientation,
    this.properties = const {},
  });
}

/// Variable object (position/orientation determined by variables)
class VariableObject {
  final ObjectType type;
  final String id;  // e.g., "mirror1", "prism_main"
  
  // Position can reference variables
  final PositionExpression positionExpr;  // e.g., "{baseX} + {offset1}"
  
  // Orientation can reference variables
  final OrientationExpression orientationExpr;  // e.g., "({solved} + {scramble1}) % 4"
  
  final Map<String, dynamic> properties;
  
  const VariableObject({
    required this.type,
    required this.id,
    required this.positionExpr,
    required this.orientationExpr,
    this.properties = const {},
  });
}

/// Variable parameter
class TemplateVariable {
  final String name;          // e.g., "scramble1"
  final VariableType type;    // int, position, orientation
  final int minValue;
  final int maxValue;
  final int? defaultValue;
  
  const TemplateVariable({
    required this.name,
    required this.type,
    required this.minValue,
    required this.maxValue,
    this.defaultValue,
  });
}

enum VariableType {
  integer,        // Generic int
  orientation,    // 0-3 (for rotations)
  xCoordinate,    // 0-13 (grid X)
  yCoordinate,    // 0-6 (grid Y)
  offset,         // -2 to +2 (position adjustments)
  scramble,       // 1-3 (rotations from solved)
}

/// Expression for dynamic positioning
class PositionExpression {
  final String xExpr;
  final String yExpr;

  const PositionExpression({required this.xExpr, required this.yExpr});

  // Convenience constructors
  factory PositionExpression.static(int x, int y) {
    return PositionExpression(xExpr: '$x', yExpr: '$y');
  }

  factory PositionExpression.variable(String xVar, String yVar) {
    return PositionExpression(xExpr: '\$$xVar', yExpr: '\$$yVar');
  }
}

/// Expression for dynamic orientation
class OrientationExpression {
  final String expression; // e.g., "$solved" or "$solved + $scramble"

  const OrientationExpression(this.expression);
  
  factory OrientationExpression.static(int orientation) {
    return OrientationExpression('$orientation');
  }
  
  factory OrientationExpression.scramble(String scrambleVar) {
    return OrientationExpression('\$solved + \$$scrambleVar');
  }
}

/// Solved state reference
class SolvedState {
  /// Object orientations in solved configuration (key: objectId)
  final Map<String, int> orientations;
  
  /// Expected solution sequence
  final List<SolutionStep> steps; // Using existing SolutionStep model might be complex if it depends on specific types, define simplified or use existing if compatible.

  /// Total moves in optimal solution
  final int totalMoves;
  
  const SolvedState({
    required this.orientations,
    required this.steps, // We might need to map this to the real SolutionStep later
    required this.totalMoves,
  });
}

/// Simplified solution step for templates
class SolutionStep {
  final String objectId;
  final int taps;
  
  const SolutionStep(this.objectId, this.taps);
}

/// Generation constraints
class TemplateConstraints {
  /// Minimum distance between prism and source
  final int minPrismSourceDistance;
  
  /// Objects that must not overlap (groups of IDs)
  final List<List<String>> noOverlapGroups;
  
  const TemplateConstraints({
    this.minPrismSourceDistance = 2,
    this.noOverlapGroups = const [],
  });
}

/// Template metadata
class TemplateMetadata {
  final String author;
  final String? description;
  final List<String> tags;
  
  const TemplateMetadata({
    this.author = 'System',
    this.description,
    this.tags = const [],
  });
}

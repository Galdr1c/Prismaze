import 'package:flutter/foundation.dart';
import '../../core/models/models.dart';
import 'template_family.dart';

/// Defines a fixed object position in the template.
@immutable
class Anchor {
  final GridPosition position;
  final String type; // e.g., 'mirror', 'prism', 'target', 'source'
  final int? initialOrientation; // Optional fixed orientation
  final int? solutionOrientation; // The correct orientation for the solution
  final LightColor? requiredColor; // Specifically for targets/sources

  const Anchor({
    required this.position,
    required this.type,
    this.initialOrientation,
    this.requiredColor,
    this.solutionOrientation,
  });
}

/// Defines a position that can dynamically hold an object based on the seed.
@immutable
class VariableSlot {
  final GridPosition position;
  final List<String> allowedTypes; // e.g., ['mirror', 'blocker']
  final double probability; // 0.0 - 1.0 chance to be filled

  const VariableSlot({
    required this.position,
    this.allowedTypes = const [],
    this.probability = 1.0,
  });
}

/// Defines a deterministic wall layout.
@immutable
class WallPattern {
  final List<GridPosition> walls;
  
  const WallPattern(this.walls);
}

/// Abstract definition of a step required to solve the level.
/// Used for validation to ensure the generated level is theoretically solvable.
/// 
/// Standard: References a unique cell [position] and the final [targetOrientation].
@immutable
class SolutionStep {
  final GridPosition position;
  final int targetOrientation;
  final String? description;

  const SolutionStep({
    required this.position,
    required this.targetOrientation,
    this.description,
  });
}

/// [Merge Rule Contract]
/// 1. Merging is SPATIALLY ADDITIVE: Any color mask passing through a target contributes to its state.
/// 2. Merging is INDEPENDENT of arrival time: Static simulation treats all rays as simultaneous.
/// 3. Standard Model: R+G=Y, G+B=C, R+B=M, R+G+B=W (White).


/// Constraint rules for ensuring the level remains readable.
@immutable
class ReadabilityConstraints {
  final int maxObjects;
  final int maxColors;
  final int minSpacing; // Minimum cells between interactive objects

  const ReadabilityConstraints({
    this.maxObjects = 10,
    this.maxColors = 3,
    this.minSpacing = 1,
  });
}

/// The blueprint for a specific structural layout.
@immutable
class Template {
  final TemplateFamily family;
  final int variantId;
  final List<Anchor> anchors;
  final List<VariableSlot> variableSlots;
  final List<WallPattern> wallPresets;
  final List<SolutionStep> solutionSteps;
  final ReadabilityConstraints readabilityRules;

  const Template({
    required this.family,
    required this.variantId,
    required this.anchors,
    required this.variableSlots,
    required this.wallPresets,
    required this.solutionSteps,
    this.readabilityRules = const ReadabilityConstraints(),
  });
  
  String get id => "${family.name}_v$variantId";
}

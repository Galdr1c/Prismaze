import 'package:flutter/foundation.dart';
import '../../core/models/models.dart';
import '../templates/template_models.dart';

/// Represents a fully generated level, ready for validation or play.
@immutable
class GeneratedLevel {
  final int id; // Level Index
  final int seed;
  final Template template;
  final List<GameObject> objects;
  final WallPattern appliedWallPattern;
  final String signature; // Recipe fingerprint for validation

  const GeneratedLevel({
    required this.id,
    required this.seed,
    required this.template,
    required this.objects,
    required this.appliedWallPattern,
    required this.signature,
  });

  GeneratedLevel copyWith({
    int? id,
    int? seed,
    Template? template,
    List<GameObject>? objects,
    WallPattern? appliedWallPattern,
    String? signature,
  }) {
    return GeneratedLevel(
      id: id ?? this.id,
      seed: seed ?? this.seed,
      template: template ?? this.template,
      objects: objects ?? this.objects,
      appliedWallPattern: appliedWallPattern ?? this.appliedWallPattern,
      signature: signature ?? this.signature,
    );
  }

  /// The 'Par' (ideal moves) is strictly the number of solution steps (HATA 4).
  int get par => template.solutionSteps.length;

  @override
  String toString() => 'GeneratedLevel(id: $id, sig: ${signature.substring(0, 8)})';
}

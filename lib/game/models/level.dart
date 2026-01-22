import 'dart:convert';
import 'package:flame/components.dart';

/// Represents the data structure of a level, decoupled from the game engine.
class Level {
  final int id;
  final int optimalMoves; // 'par'
  final String? solution;
  final List<LevelObject> objects;

  Level({
    required this.id,
    required this.optimalMoves,
    this.solution,
    required this.objects,
  });

  factory Level.fromJson(Map<String, dynamic> json) {
    return Level(
      id: json['id'] as int? ?? 0,
      optimalMoves: json['par'] as int? ?? 0,
      solution: json['solution'] as String?,
      objects: (json['objects'] as List<dynamic>?)
              ?.map((e) => LevelObject.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }
}

class LevelObject {
  final String type;
  final double x;
  final double y;
  final double angle;
  final String? color;
  final double width;
  final double height;
  final bool locked;
  final int sequence;
  final double interval;
  final double delay;
  final int linkedId; // For portals
  final List<Vector2> waypoints; // For moving behaviors
  final double speed;

  LevelObject({
    required this.type,
    required this.x,
    required this.y,
    this.angle = 0,
    this.color,
    this.width = 0,
    this.height = 0,
    this.locked = false,
    this.sequence = 0,
    this.interval = 0,
    this.delay = 0,
    this.linkedId = 0,
    this.waypoints = const [],
    this.speed = 0,
  });

  factory LevelObject.fromJson(Map<String, dynamic> json) {
    var wpList = (json['waypoints'] as List? ?? []);
    var waypoints = wpList.map((p) => Vector2((p['x'] as num).toDouble(), (p['y'] as num).toDouble())).toList();

    return LevelObject(
      type: json['type'] as String,
      x: (json['x'] as num).toDouble(),
      y: (json['y'] as num).toDouble(),
      angle: (json['angle'] as num?)?.toDouble() ?? (json['direction'] as num?)?.toDouble() ?? 0.0,
      color: json['color'] as String?,
      width: (json['width'] as num?)?.toDouble() ?? 0.0,
      height: (json['height'] as num?)?.toDouble() ?? 0.0,
      locked: json['locked'] as bool? ?? false,
      sequence: json['sequence'] as int? ?? 0,
      interval: (json['interval'] as num?)?.toDouble() ?? 0.0,
      delay: (json['delay'] as num?)?.toDouble() ?? 0.0,
      linkedId: (json['link'] as num?)?.toInt() ?? 0,
      waypoints: waypoints,
      speed: (json['speed'] as num?)?.toDouble() ?? 0.0,
    );
  }
}


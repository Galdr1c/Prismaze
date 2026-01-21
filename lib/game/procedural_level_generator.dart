import 'dart:math';
import 'package:flutter/material.dart';

class ProceduralLevelGenerator {
  final Random _rng = Random();

  /// Generates a level map structure compatible with LevelLoader
  Map<String, dynamic> generateLevel(int levelId) {
    int difficulty = levelId; 
    
    // Grid Size (Scales with difficulty, max 700x1280 essentially)
    double width = 720;
    double height = 1000; // Playable area
    
    // Object Counts
    int mirrorCount = 3 + (difficulty / 5).floor().clamp(0, 8);
    int wallCount = 2 + (difficulty / 4).floor().clamp(0, 10);
    int prismCount = (difficulty > 30) ? 1 + (difficulty / 20).floor().clamp(0, 4) : 0;
    int portalCount = (difficulty > 90) ? 2 : 0; // Pairs
    
    List<Map<String, dynamic>> objects = [];
    int objectIdCounter = 0;

    // 1. Place Light Source (Fixed top or random edge)
    // For simplicity, Top Left or Top Center
    double srcX = 100 + _rng.nextInt(500).toDouble();
    double srcY = 200;
    objects.add({
      'id': objectIdCounter++,
      'type': 'source',
      'x': srcX,
      'y': srcY,
      'angle': _rng.nextDouble() * 3.14, // Random downward angle
      'color': "FFFF0000" // Red default
    });

    // 2. Place Targets (Win Condition)
    // Place at bottom area
    int targetCount = 1 + (difficulty / 10).floor().clamp(0, 3);
    for (int i = 0; i < targetCount; i++) {
        objects.add({
             'id': objectIdCounter++,
             'type': 'target',
             'x': 100 + _rng.nextInt(500).toDouble(),
             'y': 900 + _rng.nextInt(200).toDouble(),
             'color': "FFFF0000", // Match source for now (v1)
             'sequence': 0
        });
    }

    // 3. Place Obstacles (Walls)
    for (int i = 0; i < wallCount; i++) {
        objects.add({
            'id': objectIdCounter++,
            'type': 'wall',
            'x': 50 + _rng.nextInt(600).toDouble(),
            'y': 300 + _rng.nextInt(500).toDouble(),
            'width': 50 + _rng.nextInt(100).toDouble(),
            'height': 50 + _rng.nextInt(100).toDouble(),
        });
    }

    // 4. Place Tools (Mirrors)
    for (int i = 0; i < mirrorCount; i++) {
        objects.add({
            'id': objectIdCounter++,
            'type': 'mirror',
            'x': 50 + _rng.nextInt(600).toDouble(),
            'y': 300 + _rng.nextInt(500).toDouble(),
            'angle': _rng.nextDouble() * 3.14 * 2,
            'locked': false
        });
    }
    
    // 5. Place Portals (if unlocked)
    if (portalCount > 0) {
        // Portal A
        objects.add({
             'id': objectIdCounter++,
             'type': 'portal',
             'x': 100.0, 'y': 500.0,
             'width': 60, 'height': 60,
             'link': objectIdCounter + 1, // Link to next
             'color': "FF00FF00" 
        });
        // Portal B
        objects.add({
             'id': objectIdCounter++,
             'type': 'portal',
             'x': 600.0, 'y': 800.0,
             'width': 60, 'height': 60,
             'link': objectIdCounter - 2, // Link to prev
             'color': "FF00FF00"
        });
    }

    return {
      'id': levelId,
      'par': 5 + mirrorCount, // Estimate par
      'objects': objects,
      // No strict solution for proc-gen, allow free play
    };
  }
}

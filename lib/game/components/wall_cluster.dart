import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import '../prismaze_game.dart';
import 'wall.dart';

/// Optimized rendering for clustered walls
class WallCluster extends PositionComponent with HasGameRef<PrismazeGame> {
  final List<Wall> walls;
  Path? _cachedOutlinePath;
  Path? _cachedBodyPath;
  int _themeHash = 0;

  Path get outlinePath {
    _cachedOutlinePath ??= _buildOutlinePath();
    return _cachedOutlinePath!;
  }

  Path get bodyPath {
    _cachedBodyPath ??= _buildBodyPath();
    return _cachedBodyPath!;
  }

  // Grid constants synchronized with GridOverlay
  static const double cellSize = 85.0;
  static const double offsetX = 45.0;
  static const double offsetY = 62.5;
  
  WallCluster(this.walls) : super(
    priority: 10, // High priority to be above background and grid
    size: Vector2(1344, 756), // Cover full game area
  );
  
  @override
  void update(double dt) {
    super.update(dt);
    
    // Rebuild cache if theme changed
    final currentTheme = gameRef.customizationManager.selectedTheme;
    final newHash = currentTheme.hashCode;
    if (_themeHash != newHash) {
      _themeHash = newHash;
      _cachedOutlinePath = null;
      _cachedBodyPath = null;
    }
  }
  
  @override
  void render(Canvas canvas) {
    if (walls.isEmpty) return;
    
    final reducedGlow = gameRef.settingsManager.reducedGlowEnabled;
    final highContrast = gameRef.settingsManager.highContrastEnabled;
    
    // Build paths on first render or theme change
    _cachedOutlinePath ??= _buildOutlinePath();
    _cachedBodyPath ??= _buildBodyPath();
    
    // Check global opacity from first wall (if exists) or default to 1
    final double globalOpacity = walls.isNotEmpty ? walls.first.opacity : 1.0;
    if (globalOpacity < 0.01) return; // Skip if invisible
    
    if (highContrast) {
      _renderHighContrast(canvas);
      return;
    }
    
    final theme = gameRef.customizationManager.selectedTheme;
    final glowColor = Wall.getThemeColorStatic(theme, 'glow');
    final borderColor = Wall.getThemeColorStatic(theme, 'border');
    final darkColor = Wall.getThemeColorStatic(theme, 'dark');
    final lightColor = Wall.getThemeColorStatic(theme, 'light');
    
    // === SINGLE OUTER GLOW (Removed) ===
    // Removed to match Wall.dart style
    
    // === BODY (Solid & Opaque) ===
    final Paint bodyPaint = Paint();
    bodyPaint.color = darkColor; // Match Wall.dart (Opaque Dark)
    
    canvas.drawPath(_cachedBodyPath!, bodyPaint);
    
    // === SINGLE BORDER (Thicker) ===
    canvas.drawPath(
      _cachedOutlinePath!,
      Paint()
        ..color = borderColor // Fully opaque
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.0, // Match Wall.dart
    );
  }
  
  void _renderHighContrast(Canvas canvas) {
    canvas.drawPath(
      _cachedBodyPath!,
      Paint()..color = Colors.black,
    );
    canvas.drawPath(
      _cachedOutlinePath!,
      Paint()
        ..color = Colors.white
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );
  }
  
  /// Build outline path from individual walls
  Path _buildOutlinePath() {
    final path = Path();
    
    // Create a grid to track occupied cells
    final grid = <String>{};
    for (final wall in walls) {
      final x = ((wall.position.x - offsetX) / cellSize).round();
      final y = ((wall.position.y - offsetY) / cellSize).round();
      grid.add('$x,$y');
    }
    
    for (final wall in walls) {
      final x = ((wall.position.x - offsetX) / cellSize).round();
      final y = ((wall.position.y - offsetY) / cellSize).round();
      
      // Check 4 edges
      _addEdgeIfBoundary(path, x, y, grid, 'top');
      _addEdgeIfBoundary(path, x, y, grid, 'right');
      _addEdgeIfBoundary(path, x, y, grid, 'bottom');
      _addEdgeIfBoundary(path, x, y, grid, 'left');
    }
    
    return path;
  }
  
  void _addEdgeIfBoundary(Path path, int x, int y, Set<String> grid, String edge) {
    final px = offsetX + x * cellSize;
    final py = offsetY + y * cellSize;
    
    bool isBoundary = false;
    
    switch (edge) {
      case 'top':
        isBoundary = !grid.contains('$x,${y - 1}');
        if (isBoundary) {
          path.moveTo(px, py);
          path.lineTo(px + cellSize, py);
        }
        break;
      case 'right':
        isBoundary = !grid.contains('${x + 1},$y');
        if (isBoundary) {
          path.moveTo(px + cellSize, py);
          path.lineTo(px + cellSize, py + cellSize);
        }
        break;
      case 'bottom':
        isBoundary = !grid.contains('$x,${y + 1}');
        if (isBoundary) {
          path.moveTo(px, py + cellSize);
          path.lineTo(px + cellSize, py + cellSize);
        }
        break;
      case 'left':
        isBoundary = !grid.contains('${x - 1},$y');
        if (isBoundary) {
          path.moveTo(px, py);
          path.lineTo(px, py + cellSize);
        }
        break;
    }
  }
  
  Path _buildBodyPath() {
    final path = Path();
    for (final wall in walls) {
      path.addRect(Rect.fromLTWH(wall.position.x, wall.position.y, wall.size.x, wall.size.y));
    }
    return path;
  }
}

import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import '../prismaze_game.dart';
import 'wall.dart';
import '../../core/models/grid_position.dart';

/// Optimized rendering for clustered walls.
/// Merges adjacent wall cells into a single continuous shape.
class WallCluster extends PositionComponent with HasGameRef<PrismazeGame> {
  final Set<GridPosition> gridPositions;
  
  Path? _cachedOutlinePath;
  Path? _cachedBodyPath;
  int _themeHash = 0;

  // Grid constants
  static const double cellSize = 85.0;

  WallCluster({
    required this.gridPositions,
  }) : super(
    priority: -5, // Render below objects but above bottom-most layers if any
    // Anchor at top-left of the grid (0,0) effectively
    position: Vector2.zero(), 
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
    if (gridPositions.isEmpty) return;
    
    final reducedGlow = gameRef.settingsManager.reducedGlowEnabled;
    final highContrast = gameRef.settingsManager.highContrastEnabled;
    
    // Build paths if needed
    _cachedOutlinePath ??= _buildOutlinePath();
    _cachedBodyPath ??= _buildBodyPath();
    
    // Common Opacity (can be passed or animated later if needed)
    const double opacity = 1.0;
    
    if (highContrast) {
      _renderHighContrast(canvas);
      return;
    }
    
    final theme = gameRef.customizationManager.selectedTheme;
    final glowColor = Wall.getThemeColorStatic(theme, 'glow');
    final borderColor = Wall.getThemeColorStatic(theme, 'border');
    final darkColor = Wall.getThemeColorStatic(theme, 'dark'); // Body color
    
    // === BODY ===
    final Paint bodyPaint = Paint()
      ..color = darkColor.withOpacity(opacity)
      ..style = PaintingStyle.fill;
    
    canvas.drawPath(_cachedBodyPath!, bodyPaint);
    
    // === OUTLINE / BORDER ===
    final Paint borderPaint = Paint()
      ..color = borderColor.withOpacity(opacity)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0
      ..strokeCap = StrokeCap.square // Cleaner corners
      ..strokeJoin = StrokeJoin.miter;

    // Optional: Draw inner bevel/highlight for "single object" feel?
    // For now, simple border as requested.
    canvas.drawPath(_cachedOutlinePath!, borderPaint);
    
    // === GLOW (Optional) ===
    if (!reducedGlow) {
       // Draw glow behind? Or on line?
       // Wall.dart uses offset glow. 
       // Keeping it clean for now as user requested "single unit".
    }
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
  
  /// Build outline path tracing the outer edge of the cluster
  Path _buildOutlinePath() {
    final path = Path();
    
    // Convert set to string keys for fast lookup
    final gridKeys = gridPositions.map((p) => '${p.x},${p.y}').toSet();
    
    for (final pos in gridPositions) {
      final x = pos.x;
      final y = pos.y;
      
      // Pixel coordinates of top-left corner of this cell
      final px = x * cellSize;
      final py = y * cellSize;
      
      // Check neighbors to decide if we draw an edge
      
      // Top Edge
      if (!gridKeys.contains('$x,${y - 1}')) {
        path.moveTo(px, py);
        path.lineTo(px + cellSize, py);
      }
      
      // Right Edge
      if (!gridKeys.contains('${x + 1},$y')) {
        path.moveTo(px + cellSize, py);
        path.lineTo(px + cellSize, py + cellSize);
      }
      
      // Bottom Edge
      if (!gridKeys.contains('$x,${y + 1}')) {
        path.moveTo(px, py + cellSize);
        path.lineTo(px + cellSize, py + cellSize);
      }
      
      // Left Edge
      if (!gridKeys.contains('${x - 1},$y')) {
        path.moveTo(px, py);
        path.lineTo(px, py + cellSize);
      }
    }
    
    return path;
  }
  
  Path _buildBodyPath() {
    final path = Path();
    for (final pos in gridPositions) {
        // Add rect for each cell
        // Overlapping rects merge into a single path usually, 
        // but explicit path operations are expensive.
        // Just adding rects works for filling.
        path.addRect(Rect.fromLTWH(
          pos.x * cellSize, 
          pos.y * cellSize, 
          cellSize, 
          cellSize
        ));
    }
    return path;
  }
}

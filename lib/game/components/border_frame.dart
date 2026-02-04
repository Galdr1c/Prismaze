import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import '../prismaze_game.dart';
import 'wall.dart';

/// A thin aesthetic border frame around the playable grid.
/// Draws 4 thin lines (top, bottom, left, right) with theme colors.
class BorderFrame extends PositionComponent with HasGameRef<PrismazeGame> {
  final double gridWidth;
  final double gridHeight;
  final double lineThickness;
  
  BorderFrame({
    required Vector2 position,
    required this.gridWidth,
    required this.gridHeight,
    this.lineThickness = 3.0,
  }) : super(
    position: position, 
    size: Vector2(gridWidth, gridHeight),
    priority: -100, // Render behind all game objects
  );
  
  Color get _borderColor {
    final theme = gameRef.customizationManager.selectedTheme;
    return Wall.getThemeColorStatic(theme, 'border');
  }
  
  Color get _glowColor {
    final theme = gameRef.customizationManager.selectedTheme;
    return Wall.getThemeColorStatic(theme, 'glow');
  }

  @override
  void render(Canvas canvas) {
    final bool reducedGlow = gameRef.settingsManager.reducedGlowEnabled;
    final bool highContrast = gameRef.settingsManager.highContrastEnabled;
    
    final Paint linePaint = Paint()
      ..color = highContrast ? Colors.white : _borderColor
      ..strokeWidth = lineThickness
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    
    // Glow effect (if not reduced)
    if (!reducedGlow && !highContrast) {
      final Paint glowPaint = Paint()
        ..color = _glowColor.withOpacity(0.3)
        ..strokeWidth = lineThickness + 4
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6);
      
      _drawFrame(canvas, glowPaint);
    }
    
    // Main border lines
    _drawFrame(canvas, linePaint);
  }
  
  void _drawFrame(Canvas canvas, Paint paint) {
    // Top line
    canvas.drawLine(
      Offset(0, 0),
      Offset(gridWidth, 0),
      paint,
    );
    
    // Bottom line
    canvas.drawLine(
      Offset(0, gridHeight),
      Offset(gridWidth, gridHeight),
      paint,
    );
    
    // Left line
    canvas.drawLine(
      Offset(0, 0),
      Offset(0, gridHeight),
      paint,
    );
    
    // Right line
    canvas.drawLine(
      Offset(gridWidth, 0),
      Offset(gridWidth, gridHeight),
      paint,
    );
  }
}

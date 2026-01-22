import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import '../prismaze_game.dart';
import '../data/level_design_system.dart';

/// Faint grid overlay to visualize the 22x9 play area
class GridOverlay extends PositionComponent with HasGameRef<PrismazeGame> {
  static const double cellSize = 55.0;
  static const int gridCols = 22;
  static const int gridRows = 9;
  static const double offsetX = 35.0;
  static const double offsetY = 112.5;
  
  GridOverlay() : super(priority: -100); // Render behind everything
  
  @override
  void render(Canvas canvas) {
    final paint = Paint()
      ..color = Colors.white.withOpacity(0.05) // Very faint
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    
    // Draw vertical lines
    for (int x = 0; x <= gridCols; x++) {
      final xPos = offsetX + x * cellSize;
      canvas.drawLine(
        Offset(xPos, offsetY),
        Offset(xPos, offsetY + gridRows * cellSize),
        paint,
      );
    }
    
    // Draw horizontal lines
    for (int y = 0; y <= gridRows; y++) {
      final yPos = offsetY + y * cellSize;
      canvas.drawLine(
        Offset(offsetX, yPos),
        Offset(offsetX + gridCols * cellSize, yPos),
        paint,
      );
    }
    
    // Highlight corners of cells with dots
    final dotPaint = Paint()
      ..color = Colors.white.withOpacity(0.08)
      ..style = PaintingStyle.fill;
    
    for (int x = 0; x <= gridCols; x++) {
      for (int y = 0; y <= gridRows; y++) {
        canvas.drawCircle(
          Offset(offsetX + x * cellSize, offsetY + y * cellSize),
          2,
          dotPaint,
        );
      }
    }
  }
}


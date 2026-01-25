import 'package:flame/components.dart';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import '../prismaze_game.dart';
import '../data/level_design_system.dart';

/// Faint grid overlay to visualize the 14x7 play area
class GridOverlay extends PositionComponent with HasGameRef<PrismazeGame> {
  static const double cellSize = 85.0;
  static const int gridCols = 14;
  static const int gridRows = 7;
  static const double offsetX = 45.0;
  static const double offsetY = 62.5;
  
  GridOverlay() : super(priority: -100); // Render behind everything
  


  ui.Image? _cachedImage;

  @override
  Future<void> onLoad() async {
    await _cacheGrid();
  }

  Future<void> _cacheGrid() async {
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    
    // Draw the entire grid to this off-screen canvas (matching game resolution)
    // Assuming 1344x756 coverage (safe bet)
    final paint = Paint()
      ..color = Colors.white.withOpacity(0.05)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
      
    // Vertical
    for (int x = 0; x <= gridCols; x++) {
      final xPos = offsetX + x * cellSize;
      canvas.drawLine(Offset(xPos, offsetY), Offset(xPos, offsetY + gridRows * cellSize), paint);
    }
    // Horizontal
    for (int y = 0; y <= gridRows; y++) {
      final yPos = offsetY + y * cellSize;
      canvas.drawLine(Offset(offsetX, yPos), Offset(offsetX + gridCols * cellSize, yPos), paint);
    }
    
    // Dots
    final dotPaint = Paint()..color = Colors.white.withOpacity(0.08)..style = PaintingStyle.fill;
    for (int x = 0; x <= GridConstants.columns; x++) {
      for (int y = 0; y <= GridConstants.rows; y++) {
        canvas.drawCircle(Offset(GridConstants.offsetX + x * GridConstants.cellSize, GridConstants.offsetY + y * GridConstants.cellSize), 2, dotPaint);
      }
    }
    
    final picture = recorder.endRecording();
    // Convert to image (size matching camera viewport)
    _cachedImage = await picture.toImage(1344, 756);
  }

  @override
  void render(Canvas canvas) {
    if (_cachedImage != null) {
      canvas.drawImage(_cachedImage!, Offset.zero, Paint());
    }
  }
}


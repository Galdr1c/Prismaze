import 'package:flame/components.dart';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import '../prismaze_game.dart';
import '../data/level_design_system.dart';

/// Faint grid overlay to visualize the 14x7 play area
class GridOverlay extends PositionComponent with HasGameRef<PrismazeGame> {
  static const double cellSize = 85.0;
  static const int gridCols = 6;
  static const int gridRows = 12;
  // Center Offsets for 720x1280 (Portrait)
  // Grid Width: 6 * 85 = 510. Screen Width: 720. MarginX: (720-510)/2 = 105.
  // Grid Height: 12 * 85 = 1020. Screen Height: 1280. MarginY: (1280-1020)/2 = 130.
  static const double offsetX = 105.0; 
  static const double offsetY = 130.0;
  
  GridOverlay() : super(priority: -100); // Render behind everything
  


  ui.Image? _cachedImage;

  @override
  Future<void> onLoad() async {
    _cacheGrid();
  }

  void _cacheGrid() {
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    
    // Draw the entire grid to this off-screen canvas (matching game resolution)
    // 720x1280 coverage
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
    for (int x = 0; x <= gridCols; x++) {
      for (int y = 0; y <= gridRows; y++) {
        canvas.drawCircle(Offset(offsetX + x * cellSize, offsetY + y * cellSize), 2, dotPaint);
      }
    }
    
    final picture = recorder.endRecording();
    // Convert to image (size matching camera viewport)
    picture.toImage(720, 1280).then((img) => _cachedImage = img);
  }

  @override
  void render(Canvas canvas) {
    if (_cachedImage != null) {
      canvas.drawImage(_cachedImage!, Offset.zero, Paint());
    }
  }
}


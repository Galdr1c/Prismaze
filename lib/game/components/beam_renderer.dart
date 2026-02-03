import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import '../../core/logic/trace_result.dart';
import '../../core/models/models.dart';
import '../../core/models/light_color.dart';

/// Renders the light beams based on the RayTracer result.
class BeamRenderer extends PositionComponent {
  TraceResult? _result;
  
  // Paint Cache
  final Map<int, Paint> _paints = {};

  BeamRenderer() : super(priority: 100); // Draw above grid logic

  void updateResult(TraceResult result) {
    _result = result;
  }

  @override
  void render(Canvas canvas) {
    if (_result == null) return;
    
    // Grid settings (Assume standard Prismaze constants for now, should be injectable)
    const double cellSize = 85.0; // From HeadlessRayTracer/Consts
    const double offsetX = 0; // Grid offset if any
    const double offsetY = 0;
    
    for (var segment in _result!.segments) {
      final startPixel = segment.start.toPixel(cellSize);
      final endPixel = segment.end.toPixel(cellSize);
      
      final paint = _getPaint(segment.color);
      canvas.drawLine(
        Offset(startPixel.dx, startPixel.dy),
        Offset(endPixel.dx, endPixel.dy),
        paint,
      );
      
      // Add glow or cap? 
      // For Phase 9 MVP, simple lines are enough to verify logic.
      // Polish logic (animations, particles) goes here later.
    }
  }

  Paint _getPaint(LightColor color) {
    if (_paints.containsKey(color.mask)) {
      return _paints[color.mask]!;
    }
    
    // Map LightColor to UI Color
    Color uiColor;
    switch (color) {
      case LightColor.red: uiColor = Colors.redAccent; break;
      case LightColor.green: uiColor = Colors.greenAccent; break;
      case LightColor.blue: uiColor = Colors.blueAccent; break;
      case LightColor.yellow: uiColor = Colors.yellowAccent; break;
      case LightColor.purple: uiColor = Colors.purpleAccent; break;
      case LightColor.cyan: uiColor = Colors.cyanAccent; break;
      case LightColor.white: uiColor = Colors.white; break;
      default: uiColor = Colors.grey;
    }
    
    final paint = Paint()
      ..color = uiColor
      ..strokeWidth = 6.0
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3.0); // Slight glow
      
    _paints[color.mask] = paint;
    return paint;
  }
}

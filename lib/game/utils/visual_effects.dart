import 'package:flutter/material.dart';
import 'dart:math';

/// Premium visual effects utilities for game components
/// Provides shared rendering functions for glows, gradients, and animated patterns
class VisualEffects {
  
  /// Draw a multi-layer glow effect around a shape
  /// [canvas] - The canvas to draw on
  /// [rrect] - The rounded rectangle shape
  /// [glowColor] - Base color for the glow
  /// [intensity] - Glow intensity multiplier (0.0 - 1.0)
  /// [reducedGlow] - If true, uses simplified single-layer glow
  static void drawCrystalGlow(
    Canvas canvas,
    RRect rrect,
    Color glowColor, {
    double intensity = 1.0,
    double opacity = 1.0,
    bool reducedGlow = false,
  }) {
    if (reducedGlow) {
      // Simplified single-layer for accessibility
      canvas.drawRRect(
        rrect.inflate(2),
        Paint()
          ..color = glowColor.withOpacity(0.4 * intensity * opacity)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2
          ..maskFilter = const MaskFilter.blur(BlurStyle.solid, 3),
      );
      return;
    }

    // Layer 1: Wide atmospheric haze
    canvas.drawRRect(
      rrect.inflate(8),
      Paint()
        ..color = glowColor.withOpacity(0.15 * intensity * opacity)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 12),
    );

    // Layer 2: Medium glow
    canvas.drawRRect(
      rrect.inflate(4),
      Paint()
        ..color = glowColor.withOpacity(0.3 * intensity * opacity)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6),
    );

    // Layer 3: Tight edge glow
    canvas.drawRRect(
      rrect,
      Paint()
        ..color = glowColor.withOpacity(0.5 * intensity * opacity)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3
        ..maskFilter = const MaskFilter.blur(BlurStyle.solid, 4),
    );
  }

  /// Draw a 3D bevel effect on a shape
  /// Creates highlight on top-left and shadow on bottom-right
  static void drawBeveledEdge(
    Canvas canvas,
    Rect rect,
    double cornerRadius, {
    double highlightOpacity = 0.15,
    double shadowOpacity = 0.2,
    double opacity = 1.0,
  }) {
    final rrect = RRect.fromRectAndRadius(rect, Radius.circular(cornerRadius));
    
    // Top-left highlight (light source from top-left)
    final highlightPath = Path();
    highlightPath.addRRect(rrect);
    
    canvas.save();
    canvas.clipRect(Rect.fromLTRB(rect.left, rect.top, rect.right, rect.top + rect.height * 0.5));
    canvas.drawRRect(
      rrect,
      Paint()
        ..color = Colors.white.withOpacity(highlightOpacity * opacity)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );
    canvas.restore();

    // Bottom-right shadow
    canvas.save();
    canvas.clipRect(Rect.fromLTRB(rect.left, rect.top + rect.height * 0.5, rect.right, rect.bottom));
    canvas.drawRRect(
      rrect,
      Paint()
        ..color = Colors.black.withOpacity(shadowOpacity * opacity)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );
    canvas.restore();
  }

  /// Draw an animated energy grid pattern inside a shape
  /// [time] - Animation time for pattern movement
  static void drawEnergyGrid(
    Canvas canvas,
    Rect rect,
    double time, {
    Color gridColor = const Color(0xFF4D7CFF),
    double gridSize = 20.0,
    double opacity = 1.0,
    bool animated = true,
  }) {
    canvas.save();
    canvas.clipRect(rect);

    // Animated opacity pulse
    final animatedOpacity = animated 
        ? 0.08 + 0.04 * sin(time * 2.5)
        : 0.08;

    final gridPaint = Paint()
      ..color = gridColor.withOpacity(animatedOpacity * opacity)
      ..strokeWidth = 0.8
      ..style = PaintingStyle.stroke;

    // Offset based on time for flowing effect
    final offset = animated ? (time * 8) % gridSize : 0.0;

    // Vertical lines
    for (double x = rect.left + offset; x <= rect.right; x += gridSize) {
      canvas.drawLine(
        Offset(x, rect.top),
        Offset(x, rect.bottom),
        gridPaint,
      );
    }

    // Horizontal lines
    for (double y = rect.top + offset; y <= rect.bottom; y += gridSize) {
      canvas.drawLine(
        Offset(rect.left, y),
        Offset(rect.right, y),
        gridPaint,
      );
    }
    
    // Add diagonal accent lines for tech feel
    final accentPaint = Paint()
      ..color = gridColor.withOpacity(animatedOpacity * 0.5 * opacity)
      ..strokeWidth = 0.5;
    
    for (double x = rect.left - rect.height + offset * 2; x <= rect.right; x += gridSize * 2) {
      canvas.drawLine(
        Offset(x, rect.bottom),
        Offset(x + rect.height, rect.top),
        accentPaint,
      );
    }

    canvas.restore();
  }

  /// Draw a pulsing neon border
  /// [time] - Animation time for pulse effect
  /// [pulseSpeed] - Speed of the pulse animation
  static void drawPulsingBorder(
    Canvas canvas,
    RRect rrect,
    double time,
    Color borderColor, {
    double baseOpacity = 0.6,
    double pulseAmplitude = 0.2,
    double pulseSpeed = 3.0,
    double strokeWidth = 2.0,
    double opacity = 1.0,
    bool reducedGlow = false,
  }) {
    final pulse = baseOpacity + pulseAmplitude * sin(time * pulseSpeed);
    
    if (!reducedGlow) {
      // Glow layer
      canvas.drawRRect(
        rrect,
        Paint()
          ..color = borderColor.withOpacity(pulse * 0.5 * opacity)
          ..style = PaintingStyle.stroke
          ..strokeWidth = strokeWidth + 2
          ..maskFilter = const MaskFilter.blur(BlurStyle.solid, 4),
      );
    }

    // Crisp border
    canvas.drawRRect(
      rrect,
      Paint()
        ..color = borderColor.withOpacity(pulse * opacity)
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth,
    );
  }

  /// Create a crystal body gradient shader
  static Shader createCrystalGradient(
    Rect rect, {
    Color baseColor = const Color(0xFF1A1A3E),
    Color highlightColor = const Color(0xFF2A2A5E),
    double glassOpacity = 0.95,
  }) {
    return LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [
        baseColor.withOpacity(glassOpacity),
        highlightColor.withOpacity(glassOpacity),
        baseColor.withOpacity(glassOpacity),
      ],
      stops: const [0.0, 0.4, 1.0],
    ).createShader(rect);
  }
}


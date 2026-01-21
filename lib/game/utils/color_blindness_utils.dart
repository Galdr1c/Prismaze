import 'package:flutter/material.dart';

enum ColorBlindMode { none, deuteranopia, protanopia, tritanopia }

class ColorBlindnessUtils {
  
  static ColorBlindMode currentMode = ColorBlindMode.none;
  
  // Safe Palettes
  // Deuteranopia (Green-Blind): Blues and Yellows
  static const Map<int, Color> _deuteranopiaMap = {
    0xFFFF0000: Color(0xFFD35E60), // Red -> Muted Red
    0xFF00FF00: Color(0xFFE2B72F), // Green -> Yellowish
    0xFF0000FF: Color(0xFF2D74BC), // Blue -> Distinct Blue
    0xFFFF00FF: Color(0xFFB17DA6), // Magenta -> Muted
    0xFF00FFFF: Color(0xFF90C2D8), // Cyan -> Light Blue
    0xFFFFFF00: Color(0xFFFFD93B), // Yellow -> Bright Yellow
  };
  
  // Protanopia (Red-Blind): Blues and Yellows
  static const Map<int, Color> _protanopiaMap = {
    0xFFFF0000: Color(0xFF888888), // Red -> Gray/Dark
    0xFF00FF00: Color(0xFFE3BC26), // Green -> Yellow-Gold
    0xFF0000FF: Color(0xFF2879C5), // Blue -> Vivid Blue
    0xFFFF00FF: Color(0xFF757488), // Magenta -> Purple/Gray
    0xFF00FFFF: Color(0xFF94C5DA), // Cyan -> Powder Blue
    0xFFFFFF00: Color(0xFFFFE047), // Yellow -> Bright
  };
  
  // Tritanopia (Blue-Blind): Reds and Cyans/Greens
  static const Map<int, Color> _tritanopiaMap = {
    0xFFFF0000: Color(0xFFE94D4D), // Red -> Bright Red
    0xFF00FF00: Color(0xFF2CB3BF), // Green -> Teal
    0xFF0000FF: Color(0xFF384C49), // Blue -> Dark Teal
    0xFFFF00FF: Color(0xFFE68080), // Magenta -> Salmon
    0xFF00FFFF: Color(0xFF5CC5D0), // Cyan -> Sky
    0xFFFFFF00: Color(0xFFFFC0CB), // Yellow -> Pinkish
  };

  static Color getSafeColor(Color original) {
    if (currentMode == ColorBlindMode.none) return original;
    
    // We map widely used primary colors (ignoring alpha for key matching logic)
    // This is a naive implementation for exact matches. 
    // For a game with set colors, exact keys are better than algo shifting.
    
    final key = original.withAlpha(255).value;
    
    Map<int, Color>? map;
    if (currentMode == ColorBlindMode.deuteranopia) map = _deuteranopiaMap;
    else if (currentMode == ColorBlindMode.protanopia) map = _protanopiaMap;
    else if (currentMode == ColorBlindMode.tritanopia) map = _tritanopiaMap;
    
    if (map != null && map.containsKey(key)) {
        return map[key]!.withOpacity(original.opacity);
    }
    
    // Fallback: If not a primary color, return original (or apply filter implementation if needed)
    return original; 
  }
  
  static String? getSymbol(Color color) {
    if (currentMode == ColorBlindMode.none) return null;
    
    final key = color.withAlpha(255).value;
    
    // Map colors to symbols
    // Red: Square
    if (key == 0xFFFF0000) return "■";
    // Green: Triangle
    if (key == 0xFF00FF00) return "▲";
    // Blue: Circle
    if (key == 0xFF0000FF) return "●";
    // Yellow: Star
    if (key == 0xFFFFFF00) return "★";
    // Magenta: Cross
    if (key == 0xFFFF00FF) return "✖";
    // Cyan: Hexagon
    if (key == 0xFF00FFFF) return "⬡";
    // White: None
    
    return null;
  }
  
  static Paint getSymbolPaint(Color originalColor) {
      return Paint()
        ..color = Colors.white 
        ..style = PaintingStyle.fill;
        // TextPainter will handle drawing
  }
  
  static void drawSymbol(Canvas canvas, Offset center, Color color, double size) {
      final symbol = getSymbol(color);
      if (symbol == null) return;
      
      final textSpan = TextSpan(
        text: symbol,
        style: TextStyle(
          color: Colors.white.withOpacity(0.9),
          fontSize: size * 0.8,
          fontWeight: FontWeight.bold,
          shadows: [
              const Shadow(color: Colors.black, blurRadius: 2),
          ]
        ),
      );
      
      final textPainter = TextPainter(
        text: textSpan,
        textDirection: TextDirection.ltr,
        textAlign: TextAlign.center
      );
      
      textPainter.layout();
      textPainter.paint(canvas, center - Offset(textPainter.width / 2, textPainter.height / 2));
  }
}

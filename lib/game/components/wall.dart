import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import 'dart:math';
import 'dart:ui' as ui;
import 'dart:typed_data';
import '../prismaze_game.dart';
import '../utils/visual_effects.dart';

class Wall extends PositionComponent with HasGameRef<PrismazeGame> {
  double opacity = 1.0;
  double _time = 0;
  
  // Texture pattern
  static ui.Image? _patternImage;
  static bool _patternLoading = false;
  
  // Random offset for pattern variation
  late final double _patternOffsetX;
  late final double _patternOffsetY;
  
  // Theme-based color schemes
  static const Map<String, Map<String, Color>> _themeColors = {
    'theme_space': {
      'dark': Color(0xFF0D1020),
      'light': Color(0xFF1A2040),
      'glow': Color(0xFF4D7CFF),
      'border': Color(0xFF6699FF),
      'accent': Color(0xFF00D4FF),
    },
    'theme_neon': {
      'dark': Color(0xFF0A0015),
      'light': Color(0xFF1A0030),
      'glow': Color(0xFFFF00FF),
      'border': Color(0xFFFF44FF),
      'accent': Color(0xFFFF88FF),
    },
    'theme_ocean': {
      'dark': Color(0xFF001520),
      'light': Color(0xFF002535),
      'glow': Color(0xFF00BFFF),
      'border': Color(0xFF00E5FF),
      'accent': Color(0xFF00FFFF),
    },
    'theme_forest': {
      'dark': Color(0xFF0A1510),
      'light': Color(0xFF152520),
      'glow': Color(0xFF00FF88),
      'border': Color(0xFF44FF88),
      'accent': Color(0xFF88FFAA),
    },
    'theme_desert': {
      'dark': Color(0xFF1A1508),
      'light': Color(0xFF2A2010),
      'glow': Color(0xFFFFAA00),
      'border': Color(0xFFFFCC44),
      'accent': Color(0xFFFFDD88),
    },
    'theme_mountain': {
      'dark': Color(0xFF101520),
      'light': Color(0xFF1A2535),
      'glow': Color(0xFF8888FF),
      'border': Color(0xFFAAAAFF),
      'accent': Color(0xFFCCCCFF),
    },
    'theme_galaxy': {
      'dark': Color(0xFF0A0520),
      'light': Color(0xFF150A30),
      'glow': Color(0xFFAA44FF),
      'border': Color(0xFFCC66FF),
      'accent': Color(0xFFEE88FF),
    },
    'theme_winter': {
      'dark': Color(0xFF0A1520),
      'light': Color(0xFF152535),
      'glow': Color(0xFF88DDFF),
      'border': Color(0xFFAAEEFF),
      'accent': Color(0xFFCCFFFF),
    },
    'theme_halloween': {
      'dark': Color(0xFF150A00),
      'light': Color(0xFF251505),
      'glow': Color(0xFFFF6600),
      'border': Color(0xFFFF8800),
      'accent': Color(0xFFFFAA44),
    },
    'theme_summer': {
      'dark': Color(0xFF151508),
      'light': Color(0xFF252510),
      'glow': Color(0xFFFFDD00),
      'border': Color(0xFFFFEE44),
      'accent': Color(0xFFFFFF88),
    },
    'theme_abyss': {
      'dark': Color(0xFF050510),
      'light': Color(0xFF0A0A20),
      'glow': Color(0xFF6644AA),
      'border': Color(0xFF8866CC),
      'accent': Color(0xFFAA88EE),
    },
  };
  
  // Color getters based on selected theme
  Color get _bodyColorDark => _getThemeColor('dark');
  Color get _bodyColorLight => _getThemeColor('light');
  Color get _glowColor => _getThemeColor('glow');
  Color get _borderColor => _getThemeColor('border');
  Color get _accentColor => _getThemeColor('accent');
  
  Color _getThemeColor(String key) {
    final theme = gameRef.customizationManager.selectedTheme;
    return getThemeColorStatic(theme, key);
  }
  
  /// Static helper for other components to access theme colors
  static Color getThemeColorStatic(String theme, String key) {
    final colors = _themeColors[theme] ?? _themeColors['theme_space']!;
    return colors[key] ?? const Color(0xFF4D7CFF);
  }

  Wall({
    required Vector2 position,
    required Vector2 size,
  }) : _patternOffsetX = Random().nextDouble() * 500,
       _patternOffsetY = Random().nextDouble() * 500,
       super(position: position, size: size, anchor: Anchor.topLeft);

  @override
  Future<void> onLoad() async {
    // Load pattern texture once (shared across all walls)
    if (_patternImage == null && !_patternLoading) {
      _patternLoading = true;
      try {
        _patternImage = await gameRef.images.load('wall_pattern.jpg');
      } catch (e) {
        print('Failed to load wall_pattern.jpg: $e');
      }
      _patternLoading = false;
    }
  }

  @override
  void update(double dt) {
    super.update(dt);
    _time += dt;
  }

  @override
  void render(Canvas canvas) {
    if (opacity == 0) return;
    
    final rect = size.toRect();
    final rrect = RRect.fromRectAndRadius(rect, const Radius.circular(4));
    
    // Check accessibility settings
    final bool reducedGlow = gameRef.settingsManager.reducedGlowEnabled;
    final bool highContrast = gameRef.settingsManager.highContrastEnabled;
    
    if (highContrast) {
      // High Contrast Mode: Simple solid with white border
      canvas.drawRRect(rrect, Paint()..color = Colors.black.withOpacity(opacity));
      canvas.drawRRect(
        rrect,
        Paint()
          ..color = Colors.white.withOpacity(opacity)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2,
      );
      return;
    }

    // === LAYER 1: Outer Glow Haze ===
    if (!reducedGlow) {
      VisualEffects.drawCrystalGlow(
        canvas,
        rrect,
        _glowColor,
        intensity: 0.6 + 0.2 * sin(_time * 2),
        opacity: opacity,
        reducedGlow: reducedGlow,
      );
    }

    // === LAYER 2: Base Gradient Body ===
    final bodyGradient = LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [
        _bodyColorDark.withOpacity(0.95 * opacity),
        _bodyColorLight.withOpacity(0.9 * opacity),
        _bodyColorDark.withOpacity(0.95 * opacity),
      ],
      stops: const [0.0, 0.45, 1.0],
    );
    
    canvas.drawRRect(
      rrect,
      Paint()..shader = bodyGradient.createShader(rect),
    );

    // === LAYER 3: Subtle Pattern Overlay ===
    if (_patternImage != null && !reducedGlow) {
      canvas.save();
      canvas.clipRRect(rrect);
      
      // Scale pattern (0.3x) with random offset for variation
      final scale = 0.3;
      final scaleMatrix = Float64List.fromList([
        scale, 0, 0, 0,
        0, scale, 0, 0,
        0, 0, 1, 0,
        _patternOffsetX * scale, _patternOffsetY * scale, 0, 1
      ]);
      
      final shader = ui.ImageShader(
        _patternImage!,
        ui.TileMode.repeated,
        ui.TileMode.repeated,
        scaleMatrix,
      );
      
      canvas.drawRect(
        rect,
        Paint()
          ..shader = shader
          ..blendMode = BlendMode.overlay
          ..color = Colors.white.withOpacity(opacity * 0.35), // Very subtle
      );
      canvas.restore();
    }

    // === LAYER 3: Bevel Effect (3D Depth) ===
    VisualEffects.drawBeveledEdge(
      canvas,
      rect,
      4,
      highlightOpacity: 0.12,
      shadowOpacity: 0.25,
      opacity: opacity,
    );

    // === LAYER 4: Pulsing Neon Border ===
    VisualEffects.drawPulsingBorder(
      canvas,
      rrect,
      _time,
      _borderColor,
      baseOpacity: 0.2,
      pulseAmplitude: 0.05,
      pulseSpeed: 0.5,
      strokeWidth: 0.5,
      opacity: opacity,
      reducedGlow: reducedGlow,
    );
    
    // === LAYER 5: Inner Edge Highlight (Premium Touch) ===
    final innerRRect = RRect.fromRectAndRadius(
      rect.deflate(3),
      const Radius.circular(2),
    );
    canvas.drawRRect(
      innerRRect,
      Paint()
        ..color = _accentColor.withOpacity(0.08 * opacity)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 0.5,
    );
  }

  // Helper for intersection
  List<Vector2> get corners {
    final tl = absolutePosition;
    final tr = tl + Vector2(size.x, 0);
    final br = tl + size;
    final bl = tl + Vector2(0, size.y);
    return [tl, tr, br, bl];
  }
}


import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import 'dart:math';
import '../prismaze_game.dart';
import '../utils/color_blindness_utils.dart';

class LightSource extends PositionComponent with HasGameRef<PrismazeGame> {
  Color color;
  double _beamAngle; // In radians
  double _time = 0;
  
  bool get isActive => true;

  LightSource({
    required Vector2 position,
    required this.color,
    double angle = 0,
  })  : _beamAngle = angle,
        super(position: position, size: Vector2(60, 60), anchor: Anchor.center);

  double get beamAngle => _beamAngle;
  set beamAngle(double value) => _beamAngle = value;

  double opacity = 1.0;

  @override
  void update(double dt) {
    super.update(dt);
    _time += dt;
  }

  Sprite? _sprite;

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    try {
      _sprite = await gameRef.loadSprite('objects/source_emitter.png');
    } catch (e) {
      print("Error loading source_emitter.png: $e");
    }
  }

  @override
  void render(Canvas canvas) {
    if (opacity == 0) return;
    
    final safeColor = ColorBlindnessUtils.getSafeColor(color);
    final reducedGlow = gameRef.settingsManager.reducedGlowEnabled;
    
    final center = size / 2;
    // Core disk radius: User requested 10-12px.
    const double coreRadius = 11.0; 
    
    // === SPRITE LAYER (Base) ===
    if (_sprite != null) {
      canvas.save();
      canvas.translate(center.x, center.y);
      canvas.rotate(_beamAngle);
      canvas.translate(-center.x, -center.y);
      _sprite!.render(
        canvas,
        position: Vector2.zero(),
        size: size,
        overridePaint: Paint()..color = Colors.white.withOpacity(opacity),
      );
      canvas.restore();
    }

    // === TIER A: Normal (Premium) ===
    if (!reducedGlow) {
      // 1. Radial Glow (Large)
      // Radius 70-90px, Opacity 0.35
      canvas.drawCircle(
        center.toOffset(),
        50.0,
        Paint()
          ..color = safeColor.withOpacity(0.15 * opacity)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 20)
          ..blendMode = BlendMode.plus,
      );

      // 2. Lens Streak (Anamorphic)
      // Horizontal + Vertical
      // Width 160-220px, Height 3-4px, Opacity 0.22
      
      // Horizontal Streak (Relative to rotation? User said H+V. Let's assume screen aligned or local.
      // Usuallyanamorphic is relative to light source orientation.
      // However, "Horizontal + Vertical" implies a cross flare.
      // Let's draw them axis-aligned to the source's local coordinates (rotated).
      
      canvas.save();
      canvas.translate(center.x, center.y);
      // We do NOT rotate streaks usually for anamorphic, they follow camera lens. 
      // But this is top-down. Let's keep them screen-aligned (0 rotation) or local?
      // "Lens streak" usually horizontal. Let's do horizontal screen-aligned.
      
      
      
      canvas.restore();
    } 
    
    // === TIER B: Reduced Glow ===
    else {
      // Radial glow reduced: radius 35-45, opacity 0.18
       canvas.drawCircle(
        center.toOffset(),
        50.0,
        Paint()
          ..color = safeColor.withOpacity(0.15 * opacity)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10)
          ..blendMode = BlendMode.plus, // Allowed for small glow
      );
    }
    
    // === CORE DISK (Common) ===
    // Radius 10-12px, Opacity 1.0
    // Drawn on top to be the "hot" center
    canvas.drawCircle(
      center.toOffset(),
      coreRadius,
      Paint()
        ..color = Colors.white.withOpacity(opacity)
        ..maskFilter = const MaskFilter.blur(BlurStyle.solid, 2), // Very slight soften
    );
    
    // Accessibility Symbol
    ColorBlindnessUtils.drawSymbol(canvas, center.toOffset(), color, size.x / 2);
  }
}


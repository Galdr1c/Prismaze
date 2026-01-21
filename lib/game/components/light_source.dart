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
        super(position: position, size: Vector2(50, 50), anchor: Anchor.center);

  double get beamAngle => _beamAngle;
  set beamAngle(double value) => _beamAngle = value;

  double opacity = 1.0;

  @override
  void update(double dt) {
    super.update(dt);
    _time += dt;
  }

  @override
  void render(Canvas canvas) {
    if (opacity == 0) return;
    
    final safeColor = ColorBlindnessUtils.getSafeColor(color);
    final bool highContrast = gameRef.settingsManager.highContrastEnabled;
    final bool reducedGlow = gameRef.settingsManager.reducedGlowEnabled;
    
    final center = (size / 2).toOffset();
    final radius = size.x / 2;

    // High contrast mode: simple circle with arrow
    if (highContrast) {
      canvas.drawCircle(center, radius, Paint()
        ..color = Colors.white.withOpacity(opacity));
      final dir = Vector2(1, 0)..rotate(_beamAngle);
      canvas.drawLine(
        center,
        (size / 2 + dir * radius).toOffset(),
        Paint()..color = Colors.black..strokeWidth = 4..strokeCap = StrokeCap.round,
      );
      return;
    }

    // === LAYER 1: Drop Shadow ===
    if (!reducedGlow) {
      canvas.drawCircle(
        center + const Offset(2, 3),
        radius + 4,
        Paint()
          ..color = Colors.black.withOpacity(0.35 * opacity)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8),
      );
    }

    // === LAYER 2: Pulsing Outer Aura ===
    if (!reducedGlow) {
      final auraIntensity = 0.15 + 0.1 * sin(_time * 2.0);
      canvas.drawCircle(
        center,
        radius + 20,
        Paint()
          ..color = safeColor.withOpacity(auraIntensity * opacity)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 20),
      );
    }

    // === LAYER 3: Outer Halo Ring ===
    if (!reducedGlow) {
      final haloRadius = radius + 8 + 3 * sin(_time * 3);
      canvas.drawCircle(
        center,
        haloRadius,
        Paint()
          ..color = safeColor.withOpacity(0.25 * opacity)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10),
      );
    }

    // === LAYER 4: Energy Tendrils - REMOVED FOR PERFORMANCE ===
    // (The effect was subtle but expensive)

    // === LAYER 5: Main Crystal Body (Gradient) ===
    final crystalGradient = RadialGradient(
      colors: [
        Colors.white.withOpacity(0.95 * opacity),
        safeColor.withOpacity(0.9 * opacity),
        safeColor.withOpacity(0.7 * opacity),
      ],
      stops: const [0.0, 0.5, 1.0],
    );
    canvas.drawCircle(
      center,
      radius,
      Paint()..shader = crystalGradient.createShader(Rect.fromCircle(center: center, radius: radius)),
    );

    // === LAYER 6: Crystal Facets (Hexagonal hints) - SIMPLIFIED ===
    final facetPaint = Paint()
      ..color = Colors.white.withOpacity(0.15 * opacity)
      ..strokeWidth = 1
      ..style = PaintingStyle.stroke;
    
    for (int i = 0; i < 3; i++) { // Reduced from 6 to 3
      final angle = i * 2 * pi / 3; // Static, no rotation
      final x1 = center.dx + cos(angle) * radius * 0.5;
      final y1 = center.dy + sin(angle) * radius * 0.5;
      final x2 = center.dx + cos(angle) * radius * 0.9;
      final y2 = center.dy + sin(angle) * radius * 0.9;
      canvas.drawLine(Offset(x1, y1), Offset(x2, y2), facetPaint);
    }

    // === LAYER 7: Inner Core Glow (Breathing) ===
    final coreIntensity = 0.8 + 0.2 * sin(_time * 2.5);
    canvas.drawCircle(
      center,
      radius * 0.5,
      Paint()
        ..color = Colors.white.withOpacity(coreIntensity * opacity)
        ..maskFilter = reducedGlow ? null : const MaskFilter.blur(BlurStyle.solid, 4),
    );

    // === LAYER 8: Direction Arrow ===
    final dir = Vector2(1, 0)..rotate(_beamAngle);
    final arrowStart = center + Offset(dir.x * radius * 0.3, dir.y * radius * 0.3);
    final arrowEnd = center + Offset(dir.x * radius * 1.3, dir.y * radius * 1.3);
    
    // Arrow glow
    if (!reducedGlow) {
      canvas.drawLine(
        arrowStart,
        arrowEnd,
        Paint()
          ..color = Colors.white.withOpacity(0.5 * opacity)
          ..strokeWidth = 6
          ..strokeCap = StrokeCap.round
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4),
      );
    }
    
    // Arrow solid
    canvas.drawLine(
      arrowStart,
      arrowEnd,
      Paint()
        ..color = Colors.white.withOpacity(0.95 * opacity)
        ..strokeWidth = 3
        ..strokeCap = StrokeCap.round,
    );
    
    // Arrow head
    final perpDir = Vector2(-dir.y, dir.x) * radius * 0.3;
    final arrowHead = Path();
    arrowHead.moveTo(arrowEnd.dx, arrowEnd.dy);
    arrowHead.lineTo(
      arrowEnd.dx - dir.x * radius * 0.3 + perpDir.x,
      arrowEnd.dy - dir.y * radius * 0.3 + perpDir.y,
    );
    arrowHead.lineTo(
      arrowEnd.dx - dir.x * radius * 0.3 - perpDir.x,
      arrowEnd.dy - dir.y * radius * 0.3 - perpDir.y,
    );
    arrowHead.close();
    canvas.drawPath(arrowHead, Paint()..color = Colors.white.withOpacity(0.95 * opacity));

    // === LAYER 9: Beam Origin Flash ===
    if (!reducedGlow) {
      final flashIntensity = 0.5 + 0.3 * sin(_time * 5);
      final emissionPoint = center + Offset(dir.x * radius * 1.3, dir.y * radius * 1.3);
      canvas.drawCircle(
        emissionPoint,
        6 + 2 * sin(_time * 4),
        Paint()
          ..color = Colors.white.withOpacity(flashIntensity * opacity)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4),
      );
    }

    // === LAYER 10: Crystal Edge Highlight ===
    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..color = Colors.white.withOpacity(0.7 * opacity)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5,
    );
    
    // Accessibility Symbol
    ColorBlindnessUtils.drawSymbol(canvas, center, color, size.x / 2);
  }
}

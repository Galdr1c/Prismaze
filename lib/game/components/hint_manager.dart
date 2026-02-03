import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import 'dart:math';
import '../prismaze_game.dart';
import '../../core/models/models.dart';
import '../../generator/templates/template_models.dart' hide Anchor;

class HintManager extends Component with HasGameRef<PrismazeGame> {
  bool _isShowing = false;
  bool get isShowingHint => _isShowing;
  
  void showLightHint({dynamic onComplete}) {
    final level = gameRef.currentLevel;
    if (level == null) return;

    // 1. Identify the first step not yet satisfied (HATA 4)
    SolutionStep? nextStep;
    for (var step in level.template.solutionSteps) {
      final obj = level.objects.firstWhere((o) => o.position == step.position);
      if (obj.orientation != step.targetOrientation) {
        nextStep = step;
        break;
      }
    }

    if (nextStep == null) return; // Already solved?

    // 2. Highlight that object
    final component = gameRef.gridWorld.children
        .whereType<PositionComponent>()
        .firstWhere((c) => GridPosition.fromPixel(c.position, 85.0) == nextStep!.position);

    _isShowing = true;
    final effect = HintHighlightEffect(target: component);
    gameRef.gridWorld.add(effect);
    
    Future.delayed(const Duration(seconds: 4), () {
        effect.removeFromParent();
        _isShowing = false;
        if (onComplete != null) onComplete();
    });
  }
}

class HintHighlightEffect extends PositionComponent {
  final PositionComponent target;
  final dynamic moveType;
  double _time = 0;

  HintHighlightEffect({required this.target, this.moveType}) : super(
    position: target.position,
    size: target.size,
    anchor: Anchor.center,
  );

  @override
  void update(double dt) {
    _time += dt;
    super.update(dt);
  }

  @override
  void render(Canvas canvas) {
    final double pulse = 1.0 + 0.2 * (0.5 + 0.5 * sin(_time * 6));
    final double opacity = 0.5 + 0.3 * sin(_time * 6);
    
    final paint = Paint()
      ..color = Colors.cyan.withOpacity(opacity.clamp(0.0, 1.0))
      ..style = PaintingStyle.stroke
      ..strokeWidth = 5;
    
    final center = size / 2;
    canvas.drawCircle(Offset(center.x, center.y), (size.x / 2) * pulse, paint);

    // Inner glow
    canvas.drawCircle(Offset(center.x, center.y), (size.x / 2) * 0.8, Paint()..color=Colors.cyan.withOpacity(0.1));
  }
}

import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import 'light_source.dart';

class TimedLightSource extends LightSource {
  final double interval;
  final double startDelay;
  double _timer = 0;
  bool _isOn = true;

  @override
  bool get isActive => _isOn;

  TimedLightSource({
    required Vector2 position,
    required Color color,
    required double angle,
    this.interval = 2.0,
    this.startDelay = 0.0,
  }) : super(
          position: position,
          color: color,
          angle: angle,
        ) {
      _timer = -startDelay; // Negative timer for initial delay
      if (startDelay > 0) _isOn = false;
  }

  @override
  void update(double dt) {
    super.update(dt);
    _timer += dt;
    if (_timer >= interval) {
      _timer = 0;
      _isOn = !_isOn;
    } else if (_timer < 0) {
        // In delay phase
        // _isOn matches initial state? usually off if delayed?
        // Let's assume startDelay implies "wait before starting cycle".
        // If we want it to start ON, then toggle OFF, loop.
        // If startDelay > 0, we might want it OFF until delay ends.
    }
  }
  
  @override
  void render(Canvas canvas) {
      // Dim if off
      if (!_isOn) {
          canvas.drawCircle(
              (size / 2).toOffset(),
              size.x / 2,
              Paint()
                ..color = color.withOpacity(0.2)
                ..style = PaintingStyle.stroke
                ..strokeWidth = 2,
            );
            return;
      }
      super.render(canvas);
  }
}


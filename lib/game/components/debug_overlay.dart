import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import '../prismaze_game.dart';
import '../audio_manager.dart';
import 'mirror.dart';
import 'prism.dart';
import 'target.dart';
import 'light_source.dart';
import 'beam_system.dart';

import 'package:flame/events.dart'; // Added for TapCallbacks

/// Enhanced Debug visualization with performance profiling
class DebugOverlay extends Component with HasGameRef<PrismazeGame>, TapCallbacks {
  final List<Vector2> _intersectionPoints = [];
  bool _debugEnabled = false;
  
  @override
  int get priority => 1000;
  
  // FPS Tracking
  double _fps = 60.0;
  double _updateTimer = 0.0;
  
  // Frame Time Tracking (ms)
  double _avgFrameTime = 0.0;
  double _maxFrameTime = 0.0;
  double _minFrameTime = 999.0;
  int _frameCount = 0;
  
  // Component Counts
  int _mirrorCount = 0;
  int _prismCount = 0;
  int _targetCount = 0;
  int _beamSegmentCount = 0;
  int _particleCount = 0;
  int _totalComponentCount = 0;
  
  // Performance Bottleneck Detection
  double _lastUpdateTime = 0.0;
  double _lastRenderTime = 0.0;
  String _performanceWarning = '';
  
  // Text painters
  final TextPainter _textPainter = TextPainter(textDirection: TextDirection.ltr);
  
  void addIntersectionPoint(Vector2 point) {
    _intersectionPoints.add(point);
  }
  
  void clearIntersectionPoints() {
    _intersectionPoints.clear();
  }
  
  @override
  void update(double dt) {
    super.update(dt);
    
    _debugEnabled = gameRef.settingsManager.debugModeEnabled;
    
    if (dt > 0) {
      // FPS calculation
      final currentFps = 1.0 / dt;
      _fps = _fps * 0.9 + currentFps * 0.1;
      
      // Frame time tracking (milliseconds)
      final frameTimeMs = dt * 1000;
      _avgFrameTime = _avgFrameTime * 0.95 + frameTimeMs * 0.05;
      _maxFrameTime = frameTimeMs > _maxFrameTime ? frameTimeMs : _maxFrameTime * 0.99;
      _minFrameTime = frameTimeMs < _minFrameTime ? frameTimeMs : _minFrameTime * 0.99;
      _frameCount++;
      
      // Update component counts every 0.5s
      _updateTimer += dt;
      if (_updateTimer > 0.5) {
        _updateMetricsText();
        _updateTimer = 0;
        
        // Reset max frame time periodically
        if (_frameCount % 60 == 0) {
          _maxFrameTime = frameTimeMs;
        }
      }
      
      // Performance warning detection
      _detectPerformanceIssues(dt);
    }
  }
  
  void _detectPerformanceIssues(double dt) {
    _performanceWarning = '';
    
    // Check for frame drops (below 30 FPS)
    if (_fps < 30) {
      _performanceWarning = '⚠️ LOW FPS';
    }
    
    // Check for long frame times (>33ms = <30 FPS)
    if (dt > 0.033) {
      _performanceWarning = '⚠️ FRAME SPIKE: ${(dt * 1000).toStringAsFixed(1)}ms';
    }
    
    // Check for excessive components
    if (_totalComponentCount > 200) {
      _performanceWarning = '⚠️ TOO MANY COMPONENTS: $_totalComponentCount';
    }
    
    // Check for excessive particles
    if (_particleCount > 100) {
      _performanceWarning = '⚠️ TOO MANY PARTICLES: $_particleCount';
    }
    
    // Check for excessive beam segments
    if (_beamSegmentCount > 50) {
      _performanceWarning = '⚠️ TOO MANY BEAMS: $_beamSegmentCount';
    }
  }
  
  void _updateMetricsText() {
    // Count all components
    _mirrorCount = gameRef.world.children.whereType<Mirror>().length;
    _prismCount = gameRef.world.children.whereType<Prism>().length;
    _targetCount = gameRef.world.children.whereType<Target>().length;
    _totalComponentCount = gameRef.world.children.length;
    
    // Get beam system metrics
    _beamSegmentCount = gameRef.beamSystem.debugSegmentCount;
    _particleCount = gameRef.beamSystem.debugParticleCount;
    
    final sfxPlayers = AudioManager().debugActiveSfxCount;
    
    // Build detailed metrics text
    final metricsBuffer = StringBuffer();
    
    // === CRITICAL METRICS (Top Priority) ===
    metricsBuffer.writeln('═══ PERFORMANCE ═══');
    metricsBuffer.writeln('FPS: ${_fps.toStringAsFixed(1)} / 60');
    metricsBuffer.writeln('Frame: ${_avgFrameTime.toStringAsFixed(2)}ms avg');
    metricsBuffer.writeln('       ${_minFrameTime.toStringAsFixed(2)}ms min');
    metricsBuffer.writeln('       ${_maxFrameTime.toStringAsFixed(2)}ms max');
    
    final style = TextStyle(
      color: _fps < 30 ? Colors.red : (_fps < 50 ? Colors.yellow : Colors.green),
      fontSize: 11,
      fontWeight: FontWeight.bold,
      shadows: [
        Shadow(blurRadius: 3, color: Colors.black, offset: Offset(1, 1))
      ],
    );
    
    _textPainter.text = TextSpan(
      text: metricsBuffer.toString().trimRight(),
      style: style,
    );
    _textPainter.layout();
  }
  
  @override
  void render(Canvas canvas) {
    if (!_debugEnabled) return;
    
    final renderStartTime = DateTime.now();
    
    // 1. Always Draw Performance Metrics (Metrics-Only Mode by default)
    _drawPerformanceMetrics(canvas);

    // 2. Draw Heavy Visuals ONLY if Full Debug is enabled
    if (_showFullDebug) {
      _drawPlayAreaBounds(canvas);
      _drawMirrorHitboxes(canvas);
      _drawPrismHitboxes(canvas);
      _drawTargetHitboxes(canvas);
      _drawLightSourceHitboxes(canvas);
      _drawIntersectionPoints(canvas);
    }
    
    // Track render time
    _lastRenderTime = DateTime.now().difference(renderStartTime).inMicroseconds / 1000.0;
  }
  
  // Toggle for full debug mode
  bool _showFullDebug = false;
  
  @override
  void onTapDown(TapDownEvent event) {
     // Simple way to toggle: Tap the overlay
     _showFullDebug = !_showFullDebug;
  }
  
  void _drawPerformanceMetrics(Canvas canvas) {
    if (_textPainter.text == null) _updateMetricsText();
    
    // Background with warning color
    final bgColor = _fps < 30 
        ? Colors.red.withOpacity(0.5)
        : (_fps < 50 ? Colors.orange.withOpacity(0.5) : Colors.black.withOpacity(0.5));
    
    canvas.drawRect(
      Rect.fromLTWH(10, 10, _textPainter.width + 20, _textPainter.height + 20),
      Paint()..color = bgColor
    );
    
    // Border
    canvas.drawRect(
      Rect.fromLTWH(10, 10, _textPainter.width + 20, _textPainter.height + 20),
      Paint()
        ..color = Colors.white
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
    );
    
    _textPainter.paint(canvas, const Offset(20, 20));
  }
  
  void _drawPlayAreaBounds(Canvas canvas) {
    const gridSize = 85.0;
    const double offsetX = 45.0;
    const double offsetY = 62.5;
    const int cols = 14;
    const int rows = 7;
    
    final gridPaint = Paint()
      ..color = Colors.cyan.withOpacity(0.15)
      ..strokeWidth = 1;
    
    // Vertical lines
    for (int i = 0; i <= cols; i++) {
      final x = offsetX + i * gridSize;
      canvas.drawLine(
        Offset(x, offsetY),
        Offset(x, offsetY + rows * gridSize),
        gridPaint,
      );
    }
    
    // Horizontal lines
    for (int i = 0; i <= rows; i++) {
      final y = offsetY + i * gridSize;
      canvas.drawLine(
        Offset(offsetX, y),
        Offset(offsetX + cols * gridSize, y),
        gridPaint,
      );
    }
  }
  
  void _drawMirrorHitboxes(Canvas canvas) {
    final paint = Paint()
      ..color = Colors.green.withOpacity(0.5)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    
    for (final mirror in gameRef.world.children.whereType<Mirror>()) {
      final rect = Rect.fromCenter(
        center: Offset(mirror.position.x, mirror.position.y),
        width: mirror.size.x + 10,
        height: mirror.size.y + 10,
      );
      canvas.drawRect(rect, paint);
    }
  }
  
  void _drawPrismHitboxes(Canvas canvas) {
    final paint = Paint()
      ..color = Colors.purple.withOpacity(0.5)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    
    for (final prism in gameRef.world.children.whereType<Prism>()) {
      final rect = Rect.fromCenter(
        center: Offset(prism.position.x, prism.position.y),
        width: prism.size.x,
        height: prism.size.y,
      );
      canvas.drawRect(rect, paint);
    }
  }
  
  void _drawTargetHitboxes(Canvas canvas) {
    final paint = Paint()
      ..color = Colors.orange.withOpacity(0.5)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    
    for (final target in gameRef.world.children.whereType<Target>()) {
      canvas.drawCircle(
        target.position.toOffset(),
        target.size.x / 2,
        paint,
      );
    }
  }
  
  void _drawLightSourceHitboxes(Canvas canvas) {
    for (final source in gameRef.world.children.whereType<LightSource>()) {
      canvas.drawCircle(
        source.position.toOffset(),
        10,
        Paint()
          ..color = Colors.white.withOpacity(0.5)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2,
      );
    }
  }
  
  void _drawIntersectionPoints(Canvas canvas) {
    for (final point in _intersectionPoints) {
      canvas.drawCircle(
        point.toOffset(),
        8,
        Paint()
          ..color = Colors.yellow.withOpacity(0.5)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2,
      );
      canvas.drawCircle(
        point.toOffset(),
        3,
        Paint()..color = Colors.yellow,
      );
    }
  }
}

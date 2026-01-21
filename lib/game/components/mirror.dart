import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flutter/material.dart';
import '../audio_manager.dart';
import '../prismaze_game.dart';
import '../game_bounds.dart';
import '../utils/visual_effects.dart';
import '../procedural/models/models.dart' as proc;
import 'wall.dart';
import 'prism.dart';
import 'dart:math';

class Mirror extends PositionComponent with DragCallbacks, DoubleTapCallbacks, TapCallbacks, HasGameRef<PrismazeGame> {
  // Visual state
  double _shineOffset = -1.0;
  bool _isRotating = false;
  bool isLocked = false;
  double _time = 0;
  double _lightHitIntensity = 0; // Glow when light hits
  
  /// Discrete orientation (0-3) for the new procedural system.
  /// 0 = horizontal "_", 1 = slash "/", 2 = vertical "|", 3 = backslash "\"
  int _discreteOrientation = 0;
  
  /// Whether this mirror uses discrete orientation (campaign mode).
  /// When true, drag is disabled and tap rotates through 4 states.
  bool useDiscreteOrientation = false;
  
  /// Whether drag movement is allowed (false in campaign/episode mode).
  bool allowDrag = true;
  
  // Track move for undo
  Vector2 _dragStartPos = Vector2.zero();
  double _dragStartAngle = 0;
  
  // Track for movement detection
  DateTime _dragStartTime = DateTime.now();
  bool _hasMoved = false;

  double opacity = 1.0;
  
  // Premium color scheme
  static const _frameGoldDark = Color(0xFFB8860B);     // Dark gold
  static const _frameGoldLight = Color(0xFFFFD700);    // Bright gold
  static const _frameGoldMid = Color(0xFFD4AF37);      // Classic gold
  static const _chromeDark = Color(0xFF8A9BAE);        // Dark chrome
  static const _chromeLight = Color(0xFFE8EEF4);       // Bright chrome
  static const _chromeMid = Color(0xFFB8C5D6);         // Mid chrome
  static const _glowColor = Color(0xFF64FFDA);         // Cyan accent glow
  static const _impactColor = Color(0xFFFFFFFF);       // White impact flash

  Mirror({
    required Vector2 position,
    double angle = 0,
    this.isLocked = false,
    int discreteOrientation = 0,
    this.useDiscreteOrientation = false,
    this.allowDrag = true,
  }) : _discreteOrientation = discreteOrientation,
       super(
          position: position,
          size: Vector2(54, 14), // Maximize width within 55px cell
          angle: angle,
          anchor: Anchor.center,
        );
  
  /// Called by BeamSystem when light hits this mirror
  void onLightHit() {
    _lightHitIntensity = 1.0;
  }
  
  /// Get discrete orientation for procedural system.
  int get discreteOrientation => _discreteOrientation;
  
  /// Set discrete orientation and update visual angle.
  set discreteOrientation(int value) {
    _discreteOrientation = value % 4;
    if (useDiscreteOrientation) {
      angle = _discreteOrientationToAngle(_discreteOrientation);
    }
  }
  
  /// Convert discrete orientation to visual angle (45° increments).
  static double _discreteOrientationToAngle(int orientation) {
    // 0 = 0°, 1 = 45°, 2 = 90°, 3 = 135° (consistent increments)
    return (orientation % 4) * pi / 4;
  }
  
  /// Convert from procedural model.
  factory Mirror.fromProcedural(proc.Mirror m, {bool allowDrag = false}) {
    final angle = _discreteOrientationToAngle(m.orientation.index);
    return Mirror(
      position: Vector2(
        m.position.x * proc.GridPosition.cellSize + proc.GridPosition.cellSize / 2,
        m.position.y * proc.GridPosition.cellSize + proc.GridPosition.cellSize / 2,
      ),
      angle: angle,
      isLocked: !m.rotatable,
      discreteOrientation: m.orientation.index,
      useDiscreteOrientation: true,
      allowDrag: allowDrag,
    );
  }

  // ===== TAP TO ROTATE (Campaign mode) =====
  @override
  void onTapUp(TapUpEvent event) {
    if (isLocked) return;
    if (!useDiscreteOrientation) return; // Use double-tap for legacy
    
    // Record for undo
    final startPos = position.clone();
    final startAngle = angle;
    
    // Rotate to next discrete state
    _discreteOrientation = (_discreteOrientation + 1) % 4;
    angle = _discreteOrientationToAngle(_discreteOrientation);
    
    print('MIRROR TAP ROTATE! orientation=$_discreteOrientation');
    _triggerShine();
    AudioManager().playSfx('mirror_tap_sound.mp3');
    
    gameRef.recordMove(hashCode, startPos, startAngle);
    gameRef.requestBeamUpdate();
  }
  
  // ===== DOUBLE TAP TO ROTATE (Legacy mode) =====
  @override
  void onDoubleTapDown(DoubleTapDownEvent event) {
    if (isLocked) return;
    if (useDiscreteOrientation) return; // Use single tap for campaign
    
    // Record for undo
    final startPos = position.clone();
    final startAngle = angle;
    
    // ROTATE 45 degrees
    angle += pi / 4;
    if (angle >= 2 * pi) angle -= 2 * pi;
    
    print('MIRROR DOUBLE-TAP ROTATE! angle=${(angle * 180 / pi).toStringAsFixed(0)}°');
    _triggerShine();
    AudioManager().playSfx('mirror_tap_sound.mp3');
    
    // Record move using hashCode as ID (guaranteed unique)
    gameRef.recordMove(hashCode, startPos, startAngle);
    
    gameRef.requestBeamUpdate();
  }

  @override
  void update(double dt) {
      super.update(dt);
      _time += dt;
      
      // Animate shine if rotating (or just triggered)
      if (_shineOffset > -1.0) {
          _shineOffset += dt * 2.5; // Speed
          if (_shineOffset > 2.0) {
              _shineOffset = -1.0; // Reset
              _isRotating = false;
          }
      }
      
      // Decay light hit intensity
      if (_lightHitIntensity > 0) {
        _lightHitIntensity -= dt * 3.0; // Fade over ~0.3s
        if (_lightHitIntensity < 0) _lightHitIntensity = 0;
      }
  }

  @override
  void render(Canvas canvas) {
    if (opacity == 0) return;
    
    final rect = size.toRect();
    final rrect = RRect.fromRectAndRadius(rect, const Radius.circular(6));
    
    // Check accessibility settings
    final bool reducedGlow = gameRef.settingsManager.reducedGlowEnabled;
    final bool highContrast = gameRef.settingsManager.highContrastEnabled;
    
    if (highContrast) {
      // High Contrast Mode: Simple solid with white border
      canvas.drawRRect(rrect, Paint()..color = Colors.grey.shade800.withOpacity(opacity));
      canvas.drawRRect(
        rrect,
        Paint()
          ..color = Colors.white.withOpacity(opacity)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2,
      );
      return;
    }

    // === LAYER 1: Drop Shadow (Depth) ===
    if (!reducedGlow) {
      final shadowRRect = rrect.shift(const Offset(2, 3));
      canvas.drawRRect(
        shadowRRect,
        Paint()
          ..color = Colors.black.withOpacity(0.35 * opacity)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4),
      );
    }

    // === LAYER 2: Golden Frame (Outer) ===
    final frameGradient = LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [
        _frameGoldDark.withOpacity(opacity),
        _frameGoldLight.withOpacity(opacity),
        _frameGoldMid.withOpacity(opacity),
        _frameGoldDark.withOpacity(opacity),
      ],
      stops: const [0.0, 0.35, 0.65, 1.0],
    );
    
    canvas.drawRRect(
      rrect,
      Paint()..shader = frameGradient.createShader(rect),
    );
    
    // Frame inner shadow (inset effect)
    final innerShadowRRect = RRect.fromRectAndRadius(
      rect.deflate(1),
      const Radius.circular(5),
    );
    canvas.drawRRect(
      innerShadowRRect,
      Paint()
        ..color = Colors.black.withOpacity(0.3 * opacity)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1,
    );

    // === LAYER 3: Chrome Mirror Surface ===
    final innerRect = Rect.fromCenter(
      center: rect.center,
      width: size.x - 8,
      height: size.y - 5,
    );
    final innerRRect = RRect.fromRectAndRadius(innerRect, const Radius.circular(3));
    
    // Chrome gradient (creates curved/reflective look)
    final chromeGradient = LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [
        _chromeDark.withOpacity(opacity),
        _chromeLight.withOpacity(0.95 * opacity),
        _chromeMid.withOpacity(opacity),
        _chromeDark.withOpacity(opacity),
      ],
      stops: const [0.0, 0.3, 0.7, 1.0],
    );
    
    canvas.drawRRect(
      innerRRect,
      Paint()..shader = chromeGradient.createShader(innerRect),
    );

    // === LAYER 4: Idle Shimmer (Subtle sweep) ===
    if (!reducedGlow) {
      final shimmerPhase = (_time * 0.3) % 3.0; // Slow sweep every 3 seconds
      if (shimmerPhase < 1.0) {
        final shimmerPos = shimmerPhase * (size.x + 30) - 15;
        canvas.save();
        canvas.clipRRect(innerRRect);
        canvas.drawRect(
          Rect.fromLTWH(shimmerPos - 10, 0, 20, size.y),
          Paint()
            ..shader = LinearGradient(
              colors: [
                Colors.white.withOpacity(0.0),
                Colors.white.withOpacity(0.25 * opacity),
                Colors.white.withOpacity(0.0),
              ],
            ).createShader(Rect.fromLTWH(shimmerPos - 10, 0, 20, size.y)),
        );
        canvas.restore();
      }
    }

    // === LAYER 5: Rotation Shine Effect ===
    if (_shineOffset > -1.0 || _isRotating) {
      canvas.save();
      canvas.clipRRect(innerRRect);
      
      final glarePos = _shineOffset * size.x;
      canvas.drawRect(
        innerRect,
        Paint()
          ..shader = LinearGradient(
            colors: [
              Colors.white.withOpacity(0.0),
              Colors.white.withOpacity(0.95 * opacity),
              Colors.white.withOpacity(0.0),
            ],
            stops: const [0.0, 0.5, 1.0],
          ).createShader(Rect.fromLTWH(glarePos - 25, 0, 50, size.y)),
      );
      canvas.restore();
    }

    // === LAYER 6: Light Impact Glow ===
    if (_lightHitIntensity > 0 && !reducedGlow) {
      // Edge glow intensifies
      VisualEffects.drawCrystalGlow(
        canvas,
        rrect,
        _impactColor,
        intensity: _lightHitIntensity * 0.8,
        opacity: opacity,
        reducedGlow: false,
      );
      
      // Surface flash
      canvas.drawRRect(
        innerRRect,
        Paint()
          ..color = _impactColor.withOpacity(_lightHitIntensity * 0.4 * opacity)
          ..maskFilter = const MaskFilter.blur(BlurStyle.solid, 3),
      );
    }

    // === LAYER 7: Frame Glow (Pulsing) ===
    if (!reducedGlow) {
      final pulseIntensity = 0.3 + 0.1 * sin(_time * 2.5);
      canvas.drawRRect(
        rrect,
        Paint()
          ..color = _glowColor.withOpacity(pulseIntensity * opacity)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2
          ..maskFilter = const MaskFilter.blur(BlurStyle.solid, 3),
      );
    }
    
    // === LAYER 8: Crisp Frame Border ===
    canvas.drawRRect(
      rrect,
      Paint()
        ..color = _frameGoldLight.withOpacity(0.9 * opacity)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1,
    );
    
    // Locked Indicator
    if (isLocked) {
      canvas.drawCircle(
        Offset(size.x / 2, size.y / 2),
        4,
        Paint()..color = Colors.redAccent.withOpacity(opacity),
      );
      canvas.drawCircle(
        Offset(size.x / 2, size.y / 2),
        2,
        Paint()..color = Colors.white.withOpacity(opacity),
      );
    }
  }


  // Physics Line Segment
  Vector2 get startPoint {
    final localStart = Vector2(0, size.y / 2);
    return absolutePositionOf(localStart);
  }

  Vector2 get endPoint {
    final localEnd = Vector2(size.x, size.y / 2);
    return absolutePositionOf(localEnd);
  }

  // --- Interaction ---
  
  @override
  void onDragStart(DragStartEvent event) {
    if (isLocked) return;
    super.onDragStart(event); // Always call super for drag lifecycle
    _dragStartPos = position.clone();
    _dragStartAngle = angle;
    _dragStartTime = DateTime.now();
    _hasMoved = false;
  }

  @override
  void onDragUpdate(DragUpdateEvent event) {
    if (isLocked) return;
    if (!allowDrag) return; // Campaign mode disables drag
    
    // Store old position for collision rollback
    final oldPosition = position.clone();
    
    // Calculate global delta from localDelta
    final globalDelta = event.localDelta.clone()..rotate(angle);
    
    // Apply zoom correction
    position += globalDelta / gameRef.camera.viewfinder.zoom;
    
    // BOUNDARY CHECK via GameBounds
    position = GameBounds.clampPosition(position, size);
    
    // WALL COLLISION CHECK
    if (_collidesWithWall()) {
      position = oldPosition; // Revert if colliding
      return;
    }
    
    // OBJECT COLLISION CHECK
    if (_collidesWithObjects()) {
      position = oldPosition;
      return;
    }
    
    // Only mark as moved if significant movement from start
    final distFromStart = (position - _dragStartPos).length;
    if (distFromStart > 10) {
      _hasMoved = true;
    }
    
    // Snap to Grid (20px) if enabled
    if (gameRef.settingsManager.snapToGrid) {
        position.x = (position.x / 20).round() * 20.0;
        position.y = (position.y / 20).round() * 20.0;
    }
    
    gameRef.requestBeamUpdate(); 
  }
  
  bool _collidesWithWall() {
    final mirrorRect = Rect.fromCenter(
      center: Offset(position.x, position.y),
      width: size.x + 10, // Add buffer
      height: size.y + 10,
    );
    
    for (final wall in gameRef.world.children.whereType<Wall>()) {
      final wallRect = Rect.fromLTWH(
        wall.position.x,
        wall.position.y,
        wall.size.x,
        wall.size.y,
      );
      if (mirrorRect.overlaps(wallRect)) {
        return true;
      }
    }
    return false;
  }
  
  bool _collidesWithObjects() {
    final mirrorRect = Rect.fromCenter(
      center: Offset(position.x, position.y),
      width: size.x + 5,
      height: size.y + 5,
    );
    
    // Check other mirrors
    for (final other in gameRef.world.children.whereType<Mirror>()) {
      if (other == this) continue;
      final otherRect = Rect.fromCenter(
        center: Offset(other.position.x, other.position.y),
        width: other.size.x,
        height: other.size.y,
      );
      if (mirrorRect.overlaps(otherRect)) return true;
    }
    
    // Check prisms
    for (final prism in gameRef.world.children.whereType<Prism>()) {
      final prismRect = Rect.fromCenter(
        center: Offset(prism.position.x, prism.position.y),
        width: prism.size.x,
        height: prism.size.y,
      );
      if (mirrorRect.overlaps(prismRect)) return true;
    }
    
    return false;
  }

  @override
  void onDragEnd(DragEndEvent event) {
    if (isLocked) return;
    super.onDragEnd(event);
    
    // Calculate drag duration
    final dragDuration = DateTime.now().difference(_dragStartTime);
    final isQuickTap = dragDuration.inMilliseconds < 400 && !_hasMoved;
    
    print('Mirror onDragEnd: duration=${dragDuration.inMilliseconds}ms, hasMoved=$_hasMoved, isQuickTap=$isQuickTap');
    
    // TAP ROTATION: If quick tap (< 400ms) and didn't move, rotate the mirror
    if (isQuickTap) {
      _rotateDiscrete();
      AudioManager().playSfx('mirror_tap_sound.mp3');
      gameRef.recordMove(hashCode, position.clone(), _dragStartAngle);
      gameRef.requestBeamUpdate();
      return;
    }
    
    // Only plays sound if actually moved
    if (_hasMoved) {
      AudioManager().playSfx('mirror_tap_sound.mp3');
    }
    
    // Record move for undo (only if position changed)
    if (position != _dragStartPos) {
       gameRef.recordMove(hashCode, _dragStartPos, _dragStartAngle);
    }
    
    gameRef.requestBeamUpdate();
  }
  
  /// Rotate the mirror by 45 degrees (one discrete step).
  void _rotateDiscrete() {
    // First, derive current discrete orientation from actual angle
    // This ensures we're in sync even if _discreteOrientation wasn't initialized
    _discreteOrientation = ((angle / (pi / 4)).round() % 4).abs();
    
    // Advance to next position
    _discreteOrientation = (_discreteOrientation + 1) % 4;
    angle = _discreteOrientationToAngle(_discreteOrientation);
    _triggerShine();
    
    print('Mirror rotated to orientation $_discreteOrientation, angle=${(angle * 180 / pi).toStringAsFixed(1)}°');
  }
  
  // NOTE: onTapUp is NOT used because DragCallbacks intercepts all touches.
  // Tap detection is handled in onDragEnd via timing check.
  
  void _triggerShine() {
      _isRotating = true;
      _shineOffset = -0.5; // Start off-left
  }
}

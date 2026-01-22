import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flame/sprite.dart';
import 'package:flutter/material.dart';
import '../audio_manager.dart';
import '../prismaze_game.dart';
import 'dart:math';
import '../game_bounds.dart';
import '../procedural/models/models.dart' as proc;
import 'wall.dart';
import 'mirror.dart';

class Prism extends PositionComponent with DragCallbacks, TapCallbacks, HasGameRef<PrismazeGame> {
  bool _isDragging = false;
  double _visualAngleOffset = 0;
  double _time = 0;
  bool isLocked = false;
  double _lightHitIntensity = 0; // Flash when light enters
  double _floatOffset = 0; // Floating animation

  double opacity = 1.0;
  
  /// Discrete orientation (0-3) for the new procedural system.
  int _discreteOrientation = 0;
  
  /// Whether this prism uses discrete orientation (campaign mode).
  bool useDiscreteOrientation = false;
  
  /// Whether drag movement is allowed (false in campaign/episode mode).
  bool allowDrag = true;
  
  /// Prism type for procedural system.
  proc.PrismType prismType = proc.PrismType.splitter;
  
  // Track move for undo
  Vector2 _dragStartPos = Vector2.zero();
  double _dragStartAngle = 0;
  
  // Track for tap detection
  DateTime _dragStartTime = DateTime.now();
  bool _hasMoved = false;
  
  // Premium color scheme
  static const _crystalClear = Color(0xFFE8F4FC);
  static const _crystalCore = Color(0xFF88DDFF);
  static const _edgeHighlight = Color(0xFFFFFFFF);
  
  // Rainbow refraction colors
  static const _rainbowColors = [
    Color(0xFFFF6B6B), // Red
    Color(0xFFFFE66D), // Yellow
    Color(0xFF4ECB71), // Green
    Color(0xFF4DABF7), // Blue
    Color(0xFFDA77F2), // Purple
  ];
  
  // Sprite for crystal image
  Sprite? _prismSprite;
  
  // Color of the light hitting this prism (for glow effect)
  Color _hitLightColor = const Color(0xFF88DDFF);

  // === OPTIMIZATION: CACHED PAINTS ===
  final Paint _basePaint = Paint();
  final Paint _strokePaint = Paint()..style = PaintingStyle.stroke;
  final Paint _glowPaint = Paint();
  
  // Static MaskFilters
  static const _blur4 = MaskFilter.blur(BlurStyle.normal, 4);

  Prism({
    required Vector2 position,
    double angle = 0,
    this.isLocked = false,
    int discreteOrientation = 0,
    this.useDiscreteOrientation = false,
    this.allowDrag = true,
    this.prismType = proc.PrismType.splitter,
  }) : _discreteOrientation = discreteOrientation,
       super(
          position: position,
          size: Vector2(54, 54), // Maximize size within 55px cell
          angle: angle,
          anchor: Anchor.center,
        );
  
  /// Get discrete orientation for procedural system.
  int get discreteOrientation => _discreteOrientation;
  
  /// Set discrete orientation and update visual angle.
  set discreteOrientation(int value) {
    _discreteOrientation = value % 4;
    if (useDiscreteOrientation) {
      angle = _discreteOrientationToAngle(_discreteOrientation);
    }
  }
  
  /// Convert discrete orientation to visual angle (90° increments).
  static double _discreteOrientationToAngle(int orientation) {
    return (orientation % 4) * pi / 2;
  }
  
  /// Convert from procedural model.
  factory Prism.fromProcedural(proc.Prism p, {bool allowDrag = false}) {
    final angle = _discreteOrientationToAngle(p.orientation);
    return Prism(
      position: Vector2(
        p.position.x * proc.GridPosition.cellSize + proc.GridPosition.cellSize / 2,
        p.position.y * proc.GridPosition.cellSize + proc.GridPosition.cellSize / 2,
      ),
      angle: angle,
      isLocked: !p.rotatable,
      discreteOrientation: p.orientation,
      useDiscreteOrientation: true,
      allowDrag: allowDrag,
      prismType: p.type,
    );
  }
        
  /// Called when light enters this prism
  void onLightHit([Color? lightColor]) {
    _lightHitIntensity = 1.0;
    if (lightColor != null) {
      _hitLightColor = lightColor;
    }
  }
  
  @override
  Future<void> onLoad() async {
    // Load the appropriate prism sprite based on selected skin
    await _loadPrismSprite();
  }
  
  Future<void> _loadPrismSprite() async {
    final skin = gameRef.customizationManager.selectedSkin;
    
    // Dynamic skin-to-file mapping
    // skin_emerald → Prism_emerald.png
    // skin_crystal → Prism.png (default)
    String spriteFile;
    if (skin == 'skin_crystal') {
      spriteFile = 'Prism.png';
    } else if (skin.startsWith('skin_')) {
      // Extract skin name: skin_emerald → emerald
      final skinName = skin.substring(5); // Remove 'skin_' prefix
      spriteFile = 'Prism_$skinName.png';
    } else {
      spriteFile = 'Prism.png';
    }
    
    try {
      final image = await gameRef.images.load(spriteFile);
      _prismSprite = Sprite(image);
    } catch (e) {
      print('Failed to load $spriteFile sprite: $e');
      // Try loading default if skin sprite not found
      if (spriteFile != 'Prism.png') {
        try {
          final fallback = await gameRef.images.load('Prism.png');
          _prismSprite = Sprite(fallback);
        } catch (e2) {
          print('Failed to load fallback Prism.png: $e2');
        }
      }
    }
  }

  @override
  void update(double dt) {
      super.update(dt);
      _time += dt;
      
      // Visual rotation wobble when dragging (only during drag)
      if (_isDragging) {
           _visualAngleOffset = sin(_time * 10) * 0.08;
      } else if (_visualAngleOffset != 0) {
           _visualAngleOffset = _visualAngleOffset * 0.92;
           if (_visualAngleOffset.abs() < 0.001) _visualAngleOffset = 0;
      }
      
      // Decay light hit intensity
      if (_lightHitIntensity > 0) {
        _lightHitIntensity -= dt * 3.0; // Faster decay
        if (_lightHitIntensity < 0) _lightHitIntensity = 0;
      }
  }

  @override
  void render(Canvas canvas) {
    if (opacity == 0) return;

    // Check accessibility settings
    final bool reducedGlow = gameRef.settingsManager.reducedGlowEnabled;
    final bool highContrast = gameRef.settingsManager.highContrastEnabled;
    
    // Apply wobble effect when dragging
    canvas.save();
    if (_visualAngleOffset != 0) {
      canvas.rotate(_visualAngleOffset);
    }

    final w = size.x;
    final h = size.y;
    final center = Offset(w / 2, h / 2);
    
    // Use the light color that hit this prism for glow effects
    final glowColor = _hitLightColor;

    if (highContrast) {
      // High Contrast: Simple diamond with white border
      final path = Path()
        ..moveTo(w / 2, 0)
        ..lineTo(w, h / 2)
        ..lineTo(w / 2, h)
        ..lineTo(0, h / 2)
        ..close();
      _basePaint.color = Colors.grey.shade700.withOpacity(opacity);
      canvas.drawPath(path, _basePaint);
      
      _strokePaint
        ..color = Colors.white.withOpacity(opacity)
        ..strokeWidth = 2;
      canvas.drawPath(path, _strokePaint);
      canvas.restore();
      return;
    }

    // === LAYER 1: Subtle Drop Shadow ===
    if (!reducedGlow) {
      _glowPaint
        ..color = Colors.black.withOpacity(0.15 * opacity)
        ..maskFilter = _blur4;
      canvas.drawOval(
        Rect.fromCenter(center: center + const Offset(2, 5), width: w * 0.5, height: h * 0.15),
        _glowPaint,
      );
    }

    // === LAYER 2: Main Sprite ===
    if (_prismSprite != null) {
      // Apply opacity if needed
      Paint? spritePaint;
      if (opacity < 1.0) {
        _basePaint.color = Colors.white.withOpacity(opacity);
        spritePaint = _basePaint;
      }
      
      _prismSprite!.render(
        canvas,
        position: Vector2.zero(),
        size: size,
        overridePaint: spritePaint,
      );
      
      // === LAYER 3: Inner Light Reflection (when light is passing through) ===
      if (_lightHitIntensity > 0) {
        // Soft inner glow matching light color - blended on top
        _glowPaint
          ..color = glowColor.withOpacity(_lightHitIntensity * 0.35 * opacity)
          ..blendMode = BlendMode.plus
          ..maskFilter = null;
        canvas.drawOval(
          Rect.fromCenter(center: center, width: w * 0.4, height: h * 0.5),
          _glowPaint,
        );
      }
    } else {
      // Fallback: Draw simple diamond if sprite not loaded
      final path = Path()
        ..moveTo(w / 2, 4)
        ..lineTo(w - 4, h / 2)
        ..lineTo(w / 2, h - 4)
        ..lineTo(4, h / 2)
        ..close();
      _basePaint.color = glowColor.withOpacity(opacity);
      canvas.drawPath(path, _basePaint);
    }

    // Draw lock icon if locked
    if (isLocked) {
      _basePaint.color = Colors.red.withOpacity(0.8 * opacity);
      canvas.drawCircle(center, 6, _basePaint);
      
      _strokePaint
        ..color = Colors.white.withOpacity(opacity)
        ..strokeWidth = 1.5;
      canvas.drawCircle(center, 6, _strokePaint);
    }
    
    canvas.restore();
  }
  @override
  void onDragStart(DragStartEvent event) {
    if (isLocked) return;
    super.onDragStart(event); // Always call super for drag lifecycle
    _dragStartPos = position.clone();
    _dragStartAngle = angle;
    _dragStartTime = DateTime.now();
    _hasMoved = false;
    
    if (allowDrag) {
      _isDragging = true;
      AudioManager().playSfx('crystal_tap_sound.mp3');
      AudioManager().vibratePrismHold(); // 10ms hold
      // Scale up visual feedback
      scale = Vector2.all(1.1);
    }
  }
  @override
  void onDragUpdate(DragUpdateEvent event) {
    if (isLocked) return;
    if (!allowDrag) return; // Campaign mode disables drag
    
    // Store old position for collision rollback
    final oldPosition = position.clone();
    
    // Calculate global delta from localDelta
    // FIX: 1:1 movement, not multiplied
    final globalDelta = event.localDelta.clone()..rotate(angle);
    
    // Apply zoom correction
    position += globalDelta / gameRef.camera.viewfinder.zoom;

    // BOUNDARY CHECK via GameBounds
    position = GameBounds.clampPosition(position, size);
    
    // WALL COLLISION CHECK
    if (_collidesWithWall()) {
      position = oldPosition;
      return;
    }
    
    // OBJECT COLLISION CHECK
    if (_collidesWithObjects()) {
      position = oldPosition;
      return;
    }
    
    // Snap to Grid (20px) if enabled
    if (gameRef.settingsManager.snapToGrid) {
        position.x = (position.x / 20).round() * 20.0;
        position.y = (position.y / 20).round() * 20.0;
    }
    
    // Track movement
    final distFromStart = (position - _dragStartPos).length;
    if (distFromStart > 10) {
      _hasMoved = true;
    }
    
    gameRef.requestBeamUpdate(); // Live preview while dragging
  }
  
  @override
  void onDragEnd(DragEndEvent event) {
    if (isLocked) return;
    super.onDragEnd(event);
    _isDragging = false;
    
    // Calculate drag duration for tap detection
    final dragDuration = DateTime.now().difference(_dragStartTime);
    final isQuickTap = dragDuration.inMilliseconds < 400 && !_hasMoved;
    
    print('Prism onDragEnd: duration=${dragDuration.inMilliseconds}ms, hasMoved=$_hasMoved, isQuickTap=$isQuickTap');
    
    // TAP ROTATION: If quick tap (< 400ms) and didn't move, rotate the prism
    if (isQuickTap) {
      _rotateDiscrete();
      gameRef.requestBeamUpdate();
      scale = Vector2.all(1.0);
      return;
    }
    
    // Record move if position changed
    if (position != _dragStartPos) {
       gameRef.recordMove(hashCode, _dragStartPos, _dragStartAngle);
    }
    
    gameRef.requestBeamUpdate();
    
    // Reset scale
    scale = Vector2.all(1.0);
  }
  
  /// Rotate the prism by one discrete step (90°).
  void _rotateDiscrete() {
    final startAng = angle;
    final startPos = position.clone();
    
    // Derive current discrete orientation from actual angle (90° = pi/2 increments)
    _discreteOrientation = ((angle / (pi / 2)).round() % 4).abs();
    
    // Advance to next position
    _discreteOrientation = (_discreteOrientation + 1) % 4;
    angle = _discreteOrientationToAngle(_discreteOrientation);
    
    // Record move using hashCode
    gameRef.recordMove(hashCode, startPos, startAng);
    AudioManager().playSfx('rotate.mp3');
    
    print('Prism rotated to orientation $_discreteOrientation, angle=${(angle * 180 / pi).toStringAsFixed(1)}°');
  }
  
  @override
  void onTapUp(TapUpEvent event) {
      if (isLocked) return;
      
      // Record state before rotate
      final startAng = angle;
      final startPos = position.clone();
      
      if (useDiscreteOrientation) {
        // Campaign mode: 4 states (90° increments)
        _discreteOrientation = (_discreteOrientation + 1) % 4;
        angle = _discreteOrientationToAngle(_discreteOrientation);
      } else {
        // Legacy mode: 60 degrees (PI/3)
        angle += pi / 3;
        if (angle >= 2 * pi) angle -= 2 * pi;
      }
      
      // Record move using hashCode
      gameRef.recordMove(hashCode, startPos, startAng);
      
      gameRef.requestBeamUpdate();
      AudioManager().playSfx('rotate.mp3');
  }

  // Returns vertices in absolute coordinates
  List<Vector2> get absoluteVertices {
    final w = size.x;
    final h = size.y;
    // Matches the render path logic
    final v1 = Vector2(w / 2, 0);
    final v2 = Vector2(w, h);
    final v3 = Vector2(0, h);
    
    return [
      absolutePositionOf(v1),
      absolutePositionOf(v2),
      absolutePositionOf(v3),
    ];
  }
  
  bool _collidesWithWall() {
    final prismRect = Rect.fromCenter(
      center: Offset(position.x, position.y),
      width: size.x + 10,
      height: size.y + 10,
    );
    
    for (final wall in gameRef.world.children.whereType<Wall>()) {
      final wallRect = Rect.fromLTWH(
        wall.position.x,
        wall.position.y,
        wall.size.x,
        wall.size.y,
      );
      if (prismRect.overlaps(wallRect)) {
        return true;
      }
    }
    return false;
  }
  
  bool _collidesWithObjects() {
    final prismRect = Rect.fromCenter(
      center: Offset(position.x, position.y),
      width: size.x + 5,
      height: size.y + 5,
    );
    
    // Check other prisms
    for (final other in gameRef.world.children.whereType<Prism>()) {
      if (other == this) continue;
      final otherRect = Rect.fromCenter(
        center: Offset(other.position.x, other.position.y),
        width: other.size.x,
        height: other.size.y,
      );
      if (prismRect.overlaps(otherRect)) return true;
    }
    
    // Check mirrors
    for (final mirror in gameRef.world.children.whereType<Mirror>()) {
      final mirrorRect = Rect.fromCenter(
        center: Offset(mirror.position.x, mirror.position.y),
        width: mirror.size.x,
        height: mirror.size.y,
      );
      if (prismRect.overlaps(mirrorRect)) return true;
    }
    
    return false;
  }
  
  @override
  bool containsLocalPoint(Vector2 point) {
    bool hasAssist = gameRef.settingsManager.motorAssistEnabled;
    if (hasAssist) {
        // Expand hitbox by 50%
        // Standard check is within size rect? or custom?
        // Default impl checks size. 
        // We can just check Rect with padding.
        final r = size.toRect().inflate(20); // +20px padding all sides
        return r.contains(point.toOffset());
    }
    return super.containsLocalPoint(point);
  }
}


import 'package:flame/components.dart';
import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'dart:math';
import 'light_source.dart';
import 'mirror.dart';
import 'wall.dart';
import 'prism.dart';
import 'target.dart';
import 'filter.dart';
import 'glass_wall.dart';
import 'splitter.dart';
import 'portal.dart';
import 'absorbing_wall.dart';
import '../utils/physics_utils.dart';
import '../utils/color_blindness_utils.dart';
import '../audio_manager.dart';
import '../prismaze_game.dart';
import '../procedural/ray_tracer_adapter.dart';

class BeamSegment {
  final Vector2 start;
  final Vector2 end;
  final Color color;
  
  BeamSegment(this.start, this.end, this.color);
}

class BeamParticle {
  Vector2 position;
  Vector2 velocity;
  Color color;
  double life; // 0.0 to 1.0
  double size;
  
  BeamParticle({
      required this.position, 
      required this.velocity, 
      required this.color,
      this.life = 1.0,
      this.size = 2.0
  });
}

class BeamSystem extends Component with HasGameRef<PrismazeGame> {
  
  final int maxBounces = 10;
  final double maxRayLength = 2000;
  
  // Data Storage
  final List<BeamSegment> _segments = [];
  final List<BeamParticle> _particles = [];
  final Random _rng = Random();
  
  // External segments from RayTracer (procedural mode)
  List<RenderSegment>? _externalSegments;
  
  /// Use RayTracer segments instead of legacy beam calculation.
  /// When true, BeamSystem only renders; it does not compute physics.
  bool useRayTracerMode = false;
  
  // Debug getters
  int get debugParticleCount => _particles.length;
  
  // Debug getters
  int get debugSegmentCount => _segments.length; // Still useful count
  int get debugDrawCalls => _cachedPaths.length; // New metric: reduced draw calls
  
  /// Debug: show ray segments from RayTracer even when not in RayTracer mode.
  bool debugShowRayTracerSegments = false;
  
  bool _needsUpdate = true;
  double _pulseIntensity = 0.0;
  double _time = 0.0; // For energy pulse animation
  
  // === OPTIMIZATION: CACHED COMPONENTS ===
  // We cache these lists to avoid querying the world 8+ times per frame.
  final List<Mirror> _cachedMirrors = [];
  final List<Wall> _cachedWalls = [];
  final List<Prism> _cachedPrisms = [];
  final List<Target> _cachedTargets = [];
  final List<Filter> _cachedFilters = [];
  final List<GlassWall> _cachedGlassWalls = [];
  final List<Splitter> _cachedSplitters = [];
  final List<Portal> _cachedPortals = [];
  final List<AbsorbingWall> _cachedAbsorbingWalls = [];
  final List<LightSource> _cachedSources = [];
  
  // === OPTIMIZATION: CACHED PAINTS ===
  // Reuse Paint objects to prevent GC churn (creating ~1000 objects per second)
  final Paint _hazePaint = Paint()..strokeCap = StrokeCap.round; // blur updated dynamically or pre-set if const
  final Paint _outerGlowPaint = Paint()..strokeCap = StrokeCap.round;
  final Paint _corePaint = Paint()..style = PaintingStyle.stroke..strokeCap = StrokeCap.round..isAntiAlias = true;
  final Paint _innerPaint = Paint()..style = PaintingStyle.stroke..strokeCap = StrokeCap.round..isAntiAlias = true;
  final Paint _pulsePaint = Paint()..style = PaintingStyle.fill..color = Colors.white.withOpacity(0.6)..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);
  
  // Static MaskFilters to reuse
  static const _blur15 = MaskFilter.blur(BlurStyle.normal, 15);
  static const _blur5 = MaskFilter.blur(BlurStyle.normal, 5);
  static const _blur18 = MaskFilter.blur(BlurStyle.normal, 18);
  static const _blur8 = MaskFilter.blur(BlurStyle.normal, 8);
  static const _blur6 = MaskFilter.blur(BlurStyle.normal, 6);
  static const _blur3 = MaskFilter.blur(BlurStyle.normal, 3);
  
  // === OPTIMIZATION: BATCH RENDERER ===
  // Group segments by color to allow batch drawing (drawPath)
  // This reduces draw calls from ~50-100 to ~3-5 per frame.
  final Map<Color, Path> _cachedPaths = {};
  
  void pulseBeams() {
      _pulseIntensity = 1.0;
  }
  
  /// Call this when the level loads or components change significantly (not on move)
  void refreshCache() {
     _cachedMirrors.clear(); _cachedMirrors.addAll(gameRef.world.children.whereType<Mirror>().where((c) => !c.isRemoving));
     _cachedWalls.clear(); _cachedWalls.addAll(gameRef.world.children.whereType<Wall>().where((c) => !c.isRemoving));
     _cachedPrisms.clear(); _cachedPrisms.addAll(gameRef.world.children.whereType<Prism>().where((c) => !c.isRemoving));
     _cachedTargets.clear(); _cachedTargets.addAll(gameRef.world.children.whereType<Target>().where((c) => !c.isRemoving));
     _cachedFilters.clear(); _cachedFilters.addAll(gameRef.world.children.whereType<Filter>().where((c) => !c.isRemoving));
     _cachedGlassWalls.clear(); _cachedGlassWalls.addAll(gameRef.world.children.whereType<GlassWall>().where((c) => !c.isRemoving));
     _cachedSplitters.clear(); _cachedSplitters.addAll(gameRef.world.children.whereType<Splitter>().where((c) => !c.isRemoving));
     _cachedPortals.clear(); _cachedPortals.addAll(gameRef.world.children.whereType<Portal>().where((c) => !c.isRemoving));
     _cachedAbsorbingWalls.clear(); _cachedAbsorbingWalls.addAll(gameRef.world.children.whereType<AbsorbingWall>().where((c) => !c.isRemoving));
     _cachedSources.clear(); _cachedSources.addAll(gameRef.world.children.whereType<LightSource>().where((c) => !c.isRemoving));
     
     // Sort targets for sequencing logic
     _cachedTargets.sort((a, b) => a.sequenceIndex.compareTo(b.sequenceIndex));
     
     requestUpdate();
  }
  
  @override
  void update(double dt) {
     _time += dt;
     
     if (_pulseIntensity > 0) {
         _pulseIntensity -= dt * 2.0; // Fade out in ~0.5s
         if (_pulseIntensity < 0) _pulseIntensity = 0.0;
     }

     if (_needsUpdate) {
         _recalculateBeams();
         _needsUpdate = false;
     }
     
     _updateParticles(dt);
  }
  
  void requestUpdate() {
      _needsUpdate = true;
  }
  
  // Public method calling private impl
  void updateBeams() => requestUpdate();
  
  /// Set external segments from RayTracer.
  /// When set, these segments are rendered instead of (or in addition to) legacy segments.
  void setExternalSegments(List<RenderSegment> segments) {
    _externalSegments = segments;
  }
  
  /// Clear external segments.
  void clearExternalSegments() {
    _externalSegments = null;
  }
  
  /// Render segments from RayTracer (procedural mode).
  /// This is the primary method for campaign/procedural levels.
  void renderRayTracerSegments(List<RenderSegment> segments) {
    _externalSegments = segments;
    // In RayTracer mode, we don't need to recalculate legacy beams
    if (useRayTracerMode) {
      _segments.clear();
    }
  }
  
  void _updateParticles(double dt) {
      // OPTIMIZATION: Skip particles if reduced glow mode
      if (gameRef.settingsManager.reducedGlowEnabled) {
        _particles.clear();
        return;
      }
      
      // OPTIMIZATION: Limit max particles to 50
      const int maxParticles = 50;
      
      // 1. Convert current segments to potential spawn sources
      // For each segment, small chance to spawn a particle
      for (final seg in _segments) {
          if (seg.color.opacity < 0.1) continue;
          if (_particles.length >= maxParticles) break; // Stop if at limit
          
          // OPTIMIZATION: Reduced spawn rate from 0.08 to 0.04
          if (_rng.nextDouble() < 0.04) { 
              final t = _rng.nextDouble();
              final pos = seg.start + (seg.end - seg.start) * t;
              
              // Velocity: Flow along the beam
              final dir = (seg.end - seg.start).normalized();
              final speed = 100.0 + _rng.nextDouble() * 50.0; 
              
              _particles.add(BeamParticle(
                  position: pos,
                  velocity: dir * speed,
                  color: seg.color.withOpacity(0.8), // brighter
                  life: 0.5 + _rng.nextDouble() * 0.5,
                  size: 2.0 + _rng.nextDouble() * 2.0,
              ));
          }
      }
      
      // 2. Update existing particles
      for (int i = _particles.length - 1; i >= 0; i--) {
          final p = _particles[i];
          p.position += p.velocity * dt;
          p.life -= dt;
          
          if (p.life <= 0) {
              _particles.removeAt(i);
          }
      }
  }

  void clearBeams() {
      _segments.clear();
      _particles.clear();
      _externalSegments = null; // Guardrail: Ensure external segments are cleared on level reset
      _cachedPaths.clear(); // CRITICAL FIX: Clear visual cache to prevent ghost beams during transition
  }
  
  void _recalculateBeams() {
    // Skip legacy calculation if in RayTracer mode
    if (useRayTracerMode) {
      _segments.clear();
      return;
    }
    
    _segments.clear(); 

    
    // Use CACHED lists (O(1) access instead of O(N) query)
    if (_cachedMirrors.isEmpty && _cachedWalls.isEmpty && _cachedTargets.isEmpty) {
        // Fallback or auto-init if empty
        refreshCache();
    }

    for (var t in _cachedTargets) t.resetHits();
    
    for (final source in _cachedSources) {
      if (!source.isActive) continue;
      
      _castBeam(
          source.color, 
          source.position, 
          Vector2(1, 0)..rotate(source.beamAngle), 
          _cachedMirrors, _cachedWalls, _cachedPrisms, _cachedTargets, _cachedFilters, _cachedGlassWalls, _cachedSplitters, _cachedPortals, _cachedAbsorbingWalls,
          0
      );
    }
    
    
    // Check Targets (using cached)
    for (var t in _cachedTargets) t.checkStatus();
    
    // Sequence Logic
    for (var t in _cachedTargets) {
        if (t.isLit && t.sequenceIndex > 0) {
             bool predecessorsLit = _cachedTargets.where((other) => 
                other.sequenceIndex > 0 && 
                other.sequenceIndex < t.sequenceIndex
             ).every((other) => other.isLit);
             
             if (!predecessorsLit) {
                 t.setLockedState(); 
             }
        }
    }
    
    // BUILD BATCHES
    _buildBatchedPaths();
  }
  
  void _buildBatchedPaths() {
      _cachedPaths.clear();
      
      for (final seg in _segments) {
          // Optimization: Skip invisible segments
          if (seg.color.opacity < 0.05) continue;
          
          _cachedPaths.putIfAbsent(seg.color, () => Path())
            ..moveTo(seg.start.x, seg.start.y) // Move to start of every segment (assuming disjoint)
            ..lineTo(seg.end.x, seg.end.y);
      }
  }

  void _castBeam(
    Color beamColor,
    Vector2 start,
    Vector2 direction,
    List<Mirror> mirrors,
    List<Wall> walls,
    List<Prism> prisms,
    List<Target> targets,
    List<Filter> filters,
    List<GlassWall> glassWalls,
    List<Splitter> splitters,
    List<Portal> portals,
    List<AbsorbingWall> absorbingWalls,
    int bounces, {
    Set<String>? visitedSegments,
  }) {
    if (bounces >= maxBounces) return;
    
    // Loop detection: track visited segments to prevent infinite loops
    visitedSegments ??= {};
    final segmentKey = '${start.x.toStringAsFixed(0)},${start.y.toStringAsFixed(0)},${direction.x.toStringAsFixed(2)},${direction.y.toStringAsFixed(2)}';
    if (visitedSegments.contains(segmentKey)) return;
    visitedSegments.add(segmentKey);

    Vector2 closestPoint = start + direction * maxRayLength;
    double closestDist = maxRayLength;
    
    // Hit Objects
    Mirror? hitMirror;
    Prism? hitPrism;
    Filter? hitFilter;
    GlassWall? hitGlassWall;
    Splitter? hitSplitter;
    Portal? hitPortal;
    Vector2? hitNormal;
    bool hitWall = false;
    bool hitAbsorbingWall = false;

    // Check Mirrors
    for (final mirror in mirrors) {
      final p1 = mirror.startPoint;
      final p2 = mirror.endPoint;
      final intersection = PhysicsUtils.getLineSegmentIntersection(start, closestPoint, p1, p2);
      
      if (intersection != null) {
        final dist = start.distanceTo(intersection);
        if (dist < closestDist && dist > 3.0) {
          closestDist = dist;
          closestPoint = intersection;
          hitMirror = mirror;
          hitPrism = null; hitWall = false; hitFilter = null; hitGlassWall = null; hitSplitter = null; hitPortal = null;
          Vector2 surfaceDir = p2 - p1;
          hitNormal = Vector2(-surfaceDir.y, surfaceDir.x).normalized();
        }
      }
    }

    // Check Walls
    for (final wall in walls) {
        final corners = wall.corners;
        for (int i = 0; i < 4; i++) {
            final p1 = corners[i];
            final p2 = corners[(i + 1) % 4];
             final intersection = PhysicsUtils.getLineSegmentIntersection(start, closestPoint, p1, p2);

             if (intersection != null) {
                final dist = start.distanceTo(intersection);
                if (dist < closestDist && dist > 3.0) {
                  closestDist = dist;
                  closestPoint = intersection;
                  hitWall = true;
                   hitMirror = null; hitPrism = null; hitFilter = null; hitGlassWall = null; hitSplitter = null; hitPortal = null;
                }
             }
        }
    }
    
    // Check Absorbing Walls
    for (final absWall in absorbingWalls) {
        final corners = absWall.corners;
        for (int i = 0; i < 4; i++) {
            final p1 = corners[i];
            final p2 = corners[(i + 1) % 4];
             final intersection = PhysicsUtils.getLineSegmentIntersection(start, closestPoint, p1, p2);

             if (intersection != null) {
                final dist = start.distanceTo(intersection);
                if (dist < closestDist && dist > 3.0) {
                  closestDist = dist;
                  closestPoint = intersection;
                  hitAbsorbingWall = true;
                  hitWall = false;
                  hitMirror = null; hitPrism = null; hitFilter = null; hitGlassWall = null; hitSplitter = null; hitPortal = null;
                }
             }
        }
    }
    
    // Check Prisms
    for (final prism in prisms) {
        final vertices = prism.absoluteVertices;
        for (int i = 0; i < 3; i++) {
            final p1 = vertices[i];
            final p2 = vertices[(i + 1) % 3];
            final intersection = PhysicsUtils.getLineSegmentIntersection(start, closestPoint, p1, p2);
            
            if (intersection != null) {
                final dist = start.distanceTo(intersection);
                if (dist < closestDist && dist > 3.0) { 
                   closestDist = dist;
                   closestPoint = intersection;
                   hitPrism = prism;
                   hitMirror = null; hitWall = false; hitFilter = null; hitGlassWall = null; hitSplitter = null; hitPortal = null;
                   
                   Vector2 surfaceDir = p2 - p1;
                   hitNormal = Vector2(-surfaceDir.y, surfaceDir.x).normalized();
                }
            }
        }
    }
    
    // Check Filters
    for (final filter in filters) {
        final rect = filter.toAbsoluteRect();
        final corners = [
            Vector2(rect.left, rect.top), Vector2(rect.right, rect.top),
            Vector2(rect.right, rect.bottom), Vector2(rect.left, rect.bottom),
        ];
        for (int i = 0; i < 4; i++) {
            final p1 = corners[i];
            final p2 = corners[(i + 1) % 4];
            final intersection = PhysicsUtils.getLineSegmentIntersection(start, closestPoint, p1, p2);
            if (intersection != null) {
                 final dist = start.distanceTo(intersection);
                 if (dist < closestDist && dist > 3.0) {
                     closestDist = dist;
                     closestPoint = intersection;
                     hitFilter = filter;
                      hitMirror = null; hitPrism = null; hitWall = false; hitGlassWall = null; hitSplitter = null; hitPortal = null;
                 }
            }
        }
    }
    
    // Check Splitters
    for (final splitter in splitters) {
      final p1 = splitter.startPoint;
      final p2 = splitter.endPoint;
      final intersection = PhysicsUtils.getLineSegmentIntersection(start, closestPoint, p1, p2);
      if (intersection != null) {
        final dist = start.distanceTo(intersection);
        if (dist < closestDist && dist > 3.0) {
          closestDist = dist;
          closestPoint = intersection;
          hitSplitter = splitter;
           hitMirror = null; hitPrism = null; hitWall = false; hitGlassWall = null; hitFilter = null; hitPortal = null;
          Vector2 surfaceDir = p2 - p1;
          hitNormal = Vector2(-surfaceDir.y, surfaceDir.x).normalized();
        }
      }
    }
    
    // Check Portals
    for (final portal in portals) {
      final p1 = portal.startPoint;
      final p2 = portal.endPoint;
      final intersection = PhysicsUtils.getLineSegmentIntersection(start, closestPoint, p1, p2);
      if (intersection != null) {
        final dist = start.distanceTo(intersection);
        if (dist < closestDist && dist > 3.0) {
          closestDist = dist;
          closestPoint = intersection;
           hitPortal = portal;
           hitMirror = null; hitPrism = null; hitWall = false; hitGlassWall = null; hitFilter = null; hitSplitter = null;
          hitNormal = Vector2(-(p2 - p1).y, (p2 - p1).x).normalized();
        }
      }
    }
    
    // Check Targets
    for (final target in targets) {
        final beamVec = closestPoint - start;
        final beamLen = beamVec.length;
        if (beamLen < 1) continue;
        final beamDir = beamVec / beamLen;
        
        final targetVec = target.absolutePosition - start;
        final projection = targetVec.dot(beamDir);
        
        if (projection >= 0 && projection <= beamLen) {
            final distToLine = (targetVec - beamDir * projection).length;
            if (distToLine <= target.size.x / 2) { 
                 target.addBeamColor(beamColor);
            }
        }
    }

     // Add Segment (Legacy list kept for logic/particles, but rendering uses paths)
    _segments.add(BeamSegment(start, closestPoint, beamColor));

    // Recursion
    if (hitAbsorbingWall || hitWall) {
      return; // Stop beam
    }
    
    if (hitMirror != null && hitNormal != null) {
      final reflectedDir = PhysicsUtils.getReflectionVector(direction, hitNormal);
      _castBeam(beamColor, closestPoint, reflectedDir, mirrors, walls, prisms, targets, filters, glassWalls, splitters, portals, absorbingWalls, bounces + 1, visitedSegments: visitedSegments);
    } else if (hitSplitter != null && hitNormal != null) {
        _castBeam(beamColor.withOpacity(beamColor.opacity * 0.5), closestPoint, direction, mirrors, walls, prisms, targets, filters, glassWalls, splitters, portals, absorbingWalls, bounces + 1, visitedSegments: visitedSegments);
        final reflectedDir = PhysicsUtils.getReflectionVector(direction, hitNormal);
        _castBeam(beamColor.withOpacity(beamColor.opacity * 0.5), closestPoint, reflectedDir, mirrors, walls, prisms, targets, filters, glassWalls, splitters, portals, absorbingWalls, bounces + 1, visitedSegments: visitedSegments);
    } else if (hitPortal != null && hitNormal != null) {
         try {
            final exitPortal = portals.firstWhere((p) => p.id == hitPortal!.linkedPortalId);
            final exitPoint = exitPortal.absolutePosition;
            final p1_out = exitPortal.startPoint;
            final p2_out = exitPortal.endPoint;
            final surfaceDir = p2_out - p1_out;
            final exitNormal = Vector2(surfaceDir.y, -surfaceDir.x).normalized(); 
            final safeExit = exitPoint + exitNormal * 5;
            _castBeam(beamColor, safeExit, exitNormal, mirrors, walls, prisms, targets, filters, glassWalls, splitters, portals, absorbingWalls, bounces + 1, visitedSegments: visitedSegments);
        } catch (e) {}
    } else if (hitFilter != null) {
         Color nextColor = PhysicsUtils.applyFilter(beamColor, hitFilter!.color);
         if (nextColor.computeLuminance() > 0.01) {
             _castBeam(nextColor, closestPoint, direction, mirrors, walls, prisms, targets, filters, glassWalls, splitters, portals, absorbingWalls, bounces + 1, visitedSegments: visitedSegments);
         }
    } else if (hitGlassWall != null) {
        final nextAlpha = beamColor.opacity * 0.5;
        if (nextAlpha > 0.05) {
            _castBeam(beamColor.withOpacity(nextAlpha), closestPoint, direction, mirrors, walls, prisms, targets, filters, glassWalls, splitters, portals, absorbingWalls, bounces + 1, visitedSegments: visitedSegments);
        }
    } else if (hitPrism != null && hitNormal != null) {
        // Trigger glow effect on prism with the incoming beam color
        hitPrism.onLightHit(beamColor);
        
        bool entering = direction.dot(hitNormal) < 0;
        double n1 = entering ? 1.0 : 1.5;
        double n2 = entering ? 1.5 : 1.0;
        Vector2 calcNormal = entering ? hitNormal : -hitNormal;
        Vector2? refractedDir = PhysicsUtils.getRefractionVector(direction.normalized(), calcNormal, n1, n2);
        
        if (refractedDir != null) {
             _castBeam(beamColor, closestPoint, refractedDir, mirrors, walls, prisms, targets, filters, glassWalls, splitters, portals, absorbingWalls, bounces + 1, visitedSegments: visitedSegments);
        } else {
             final reflectedDir = PhysicsUtils.getReflectionVector(direction, calcNormal);
             _castBeam(beamColor, closestPoint, reflectedDir, mirrors, walls, prisms, targets, filters, glassWalls, splitters, portals, absorbingWalls, bounces + 1, visitedSegments: visitedSegments);
        }
    }
  }

  @override
  void render(Canvas canvas) {
      final bool reducedGlow = gameRef.settingsManager.reducedGlowEnabled;
      final bool highContrast = gameRef.settingsManager.highContrastEnabled;
      
      // Render external RayTracer segments if available
      if (_externalSegments != null && _externalSegments!.isNotEmpty) {
        _renderExternalSegments(canvas, _externalSegments!, reducedGlow, highContrast);
      }
      
      // Render legacy segments if not in RayTracer mode (or if debugging both)
      if (!useRayTracerMode || debugShowRayTracerSegments) {
        _renderLegacySegments(canvas, reducedGlow, highContrast);
      }
  }
  
  /// Render external segments from RayTracer.
  /// OPTIMIZED: Batches segments by color and reuses Paint objects.
  void _renderExternalSegments(
    Canvas canvas,
    List<RenderSegment> segments,
    bool reducedGlow,
    bool highContrast,
  ) {
    if (segments.isEmpty) return;
    
    // High contrast mode: simple solid white lines
    if (highContrast) {
      _corePaint
        ..color = Colors.white
        ..strokeWidth = 6
        ..maskFilter = null;
      
      for (final seg in segments) {
        canvas.drawLine(
          Offset(seg.start.x, seg.start.y),
          Offset(seg.end.x, seg.end.y),
          _corePaint,
        );
      }
      return;
    }
    
    // Build batched paths by color (reduces draw calls significantly)
    final batchedPaths = <Color, Path>{};
    for (final seg in segments) {
      final safeColor = ColorBlindnessUtils.getSafeColor(seg.color);
      batchedPaths.putIfAbsent(safeColor, () => Path())
        ..moveTo(seg.start.x, seg.start.y)
        ..lineTo(seg.end.x, seg.end.y);
    }
    
    // === LAYER 0: Wide outer glow ===
    if (!reducedGlow) {
      _hazePaint.maskFilter = _blur15;
      _hazePaint.strokeWidth = 40;
      
      for (final entry in batchedPaths.entries) {
        _hazePaint.color = entry.key.withOpacity(0.15);
        canvas.drawPath(entry.value, _hazePaint);
      }
    }
    
    // === LAYER 1: Medium glow ===
    _outerGlowPaint.maskFilter = reducedGlow ? _blur5 : const MaskFilter.blur(BlurStyle.normal, 10);
    _outerGlowPaint.strokeWidth = reducedGlow ? 14 : 22;
    
    for (final entry in batchedPaths.entries) {
      _outerGlowPaint.color = entry.key.withOpacity(reducedGlow ? 0.4 : 0.35);
      canvas.drawPath(entry.value, _outerGlowPaint);
    }
    
    // === LAYER 2: Solid core beam ===
    _corePaint.maskFilter = null;
    _corePaint.strokeWidth = 10;
    
    for (final entry in batchedPaths.entries) {
      _corePaint.color = entry.key.withOpacity(0.95);
      canvas.drawPath(entry.value, _corePaint);
    }
    
    // === LAYER 3: White hot inner core ===
    _innerPaint.color = Colors.white.withOpacity(0.95);
    _innerPaint.strokeWidth = 4;
    _innerPaint.maskFilter = null;
    
    for (final path in batchedPaths.values) {
      canvas.drawPath(path, _innerPaint);
    }
    
    // === LAYER 4: Energy pulse (skip in reduced glow mode) ===
    if (!reducedGlow) {
      final pulsePhase = (_time * 1.2) % 1.0;
      for (final seg in segments) {
        final dx = seg.end.x - seg.start.x;
        final dy = seg.end.y - seg.start.y;
        final beamLength = (dx * dx + dy * dy);
        if (beamLength < 400) continue; // Skip short segments (20*20 = 400)
        
        final pulseX = seg.start.x + dx * pulsePhase;
        final pulseY = seg.start.y + dy * pulsePhase;
        canvas.drawCircle(Offset(pulseX, pulseY), 8, _pulsePaint);
      }
    }
  }
  
  /// Render legacy beam segments.
  void _renderLegacySegments(
    Canvas canvas,
    bool reducedGlow,
    bool highContrast,
  ) {
      // High contrast mode: simple solid lines
      if (highContrast) {
        _corePaint
            ..color = Colors.white
            ..strokeWidth = 6
            ..maskFilter = null;
            
        for (final path in _cachedPaths.values) {
             canvas.drawPath(path, _corePaint);
        }
        return;
      }
      
      // === LAYER 0: Ultra-wide atmospheric haze (OPTIMIZED) ===
      if (!reducedGlow) {
        _hazePaint.maskFilter = _blur15;
        _hazePaint.strokeWidth = 40;
        
        for (final entry in _cachedPaths.entries) {
          final safeColor = ColorBlindnessUtils.getSafeColor(entry.key);
          _hazePaint.color = safeColor.withOpacity(0.1);
          canvas.drawPath(entry.value, _hazePaint);
        }
      }
      
      // === LAYER 1: Wide outer glow ===
      // Setup paint once (mask filter changes per mode)
      _outerGlowPaint.maskFilter = reducedGlow ? _blur5 : _blur18;
      
      for (final entry in _cachedPaths.entries) {
        final safeColor = ColorBlindnessUtils.getSafeColor(entry.key);
        final path = entry.value;
        
        if (reducedGlow) {
          // Reduced: Single efficient glow layer
          _outerGlowPaint.color = safeColor.withOpacity(0.4);
          _outerGlowPaint.strokeWidth = 14;
          canvas.drawPath(path, _outerGlowPaint);
        } else {
          // Full quality: Wide atmospheric haze
          _outerGlowPaint.color = safeColor.withOpacity(0.2);
          _outerGlowPaint.strokeWidth = 36;
          canvas.drawPath(path, _outerGlowPaint);
          
          // Medium intense glow (Using same paint, reused)
          _hazePaint.maskFilter = _blur8;
          _hazePaint.color = safeColor.withOpacity(0.45);
          _hazePaint.strokeWidth = 18;
          canvas.drawPath(path, _hazePaint);
        }
      }
      
      // === LAYER 2: Solid core beam ===
      _corePaint.maskFilter = null; // No blur for core
      
      for (final entry in _cachedPaths.entries) {
        final safeColor = ColorBlindnessUtils.getSafeColor(entry.key);
        final path = entry.value;
        double boost = _pulseIntensity * 4.0;
        
        _corePaint.color = safeColor.withOpacity((0.95 + _pulseIntensity * 0.05).clamp(0.0, 1.0));
        _corePaint.strokeWidth = 10 + boost;
        canvas.drawPath(path, _corePaint);
      }
      
      // === LAYER 3: White hot inner core ===
      _innerPaint.color = Colors.white.withOpacity(0.95);
      _innerPaint.strokeWidth = 4;
      _innerPaint.maskFilter = null;
      
      // Combine all paths for white core since color doesn't matter?
      // Actually yes, all cores are white. We can draw them all in one go if we had a unified path.
      // But _cachedPaths is by color. Iterating is fine.
      for (final path in _cachedPaths.values) {
        canvas.drawPath(path, _innerPaint);
      }
      
      // === LAYER 4: Energy pulse traveling along beam ===
      if (!reducedGlow) {
        final pulsePhase = (_time * 1.2) % 1.0; 
        
        for (final segment in _segments) {
          if (segment.color.opacity < 0.1) continue;
          final beamDir = segment.end - segment.start;
          final beamLength = beamDir.length;
          if (beamLength < 20) continue; 
          
          final pulsePos = segment.start + beamDir * pulsePhase;
          canvas.drawCircle(pulsePos.toOffset(), 8, _pulsePaint);
        }
      }
      
      // === LAYER 5: Render particles ===
      // Reuse paints for particles
      _hazePaint.maskFilter = _blur6;
      _outerGlowPaint.maskFilter = _blur3;
      _innerPaint.color = Colors.white; // Reuse inner paint for core
      
      for (final p in _particles) {
        // Outer
        _hazePaint.color = p.color.withOpacity(p.life * 0.2);
        canvas.drawCircle(p.position.toOffset(), p.size * 3, _hazePaint);
        
        // Inner
        _outerGlowPaint.color = p.color.withOpacity(p.life * 0.5);
        canvas.drawCircle(p.position.toOffset(), p.size * 1.5, _outerGlowPaint);
        
        // Core
        _innerPaint.color = Colors.white.withOpacity(p.life * 0.9);
        canvas.drawCircle(p.position.toOffset(), p.size, _innerPaint);
      }
  }
}


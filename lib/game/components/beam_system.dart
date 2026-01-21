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
  
  /// Debug: show ray segments from RayTracer even when not in RayTracer mode.
  bool debugShowRayTracerSegments = false;
  
  bool _needsUpdate = true;
  double _pulseIntensity = 0.0;
  double _time = 0.0; // For energy pulse animation
  
  void pulseBeams() {
      _pulseIntensity = 1.0;
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
  }
  
  void _recalculateBeams() {
    // Skip legacy calculation if in RayTracer mode
    if (useRayTracerMode) {
      _segments.clear();
      return;
    }
    
    _segments.clear(); 

    // Reset Targets - NOW QUERY FROM WORLD
    final targets = gameRef.world.children.whereType<Target>().toList();
    for (var t in targets) t.resetHits();

    // Query interactables FROM WORLD (where level components are added)
    final mirrors = gameRef.world.children.whereType<Mirror>().toList();
    final walls = gameRef.world.children.whereType<Wall>().toList();
    final prisms = gameRef.world.children.whereType<Prism>().toList();
    final filters = gameRef.world.children.whereType<Filter>().toList();
    final glassWalls = gameRef.world.children.whereType<GlassWall>().toList();
    final splitters = gameRef.world.children.whereType<Splitter>().toList();
    final portals = gameRef.world.children.whereType<Portal>().toList();
    final absorbingWalls = gameRef.world.children.whereType<AbsorbingWall>().toList();
    
    final sources = gameRef.world.children.whereType<LightSource>().toList();
    
    for (final source in sources) {
      if (!source.isActive) continue;
      
      _castBeam(
          source.color, 
          source.position, 
          Vector2(1, 0)..rotate(source.beamAngle), 
          mirrors, walls, prisms, targets, filters, glassWalls, splitters, portals, absorbingWalls,
          0
      );
    }
    
    // Check Targets
    targets.sort((a, b) => a.sequenceIndex.compareTo(b.sequenceIndex));
    for (var t in targets) t.checkStatus();
    
     // Sequence Logic
    for (var t in targets) {
        if (t.isLit && t.sequenceIndex > 0) {
             bool predecessorsLit = targets.where((other) => 
                other.sequenceIndex > 0 && 
                other.sequenceIndex < t.sequenceIndex
             ).every((other) => other.isLit);
             
             if (!predecessorsLit) {
                 t.setLockedState(); 
             }
        }
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

    // Add Segment
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
  void _renderExternalSegments(
    Canvas canvas,
    List<RenderSegment> segments,
    bool reducedGlow,
    bool highContrast,
  ) {
    if (highContrast) {
      for (final seg in segments) {
        canvas.drawLine(
          seg.start.toOffset(),
          seg.end.toOffset(),
          Paint()
            ..color = Colors.white
            ..strokeWidth = 6
            ..strokeCap = StrokeCap.round,
        );
      }
      return;
    }
    
    // Layer 1: Wide outer glow
    if (!reducedGlow) {
      for (final seg in segments) {
        final safeColor = ColorBlindnessUtils.getSafeColor(seg.color);
        canvas.drawLine(
          seg.start.toOffset(),
          seg.end.toOffset(),
          Paint()
            ..color = safeColor.withOpacity(0.15)
            ..strokeWidth = 40
            ..strokeCap = StrokeCap.round
            ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 15),
        );
      }
    }
    
    // Layer 2: Medium glow
    for (final seg in segments) {
      final safeColor = ColorBlindnessUtils.getSafeColor(seg.color);
      canvas.drawLine(
        seg.start.toOffset(),
        seg.end.toOffset(),
        Paint()
          ..color = safeColor.withOpacity(reducedGlow ? 0.4 : 0.35)
          ..strokeWidth = reducedGlow ? 14 : 22
          ..strokeCap = StrokeCap.round
          ..maskFilter = MaskFilter.blur(BlurStyle.normal, reducedGlow ? 5 : 10),
      );
    }
    
    // Layer 3: Solid core
    for (final seg in segments) {
      final safeColor = ColorBlindnessUtils.getSafeColor(seg.color);
      canvas.drawLine(
        seg.start.toOffset(),
        seg.end.toOffset(),
        Paint()
          ..color = safeColor.withOpacity(0.95)
          ..strokeWidth = 10
          ..strokeCap = StrokeCap.round,
      );
    }
    
    // Layer 4: White hot core
    for (final seg in segments) {
      canvas.drawLine(
        seg.start.toOffset(),
        seg.end.toOffset(),
        Paint()
          ..color = Colors.white.withOpacity(0.95)
          ..strokeWidth = 4
          ..strokeCap = StrokeCap.round,
      );
    }
    
    // Layer 5: Energy pulse
    if (!reducedGlow) {
      final pulsePhase = (_time * 1.2) % 1.0;
      for (final seg in segments) {
        final beamDir = seg.end - seg.start;
        final beamLength = beamDir.length;
        if (beamLength < 20) continue;
        
        final pulsePos = seg.start + beamDir * pulsePhase;
        canvas.drawCircle(
          pulsePos.toOffset(),
          8,
          Paint()
            ..color = Colors.white.withOpacity(0.6)
            ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4),
        );
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
        for (final segment in _segments) {
          if (segment.color.opacity < 0.05) continue;
          canvas.drawLine(
            segment.start.toOffset(),
            segment.end.toOffset(),
            Paint()
              ..color = Colors.white
              ..strokeWidth = 6
              ..strokeCap = StrokeCap.round,
          );
        }
        return;
      }
      
      // === LAYER 0: Ultra-wide atmospheric haze (OPTIMIZED - reduced blur) ===
      if (!reducedGlow) {
        for (final segment in _segments) {
          if (segment.color.opacity < 0.05) continue;
          final safeColor = ColorBlindnessUtils.getSafeColor(segment.color);
          
          canvas.drawLine(
            segment.start.toOffset(),
            segment.end.toOffset(),
            Paint()
              ..color = safeColor.withOpacity(0.1)
              ..strokeWidth = 40 // Reduced from 60
              ..strokeCap = StrokeCap.round
              ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 15), // Reduced from 30
          );
        }
      }
      
      // === LAYER 1: Wide outer glow ===
      for (final segment in _segments) {
        if (segment.color.opacity < 0.05) continue;
        final safeColor = ColorBlindnessUtils.getSafeColor(segment.color);
        
        if (reducedGlow) {
          // Reduced: Single efficient glow layer
          canvas.drawLine(
            segment.start.toOffset(),
            segment.end.toOffset(),
            Paint()
              ..color = safeColor.withOpacity(0.4)
              ..strokeWidth = 14
              ..strokeCap = StrokeCap.round
              ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5),
          );
        } else {
          // Full quality: Wide atmospheric haze
          canvas.drawLine(
            segment.start.toOffset(),
            segment.end.toOffset(),
            Paint()
              ..color = safeColor.withOpacity(0.2)
              ..strokeWidth = 36
              ..strokeCap = StrokeCap.round
              ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 18),
          );
          
          // Medium intense glow
          canvas.drawLine(
            segment.start.toOffset(),
            segment.end.toOffset(),
            Paint()
              ..color = safeColor.withOpacity(0.45)
              ..strokeWidth = 18
              ..strokeCap = StrokeCap.round
              ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8),
          );
        }
      }
      
      // === LAYER 2: Solid core beam ===
      for (final segment in _segments) {
        if (segment.color.opacity < 0.05) continue;
        final safeColor = ColorBlindnessUtils.getSafeColor(segment.color);
        double boost = _pulseIntensity * 4.0;
        
        canvas.drawLine(
          segment.start.toOffset(),
          segment.end.toOffset(),
          Paint()
            ..color = safeColor.withOpacity((0.95 + _pulseIntensity * 0.05).clamp(0.0, 1.0))
            ..strokeWidth = 10 + boost
            ..strokeCap = StrokeCap.round
            ..isAntiAlias = true,
        );
      }
      
      // === LAYER 3: White hot inner core ===
      for (final segment in _segments) {
        if (segment.color.opacity < 0.05) continue;
        
        canvas.drawLine(
          segment.start.toOffset(),
          segment.end.toOffset(),
          Paint()
            ..color = Colors.white.withOpacity(0.95)
            ..strokeWidth = 4
            ..strokeCap = StrokeCap.round
            ..isAntiAlias = true,
        );
      }
      
      // === LAYER 4: Energy pulse traveling along beam (OPTIMIZED - single pulse) ===
      if (!reducedGlow) {
        final pulsePhase = (_time * 1.2) % 1.0; // Slower
        
        for (final segment in _segments) {
          if (segment.color.opacity < 0.1) continue;
          
          final beamDir = segment.end - segment.start;
          final beamLength = beamDir.length;
          if (beamLength < 20) continue; // Skip short segments
          
          // Single pulse only
          final pulsePos = segment.start + beamDir * pulsePhase;
          canvas.drawCircle(
            pulsePos.toOffset(),
            8, // Smaller
            Paint()
              ..color = Colors.white.withOpacity(0.6)
              ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4), // Reduced blur
          );
        }
      }
      
      // === LAYER 5: Render particles with enhanced glow ===
      for (final p in _particles) {
        // Outer particle glow
        canvas.drawCircle(
          p.position.toOffset(),
          p.size * 3,
          Paint()
            ..color = p.color.withOpacity(p.life * 0.2)
            ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6),
        );
        // Inner particle glow
        canvas.drawCircle(
          p.position.toOffset(),
          p.size * 1.5,
          Paint()
            ..color = p.color.withOpacity(p.life * 0.5)
            ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3),
        );
        // Particle core
        canvas.drawCircle(
          p.position.toOffset(),
          p.size,
          Paint()..color = Colors.white.withOpacity(p.life * 0.9),
        );
      }
  }
}

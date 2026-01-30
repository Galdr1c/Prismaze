/// Adapter to convert RayTracer segments to BeamSystem render segments.
///
/// Maps discrete grid-cell segments to pixel coordinates for rendering.
library;

import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import 'models/models.dart';
import 'ray_tracer.dart';

/// A pixel-space segment for BeamSystem rendering.
class RenderSegment {
  final Vector2 start;
  final Vector2 end;
  final Color color;
  final bool isSecondary;

  const RenderSegment({
    required this.start,
    required this.end,
    required this.color,
    this.isSecondary = false,
  });

  @override
  String toString() => 'RenderSegment($start -> $end, $color, sec=$isSecondary)';
}

/// Converts TraceResult from RayTracer to pixel-space render segments.
class RayTracerAdapter {
  /// Board offset in pixels (where the grid starts).
  final Vector2 boardOffset;

  /// Cell size in pixels.
  final double cellSize;

  RayTracerAdapter({
    Vector2? boardOffset,
    this.cellSize = 85.0,
  }) : boardOffset = boardOffset ?? Vector2(45.0, 62.5);

  /// Convert TraceResult segments to pixel-space RenderSegments.
  List<RenderSegment> convertToPixelSegments(TraceResult result) {
    final renderSegments = <RenderSegment>[];

    for (final segment in result.segments) {
      // Convert grid coordinates to pixel coordinates
      // Grid cell (x, y) -> pixel center at (x * cellSize + cellSize/2, y * cellSize + cellSize/2)
      final startPixel = _gridToPixel(segment.startX, segment.startY);
      var endPixel = _gridToPixel(segment.endX, segment.endY);
      
      // Fix Beam Overflow: Clip the line segment to the grid boundaries
      final endPos = GridPosition(segment.endX, segment.endY);
      if (!endPos.isValid) {
          endPixel = _clipToGrid(startPixel, endPixel);
      }

      renderSegments.add(RenderSegment(
        start: startPixel,
        end: endPixel,
        color: segment.color.renderColor,
        isSecondary: segment.isSecondary,
      ));
    }

    return renderSegments;
  }

  /// Clip a line segment (p1->p2) to the grid's bounding rectangle.
  /// Assumes p1 is inside and p2 is outside. Returns the intersection point.
  Vector2 _clipToGrid(Vector2 p1, Vector2 p2) {
      const double tolerance = 25.0; // Allow slight overlap to cover visual gaps
      final minX = boardOffset.x - tolerance;
      final minY = boardOffset.y - tolerance;
      final maxX = boardOffset.x + GridPosition.gridWidth * cellSize + tolerance;
      final maxY = boardOffset.y + GridPosition.gridHeight * cellSize + tolerance;

      double tMin = 0.0;
      double tMax = 1.0;
      final dx = p2.x - p1.x;
      final dy = p2.y - p1.y;

      final p = [-dx, dx, -dy, dy];
      final q = [p1.x - minX, maxX - p1.x, p1.y - minY, maxY - p1.y];

      for (int i = 0; i < 4; i++) {
          if (p[i] == 0) {
              if (q[i] < 0) return p1; // Parallel and outside? Shouldn't happen if p1 inside.
          } else {
              final t = q[i] / p[i];
              if (p[i] < 0) {
                  if (t > tMax) return p1; // Invalid
                  if (t > tMin) tMin = t;
              } else {
                  if (t < tMin) return p1; // Invalid
                  if (t < tMax) tMax = t;
              }
          }
      }

      // Since p1 is inside (t=0) and p2 is outside (t=1), we effectively want tMax (exit point)
      // Wait, Liang-Barsky usually finds entry/exit t for infinite line against box.
      // Here p1 is INSIDE. So t_entry < 0. We want t_exit (positive t).
      // t_exit corresponds to the 'positive p' cases (moving towards boundary) being minimal positive?
      // Actually simpler: Raycasting intersection.
      
      // Let's us simple slab method.
      // Find 't' for each boundary. Pick the smallest positive 't'.
      
      double t = 1.0;
      
      // Right edge
      if (dx > 0) { 
        final tHit = (maxX - p1.x) / dx;
        if (tHit < t) t = tHit;
      }
      // Left edge
      else if (dx < 0) {
        final tHit = (minX - p1.x) / dx;
        if (tHit < t) t = tHit;
      }
      
      // Bottom edge
      if (dy > 0) {
        final tHit = (maxY - p1.y) / dy;
        if (tHit < t) t = tHit;
      }
      // Top edge
      else if (dy < 0) {
        final tHit = (minY - p1.y) / dy;
        if (tHit < t) t = tHit;
      }
      
      return Vector2(p1.x + t * dx, p1.y + t * dy);
  }

  /// Convert grid cell coordinates to pixel coordinates (cell center).
  Vector2 _gridToPixel(int gridX, int gridY) {
    return Vector2(
      boardOffset.x + gridX * cellSize + cellSize / 2,
      boardOffset.y + gridY * cellSize + cellSize / 2,
    );
  }

  /// Convert pixel coordinates to grid cell coordinates.
  GridPosition pixelToGrid(Vector2 pixel) {
    final x = ((pixel.x - boardOffset.x) / cellSize).floor();
    final y = ((pixel.y - boardOffset.y) / cellSize).floor();
    return GridPosition(
      x.clamp(0, GridPosition.gridWidth - 1),
      y.clamp(0, GridPosition.gridHeight - 1),
    );
  }
}

/// Target satisfaction info for UI display.
class TargetStatus {
  final int targetIndex;
  final GridPosition position;
  final LightColor requiredColor;
  final Set<LightColor> arrivingColors;
  final bool satisfied;

  const TargetStatus({
    required this.targetIndex,
    required this.position,
    required this.requiredColor,
    required this.arrivingColors,
    required this.satisfied,
  });
}

/// Extract target status from TraceResult.
List<TargetStatus> getTargetStatuses(
  GeneratedLevel level,
  TraceResult result,
) {
  final statuses = <TargetStatus>[];

  for (int i = 0; i < level.targets.length; i++) {
    final target = level.targets[i];
    final arriving = result.targetArrivals[i] ?? {};

    statuses.add(TargetStatus(
      targetIndex: i,
      position: target.position,
      requiredColor: target.requiredColor,
      arrivingColors: arriving,
      satisfied: ColorMixer.satisfiesTarget(arriving, target.requiredColor),
    ));
  }

  return statuses;
}


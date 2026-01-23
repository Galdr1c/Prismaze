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

  const RenderSegment({
    required this.start,
    required this.end,
    required this.color,
  });

  @override
  String toString() => 'RenderSegment($start -> $end, $color)';
}

/// Converts TraceResult from RayTracer to pixel-space render segments.
class RayTracerAdapter {
  /// Board offset in pixels (where the grid starts).
  final Vector2 boardOffset;

  /// Cell size in pixels.
  final double cellSize;

  RayTracerAdapter({
    Vector2? boardOffset,
    this.cellSize = 55.0,
  }) : boardOffset = boardOffset ?? Vector2(35.0, 112.5);

  /// Convert TraceResult segments to pixel-space RenderSegments.
  List<RenderSegment> convertToPixelSegments(TraceResult result) {
    final renderSegments = <RenderSegment>[];

    for (final segment in result.segments) {
      // Convert grid coordinates to pixel coordinates
      // Grid cell (x, y) -> pixel center at (x * cellSize + cellSize/2, y * cellSize + cellSize/2)
      final startPixel = _gridToPixel(segment.startX, segment.startY);
      final endPixel = _gridToPixel(segment.endX, segment.endY);

      renderSegments.add(RenderSegment(
        start: startPixel,
        end: endPixel,
        color: segment.color.renderColor,
      ));
    }

    return renderSegments;
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


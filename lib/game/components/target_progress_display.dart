/// Target Progress Display Widget.
///
/// Shows the collected color components on a target as it accumulates
/// colors for mixed targets (e.g., Purple = R + B).
library;

import 'package:flutter/material.dart';
import '../procedural/models/models.dart';

/// Displays target progress for color accumulation.
class TargetProgressDisplay extends StatelessWidget {
  /// The target's required color.
  final LightColor requiredColor;

  /// Current collected mask (R=1, B=2, Y=4, W=8).
  final int collectedMask;

  /// Size of the display.
  final double size;

  /// Whether to show a "wrong color" pulse animation.
  final bool showWrongColorPulse;

  const TargetProgressDisplay({
    super.key,
    required this.requiredColor,
    required this.collectedMask,
    this.size = 48.0,
    this.showWrongColorPulse = false,
  });

  @override
  Widget build(BuildContext context) {
    final requiredMask = requiredColor.requiredMask;
    final isSatisfied = (collectedMask & requiredMask) == requiredMask;

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color: isSatisfied ? Colors.greenAccent : Colors.white54,
          width: isSatisfied ? 3.0 : 2.0,
        ),
        boxShadow: isSatisfied
            ? [
                BoxShadow(
                  color: Colors.greenAccent.withValues(alpha: 0.5),
                  blurRadius: 10,
                  spreadRadius: 2,
                ),
              ]
            : null,
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Background with required color
          Container(
            width: size - 8,
            height: size - 8,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: requiredColor.renderColor.withValues(alpha: 0.3),
            ),
          ),
          
          // Component slots for mixed colors
          if (requiredColor.isMixed) _buildMixedColorSlots(),
          
          // Single slot for base/white colors
          if (!requiredColor.isMixed) _buildSingleSlot(),
          
          // Wrong color pulse overlay
          if (showWrongColorPulse) _buildWrongColorPulse(),
        ],
      ),
    );
  }

  /// Build slots for mixed color targets (purple, orange, green).
  Widget _buildMixedColorSlots() {
    final components = _getRequiredComponents();
    final slotSize = size * 0.3;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: components.map((component) {
        final isCollected = _isComponentCollected(component);
        return Container(
          width: slotSize,
          height: slotSize,
          margin: const EdgeInsets.symmetric(horizontal: 2),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isCollected 
                ? _getComponentColor(component)
                : Colors.grey.shade800,
            border: Border.all(
              color: isCollected ? Colors.white : Colors.grey.shade600,
              width: 1.5,
            ),
          ),
          child: isCollected
              ? Icon(Icons.check, size: slotSize * 0.6, color: Colors.white)
              : null,
        );
      }).toList(),
    );
  }

  /// Build single slot for base or white targets.
  Widget _buildSingleSlot() {
    final isCollected = ColorMask.satisfies(collectedMask, requiredColor.requiredMask);
    final slotSize = size * 0.5;

    return Container(
      width: slotSize,
      height: slotSize,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: isCollected 
            ? requiredColor.renderColor 
            : Colors.grey.shade800,
        border: Border.all(
          color: isCollected ? Colors.white : Colors.grey.shade600,
          width: 2,
        ),
      ),
      child: isCollected
          ? const Icon(Icons.check, color: Colors.white)
          : null,
    );
  }

  /// Build wrong color pulse animation.
  Widget _buildWrongColorPulse() {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: const Duration(milliseconds: 300),
      builder: (context, value, child) {
        return Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.red.withValues(alpha: 0.3 * (1 - value)),
          ),
        );
      },
    );
  }

  /// Get the required base components for this color.
  List<ColorComponent> _getRequiredComponents() {
    switch (requiredColor) {
      case LightColor.purple:
        return [ColorComponent.red, ColorComponent.blue];
      case LightColor.orange:
        return [ColorComponent.red, ColorComponent.yellow];
      case LightColor.green:
        return [ColorComponent.blue, ColorComponent.yellow];
      default:
        return [];
    }
  }

  /// Check if a component is collected.
  bool _isComponentCollected(ColorComponent component) {
    switch (component) {
      case ColorComponent.red:
        return (collectedMask & ColorMask.red) != 0;
      case ColorComponent.blue:
        return (collectedMask & ColorMask.blue) != 0;
      case ColorComponent.yellow:
        return (collectedMask & ColorMask.yellow) != 0;
    }
  }

  /// Get the render color for a component.
  Color _getComponentColor(ColorComponent component) {
    switch (component) {
      case ColorComponent.red:
        return LightColor.red.renderColor;
      case ColorComponent.blue:
        return LightColor.blue.renderColor;
      case ColorComponent.yellow:
        return LightColor.yellow.renderColor;
    }
  }
}

/// Color component enum for UI display.
enum ColorComponent { red, blue, yellow }

/// Animated target that shows progress and pulses on wrong color.
class AnimatedTargetProgress extends StatefulWidget {
  final LightColor requiredColor;
  final int collectedMask;
  final int? lastArrivedMask;
  final double size;

  const AnimatedTargetProgress({
    super.key,
    required this.requiredColor,
    required this.collectedMask,
    this.lastArrivedMask,
    this.size = 48.0,
  });

  @override
  State<AnimatedTargetProgress> createState() => _AnimatedTargetProgressState();
}

class _AnimatedTargetProgressState extends State<AnimatedTargetProgress>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  bool _showWrongPulse = false;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
  }

  @override
  void didUpdateWidget(AnimatedTargetProgress oldWidget) {
    super.didUpdateWidget(oldWidget);
    
    // Check if wrong color arrived
    if (widget.lastArrivedMask != null && 
        oldWidget.lastArrivedMask != widget.lastArrivedMask) {
      final requiredMask = widget.requiredColor.requiredMask;
      final arrivedButNotNeeded = widget.lastArrivedMask! & ~requiredMask;
      
      if (arrivedButNotNeeded != 0) {
        // Wrong color arrived - show pulse
        setState(() => _showWrongPulse = true);
        _pulseController.forward(from: 0).then((_) {
          if (mounted) {
            setState(() => _showWrongPulse = false);
          }
        });
      }
    }
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return TargetProgressDisplay(
      requiredColor: widget.requiredColor,
      collectedMask: widget.collectedMask,
      size: widget.size,
      showWrongColorPulse: _showWrongPulse,
    );
  }
}

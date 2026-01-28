import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';
import 'bouncing_button.dart';

class CuteMenuButton extends StatefulWidget {
  final String label;
  final VoidCallback onTap;
  final Color baseColor;
  final double height;
  final IconData? icon;
  final double width;
  final double fontSize;
  final Color? textColor;

  const CuteMenuButton({
    super.key,
    required this.label,
    required this.onTap,
    required this.baseColor,
    this.icon,
    this.width = 240,
    this.fontSize = 20,
    this.height = 64,
    this.textColor,
  });

  @override
  State<CuteMenuButton> createState() => _CuteMenuButtonState();
}

class _CuteMenuButtonState extends State<CuteMenuButton> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _pressAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 50), // Snappy press
      reverseDuration: const Duration(milliseconds: 100),
    );
    _pressAnimation = Tween<double>(begin: 0.0, end: 6.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onTapDown(TapDownDetails details) {
    _controller.forward();
  }

  void _onTapUp(TapUpDetails details) {
    _controller.reverse();
    widget.onTap();
  }

  void _onTapCancel() {
    _controller.reverse();
  }

  @override
  Widget build(BuildContext context) {
    final darkShadow = widget.baseColor.withOpacity(0.8);
    // Darker shade for the background/border/3D sides
    final sideColor = widget.baseColor.withAlpha(255)
        .withRed((widget.baseColor.red * 0.6).toInt())
        .withGreen((widget.baseColor.green * 0.6).toInt())
        .withBlue((widget.baseColor.blue * 0.6).toInt());

    return GestureDetector(
      onTapDown: _onTapDown,
      onTapUp: _onTapUp,
      onTapCancel: _onTapCancel,
      child: AnimatedBuilder(
        animation: _pressAnimation,
        builder: (context, child) {
          final pressOffset = _pressAnimation.value;
          // When pressed (offset 6), we push the top face down by 6px
          // The total height of the container remains fixed so layout doesn't jump
          
          return Container(
            width: widget.width,
            height: widget.height,
            decoration: BoxDecoration(
              color: Colors.transparent, // Background handled by layers
            ),
            child: Stack(
              children: [
                // 1. Bottom/Side Layer (The 3D depth)
                // This stays fixed or shrinks slightly?
                // Actually, this is the "base" that is visible at the bottom.
                Positioned(
                  left: 0, right: 0, 
                  top: pressOffset, // Moves down slightly or stays?
                  // Better Strategy: The "Side" is a fixed background container.
                  // The "Face" moves down over it.
                  bottom: 0,
                  child: Container(
                    decoration: BoxDecoration(
                      color: sideColor,
                      borderRadius: BorderRadius.circular(widget.height / 2),
                      boxShadow: [
                        BoxShadow(
                           color: Colors.black.withOpacity(0.3),
                           offset: const Offset(0, 4),
                           blurRadius: 8,
                        ) 
                      ]
                    ),
                  ),
                ),
                
                // 2. The Face Layer (Moves DOWN on press)
                Positioned(
                  left: 0, right: 0,
                  // Initial (Unpressed): Top is 0, Bottom is 6 (showing 6px of side color)
                  // Pressed (Full): Top is 6, Bottom is 0 (covering the side color)
                  top: pressOffset,
                  bottom: 6.0 - pressOffset, 
                  child: Container(
                    decoration: BoxDecoration(
                      color: widget.baseColor,
                      borderRadius: BorderRadius.circular(widget.height / 2),
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          widget.baseColor.withOpacity(0.9),
                          widget.baseColor,
                        ],
                      ),
                    ),
                    child: Stack(
                      children: [
                         // Top Shine
                         Positioned(
                           left: 10, right: 10, top: 4,
                           height: (widget.height * 0.4),
                           child: Container(
                             decoration: BoxDecoration(
                               gradient: LinearGradient(
                                 begin: Alignment.topCenter,
                                 end: Alignment.bottomCenter,
                                 colors: [
                                   Colors.white.withOpacity(0.4),
                                   Colors.white.withOpacity(0.0),
                                 ],
                               ),
                               borderRadius: BorderRadius.vertical(top: Radius.circular(widget.height / 2 - 5)),
                             ),
                           ),
                         ),
                         // Content
                         Center(
                           child: Row(
                             mainAxisAlignment: MainAxisAlignment.center,
                             children: [
                               if (widget.icon != null) ...[
                                 Icon(widget.icon, color: widget.textColor ?? Colors.white, size: widget.fontSize + 4),
                                 const SizedBox(width: 10),
                               ],
                               Text(
                                 widget.label.toUpperCase(),
                                 style: GoogleFonts.dynaPuff(
                                   color: widget.textColor ?? Colors.white,
                                   fontSize: widget.fontSize,
                                   fontWeight: FontWeight.w900,
                                   letterSpacing: 1.5,
                                   shadows: [
                                     Shadow(
                                       color: Colors.black.withOpacity(0.5),
                                       offset: const Offset(0, 2),
                                       blurRadius: 2,
                                     ),
                                   ],
                                 ),
                               ),
                             ],
                           ),
                         ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
        }
      ),
    );
  }
}

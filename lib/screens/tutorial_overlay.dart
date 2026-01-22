import 'package:flutter/material.dart';

class TutorialOverlay extends StatefulWidget {
  final VoidCallback onDismiss;
  final String text;
  final bool showHand;
  
  const TutorialOverlay({
      super.key, 
      required this.onDismiss,
      this.text = "Aynayı sürükle ve döndür",
      this.showHand = true,
  });

  @override
  State<TutorialOverlay> createState() => _TutorialOverlayState();
}

class _TutorialOverlayState extends State<TutorialOverlay> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  
  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this, 
      duration: const Duration(milliseconds: 1500)
    )..repeat(reverse: true);
  }
  
  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Hardcoded positions for Level 1 Mirror tutorial for now.
    // Ideally, we project the Mirror's world position to screen coordinates.
    // But since viewport is fixed (720x1280), we can estimate or center it.
    
    return Stack(
      children: [
        // Darken background slightly to focus attention
        Container(color: Colors.black12),
        
        Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
               Padding(
                 padding: const EdgeInsets.only(bottom: 200), // Push text up
                 child: Text(
                  widget.text,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    shadows: [Shadow(color: Colors.black, blurRadius: 4)],
                  ),
                 ),
               ),
            ],
          ),
        ),

        // Hand Animation (Only if showing 'Drag' tutorial)
        if (widget.showHand)
        AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            return Align(
              alignment: Alignment(0.2 * _controller.value - 0.1, 0.2), // Move horizontally slightly
              child: Transform.translate(
                offset: Offset(50 * _controller.value, -50 * _controller.value), // Diagonal swipe hint
                child: const Icon(Icons.touch_app, color: Colors.cyanAccent, size: 64),
              ),
            );
          },
        ),
      ],
    );
  }
}


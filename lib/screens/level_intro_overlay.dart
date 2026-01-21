import 'package:flutter/material.dart';
import 'dart:async';
import '../game/localization_manager.dart';

class LevelIntroOverlay extends StatefulWidget {
  final int levelId;
  final bool autoStart;
  final VoidCallback onStart;

  const LevelIntroOverlay({
    super.key, 
    required this.levelId, 
    required this.autoStart, 
    required this.onStart
  });

  @override
  State<LevelIntroOverlay> createState() => _LevelIntroOverlayState();
}

class _LevelIntroOverlayState extends State<LevelIntroOverlay> with SingleTickerProviderStateMixin {
  double _opacity = 0.0;
  bool _showButton = false;
  late AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(vsync: this, duration: const Duration(seconds: 1))..repeat(reverse: true);
    
    // Sequence: Fade In -> Wait -> (Fade Out OR Show Button)
    
    // 1. Fade In (0.5s)
    Future.delayed(const Duration(milliseconds: 100), () {
        if(mounted) setState(() => _opacity = 1.0);
    });
    
    // 2. Wait
    Future.delayed(const Duration(seconds: 2), () {
        if (!mounted) return;
        
        if (widget.autoStart) {
            // Auto Start: Fade Out
            setState(() => _opacity = 0.0);
            Future.delayed(const Duration(milliseconds: 500), widget.onStart); 
        } else {
            // Manual Start: Show Button
            setState(() => _showButton = true);
        }
    });
  }
  
  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final loc = LocalizationManager();
    return AnimatedOpacity(
        duration: const Duration(milliseconds: 500),
        opacity: _opacity,
        child: Container(
            color: Colors.black.withOpacity(0.4),
            child: Center(
                child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                        // LEVEL TEXT
                        Text(
                            "${loc.getString('level_prefix')} ${widget.levelId}",
                            style: const TextStyle(
                                fontFamily: 'Orbitron',
                                fontSize: 48,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                                shadows: [
                                    BoxShadow(color: Colors.cyanAccent, blurRadius: 20, spreadRadius: 5)
                                ]
                            ),
                        ),
                        const SizedBox(height: 50),
                        
                        // START BUTTON (Manual Mode)
                        if (_showButton)
                            ScaleTransition(
                                scale: Tween(begin: 1.0, end: 1.1).animate(CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut)),
                                child: ElevatedButton(
                                    onPressed: () {
                                        setState(() => _opacity = 0.0);
                                        Future.delayed(const Duration(milliseconds: 500), widget.onStart);
                                    },
                                    style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.purpleAccent,
                                        padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 15),
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30))
                                    ),
                                    child: const Text("BAŞLA!", style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                                ),
                            ),
                    ],
                ),
            ),
        ),
    );
  }
}

import 'package:flutter/material.dart';

class OnboardingCompleteOverlay extends StatelessWidget {
  final VoidCallback onContinue;
  final int bonusTokens;

  const OnboardingCompleteOverlay({
    super.key, 
    required this.onContinue,
    this.bonusTokens = 10,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black87,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Trophy / Success Icon
            const Icon(Icons.emoji_events, color: Colors.amberAccent, size: 80),
            const SizedBox(height: 20),
            
            // Title
            const Text(
              "Tebrikler!",
              style: TextStyle(
                fontSize: 40,
                fontWeight: FontWeight.bold,
                color: Colors.white,
                shadows: [Shadow(color: Colors.purpleAccent, blurRadius: 20)],
              ),
            ),
            const SizedBox(height: 10),
            
            // Subtitle
            const Text(
              "Artık hazırsın!",
              style: TextStyle(
                fontSize: 24,
                color: Colors.white70,
              ),
            ),
            const SizedBox(height: 40),
            
            // Reward
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white10,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.purpleAccent.withOpacity(0.5)),
              ),
              child: Column(
                children: [
                  const Text("Başlangıç Bonusu", style: TextStyle(color: Colors.white54)),
                  const SizedBox(height: 10),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.lightbulb, color: Colors.yellowAccent, size: 30),
                      const SizedBox(width: 10),
                      Text(
                        "+$bonusTokens", 
                        style: const TextStyle(color: Colors.yellowAccent, fontSize: 32, fontWeight: FontWeight.bold)
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 60),
            
            // Continue Button
            ElevatedButton(
              onPressed: onContinue,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.purpleAccent,
                padding: const EdgeInsets.symmetric(horizontal: 50, vertical: 15),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
              ),
              child: const Text(
                "ANA MENÜ", 
                style: TextStyle(fontSize: 20, color: Colors.white, fontWeight: FontWeight.bold)
              ),
            ),
          ],
        ),
      ),
    );
  }
}


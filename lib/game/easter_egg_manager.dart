import 'dart:async';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Easter Egg and Secret Content Manager
class EasterEggManager {
  static final EasterEggManager _instance = EasterEggManager._internal();
  factory EasterEggManager() => _instance;
  EasterEggManager._internal();
  
  late SharedPreferences _prefs;
  
  // Tap counter for mini-game trigger
  int _rapidTapCount = 0;
  DateTime? _lastTapTime;
  
  // Secret code buffer
  final List<String> _codeBuffer = [];
  
  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
  }
  
  // ==========================================
  // SPECIAL LEVEL TRIGGERS
  // ==========================================
  
  /// Check for special level events
  EasterEggEvent? checkLevelEvent(int levelId) {
    switch (levelId) {
      case 42:
        return EasterEggEvent(
          type: EasterEggType.secretLevel,
          title: "Evrenin Cevabı",
          message: "Tebrikler! 42. seviyeyi buldun.\n\"Evrenin, hayatın ve her şeyin cevabı.\"",
          icon: Icons.auto_awesome,
          reward: "secret_skin_universe",
        );
        
      case 69:
        return EasterEggEvent(
          type: EasterEggType.funnyMessage,
          title: "Nice.",
          message: "😏 Nice.",
          icon: Icons.sentiment_very_satisfied,
        );
        
      case 100:
        return EasterEggEvent(
          type: EasterEggType.milestone,
          title: "🎉 EFSANE!",
          message: "100 seviyeyi tamamladın!\nSen gerçek bir ışık ustasısın!",
          icon: Icons.celebration,
          reward: "badge_century",
        );
        
      case 314:
        return EasterEggEvent(
          type: EasterEggType.funnyMessage,
          title: "π Seviyesi",
          message: "3.14159265... Matematiğin güzelliği!",
          icon: Icons.pie_chart,
        );
        
      case 404:
        return EasterEggEvent(
          type: EasterEggType.funnyMessage,
          title: "Level Not Found",
          message: "Hata 404: Bu level bulunamadı...\n...şaka şaka, işte buradasın! 🤣",
          icon: Icons.error_outline,
        );
        
      case 666:
        return EasterEggEvent(
          type: EasterEggType.funnyMessage,
          title: "👹 Karanlık Seviye",
          message: "Cesur bir oyuncusun...",
          icon: Icons.whatshot,
        );
        
      default:
        return null;
    }
  }
  
  // ==========================================
  // HIDDEN SKIN CONDITIONS
  // ==========================================
  
  /// Check if hidden skin should unlock
  Future<String?> checkHiddenSkinUnlock({
    required int totalThreeStars,
    required int levelsWithoutHint,
    required int totalLevelsCompleted,
  }) async {
    // Rainbow skin: All color levels with 3 stars (assume 50 color levels)
    if (totalThreeStars >= 50 && !_hasSkin('skin_rainbow_secret')) {
      await _unlockSkin('skin_rainbow_secret');
      return 'skin_rainbow_secret';
    }
    
    // Ghost skin: 100 levels without hints
    if (levelsWithoutHint >= 100 && !_hasSkin('skin_ghost')) {
      await _unlockSkin('skin_ghost');
      return 'skin_ghost';
    }
    
    // Legend skin: Complete 500 levels
    if (totalLevelsCompleted >= 500 && !_hasSkin('skin_legend')) {
      await _unlockSkin('skin_legend');
      return 'skin_legend';
    }
    
    return null;
  }
  
  bool _hasSkin(String skinId) {
    final skins = _prefs.getStringList('unlocked_easter_skins') ?? [];
    return skins.contains(skinId);
  }
  
  Future<void> _unlockSkin(String skinId) async {
    final skins = _prefs.getStringList('unlocked_easter_skins') ?? [];
    skins.add(skinId);
    await _prefs.setStringList('unlocked_easter_skins', skins);
  }
  
  // ==========================================
  // SECRET CODE SYSTEM
  // ==========================================
  
  /// Known secret codes (shared on social media)
  static const Map<String, String> secretCodes = {
    'KYNORA2024': 'skin_developer',
    'PRISMAZE': 'skin_prism_master',
    'RAINBOW': '100_tokens',
    'LIGHT': 'effect_sparkle',
    'EASTER': 'skin_bunny',
  };
  
  /// Try to redeem a secret code
  String? redeemCode(String code) {
    final upperCode = code.toUpperCase().trim();
    
    if (_prefs.getStringList('used_codes')?.contains(upperCode) == true) {
      return null; // Already used
    }
    
    final reward = secretCodes[upperCode];
    if (reward != null) {
      _markCodeUsed(upperCode);
      return reward;
    }
    
    return null;
  }
  
  Future<void> _markCodeUsed(String code) async {
    final used = _prefs.getStringList('used_codes') ?? [];
    used.add(code);
    await _prefs.setStringList('used_codes', used);
  }
  
  // ==========================================
  // RAPID TAP MINI-GAME
  // ==========================================
  
  /// Call on each rapid tap - returns true if mini-game should trigger
  bool onRapidTap() {
    final now = DateTime.now();
    
    if (_lastTapTime != null && 
        now.difference(_lastTapTime!).inMilliseconds < 300) {
      _rapidTapCount++;
    } else {
      _rapidTapCount = 1;
    }
    
    _lastTapTime = now;
    
    // 10 rapid taps triggers mini-game
    if (_rapidTapCount >= 10) {
      _rapidTapCount = 0;
      return true;
    }
    
    return false;
  }
  
  // ==========================================
  // ABOUT SCREEN EASTER EGGS
  // ==========================================
  
  /// Developer credits with light effect
  static const List<DeveloperCredit> developers = [
    DeveloperCredit(
      name: "Yusuf",
      role: "Lead Developer",
      color: Colors.cyanAccent,
    ),
    DeveloperCredit(
      name: "Kynora Studio",
      role: "Publisher",
      color: Colors.purpleAccent,
    ),
  ];
  
  /// Pop culture level references
  static const Map<int, String> popCultureLevels = {
    10: "Pac-Man şekli",
    25: "Space Invaders düşmanı",
    50: "Tetris L-bloğu",
    75: "Mario yıldızı",
    99: "Zelda Triforce",
  };
}

// ==========================================
// DATA CLASSES
// ==========================================

enum EasterEggType {
  secretLevel,
  funnyMessage,
  milestone,
  hiddenSkin,
  miniGame,
}

class EasterEggEvent {
  final EasterEggType type;
  final String title;
  final String message;
  final IconData icon;
  final String? reward;
  
  const EasterEggEvent({
    required this.type,
    required this.title,
    required this.message,
    required this.icon,
    this.reward,
  });
}

class DeveloperCredit {
  final String name;
  final String role;
  final Color color;
  
  const DeveloperCredit({
    required this.name,
    required this.role,
    required this.color,
  });
}

// ==========================================
// MINI-GAME (Flappy Light)
// ==========================================

/// Simple mini-game widget (Flappy Bird style)
class FlappyLightMiniGame extends StatefulWidget {
  final VoidCallback onClose;
  
  const FlappyLightMiniGame({super.key, required this.onClose});
  
  @override
  State<FlappyLightMiniGame> createState() => _FlappyLightMiniGameState();
}

class _FlappyLightMiniGameState extends State<FlappyLightMiniGame> {
  double birdY = 0;
  double velocity = 0;
  int score = 0;
  bool gameRunning = false;
  Timer? gameTimer;
  
  void startGame() {
    setState(() {
      birdY = 0;
      velocity = 0;
      score = 0;
      gameRunning = true;
    });
    
    gameTimer = Timer.periodic(const Duration(milliseconds: 50), (timer) {
      setState(() {
        velocity += 0.5; // Gravity
        birdY += velocity;
        
        // Bounds check
        if (birdY > 200 || birdY < -200) {
          gameOver();
        }
        
        score++;
      });
    });
  }
  
  void jump() {
    if (!gameRunning) {
      startGame();
    } else {
      setState(() {
        velocity = -10;
      });
    }
  }
  
  void gameOver() {
    gameTimer?.cancel();
    setState(() {
      gameRunning = false;
    });
  }
  
  @override
  void dispose() {
    gameTimer?.cancel();
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.black87,
      child: GestureDetector(
        onTap: jump,
        child: Stack(
          children: [
            // Background
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    const Color(0xFF1A0A2E),
                    const Color(0xFF0D0D1A),
                  ],
                ),
              ),
            ),
            
            // Bird (Light orb)
            Center(
              child: Transform.translate(
                offset: Offset(0, birdY),
                child: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.cyanAccent,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.cyanAccent.withOpacity(0.5),
                        blurRadius: 20,
                        spreadRadius: 5,
                      ),
                    ],
                  ),
                ),
              ),
            ),
            
            // Score
            Positioned(
              top: 50,
              left: 0,
              right: 0,
              child: Text(
                'Score: ${score ~/ 10}',
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.white, fontSize: 24),
              ),
            ),
            
            // Instructions
            if (!gameRunning)
              const Center(
                child: Text(
                  'Tap to Start!',
                  style: TextStyle(color: Colors.white54, fontSize: 18),
                ),
              ),
            
            // Close button
            Positioned(
              top: 40,
              right: 20,
              child: IconButton(
                icon: const Icon(Icons.close, color: Colors.white),
                onPressed: widget.onClose,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

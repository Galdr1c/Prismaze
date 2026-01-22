import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'main_menu_screen.dart';
import '../game/audio_manager.dart';
import '../game/localization_manager.dart';
import '../theme/app_theme.dart';
import '../game/settings_manager.dart';
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _opacityAnim;
  late Animation<double> _scaleAnim;
  bool _navigated = false;
  bool _showTapIndicator = false; // Control visibility

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    );

    _opacityAnim = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeIn),
    );
    
    _scaleAnim = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutBack),
    );

    _controller.forward();
    
    _initAudio();
  }

  Future<void> _initAudio() async {
    try {
      await AudioManager().init();
      await AudioManager().loadAssets(); 
      // initSfxPool removed - new AudioManager uses on-demand loading
      
      // Sync with Settings before playing
      final sm = SettingsManager();
      await sm.init(); // Ensure settings are loaded
      
      // Apply Language immediately
      LocalizationManager().setLanguage(sm.languageCode);
      print("SplashScreen: Applied Language: ${sm.languageCode}");
      
      print("SplashScreen: Syncing Audio. Master Vol from Settings: ${sm.masterVolume}");
      
      AudioManager().setMasterVolume(sm.masterVolume);
      AudioManager().setMusicVolume(sm.musicVolume);
      AudioManager().setSfxVolume(sm.sfxVolume);
      
      print("SplashScreen: Playing starting sound. Effective SFX: ${AudioManager().effectiveSfxVolume} (Master: ${sm.masterVolume})");
      // Play sound only if successfully initialized
      AudioManager().playSfxId(SfxId.start); 
    } catch (e) {
      print("SplashScreen: Audio Init Error: $e");
      // Continue even if audio fails
    }
      
    // Delay showing the "Tap to Continue" to let the logo/sound shine alone
    await Future.delayed(const Duration(seconds: 3));
    if (mounted) {
        setState(() {
            _showTapIndicator = true;
        });
    }
  }

  void _navigateToHome() {
    if (_navigated || !_showTapIndicator) return; // Only allow nav if indicator is visible
    _navigated = true;
    // ... rest of navigation logic
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        pageBuilder: (_, __, ___) => const MainMenuScreen(),
        transitionsBuilder: (_, a, __, c) => FadeTransition(opacity: a, child: c),
        transitionDuration: const Duration(milliseconds: 800),
      ),
    );
  }
  
  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: PrismazeTheme.backgroundDark,
      body: GestureDetector(
        onTap: _navigateToHome,
        child: Container(
            decoration: BoxDecoration(
              gradient: PrismazeTheme.backgroundGradient,
            ),
            width: double.infinity,
            height: double.infinity,
            child: SafeArea(
              child: Center(
                child: AnimatedBuilder(
                  animation: _controller,
                  builder: (context, child) {
                    return Opacity(
                      opacity: _opacityAnim.value,
                      child: Transform.scale(
                        scale: _scaleAnim.value,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            // Logo with Cartoon Font
                            Text(
                              "PRISMAZE",
                              textAlign: TextAlign.center,
                              style: GoogleFonts.dynaPuff(
                                fontSize: 52,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                                letterSpacing: 6,
                                shadows: (SettingsManager().reducedGlowEnabled || SettingsManager().highContrastEnabled) ? [] : [
                                  Shadow(color: PrismazeTheme.primaryPurple, blurRadius: 30),
                                  Shadow(color: PrismazeTheme.accentPink, blurRadius: 50),
                                  const Shadow(color: Colors.white, blurRadius: 10),
                                ],
                              ),
                            ),
                            const SizedBox(height: 12),
                            // Subtitle
                            Text(
                              LocalizationManager().getString('splash_subtitle'),
                              textAlign: TextAlign.center,
                              style: GoogleFonts.dynaPuff(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                                color: PrismazeTheme.textSecondary,
                              ),
                            ),
                            const SizedBox(height: 50),
                            // Tap to continue (visible only when ready)
                            AnimatedOpacity(
                              opacity: _showTapIndicator ? 1.0 : 0.0,
                              duration: const Duration(milliseconds: 500),
                              child: _TapIndicator(),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
        ),
      ),
    );
  }
}

class _TapIndicator extends StatefulWidget {
  @override
  State<_TapIndicator> createState() => _TapIndicatorState();
}

class _TapIndicatorState extends State<_TapIndicator> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  
  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1200))
      ..repeat(reverse: true);
  }
  
  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Opacity(
          opacity: 0.4 + (_controller.value * 0.6),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.touch_app, color: PrismazeTheme.primaryPurpleLight, size: 32),
              const SizedBox(height: 8),
              Text(
                LocalizationManager().getString('tap_to_start'),
                style: GoogleFonts.dynaPuff(
                  color: PrismazeTheme.textSecondary, 
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}


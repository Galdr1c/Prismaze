import 'package:flutter/material.dart';
import '../game/progress_manager.dart';
import '../generator/cache/level_cache_manager.dart';
import 'game_screen.dart';
import '../game/localization_manager.dart';
import '../game/audio_manager.dart';
import '../theme/app_theme.dart';
import '../widgets/bouncing_button.dart';
import 'components/fast_page_route.dart';
import 'package:google_fonts/google_fonts.dart';

class EndlessModeScreen extends StatefulWidget {
  const EndlessModeScreen({super.key});

  @override
  State<EndlessModeScreen> createState() => _EndlessModeScreenState();
}

class _EndlessModeScreenState extends State<EndlessModeScreen> {
  late ProgressManager _progress;
  bool _isLoading = true;
  int _highestLevel = 1;

  @override
  void initState() {
    super.initState();
    _loadProgress();
  }

  Future<void> _loadProgress() async {
    _progress = ProgressManager();
    await _progress.init();

    _highestLevel = await _progress.getHighestEndlessLevel();

    // Prefetch logic
    // We prefetch from highestLevel (which is the next playable one)
    final version = _progress.generatorVersion;
    if (_highestLevel > 0) {
      LevelCacheManager().prepareNextLevels(version, _highestLevel);
    } else {
      // Logic gap: prepareNextLevels usually takes an index and prefetches next ones.
      // If highest is 1 (new game), we want 1, 2, 3...
      // LevelCacheManager().prepareNextLevels(0) -> 1, 2, 3...
      LevelCacheManager().prepareNextLevels(version, 0); 
    }

    if (mounted) {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        backgroundColor: const Color(0xFF030308),
        body: Center(child: CircularProgressIndicator(color: Colors.purpleAccent)),
      );
    }

    return Scaffold(
        backgroundColor: const Color(0xFF030308),
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () => Navigator.pop(context),
          ),
          title: Text("Endless Mode", style: GoogleFonts.dynaPuff(color: Colors.white)),
          centerTitle: true,
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Info
              Text(
                "Highest Level: $_highestLevel",
                style: GoogleFonts.dynaPuff(color: Colors.white70, fontSize: 18),
              ),
              const SizedBox(height: 48),

              // Continue Button
              BouncingButton(
                onTap: () {
                    AudioManager().playSfx('ui_click');
                    Navigator.push(
                      context,
                      FastPageRoute(
                        page: GameScreen(levelId: _highestLevel),
                      ),
                    ).then((_) => _loadProgress()); // Refresh on return
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 16),
                  decoration: BoxDecoration(
                    color: Colors.purpleAccent,
                    borderRadius: BorderRadius.circular(30),
                    boxShadow: [BoxShadow(color: Colors.purple.withOpacity(0.5), blurRadius: 12)],
                  ),
                  child: Text(
                    'Continune (Level $_highestLevel)',
                    style: GoogleFonts.dynaPuff(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // New Game Button
              TextButton(
                onPressed: () async {
                   AudioManager().playSfx('ui_click');
                   // Confirm dialog? For now instant.
                   await _progress.resetEndlessProgress();
                   if (!mounted) return;
                   
                   Navigator.push(
                     context,
                     FastPageRoute(builder: (_) => const GameScreen(levelId: 1)), // Using builder due to tool limitation or standard route
                   ).then((_) => _loadProgress());
                },
                child: Text(
                  'Start New Game',
                  style: GoogleFonts.dynaPuff(color: Colors.redAccent, fontSize: 16),
                ),
              )
            ],
          ),
        ),
    );
  }
}

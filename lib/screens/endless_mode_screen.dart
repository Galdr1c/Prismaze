import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../game/procedural/level_generator.dart';
import '../game/procedural/models/models.dart' as proc;
import '../game/audio_manager.dart';
import '../game/economy_manager.dart';
import '../game/progress_manager.dart';
import '../game/endless_run_manager.dart';
import '../theme/app_theme.dart';
import '../game/localization_manager.dart';
import 'components/styled_back_button.dart';
import 'components/fast_page_route.dart';
import 'game_screen.dart';

/// Endless Mode Entry Screen
class EndlessModeScreen extends StatefulWidget {
  const EndlessModeScreen({super.key});

  @override
  State<EndlessModeScreen> createState() => _EndlessModeScreenState();
}

class _EndlessModeScreenState extends State<EndlessModeScreen> {
  final LevelGenerator _generator = LevelGenerator();
  late EconomyManager _economy;
  late ProgressManager _progress;
  bool _isLoading = true;
  
  int _highestEndlessLevel = 0;
  int _totalEndlessTokens = 0;
  
  @override
  void initState() {
    super.initState();
    _loadData();
  }
  
  Future<void> _loadData() async {
    _economy = EconomyManager();
    await _economy.init();
    
    _progress = ProgressManager();
    await _progress.init();
    
    // Load endless run manager
    await EndlessRunManager().init();
    _highestEndlessLevel = EndlessRunManager().highestIndex;
    _totalEndlessTokens = 0; // TODO: Track tokens earned
    
    setState(() => _isLoading = false);
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: PrismazeTheme.backgroundDark,
      body: _isLoading 
        ? Center(child: CircularProgressIndicator(color: PrismazeTheme.primaryPurple))
        : Stack(
          children: [
            // Background gradient
            Container(
              decoration: BoxDecoration(
                gradient: PrismazeTheme.backgroundGradient,
              ),
            ),
            
            SafeArea(
              child: Column(
                children: [
                  // Header
                  _buildHeader(),
                  
                  Expanded(
                    child: Row(
                        children: [
                            // LEFT: Infinity & Title
                            Expanded(
                                flex: 1,
                                child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                        _buildInfinitySymbol(),
                                        const SizedBox(height: 20),
                                        Text(
                                            LocalizationManager().getString('endless_mode'),
                                            style: GoogleFonts.dynaPuff(
                                                color: Colors.white,
                                                fontSize: 36,
                                                fontWeight: FontWeight.w900,
                                                letterSpacing: 4,
                                            ),
                                        ),
                                        const SizedBox(height: 10),
                                        Text(
                                            LocalizationManager().getString('endless_subtitle'),
                                            textAlign: TextAlign.center,
                                            style: GoogleFonts.dynaPuff(
                                              color: PrismazeTheme.textSecondary,
                                              fontSize: 14,
                                              fontWeight: FontWeight.w500,
                                            ),
                                        ),
                                    ],
                                ),
                            ),
                            
                            // RIGHT: Stats & Buttons
                            Expanded(
                                flex: 1,
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                      _buildStats(),
                                      const SizedBox(height: 40),
                                      _buildButtons(),
                                  ],
                                ),
                            ),
                        ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
    );
  }
  
  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          StyledBackButton(),
          const Spacer(),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: PrismazeTheme.backgroundCard,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: PrismazeTheme.warningYellow.withOpacity(0.4), width: 2),
            ),
            child: Row(
              children: [
                Icon(Icons.lightbulb, color: PrismazeTheme.warningYellow, size: 20),
                const SizedBox(width: 8),
                Text(
                  '${_economy.tokens}',
                  style: GoogleFonts.dynaPuff(color: Colors.white, fontWeight: FontWeight.w700),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildInfinitySymbol() {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: const Duration(seconds: 2),
      builder: (context, value, child) {
        return Transform.rotate(
          angle: value * 0.1,
          child: ShaderMask(
            shaderCallback: (bounds) => LinearGradient(
              colors: [
                PrismazeTheme.primaryPurple,
                PrismazeTheme.accentCyan,
                PrismazeTheme.primaryPurple,
              ],
              stops: [0, value, 1],
            ).createShader(bounds),
            child: Text(
              '∞',
              style: GoogleFonts.dynaPuff(
                fontSize: 120,
                fontWeight: FontWeight.w100,
                color: Colors.white,
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildStats() {
    final loc = LocalizationManager();
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 40),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: PrismazeTheme.backgroundCard,
        borderRadius: BorderRadius.circular(PrismazeTheme.borderRadiusMedium),
        border: Border.all(color: PrismazeTheme.primaryPurple.withOpacity(0.3), width: 2),
        boxShadow: [
          BoxShadow(color: PrismazeTheme.primaryPurple.withOpacity(0.2), blurRadius: 15),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildStatItem(loc.getString('stat_highest'), '$_highestEndlessLevel', Icons.emoji_events),
          Container(width: 1, height: 40, color: Colors.white24),
          _buildStatItem(loc.getString('lbl_earnings'), '$_totalEndlessTokens 🪙', Icons.monetization_on),
          Container(width: 1, height: 40, color: Colors.white24),
          _buildStatItem(loc.getString('stat_difficulty'), _getDifficultyText(), Icons.trending_up),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: Colors.cyanAccent, size: 24),
        const SizedBox(height: 8),
        Text(value, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
        Text(label, style: const TextStyle(color: Colors.white38, fontSize: 11)),
      ],
    );
  }
  
  String _getDifficultyText() {
    final loc = LocalizationManager();
    if (_highestEndlessLevel <= 5) return loc.getString('diff_easy');
    if (_highestEndlessLevel <= 15) return loc.getString('diff_medium');
    if (_highestEndlessLevel <= 30) return loc.getString('diff_hard');
    if (_highestEndlessLevel <= 50) return loc.getString('diff_expert');
    return loc.getString('diff_master');
  }
  
  Widget _buildButtons() {
    final loc = LocalizationManager();
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 40),
      child: Column(
        children: [
          // Continue Button (if progress exists)
          if (_highestEndlessLevel > 0)
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => _startEndless(continueProgress: true),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.purpleAccent,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                ),
                child: Text(loc.getString('btn_continue_level').replaceAll('{0}', '${_highestEndlessLevel + 1}')),
              ),
            ),
          
          if (_highestEndlessLevel > 0) const SizedBox(height: 12),
          
          // New Game Button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => _startEndless(continueProgress: false),
              style: ElevatedButton.styleFrom(
                backgroundColor: _highestEndlessLevel > 0 
                  ? Colors.white.withOpacity(0.1) 
                  : Colors.cyanAccent,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                side: BorderSide(
                  color: _highestEndlessLevel > 0 ? Colors.white24 : Colors.transparent,
                ),
              ),
              child: Text(_highestEndlessLevel > 0 ? loc.getString('btn_start_new') : loc.getString('btn_start')),
            ),
          ),
        ],
      ),
    );
  }
  
  void _startEndless({required bool continueProgress}) async {
    AudioManager().playSfxId(SfxId.mirrorMove);
    
    final manager = EndlessRunManager();
    
    if (continueProgress) {
      // Continue existing run
      if (!manager.continueRun()) {
        // No active run, start new
        await manager.startNewRun();
      }
    } else {
      // Start new run
      await manager.startNewRun();
    }
    
    final levelIndex = manager.currentIndex;
    final seed = manager.deriveSeed(levelIndex);
    final difficultyEpisode = manager.getDifficultyEpisode();
    
    // Generate endless level with deterministic seed
    final level = _generator.generate(difficultyEpisode, levelIndex, seed);
    
    if (level != null) {
      Navigator.push(
        context,
        FastPageRoute(
          page: GameScreen(
              levelId: levelIndex,
              generatedLevel: level,
              isEndlessMode: true,
          ),
        ),
      );
    } else {
      // Generation failed, show error
      debugPrint('Endless level generation failed for level $levelIndex (seed=$seed)');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Level generation failed. Please try again.')),
      );
    }
  }
}


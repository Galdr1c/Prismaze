/// Campaign Screen
/// 
/// New scalable campaign UI for 1000-2000+ levels per episode.
/// Uses episode journey flow instead of grid of buttons.
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../game/progress/campaign_progress.dart';
import '../game/procedural/campaign_loader.dart';
import '../game/audio_manager.dart';
import '../game/localization_manager.dart';
import '../theme/app_theme.dart';
import 'components/styled_back_button.dart';
import 'components/fast_page_route.dart';
import 'game_screen.dart';

/// Episode configuration for UI.
class EpisodeConfig {
  final int episode;
  final String title;
  final String subtitle;
  final Color themeColor;
  final IconData icon;

  const EpisodeConfig({
    required this.episode,
    required this.title,
    required this.subtitle,
    required this.themeColor,
    required this.icon,
  });
}

/// Episode configurations.
const List<EpisodeConfig> episodeConfigs = [
  EpisodeConfig(
    episode: 1,
    title: 'Tutorial',
    subtitle: 'Learn the basics',
    themeColor: Color(0xFF9B59B6),
    icon: Icons.school,
  ),
  EpisodeConfig(
    episode: 2,
    title: 'Easy',
    subtitle: 'Simple puzzles',
    themeColor: Color(0xFF3498DB),
    icon: Icons.star_outline,
  ),
  EpisodeConfig(
    episode: 3,
    title: 'Medium',
    subtitle: 'Color mixing',
    themeColor: Color(0xFF27AE60),
    icon: Icons.palette,
  ),
  EpisodeConfig(
    episode: 4,
    title: 'Hard',
    subtitle: 'Complex routing',
    themeColor: Color(0xFFE67E22),
    icon: Icons.auto_awesome,
  ),
  EpisodeConfig(
    episode: 5,
    title: 'Expert',
    subtitle: 'Master puzzles',
    themeColor: Color(0xFFE74C3C),
    icon: Icons.diamond,
  ),
];

class CampaignScreen extends StatefulWidget {
  const CampaignScreen({super.key});

  @override
  State<CampaignScreen> createState() => _CampaignScreenState();
}

class _CampaignScreenState extends State<CampaignScreen> {
  final CampaignProgress _progress = CampaignProgress();
  bool _loading = true;
  int _selectedEpisode = 1;
  Map<String, dynamic>? _manifest;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    // Load manifest first
    try {
      _manifest = await CampaignLevelLoader.loadManifest();
    } catch (e) {
      // Manifest not found, use empty
      _manifest = {'episodes': {}};
    }

    // Initialize progress with manifest
    await _progress.initWithManifest(_manifest ?? {'episodes': {}});

    // Find first available episode (select highest unlocked)
    final episodeIds = _progress.episodeIds;
    if (episodeIds.isNotEmpty) {
      for (final ep in episodeIds) {
        if (_progress.isEpisodeUnlocked(ep)) {
          _selectedEpisode = ep;
        }
      }
    }

    setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return Scaffold(
        backgroundColor: PrismazeTheme.backgroundDark,
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    final loc = LocalizationManager();

    return Scaffold(
      backgroundColor: PrismazeTheme.backgroundDark,
      body: Container(
        decoration: BoxDecoration(gradient: PrismazeTheme.backgroundGradient),
        child: SafeArea(
          child: Column(
            children: [
              _buildTopBar(loc),
              const SizedBox(height: 8),
              _buildEpisodeSelector(),
              const SizedBox(height: 16),
              Expanded(child: _buildSelectedEpisodePanel()),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTopBar(LocalizationManager loc) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          StyledBackButton(),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              'CAMPAIGN',
              style: GoogleFonts.dynaPuff(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          // Total stars
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: PrismazeTheme.backgroundCard,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                Icon(Icons.star, color: PrismazeTheme.starGold, size: 18),
                const SizedBox(width: 4),
                Text(
                  '${_progress.getTotalStars()}',
                  style: GoogleFonts.dynaPuff(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEpisodeSelector() {
    return SizedBox(
      height: 100,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        itemCount: episodeConfigs.length,
        itemBuilder: (context, index) {
          final config = episodeConfigs[index];
          return _buildEpisodeCard(config);
        },
      ),
    );
  }

  Widget _buildEpisodeCard(EpisodeConfig config) {
    final isSelected = config.episode == _selectedEpisode;
    final isUnlocked = _progress.isEpisodeUnlocked(config.episode);
    final ep = _progress.getEpisodeProgress(config.episode);

    return GestureDetector(
      onTap: () {
        AudioManager().playSfx('soft_button_click.mp3');
        if (isUnlocked) {
          setState(() => _selectedEpisode = config.episode);
        } else {
          _showLockedDialog(config);
        }
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: 130,
        margin: const EdgeInsets.symmetric(horizontal: 4),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          gradient: isUnlocked
              ? LinearGradient(
                  colors: [
                    config.themeColor.withOpacity(isSelected ? 0.6 : 0.3),
                    config.themeColor.withOpacity(isSelected ? 0.3 : 0.1),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                )
              : null,
          color: isUnlocked ? null : Colors.white.withOpacity(0.05),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected 
                ? config.themeColor 
                : (isUnlocked ? config.themeColor.withOpacity(0.3) : Colors.white12),
            width: isSelected ? 2 : 1,
          ),
          boxShadow: isSelected
              ? [BoxShadow(color: config.themeColor.withOpacity(0.3), blurRadius: 10)]
              : null,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  isUnlocked ? config.icon : Icons.lock,
                  color: isUnlocked ? config.themeColor : Colors.white30,
                  size: 20,
                ),
                const Spacer(),
                if (isUnlocked)
                  Text(
                    'E${config.episode}',
                    style: GoogleFonts.dynaPuff(
                      color: config.themeColor.withOpacity(0.7),
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              config.title,
              style: GoogleFonts.dynaPuff(
                color: isUnlocked ? Colors.white : Colors.white30,
                fontSize: 14,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 2),
            if (isUnlocked)
              Text(
                '${ep.completedLevels}/${ep.totalLevels}',
                style: GoogleFonts.dynaPuff(
                  color: Colors.white60,
                  fontSize: 10,
                ),
              )
            else
              Text(
                'Locked',
                style: GoogleFonts.dynaPuff(
                  color: Colors.white30,
                  fontSize: 10,
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildSelectedEpisodePanel() {
    final config = episodeConfigs[_selectedEpisode - 1];
    final ep = _progress.getEpisodeProgress(_selectedEpisode);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Episode header card
          _buildEpisodeHeader(config, ep),
          const SizedBox(height: 20),
          // Continue button
          _buildContinueButton(config, ep),
          const SizedBox(height: 16),
          // Progress bar
          _buildProgressBar(config, ep),
          const SizedBox(height: 20),
          // Action buttons
          _buildActionButtons(config, ep),
        ],
      ),
    );
  }

  Widget _buildEpisodeHeader(EpisodeConfig config, EpisodeProgress ep) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            config.themeColor.withOpacity(0.3),
            config.themeColor.withOpacity(0.1),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: config.themeColor.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: config.themeColor.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(config.icon, color: config.themeColor, size: 32),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'EPISODE ${config.episode}',
                  style: GoogleFonts.dynaPuff(
                    color: config.themeColor,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  config.title.toUpperCase(),
                  style: GoogleFonts.dynaPuff(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  config.subtitle,
                  style: GoogleFonts.dynaPuff(
                    color: Colors.white60,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Row(
                children: [
                  Icon(Icons.star, color: PrismazeTheme.starGold, size: 16),
                  const SizedBox(width: 4),
                  Text(
                    '${ep.totalStars}',
                    style: GoogleFonts.dynaPuff(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                '${(ep.progressPercent * 100).toStringAsFixed(0)}%',
                style: GoogleFonts.dynaPuff(
                  color: config.themeColor,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildContinueButton(EpisodeConfig config, EpisodeProgress ep) {
    final currentLevel = ep.currentLevelIndex + 1;
    final isComplete = ep.currentLevelIndex >= ep.totalLevels;

    return GestureDetector(
      onTap: isComplete ? null : () => _playLevel(ep.currentLevelIndex),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: isComplete 
              ? null 
              : LinearGradient(colors: [config.themeColor, config.themeColor.withOpacity(0.7)]),
          color: isComplete ? Colors.white.withOpacity(0.1) : null,
          borderRadius: BorderRadius.circular(16),
          boxShadow: isComplete
              ? null
              : [BoxShadow(color: config.themeColor.withOpacity(0.3), blurRadius: 12, offset: const Offset(0, 4))],
        ),
        child: Row(
          children: [
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                isComplete ? Icons.check : Icons.play_arrow,
                color: Colors.white,
                size: 28,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    isComplete ? 'COMPLETED' : 'CONTINUE',
                    style: GoogleFonts.dynaPuff(
                      color: Colors.white.withOpacity(0.8),
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    isComplete ? 'All levels done!' : 'Level $currentLevel',
                    style: GoogleFonts.dynaPuff(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_ios,
              color: Colors.white.withOpacity(0.6),
              size: 20,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProgressBar(EpisodeConfig config, EpisodeProgress ep) {
    final milestones = <int>[];
    for (int i = 50; i < ep.totalLevels; i += 50) {
      milestones.add(i);
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: PrismazeTheme.backgroundCard,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Progress',
                style: GoogleFonts.dynaPuff(
                  color: Colors.white60,
                  fontSize: 12,
                ),
              ),
              Text(
                '${ep.completedLevels} / ${ep.totalLevels} levels',
                style: GoogleFonts.dynaPuff(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Stack(
            children: [
              // Background
              Container(
                height: 10,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(5),
                ),
              ),
              // Progress
              FractionallySizedBox(
                widthFactor: ep.progressPercent.clamp(0, 1),
                child: Container(
                  height: 10,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [config.themeColor, config.themeColor.withOpacity(0.7)],
                    ),
                    borderRadius: BorderRadius.circular(5),
                  ),
                ),
              ),
              // Current position marker
              if (ep.totalLevels > 0)
                Positioned(
                  left: (ep.currentLevelIndex / ep.totalLevels).clamp(0, 1) * 
                      (MediaQuery.of(context).size.width - 64 - 32) - 6,
                  top: -3,
                  child: Container(
                    width: 16,
                    height: 16,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      boxShadow: [BoxShadow(color: config.themeColor, blurRadius: 6)],
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
          // Milestone markers
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('1', style: GoogleFonts.dynaPuff(color: Colors.white30, fontSize: 10)),
              ...milestones.take(3).map((m) => Text('$m', style: GoogleFonts.dynaPuff(color: Colors.white30, fontSize: 10))),
              Text('${ep.totalLevels}', style: GoogleFonts.dynaPuff(color: Colors.white30, fontSize: 10)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons(EpisodeConfig config, EpisodeProgress ep) {
    return Row(
      children: [
        Expanded(
          child: GestureDetector(
            onTap: () => _showJumpDialog(config, ep),
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 14),
              decoration: BoxDecoration(
                color: PrismazeTheme.backgroundCard,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: config.themeColor.withOpacity(0.3)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.skip_next, color: config.themeColor, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    'Jump to Level',
                    style: GoogleFonts.dynaPuff(
                      color: Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: GestureDetector(
            onTap: () => _showStatsDialog(config, ep),
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 14),
              decoration: BoxDecoration(
                color: PrismazeTheme.backgroundCard,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.bar_chart, color: Colors.white60, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    'Statistics',
                    style: GoogleFonts.dynaPuff(
                      color: Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  void _showJumpDialog(EpisodeConfig config, EpisodeProgress ep) {
    final maxLevel = ep.unlockedMaxIndex + 1;
    int selectedLevel = ep.currentLevelIndex + 1;

    showDialog(
      context: context,
      barrierColor: Colors.black54,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => Center(
          child: Material(
            color: Colors.transparent,
            child: Container(
              margin: const EdgeInsets.all(32),
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: PrismazeTheme.backgroundCard,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: config.themeColor.withOpacity(0.5)),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Jump to Level',
                    style: GoogleFonts.dynaPuff(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 20),
                  // Level display
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    decoration: BoxDecoration(
                      color: config.themeColor.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      'Level $selectedLevel',
                      style: GoogleFonts.dynaPuff(
                        color: config.themeColor,
                        fontSize: 28,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  // Slider
                  SliderTheme(
                    data: SliderTheme.of(context).copyWith(
                      activeTrackColor: config.themeColor,
                      inactiveTrackColor: config.themeColor.withOpacity(0.2),
                      thumbColor: config.themeColor,
                      overlayColor: config.themeColor.withOpacity(0.2),
                    ),
                    child: Slider(
                      value: selectedLevel.toDouble(),
                      min: 1,
                      max: maxLevel.toDouble(),
                      divisions: maxLevel > 1 ? maxLevel - 1 : 1,
                      onChanged: (value) {
                        setDialogState(() => selectedLevel = value.round());
                      },
                    ),
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('1', style: GoogleFonts.dynaPuff(color: Colors.white30, fontSize: 12)),
                      Text('$maxLevel unlocked', style: GoogleFonts.dynaPuff(color: Colors.white30, fontSize: 12)),
                    ],
                  ),
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      Expanded(
                        child: GestureDetector(
                          onTap: () => Navigator.pop(ctx),
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Center(
                              child: Text(
                                'Cancel',
                                style: GoogleFonts.dynaPuff(
                                  color: Colors.white60,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: GestureDetector(
                          onTap: () {
                            Navigator.pop(ctx);
                            _playLevel(selectedLevel - 1);
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [config.themeColor, config.themeColor.withOpacity(0.7)],
                              ),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Center(
                              child: Text(
                                'Play',
                                style: GoogleFonts.dynaPuff(
                                  color: Colors.white,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _showStatsDialog(EpisodeConfig config, EpisodeProgress ep) {
    showDialog(
      context: context,
      barrierColor: Colors.black54,
      builder: (ctx) => Center(
        child: Material(
          color: Colors.transparent,
          child: Container(
            margin: const EdgeInsets.all(32),
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: PrismazeTheme.backgroundCard,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Episode ${config.episode} Stats',
                  style: GoogleFonts.dynaPuff(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 20),
                _buildStatRow('Completed', '${ep.completedLevels}', config.themeColor),
                _buildStatRow('Total Levels', '${ep.totalLevels}', Colors.white60),
                _buildStatRow('Stars Earned', '${ep.totalStars}', PrismazeTheme.starGold),
                _buildStatRow('Max Stars', '${ep.totalLevels * 3}', Colors.white30),
                _buildStatRow('Progress', '${(ep.progressPercent * 100).toStringAsFixed(1)}%', config.themeColor),
                const SizedBox(height: 20),
                GestureDetector(
                  onTap: () => Navigator.pop(ctx),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                    decoration: BoxDecoration(
                      gradient: PrismazeTheme.buttonGradient,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      'Close',
                      style: GoogleFonts.dynaPuff(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatRow(String label, String value, Color valueColor) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: GoogleFonts.dynaPuff(color: Colors.white60, fontSize: 14)),
          Text(value, style: GoogleFonts.dynaPuff(color: valueColor, fontSize: 14, fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }

  void _showLockedDialog(EpisodeConfig config) {
    AudioManager().playSfx('error_sound.mp3');
    showDialog(
      context: context,
      barrierColor: Colors.black54,
      builder: (ctx) => Center(
        child: Material(
          color: Colors.transparent,
          child: Container(
            margin: const EdgeInsets.all(40),
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: PrismazeTheme.backgroundCard,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: PrismazeTheme.warningYellow.withOpacity(0.5)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: PrismazeTheme.warningYellow.withOpacity(0.2),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.lock_outline, color: PrismazeTheme.warningYellow, size: 40),
                ),
                const SizedBox(height: 16),
                Text(
                  'Episode Locked',
                  style: GoogleFonts.dynaPuff(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 8),
                Text(
                  'Complete 80% of Episode ${config.episode - 1} to unlock',
                  style: GoogleFonts.dynaPuff(color: Colors.white70, fontSize: 13),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 20),
                GestureDetector(
                  onTap: () => Navigator.pop(ctx),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 10),
                    decoration: BoxDecoration(
                      gradient: PrismazeTheme.buttonGradient,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text('OK', style: GoogleFonts.dynaPuff(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w700)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _playLevel(int levelIndex) async {
    AudioManager().playSfx('soft_button_click.mp3');
    
    // Set current level
    await _progress.setCurrentLevel(_selectedEpisode, levelIndex);
    
    // Navigate to game screen
    // TODO: Update GameScreen to accept episode + levelIndex
    if (mounted) {
      Navigator.push(
        context,
        FastPageRoute(
          page: GameScreen(
            levelId: levelIndex + 1, // Temporary: use level number as ID
            episode: _selectedEpisode,
            levelIndex: levelIndex,
          ),
        ),
      );
    }
  }
}

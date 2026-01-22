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
    title: 'ep_1_title',
    subtitle: 'ep_1_desc',
    themeColor: Color(0xFF9B59B6),
    icon: Icons.school,
  ),
  EpisodeConfig(
    episode: 2,
    title: 'ep_2_title',
    subtitle: 'ep_2_desc',
    themeColor: Color(0xFF3498DB),
    icon: Icons.star_outline,
  ),
  EpisodeConfig(
    episode: 3,
    title: 'ep_3_title',
    subtitle: 'ep_3_desc',
    themeColor: Color(0xFF27AE60),
    icon: Icons.palette,
  ),
  EpisodeConfig(
    episode: 4,
    title: 'ep_4_title',
    subtitle: 'ep_4_desc',
    themeColor: Color(0xFFE67E22),
    icon: Icons.auto_awesome,
  ),
  EpisodeConfig(
    episode: 5,
    title: 'ep_5_title',
    subtitle: 'ep_5_desc',
    themeColor: Color(0xFFE74C3C),
    icon: Icons.diamond,
  ),
];

class EpisodePatternPainter extends CustomPainter {
  final int episodeIndex;
  final Color color;

  EpisodePatternPainter({required this.episodeIndex, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color.withOpacity(0.1)
      ..style = PaintingStyle.fill;

    switch (episodeIndex) {
      case 1: // Circles (Tutorial)
        for (double i = 5; i < size.width; i += 15) {
          for (double j = 5; j < size.height; j += 15) {
            canvas.drawCircle(Offset(i, j), 3, paint);
          }
        }
        break;
      case 2: // Stripes (Easy)
        paint.strokeWidth = 2;
        paint.style = PaintingStyle.stroke;
        for (double i = -size.height; i < size.width; i += 10) {
          canvas.drawLine(Offset(i, size.height), Offset(i + size.height, 0), paint);
        }
        break;
      case 3: // Grid (Medium)
        paint.strokeWidth = 1;
        paint.style = PaintingStyle.stroke;
        for (double i = 0; i <= size.width; i += 15) {
          canvas.drawLine(Offset(i, 0), Offset(i, size.height), paint);
        }
        for (double i = 0; i <= size.height; i += 15) {
          canvas.drawLine(Offset(0, i), Offset(size.width, i), paint);
        }
        break;
      case 4: // Triangles/Diamonds (Hard)
        final path = Path();
        for (double i = 0; i < size.width; i += 20) {
          for (double j = 0; j < size.height; j += 20) {
            path.moveTo(i + 10, j);     // Top
            path.lineTo(i + 20, j + 10); // Right
            path.lineTo(i + 10, j + 20); // Bottom
            path.lineTo(i, j + 10);      // Left
            path.close();
          }
        }
        canvas.drawPath(path, paint);
        break;
      case 5: // Curves (Expert)
        paint.style = PaintingStyle.stroke;
        paint.strokeWidth = 1.5;
        for (double j = 0; j < size.height + 20; j += 15) {
           final path = Path();
           path.moveTo(0, j);
            for (double i = 0; i <= size.width; i += 20) {
             path.quadraticBezierTo(i + 10, j - 10, i + 20, j);
           }
           canvas.drawPath(path, paint);
        }
        break;
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}


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
      height: 80, // Reduced from 100
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
        AudioManager().playSfxId(SfxId.uiClick);
        if (isUnlocked) {
          setState(() => _selectedEpisode = config.episode);
        } else {
          _showLockedDialog(config);
        }
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: 110, 
        margin: const EdgeInsets.symmetric(horizontal: 4),
        // Padding moved to inner content
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
        child: Stack(
          children: [
            // Pattern Background
             if (isUnlocked)
               Positioned.fill(
                 child: ClipRRect(
                   borderRadius: BorderRadius.circular(16),
                   child: CustomPaint(
                     painter: EpisodePatternPainter(
                       episodeIndex: config.episode, 
                       color: config.themeColor
                     ),
                   ),
                 ),
               ),
               
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center, // Center vertically
                children: [
                  Row(
                    children: [
                      // No Icon for unlocked, Lock icon for locked
                      if (!isUnlocked)
                        Icon(
                          Icons.lock,
                          color: Colors.white30,
                          size: 18, 
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
                  const SizedBox(height: 4),
            Flexible( // Use Flexible to allow text to take available space
              child: Text(
                LocalizationManager().getString(config.title),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.dynaPuff(
                  color: isUnlocked ? Colors.white : Colors.white30,
                  fontSize: 11, // Reduced slightly
                  fontWeight: FontWeight.w800,
                  height: 1.1,
                ),
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
          const SizedBox(height: 12),
          
          // Two Column Bottom Layout
          IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Left: Continue Button
                Expanded(
                  flex: 5,
                  child: _buildContinueButton(config, ep),
                ),
                const SizedBox(width: 12),
                // Right: Progress & Actions
                Expanded(
                  flex: 4,
                  child: Column(
                    children: [
                        _buildProgressBar(config, ep),
                        const SizedBox(height: 8),
                         _buildActionButtons(config, ep),
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

  Widget _buildEpisodeHeader(EpisodeConfig config, EpisodeProgress ep) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            config.themeColor.withOpacity(0.3),
            config.themeColor.withOpacity(0.1),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: config.themeColor.withOpacity(0.3)),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Stack(
          children: [
            // Full Background Pattern
            Positioned.fill(
              child: CustomPaint(
                painter: EpisodePatternPainter(
                  episodeIndex: config.episode, 
                  color: config.themeColor
                ),
              ),
            ),
            
            // Content
            Padding(
              padding: const EdgeInsets.all(16), // Increased padding layout
              child: Row(
                children: [
                  // Icon container removed completely
                  
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'EPISODE ${config.episode}',
                          style: GoogleFonts.dynaPuff(
                            color: config.themeColor,
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text(
                          LocalizationManager().getString(config.title).toUpperCase(),
                          style: GoogleFonts.dynaPuff(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          LocalizationManager().getString(config.subtitle),
                          style: GoogleFonts.dynaPuff(
                            color: Colors.white60,
                            fontSize: 11,
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
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContinueButton(EpisodeConfig config, EpisodeProgress ep) {
    final currentLevel = ep.currentLevelIndex + 1;
    final isComplete = ep.currentLevelIndex >= ep.totalLevels;

    return GestureDetector(
      onTap: isComplete ? null : () => _playLevel(ep.currentLevelIndex),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20), // More vertical padding for height
        decoration: BoxDecoration(
          gradient: isComplete 
              ? null 
              : LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [config.themeColor, config.themeColor.withOpacity(0.7)]
                ),
          color: isComplete ? Colors.white.withOpacity(0.1) : null,
          borderRadius: BorderRadius.circular(16),
          boxShadow: isComplete
              ? null
              : [BoxShadow(color: config.themeColor.withOpacity(0.3), blurRadius: 12, offset: const Offset(0, 4))],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                isComplete ? Icons.check : Icons.play_arrow,
                color: Colors.white,
                size: 24,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              isComplete ? 'COMPLETED' : LocalizationManager().getString('continue').toUpperCase(),
              style: GoogleFonts.dynaPuff(
                color: Colors.white.withOpacity(0.8),
                fontSize: 10,
                fontWeight: FontWeight.w600,
              ),
            ),
            Text(
              isComplete ? 'Done!' : 'Level $currentLevel',
              style: GoogleFonts.dynaPuff(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w800,
              ),
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
      padding: const EdgeInsets.all(12),
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
                  fontSize: 10,
                ),
              ),
              Text(
                '${(ep.progressPercent * 100).toInt()}%',
                style: GoogleFonts.dynaPuff(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
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
              padding: const EdgeInsets.symmetric(vertical: 10),
              decoration: BoxDecoration(
                color: PrismazeTheme.backgroundCard,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: config.themeColor.withOpacity(0.3)),
              ),
              child: Center(
                  child: Icon(Icons.skip_next, color: config.themeColor, size: 20),
              ),
            ),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: GestureDetector(
            onTap: () => _showStatsDialog(config, ep),
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 10),
              decoration: BoxDecoration(
                color: PrismazeTheme.backgroundCard,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Center(
                  child: Icon(Icons.bar_chart, color: Colors.white60, size: 20),
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
    AudioManager().playSfxId(SfxId.error);
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
    AudioManager().playSfxId(SfxId.uiClick);
    
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


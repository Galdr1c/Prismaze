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
import '../widgets/bouncing_button.dart';

/// Episode configuration for UI.
class EpisodeConfig {
  final int episode;
  final String titleKey;
  final String descKey;
  final Color themeColor;

  const EpisodeConfig({
    required this.episode,
    required this.titleKey,
    required this.descKey,
    required this.themeColor,
  });
}

/// Episode configurations.
const List<EpisodeConfig> episodeConfigs = [
  EpisodeConfig(
    episode: 1,
    titleKey: 'ep_1_title',
    descKey: 'ep_1_desc',
    themeColor: Color(0xFF9B59B6),
  ),
  EpisodeConfig(
    episode: 2,
    titleKey: 'ep_2_title',
    descKey: 'ep_2_desc',
    themeColor: Color(0xFF3498DB),
  ),
  EpisodeConfig(
    episode: 3,
    titleKey: 'ep_3_title',
    descKey: 'ep_3_desc',
    themeColor: Color(0xFF27AE60),
  ),
  EpisodeConfig(
    episode: 4,
    titleKey: 'ep_4_title',
    descKey: 'ep_4_desc',
    themeColor: Color(0xFFE67E22),
  ),
  EpisodeConfig(
    episode: 5,
    titleKey: 'ep_5_title',
    descKey: 'ep_5_desc',
    themeColor: Color(0xFFE74C3C),
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
      height: 95, // Reduced from 120
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
    final loc = LocalizationManager();

    return BouncingButton(
      // Subtle bounce for cards
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
        width: 110, // Reduced from 130
        margin: const EdgeInsets.symmetric(horizontal: 4),
        padding: const EdgeInsets.all(8), // Reduced from 12
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
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected 
                ? config.themeColor 
                : (isUnlocked ? config.themeColor.withOpacity(0.3) : Colors.white12),
            width: isSelected ? 1.5 : 1, // Slightly thinner
          ),
          boxShadow: isSelected
              ? [BoxShadow(color: config.themeColor.withOpacity(0.3), blurRadius: 8)]
              : null,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                if (!isUnlocked)
                  Icon(Icons.lock, color: Colors.white30, size: 16)
                else
                   SizedBox(height: 16),
                   
                if (isUnlocked)
                  Text(
                    'E${config.episode}',
                    style: GoogleFonts.dynaPuff(
                      color: config.themeColor.withOpacity(0.7),
                      fontSize: 8, // Smaller
                      fontWeight: FontWeight.w600,
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              loc.getString(config.titleKey),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.dynaPuff(
                color: isUnlocked ? Colors.white : Colors.white30,
                fontSize: 10, // Smaller
                fontWeight: FontWeight.w800,
                height: 1.1,
              ),
            ),
            const Spacer(),
            if (isUnlocked)
              Text(
                '${ep.completedLevels}/${ep.totalLevels}',
                style: GoogleFonts.dynaPuff(
                  color: Colors.white60,
                  fontSize: 9,
                ),
              )
            else
              Text(
                loc.getString('level_locked'),
                style: GoogleFonts.dynaPuff(
                  color: Colors.white30,
                  fontSize: 9,
                ),
              ),
          ],
        ),
      ),
    );
  }

  int _expandedGroupIndex = -1;

  Widget _buildSelectedEpisodePanel() {
    final config = episodeConfigs[_selectedEpisode - 1];
    final ep = _progress.getEpisodeProgress(_selectedEpisode);
    
    // Auto-open group containing current level if not manually changed
    if (_expandedGroupIndex == -1) {
      _expandedGroupIndex = (ep.currentLevelIndex ~/ 25);
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final isNarrow = constraints.maxWidth < 700;
        
        if (isNarrow) {
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                _buildEpisodeHeader(config, ep),
                const SizedBox(height: 12),
                _buildContinueButton(config, ep),
                const SizedBox(height: 12),
                _buildActionButtons(config, ep),
                const SizedBox(height: 20),
                _buildLevelAccordion(config, ep),
              ],
            ),
          );
        }

        return Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // LEFT COLUMN: Header, Continue, Jump
              Expanded(
                flex: 4,
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      _buildEpisodeHeader(config, ep),
                      const SizedBox(height: 12),
                      _buildContinueButton(config, ep),
                      const SizedBox(height: 12),
                      _buildActionButtons(config, ep),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 20),
              // RIGHT COLUMN: Level Accordion
              Expanded(
                flex: 6,
                child: Container(
                  clipBehavior: Clip.antiAlias,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.03),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: SingleChildScrollView(
                    child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: _buildLevelAccordion(config, ep),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      }
    );
  }

  Widget _buildEpisodeHeader(EpisodeConfig config, EpisodeProgress ep) {
    final loc = LocalizationManager();
    return Container(
      padding: const EdgeInsets.all(14), // Reduced from 20
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            config.themeColor.withOpacity(0.3),
            config.themeColor.withOpacity(0.1),
          ],
        ),
        borderRadius: BorderRadius.circular(16), // Slightly smaller radius
        border: Border.all(color: config.themeColor.withOpacity(0.3)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center, // Centered
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  loc.getString('level_world_title').replaceAll('{id}', config.episode.toString()), 
                  style: GoogleFonts.dynaPuff(
                    color: config.themeColor,
                    fontSize: 9, // Smaller
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  loc.getString(config.titleKey).toUpperCase(),
                  style: GoogleFonts.dynaPuff(
                    color: Colors.white,
                    fontSize: 18, // Reduced from 24
                    fontWeight: FontWeight.w800,
                  ),
                ),
                Text(
                  loc.getString(config.descKey),
                  style: GoogleFonts.dynaPuff(
                    color: Colors.white60,
                    fontSize: 11, // Smaller
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
                  Icon(Icons.star, color: PrismazeTheme.starGold, size: 16), // Smaller
                  const SizedBox(width: 4),
                  Text(
                    '${ep.totalStars}',
                    style: GoogleFonts.dynaPuff(
                      color: Colors.white,
                      fontSize: 14, // Smaller
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 2),
              Text(
                '${(ep.progressPercent * 100).toStringAsFixed(0)}%',
                style: GoogleFonts.dynaPuff(
                  color: config.themeColor,
                  fontSize: 11, // Smaller
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

    return BouncingButton(
      onTap: isComplete ? () {} : () => _playLevel(ep.currentLevelIndex),
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

  Widget _buildLevelAccordion(EpisodeConfig config, EpisodeProgress ep) {
    const groupSize = 40; 
    final groupCount = (ep.totalLevels / groupSize).ceil();
    
    return Column(
      children: List.generate(groupCount, (gIdx) {
        final start = gIdx * groupSize;
        final end = ((gIdx + 1) * groupSize).clamp(0, ep.totalLevels);
        final isUnlocked = ep.unlockedMaxIndex >= start;
        final isExpanded = _expandedGroupIndex == gIdx;
        
        return Container(
          margin: const EdgeInsets.only(bottom: 6),
          decoration: BoxDecoration(
            color: PrismazeTheme.backgroundCard,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: isExpanded 
                  ? config.themeColor.withOpacity(0.4) 
                  : Colors.white.withOpacity(0.03)
            ),
          ),
          child: Column(
            children: [
              // Accordion Header
              InkWell(
                onTap: () => setState(() => _expandedGroupIndex = isExpanded ? -1 : gIdx),
                borderRadius: BorderRadius.circular(10),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  child: Row(
                    children: [
                      Text(
                        'Levels ${start + 1} - $end',
                        style: GoogleFonts.dynaPuff(
                          color: isUnlocked ? Colors.white : Colors.white30,
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const Spacer(),
                      Icon(
                        isUnlocked 
                            ? (isExpanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down) 
                            : Icons.lock,
                        color: isUnlocked ? config.themeColor : Colors.white24,
                        size: 18,
                      ),
                    ],
                  ),
                ),
              ),
              if (isExpanded && isUnlocked)
                Container(
                  padding: const EdgeInsets.fromLTRB(6, 0, 6, 8),
                  child: GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 10, 
                      mainAxisSpacing: 3,
                      crossAxisSpacing: 3,
                      childAspectRatio: 0.85,
                    ),
                    itemCount: end - start,
                    itemBuilder: (context, i) {
                      final lIdx = start + i;
                      return _buildLevelGridItem(config, ep, lIdx);
                    },
                  ),
                ),
            ],
          ),
        );
      }),
    );
  }

  Widget _buildLevelGridItem(EpisodeConfig config, EpisodeProgress ep, int lIdx) {
    final stars = ep.getStars(lIdx);
    final isUnlocked = lIdx <= ep.unlockedMaxIndex;
    final isCurrent = lIdx == ep.currentLevelIndex;
    
    return GestureDetector(
      onTap: isUnlocked ? () => _playLevel(lIdx) : null,
      child: Container(
        decoration: BoxDecoration(
          color: isCurrent 
              ? config.themeColor.withOpacity(0.4) 
              : (isUnlocked ? Colors.white.withOpacity(0.03) : Colors.black12),
          borderRadius: BorderRadius.circular(4),
          border: Border.all(
            color: isCurrent 
                ? config.themeColor 
                : (isUnlocked ? Colors.white.withOpacity(0.04) : Colors.transparent),
            width: 0.5,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              '${lIdx + 1}',
              style: GoogleFonts.dynaPuff(
                color: isUnlocked ? Colors.white.withOpacity(0.8) : Colors.white10,
                fontSize: 9, 
                fontWeight: isCurrent ? FontWeight.w900 : FontWeight.w500,
                height: 1,
              ),
            ),
            const SizedBox(height: 1),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(3, (sIdx) => Icon(
                Icons.star,
                size: 5, 
                color: sIdx < stars 
                    ? PrismazeTheme.starGold 
                    : Colors.white.withOpacity(0.03),
              )),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButtons(EpisodeConfig config, EpisodeProgress ep) {
    return _buildActionItem(config, 'Jump to Level', Icons.skip_next, () => _showJumpDialog(config, ep));
  }

  Widget _buildActionItem(EpisodeConfig config, String label, IconData icon, VoidCallback onTap) {
    return BouncingButton(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: PrismazeTheme.backgroundCard,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: config.themeColor.withOpacity(0.3)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: config.themeColor, size: 16),
            const SizedBox(width: 8),
            Text(label, style: GoogleFonts.dynaPuff(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600)),
          ],
        ),
      ),
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

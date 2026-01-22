import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../game/world_data.dart';
import '../game/progress_manager.dart';
import '../game/economy_manager.dart';
import '../game/audio_manager.dart';
import '../game/localization_manager.dart';
import '../theme/app_theme.dart';
import 'components/styled_back_button.dart';
import 'components/fast_page_route.dart';
import 'game_screen.dart';

class LevelSelectScreen extends StatefulWidget {
  const LevelSelectScreen({super.key});

  @override
  State<LevelSelectScreen> createState() => _LevelSelectScreenState();
}

class _LevelSelectScreenState extends State<LevelSelectScreen> {
  late ProgressManager progress;
  late EconomyManager economy;
  bool _loading = true;
  int? _expandedWorldId;

  @override
  void initState() {
    super.initState();
    _initManagers();
  }

  Future<void> _initManagers() async {
    progress = ProgressManager();
    economy = EconomyManager();
    await progress.init();
    await economy.init();
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
              Expanded(child: _buildAccordionList(loc)),
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
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          StyledBackButton(),
          Text(loc.getString('levels'), style: GoogleFonts.dynaPuff(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w800)),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(color: PrismazeTheme.backgroundCard, borderRadius: BorderRadius.circular(16)),
            child: Row(
              children: [
                Icon(Icons.lightbulb, color: PrismazeTheme.warningYellow, size: 16),
                const SizedBox(width: 4),
                Text('${economy.tokens}', style: GoogleFonts.dynaPuff(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w700)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAccordionList(LocalizationManager loc) {
    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: GameWorlds.worlds.length,
      itemBuilder: (context, index) {
        final world = GameWorlds.worlds[index];
        final isExpanded = _expandedWorldId == world.id;
        final isUnlocked = progress.isWorldUnlocked(world.id);
        
        return _buildWorldAccordion(world, isExpanded, isUnlocked, loc);
      },
    );
  }

  Widget _buildWorldAccordion(WorldData world, bool isExpanded, bool isUnlocked, LocalizationManager loc) {
    final completedInWorld = _getCompletedLevelsInWorld(world);
    final starsInWorld = _getStarsInWorld(world);

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        gradient: isUnlocked 
            ? LinearGradient(colors: [world.themeColor.withOpacity(0.4), world.themeColor.withOpacity(0.1)])
            : null,
        color: isUnlocked ? null : Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: isExpanded ? world.themeColor : (isUnlocked ? world.themeColor.withOpacity(0.3) : Colors.white12), width: isExpanded ? 2 : 1),
      ),
      child: Column(
        children: [
          // Header
          GestureDetector(
            onTap: () {
              AudioManager().playSfxId(SfxId.uiClick);
              if (isUnlocked) {
                setState(() => _expandedWorldId = isExpanded ? null : world.id);
              } else {
                _showLockedWarning();
              }
            },
            child: Container(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  // Icon
                  Container(
                    width: 50, height: 50,
                    decoration: BoxDecoration(color: world.themeColor.withOpacity(isUnlocked ? 0.3 : 0.1), borderRadius: BorderRadius.circular(10)),
                    child: Icon(isUnlocked ? world.icon : Icons.lock, color: isUnlocked ? world.themeColor : Colors.white30, size: 28),
                  ),
                  const SizedBox(width: 12),
                  // Info
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(loc.getStringParam('level_world_title', {'id': '${world.id}'}), style: GoogleFonts.dynaPuff(color: isUnlocked ? world.themeColor : Colors.white30, fontSize: 10, fontWeight: FontWeight.w600)),
                        Text(loc.getString(world.nameKey), style: GoogleFonts.dynaPuff(color: isUnlocked ? Colors.white : Colors.white30, fontSize: 14, fontWeight: FontWeight.w800)),
                        if (isUnlocked) ...[
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Text('$completedInWorld/${world.levelCount}', style: GoogleFonts.dynaPuff(color: Colors.white60, fontSize: 10)),
                              const SizedBox(width: 12),
                              Icon(Icons.star, color: PrismazeTheme.starGold, size: 12),
                              Text(' $starsInWorld', style: GoogleFonts.dynaPuff(color: Colors.white60, fontSize: 10)),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                  // Arrow
                  if (isUnlocked)
                    AnimatedRotation(
                      turns: isExpanded ? 0.5 : 0,
                      duration: const Duration(milliseconds: 200),
                      child: Icon(Icons.keyboard_arrow_down, color: world.themeColor, size: 28),
                    ),
                ],
              ),
            ),
          ),
          // Expanded Level Grid
          AnimatedCrossFade(
            firstChild: const SizedBox.shrink(),
            secondChild: _buildLevelGridInCard(world),
            crossFadeState: isExpanded ? CrossFadeState.showSecond : CrossFadeState.showFirst,
            duration: const Duration(milliseconds: 250),
          ),
        ],
      ),
    );
  }

  Widget _buildLevelGridInCard(WorldData world) {
    final levels = List.generate(world.levelCount, (i) => world.startLevel + i);
    
    return Container(
      padding: const EdgeInsets.fromLTRB(8, 0, 8, 8),
      child: Wrap(
        spacing: 6,
        runSpacing: 6,
        children: levels.map((levelId) {
          final stars = progress.getStarsForLevel(levelId);
          final isCompleted = stars > 0;
          final isUnlocked = progress.isLevelUnlocked(levelId);
          final isCurrent = isUnlocked && !isCompleted;

          return GestureDetector(
            onTap: () {
              if (isUnlocked) {
                AudioManager().playSfxId(SfxId.uiClick);
                Navigator.push(context, FastPageRoute(page: GameScreen(levelId: levelId)));
              } else {
                _showLockedLevelWarning(levelId);
              }
            },
            child: Container(
              width: 48, height: 48,
              decoration: BoxDecoration(
                color: isCompleted ? world.themeColor.withOpacity(0.3) : isUnlocked ? PrismazeTheme.backgroundCard : Colors.white.withOpacity(0.05),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: isCurrent ? Colors.white : isCompleted ? world.themeColor.withOpacity(0.5) : Colors.white10, width: isCurrent ? 2 : 1),
                boxShadow: isCurrent ? [BoxShadow(color: Colors.white.withOpacity(0.3), blurRadius: 6)] : null,
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (!isUnlocked)
                    Icon(Icons.lock, color: Colors.white30, size: 14)
                  else ...[
                    Text('$levelId', style: GoogleFonts.dynaPuff(color: isCompleted ? world.themeColor : Colors.white, fontSize: 12, fontWeight: FontWeight.w800)),
                    if (isCompleted && stars > 0)
                      Row(mainAxisAlignment: MainAxisAlignment.center, children: List.generate(3, (i) => Icon(Icons.star, size: 6, color: i < stars ? PrismazeTheme.starGold : Colors.white24))),
                  ],
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  int _getCompletedLevelsInWorld(WorldData world) {
    int count = 0;
    for (int i = world.startLevel; i <= world.endLevel; i++) {
        if (progress.getStarsForLevel(i) > 0) count++;
    }
    return count;
  }

  int _getStarsInWorld(WorldData world) {
    int stars = 0;
    for (int i = world.startLevel; i <= world.endLevel; i++) {
      stars += progress.getStarsForLevel(i);
    }
    return stars;
  }

  void _showLockedWarning() {
    AudioManager().playSfxId(SfxId.error);
    final loc = LocalizationManager();
    
    showDialog(
      context: context,
      barrierColor: Colors.black54,
      builder: (ctx) => Center(
        child: Material(
          color: Colors.transparent,
          child: TweenAnimationBuilder<double>(
            tween: Tween(begin: 0.8, end: 1.0),
            duration: const Duration(milliseconds: 200),
            curve: Curves.elasticOut,
            builder: (context, scale, child) => Transform.scale(scale: scale, child: child),
            child: Container(
              margin: const EdgeInsets.all(40),
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
              color: PrismazeTheme.backgroundCard,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: PrismazeTheme.warningYellow.withOpacity(0.5), width: 2),
              boxShadow: [BoxShadow(color: PrismazeTheme.warningYellow.withOpacity(0.3), blurRadius: 20)],
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
                  loc.getString('level_locked'),
                  style: GoogleFonts.dynaPuff(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 8),
                Text(
                  loc.getString('level_locked_msg'),
                  style: GoogleFonts.dynaPuff(color: Colors.white70, fontSize: 13),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 20),
                GestureDetector(
                  onTap: () {
                    AudioManager().playSfxId(SfxId.uiClick);
                    Navigator.pop(ctx);
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 10),
                    decoration: BoxDecoration(
                      gradient: PrismazeTheme.buttonGradient,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(LocalizationManager().getString('btn_close'), style: GoogleFonts.dynaPuff(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w700)),
                  ),
                ),
              ],
            ),
          ),
        ),
        ),
      ),
    );
  }

  void _showLockedLevelWarning(int levelId) {
    AudioManager().playSfxId(SfxId.error);
    final loc = LocalizationManager();
    final neededLevel = levelId - 1;
    
    showDialog(
      context: context,
      barrierColor: Colors.black54,
      builder: (ctx) => Center(
        child: Material(
          color: Colors.transparent,
          child: TweenAnimationBuilder<double>(
            tween: Tween(begin: 0.8, end: 1.0),
            duration: const Duration(milliseconds: 200),
            curve: Curves.elasticOut,
            builder: (context, scale, child) => Transform.scale(scale: scale, child: child),
            child: Container(
              margin: const EdgeInsets.all(40),
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: PrismazeTheme.backgroundCard,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: PrismazeTheme.warningYellow.withOpacity(0.5), width: 2),
                boxShadow: [BoxShadow(color: PrismazeTheme.warningYellow.withOpacity(0.3), blurRadius: 20)],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(color: PrismazeTheme.warningYellow.withOpacity(0.2), shape: BoxShape.circle),
                    child: Icon(Icons.lock_outline, color: PrismazeTheme.warningYellow, size: 40),
                  ),
                  const SizedBox(height: 16),
                  Text(loc.getString('level_locked'), style: GoogleFonts.dynaPuff(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w800)),
                  const SizedBox(height: 8),
                  Text(loc.getStringParam('level_locked_msg', {'level': '$neededLevel'}), style: GoogleFonts.dynaPuff(color: Colors.white70, fontSize: 13), textAlign: TextAlign.center),
                  const SizedBox(height: 20),
                  GestureDetector(
                    onTap: () {
                      AudioManager().playSfxId(SfxId.uiClick);
                      Navigator.pop(ctx);
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 10),
                      decoration: BoxDecoration(gradient: PrismazeTheme.buttonGradient, borderRadius: BorderRadius.circular(20)),
                      child: Text(LocalizationManager().getString('btn_close'), style: GoogleFonts.dynaPuff(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w700)),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}


import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../game/progress_manager.dart';
import '../game/localization_manager.dart';
import '../theme/app_theme.dart';
import 'components/styled_back_button.dart';

/// Achievements Display Screen
class AchievementsScreen extends StatelessWidget {
  final ProgressManager progressManager;
  
  const AchievementsScreen({super.key, required this.progressManager});
  
  @override
  Widget build(BuildContext context) {
    final loc = LocalizationManager();

    return Scaffold(
      backgroundColor: PrismazeTheme.backgroundDark,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(loc.getString('ach_title'), style: GoogleFonts.dynaPuff(fontWeight: FontWeight.bold)),
        leadingWidth: 100,
        leading: Padding(
          padding: const EdgeInsets.only(left: 8, top: 8, bottom: 8),
          child: StyledBackButton(),
        ),
      ),
      body: SafeArea(
        child: Row(
          children: [
            // Categories as horizontal scrolling columns
            Expanded(
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.all(16),
                children: [
                  _buildCategoryColumn(loc.getString('cat_speed'), Icons.speed, Colors.orangeAccent, [
                    _Achievement(loc.getString('ach_quick_thinker'), loc.getString('ach_desc_quick_thinker'), 'ach_quick_thinker', 3),
                    _Achievement(loc.getString('ach_speed_1'), loc.getString('ach_desc_one_shot_master'), 'ach_speed_1', 5), 
                    _Achievement(loc.getString('ach_speed_master'), '50 level < 20s', 'ach_speed_master', 10),
                  ], loc),
                  const SizedBox(width: 16),
                  
                  _buildCategoryColumn(loc.getString('cat_perfection'), Icons.star, Colors.amber, [
                    _Achievement(loc.getString('ach_perfectionist'), loc.getString('ach_desc_perfectionist'), 'ach_perfectionist', 5),
                    _Achievement(loc.getString('ach_star_hunter'), loc.getString('ach_desc_star_hunter'), 'ach_star_hunter', 5),
                    _Achievement(loc.getString('ach_perfect_1'), '10 level 3 star', 'ach_perfect_1', 5),
                    _Achievement(loc.getString('ach_clean_sweep'), loc.getString('ach_desc_clean_sweep'), 'ach_clean_sweep', 10),
                    _Achievement(loc.getString('ach_perfect_master'), '200 level 3 star', 'ach_perfect_master', 10),
                  ], loc),
                  const SizedBox(width: 16),
                  
                  _buildCategoryColumn(loc.getString('cat_marathon'), Icons.directions_run, Colors.greenAccent, [
                    _Achievement(loc.getString('ach_warmup'), loc.getString('ach_desc_warmup'), 'ach_warmup', 3),
                    _Achievement(loc.getString('ach_marathon_1'), '10 level session', 'ach_marathon_1', 3),
                    _Achievement(loc.getString('ach_focused'), loc.getString('ach_desc_focused'), 'ach_focused', 5),
                    _Achievement(loc.getString('ach_marathon_master'), '100 level session', 'ach_marathon_master', 10),
                  ], loc),
                  const SizedBox(width: 16),
                  
                  _buildCategoryColumn(loc.getString('cat_independence'), Icons.lightbulb_outline, Colors.cyanAccent, [
                    _Achievement(loc.getString('ach_self_starter'), loc.getString('ach_desc_self_starter'), 'ach_self_starter', 3),
                    _Achievement(loc.getString('ach_patient'), loc.getString('ach_desc_patient'), 'ach_patient', 5),
                    _Achievement(loc.getString('ach_independent_1'), '25 level no hint', 'ach_independent_1', 5),
                    _Achievement(loc.getString('ach_problem_solver'), loc.getString('ach_desc_problem_solver'), 'ach_problem_solver', 5),
                    _Achievement(loc.getString('ach_independent_master'), '100 level no hint', 'ach_independent_master', 10),
                  ], loc),
                  const SizedBox(width: 16),
                  
                  _buildCategoryColumn(loc.getString('cat_secret'), Icons.visibility_off, Colors.purpleAccent, [
                    _Achievement(loc.getString('ach_darkness'), loc.getString('ach_desc_darkness'), 'ach_darkness', 5),
                    _Achievement(loc.getString('ach_minimalist'), loc.getString('ach_desc_minimalist'), 'ach_minimalist', 10),
                    _Achievement(loc.getString('ach_lucky_7'), '7 attempts', 'ach_lucky_7', 3),
                    _Achievement(loc.getString('ach_night_owl'), '10x 02:00-04:00', 'ach_night_owl', 5),
                    _Achievement(loc.getString('ach_patience_stone'), '10 min level', 'ach_patience_stone', 5),
                  ], loc),
                  const SizedBox(width: 16),
                  
                  _buildCategoryColumn(loc.getString('cat_legend'), Icons.auto_awesome, Colors.amber, [
                    _Achievement(loc.getString('ach_first_light'), loc.getString('ach_desc_first_light'), 'ach_first_light', 3),
                    _Achievement(loc.getString('ach_light_apprentice'), loc.getString('ach_desc_light_apprentice'), 'ach_light_apprentice', 5),
                    _Achievement(loc.getString('ach_light_master'), '200 Level', 'ach_light_master', 10),
                    _Achievement(loc.getString('ach_legend'), '20 Achievements', 'ach_legend', 10),
                  ], loc),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildCategoryColumn(String title, IconData icon, Color color, List<_Achievement> achievements, LocalizationManager loc) {
    return Container(
      width: 280, // Fixed width for horizontal scroll
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Icon(icon, color: color, size: 20),
              const SizedBox(width: 8),
              Text(title, style: GoogleFonts.dynaPuff(color: color, fontSize: 16, fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 12),
          
          // Achievement Cards (scrollable vertically within column)
          Expanded(
            child: ListView(
              shrinkWrap: true,
              children: achievements.map((a) => _buildAchievementCard(a, color, loc)).toList(),
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildAchievementCard(_Achievement achievement, Color categoryColor, LocalizationManager loc) {
    final isUnlocked = progressManager.isAchievementUnlocked(achievement.id);
    
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isUnlocked ? categoryColor.withOpacity(0.2) : PrismazeTheme.backgroundCard,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isUnlocked ? categoryColor.withOpacity(0.5) : Colors.white12,
        ),
        boxShadow: isUnlocked ? [
           BoxShadow(color: categoryColor.withOpacity(0.1), blurRadius: 8)
        ] : null,
      ),
      child: Row(
        children: [
          // Icon
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isUnlocked ? categoryColor : Colors.white10,
            ),
            child: Icon(
              isUnlocked ? Icons.check : Icons.lock,
              color: isUnlocked ? Colors.white : Colors.white38,
              size: 20,
            ),
          ),
          
          const SizedBox(width: 12),
          
          // Text
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  achievement.title,
                  style: GoogleFonts.dynaPuff(
                    color: isUnlocked ? Colors.white : Colors.white70,
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
                Text(
                  achievement.description,
                  style: GoogleFonts.dynaPuff(
                    color: isUnlocked ? Colors.white70 : Colors.white38,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
          
          // Reward
          if (isUnlocked)
            Row(
              children: [
                Icon(Icons.lightbulb, size: 12, color: PrismazeTheme.warningYellow),
                Text('+${achievement.reward}', style: GoogleFonts.dynaPuff(color: PrismazeTheme.warningYellow, fontSize: 12, fontWeight: FontWeight.bold)),
              ],
            ),
        ],
      ),
    );
  }
}

class _Achievement {
  final String title;
  final String description;
  final String id;
  final int reward;
  
  const _Achievement(this.title, this.description, this.id, this.reward);
}


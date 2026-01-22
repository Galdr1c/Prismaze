import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../game/progress_manager.dart';
import '../game/localization_manager.dart';
import 'components/styled_back_button.dart';

/// Achievements Display Screen
class AchievementsScreen extends StatelessWidget {
  final ProgressManager progressManager;
  
  const AchievementsScreen({super.key, required this.progressManager});
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D0D1A),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(LocalizationManager().getString('ach_title'), style: GoogleFonts.dynaPuff(fontWeight: FontWeight.bold)),
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
                  _buildCategoryColumn('Hız', Icons.speed, Colors.orangeAccent, [
                    _Achievement('Hızlı Düşünür', 'Bir leveli 10 saniyede bitir', 'ach_quick_thinker'),
                    _Achievement('Işık Hızı', '5 level altında 20 saniye', 'ach_speed_1'),
                    _Achievement('Hız Ustası', '50 level altında 20 saniye', 'ach_speed_master'),
                  ]),
                  const SizedBox(width: 16),
                  
                  _buildCategoryColumn('Mükemmellik', Icons.star, Colors.amber, [
                    _Achievement('Mükemmeliyetçi', '5 art arda 3 yıldız', 'ach_perfectionist'),
                    _Achievement('Altın Yol', '10 level 3 yıldız', 'ach_perfect_1'),
                    _Achievement('Mükemmellik Ustası', '200 level 3 yıldız', 'ach_perfect_master'),
                  ]),
                  const SizedBox(width: 16),
                  
                  _buildCategoryColumn('Maraton', Icons.directions_run, Colors.greenAccent, [
                    _Achievement('Devamlılık', '10 level tek oturumda', 'ach_marathon_1'),
                    _Achievement('Maraton Koşucusu', '25 level tek oturumda', 'ach_marathon_2'),
                    _Achievement('Maraton Ustası', '100 level tek oturumda', 'ach_marathon_master'),
                  ]),
                  const SizedBox(width: 16),
                  
                  _buildCategoryColumn('Bağımsızlık', Icons.lightbulb_outline, Colors.cyanAccent, [
                    _Achievement('Tereddütsüz', '20 level ipuçsuz', 'ach_patient'),
                    _Achievement('Bağımsız', '25 level ipuçsuz', 'ach_independent_1'),
                    _Achievement('Bağımsızlık Ustası', '100 level ipuçsuz', 'ach_independent_master'),
                  ]),
                  const SizedBox(width: 16),
                  
                  _buildCategoryColumn('Gizli', Icons.visibility_off, Colors.purpleAccent, [
                    _Achievement('Karanlık', 'Tüm sesleri kapat', 'ach_darkness'),
                    _Achievement('Minimalist', 'Bir leveli 1 hamlede bitir', 'ach_minimalist'),
                    _Achievement('Şanslı 7', '7. denemede bitir', 'ach_lucky_7'),
                    _Achievement('Gece Kuşu', '10 kez gece 2-4 arası oyna', 'ach_night_owl'),
                    _Achievement('Sabır Taşı', 'Bir levelde 10 dakika geçir', 'ach_patience_stone'),
                  ]),
                  const SizedBox(width: 16),
                  
                  _buildCategoryColumn('Efsane', Icons.auto_awesome, Colors.amber, [
                    _Achievement('İlk Işık', 'Level 1\'i bitir', 'ach_first_light'),
                    _Achievement('Işık Çırağı', '100 level bitir', 'ach_light_apprentice'),
                    _Achievement('Işık Ustası', '200 level bitir', 'ach_light_master'),
                    _Achievement('Efsane', '20 başarı aç', 'ach_legend'),
                  ]),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildCategoryColumn(String title, IconData icon, Color color, List<_Achievement> achievements) {
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
              children: achievements.map((a) => _buildAchievementCard(a, color)).toList(),
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildAchievementCard(_Achievement achievement, Color categoryColor) {
    // Check if unlocked (stub - would check progressManager)
    final isUnlocked = false; // TODO: Check actual unlock status
    
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isUnlocked ? categoryColor.withOpacity(0.2) : Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isUnlocked ? categoryColor.withOpacity(0.5) : Colors.white12,
        ),
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
                  ),
                ),
                Text(
                  achievement.description,
                  style: GoogleFonts.dynaPuff(
                    color: isUnlocked ? Colors.white70 : Colors.white38,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          
          // Reward
          if (isUnlocked)
            const Text('+20 🪙', style: TextStyle(color: Colors.amber)),
        ],
      ),
    );
  }
}

class _Achievement {
  final String title;
  final String description;
  final String id;
  
  const _Achievement(this.title, this.description, this.id);
}


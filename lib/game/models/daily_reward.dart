/// Model class representing a daily login reward
class DailyReward {
  final int day;
  final int hintAmount;
  final String? skinId;
  final String? particleEffectId;
  final String? backgroundId;
  final String rarity; 
  final String? label;

  const DailyReward({
    required this.day,
    required this.hintAmount,
    this.skinId,
    this.particleEffectId,
    this.backgroundId,
    this.rarity = 'common',
    this.label,
  });

  bool get hasSkin => skinId != null;
  bool get hasEffect => particleEffectId != null;
  bool get hasBackground => backgroundId != null;
  bool get hasSpecialReward => hasSkin || hasEffect || hasBackground;

  /// The 7-day reward cycle with escalating rewards
  static const List<DailyReward> rewardCycle = [
    DailyReward(day: 1, hintAmount: 5),
    DailyReward(day: 2, hintAmount: 10),
    DailyReward(day: 3, hintAmount: 15),
    DailyReward(day: 4, hintAmount: 20),
    DailyReward(day: 5, hintAmount: 25),
    DailyReward(day: 6, hintAmount: 30),
    DailyReward(
      day: 7, 
      hintAmount: 50, 
      skinId: 'skin_daily_epic', 
      backgroundId: 'theme_daily_exclusive',
      rarity: 'epic',
      label: 'Epic Bundle',
    ),
  ];

  /// Rare Grand Prizes for Day 7 (Rotating Weekly)
  static const List<DailyReward> grandPrizes = [
    DailyReward(
      day: 7, 
      hintAmount: 50, 
      skinId: 'skin_neon', 
      rarity: 'rare', // Week 1: Neon Skin
      label: 'Neon',
    ),
    DailyReward(
      day: 7, 
      hintAmount: 50, 
      backgroundId: 'theme_forest',
      rarity: 'rare', // Week 2: Forest Theme
      label: 'Forest',
    ),
    DailyReward(
      day: 7, 
      hintAmount: 50, 
      skinId: 'skin_sunset',
      rarity: 'rare', // Week 3: Sunset Skin
      label: 'Sunset',
    ),
    DailyReward(
      day: 7, 
      hintAmount: 50, 
      backgroundId: 'theme_desert',
      rarity: 'rare', // Week 4: Desert Theme
      label: 'Desert',
    ),
  ];

  /// Get reward for a specific day (1-7)
  static DailyReward getForDay(int day) {
    if (day == 7) {
      // Rotate based on week number since epoch
      final int weekNum = (DateTime.now().millisecondsSinceEpoch / (1000 * 60 * 60 * 24 * 7)).floor();
      return grandPrizes[weekNum % grandPrizes.length];
    }
    
    final index = ((day - 1) % 7).clamp(0, 6);
    return rewardCycle[index];
  }

  @override
  String toString() => 'DailyReward(day: $day, hints: $hintAmount, skin: $skinId, effect: $particleEffectId, bg: $backgroundId)';
}

/// Result of checking daily reward status
class DailyRewardStatus {
  final bool canClaim;
  final DailyReward currentReward;
  final DailyReward nextReward;
  final int currentStreak;
  final bool wasStreakBroken;
  final Duration? timeUntilNextClaim;

  const DailyRewardStatus({
    required this.canClaim,
    required this.currentReward,
    required this.nextReward,
    required this.currentStreak,
    this.wasStreakBroken = false,
    this.timeUntilNextClaim,
  });
}

/// Cost options for restoring a broken streak
class StreakRestoreOption {
  static const int hintCost = 50;
  static const bool allowAdRestore = true;
}


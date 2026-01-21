/// Model class representing a daily login reward
class DailyReward {
  final int day;
  final int hintTokens;
  final String? skinId;
  final String? particleEffectId;
  final String? backgroundId;
  final String rarity; // 'common', 'rare', 'epic'

  const DailyReward({
    required this.day,
    required this.hintTokens,
    this.skinId,
    this.particleEffectId,
    this.backgroundId,
    this.rarity = 'common',
  });

  bool get hasSkin => skinId != null;
  bool get hasEffect => particleEffectId != null;
  bool get hasBackground => backgroundId != null;
  bool get hasSpecialReward => hasSkin || hasEffect || hasBackground;

  /// The 7-day reward cycle with escalating rewards
  static const List<DailyReward> rewardCycle = [
    DailyReward(day: 1, hintTokens: 5),
    DailyReward(day: 2, hintTokens: 10),
    DailyReward(day: 3, hintTokens: 15, skinId: 'skin_daily_common', rarity: 'common'),
    DailyReward(day: 4, hintTokens: 20),
    DailyReward(day: 5, hintTokens: 25, skinId: 'skin_daily_rare', rarity: 'rare'),
    DailyReward(day: 6, hintTokens: 30, particleEffectId: 'effect_daily_special', rarity: 'rare'),
    DailyReward(
      day: 7, 
      hintTokens: 50, 
      skinId: 'skin_daily_epic', 
      backgroundId: 'theme_daily_exclusive',
      rarity: 'epic',
    ),
  ];

  /// Get reward for a specific day (1-7)
  static DailyReward getForDay(int day) {
    final index = ((day - 1) % 7).clamp(0, 6);
    return rewardCycle[index];
  }

  @override
  String toString() => 'DailyReward(day: $day, tokens: $hintTokens, skin: $skinId, effect: $particleEffectId, bg: $backgroundId)';
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
  static const int tokenCost = 50;
  static const bool allowAdRestore = true;
}

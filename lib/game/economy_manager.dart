import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart';
import 'package:flame/components.dart';
import 'utils/security_utils.dart';
import 'models/daily_reward.dart';

/// Comeback bonus for returning players
class ComebackReward {
  final int hintTokens;
  final String? freeSkinId;
  final String message;
  final int daysAway;
  final bool isLongAbsence;

  const ComebackReward({
    required this.hintTokens,
    this.freeSkinId,
    required this.message,
    required this.daysAway,
    this.isLongAbsence = false,
  });
}

class EconomyManager extends ChangeNotifier {
  static const String keyTokens = 'hint_tokens_enc'; // Changed key for encrypted
  static const String keyTokensChecksum = 'hint_tokens_cs';
  static const String keyLastLogin = 'last_login_date';
  static const String keyDailyStreak = 'daily_streak';
  static const String keyLastPlayedDate = 'last_played_date';
  static const String keyComebackClaimed = 'comeback_claimed';
  
  late SharedPreferences _prefs;
  int _tokens = 0;
  final ValueNotifier<int> tokenNotifier = ValueNotifier(0);
  
  // Comeback bonus state
  ComebackReward? _pendingComebackReward;
  ComebackReward? get pendingComebackReward => _pendingComebackReward;
  bool get hasComebackReward => _pendingComebackReward != null;
  
  int get tokens => _tokens;
  
  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
    
    // Try to load encrypted tokens
    final encoded = _prefs.getString(keyTokens);
    if (encoded != null) {
        final decoded = SecurityUtils.decodeValue(encoded);
        if (decoded != null) {
            _tokens = decoded;
        } else {
            // Tampered - reset to 0
            print("[Security] Token data tampered, resetting.");
            _tokens = 0;
            await _saveTokensSecurely();
        }
    } else if (!_prefs.containsKey(keyTokens)) {
        // New user
        addTokens(10);
    }
    
    tokenNotifier.value = _tokens;
    
    // Check for comeback bonus
    await _checkComebackBonus();
    
    _checkDailyLogin();
  }
  
  /// Check if user qualifies for comeback bonus
  Future<void> _checkComebackBonus() async {
    final lastPlayedStr = _prefs.getString(keyLastPlayedDate);
    if (lastPlayedStr == null) {
      // First time user - no comeback bonus
      await _updateLastPlayedDate();
      return;
    }
    
    // Check if already claimed comeback this session
    final comebackDate = _prefs.getString(keyComebackClaimed);
    final todayStr = DateTime.now().toIso8601String().substring(0, 10);
    if (comebackDate == todayStr) {
      // Already claimed today
      return;
    }
    
    final lastPlayed = DateTime.tryParse(lastPlayedStr);
    if (lastPlayed == null) {
      await _updateLastPlayedDate();
      return;
    }
    
    final daysSinceLastPlay = DateTime.now().difference(lastPlayed).inDays;
    
    if (daysSinceLastPlay >= 30) {
      // Long absence - big reward
      _pendingComebackReward = ComebackReward(
        hintTokens: 100,
        freeSkinId: 'skin_comeback_special',
        message: 'Seni özledik! İşte özel bir hediye!',
        daysAway: daysSinceLastPlay,
        isLongAbsence: true,
      );
    } else if (daysSinceLastPlay >= 3) {
      // Short absence - regular reward
      _pendingComebackReward = ComebackReward(
        hintTokens: 50,
        message: 'Tekrar hoş geldin! İşte bir hediye!',
        daysAway: daysSinceLastPlay,
      );
    }
    
    // Update last played date
    await _updateLastPlayedDate();
    notifyListeners();
  }
  
  /// Update last played date (call this when user plays)
  Future<void> _updateLastPlayedDate() async {
    await _prefs.setString(keyLastPlayedDate, DateTime.now().toIso8601String());
  }
  
  /// Mark that user has played today
  Future<void> updateLastPlayed() async {
    await _updateLastPlayedDate();
  }
  
  /// Claim comeback bonus
  Future<ComebackReward?> claimComebackReward() async {
    if (_pendingComebackReward == null) return null;
    
    final reward = _pendingComebackReward!;
    
    // Grant tokens
    await addTokensSecure(reward.hintTokens, source: 'comeback_bonus_${reward.daysAway}_days');
    
    // Mark as claimed today
    final todayStr = DateTime.now().toIso8601String().substring(0, 10);
    await _prefs.setString(keyComebackClaimed, todayStr);
    
    _pendingComebackReward = null;
    notifyListeners();
    
    print("Economy: Comeback bonus claimed - ${reward.hintTokens} tokens after ${reward.daysAway} days");
    return reward;
  }

  Future<void> giveTutorialBonus() async {
      // Check if already given? For now just give it.
      // Ideal: check a flag.
      bool given = _prefs.getBool('tutorial_bonus_given') ?? false;
      if (!given) {
          await addTokens(3);
          await _prefs.setBool('tutorial_bonus_given', true);
      }
  }
  
  // --- Daily Login System (Enhanced) ---
  
  bool _canClaimDailyLogin = false;
  int _dailyStreak = 0;
  bool _wasStreakBroken = false;
  int _previousStreak = 0; // For streak restore
  DateTime? _lastClaimTime;
  
  bool get canClaimDailyLogin => _canClaimDailyLogin;
  int get dailyStreak => _dailyStreak;
  bool get wasStreakBroken => _wasStreakBroken;
  int get previousStreak => _previousStreak;
  bool get canRestoreStreak => _wasStreakBroken && _previousStreak > 1;
  
  /// Check daily login status using Local Calendar Days (Midnight Reset)
  Future<void> _checkDailyLogin() async {
      // Use Local time for consistent daily resets at user's midnight
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      
      final lastClaimStr = _prefs.getString(keyLastLogin);
      
      _dailyStreak = _prefs.getInt('login_streak_count') ?? 0;
      _previousStreak = _prefs.getInt('previous_streak') ?? 0;
      _wasStreakBroken = false;
      
      if (lastClaimStr == null) {
          // First time user
          _canClaimDailyLogin = true;
          _dailyStreak = 0;
          notifyListeners();
          return;
      }
      
      _lastClaimTime = DateTime.tryParse(lastClaimStr);
      if (_lastClaimTime == null) {
          _canClaimDailyLogin = true;
          _dailyStreak = 0;
          notifyListeners();
          return;
      }
      
      // Compare Calendar Days
      final lastClaimLocal = _lastClaimTime!.toLocal();
      final lastDate = DateTime(lastClaimLocal.year, lastClaimLocal.month, lastClaimLocal.day);
      
      final diffDays = today.difference(lastDate).inDays;
      
      if (diffDays == 0) {
          // Already claimed today
          _canClaimDailyLogin = false;
      } else if (diffDays == 1) {
          // Claimed yesterday -> Can claim today (Streak continues)
          _canClaimDailyLogin = true;
          
          // Cycle wrap correction: If streak was 7, next claim starts 1
          if (_dailyStreak >= 7) {
              _dailyStreak = 0; 
          }
      } else {
          // diffDays > 1: Missed at least one day -> Streak Broken
          _canClaimDailyLogin = true;
          
          // Only mark broken if we had a meaningful streak
          if (_dailyStreak > 1) {
              _previousStreak = _dailyStreak;
              _wasStreakBroken = true;
              await _prefs.setInt('previous_streak', _dailyStreak);
          }
          _dailyStreak = 0; // Reset to Day 1
      }
      notifyListeners();
  }
  
  /// Get the current reward that would be claimed
  DailyReward getCurrentReward() {
      final day = _canClaimDailyLogin ? (_dailyStreak + 1) : _dailyStreak;
      return DailyReward.getForDay(day.clamp(1, 7));
  }
  
  /// Get preview of next day's reward
  DailyReward getNextReward() {
      final nextDay = (_dailyStreak + 1) > 7 ? 1 : (_dailyStreak + 1);
      return DailyReward.getForDay(nextDay);
  }
  
  /// Get hours until next claim is available (Midnight)
  int getHoursUntilNextClaim() {
      if (_canClaimDailyLogin) return 0;
      // Count down to next midnight
      final now = DateTime.now();
      final midnight = DateTime(now.year, now.month, now.day + 1);
      final diff = midnight.difference(now);
      return diff.inHours + 1; // Round up slightly for display
  }
  
  /// Claim daily login reward
  Future<DailyReward?> claimDailyLoginReward() async {
      if (!_canClaimDailyLogin) return null;
      
      final nowUtc = DateTime.now().toUtc();
      
      _dailyStreak++;
      if (_dailyStreak > 7) _dailyStreak = 1; // Cycle reset
      
      // Save state with ISO timestamp (UTC)
      await _prefs.setString(keyLastLogin, nowUtc.toIso8601String());
      await _prefs.setInt('login_streak_count', _dailyStreak);
      
      // Clear streak broken state after successful claim
      _wasStreakBroken = false;
      _previousStreak = 0;
      await _prefs.remove('previous_streak');
      
      // Get reward for current day
      final reward = DailyReward.getForDay(_dailyStreak);
      
      // Grant tokens
      await addTokensSecure(reward.hintTokens, source: 'daily_login_day_$_dailyStreak');
      
      _canClaimDailyLogin = false;
      _lastClaimTime = nowUtc;
      notifyListeners();
      
      return reward;
  }
  
  /// Restore broken streak by spending 50 tokens
  Future<bool> restoreStreakWithTokens() async {
      if (!canRestoreStreak) return false;
      if (_tokens < StreakRestoreOption.tokenCost) return false;
      
      // Spend tokens
      final spent = await spendTokens(StreakRestoreOption.tokenCost);
      if (!spent) return false;
      
      // Restore previous streak
      _dailyStreak = _previousStreak;
      _wasStreakBroken = false;
      _previousStreak = 0;
      
      await _prefs.setInt('login_streak_count', _dailyStreak);
      await _prefs.remove('previous_streak');
      
      notifyListeners();
      print("Economy: Streak restored to day $_dailyStreak via tokens");
      return true;
  }
  
  /// Restore broken streak after watching ad (called by AdManager)
  Future<bool> restoreStreakWithAd() async {
      if (!canRestoreStreak) return false;
      
      // Restore previous streak
      _dailyStreak = _previousStreak;
      _wasStreakBroken = false;
      _previousStreak = 0;
      
      await _prefs.setInt('login_streak_count', _dailyStreak);
      await _prefs.remove('previous_streak');
      
      notifyListeners();
      print("Economy: Streak restored to day $_dailyStreak via ad");
      return true;
  }

  Future<void> addTokensSecure(int amount, {String source = 'unknown'}) async {
      _tokens += amount;
      tokenNotifier.value = _tokens;
      notifyListeners();
      await _saveTokensSecurely();
      
      print("Economy: Added $amount tokens (Source: $source)");
  }
  
  // Backward compatibility alias
  Future<void> addTokens(int amount) async {
      await addTokensSecure(amount, source: 'legacy_add');
  }

  Future<void> _saveTokensSecurely() async {
      final encoded = SecurityUtils.encodeValue(_tokens);
      final checksum = SecurityUtils.generateChecksum(_tokens, DateTime.now().millisecondsSinceEpoch);
      await _prefs.setString(keyTokens, encoded);
      await _prefs.setString(keyTokensChecksum, checksum);
  }
  
  Future<bool> spendTokens(int amount) async {
      if (_tokens >= amount) {
          _tokens -= amount;
          tokenNotifier.value = _tokens;
          notifyListeners();
          await _saveTokensSecurely(); 
          return true;
      }
      return false;
  }
  
  Future<void> resetData() async {
      _tokens = 0;
      await _saveTokensSecurely();
      await _prefs.remove(keyLastLogin);
      await _prefs.remove(keyDailyStreak);
      notifyListeners();
  }
  
  bool hasUnlimitedHints() {
      final expiryStr = _prefs.getString('unlimited_hints_expiry');
      if (expiryStr == null) return false;
      final expiry = DateTime.parse(expiryStr);
      return DateTime.now().isBefore(expiry);
  }

  Future<int> onLevelComplete(int levelId, int moves, int parMoves) async {
      int earned = 0;
      List<String> earnedRewards = [];
      
      // === CHAPTER FINALE REWARDS (Level 30, 60, 100, 150, 200) ===
      final chapterFinaleLevels = [30, 60, 100, 150, 200];
      if (chapterFinaleLevels.contains(levelId)) {
          earned += 20;
          earnedRewards.add("Bölüm Finali +20 Jeton");
      }
      
      // === MINI-BOSS REWARDS (Level 20, 40, 70, 80, 90) ===
      final miniBossLevels = [20, 40, 70, 80, 90];
      if (miniBossLevels.contains(levelId) && moves <= parMoves) {
          earned += 10;
          earnedRewards.add("Mini-Boss +10 Jeton");
      }
      
      // === SINGLE MOVE BONUS ===
      if (moves == 1) {
          earned += 2;
          earnedRewards.add("Tek Hamle +2 Jeton");
          
          int singleMoveCount = (_prefs.getInt('single_move_count') ?? 0) + 1;
          await _prefs.setInt('single_move_count', singleMoveCount);
          
          int singleMoveStreak = (_prefs.getInt('single_move_streak') ?? 0) + 1;
          await _prefs.setInt('single_move_streak', singleMoveStreak);
          
          if (singleMoveStreak % 5 == 0) {
              earned += 5;
              earnedRewards.add("5 Ardışık Tek Hamle +5 Jeton");
          }
      } else {
          await _prefs.setInt('single_move_streak', 0);
      }
      
      // "Her 10 level: 3 jeton bonus"
      if (levelId % 10 == 0 && !chapterFinaleLevels.contains(levelId)) {
          earned += 3;
          earnedRewards.add("Kilometre Taşı +3 Jeton");
      }
      
      // "Mükemmel çözüm (minimum hamle ile): 2 ekstra jeton"
      if (moves <= parMoves) {
          earned += 2;
          earnedRewards.add("Mükemmel Çözüm +2 Jeton");
      }
      
      // "Üst üste 5 level tek denemede: 5 jeton"
      int streak = _prefs.getInt(keyDailyStreak) ?? 0;
      if (moves <= parMoves) {
          streak++;
          if (streak % 5 == 0) { 
              earned += 5;
              earnedRewards.add("Seri Bonus +5 Jeton");
          }
      } else {
          streak = 0;
      }
      await _prefs.setInt(keyDailyStreak, streak);
      
      if (earned > 0) {
          // Use secure add
          await addTokensSecure(earned, source: 'level_complete_$levelId');
          for (var reward in earnedRewards) {
              print("Ödül: $reward");
          }
      }
      return earned;
  }
  
  // NOTE: Logic for purchaseProduct and watchAdForTokens has been moved to IAPManager and AdManager.
  // This ensures better separation of concerns and simpler testing.
}


import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart';
import 'package:flame/components.dart';
import 'utils/security_utils.dart';
import 'models/daily_reward.dart';

/// Comeback bonus for returning players
class ComebackReward {
  final int amount;
  final String? freeSkinId;
  final String message;
  final int daysAway;
  final bool isLongAbsence;

  const ComebackReward({
    required this.amount,
    this.freeSkinId,
    required this.message,
    required this.daysAway,
    this.isLongAbsence = false,
  });
}

class EconomyManager extends ChangeNotifier {
  static const String keyHints = 'hint_count_enc'; 
  static const String keyHintsChecksum = 'hint_count_cs';
  
  // Legacy keys for migration
  static const String keyLegacyTokens = 'hint_tokens_enc'; 
  static const String keyLegacyTokensChecksum = 'hint_tokens_cs';
  
  static const String keyLastLogin = 'last_login_date';
  static const String keyDailyStreak = 'daily_streak';
  static const String keyLastPlayedDate = 'last_played_date';
  static const String keyComebackClaimed = 'comeback_claimed';
  
  late SharedPreferences _prefs;
  int _hints = 0;
  final ValueNotifier<int> hintNotifier = ValueNotifier(0);
  
  // Comeback bonus state
  ComebackReward? _pendingComebackReward;
  ComebackReward? get pendingComebackReward => _pendingComebackReward;
  bool get hasComebackReward => _pendingComebackReward != null;
  
  int get hints => _hints;
  
  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
    
    // 1. Try to load NEW hint key
    if (_prefs.containsKey(keyHints)) {
        final encoded = _prefs.getString(keyHints);
        if (encoded != null) {
            final decoded = SecurityUtils.decodeValue(encoded);
            if (decoded != null) {
                _hints = decoded;
            } else {
                print("[Security] Hint data tampered, resetting.");
                _hints = 0;
                await _saveHintsSecurely();
            }
        }
    } 
    // 2. Migration: Check for OLD token key
    else if (_prefs.containsKey(keyLegacyTokens)) {
        print("[Economy] Migrating legacy tokens to hints...");
        final encoded = _prefs.getString(keyLegacyTokens);
        if (encoded != null) {
            final decoded = SecurityUtils.decodeValue(encoded);
            if (decoded != null) {
                _hints = decoded;
            }
        }
        // Save to new key and remove old
        await _saveHintsSecurely();
        await _prefs.remove(keyLegacyTokens);
        await _prefs.remove(keyLegacyTokensChecksum);
        print("[Economy] Migration complete. Hints: $_hints");
    }
    // 3. New User
    else {
        addHints(10);
    }
    
    hintNotifier.value = _hints;
    
    // Check for comeback bonus
    await _checkComebackBonus();
    
    _checkDailyLogin();
  }
  
  /// Check if user qualifies for comeback bonus
  Future<void> _checkComebackBonus() async {
    final lastPlayedStr = _prefs.getString(keyLastPlayedDate);
    if (lastPlayedStr == null) {
      await _updateLastPlayedDate();
      return;
    }
    
    final comebackDate = _prefs.getString(keyComebackClaimed);
    final todayStr = DateTime.now().toIso8601String().substring(0, 10);
    if (comebackDate == todayStr) return;
    
    final lastPlayed = DateTime.tryParse(lastPlayedStr);
    if (lastPlayed == null) {
      await _updateLastPlayedDate();
      return;
    }
    
    final daysSinceLastPlay = DateTime.now().difference(lastPlayed).inDays;
    
    if (daysSinceLastPlay >= 30) {
      _pendingComebackReward = ComebackReward(
        amount: 100,
        freeSkinId: 'skin_comeback_special',
        message: 'Seni özledik! İşte özel bir hediye!',
        daysAway: daysSinceLastPlay,
        isLongAbsence: true,
      );
    } else if (daysSinceLastPlay >= 3) {
      _pendingComebackReward = ComebackReward(
        amount: 50,
        message: 'Tekrar hoş geldin! İşte bir hediye!',
        daysAway: daysSinceLastPlay,
      );
    }
    
    await _updateLastPlayedDate();
    notifyListeners();
  }
  
  Future<void> _updateLastPlayedDate() async {
    await _prefs.setString(keyLastPlayedDate, DateTime.now().toIso8601String());
  }
  
  Future<void> updateLastPlayed() async {
    await _updateLastPlayedDate();
  }
  
  Future<ComebackReward?> claimComebackReward() async {
    if (_pendingComebackReward == null) return null;
    
    final reward = _pendingComebackReward!;
    
    await addHintsSecure(reward.amount, source: 'comeback_bonus_${reward.daysAway}_days');
    
    final todayStr = DateTime.now().toIso8601String().substring(0, 10);
    await _prefs.setString(keyComebackClaimed, todayStr);
    
    _pendingComebackReward = null;
    notifyListeners();
    
    print("Economy: Comeback bonus claimed - ${reward.amount} hints");
    return reward;
  }

  Future<void> giveTutorialBonus() async {
      bool given = _prefs.getBool('tutorial_bonus_given') ?? false;
      if (!given) {
          await addHints(3);
          await _prefs.setBool('tutorial_bonus_given', true);
      }
  }
  
  // --- Daily Login System ---
  
  bool _canClaimDailyLogin = false;
  int _dailyStreak = 0;
  bool _wasStreakBroken = false;
  int _previousStreak = 0;
  DateTime? _lastClaimTime;
  
  bool get canClaimDailyLogin => _canClaimDailyLogin;
  int get dailyStreak => _dailyStreak;
  bool get wasStreakBroken => _wasStreakBroken;
  int get previousStreak => _previousStreak;
  bool get canRestoreStreak => _wasStreakBroken && _previousStreak > 1;
  
  Future<void> _checkDailyLogin() async {
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      
      final lastClaimStr = _prefs.getString(keyLastLogin);
      
      _dailyStreak = _prefs.getInt('login_streak_count') ?? 0;
      _previousStreak = _prefs.getInt('previous_streak') ?? 0;
      _wasStreakBroken = false;
      
      if (lastClaimStr == null) {
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
      
      final lastClaimLocal = _lastClaimTime!.toLocal();
      final lastDate = DateTime(lastClaimLocal.year, lastClaimLocal.month, lastClaimLocal.day);
      
      final diffDays = today.difference(lastDate).inDays;
      
      if (diffDays == 0) {
          _canClaimDailyLogin = false;
      } else if (diffDays == 1) {
          _canClaimDailyLogin = true;
          if (_dailyStreak >= 7) {
              _dailyStreak = 0; 
          }
      } else {
          _canClaimDailyLogin = true;
          if (_dailyStreak > 1) {
              _previousStreak = _dailyStreak;
              _wasStreakBroken = true;
              await _prefs.setInt('previous_streak', _dailyStreak);
          }
          _dailyStreak = 0; 
      }
      notifyListeners();
  }
  
  DailyReward getCurrentReward() {
      final day = _canClaimDailyLogin ? (_dailyStreak + 1) : _dailyStreak;
      return DailyReward.getForDay(day.clamp(1, 7));
  }
  
  DailyReward getNextReward() {
      final nextDay = (_dailyStreak + 1) > 7 ? 1 : (_dailyStreak + 1);
      return DailyReward.getForDay(nextDay);
  }
  
  int getHoursUntilNextClaim() {
      if (_canClaimDailyLogin) return 0;
      final now = DateTime.now();
      final midnight = DateTime(now.year, now.month, now.day + 1);
      final diff = midnight.difference(now);
      return diff.inHours + 1;
  }
  
  Future<DailyReward?> claimDailyLoginReward() async {
      if (!_canClaimDailyLogin) return null;
      
      final nowUtc = DateTime.now().toUtc();
      
      _dailyStreak++;
      if (_dailyStreak > 7) _dailyStreak = 1;
      
      await _prefs.setString(keyLastLogin, nowUtc.toIso8601String());
      await _prefs.setInt('login_streak_count', _dailyStreak);
      
      _wasStreakBroken = false;
      _previousStreak = 0;
      await _prefs.remove('previous_streak');
      
      final reward = DailyReward.getForDay(_dailyStreak);
      
      // Grant hints
      await addHintsSecure(reward.hintAmount, source: 'daily_login_day_$_dailyStreak');
      
      _canClaimDailyLogin = false;
      _lastClaimTime = nowUtc;
      notifyListeners();
      
      return reward;
  }
  
  Future<bool> restoreStreakWithHints() async {
      if (!canRestoreStreak) return false;
      
      // Cost to restore streak: 50 Hints? Or maybe less now? 
      // Keeping constant for now
      if (_hints < StreakRestoreOption.hintCost) return false;
      
      final spent = await spendHints(StreakRestoreOption.hintCost);
      if (!spent) return false;
      
      _dailyStreak = _previousStreak;
      _wasStreakBroken = false;
      _previousStreak = 0;
      
      await _prefs.setInt('login_streak_count', _dailyStreak);
      await _prefs.remove('previous_streak');
      
      notifyListeners();
      return true;
  }
  
  Future<bool> restoreStreakWithAd() async {
      if (!canRestoreStreak) return false;
      
      _dailyStreak = _previousStreak;
      _wasStreakBroken = false;
      _previousStreak = 0;
      
      await _prefs.setInt('login_streak_count', _dailyStreak);
      await _prefs.remove('previous_streak');
      
      notifyListeners();
      return true;
  }

  Future<void> addHintsSecure(int amount, {String source = 'unknown'}) async {
      _hints += amount;
      hintNotifier.value = _hints;
      notifyListeners();
      await _saveHintsSecurely();
      
      print("Economy: Added $amount hints (Source: $source)");
  }
  
  Future<void> addHints(int amount) async {
      await addHintsSecure(amount, source: 'legacy_add');
  }

  Future<void> _saveHintsSecurely() async {
      final encoded = SecurityUtils.encodeValue(_hints);
      final checksum = SecurityUtils.generateChecksum(_hints, DateTime.now().millisecondsSinceEpoch);
      await _prefs.setString(keyHints, encoded);
      await _prefs.setString(keyHintsChecksum, checksum);
  }
  
  Future<bool> spendHints(int amount) async {
      if (_hints >= amount) {
          _hints -= amount;
          hintNotifier.value = _hints;
          notifyListeners();
          await _saveHintsSecurely(); 
          return true;
      }
      return false;
  }
  
  Future<void> resetData() async {
      _hints = 0;
      await _saveHintsSecurely();
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
      
      // === CHAPTER FINALE REWARDS ===
      final chapterFinaleLevels = [30, 60, 100, 150, 200];
      if (chapterFinaleLevels.contains(levelId)) {
          earned += 20;
          earnedRewards.add("Bölüm Finali +20 İpucu");
      }
      
      // === MINI-BOSS REWARDS ===
      final miniBossLevels = [20, 40, 70, 80, 90];
      if (miniBossLevels.contains(levelId) && moves <= parMoves) {
          earned += 10;
          earnedRewards.add("Mini-Boss +10 İpucu");
      }
      
      // === SINGLE MOVE BONUS ===
      if (moves == 1) {
          earned += 2;
          earnedRewards.add("Tek Hamle +2 İpucu");
          
          int singleMoveCount = (_prefs.getInt('single_move_count') ?? 0) + 1;
          await _prefs.setInt('single_move_count', singleMoveCount);
          
          int singleMoveStreak = (_prefs.getInt('single_move_streak') ?? 0) + 1;
          await _prefs.setInt('single_move_streak', singleMoveStreak);
          
          if (singleMoveStreak % 5 == 0) {
              earned += 5;
              earnedRewards.add("5 Ardışık Tek Hamle +5 İpucu");
          }
      } else {
          await _prefs.setInt('single_move_streak', 0);
      }
      
      if (levelId % 10 == 0 && !chapterFinaleLevels.contains(levelId)) {
          earned += 3;
          earnedRewards.add("Kilometre Taşı +3 İpucu");
      }
      
      if (moves <= parMoves) {
          earned += 2;
          earnedRewards.add("Mükemmel Çözüm +2 İpucu");
      }
      
      int streak = _prefs.getInt(keyDailyStreak) ?? 0;
      if (moves <= parMoves) {
          streak++;
          if (streak % 5 == 0) { 
              earned += 5;
              earnedRewards.add("Seri Bonus +5 İpucu");
          }
      } else {
          streak = 0;
      }
      await _prefs.setInt(keyDailyStreak, streak);
      
      if (earned > 0) {
          await addHintsSecure(earned, source: 'level_complete_$levelId');
          for (var reward in earnedRewards) {
              print("Ödül: $reward");
          }
      }
      return earned;
  }
}



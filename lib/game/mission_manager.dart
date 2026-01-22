import 'dart:convert';
import 'dart:math';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart';
import 'economy_manager.dart';

enum MissionType {
  playLevels,      // Level completion
  stars3,          // Get 3 stars
  perfectFinish,   // Perfect (par moves)
  noHint,          // No hint used
  watchAd,         // Watch rewarded ad
  playTime,        // Play time (minutes)
  undoFree,        // No undo used
  fastComplete,    // Complete under X seconds
  exactMoves,      // Complete with exact moves
}

class Mission {
  final String id;
  final MissionType type;
  final String description;
  final int target;
  int current;
  final int reward;
  bool claimed;
  final String difficulty; // Easy, Medium, Hard

  Mission({
    required this.id,
    required this.type,
    required this.description,
    required this.target,
    this.current = 0,
    required this.reward,
    this.claimed = false,
    required this.difficulty,
  });

  bool get isCompleted => current >= target;

  Map<String, dynamic> toJson() => {
    'id': id,
    'type': type.index,
    'description': description,
    'target': target,
    'current': current,
    'reward': reward,
    'claimed': claimed,
    'difficulty': difficulty,
  };

  factory Mission.fromJson(Map<String, dynamic> json) => Mission(
    id: json['id'],
    type: MissionType.values[json['type']],
    description: json['description'],
    target: json['target'],
    current: json['current'],
    reward: json['reward'],
    claimed: json['claimed'],
    difficulty: json['difficulty'],
  );
}

class MissionManager extends ChangeNotifier {
  static const String keyMissions = 'daily_missions';
  static const String keyMissionDate = 'mission_date';
  static const String keyBonusClaimed = 'daily_bonus_claimed';
  
  final EconomyManager economyManager;
  late SharedPreferences _prefs;
  
  List<Mission> missions = [];
  bool bonusClaimed = false;
  
  // Reward structure: Complete 1 = 5, Complete 2 = +10 (15 total), Complete 3 = +20 bonus (35 total)
  static const int bonusReward = 20;
  
  MissionManager(this.economyManager);
  
  /// Check if all missions are completed
  bool get allCompleted => missions.every((m) => m.isCompleted);
  
  /// Check if all missions are claimed
  bool get allClaimed => missions.every((m) => m.claimed);
  
  /// Check if bonus is available (all completed and claimed, but bonus not claimed)
  bool get bonusAvailable => allCompleted && allClaimed && !bonusClaimed;
  
  /// Get total earned today (including potential bonus)
  int get totalEarnedToday {
    int total = missions.where((m) => m.claimed).fold(0, (sum, m) => sum + m.reward);
    if (bonusClaimed) total += bonusReward;
    return total;
  }
  
  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
    
    final savedDate = _prefs.getString(keyMissionDate);
    final now = DateTime.now();
    final todayStr = "${now.year}-${now.month}-${now.day}";
    
    if (savedDate != todayStr) {
        _generateDailyMissions();
        await _prefs.setString(keyMissionDate, todayStr);
        await _prefs.setBool(keyBonusClaimed, false);
        bonusClaimed = false;
    } else {
        _loadMissions();
        bonusClaimed = _prefs.getBool(keyBonusClaimed) ?? false;
    }
  }
  
  void _loadMissions() {
      final List<String>? jsonList = _prefs.getStringList(keyMissions);
      if (jsonList != null) {
          missions = jsonList.map((str) => Mission.fromJson(jsonDecode(str))).toList();
      } else {
          _generateDailyMissions();
      }
  }
  
  void _generateDailyMissions() {
      missions = [];
      final random = Random();
      
      // === TYPE 1: LEVEL COMPLETION CHALLENGES (5 tokens) ===
      final levelOptions = [
          Mission(id: 'l1', type: MissionType.playLevels, description: '5 level tamamla', target: 5, reward: 5, difficulty: 'Easy'),
          Mission(id: 'l2', type: MissionType.stars3, description: '3 level 3 yıldızla bitir', target: 3, reward: 5, difficulty: 'Easy'),
          Mission(id: 'l3', type: MissionType.noHint, description: '1 level ipucu kullanmadan bitir', target: 1, reward: 5, difficulty: 'Easy'),
          Mission(id: 'l4', type: MissionType.fastComplete, description: '1 level 30 saniyede bitir', target: 1, reward: 5, difficulty: 'Easy'),
      ];
      missions.add(levelOptions[random.nextInt(levelOptions.length)]);
      
      // === TYPE 2: SKILL CHALLENGES (10 tokens) ===
      final skillOptions = [
          Mission(id: 's1', type: MissionType.perfectFinish, description: '1 level mükemmel çöz (par moves)', target: 1, reward: 10, difficulty: 'Medium'),
          Mission(id: 's2', type: MissionType.stars3, description: '1 level tek denemede 3 yıldız al', target: 1, reward: 10, difficulty: 'Medium'),
          Mission(id: 's3', type: MissionType.undoFree, description: '3 level geri alma kullanmadan bitir', target: 3, reward: 10, difficulty: 'Medium'),
          Mission(id: 's4', type: MissionType.noHint, description: '5 level ipucu kullanmadan bitir', target: 5, reward: 10, difficulty: 'Medium'),
      ];
      missions.add(skillOptions[random.nextInt(skillOptions.length)]);
      
      // === TYPE 3: COLLECTION CHALLENGES (20 tokens) ===
      final collectionOptions = [
          Mission(id: 'c1', type: MissionType.playLevels, description: '15 level tamamla', target: 15, reward: 20, difficulty: 'Hard'),
          Mission(id: 'c2', type: MissionType.watchAd, description: '3 reklam izle', target: 3, reward: 20, difficulty: 'Hard'),
          Mission(id: 'c3', type: MissionType.stars3, description: '10 level 3 yıldızla bitir', target: 10, reward: 20, difficulty: 'Hard'),
          Mission(id: 'c4', type: MissionType.perfectFinish, description: '5 level mükemmel çöz', target: 5, reward: 20, difficulty: 'Hard'),
      ];
      missions.add(collectionOptions[random.nextInt(collectionOptions.length)]);
      
      _saveMissions();
      notifyListeners();
  }
  
  Future<void> _saveMissions() async {
      final jsonList = missions.map((m) => jsonEncode(m.toJson())).toList();
      await _prefs.setStringList(keyMissions, jsonList);
  }
  
  // ============ PROGRESS LISTENERS ============
  
  void onLevelComplete({
    required int stars, 
    required bool perfect, 
    required bool usedHint, 
    required bool usedUndo,
    int? completionTimeSeconds,
  }) {
      bool anyChanged = false;
      
      for (var m in missions) {
          if (m.isCompleted || m.claimed) continue;
          
          switch (m.type) {
              case MissionType.playLevels:
                  m.current++;
                  anyChanged = true;
                  break;
              case MissionType.stars3:
                  if (stars == 3) {
                      m.current++;
                      anyChanged = true;
                  }
                  break;
              case MissionType.perfectFinish:
                  if (perfect) {
                      m.current++;
                      anyChanged = true;
                  }
                  break;
              case MissionType.noHint:
                  if (!usedHint) {
                      m.current++;
                      anyChanged = true;
                  }
                  break;
              case MissionType.undoFree:
                  if (!usedUndo) {
                      m.current++;
                      anyChanged = true;
                  }
                  break;
              case MissionType.fastComplete:
                  if (completionTimeSeconds != null && completionTimeSeconds <= 30) {
                      m.current++;
                      anyChanged = true;
                  }
                  break;
              default:
                  break;
          }
      }
      
      if (anyChanged) {
        _saveMissions();
        notifyListeners();
      }
  }
  
  void onAdWatched() {
       bool anyChanged = false;
       for (var m in missions) {
          if (m.type == MissionType.watchAd && !m.isCompleted && !m.claimed) {
              m.current++;
              anyChanged = true;
          }
       }
       if (anyChanged) {
         _saveMissions();
         notifyListeners();
       }
  }
  
  void onTimeUpdate(double minutes) {
       bool anyChanged = false;
       for (var m in missions) {
          if (m.type == MissionType.playTime && !m.isCompleted && !m.claimed) {
              m.current = minutes.toInt();
              anyChanged = true;
          }
       }
       if (anyChanged) {
         _saveMissions();
         notifyListeners();
       }
  }
  
  /// Claim individual mission reward
  Future<void> claimReward(Mission m) async {
      if (m.isCompleted && !m.claimed) {
          m.claimed = true;
          await economyManager.addTokens(m.reward);
          await _saveMissions();
          notifyListeners();
      }
  }
  
  /// Claim bonus reward for completing all 3 missions
  Future<bool> claimBonusReward() async {
      if (bonusAvailable) {
          bonusClaimed = true;
          await economyManager.addTokens(bonusReward);
          await _prefs.setBool(keyBonusClaimed, true);
          notifyListeners();
          return true;
      }
      return false;
  }
}


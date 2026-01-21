import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Manages seasonal events, bonuses, and special content
class EventManager extends ChangeNotifier {
  late SharedPreferences _prefs;
  
  // Current active event
  SeasonalEvent? _activeEvent;
  SeasonalEvent? get activeEvent => _activeEvent;
  
  // Debug override
  static const String _debugEventKey = 'debug_force_event';
  String? _debugForcedEventId;
  
  // Event definitions
  static final List<SeasonalEvent> _events = [
    SeasonalEvent(
      id: 'halloween',
      name: 'Cadılar Bayramı',
      startMonth: 10, startDay: 25,
      endMonth: 11, endDay: 3,
      tokenMultiplier: 2.0,
      questRewardMultiplier: 3.0,
      themeId: 'theme_halloween',
      musicId: 'hallowen_event_bgm.mp3',
      iconEmoji: '🎃',
    ),
    SeasonalEvent(
      id: 'winter',
      name: 'Kış Kristalleri',
      startMonth: 12, startDay: 15,
      endMonth: 1, endDay: 5,
      tokenMultiplier: 2.0,
      questRewardMultiplier: 2.5,
      themeId: 'theme_winter',
      musicId: 'frozen_event_bgm.mp3',
      iconEmoji: '❄️',
    ),
    SeasonalEvent(
      id: 'summer',
      name: 'Yaz Festivali',
      startMonth: 6, startDay: 21,
      endMonth: 7, endDay: 10,
      tokenMultiplier: 1.5,
      questRewardMultiplier: 2.0,
      themeId: 'theme_summer',
      musicId: 'summer_event_bgm.mp3',
      iconEmoji: '☀️',
    ),
    SeasonalEvent(
      id: 'valentines',
      name: 'Sevgililer Günü',
      startMonth: 2, startDay: 10,
      endMonth: 2, endDay: 16,
      tokenMultiplier: 1.5,
      questRewardMultiplier: 2.0,
      themeId: 'theme_valentines',
      musicId: 'bgm_game_mid.mp3',
      iconEmoji: '💝',
    ),
  ];
  
  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
    
    // Check for debug forced event
    _debugForcedEventId = _prefs.getString(_debugEventKey);
    
    checkActiveEvent();
  }
  
  /// Force a specific event (for debugging)
  Future<void> debugForceEvent(String? eventId) async {
    if (eventId == null) {
      await _prefs.remove(_debugEventKey);
      _debugForcedEventId = null;
    } else {
      await _prefs.setString(_debugEventKey, eventId);
      _debugForcedEventId = eventId;
    }
    checkActiveEvent();
    print("EventManager: Debug forced event = $eventId");
  }
  
  /// Clear debug override
  Future<void> debugClearEvent() async {
    await _prefs.remove(_debugEventKey);
    _debugForcedEventId = null;
    checkActiveEvent();
  }
  
  /// Check if any event is currently active based on date OR debug override
  void checkActiveEvent() {
    // Check debug override first
    if (_debugForcedEventId != null) {
      final forcedEvent = _events.firstWhere(
        (e) => e.id == _debugForcedEventId,
        orElse: () => _events.first,
      );
      if (_events.any((e) => e.id == _debugForcedEventId)) {
        _activeEvent = forcedEvent;
        notifyListeners();
        print("EventManager: Using debug forced event: ${_activeEvent?.name}");
        return;
      }
    }
    
    final now = DateTime.now();
    
    for (final event in _events) {
      if (_isEventActive(event, now)) {
        _activeEvent = event;
        notifyListeners();
        return;
      }
    }
    
    _activeEvent = null;
    notifyListeners();
  }
  
  bool _isEventActive(SeasonalEvent event, DateTime now) {
    final currentMonth = now.month;
    final currentDay = now.day;
    
    // Handle year-wrap events (e.g., Dec 15 - Jan 5)
    if (event.endMonth < event.startMonth) {
      // Event spans across year boundary
      if (currentMonth == event.startMonth && currentDay >= event.startDay) return true;
      if (currentMonth > event.startMonth) return true;
      if (currentMonth < event.endMonth) return true;
      if (currentMonth == event.endMonth && currentDay <= event.endDay) return true;
    } else {
      // Normal event within same year
      if (currentMonth < event.startMonth || currentMonth > event.endMonth) return false;
      if (currentMonth == event.startMonth && currentDay < event.startDay) return false;
      if (currentMonth == event.endMonth && currentDay > event.endDay) return false;
      return true;
    }
    
    return false;
  }
  
  /// Get token multiplier (1.0 if no event)
  double get tokenMultiplier => _activeEvent?.tokenMultiplier ?? 1.0;
  
  /// Get quest reward multiplier (1.0 if no event)
  double get questRewardMultiplier => _activeEvent?.questRewardMultiplier ?? 1.0;
  
  /// Check if player has claimed event reward
  bool hasClaimedEventReward(String eventId) {
    return _prefs.getBool('event_claimed_$eventId') ?? false;
  }
  
  /// Claim event participation reward
  Future<void> claimEventReward(String eventId) async {
    await _prefs.setBool('event_claimed_$eventId', true);
  }
  
  /// Get event-specific missions
  List<EventMission> getEventMissions() {
    if (_activeEvent == null) return [];
    
    switch (_activeEvent!.id) {
      case 'halloween':
        return [
          EventMission(id: 'hw_1', title: 'Hayalet Avcısı', description: '10 seviye tamamla', target: 10, reward: 30),
          EventMission(id: 'hw_2', title: 'Balkabağı Ustası', description: '5 seviyeyi 3 yıldızla bitir', target: 5, reward: 50),
          EventMission(id: 'hw_3', title: 'Karanlık Yolcu', description: 'Gece 21:00-05:00 arası oyna', target: 3, reward: 25),
        ];
      case 'winter':
        return [
          EventMission(id: 'wt_1', title: 'Buz Kırıcı', description: '15 seviye tamamla', target: 15, reward: 40),
          EventMission(id: 'wt_2', title: 'Kar Tanesi', description: 'İpucu kullanmadan 10 seviye', target: 10, reward: 60),
          EventMission(id: 'wt_3', title: 'Kış Masalı', description: '3 yıldızlı 8 seviye tamamla', target: 8, reward: 45),
        ];
      case 'summer':
        return [
          EventMission(id: 'sm_1', title: 'Güneş Savaşçısı', description: '12 seviye tamamla', target: 12, reward: 35),
          EventMission(id: 'sm_2', title: 'Plaj Ustası', description: '20 seviyeyi geç', target: 20, reward: 55),
          EventMission(id: 'sm_3', title: 'Yaz Rüzgarı', description: 'Ardışık 5 gün oyna', target: 5, reward: 40),
        ];
      case 'valentines':
        return [
          EventMission(id: 'vt_1', title: 'Aşk Okları', description: '7 seviye tamamla', target: 7, reward: 25),
          EventMission(id: 'vt_2', title: 'Kalp Avcısı', description: '3 yıldızlı 5 seviye bitir', target: 5, reward: 40),
          EventMission(id: 'vt_3', title: 'Romantik Yolculuk', description: 'Toplam 15 seviye tamamla', target: 15, reward: 50),
        ];
      default:
        return [];
    }
  }
  
  /// Get progress for event mission
  int getMissionProgress(String missionId) {
    return _prefs.getInt('event_mission_$missionId') ?? 0;
  }
  
  /// Update mission progress
  Future<void> updateMissionProgress(String missionId, int progress) async {
    await _prefs.setInt('event_mission_$missionId', progress);
    notifyListeners();
  }
  
  /// Get days remaining for current event
  int get daysRemaining {
    if (_activeEvent == null) return 0;
    
    final now = DateTime.now();
    var endDate = DateTime(now.year, _activeEvent!.endMonth, _activeEvent!.endDay);
    
    // Handle year wrap
    if (_activeEvent!.endMonth < _activeEvent!.startMonth && now.month >= _activeEvent!.startMonth) {
      endDate = DateTime(now.year + 1, _activeEvent!.endMonth, _activeEvent!.endDay);
    }
    
    return endDate.difference(now).inDays;
  }
}

/// Seasonal Event Data
class SeasonalEvent {
  final String id;
  final String name;
  final int startMonth;
  final int startDay;
  final int endMonth;
  final int endDay;
  final double tokenMultiplier;
  final double questRewardMultiplier;
  final String themeId;
  final String musicId;
  final String iconEmoji;
  
  const SeasonalEvent({
    required this.id,
    required this.name,
    required this.startMonth,
    required this.startDay,
    required this.endMonth,
    required this.endDay,
    required this.tokenMultiplier,
    required this.questRewardMultiplier,
    required this.themeId,
    required this.musicId,
    required this.iconEmoji,
  });
}

/// Event Mission Data
class EventMission {
  final String id;
  final String title;
  final String description;
  final int target;
  final int reward;
  
  const EventMission({
    required this.id,
    required this.title,
    required this.description,
    required this.target,
    required this.reward,
  });
}

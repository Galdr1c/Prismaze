import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'localization_manager.dart';
import 'progress_manager.dart';
import 'settings_manager.dart';

// Assuming we would use flutter_local_notifications package in real implementation.
// Since I cannot install packages dynamically, this Manager will implement the ARCHITECTURE 
// and print to console / Update SharedPreferences to simulate "Scheduled" state.
// In a real device scenario, we would initialize the plugin here.

class NotificationManager {
  static final NotificationManager _instance = NotificationManager._internal();
  factory NotificationManager() => _instance;
  NotificationManager._internal();
  
  late SharedPreferences _prefs;
  bool _initialized = false;
  
  Future<void> init() async {
      if (_initialized) return;
      _prefs = await SharedPreferences.getInstance();
      print("NotificationManager: Initialized (Simulated)");
      _initialized = true;
      
      // Request permissions (Mock)
      _requestPermissions();
  }
  
  void _requestPermissions() {
      // Platform channel call would go here
      print("NotificationManager: Permission Requested -> Granted");
  }

  // --- SCHEDULING ---
  
  Future<void> scheduleRetentionNotifications() async {
      final sm = SettingsManager();
      await sm.init();
      
      // If notifications disabled, cancel all and return
      if (sm.notifMode == 'none') {
          await _cancelAll();
          return;
      }
      
      // If only events, don't schedule standard retention loop
      if (sm.notifMode == 'events') { // 'events' mode only schedules events, not retention
           await _cancelAll();
           // (Retention is considered "standard spam" usually)
           return;
      }
      
      await _cancelAll(); 
      final loc = LocalizationManager();
      final pm = ProgressManager();
      await pm.init();
      
      // SMART SCHEDULING
      // Calculate best hour for user
      final preferredHours = pm.getPreferredPlayHours();
      int targetHour = 20; // Default 8 PM
      if (preferredHours.isNotEmpty) targetHour = preferredHours.first;
      
      final now = DateTime.now();
      // Calculate delay to reach Target Hour tomorrow
      DateTime nextPlayParams = DateTime(now.year, now.month, now.day, targetHour);
      if (nextPlayParams.isBefore(now)) nextPlayParams = nextPlayParams.add(const Duration(days: 1));
      
      int secondsToNext = nextPlayParams.difference(now).inSeconds;
      if (secondsToNext < 7200) secondsToNext += 86400; // If too close/recent, push to next day? Or keep it.
      
      // 1. Smart Recall (Next Day at Preferred Hour)
      await _schedule(
          id: 1, 
          title: loc.getString('notif_1d_title'), 
          body: loc.getString('notif_1d_body'), 
          secondsFromNow: secondsToNext
      );
      
      // 2. 3 Day Free Gift (3 days later at preferred hour)
      await _schedule(
          id: 2, 
          title: loc.getString('notif_3d_title'), 
          body: loc.getString('notif_3d_body'), 
          secondsFromNow: secondsToNext + (2 * 86400)
      );
      
      // ... same for others
      
      print("NotificationManager: Smart Loop Scheduled (Target Hour: $targetHour)");
  }
  
  Future<void> scheduleEvent(String eventId, int secondsUsersLocal) async {
       final loc = LocalizationManager();
       String title = "Event";
       if (eventId == 'winter') title = loc.getString('notif_event_winter');
       if (eventId == 'skin') title = loc.getString('notif_skin_limited');
       
       await _schedule(
           id: 99, 
           title: title, 
           body: "Tap to view!", 
           secondsFromNow: secondsUsersLocal
       );
  }

  // --- CANCEL ---
  
  Future<void> cancelAll() async {
      await _cancelAll();
      print("NotificationManager: All Cancelled");
  }
  
  // --- INTERNAL MOCK IMPLEMENTATION ---
  
  Future<void> _schedule({
      required int id, 
      required String title, 
      required String body, 
      int secondsFromNow = 0, 
      String? payload
  }) async {
      final scheduledTime = DateTime.now().add(Duration(seconds: secondsFromNow));
      
      // In real app: plugin.schedule(...)
      print("🔔 SCHEDULED NOTIFICATION [ID:$id]");
      print("   Time: $scheduledTime");
      print("   Title: $title");
      print("   Body: $body");
      
      // Persist for debugging / validation
      await _prefs.setString('notif_sched_$id', scheduledTime.toIso8601String());
  }
  
  Future<void> _cancelAll() async {
      // In real app: plugin.cancelAll()
      // Just clear our mock keys
      final keys = _prefs.getKeys().where((k) => k.startsWith('notif_sched_'));
      for (final key in keys) {
          await _prefs.remove(key);
      }
  }
}

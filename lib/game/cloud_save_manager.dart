import 'package:games_services/games_services.dart';
import 'package:prismaze/game/services/platform_service.dart';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'progress_manager.dart';
import 'economy_manager.dart';
import 'network_manager.dart';

enum SyncResult { success, offline, conflict, error }

class CloudSaveManager {
  static const String keyPendingSave = 'cloud_pending_save';
  static const String keyLastCloudSave = 'cloud_last_save_timestamp';
  
  // Save progress safely
  Future<void> saveProgress(int totalStars, int maxLevel, int tokens) async {
      final prefs = await SharedPreferences.getInstance();
      
      final data = {
          'stars': totalStars,
          'maxLevel': maxLevel,
          'tokens': tokens,
          'timestamp': DateTime.now().millisecondsSinceEpoch
      };
      
      // Always save "Pendings" to local prefs first (Queue)
      await prefs.setString(keyPendingSave, jsonEncode(data));
      
      if (NetworkManager().isOnline) {
          await _performUpload(data);
      } else {
          print("Cloud: Offline. Added to upload queue.");
      }
  }
  
  Future<void> _performUpload(Map<String, dynamic> data) async {
      try {
           // Submit Score
           // Submit Score
           await PlatformService().submitScore(
              androidLeaderboardID: 'LB_STARS', 
              iOSLeaderboardID: 'LB_STARS', 
              score: data['stars']
           );
           
           // Snapshot logic (Stub)
           print("Cloud: Uploading snapshot... $data");
           // await GamesServices.saveSnapshot(name: 'progress', data: jsonEncode(data));
           
           // Clear pending on success
           final prefs = await SharedPreferences.getInstance();
           await prefs.remove(keyPendingSave);
           await prefs.setInt(keyLastCloudSave, DateTime.now().millisecondsSinceEpoch);
           
      } catch (e) {
          print("Cloud: Upload failed: $e");
      }
  }
  
  // Try to sync queue if online
  Future<void> retryPendingSaves() async {
      if (!NetworkManager().isOnline) return;
      
      final prefs = await SharedPreferences.getInstance();
      final pendingParams = prefs.getString(keyPendingSave);
      
      if (pendingParams != null) {
          print("Cloud: Retrying pending save...");
          final data = jsonDecode(pendingParams);
          await _performUpload(data);
      }
  }
  
  Future<void> deleteData() async {
      print("CloudSaveManager: Deleting Cloud Data...");
      await Future.delayed(const Duration(seconds: 1));
      // In real implementation: GamesServices.deleteSnapshot(...)
      print("CloudSaveManager: Cloud Data Deleted (Simulated).");
  }
  
  // Returns result to let UI know if conflict happened
  Future<SyncResult> syncProgress(ProgressManager progressManager, EconomyManager economyManager) async {
      if (!NetworkManager().isOnline) {
          print("Cloud: Offline. Skipping sync.");
          return SyncResult.offline;
      }

      try {
           print("Cloud: Syncing...");
           // await Future.delayed(const Duration(seconds: 1)); // Mock latency
           
           // Mock Load
           // final snapshot = await GamesServices.loadSnapshot(name: 'progress');
           // if (snapshot == null) return SyncResult.success;
           // final data = jsonDecode(snapshot.data);
           
           // MOCK CONFLICT DATA FOR TESTING (Uncomment to test conflict)
           /*
           final data = {
               'stars': 999,
               'maxLevel': 50,
               'timestamp': DateTime.now().millisecondsSinceEpoch + 10000 // Future
           };
           */
           
           // Real logic: Check timestamps or values
           // If Cloud data appears "Advanced" or "Different", return Conflict
           
           // Stub behavior:
           print("Cloud: Sync Complete (Stub).");
           return SyncResult.success;
           
      } catch (e) {
          print("Cloud: Sync Failed: $e");
          return SyncResult.error;
      }
  }
}

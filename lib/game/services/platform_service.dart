import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:games_services/games_services.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

class PlatformService {
  static final PlatformService _instance = PlatformService._internal();
  factory PlatformService() => _instance;
  PlatformService._internal();

  bool _isSignedIn = false;
  bool get isSignedIn => _isSignedIn;

  /// Initialize platform services (Sign In)
  Future<void> init() async {
    if (kIsWeb) return; // Not supported on web yet
    if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) return; // Mobile only for now

    // Skip sign-in if offline - prevents Google Play Games popup
    final connectivity = await Connectivity().checkConnectivity();
    if (connectivity.contains(ConnectivityResult.none)) {
      print("PlatformService: Offline, skipping sign in.");
      _isSignedIn = false;
      return;
    }

    try {
      print("PlatformService: Attempting sign in...");
      // Attempt silent sign-in first
      await GamesServices.signIn();
      _isSignedIn = true;
      print("PlatformService: Signed in successfully.");
    } catch (e) {
      // It's common to fail if user cancels or no network, or not configured.
      // We catch it to prevent app crash.
      print("PlatformService: Sign in failed (harmless if not configured): $e");
      _isSignedIn = false;
    }
  }

  /// Submit score safely
  Future<void> submitScore({required int score, required String androidLeaderboardID, required String iOSLeaderboardID}) async {
    if (!_isSignedIn) {
      print("PlatformService: Cannot submit score. Not signed in.");
      return;
    }

    try {
      await GamesServices.submitScore(
        score: Score(
          androidLeaderboardID: androidLeaderboardID,
          iOSLeaderboardID: iOSLeaderboardID,
          value: score,
        ),
      );
      print("PlatformService: Score submitted: $score");
    } catch (e) {
      print("PlatformService: Submit score failed: $e");
    }
  }

  /// Show Leaderboard safely
  Future<void> showLeaderboard({required String androidLeaderboardID, required String iOSLeaderboardID}) async {
    if (!_isSignedIn) {
      // Try to sign in again if user explicitly asks for leaderboard
      await init();
      if (!_isSignedIn) return;
    }

    try {
      await GamesServices.showLeaderboards(
        androidLeaderboardID: androidLeaderboardID,
        iOSLeaderboardID: iOSLeaderboardID,
      );
    } catch (e) {
      print("PlatformService: Show leaderboard failed: $e");
    }
  }
}


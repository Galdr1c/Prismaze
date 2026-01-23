import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'analytics_manager.dart';
import 'settings_manager.dart';

class AdManager extends ChangeNotifier {
  static const String keyDailyAdCount = 'daily_ad_count';
  static const String keyAdDate = 'ad_date';
  static const String keyRemoveAds = 'remove_ads';
  
  static const int maxDailyRewardedAds = 10;
  static const int interstitialInterval = 7;
  
  /// Check if we're on a mobile platform that supports ads
  bool get _isMobilePlatform {
    if (kIsWeb) return false;
    return defaultTargetPlatform == TargetPlatform.android ||
           defaultTargetPlatform == TargetPlatform.iOS;
  }
  
  /* Safe Test Ad Units */
  final String _rewardedAdUnitId = 'ca-app-pub-3940256099942544~3347511713'; // TEST ID
  final String _androidTestAdUnitId = 'ca-app-pub-3940256099942544/5224354917'; // Android Test
  final String _iosTestAdUnitId = 'ca-app-pub-3940256099942544/1712485313'; // iOS Test
  
  String get rewardedAdUnitId {
    if (defaultTargetPlatform == TargetPlatform.android) {
      return _androidTestAdUnitId;
    } else if (defaultTargetPlatform == TargetPlatform.iOS) {
      return _iosTestAdUnitId;
    }
    return _androidTestAdUnitId;
  }

  late SharedPreferences _prefs;
  AnalyticsManager? _analytics;
  
  int _dailyAdsWatched = 0;
  int _levelsSinceLastAd = 0;
  bool _isAdFree = false;
  
  // Rate Limiting
  final Map<String, DateTime> _lastAdWatchTime = {};
  static const Duration _adCooldown = Duration(minutes: 15); // Max 4 ads per hour approx

  RewardedAd? _rewardedAd;
  bool _isRewardedAdLoaded = false;
  bool _isLoadingAd = false;

  void setAnalytics(AnalyticsManager analytics) {
    _analytics = analytics;
  }

  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
    
    // Initialize Mobile Ads SDK (ONLY on mobile platforms)
    if (_isMobilePlatform) {
      try {
        await MobileAds.instance.initialize();
        debugPrint('AdManager: Mobile Ads SDK initialized');
      } catch (e) {
        debugPrint('AdManager: Failed to initialize Mobile Ads SDK: $e');
        // Continue without ads - don't block game loading
      }
    } else {
      debugPrint('AdManager: Skipping ads (non-mobile platform)');
    }

    _isAdFree = _prefs.getBool(keyRemoveAds) ?? false;
    
    // Check Date for Daily Cap Reset
    final savedDate = _prefs.getString(keyAdDate);
    final now = DateTime.now();
    final todayStr = "${now.year}-${now.month}-${now.day}";
    
    if (savedDate != todayStr) {
        _dailyAdsWatched = 0;
        await _prefs.setString(keyAdDate, todayStr);
        await _prefs.setInt(keyDailyAdCount, 0);
    } else {
        _dailyAdsWatched = _prefs.getInt(keyDailyAdCount) ?? 0;
    }

    if (!_isAdFree && _isMobilePlatform) {
        loadRewardedAd();
    }
  }

  Future<void> loadRewardedAd() async {
    if (_isLoadingAd || _isRewardedAdLoaded || _isAdFree) return;
    
    _isLoadingAd = true;
    notifyListeners();
    print("AdManager: Loading Rewarded Ad...");

    await RewardedAd.load(
        adUnitId: rewardedAdUnitId,
        request: const AdRequest(),
        rewardedAdLoadCallback: RewardedAdLoadCallback(
          onAdLoaded: (RewardedAd ad) {
            print('AdManager: Rewarded Ad Loaded: $ad');
            _rewardedAd = ad;
            _isRewardedAdLoaded = true;
            _isLoadingAd = false;
            notifyListeners();
          },
          onAdFailedToLoad: (LoadAdError error) {
            print('AdManager: Rewarded Ad failed to load: $error');
            _rewardedAd = null;
            _isRewardedAdLoaded = false;
            _isLoadingAd = false;
            notifyListeners();
          },
        ));
  }

  Future<bool> showRewardedAd(String placement) async {
    if (!_isMobilePlatform) return false; // Ads not supported on this platform
    if (_isAdFree) return true; // Ad-free users get rewards instantly? No, usually skip logic.

    if (!_isRewardedAdLoaded || _rewardedAd == null) {
      print("AdManager: Ad not ready. Loading one now...");
      await loadRewardedAd();
      if (!_isRewardedAdLoaded) return false;
    }

    if (_dailyAdsWatched >= maxDailyRewardedAds) {
      print("Daily Ad Limit Reached!");
      return false;
    }

    // Rate Limiting Check
    final now = DateTime.now();
    if (_lastAdWatchTime.containsKey(placement)) {
        final lastTime = _lastAdWatchTime[placement]!;
        if (now.difference(lastTime) < _adCooldown) {
             print("AdManager: Rate limit! Wait before watching '$placement' again.");
             return false;
        }
    }

    bool rewardEarned = false;
    
    await _rewardedAd!.show(
      onUserEarnedReward: (AdWithoutView ad, RewardItem reward) async {
        print('AdManager: User earned reward: ${reward.amount} ${reward.type}');
        
        bool verified = await _verifyAdCompletion(placement, reward);
        if (verified) {
           rewardEarned = true;
        } else {
           _handleAdFraud(placement);
        }
      });
      
    // Cleanup happens in callbacks usually, but here we wait for show() to complete
    _rewardedAd = null;
    _isRewardedAdLoaded = false;
    loadRewardedAd(); // Preload next
    
    if (rewardEarned) {
         _dailyAdsWatched++;
         await _prefs.setInt(keyDailyAdCount, _dailyAdsWatched);
         _lastAdWatchTime[placement] = now;
         
         bool track = !SettingsManager().adTrackingOptOut;
         if (track) {
           _analytics?.logAdImpression('rewarded', placement);
         }
    }

    return rewardEarned;
  }

  Future<bool> _verifyAdCompletion(String placement, RewardItem reward) async {
      // 1. Client-Side Basic Checks
      if (reward.amount <= 0) return false;
      
      // 2. Server-Side Verification Stub
      // In a real app, send a token to your server.
      try {
          // Simulate server check
          // final response = await http.post(...)
          // if (response.statusCode == 200) return true;
          await Future.delayed(const Duration(milliseconds: 500));
          return true; // Assume success for now
      } catch (e) {
          print("Ad Verification Error: $e");
          return true; // Fail open for network errors to not punish legitimate users
      }
  }

  void _handleAdFraud(String placement) {
      print("Fraud detected or Verification failed for $placement");
      // Log to analytics
  }
  
  // --- Stub for Interstitials (Not using real ads yet) ---
  Future<void> checkAndShowInterstitial(int levelId) async {
      // Keeping original mock logic for interstitials to not disrupt flow too much
      if (_isAdFree) return;
      _levelsSinceLastAd++;
      if (_levelsSinceLastAd >= interstitialInterval) {
           print("AdManager: Interstitial logic would run here.");
           _levelsSinceLastAd = 0;
           _analytics?.logAdImpression('interstitial', 'level_end');
      }
  }

  bool shouldShowBanner() => !_isAdFree;

  Future<void> setAdFree(bool enable) async {
      _isAdFree = enable;
      await _prefs.setBool(keyRemoveAds, enable);
      notifyListeners();
  }
}


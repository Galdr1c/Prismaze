import 'package:flutter/foundation.dart';

class AnalyticsManager {
  static final AnalyticsManager _instance = AnalyticsManager._internal();
  factory AnalyticsManager() => _instance;
  AnalyticsManager._internal();

  Future<void> init() async {
      debugPrint("[Analytics] Initialized");
  }

  Future<void> logEvent(String name, [Map<String, dynamic>? parameters]) async {
    debugPrint("[Analytics] Log Event: $name, Params: $parameters");
  }

  Future<void> logLevelStart(int levelId) async {
    await logEvent('level_start', {'level_id': levelId});
  }

  Future<void> logLevelComplete(int levelId, int stars, int moves, double duration, bool usedHint) async {
    await logEvent('level_complete', {
        'level_id': levelId, 
        'stars': stars,
        'moves': moves,
        'duration': duration,
        'used_hint': usedHint,
    });
  }

  Future<void> logAdImpression(String type, String placement) async {
      await logEvent('ad_impression', {'type': type, 'placement': placement});
  }

  Future<void> logIAP(String productId, double price, String currency) async {
      await logEvent('iap_purchase', {
          'product_id': productId,
          'price': price,
          'currency': currency
      });
  }
}

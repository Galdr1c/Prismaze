import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'economy_manager.dart';
import 'analytics_manager.dart';

class IAPManager extends ChangeNotifier {
  // Product IDs
  static const String pidHint50 = 'hint_pack_50';
  static const String pidHint150 = 'hint_pack_150';
  static const String pidHint500 = 'hint_pack_500';
  static const String pidHint1500 = 'hint_pack_1500';
  static const String pidNoAds = 'remove_ads';
  static const String pidUnlimitedHints = 'unlimited_hints_1mo';
  static const String pidFullGame = 'full_game_bundle';

  late SharedPreferences _prefs;
  AnalyticsManager? _analytics;
  final EconomyManager _economyManager;

  bool _isPurchasing = false;
  bool _isAvailable = true; // Would be false if store is unreachable

  bool get isPurchasing => _isPurchasing;
  bool get isAvailable => _isAvailable;

  IAPManager(this._economyManager);

  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
    // In a real app, initialize IAP connection here.
    // _isAvailable = await InAppPurchase.instance.isAvailable();
    print("IAPManager: Initialized.");
  }

  void setAnalytics(AnalyticsManager analytics) {
    _analytics = analytics;
  }

  /// Initiates a purchase for the given [productId].
  /// Returns existing purchased status or triggers logic.
  Future<void> purchaseProduct(String productId) async {
    if (_isPurchasing) return; // Prevent double-tap
    _isPurchasing = true;
    notifyListeners();

    try {
      print("[IAP] Purchase started: $productId");
      
      // Simulate Store Delay
      await Future.delayed(const Duration(seconds: 1));
      
      // Simulate Success/Failure handling
      // For now, always success in mock.
      bool success = true;

      // In real app, we would wait for stream updates.
      // Here we simulate immediate result.
      
      if (success) {
         await _verifyAndDeliver(productId);
         _analytics?.logIAP(productId, 0.99, 'USD'); // Mock price
      } else {
         throw Exception("User cancelled or store error");
      }

    } catch (e) {
      print("[IAP] Error: $e");
      rethrow; // Let UI handle error display
    } finally {
      _isPurchasing = false;
      notifyListeners();
    }
  }

  /// Restores previous purchases (Non-Consumables).
  Future<void> restorePurchases() async {
    if (_isPurchasing) return;
    _isPurchasing = true;
    notifyListeners();

    try {
      print("[IAP] Restore started...");
      await Future.delayed(const Duration(seconds: 1));
      
      // Stub: Check what was supposedly purchased
      // In real app: QueryPastPurchases()
      
      // Example: Restore NoAds if flag suggests we had it, or server says so.
      // For this stub, we don't have a real backend to query.
      // We'll just say "Restoration Complete" without changing mock state unless tracked.
      
      print("[IAP] Restore completed.");
    } catch (e) {
      print("[IAP] Restore failed: $e");
      rethrow;
    } finally {
      _isPurchasing = false;
      notifyListeners();
    }
  }

  /// Simulates receipt validation and delivery
  Future<void> _verifyAndDeliver(String productId) async {
     print("[IAP] Verifying receipt for $productId...");
     
     // 1. Validation (Mock)
     bool isValid = true; 
     
     if (!isValid) throw Exception("Receipt validation failed");

     // 2. Delivery
     await _deliverProduct(productId);
  }

  Future<void> _deliverProduct(String productId) async {
      switch (productId) {
           case pidHint50: await _economyManager.addHintsSecure(50, source: 'iap'); break;
           case pidHint150: await _economyManager.addHintsSecure(150, source: 'iap'); break;
           case pidHint500: await _economyManager.addHintsSecure(500, source: 'iap'); break;
           case pidHint1500: await _economyManager.addHintsSecure(1500, source: 'iap'); break;
           
           case pidNoAds:
               // Need to change AdManager state. 
               // Currently AdManager has setAdFree.
               // We might need to handle this via prefs or a callback since IAPManager 
               // doesn't hold AdManager reference directly yet.
               await _prefs.setBool('remove_ads', true); 
               // Note: AdManager needs to refresh or listen to this.
               break;

           case pidUnlimitedHints:
               final expiry = DateTime.now().add(const Duration(days: 30));
               await _prefs.setString('unlimited_hints_expiry', expiry.toIso8601String());
               break;
               
           case pidFullGame:
                await _economyManager.addHintsSecure(500, source: 'iap');
                await _prefs.setBool('remove_ads', true);
                break;
                
           default:
               print("Unknown product: $productId");
      }
      print("[IAP] Delivered: $productId");
  }
  
  bool hasUnlimitedHints() {
      final expiryStr = _prefs.getString('unlimited_hints_expiry');
      if (expiryStr == null) return false;
      final expiry = DateTime.parse(expiryStr);
      return DateTime.now().isBefore(expiry);
  }
}


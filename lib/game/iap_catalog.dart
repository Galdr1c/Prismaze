import 'package:flutter/material.dart';

/// IAP Product types
enum ProductType {
  consumable,    // Tokens, one-time use
  nonConsumable, // Skins, permanent unlock
  subscription,  // Monthly/yearly
  bundle,        // Package of multiple items
}

/// Product definition for IAP
class IAPProduct {
  final String id;
  final String name;
  final String description;
  final double price;
  final double? originalPriceValue; // Original price before discount
  final String currency;
  final ProductType type;
  final List<String> contents; // What's included
  final int? savings; // % savings shown
  final String? badge; // "En İyi Değer!" etc.
  final bool isLimited; // Seasonal/time-limited
  final DateTime? expiresAt;
  
  const IAPProduct({
    required this.id,
    required this.name,
    required this.description,
    required this.price,
    this.originalPriceValue,
    this.currency = 'USD',
    required this.type,
    this.contents = const [],
    this.savings,
    this.badge,
    this.isLimited = false,
    this.expiresAt,
  });
  
  String get formattedPrice => '\$${price.toStringAsFixed(2)}';
  
  String? get originalPrice => originalPriceValue != null 
      ? '\$${originalPriceValue!.toStringAsFixed(2)}' 
      : null;
  
  String get badgeOrSavings {
    if (badge != null) return badge!; // Now returning key
    if (savings != null) return 'badge_save_percent'; // Key for savings
    return '';
  }
}

/// IAP Catalog - All available products
class IAPCatalog {
  
  // === HINT PACKS ===
  static const hintSmall = IAPProduct(
    id: 'hint_pack_50',
    name: 'prod_name_hint_50',
    description: 'prod_desc_hint_50',
    price: 0.99,
    type: ProductType.consumable,
    contents: ['cont_50_tokens'],
  );
  
  static const hintMedium = IAPProduct(
    id: 'hint_pack_150',
    name: 'prod_name_hint_150',
    description: 'prod_desc_hint_150',
    price: 2.49,
    originalPriceValue: 2.99,
    type: ProductType.consumable,
    contents: ['cont_150_tokens'],
    savings: 15,
  );
  
  static const hintLarge = IAPProduct(
    id: 'hint_pack_500',
    name: 'prod_name_hint_500',
    description: 'prod_desc_hint_500',
    price: 6.99,
    originalPriceValue: 9.99,
    type: ProductType.consumable,
    contents: ['cont_500_tokens'],
    savings: 30,
  );
  
  static const hintMega = IAPProduct(
    id: 'hint_pack_1500',
    name: 'prod_name_hint_1500',
    description: 'prod_desc_hint_1500',
    price: 14.99,
    originalPriceValue: 29.99,
    type: ProductType.consumable,
    contents: ['cont_1500_tokens'],
    savings: 50,
    badge: 'badge_popular',
  );
  
  // === BUNDLES ===
  static const starterPack = IAPProduct(
    id: 'bundle_starter',
    name: 'prod_name_starter',
    description: 'prod_desc_starter',
    price: 4.99,
    originalPriceValue: 12.49,
    type: ProductType.bundle,
    contents: [
      'cont_200_tokens',
      'cont_3_skins',
      'cont_no_ads_1w',
    ],
    savings: 60,
    badge: 'badge_starter',
  );
  
  static const fullBundle = IAPProduct(
    id: 'bundle_full',
    name: 'prod_name_full',
    description: 'prod_desc_full',
    price: 19.99,
    type: ProductType.bundle,
    contents: [
      'cont_unlimited_hints',
      'cont_all_skins',
      'cont_no_ads_forever',
      'cont_dlc_discount',
    ],
    badge: 'badge_best_value',
  );
  
  // === SUBSCRIPTIONS ===
  static const monthlyPremium = IAPProduct(
    id: 'sub_monthly',
    name: 'prod_name_monthly',
    description: 'prod_desc_monthly',
    price: 2.99,
    type: ProductType.subscription,
    contents: [
      'cont_daily_10',
      'cont_no_ads_exp',
      'cont_badge_sub',
      'cont_early_access',
    ],
  );
  
  static const yearlyPremium = IAPProduct(
    id: 'sub_yearly',
    name: 'prod_name_yearly',
    description: 'prod_desc_yearly',
    price: 29.99,
    originalPriceValue: 35.99,
    type: ProductType.subscription,
    contents: [
      'cont_daily_10',
      'cont_no_ads_exp',
      'cont_badge_gold',
      'cont_early_access',
      'cont_skin_yearly',
    ],
    savings: 17,
    badge: 'badge_2_months_free',
  );
  
  // === SEASONAL PACKS ===
  static IAPProduct winterPack = IAPProduct(
    id: 'seasonal_winter',
    name: 'prod_name_winter',
    description: 'prod_desc_winter',
    price: 6.99,
    originalPriceValue: 9.99,
    type: ProductType.bundle,
    contents: [
      'cont_5_skins_winter',
      'cont_300_tokens',
      'cont_effect_snow',
    ],
    isLimited: true,
    savings: 30,
    badge: 'badge_limited',
  );
  
  static IAPProduct summerPack = IAPProduct(
    id: 'seasonal_summer',
    name: 'prod_name_summer',
    description: 'prod_desc_summer',
    price: 6.99,
    originalPriceValue: 9.99,
    type: ProductType.bundle,
    contents: [
      'cont_5_skins_summer',
      'cont_300_tokens',
      'cont_effect_sun',
    ],
    isLimited: true,
    savings: 30,
    badge: 'badge_limited',
  );
  
  static IAPProduct halloweenPack = IAPProduct(
    id: 'seasonal_halloween',
    name: 'prod_name_halloween',
    description: 'prod_desc_halloween',
    price: 6.99,
    originalPriceValue: 9.99,
    type: ProductType.bundle,
    contents: [
      'cont_skins_halloween',
      'cont_300_tokens',
      'cont_theme_halloween',
    ],
    isLimited: true,
    savings: 30,
    badge: 'badge_limited',
  );
  
  static IAPProduct valentinesPack = IAPProduct(
    id: 'seasonal_valentines',
    name: 'prod_name_valentines',
    description: 'prod_desc_valentines',
    price: 5.99,
    originalPriceValue: 8.99,
    type: ProductType.bundle,
    contents: [
      'cont_skins_valentines',
      'cont_200_tokens',
      'cont_effect_hearts',
    ],
    isLimited: true,
    savings: 35,
    badge: 'badge_limited',
  );
  
  // === REMOVE ADS ===
  static const removeAds = IAPProduct(
    id: 'remove_ads',
    name: 'prod_name_remove_ads',
    description: 'prod_desc_remove_ads',
    price: 3.99,
    type: ProductType.nonConsumable,
    contents: ['cont_remove_all_ads'],
  );
  
  // === ALL PRODUCTS LIST ===
  static List<IAPProduct> get allProducts => [
    hintSmall,
    hintMedium,
    hintLarge,
    hintMega,
    starterPack,
    fullBundle,
    monthlyPremium,
    yearlyPremium,
    monthlyPremium,
    yearlyPremium,
    winterPack,
    summerPack,
    halloweenPack,
    valentinesPack,
    removeAds,
  ];
  
  static List<IAPProduct> get hintProducts => allProducts.where((p) => p.type == ProductType.consumable).toList();
  static List<IAPProduct> get bundleProducts => allProducts.where((p) => p.type == ProductType.bundle).toList();
  static List<IAPProduct> get subscriptionProducts => allProducts.where((p) => p.type == ProductType.subscription).toList();
  static List<IAPProduct> get seasonalProducts => allProducts.where((p) => p.isLimited).toList();
  
  static IAPProduct? getById(String id) {
    try {
      return allProducts.firstWhere((p) => p.id == id);
    } catch (_) {
      return null;
    }
  }
}

/// Store UI Helper
class StoreUtils {
  
  /// Get color for bundle badge
  static Color getBadgeColor(IAPProduct product) {
    if (product.badge == 'badge_best_value') return Colors.amber;
    if (product.badge == 'badge_popular') return Colors.purpleAccent;
    if (product.isLimited) return Colors.redAccent;
    if (product.savings != null && product.savings! >= 50) return Colors.greenAccent;
    return Colors.cyanAccent;
  }
  
  /// Format subscription period
  static String formatSubscriptionPeriod(IAPProduct product) {
    if (product.id.contains('monthly')) return '/ay';
    if (product.id.contains('yearly')) return '/yıl';
    return '';
  }
  
  /// Format event countdown timer
  static String formatEventTimer(Duration duration) {
    if (duration.inSeconds <= 0) return "00:00:00";
    
    final days = duration.inDays;
    final hours = duration.inHours % 24;
    final minutes = duration.inMinutes % 60;
    final seconds = duration.inSeconds % 60;
    
    if (days > 0) {
      return '${days}g ${hours}s';
    } else {
      // < 24h: Show HH:MM:SS format
      final h = hours.toString().padLeft(2, '0');
      final m = minutes.toString().padLeft(2, '0');
      final s = seconds.toString().padLeft(2, '0');
      return '$h:$m:$s';
    }
  }
}


import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart';
import 'progress_manager.dart';

enum ItemType { prismSkin, lightEffect, backgroundTheme }

/// Rarity levels for collectibles
enum ItemRarity { 
  common,    // Easy to get (daily rewards, level completion)
  rare,      // Moderate effort (achievements, events)
  epic,      // Hard to get (100% chapter completion)
  legendary, // Very rare (special events, IAP exclusive)
}

class GameItem {
  final String id;
  final ItemType type;
  final String name;
  final String description;
  final ItemRarity rarity;
  final int requiredStars;
  final bool isIAP;
  final String? productId;
  final bool isEventExclusive;
  final String? eventId;

  const GameItem({
    required this.id,
    required this.type,
    required this.name,
    this.description = '',
    this.rarity = ItemRarity.common,
    this.requiredStars = 0,
    this.isIAP = false,
    this.productId,
    this.isEventExclusive = false,
    this.eventId,
  });
}

class CustomizationManager extends ChangeNotifier {
  static const String keySelectedSkin = 'selected_skin';
  static const String keySelectedEffect = 'selected_effect';
  static const String keySelectedTheme = 'selected_theme';
  static const String keyUnlockedItems = 'unlocked_items';

  late SharedPreferences _prefs;
  final ProgressManager progressManager;

  // =============== FULL CATALOG WITH RARITY ===============
  final List<GameItem> catalog = [
    // ============= PRISM SKINS (50+) =============
    // COMMON (20) - Easy to get
    GameItem(id: 'skin_crystal', type: ItemType.prismSkin, name: 'Kristal Cam', rarity: ItemRarity.common, description: 'Varsayılan'),
    GameItem(id: 'skin_ice', type: ItemType.prismSkin, name: 'Buzlu Cam', rarity: ItemRarity.common),
    GameItem(id: 'skin_emerald', type: ItemType.prismSkin, name: 'Yeşil Zümrüt', rarity: ItemRarity.common),
    GameItem(id: 'skin_ruby', type: ItemType.prismSkin, name: 'Yakut', rarity: ItemRarity.common),
    GameItem(id: 'skin_sapphire', type: ItemType.prismSkin, name: 'Safir', rarity: ItemRarity.common),
    GameItem(id: 'skin_amber', type: ItemType.prismSkin, name: 'Kehribar', rarity: ItemRarity.common),
    GameItem(id: 'skin_jade', type: ItemType.prismSkin, name: 'Yeşim', rarity: ItemRarity.common),
    GameItem(id: 'skin_obsidian', type: ItemType.prismSkin, name: 'Obsidyen', rarity: ItemRarity.common),
    GameItem(id: 'skin_quartz', type: ItemType.prismSkin, name: 'Kuvars', rarity: ItemRarity.common),
    GameItem(id: 'skin_pearl', type: ItemType.prismSkin, name: 'İnci', rarity: ItemRarity.common),
    GameItem(id: 'skin_topaz', type: ItemType.prismSkin, name: 'Topaz', rarity: ItemRarity.common),
    GameItem(id: 'skin_amethyst', type: ItemType.prismSkin, name: 'Ametist', rarity: ItemRarity.common),
    GameItem(id: 'skin_bronze', type: ItemType.prismSkin, name: 'Bronz', rarity: ItemRarity.common, requiredStars: 10),
    GameItem(id: 'skin_silver', type: ItemType.prismSkin, name: 'Gümüş', rarity: ItemRarity.common, requiredStars: 25),
    GameItem(id: 'skin_marble', type: ItemType.prismSkin, name: 'Mermer', rarity: ItemRarity.common, requiredStars: 40),
    GameItem(id: 'skin_glass', type: ItemType.prismSkin, name: 'Cam', rarity: ItemRarity.common),
    GameItem(id: 'skin_opal', type: ItemType.prismSkin, name: 'Opal', rarity: ItemRarity.common),
    GameItem(id: 'skin_turquoise', type: ItemType.prismSkin, name: 'Turkuaz', rarity: ItemRarity.common),
    
    // RARE (15) - Moderate effort
    GameItem(id: 'skin_gold', type: ItemType.prismSkin, name: 'Altın Prizma', rarity: ItemRarity.rare, requiredStars: 50),
    GameItem(id: 'skin_neon', type: ItemType.prismSkin, name: 'Neon', rarity: ItemRarity.rare, requiredStars: 75),
    GameItem(id: 'skin_holographic', type: ItemType.prismSkin, name: 'Holografik', rarity: ItemRarity.rare, requiredStars: 100),
    GameItem(id: 'skin_diamond', type: ItemType.prismSkin, name: 'Elmas Prizma', rarity: ItemRarity.rare, requiredStars: 150),
    GameItem(id: 'skin_aurora', type: ItemType.prismSkin, name: 'Aurora', rarity: ItemRarity.rare, requiredStars: 125),
    GameItem(id: 'skin_sunset', type: ItemType.prismSkin, name: 'Gün Batımı', rarity: ItemRarity.rare, requiredStars: 175),
    GameItem(id: 'skin_midnight', type: ItemType.prismSkin, name: 'Gece Yarısı', rarity: ItemRarity.rare, requiredStars: 200),
    GameItem(id: 'skin_forest', type: ItemType.prismSkin, name: 'Orman', rarity: ItemRarity.rare, requiredStars: 225),
    GameItem(id: 'skin_ocean', type: ItemType.prismSkin, name: 'Okyanus Derinliği', rarity: ItemRarity.rare, requiredStars: 250),
    GameItem(id: 'skin_pumpkin', type: ItemType.prismSkin, name: 'Balkabağı', rarity: ItemRarity.rare, isEventExclusive: true, eventId: 'halloween'),
    GameItem(id: 'skin_heart', type: ItemType.prismSkin, name: 'Kalp', rarity: ItemRarity.rare, isEventExclusive: true, eventId: 'valentines'),
    
    // EPIC (10) - Hard to get
    GameItem(id: 'skin_rainbow', type: ItemType.prismSkin, name: 'Gökkuşağı Prizma', rarity: ItemRarity.epic, requiredStars: 350),
    GameItem(id: 'skin_plasma', type: ItemType.prismSkin, name: 'Plazma Prizma', rarity: ItemRarity.epic, requiredStars: 400),
    GameItem(id: 'skin_phoenix', type: ItemType.prismSkin, name: 'Anka Kuşu', rarity: ItemRarity.epic, requiredStars: 500),
    GameItem(id: 'skin_dragon', type: ItemType.prismSkin, name: 'Ejderha', rarity: ItemRarity.epic, requiredStars: 550),
    GameItem(id: 'skin_galactic', type: ItemType.prismSkin, name: 'Galaktik', rarity: ItemRarity.epic, requiredStars: 600),
    GameItem(id: 'skin_blizzard', type: ItemType.prismSkin, name: 'Kar Fırtınası', rarity: ItemRarity.epic, isEventExclusive: true, eventId: 'winter'),
    GameItem(id: 'skin_ghost', type: ItemType.prismSkin, name: 'Hayalet', rarity: ItemRarity.epic, isEventExclusive: true, eventId: 'halloween'),
    
    // LEGENDARY (5) - Very rare
    GameItem(id: 'skin_blackhole', type: ItemType.prismSkin, name: 'Kara Delik', rarity: ItemRarity.legendary, isIAP: true, productId: 'iap_skin_blackhole'),
    GameItem(id: 'skin_dimension', type: ItemType.prismSkin, name: 'Boyut Geçidi', rarity: ItemRarity.legendary, requiredStars: 900),
    GameItem(id: 'skin_infinity', type: ItemType.prismSkin, name: 'Sonsuzluk', rarity: ItemRarity.legendary, isIAP: true, productId: 'iap_skin_infinity'),
    GameItem(id: 'skin_creator', type: ItemType.prismSkin, name: 'Yaratıcı', rarity: ItemRarity.legendary, description: '%100 tamamlama'),
    
    // ============= LIGHT EFFECTS (8+) =============
    GameItem(id: 'effect_classic', type: ItemType.lightEffect, name: 'Klasik Işın', rarity: ItemRarity.common),
    GameItem(id: 'effect_dotted', type: ItemType.lightEffect, name: 'Noktalı Işın', rarity: ItemRarity.common),
    GameItem(id: 'effect_glitter', type: ItemType.lightEffect, name: 'Parıltılı Işın', rarity: ItemRarity.rare, requiredStars: 100),
    GameItem(id: 'effect_rainbow', type: ItemType.lightEffect, name: 'Gökkuşağı Işın', rarity: ItemRarity.rare, requiredStars: 200),
    GameItem(id: 'effect_pulse', type: ItemType.lightEffect, name: 'Nabız', rarity: ItemRarity.epic, requiredStars: 300),
    GameItem(id: 'effect_daily_special', type: ItemType.lightEffect, name: 'Özel Parıltı', rarity: ItemRarity.rare, description: 'Günlük ödül (Gün 6)'),
    GameItem(id: 'effect_snow', type: ItemType.lightEffect, name: 'Kar Tanesi', rarity: ItemRarity.epic, isEventExclusive: true, eventId: 'winter'),
    GameItem(id: 'effect_fire', type: ItemType.lightEffect, name: 'Ateş', rarity: ItemRarity.epic, isEventExclusive: true, eventId: 'halloween'),
    
    // ============= BACKGROUNDS (12+) =============
    GameItem(id: 'theme_space', type: ItemType.backgroundTheme, name: 'Uzay Boşluğu', rarity: ItemRarity.common),
    GameItem(id: 'theme_neon', type: ItemType.backgroundTheme, name: 'Neon Şehir', rarity: ItemRarity.common),
    GameItem(id: 'theme_ocean', type: ItemType.backgroundTheme, name: 'Okyanus', rarity: ItemRarity.common),
    GameItem(id: 'theme_forest', type: ItemType.backgroundTheme, name: 'Orman', rarity: ItemRarity.rare, requiredStars: 150),
    GameItem(id: 'theme_desert', type: ItemType.backgroundTheme, name: 'Çöl', rarity: ItemRarity.rare, requiredStars: 200),
    GameItem(id: 'theme_mountain', type: ItemType.backgroundTheme, name: 'Dağ', rarity: ItemRarity.rare, requiredStars: 250),
    GameItem(id: 'theme_galaxy', type: ItemType.backgroundTheme, name: 'Galaksi', rarity: ItemRarity.epic, requiredStars: 400),
    GameItem(id: 'theme_daily_exclusive', type: ItemType.backgroundTheme, name: 'Özel Arka Plan', rarity: ItemRarity.epic, description: 'Günlük ödül (Gün 7)'),
    GameItem(id: 'theme_winter', type: ItemType.backgroundTheme, name: 'Kış Masalı', rarity: ItemRarity.epic, isEventExclusive: true, eventId: 'winter'),
    GameItem(id: 'theme_halloween', type: ItemType.backgroundTheme, name: 'Cadılar Bayramı', rarity: ItemRarity.epic, isEventExclusive: true, eventId: 'halloween'),
    GameItem(id: 'theme_summer', type: ItemType.backgroundTheme, name: 'Yaz Günü', rarity: ItemRarity.epic, isEventExclusive: true, eventId: 'summer'),
    GameItem(id: 'theme_abyss', type: ItemType.backgroundTheme, name: 'Abyss', rarity: ItemRarity.legendary, isIAP: true, productId: 'iap_theme_abyss'),
  ];

  // State
  String _selectedSkin = 'skin_crystal';
  String _selectedEffect = 'effect_classic';
  String _selectedTheme = 'theme_space';
  final Set<String> _unlockedIds = {
    'skin_crystal', 'skin_ice', 'skin_emerald',
    'effect_classic', 'effect_dotted',
    'theme_space', 'theme_neon', 'theme_ocean'
  };

  String get selectedSkin => _selectedSkin;
  String get selectedEffect => _selectedEffect;
  String get selectedTheme => _selectedTheme;

  CustomizationManager(this.progressManager);

  // =============== COLLECTION PROGRESS ===============
  
  /// Get total items in catalog by type
  int getTotalByType(ItemType type) => catalog.where((i) => i.type == type).length;
  
  /// Get unlocked items by type
  int getUnlockedByType(ItemType type) {
    return catalog.where((i) => i.type == type && isUnlocked(i.id)).length;
  }
  
  /// Get collection completion percentage (0-100)
  double get collectionCompletion {
    int total = catalog.length;
    int unlocked = catalog.where((i) => isUnlocked(i.id)).length;
    return (unlocked / total) * 100;
  }
  
  /// Get completion by rarity
  Map<ItemRarity, double> getCompletionByRarity() {
    Map<ItemRarity, double> result = {};
    for (var rarity in ItemRarity.values) {
      int total = catalog.where((i) => i.rarity == rarity).length;
      int unlocked = catalog.where((i) => i.rarity == rarity && isUnlocked(i.id)).length;
      result[rarity] = total > 0 ? (unlocked / total) * 100 : 0;
    }
    return result;
  }
  
  /// Get items by rarity
  List<GameItem> getItemsByRarity(ItemRarity rarity) {
    return catalog.where((i) => i.rarity == rarity).toList();
  }
  
  /// Get items by type
  List<GameItem> getItemsByType(ItemType type) {
    return catalog.where((i) => i.type == type).toList();
  }
  
  /// Get rarity color
  static int getRarityColor(ItemRarity rarity) {
    switch (rarity) {
      case ItemRarity.common: return 0xFF9E9E9E;    // Grey
      case ItemRarity.rare: return 0xFF2196F3;      // Blue
      case ItemRarity.epic: return 0xFF9C27B0;      // Purple
      case ItemRarity.legendary: return 0xFFFFD700; // Gold
    }
  }
  
  /// Get rarity name
  static String getRarityName(ItemRarity rarity) {
    switch (rarity) {
      case ItemRarity.common: return 'Sıradan';
      case ItemRarity.rare: return 'Nadir';
      case ItemRarity.epic: return 'Epik';
      case ItemRarity.legendary: return 'Efsanevi';
    }
  }

  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
    _selectedSkin = _prefs.getString(keySelectedSkin) ?? 'skin_crystal';
    _selectedEffect = _prefs.getString(keySelectedEffect) ?? 'effect_classic';
    _selectedTheme = _prefs.getString(keySelectedTheme) ?? 'theme_space';
    
    final unlockedList = _prefs.getStringList(keyUnlockedItems);
    if (unlockedList != null) {
      _unlockedIds.addAll(unlockedList);
    }
  }

  bool isUnlocked(String id) {
    if (_unlockedIds.contains(id)) return true;
    
    // Check dynamic unlocks (Stars)
    final item = catalog.firstWhere((e) => e.id == id, orElse: () => const GameItem(id: '', type: ItemType.prismSkin, name: ''));
    if (item.id.isNotEmpty && !item.isIAP && item.requiredStars > 0) {
       if (progressManager.totalStars >= item.requiredStars) {
           _unlock(id);
           return true; 
       }
    }
    return false;
  }

  Future<void> unlockSkin(String id) async {
      if (!_unlockedIds.contains(id)) {
          await _unlock(id);
      }
  }

  Future<void> _unlock(String id) async {
    _unlockedIds.add(id);
    await _prefs.setStringList(keyUnlockedItems, _unlockedIds.toList());
    notifyListeners();
  }
  
  Future<void> selectItem(String id) async {
    if (!isUnlocked(id)) return;
    
    final item = catalog.firstWhere((e) => e.id == id);
    switch (item.type) {
      case ItemType.prismSkin:
        _selectedSkin = id;
        await _prefs.setString(keySelectedSkin, id);
        break;
      case ItemType.lightEffect:
        _selectedEffect = id;
        await _prefs.setString(keySelectedEffect, id);
        break;
      case ItemType.backgroundTheme:
        _selectedTheme = id;
        await _prefs.setString(keySelectedTheme, id);
        break;
    }
    notifyListeners();
  }
  
  Future<void> resetData() async {
      _unlockedIds.clear();
      _selectedSkin = 'skin_crystal';
      _selectedEffect = 'effect_classic';
      _selectedTheme = 'theme_space';
      
      _unlockedIds.addAll({
        'skin_crystal', 'skin_ice', 'skin_emerald',
        'effect_classic', 'effect_dotted',
        'theme_space', 'theme_neon', 'theme_ocean' 
      });
      
      await _prefs.remove(keySelectedSkin);
      await _prefs.remove(keySelectedEffect);
      await _prefs.remove(keySelectedTheme);
      await _prefs.remove(keyUnlockedItems);
      notifyListeners();
  }
}

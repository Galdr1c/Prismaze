import 'package:flutter/material.dart';
import '../game/iap_catalog.dart';
import '../game/economy_manager.dart';
import '../game/iap_manager.dart';
import '../game/event_manager.dart'; // Added
import '../game/audio_manager.dart';
import 'dart:async'; // Added for Timer
import 'package:google_fonts/google_fonts.dart';
import '../game/localization_manager.dart';
import 'components/styled_back_button.dart';
import '../widgets/cute_menu_button.dart';

/// In-App Purchase Store Screen
class StoreScreen extends StatefulWidget {
  final IAPManager iapManager;
  
  const StoreScreen({super.key, required this.iapManager});

  @override
  State<StoreScreen> createState() => _StoreScreenState();
}

class _StoreScreenState extends State<StoreScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late EventManager _eventManager;
  Timer? _timer;
  
  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    
    _eventManager = EventManager();
    _eventManager.init().then((_) {
      if (mounted) setState(() {});
    });
    
    // Start timer for countdown
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) setState(() {});
    });
  }
  
  @override
  void dispose() {
    _timer?.cancel();
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // ... no change to build ...
    final loc = LocalizationManager();
    return Scaffold(
      backgroundColor: const Color(0xFF0D0D1A),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(loc.getString('store_title'), style: GoogleFonts.dynaPuff(fontWeight: FontWeight.bold)),
        leadingWidth: 100,
        leading: Padding(
          padding: const EdgeInsets.only(left: 8, top: 8, bottom: 8),
          child: StyledBackButton(),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.restore, color: Colors.white54),
            tooltip: loc.getString('btn_restore'),
            onPressed: _restorePurchases,
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.cyanAccent,
          labelColor: Colors.cyanAccent,
          unselectedLabelColor: Colors.white54,
          labelStyle: GoogleFonts.dynaPuff(fontWeight: FontWeight.bold),
          unselectedLabelStyle: GoogleFonts.dynaPuff(),
          tabs: [
            Tab(text: loc.getString('store_tab_bundles')),
            Tab(text: loc.getString('store_tab_tokens')),
            Tab(text: loc.getString('store_tab_premium')),
            Tab(text: loc.getString('store_tab_seasonal')),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildBundlesTab(),
          _buildTokensTab(), // Now displays Hints
          _buildSubscriptionTab(),
          _buildSeasonalTab(),
        ],
      ),
    );
  }

  Future<void> _restorePurchases() async {
      if (widget.iapManager.isPurchasing) return;
      
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) => const Center(child: CircularProgressIndicator()),
      );
      
      try {
          await widget.iapManager.restorePurchases();
          if (mounted) {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                      content: Text(LocalizationManager().getString('msg_restore_success'), style: GoogleFonts.dynaPuff()),
                      backgroundColor: Colors.green,
                  ),
              );
          }
      } catch (e) {
          if (mounted) {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                      content: Text(LocalizationManager().getString('msg_restore_fail'), style: GoogleFonts.dynaPuff()),
                      backgroundColor: Colors.red,
                  ),
              );
          }
      }
  }

  // ... rest of build helper methods ...
  
  Widget _buildBundlesTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(8),
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          _buildProductCard(IAPCatalog.starterPack, featured: true),
          _buildProductCard(IAPCatalog.fullBundle, featured: true),
          _buildProductCard(IAPCatalog.removeAds),
        ],
      ),
    );
  }
  
  Widget _buildTokensTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(8),
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: IAPCatalog.hintProducts.map((p) => _buildProductCard(p)).toList(),
      ),
    );
  }
  
  Widget _buildSubscriptionTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(8),
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          _buildProductCard(IAPCatalog.monthlyPremium, isSubscription: true),
          _buildProductCard(IAPCatalog.yearlyPremium, isSubscription: true, featured: true),
        ],
      ),
    );
  }
  
  Widget _buildSeasonalTab() {
    final activeEventId = _eventManager.activeEvent?.id;
    
    // Filter products: Only show if they match the active event ID
    final seasonalProducts = IAPCatalog.seasonalProducts.where((p) {
      if (activeEventId == null) return false;
      return p.id.contains(activeEventId);
    }).toList();
    
    if (seasonalProducts.isEmpty) {
      return Center(
        child: Text(
          LocalizationManager().getString('store_seasonal_empty'),
          textAlign: TextAlign.center,
          style: GoogleFonts.dynaPuff(color: Colors.white54),
        ),
      );
    }
    
    return SingleChildScrollView(
      padding: const EdgeInsets.all(8),
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: seasonalProducts.map((p) => _buildProductCard(p, isLimited: true)).toList(),
      ),
    );
  }
  
  Widget _buildProductCard(IAPProduct product, {
    bool featured = false,
    bool isSubscription = false,
    bool isLimited = false,
  }) {
    final badgeColor = StoreUtils.getBadgeColor(product);
    final loc = LocalizationManager();
    final isCyanTheme = !featured; // Cyan for normal, Purple for featured
    
    return LayoutBuilder(
      builder: (context, constraints) {
        final screenWidth = MediaQuery.of(context).size.width;
        final cardWidth = (screenWidth - 8 * 4) / 2; 
        
        return ConstrainedBox(
          constraints: BoxConstraints(
            minWidth: cardWidth,
            maxWidth: cardWidth,
            minHeight: featured ? 230 : 190, 
          ),
          child: GestureDetector(
            onTap: () => _purchaseProduct(product),
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: featured 
                    ? [const Color(0xFF4A148C).withOpacity(0.8), const Color(0xFF2A0A4E).withOpacity(0.9)] 
                    : [const Color(0xFF1A1A2E).withOpacity(0.8), const Color(0xFF0D0D1A).withOpacity(0.9)],
                ),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: featured ? Colors.purpleAccent.withOpacity(0.6) : Colors.cyanAccent.withOpacity(0.3),
                  width: featured ? 2 : 1,
                ),
                boxShadow: [
                  BoxShadow(
                    color: featured ? Colors.purpleAccent.withOpacity(0.15) : Colors.cyanAccent.withOpacity(0.05),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Stack(
                children: [
                  // Card Content
                   Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Title row with inline badge
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Text(
                                loc.getString(product.name),
                                style: GoogleFonts.dynaPuff(
                                  color: Colors.white,
                                  fontSize: featured ? 14 : 12,
                                  fontWeight: FontWeight.w700,
                                  height: 1.1,
                                ),
                              ),
                            ),
                            // Inline badge (savings/featured)
                            if (product.badgeOrSavings.isNotEmpty) ...[
                              const SizedBox(width: 4),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                                decoration: BoxDecoration(
                                  color: badgeColor,
                                  borderRadius: BorderRadius.circular(8),
                                  boxShadow: [
                                    BoxShadow(color: badgeColor.withOpacity(0.4), blurRadius: 4)
                                  ],
                                ),
                                child: Text(
                                  product.savings != null 
                                    ? loc.getString('badge_save_percent').replaceAll('{0}', '${product.savings}') 
                                    : loc.getString(product.badgeOrSavings),
                                  style: GoogleFonts.dynaPuff(color: Colors.black, fontSize: 9, fontWeight: FontWeight.bold),
                                ),
                              ),
                            ],
                          ],
                        ),
                        // Limited badge below title if seasonal (with Timer)
                        if (isLimited) ...[
                          const SizedBox(height: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: Colors.redAccent.withOpacity(0.2),
                              border: Border.all(color: Colors.redAccent.withOpacity(0.5)),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.timer, color: Colors.redAccent, size: 10),
                                const SizedBox(width: 4),
                                Text(
                                  // Dynamic Timer Text
                                  StoreUtils.formatEventTimer(_eventManager.remainingDuration), 
                                  style: GoogleFonts.dynaPuff(color: Colors.redAccent, fontSize: 9, fontWeight: FontWeight.bold)
                                ),
                              ],
                            ),
                          ),
                        ],
                        
                        const SizedBox(height: 8),
                        
                        // Price Section
                        if (product.savings != null && product.originalPrice != null)
                          Text(
                            product.originalPrice!,
                            style: GoogleFonts.dynaPuff(
                              color: Colors.white38,
                              fontSize: 10,
                              decoration: TextDecoration.lineThrough,
                              decorationColor: Colors.redAccent,
                            ),
                          ),
                        Text(
                          product.formattedPrice + (isSubscription ? StoreUtils.formatSubscriptionPeriod(product) : ''),
                          style: GoogleFonts.dynaPuff(
                            color: featured ? Colors.purpleAccent : Colors.cyanAccent,
                            fontSize: featured ? 18 : 15,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        
                        const SizedBox(height: 8),
                        
                        // Description
                        Text(
                          loc.getString(product.description),
                          style: GoogleFonts.dynaPuff(color: Colors.white60, fontSize: 10, height: 1.2),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        
                        const SizedBox(height: 10),
                        
                        // Features List
                         ...product.contents.take(3).map((contentKey) => Padding(
                          padding: const EdgeInsets.only(bottom: 3),
                          child: Row(
                            children: [
                              Icon(Icons.check_circle, color: featured ? Colors.purpleAccent : Colors.cyanAccent, size: 12),
                              const SizedBox(width: 4),
                              Expanded(
                                child: Text(
                                  loc.getString(contentKey), 
                                  style: GoogleFonts.dynaPuff(color: Colors.white70, fontSize: 10),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        )),
                        
                        const SizedBox(height: 12),
                        
                        // Action Button
                        CuteMenuButton(
                          label: isSubscription ? loc.getString('btn_subscribe') : loc.getString('btn_buy'),
                          onTap: () => _purchaseProduct(product),
                          baseColor: featured ? Colors.purpleAccent : Colors.cyanAccent,
                          textColor: featured ? Colors.white : Colors.black, // High contrast
                          height: 44,
                          fontSize: 13,
                          width: double.infinity,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
  
  Future<void> _purchaseProduct(IAPProduct product) async {
    AudioManager().playSfxId(SfxId.uiClick);
    
    // Check if IAP is busy
    if (widget.iapManager.isPurchasing) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );
    
    try {
      await widget.iapManager.purchaseProduct(product.id);
      
      if (mounted) {
        Navigator.pop(context); // Close loading
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                LocalizationManager().getString('msg_purchase_success')
                    .replaceAll('{0}', LocalizationManager().getString(product.name)),
                style: GoogleFonts.dynaPuff(),
            ),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context); // Close loading
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                LocalizationManager().getString('msg_purchase_fail').replaceAll('{0}', '$e'),
                style: GoogleFonts.dynaPuff(),
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}


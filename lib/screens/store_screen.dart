import 'package:flutter/material.dart';
import '../game/iap_catalog.dart';
import '../game/economy_manager.dart';
import '../game/iap_manager.dart';
import '../game/audio_manager.dart';
import 'package:google_fonts/google_fonts.dart';
import '../game/localization_manager.dart';
import 'components/styled_back_button.dart';

/// In-App Purchase Store Screen
class StoreScreen extends StatefulWidget {
  final IAPManager iapManager;
  
  const StoreScreen({super.key, required this.iapManager});

  @override
  State<StoreScreen> createState() => _StoreScreenState();
}

class _StoreScreenState extends State<StoreScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  
  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }
  
  @override
  void dispose() {
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
          _buildTokensTab(),
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
        children: IAPCatalog.tokenProducts.map((p) => _buildProductCard(p)).toList(),
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
    final seasonalProducts = IAPCatalog.seasonalProducts;
    
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
    
    return LayoutBuilder(
      builder: (context, constraints) {
        final screenWidth = MediaQuery.of(context).size.width;
        final cardWidth = (screenWidth - 8 * 4) / 3; 
        
        return ConstrainedBox(
          constraints: BoxConstraints(
            minWidth: cardWidth,
            maxWidth: cardWidth,
            minHeight: featured ? 220 : 180, // Consistent minimum height
          ),
          child: GestureDetector(
            onTap: () => _purchaseProduct(product),
            child: Container(
              decoration: BoxDecoration(
                gradient: featured ? LinearGradient(
                  colors: [
                    const Color(0xFF2A1A4A),
                    const Color(0xFF1A0A2E),
                  ],
                ) : null,
                color: featured ? null : Colors.white.withOpacity(0.05),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: featured ? Colors.purpleAccent.withOpacity(0.5) : Colors.white12,
                  width: featured ? 2 : 1,
                ),
              ),
              child: Stack(
                children: [
                  // Card Content
                   Padding(
                    padding: const EdgeInsets.all(10),
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
                                  fontSize: featured ? 13 : 11,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            // Inline badge (savings/featured)
                            if (product.badgeOrSavings.isNotEmpty) ...[
                              const SizedBox(width: 4),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                                decoration: BoxDecoration(
                                  color: badgeColor,
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  product.savings != null 
                                    ? loc.getString('badge_save_percent').replaceAll('{0}', '${product.savings}') 
                                    : loc.getString(product.badgeOrSavings),
                                  style: GoogleFonts.dynaPuff(color: Colors.black, fontSize: 8, fontWeight: FontWeight.bold),
                                ),
                              ),
                            ],
                          ],
                        ),
                        // Limited badge below title if seasonal
                        if (isLimited) ...[
                          const SizedBox(height: 4),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.redAccent,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.timer, color: Colors.white, size: 10),
                                const SizedBox(width: 2),
                                Text(loc.getString('store_badge_limited'), style: GoogleFonts.dynaPuff(color: Colors.white, fontSize: 8)),
                              ],
                            ),
                          ),
                        ],
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
                            color: Colors.cyanAccent,
                            fontSize: featured ? 16 : 14,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          loc.getString(product.description),
                          style: GoogleFonts.dynaPuff(color: Colors.white54, fontSize: 10),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 6),
                         ...product.contents.take(3).map((contentKey) => Padding(
                          padding: const EdgeInsets.only(bottom: 2),
                          child: Row(
                            children: [
                              const Icon(Icons.check_circle, color: Colors.greenAccent, size: 12),
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
                        const SizedBox(height: 8),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: () => _purchaseProduct(product),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: featured ? Colors.purpleAccent : Colors.cyanAccent,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 8),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            ),
                            child: Text(
                                isSubscription ? loc.getString('btn_subscribe') : loc.getString('btn_buy'),
                                style: GoogleFonts.dynaPuff(fontWeight: FontWeight.bold, fontSize: 11),
                            ),
                          ),
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
    AudioManager().playSfx('soft_button_click.mp3');
    
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

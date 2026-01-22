import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../game/customization_manager.dart';
import '../game/audio_manager.dart';
import '../game/localization_manager.dart';
import 'components/styled_back_button.dart';

/// Skin and Theme Customization Screen
class CustomizationScreen extends StatefulWidget {
  final CustomizationManager customizationManager;
  
  const CustomizationScreen({super.key, required this.customizationManager});

  @override
  State<CustomizationScreen> createState() => _CustomizationScreenState();
}

class _CustomizationScreenState extends State<CustomizationScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  
  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }
  
  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D0D1A),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(LocalizationManager().getString('cust_title'), style: GoogleFonts.dynaPuff(fontWeight: FontWeight.bold)),
        leadingWidth: 100,
        leading: Padding(
          padding: const EdgeInsets.only(left: 8, top: 8, bottom: 8),
          child: StyledBackButton(),
        ),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.purpleAccent,
          labelColor: Colors.purpleAccent,
          unselectedLabelColor: Colors.white54,
          labelStyle: GoogleFonts.dynaPuff(fontWeight: FontWeight.bold),
          unselectedLabelStyle: GoogleFonts.dynaPuff(),
          tabs: [
            Tab(text: LocalizationManager().getString('cust_tab_prism')),
            Tab(text: LocalizationManager().getString('cust_tab_effect')),
            Tab(text: LocalizationManager().getString('cust_tab_theme')),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildItemGrid(ItemType.prismSkin),
          _buildItemGrid(ItemType.lightEffect),
          _buildItemGrid(ItemType.backgroundTheme),
        ],
      ),
    );
  }
  
  Widget _buildItemGrid(ItemType type) {
    final items = widget.customizationManager.catalog.where((i) => i.type == type).toList();
    
    return GridView.builder(
      padding: const EdgeInsets.all(8),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 4,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
        childAspectRatio: 1.8,
      ),
      itemCount: items.length,
      itemBuilder: (context, index) => _buildItemCard(items[index]),
    );
  }
  
  Widget _buildItemCard(GameItem item) {
    final isUnlocked = widget.customizationManager.isUnlocked(item.id);
    final isSelected = _isSelected(item);
    
    return GestureDetector(
      onTap: () => _selectItem(item),
      child: Container(
        decoration: BoxDecoration(
          gradient: isSelected ? LinearGradient(
            colors: [Colors.purpleAccent.withOpacity(0.5), Colors.cyanAccent.withOpacity(0.3)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ) : null,
          color: isSelected ? null : (isUnlocked ? Colors.white.withOpacity(0.1) : Colors.white.withOpacity(0.03)),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? Colors.purpleAccent : (isUnlocked ? Colors.white24 : Colors.white10),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Stack(
          children: [
            // Content
            Padding(
              padding: const EdgeInsets.all(8),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Icon/Preview
                  Container(
                    width: 250,
                    height: 50,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: isUnlocked ? LinearGradient(
                        colors: _getItemColors(item),
                      ) : null,
                      color: isUnlocked ? null : Colors.white10,
                    ),
                    child: isUnlocked 
                      ? null 
                      : const Icon(Icons.lock, color: Colors.white38, size: 24),
                  ),
                  
                  const SizedBox(height: 8),
                  
                  // Name
                  Text(
                    item.name,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: isUnlocked ? Colors.white : Colors.white38,
                      fontSize: 11,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  
                  // Unlock requirement
                  if (!isUnlocked && item.requiredStars > 0)
                    Text(
                      '${item.requiredStars} ⭐',
                      style: const TextStyle(color: Colors.amber, fontSize: 10),
                    ),
                  
                  if (!isUnlocked && item.isIAP)
                    const Text(
                      '💰 Premium',
                      style: TextStyle(color: Colors.purpleAccent, fontSize: 10),
                    ),
                ],
              ),
            ),
            
            // Selected checkmark
            if (isSelected)
              Positioned(
                top: 4,
                right: 4,
                child: Container(
                  padding: const EdgeInsets.all(2),
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.purpleAccent,
                  ),
                  child: const Icon(Icons.check, color: Colors.white, size: 14),
                ),
              ),
          ],
        ),
      ),
    );
  }
  
  bool _isSelected(GameItem item) {
    switch (item.type) {
      case ItemType.prismSkin:
        return widget.customizationManager.selectedSkin == item.id;
      case ItemType.lightEffect:
        return widget.customizationManager.selectedEffect == item.id;
      case ItemType.backgroundTheme:
        return widget.customizationManager.selectedTheme == item.id;
    }
  }
  
  void _selectItem(GameItem item) async {
    if (!widget.customizationManager.isUnlocked(item.id)) {
      // Show unlock requirement
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(item.isIAP 
            ? 'Bu öğe mağazadan satın alınabilir.'
            : '${item.requiredStars} yıldız gerekiyor.'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }
    
    AudioManager().playSfxId(SfxId.uiClick);
    await widget.customizationManager.selectItem(item.id);
    setState(() {});
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${item.name} seçildi! ✨'),
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 1),
      ),
    );
  }
  
  List<Color> _getItemColors(GameItem item) {
    // Color schemes based on item id
    if (item.id.contains('crystal')) return [Colors.white, Colors.cyan];
    if (item.id.contains('ice')) return [Colors.lightBlue, Colors.white];
    if (item.id.contains('emerald')) return [Colors.green, Colors.teal];
    if (item.id.contains('gold')) return [Colors.amber, Colors.orange];
    if (item.id.contains('diamond')) return [Colors.white, Colors.lightBlue];
    if (item.id.contains('rainbow')) return [Colors.red, Colors.purple];
    if (item.id.contains('plasma')) return [Colors.purple, Colors.pink];
    if (item.id.contains('galactic')) return [Colors.deepPurple, Colors.blue];
    if (item.id.contains('space')) return [Colors.indigo, Colors.black];
    if (item.id.contains('neon')) return [Colors.pink, Colors.cyan];
    if (item.id.contains('ocean')) return [Colors.blue, Colors.teal];
    return [Colors.grey, Colors.blueGrey];
  }
}


import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../game/easter_egg_manager.dart';
import '../game/event_manager.dart'; // Added
import '../game/localization_manager.dart';
import '../game/audio_manager.dart';
import '../game/progress/campaign_progress.dart';
import '../game/utils/security_utils.dart';
import '../theme/app_theme.dart';
import 'components/styled_back_button.dart';
import 'components/fast_page_route.dart';
import '../game/privacy_manager.dart';
import 'privacy_policy_screen.dart';
import 'terms_of_service_screen.dart';
import '../game/procedural/campaign_loader.dart';

/// About Screen with Developer Credits and Hidden Debug Menu
class AboutScreen extends StatefulWidget {
  const AboutScreen({super.key});

  @override
  State<AboutScreen> createState() => _AboutScreenState();
}

class _AboutScreenState extends State<AboutScreen> with TickerProviderStateMixin {
  late List<AnimationController> _glowControllers;
  
  // Hidden Developer Menu State
  int _versionTapCount = 0;
  bool _devModeUnlocked = false;
  bool _isLoadingDebug = false;
  static const String _devPassword = '190319';
  static const String _keyDevUnlocked = 'dev_mode_unlocked';
  
  @override
  void initState() {
    super.initState();
    
    // Check if already unlocked
    _checkDevModeStatus();
    
    // Create glow animation for each developer
    _glowControllers = EasterEggManager.developers.map((dev) {
      final controller = AnimationController(
        vsync: this,
        duration: const Duration(seconds: 2),
      )..repeat(reverse: true);
      return controller;
    }).toList();
  }
  
  Future<void> _checkDevModeStatus() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _devModeUnlocked = prefs.getBool(_keyDevUnlocked) ?? false;
    });
  }
  
  @override
  void dispose() {
    for (var controller in _glowControllers) {
      controller.dispose();
    }
    super.dispose();
  }
  
  void _onVersionTap() {
    AudioManager().playSfxId(SfxId.uiClick);
    _versionTapCount++;
    
    if (_versionTapCount >= 5) {
      _versionTapCount = 0;
      _showPasswordDialog();
    } else if (_versionTapCount >= 3) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${5 - _versionTapCount} kere daha...'),
          backgroundColor: Colors.purple,
          duration: const Duration(milliseconds: 800),
        ),
      );
    }
  }
  
  void _showPasswordDialog() {
    if (_devModeUnlocked) {
      // Already unlocked - show dev panel directly
      _showDevPanel();
      return;
    }
    
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: PrismazeTheme.backgroundCard,
        title: Text('🔐 Geliştirici Girişi', style: GoogleFonts.dynaPuff(color: Colors.white)),
        content: TextField(
          controller: controller,
          obscureText: true,
          style: GoogleFonts.dynaPuff(color: Colors.white),
          decoration: InputDecoration(
            hintText: 'Şifre',
            hintStyle: GoogleFonts.dynaPuff(color: Colors.white38),
            enabledBorder: OutlineInputBorder(
              borderSide: BorderSide(color: Colors.white24),
              borderRadius: BorderRadius.circular(8),
            ),
            focusedBorder: OutlineInputBorder(
              borderSide: BorderSide(color: PrismazeTheme.primaryPurple),
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('İptal', style: GoogleFonts.dynaPuff(color: Colors.white54)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: PrismazeTheme.primaryPurple),
            onPressed: () async {
              if (controller.text.toUpperCase() == _devPassword) {
                Navigator.pop(ctx);
                final prefs = await SharedPreferences.getInstance();
                await prefs.setBool(_keyDevUnlocked, true);
                setState(() => _devModeUnlocked = true);
                AudioManager().playSfxId(SfxId.achievementUnlocked);
                _showDevPanel();
              } else {
                AudioManager().playSfxId(SfxId.error);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Yanlış şifre!'), backgroundColor: Colors.red),
                );
              }
            },
            child: Text('Giriş', style: GoogleFonts.dynaPuff(color: Colors.white)),
          ),
        ],
      ),
    );
  }
  
  void _showDevPanel() {
    showModalBottomSheet(
      context: context,
      backgroundColor: PrismazeTheme.backgroundCard,
      isScrollControlled: true,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) => Container(
          height: MediaQuery.of(ctx).size.height * 0.7, // Fixed height
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              // Header (fixed)
              Row(
                children: [
                  Icon(Icons.developer_mode, color: PrismazeTheme.warningYellow, size: 24),
                  const SizedBox(width: 12),
                  Text('Geliştirici Araçları', style: GoogleFonts.dynaPuff(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                  const Spacer(),
                  IconButton(
                    icon: Icon(Icons.close, color: Colors.white54),
                    onPressed: () => Navigator.pop(ctx),
                  ),
                ],
              ),
              const Divider(color: Colors.white24),
              
              // Scrollable content
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (_isLoadingDebug)
                        Center(child: Padding(
                          padding: EdgeInsets.all(40),
                          child: CircularProgressIndicator(color: PrismazeTheme.primaryPurple),
                        ))
                      else ...[
                        const SizedBox(height: 8),
                        
                        // DEBUG OVERLAY TOGGLE
                        _sectionHeader('🔍 Debug Görüntüleme'),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(
                            color: Colors.cyan.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.cyan.withOpacity(0.3)),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.grid_on, color: Colors.cyan, size: 20),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text('Hitbox Göster', style: GoogleFonts.dynaPuff(color: Colors.white, fontSize: 12)),
                                    Text('Duvar, ayna, prizma ve hedef çarpışma alanları', style: GoogleFonts.dynaPuff(color: Colors.white38, fontSize: 9)),
                                  ],
                                ),
                              ),
                              FutureBuilder<bool>(
                                future: SharedPreferences.getInstance().then((p) => p.getBool('settings_debug_mode') ?? false),
                                builder: (context, snapshot) {
                                  final isEnabled = snapshot.data ?? false;
                                  return Switch(
                                    value: isEnabled,
                                    activeColor: Colors.cyan,
                                    onChanged: (val) async {
                                      final prefs = await SharedPreferences.getInstance();
                                      await prefs.setBool('settings_debug_mode', val);
                                      setModalState(() {});
                                      AudioManager().playSfxId(SfxId.uiClick);
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(
                                          content: Text(val ? 'Debug overlay aktif! Level\'e girin.' : 'Debug overlay kapatıldı.'),
                                          backgroundColor: Colors.cyan,
                                          duration: Duration(seconds: 1),
                                        ),
                                      );
                                    },
                                  );
                                },
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 12),
                        
                        // LEVEL CONTROLS
                        _sectionHeader('📍 Level Kontrolleri'),
                        Row(
                          children: [
                            Expanded(child: _devButton('TÜM LEVELLERİ AÇ', Icons.lock_open, Colors.green, () async {
                              setModalState(() => _isLoadingDebug = true);
                                try {
                                  // Ensure manifest is loaded so we know correct level counts
                                  final manifest = await CampaignLevelLoader.loadManifest();
                                  final progress = CampaignProgress();
                                  await progress.initWithManifest(manifest ?? {'episodes': {}});

                                  // NEW: Use CampaignProgress for episode-based system (5 episodes x 200 levels = 1000 total)
                                  for (int episode = 1; episode <= 5; episode++) {
                                    final levelCount = progress.getLevelCount(episode);
                                    await progress.debugSetProgress(episode, levelCount, 3);
                                  }
                                
                                AudioManager().playSfxId(SfxId.achievementUnlocked);
                                if (mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Tüm leveller açıldı (5 Episode x 200 = 1000 level, 3★)!'), backgroundColor: Colors.green));
                                }
                              } catch (e) {
                                print('Debug unlock error: $e');
                                if (mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Hata: $e'), backgroundColor: Colors.red));
                                }
                              }
                              setModalState(() => _isLoadingDebug = false);
                            })),
                            const SizedBox(width: 8),
                            Expanded(child: _devButton('LEVELLERİ SIFIRLA', Icons.restart_alt, Colors.orange, () async {
                              setModalState(() => _isLoadingDebug = true);
                              try {
                                // NEW: Use CampaignProgress.resetAll() for episode-based system
                                await CampaignProgress().resetAll();
                                
                                AudioManager().playSfx('trash.mp3');
                                if (mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Tüm leveller sıfırlandı!'), backgroundColor: Colors.orange));
                                }
                              } catch (e) {
                                print('Debug reset error: $e');
                              }
                              setModalState(() => _isLoadingDebug = false);
                            })),
                          ],
                        ),
                        const SizedBox(height: 12),
                        
                        // TIME CONTROLS
                        _sectionHeader('⏰ Zaman Kontrolleri'),
                        Row(
                          children: [
                            Expanded(child: _devButton('GÜNLÜK SIFIRLA', Icons.calendar_today, Colors.blue, () async {
                              final prefs = await SharedPreferences.getInstance();
                              await prefs.remove('last_login_date');
                              await prefs.remove('login_streak_count');
                              await prefs.remove('mission_date');
                              AudioManager().playSfxId(SfxId.achievementUnlocked);
                              if (mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Günlükler sıfırlandı! Restart gerekli.'), backgroundColor: Colors.blue));
                              }
                            })),
                            const SizedBox(width: 8),
                            Expanded(child: _devButton('SERİYİ KIR', Icons.broken_image, Colors.red, () async {
                              final prefs = await SharedPreferences.getInstance();
                              final threeDaysAgo = DateTime.now().subtract(Duration(days: 3)).toUtc().toIso8601String();
                              await prefs.setString('last_login_date', threeDaysAgo);
                              await prefs.setInt('login_streak_count', 5);
                              await prefs.setInt('previous_streak', 5);
                              AudioManager().playSfxId(SfxId.error);
                              if (mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Seri kırıldı! Restart gerekli.'), backgroundColor: Colors.red));
                              }
                            })),
                          ],
                        ),
                        const SizedBox(height: 12),
                        
                        // EVENT CONTROLS
                        _sectionHeader('🎃 Etkinlik Simülasyonu'),
                        Wrap(
                          spacing: 6,
                          runSpacing: 6,
                          children: [
                            _eventButton('🎃 Halloween', 'halloween', ctx),
                            _eventButton('❄️ Kış', 'winter', ctx),
                            _eventButton('☀️ Yaz', 'summer', ctx),
                            _eventButton('💝 Sevgililer', 'valentines', ctx),
                            _clearEventButton(ctx),
                          ],
                        ),
                        const SizedBox(height: 12),
                        
                        // ECONOMY CONTROLS
                        _sectionHeader('💰 Ekonomi'),
                        Row(
                          children: [
                            Expanded(child: _devButton('+100', Icons.add_circle, Colors.amber, () async {
                              final prefs = await SharedPreferences.getInstance();
                              // Decode current tokens
                              final encoded = prefs.getString('hint_tokens_enc');
                              int currentTokens = 0;
                              if (encoded != null) {
                                currentTokens = SecurityUtils.decodeValue(encoded) ?? 0;
                              }
                              // Add and re-encode
                              final newTokens = currentTokens + 100;
                              await prefs.setString('hint_tokens_enc', SecurityUtils.encodeValue(newTokens));
                              AudioManager().playSfxId(SfxId.coin);
                              if (mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('+100 jeton ($newTokens toplam)! Hot restart yapın.'), backgroundColor: Colors.amber));
                              }
                            })),
                            const SizedBox(width: 6),
                            Expanded(child: _devButton('+500', Icons.monetization_on, Colors.amber.shade700, () async {
                              final prefs = await SharedPreferences.getInstance();
                              final encoded = prefs.getString('hint_tokens_enc');
                              int currentTokens = 0;
                              if (encoded != null) {
                                currentTokens = SecurityUtils.decodeValue(encoded) ?? 0;
                              }
                              final newTokens = currentTokens + 500;
                              await prefs.setString('hint_tokens_enc', SecurityUtils.encodeValue(newTokens));
                              AudioManager().playSfxId(SfxId.coin);
                              if (mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('+500 jeton ($newTokens toplam)! Hot restart yapın.'), backgroundColor: Colors.amber));
                              }
                            })),
                            const SizedBox(width: 6),
                            Expanded(child: _devButton('SIFIRLA', Icons.money_off, Colors.red, () async {
                              final prefs = await SharedPreferences.getInstance();
                              await prefs.setString('hint_tokens_enc', SecurityUtils.encodeValue(0));
                              AudioManager().playSfx('trash.mp3');
                              if (mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Jetonlar sıfırlandı! Hot restart yapın.'), backgroundColor: Colors.red));
                              }
                            })),
                          ],
                        ),
                        const SizedBox(height: 12),
                        
                        // COLLECTION CONTROLS
                        _sectionHeader('🎨 Koleksiyon'),
                        Row(
                          children: [
                            Expanded(child: _devButton('TÜM SKİNLER', Icons.palette, Colors.purple, () async {
                              setModalState(() => _isLoadingDebug = true);
                              final prefs = await SharedPreferences.getInstance();
                              // Unlock ALL skins, effects, and themes
                              final allItems = [
                                // PRISM SKINS (39)
                                'skin_crystal', 'skin_ice', 'skin_emerald', 'skin_ruby', 'skin_sapphire',
                                'skin_amber', 'skin_jade', 'skin_obsidian', 'skin_quartz', 'skin_pearl',
                                'skin_topaz', 'skin_amethyst', 'skin_bronze', 'skin_silver', 'skin_marble',
                                'skin_glass', 'skin_opal', 'skin_turquoise',
                                'skin_gold', 'skin_neon', 'skin_holographic', 'skin_diamond', 'skin_aurora',
                                'skin_sunset', 'skin_midnight', 'skin_forest', 'skin_ocean', 'skin_pumpkin', 'skin_heart',
                                'skin_rainbow', 'skin_plasma', 'skin_phoenix', 'skin_dragon', 'skin_galactic',
                                'skin_blizzard', 'skin_ghost',
                                'skin_blackhole', 'skin_dimension', 'skin_infinity', 'skin_creator',
                                // EFFECTS
                                'effect_classic', 'effect_dotted', 'effect_glitter', 'effect_rainbow', 
                                'effect_pulse', 'effect_daily_special', 'effect_snow', 'effect_fire',
                                // THEMES
                                'theme_space', 'theme_neon', 'theme_ocean', 'theme_forest', 'theme_desert',
                                'theme_mountain', 'theme_galaxy', 'theme_daily_exclusive', 'theme_winter',
                                'theme_halloween', 'theme_summer', 'theme_abyss',
                              ];
                              await prefs.setStringList('unlocked_items', allItems);
                              AudioManager().playSfxId(SfxId.achievementUnlocked);
                              setModalState(() => _isLoadingDebug = false);
                              if (mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Tüm ${allItems.length} item açıldı! Restart gerekli.'), backgroundColor: Colors.purple));
                              }
                            })),
                            const SizedBox(width: 8),
                            Expanded(child: _devButton('KOL. SIFIRLA', Icons.delete_sweep, Colors.red.shade700, () async {
                              final prefs = await SharedPreferences.getInstance();
                              await prefs.remove('unlocked_items');
                              AudioManager().playSfx('trash.mp3');
                              if (mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Koleksiyon sıfırlandı! Restart gerekli.'), backgroundColor: Colors.red));
                              }
                            })),
                          ],
                        ),
                        const SizedBox(height: 12),
                        
                        // COMEBACK TEST
                        _sectionHeader('🎁 Geri Dönüş Testi'),
                        Row(
                          children: [
                            Expanded(child: _devButton('5 GÜN', Icons.timelapse, Colors.teal, () async {
                              final prefs = await SharedPreferences.getInstance();
                              final fiveDaysAgo = DateTime.now().subtract(Duration(days: 5)).toIso8601String();
                              await prefs.setString('last_played_date', fiveDaysAgo);
                              await prefs.remove('comeback_claimed');
                              AudioManager().playSfxId(SfxId.achievementUnlocked);
                              if (mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('5 gün uzaklık! Restart gerekli.'), backgroundColor: Colors.teal));
                              }
                            })),
                            const SizedBox(width: 8),
                            Expanded(child: _devButton('35 GÜN', Icons.date_range, Colors.indigo, () async {
                              final prefs = await SharedPreferences.getInstance();
                              final ago = DateTime.now().subtract(Duration(days: 35)).toIso8601String();
                              await prefs.setString('last_played_date', ago);
                              await prefs.remove('comeback_claimed');
                              AudioManager().playSfxId(SfxId.achievementUnlocked);
                              if (mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('35 gün uzaklık! Restart gerekli.'), backgroundColor: Colors.indigo));
                              }
                            })),
                          ],
                        ),
                        
                        const SizedBox(height: 20),
                        
                        // Lock Dev Mode Button
                        Center(
                          child: TextButton.icon(
                            icon: Icon(Icons.lock, color: Colors.red, size: 14),
                            label: Text('Geliştirici Modunu Kilitle', style: GoogleFonts.dynaPuff(color: Colors.red, fontSize: 11)),
                            onPressed: () async {
                              final prefs = await SharedPreferences.getInstance();
                              await prefs.setBool(_keyDevUnlocked, false);
                              setState(() => _devModeUnlocked = false);
                              Navigator.pop(ctx);
                              ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Geliştirici modu kilitlendi'), backgroundColor: Colors.red));
                            },
                          ),
                        ),
                        const SizedBox(height: 10),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
  
  Widget _sectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Text(title, style: GoogleFonts.dynaPuff(color: PrismazeTheme.accentCyan, fontSize: 12, fontWeight: FontWeight.w600)),
    );
  }
  
  Widget _devButton(String label, IconData icon, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        decoration: BoxDecoration(
          color: color.withOpacity(0.15),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.4)),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(height: 4),
            Text(label, style: GoogleFonts.dynaPuff(color: Colors.white, fontSize: 9), textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
  
  Widget _eventButton(String label, String eventId, BuildContext ctx) {
    return GestureDetector(
      onTap: () async {
        // Use EventManager for instant update
        await EventManager().debugForceEvent(eventId);
        AudioManager().playSfxId(SfxId.achievementUnlocked);
        Navigator.pop(ctx);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('$label etkinliği aktif! Mağaza ve görevleri kontrol edin.'), 
            backgroundColor: Colors.purple,
            duration: const Duration(seconds: 2),
          ),
        );
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
        decoration: BoxDecoration(
          color: PrismazeTheme.primaryPurple.withOpacity(0.2),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: PrismazeTheme.primaryPurple.withOpacity(0.4)),
        ),
        child: Text(label, style: GoogleFonts.dynaPuff(color: Colors.white, fontSize: 11)),
      ),
    );
  }
  
  Widget _clearEventButton(BuildContext ctx) {
    return GestureDetector(
      onTap: () async {
        await EventManager().debugClearEvent();
        AudioManager().playSfx('trash.mp3');
        Navigator.pop(ctx);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Etkinlik simülasyonu kapatıldı.'), backgroundColor: Colors.red),
        );
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
        decoration: BoxDecoration(
          color: Colors.red.withOpacity(0.2),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.red.withOpacity(0.4)),
        ),
        child: Text('❌ Kaldır', style: GoogleFonts.dynaPuff(color: Colors.red.shade300, fontSize: 11)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: PrismazeTheme.backgroundDark,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(LocalizationManager().getString('about_title'), style: GoogleFonts.dynaPuff(fontWeight: FontWeight.w800)),
        leadingWidth: 100,
        leading: Padding(
          padding: const EdgeInsets.only(left: 8, top: 8, bottom: 8),
          child: StyledBackButton(),
        ),
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: PrismazeTheme.backgroundGradient,
        ),
        child: SafeArea(
          child: Row(
            children: [
              // LEFT COLUMN: Logo, App Info, Links
              Expanded(
                flex: 4,
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Logo
                      Container(
                        width: 100,
                        height: 100,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: PrismazeTheme.buttonGradient,
                          boxShadow: [
                            BoxShadow(
                              color: PrismazeTheme.primaryPurple.withOpacity(0.5),
                              blurRadius: 30,
                              spreadRadius: 5,
                            ),
                          ],
                        ),
                        child: const Icon(Icons.auto_awesome, size: 50, color: Colors.white),
                      ),
                    
                    const SizedBox(height: 16),
                    
                    // App Name
                    const Text(
                      'PrisMaze',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 2,
                      ),
                    ),
                    
                    const SizedBox(height: 4),
                    
                    // VERSION - TAP 5 TIMES TO UNLOCK DEV MODE
                    GestureDetector(
                      onTap: _onVersionTap,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                        decoration: BoxDecoration(
                          color: _devModeUnlocked ? PrismazeTheme.warningYellow.withOpacity(0.2) : Colors.transparent,
                          borderRadius: BorderRadius.circular(8),
                          border: _devModeUnlocked ? Border.all(color: PrismazeTheme.warningYellow.withOpacity(0.5)) : null,
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              'Sürüm 1.0.0',
                              style: TextStyle(color: _devModeUnlocked ? PrismazeTheme.warningYellow : Colors.white54, fontSize: 12),
                            ),
                            if (_devModeUnlocked) ...[
                              const SizedBox(width: 6),
                              Icon(Icons.developer_mode, color: PrismazeTheme.warningYellow, size: 14),
                            ],
                          ],
                        ),
                      ),
                    ),
                    
                    const SizedBox(height: 24),
                    
                    // Links
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _buildSocialButton(Icons.privacy_tip, 'Gizlilik', () {
                           Navigator.push(context, FastPageRoute(page: const PrivacyPolicyScreen()));
                        }),
                        const SizedBox(width: 16),
                        _buildSocialButton(Icons.description, 'Şartlar', () {
                           Navigator.push(context, FastPageRoute(page: const TermsOfServiceScreen()));
                        }),
                        const SizedBox(width: 16),
                        _buildSocialButton(Icons.email, 'İletişim', () => PrivacyManager().requestDataViaEmail()),
                      ],
                    ),
                    
                    const SizedBox(height: 24),
                    
                    // Copyright
                    Text(
                      '© 2026 Kynora Studio',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.white.withOpacity(0.3), fontSize: 11),
                    ),
                    
                    const SizedBox(height: 8),
                    
                    // Easter egg hint
                    GestureDetector(
                      onDoubleTap: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Gizli kod: KYNORA2026 🤫'),
                            backgroundColor: Colors.purple,
                          ),
                        );
                      },
                      child: const Text(
                        'Made with 💜 in Türkiye',
                        style: TextStyle(color: Colors.white24, fontSize: 10),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            
            // RIGHT COLUMN: Developers & Thanks
            Expanded(
              flex: 6,
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Developer Credits
                    const Text(
                      'GELİŞTİRİCİLER',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 3,
                      ),
                    ),
                    
                    const SizedBox(height: 12),
                    
                    ...EasterEggManager.developers.asMap().entries.map((entry) {
                      return _buildDeveloperCard(entry.value, _glowControllers[entry.key]);
                    }),
                    
                    const SizedBox(height: 24),
                    
                    // Special Thanks
                    const Text(
                      'ÖZEL TEŞEKKÜRLER',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 3,
                      ),
                    ),
                    
                    const SizedBox(height: 8),
                    
                    const Text(
                      'Tüm oyuncularımıza, beta test ekibimize ve ailelerimize ❤️',
                      style: TextStyle(color: Colors.white54, height: 1.4, fontSize: 12),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      ),
    );
  }
  
  Widget _buildDeveloperCard(DeveloperCredit dev, AnimationController controller) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, child) {
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: dev.color.withOpacity(0.3 + controller.value * 0.4),
              width: 2,
            ),
            boxShadow: [
              BoxShadow(
                color: dev.color.withOpacity(0.2 * controller.value),
                blurRadius: 20,
                spreadRadius: 2,
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    colors: [dev.color, dev.color.withOpacity(0.5)],
                  ),
                ),
                child: const Icon(Icons.person, color: Colors.white),
              ),
              const SizedBox(width: 16),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    dev.name,
                    style: TextStyle(
                      color: dev.color,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    dev.role,
                    style: const TextStyle(color: Colors.white54, fontSize: 13),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
  
  Widget _buildSocialButton(IconData icon, String label, VoidCallback onTap) {
    return GestureDetector(
      onTap: () {
        AudioManager().playSfxId(SfxId.uiClick);
        onTap();
      },
      child: Column(
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white.withOpacity(0.1),
            ),
            child: Icon(icon, color: Colors.white54),
          ),
          const SizedBox(height: 6),
          Text(label, style: const TextStyle(color: Colors.white38, fontSize: 11)),
        ],
      ),
    );
  }
}


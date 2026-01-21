import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../game/economy_manager.dart';
import '../game/progress_manager.dart';
import '../game/progress/campaign_progress.dart';
import '../game/audio_manager.dart';
import '../game/settings_manager.dart';
import '../game/localization_manager.dart';
import '../game/notification_manager.dart';
import '../game/customization_manager.dart';
import '../game/easter_egg_manager.dart';
import '../game/mission_manager.dart';
import '../game/utils/platform_utils.dart';
import '../theme/app_theme.dart';
import 'settings_overlay.dart';
import 'game_screen.dart';
import '../game/iap_manager.dart';
import '../game/network_manager.dart';
import '../game/privacy_manager.dart';
import '../game/cloud_save_manager.dart';
import '../game/services/platform_service.dart';
import 'store_screen.dart';
import 'achievements_screen.dart';
import 'customization_screen.dart';
import 'about_screen.dart';
import 'endless_mode_screen.dart';
import 'statistics_screen.dart';
import 'campaign_screen.dart';
import 'daily_quests_screen.dart';
import 'components/menu_icon_button.dart';
import 'components/daily_login_overlay.dart';
import 'components/fast_page_route.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'components/age_gate_dialog.dart';

class MainMenuScreen extends StatefulWidget {
  const MainMenuScreen({super.key});

  @override
  State<MainMenuScreen> createState() => _MainMenuScreenState();
}

class _MainMenuScreenState extends State<MainMenuScreen> with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  late AnimationController _controller;
  late EconomyManager economy;
  late ProgressManager progress;
  late MissionManager missionManager;
  late IAPManager iapManager;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this); // Observe lifecycle
    _controller = AnimationController(vsync: this, duration: const Duration(seconds: 2))..repeat(reverse: true);
    _loadData();
  }
  
  Future<void> _loadData() async {
      economy = EconomyManager();
      await economy.init();
      iapManager = IAPManager(economy);
      await iapManager.init();
      progress = ProgressManager();
      await progress.init();
      missionManager = MissionManager(economy);
      await missionManager.init();
      
      // Init Network & Retry Pending
      await PlatformService().init();
      await NetworkManager().init();
      await CloudSaveManager().retryPendingSaves();
      await PrivacyManager().init();
      
      if (mounted) {
        await _verifyAge();
      }

      if (mounted && PrivacyManager().shouldShowConsentDialog() && !PrivacyManager().isChildMode) {
        _showPrivacyDialog();
      }
      
      setState(() {
          _isLoading = false;
      });

      final sm = SettingsManager();
      
      // await sm.init(); // Already initialized in main
      await LocalizationManager().init(); // Load lang
      
      // Init Notification Manager
      await NotificationManager().init();
      
      // Cancel pending notifications since we are active
      NotificationManager().cancelAll(); 
      
      AudioManager().setMusicVolume(sm.musicVolume); 
      AudioManager().setMasterVolume(sm.masterVolume);
      AudioManager().setSfxVolume(sm.sfxVolume);
      AudioManager().setVibration(sm.vibrationEnabled);

      AudioManager().playMenuMusic();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _controller.dispose();
    super.dispose();
  }
  
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
      if (state == AppLifecycleState.paused || state == AppLifecycleState.detached) {
          // User leaving app -> Stop music and schedule retention
          AudioManager().stopAllMusic();
          NotificationManager().scheduleRetentionNotifications();
      } else if (state == AppLifecycleState.resumed) {
          // User returned -> Resume music and cancel reminders
          AudioManager().playMenuMusic();
          NotificationManager().cancelAll();
      }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        backgroundColor: PrismazeTheme.backgroundDark, 
        body: Center(
          child: CircularProgressIndicator(color: PrismazeTheme.primaryPurple),
        ),
      );
    }

    return Scaffold(
      backgroundColor: PrismazeTheme.backgroundDark,
      body: Stack(
        children: [
          // Background Gradient
          Container(
            decoration: BoxDecoration(
              gradient: PrismazeTheme.backgroundGradient,
            ),
          ),
          
          SafeArea(
            child: Column(
              children: [
                // --- TOP SECTION ---
                _buildTopBar(),
                
                // --- MAIN CONTENT: Two Column Layout ---
                Expanded(
                  child: Row(
                    children: [
                      // LEFT SIDE: Title & Info
                      Expanded(
                        flex: 5,
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            _buildTitle(),
                            const SizedBox(height: 8),
                            _buildLastPlayedInfo(),
                          ],
                        ),
                      ),
                      // RIGHT SIDE: All Buttons
                      Expanded(
                        flex: 5,
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            _buildContinueButton(),
                            const SizedBox(height: 14),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                _buildLevelsButton(),
                                const SizedBox(width: 16),
                                _buildEndlessModeButton(),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                
                // --- BOTTOM SECTION ---
                _buildBottomBar(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTopBar() {
    final loc = LocalizationManager();
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Left: Settings & Stars
          Row(
            children: [
              Container(
                decoration: BoxDecoration(
                  color: PrismazeTheme.backgroundCard,
                  shape: BoxShape.circle,
                  border: Border.all(color: PrismazeTheme.primaryPurple.withOpacity(0.4), width: 2),
                ),
                child: IconButton(
                  icon: Icon(Icons.settings, color: PrismazeTheme.primaryPurpleLight, size: 20),
                  padding: const EdgeInsets.all(8),
                  constraints: const BoxConstraints(),
                  onPressed: () {
                       showDialog(
                           context: context,
                           barrierDismissible: true,
                           builder: (ctx) => SettingsOverlay(
                               settingsManager: SettingsManager(),
                               progressManager: progress,
                               onClose: () {
                                   Navigator.pop(ctx);
                                   setState(() { _isLoading = true; });
                                   _loadData(); // Reload data in case of reset
                               },
                           ),
                       );
                  },
                ),
              ),
              const SizedBox(width: 10),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: PrismazeTheme.backgroundCard,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: PrismazeTheme.starGold.withOpacity(0.4), width: 2),
                ),
                child: Row(
                  children: [
                    Icon(Icons.star, color: PrismazeTheme.starGold, size: 18),
                    const SizedBox(width: 4),
                    Text(
                      '${progress.totalStars}', 
                      style: GoogleFonts.dynaPuff(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w700),
                    ),
                  ],
                ),
              ),
            ],
          ),
          
          // Right: Hints + Store
          Row(
            children: [
              // Hints/Tokens
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: PrismazeTheme.backgroundCard,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: PrismazeTheme.warningYellow.withOpacity(0.4), width: 2),
                ),
                child: Row(
                  children: [
                    Icon(Icons.lightbulb, color: PrismazeTheme.warningYellow, size: 18),
                    const SizedBox(width: 6),
                    Text(
                      '${economy.tokens}',
                      style: GoogleFonts.dynaPuff(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w700),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              // Store Button
              GestureDetector(
                onTap: () {
                  AudioManager().playSfx('soft_button_click.mp3');
                  Navigator.push(context, FastPageRoute(page: StoreScreen(iapManager: iapManager)));
                },
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: PrismazeTheme.backgroundCard,
                    shape: BoxShape.circle,
                    border: Border.all(color: PrismazeTheme.accentCyan.withOpacity(0.4), width: 2),
                  ),
                  child: Icon(Icons.shopping_cart, color: PrismazeTheme.accentCyan, size: 20),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTitle() {
      // Optimized: Static gradient text without continuous animation
      final reduced = SettingsManager().reducedGlowEnabled;
      final highContrast = SettingsManager().highContrastEnabled;
      
      final text = Text(
        LocalizationManager().getString('app_title'),
        textAlign: TextAlign.center,
        style: GoogleFonts.dynaPuff(
          fontSize: 42,
          fontWeight: FontWeight.w900,
          color: Colors.white,
          height: 1.0,
          letterSpacing: 3,
          shadows: reduced ? null : [
            const Shadow(color: Color(0xFF9C27B0), blurRadius: 8),
            const Shadow(color: Color(0xFFE91E63), blurRadius: 12),
          ],
        ),
      );
      
      // Skip shader for reduced glow or high contrast
      if (reduced || highContrast) {
        return RepaintBoundary(child: text);
      }
      
      // Apply gradient with ShaderMask - srcIn clips gradient to text shape
      return RepaintBoundary(
        child: ShaderMask(
          blendMode: BlendMode.srcIn,
          shaderCallback: (bounds) => const LinearGradient(
            colors: [Color(0xFF9C27B0), Color(0xFFE91E63), Color(0xFF9C27B0)],
          ).createShader(bounds),
          child: text,
        ),
      );
  }
  
  Widget _buildLastPlayedInfo() {
      final loc = LocalizationManager();
      final nextLevel = progress.getNextPlayableLevel();
      return Text(
          "${loc.getString('last_played')}: ${loc.getString('level_prefix')} $nextLevel",
          style: GoogleFonts.dynaPuff(
            color: PrismazeTheme.textSecondary, 
            letterSpacing: 2,
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
      );
  }
  
  Widget _buildContinueButton() {
      // Get current campaign progress
      final campaignProgress = CampaignProgress();
      final episodeIds = campaignProgress.episodeIds;
      
      // Find the current episode/level to play
      int targetEpisode = 1;
      int targetLevelIndex = 0;
      
      for (final ep in episodeIds) {
        final epProgress = campaignProgress.getEpisodeProgress(ep);
        if (epProgress.currentLevelIndex < epProgress.totalLevels) {
          targetEpisode = ep;
          targetLevelIndex = epProgress.currentLevelIndex;
          break;
        }
      }
      
      // Calculate display level ID
      final displayLevelId = (targetEpisode - 1) * 200 + targetLevelIndex + 1;
      
      return ScaleTransition(
        scale: Tween(begin: 1.0, end: 1.05).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut)),
        child: GestureDetector(
            onTap: () {
                AudioManager().playSfx('soft_button_click.mp3');
                Navigator.push(context, FastPageRoute(page: GameScreen(
                    levelId: displayLevelId,
                    episode: targetEpisode,
                    levelIndex: targetLevelIndex,
                )))
                  .then((_) {
                       AudioManager().playMenuMusic();       
                       _loadData();
                  });
            },
            child: Container(
                width: 220,
                padding: const EdgeInsets.symmetric(vertical: 14),
                decoration: BoxDecoration(
                    gradient: PrismazeTheme.buttonGradient,
                    borderRadius: BorderRadius.circular(PrismazeTheme.borderRadiusXL),
                    boxShadow: PrismazeTheme.getGlow(PrismazeTheme.primaryPurple, PrismazeTheme.accentPink),
                    border: Border.all(color: Colors.white.withOpacity(0.2), width: 2),
                ),
                child: Center(
                    child: Text(
                        LocalizationManager().getString('continue'),
                        style: GoogleFonts.dynaPuff(
                          color: Colors.white, 
                          fontSize: 18, 
                          fontWeight: FontWeight.w800, 
                          letterSpacing: 1,
                        ),
                    ),
                ),
            ),
        ),
      );
  }
  
  Widget _buildLevelsButton() {
     return GestureDetector(
         onTap: () {
           AudioManager().playSfx('soft_button_click.mp3');
           Navigator.push(context, FastPageRoute(page: const CampaignScreen()))
             .then((_) {
                  AudioManager().playMenuMusic();
                  _loadData();
             });
         },
         child: Container(
           padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
           decoration: BoxDecoration(
             color: PrismazeTheme.backgroundCard,
             borderRadius: BorderRadius.circular(PrismazeTheme.borderRadiusLarge),
             border: Border.all(color: PrismazeTheme.primaryPurpleLight.withOpacity(0.5), width: 2),
             boxShadow: [
               BoxShadow(color: PrismazeTheme.primaryPurple.withOpacity(0.2), blurRadius: 15),
             ],
           ),
           child: Text(
             LocalizationManager().getString('levels'), 
             style: GoogleFonts.dynaPuff(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w700),
           ),
         ),
     );
  }
  
  Widget _buildEndlessModeButton() {
     return GestureDetector(
         onTap: () {
             AudioManager().playSfx('whoosh.mp3');
             Navigator.push(context, FastPageRoute(page: const EndlessModeScreen()))
               .then((_) {
                    AudioManager().playMenuMusic();
                    _loadData();
               });
         },
         child: Container(
             padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
             decoration: BoxDecoration(
                 gradient: PrismazeTheme.accentGradient,
                 borderRadius: BorderRadius.circular(PrismazeTheme.borderRadiusLarge),
                 border: Border.all(color: Colors.white.withOpacity(0.2), width: 2),
                 boxShadow: [
                   BoxShadow(color: PrismazeTheme.accentCyan.withOpacity(0.4), blurRadius: 20, spreadRadius: 2),
                 ],
             ),
             child: Row(
                 mainAxisSize: MainAxisSize.min,
                 children: [
                     Text('∞', style: GoogleFonts.dynaPuff(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w900)),
                     const SizedBox(width: 8),
                     Text(LocalizationManager().getString('endless_mode'), style: GoogleFonts.dynaPuff(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w800)),
                 ],
             ),
         ),
     );
  }
  
  Widget _buildBottomBar() {
      return Padding(
          padding: const EdgeInsets.only(bottom: 12, left: 60, right: 60),
          child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                  color: PrismazeTheme.backgroundCard.withOpacity(0.8),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                    color: Colors.white.withOpacity(0.1),
                    width: 1,
                  ),
              ),
              child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                      // Daily Quests Button with notification dot
                      Stack(
                        clipBehavior: Clip.none,
                        children: [
                          MenuIconButton(icon: Icons.assignment, onTap: () {
                              AudioManager().playSfx('soft_button_click.mp3');
                              Navigator.push(context, FastPageRoute(
                                  page: DailyQuestsScreen(
                                      missionManager: missionManager,
                                      economyManager: economy,
                                  ),
                              )).then((_) => setState(() {})); // Refresh dot after returning
                          }),
                          // Notification dot if unclaimed rewards OR daily login available
                          if (missionManager.missions.any((m) => m.isCompleted && !m.claimed) || economy.canClaimDailyLogin)
                            Positioned(
                              right: 0,
                              top: 0,
                              child: Container(
                                width: 10,
                                height: 10,
                                decoration: BoxDecoration(
                                  color: Colors.red,
                                  shape: BoxShape.circle,
                                  border: Border.all(color: Colors.black, width: 1),
                                ),
                              ),
                            ),
                        ],
                      ),
                      MenuIconButton(icon: Icons.palette, onTap: () {
                          AudioManager().playSfx('soft_button_click.mp3');
                          final cm = CustomizationManager(progress);
                          cm.init().then((_) {
                              Navigator.push(context, FastPageRoute(
                                  page: CustomizationScreen(customizationManager: cm),
                              ));
                          });
                      }),
                      MenuIconButton(icon: Icons.emoji_events, onTap: () {
                          AudioManager().playSfx('soft_button_click.mp3');
                          Navigator.push(context, FastPageRoute(
                              page: AchievementsScreen(progressManager: progress),
                          ));
                      }),
                      MenuIconButton(icon: Icons.bar_chart, onTap: () {
                          AudioManager().playSfx('soft_button_click.mp3');
                          Navigator.push(context, FastPageRoute(
                              page: StatisticsScreen(progressManager: progress),
                          ));
                      }),

                  ],
              ),
          ),
      );
  }
  



  Future<void> _verifyAge() async {
    final prefs = await SharedPreferences.getInstance();
    final hasVerifiedAge = prefs.getBool('age_verified') ?? false;
    
    if (!hasVerifiedAge) {
      final isAdult = await showDialog<bool>(
        context: context,
        barrierDismissible: false,
        builder: (context) => const AgeGateDialog(),
      );
      
      if (isAdult != null) {
        await prefs.setBool('age_verified', true);
        
        if (!isAdult) {
          // Child Mode
          await PrivacyManager().setChildMode(true);
          if (mounted) {
             ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(LocalizationManager().getString('child_mode_active') + "\n" + LocalizationManager().getString('child_mode_desc')),
                  backgroundColor: PrismazeTheme.primaryPurple,
                  duration: Duration(seconds: 4),
                )
             );
          }
        } else {
          // Adult Mode - Ensure child mode is off
          await PrivacyManager().setChildMode(false);
        }
      }
    }
  }

  void _showPrivacyDialog() {
    final loc = LocalizationManager();
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF202020),
        title: Text(loc.getString('privacy_consent_title'), style: GoogleFonts.outfit(color: Colors.white)),
        content: Text(loc.getString('privacy_consent_body'), style: GoogleFonts.outfit(color: Colors.white70)),
        actions: [
            TextButton(
                onPressed: () {
                    PrivacyManager().denyConsent();
                    Navigator.pop(ctx);
                },
                child: Text(loc.getString('privacy_decline'), style: GoogleFonts.outfit(color: Colors.redAccent))
            ),
            ElevatedButton(
                onPressed: () {
                    PrivacyManager().setConsent(analytics: true, personalizedAds: true);
                    Navigator.pop(ctx);
                },
                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF00E5FF)),
                child: Text(loc.getString('privacy_accept'), style: GoogleFonts.outfit(color: Colors.black)),
            ),
        ],
      ),
    );
  }
}

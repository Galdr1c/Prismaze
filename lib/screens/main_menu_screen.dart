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
import '../widgets/cute_menu_button.dart';
import '../widgets/bouncing_button.dart';

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
    try {
      print("MainMenu: _loadData executing...");
      economy = EconomyManager();
      await economy.init();
      print("MainMenu: Economy DONE");
      
      iapManager = IAPManager(economy);
      await iapManager.init();
      print("MainMenu: IAP DONE");
      
      progress = ProgressManager();
      await progress.init();
      print("MainMenu: Progress DONE");
      
      missionManager = MissionManager(economy);
      await missionManager.init();
      print("MainMenu: Mission DONE");
      
      // Init Network & Retry Pending
      // TEMPORARILY DISABLED FOR DEBUGGING
      // await PlatformService().init();
      // await NetworkManager().init();
      // await CloudSaveManager().retryPendingSaves();
      await PrivacyManager().init();
      print("MainMenu: Privacy DONE");
    } catch (e, stack) {
      print("MainMenu: FATAL ERROR during load: $e");
      print(stack);
    }
      
      // FIX: Dismiss loading spinner BEFORE showing blocking dialogs (Age/Privacy).
      // This prevents "deadlock" where dialog waits for user, but user sees only spinner.
      setState(() {
          print("MainMenu: Setting isLoading = false");
          _isLoading = false;
      });
      
      if (mounted) {
        await _verifyAge();
      }

      if (mounted && PrivacyManager().shouldShowConsentDialog() && !PrivacyManager().isChildMode) {
        _showPrivacyDialog();
      }

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

      AudioManager().setContext(AudioContext.menu);
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
          AudioManager().setContext(AudioContext.menu);
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
                  border: Border.all(color: PrismazeTheme.primaryPurple.withOpacity(0.3), width: 1.5),
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
                          _loadData(); 
                        },
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(width: 10),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: PrismazeTheme.backgroundCard,
                  borderRadius: BorderRadius.circular(PrismazeTheme.borderRadiusMedium),
                  border: Border.all(color: PrismazeTheme.starGold.withOpacity(0.3), width: 1.5),
                ),
                child: Row(
                  children: [
                    Icon(Icons.star, color: PrismazeTheme.starGold, size: 18),
                    const SizedBox(width: 6),
                    Text(
                      '${CampaignProgress().getTotalStars()}', 
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
                  borderRadius: BorderRadius.circular(PrismazeTheme.borderRadiusMedium),
                  border: Border.all(color: PrismazeTheme.warningYellow.withOpacity(0.3), width: 1.5),
                ),
                child: Row(
                  children: [
                    Icon(Icons.lightbulb, color: PrismazeTheme.warningYellow, size: 18),
                    const SizedBox(width: 6),
                    Text(
                      '${economy.hints}',
                      style: GoogleFonts.dynaPuff(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w700),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              // Store Button
              GestureDetector(
                onTap: () {
                  AudioManager().playSfxId(SfxId.uiClick);
                  Navigator.push(context, FastPageRoute(page: StoreScreen(iapManager: iapManager)));
                },
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: PrismazeTheme.backgroundCard,
                    shape: BoxShape.circle,
                    border: Border.all(color: PrismazeTheme.accentCyan.withOpacity(0.3), width: 1.5),
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
      final episode = progress.lastPlayedEpisode;
      final levelIndex = progress.lastPlayedLevelIndex;
      final levelId = levelIndex + 1;
      
      // Target: "Last Played: Episode 1 - Level 123"
      final episodeStr = "${loc.getString('episode_prefix') ?? 'Episode'} $episode";
      final levelStr = "${loc.getString('level_prefix')} $levelId";
      
      return Text(
          "${loc.getString('last_played')}: $episodeStr - $levelStr",
          style: GoogleFonts.dynaPuff(
            color: PrismazeTheme.textSecondary, 
            letterSpacing: 2,
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
      );
  }
  
  Widget _buildContinueButton() {
      final campaignProgress = CampaignProgress();
      final episodeIds = campaignProgress.episodeIds;
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
      final displayLevelId = (targetEpisode - 1) * 200 + targetLevelIndex + 1;
      
      return CuteMenuButton(
        label: LocalizationManager().getString('continue'),
        baseColor: PrismazeTheme.primaryPurple,
        onTap: () {
            AudioManager().playSfxId(SfxId.uiClick);
            Navigator.push(context, FastPageRoute(page: GameScreen(
                levelId: displayLevelId,
                episode: targetEpisode,
                levelIndex: targetLevelIndex,
            )))
              .then((_) {
                   AudioManager().setContext(AudioContext.menu);       
                   _loadData();
              });
        },
      );
  }
  
  Widget _buildLevelsButton() {
     return CuteMenuButton(
       label: LocalizationManager().getString('levels'),
       baseColor: PrismazeTheme.accentCyan,
       width: 160,
       fontSize: 16,
       onTap: () {
         AudioManager().playSfxId(SfxId.uiClick);
         Navigator.push(context, FastPageRoute(page: const CampaignScreen()))
           .then((_) {
                AudioManager().setContext(AudioContext.menu);
                _loadData();
           });
       },
     );
  }
  
  Widget _buildEndlessModeButton() {
     return CuteMenuButton(
       label: LocalizationManager().getString('endless_mode'),
       baseColor: const Color(0xFFFF9800), // Orange for contrast
       width: 160,
       fontSize: 14,
       onTap: () {
           AudioManager().playSfxId(SfxId.mirrorMove);
           Navigator.push(context, FastPageRoute(page: const EndlessModeScreen()))
             .then((_) {
                  AudioManager().setContext(AudioContext.menu);
                  _loadData();
             });
       },
     );
  }
  
  Widget _buildBottomBar() {
      return Padding(
          padding: const EdgeInsets.only(bottom: 24, left: 30, right: 30),
          child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                  // Daily Quests Button with notification dot
                  Stack(
                    clipBehavior: Clip.none,
                    children: [
                      _buildAssetButton('assets/images/ui/icon_quests.png', () {
                          AudioManager().playSfxId(SfxId.uiClick);
                          Navigator.push(context, FastPageRoute(
                              page: DailyQuestsScreen(
                                  missionManager: missionManager,
                                  economyManager: economy,
                              ),
                          )).then((_) => setState(() {}));
                      }),
                      if (missionManager.missions.any((m) => m.isCompleted && !m.claimed) || economy.canClaimDailyLogin)
                        Positioned(
                          right: -2,
                          top: -2,
                          child: Container(
                            width: 12,
                            height: 12,
                            decoration: BoxDecoration(
                              color: PrismazeTheme.errorRed,
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white, width: 2),
                            ),
                          ),
                        ),
                    ],
                  ),
                  _buildAssetButton('assets/images/ui/icon_palette.png', () {
                      AudioManager().playSfxId(SfxId.uiClick);
                      final cm = CustomizationManager(progress);
                      cm.init().then((_) {
                          Navigator.push(context, FastPageRoute(
                              page: CustomizationScreen(customizationManager: cm),
                          ));
                      });
                  }),
                  _buildAssetButton('assets/images/ui/icon_trophy.png', () {
                      AudioManager().playSfxId(SfxId.uiClick);
                      Navigator.push(context, FastPageRoute(
                          page: AchievementsScreen(progressManager: progress),
                      ));
                  }),
                  _buildAssetButton('assets/images/ui/icon_stats.png', () {
                      AudioManager().playSfxId(SfxId.uiClick);
                      Navigator.push(context, FastPageRoute(
                          page: StatisticsScreen(
                            progressManager: progress,
                            missionManager: missionManager,
                          ),
                      ));
                  }),

              ],
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
        backgroundColor: PrismazeTheme.backgroundCard,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(PrismazeTheme.borderRadiusLarge),
          side: BorderSide(color: PrismazeTheme.primaryPurple.withOpacity(0.3), width: 1.5),
        ),
        title: Text(loc.getString('privacy_consent_title'), style: GoogleFonts.dynaPuff(color: Colors.white, fontSize: 18)),
        content: Text(loc.getString('privacy_consent_body'), style: GoogleFonts.dynaPuff(color: PrismazeTheme.textSecondary, fontSize: 14)),
        actions: [
            TextButton(
                onPressed: () {
                    PrivacyManager().denyConsent();
                    Navigator.pop(ctx);
                },
                child: Text(loc.getString('privacy_decline'), style: GoogleFonts.dynaPuff(color: PrismazeTheme.errorRed))
            ),
            ElevatedButton(
                onPressed: () {
                    PrivacyManager().setConsent(analytics: true, personalizedAds: true);
                    Navigator.pop(ctx);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: PrismazeTheme.accentPink,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(PrismazeTheme.borderRadiusSmall)),
                ),
                child: Text(loc.getString('privacy_accept'), style: GoogleFonts.dynaPuff(color: Colors.white)),
            ),
        ],
      ),
    );
  }

  Widget _buildAssetButton(String assetPath, VoidCallback onTap) {
      return BouncingButton(
          onTap: onTap,
          child: Padding(
              padding: const EdgeInsets.all(4),
              child: Image.asset(
                  assetPath,
                  width: 48,
                  height: 48,
                  fit: BoxFit.contain,
              ),
          ),
      );
  }
}



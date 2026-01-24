import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../game/settings_manager.dart';
import '../game/audio_manager.dart';
import '../game/notification_manager.dart';
import '../game/localization_manager.dart';
import '../game/cloud_save_manager.dart';
import '../game/customization_manager.dart';
import '../game/progress_manager.dart';
import '../game/economy_manager.dart';
import '../game/network_manager.dart';
import '../game/privacy_manager.dart';
import '../theme/app_theme.dart';
import 'about_screen.dart';
import 'components/fast_page_route.dart';

class SettingsOverlay extends StatefulWidget {
  final SettingsManager settingsManager;
  final ProgressManager? progressManager;
  final VoidCallback onClose;

  const SettingsOverlay({super.key, required this.settingsManager, this.progressManager, required this.onClose});

  @override
  State<SettingsOverlay> createState() => _SettingsOverlayState();
}

class _SettingsOverlayState extends State<SettingsOverlay> {
  // Audio
  double _masterVol = 1.0;
  double _musicVol = 1.0;
  double _sfxVol = 1.0;
  double _ambientVol = 1.0;
  double _voiceVol = 1.0;
  bool _muteAll = false;
  bool _isSyncing = false;

  // Gameplay
  bool _autoStart = true;
  double _vibStrength = 1.0;
  bool _motorAssist = false;

  // Accessibility
  int _colorBlindIdx = 0;
  bool _bigText = false;
  bool _highContrast = false;
  bool _reducedGlow = false;

  // Notifications
  bool _notifDaily = true;
  bool _notifEvents = true;
  bool _notifReminders = true;

  // Privacy
  bool _analyticsOptOut = false;
  bool _adTrackingOptOut = false;

  String _langCode = 'tr';

  final List<String> _colorBlindOptions = ['Normal', 'Deuteranopia', 'Protanopia', 'Tritanopia'];
  final Map<String, String> _languages = {
    'tr': '🇹🇷 Türkçe', 'en': '🇬🇧 English',
  };

  int _expandedSection = 0; // 0=sound, 1=gameplay, 2=accessibility, 3=notif, 4=data, 5=language

  @override
  void initState() {
    super.initState();
    final s = widget.settingsManager;
    _masterVol = s.masterVolume;
    _musicVol = s.musicVolume;
    _sfxVol = s.sfxVolume;
    _ambientVol = s.ambientVolume;
    _voiceVol = s.voiceVolume;
    _autoStart = s.autoStartLevel;
    _vibStrength = s.vibrationStrength;
    _motorAssist = s.motorAssistEnabled;
    _colorBlindIdx = s.colorBlindIndex;
    _bigText = s.bigTextEnabled;
    _highContrast = s.highContrastEnabled;
    _analyticsOptOut = s.analyticsOptOut;
    _adTrackingOptOut = s.adTrackingOptOut;
    _langCode = s.languageCode;
    _muteAll = _masterVol == 0;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.black.withOpacity(0.7),
      child: Center(
        child: Material(
          color: Colors.transparent,
          child: Container(
            width: MediaQuery.of(context).size.width * 0.75,
            constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.8),
            decoration: BoxDecoration(
              color: PrismazeTheme.backgroundCard,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: PrismazeTheme.primaryPurple.withOpacity(0.4)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildHeader(),
                Flexible(
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                    shrinkWrap: true,
                    children: [
                      _buildSection(0, Icons.volume_up, LocalizationManager().getString('settings_section_audio'), _buildSoundSettings()),
                      _buildSection(1, Icons.gamepad, LocalizationManager().getString('settings_section_gameplay'), _buildGameplaySettings()),
                      _buildSection(2, Icons.accessibility, LocalizationManager().getString('settings_section_accessibility'), _buildAccessibilitySettings()),
                      _buildSection(3, Icons.notifications, LocalizationManager().getString('settings_section_notifications'), _buildNotificationSettings()),
                      _buildSection(4, Icons.storage, LocalizationManager().getString('settings_section_data'), _buildDataSettings()),
                      _buildSection(5, Icons.language, LocalizationManager().getString('settings_section_language'), _buildLanguageSettings()),
                      const SizedBox(height: 8),
                      _buildAboutButton(),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: PrismazeTheme.primaryPurple.withOpacity(0.2),
        borderRadius: const BorderRadius.only(topLeft: Radius.circular(16), topRight: Radius.circular(16)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () { AudioManager().playSfxId(SfxId.uiClick); widget.onClose(); },
            child: Padding(
              padding: const EdgeInsets.all(11), // 11 + 22 + 11 = 44px
              child: Icon(Icons.close, color: Colors.white70, size: 22),
            ),
          ),
          Text(LocalizationManager().getString('settings_title'), style: GoogleFonts.dynaPuff(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w800)),
          const SizedBox(width: 22),
        ],
      ),
    );
  }

  Widget _buildSection(int idx, IconData icon, String title, Widget content) {
    final isExpanded = _expandedSection == idx;
    return Column(
      children: [
        GestureDetector(
          onTap: () {
            AudioManager().playSfxId(SfxId.uiClick);
            setState(() => _expandedSection = isExpanded ? -1 : idx);
          },
          child: Container(
            margin: const EdgeInsets.only(top: 6),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            decoration: BoxDecoration(
              color: isExpanded ? PrismazeTheme.primaryPurple.withOpacity(0.15) : Colors.white.withOpacity(0.05),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Icon(icon, color: isExpanded ? PrismazeTheme.primaryPurpleLight : Colors.white60, size: 16),
                const SizedBox(width: 8),
                Expanded(child: Text(title, style: GoogleFonts.dynaPuff(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w600))),
                Icon(isExpanded ? Icons.expand_less : Icons.expand_more, color: Colors.white60, size: 18),
              ],
            ),
          ),
        ),
        AnimatedCrossFade(
          firstChild: const SizedBox.shrink(),
          secondChild: Padding(padding: const EdgeInsets.only(top: 6), child: content),
          crossFadeState: isExpanded ? CrossFadeState.showSecond : CrossFadeState.showFirst,
          duration: const Duration(milliseconds: 200),
        ),
      ],
    );
  }

  // SOUND SETTINGS
  Widget _buildSoundSettings() {
    return Column(
      children: [
        _sliderRow(LocalizationManager().getString('settings_audio_master'), _masterVol, (v) => setState(() => _masterVol = v), (v) { widget.settingsManager.setMasterVolume(v); AudioManager().setMasterVolume(v); AudioManager().updateBgmVolume(); }),
        _sliderRow(LocalizationManager().getString('settings_audio_music'), _musicVol, (v) => setState(() => _musicVol = v), (v) { widget.settingsManager.setMusicVolume(v); AudioManager().setMusicVolume(v); AudioManager().updateBgmVolume(); if (v > 0) AudioManager().setContext(AudioContext.menu); }),
        _sliderRow(LocalizationManager().getString('settings_audio_sfx'), _sfxVol, (v) => setState(() => _sfxVol = v), (v) { widget.settingsManager.setSfxVolume(v); AudioManager().setSfxVolume(v); }),
        _sliderRow(LocalizationManager().getString('settings_audio_ambient'), _ambientVol, (v) => setState(() => _ambientVol = v), (v) => widget.settingsManager.setAmbientVolume(v)),
        _sliderRow(LocalizationManager().getString('settings_audio_voice'), _voiceVol, (v) => setState(() => _voiceVol = v), (v) => widget.settingsManager.setVoiceVolume(v)),
        _toggleRow(LocalizationManager().getString('settings_audio_mute_all'), _muteAll, (v) {
          setState(() { _muteAll = v; _masterVol = v ? 0 : 1; });
          widget.settingsManager.setMasterVolume(v ? 0 : 1);
          AudioManager().setMasterVolume(v ? 0 : 1);
          if (v) {
            AudioManager().stopBgm();
          } else {
            AudioManager().updateBgmVolume();
            AudioManager().setContext(AudioContext.menu);
          }
        }),
      ],
    );
  }

  // GAMEPLAY SETTINGS
  Widget _buildGameplaySettings() {
    return Column(
      children: [
        _toggleRow(LocalizationManager().getString('settings_gameplay_autostart'), _autoStart, (v) { setState(() => _autoStart = v); widget.settingsManager.setAutoStartLevel(v); }),
        _buildVibrationStrength(),
        _toggleRow(LocalizationManager().getString('settings_gameplay_motor_assist'), _motorAssist, (v) { setState(() => _motorAssist = v); widget.settingsManager.setMotorAssist(v); }),
      ],
    );
  }

  Widget _buildVibrationStrength() {
    final options = [0.0, 0.5, 1.0, 1.5];
    final labels = ['Kapalı', '%50', '%100', '%150'];
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(LocalizationManager().getString('settings_gameplay_vibration'), style: GoogleFonts.dynaPuff(color: Colors.white70, fontSize: 10)),
          const SizedBox(height: 4),
          Row(
            children: List.generate(4, (i) {
              final isSelected = (_vibStrength - options[i]).abs() < 0.01;
              return Expanded(
                child: GestureDetector(
                  onTap: () { 
                    setState(() => _vibStrength = options[i]); 
                    widget.settingsManager.setVibrationStrength(options[i]);
                    AudioManager().setVibrationStrength(options[i]);
                    if (options[i] > 0) AudioManager().playSfxId(SfxId.uiClick); 
                  },
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 2),
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    decoration: BoxDecoration(
                      color: isSelected ? PrismazeTheme.primaryPurple.withOpacity(0.3) : Colors.white.withOpacity(0.05),
                      borderRadius: BorderRadius.circular(6),
                      border: isSelected ? Border.all(color: PrismazeTheme.primaryPurple) : null,
                    ),
                    child: Center(child: Text(labels[i], style: GoogleFonts.dynaPuff(color: Colors.white, fontSize: 9))),
                  ),
                ),
              );
            }),
          ),
        ],
      ),
    );
  }

  // ACCESSIBILITY SETTINGS
  Widget _buildAccessibilitySettings() {
    // Also using loop-based dropdown label mapping if needed, but here individual items:
    return Column(
      children: [
        _buildColorBlindDropdown(),
        _toggleRow(LocalizationManager().getString('settings_acc_big_text'), _bigText, (v) { setState(() => _bigText = v); widget.settingsManager.setBigText(v); }),
        _toggleRow(LocalizationManager().getString('settings_acc_high_contrast'), _highContrast, (v) { setState(() => _highContrast = v); widget.settingsManager.setHighContrast(v); }),
        _toggleRow(LocalizationManager().getString('settings_acc_reduced_glow'), widget.settingsManager.reducedGlowEnabled, (v) { 
             setState(() => _reducedGlow = v);
             widget.settingsManager.setReducedGlow(v); 
        }),
      ],
    );
  }

  Widget _buildColorBlindDropdown() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(child: Text(LocalizationManager().getString('settings_acc_colorblind'), style: GoogleFonts.dynaPuff(color: Colors.white70, fontSize: 10))),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                decoration: BoxDecoration(color: Colors.white.withOpacity(0.05), borderRadius: BorderRadius.circular(6)),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<int>(
                    value: _colorBlindIdx,
                    dropdownColor: PrismazeTheme.backgroundCard,
                    style: GoogleFonts.dynaPuff(color: Colors.white, fontSize: 10),
                    icon: Icon(Icons.arrow_drop_down, color: Colors.white60, size: 16),
                    items: _colorBlindOptions.asMap().entries.map((e) => DropdownMenuItem(value: e.key, child: Text(e.value))).toList(),
                    onChanged: (v) { if (v != null) { setState(() => _colorBlindIdx = v); widget.settingsManager.setColorBlindMode(v); } },
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          _buildColorPreview(_colorBlindIdx),
        ],
      ),
    );
  }

  Widget _buildColorPreview(int mode) {
    // Get colors directly from theme helper
    final primary = PrismazeTheme.getPaletteColor(mode, 'primary');
    final accent = PrismazeTheme.getPaletteColor(mode, 'accent');
    final success = PrismazeTheme.getPaletteColor(mode, 'success');
    final error = PrismazeTheme.getPaletteColor(mode, 'error');

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        _colorBox(primary, LocalizationManager().getString('preview_primary')),
        _colorBox(accent, LocalizationManager().getString('preview_accent')),
        _colorBox(success, LocalizationManager().getString('preview_success')),
        _colorBox(error, LocalizationManager().getString('preview_error')),
      ],
    );
  }

  Widget _colorBox(Color c, String label) {
    return Column(
      children: [
        Container(
          width: 30, height: 30,
          decoration: BoxDecoration(color: c, borderRadius: BorderRadius.circular(8), border: Border.all(color: Colors.white24)),
        ),
        const SizedBox(height: 2),
        Text(label, style: GoogleFonts.dynaPuff(color: Colors.white54, fontSize: 8)),
      ],
    );
  }

  // NOTIFICATION SETTINGS
  Widget _buildNotificationSettings() {
    return Column(
      children: [
        _toggleRow(LocalizationManager().getString('settings_notif_daily'), _notifDaily, (v) { 
            setState(() => _notifDaily = v); 
            widget.settingsManager.setNotifDaily(v);
            // Trigger update in NotificationManager
            NotificationManager().scheduleRetentionNotifications();
        }),
        _toggleRow(LocalizationManager().getString('settings_notif_events'), _notifEvents, (v) { 
            setState(() => _notifEvents = v); 
            widget.settingsManager.setNotifEvents(v);
        }),
        _toggleRow(LocalizationManager().getString('settings_notif_reminders'), _notifReminders, (v) { 
             setState(() => _notifReminders = v); 
             widget.settingsManager.setNotifReminders(v);
        }),
      ],
    );
  }

  // DATA SETTINGS
  Widget _buildDataSettings() {
    final isChildMode = PrivacyManager().isChildMode;
    
    return Column(
      children: [
        if (isChildMode)
          Container(
            padding: const EdgeInsets.all(8),
            margin: const EdgeInsets.only(bottom: 8),
            decoration: BoxDecoration(
              color: PrismazeTheme.primaryPurple.withOpacity(0.2),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: PrismazeTheme.primaryPurple.withOpacity(0.5)),
            ),
            child: Row(
              children: [
                Icon(Icons.child_care, color: Colors.white, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    LocalizationManager().getString('child_mode_active'),
                    style: GoogleFonts.dynaPuff(color: Colors.white, fontSize: 12),
                  ),
                ),
              ],
            ),
          ),
          
        Opacity(
          opacity: isChildMode ? 0.5 : 1.0,
          child: IgnorePointer(
            ignoring: isChildMode,
            child: Column(
              children: [
                _toggleRow(LocalizationManager().getString('settings_data_analytics'), PrivacyManager().analyticsEnabled, (v) { 
                     setState(() => _analyticsOptOut = !v); 
                     PrivacyManager().setAnalyticsEnabled(v);
                }),
                _toggleRow(LocalizationManager().getString('settings_data_ads'), PrivacyManager().adsPersonalized, (v) { 
                    setState(() => _adTrackingOptOut = !v);
                    PrivacyManager().setPersonalizedAds(v); 
                }),
              ],
            ),
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(child: _actionButton(LocalizationManager().getString('settings_data_export') ?? 'Verileri İndir', Icons.download, Colors.green, _exportData)),
            const SizedBox(width: 8),
            Expanded(child: _actionButton(LocalizationManager().getString('settings_data_delete_all'), Icons.delete_forever, PrismazeTheme.errorRed, _deleteAllData)),
          ],
        ),
        const SizedBox(height: 12),
        // Network Status & Screen
        StreamBuilder<ConnectionStatus>(
            stream: NetworkManager().statusStream,
            initialData: NetworkManager().isOnline ? ConnectionStatus.online : ConnectionStatus.offline,
            builder: (context, snapshot) {
                final isOnline = snapshot.data == ConnectionStatus.online;
                return Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                        color: Colors.black26,
                        borderRadius: BorderRadius.circular(8)
                    ),
                    child: Row(
                        children: [
                            Icon(isOnline ? Icons.wifi : Icons.wifi_off, 
                                 size: 14, 
                                 color: isOnline ? PrismazeTheme.successGreen : PrismazeTheme.errorRed),
                            const SizedBox(width: 8),
                            Expanded(
                                child: Text(
                                    isOnline ? LocalizationManager().getString('sync_online') : LocalizationManager().getString('sync_offline'),
                                    style: GoogleFonts.dynaPuff(color: Colors.white70, fontSize: 10)
                                )
                            ),
                            if (isOnline)
                                GestureDetector(
                                    onTap: _manualSync,
                                    child: Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                        decoration: BoxDecoration(
                                            border: Border.all(color: Colors.white24),
                                            borderRadius: BorderRadius.circular(12)
                                        ),
                                        child: _isSyncing 
                                            ? SizedBox(width: 10, height: 10, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) 
                                            : Text(LocalizationManager().getString('sync_now'), style: GoogleFonts.dynaPuff(color: Colors.white, fontSize: 9)),
                                    ),
                                )
                        ],
                    ),
                );
            }
        ),

      ],
    );
  }

  Future<void> _exportData() async {
    AudioManager().playSfxId(SfxId.uiClick);
    ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Veriler hazırlanıyor...'), duration: Duration(seconds: 1), backgroundColor: Colors.blue)
    );
    
    final result = await PrivacyManager().shareUserData();
    if (!mounted) return;
    
    if (!result) {
         ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Veri dışa aktarma başarısız.'), backgroundColor: Colors.red)
        );
    }
  }

  Future<void> _manualSync() async {
      if (_isSyncing) return;
      setState(() => _isSyncing = true);
      
      final result = await CloudSaveManager().syncProgress(
          ProgressManager(), // Note: Ideally pass instances or use GetIt/Riverpod
          EconomyManager() 
      );
      
      if (mounted) {
          setState(() => _isSyncing = false);
          if (result == SyncResult.success) {
              AudioManager().playSfxId(SfxId.achievementUnlocked);
          } else if (result == SyncResult.conflict) {
              AudioManager().playSfxId(SfxId.error);
              _showConflictDialog();
          } else {
              AudioManager().playSfxId(SfxId.error);
          }
      }
  }
  
  void _showConflictDialog() {
      showDialog(
        context: context,
        builder: (ctx) => _confirmDialog(
          "Veri Çakışması",
          "Buluttaki verileriniz ile cihazdaki verileriniz farklı görünüyor. Hangisini kullanmak istersiniz?",
          "Bulutu İndir",
          Colors.orange, 
          () async {
            Navigator.pop(ctx);
            // In a real app, logic to force-download would go here
            // CloudSaveManager().forceDownload();
            AudioManager().playSfxId(SfxId.achievementUnlocked);
          }
        ),
      );
  }

  Widget _actionButton(String label, IconData icon, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(color: color.withOpacity(0.15), borderRadius: BorderRadius.circular(8), border: Border.all(color: color.withOpacity(0.3))),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 14),
            const SizedBox(width: 4),
            Text(label, style: GoogleFonts.dynaPuff(color: color, fontSize: 9)),
          ],
        ),
      ),
    );
  }

  // LANGUAGE SETTINGS
  Widget _buildLanguageSettings() {
    return Wrap(
      spacing: 4,
      runSpacing: 4,
      children: _languages.entries.map((e) {
        final isSelected = _langCode == e.key;
        return GestureDetector(
          onTap: () {
            AudioManager().playSfxId(SfxId.uiClick);
            setState(() => _langCode = e.key);
            widget.settingsManager.setLanguage(e.key);
            LocalizationManager().setLanguage(e.key);
            _showLanguageChangeNotice();
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
            decoration: BoxDecoration(
              color: isSelected ? PrismazeTheme.primaryPurple.withOpacity(0.3) : Colors.white.withOpacity(0.05),
              borderRadius: BorderRadius.circular(6),
              border: isSelected ? Border.all(color: PrismazeTheme.primaryPurple) : null,
            ),
            child: Text(e.value, style: GoogleFonts.dynaPuff(color: Colors.white, fontSize: 10)),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildAboutButton() {
    return Column(
      children: [
        GestureDetector(
          onTap: () {
            AudioManager().playSfxId(SfxId.uiClick);
            Navigator.push(context, FastPageRoute(page: const AboutScreen()));
          },
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 10),
            decoration: BoxDecoration(color: Colors.white.withOpacity(0.05), borderRadius: BorderRadius.circular(8)),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.info_outline, color: Colors.white60, size: 14),
                const SizedBox(width: 6),
                Text(LocalizationManager().getString('settings_about'), style: GoogleFonts.dynaPuff(color: Colors.white70, fontSize: 11)),
              ],
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          "Debug: SM=${widget.settingsManager.hashCode} | Glow=${widget.settingsManager.reducedGlowEnabled}",
          style: const TextStyle(color: Colors.red, fontSize: 10, decoration: TextDecoration.none),
        ),
      ],
    );
  }

  // HELPERS
  Widget _sliderRow(String label, double val, Function(double) onChange, Function(double) onEnd) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          SizedBox(width: 80, child: Text(label, style: GoogleFonts.dynaPuff(color: Colors.white70, fontSize: 10))),
          Expanded(
            child: SliderTheme(
              data: SliderTheme.of(context).copyWith(
                activeTrackColor: PrismazeTheme.primaryPurple,
                inactiveTrackColor: Colors.white.withOpacity(0.1),
                thumbColor: Colors.white,
                overlayColor: Colors.transparent,
                trackHeight: 2,
                thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 4),
              ),
              child: Slider(value: val.clamp(0.0, 1.0), onChanged: onChange, onChangeEnd: onEnd),
            ),
          ),
          SizedBox(width: 28, child: Text('${(val * 100).toInt()}%', style: GoogleFonts.dynaPuff(color: Colors.white60, fontSize: 9))),
        ],
      ),
    );
  }

  Widget _toggleRow(String label, bool val, Function(bool) onChange) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Expanded(child: Text(label, style: GoogleFonts.dynaPuff(color: Colors.white70, fontSize: 10))),
          Transform.scale(
            scale: 0.7,
            child: Switch(value: val, onChanged: onChange, activeColor: PrismazeTheme.primaryPurple),
          ),
        ],
      ),
    );
  }

  void _restoreProgress() {
    AudioManager().playSfxId(SfxId.uiClick);
    showDialog(
      context: context,
      builder: (ctx) => _confirmDialog(
        LocalizationManager().getString('dialog_restore_title'),
        LocalizationManager().getString('dialog_restore_msg'),
        LocalizationManager().getString('btn_restore'),
        Colors.blue, 
        () async {
          Navigator.pop(ctx);
          final pm = ProgressManager(); await pm.init();
          final em = EconomyManager(); await em.init();
          await CloudSaveManager().syncProgress(pm, em);
        }
      ),
    );
  }

  void _deleteAllData() {
    AudioManager().playSfxId(SfxId.error);
    showDialog(
      context: context,
      builder: (ctx) => _confirmDialog(
        LocalizationManager().getString('dialog_delete_title'),
        LocalizationManager().getString('dialog_delete_msg'),
        LocalizationManager().getString('btn_delete'),
        PrismazeTheme.errorRed, () {
        Navigator.pop(ctx);
        _confirmDeleteSecond();
      }),
    );
  }

  void _confirmDeleteSecond() {
    showDialog(
      context: context,
      builder: (ctx) => _confirmDialog(
        LocalizationManager().getString('dialog_final_title'),
        LocalizationManager().getString('dialog_final_msg'),
        LocalizationManager().getString('btn_delete_backup'),
        PrismazeTheme.errorRed, () async {
        // 1. Use PrivacyManager to delete everything
        final success = await PrivacyManager().deleteAllUserData();
        
        if (!mounted) return;
        
        if (success) {
             // Close the dialog first
            Navigator.pop(ctx); 
            
            // Trigger MainMenu reload via callback (which handles navigation and reloading)
            widget.onClose();
        } else {
             ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Veri silme başarısız.'), backgroundColor: Colors.red)
            );
        }
      }),
    );
  }

  Widget _confirmDialog(String title, String msg, String confirmText, Color color, VoidCallback onConfirm) {
    return Center(
      child: Material(
        color: Colors.transparent,
        child: Container(
          margin: const EdgeInsets.all(40),
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: PrismazeTheme.backgroundCard,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: color.withOpacity(0.5)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(title, style: GoogleFonts.dynaPuff(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w800)),
              const SizedBox(height: 8),
              Text(msg, style: GoogleFonts.dynaPuff(color: Colors.white70, fontSize: 11), textAlign: TextAlign.center),
              const SizedBox(height: 16),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  GestureDetector(
                    onTap: () { AudioManager().playSfxId(SfxId.uiClick); Navigator.pop(context); },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                      decoration: BoxDecoration(color: Colors.white.withOpacity(0.1), borderRadius: BorderRadius.circular(16)),
                      child: Text(LocalizationManager().getString('btn_cancel'), style: GoogleFonts.dynaPuff(color: Colors.white70, fontSize: 10)),
                    ),
                  ),
                  const SizedBox(width: 12),
                  GestureDetector(
                    onTap: onConfirm,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                      decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(16)),
                      child: Text(confirmText, style: GoogleFonts.dynaPuff(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w700)),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showLanguageChangeNotice() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(Icons.language, color: Colors.white, size: 18),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                LocalizationManager().getString('language_change_notice'),
                style: GoogleFonts.dynaPuff(color: Colors.white, fontSize: 11),
              ),
            ),
          ],
        ),
        backgroundColor: PrismazeTheme.primaryPurple,
        duration: const Duration(seconds: 3),
      ),
    );
  }
}



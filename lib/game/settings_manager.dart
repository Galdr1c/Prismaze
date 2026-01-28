import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart';
import 'audio_manager.dart';

class SettingsManager extends ChangeNotifier {
  static final SettingsManager _instance = SettingsManager._internal();
  factory SettingsManager() => _instance;
  SettingsManager._internal() {
      print("SettingsManager: Created Instance (Hash: $hashCode)");
  }

  static const String keyLanguage = 'settings_language'; // Added
  static const String keyMasterVolume = 'settings_master_vol';
  static const String keyMusicVolume = 'settings_music_vol';
  static const String keySfxVolume = 'settings_sfx_vol';
  static const String keyAmbientVolume = 'settings_ambient_vol';
  static const String keyVoiceVolume = 'settings_voice_vol';
  static const String keyVibration = 'settings_vibration';
  static const String keyBigText = 'settings_big_text';
  static const String keyHighContrast = 'settings_high_contrast';

  static const String keyVibrationStrength = 'settings_vibration_strength';
  static const String keyNotifSettings = 'settings_notif_mode'; 
  static const String keyColorBlind = 'settings_color_blind'; 
  static const String keyReducedGlow = 'settings_reduced_glow';
  static const String keyNotifDaily = 'settings_notif_daily';
  static const String keyNotifEvents = 'settings_notif_events';
  static const String keyNotifReminders = 'settings_notif_reminders';

  static const String keyAnalyticsOptOut = 'privacy_analytics_opt_out';
  static const String keyAdTrackingOptOut = 'privacy_ad_tracking_opt_out';
  static const String keyBackgroundAudio = 'settings_background_audio';

  late SharedPreferences _prefs;
  String _languageCode = 'tr';
  
  // Audio Channels
  double _masterVolume = 1.0;
  double _musicVolume = 1.0;
  double _sfxVolume = 1.0;
  double _ambientVolume = 1.0;
  double _voiceVolume = 1.0;
  bool _vibrationEnabled = true;
  bool _allowBackgroundAudio = false; // When true, game music is off

  String _notifMode = 'all'; 
  int _colorBlindIndex = 0;
  bool _bigTextEnabled = false;
  bool _highContrastEnabled = false;
  double _vibrationStrength = 1.0; 
  
  bool _analyticsOptOut = false;
  bool _adTrackingOptOut = false;
  bool _reducedGlowEnabled = false;
  bool _notifDaily = true;
  bool _notifEvents = true;
  bool _notifReminders = true;

  // Getters - Audio
  double get masterVolume => _masterVolume;
  double get musicVolume => _musicVolume;
  double get sfxVolume => _sfxVolume;
  double get ambientVolume => _ambientVolume;
  double get voiceVolume => _voiceVolume;
  bool get vibrationEnabled => _vibrationEnabled;
  bool get allowBackgroundAudio => _allowBackgroundAudio;
  String get languageCode => _languageCode;
  
  // Getters - Other
  String get notifMode => _notifMode;
  int get colorBlindIndex => _colorBlindIndex;
  bool get bigTextEnabled => _bigTextEnabled;
  bool get highContrastEnabled => _highContrastEnabled;
  bool get reducedGlowEnabled => _reducedGlowEnabled;
  bool get notifDaily => _notifDaily;
  bool get notifEvents => _notifEvents;
  bool get notifReminders => _notifReminders;
  double get vibrationStrength => _vibrationStrength;
  bool get analyticsOptOut => _analyticsOptOut;
  bool get adTrackingOptOut => _adTrackingOptOut;
  
  // ... Init ...
  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
    
    // Audio
    _masterVolume = _prefs.getDouble(keyMasterVolume) ?? 1.0;
    _musicVolume = _prefs.getDouble(keyMusicVolume) ?? 1.0;
    _sfxVolume = _prefs.getDouble(keySfxVolume) ?? 1.0;
    _ambientVolume = _prefs.getDouble(keyAmbientVolume) ?? 1.0;
    _voiceVolume = _prefs.getDouble(keyVoiceVolume) ?? 1.0;
    _vibrationEnabled = _prefs.getBool(keyVibration) ?? true;
    _allowBackgroundAudio = _prefs.getBool(keyBackgroundAudio) ?? false;
    
    double savedVibe = _prefs.getDouble(keyVibrationStrength) ?? 1.0;
    _vibrationStrength = savedVibe;

    _languageCode = _prefs.getString(keyLanguage) ?? 'tr';
    _notifMode = _prefs.getString(keyNotifSettings) ?? 'all';
    _colorBlindIndex = _prefs.getInt(keyColorBlind) ?? 0;
    _bigTextEnabled = _prefs.getBool(keyBigText) ?? false;
    _highContrastEnabled = _prefs.getBool(keyHighContrast) ?? false;
    _reducedGlowEnabled = _prefs.getBool(keyReducedGlow) ?? true; // Default to TRUE for performance
    _notifDaily = _prefs.getBool(keyNotifDaily) ?? true;
    _notifEvents = _prefs.getBool(keyNotifEvents) ?? true;
    _notifReminders = _prefs.getBool(keyNotifReminders) ?? true;
    _snapToGrid = _prefs.getBool(keySnapToGrid) ?? false;
    _debugModeEnabled = _prefs.getBool(keyDebugMode) ?? false;
    
    print("SettingsManager: Loading prefs... (Hash: $hashCode)");
    _analyticsOptOut = _prefs.getBool(keyAnalyticsOptOut) ?? false;
    _adTrackingOptOut = _prefs.getBool(keyAdTrackingOptOut) ?? false;
    print("SettingsManager: Loaded Reduced Glow: $_reducedGlowEnabled");
    print("SettingsManager: Loaded Master Volume: $_masterVolume");
    print("SettingsManager: Loaded Debug Mode: $_debugModeEnabled");
  }
  
  // ... Setters ...
  
  Future<void> setReducedGlow(bool enabled) async {
      print("SettingsManager: Setting Reduced Glow to $enabled");
      _reducedGlowEnabled = enabled;
      await _prefs.setBool(keyReducedGlow, enabled);
      notifyListeners();
  }
  
  Future<void> setNotifDaily(bool enabled) async {
      _notifDaily = enabled;
      await _prefs.setBool(keyNotifDaily, enabled);
      notifyListeners();
  }
  
  Future<void> setNotifEvents(bool enabled) async {
      _notifEvents = enabled;
      await _prefs.setBool(keyNotifEvents, enabled);
      notifyListeners();
  }
  
  Future<void> setNotifReminders(bool enabled) async {
      _notifReminders = enabled;
      await _prefs.setBool(keyNotifReminders, enabled);
      notifyListeners();
  }
  
  Future<void> setAnalyticsOptOut(bool optOut) async {
      _analyticsOptOut = optOut;
      await _prefs.setBool(keyAnalyticsOptOut, optOut);
      notifyListeners();
  }
  
  Future<void> setAdTrackingOptOut(bool optOut) async {
      _adTrackingOptOut = optOut;
      await _prefs.setBool(keyAdTrackingOptOut, optOut);
      notifyListeners();
  }

  Future<void> setVibrationStrength(double strength) async {
      _vibrationStrength = strength;
      await _prefs.setDouble(keyVibrationStrength, strength);
      notifyListeners();
  }
  
  Future<void> setBigText(bool enabled) async {
      _bigTextEnabled = enabled;
      await _prefs.setBool(keyBigText, enabled);
      notifyListeners();
  }
  
  Future<void> setHighContrast(bool enabled) async {
      _highContrastEnabled = enabled;
      await _prefs.setBool(keyHighContrast, enabled);
      notifyListeners();
  }

  Future<void> setColorBlindMode(int index) async {
      _colorBlindIndex = index;
      await _prefs.setInt(keyColorBlind, index);
      notifyListeners();
  }
  
  Future<void> setNotificationMode(String mode) async {
      _notifMode = mode;
      await _prefs.setString(keyNotifSettings, mode);
      notifyListeners();
  }
  
  // ... (Audio setters)
  Future<void> setMasterVolume(double vol) async {
      _masterVolume = vol;
      await _prefs.setDouble(keyMasterVolume, vol);
      notifyListeners();
  }
  
  Future<void> setMusicVolume(double vol) async {
      _musicVolume = vol;
      await _prefs.setDouble(keyMusicVolume, vol);
      notifyListeners();
  }
  
  Future<void> setSfxVolume(double vol) async {
      _sfxVolume = vol;
      await _prefs.setDouble(keySfxVolume, vol);
      notifyListeners();
  }
  
  Future<void> setAmbientVolume(double vol) async {
      _ambientVolume = vol;
      await _prefs.setDouble(keyAmbientVolume, vol);
      notifyListeners();
  }
  
  Future<void> setVoiceVolume(double vol) async {
      _voiceVolume = vol;
      await _prefs.setDouble(keyVoiceVolume, vol);
      notifyListeners();
  }
  
  Future<void> setAllowBackgroundAudio(bool allow) async {
      _allowBackgroundAudio = allow;
      await _prefs.setBool(keyBackgroundAudio, allow);
      notifyListeners();
  }
  
  Future<void> setVibration(bool enabled) async {
      _vibrationEnabled = enabled;
      await _prefs.setBool(keyVibration, enabled);
      notifyListeners();
  }
  
  Future<void> setLanguage(String code) async {
      _languageCode = code;
      await _prefs.setString(keyLanguage, code);
      notifyListeners();
  }
  
  // Snap To Grid
  static const String keySnapToGrid = 'settings_snap_to_grid';
  bool _snapToGrid = false;
  bool get snapToGrid => _snapToGrid;
  
  Future<void> setSnapToGrid(bool enabled) async {
      _snapToGrid = enabled;
      await _prefs.setBool(keySnapToGrid, enabled);
      notifyListeners();
  }
  
  // Debug Mode (Developer)
  static const String keyDebugMode = 'settings_debug_mode';
  bool _debugModeEnabled = false;
  bool get debugModeEnabled => _debugModeEnabled;
  
  Future<void> setDebugMode(bool enabled) async {
      _debugModeEnabled = enabled;
      await _prefs.setBool(keyDebugMode, enabled);
      notifyListeners();
  }
}


import 'dart:async';
import 'package:flame_audio/flame_audio.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/services.dart';

class AudioManager {
  static final AudioManager _instance = AudioManager._internal();
  factory AudioManager() => _instance;
  AudioManager._internal();

  bool _isMuted = false;
  
  // Volume Channels
  double _masterVolume = 1.0;
  double _musicVolume = 1.0;
  double _sfxVolume = 1.0;
  double _ambientVolume = 1.0;
  double _voiceVolume = 1.0;
  bool _vibrationEnabled = true;

  // Asset Mapping for Legacy Calls
  static const Map<String, String> sfxMapping = {
    'whoosh.mp3': 'mirror_move_sound.mp3',
    'click.mp3': 'crystal_tap_sound.mp3',
    'tap.mp3': 'crystal_tap_sound.mp3',
    'ding.mp3': 'target_hit_sound.mp3',
    'win.mp3': 'level_complete_sound.mp3',
    'victory.mp3': 'victory.mp3',
    'power_up.mp3': 'light_reflection_sound.mp3', // Map power_up to light reflection
    'coin.mp3': 'coin_collect.mp3',
    'error.mp3': 'error_sound.mp3',
    'star.mp3': 'star_earned.mp3',
    'unlock.mp3': 'achievement_unlock.mp3',
    'confetti.mp3': 'confetti.mp3',
  };

  Future<void> init() async {
      // Any async init
  }

  // Preload assets
  Future<void> loadAssets() async {
    try {
      await FlameAudio.audioCache.loadAll([
        '1-50_level_bgm.mp3',
        '50-100_level_bgm.mp3', 
        '100-200_level_bgm.mp3',
        'achievement_unlock.mp3',
        'achievement_unlocked.mp3',
        'coin_collect.mp3',
        'color_mixing_sound.mp3',
        'confetti.mp3',
        'crystal_move_sound.mp3',
        'crystal_tap_sound.mp3',
        'daily_quest_complete.mp3',
        'error_sound.mp3',
        'frozen_event_bgm.mp3',
        'hallowen_event_bgm.mp3',
        'level_complete_sound.mp3',
        'light_reflection_sound.mp3',
        'main_menu_sound.mp3',
        'main_menu_sound2.mp3',
        'menu_open.mp3',
        'mirror_move_sound.mp3',
        'mirror_tap_sound.mp3',
        'mobile_notification.mp3',
        'pop_up_sound.mp3',
        'rare_item_unlocked.mp3',
        'star_earned.mp3',
        'starting_sound.mp3',
        'summer_event_bgm.mp3',
        'target_hit_sound.mp3',
        'token_spent_sound.mp3',
        'victory.mp3',
        'wrong_color_sound.mp3'
      ]);
      print("AudioManager: Assets loaded successfully.");
    } catch (e) { print("Audio assets error: $e"); }
  }
  
  // Setters
  void setMasterVolume(double vol) => _masterVolume = vol.clamp(0.0, 1.0);
  void setMusicVolume(double vol) => _musicVolume = vol.clamp(0.0, 1.0);
  void setSfxVolume(double vol) => _sfxVolume = vol.clamp(0.0, 1.0);
  void setAmbientVolume(double vol) => _ambientVolume = vol.clamp(0.0, 1.0);
  void setVoiceVolume(double vol) => _voiceVolume = vol.clamp(0.0, 1.0);
  void setVibration(bool enabled) => _vibrationEnabled = enabled;
  
  // Effective volume (applies master)
  double get effectiveMusicVolume => _masterVolume * _musicVolume;
  double get effectiveSfxVolume => _masterVolume * _sfxVolume;
  double get effectiveAmbientVolume => _masterVolume * _ambientVolume;
  double get effectiveVoiceVolume => _masterVolume * _voiceVolume;

  // Background audio mode (player's own music)
  bool allowBackgroundAudio = false;

  // Track names for re-looping
  String? _currentMenuTrack;
  String? _currentGameTrack;
  AudioPlayer? _menuPlayer;
  AudioPlayer? _gamePlayer;
  bool _menuMusicActive = false;  // Flag to prevent restart
  bool _gameMusicActive = false;  // Flag for game music
  bool _musicChanging = false;    // Mutex to prevent concurrent calls
  
  // Subscription cleanup to prevent memory leaks
  StreamSubscription? _menuLoopSub;
  StreamSubscription? _gameLoopSub;

  Future<void> playMenuMusic() async {
    if (allowBackgroundAudio) return;
    if (_musicChanging) return; // Prevent concurrent calls
    
    _musicChanging = true;
    
    try {
      // Stop gameplay music first
      if (_gamePlayer != null) {
        try {
          await _gamePlayer!.stop();
          await _gamePlayer!.dispose();
        } catch(e) {}
        _gamePlayer = null;
        _currentGameTrack = null;
        _gameMusicActive = false;
      }
      
      // If menu music is already active and player is still playing, just update volume
      if (_menuMusicActive && _menuPlayer != null) {
        final state = _menuPlayer!.state;
        if (state == PlayerState.playing || state == PlayerState.paused) {
          await _menuPlayer!.setVolume(0.5 * effectiveMusicVolume);
          _musicChanging = false;
          return;
        }
        // Player stopped unexpectedly - will recreate below
        print("Menu player stopped unexpectedly, recreating...");
      }
      
      if (effectiveMusicVolume <= 0) {
        _musicChanging = false;
        return;
      }

      if (FlameAudio.bgm.isPlaying) FlameAudio.bgm.stop();
      
      // Dispose old player if exists
      if (_menuPlayer != null) {
        try { await _menuPlayer!.dispose(); } catch(e) {}
        _menuPlayer = null;
      }
      
      _currentMenuTrack = 'main_menu_sound2.mp3';
      _menuMusicActive = true;
      
      // Create dedicated player for menu music
      _menuPlayer = AudioPlayer();
      await _menuPlayer!.setReleaseMode(ReleaseMode.stop); // Don't auto-release
      await _menuPlayer!.setSource(AssetSource('audio/$_currentMenuTrack'));
      await _menuPlayer!.setVolume(0.5 * effectiveMusicVolume);
      await _menuPlayer!.resume();
      
      print("Menu music started: $_currentMenuTrack");
      
      // Cancel old subscription before adding new one
      await _menuLoopSub?.cancel();
      
      // Loop only after track completes
      _menuLoopSub = _menuPlayer!.onPlayerComplete.listen((_) async {
        if (_currentMenuTrack != null && _menuPlayer != null && _menuMusicActive) {
          try {
            await _menuPlayer!.seek(Duration.zero);
            await _menuPlayer!.resume();
            print("Menu music looped");
          } catch(e) {
            print("Menu loop error: $e");
          }
        }
      });
    } catch(e) { 
      print("Menu Music Error: $e"); 
      _menuMusicActive = false;
    }
    
    _musicChanging = false;
  }

  Future<void> playGameplayMusic(int levelId) async {
    if (allowBackgroundAudio) return;
    if (_musicChanging) return; // Prevent concurrent calls
    
    _musicChanging = true;
    
    try {
      // Stop menu music first
      if (_menuPlayer != null) {
        try {
          await _menuPlayer!.stop();
          await _menuPlayer!.dispose();
        } catch(e) {}
        _menuPlayer = null;
        _currentMenuTrack = null;
        _menuMusicActive = false;
      }
      
      if (effectiveMusicVolume <= 0) {
        _musicChanging = false;
        return;
      }

      String track;
      if (levelId <= 50) track = '1-50_level_bgm.mp3';
      else if (levelId <= 100) track = '50-100_level_bgm.mp3';
      else track = '100-200_level_bgm.mp3';

      // If same track is already playing, just update volume
      if (_gameMusicActive && _currentGameTrack == track && _gamePlayer != null) {
        _gamePlayer!.setVolume(0.4 * effectiveMusicVolume);
        _musicChanging = false;
        return;
      }

      // Stop old game music if different track
      if (_gamePlayer != null) {
        try {
          await _gamePlayer!.stop();
          await _gamePlayer!.dispose();
        } catch(e) {}
        _gamePlayer = null;
      }

      _currentGameTrack = track;
      _gameMusicActive = true;
      
      // Create dedicated player for game music
      _gamePlayer = AudioPlayer();
      await _gamePlayer!.setReleaseMode(ReleaseMode.stop);
      await _gamePlayer!.setSource(AssetSource('audio/$track'));
      await _gamePlayer!.setVolume(0.4 * effectiveMusicVolume);
      await _gamePlayer!.resume();
      
      // Cancel old subscription before adding new one
      await _gameLoopSub?.cancel();
      
      // Loop only after track completes
      _gameLoopSub = _gamePlayer!.onPlayerComplete.listen((_) async {
        if (_currentGameTrack != null && _gamePlayer != null && _gameMusicActive) {
          try {
            await _gamePlayer!.seek(Duration.zero);
            await _gamePlayer!.resume();
          } catch(e) {
            print("Game loop error: $e");
          }
        }
      });
    } catch(e) { 
      print("Game Music Error: $e"); 
    }
    
    _musicChanging = false;
  }
  
  void updateBgmVolume() {
     _menuPlayer?.setVolume(0.5 * effectiveMusicVolume);
     _gamePlayer?.setVolume(0.4 * effectiveMusicVolume);
  }

  void stopAllMusic() async {
    try {
      await _menuPlayer?.stop();
      await _menuPlayer?.dispose();
    } catch(e) {}
    try {
      await _gamePlayer?.stop();
      await _gamePlayer?.dispose();
    } catch(e) {}
    _menuPlayer = null;
    _gamePlayer = null;
    _menuMusicActive = false;
    _gameMusicActive = false;
    _currentMenuTrack = null;
    _currentGameTrack = null;
    FlameAudio.bgm.stop();
  }

  // Legacy Wrappers
  void playMenuBgm() => playMenuMusic();
  void playGameBgm(int levelId) => playGameplayMusic(levelId);
  void stopBgm() => stopAllMusic();

  // --- SFX (using FlameAudio for better audio context management) ---
  
  void playSfx(String file, {double volume = 1.0}) {
    if (_isMuted || effectiveSfxVolume <= 0) return;
    
    // Map legacy/logical names to actual files
    String actualFile = sfxMapping[file] ?? file;
    
    // Use FlameAudio for SFX - handles audio context properly
    try {
      FlameAudio.play(actualFile, volume: volume * effectiveSfxVolume);
    } catch(e) {
      print("SFX Error ($file -> $actualFile): $e");
    }
  }
  
  // Pool initialization (kept for compatibility but not used)
  Future<void> initSfxPool() async {
    // SFX now uses FlameAudio instead of pooled players
    // to avoid audio focus conflicts with music
    print("AudioManager: SFX using FlameAudio (no pool)");
  }
  
  // Ambient sounds
  void playAmbient(String file, {double volume = 0.3}) {
      // Logic for ambient if needed, e.g. 'frozen_event_bgm.mp3' as ambient?
  }
  
  // Voice/Tutorial narration
  void playVoice(String file, {double volume = 1.0}) {
    if (_isMuted || effectiveVoiceVolume <= 0) return;
    try {
      FlameAudio.play(file, volume: volume * effectiveVoiceVolume);
    } catch(e) {}
  }
  
  // --- Haptics ---
  
  double _vibrationStrength = 1.0;

  void setVibrationStrength(double str) => _vibrationStrength = str;

  void vibrate() {
      if (!_vibrationEnabled || _vibrationStrength <= 0) return;
      if (_vibrationStrength < 0.8) HapticFeedback.lightImpact();
      else if (_vibrationStrength > 1.2) HapticFeedback.heavyImpact();
      else HapticFeedback.mediumImpact();
  }
  
  void vibratePrismHold() {
      if (!_vibrationEnabled || _vibrationStrength <= 0) return;
      HapticFeedback.selectionClick();
  }
  
  void vibrateCorrectTarget() {
      if (!_vibrationEnabled || _vibrationStrength <= 0) return;
      if (_vibrationStrength > 1.2) HapticFeedback.heavyImpact();
      else HapticFeedback.mediumImpact();
  }
  
  void vibrateWrongMove() {
       if (!_vibrationEnabled || _vibrationStrength <= 0) return;
       if (_vibrationStrength > 0.5) HapticFeedback.vibrate(); 
  }
  
  Future<void> vibrateLevelComplete() async {
      if (!_vibrationEnabled || _vibrationStrength <= 0) return;
      if (_vibrationStrength > 1.2) {
          await HapticFeedback.heavyImpact();
          await Future.delayed(const Duration(milliseconds: 100));
          await HapticFeedback.heavyImpact();
      } else {
          await HapticFeedback.mediumImpact();
          await Future.delayed(const Duration(milliseconds: 100));
          await HapticFeedback.mediumImpact();
      }
  }
  
  Future<void> vibrateHint() async {
      if (!_vibrationEnabled || _vibrationStrength <= 0) return;
      for(int i=0; i<3; i++) {
          HapticFeedback.lightImpact();
          await Future.delayed(const Duration(milliseconds: 100));
      }
  }
  
  void vibrateStar(int index) {
      if (!_vibrationEnabled || _vibrationStrength <= 0) return;
      if (index == 0) HapticFeedback.selectionClick();
      else if (index == 1) HapticFeedback.lightImpact();
      else HapticFeedback.mediumImpact();
  }

  void toggleMute() {
    _isMuted = !_isMuted;
    if (_isMuted) {
      stopBgm();
    } else {
      playMenuBgm();
    }
  }
}


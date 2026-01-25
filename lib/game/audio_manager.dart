/// Centralized Audio Manager
/// 
/// Single source of truth for all audio playback.
/// Uses enum-based API to prevent raw filename usage.
/// Supports stoppable SFX, context switching, and cooldown/maxInstances.
library;

import 'dart:async';
import 'package:flame_audio/flame_audio.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:audioplayers/audioplayers.dart' as ap;
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';

/// Audio context for automatic BGM/SFX management.
enum AudioContext { menu, gameplay }

/// Background music identifiers.
enum BgmId {
  menu,
  level1_50,
  level50_100,
  level100_200,
  eventSummer,
  eventHalloween,
  eventFrozen,
}

/// Sound effect identifiers.
enum SfxId {
  uiClick,
  uiOpenMenu,
  mirrorTap,
  mirrorMove,
  prismTap,
  prismRotate,
  targetHit,
  wrongColor,
  colorMix,
  coin,
  tokenSpent,
  error,
  starEarned,
  levelComplete,
  victory,
  confetti,
  achievementUnlock,
  achievementUnlocked,
  dailyQuestComplete,
  notification,
  popup,
  rareItemUnlocked,
  start,
  lightReflection,
}

/// Centralized audio manager - singleton.
class AudioManager {
  static final AudioManager _instance = AudioManager._internal();
  factory AudioManager() => _instance;
  AudioManager._internal();

  // === VOLUME CONTROLS ===
  double _masterVolume = 1.0;
  double _musicVolume = 0.8;
  double _sfxVolume = 0.9;
  double _ambientVolume = 0.5;
  double _voiceVolume = 1.0;
  bool _vibrationEnabled = true;
  double _vibrationStrength = 1.0;

  // === BGM STATE ===
  AudioPlayer? _bgmPlayer;
  BgmId? _currentBgm;
  bool _bgmLoading = false;

  // === SFX STATE ===
  final Map<SfxId, Set<AudioPlayer>> _activeSfx = {};
  final Map<SfxId, DateTime> _lastPlayTime = {};
  
  /// Debug: Get total active SFX player count
  int get debugActiveSfxCount => _activeSfx.values.fold(0, (sum, set) => sum + set.length);

  // === CENTRAL PATH MAPPINGS ===
  static const Map<BgmId, String> _bgmPaths = {
    BgmId.menu: 'audio/bgm/main_menu_sound2.mp3',
    BgmId.level1_50: 'audio/bgm/1-50_level_bgm.mp3',
    BgmId.level50_100: 'audio/bgm/50-100_level_bgm.mp3',
    BgmId.level100_200: 'audio/bgm/100-200_level_bgm.mp3',
    BgmId.eventSummer: 'audio/bgm/summer_event_bgm.mp3',
    BgmId.eventHalloween: 'audio/bgm/hallowen_event_bgm.mp3',
    BgmId.eventFrozen: 'audio/bgm/frozen_event_bgm.mp3',
  };

  static const Map<SfxId, String> _sfxPaths = {
    SfxId.uiClick: 'audio/sfx/soft_button_click.mp3',
    SfxId.uiOpenMenu: 'audio/sfx/menu_open.mp3',
    SfxId.mirrorTap: 'audio/sfx/mirror_tap_sound.mp3',
    SfxId.mirrorMove: 'audio/sfx/mirror_move_sound.mp3',
    SfxId.prismTap: 'audio/sfx/crystal_tap_sound.mp3',
    SfxId.prismRotate: 'audio/sfx/crystal_move_sound.mp3',
    SfxId.targetHit: 'audio/sfx/target_hit_sound.mp3',
    SfxId.wrongColor: 'audio/sfx/wrong_color_sound.mp3',
    SfxId.colorMix: 'audio/sfx/color_mixing_sound.mp3',
    SfxId.coin: 'audio/sfx/coin_collect.mp3',
    SfxId.tokenSpent: 'audio/sfx/token_spent_sound.mp3',
    SfxId.error: 'audio/sfx/error_sound.mp3',
    SfxId.starEarned: 'audio/sfx/star_earned.mp3',
    SfxId.levelComplete: 'audio/sfx/level_complete_sound.mp3',
    SfxId.victory: 'audio/sfx/victory.mp3',
    SfxId.confetti: 'audio/sfx/confetti.mp3',
    SfxId.achievementUnlock: 'audio/sfx/achievement_unlock.mp3',
    SfxId.achievementUnlocked: 'audio/sfx/achievement_unlocked.mp3',
    SfxId.dailyQuestComplete: 'audio/sfx/daily_quest_complete.mp3',
    SfxId.notification: 'audio/sfx/mobile_notification.mp3',
    SfxId.popup: 'audio/sfx/pop_up_sound.mp3',
    SfxId.rareItemUnlocked: 'audio/sfx/rare_item_unlocked.mp3',
    SfxId.start: 'audio/sfx/starting_sound.mp3',
    SfxId.lightReflection: 'audio/sfx/light_reflection_sound.mp3',
  };

  // === COOLDOWN / MAX INSTANCES POLICIES ===
  static const Map<SfxId, int> _cooldownMs = {
    SfxId.uiClick: 40,
    SfxId.mirrorTap: 60,
    SfxId.prismTap: 60,
    SfxId.starEarned: 200,
    SfxId.targetHit: 100,
    SfxId.wrongColor: 150,
    SfxId.coin: 50,
  };

  static const Map<SfxId, int> _maxInstances = {
    SfxId.uiClick: 2,
    SfxId.mirrorTap: 2,
    SfxId.prismTap: 2,
    SfxId.starEarned: 1,
    SfxId.levelComplete: 1,
    SfxId.victory: 1,
    SfxId.targetHit: 3,
    SfxId.coin: 3,
  };

  // === LEGACY FILENAME MAPPING ===
  static const Map<String, SfxId> _legacyMap = {
    'soft_button_click.mp3': SfxId.uiClick,
    'whoosh.mp3': SfxId.mirrorMove,
    'ding.mp3': SfxId.targetHit,
    'win.mp3': SfxId.levelComplete,
    'power_up.mp3': SfxId.colorMix,
    'success.mp3': SfxId.achievementUnlocked,
    'trash.mp3': SfxId.popup,
    'rotate.mp3': SfxId.prismRotate,
    'mirror_tap_sound.mp3': SfxId.mirrorTap,
    'crystal_tap_sound.mp3': SfxId.prismTap,
    'star_earned.mp3': SfxId.starEarned,
    'coin_collect.mp3': SfxId.coin,
    'level_complete_sound.mp3': SfxId.levelComplete,
    'victory.mp3': SfxId.victory,
    'error_sound.mp3': SfxId.error,
  };

  // === INITIALIZATION ===
  Future<void> init() async {
    // Configure global audio context to allow mixing (prevents SFX from stopping BGM)
    final audioContext = ap.AudioContext(
      iOS: ap.AudioContextIOS(
        category: ap.AVAudioSessionCategory.playback,
        options: {ap.AVAudioSessionOptions.mixWithOthers},
      ),
      android: ap.AudioContextAndroid(
        isSpeakerphoneOn: true,
        stayAwake: true,
        contentType: ap.AndroidContentType.sonification,
        usageType: ap.AndroidUsageType.game,
        audioFocus: ap.AndroidAudioFocus.none, 
      ),
    );
    await ap.AudioPlayer.global.setAudioContext(audioContext);

    _bgmPlayer = AudioPlayer();
    _bgmPlayer!.setReleaseMode(ReleaseMode.loop);
    debugPrint('AudioManager: Initialized');
  }

  /// Preload minimal frequently-used assets to reduce stutter.
  Future<void> loadAssets() async {
    const preloadSfx = [
      SfxId.uiClick,
      SfxId.error,
      SfxId.mirrorTap,
      SfxId.prismTap,
      SfxId.targetHit,
      SfxId.starEarned,
      SfxId.levelComplete,
      SfxId.coin,
    ];

    for (final id in preloadSfx) {
      final path = _sfxPaths[id];
      if (path != null) {
        try {
          // FlameAudio assumes 'audio/' prefix, so strip it from our keys
          final effectivePath = path.replaceFirst('audio/', '');
          await FlameAudio.audioCache.load(effectivePath);
        } catch (e) {
          debugPrint('AudioManager: Failed to preload $path: $e');
        }
      }
    }

    // Preload menu BGM
    try {
      final bgmPath = _bgmPaths[BgmId.menu]!;
      final effectiveBgmPath = bgmPath.replaceFirst('audio/', '');
      await FlameAudio.audioCache.load(effectiveBgmPath);
    } catch (e) {
      debugPrint('AudioManager: Failed to preload menu BGM: $e');
    }

    debugPrint('AudioManager: Preloaded ${preloadSfx.length} SFX + menu BGM');
  }

  // === VOLUME SETTERS ===
  void setMasterVolume(double vol) => _masterVolume = vol.clamp(0.0, 1.0);
  void setMusicVolume(double vol) { _musicVolume = vol.clamp(0.0, 1.0); updateBgmVolume(); }
  void setSfxVolume(double vol) => _sfxVolume = vol.clamp(0.0, 1.0);
  void setAmbientVolume(double vol) => _ambientVolume = vol.clamp(0.0, 1.0);
  void setVoiceVolume(double vol) => _voiceVolume = vol.clamp(0.0, 1.0);
  void setVibration(bool enabled) => _vibrationEnabled = enabled;
  void setVibrationStrength(double str) => _vibrationStrength = str.clamp(0.0, 1.0);

  double get effectiveMusicVolume => _masterVolume * _musicVolume;
  double get effectiveSfxVolume => _masterVolume * _sfxVolume;

  // === CONTEXT SWITCHING ===
  /// Switch audio context (stops all SFX, changes BGM appropriately).
  Future<void> setContext(AudioContext ctx, {int? levelId}) async {
    stopAllSfx();

    switch (ctx) {
      case AudioContext.menu:
        await playBgm(BgmId.menu);
        break;
      case AudioContext.gameplay:
        final bgm = _getBgmForLevel(levelId ?? 1);
        await playBgm(bgm);
        break;
    }

    debugPrint('AudioManager: Context set to ${ctx.name}');
  }

  BgmId _getBgmForLevel(int levelId) {
    if (levelId <= 50) return BgmId.level1_50;
    if (levelId <= 100) return BgmId.level50_100;
    return BgmId.level100_200;
  }

  // === BGM PLAYBACK ===
  Future<void> playBgm(BgmId id) async {
    if (_bgmLoading) return;
    if (_currentBgm == id && _bgmPlayer?.state == PlayerState.playing) return;

    _bgmLoading = true;
    try {
      final path = _bgmPaths[id];
      if (path == null) {
        debugPrint('AudioManager: Unknown BGM $id');
        return;
      }

      await _bgmPlayer?.stop();
      _currentBgm = id;

      await _bgmPlayer?.setSource(AssetSource(path));
      await _bgmPlayer?.setVolume(effectiveMusicVolume);
      await _bgmPlayer?.resume();

      debugPrint('AudioManager: Playing BGM $id');
    } catch (e) {
      debugPrint('AudioManager: Failed to play BGM $id: $e');
    } finally {
      _bgmLoading = false;
    }
  }

  void stopBgm() {
    _bgmPlayer?.stop();
    _currentBgm = null;
    debugPrint('AudioManager: BGM stopped');
  }

  void updateBgmVolume() {
    _bgmPlayer?.setVolume(effectiveMusicVolume);
  }

  // === LEGACY WRAPPERS (for backward compatibility) ===
  void playMenuMusic() => setContext(AudioContext.menu);
  void playGameplayMusic(int levelId) => setContext(AudioContext.gameplay, levelId: levelId);
  void playMenuBgm() => setContext(AudioContext.menu);
  void playGameBgm(int levelId) => setContext(AudioContext.gameplay, levelId: levelId);

  void stopAllMusic() {
    stopBgm();
    stopAllSfx();
  }

  // === SFX PLAYBACK (STOPPABLE) ===
  /// Play SFX by enum ID (preferred).
  Future<void> playSfxId(SfxId id, {double? volume}) async {
    final path = _sfxPaths[id];
    if (path == null) {
      debugPrint('AudioManager: Unknown SFX $id');
      return;
    }

    // Cooldown check
    final cooldown = _cooldownMs[id] ?? 0;
    if (cooldown > 0) {
      final lastTime = _lastPlayTime[id];
      if (lastTime != null) {
        final elapsed = DateTime.now().difference(lastTime).inMilliseconds;
        if (elapsed < cooldown) return;
      }
    }

    // Max instances check
    final maxInst = _maxInstances[id] ?? 5;
    final active = _activeSfx[id] ?? {};
    if (active.length >= maxInst) {
      // Kill oldest
      if (active.isNotEmpty) {
        final oldest = active.first;
        await oldest.stop();
        await oldest.dispose();
        active.remove(oldest);
      }
    }

    _lastPlayTime[id] = DateTime.now();

    try {
      final player = AudioPlayer();
      await player.setSource(AssetSource(path));
      await player.setVolume((volume ?? 1.0) * effectiveSfxVolume);
      
      _activeSfx[id] = active..add(player);

      player.onPlayerComplete.listen((_) async {
        _activeSfx[id]?.remove(player);
        await player.dispose();
      });

      await player.resume();
    } catch (e) {
      debugPrint('AudioManager: Failed to play SFX $id: $e');
    }
  }

  /// Legacy playSfx with raw filename (deprecated, use playSfxId).
  @Deprecated('Use playSfxId with SfxId enum instead')
  Future<void> playSfx(String file, {double volume = 1.0}) async {
    // Try legacy mapping
    final mapped = _legacyMap[file];
    if (mapped != null) {
      await playSfxId(mapped, volume: volume);
      return;
    }

    // Try direct path
    for (final entry in _sfxPaths.entries) {
      if (entry.value.endsWith(file)) {
        await playSfxId(entry.key, volume: volume);
        return;
      }
    }

    debugPrint('AudioManager: Legacy SFX "$file" not mapped');
  }

  /// Stop all active SFX players.
  Future<void> stopAllSfx() async {
    final allPlayers = _activeSfx.values.expand((set) => set).toList();
    _activeSfx.clear();

    for (final player in allPlayers) {
        try {
          await player.stop();
          await player.dispose();
        } catch (_) {}
    }
    debugPrint('AudioManager: All SFX stopped');
  }

  // === VIBRATION ===
  void vibrate() {
    if (!_vibrationEnabled) return;
    HapticFeedback.lightImpact();
  }

  void vibratePrismHold() {
    if (!_vibrationEnabled) return;
    HapticFeedback.mediumImpact();
  }

  void vibrateCorrectTarget() {
    if (!_vibrationEnabled) return;
    HapticFeedback.heavyImpact();
  }

  void vibrateWrongMove() {
    if (!_vibrationEnabled) return;
    HapticFeedback.vibrate();
  }

  void vibrateLevelComplete() {
    if (!_vibrationEnabled) return;
    HapticFeedback.heavyImpact();
    Future.delayed(const Duration(milliseconds: 100), () {
      HapticFeedback.mediumImpact();
    });
  }

  void vibrateHint() {
    if (!_vibrationEnabled) return;
    HapticFeedback.selectionClick();
  }

  void vibrateStar(int index) {
    if (!_vibrationEnabled) return;
    switch (index) {
      case 0:
        HapticFeedback.lightImpact();
        break;
      case 1:
        HapticFeedback.mediumImpact();
        break;
      case 2:
        HapticFeedback.heavyImpact();
        break;
    }
  }

  // === MUTE TOGGLE ===
  bool _isMuted = false;
  bool get isMuted => _isMuted;

  void toggleMute() {
    _isMuted = !_isMuted;
    if (_isMuted) {
      _bgmPlayer?.setVolume(0);
    } else {
      updateBgmVolume();
    }
  }
}



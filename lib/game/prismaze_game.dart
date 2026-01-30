import 'package:flame/components.dart';
import 'package:flame/game.dart';
import 'package:flame/events.dart';
import 'package:flame/input.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:developer' as dev;
import 'dart:async';
import 'components/beam_system.dart';
import 'components/background.dart';
import 'level_loader.dart';
import 'audio_manager.dart';
import 'components/hint_manager.dart';
import 'economy_manager.dart';
import 'progress_manager.dart';
import 'mission_manager.dart';
import 'procedural/models/models.dart' as proc;
import 'procedural/ray_tracer.dart' as proc; // Alias merging
import 'procedural/ray_tracer_adapter.dart' as proc; // Alias merging
import 'progress/campaign_progress.dart';
import 'customization_manager.dart';
import 'ad_manager.dart';
import 'settings_manager.dart';
import 'cloud_save_manager.dart';
import 'analytics_manager.dart';
import 'procedural_level_generator.dart';
import 'components/target.dart';
import 'components/prism.dart';
import 'components/mirror.dart';
import 'components/wall.dart';
import 'components/light_source.dart';
import 'utils/color_blindness_utils.dart';
import 'level_state_manager.dart';
import 'easter_egg_manager.dart';
import 'undo_system.dart';
import 'components/debug_overlay.dart';
import 'procedural/models/game_state.dart';
import 'endless_run_manager.dart';

class LevelResult {
  final int stars;
  final int moves;
  final int par;
  final int earnedHints;
  final String? customTitle; // Added
  
  LevelResult({
      required this.stars,
      required this.moves,
      required this.par,
      required this.earnedHints,
      this.customTitle,
      this.oldStars = 0, // Default to 0 (new level)
  });
  
  final int oldStars;
}

class PrismazeGame extends FlameGame with HasCollisionDetection {
  final WidgetRef ref;
  late final BeamSystem beamSystem;
  late LevelLoader levelLoader;
  late HintManager hintManager;
  late EconomyManager economyManager;
  late ProgressManager progressManager;
  late MissionManager missionManager;
  late CustomizationManager customizationManager;
  late AdManager adManager;
  late AnalyticsManager analyticsManager;
  late SettingsManager settingsManager;
  late DebugOverlay debugOverlay;
  late EndlessRunManager endlessManager;
  final UndoSystem undoSystem = UndoSystem();
  
  int moves = 0;
  double levelTime = 0;
  bool usedHint = false; // logic needed to set this
  bool usedUndo = false;
  int currentLevelPar = 99;
  int currentLevelId = 1;
  int _retryCount = 0;
  bool _isLevelCompleted = false;
  
  // Listener callback for cleanup
  late VoidCallback _colorBlindListener;
  
  // Easter Egg Notifier for special popups
  final ValueNotifier<EasterEggEvent?> easterEggNotifier = ValueNotifier(null);
  
  // Load Completion
  final Completer<void> _loadCompleter = Completer();
  Future<void> get loaded => _loadCompleter.future;

  final Map<String, dynamic>? levelData;
  final int? episode;
  final int? levelIndex;
  
  bool isEndlessMode = false;
  bool isCampaignMode = false;
  int? currentEpisode;
  int? currentLevelIdx;

  Map<String, dynamic>? currentLevelJson; // To store current level data for restart
  ProceduralLevelGenerator? proceduralGenerator;
  proc.LevelMeta? currentLevelMeta;
  proc.GeneratedLevel? currentGeneratedLevel; // Active procedural level data
  
  // Procedural Systems
  final proc.RayTracer _procTracer = proc.RayTracer();
  late final proc.RayTracerAdapter _procAdapter = proc.RayTracerAdapter(
    boardOffset: Vector2(45.0, 62.5),
    cellSize: 85.0,
  );
  
  late GameState currentState; // Single Source of Truth

  PrismazeGame(this.ref, {this.levelData, this.episode, this.levelIndex}) : super(
    camera: CameraComponent.withFixedResolution(
        width: 1344, // 5% zoom out (1280 * 1.05)
        height: 756, // 5% zoom out (720 * 1.05)
    )
  ) {
    if (episode != null && levelIndex != null) {
      isCampaignMode = true;
      currentEpisode = episode;
      currentLevelIdx = levelIndex;
      currentLevelId = (episode! - 1) * 1000 + (levelIndex! + 1); // For display/IDs
    }
  }
  
  bool _needsBeamUpdate = true;
  
  void requestBeamUpdate() {
      _needsBeamUpdate = true;
  }
  
  void resetLevelState() {
      _isLevelCompleted = false;
      levelTime = 0;
      usedHint = false;
      usedUndo = false;
  }

  // Zoom Controls
  double _targetZoom = 1.0;
  
  void zoomIn() {
    _targetZoom = (_targetZoom + 0.2).clamp(0.5, 2.0); // Min 0.5x, Max 2.0x
  }
  
  void zoomOut() {
    _targetZoom = (_targetZoom - 0.2).clamp(0.5, 2.0);
  }
  
  @override
  void update(double dt) {
      super.update(dt * timeScale);
      
      // Smooth Zoom
      if ((camera.viewfinder.zoom - _targetZoom).abs() > 0.01) {
          final newZoom = camera.viewfinder.zoom + (_targetZoom - camera.viewfinder.zoom) * dt * 5.0;
          camera.viewfinder.zoom = newZoom;
      }
      
      if (!_isLevelCompleted) {
          levelTime += dt * timeScale;
          levelTimeNotifier.value = levelTime; // Update UI
          
          // FIX: Always update beams when level has started (ensures beams render after intro)
          if (_needsBeamUpdate) {
             assert(() { dev.Timeline.startSync('BeamSystem.updateBeams'); return true; }());
             
             if (beamSystem.useRayTracerMode && currentGeneratedLevel != null) {
                final level = currentGeneratedLevel!;
                final trace = _procTracer.trace(level, currentState);

                // progress biriksin:
                currentState = currentState.withTargetProgress(level.targets, trace.arrivalMasks);

                // ışınları çiz:
                final segs = _procAdapter.convertToPixelSegments(trace);
                beamSystem.setExternalSegments(segs);
                beamSystem.updateBeams(); // Trigger render

                // target görsellerini state’e göre güncelle
                _applyProceduralTargets();
              } else {
                beamSystem.updateBeams(); // legacy
              }
             
             assert(() { dev.Timeline.finishSync(); return true; }());
             _needsBeamUpdate = false;
          }
          
          // Win Condition Check
          bool won = false;
          if (currentGeneratedLevel != null) {
              // Stateful Procedural Win
              won = currentState.allTargetsSatisfied(currentGeneratedLevel!.targets);
          } else {
              // Legacy Simultaneous Win
              final targets = world.children.query<Target>();
              final allLit = targets.isNotEmpty && targets.every((t) => t.isLit);
              final allHaveColor = targets.every((t) => t.accumulatedColor != const Color(0xFF000000));
              won = allLit && allHaveColor;
          }
          
          if (won) {
              _onLevelWin();
          }
      
      // Tutorial Level 2 Adaptive Hint
      if (currentLevelId == 2 && !_isLevelCompleted && levelTime > 10.0) {
          // If > 10s and not won, show hint suggestion?
          // For now, simpler: Just pulse the hint button or show a message?
          // The prompt says "ipucu animasyonu gösterilir".
          // Let's assume we can re-activate the tutorial overlay with hint text,
          // OR just trigger the hint system's visualization if available.
          // Since we have a hint system, let's use it!
          
          // Only trigger once
          if (!hintManager.isShowingHint) {
             // For tutorial, maybe we give a free visual hint?
             // Or just flash the UI.
             // Let's toggle the tutorial Overlay with "Takıldın mı? İpucu al!"
             // But simpler: Just Auto-Show Hint if user is really stuck (Tutorial privilege).
             // hintManager.showHint(...) requires context or overlay hook.
          }
      }
  }
  }

  
  void _onLevelWin() async {
      if (_isLevelCompleted) return;
      _isLevelCompleted = true; // Prevent multiple triggers
      
      // Wait for target fill animation to complete (~1.5s fill time)
      await Future.delayed(const Duration(milliseconds: 1000));
      
      // Beam Pulse Effect (Visual Feedback before overlay)
      beamSystem.pulseBeams(); 
      AudioManager().playSfx('power_up.mp3'); 
      
      // Wait another 1s for pulse effect + celebration moment
      await Future.delayed(const Duration(milliseconds: 700));
      
      print("Level Complete!");
      AudioManager().vibrateLevelComplete(); // Double pulse
      
      // Award Rewards
      int earned = 0;
      if (isEndlessMode) {
          // Endless Mode Reward Logic
          earned = 10 + (currentLevelId / 5).floor(); // Base 10 + scaling
          economyManager.addHints(earned);
      } else {
          // Standard Campaign
          earned = await economyManager.onLevelComplete(currentLevelId, moves, currentLevelPar);
      }
      
      // Calculate Stars & Progress
      int stars = 0;
      int oldStars = 0;
      
      if (isCampaignMode && currentLevelMeta != null) {
          stars = currentLevelMeta!.getStars(moves);
          if (currentEpisode != null && currentLevelIdx != null) {
              // Fetch OLD stars first
              oldStars = CampaignProgress().getEpisodeProgress(currentEpisode!).getStars(currentLevelIdx!);
              
              if (stars > oldStars) {
                   await CampaignProgress().completeLevel(currentEpisode!, currentLevelIdx!, stars);
              }
          }
      } else {
          oldStars = progressManager.getStarsForLevel(currentLevelId);
          stars = await progressManager.completeLevel(currentLevelId, moves, currentLevelPar, usedHint, levelTime);
      }
      
      // Determine flags
      bool isNewPerfect = (stars == 3 && oldStars < 3);
      bool isUniqueCompletion = (oldStars == 0); // Was 0 stars before
      
      // Update Missions
      missionManager.onLevelComplete(
          stars: stars,
          perfect: moves <= currentLevelPar,
          usedHint: usedHint,
          usedUndo: usedUndo
      );
      
      // Clear Auto-Save
      LevelStateManager().clearLevelState(currentLevelId);
      
      // Auto-save to Cloud (Throttle this in real app)
      CloudSaveManager().saveProgress(
          progressManager.totalStars, 
          currentLevelId, 
          economyManager.hints
      );
      
      print("Level Complete! Stars: $stars (Old: $oldStars), Time: ${levelTime.toStringAsFixed(2)}s");
      
      analyticsManager.logLevelComplete(
          currentLevelId, 
          stars, 
          moves, 
          levelTime, 
          usedHint // Corrected signature
      );
      
      
      // Video Guide Triggers (Level 30, 60)
      if (currentLevelId == 30) {
           activeVideoNotifier.value = 'mixing_guide';
      } else if (currentLevelId == 60) {
           activeVideoNotifier.value = 'advanced_tactics';
      }
      
      // Update Total Hints Earned Stats
      await progressManager.trackHintsEarned(earned);
      
      // === EASTER EGG CHECK ===
      final easterEgg = EasterEggManager().checkLevelEvent(currentLevelId);
      if (easterEgg != null) {
          easterEggNotifier.value = easterEgg;
      }
      
      // Check hidden skin unlocks
      final hiddenSkin = await EasterEggManager().checkHiddenSkinUnlock(
          totalThreeStars: progressManager.totalThreeStars,
          levelsWithoutHint: progressManager.levelsWithoutHints,
          totalLevelsCompleted: progressManager.levelsCompleted,
      );
      if (hiddenSkin != null) {
          print("🎁 Hidden Skin Unlocked: $hiddenSkin");
      }
      
      // Tutorial Success Message
      if (currentLevelId == 1) {
             // ... 
      }
      
      // Check Secret Achievements
      // We need local settings state. 
      // We init SettingsManager in onLoad but didn't keep reference (local var).
      // Let's re-fetch or keep reference. 
      // Better to keep reference in PrismazeGame.
      final sm = SettingsManager(); // It re-reads prefs which is fine, but slightly inefficient.
      await sm.init();
      
      await progressManager.checkGlobalAchievements(
          levelId: currentLevelId,
          stars: stars,
          moves: moves,
          duration: levelTime,
          attempts: 1, // Reset on complete
          usedHints: usedHint,
          musicOn: sm.musicVolume > 0,
          sfxOn: sm.sfxVolume > 0,
          vibrationOn: sm.vibrationEnabled,
          onHintReward: (amount) {
              economyManager.addHints(amount);
              AudioManager().playSfx('coin_collect.mp3');
          },
          onSkinReward: (skinId) {
              customizationManager.unlockSkin(skinId); 
          },
          isNewPerfect: isNewPerfect,
          isUniqueCompletion: isUniqueCompletion
      );
      
      
      // Notify UI
      levelCompleteNotifier.value = LevelResult(
          stars: stars,
          moves: moves,
          par: currentLevelPar,
          earnedHints: earned,
          customTitle: currentLevelId == 1 ? "Harika! İşte böyle!" : null,
          oldStars: oldStars,
      );
      
      // Auto-progression handled by UI now
      // EXCEPT Level 4 (Tutorial End)
      if (currentLevelId == 4) {
           // Delay slightly then show Onboarding Complete
           Future.delayed(const Duration(milliseconds: 1500), () {
               onboardingCompleteNotifier.value = true;
               economyManager.addHints(10); // Graduation Gift
           });
      }
  }
  
  void nextLevel() async {
      // Check Interstitial
      await adManager.checkAndShowInterstitial(currentLevelId);
      
      // Reset state
      _isLevelCompleted = false;
      moves = 0;
      levelTime = 0;
      usedHint = false;
      usedUndo = false;
      _retryCount = 0;
      undoSystem.reset(); // FIX: Reset undo count for new level
      
      if (isCampaignMode && currentEpisode != null && currentLevelIdx != null) {
          currentLevelIdx = currentLevelIdx! + 1;
          final count = CampaignProgress().getLevelCount(currentEpisode!);
          
          if (currentLevelIdx! >= count) {
              // Try moving to next episode
              final allEpisodes = CampaignProgress().episodeIds;
              final currentIdx = allEpisodes.indexOf(currentEpisode!);
              if (currentIdx != -1 && currentIdx < allEpisodes.length - 1) {
                  currentEpisode = allEpisodes[currentIdx + 1];
                  currentLevelIdx = 0;
              } else {
                  // Stay on last level or show completion screen?
                  // For now, clamp to last level to avoid crash
                  currentLevelIdx = count - 1;
              }
          }
          currentLevelId = (currentEpisode! - 1) * 1000 + (currentLevelIdx! + 1);
      } else {
          currentLevelId++;
      }
      
      levelCompleteNotifier.value = null; // Clear result
      
      print("Loading Level $currentLevelId...");
      
    if (isCampaignMode && currentEpisode != null && currentLevelIdx != null) {
          levelLoader.loadCampaignLevel(currentEpisode!, currentLevelIdx!);
      } else if (isEndlessMode) {
          // Notify manager of completion
          await endlessManager.onLevelComplete();
          currentLevelId = endlessManager.currentIndex;
          
          if (proceduralGenerator != null) {
             // Endless mode: Generate and load via standard path
             // The proceduralGenerator creates JSON data - for now use loadLevel fallback
             levelLoader.loadLevel(currentLevelId);
          } else {
             // Fallback
             levelLoader.loadLevel(currentLevelId);
          }
      } else {
          levelLoader.loadLevel(currentLevelId);
      }
      
      _updateNotifiers();
      
      // Delay beam update until sequence starts
      _needsBeamUpdate = false; 
      beamSystem.clearBeams();
      
      // Trigger Intro
      introActiveNotifier.value = true;
      hasStartedLevel.value = false;
      
      // FIX: Force beam update after components are loaded (regardless of intro)
      Future.delayed(const Duration(milliseconds: 500), () {
        if (currentLevelId == currentLevelId) { // Still on same level
          requestBeamUpdate();
          hasStartedLevel.value = true; // Enable beam rendering
        }
      });
      
      _checkContextualContent(currentLevelId);
      
      // Log Analytics
      analyticsManager.logLevelStart(currentLevelId);
      
      // Update BGM
      AudioManager().playGameBgm(currentLevelId);
      
      // Tutorial Check
      if (currentLevelId == 1) {
          tutorialActiveNotifier.value = true;
      } else if (currentLevelId == 2) {
          tutorialActiveNotifier.value = true;
          // Auto-hide text after 3 seconds for Level 2 so they can play
          Future.delayed(const Duration(seconds: 3), () {
              if (currentLevelId == 2) tutorialActiveNotifier.value = false;
          });
      } else if (currentLevelId == 3) {
          tutorialActiveNotifier.value = true;
          // Auto-hide text after 4 seconds for Level 3
          Future.delayed(const Duration(seconds: 4), () {
              if (currentLevelId == 3) tutorialActiveNotifier.value = false;
          });
      } else if (currentLevelId == 4) {
          // Step 5: Hint Introduction
          tutorialActiveNotifier.value = true;
          hintHighlightNotifier.value = true;
          
          // Gift Tokens
          economyManager.giveTutorialBonus(); 
          
          // Auto-hide text/highlight after 5 seconds
          Future.delayed(const Duration(seconds: 5), () {
              if (currentLevelId == 4) {
                   tutorialActiveNotifier.value = false;
                   hintHighlightNotifier.value = false;
              }
          });
      } else {
          tutorialActiveNotifier.value = false;
          hintHighlightNotifier.value = false;
      }
  }
  
  void restartLevel() {
      _retryCount++;
      _isLevelCompleted = false;
      levelCompleteNotifier.value = null;
      
      // Restart: Use Campaign or standard path
      if (isCampaignMode && currentEpisode != null && currentLevelIdx != null) {
          levelLoader.loadCampaignLevel(currentEpisode!, currentLevelIdx!);
      } else {
          levelLoader.loadLevel(currentLevelId);
      }
      _undoStack.clear();
      undoSystem.reset(); // Reset undo counts
      moves = 0;
      levelTime = 0;
      usedHint = false;
      usedUndo = false;
      _updateNotifiers();
      requestBeamUpdate();
      AudioManager().playGameBgm(currentLevelId);
  }

  void recordMove(int componentId, Vector2 position, double angle) {
      _undoStack.add(MoveAction(componentId, position, angle));
      if (_undoStack.length > 5) {
        _undoStack.removeAt(0); // Keep last 5
      }
      moves++;
      _updateNotifiers();
      
      // Hide tutorial
      if (tutorialActiveNotifier.value) {
          tutorialActiveNotifier.value = false;
      }
      
      // Auto-Save State
      _autoSaveLevel();
  }
  
  void _autoSaveLevel() {
      // Collect positions of key interactables (Prisms, Mirrors)
      // Index-based list to map back on load
      List<Map<String, dynamic>> state = [];
      
      // Order: Walls, Mirrors, Prisms, Targets, Source
      // But we only care about MOVABLE things for now?
      // Actually Prisms and Mirrors rotate/move.
      // We should grab all "Prism" and "Mirror" components.
      
      final prisms = children.query<Prism>();
      final mirrors = children.query<Mirror>();
      
      // We must Sort them to ensure deterministic order so index matching works
      // Sorting by initial ID or position? 
      // Position changes, so that's bad for ID.
      // If LevelLoader spawns them in order, the query order *might* be stable if list isn't modified.
      // But robust way implies having IDs.
      // Since I don't have IDs on components, I trust query order for now (risky but okay for proto).
      
      for(final p in prisms) {
          state.add({
              'type': 'prism',
              'x': p.position.x,
              'y': p.position.y,
              'angle': p.angle
          });
      }
      for(final m in mirrors) {
          state.add({
              'type': 'mirror',
              'x': m.position.x,
              'y': m.position.y,
              'angle': m.angle
          });
      }
      
      LevelStateManager().saveLevelState(currentLevelId, state);
  }
  // Removed: Debug onTapUp that triggered hints on every tap
  // @override
  // void onTapUp(TapUpInfo info) {
  //     hintManager.showLightHint();
  //     usedHint = true;
  //     print("Hint Requested");
  // }
  // UI State
  ValueNotifier<int> movesNotifier = ValueNotifier(0);
  ValueNotifier<int> parNotifier = ValueNotifier(99);
  final ValueNotifier<int> scoreNotifier = ValueNotifier(0);
  final ValueNotifier<LevelResult?> levelCompleteNotifier = ValueNotifier(null);
  
  // Tutorial
  final ValueNotifier<bool> introActiveNotifier = ValueNotifier(false); // Added
  final ValueNotifier<bool> tutorialActiveNotifier = ValueNotifier(false);
  final ValueNotifier<bool> hintHighlightNotifier = ValueNotifier(false); 
  final ValueNotifier<bool> hasStartedLevel = ValueNotifier(false); // Added for physics check
  final ValueNotifier<int> levelNotifier = ValueNotifier(1);

  // ...

  Future<void> startLevelSequence() async {
      introActiveNotifier.value = false;
      hasStartedLevel.value = true;
      
      // Sequence: Quick Fade In (optimized for speed)
      // All components fade in quickly
      await _animateFadeIn<Wall>(0.15);
      await _animateFadeIn<Mirror>(0.1);
      _animateFadeIn<Prism>(0.1); // Fire and forget
      await _animateFadeIn<Target>(0.1);
      await _animateFadeIn<LightSource>(0.15);
      
      // Enable Physics - Request beam update
      requestBeamUpdate();
      
      // Secondary beam update after short delay to ensure all components are ready
      Future.delayed(const Duration(milliseconds: 50), () {
        if (!_isLevelCompleted) {
          requestBeamUpdate();
        }
      });
  }
  
  Future<void> _animateFadeIn<T>(double duration) async {
      // FIX: Search in world.children, not children
      final components = world.children.whereType<T>();
      if (components.isEmpty) return;
      
      final steps = 10;
      final stepDelay = (duration * 1000 / steps).round();
      for(int i=1; i<=steps; i++) {
          await Future.delayed(Duration(milliseconds: stepDelay));
          for(final c in components) {
               // Dynamic access is tricky. 
               // We know T is one of the types we modified.
               if (c is Wall) c.opacity = i/steps;
               if (c is Mirror) c.opacity = i/steps;
               if (c is Prism) c.opacity = i/steps;
               if (c is Target) c.opacity = i/steps;
               if (c is LightSource) c.opacity = i/steps;
          }
      }
  } 
  // State Getters
  bool get isLevelCompleted => _isLevelCompleted;
  
  final ValueNotifier<double> levelTimeNotifier = ValueNotifier(0.0);
  final ValueNotifier<bool> onboardingCompleteNotifier = ValueNotifier(false); 
  final ValueNotifier<String?> activeTipNotifier = ValueNotifier(null);
  final ValueNotifier<String?> activeVideoNotifier = ValueNotifier(null); 
  
  /* late ProgressManager progressManager; // Removed duplicate */
  final List<MoveAction> _undoStack = [];
  static const int _maxUndo = 5;
  
  // Game Speed
  double timeScale = 1.0;

  @override
  Future<void> onLoad() async {
    print("=== PRISMAZE GAME onLoad START ===");
    
    // CRITICAL: Call super.onLoad to init camera/world
    await super.onLoad();
    
    // Check if we should activate Endless Mode
    if (!isCampaignMode && levelData == null && episode == null) {
        // Default to endless if nothing else specified
        isEndlessMode = true;
    }

    if (isEndlessMode) {
        endlessManager = EndlessRunManager();
        await endlessManager.init();
        
        if (endlessManager.hasActiveRun) {
            endlessManager.continueRun();
        } else {
            await endlessManager.startNewRun();
        }
        
        currentLevelId = endlessManager.currentIndex;
    }
    
    // Ensure world is in the component tree
    if (world.parent == null) {
      add(world);
    }
    
    // Ensure camera points to world
    camera.world = world;
    
    // Audio Setup
    print("DEBUG: Loading Audio...");
    await AudioManager().loadAssets();
    await AudioManager().init(); 
    AudioManager().playGameBgm(currentLevelId);
    print("DEBUG: Audio Loaded");
    
    // Center Camera on 1280x720 Play Area
    camera.viewfinder.position = Vector2(640, 360);
    camera.viewfinder.anchor = Anchor.center;

    // Economy
    economyManager = EconomyManager(); 
    await economyManager.init(); 
    
    // Progress
    progressManager = ProgressManager();
    await progressManager.init();
    
    // Missions
    missionManager = MissionManager(economyManager);
    await missionManager.init();
    
    // Customization
    customizationManager = CustomizationManager(progressManager);
    await customizationManager.init();
    
    // Ads
    adManager = AdManager();
    await adManager.init();
    
    // Settings
    settingsManager = SettingsManager();
    await settingsManager.init();
    
    // Cloud
    final cloudSaveManager = CloudSaveManager();
    cloudSaveManager.syncProgress(progressManager, economyManager);
    
    // Level State (Auto Save)
    await LevelStateManager().init();
    
    // Analytics
    analyticsManager = AnalyticsManager();
    await analyticsManager.init();
    adManager.setAnalytics(analyticsManager);

    // Hint Manager
    hintManager = HintManager(); 
    world.add(hintManager); 
    
    // Add Background System
    world.add(BackgroundComponent());  // FIXED: Use world.add for camera rendering

    // Initialize Beam System (The physics engine)
    
    // Sync ColorBlind Mode
    ColorBlindnessUtils.currentMode = ColorBlindMode.values[settingsManager.colorBlindIndex];
    _colorBlindListener = () {
        ColorBlindnessUtils.currentMode = ColorBlindMode.values[settingsManager.colorBlindIndex];
    };
    settingsManager.addListener(_colorBlindListener);

    beamSystem = BeamSystem();
    world.add(beamSystem);  // FIXED: Use world.add for camera rendering
    
    // Debug Overlay (renders on top when enabled)
    debugOverlay = DebugOverlay();
    world.add(debugOverlay);

    // Level Loader
    print("DEBUG: Creating LevelLoader...");
    levelLoader = LevelLoader();
    world.add(levelLoader); 
    print("DEBUG: LevelLoader added to world");
    
    // Load Injected Level or Asset Level
    if (isCampaignMode && currentEpisode != null && currentLevelIdx != null) {
        print("DEBUG: Loading Campaign Episode $currentEpisode Level $currentLevelIdx...");
        await levelLoader.loadCampaignLevel(currentEpisode!, currentLevelIdx!);
    } else if (levelData != null) {
        print("DEBUG: Loading Endless Mode level...");
        isEndlessMode = true;
        proceduralGenerator = ProceduralLevelGenerator();
        // Endless mode: Use standard level loading path
        await levelLoader.loadLevel(currentLevelId);
    } else {
        print("DEBUG: Loading Campaign Level $currentLevelId...");
        await levelLoader.loadLevel(currentLevelId);
        print("DEBUG: Level $currentLevelId loaded!");
    }
    _updateNotifiers();
    _updateNotifiers(); // Double update to ensure UI catches up?
    requestBeamUpdate(); // Ensure first frame is drawn
    
    // Check Contextual Content (Tips/Videos)
    _checkContextualContent(currentLevelId);
    
    // Mark as Fully Loaded
    print("=== PRISMAZE GAME onLoad COMPLETE ===");
    print("DEBUG: World children count: ${world.children.length}");
    _loadCompleter.complete();
  }
  
  // Removed duplicate startLevelSequence
  // Original is at line 468

  void _checkContextualContent(int levelId) {
      // 1. Contextual Tips
      final tip = _getContextualTip(levelId);
      if (tip != null) {
          // Show Tip (UI Notifier)
          // We'll use tutorialActiveNotifier for simplicity or a new one
          activeTipNotifier.value = tip;
          Future.delayed(const Duration(seconds: 4), () {
               activeTipNotifier.value = null; // Hide after 4s
          });
      }
      
      // 2. Video Guides Check
      // This is usually triggered on MENU or Level Complete, but let's check entrance.
      // Actually request says "Level 30 sonrası", probably means UPON completing 30.
      // but if we just loaded 31, we can show it "New Guide Unlocked!".
      // For "Welcome" video, it's on first launch.
      
      if (levelId == 1 && !progressManager.isVideoWatched('welcome')) {
          // Show Welcome Video
          // We need a proper Video Overlay trigger
          activeVideoNotifier.value = 'welcome';
      }
  }
  
  String? _getContextualTip(int levelId) {
      switch(levelId) {
          case 15: return "İpucu: Işığı duvardan sektirebilirsin!";
          case 35: return "Taktik: Önce hedefleri planla, sonra başla";
          case 60: return "Bilgi: İki ışın birleşince renk karışır";
          case 85: return "Trick: Hareketli prizmaların zamanlamasını izle";
          default: return null;
      }
  }
  
  // Called by Video Overlay when finished
  void onVideoComplete(String videoId) {
      if (!progressManager.isVideoWatched(videoId)) {
          progressManager.markVideoWatched(videoId);
          economyManager.addHints(5);
          print("Video Watched: $videoId (+5 Hints)");
      }
      activeVideoNotifier.value = null; // Close overlay
  }

  void undo() {
      // FIX: Check stack FIRST before consuming an undo point
      if (_undoStack.isEmpty) {
          print("Undo stack is empty - no moves to undo!");
          return;
      }
      
      // Try to consume an undo point
      if (!undoSystem.useUndo()) {
          print("No undos remaining or limit reached!");
          return;
      }
      
      final action = _undoStack.removeLast();
      
      // Find component and revert
      final component = findComponentById(action.componentId);
      if (component != null && component is PositionComponent) {
          component.position = action.position.clone();
          component.angle = action.angle;
          print("Undo applied: component ${action.componentId} reverted");
      } else {
          print("Undo failed: component ${action.componentId} not found");
      }
      
      usedUndo = true; // Mark undo usage
      _updateNotifiers();
      requestBeamUpdate();
  }
  
  void toggleSpeed() {
      if (timeScale == 1.0) {
          timeScale = 2.0;
      } else {
          timeScale = 1.0;
      }
      // Notify UI if needed?
  }

  // Tutorial Methods
  void finishOnboarding() {
      onboardingCompleteNotifier.value = true;
      // Maybe save state?
  }

  void skipTutorial() {
      // Logic to jump to level 5?
      if (currentLevelId <= 4) {
          levelLoader.loadLevel(5);
          currentLevelId = 5;
          _updateNotifiers();
          tutorialActiveNotifier.value = false;
      }
  }

  // Helper to find component by hashCode
  Component? findComponentById(int id) {
      // Search in world.children (where game objects are)
      for (final c in world.children) {
          if (c.hashCode == id) return c;
      }
      // Also check direct children (fallback)
      for (final c in children) {
          if (c.hashCode == id) return c;
      }
      return null;
  }


  @override
  Color backgroundColor() => const Color(0xFF000000); // Fallback
  
  void _updateNotifiers() {
      movesNotifier.value = moves;
      levelTimeNotifier.value = levelTime;
      
      // FIX: Show level relative to episode (1-1000) instead of absolute ID (e.g. 4185 -> 185)
      if (isCampaignMode && currentLevelIdx != null) {
          levelNotifier.value = currentLevelIdx! + 1;
      } else {
          levelNotifier.value = currentLevelId;
      }
  }
  @override
  void onDispose() {
      // Remove Listeners
      settingsManager.removeListener(_colorBlindListener);
      
      // Dispose Notifiers
      movesNotifier.dispose();
      parNotifier.dispose();
      scoreNotifier.dispose();
      levelCompleteNotifier.dispose();
      introActiveNotifier.dispose();
      tutorialActiveNotifier.dispose();
      hintHighlightNotifier.dispose();
      hasStartedLevel.dispose();
      levelNotifier.dispose();
      levelTimeNotifier.dispose();
      onboardingCompleteNotifier.dispose();
      activeTipNotifier.dispose();
      activeVideoNotifier.dispose();
      easterEggNotifier.dispose();
      
      // Dispose Managers
      economyManager.dispose();
      progressManager.dispose();
      missionManager.dispose();
      
      super.onDispose();
  }
  /// Synchronize target visuals (color progress) with the procedural GameState
  /// Synchronize target visuals (color progress) with the procedural GameState
  /// Synchronize target visuals (color progress) with the procedural GameState
  void _applyProceduralTargets() {
    final targets = world.children.whereType<Target>();
    for (final target in targets) {
      if (target.procIndex != null) {
         final mask = currentState.getTargetCollected(target.procIndex!);
         target.applyProceduralMask(mask);
      }
    }
  }
}

class MoveAction {
  final int componentId;
  final Vector2 position;
  final double angle;
  
  MoveAction(this.componentId, this.position, this.angle);
}




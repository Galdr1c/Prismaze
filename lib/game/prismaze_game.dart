// Minimal stub to keep screens working
import 'package:flame/game.dart';
import 'package:flame/components.dart';
import 'package:flame/input.dart'; // Correct for TapDetector
import 'package:flame/events.dart'; // For TapUpEvent? Actually just input usually covers it or events.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// Managers
import 'audio_manager.dart';
import 'customization_manager.dart';
import 'settings_manager.dart';
import 'economy_manager.dart';
import 'progress_manager.dart';
import 'ad_manager.dart';
import 'undo_system.dart';
import 'components/hint_manager.dart';
import 'components/background.dart';

// New Engine Components
import '../generator/cache/level_cache_manager.dart';
import '../generator/models/generated_level.dart';
import '../core/logic/ray_tracer.dart';
import '../core/logic/trace_result.dart';
import '../core/models/models.dart';
import '../core/models/objects.dart';
import 'components/object_factory.dart';
import 'components/beam_renderer.dart';
import 'components/mirror.dart';
import 'components/prism.dart';

class LevelResult {
  final int stars;
  final int moves;
  final int par;
  final int earnedHints;
  final String? customTitle; 
  final int oldStars;
  
  LevelResult({
      required this.stars,
      required this.moves,
      required this.par,
      required this.earnedHints,
      this.customTitle,
      this.oldStars = 0,
  });
}

class PrismazeGame extends FlameGame with TapDetector {
  final WidgetRef ref;
  
  // Game State
  int moves = 0;
  int currentLevelPar = 0; // Legacy, determined by complexity?
  int currentLevelId = 1;
  GeneratedLevel? currentLevel;
  TraceResult? lastTrace;
  bool isLevelCompleted = false;

  // Components
  // final World gridWorld = World(); // REMOVED: Managed by FlameGame
  late BeamRenderer beamRenderer;
  
  // Notifiers
  final ValueNotifier<int> movesNotifier = ValueNotifier(0);
  final ValueNotifier<int> parNotifier = ValueNotifier(0);
  final ValueNotifier<int> levelNotifier = ValueNotifier(1);
  final ValueNotifier<double> levelTimeNotifier = ValueNotifier(0.0);
  final ValueNotifier<LevelResult?> levelCompleteNotifier = ValueNotifier(null);
  
  // Stubs
  final ValueNotifier<bool> tutorialActiveNotifier = ValueNotifier(false);
  final ValueNotifier<bool> hintHighlightNotifier = ValueNotifier(false);
  final ValueNotifier<bool> introActiveNotifier = ValueNotifier(false);
  final ValueNotifier<String?> activeTipNotifier = ValueNotifier(null);
  final ValueNotifier<String?> activeVideoNotifier = ValueNotifier(null);
  
  // Managers
  late CustomizationManager customizationManager;
  late SettingsManager settingsManager;
  late EconomyManager economyManager;
  late ProgressManager progressManager;
  final UndoSystem undoSystem = UndoSystem();
  late AdManager adManager;
  late HintManager hintManager;

  // Cache
  final LevelCacheManager cacheManager = LevelCacheManager();

  PrismazeGame(this.ref, {int? levelId}) : super(
    // Global Endless Mode: Only uses levelId
    world: World(), // We will use this passed world as our gridWorld reference
    camera: CameraComponent.withFixedResolution(
       width: 720,
       height: 1280, // Portrait Ratio 9:16
    )..viewfinder.anchor = Anchor.center,
  ) {
    if (levelId != null) {
      currentLevelId = levelId;
    }
  }

  // Helper to access the world instance created by super or assigned
  World get gridWorld => world;

  @override
  Future<void> onLoad() async {
    await AudioManager().init();
    
    // Init Managers
    settingsManager = SettingsManager();
    await settingsManager.init();
    
    economyManager = EconomyManager();
    await economyManager.init();
    
    progressManager = ProgressManager();
    await progressManager.init();
    
    customizationManager = CustomizationManager(progressManager);
    await customizationManager.init();
    
    // undoSystem is now initialized at declaration
    adManager = AdManager();
    
    // Setup Visuals
    add(BackgroundComponent());
    
    beamRenderer = BeamRenderer();
    gridWorld.add(beamRenderer);
    
    hintManager = HintManager();
    gridWorld.add(hintManager);
    
    // Load Level
    // RESUME: Use passed levelId or last played from progress
    if (currentLevelId <= 1) { // If default/not set
        currentLevelId = progressManager.lastPlayedLevelId;
    }
    await loadLevel(currentLevelId);
    
    // Camera setup
    camera.viewfinder.anchor = Anchor.center;
    // Center the 6x12 grid: 6*85 = 510 width, 12*85 = 1020 height
    // Grid center: 510/2 = 255, 1020/2 = 510
    camera.viewfinder.position = Vector2(255, 510);
  }
  
  Future<void> loadLevel(int index) async {
    isLevelCompleted = false;
    currentLevelId = index;
    levelNotifier.value = index;
    moves = 0;
    movesNotifier.value = 0;
    
    // Crash-Safe: Save current level as last played IMMEDIATELY (HATA 4)
    progressManager.setLastPlayedLevel(index);

    // Clear old
    gridWorld.removeAll(gridWorld.children.whereType<PositionComponent>().where((c) => c != beamRenderer));
    
    try {
      // 1. Get from Cache (Model 1: use locked version)
      final version = progressManager.generatorVersion;
      final level = await cacheManager.getLevel(version, index);
      currentLevel = level;
      
      // Update UI Par from template
      currentLevelPar = level.par;
      parNotifier.value = currentLevelPar;
      
      // 2. Factory Create
      final components = ObjectFactory.createComponents(level);
      gridWorld.addAll(components);
      
      // Center Camera on the 6x12 Grid
      // Grid size: 6 cols * 85 = 510 width, 12 rows * 85 = 1020 height
      // Grid center: 510/2 = 255, 1020/2 = 510
      camera.viewfinder.position = Vector2(255, 510);
      
      // 3. Prefetch Next
      cacheManager.prepareNextLevels(version, index);
      
      // 4. Initial Trace
      _updateTrace();
      
    } catch (e) {
      print("Level Load Failed: $e");
    }
  }

  @override
  void onTapUp(TapUpInfo info) {
    if (isLevelCompleted || currentLevel == null) return;
    
    // Convert screen tap to world coordinates properly
    // info.eventPosition.global is screen position
    // We need to convert through camera viewport then viewfinder
    final screenPos = info.eventPosition.global;
    final viewportPos = camera.viewport.globalToLocal(screenPos);
    final worldPoint = camera.viewfinder.parentToLocal(viewportPos);
    
    print('TAP DEBUG: Screen=$screenPos, Viewport=$viewportPos, World=$worldPoint');
    
    // Find all rotatable objects
    final rotatables = <PositionComponent>[];
    for (var c in world.children) {
      if (c is Mirror && !c.isFixed) {
        rotatables.add(c);
      } else if (c is Prism && !c.isFixed) {
        rotatables.add(c);
      }
    }
    
    print('TAP DEBUG: Found ${rotatables.length} rotatable objects');
    
    // Find closest object to tap point (distance-based)
    PositionComponent? tapped;
    double minDist = double.infinity;
    
    for (var obj in rotatables) {
      final dist = (obj.position - worldPoint).length;
      print('TAP DEBUG: Object ${obj.runtimeType} at ${obj.position}, dist=$dist');
      
      // Hit threshold: half cell size (42.5) plus some tolerance
      if (dist < 50 && dist < minDist) {
        minDist = dist;
        tapped = obj;
      }
    }
    
    if (tapped != null) {
      print('TAP DEBUG: Rotating ${tapped.runtimeType} at ${tapped.position}');
      
      bool rotated = false;
      if (tapped is Mirror) {
        tapped.rotate();
        final gridPos = GridPosition.fromPixel(tapped.position, 85.0);
        _rotateObjectInModel(gridPos);
        rotated = true;
      } else if (tapped is Prism) {
        tapped.rotate();
        final gridPos = GridPosition.fromPixel(tapped.position, 85.0);
        _rotateObjectInModel(gridPos);
        rotated = true;
      }
      
      if (rotated) {
        moves++;
        movesNotifier.value = moves;
        AudioManager().playSfx('rotate');
        _updateTrace();
      }
    } else {
      print('TAP DEBUG: No object found at tap position');
    }
  }
  
  void _rotateObjectInModel(GridPosition pos) {
    if (currentLevel == null) return;
    
    // Find object in list match pos
    // Note: GeneratedLevel.objects is unmodifiable list?
    // We need to be able to mutate the state for RayTracer.
    // In strict functional style, we create new level state.
    // Here for perf, we probably mutated the object if it's mutable, 
    // OR verify if we need to replace it.
    
    // GameObject is immutable. generatedLevel.objects is List.
    // We replace the object in the list.
    
    final index = currentLevel!.objects.indexWhere((o) => o.position == pos);
    if (index != -1) {
       final obj = currentLevel!.objects[index];
       if (obj.rotatable) { // Double check
          final newObj = obj.rotateRight();
          currentLevel!.objects[index] = newObj;
       }
    }
  }

  void _updateTrace() {
    if (currentLevel == null) return;
    
    lastTrace = RayTracer.trace(currentLevel!);
    beamRenderer.updateResult(lastTrace!);
    
    if (lastTrace!.success) {
      _handleWin();
    }
  }
  
  Future<void> _handleWin() async {
    if (isLevelCompleted) return;
    isLevelCompleted = true;
    AudioManager().playSfx('level_complete');
    
    // 1. COMPLETION STATE WRITTEN FIRST (HATA 4)
    final par = currentLevel?.par ?? 10;
    final stars = await progressManager.completeLevel(
        currentLevelId, 
        moves, 
        par, 
        false, 
        0.0
    );

    // 2. INCREMENT CURRENT INDEX FOR CRASH-SAFETY
    final nextLevelId = currentLevelId + 1;
    await progressManager.setLastPlayedLevel(nextLevelId);

    // 2b. UPDATE ENDLESS HIGH SCORE (HATA 5)
    // We unlocked nextLevelId, so that is the new highest reachable.
    await progressManager.setHighestEndlessLevel(nextLevelId);

    // 3. START PREFETCH via Optimized Handler (HATA 5)
    cacheManager.onLevelComplete(progressManager.generatorVersion, currentLevelId);

    // Show overlay
    final result = LevelResult(
      stars: stars, 
      moves: moves, 
      par: par, 
      earnedHints: stars == 3 ? 1 : 0, 
      oldStars: 0
    );
    levelCompleteNotifier.value = result;
  }

  // API wrappers
  void nextLevel() {
    loadLevel(currentLevelId + 1);
    levelCompleteNotifier.value = null;
  }
  
  void restartLevel() {
    loadLevel(currentLevelId);
    levelCompleteNotifier.value = null;
  }
  
  void zoomIn() {}
  void zoomOut() {}
  void requestBeamUpdate() {} 
  void undo() {}
}

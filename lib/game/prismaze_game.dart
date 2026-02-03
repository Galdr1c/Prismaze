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

  PrismazeGame(this.ref, {dynamic levelData, int? episode, int? levelIndex}) : super(
    world: World(), // We will use this passed world as our gridWorld reference
    camera: CameraComponent.withFixedResolution(
       width: 720,
       height: 1280, // Portrait Ratio 9:16
    )..viewfinder.anchor = Anchor.center,
  );

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
    // RESUME: Use the last played level index from progress manager (HATA 4)
    currentLevelId = progressManager.lastPlayedLevelId;
    await loadLevel(currentLevelId);
    
    // Camera setup
    camera.viewfinder.anchor = Anchor.center;
    // Center the 6x12 grid (approx 510x1020 px) in screen
    // Grid Center: (3*85, 6*85) = (255, 510)
    camera.viewfinder.position = Vector2(255 + 30, 510); // Offset slightly
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
      
      // Center Camera on the Level Grid (8 cols x 85.0 = 680 width, 10 rows x 85.0 = 850 height)
      // Level origin is (0,0). Center is approx (340, 425).
      camera.viewfinder.position = Vector2(340, 425);
      
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
    
    // TapUpInfo provides eventPosition.widget (screen pixels)
    
    // Convert tap to world coordinates
    final worldPoint = camera.viewfinder.parentToLocal(info.eventPosition.widget);
    
    // Find all potential candidates
    final candidates = <PositionComponent>[];
    for (var c in gridWorld.children) {
      if (c is PositionComponent && c.containsPoint(worldPoint)) {
        if ((c is Mirror && !c.isFixed) || (c is Prism && !c.isFixed)) {
          candidates.add(c);
        }
      }
    }
    
    if (candidates.isEmpty) return;

    // Tap Priority: Sort by distance to center
    candidates.sort((a, b) {
      double distA = (a.position - worldPoint).length;
      double distB = (b.position - worldPoint).length;
      return distA.compareTo(distB);
    });

    final best = candidates.first;
    bool rotated = false;
    
    if (best is Mirror) {
      best.rotate();
      final gridPos = GridPosition.fromPixel(best.position, 85.0);
      _rotateObjectInModel(gridPos);
      rotated = true;
    } else if (best is Prism) {
      best.rotate();
      final gridPos = GridPosition.fromPixel(best.position, 85.0);
      _rotateObjectInModel(gridPos);
      rotated = true;
    }
    

    
    if (rotated) {
      moves++;
      movesNotifier.value = moves;
      AudioManager().playSfx('rotate');
      _updateTrace();
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

    // 3. START PREFETCH
    cacheManager.prepareNextLevels(progressManager.generatorVersion, nextLevelId);

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

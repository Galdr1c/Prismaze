import 'package:prismaze/core/utils/utils.dart';
import '../../generator/recipe_deriver.dart';
import '../templates/template_family.dart';
import '../templates/template_catalog.dart'; // To maybe check existence per variant?
import 'pacing_rules.dart';
import 'cooldown_tracker.dart';

class TemplateSelector {
  // Cache to store the determined family for each level index.
  // This allows us to "fast forward" or look up without re-running RNG for 1..N-1 every time
  // if we persist it in memory during session.
  // For strict determinism across sessions, we re-calculate from the nearest trusted checkpoint or 1.
  // Currently, we'll re-calculate from 1 for absolute safety on "law of the seed".
  // Performance: for level 1000, 1000 fast RNG calls is negligible (<1ms).
  final Map<int, TemplateFamily> _cache = {};
  
  /// Selects the TemplateFamily for the given level index.
  /// 
  /// This method is HISTORY-AWARE. It ensures that the sequence 1..current
  /// is respected to maintain correct cooldown states.
  TemplateFamily selectFamily(String version, int levelIndex) {
    if (_cache.containsKey(levelIndex)) {
      return _cache[levelIndex]!;
    }

    // Re-simulate from the last cached point or from 1
    // Ideally finding the highest cached index < levelIndex
    // But since we want strict statelessness from the caller's perspective:
    // We assume we might need to calc from 1 if cache is empty.
    
    // Optimization: If cache has N, and we want N+1, just calc N+1.
    // If we want N+100, we must calc N+1..N+100.
    
    int start = 1;
    // Find highest cached index below target
    // Keys are not guaranteed sorted in Map, but we can search.
    // Or just rely on linear fill if used sequentially.
    // For random access (Level select), we might just recalc from 1. 2000 steps is cheap.
    
    final tracker = CooldownTracker(maxCooldown: 6);
    
    for (int i = 1; i <= levelIndex; i++) {
      if (_cache.containsKey(i)) {
        // Hydrate tracker with cached decision
        tracker.recordUsage(_cache[i]!);
        if (i == levelIndex) return _cache[i]!;
        start = i + 1;
        continue;
      } else {
        // Calculate new
        // 1. Derive Seed for this step
        final int stepSeed = RecipeDeriver.deriveSeed(version, i);
        final rng = DeterministicRNG(stepSeed);
        
        // 2. Get Eligible (Weights + Cooldown)
        final weights = PacingRules.getWeights(i);
        List<TemplateFamily> eligible = _filterEligible(weights, tracker, 6);
        
        // 3. Fallback Logic
        if (eligible.isEmpty) {
          // Reduce cooldown
          eligible = _filterEligible(weights, tracker, 3);
        }
        if (eligible.isEmpty) {
          // Emergency fallback
           eligible = [TemplateFamily.verticalCorridor];
        }
        
        // 4. Select (Deterministic Weighted Random)
        // Sort for strict determinism before picking
        eligible.sort((a, b) => a.index.compareTo(b.index));
        
        TemplateFamily selected = _weightedPick(eligible, weights, rng);
        
        // 5. Store & Update Tracker
        _cache[i] = selected;
        tracker.recordUsage(selected);
        // if (levelIndex < 50) {
        //    print('Level $levelIndex: Selected ${selected.name} from ${eligible.map((e) => e.name).toList()}');
        // }
        
        if (i == levelIndex) return selected;
      }
    }
    
    return _cache[levelIndex]!;
  }
  
  List<TemplateFamily> _filterEligible(
    Map<TemplateFamily, int> weights, 
    CooldownTracker tracker, 
    int effectiveCooldownWindow
  ) {
    // Current history reference
    // We can't change tracker's internal list easily without hacks.
    // Instead check history manually vs effective window.
    final history = tracker.history;
    final int historyLen = history.length;
    // Window size X means check last X items.
    // If history has 6 items, and we want window 3, we check items at indices 3,4,5.
    
    final forbidden = <TemplateFamily>{};
    if (historyLen > 0 && effectiveCooldownWindow > 0) {
       int checkCount = effectiveCooldownWindow;
       if (checkCount > historyLen) checkCount = historyLen;
       
       // History is Queue-like, usually we just assume tracker's isCooldown checks full history.
       // But here we need variable window.
       // Let's iterate backwards.
       for (int j = 0; j < checkCount; j++) {
         forbidden.add(history[historyLen - 1 - j]);
       }
    }
    
    return weights.keys.where((f) => weights[f]! > 0 && !forbidden.contains(f)).toList();
  }
  
  TemplateFamily _weightedPick(
    List<TemplateFamily> candidates, 
    Map<TemplateFamily, int> weights, 
    DeterministicRNG rng
  ) {
    if (candidates.isEmpty) return TemplateFamily.verticalCorridor;
    if (candidates.length == 1) return candidates.first;
    
    int totalWeight = candidates.fold(0, (sum, f) => sum + weights[f]!);
    int roll = rng.nextInt(totalWeight);
    
    int currentSum = 0;
    for (var f in candidates) {
      currentSum += weights[f]!;
      if (roll < currentSum) return f;
    }
    
    return candidates.last;
  }
}

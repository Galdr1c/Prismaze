import 'dart:collection';
import '../templates/template_family.dart';

/// Tracks the history of used families to enforce cooldowns.
/// Sliding window approach.
class CooldownTracker {
  final Queue<TemplateFamily> _history = Queue<TemplateFamily>();
  int _maxCooldown;

  CooldownTracker({int maxCooldown = 6}) : _maxCooldown = maxCooldown;

  /// Adds a family to the history. Maintain max size.
  void recordUsage(TemplateFamily family) {
    _history.addLast(family);
    while (_history.length > _maxCooldown) {
      _history.removeFirst();
    }
  }

  /// Checks if a family is currently on cooldown.
  bool isCooldown(TemplateFamily family) {
    return _history.contains(family);
  }

  /// Temporarily Reduces the cooldown window size if generation gets stuck.
  /// This doesn't change history, just effectively ignores older entries for the next check logic upstream.
  /// But strictly speaking, the tracker just answers "is contained".
  /// The Selector handles the logic of ignoring the tracker if needed.
  
  /// Returns the current history for debugging/hashing
  List<TemplateFamily> get history => _history.toList();
  
  /// Reset for new calculation chain
  void reset() {
    _history.clear();
  }
}

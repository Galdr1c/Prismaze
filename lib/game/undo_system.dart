import 'package:flutter/foundation.dart';

class UndoSystem extends ChangeNotifier {
  int baseUndoCount = 3;      // Free undos
  int bonusUndoCount = 0;     // Earned via ads
  int maxBonusUndos = 2;      // Max 2 ad-based undos
  int usedUndos = 0;
  
  // Getters compatibility
  bool get canUndo => usedUndos < baseUndoCount + bonusUndoCount;
  bool get canWatchAd => !canUndo && bonusUndoCount < maxBonusUndos;
  
  void reset() {
    usedUndos = 0;
    bonusUndoCount = 0; 
    notifyListeners();
  }
  
  bool performUndo() {
    if (canUndo) {
      usedUndos++;
      notifyListeners();
      return true;
    }
    return false;
  }
  
  // Alias for compatibility if needed, or update callers
  bool useUndo() => performUndo();
  
  void addBonusUndo() {
    if (bonusUndoCount < maxBonusUndos) {
      bonusUndoCount++;
      notifyListeners();
    }
  }
  
  String getUndoText() {
    int remaining = (baseUndoCount + bonusUndoCount) - usedUndos;
    int total = baseUndoCount + bonusUndoCount;
    return "$remaining/$total";
  }
  
  // Legacy alias
  String getCounterText() => getUndoText();
}


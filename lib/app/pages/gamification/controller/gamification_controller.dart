import 'package:flutter/material.dart';
import '../model/plant_stages_data.dart'; // Contient la classe ET la liste

class GamificationController extends ChangeNotifier {
  int _xp = 0;
  int get xp => _xp;

  PlantStage get currentStage {
    return plantStages.lastWhere(
          (stage) => _xp >= stage.requiredXp,
      orElse: () => plantStages.first,
    );
  }

  double get progressToNextStage {
    final currentIndex = plantStages.indexOf(currentStage);
    if (currentIndex == plantStages.length - 1) return 1.0;

    final currentXp = currentStage.requiredXp;
    final nextXp = plantStages[currentIndex + 1].requiredXp;

    return (_xp - currentXp) / (nextXp - currentXp);
  }

  void gainXp(int amount) {
    _xp += amount;
    print("🧠 [Gamification] XP actuel : $_xp (→ ${currentStage.name})");
    notifyListeners();
  }

  void resetXp() {
    _xp = 0;
    notifyListeners();
  }
}

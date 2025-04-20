import 'package:flutter/material.dart';
import 'package:sapient/app/pages/gamification/model/plant_stages_data.dart';
import 'package:sapient/app/pages/gamification/controller/gamification_controller.dart';

class PlantHeader extends StatelessWidget {
  final PlantStage stage;
  final double progress;
  final int remainingXp;
  const PlantHeader({
    super.key,
    required this.stage,
    required this.progress,
    required this.remainingXp,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const SizedBox(height: 60),
        const Text(
          "🌱 Fais pousser ta plante",
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Colors.brown,
            fontFamily: 'Raleway',
          ),
        ),
        const SizedBox(height: 16),
        Text(
          stage.description,
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 16,
            fontStyle: FontStyle.italic,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 24),
        Container(
          height: 12,
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.3),
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: Colors.black.withOpacity(0.6), width: 1.2),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: progress,
              backgroundColor: Colors.transparent,
              valueColor: AlwaysStoppedAnimation<Color>(Colors.green.shade600),
              minHeight: 12,
            ),
          ),
        ),
        const SizedBox(height: 12),
        Text(
          stage.isFinalStage
              ? "Tu as atteint le niveau maximum 🌟"
              : "Encore $remainingXp XP pour atteindre le prochain stade !",
          style: const TextStyle(fontSize: 14),
        ),
      ],
    );
  }
}

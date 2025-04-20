import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sapient/app/pages/gamification/controller/gamification_controller.dart';
import 'package:sapient/app/pages/gamification/model/plant_stages_data.dart';

import 'plant_header.dart';
import 'water_button.dart';
import 'floating_xp_text.dart';

class PlantContent extends StatefulWidget {
  const PlantContent({super.key});

  @override
  State<PlantContent> createState() => _PlantContentState();
}

class _PlantContentState extends State<PlantContent> {
  bool _showXp = false;

  void _triggerXpAnimation(GamificationController controller) {
    setState(() => _showXp = true);
    controller.gainXp(10);
    Future.delayed(const Duration(milliseconds: 800), () {
      if (mounted) setState(() => _showXp = false);
    });
  }

  @override
  Widget build(BuildContext context) {
    final controller = Provider.of<GamificationController>(context);
    final PlantStage stage = controller.currentStage;
    final double progress = controller.progressToNextStage;
    final int remainingXp = _remainingXp(controller);

    return Stack(
      children: [
        if (_showXp)
          Positioned(
            top: 140,
            left: 0,
            right: 0,
            child: Center(child: FloatingXpText(text: "+10 XP")),
          ),

        Positioned.fill(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                PlantHeader(
                  stage: stage,
                  progress: progress,
                  remainingXp: remainingXp,
                ),
                WaterButton(onPressed: () => _triggerXpAnimation(controller)),
              ],
            ),
          ),
        ),
      ],
    );
  }

  int _remainingXp(GamificationController controller) {
    final currentStage = controller.currentStage;
    final index = plantStages.indexOf(currentStage);
    if (index < plantStages.length - 1) {
      final nextStage = plantStages[index + 1];
      return nextStage.requiredXp - controller.xp;
    }
    return 0;
  }
}
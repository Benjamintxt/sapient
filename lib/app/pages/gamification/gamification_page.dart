import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sapient/app/pages/gamification/controller/gamification_controller.dart';
import 'package:sapient/app/pages/gamification/model/plant_stages_data.dart';
import 'package:sapient/app/pages/gamification/widgets/plant_content.dart'; //  Ton widget avec barre et bouton

class GamificationPage extends StatelessWidget {
  const GamificationPage({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => GamificationController(),
      child: const _GamificationFullBackground(),
    );
  }
}

class _GamificationFullBackground extends StatelessWidget {
  const _GamificationFullBackground();

  @override
  Widget build(BuildContext context) {
    final controller = Provider.of<GamificationController>(context);
    final PlantStage stage = controller.currentStage;

    return Scaffold(
      extendBodyBehindAppBar: true,
      body: Stack(
        children: [
          _buildBackground(stage),              //  Image de fond
          const Positioned.fill(child: PlantContent()), //  Contenu au-dessus
          Positioned(                           // Bouton retour
            top: 55,
            left: 16,
            child: IconButton(
              icon: const Icon(Icons.arrow_back, color: Color(0xFF4A148C), size: 28),
              onPressed: () => Navigator.pop(context),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBackground(PlantStage stage) {
    return Stack(
      children: [
        Positioned.fill(
          child: Image.asset(
            stage.imagePath,
            key: ValueKey(stage.imagePath),
            fit: BoxFit.cover,
          ),
        ),
        Positioned.fill(
          child: Container(
            color: Colors.white.withAlpha(38),
          ),
        ),
      ],
    );
  }
}

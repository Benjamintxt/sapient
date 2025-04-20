/// 🎋 CONFIGURATION DES ÉTAPES DE LA PLANTE (GAMIFICATION)
///
/// 🧩 Ce fichier génère automatiquement la liste `plantStages` utilisée
///     dans toute l’application pour afficher les étapes de croissance.
///
/// ─────────────────────────────────────────────────────────────
/// 📌 COMMENT MODIFIER LES PALIERS XP ?
///
/// ▶️ Modifie simplement la liste `stageXpIncrements` :
///     Chaque valeur représente l'XP requis **cumulé** pour débloquer un stage.
///     Exemple :
///       [0, 100, 300, 600, 1000] →
///         - Stage 0 à partir de 0 XP
///         - Stage 1 à partir de 100 XP
///         - Stage 2 à partir de 300 XP
///         - etc.
///
/// 📌 COMMENT CHANGER LES TITRES, MESSAGES ET IMAGES ?
///
/// ▶️ Modifie la liste `_stageInfos` :
///     Chaque map contient :
///       - `name`: le nom du stage
///       - `description`: le texte affiché sous la plante
///       - `image`: le chemin vers l’image à afficher en fond
///
/// 📌 COMMENT AJOUTER UN NOUVEAU STAGE ?
///
/// ▶️ Étapes simples :
///     1. Ajoute une nouvelle entrée dans `stageXpIncrements`
///     2. Ajoute une nouvelle `Map` dans `_stageInfos`
///
/// ⚠️ Les deux listes doivent avoir **exactement le même nombre d’éléments**.
///
/// 📌 COMMENT CHANGER LA LOGIQUE ?
/*
   - Le code plus bas utilise `.List.generate(...)` pour combiner les deux listes.
   - Le dernier stage est automatiquement marqué `isFinalStage: true`.
   - Tu n’as rien à modifier dans les widgets Flutter eux-mêmes.
*/
/// ─────────────────────────────────────────────────────────────


/// 📦 Modèle d’un niveau de plante
class PlantStage {
  final String name;
  final String description;
  final int requiredXp;
  final String imagePath;
  final bool isFinalStage;

  const PlantStage({
    required this.name,
    required this.description,
    required this.requiredXp,
    required this.imagePath,
    this.isFinalStage = false,
  });
}

/// 🧠 Configuration simplifiée pour chaque palier
const List<int> stageXpIncrements = [0, 100, 200, 300, 400]; // XP nécessaires cumulés

const List<Map<String, String>> _stageInfos = [
  {
    "name": "Graine",
    "description": "Chaque graine de savoir compte 🌱",
    "image": "assets/images/plant_stages/stage_0.png",
  },
  {
    "name": "Pousse",
    "description": "Tu as commencé à arroser ta curiosité 🍃",
    "image": "assets/images/plant_stages/stage_1.png",
  },
  {
    "name": "Premières fleurs",
    "description": "Une floraison de savoir 🌼",
    "image": "assets/images/plant_stages/stage_2.png",
  },
  {
    "name": "Petit arbre en fleurs",
    "description": "Ta connaissance prend racine 🌸",
    "image": "assets/images/plant_stages/stage_3.png",
  },
  {
    "name": "Bonsaï sacré",
    "description": "Un arbre de sagesse en pleine forme 🪴",
    "image": "assets/images/plant_stages/stage_4.png",
  },
];

/// 🌿 Liste finale des stages, générée dynamiquement
final List<PlantStage> plantStages = List.generate(_stageInfos.length, (index) {
  final info = _stageInfos[index];
  final isFinal = index == _stageInfos.length - 1;

  return PlantStage(
    name: info["name"]!,
    description: info["description"]!,
    requiredXp: stageXpIncrements[index],
    imagePath: info["image"]!,
    isFinalStage: isFinal,
  );
});

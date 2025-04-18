// 📄 profile_page.dart
// 👤 Page de profil utilisateur avec design floral/pastel + édition + stats

import 'package:flutter/material.dart'; // 🎨 Composants UI
import 'package:flutter_gen/gen_l10n/app_localizations.dart'; // 🌍 Traductions multilingues
import 'profile_editable_card.dart'; // ✏️ Carte modifiable
import 'profile_static_card.dart'; // 🔒 Carte statique
import 'profile_icon_card.dart'; // 🌐 Carte avec icône
import 'edit_dialog.dart'; // 📝 Dialogue d'édition
import 'language_picker_dialog.dart'; // 🌍 Dialogue choix de langue
import 'package:sapient/app/pages/user/statistics/statistics_page.dart'; // 📊 Page des stats

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key}); // 🔑 Constructeur avec clé optionnelle

  @override
  State<ProfilePage> createState() => _ProfilePageState(); // 🧠 Création de l'état
}

class _ProfilePageState extends State<ProfilePage> {
  final String userEmail = 'example@example.com'; // 📧 Email de l'utilisateur (exemple statique)
  final String userName = 'John Doe'; // 👤 Nom utilisateur (statique)
  final String userObjectives = 'Apprendre Flutter et Dart'; // 🎯 Objectifs (statique)

  @override
  Widget build(BuildContext context) {
    final local = AppLocalizations.of(context)!; // 🌍 Chargement des traductions

    return Scaffold(
      extendBodyBehindAppBar: true, // 🪟 Fond visible sous la barre d'app
      backgroundColor: Colors.transparent, // 🎨 Fond transparent pour laisser voir l'image
      body: Stack(
        children: [
          // 🌸 Image de fond pastel
          Positioned.fill(
            child: Image.asset(
              'assets/images/Screen profil.png', // 🖼️ Image à afficher
              fit: BoxFit.cover, // 🔳 Remplir tout l'écran
            ),
          ),

          // 🌫️ Voile blanc pour lisibilité du texte
          Positioned.fill(
            child: Container(color: Colors.white.withAlpha(38)),
          ),

          // 🔙 Bouton retour (en haut à gauche)
          Positioned(
            top: 55, // ↕️ Distance depuis le haut
            left: 16, // ↔️ Distance depuis la gauche
            child: IconButton(
              icon: const Icon(Icons.arrow_back, color: Color(0xFF4A148C), size: 28), // 🎨 Icône flèche violette
              onPressed: () => Navigator.pop(context), // 🔙 Revenir en arrière
            ),
          ),

          // 🏷️ Titre centré "Profil"
          Positioned(
            top: 50,
            left: 0,
            right: 0,
            child: Center(
              child: Text(
                local.profile, // 🌍 Traduction du mot "Profil"
                style: const TextStyle(
                  fontSize: 32, // 🔠 Taille du titre
                  fontWeight: FontWeight.bold, // 🅱️ Gras
                  color: Color(0xFF4A148C), // 🎨 Couleur violette
                  fontFamily: 'Raleway', // ✏️ Police personnalisée
                  shadows: [
                    Shadow(blurRadius: 3, color: Colors.black26, offset: Offset(1, 2)), // 🌫️ Effet d'ombre
                  ],
                ),
              ),
            ),
          ),

          // 🧱 Contenu principal
          Positioned.fill(
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20), // 🧱 Marges
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center, // ↔️ Centrage horizontal
                  children: [
                    // 👤 Icône de profil (avatar)
                    CircleAvatar(
                      radius: 48, // ⚪ Taille du cercle
                      backgroundColor: Colors.deepPurple.shade100, // 🎨 Violet clair
                      child: const Icon(Icons.person, size: 48, color: Colors.deepPurple), // 👤 Icône au centre
                    ),

                    const SizedBox(height: 32), // ↕️ Espace

                    // ✏️ Carte modifiable : nom
                    ProfileEditableCard(
                      label: local.profile_name, // 🏷️ "Nom"
                      value: userName, // 🔠 Valeur du nom
                      onEdit: () => showEditDialog(
                        context: context,
                        field: 'name',
                        currentValue: userName,
                        onSave: (newValue) {
                          setState(() {
                            // TODO: enregistrer le nouveau nom
                          });
                        },
                      ),
                    ),

                    const SizedBox(height: 12),

                    // 🔒 Carte statique : email
                    ProfileStaticCard(
                      label: local.profile_email, // 🏷️ "Email"
                      value: userEmail,
                    ),

                    const SizedBox(height: 12),

                    // ✏️ Carte modifiable : objectifs
                    ProfileEditableCard(
                      label: local.learning_objectives, // 🏷️ "Objectifs"
                      value: userObjectives,
                      onEdit: () => showEditDialog(
                        context: context,
                        field: 'objectives',
                        currentValue: userObjectives,
                        onSave: (newValue) {
                          setState(() {
                            // TODO: enregistrer les objectifs
                          });
                        },
                      ),
                    ),

                    const SizedBox(height: 12),

                    // 🌐 Carte langue avec icône
                    ProfileIconCard(
                      label: local.change_language,
                      icon: Icons.language, // 🌍 Icône
                      onTap: () => _showLanguagePickerDialog(context), // 📤 Affiche le dialogue
                    ),

                    const Spacer(), // 📏 Pousse le bouton vers le bas

                    // 📊 Bouton stats centré en bas
                    Center(
                      child: FloatingActionButton(
                        heroTag: 'stats_btn', // 🏷️ ID unique
                        backgroundColor: Colors.deepPurple, // 🎨 Violet
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => const StatisticsPage()), // 📊 Ouvre la page des statistiques
                          );
                        },
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)), // 🟣 Coins arrondis
                        child: const Icon(Icons.bar_chart, color: Colors.white), // 📊 Icône
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// 🌍 Ouvre le dialogue pour changer la langue
  void _showLanguagePickerDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => const LanguagePickerDialog(),
    );
  }
}

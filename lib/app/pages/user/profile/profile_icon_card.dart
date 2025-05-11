//  profile_icon_card.dart
//  Widget pour afficher une carte avec une icône, pour une action rapide dans le profil.

import 'package:flutter/material.dart'; //  UI Flutter

//  Active ou désactive les logs de debug pour les cartes avec icône
const bool kEnableProfileIconCardLogs = false;

///  Log conditionnel pour les cartes avec icône
void logProfileIconCard(String message) {
  if (kEnableProfileIconCardLogs) print('[ProfileIconCard] $message');
}

///  Widget qui affiche une carte avec une icône (pour actions comme changer de langue, etc.)
class ProfileIconCard extends StatelessWidget {
  final String label; //  Label du champ (ex: "Changer de langue")
  final IconData icon; //  Icône à afficher (ex: Icône de langue)
  final VoidCallback onTap; //  Fonction à exécuter quand on tape

  const ProfileIconCard({
    super.key,
    required this.label,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    logProfileIconCard(' Affichage d’une carte avec icône : $label');

    return Card(
      color: Colors.white.withAlpha(229), //  Fond semi-transparent
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)), //  Coins arrondis
      elevation: 4, //  Ombre portée
      child: ListTile(
        title: Text(
          label, //  Affiche le label à gauche (ex : "Changer de langue")
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.deepPurple),
        ),
        trailing: Icon(
          icon, //  Affiche l'icône à droite (ex : Icône de langue)
          color: Colors.deepPurple, //  Couleur violette de l'icône
        ),
        onTap: onTap, // 📱 Action à réaliser au clic
      ),
    );
  }
}

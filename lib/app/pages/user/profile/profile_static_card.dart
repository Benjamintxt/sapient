//  profile_static_card.dart
//  Widget pour afficher une carte de profil non modifiable (ex: e-mail utilisateur)

import 'package:flutter/material.dart'; //  UI Flutter

//  Active ou désactive les logs de debug pour les cartes statiques
const bool kEnableProfileCardLogs = false;

///  Log conditionnel pour les cartes statiques
void logProfileCard(String message) {
  if (kEnableProfileCardLogs) print('[ProfileStaticCard] $message');
}

///  Widget qui affiche un champ de profil non éditable
class ProfileStaticCard extends StatelessWidget {
  final String label; // ️ Titre de la ligne (ex: "E-mail")
  final String value; //  Valeur à afficher (ex: adresse email)

  const ProfileStaticCard({
    super.key,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    logProfileCard(' Affichage d’une carte statique : $label');

    return Card(
      color: Colors.white.withAlpha(229), //  Fond semi-transparent blanc pour lisibilité
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16), //  Coins arrondis pour un look doux
      ),
      elevation: 4, //  Effet d’ombre pour surélever visuellement la carte
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16), //  Espacement interne vertical/horizontal
        child: Row(
          children: [
            Expanded( //  Prend tout l’espace disponible
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start, // Aligne les éléments à gauche
                children: [
                  Text(
                    label, //  Affiche le nom du champ (ex: "Adresse email")
                    style: const TextStyle(
                      fontSize: 16, // Taille du titre
                      fontWeight: FontWeight.bold, // Titre en gras
                      color: Colors.deepPurple, // Couleur violette pour cohérence de thème
                    ),
                  ),
                  const SizedBox(height: 4), // Petit espace entre le label et la valeur
                  Text(
                    value, //  Affiche la valeur statique (ex: email de l’utilisateur)
                    style: const TextStyle(
                      fontSize: 14, //  Taille plus petite pour le contenu
                      color: Colors.black87, // Couleur gris foncé
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

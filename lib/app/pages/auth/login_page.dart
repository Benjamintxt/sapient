import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});
  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // 🌸 Image de fond plein écran
          Positioned.fill(
            child: Image.asset(
              'assets/images/Screen Connexion.png',
              fit: BoxFit.cover,
            ),
          ),

          // 🌫️ Couleur par-dessus l’image (effet doux)
          Positioned.fill(
            child: Container(
              color: Colors.white.withAlpha(51),
            ),
          ),

          // 🌸 Contenu centré (logo, formulaire)
          Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const SizedBox(height: 64),
                  const Text(
                    "Sapient",
                    style: TextStyle(
                      fontSize: 42,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF4A148C),
                      fontFamily: 'Raleway',
                    ),
                  ),
                  const SizedBox(height: 360), // Ajout pour décaler vers le bas
                  TextField(
                    controller: emailController,
                    decoration: InputDecoration(
                      hintText: "Email",
                      filled: true,
                      fillColor: Colors.white.withAlpha(229),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide.none,
                      ),
                    ),
                    keyboardType: TextInputType.emailAddress,
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: passwordController,
                    obscureText: true,
                    decoration: InputDecoration(
                      hintText: "Mot de passe",
                      filled: true,
                      fillColor: Colors.white..withAlpha(229),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),

                  const SizedBox(height: 30), // 👆 remonte les boutons

                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      // 🔓 Se connecter
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.deepPurple..withAlpha(229),
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black..withAlpha(51),
                              blurRadius: 6,
                              offset: const Offset(0, 3),
                            ),
                          ],
                        ),
                        child: IconButton(
                          onPressed: () async {
                            try {
                              await FirebaseAuth.instance.signInWithEmailAndPassword(
                                email: emailController.text.trim(),
                                password: passwordController.text.trim(),
                              );
                            } catch (e) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text("Erreur de connexion : ${e.toString()}")),
                              );
                            }
                          },
                          icon: const Icon(Icons.login, size: 30, color: Colors.white),
                          padding: const EdgeInsets.all(16),
                        ),
                      ),

                      // 🔑 Mot de passe oublié
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.deepPurple..withAlpha(229),
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black..withAlpha(51),
                              blurRadius: 6,
                              offset: const Offset(0, 3),
                            ),
                          ],
                        ),
                        child: IconButton(
                          onPressed: () async {
                            try {
                              await FirebaseAuth.instance.sendPasswordResetEmail(
                                email: emailController.text.trim(),
                              );
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text("Email de réinitialisation envoyé")),
                              );
                            } catch (e) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text("Erreur : ${e.toString()}")),
                              );
                            }
                          },

                          icon: const Icon(Icons.lock_reset, size: 30, color: Colors.white),
                          padding: const EdgeInsets.all(16),
                        ),
                      ),

                      // ➕ Créer un compte
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.deepPurple..withAlpha(229),
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black..withAlpha(51),
                              blurRadius: 6,
                              offset: const Offset(0, 3),
                            ),
                          ],
                        ),
                        child: IconButton(
                          onPressed: () async {
                            try {
                              await FirebaseAuth.instance.createUserWithEmailAndPassword(
                                email: emailController.text.trim(),
                                password: passwordController.text.trim(),
                              );
                            } catch (e) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text("Erreur création : ${e.toString()}")),
                              );
                            }
                          },

                          icon: const Icon(Icons.person_add_alt_1, size: 30, color: Colors.white),
                          padding: const EdgeInsets.all(16),
                        ),
                      ),
                    ],
                  ),



                ],
              ),
            ),
          ),
        ],
      ),

    );
  }
}

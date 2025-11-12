// Fichier: page_connexion.dart

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:crypto/crypto.dart'; 
import 'dart:convert'; 

// Importation des fichiers nécessaires
import 'page_inscription.dart';
import 'services/database_manager.dart'; 

class PageConnexion extends StatefulWidget {
  const PageConnexion({super.key});

  @override
  State<PageConnexion> createState() => _PageConnexionState();
}

class _PageConnexionState extends State<PageConnexion> {
  final _formKey = GlobalKey<FormState>();
  
  final TextEditingController _nomUtilisateurController = TextEditingController();
  final TextEditingController _motDePasseController = TextEditingController();
  
  String? _errorMessage;
  bool _isLoading = false;

  @override
  void dispose() {
    _nomUtilisateurController.dispose();
    _motDePasseController.dispose();
    super.dispose();
  }
  
  // ----------------------------------------------------
  // LOGIQUE DE CONNEXION (Inchagngée)
  // ----------------------------------------------------
  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _errorMessage = null; 
      _isLoading = true;
    });

    final String nomUtilisateur = _nomUtilisateurController.text.trim();
    final String motDePasse = _motDePasseController.text;
    
    // Utilisation du même hachage simple (SHA-256) pour la vérification
    final String inputHash = sha256.convert(utf8.encode(motDePasse)).toString();

    try {
      final int? userId = await DatabaseManager.instance.getUserForLogin(nomUtilisateur, inputHash);

      if (userId != null && userId > 0) {
        // SUCCÈS : Enregistrer la session
        final prefs = await SharedPreferences.getInstance();
        await prefs.setInt('user_id', userId); 

        // Navigation vers la page des tâches
        if (mounted) {
          Navigator.of(context).pushReplacementNamed('/tasks');
        }
      } else {
        // ÉCHEC : Afficher le message d'erreur
        setState(() {
          _errorMessage = "Nom d'utilisateur ou mot de passe incorrect.";
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = "Une erreur est survenue lors de la connexion.";
      });
      print('Erreur de connexion: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  // ----------------------------------------------------
  // INTERFACE UTILISATEUR AVEC LOGO MIS À JOUR
  // ----------------------------------------------------
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(32.0),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                
                // 1. LOGO DE L'APPLICATION (MODIFIÉ)
                Center(
                  child: SizedBox(
                    width: 225, 
                    height: 200, 
                    child: ClipRRect( // AJOUTÉ POUR L'ARRONDI
                      borderRadius: BorderRadius.circular(10.0), // 👈 RAYON SIGNIFICATIF POUR UN EFFET PROFESSIONNEL
                      child: Image.asset(
                        // Images logo
                        'asset/images/logo.png', 
                        fit: BoxFit.cover, // 👈 MODIFIÉ POUR REMPLIR L'ESPACE ARRONDIE
                        // Si l'image n'est pas trouvée, afficher un placeholder
                        errorBuilder: (context, error, stackTrace) => Container(
                          decoration: BoxDecoration(
                            color: Colors.blueGrey.shade100,
                            // Utilise le même rayon pour le placeholder en cas d'erreur
                            borderRadius: BorderRadius.circular(60.0), 
                            border: Border.all(color: Colors.blueGrey.shade200),
                          ),
                          child: const Center(
                            child: Text(
                              'TODO',
                              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                
                // 2. MESSAGE DE BIENVENUE/RETOUR
                const Text(
                  'Vos tâches vous attendent.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 25, fontWeight: FontWeight.bold),
                ),
                const Text(
                  'Veuillez vous connecter pour accéder à vos notes.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 16, color: Colors.grey),
                ),
                const SizedBox(height: 40),

                // 3. FORMULAIRE DE CONNEXION (Champs inchangés)
                
                // Champ Nom d'utilisateur
                TextFormField(
                  controller: _nomUtilisateurController,
                  decoration: const InputDecoration(
                    labelText: 'Nom d\'utilisateur',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.person),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Veuillez entrer votre nom d\'utilisateur.';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 20),

                // Champ Mot de passe
                TextFormField(
                  controller: _motDePasseController,
                  obscureText: true,
                  decoration: const InputDecoration(
                    labelText: 'Mot de passe',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.lock),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Veuillez entrer votre mot de passe.';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 30),

                // Message d'erreur
                if (_errorMessage != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 15.0),
                    child: Text(
                      _errorMessage!,
                      style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
                      textAlign: TextAlign.center,
                    ),
                  ),
                
                // Bouton de Connexion
                ElevatedButton(
                  onPressed: _isLoading ? null : _handleLogin,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 15),
                    textStyle: const TextStyle(fontSize: 18),
                  ),
                  child: _isLoading 
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text('Se connecter'),
                ),
                const SizedBox(height: 20),

                // Lien vers la page d'inscription
                TextButton(
                  onPressed: () {
                    // Utilisation de MaterialPageRoute pour naviguer vers l'inscription (au lieu de la route nommée pour la simplicité ici)
                    Navigator.of(context).push(
                      MaterialPageRoute(builder: (context) => const PageInscription()),
                    );
                  },
                  child: const Text("Pas encore de compte ? Inscrivez-vous !"),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
// Fichier: page_inscription.dart

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:crypto/crypto.dart'; // Pour le hachage du mot de passe
import 'dart:convert'; // Pour l'encodage UTF-8

// Importation des fichiers nécessaires
import 'services/database_manager.dart';
import 'modele/utilisateurs_modele.dart';

class PageInscription extends StatefulWidget {
  const PageInscription({super.key});

  @override
  State<PageInscription> createState() => _PageInscriptionState();
}

class _PageInscriptionState extends State<PageInscription> {
  final _formKey = GlobalKey<FormState>();
  
  final TextEditingController _nomUtilisateurController = TextEditingController();
  final TextEditingController _motDePasseController = TextEditingController();
  final TextEditingController _confirmationMotDePasseController = TextEditingController();
  
  String? _errorMessage;
  bool _isLoading = false;

  @override
  void dispose() {
    _nomUtilisateurController.dispose();
    _motDePasseController.dispose();
    _confirmationMotDePasseController.dispose();
    super.dispose();
  }
  
  // ----------------------------------------------------
  // LOGIQUE D'INSCRIPTION
  // ----------------------------------------------------
  Future<void> _handleSignup() async {
    // 1. Validation du formulaire
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _errorMessage = null;
      _isLoading = true;
    });

    final String nomUtilisateur = _nomUtilisateurController.text.trim();
    final String motDePasse = _motDePasseController.text;

    try {
      // 2. Vérification de l'unicité du nom d'utilisateur
      final isUnique = await DatabaseManager.instance.isUsernameUnique(nomUtilisateur);

      if (!isUnique) {
        setState(() {
          _errorMessage = "Ce nom d'utilisateur est déjà utilisé.";
          _isLoading = false;
        });
        return;
      }
      
      // 3. Hachage sécurisé du mot de passe
      // REMARQUE: SHA-256 est utilisé ici pour la simplicité, 
      // mais des fonctions plus robustes comme bcrypt ou Argon2 sont recommandées en production.
      final String passwordHash = sha256.convert(utf8.encode(motDePasse)).toString();

      // 4. Création du modèle utilisateur sans ID (sera généré par la DB)
      final newUser = Utilisateur.sansId(
        nomUtilisateur: nomUtilisateur, 
        motDePasseHache: passwordHash,
      );

      // 5. Insertion dans la base de données
      final newUserId = await DatabaseManager.instance.insertUser(newUser);

      if (newUserId > 0) {
        // 6. SUCCÈS : Enregistrer la session et naviguer
        final prefs = await SharedPreferences.getInstance();
        await prefs.setInt('user_id', newUserId);

        // Navigation vers la page des tâches (TaskListScreen)
        if (mounted) {
          // Utilisation de pushReplacementNamed pour remplacer l'écran actuel par la liste de tâches
          Navigator.of(context).pushReplacementNamed('/tasks');
        }
      } else {
         // Erreur non gérée par isUnique (rare)
        setState(() {
          _errorMessage = "Échec de l'inscription. Veuillez réessayer.";
        });
      }

    } catch (e) {
      setState(() {
        _errorMessage = "Une erreur serveur/DB est survenue: $e";
      });
      print('Erreur d\'inscription: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  // ----------------------------------------------------
  // INTERFACE UTILISATEUR
  // ----------------------------------------------------
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Inscription"),
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(32.0),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                const Text(
                  'Créer votre compte',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 40),

                // Champ Nom d'utilisateur
                TextFormField(
                  controller: _nomUtilisateurController,
                  decoration: const InputDecoration(
                    labelText: 'Nom d\'utilisateur',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.person_add),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Veuillez choisir un nom d\'utilisateur.';
                    }
                    if (value.length < 3) {
                      return 'Le nom d\'utilisateur doit avoir au moins 3 caractères.';
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
                    prefixIcon: Icon(Icons.lock_open),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Veuillez entrer un mot de passe.';
                    }
                    if (value.length < 6) {
                      return 'Le mot de passe doit avoir au moins 6 caractères.';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 20),
                
                // Champ Confirmation Mot de passe
                TextFormField(
                  controller: _confirmationMotDePasseController,
                  obscureText: true,
                  decoration: const InputDecoration(
                    labelText: 'Confirmer le mot de passe',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.lock_outline),
                  ),
                  validator: (value) {
                    if (value != _motDePasseController.text) {
                      return 'Les mots de passe ne correspondent pas.';
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
                
                // Bouton d'Inscription
                ElevatedButton(
                  onPressed: _isLoading ? null : _handleSignup,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 15),
                    textStyle: const TextStyle(fontSize: 18),
                  ),
                  child: _isLoading 
                    ? const CircularProgressIndicator(color: Colors.white) 
                    : const Text('S\'inscrire'),
                ),
                const SizedBox(height: 20),

                // Lien vers la page de connexion
                TextButton(
                  onPressed: () {
                    // Revenir à la page de connexion
                    Navigator.of(context).pop(); 
                  },
                  child: const Text("J'ai déjà un compte ? Me connecter"),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
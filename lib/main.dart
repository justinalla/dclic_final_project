// Fichier: main.dart

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'page_connexion.dart';
import 'page_inscription.dart'; 
import 'taches_interface.dart'; 

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MonAppToDo());
}

// ----------------------------------------------------
// Le Widget principal de l'application
//------------------------------------------------------

class MonAppToDo extends StatelessWidget {
  const MonAppToDo({super.key});

  @override
  Widget build(BuildContext context) {
    // Définition de la couleur primaire (Teal/Sarcelle)
    const MaterialColor primaryTeal = Colors.teal;

    return MaterialApp(
      title: 'Ma ToDo List',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        // Utilise la couleur Teal comme couleur primaire
        primarySwatch: primaryTeal,
        visualDensity: VisualDensity.adaptivePlatformDensity,
        
        // --- 1. Thème de l'AppBar : Appliqué aux pages qui en ont une (Inscription, Tâches, Formulaire) ---
        appBarTheme: AppBarTheme(
          // Couleur de fond élégante (Teal sombre)
          backgroundColor: primaryTeal.shade800, 
          // Icônes et flèches en blanc (pour le contraste)
          iconTheme: const IconThemeData(color: Colors.white),
          // Style du titre en blanc, gras
          titleTextStyle: const TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
          elevation: 4,
        ),
        
        // --- 2. Thème des Boutons Surélevés (ElevatedButton) : Appliqué à TOUS les boutons (y compris Connexion) ---
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            // Fond du bouton (Teal légèrement plus clair)
            backgroundColor: primaryTeal.shade600, 
            // Texte du bouton en blanc
            foregroundColor: Colors.white, 
            
            // Coins arrondis et ombre
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            elevation: 3,
            
            // Padding et style de texte
            padding: const EdgeInsets.symmetric(vertical: 15),
            textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
        ),

        // --- 3. Thème du Bouton Flottant (FAB) ---
        floatingActionButtonTheme: const FloatingActionButtonThemeData(
          backgroundColor: primaryTeal,
          foregroundColor: Colors.white,
        ),
      ),

      // C'est ici que nous déterminons la première page
      home: const SplashCheckSession(),

      // Définition des routes pour la navigation
      routes: {
        '/login': (context) => const PageConnexion(),
        '/tasks': (context) => const TachesInterface(),
        '/signup': (context) => const PageInscription(),
      },
    );
  }
}

// ----------------------------------------------------
// Widget pour vérifier la session au démarrage (inchangé)
// ----------------------------------------------------
class SplashCheckSession extends StatefulWidget {
  const SplashCheckSession({super.key});

  @override
  State<SplashCheckSession> createState() => _SplashCheckSessionState();
}

class _SplashCheckSessionState extends State<SplashCheckSession> {
  
  Future<void> _checkLoginStatus() async {
    final prefs = await SharedPreferences.getInstance();
    final int? userId = prefs.getInt('user_id');

    await Future.delayed(const Duration(seconds: 1)); 

    if (!mounted) return;

    if (userId != null && userId > 0) {
      Navigator.of(context).pushReplacementNamed('/tasks');
    } else {
      Navigator.of(context).pushReplacementNamed('/login');
    }
  }

  @override
  void initState() {
    super.initState();
    _checkLoginStatus(); 
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 20),
            Text("Vérification de la session...")
          ],
        ),
      ),
    );
  }
}
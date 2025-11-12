// Fichier: lib/services/database_manager.dart

import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Importation des modèles de données
import '../modele/utilisateurs_modele.dart';
import '../modele/tache_modele.dart';

class DatabaseManager {
  
  // Constantes de la Base de Données
  static Database? _database;
  static const String _databaseName = 'todo_app.db';
  static const int _databaseVersion = 1;

  // Noms des Tables
  static const String tableUsers = 'users';
  static const String tableTasks = 'tasks';

  // Colonnes de la Table 'users'
  static const String columnUserId = 'id';
  static const String columnUserNom = 'nom_utilisateur';
  static const String columnUserPasswordHash = 'mot_de_passe_hache';
  
  // Colonnes de la Table 'tasks'
  static const String columnTaskId = 'id';
  static const String columnTaskUserId = 'user_id';
  static const String columnTaskTitre = 'titre';
  static const String columnTaskDescription = 'description';
  static const String columnTaskIsDone = 'is_done';
  
  // ----------------------------------------------------
  // Singleton Pattern pour éviter les multiples instances
  // ----------------------------------------------------

  DatabaseManager._privateConstructor();
  static final DatabaseManager instance = DatabaseManager._privateConstructor();

  // Getter pour la base de données

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  // Initialisation de la base de données

  Future<Database> _initDatabase() async {
    String path = join(await getDatabasesPath(), _databaseName);
    return await openDatabase(
      path,
      version: _databaseVersion,
      onCreate: _onCreate,
    );
  }

  // ----------------------------------------------------
  // Création des Tables
  // ----------------------------------------------------

  Future _onCreate(Database db, int version) async {

    // Création de la table Utilisateurs
    await db.execute('''
      CREATE TABLE ${DatabaseManager.tableUsers} (
        ${DatabaseManager.columnUserId} INTEGER PRIMARY KEY AUTOINCREMENT,
        ${DatabaseManager.columnUserNom} TEXT UNIQUE,
        ${DatabaseManager.columnUserPasswordHash} TEXT
      )
    ''');

    // Création de la table Tâches avec Clé Étrangère
    await db.execute('''
      CREATE TABLE ${DatabaseManager.tableTasks} (
        ${DatabaseManager.columnTaskId} INTEGER PRIMARY KEY AUTOINCREMENT,
        ${DatabaseManager.columnTaskUserId} INTEGER,
        ${DatabaseManager.columnTaskTitre} TEXT NOT NULL,
        ${DatabaseManager.columnTaskDescription} TEXT,
        ${DatabaseManager.columnTaskIsDone} INTEGER DEFAULT 0,
        FOREIGN KEY (${DatabaseManager.columnTaskUserId}) 
            REFERENCES ${DatabaseManager.tableUsers} (${DatabaseManager.columnUserId}) ON DELETE CASCADE
      )
    ''');
  }

  // ----------------------------------------------------
  // OPÉRATIONS UTILISATEUR (Authentification)
  // ----------------------------------------------------

  // Inscription : Insérer un nouvel utilisateur
  Future<int> insertUser(Utilisateur user) async {
    Database db = await instance.database;
    return await db.insert(
      DatabaseManager.tableUsers,
      user.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }
  
  // Vérification de l'unicité du nom d'utilisateur (pour l'inscription)

  Future<bool> isUsernameUnique(String nomUtilisateur) async {
    Database db = await instance.database;
    final List<Map<String, dynamic>> maps = await db.query(
      DatabaseManager.tableUsers,
      where: '${DatabaseManager.columnUserNom} = ?',
      whereArgs: [nomUtilisateur],
    );
    return maps.isEmpty;
  }

  // Connexion : Récupérer l'ID utilisateur pour validation (Mot de passe déjà haché)

  Future<int?> getUserForLogin(String nomUtilisateur, String motDePasseHache) async {
    Database db = await instance.database;
    final List<Map<String, dynamic>> maps = await db.query(
      DatabaseManager.tableUsers,
      columns: [DatabaseManager.columnUserId],
      where: '${DatabaseManager.columnUserNom} = ? AND ${DatabaseManager.columnUserPasswordHash} = ?',
      whereArgs: [nomUtilisateur, motDePasseHache],
      limit: 1,
    );

    if (maps.isNotEmpty) {
      return maps.first[DatabaseManager.columnUserId] as int;
    }
    return null; // Connexion échouée
  }
  
  // ----------------------------------------------------
  // OPÉRATIONS TÂCHES (CRUD)
  // ----------------------------------------------------

  // Créer une nouvelle tâche
  Future<int> createTask(Tache tache) async {
    Database db = await instance.database;
    return await db.insert(DatabaseManager.tableTasks, tache.toMap());
  }

  // Récupérer toutes les tâches d'un utilisateur spécifique

  Future<List<Tache>> getTasksByUserId(int userId) async {
    Database db = await instance.database;
    final List<Map<String, dynamic>> maps = await db.query(
      DatabaseManager.tableTasks,
      where: '${DatabaseManager.columnTaskUserId} = ?',
      whereArgs: [userId],
      orderBy: '${DatabaseManager.columnTaskId} DESC', // Tri par ID, du plus récent au plus ancien
    );

    return List.generate(maps.length, (i) {
      return Tache.fromMap(maps[i]);
    });
  }

  // Mettre à jour une tâche (titre, description)

  Future<int> updateTask(Tache tache) async {
    Database db = await instance.database;
    return await db.update(
      DatabaseManager.tableTasks,
      tache.toMap(),
      where: '${DatabaseManager.columnTaskId} = ? AND ${DatabaseManager.columnTaskUserId} = ?',
      whereArgs: [tache.id, tache.userId],
    );
  }

  // Mettre à jour le statut (terminé/en cours)
  
  Future<int> updateTaskStatus(int taskId, int userId, bool isDone) async {
    Database db = await instance.database;
    return await db.update(
      DatabaseManager.tableTasks,
      {DatabaseManager.columnTaskIsDone: isDone ? 1 : 0},
      where: '${DatabaseManager.columnTaskId} = ? AND ${DatabaseManager.columnTaskUserId} = ?',
      whereArgs: [taskId, userId],
    );
  }

  // Supprimer une tâche
  Future<int> deleteTask(int taskId, int userId) async {
    Database db = await instance.database;
    return await db.delete(
      DatabaseManager.tableTasks,
      where: '${DatabaseManager.columnTaskId} = ? AND ${DatabaseManager.columnTaskUserId} = ?',
      whereArgs: [taskId, userId],
    );
  }

  // ----------------------------------------------------
  // GESTION DE LA DÉCONNEXION/SESSION
  // ----------------------------------------------------
  Future<void> logOut() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('user_id'); // Supprime l'ID utilisateur de la mémoire locale
  }

  // Fermer la base de données (Utile pour le nettoyage, souvent non nécessaire pour les apps mobiles)
  Future<void> close() async {
    if (_database != null) {
      Database db = await instance.database;
      db.close();
      _database = null; // Réinitialiser l'instance
    }
  }
}
// Fichier: lib/Modèle/tache_modele.dart

class Tache {
  // Attributs de la classe
  int? id; // Clé primaire auto-incrémentée
  int userId; // Clé étrangère : lie la tâche à un utilisateur // Avec des recherches il est nécessaire
  String titre;
  String? description; // Optionnel, l'utilisateur peut décrire une t$eche ou non
  int isDone; // Statut de la tâche 

  // 1. Constructeur complet (pour la récupération et la mise à jour)

  Tache({
    this.id,
    required this.userId,
    required this.titre,
    this.description,
    this.isDone = 0, // Défaut à 0 (en cours)
  });

  // 2. Constructeur sans ID (pour l'insertion d'une nouvelle tâche)

  Tache.sansId({
    required this.userId,
    required this.titre,
    this.description,
    this.isDone = 0,
  }) : id = null;

  // ----------------------------------------------------
  // Méthode pour convertir un objet Tache en Map (pour l'insertion/mise à jour sqflite)
  // ----------------------------------------------------

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'user_id': userId, // Nom de colonne dans la base de données
      'titre': titre,
      'description': description,
      'is_done': isDone,
    };
  }

  // ----------------------------------------------------
  // Méthode pour créer un objet Tache à partir d'un Map (récupération de sqflite)
  // ----------------------------------------------------
  factory Tache.fromMap(Map<String, dynamic> map) {
    return Tache(
      id: map['id'] as int?,
      userId: map['user_id'] as int,
      titre: map['titre'] as String,
      // Le champ description pourrait être null dans la DB
      description: map['description'] as String?, 
      // Le statut est stocké comme INTEGER (0 ou 1) en SQLite
      isDone: map['is_done'] as int, 
    );
  }

  @override
  String toString() {
    return 'Tache{id: $id, userId: $userId, titre: $titre, isDone: $isDone}';
  }
}
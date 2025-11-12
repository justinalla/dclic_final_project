// Fichier: lib/Modèle/utilisateur_modele.dart

class Utilisateur {
  // Attributs de la classe 
  int? id; // Clé primaire avec auto-incrémentation 
  String nomUtilisateur;
  String motDePasseHache; // stockage de mot de passe HACHÉ

  // 1. Constructeur avec tous les attributs (pour la récupération depuis la BD)

  Utilisateur({
    this.id,
    required this.nomUtilisateur,
    required this.motDePasseHache,
  });

  // 2. Constructeur sans l'attribut id (pour l'insertion)

  Utilisateur.sansId({
    required this.nomUtilisateur,
    required this.motDePasseHache,
  }) : id = null; // Initialise explicitement id à null

  // ----------------------------------------------------
  // Méthode pour convertir un objet Utilisateur en Map (pour l'insertion/mise à jour)
  // ----------------------------------------------------

  Map<String, dynamic> toMap() {
    return {
      // Inclure l'ID uniquement s'il est non-nul
      if (id != null) 'id': id, 
      'nom_utilisateur': nomUtilisateur,
      'mot_de_passe_hache': motDePasseHache,
    };
  }

  // ----------------------------------------------------
  // Méthode pour créer un objet Utilisateur à partir d'un Map (récupération de sqflite)
  // ----------------------------------------------------

  factory Utilisateur.fromMap(Map<String, dynamic> map) {
    return Utilisateur(
      id: map['id'] as int?,
      nomUtilisateur: map['nom_utilisateur'] as String,
      motDePasseHache: map['mot_de_passe_hache'] as String,
    );
  }

  @override
  String toString() {
    return 'Utilisateur{id: $id, nomUtilisateur: $nomUtilisateur}';
  }
}
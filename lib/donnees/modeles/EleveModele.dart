/// Modèle représentant un élève dans la base de données Firestore.
/// Chaque élève est lié à un utilisateur existant dans la collection "utilisateurs".
class EleveModele {
  /// ID du document Firestore dans la collection "eleves".
  final String id;

  /// ID de l'utilisateur associé à cet élève (clé étrangère).
  final String utilisateurId;

  /// ID de la classe associée à cet élève (clé étrangère).
  final String classeId;

  /// Liste des IDs des notes associées à cet élève.
  final List<String> notesIds;

  /// Constructeur principal utilisant des paramètres nommés.
  EleveModele({
    required this.id,
    required this.utilisateurId,
    required this.classeId,
    required this.notesIds,
  });

  /// Factory permettant de créer une instance d'EleveModele à partir
  /// d'une map (généralement issue de Firestore) et de l'ID du document Firestore.
  factory EleveModele.fromMap(Map<String, dynamic> map, String id) {
    return EleveModele(
      id: id,
      utilisateurId: map['utilisateurId'] ?? '',
      classeId: map['classeId'] ?? '',
      notesIds: List<String>.from(map['notesIds'] ?? []),
    );
  }

  /// Convertit l'instance d'EleveModele en une Map<String, dynamic>
  /// à stocker dans Firestore ou à convertir en JSON.
  ///
  /// Ici, l'ID n'est pas inclus dans la Map car Firestore gère l'ID séparément.
  Map<String, dynamic> toMap() {
    return {
      'utilisateurId': utilisateurId,
      'classeId': classeId,
      'notesIds': notesIds,
    };
  }
}
/// Modèle représentant un parent dans la base de données Firestore.
/// Chaque parent est lié à un utilisateur existant dans la collection "utilisateurs".
class ParentModele {
  /// ID du document Firestore dans la collection "parents".
  final String id;

  /// ID de l'utilisateur associé à ce parent (clé étrangère).
  final String utilisateurId;

  /// Constructeur principal.
  ParentModele({
    required this.id,
    required this.utilisateurId,
  });

  /// Factory pour construire un `ParentModele` à partir d'une Map.
  factory ParentModele.fromMap(Map<String, dynamic> map, String id) {
    return ParentModele(
      id: id,
      utilisateurId: map['utilisateurId'] ?? '',
    );
  }

  /// Convertit le modèle en une Map pour Firestore ou JSON.
  Map<String, dynamic> toMap() {
    return {
      'utilisateurId': utilisateurId,
    };
  }

  @override
  String toString() {
    return 'ParentModele(id: $id, utilisateurId: $utilisateurId)';
  }
}

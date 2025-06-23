/// Modèle représentant un administrateur dans la base de données Firestore.
/// Chaque administrateur est lié à un utilisateur existant dans la collection "utilisateurs".
class AdministrateurModele {
  /// ID du document Firestore dans la collection "administrateurs".
  final String id;

  /// ID de l'utilisateur associé à cet administrateur (clé étrangère).
  final String utilisateurId;

  /// Constructeur principal utilisant des paramètres nommés.
  AdministrateurModele({required this.id, required this.utilisateurId});

  /// Factory permettant de créer une instance d'AdministrateurModele à partir
  /// d'une map (généralement issue de Firestore) et de l'ID du document Firestore.
  factory AdministrateurModele.fromMap(Map<String, dynamic> map, String id) {
    return AdministrateurModele(
      id: id,
      utilisateurId: map['utilisateurId'] as String,
    );
  }

  /// Convertit l'instance d'AdministrateurModele en une Map<String, dynamic>
  /// à stocker dans Firestore ou à convertir en JSON.
  ///
  /// Ici, l'ID n'est pas inclus dans la Map car Firestore gère l'ID séparément.
  Map<String, dynamic> toMap() {
    return {
      'utilisateurId': utilisateurId,
    };
  }
}

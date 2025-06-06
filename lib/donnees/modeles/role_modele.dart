class RoleModele {
  final String id;
  final String nom;
  final String description;

  RoleModele({
    required this.id,
    required this.nom,
    required this.description,
  });

  factory RoleModele.fromMap(Map<String, dynamic> data, String documentId) {
    final nom = data['nom'] as String?;
    final description = data['description'] as String?;

    if (nom == null || description == null) {
      throw ArgumentError('Les champs "nom" et "description" doivent être non nuls dans les données.');
    }

    return RoleModele(
      id: documentId,
      nom: nom,
      description: description,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'nom': nom,
      'description': description,
    };
  }

  @override
  String toString() {
    return 'RoleModele(id: $id, nom: $nom, description: $description)';
  }
}

class RoleModele {
  final String id;
  final String nom;
  final String description;

  RoleModele({
    required this.id,
    required this.nom,
    required this.description,
  });

  factory RoleModele.fromMap(Map<String, dynamic> data, String id) {
    return RoleModele(
      id: id,
      nom: data['nom'] ?? '',
      description: data['description'] ?? '',
    );
  }
}

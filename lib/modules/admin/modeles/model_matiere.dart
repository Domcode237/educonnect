class MatiereModele {
  final String id;
  final String nom;
  final double coefficient;
  final String description;
  final String etablissementId; // Nouvel attribut ajouté

  MatiereModele({
    required this.id,
    required this.nom,
    required this.coefficient,
    required this.description,
    required this.etablissementId, // Ajout dans le constructeur
  });

  factory MatiereModele.fromMap(Map<String, dynamic> map, [String? id]) {
    return MatiereModele(
      id: id ?? map['id'] ?? '',
      nom: map['nom'] ?? '',
      coefficient: (map['coefficient'] ?? 1.0).toDouble(),
      description: map['description'] ?? '',
      etablissementId: map['etablissementId'] ?? '', // Lecture du champ
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'nom': nom,
      'coefficient': coefficient,
      'description': description,
      'etablissementId': etablissementId, // Ajout dans la map pour Firestore
    };
  }
}
